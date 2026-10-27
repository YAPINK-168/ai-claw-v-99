extends RefCounted
class_name YouyouActionSplitExpressionTimelines

## 动作内 split 眼/嘴槽位时间轴（squint mix 导出；含第二局 crane01_01–05）。

const CONFIG_PATH := "res://config/youyou_action_split_expression_timelines.json"
const SCHEMA := "youyou_action_split_expression_timelines_v1"

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
		return not _actions.is_empty()
	_loaded = true
	_meta = {}
	_actions = {}
	if not FileAccess.file_exists(CONFIG_PATH):
		push_warning("Split 表情时间轴配置缺失：" + CONFIG_PATH)
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not (parsed is Dictionary):
		push_error("Split 表情时间轴 JSON 无效")
		return false
	var root: Dictionary = parsed
	if String(root.get("schema", "")) != SCHEMA:
		push_warning("Split 表情时间轴 schema 不匹配")
	var raw: Variant = root.get("actions", {})
	if raw is Dictionary:
		_actions = raw as Dictionary
	_meta = root.duplicate()
	_meta.erase("actions")
	return not _actions.is_empty()


static func default_slot_blend_sec() -> float:
	load_config()
	return maxf(float(_meta.get("default_slot_blend_sec", 0.35)), 0.01)


## 第二局 crane01：01 无末尾渐出；02–04 无首尾渐入渐出；05 无首部渐入。
## crane03：01 保留开头 0.35s、取消末尾；02–07 槽首尾默认无 0.35s；03/04 槽位无渐出。
static func slot_fade_overrides(action_id: String) -> Dictionary:
	match action_id:
		"youyou_claw crane01_01":
			return {"no_fade_out": true}
		"youyou_claw crane01_02", "youyou_claw crane01_03", "youyou_claw crane01_04":
			return {"no_fade_in": true, "no_fade_out": true}
		"youyou_claw crane01_05":
			return {"no_fade_in": true}
		"youyou_claw_crane03_01":
			return {"no_fade_out": true}
		"youyou_claw_crane03_03", "youyou_claw_crane03_04":
			return {"no_fade_in": true, "no_fade_out": true}
		"youyou_claw_crane03_02", "youyou_claw_crane03_02_post_scare", "youyou_claw_crane03_05", "youyou_claw_crane03_06", "youyou_claw_crane03_07":
			return {"no_fade_in": true, "no_fade_out": true}
	return {}


static func max_expression_end_sec(action_id: String) -> float:
	var max_end := 0.0
	for raw in get_expressions(action_id):
		if raw is Dictionary:
			max_end = maxf(max_end, float((raw as Dictionary).get("end_sec", 0.0)))
	return max_end


## 03/04：槽位结束后仍按末槽采样，避免槽 end 前渐出或 end 后表情被清零。
static func clamp_split_eval_time(action_id: String, t_sec: float) -> float:
	if action_id != "youyou_claw_crane03_03" and action_id != "youyou_claw_crane03_04":
		return t_sec
	var max_end := max_expression_end_sec(action_id)
	if max_end <= 0.0:
		return t_sec
	if t_sec >= max_end - 0.0005:
		return max_end
	return t_sec


static func apply_slot_fade_overrides(action_id: String, entry: Dictionary) -> Dictionary:
	var out := entry.duplicate(true)
	var ov := slot_fade_overrides(action_id)
	for key in ov:
		out[key] = ov[key]
	return out


static func is_code_only_action(action_id: String) -> bool:
	return action_id in CODE_ONLY_ACTION_IDS


static func has_timeline(action_id: String) -> bool:
	if is_code_only_action(action_id):
		return false
	load_config()
	return _actions.has(action_id)


static func get_expressions(action_id: String) -> Array:
	if is_code_only_action(action_id):
		return []
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
		if id != "" and not is_code_only_action(id):
			ids.append(id)
	ids.sort()
	return ids


static func export_actions_for_project() -> Dictionary:
	load_config()
	return _actions.duplicate(true)
