extends Control
class_name PlaneCountdownHowto
## Countdown howto: plate art below + separate number / GET READY labels above.

const PATH_3 := "res://assets/plane/howto_get_ready.png"
const PATH_2 := "res://assets/plane/howto_get_ready_2.png"
const PATH_1 := "res://assets/plane/howto_get_ready_1.png"
const PATH_START := "res://assets/plane/howto_get_ready_start.png"
## Crop past baked GET READY remnant (~y250/575); keep 移动/发射 pills
const PLATE_TOP_RATIO := 0.435

var _plate: TextureRect
var _num: Label
var _ready_lbl: Label
var _tex_full := {}
var _tex_plate := {}
var _step := "3"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_nodes()
	_ensure_tex()
	set_step("3")


func _ensure_nodes() -> void:
	if _plate != null:
		return
	_plate = TextureRect.new()
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_plate.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_plate)
	_num = Label.new()
	_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_num.add_theme_color_override("font_color", Color(0.965, 0.816, 0.337))
	_num.add_theme_color_override("font_outline_color", Color(0.416, 0.227, 0.031))
	_num.add_theme_constant_override("outline_size", 22)
	add_child(_num)
	_ready_lbl = Label.new()
	_ready_lbl.text = "GET READY"
	_ready_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ready_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ready_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ready_lbl.add_theme_color_override("font_color", Color(0.941, 0.784, 0.282))
	_ready_lbl.add_theme_color_override("font_outline_color", Color(0.29, 0.165, 0.031))
	_ready_lbl.add_theme_constant_override("outline_size", 10)
	add_child(_ready_lbl)


func _ensure_tex() -> void:
	if not _tex_full.is_empty():
		return
	_tex_full["3"] = _load_tex(PATH_3)
	_tex_full["2"] = _load_tex(PATH_2)
	_tex_full["1"] = _load_tex(PATH_1)
	_tex_full["START"] = _load_tex(PATH_START)
	for k in _tex_full.keys():
		_tex_plate[k] = _make_plate(_tex_full[k])


func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _make_plate(src: Texture2D) -> Texture2D:
	if src == null:
		return null
	var img := src.get_image()
	if img == null:
		return src
	var h := img.get_height()
	var w := img.get_width()
	var top := clampi(int(round(float(h) * PLATE_TOP_RATIO)), 0, h - 8)
	var plate := img.get_region(Rect2i(0, top, w, h - top))
	return ImageTexture.create_from_image(plate)


func reset_anim() -> void:
	pass


func set_step(step_text: String) -> void:
	_ensure_nodes()
	_ensure_tex()
	_step = step_text
	if _tex_plate.has(step_text):
		_plate.texture = _tex_plate[step_text]
	elif _tex_plate.has("3"):
		_plate.texture = _tex_plate["3"]
	if step_text == "START":
		_num.text = "START"
	else:
		_num.text = step_text
	_ready_lbl.visible = true
	_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()


func _layout() -> void:
	if _plate == null or size.x < 8.0 or size.y < 8.0:
		return
	var w := size.x
	var h := size.y
	var head_h := h * 0.30
	var num_mul := 0.18
	if _step == "START":
		num_mul = 0.11
	var base := minf(w, h)
	_num.add_theme_font_size_override("font_size", int(round(base * num_mul)))
	_ready_lbl.add_theme_font_size_override("font_size", int(round(base * 0.038)))
	_num.size = Vector2(w * 0.72, head_h * 0.62)
	_num.position = Vector2((w - _num.size.x) * 0.5, h * 0.018)
	_ready_lbl.size = Vector2(w * 0.70, head_h * 0.28)
	_ready_lbl.position = Vector2((w - _ready_lbl.size.x) * 0.5, _num.position.y + _num.size.y * 0.92)
	var plate_top := _ready_lbl.position.y + _ready_lbl.size.y + h * 0.012
	var plate_h := h - plate_top - h * 0.01
	var plate_w := w * 0.92
	_plate.position = Vector2((w - plate_w) * 0.5, plate_top)
	_plate.size = Vector2(plate_w, maxf(40.0, plate_h))
