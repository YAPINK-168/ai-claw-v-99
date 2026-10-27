extends Node
class_name YouyouClawShowAdapter

## 业务 ShowPort 语义 → 正式场景事件表现（不直接加载 GLB/MP3）。

signal show_finished(token: int)
signal show_failed(token: int)
signal welcome_finished

const MAP_PATH := "res://config/youyou_claw_show_map.json"

var _event_perf: YouyouEventActionPerformance
var _host: Node
var _wait_token := -1
var _held_opening_token := -1
var _last_action := ""
var _last_speech := ""


func setup(event_performance: YouyouEventActionPerformance, host: Node = null) -> void:
	_event_perf = event_performance
	_host = host
	if not _event_perf.performance_finished.is_connected(_on_performance_finished):
		_event_perf.performance_finished.connect(_on_performance_finished)
	if not _event_perf.performance_failed.is_connected(_on_performance_failed):
		_event_perf.performance_failed.connect(_on_performance_failed)


func play(action_id: String, speech_id: String, token: int, wait_for_it: bool = false) -> void:
	_last_action = action_id
	_last_speech = speech_id
	if action_id == "opening" and _host != null and _host.has_method("begin_coin_welcome"):
		_host.begin_coin_welcome(token, speech_id)
		return
	if action_id == "paid_observe" and _host != null and _host.has_method("begin_paid_observe"):
		_held_opening_token = token
		_wait_token = -1
		var started := true
		if _host.has_method("begin_paid_observe"):
			started = bool(_host.begin_paid_observe(token))
		if not started:
			fail_opening()
		return
	if action_id == "success_continue_guide" and _host != null and _host.has_method("begin_success_continue_guide"):
		_wait_token = token
		if not bool(_host.begin_success_continue_guide(token)):
			_wait_token = -1
			call_deferred("_emit_failed", token)
		return
	if action_id == "fail_continue_guide" and _host != null and _host.has_method("begin_fail_continue_guide"):
		_wait_token = token
		if not bool(_host.begin_fail_continue_guide(token)):
			_wait_token = -1
			call_deferred("_emit_failed", token)
		return
	if _dispatch_pose(action_id):
		return
	if (
		action_id == "invite_minigame"
		and wait_for_it
		and _host != null
		and _host.has_method("begin_minigame_invite")
	):
		_wait_token = token
		_host.begin_minigame_invite(token)
		return
	if action_id == "attract" or action_id == "idle_base" or action_id == "replay_wait":
		if _host != null and _host.has_method("on_show_presence_request"):
			_host.on_show_presence_request(action_id)
	var mapping := _resolve_mapping(action_id, speech_id)
	if mapping.is_empty():
		push_warning("Show 映射缺失：action=%s speech=%s" % [action_id, speech_id])
		if wait_for_it:
			call_deferred("_emit_done", token)
		return
	var event_id := String(mapping.get("event_action_id", ""))
	var status := String(mapping.get("binding_status", ""))
	if event_id == "" or status != "confirmed":
		if wait_for_it:
			call_deferred("_emit_done", token)
		return
	if _event_perf == null:
		push_error("事件表现节点未 setup")
		if wait_for_it:
			call_deferred("_emit_failed", token)
		return
	if wait_for_it:
		_wait_token = token
	_prepare_host()
	if not _event_perf.play_event(event_id, token):
		return
	if not wait_for_it:
		call_deferred("_emit_done", token)


func complete_minigame_invite(token: int) -> void:
	if _wait_token >= 0 and token == _wait_token:
		var t := _wait_token
		_wait_token = -1
		show_finished.emit(t)


func fail_minigame_invite(token: int) -> void:
	if _wait_token >= 0 and token == _wait_token:
		var t := _wait_token
		_wait_token = -1
		show_failed.emit(t)


func complete_opening() -> void:
	if _held_opening_token < 0:
		return
	var token := _held_opening_token
	_held_opening_token = -1
	show_finished.emit(token)


func fail_opening() -> void:
	if _held_opening_token < 0:
		return
	var token := _held_opening_token
	_held_opening_token = -1
	show_failed.emit(token)


func notify_welcome_finished() -> void:
	welcome_finished.emit()


func _dispatch_pose(action_id: String) -> bool:
	if _host == null:
		return false
	if action_id == "operating" and _host.has_method("begin_operate_hold"):
		_host.begin_operate_hold()
		return true
	if action_id == "grabbing" and _host.has_method("begin_deeper_crouch"):
		_host.begin_deeper_crouch()
		return true
	return false


func play_action(action_id: String, token: int) -> void:
	play(action_id, "", token, false)


func play_speech(speech_id: String, token: int) -> void:
	play("", speech_id, token, false)


func play_event_by_id(event_action_id: String, token: int, wait_for_it: bool = false) -> void:
	_last_action = ""
	_last_speech = ""
	if _event_perf == null:
		if wait_for_it:
			call_deferred("_emit_failed", token)
		return
	if wait_for_it:
		_wait_token = token
	_prepare_host()
	if not _event_perf.play_event(event_action_id, token):
		return
	if not wait_for_it:
		call_deferred("_emit_done", token)


func _on_performance_finished(token: int, _action_id: String, _reason: String) -> void:
	if _wait_token >= 0 and token == _wait_token:
		var t := _wait_token
		_wait_token = -1
		show_finished.emit(t)


func _on_performance_failed(token: int, action_id: String, code: String, message: String) -> void:
	push_warning("Show 事件播放失败 %s [%s]: %s" % [action_id, code, message])
	if _wait_token >= 0 and token == _wait_token:
		var t := _wait_token
		_wait_token = -1
		show_failed.emit(t)


func _emit_failed(token: int) -> void:
	if is_inside_tree():
		show_failed.emit(token)


func _prepare_host() -> void:
	if _host != null and _host.has_method("halt_stale_invite_for_show"):
		_host.halt_stale_invite_for_show()
	if _host != null and _host.has_method("prepare_business_event_from_show"):
		_host.prepare_business_event_from_show()
	elif _host != null and _host.has_method("prepare_business_event"):
		_host.prepare_business_event()


func _emit_done(token: int) -> void:
	if is_inside_tree():
		show_finished.emit(token)


func _resolve_mapping(action_id: String, speech_id: String) -> Dictionary:
	var mappings := _load_mappings()
	for item in mappings:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var m: Dictionary = item
		if String(m.get("business_action", "")) != action_id:
			continue
		if String(m.get("business_speech", "")) != speech_id:
			continue
		return m
	return {}


func _load_mappings() -> Array:
	if not ResExists.path(MAP_PATH):
		push_error("Show 映射缺失：" + MAP_PATH)
		return []
	var file := FileAccess.open(MAP_PATH, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var raw: Variant = parsed.get("mappings", [])
	if typeof(raw) != TYPE_ARRAY:
		return []
	return raw
