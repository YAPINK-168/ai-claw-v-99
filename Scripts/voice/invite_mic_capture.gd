extends Node
class_name InviteMicCapture

## 麦克风采集 + 简单能量门控（不上传时不保留引导语回声）。

const AudioPcmUtil := preload("res://Scripts/voice/audio_pcm_util.gd")
const InviteListenConfig := preload("res://Scripts/voice/invite_listen_config.gd")

signal speech_started()
signal pcm_chunk(pcm: PackedByteArray)

var _mic_player: AudioStreamPlayer
var _capture: AudioEffectCapture
var _mix_rate := 48000
var _active := false
var _float_buf: PackedFloat32Array = PackedFloat32Array()
var _chunk_samples := 0
var _speech_active := false
var _above_count := 0
var _below_count := 0
var _speech_notified := false


func _ready() -> void:
	_ensure_record_bus()
	_mic_player = AudioStreamPlayer.new()
	_mic_player.stream = AudioStreamMicrophone.new()
	_mic_player.bus = "InviteRecord"
	add_child(_mic_player)
	_mix_rate = int(AudioServer.get_mix_rate())
	_chunk_samples = int(float(_mix_rate) * InviteListenConfig.PCM_CHUNK_MS / 1000.0)


func start_capture() -> void:
	if _active:
		return
	_active = true
	_float_buf = PackedFloat32Array()
	_speech_active = false
	_above_count = 0
	_below_count = 0
	_speech_notified = false
	_set_capture_enabled(true)
	if not _mic_player.playing:
		_mic_player.play()
	if _capture != null:
		_capture.clear_buffer()


func stop_capture() -> void:
	_active = false
	if _mic_player.playing:
		_mic_player.stop()
	_discard_capture()
	_set_capture_enabled(false)
	_float_buf = PackedFloat32Array()


func _process(_delta: float) -> void:
	if not _active:
		_discard_capture()
		return
	_flush_capture()


func _flush_capture() -> void:
	if _capture == null:
		return
	var frames := _capture.get_frames_available()
	if frames <= 0:
		return
	var buf: PackedVector2Array = _capture.get_buffer(frames)
	if buf.is_empty():
		return
	var start := _float_buf.size()
	_float_buf.resize(start + buf.size())
	var peak := 0.0
	for i in buf.size():
		var s := (buf[i].x + buf[i].y) * 0.5
		_float_buf[start + i] = s
		peak = maxf(peak, absf(s))
	_update_energy(peak)
	while _float_buf.size() >= _chunk_samples:
		var chunk := PackedFloat32Array()
		chunk.resize(_chunk_samples)
		for i in _chunk_samples:
			chunk[i] = _float_buf[i]
		_float_buf = _float_buf.slice(_chunk_samples)
		# 引导语结束后才开麦；PCM 持续上传 ASR，能量门控仅用于 VAD 起说计时。
		var pcm := AudioPcmUtil.floats_to_pcm16_mono(
			chunk, _mix_rate, InviteListenConfig.SAMPLE_RATE
		)
		pcm_chunk.emit(pcm)


func _update_energy(peak: float) -> void:
	if peak >= InviteListenConfig.ENERGY_THRESHOLD:
		_above_count += 1
		_below_count = 0
		if not _speech_active and _above_count >= InviteListenConfig.ENERGY_START_FRAMES:
			_speech_active = true
			if not _speech_notified:
				_speech_notified = true
				speech_started.emit()
	else:
		_below_count += 1
		_above_count = 0


func _discard_capture() -> void:
	if _capture == null:
		return
	var frames := _capture.get_frames_available()
	if frames > 0:
		_capture.get_buffer(frames)


func _ensure_record_bus() -> void:
	var idx := AudioServer.get_bus_index("InviteRecord")
	if idx < 0:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "InviteRecord")
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
	var idx := AudioServer.get_bus_index("InviteRecord")
	if idx < 0:
		return
	for i in AudioServer.get_bus_effect_count(idx):
		if AudioServer.get_bus_effect(idx, i) is AudioEffectCapture:
			AudioServer.set_bus_effect_enabled(idx, i, on)
			break
