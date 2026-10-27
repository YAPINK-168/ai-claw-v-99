class_name Pcm16StreamPlayer
extends RefCounted

const StreamTtsPlaybackTraceScript := preload("res://Scripts/voice/stream_tts_playback_trace.gd")

## Godot 4.x：24kHz mono PCM16 LE → AudioStreamGenerator 连续播放（主线程 tick，不阻塞帧循环）。

const DEFAULT_MIN_START_MS := 150.0
const DEFAULT_WARM_MIN_START_MS := 80.0
const DEFAULT_MAX_PENDING_BYTES := 96000
const DEFAULT_PLAYBACK_END_TOLERANCE_SEC := 0.025
const DEFAULT_PLAYBACK_TAIL_PAD_SEC := 0.16
const ENV_PLAYBACK_END_TOLERANCE_MS := "YOUYOU_STREAM_TTS_PLAYBACK_END_TOLERANCE_MS"
const ENV_PLAYBACK_TAIL_PAD_MS := "YOUYOU_STREAM_TTS_PLAYBACK_TAIL_PAD_MS"

var min_start_ms: float = DEFAULT_MIN_START_MS
var warm_min_start_ms: float = DEFAULT_WARM_MIN_START_MS
var max_pending_bytes: int = DEFAULT_MAX_PENDING_BYTES

var _player: AudioStreamPlayer
var _generator: AudioStreamGenerator
var _pcm_rate: int = 24000
var _turn_gen: int = -1
var _byte_tail: PackedByteArray = PackedByteArray()
var _pending: PackedByteArray = PackedByteArray()
var _pending_read: int = 0
var _playback_warmed: bool = false
var _started_playback: bool = false
var _playback_started_fired: bool = false
var _frames_pushed: int = 0
var _last_skips: int = 0
var _credited_underruns: int = 0
var _expecting_pcm: bool = false
var _on_playback_started: Callable = Callable()
var _trace: StreamTtsPlaybackTraceScript
var _tail_pad_started_usec: int = -1


func bind_player(player: AudioStreamPlayer, pcm_sample_rate: int) -> void:
	_player = player
	_pcm_rate = maxi(pcm_sample_rate, 1)


func set_trace(trace: StreamTtsPlaybackTraceScript) -> void:
	_trace = trace


func set_playback_started_callback(callable: Callable) -> void:
	_on_playback_started = callable


func begin_turn(turn_gen: int) -> void:
	_turn_gen = turn_gen
	_reset_buffers()
	_playback_warmed = false
	_started_playback = false
	_playback_started_fired = false
	_frames_pushed = 0
	_last_skips = 0
	_credited_underruns = 0
	_expecting_pcm = false
	_tail_pad_started_usec = -1
	if _player == null:
		return
	_generator = AudioStreamGenerator.new()
	_generator.mix_rate = _pcm_rate
	_generator.buffer_length = 1.0
	_player.stream = _generator
	_player.stop()


func set_expecting_pcm(expecting: bool) -> void:
	_expecting_pcm = expecting


func stop_immediate() -> void:
	_turn_gen = -1
	_pending.clear()
	_pending_read = 0
	_byte_tail.clear()
	_started_playback = false
	_expecting_pcm = false
	if _player != null and _player.playing:
		_player.stop()


## Headless 无真实音频输出时，避免 wait_until_idle 永久等待。
func discard_pending_for_headless(turn_gen: int) -> void:
	if turn_gen != _turn_gen:
		return
	_pending.clear()
	_pending_read = 0
	_byte_tail.clear()
	_started_playback = false
	_expecting_pcm = false
	if _player != null and _player.playing:
		_player.stop()


func feed_pcm(chunk: PackedByteArray, turn_gen: int) -> void:
	if turn_gen != _turn_gen or chunk.is_empty():
		return
	var merged := _byte_tail.duplicate()
	merged.append_array(chunk)
	_byte_tail.clear()
	var usable := merged.size() - (merged.size() % 2)
	if usable <= 0:
		_byte_tail = merged
		return
	var aligned := merged.slice(0, usable)
	if merged.size() > usable:
		_byte_tail = merged.slice(usable, merged.size())
	_trim_pending_if_needed(aligned.size())
	_pending.append_array(aligned)


func pending_bytes() -> int:
	return _pending.size() - _pending_read + _byte_tail.size()


func playback_started() -> bool:
	return _playback_started_fired


func underrun_count() -> int:
	return _credited_underruns


func raw_skips_total() -> int:
	return _last_skips


func tick(turn_gen: int) -> void:
	if turn_gen != _turn_gen or _player == null or _generator == null:
		return
	var min_ms := warm_min_start_ms if _playback_warmed else min_start_ms
	var min_bytes := int(_pcm_rate * 2.0 * min_ms / 1000.0)
	if pending_bytes() >= min_bytes:
		if _trace != null:
			_trace.mark("startup_buffer_ready")
	if not _player.playing:
		if pending_bytes() < min_bytes:
			return
		_player.play()
		_started_playback = _player.playing
		if _trace != null and _started_playback:
			_trace.mark("generator_play_called")
	if not _player.playing:
		return
	var playback := _player.get_stream_playback()
	if playback == null or not playback is AudioStreamGeneratorPlayback:
		return
	var gen_pb := playback as AudioStreamGeneratorPlayback
	_push_pending_frames(gen_pb, turn_gen)
	_track_skips(gen_pb)


func _push_pending_frames(gen_pb: AudioStreamGeneratorPlayback, turn_gen: int) -> void:
	var guard := 0
	while turn_gen == _turn_gen and _pending_read + 2 <= _pending.size() and guard < 16384:
		guard += 1
		var avail := gen_pb.get_frames_available()
		if avail <= 0:
			break
		var pending_frames := (_pending.size() - _pending_read) / 2
		var batch := mini(avail, pending_frames)
		batch = mini(batch, 2048)
		for _i in batch:
			if _pending_read + 2 > _pending.size():
				break
			var lo := int(_pending[_pending_read])
			var hi := int(_pending[_pending_read + 1])
			_pending_read += 2
			var sample := int(lo | (hi << 8))
			if sample >= 32768:
				sample -= 65536
			var f := clampf(float(sample) / 32768.0, -1.0, 1.0)
			if not gen_pb.push_frame(Vector2(f, f)):
				_pending_read -= 2
				break
			_frames_pushed += 1
			if not _playback_started_fired:
				_playback_started_fired = true
				_playback_warmed = true
				if _trace != null:
					_trace.mark("first_pcm_pushed")
				if _on_playback_started.is_valid():
					_on_playback_started.call()


func _track_skips(gen_pb: AudioStreamGeneratorPlayback) -> void:
	var sk := gen_pb.get_skips()
	if sk <= _last_skips:
		return
	var delta := sk - _last_skips
	_last_skips = sk
	if not _playback_started_fired:
		return
	if not _player.playing:
		return
	if not _expecting_pcm:
		return
	if pending_bytes() > 0:
		return
	_credited_underruns += delta


func played_seconds() -> float:
	if _player == null or not _started_playback:
		return 0.0
	return maxf(_player.get_playback_position(), 0.0)


func is_playback_idle(turn_gen: int, synth_done: bool) -> bool:
	if turn_gen != _turn_gen:
		return true
	if not synth_done:
		return false
	if pending_bytes() > 0:
		return false
	if _player == null or not _started_playback:
		return true
	if not _player.playing:
		return true
	# 已全部喂入 PCM 但 Generator 仍可能长期 playing（静音 underrun），
	# 用 playback_position 与已推送帧数对齐，避免 speak() 永不返回。
	if not _expecting_pcm and _frames_pushed > 0:
		var pushed_sec := float(_frames_pushed) / float(maxi(_pcm_rate, 1))
		var played_sec := _player.get_playback_position()
		var tol := _playback_end_tolerance_sec()
		if played_sec + tol < pushed_sec:
			_tail_pad_started_usec = -1
			return false
		var pad_sec := _playback_tail_pad_sec()
		if pad_sec > 0.001:
			if _tail_pad_started_usec < 0:
				_tail_pad_started_usec = Time.get_ticks_usec()
			var elapsed := float(Time.get_ticks_usec() - _tail_pad_started_usec) / 1_000_000.0
			if elapsed < pad_sec:
				return false
		_player.stop()
		return true
	return false


static func _playback_end_tolerance_sec() -> float:
	var raw := OS.get_environment(ENV_PLAYBACK_END_TOLERANCE_MS).strip_edges()
	if raw.is_valid_int():
		return clampf(float(int(raw)) / 1000.0, 0.0, 0.12)
	return DEFAULT_PLAYBACK_END_TOLERANCE_SEC


static func _playback_tail_pad_sec() -> float:
	var raw := OS.get_environment(ENV_PLAYBACK_TAIL_PAD_MS).strip_edges()
	if raw.is_valid_int():
		return clampf(float(int(raw)) / 1000.0, 0.0, 0.45)
	return DEFAULT_PLAYBACK_TAIL_PAD_SEC


func feed_silence_ms(duration_ms: float, turn_gen: int) -> void:
	var ms := clampf(duration_ms, 0.0, 500.0)
	if ms <= 0.0:
		return
	var samples := int(float(_pcm_rate) * ms / 1000.0)
	if samples <= 0:
		return
	var pcm := PackedByteArray()
	pcm.resize(samples * 2)
	feed_pcm(pcm, turn_gen)


func wait_until_idle(turn_gen: int, synth_done: bool, tree: SceneTree, stop_check: Callable) -> bool:
	var frames := 0
	# 长回复可超过 20s；上限约 3 分钟 @60fps，避免永久卡死。
	var max_frames := 10800
	while turn_gen == _turn_gen and frames < max_frames:
		if stop_check.is_valid() and stop_check.call():
			break
		tick(turn_gen)
		if is_playback_idle(turn_gen, synth_done):
			return true
		await tree.process_frame
		frames += 1
	return is_playback_idle(turn_gen, synth_done)


func _trim_pending_if_needed(incoming: int) -> void:
	var live := _pending.size() - _pending_read
	if live + incoming <= max_pending_bytes:
		return
	var drop := live + incoming - max_pending_bytes
	if drop >= live:
		_pending.clear()
		_pending_read = 0
	else:
		_pending_read += drop
		if _pending_read > _pending.size() / 2:
			_compact_pending()


func _compact_pending() -> void:
	if _pending_read <= 0:
		return
	_pending = _pending.slice(_pending_read, _pending.size())
	_pending_read = 0


func _reset_buffers() -> void:
	_pending.clear()
	_pending_read = 0
	_byte_tail.clear()
