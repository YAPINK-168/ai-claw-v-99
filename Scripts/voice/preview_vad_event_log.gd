extends RefCounted
class_name PreviewVadEventLog

## 正式场景 VAD/采集观测环形日志（不改变 VAD 判定，仅记录）。

const MAX_EVENTS := 16

static var _events: Array[Dictionary] = []


static func push(event: String, fields: Dictionary = {}) -> void:
	var row: Dictionary = fields.duplicate(true)
	row["event"] = event
	row["t_msec"] = Time.get_ticks_msec()
	_events.append(row)
	while _events.size() > MAX_EVENTS:
		_events.pop_front()


static func clear() -> void:
	_events.clear()


static func get_events() -> Array[Dictionary]:
	return _events.duplicate(true)


static func last_event() -> Dictionary:
	if _events.is_empty():
		return {}
	return _events[_events.size() - 1].duplicate(true)


static func format_last_brief() -> String:
	var row := last_event()
	if row.is_empty():
		return "-"
	var parts: PackedStringArray = PackedStringArray()
	parts.append(String(row.get("event", "?")))
	if row.has("perf_state"):
		parts.append("perf=%s" % String(row.get("perf_state", "")))
	if row.has("peak"):
		parts.append("peak=%.4f" % float(row.get("peak", 0.0)))
	if row.has("duration_sec"):
		parts.append("dur=%.2fs" % float(row.get("duration_sec", 0.0)))
	if row.has("reason"):
		parts.append("reason=%s" % String(row.get("reason", "")))
	if row.has("paused"):
		parts.append("paused=%s" % str(row.get("paused", false)))
	if row.has("precoin_play"):
		parts.append(String(row.get("precoin_play", "")))
	return " ".join(parts)
