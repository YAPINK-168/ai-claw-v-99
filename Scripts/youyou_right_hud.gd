extends CanvasLayer
class_name YouyouRightHud
## 主场景人物右侧：本轮大奖（语音交互已移至 LeftHud 台词下方）。

const DISPLAY_W := 328.0
const MARGIN := 10.0
const TOP_INSET := 118.0
const STACK_SEP := 8.0

const TEX_PRIZE := "res://assets/youyou_ui/panel_grand_prize.png"

const TEXT_PRIZE := Color(1.0, 1.0, 1.0, 1.0)

const FloatingUi := preload("res://Scripts/ui/floating_ui.gd")

var _prize_name: Label


func _ready() -> void:
	layer = 12
	_build()
	set_prize_name("")


func set_prize_name(text: String) -> void:
	if _prize_name != null:
		_prize_name.text = text


func _build() -> void:
	var anchor := _anchor_top_right()
	add_child(anchor)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", STACK_SEP)
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_END
	anchor.add_child(vbox)
	vbox.add_child(_make_prize_panel())


func _anchor_top_right() -> MarginContainer:
	var m := MarginContainer.new()
	m.name = "RightStack"
	m.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	m.anchor_left = 1.0
	m.anchor_right = 1.0
	m.offset_left = -(MARGIN + DISPLAY_W)
	m.offset_top = TOP_INSET
	m.offset_right = -MARGIN
	m.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	m.grow_vertical = Control.GROW_DIRECTION_END
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return m


func _make_art_panel(node_name: String, path: String, float_cfg: Dictionary = {}) -> Control:
	var tex := load(path) as Texture2D
	var h := 80.0
	if tex != null:
		h = DISPLAY_W * tex.get_height() / maxf(tex.get_width(), 1.0)
	else:
		push_error("RightHud 缺少贴图：%s" % path)
	var root := Control.new()
	root.name = node_name
	root.custom_minimum_size = Vector2(DISPLAY_W, h)
	root.clip_contents = true
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var visual := FloatingUi.wrap_layout_panel(root, float_cfg)
	var rect := TextureRect.new()
	rect.name = "Art"
	if tex != null:
		rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(rect)
	return root


func _panel_visual(root: Control) -> Control:
	return root.get_node("FloatVisual") as Control


func _make_prize_panel() -> Control:
	var root := _make_art_panel("GrandPrizePanel", TEX_PRIZE)
	_prize_name = _overlay_label(_panel_visual(root), 12, TEXT_PRIZE, true)
	_prize_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prize_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prize_name.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_prize_name.offset_left = 36.0
	_prize_name.offset_top = -36.0
	_prize_name.offset_right = -36.0
	_prize_name.offset_bottom = -8.0
	_prize_name.add_theme_constant_override("outline_size", 3)
	_prize_name.add_theme_color_override("font_outline_color", Color(0.85, 0.25, 0.55, 0.9))
	return root


func _overlay_label(parent: Control, font_size: int, color: Color, bold: bool) -> Label:
	var lb := Label.new()
	lb.name = "OverlayLabel"
	lb.add_theme_font_size_override("font_size", font_size)
	lb.add_theme_color_override("font_color", color)
	if bold:
		lb.add_theme_constant_override("outline_size", 2)
		lb.add_theme_color_override("font_outline_color", Color(0.45, 0.15, 0.35, 0.85))
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lb)
	return lb
