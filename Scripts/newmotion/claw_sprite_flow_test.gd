extends Node

## 有 ClawBusiness、无 3D 柚柚：序列帧填坑跑通整局。

const VIEWPORT_SIZE := Vector2i(1920, 1080)
const ClawBusinessNode := preload("res://Scripts/business/claw_business.gd")
const ClawMinigamePortNode := preload("res://Scripts/business/claw_minigame_port.gd")
const MinigameHostNode := preload("res://Scripts/business/claw_minigame_host.gd")
const MinigameInviteFlow := preload("res://Scripts/youyou_minigame_invite_flow.gd")
const SpriteAdapter := preload("res://Scripts/newmotion/sprite_claw_show_adapter.gd")
const PoseDirector := preload("res://Scripts/newmotion/operate_pose_director.gd")
const DoudouFollowupDirector := preload("res://Scripts/newmotion/doudou_followup_director.gd")
const ClawSceneAudio := preload("res://Scripts/audio/claw_scene_audio.gd")
const PreviewAiVoiceBridgeScript := preload("res://Scripts/voice/preview_ai_voice_bridge.gd")
const PreviewAiVoicePlayerStatusScript := preload("res://Scripts/voice/preview_ai_voice_player_status.gd")

const RETURN_NONE := 0
const RETURN_PRIZE := 1
const RETURN_MISS_RETRY := 2
const RETURN_MISS_IDLE := 3
const PRIZE_CLIP := "恭喜你获得一次抓取机会"
const RETRY_CLIP := "youyou_guideNext_2"
const BREATH_CLIP := "youyou_Idlebreath"
const HEAR_CLIP := "AI-listen"
const THINK_OPEN_CLIP := "AI-think1"
const THINK_LOOP_CLIP := "AI-think2"
const THINK_END_CLIP := "AI-think3"
const SPEAK_OPEN_CLIP := "AI-talk1"
const SPEAK_LOOP_CLIP := "AI-talk2"
const SPEAK_END_CLIP := "AI-talk3"
const SPEAK_END_SEC := 97.0 / 24.0
const VOICE_POSE_NONE := 0
const VOICE_POSE_BREATH := 1
const VOICE_POSE_LISTEN := 2
const VOICE_POSE_SPEAK := 3
const VOICE_POSE_THINK := 4
## 语音窗口内静默招揽：招揽 → 招揽 → 呼吸，循环
const VOICE_POSE_WINDOW_ATTRACT := 5
const MISS_IDLE_SEC := 10.0
const NO_RESPONSE_SEC := 10.0
const VOICE_SILENCE_LEAVE_SEC := 5.0
const VOICE_COIN_GRACE_SEC := 5.0

@onready var _character: AnimatedSprite2D = $CharacterLayer/Character
@onready var _doudou: NewMotionSpriteActor = $DoudouLayer/Doudou
@onready var _bg_layer: CanvasLayer = $BackgroundLayer
@onready var _doudou_layer: CanvasLayer = $DoudouLayer
@onready var _character_layer: CanvasLayer = $CharacterLayer
@onready var _ui_layer: CanvasLayer = $UiLayer
@onready var _hud: PanelContainer = get_node_or_null("UiLayer/Hud") as PanelContainer
@onready var _flow_hint_panel: PanelContainer = $UiLayer/FlowHint
@onready var _flow_hint: Label = $UiLayer/FlowHint/Margin/HintText
@onready var _invite_prompt: PanelContainer = $UiLayer/InvitePrompt
@onready var _status: Label = get_node_or_null("UiLayer/Hud/Margin/VBox/Status") as Label
@onready var _help: Label = get_node_or_null("UiLayer/Hud/Margin/VBox/Help") as Label
@onready var _note: Label = get_node_or_null("UiLayer/Hud/Margin/VBox/Note") as Label

var _business: ClawBusiness
var _show: Node
var _pose
var _minigame: ClawMinigamePort
var _minigame_host: Node2D
var _invite_flow: YouyouMinigameInviteFlow
var _claw_audio: Node
@onready var _left_hud: YouyouLeftHud = get_node_or_null("LeftHud") as YouyouLeftHud
var _minigame_launch_pending := false
var _return_mode := RETURN_NONE
var _free_round_ready := false
var _miss_idle_left := 0.0
var _free_plays_at_open := 0
var _ai_voice: PreviewAiVoiceBridge
var _ai_player_status: PreviewAiVoicePlayerStatus
var _ai_pose_locked := false
var _voice_processing := false
var _voice_pose_clip := ""
var _voice_pose_mode := VOICE_POSE_NONE
var _pending_breath_after_hear := false
var _pending_think_after_hear := false
var _pending_speak_after_hear := false
## 倾听片播着时静默招揽先挂起，听播完再切
var _pending_window_attract_after_hear := false
var _hear_hold_until_finished := false
var _speak_phase := ""
var _think_phase := ""
var _silence_leave_at_msec := 0
var _voice_coin_grace_left := -1.0
## 窗口静默招揽：0/1 播招揽，满 2 次后播呼吸再清零
var _window_attract_count := 0
var _doudou_director: DoudouFollowupDirector
## 柚柚引导小游戏或第二局抓娃娃播完后，等多久没人回应就结束本局。
var _no_response_left := -1.0


func _enter_tree() -> void:
	_apply_viewport()


func _ready() -> void:
	_apply_ui_font()
	if _help != null:
		_help.text = (
			"无人时待机招揽：随机「待机+呼吸+招揽」组合循环。M 走近开 AI 窗口 · Backspace 离开 · T 投币。"
			+ "窗口内 5 秒无人讲话：招揽×2 + 呼吸循环；有人讲话回到倾听。窗口结束回待机招揽。"
			+ "识别/思考/准备回答：think1 后循环 think2；开口前 think3，再说话1→循环说话2→说话3。"
			+ "倾听动作播完前不打断，播完再接思考/说话/招揽；呼吸待机可直接打断。"
			+ "开局后倾身并停在倾身待机，按住 A/D 左右看、W 向前看、S 仰头，松开从当前帧倒放回去。"
			+ "G 下蹲并蹲着待机 · B 往上抓站起。失败后先播失败，再邀请小游戏。引导小游戏或第二局抓娃娃播完，兜兜接「我看算了吧」再跑出；10 秒没人回应则本局结束，柚柚回到待机招揽。说想玩/不玩，或按 1/2。拒绝后接再抓一次。"
			+ "第一局：倾身后兜兜看那边入场对戏（对戏中 A/D/W/S 不打断柚柚）；按 G 两人立刻打断并进抓取后流程。第二局起兜兜爬行从右侧入场，不打断柚柚。小游戏中 M 关掉 · Ctrl+Z 开第二局 · Q 重置。"
			+ "小游戏拿到抓取机会后，按 O 免费开一局。"
		)
	if _left_hud == null:
		push_error("ClawSpriteFlowTest: 请在场景里放置 LeftHud（实例 youyou_arcade_hud.tscn），编辑器里调整的位置才会进运行。")
	_show = SpriteAdapter.new()
	_show.name = "SpriteClawShowAdapter"
	add_child(_show)
	_show.setup(_character)
	_show.clip_changed.connect(_on_clip_changed)
	if _character.has_signal("pose_clip_finished"):
		_character.connect("pose_clip_finished", _on_return_clip_finished)
	_pose = PoseDirector.new()
	_pose.name = "OperatePoseDirector"
	add_child(_pose)
	_pose.setup(_character, _show)
	_show.pose_command.connect(_pose.on_command)
	_show.neutral_play.connect(_on_neutral_play)
	_pose.stand_finished.connect(_on_stand_finished)
	_pose.lean_idle_began.connect(_on_lean_idle_for_doudou)
	_doudou_director = DoudouFollowupDirector.new()
	_doudou_director.name = "DoudouFollowupDirector"
	add_child(_doudou_director)
	_doudou_director.setup(_doudou, _pose)

	_minigame = ClawMinigamePortNode.new()
	_minigame.name = "ClawMinigamePort"
	add_child(_minigame)
	_minigame_host = MinigameHostNode.new()
	_minigame_host.name = "ClawMinigameHost"
	add_child(_minigame_host)
	_minigame_host.setup(_minigame)
	_minigame.opened.connect(_minigame_host.open_round)
	_minigame.opened.connect(_on_minigame_port_opened)
	_minigame.finished.connect(_on_minigame_port_finished)
	if _minigame_host.has_signal("play_scene_active"):
		_minigame_host.play_scene_active.connect(_on_minigame_play_scene)
	if _minigame_host.has_signal("lobby_music_suspended"):
		_minigame_host.lobby_music_suspended.connect(_on_lobby_music_suspended)

	_invite_flow = MinigameInviteFlow.new()
	_invite_flow.name = "MinigameInviteFlow"
	add_child(_invite_flow)
	_invite_flow.setup(self)

	_business = ClawBusinessNode.new()
	_business.name = "ClawBusiness"
	add_child(_business)
	_business.bind(_show, _minigame)
	if _minigame.finished.is_connected(_business._on_minigame_port_finished):
		_minigame.finished.disconnect(_business._on_minigame_port_finished)
	_business.situation_changed.connect(_on_situation_changed)
	_claw_audio = ClawSceneAudio.new()
	_claw_audio.name = "ClawSceneAudio"
	add_child(_claw_audio)
	_ai_voice = PreviewAiVoiceBridgeScript.new()
	_ai_voice.name = "PreviewAiVoiceBridge"
	add_child(_ai_voice)
	_ai_voice.setup(self)
	if _left_hud != null:
		_left_hud.bind_voice_ai_bridge(_ai_voice)
		_ai_player_status = PreviewAiVoicePlayerStatusScript.new()
		_ai_player_status.bind(self, _left_hud.get_voice_status_label())
	_refresh_hud()


func _process(delta: float) -> void:
	_tick_voice_window(delta)
	_sync_voice_panel_situation()
	_tick_return_wait(delta)
	_tick_no_response(delta)
	_maybe_start_invite_listen()
	_sync_invite_prompt()
	_refresh_flow_hint()
	if _pose == null:
		return
	if _minigame_covers_ui() or not _in_claw_round():
		return
	var left := Input.is_physical_key_pressed(KEY_A)
	var right := Input.is_physical_key_pressed(KEY_D)
	var forward := Input.is_physical_key_pressed(KEY_W)
	var back := Input.is_physical_key_pressed(KEY_S)
	var dir := 0
	var held := int(left) + int(right) + int(forward) + int(back)
	if held == 1:
		if back:
			dir = 3
		elif forward:
			dir = 2
		elif left:
			dir = -1
		else:
			dir = 1
	_pose.set_look(dir)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := event as InputEventKey
	if _minigame_covers_ui() and key.keycode != KEY_M and key.keycode != KEY_Q:
		return
	var reset_wait := _return_mode == RETURN_MISS_IDLE
	match key.keycode:
		KEY_A:
			if not _in_claw_round():
				return
			_play_move("right")
		KEY_D:
			if not _in_claw_round():
				return
			_play_move("left")
		KEY_W:
			if not _in_claw_round():
				return
			_play_move("up")
		KEY_S:
			if not _in_claw_round():
				return
			_play_move("down")
		KEY_ENTER, KEY_KP_ENTER:
			_on_player_walk_in()
		KEY_BACKSPACE:
			if _invite_flow != null and _invite_flow.holds_schedule():
				_invite_flow.notify_presence_released()
				_set_debug_note( "已取消小游戏邀请（不算拒绝）。")
				_refresh_hud()
			else:
				_end_voice_for_business("player_left")
				_submit(ClawBusinessNode.PLAYER_LEFT)
		KEY_T:
			_on_coin_pressed()
		KEY_G:
			var grabbed: Dictionary = _submit(ClawBusinessNode.GRAB_PRESSED)
			if bool(grabbed.get("ok", false)):
				_play_grab_down()
				if _doudou_director != null:
					_doudou_director.notify_grab_pressed()
		KEY_O:
			if not _try_free_round_key():
				_submit(ClawBusinessNode.PLAYER_OPERATING)
		KEY_1:
			_on_key_one()
		KEY_2:
			_on_key_two()
		KEY_B:
			if _pose != null and bool(_pose.request_stand()):
				_play_grab_up()
				_set_debug_note( "往上抓，播放站起。")
				_refresh_hud()
			else:
				_set_debug_note( "现在还不能往上抓。先按 G，等蹲着待机后再按 B。")
				_refresh_hud()
		KEY_M:
			if _minigame_covers_ui():
				_force_close_minigame()
			else:
				_on_player_walk_in()
		KEY_Z:
			if not event.ctrl_pressed:
				return
			var replayed: Dictionary = _submit(ClawBusinessNode.SUCCESS_REPLAY)
			if bool(replayed.get("ok", false)):
				_cancel_no_response_window()
				if _doudou_director != null:
					_doudou_director.notify_player_restarted()
		KEY_Q:
			_reset_flow()
		_:
			return
	if reset_wait and _return_mode == RETURN_MISS_IDLE:
		_miss_idle_left = MISS_IDLE_SEC
	get_viewport().set_input_as_handled()


func _in_claw_round() -> bool:
	if _business == null:
		return false
	var stage: int = _business.current_stage()
	return (
		stage == ClawBusinessNode.Stage.WAIT_START
		or stage == ClawBusinessNode.Stage.OPERATE
		or stage == ClawBusinessNode.Stage.GRABBING
	)


func _on_key_one() -> void:
	if _keyboard_minigame_choice(true):
		return
	_set_debug_note( "现在按 1 无效（失败邀请时同意小游戏）。")
	_refresh_hud()


func _on_key_two() -> void:
	if _keyboard_minigame_choice(false):
		return
	_set_debug_note( "现在按 2 无效（失败邀请时拒绝小游戏）。")
	_refresh_hud()


func _keyboard_minigame_choice(play: bool) -> bool:
	if _business == null:
		return false
	var inviting := _show != null and String(_show.get("last_action")) == "invite_minigame"
	var listening := _invite_flow != null and _invite_flow.holds_schedule()
	if not inviting and not listening and not _business.is_invite_listen():
		return false
	var intent := "PLAY" if play else "DECLINE"
	if _invite_flow != null and _invite_flow.holds_schedule():
		_invite_flow.accept_keyboard_intent(intent)
	elif _business.is_invite_listen():
		_business.submit_invite_intent(intent)
		_after_invite_business(intent)
	elif inviting:
		_business.arm_keyboard_invite(intent)
	else:
		return false
	_set_debug_note( "键盘选择：%s。" % ("进入小游戏" if play else "不玩小游戏"))
	_refresh_hud()
	return true


func _on_coin_pressed() -> void:
	_end_voice_for_business("coin")
	var result := _submit(ClawBusinessNode.COIN_ACCEPTED)
	# 测试场景按一次 T 投满本局币，立刻切投币欢迎，不要停在呼吸待机。
	if (
		_business.current_stage() == ClawBusinessNode.Stage.STANDBY
		and not _business.is_welcome_busy()
		and _business.coin_balance() < ClawBusinessNode.ROUND_COST
	):
		result = _submit(ClawBusinessNode.COIN_ACCEPTED)
	if bool(result.get("ok", false)) and _claw_audio != null and _claw_audio.has_method("play_coin"):
		_claw_audio.play_coin()


func _on_player_walk_in() -> void:
	if _minigame_covers_ui() or _business == null:
		return
	_clear_return_performance()
	_voice_coin_grace_left = -1.0
	var entered := _submit(ClawBusinessNode.PLAYER_ENTERED)
	if not bool(entered.get("ok", false)) and not _business.has_visitor():
		return
	if not preview_ai_may_continuous_listen():
		_set_debug_note( "现在不能进入语音。")
		_refresh_hud()
		return
	_ai_pose_locked = true
	_voice_processing = false
	if _ai_voice != null:
		_ai_voice.open_interaction_window()
	if _left_hud != null:
		_left_hud.apply_voice_status_event("wait_listen", {})
	_arm_voice_silence_leave()
	perf_play_listen_idle()
	_set_debug_note( "走近了。正在倾听；5 秒无人讲话会招揽。")
	_refresh_hud()


func preview_ai_may_continuous_listen() -> bool:
	if _business == null or _minigame_covers_ui():
		return false
	if _business.current_stage() != ClawBusinessNode.Stage.STANDBY:
		return false
	if _business.is_welcome_busy() or not _business.has_visitor():
		return false
	if _business.is_invite_listen():
		return false
	if _invite_flow != null and _invite_flow.holds_schedule():
		return false
	return true


func preview_ai_may_resume_attract() -> bool:
	return preview_ai_may_continuous_listen()


func perf_resume_precoin_attract() -> void:
	## 协调器 ATTRACT：窗口内先倾听；满 5 秒无人讲话才由静默计时切招揽×2+呼吸
	if not _ai_pose_locked or not preview_ai_may_resume_attract():
		return
	_voice_processing = false
	if _ai_voice != null and _ai_voice.is_window_armed():
		_arm_voice_silence_leave()
	perf_play_listen_idle()


func perf_play_listen_idle() -> void:
	if not _ai_pose_locked:
		return
	_voice_processing = false
	_pending_breath_after_hear = false
	_pending_think_after_hear = false
	_pending_speak_after_hear = false
	_pending_window_attract_after_hear = false
	_think_phase = ""
	_window_attract_count = 0
	if _voice_pose_mode == VOICE_POSE_LISTEN:
		## 已在倾听：若正在播听则不重切，等播完按原循环接呼吸
		if _is_playing_hear_clip():
			return
		_play_voice_clip(HEAR_CLIP, false)
		_prefetch_youyou(BREATH_CLIP, true)
		return
	_voice_pose_mode = VOICE_POSE_LISTEN
	_speak_phase = ""
	_play_voice_clip(HEAR_CLIP, false)
	_prefetch_youyou(BREATH_CLIP, true)


func perf_play_ai_speak() -> void:
	if not _ai_pose_locked:
		return
	_voice_processing = false
	_pending_breath_after_hear = false
	_pending_think_after_hear = false
	_pending_window_attract_after_hear = false
	if _voice_pose_mode == VOICE_POSE_SPEAK:
		_pending_speak_after_hear = false
		return
	_prefetch_youyou(THINK_END_CLIP, true)
	_prefetch_youyou(SPEAK_OPEN_CLIP, false)
	if _is_playing_hear_clip():
		_pending_speak_after_hear = true
		return
	_start_speak_via_think3()


func perf_stop_ai_speak_pose() -> void:
	pass


func perf_clear_presentation() -> void:
	pass


func preview_ai_on_coord_debug(_tag: String, _detail: String) -> void:
	pass


func preview_ai_voice_status(event: String, ctx: Dictionary) -> void:
	match event:
		"vad_listen", "asr", "llm_think", "tts_prep", "playback":
			_silence_leave_at_msec = 0
			if _ai_voice != null:
				_ai_voice.bump_window_for_activity()
			## 静默招揽中有人说话：回到倾听
			if event == "vad_listen" and _voice_pose_mode == VOICE_POSE_WINDOW_ATTRACT:
				perf_play_listen_idle()
		"wait_listen":
			_voice_processing = false
			if _ai_voice != null and _ai_voice.is_window_armed():
				_arm_voice_silence_leave()
			if _voice_pose_mode == VOICE_POSE_WINDOW_ATTRACT:
				perf_play_listen_idle()
	if event == "asr" or event == "llm_think" or event == "tts_prep":
		_voice_processing = true
		_window_attract_count = 0
		_pending_window_attract_after_hear = false
		## 识别/思考/准备回答：think1→循环 think2。倾听播完再切；呼吸待机可直接打断。
		if _voice_pose_mode == VOICE_POSE_THINK:
			pass
		elif _is_playing_hear_clip():
			_pending_think_after_hear = true
			_prefetch_youyou(THINK_OPEN_CLIP, true)
		else:
			_begin_think_loop(true)
	if _ai_player_status != null:
		_ai_player_status.handle(event, ctx)
	if _left_hud != null:
		_left_hud.apply_voice_status_event(event, ctx)


func preview_ai_on_window_closed(reason: String, _resume_attract: bool) -> void:
	_silence_leave_at_msec = 0
	_voice_processing = false
	_pending_think_after_hear = false
	_pending_speak_after_hear = false
	_pending_window_attract_after_hear = false
	_think_phase = ""
	_window_attract_count = 0
	if _left_hud != null:
		_left_hud.apply_voice_status_event("session_closed", {"silent": true})
	if _ai_player_status != null:
		_ai_player_status.on_window_closed(reason)
	if reason == "coin" or reason == "player_left" or reason == "business_event" or reason == "reset":
		_voice_coin_grace_left = -1.0
		_ai_pose_locked = false
		_voice_pose_mode = VOICE_POSE_NONE
		_set_return_suppressed(false)
		return
	if _business == null or not _business.has_visitor():
		_ai_pose_locked = false
		_voice_pose_mode = VOICE_POSE_NONE
		_set_return_suppressed(false)
		if _show != null and _show.has_method("resume_random_idle"):
			_show.resume_random_idle()
		return
	if _business.current_stage() != ClawBusinessNode.Stage.STANDBY or _business.is_welcome_busy():
		_ai_pose_locked = false
		_voice_pose_mode = VOICE_POSE_NONE
		_set_return_suppressed(false)
		return
	## 窗口结束：回到无人时的待机招揽组合
	_voice_coin_grace_left = VOICE_COIN_GRACE_SEC
	_ai_pose_locked = false
	_voice_pose_mode = VOICE_POSE_NONE
	_set_return_suppressed(false)
	if _show != null and _show.has_method("resume_random_idle"):
		_show.resume_random_idle()
	_set_debug_note( "语音窗口结束，回到待机招揽。5 秒内按 T 投币，否则离开交互。")
	_refresh_hud()


func _sync_voice_panel_situation() -> void:
	if _left_hud == null:
		return
	var mode := ""
	var remain := -1.0
	if _invite_flow != null:
		match _invite_flow.phase_name():
			"PLAYING":
				mode = "invite_ask"
			"WAITING_ANSWER":
				mode = "invite_wait"
			"LISTENING":
				mode = "invite_listen"
				remain = _invite_flow.listen_remaining_sec()
	_left_hud.set_voice_situation(mode, remain)


func _arm_voice_silence_leave() -> void:
	_silence_leave_at_msec = Time.get_ticks_msec() + int(VOICE_SILENCE_LEAVE_SEC * 1000.0)


func _poll_voice_silence_leave() -> void:
	if _silence_leave_at_msec <= 0:
		return
	if _ai_voice == null or not _ai_voice.is_window_armed():
		_silence_leave_at_msec = 0
		return
	if Time.get_ticks_msec() < _silence_leave_at_msec:
		return
	## 5 秒无人讲话：不关窗口，切招揽×2+呼吸循环；有人再讲话回到倾听
	_silence_leave_at_msec = 0
	_begin_window_attract_cycle()


func _begin_window_attract_cycle() -> void:
	if not _ai_pose_locked:
		return
	## 倾听播完前不打断，挂起等听结束再招揽
	if _is_playing_hear_clip():
		_pending_window_attract_after_hear = true
		_silence_leave_at_msec = 0
		return
	_voice_processing = false
	_pending_breath_after_hear = false
	_pending_think_after_hear = false
	_pending_speak_after_hear = false
	_pending_window_attract_after_hear = false
	_think_phase = ""
	_speak_phase = ""
	_window_attract_count = 0
	_voice_pose_mode = VOICE_POSE_WINDOW_ATTRACT
	_play_next_window_attract()
	_set_debug_note( "窗口内静默：招揽×2 + 呼吸循环。讲话可回到倾听。")


func _play_next_window_attract() -> void:
	if _voice_pose_mode != VOICE_POSE_WINDOW_ATTRACT:
		return
	var clip := ""
	if _window_attract_count < 2:
		if _show != null and _show.has_method("pick_random_attract"):
			clip = String(_show.pick_random_attract())
			if _show.has_method("note_picked_attract"):
				_show.note_picked_attract(clip)
		if clip == "":
			clip = "youyou_Attract_1"
		_window_attract_count += 1
		_play_voice_clip(clip, false)
		if _window_attract_count >= 2:
			_prefetch_youyou(BREATH_CLIP, true)
		elif _show != null and _show.has_method("pick_random_attract"):
			_prefetch_youyou(String(_show.pick_random_attract()), true)
		return
	_window_attract_count = 0
	_play_voice_clip(BREATH_CLIP, false)
	if _show != null and _show.has_method("pick_random_attract"):
		_prefetch_youyou(String(_show.pick_random_attract()), true)


func _tick_voice_window(delta: float) -> void:
	_tick_speak_tail()
	_poll_voice_silence_leave()
	if _voice_coin_grace_left < 0.0:
		return
	if _business == null:
		_voice_coin_grace_left = -1.0
		return
	if _business.current_stage() != ClawBusinessNode.Stage.STANDBY or _business.is_welcome_busy():
		_voice_coin_grace_left = -1.0
		_ai_pose_locked = false
		return
	_voice_coin_grace_left -= delta
	if _voice_coin_grace_left > 0.0:
		return
	_voice_coin_grace_left = -1.0
	_ai_pose_locked = false
	_set_return_suppressed(false)
	if _business.has_visitor():
		_submit(ClawBusinessNode.PLAYER_LEFT)
	elif _show != null and _show.has_method("resume_random_idle"):
		_show.resume_random_idle()
	_set_debug_note( "没有投币，回到随机待机。")
	_refresh_hud()


func _end_voice_for_business(reason: String) -> void:
	_ai_pose_locked = false
	_voice_processing = false
	_voice_pose_mode = VOICE_POSE_NONE
	_pending_breath_after_hear = false
	_pending_think_after_hear = false
	_pending_speak_after_hear = false
	_pending_window_attract_after_hear = false
	_hear_hold_until_finished = false
	_speak_phase = ""
	_think_phase = ""
	_window_attract_count = 0
	_silence_leave_at_msec = 0
	_voice_coin_grace_left = -1.0
	_set_return_suppressed(false)
	if _left_hud != null:
		_left_hud.apply_voice_status_event("session_closed", {"silent": true})
	if _ai_voice != null:
		_ai_voice.request_preempt(reason, false)


func _is_playing_hear_clip() -> bool:
	if _hear_hold_until_finished:
		return true
	if _character == null:
		return _voice_pose_clip == HEAR_CLIP
	var current := ""
	if _character.has_method("current_clip"):
		current = String(_character.call("current_clip"))
	if current == "":
		current = String(_character.animation)
	if current == HEAR_CLIP:
		return not _character.has_method("is_playing") or _character.is_playing()
	return _voice_pose_clip == HEAR_CLIP and _character.has_method("is_playing") and _character.is_playing()


func _start_speak_via_think3() -> void:
	## 准备开口：先 think3，再接说话1
	_pending_speak_after_hear = false
	_pending_breath_after_hear = false
	_pending_think_after_hear = false
	_pending_window_attract_after_hear = false
	_think_phase = ""
	_voice_pose_mode = VOICE_POSE_SPEAK
	_speak_phase = "pre"
	_prefetch_youyou(SPEAK_OPEN_CLIP, true)
	_prefetch_youyou(SPEAK_LOOP_CLIP, false)
	_play_voice_clip(THINK_END_CLIP, false)


func _begin_think_loop(force: bool = false) -> void:
	## 识别/思考/准备回答：think1 → 循环 think2。倾听未播完一律等；呼吸待机可直接打断。
	_pending_speak_after_hear = false
	_pending_window_attract_after_hear = false
	if _is_playing_hear_clip():
		_pending_think_after_hear = true
		_prefetch_youyou(THINK_OPEN_CLIP, true)
		return
	_pending_think_after_hear = false
	_pending_breath_after_hear = false
	if _voice_pose_mode == VOICE_POSE_THINK and (_think_phase == "open" or _think_phase == "loop"):
		return
	_voice_pose_mode = VOICE_POSE_THINK
	_think_phase = "open"
	_speak_phase = ""
	_prefetch_youyou(THINK_LOOP_CLIP, true)
	_play_voice_clip(THINK_OPEN_CLIP, false)


func _begin_breath_loop(force: bool = false) -> void:
	_pending_speak_after_hear = false
	_pending_think_after_hear = false
	_think_phase = ""
	if _is_playing_hear_clip():
		_pending_breath_after_hear = true
		return
	_pending_breath_after_hear = false
	_voice_pose_mode = VOICE_POSE_BREATH
	_speak_phase = ""
	_play_voice_clip(BREATH_CLIP, true)


func _prefetch_youyou(clip_name: String, urgent: bool = false) -> void:
	if clip_name == "" or _character == null or not _character.has_method("prefetch_clip"):
		return
	_character.call("prefetch_clip", clip_name, urgent)


func _play_voice_clip(clip_name: String, loop: bool) -> void:
	if not _ai_pose_locked or clip_name == "":
		return
	## 倾听播完前不打断；下一阶段由 pending 在听结束后接上
	if clip_name != HEAR_CLIP and _is_playing_hear_clip():
		return
	_voice_pose_clip = clip_name
	_hear_hold_until_finished = clip_name == HEAR_CLIP
	if _pose != null:
		_pose.force_off()
	if _show != null and _show.has_method("suspend_for_return"):
		_show.suspend_for_return()
	_set_return_suppressed(true)
	if (
		loop
		and _character != null
		and _character.has_method("current_clip")
		and _character.has_method("is_looping_clip")
		and String(_character.call("current_clip")) == clip_name
		and bool(_character.call("is_looping_clip"))
		and _character.is_playing()
	):
		return
	if _character != null and _character.has_method("play_clip"):
		_character.call("play_clip", clip_name, loop, false)
	if _show != null and _show.has_method("note_clip"):
		_show.note_clip("voice", clip_name)


func _advance_voice_pose(clip_name: String) -> bool:
	if not _ai_pose_locked:
		return false
	if _voice_pose_mode == VOICE_POSE_LISTEN:
		if clip_name == HEAR_CLIP:
			_hear_hold_until_finished = false
			if _pending_speak_after_hear:
				_start_speak_via_think3()
				return true
			if _voice_processing or _pending_think_after_hear:
				_begin_think_loop(true)
				return true
			if _pending_window_attract_after_hear:
				_pending_window_attract_after_hear = false
				_begin_window_attract_cycle()
				return true
			if _pending_breath_after_hear:
				_begin_breath_loop(true)
				return true
			_play_voice_clip(BREATH_CLIP, false)
			_prefetch_youyou(HEAR_CLIP, true)
			return true
		if clip_name == BREATH_CLIP:
			_play_voice_clip(HEAR_CLIP, false)
			_prefetch_youyou(BREATH_CLIP, true)
			return true
		return false
	if _voice_pose_mode == VOICE_POSE_THINK:
		if clip_name == THINK_OPEN_CLIP:
			_think_phase = "loop"
			_play_voice_clip(THINK_LOOP_CLIP, true)
			return true
		return false
	if _voice_pose_mode == VOICE_POSE_WINDOW_ATTRACT:
		_play_next_window_attract()
		return true
	if _voice_pose_mode != VOICE_POSE_SPEAK:
		return false
	if _speak_phase == "pre" and clip_name == THINK_END_CLIP:
		_speak_phase = "open"
		_prefetch_youyou(SPEAK_LOOP_CLIP, true)
		_play_voice_clip(SPEAK_OPEN_CLIP, false)
		return true
	if _speak_phase == "open" and clip_name == SPEAK_OPEN_CLIP:
		if _answer_should_end():
			_begin_speak_end()
		else:
			_speak_phase = "loop"
			_prefetch_youyou(SPEAK_END_CLIP, true)
			_play_voice_clip(SPEAK_LOOP_CLIP, true)
		return true
	if _speak_phase == "end" and clip_name == SPEAK_END_CLIP:
		return true
	return false


func _tick_speak_tail() -> void:
	if _voice_pose_mode != VOICE_POSE_SPEAK or _speak_phase != "loop":
		return
	if not _answer_should_end():
		return
	_begin_speak_end()


func _begin_speak_end() -> void:
	_speak_phase = "end"
	_play_voice_clip(SPEAK_END_CLIP, false)


func _answer_should_end() -> bool:
	var timing := _answer_timing()
	if timing.is_empty() or not bool(timing.get("synth_done", false)):
		return false
	var total := float(timing.get("total_sec", 0.0))
	var played := float(timing.get("played_sec", 0.0))
	if total <= 0.05:
		return false
	return total - played <= SPEAK_END_SEC


func _answer_timing() -> Dictionary:
	if _ai_voice == null or not _ai_voice.has_method("get_voice_output"):
		return {}
	var output: VoiceOutput = _ai_voice.get_voice_output()
	if output == null:
		return {}
	return output.answer_timing()


func _on_lean_idle_for_doudou() -> void:
	if _doudou_director == null or _business == null:
		return
	_doudou_director.on_operate_idle(_business.paid_round_count())


func _on_stand_finished() -> void:
	if _business.current_stage() != ClawBusinessNode.Stage.GRABBING:
		return
	if _pose != null and not bool(_pose.is_result_ready()):
		return
	var success := randi() % 2 == 0
	var event_id := ClawBusinessNode.GRAB_SUCCEEDED if success else ClawBusinessNode.GRAB_FAILED
	var extra := {} if success else {"next": "minigame"}
	## 先通知兜兜再走业务演出，避免结果片被后续状态切换挤掉
	if _doudou_director != null:
		_doudou_director.notify_result(success)
	_submit(event_id, extra)
	if _claw_audio != null and _claw_audio.has_method("play_outcome"):
		_claw_audio.play_outcome(success)
	_set_debug_note( "站起结束，随机判定%s。" % ("成功" if success else "失败"))
	_refresh_hud()


func _submit(event_id: String, extra: Dictionary = {}) -> Dictionary:
	var result: Dictionary = _business.submit(event_id, extra)
	_set_debug_note( String(result.get("note", "")))
	_refresh_hud()
	return result


func _on_situation_changed() -> void:
	if _return_mode != RETURN_NONE and _business != null:
		if _business.current_stage() != ClawBusinessNode.Stage.STANDBY or _business.is_welcome_busy():
			_clear_return_performance()
	if _ai_voice != null and _ai_voice.is_window_armed() and not preview_ai_may_continuous_listen():
		_end_voice_for_business("business_event")
	if _voice_coin_grace_left >= 0.0 and _business != null:
		if _business.current_stage() != ClawBusinessNode.Stage.STANDBY or _business.is_welcome_busy():
			_voice_coin_grace_left = -1.0
			_ai_pose_locked = false
	if _doudou_director != null and _business.is_invite_listen():
		_doudou_director.notify_guide_game_finished()
	if (
		_doudou_director != null
		and _business.current_stage() == ClawBusinessNode.Stage.STANDBY
		and not _business.is_welcome_busy()
		and _doudou_director.needs_exit()
	):
		_doudou_director.ensure_give_up_exit()
	if (
		_doudou_director != null
		and _business.paid_round_count() == 0
		and _business.current_stage() == ClawBusinessNode.Stage.STANDBY
		and not _business.is_welcome_busy()
		and not _doudou_director.is_leaving()
	):
		_doudou_director.dismiss()
	_refresh_hud()
	if not _in_solicit_idle():
		_clear_solicit_dialogue()
	call_deferred("_sync_invite_outcome")


func _maybe_start_invite_listen() -> void:
	if _business == null or _invite_flow == null:
		return
	if not _business.is_invite_listen():
		return
	if _invite_flow.phase_name() != "IDLE":
		return
	if _character != null and _character.has_method("is_voice_playing") and bool(_character.is_voice_playing()):
		return
	_invite_flow.begin_listen_after_guide()


func _sync_invite_outcome() -> void:
	if _business == null:
		return
	if _business.is_invite_play_accepted():
		_request_draw_scene_after_invite_play("accepted")


func _on_clip_changed(action_id: String, clip: String) -> void:
	_refresh_hud()
	print("Show %s → %s" % [action_id, clip])
	if not _in_solicit_idle() or action_id == "idle_breath" or action_id == "idle_base":
		_clear_solicit_dialogue()
	if action_id == "invite_minigame" and _invite_flow != null:
		_invite_flow.preconnect_for_upcoming_listen()
	if clip == "youyou_guideGame" and _doudou_director != null:
		_doudou_director.prefetch_exit_line()


func grab_log(message: String) -> void:
	print(message)


func invite_business_snapshot() -> Dictionary:
	if _business == null:
		return {}
	return {
		"stage": _business.stage_name(),
		"result_phase": _business.result_phase(),
		"invite_session": _business.invite_listen_session(),
	}


func minigame_invite_listen_ready() -> void:
	_set_debug_note( "麦克风已打开，请直接说：想玩 / 不玩。")
	_sync_invite_prompt()
	_refresh_hud()


func minigame_invite_listen_ended() -> void:
	_sync_invite_prompt()


func minigame_invite_reask(_token: int) -> void:
	_set_debug_note( "没听清，请再说想玩或不玩。")
	_sync_invite_prompt()


func minigame_invite_on_intent(intent: String, session: int = -1, reason: String = "") -> void:
	if _business == null:
		return
	if session >= 0 and _invite_flow != null and session != _invite_flow.invite_session_id():
		grab_log("[小游戏引导] 意愿=%s 已忽略（session=%d 过期）。" % [intent, session])
		return
	var result: Dictionary = _business.submit_invite_intent(intent)
	grab_log("[小游戏引导] intent=%s reason=%s ok=%s note=%s" % [
		intent, reason, str(result.get("ok", false)), String(result.get("note", "")),
	])
	_after_invite_business(intent)


func minigame_invite_on_error(reason: String, session: int = -1) -> void:
	if _business == null:
		return
	if session >= 0 and _invite_flow != null and session != _invite_flow.invite_session_id():
		return
	_business.finalize_invite_listen_error("语音识别异常：%s" % reason)
	_after_invite_business("ERROR")


func minigame_invite_cancelled(clear_visitor: bool = false) -> void:
	if _business == null:
		return
	_business.cancel_invite_listen(clear_visitor)
	_set_debug_note( "已取消小游戏邀请（不算拒绝）。")
	_sync_invite_prompt()
	_refresh_hud()


func _after_invite_business(outcome: String) -> void:
	if outcome == "PLAY" or outcome == "DECLINE":
		_cancel_no_response_window()
	if outcome == "PLAY":
		_set_debug_note( "同意玩小游戏，进入抽取转盘。")
		call_deferred("_request_draw_scene_after_invite_play", "voice_play")
		return
	if outcome == "DECLINE":
		if _invite_flow != null and _invite_flow.has_method("halt_for_other_show"):
			_invite_flow.halt_for_other_show()
		_set_debug_note( "先不玩小游戏，引导再抓一次。")
	_refresh_hud()


func _request_draw_scene_after_invite_play(reason: String) -> void:
	if _business == null or not _business.is_invite_play_accepted():
		return
	if _minigame_launch_pending:
		return
	_minigame_launch_pending = true
	grab_log("[小游戏抽取] 启动抽取场景 reason=%s" % reason)
	var result: Dictionary = _business.begin_minigame_after_invite_play()
	grab_log("[小游戏抽取] 业务 ok=%s note=%s" % [
		str(result.get("ok", false)), String(result.get("note", "")),
	])
	if not bool(result.get("ok", false)):
		_minigame_launch_pending = false
		_set_debug_note( String(result.get("note", "小游戏启动失败。")))
		_refresh_hud()
		return
	if _invite_flow != null:
		_invite_flow.notify_minigame_started()
	if _doudou_director != null and not _doudou_director.is_leaving():
		_doudou_director.dismiss()
	_sync_minigame_overlay_chrome()
	_minigame_launch_pending = false
	_set_debug_note( "进入小游戏转盘。")
	_refresh_hud()


func _on_minigame_port_opened(_token: int) -> void:
	_free_plays_at_open = _current_free_plays()
	_clear_return_performance()
	_sync_minigame_overlay_chrome()
	_prefetch_youyou(PRIZE_CLIP, true)


func _on_minigame_port_finished(_token: int, another_grab: bool) -> void:
	var earned := another_grab or _current_free_plays() > _free_plays_at_open
	var settled := false
	if _business != null and _business.has_method("finish_minigame_quietly"):
		settled = bool(_business.finish_minigame_quietly())
	if _minigame_host != null and _minigame_host.has_method("close_round"):
		_minigame_host.close_round()
	if _invite_flow != null:
		_invite_flow.notify_minigame_started()
	_sync_minigame_overlay_chrome()
	if settled:
		call_deferred("_begin_minigame_return", earned)
	_refresh_hud()


func _begin_minigame_return(earned: bool) -> void:
	if _business == null or _business.current_stage() != ClawBusinessNode.Stage.STANDBY:
		return
	if _business.is_welcome_busy():
		return
	if _pose != null:
		_pose.force_off()
	if _show != null and _show.has_method("suspend_for_return"):
		_show.suspend_for_return()
	if earned:
		_return_mode = RETURN_PRIZE
		_free_round_ready = false
		_play_return_clip(PRIZE_CLIP, false)
		_set_debug_note( "获得一次抓取机会。播完后按 O 免费开局。")
	else:
		_return_mode = RETURN_MISS_RETRY
		_free_round_ready = false
		_play_return_clip(RETRY_CLIP, false)
		_set_debug_note( "没有抓取机会。再试一次怎么样。")
	_refresh_hud()


func _on_return_clip_finished(clip_name: String) -> void:
	var invite_already_chosen := (
		_business != null
		and _business.has_method("has_pending_keyboard_invite")
		and _business.has_pending_keyboard_invite()
	)
	if _doudou_director != null and (clip_name == "youyou_guideGame" or not invite_already_chosen):
		_doudou_director.notify_youyou_clip_finished(clip_name)
	if _youyou_tail_needs_exit(clip_name) and not invite_already_chosen:
		_arm_no_response_window()
	if _advance_voice_pose(clip_name):
		return
	if _return_mode == RETURN_PRIZE and clip_name == PRIZE_CLIP:
		_free_round_ready = true
		_set_debug_note( "按 O 免费开一局，不扣币。")
		_refresh_hud()
		return
	if _return_mode == RETURN_MISS_RETRY and clip_name == RETRY_CLIP:
		_return_mode = RETURN_MISS_IDLE
		_miss_idle_left = MISS_IDLE_SEC
		_play_return_clip(BREATH_CLIP, true)
		_set_debug_note( "呼吸待机 10 秒。没有重开就进入随机待机招揽。")
		_refresh_hud()


func _tick_return_wait(delta: float) -> void:
	if _return_mode != RETURN_MISS_IDLE:
		return
	if _business != null and (
		_business.current_stage() != ClawBusinessNode.Stage.STANDBY
		or _business.is_welcome_busy()
	):
		_clear_return_performance()
		return
	_miss_idle_left -= delta
	if _miss_idle_left > 0.0:
		return
	_return_mode = RETURN_NONE
	_miss_idle_left = 0.0
	_set_return_suppressed(false)
	if _show != null and _show.has_method("resume_random_idle"):
		_show.resume_random_idle()
	_set_debug_note( "呼吸待机 10 秒没有重开，进入随机待机招揽。")
	_refresh_hud()


func _youyou_tail_needs_exit(clip_name: String) -> bool:
	if clip_name == "youyou_guideGame" or clip_name == "youyou_guideNext_2":
		return true
	return (
		clip_name == "youyou_guideNext_1"
		and _business != null
		and _business.paid_round_count() >= 2
	)


func _arm_no_response_window() -> void:
	_no_response_left = NO_RESPONSE_SEC


func _cancel_no_response_window() -> void:
	_no_response_left = -1.0


func _tick_no_response(delta: float) -> void:
	if _no_response_left < 0.0 or _business == null:
		return
	var stage: int = _business.current_stage()
	if stage == ClawBusinessNode.Stage.STANDBY:
		_cancel_no_response_window()
		return
	if (
		stage == ClawBusinessNode.Stage.MINIGAME
		or stage == ClawBusinessNode.Stage.WAIT_START
		or stage == ClawBusinessNode.Stage.OPERATE
		or stage == ClawBusinessNode.Stage.GRABBING
	):
		_cancel_no_response_window()
		return
	_no_response_left -= delta
	if _no_response_left > 0.0:
		return
	_finish_no_response_window()


func _finish_no_response_window() -> void:
	_no_response_left = -1.0
	if _business == null:
		return
	if _invite_flow != null and _invite_flow.has_method("halt_for_other_show"):
		_invite_flow.halt_for_other_show()
	if _doudou_director != null:
		_doudou_director.ensure_give_up_exit()
	var stage: int = _business.current_stage()
	if stage == ClawBusinessNode.Stage.STANDBY and not _business.is_welcome_busy():
		if _show != null and _show.has_method("resume_random_idle"):
			_show.resume_random_idle()
		_set_debug_note( "10 秒没有玩家响应，兜兜离场，柚柚进入待机招揽，本局结束。")
		_refresh_hud()
		return
	if _business.has_method("end_round_no_response"):
		_business.end_round_no_response()
	_set_debug_note( "10 秒没有玩家响应，兜兜离场，柚柚进入待机招揽，本局结束。")
	_refresh_hud()


func _try_free_round_key() -> bool:
	if _return_mode != RETURN_PRIZE:
		return false
	if not _free_round_ready:
		_set_debug_note( "先看完恭喜，再按 O 免费开局。")
		_refresh_hud()
		return true
	_start_free_round()
	return true


func _start_free_round() -> void:
	_cancel_no_response_window()
	_end_voice_for_business("business_event")
	var spend := maxi(0, _current_free_plays() - _free_plays_at_open)
	_clear_return_performance()
	while spend > 0 and GameState.consume_free_play():
		spend -= 1
	var result: Dictionary = _business.begin_free_grab_round()
	_set_debug_note( String(result.get("note", "免费开局。")))
	_refresh_hud()


func _play_return_clip(clip_name: String, loop: bool) -> void:
	_set_return_suppressed(true)
	if _character != null and _character.has_method("play_clip"):
		_character.call("play_clip", clip_name, loop, false)
	if _show != null and _show.has_method("note_clip"):
		_show.note_clip("round_over", clip_name)


func _clear_return_performance() -> void:
	_return_mode = RETURN_NONE
	_free_round_ready = false
	_miss_idle_left = 0.0
	_set_return_suppressed(false)


func _set_return_suppressed(on: bool) -> void:
	if _character != null and _character.has_method("set_target_suppressed"):
		_character.call("set_target_suppressed", on)


func _current_free_plays() -> int:
	return int(GameState.free_claw_plays)


func _on_minigame_play_scene(active: bool) -> void:
	_sync_minigame_overlay_chrome()
	if active:
		_set_claw_bgm_suspended(true)


func _on_lobby_music_suspended(suspended: bool) -> void:
	_set_claw_bgm_suspended(suspended)


func _set_claw_bgm_suspended(suspended: bool) -> void:
	if _claw_audio == null:
		return
	if suspended and _claw_audio.has_method("pause_bgm"):
		_claw_audio.pause_bgm()
	elif not suspended and _claw_audio.has_method("resume_bgm"):
		_claw_audio.resume_bgm()


func _minigame_covers_ui() -> bool:
	return _minigame_host != null and _minigame_host.has_method("covers_screen") and bool(_minigame_host.covers_screen())


func _sync_minigame_overlay_chrome() -> void:
	var hide := _minigame_covers_ui()
	if _bg_layer != null:
		_bg_layer.visible = not hide
	if _doudou_layer != null:
		_doudou_layer.visible = not hide
	if _character_layer != null:
		_character_layer.visible = not hide
	if _ui_layer != null:
		_ui_layer.visible = not hide
	if _hud != null:
		_hud.visible = not hide
	if _flow_hint_panel != null:
		_flow_hint_panel.visible = false
	if _left_hud != null:
		_left_hud.visible = not hide
	if hide:
		if _character != null and _character.has_method("is_voice_playing") and bool(_character.is_voice_playing()):
			_character.stop_playback()
	_sync_invite_prompt()


func _force_close_minigame() -> void:
	if not _minigame_covers_ui():
		_set_debug_note( "当前没有打开的小游戏。")
		_refresh_hud()
		return
	if _minigame_host != null and _minigame_host.has_method("close_round"):
		_minigame_host.close_round()
	_minigame.notify_finished(false)
	_sync_minigame_overlay_chrome()
	_refresh_hud()


func _reset_flow() -> void:
	if _invite_flow != null:
		_invite_flow.debug_reset_flow()
	if _minigame_host != null and _minigame_host.has_method("close_round"):
		_minigame_host.close_round()
	_minigame_launch_pending = false
	_end_voice_for_business("reset")
	_clear_return_performance()
	_cancel_no_response_window()
	_sync_invite_prompt()
	if _pose != null:
		_pose.force_off()
	if _doudou_director != null:
		_doudou_director.dismiss()
	_business.reset_for_retest()
	_sync_minigame_overlay_chrome()
	_refresh_hud()
	_set_debug_note( "已重置到待机。")


func _sync_invite_prompt() -> void:
	if _invite_prompt == null:
		return
	var show_prompt := (
		_business != null
		and _business.is_invite_listen()
		and not _minigame_covers_ui()
	)
	if _invite_prompt.visible != show_prompt:
		_invite_prompt.visible = show_prompt


func _on_neutral_play(_action_id: String) -> void:
	if _pose != null:
		_pose.force_off()


func _set_debug_note(text: String) -> void:
	if _note != null:
		_note.text = text


func _refresh_hud() -> void:
	if _business == null:
		return
	if _status != null:
		var visitor := "有人" if _business.has_visitor() else "无人"
		var phase := _business.result_phase()
		var phase_bit := (" / " + phase) if phase != "" else ""
		var clip := "—"
		var action := "—"
		if _show != null:
			clip = String(_show.get("last_clip"))
			action = String(_show.get("last_action"))
		var pose := ""
		if _pose != null:
			pose = String(_pose.label())
		if pose != "":
			pose = " · 操作 " + pose
		_status.text = "阶段 %s%s · 币 %d · %s · 片 %s（%s）%s%s" % [
			_business.stage_name(),
			phase_bit,
			_business.coin_balance(),
			visitor,
			clip,
			action,
			pose,
			" · 小游戏" if _minigame_covers_ui() else "",
		]
	if _note != null and _business.last_note != "" and (_note.text == "" or _note.text.begins_with("Show")):
		_note.text = _business.last_note
	if _left_hud != null:
		_left_hud.set_coin_count(_business.coin_balance())
	_refresh_flow_hint()


func on_voice_subtitle_audio(audio_path: String) -> void:
	if _left_hud == null:
		return
	if not _in_solicit_idle():
		_clear_solicit_dialogue()
		return
	var line := YouyouVoiceSubtitleCatalog.subtitle_for_audio_path(audio_path)
	if line.is_empty():
		return
	_left_hud.set_dialogue(line)


func _in_solicit_idle() -> bool:
	if _business == null or _minigame_covers_ui() or _ai_pose_locked:
		return false
	if _business.current_stage() != ClawBusinessNode.Stage.STANDBY or _business.is_welcome_busy():
		return false
	if _show != null and _show.has_method("is_random_idle"):
		return bool(_show.is_random_idle())
	return false


func _clear_solicit_dialogue() -> void:
	if _left_hud != null:
		_left_hud.set_dialogue("")


func _refresh_flow_hint() -> void:
	if _flow_hint == null:
		return
	var text := _flow_hint_text()
	if _flow_hint.text != text:
		_flow_hint.text = text


func _flow_hint_text() -> String:
	if _minigame_covers_ui():
		return "小游戏\n转盘抽取后直接进入游戏"
	if _return_mode == RETURN_PRIZE:
		if _free_round_ready:
			return "恭喜获得抓取机会\n按 O 免费开一局，不扣币"
		return "恭喜你获得一次抓取机会"
	if _return_mode == RETURN_MISS_RETRY:
		return "再试一次怎么样\n它悄悄跟我说，它喜欢你"
	if _return_mode == RETURN_MISS_IDLE:
		return "呼吸待机等待重开\n%.0f 秒内无操作则随机待机" % maxf(_miss_idle_left, 0.0)
	if _voice_coin_grace_left >= 0.0:
		return "语音结束\n%.0f 秒内按 T 投币，否则随机待机" % maxf(_voice_coin_grace_left, 0.0)
	if _ai_pose_locked and _ai_voice != null and _ai_voice.is_window_armed():
		if _voice_processing:
			if _is_playing_hear_clip() or _pending_think_after_hear:
				return "正在识别\n倾听播完后再切 think1→think2"
			return "识别、思考、准备回答\nthink1 → 循环 think2"
		if _voice_pose_mode == VOICE_POSE_LISTEN:
			return "正在聆听\n倾听不打断；播完再接下一阶段"
		if _voice_pose_mode == VOICE_POSE_WINDOW_ATTRACT:
			return "窗口静默招揽\n招揽×2 + 呼吸循环"
		if _voice_pose_mode == VOICE_POSE_SPEAK:
			if _speak_phase == "open":
				return "回答玩家\n说话1"
			if _speak_phase == "end":
				return "回答收尾\n说话3"
			return "回答玩家\n循环说话2"
		return "倾听\n循环呼吸待机"
	if _business == null:
		return "待机招揽"
	var stage: int = _business.current_stage()
	var result := _business.result_phase()
	var pose := String(_pose.label()) if _pose != null else ""
	var action := String(_show.get("last_action")) if _show != null else ""
	if stage == ClawBusinessNode.Stage.STANDBY:
		if _business.is_welcome_busy():
			return "投币欢迎\n正在播放开场"
		if _business.has_visitor():
			if _business.coin_balance() >= ClawBusinessNode.ROUND_COST:
				return "可以开局\n按 T 投币开始"
			return "有人走近\n按 T 投币开局"
		return "待机招揽\n按 M 走近开 AI 窗口"
	if stage == ClawBusinessNode.Stage.WAIT_START:
		return "投币欢迎\n想好了就试试吧"
	if stage == ClawBusinessNode.Stage.OPERATE:
		if pose == "倾身":
			return "开局倾身\n看向钩爪"
		if pose.begins_with("向") or pose == "仰头":
			return "看向钩爪\n松开 A / D / W / S 回到倾身待机"
		return "操作爪子\nA/D 左右看，W 向前，S 仰头 · G 下抓"
	if stage == ClawBusinessNode.Stage.GRABBING:
		if pose == "下蹲":
			return "下蹲抓取"
		if pose == "蹲着待机":
			return "蹲着待机\n按 B 往上抓"
		if pose == "站起":
			return "往上抓 · 站起"
		if pose == "已站起":
			return "站起结束\n正在判定结果"
		return "正在抓取"
	if stage == ClawBusinessNode.Stage.RESULT:
		match result:
			"feedback":
				if action == "result_success":
					return "抓到了"
				return "没抓到"
			"success_guide":
				return "成功引导\n下一只小可爱也在等你"
			"guide":
				if action == "invite_minigame":
					return "邀请小游戏\n要不要试试别的"
				return "结果引导"
			"invite_listen":
				if _no_response_left >= 0.0:
					return "等玩家回应\n%.0f 秒内无响应则本局结束" % maxf(_no_response_left, 0.0)
				return "呼吸待机，麦克风已开\n说想玩 / 不玩，或按 1 / 2"
			"invite_play_accepted":
				return "同意玩小游戏\n即将进入转盘"
			"fail_continue_guide":
				return "引导再抓一次\n播完进入呼吸待机"
			"success_hold", "fail_hold":
				return "呼吸待机 10 秒\n没重开则随机待机招揽"
			"invite_listen_error":
				return "没听清意愿\n回到待机"
			_:
				if action == "invite_minigame":
					return "邀请小游戏\n要不要试试别的"
				return "结果演出"
	if stage == ClawBusinessNode.Stage.MINIGAME:
		return "小游戏\n转盘抽取后直接进入游戏"
	return "当前流程"


func _play_move(direction: String) -> void:
	if _claw_audio != null and _claw_audio.has_method("play_move"):
		_claw_audio.play_move(direction)


func _play_grab_down() -> void:
	if _claw_audio != null and _claw_audio.has_method("play_grab_down"):
		_claw_audio.play_grab_down()


func _play_grab_up() -> void:
	if _claw_audio != null and _claw_audio.has_method("play_grab_up"):
		_claw_audio.play_grab_up()


func _apply_viewport() -> void:
	# 与 project.godot / youyou_arcade_hud 设计分辨率一致（1920×1080 keep）
	var window := get_window()
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	window.content_scale_size = VIEWPORT_SIZE
	window.title = "序列帧业务流程测试"
	var screen_size := DisplayServer.screen_get_size()
	var window_size := VIEWPORT_SIZE
	var margin := Vector2i(48, 88)
	if screen_size.x < VIEWPORT_SIZE.x + margin.x or screen_size.y < VIEWPORT_SIZE.y + margin.y:
		var fit := minf(
			float(screen_size.x - margin.x) / float(VIEWPORT_SIZE.x),
			float(screen_size.y - margin.y) / float(VIEWPORT_SIZE.y)
		)
		window_size = Vector2i(
			maxi(int(VIEWPORT_SIZE.x * fit), 960),
			maxi(int(VIEWPORT_SIZE.y * fit), 540)
		)
	window.size = window_size
	window.position = (screen_size - window_size) / 2


func _apply_ui_font() -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "Segoe UI"])
	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = 20
	var debug_hud := get_node_or_null("UiLayer/Hud")
	if debug_hud != null:
		debug_hud.theme = theme
	var flow_hint := get_node_or_null("UiLayer/FlowHint")
	if flow_hint != null:
		flow_hint.theme = theme
