extends Node

## Phase4-B.1：Headless 分句诊断（8 字 vs 24 字，不接网络）。

const VoiceOutputScript := preload("res://Scripts/voice/voice_output.gd")
const SplitConfigScript := preload("res://Scripts/voice/voice_tts_split_config.gd")

const SAMPLE_SHORT_COMMA := "粉色兔子超软萌，要不要我帮你抓一只呀？"
const SAMPLE_MULTI_COMMA := "好呀，我这就帮你看看爪子准不准，稍等一下哦。"
const SAMPLE_40_60 := "今天爪子状态不错，你要是看中哪只告诉我，我可以帮你分析一下位置，咱们再决定要不要出手。"
const SAMPLE_STRONG := "真的吗？太好了！"
const ANDROID_BOUNDARY := "一二三四五六七八九十，一二三四五六七八九十，一二三四五六七八九十，一二三四五六七八九十。"


func run() -> bool:
	OS.set_environment("YOUYOU_TTS_COMMA_MIN_CHARS", "")
	OS.set_environment("YOUYOU_TTS_RELAX_COMMA", "")
	SplitConfigScript.reset_log_for_tests()
	var ok := true
	ok = ok and _compare_policies()
	ok = ok and _assert_default_short_replies()
	print("=== tts_chunk_diagnostic_pass=%s ===" % str(ok))
	return ok


func _compare_policies() -> bool:
	var cases: Array = [
		{"name": "short_comma", "text": SAMPLE_SHORT_COMMA},
		{"name": "multi_comma", "text": SAMPLE_MULTI_COMMA},
		{"name": "forty_sixty", "text": SAMPLE_40_60},
		{"name": "strong_punct", "text": SAMPLE_STRONG},
		{"name": "android_boundary", "text": ANDROID_BOUNDARY},
	]
	for c in cases:
		var t: String = c["text"]
		var a: int = _chunk_count_with_comma_min(8, t)
		var b: int = _chunk_count_with_comma_min(24, t)
		print(
			"tts_chunk_policy case=%s len=%d chunks_8=%d chunks_24=%d"
			% [c["name"], t.length(), a, b]
		)
		if c["name"] == "short_comma" and b != 1:
			push_error("tts_chunk_diagnostic: short_comma expected 1 chunk at comma_min=24")
			return false
	return true


func _assert_default_short_replies() -> bool:
	SplitConfigScript.reset_log_for_tests()
	var vo := VoiceOutputScript.new()
	var effective := SplitConfigScript.comma_break_min_chars()
	print(
		"tts_chunk_diagnostic effective_comma_min=%d source=%s platform=%s"
		% [effective, SplitConfigScript.comma_break_source(), OS.get_name()]
	)
	var n1 := vo.peek_tts_chunks(SAMPLE_SHORT_COMMA).size()
	var n2 := vo.peek_tts_chunks(SAMPLE_MULTI_COMMA).size()
	print("tts_chunk_diagnostic default short_comma chunks=%d multi_comma chunks=%d" % [n1, n2])
	vo.free()
	if effective != 24:
		push_warning("tts_chunk_diagnostic: project default expected 24, got %d" % effective)
	var ok := n1 == 1 and n2 == 1
	if not ok:
		push_error("tts_chunk_diagnostic: default short replies should be single chunk")
	return ok


func _chunk_count_with_comma_min(comma_min: int, text: String) -> int:
	var prev := OS.get_environment("YOUYOU_TTS_COMMA_MIN_CHARS")
	OS.set_environment("YOUYOU_TTS_COMMA_MIN_CHARS", str(comma_min))
	OS.set_environment("YOUYOU_TTS_RELAX_COMMA", "")
	var vo := VoiceOutputScript.new()
	var n := vo.peek_tts_chunks(text).size()
	vo.free()
	OS.set_environment("YOUYOU_TTS_COMMA_MIN_CHARS", prev)
	return n
