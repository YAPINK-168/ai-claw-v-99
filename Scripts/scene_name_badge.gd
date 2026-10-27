extends RefCounted
## 在场景画面右上角用红字标出该场景文件名。

const COLOR := Color(1.0, 0.15, 0.12, 1.0)
const OUTLINE := Color(0.25, 0.0, 0.0, 1.0)
const LAYER := 120


static func attach(host: Node) -> void:
	if host == null or not host.is_inside_tree():
		return
	if host.get_node_or_null("SceneNameBadge") != null:
		return
	var layer := CanvasLayer.new()
	layer.name = "SceneNameBadge"
	layer.layer = LAYER
	host.add_child(layer)
	var label := Label.new()
	label.name = "NameLabel"
	label.text = title_of(host)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", COLOR)
	label.add_theme_color_override("font_outline_color", OUTLINE)
	label.add_theme_constant_override("outline_size", 6)
	label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var stack := host.get_tree().get_nodes_in_group("scene_name_badge").size()
	label.offset_left = -520.0
	label.offset_right = -16.0
	label.offset_top = 10.0 + stack * 32.0
	label.offset_bottom = 40.0 + stack * 32.0
	layer.add_child(label)
	label.add_to_group("scene_name_badge")


static func title_of(host: Node) -> String:
	var path := host.scene_file_path
	if path == "":
		return host.name
	var file := path.get_file().get_basename()
	if file == "main" and path.contains("miner/"):
		return "miner/main"
	return file
