extends Node2D
## 飞机大战壳：公共 API、输入、音频、结算。逻辑/表现分离。

const _LogicScript := preload("res://街机小游戏/scripts/plane/plane_logic.gd")
const _ViewScript := preload("res://街机小游戏/scripts/plane/plane_view.gd")
const _PATH_LOTTERY_TICKET := "res://街机小游戏/assets/plane/neon/lottery_ticket.png"

signal round_finished(points: int)
var _points_round_id := ""
signal ask_return_hub()

var active := false
var session_points := 0
var logic: RefCounted
var view: Node2D
var _board_hold := 0
var _fire_held := false ## 与方向键独立，避免抓取键/空格把摇杆状态冲掉
var _mock_stick_prev := -1
const _BOARD_DIR_MASK := (
	BoardLink.KEY_LEFT | BoardLink.KEY_RIGHT | BoardLink.KEY_UP | BoardLink.KEY_DOWN
)

var ui: CanvasLayer
var hud_score: Label
var hud_status: Label
var hud_title: Label
var hud_hint: Label
var overlay: ColorRect
var overlay_msg: Label
var overlay_sub: Label
var overlay_lottery: Label
var btn_ok: Button
var _hud_styled := false
var _shoot_sfx_cd := 0.0
var _eshot_sfx_cd := 0.0
var _hit_sfx_cd := 0.0
var _fx_kind := -1
var _countdown_i := -1
var _countdown_t := 0.0
const _COUNTDOWN_STEPS := ["3", "2", "1", "START"]
const _COUNTDOWN_STEP_SEC := 0.85
## 0=正常流程；1=第一个 Boss WARNING；2=第二个 Boss WARNING … 正式版改 0
const DEV_START_AT_BOSS_WARN := 0
const _JACKPOT_INIT := 752982
const _LOCAL_BONUS_INIT := 5284
const _COIN_COUNT_MAX := 999
const _COIN_DENOM := 2 ## 显示为 xx/02，分母固定
var _jackpot := _JACKPOT_INIT
var _local_bonus := _LOCAL_BONUS_INIT
var _coin_sig_hooked := false
var _credits_sig_hooked := false
const _SETTLE_ROLL_SEC := 5.0
## 结算彩票纯表现：固定数量炸开→聚拢，与真实张数无关
const _TICKET_BURST_COUNT := 32
const _TICKET_BURST_OUT_SEC := 0.40
const _TICKET_GATHER_FROM_SEC := 0.48
const _TICKET_GATHER_TO_SEC := 2.20
const _TICKET_BURST_DIST_MIN := 85.0
const _TICKET_BURST_DIST_MAX := 260.0
var _settle_roll_active := false
var _settle_roll_t := 0.0
var _settle_score_start := 0
var _settle_tickets_target := 0
var _ticket_fly_layer: Control
var _ticket_flies: Array[Dictionary] = []
var _tex_lottery: Texture2D


func _ready() -> void:
	logic = _LogicScript.new()
	view = _ViewScript.new()
	view.name = "PlaneView"
	add_child(view)
	move_child(view, 0)
	var h: Dictionary = HoneyMinigameHud.build(
		self, "飞机大战", "摇杆移动 · 抓取键射击（可长按）"
	)
	ui = h["ui"]
	hud_score = h["score"]
	hud_status = h["status"]
	hud_title = h["title"]
	hud_hint = h["hint"]
	overlay = h["overlay"]
	overlay_msg = h["msg"]
	overlay_sub = h["sub"]
	btn_ok = h["btn"]
	_style_hud()
	_build_overlay_lottery_label()
	_build_ticket_fly_layer()
	btn_ok.pressed.connect(_on_ok)
	overlay.gui_input.connect(_on_overlay_gui)
	visible = false
	set_process(false)
	set_process_input(true)
	_hook_coin_signals()
	_hook_credits_signals()
	if get_tree() and get_tree().current_scene == self:
		call_deferred("start_round")


func _hook_coin_signals() -> void:
	if _coin_sig_hooked:
		return
	if BoardLink.coin_inserted.is_connected(_on_coin_inserted):
		_coin_sig_hooked = true
		return
	BoardLink.coin_inserted.connect(_on_coin_inserted)
	_coin_sig_hooked = true


func _hook_credits_signals() -> void:
	if _credits_sig_hooked:
		return
	if BoardLink.credits_changed.is_connected(_on_machine_credits_changed):
		_credits_sig_hooked = true
		return
	BoardLink.credits_changed.connect(_on_machine_credits_changed)
	_credits_sig_hooked = true


func _on_machine_credits_changed(_credits: int) -> void:
	if visible and active:
		_push_arcade_hud()


func _machine_coin_display() -> int:
	return clampi(BoardLink.get_credits(), 0, _COIN_COUNT_MAX)


func _on_coin_inserted(amount: int, _credits: int) -> void:
	## 仅在本局飞机大战进行中计奖（与机台 coin_inserted 同源）
	if not active or not visible:
		return
	_apply_arcade_coin(maxi(1, amount))


func _apply_arcade_coin(n: int) -> void:
	for _i in n:
		_jackpot += 100
		_local_bonus += 100
		GameState.add_tokens(1)
	_push_arcade_hud()
	ArcadeAudio.sfx_coin()


## 编辑器/PC：F1 走 BoardLink 与真机相同投币帧，再触发 coin_inserted
func _simulate_arcade_coin() -> void:
	if not active or not visible:
		return
	BoardLink.simulate_coin_insert(1)


func _reset_arcade_hud() -> void:
	_jackpot = _JACKPOT_INIT
	_local_bonus = _LOCAL_BONUS_INIT
	_push_arcade_hud()


func _push_arcade_hud() -> void:
	if view == null:
		return
	view.arcade_jackpot = _jackpot
	view.arcade_local_bonus = _local_bonus
	## 左侧为娃娃机实机余币（BoardLink），格式 xx/02
	view.arcade_coin_in = _machine_coin_display()
	view.arcade_coin_need = _COIN_DENOM
	view.arcade_next_tip = "下一次：柚柚陪你玩"


func start_round() -> void:
	_points_round_id = GameState.begin_points_round("plane")
	visible = true
	z_index = 100
	ui.visible = true
	active = true
	set_process(true)
	BoardLink.take_control()
	_board_hold = 0
	_fire_held = false
	_mock_stick_prev = -1
	session_points = 0
	_reset_arcade_hud()
	logic.reset()
	if DEV_START_AT_BOSS_WARN > 0:
		logic.queue_boss_warning_start(DEV_START_AT_BOSS_WARN)
	logic.playing = false
	view.reset()
	_push_arcade_hud()
	_stop_settle_roll()
	overlay.visible = false
	if overlay_lottery:
		overlay_lottery.visible = false
	ArcadeAudio.play_plane()
	ArcadeAudio.set_minigame_tempo(1.0)
	_shoot_sfx_cd = 0.0
	_eshot_sfx_cd = 0.0
	_hit_sfx_cd = 0.0
	_begin_countdown()
	_refresh()
	view.sync(logic, 0.0)


func stop_and_hide() -> void:
	_stop_settle_roll()
	active = false
	_countdown_i = -1
	if view and view.has_method("hide_countdown"):
		view.hide_countdown()
	set_process(false)
	visible = false
	if ui:
		ui.visible = false
	if overlay:
		overlay.visible = false
	ArcadeAudio.on_game_over()


func on_board_key(mask: int, _pressed: bool = true) -> void:
	if overlay.visible:
		if mask & BoardLink.KEY_ENTER:
			_on_ok()
		return
	if not active:
		return
	## 倒计时引导期也接收机台输入，方便试飞
	_apply_board_mask(mask)


func _input(event: InputEvent) -> void:
	if not active or not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		_simulate_arcade_coin()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if overlay.visible:
		if event.is_action_pressed("ui_accept"):
			_on_ok()
			get_viewport().set_input_as_handled()
		return
	if not active:
		return
	if ProjectSettings.get_setting(BoardLink.SETTINGS_MOCK, true):
		return
	if event.is_action_pressed("ui_left"):
		logic.nudge(-1.0)
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_right"):
		logic.nudge(1.0)
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_up"):
		logic.nudge(0.0, -1.0)
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_down"):
		logic.nudge(0.0, 1.0)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _settle_roll_active:
		_tick_settle_roll(delta)
		return
	if not active:
		return
	if overlay.visible:
		return
	_poll_mock_stick()
	if not ProjectSettings.get_setting(BoardLink.SETTINGS_MOCK, true):
		_sync_board_from_link()
	var hold_l := _hold_dir(BoardLink.KEY_LEFT, KEY_A, KEY_LEFT, "ui_left")
	var hold_r := _hold_dir(BoardLink.KEY_RIGHT, KEY_D, KEY_RIGHT, "ui_right")
	var hold_u := _hold_dir(_board_up_bit(), KEY_W, KEY_UP, "ui_up")
	var hold_d := _hold_dir(_board_down_bit(), KEY_S, KEY_DOWN, "ui_down")
	var hold_fire := _hold_fire()
	if _countdown_i >= 0:
		_tick_countdown(delta)
		## 引导期可移动 / 试射，不刷怪
		var warm: Array = logic.tick_warmup(delta, hold_l, hold_r, hold_u, hold_d, hold_fire)
		for ev in warm:
			_on_logic_event(ev)
		view.sync(logic, delta)
		if view.has_method("tick_countdown"):
			view.tick_countdown(delta)
		_shoot_sfx_cd = maxf(0.0, _shoot_sfx_cd - delta)
		_refresh()
		return
	var events: Array = logic.tick(delta, hold_l, hold_r, hold_u, hold_d, hold_fire)
	for ev in events:
		_on_logic_event(ev)
	view.sync(logic, delta)
	_shoot_sfx_cd = maxf(0.0, _shoot_sfx_cd - delta)
	_eshot_sfx_cd = maxf(0.0, _eshot_sfx_cd - delta)
	_hit_sfx_cd = maxf(0.0, _hit_sfx_cd - delta)
	session_points = int(logic.score)
	_refresh()
	if logic.ended and not overlay.visible:
		_end(logic.end_reason)


func _begin_countdown() -> void:
	_countdown_i = 0
	_countdown_t = _COUNTDOWN_STEP_SEC
	if view.has_method("show_countdown"):
		view.show_countdown(_COUNTDOWN_STEPS[_countdown_i])
	ArcadeAudio.sfx_start()
	if hud_hint:
		hud_hint.visible = false


func _tick_countdown(delta: float) -> void:
	_countdown_t -= delta
	if _countdown_t > 0.0:
		return
	_countdown_i += 1
	if _countdown_i >= _COUNTDOWN_STEPS.size():
		_finish_countdown()
		return
	_countdown_t = _COUNTDOWN_STEP_SEC if _COUNTDOWN_STEPS[_countdown_i] != "START" else 0.70
	if view.has_method("show_countdown"):
		view.show_countdown(_COUNTDOWN_STEPS[_countdown_i])
	if _COUNTDOWN_STEPS[_countdown_i] == "START":
		ArcadeAudio.sfx_coin()
	else:
		ArcadeAudio.sfx_start()


func _finish_countdown() -> void:
	_countdown_i = -1
	_countdown_t = 0.0
	if view.has_method("hide_countdown"):
		view.hide_countdown()
	## 清掉引导期试射残留弹
	for b in logic.bullets:
		b["live"] = false
	logic.playing = true
	_board_hold = 0
	_fire_held = false
	_mock_stick_prev = -1
	if hud_hint:
		hud_hint.visible = true
		hud_hint.text = "摇杆移动 · 抓取键射击（长按连发）"


func _hold_dir(board_bit: int, key_wasd: Key, key_arrow: Key, action: String) -> bool:
	if (_board_hold & board_bit) != 0:
		return true
	if Input.is_physical_key_pressed(key_wasd) or Input.is_physical_key_pressed(key_arrow):
		return true
	return Input.is_action_pressed(action)


func _hold_fire() -> bool:
	## 开火与方向分开读：Z/J 不与方向键冲突；机台抓取键走独立锁存
	if _fire_held:
		return true
	if Input.is_physical_key_pressed(KEY_Z) or Input.is_physical_key_pressed(KEY_J):
		return true
	if Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_ENTER):
		return true
	return Input.is_action_pressed("ui_accept")


func _apply_board_mask(mask: int) -> void:
	var prev_dirs := _board_hold & _BOARD_DIR_MASK
	var dirs := mask & _BOARD_DIR_MASK
	var enter := (mask & BoardLink.KEY_ENTER) != 0

	if mask == 0:
		_board_hold = 0
		_fire_held = false
		return

	## 方向与开火独立更新，互不覆盖
	var next_dirs := dirs
	if dirs == 0 and enter:
		## 仅抓取键上报时保留当前摇杆方向
		next_dirs = prev_dirs
	elif dirs == 0 and not enter:
		next_dirs = 0

	if enter:
		_fire_held = true
	elif dirs != 0:
		## 带方向的完整键位里没有抓取 = 已松开开火
		_fire_held = false

	var next := next_dirs | (BoardLink.KEY_ENTER if _fire_held else 0)
	var edge := next_dirs & ~prev_dirs
	_board_hold = next
	if edge & BoardLink.KEY_LEFT:
		logic.nudge(-1.0)
	if edge & BoardLink.KEY_RIGHT:
		logic.nudge(1.0)
	if edge & _board_up_bit():
		logic.nudge(0.0, -1.0)
	if edge & _board_down_bit():
		logic.nudge(0.0, 1.0)


func _board_up_bit() -> int:
	# 实机摇杆向上时，控制板报的是已对调后的 KEY_DOWN。战机画面要跟手，不改全局键位。
	if _real_stick_y_inverted():
		return BoardLink.KEY_DOWN
	return BoardLink.KEY_UP


func _board_down_bit() -> int:
	if _real_stick_y_inverted():
		return BoardLink.KEY_UP
	return BoardLink.KEY_DOWN


func _real_stick_y_inverted() -> bool:
	return not bool(ProjectSettings.get_setting(BoardLink.SETTINGS_MOCK, false))


func _sync_board_from_link() -> void:
	if not active or overlay.visible:
		return
	var bits := BoardLink.get_current_key_bits()
	var prev_sig := (_board_hold & _BOARD_DIR_MASK) | (BoardLink.KEY_ENTER if _fire_held else 0)
	var next_sig := (bits & _BOARD_DIR_MASK) | (BoardLink.KEY_ENTER if (bits & BoardLink.KEY_ENTER) != 0 else 0)
	if next_sig == prev_sig and bits != 0:
		return
	if bits == 0 and prev_sig == 0:
		return
	_apply_board_mask(bits)


func _poll_mock_stick() -> void:
	if not ProjectSettings.get_setting(BoardLink.SETTINGS_MOCK, true):
		return
	if not active or overlay.visible:
		return
	## PC：方向与开火都直接读键盘，不再塞进同一 mask 互相覆盖
	var dirs := 0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_action_pressed("ui_left"):
		dirs |= BoardLink.KEY_LEFT
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_action_pressed("ui_right"):
		dirs |= BoardLink.KEY_RIGHT
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or Input.is_action_pressed("ui_up"):
		dirs |= BoardLink.KEY_UP
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) or Input.is_action_pressed("ui_down"):
		dirs |= BoardLink.KEY_DOWN
	var fire := (
		Input.is_physical_key_pressed(KEY_Z)
		or Input.is_physical_key_pressed(KEY_J)
		or Input.is_physical_key_pressed(KEY_SPACE)
		or Input.is_physical_key_pressed(KEY_ENTER)
		or Input.is_action_pressed("ui_accept")
	)
	_fire_held = fire
	var mask := dirs | (BoardLink.KEY_ENTER if fire else 0)
	if mask != _mock_stick_prev:
		var prev_dirs := _board_hold & _BOARD_DIR_MASK
		_board_hold = mask
		var edge := dirs & ~prev_dirs
		if edge & BoardLink.KEY_LEFT:
			logic.nudge(-1.0)
		if edge & BoardLink.KEY_RIGHT:
			logic.nudge(1.0)
		if edge & BoardLink.KEY_UP:
			logic.nudge(0.0, -1.0)
		if edge & BoardLink.KEY_DOWN:
			logic.nudge(0.0, 1.0)
		_mock_stick_prev = mask


func _on_logic_event(ev: Dictionary) -> void:
	if ev.is_empty():
		return
	var t := str(ev.get("type", ""))
	match t:
		"kill":
			if bool(ev.get("boss", false)):
				return
			var kind := int(ev.get("kind", 0))
			var gain := int(ev.get("gain", 0))
			var combo := int(ev.get("combo", 0))
			var nx := float(ev.get("x", 0.5))
			var ny := float(ev.get("y", 0.5))
			if kind == PlaneLogic.KIND_GOLD:
				view.spawn_score_gems(3, nx, ny)
			elif kind == PlaneLogic.KIND_PURPLE:
				view.spawn_score_gems(5, nx, ny)
			else:
				view.spawn_score_gems(1, nx, ny)
			view.burst_stars(nx, ny, 3 if kind >= 2 else 2)
			view.punch(3.0 if kind >= 2 else 2.2)
			view.float_text("+%d" % gain, nx, ny, Color("FFF4C0") if kind == 3 else Color("FFE08A"))
			if combo >= 3:
				view.float_text("连击", nx, ny - 0.06, Color("F5D76E"))
				view.punch(3.6 if logic.power_lv >= 2 else 2.4)
			_fx_kind = kind
		"hit":
			if _hit_sfx_cd <= 0.0:
				ArcadeAudio.sfx_plane_hit(int(ev.get("kind", 0)), bool(ev.get("boss", false)))
				_hit_sfx_cd = 0.045 if bool(ev.get("boss", false)) else 0.035
		"hurt":
			if int(ev.get("hp", 1)) <= 0:
				ArcadeAudio.sfx_plane_player_die()
				view.spawn_booms(float(ev.get("x", 0.5)), float(ev.get("y", 0.5)), 1, true)
			else:
				ArcadeAudio.sfx_plane_player_hurt()
			view.flash_hurt()
		"shield_block":
			ArcadeAudio.sfx_plane_shield_break()
			view.burst_stars(float(ev.get("x", 0.5)), float(ev.get("y", 0.5)), 2)
			view.punch(1.6)
		"bomb":
			ArcadeAudio.sfx_tetris_clear(4)
			ArcadeAudio.sfx_die()
			view.flash_bomb()
			var spots: Array = ev.get("spots", [])
			var n := 0
			for p in spots:
				if n >= 8:
					break
				if p is Vector2:
					view.burst_stars(p.x, p.y, 1)
					n += 1
			for extra in ev.get("extra", []):
				if extra is Dictionary:
					_on_logic_event(extra)
		"wave":
			ArcadeAudio.sfx_coin()
			view.show_wave(int(ev.get("wave", 2)), str(ev.get("title", "")))
		"warning":
			ArcadeAudio.sfx_plane_warning()
			view.show_warning()
		"boss_title":
			view.show_boss_title(str(ev.get("name", "BOSS")), str(ev.get("sub", "")))
		"pipe_break":
			## 破管提示音 + 碎片爆炸；爆炸走独立 FX 槽，不被后面的 boom 盖掉
			ArcadeAudio.sfx_tetris_clear(3)
			ArcadeAudio.sfx_plane_boss_part()
			view.punch(5.2)
			view.show_pickup("破管")
			view.float_text("破管", float(ev.get("x", 0.5)), float(ev.get("y", 0.28)), Color("FFE08A"))
		"part_drop":
			ArcadeAudio.sfx_plane_boss_part()
			view.punch(3.6)
			view.spawn_score_gems(2, float(ev.get("x", 0.5)), float(ev.get("y", 0.5)))
			## 同帧命中音会抢耳朵，短暂压一下
			_hit_sfx_cd = maxf(_hit_sfx_cd, 0.12)
		"boom":
			var boom_kind := int(ev.get("kind", _fx_kind))
			var boom_boss := bool(ev.get("boss", false))
			var wreck := bool(ev.get("wreck", false))
			var missile_break := bool(ev.get("missile", false))
			var silent := bool(ev.get("silent", false))
			## 零件/破管爆炸由 part_drop、pipe_break 负责；导弹拦截只爆画面
			if not wreck and not missile_break and not silent:
				ArcadeAudio.sfx_plane_explode(boom_kind, boom_boss)
			view.spawn_booms(float(ev.get("x", 0.5)), float(ev.get("y", 0.5)), int(ev.get("n", 1)), bool(ev.get("big", false)), boom_kind if boom_kind >= 0 else _fx_kind)
			_fx_kind = -1
			if bool(ev.get("big", false)):
				view.punch(4.6)
			elif missile_break:
				view.punch(1.1)
			else:
				view.punch(1.8)
		"boss_kill":
			view.flash_bomb()
			view.punch(5.6)
			view.spawn_score_gems(10, float(ev.get("x", 0.5)), float(ev.get("y", 0.5)))
			var kt := "霸王击破" if int(ev.get("style", 0)) >= 4 else "击破"
			view.show_pickup(kt)
			view.float_text(kt, float(ev.get("x", 0.5)), float(ev.get("y", 0.28)), Color("FFE08A"))
		"combo_break":
			var rubies := int(ev.get("gems", 0))
			if rubies <= 0:
				return
			var gain_cb := int(ev.get("gain", 0))
			var pv := view as PlaneView
			if pv == null:
				return
			var center: Vector2 = pv.combo_tower_world_center()
			var norm: Vector2 = pv.play_norm_from_world(center)
			pv.spawn_score_gems_world(rubies, center, 1.38, 0.1)
			pv.burst_stars(
				norm.x,
				norm.y,
				mini(maxi(rubies, 2), 14),
				Color(1.0, 0.42, 0.55, 1.0)
			)
			pv.punch(2.2 + float(rubies) * 0.07)
			if gain_cb > 0:
				pv.float_text("+%d" % gain_cb, norm.x, norm.y - 0.05, Color(1.0, 0.58, 0.68))
			if bool(ev.get("fengshen", false)):
				pv.show_combo_tier_peak_center("fengshen")
			var prev_combo := int(ev.get("combo", 0))
			if prev_combo >= 3 and prev_combo < PlaneLogic.COMBO_TIER_LUANWU:
				ArcadeAudio.sfx_plane_ruby_collect_material()
			elif prev_combo >= PlaneLogic.COMBO_TIER_LUANWU and prev_combo < PlaneLogic.COMBO_TIER_FENGSHEN:
				ArcadeAudio.sfx_plane_ruby_coin_env()
			elif prev_combo >= PlaneLogic.COMBO_TIER_FENGSHEN:
				ArcadeAudio.sfx_plane_ruby_coin_clatter()
		"item":
			var ik := int(ev.get("kind", 0))
			if ik == 0:
				ArcadeAudio.sfx_coin()
				view.show_pickup(str(ev.get("banner", "火力 Lv%d" % int(ev.get("lv", logic.power_lv)))))
				view.flash_double()
			elif ik == 1:
				ArcadeAudio.sfx_eat(1)
				view.show_pickup(str(ev.get("banner", "护盾")))
				view.flash_shield()
			elif ik == 3:
				ArcadeAudio.sfx_eat(1)
				var bn := str(ev.get("banner", "+%d" % PlaneLogic.SCORE_POINT_SCALE))
				view.show_pickup(bn)
				view.float_text(bn, logic.player_x, logic.player_y - 0.08, Color("FFE08A"))
			elif ik == 4:
				ArcadeAudio.sfx_eat(1)
				view.show_pickup("+1")
				view.flash_heal()
				view.float_text("+1", logic.player_x, logic.player_y - 0.08, Color("FF8A9A"))
			else:
				ArcadeAudio.sfx_eat(1)
		"heal":
			ArcadeAudio.sfx_eat(1)
			view.show_pickup("+1")
			view.flash_heal()
			view.float_text("+1", logic.player_x, logic.player_y - 0.08, Color("FF8A9A"))
		"nuke":
			ArcadeAudio.sfx_start()
			view.flash_bomb()
			view.show_pickup(str(ev.get("banner", "全屏清除")))
			var spots: Array = ev.get("spots", [])
			var n := 0
			for p in spots:
				if n >= 8:
					break
				if p is Vector2:
					view.burst_stars(p.x, p.y, 1)
					n += 1
		"flash":
			if str(ev.get("text", "")) == "没有目标":
				view.show_pickup("没有目标")
		"super":
			ArcadeAudio.sfx_coin()
			ArcadeAudio.sfx_start()
			view.flash_laser()
			view.show_pickup("超级武器")
			view.punch(4.2)
		"shoot":
			if _shoot_sfx_cd <= 0.0:
				ArcadeAudio.sfx_plane_shoot()
				_shoot_sfx_cd = 0.065
			view.spray_muzzle(logic.player_x, logic.player_y - 0.058, int(ev.get("n", 1)))
			if bool(ev.get("double", false)):
				view.punch(0.35)
		"entry_salvo":
			match str(ev.get("phase", "burst")):
				"burst":
					ArcadeAudio.sfx_plane_boss_entry_missile()
					view.punch(5.4)
					var by := float(ev.get("y", 0.5))
					view.spawn_booms(float(ev.get("lx", 0.38)), by, 3, true)
					view.spawn_booms(float(ev.get("rx", 0.62)), by, 3, true)
				"shot":
					var sy := float(ev.get("y", 0.5))
					view.punch(0.75)
					view.spawn_booms(float(ev.get("lx", 0.38)), sy, 1, false)
					view.spawn_booms(float(ev.get("rx", 0.62)), sy, 1, false)
		"eshot":
			## 敌机开火走独立通道；用字面 kind，避免 RefCounted 取常量踩空
			if _eshot_sfx_cd > 0.0:
				pass
			elif bool(ev.get("boss", false)):
				ArcadeAudio.sfx_plane_shoot_boss()
				_eshot_sfx_cd = 0.09
			else:
				match int(ev.get("kind", -1)):
					2: ## PlaneLogic.KIND_PURPLE 大型紫机
						ArcadeAudio.sfx_plane_shoot_enemy_big()
						_eshot_sfx_cd = 0.07
					0, 1: ## 红 / 青小型机
						ArcadeAudio.sfx_plane_shoot_enemy_small()
						_eshot_sfx_cd = 0.05
					_:
						pass
		"missile":
			if _shoot_sfx_cd <= 0.0:
				ArcadeAudio.sfx_plane_shoot()
				_shoot_sfx_cd = 0.055
			view.punch(0.55)
		"end":
			pass


func _style_hud() -> void:
	if _hud_styled or ui == null:
		return
	_hud_styled = true
	## 左上角自绘 HUD，隐藏通用顶栏，避免叠字
	if hud_title:
		hud_title.visible = false
	if hud_score:
		hud_score.visible = false
	if hud_status:
		hud_status.visible = false
	var top := ui.get_node_or_null("TopBar")
	if top:
		top.visible = false
	_ink_label(hud_hint, Color("C8D8EC"), 15)
	overlay.color = Color(0.015,0.025,0.10,0.72)
	var panel := _overlay_settle_panel()
	if panel:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("0A1434")
		box.border_color = Color("62DFF8")
		box.set_border_width_all(2)
		box.set_corner_radius_all(8)
		box.content_margin_left = 28
		box.content_margin_right = 28
		box.content_margin_top = 24
		box.content_margin_bottom = 24
		panel.add_theme_stylebox_override("panel",box)
	_ink_label(overlay_msg,Color("EAF7FF"),26)
	_ink_label(overlay_sub,Color("6CE9FF"),36)
	if btn_ok:
		for state in ["normal","hover","pressed","focus"]:
			var button_style := StyleBoxFlat.new()
			button_style.bg_color = Color("23345F") if state == "normal" else Color("4A397A")
			button_style.border_color = Color("CF6CFF")
			button_style.set_border_width_all(2)
			button_style.set_corner_radius_all(6)
			btn_ok.add_theme_stylebox_override(state,button_style)
		btn_ok.add_theme_color_override("font_color",Color("EDFAFF"))
		btn_ok.add_theme_color_override("font_hover_color",Color.WHITE)


func _build_overlay_lottery_label() -> void:
	if overlay == null or overlay_lottery != null:
		return
	overlay_lottery = Label.new()
	overlay_lottery.name = "LotteryReward"
	overlay_lottery.visible = false
	overlay_lottery.text = "获得彩票：0 张"
	overlay_lottery.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	overlay_lottery.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	overlay_lottery.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	overlay_lottery.offset_left = -720.0
	overlay_lottery.offset_top = -160.0
	overlay_lottery.offset_right = -20.0
	overlay_lottery.offset_bottom = -18.0
	overlay_lottery.autowrap_mode = TextServer.AUTOWRAP_OFF
	_style_overlay_lottery(overlay_lottery)
	overlay.add_child(overlay_lottery)


func _build_ticket_fly_layer() -> void:
	if overlay == null or _ticket_fly_layer != null:
		return
	_ticket_fly_layer = Control.new()
	_ticket_fly_layer.name = "TicketFlyLayer"
	_ticket_fly_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ticket_fly_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ticket_fly_layer.z_index = 32
	overlay.add_child(_ticket_fly_layer)
	_ticket_fly_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _ensure_lottery_ticket_tex() -> void:
	if _tex_lottery != null:
		return
	if ResourceLoader.exists(_PATH_LOTTERY_TICKET):
		_tex_lottery = load(_PATH_LOTTERY_TICKET) as Texture2D


func _style_overlay_lottery(l: Label) -> void:
	if l == null:
		return
	l.add_theme_font_size_override("font_size", 52)
	l.add_theme_color_override("font_color", Color("FFF16D"))
	l.add_theme_color_override("font_outline_color", Color(0.12, 0.02, 0.02, 0.95))
	l.add_theme_constant_override("outline_size", 12)
	l.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.45))
	l.add_theme_constant_override("shadow_offset_x", 3)
	l.add_theme_constant_override("shadow_offset_y", 4)


func _lottery_tickets_from_score(score: int) -> int:
	## n = floor(最终得分 / 1000)
	return maxi(0, score / 1000)


func _ink_label(l: Label, color: Color, size: int) -> void:
	if l == null:
		return
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.04, 0.05, 0.08, 0.95))
	l.add_theme_constant_override("outline_size", 8)


func _refresh() -> void:
	## 得分/生命/街机信息由 PlaneView 绘制；底栏操作提示
	if hud_hint:
		var tip := "摇杆移动 · 抓取键射击（长按连发）"
		if not OS.has_feature("android") and not OS.has_feature("mobile"):
			tip += " · F1 模拟投币"
		hud_hint.text = tip
	_push_arcade_hud()


func _end(reason: String) -> void:
	if not visible or not active:
		return
	active = false
	## 弹窗必须用场内同一套显示分；发币仍走 settle（软顶）
	var shown := int(logic.score)
	if shown <= 0:
		shown = session_points
	var tokens: int = logic.settle_score()
	session_points = shown
	ArcadeAudio.on_game_over()
	BoardLink.release_control()
	if tokens > 0:
		GameState.add_tokens(tokens)
		BoardLink.report_settle(tokens)
	overlay_msg.text = "被击落 · 本局得分"
	overlay_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if overlay_sub:
		overlay_sub.visible = true
		overlay_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		overlay_sub.add_theme_font_size_override("font_size", 36)
		overlay_sub.add_theme_color_override("font_color", Color("6CE9FF"))
		overlay_sub.add_theme_color_override("font_outline_color", Color(0.04, 0.05, 0.08, 0.85))
		overlay_sub.add_theme_constant_override("outline_size", 6)
	overlay.visible = true
	_start_settle_roll(shown)
	_refresh()
	GameState.finish_points_round(self, "plane", _points_round_id, shown)
	round_finished.emit(tokens)


func _start_settle_roll(final_score: int) -> void:
	_settle_score_start = maxi(0, final_score)
	_settle_tickets_target = _lottery_tickets_from_score(_settle_score_start)
	_settle_roll_t = 0.0
	_settle_roll_active = true
	set_process(true)
	_apply_settle_roll_display(_settle_score_start, 0)
	if _settle_tickets_target > 0:
		ArcadeAudio.sfx_plane_lottery_cash()
	_begin_settle_ticket_flies()


func _begin_settle_ticket_flies() -> void:
	## 等 overlay / 得分面板完成布局后再取中心，避免 global_rect 仍为 (0,0) 时从左上角爆开
	await get_tree().process_frame
	await get_tree().process_frame
	if not _settle_roll_active or _settle_tickets_target <= 0:
		return
	_spawn_settle_ticket_flies()


func _spawn_settle_ticket_flies() -> void:
	_clear_ticket_flies()
	_ensure_lottery_ticket_tex()
	if _ticket_fly_layer == null or _tex_lottery == null or _settle_tickets_target <= 0:
		return
	for i in _TICKET_BURST_COUNT:
		var ang := TAU * float(i) / float(_TICKET_BURST_COUNT) + sin(float(i) * 2.17) * 0.55
		var dist := lerpf(
			_TICKET_BURST_DIST_MIN,
			_TICKET_BURST_DIST_MAX,
			0.5 + 0.5 * sin(float(i) * 1.73 + 0.4)
		)
		var burst_off := Vector2(cos(ang), sin(ang)) * dist
		var sz := lerpf(72.0, 108.0, 0.5 + 0.5 * sin(float(i) * 3.1))
		var rect := TextureRect.new()
		rect.texture = _tex_lottery
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.custom_minimum_size = Vector2(sz, sz * 1.08)
		rect.size = rect.custom_minimum_size
		rect.pivot_offset = rect.size * 0.5
		rect.visible = false
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ticket_fly_layer.add_child(rect)
		_ticket_flies.append({
			"node": rect,
			"delay": fmod(float(i) * 0.011, 0.14),
			"burst_off": burst_off,
			"spin": sin(float(i) * 4.9) * 0.9,
			"size": sz,
		})


func _tick_settle_roll(delta: float) -> void:
	_settle_roll_t += delta
	var u := clampf(_settle_roll_t / _SETTLE_ROLL_SEC, 0.0, 1.0)
	var score_show := int(round(float(_settle_score_start) * (1.0 - u)))
	var tickets_show := int(round(float(_settle_tickets_target) * u))
	_apply_settle_roll_display(score_show, tickets_show)
	_tick_settle_ticket_flies()
	if u >= 1.0:
		_apply_settle_roll_display(0, _settle_tickets_target)
		_stop_settle_roll()


func _tick_settle_ticket_flies() -> void:
	if _ticket_flies.is_empty():
		return
	var start := _ticket_fly_start_local()
	var end := _ticket_fly_end_local()
	for fly in _ticket_flies:
		var rect: TextureRect = fly["node"] as TextureRect
		if rect == null:
			continue
		var t := _settle_roll_t - float(fly["delay"])
		if t < 0.0 or t > _TICKET_GATHER_TO_SEC + 0.08:
			rect.visible = false
			continue
		var burst_pt: Vector2 = start + fly["burst_off"]
		var pos := start
		var sc := 0.18
		var alpha := 1.0
		if t < _TICKET_BURST_OUT_SEC:
			var u := _smooth01(t / _TICKET_BURST_OUT_SEC)
			u = 1.0 - pow(1.0 - u, 2.4)
			pos = start.lerp(burst_pt, u)
			sc = lerpf(0.12, 1.12, u)
			alpha = clampf(0.15 + u * 1.0, 0.0, 1.0)
		elif t < _TICKET_GATHER_FROM_SEC:
			pos = burst_pt
			var h := (t - _TICKET_BURST_OUT_SEC) / maxf(
				_TICKET_GATHER_FROM_SEC - _TICKET_BURST_OUT_SEC, 0.001
			)
			sc = 1.05 + sin(h * PI * 2.5 + float(fly["spin"])) * 0.06
		else:
			var u := _smooth01(
				(t - _TICKET_GATHER_FROM_SEC)
				/ maxf(_TICKET_GATHER_TO_SEC - _TICKET_GATHER_FROM_SEC, 0.001)
			)
			u = pow(u, 0.82)
			var mid := burst_pt.lerp(end, 0.38) + Vector2(90.0, -55.0)
			pos = _bezier2(burst_pt, mid, end, u)
			sc = lerpf(0.92, 0.22, u)
			alpha = lerpf(1.0, 0.35, clampf(u * 0.95, 0.0, 1.0))
			if u > 0.92:
				alpha = lerpf(alpha, 0.0, (u - 0.92) / 0.08)
		rect.visible = alpha > 0.02
		rect.position = pos - rect.size * 0.5
		rect.scale = Vector2(sc, sc)
		rect.rotation = float(fly["spin"]) + sin(t * 9.0) * 0.12 * sc
		rect.modulate = Color(1.0, 1.0, 1.0, alpha)


func _smooth01(x: float) -> float:
	var u := clampf(x, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)


func _bezier2(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u * u * a + 2.0 * u * t * b + t * t * c


func _ticket_fly_start_local() -> Vector2:
	return _global_to_ticket_local(_settle_burst_center_global())


func _ticket_fly_end_local() -> Vector2:
	return _global_to_ticket_local(_lottery_count_digit_center_global(_settle_tickets_target))


func _overlay_settle_panel() -> Control:
	if overlay == null:
		return null
	for child in overlay.get_children():
		if child is CenterContainer and child.get_child_count() > 0:
			var panel := child.get_child(0)
			if panel is Control:
				return panel as Control
	return null


func _settle_burst_center_global() -> Vector2:
	var panel := _overlay_settle_panel()
	if panel != null:
		var rect := panel.get_global_rect()
		if rect.size.x >= 8.0 and rect.size.y >= 8.0:
			return rect.get_center()
	if overlay_sub and overlay_sub.visible:
		var sub_rect := overlay_sub.get_global_rect()
		if sub_rect.size.x >= 4.0 and sub_rect.size.y >= 4.0:
			return sub_rect.get_center()
	var vp := get_viewport().get_visible_rect().size
	return Vector2(vp.x * 0.5, vp.y * 0.46)


func _lottery_count_digit_center_global(count: int) -> Vector2:
	if overlay_lottery == null or not overlay_lottery.visible:
		var vp := get_viewport().get_visible_rect().size
		return Vector2(vp.x - 168.0, vp.y - 72.0)
	var prefix := "获得彩票："
	var suffix := " 张"
	var num := str(maxi(0, count))
	var full := prefix + num + suffix
	var fs: int = overlay_lottery.get_theme_font_size("font_size")
	var font: Font = overlay_lottery.get_theme_font("font")
	if font == null:
		font = ThemeDB.fallback_font
	var sz_prefix := font.get_string_size(prefix, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var sz_num := font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var sz_full := font.get_string_size(full, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var rect := overlay_lottery.get_global_rect()
	var text_right := rect.position.x + rect.size.x
	var text_left := text_right - sz_full.x
	var cx := text_left + sz_prefix.x + sz_num.x * 0.5
	var cy := rect.position.y + rect.size.y * 0.5
	return Vector2(cx, cy)


func _global_to_ticket_local(global_pt: Vector2) -> Vector2:
	if _ticket_fly_layer == null:
		return global_pt
	var inv := _ticket_fly_layer.get_global_transform_with_canvas().affine_inverse()
	return inv * global_pt


func _clear_ticket_flies() -> void:
	for fly in _ticket_flies:
		var rect: TextureRect = fly.get("node") as TextureRect
		if rect and is_instance_valid(rect):
			rect.queue_free()
	_ticket_flies.clear()


func _apply_settle_roll_display(score_show: int, tickets_show: int) -> void:
	if overlay_sub:
		overlay_sub.visible = true
		overlay_sub.text = _fmt_score(maxi(0, score_show))
	if overlay_lottery:
		_style_overlay_lottery(overlay_lottery)
		overlay_lottery.text = "本局可兑彩票：%d 张" % maxi(0, tickets_show)
		overlay_lottery.visible = true


func _stop_settle_roll() -> void:
	_settle_roll_active = false
	_settle_roll_t = 0.0
	_clear_ticket_flies()
	if not active:
		set_process(false)


func _fmt_score(n: int) -> String:
	var s := str(maxi(0, n))
	var out := ""
	var cnt := 0
	for i in range(s.length() - 1, -1, -1):
		if cnt > 0 and cnt % 3 == 0:
			out = "," + out
		out = s[i] + out
		cnt += 1
	return out


func _on_ok() -> void:
	if GameState.points_result_is_open():
		return
	_stop_settle_roll()
	overlay.visible = false
	if overlay_lottery:
		overlay_lottery.visible = false
	stop_and_hide()
	ask_return_hub.emit()


func _on_overlay_gui(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_on_ok()
	elif event is InputEventMouseButton and event.pressed:
		_on_ok()
