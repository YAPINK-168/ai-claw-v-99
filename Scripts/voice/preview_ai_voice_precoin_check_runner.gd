extends Node

## 正式场景投币前 AI 桥接 headless 检查（桩 ASR/LLM/TTS，无真实 API）。

const SpeechInputScript := preload("res://Scripts/voice/speech_input.gd")
const YouyouDialogueClientScript := preload("res://Scripts/voice/youyou_dialogue_client.gd")
const VoiceOutputScript := preload("res://Scripts/voice/voice_output.gd")
const VoiceInteractionControllerScript := preload("res://Scripts/voice/voice_interaction_controller.gd")
const FacePresenterScript := preload("res://Scripts/youyou_face_presenter.gd")
const VisemeProceduralDriverScript := preload("res://Scripts/voice/viseme_procedural_driver.gd")
const LlmResponseScript := preload("res://Scripts/voice/llm_response.gd")
const AiPerformanceCoordinatorScript := preload("res://Scripts/voice/ai_performance_coordinator.gd")


class StubSpeech extends SpeechInputScript:
	func _ready() -> void:
		pass


class StubDialogue extends YouyouDialogueClientScript:
	func ask(_player_text: String) -> LlmResponseScript:
		await get_tree().process_frame
		var r := LlmResponseScript.fallback("预演回复")
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
		if _hook.is_valid():
			_hook.call()
		for _i in 3:
			await get_tree().process_frame
		return true


class MockPrecoinHost extends Node:
	var may_listen := true
	var may_resume := true
	var resume_precoin_count := 0
	var listen_count := 0
	var speak_count := 0
	var attract_play_count := 0

	func preview_ai_may_continuous_listen() -> bool:
		return may_listen

	func preview_ai_may_resume_attract() -> bool:
		return may_resume

	func perf_play_attract() -> void:
		attract_play_count += 1

	func perf_resume_precoin_attract() -> void:
		if preview_ai_may_resume_attract():
			resume_precoin_count += 1

	func perf_play_listen_idle() -> void:
		listen_count += 1

	func perf_play_ai_speak() -> void:
		speak_count += 1

	func perf_stop_ai_speak_pose() -> void:
		pass

	func perf_clear_presentation() -> void:
		pass


func run() -> bool:
	var ok := true
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
	var voice := VoiceInteractionControllerScript.new()
	add_child(voice)
	voice.setup(speech, dialogue, output, face, viseme)
	voice.manage_viseme = false
	var coord := AiPerformanceCoordinatorScript.new()
	add_child(coord)
	coord.precoin_attract_mode = true
	coord.setup(host, voice, speech, viseme, "PreviewAiVoicePrecoinCheck")
	coord.debug_enable_mock_asr("你好")
	output.set_playback_started_hook(coord.notify_tts_playback_started)
	await get_tree().process_frame
	coord.start_session()
	ok = ok and coord.get_perf_state() == AiPerformanceCoordinatorScript.PerfState.ATTRACT
	ok = ok and not coord.holds_precoin_schedule()
	ok = ok and host.attract_play_count == 0 and host.resume_precoin_count >= 1
	coord.debug_trigger_mock_utterance()
	await get_tree().process_frame
	ok = ok and host.listen_count >= 1
	ok = ok and coord.holds_precoin_schedule()
	ok = ok and coord.get_perf_state() == AiPerformanceCoordinatorScript.PerfState.LISTENING
	var waited := 0.0
	while waited < 3.0 and host.speak_count < 1:
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and host.speak_count >= 1
	waited = 0.0
	while waited < 5.0:
		if coord.get_perf_state() == AiPerformanceCoordinatorScript.PerfState.ATTRACT:
			break
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and coord.get_perf_state() == AiPerformanceCoordinatorScript.PerfState.ATTRACT
	var resume_before := host.resume_precoin_count
	host.may_resume = false
	coord.debug_trigger_mock_utterance()
	await get_tree().process_frame
	waited = 0.0
	while waited < 5.0:
		if coord.get_perf_state() == AiPerformanceCoordinatorScript.PerfState.ATTRACT:
			break
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and host.resume_precoin_count == resume_before
	host.may_resume = true
	var gen_before := coord.get_session_generation()
	await coord.stop_session("preempt_test")
	ok = ok and not coord.is_session_active()
	ok = ok and coord.get_session_generation() > gen_before
	host.may_listen = false
	coord.start_session()
	ok = ok and not coord.is_session_active()
	print(
		"preview_ai_voice_precoin_check resume=%d listen=%d speak=%d ok=%s"
		% [host.resume_precoin_count, host.listen_count, host.speak_count, str(ok)]
	)
	print("=== preview_ai_voice_precoin_check_pass=%s ===" % str(ok))
	return ok
