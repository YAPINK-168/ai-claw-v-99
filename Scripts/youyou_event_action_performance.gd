extends Node
class_name YouyouEventActionPerformance

## 正式场景：仅白名单内的事件动作（catalog 参数），复用 Timeline，package 级完成通知。

signal performance_finished(token: int, action_id: String, reason: String)
signal performance_failed(token: int, action_id: String, code: String, message: String)

const Timeline := preload("res://Scripts/youyou_action_lipsync_timeline.gd")
const EventCatalog := preload("res://Scripts/youyou_action_event_catalog.gd")
const FacePresenter := preload("res://Scripts/youyou_face_presenter.gd")

const PREVIEW_EVENT_WHITELIST: PackedStringArray = [
	"youyou_coin01",
	"youyou_coin02",
	"youyou_fail01",
	"youyou_victory01",
	"youyou_claw crane01_01",
	"youyou_claw crane01_02",
	"youyou_claw crane01_03",
	"youyou_claw crane01_04",
	"youyou_claw crane01_05",
	"youyou_claw_crane02_01",
	"youyou_claw_crane02_02",
	"youyou_claw_crane02_03",
	"youyou_claw_crane02_04",
	"youyou_claw_crane02_05",
	"youyou_claw_crane02_06",
	"youyou_claw_crane02_07",
	"youyou_claw_crane03_01",
	"youyou_claw_crane03_02",
	"youyou_claw_crane03_03",
	"youyou_claw_crane03_04",
	"youyou_claw_crane03_05",
	"youyou_claw_crane03_06",
	"youyou_claw_crane03_07",
	"youyou_claw_crane03_08",
	"youyou_victory02",
	"youyou_Speak_Idle05",
]

var _timeline: YouyouActionLipsyncTimeline
var _player: AnimationPlayer
var _play_token := 0
var _active_action_id := ""
var _active := false
var _package_listen_gen := -1

func setup(host: Node, anim_player: AnimationPlayer, face: FacePresenter, idle_anim_name: String) -> void:
	_player = anim_player
	_timeline = Timeline.new()
	_timeline.name = "FormalEventTimeline"
	add_child(_timeline)
	_timeline.setup(host, anim_player, face, idle_anim_name)
	if not _timeline.package_finished.is_connected(_on_package_finished):
		_timeline.package_finished.connect(_on_package_finished)


func is_playing() -> bool:
	return _active


func get_active_action_id() -> String:
	return _active_action_id


func get_timeline() -> YouyouActionLipsyncTimeline:
	return _timeline


func validate_event(action_id: String) -> Dictionary:
	var result := {"ok": false, "action_id": action_id, "errors": PackedStringArray([])}
	if action_id not in PREVIEW_EVENT_WHITELIST:
		result["errors"].append("不在正式场景事件白名单")
		return result
	var entry := EventCatalog.find_entry(action_id)
	if entry.is_empty():
		result["errors"].append("事件 catalog 无条目")
		return result
	var scene_path := String(entry.get("scene", ""))
	var source_anim := String(entry.get("source_anim", action_id))
	var audio_path := String(entry.get("default_audio", ""))
	if not ResExists.path(scene_path):
		result["errors"].append("GLB 不存在：" + scene_path)
	if audio_path != "" and not ResExists.path(audio_path):
		result["errors"].append("配音不存在：" + audio_path)
	var probe := EventCatalog.probe_animation_clip(scene_path, source_anim)
	if not bool(probe.get("ok", false)):
		result["errors"].append(String(probe.get("reason", "动画探测失败")))
	if _player == null:
		result["errors"].append("AnimationPlayer 未绑定")
	elif not _timeline.select_action(action_id):
		result["errors"].append("Timeline 无法选择动作")
	elif not _player.has_animation(action_id):
		result["errors"].append("动画 clip 未接入 AnimationPlayer")
	if not result["errors"].is_empty():
		return result
	result["ok"] = true
	result["scene"] = scene_path
	result["audio"] = audio_path
	result["clip_length"] = probe.get("clip_length", 0.0)
	return result


func play_event(
	action_id: String,
	token: int = 0,
	return_to_idle: bool = true,
	play_bound_audio: bool = true,
	blend: float = -1.0,
	audio_override: String = "",
) -> bool:
	var check := validate_event(action_id)
	if not bool(check.get("ok", false)):
		for err in check.get("errors", []):
			_fail(token, action_id, "validate", String(err))
		return false
	if _active:
		_timeline.stop(true)
		_active = false
		_active_action_id = ""
	_play_token = token
	_active_action_id = action_id
	_active = true
	if not _timeline.select_action(action_id):
		_active = false
		_active_action_id = ""
		_fail(token, action_id, "select_failed", "Timeline select 失败")
		return false
	if _player != null and _player.has_animation(action_id):
		_player.get_animation(action_id).loop_mode = Animation.LOOP_NONE
	_timeline.set_keep_pose(not return_to_idle)
	_timeline.set_play_blend(blend)
	if not play_bound_audio:
		_timeline.set_audio_resource("")
	if audio_override != "":
		_timeline.set_audio_resource(audio_override)
	_timeline.play()
	_package_listen_gen = _timeline.get_session_gen()
	return true


func ensure_body_clip(action_id: String) -> bool:
	if _player != null and _player.has_animation(action_id):
		return true
	if _timeline == null or not _timeline.select_action(action_id):
		return false
	return _player != null and _player.has_animation(action_id)


func release_body_keep_speech() -> void:
	_active = false
	_active_action_id = ""
	_package_listen_gen = -1
	if _timeline != null:
		_timeline.keep_audio_release_body()


func arm_body_clip(action_id: String) -> bool:
	var check := validate_event(action_id)
	if not bool(check.get("ok", false)):
		for err in check.get("errors", []):
			push_warning("身体循环准备失败 %s: %s" % [action_id, String(err)])
		return false
	_active = false
	_active_action_id = ""
	_package_listen_gen = -1
	if _timeline != null:
		_timeline.stop(false)
		_timeline.disarm_keep_pose()
		if not _timeline.select_action(action_id):
			return false
	return _player != null and _player.has_animation(action_id)


func arm_split_loop(action_id: String = "", hold_last: bool = false) -> void:
	if _timeline != null:
		_timeline.arm_split_loop(action_id, hold_last)


func start_external_speech_viseme(player: AudioStreamPlayer) -> bool:
	if _timeline == null:
		return false
	return _timeline.start_external_speech_viseme(player)


func stop_external_speech_viseme() -> void:
	if _timeline != null:
		_timeline.stop_external_speech_viseme()


func is_external_speech_viseme_active() -> bool:
	return _timeline != null and _timeline.is_external_speech_viseme_active()


func stop_event(invalidate: bool = true) -> void:
	if invalidate:
		_active = false
		_active_action_id = ""
		_package_listen_gen = -1
	if _timeline != null:
		_timeline.stop(invalidate)


func notify_animation_finished(anim_name: StringName) -> void:
	if _timeline != null and _active:
		_timeline.notify_animation_finished(anim_name)


func _on_package_finished(session_gen: int, action_id: String) -> void:
	if session_gen != _package_listen_gen:
		return
	if not _active or action_id != _active_action_id:
		return
	_active = false
	_active_action_id = ""
	var token := _play_token
	performance_finished.emit(token, action_id, "package_complete")


func _fail(token: int, action_id: String, code: String, message: String) -> void:
	push_warning("事件表现失败 %s [%s]: %s" % [action_id, code, message])
	performance_failed.emit(token, action_id, code, message)
