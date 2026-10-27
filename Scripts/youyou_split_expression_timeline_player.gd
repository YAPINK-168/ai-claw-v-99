extends RefCounted
class_name YouyouSplitExpressionTimelinePlayer

## 动作内 split 眼/嘴槽位时间轴驱动（与 squint mix 预览同一套混合逻辑）。

const SplitTimelines := preload("res://Scripts/youyou_action_split_expression_timelines.gd")
const FacePresenter := preload("res://Scripts/youyou_face_presenter.gd")

const EYES_SQUINT := "Eyes_squint_smile"

enum BlinkCompare { OFF, LEGACY, SQUINT_AS_BLINK }

var _meshes: Array[MeshInstance3D] = []
var _gaze: Node = null
var _mouth_emotion_coef := 1.0
var _viseme_speech_active := false
var _squint_ready := false
var _blend_sec := 0.35


func setup(meshes: Array[MeshInstance3D], gaze: Node = null) -> void:
	_meshes = meshes
	_gaze = gaze
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
	var peak_legacy_blink := 0.0
	if zero_layers:
		_zero_expression_layers()
	for i in list.size():
		var e: Dictionary = list[i]
		var alpha := _slot_alpha_at(SplitTimelines.apply_slot_fade_overrides(action_id, e), t_sec, _blend_sec)
		if alpha <= 0.0005:
			continue
		any = true
		peak_legacy_blink = maxf(peak_legacy_blink, _write_recipe_shapes(e, alpha, true))
	if not any and zero_layers:
		_zero_expression_layers()
		return
	if peak_legacy_blink > 0.0 and _gaze != null and _gaze.has_method("apply_blink_weight"):
		_gaze.call("apply_blink_weight", peak_legacy_blink)


func _slot_alpha_at(entry: Dictionary, t: float, blend_sec: float) -> float:
	return slot_alpha_at(entry, t, blend_sec)


## 槽位透明度：默认首尾 smoothstep；JSON 可设 no_fade_in / no_fade_out 或 fade_*_sec。
static func slot_alpha_at(entry: Dictionary, t: float, blend_sec: float) -> float:
	var t0 := float(entry.get("start_sec", 0.0))
	var t1 := float(entry.get("end_sec", t0))
	if t1 <= t0:
		t1 = t0 + 0.01
	if t < t0 or t > t1:
		return 0.0
	var default_blend := clampf(blend_sec, 0.01, maxf((t1 - t0) * 0.5, 0.01))
	var fade_in := default_blend
	var fade_out := default_blend
	if entry.has("fade_in_sec"):
		fade_in = maxf(float(entry["fade_in_sec"]), 0.0)
	if entry.has("fade_out_sec"):
		fade_out = maxf(float(entry["fade_out_sec"]), 0.0)
	if bool(entry.get("no_fade_in", false)):
		fade_in = 0.0
	if bool(entry.get("no_fade_out", false)):
		fade_out = 0.0
	if fade_in > 0.0001 and t <= t0 + fade_in:
		return _smoothstep01((t - t0) / fade_in)
	if fade_out > 0.0001 and t >= t1 - fade_out:
		return _smoothstep01((t1 - t) / fade_out)
	return 1.0


static func _smoothstep01(x: float) -> float:
	var u := clampf(x, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)


func _write_recipe_shapes(recipe: Dictionary, slot_alpha: float, accumulate: bool) -> float:
	var scale := clampf(slot_alpha, 0.0, 1.0)
	if scale <= 0.0001:
		return 0.0
	var eyes_key := String(recipe.get("eyes", ""))
	var mouth_key := String(recipe.get("mouth", ""))
	var ew := clampf(float(recipe.get("eye_weight", 1.0)), 0.0, 1.0) * scale
	var mw := clampf(float(recipe.get("mouth_weight", 1.0)), 0.0, 1.0) * scale
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
	var legacy_blink := 0.0
	match blink_mode:
		BlinkCompare.LEGACY:
			legacy_blink = bw
		BlinkCompare.SQUINT_AS_BLINK:
			if _squint_ready:
				if accumulate:
					_add_shape_weight(EYES_SQUINT, bw)
				else:
					_write_shape_all_meshes(EYES_SQUINT, bw)
			else:
				legacy_blink = bw
	return legacy_blink


func _zero_expression_layers() -> void:
	## 只清 split 槽位（Eyes_/Mouth_），不碰 eyeLook*/eyeBlink，避免与 EyeGazeController / 待机眨眼每帧打架。
	for mesh in _meshes:
		if mesh.mesh == null:
			continue
		for i in mesh.mesh.get_blend_shape_count():
			var shape_name := String(mesh.mesh.get_blend_shape_name(i))
			if shape_name.begins_with("Eyes_") or shape_name.begins_with("Mouth_"):
				mesh.set_blend_shape_value(i, 0.0)
			elif shape_name in FacePresenter.LEGACY_COMPOSITE_KEYS:
				mesh.set_blend_shape_value(i, 0.0)


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
		if mesh.name == "人体_001" or mesh.name == "人体.001":
			return mesh.find_blend_shape_by_name(shape_name) >= 0
	for mesh in _meshes:
		if mesh.find_blend_shape_by_name(shape_name) >= 0:
			return true
	return false
