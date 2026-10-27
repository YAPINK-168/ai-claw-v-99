extends Node

## Phase3-C2 Step2：固定文本 + WS TTS + Godot 实际播放（需 YOUYOU_VOICE_STREAM_TTS_LIVE_PLAY=1）。

const VoiceOutputScript := preload("res://Scripts/voice/voice_output.gd")
const BailianTtsConfigScript := preload("res://Scripts/voice/bailian_tts_config.gd")
const YouyouVoiceSecretsScript := preload("res://Scripts/voice/youyou_voice_secrets.gd")
const AliyunNlsConfigScript := preload("res://Scripts/voice/aliyun_nls_config.gd")
const MoonshotLlmClientScript := preload("res://Scripts/voice/moonshot_llm_client.gd")
const VoiceTurnLatencyScript := preload("res://Scripts/voice/voice_turn_latency.gd")

const TEXT := "粉色兔子超软萌，要不要我帮你抓一只呀？"


func run() -> bool:
	if not _env_truthy("YOUYOU_VOICE_STREAM_TTS_LIVE_PLAY"):
		print("voice_output_stream_tts_playback_check: SKIP (set YOUYOU_VOICE_STREAM_TTS_LIVE_PLAY=1)")
		print("=== voice_output_stream_tts_playback_check_pass=true ===")
		return true

	var cfg := BailianTtsConfigScript.new()
	var aliyun := AliyunNlsConfigScript.new()
	var moon := MoonshotLlmClientScript.new()
	YouyouVoiceSecretsScript.load_into(aliyun, moon, cfg)
	if not cfg.validate_for_tts().is_empty():
		push_error("voice_output_stream_tts_playback_check: missing TTS config")
		return false

	var player := AudioStreamPlayer.new()
	add_child(player)
	var output := VoiceOutputScript.new()
	add_child(output)
	output.setup(null, null, player, cfg)
	output.stream_tts_enabled = true
	var latency := VoiceTurnLatencyScript.new()
	latency.enabled = true
	output.latency = latency
	var playback_ms: Array = [-1]
	var t0 := Time.get_ticks_msec()
	output.set_playback_started_hook(func() -> void:
		if int(playback_ms[0]) < 0:
			playback_ms[0] = Time.get_ticks_msec() - t0
	)

	latency.start_turn("stream_tts_live_play")
	var ok: bool = await output.speak(TEXT, "happy", 0.6)
	print(
		"voice_output_stream_tts_playback_check: ok=%s playback_ms=%s ws_first=%s"
		% [
			str(ok),
			str(int(playback_ms[0])),
			str(latency.has_mark("tts_ws_first_pcm")),
		]
	)
	output.queue_free()
	player.queue_free()
	print("=== voice_output_stream_tts_playback_check_pass=%s ===" % str(ok and int(playback_ms[0]) >= 0))
	return ok and int(playback_ms[0]) >= 0


func _env_truthy(name: String) -> bool:
	var v := OS.get_environment(name).strip_edges().to_lower()
	return v in ["1", "true", "yes", "on"]
