extends Node

## C2.1：流式 TTS 取消/抢占 Mock（播放中 stop、正常结束）。

const VoiceOutputScript := preload("res://Scripts/voice/voice_output.gd")
const BailianTtsConfigScript := preload("res://Scripts/voice/bailian_tts_config.gd")


func run() -> bool:
	var cfg := BailianTtsConfigScript.new()
	cfg.apply_fixed_defaults()
	cfg.api_key = "mock-preempt"
	var player := AudioStreamPlayer.new()
	add_child(player)
	var output := VoiceOutputScript.new()
	add_child(output)
	output.setup(null, null, player, cfg)
	output.stream_tts_enabled = true
	output.bailian_ws_client.mock_mode = true

	var ok := true
	var cancel_ok: bool = await _speak_interrupt(output, 0.05)
	ok = ok and not cancel_ok and not output.is_speaking()

	var t3: bool = await output.speak("正常结束。", "happy", 0.5)
	ok = ok and t3

	output.queue_free()
	player.queue_free()
	print("=== stream_tts_preempt_check_pass=%s ===" % str(ok))
	return ok


func _speak_interrupt(output: VoiceOutputScript, delay_sec: float) -> bool:
	var done: Array = [false]
	var result: Array = [false]
	_run_speak_async(output, done, result)
	await get_tree().create_timer(delay_sec).timeout
	output.stop(true)
	while not bool(done[0]):
		await get_tree().process_frame
	return bool(result[0])


func _run_speak_async(output: VoiceOutputScript, done: Array, result: Array) -> void:
	result[0] = await output.speak("播放中取消测试。", "happy", 0.5)
	done[0] = true
