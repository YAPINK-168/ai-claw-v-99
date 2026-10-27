extends Node

## 投币开局后的操作表演：倾身 → 倾身待机；按住 A/D/W/S 正放左右看、向前看或仰头，松开倒放回待机；
## 抓取 → 下蹲 → 蹲着待机；往上抓 → 站起。「蹲着」不使用。

const CLIP_LEAN := "youyou_Basecontrol_lean"
const CLIP_LEAN_IDLE := "youyou_Basecontrol_keeplean"
const CLIP_LOOK_LEFT := "youyou_Basecontrol_lookleft"
const CLIP_LOOK_RIGHT := "youyou_Basecontrol_lookright"
const CLIP_LOOK_FORWARD := "youyou_control_lookforward"
const CLIP_LOOK_BACK := "youyou_control_lookback"
## set_look：-1 向左，1 向右，2 向前，3 仰头。
const LOOK_FORWARD := 2
const LOOK_BACK := 3
const CLIP_CROUCH := "youyou_Basecontrol_squat"
const CLIP_CROUCH_IDLE := "youyou_Basecontrol_keepSquat"
const CLIP_STAND := "youyou_Basecontrol_standup"
const LEAN_SPEED := 1.5
const CROUCH_SPEED := 1.5

signal stand_finished
signal lean_idle_began
signal script_clip_finished(clip_name: String)

enum Phase { OFF, LEAN_IN, LEAN_IDLE, LOOK, CROUCH_IN, CROUCH_IDLE, STAND, STOOD, SCRIPT }

var _actor: NewMotionSpriteActor
var _show: Node
var _phase := Phase.OFF
var _look_dir := 0
var _active_look := 0
var _script_clip := ""
## false：关节点结束后不回倾身待机，由调用方立刻接下一段对戏。
var _script_return_lean := true
## 对戏片脚点承接（干嘛 1–4 与切入/切回倾身待机）。
var _script_feet_carry := Vector2.ZERO
var _script_feet_valid := false
var _script_feet_pending := false
## 倾身切到待机后，最多再等这么多帧让边播边补结束，然后才去预载左右看和兜兜。
var _lean_cut_waits := 0


func setup(actor: NewMotionSpriteActor, show: Node) -> void:
	_actor = actor
	_show = show
	if not _actor.pose_clip_finished.is_connected(_on_pose_clip_finished):
		_actor.pose_clip_finished.connect(_on_pose_clip_finished)
	if not _actor.scrub_returned.is_connected(_on_scrub_returned):
		_actor.scrub_returned.connect(_on_scrub_returned)
	if not _actor.clip_started.is_connected(_on_clip_started_for_feet):
		_actor.clip_started.connect(_on_clip_started_for_feet)
	## 进场就钉住倾身待机。它有一百多帧，等到倾身那 0.7 秒再下才来不及。
	_preheat_lean_idle()


func on_command(action_id: String, _token: int, _wait_for_it: bool) -> void:
	match action_id:
		"paid_observe":
			_start_lean_in()
		"operating":
			if _phase == Phase.SCRIPT or _phase == Phase.LEAN_IN or _phase == Phase.LEAN_IDLE or _phase == Phase.LOOK:
				return
			if _phase == Phase.CROUCH_IN or _phase == Phase.CROUCH_IDLE or _phase == Phase.STAND or _phase == Phase.STOOD:
				return
			_start_lean_in()
		"grabbing":
			_start_crouch()


func force_off() -> void:
	_phase = Phase.OFF
	_look_dir = 0
	_active_look = 0
	_script_clip = ""
	_script_return_lean = true
	_script_feet_valid = false
	_script_feet_pending = false
	if _actor != null:
		if _actor.is_scrubbing():
			_actor.cancel_scrub()
		_actor.set_target_suppressed(false)
		if _actor.has_method("unpin_clips"):
			_actor.unpin_clips(PackedStringArray([
				CLIP_LOOK_LEFT, CLIP_LOOK_RIGHT, CLIP_LOOK_FORWARD, CLIP_LOOK_BACK, CLIP_LEAN,
				CLIP_CROUCH, CLIP_CROUCH_IDLE, CLIP_STAND,
			]))
		_preheat_lean_idle()


func set_look(dir: int) -> void:
	## 记下方向。对戏 / 倾身 / 下蹲 / 站起播着时不抢播。
	## 左右看 / 向前看 / 仰头：按住正放，松开或换向立刻从当前帧倒放。
	_look_dir = dir
	if _actor == null:
		return
	if _look_input_locked():
		return
	if _phase == Phase.LEAN_IDLE:
		if dir == 0:
			return
		if not _can_interrupt_for_look():
			return
		_begin_look(dir)
		return
	if _phase != Phase.LOOK:
		return
	if dir == _active_look:
		_actor.set_scrub_hold(true)
		return
	_actor.set_scrub_hold(false)


func _look_input_locked() -> bool:
	return (
		_phase == Phase.OFF
		or _phase == Phase.SCRIPT
		or _phase == Phase.LEAN_IN
		or _phase == Phase.CROUCH_IN
		or _phase == Phase.CROUCH_IDLE
		or _phase == Phase.STAND
		or _phase == Phase.STOOD
	)


func _can_interrupt_for_look() -> bool:
	if _actor == null:
		return false
	var cur := String(_actor.current_clip())
	if cur == "" or cur == CLIP_LEAN_IDLE:
		return true
	## 相位偶发不同步时，勿打断对戏等非待机片
	return cur == CLIP_LOOK_LEFT or cur == CLIP_LOOK_RIGHT or cur == CLIP_LOOK_FORWARD or cur == CLIP_LOOK_BACK


func blocks_script() -> bool:
	return (
		_phase == Phase.OFF
		or _phase == Phase.CROUCH_IN
		or _phase == Phase.CROUCH_IDLE
		or _phase == Phase.STAND
		or _phase == Phase.STOOD
	)


func prefetch_script_clips(clips: PackedStringArray) -> void:
	if _actor == null or clips.is_empty():
		return
	for i in clips.size():
		_actor.prefetch_clip(clips[i], i == 0)


func play_script_clip(clip: String, return_to_lean_idle: bool = true) -> bool:
	if _actor == null or clip == "" or blocks_script():
		return false
	if _actor.is_scrubbing():
		_actor.cancel_scrub()
	## 从倾身待机/左右看/上一段对戏切入时，记下脚点，播完对齐
	_capture_script_feet()
	_script_clip = clip
	_script_return_lean = return_to_lean_idle
	_phase = Phase.SCRIPT
	_active_look = 0
	_actor.set_target_suppressed(true)
	if _play(clip, false, "script"):
		_queue_or_apply_script_feet(clip)
		return true
	_script_clip = ""
	_script_return_lean = true
	_script_feet_valid = false
	_script_feet_pending = false
	_enter_lean_idle()
	return false


## 当前对戏片剩余秒数（按帧与 speed_scale）；非 SCRIPT 时返回 -1。
func script_seconds_left() -> float:
	if _phase != Phase.SCRIPT or _actor == null or _script_clip == "":
		return -1.0
	var total := 0
	if _actor.has_method("clip_frame_count"):
		total = int(_actor.clip_frame_count(_script_clip))
	if total <= 0:
		return -1.0
	var left_frames := maxi(0, total - 1 - _actor.frame)
	return float(left_frames) / (24.0 * maxf(_actor.speed_scale, 0.05))


func request_stand() -> bool:
	if _actor == null or _phase != Phase.CROUCH_IDLE:
		return false
	_phase = Phase.STAND
	_look_dir = 0
	_active_look = 0
	_actor.set_target_suppressed(true)
	if not _play(CLIP_STAND, false, "stand"):
		_phase = Phase.STOOD
		return false
	return true


func is_result_ready() -> bool:
	return _phase == Phase.STOOD or _phase == Phase.OFF


func label() -> String:
	match _phase:
		Phase.LEAN_IN:
			return "倾身"
		Phase.LEAN_IDLE:
			return "倾身待机"
		Phase.LOOK:
			if _active_look == LOOK_FORWARD:
				return "向前看"
			if _active_look == LOOK_BACK:
				return "仰头"
			return "向左看" if _active_look < 0 else "向右看"
		Phase.CROUCH_IN:
			return "下蹲"
		Phase.CROUCH_IDLE:
			return "蹲着待机"
		Phase.STAND:
			return "站起"
		Phase.STOOD:
			return "已站起"
		Phase.SCRIPT:
			return _script_clip
		_:
			return ""


func _start_lean_in() -> void:
	_phase = Phase.LEAN_IN
	_look_dir = 0
	_active_look = 0
	if _actor != null:
		## 倾身这几帧里只补倾身待机。左右看留到待机已经接上之后，避免把带宽抢走。
		_preheat_lean_idle()
		if _actor.has_method("focus_clip"):
			_actor.focus_clip(CLIP_LEAN)
	if _actor != null and _actor.is_scrubbing():
		_actor.cancel_scrub()
	_actor.set_target_suppressed(true)
	if not _play(CLIP_LEAN, false, "paid_observe"):
		_enter_lean_idle()
		_finish_wait()


func _start_crouch() -> void:
	_script_clip = ""
	_phase = Phase.CROUCH_IN
	_look_dir = 0
	_active_look = 0
	if _actor != null:
		if _actor.has_method("unpin_clips"):
			_actor.unpin_clips(PackedStringArray([CLIP_LOOK_LEFT, CLIP_LOOK_RIGHT, CLIP_LOOK_FORWARD, CLIP_LOOK_BACK, CLIP_LEAN]))
		if _actor.has_method("focus_clip"):
			_actor.focus_clip(CLIP_CROUCH)
		_actor.prefetch_clip(CLIP_CROUCH_IDLE, true)
	if _actor != null and _actor.is_scrubbing():
		_actor.cancel_scrub()
	_actor.set_target_suppressed(true)
	if not _play(CLIP_CROUCH, false, "grabbing"):
		_enter_crouch_idle()
		return
	if _actor.current_clip() != CLIP_CROUCH and _actor.has_method("hold_current_frame"):
		_actor.hold_current_frame()


func _enter_lean_idle() -> void:
	_phase = Phase.LEAN_IDLE
	_active_look = 0
	_lean_cut_waits = 0
	_play(CLIP_LEAN_IDLE, true, "operating")
	## 切换这一帧只接待机。左右看和兜兜入场等下一帧、并且待机不再边播边补时再开。
	call_deferred("_after_lean_idle_cut")


func _after_lean_idle_cut() -> void:
	if _phase != Phase.LEAN_IDLE:
		return
	_lean_cut_waits += 1
	if (
		_lean_cut_waits < 240
		and _actor != null
		and _actor.has_method("is_clip_streaming")
		and bool(_actor.is_clip_streaming(CLIP_LEAN_IDLE))
	):
		call_deferred("_after_lean_idle_cut")
		return
	_prefetch_operate_looks()
	lean_idle_began.emit()
	if _look_dir != 0:
		set_look(_look_dir)


func _preheat_lean_idle() -> void:
	if _actor == null or not _actor.has_method("pin_clips"):
		return
	_actor.pin_clips(PackedStringArray([CLIP_LEAN_IDLE]))


func _prefetch_operate_looks() -> void:
	if _actor == null:
		return
	if _actor.has_method("pin_clips"):
		_actor.pin_clips(PackedStringArray([
			CLIP_LOOK_LEFT, CLIP_LOOK_RIGHT, CLIP_LOOK_FORWARD, CLIP_LOOK_BACK, CLIP_LEAN_IDLE,
		]))
	_actor.prefetch_clip(CLIP_LOOK_LEFT, false)
	_actor.prefetch_clip(CLIP_LOOK_RIGHT, false)
	_actor.prefetch_clip(CLIP_LOOK_FORWARD, false)
	_actor.prefetch_clip(CLIP_LOOK_BACK, false)


func _enter_crouch_idle() -> void:
	_phase = Phase.CROUCH_IDLE
	if _actor != null:
		_actor.prefetch_clip(CLIP_STAND, true)
	_play(CLIP_CROUCH_IDLE, true, "grabbing")


func _begin_look(dir: int) -> void:
	_active_look = dir
	_phase = Phase.LOOK
	var clip := CLIP_LOOK_RIGHT
	var action := "look_right"
	if dir < 0:
		clip = CLIP_LOOK_LEFT
		action = "look_left"
	elif dir == LOOK_FORWARD:
		clip = CLIP_LOOK_FORWARD
		action = "look_forward"
	elif dir == LOOK_BACK:
		clip = CLIP_LOOK_BACK
		action = "look_back"
	_note(action, clip)
	## 立刻打断倾身待机，再切左右看（加载中也先停住，不继续播待机循环）
	if _actor.has_method("hold_current_frame"):
		_actor.hold_current_frame()
	if _actor.has_method("focus_clip"):
		_actor.focus_clip(clip)
	_actor.prefetch_clip(clip, true)
	_actor.prefetch_clip(CLIP_LEAN_IDLE, true)
	if not _actor.begin_scrub(clip):
		_phase = Phase.LEAN_IDLE
		_active_look = 0
		_play(CLIP_LEAN_IDLE, true, "operating")
		return
	_actor.set_scrub_hold(true)


func _on_pose_clip_finished(clip_name: String) -> void:
	match _phase:
		Phase.LEAN_IN:
			if clip_name != CLIP_LEAN:
				return
			_enter_lean_idle()
			_finish_wait()
		Phase.CROUCH_IN:
			if clip_name != CLIP_CROUCH:
				return
			_enter_crouch_idle()
		Phase.STAND:
			if clip_name != CLIP_STAND:
				return
			_phase = Phase.STOOD
			# 下一帧再出结果，避免站起 animation_finished 回调里直接切结果片，把结果动作当成已经播完。
			call_deferred("_emit_stand_finished")
		Phase.SCRIPT:
			if clip_name != _script_clip:
				return
			var done := _script_clip
			var back_to_lean := _script_return_lean
			_capture_script_feet()
			_script_clip = ""
			_script_return_lean = true
			script_clip_finished.emit(done)
			## 默认可回倾身待机；链式对戏由调用方关掉 return_to_lean，脚点仍承接
			if back_to_lean:
				_enter_lean_idle()
				_queue_or_apply_script_feet(CLIP_LEAN_IDLE)


func _on_clip_started_for_feet(clip_name: String, _is_bridge: bool) -> void:
	if not _script_feet_pending:
		return
	if clip_name != _script_clip and not (
		_phase == Phase.LEAN_IDLE and clip_name == CLIP_LEAN_IDLE
	):
		return
	_script_feet_pending = false
	_apply_script_feet()


func _on_scrub_returned() -> void:
	if _phase != Phase.LOOK:
		return
	var next := _look_dir
	_phase = Phase.LEAN_IDLE
	_active_look = 0
	_play(CLIP_LEAN_IDLE, true, "operating")
	if next != 0:
		set_look(next)


func _play(clip: String, loop: bool, action_id: String) -> bool:
	if _actor == null:
		return false
	_note(action_id, clip)
	if not _actor.play_clip(clip, loop, false):
		return false
	if clip == CLIP_LEAN:
		_actor.speed_scale = LEAN_SPEED
	elif clip == CLIP_CROUCH:
		_actor.speed_scale = CROUCH_SPEED
	return true


func _capture_script_feet() -> void:
	_script_feet_valid = false
	_script_feet_pending = false
	if _actor == null or not _actor.has_method("capture_feet_screen"):
		return
	if _actor.current_clip() == "":
		return
	_script_feet_carry = _actor.capture_feet_screen()
	_script_feet_valid = true


func _queue_or_apply_script_feet(expected_clip: String) -> void:
	if not _script_feet_valid or _actor == null:
		return
	if String(_actor.current_clip()) == expected_clip:
		_apply_script_feet()
		return
	_script_feet_pending = true


func _apply_script_feet() -> void:
	if not _script_feet_valid or _actor == null:
		return
	if _actor.has_method("align_feet_to_screen"):
		_actor.align_feet_to_screen(_script_feet_carry)
	_script_feet_valid = false
	_script_feet_pending = false


func _note(action_id: String, clip: String) -> void:
	if _show != null and _show.has_method("note_clip"):
		_show.call("note_clip", action_id, clip)


func _emit_stand_finished() -> void:
	if _phase != Phase.STOOD:
		return
	stand_finished.emit()


func _finish_wait() -> void:
	if _show != null and _show.has_method("finish_pose_wait"):
		_show.call("finish_pose_wait")
