class_name HoneyMinigameHud
extends RefCounted
## 蜂蜜牛奶风小游戏 HUD 构建器（与方块/蛇一致）

const COL_TEXT := Color("6B4F3A")
const COL_ACCENT := Color("D4894A")
const COL_MUTED := Color(0.55, 0.4, 0.3, 1)


static func build(host: Node, title_text: String, hint_text: String) -> Dictionary:
	var ui := CanvasLayer.new()
	ui.name = "UI"
	ui.layer = 12
	ui.visible = false
	host.add_child(ui)

	var top := HBoxContainer.new()
	top.name = "TopBar"
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 28
	top.offset_top = 14
	top.offset_right = -28
	top.offset_bottom = 54
	top.add_theme_constant_override("separation", 24)
	ui.add_child(top)

	var title := _label(title_text, 22, COL_TEXT)
	title.name = "Title"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)

	var score := _label("本局积分：0", 22, COL_ACCENT)
	score.name = "Score"
	score.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(score)

	var status := _label("", 20, COL_MUTED)
	status.name = "Status"
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(status)

	var bottom := HBoxContainer.new()
	bottom.name = "BottomBar"
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 24
	bottom.offset_top = -44
	bottom.offset_right = -24
	bottom.offset_bottom = -10
	ui.add_child(bottom)

	var hint := _label(hint_text, 15, Color(0.62, 0.45, 0.32, 0.92))
	hint.name = "Hint"
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(hint)

	var overlay := ColorRect.new()
	overlay.name = "Overlay"
	overlay.visible = false
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.78, 0.62, 0.42, 0.55)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 0)
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(1, 0.97, 0.92, 0.96)
	psb.border_color = Color(0.91, 0.72, 0.43, 0.98)
	psb.set_border_width_all(2)
	psb.set_corner_radius_all(10)
	psb.content_margin_left = 28
	psb.content_margin_right = 28
	psb.content_margin_top = 24
	psb.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", psb)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var msg := _label("游戏结束", 26, COL_TEXT)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(msg)

	var sub := _label("说明", 16, COL_MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(sub)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 48)
	btn.text = "返回娃娃机"
	btn.add_theme_color_override("font_color", COL_TEXT)
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(0.96, 0.84, 0.43, 1)
	bsb.border_color = Color(0.83, 0.54, 0.29, 1)
	bsb.set_border_width_all(2)
	bsb.set_corner_radius_all(8)
	bsb.content_margin_left = 16
	bsb.content_margin_right = 16
	bsb.content_margin_top = 10
	bsb.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal", bsb)
	vbox.add_child(btn)

	return {
		"ui": ui,
		"title": title,
		"score": score,
		"status": status,
		"hint": hint,
		"overlay": overlay,
		"msg": msg,
		"sub": sub,
		"btn": btn,
	}


static func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
