extends Node
class_name YouyouApprovedActionPerformance

## 正式场景：已验收动作的配音、口型、表情与动作速率（代际防串台）。

const Approved := preload("res://Scripts/youyou_action_lipsync_approved.gd")
const VoiceSubtitleCatalog := preload("res://Scripts/youyou_voice_subtitle_catalog.gd")
const VoiceEmotionSchedules := preload("res://Scripts/youyou_voice_emotion_schedules.gd")
const FacePresenter := preload("res://Scripts/youyou_face_presenter.gd")
const VisemeDriver := preload("res://Scripts/youyou_test_audio_viseme_driver.gd")
const SplitTimelines := preload("res://Scripts/youyou_action_split_expression_timelines.gd")
const SplitTimelinePlayer := preload("res://Scripts/youyou_split_expression_timeline_player.gd")
const DirectVisemePlayer := preload("res://Scripts/youyou_direct_viseme_mesh_player.gd")

var _host: Node
var _player: AnimationPlayer
var _face: FacePresenter
var _audio: AudioStreamPlayer
var _viseme: VisemeDriver

var _session_gen := 0
var _action_id := ""
var _params: Dictionary = {}
var _base_idle_emotion := FacePresenter.NEUTRAL_EMOTION_ID
var _emotion_applied := false
var _split_timeline_active := false
var _split_player: SplitTimelinePlayer
var _direct_viseme: DirectVisemePlayer


func setup(host: Node, anim_player: AnimationPlayer, face: FacePresenter) -> void:
	_host = host
	_player = anim_player
	_face = face
	_audio = AudioStreamPlayer.new()
	_audio.name = "ApprovedActionAudio"
	_audio.volume_db = preload("res://Scripts/audio/claw_scene_audio.gd").VOICE_VOLUME_DB
	add_child(_audio)
	_audio.finished.connect(_on_audio_finished)
	_viseme = VisemeDriver.new()
	_viseme.name = "ApprovedActionViseme"
	add_child(_viseme)
	_viseme.setup(_face, _audio)
	_viseme.process_priority = 10
	process_priority = -10
	_split_player = SplitTimelinePlayer.new()
	var gaze: Node = host.get_node_or_null("EyeGazeController") if host != null else null
	_direct_viseme = DirectVisemePlayer.new()
	if _face != null:
		_split_player.setup(_face.get_meshes(), gaze)
		_direct_viseme.setup(_face.get_meshes(), _audio)


func get_active_action_id() -> String:
	return _action_id


func start(action_id: String, session_gen: int) -> bool:
	stop(false)
	var check: Dictionary = Approved.validate_for_play(action_id)
	if not bool(check.get("ok", false)):
		for err in check.get("errors", []):
			push_error("已验收动作无效 %s: %s" % [action_id, str(err)])
		return false
	_params = check.get("params", {}) as Dictionary
	_action_id = action_id
	_session_gen = session_gen
	_emotion_applied = false
	_split_timeline_active = SplitTimelines.has_timeline(action_id)
	if _face != null:
		_face.set_split_expression_override(_split_timeline_active)
	_apply_face_coefficients()
	var speed := float(_params.get("action_speed", 1.0))
	if _player != null and String(_player.assigned_animation) == action_id:
		_player.speed_scale = speed
	_schedule(action_id, session_gen)
	return true


func stop(invalidate: bool = true) -> void:
	if invalidate:
		_session_gen += 1
	var was_split := _split_timeline_active
	_end_split_timeline_face(false)
	if _audio.playing:
		_audio.stop()
	var release := float(_params.get("mouth_release_duration", 0.15))
	if _viseme != null:
		_viseme.stop(release)
	if _direct_viseme != null:
		_direct_viseme.stop()
	_action_id = ""
	_params = {}
	_split_timeline_active = false
	if was_split and _host != null and _host.has_method("_pop_split_idle_life_suppression"):
		_host.call("_pop_split_idle_life_suppression")
	if _player != null:
		_player.speed_scale = 1.0


func on_action_animation_finished(action_id: String, session_gen: int) -> void:
	if action_id != _action_id or session_gen != _session_gen:
		return
	var return_d := float(_params.get("idle_expression_return_duration", 0.5))
	_end_split_timeline_face(true, return_d)
	stop(false)


func _apply_face_coefficients() -> void:
	if _face == null:
		return
	_face.set_coefficients(
		float(_params.get("mouth_emotion_weight", FacePresenter.APPROVED_MOUTH_EMOTION_COEF)),
		float(_params.get("viseme_weight", FacePresenter.APPROVED_VISEME_COEF)),
		float(_params.get("emotion_blend_duration", FacePresenter.APPROVED_BLEND_TIME)),
	)
	_viseme.configure_viseme_blend(float(_params.get("mouth_release_duration", 0.15)))


func _wall_delay(anim_seconds: float) -> float:
	var speed := maxf(float(_params.get("action_speed", 1.0)), 0.01)
	return maxf(anim_seconds, 0.0) / speed


func _process(_delta: float) -> void:
	if not _split_timeline_active or _action_id == "" or _split_player == null:
		return
	if _direct_viseme != null:
		_direct_viseme.tick()
	if _player == null:
		return
	var cur := String(_player.current_animation)
	var assigned := String(_player.assigned_animation)
	if cur != _action_id and assigned != _action_id:
		return
	var speed := maxf(float(_params.get("action_speed", 1.0)), 0.01)
	var t := _player.current_animation_position / speed
	_split_player.set_mouth_emotion_coef(float(_params.get("mouth_emotion_weight", FacePresenter.APPROVED_MOUTH_EMOTION_COEF)))
	var speech := _audio != null and _audio.playing
	_split_player.set_viseme_speech_active(speech)
	_split_player.apply_at_time(_action_id, t, true)


func _schedule(action_id: String, gen: int) -> void:
	if _host == null:
		return
	var audio_path := String(_params.get("audio_path", ""))
	if _split_timeline_active:
		_schedule_split_audio_only(action_id, gen, audio_path)
		return
	var plan := VoiceEmotionSchedules.plan_for(action_id, audio_path)
	if plan.is_empty():
		var legacy: Variant = _params.get("emotion_schedule", [])
		if legacy is Array and not (legacy as Array).is_empty():
			plan = {
				"emotion_id": String(_params.get("emotion_id", "smile")),
				"emotion_blend_duration": float(_params.get("emotion_blend_duration", 0.4)),
				"time_base": "action",
				"schedule": legacy,
			}
	if not plan.is_empty():
		_schedule_emotion_plan(action_id, gen, plan)
	elif audio_path == "":
		var emo_start := maxf(float(_params.get("emotion_start_offset", 0.0)), 0.0)
		var emo_wall := _wall_delay(emo_start)
		if emo_wall > 0.0:
			_host.get_tree().create_timer(emo_wall).timeout.connect(
				func() -> void:
					_on_emotion(gen, action_id),
				CONNECT_ONE_SHOT,
			)
		else:
			_on_emotion(gen, action_id)
	else:
		var offset := float(_params.get("audio_start_offset", 1.667))
		var lead := maxf(float(_params.get("emotion_lead_time", 0.0)), 0.0)
		var audio_at := _wall_delay(offset)
		var emotion_at := maxf(audio_at - lead, 0.0)
		if lead > 0.001 and emotion_at + 0.0001 < audio_at:
			if emotion_at > 0.0:
				_host.get_tree().create_timer(emotion_at).timeout.connect(
					func() -> void:
						_on_emotion(gen, action_id),
					CONNECT_ONE_SHOT,
				)
			else:
				_on_emotion(gen, action_id)
		elif lead <= 0.001 and audio_at > 0.0:
			_host.get_tree().create_timer(emotion_at).timeout.connect(
				func() -> void:
					_on_emotion(gen, action_id),
				CONNECT_ONE_SHOT,
			)
		if audio_at > 0.0:
			_host.get_tree().create_timer(audio_at).timeout.connect(
				func() -> void:
					_on_audio(gen, action_id),
				CONNECT_ONE_SHOT,
			)
		else:
			_on_audio(gen, action_id)


func _schedule_split_audio_only(action_id: String, gen: int, audio_path: String) -> void:
	if audio_path == "":
		return
	var offset := float(_params.get("audio_start_offset", 1.667))
	var audio_at := _wall_delay(offset)
	if audio_at > 0.0:
		_host.get_tree().create_timer(audio_at).timeout.connect(
			func() -> void:
				_on_audio(gen, action_id),
			CONNECT_ONE_SHOT,
		)
	else:
		_on_audio(gen, action_id)


func _schedule_emotion_plan(action_id: String, gen: int, plan: Dictionary) -> void:
	VoiceEmotionSchedules.arm_cues(
		_host,
		_face,
		gen,
		func(g: int) -> bool:
			return g == _session_gen and action_id == _action_id,
		plan,
		float(_params.get("action_speed", 1.0)),
		0.0,
	)
	var offset := float(_params.get("audio_start_offset", 1.667))
	var audio_at := _wall_delay(offset)
	if audio_at > 0.0:
		_host.get_tree().create_timer(audio_at).timeout.connect(
			func() -> void:
				_on_audio(gen, action_id),
			CONNECT_ONE_SHOT,
		)
	else:
		_on_audio(gen, action_id)


func _apply_emotion_cue(gen: int, action_id: String, emo: String, blend: float) -> void:
	if gen != _session_gen or action_id != _action_id or _face == null:
		return
	_face.configure_performance_blend(blend)
	_face.set_emotion(emo, blend)
	_emotion_applied = true


func _on_emotion(gen: int, action_id: String) -> void:
	if gen != _session_gen or action_id != _action_id or _face == null:
		return
	if _emotion_applied:
		return
	var emo := String(_params.get("emotion_id", "smile"))
	var blend := float(_params.get("emotion_blend_duration", 0.4))
	_apply_emotion_cue(gen, action_id, emo, blend)


func _on_audio(gen: int, action_id: String) -> void:
	if gen != _session_gen or action_id != _action_id:
		return
	var path := String(_params.get("audio_path", ""))
	if path == "":
		if not _emotion_applied:
			_on_emotion(gen, action_id)
		return
	var stream := load(path) as AudioStream
	if stream == null:
		push_error("配音加载失败：" + path)
		return
	if not _split_timeline_active and not _emotion_applied and VoiceEmotionSchedules.plan_for(action_id, path).is_empty():
		_on_emotion(gen, action_id)
	_audio.stream = stream
	_audio.pitch_scale = float(_params.get("audio_speed", 1.0))
	VoiceSubtitleCatalog.notify_audio(_host, path)
	_audio.play()
	if _split_timeline_active and _direct_viseme != null:
		_direct_viseme.set_viseme_coef(float(_params.get("viseme_weight", FacePresenter.APPROVED_VISEME_COEF)))
		_direct_viseme.start()
	else:
		_viseme.start()


func _on_audio_finished() -> void:
	var release := float(_params.get("mouth_release_duration", 0.15))
	var return_d := float(_params.get("idle_expression_return_duration", 0.5))
	if _split_timeline_active and _direct_viseme != null:
		_direct_viseme.stop()
	else:
		_viseme.stop(release)
	if _split_timeline_active:
		return
	if _face != null:
		_face.restore_idle_expression(_base_idle_emotion, return_d)


func _end_split_timeline_face(return_to_idle: bool, return_d: float = 0.5) -> void:
	if _split_player != null:
		_split_player.clear_timeline_layers()
	if _face != null:
		_face.set_split_expression_override(false)
		if return_to_idle:
			_face.restore_idle_expression(_base_idle_emotion, return_d)
