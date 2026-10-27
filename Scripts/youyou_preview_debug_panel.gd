extends CanvasLayer
class_name PreviewDebugPanel
## 主场景右上角粉白半透明调试面板。

const PANEL_W := 268.0
const MARGIN := 12.0
const MAX_BODY_LINES := 11

const BG := Color(1.0, 0.97, 0.99, 0.58)
const BORDER := Color(1.0, 0.82, 0.9, 0.85)
const TITLE := Color(0.78, 0.38, 0.52, 1.0)
const BODY := Color(0.42, 0.28, 0.36, 0.92)

var _title: Label
var _body: Label


func _ready() -> void:
	layer = 25
	_build()


func _build() -> void:
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.anchor_left = 1.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -PANEL_W - MARGIN
	panel.offset_top = MARGIN
	panel.offset_right = -MARGIN
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var box := StyleBoxFlat.new()
	box.bg_color = BG
	box.border_color = BORDER
	box.set_border_width_all(1)
	box.set_corner_radius_all(10)
	box.shadow_color = Color(0.85, 0.55, 0.68, 0.22)
	box.shadow_size = 6
	box.shadow_offset = Vector2(0, 2)
	box.set_content_margin_all(11)
	panel.add_theme_stylebox_override("panel", box)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	_title = Label.new()
	_title.name = "Title"
	_title.text = "调试"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title.add_theme_font_size_override("font_size", 13)
	_title.add_theme_color_override("font_color", TITLE)
	vbox.add_child(_title)

	_body = Label.new()
	_body.name = "Body"
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_body.add_theme_font_size_override("font_size", 12)
	_body.add_theme_color_override("font_color", BODY)
	vbox.add_child(_body)


func set_body(text: String) -> void:
	if _body == null:
		return
	var lines := text.split("\n", false)
	if lines.is_empty():
		_title.text = "调试"
		_body.text = ""
		return
	var head := String(lines[0])
	var body_lines: PackedStringArray = []
	if head.begins_with("调试"):
		_title.text = head
		if lines.size() > 1:
			body_lines = lines.slice(1)
	else:
		_title.text = "调试"
		body_lines = lines
	if body_lines.size() > MAX_BODY_LINES:
		body_lines = body_lines.slice(body_lines.size() - MAX_BODY_LINES, body_lines.size())
	_body.text = "\n".join(body_lines) if not body_lines.is_empty() else ""


func set_gameplay_hidden(hidden: bool) -> void:
	visible = not hidden


static func log_worthy(message: String) -> bool:
	if message.begins_with("错误"):
		return true
	if message.begins_with("[业务]"):
		return true
	if message.begins_with("[抓取]"):
		if message.length() > 72:
			return false
		return true
	if message.begins_with("[AI]") or message.begins_with("[AI-VAD]"):
		return true
	if message.begins_with("[待机]"):
		return "拒绝" in message or "blocked" in message or "业务接管" in message
	if message.begins_with("[小游戏"):
		return true
	return false
