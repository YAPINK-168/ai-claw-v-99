extends Node

## Phase4-D.1：defer isolate 实验 + 追踪开关 Smoke（mock，不改正式默认）。

const InviteStreamingAsrScript := preload("res://Scripts/voice/invite_streaming_asr.gd")
const FormalStreamingAsrControllerScript := preload("res://Scripts/voice/formal_streaming_asr_controller.gd")
const SpeechInputScript := preload("res://Scripts/voice/speech_input.gd")
const AliyunNlsConfigScript := preload("res://Scripts/voice/aliyun_nls_config.gd")
const NlsTokenProviderScript := preload("res://Scripts/voice/nls_token_provider.gd")
const FormalAsrTurnTraceScript := preload("res://Scripts/voice/formal_asr_turn_trace.gd")


class StubSpeech extends SpeechInputScript:
	func _ready() -> void:
		pass

	func recognize_pcm16(_pcm: PackedByteArray, _sample_rate: int = 16000) -> String:
		return "rest_ok"


func run() -> bool:
	var ok := true
	ok = ok and await _test_trace_smoke()
	ok = ok and await _test_defer_isolate_two_turns()
	ok = ok and await _test_default_await_isolate()
	print("=== formal_streaming_asr_d1_check_pass=%s ===" % str(ok))
	return ok


func _make_ctrl() -> Dictionary:
	var nls := AliyunNlsConfigScript.new()
	add_child(nls)
	var tokens := NlsTokenProviderScript.new()
	tokens.setup(nls)
	add_child(tokens)
	var speech := StubSpeech.new()
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
	return {"ctrl": ctrl, "asr": asr}


func _test_trace_smoke() -> bool:
	OS.set_environment("YOUYOU_FORMAL_ASR_TRACE", "1")
	FormalAsrTurnTraceScript.refresh_from_env()
	FormalAsrTurnTraceScript.reset_anchor()
	var s := _make_ctrl()
	var ctrl: FormalStreamingAsrControllerScript = s.ctrl
	ctrl.on_session_started(1)
	ctrl.on_vad_speech_started(1, [])
	var t: String = await ctrl.finalize_utterance(PackedByteArray([1, 0]), 16000, 1)
	OS.set_environment("YOUYOU_FORMAL_ASR_TRACE", "")
	FormalAsrTurnTraceScript.refresh_from_env()
	return t == "你好"


func _test_defer_isolate_two_turns() -> bool:
	OS.set_environment("YOUYOU_ASR_DEFER_ISOLATE", "1")
	var s := _make_ctrl()
	var ctrl: FormalStreamingAsrControllerScript = s.ctrl
	var asr: InviteStreamingAsrScript = s.asr
	ctrl.on_session_started(2)
	ctrl.on_vad_speech_started(2, [])
	var t1: String = await ctrl.finalize_utterance(PackedByteArray([1, 0]), 16000, 2)
	await get_tree().process_frame
	await get_tree().process_frame
	ctrl.on_vad_speech_started(2, [])
	await get_tree().process_frame
	await get_tree().process_frame
	var t2: String = await ctrl.finalize_utterance(PackedByteArray([2, 0]), 16000, 2)
	OS.set_environment("YOUYOU_ASR_DEFER_ISOLATE", "")
	var ok := t1 == "你好" and t2 == "你好"
	if not ok:
		push_error("formal_streaming_asr_d1 defer_isolate t1=%s t2=%s" % [t1, t2])
	return ok


func _test_default_await_isolate() -> bool:
	OS.set_environment("YOUYOU_ASR_DEFER_ISOLATE", "0")
	var s := _make_ctrl()
	var ctrl: FormalStreamingAsrControllerScript = s.ctrl
	ctrl.on_session_started(3)
	ctrl.on_vad_speech_started(3, [])
	var t: String = await ctrl.finalize_utterance(PackedByteArray([1, 0]), 16000, 3)
	return t == "你好"
