extends RefCounted
class_name DoudouActionSplitExpressionTimelines

## 兜兜动作内 split 眼/嘴槽位（squint mix 导出）。

const CONFIG_PATH := "res://config/doudou_action_split_expression_timelines.json"
const SCHEMA := "doudou_action_split_expression_timelines_v1"

const CODE_ONLY_ACTION_IDS: PackedStringArray = []

static var _meta: Dictionary = {}
static var _actions: Dictionary = {}
static var _loaded := false


static func reload() -> void:
	_loaded = false
	_meta = {}
	_actions = {}
	load_config()


static func load_config() -> bool:
	if _loaded:
		return not _actions.is_empty() or FileAccess.file_exists(CONFIG_PATH)
	_loaded = true
	_meta = {}
	_actions = {}
	if not FileAccess.file_exists(CONFIG_PATH):
		push_warning("兜兜 Split 表情时间轴配置缺失：" + CONFIG_PATH)
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not (parsed is Dictionary):
		push_error("兜兜 Split 表情时间轴 JSON 无效")
		return false
	var root: Dictionary = parsed
	if String(root.get("schema", "")) != SCHEMA:
		push_warning("兜兜 Split 表情时间轴 schema 不匹配")
	var raw: Variant = root.get("actions", {})
	if raw is Dictionary:
		_actions = raw as Dictionary
	_meta = root.duplicate()
	_meta.erase("actions")
	return true


static func default_slot_blend_sec() -> float:
	load_config()
	return maxf(float(_meta.get("default_slot_blend_sec", 0.35)), 0.01)


static func is_code_only_action(_action_id: String) -> bool:
	return false


static func has_timeline(action_id: String) -> bool:
	load_config()
	return _actions.has(action_id)


static func get_expressions(action_id: String) -> Array:
	load_config()
	var bucket: Variant = _actions.get(action_id, {})
	if bucket is Dictionary:
		var expr: Variant = (bucket as Dictionary).get("expressions", [])
		if expr is Array:
			return (expr as Array).duplicate(true)
	return []


static func all_action_ids() -> PackedStringArray:
	load_config()
	var ids: PackedStringArray = []
	for key in _actions.keys():
		var id := String(key)
		if id != "":
			ids.append(id)
	ids.sort()
	return ids


static func export_actions_for_project() -> Dictionary:
	load_config()
	return _actions.duplicate(true)
