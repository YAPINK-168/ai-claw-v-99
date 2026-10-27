class_name VoiceTurnLatency
extends RefCounted

## 全链路耗时（Time.get_ticks_usec 单调时钟）。未发生的阶段在报告中为 null，不用 0 冒充。

const VoicePipelineBaselineStatsScript := preload("res://Scripts/voice/voice_pipeline_baseline_stats.gd")

const HISTORY_MAX := 32

var enabled: bool = false

var turn_id: int = 0
var _path: String = ""
var _outcome: String = "idle"
var _marks: Dictionary = {}
var _tts_segments: Array[Dictionary] = []
var _current_tts_chunk: int = -1

static var _seq: int = 0
static var _history: Array[Dictionary] = []

## 最近一次 abort 的一行摘要（供 [AI-VAD] / 面板）。
static var _last_abort_summary: String = ""

const _PIPELINE_STAGES: Array[Dictionary] = [
	{
		"id": "vad",
		"label": "VAD/PCM",
		"start_marks": ["vad_start"],
		"end_marks": ["vad_end"],
		"extra_marks": ["pcm_ready"],
	},
	{
		"id": "asr_token",
		"label": "ASR Token",
		"start_marks": ["asr_token_start"],
		"end_marks": ["asr_start"],
		"extra_marks": [],
	},
	{
		"id": "asr",
		"label": "ASR HTTP",
		"start_marks": ["asr_start"],
		"end_marks": ["asr_end"],
		"extra_marks": [],
	},
	{
		"id": "llm",
		"label": "LLM",
		"start_marks": ["llm_start"],
		"end_marks": ["llm_end"],
		"extra_marks": ["llm_first_token"],
	},
	{
		"id": "tts",
		"label": "TTS",
		"start_marks": ["tts_start"],
		"end_marks": ["tts_first_audio_ready", "tts_all_ready"],
		"extra_marks": ["tts_http_start", "tts_http_done", "tts_download_start"],
	},
	{
		"id": "playback",
		"label": "Playback",
		"start_marks": ["playback_start"],
		"end_marks": ["playback_end"],
		"extra_marks": ["tts_decode_start"],
	},
]


func start_turn(path: String) -> void:
	if not enabled:
		return
	_seq += 1
	turn_id = _seq
	_path = path
	_outcome = "running"
	_marks.clear()
	_tts_segments.clear()
	_current_tts_chunk = -1


func mark_once(event: String) -> void:
	if not enabled:
		return
	if _marks.has(event):
		return
	_marks[event] = Time.get_ticks_usec()


func mark_end(event: String) -> void:
	if not enabled:
		return
	_marks[event] = Time.get_ticks_usec()


func has_mark(event: String) -> bool:
	return _marks.has(event)


func set_tts_chunk_index(index: int) -> void:
	if not enabled:
		return
	_current_tts_chunk = index


func notify_tts_http_span(http_ms: float) -> void:
	if not enabled or _current_tts_chunk < 0:
		return
	_ensure_segment(_current_tts_chunk)
	var seg: Dictionary = _tts_segments[_current_tts_chunk]
	seg["http_ms"] = http_ms


func notify_tts_segment_bytes(byte_size: int) -> void:
	if not enabled or _current_tts_chunk < 0:
		return
	_ensure_segment(_current_tts_chunk)
	var seg: Dictionary = _tts_segments[_current_tts_chunk]
	seg["bytes"] = byte_size


func close_open_stages() -> void:
	if not enabled:
		return
	if has_mark("asr_start") and not has_mark("asr_end"):
		mark_end("asr_end")
	if has_mark("llm_start") and not has_mark("llm_end"):
		mark_end("llm_end")
	if has_mark("tts_start") and not has_mark("tts_all_ready"):
		mark_end("tts_all_ready")


func get_path_name() -> String:
	return _path


func is_turn_running() -> bool:
	return enabled and _outcome == "running"


func abort_turn(outcome: String = "aborted", context: Dictionary = {}) -> void:
	if not enabled or _outcome != "running":
		return
	var diagnosis := _build_abort_diagnosis(outcome, context)
	_last_abort_summary = String(diagnosis.get("summary_line", ""))
	close_open_stages()
	_outcome = outcome
	mark_end("turn_end")
	VoicePipelineBaselineStatsScript.record_turn_outcome(outcome)
	print("voice_latency_abort turn_id=%d outcome=%s" % [turn_id, outcome])
	_print_abort_diagnosis(diagnosis)


static func get_last_abort_summary() -> String:
	return _last_abort_summary


static func clear_last_abort_summary() -> void:
	_last_abort_summary = ""


func finish(outcome: String, record_history: bool = true) -> void:
	if not enabled:
		return
	close_open_stages()
	_outcome = outcome
	mark_end("turn_end")
	var report := build_report()
	VoicePipelineBaselineStatsScript.record_turn_outcome(outcome)
	if record_history:
		_history.append(report)
		while _history.size() > HISTORY_MAX:
			_history.pop_front()
	_print_round(report)


func build_report() -> Dictionary:
	var input_end := _pick_input_end_event()
	var r := {
		"turn_id": turn_id,
		"path": _path,
		"outcome": _outcome,
		"events": _marks.duplicate(),
		"tts_segments": _tts_segments.duplicate(true),
	}
	r["asr_ms"] = _delta("asr_start", "asr_end")
	r["llm_ms"] = _delta("llm_start", "llm_end")
	r["tts_first_http_ms"] = _delta("tts_http_start", "tts_http_done")
	r["tts_first_download_ms"] = _delta("tts_download_start", "tts_first_audio_ready")
	r["tts_first_ready_ms"] = _delta("tts_start", "tts_first_audio_ready")
	r["decode_to_play_ms"] = _delta("tts_decode_start", "playback_start")
	r["ptt_end_to_play_ms"] = _delta(input_end, "playback_start")
	r["ptt_end_to_playback_end_ms"] = _delta(input_end, "playback_end")
	r["turn_total_ms"] = _delta(_turn_start_event(), "turn_end")
	r["tts_all_synth_ms"] = _delta("tts_start", "tts_all_ready")
	r["asr_token_ms"] = _delta("asr_token_start", "asr_start")
	r["vad_end_to_asr_end_ms"] = _delta("vad_end", "asr_end")
	r["asr_end_to_llm_end_ms"] = _delta("asr_end", "llm_end")
	r["llm_end_to_tts_first_ready_ms"] = _delta("llm_end", "tts_first_audio_ready")
	r["tts_first_ready_to_playback_ms"] = _delta("tts_first_audio_ready", "playback_start")
	r["vad_end_to_playback_ms"] = _delta("vad_end", "playback_start")
	# 讲话段 VAD 起点→终点（含起说检测与尾静音判定），不是单独的「尾静音延迟」。
	r["vad_wait_ms"] = _delta("vad_start", "vad_end")
	r["llm_first_token_ms"] = _delta("llm_start", "llm_first_token")
	r["llm_first_token_to_end_ms"] = _delta("llm_first_token", "llm_end")
	# 兼容旧字段名
	r["release_to_play_ms"] = r["ptt_end_to_play_ms"]
	r["tts_first_chunk_ms"] = r["tts_first_ready_ms"]
	r["tts_http_ms"] = r["tts_first_http_ms"]
	r["tts_download_ms"] = r["tts_first_download_ms"]
	return r


static func get_history() -> Array[Dictionary]:
	return _history.duplicate(true)


static func get_recent_averages(last_n: int = 5) -> Dictionary:
	var n := mini(maxi(last_n, 1), _history.size())
	if n == 0:
		return {}
	var start := _history.size() - n
	var keys := [
		"asr_ms",
		"llm_ms",
		"tts_first_ready_ms",
		"ptt_end_to_play_ms",
		"ptt_end_to_playback_end_ms",
	]
	var sums: Dictionary = {}
	var counts: Dictionary = {}
	for k in keys:
		sums[k] = 0.0
		counts[k] = 0
	for i in range(start, _history.size()):
		var row: Dictionary = _history[i]
		for k in keys:
			var v: Variant = row.get(k)
			if v == null:
				continue
			var f := float(v)
			if f >= 0.0:
				sums[k] += f
				counts[k] += 1
	var avg: Dictionary = {}
	for k in keys:
		var c: int = int(counts[k])
		if c > 0:
			avg[k] = float(sums[k]) / float(c)
	return avg


static func clear_history() -> void:
	_history.clear()


static func format_summary_line(report: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append("id=%d" % int(report.get("turn_id", 0)))
	parts.append(str(report.get("path", "")))
	parts.append(str(report.get("outcome", "")))
	for key in ["ptt_end_to_play_ms", "asr_ms", "llm_ms", "tts_first_ready_ms", "turn_total_ms"]:
		var v: Variant = report.get(key)
		if v == null:
			parts.append("%s=—" % key)
		else:
			var f := float(v)
			if f >= 0.0:
				parts.append("%s=%.0fms" % [key, f])
			else:
				parts.append("%s=—" % key)
	return " ".join(parts)


static func print_aggregate() -> void:
	if _history.is_empty():
		print("voice_latency_aggregate rounds=0")
		return
	var avg := get_recent_averages(_history.size())
	print("voice_latency_aggregate rounds=", _history.size())
	for k in avg.keys():
		print("  avg_%s=%.1fms" % [k, float(avg[k])])
	for row in _history:
		print("  ", format_summary_line(row))


func _turn_start_event() -> String:
	if _path == "ptt":
		return "ptt_start" if _marks.has("ptt_start") else "ptt_end"
	if _path == "continuous":
		return "vad_start" if _marks.has("vad_start") else "vad_end"
	return "text_submit"


func _pick_input_end_event() -> String:
	if _marks.has("vad_end"):
		return "vad_end"
	if _marks.has("ptt_end"):
		return "ptt_end"
	if _marks.has("text_submit"):
		return "text_submit"
	return ""


func _delta(from_event: String, to_event: String) -> Variant:
	if from_event.is_empty() or not _marks.has(from_event) or not _marks.has(to_event):
		return null
	return float(int(_marks[to_event]) - int(_marks[from_event])) / 1000.0


func _anchor_usec() -> int:
	var anchor_ev := _turn_start_event()
	if not anchor_ev.is_empty() and _marks.has(anchor_ev):
		return int(_marks[anchor_ev])
	var earliest := -1
	for key in _marks.keys():
		var t := int(_marks[key])
		if earliest < 0 or t < earliest:
			earliest = t
	return maxi(earliest, 0)


func _mark_offset_ms(event: String) -> Variant:
	if not _marks.has(event):
		return null
	var anchor := _anchor_usec()
	if anchor <= 0:
		return null
	return float(int(_marks[event]) - anchor) / 1000.0


func _stage_has_any_mark(def: Dictionary, which: String) -> bool:
	var keys: Array = def.get(which, [])
	for k in keys:
		if _marks.has(String(k)):
			return true
	return false


func _stage_status(def: Dictionary) -> String:
	var started := _stage_has_any_mark(def, "start_marks") or _stage_has_any_mark(def, "extra_marks")
	if not started:
		return "not_started"
	var end_marks: Array = def.get("end_marks", [])
	for em in end_marks:
		if _marks.has(String(em)):
			return "completed"
	if _stage_has_any_mark(def, "start_marks"):
		return "started_incomplete"
	return "partial"


func _build_abort_diagnosis(outcome: String, context: Dictionary) -> Dictionary:
	var stage_lines: PackedStringArray = PackedStringArray()
	var last_completed := ""
	var open_stages: PackedStringArray = PackedStringArray()
	for def in _PIPELINE_STAGES:
		var st := _stage_status(def)
		var sid := String(def.get("id", ""))
		var label := String(def.get("label", sid))
		stage_lines.append("%s=%s" % [sid, st])
		if st == "completed":
			last_completed = sid
		elif st == "started_incomplete" or st == "partial":
			open_stages.append("%s(%s)" % [label, st])
	var mark_parts: PackedStringArray = PackedStringArray()
	var sorted_keys: Array = _marks.keys()
	sorted_keys.sort_custom(func(a, b): return int(_marks[a]) < int(_marks[b]))
	for key in sorted_keys:
		var off: Variant = _mark_offset_ms(String(key))
		if off == null:
			mark_parts.append("%s=?" % key)
		else:
			mark_parts.append("%s=%.1fms" % [key, float(off)])
	var cancel_reason := String(context.get("cancel_reason", outcome))
	var voice_state := String(context.get("voice_state", ""))
	if voice_state.is_empty():
		voice_state = "unknown"
	var perf_state := String(context.get("perf_state", ""))
	if perf_state.is_empty():
		perf_state = "unknown"
	var asr_err := _format_optional_error(context.get("asr_last_error", null))
	var voice_err := _format_optional_error(context.get("voice_last_error", null))
	var open_hint := "none"
	if not open_stages.is_empty():
		open_hint = ", ".join(open_stages)
	var summary := (
		"cancel=%s last_done=%s open=%s voice=%s perf=%s"
		% [
			cancel_reason,
			last_completed if last_completed != "" else "none",
			open_hint,
			voice_state,
			perf_state,
		]
	)
	return {
		"turn_id": turn_id,
		"path": _path,
		"outcome": outcome,
		"cancel_reason": cancel_reason,
		"stage_status": " | ".join(stage_lines),
		"last_completed_stage": last_completed,
		"open_stages": open_stages,
		"marks_line": " ".join(mark_parts),
		"voice_state": voice_state,
		"perf_state": perf_state,
		"utterance_busy": context.get("utterance_busy", null),
		"session_active": context.get("session_active", null),
		"asr_last_error": asr_err,
		"voice_last_error": voice_err,
		"summary_line": summary,
	}


func _format_optional_error(raw: Variant) -> String:
	if raw == null:
		return "(unknown)"
	var s := str(raw).strip_edges()
	if s.is_empty():
		return "(empty)"
	return s


func _print_abort_diagnosis(diag: Dictionary) -> void:
	print(
		"voice_latency_abort_diag turn_id=%d path=%s cancel_reason=%s"
		% [diag.get("turn_id", 0), diag.get("path", ""), diag.get("cancel_reason", "")]
	)
	print("  stages: %s" % diag.get("stage_status", ""))
	print("  last_completed: %s" % diag.get("last_completed_stage", ""))
	var open: Variant = diag.get("open_stages", [])
	if typeof(open) == TYPE_ARRAY and not (open as Array).is_empty():
		print("  open_stages: %s" % ", ".join(open))
	else:
		print("  open_stages: none")
	var marks_line := String(diag.get("marks_line", ""))
	if marks_line.is_empty():
		print("  marks: (none recorded)")
	else:
		print("  marks: %s" % marks_line)
	print(
		"  runtime: voice_state=%s perf_state=%s utterance_busy=%s session_active=%s"
		% [
			diag.get("voice_state", "unknown"),
			diag.get("perf_state", "unknown"),
			str(diag.get("utterance_busy", "?")),
			str(diag.get("session_active", "?")),
		]
	)
	print("  asr_last_error=%s voice_last_error=%s" % [diag.get("asr_last_error", ""), diag.get("voice_last_error", "")])


func _ensure_segment(index: int) -> void:
	while _tts_segments.size() <= index:
		_tts_segments.append({"index": _tts_segments.size(), "http_ms": null, "bytes": 0})


func _print_round(r: Dictionary) -> void:
	print(
		"voice_latency_round turn_id=%d path=%s outcome=%s"
		% [r.get("turn_id", 0), r.get("path", ""), r.get("outcome", "")]
	)
	var line := static_format_metrics(r)
	if not line.is_empty():
		print("  ", line)
	var segs: Variant = r.get("tts_segments", [])
	if typeof(segs) == TYPE_ARRAY and (segs as Array).size() > 1:
		print("  tts_segments=", segs)


static func _format_metric_field(r: Dictionary, key: String) -> String:
	var v: Variant = r.get(key)
	if v == null:
		return "%s=—" % key
	var f := float(v)
	if f < 0.0:
		return "%s=—" % key
	return "%s=%.1fms" % [key, f]


static func static_format_metrics(r: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	var path := str(r.get("path", ""))
	if path == "continuous":
		for key in [
			"vad_end_to_asr_end_ms",
			"asr_end_to_llm_end_ms",
			"llm_end_to_tts_first_ready_ms",
			"tts_first_ready_to_playback_ms",
			"vad_end_to_playback_ms",
			"turn_total_ms",
		]:
			parts.append(_format_metric_field(r, key))
		for key in [
			"vad_wait_ms",
			"asr_token_ms",
			"asr_ms",
			"llm_first_token_ms",
			"llm_ms",
			"tts_first_http_ms",
			"tts_first_download_ms",
			"decode_to_play_ms",
		]:
			parts.append(_format_metric_field(r, key))
		return " | ".join(parts)
	for key in [
		"ptt_end_to_play_ms",
		"asr_ms",
		"llm_ms",
		"tts_first_ready_ms",
		"tts_first_http_ms",
		"tts_first_download_ms",
		"decode_to_play_ms",
		"ptt_end_to_playback_end_ms",
		"turn_total_ms",
	]:
		var v: Variant = r.get(key)
		if v == null:
			continue
		var f := float(v)
		if f >= 0.0:
			parts.append("%s=%.1fms" % [key, f])
	return " | ".join(parts)


## 兼容旧调用
func begin_turn(path: String) -> void:
	start_turn(path)
	if path == "text":
		mark_once("text_submit")
	elif path == "ptt":
		mark_once("ptt_end")


func mark(event: String) -> void:
	match event:
		"asr_done":
			mark_end("asr_end")
		"llm_done":
			mark_end("llm_end")
		"tts_playback_start":
			mark_once("playback_start")
		"release_submit":
			mark_once("text_submit")
		_:
			mark_once(event)
