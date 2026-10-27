extends Control
class_name FloatingUi
## 面板内静态 FloatVisual 容器（无漂浮动画）。


static func wrap_layout_panel(layout_root: Control, _config: Dictionary = {}) -> Control:
	var visual := Control.new()
	visual.name = "FloatVisual"
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout_root.add_child(visual)
	return visual
