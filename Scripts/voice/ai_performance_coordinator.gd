extends Node
class_name AiPerformanceCoordinator

## 表现联动测试：持续监听 + 语音事件驱动动作状态（不依赖 ClawBusiness / Precoin）。

const ContinuousCapture := preload("res://Scripts/voice/continuous_utterance_capture.gd")
const VoiceInteractionControllerScript := preload("res://Scripts/voice/voice_interaction_controller.gd")
const SpeechInputScript := preload("res://Scripts/voice/speech_input.gd")
const VisemeProceduralDriverScript := preload("res://Scripts/voice/viseme_procedural_driver.gd")
const PreviewVadEventLog := preload("res://Scripts/voice/preview_vad_event_log.gd")
const VoiceTurnLatencyScript := preload("res://Scripts/voice/voice_turn_latency.gd")
const VoicePipelineBaselineStatsScript := preload("res://Scripts/voice/voice_pipeline_baseline_stats.gd")
const FormalStreamingAsrControllerScript := preload("res://Scripts/voice/formal_streaming_asr_controller.gd")
const VoiceTurnTraceScript := preload("res://Scripts/voice/voice_turn_trace.gd")
const FormalAsrTurnTraceScript := preload("res://Scripts/voice/formal_asr_turn_trace.gd")
const InviteListenConfigScript := preload("res://Scripts/voice/invite_listen_config.gd")

enum PerfState {
	CANCELLED,
	ATTRACT,
	LISTENING,
	AI_SPEAKING,
	RESUME_ATTRACT,
}

signal perf_state_changed(old_state: PerfState, new_state: PerfState)
signal debug_event(tag: String, detail: String)

var _host: Node
var _voice: VoiceInteractionControllerScript
var _speech: SpeechInputScript
var _capture: Node
var _viseme: VisemeProceduralDriverScript

var _state := PerfState.CANCELLED
var _session_gen := 0
var _utterance_busy := false
var _mock_asr_enabled := false
var _mock_asr_text := "你好"
var _session_active := false
## 为 true 时 ATTRACT 不调用 perf_play_attract，由 Precoin 负责招揽（正式场景）。
var precoin_attract_mode := false

var _latency: VoiceTurnLatencyScript
var _stream_asr_ctrl: FormalStreamingAsrControllerScript
var _stream_asr_enabled := false
var _turn_submit_gen := 0


func set_latency_tracker(tracker: VoiceTurnLatencyScript) -> void:
	_latency = tracker


func configure_stream_asr(enabled: bool, controller: FormalStreamingAsrControllerScript) -> void:
	_stream_asr_enabled = enabled
	_stream_asr_ctrl = controller
	if _stream_asr_ctrl != null:
		_stream_asr_ctrl.set_feature_enabled(enabled)
		if _latency != null:
			_stream_asr_ctrl.set_latency_tracker(_latency)


func _use_stream_asr_path() -> bool:
	return _stream_asr_enabled and not _mock_asr_enabled and _stream_asr_ctrl != null


func setup(
	host: Node,
	voice: VoiceInteractionControllerScript,
	speech: SpeechInputScript,
	viseme: VisemeProceduralDriverScript,
	capture_bus: String = "AiPerfVoiceRecord",
) -> void:
	VoiceTurnTraceScript.refresh_from_env()
	_host = host
	_voice = voice
	_speech = speech
	_viseme = viseme
	_capture = ContinuousCapture.new()
	_capture.record_bus_name = capture_bus
	_capture.name = "AiPerfContinuousCapture"
	add_child(_capture)
	_capture.speech_started.connect(_on_speech_started)
	_capture.speech_ended.connect(_on_speech_ended)
	_capture.utterance_rejected.connect(_on_utterance_rejected)
	if _capture.has_signal("pcm_chunk") and not _capture.pcm_chunk.is_connected(_on_capture_pcm_chunk):
		_capture.pcm_chunk.connect(_on_capture_pcm_chunk)
	if _voice != null:
		if not _voice.state_changed.is_connected(_on_voice_state_changed):
			_voice.state_changed.connect(_on_voice_state_changed)
		if not _voice.turn_finished.is_connected(_on_voice_turn_finished):
			_voice.turn_finished.connect(_on_voice_turn_finished)


func get_perf_state() -> PerfState:
	return _state


func get_perf_state_name() -> String:
	return PerfState.keys()[_state]


func get_session_generation() -> int:
	return _session_gen


func is_session_active() -> bool:
	return _session_active


func holds_precoin_schedule() -> bool:
	if not _session_active:
		return false
	if _state in [PerfState.AI_SPEAKING, PerfState.RESUME_ATTRACT, PerfState.LISTENING]:
		return true
	if _utterance_busy:
		return true
	if _voice != null and _voice.is_busy():
		return true
	return false


func debug_enable_mock_asr(text: String = "你好") -> void:
	_mock_asr_enabled = true
	_mock_asr_text = text
	if _capture != null:
		_capture.mock_mode = true


func debug_trigger_mock_utterance() -> void:
	if _capture != null:
		_capture.debug_emit_mock_utterance()


func start_session() -> void:
	if _session_active:
		return
	if _host != null and _host.has_method("preview_ai_may_continuous_listen"):
		if not _host.preview_ai_may_continuous_listen():
			return
	_session_gen += 1
	_session_active = true
	_set_state(PerfState.ATTRACT)
	_capture.start_capture()
	if _stream_asr_ctrl != null and _use_stream_asr_path():
		_stream_asr_ctrl.on_session_started(_session_gen)
	_emit_debug("session_start", "gen=%d" % _session_gen)
	_emit_status("wait_listen", {"reason": "session_start"})


func stop_session(reason: String = "stop") -> void:
	if not _session_active and _state == PerfState.CANCELLED:
		return
	if _latency != null and _latency.enabled and _latency.is_turn_running():
		_latency.abort_turn("session_%s" % reason, _latency_abort_context(reason))
		_emit_latency_abort_summary()
	_emit_status("session_closed", {"reason": reason, "silent": true, "session_gen": _session_gen})
	if _stream_asr_ctrl != null:
		_stream_asr_ctrl.on_session_stopped()
	_turn_submit_gen += 1
	_session_gen += 1
	_session_active = false
	_utterance_busy = false
	_capture.stop_capture()
	_stop_ai_presentation()
	if _voice != null and _voice.is_busy():
		await _voice.cancel_turn()
	_set_state(PerfState.CANCELLED)
	VoicePipelineBaselineStatsScript.record_session_closed(reason)
	_emit_debug("session_stop", reason)


func cancel_turn_preempt(reason: String = "preempt") -> void:
	await stop_session(reason)


func notify_tts_playback_started() -> void:
	if not _session_active:
		return
	VoiceTurnTraceScript.log("tts_first_playback", {"perf_state": get_perf_state_name()})
	_emit_status("playback", {"reason": "tts_playback_started"})
	if _voice != null:
		_voice.notify_tts_playback_started()
	if _voice != null and _voice.get_state() == VoiceInteractionControllerScript.State.SPEAKING:
		_on_ai_speaking_started()


func snapshot() -> Dictionary:
	return {
		"perf_state": get_perf_state_name(),
		"session_active": _session_active,
		"session_gen": _session_gen,
		"utterance_busy": _utterance_busy,
		"voice_state": _voice.get_state_name() if _voice != null else "",
		"capture_listening": _capture != null and _capture.is_active(),
	}


func _set_state(next: PerfState) -> void:
	if _state == next:
		return
	var old := _state
	_state = next
	perf_state_changed.emit(old, next)
	_emit_debug("perf_state", "%s->%s" % [PerfState.keys()[old], PerfState.keys()[next]])
	VoiceTurnTraceScript.log(
		"coordinator_state_changed",
		{"from": PerfState.keys()[old], "to": PerfState.keys()[next]},
	)
	match next:
		PerfState.ATTRACT:
			_utterance_busy = false
			_capture_set_paused(false, true)
			if precoin_attract_mode:
				if _host != null and _host.has_method("perf_resume_precoin_attract"):
					_host.perf_resume_precoin_attract()
			elif _host != null and _host.has_method("perf_play_attract"):
				_host.perf_play_attract()
		PerfState.LISTENING:
			_capture_set_paused(false)
			if _host != null and _host.has_method("perf_play_listen_idle"):
				_host.perf_play_listen_idle()
		PerfState.AI_SPEAKING:
			_capture_set_paused(true)
			if _host != null and _host.has_method("perf_play_ai_speak"):
				_host.perf_play_ai_speak()
			if _viseme != null:
				_viseme.start()
		PerfState.RESUME_ATTRACT:
			_capture_set_paused(true)
			_stop_ai_presentation()
		PerfState.CANCELLED:
			_capture_set_paused(true)
			if _host != null and _host.has_method("perf_clear_presentation"):
				_host.perf_clear_presentation()


func _on_speech_started() -> void:
	if not _session_active or _utterance_busy:
		return
	if _state == PerfState.AI_SPEAKING or _state == PerfState.RESUME_ATTRACT:
		return
	if _voice != null and _voice.is_busy():
		return
	VoiceTurnTraceScript.set_context(_session_gen, _turn_submit_gen)
	VoiceTurnTraceScript.log("speech_started", {"perf_state": get_perf_state_name()})
	PreviewVadEventLog.push("coord_speech_started", {"perf_state": get_perf_state_name()})
	if _latency != null and _latency.enabled:
		_latency.start_turn("continuous")
		_latency.mark_once("vad_start")
	_emit_debug("vad", "speech_started")
	_emit_status("vad_listen", {"reason": "vad_speech_started"})
	_set_state(PerfState.LISTENING)
	if _use_stream_asr_path() and _capture is ContinuousCapture:
		var preroll: Array = (_capture as ContinuousCapture).take_preroll_pcm()
		_stream_asr_ctrl.on_vad_speech_started(_session_gen, preroll)


func _on_capture_pcm_chunk(pcm: PackedByteArray) -> void:
	if not _session_active or _utterance_busy:
		return
	if _state != PerfState.LISTENING:
		return
	if _use_stream_asr_path():
		_stream_asr_ctrl.push_pcm(pcm)


func _on_utterance_rejected(reason: String) -> void:
	PreviewVadEventLog.push("coord_utterance_rejected", {
		"perf_state": get_perf_state_name(),
		"reason": reason,
	})
	_emit_debug("vad", "rejected=" + reason)
	if _state == PerfState.LISTENING and _session_active:
		if _use_stream_asr_path():
			_stream_asr_ctrl.cancel_active_turn(false)
		_set_state(PerfState.ATTRACT)
		_emit_status("wait_listen", {"reason": "utterance_rejected"})


func _on_speech_ended(pcm: PackedByteArray, sample_rate: int) -> void:
	if not _session_active or _utterance_busy:
		return
	if _state != PerfState.LISTENING:
		return
	_utterance_busy = true
	var gen := _session_gen
	_capture_set_paused(true)
	if _latency != null and _latency.enabled:
		if not _latency.is_turn_running():
			_latency.start_turn("continuous")
			_latency.mark_once("vad_start")
		_latency.mark_once("vad_end")
		_latency.mark_once("pcm_ready")
	PreviewVadEventLog.push("coord_speech_ended", {
		"perf_state": get_perf_state_name(),
		"pcm_bytes": pcm.size(),
	})
	FormalAsrTurnTraceScript.refresh_from_env()
	FormalAsrTurnTraceScript.log("vad_speech_ended", {
		"session_gen": gen,
		"pcm_bytes": pcm.size(),
		"sample_rate": sample_rate,
		"trailing_ms": InviteListenConfigScript.trailing_silence_ms(),
	})
	_emit_debug("vad", "speech_ended bytes=%d" % pcm.size())
	_emit_status("asr", {"reason": "vad_speech_ended"})
	var text := ""
	if _mock_asr_enabled:
		if _latency != null and _latency.enabled:
			_latency.mark_once("asr_start")
			_latency.mark_end("asr_end")
		text = _mock_asr_text
	elif _use_stream_asr_path():
		text = await _stream_asr_ctrl.finalize_utterance(pcm, sample_rate, gen)
	else:
		text = await _speech.recognize_pcm16(pcm, sample_rate)
	if gen != _session_gen or not _session_active:
		_utterance_busy = false
		if _use_stream_asr_path():
			_stream_asr_ctrl.cancel_active_turn(false)
		_utterance_busy = false
		if _latency != null and _latency.enabled and _latency.is_turn_running():
			_latency.abort_turn("stale_gen", _latency_abort_context("stale_gen"))
			_emit_latency_abort_summary()
		if _session_active and _state == PerfState.LISTENING:
			_set_state(PerfState.ATTRACT)
		return
	if text.strip_edges().is_empty():
		_utterance_busy = false
		if _latency != null and _latency.enabled and _latency.is_turn_running():
			_latency.finish("asr_empty", true)
		var asr_err := _speech.last_error if _speech != null else ""
		if str(asr_err).strip_edges().is_empty():
			_emit_status("asr_empty", {"reason": "asr_empty"})
		else:
			_emit_status("asr_failed", {"reason": "asr_failed", "fail_kind": "asr", "detail": asr_err})
		if _session_active:
			_set_state(PerfState.ATTRACT)
		return
	if _voice != null:
		_turn_submit_gen += 1
		var submit_id := _turn_submit_gen
		VoiceTurnTraceScript.set_context(_session_gen, submit_id)
		VoiceTurnTraceScript.log("asr_submit", {"text_len": text.length()})
		await _voice.submit_text(text, true)
		if submit_id != _turn_submit_gen:
			_utterance_busy = false
			return
	if gen == _session_gen:
		_utterance_busy = false
	else:
		if _latency != null and _latency.enabled and _latency.is_turn_running():
			_latency.abort_turn("stale_gen", _latency_abort_context("stale_gen"))
			_emit_latency_abort_summary()
		if _session_active and _state in [PerfState.LISTENING, PerfState.AI_SPEAKING]:
			_set_state(PerfState.ATTRACT)


func _latency_abort_context(cancel_reason: String) -> Dictionary:
	var ctx := {
		"cancel_reason": cancel_reason,
		"perf_state": get_perf_state_name(),
		"utterance_busy": _utterance_busy,
		"session_active": _session_active,
	}
	if _speech != null:
		ctx["asr_last_error"] = _speech.last_error
	if _voice != null:
		ctx["voice_state"] = _voice.get_state_name()
		ctx["voice_last_error"] = _voice.get_last_error()
	return ctx


func _emit_latency_abort_summary() -> void:
	var line := VoiceTurnLatencyScript.get_last_abort_summary()
	if line.is_empty():
		return
	_emit_debug("latency_abort", line)


func _on_voice_state_changed(_old: int, new_state: int) -> void:
	if not _session_active:
		return
	match new_state:
		VoiceInteractionControllerScript.State.THINKING:
			_emit_status("llm_think", {"reason": "voice_thinking"})
		VoiceInteractionControllerScript.State.SYNTHESIZING:
			_emit_status("tts_prep", {"reason": "voice_synthesizing"})
		VoiceInteractionControllerScript.State.SPEAKING:
			_on_ai_speaking_started()
		VoiceInteractionControllerScript.State.IDLE:
			if _old in [
				VoiceInteractionControllerScript.State.SPEAKING,
				VoiceInteractionControllerScript.State.SYNTHESIZING,
			]:
				_stop_ai_presentation()


func _on_ai_speaking_started() -> void:
	if not _session_active:
		return
	_set_state(PerfState.AI_SPEAKING)


func _on_voice_turn_finished(reason: String) -> void:
	if not _session_active:
		return
	var gen := _session_gen
	VoiceTurnTraceScript.log("tts_turn_finished", {"reason": reason})
	_stop_ai_presentation()
	if gen != _session_gen:
		return
	_set_state(PerfState.RESUME_ATTRACT)
	var cooldown_ms := InviteListenConfigScript.post_tts_listen_cooldown_ms()
	if cooldown_ms > 0:
		VoiceTurnTraceScript.log("post_tts_listen_cooldown", {"ms": cooldown_ms})
		await get_tree().create_timer(float(cooldown_ms) / 1000.0).timeout
	else:
		await get_tree().process_frame
	if gen != _session_gen or not _session_active:
		return
	_set_state(PerfState.ATTRACT)
	VoiceTurnTraceScript.log("precoin_resumed", {"reason": reason})
	_emit_debug("turn_finished", reason)
	if reason == "completed":
		_emit_status("wait_listen", {"reason": "turn_completed"})
	elif reason == "error":
		_emit_status("pipeline_failed", {
			"reason": "voice_turn_error",
			"fail_kind": _classify_voice_fail_kind(),
			"detail": _voice.get_last_error() if _voice != null else "",
		})


func _stop_ai_presentation() -> void:
	if _viseme != null:
		_viseme.stop()
	if _host != null and _host.has_method("perf_stop_ai_speak_pose"):
		_host.perf_stop_ai_speak_pose()


func _capture_set_paused(paused: bool, flush_on_resume: bool = false) -> void:
	if _capture != null:
		_capture.set_paused(paused, flush_on_resume)
	VoiceTurnTraceScript.log(
		"capture_paused" if paused else "capture_resumed",
		{"perf_state": get_perf_state_name(), "flush": flush_on_resume},
	)
	PreviewVadEventLog.push(
		"coord_capture_pause" if paused else "coord_capture_resume",
		{"perf_state": get_perf_state_name(), "paused": paused},
	)


func _emit_debug(tag: String, detail: String) -> void:
	debug_event.emit(tag, detail)


func _emit_status(event: String, extra: Dictionary = {}) -> void:
	if _host == null or not _host.has_method("preview_ai_voice_status"):
		return
	var ctx := extra.duplicate()
	ctx["session_gen"] = _session_gen
	_host.preview_ai_voice_status(event, ctx)


func _classify_voice_fail_kind() -> String:
	if _voice == null:
		return "pipeline"
	var err := _voice.get_last_error()
	if err.contains("LLM"):
		return "llm"
	if err.contains("TTS"):
		return "tts"
	return "pipeline"
