extends RefCounted
class_name YouyouVoiceEmotionSchedules

## 动作 / 配音文件名 → 多段表情排程（time_base: action=动作轴秒，voice=开口后秒）。

const CONFIG_PATH := "res://config/youyou_voice_emotion_schedules.json"
const FacePresenter := preload("res://Scripts/youyou_face_presenter.gd")
const SplitTimelines := preload("res://Scripts/youyou_action_split_expression_timelines.gd")

static var _by_action: Dictionary = {}
static var _by_filename: Dictionary = {}
static var _loaded := false


static func plan_for(action_id: String, audio_path: String) -> Dictionary:
	if SplitTimelines.has_timeline(action_id):
		return {}
	_ensure_loaded()
	var merged: Dictionary = {}
	if action_id != "" and _by_action.has(action_id):
		merged = (_by_action[action_id] as Dictionary).duplicate(true)
	var file_key := audio_path.get_file()
	if file_key != "" and _by_filename.has(file_key):
		var file_plan: Dictionary = (_by_filename[file_key] as Dictionary).duplicate(true)
		for k in file_plan.keys():
			merged[k] = file_plan[k]
	if merged.is_empty():
		return {}
	if not merged.has("schedule"):
		return {}
	var sched: Variant = merged.get("schedule", [])
	if sched is not Array or (sched as Array).is_empty():
		return {}
	return merged


static func arm_cues(
	host: Node,
	face: FacePresenter,
	session_gen: int,
	is_still_valid: Callable,
	plan: Dictionary,
	action_speed: float = 1.0,
	playback_window_start: float = 0.0,
) -> void:
	if host == null or face == null or plan.is_empty():
		return
	var schedule: Array = plan.get("schedule", []) as Array
	if schedule.is_empty():
		return
	var default_blend := float(plan.get("emotion_blend_duration", 0.4))
	var time_base := String(plan.get("time_base", "action"))
	var speed := maxf(action_speed, 0.01)
	var voice_anchor := float(plan.get("voice_anchor_action_time", -1.0))
	for cue: Variant in schedule:
		if cue is not Dictionary:
			continue
		var emo := String((cue as Dictionary).get("emotion_id", ""))
		if emo == "":
			continue
		var t := maxf(float((cue as Dictionary).get("time", 0.0)), 0.0)
		var blend := float((cue as Dictionary).get("blend_duration", default_blend))
		var wall := 0.0
		if time_base == "voice":
			if voice_anchor >= 0.0:
				wall = maxf(voice_anchor - playback_window_start, 0.0) / speed + t
			else:
				wall = t
		else:
			wall = maxf(t - playback_window_start, 0.0) / speed
		if wall > 0.0:
			host.get_tree().create_timer(wall).timeout.connect(
				func() -> void:
					if not is_still_valid.call(session_gen):
						return
					_apply_cue(face, emo, blend),
				CONNECT_ONE_SHOT,
			)
		else:
			if is_still_valid.call(session_gen):
				_apply_cue(face, emo, blend)


static func apply_root_emotion(face: FacePresenter, plan: Dictionary) -> void:
	if face == null or plan.is_empty():
		return
	var emo := String(plan.get("emotion_id", ""))
	if emo == "":
		return
	var blend := float(plan.get("emotion_blend_duration", 0.4))
	_apply_cue(face, emo, blend)


static func _apply_cue(face: FacePresenter, emo: String, blend: float) -> void:
	face.configure_performance_blend(blend)
	face.set_emotion(emo, blend)


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_by_action = {}
	_by_filename = {}
	if not FileAccess.file_exists(CONFIG_PATH):
		push_warning("表情排程表缺失：" + CONFIG_PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not (parsed is Dictionary):
		push_warning("表情排程 JSON 无效")
		return
	var raw_action: Variant = (parsed as Dictionary).get("by_action_id", {})
	if raw_action is Dictionary:
		_by_action = raw_action
	var raw_file: Variant = (parsed as Dictionary).get("by_filename", {})
	if raw_file is Dictionary:
		_by_filename = raw_file
