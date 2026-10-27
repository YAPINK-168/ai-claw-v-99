extends Node
class_name ClawBoardBridge

## 串口 BoardLink ↔ ClawBusiness。Windows 仅 WASD/X 时，X 的业务含义也走这里。

const Business := preload("res://Scripts/business/claw_business.gd")

enum PostMinigame { NONE, AWAIT_X_HOME, AWAIT_X_NEW_ROUND }

signal bridge_note(text: String)

var _business: ClawBusiness
var _host: Node
var _round_success_latched := false
var _post_minigame := PostMinigame.NONE


func setup(business: ClawBusiness, host: Node = null) -> void:
	_business = business
	_host = host
	if BoardLink.mech_event.is_connected(_on_mech_event):
		BoardLink.mech_event.disconnect(_on_mech_event)
	BoardLink.mech_event.connect(_on_mech_event)
	if BoardLink.coin_inserted.is_connected(_on_coin_inserted):
		BoardLink.coin_inserted.disconnect(_on_coin_inserted)
	BoardLink.coin_inserted.connect(_on_coin_inserted)
	if BoardLink.credits_changed.is_connected(_on_credits_changed):
		BoardLink.credits_changed.disconnect(_on_credits_changed)
	BoardLink.credits_changed.connect(_on_credits_changed)
	if not BoardLink.claw_won.is_connected(_on_claw_sensor_success):
		BoardLink.claw_won.connect(_on_claw_sensor_success)
	if not BoardLink.claw_failed.is_connected(_on_claw_sensor_fail):
		BoardLink.claw_failed.connect(_on_claw_sensor_fail)
	_business.sync_machine_credits(machine_credits())


func machine_credits() -> int:
	return BoardLink.get_credits()


func on_minigame_overlay_started() -> void:
	BoardLink.take_control()
	_post_minigame = PostMinigame.NONE
	_note("小游戏开始：已接管 IO 板，摇杆/按键只给小游戏。")


func on_minigame_settled() -> void:
	BoardLink.release_control()
	if machine_credits() >= Business.ROUND_COST:
		_post_minigame = PostMinigame.AWAIT_X_HOME
		_note("小游戏结算完成。按 X 回到抓娃娃；再按 X 扣 %d 币开新局。" % Business.ROUND_COST)
	else:
		_post_minigame = PostMinigame.NONE
		_note("小游戏结算完成。余币不足，请投币后再按 X 开局。")


func on_action_button_pressed() -> void:
	if _business == null:
		return
	if _post_minigame == PostMinigame.AWAIT_X_HOME:
		_post_minigame = PostMinigame.AWAIT_X_NEW_ROUND
		_note("已回到抓娃娃主流程。再按 X 可开新局（需余币 ≥ %d）。" % Business.ROUND_COST)
		return
	if _post_minigame == PostMinigame.AWAIT_X_NEW_ROUND:
		_try_begin_machine_round("小游戏后")
		return
	if _business.is_success_hold() and machine_credits() >= Business.ROUND_COST:
		_try_begin_machine_round("成功后")
		return
	if _business.current_stage() == Business.Stage.OPERATE or _business.current_stage() == Business.Stage.WAIT_START:
		if _host != null and _host.has_method("arm_machine_grab"):
			_host.call("arm_machine_grab")
		var grabbed: Dictionary = _submit(Business.GRAB_PRESSED)
		if bool(grabbed.get("ok", false)) and _host != null and _host.has_method("_play_grab_down"):
			_host.call("_play_grab_down")
		return
	_note("当前阶段按 X 无效：%s" % _business.stage_name())


func _on_coin_inserted(_amount: int, _credits: int) -> void:
	# 与 0x09/0x01 可能同一次投币重复上报，这里只同步余币
	_sync_credits()


func _on_credits_changed(credits: int) -> void:
	if _business != null:
		_business.sync_machine_credits(credits)


func _on_claw_sensor_success() -> void:
	_deliver_grab_sensor(true)


func _on_claw_sensor_fail() -> void:
	_deliver_grab_sensor(false)


func _deliver_grab_sensor(success: bool) -> void:
	if success:
		_round_success_latched = true
	elif _round_success_latched:
		return
	if _host != null and _host.has_method("latch_machine_grab_result"):
		_host.call("latch_machine_grab_result", success)
		return
	_submit(Business.GRAB_SUCCEEDED if success else Business.GRAB_FAILED)


func _on_mech_event(event_id: int) -> void:
	match event_id:
		0x01:
			_submit(Business.COIN_ACCEPTED)
			_sync_credits()
		0x02:
			_round_success_latched = false
			if _business != null and not _business.has_visitor():
				_submit(Business.PLAYER_ENTERED)
			_sync_credits()
			if _host != null and _host.has_method("enter_claw_watch_keeping_speech"):
				_host.call("enter_claw_watch_keeping_speech")
			_try_begin_machine_round("0x02")
		0x03:
			_round_success_latched = false
			if _host != null and _host.has_method("arm_machine_grab"):
				_host.call("arm_machine_grab")
			var grabbed: Dictionary = _submit(Business.GRAB_PRESSED)
			if not bool(grabbed.get("ok", false)) and _business != null and _business.current_stage() == Business.Stage.STANDBY:
				_try_begin_machine_round("抓取时补开局")
				if _host != null and _host.has_method("arm_machine_grab"):
					_host.call("arm_machine_grab")
				grabbed = _submit(Business.GRAB_PRESSED)
			if bool(grabbed.get("ok", false)) and _host != null and _host.has_method("_play_grab_down"):
				_host.call("_play_grab_down")
		0x0A:
			_round_success_latched = true
			if _host != null and _host.has_method("latch_machine_grab_result"):
				_host.call("latch_machine_grab_result", true)
			else:
				_submit(Business.GRAB_SUCCEEDED)
		0x0B:
			if _round_success_latched:
				pass
			elif _host != null and _host.has_method("latch_machine_grab_result"):
				_host.call("latch_machine_grab_result", false)
			else:
				_submit(Business.GRAB_FAILED)
		_:
			pass


func _try_begin_machine_round(reason: String) -> void:
	if _business == null:
		return
	_sync_credits()
	var result: Dictionary = _business.begin_round_from_machine()
	if bool(result.get("ok", false)):
		_post_minigame = PostMinigame.NONE
		_round_success_latched = false
	_note("[%s] %s" % [reason, String(result.get("note", ""))])


func _sync_credits() -> void:
	if _business != null:
		_business.sync_machine_credits(machine_credits())


func _submit(event_id: String) -> Dictionary:
	if _business == null:
		return {}
	var result: Dictionary = _business.submit(event_id)
	_note(String(result.get("note", "")))
	return result


func _note(text: String) -> void:
	if text.is_empty():
		return
	bridge_note.emit(text)
	if _host != null and _host.has_method("_note"):
		_host.call("_note", "[串口] " + text)
