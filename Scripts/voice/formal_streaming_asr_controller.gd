extends Node
class_name FormalStreamingAsrController

## 正式 AI 流式 ASR：复用 InviteStreamingAsr 协议，不混入邀请业务状态。

const InviteStreamingAsrScript := preload("res://Scripts/voice/invite_streaming_asr.gd")
const SpeechInputScript := preload("res://Scripts/voice/speech_input.gd")
const InviteListenConfig := preload("res://Scripts/voice/invite_listen_config.gd")
const VoiceTurnLatencyScript := preload("res://Scripts/voice/voice_turn_latency.gd")
const FormalAsrTurnTraceScript := preload("res://Scripts/voice/formal_asr_turn_trace.gd")

const FINAL_WAIT_SEC := 2.5
const PRECONNECT_WAIT_SEC := 8.0

var _asr: InviteStreamingAsrScript
var _speech: SpeechInputScript
var _latency: VoiceTurnLatencyScript
var _log_fn: Callable

var _feature_enabled := false
var _session_gen := -1
var _turn_gen := 0
var _stream_open := false
var _pcm_pending: Array = []
var _pcm_delivering := false
var _bound_asr_ws_gen := -1
var _final_text := ""
var _awaiting_final := false
var _finalize_turn_gen := -1
var _rest_consumed_turn_gen := -1
var _rest_in_progress := false
var _ws_result_committed := false
var _last_full_pcm := PackedByteArray()
var _last_sample_rate := InviteListenConfig.SAMPLE_RATE
var _session_rest_fallback_count := 0
var _stale_callback_drops := 0
var _utterance_end_sent_usec := -1
var _turn_ws_failed := false
## Headless：mock ASR 时 finalize 返回此文本（不调用 REST）。
var mock_stream_result := "你好"
## 仅测试：覆盖 FINAL_WAIT_SEC（秒），-1 表示使用默认。
var debug_final_wait_sec: float = -1.0


func setup(asr: InviteStreamingAsrScript, speech: SpeechInputScript) -> void:
	_asr = asr
	_speech = speech
	if _asr != null:
		if not _asr.transcription_started.is_connected(_on_transcription_started):
			_asr.transcription_started.connect(_on_transcription_started)
		if not _asr.sentence_end.is_connected(_on_sentence_end):
			_asr.sentence_end.connect(_on_sentence_end)
		if not _asr.session_failed.is_connected(_on_session_failed):
			_asr.session_failed.connect(_on_session_failed)
		if not _asr.session_closed.is_connected(_on_session_closed):
			_asr.session_closed.connect(_on_session_closed)


func set_log_fn(fn: Callable) -> void:
	_log_fn = fn


func set_latency_tracker(tracker: VoiceTurnLatencyScript) -> void:
	_latency = tracker


func set_feature_enabled(on: bool) -> void:
	_feature_enabled = on
	if not on:
		cancel_active_turn(true)


func is_feature_enabled() -> bool:
	return _feature_enabled


func on_session_started(session_gen: int) -> void:
	_session_gen = session_gen
	_session_rest_fallback_count = 0
	_stale_callback_drops = 0
	if _feature_enabled and _asr != null:
		var t0 := Time.get_ticks_usec()
		_asr.begin_preconnect()
		_log_struct({
			"event": "preconnect_begin",
			"session_gen": session_gen,
		})
		_run_log_preconnect_async(session_gen, t0)


func on_session_stopped() -> void:
	cancel_active_turn(true)
	_session_gen = -1
	if _asr != null:
		_asr.stop_session()
	_log_struct({"event": "session_stopped"})


func on_vad_speech_started(turn_session_gen: int, preroll_pcm: Array) -> void:
	if not _feature_enabled or _asr == null:
		return
	FormalAsrTurnTraceScript.refresh_from_env()
	_turn_gen += 1
	_stream_open = false
	_final_text = ""
	_awaiting_final = false
	_finalize_turn_gen = -1
	_ws_result_committed = false
	_turn_ws_failed = false
	_bound_asr_ws_gen = _asr.get_ws_session_gen()
	for chunk in preroll_pcm:
		if chunk is PackedByteArray and not (chunk as PackedByteArray).is_empty():
			_pcm_pending.append(chunk)
	_log_struct({
		"event": "utterance_vad_start",
		"session_gen": turn_session_gen,
		"turn_gen": _turn_gen,
		"ws_gen": _bound_asr_ws_gen,
	})
	FormalAsrTurnTraceScript.log("vad_speech_started", _trace(turn_session_gen, _turn_gen, {
		"asr_ready": _asr.is_ready(),
	}))
	_open_stream_for_turn(turn_session_gen)


func push_pcm(pcm: PackedByteArray) -> void:
	if not _feature_enabled or pcm.is_empty() or _asr == null:
		return
	if _stream_open:
		_asr.send_pcm(pcm)
		return
	_pcm_pending.append(pcm)
	while _pcm_pending.size() > 24:
		_pcm_pending.pop_front()


func cancel_active_turn(full_stop: bool = false) -> void:
	var prev_turn := _turn_gen
	_turn_gen += 1
	_stream_open = false
	_awaiting_final = false
	_finalize_turn_gen = -1
	_final_text = ""
	_pcm_pending.clear()
	_pcm_delivering = false
	_bound_asr_ws_gen = -1
	if full_stop and _asr != null:
		_asr.stop_session()
	_log_struct({
		"event": "turn_cancelled",
		"prev_turn_gen": prev_turn,
		"turn_gen": _turn_gen,
		"full_stop": full_stop,
	})


func finalize_utterance(
	full_pcm: PackedByteArray,
	sample_rate: int,
	turn_session_gen: int,
) -> String:
	if not _feature_enabled or _asr == null or _speech == null:
		return ""
	if turn_session_gen != _session_gen:
		return ""
	var my_turn := _turn_gen
	_finalize_turn_gen = my_turn
	_ws_result_committed = false
	if _asr != null:
		_bound_asr_ws_gen = _asr.get_ws_session_gen()
	_last_full_pcm = full_pcm
	_last_sample_rate = sample_rate
	if _latency != null and _latency.enabled:
		_latency.mark_once("asr_start")
	_log_struct({
		"event": "finalize_begin",
		"session_gen": turn_session_gen,
		"turn_gen": my_turn,
		"ws_gen": _bound_asr_ws_gen,
	})
	FormalAsrTurnTraceScript.refresh_from_env()
	FormalAsrTurnTraceScript.reset_anchor()
	FormalAsrTurnTraceScript.log("finalize_begin", _trace(turn_session_gen, my_turn, {
		"pcm_bytes": full_pcm.size(),
		"sample_rate": sample_rate,
	}))
	if not await _deliver_pending_pcm(turn_session_gen, my_turn):
		return ""
	if not _finalize_still_valid(turn_session_gen, my_turn):
		_pcm_pending.clear()
		return ""
	_asr.request_utterance_end()
	FormalAsrTurnTraceScript.log("request_utterance_end", _trace(turn_session_gen, my_turn, {
		"last_pcm_msec": _asr.last_pcm_sent_msec,
		"last_pcm_bytes": _asr.last_pcm_sent_bytes,
		"sent_pcm_bytes": _asr.sent_pcm_bytes,
	}))
	if _asr.mock_mode and not mock_stream_result.strip_edges().is_empty():
		_asr.inject_mock_partial(mock_stream_result, true)
		await get_tree().process_frame
		if not _finalize_still_valid(turn_session_gen, my_turn):
			return ""
		var mock_text := _final_text.strip_edges()
		if mock_text.is_empty():
			mock_text = mock_stream_result.strip_edges()
		_commit_ws_result(mock_text, turn_session_gen, my_turn)
		_close_asr_timing()
		FormalAsrTurnTraceScript.log("asr_final_text_ready", _trace(turn_session_gen, my_turn, {
			"path": "mock_ws",
			"text_len": mock_text.length(),
		}))
		await _finish_utterance_isolate(turn_session_gen, my_turn)
		return mock_text
	_awaiting_final = true
	_utterance_end_sent_usec = Time.get_ticks_usec()
	var waited := 0.0
	var limit := _final_wait_sec()
	while _awaiting_final and waited < limit:
		if not _finalize_still_valid(turn_session_gen, my_turn):
			_awaiting_final = false
			return ""
		await get_tree().process_frame
		waited += get_process_delta_time()
	if _awaiting_final and waited >= limit:
		FormalAsrTurnTraceScript.log("sentence_end_timeout", _trace(turn_session_gen, my_turn, {
			"wait_sec": waited,
			"limit_sec": limit,
		}))
	var text := _final_text.strip_edges()
	if not text.is_empty():
		if not _finalize_still_valid(turn_session_gen, my_turn):
			return ""
		_log_sentence_end_timing(turn_session_gen, my_turn, true)
		FormalAsrTurnTraceScript.log("sentence_end_accepted", _trace(turn_session_gen, my_turn, {
			"text_len": text.length(),
		}))
		_commit_ws_result(text, turn_session_gen, my_turn)
		_close_asr_timing()
		FormalAsrTurnTraceScript.log("asr_final_text_ready", _trace(turn_session_gen, my_turn, {
			"path": "ws",
			"text_len": text.length(),
		}))
		await _finish_utterance_isolate(turn_session_gen, my_turn)
		return text
	if not _finalize_still_valid(turn_session_gen, my_turn):
		return ""
	_log_sentence_end_timing(turn_session_gen, my_turn, false)
	return await _try_rest_fallback_once(turn_session_gen, my_turn)


func _try_rest_fallback_once(turn_session_gen: int, my_turn: int) -> String:
	if not _finalize_still_valid(turn_session_gen, my_turn):
		_close_asr_timing()
		return ""
	if _ws_result_committed:
		_close_asr_timing()
		return ""
	if _turn_ws_failed:
		_log_struct({
			"event": "rest_fallback_skipped",
			"reason": "ws_session_failed",
			"session_gen": turn_session_gen,
			"turn_gen": my_turn,
		})
		_close_asr_timing()
		await _finish_utterance_isolate(turn_session_gen, my_turn)
		return ""
	if _rest_consumed_turn_gen == my_turn:
		_log_struct({
			"event": "rest_fallback_skipped",
			"reason": "already_used_this_turn",
			"session_gen": turn_session_gen,
			"turn_gen": my_turn,
		})
		_close_asr_timing()
		return ""
	if _last_full_pcm.is_empty():
		_close_asr_timing()
		return ""
	_rest_consumed_turn_gen = my_turn
	_session_rest_fallback_count += 1
	_rest_in_progress = true
	var reason := "sentence_end_timeout" if _utterance_end_sent_usec >= 0 else "ws_no_result"
	var rest_t0 := Time.get_ticks_usec()
	FormalAsrTurnTraceScript.log("rest_fallback_begin", _trace(turn_session_gen, my_turn, {
		"reason": reason,
	}))
	_log_struct({
		"event": "rest_fallback_begin",
		"reason": reason,
		"session_gen": turn_session_gen,
		"turn_gen": my_turn,
		"session_rest_count": _session_rest_fallback_count,
	})
	var text := await _speech.recognize_pcm16(_last_full_pcm, _last_sample_rate)
	_rest_in_progress = false
	FormalAsrTurnTraceScript.log("rest_fallback_end", _trace(turn_session_gen, my_turn, {
		"rest_ms": float(Time.get_ticks_usec() - rest_t0) / 1000.0,
		"text_len": text.strip_edges().length(),
	}))
	if not _finalize_still_valid(turn_session_gen, my_turn):
		_log_struct({
			"event": "rest_fallback_discarded",
			"reason": "turn_or_session_invalid",
			"turn_gen": my_turn,
		})
		_close_asr_timing()
		return ""
	if _ws_result_committed:
		_log_struct({
			"event": "rest_fallback_discarded",
			"reason": "ws_already_committed",
			"turn_gen": my_turn,
		})
		_close_asr_timing()
		return ""
	text = text.strip_edges()
	_log_struct({
		"event": "rest_fallback_done",
		"session_gen": turn_session_gen,
		"turn_gen": my_turn,
		"text_nonempty": not text.is_empty(),
		"session_rest_count": _session_rest_fallback_count,
	})
	_close_asr_timing()
	if not text.is_empty():
		FormalAsrTurnTraceScript.log("asr_final_text_ready", _trace(turn_session_gen, my_turn, {
			"path": "rest",
			"text_len": text.length(),
		}))
	await _finish_utterance_isolate(turn_session_gen, my_turn)
	return text


func _deliver_pending_pcm(turn_session_gen: int, my_turn: int) -> bool:
	if turn_session_gen != _session_gen or my_turn != _turn_gen:
		_pcm_pending.clear()
		return false
	if _pcm_pending.is_empty():
		return true
	if _pcm_delivering:
		while _pcm_delivering:
			if turn_session_gen != _session_gen or my_turn != _turn_gen:
				_pcm_pending.clear()
				return false
			await get_tree().process_frame
		return turn_session_gen == _session_gen and my_turn == _turn_gen
	_pcm_delivering = true
	if not _stream_open:
		if not await _ensure_asr_ready(turn_session_gen):
			_pcm_pending.clear()
			_pcm_delivering = false
			return turn_session_gen == _session_gen and my_turn == _turn_gen
		if turn_session_gen != _session_gen or my_turn != _turn_gen:
			_pcm_pending.clear()
			_pcm_delivering = false
			return false
		if _asr != null and _asr.is_ready():
			_asr.begin_stream()
			_stream_open = true
	var batch: Array = _pcm_pending.duplicate()
	_pcm_pending.clear()
	for chunk in batch:
		if turn_session_gen != _session_gen or my_turn != _turn_gen:
			_pcm_delivering = false
			return false
		if _asr != null:
			_asr.send_pcm(chunk)
	_pcm_delivering = false
	return true


func _open_stream_for_turn(turn_session_gen: int) -> void:
	if turn_session_gen != _session_gen or _asr == null:
		return
	_run_open_stream_async(turn_session_gen, _turn_gen)


func _run_open_stream_async(turn_session_gen: int, turn_gen_at_start: int) -> void:
	var t0 := Time.get_ticks_usec()
	if not await _ensure_asr_ready(turn_session_gen):
		return
	if turn_session_gen != _session_gen or turn_gen_at_start != _turn_gen:
		return
	if _asr.is_ready():
		_asr.begin_stream()
		_stream_open = true
		var pre_ms := float(Time.get_ticks_usec() - t0) / 1000.0
		_log_struct({
			"event": "stream_open",
			"session_gen": turn_session_gen,
			"turn_gen": turn_gen_at_start,
			"preconnect_wait_ms": pre_ms,
			"ws_gen": _asr.get_ws_session_gen(),
		})
		if not await _deliver_pending_pcm(turn_session_gen, turn_gen_at_start):
			return


func _ensure_asr_ready(turn_session_gen: int) -> bool:
	if _asr == null:
		return false
	if _asr.is_ready():
		FormalAsrTurnTraceScript.log("asr_ready_immediate", _trace_fields(turn_session_gen, _turn_gen))
		return true
	if not _asr.mock_mode:
		_asr.begin_preconnect()
	var waited := 0.0
	var t0 := Time.get_ticks_usec()
	FormalAsrTurnTraceScript.log("preconnect_wait_begin", _trace_fields(turn_session_gen, _turn_gen))
	while waited < PRECONNECT_WAIT_SEC:
		if turn_session_gen != _session_gen:
			return false
		if _asr.is_ready():
			_log_struct({
				"event": "preconnect_ready",
				"session_gen": turn_session_gen,
				"preconnect_ms": float(Time.get_ticks_usec() - t0) / 1000.0,
				"ws_gen": _asr.get_ws_session_gen(),
			})
			return true
		await get_tree().process_frame
		waited += get_process_delta_time()
	var ok := _asr.is_ready()
	var pre_ms := float(Time.get_ticks_usec() - t0) / 1000.0
	FormalAsrTurnTraceScript.log(
		"preconnect_wait_done" if ok else "preconnect_wait_timeout",
		_trace(turn_session_gen, _turn_gen, {"preconnect_ms": pre_ms, "ok": ok})
	)
	_log_struct({
		"event": "preconnect_ready" if ok else "preconnect_timeout",
		"session_gen": turn_session_gen,
		"preconnect_ms": pre_ms,
		"ws_gen": _asr.get_ws_session_gen() if _asr != null else -1,
	})
	return ok


func _on_transcription_started() -> void:
	_log_struct({
		"event": "ws_transcription_started",
		"session_gen": _session_gen,
		"ws_gen": _asr.get_ws_session_gen() if _asr != null else -1,
	})


func _on_sentence_end(text: String) -> void:
	var accept := _accept_sentence_end_event()
	if not accept:
		_stale_callback_drops += 1
		_log_struct({
			"event": "stale_callback_dropped",
			"kind": "sentence_end",
			"drop_count": _stale_callback_drops,
			"turn_gen": _turn_gen,
			"finalize_turn_gen": _finalize_turn_gen,
			"awaiting_final": _awaiting_final,
		})
		return
	if _rest_in_progress:
		_stale_callback_drops += 1
		_log_struct({
			"event": "stale_callback_dropped",
			"kind": "sentence_end_during_rest",
			"drop_count": _stale_callback_drops,
		})
		return
	_final_text = text
	_awaiting_final = false
	FormalAsrTurnTraceScript.log("sentence_end_callback", _trace(_session_gen, _finalize_turn_gen, {
		"text_len": text.length(),
	}))


func _on_session_failed(reason: String) -> void:
	if not _feature_enabled or _session_gen < 0:
		return
	var accepted := _accept_asr_event_for_turn()
	if not accepted:
		_stale_callback_drops += 1
		_log_struct({
			"event": "stale_callback_dropped",
			"kind": "session_failed",
			"reason": reason,
			"drop_count": _stale_callback_drops,
		})
		if _finalize_turn_gen < 0 or _turn_gen == _finalize_turn_gen:
			_turn_ws_failed = true
			_awaiting_final = false
			_stream_open = false
		return
	_awaiting_final = false
	_stream_open = false
	_turn_ws_failed = true
	_log_struct({
		"event": "ws_session_failed",
		"reason": reason,
		"session_gen": _session_gen,
		"turn_gen": _turn_gen,
		"finalize_turn_gen": _finalize_turn_gen,
	})


func _on_session_closed() -> void:
	_stream_open = false


func _accept_sentence_end_event() -> bool:
	if not _accept_asr_event_for_turn():
		return false
	if not _awaiting_final:
		return false
	if _finalize_turn_gen < 0 or _turn_gen != _finalize_turn_gen:
		return false
	return true


func _accept_asr_event_for_turn() -> bool:
	if _asr == null or not _feature_enabled:
		return false
	if _bound_asr_ws_gen >= 0 and _asr.get_ws_session_gen() != _bound_asr_ws_gen:
		return false
	if _finalize_turn_gen >= 0 and _turn_gen != _finalize_turn_gen:
		return false
	return true


func _finalize_still_valid(turn_session_gen: int, my_turn: int) -> bool:
	if turn_session_gen != _session_gen:
		return false
	if _turn_gen != my_turn:
		return false
	return true


func _commit_ws_result(_text: String, turn_session_gen: int, my_turn: int) -> void:
	if not _finalize_still_valid(turn_session_gen, my_turn):
		return
	_ws_result_committed = true
	_awaiting_final = false


func _finish_utterance_isolate(turn_session_gen: int, my_turn: int) -> void:
	if _experimental_defer_isolate():
		FormalAsrTurnTraceScript.log("isolate_reconnect_deferred", _trace_fields(turn_session_gen, my_turn))
		call_deferred("_deferred_isolate_async", turn_session_gen)
	else:
		await _isolate_ws_after_utterance(turn_session_gen)


func _deferred_isolate_async(turn_session_gen: int) -> void:
	await _isolate_ws_after_utterance(turn_session_gen)


static func _experimental_defer_isolate() -> bool:
	var v := OS.get_environment("YOUYOU_ASR_DEFER_ISOLATE").strip_edges().to_lower()
	return v in ["1", "true", "yes", "on"]


func _isolate_ws_after_utterance(turn_session_gen: int) -> void:
	if not _feature_enabled or _asr == null:
		return
	if turn_session_gen != _session_gen:
		return
	var prev_ws := _asr.get_ws_session_gen()
	FormalAsrTurnTraceScript.log("force_reconnect_begin", _trace(turn_session_gen, _turn_gen, {
		"prev_ws_gen": prev_ws,
	}))
	var t0 := Time.get_ticks_usec()
	_asr.force_reconnect()
	await get_tree().process_frame
	FormalAsrTurnTraceScript.log("force_reconnect_done", _trace(turn_session_gen, _turn_gen, {
		"prev_ws_gen": prev_ws,
		"new_ws_gen": _asr.get_ws_session_gen(),
		"isolate_ms": float(Time.get_ticks_usec() - t0) / 1000.0,
		"asr_ready": _asr.is_ready(),
	}))
	_log_struct({
		"event": "ws_isolate_reconnect",
		"session_gen": turn_session_gen,
		"prev_ws_gen": prev_ws,
		"new_ws_gen": _asr.get_ws_session_gen(),
	})


func _trace_fields(session_gen: int, turn_gen: int) -> Dictionary:
	var ws_gen := _asr.get_ws_session_gen() if _asr != null else -1
	var task_len := _asr.get_current_task_id().length() if _asr != null else 0
	return {
		"session_gen": session_gen,
		"turn_gen": turn_gen,
		"ws_gen": ws_gen,
		"task_id_len": task_len,
		"trailing_ms": InviteListenConfig.trailing_silence_ms(),
	}


func _trace(session_gen: int, turn_gen: int, extra: Dictionary = {}) -> Dictionary:
	var d := _trace_fields(session_gen, turn_gen)
	for k in extra.keys():
		d[k] = extra[k]
	return d


func _run_log_preconnect_async(session_gen: int, t0_usec: int) -> void:
	var waited := 0.0
	while waited < PRECONNECT_WAIT_SEC:
		if session_gen != _session_gen:
			return
		if _asr != null and _asr.is_ready():
			_log_struct({
				"event": "session_preconnect_ready",
				"session_gen": session_gen,
				"preconnect_ms": float(Time.get_ticks_usec() - t0_usec) / 1000.0,
				"ws_gen": _asr.get_ws_session_gen(),
			})
			return
		await get_tree().process_frame
		waited += get_process_delta_time()


func _log_sentence_end_timing(session_gen: int, my_turn: int, text_valid: bool) -> void:
	var ms: Variant = null
	if _utterance_end_sent_usec >= 0:
		ms = float(Time.get_ticks_usec() - _utterance_end_sent_usec) / 1000.0
	_log_struct({
		"event": "sentence_end_wait_done",
		"session_gen": session_gen,
		"turn_gen": my_turn,
		"vad_end_to_sentence_ms": ms,
		"ws_text_valid": text_valid,
	})


func _final_wait_sec() -> float:
	if debug_final_wait_sec >= 0.0:
		return debug_final_wait_sec
	return FINAL_WAIT_SEC


func _close_asr_timing() -> void:
	if _latency != null and _latency.enabled and _latency.has_mark("asr_start"):
		_latency.mark_end("asr_end")


func _log_struct(fields: Dictionary) -> void:
	var parts: PackedStringArray = PackedStringArray()
	parts.append("formal_stream_asr")
	for key in fields.keys():
		var v: Variant = fields[key]
		if v is String and _looks_sensitive(String(v)):
			continue
		parts.append("%s=%s" % [str(key), _format_log_value(v)])
	var line := " ".join(parts)
	if _log_fn.is_valid():
		_log_fn.call(line)
	else:
		print(line)


func _format_log_value(v: Variant) -> String:
	match typeof(v):
		TYPE_BOOL:
			return "true" if v else "false"
		TYPE_FLOAT:
			return "%.1f" % float(v)
		_:
			return str(v)


func _looks_sensitive(s: String) -> bool:
	var lower := s.to_lower()
	return lower.contains("token") or lower.contains("appkey") or lower.contains("secret")
