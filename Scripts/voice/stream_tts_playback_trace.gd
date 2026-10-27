class_name StreamTtsPlaybackTrace
extends RefCounted

## Phase3-C2.1：流式 TTS 首播分段计时（Time.get_ticks_usec 单调时钟）。

var _origin_us: int = 0
var _marks: Dictionary = {}


func begin() -> void:
	_origin_us = Time.get_ticks_usec()
	_marks.clear()
	mark("speak_start")


func mark(event: String) -> void:
	if _origin_us <= 0:
		_origin_us = Time.get_ticks_usec()
	if _marks.has(event):
		return
	_marks[event] = Time.get_ticks_usec()


func has(event: String) -> bool:
	return _marks.has(event)


func offset_ms(event: String) -> Variant:
	if not _marks.has(event):
		return null
	return float(int(_marks[event]) - _origin_us) / 1000.0


func span_ms(start_event: String, end_event: String) -> Variant:
	if not _marks.has(start_event) or not _marks.has(end_event):
		return null
	return float(int(_marks[end_event]) - int(_marks[start_event])) / 1000.0


func to_dictionary() -> Dictionary:
	var out := {}
	for k in _marks.keys():
		out[k] = offset_ms(str(k))
	return out


func report_line() -> String:
	var parts: PackedStringArray = PackedStringArray()
	var order := [
		"speak_start",
		"ws_connect_start",
		"ws_connected",
		"task_started",
		"continue_task_sent",
		"first_pcm_received",
		"startup_buffer_ready",
		"generator_play_called",
		"first_pcm_pushed",
		"playback_start_hook",
	]
	for ev in order:
		var ms: Variant = offset_ms(ev)
		if ms != null:
			parts.append("%s=%.1fms" % [ev, float(ms)])
	return "stream_tts_trace " + ", ".join(parts)
