extends RefCounted
class_name MinigameIntentRules

## 本地意愿词表：PLAY / DECLINE / UNKNOWN（互斥）。

const PLAY_PHRASES: PackedStringArray = [
	"我想玩", "我要玩", "玩一个", "来一个", "好啊", "来吧", "可以", "行啊", "要玩",
]
const DECLINE_PHRASES: PackedStringArray = [
	"不想玩", "不玩", "不用了", "不要了", "不要", "算了", "先不玩", "下次吧", "改天",
]
const UNKNOWN_SHORT: PackedStringArray = ["不", "不是", "没", "没有", "听不清"]


static func classify(text: String) -> String:
	var t := _norm(text)
	if t.is_empty():
		return "UNKNOWN"
	for phrase in DECLINE_PHRASES:
		if t.contains(phrase):
			return "DECLINE"
	if _negated_play(t):
		return "UNKNOWN"
	for phrase in PLAY_PHRASES:
		if t.contains(phrase):
			return "PLAY"
	if t in ["好", "可以", "行", "要", "玩"]:
		return "PLAY"
	if t.contains("玩"):
		var idx := t.find("玩")
		var before := t.substr(0, idx)
		if before.contains("不"):
			return "UNKNOWN"
		return "PLAY"
	for phrase in UNKNOWN_SHORT:
		if t == phrase or t.begins_with(phrase):
			return "UNKNOWN"
	return "UNKNOWN"


static func can_early_commit(intent: String) -> bool:
	return intent == "PLAY" or intent == "DECLINE"


static func _norm(text: String) -> String:
	return text.strip_edges().replace(" ", "").replace("，", "").replace("。", "")


static func _negated_play(t: String) -> bool:
	if t.contains("不想玩") or t.contains("不玩"):
		return true
	if t.contains("不想") and not t.contains("玩"):
		return true
	if t.begins_with("不") and t.contains("玩"):
		return true
	if t == "我想" or t == "我要":
		return true
	return false
