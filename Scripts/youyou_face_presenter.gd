extends Node
class_name YouyouFacePresenter

## 正式 + 测试共用的面部表现：拆分 Eyes_*/Mouth_*、口型 A/E/I/O/U、复合主键归零、视线复合键。

const TransitionConfig := preload("res://Scripts/youyou_expression_transition_config.gd")
const PATCH_APPLIER_PATH := "res://youyou_assets/expressions_split/apply_youyou_blendshapes.gd"
const PATCH_BIN_PATH := "res://youyou_assets/expressions_split/youyou_blendshapes.bin"
const PATCH_BIN_EXTENSION_PATH := "res://声音/youyou_new_blendshapes.bin"
const SQUINT_PATCH_BIN_PATH := "res://youyou_assets/expressions_split/youyou_squint_smile_patch.bin"
const FACE_CACHE_VERSION := 2
const FACE_CACHE_DIR := "user://youyou_face_cache"
const FACE_SOURCE_PATHS: PackedStringArray = [
	"res://柚柚.glb",
	"res://新衣服/柚柚衣服.glb",
	PATCH_BIN_PATH,
	PATCH_BIN_EXTENSION_PATH,
	SQUINT_PATCH_BIN_PATH,
]

const VISEME_IDS: PackedStringArray = ["a", "e", "i", "o", "u"]
const VISEME_SHAPE_NAMES: Dictionary = {
	"a": "A", "e": "E", "i": "i", "o": "o", "u": "u",
}
const VISEME_MESH_PARTICIPANTS: PackedStringArray = [
	"人体_001", "上牙", "下牙", "舌头",
]
## 眯眼/闭眼类表情：仍写睫毛 Eyes_* 以贴合眼球；仅暂停 idle 眨眼，避免与 eyeBlink 叠加重拉。
const BLINK_MASK_EMOTION_IDS: PackedStringArray = [
	"grin", "yawn", "sleepy", "bite_wink",
]
## 测试场景人工验收系数（HUD 可读嘴情 0.35；口型/过渡滑条约在 0–1 的 75% / 27%）
const APPROVED_MOUTH_EMOTION_COEF := 0.35
const APPROVED_VISEME_COEF := 0.75
const APPROVED_BLEND_TIME := 0.27
const VISEME_BLEND_TIME := APPROVED_BLEND_TIME

const SPLIT_EMOTION_IDS: PackedStringArray = [
	"smile", "surprise", "laugh", "angry", "sad", "grin",
	"think", "sleepy", "yawn", "min_smile", "mid_smile", "whistle", "puff",
	"bite_wink", "smug_smile", "serious",
]
const LEGACY_COMPOSITE_KEYS: PackedStringArray = [
	"smile", "surprise", "laugh", "angry", "sad", "grin",
]
const GAZE_KEYS: PackedStringArray = ["wink", "lookleft", "lookright"]
const DEFAULT_EMOTION := "smile"
const DEFAULT_PRIMARY := "smile"
## 基础待机：不挂 split 主表情（仅保留 EyeGazeController 眨眼/转眼）
const NEUTRAL_EMOTION_ID := ""
const TRANSITION_BLEND_TIME_DEFAULT := 0.4

const SPLIT_PROFILES: Dictionary = {
	"smile": {"label": "微笑", "eyes": "Eyes_smile", "mouth": "Mouth_smile"},
	"surprise": {"label": "惊讶", "eyes": "Eyes_surprise", "mouth": "Mouth_surprise"},
	"laugh": {"label": "大笑", "eyes": "Eyes_laugh", "mouth": "Mouth_laugh"},
	"angry": {"label": "生气", "eyes": "Eyes_angry", "mouth": "Mouth_angry"},
	"sad": {"label": "难过", "eyes": "Eyes_sad", "mouth": "Mouth_sad"},
	"grin": {"label": "眯眼笑", "eyes": "Eyes_grin", "mouth": "Mouth_grin"},
	"think": {"label": "思考", "eyes": "Eyes_think", "mouth": "Mouth_think"},
	"sleepy": {"label": "犯困", "eyes": "Eyes_sleepy", "mouth": "Mouth_sleepy"},
	"yawn": {"label": "哈欠", "eyes": "Eyes_yawn", "mouth": "Mouth_yawn"},
	"min_smile": {"label": "小笑", "eyes": "Eyes_min_smile", "mouth": "Mouth_min_smile"},
	"mid_smile": {"label": "中笑", "eyes": "Eyes_mid_smile", "mouth": "Mouth_mid_smile"},
	"whistle": {"label": "吹口哨", "eyes": "Eyes_whistle", "mouth": "Mouth_whistle"},
	"puff": {"label": "鼓气", "eyes": "Eyes_puff", "mouth": "Mouth_puff"},
	"bite_wink": {"label": "咬唇眨眼", "eyes": "Eyes_bite_wink", "mouth": "Mouth_bite_wink"},
	"smug_smile": {"label": "得意微笑", "eyes": "Eyes_smug_smile", "mouth": "Mouth_smug_smile"},
	"serious": {"label": "严肃", "eyes": "Eyes_serious", "mouth": "Mouth_serious"},
}

var _meshes: Array[MeshInstance3D] = []
var _default_shapes: Dictionary = {}
var _managed_shapes: PackedStringArray = []
var _split_shape_names: PackedStringArray = []
var _emotion_ready: Dictionary = {}

var _active_emotion := DEFAULT_EMOTION
var _active_gaze := ""
var _active_viseme := ""
var _viseme_strength := 0.0

var _mouth_emotion_coef := APPROVED_MOUTH_EMOTION_COEF
var _viseme_coef := APPROVED_VISEME_COEF
var _blend_time := APPROVED_BLEND_TIME
var _performance_blend_time := TRANSITION_BLEND_TIME_DEFAULT

var _tween: Tween
var _tween_gen := 0
var _transition_progress := 1.0
var _transition_active := false
var _transition_elapsed := 0.0
var _transition_duration := 0.0
var _current_expression_id := DEFAULT_EMOTION
var _transition_from_id := ""
var _start_weights: Dictionary = {}
var _target_weights: Dictionary = {}
var _current_weights: Dictionary = {}
var _last_applied_duration := 0.0
var _split_expression_override := false


static func apply_split_patch_to_model(model: Node3D) -> Dictionary:
	if not ResExists.path(PATCH_BIN_PATH):
		var msg := "拆分补丁二进制不存在：" + PATCH_BIN_PATH
		push_error(msg)
		return {"ok": false, "summary": msg, "diagnostics": [], "success_count": 0, "total_count": 8}
	if _try_apply_face_cache(model):
		var cached := {
			"ok": true,
			"summary": "使用已缓存的表情网格",
			"diagnostics": [],
			"success_count": 1,
			"total_count": 1,
			"from_cache": true,
		}
		return _apply_squint_smile_patch_to_model(model, cached)
	var base := _apply_patch_bin_to_model(model, PATCH_BIN_PATH)
	if not ResExists.path(PATCH_BIN_EXTENSION_PATH):
		var early := _apply_squint_smile_patch_to_model(model, base)
		if bool(early.get("ok", false)):
			_store_face_cache(model)
		return early
	var ext := _apply_patch_bin_to_model(model, PATCH_BIN_EXTENSION_PATH)
	var merged := _merge_patch_results(base, ext)
	merged = _apply_squint_smile_patch_to_model(model, merged)
	if bool(merged.get("ok", false)):
		_store_face_cache(model)
	return merged


static func _apply_squint_smile_patch_to_model(model: Node3D, merged: Dictionary) -> Dictionary:
	if model == null or merged.is_empty():
		return merged
	if not ResExists.path(SQUINT_PATCH_BIN_PATH):
		return merged
	var squint := _apply_patch_bin_to_model(model, SQUINT_PATCH_BIN_PATH)
	return _merge_patch_results(merged, squint)


static func _face_cache_key() -> String:
	var parts: PackedStringArray = PackedStringArray([str(FACE_CACHE_VERSION)])
	for path in FACE_SOURCE_PATHS:
		parts.append(_file_stamp(path))
	return "\n".join(parts)


static func _file_stamp(path: String) -> String:
	if not FileAccess.file_exists(path):
		return path + ":missing"
	var file := FileAccess.open(path, FileAccess.READ)
	var length := 0
	if file != null:
		length = file.get_length()
		file.close()
	return "%s:%d:%d" % [path, length, FileAccess.get_modified_time(path)]


static func _mesh_has_shape(mesh: Mesh, shape_name: String) -> bool:
	for i in mesh.get_blend_shape_count():
		if String(mesh.get_blend_shape_name(i)) == shape_name:
			return true
	return false


static func _try_apply_face_cache(model: Node3D) -> bool:
	var key_path := FACE_CACHE_DIR + "/key.txt"
	var manifest_path := FACE_CACHE_DIR + "/manifest.txt"
	if not FileAccess.file_exists(key_path) or not FileAccess.file_exists(manifest_path):
		return false
	var stored := FileAccess.get_file_as_string(key_path).strip_edges()
	if stored != _face_cache_key().strip_edges():
		return false
	var pairs: Array[Dictionary] = []
	var saw_mouth := false
	for line in FileAccess.get_file_as_string(manifest_path).split("\n", false):
		var tab := line.find("\t")
		if tab <= 0:
			return false
		var mesh := load("%s/mesh_%s.res" % [FACE_CACHE_DIR, line.substr(0, tab)]) as ArrayMesh
		var node := model.get_node_or_null(NodePath(line.substr(tab + 1)))
		if mesh == null or node == null or not (node is MeshInstance3D):
			return false
		if _mesh_has_shape(mesh, "Mouth_smile"):
			saw_mouth = true
		pairs.append({"node": node, "mesh": mesh})
	if not saw_mouth or pairs.is_empty():
		return false
	for pair in pairs:
		(pair["node"] as MeshInstance3D).mesh = pair["mesh"]
	print("表情网格使用上次结果，跳过重新计算。")
	return true


static func _store_face_cache(model: Node3D) -> void:
	var entries: Array[Dictionary] = []
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null or not (mi.mesh is ArrayMesh):
			continue
		var mesh := mi.mesh as ArrayMesh
		if not _mesh_has_shape(mesh, "Mouth_smile") and not _mesh_has_shape(mesh, "Eyes_smile"):
			continue
		entries.append({"path": str(model.get_path_to(mi)), "mesh": mesh})
	if entries.is_empty():
		return
	var root := DirAccess.open("user://")
	if root == null:
		return
	root.make_dir_recursive("youyou_face_cache")
	var cache_dir := DirAccess.open(FACE_CACHE_DIR)
	if cache_dir != null and cache_dir.file_exists("key.txt"):
		cache_dir.remove("key.txt")
	var manifest := ""
	for i in entries.size():
		var err: Error = ResourceSaver.save(
			entries[i]["mesh"],
			"%s/mesh_%d.res" % [FACE_CACHE_DIR, i],
			ResourceSaver.FLAG_COMPRESS
		)
		if err != OK:
			push_warning("表情网格没能记住，下次启动仍会重新计算。")
			return
		manifest += "%d\t%s\n" % [i, String(entries[i]["path"])]
	var manifest_file := FileAccess.open(FACE_CACHE_DIR + "/manifest.txt", FileAccess.WRITE)
	if manifest_file == null:
		return
	manifest_file.store_string(manifest)
	manifest_file.close()
	var key_file := FileAccess.open(FACE_CACHE_DIR + "/key.txt", FileAccess.WRITE)
	if key_file == null:
		return
	key_file.store_string(_face_cache_key())
	key_file.close()
	print("表情网格已记住，下次启动不用再算一遍。")


static func _apply_patch_bin_to_model(model: Node3D, bin_path: String) -> Dictionary:
	if not ResourceLoader.exists(PATCH_APPLIER_PATH) or not ResourceLoader.exists(bin_path):
		return {
			"ok": false,
			"summary": "3D blendshape assets removed",
			"diagnostics": [],
			"success_count": 0,
			"total_count": 0,
			"bin_path": bin_path,
		}
	var script := load(PATCH_APPLIER_PATH)
	if script == null:
		return {
			"ok": false,
			"summary": "3D blendshape applier missing",
			"diagnostics": [],
			"success_count": 0,
			"total_count": 0,
			"bin_path": bin_path,
		}
	var applier: Node = (script as GDScript).new()
	applier.name = "YouyouSplitPatchApplier"
	applier.set("blendshape_file", bin_path)
	model.add_child(applier)
	var result: Dictionary = applier.call("apply_blendshapes_with_diagnostics")
	applier.queue_free()
	result["bin_path"] = bin_path
	return result


static func _merge_patch_results(base: Dictionary, ext: Dictionary) -> Dictionary:
	var base_ok := int(base.get("success_count", 0)) > 0
	var ext_ok := int(ext.get("success_count", 0)) > 0
	var ok := base_ok and ext_ok
	var diag: Array = []
	diag.append_array(base.get("diagnostics", []))
	diag.append_array(ext.get("diagnostics", []))
	var summary := String(base.get("summary", "")) + "\n[扩展补丁]\n" + String(ext.get("summary", ""))
	return {
		"ok": ok,
		"summary": summary.strip_edges(),
		"diagnostics": diag,
		"success_count": int(base.get("success_count", 0)) + int(ext.get("success_count", 0)),
		"total_count": int(base.get("total_count", 0)) + int(ext.get("total_count", 0)),
		"extension_applied": true,
	}


func get_meshes() -> Array[MeshInstance3D]:
	return _meshes


func set_split_expression_override(active: bool) -> void:
	_split_expression_override = active
	if active:
		_abort_transition()
		_active_viseme = ""
		_viseme_strength = 0.0


func is_split_expression_override() -> bool:
	return _split_expression_override


static func capture_zero_baseline(meshes: Array[MeshInstance3D]) -> Dictionary:
	var out: Dictionary = {}
	for mesh in meshes:
		var values := {}
		for i in mesh.mesh.get_blend_shape_count():
			values[String(mesh.mesh.get_blend_shape_name(i))] = 0.0
		out[mesh] = values
	return out


func setup(meshes: Array[MeshInstance3D], default_shapes: Dictionary = {}) -> void:
	_abort_transition()
	_meshes = meshes
	_default_shapes = default_shapes
	_build_split_shape_list()
	_refresh_emotion_readiness()
	_build_managed_shapes()
	_sync_current_weights_from_meshes()
	_current_expression_id = _active_emotion


func configure_patch_readiness(_diagnostics: Array) -> void:
	_refresh_emotion_readiness()


func configure_coefficients(mouth_emotion: float, viseme: float, blend_time: float) -> void:
	_mouth_emotion_coef = clampf(mouth_emotion, 0.0, 1.0)
	_viseme_coef = clampf(viseme, 0.0, 1.0)
	_blend_time = maxf(blend_time, 0.0)


func apply_approved_coefficients() -> void:
	configure_coefficients(
		APPROVED_MOUTH_EMOTION_COEF,
		APPROVED_VISEME_COEF,
		APPROVED_BLEND_TIME,
	)


func configure_performance_blend(duration: float) -> void:
	_performance_blend_time = maxf(duration, 0.0)


func get_split_profile(emotion_id: String) -> Dictionary:
	return SPLIT_PROFILES.get(emotion_id, {})


func get_emotion_ids() -> PackedStringArray:
	return SPLIT_EMOTION_IDS.duplicate()


func get_emotion_label(emotion_id: String) -> String:
	var p: Dictionary = SPLIT_PROFILES.get(emotion_id, {})
	return String(p.get("label", emotion_id))


func is_emotion_available(emotion_id: String) -> bool:
	return bool(_emotion_ready.get(emotion_id, false))


func get_emotion_readiness() -> Dictionary:
	return _emotion_ready.duplicate()


func get_split_shape_names() -> PackedStringArray:
	return _split_shape_names.duplicate()


func is_composite_emotion(_emotion_id: String) -> bool:
	return false


func get_active_emotion() -> String:
	return _active_emotion


static func emotion_should_mask_blink(emotion_id: String) -> bool:
	return emotion_id in BLINK_MASK_EMOTION_IDS


static func is_eyes_split_shape(shape_name: String) -> bool:
	return shape_name.begins_with("Eyes_")


func get_active_viseme() -> String:
	return _active_viseme


func get_active_primary() -> String:
	if _active_gaze != "":
		return _active_gaze
	return _active_emotion


func get_emotion_restore_primary() -> String:
	if _active_emotion != "":
		return _active_emotion
	return NEUTRAL_EMOTION_ID


func get_transition_progress() -> float:
	return _transition_progress


func is_transition_running() -> bool:
	return _transition_active and _tween != null and _tween.is_valid() and _transition_progress < 0.999


func get_current_expression_id() -> String:
	return _current_expression_id


func get_last_blend_duration() -> float:
	return _last_applied_duration


func get_transition_debug_state() -> Dictionary:
	return {
		"current_expression_id": _current_expression_id,
		"transition_from_id": _transition_from_id,
		"transition_active": _transition_active,
		"transition_elapsed": _transition_elapsed,
		"transition_duration": _transition_duration,
		"transition_progress": _transition_progress,
		"transition_generation": _tween_gen,
	}


func performance_blend_duration() -> float:
	return _performance_blend_time


func set_coefficients(mouth_emotion: float, viseme: float, blend_time: float) -> void:
	configure_coefficients(mouth_emotion, viseme, blend_time)


func get_coefficients() -> Vector3:
	return Vector3(_mouth_emotion_coef, _viseme_coef, _blend_time)


func set_emotion(emotion_id: String, duration: float = -1.0) -> bool:
	if emotion_id not in SPLIT_PROFILES:
		push_warning("无效表情 ID，跳过：" + emotion_id)
		return false
	if not is_emotion_available(emotion_id):
		push_warning("拆分情绪未就绪，跳过：" + emotion_id)
		return false
	var from_id := _current_expression_id if _active_gaze == "" else ""
	var resolved := TransitionConfig.resolve_emotion_duration(from_id, emotion_id, duration)
	if _should_skip_emotion_request(emotion_id, resolved):
		return true
	_transition_from_id = from_id
	_active_gaze = ""
	_active_emotion = emotion_id
	_current_expression_id = emotion_id
	_apply_state(resolved)
	return true


func set_gaze(gaze_id: String, duration: float = -1.0) -> bool:
	if gaze_id != "" and gaze_id not in GAZE_KEYS:
		push_warning("无效视线 ID：" + gaze_id)
		return false
	if gaze_id != "" and not _shape_exists_any_mesh(gaze_id):
		push_warning("视线形态键不存在：" + gaze_id)
		return false
	var from_gaze := _active_gaze
	var resolved := TransitionConfig.resolve_gaze_duration(from_gaze, gaze_id, duration)
	if gaze_id == _active_gaze and not is_transition_running() and resolved <= 0.0:
		return true
	_transition_from_id = from_gaze
	_active_gaze = gaze_id
	if gaze_id != "":
		_active_emotion = ""
		_current_expression_id = gaze_id
	elif _active_emotion != "":
		_current_expression_id = _active_emotion
	_apply_state(resolved)
	return true


func set_primary(shape_name: String, duration: float = -1.0) -> bool:
	if shape_name in SPLIT_EMOTION_IDS:
		return set_emotion(shape_name, duration)
	if shape_name in GAZE_KEYS:
		return set_gaze(shape_name, duration)
	return false


func set_viseme(viseme_id: String, duration: float = -1.0) -> bool:
	var vid := viseme_id.to_lower()
	if vid not in VISEME_IDS:
		return false
	_active_viseme = vid
	_viseme_strength = 1.0
	_apply_state(duration)
	return true


func clear_viseme(duration: float = -1.0) -> void:
	_active_viseme = ""
	_viseme_strength = 0.0
	_apply_state(duration)


func reset_all(duration: float = -1.0) -> void:
	_active_gaze = ""
	_active_viseme = ""
	_viseme_strength = 0.0
	if not is_emotion_available(DEFAULT_EMOTION):
		_active_emotion = ""
		_current_expression_id = ""
		_apply_state(duration)
		return
	var from_id := _current_expression_id if _active_gaze == "" else ""
	var resolved := TransitionConfig.resolve_emotion_duration(from_id, DEFAULT_EMOTION, duration)
	if duration < 0.0 and resolved <= 0.0:
		resolved = TransitionConfig.RESTORE_BASE
	_transition_from_id = from_id
	_active_emotion = DEFAULT_EMOTION
	_current_expression_id = DEFAULT_EMOTION
	_apply_state(resolved)


func reset_to_default(duration: float = -1.0) -> void:
	if duration < 0.0:
		reset_all(_performance_blend_time)
	else:
		reset_all(duration)


func clear_to_neutral(duration: float = -1.0) -> void:
	_active_gaze = ""
	_active_viseme = ""
	_viseme_strength = 0.0
	_active_emotion = ""
	_current_expression_id = ""
	var resolved := duration if duration >= 0.0 else _performance_blend_time
	_apply_state(resolved)


func restore_idle_expression(emotion_id: String, duration: float) -> void:
	configure_performance_blend(duration)
	if emotion_id == "":
		clear_to_neutral(duration)
	else:
		set_emotion(emotion_id, duration)


func read_shape_on_body(shape_name: String) -> float:
	var body := _find_mesh("人体_001")
	if body == null:
		return -1.0
	var idx := body.find_blend_shape_by_name(shape_name)
	if idx < 0:
		return -1.0
	return body.get_blend_shape_value(idx)


func read_shape_on_any_mesh(shape_name: String) -> float:
	for mesh in _meshes:
		var idx := mesh.find_blend_shape_by_name(shape_name)
		if idx >= 0:
			return mesh.get_blend_shape_value(idx)
	return -1.0


func read_primary_on_mesh(mesh: MeshInstance3D, primary: String) -> float:
	if primary in SPLIT_EMOTION_IDS:
		var p: Dictionary = SPLIT_PROFILES.get(primary, {})
		var eyes := String(p.get("eyes", ""))
		var mouth := String(p.get("mouth", ""))
		var ev := -1.0
		var mv := -1.0
		if eyes != "":
			var ei := mesh.find_blend_shape_by_name(eyes)
			if ei >= 0:
				ev = mesh.get_blend_shape_value(ei)
		if mouth != "":
			var mi := mesh.find_blend_shape_by_name(mouth)
			if mi >= 0:
				mv = mesh.get_blend_shape_value(mi)
		if ev < 0.0 and mv < 0.0:
			return -1.0
		return maxf(ev, mv)
	var index := mesh.find_blend_shape_by_name(primary)
	if index < 0:
		return -1.0
	return mesh.get_blend_shape_value(index)


func get_viseme_shape_name(viseme_id: String) -> String:
	return String(VISEME_SHAPE_NAMES.get(viseme_id.to_lower(), ""))


func get_viseme_blend_shape_names() -> PackedStringArray:
	var names: PackedStringArray = []
	var seen: Dictionary = {}
	for vid in VISEME_IDS:
		var shape_name := get_viseme_shape_name(vid)
		if shape_name == "" or seen.has(shape_name):
			continue
		seen[shape_name] = true
		names.append(shape_name)
	return names


func read_viseme_on_mesh(mesh: MeshInstance3D, viseme_id: String) -> float:
	var shape_name := get_viseme_shape_name(viseme_id)
	if shape_name.is_empty():
		return -1.0
	var index := mesh.find_blend_shape_by_name(shape_name)
	if index < 0:
		return -1.0
	return mesh.get_blend_shape_value(index)


func is_viseme_participant_mesh(mesh: MeshInstance3D) -> bool:
	return mesh.name in VISEME_MESH_PARTICIPANTS


func all_visemes_near_zero(max_weight: float = 0.02) -> bool:
	for mesh in _meshes:
		if not is_viseme_participant_mesh(mesh):
			continue
		for vid in VISEME_IDS:
			var v := read_viseme_on_mesh(mesh, vid)
			if v < 0.0:
				continue
			if v > max_weight:
				return false
	return true


func max_viseme_weight_excluding(active_vid: String, max_weight: float = 0.02) -> float:
	var active_shape := get_viseme_shape_name(active_vid)
	var peak := 0.0
	for mesh in _meshes:
		if not is_viseme_participant_mesh(mesh):
			continue
		for vid in VISEME_IDS:
			var sh := get_viseme_shape_name(vid)
			if sh == active_shape:
				continue
			var v := read_viseme_on_mesh(mesh, vid)
			if v >= 0.0:
				peak = maxf(peak, v)
	return peak


func sample_debug_lines(max_shapes: int = 10) -> PackedStringArray:
	var lines: PackedStringArray = []
	var profile: Dictionary = get_split_profile(_active_emotion)
	var eyes_key := String(profile.get("eyes", ""))
	var mouth_key := String(profile.get("mouth", ""))
	lines.append(
		"情绪: %s | 视线: %s | 口型: %s | 嘴情系数: %.2f"
		% [
			get_emotion_label(_active_emotion) if _active_emotion != "" else "—",
			_active_gaze if _active_gaze != "" else "—",
			_active_viseme if _active_viseme != "" else "—",
			_mouth_emotion_coef,
		]
	)
	if eyes_key != "":
		lines.append("  活动眼键 %s=%.3f" % [eyes_key, read_shape_on_any_mesh(eyes_key)])
	if mouth_key != "":
		lines.append("  活动嘴键 %s=%.3f" % [mouth_key, read_shape_on_any_mesh(mouth_key)])
	if _active_viseme != "":
		var vname := get_viseme_shape_name(_active_viseme)
		lines.append("  活动元音 %s=%.3f" % [vname, read_shape_on_any_mesh(vname)])
	var shown := 0
	for shape_name in _managed_shapes:
		if shown >= max_shapes:
			break
		var v := read_shape_on_any_mesh(shape_name)
		if v < 0.0 or absf(v) < 0.02:
			continue
		lines.append("  %s=%.3f" % [shape_name, v])
		shown += 1
	return lines


func _build_split_shape_list() -> void:
	var keys: Dictionary = {}
	for eid in SPLIT_PROFILES:
		var p: Dictionary = SPLIT_PROFILES[eid]
		keys[String(p["eyes"])] = true
		keys[String(p["mouth"])] = true
	_split_shape_names = PackedStringArray(keys.keys())
	_split_shape_names.sort()


func _refresh_emotion_readiness() -> void:
	_emotion_ready.clear()
	for eid in SPLIT_EMOTION_IDS:
		var p: Dictionary = SPLIT_PROFILES[eid]
		var eyes := String(p["eyes"])
		var mouth := String(p["mouth"])
		_emotion_ready[eid] = _shape_exists_any_mesh(eyes) and _shape_exists_any_mesh(mouth)


func _build_managed_shapes() -> void:
	var keys: Dictionary = {}
	for name in _split_shape_names:
		keys[name] = true
	for pk in LEGACY_COMPOSITE_KEYS:
		keys[pk] = true
	for shape_name in get_viseme_blend_shape_names():
		keys[shape_name] = true
	for gk in GAZE_KEYS:
		keys[gk] = true
	_managed_shapes = PackedStringArray(keys.keys())
	_managed_shapes.sort()


func _shape_exists_any_mesh(shape_name: String) -> bool:
	for mesh in _meshes:
		if mesh.find_blend_shape_by_name(shape_name) >= 0:
			return true
	return false


func _find_mesh(name: String) -> MeshInstance3D:
	for mesh in _meshes:
		if mesh.name == name:
			return mesh
	return null


func _resolve_duration(requested: float) -> float:
	if requested >= 0.0:
		return requested
	return _blend_time


func _apply_state(duration: float = -1.0) -> void:
	var dur := _resolve_duration(duration)
	var targets := _build_targets()
	_target_weights = targets.duplicate()
	if not is_transition_running() and _weights_match_targets(targets, 0.015):
		_sync_current_weights_from_meshes()
		return
	_abort_transition()
	_sync_current_weights_from_meshes()
	_start_weights = _snapshot_mesh_weights_for_targets(targets)
	_tween_gen += 1
	var gen := _tween_gen
	_last_applied_duration = dur
	_transition_duration = dur
	_transition_elapsed = 0.0
	if dur <= 0.0:
		_finish_transition_instant(targets)
		return
	_transition_active = true
	_transition_progress = 0.0
	_tween = create_tween()
	var tracks := _collect_transition_tracks(targets)
	if tracks.is_empty():
		_finish_transition_instant(targets)
		return
	_tween.tween_method(_transition_step.bind(gen, tracks), 0.0, 1.0, dur)
	_tween.finished.connect(func() -> void:
		if gen != _tween_gen:
			return
		_transition_active = false
		_transition_progress = 1.0
		_transition_elapsed = _transition_duration
		_sync_current_weights_from_meshes()
	, CONNECT_ONE_SHOT)


func _build_targets() -> Dictionary:
	var targets: Dictionary = {}
	for shape_name in _managed_shapes:
		if _split_expression_override and _shape_owned_by_split_timeline(shape_name):
			continue
		targets[shape_name] = _baseline_for_shape(shape_name)

	if not _split_expression_override:
		for pk in LEGACY_COMPOSITE_KEYS:
			targets[pk] = 0.0
		for name in _split_shape_names:
			targets[name] = 0.0

	for gk in GAZE_KEYS:
		targets[gk] = 0.0

	if _active_gaze != "":
		targets[_active_gaze] = 1.0
	else:
		var viseme_active := _active_viseme != "" and _viseme_strength > 0.0
		var mouth_scale := _mouth_emotion_coef if viseme_active else 1.0
		if not _split_expression_override and _active_emotion != "" and is_emotion_available(_active_emotion):
			var profile: Dictionary = get_split_profile(_active_emotion)
			targets[String(profile["eyes"])] = 1.0
			targets[String(profile["mouth"])] = mouth_scale

	if not _split_expression_override:
		for shape_name in get_viseme_blend_shape_names():
			targets[shape_name] = 0.0
		if _active_viseme != "" and _viseme_strength > 0.0:
			targets[get_viseme_shape_name(_active_viseme)] = _viseme_coef * _viseme_strength

	return targets


func _shape_owned_by_split_timeline(shape_name: String) -> bool:
	if shape_name in LEGACY_COMPOSITE_KEYS:
		return true
	return shape_name in _split_shape_names


func _baseline_for_shape(shape_name: String) -> float:
	var sum := 0.0
	var count := 0
	for mesh in _meshes:
		var per_mesh: Dictionary = _default_shapes.get(mesh, {})
		if per_mesh.has(shape_name):
			sum += float(per_mesh[shape_name])
			count += 1
		else:
			var index := mesh.find_blend_shape_by_name(shape_name)
			if index >= 0:
				sum += mesh.get_blend_shape_value(index)
				count += 1
	if count == 0:
		return 0.0
	return sum / float(count)


func _apply_targets_instant(targets: Dictionary) -> void:
	for mesh in _meshes:
		for shape_name in _managed_shapes:
			var index := mesh.find_blend_shape_by_name(shape_name)
			if index < 0 or not targets.has(shape_name):
				continue
			var w := _resolve_shape_target_for_mesh(mesh, shape_name, float(targets[shape_name]))
			mesh.set_blend_shape_value(index, w)
			_current_weights[_weight_key(mesh, shape_name)] = w


func _setter_for(mesh: MeshInstance3D, index: int, gen: int) -> Callable:
	return func(value: float) -> void:
		if gen != _tween_gen:
			return
		mesh.set_blend_shape_value(index, clampf(value, 0.0, 1.0))


func _abort_transition() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	_transition_active = false


func _finish_transition_instant(targets: Dictionary) -> void:
	_transition_active = false
	_transition_progress = 1.0
	_transition_elapsed = 0.0
	_apply_targets_instant(targets)
	_sync_current_weights_from_meshes()


func _smoothstep01(t: float) -> float:
	var x := clampf(t, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


func _weight_key(mesh: MeshInstance3D, shape_name: String) -> String:
	return "%s|%s" % [mesh.get_instance_id(), shape_name]


func _sync_current_weights_from_meshes() -> void:
	for mesh in _meshes:
		for shape_name in _managed_shapes:
			var index := mesh.find_blend_shape_by_name(shape_name)
			if index < 0:
				continue
			_current_weights[_weight_key(mesh, shape_name)] = mesh.get_blend_shape_value(index)


func _snapshot_mesh_weights_for_targets(targets: Dictionary) -> Dictionary:
	var snap: Dictionary = {}
	for mesh in _meshes:
		for shape_name in targets:
			var index := mesh.find_blend_shape_by_name(shape_name)
			if index < 0:
				continue
			snap[_weight_key(mesh, shape_name)] = mesh.get_blend_shape_value(index)
	return snap


func _collect_transition_tracks(targets: Dictionary) -> Array:
	var tracks: Array = []
	for mesh in _meshes:
		for shape_name in _managed_shapes:
			if not targets.has(shape_name):
				continue
			var index := mesh.find_blend_shape_by_name(shape_name)
			if index < 0:
				continue
			var key := _weight_key(mesh, shape_name)
			var start := float(_start_weights.get(key, mesh.get_blend_shape_value(index)))
			var target := _resolve_shape_target_for_mesh(mesh, shape_name, float(targets[shape_name]))
			if is_equal_approx(start, target):
				continue
			tracks.append({"mesh": mesh, "index": index, "key": key, "start": start, "target": target})
	return tracks


func _transition_step(raw_t: float, gen: int, tracks: Array) -> void:
	if gen != _tween_gen:
		return
	var eased := _smoothstep01(raw_t)
	_transition_progress = eased
	_transition_elapsed = eased * _transition_duration
	for track in tracks:
		var mesh: MeshInstance3D = track["mesh"]
		var index: int = track["index"]
		var start: float = track["start"]
		var target: float = track["target"]
		var w := lerpf(start, target, eased)
		w = clampf(w, 0.0, 1.0)
		mesh.set_blend_shape_value(index, w)
		_current_weights[track["key"]] = w


func _should_skip_emotion_request(emotion_id: String, resolved_duration: float) -> bool:
	if _active_gaze != "":
		return false
	if emotion_id != _active_emotion or emotion_id != _current_expression_id:
		return false
	if is_transition_running():
		return false
	if resolved_duration > 0.0:
		return _weights_match_targets(_build_targets(), 0.02)
	return true


func _weights_match_targets(targets: Dictionary, epsilon: float) -> bool:
	for mesh in _meshes:
		for shape_name in _managed_shapes:
			if not targets.has(shape_name):
				continue
			var index := mesh.find_blend_shape_by_name(shape_name)
			if index < 0:
				continue
			var target := _resolve_shape_target_for_mesh(mesh, shape_name, float(targets[shape_name]))
			var current := mesh.get_blend_shape_value(index)
			if absf(current - target) > epsilon:
				return false
	return true


func _resolve_shape_target_for_mesh(_mesh: MeshInstance3D, _shape_name: String, global_target: float) -> float:
	return clampf(global_target, 0.0, 1.0)
