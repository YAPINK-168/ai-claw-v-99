extends RefCounted
class_name DoudouDirectVisemeMeshPlayer

## 兜兜口型：Mouth_嘴型*，在 split 表情之后叠（与 squint 测试场一致）。

const FacePresenter := preload("res://Scripts/youyou_face_presenter.gd")
const DoudouFacePresenter := preload("res://Scripts/doudou/doudou_face_presenter.gd")

const VISEME_INTERVAL := 0.13
## 兜兜 morph 只有嘴型 A/E/O；i、u 与 e/o 同形，循环用这三档即可。
const DOUDOU_VISEME_CYCLE: PackedStringArray = ["a", "e", "o"]

var _meshes: Array[MeshInstance3D] = []
var _player: AudioStreamPlayer
var _face: DoudouFacePresenter
var _viseme_coef := DoudouFacePresenter.DOUDOU_VISEME_COEF
var _active := false
var _idx := 0
var _accum := 0.0
var _last_pos := 0.0


func setup(meshes: Array[MeshInstance3D], player: AudioStreamPlayer, face: DoudouFacePresenter) -> void:
	_meshes = meshes
	_player = player
	_face = face


func set_viseme_coef(value: float) -> void:
	_viseme_coef = clampf(value, 0.0, 1.0)


func start() -> void:
	_active = true
	_idx = 0
	_accum = 0.0
	_last_pos = 0.0
	if _player != null and _player.playing:
		_last_pos = _player.get_playback_position()
	_zero_viseme_shapes_only()
	_apply_direct_viseme(DOUDOU_VISEME_CYCLE[0])


func stop() -> void:
	_active = false
	_zero_viseme_shapes_only()


func is_active() -> bool:
	return _active


func tick() -> void:
	if not _active or _player == null or not _player.playing:
		return
	var pos := _player.get_playback_position()
	var advanced := pos - _last_pos
	if advanced < 0.0:
		advanced = pos
	_last_pos = pos
	if advanced <= 0.0:
		refresh_current()
		return
	_accum += advanced
	var step := maxf(VISEME_INTERVAL, 0.04)
	while _accum >= step:
		_accum -= step
		_idx = (_idx + 1) % DOUDOU_VISEME_CYCLE.size()
	_apply_direct_viseme(DOUDOU_VISEME_CYCLE[_idx])


func refresh_current() -> void:
	if not _active:
		return
	_apply_direct_viseme(DOUDOU_VISEME_CYCLE[_idx])


func _apply_direct_viseme(viseme_id: String) -> void:
	_zero_viseme_shapes_only()
	if _face == null:
		return
	var shape_name := _face.get_viseme_shape_name(viseme_id)
	if shape_name == "":
		return
	var w := _viseme_coef
	for mesh in _meshes:
		if not _face.is_viseme_participant_mesh(mesh):
			continue
		var idx := mesh.find_blend_shape_by_name(shape_name)
		if idx >= 0:
			mesh.set_blend_shape_value(idx, w)


func _zero_viseme_shapes_only() -> void:
	if _face == null:
		return
	for mesh in _meshes:
		for v in DoudouFacePresenter.DOUDOU_VISEME_SHAPE_NAMES.values():
			var shape_name := String(v)
			if shape_name == "":
				continue
			var idx := mesh.find_blend_shape_by_name(shape_name)
			if idx >= 0:
				mesh.set_blend_shape_value(idx, 0.0)
