extends Node
class_name YouyouHeadFollowController

## 在 AnimationPlayer 之后叠加 mixamorig_Head 微小旋转（仅测试场 / 基础待机）。

const HEAD_BONE := &"mixamorig_Head"

@export var max_yaw_deg: float = 12.5
@export var max_pitch_deg: float = 9.0
@export var smooth_speed: float = 5.0
@export var keyboard_smooth_speed: float = 17.0
@export var gaze_horizontal_ref: float = 0.95
@export var gaze_vertical_ref: float = 0.75

var _skeleton: Skeleton3D
var _head_idx := -1
var _enabled := false
var _target_yaw := 0.0
var _target_pitch := 0.0
var _current_yaw := 0.0
var _current_pitch := 0.0
var _applied_offset := Quaternion.IDENTITY
## 上一帧写入前的动画姿势。操作循环每帧重写头部时，用它叠 WASD，避免把偏移抵消掉。
var _base_pose := Quaternion.IDENTITY
var _have_base := false


func setup(model_root: Node3D) -> void:
	_skeleton = model_root.find_child("Skeleton3D", true, false) as Skeleton3D
	if _skeleton == null:
		push_error("YouyouHeadFollowController: 未找到 Skeleton3D")
		return
	_head_idx = _skeleton.find_bone(HEAD_BONE)
	if _head_idx < 0:
		push_error("YouyouHeadFollowController: 未找到骨骼 " + String(HEAD_BONE))
	process_priority = 101


func relinquish() -> void:
	_strip_applied_offset()
	_enabled = false
	_target_yaw = 0.0
	_target_pitch = 0.0
	_current_yaw = 0.0
	_current_pitch = 0.0


func set_enabled(on: bool) -> void:
	if _enabled and not on:
		_target_yaw = 0.0
		_target_pitch = 0.0
	_enabled = on


func is_enabled() -> bool:
	return _enabled


func get_current_yaw() -> float:
	return _current_yaw


func get_current_pitch() -> float:
	return _current_pitch


func set_smooth_speed(speed: float) -> void:
	smooth_speed = maxf(speed, 0.1)


func set_follow_gaze(gaze: Vector2) -> void:
	if not _enabled or _head_idx < 0:
		_target_yaw = 0.0
		_target_pitch = 0.0
		return
	var hx := clampf(gaze.x / maxf(gaze_horizontal_ref, 0.001), -1.0, 1.0)
	var vy := clampf(gaze.y / maxf(gaze_vertical_ref, 0.001), -1.0, 1.0)
	_target_yaw = deg_to_rad(max_yaw_deg) * hx * 0.92
	_target_pitch = deg_to_rad(max_pitch_deg) * vy * 0.9


func get_target_yaw_deg() -> float:
	return rad_to_deg(_target_yaw)


func get_current_yaw_deg() -> float:
	return rad_to_deg(_current_yaw)


func get_current_pitch_deg() -> float:
	return rad_to_deg(_current_pitch)


func process_follow(delta: float) -> void:
	if _skeleton == null or _head_idx < 0:
		return
	var t := clampf(smooth_speed * delta, 0.0, 1.0)
	var want_yaw := _target_yaw if _enabled else 0.0
	var want_pitch := _target_pitch if _enabled else 0.0
	_current_yaw = lerpf(_current_yaw, want_yaw, t)
	_current_pitch = lerpf(_current_pitch, want_pitch, t)
	_apply_additive()


func _apply_additive() -> void:
	if _skeleton == null or _head_idx < 0:
		return
	var pose := _skeleton.get_bone_pose_rotation(_head_idx)
	var base := pose
	if _have_base and _same_rotation(pose, _base_pose * _applied_offset):
		base = _base_pose
	var offset := Quaternion.IDENTITY
	if _enabled:
		offset = Quaternion.from_euler(Vector3(_current_pitch, _current_yaw, 0.0))
	_base_pose = base
	_have_base = true
	_skeleton.set_bone_pose_rotation(_head_idx, base * offset)
	_applied_offset = offset


func _strip_applied_offset() -> void:
	if _skeleton != null and _head_idx >= 0 and _have_base:
		var pose := _skeleton.get_bone_pose_rotation(_head_idx)
		if _same_rotation(pose, _base_pose * _applied_offset):
			_skeleton.set_bone_pose_rotation(_head_idx, _base_pose)
	_applied_offset = Quaternion.IDENTITY
	_have_base = false


func _same_rotation(a: Quaternion, b: Quaternion) -> bool:
	return a.angle_to(b) < 0.01
