class_name VoiceOutput
extends Node

## TTS：百炼 SpeechSynthesizer（与 AudioPanel qwen-audio-3.0-tts-plus 配置一致）。
## ASR 仍使用 NLS；本节点不再调用 NLS /stream/v1/tts。

const AliyunNlsConfigScript := preload("res://Scripts/voice/aliyun_nls_config.gd")
const NlsTokenProviderScript := preload("res://Scripts/voice/nls_token_provider.gd")
const BailianTtsConfigScript := preload("res://Scripts/voice/bailian_tts_config.gd")
const BailianTtsClientScript := preload("res://Scripts/voice/bailian_tts_client.gd")
const BailianTtsWsClientScript := preload("res://Scripts/voice/bailian_tts_ws_client.gd")
const Pcm16StreamPlayerScript := preload("res://Scripts/voice/pcm16_stream_player.gd")
const AudioBytesUtilScript := preload("res://Scripts/voice/audio_bytes_util.gd")
const VoiceTurnLatencyScript := preload("res://Scripts/voice/voice_turn_latency.gd")
const StreamTtsPlaybackTraceScript := preload("res://Scripts/voice/stream_tts_playback_trace.gd")
const VoiceTtsSplitConfigScript := preload("res://Scripts/voice/voice_tts_split_config.gd")

var config: AliyunNlsConfigScript
var latency: VoiceTurnLatencyScript
var token_provider: NlsTokenProviderScript
var bailian_config: BailianTtsConfigScript
var bailian_client: BailianTtsClientScript
var bailian_ws_client: BailianTtsWsClientScript
var audio_player: AudioStreamPlayer

## 默认走百炼 HTTP。YOUYOU_VOICE_STREAM_TTS=1 时由 Preview 桥接改走 WebSocket PCM。
var stream_tts_enabled: bool = false

## 首句 PCM 就绪即播放；关闭则恢复「全部分句合成完再播」。
## true 时：后台 _drain_playback_queue 与 for 分句合成并行——首句 await 合成入队后即播放，
## 后续分句在播放上一段期间继续串行 synthesize（不增并发 HTTP，仅重叠播放与合成）。
@export var stream_first_chunk: bool = true

@export_category("TTS Voice Settings")
@export_range(-500, 500, 1) var speech_rate: int = 0
@export_range(-500, 500, 1) var pitch_rate: int = 0

var _http: HTTPRequest
var _stop_requested: bool = false
var _speaking: bool = false
var _pcm_queue: Array = [] # PackedByteArray chunks waiting to play
var _synth_done: bool = true
var _playback_done: bool = true
var _speak_gen: int = 0
var _play_sample_rate: int = 16000
## Accumulated PCM duration (seconds) for the current speak() call — for lip sync.
var _speak_audio_seconds: float = 0.0
var _http_played_seconds: float = 0.0
var _playback_started_hook: Callable = Callable()
var _pcm_stream: Pcm16StreamPlayerScript
var _stream_chunk_playback_started: bool = false
var _ws_stream_pumping: bool = false
var _stream_trace: StreamTtsPlaybackTraceScript


func setup(
	nls_config: AliyunNlsConfigScript,
	tokens: NlsTokenProviderScript,
	player: AudioStreamPlayer,
	tts_config: BailianTtsConfigScript = null,
) -> void:
	config = nls_config
	token_provider = tokens
	audio_player = player
	bailian_config = tts_config
	if bailian_client == null:
		bailian_client = BailianTtsClientScript.new()
		bailian_client.name = "BailianTtsClient"
		add_child(bailian_client)
	bailian_client.setup(bailian_config)
	if bailian_ws_client == null:
		bailian_ws_client = BailianTtsWsClientScript.new()
		bailian_ws_client.name = "BailianTtsWsClient"
		add_child(bailian_ws_client)
	bailian_ws_client.setup(bailian_config)
	if _pcm_stream == null:
		_pcm_stream = Pcm16StreamPlayerScript.new()
		_pcm_stream.set_playback_started_callback(_on_stream_playback_started)


func set_stream_tts_enabled(enabled: bool) -> void:
	stream_tts_enabled = enabled


func last_stream_underrun_count() -> int:
	if _pcm_stream == null:
		return 0
	return _pcm_stream.underrun_count()


func set_playback_started_hook(callable: Callable) -> void:
	_playback_started_hook = callable


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 60.0
	add_child(_http)
	set_process(false)


func _process(_delta: float) -> void:
	if _ws_stream_pumping and _pcm_stream != null and not _stop_requested:
		_pcm_stream.tick(_speak_gen)


func is_speaking() -> bool:
	return _speaking


## 诊断：返回当前分句策略下的 chunk 列表（不改变 speak 行为）。
func peek_tts_chunks(text: String) -> PackedStringArray:
	return _split_for_tts(text)


## Total synthesized audio seconds so far for the active speak (grows as chunks arrive).
func get_speak_audio_seconds() -> float:
	return _speak_audio_seconds


## synth_done 为真后，total_sec - played_sec 是还没播完的回答时长。
func answer_timing() -> Dictionary:
	var played := _http_played_seconds
	if stream_tts_enabled and _pcm_stream != null:
		played = _pcm_stream.played_seconds()
	elif audio_player != null and audio_player.playing:
		played += maxf(audio_player.get_playback_position(), 0.0)
	return {
		"synth_done": _synth_done,
		"total_sec": _speak_audio_seconds,
		"played_sec": played,
	}


func stop(invalidate_inflight: bool = true) -> void:
	_stop_requested = true
	if invalidate_inflight:
		_speak_gen += 1
		if bailian_client != null:
			bailian_client.cancel_session()
		if bailian_ws_client != null:
			bailian_ws_client.cancel()
		if _pcm_stream != null:
			_pcm_stream.stop_immediate()
	_ws_stream_pumping = false
	set_process(false)
	_pcm_queue.clear()
	_synth_done = true
	_speak_audio_seconds = 0.0
	_http_played_seconds = 0.0
	if audio_player != null and audio_player.playing:
		audio_player.stop()
	_speaking = false


func speak(text: String, emotion: String = "", intensity: float = 0.0) -> bool:
	if text.strip_edges().is_empty():
		return true
	if bailian_config == null or bailian_client == null:
		push_error("TTS 缺少百炼配置或客户端")
		return false
	var tts_err := bailian_config.validate_for_tts()
	if not tts_err.is_empty():
		push_error("TTS 配置不完整: " + tts_err)
		return false

	stop(false)
	if bailian_client != null:
		bailian_client.cancel_session()
	if bailian_ws_client != null:
		bailian_ws_client.cancel()
	_stop_requested = false
	_speaking = true
	_speak_gen += 1
	var gen := _speak_gen
	_speak_audio_seconds = 0.0
	_http_played_seconds = 0.0

	var emotion_category := ""
	var llm_intensity := _sanitize_llm_intensity(intensity)
	var mapped_intensity := 0.01
	if not emotion.strip_edges().is_empty():
		emotion_category = _map_emotion_category(emotion)
		mapped_intensity = clampf(llm_intensity * 1.2, 0.01, 1.4)

	print("VoiceOutput: 百炼 TTS model=%s voice=%s emotion=%s"
		% [bailian_config.model, bailian_config.voice, emotion_category if not emotion_category.is_empty() else "(plain)"])
	print("VoiceOutput: 开始 TTS，文本长度=", text.length(),
		" stream_first_chunk=", stream_first_chunk)

	var rate := bailian_config.sample_rate if bailian_config.sample_rate > 0 else 24000
	if latency != null and latency.enabled:
		latency.mark_once("tts_start")
	VoiceTtsSplitConfigScript.log_effective_once()
	var chunks := _split_for_tts(text)
	print("VoiceOutput: TTS 分句数=", chunks.size(), " comma_min=", VoiceTtsSplitConfigScript.comma_break_min_chars())
	if chunks.is_empty():
		_speaking = false
		return true

	if stream_tts_enabled and stream_first_chunk and _stream_tts_ready():
		var ok_stream := await _speak_ws_pcm_stream(
			chunks, rate, emotion_category, mapped_intensity, gen
		)
		return ok_stream
	elif stream_tts_enabled and stream_first_chunk:
		push_warning("VoiceOutput: 流式 TTS 不可用，回退 HTTP TTS")

	if not stream_first_chunk:
		var ok_legacy := await _speak_legacy_buffer_all(
			chunks, rate, emotion_category, mapped_intensity, gen
		)
		return ok_legacy

	_pcm_queue.clear()
	_synth_done = false
	_playback_done = false
	_play_sample_rate = rate
	_drain_playback_queue(gen)

	for i in chunks.size():
		if _stop_requested or gen != _speak_gen:
			_synth_done = true
			if audio_player != null and audio_player.playing:
				audio_player.stop()
			while not _playback_done and gen == _speak_gen:
				await get_tree().process_frame
			_speaking = false
			return false
		if latency != null and latency.enabled:
			latency.set_tts_chunk_index(i)
		var piece: PackedByteArray = await _synthesize_chunk_bailian(
			chunks[i], emotion_category, mapped_intensity, gen
		)
		if _stop_requested or gen != _speak_gen:
			_synth_done = true
			_pcm_queue.clear()
			if audio_player != null and audio_player.playing:
				audio_player.stop()
			while not _playback_done and gen == _speak_gen:
				await get_tree().process_frame
			_speaking = false
			return false
		if piece.is_empty():
			push_error("VoiceOutput: 某一句 TTS 返回空音频")
			_synth_done = true
			_pcm_queue.clear()
			if audio_player != null and audio_player.playing:
				audio_player.stop()
			while not _playback_done and gen == _speak_gen:
				await get_tree().process_frame
			_speaking = false
			return false
		_note_audio_seconds(piece)
		_pcm_queue.append(piece)
		if i == 0:
			print("VoiceOutput: 首句就绪，开始播放 (bytes=%d, 剩余分句=%d)" % [
				piece.size(), chunks.size() - 1
			])

	_synth_done = true
	if latency != null and latency.enabled:
		latency.mark_end("tts_all_ready")
	while not _playback_done and gen == _speak_gen:
		if _stop_requested:
			break
		await get_tree().process_frame

	if audio_player != null and audio_player.playing:
		audio_player.stop()
	var ok := not _stop_requested and gen == _speak_gen
	_speaking = false
	if latency != null and latency.enabled and ok:
		latency.mark_end("playback_end")
	print("VoiceOutput: 播放结束 ok=", ok)
	return ok


func _speak_legacy_buffer_all(
	chunks: PackedStringArray,
	rate: int,
	emotion_category: String,
	mapped_intensity: float,
	gen: int
) -> bool:
	var pcm := PackedByteArray()
	for chunk_i in chunks.size():
		if _stop_requested or gen != _speak_gen:
			_speaking = false
			return false
		if latency != null and latency.enabled:
			latency.set_tts_chunk_index(chunk_i)
		var piece: PackedByteArray = await _synthesize_chunk_bailian(
			chunks[chunk_i], emotion_category, mapped_intensity, gen
		)
		if _stop_requested or gen != _speak_gen:
			_speaking = false
			return false
		if piece.is_empty():
			push_error("VoiceOutput: 某一句 TTS 返回空音频")
			_speaking = false
			return false
		pcm.append_array(piece)

	if pcm.size() < 2:
		push_error("TTS 返回空音频")
		_speaking = false
		return false

	_speak_audio_seconds = _estimate_bytes_duration(pcm)
	await _play_audio_bytes(pcm, gen)
	if audio_player != null and audio_player.playing:
		audio_player.stop()
	var ok := not _stop_requested and gen == _speak_gen
	_speaking = false
	print("VoiceOutput: 播放结束")
	return ok


func _note_audio_seconds(pcm: PackedByteArray) -> void:
	_speak_audio_seconds += _estimate_bytes_duration(pcm)


func _estimate_bytes_duration(pcm: PackedByteArray) -> float:
	var stream := AudioBytesUtilScript.stream_from_bytes(pcm)
	return AudioBytesUtilScript.estimate_duration_sec(stream)


func _drain_playback_queue(gen: int) -> void:
	while gen == _speak_gen:
		if _stop_requested:
			break
		if _pcm_queue.is_empty():
			if _synth_done:
				break
			await get_tree().process_frame
			continue
		var piece: PackedByteArray = _pcm_queue.pop_front()
		await _play_audio_bytes(piece, gen)
		if _stop_requested or gen != _speak_gen:
			break
	if gen == _speak_gen:
		_playback_done = true


func _play_audio_bytes(pcm: PackedByteArray, gen: int) -> void:
	if pcm.is_empty() or audio_player == null:
		return
	if _stop_requested or gen != _speak_gen:
		return

	if latency != null and latency.enabled:
		latency.mark_once("tts_decode_start")
	var stream := AudioBytesUtilScript.stream_from_bytes(pcm)
	if stream == null:
		push_error("VoiceOutput: 音频解码失败 (bytes=%d format=%s)" % [
			pcm.size(), AudioBytesUtilScript.detect_format(pcm),
		])
		return
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		print(
			"VoiceOutput: 解码 WAV mix_rate=%d stereo=%s pcm_bytes=%d"
			% [wav.mix_rate, wav.stereo, wav.data.size()]
		)

	audio_player.stream = stream
	audio_player.bus = "Master"
	audio_player.play()
	if not audio_player.playing:
		push_error("VoiceOutput: AudioStreamPlayer 未能开始播放")
		return
	if latency != null and latency.enabled:
		latency.mark_once("playback_start")
	if _playback_started_hook.is_valid():
		_playback_started_hook.call()

	var seconds: float = AudioBytesUtilScript.estimate_duration_sec(stream)
	if seconds <= 0.0:
		seconds = 8.0
	print("VoiceOutput: 播放分片 %.2fs bytes=%d" % [seconds, pcm.size()])
	var elapsed := 0.0
	while audio_player.playing and elapsed < seconds + 0.5:
		if _stop_requested or gen != _speak_gen:
			audio_player.stop()
			break
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if gen == _speak_gen:
		_http_played_seconds += seconds


func _stream_tts_ready() -> bool:
	if bailian_ws_client == null or _pcm_stream == null or audio_player == null:
		return false
	if bailian_config == null:
		return false
	if not bailian_config.validate_for_tts().is_empty():
		return false
	return not bailian_config.get_websocket_inference_url().is_empty()


func _on_stream_playback_started() -> void:
	if _stream_chunk_playback_started:
		return
	_stream_chunk_playback_started = true
	if _stream_trace != null:
		_stream_trace.mark("playback_start_hook")
	if latency != null and latency.enabled:
		latency.mark_once("tts_decode_start")
		latency.mark_once("playback_start")
	if _playback_started_hook.is_valid():
		_playback_started_hook.call()


func _speak_ws_pcm_stream(
	chunks: PackedStringArray,
	rate: int,
	emotion_category: String,
	mapped_intensity: float,
	gen: int,
) -> bool:
	if bailian_ws_client == null or _pcm_stream == null or audio_player == null:
		push_error("VoiceOutput: 流式 TTS 未初始化")
		return false
	_stream_chunk_playback_started = false
	_apply_stream_min_start_from_env()
	_stream_trace = StreamTtsPlaybackTraceScript.new()
	_stream_trace.begin()
	bailian_ws_client.set_stream_trace(_stream_trace)
	_pcm_stream.bind_player(audio_player, rate)
	_pcm_stream.set_trace(_stream_trace)
	_pcm_stream.begin_turn(gen)
	_synth_done = false
	_playback_done = false
	_play_sample_rate = rate
	print("VoiceOutput: 流式 WS TTS 分句数=", chunks.size())
	const VoiceTurnTraceScript := preload("res://Scripts/voice/voice_turn_trace.gd")
	VoiceTurnTraceScript.refresh_from_env()
	VoiceTurnTraceScript.log("tts_speak_started", {"speak_gen": gen, "chunks": chunks.size()})

	_ws_stream_pumping = true
	set_process(true)

	var any_chunk_ok := false
	for i in chunks.size():
		if _stop_requested or gen != _speak_gen:
			break
		if latency != null and latency.enabled:
			latency.set_tts_chunk_index(i)
			if i == 0:
				latency.mark_once("tts_ws_connect_start")
		var instruction := _build_bailian_instruction(emotion_category, mapped_intensity)
		var chunk_text: String = chunks[i]
		var saw_pcm: Array = [false]
		var chunk_index := i
		_pcm_stream.set_expecting_pcm(true)
		var on_pcm := func(pcm: PackedByteArray, speak_gen: int) -> void:
			if speak_gen != gen or gen != _speak_gen or _stop_requested:
				return
			if not bool(saw_pcm[0]):
				saw_pcm[0] = true
				if latency != null and latency.enabled and chunk_index == 0:
					latency.mark_once("tts_ws_first_pcm")
					latency.mark_end("tts_first_audio_ready")
			_pcm_stream.feed_pcm(pcm, gen)
			_note_pcm16_seconds(pcm, rate)

		var ws_result: Dictionary = await bailian_ws_client.synthesize_pcm_stream(
			chunk_text, instruction, gen, on_pcm, i > 0
		)
		_pcm_stream.set_expecting_pcm(false)
		if latency != null and latency.enabled and i == 0:
			latency.mark_once("tts_ws_connect_done")
		if _stop_requested or gen != _speak_gen:
			break
		if not bool(ws_result.get("ok", false)):
			var err := str(ws_result.get("error", ""))
			if _stop_requested or gen != _speak_gen or err == "cancelled":
				break
			if not any_chunk_ok and not _stream_chunk_playback_started:
				print("VoiceOutput: WS TTS 失败，首包前 HTTP 回退 chunk=", i, " err=", err)
				var http_piece := await _synthesize_chunk_bailian(
					chunk_text, emotion_category, mapped_intensity, gen
				)
				if http_piece.is_empty():
					break
				_pcm_stream.feed_pcm(_extract_pcm16_from_wav_or_raw(http_piece, rate), gen)
				any_chunk_ok = true
			else:
				push_error("VoiceOutput: WS TTS 失败（已播放部分，不回退 HTTP）: " + err)
				break
		else:
			any_chunk_ok = true
			if latency != null and latency.enabled:
				var metrics: Dictionary = ws_result.get("metrics", {})
				latency.notify_tts_http_span(float(metrics.get("connect_ms", 0.0)))
		if _stop_requested or gen != _speak_gen:
			break
		if i + 1 < chunks.size():
			await _ws_chunk_boundary_pad(gen, rate)

	_ws_stream_pumping = false
	set_process(false)
	_synth_done = true
	if latency != null and latency.enabled:
		latency.mark_end("tts_all_ready")
	VoiceTurnTraceScript.log("tts_all_audio_synth_done", {"speak_gen": gen})
	var drained: bool
	if DisplayServer.get_name() == "headless":
		_pcm_stream.discard_pending_for_headless(gen)
		drained = true
	else:
		drained = await _pcm_stream.wait_until_idle(
			gen,
			true,
			get_tree(),
			func() -> bool: return _stop_requested or gen != _speak_gen,
		)
	VoiceTurnTraceScript.log(
		"tts_all_audio_drained" if drained else "tts_drain_timeout",
		{"speak_gen": gen, "drained": drained},
	)
	if audio_player != null and audio_player.playing:
		if _stop_requested or gen != _speak_gen or drained:
			audio_player.stop()
	elif not drained:
		push_warning("VoiceOutput: 流式 WS 播放缓冲未在时限内排空")
	_playback_done = true
	var ok := any_chunk_ok and not _stop_requested and gen == _speak_gen and drained
	_speaking = false
	if latency != null and latency.enabled and ok:
		latency.mark_end("playback_end")
	print(
		"VoiceOutput: 流式 WS 播放结束 ok=%s underruns=%d raw_skips=%d"
		% [str(ok), _pcm_stream.underrun_count(), _pcm_stream.raw_skips_total()]
	)
	if _stream_trace != null:
		print(_stream_trace.report_line())
	return ok


const ENV_WS_CHUNK_PAD_MS := "YOUYOU_TTS_WS_CHUNK_PAD_MS"
const DEFAULT_WS_CHUNK_PAD_MS := 72.0


func _ws_chunk_boundary_pad(speak_gen: int, rate: int) -> void:
	if _pcm_stream == null or _stop_requested or speak_gen != _speak_gen:
		return
	var pad_ms := _ws_chunk_pad_ms()
	if pad_ms <= 0.0:
		return
	_pcm_stream.feed_silence_ms(pad_ms, speak_gen)
	var tree := get_tree()
	if tree == null:
		return
	var end_usec := Time.get_ticks_usec() + int(pad_ms * 1000.0)
	while speak_gen == _speak_gen and not _stop_requested and Time.get_ticks_usec() < end_usec:
		_pcm_stream.tick(speak_gen)
		await tree.process_frame


func _ws_chunk_pad_ms() -> float:
	var raw := OS.get_environment(ENV_WS_CHUNK_PAD_MS).strip_edges()
	if raw.is_valid_float():
		return clampf(float(raw), 0.0, 200.0)
	const key := "voice/tts_ws_chunk_pad_ms"
	if ProjectSettings.has_setting("application/config/%s" % key):
		return clampf(float(ProjectSettings.get_setting("application/config/%s" % key)), 0.0, 200.0)
	return DEFAULT_WS_CHUNK_PAD_MS


func _apply_stream_min_start_from_env() -> void:
	if _pcm_stream == null:
		return
	var raw := OS.get_environment("YOUYOU_STREAM_TTS_MIN_START_MS").strip_edges()
	if raw.is_empty():
		return
	var ms := float(raw)
	if ms >= 80.0 and ms <= 400.0:
		_pcm_stream.min_start_ms = ms


func _note_pcm16_seconds(pcm: PackedByteArray, rate: int) -> void:
	var samples := pcm.size() / 2
	_speak_audio_seconds += float(samples) / float(maxi(rate, 1))


func _extract_pcm16_from_wav_or_raw(data: PackedByteArray, rate: int) -> PackedByteArray:
	var stream := AudioBytesUtilScript.stream_from_bytes(data)
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		if wav.format == AudioStreamWAV.FORMAT_16_BITS and not wav.stereo and wav.mix_rate == rate:
			return wav.data
	return data


func _synthesize_chunk_bailian(
	chunk: String,
	emotion_category: String,
	mapped_intensity: float,
	gen: int,
) -> PackedByteArray:
	var instruction := _build_bailian_instruction(emotion_category, mapped_intensity)
	var result: Dictionary = await bailian_client.synthesize_text(
		chunk, instruction, gen
	)
	if _stop_requested or gen != _speak_gen:
		return PackedByteArray()
	if not bool(result.get("ok", false)):
		var err_msg := str(result.get("error", "TTS 失败"))
		push_error(err_msg)
		return PackedByteArray()
	return result.get("audio", PackedByteArray()) as PackedByteArray


func _build_bailian_instruction(emotion_category: String, _intensity: float) -> String:
	## 与 AudioPanel `compose_instruction` 一致：情绪进 input.instruction，不改写 input.text。
	if bailian_config != null:
		var fixed := bailian_config.default_instruction.strip_edges()
		if not fixed.is_empty() and emotion_category.is_empty():
			return fixed
	var emotion_label := _emotion_label_for_instruction(emotion_category)
	var parts: PackedStringArray = PackedStringArray()
	if not emotion_label.is_empty():
		parts.append("情绪：" + emotion_label)
	if bailian_config != null:
		var fixed2 := bailian_config.default_instruction.strip_edges()
		if not fixed2.is_empty():
			parts.append(fixed2)
	return "；".join(parts)


func _emotion_label_for_instruction(emotion_category: String) -> String:
	match emotion_category:
		"happy":
			return "开心"
		"sad":
			return "悲伤"
		"angry":
			return "愤怒"
		"surprise":
			return "惊讶"
		"neutral":
			return ""
		_:
			return ""


## LLM intensity → 合法 0~1；非法默认 0.4；小于 0 按 0（映射后夹到 0.01）；大于 1 按 1.0。
func _sanitize_llm_intensity(intensity: float) -> float:
	if is_nan(intensity) or is_inf(intensity):
		return 0.4
	if intensity < 0.0:
		return 0.0
	if intensity > 1.0:
		return 1.0
	return intensity


## 仅允许阿里云 SSML 的 5 种 emotion；扩展情绪映射到最接近类别。
## surprised 兼容为 surprise。未知回退 neutral。不改变 TTS 管道本身。
func _map_emotion_category(emotion: String) -> String:
	match emotion.strip_edges().to_lower():
		"neutral":
			return "neutral"
		"happy", "shy", "playful", "proud", "curious":
			return "happy"
		"sad":
			return "sad"
		"angry":
			return "angry"
		"surprise", "surprised":
			return "surprise"
		"confused":
			return "neutral"
		_:
			return "neutral"


func _split_for_tts(text: String) -> PackedStringArray:
	var list: PackedStringArray = PackedStringArray()
	var sb := ""
	var on_android := OS.get_name() == "Android"
	var soft_limit := 48 if on_android else 80
	var hard_limit := 160 if on_android else 280
	var comma_min := _comma_break_min_chars()
	for i in text.length():
		var c := text.substr(i, 1)
		sb += c
		var is_comma := c == "，" or c == ","
		var is_strong_punct := c == "。" or c == "！" or c == "？" or c == "；" or c == "\n" \
			or c == "." or c == "!" or c == "?"
		var min_before := comma_min if is_comma else 8
		var punct := is_strong_punct or is_comma
		if (punct and sb.length() >= min_before) or sb.length() >= soft_limit:
			sb = _flush_tts_chunk(list, sb, hard_limit)
	_flush_tts_chunk(list, sb, hard_limit)
	return list


func _comma_break_min_chars() -> int:
	return VoiceTtsSplitConfigScript.comma_break_min_chars()


func _flush_tts_chunk(list: PackedStringArray, sb: String, hard_limit: int) -> String:
	var chunk := sb.strip_edges()
	if chunk.is_empty():
		return ""
	while chunk.length() > hard_limit:
		list.append(chunk.substr(0, hard_limit))
		chunk = chunk.substr(hard_limit)
	if chunk.length() > 0:
		list.append(chunk)
	return ""
