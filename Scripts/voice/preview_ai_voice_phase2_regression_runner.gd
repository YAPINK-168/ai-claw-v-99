extends Node

## Phase2 基线回归：桩 ASR/LLM/TTS + 静态约束检查。不实例化 PreviewAiVoiceBridge（避免真实凭证/麦克风栈）。

const SpeechInputScript := preload("res://Scripts/voice/speech_input.gd")
const YouyouDialogueClientScript := preload("res://Scripts/voice/youyou_dialogue_client.gd")
const VoiceOutputScript := preload("res://Scripts/voice/voice_output.gd")
const VoiceInteractionControllerScript := preload("res://Scripts/voice/voice_interaction_controller.gd")
const FacePresenterScript := preload("res://Scripts/youyou_face_presenter.gd")
const VisemeProceduralDriverScript := preload("res://Scripts/voice/viseme_procedural_driver.gd")
const LlmResponseScript := preload("res://Scripts/voice/llm_response.gd")
const AiPerformanceCoordinatorScript := preload("res://Scripts/voice/ai_performance_coordinator.gd")
const VoiceTurnLatencyScript := preload("res://Scripts/voice/voice_turn_latency.gd")
const VoicePipelineFeatureFlagsScript := preload("res://Scripts/voice/voice_pipeline_feature_flags.gd")
const VoicePipelineBaselineStatsScript := preload("res://Scripts/voice/voice_pipeline_baseline_stats.gd")
const VoiceLlmJsonIncrementalScript := preload("res://Scripts/voice/voice_llm_json_incremental.gd")
const VoiceStreamingAsrSharedScript := preload("res://Scripts/voice/voice_streaming_asr_shared.gd")


class StubSpeech extends SpeechInputScript:
	func _ready() -> void:
		pass


class StubDialogue extends YouyouDialogueClientScript:
	enum Mode { OK, FAIL }

	var mode := Mode.OK

	func ask(_player_text: String) -> LlmResponseScript:
		await get_tree().process_frame
		if mode == Mode.FAIL:
			return LlmResponseScript.failure()
		var r := LlmResponseScript.fallback("Phase2 回归")
		r.ok = true
		r.emotion = "happy"
		return r


class StubVoiceOutput extends VoiceOutputScript:
	var _hook: Callable = Callable()
	var fail_next := false
	var stop_count := 0
	var speak_count := 0

	func _ready() -> void:
		pass

	func set_playback_started_hook(callable: Callable) -> void:
		_hook = callable

	func stop(_invalidate_inflight: bool = true) -> void:
		stop_count += 1

	func is_speaking() -> bool:
		return false

	func speak(_text: String, _emotion: String = "", _intensity: float = 0.0) -> bool:
		speak_count += 1
		if fail_next:
			return false
		if latency != null and latency.enabled:
			latency.mark_once("tts_start")
			latency.mark_end("tts_first_audio_ready")
			latency.mark_once("tts_decode_start")
			latency.mark_once("playback_start")
			latency.mark_end("playback_end")
		await get_tree().process_frame
		if _hook.is_valid():
			_hook.call()
		await get_tree().process_frame
		return true


class Host extends Node:
	var may_listen := true

	func preview_ai_may_continuous_listen() -> bool:
		return may_listen

	func preview_ai_may_resume_attract() -> bool:
		return may_listen

	func preview_ai_voice_status(_e: String, _c: Dictionary) -> void:
		pass

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


func run() -> bool:
	VoicePipelineBaselineStatsScript.reset()
	VoiceTurnLatencyScript.clear_history()
	var ok: bool = true
	ok = ok and _test_flags_defaults()
	ok = ok and _test_llm_json_incremental()
	ok = ok and _test_asr_bus_mutex()
	ok = ok and await _test_normal_turn()
	ok = ok and await _test_asr_empty()
	ok = ok and await _test_llm_fail()
	ok = ok and await _test_tts_fail()
	ok = ok and await _test_preempt_during_turn()
	ok = ok and await _test_stale_after_stop()
	ok = ok and await _test_session_open_close()
	ok = ok and _test_latency_metric_slots()
	VoicePipelineBaselineStatsScript.print_summary()
	print("=== preview_ai_voice_phase2_regression_pass=%s ===" % str(ok))
	return ok


## Phase4-C 起正式默认 stream_tts=true（project.godot）；Phase2 断言同步为 WS 默认，非为通过而放宽。
func _test_flags_defaults() -> bool:
	OS.set_environment("YOUYOU_VOICE_STREAM_TTS", "")
	var f := VoicePipelineFeatureFlagsScript.load_current()
	var ok: bool = (
		f.stream_asr
		and f.stream_tts
		and not f.stream_llm
		and not f.new_window_policy
		and f.stable_path_required()
	)
	if not ok:
		push_error("phase2_regression flags not expected defaults: %s" % f.status_line())
	return ok


func _test_llm_json_incremental() -> bool:
	var full := '{"reply":"你好","emotion":"happy","intensity":0.5,"action":"chat","expression":"happy"}'
	var ex := VoiceLlmJsonIncrementalScript.extract_reply_progress(full)
	var ok: bool = VoiceLlmJsonIncrementalScript.is_safe_for_tts(ex) and str(ex.get("reply", "")) == "你好"
	var partial := VoiceLlmJsonIncrementalScript.extract_reply_progress('{"reply":"你')
	ok = ok and not VoiceLlmJsonIncrementalScript.is_safe_for_tts(partial)
	if not ok:
		push_error("phase2_regression llm_json_incremental")
	return ok


func _test_asr_bus_mutex() -> bool:
	var ok: bool = true
	ok = ok and not VoiceStreamingAsrSharedScript.formal_may_open_capture(true, true)
	ok = ok and VoiceStreamingAsrSharedScript.formal_may_open_capture(false, true)
	ok = ok and not VoiceStreamingAsrSharedScript.invite_may_open_stream(true, true)
	ok = ok and VoiceStreamingAsrSharedScript.invite_may_open_stream(false, true)
	if not ok:
		push_error("phase2_regression asr_bus_mutex")
	return ok


func _new_stack(host: Host) -> Dictionary:
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
	coord.setup(host, voice, speech, viseme, "Phase2Regression")
	output.set_playback_started_hook(coord.notify_tts_playback_started)
	coord.debug_enable_mock_asr("你好")
	return {"coord": coord, "voice": voice, "output": output, "dialogue": dialogue, "latency": latency}


func _test_normal_turn() -> bool:
	var host := Host.new()
	add_child(host)
	var s: Dictionary = _new_stack(host)
	var coord: AiPerformanceCoordinatorScript = s.coord
	await get_tree().process_frame
	coord.start_session()
	coord.debug_trigger_mock_utterance()
	var t := 0.0
	while t < 6.0 and coord.get_perf_state() != AiPerformanceCoordinatorScript.PerfState.ATTRACT:
		await get_tree().process_frame
		t += get_process_delta_time()
	var ok: bool = coord.get_perf_state() == AiPerformanceCoordinatorScript.PerfState.ATTRACT
	ok = ok and not s.voice.is_busy()
	if not ok:
		push_error("phase2_regression normal_turn")
	return ok


func _test_asr_empty() -> bool:
	var host := Host.new()
	add_child(host)
	var s: Dictionary = _new_stack(host)
	var coord: AiPerformanceCoordinatorScript = s.coord
	coord.debug_enable_mock_asr("")
	coord.start_session()
	coord.debug_trigger_mock_utterance()
	var t := 0.0
	while t < 4.0 and coord.get_perf_state() != AiPerformanceCoordinatorScript.PerfState.ATTRACT:
		await get_tree().process_frame
		t += get_process_delta_time()
	var ok: bool = coord.get_perf_state() == AiPerformanceCoordinatorScript.PerfState.ATTRACT
	if not ok:
		push_error("phase2_regression asr_empty")
	return ok


func _test_llm_fail() -> bool:
	var host := Host.new()
	add_child(host)
	var s: Dictionary = _new_stack(host)
	s.dialogue.mode = StubDialogue.Mode.FAIL
	var coord: AiPerformanceCoordinatorScript = s.coord
	coord.start_session()
	coord.debug_trigger_mock_utterance()
	var t := 0.0
	while t < 5.0 and s.voice.get_state() != VoiceInteractionControllerScript.State.IDLE:
		await get_tree().process_frame
		t += get_process_delta_time()
	var ok: bool = s.voice.get_state() == VoiceInteractionControllerScript.State.IDLE
	if not ok:
		push_error("phase2_regression llm_fail")
	return ok


func _test_tts_fail() -> bool:
	var host := Host.new()
	add_child(host)
	var s: Dictionary = _new_stack(host)
	s.output.fail_next = true
	var coord: AiPerformanceCoordinatorScript = s.coord
	coord.start_session()
	coord.debug_trigger_mock_utterance()
	var t := 0.0
	while t < 5.0 and s.voice.get_state() != VoiceInteractionControllerScript.State.IDLE:
		await get_tree().process_frame
		t += get_process_delta_time()
	var ok: bool = s.voice.get_state() == VoiceInteractionControllerScript.State.IDLE and s.output.speak_count >= 1
	if not ok:
		push_error("phase2_regression tts_fail")
	return ok


func _test_preempt_during_turn() -> bool:
	var host := Host.new()
	add_child(host)
	var s: Dictionary = _new_stack(host)
	var coord: AiPerformanceCoordinatorScript = s.coord
	coord.start_session()
	coord.debug_trigger_mock_utterance()
	await get_tree().process_frame
	await coord.stop_session("coin")
	var ok: bool = not coord.is_session_active() and s.voice.get_state() == VoiceInteractionControllerScript.State.IDLE
	ok = ok and s.output.stop_count >= 1
	if not ok:
		push_error("phase2_regression preempt")
	return ok


func _test_stale_after_stop() -> bool:
	var host := Host.new()
	add_child(host)
	var s: Dictionary = _new_stack(host)
	var coord: AiPerformanceCoordinatorScript = s.coord
	coord.start_session()
	coord.debug_trigger_mock_utterance()
	await get_tree().process_frame
	var gen := coord.get_session_generation()
	await coord.stop_session("player_left")
	var ok: bool = coord.get_session_generation() > gen and not coord.is_session_active()
	if not ok:
		push_error("phase2_regression stale_gen")
	return ok


func _test_session_open_close() -> bool:
	var host := Host.new()
	add_child(host)
	var s: Dictionary = _new_stack(host)
	var coord: AiPerformanceCoordinatorScript = s.coord
	coord.start_session()
	var ok: bool = coord.is_session_active()
	await coord.stop_session("close_a")
	ok = ok and not coord.is_session_active()
	coord.start_session()
	ok = ok and coord.is_session_active()
	await coord.stop_session("close_b")
	ok = ok and not coord.is_session_active()
	if not ok:
		push_error("phase2_regression session_cycles")
	return ok


func _test_latency_metric_slots() -> bool:
	var hist := VoiceTurnLatencyScript.get_history()
	if hist.is_empty():
		push_error("phase2_regression latency history empty")
		return false
	var r: Dictionary = hist[-1]
	var ok: bool = r.get("asr_ms") != null or r.get("vad_end_to_asr_end_ms") != null
	ok = ok and r.get("tts_first_ready_ms") != null
	ok = ok and r.get("events", {}).has("playback_start")
	# 稳定链路无 SSE：llm_first_token 应为 null
	ok = ok and r.get("llm_first_token_ms") == null
	if not ok:
		push_error("phase2_regression latency slots r=%s" % str(r))
	return ok
