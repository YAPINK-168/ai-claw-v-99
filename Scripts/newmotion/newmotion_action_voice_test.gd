extends Node

## NewMotion 序列帧动作配音测试：选动作、选配音、调起点/语速，保存到 JSON。

const ACTION_ROOT := "res://NewMotion/动作"
const VOICE_ROOT := "res://配音"
const CONFIG_PATH := "res://config/newmotion_action_voice_map.json"
const VIEWPORT_SIZE := Vector2i(1920, 1080)

@onready var _actor: NewMotionSpriteActor = $CharacterLayer/Character
@onready var _action_option: OptionButton = $UiLayer/Panel/Margin/VBox/ActionRow/ActionOption
@onready var _voice_option: OptionButton = $UiLayer/Panel/Margin/VBox/VoiceRow/VoiceOption
@onready var _offset_slider: HSlider = $UiLayer/Panel/Margin/VBox/OffsetRow/OffsetSlider
@onready var _offset_value: Label = $UiLayer/Panel/Margin/VBox/OffsetRow/OffsetValue
@onready var _audio_speed_slider: HSlider = $UiLayer/Panel/Margin/VBox/AudioSpeedRow/AudioSpeedSlider
@onready var _audio_speed_value: Label = $UiLayer/Panel/Margin/VBox/AudioSpeedRow/AudioSpeedValue
@onready var _action_speed_slider: HSlider = $UiLayer/Panel/Margin/VBox/ActionSpeedRow/ActionSpeedSlider
@onready var _action_speed_value: Label = $UiLayer/Panel/Margin/VBox/ActionSpeedRow/ActionSpeedValue
@onready var _notes_edit: LineEdit = $UiLayer/Panel/Margin/VBox/NotesRow/NotesEdit
@onready var _loop_check: CheckBox = $UiLayer/Panel/Margin/VBox/ControlRow/LoopCheck
@onready var _status: Label = $UiLayer/Panel/Margin/VBox/StatusLabel
@onready var _coverage: Label = $UiLayer/Panel/Margin/VBox/CoverageLabel
@onready var _audio: AudioStreamPlayer = $AudioStreamPlayer

var _actions: PackedStringArray = PackedStringArray()
var _voices: PackedStringArray = PackedStringArray()
var _entries: Dictionary = {}
var _syncing := false
var _audio_delay_left := -1.0
var _waiting_audio := false


func _enter_tree() -> void:
	_apply_viewport()


func _ready() -> void:
	set_process(false)
	_apply_ui_font()
	## 预览走角色内建配音，避免测试场景再播一遍。
	_actor.auto_play_voice = true
	_actions = _list_dirs(NewMotionActionFs.abs_root())
	_voices = _list_audio(VOICE_ROOT)
	_load_config()

	_action_option.clear()
	for action_name in _actions:
		_action_option.add_item(_mark_action_label(action_name))
	_voice_option.clear()
	_voice_option.add_item("（无配音）")
	for voice_name in _voices:
		_voice_option.add_item(voice_name)

	_action_option.item_selected.connect(_on_action_selected)
	_voice_option.item_selected.connect(_on_voice_selected)
	_offset_slider.value_changed.connect(_on_offset_changed)
	_audio_speed_slider.value_changed.connect(_on_audio_speed_changed)
	_action_speed_slider.value_changed.connect(_on_action_speed_changed)
	_notes_edit.text_changed.connect(_on_notes_changed)
	$UiLayer/Panel/Margin/VBox/ControlRow/PlayButton.pressed.connect(_play_current)
	$UiLayer/Panel/Margin/VBox/ControlRow/StopButton.pressed.connect(_stop_all)
	$UiLayer/Panel/Margin/VBox/ControlRow/SaveButton.pressed.connect(_save_config)
	$UiLayer/Panel/Margin/VBox/ControlRow/SuggestButton.pressed.connect(_suggest_voice_for_current)
	if has_node("UiLayer/Panel/Margin/VBox/ControlRow/RefreshButton"):
		$UiLayer/Panel/Margin/VBox/ControlRow/RefreshButton.pressed.connect(_refresh_libraries)
	if not _actor.animation_finished.is_connected(_on_actor_finished):
		_actor.animation_finished.connect(_on_actor_finished)

	if _actions.is_empty():
		_status.text = "没有找到动作文件夹：%s" % ACTION_ROOT
		return
	_auto_bind_exact_voice_matches()
	_select_action_index(0)
	_refresh_coverage()
	## 进场景就落第一段序列帧，避免只剩 UI、角色空白。
	_play_current()


func _process(delta: float) -> void:
	if not _waiting_audio:
		set_process(false)
		return
	_audio_delay_left -= delta
	if _audio_delay_left <= 0.0:
		_waiting_audio = false
		set_process(false)
		if _audio.stream != null:
			_audio.play()


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
	window.title = "NewMotion 动作配音测试"
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


func _list_dirs(root: String) -> PackedStringArray:
	var result := PackedStringArray()
	var dir := DirAccess.open(root)
	if dir == null:
		return result
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir() and not entry.begins_with("."):
			result.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	result.sort()
	return result


func _list_audio(root: String) -> PackedStringArray:
	var result := PackedStringArray()
	_collect_audio(root, "", result)
	result.sort()
	return result


func _collect_audio(abs_root: String, rel_prefix: String, result: PackedStringArray) -> void:
	var fs_root := ProjectSettings.globalize_path(abs_root)
	var dir := DirAccess.open(fs_root)
	if dir == null:
		dir = DirAccess.open(abs_root)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			if not entry.begins_with("."):
				var child_rel := entry if rel_prefix == "" else rel_prefix.path_join(entry)
				_collect_audio(abs_root.path_join(entry), child_rel, result)
		else:
			var ext := entry.get_extension().to_lower()
			if ext == "mp3" or ext == "ogg" or ext == "wav":
				if rel_prefix == "":
					result.append(entry)
				else:
					result.append(rel_prefix.path_join(entry))
		entry = dir.get_next()
	dir.list_dir_end()


func _voice_rel_from_path(audio_path: String) -> String:
	var normalized := audio_path.replace("\\", "/")
	var prefix := VOICE_ROOT.replace("\\", "/") + "/"
	if normalized.begins_with(prefix):
		return normalized.substr(prefix.length())
	return normalized.get_file()


func _find_voice_index(rel: String) -> int:
	var found := _voices.find(rel)
	if found >= 0:
		return found
	var want := rel.replace("\\", "/").to_lower()
	for i in _voices.size():
		if String(_voices[i]).replace("\\", "/").to_lower() == want:
			return i
	return -1


func _mark_action_label(action_name: String) -> String:
	if _entries.has(action_name) and str((_entries[action_name] as Dictionary).get("audio_path", "")) != "":
		return "✓ " + action_name
	return action_name


func _refresh_action_labels() -> void:
	var selected := _action_option.selected
	_syncing = true
	_action_option.clear()
	for action_name in _actions:
		_action_option.add_item(_mark_action_label(action_name))
	if selected >= 0 and selected < _action_option.item_count:
		_action_option.select(selected)
	_syncing = false


func _current_action() -> String:
	var idx := _action_option.selected
	if idx < 0 or idx >= _actions.size():
		return ""
	return _actions[idx]


func _select_action_index(index: int) -> void:
	if index < 0 or index >= _actions.size():
		return
	_syncing = true
	_action_option.select(index)
	_syncing = false
	_load_entry_into_ui(_actions[index])


func _on_action_selected(index: int) -> void:
	if _syncing:
		return
	if index < 0 or index >= _actions.size():
		return
	_stop_all()
	_load_entry_into_ui(_actions[index])
	_play_current()


func _on_voice_selected(_index: int) -> void:
	if _syncing:
		return
	_write_ui_into_entry(_current_action())
	_refresh_action_labels()
	_refresh_coverage()


func _on_offset_changed(value: float) -> void:
	_offset_value.text = "%.2fs" % value
	if not _syncing:
		_write_ui_into_entry(_current_action())


func _on_audio_speed_changed(value: float) -> void:
	_audio_speed_value.text = "%.2fx" % value
	if not _syncing:
		_write_ui_into_entry(_current_action())


func _on_action_speed_changed(value: float) -> void:
	_action_speed_value.text = "%.2fx" % value
	if not _syncing:
		_write_ui_into_entry(_current_action())


func _on_notes_changed(_new_text: String) -> void:
	if not _syncing:
		_write_ui_into_entry(_current_action())


func _default_entry() -> Dictionary:
	return {
		"audio_path": "",
		"audio_start_offset": 0.0,
		"audio_speed": 1.0,
		"action_speed": 1.0,
		"notes": "",
	}


func _load_entry_into_ui(action_name: String) -> void:
	var entry: Dictionary = _default_entry()
	if _entries.has(action_name) and _entries[action_name] is Dictionary:
		entry = (_entries[action_name] as Dictionary).duplicate(true)
	_syncing = true
	var audio_path := str(entry.get("audio_path", ""))
	var voice_idx := 0
	if audio_path != "":
		var found := _find_voice_index(_voice_rel_from_path(audio_path))
		if found >= 0:
			voice_idx = found + 1
	_voice_option.select(voice_idx)
	_offset_slider.value = float(entry.get("audio_start_offset", 0.0))
	_offset_value.text = "%.2fs" % _offset_slider.value
	_audio_speed_slider.value = float(entry.get("audio_speed", 1.0))
	_audio_speed_value.text = "%.2fx" % _audio_speed_slider.value
	_action_speed_slider.value = float(entry.get("action_speed", 1.0))
	_action_speed_value.text = "%.2fx" % _action_speed_slider.value
	_notes_edit.text = str(entry.get("notes", ""))
	_syncing = false
	_status.text = "当前：%s" % action_name


func _write_ui_into_entry(action_name: String) -> void:
	if action_name == "":
		return
	var audio_path := ""
	var voice_idx := _voice_option.selected
	if voice_idx > 0 and voice_idx <= _voices.size():
		audio_path = VOICE_ROOT.path_join(_voices[voice_idx - 1])
	var entry := {
		"audio_path": audio_path,
		"audio_start_offset": _offset_slider.value,
		"audio_speed": _audio_speed_slider.value,
		"action_speed": _action_speed_slider.value,
		"notes": _notes_edit.text,
	}
	if audio_path == "" and _notes_edit.text.strip_edges() == "":
		_entries.erase(action_name)
	else:
		_entries[action_name] = entry


func _load_config() -> void:
	_entries.clear()
	if not FileAccess.file_exists(CONFIG_PATH):
		return
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var root := parsed as Dictionary
	var entries: Variant = root.get("entries", {})
	if entries is Dictionary:
		_entries = (entries as Dictionary).duplicate(true)


func _save_config() -> void:
	_write_ui_into_entry(_current_action())
	var payload := {
		"schema": "newmotion_action_voice_map_v1",
		"description": "NewMotion 序列帧动作 ↔ 配音。由 newmotion_action_voice_test 场景编辑保存。",
		"action_root": ACTION_ROOT,
		"voice_root": VOICE_ROOT,
		"entries": _entries,
	}
	var file := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file == null:
		_status.text = "保存失败：无法写入 %s" % CONFIG_PATH
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	_actor.reload_voice_map()
	_refresh_action_labels()
	_refresh_coverage()
	_status.text = "已保存 → %s（%d 条）" % [CONFIG_PATH, _entries.size()]


func _refresh_coverage() -> void:
	var mapped := 0
	for action_name in _actions:
		if _entries.has(action_name) and str((_entries[action_name] as Dictionary).get("audio_path", "")) != "":
			mapped += 1
	_coverage.text = "已配音 %d / %d · 配音库 %d" % [mapped, _actions.size(), _voices.size()]


func _refresh_libraries() -> void:
	var keep_action := _current_action()
	_actions = _list_dirs(NewMotionActionFs.abs_root())
	_voices = _list_audio(VOICE_ROOT)
	_action_option.clear()
	for action_name in _actions:
		_action_option.add_item(_mark_action_label(action_name))
	_voice_option.clear()
	_voice_option.add_item("（无配音）")
	for voice_name in _voices:
		_voice_option.add_item(voice_name)
	_auto_bind_exact_voice_matches()
	var idx := _actions.find(keep_action)
	_select_action_index(maxi(idx, 0))
	_refresh_coverage()
	_status.text = "已刷新：动作 %d · 配音 %d" % [_actions.size(), _voices.size()]


## 动作名与配音文件名（去扩展名）完全一致时，自动写入未配置条目。
func _auto_bind_exact_voice_matches() -> void:
	var bound := 0
	for action_name in _actions:
		if _entries.has(action_name) and str((_entries[action_name] as Dictionary).get("audio_path", "")) != "":
			continue
		var hit := -1
		for i in _voices.size():
			var stem := String(_voices[i]).get_file().get_basename()
			if stem == action_name:
				hit = i
				break
		if hit < 0:
			continue
		var entry := _default_entry()
		entry["audio_path"] = VOICE_ROOT.path_join(_voices[hit])
		entry["notes"] = "自动匹配同名配音"
		_entries[action_name] = entry
		bound += 1
	if bound > 0:
		_refresh_action_labels()


func _suggest_voice_for_current() -> void:
	var action_name := _current_action()
	if action_name == "":
		return
	var best_idx := -1
	var best_score := 0
	for i in _voices.size():
		var score := _name_match_score(action_name, _voices[i].get_file().get_basename())
		if score > best_score:
			best_score = score
			best_idx = i
	if best_idx < 0 or best_score < 2:
		_status.text = "没有较靠谱的配音候选：%s" % action_name
		return
	_syncing = true
	_voice_option.select(best_idx + 1)
	_syncing = false
	_write_ui_into_entry(action_name)
	_refresh_action_labels()
	_refresh_coverage()
	_status.text = "建议配音：%s（相关度 %d）" % [_voices[best_idx], best_score]


func _name_match_score(action_name: String, voice_stem: String) -> int:
	var score := 0
	if action_name == voice_stem:
		return 100
	if action_name in voice_stem or voice_stem in action_name:
		score += 8
	## 别名：动作名 ↔ 配音文件名不完全相同但成对
	var aliases := {
		"doudou_Attract_9": "抓不到唱歌",
		"doudou_Attract_4": "拍苍蝇",
		"youyou_success_1": "哇，手法不错呀",
		"doudou_fail": "掉咯掉咯",
	}
	if aliases.has(action_name) and String(aliases[action_name]) == voice_stem:
		score += 20
	if aliases.has(action_name) and String(aliases[action_name]) in voice_stem:
		score += 12
	var keywords := PackedStringArray([
		"手感", "手法", "经验", "期待", "擦肩", "抓取机会", "机会已激活", "想好了",
		"standby", "Attract", "Idlebreath", "穿搭", "漂亮", "困", "伸懒腰", "玩游戏", "think",
		"靠近", "小可爱", "小游戏", "耍帅", "拍苍蝇", "抓不到", "唱歌", "掉咯",
	])
	for key in keywords:
		if key in action_name and key in voice_stem:
			score += key.length()
	return score


func _play_current() -> void:
	var action_name := _current_action()
	if action_name == "":
		return
	_write_ui_into_entry(action_name)
	_stop_all()
	var entry: Dictionary = _default_entry()
	if _entries.has(action_name):
		entry = _entries[action_name] as Dictionary
	_actor.apply_voice_entry(action_name, entry)
	var ok := _actor.play_clip(action_name, _loop_check.button_pressed, false)
	if not ok:
		_status.text = "动作播不了：%s" % action_name
		return
	var audio_path := str(entry.get("audio_path", ""))
	if audio_path == "":
		_status.text = "播放动作（无配音）：%s" % action_name
		return
	_status.text = "播放：%s + %s" % [action_name, audio_path.get_file()]


func _stop_all() -> void:
	_waiting_audio = false
	_audio_delay_left = -1.0
	set_process(false)
	if _audio.playing:
		_audio.stop()
	_actor.stop_playback()
	_actor.speed_scale = 1.0


func _on_actor_finished() -> void:
	if _loop_check.button_pressed:
		return
	if _actor.is_voice_playing():
		_status.text = "动作结束，配音仍在播…"
	else:
		_status.text = "播放结束"
