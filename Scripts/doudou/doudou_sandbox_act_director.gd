extends Node
class_name DoudouSandboxActDirector

## 首局 crane03：欢迎结束 → 01开始站立 → 02维持站立 + 兜兜入场；
## 入场倒数 4.5s → 03被吓到 → 回 02；战术指导倒数 0.5s → 04转头 → 开操作台词并回 05。
## 01/03/04 期间 WASD 仍控爪，但不打断身体、不叠眼头；回到 02/05 才跟 preview 一样转头转眼。

const CRANE03_01 := "youyou_claw_crane03_01"
const CRANE03_03 := "youyou_claw_crane03_03"
const CRANE03_04 := "youyou_claw_crane03_04"

var _host: Node
var _doudou: DoudouSideActor
var _grab_flow: YouyouGrabShowFlow
var _event: YouyouEventActionPerformance
var _face: YouyouFacePresenter
var _token_seq := -9000
var _first_round_active := false
var _awaiting_youyou_01 := false
var _awaiting_youyou_02 := false
var _awaiting_youyou_03 := false
var _awaiting_doudou_tactics := false


func setup(
	host: Node,
	doudou: DoudouSideActor,
	grab_flow: YouyouGrabShowFlow,
	event_performance: YouyouEventActionPerformance,
	face: YouyouFacePresenter,
) -> void:
	_host = host
	_doudou = doudou
	_grab_flow = grab_flow
	_event = event_performance
	_face = face
	if _doudou != null:
		if not _doudou.entrance_scare_point.is_connected(_on_entrance_scare_point):
			_doudou.entrance_scare_point.connect(_on_entrance_scare_point)
		if not _doudou.scripted_tactics_scare_point.is_connected(_on_tactics_turn_point):
			_doudou.scripted_tactics_scare_point.connect(_on_tactics_turn_point)
		if not _doudou.scripted_tactics_finished.is_connected(_on_doudou_tactics_finished):
			_doudou.scripted_tactics_finished.connect(_on_doudou_tactics_finished)
	if _event != null and not _event.performance_finished.is_connected(_on_performance_finished):
		_event.performance_finished.connect(_on_performance_finished)


func begin_first_round_after_welcome() -> void:
	_first_round_active = true
	_awaiting_youyou_01 = false
	_awaiting_youyou_02 = false
	_awaiting_youyou_03 = false
	_awaiting_doudou_tactics = false
	if _grab_flow != null:
		_grab_flow.set_crane03_profile(true)
		_grab_flow.set_crane03_post_turn(false)
		_grab_flow.set_crane03_operate_split_expression("")
		_grab_flow.set_operate_ambient_voice_enabled(false)
		_lock_scripted_act(true)
	if _doudou != null:
		_doudou.configure_first_round_scripted(true)
	_play_youyou_once(CRANE03_01)
	_awaiting_youyou_01 = true


func is_first_round_active() -> bool:
	return _first_round_active


func begin_followup_round() -> void:
	_first_round_active = false
	_awaiting_youyou_01 = false
	_awaiting_youyou_02 = false
	_awaiting_youyou_03 = false
	_awaiting_doudou_tactics = false
	if _grab_flow != null:
		_grab_flow.set_crane03_profile(false)
		_grab_flow.set_operate_ambient_voice_enabled(true)
		_lock_scripted_act(false)
	if _doudou != null:
		_doudou.configure_followup_round(true)


func _on_entrance_scare_point() -> void:
	if not _first_round_active:
		return
	_lock_scripted_act(true)
	if _face != null and not YouyouActionSplitExpressionTimelines.has_timeline(CRANE03_03):
		_face.set_emotion("surprise", 0.28)
	_play_youyou_once(CRANE03_03)
	_awaiting_youyou_02 = true


func _on_tactics_turn_point() -> void:
	if not _first_round_active or not _awaiting_doudou_tactics or _awaiting_youyou_03:
		return
	_lock_scripted_act(true)
	if _face != null and not YouyouActionSplitExpressionTimelines.has_timeline(CRANE03_04):
		_face.set_emotion("angry", 0.32)
	_play_youyou_once(CRANE03_04)
	_awaiting_youyou_03 = true


func _on_doudou_tactics_finished() -> void:
	if not _first_round_active or not _awaiting_doudou_tactics:
		return
	_awaiting_doudou_tactics = false
	if not _awaiting_youyou_03:
		_on_tactics_turn_point()


func _on_performance_finished(_token: int, action_id: String, _reason: String) -> void:
	if not _first_round_active:
		return
	if _awaiting_youyou_01 and action_id == CRANE03_01:
		_awaiting_youyou_01 = false
		_resume_operate_hold(false, 0.12, false)
		if _doudou != null:
			_doudou.begin_entrance_after_welcome()
		return
	if _awaiting_youyou_02 and action_id == CRANE03_03:
		_awaiting_youyou_02 = false
		if _grab_flow != null:
			_grab_flow.set_crane03_operate_split_expression(
				YouyouGrabShowFlow.CRANE03_02_POST_SCARE
			)
		_resume_operate_hold(false, 0.08, false)
		if _doudou != null:
			_awaiting_doudou_tactics = true
			_doudou.play_scripted_tactics()
		return
	if _awaiting_youyou_03 and action_id == CRANE03_04:
		_awaiting_youyou_03 = false
		if _grab_flow != null:
			_grab_flow.set_crane03_post_turn(true)
			_grab_flow.set_operate_ambient_voice_enabled(true)
		_resume_operate_hold(true, 0.1, true)
		if _doudou != null:
			_doudou.play_first_round_taunt_sequence()


func _lock_scripted_act(locked: bool) -> void:
	if _grab_flow != null:
		_grab_flow.set_scripted_body_locked(locked)
		_grab_flow.set_operate_look_enabled(not locked)
	if _host != null and _host.has_method("_sync_idle_presence"):
		_host.call("_sync_idle_presence")


func _resume_operate_hold(post_turn: bool, blend: float, arm_voice: bool) -> void:
	_lock_scripted_act(false)
	if _grab_flow == null:
		return
	if not post_turn:
		_grab_flow.set_crane03_post_turn(false)
	_grab_flow.snap_operate_loop(blend, arm_voice, true)
	if _host != null and _host.has_method("_apply_sandbox_operate_wasd_look"):
		_host.call("_apply_sandbox_operate_wasd_look")


func _play_youyou_once(action_id: String) -> void:
	if _event == null:
		return
	var token := _next_token()
	if _host != null and _host.has_method("grab_mark_event"):
		_host.grab_mark_event(true)
	# 配音与时序来自 config/youyou_action_event_catalog.json（勿在此硬编码覆盖）
	_event.play_event(action_id, token, false, true, 0.12, "")


func _next_token() -> int:
	_token_seq -= 1
	return _token_seq
