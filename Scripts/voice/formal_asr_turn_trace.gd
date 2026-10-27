extends RefCounted
class_name FormalAsrTurnTrace

## Phase4-D.1：正式流式 ASR 低噪声追踪（YOUYOU_FORMAL_ASR_TRACE=1）。

static var _enabled := false
static var _t0_usec: int = -1


static func refresh_from_env() -> void:
	var v := OS.get_environment("YOUYOU_FORMAL_ASR_TRACE").strip_edges().to_lower()
	_enabled = v in ["1", "true", "yes", "on"]


static func reset_anchor() -> void:
	_t0_usec = Time.get_ticks_usec()


static func log(event: String, fields: Dictionary = {}) -> void:
	if not _enabled:
		return
	if _t0_usec < 0:
		reset_anchor()
	var parts: PackedStringArray = PackedStringArray()
	parts.append("formal_asr_trace")
	parts.append("event=%s" % event)
	parts.append("t_ms=%.2f" % (float(Time.get_ticks_usec() - _t0_usec) / 1000.0))
	for k in fields.keys():
		var val = fields[k]
		if val is String and _looks_sensitive(str(val)):
			continue
		parts.append("%s=%s" % [str(k), str(val)])
	print(" ".join(parts))


static func _looks_sensitive(raw: String) -> bool:
	var lower := raw.to_lower()
	return lower.contains("token") or lower.contains("appkey") or lower.contains("sk-")
