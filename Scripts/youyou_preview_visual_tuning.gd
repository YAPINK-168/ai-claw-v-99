extends RefCounted
class_name YouyouPreviewVisualTuning
## 主界面 2.5D 视觉统一（集中微调）。在编辑器中改下列常量后运行主场景即可预览。

## ========== 背景（仅电玩城 Quad 的 unshaded Shader，不影响人物与 UI）==========
## 中间调约降 18%，高光再压地板反光和霓虹峰值。
const BACKGROUND_BRIGHTNESS := 0.82
const BACKGROUND_SATURATION := 1.05
const BACKGROUND_CONTRAST := 1.04
const BACKGROUND_HIGHLIGHT_ROLLOFF := 1.55
const BACKGROUND_HIGHLIGHT_THRESHOLD := 0.52

## ========== UI（CanvasLayer 子节点 modulate，不参与 3D 曝光）==========
const UI_BRIGHTNESS := 0.90
const UI_SATURATION := 0.93
const UI_GLOW_STRENGTH := 0.89

# --- 3D 角色灯光预设（不改相机曝光 / Tonemap / 背景 Shader / UI）---
const LightPresets := preload("res://Scripts/youyou_character_light_presets.gd")
## 当前电玩城。改成 LightPresets.Id.SKY_DAY 可恢复蓝天棚拍。
const ACTIVE_PRESET: LightPresets.Id = LightPresets.Id.NEON_ARCADE

## 曝光与辉光保持原值，避免整屏后处理连带改变 2D 背景。
const STUDIO_CAMERA_EXPOSURE := 0.88
const STUDIO_TONEMAP_EXPOSURE := 0.98
const STUDIO_BG_COLOR := Color(0.68, 0.84, 0.96, 1.0)
const STUDIO_SSAO_ENABLED := false
const STUDIO_SSR_ENABLED := false
const STUDIO_GLOW_INTENSITY := 0.03
const STUDIO_GLOW_STRENGTH := 0.12

const PLATE_SHADER_PATH := "res://shaders/youyou_2_5d_plate_grade.gdshader"


static func background_plate_shader_params() -> Dictionary:
	return {
		"brightness": BACKGROUND_BRIGHTNESS,
		"saturation": BACKGROUND_SATURATION,
		"contrast": BACKGROUND_CONTRAST,
		"highlight_rolloff": BACKGROUND_HIGHLIGHT_ROLLOFF,
		"highlight_threshold": BACKGROUND_HIGHLIGHT_THRESHOLD,
	}


static func ui_modulate_color() -> Color:
	var grey := UI_BRIGHTNESS
	var chroma := UI_SATURATION
	var r := lerpf(grey, grey * 1.02, chroma) * lerpf(1.0, UI_GLOW_STRENGTH, 0.15)
	var g := lerpf(grey, grey * 1.0, chroma)
	var b := lerpf(grey, grey * 1.04, chroma) * lerpf(1.0, UI_GLOW_STRENGTH, 0.35)
	return Color(r, g, b, 1.0)


static func apply_studio_2_5d(host: Node3D) -> void:
	var backdrop := host.get_node_or_null("Youyou2_5dBackdrop")
	if backdrop != null:
		if backdrop.has_method("build"):
			backdrop.call("build")
		if backdrop.has_method("apply_plate_grade"):
			var plate_shader := load(PLATE_SHADER_PATH) as Shader
			if plate_shader == null:
				push_error("缺少背景调色 Shader：%s" % PLATE_SHADER_PATH)
			else:
				backdrop.call("apply_plate_grade", plate_shader, background_plate_shader_params())
	apply_character_light_preset(host, ACTIVE_PRESET)
	_apply_camera(host)


static func apply_ui_canvas(layer: CanvasLayer) -> void:
	if layer == null:
		return
	var tint := ui_modulate_color()
	for child in layer.get_children():
		if child is CanvasItem:
			(child as CanvasItem).modulate = tint


static func apply_character_light_preset(host: Node3D, preset_id: LightPresets.Id) -> void:
	var preset := LightPresets.get_preset(preset_id)
	_apply_environment(host, preset)
	_apply_character_lights(host, preset)
	var backdrop := host.get_node_or_null("Youyou2_5dBackdrop")
	if backdrop != null and backdrop.has_method("set_contact_shadow"):
		backdrop.call("set_contact_shadow", preset["shadow_color"], preset["shadow_strength"])


static func _apply_environment(host: Node3D, preset: Dictionary) -> void:
	var world_env := host.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_env == null or world_env.environment == null:
		return
	var env := world_env.environment.duplicate() as Environment
	env.background_color = STUDIO_BG_COLOR
	env.tonemap_exposure = STUDIO_TONEMAP_EXPOSURE
	env.ambient_light_color = preset["ambient_color"]
	env.ambient_light_energy = preset["ambient_energy"]
	env.ssao_enabled = STUDIO_SSAO_ENABLED
	env.ssr_enabled = STUDIO_SSR_ENABLED
	env.glow_intensity = STUDIO_GLOW_INTENSITY
	env.glow_strength = STUDIO_GLOW_STRENGTH
	world_env.environment = env


static func _apply_camera(host: Node3D) -> void:
	var camera := host.get_node_or_null("ObservePivot/Camera3D") as Camera3D
	if camera == null or camera.attributes == null:
		return
	var attrs := camera.attributes.duplicate() as CameraAttributesPractical
	attrs.exposure_multiplier = STUDIO_CAMERA_EXPOSURE
	camera.attributes = attrs


static func _apply_character_lights(host: Node3D, preset: Dictionary) -> void:
	var key := host.get_node_or_null("KeyLight") as DirectionalLight3D
	if key != null:
		key.shadow_enabled = false
		key.light_energy = preset["key_energy"]
		key.light_color = preset["key_color"]
	var fill := host.get_node_or_null("FillLight") as DirectionalLight3D
	if fill != null:
		fill.light_energy = preset["fill_energy"]
		fill.light_color = preset["fill_color"]
	var face := host.get_node_or_null("ObservePivot/Camera3D/FaceFill") as OmniLight3D
	if face != null:
		face.light_energy = preset["face_energy"]
		face.light_color = preset["face_color"]
	var rim := host.get_node_or_null("HairRim") as DirectionalLight3D
	if rim != null:
		rim.light_energy = preset["rim_energy"]
		rim.light_color = preset["rim_color"]
