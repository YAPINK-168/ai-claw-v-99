extends Node2D
## 抓失败后的小游戏层：新街机转盘随机抽三款，再进入对应场景。

const RouletteScript := preload("res://街机小游戏/scripts/game_roulette.gd")
const MinigameCatalog := preload("res://Scripts/business/claw_minigame_catalog.gd")

const RETURN_SEC := 15.0

signal play_scene_active(active: bool)
## true：转盘或小游戏占用音乐，主场景背景曲应停；false：回到抓娃娃
signal lobby_music_suspended(suspended: bool)

enum Phase { HIDDEN, SPIN, WAIT_LAUNCH, PLAY, SETTLED }

var _port
var _phase := Phase.HIDDEN
var _open := false
var _inner: Node2D
var _play_layer: CanvasLayer
var _bg_video: CanvasLayer
var _roulette: Control
var _hint: Label
var _return_left := 0.0
var _settlement_holding := false
var _drawn_game_id := ""
var _inner_launch_count := 0


func _ready() -> void:
	visible = false
	z_index = 100
	_build_play_layer()
	_build_blocker()
	_build_roulette()
	_build_hint()
	_ensure_input_actions()
	set_process(false)
	if not BoardLink.board_key.is_connected(_forward_board_keys):
		BoardLink.board_key.connect(_forward_board_keys)


func setup(port) -> void:
	_port = port


func covers_screen() -> bool:
	return _open


func inner_game_loaded() -> bool:
	return _inner != null and is_instance_valid(_inner)


func draw_phase_name() -> String:
	if not _open:
		return "HIDDEN"
	return Phase.keys()[_phase]


func drawn_game_id() -> String:
	return _drawn_game_id


func is_draw_flow_active() -> bool:
	return _open and not inner_game_loaded() and _phase in [Phase.SPIN, Phase.WAIT_LAUNCH]


func open_round(_token: int = 0) -> void:
	_open = true
	lobby_music_suspended.emit(true)
	visible = true
	_return_left = 0.0
	_settlement_holding = false
	_hint.visible = false
	_drawn_game_id = ""
	_inner_launch_count = 0
	_free_inner()
	_phase = Phase.SPIN
	set_process(true)
	_roulette.visible = true
	if ArcadeAudio.has_method("stop_bgm"):
		ArcadeAudio.stop_bgm()
	_roulette.start_spin()
	ArcadeAudio.play_roulette()
	print("[小游戏抽取] 进入街机转盘抽取 token=%d" % _token)


func close_round() -> void:
	if not _open and _phase == Phase.HIDDEN:
		return
	print("[小游戏抽取] 关闭回合 phase=%s drawn=%s" % [draw_phase_name(), _drawn_game_id])
	_open = false
	_phase = Phase.HIDDEN
	_drawn_game_id = ""
	_return_left = 0.0
	_settlement_holding = false
	set_process(false)
	if ArcadeAudio.has_method("stop_bgm"):
		ArcadeAudio.stop_bgm()
	_hide_bg_video()
	_stop_roulette()
	_free_inner()
	lobby_music_suspended.emit(false)
	if _hint != null:
		_hint.visible = false
	visible = false


func replay_round() -> void:
	if not _open:
		return
	if _drawn_game_id == "" or not MinigameCatalog.is_playable(_drawn_game_id):
		return
	_phase = Phase.PLAY
	_return_left = 0.0
	_hint.visible = false
	_spawn_inner(_drawn_game_id)


func debug_confirm_draw_launch() -> void:
	if _phase == Phase.WAIT_LAUNCH:
		_launch_game()


func debug_inner_launch_count() -> int:
	return _inner_launch_count


func debug_replay_spin_finished(game_id: String) -> void:
	_on_spin_finished(game_id)


func debug_wait_spin_finished(timeout_sec: float = 5.0) -> bool:
	var waited := 0.0
	while waited < timeout_sec and _phase == Phase.SPIN:
		await get_tree().process_frame
		waited += get_process_delta_time()
	return _phase != Phase.SPIN or _drawn_game_id != ""


func miner_steer_axis() -> float:
	return 0.0


func obtain_bg_video() -> CanvasLayer:
	var scr = load("res://街机小游戏/miner/scripts/miner_bg_video.gd")
	var orphan := get_tree().root.get_node_or_null("BackgroundVideo")
	if orphan != null and orphan != _bg_video:
		orphan.queue_free()
	var fresh := _bg_video == null or not is_instance_valid(_bg_video)
	if fresh:
		_bg_video = scr.new()
		_bg_video.name = "BackgroundVideo"
		add_child(_bg_video)
	move_child(_bg_video, 0)
	_bg_video.visible = true
	if not fresh and _bg_video.has_method("restart_for_round"):
		_bg_video.restart_for_round()
	return _bg_video


func _forward_board_keys(bits: int) -> void:
	if _inner != null and is_instance_valid(_inner) and _inner.has_method("on_board_key"):
		_inner.on_board_key(bits)


func _process(delta: float) -> void:
	if _phase == Phase.PLAY and _inner != null and is_instance_valid(_inner) and _inner.has_method("on_board_key"):
		_forward_board_keys(BoardLink.get_current_key_bits())
	if _phase != Phase.SETTLED:
		return
	if GameState.points_result_is_open():
		if not _settlement_holding:
			_settlement_holding = true
			print("[小游戏] 账户结算显示中，主场景保持安静")
		return
	_settlement_holding = false
	_return_left -= delta
	if _return_left <= 0.0:
		_finish_round()


func _input(event: InputEvent) -> void:
	if not _open:
		return
	if _phase == Phase.WAIT_LAUNCH and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_launch_game()
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key := event as InputEventKey
	if _phase == Phase.SPIN and _is_fn_confirm(key):
		get_viewport().set_input_as_handled()
	elif _phase == Phase.WAIT_LAUNCH and _is_start_key(key):
		_launch_game()
		get_viewport().set_input_as_handled()
	elif (_phase == Phase.PLAY or _phase == Phase.SETTLED) and (_is_fn_confirm(key) or _is_action_key(key)):
		if _inner != null and _inner.has_method("press_fire"):
			_inner.press_fire()
		get_viewport().set_input_as_handled()


func _build_play_layer() -> void:
	_play_layer = CanvasLayer.new()
	_play_layer.name = "PlayLayer"
	# 高于抓娃娃背景/人物（0/1）和测试 HUD（10），低于转盘（20）。
	_play_layer.layer = 15
	add_child(_play_layer)


func _build_blocker() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 14
	layer.name = "MouseBlock"
	var block := Control.new()
	block.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	block.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(block)
	add_child(layer)


func _build_roulette() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	layer.name = "RouletteLayer"
	_roulette = RouletteScript.new()
	_roulette.name = "Roulette"
	_roulette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_roulette.visible = false
	_roulette.spin_finished.connect(_on_spin_finished)
	if _roulette.has_signal("transition_finished"):
		_roulette.transition_finished.connect(_stop_roulette)
	layer.add_child(_roulette)
	add_child(layer)


func _build_hint() -> void:
	var layer := _roulette.get_parent() as CanvasLayer
	_hint = Label.new()
	_hint.name = "ReturnHint"
	_hint.visible = false
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_hint.offset_top = -64.0
	_hint.offset_bottom = -16.0
	_hint.add_theme_font_size_override("font_size", 22)
	_hint.add_theme_color_override("font_color", Color("FFE8C8"))
	layer.add_child(_hint)


func _on_spin_finished(game_id: String) -> void:
	if not _open or _phase != Phase.SPIN:
		print("[小游戏抽取] 忽略转盘结束回调 phase=%s id=%s" % [draw_phase_name(), game_id])
		return
	if not MinigameCatalog.is_playable(game_id):
		push_error("小游戏场景不可用：%s %s" % [game_id, MinigameCatalog.scene_path(game_id)])
		_finish_round()
		return
	_drawn_game_id = game_id
	print("[小游戏抽取] 抽中 id=%s title=%s，转盘结束，自动进入" % [
		game_id, MinigameCatalog.title_for(game_id),
	])
	_phase = Phase.WAIT_LAUNCH
	_launch_game()


func _launch_game() -> void:
	if _phase != Phase.WAIT_LAUNCH or _inner_launch_count > 0:
		return
	if not MinigameCatalog.is_playable(_drawn_game_id):
		push_error("无法启动小游戏：抽取结果无效或场景不存在。")
		_finish_round()
		return
	_phase = Phase.PLAY
	if ArcadeAudio.has_method("stop_bgm"):
		ArcadeAudio.stop_bgm()
	print("[小游戏] 自动加载 id=%s path=%s" % [
		_drawn_game_id, MinigameCatalog.scene_path(_drawn_game_id),
	])
	_spawn_inner(_drawn_game_id)
	if _roulette != null and _roulette.has_method("begin_enter"):
		_roulette.begin_enter()
	else:
		_stop_roulette()


func _spawn_inner(game_id: String) -> void:
	_free_inner(false)
	var scene_path := MinigameCatalog.scene_path(game_id)
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("小游戏场景加载失败：%s" % scene_path)
		_finish_round()
		return
	var node := packed.instantiate()
	if not node is Node2D:
		node.free()
		push_error("小游戏场景根节点不是 Node2D：%s" % scene_path)
		_finish_round()
		return
	_inner = node as Node2D
	_inner.name = "Minigame_%s" % game_id
	_inner_launch_count += 1
	if _play_layer != null:
		_play_layer.add_child(_inner)
	else:
		add_child(_inner)
	print("[小游戏] 场景已挂载 id=%s launch=%d" % [game_id, _inner_launch_count])
	play_scene_active.emit(true)
	if _inner.has_method("start_round"):
		_inner.start_round()
	_forward_board_keys(BoardLink.get_current_key_bits())
	if _inner.has_signal("round_finished"):
		_inner.round_finished.connect(_on_inner_settled)
	elif _inner.has_signal("settled"):
		_inner.settled.connect(_on_inner_settled)
	if _inner.has_signal("ask_return_hub"):
		_inner.ask_return_hub.connect(_finish_round)
	if _inner.has_method("_on_viewport_resized"):
		_inner.call_deferred("_on_viewport_resized")
	if _inner.has_method("_post_layout_sync"):
		_inner.call_deferred("_post_layout_sync")


func _on_inner_settled(_score: int) -> void:
	if _phase != Phase.PLAY:
		return
	_phase = Phase.SETTLED
	_return_left = RETURN_SEC
	if _hint != null:
		_hint.visible = false


func _finish_round() -> void:
	if not _open:
		return
	var port = _port
	close_round()
	if port != null and port.has_method("notify_finished"):
		port.notify_finished(false)


func _free_inner(notify_left: bool = true) -> void:
	var had_scene := _inner != null and is_instance_valid(_inner)
	if had_scene:
		if _inner.has_method("stop_and_hide"):
			_inner.stop_and_hide()
		_inner.queue_free()
	_inner = null
	if had_scene and notify_left:
		play_scene_active.emit(false)


func _stop_roulette() -> void:
	if _roulette == null or not is_instance_valid(_roulette):
		return
	if _roulette.has_method("stop_audio"):
		_roulette.stop_audio()
	_roulette.set_process(false)
	_roulette.visible = false


func _hide_bg_video() -> void:
	if _bg_video == null or not is_instance_valid(_bg_video):
		return
	if _bg_video.has_method("stop_playback"):
		_bg_video.stop_playback()
	_bg_video.visible = false


func _is_start_key(key: InputEventKey) -> bool:
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	if code == KEY_SPACE or code == KEY_ENTER or code == KEY_KP_ENTER:
		return true
	return _is_fn_confirm(key)


func _is_fn_confirm(key: InputEventKey) -> bool:
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	return code == KEY_9 or code == KEY_KP_9


func _is_action_key(key: InputEventKey) -> bool:
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	return code == KEY_X


func _ensure_input_actions() -> void:
	_ensure_action("move_left")
	_ensure_action("move_right")
	_ensure_action("fire")
	_add_keys("move_left", [KEY_LEFT, KEY_A, KEY_KP_4])
	_add_keys("move_right", [KEY_RIGHT, KEY_D, KEY_KP_6])
	_add_keys("fire", [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_X, KEY_Z, KEY_J])


func _ensure_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)


func _add_keys(action: String, keys: Array) -> void:
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		ev.keycode = key
		if not InputMap.action_has_event(action, ev):
			InputMap.action_add_event(action, ev)
