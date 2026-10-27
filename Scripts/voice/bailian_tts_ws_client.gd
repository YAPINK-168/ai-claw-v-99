class_name BailianTtsWsClient
extends Node

## 百炼 Qwen-Audio-TTS WebSocket 流式合成（Phase3-C1 隔离 + Phase3-C2 VoiceOutput 分片回调）。

const BailianTtsConfigScript := preload("res://Scripts/voice/bailian_tts_config.gd")
const NlsHexId := preload("res://Scripts/voice/nls_hex_id.gd")
const AudioBytesUtilScript := preload("res://Scripts/voice/audio_bytes_util.gd")
const StreamTtsPlaybackTraceScript := preload("res://Scripts/voice/stream_tts_playback_trace.gd")

const CONNECT_TIMEOUT_MS := 15000
const TASK_TIMEOUT_MS := 45000
const MAX_PCM_BYTES := 8 * 1024 * 1024
const MIN_PCM_PLAYABLE_BYTES := 4800

enum State { IDLE, CONNECTING, AWAIT_TASK_STARTED, STREAMING, AWAIT_TASK_FINISHED, FAILED }

var mock_mode := false
## Mock：单分句 PCM 时长（秒），用于生命周期 / 排空测试。
var mock_pcm_duration_sec: float = 0.12

var _config: BailianTtsConfigScript
var _ws: WebSocketPeer
var _state := State.IDLE
var _session_epoch := 0
var _task_id := ""
var _connect_started_ms := 0
var _ws_open_ms := 0
var _task_started_ms := 0
var _first_binary_ms := -1
var _first_playable_ms := -1
var _finish_ms := -1
var _pcm := PackedByteArray()
var _awaiting: Array = []
var _last_error := ""
var _task_failed_reason := ""
var _stale_binary_drops := 0
var _on_pcm_chunk: Callable = Callable()
var _active_speak_gen := -1
var _first_chunk_cb_fired := false
var _trace: StreamTtsPlaybackTraceScript
var _continue_sent := false


func _ready() -> void:
	set_process(true)


func setup(config: BailianTtsConfigScript) -> void:
	_config = config


func set_stream_trace(trace: StreamTtsPlaybackTraceScript) -> void:
	_trace = trace


func cancel() -> void:
	_session_epoch += 1
	_on_pcm_chunk = Callable()
	_active_speak_gen = -1
	_reset_task_state()
	if _ws != null:
		_ws.close()
	_ws = null
	_state = State.IDLE


## 流式合成：每收到二进制 PCM 即调用 on_pcm_chunk(PackedByteArray)；turn_epoch 与 cancel 联动失效。
func synthesize_pcm_stream(
	text: String,
	instruction: String = "",
	speak_gen: int = 0,
	on_pcm_chunk: Callable = Callable(),
	reuse_connection: bool = false,
) -> Dictionary:
	_active_speak_gen = speak_gen
	_on_pcm_chunk = on_pcm_chunk
	_first_chunk_cb_fired = false
	var result: Dictionary = await synthesize_pcm(text, instruction, reuse_connection)
	_on_pcm_chunk = Callable()
	return result


## 返回 metrics 字典 + ok + pcm + error；metrics 含 connect_ms, first_audio_frame_ms, playable_ms, total_ms 等。
func synthesize_pcm(text: String, instruction: String = "", reuse_connection: bool = false) -> Dictionary:
	var empty_metrics := _empty_metrics()
	if text.strip_edges().is_empty():
		return {"ok": false, "pcm": PackedByteArray(), "error": "empty_text", "metrics": empty_metrics}
	if mock_mode:
		return await _mock_synthesize(text)
	if _config == null:
		return {"ok": false, "pcm": PackedByteArray(), "error": "missing_config", "metrics": empty_metrics}
	var cfg_err := _config.validate_for_tts()
	if not cfg_err.is_empty():
		return {"ok": false, "pcm": PackedByteArray(), "error": cfg_err, "metrics": empty_metrics}
	var ws_url := _config.get_websocket_inference_url()
	if ws_url.is_empty():
		return {"ok": false, "pcm": PackedByteArray(), "error": "missing_ws_url", "metrics": empty_metrics}

	var epoch := _session_epoch
	_reset_task_state()
	_task_id = NlsHexId.new_id32()
	_connect_started_ms = Time.get_ticks_msec()
	_continue_sent = false
	if _trace != null and (not reuse_connection or _ws == null or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN):
		_trace.mark("ws_connect_start")

	if not reuse_connection or _ws == null or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		if _ws != null:
			_ws.close()
			_ws = null
		if not await _connect_ws(ws_url, epoch):
			return {"ok": false, "pcm": PackedByteArray(), "error": _last_error, "metrics": _collect_metrics()}

	if epoch != _session_epoch:
		return {"ok": false, "pcm": PackedByteArray(), "error": "cancelled", "metrics": _collect_metrics()}

	_state = State.AWAIT_TASK_STARTED
	_send_run_task(instruction)
	if not await _wait_for_task_started(epoch):
		return {"ok": false, "pcm": PackedByteArray(), "error": _last_error, "metrics": _collect_metrics()}

	_task_started_ms = Time.get_ticks_msec()
	if _trace != null:
		_trace.mark("continue_task_sent")
	_send_continue_task(text)
	_send_finish_task()
	_state = State.AWAIT_TASK_FINISHED

	if not await _wait_for_task_finished(epoch):
		return {"ok": false, "pcm": PackedByteArray(), "error": _last_error, "metrics": _collect_metrics()}

	if _pcm.is_empty():
		return {"ok": false, "pcm": PackedByteArray(), "error": "empty_audio", "metrics": _collect_metrics()}

	_finish_ms = Time.get_ticks_msec()
	return {"ok": true, "pcm": _pcm.duplicate(), "error": "", "metrics": _collect_metrics()}


func preconnect() -> bool:
	if mock_mode:
		return true
	if _config == null:
		return false
	var ws_url := _config.get_websocket_inference_url()
	if ws_url.is_empty():
		return false
	var epoch := _session_epoch
	return await _connect_ws(ws_url, epoch)


func _process(_delta: float) -> void:
	if mock_mode or _ws == null:
		return
	_ws.poll()
	while _ws.get_available_packet_count() > 0:
		var pkt := _ws.get_packet()
		if _ws.was_string_packet():
			_handle_json(pkt.get_string_from_utf8())
		else:
			_handle_binary(pkt)


func _connect_ws(url: String, epoch: int) -> bool:
	_ws = WebSocketPeer.new()
	var key := _config.api_key.strip_edges()
	_ws.set_handshake_headers(PackedStringArray(["Authorization: Bearer %s" % key]))
	var err := _ws.connect_to_url(url)
	if err != OK:
		_last_error = "connect_err_%s" % err
		_state = State.FAILED
		return false
	_state = State.CONNECTING
	var waited := 0
	while epoch == _session_epoch and waited < CONNECT_TIMEOUT_MS:
		_ws.poll()
		var st := _ws.get_ready_state()
		if st == WebSocketPeer.STATE_OPEN:
			_ws_open_ms = Time.get_ticks_msec()
			if _trace != null:
				_trace.mark("ws_connected")
			_state = State.IDLE
			return true
		if st == WebSocketPeer.STATE_CLOSED:
			_last_error = "ws_closed_during_connect"
			return false
		await get_tree().process_frame
		waited += int(get_process_delta_time() * 1000.0)
	_last_error = "connect_timeout"
	return false


func _send_run_task(instruction: String) -> void:
	var params := {
		"text_type": "PlainText",
		"voice": _config.voice.strip_edges(),
		"format": "pcm",
		"sample_rate": _config.sample_rate,
		"volume": 50,
		"rate": 1.0,
		"pitch": 1.0,
		"enable_ssml": false,
	}
	var instr := instruction.strip_edges()
	if instr.is_empty():
		instr = _config.default_instruction.strip_edges()
	var input := {}
	if not instr.is_empty():
		input["instruction"] = instr
	var msg := {
		"header": {
			"action": "run-task",
			"task_id": _task_id,
			"streaming": "duplex",
		},
		"payload": {
			"task_group": "audio",
			"task": "tts",
			"function": "SpeechSynthesizer",
			"model": _config.model.strip_edges(),
			"parameters": params,
			"input": input,
		},
	}
	_ws.send_text(JSON.stringify(msg))


func _send_continue_task(text: String) -> void:
	var msg := {
		"header": {
			"action": "continue-task",
			"task_id": _task_id,
			"streaming": "duplex",
		},
		"payload": {
			"input": {
				"text": text,
			},
		},
	}
	_ws.send_text(JSON.stringify(msg))


func _send_finish_task() -> void:
	var msg := {
		"header": {
			"action": "finish-task",
			"task_id": _task_id,
			"streaming": "duplex",
		},
		"payload": {
			"input": {},
		},
	}
	_ws.send_text(JSON.stringify(msg))


func _handle_json(raw: String) -> void:
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var header: Dictionary = parsed.get("header", {})
	var event := str(header.get("event", "")).strip_edges()
	match event:
		"task-started":
			if _state == State.AWAIT_TASK_STARTED:
				_state = State.STREAMING
				if _trace != null:
					_trace.mark("task_started")
				_resume_waiters(true)
		"task-finished":
			if str(header.get("task_id", "")) == _task_id or _task_id.is_empty():
				_state = State.IDLE
				_resume_waiters(true)
		"task-failed":
			_task_failed_reason = _sanitize_err(raw)
			_state = State.FAILED
			_last_error = "task_failed"
			_resume_waiters(false)
		"result-generated":
			pass


func _handle_binary(data: PackedByteArray) -> void:
	if _state != State.STREAMING and _state != State.AWAIT_TASK_FINISHED:
		_stale_binary_drops += 1
		return
	if data.is_empty():
		return
	if _trace != null and _first_binary_ms < 0:
		_trace.mark("first_pcm_received")
	var now := Time.get_ticks_msec()
	if _first_binary_ms < 0 and _task_started_ms > 0:
		_first_binary_ms = now - _task_started_ms
	if _pcm.size() + data.size() > MAX_PCM_BYTES:
		_last_error = "pcm_buffer_overflow"
		_state = State.FAILED
		_session_epoch += 1
		return
	_pcm.append_array(data)
	if _first_playable_ms < 0 and _pcm.size() >= MIN_PCM_PLAYABLE_BYTES:
		_first_playable_ms = now - _task_started_ms if _task_started_ms > 0 else 0
	if _on_pcm_chunk.is_valid():
		_on_pcm_chunk.call(data.duplicate(), _active_speak_gen)
		_first_chunk_cb_fired = true


func _wait_for_task_started(epoch: int) -> bool:
	return await _wait_until(
		epoch,
		func() -> bool: return _state == State.STREAMING or _state == State.FAILED,
		CONNECT_TIMEOUT_MS,
		"task_started_timeout",
	)


func _wait_for_task_finished(epoch: int) -> bool:
	return await _wait_until(
		epoch,
		func() -> bool: return _state == State.IDLE or _state == State.FAILED,
		TASK_TIMEOUT_MS,
		"task_finished_timeout",
	)


func _wait_until(epoch: int, done: Callable, timeout_ms: int, timeout_err: String) -> bool:
	var waited := 0
	while epoch == _session_epoch and waited < timeout_ms:
		if done.call():
			if _state == State.FAILED:
				if _last_error.is_empty():
					_last_error = _task_failed_reason if not _task_failed_reason.is_empty() else "task_failed"
				return false
			return true
		await get_tree().process_frame
		waited += int(get_process_delta_time() * 1000.0)
	_last_error = timeout_err
	return false


func _resume_waiters(_ok: bool) -> void:
	for w in _awaiting:
		if w is Array and (w as Array).size() > 0:
			(w as Array)[0] = true
	_awaiting.clear()


func _reset_task_state() -> void:
	_task_id = ""
	_pcm.clear()
	_first_binary_ms = -1
	_first_playable_ms = -1
	_finish_ms = -1
	_task_started_ms = 0
	_task_failed_reason = ""
	_stale_binary_drops = 0
	if _state != State.CONNECTING:
		_state = State.IDLE


func _collect_metrics() -> Dictionary:
	var connect_ms := -1.0
	if _connect_started_ms > 0 and _ws_open_ms > 0:
		connect_ms = float(_ws_open_ms - _connect_started_ms)
	var total_ms := -1.0
	if _connect_started_ms > 0 and _finish_ms > 0:
		total_ms = float(_finish_ms - _connect_started_ms)
	elif _connect_started_ms > 0:
		total_ms = float(Time.get_ticks_msec() - _connect_started_ms)
	return {
		"connect_ms": connect_ms,
		"first_audio_frame_ms": float(_first_binary_ms) if _first_binary_ms >= 0 else null,
		"playable_pcm_ms": float(_first_playable_ms) if _first_playable_ms >= 0 else null,
		"total_ms": total_ms,
		"pcm_bytes": _pcm.size(),
		"stale_binary_drops": _stale_binary_drops,
		"decode_ok": _pcm.size() > 0 and AudioBytesUtilScript.pcm16_mono_stream(_pcm, _config.sample_rate if _config else 24000) != null,
	}


func _empty_metrics() -> Dictionary:
	return {
		"connect_ms": null,
		"first_audio_frame_ms": null,
		"playable_pcm_ms": null,
		"total_ms": null,
		"pcm_bytes": 0,
		"stale_binary_drops": 0,
		"decode_ok": false,
	}


func _sanitize_err(raw: String) -> String:
	if raw.length() > 160:
		return raw.substr(0, 160) + "…"
	if raw.to_lower().contains("sk-"):
		return "(redacted)"
	return raw


func _mock_synthesize(text: String) -> Dictionary:
	var epoch := _session_epoch
	await get_tree().create_timer(0.04).timeout
	if epoch != _session_epoch:
		return {"ok": false, "pcm": PackedByteArray(), "error": "cancelled", "metrics": _empty_metrics()}
	var rate := 24000
	var dur := maxf(mock_pcm_duration_sec, 0.05)
	var samples := maxi(int(rate * dur), 1200)
	var pcm := PackedByteArray()
	pcm.resize(samples * 2)
	if _on_pcm_chunk.is_valid():
		var part := samples / 3
		for i in 3:
			if epoch != _session_epoch:
				return {"ok": false, "pcm": PackedByteArray(), "error": "cancelled", "metrics": _empty_metrics()}
			var slice := pcm.slice(i * part * 2, mini((i + 1) * part * 2, pcm.size()))
			_on_pcm_chunk.call(slice, _active_speak_gen)
			await get_tree().create_timer(0.01).timeout
	_finish_ms = Time.get_ticks_msec()
	return {
		"ok": true,
		"pcm": pcm,
		"error": "",
		"metrics": {
			"connect_ms": 40.0,
			"first_audio_frame_ms": 55.0,
			"playable_pcm_ms": 60.0,
			"total_ms": 80.0,
			"pcm_bytes": pcm.size(),
			"stale_binary_drops": 0,
			"decode_ok": AudioBytesUtilScript.pcm16_mono_stream(pcm, rate) != null,
		},
	}
