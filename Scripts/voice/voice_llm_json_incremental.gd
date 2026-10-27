extends RefCounted
class_name VoiceLlmJsonIncremental

## Moonshot 结构化 JSON 的增量提取（第三阶段设计用）。
## 本阶段不接入 YouyouDialogueClient / 正式 TTS 链路。

enum ExtractState { INCOMPLETE, PARTIAL_REPLY, COMPLETE_OBJECT }


## 从可能未闭合的 JSON 文本中提取 reply 字段（字符串值，支持转义）。
## 返回 { state, reply, raw_candidate }；reply 仅在 COMPLETE_OBJECT 或 PARTIAL_REPLY 时非空。
static func extract_reply_progress(raw: String) -> Dictionary:
	var text := _strip_markdown_fence(raw.strip_edges())
	var start := text.find("{")
	if start < 0:
		return {"state": ExtractState.INCOMPLETE, "reply": "", "raw_candidate": ""}
	var slice := text.substr(start)
	var end_brace := slice.rfind("}")
	if end_brace > 0:
		var parsed: Variant = JSON.parse_string(slice.substr(0, end_brace + 1))
		if typeof(parsed) == TYPE_DICTIONARY:
			var d: Dictionary = parsed
			var full_reply := str(d.get("reply", "")).strip_edges()
			if not full_reply.is_empty():
				return {
					"state": ExtractState.COMPLETE_OBJECT,
					"reply": full_reply,
					"raw_candidate": slice.substr(0, end_brace + 1),
				}
	var reply := _scan_reply_string_value(slice)
	var partial: String = str(reply.get("value", ""))
	if not partial.is_empty():
		return {
			"state": ExtractState.PARTIAL_REPLY,
			"reply": partial,
			"raw_candidate": slice,
		}
	return {"state": ExtractState.INCOMPLETE, "reply": "", "raw_candidate": slice}


static func is_safe_for_tts(extract: Dictionary) -> bool:
	return int(extract.get("state", ExtractState.INCOMPLETE)) == ExtractState.COMPLETE_OBJECT


static func _strip_markdown_fence(text: String) -> String:
	if not text.begins_with("```"):
		return text
	var first_nl := text.find("\n")
	if first_nl >= 0:
		text = text.substr(first_nl + 1)
	var fence := text.rfind("```")
	if fence >= 0:
		text = text.substr(0, fence)
	return text.strip_edges()


static func _scan_reply_string_value(json_from_brace: String) -> Dictionary:
	var key := "\"reply\""
	var ki := json_from_brace.find(key)
	if ki < 0:
		return {"complete": false, "value": "", "end_index": -1}
	var i := ki + key.length()
	while i < json_from_brace.length() and json_from_brace[i] in [" ", "\t", "\n", "\r"]:
		i += 1
	if i >= json_from_brace.length() or json_from_brace[i] != ":":
		return {"complete": false, "value": "", "end_index": -1}
	i += 1
	while i < json_from_brace.length() and json_from_brace[i] in [" ", "\t", "\n", "\r"]:
		i += 1
	if i >= json_from_brace.length() or json_from_brace[i] != "\"":
		return {"complete": false, "value": "", "end_index": -1}
	i += 1
	var sb := PackedStringArray()
	var escaped := false
	while i < json_from_brace.length():
		var c := json_from_brace[i]
		if escaped:
			match c:
				"n":
					sb.append("\n")
				"t":
					sb.append("\t")
				"r":
					sb.append("\r")
				"\\", "\"", "/":
					sb.append(c)
				_:
					sb.append(c)
			escaped = false
			i += 1
			continue
		if c == "\\":
			escaped = true
			i += 1
			continue
		if c == "\"":
			return {"complete": true, "value": "".join(sb), "end_index": i}
		sb.append(c)
		i += 1
	return {"complete": false, "value": "".join(sb), "end_index": i}
