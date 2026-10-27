extends Node2D
## 海底矿工壳：嵌入同事的整局玩法，对齐飞机大战的开局 / 隐藏 / 机台键。

const INNER_SCENE := preload("res://街机小游戏/miner/scenes/main.tscn")
const MinerBgVideoScript := preload("res://街机小游戏/miner/scripts/miner_bg_video.gd")
## 同事计分是金币/宝箱（几十到几百），街机积分锚点约 12，按 100 分折 1 积分
const SCORE_PER_TOKEN := 100
const TOKEN_CAP := 24

signal round_finished(points: int)
signal ask_return_hub()
signal ask_keep_playing()

var active := false
var session_points := 0
var _inner: Node2D
var _bg_video: MinerBgVideo
var _board_hold := 0
var _fire_edge := false
var _awarded := false


func _ready() -> void:
	_ensure_input_actions()
	visible = false
	set_process(false)
	set_process_input(false)


func start_round() -> void:
	visible = true
	z_index = 100
	active = true
	_awarded = false
	_board_hold = 0
	_fire_edge = false
	session_points = 0
	set_process(true)
	BoardLink.take_control()
	ArcadeAudio.stop_bgm()
	_spawn_inner()


func stop_and_hide() -> void:
	active = false
	_board_hold = 0
	_fire_edge = false
	set_process(false)
	_free_inner()
	_hide_bg_video()
	visible = false
	BoardLink.release_control()
	ArcadeAudio.on_game_over()


func on_board_key(mask: int, _pressed: bool = true) -> void:
	if not active:
		return
	var enter := (mask & BoardLink.KEY_ENTER) != 0
	if mask == 0:
		_board_hold = 0
		_fire_edge = false
		return
	var dirs := mask & (BoardLink.KEY_LEFT | BoardLink.KEY_RIGHT)
	if dirs == 0 and enter:
		pass
	else:
		_board_hold = dirs
	if enter and not _fire_edge:
		_fire_edge = true
		if _inner and _inner.has_method("press_fire"):
			_inner.press_fire()
	elif not enter:
		_fire_edge = false


func miner_steer_axis() -> float:
	if not active:
		return 0.0
	var axis := 0.0
	if _board_hold & BoardLink.KEY_LEFT:
		axis -= 1.0
	if _board_hold & BoardLink.KEY_RIGHT:
		axis += 1.0
	return axis


func replay_round() -> void:
	if not active:
		return
	_awarded = false
	_board_hold = 0
	_fire_edge = false
	ask_keep_playing.emit()
	BoardLink.take_control()
	ArcadeAudio.stop_bgm()
	_spawn_inner()


func obtain_bg_video() -> MinerBgVideo:
	var orphan := get_tree().root.get_node_or_null("BackgroundVideo")
	if orphan != null and orphan != _bg_video:
		orphan.queue_free()
	var fresh := _bg_video == null or not is_instance_valid(_bg_video)
	if fresh:
		_bg_video = MinerBgVideoScript.new()
		_bg_video.name = "BackgroundVideo"
		add_child(_bg_video)
	move_child(_bg_video, 0)
	_bg_video.visible = true
	if not fresh and _bg_video.has_method("restart_for_round"):
		_bg_video.restart_for_round()
	return _bg_video


func _hide_bg_video() -> void:
	if _bg_video == null or not is_instance_valid(_bg_video):
		return
	if _bg_video.has_method("stop_playback"):
		_bg_video.stop_playback()
	_bg_video.visible = false


func _spawn_inner() -> void:
	_free_inner()
	_inner = INNER_SCENE.instantiate()
	_inner.name = "SeabedMiner"
	add_child(_inner)
	if _inner.has_signal("settled"):
		_inner.settled.connect(_on_inner_settled)
	call_deferred("_refit_inner_viewport")


func _refit_inner_viewport() -> void:
	if _inner == null:
		return
	if _inner.has_method("_on_viewport_resized"):
		_inner._on_viewport_resized()
	if _inner.has_method("_post_layout_sync"):
		_inner.call_deferred("_post_layout_sync")


func _free_inner() -> void:
	if _inner and is_instance_valid(_inner):
		_inner.queue_free()
	_inner = null


func _on_inner_settled(score: int) -> void:
	if _awarded:
		return
	_awarded = true
	session_points = maxi(0, score)
	var tokens := mini(session_points / SCORE_PER_TOKEN, TOKEN_CAP)
	BoardLink.release_control()
	if tokens > 0:
		GameState.add_tokens(tokens)
		BoardLink.report_settle(tokens)
	round_finished.emit(tokens)


func _ensure_input_actions() -> void:
	_ensure_action("move_left")
	_ensure_action("move_right")
	_ensure_action("fire")
	_add_keys("move_left", [KEY_LEFT, KEY_A, KEY_KP_4])
	_add_keys("move_right", [KEY_RIGHT, KEY_D, KEY_KP_6])
	_add_keys("fire", [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_Z, KEY_J])
	_add_joy_buttons("move_left", [JOY_BUTTON_DPAD_LEFT])
	_add_joy_buttons("move_right", [JOY_BUTTON_DPAD_RIGHT])
	_add_joy_buttons("fire", [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_START])


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


func _add_joy_buttons(action: String, buttons: Array) -> void:
	for button in buttons:
		var ev := InputEventJoypadButton.new()
		ev.button_index = button
		if not InputMap.action_has_event(action, ev):
			InputMap.action_add_event(action, ev)
