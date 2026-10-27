extends Node

## Phase3-C1：HTTP TTS vs WebSocket 流式 TTS 隔离 A/B（固定文本，不接 VoiceOutput / Moonshot）。

const BailianTtsConfigScript := preload("res://Scripts/voice/bailian_tts_config.gd")
const BailianTtsClientScript := preload("res://Scripts/voice/bailian_tts_client.gd")
const BailianTtsWsClientScript := preload("res://Scripts/voice/bailian_tts_ws_client.gd")
const AudioBytesUtilScript := preload("res://Scripts/voice/audio_bytes_util.gd")
const YouyouVoiceSecretsScript := preload("res://Scripts/voice/youyou_voice_secrets.gd")
const AliyunNlsConfigScript := preload("res://Scripts/voice/aliyun_nls_config.gd")
const MoonshotLlmClientScript := preload("res://Scripts/voice/moonshot_llm_client.gd")

const DEFAULT_TEXT := "粉色兔子超软萌，要不要我帮你抓一只呀？"
const DEFAULT_INSTRUCTION := "情绪：开心"
const DEFAULT_ROUNDS := 10


func run() -> bool:
	var mock_only := _env_truthy("YOUYOU_BAILIAN_TTS_ISOLATED_MOCK")
	var live_ab := _env_truthy("YOUYOU_BAILIAN_TTS_ISOLATED_LIVE")
	var rounds := _env_int("YOUYOU_BAILIAN_TTS_AB_ROUNDS", DEFAULT_ROUNDS)
	var text := _env_str("YOUYOU_BAILIAN_TTS_AB_TEXT", DEFAULT_TEXT)
	var instruction := _env_str("YOUYOU_BAILIAN_TTS_AB_INSTRUCTION", DEFAULT_INSTRUCTION)

	print("bailian_tts_isolated_check: start mock_only=%s live_ab=%s rounds=%d" % [mock_only, live_ab, rounds])

	var mock_ok := await _run_mock_suite()
	if not mock_ok:
		print("bailian_tts_isolated_check: FAIL mock_suite")
		return false

	var config := BailianTtsConfigScript.new()
	var aliyun := AliyunNlsConfigScript.new()
	var moonshot := MoonshotLlmClientScript.new()
	YouyouVoiceSecretsScript.load_into(aliyun, moonshot, config)
	var cfg_err := config.validate_for_tts()
	var ws_url := config.get_websocket_inference_url()
	print(
		"bailian_tts_isolated_check: protocol model=%s voice=%s ws_host=%s cfg_ok=%s"
		% [
			config.model,
			config.voice,
			_redact_url(ws_url),
			cfg_err.is_empty(),
		]
	)

	if not live_ab:
		print("bailian_tts_isolated_check: PASS (mock only; set YOUYOU_BAILIAN_TTS_ISOLATED_LIVE=1 for实机 A/B)")
		print("bailian_tts_isolated_check: real_device_ab=NOT_RUN")
		return true

	if not cfg_err.is_empty():
		print("bailian_tts_isolated_check: SKIP live (config: %s)" % cfg_err)
		print("bailian_tts_isolated_check: real_device_ab=NOT_RUN")
		return mock_only

	if mock_only:
		print("bailian_tts_isolated_check: SKIP live (YOUYOU_BAILIAN_TTS_ISOLATED_MOCK=1)")
		print("bailian_tts_isolated_check: real_device_ab=NOT_RUN")
		return true

	var ab := await _run_live_ab(config, text, instruction, rounds)
	_print_ab_summary(ab)
	var fail_rate := float(ab.get("failed", 0)) / float(max(ab.get("attempts", 1), 1))
	return ab.get("ws_voice_ok", false) and fail_rate < 0.5


func _run_mock_suite() -> bool:
	var cfg := BailianTtsConfigScript.new()
	cfg.apply_fixed_defaults()
	var ws := BailianTtsWsClientScript.new()
	add_child(ws)
	ws.setup(cfg)
	ws.mock_mode = true

	var r1: Dictionary = await ws.synthesize_pcm("测试", "情绪：开心")
	if not r1.get("ok", false):
		return false
	var m1: Dictionary = r1.get("metrics", {})
	if m1.get("first_audio_frame_ms", null) == null:
		return false

	ws.cancel()
	var r2: Dictionary = await ws.synthesize_pcm("取消后", "情绪：开心")
	if not r2.get("ok", false):
		return false

	if cfg.get_websocket_inference_url().is_empty() and cfg.get_workspace_root().is_empty():
		pass
	else:
		var url := cfg.get_websocket_inference_url()
		if not url.begins_with("wss://") or not url.ends_with("/api-ws/v1/inference"):
			return false

	ws.queue_free()
	return true


func _run_live_ab(config: BailianTtsConfigScript, text: String, instruction: String, rounds: int) -> Dictionary:
	var http := BailianTtsClientScript.new()
	var ws := BailianTtsWsClientScript.new()
	add_child(http)
	add_child(ws)
	http.setup(config)
	ws.setup(config)

	var http_cold: Array = []
	var ws_cold: Array = []
	var ws_preconnect: Array = []
	var ws_voice_ok := true
	var failed := 0
	var attempts := 0

	for i in rounds:
		if i % 2 == 0:
			attempts += 1
			var row := await _bench_http(http, text, instruction, "cold")
			http_cold.append(row)
			if not row.get("ok", false):
				failed += 1
		else:
			attempts += 1
			ws.cancel()
			var row_c := await _bench_ws(ws, text, instruction, false)
			ws_cold.append(row_c)
			if not row_c.get("ok", false):
				failed += 1
				if _looks_like_voice_reject(row_c.get("error", "")):
					ws_voice_ok = false

	for j in mini(rounds, 5):
		if j == 0:
			ws.cancel()
			if not await ws.preconnect():
				ws_preconnect.append({"ok": false, "error": "preconnect_failed", "mode": "preconnect"})
				failed += 1
				continue
		attempts += 1
		var row_p := await _bench_ws(ws, text, instruction, true)
		row_p["mode"] = "preconnect"
		ws_preconnect.append(row_p)
		if not row_p.get("ok", false):
			failed += 1

	ws.cancel()
	http.queue_free()
	ws.queue_free()

	return {
		"http_cold": http_cold,
		"ws_cold": ws_cold,
		"ws_preconnect": ws_preconnect,
		"failed": failed,
		"attempts": attempts,
		"ws_voice_ok": ws_voice_ok,
	}


func _bench_http(client: BailianTtsClientScript, text: String, instruction: String, mode: String) -> Dictionary:
	var t0 := Time.get_ticks_msec()
	var res: Dictionary = await client.synthesize_text(text, instruction)
	var t1 := Time.get_ticks_msec()
	var decode_ok := false
	var dur := 0.0
	if res.get("ok", false):
		var audio: PackedByteArray = res.get("audio", PackedByteArray())
		var stream := AudioBytesUtilScript.stream_from_bytes(audio)
		decode_ok = stream != null
		dur = float(res.get("duration_sec", 0.0))
	return {
		"ok": res.get("ok", false),
		"mode": mode,
		"path": "http",
		"total_ms": float(t1 - t0),
		"first_audio_ready_ms": float(t1 - t0),
		"decode_ok": decode_ok,
		"duration_sec": dur,
		"error": str(res.get("error", "")),
	}


func _bench_ws(client: BailianTtsWsClientScript, text: String, instruction: String, reuse: bool) -> Dictionary:
	var res: Dictionary = await client.synthesize_pcm(text, instruction, reuse)
	var m: Dictionary = res.get("metrics", {})
	return {
		"ok": res.get("ok", false),
		"mode": "preconnect" if reuse else "cold",
		"path": "ws_pcm",
		"connect_ms": m.get("connect_ms", null),
		"first_audio_frame_ms": m.get("first_audio_frame_ms", null),
		"playable_pcm_ms": m.get("playable_pcm_ms", null),
		"total_ms": m.get("total_ms", null),
		"decode_ok": m.get("decode_ok", false),
		"pcm_bytes": m.get("pcm_bytes", 0),
		"stale_binary_drops": m.get("stale_binary_drops", 0),
		"error": str(res.get("error", "")),
	}


func _print_ab_summary(ab: Dictionary) -> void:
	print("bailian_tts_ab_summary: attempts=%d failed=%d" % [ab.get("attempts", 0), ab.get("failed", 0)])
	_print_stats("http_cold", ab.get("http_cold", []))
	_print_stats("ws_cold", ab.get("ws_cold", []))
	_print_stats("ws_preconnect", ab.get("ws_preconnect", []))
	print("bailian_tts_ab_summary: ws_voice_ok=%s" % ab.get("ws_voice_ok", false))
	print("bailian_tts_ab_summary: timbre_subjective=NOT_RUN (需人工听感对比 HTTP vs WS)")
	print("bailian_tts_isolated_check: real_device_ab=COMPLETED")


func _print_stats(label: String, rows: Array) -> void:
	var totals: Array = []
	var firsts: Array = []
	var oks := 0
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		if row.get("ok", false):
			oks += 1
		var tot = row.get("total_ms", null)
		if tot != null:
			totals.append(float(tot))
		var fa = row.get("first_audio_frame_ms", row.get("first_audio_ready_ms", null))
		if fa != null:
			firsts.append(float(fa))
	print(
		"bailian_tts_ab_%s: n=%d ok=%d total_ms avg=%s first_ms avg=%s"
		% [label, rows.size(), oks, _avg(totals), _avg(firsts)]
	)


func _avg(nums: Array) -> String:
	if nums.is_empty():
		return "n/a"
	var s := 0.0
	for n in nums:
		s += float(n)
	return "%.1f" % (s / float(nums.size()))


func _looks_like_voice_reject(err: String) -> bool:
	var e := err.to_lower()
	return e.contains("voice") or e.contains("invalid") or e.contains("not found") or e.contains("permission")


func _env_truthy(name: String) -> bool:
	var v := OS.get_environment(name).strip_edges().to_lower()
	return v in ["1", "true", "yes", "on"]


func _env_int(name: String, default_val: int) -> int:
	var v := OS.get_environment(name).strip_edges()
	if v.is_empty():
		return default_val
	return int(v)


func _env_str(name: String, default_val: String) -> String:
	var v := OS.get_environment(name).strip_edges()
	return v if not v.is_empty() else default_val


func _redact_url(url: String) -> String:
	if url.is_empty():
		return "(empty)"
	return url.split("/api-ws")[0] + "/api-ws/..."
