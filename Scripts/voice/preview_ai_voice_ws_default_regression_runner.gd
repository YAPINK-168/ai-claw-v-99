extends Node

## Phase4-C.1：stream_tts 默认开启 + HTTP 回退可独立关闭（Headless，无实网 TTS）。

const VoicePipelineFeatureFlagsScript := preload("res://Scripts/voice/voice_pipeline_feature_flags.gd")
const VoiceOutputScript := preload("res://Scripts/voice/voice_output.gd")
const BailianTtsConfigScript := preload("res://Scripts/voice/bailian_tts_config.gd")

const SAMPLE_SHORT := "粉色兔子超软萌，要不要我帮你抓一只呀？"
const SAMPLE_LONG := "今天爪子状态不错，你要是看中哪只告诉我，我可以帮你分析一下位置，咱们再决定要不要出手。"


func run() -> bool:
	var ok := true
	ok = ok and _test_project_ws_default_on()
	ok = ok and _test_env_can_disable_ws()
	ok = ok and await _test_ws_mock_short_and_long()
	ok = ok and await _test_http_path_when_ws_flag_off()
	print("=== preview_ai_voice_ws_default_regression_pass=%s ===" % str(ok))
	return ok


func _test_project_ws_default_on() -> bool:
	OS.set_environment("YOUYOU_VOICE_STREAM_TTS", "")
	var f := VoicePipelineFeatureFlagsScript.load_current()
	var ok := f.stream_asr and f.stream_tts
	print("ws_default_regression flags_default=%s" % f.status_line())
	if not ok:
		push_error("ws_default_regression expected stream_tts=true from project default")
	return ok


func _test_env_can_disable_ws() -> bool:
	OS.set_environment("YOUYOU_VOICE_STREAM_TTS", "0")
	var f := VoicePipelineFeatureFlagsScript.load_current()
	var ok := not f.stream_tts
	OS.set_environment("YOUYOU_VOICE_STREAM_TTS", "")
	print("ws_default_regression env_off stream_tts=%s ok=%s" % [str(f.stream_tts), str(ok)])
	return ok


func _test_ws_mock_short_and_long() -> bool:
	var cfg := BailianTtsConfigScript.new()
	cfg.apply_fixed_defaults()
	cfg.api_key = "mock-ws-default-regression"
	var player := AudioStreamPlayer.new()
	add_child(player)
	var output := VoiceOutputScript.new()
	add_child(output)
	output.setup(null, null, player, cfg)
	output.stream_tts_enabled = true
	output.bailian_ws_client.mock_mode = true
	var ok := true
	for label in ["short", "long"]:
		var text := SAMPLE_SHORT if label == "short" else SAMPLE_LONG
		var chunks := output.peek_tts_chunks(text)
		var spoke: bool = await output.speak(text, "happy", 0.5)
		ok = ok and spoke and chunks.size() >= 1
		print(
			"ws_default_regression mock_speak label=%s chunks=%d ok=%s underruns=%d"
			% [label, chunks.size(), str(spoke), output.last_stream_underrun_count()]
		)
	output.queue_free()
	player.queue_free()
	return ok


func _test_http_path_when_ws_flag_off() -> bool:
	OS.set_environment("YOUYOU_VOICE_STREAM_TTS", "0")
	var f := VoicePipelineFeatureFlagsScript.load_current()
	if f.stream_tts:
		push_error("ws_default_regression env off failed")
		OS.set_environment("YOUYOU_VOICE_STREAM_TTS", "")
		return false
	var cfg := BailianTtsConfigScript.new()
	cfg.apply_fixed_defaults()
	var output := VoiceOutputScript.new()
	output.setup(null, null, AudioStreamPlayer.new(), cfg)
	output.set_stream_tts_enabled(true)
	var uses_ws := output.stream_tts_enabled
	output.set_stream_tts_enabled(false)
	var http_path := not output.stream_tts_enabled
	OS.set_environment("YOUYOU_VOICE_STREAM_TTS", "")
	var ok := uses_ws and http_path
	print("ws_default_regression http_fallback_independent ok=%s" % str(ok))
	output.free()
	return ok
