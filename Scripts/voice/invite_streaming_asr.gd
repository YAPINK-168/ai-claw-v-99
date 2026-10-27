extends Node
class_name InviteStreamingAsr

## 阿里云 SpeechTranscriber WebSocket（16kHz PCM）。支持 mock 供自动测试。

signal transcription_started()
signal partial_text(text: String)
signal sentence_end(text: String)
signal session_failed(reason: String)
signal session_closed()

enum State { IDLE, CONNECTING, AWAITING_STARTED, READY, STREAMING, CLOSING }

const InviteListenConfig := preload("res://Scripts/voice/invite_listen_config.gd")
const NlsHexId := preload("res://Scripts/voice/nls_hex_id.gd")
const FormalAsrTurnTraceScript := preload("res://Scripts/voice/formal_asr_turn_trace.gd")

var mock_mode := false

var _config: AliyunNlsConfig
var _tokens: NlsTokenProvider
var _ws: WebSocketPeer
var _state := State.IDLE
var _task_id := ""
var _session_gen := 0
var _ready := false
var _connect_started_ms := 0
var _intentional_close := false
var _start_sent_ms := 0
var _ws_session_gen := 0
var _log_fn: Callable

const CONNECT_TIMEOUT_MS := 15000
const STARTED_TIMEOUT_MS := 12000


func setup(config: AliyunNlsConfig, tokens: NlsTokenProvider, log_fn: Callable = Callable()) -> void:
	_config = config
	_tokens = tokens
	_log_fn = log_fn


func is_ready() -> bool:
	return _ready and (_state == State.READY or _state == State.STREAMING)


func get_state_name() -> String:
	return State.keys()[_state]


func get_current_task_id() -> String:
	return _task_id


func begin_preconnect() -> void:
	FormalAsrTurnTraceScript.refresh_from_env()
	if mock_mode:
		_session_gen += 1
		var gen := _session_gen
		_state = State.CONNECTING
		_log("ws_connect_begin mock")
		FormalAsrTurnTraceScript.log("ws_connect_begin", {
			"ws_gen": _ws_session_gen,
			"session_gen": gen,
			"mock": true,
		})
		call_deferred("_mock_ready", gen)
		return
	if _state == State.READY or _state == State.STREAMING:
		return
	if _state == State.CONNECTING:
		_log("ws_connect_in_progress")
		return
	if _state != State.IDLE and _state != State.CLOSING:
		return
	_session_gen += 1
	var gen := _session_gen
	_state = State.CONNECTING
	_ready = false
	_connect_started_ms = Time.get_ticks_msec()
	_log("ws_connect_begin")
	FormalAsrTurnTraceScript.log("ws_connect_begin", {
		"ws_gen": _ws_session_gen,
		"session_gen": gen,
		"mock": false,
	})
	_connect_async(gen)


func begin_stream() -> void:
	if _state == State.READY:
		_state = State.STREAMING
		_log("stream_begin")


## 仅发送 StopTranscription，保持 WebSocket 会话供下一轮复用（正式 AI 单句结束）。
var last_pcm_sent_msec := -1
var last_pcm_sent_bytes := 0
var utterance_end_msec := -1
var sent_pcm_bytes := 0


func request_utterance_end() -> void:
	utterance_end_msec = Time.get_ticks_msec()
	print(
		"asr_utterance_end last_pcm_msec=%d last_pcm_bytes=%d end_msec=%d sent_bytes=%d"
		% [last_pcm_sent_msec, last_pcm_sent_bytes, utterance_end_msec, sent_pcm_bytes]
	)
	if _ws == null:
		return
	if _state == State.STREAMING or _state == State.READY:
		_send_stop()
		_log("utterance_end_requested")


func send_pcm(pcm: PackedByteArray) -> void:
	if pcm.is_empty():
		return
	if mock_mode:
		_note_pcm_sent(pcm)
		return
	if _ws == null or _state != State.STREAMING:
		return
	if _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	_ws.send(pcm)
	_note_pcm_sent(pcm)


func _note_pcm_sent(pcm: PackedByteArray) -> void:
	last_pcm_sent_msec = Time.get_ticks_msec()
	last_pcm_sent_bytes = pcm.size()
	sent_pcm_bytes += pcm.size()


func force_reconnect() -> void:
	FormalAsrTurnTraceScript.log("force_reconnect", {
		"ws_gen": _ws_session_gen,
		"task_id_len": _task_id.length(),
	})
	if mock_mode:
		stop_session()
		begin_preconnect()
		return
	_intentional_close = true
	stop_session()
	_intentional_close = false
	begin_preconnect()


func stop_session() -> void:
	var gen := _session_gen
	_session_gen += 1
	_ws_session_gen = _session_gen
	_intentional_close = true
	if mock_mode:
		_state = State.IDLE
		_ready = false
		_intentional_close = false
		session_closed.emit()
		return
	if _ws != null and _state != State.IDLE:
		_state = State.CLOSING
		if _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
			_send_stop()
		_ws.close()
	else:
		_state = State.IDLE
		_ready = false
		_intentional_close = false
	_ws = null
	if gen == _session_gen:
		session_closed.emit()


func inject_mock_partial(text: String, final_line: bool = false) -> void:
	if not mock_mode:
		return
	partial_text.emit(text)
	if final_line:
		sentence_end.emit(text)


func _process(_delta: float) -> void:
	if mock_mode:
		return
	if _state == State.CONNECTING and _connect_started_ms > 0:
		if Time.get_ticks_msec() - _connect_started_ms > CONNECT_TIMEOUT_MS:
			_log("ws_connect_timeout phase=CONNECTING")
			_emit_session_failed("connect_timeout")
			stop_session()
			return
	if _state == State.AWAITING_STARTED and _start_sent_ms > 0:
		if Time.get_ticks_msec() - _start_sent_ms > STARTED_TIMEOUT_MS:
			_log("ws_started_timeout phase=AWAITING_STARTED")
			_emit_session_failed("started_timeout")
			stop_session()
			return
	if _ws == null:
		return
	_ws.poll()
	var state := _ws.get_ready_state()
	if _ws == null:
		return
	if state == WebSocketPeer.STATE_CLOSED:
		var code := _ws.get_close_code()
		var reason := _sanitize_close_reason(_ws.get_close_reason())
		if _intentional_close or _state == State.CLOSING:
			_log("ws_closed_intentional code=%s reason=%s" % [str(code), reason])
			_state = State.IDLE
			_ready = false
			_intentional_close = false
			return
		if _state != State.IDLE:
			_log(
				"ws_closed_unexpected code=%s reason=%s phase=%s ready=%s"
				% [str(code), reason, get_state_name(), str(_ready)]
			)
			_emit_session_failed("websocket_closed")
			stop_session()
		return
	while _ws != null and _ws.get_available_packet_count() > 0:
		var pkt := _ws.get_packet()
		if _ws == null:
			return
		if _ws.was_string_packet():
			_handle_json(pkt.get_string_from_utf8())
		elif _ws != null:
			_log("ws_binary_frame len=%d" % pkt.size())


func _connect_async(gen: int) -> void:
	if _config == null or _tokens == null:
		_emit_session_failed("missing_config")
		return
	var token: String = await _tokens.get_token()
	if gen != _session_gen:
		return
	if token.is_empty():
		_emit_session_failed("token_failed")
		return
	_ws = WebSocketPeer.new()
	var url := _config.get_realtime_ws_url(token)
	_log("ws_endpoint=%s" % _safe_ws_endpoint(url))
	var err := _ws.connect_to_url(url)
	if err != OK:
		_emit_session_failed("connect_err_%s" % err)
		_ws = null
		_state = State.IDLE
		return
	_log("ws_connect_sent token_len=%d appkey_set=%s" % [
		token.length(),
		str(not _config.app_key.strip_edges().is_empty()),
	])
	while gen == _session_gen and _ws != null:
		_ws.poll()
		if _ws == null:
			return
		var rs := _ws.get_ready_state()
		if rs == WebSocketPeer.STATE_OPEN:
			_task_id = NlsHexId.new_id32()
			var send_err := _send_start()
			_state = State.AWAITING_STARTED
			_start_sent_ms = Time.get_ticks_msec()
			_log("ws_open start_sent send_err=%s task_id_len=%d" % [str(send_err), _task_id.length()])
			FormalAsrTurnTraceScript.log("ws_connect_open", {
				"ws_gen": _ws_session_gen,
				"task_id_len": _task_id.length(),
			})
			return
		if rs == WebSocketPeer.STATE_CLOSED:
			var code := _ws.get_close_code()
			var reason := _sanitize_close_reason(_ws.get_close_reason())
			_log("ws_connect_closed code=%s reason=%s" % [str(code), reason])
			_emit_session_failed("connect_closed")
			stop_session()
			return
		await get_tree().process_frame


func _send_start() -> int:
	var message_id := NlsHexId.new_id32()
	var msg := {
		"header": {
			"appkey": _config.app_key,
			"message_id": message_id,
			"namespace": "SpeechTranscriber",
			"name": "StartTranscription",
			"task_id": _task_id,
		},
		"payload": {
			"format": "pcm",
			"sample_rate": InviteListenConfig.SAMPLE_RATE,
			"enable_intermediate_result": true,
			"enable_punctuation_prediction": true,
			"enable_inverse_text_normalization": true,
		},
	}
	return _ws.send_text(JSON.stringify(msg))


func _send_stop() -> void:
	if _ws == null:
		return
	var msg := {
		"header": {
			"appkey": _config.app_key,
			"message_id": NlsHexId.new_id32(),
			"namespace": "SpeechTranscriber",
			"name": "StopTranscription",
			"task_id": _task_id,
		},
		"payload": {},
	}
	_ws.send_text(JSON.stringify(msg))


func _handle_json(raw: String) -> void:
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		_log("ws_event parse_failed len=%d" % raw.length())
		return
	var header: Dictionary = parsed.get("header", {})
	var name := String(header.get("name", ""))
	var status := int(header.get("status", 0))
	var status_text := _sanitize_status_text(String(
		header.get("status_text", header.get("status_message", ""))
	))
	var payload: Dictionary = parsed.get("payload", {})
	_log("ws_event name=%s status=%s text=%s" % [name, str(status), status_text])
	match name:
		"TranscriptionStarted":
			_ready = true
			_state = State.READY
			_start_sent_ms = 0
			_log("transcription_started")
			FormalAsrTurnTraceScript.log("asr_ready", {
				"ws_gen": _ws_session_gen,
				"task_id_len": _task_id.length(),
			})
			transcription_started.emit()
		"TranscriptionResultChanged":
			var text := String(payload.get("result", "")).strip_edges()
			if not text.is_empty():
				partial_text.emit(text)
		"SentenceEnd":
			var text := String(payload.get("result", "")).strip_edges()
			FormalAsrTurnTraceScript.log("sentence_end_wire", {
				"ws_gen": _ws_session_gen,
				"text_len": text.length(),
			})
			sentence_end.emit(text)
		"TaskFailed":
			var msg := status_text
			if msg.is_empty():
				msg = String(payload.get("message", "task_failed"))
			_emit_session_failed("task_failed:%s" % msg)
		"TranscriptionCompleted":
			session_closed.emit()
		_:
			if not name.is_empty():
				_log("ws_event_unhandled name=%s" % name)


func debug_simulate_task_failed(message: String) -> void:
	if not mock_mode:
		return
	_handle_json(JSON.stringify({
		"header": {
			"name": "TaskFailed",
			"status": 40000002,
			"status_text": message,
		},
		"payload": {"message": message},
	}))


func debug_simulate_unexpected_close() -> void:
	if not mock_mode:
		return
	_emit_session_failed("websocket_closed")


func get_ws_session_gen() -> int:
	return _ws_session_gen


func _mock_ready(gen: int) -> void:
	await get_tree().create_timer(0.05).timeout
	if gen != _session_gen:
		return
	_ready = true
	_state = State.READY
	_log("transcription_started mock")
	transcription_started.emit()


func _emit_session_failed(reason: String) -> void:
	_ws_session_gen = _session_gen
	session_failed.emit(reason)


func _safe_ws_endpoint(url: String) -> String:
	var base := url.split("?")[0]
	return base.strip_edges()


func _sanitize_close_reason(reason: String) -> String:
	var t := reason.strip_edges()
	if t.is_empty():
		return "(empty)"
	if t.length() > 120:
		t = t.substr(0, 120) + "…"
	if t.to_lower().contains("token"):
		return "(redacted)"
	return t


func _sanitize_status_text(text: String) -> String:
	var t := text.strip_edges()
	if t.length() > 160:
		t = t.substr(0, 160) + "…"
	return t


func _log(msg: String) -> void:
	if _log_fn.is_valid():
		_log_fn.call(msg)
