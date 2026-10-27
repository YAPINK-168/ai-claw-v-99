extends Node

## 第一局：柚柚倾身待机起；兜兜「看那边」入场 → 循环兜兜待机。
## 看那边倒数第 5 秒柚柚播「兜兜你干嘛-1」；吓到倒数第 1 秒兜兜打断待机播战术指导02。
## 吓到播完直接接「兜兜你干嘛-2」（明明就是捣乱），不经倾身待机；捣乱后再回倾身待机。
## 干嘛 1–4 与切入/切回倾身待机均脚点承接上一段结束位。
## 捣乱结束后：兜兜打断待机播「抓不到抓不到（兜兜）」→ 待机 →「就这水平04」。
## 就这水平倒数第 1 秒：柚柚打断倾身待机播「兜兜你干嘛-3」，播完直接接「兜兜你干嘛-4」（不经倾身待机）。
## 就这水平播完：兜兜循环待机（intro_wait）等抓取结果；成功只播「纯属运气（兜兜）」，播完离场。
## 按下抓取：兜兜打断当前片子，立刻播「路过假装捂眼睛」。
## A/D 仍可记方向，但不打断柚柚对戏片。
## 第二套（第 2 局起）：兜兜「爬行入场」播完后，按随机顺序连播射弹弓失败、耍帅、跳舞、跑来跑去捣乱、抓不到抓不到、拍苍蝇，中间不插待机。
## 失败收尾：掉咯 →（等柚柚引导）→ 我看算了吧 → 立刻跑出离场。
## 柚柚播完引导小游戏，或第二局抓娃娃的续玩引导：兜兜接「我看算了吧」再跑出。
## 掉咯之后如果玩家重开：不等引导，立刻跑出唱，入场仍等到下一局倾身待机。

const VIEWPORT := Vector2(1920, 1080)
const IDLE_HOLD_SEC := 3.0
## 入场时身体左缘贴在右屏缘外侧，只留一点余量，避免起步太远入场拖太久。
const OFFSCREEN_MARGIN := 8.0
const CLIP_LOOK_THERE := "doudou_come_1"
const CLIP_SCARE := "youyou_control2_1"
const CLIP_MEDDLE := "youyou_control2_2"
const CLIP_ANGRY := "youyou_control2_3"
const CLIP_CALM := "youyou_control2_4"
const CLIP_TACTICS := "doudou_Attract_12"
const CLIP_SING := "doudou_Attract_9"
const CLIP_TAUNT := "doudou_Attract_6"
## 看那边剩余该秒数时，柚柚播你干嘛-1（按动作播放时间，含 speed_scale）。
const LOOK_SCARE_LEAD_SEC := 5.0
## 被吓到剩余该秒数时，兜兜打断待机播战术指导。
const SCARE_TACTICS_LEAD_SEC := 1.0
## 「就这水平」剩余该秒数时，柚柚打断倾身待机播生气。
const TAUNT_ANGRY_LEAD_SEC := 1.0
const TAUNT_IDLE_SEC := 1.2
const CLIP_ENTRANCE := "doudou_come_2"
const CLIP_IDLE := "doudou_Idlebreath"
const CLIP_HARASS := "doudou_Attract_5"
const CLIP_MISS := "doudou_Attract_9"
## 第二局入场之后的捣乱池，播完打乱再来一轮，中间不插待机。
const ROUND2_CLIPS: PackedStringArray = [
	"doudou_Attract_2",
	"doudou_Attract_3",
	"doudou_Attract_4",
	"doudou_Attract_5",
	"doudou_Attract_9",
	"拍苍蝇",
]
const CLIP_GRAB := "doudou_Attract_7"
const CLIP_SUCCESS := "doudou_success"
## 失败结果：掉咯掉咯
const CLIP_FAIL := "doudou_fail"
## 失败引导后：我看算了吧 → 立刻跑出
const CLIP_GIVE_UP := "doudou_guideGame"
const CLIP_RUN := "doudou_run"
const GUIDE_CLIPS: PackedStringArray = [
	"youyou_guideGame",
	"youyou_guideNext_2",
]
## 第二局抓娃娃播完后续玩引导（成功那条）。第一局成功仍只播纯属运气后离场。
const CLIP_SECOND_ROUND_GUIDE := "youyou_guideNext_1"

var _actor: NewMotionSpriteActor
var _pose: Node
var _active := false
var _round_no := -1
var _phase := ""
var _playing := ""
var _want_clip := ""
var _want_loop := false
var _want_offscreen := false
var _grab_armed := false
var _result := 0
var _idle_left := 0.0
var _idle_frame := 0
var _run_frame := -1
var _carry_valid := false
var _carry := Vector2.ZERO
var _bounds_cache := {}
var _idle_slot := 0
var _guide_done := false
var _first_round := false
var _scare_sent := false
var _tactics_from_scare := false
var _angry_from_taunt := false
var _youyou_step := ""
var _want_authored := false
var _pending_sing := false
var _round2_order: Array[String] = []
var _round2_index := 0
## 失败后玩家已重开：先把跑出唱完，入场先记着。
var _exit_for_restart := false
## 第二局成功：纯属运气之后先留在场上，等柚柚续玩引导再接我看算了吧。
var _await_round_tail := false
var _entrance_pending := false
var _entrance_round := 0


func setup(actor: NewMotionSpriteActor, pose: Node = null) -> void:
	_actor = actor
	if _actor == null:
		return
	_actor.visible = false
	_actor.set_target_suppressed(true)
	if not _actor.pose_clip_finished.is_connected(_on_clip_finished):
		_actor.pose_clip_finished.connect(_on_clip_finished)
	_pose = pose
	if _pose != null and _pose.has_signal("script_clip_finished"):
		if not _pose.is_connected("script_clip_finished", _on_youyou_script_finished):
			_pose.connect("script_clip_finished", _on_youyou_script_finished)


func on_operate_idle(round_no: int) -> void:
	if round_no <= 0:
		dismiss()
		return
	if round_no == 1:
		if _active and _round_no == 1:
			return
		_begin_first_round()
		return
	if _active and _round_no == round_no:
		return
	if _defer_entrance_for_run():
		_entrance_round = round_no
		_entrance_pending = true
		return
	_begin_later_round(round_no)


func _begin_later_round(round_no: int) -> void:
	_round_no = round_no
	_active = true
	_phase = ""
	_playing = ""
	_want_clip = ""
	_grab_armed = false
	_result = 0
	_idle_left = 0.0
	_carry_valid = false
	_carry = Vector2.ZERO
	_idle_slot = 0
	_guide_done = false
	_first_round = false
	_exit_for_restart = false
	_entrance_pending = false
	_entrance_round = 0
	_await_round_tail = false
	_round2_order.clear()
	_round2_index = 0
	_request(CLIP_ENTRANCE, false, "entrance", true)


func _defer_entrance_for_run() -> bool:
	if not _exit_for_restart:
		return false
	return (
		_phase == "fail"
		or _phase == "fail_idle"
		or _phase == "give_up"
		or _phase == "run_out"
		or _want_clip == CLIP_FAIL
		or _want_clip == CLIP_RUN
	)


func _start_pending_entrance() -> void:
	if not _entrance_pending:
		return
	var round_no := _entrance_round
	_entrance_pending = false
	_exit_for_restart = false
	_begin_later_round(round_no)


func _begin_first_round() -> void:
	## 第一局：柚柚已在倾身待机；兜兜看那边入场 → 待机循环，再与柚柚对戏。
	## A/D 不打断柚柚对戏；按 G 双方立刻打断，走第二套抓取后流程。
	_round_no = 1
	_active = true
	_phase = ""
	_playing = ""
	_want_clip = ""
	_grab_armed = false
	_result = 0
	_idle_left = 0.0
	_carry_valid = false
	_carry = Vector2.ZERO
	_first_round = true
	_scare_sent = false
	_tactics_from_scare = false
	_angry_from_taunt = false
	_youyou_step = ""
	_pending_sing = false
	_await_round_tail = false
	if _pose != null and _pose.has_method("prefetch_script_clips"):
		_pose.prefetch_script_clips(PackedStringArray([CLIP_SCARE, CLIP_MEDDLE]))
	## 看那边从画面右缘外入场，后续动作脚点接这段结束位
	_request(CLIP_LOOK_THERE, false, "look_in", true)


func notify_grab_pressed() -> void:
	if not _active or _result != 0:
		return
	if _phase == "grab" or _playing == CLIP_GRAB or _want_clip == CLIP_GRAB:
		_grab_armed = true
		return
	_grab_armed = true
	## 预载捂眼睛和结果片，按下后能马上接上
	if _actor != null:
		_actor.prefetch_clip(CLIP_GRAB, true)
		_actor.prefetch_clip(CLIP_SUCCESS, true)
		_actor.prefetch_clip(CLIP_FAIL, true)
	## 打断当前片子，立刻播路过假装捂眼睛
	_request(CLIP_GRAB, false, "grab", false)


func notify_result(player_success: bool) -> void:
	if not _active:
		return
	if _phase == "success" or _phase == "run_out" or _phase == "left":
		return
	if _phase == "fail" or _phase == "fail_idle" or _phase == "give_up" or _phase == "run_out":
		return
	_result = 1 if player_success else 2
	_first_round = false
	## 捂眼睛正在播：等播完再接（grab 结束分支会转 success/fail）
	if _playing == CLIP_GRAB:
		return
	## 捂眼睛只在排队、还没开播：取消排队，立刻播结果（否则会一直卡在 want_clip==GRAB）
	if _want_clip == CLIP_GRAB:
		_want_clip = ""
	if _result == 2:
		_request(CLIP_FAIL, false, "fail", false)
		return
	## 成功：立刻播「纯属运气（兜兜）」→ doudou_success
	_request(CLIP_SUCCESS, false, "success", false)


func notify_player_restarted() -> void:
	## 掉咯之后重开：先跑出唱。入场不接在跑出后面，仍等下一局倾身待机。
	if not _active or _result != 2:
		return
	if _phase == "left" or _phase == "entrance" or _phase == "look_in" or _phase == "round2":
		return
	_exit_for_restart = true
	if _phase == "run_out" or _want_clip == CLIP_RUN:
		return
	if _phase == "fail" or _want_clip == CLIP_FAIL:
		if _actor != null:
			_actor.prefetch_clip(CLIP_RUN, true)
		return
	_request(CLIP_RUN, false, "run_out", false)


func notify_youyou_clip_finished(clip_name: String) -> void:
	if clip_name == "youyou_guideGame":
		notify_guide_game_finished()
		return
	if not _active or not _is_youyou_tail(clip_name):
		return
	_guide_done = true
	if _exit_for_restart:
		return
	_start_give_up()


func notify_guide_game_finished() -> void:
	## 柚柚引导小游戏整段播完：兜兜接「我看算了吧」，播完立刻跑出。
	_guide_done = true
	prefetch_exit_line()
	if _exit_for_restart:
		return
	_start_give_up()


func prefetch_exit_line() -> void:
	if _actor == null:
		return
	_actor.prefetch_clip(CLIP_GIVE_UP, true)
	_actor.prefetch_clip(CLIP_RUN, true)


func ensure_give_up_exit() -> void:
	## 10 秒没人回应时补上离场：还没开口就先「我看算了吧」，再说完接跑出。
	if not _active or _result == 0 or _exit_for_restart:
		return
	_guide_done = true
	_start_give_up()


func needs_exit() -> bool:
	if not _active or _result == 0 or is_leaving():
		return false
	return (
		_phase == "fail"
		or _phase == "fail_idle"
		or _phase == "await_tail"
		or _phase == "success"
	)


func is_leaving() -> bool:
	return (
		_phase == "give_up"
		or _phase == "run_out"
		or _want_clip == CLIP_GIVE_UP
		or _want_clip == CLIP_RUN
	)


func _is_youyou_tail(clip_name: String) -> bool:
	if clip_name in GUIDE_CLIPS:
		return true
	return clip_name == CLIP_SECOND_ROUND_GUIDE and _round_no >= 2


func _start_give_up() -> void:
	if not _active or _exit_for_restart or not _guide_done:
		return
	if is_leaving() or _phase == "left":
		return
	## 掉咯 / 纯属运气还在播就等它播完，播完再接我看算了吧。
	if _blocking_result_clip():
		return
	_await_round_tail = false
	_request(CLIP_GIVE_UP, false, "give_up", false)


func _blocking_result_clip() -> bool:
	if _phase == "fail" or _playing == CLIP_FAIL or _want_clip == CLIP_FAIL:
		return _clip_still_playing(CLIP_FAIL)
	if _phase == "success" or _playing == CLIP_SUCCESS or _want_clip == CLIP_SUCCESS:
		return _clip_still_playing(CLIP_SUCCESS)
	return false


func _clip_still_playing(clip: String) -> bool:
	if _want_clip == clip:
		return true
	if _actor != null and _actor.has_method("current_clip"):
		if String(_actor.current_clip()) != clip:
			return false
		if _actor.has_method("is_playing") and not _actor.is_playing():
			return false
		return true
	return _playing == clip


func dismiss() -> void:
	_active = false
	_round_no = -1
	_phase = ""
	_playing = ""
	_want_clip = ""
	_grab_armed = false
	_result = 0
	_idle_left = 0.0
	_idle_slot = 0
	_guide_done = false
	_first_round = false
	_scare_sent = false
	_tactics_from_scare = false
	_angry_from_taunt = false
	_youyou_step = ""
	_pending_sing = false
	_round2_order.clear()
	_round2_index = 0
	_exit_for_restart = false
	_entrance_pending = false
	_entrance_round = 0
	_await_round_tail = false
	_carry_valid = false
	if _actor != null:
		_actor.stop_playback()
		_actor.visible = false
		if _actor.has_method("discard_unused_clips"):
			_actor.discard_unused_clips()


func _process(_delta: float) -> void:
	_pump_request()
	if not _active or _actor == null:
		return
	if _guide_done:
		_start_give_up()
	if _first_round:
		_tick_first_round(_delta)
	if _phase == "run_out":
		_hide_broken_run_frame()
	## 抓取已按下且兜兜在待机：立刻打断，播路过假装捂眼睛（不等这一轮待机播完）
	if _grab_armed and _result == 0 and _playing == CLIP_IDLE and _want_clip == "":
		_request(CLIP_GRAB, false, "grab", false)
		return
	if _first_round and _phase == "post_sing_idle" and _playing == CLIP_IDLE and not _grab_armed:
		_idle_left -= _delta
		if _idle_left <= 0.0:
			_capture_visible()
			if _pose != null and _pose.has_method("prefetch_script_clips"):
				_pose.prefetch_script_clips(PackedStringArray([CLIP_ANGRY, CLIP_CALM]))
			_request(CLIP_TAUNT, false, "taunt", false)
		return
	if (
		_phase != "idle"
		and _phase != "idle_wait"
		and _phase != "fail_idle"
		and _phase != "intro_idle"
		and _phase != "intro_wait"
	):
		return
	if _phase != "idle" or _grab_armed or _playing != CLIP_IDLE:
		return
	_idle_left -= _delta
	if _idle_left > 0.0:
		return
	_capture_visible()
	_advance_after_idle()


func _advance_after_idle() -> void:
	if _idle_slot == 1:
		_request(CLIP_HARASS, false, "harass", false)
		return
	if _idle_slot == 2:
		_request(CLIP_MISS, false, "miss", false)
		return
	_request(CLIP_IDLE, true, "idle_wait", false)


func _shuffle_round2() -> void:
	_round2_order.clear()
	var pool: Array[String] = []
	for clip_name in ROUND2_CLIPS:
		pool.append(clip_name)
	while not pool.is_empty():
		var pick := randi() % pool.size()
		_round2_order.append(pool[pick])
		pool.remove_at(pick)
	_round2_index = 0


func _begin_round2_playlist() -> void:
	_shuffle_round2()
	_play_round2_next()


func _play_round2_next() -> void:
	if _result != 0 or _grab_armed:
		return
	if _round2_index >= _round2_order.size():
		_shuffle_round2()
	if _round2_order.is_empty():
		return
	var clip_name := _round2_order[_round2_index]
	_round2_index += 1
	_request(clip_name, false, "round2", false)


func _doudou_is_idle() -> bool:
	if _playing == CLIP_IDLE:
		return true
	return (
		_phase == "idle"
		or _phase == "idle_wait"
		or _phase == "intro_idle"
		or _phase == "intro_wait"
		or _phase == "idle_for_sing"
		or _phase == "post_sing_idle"
		or _phase == "fail_idle"
	)


func _hold_idle(slot: int) -> void:
	_idle_slot = slot
	_idle_left = IDLE_HOLD_SEC
	_request(CLIP_IDLE, true, "idle", false)


func _on_clip_finished(clip_name: String) -> void:
	if not _active or _want_loop or clip_name != _playing:
		return
	_capture_visible()
	_playing = ""
	if _first_round and _advance_intro(clip_name):
		return
	if (
		_result == 2
		and _phase != "fail"
		and _phase != "fail_idle"
		and _phase != "give_up"
		and _phase != "run_out"
		and _phase != "left"
	):
		_request(CLIP_FAIL, false, "fail", false)
		return
	## 非待机片播完时若抓取已按下，接捂眼睛（待机中途按下已在 notify 里打断）
	if (
		_grab_armed
		and _result != 2
		and _phase != "grab"
		and _phase != "give_up"
		and _phase != "success"
		and _phase != "run_out"
		and _phase != "left"
	):
		_request(CLIP_GRAB, false, "grab", false)
		return
	match _phase:
		"entrance":
			_begin_round2_playlist()
		"round2":
			if _result == 0 and not _grab_armed:
				_play_round2_next()
		"harass":
			_hold_idle(2)
		"miss":
			_request(CLIP_IDLE, true, "idle_wait", false)
		"grab":
			if _result == 1:
				_request(CLIP_SUCCESS, false, "success", false)
			elif _result == 2:
				_request(CLIP_FAIL, false, "fail", false)
		"success":
			if _round_no >= 2:
				if _actor != null:
					_actor.prefetch_clip(CLIP_GIVE_UP, true)
					_actor.prefetch_clip(CLIP_RUN, false)
				if _guide_done:
					_request(CLIP_GIVE_UP, false, "give_up", false)
				else:
					_await_round_tail = true
					_request(CLIP_IDLE, true, "await_tail", false)
				return
			_phase = "left"
			if _actor != null:
				_actor.visible = false
		"run_out":
			_phase = "left"
			if _actor != null:
				_actor.visible = false
			_start_pending_entrance()
		"fail":
			if _exit_for_restart:
				_request(CLIP_RUN, false, "run_out", false)
				return
			if _guide_done:
				_request(CLIP_GIVE_UP, false, "give_up", false)
			else:
				_request(CLIP_IDLE, true, "fail_idle", false)
		"give_up":
			## 我看算了吧播完立刻接跑出
			_request(CLIP_RUN, false, "run_out", false)


func _request(clip: String, loop: bool, phase: String, offscreen: bool, authored: bool = false) -> void:
	if _actor == null:
		return
	if phase != "entrance" and phase != "look_in":
		_capture_visible()
	## 结果片禁止按「无脚点承接」甩到屏外，否则纯属运气/掉了播了也看不见
	if phase == "success" or phase == "fail" or phase == "give_up" or phase == "run_out":
		offscreen = false
		if not _carry_valid:
			authored = true
	_phase = phase
	_playing = ""
	_want_loop = loop
	_want_offscreen = offscreen
	_want_authored = authored
	_want_clip = clip
	## 入场要从画面外走进来。片子往往要下一帧才加载完，先显示会把上一局停在场内的那一帧闪出来。
	_actor.visible = not offscreen
	if _actor.has_method("focus_clip"):
		_actor.focus_clip(clip)
	else:
		_actor.prefetch_clip(clip, true)
	_prefetch_followup(phase)
	_pump_request()


func _prefetch_followup(phase: String) -> void:
	if _actor == null:
		return
	var nxt := ""
	match phase:
		"look_in":
			## 看那边期间钉住并预载待机+战术指导，避免播完后才加载导致接不上
			if _actor.has_method("pin_clips"):
				_actor.pin_clips(PackedStringArray([CLIP_IDLE, CLIP_TACTICS]))
			_actor.prefetch_clip(CLIP_IDLE, true)
			_actor.prefetch_clip(CLIP_TACTICS, false)
			return
		"intro_idle":
			nxt = CLIP_TACTICS
		"tactics":
			nxt = CLIP_SING
		"sing":
			nxt = CLIP_IDLE
		"post_sing_idle":
			nxt = CLIP_TAUNT
		"taunt", "harass", "miss":
			nxt = CLIP_IDLE
		"entrance":
			if _actor.has_method("pin_clips"):
				_actor.pin_clips(ROUND2_CLIPS)
			for clip_name in ROUND2_CLIPS:
				_actor.prefetch_clip(clip_name, false)
			return
		"round2":
			if _round2_index < _round2_order.size():
				nxt = _round2_order[_round2_index]
		"idle":
			if _idle_slot == 1:
				nxt = CLIP_HARASS
			elif _idle_slot == 2:
				nxt = CLIP_MISS
			else:
				nxt = CLIP_GRAB
		"idle_wait":
			nxt = CLIP_GRAB
		"intro_wait":
			nxt = CLIP_SUCCESS
		"grab":
			nxt = CLIP_SUCCESS
		"fail", "fail_idle":
			nxt = CLIP_GIVE_UP
			_actor.prefetch_clip(CLIP_RUN, false)
		"give_up":
			nxt = CLIP_RUN
	if nxt != "":
		_actor.prefetch_clip(nxt, true)


func _pump_request() -> void:
	if _actor == null or _want_clip == "":
		return
	if not _actor.has_clip_ready(_want_clip):
		return
	var clip := _want_clip
	var loop := _want_loop
	var offscreen := _want_offscreen
	var authored := _want_authored
	_want_clip = ""
	_want_offscreen = false
	_want_authored = false
	_align_start(clip, offscreen, authored)
	if not _actor.play_clip(clip, loop, false):
		return
	_actor.visible = true
	_playing = clip
	_idle_frame = _actor.frame
	_run_frame = -1


func _idle_wrapped() -> bool:
	if _actor == null or _playing != CLIP_IDLE:
		return false
	var current := _actor.frame
	var wrapped := current < _idle_frame and _idle_frame > 2
	_idle_frame = current
	return wrapped


func _hide_broken_run_frame() -> void:
	if _actor == null or _actor.frame == _run_frame:
		return
	_run_frame = _actor.frame
	var tex := _actor.current_frame_texture()
	var layout := _visual_layout(_playing, _actor.frame, tex)
	if layout.is_empty():
		return
	var width_limit := 900.0 * float(layout.get("full_w", 1920)) / 1920.0
	var opaque_w := float(layout.get("max_x", 0)) - float(layout.get("min_x", 0))
	if opaque_w <= width_limit:
		return
	_playing = ""
	_phase = "left"
	_actor.stop_playback()
	_actor.visible = false


func _align_start(clip: String, offscreen: bool, authored: bool = false) -> void:
	var tex := _actor.clip_frame_texture(clip, 0)
	var layout := _visual_layout(clip, 0, tex)
	if layout.is_empty():
		return
	if authored:
		_actor.set_frame_offset(Vector2.ZERO)
		return
	var scale := _stage_scale(tex, clip)
	if offscreen or not _carry_valid:
		## 用身体左缘对齐到屏右外，起始帧整段在画面外再走进来
		var local_left := _local_on_canvas(layout, Vector2(float(layout.get("min_x", 0)), 0.0), scale).x
		var offset_x := VIEWPORT.x + OFFSCREEN_MARGIN - VIEWPORT.x * 0.5 - local_left
		_actor.set_frame_offset(Vector2(offset_x, 0.0))
		return
	var feet := Vector2(float(layout.get("feet_x", 0)), float(layout.get("feet_y", 0)))
	var local := _local_on_canvas(layout, feet, scale)
	_actor.set_frame_offset(_carry - VIEWPORT * 0.5 - local)


func _capture_visible() -> void:
	if _actor == null or _playing == "":
		return
	var tex := _actor.current_frame_texture()
	var layout := _visual_layout(_playing, _actor.frame, tex)
	if layout.is_empty():
		return
	## 人跑出画后末帧全透明，脚点会落到裁图左上角，下一段（跑出）就被抬到画面上方。
	var body_h := float(layout.get("body_h", 0.0))
	var body_w := float(layout.get("body_w", 0.0))
	if body_h < 24.0 or body_w < 24.0:
		return
	var scale := _stage_scale(tex, _playing)
	var feet := Vector2(float(layout.get("feet_x", 0)), float(layout.get("feet_y", 0)))
	var local := _local_on_canvas(layout, feet, scale)
	_carry = VIEWPORT * 0.5 + _actor.frame_offset + local
	_carry_valid = true


func _visual_layout(clip: String, index: int, tex: Texture2D) -> Dictionary:
	if _actor != null and _actor.has_method("frame_layout"):
		var layout: Dictionary = _actor.frame_layout(clip, index)
		if not layout.is_empty():
			return layout
	if tex == null:
		return {}
	var box := _opaque_box(tex)
	return {
		"offset": Vector2.ZERO,
		"full_w": tex.get_width(),
		"full_h": tex.get_height(),
		"crop_w": tex.get_width(),
		"crop_h": tex.get_height(),
		"min_x": int(box.get("min_x", 0)),
		"max_x": int(box.get("max_x", 0)),
		"feet_x": int(box.get("feet_x", 0)),
		"feet_y": int(box.get("feet_y", 0)),
	}


func _local_on_canvas(layout: Dictionary, point: Vector2, scale: float) -> Vector2:
	var origin := Vector2(float(layout.get("crop_w", 0)), float(layout.get("crop_h", 0))) * 0.5
	var draw: Vector2 = layout.get("offset", Vector2.ZERO)
	return (point - origin + draw) * scale


func _stage_scale(tex: Texture2D, clip_name: String) -> float:
	if _actor != null and _actor.has_method("uniform_scale_for_texture"):
		return float(_actor.uniform_scale_for_texture(tex, clip_name))
	var fit := 1.0
	if _actor != null:
		fit = _actor.frame_fit_scale
	return VIEWPORT.y / float(tex.get_height()) * fit


func _opaque_box(tex: Texture2D) -> Dictionary:
	var key := str(tex.get_rid())
	if _bounds_cache.has(key):
		return _bounds_cache[key]
	var image := tex.get_image()
	var box := {
		"min_x": 0,
		"max_x": tex.get_width() - 1,
		"feet_x": int(tex.get_width() / 2),
		"feet_y": tex.get_height() - 1,
	}
	if image == null or image.is_empty():
		return box
	var width := image.get_width()
	var height := image.get_height()
	var small := image
	var sample_w := 96
	if width > sample_w:
		small = image.duplicate()
		var sample_h := maxi(1, int(round(float(height) * float(sample_w) / float(width))))
		small.resize(sample_w, sample_h, Image.INTERPOLATE_NEAREST)
	var scale_x := float(width) / float(small.get_width())
	var scale_y := float(height) / float(small.get_height())
	var min_x := width
	var max_x := -1
	var max_y := -1
	for y in range(small.get_height()):
		for x in range(small.get_width()):
			if small.get_pixel(x, y).a <= 0.06:
				continue
			var px := int(float(x) * scale_x)
			var py := int(float(y) * scale_y)
			min_x = mini(min_x, px)
			max_x = maxi(max_x, px)
			max_y = maxi(max_y, py)
	if max_x < 0:
		return box
	box = {
		"min_x": min_x,
		"max_x": max_x,
		"feet_x": int((min_x + max_x) / 2),
		"feet_y": max_y,
	}
	_bounds_cache[key] = box
	return box


func _tick_first_round(_delta: float) -> void:
	## 捣乱已结束且兜兜在待机：打断待机唱歌「抓不到抓不到」
	if (
		_youyou_step == "meddle_done"
		and _pending_sing
		and (_phase == "idle_for_sing" or _phase == "intro_idle")
		and _want_clip == ""
		and (_playing == CLIP_IDLE or _playing == "")
	):
		_pending_sing = false
		_request(CLIP_SING, false, "sing", false)
		return
	## 「就这水平」倒数第 1 秒：柚柚打断倾身待机播生气，再直接接稳住
	if _phase == "taunt" and _playing == CLIP_TAUNT and not _angry_from_taunt:
		var taunt_left := _doudou_seconds_left()
		if taunt_left >= 0.0 and taunt_left <= TAUNT_ANGRY_LEAD_SEC:
			_try_angry_from_taunt()
	## 被吓到倒数第 1 秒：打断待机（或入场）播战术指导
	if _youyou_step == "scare" and not _tactics_from_scare:
		var left := -1.0
		if _pose != null and _pose.has_method("script_seconds_left"):
			left = float(_pose.script_seconds_left())
		if left >= 0.0 and left <= SCARE_TACTICS_LEAD_SEC:
			_try_tactics_from_scare()
	if _scare_sent or _phase != "look_in" or _playing != CLIP_LOOK_THERE or _actor == null:
		return
	var look_left := _doudou_seconds_left()
	if look_left >= 0.0 and look_left <= LOOK_SCARE_LEAD_SEC:
		_scare_sent = true
		## 吓到结束后要直接接捣乱，不回倾身待机
		_play_youyou(CLIP_SCARE, "scare", false)


func _doudou_seconds_left() -> float:
	if _actor == null or _playing == "":
		return -1.0
	var total := 0
	if _actor.has_method("clip_frame_count"):
		total = int(_actor.clip_frame_count(_playing))
	if total <= 0:
		return -1.0
	var left_frames := maxi(0, total - 1 - _actor.frame)
	return float(left_frames) / (24.0 * maxf(_actor.speed_scale, 0.05))


func _try_angry_from_taunt() -> void:
	if _angry_from_taunt or _grab_armed:
		return
	_angry_from_taunt = true
	## 生气播完直接接稳住，中间不回倾身待机
	_play_youyou(CLIP_ANGRY, "angry", false)
	if _pose != null and _pose.has_method("prefetch_script_clips"):
		_pose.prefetch_script_clips(PackedStringArray([CLIP_CALM]))


func _try_tactics_from_scare() -> void:
	if _tactics_from_scare or _grab_armed:
		return
	if _phase != "intro_idle" and _phase != "look_in":
		return
	if _phase == "tactics" or _playing == CLIP_TACTICS or _want_clip == CLIP_TACTICS:
		_tactics_from_scare = true
		return
	_tactics_from_scare = true
	_request(CLIP_TACTICS, false, "tactics", false)


func _cut_intro_for_grab() -> void:
	## 按 G：打断第一局对戏，双方进抓取；后续与第二套相同。
	_first_round = false
	_scare_sent = true
	_tactics_from_scare = true
	_angry_from_taunt = true
	_youyou_step = "cut"
	_pending_sing = false
	_request(CLIP_GRAB, false, "grab", false)
	if _actor != null and _actor.current_clip() != CLIP_GRAB and _actor.has_method("hold_current_frame"):
		_actor.hold_current_frame()


func _advance_intro(clip_name: String) -> bool:
	## 第一局对戏按阶段播完；G 只武装，不在这里打断进捂眼睛
	match _phase:
		"look_in":
			if clip_name != CLIP_LOOK_THERE:
				return false
			## 看那边结束 → 循环兜兜待机；吓到倒数第 1 秒再打断播战术指导
			if _tactics_from_scare:
				## 战术指导已在看那边未结束时插播，不再回待机
				return true
			_request(CLIP_IDLE, true, "intro_idle", false)
			return true
		"tactics":
			if clip_name != CLIP_TACTICS:
				return false
			## 战术指导完：回待机；等柚柚捣乱结束后再打断待机唱歌
			_pending_sing = true
			if _actor != null:
				_actor.prefetch_clip(CLIP_SING, true)
			_request(CLIP_IDLE, true, "idle_for_sing", false)
			return true
		"sing":
			if clip_name != CLIP_SING:
				return false
			_idle_slot = 0
			_idle_left = TAUNT_IDLE_SEC
			_request(CLIP_IDLE, true, "post_sing_idle", false)
			return true
		"post_sing_idle":
			return false
		"taunt":
			if clip_name != CLIP_TAUNT:
				return false
			## 生气已在倒数第 1 秒触发；嘲讽结束兜兜回待机
			if not _angry_from_taunt:
				_try_angry_from_taunt()
			_request(CLIP_IDLE, true, "intro_wait", false)
			return true
	return false


func _play_youyou(clip: String, step: String, return_to_lean: bool = true) -> void:
	if _pose == null or not _pose.has_method("play_script_clip"):
		return
	if _pose.has_method("blocks_script") and bool(_pose.blocks_script()):
		return
	if not bool(_pose.play_script_clip(clip, return_to_lean)):
		return
	_youyou_step = step
	var nxt := ""
	match clip:
		CLIP_SCARE:
			nxt = CLIP_MEDDLE
		CLIP_MEDDLE:
			nxt = CLIP_ANGRY
		CLIP_ANGRY:
			nxt = CLIP_CALM
	if nxt != "" and _pose.has_method("prefetch_script_clips"):
		_pose.prefetch_script_clips(PackedStringArray([nxt]))


func _on_youyou_script_finished(_clip_name: String) -> void:
	if not _first_round or _youyou_step == "cut":
		return
	## 链式对戏要同帧接上，不能 deferred（否则中间会空一拍）
	if _youyou_step == "scare" or _youyou_step == "angry":
		_continue_youyou()
		return
	call_deferred("_continue_youyou")


func _continue_youyou() -> void:
	if not _first_round or _grab_armed:
		return
	if _pose != null and _pose.has_method("blocks_script") and bool(_pose.blocks_script()):
		return
	match _youyou_step:
		"scare":
			## 被吓到播完直接接捣乱，不经倾身待机；捣乱结束后再回倾身待机
			_play_youyou(CLIP_MEDDLE, "meddle", true)
		"meddle":
			## 捣乱播完已回倾身待机；兜兜侧由 tick 在待机时打断唱歌
			_youyou_step = "meddle_done"
		"angry":
			## 生气播完直接接稳住，不经倾身待机
			_play_youyou(CLIP_CALM, "calm", true)
		"calm":
			_youyou_step = "done"
