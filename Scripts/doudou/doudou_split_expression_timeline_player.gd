extends RefCounted
class_name DoudouSplitExpressionTimelinePlayer

## 兜兜动作 split 眼/嘴槽位（与 doudou_squint_mix_test 同一套逻辑）。

const SplitTimelines := preload("res://Scripts/doudou/doudou_action_split_expression_timelines.gd")
const FacePresenter := preload("res://Scripts/youyou_face_presenter.gd")
const DoudouFacePresenter := preload("res://Scripts/doudou/doudou_face_presenter.gd")

const EYES_SQUINT := "Eyes_开心"

enum BlinkCompare { OFF, LEGACY, SQUINT_AS_BLINK }

var _meshes: Array[MeshInstance3D] = []
var _mouth_emotion_coef := 1.0
var _viseme_speech_active := false
var _squint_ready := false
var _blend_sec := 0.35


func setup(meshes: Array[MeshInstance3D]) -> void:
	_meshes = meshes
	_squint_ready = _shape_exists_on_body(EYES_SQUINT)
	_blend_sec = SplitTimelines.default_slot_blend_sec()


func set_mouth_emotion_coef(value: float) -> void:
	_mouth_emotion_coef = clampf(value, 0.0, 1.0)


func set_viseme_speech_active(active: bool) -> void:
	_viseme_speech_active = active


func clear_timeline_layers() -> void:
	_zero_expression_layers()


func apply_at_time(action_id: String, t_sec: float, zero_layers: bool = true) -> void:
	if not SplitTimelines.has_timeline(action_id):
		return
	var list: Array = SplitTimelines.get_expressions(action_id).duplicate()
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("start_sec", 0.0)) < float(b.get("start_sec", 0.0))
	)
	var any := false
	if zero_layers:
		_zero_expression_layers()
	for i in list.size():
		var e: Dictionary = list[i]
		var alpha := _slot_alpha_at(e, t_sec, _blend_sec)
		if alpha <= 0.0005:
			continue
		any = true
		_write_recipe_shapes(e, alpha, true)
	if not any and zero_layers:
		_zero_expression_layers()


func _slot_alpha_at(entry: Dictionary, t: float, blend_sec: float) -> float:
	var t0 := float(entry.get("start_sec", 0.0))
	var t1 := float(entry.get("end_sec", t0))
	if t1 <= t0:
		t1 = t0 + 0.01
	if t < t0 or t > t1:
		return 0.0
	var blend := clampf(blend_sec, 0.01, maxf((t1 - t0) * 0.5, 0.01))
	if t <= t0 + blend:
		return _smoothstep01((t - t0) / blend)
	if t >= t1 - blend:
		return _smoothstep01((t1 - t) / blend)
	return 1.0


func _smoothstep01(x: float) -> float:
	var u := clampf(x, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)


func _write_recipe_shapes(recipe: Dictionary, slot_alpha: float, accumulate: bool) -> void:
	var scale := clampf(slot_alpha, 0.0, 1.0)
	if scale <= 0.0001:
		return
	var eyes_key := String(recipe.get("eyes", ""))
	var mouth_key := String(recipe.get("mouth", ""))
	var ew := clampf(float(recipe.get("eye_weight", 1.0)), 0.0, 1.0) * scale
	var mw := clampf(float(recipe.get("mouth_weight", 1.0)), 0.0, 1.0) * scale
	# 说话：Mouth_嘴型* 由 DirectViseme；Mouth_情绪 降权叠加以保留神态（与 squint 场一致）。
	if _viseme_speech_active and mouth_key != "":
		mw *= _mouth_emotion_coef
	if eyes_key != "":
		if accumulate:
			_add_shape_weight(eyes_key, ew)
		else:
			_write_shape_all_meshes(eyes_key, ew)
	if mouth_key != "":
		if accumulate:
			_add_shape_weight(mouth_key, mw)
		else:
			_write_shape_all_meshes(mouth_key, mw)
	var blink_mode := int(recipe.get("blink_mode", BlinkCompare.OFF))
	var bw := clampf(float(recipe.get("blink_weight", 0.0)), 0.0, 1.0) * scale
	match blink_mode:
		BlinkCompare.SQUINT_AS_BLINK:
			if _squint_ready:
				if accumulate:
					_add_shape_weight(EYES_SQUINT, bw)
				else:
					_write_shape_all_meshes(EYES_SQUINT, bw)


func _zero_expression_layers() -> void:
	for mesh in _meshes:
		if mesh.mesh == null:
			continue
		for i in mesh.mesh.get_blend_shape_count():
			var shape_name := String(mesh.mesh.get_blend_shape_name(i))
			if shape_name.begins_with("Mouth_") and _viseme_speech_active and _is_viseme_mouth_shape(shape_name):
				continue
			if shape_name.begins_with("Eyes_") or shape_name.begins_with("Mouth_"):
				mesh.set_blend_shape_value(i, 0.0)
			elif shape_name in FacePresenter.LEGACY_COMPOSITE_KEYS:
				mesh.set_blend_shape_value(i, 0.0)


func _is_viseme_mouth_shape(shape_name: String) -> bool:
	for v in DoudouFacePresenter.DOUDOU_VISEME_SHAPE_NAMES.values():
		if shape_name == String(v):
			return true
	return false


func _add_shape_weight(shape_name: String, delta: float) -> void:
	if shape_name == "" or delta <= 0.0001:
		return
	for mesh in _meshes:
		var idx := mesh.find_blend_shape_by_name(shape_name)
		if idx < 0:
			continue
		var cur := mesh.get_blend_shape_value(idx)
		mesh.set_blend_shape_value(idx, clampf(cur + delta, 0.0, 1.0))


func _write_shape_all_meshes(shape_name: String, weight: float) -> void:
	var w := clampf(weight, 0.0, 1.0)
	for mesh in _meshes:
		var idx := mesh.find_blend_shape_by_name(shape_name)
		if idx >= 0:
			mesh.set_blend_shape_value(idx, w)


func _shape_exists_on_body(shape_name: String) -> bool:
	for mesh in _meshes:
		if mesh.find_blend_shape_by_name(shape_name) >= 0:
			return true
	return false
