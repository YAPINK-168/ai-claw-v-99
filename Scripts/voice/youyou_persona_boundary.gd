extends RefCounted
class_name YouyouPersonaBoundary

## Phase4-C.1：reply 业务边界扫描（与 Prompt 一致，供 live 测试）。

const BUSINESS_VIOLATION_PATTERNS: Array[String] = [
	"一定.*抓",
	"保证.*抓",
	"肯定能抓",
	"必中",
	"包中",
	"打包票",
	"下次一定",
	"一定能抓到",
	"练到抓到为止",
	"100%抓",
]


static func business_violation_reason(reply: String) -> String:
	var t := reply.strip_edges()
	if t.is_empty():
		return ""
	for pat in BUSINESS_VIOLATION_PATTERNS:
		var re := RegEx.new()
		if re.compile(pat) != OK:
			continue
		if re.search(t) == null:
			continue
		if _is_refusal_context(t, pat):
			continue
		return "business_promise:" + pat
	return ""


static func _is_refusal_context(text: String, pattern: String) -> bool:
	## 拒绝承诺时可能仍出现「打包票/必中」等词，不算业务越界。
	if pattern in ["打包票", "包中", "必中"]:
		for neg in ["没法", "不能", "不可", "不敢", "不会", "无法", "别指望", "没那"]:
			if text.contains(neg):
				return true
	return false
