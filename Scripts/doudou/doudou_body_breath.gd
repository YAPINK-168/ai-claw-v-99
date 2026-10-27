extends Node
class_name DoudouBodyBreath

## 在 AnimationPlayer 之后对胸廓骨骼做轻微 additive，营造呼吸起伏。

const BONE_LAYERS: Array[Dictionary] = [
	{
		"names": ["mixamorig:Spine2", "mixamorig_Spine2"],
		"pitch_weight": 0.5,
	},
	{
		"names": ["mixamorig:Spine1", "mixamorig_Spine1"],
		"pitch_weight": 0.32,
	},
	{
		"names": ["mixamorig:Spine", "mixamorig_Spine"],
		"pitch_weight": 0.18,
	},
]

const PERIOD_SEC_DEFAULT := 3.35
const PITCH_DEG_DEFAULT := 4.2
const SPINE2_LIFT_DEFAULT := 0.0095
## 沙盒叉腰待机：起伏要一眼能看出来（程序叠在 GLB 待机之上）。
const PERIOD_SEC_HUB_IDLE := 3.55
const PITCH_DEG_HUB_IDLE := 9.5
const SPINE2_LIFT_HUB_IDLE := 0.024
const HUB_IDLE_STRENGTH := 1.55

var _skeleton: Skeleton3D
var _anim_player: AnimationPlayer
var _bones: Array[Dictionary] = []
var _phase_t := 0.0
var _enabled := true
var _strength := 1.0
var _hub_idle_prominent := false
var _period_sec := PERIOD_SEC_DEFAULT
var _pitch_deg := PITCH_DEG_DEFAULT
var _spine2_lift_m := SPINE2_LIFT_DEFAULT
var _last_additive: Dictionary = {}
var _last_lift: Dictionary = {}


func setup(model_root: Node3D, anim_player: AnimationPlayer = null) -> void:
	_skeleton = model_root.find_child("Skeleton3D", true, false) as Skeleton3D
	_anim_player = anim_player
	if _anim_player == null:
		_anim_player = model_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_rebind_bones()
	# 数值越小越晚于 AnimationPlayer(0) 执行，避免本帧动画盖掉或叠乱呼吸。
	if _anim_player != null:
		_anim_player.process_priority = 0
	process_priority = -120
	set_process(true)


func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	if not enabled:
		sync_after_skeleton_reset()


func set_strength(strength: float) -> void:
	_strength = clampf(strength, 0.0, 2.5)


## 叉腰待机 hub：加强胸口起伏；其它动作恢复默认。
func set_hub_idle_prominent(enabled: bool) -> void:
	if _hub_idle_prominent == enabled:
		return
	_hub_idle_prominent = enabled
	if enabled:
		_period_sec = PERIOD_SEC_HUB_IDLE
		_pitch_deg = PITCH_DEG_HUB_IDLE
		_spine2_lift_m = SPINE2_LIFT_HUB_IDLE
		_strength = HUB_IDLE_STRENGTH
	else:
		_period_sec = PERIOD_SEC_DEFAULT
		_pitch_deg = PITCH_DEG_DEFAULT
		_spine2_lift_m = SPINE2_LIFT_DEFAULT
		_strength = 1.08
	sync_after_skeleton_reset()


func sync_after_skeleton_reset() -> void:
	_last_additive.clear()
	_last_lift.clear()


func _rebind_bones() -> void:
	_bones.clear()
	sync_after_skeleton_reset()
	if _skeleton == null:
		push_warning("DoudouBodyBreath: 未找到 Skeleton3D")
		return
	for layer in BONE_LAYERS:
		for bone_name in layer["names"]:
			var idx := _skeleton.find_bone(String(bone_name))
			if idx >= 0:
				_bones.append({"idx": idx, "pitch_weight": float(layer["pitch_weight"])})
				break
	if _bones.is_empty():
		push_warning("DoudouBodyBreath: 脊柱骨骼未绑定，呼吸无效")


func _process(delta: float) -> void:
	if not _enabled or _skeleton == null or _bones.is_empty():
		return
	_phase_t += delta
	var wave := sin(_phase_t * TAU / _period_sec)
	var breath := (wave + 1.0) * 0.5
	breath = breath * breath * (3.0 - 2.0 * breath)
	breath *= _strength
	for entry in _bones:
		var idx: int = entry["idx"]
		var pitch := deg_to_rad(_pitch_deg * float(entry["pitch_weight"]) * breath)
		var additive := Quaternion(Vector3.RIGHT, -pitch)
		var rot := _skeleton.get_bone_pose_rotation(idx)
		if _last_additive.has(idx):
			rot = rot * (_last_additive[idx] as Quaternion).inverse()
		_skeleton.set_bone_pose_rotation(idx, rot * additive)
		_last_additive[idx] = additive
		if float(entry["pitch_weight"]) >= 0.45:
			var lift := _spine2_lift_m * breath
			var pos := _skeleton.get_bone_pose_position(idx)
			if _last_lift.has(idx):
				pos -= _last_lift[idx] as Vector3
			pos.y += lift
			_skeleton.set_bone_pose_position(idx, pos)
			_last_lift[idx] = Vector3(0.0, lift, 0.0)
