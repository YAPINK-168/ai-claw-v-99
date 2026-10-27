extends Node
class_name DoudouIdleBlink

## 沙盒兜兜随机眨眼。写在表情和时间线之后，用模型自带的 eyeBlink。

const BLINK_LEFT := "eyeBlinkLeft"
const BLINK_RIGHT := "eyeBlinkRight"

var _meshes: Array[MeshInstance3D] = []
var _left: PackedInt32Array = PackedInt32Array()
var _right: PackedInt32Array = PackedInt32Array()
var _ready_shapes := false
var _timer := 0.0
var _phase := "idle"
var _weight := 0.0
var _hold_left := 0.0
var _holding_closed := false


func setup(meshes: Array[MeshInstance3D]) -> void:
	_meshes = meshes
	_left.resize(meshes.size())
	_right.resize(meshes.size())
	var found := false
	for i in meshes.size():
		var mesh := meshes[i]
		_left[i] = mesh.find_blend_shape_by_name(BLINK_LEFT)
		_right[i] = mesh.find_blend_shape_by_name(BLINK_RIGHT)
		if _left[i] >= 0 or _right[i] >= 0:
			found = true
	_ready_shapes = found
	if not found:
		push_warning("兜兜眨眼：网格上没有 eyeBlinkLeft / eyeBlinkRight")
		set_process(false)
		return
	_timer = randf_range(0.8, 2.2)
	process_priority = 200
	set_process(true)


func _process(delta: float) -> void:
	if not _ready_shapes:
		return
	var host := get_parent() as Node3D
	if host != null and not host.is_visible_in_tree():
		if _holding_closed:
			_write(0.0)
			_holding_closed = false
			_phase = "idle"
			_weight = 0.0
		return
	_advance(delta)
	if _weight > 0.001:
		_write(_weight)
		_holding_closed = true
	elif _holding_closed:
		_write(0.0)
		_holding_closed = false


func _advance(delta: float) -> void:
	if _phase == "idle":
		_timer -= delta
		if _timer <= 0.0:
			_phase = "closing"
		return
	if _phase == "closing":
		_weight = move_toward(_weight, 1.0, 16.0 * delta)
		if _weight >= 0.98:
			_phase = "hold"
			_hold_left = 0.04
		return
	if _phase == "hold":
		_hold_left -= delta
		_weight = 1.0
		if _hold_left <= 0.0:
			_phase = "opening"
		return
	_weight = move_toward(_weight, 0.0, 12.0 * delta)
	if _weight <= 0.02:
		_weight = 0.0
		_phase = "idle"
		_timer = randf_range(1.6, 4.2)


func _write(weight: float) -> void:
	var w := clampf(weight, 0.0, 1.0)
	for i in _meshes.size():
		var mesh := _meshes[i]
		if mesh == null:
			continue
		if _left[i] >= 0:
			mesh.set_blend_shape_value(_left[i], w)
		if _right[i] >= 0:
			mesh.set_blend_shape_value(_right[i], w)
