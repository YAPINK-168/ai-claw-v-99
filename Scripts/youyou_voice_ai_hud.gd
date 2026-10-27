extends Node
class_name YouyouVoiceAiHud
## 右上角 AI 语音面板：标题、波形、倒计时、与 PlayerStatus 共用底部 Label。

const PlayerStatusScript := preload("res://Scripts/voice/preview_ai_voice_player_status.gd")
const WaveformScript := preload("res://Scripts/youyou_voice_ai_waveform.gd")

const MSG_TITLE_LIVE := "AI语音交互中..."
const MSG_TITLE_IDLE := "语音未开启"
const MSG_ATTRACT := "柚柚正在等待与你互动..."
const MSG_IDLE := "走近后才能和柚柚说话"
const MSG_INVITE_ASK := "柚柚正在问你要不要玩小游戏"
const MSG_INVITE_WAIT := "柚柚正在等你回答"
const MSG_INVITE_LISTEN := "请说想玩，或者不玩"

const TOP_LEFT := Vector2(46.0, 27.0)
const TOP_RIGHT := Vector2(298.0, 51.0)
const TOP_TEXT_Y_OFFSET := 6.0
const WAVE_Y_OFFSET := 5.0
const MIC_RESERVE := 38.0
const GREEN_RESERVE := 20.0
const WAVE_COUNTDOWN_GAP := 10.0
const COUNTDOWN_MIN_W := 34.0

const BUBBLE_LEFT := 44.0
const BUBBLE_TOP := 183.0
const BUBBLE_RIGHT := 284.0
const BUBBLE_BOTTOM := 220.0
const BUBBLE_TEXT_Y_OFFSET := 6.0

var _panel: Control
var _status_label: Label
var _title: Label
var _waveform: Control
var _countdown: Label
var _countdown_bg: Panel
var _bridge: PreviewAiVoiceBridge
var _ui_phase := "idle"
var _last_second := -1
var _breath := 0.0
## "" 空闲；invite_ask 正在问；invite_wait 问完等开口；invite_listen 正在听意愿
var _situation := ""
var _situation_remain := -1.0


func setup(panel: Control, status_label: Label) -> void:
	_panel = panel
	_status_label = status_label
	_build_top_chrome()
	_layout_status_label()
	_apply_attract_hint()


func bind_bridge(bridge: PreviewAiVoiceBridge) -> void:
	_bridge = bridge
	set_process(bridge != null)


func apply_status_event(event: String, ctx: Dictionary) -> void:
	match event:
		"wait_listen":
			_ui_phase = "wait"
		"vad_listen":
			_ui_phase = "mic"
		"asr", "llm_think", "tts_prep":
			_ui_phase = "processing"
		"playback":
			_ui_phase = "tts"
		"session_closed":
			_ui_phase = "idle"
			if bool(ctx.get("silent", true)):
				call_deferred("_apply_attract_hint")
		_:
			pass
	call_deferred("_fit_status_font")


func get_status_label() -> Label:
	return _status_label


func _build_top_chrome() -> void:
	if _panel == null:
		return
	var bar := Control.new()
	bar.name = "TopStatusBar"
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	bar.position = TOP_LEFT
	bar.size = TOP_RIGHT - TOP_LEFT
	_panel.add_child(bar)

	_title = Label.new()
	_title.name = "Title"
	_title.text = MSG_TITLE_IDLE
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 12)
	_title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.96))
	_title.add_theme_constant_override("outline_size", 1)
	_title.add_theme_color_override("font_outline_color", Color(0.05, 0.12, 0.35, 0.45))
	bar.add_child(_title)

	_countdown_bg = Panel.new()
	_countdown_bg.name = "CountdownPill"
	_countdown_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pill := StyleBoxFlat.new()
	pill.bg_color = Color(0.08, 0.18, 0.42, 0.72)
	pill.corner_radius_top_left = 8
	pill.corner_radius_top_right = 8
	pill.corner_radius_bottom_left = 8
	pill.corner_radius_bottom_right = 8
	pill.content_margin_left = 6
	pill.content_margin_right = 6
	pill.content_margin_top = 1
	pill.content_margin_bottom = 1
	_countdown_bg.add_theme_stylebox_override("panel", pill)
	bar.add_child(_countdown_bg)

	_countdown = Label.new()
	_countdown.name = "Countdown"
	_countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_countdown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_countdown.add_theme_font_size_override("font_size", 10)
	_countdown.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.98))
	_countdown.custom_minimum_size = Vector2(COUNTDOWN_MIN_W, 16.0)
	_countdown.text = "--"
	_countdown_bg.add_child(_countdown)
	_countdown.set_anchors_preset(Control.PRESET_FULL_RECT)

	_waveform = WaveformScript.new()
	_waveform.name = "Waveform"
	_waveform.clip_contents = true
	bar.add_child(_waveform)
	bar.move_child(_countdown_bg, bar.get_child_count() - 1)
	_layout_top_bar()


func _layout_top_bar() -> void:
	if _title == null or _waveform == null or _countdown_bg == null:
		return
	var bar_w := TOP_RIGHT.x - TOP_LEFT.x
	var bar_h := TOP_RIGHT.y - TOP_LEFT.y
	_title.position = Vector2(MIC_RESERVE, TOP_TEXT_Y_OFFSET)
	_title.size = Vector2(112.0, bar_h - TOP_TEXT_Y_OFFSET)

	_countdown_bg.size = Vector2(COUNTDOWN_MIN_W + 4.0, 18.0)
	_countdown_bg.position = Vector2(
		bar_w - GREEN_RESERVE - _countdown_bg.size.x,
		TOP_TEXT_Y_OFFSET + (bar_h - TOP_TEXT_Y_OFFSET - _countdown_bg.size.y) * 0.5
	)

	var wave_left := _title.position.x + _title.size.x + 4.0
	var wave_right := _countdown_bg.position.x - WAVE_COUNTDOWN_GAP
	var wave_y := TOP_TEXT_Y_OFFSET + WAVE_Y_OFFSET
	_waveform.position = Vector2(wave_left, wave_y)
	_waveform.size = Vector2(maxf(28.0, wave_right - wave_left), bar_h - wave_y)


func _layout_status_label() -> void:
	if _status_label == null:
		return
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.clip_text = true
	_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_status_label.max_lines_visible = 2
	_status_label.add_theme_font_size_override("font_size", 10)
	_status_label.add_theme_color_override("font_color", Color(0.10, 0.30, 0.58, 1.0))
	_place_label(_status_label, BUBBLE_LEFT, BUBBLE_TOP, BUBBLE_RIGHT, BUBBLE_BOTTOM)
	_status_label.position.y += BUBBLE_TEXT_Y_OFFSET
	_fit_status_font()


func _place_label(label: Control, left: float, top: float, right: float, bottom: float) -> void:
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	label.position = Vector2(left, top)
	label.size = Vector2(right - left, bottom - top)


func _fit_status_font() -> void:
	if _status_label == null:
		return
	var box_h := _status_label.size.y
	if box_h <= 0.0:
		return
	for size in [11, 10, 9]:
		_status_label.add_theme_font_size_override("font_size", size)
		var needed := _status_label.get_minimum_size().y
		if needed <= box_h + 1.0:
			return


func set_situation(mode: String, remain_sec: float = -1.0) -> void:
	_situation = mode
	_situation_remain = remain_sec


func _window_live() -> bool:
	return _bridge != null and _bridge.is_window_armed()


func _voice_live() -> bool:
	return _window_live() or _situation != ""


func _situation_message() -> String:
	match _situation:
		"invite_ask":
			return MSG_INVITE_ASK
		"invite_wait":
			return MSG_INVITE_WAIT
		"invite_listen":
			return MSG_INVITE_LISTEN
		_:
			return ""


func _apply_attract_hint() -> void:
	if _status_label == null:
		return
	var situation_text := _situation_message()
	if situation_text != "":
		_status_label.text = situation_text
	elif _window_live():
		_status_label.text = MSG_ATTRACT
	else:
		_status_label.text = MSG_IDLE
	_status_label.visible = true
	_fit_status_font()


func _process(delta: float) -> void:
	_breath += delta
	_sync_window_chrome()
	_update_countdown()
	_update_waveform_drive()
	_maybe_restore_attract()


func _sync_window_chrome() -> void:
	var live := _voice_live()
	if _title != null:
		_title.text = MSG_TITLE_LIVE if live else MSG_TITLE_IDLE
		_title.add_theme_color_override(
			"font_color",
			Color(1, 1, 1, 0.96) if live else Color(1, 1, 1, 0.72)
		)
	if _waveform != null:
		_waveform.visible = live
		if _situation == "invite_ask":
			_waveform.set_drive_mode("tts")
		elif _situation == "invite_listen" or _situation == "invite_wait":
			_waveform.set_drive_mode("mic")
	if _countdown_bg != null:
		_countdown_bg.visible = _window_live() or _situation == "invite_listen"


func _maybe_restore_attract() -> void:
	if _status_label == null:
		return
	var wanted := _situation_message()
	if wanted != "":
		if _status_label.text != wanted:
			_apply_attract_hint()
		return
	var text := _status_label.text
	var live := _window_live()
	if (
		text.is_empty()
		or text == MSG_INVITE_ASK
		or text == MSG_INVITE_WAIT
		or text == MSG_INVITE_LISTEN
		or (not live and text == MSG_ATTRACT)
		or (live and text == MSG_IDLE)
	):
		_apply_attract_hint()


func _update_countdown() -> void:
	if _countdown == null or _countdown_bg == null:
		return
	if _situation == "invite_listen" and _situation_remain >= 0.0:
		var invite_sec := int(ceilf(_situation_remain))
		_countdown.text = "%ds" % invite_sec
		_countdown_bg.modulate = Color(1, 1, 1, 1.0)
		_countdown.add_theme_color_override("font_color", Color(1, 1, 1, 0.98))
		_last_second = invite_sec
		return
	if _bridge == null or not _bridge.is_window_armed():
		_countdown.text = "--"
		_countdown_bg.modulate = Color(1, 1, 1, 0.55)
		_countdown.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
		return
	var sec := int(ceilf(_bridge.get_window_remaining_sec()))
	if sec < 0:
		sec = 0
	_countdown.text = "%ds" % sec
	_countdown_bg.modulate = Color(1, 1, 1, 1.0)
	var col := Color(1.0, 1.0, 1.0, 0.98)
	if sec <= 5:
		col = Color(1.0, 0.92, 0.72, 0.98)
	if sec <= 3:
		var pulse := 0.92 + sin(_breath * 5.5) * 0.08
		_countdown_bg.modulate = Color(pulse, pulse, pulse, 1.0)
	_countdown.add_theme_color_override("font_color", col)
	if sec != _last_second:
		_last_second = sec


func _update_waveform_drive() -> void:
	if _waveform == null or _situation != "":
		return
	var mode := "idle"
	match _ui_phase:
		"mic":
			mode = "mic"
		"tts":
			mode = "tts"
		"processing", "wait":
			mode = "processing"
		_:
			mode = "idle"
	_waveform.set_drive_mode(mode)
	var ext := 0.0
	if mode == "mic":
		ext = _read_bus_peak_linear("Record")
	elif mode == "tts":
		ext = _read_bus_peak_linear("Master")
	_waveform.set_external_level(ext)


func _read_bus_peak_linear(bus_name: String) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return 0.0
	var db := AudioServer.get_bus_peak_volume_left_db(idx, 0)
	if db < -60.0:
		return 0.0
	return clampf(pow(10.0, db / 20.0), 0.0, 1.0)
