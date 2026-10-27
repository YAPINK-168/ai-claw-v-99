class_name VoiceTurnTrace
extends RefCounted

## 单轮语音生命周期低噪声追踪（YOUYOU_VOICE_TURN_TRACE=1 启用，不记录密钥）。

static var _enabled: bool = false
static var _session_gen: int = -1
static var _turn_submit_id: int = -1


static func refresh_from_env() -> void:
	var v := OS.get_environment("YOUYOU_VOICE_TURN_TRACE").strip_edges().to_lower()
	_enabled = v in ["1", "true", "yes", "on"]


static func set_context(session_gen: int, turn_submit_id: int = -1) -> void:
	_session_gen = session_gen
	if turn_submit_id >= 0:
		_turn_submit_id = turn_submit_id


static func log(event: String, extra: Dictionary = {}) -> void:
	if not _enabled:
		return
	var parts: PackedStringArray = PackedStringArray()
	parts.append("event=%s" % event)
	if _session_gen >= 0:
		parts.append("session_gen=%d" % _session_gen)
	if _turn_submit_id >= 0:
		parts.append("turn_submit=%d" % _turn_submit_id)
	for k in extra.keys():
		var val = extra[k]
		if val is String and _looks_sensitive(str(val)):
			continue
		parts.append("%s=%s" % [str(k), str(val)])
	print("[voice_turn_trace] ", ", ".join(parts))


static func _looks_sensitive(raw: String) -> bool:
	var lower := raw.to_lower()
	return lower.contains("sk-") or lower.contains("api_key") or lower.contains("token")
