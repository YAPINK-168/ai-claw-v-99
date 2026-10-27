extends RefCounted
class_name YouyouDirectVisemeMeshPlayer

## 与 squint mix 测试场景一致：口型直接写 mesh，不经 FacePresenter tween。

const FacePresenter := preload("res://Scripts/youyou_face_presenter.gd")

const VISEME_INTERVAL := 0.13

var _meshes: Array[MeshInstance3D] = []
var _player: AudioStreamPlayer
var _viseme_coef := FacePresenter.APPROVED_VISEME_COEF
var _active := false
var _idx := 0
var _accum := 0.0
var _last_pos := 0.0


func setup(meshes: Array[MeshInstance3D], player: AudioStreamPlayer) -> void:
	_meshes = meshes
	_player = player


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
	_apply_direct_viseme(FacePresenter.VISEME_IDS[0])


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
		return
	_accum += advanced
	var step := maxf(VISEME_INTERVAL, 0.04)
	while _accum >= step:
		_accum -= step
		_idx = (_idx + 1) % FacePresenter.VISEME_IDS.size()
		_apply_direct_viseme(FacePresenter.VISEME_IDS[_idx])


func _apply_direct_viseme(viseme_id: String) -> void:
	_zero_viseme_shapes_only()
	var shape_name := String(FacePresenter.VISEME_SHAPE_NAMES.get(viseme_id.to_lower(), ""))
	if shape_name == "":
		return
	var w := _viseme_coef
	for mesh in _meshes:
		if mesh.name not in FacePresenter.VISEME_MESH_PARTICIPANTS:
			continue
		var idx := mesh.find_blend_shape_by_name(shape_name)
		if idx >= 0:
			mesh.set_blend_shape_value(idx, w)


func _zero_viseme_shapes_only() -> void:
	for mesh in _meshes:
		for vid in FacePresenter.VISEME_IDS:
			var shape_name := String(FacePresenter.VISEME_SHAPE_NAMES[vid])
			var idx := mesh.find_blend_shape_by_name(shape_name)
			if idx >= 0:
				mesh.set_blend_shape_value(idx, 0.0)
