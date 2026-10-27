extends Node

## Phase3-A 流式 ASR 隔离检查（mock WebSocket，无真实网络）。

const InviteStreamingAsrScript := preload("res://Scripts/voice/invite_streaming_asr.gd")
const FormalStreamingAsrControllerScript := preload("res://Scripts/voice/formal_streaming_asr_controller.gd")
const SpeechInputScript := preload("res://Scripts/voice/speech_input.gd")
const AliyunNlsConfigScript := preload("res://Scripts/voice/aliyun_nls_config.gd")
const NlsTokenProviderScript := preload("res://Scripts/voice/nls_token_provider.gd")
const VoiceTurnLatencyScript := preload("res://Scripts/voice/voice_turn_latency.gd")
const VoiceStreamingAsrSharedScript := preload("res://Scripts/voice/voice_streaming_asr_shared.gd")


class StubSpeech extends SpeechInputScript:
	var rest_calls := 0
	var rest_reply_prefix := "rest_"

	func _ready() -> void:
		pass

	func recognize_pcm16(_pcm: PackedByteArray, _sample_rate: int = 16000) -> String:
		rest_calls += 1
		return "%s%d" % [rest_reply_prefix, rest_calls]


func run() -> bool:
	var ok := true
	ok = ok and await _test_mock_finalize()
	ok = ok and await _test_cancel_stale_session()
	ok = ok and await _test_session_failed_no_rest()
	ok = ok and await _test_two_utterances_rest_fallback()
	ok = ok and await _test_late_sentence_during_listening()
	ok = ok and await _test_cancel_during_finalize_no_rest()
	ok = ok and await _test_late_ws_during_wait_beats_rest()
	ok = ok and await _test_session_stop_during_finalize()
	ok = ok and _test_bus_mutex()
	print("=== formal_streaming_asr_check_pass=%s ===" % str(ok))
	return ok


func _make_ctrl(use_counting_speech: bool = false) -> Dictionary:
	var nls := AliyunNlsConfigScript.new()
	add_child(nls)
	var tokens := NlsTokenProviderScript.new()
	tokens.setup(nls)
	add_child(tokens)
	var speech: SpeechInputScript
	if use_counting_speech:
		speech = StubSpeech.new()
	else:
		speech = StubSpeech.new()
	add_child(speech)
	var asr := InviteStreamingAsrScript.new()
	asr.mock_mode = true
	add_child(asr)
	asr.setup(nls, tokens)
	var ctrl := FormalStreamingAsrControllerScript.new()
	add_child(ctrl)
	ctrl.setup(asr, speech)
	ctrl.set_feature_enabled(true)
	ctrl.debug_final_wait_sec = 0.05
	var lat := VoiceTurnLatencyScript.new()
	lat.enabled = true
	ctrl.set_latency_tracker(lat)
	return {"ctrl": ctrl, "asr": asr, "lat": lat, "speech": speech}


func _test_mock_finalize() -> bool:
	var s: Dictionary = _make_ctrl()
	var ctrl: FormalStreamingAsrControllerScript = s.ctrl
	ctrl.on_session_started(1)
	ctrl.on_vad_speech_started(1, [PackedByteArray([1, 0])])
	ctrl.push_pcm(PackedByteArray([2, 0]))
	var pcm := PackedByteArray([1, 0, 2, 0])
	var text: String = await ctrl.finalize_utterance(pcm, 16000, 1)
	var ok := text == "你好"
	if not ok:
		push_error("formal_streaming_asr_check mock_finalize text=%s" % text)
	return ok


func _test_cancel_stale_session() -> bool:
	var s: Dictionary = _make_ctrl()
	var ctrl: FormalStreamingAsrControllerScript = s.ctrl
	ctrl.on_session_started(10)
	ctrl.on_vad_speech_started(10, [])
	ctrl.on_session_stopped()
	var text: String = await ctrl.finalize_utterance(PackedByteArray([1, 0]), 16000, 10)
	var ok := text.is_empty()
	if not ok:
		push_error("formal_streaming_asr_check stale_session expected empty got=%s" % text)
	return ok


func _test_session_failed_no_rest() -> bool:
	var s: Dictionary = _make_ctrl(true)
	var ctrl: FormalStreamingAsrControllerScript = s.ctrl
	var asr: InviteStreamingAsrScript = s.asr
	var speech: StubSpeech = s.speech as StubSpeech
	ctrl.mock_stream_result = ""
	ctrl.on_session_started(2)
	ctrl.on_vad_speech_started(2, [])
	asr.debug_simulate_task_failed("mock_fail")
	await get_tree().process_frame
	var text: String = await ctrl.finalize_utterance(PackedByteArray([1, 0]), 16000, 2)
	var ok := text.is_empty() and speech.rest_calls == 0
	if not ok:
		push_error(
			"formal_streaming_asr_check session_failed expected empty no_rest rest_calls=%d"
			% speech.rest_calls
		)
	return ok


func _test_two_utterances_rest_fallback() -> bool:
	var s: Dictionary = _make_ctrl(true)
	var ctrl: FormalStreamingAsrControllerScript = s.ctrl
	var speech: StubSpeech = s.speech as StubSpeech
	ctrl.mock_stream_result = ""
	ctrl.on_session_started(100)
	for i in 2:
		ctrl.on_vad_speech_started(100, [])
		await get_tree().process_frame
		var text: String = await ctrl.finalize_utterance(PackedByteArray([1, 0]), 16000, 100)
		if text != "rest_%d" % (i + 1):
			push_error(
				"formal_streaming_asr_check two_rest turn=%d text=%s calls=%d"
				% [i, text, speech.rest_calls]
			)
			return false
		await get_tree().process_frame
	var ok := speech.rest_calls == 2
	if not ok:
		push_error("formal_streaming_asr_check two_rest expected 2 calls got=%d" % speech.rest_calls)
	return ok


func _test_late_sentence_during_listening() -> bool:
	var s: Dictionary = _make_ctrl()
	var ctrl: FormalStreamingAsrControllerScript = s.ctrl
	var asr: InviteStreamingAsrScript = s.asr
	ctrl.on_session_started(3)
	ctrl.on_vad_speech_started(3, [])
	await ctrl.finalize_utterance(PackedByteArray([1, 0]), 16000, 3)
	ctrl.mock_stream_result = "第二句"
	ctrl.on_vad_speech_started(3, [])
	asr.sentence_end.emit("迟到第一句")
	await get_tree().process_frame
	var text: String = await ctrl.finalize_utterance(PackedByteArray([2, 0]), 16000, 3)
	var ok := text == "第二句"
	if not ok:
		push_error("formal_streaming_asr_check late_listening got=%s" % text)
	return ok


func _test_cancel_during_finalize_no_rest() -> bool:
	var s: Dictionary = _make_ctrl(true)
	var ctrl: FormalStreamingAsrControllerScript = s.ctrl
	var speech: StubSpeech = s.speech as StubSpeech
	ctrl.mock_stream_result = ""
	ctrl.debug_final_wait_sec = 0.4
	ctrl.on_session_started(4)
	ctrl.on_vad_speech_started(4, [])
	call_deferred("_run_finalize_async", ctrl, 4)
	await get_tree().create_timer(0.05).timeout
	ctrl.cancel_active_turn(false)
	await get_tree().create_timer(0.6).timeout
	var ok := speech.rest_calls == 0
	if not ok:
		push_error("formal_streaming_asr_check cancel_finalize rest_calls=%d" % speech.rest_calls)
	return ok


func _run_finalize_async(ctrl: FormalStreamingAsrControllerScript, session_gen: int) -> void:
	await ctrl.finalize_utterance(PackedByteArray([1, 0]), 16000, session_gen)


func _test_late_ws_during_wait_beats_rest() -> bool:
	var s: Dictionary = _make_ctrl(true)
	var ctrl: FormalStreamingAsrControllerScript = s.ctrl
	var asr: InviteStreamingAsrScript = s.asr
	var speech: StubSpeech = s.speech as StubSpeech
	ctrl.mock_stream_result = ""
	ctrl.debug_final_wait_sec = 0.4
	ctrl.on_session_started(5)
	ctrl.on_vad_speech_started(5, [])
	var out: Array = [""]
	call_deferred("_finalize_into", ctrl, 5, out)
	await get_tree().process_frame
	asr.sentence_end.emit("ws_ok")
	await get_tree().create_timer(0.15).timeout
	var text := String(out[0])
	var ok := text == "ws_ok" and speech.rest_calls == 0
	if not ok:
		push_error("formal_streaming_asr_check late_ws_wait text=%s rest=%d" % [text, speech.rest_calls])
	return ok


func _finalize_into(ctrl: FormalStreamingAsrControllerScript, session_gen: int, out: Array) -> void:
	out[0] = await ctrl.finalize_utterance(PackedByteArray([1, 0]), 16000, session_gen)


func _test_session_stop_during_finalize() -> bool:
	var s: Dictionary = _make_ctrl(true)
	var ctrl: FormalStreamingAsrControllerScript = s.ctrl
	var speech: StubSpeech = s.speech as StubSpeech
	ctrl.mock_stream_result = ""
	ctrl.debug_final_wait_sec = 0.3
	ctrl.on_session_started(6)
	ctrl.on_vad_speech_started(6, [])
	call_deferred("_run_finalize_async", ctrl, 6)
	await get_tree().create_timer(0.05).timeout
	ctrl.on_session_stopped()
	await get_tree().create_timer(0.6).timeout
	var ok := speech.rest_calls == 0
	if not ok:
		push_error("formal_streaming_asr_check session_stop rest=%d" % speech.rest_calls)
	return ok


func _test_bus_mutex() -> bool:
	return (
		not VoiceStreamingAsrSharedScript.formal_may_open_capture(true, true)
		and VoiceStreamingAsrSharedScript.invite_may_open_stream(true, true) == false
	)
