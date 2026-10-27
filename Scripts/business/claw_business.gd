extends Node
class_name ClawBusiness

const ShowPort := preload("res://Scripts/business/claw_show_port.gd")

## 娃娃机业务流程。只回答两件事：现在在哪一步，以及这一步允许什么发生。
## 不播放柚柚的动作和语音，只通过表现接口提出请求。

signal situation_changed

const PLAYER_ENTERED := "player_entered"
const PLAYER_LEFT := "player_left"
const COIN_ACCEPTED := "coin_accepted"
const PLAYER_OPERATING := "player_operating"
const GRAB_PRESSED := "grab_pressed"
const GRAB_SUCCEEDED := "grab_succeeded"
const GRAB_FAILED := "grab_failed"
const SUCCESS_REPLAY := "success_replay"
const FAIL_REPLAY := "fail_replay"
const MINIGAME_FINISHED := "minigame_finished"

enum Stage { STANDBY, WAIT_START, OPERATE, GRABBING, RESULT, MINIGAME }

var _stage := Stage.STANDBY
var _visitor := false
var _token := 0
var _wait_show := false
var _success := false
var _after_result := "over"
var _result_phase := ""
var _invite_listen_session := 0
var _invite_outcome_locked := false
var _keyboard_invite := ""
var _minigame_launch_locked := false
var _minigame_from_invite_play := false
var _coins := 0
var _welcome_played := false
var _welcome_busy := false
var _paid_round_queued := false
var _crouch_after_welcome := false
var _welcome_play_count := 0
var _paid_round_count := 0
var _success_hold_until_ms := 0
## 上一局结束时的余额。-1 表示还没有完整开过局，下一声欢迎用首局。
var _followup_coins := -1
var _followup_zero_until_ms := 0
var _followup_coined_in_window := false
var _closing_from_hold_timeout := false
## 引导下一局播完后：呼吸待机这么久。期间没有重开，就进入随机待机招揽。
var _fail_short_wait := false
## 本局结束且余额为 0 时：此秒数内投币仍算续局；超时则抓娃娃结束，下次投币为首局。
const REPLAY_HOLD_ZERO_BALANCE_SEC := 10.0
const GUIDE_BREATH_HOLD_SEC := 10.0
const FAIL_REPLAY_WAIT_SEC := GUIDE_BREATH_HOLD_SEC
const SUCCESS_HOLD_SEC := REPLAY_HOLD_ZERO_BALANCE_SEC
const ROUND_COST := 2
var _show
var _minigame
var last_note := ""


func bind(show_port, minigame_port) -> void:
	_show = show_port
	_minigame = minigame_port
	if not _show.show_finished.is_connected(_on_show_finished):
		_show.show_finished.connect(_on_show_finished)
	if _show.has_signal("show_failed") and not _show.show_failed.is_connected(_on_show_failed):
		_show.show_failed.connect(_on_show_failed)
	if not _minigame.finished.is_connected(_on_minigame_port_finished):
		_minigame.finished.connect(_on_minigame_port_finished)
	if _show.has_signal("welcome_finished") and not _show.welcome_finished.is_connected(notify_coin_welcome_finished):
		_show.welcome_finished.connect(notify_coin_welcome_finished)
	_enter_standby(false)


func current_stage() -> Stage:
	return _stage


func debug_resume_grabbing() -> void:
	_wait_show = false
	_result_phase = ""
	_token = _next_token()
	_stage = Stage.GRABBING


func has_visitor() -> bool:
	return _visitor


func stage_name() -> String:
	match _stage:
		Stage.STANDBY:
			return "待机"
		Stage.WAIT_START:
			return "等待开始"
		Stage.OPERATE:
			return "玩家操作"
		Stage.GRABBING:
			return "正在抓"
		Stage.RESULT:
			return "结果"
		Stage.MINIGAME:
			return "小游戏"
	return ""


func explain() -> String:
	match _stage:
		Stage.STANDBY:
			if _welcome_busy:
				return "正在播放本轮唯一一次投币欢迎。余额 %d。" % _coins
			if _coins >= ROUND_COST:
				return "余额 %d。满 %d 个币，并且现在可以开新局时，才会扣币开始。" % [_coins, ROUND_COST]
			if _visitor:
				if _coins > 0:
					return "有人在机器前，柚柚在招揽。余额 %d，还不够开新局。" % _coins
				return "有人在机器前，柚柚在招揽。还没投币，不能抓。"
			if _coins > 0:
				return "余额 %d。满 %d 个币，并且现在可以开新局时，才会扣币开始。" % [_coins, ROUND_COST]
			return "机器前没人，柚柚做基础待机。"
		Stage.WAIT_START:
			return "已扣除 %d 个币，正在蹲下观察。观察完才进入操作循环。" % ROUND_COST
		Stage.OPERATE:
			return "现在可以操作爪子。只有按下抓取，才会真的去抓。"
		Stage.GRABBING:
			return "正在抓。这一下还没出结果之前，再投币、再按抓取，都不算。"
		Stage.RESULT:
			if _result_phase == "success_guide":
				return "抓取成功已经演完，正在播放续玩引导。"
			if _result_phase == "success_hold" or _result_phase == "fail_hold":
				if _coins >= ROUND_COST:
					return "呼吸待机 %d 秒。余额 %d，按 Ctrl+Z 重开；没重开则进入随机待机招揽。" % [int(GUIDE_BREATH_HOLD_SEC), _coins]
				return "呼吸待机 %d 秒。没有重开则进入随机待机招揽。" % int(GUIDE_BREATH_HOLD_SEC)
			if _result_phase == "fail_continue_guide":
				return "拒绝小游戏后，正在播放抓娃娃续玩引导。"
			if _result_phase == "invite_play_accepted":
				return "玩家愿意玩小游戏，即将进入抽取转盘。"
			if _result_phase == "invite_listen_error":
				return "小游戏意愿识别异常结束，未当作玩家拒绝。"
			if _result_phase == "invite_listen":
				return "失败结果已播完，正在等玩家回答要不要玩小游戏。"
			if _result_phase == "feedback":
				if _success:
					return "抓到了。先把这个结果演完，再决定接下来去哪。"
				return "没抓到。先把这个结果演完，再决定接下来去哪。"
			match _after_result:
				"minigame":
					return "结果演完了，正在邀请去小游戏。"
				"retry":
					return "结果演完了。再给一次抓，不用重新投币。"
				_:
					return "这一轮要结束了，正在收尾。"
		Stage.MINIGAME:
			return "小游戏抽取或具体玩法进行中。抓娃娃流程暂停，结束后按现有规则返回。"
	return ""


func submit(event_id: String, extra: Dictionary = {}) -> Dictionary:
	match event_id:
		PLAYER_ENTERED:
			return _on_player_entered()
		PLAYER_LEFT:
			return _on_player_left()
		COIN_ACCEPTED:
			return _on_coin()
		PLAYER_OPERATING:
			return _on_player_operating()
		GRAB_PRESSED:
			return _on_grab_pressed()
		GRAB_SUCCEEDED:
			return _on_grab_result(true, String(extra.get("next", "")))
		GRAB_FAILED:
			return _on_grab_result(false, String(extra.get("next", "")))
		MINIGAME_FINISHED:
			return _on_minigame_finished(bool(extra.get("another_grab", false)))
		SUCCESS_REPLAY, FAIL_REPLAY:
			return request_followup_round()
		_:
			return _reject("这件事先不处理。")


func _on_player_entered() -> Dictionary:
	if _stage != Stage.STANDBY:
		return _reject("这轮已经开始了。")
	if _visitor:
		return _reject("人已经在机器前了。")
	_visitor = true
	_play(ShowPort.ACTION_ATTRACT, ShowPort.SPEECH_ATTRACT, false)
	_announce("有人走过来，开始招揽。")
	return _accept("有人走过来，开始招揽。")


func _on_player_left() -> Dictionary:
	if _stage != Stage.STANDBY:
		return _reject("币已经投了，人走开这轮也不中断。")
	if not _visitor and _coins == 0:
		return _reject("机器前本来就没人。")
	_visitor = false
	_welcome_played = false
	_welcome_busy = false
	_paid_round_queued = false
	_play(ShowPort.ACTION_STANDBY, "", false)
	_announce("人走开了，本轮欢迎已结束。余额仍是 %d。" % _coins)
	return _accept("人走开了，本轮欢迎已结束。")


func coin_balance() -> int:
	return _coins


## 与 IO 板 coinin 对齐（BoardLink.credits_changed / 投币帧）
func sync_machine_credits(credits: int) -> void:
	var v := maxi(0, credits)
	if v == _coins:
		return
	var increased := v > _coins
	_coins = v
	situation_changed.emit()
	if increased:
		_note_coin_for_followup()
		_maybe_welcome_from_machine_credits()


func _maybe_welcome_from_machine_credits() -> void:
	if _show == null:
		return
	if _stage != Stage.STANDBY or _welcome_played or _welcome_busy:
		return
	if _coins < ROUND_COST:
		return
	# 和电脑上投币一样：欢迎说完就进入放大盯钩爪，不要回到轻招揽。
	_paid_round_queued = true
	_crouch_after_welcome = false
	_start_welcome()


## 真机已经开始动钩爪：进入操作阶段。余币以控制板为准，这里不再因为本地余币挡住。
func begin_round_from_machine() -> Dictionary:
	if _stage == Stage.WAIT_START or _stage == Stage.OPERATE or _stage == Stage.GRABBING:
		return _accept("这轮已经开了。")
	if _stage == Stage.MINIGAME:
		return _reject("小游戏进行中，不能开抓娃娃。")
	if is_invite_listen():
		return _accept("还在等小游戏回答，身体先去盯钩爪。")
	if _stage == Stage.RESULT:
		_success_hold_until_ms = 0
		set_process(false)
		_result_phase = ""
		_wait_show = false
		_stage = Stage.STANDBY
	if _stage != Stage.STANDBY:
		return _reject("当前不在待机，不能开局。")
	_welcome_busy = false
	_welcome_played = true
	_paid_round_queued = false
	_crouch_after_welcome = false
	_stage = Stage.OPERATE
	_result_phase = ""
	_wait_show = false
	_visitor = true
	_announce("机台开局，进入盯钩爪。")
	situation_changed.emit()
	return _accept("机台开局，进入盯钩爪。")


func note_claw_operated() -> void:
	begin_round_from_machine()


func welcome_play_count() -> int:
	return _welcome_play_count


func paid_round_count() -> int:
	return _paid_round_count


## 当前欢迎是否为「续局投币欢迎」（非整段抓娃娃的首局欢迎）。
func is_session_first_coin_welcome() -> bool:
	return not _welcome_is_return()


func is_welcome_busy() -> bool:
	return _welcome_busy


func reset_for_retest() -> void:
	_stage = Stage.STANDBY
	_result_phase = ""
	_invite_outcome_locked = false
	_minigame_launch_locked = false
	_minigame_from_invite_play = false
	_welcome_played = false
	_welcome_busy = false
	_paid_round_queued = false
	_crouch_after_welcome = false
	_coins = 0
	_keyboard_invite = ""
	_success_hold_until_ms = 0
	set_process(false)
	_clear_followup_welcome()
	_visitor = false
	_wait_show = false
	_success = false
	_after_result = "over"
	situation_changed.emit()


func take_crouch_after_welcome() -> bool:
	var pending := _crouch_after_welcome
	_crouch_after_welcome = false
	return pending


func notify_coin_welcome_finished() -> void:
	if not _welcome_busy:
		return
	_welcome_busy = false
	if _paid_round_queued and _stage == Stage.STANDBY and _coins >= ROUND_COST:
		_begin_paid_round()
		return
	_paid_round_queued = false
	if _stage != Stage.STANDBY:
		return
	if _visitor:
		_play(ShowPort.ACTION_ATTRACT, ShowPort.SPEECH_ATTRACT, false)
	else:
		_play(ShowPort.ACTION_STANDBY, "", false)
	_announce("投币欢迎结束。余额 %d。" % _coins)


func _on_coin() -> Dictionary:
	_coins += 1
	_visitor = true
	_note_coin_for_followup()
	if is_replay_hold():
		return _on_coin_during_replay_hold()
	var played_welcome := false
	if _stage == Stage.STANDBY and not _welcome_played and _coins >= ROUND_COST:
		_start_welcome()
		played_welcome = true
	var started := _try_paid_round()
	var note := "投币 +1，余额 %d。" % _coins
	if _coins < ROUND_COST and not _welcome_played:
		note += "未满 %d 个币，先不播放欢迎。" % ROUND_COST
	elif played_welcome:
		note += "满 %d 个币，本轮欢迎只播放一次。" % ROUND_COST
	else:
		note += "本轮已欢迎过，只累加余额。"
	if started:
		note += "扣除 %d 个币，开始蹲下观察。" % ROUND_COST
	elif _paid_round_queued:
		note += "欢迎结束后再开局。"
	_announce(note)
	return _accept(note)


func _start_welcome() -> void:
	_welcome_played = true
	_welcome_busy = true
	_welcome_play_count += 1
	var speech := ShowPort.SPEECH_COIN_RETURN if _welcome_is_return() else ShowPort.SPEECH_COIN
	_play(ShowPort.ACTION_OPENING, speech, false)


func _clear_followup_welcome() -> void:
	_followup_coins = -1
	_followup_zero_until_ms = 0
	_followup_coined_in_window = false


func _note_round_closed() -> void:
	if _paid_round_count <= 0:
		return
	_followup_coins = _coins
	_followup_coined_in_window = false
	if _coins > 0:
		_followup_zero_until_ms = 0
	else:
		_followup_zero_until_ms = Time.get_ticks_msec() + int(SUCCESS_HOLD_SEC * 1000.0)


func _note_coin_for_followup() -> void:
	if _followup_coins != 0:
		return
	if _followup_zero_until_ms <= 0 or Time.get_ticks_msec() > _followup_zero_until_ms:
		return
	_followup_coined_in_window = true
	_followup_coins = _coins
	_followup_zero_until_ms = 0


func _welcome_is_return() -> bool:
	if _followup_coined_in_window or _followup_coins > 0:
		return true
	return _followup_coins == 0 and _followup_zero_until_ms > 0 and Time.get_ticks_msec() <= _followup_zero_until_ms


func _on_coin_during_replay_hold() -> Dictionary:
	var note := "投币 +1，余额 %d。" % _coins
	if _coins >= ROUND_COST:
		note += "已够 %d 个币，按 Ctrl+Z 再开一局，不会自动开始。" % ROUND_COST
	else:
		note += "还不够 %d 个币。呼吸待机倒计时继续，凑够币可 Ctrl+Z 重开。" % ROUND_COST
	_announce(note)
	return _accept(note)


func _try_paid_round() -> bool:
	if _stage != Stage.STANDBY or _coins < ROUND_COST:
		return false
	if _welcome_busy:
		_paid_round_queued = true
		return false
	return _begin_paid_round()


func _begin_paid_round() -> bool:
	if _stage != Stage.STANDBY or _coins < ROUND_COST or _welcome_busy:
		return false
	_coins -= ROUND_COST
	_paid_round_count += 1
	_paid_round_queued = false
	_stage = Stage.WAIT_START
	_play(ShowPort.ACTION_PAID_OBSERVE, "", true)
	_announce("扣除 %d 个币，播放蹲下观察。" % ROUND_COST)
	return true


func _on_player_operating() -> Dictionary:
	if _stage != Stage.OPERATE:
		return _reject("现在还不能操作爪子。")
	_play(ShowPort.ACTION_OPERATING, "", false)
	_announce("玩家正在操作爪子。")
	return _accept("玩家正在操作爪子。")


func _on_grab_pressed() -> Dictionary:
	if _stage == Stage.WAIT_START:
		_wait_show = false
		_result_phase = ""
		_stage = Stage.OPERATE
	if _stage != Stage.OPERATE:
		if _stage == Stage.GRABBING:
			return _reject("正在抓，不能再抓一次。")
		return _reject("现在还不能抓。")
	_stage = Stage.GRABBING
	_play(ShowPort.ACTION_GRABBING, ShowPort.SPEECH_GRAB, false)
	_announce("开始抓取。")
	return _accept("开始抓取。")


func _on_grab_result(success: bool, requested_next: String) -> Dictionary:
	if _stage != Stage.GRABBING:
		return _reject("现在没有一轮抓取在进行。")
	_success = success
	_after_result = _normalize_next(requested_next, success)
	_result_phase = "feedback"
	_stage = Stage.RESULT
	if success:
		_play(ShowPort.ACTION_SUCCESS, ShowPort.SPEECH_SUCCESS, true)
		_announce("抓到了。")
		return _accept("抓到了。")
	_play(ShowPort.ACTION_FAIL, ShowPort.SPEECH_FAIL, true)
	_announce("没抓到。")
	return _accept("没抓到。")


func _on_minigame_finished(another_grab: bool) -> Dictionary:
	if _stage != Stage.MINIGAME:
		return _reject("现在不在小游戏里。")
	_minigame_launch_locked = false
	_minigame_from_invite_play = false
	if another_grab:
		_enter_operate("小游戏结束，再给一次抓。")
		return _accept("小游戏结束，再给一次抓。")
	_enter_standby_after_round("小游戏结束，这一轮到此为止。")
	return _accept("小游戏结束，这一轮到此为止。")


## 序列帧测试场景自己播返场，这里只回到待机，不立刻切招揽或操作。
func finish_minigame_quietly() -> bool:
	if _stage != Stage.MINIGAME:
		return false
	_minigame_launch_locked = false
	_minigame_from_invite_play = false
	_note_round_closed()
	_success_hold_until_ms = 0
	set_process(false)
	_stage = Stage.STANDBY
	_result_phase = ""
	_success = false
	_after_result = "over"
	_invite_outcome_locked = false
	_wait_show = false
	_announce("小游戏结束，回到抓娃娃。")
	return true


## 不扣币，从倾身开始一整局抓取。
func begin_free_grab_round() -> Dictionary:
	if _stage != Stage.STANDBY or _welcome_busy:
		return _reject("现在不能免费开局。")
	_paid_round_count += 1
	_paid_round_queued = false
	_welcome_busy = false
	_visitor = true
	_stage = Stage.WAIT_START
	_play(ShowPort.ACTION_PAID_OBSERVE, "", true)
	_announce("免费开局，不扣币。")
	return _accept("免费开局，不扣币。")


func _on_minigame_port_finished(token: int, another_grab: bool) -> void:
	if token != _token or _stage != Stage.MINIGAME:
		return
	_on_minigame_finished(another_grab)


func _on_show_finished(token: int) -> void:
	if token != _token or not _wait_show:
		return
	_wait_show = false
	match _stage:
		Stage.WAIT_START:
			_enter_operate("开场结束，可以把控制权交给玩家了。")
		Stage.RESULT:
			if _result_phase == "fail_continue_guide":
				var second_grab := _after_result == "second_grab"
				var hold_note := "引导再抓一次结束，呼吸待机等待。" if second_grab else "拒绝后续玩引导结束，回到基础待机。"
				_enter_fail_hold(hold_note, second_grab)
				return
			_advance_result()


func _on_show_failed(token: int) -> void:
	if token != _token or not _wait_show:
		return
	_wait_show = false
	if _result_phase == "success_guide":
		_enter_success_hold("续玩引导没有演完，仍进入等待。")
		return
	if _result_phase == "fail_continue_guide":
		var second_grab := _after_result == "second_grab"
		var hold_note := "引导没有演完，仍进入呼吸待机等待。" if second_grab else "拒绝后续玩引导没有演完，仍进入等待。"
		_enter_fail_hold(hold_note, second_grab)
		return
	_announce("表现没有演完，停在当前阶段，不进入下一步。")


func _advance_result() -> void:
	if _result_phase == "feedback":
		_result_phase = "guide"
		match _after_result:
			"minigame":
				_play(ShowPort.ACTION_INVITE_MINIGAME, ShowPort.SPEECH_MINIGAME, true)
				_announce("邀请去小游戏。")
			"second_grab":
				_result_phase = "fail_continue_guide"
				_play(ShowPort.ACTION_FAIL_CONTINUE_GUIDE, "", true)
				_announce("安慰结束，引导再抓一次。")
			"retry":
				_play(ShowPort.ACTION_INVITE_RETRY, ShowPort.SPEECH_RETRY, true)
				_announce("再给一次抓。")
			_:
				if _success:
					_result_phase = "success_guide"
					_play(ShowPort.ACTION_SUCCESS_GUIDE, "", true)
					_announce("成功结果演完，播放续玩引导。")
				else:
					_play(ShowPort.ACTION_ROUND_OVER, ShowPort.SPEECH_ROUND_OVER, true)
					_announce("这一轮收尾。")
		return
	if _result_phase == "success_guide":
		_enter_success_hold("续玩引导结束，回到基础待机。")
		return
	match _after_result:
		"minigame":
			_enter_invite_listen("引导语结束，等待玩家是否愿意玩小游戏。")
		"retry":
			_enter_operate("可以再抓一次，不用重新投币。")
		_:
			_enter_standby_after_round("这一轮结束。人还在的话，继续招揽。")


func is_success_hold() -> bool:
	return _stage == Stage.RESULT and _result_phase == "success_hold"


func is_success_guide() -> bool:
	return _stage == Stage.RESULT and _result_phase == "success_guide"


func is_replay_hold() -> bool:
	return is_success_hold() or is_fail_hold()


func can_request_followup_from_standby() -> bool:
	return (
		_stage == Stage.STANDBY
		and _paid_round_count > 0
		and _coins >= ROUND_COST
		and not _welcome_busy
	)


func request_followup_round() -> Dictionary:
	if is_replay_hold():
		return _begin_followup_paid_round()
	if can_request_followup_from_standby():
		return _begin_followup_paid_round()
	if _stage == Stage.STANDBY and _paid_round_count > 0 and _coins < ROUND_COST:
		return _reject("余额不足 %d 个币，先 Ctrl+T 投币再按 Ctrl+Z。" % ROUND_COST)
	if is_invite_listen():
		return _reject("还在等小游戏回答，按 1 或 2 后再开新局。")
	if _stage == Stage.RESULT and not is_replay_hold():
		return _reject("等续玩引导播完进入等待，再按 Ctrl+Z 开续局。")
	return _reject("现在不能用 Ctrl+Z 开新局。")


func request_replay_from_hold() -> Dictionary:
	return request_followup_round()


func request_success_replay() -> Dictionary:
	return request_replay_from_hold()


func is_fail_hold() -> bool:
	return _stage == Stage.RESULT and _result_phase == "fail_hold"


func is_fail_continue_guide() -> bool:
	return _stage == Stage.RESULT and _result_phase == "fail_continue_guide"


func request_fail_replay() -> Dictionary:
	return request_replay_from_hold()


func _begin_followup_paid_round() -> Dictionary:
	if _coins < ROUND_COST:
		return _reject("余额不足 %d 个币。" % ROUND_COST)
	if _welcome_busy:
		return _reject("欢迎表现还没结束。")
	_success_hold_until_ms = 0
	_fail_short_wait = false
	set_process(false)
	_result_phase = ""
	_stage = Stage.STANDBY
	_wait_show = false
	_paid_round_queued = true
	_start_welcome()
	_announce("先播投币欢迎，再进入新一局。")
	return _accept("按 Ctrl+Z 开始新一局。")


func _arm_guide_breath_hold() -> void:
	_success_hold_until_ms = Time.get_ticks_msec() + int(GUIDE_BREATH_HOLD_SEC * 1000.0)
	set_process(true)


func _configure_replay_hold_timer() -> void:
	if _coins > 0:
		_success_hold_until_ms = 0
		set_process(false)
	else:
		_success_hold_until_ms = Time.get_ticks_msec() + int(REPLAY_HOLD_ZERO_BALANCE_SEC * 1000.0)
		set_process(true)


func _enter_success_hold(note: String) -> void:
	_note_round_closed()
	_stage = Stage.RESULT
	_result_phase = "success_hold"
	_wait_show = false
	_success = false
	_after_result = "over"
	_fail_short_wait = false
	_arm_guide_breath_hold()
	_play(ShowPort.ACTION_REPLAY_WAIT, "", false)
	_announce("%s 先呼吸待机 %d 秒，没有重开则进入随机待机招揽。" % [note, int(GUIDE_BREATH_HOLD_SEC)])


func _enter_fail_hold(note: String, short_wait: bool = false) -> void:
	_note_round_closed()
	_stage = Stage.RESULT
	_result_phase = "fail_hold"
	_wait_show = false
	_success = false
	_after_result = "over"
	_fail_short_wait = short_wait
	_arm_guide_breath_hold()
	_play(ShowPort.ACTION_REPLAY_WAIT, "", false)
	_announce("%s 先呼吸待机 %d 秒，没有重开则进入随机待机招揽。" % [note, int(GUIDE_BREATH_HOLD_SEC)])


func _process(_delta: float) -> void:
	if _success_hold_until_ms <= 0:
		return
	if not is_replay_hold():
		return
	if Time.get_ticks_msec() >= _success_hold_until_ms:
		_success_hold_until_ms = 0
		set_process(false)
		_end_replay_hold_timeout()


## 引导小游戏或第二局收尾后 10 秒没人回应：结束本局，柚柚回到待机招揽。
func end_round_no_response() -> void:
	if (
		_stage == Stage.MINIGAME
		or _stage == Stage.OPERATE
		or _stage == Stage.GRABBING
		or _stage == Stage.WAIT_START
	):
		return
	if _stage == Stage.STANDBY and _result_phase == "":
		return
	_success_hold_until_ms = 0
	set_process(false)
	_end_replay_hold_timeout(
		"10 秒没有玩家响应，兜兜离场，柚柚进入待机招揽，本局结束。有余币可 Ctrl+Z 开续局。",
		"10 秒没有玩家响应，兜兜离场，柚柚进入待机招揽，本局结束。"
	)


func _end_replay_hold_timeout(note_with_coins: String = "", note_without_coins: String = "") -> void:
	_fail_short_wait = false
	_welcome_played = false
	_welcome_busy = false
	_paid_round_queued = false
	_visitor = false
	var with_coins := note_with_coins
	if with_coins == "":
		with_coins = "呼吸待机结束且没有重开，进入随机待机招揽。有余币可 Ctrl+Z 开续局。"
	var without_coins := note_without_coins
	if without_coins == "":
		without_coins = (
			"呼吸待机 %d 秒内没有重开，进入随机待机招揽。下次满币欢迎按首局。"
			% int(GUIDE_BREATH_HOLD_SEC)
		)
	if _coins > 0:
		_closing_from_hold_timeout = true
		_enter_standby_after_round(with_coins)
		_closing_from_hold_timeout = false
		return
	_paid_round_count = 0
	_welcome_play_count = 0
	_clear_followup_welcome()
	_closing_from_hold_timeout = true
	_enter_standby_after_round(without_coins)
	_closing_from_hold_timeout = false


func _enter_operate(note: String) -> void:
	_stage = Stage.OPERATE
	_result_phase = ""
	_success_hold_until_ms = 0
	set_process(false)
	_play(ShowPort.ACTION_OPERATING, ShowPort.SPEECH_CONTROL, false)
	_announce(note)


func _enter_invite_listen(note: String) -> void:
	_stage = Stage.RESULT
	_result_phase = "invite_listen"
	_invite_outcome_locked = false
	_invite_listen_session += 1
	_wait_show = false
	_announce(note)
	_flush_keyboard_invite()


func has_pending_keyboard_invite() -> bool:
	return _keyboard_invite != ""


func arm_keyboard_invite(intent: String) -> void:
	if intent != "PLAY" and intent != "DECLINE":
		return
	if is_invite_play_accepted():
		return
	_keyboard_invite = intent


func _flush_keyboard_invite() -> void:
	if _keyboard_invite == "":
		return
	var intent := _keyboard_invite
	_keyboard_invite = ""
	submit_invite_intent(intent)


func result_phase() -> String:
	return _result_phase


func invite_listen_session() -> int:
	return _invite_listen_session


func is_invite_listen() -> bool:
	return _stage == Stage.RESULT and _result_phase == "invite_listen"


func is_invite_play_accepted() -> bool:
	return _stage == Stage.RESULT and _result_phase == "invite_play_accepted"


func launched_minigame_from_invite_play() -> bool:
	return _minigame_from_invite_play and _stage == Stage.MINIGAME


func is_invite_listen_error() -> bool:
	return _stage == Stage.RESULT and _result_phase == "invite_listen_error"


func submit_invite_intent(intent: String) -> Dictionary:
	if is_invite_play_accepted():
		if intent == "PLAY":
			return _accept("玩家愿意玩小游戏（已确认）。")
		return _reject("意愿已确认，不能重复提交。")
	if _stage == Stage.MINIGAME and _minigame_from_invite_play:
		return _reject("小游戏已在运行。")
	if not is_invite_listen():
		return _reject("当前不在小游戏意愿等待阶段。")
	if _invite_outcome_locked:
		return _reject("本轮意愿已提交过。")
	match intent:
		"PLAY":
			_invite_outcome_locked = true
			_result_phase = "invite_play_accepted"
			_announce("玩家愿意玩小游戏。")
			return _accept("玩家愿意玩小游戏。")
		"DECLINE":
			_invite_outcome_locked = true
			_finalize_invite_decline("玩家暂不玩小游戏，回到抓娃娃流程。")
			return _accept("玩家暂不玩小游戏。")
		_:
			return _reject("无法识别的意愿结果。")


func finalize_invite_listen_error(note: String) -> Dictionary:
	if not is_invite_listen():
		if is_invite_listen_error():
			return _accept("识别异常已记录。")
		return _reject("当前不在小游戏意愿等待阶段。")
	if _invite_outcome_locked:
		return _reject("本轮意愿已提交过。")
	_invite_outcome_locked = true
	_result_phase = "invite_listen_error"
	_announce(note)
	_enter_standby_after_round("语音识别异常，本轮邀请结束（非玩家拒绝）。")
	return _accept(note)


func cancel_invite_listen(clear_visitor: bool = false) -> void:
	if not is_invite_listen():
		return
	if clear_visitor:
		_visitor = false
	_enter_standby_after_round("小游戏引导已取消。")


func _finalize_invite_decline(note: String) -> void:
	_stage = Stage.RESULT
	_result_phase = "fail_continue_guide"
	_success = false
	_after_result = "over"
	_invite_outcome_locked = true
	_wait_show = false
	call_deferred("_begin_fail_continue_show_after_decline", note)


func _begin_fail_continue_show_after_decline(note: String) -> void:
	if _result_phase != "fail_continue_guide" or _stage != Stage.RESULT:
		return
	if _show == null:
		push_error("拒绝后续玩引导：Show 未绑定。")
		_enter_fail_hold("Show 未绑定，仍进入续玩等待。")
		return
	_play(ShowPort.ACTION_FAIL_CONTINUE_GUIDE, "", true)
	_announce("%s 播放拒绝后续玩引导。" % note)


## 阶段 A 自动检查专用：结束等待并进入小游戏阶段，供后续业务检查衔接；正式意愿识别接入后改为 intent 驱动。
func begin_minigame_after_invite_play() -> Dictionary:
	if not is_invite_play_accepted():
		return _reject("尚未确认 PLAY，不能启动小游戏。")
	if _minigame_launch_locked or _stage == Stage.MINIGAME:
		return _reject("小游戏已在启动或运行中。")
	if _minigame == null:
		return _reject("小游戏接口未绑定。")
	_minigame_launch_locked = true
	_minigame_from_invite_play = true
	_enter_minigame()
	return _accept("玩家已同意，进入小游戏抽取。")


func debug_force_minigame_from_invite_listen() -> void:
	if not is_invite_listen():
		return
	_minigame_launch_locked = true
	_minigame_from_invite_play = false
	_enter_minigame()


## 自动检查：进入小游戏意愿等待阶段。
func debug_enter_invite_listen_for_check() -> void:
	_enter_invite_listen("自动检查：等待小游戏意愿。")


func debug_reset_standalone_for_check() -> void:
	_stage = Stage.STANDBY
	_result_phase = ""
	_invite_outcome_locked = false
	_minigame_launch_locked = false
	_minigame_from_invite_play = false
	_coins = 0
	_welcome_played = false
	_welcome_busy = false
	_paid_round_queued = false
	_welcome_play_count = 0
	_paid_round_count = 0
	_success_hold_until_ms = 0
	set_process(false)
	_clear_followup_welcome()
	_visitor = false
	_wait_show = false


func _enter_minigame() -> void:
	_stage = Stage.MINIGAME
	_result_phase = ""
	_token = _next_token()
	_wait_show = false
	if _minigame == null:
		_minigame_launch_locked = false
		_announce("小游戏接口缺失，无法启动。")
		_enter_standby_after_round("小游戏启动失败。")
		return
	_minigame.open_minigame(_token)
	_announce("进入小游戏抽取。")


func on_minigame_open_failed(note: String) -> void:
	if _stage != Stage.MINIGAME:
		return
	_minigame_launch_locked = false
	_minigame_from_invite_play = false
	_enter_standby_after_round(note)


func _enter_standby_after_round(note: String) -> void:
	if not _closing_from_hold_timeout:
		_note_round_closed()
	_success_hold_until_ms = 0
	set_process(false)
	_stage = Stage.STANDBY
	_result_phase = ""
	_success = false
	_after_result = "over"
	_invite_outcome_locked = false
	if _visitor:
		_play(ShowPort.ACTION_ATTRACT, ShowPort.SPEECH_ATTRACT, false)
	else:
		_play(ShowPort.ACTION_STANDBY, "", false)
	_announce(note)


func _enter_standby(visitor: bool) -> void:
	_stage = Stage.STANDBY
	_visitor = visitor
	_result_phase = ""
	_play(ShowPort.ACTION_STANDBY, "", false)
	_announce("机器空着，基础待机。")


func _play(action_id: String, speech_id: String, wait_for_it: bool) -> void:
	_token = _next_token()
	_wait_show = wait_for_it
	_show.play(action_id, speech_id, _token, wait_for_it)


func _next_token() -> int:
	_token += 1
	return _token


func _normalize_next(requested_next: String, success: bool) -> String:
	if (
		requested_next == "minigame"
		or requested_next == "retry"
		or requested_next == "over"
		or requested_next == "second_grab"
	):
		return requested_next
	if success:
		return "over"
	return "minigame"


func _announce(note: String) -> void:
	last_note = note
	situation_changed.emit()


func _accept(note: String) -> Dictionary:
	return {"ok": true, "note": note}


func _reject(note: String) -> Dictionary:
	last_note = note
	situation_changed.emit()
	return {"ok": false, "note": note}
