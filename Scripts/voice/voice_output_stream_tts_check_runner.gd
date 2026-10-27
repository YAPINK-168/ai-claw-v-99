extends Node

## Phase3-C2 Step3：VoiceOutput + Mock WS 流式 TTS（Headless，无 Preview 桥）。

const VoiceOutputScript := preload("res://Scripts/voice/voice_output.gd")
const BailianTtsConfigScript := preload("res://Scripts/voice/bailian_tts_config.gd")
const BailianTtsWsClientScript := preload("res://Scripts/voice/bailian_tts_ws_client.gd")
const VoiceTurnLatencyScript := preload("res://Scripts/voice/voice_turn_latency.gd")


func run() -> bool:
	var cfg := BailianTtsConfigScript.new()
	cfg.apply_fixed_defaults()
	cfg.api_key = "mock-stream-tts-check"
	var player := AudioStreamPlayer.new()
	add_child(player)
	var output := VoiceOutputScript.new()
	add_child(output)
	output.setup(null, null, player, cfg)
	output.stream_tts_enabled = true
	output.bailian_ws_client.mock_mode = true
	var latency := VoiceTurnLatencyScript.new()
	latency.enabled = true
	output.latency = latency

	var hook := 0
	output.set_playback_started_hook(func() -> void: hook += 1)

	latency.start_turn("stream_tts_mock")
	var ok_speak: bool = await output.speak("你好呀。", "happy", 0.5)
	var headless := DisplayServer.get_name() == "headless"
	var ok := ok_speak and latency.has_mark("tts_ws_first_pcm")
	ok = ok and latency.has_mark("tts_first_audio_ready")
	if headless:
		ok = ok and not latency.has_mark("playback_start")
	else:
		ok = ok and hook >= 1 and latency.has_mark("playback_start")

	output.stop(true)
	ok = ok and not output.is_speaking()

	output.queue_free()
	player.queue_free()
	print("=== voice_output_stream_tts_check_pass=%s hook=%d ===" % [str(ok), hook])
	return ok
