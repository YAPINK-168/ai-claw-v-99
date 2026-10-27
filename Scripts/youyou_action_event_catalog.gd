extends RefCounted
class_name YouyouActionEventCatalog

## 事件动作登记（测试场专用，禁止目录扫描、禁止自动并入正式池）。

const CONFIG_PATH := "res://config/youyou_action_event_catalog.json"

const ALLOWED_ACCEPTANCE: PackedStringArray = ["draft", "pending"]

const TIMELINE_PERSIST_KEYS: PackedStringArray = [
	"playback_start",
	"playback_end",
	"pre_idle_duration",
	"post_idle_duration",
	"audio_start_offset",
	"audio_speed",
	"action_speed",
	"emotion_lead_time",
	"emotion_blend_duration",
	"mouth_release_duration",
	"idle_expression_return_duration",
	"mouth_emotion_weight",
	"viseme_weight",
	"manual_acceptance_status",
	"notes",
]

static var _entries: Array[Dictionary] = []
static var _meta: Dictionary = {}
static var _loaded := false
static var _runtime_patch: Dictionary = {}


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_entries = []
	_meta = {}
	if not ResExists.path(CONFIG_PATH):
		push_error("事件动作登记缺失：" + CONFIG_PATH)
		return
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("无法读取：" + CONFIG_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("事件登记 JSON 格式错误")
		return
	_meta = parsed.duplicate()
	_meta.erase("entries")
	var raw: Variant = parsed.get("entries", [])
	if typeof(raw) != TYPE_ARRAY:
		push_error("事件登记 entries 必须为数组")
		return
	for item in raw:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = item
		var status := String(entry.get("manual_acceptance_status", "draft"))
		if status not in ALLOWED_ACCEPTANCE:
			push_warning(
				"事件动作 %s 验收状态 %s 非法，已视为 draft"
				% [String(entry.get("action_id", "?")), status]
			)
			entry["manual_acceptance_status"] = "draft"
		_entries.append(entry)


static func reload_from_disk() -> void:
	_loaded = false
	_entries = []
	_meta = {}
	ensure_loaded()


static func get_catalog_notes() -> String:
	ensure_loaded()
	return String(_meta.get("catalog_notes", ""))


static func get_entries() -> Array[Dictionary]:
	ensure_loaded()
	return _entries.duplicate()


static func set_runtime_patch(action_id: String, fields: Dictionary) -> void:
	if fields.is_empty():
		_runtime_patch.erase(action_id)
		return
	var merged: Dictionary = _runtime_patch.get(action_id, {})
	for key in fields:
		merged[key] = fields[key]
	_runtime_patch[action_id] = merged


static func find_entry(action_id: String) -> Dictionary:
	ensure_loaded()
	for entry in _entries:
		if String(entry.get("action_id", "")) == action_id:
			var out := entry.duplicate()
			if _runtime_patch.has(action_id):
				for key in _runtime_patch[action_id]:
					out[key] = _runtime_patch[action_id][key]
			return out
	return {}


static func get_action_ids() -> PackedStringArray:
	ensure_loaded()
	var ids: PackedStringArray = []
	for entry in _entries:
		ids.append(String(entry.get("action_id", "")))
	return ids


static func validate_registry() -> Dictionary:
	ensure_loaded()
	var issues: PackedStringArray = []
	var ids_seen: Dictionary = {}
	for entry in _entries:
		var aid := String(entry.get("action_id", ""))
		if aid == "":
			issues.append("条目缺少 action_id")
			continue
		if ids_seen.has(aid):
			issues.append("重复 action_id：" + aid)
		ids_seen[aid] = true
		if String(entry.get("scene", "")) == "":
			issues.append("%s 缺少 scene" % aid)
		var status := String(entry.get("manual_acceptance_status", ""))
		if status not in ALLOWED_ACCEPTANCE:
			issues.append("%s 验收状态非法：%s" % [aid, status])
	return {"ok": issues.is_empty(), "issues": issues, "count": _entries.size()}


static func persist_timeline_params_to_config(timeline_params: Dictionary) -> Dictionary:
	ensure_loaded()
	var action_id := String(timeline_params.get("action_id", ""))
	if action_id == "":
		return {"ok": false, "reason": "缺少 action_id"}
	if not ResExists.path(CONFIG_PATH):
		return {"ok": false, "reason": "catalog 文件不存在"}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not (parsed is Dictionary):
		return {"ok": false, "reason": "catalog JSON 无效"}
	var root: Dictionary = parsed
	var entries: Variant = root.get("entries", [])
	if not (entries is Array):
		return {"ok": false, "reason": "entries 不是数组"}
	var clip_total := maxf(float(timeline_params.get("clip_total_duration", 0.0)), 0.0)
	var found := false
	for i in entries.size():
		var item: Variant = entries[i]
		if not (item is Dictionary):
			continue
		var entry: Dictionary = item
		if String(entry.get("action_id", "")) != action_id:
			continue
		found = true
		for key in TIMELINE_PERSIST_KEYS:
			if not timeline_params.has(key):
				continue
			if key == "playback_end":
				var end_v := float(timeline_params["playback_end"])
				if end_v < 0.0 or (clip_total > 0.05 and end_v >= clip_total - 0.05):
					entry.erase("playback_end")
				else:
					entry["playback_end"] = end_v
				continue
			entry[key] = timeline_params[key]
		if timeline_params.has("emotion_id"):
			entry["default_emotion"] = String(timeline_params["emotion_id"])
		if timeline_params.has("audio_path"):
			entry["default_audio"] = String(timeline_params["audio_path"])
		entries[i] = entry
		break
	if not found:
		return {"ok": false, "reason": "catalog 无此 action_id：" + action_id}
	root["entries"] = entries
	var file := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "reason": "无法写入 " + CONFIG_PATH}
	file.store_string(JSON.stringify(root, "\t") + "\n")
	file.close()
	reload_from_disk()
	return {"ok": true, "path": CONFIG_PATH, "action_id": action_id}


## 只读：加载 GLB、提取动画 clip（不写入白名单或正式配置）。
static func probe_animation_clip(scene_path: String, source_anim: String) -> Dictionary:
	var result := {
		"ok": false,
		"scene_path": scene_path,
		"source_anim": source_anim,
		"clip_length": 0.0,
		"reason": "",
	}
	if scene_path == "":
		result["reason"] = "scene 路径为空"
		return result
	if not ResExists.path(scene_path):
		result["reason"] = "场景文件不存在"
		return result
	var packed := load(scene_path) as PackedScene
	if packed == null:
		result["reason"] = "PackedScene 加载失败（导入/路径）"
		return result
	var instance := packed.instantiate()
	var source := instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if source == null:
		instance.free()
		result["reason"] = "未找到 AnimationPlayer"
		return result
	if not source.has_animation(source_anim):
		var names: PackedStringArray = []
		for anim_name in source.get_animation_list():
			names.append(String(anim_name))
		instance.free()
		result["reason"] = "动画不存在；AnimationPlayer 内列表=%s" % ",".join(names)
		return result
	var clip := source.get_animation(source_anim) as Animation
	if clip == null:
		instance.free()
		result["reason"] = "get_animation 返回空"
		return result
	if clip.get_track_count() <= 0:
		instance.free()
		result["reason"] = "动画轨道数为 0"
		return result
	result["clip_length"] = clip.length
	result["ok"] = clip.length > 0.01
	if not result["ok"]:
		result["reason"] = "动画长度过短"
	else:
		result["reason"] = "ok"
	instance.free()
	return result
