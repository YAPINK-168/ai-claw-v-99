extends Node
class_name YouyouActionLipsyncTimeline

## 独立测试场景：动作 + 绑定配音 + 表情/口型时间轴（代际 token 防过期回调）。

const FacePresenter := preload("res://Scripts/youyou_face_presenter.gd")
const VisemeDriver := preload("res://Scripts/youyou_test_audio_viseme_driver.gd")
const VoiceSubtitleCatalog := preload("res://Scripts/youyou_voice_subtitle_catalog.gd")
const DEFAULT_PRE_POST_IDLE := 1.667
const Approved := preload("res://Scripts/youyou_action_lipsync_approved.gd")
const DefaultEventCatalog := preload("res://Scripts/youyou_action_event_catalog.gd")
const VoiceEmotionSchedules := preload("res://Scripts/youyou_voice_emotion_schedules.gd")
const SplitTimelines := preload("res://Scripts/youyou_action_split_expression_timelines.gd")
const SplitTimelinePlayer := preload("res://Scripts/youyou_split_expression_timeline_player.gd")
const DirectVisemePlayer := preload("res://Scripts/youyou_direct_viseme_mesh_player.gd")

enum Phase { STOPPED, PRE_IDLE, MAIN, POST, FINISHED }

const CATALOG_FILTER_ALL := "all"
const CATALOG_FILTER_APPROVED := "approved"
const CATALOG_FILTER_EVENT := "event"
const RESOURCE_KIND_APPROVED := "approved_catalog"
const RESOURCE_KIND_EVENT := "event_catalog"

## 与美术表一致：仅收录已交付且工程内存在配音 mp3 的动作。
const ACTION_CATALOG: Array[Dictionary] = [
	{
		"action_id": "youyou_Basic_Idle01",
		"scene": "res://待机Animation/youyou_Basic_Idle01.001.glb",
		"source_anim": "youyou_Basic_Idle01_001",
		"default_audio": "res://配音/操作2-这个角度.mp3",
		"default_emotion": "think",
	},
	{
		"action_id": "youyou_Basic_Idle02",
		"scene": "res://待机Animation/youyou_Basic_Idle02.glb",
		"source_anim": "youyou_Basic_Idle02",
		"default_audio": "res://配音/轻待机5-吃什么.mp3",
		"default_emotion": "think",
	},
	{
		"action_id": "youyou_Basic_Idle03",
		"scene": "res://待机Animation/youyou_Basic_Idle03.glb",
		"source_anim": "youyou_Basic_Idle03",
		"default_audio": "res://配音/轻待机3-数手指.mp3",
		"default_emotion": "think",
	},
	{
		"action_id": "youyou_Basic_Idle04",
		"scene": "res://待机Animation/youyou_Basic_Idle04.glb",
		"source_anim": "youyou_Basic_Idle04",
		"default_audio": "res://配音/轻待机5-看看什么有意思.mp3",
		"default_emotion": "grin",
	},
	{
		"action_id": "youyou_Basic_Idle05",
		"scene": "res://待机Animation/youyou_Basic_Idle05.glb",
		"source_anim": "youyou_Basic_Idle05",
		"default_audio": "res://配音/操作3-稳住节奏（修）.mp3",
		"default_emotion": "smile",
	},
	{
		"action_id": "youyou_Hello_Idle01",
		"scene": "res://待机Animation/youyou_Hello_Idle01.glb",
		"source_anim": "youyou_Hello_Idle01",
		"default_audio": "res://配音/招揽1-小惊喜.mp3",
		"default_emotion": "smile",
	},
	{
		"action_id": "youyou_Hello_Idle02",
		"scene": "res://待机Animation/youyou_Hello_Idle02.glb",
		"source_anim": "youyou_Hello_Idle02",
		"default_audio": "res://配音/招揽4-穿搭.mp3",
		"default_emotion": "mid_smile",
	},
	{
		"action_id": "youyou_Hello_Idle03",
		"scene": "res://待机Animation/youyou_Hello_Idle03.glb",
		"source_anim": "youyou_Hello_Idle03",
		"default_audio": "res://配音/招揽7-有意思的事.mp3",
		"default_emotion": "laugh",
	},
	{
		"action_id": "youyou_Hello_Idle05",
		"scene": "res://待机Animation/youyou_Hello_Idle05.glb",
		"source_anim": "youyou_Hello_Idle05",
		"default_audio": "res://配音/招揽3-心跳加速.mp3",
		"default_emotion": "smug_smile",
	},
	{
		"action_id": "youyou_Hello_Idle06",
		"scene": "res://待机Animation/youyou_Hello_Idle06.glb",
		"source_anim": "youyou_Hello_Idle06",
		"default_audio": "res://配音/招揽9-诶诶诶.mp3",
		"default_emotion": "surprise",
	},
	{
		"action_id": "youyou_Hello_Idle07",
		"scene": "res://待机Animation/youyou_Hello_Idle07.glb",
		"source_anim": "youyou_Hello_Idle07",
		"default_audio": "res://配音/招揽8-大胆上手抓.mp3",
		"default_emotion": "laugh",
	},
	{
		"action_id": "youyou_Hello_Idle08",
		"scene": "res://待机Animation/youyou_Hello_Idle08.glb",
		"source_anim": "youyou_Hello_Idle08",
		"default_audio": "res://配音/招揽6-摇杆左右扭.mp3",
		"default_emotion": "mid_smile",
	},
]

const CLIP_ALIASES: Dictionary = {
	"youyou_Basic_Idle01": {
		"scene": "res://待机Animation/youyou_Basic_Idle01.001.glb",
		"source": "youyou_Basic_Idle01_001",
	},
}

var _host: Node
var _player: AnimationPlayer
var _idle_anim := "Basic_Idle"
var _face: FacePresenter
var _event_catalog = DefaultEventCatalog
var _include_approved_catalog := true
var _audio: AudioStreamPlayer
var _viseme_driver: VisemeDriver

var _session_gen := 0
var _phase := Phase.STOPPED
var _action_id := ""
var _clip_total := 0.0
var _loaded_clips: Dictionary = {}

var _pre_idle_duration := DEFAULT_PRE_POST_IDLE
var _post_idle_duration := DEFAULT_PRE_POST_IDLE
var _main_action_duration := 0.0
var _main_end_time := 0.0
var _window_start := 0.0
var _window_end := -1.0
var _active_start := 0.0
var _active_end := 0.0

var _audio_path := ""
var _play_blend := -1.0
var _keep_pose := false
var _pose_kept := false
var _audio_source_duration := 0.0
var _audio_start_offset := DEFAULT_PRE_POST_IDLE
var _audio_speed := 1.0
var _action_speed := 1.0
var _audio_started := false
var _audio_finished := false

var _target_emotion := "laugh"
var _emotion_lead_time := 0.35
var _emotion_blend_duration := 0.40
var _mouth_release_duration := 0.15
var _idle_return_duration := 0.50
var _base_idle_emotion := FacePresenter.NEUTRAL_EMOTION_ID

var _emotion_scheduled := false
var _emotion_applied := false
var _idle_return_started := false

var _manual_acceptance_status := "draft"
var _notes := ""
var _resource_kind := RESOURCE_KIND_APPROVED
var _category := ""
var _package_finish_emitted := false
var _split_player: SplitTimelinePlayer
var _direct_viseme: DirectVisemePlayer
var _mouth_emotion_weight := FacePresenter.APPROVED_MOUTH_EMOTION_COEF
var _viseme_weight := FacePresenter.APPROVED_VISEME_COEF
var _external_speech_active := false
var _split_hold_last := false
var _split_expression_action_id := ""

## 动作进入 FINISHED 且（无配音或配音已结束）时发出，供正式场景事件表现层使用。
signal package_finished(session_gen: int, action_id: String)

func setup(
	host: Node,
	anim_player: AnimationPlayer,
	face: FacePresenter,
	idle_anim_name: String,
	event_catalog = null,
	include_approved_catalog: bool = true,
) -> void:
	_host = host
	_player = anim_player
	_face = face
	_idle_anim = idle_anim_name
	_event_catalog = event_catalog if event_catalog != null else DefaultEventCatalog
	_include_approved_catalog = include_approved_catalog
	_audio = AudioStreamPlayer.new()
	_audio.name = "ActionTimelineAudio"
	_audio.volume_db = preload("res://Scripts/audio/claw_scene_audio.gd").VOICE_VOLUME_DB
	add_child(_audio)
	_audio.finished.connect(_on_audio_finished)
	_viseme_driver = VisemeDriver.new()
	_viseme_driver.name = "ActionTimelineVisemeDriver"
	add_child(_viseme_driver)
	_viseme_driver.setup(_face, _audio)
	_viseme_driver.process_priority = 10
	process_priority = -10
	_split_player = SplitTimelinePlayer.new()
	var gaze: Node = host.get_node_or_null("EyeGazeController") if host != null else null
	_direct_viseme = DirectVisemePlayer.new()
	if _face != null:
		_split_player.setup(_face.get_meshes(), gaze)
		_direct_viseme.setup(_face.get_meshes(), _audio)
	_event_catalog.ensure_loaded()
	var first_id := ""
	if _include_approved_catalog and not ACTION_CATALOG.is_empty():
		first_id = String(ACTION_CATALOG[0].get("action_id", ""))
	elif not _event_catalog.get_entries().is_empty():
		first_id = String(_event_catalog.get_entries()[0].get("action_id", ""))
	if first_id != "":
		select_action(first_id)


func get_approved_catalog() -> Array[Dictionary]:
	return ACTION_CATALOG.duplicate()


func get_event_catalog() -> Array[Dictionary]:
	return _event_catalog.get_entries()


func get_catalog() -> Array[Dictionary]:
	return get_approved_catalog()


func get_action_ids(catalog_filter: String = CATALOG_FILTER_ALL) -> PackedStringArray:
	var ids: PackedStringArray = []
	if _include_approved_catalog and (
		catalog_filter == CATALOG_FILTER_ALL or catalog_filter == CATALOG_FILTER_APPROVED
	):
		for entry in ACTION_CATALOG:
			ids.append(String(entry.get("action_id", "")))
	if catalog_filter == CATALOG_FILTER_ALL or catalog_filter == CATALOG_FILTER_EVENT:
		for entry in _event_catalog.get_entries():
			ids.append(String(entry.get("action_id", "")))
	return ids


func get_resource_kind(action_id: String) -> String:
	if find_catalog_entry(action_id) != {}:
		return RESOURCE_KIND_APPROVED
	if _event_catalog.find_entry(action_id) != {}:
		return RESOURCE_KIND_EVENT
	return ""


func get_resource_kind_label(action_id: String = "") -> String:
	var aid := action_id if action_id != "" else _action_id
	match get_resource_kind(aid):
		RESOURCE_KIND_APPROVED:
			return "已验收资源（轻待机/招揽调试目录）"
		RESOURCE_KIND_EVENT:
			return "事件测试资源（未入正式池）"
		_:
			return "未知资源"


func find_catalog_entry(action_id: String) -> Dictionary:
	for entry in ACTION_CATALOG:
		if String(entry.get("action_id", "")) == action_id:
			return entry
	return {}


func find_event_entry(action_id: String) -> Dictionary:
	return _event_catalog.find_entry(action_id)


func get_bound_audio_path(action_id: String) -> String:
	if get_resource_kind(action_id) == RESOURCE_KIND_EVENT:
		var event_entry: Dictionary = _event_catalog.find_entry(action_id)
		return String(event_entry.get("default_audio", ""))
	var approved := get_approved_params(action_id)
	if approved.has("audio_path"):
		return String(approved["audio_path"])
	var entry := find_catalog_entry(action_id)
	return String(entry.get("default_audio", ""))


func get_approved_params(action_id: String) -> Dictionary:
	return Approved.get_params(action_id)


func has_approved_preset(action_id: String) -> bool:
	if get_resource_kind(action_id) != RESOURCE_KIND_APPROVED:
		return false
	return bool(Approved.validate_entry(action_id).get("ok", false))


func select_action(action_id: String) -> bool:
	for entry in ACTION_CATALOG:
		if String(entry.get("action_id", "")) == action_id:
			_resource_kind = RESOURCE_KIND_APPROVED
			_category = ""
			_action_id = action_id
			_audio_path = String(entry.get("default_audio", ""))
			_target_emotion = String(entry.get("default_emotion", "smile"))
			_load_action_clip(entry)
			_apply_approved_preset(action_id)
			_probe_audio_duration()
			_recompute_main_duration()
			return true
	var event_entry: Dictionary = _event_catalog.find_entry(action_id)
	if not event_entry.is_empty():
		_resource_kind = RESOURCE_KIND_EVENT
		_category = String(event_entry.get("category", ""))
		_action_id = action_id
		_audio_path = String(event_entry.get("default_audio", ""))
		_target_emotion = String(event_entry.get("default_emotion", "smile"))
		_manual_acceptance_status = String(event_entry.get("manual_acceptance_status", "draft"))
		_notes = String(event_entry.get("notes", ""))
		_apply_event_catalog_preset(event_entry)
		_load_action_clip(event_entry)
		_probe_audio_duration()
		_recompute_main_duration()
		return true
	return false


func _apply_event_debug_defaults() -> void:
	_audio_start_offset = DEFAULT_PRE_POST_IDLE
	_audio_speed = 1.0
	_action_speed = 1.0
	_emotion_lead_time = 0.35
	_emotion_blend_duration = 0.40
	_mouth_release_duration = 0.15
	_idle_return_duration = 0.50
	set_pre_post_idle(DEFAULT_PRE_POST_IDLE, DEFAULT_PRE_POST_IDLE)
	if _face != null:
		_face.set_coefficients(
			FacePresenter.APPROVED_MOUTH_EMOTION_COEF,
			FacePresenter.APPROVED_VISEME_COEF,
			_emotion_blend_duration,
		)
	_viseme_driver.configure_viseme_blend(_mouth_release_duration)


func _apply_event_catalog_preset(entry: Dictionary) -> void:
	_apply_event_debug_defaults()
	if entry.is_empty():
		return
	set_pre_post_idle(
		float(entry.get("pre_idle_duration", _pre_idle_duration)),
		float(entry.get("post_idle_duration", _post_idle_duration)),
	)
	var window_end := -1.0
	if entry.has("playback_end"):
		window_end = float(entry["playback_end"])
	_set_playback_window(float(entry.get("playback_start", 0.0)), window_end)
	var tune := {}
	if entry.has("audio_start_offset"):
		tune["audio_start_offset"] = entry["audio_start_offset"]
	if entry.has("audio_speed"):
		tune["audio_speed"] = entry["audio_speed"]
	if entry.has("action_speed"):
		tune["action_speed"] = entry["action_speed"]
	if entry.has("default_emotion"):
		tune["emotion_id"] = entry["default_emotion"]
	if entry.has("emotion_lead_time"):
		tune["emotion_lead_time"] = entry["emotion_lead_time"]
	if entry.has("emotion_blend_duration"):
		tune["emotion_blend_duration"] = entry["emotion_blend_duration"]
	if entry.has("mouth_release_duration"):
		tune["mouth_release_duration"] = entry["mouth_release_duration"]
	if entry.has("idle_expression_return_duration"):
		tune["idle_expression_return_duration"] = entry["idle_expression_return_duration"]
	if entry.has("mouth_emotion_weight") and entry.has("viseme_weight"):
		tune["mouth_emotion_weight"] = entry["mouth_emotion_weight"]
		tune["viseme_weight"] = entry["viseme_weight"]
	if entry.has("manual_acceptance_status"):
		tune["manual_acceptance_status"] = entry["manual_acceptance_status"]
	if entry.has("notes"):
		tune["notes"] = entry["notes"]
	if not tune.is_empty():
		set_timeline_params(tune)


func _apply_approved_preset(action_id: String) -> void:
	_set_playback_window(0.0, -1.0)
	var preset := Approved.get_params(action_id)
	if preset.is_empty():
		return
	if preset.has("audio_path"):
		_audio_path = String(preset["audio_path"])
	set_pre_post_idle(
		float(preset.get("pre_idle_duration", _pre_idle_duration)),
		float(preset.get("post_idle_duration", _post_idle_duration)),
	)
	var tune := preset.duplicate()
	tune.erase("pre_idle_duration")
	tune.erase("post_idle_duration")
	set_timeline_params(tune)


func set_audio_resource(path: String) -> void:
	_audio_path = path
	_probe_audio_duration()


func set_pre_post_idle(pre: float, post: float) -> void:
	_pre_idle_duration = maxf(pre, 0.0)
	_post_idle_duration = maxf(post, 0.0)
	_recompute_main_duration()


func _set_playback_window(start: float, end: float) -> void:
	_window_start = maxf(start, 0.0)
	_window_end = end


func get_playback_window() -> Vector2:
	var end := _clip_total if _window_end < 0.0 else minf(_window_end, _clip_total)
	var start := clampf(_window_start, 0.0, maxf(end, 0.0))
	return Vector2(start, end)


func _playback_window_for_play() -> Vector2:
	var window := get_playback_window()
	if _event_catalog.has_method("forces_full_clip_playback"):
		if _event_catalog.forces_full_clip_playback(_action_id):
			var entry: Dictionary = _event_catalog.find_entry(_action_id)
			var start := window.x
			if not entry.is_empty():
				start = maxf(float(entry.get("playback_start", start)), 0.0)
			return Vector2(start, _clip_total)
	return window


func _playback_end_limit_for_process() -> float:
	if _event_catalog.has_method("forces_full_clip_playback"):
		if _event_catalog.forces_full_clip_playback(_action_id):
			return _clip_total
	return _active_end if _active_end > 0.0 else _clip_total


func set_main_action_duration(seconds: float) -> void:
	if seconds > 0.0:
		_main_action_duration = seconds
		_main_end_time = _pre_idle_duration + _main_action_duration
	else:
		_recompute_main_duration()


func set_timeline_params(params: Dictionary) -> void:
	if params.has("audio_start_offset"):
		_audio_start_offset = maxf(float(params["audio_start_offset"]), 0.0)
	if params.has("audio_speed"):
		_audio_speed = clampf(float(params["audio_speed"]), 0.5, 2.0)
	if params.has("action_speed"):
		_action_speed = clampf(float(params["action_speed"]), 0.5, 2.0)
		_apply_action_playback_speed()
	if params.has("emotion_id"):
		_target_emotion = String(params["emotion_id"])
	if params.has("emotion_lead_time"):
		_emotion_lead_time = maxf(float(params["emotion_lead_time"]), 0.0)
	if params.has("emotion_blend_duration"):
		_emotion_blend_duration = maxf(float(params["emotion_blend_duration"]), 0.0)
	if params.has("mouth_release_duration"):
		_mouth_release_duration = maxf(float(params["mouth_release_duration"]), 0.0)
	if params.has("idle_expression_return_duration"):
		_idle_return_duration = maxf(float(params["idle_expression_return_duration"]), 0.0)
	if params.has("manual_acceptance_status"):
		_manual_acceptance_status = String(params["manual_acceptance_status"])
	if params.has("notes"):
		_notes = String(params["notes"])
	if params.has("playback_start") or params.has("playback_end"):
		var end_v := float(params["playback_end"]) if params.has("playback_end") else _window_end
		_set_playback_window(float(params.get("playback_start", _window_start)), end_v)
		_recompute_main_duration()
	if params.has("mouth_emotion_weight"):
		_mouth_emotion_weight = clampf(float(params["mouth_emotion_weight"]), 0.0, 1.0)
	if params.has("viseme_weight"):
		_viseme_weight = clampf(float(params["viseme_weight"]), 0.0, 1.0)
	if _face != null and params.has("mouth_emotion_weight") and params.has("viseme_weight"):
		var blend := float(params.get("emotion_blend_duration", _face.get_coefficients().z))
		_face.set_coefficients(
			float(params["mouth_emotion_weight"]),
			float(params["viseme_weight"]),
			blend,
		)
	_viseme_driver.configure_viseme_blend(_mouth_release_duration)


func get_timeline_params() -> Dictionary:
	var coef := Vector3.ZERO
	if _face != null:
		coef = _face.get_coefficients()
	return {
		"action_id": _action_id,
		"resource_kind": _resource_kind,
		"category": _category,
		"audio_id": _audio_path.get_file().get_basename() if _audio_path != "" else "",
		"audio_path": _audio_path,
		"pre_idle_duration": _pre_idle_duration,
		"main_action_duration": _main_action_duration,
		"post_idle_duration": _post_idle_duration,
		"playback_start": _window_start,
		"playback_end": _window_end,
		"clip_total_duration": _clip_total,
		"audio_start_offset": _audio_start_offset,
		"audio_speed": _audio_speed,
		"action_speed": _action_speed,
		"emotion_id": _target_emotion,
		"emotion_lead_time": _emotion_lead_time,
		"emotion_blend_duration": _emotion_blend_duration,
		"mouth_emotion_weight": coef.x,
		"viseme_weight": coef.y,
		"mouth_release_duration": _mouth_release_duration,
		"idle_expression_return_duration": _idle_return_duration,
		"manual_acceptance_status": _manual_acceptance_status,
		"notes": _notes,
	}


func play_voice_with_viseme() -> void:
	if _audio_path == "":
		push_warning("未选择配音：请在下拉框中选择 res://配音 下的 mp3")
		return
	stop(false)
	_session_gen += 1
	var gen := _session_gen
	_reset_flags()
	_start_audio(gen)


func set_play_blend(blend: float) -> void:
	_play_blend = blend


func set_keep_pose(keep: bool) -> void:
	_keep_pose = keep


func play() -> void:
	if _player == null or _action_id == "":
		return
	var blend := _play_blend
	var keep := _keep_pose
	_play_blend = -1.0
	_keep_pose = false
	stop(false)
	_pose_kept = keep
	_session_gen += 1
	var gen := _session_gen
	_reset_flags()
	if not _player.has_animation(_action_id):
		push_error("动作 clip 未加载：" + _action_id)
		return
	_player.speed_scale = _action_speed
	var window := _playback_window_for_play()
	_active_start = window.x
	_active_end = window.y
	var trimmed := _active_start > 0.001 or (_clip_total > 0.0 and _active_end < _clip_total - 0.001)
	if trimmed:
		_player.play_section(_action_id, _active_start, _active_end, blend, 1.0, false)
	else:
		_player.play(_action_id, blend, 1.0, false)
	_phase = Phase.PRE_IDLE
	if _face != null:
		_face.set_split_expression_override(SplitTimelines.has_timeline(_action_id))
	_schedule_async(gen)


func replay() -> void:
	play()


func stop(invalidate: bool = true) -> void:
	if invalidate:
		_session_gen += 1
	_end_split_timeline_face(false)
	_stop_audio_and_viseme()
	if _player != null and _player.is_playing() and _player.current_animation == _action_id:
		_player.stop()
	if _player != null:
		_player.speed_scale = 1.0
	_phase = Phase.STOPPED
	_reset_flags()


func disarm_keep_pose() -> void:
	_session_gen += 1
	_stop_audio_and_viseme()
	_phase = Phase.STOPPED
	_reset_flags()


## 释放身体控制权，但保留正在播放的台词/口型（WASD 盯爪时切操作循环）。
func keep_audio_release_body() -> void:
	_session_gen += 1
	_phase = Phase.STOPPED
	_reset_flags()
	_pose_kept = false


func set_split_expression_action_id(action_id: String) -> void:
	_split_expression_action_id = action_id


func get_split_expression_action_id() -> String:
	return _split_expression_action_id


func _split_timeline_action_id() -> String:
	if _split_expression_action_id != "":
		return _split_expression_action_id
	return _action_id


## 身体由外部循环播放时，继续按当前 clip 时间写 split 表情槽。
func arm_split_loop(action_id: String = "", hold_last: bool = false) -> void:
	if action_id != "" and action_id != _action_id:
		select_action(action_id)
	if _action_id == "" or not SplitTimelines.has_timeline(_split_timeline_action_id()):
		return
	_phase = Phase.MAIN
	_active_start = 0.0
	_split_hold_last = hold_last
	_pose_kept = hold_last
	if _face != null:
		_face.set_split_expression_override(true)


## 操作循环随机配音：分轨表情挡 FacePresenter 口型，改走 mesh 直写 AEO。
func start_external_speech_viseme(player: AudioStreamPlayer) -> bool:
	if player == null or _action_id == "" or not SplitTimelines.has_timeline(_action_id):
		return false
	if _direct_viseme == null or _face == null:
		return false
	_external_speech_active = true
	_face.set_split_expression_override(true)
	_direct_viseme.setup(_face.get_meshes(), player)
	_direct_viseme.set_viseme_coef(_viseme_weight)
	_direct_viseme.start()
	return true


func stop_external_speech_viseme() -> void:
	_external_speech_active = false
	if _direct_viseme != null:
		_direct_viseme.stop()
		_bind_direct_viseme_to_timeline_audio()


func is_external_speech_viseme_active() -> bool:
	return _external_speech_active and _direct_viseme != null and _direct_viseme.is_active()


func get_phase() -> Phase:
	return _phase


func get_phase_label() -> String:
	match _phase:
		Phase.PRE_IDLE:
			return "前置待机"
		Phase.MAIN:
			return "主动作"
		Phase.POST:
			return "后置待机"
		Phase.FINISHED:
			return "已结束"
		_:
			return "已停止"


func get_anim_time() -> float:
	if _player == null:
		return 0.0
	if _player.current_animation != _action_id:
		return 0.0
	return _player.current_animation_position


func get_main_remaining() -> float:
	return maxf(_main_end_time - get_anim_time(), 0.0)


func get_audio_path() -> String:
	return _audio_path


func get_audio_playback_time() -> float:
	if _audio == null or not _audio.playing:
		return 0.0
	return _audio.get_playback_position()


func get_audio_effective_duration() -> float:
	if _audio_source_duration <= 0.0:
		return 0.0
	return _audio_source_duration / maxf(_audio_speed, 0.01)


func get_audio_remaining() -> float:
	return maxf(get_audio_effective_duration() - get_audio_playback_time(), 0.0)


func get_clip_total_duration() -> float:
	return _clip_total


func get_main_action_duration_value() -> float:
	return _main_action_duration


func get_audio_source_duration() -> float:
	return _audio_source_duration


func build_status_lines() -> PackedStringArray:
	var lines: PackedStringArray = []
	lines.append("资源: %s | 分类: %s | 验收: %s" % [
		get_resource_kind_label(),
		_category if _category != "" else "—",
		_manual_acceptance_status,
	])
	if _resource_kind == RESOURCE_KIND_EVENT and _audio_path == "":
		lines.append("配音: 未绑定（事件资源仅动作/兼容性调试，不代表口型组合已验收）")
	lines.append(
		"阶段: %s | 动作 t=%.2fs / 总长 %.2fs | 主动作 %.2fs 剩 %.2fs | 动作速率 ×%.2f"
		% [
			get_phase_label(),
			get_anim_time(),
			_clip_total,
			_main_action_duration,
			get_main_remaining(),
			_action_speed,
		]
	)
	if not (_resource_kind == RESOURCE_KIND_EVENT and _audio_path == ""):
		lines.append(
			"配音: 原长 %.2fs ×%.2f → 实际 %.2fs | 播放 %.2fs 剩 %.2fs | 偏移 %.2fs | %s"
			% [
				_audio_source_duration,
				_audio_speed,
				get_audio_effective_duration(),
				get_audio_playback_time(),
				get_audio_remaining(),
				_audio_start_offset,
				"播放中" if _audio.playing else ("已播完" if _audio_finished else "未启动"),
			]
		)
	var emo_state := "未触发"
	if _emotion_applied:
		emo_state = "已到目标"
	elif _emotion_scheduled:
		emo_state = "渐变中/已排程"
	lines.append(
		"目标情绪: %s | 表情 %s | 提前 %.2fs 渐变 %.2fs"
		% [_target_emotion, emo_state, _emotion_lead_time, _emotion_blend_duration]
	)
	if _face != null:
		lines.append(
			"口型: %s | 嘴情 %.2f 口型系数 %.2f | 口型退出 %.2fs"
			% [
				_face.get_active_viseme() if _face.get_active_viseme() != "" else "—",
				_face.get_coefficients().x,
				_face.get_coefficients().y,
				_mouth_release_duration,
			]
		)
	return lines


func save_params_to_path(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var payload := {
		"schema": "youyou_action_lipsync_tuning_v1",
		"saved_at_utc": Time.get_datetime_string_from_system(true),
		"params": get_timeline_params(),
	}
	file.store_string(JSON.stringify(payload, "\t"))
	return OK


func export_params_json() -> String:
	var payload := {
		"schema": "youyou_action_lipsync_tuning_v1",
		"saved_at_utc": Time.get_datetime_string_from_system(true),
		"params": get_timeline_params(),
	}
	return JSON.stringify(payload, "\t")


func apply_params_from_dict(params: Dictionary) -> void:
	if params.has("action_id"):
		select_action(String(params["action_id"]))
	if params.has("audio_path"):
		set_audio_resource(String(params["audio_path"]))
	elif params.has("audio_id"):
		var aid := String(params["audio_id"])
		if aid != "":
			set_audio_resource("res://配音/%s.mp3" % aid)
	set_pre_post_idle(
		float(params.get("pre_idle_duration", _pre_idle_duration)),
		float(params.get("post_idle_duration", _post_idle_duration)),
	)
	if params.has("main_action_duration"):
		set_main_action_duration(float(params["main_action_duration"]))
	set_timeline_params(params)


func _reset_flags() -> void:
	_emotion_scheduled = false
	_emotion_applied = false
	_audio_started = false
	_audio_finished = false
	_idle_return_started = false
	_package_finish_emitted = false
	_external_speech_active = false
	_split_hold_last = false


func is_audio_finished() -> bool:
	return _audio_finished


func is_audio_playing() -> bool:
	return _audio != null and _audio.playing


func get_current_action_id() -> String:
	return _action_id


func get_session_gen() -> int:
	return _session_gen


func _check_package_finished(gen: int) -> void:
	if gen != _session_gen or _package_finish_emitted or _action_id == "":
		return
	if _phase != Phase.FINISHED:
		return
	if _audio_path != "":
		if _audio_started and (_audio.playing or not _audio_finished):
			return
		if not _audio_started and FileAccess.file_exists(_audio_path) and _audio_source_duration > 0.0:
			return
	_package_finish_emitted = true
	package_finished.emit(gen, _action_id)


func _recompute_main_duration() -> void:
	if _clip_total <= _pre_idle_duration + _post_idle_duration:
		_main_action_duration = maxf(_clip_total - _pre_idle_duration - _post_idle_duration, 0.0)
	else:
		_main_action_duration = _clip_total - _pre_idle_duration - _post_idle_duration
	_main_end_time = _pre_idle_duration + _main_action_duration


func _clip_location(display_name: String) -> Dictionary:
	if CLIP_ALIASES.has(display_name):
		return CLIP_ALIASES[display_name]
	return {"scene": "res://待机Animation/%s.glb" % display_name, "source": display_name}


func probe_action_clip(action_id: String) -> Dictionary:
	var entry := find_catalog_entry(action_id)
	if entry.is_empty():
		entry = _event_catalog.find_entry(action_id)
	if entry.is_empty():
		return {"ok": false, "reason": "未登记 action_id", "action_id": action_id}
	var scene_path := String(entry.get("scene", ""))
	var source_anim := String(entry.get("source_anim", action_id))
	if scene_path == "" and get_resource_kind(action_id) == RESOURCE_KIND_APPROVED:
		var mapped := _clip_location(action_id)
		scene_path = String(mapped.get("scene", ""))
		if source_anim == action_id and CLIP_ALIASES.has(action_id):
			source_anim = String(CLIP_ALIASES[action_id].get("source", action_id))
	var probe: Dictionary = _event_catalog.probe_animation_clip(scene_path, source_anim)
	probe["action_id"] = action_id
	return probe


func _load_action_clip(entry: Dictionary) -> void:
	var action_id := String(entry.get("action_id", ""))
	var scene_path := String(entry.get("scene", ""))
	if scene_path == "":
		var mapped := _clip_location(action_id)
		scene_path = String(mapped.get("scene", ""))
	if scene_path != "":
		var source_anim := String(entry.get("source_anim", action_id))
		if source_anim == action_id and CLIP_ALIASES.has(action_id):
			source_anim = String(CLIP_ALIASES[action_id].get("source", action_id))
		var clip := _take_clip(scene_path, source_anim)
		if clip == null:
			return
		clip.loop_mode = Animation.LOOP_NONE
		_mount_action_clip(action_id, clip)
		return
	if _loaded_clips.has(action_id):
		_clip_total = float(_loaded_clips[action_id])
		return
	if _player != null and _player.has_animation(action_id):
		var embedded := _player.get_animation(action_id)
		_clip_total = embedded.length
		_loaded_clips[action_id] = _clip_total


func _mount_action_clip(action_id: String, clip: Animation) -> void:
	_clip_total = clip.length
	_loaded_clips[action_id] = _clip_total
	if _player == null:
		return
	var lib := _player.get_animation_library("")
	if lib == null:
		lib = AnimationLibrary.new()
		_player.add_animation_library("", lib)
	if lib.has_animation(action_id):
		lib.remove_animation(action_id)
	lib.add_animation(action_id, clip)


func _take_clip(scene_path: String, anim_name: String) -> Animation:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("动画场景加载失败：" + scene_path)
		return null
	var instance := packed.instantiate()
	var source := instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if source == null or not source.has_animation(anim_name):
		instance.free()
		push_error("动画不存在：" + anim_name + " @ " + scene_path)
		return null
	var clip := (source.get_animation(anim_name) as Animation).duplicate(true) as Animation
	instance.free()
	return clip


func _probe_audio_duration() -> void:
	_audio_source_duration = 0.0
	if _audio_path == "" or not FileAccess.file_exists(_audio_path):
		return
	var stream := load(_audio_path) as AudioStream
	if stream == null:
		return
	if stream.has_method("get_length"):
		var len: float = stream.get_length()
		if len > 0.0:
			_audio_source_duration = len


func _wall_delay_for_anim_time(anim_seconds: float) -> float:
	var speed := maxf(_action_speed, 0.01)
	return maxf(anim_seconds, 0.0) / speed


func _apply_action_playback_speed() -> void:
	if _player == null:
		return
	if String(_player.current_animation) != _action_id:
		return
	if _phase == Phase.STOPPED or _phase == Phase.FINISHED:
		return
	_player.speed_scale = _action_speed


func _schedule_async(gen: int) -> void:
	if _host == null:
		return
	if SplitTimelines.has_timeline(_action_id):
		if _face != null:
			_face.set_split_expression_override(true)
		var audio_wall := _wall_delay_for_anim_time(maxf(_audio_start_offset - _active_start, 0.0))
		if audio_wall > 0.0:
			_host.get_tree().create_timer(audio_wall).timeout.connect(
				func() -> void:
					_on_audio_start_timer(gen),
				CONNECT_ONE_SHOT,
			)
		else:
			_on_audio_start_timer(gen)
		return
	var plan := VoiceEmotionSchedules.plan_for(_action_id, _audio_path)
	if not plan.is_empty():
		VoiceEmotionSchedules.arm_cues(
			_host,
			_face,
			gen,
			func(g: int) -> bool:
				return g == _session_gen,
			plan,
			_action_speed,
			_active_start,
		)
		_emotion_scheduled = true
	else:
		var audio_wall := _wall_delay_for_anim_time(maxf(_audio_start_offset - _active_start, 0.0))
		var emotion_wall := maxf(audio_wall - _emotion_lead_time, 0.0)
		if _target_emotion != "" and _emotion_lead_time > 0.001:
			if emotion_wall + 0.0001 < audio_wall:
				if emotion_wall > 0.0:
					_host.get_tree().create_timer(emotion_wall).timeout.connect(
						func() -> void:
							_apply_performance_emotion(gen),
						CONNECT_ONE_SHOT,
					)
				else:
					_apply_performance_emotion(gen)
	var audio_wall := _wall_delay_for_anim_time(maxf(_audio_start_offset - _active_start, 0.0))
	if audio_wall > 0.0:
		_host.get_tree().create_timer(audio_wall).timeout.connect(
			func() -> void:
				_on_audio_start_timer(gen),
			CONNECT_ONE_SHOT,
		)
	else:
		_on_audio_start_timer(gen)


func _apply_performance_emotion(gen: int) -> void:
	if SplitTimelines.has_timeline(_action_id):
		return
	if gen != _session_gen or _face == null or _target_emotion == "":
		return
	if _emotion_applied:
		return
	_emotion_scheduled = true
	_face.configure_performance_blend(_emotion_blend_duration)
	_face.set_emotion(_target_emotion, _emotion_blend_duration)
	_emotion_applied = true


func _release_performance_emotion(gen: int) -> void:
	if gen != _session_gen or _face == null:
		return
	if SplitTimelines.has_timeline(_action_id):
		return
	if not _emotion_applied:
		return
	var blend := maxf(_mouth_release_duration, _idle_return_duration * 0.5)
	_face.restore_idle_expression(_base_idle_emotion, blend)
	_emotion_applied = false


func _on_audio_start_timer(gen: int) -> void:
	if gen != _session_gen:
		return
	_start_audio(gen)


func _start_audio(gen: int) -> void:
	if gen != _session_gen or _audio_path == "":
		return
	var stream := load(_audio_path) as AudioStream
	if stream == null:
		push_error("配音加载失败：" + _audio_path)
		return
	if not _emotion_applied and not _emotion_scheduled:
		_apply_performance_emotion(gen)
	_audio.stream = stream
	_audio.pitch_scale = _audio_speed
	VoiceSubtitleCatalog.notify_audio(_host, _audio_path)
	_audio.play()
	_audio_started = true
	_external_speech_active = false
	if SplitTimelines.has_timeline(_action_id) and _direct_viseme != null:
		if _face != null:
			_face.set_split_expression_override(true)
		_bind_direct_viseme_to_timeline_audio()
		_direct_viseme.set_viseme_coef(_viseme_weight)
		_direct_viseme.start()
	else:
		_viseme_driver.configure_viseme_blend(_mouth_release_duration)
		_viseme_driver.start()


func _on_audio_finished() -> void:
	var gen := _session_gen
	if not _audio_started:
		return
	_audio_finished = true
	if SplitTimelines.has_timeline(_action_id) and _direct_viseme != null:
		_direct_viseme.stop()
	else:
		_viseme_driver.stop(_mouth_release_duration)
	_release_performance_emotion(gen)
	_check_package_finished(gen)


func _stop_audio_and_viseme() -> void:
	var gen := _session_gen
	if _audio.playing:
		_audio.stop()
	_external_speech_active = false
	if SplitTimelines.has_timeline(_action_id) and _direct_viseme != null:
		_direct_viseme.stop()
		_bind_direct_viseme_to_timeline_audio()
	else:
		_viseme_driver.stop(_mouth_release_duration)
	_release_performance_emotion(gen)


func _process(_delta: float) -> void:
	if SplitTimelines.has_timeline(_action_id) and _direct_viseme != null:
		_direct_viseme.tick()
	if _player == null or _phase == Phase.STOPPED or _phase == Phase.FINISHED:
		return
	var current := String(_player.current_animation)
	var assigned := String(_player.assigned_animation)
	if current != _action_id and assigned != _action_id:
		return
	var t := _player.current_animation_position
	if current != _action_id and t + 0.001 < _active_start:
		return
	var limit := _playback_end_limit_for_process()
	if limit > 0.0 and t >= limit - 0.001:
		if _split_hold_last:
			_hold_split_last_frame(limit)
			return
		_on_action_end()
		return
	if t < _pre_idle_duration:
		_phase = Phase.PRE_IDLE
	elif t < _main_end_time:
		_phase = Phase.MAIN
	else:
		_phase = Phase.POST
	_tick_split_expression_timeline(t)


func _on_action_end() -> void:
	if _phase == Phase.FINISHED:
		return
	_phase = Phase.FINISHED
	var gen := _session_gen
	if not _idle_return_started and _face != null:
		_idle_return_started = true
		if SplitTimelines.has_timeline(_action_id):
			if _pose_kept:
				pass
			else:
				_end_split_timeline_face(true, _idle_return_duration)
		elif not _emotion_applied:
			_face.restore_idle_expression(_base_idle_emotion, _idle_return_duration)
	if _player != null:
		_player.speed_scale = 1.0
		if not _pose_kept and _player.has_animation(_idle_anim):
			_player.play(_idle_anim)
		elif _pose_kept and _player.is_playing() and String(_player.current_animation) == _action_id:
			_player.pause()
	_check_package_finished(gen)


func notify_animation_finished(anim_name: StringName) -> void:
	if String(anim_name) != _action_id:
		return
	if _phase != Phase.FINISHED:
		_on_action_end()


func _hold_split_last_frame(limit: float) -> void:
	if _player != null:
		if _player.is_playing():
			_player.pause()
		if limit > 0.0:
			_player.seek(limit, true)
	_phase = Phase.MAIN
	_tick_split_expression_timeline(limit)


func _tick_split_expression_timeline(anim_pos: float) -> void:
	if _split_player == null or not SplitTimelines.has_timeline(_action_id):
		return
	var speed := maxf(_action_speed, 0.01)
	var t := maxf(anim_pos - _active_start, 0.0) / speed
	var expr_id := _split_timeline_action_id()
	t = SplitTimelines.clamp_split_eval_time(expr_id, t)
	if _split_hold_last:
		var hold_end := SplitTimelines.max_expression_end_sec(expr_id)
		if hold_end > 0.0 and t > hold_end:
			t = hold_end
	_split_player.set_mouth_emotion_coef(_mouth_emotion_weight)
	var speech := (_audio != null and _audio.playing) or _external_speech_active
	_split_player.set_viseme_speech_active(speech)
	_split_player.apply_at_time(expr_id, t, true)


func _bind_direct_viseme_to_timeline_audio() -> void:
	if _direct_viseme == null or _face == null:
		return
	_direct_viseme.setup(_face.get_meshes(), _audio)


func _end_split_timeline_face(return_to_idle: bool, return_d: float = 0.5) -> void:
	if _split_player != null:
		_split_player.clear_timeline_layers()
	if _face != null:
		_face.set_split_expression_override(false)
		if return_to_idle:
			_face.restore_idle_expression(_base_idle_emotion, return_d)
	_emotion_applied = false
