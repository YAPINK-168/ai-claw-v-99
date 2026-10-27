extends Node

## 玩家可见 AI 状态提示 headless 检查（桩 ASR/LLM/TTS，无 PreviewAiVoiceBridge / 无真实 API）。

const SpeechInputScript := preload("res://Scripts/voice/speech_input.gd")
const YouyouDialogueClientScript := preload("res://Scripts/voice/youyou_dialogue_client.gd")
const VoiceOutputScript := preload("res://Scripts/voice/voice_output.gd")
const VoiceInteractionControllerScript := preload("res://Scripts/voice/voice_interaction_controller.gd")
const FacePresenterScript := preload("res://Scripts/youyou_face_presenter.gd")
const VisemeProceduralDriverScript := preload("res://Scripts/voice/viseme_procedural_driver.gd")
const LlmResponseScript := preload("res://Scripts/voice/llm_response.gd")
const AiPerformanceCoordinatorScript := preload("res://Scripts/voice/ai_performance_coordinator.gd")
const PreviewAiVoicePlayerStatusScript := preload("res://Scripts/voice/preview_ai_voice_player_status.gd")
const PreviewVadEventLog := preload("res://Scripts/voice/preview_vad_event_log.gd")
const VoiceTurnLatencyScript := preload("res://Scripts/voice/voice_turn_latency.gd")


class StubSpeech extends SpeechInputScript:
	func _ready() -> void:
		pass


class StubDialogue extends YouyouDialogueClientScript:
	func ask(_player_text: String) -> LlmResponseScript:
		await get_tree().process_frame
		var r := LlmResponseScript.fallback("测试回复")
		r.ok = true
		return r


class StubVoiceOutput extends VoiceOutputScript:
	var _hook: Callable = Callable()

	func _ready() -> void:
		pass

	func set_playback_started_hook(callable: Callable) -> void:
		_hook = callable

	func stop(_invalidate_inflight: bool = true) -> void:
		pass

	func is_speaking() -> bool:
		return false

	func speak(_text: String, _emotion: String = "", _intensity: float = 0.0) -> bool:
		await get_tree().process_frame
		if latency != null and latency.enabled:
			latency.mark_once("tts_start")
			latency.mark_end("tts_first_audio_ready")
			latency.mark_once("tts_decode_start")
			latency.mark_once("playback_start")
		if _hook.is_valid():
			_hook.call()
		await get_tree().process_frame
		await get_tree().process_frame
		return true


class StatusHost extends Node:
	var status: PreviewAiVoicePlayerStatusScript
	var label := Label.new()

	func _ready() -> void:
		add_child(label)
		status = PreviewAiVoicePlayerStatusScript.new()
		status.bind(self, label)

	func preview_ai_may_continuous_listen() -> bool:
		return true

	func preview_ai_may_resume_attract() -> bool:
		return true

	func preview_ai_voice_status(event: String, ctx: Dictionary) -> void:
		status.handle(event, ctx)

	func preview_ai_on_window_closed(reason: String, _resume: bool) -> void:
		status.on_window_closed(reason)

	func perf_resume_precoin_attract() -> void:
		pass

	func perf_play_listen_idle() -> void:
		pass

	func perf_play_ai_speak() -> void:
		pass

	func perf_stop_ai_speak_pose() -> void:
		pass

	func perf_clear_presentation() -> void:
		pass


func _status_phases(host: StatusHost) -> Array:
	var phases: Array = []
	for row in PreviewVadEventLog.get_events():
		if String(row.get("event", "")) != "ai_voice_status":
			continue
		phases.append(String(row.get("phase", "")))
	return phases


func _has_phase(phases: Array, phase: String) -> bool:
	return phase in phases


func run() -> bool:
	var ok := true
	PreviewVadEventLog.clear()
	var host := StatusHost.new()
	host.name = "StatusCheckHost"
	add_child(host)
	await get_tree().process_frame
	var speech := StubSpeech.new()
	add_child(speech)
	var dialogue := StubDialogue.new()
	add_child(dialogue)
	var output := StubVoiceOutput.new()
	add_child(output)
	var face := FacePresenterScript.new()
	add_child(face)
	var viseme := VisemeProceduralDriverScript.new()
	add_child(viseme)
	var latency := VoiceTurnLatencyScript.new()
	latency.enabled = true
	var voice := VoiceInteractionControllerScript.new()
	add_child(voice)
	voice.setup(speech, dialogue, output, face, viseme)
	voice.manage_viseme = false
	voice.bind_latency_tracker(latency)
	var coord := AiPerformanceCoordinatorScript.new()
	add_child(coord)
	coord.precoin_attract_mode = true
	coord.set_latency_tracker(latency)
	coord.setup(host, voice, speech, viseme, "PreviewAiVoiceStatusCheck")
	coord.debug_enable_mock_asr("你好")
	output.set_playback_started_hook(coord.notify_tts_playback_started)
	await get_tree().process_frame
	coord.start_session()
	ok = ok and host.status.current_message() == PreviewAiVoicePlayerStatusScript.MSG_WAIT
	coord.debug_trigger_mock_utterance()
	var waited := 0.0
	while waited < 5.0 and host.status.current_message() != PreviewAiVoicePlayerStatusScript.MSG_PLAYBACK:
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and host.status.current_message() == PreviewAiVoicePlayerStatusScript.MSG_PLAYBACK
	while waited < 8.0 and host.status.current_message() != PreviewAiVoicePlayerStatusScript.MSG_WAIT:
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and host.status.current_message() == PreviewAiVoicePlayerStatusScript.MSG_WAIT
	if not ok:
		push_error("status_check after_turn msg=%s" % host.status.current_message())
		return false
	var phases := _status_phases(host)
	ok = ok and _has_phase(phases, "vad_listen")
	ok = ok and _has_phase(phases, "asr")
	ok = ok and _has_phase(phases, "llm_think")
	ok = ok and _has_phase(phases, "tts_prep")
	ok = ok and _has_phase(phases, "playback")
	ok = ok and _has_phase(phases, "wait_listen")
	# ASR empty（桩 ASR 返回空串）
	host.status.force_clear()
	await coord.stop_session("check_asr_empty")
	coord.debug_enable_mock_asr("")
	coord.start_session()
	coord.debug_trigger_mock_utterance()
	waited = 0.0
	while waited < 3.0 and host.status.current_message() != PreviewAiVoicePlayerStatusScript.MSG_ASR_EMPTY:
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and host.status.current_message() == PreviewAiVoicePlayerStatusScript.MSG_ASR_EMPTY
	# Timeout feedback
	host.status.on_window_closed("window_timeout")
	ok = ok and host.status.current_message() == PreviewAiVoicePlayerStatusScript.MSG_TIMEOUT
	await get_tree().create_timer(4.5).timeout
	ok = ok and host.status.current_message() == ""
	# Preempt clear
	host.status.handle("wait_listen", {"session_gen": 99})
	host.status.on_window_closed("coin")
	ok = ok and host.status.current_message() == ""
	# Stale gen ignored
	host.status.handle("playback", {"session_gen": 1})
	ok = ok and host.status.current_message() == ""
	# Session stop while mock utterance would be stale
	PreviewVadEventLog.clear()
	coord.debug_enable_mock_asr("你好")
	coord.start_session()
	var gen2 := coord.get_session_generation()
	coord.debug_trigger_mock_utterance()
	await get_tree().process_frame
	await coord.stop_session("preempt_test")
	host.status.force_clear()
	host.status.handle("playback", {"session_gen": gen2})
	ok = ok and host.status.current_message() == ""
	if not ok:
		push_error(
			"status_check msg=%s phases=%s" % [host.status.current_message(), str(phases)]
		)
	print("preview_ai_voice_status_check phases=%s ok=%s" % [str(phases), str(ok)])
	print("=== preview_ai_voice_status_check_pass=%s ===" % str(ok))
	return ok
