@tool
extends Node3D
class_name DoudouSandboxLayout

## 沙盒专用：在编辑器里拖 DoudouSlot（或它下面的预览模型）调站位。
## 运行时把兜兜放到这个世界坐标上，再从这里开始播动作。改完须保存场景并用 F6 运行本场景。

const YOUYOU_PREVIEW_NAME := "YouyouEditorPreview"
const DOUDOU_PREVIEW_NAME := "DoudouEditorPreview"


func get_youyou_slot() -> Node3D:
	return get_node_or_null("YouyouSlot") as Node3D


func get_doudou_slot() -> Node3D:
	return get_node_or_null("DoudouSlot") as Node3D


func hide_editor_previews() -> void:
	for slot_name in ["YouyouSlot", "DoudouSlot"]:
		var slot := get_node_or_null(slot_name)
		if slot == null:
			continue
		for child in slot.get_children():
			if child is Node3D:
				(child as Node3D).visible = false


func show_editor_previews_in_editor() -> void:
	if not Engine.is_editor_hint():
		return
	for slot_name in ["YouyouSlot", "DoudouSlot"]:
		var slot := get_node_or_null(slot_name)
		if slot == null:
			continue
		for child in slot.get_children():
			if child is Node3D:
				(child as Node3D).visible = true


func _ready() -> void:
	if Engine.is_editor_hint():
		show_editor_previews_in_editor()
