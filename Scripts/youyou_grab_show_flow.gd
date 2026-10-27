extends Node
class_name YouyouGrabShowFlow

## 模拟抓取的身体序列、随机语音和操作视线。不改业务阶段。

const VisemeDriver := preload("res://Scripts/youyou_test_audio_viseme_driver.gd")
const VoiceSubtitleCatalog := preload("res://Scripts/youyou_voice_subtitle_catalog.gd")
const VoiceEmotionSchedules := preload("res://Scripts/youyou_voice_emotion_schedules.gd")
const FacePresenter := preload("res://Scripts/youyou_face_presenter.gd")

const COIN := "youyou_coin01"
const COIN_FIRST := "youyou_coin02"
const COIN_FIRST_AUDIO := "res://配音/投币1-想好了？.mp3"
const COIN_RETURN_AUDIO := "res://配音/柚柚与事件流程_剪辑/第二次抓娃欢迎.mp3"
const CRANE_01 := "youyou_claw crane01_01"
const CRANE_02 := "youyou_claw crane01_02"
const CRANE_03 := "youyou_claw crane01_03"
const CRANE_04 := "youyou_claw crane01_04"
const CRANE_05 := "youyou_claw crane01_05"
const CRANE02_01 := "youyou_claw_crane02_01"
const CRANE02_04 := "youyou_claw_crane02_04"
const CRANE02_05 := "youyou_claw_crane02_05"
const CRANE02_06 := "youyou_claw_crane02_06"
const CRANE02_07 := "youyou_claw_crane02_07"
const CRANE03_01 := "youyou_claw_crane03_01"
const CRANE03_02 := "youyou_claw_crane03_02"
const CRANE03_02_POST_SCARE := "youyou_claw_crane03_02_post_scare"
const CRANE03_05 := "youyou_claw_crane03_05"
const CRANE03_06 := "youyou_claw_crane03_06"
const CRANE03_07 := "youyou_claw_crane03_07"
const CRANE03_08 := "youyou_claw_crane03_08"

var _use_crane02_profile := false
var _use_crane03_profile := false
var _crane03_post_turn := false
var _crane03_operate_split_override := ""

const OPERATE_LINES: PackedStringArray = [
	"res://配音/操作1-胸有成竹.mp3",
	"res://配音/操作2-这个角度.mp3",
	"res://配音/操作3-稳住节奏（修）.mp3",
	"res://配音/操作4-小家伙期待.mp3",
	"res://配音/操作5-很有经验的样子.mp3",
	"res://配音/操作6-手法不错呀.mp3",
]
const GRAB_LINES: PackedStringArray = [
	"res://配音/抓取1-来了来了.mp3",
	"res://配音/抓取2-好紧张.mp3",
]

enum Phase {
	IDLE,
	OPENING_WAIT,
	COIN,
	IDLE_GAP,
	OBSERVE,
	POST_OBSERVE,
	OPERATE,
	DEEPER,
	WAIT,
	STAND,
	RESULT,
}

var _host: Node
var _event: YouyouEventActionPerformance
var _adapter: YouyouClawShowAdapter
var _player: AnimationPlayer
var _idle_life: Node
var _gaze: Node
var _head: Node
var _face: FacePresenter
var _voice: AudioStreamPlayer
var _viseme: YouyouTestAudioVisemeDriver
var _ambient_emotion_gen := 0
var _operate_pool: PackedStringArray = []
var _grab_pool: PackedStringArray = []
var _phase := Phase.IDLE
var _expect_token := -1
var _expect_action := ""
var _retired := {}
var _stale_logged := {}
var _token_seq := -2000
var _voice_gen := 0
var _active_voice_gen := -1
var _last_operate_line := ""
var _last_grab_line := ""
var _gap_left := -1.0
var _pose_gap := 0.0
var _idle_gap := 1.0
var _chain_speed := 1.0
var _result_latched := false
var _result_success := false
var _result_committed := false
var _result_commit_gen := 0
var _forced_result := -1
var _look_mode := 0
var _chain_rise := false
var _await_machine_result := false
var _waiting_board_result := false
var _pending_machine_result := -1
var _trace: PackedStringArray = []
var _opening_kind := ""
var _welcome_play_count := 0
var _active_coin := COIN_FIRST
var _active_coin_audio := COIN_FIRST_AUDIO
var _operate_short_logged := false
var _grab_short_logged := false
## 为 false 时操作蹲姿阶段不播操作系列随机台词（首局需等 crane02_03 后再开）。
var _operate_ambient_voice_enabled := true
## 为 false 时不进入盯爪转头/转眼。首局、续局操作期都保持开启，与 preview 一致。
var _operate_look_enabled := true
## 首局 01/03/04：摇杆仍有效，但不切身体、不叠眼头。
var _scripted_body_locked := false


func set_operate_ambient_voice_enabled(enabled: bool) -> void:
	_operate_ambient_voice_enabled = enabled
	if not enabled:
		_gap_left = -1.0


func set_operate_look_enabled(enabled: bool) -> void:
	_operate_look_enabled = enabled
	if not enabled:
		_end_look()


func is_operate_look_enabled() -> bool:
	return _operate_look_enabled and not _scripted_body_locked


func set_scripted_body_locked(locked: bool) -> void:
	_scripted_body_locked = locked
	if locked:
		_end_look()


func is_scripted_body_locked() -> bool:
	return _scripted_body_locked


## 首局一进来就盯爪，不依赖当前阶段是否已经是操作循环。
func engage_stick_look() -> void:
	if _scripted_body_locked or not _operate_look_enabled:
		_end_look()
		return
	_begin_look()


## 操作/观察阶段：重新打开 WASD 眼头追随（与 preview 一致）。
func refresh_operate_stick_look() -> void:
	if _scripted_body_locked or not _operate_look_enabled:
		_end_look()
		return
	match _phase:
		Phase.OBSERVE, Phase.POST_OBSERVE, Phase.OPERATE, Phase.WAIT, Phase.DEEPER:
			_begin_look()
		_:
			pass


func set_crane02_profile(enabled: bool) -> void:
	_use_crane02_profile = enabled
	if enabled:
		_use_crane03_profile = false
		_crane03_post_turn = false


func uses_crane02_profile() -> bool:
	return _use_crane02_profile


func set_crane03_profile(enabled: bool) -> void:
	_use_crane03_profile = enabled
	if enabled:
		_use_crane02_profile = false
	if not enabled:
		_crane03_post_turn = false
		_crane03_operate_split_override = ""


func uses_crane03_profile() -> bool:
	return _use_crane03_profile


func set_crane03_post_turn(enabled: bool) -> void:
	_crane03_post_turn = enabled


func set_crane03_operate_split_expression(timeline_action_id: String) -> void:
	_crane03_operate_split_override = timeline_action_id


func _apply_operate_split_expression_override(body_action_id: String) -> void:
	if _event == null or not _event.has_method("get_timeline"):
		return
	var tl := _event.get_timeline()
	if tl == null:
		return
	var override := ""
	if _use_crane03_profile and body_action_id == CRANE03_02:
		override = _crane03_operate_split_override
	if tl.has_method("set_split_expression_action_id"):
		tl.set_split_expression_action_id(override)


func snap_operate_loop(blend: float = 0.12, arm_ambient_voice: bool = true, enable_look: bool = true) -> void:
	if not _start_loop(_crane_operate(), blend):
		_log("回到操作维持姿势失败 %s" % _crane_operate())
		return
	_phase = Phase.OPERATE
	if enable_look and _operate_look_enabled:
		_begin_look()
	else:
		_end_look()
	if arm_ambient_voice and _operate_ambient_voice_enabled:
		_arm_voice_gap()


func _crane_enter() -> String:
	if _use_crane03_profile:
		return CRANE03_01
	return CRANE02_01 if _use_crane02_profile else CRANE_01


func _crane_operate() -> String:
	if _use_crane03_profile:
		return CRANE03_05 if _crane03_post_turn else CRANE03_02
	return CRANE02_04 if _use_crane02_profile else CRANE_02


func _operate_holds_last(action_id: String) -> bool:
	return _use_crane03_profile and (action_id == CRANE03_02 or action_id == CRANE03_05)


func _crane_down() -> String:
	if _use_crane03_profile:
		return CRANE03_06
	return CRANE02_05 if _use_crane02_profile else CRANE_03


func _crane_wait() -> String:
	if _use_crane03_profile:
		return CRANE03_07
	return CRANE02_06 if _use_crane02_profile else CRANE_04


func _crane_up() -> String:
	if _use_crane03_profile:
		return CRANE03_08
	return CRANE02_07 if _use_crane02_profile else CRANE_05


func setup(
	host: Node,
	event_performance: YouyouEventActionPerformance,
	adapter: YouyouClawShowAdapter,
	face: Node,
	anim_player: AnimationPlayer,
	idle_life: Node,
	gaze: Node,
	head: Node,
) -> void:
	_host = host
	_event = event_performance
	_adapter = adapter
	_player = anim_player
	_idle_life = idle_life
	_gaze = gaze
	_head = head
	_face = face as FacePresenter
	process_priority = 90
	_voice = AudioStreamPlayer.new()
	_voice.name = "GrabAmbientVoice"
	_voice.volume_db = preload("res://Scripts/audio/claw_scene_audio.gd").VOICE_VOLUME_DB
	add_child(_voice)
	_voice.finished.connect(_on_voice_finished)
	_viseme = VisemeDriver.new()
	_viseme.name = "GrabAmbientViseme"
	add_child(_viseme)
	_viseme.setup(face, _voice)
	if not _event.performance_finished.is_connected(_on_performance_finished):
		_event.performance_finished.connect(_on_performance_finished)
	if not _event.performance_failed.is_connected(_on_performance_failed):
		_event.performance_failed.connect(_on_performance_failed)
	_operate_pool = _existing_lines(OPERATE_LINES)
	_grab_pool = _existing_lines(GRAB_LINES)
	_log("操作语音 %d 条：%s" % [_operate_pool.size(), " | ".join(_operate_pool)])
	_log("抓取语音 %d 条：%s" % [_grab_pool.size(), " | ".join(_grab_pool)])
	if _operate_pool.size() < 2:
		_operate_short_logged = true
		_log("操作语音候选不足，无法避免连续重复")
	if _grab_pool.size() < 2:
		_grab_short_logged = true
		_log("抓取语音候选不足，无法避免连续重复")
	_log("目录备注与本次分工不一致：crane01_01 备注是待确认的抓取1，本次只播动作；02 备注左右观察；03 按下按钮；04 爪抓取过程；05 卸货回待机。流程仍按观察、蹲姿循环、更深下蹲、深蹲循环、站起使用这些编号。")


func begin_opening(business_token: int) -> void:
	begin_coin_welcome(business_token)


func begin_coin_welcome(_business_token: int, speech_id: String = "") -> void:
	if _phase == Phase.COIN or _phase == Phase.OPENING_WAIT:
		_log("欢迎表现已在播放，忽略重复")
		return
	if _phase != Phase.IDLE and _phase != Phase.RESULT:
		_log("当前表现占用，不重复播放欢迎")
		return
	if speech_id == "coin_return":
		_active_coin = COIN
		_active_coin_audio = COIN_RETURN_AUDIO
	else:
		_active_coin = COIN_FIRST
		_active_coin_audio = COIN_FIRST_AUDIO
	stop_ambient()
	_end_look()
	_opening_kind = "welcome"
	var waiting := ""
	if _host != null and _host.has_method("precoin_begin_handoff"):
		waiting = String(_host.precoin_begin_handoff())
	if waiting != "":
		_phase = Phase.OPENING_WAIT
		_log("等待当前表现结束后再播放投币欢迎 id=%s" % waiting)
		return
	_start_coin()


func begin_paid_observe(_business_token: int) -> bool:
	if _phase == Phase.COIN or _phase == Phase.OPENING_WAIT:
		stop_ambient()
		_phase = Phase.IDLE
		_opening_kind = ""
		_log("机台已开局，欢迎让路，开始下蹲")
	if _phase == Phase.OBSERVE:
		_opening_kind = "paid"
		_begin_look()
		_log("下蹲观察已经在播，眼睛跟上爪子")
		return true
	if _phase == Phase.POST_OBSERVE or _phase == Phase.OPERATE:
		_opening_kind = "paid"
		_begin_look()
		if _adapter != null:
			_adapter.call_deferred("complete_opening")
		_log("已经在操作蹲姿，直接把开场交回")
		return true
	if _phase != Phase.IDLE and _phase != Phase.RESULT and _phase != Phase.POST_OBSERVE:
		_log("当前表现占用，不能开始蹲下观察")
		return false
	_opening_kind = "paid"
	_result_latched = false
	_result_committed = false
	_start_observe()
	return _phase == Phase.OBSERVE or _phase == Phase.OPERATE or _phase == Phase.POST_OBSERVE


func reset_to_idle() -> void:
	stop_ambient()
	_end_look()
	_phase = Phase.IDLE
	_opening_kind = ""
	_expect_token = -1
	_expect_action = ""
	_chain_rise = false
	_await_machine_result = false
	_waiting_board_result = false
	_pending_machine_result = -1
	_result_latched = false
	_result_committed = false
	_gap_left = -1.0
	_operate_ambient_voice_enabled = true
	_operate_look_enabled = true
	_scripted_body_locked = false
	_log("测试重置，回到待机")


func begin_watch_keeping_speech() -> void:
	if _scripted_body_locked:
		return
	if _phase == Phase.DEEPER or _phase == Phase.WAIT or _phase == Phase.STAND:
		_begin_look()
		return
	if _body_is_watching():
		_begin_look()
		_phase = Phase.OPERATE
		_arm_operate_ambient_if_idle()
		return
	if _event != null and _event.has_method("release_body_keep_speech"):
		_event.release_body_keep_speech()
	_begin_look()
	_opening_kind = "paid"
	_result_latched = false
	_result_committed = false
	if not _play_body_loop_keep_audio(_crane_operate()) and not _play_body_loop_keep_audio(_crane_enter()):
		_log("盯钩爪动作没接上，镜头和眼睛仍然跟上")
		return
	_phase = Phase.OPERATE
	_arm_operate_ambient_if_idle()
	_log("玩家在操作钩爪，立刻盯钩爪，正在说的台词继续")


func _body_is_watching() -> bool:
	if _player == null:
		return false
	var anim_name := String(_player.assigned_animation)
	if _use_crane03_profile:
		return anim_name == CRANE03_01 or anim_name == CRANE03_02 or anim_name == CRANE03_05
	return anim_name == _crane_enter() or anim_name == _crane_operate()


func _play_body_loop_keep_audio(action_id: String) -> bool:
	if _player == null:
		return false
	if _event != null and _event.has_method("ensure_body_clip"):
		if not _event.ensure_body_clip(action_id):
			return false
	elif not _player.has_animation(action_id):
		return false
	var clip := _player.get_animation(action_id)
	if clip == null:
		return false
	var hold := _operate_holds_last(action_id)
	clip.loop_mode = Animation.LOOP_NONE if hold else Animation.LOOP_LINEAR
	_player.speed_scale = 1.0
	_player.play(action_id, 0.2, 1.0, false)
	_apply_operate_split_expression_override(action_id)
	if _event != null and _event.has_method("arm_split_loop"):
		_event.arm_split_loop(action_id, hold)
	return String(_player.assigned_animation) == action_id and _player.is_playing()


func begin_ready_stance() -> void:
	if (
		_phase == Phase.OBSERVE
		or _phase == Phase.POST_OBSERVE
		or _phase == Phase.OPERATE
		or _phase == Phase.DEEPER
		or _phase == Phase.WAIT
		or _phase == Phase.STAND
	):
		_begin_look()
		return
	if _phase == Phase.COIN or _phase == Phase.OPENING_WAIT:
		return
	_opening_kind = "ready"
	_result_latched = false
	_result_committed = false
	_start_observe()
	_log("欢迎结束，进入准备抓取的下蹲")


func notify_precoin_yielded() -> void:
	if _phase != Phase.OPENING_WAIT:
		_log("过期交接被忽略")
		return
	_start_coin()


func begin_operate() -> void:
	if _scripted_body_locked:
		return
	if _phase == Phase.OPERATE:
		_arm_operate_ambient_if_idle()
		if _operate_look_enabled:
			_begin_look()
		return
	if _phase == Phase.DEEPER or _phase == Phase.WAIT or _phase == Phase.STAND:
		_log("抓取阶段进行中，不回到操作蹲姿")
		return
	if _phase != Phase.POST_OBSERVE and _phase != Phase.IDLE and _phase != Phase.RESULT:
		_log("当前表现阶段不能进入操作蹲姿")
		return
	stop_ambient()
	var keep_look := _look_mode != 0
	if not keep_look:
		_end_look()
	_result_latched = false
	if _host != null and _host.has_method("clear_grab_result_banner"):
		_host.clear_grab_result_banner()
	if not _start_loop(_crane_operate()):
		_log("蹲姿循环播放失败，未进入操作表现")
		return
	_phase = Phase.OPERATE
	if _operate_look_enabled:
		_begin_look()
	else:
		_end_look()
	if _operate_ambient_voice_enabled:
		_arm_voice_gap()
	else:
		_gap_left = -1.0
	_log("进入操作蹲姿 %s" % _crane_operate())


func arm_chained_machine_grab() -> void:
	_chain_rise = true
	_await_machine_result = true
	_waiting_board_result = false
	_pending_machine_result = -1


func accepts_machine_result() -> bool:
	return (
		_await_machine_result
		or _waiting_board_result
		or _phase == Phase.DEEPER
		or _phase == Phase.STAND
		or _phase == Phase.WAIT
	)


func notify_machine_result(success: bool) -> void:
	if _result_committed:
		return
	_pending_machine_result = 1 if success else 0
	if not _waiting_board_result:
		_log("控制板先报告了%s，等提起动作演完再接结果" % ("抓到" if success else "没抓到"))
		return
	_result_success = success
	_pending_machine_result = -1
	_waiting_board_result = false
	_await_machine_result = false
	_latch_and_commit()


func begin_deeper() -> void:
	if _host != null and _host.has_method("real_machine_sensors") and bool(_host.real_machine_sensors()):
		_chain_rise = true
		_await_machine_result = true
	if (
		_phase != Phase.OPERATE
		and _phase != Phase.OBSERVE
		and _phase != Phase.POST_OBSERVE
		and _phase != Phase.COIN
		and _phase != Phase.OPENING_WAIT
		and _phase != Phase.IDLE
	):
		_chain_rise = false
		_await_machine_result = false
		_log("不在操作蹲姿，忽略下蹲")
		return
	stop_ambient()
	_begin_look()
	_result_latched = false
	_phase = Phase.DEEPER
	if _host != null and _host.has_method("hold_body_for_grab"):
		_host.hold_body_for_grab()
	var token := _next_token()
	_set_expect(token, _crane_down())
	if not _play_once(_crane_down(), token, false, true, _chain_speed, 0.0):
		if _phase == Phase.DEEPER:
			_log("更深下蹲播放失败，不进入等待循环")
			if _chain_rise:
				_start_machine_rise()
		return
	_log("播放抓取下落 %s" % _crane_down())


func request_judgment() -> bool:
	if _phase != Phase.WAIT or _result_latched:
		_log("当前阶段不能判定结果")
		return false
	stop_ambient()
	_phase = Phase.STAND
	if _host != null and _host.has_method("hold_body_for_grab"):
		_host.hold_body_for_grab()
	var token := _next_token()
	_set_expect(token, _crane_up())
	if not _play_once(_crane_up(), token, false, true, _chain_speed, 0.0):
		if _phase == Phase.STAND:
			_phase = Phase.WAIT
			_log("站起动作播放失败，未判定结果")
		return false
	_log("停止深蹲循环，播放站起 %s；站起完成前不判定结果" % _crane_up())
	return true


func stop_ambient() -> void:
	_gap_left = -1.0
	_voice_gen += 1
	_active_voice_gen = -1
	_ambient_emotion_gen += 1
	if _voice != null and _voice.playing:
		_voice.stop()
	_stop_ambient_viseme()


func notify_presence_released() -> void:
	_result_commit_gen += 1
	stop_ambient()
	_end_look()
	if _host != null and _host.has_method("clear_grab_result_banner"):
		_host.clear_grab_result_banner()
	if _phase != Phase.IDLE:
		_phase = Phase.IDLE
		_expect_token = -1
		_expect_action = ""
		_log("表现控制权交还待机调度")


func wants_look() -> bool:
	return _operate_look_enabled and not _scripted_body_locked and _look_mode != 0


func blocks_wasd_variants() -> bool:
	return _phase == Phase.OPERATE


func holds_exclusive_body() -> bool:
	return (
		_phase == Phase.OPENING_WAIT
		or _phase == Phase.COIN
		or _phase == Phase.IDLE_GAP
		or _phase == Phase.OBSERVE
		or _phase == Phase.POST_OBSERVE
		or _phase == Phase.OPERATE
		or _phase == Phase.DEEPER
		or _phase == Phase.WAIT
		or _phase == Phase.STAND
		or _phase == Phase.RESULT
	)


func phase_name() -> String:
	return Phase.keys()[_phase]


func is_voice_playing() -> bool:
	return _voice != null and _voice.playing


func is_viseme_active() -> bool:
	if _viseme != null and _viseme.is_active():
		return true
	return _event != null and _event.has_method("is_external_speech_viseme_active") and _event.is_external_speech_viseme_active()


func result_success() -> bool:
	return _result_success


func result_latched() -> bool:
	return _result_latched


func set_idle_gap(seconds: float) -> void:
	_idle_gap = maxf(seconds, 0.05)


func set_chain_speed(speed: float) -> void:
	_chain_speed = maxf(speed, 0.1)


func debug_force_voice() -> bool:
	if _phase != Phase.OPERATE and _phase != Phase.WAIT:
		return false
	if is_voice_playing():
		return false
	_gap_left = -1.0
	return _play_random_line()


func debug_force_next_result(success: bool) -> void:
	_forced_result = 1 if success else 0


func debug_rearm_wait() -> void:
	_result_commit_gen += 1
	_result_committed = false
	_result_latched = false
	_forced_result = -1
	_phase = Phase.WAIT


func debug_stale_finish() -> void:
	_retired[-123456] = true
	_on_performance_finished(-123456, CRANE_03, "package_complete")


func debug_simulate_open_failure() -> bool:
	_phase = Phase.COIN
	_expect_token = 4242
	_expect_action = COIN
	_on_performance_failed(4242, COIN, "validate", "模拟加载失败")
	return _phase == Phase.IDLE


func trace_has(text: String) -> bool:
	for line in _trace:
		if line.contains(text):
			return true
	return false


func _process(delta: float) -> void:
	if _phase == Phase.IDLE_GAP:
		_pose_gap -= delta
		if _pose_gap <= 0.0:
			_start_observe()
	if _gap_left >= 0.0 and (_phase == Phase.OPERATE or _phase == Phase.WAIT):
		_gap_left -= delta
		if _gap_left <= 0.0:
			_gap_left = -1.0
			_play_random_line()
	if (_phase == Phase.DEEPER or _phase == Phase.WAIT) and _host != null and _host.has_method("hold_grab_surprise"):
		_host.hold_grab_surprise()
	_update_grab_look_down()
	_process_look()


func welcome_play_count() -> int:
	return _welcome_play_count


func _start_coin() -> void:
	_phase = Phase.COIN
	_opening_kind = "welcome"
	_welcome_play_count += 1
	if _host != null and _host.has_method("prepare_coin_body"):
		_host.prepare_coin_body()
	var token := _next_token()
	_set_expect(token, _active_coin)
	if not _play_once(_active_coin, token, true, true, 1.0, 0.25, _active_coin_audio):
		if _phase == Phase.COIN:
			_log("投币动作播放失败")
			_fail_opening()
		return
	_log("播放投币欢迎 %s + %s，本段不回到基础待机" % [_active_coin, _active_coin_audio.get_file()])


func _start_observe() -> void:
	_begin_look()
	_phase = Phase.OBSERVE
	if _host != null and _host.has_method("grab_mark_event"):
		_host.grab_mark_event(true)
	var token := _next_token()
	_set_expect(token, _crane_enter())
	if not _play_once(_crane_enter(), token, false, true, _chain_speed):
		_log("观察动作播放失败，改进入操作蹲姿")
		_phase = Phase.POST_OBSERVE
		if _opening_kind == "paid" and _adapter != null:
			_adapter.call_deferred("complete_opening")
		begin_operate()
		return
	_log("播放下蹲观察 %s，眼睛开始跟随爪子" % _crane_enter())


func _accept_package(action_id: String) -> void:
	match _phase:
		Phase.COIN:
			if action_id != _active_coin:
				return
			_phase = Phase.IDLE
			_opening_kind = ""
			if _host != null and _host.has_method("grab_mark_event"):
				_host.grab_mark_event(false)
			_log("投币欢迎结束，直接衔接后续，不插入基础待机")
			if _host != null and _host.has_method("on_coin_welcome_finished"):
				_host.on_coin_welcome_finished()
		Phase.OBSERVE:
			if action_id != _crane_enter():
				return
			_phase = Phase.POST_OBSERVE
			_log("下蹲观察结束")
			if _opening_kind == "paid":
				if _adapter != null:
					_adapter.complete_opening()
			else:
				begin_operate()
		Phase.DEEPER:
			if action_id != _crane_down():
				return
			if _chain_rise:
				_start_machine_rise()
				return
			if not _start_loop(_crane_wait(), 0.0):
				_log("深蹲循环播放失败，停在下蹲结束姿势")
				return
			_phase = Phase.WAIT
			_arm_voice_gap()
			_log("进入抓取等待 %s" % _crane_wait())
		Phase.STAND:
			if action_id != _crane_up() or _result_latched:
				return
			if _chain_rise or _await_machine_result or _host_has_sensors():
				_resolve_chained_result()
				return
			if _forced_result == 0 or _forced_result == 1:
				_result_success = _forced_result == 1
				_forced_result = -1
			else:
				_result_success = randi() % 2 == 0
			_result_latched = true
			_result_committed = false
			_phase = Phase.RESULT
			_end_look()
			_result_commit_gen += 1
			_log("站起结束，判定%s；等播放器收尾后再提交" % ("成功" if _result_success else "失败"))
			_commit_result.call_deferred(_result_commit_gen)


func _fail_current(message: String) -> void:
	if _phase == Phase.COIN or _phase == Phase.OBSERVE or _phase == Phase.IDLE_GAP or _phase == Phase.OPENING_WAIT:
		_log("开场失败：%s" % message)
		_fail_opening()
		return
	if _phase == Phase.STAND:
		_result_commit_gen += 1
		_phase = Phase.WAIT
		_result_latched = false
		_result_committed = false
		_log("站起失败，未提交结果：%s" % message)
		return
	if _phase == Phase.DEEPER:
		_log("下蹲失败，不进入等待循环：%s" % message)
		return
	_log("动作失败：%s" % message)


func _fail_opening() -> void:
	var kind := _opening_kind
	_opening_kind = ""
	_phase = Phase.IDLE
	_gap_left = -1.0
	_end_look()
	if _host != null and _host.has_method("grab_mark_event"):
		_host.grab_mark_event(false)
	if kind == "paid" and _adapter != null:
		_adapter.fail_opening()
	elif kind == "welcome" and _host != null and _host.has_method("on_coin_welcome_finished"):
		_host.on_coin_welcome_finished()


func _start_loop(action_id: String, blend: float = 0.25) -> bool:
	if _event == null or _player == null:
		return false
	if _event.has_method("stop_event"):
		_event.stop_event(false)
	if not _event.arm_body_clip(action_id):
		return false
	var clip := _player.get_animation(action_id)
	if clip == null:
		return false
	var hold := _operate_holds_last(action_id)
	clip.loop_mode = Animation.LOOP_NONE if hold else Animation.LOOP_LINEAR
	_player.speed_scale = 1.0
	_player.play(action_id, blend, 1.0, false)
	_apply_operate_split_expression_override(action_id)
	if _event.has_method("arm_split_loop"):
		_event.arm_split_loop(action_id, hold)
	return String(_player.assigned_animation) == action_id and _player.is_playing()


func _play_once(action_id: String, token: int, play_audio: bool, keep_pose: bool, speed: float, blend: float = 0.25, audio_override: String = "") -> bool:
	if _event == null:
		return false
	if _host != null and _host.has_method("grab_mark_event"):
		_host.grab_mark_event(true)
	var ok := _event.play_event(action_id, token, not keep_pose, play_audio, blend, audio_override)
	if ok and _player != null and speed != 1.0:
		_player.speed_scale = speed
	return ok


func _arm_operate_ambient_if_idle() -> void:
	if not _operate_ambient_voice_enabled:
		return
	if _phase != Phase.OPERATE:
		return
	if is_voice_playing() or _gap_left >= 0.0:
		return
	_arm_voice_gap()


func _arm_voice_gap() -> void:
	_gap_left = randf_range(2.2, 4.0)


func _play_random_line() -> bool:
	if _voice == null or _voice.playing:
		return false
	if _phase == Phase.OPERATE and not _operate_ambient_voice_enabled:
		return false
	var pool := _operate_pool if _phase == Phase.OPERATE else _grab_pool
	var last := _last_operate_line if _phase == Phase.OPERATE else _last_grab_line
	if _phase != Phase.OPERATE and _phase != Phase.WAIT:
		return false
	if pool.is_empty():
		_log("本阶段没有可加载的专用语音，不使用其他台词")
		return false
	var pick := _pick_line(pool, last)
	var stream := load(pick) as AudioStream
	if stream == null:
		_log("语音加载失败，不改播其他类别：%s" % pick)
		return false
	if _phase == Phase.OPERATE:
		_last_operate_line = pick
	else:
		_last_grab_line = pick
	_voice_gen += 1
	_active_voice_gen = _voice_gen
	_ambient_emotion_gen += 1
	var emo_gen := _ambient_emotion_gen
	_voice.stream = stream
	if _host != null:
		VoiceSubtitleCatalog.notify_audio(_host, pick)
	var emo_plan := VoiceEmotionSchedules.plan_for("", pick)
	if _face != null and not emo_plan.is_empty():
		VoiceEmotionSchedules.arm_cues(
			_host,
			_face,
			emo_gen,
			func(g: int) -> bool:
				return g == _ambient_emotion_gen and _active_voice_gen == _voice_gen,
			emo_plan,
			1.0,
			0.0,
		)
	_voice.play()
	_start_ambient_viseme()
	_log("随机语音 %s" % pick)
	return true


func _pick_line(pool: PackedStringArray, last: String) -> String:
	var choices: PackedStringArray = []
	for path in pool:
		if pool.size() > 1 and path == last:
			continue
		choices.append(path)
	if choices.is_empty():
		return pool[0]
	return choices[randi() % choices.size()]


func _existing_lines(paths: PackedStringArray) -> PackedStringArray:
	var found: PackedStringArray = []
	for path in paths:
		if ResExists.path(path):
			found.append(path)
		else:
			_log("语音文件不存在：%s" % path)
	return found


func _on_voice_finished() -> void:
	if _active_voice_gen != _voice_gen:
		return
	_active_voice_gen = -1
	_stop_ambient_viseme()
	if _phase == Phase.OPERATE or _phase == Phase.WAIT:
		_gap_left = randf_range(4.5, 7.5)


func _start_ambient_viseme() -> void:
	var used_split := false
	if _event != null and _event.has_method("start_external_speech_viseme"):
		used_split = bool(_event.start_external_speech_viseme(_voice))
	if not used_split and _viseme != null:
		_viseme.start()


func _stop_ambient_viseme() -> void:
	if _event != null and _event.has_method("stop_external_speech_viseme"):
		_event.stop_external_speech_viseme()
	if _viseme != null:
		_viseme.stop(0.12)


func _host_has_sensors() -> bool:
	return _host != null and _host.has_method("real_machine_sensors") and bool(_host.real_machine_sensors())


func _is_ctrl_g_held() -> bool:
	var g := Input.is_physical_key_pressed(KEY_G) or Input.is_key_pressed(KEY_G)
	var ctrl := Input.is_physical_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_CTRL)
	return g and ctrl


func _update_grab_look_down() -> void:
	var holding := _is_ctrl_g_held() and (
		_phase == Phase.OPERATE or _phase == Phase.DEEPER or _phase == Phase.WAIT
	)
	if holding and not _scripted_body_locked:
		if not _operate_look_enabled:
			_operate_look_enabled = true
		if _look_mode == 0:
			_begin_look()
	if _gaze != null and _gaze.has_method("set_grab_look_down"):
		_gaze.call("set_grab_look_down", holding and not _scripted_body_locked)


func _begin_look() -> void:
	_look_mode = 1
	_apply_look()
	if _host != null and _host.has_method("sync_stick_gaze_now"):
		_host.sync_stick_gaze_now()


func _start_machine_rise() -> void:
	_phase = Phase.STAND
	if _host != null and _host.has_method("_play_grab_up"):
		_host.call("_play_grab_up")
	if _host != null and _host.has_method("hold_body_for_grab"):
		_host.hold_body_for_grab()
	var token := _next_token()
	_set_expect(token, _crane_up())
	if not _play_once(_crane_up(), token, false, true, _chain_speed, 0.0):
		_log("提起动作播放失败，按已经知道的结果收尾")
		_resolve_chained_result()
		return
	_log("下落接上提起 %s" % _crane_up())


func _resolve_chained_result() -> void:
	_chain_rise = false
	if _pending_machine_result >= 0:
		_result_success = _pending_machine_result == 1
		_pending_machine_result = -1
		_await_machine_result = false
		_latch_and_commit()
		return
	if _await_machine_result or _host_has_sensors():
		_waiting_board_result = true
		_await_machine_result = true
		_phase = Phase.RESULT
		_end_look()
		_log("提起演完，等出礼传感器：抓到或没抓到")
		return
	if _forced_result == 0 or _forced_result == 1:
		_result_success = _forced_result == 1
		_forced_result = -1
	else:
		_result_success = randi() % 2 == 0
	_latch_and_commit()


func _latch_and_commit() -> void:
	_result_latched = true
	_result_committed = false
	_phase = Phase.RESULT
	_end_look()
	_result_commit_gen += 1
	_log("抓取收尾，判定%s" % ("成功" if _result_success else "失败"))
	_commit_result.call_deferred(_result_commit_gen)


func _end_look() -> void:
	if _look_mode == 0:
		return
	_look_mode = 0
	if _gaze != null:
		if _gaze.has_method("set_grab_look_down"):
			_gaze.call("set_grab_look_down", false)
		_gaze.call("debug_set_keys", false, false, false, false, false)
	if _idle_life != null:
		_idle_life.call("set_manual_input_enabled", false)


func _process_look() -> void:
	if _look_mode == 0:
		return
	_apply_look()


func _apply_look() -> void:
	if _idle_life == null:
		return
	_idle_life.set_process(true)
	_idle_life.call("set_blink_channel", true)
	_idle_life.call("set_gaze_channel", true)
	_idle_life.call("set_head_channel", true)
	_idle_life.call("set_manual_input_enabled", true)


func _on_performance_finished(token: int, action_id: String, _reason: String) -> void:
	if token == _expect_token and action_id == _expect_action:
		_expect_token = -1
		_expect_action = ""
		_accept_package(action_id)
		return
	if _retired.has(token):
		if not bool(_stale_logged.get(token, false)):
			_stale_logged[token] = true
			_log("过期回调被忽略")


func _on_performance_failed(token: int, action_id: String, _code: String, message: String) -> void:
	if token != _expect_token:
		if _retired.has(token) and not bool(_stale_logged.get(token, false)):
			_stale_logged[token] = true
			_log("过期回调被忽略")
		return
	_expect_token = -1
	_expect_action = ""
	_log("动作播放失败 %s：%s" % [action_id, message])
	_fail_current(message)


func _commit_result(gen: int) -> void:
	if gen != _result_commit_gen or _result_committed:
		_log("过期结果提交被忽略")
		return
	if _phase != Phase.RESULT or not _result_latched:
		_log("结果阶段已变化，不提交")
		return
	_result_committed = true
	_log("提交%s结果" % ("成功" if _result_success else "失败"))
	if _host != null and _host.has_method("submit_simulated_grab_result"):
		_host.submit_simulated_grab_result(_result_success)


func _set_expect(token: int, action_id: String) -> void:
	if _expect_token != -1:
		_retired[_expect_token] = true
	_expect_token = token
	_expect_action = action_id


func _next_token() -> int:
	_token_seq -= 1
	return _token_seq


func _log(message: String) -> void:
	_trace.append(message)
	if _host != null and _host.has_method("grab_log"):
		_host.grab_log(message)
