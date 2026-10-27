extends Node

## 「youyou_control2_1」双点配音：同一动作上分别安放「兜兜你干嘛1」「兜兜你干嘛2」。
## 保存写入 config/newmotion_action_voice_map.json → entries.youyou_control2_1.audio_cues

const ACTION_NAME := "youyou_control2_1"
const CONFIG_PATH := "res://config/newmotion_action_voice_map.json"
const VIEWPORT_SIZE := Vector2i(1920, 1080)
const CLIP_FPS := 24.0
const AUDIO_LOOK := "res://配音/新新配音/兜兜你干嘛1 (2).mp3"
const AUDIO_LAUGH := "res://配音/新新配音/兜兜你干嘛2.mp3"
const LABEL_LOOK := "兜兜你干嘛1（2）"
const LABEL_LAUGH := "兜兜你干嘛2"

@onready var _actor: NewMotionSpriteActor = $CharacterLayer/Character
@onready var _look_slider: HSlider = $UiLayer/Panel/Margin/VBox/LookRow/LookSlider
@onready var _look_value: Label = $UiLayer/Panel/Margin/VBox/LookRow/LookValue
@onready var _laugh_slider: HSlider = $UiLayer/Panel/Margin/VBox/LaughRow/LaughSlider
@onready var _laugh_value: Label = $UiLayer/Panel/Margin/VBox/LaughRow/LaughValue
@onready var _action_speed_slider: HSlider = $UiLayer/Panel/Margin/VBox/ActionSpeedRow/ActionSpeedSlider
@onready var _action_speed_value: Label = $UiLayer/Panel/Margin/VBox/ActionSpeedRow/ActionSpeedValue
@onready var _notes_edit: LineEdit = $UiLayer/Panel/Margin/VBox/NotesRow/NotesEdit
@onready var _status: Label = $UiLayer/Panel/Margin/VBox/StatusLabel
@onready var _time_label: Label = $UiLayer/Panel/Margin/VBox/TimeLabel
@onready var _voice_a: AudioStreamPlayer = $VoiceLook
@onready var _voice_b: AudioStreamPlayer = $VoiceLaugh

var _entries: Dictionary = {}
var _syncing := false
var _play_gen := 0
var _clip_elapsed := 0.0
var _clip_playing := false
var _look_left := -1.0
var _laugh_left := -1.0
var _look_fired := false
var _laugh_fired := false


func _enter_tree() -> void:
	_apply_viewport()


func _ready() -> void:
	set_process(false)
	_apply_ui_font()
	_actor.auto_play_voice = false
	_load_config()
	_setup_sliders()
	_load_entry_into_ui()
	$UiLayer/Panel/Margin/VBox/ControlRow/PlayButton.pressed.connect(_play_current)
	$UiLayer/Panel/Margin/VBox/ControlRow/StopButton.pressed.connect(_stop_all)
	$UiLayer/Panel/Margin/VBox/ControlRow/SaveButton.pressed.connect(_save_config)
	_look_slider.value_changed.connect(_on_look_changed)
	_laugh_slider.value_changed.connect(_on_laugh_changed)
	_action_speed_slider.value_changed.connect(_on_action_speed_changed)
	_notes_edit.text_changed.connect(_on_notes_changed)
	if not _actor.animation_finished.is_connected(_on_actor_finished):
		_actor.animation_finished.connect(_on_actor_finished)
	_status.text = "动作固定：%s · 两段配音可各自调起点" % ACTION_NAME
	_play_current()


func _process(delta: float) -> void:
	if not _clip_playing:
		set_process(false)
		return
	_clip_elapsed += delta * maxf(_action_speed_slider.value, 0.05)
	_time_label.text = "动作时间 %.2fs / 总长约 %.2fs" % [_clip_elapsed, _clip_duration()]
	if not _look_fired and _look_left >= 0.0:
		_look_left -= delta
		if _look_left <= 0.0:
			_look_fired = true
			if _voice_a.stream != null:
				_voice_a.play()
	if not _laugh_fired and _laugh_left >= 0.0:
		_laugh_left -= delta
		if _laugh_left <= 0.0:
			_laugh_fired = true
			if _voice_b.stream != null:
				_voice_b.play()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match (event as InputEventKey).keycode:
		KEY_SPACE:
			_play_current()
		KEY_ESCAPE:
			_stop_all()


func _apply_viewport() -> void:
	var window := get_window()
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	window.content_scale_size = VIEWPORT_SIZE
	window.title = "youyou_control2_1 · 双点配音"
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
	theme.default_font_size = 18
	$UiLayer/Panel.theme = theme


func _setup_sliders() -> void:
	var dur := _clip_duration()
	_look_slider.max_value = dur
	_laugh_slider.max_value = dur
	_look_slider.step = 0.01
	_laugh_slider.step = 0.01
	_action_speed_slider.min_value = 0.5
	_action_speed_slider.max_value = 1.5
	_action_speed_slider.step = 0.01


func _clip_duration() -> float:
	var names := NewMotionActionFs.list_frame_names(ACTION_NAME)
	if names.is_empty():
		return 10.0
	return float(names.size()) / CLIP_FPS


func _default_entry() -> Dictionary:
	return {
		"audio_path": AUDIO_LOOK,
		"audio_start_offset": 0.0,
		"audio_speed": 1.0,
		"action_speed": 1.0,
		"notes": "兜兜你干嘛1（2） + 兜兜你干嘛2 双点配音",
		"audio_cues": [
			{"audio": AUDIO_LOOK, "start_at": 0.0},
			{"audio": AUDIO_LAUGH, "start_at": 3.0},
		],
	}


func _load_config() -> void:
	_entries.clear()
	if not FileAccess.file_exists(CONFIG_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var root := parsed as Dictionary
	var entries: Variant = root.get("entries", {})
	if entries is Dictionary:
		_entries = (entries as Dictionary).duplicate(true)


func _entry_for_action() -> Dictionary:
	if _entries.has(ACTION_NAME) and _entries[ACTION_NAME] is Dictionary:
		return (_entries[ACTION_NAME] as Dictionary).duplicate(true)
	return _default_entry()


func _cue_start(entry: Dictionary, audio_path: String, fallback: float) -> float:
	var cues: Variant = entry.get("audio_cues", [])
	if cues is Array:
		for item in cues:
			if typeof(item) != TYPE_DICTIONARY:
				continue
			var d := item as Dictionary
			if str(d.get("audio", "")) == audio_path:
				return maxf(float(d.get("start_at", fallback)), 0.0)
	if audio_path == AUDIO_LOOK:
		return maxf(float(entry.get("audio_start_offset", fallback)), 0.0)
	return fallback


func _load_entry_into_ui() -> void:
	var entry := _entry_for_action()
	_syncing = true
	_look_slider.value = _cue_start(entry, AUDIO_LOOK, 0.0)
	_laugh_slider.value = _cue_start(entry, AUDIO_LAUGH, 3.0)
	_look_value.text = "%.2fs" % _look_slider.value
	_laugh_value.text = "%.2fs" % _laugh_slider.value
	_action_speed_slider.value = float(entry.get("action_speed", 1.0))
	_action_speed_value.text = "%.2fx" % _action_speed_slider.value
	_notes_edit.text = str(entry.get("notes", "兜兜你干嘛1（2） + 兜兜你干嘛2 双点配音"))
	_syncing = false
	_time_label.text = "动作时间 0.00s / 总长约 %.2fs" % _clip_duration()


func _write_ui_into_entry() -> void:
	var entry := {
		"audio_path": AUDIO_LOOK,
		"audio_start_offset": _look_slider.value,
		"audio_speed": 1.0,
		"action_speed": _action_speed_slider.value,
		"notes": _notes_edit.text,
		"audio_cues": [
			{"audio": AUDIO_LOOK, "start_at": _look_slider.value},
			{"audio": AUDIO_LAUGH, "start_at": _laugh_slider.value},
		],
	}
	_entries[ACTION_NAME] = entry


func _on_look_changed(value: float) -> void:
	_look_value.text = "%.2fs" % value
	if not _syncing:
		_write_ui_into_entry()


func _on_laugh_changed(value: float) -> void:
	_laugh_value.text = "%.2fs" % value
	if not _syncing:
		_write_ui_into_entry()


func _on_action_speed_changed(value: float) -> void:
	_action_speed_value.text = "%.2fx" % value
	if not _syncing:
		_write_ui_into_entry()
	if _clip_playing and _actor != null:
		_actor.speed_scale = maxf(value, 0.05)


func _on_notes_changed(_t: String) -> void:
	if not _syncing:
		_write_ui_into_entry()


func _play_current() -> void:
	_write_ui_into_entry()
	_stop_voices_only()
	_play_gen += 1
	var gen := _play_gen
	_clip_elapsed = 0.0
	_clip_playing = true
	_look_fired = false
	_laugh_fired = false
	_look_left = _look_slider.value
	_laugh_left = _laugh_slider.value
	_voice_a.stream = _load_audio(AUDIO_LOOK)
	_voice_b.stream = _load_audio(AUDIO_LAUGH)
	_voice_a.pitch_scale = 1.0
	_voice_b.pitch_scale = 1.0
	if _look_left <= 0.0:
		_look_fired = true
		if _voice_a.stream != null:
			_voice_a.play()
	if _laugh_left <= 0.0:
		_laugh_fired = true
		if _voice_b.stream != null:
			_voice_b.play()
	set_process(true)
	_status.text = "播放中：%s @ %.2fs · %s @ %.2fs" % [LABEL_LOOK, _look_slider.value, LABEL_LAUGH, _laugh_slider.value]
	if not _actor.play_clip(ACTION_NAME, false, false):
		_status.text = "动作加载中…稍候会自动开播"
		_actor.focus_clip(ACTION_NAME)
		_wait_then_play(gen)
		return
	_actor.speed_scale = maxf(_action_speed_slider.value, 0.05)


func _wait_then_play(gen: int) -> void:
	await get_tree().create_timer(0.05).timeout
	if gen != _play_gen:
		return
	for _i in 80:
		if _actor.has_clip_ready(ACTION_NAME):
			if not _actor.play_clip(ACTION_NAME, false, false):
				_status.text = "播放失败：%s" % ACTION_NAME
				return
			_actor.speed_scale = maxf(_action_speed_slider.value, 0.05)
			return
		await get_tree().create_timer(0.05).timeout
		if gen != _play_gen:
			return
	_status.text = "超时：动作帧未就绪 %s" % ACTION_NAME


func _stop_all() -> void:
	_play_gen += 1
	_clip_playing = false
	set_process(false)
	_stop_voices_only()
	if _actor != null:
		_actor.stop_playback()
	_status.text = "已停止"
	_time_label.text = "动作时间 0.00s / 总长约 %.2fs" % _clip_duration()


func _stop_voices_only() -> void:
	_look_left = -1.0
	_laugh_left = -1.0
	_look_fired = true
	_laugh_fired = true
	if _voice_a.playing:
		_voice_a.stop()
	if _voice_b.playing:
		_voice_b.stop()
	_voice_a.stream = null
	_voice_b.stream = null


func _on_actor_finished() -> void:
	_clip_playing = false
	set_process(false)
	_status.text = "动作播完 · 配音可继续收尾"
	_time_label.text = "动作时间 %.2fs / 总长约 %.2fs" % [_clip_elapsed, _clip_duration()]


func _save_config() -> void:
	_write_ui_into_entry()
	var root := {
		"action_root": "res://NewMotion/动作",
		"description": "NewMotion 序列帧动作 ↔ 配音。由 newmotion_action_voice_test / look_there_voice_cues_test 保存。",
		"entries": _entries,
	}
	var file := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file == null:
		_status.text = "保存失败：打不开 %s" % CONFIG_PATH
		return
	file.store_string(JSON.stringify(root, "\t"))
	file.close()
	if _actor != null and _actor.has_method("reload_voice_map"):
		_actor.reload_voice_map()
	_status.text = "已保存 → %s（%s.audio_cues）" % [CONFIG_PATH, ACTION_NAME]


func _load_audio(path: String) -> AudioStream:
	var stream := ResourceLoader.load(path, "AudioStream") as AudioStream
	if stream != null:
		return stream
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		bytes = FileAccess.get_file_as_bytes(ProjectSettings.globalize_path(path))
	if bytes.is_empty():
		push_warning("配音加载失败: %s" % path)
		return null
	if path.get_extension().to_lower() != "mp3":
		return null
	var mp3 := AudioStreamMP3.new()
	mp3.data = bytes
	return mp3
