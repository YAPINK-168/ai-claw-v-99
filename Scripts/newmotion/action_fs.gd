class_name NewMotionActionFs
extends Object

## 序列帧放在工程里，但用 .gdignore 不让编辑器导入/出缩略图。
## 运行时按磁盘路径读 PNG / WebP。有 PNG 用 PNG，否则用 WebP。

const RES_ROOT := "res://NewMotion/动作"
const CANVAS_NAME := "canvas.json"


static func abs_root() -> String:
	return ProjectSettings.globalize_path(RES_ROOT)


static func clip_dir(action_name: String) -> String:
	return abs_root().path_join(action_name)


static func png_path(action_name: String, file_name: String) -> String:
	return clip_dir(action_name).path_join(file_name)


static func folder_has_frames(folder: String) -> bool:
	return not list_frame_names_in(folder).is_empty()


static func list_frame_names(action_name: String) -> PackedStringArray:
	return list_frame_names_in(clip_dir(action_name))


static func list_frame_names_in(folder: String) -> PackedStringArray:
	var pngs := PackedStringArray()
	var webps := PackedStringArray()
	var dir := DirAccess.open(folder)
	if dir == null:
		return pngs
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir():
			var ext := entry.get_extension().to_lower()
			if ext == "png":
				pngs.append(entry)
			elif ext == "webp":
				webps.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	if not pngs.is_empty():
		pngs.sort()
		return pngs
	webps.sort()
	return webps


static func load_canvas(action_name: String) -> Dictionary:
	return load_canvas_in(clip_dir(action_name))


static func load_canvas_in(folder: String) -> Dictionary:
	var path := folder.path_join(CANVAS_NAME)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


static func load_png(path: String) -> Texture2D:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)
