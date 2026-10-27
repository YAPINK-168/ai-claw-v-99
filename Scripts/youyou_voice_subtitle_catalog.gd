extends RefCounted
class_name YouyouVoiceSubtitleCatalog

const CONFIG_PATH := "res://config/youyou_voice_subtitles.json"

static var _by_filename: Dictionary = {}
static var _loaded := false


static func subtitle_for_audio_path(audio_path: String) -> String:
	_ensure_loaded()
	if audio_path.is_empty():
		return ""
	var key := audio_path.get_file()
	if _by_filename.has(key):
		return String(_by_filename[key])
	for name in _by_filename.keys():
		if key.contains(String(name).trim_suffix(".mp3")):
			return String(_by_filename[name])
	return ""


static func notify_audio(host: Node, audio_path: String) -> void:
	if audio_path.is_empty() or host == null:
		return
	var node: Node = host
	while node != null:
		if node.has_method("on_voice_subtitle_audio"):
			node.call("on_voice_subtitle_audio", audio_path)
			return
		node = node.get_parent()


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_by_filename = {}
	if not ResExists.path(CONFIG_PATH):
		push_warning("台词表缺失：" + CONFIG_PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not (parsed is Dictionary):
		push_warning("台词表 JSON 无效")
		return
	var raw: Variant = parsed.get("by_filename", {})
	if raw is Dictionary:
		_by_filename = raw
