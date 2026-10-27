extends Node

## VAD 观测 + 连续链路延迟计时 headless 检查（桩 ASR/LLM/TTS，无真实 API）。

const SpeechInputScript := preload("res://Scripts/voice/speech_input.gd")
const YouyouDialogueClientScript := preload("res://Scripts/voice/youyou_dialogue_client.gd")
const VoiceOutputScript := preload("res://Scripts/voice/voice_output.gd")
const VoiceInteractionControllerScript := preload("res://Scripts/voice/voice_interaction_controller.gd")
const FacePresenterScript := preload("res://Scripts/youyou_face_presenter.gd")
const VisemeProceduralDriverScript := preload("res://Scripts/voice/viseme_procedural_driver.gd")
const LlmResponseScript := preload("res://Scripts/voice/llm_response.gd")
const AiPerformanceCoordinatorScript := preload("res://Scripts/voice/ai_performance_coordinator.gd")
const VoiceTurnLatencyScript := preload("res://Scripts/voice/voice_turn_latency.gd")
const PreviewVadEventLog := preload("res://Scripts/voice/preview_vad_event_log.gd")


class StubSpeech extends SpeechInputScript:
	func _ready() -> void:
		pass


class StubDialogue extends YouyouDialogueClientScript:
	var test_latency: VoiceTurnLatencyScript

	func ask(_player_text: String) -> LlmResponseScript:
		if test_latency != null and test_latency.enabled:
			test_latency.mark_once("llm_start")
		await get_tree().process_frame
		if test_latency != null and test_latency.enabled:
			test_latency.mark_end("llm_end")
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
		if latency != null and latency.enabled:
			latency.mark_once("tts_start")
			latency.mark_end("tts_first_audio_ready")
			latency.mark_once("tts_decode_start")
			latency.mark_once("playback_start")
		await get_tree().process_frame
		if _hook.is_valid():
			_hook.call()
		for _i in 2:
			await get_tree().process_frame
		return true


class MockPrecoinHost extends Node:
	var may_listen := true
	var may_resume := true
	var resume_precoin_count := 0
	var listen_count := 0
	var blocked_play := false

	func preview_ai_may_continuous_listen() -> bool:
		return may_listen

	func preview_ai_may_resume_attract() -> bool:
		return may_resume

	func perf_resume_precoin_attract() -> void:
		if preview_ai_may_resume_attract():
			resume_precoin_count += 1

	func perf_play_listen_idle() -> void:
		listen_count += 1

	func perf_play_ai_speak() -> void:
		pass

	func perf_stop_ai_speak_pose() -> void:
		pass

	func perf_clear_presentation() -> void:
		pass

	func precoin_play_action(_action_id: String, _kind: String) -> bool:
		if blocked_play:
			PreviewVadEventLog.push("precoin_play_blocked", {
				"precoin_play": "blocked_ai_phase id=test",
				"perf_state": "LISTENING",
			})
			return false
		return true


func run() -> bool:
	var ok := true
	PreviewVadEventLog.clear()
	VoiceTurnLatencyScript.clear_history()
	var host := MockPrecoinHost.new()
	host.name = "MockPrecoinHost"
	add_child(host)
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
	dialogue.test_latency = latency
	var voice := VoiceInteractionControllerScript.new()
	add_child(voice)
	voice.setup(speech, dialogue, output, face, viseme)
	voice.manage_viseme = false
	voice.bind_latency_tracker(latency)
	var coord := AiPerformanceCoordinatorScript.new()
	add_child(coord)
	coord.precoin_attract_mode = true
	coord.set_latency_tracker(latency)
	coord.setup(host, voice, speech, viseme, "PreviewAiObservabilityCheck")
	coord.debug_enable_mock_asr("你好")
	output.set_playback_started_hook(coord.notify_tts_playback_started)
	await get_tree().process_frame
	host.blocked_play = true
	coord.start_session()
	coord.debug_trigger_mock_utterance()
	await get_tree().process_frame
	ok = ok and not host.precoin_play_action("test_attract", "attract")
	var blocked := false
	for row in PreviewVadEventLog.get_events():
		if String(row.get("event", "")) == "precoin_play_blocked":
			blocked = true
	ok = ok and blocked
	host.blocked_play = false
	var waited := 0.0
	while waited < 5.0 and VoiceTurnLatencyScript.get_history().is_empty():
		await get_tree().process_frame
		waited += get_process_delta_time()
	var events := PreviewVadEventLog.get_events()
	ok = ok and events.size() >= 2
	var has_started := false
	var has_ended := false
	for row in events:
		var ev := String(row.get("event", ""))
		if ev == "speech_started" or ev == "coord_speech_started":
			has_started = true
		if ev == "speech_ended" or ev == "coord_speech_ended":
			has_ended = true
	ok = ok and has_started and has_ended
	ok = ok and not VoiceTurnLatencyScript.get_history().is_empty()
	var report: Dictionary = VoiceTurnLatencyScript.get_history()[-1]
	ok = ok and str(report.get("path", "")) == "continuous"
	ok = ok and str(report.get("outcome", "")) == "completed"
	var marks: Dictionary = report.get("events", {})
	ok = ok and marks.has("vad_start") and marks.has("vad_end") and marks.has("pcm_ready")
	ok = ok and marks.has("asr_start") and marks.has("asr_end")
	ok = ok and marks.has("llm_start") and marks.has("llm_end")
	ok = ok and marks.has("playback_start")
	ok = ok and report.get("vad_end_to_playback_ms") != null
	var hist_before := VoiceTurnLatencyScript.get_history().size()
	await coord.stop_session("preempt_test")
	await get_tree().process_frame
	ok = ok and VoiceTurnLatencyScript.get_history().size() == hist_before
	print(
		"preview_ai_voice_observability_check events=%d report_outcome=%s ok=%s"
		% [events.size(), str(report.get("outcome", "")), str(ok)]
	)
	print("=== preview_ai_voice_observability_check_pass=%s ===" % str(ok))
	return ok
