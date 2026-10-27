extends Node3D
## 电玩城背景 Quad。前景花层保留节点但默认隐藏，避免挡住地板。

const BG_PATH := "res://assets/youyou_2_5d/arcade_neon.jpg"
const FG_PATH := "res://assets/youyou_2_5d/foreground_flowers.png"

const DESIGN_ASPECT := 16.0 / 9.0
const PLATE_CENTER_Y := 0.54
const BACK_Z := -1.2
const FORE_Z := 0.8
const ORTHO_SIZE := 1.45
const CAMERA_DISTANCE := 3.0
const SHADOW_SHADER_PATH := "res://shaders/youyou_2_5d_ground_shadow.gdshader"
const SHADOW_Y := 0.008
const SHADOW_SIZE := Vector2(0.50, 0.20)

@onready var _back: MeshInstance3D = $SkyCity_BackPlate
@onready var _fore: MeshInstance3D = $Flowers_Foreground

var _built := false
var _shadow: MeshInstance3D
var _shadow_mat: ShaderMaterial
var _follow: Node3D


func build() -> void:
	if _built:
		return
	var plate_h := ORTHO_SIZE
	var plate_w := plate_h * DESIGN_ASPECT
	_place_quad(_back, BG_PATH, false, plate_w, plate_h, Vector3(0.0, PLATE_CENTER_Y, BACK_Z))
	_setup_foot_shadow()
	_place_quad(_fore, FG_PATH, true, plate_w, plate_h, Vector3(0.0, PLATE_CENTER_Y, FORE_Z))
	if _fore != null:
		_fore.visible = false
	_built = true


func apply_plate_grade(plate_shader: Shader, shader_params: Dictionary) -> void:
	for plate in [_back, _fore]:
		if plate == null:
			continue
		var path := BG_PATH if plate == _back else FG_PATH
		_apply_grade_material(plate, path, plate == _fore, plate_shader, shader_params)


func set_contact_shadow(tint: Color, strength: float) -> void:
	if _shadow_mat == null:
		return
	_shadow_mat.set_shader_parameter("shadow_color", Vector3(tint.r, tint.g, tint.b))
	_shadow_mat.set_shader_parameter("strength", clampf(strength, 0.0, 0.6))


func set_follow_target(target: Node3D) -> void:
	_follow = target
	if _shadow != null:
		_sync_shadow_position()


func _setup_foot_shadow() -> void:
	_shadow = MeshInstance3D.new()
	_shadow.name = "FootContactShadow"
	add_child(_shadow)
	var quad := QuadMesh.new()
	quad.size = SHADOW_SIZE
	_shadow.mesh = quad
	_shadow.rotation.x = -PI * 0.5
	_shadow.position.y = SHADOW_Y
	_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shadow_mat = ShaderMaterial.new()
	var shadow_shader := load(SHADOW_SHADER_PATH) as Shader
	if shadow_shader == null:
		push_error("缺少脚影 Shader：%s" % SHADOW_SHADER_PATH)
	else:
		_shadow_mat.shader = shadow_shader
	_shadow_mat.set_shader_parameter("strength", 0.30)
	_shadow_mat.set_shader_parameter("shadow_color", Color(0.22, 0.08, 0.28))
	_shadow_mat.set_shader_parameter("ellipse_scale", Vector2(0.28, 0.11))
	_shadow.material_override = _shadow_mat
	_sync_shadow_position()


func _process(_delta: float) -> void:
	if _follow != null and is_instance_valid(_follow):
		_sync_shadow_position()


func _sync_shadow_position() -> void:
	if _shadow == null or _follow == null:
		return
	var p := _follow.global_position
	_shadow.global_position = Vector3(p.x, SHADOW_Y, p.z)


static func camera_focus() -> Vector3:
	return Vector3(0.0, PLATE_CENTER_Y, 0.0)


static func camera_distance() -> float:
	return CAMERA_DISTANCE


static func ortho_size() -> float:
	return ORTHO_SIZE


## 正交机位：保证视锥不超出背景/前景 Quad（与 build 时 plate 尺寸一致）。
static func clamp_camera_to_plate(focus_y: float, ortho_height: float, viewport_aspect: float) -> Vector2:
	var plate_half_h := ORTHO_SIZE * 0.5
	var plate_half_w := ORTHO_SIZE * DESIGN_ASPECT * 0.5
	var cy := PLATE_CENTER_Y
	var ortho := maxf(ortho_height, 0.01)
	var aspect := maxf(viewport_aspect, 0.01)
	var vis_half_w := ortho * aspect * 0.5
	if vis_half_w > plate_half_w:
		ortho = (plate_half_w * 2.0) / aspect
	var vis_half_h := ortho * 0.5
	var y_lo := cy - plate_half_h + vis_half_h
	var y_hi := cy + plate_half_h - vis_half_h
	if y_lo > y_hi:
		ortho = ORTHO_SIZE
		vis_half_h = ortho * 0.5
		y_lo = cy - plate_half_h + vis_half_h
		y_hi = cy + plate_half_h - vis_half_h
	return Vector2(clampf(focus_y, y_lo, y_hi), ortho)


func _place_quad(
	plate: MeshInstance3D,
	tex_path: String,
	transparent: bool,
	width: float,
	height: float,
	pos: Vector3
) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(width, height)
	plate.mesh = quad
	plate.position = pos
	plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	plate.material_override = _make_standard_plate_material(tex_path, transparent)


func _make_standard_plate_material(tex_path: String, transparent: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(tex_path) as Texture2D
	mat.albedo_color = Color(1.0, 1.0, 1.0)
	mat.roughness = 1.0
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


func _apply_grade_material(
	plate: MeshInstance3D,
	tex_path: String,
	transparent: bool,
	plate_shader: Shader,
	shader_params: Dictionary
) -> void:
	if plate_shader == null:
		plate.material_override = _make_standard_plate_material(tex_path, transparent)
		return
	var sm := ShaderMaterial.new()
	sm.shader = plate_shader
	sm.set_shader_parameter("albedo_tex", load(tex_path) as Texture2D)
	for key in shader_params:
		sm.set_shader_parameter(StringName(key), shader_params[key])
	sm.set_shader_parameter("alpha_scissor", 0.02 if transparent else 0.0)
	plate.material_override = sm
