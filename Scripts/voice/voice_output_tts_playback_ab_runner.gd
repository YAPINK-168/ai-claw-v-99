extends Node

## Phase3-C2：同句 HTTP vs WS 首播 A/B（需 YOUYOU_VOICE_STREAM_TTS_PLAYBACK_AB=1，有音频设备时测 playback_start）。

const VoiceOutputScript := preload("res://Scripts/voice/voice_output.gd")
const BailianTtsConfigScript := preload("res://Scripts/voice/bailian_tts_config.gd")
const YouyouVoiceSecretsScript := preload("res://Scripts/voice/youyou_voice_secrets.gd")
const AliyunNlsConfigScript := preload("res://Scripts/voice/aliyun_nls_config.gd")
const MoonshotLlmClientScript := preload("res://Scripts/voice/moonshot_llm_client.gd")

const TEXT := "粉色兔子超软萌，要不要我帮你抓一只呀？"
const ROUNDS := 10


func run() -> bool:
	if not _env_truthy("YOUYOU_VOICE_STREAM_TTS_PLAYBACK_AB"):
		print("voice_output_tts_playback_ab: SKIP")
		return true
	var cfg := BailianTtsConfigScript.new()
	YouyouVoiceSecretsScript.load_into(AliyunNlsConfigScript.new(), MoonshotLlmClientScript.new(), cfg)
	if not cfg.validate_for_tts().is_empty():
		push_error("voice_output_tts_playback_ab: missing config")
		return false
	var http_first: Array = []
	var ws_first: Array = []
	var ws_underruns: Array = []
	for i in ROUNDS:
		if i % 2 == 0:
			http_first.append(await _bench_http(cfg))
		else:
			var ws_row: Dictionary = await _bench_ws(cfg)
			ws_first.append(ws_row.get("hook_ms", -1.0))
			ws_underruns.append(ws_row.get("underruns", 0))
	_print_ab(http_first, ws_first, ws_underruns)
	return true


func _bench_http(cfg: BailianTtsConfigScript) -> float:
	var player := AudioStreamPlayer.new()
	add_child(player)
	var output := VoiceOutputScript.new()
	add_child(output)
	output.setup(null, null, player, cfg)
	output.stream_tts_enabled = false
	var ms: Array = [-1.0]
	var t0_us := Time.get_ticks_usec()
	output.set_playback_started_hook(func() -> void:
		if float(ms[0]) < 0:
			ms[0] = float(Time.get_ticks_usec() - t0_us) / 1000.0
	)
	await output.speak(TEXT, "happy", 0.6)
	output.queue_free()
	player.queue_free()
	await get_tree().process_frame
	return float(ms[0])


func _bench_ws(cfg: BailianTtsConfigScript) -> Dictionary:
	var player := AudioStreamPlayer.new()
	add_child(player)
	var output := VoiceOutputScript.new()
	add_child(output)
	output.setup(null, null, player, cfg)
	output.stream_tts_enabled = true
	var ms: Array = [-1.0]
	var t0_us := Time.get_ticks_usec()
	output.set_playback_started_hook(func() -> void:
		if float(ms[0]) < 0:
			ms[0] = float(Time.get_ticks_usec() - t0_us) / 1000.0
	)
	await output.speak(TEXT, "happy", 0.6)
	var und := output.last_stream_underrun_count()
	output.queue_free()
	player.queue_free()
	await get_tree().process_frame
	return {"hook_ms": float(ms[0]), "underruns": und}


func _print_ab(http: Array, ws: Array, ws_underruns: Array) -> void:
	print("voice_output_tts_playback_ab http_hook_ms avg=%s p50=%s p95=%s n=%d" % [
		_avg(http), _pct(http, 0.5), _pct(http, 0.95), http.size(),
	])
	print("voice_output_tts_playback_ab ws_hook_ms avg=%s p50=%s p95=%s n=%d" % [
		_avg(ws), _pct(ws, 0.5), _pct(ws, 0.95), ws.size(),
	])
	print("voice_output_tts_playback_ab ws_underruns avg=%s p95=%s" % [
		_avg(ws_underruns), _pct(ws_underruns, 0.95),
	])


func _avg(nums: Array) -> String:
	var vals: Array = []
	for n in nums:
		if float(n) >= 0:
			vals.append(float(n))
	if vals.is_empty():
		return "n/a"
	var s := 0.0
	for v in vals:
		s += float(v)
	return "%.1f" % (s / float(vals.size()))


func _pct(nums: Array, p: float) -> String:
	var vals: Array = []
	for n in nums:
		if float(n) >= 0:
			vals.append(float(n))
	if vals.is_empty():
		return "n/a"
	vals.sort()
	var idx := clampi(int(ceilf(float(vals.size()) * p)) - 1, 0, vals.size() - 1)
	return "%.1f" % float(vals[idx])


func _env_truthy(name: String) -> bool:
	var v := OS.get_environment(name).strip_edges().to_lower()
	return v in ["1", "true", "yes", "on"]
