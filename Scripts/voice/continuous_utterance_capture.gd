extends Node
class_name ContinuousUtteranceCapture

## 持续麦克风采集 + 能量门控起说/结束（与 InviteMicCapture 同源阈值，独立音频总线）。

const AudioPcmUtil := preload("res://Scripts/voice/audio_pcm_util.gd")
const InviteListenConfig := preload("res://Scripts/voice/invite_listen_config.gd")
const PreviewVadEventLog := preload("res://Scripts/voice/preview_vad_event_log.gd")

signal speech_started()
signal speech_ended(pcm: PackedByteArray, sample_rate: int)
signal utterance_rejected(reason: String)
## 16kHz PCM 分片（约 PCM_CHUNK_MS）；起说前写入环形缓冲，起说后实时上传。
signal pcm_chunk(pcm: PackedByteArray)

## 独立总线名，避免与 InviteRecord / Record 并发冲突。
var record_bus_name := "FormalVoiceRecord"

var mock_mode := false
var mock_utterance_text := ""

var _mic_player: AudioStreamPlayer
var _capture: AudioEffectCapture
var _mix_rate := 48000
var _active := false
var _paused := false
var _float_buf: PackedFloat32Array = PackedFloat32Array()
var _utterance_floats: PackedFloat32Array = PackedFloat32Array()
var _chunk_samples := 0
var _speech_active := false
var _above_count := 0
var _speech_notified := false
var _last_trigger_peak := 0.0
var _preroll_pcm: Array = []
var _preroll_acc := PackedFloat32Array()
var _chunk_acc := PackedFloat32Array()
var _pending_start := PackedFloat32Array()
var _trailing_silence_samples := 0
var _trailing_ms_used := InviteListenConfig.TRAILING_MS_DEFAULT
var _reject_too_short := 0
var _reject_too_quiet := 0
var _last_chunk_msec := -1
var _tail_pcm_bytes := 0
var _chunk_bytes_total := 0
var _last_endpoint := {}
const PREROLL_MAX_CHUNKS := 5


func _ready() -> void:
	_ensure_record_bus()
	_mic_player = AudioStreamPlayer.new()
	_mic_player.stream = AudioStreamMicrophone.new()
	_mic_player.bus = record_bus_name
	add_child(_mic_player)
	_apply_mix_rate(int(AudioServer.get_mix_rate()))


func start_capture() -> void:
	if _active:
		return
	_active = true
	_paused = false
	_reset_utterance_state()
	_reset_preroll()
	_set_capture_enabled(true)
	if not _mic_player.playing:
		_mic_player.play()
	if _capture != null:
		_capture.clear_buffer()


func stop_capture() -> void:
	_active = false
	_paused = false
	if _mic_player.playing:
		_mic_player.stop()
	_discard_capture()
	_set_capture_enabled(false)
	_reset_utterance_state()


func set_paused(paused: bool, flush_on_resume: bool = false) -> void:
	if _paused != paused:
		PreviewVadEventLog.push(
			"capture_pause" if paused else "capture_resume",
			{"paused": paused, "speech_active": _speech_active},
		)
	_paused = paused
	if paused and _speech_active:
		_abort_open_utterance()
	if paused:
		_float_buf = PackedFloat32Array()
	elif flush_on_resume and _active:
		_reset_utterance_state()
		_reset_preroll()
		_float_buf = PackedFloat32Array()
		if _capture != null:
			_capture.clear_buffer()


func is_active() -> bool:
	return _active


func is_speech_active() -> bool:
	return _speech_active


func debug_set_mix_rate(rate: int) -> void:
	_apply_mix_rate(rate)


func debug_feed_samples(samples: PackedFloat32Array) -> void:
	_ingest(samples)


func debug_last_endpoint() -> Dictionary:
	return _last_endpoint.duplicate(true)


func take_preroll_pcm() -> Array:
	var out := _preroll_pcm.duplicate()
	_preroll_pcm.clear()
	return out


func _reset_preroll() -> void:
	_preroll_pcm.clear()


func debug_emit_mock_utterance() -> void:
	if not mock_mode:
		return
	PreviewVadEventLog.push("speech_started", {
		"mock": true,
		"peak": 0.5,
		"above_count": InviteListenConfig.ENERGY_START_FRAMES,
		"trailing_ms": InviteListenConfig.trailing_silence_ms(),
	})
	speech_started.emit()
	var pcm := PackedByteArray([1, 0])
	PreviewVadEventLog.push("speech_ended", {
		"mock": true,
		"peak": 0.5,
		"duration_sec": 0.25,
		"pcm_bytes": pcm.size(),
		"sample_rate": InviteListenConfig.SAMPLE_RATE,
	})
	speech_ended.emit(pcm, InviteListenConfig.SAMPLE_RATE)


func _process(_delta: float) -> void:
	if not _active or _paused:
		if not _active:
			_discard_capture()
		return
	if mock_mode:
		return
	_flush_capture()


func _apply_mix_rate(rate: int) -> void:
	_mix_rate = maxi(rate, 1)
	_chunk_samples = maxi(1, int(float(_mix_rate) * InviteListenConfig.PCM_CHUNK_MS / 1000.0))


func _hop_samples() -> int:
	return maxi(1, int(float(_mix_rate) * InviteListenConfig.ANALYSIS_HOP_MS / 1000.0))


func _reset_utterance_state() -> void:
	_float_buf = PackedFloat32Array()
	_utterance_floats = PackedFloat32Array()
	_chunk_acc = PackedFloat32Array()
	_pending_start = PackedFloat32Array()
	_preroll_acc = PackedFloat32Array()
	_speech_active = false
	_above_count = 0
	_trailing_silence_samples = 0
	_speech_notified = false
	_last_chunk_msec = -1
	_tail_pcm_bytes = 0
	_chunk_bytes_total = 0


func _flush_capture() -> void:
	if _capture == null:
		return
	var frames := _capture.get_frames_available()
	if frames <= 0:
		return
	var buf: PackedVector2Array = _capture.get_buffer(frames)
	if buf.is_empty():
		return
	var incoming := PackedFloat32Array()
	incoming.resize(buf.size())
	for i in buf.size():
		incoming[i] = (buf[i].x + buf[i].y) * 0.5
	_ingest(incoming)


func _ingest(samples: PackedFloat32Array) -> void:
	if samples.is_empty() or _paused:
		return
	var start := _float_buf.size()
	_float_buf.resize(start + samples.size())
	for i in samples.size():
		_float_buf[start + i] = samples[i]
	var hop := _hop_samples()
	while _float_buf.size() >= hop and not _paused:
		var piece := PackedFloat32Array()
		piece.resize(hop)
		var peak := 0.0
		for i in hop:
			piece[i] = _float_buf[i]
			peak = maxf(peak, absf(piece[i]))
		_float_buf = _float_buf.slice(hop)
		if not _consume_hop(piece, peak):
			return


func _consume_hop(hop: PackedFloat32Array, peak: float) -> bool:
	if peak >= InviteListenConfig.ENERGY_THRESHOLD:
		_trailing_silence_samples = 0
		_above_count += 1
		if not _speech_active:
			_pending_start = _concat(_pending_start, hop)
			if _above_count >= InviteListenConfig.ENERGY_START_FRAMES:
				_begin_speech(peak)
			return true
		_append_voiced(hop, false)
		return true
	_above_count = 0
	if not _speech_active:
		if not _pending_start.is_empty():
			_queue_preroll(_pending_start)
			_pending_start = PackedFloat32Array()
		_queue_preroll(hop)
		return true
	_trailing_silence_samples += hop.size()
	_append_voiced(hop, false)
	var silent_ms := _samples_to_ms(_trailing_silence_samples)
	if silent_ms + 0.001 < float(_trailing_ms_used):
		return true
	_close_utterance(silent_ms)
	return false


func _begin_speech(peak: float) -> void:
	_drain_preroll(true)
	_speech_active = true
	_speech_notified = true
	_trailing_silence_samples = 0
	_trailing_ms_used = InviteListenConfig.trailing_silence_ms()
	_last_trigger_peak = peak
	_utterance_floats = PackedFloat32Array()
	_chunk_acc = PackedFloat32Array()
	_chunk_bytes_total = 0
	_tail_pcm_bytes = 0
	_last_chunk_msec = -1
	PreviewVadEventLog.push("speech_started", {
		"peak": peak,
		"trailing_ms": _trailing_ms_used,
		"above_count": _above_count,
	})
	_print_vad("speech_started", 0.0, 0.0)
	speech_started.emit()
	var started := _pending_start
	_pending_start = PackedFloat32Array()
	_append_voiced(started, false)


func _close_utterance(actual_trailing_ms: float) -> void:
	_speech_active = false
	_speech_notified = false
	_above_count = 0
	_append_voiced(PackedFloat32Array(), true)
	var floats := _utterance_floats
	_utterance_floats = PackedFloat32Array()
	_chunk_acc = PackedFloat32Array()
	_pending_start = PackedFloat32Array()
	_trailing_silence_samples = 0
	var duration_ms := _samples_to_ms(floats.size())
	var peak := 0.0
	for i in floats.size():
		peak = maxf(peak, absf(floats[i]))
	if duration_ms < 200.0:
		_reject_too_short += 1
		_remember_endpoint("too_short", actual_trailing_ms, duration_ms, floats.size(), peak)
		PreviewVadEventLog.push("utterance_rejected", {
			"reason": "too_short",
			"duration_sec": duration_ms / 1000.0,
			"peak": peak,
			"trailing_ms": _trailing_ms_used,
			"actual_trailing_ms": actual_trailing_ms,
		})
		_print_vad("too_short", actual_trailing_ms, duration_ms)
		utterance_rejected.emit("too_short")
		return
	if peak < 0.01:
		_reject_too_quiet += 1
		_remember_endpoint("too_quiet", actual_trailing_ms, duration_ms, floats.size(), peak)
		PreviewVadEventLog.push("utterance_rejected", {
			"reason": "too_quiet",
			"duration_sec": duration_ms / 1000.0,
			"peak": peak,
			"trailing_ms": _trailing_ms_used,
			"actual_trailing_ms": actual_trailing_ms,
		})
		_print_vad("too_quiet", actual_trailing_ms, duration_ms)
		utterance_rejected.emit("too_quiet")
		return
	var pcm := _resample_chunk(floats)
	_remember_endpoint("speech_ended", actual_trailing_ms, duration_ms, floats.size(), peak)
	PreviewVadEventLog.push("speech_ended", {
		"duration_sec": duration_ms / 1000.0,
		"peak": peak,
		"pcm_bytes": pcm.size(),
		"sample_rate": InviteListenConfig.SAMPLE_RATE,
		"trailing_ms": _trailing_ms_used,
		"actual_trailing_ms": actual_trailing_ms,
		"tail_bytes": _tail_pcm_bytes,
	})
	_print_vad("speech_ended", actual_trailing_ms, duration_ms)
	speech_ended.emit(pcm, InviteListenConfig.SAMPLE_RATE)


func _abort_open_utterance() -> void:
	_speech_active = false
	_speech_notified = false
	_above_count = 0
	_trailing_silence_samples = 0
	_utterance_floats = PackedFloat32Array()
	_chunk_acc = PackedFloat32Array()
	_pending_start = PackedFloat32Array()


func _append_voiced(samples: PackedFloat32Array, flush_short: bool) -> void:
	if not samples.is_empty():
		_utterance_floats = _concat(_utterance_floats, samples)
		_chunk_acc = _concat(_chunk_acc, samples)
	while _chunk_acc.size() >= _chunk_samples:
		var piece := _take_front(_chunk_acc, _chunk_samples)
		_chunk_acc = _drop_front(_chunk_acc, _chunk_samples)
		_emit_pcm_chunk(piece, false)
	if flush_short and _chunk_acc.size() > 0:
		var tail := _chunk_acc
		_chunk_acc = PackedFloat32Array()
		_emit_pcm_chunk(tail, true)


func _emit_pcm_chunk(samples: PackedFloat32Array, is_tail: bool) -> void:
	var pcm := _resample_chunk(samples)
	if pcm.is_empty():
		return
	_last_chunk_msec = Time.get_ticks_msec()
	_chunk_bytes_total += pcm.size()
	if is_tail:
		_tail_pcm_bytes = pcm.size()
	pcm_chunk.emit(pcm)


func _queue_preroll(samples: PackedFloat32Array) -> void:
	_preroll_acc = _concat(_preroll_acc, samples)
	_drain_preroll(false)


func _drain_preroll(flush_short: bool) -> void:
	while _preroll_acc.size() >= _chunk_samples:
		var piece := _take_front(_preroll_acc, _chunk_samples)
		_preroll_acc = _drop_front(_preroll_acc, _chunk_samples)
		_push_preroll_pcm(_resample_chunk(piece))
	if flush_short and _preroll_acc.size() > 0:
		var piece := _preroll_acc
		_preroll_acc = PackedFloat32Array()
		_push_preroll_pcm(_resample_chunk(piece))


func _push_preroll_pcm(pcm: PackedByteArray) -> void:
	if pcm.is_empty():
		return
	_preroll_pcm.append(pcm)
	while _preroll_pcm.size() > PREROLL_MAX_CHUNKS:
		_preroll_pcm.pop_front()


func _resample_chunk(samples: PackedFloat32Array) -> PackedByteArray:
	if samples.is_empty():
		return PackedByteArray()
	return AudioPcmUtil.floats_to_pcm16_mono(samples, _mix_rate, InviteListenConfig.SAMPLE_RATE)


func _samples_to_ms(samples: int) -> float:
	return 1000.0 * float(samples) / float(maxi(_mix_rate, 1))


func _remember_endpoint(
	event_name: String,
	actual_trailing_ms: float,
	duration_ms: float,
	utterance_samples: int,
	peak: float,
) -> void:
	_last_endpoint = {
		"event": event_name,
		"trailing_ms": _trailing_ms_used,
		"actual_trailing_ms": actual_trailing_ms,
		"duration_ms": duration_ms,
		"utterance_samples": utterance_samples,
		"tail_bytes": _tail_pcm_bytes,
		"chunk_bytes": _chunk_bytes_total,
		"last_chunk_msec": _last_chunk_msec,
		"reject_short": _reject_too_short,
		"reject_quiet": _reject_too_quiet,
		"peak": peak,
	}


func _print_vad(event_name: String, actual_trailing_ms: float, duration_ms: float) -> void:
	print(
		"vad_listen event=%s trailing_ms=%d actual_trailing_ms=%.1f duration_ms=%.1f tail_bytes=%d last_chunk_msec=%d reject_short=%d reject_quiet=%d"
		% [
			event_name,
			_trailing_ms_used,
			actual_trailing_ms,
			duration_ms,
			_tail_pcm_bytes,
			_last_chunk_msec,
			_reject_too_short,
			_reject_too_quiet,
		]
	)


func _concat(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	if b.is_empty():
		return a
	var start := a.size()
	a.resize(start + b.size())
	for i in b.size():
		a[start + i] = b[i]
	return a


func _take_front(buf: PackedFloat32Array, count: int) -> PackedFloat32Array:
	var piece := PackedFloat32Array()
	piece.resize(count)
	for i in count:
		piece[i] = buf[i]
	return piece


func _drop_front(buf: PackedFloat32Array, count: int) -> PackedFloat32Array:
	if count >= buf.size():
		return PackedFloat32Array()
	return buf.slice(count)


func _discard_capture() -> void:
	if _capture == null:
		return
	var frames := _capture.get_frames_available()
	if frames > 0:
		_capture.get_buffer(frames)


func _ensure_record_bus() -> void:
	var idx := AudioServer.get_bus_index(record_bus_name)
	if idx < 0:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, record_bus_name)
		AudioServer.set_bus_send(idx, "Master")
	AudioServer.set_bus_mute(idx, true)
	var capture_i := -1
	for i in AudioServer.get_bus_effect_count(idx):
		if AudioServer.get_bus_effect(idx, i) is AudioEffectCapture:
			capture_i = i
			break
	if capture_i < 0:
		AudioServer.add_bus_effect(idx, AudioEffectCapture.new())
		capture_i = AudioServer.get_bus_effect_count(idx) - 1
	_capture = AudioServer.get_bus_effect(idx, capture_i) as AudioEffectCapture
	AudioServer.set_bus_effect_enabled(idx, capture_i, false)


func _set_capture_enabled(on: bool) -> void:
	var idx := AudioServer.get_bus_index(record_bus_name)
	if idx < 0:
		return
	for i in AudioServer.get_bus_effect_count(idx):
		if AudioServer.get_bus_effect(idx, i) is AudioEffectCapture:
			AudioServer.set_bus_effect_enabled(idx, i, on)
			break
