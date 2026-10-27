extends Node

## Phase4-B.1：逗号 8 vs 24 实网 WS 首播/整段 A/B（YOUYOU_TTS_COMMA_POLICY_AB=1）。

const VoiceOutputScript := preload("res://Scripts/voice/voice_output.gd")
const BailianTtsConfigScript := preload("res://Scripts/voice/bailian_tts_config.gd")
const YouyouVoiceSecretsScript := preload("res://Scripts/voice/youyou_voice_secrets.gd")
const AliyunNlsConfigScript := preload("res://Scripts/voice/aliyun_nls_config.gd")
const MoonshotLlmClientScript := preload("res://Scripts/voice/moonshot_llm_client.gd")
const VoiceTurnLatencyScript := preload("res://Scripts/voice/voice_turn_latency.gd")

const SHORT_TEXT := "粉色兔子超软萌，要不要我帮你抓一只呀？"
const LONG_TEXT := "今天爪子状态不错，你要是看中哪只告诉我，我可以帮你分析一下位置，咱们再决定要不要出手。"


func run() -> bool:
	if not _env_truthy("YOUYOU_TTS_COMMA_POLICY_AB"):
		print("voice_tts_comma_policy_ab: SKIP")
		return true
	var cfg := BailianTtsConfigScript.new()
	YouyouVoiceSecretsScript.load_into(AliyunNlsConfigScript.new(), MoonshotLlmClientScript.new(), cfg)
	if not cfg.validate_for_tts().is_empty():
		push_error("voice_tts_comma_policy_ab: missing config")
		return false
	var rounds := _env_int("YOUYOU_TTS_COMMA_POLICY_ROUNDS", 6)
	var rows: Array = []
	for i in rounds:
		var comma_min := 8 if i % 2 == 0 else 24
		for text_id in ["short", "long"]:
			var text := SHORT_TEXT if text_id == "short" else LONG_TEXT
			var row := await _bench_ws(cfg, text, comma_min, text_id)
			rows.append(row)
	_print_summary(rows)
	return true


func _bench_ws(cfg: BailianTtsConfigScript, text: String, comma_min: int, text_id: String) -> Dictionary:
	OS.set_environment("YOUYOU_TTS_COMMA_MIN_CHARS", str(comma_min))
	OS.set_environment("YOUYOU_TTS_RELAX_COMMA", "")
	var player := AudioStreamPlayer.new()
	add_child(player)
	var lat := VoiceTurnLatencyScript.new()
	lat.enabled = true
	var output := VoiceOutputScript.new()
	add_child(output)
	output.setup(null, null, player, cfg)
	output.latency = lat
	output.stream_tts_enabled = true
	var hook_ms: Array = [-1.0]
	var t0_us := Time.get_ticks_usec()
	output.set_playback_started_hook(func() -> void:
		if float(hook_ms[0]) < 0:
			hook_ms[0] = float(Time.get_ticks_usec() - t0_us) / 1000.0
	)
	lat.start_turn("comma_ab")
	lat.mark_once("tts_start")
	var chunks := output.peek_tts_chunks(text)
	var t_speak := Time.get_ticks_usec()
	var ok := await output.speak(text, "happy", 0.6)
	var total_ms := float(Time.get_ticks_usec() - t_speak) / 1000.0
	var und := output.last_stream_underrun_count()
	var hist := VoiceTurnLatencyScript.get_history()
	var metrics_line := ""
	if not hist.is_empty():
		metrics_line = VoiceTurnLatencyScript.static_format_metrics(hist[hist.size() - 1])
	output.queue_free()
	player.queue_free()
	await get_tree().process_frame
	return {
		"comma_min": comma_min,
		"text_id": text_id,
		"text_len": text.length(),
		"chunks": chunks.size(),
		"ws_tasks": chunks.size(),
		"ok": ok,
		"playback_hook_ms": float(hook_ms[0]),
		"speak_total_ms": total_ms,
		"underruns": und,
		"metrics_line": metrics_line,
	}


func _print_summary(rows: Array) -> void:
	var by_key: Dictionary = {}
	for r in rows:
		var k := "%d|%s" % [int(r["comma_min"]), str(r["text_id"])]
		if not by_key.has(k):
			by_key[k] = []
		by_key[k].append(r)
	print("voice_tts_comma_policy_ab summary:")
	for k in by_key.keys():
		var list: Array = by_key[k]
		var hooks: Array = []
		var totals: Array = []
		var chunks_arr: Array = []
		for r in list:
			if float(r["playback_hook_ms"]) >= 0:
				hooks.append(float(r["playback_hook_ms"]))
			totals.append(float(r["speak_total_ms"]))
			chunks_arr.append(int(r["chunks"]))
		print(
			"  policy=%s n=%d chunks_avg=%s hook_avg=%s hook_p50=%s total_avg=%s total_p50=%s underrun_sum=%d"
			% [
				k,
				list.size(),
				_avg(chunks_arr),
				_avg(hooks),
				_pct(hooks, 0.5),
				_avg(totals),
				_pct(totals, 0.5),
				_sum_int(list, "underruns"),
			]
		)


func _avg(nums: Array) -> String:
	if nums.is_empty():
		return "n/a"
	var s := 0.0
	for n in nums:
		s += float(n)
	return "%.1f" % (s / float(nums.size()))


func _pct(nums: Array, p: float) -> String:
	if nums.is_empty():
		return "n/a"
	var vals: Array = []
	for n in nums:
		vals.append(float(n))
	vals.sort()
	var idx := clampi(int(ceilf(float(vals.size()) * p)) - 1, 0, vals.size() - 1)
	return "%.1f" % float(vals[idx])


func _sum_int(rows: Array, key: String) -> int:
	var s := 0
	for r in rows:
		s += int(r.get(key, 0))
	return s


func _env_truthy(name: String) -> bool:
	var v := OS.get_environment(name).strip_edges().to_lower()
	return v in ["1", "true", "yes", "on"]


func _env_int(name: String, default: int) -> int:
	var v := OS.get_environment(name).strip_edges()
	return default if not v.is_valid_int() else int(v)
