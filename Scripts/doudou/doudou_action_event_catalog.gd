extends RefCounted
class_name DoudouActionEventCatalog

## 兜兜事件动作登记（测试场专用）。

const CONFIG_PATH := "res://config/doudou_action_event_catalog.json"

const ALLOWED_ACCEPTANCE: PackedStringArray = ["draft", "pending"]

## 口型场 slider 不能裁短；沙盒同样播满 GLB（≈5s）。
const FORCE_FULL_CLIP_ACTION_IDS: PackedStringArray = [
	"跳舞嘲讽",
	"上前嘲讽",
]

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
	if not FileAccess.file_exists(CONFIG_PATH):
		push_error("兜兜事件登记缺失：" + CONFIG_PATH)
		return
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_meta = parsed.duplicate()
	_meta.erase("entries")
	var raw: Variant = parsed.get("entries", [])
	if typeof(raw) != TYPE_ARRAY:
		return
	for item in raw:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = item
		var status := String(entry.get("manual_acceptance_status", "draft"))
		if status not in ALLOWED_ACCEPTANCE:
			entry["manual_acceptance_status"] = "draft"
		_entries.append(entry)


static func get_catalog_notes() -> String:
	ensure_loaded()
	return String(_meta.get("catalog_notes", ""))


static func get_entries() -> Array[Dictionary]:
	ensure_loaded()
	return _entries.duplicate()


static func set_runtime_patch(action_id: String, fields: Dictionary) -> void:
	ensure_loaded()
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


static func probe_animation_clip(scene_path: String, source_anim: String) -> Dictionary:
	const YouyouCatalog := preload("res://Scripts/youyou_action_event_catalog.gd")
	return YouyouCatalog.probe_animation_clip(scene_path, source_anim)


static func forces_full_clip_playback(action_id: String) -> bool:
	return action_id in FORCE_FULL_CLIP_ACTION_IDS


static func persist_timeline_params_to_config(timeline_params: Dictionary) -> Dictionary:
	ensure_loaded()
	var action_id := String(timeline_params.get("action_id", ""))
	if action_id == "":
		return {"ok": false, "reason": "缺少 action_id"}
	if not FileAccess.file_exists(CONFIG_PATH):
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
			if key == "emotion_id":
				continue
			entry[key] = timeline_params[key]
		if timeline_params.has("emotion_id"):
			entry["default_emotion"] = String(timeline_params["emotion_id"])
		if timeline_params.has("audio_path"):
			entry["default_audio"] = String(timeline_params["audio_path"])
		if forces_full_clip_playback(action_id):
			entry.erase("playback_end")
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
	_loaded = false
	_entries = []
	_meta = {}
	ensure_loaded()
	return {"ok": true, "path": CONFIG_PATH, "action_id": action_id}
