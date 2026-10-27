extends Node
class_name SpriteClawShowAdapter

## 业务 ShowPort → 序列帧。无 3D / 表情 / 口型。
## 对外：play / show_finished / show_failed / welcome_finished（与 ClawBusiness.bind 对齐）

signal show_finished(token: int)
signal show_failed(token: int)
signal welcome_finished
signal clip_changed(action_id: String, clip: String)
signal pose_command(action_id: String, token: int, wait_for_it: bool)
signal neutral_play(action_id: String)

const MAP_PATH := "res://config/newmotion_claw_sprite_map.json"
const ACTION_ROOT := "res://NewMotion/动作"

var _actor: AnimatedSprite2D
var _map: Dictionary = {}
var _fallback_idle := "youyou_Idlebreath"
var _wait_token := -1
var _wait_clip := ""
var _await_voice := false
var _opening_pending := false
var _play_gen := 0
var _random_when_idle := true
var _random_active := false
## 待机招揽组合：待机动作 → 呼吸待机 → 招揽动作，循环；各槽随机抽。
enum RandomSlot { STANDBY, BREATH, ATTRACT }
var _random_slot := RandomSlot.STANDBY
var _standby_pool: PackedStringArray = PackedStringArray()
var _attract_pool: PackedStringArray = PackedStringArray()
var _random_include: PackedStringArray = PackedStringArray()
var _random_exclude: PackedStringArray = PackedStringArray()
var _last_standby_clip := ""
var _last_attract_clip := ""
var _rng := RandomNumberGenerator.new()
var _pose_wait_token := -1
var last_action := ""
var last_speech := ""
var last_clip := ""

const POSE_ACTIONS: PackedStringArray = ["paid_observe", "operating", "grabbing"]


func setup(actor: AnimatedSprite2D) -> void:
	_actor = actor
	_rng.randomize()
	_load_map()
	if _actor.has_signal("target_finished") and not _actor.is_connected("target_finished", _on_target_finished):
		_actor.connect("target_finished", _on_target_finished)
	elif not _actor.animation_finished.is_connected(_on_target_finished):
		_actor.animation_finished.connect(_on_target_finished)
	if _actor.has_signal("clip_started") and not _actor.is_connected("clip_started", _on_clip_started):
		_actor.connect("clip_started", _on_clip_started)


func reload_map() -> void:
	_load_map()


func note_clip(action_id: String, clip: String) -> void:
	last_action = action_id
	last_clip = clip
	clip_changed.emit(action_id, clip)


func finish_pose_wait() -> void:
	if _pose_wait_token < 0:
		return
	var token := _pose_wait_token
	_pose_wait_token = -1
	show_finished.emit(token)


func play(action_id: String, speech_id: String, token: int, wait_for_it: bool = false) -> void:
	last_speech = speech_id
	_await_voice = false
	if action_id in POSE_ACTIONS:
		_random_active = false
		_opening_pending = false
		_play_gen += 1
		_wait_token = -1
		_wait_clip = ""
		_pose_wait_token = token if wait_for_it else -1
		last_action = action_id
		pose_command.emit(action_id, token, wait_for_it)
		return
	_pose_wait_token = -1
	neutral_play.emit(action_id)
	if action_id == "idle_base" and _random_when_idle and _has_random_pools():
		last_action = action_id
		_opening_pending = false
		_wait_token = token if wait_for_it else -1
		_wait_clip = ""
		if _random_active:
			if wait_for_it:
				call_deferred("_emit_done", token)
			return
		_play_gen += 1
		_begin_random_idle()
		if wait_for_it:
			call_deferred("_emit_done", token)
		return
	_random_active = false
	last_action = action_id
	_play_gen += 1
	_wait_token = token if wait_for_it else -1
	_wait_clip = ""
	_opening_pending = action_id == "opening"
	var lookup_id := action_id
	if action_id == "opening" and speech_id == "coin_return":
		lookup_id = "opening_return"
	var entry := _lookup(lookup_id)
	if entry.is_empty() and lookup_id != action_id:
		entry = _lookup(action_id)
	if entry.is_empty():
		push_warning("序列帧映射缺失: %s" % action_id)
		if wait_for_it:
			call_deferred("_emit_failed", token)
		elif _opening_pending:
			_opening_pending = false
			call_deferred("_emit_welcome")
		return
	var clip := String(entry.get("clip", ""))
	var loop := bool(entry.get("loop", false))
	if wait_for_it:
		loop = false
	# 业务段落直接切，不要先插一轮呼吸待机（那会拖住投币欢迎，还会因 720/1080 身高差闪一帧）。
	if wait_for_it:
		_wait_clip = clip
	if not _actor.has_method("play_clip") or not bool(_actor.call("play_clip", clip, loop, false)):
		push_error("序列帧播放失败: action=%s clip=%s" % [action_id, clip])
		if wait_for_it:
			call_deferred("_emit_failed", token)
		elif _opening_pending:
			_opening_pending = false
			call_deferred("_emit_welcome")
		return
	last_clip = String(_actor.call("current_clip")) if _actor.has_method("current_clip") else clip
	clip_changed.emit(action_id, last_clip)


## 返场片段自己播，先停掉随机待机，避免它插进来。
func suspend_for_return() -> void:
	_random_active = false
	_opening_pending = false
	_wait_token = -1
	_wait_clip = ""
	_pose_wait_token = -1
	_play_gen += 1


func is_random_idle() -> bool:
	return _random_active


func resume_random_idle() -> void:
	suspend_for_return()
	last_action = "idle_base"
	if _random_when_idle and _has_random_pools():
		neutral_play.emit("idle_base")
		_begin_random_idle()
		return
	play("idle_base", "", 0, false)


func breath_clip() -> String:
	return _fallback_idle


func pick_random_standby() -> String:
	return _pick_from_pool(_standby_pool, _last_standby_clip)


func pick_random_attract() -> String:
	return _pick_from_pool(_attract_pool, _last_attract_clip)


func note_picked_standby(clip: String) -> void:
	if clip != "":
		_last_standby_clip = clip


func note_picked_attract(clip: String) -> void:
	if clip != "":
		_last_attract_clip = clip


func play_action(action_id: String, token: int) -> void:
	play(action_id, "", token, false)


func play_speech(speech_id: String, token: int) -> void:
	play("", speech_id, token, false)


func _on_clip_started(clip_name: String, is_bridge: bool) -> void:
	last_clip = clip_name
	var action_id := "transition" if is_bridge else last_action
	clip_changed.emit(action_id, clip_name)


func _process(_delta: float) -> void:
	if not _await_voice:
		set_process(false)
		return
	if _is_voice_playing():
		return
	_await_voice = false
	set_process(false)
	_complete_wait_or_idle()


func _on_target_finished() -> void:
	if _actor != null and _actor.has_method("is_bridging") and bool(_actor.call("is_bridging")):
		return
	if _random_active:
		_play_random_next()
		return
	if _wait_token >= 0 and _wait_clip != "" and not _is_current_wait_clip():
		return
	if _wait_token >= 0 and _is_voice_playing():
		_await_voice = true
		set_process(true)
		return
	_complete_wait_or_idle()


func _complete_wait_or_idle() -> void:
	var gen := _play_gen
	if _opening_pending:
		_opening_pending = false
		welcome_finished.emit()
	if gen != _play_gen:
		return
	var waited := _wait_token >= 0
	if waited:
		var t := _wait_token
		_wait_token = -1
		_wait_clip = ""
		show_finished.emit(t)
	if gen != _play_gen:
		return
	if _actor != null and _actor.has_method("is_looping_clip") and not bool(_actor.call("is_looping_clip")):
		if waited:
			_play_hold_idle()
		else:
			_play_idle_fallback()


func _is_current_wait_clip() -> bool:
	if _wait_clip == "":
		return true
	if _actor != null and _actor.has_method("current_clip"):
		return String(_actor.call("current_clip")) == _wait_clip
	return last_clip == _wait_clip


func _is_voice_playing() -> bool:
	return _actor != null and _actor.has_method("is_voice_playing") and bool(_actor.call("is_voice_playing"))


func _play_hold_idle() -> void:
	_random_active = false
	var clip := _fallback_idle
	var entry := _lookup("idle_base")
	if not entry.is_empty():
		clip = String(entry.get("clip", clip))
	if clip == "" or not _actor.has_method("play_clip"):
		return
	var same_playing := (
		_actor.has_method("current_clip")
		and String(_actor.call("current_clip")) == clip
		and _actor.is_playing()
	)
	if same_playing:
		return
	_play_gen += 1
	_wait_token = -1
	_opening_pending = false
	if bool(_actor.call("play_clip", clip, true, false)):
		last_action = "idle_hold"
		last_clip = clip
		clip_changed.emit("idle_hold", clip)


func _play_idle_fallback() -> void:
	if _random_when_idle and _has_random_pools():
		_begin_random_idle()
		return
	var entry := _lookup("idle_base")
	var clip := _fallback_idle
	if not entry.is_empty():
		clip = String(entry.get("clip", clip))
	var same_playing := (
		_actor != null
		and _actor.has_method("current_clip")
		and String(_actor.call("current_clip")) == clip
		and _actor.is_playing()
	)
	if clip == "" or same_playing:
		return
	_play_gen += 1
	_wait_token = -1
	_opening_pending = false
	if _actor.has_method("play_clip") and bool(_actor.call("play_clip", clip, true, false)):
		last_action = "idle_base"
		last_clip = clip
		clip_changed.emit("idle_base", clip)


func _begin_random_idle() -> void:
	_random_active = true
	_wait_token = -1
	_opening_pending = false
	_random_slot = RandomSlot.STANDBY
	_play_random_next()


func _play_random_next() -> void:
	if not _random_active or not _has_random_pools():
		return
	if not _actor.has_method("play_clip"):
		return
	var clip := ""
	var action_id := "idle_random"
	match _random_slot:
		RandomSlot.STANDBY:
			clip = _pick_from_pool(_standby_pool, _last_standby_clip)
			if clip == "":
				clip = _pick_from_pool(_attract_pool, _last_attract_clip)
			_last_standby_clip = clip
			_random_slot = RandomSlot.BREATH
			action_id = "idle_standby"
		RandomSlot.BREATH:
			clip = _fallback_idle
			_random_slot = RandomSlot.ATTRACT
			action_id = "idle_breath"
		_:
			clip = _pick_from_pool(_attract_pool, _last_attract_clip)
			if clip == "":
				clip = _pick_from_pool(_standby_pool, _last_standby_clip)
			_last_attract_clip = clip
			_random_slot = RandomSlot.STANDBY
			action_id = "idle_attract"
	if clip == "":
		return
	## 组合内自带呼吸槽，不再经 via_idle 插额外呼吸
	if not bool(_actor.call("play_clip", clip, false, false)):
		push_warning("随机动作播不了: %s" % clip)
		return
	last_action = action_id
	last_clip = String(_actor.call("current_clip")) if _actor.has_method("current_clip") else clip
	clip_changed.emit(action_id, last_clip)
	_prefetch_random_followup()


func _prefetch_random_followup() -> void:
	if _actor == null or not _actor.has_method("prefetch_clip"):
		return
	var nxt := ""
	match _random_slot:
		RandomSlot.STANDBY:
			nxt = _pick_from_pool(_standby_pool, _last_standby_clip)
			if nxt == "":
				nxt = _pick_from_pool(_attract_pool, _last_attract_clip)
		RandomSlot.BREATH:
			nxt = _fallback_idle
		_:
			nxt = _pick_from_pool(_attract_pool, _last_attract_clip)
			if nxt == "":
				nxt = _pick_from_pool(_standby_pool, _last_standby_clip)
	if nxt != "":
		_actor.call("prefetch_clip", nxt, true)


func _has_random_pools() -> bool:
	return not _standby_pool.is_empty() or not _attract_pool.is_empty()


func _pick_from_pool(pool: PackedStringArray, last_clip: String) -> String:
	if pool.is_empty():
		return ""
	if pool.size() == 1:
		return pool[0]
	var candidates := PackedStringArray()
	for clip in pool:
		if clip != last_clip:
			candidates.append(clip)
	if candidates.is_empty():
		return pool[0]
	return candidates[_rng.randi_range(0, candidates.size() - 1)]


func _rebuild_random_pool() -> void:
	_standby_pool = PackedStringArray()
	_attract_pool = PackedStringArray()
	var source: PackedStringArray = PackedStringArray()
	if not _random_include.is_empty():
		for clip in _random_include:
			if clip == _fallback_idle or clip in _random_exclude:
				continue
			if NewMotionActionFs.folder_has_frames(NewMotionActionFs.clip_dir(clip)):
				source.append(clip)
			else:
				push_warning("随机待机池缺少动作: %s" % clip)
	else:
		var dir := DirAccess.open(NewMotionActionFs.abs_root())
		if dir == null:
			push_error("打不开动作目录: %s" % NewMotionActionFs.abs_root())
			return
		dir.list_dir_begin()
		var entry := dir.get_next()
		while entry != "":
			if dir.current_is_dir() and not entry.begins_with("."):
				if entry != _fallback_idle and not entry in _random_exclude and NewMotionActionFs.folder_has_frames(NewMotionActionFs.clip_dir(entry)):
					source.append(entry)
			entry = dir.get_next()
		dir.list_dir_end()
	for clip in source:
		var lower := clip.to_lower()
		if "attract" in lower or "招揽" in clip:
			_attract_pool.append(clip)
		else:
			_standby_pool.append(clip)
	if _standby_pool.is_empty() and not _attract_pool.is_empty():
		_standby_pool = _attract_pool.duplicate()
	if _attract_pool.is_empty() and not _standby_pool.is_empty():
		_attract_pool = _standby_pool.duplicate()


func _folder_has_png(folder: String) -> bool:
	return NewMotionActionFs.folder_has_frames(folder)


func _lookup(action_id: String) -> Dictionary:
	if action_id == "" or not _map.has(action_id):
		return {}
	var raw: Variant = _map[action_id]
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	return raw as Dictionary


func _load_map() -> void:
	_map.clear()
	if not FileAccess.file_exists(MAP_PATH):
		push_error("缺少映射: %s" % MAP_PATH)
		return
	var text := FileAccess.get_file_as_string(MAP_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("映射 JSON 无效: %s" % MAP_PATH)
		return
	var root := parsed as Dictionary
	_fallback_idle = String(root.get("fallback_idle", _fallback_idle))
	_random_when_idle = bool(root.get("random_when_idle", true))
	_random_include = PackedStringArray()
	var include: Variant = root.get("random_include", [])
	if typeof(include) == TYPE_ARRAY:
		for item in include:
			_random_include.append(String(item))
	_random_exclude = PackedStringArray()
	var exclude: Variant = root.get("random_exclude", [])
	if typeof(exclude) == TYPE_ARRAY:
		for item in exclude:
			_random_exclude.append(String(item))
	var mappings: Variant = root.get("mappings", {})
	if typeof(mappings) == TYPE_DICTIONARY:
		_map = mappings as Dictionary
	_rebuild_random_pool()


func _emit_done(token: int) -> void:
	if is_inside_tree():
		show_finished.emit(token)


func _emit_failed(token: int) -> void:
	if is_inside_tree():
		show_failed.emit(token)


func _emit_welcome() -> void:
	if is_inside_tree():
		welcome_finished.emit()
