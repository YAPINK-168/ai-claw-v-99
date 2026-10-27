extends Node3D

const _Backdrop := preload("res://Scripts/youyou_2_5d_backdrop.gd")

const MIN_DISTANCE := 0.35
const MAX_DISTANCE := 8.5
const PAN_LIMIT := 1.6
const ORBIT_SPEED := 0.008
const PAN_SPEED := 0.0014
const ZOOM_STEP := 1.1
const PITCH_LIMIT_DOWN := -55.0
const PITCH_LIMIT_UP := 65.0
## 进场景与按 R 时的默认机位。
## 透视默认：同语义——裆部以上半身。
const LOBBY_FOCUS := Vector3(0.0, 1.08, -0.015)
const LOBBY_DISTANCE := 3.95
const LOBBY_PITCH := -0.19
const LOBBY_YAW := 0.0

## 主场景 youyou_preview 默认：大腿根/膝上起，不露脚（勿用 plate clamp，否则焦点被锁在 0.54 会露出全身）。
const STUDIO_FOCUS := Vector3(0.0, 0.755, 0.0)
const STUDIO_DISTANCE := 3.0
const STUDIO_ORTHO_SIZE := 1.06
## 兜兜沙盒：与主 preview 相同上半身正交机位（不再拉远拍全身双人）。
const SANDBOX_ORTHO_SIZE := STUDIO_ORTHO_SIZE
const SANDBOX_STUDIO_DISTANCE := STUDIO_DISTANCE
## 投币开局后：手肘以上特写（焦点勿过高，否则人物偏下、头顶留白过大）。
const STUDIO_CLOSEUP_FOCUS_Y := 0.785
const STUDIO_CLOSEUP_ORTHO := 0.78
const LOBBY_CLOSEUP_FOCUS := Vector3(0.0, 1.12, -0.015)
const LOBBY_CLOSEUP_DISTANCE := 2.72
## 兜兜测试场默认机位（模型对齐后会由 set_doudou_orbit_focus 覆盖 Y）。
const DOUDOU_TEST_DISTANCE := 3.35
const DOUDOU_TEST_PITCH := -0.12
const DOUDOU_TEST_FOCUS_FALLBACK := Vector3(0.0, 0.88, 0.0)
const GRAB_CLOSEUP_IN_SEC := 0.88
const GRAB_CLOSEUP_OUT_SEC := 1.35

@onready var _camera: Camera3D = $Camera3D

var _studio_2_5d := false
var _grab_closeup := ""
var _grab_closeup_t := 0.0
var _grab_closeup_from_y := 0.0
var _grab_closeup_from_size := STUDIO_ORTHO_SIZE
var _grab_closeup_from_dist := LOBBY_DISTANCE
var _grab_closeup_home_pos := Vector3.ZERO
var _grab_closeup_restore_dist := LOBBY_DISTANCE
var _yaw := LOBBY_YAW
var _pitch := LOBBY_PITCH
var _distance := LOBBY_DISTANCE
var _distance_target := LOBBY_DISTANCE
var _home_position := LOBBY_FOCUS
var _home_yaw := LOBBY_YAW
var _home_pitch := LOBBY_PITCH
var _home_distance := LOBBY_DISTANCE
var _dragging := false
var _panning := false
var _alt_orbit_drag := false
var _doudou_orbit_focus: Vector3 = Vector3.INF
var _doudou_orbit_distance: float = -1.0
var _doudou_orbit_pitch: float = INF


func _ready() -> void:
	_camera.current = true
	var args := OS.get_cmdline_user_args()
	_check_log("ready args=" + str(args))
	if "--camera-check" in args:
		_run_camera_check()
	elif _parent_uses_studio_backdrop():
		set_studio_2_5d_mode(true)
	elif _is_doudou_preview_host():
		_apply_doudou_test_view()
	else:
		_apply_lobby_view()


func _process(delta: float) -> void:
	_step_grab_closeup(delta)
	if _grab_closeup == "":
		var blend := 1.0 - exp(-10.0 * delta)
		_distance = lerpf(_distance, _distance_target, blend)
	_apply_transform()


func begin_grab_round_closeup() -> void:
	if _grab_closeup in ["in", "hold"]:
		return
	_grab_closeup_home_pos = position
	_grab_closeup_restore_dist = _distance_target
	if _studio_2_5d:
		_grab_closeup_from_y = position.y
		_grab_closeup_from_size = _camera.size
	else:
		_grab_closeup_from_dist = _distance_target
	_store_home()
	_grab_closeup = "in"
	_grab_closeup_t = 0.0


func release_grab_round_closeup() -> void:
	if _grab_closeup == "" or _grab_closeup == "out":
		return
	_grab_closeup = "out"
	_grab_closeup_t = 0.0


func is_grab_closeup_active() -> bool:
	return _grab_closeup != ""


func set_studio_2_5d_mode(enabled: bool) -> void:
	_grab_closeup = ""
	_studio_2_5d = enabled
	if enabled:
		var dist := _sandbox_studio_distance() if _is_doudou_sandbox_host() else STUDIO_DISTANCE
		position = STUDIO_FOCUS
		position.x = STUDIO_FOCUS.x
		position.z = STUDIO_FOCUS.z
		_yaw = 0.0
		_pitch = 0.0
		_distance = dist
		_distance_target = dist
		_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		rotation = Vector3.ZERO
		_camera.position = Vector3(0.0, 0.0, dist)
		_apply_studio_default_frame()
		_store_home()
	else:
		_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		_apply_lobby_view()


func handle_camera_input(event: InputEvent) -> bool:
	if _studio_2_5d or _grab_closeup != "":
		return false
	return _process_camera_input(event)


func _unhandled_input(event: InputEvent) -> void:
	if _studio_2_5d:
		if _grab_closeup != "" and event is InputEventMouseButton:
			get_viewport().set_input_as_handled()
			return
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
			set_studio_2_5d_mode(true)
			get_viewport().set_input_as_handled()
		return
	if _process_camera_input(event):
		get_viewport().set_input_as_handled()


func _process_camera_input(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		reset_view()
		return true
	if event is InputEventMouseButton:
		return _on_mouse_button(event as InputEventMouseButton)
	if event is InputEventMouseMotion and _dragging:
		_on_mouse_motion(event as InputEventMouseMotion)
		return true
	return false


func _on_mouse_button(event: InputEventMouseButton) -> bool:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and event.alt_pressed:
			_dragging = true
			_alt_orbit_drag = true
			_panning = false
			return true
		if not event.pressed and _alt_orbit_drag:
			_dragging = false
			_alt_orbit_drag = false
			_panning = false
			return true
		return false
	if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_dragging = true
			_alt_orbit_drag = false
			_panning = event.shift_pressed
		else:
			_dragging = false
			_panning = false
		return true
	if not event.pressed:
		return false
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_distance_target = clampf(_distance_target / ZOOM_STEP, MIN_DISTANCE, MAX_DISTANCE)
		return true
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_distance_target = clampf(_distance_target * ZOOM_STEP, MIN_DISTANCE, MAX_DISTANCE)
		return true
	return false


func _on_mouse_motion(event: InputEventMouseMotion) -> void:
	var pan_now := _panning or event.shift_pressed
	if pan_now and not _alt_orbit_drag:
		_pan(event.relative)
	else:
		_orbit(event.relative)


func _orbit(relative: Vector2) -> void:
	_yaw -= relative.x * ORBIT_SPEED
	_pitch = clampf(_pitch - relative.y * ORBIT_SPEED, deg_to_rad(PITCH_LIMIT_DOWN), deg_to_rad(PITCH_LIMIT_UP))
	_apply_transform()


func _pan(relative: Vector2) -> void:
	var basis := global_transform.basis
	var offset := (-basis.x * relative.x + basis.y * relative.y) * PAN_SPEED * _distance
	position += offset
	var from_home := position - _home_position
	if from_home.length() > PAN_LIMIT:
		position = _home_position + from_home.normalized() * PAN_LIMIT
	_apply_transform()


func reset_view() -> void:
	if _studio_2_5d:
		set_studio_2_5d_mode(true)
		return
	if _is_doudou_preview_host():
		_apply_doudou_test_view()
		return
	_apply_lobby_view()


func set_doudou_orbit_focus(focus: Vector3, distance: float = -1.0, pitch: float = INF) -> void:
	_doudou_orbit_focus = focus
	_doudou_orbit_distance = distance
	_doudou_orbit_pitch = pitch
	var dist := DOUDOU_TEST_DISTANCE if distance <= 0.0 else distance
	var p := DOUDOU_TEST_PITCH if not is_finite(pitch) else pitch
	_apply_orbit_view(focus, LOBBY_YAW, p, dist)


func _parent_uses_studio_backdrop() -> bool:
	return _is_main_preview_scene()


func _is_main_preview_scene() -> bool:
	var host := get_parent()
	if host == null:
		return false
	if host.name == "YouyouPreview":
		return true
	var kind: Variant = host.get("backdrop_kind")
	return kind != null and int(kind) == 1


func _is_doudou_sandbox_host() -> bool:
	var host := get_parent()
	return host != null and String(host.name) == "YouyouPreviewDoudouSandbox"


func _sandbox_studio_distance() -> float:
	return SANDBOX_STUDIO_DISTANCE


func _sandbox_ortho_size() -> float:
	return SANDBOX_ORTHO_SIZE


func _is_doudou_preview_host() -> bool:
	var host := get_parent()
	if host == null:
		return false
	return (
		host.name == "DoudouEmotionLipsyncTest"
		or host.name == "DoudouFullbodyPreview"
		or host.name == "DoudouEntranceAudioCueTest"
		or host.name == "DoudouSquintMixTest"
	)


func _apply_doudou_test_view() -> void:
	var host := get_parent()
	if host != null and host.has_method("refresh_doudou_camera"):
		host.call("refresh_doudou_camera")
		return
	var focus := _doudou_orbit_focus
	if not is_finite(focus.x):
		focus = DOUDOU_TEST_FOCUS_FALLBACK
	var dist := DOUDOU_TEST_DISTANCE if _doudou_orbit_distance <= 0.0 else _doudou_orbit_distance
	var p := DOUDOU_TEST_PITCH if not is_finite(_doudou_orbit_pitch) else _doudou_orbit_pitch
	_apply_orbit_view(focus, LOBBY_YAW, p, dist)


func _apply_orbit_view(focus: Vector3, yaw: float, pitch: float, dist: float) -> void:
	position = focus
	_yaw = yaw
	_pitch = pitch
	_distance = dist
	_distance_target = dist
	_apply_transform()
	_store_home()


func _apply_studio_default_frame() -> void:
	var ortho := STUDIO_ORTHO_SIZE
	if _is_main_preview_scene() or _is_doudou_sandbox_host():
		position.x = STUDIO_FOCUS.x
		position.y = STUDIO_FOCUS.y
		position.z = STUDIO_FOCUS.z
		_camera.size = ortho
	else:
		_apply_plate_clamped_studio(STUDIO_FOCUS.y, ortho)


func _apply_lobby_view() -> void:
	_apply_orbit_view(LOBBY_FOCUS, LOBBY_YAW, LOBBY_PITCH, LOBBY_DISTANCE)


func _apply_transform() -> void:
	rotation = Vector3(_pitch, _yaw, 0.0)
	_camera.position = Vector3(0.0, 0.0, _distance)


func _store_home() -> void:
	_home_position = position
	_home_yaw = _yaw
	_home_pitch = _pitch
	_home_distance = _distance_target


func _step_grab_closeup(delta: float) -> void:
	if _grab_closeup == "":
		return
	_grab_closeup_t += delta
	if _studio_2_5d:
		_step_grab_closeup_studio()
	else:
		_step_grab_closeup_perspective()


func _step_grab_closeup_studio() -> void:
	match _grab_closeup:
		"in":
			var u := _ease(clampf(_grab_closeup_t / GRAB_CLOSEUP_IN_SEC, 0.0, 1.0))
			var y := lerpf(_grab_closeup_from_y, STUDIO_CLOSEUP_FOCUS_Y, u)
			var ortho := lerpf(_grab_closeup_from_size, STUDIO_CLOSEUP_ORTHO, u)
			_apply_plate_clamped_studio(y, ortho)
			if u >= 1.0:
				_grab_closeup = "hold"
				_grab_closeup_t = 0.0
		"hold":
			_apply_plate_clamped_studio(STUDIO_CLOSEUP_FOCUS_Y, STUDIO_CLOSEUP_ORTHO)
		"out":
			var u := _ease(clampf(_grab_closeup_t / GRAB_CLOSEUP_OUT_SEC, 0.0, 1.0))
			var y := lerpf(STUDIO_CLOSEUP_FOCUS_Y, _grab_closeup_home_pos.y, u)
			var ortho := lerpf(STUDIO_CLOSEUP_ORTHO, _grab_closeup_from_size, u)
			_apply_plate_clamped_studio(y, ortho)
			if u >= 1.0:
				position.x = _grab_closeup_home_pos.x
				position.z = _grab_closeup_home_pos.z
				_apply_studio_default_frame()
				_grab_closeup = ""
				_grab_closeup_t = 0.0
				_store_home()


func _viewport_aspect() -> float:
	var vp := get_viewport().get_visible_rect().size
	if vp.y <= 0.0:
		return _Backdrop.DESIGN_ASPECT
	return vp.x / vp.y


func _apply_plate_clamped_studio(focus_y: float, ortho_height: float) -> void:
	var clamped := _Backdrop.clamp_camera_to_plate(focus_y, ortho_height, _viewport_aspect())
	position.y = clamped.x
	position.x = 0.0
	_camera.size = clamped.y


func _step_grab_closeup_perspective() -> void:
	match _grab_closeup:
		"in":
			var u := _ease(clampf(_grab_closeup_t / GRAB_CLOSEUP_IN_SEC, 0.0, 1.0))
			position = _grab_closeup_home_pos.lerp(LOBBY_CLOSEUP_FOCUS, u)
			_distance = lerpf(_grab_closeup_from_dist, LOBBY_CLOSEUP_DISTANCE, u)
			_distance_target = _distance
			if u >= 1.0:
				_grab_closeup = "hold"
				_grab_closeup_t = 0.0
		"hold":
			position = LOBBY_CLOSEUP_FOCUS
			_distance = LOBBY_CLOSEUP_DISTANCE
			_distance_target = LOBBY_CLOSEUP_DISTANCE
		"out":
			var u := _ease(clampf(_grab_closeup_t / GRAB_CLOSEUP_OUT_SEC, 0.0, 1.0))
			position = LOBBY_CLOSEUP_FOCUS.lerp(_grab_closeup_home_pos, u)
			_distance = lerpf(LOBBY_CLOSEUP_DISTANCE, _grab_closeup_restore_dist, u)
			_distance_target = _distance
			if u >= 1.0:
				position = _grab_closeup_home_pos
				_distance = _grab_closeup_restore_dist
				_distance_target = _grab_closeup_restore_dist
				_grab_closeup = ""
				_grab_closeup_t = 0.0
				_store_home()


func _ease(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)


func _run_camera_check() -> void:
	await get_tree().process_frame
	_apply_lobby_view()
	var lines: PackedStringArray = [
		"lobby_focus=" + str(position),
		"lobby_dist=" + str(_distance_target),
		"lobby_pitch_deg=" + str(rad_to_deg(_pitch)),
	]
	await _save_png("C:/Users/29385/AppData/Local/Temp/youyou_cam_front.png")
	_check_log("\n".join(lines))
	print("\n".join(lines))
	get_tree().quit()


func _check_log(message: String) -> void:
	var file := FileAccess.open("C:/Users/29385/AppData/Local/Temp/youyou_camera_check.log", FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open("C:/Users/29385/AppData/Local/Temp/youyou_camera_check.log", FileAccess.WRITE)
	if file == null:
		push_error("无法写相机检查日志")
		return
	file.seek_end()
	file.store_line(message)
	file.close()


func _save_png(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	print("png %s size=%s err=%s" % [path, image.get_size(), err])
