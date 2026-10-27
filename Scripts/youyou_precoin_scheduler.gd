extends Node
class_name YouyouPrecoinScheduler

## 投币前唯一待机调度器。
## 只决定下一段播什么，播放、配音、表情和业务状态机仍走现有模块。
## 同一时间只有一个身体主动作；完成回调带会话，过期通知只记一次。

const IDLE_DWELL_MIN := 2.0
const IDLE_DWELL_MAX := 4.0
const ATTRACT_DWELL_MIN := 0.9
const ATTRACT_DWELL_MAX := 1.7
const BLEND_IN_LIGHT := 0.25
const BLEND_IN_ATTRACT := 0.25
const BLEND_OUT_LIGHT := 0.30
const BLEND_OUT_ATTRACT := 0.30

enum TargetMode { IDLE, ATTRACT, BUSINESS }
enum Phase { DWELL, ACTION, BLEND, BUSINESS, SUSPENDED }

var _host: Node
var _entries: Array = []
var _timer: Timer
var _enabled := false
var _suspended := false
var _business := false
var _from_show := false
var _yield_on_finish := false
var _player_present := false
var _target := TargetMode.IDLE
var _phase := Phase.DWELL
var _current_action_id := ""
var _current_kind := ""
var _last_action_id := ""
var _skip_pick_id := ""
var _transitioning := false
var _action_playing := false
var _pending_switch := false
var _session := 0
var _finish_consumed := true
var _rejected_action_id := ""
var _stale_logged := false
var _limit_logged := {}
var _dwell_idle_min := IDLE_DWELL_MIN
var _dwell_idle_max := IDLE_DWELL_MAX
var _dwell_attract_min := ATTRACT_DWELL_MIN
var _dwell_attract_max := ATTRACT_DWELL_MAX
var _blend_in_light := BLEND_IN_LIGHT
var _blend_in_attract := BLEND_IN_ATTRACT
var _blend_out_light := BLEND_OUT_LIGHT
var _blend_out_attract := BLEND_OUT_ATTRACT
var _trace: PackedStringArray = []


func setup(host: Node, entries: Array, blends: Dictionary = {}) -> void:
	_host = host
	_entries = entries.duplicate(true)
	if blends.has("to_light"):
		_blend_in_light = float(blends["to_light"])
	if blends.has("to_attract"):
		_blend_in_attract = float(blends["to_attract"])
	if blends.has("light_to_base"):
		_blend_out_light = float(blends["light_to_base"])
	if blends.has("attract_to_base"):
		_blend_out_attract = float(blends["attract_to_base"])
	if _timer == null:
		_timer = Timer.new()
		_timer.name = "PrecoinSchedule"
		_timer.one_shot = true
		_timer.timeout.connect(_on_timer)
		add_child(_timer)


func configure_dwells(idle_min: float, idle_max: float, attract_min: float, attract_max: float) -> void:
	_dwell_idle_min = idle_min
	_dwell_idle_max = maxf(idle_max, idle_min)
	_dwell_attract_min = attract_min
	_dwell_attract_max = maxf(attract_max, attract_min)


func start() -> void:
	randomize()
	_enabled = true
	_suspended = false
	_business = false
	_player_present = false
	_skip_pick_id = ""
	_target = TargetMode.IDLE
	_phase = Phase.DWELL
	_current_action_id = ""
	_current_kind = "base"
	_action_playing = false
	_transitioning = false
	_pending_switch = false
	_log("玩家=离开 模式=IDLE 当前动作=Basic_Idle 初始基础待机")
	_report_pools()
	_arm_dwell()


func interrupt_current_action_for_voice() -> void:
	if not _enabled or _business:
		return
	_mark_rejected_if_acting()
	_transitioning = false
	_action_playing = false
	_finish_consumed = true
	_session += 1
	_phase = Phase.DWELL
	_stop_timer()
	if _host != null and _host.has_method("precoin_ensure_base_idle"):
		_host.precoin_ensure_base_idle()
	_pending_switch = true
	_arm_dwell()


func nudge_attract_after_voice_turn() -> void:
	if not _enabled or _business or not _player_present or _target != TargetMode.ATTRACT:
		return
	if _phase == Phase.ACTION or _phase == Phase.BLEND:
		_pending_switch = true
		return
	_pending_switch = true
	if _phase == Phase.DWELL:
		_arm_dwell()


func set_player_present(present: bool) -> void:
	if not _enabled:
		return
	if _business:
		_log("业务接管中，忽略待机请求")
		return
	if present:
		if _player_present and _target == TargetMode.ATTRACT:
			_log("玩家=在场 模式=ATTRACT 当前动作=%s 重复进入，忽略" % _display_action())
			return
		_player_present = true
		_target = TargetMode.ATTRACT
		_pending_switch = true
		_log("玩家=在场 模式=ATTRACT 当前动作=%s" % _display_action())
		if _phase == Phase.ACTION or _phase == Phase.BLEND:
			return
		if _phase == Phase.DWELL:
			_arm_dwell()
		return
	if not _player_present and _target == TargetMode.IDLE:
		_log("玩家=离开 模式=IDLE 当前动作=%s 重复离开，忽略" % _display_action())
		return
	_player_present = false
	_target = TargetMode.IDLE
	_pending_switch = true
	_log("玩家=离开 模式=IDLE 当前动作=%s" % _display_action())
	if _phase == Phase.ACTION or _phase == Phase.BLEND:
		return
	if _phase == Phase.DWELL:
		_arm_dwell()


func begin_handoff() -> String:
	_business = true
	_enabled = true
	_target = TargetMode.BUSINESS
	_pending_switch = false
	_stop_timer()
	var interrupt_id := ""
	if _phase == Phase.ACTION and _action_playing and not _finish_consumed:
		interrupt_id = _current_action_id
	elif _phase == Phase.BLEND and _current_action_id != "":
		interrupt_id = _current_action_id
	if interrupt_id != "":
		_mark_rejected_if_acting()
		if _host != null and _host.has_method("precoin_abort_for_coin"):
			_host.precoin_abort_for_coin(interrupt_id)
		_transitioning = false
		_action_playing = false
		_finish_consumed = true
		_phase = Phase.BUSINESS
		_session += 1
		_yield_on_finish = false
		_log("投币打断当前表现 id=%s" % interrupt_id)
		return ""
	var taken := _display_action()
	_mark_rejected_if_acting()
	_transitioning = false
	_action_playing = false
	_phase = Phase.BUSINESS
	_finish_consumed = true
	_session += 1
	_yield_on_finish = false
	_log("业务接管 模式=BUSINESS 当前动作=%s" % taken)
	return ""


func is_yielding() -> bool:
	return _yield_on_finish


func enter_business(from_show: bool) -> void:
	_from_show = from_show
	_business = true
	_enabled = true
	_target = TargetMode.BUSINESS
	_pending_switch = false
	_stop_timer()
	var taken := _display_action()
	_mark_rejected_if_acting()
	_transitioning = false
	_action_playing = false
	_phase = Phase.BUSINESS
	_finish_consumed = true
	_session += 1
	_log("业务接管 模式=BUSINESS 当前动作=%s" % taken)


func resume_after_preview_package() -> void:
	if _from_show or not _business:
		return
	_business = false
	_suspended = false
	_target = TargetMode.ATTRACT if _player_present else TargetMode.IDLE
	_phase = Phase.DWELL
	_action_playing = false
	_transitioning = false
	_current_action_id = ""
	_current_kind = "base"
	_log("玩家=%s 模式=%s 当前动作=Basic_Idle 预览业务包结束，恢复投币前调度" % [_presence_text(), _mode_name()])
	_arm_dwell()


func release_to_presence(present: bool) -> void:
	if _business:
		_business = false
		_suspended = false
		_from_show = false
		_player_present = present
		_target = TargetMode.ATTRACT if present else TargetMode.IDLE
		_pending_switch = false
		_phase = Phase.DWELL
		_action_playing = false
		_transitioning = false
		_current_action_id = ""
		_current_kind = "base"
		_rejected_action_id = ""
		_log("玩家=%s 模式=%s 当前动作=Basic_Idle 业务交还" % [_presence_text(), _mode_name()])
		if _host != null and _host.has_method("precoin_ensure_base_idle"):
			_host.precoin_ensure_base_idle()
		_arm_dwell()
		return
	set_player_present(present)


func suspend_for_manual() -> void:
	if _business:
		return
	_suspended = true
	_stop_timer()
	_mark_rejected_if_acting()
	_phase = Phase.SUSPENDED
	_action_playing = false
	_transitioning = false
	_finish_consumed = true
	_session += 1


func resume_after_manual() -> void:
	if _business:
		_log("业务接管中，忽略恢复待机")
		return
	if not _suspended and _phase == Phase.DWELL and not _transitioning:
		_log("玩家=%s 模式=%s 当前动作=Basic_Idle 自动待机已在进行" % [_presence_text(), _mode_name()])
		return
	_suspended = false
	if _phase == Phase.ACTION:
		_mark_rejected_if_acting()
	_phase = Phase.DWELL
	_action_playing = false
	_transitioning = false
	_finish_consumed = true
	_session += 1
	_current_action_id = ""
	_current_kind = "base"
	_log("玩家=%s 模式=%s 当前动作=Basic_Idle" % [_presence_text(), _mode_name()])
	_arm_dwell()


func notify_animation_finished(anim_name: String) -> bool:
	if _rejected_action_id != "" and anim_name == _rejected_action_id and _phase != Phase.ACTION:
		if not _stale_logged:
			_stale_logged = true
			_log("过期回调被忽略")
		return false
	if _phase != Phase.ACTION or _finish_consumed or anim_name != _current_action_id:
		return false
	_finish_consumed = true
	_action_playing = false
	_last_action_id = _current_action_id
	_log("动作结束 id=%s 类型=%s" % [_current_action_id, _kind_label(_current_kind)])
	if _yield_on_finish:
		_yield_on_finish = false
		_phase = Phase.BUSINESS
		_session += 1
		_log("业务交接完成 id=%s" % anim_name)
		if _host != null and _host.has_method("precoin_yield_finished"):
			_host.precoin_yield_finished(anim_name)
		return true
	_begin_transition()
	return true


func poll_playback(anim_name: String, playing: bool) -> void:
	if _phase != Phase.ACTION or _finish_consumed:
		return
	if playing or anim_name != _current_action_id:
		return
	notify_animation_finished(anim_name)


func debug_reject_current() -> void:
	_mark_rejected_if_acting()
	_phase = Phase.DWELL
	_action_playing = false
	_transitioning = false
	_finish_consumed = true
	_stop_timer()


func debug_decision(kinds: PackedStringArray, previous: String) -> Dictionary:
	return _decision(kinds, previous)


func is_business() -> bool:
	return _business


func is_player_present() -> bool:
	return _player_present


func is_action_playing() -> bool:
	return _action_playing and _phase == Phase.ACTION


func is_transitioning() -> bool:
	return _transitioning or _phase == Phase.BLEND


func is_suspended() -> bool:
	return _suspended


func is_idle_dwell() -> bool:
	return _phase == Phase.DWELL and not _action_playing and not _transitioning


func current_action_id() -> String:
	return _current_action_id


func current_kind() -> String:
	return _current_kind


func target_mode_name() -> String:
	return _mode_name()


func phase_name() -> String:
	match _phase:
		Phase.DWELL:
			return "DWELL"
		Phase.ACTION:
			return "ACTION"
		Phase.BLEND:
			return "BLEND"
		Phase.BUSINESS:
			return "BUSINESS"
		Phase.SUSPENDED:
			return "SUSPENDED"
	return ""


func count_kind(kind: String) -> int:
	var count := 0
	for entry in _entries:
		if String(entry.get("kind", "")) == kind:
			count += 1
	return count


func has_action(action_id: String) -> bool:
	for entry in _entries:
		if String(entry.get("id", "")) == action_id:
			return true
	return false


func trace_contains(fragment: String) -> bool:
	return _trace_has_from(0, fragment)


func trace_size() -> int:
	return _trace.size()


func trace_has_from(index: int, fragment: String) -> bool:
	return _trace_has_from(index, fragment)


func _trace_has_from(index: int, fragment: String) -> bool:
	var start := clampi(index, 0, _trace.size())
	for i in range(start, _trace.size()):
		if fragment in _trace[i]:
			return true
	return false


func _report_pools() -> void:
	var general := count_kind("general_light")
	var exclusive := count_kind("exclusive_light")
	var attract := count_kind("attract")
	_log("动作池 通用轻待机=%d 专属待机=%d 轻招揽=%d" % [general, exclusive, attract])
	if general == 0:
		_log("通用轻待机无已验收条目，待机池只使用角色专属待机。待确认通用轻待机动作 ID，未把未验收片段加入随机池")


func _arm_dwell() -> void:
	if not _enabled or _business or _suspended or _timer == null:
		return
	if _phase != Phase.DWELL:
		return
	_timer.stop()
	var span := _dwell_span()
	_timer.start(randf_range(span.x, span.y))


func _dwell_span() -> Vector2:
	if _target == TargetMode.ATTRACT:
		return Vector2(_dwell_attract_min, _dwell_attract_max)
	return Vector2(_dwell_idle_min, _dwell_idle_max)


func _on_timer() -> void:
	if not _enabled or _business or _suspended:
		return
	if _phase == Phase.BLEND:
		_transitioning = false
		_phase = Phase.DWELL
		_current_kind = "base"
		_pending_switch = false
		_log("过渡结束 玩家=%s 模式=%s 当前动作=Basic_Idle" % [_presence_text(), _mode_name()])
		_arm_dwell()
		return
	if _phase == Phase.DWELL:
		_try_play_next()


func _try_play_next() -> void:
	if _phase != Phase.DWELL or _transitioning or _action_playing or _business or _suspended:
		return
	var kinds := PackedStringArray(["attract"])
	if _target != TargetMode.ATTRACT:
		kinds = PackedStringArray(["general_light", "exclusive_light"])
	var decision := _decision(kinds, _last_action_id)
	var action_id := String(decision.get("id", ""))
	if action_id == "":
		var hold := String(decision.get("hold", ""))
		if hold == "single_or_empty":
			_log_once("hold:" + ",".join(kinds), "没有可交替的动作，保持基础待机")
		else:
			_log_once("empty:" + ",".join(kinds), "没有符合条件的动作，保持基础待机")
		_arm_dwell()
		return
	var kind := String(decision.get("kind", ""))
	if _host != null and _host.has_method("precoin_should_defer_schedule"):
		if _host.precoin_should_defer_schedule():
			_log_once("defer:schedule", "待机调度让路（AI/业务占用），稍后重试")
			_arm_dwell()
			return
	_session += 1
	_finish_consumed = false
	_stale_logged = false
	_rejected_action_id = ""
	_phase = Phase.ACTION
	_action_playing = true
	_transitioning = false
	_pending_switch = false
	_current_action_id = action_id
	_current_kind = kind
	_skip_pick_id = ""
	_log("动作开始 id=%s 类型=%s 玩家=%s 模式=%s" % [action_id, _kind_label(kind), _presence_text(), _mode_name()])
	var started := false
	if _host != null and _host.has_method("precoin_play_action"):
		started = bool(_host.precoin_play_action(action_id, kind))
	if not started:
		_phase = Phase.DWELL
		_action_playing = false
		_finish_consumed = true
		_current_action_id = ""
		_current_kind = "base"
		var reason := ""
		if _host != null and _host.has_method("get_precoin_last_play_result"):
			reason = String(_host.get_precoin_last_play_result())
		_skip_pick_id = action_id
		if reason.is_empty():
			_log("动作无法播放，保持基础待机 id=%s" % action_id)
		else:
			_log("动作无法播放，保持基础待机 id=%s reason=%s" % [action_id, reason])
		_arm_dwell()


func _begin_transition() -> void:
	_phase = Phase.BLEND
	_transitioning = true
	_action_playing = false
	var blend := _blend_out_attract if _current_kind == "attract" else _blend_out_light
	_log("过渡开始 从=%s" % _current_action_id)
	if _host != null and _host.has_method("precoin_return_to_base"):
		var used: float = float(_host.precoin_return_to_base(_current_action_id))
		if used > 0.0:
			blend = used
	if _timer == null:
		return
	_timer.stop()
	_timer.start(maxf(blend, 0.05))


func _decision(kinds: PackedStringArray, previous: String) -> Dictionary:
	var choices: Array = []
	var available := 0
	for entry in _entries:
		var kind := String(entry.get("kind", ""))
		if kind not in kinds:
			continue
		available += 1
		var action_id := String(entry.get("id", ""))
		if action_id == previous or action_id == _skip_pick_id:
			continue
		choices.append(entry)
	if choices.is_empty():
		if available < 2:
			return {"id": "", "kind": "", "hold": "single_or_empty"}
		return {"id": "", "kind": "", "hold": "no_candidate"}
	choices.shuffle()
	var picked: Dictionary = _weighted(choices)
	return {
		"id": String(picked.get("id", "")),
		"kind": String(picked.get("kind", "")),
		"hold": "",
	}


func _weighted(choices: Array) -> Dictionary:
	if choices.is_empty():
		return {}
	var total := 0.0
	for entry in choices:
		total += maxf(float(entry.get("weight", 1.0)), 0.0)
	if total <= 0.0:
		return choices[randi() % choices.size()]
	var cursor := randf() * total
	var walked := 0.0
	for entry in choices:
		walked += maxf(float(entry.get("weight", 1.0)), 0.0)
		if cursor < walked:
			return entry
	return choices[choices.size() - 1]


func _mark_rejected_if_acting() -> void:
	if _phase == Phase.ACTION and _current_action_id != "":
		_rejected_action_id = _current_action_id
		_stale_logged = false


func _stop_timer() -> void:
	if _timer != null:
		_timer.stop()


func _display_action() -> String:
	if _phase == Phase.ACTION and _current_action_id != "":
		return _current_action_id
	if _phase == Phase.BLEND and _current_action_id != "":
		return _current_action_id
	return "Basic_Idle"


func _presence_text() -> String:
	return "在场" if _player_present else "离开"


func _mode_name() -> String:
	match _target:
		TargetMode.ATTRACT:
			return "ATTRACT"
		TargetMode.BUSINESS:
			return "BUSINESS"
		_:
			return "IDLE"


func _kind_label(kind: String) -> String:
	match kind:
		"general_light":
			return "通用轻待机"
		"exclusive_light":
			return "专属待机"
		"attract":
			return "轻招揽"
		_:
			return "基础待机"


func _log(message: String) -> void:
	_trace.append(message)
	if _trace.size() > 80:
		_trace.remove_at(0)
	if _host != null and _host.has_method("precoin_log"):
		_host.precoin_log(message)


func _log_once(key: String, message: String) -> void:
	if bool(_limit_logged.get(key, false)):
		return
	_limit_logged[key] = true
	_log(message)
