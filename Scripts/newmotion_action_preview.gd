extends Node

const ACTION_ROOT := "res://NewMotion/动作"
const VOICE_MAP_PATH := "res://config/newmotion_action_voice_map.json"
const VIEWPORT_SIZE := Vector2i(1920, 1080)
const PLAYBACK_FPS := 24.0
## Feet rest on the floor emblem in the center of the room.
const FEET_ANCHOR := Vector2(0.509, 0.835)
const CHARACTER_HEIGHT_RATIO := 0.60
const FEET_IN_FRAME := 0.994
const IDLE_CLIP := "youyou_Idlebreath"
const RANDOM_IDLE_CLIPS: PackedStringArray = [
	"youyou_standby_5",
	"youyou_Attract_3",
	"youyou_Attract_2",
	"youyou_Attract_1",
	"youyou_standby_1",
	"youyou_standby_3",
	"youyou_Attract_5",
	"youyou_standby_2",
	"youyou_Attract_4",
]
## Spread disk decode across idle frames so the next clip is ready without a hitch.
const WARM_BATCH := 8

@onready var _character: AnimatedSprite2D = $CharacterLayer/Character
@onready var _action_option: OptionButton = $UiLayer/ActionBar/Margin/Row/ActionOption
@onready var _caption: Label = $UiLayer/ActionBar/Margin/Row/Caption

var _actions: PackedStringArray = PackedStringArray()
var _random_pool: PackedStringArray = PackedStringArray()
var _playing := ""
var _pending_after_idle := ""
## One shared atlas of clips. Only idle + current + preloaded-next stay resident.
var _shared_frames: SpriteFrames = SpriteFrames.new()
var _rng := RandomNumberGenerator.new()
var _syncing_option := false

var _warm_action := ""
var _warm_files: PackedStringArray = PackedStringArray()
var _warm_index := 0
var _warm_textures: Array[Texture2D] = []

var _voice_entries: Dictionary = {}
var _voice: AudioStreamPlayer
var _voice_delay_left := -1.0
var _waiting_voice := false


func _enter_tree() -> void:
	_apply_viewport()


func _ready() -> void:
	_rng.randomize()
	set_process(false)
	_load_voice_map()
	_ensure_voice_player()
	_apply_ui_font()
	_caption.text = "随机 · 待机过渡"
	if _shared_frames.has_animation(&"default"):
		_shared_frames.remove_animation(&"default")
	_character.sprite_frames = _shared_frames
	_actions = _list_actions()
	_random_pool = _build_random_pool(_actions)
	for action_name in _actions:
		_action_option.add_item(action_name)
	_action_option.item_selected.connect(_on_action_selected)
	_character.animation_finished.connect(_on_animation_finished)
	if _actions.is_empty():
		push_error("没有在 %s 里找到动作文件夹" % ACTION_ROOT)
		return
	## Warm idle first so action→idle never pays a cold load.
	if not _ensure_animation(IDLE_CLIP):
		push_error("待机动作加载失败: %s" % IDLE_CLIP)
	if _random_pool.is_empty():
		push_error("随机池为空（可能都被排除了）")
		_action_option.select(0)
		_play_action(_actions[0])
		return
	_play_random_next()


func _process(delta: float) -> void:
	_pump_warmup()
	if _waiting_voice:
		_voice_delay_left -= delta
		if _voice_delay_left <= 0.0:
			_waiting_voice = false
			if _voice != null and _voice.stream != null:
				_voice.play()
	if _warm_action == "" and not _waiting_voice:
		set_process(false)


func _apply_viewport() -> void:
	var window := get_window()
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	window.content_scale_size = VIEWPORT_SIZE
	window.title = "动作预览 · 随机循环"
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
	theme.default_font_size = 22
	$UiLayer/ActionBar.theme = theme


func _list_actions() -> PackedStringArray:
	var result := PackedStringArray()
	var dir := DirAccess.open(NewMotionActionFs.abs_root())
	if dir == null:
		push_error("打不开动作目录: %s (%s)" % [NewMotionActionFs.abs_root(), error_string(DirAccess.get_open_error())])
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


func _build_random_pool(all_actions: PackedStringArray) -> PackedStringArray:
	var pool := PackedStringArray()
	for action_name in RANDOM_IDLE_CLIPS:
		if action_name in all_actions:
			pool.append(action_name)
	return pool


func _on_action_selected(index: int) -> void:
	if _syncing_option:
		return
	if index < 0 or index >= _actions.size():
		return
	_request_action(_actions[index])


func _on_animation_finished() -> void:
	if _playing != IDLE_CLIP:
		## Decide the next clip now so idle can preload it.
		if _pending_after_idle == "":
			_pending_after_idle = _pick_random_action()
		var next_name := _pending_after_idle
		_play_action(IDLE_CLIP)
		_schedule_preload(next_name)
		_evict_except([IDLE_CLIP, next_name])
		return
	if _pending_after_idle != "":
		var next_name := _pending_after_idle
		_pending_after_idle = ""
		_finish_warmup_now(next_name)
		_play_action(next_name)
		_evict_except([IDLE_CLIP, next_name])
		return
	_play_random_next()


func _play_random_next() -> void:
	if _random_pool.is_empty():
		return
	_request_action(_pick_random_action())


func _request_action(action_name: String) -> void:
	if action_name == "":
		return
	if _playing != "" and _playing != IDLE_CLIP and action_name != IDLE_CLIP:
		_pending_after_idle = action_name
		_play_action(IDLE_CLIP)
		_schedule_preload(action_name)
		_evict_except([IDLE_CLIP, action_name])
		return
	_pending_after_idle = ""
	_finish_warmup_now(action_name)
	_play_action(action_name)
	_evict_except([IDLE_CLIP, action_name])


func _pick_random_action() -> String:
	if _random_pool.size() == 1:
		return _random_pool[0]
	var candidates := PackedStringArray()
	for action_name in _random_pool:
		if action_name != _playing:
			candidates.append(action_name)
	if candidates.is_empty():
		return _random_pool[0]
	return candidates[_rng.randi_range(0, candidates.size() - 1)]


func _play_action(action_name: String) -> void:
	if not _ensure_animation(action_name):
		return
	var sample := _shared_frames.get_frame_texture(action_name, 0)
	if sample == null:
		return
	if _character.sprite_frames != _shared_frames:
		_character.sprite_frames = _shared_frames
	_character.animation = action_name
	_place_character(sample.get_height())
	_apply_mapped_voice(action_name)
	_character.play(action_name)
	_playing = action_name
	_sync_option_to_playing()
	print("播放: %s" % action_name)


func _sync_option_to_playing() -> void:
	var index := _actions.find(_playing)
	if index < 0 or _action_option.selected == index:
		return
	_syncing_option = true
	_action_option.select(index)
	_syncing_option = false


func _ensure_animation(action_name: String) -> bool:
	if action_name == "":
		return false
	if _shared_frames.has_animation(action_name) and _shared_frames.get_frame_count(action_name) > 0:
		return true
	if _warm_action == action_name:
		_finish_warmup_now(action_name)
		return _shared_frames.has_animation(action_name) and _shared_frames.get_frame_count(action_name) > 0
	return _load_animation_into_shared(action_name)


func _list_png_names(action_name: String) -> PackedStringArray:
	var file_names := NewMotionActionFs.list_frame_names(action_name)
	if file_names.is_empty():
		push_error("打不开动作: %s" % NewMotionActionFs.clip_dir(action_name))
	return file_names


func _load_texture(path: String) -> Texture2D:
	return NewMotionActionFs.load_png(path)


func _load_animation_into_shared(action_name: String) -> bool:
	var file_names := _list_png_names(action_name)
	if file_names.is_empty():
		push_error("动作没有序列帧: %s" % action_name)
		return false
	var folder := NewMotionActionFs.clip_dir(action_name)
	if _shared_frames.has_animation(action_name):
		_shared_frames.remove_animation(action_name)
	_shared_frames.add_animation(action_name)
	_shared_frames.set_animation_loop(action_name, false)
	_shared_frames.set_animation_speed(action_name, PLAYBACK_FPS)
	for file_name in file_names:
		var texture := _load_texture(folder.path_join(file_name))
		if texture == null:
			push_error("读取失败: %s" % folder.path_join(file_name))
			continue
		_shared_frames.add_frame(action_name, texture)
	if _shared_frames.get_frame_count(action_name) == 0:
		_shared_frames.remove_animation(action_name)
		return false
	return true


func _schedule_preload(action_name: String) -> void:
	if action_name == "" or action_name == IDLE_CLIP:
		return
	if _shared_frames.has_animation(action_name) and _shared_frames.get_frame_count(action_name) > 0:
		_cancel_warmup()
		return
	if _warm_action == action_name:
		return
	_cancel_warmup()
	var files := _list_png_names(action_name)
	if files.is_empty():
		return
	_warm_action = action_name
	_warm_files = files
	_warm_index = 0
	_warm_textures.clear()
	set_process(true)


func _cancel_warmup() -> void:
	_warm_action = ""
	_warm_files = PackedStringArray()
	_warm_index = 0
	_warm_textures.clear()
	if not _waiting_voice:
		set_process(false)


func _pump_warmup() -> void:
	if _warm_action == "":
		return
	var folder := NewMotionActionFs.clip_dir(_warm_action)
	var n := 0
	while n < WARM_BATCH and _warm_index < _warm_files.size():
		var texture := _load_texture(folder.path_join(_warm_files[_warm_index]))
		_warm_textures.append(texture)
		_warm_index += 1
		n += 1
	if _warm_index >= _warm_files.size():
		_commit_warmup()


func _commit_warmup() -> void:
	var action_name := _warm_action
	if action_name == "":
		_cancel_warmup()
		return
	if _shared_frames.has_animation(action_name):
		_shared_frames.remove_animation(action_name)
	_shared_frames.add_animation(action_name)
	_shared_frames.set_animation_loop(action_name, false)
	_shared_frames.set_animation_speed(action_name, PLAYBACK_FPS)
	for texture in _warm_textures:
		if texture != null:
			_shared_frames.add_frame(action_name, texture)
	_cancel_warmup()


func _finish_warmup_now(action_name: String) -> void:
	if _warm_action != action_name:
		return
	var folder := NewMotionActionFs.clip_dir(_warm_action)
	while _warm_index < _warm_files.size():
		var texture := _load_texture(folder.path_join(_warm_files[_warm_index]))
		_warm_textures.append(texture)
		_warm_index += 1
	_commit_warmup()


func _evict_except(keep: PackedStringArray) -> void:
	for anim_name in _shared_frames.get_animation_names():
		if anim_name in keep:
			continue
		if anim_name == _warm_action:
			continue
		_shared_frames.remove_animation(anim_name)


func _load_voice_map() -> void:
	_voice_entries.clear()
	if not FileAccess.file_exists(VOICE_MAP_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(VOICE_MAP_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var entries: Variant = (parsed as Dictionary).get("entries", {})
	if entries is Dictionary:
		_voice_entries = (entries as Dictionary).duplicate(true)


func _ensure_voice_player() -> void:
	if _voice != null:
		return
	_voice = AudioStreamPlayer.new()
	_voice.name = "MappedVoice"
	add_child(_voice)


func _apply_mapped_voice(action_name: String) -> void:
	_stop_voice()
	_character.speed_scale = 1.0
	if action_name == "" or action_name == IDLE_CLIP:
		return
	var raw: Variant = _voice_entries.get(action_name, {})
	if typeof(raw) != TYPE_DICTIONARY:
		return
	var entry := raw as Dictionary
	_character.speed_scale = maxf(float(entry.get("action_speed", 1.0)), 0.05)
	var audio_path := str(entry.get("audio_path", ""))
	if audio_path == "":
		return
	_ensure_voice_player()
	var stream := ResourceLoader.load(audio_path, "AudioStream") as AudioStream
	if stream == null:
		push_warning("配音加载失败: %s → %s" % [action_name, audio_path])
		return
	_voice.stream = stream
	_voice.pitch_scale = maxf(float(entry.get("audio_speed", 1.0)), 0.05)
	var delay := maxf(float(entry.get("audio_start_offset", 0.0)), 0.0)
	if delay <= 0.0:
		_voice.play()
		return
	_voice_delay_left = delay
	_waiting_voice = true
	set_process(true)


func _stop_voice() -> void:
	_waiting_voice = false
	_voice_delay_left = -1.0
	if _voice != null and _voice.playing:
		_voice.stop()
	if _voice != null:
		_voice.stream = null


func _place_character(texture_height: int) -> void:
	var viewport := Vector2(VIEWPORT_SIZE)
	var target_height := viewport.y * CHARACTER_HEIGHT_RATIO
	var scale_factor := target_height / float(texture_height)
	_character.scale = Vector2(scale_factor, scale_factor)
	var feet_offset := float(texture_height) * scale_factor * (FEET_IN_FRAME - 0.5)
	_character.position = Vector2(
		viewport.x * FEET_ANCHOR.x,
		viewport.y * FEET_ANCHOR.y - feet_offset
	)
