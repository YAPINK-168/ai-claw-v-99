extends Node

## Mock WS：服务端 task 已结束但 PCM 仍需本地排空；speak() 不得过早返回。

const VoiceOutputScript := preload("res://Scripts/voice/voice_output.gd")
const BailianTtsConfigScript := preload("res://Scripts/voice/bailian_tts_config.gd")
const VoiceTurnLatencyScript := preload("res://Scripts/voice/voice_turn_latency.gd")


func run() -> bool:
	var cfg := BailianTtsConfigScript.new()
	cfg.apply_fixed_defaults()
	cfg.api_key = "mock-lifecycle"
	var player := AudioStreamPlayer.new()
	add_child(player)
	var output := VoiceOutputScript.new()
	add_child(output)
	output.setup(null, null, player, cfg)
	output.stream_tts_enabled = true
	output.bailian_ws_client.mock_mode = true
	output.bailian_ws_client.mock_pcm_duration_sec = 0.45

	var t0 := Time.get_ticks_msec()
	var ok: bool = await output.speak("第一句。第二句。", "happy", 0.5)
	var elapsed := Time.get_ticks_msec() - t0
	var headless := DisplayServer.get_name() == "headless"
	var ok_time := true
	if not headless:
		# 非 headless 需实际播放 ~0.45s * 2 分句；允许帧调度误差。
		ok_time = elapsed >= 350
	print(
		"stream_tts_lifecycle_check: ok=%s elapsed_ms=%d speaking_after=%s"
		% [str(ok), elapsed, str(output.is_speaking())]
	)
	output.queue_free()
	player.queue_free()
	var passed := ok and not output.is_speaking() and ok_time
	print("=== stream_tts_lifecycle_check_pass=%s ===" % str(passed))
	return passed
