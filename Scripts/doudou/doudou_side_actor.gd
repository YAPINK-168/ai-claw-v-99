extends Node3D
class_name DoudouSideActor

## 沙盒兜兜：catalog 中文 action_id + clip 挂载；等结果时停末帧（首局上前嘲讽/续局捣乱末段），不播叉腰待机。

signal entrance_scare_point
signal scripted_tactics_scare_point
signal scripted_tactics_finished

const EventCatalog := preload("res://Scripts/doudou/doudou_action_event_catalog.gd")
const DoudouBodyBreath := preload("res://Scripts/doudou/doudou_body_breath.gd")
const ClawSceneAudio := preload("res://Scripts/audio/claw_scene_audio.gd")
const SplitTimelines := preload("res://Scripts/doudou/doudou_action_split_expression_timelines.gd")
const SplitTimelinePlayer := preload("res://Scripts/doudou/doudou_split_expression_timeline_player.gd")
const DirectVisemePlayer := preload("res://Scripts/doudou/doudou_direct_viseme_mesh_player.gd")
const DoudouFacePresenter := preload("res://Scripts/doudou/doudou_face_presenter.gd")
const DoudouIdleBlink := preload("res://Scripts/doudou/doudou_idle_blink.gd")
const FacePresenter := preload("res://Scripts/youyou_face_presenter.gd")

const MODEL_PATH := "res://doudou2/兜兜.glb"
const DOUDOU_SLOT_PREVIEW_NAME := "DoudouEditorPreview"
const ACTION_ENTRANCE := "入场"
const ACTION_TACTICS := "战术指导"
const ACTION_TAUNT_DANCE := "跳舞嘲讽"
const ACTION_TAUNT_FORWARD := "上前嘲讽"
const ACTION_IDLE_HUB := "叉腰待机"
const ACTION_PLAYER_WIN := "甩手"
const ACTION_PLAYER_LOSE := "抱肚笑"
const ACTION_RUN_OUT := "跑出"
const ACTION_FOLLOWUP_ENTRANCE := "鬼鬼祟祟"
const ACTION_FACE_GRIN := "鬼脸"
const ACTION_SPREAD_WINGS := "大鹏展翅"
const ACTION_BOUNCE := "蹦蹦跳跳"

## 第二局「鬼鬼祟祟」进场结束后按顺序播：大鹏展翅 → 蹦蹦跳跳。
const FOLLOWUP_HARASSMENT_SEQUENCE: PackedStringArray = [
	ACTION_SPREAD_WINGS,
	ACTION_BOUNCE,
]

## 入场剩余该秒数时触发柚柚 crane03_03 被吓到（倒数 4.5s）
const ENTRANCE_SCARE_LEAD_SEC := 4.5
## 战术指导剩余该秒数时触发柚柚 crane03_04 转头（比播完提前 0.5s）
const TACTICS_SCARE_LEAD_SEC := 0.5
const LOCAL_OFFSET := Vector3(0.92, 0.0, 0.78)
## 续局开场：相对 hub 槽位的场外复位，再播「鬼鬼祟祟」根运动回场
const FOLLOWUP_OFFSCENE_LOCAL_OFFSET := Vector3(3.5, 0.0, 2.2)
const HEIGHT_SCALE := 0.82
## 进叉腰：与队列其它 GLB 相同——只 finalize 承接 world 位置，再混合进循环（勿 snap 回槽位）。
const IDLE_HUB_ENTER_BLEND_SEC := 0.28
## 段与段衔接：从当前姿势混到下一段，避免先扳回绑定位。停末帧→甩手/抱肚笑仍硬切。
const POSE_BLEND_SEC := 0.12
const REF_BONE_HINTS: PackedStringArray = [
	"mixamorig:Hips",
	"mixamorig_Hips",
	"mixamorig:LeftFoot",
	"mixamorig:RightFoot",
	"mixamorig_LeftFoot",
	"mixamorig_RightFoot",
	"Root",
	"root",
]

enum RoundPhase {
	OFF,
	INTRO_ENTRANCE,
	INTRO_WAIT,
	INTRO_TACTICS,
	INTRO_WAIT_TAUNT,
	SCRIPTED_QUEUE,
	WAIT_GRAB_RESULT,
	IDLE_HUB,
	OUTCOME,
	RUN_OUT,
	FROZEN,
}

var _anchor: Node3D
var _world_slot: Node3D
var _model: Node3D
var _player: AnimationPlayer
var _audio: AudioStreamPlayer
var _body_breath: DoudouBodyBreath
var _phase := RoundPhase.OFF
var _awaiting_grab_result := false
var _slot_synced_once := false
var _scripted_first_round := false
var _followup_round := false
## 第二局鬼鬼祟祟开播前的世界坐标。第三局起进场前拉回这里，避免跑出末帧一次比一次偏。
var _followup_sneak_anchor_valid := false
var _followup_sneak_anchor_pos := Vector3.ZERO
var _entrance_scare_armed := false
var _entrance_scare_fired := false
var _tactics_scare_armed := false
var _tactics_scare_fired := false
var _scheduled_audio_cues: Array[Dictionary] = []
## 整段配音按口型场：等到 audio_start_offset 再从音频开头播。口型在出声时才启动。
var _pending_voice_action := ""
var _pending_voice_path := ""
var _pending_voice_speed := 1.0
var _pending_voice_offset := 0.0
## 与口型场相同：墙钟等待 (audio_start_offset - playback_start) / action_speed，到点从音频开头播。
var _pending_voice_delay_left := -1.0
var _grab_queued := false
## Ctrl+G 之后结果先到、当前段还没播完：记下成败，段末再播甩手/抱肚笑并跑出。
var _pending_grab_result := false
var _pending_grab_success := false
var _action_queue: Array[String] = []
var _active_action_id := ""
var _clips_loaded := false
var _followup_harassment_pending := false
var _clip_ref_start_world := Vector3.ZERO
var _clip_ref_tracking := false
var _motion_bone_idx := -1
## 续局从跑出末帧衔接下一段时，保留 SideActor 世界坐标，勿再 _finalize。
var _preserve_actor_world_once := false
var _meshes: Array[MeshInstance3D] = []
var _doudou_face: DoudouFacePresenter
var _split_player: SplitTimelinePlayer
var _idle_blink: DoudouIdleBlink
var _direct_viseme: DirectVisemePlayer
var _split_timeline_active := false
var _mouth_emotion_coef := FacePresenter.APPROVED_MOUTH_EMOTION_COEF
var _viseme_coef := DoudouFacePresenter.DOUDOU_VISEME_COEF
var _scripted_queue_finishing := false
## 开下一段时若沿用上一段播放头，短的下一段会被立刻判结束。这段时间忽略误触发的结束信号。
var _suppress_anim_finished := false
## 停末帧切到甩手/抱肚笑后，连补两帧：新动作第 0 帧根骨和停帧不一致，把胯骨拉回停帧落点。
var _result_hold_hip := Vector3.ZERO
var _result_hold_pin_left := 0
var _pose_blend_hip := Vector3.ZERO
var _pose_blend_pin_left := 0.0


func setup(anchor: Node3D) -> void:
	_anchor = anchor
	_world_slot = null
	_boot()
	_sync_initial_placement()
	_set_actor_visible(false)


func setup_from_slot(world_slot: Node3D, anchor_fallback: Node3D = null) -> void:
	_world_slot = world_slot
	_anchor = anchor_fallback
	_boot()
	_sync_initial_placement(true)
	_set_actor_visible(false)


func configure_first_round_scripted(enabled: bool) -> void:
	_scripted_first_round = enabled
	_followup_round = false
	if enabled:
		_followup_sneak_anchor_valid = false
	if not enabled:
		_reset_scare_flags()


func configure_followup_round(enabled: bool) -> void:
	_followup_round = enabled
	_scripted_first_round = false
	_reset_scare_flags()
	if enabled:
		_start_followup_round()


func set_followup_hidden() -> void:
	_phase = RoundPhase.OFF
	_awaiting_grab_result = false
	_grab_queued = false
	_action_queue.clear()
	_reset_scare_flags()
	_clear_scheduled_audio_cues()
	if _audio != null:
		_audio.stop()
	_set_actor_visible(false)
	if _player != null and _player.is_playing():
		_player.stop()


func responds_to_grab_result() -> bool:
	return visible and _phase != RoundPhase.FROZEN and _phase != RoundPhase.OFF


## 沙盒 HUD：当前正在播的 catalog 动作名（中文 action_id）。
func get_playback_action_label() -> String:
	if not visible or _phase == RoundPhase.OFF:
		return "未出场"
	if _active_action_id.is_empty():
		return "—"
	if _phase == RoundPhase.FROZEN or _phase == RoundPhase.WAIT_GRAB_RESULT:
		return "%s（停末帧）" % _active_action_id
	if _player != null and _player.is_playing():
		return _active_action_id
	return "%s（停）" % _active_action_id


## 第二局捣乱：action_id 留空则按顺序播大鹏展翅→蹦蹦跳跳；也可只播指定的一个。
func play_followup_harassment(action_id: String = "") -> bool:
	if not _followup_round or not visible:
		return false
	if _phase == RoundPhase.FROZEN or _phase == RoundPhase.OFF:
		return false
	var ids: Array[String] = []
	var pick := action_id.strip_edges()
	if pick.is_empty():
		ids = _resolved_followup_harassment_sequence()
	else:
		if pick not in FOLLOWUP_HARASSMENT_SEQUENCE:
			return false
		ids = [pick]
	if ids.is_empty():
		return false
	if _phase == RoundPhase.SCRIPTED_QUEUE and (
		not _action_queue.is_empty() or (_active_action_id != "" and _player.is_playing())
	):
		for id in ids:
			_action_queue.append(id)
		return true
	_followup_harassment_pending = false
	_start_action_queue(ids, RoundPhase.SCRIPTED_QUEUE)
	print("[兜兜] 第二局捣乱序列：%s" % ", ".join(ids))
	return true


func _resolved_followup_harassment_sequence() -> Array[String]:
	var out: Array[String] = []
	if _player == null:
		return out
	for id in FOLLOWUP_HARASSMENT_SEQUENCE:
		if _player.has_animation(id):
			out.append(id)
		else:
			push_warning("兜兜捣乱动作未挂载：%s" % id)
	return out


func _reset_scare_flags() -> void:
	_entrance_scare_armed = false
	_entrance_scare_fired = false
	_tactics_scare_armed = false
	_tactics_scare_fired = false


func _boot() -> void:
	EventCatalog.ensure_loaded()
	SplitTimelines.load_config()
	_ensure_model()
	_load_all_catalog_clips()
	process_priority = 50
	set_process(true)


func _process(delta: float) -> void:
	_apply_pose_blend_pin(delta)
	_apply_pending_result_hold_pin()
	_maintain_frozen_run_out_hold()
	_try_fire_entrance_scare_point()
	_try_fire_tactics_scare_point()
	_try_fire_scheduled_audio_cues(delta)
	_poll_scripted_full_clip_playback()
	_tick_doudou_split_face()


func _maintain_frozen_run_out_hold() -> void:
	if _phase != RoundPhase.FROZEN:
		return
	_set_actor_visible(true)
	if _player == null:
		return
	if _player.is_playing():
		_player.pause()
	if _active_action_id != ACTION_RUN_OUT or String(_player.current_animation) != ACTION_RUN_OUT:
		_hold_clip_last_frame(ACTION_RUN_OUT)


func _try_fire_entrance_scare_point() -> void:
	if not _scripted_first_round or not _entrance_scare_armed or _entrance_scare_fired:
		return
	if _active_action_id != ACTION_ENTRANCE:
		return
	if not _is_near_clip_end(ENTRANCE_SCARE_LEAD_SEC):
		return
	_entrance_scare_fired = true
	entrance_scare_point.emit()


func _try_fire_tactics_scare_point() -> void:
	if not _scripted_first_round or not _tactics_scare_armed or _tactics_scare_fired:
		return
	if _active_action_id != ACTION_TACTICS:
		return
	if not _is_near_clip_end(TACTICS_SCARE_LEAD_SEC):
		return
	_tactics_scare_fired = true
	scripted_tactics_scare_point.emit()


func _is_near_clip_end(lead_sec: float) -> bool:
	if _player == null or not _player.is_playing():
		return false
	var len := _player.current_animation_length
	var pos := _player.current_animation_position
	if len <= 0.0:
		return false
	return len - pos <= lead_sec


func _editor_placement_transform() -> Transform3D:
	if _world_slot != null and is_instance_valid(_world_slot):
		var preview := _world_slot.get_node_or_null(DOUDOU_SLOT_PREVIEW_NAME) as Node3D
		if preview != null:
			return preview.global_transform
		return _world_slot.global_transform
	return _hub_world_transform()


func _hub_world_transform() -> Transform3D:
	if _world_slot != null and is_instance_valid(_world_slot):
		var preview := _world_slot.get_node_or_null(DOUDOU_SLOT_PREVIEW_NAME) as Node3D
		if preview != null:
			return preview.global_transform
		return _world_slot.global_transform
	if _anchor != null and is_instance_valid(_anchor):
		var gt := _anchor.global_transform
		var pos := gt.origin + gt.basis * LOCAL_OFFSET
		var yaw := gt.basis.get_euler().y
		return Transform3D(Basis.from_euler(Vector3(0.0, yaw, 0.0)), pos)
	return global_transform


func _sync_initial_placement(force: bool = false) -> void:
	if _slot_synced_once and not force:
		return
	if _world_slot != null and is_instance_valid(_world_slot):
		global_transform = _editor_placement_transform()
	else:
		global_transform = _hub_world_transform()
	_slot_synced_once = true


func _snap_followup_off_scene() -> void:
	_finalize_clip_root_motion()
	var hub := _hub_world_transform()
	global_transform = hub
	global_position += hub.basis * FOLLOWUP_OFFSCENE_LOCAL_OFFSET
	_reset_model_local_transform()
	if _player != null and _player.has_animation(ACTION_RUN_OUT):
		_hold_clip_last_frame(ACTION_RUN_OUT)


func reset_to_layout_slot() -> void:
	_slot_synced_once = false
	_clip_ref_tracking = false
	_motion_bone_idx = -1
	_sync_initial_placement()
	_reset_model_local_transform()
	_phase = RoundPhase.OFF
	_awaiting_grab_result = false
	_grab_queued = false
	_pending_grab_result = false
	_action_queue.clear()
	_result_hold_pin_left = 0
	_pose_blend_pin_left = 0.0
	_followup_sneak_anchor_valid = false
	_reset_scare_flags()
	_clear_scheduled_audio_cues()
	if _audio != null:
		_audio.stop()
	if _player != null and _player.is_playing():
		_player.stop()


func begin_entrance_after_welcome() -> void:
	if _player == null:
		_ensure_model()
		_load_all_catalog_clips()
	if _player == null:
		return
	_sync_initial_placement(true)
	_set_actor_visible(true)
	_awaiting_grab_result = false
	_grab_queued = false
	_pending_grab_result = false
	_action_queue.clear()
	_entrance_scare_armed = true
	_entrance_scare_fired = false
	_play_catalog_once(ACTION_ENTRANCE, RoundPhase.INTRO_ENTRANCE)


func play_scripted_tactics() -> void:
	if not visible:
		return
	_tactics_scare_armed = true
	_tactics_scare_fired = false
	_play_catalog_once(ACTION_TACTICS, RoundPhase.INTRO_TACTICS)


func play_first_round_taunt_sequence() -> void:
	if not visible:
		return
	if (
		_phase == RoundPhase.SCRIPTED_QUEUE
		and (
			_active_action_id == ACTION_TAUNT_DANCE
			or _active_action_id == ACTION_TAUNT_FORWARD
			or _action_queue.has(ACTION_TAUNT_FORWARD)
		)
	):
		return
	_start_action_queue(
		[ACTION_TAUNT_DANCE, ACTION_TAUNT_FORWARD],
		RoundPhase.SCRIPTED_QUEUE,
	)


func notify_grab_down() -> void:
	if not visible or _phase == RoundPhase.FROZEN:
		return
	_grab_queued = true
	if _can_switch_to_grab_watch():
		_enter_grab_watch_idle()
	elif _phase == RoundPhase.INTRO_WAIT or _phase == RoundPhase.INTRO_WAIT_TAUNT:
		if _player == null or not _player.is_playing():
			_enter_grab_watch_idle()


func notify_grab_result(player_success: bool) -> void:
	if not responds_to_grab_result():
		return
	if _phase == RoundPhase.OUTCOME or _phase == RoundPhase.RUN_OUT:
		return
	# 结果在末帧等待或叉腰 hub 接；勿在嘲讽队列中段硬切 OUTCOME。
	var may_play := (
		_awaiting_grab_result
		or _phase == RoundPhase.WAIT_GRAB_RESULT
		or _phase == RoundPhase.IDLE_HUB
	)
	if may_play:
		_play_grab_result_now(player_success)
		return
	if _defer_grab_result_until_clip_ends():
		_grab_queued = true
		_pending_grab_result = true
		_pending_grab_success = player_success
		return
	_play_grab_result_now(player_success)


func _defer_grab_result_until_clip_ends() -> bool:
	if _player != null and _player.is_playing():
		return (
			_phase == RoundPhase.INTRO_ENTRANCE
			or _phase == RoundPhase.INTRO_TACTICS
			or _phase == RoundPhase.SCRIPTED_QUEUE
		)
	return false


func _play_grab_result_now(player_success: bool) -> void:
	_awaiting_grab_result = false
	_grab_queued = false
	_pending_grab_result = false
	_followup_harassment_pending = false
	_action_queue.clear()
	if _phase != RoundPhase.WAIT_GRAB_RESULT and _phase != RoundPhase.IDLE_HUB:
		_phase = RoundPhase.WAIT_GRAB_RESULT
	var action := ACTION_PLAYER_WIN if player_success else ACTION_PLAYER_LOSE
	_play_catalog_once(action, RoundPhase.OUTCOME)


func _consume_grab_after_current_clip() -> bool:
	if _pending_grab_result:
		_play_grab_result_now(_pending_grab_success)
		return true
	if not _grab_queued:
		return false
	_followup_harassment_pending = false
	_action_queue.clear()
	_enter_wait_grab_result_hold(true)
	return true


func _can_switch_to_grab_watch() -> bool:
	return _phase == RoundPhase.IDLE_HUB or _phase == RoundPhase.WAIT_GRAB_RESULT


func _enter_grab_watch_idle() -> void:
	_action_queue.clear()
	_enter_wait_grab_result_hold(true)


## 沙盒：嘲讽/捣乱播完后停末帧等 Ctrl+B，不再切叉腰待机（避免 hub 闪位）。
func _enter_wait_grab_result_hold(await_grab_result: bool = true) -> void:
	var hold_id := _active_action_id
	if hold_id == "" or hold_id == ACTION_IDLE_HUB:
		hold_id = ACTION_TAUNT_FORWARD
	if _player == null or not _player.has_animation(hold_id):
		if _player != null and _player.has_animation(ACTION_TAUNT_FORWARD):
			hold_id = ACTION_TAUNT_FORWARD
		else:
			push_warning("兜兜等待抓取结果：缺少可停帧动作（%s）" % hold_id)
			return
	_set_hub_idle_breath(false)
	_clear_scheduled_audio_cues()
	_phase = RoundPhase.WAIT_GRAB_RESULT
	_awaiting_grab_result = await_grab_result
	_hold_clip_last_frame(hold_id)


func _play_idle_hub_loop(await_grab_result: bool) -> void:
	_set_hub_idle_breath(true)
	_play_catalog_loop(ACTION_IDLE_HUB, RoundPhase.IDLE_HUB)
	_awaiting_grab_result = await_grab_result


func _start_followup_round() -> void:
	if _player == null:
		return
	_set_actor_visible(true)
	_awaiting_grab_result = false
	_grab_queued = false
	_pending_grab_result = false
	_followup_harassment_pending = true
	_clear_scheduled_audio_cues()
	if _audio != null:
		_audio.stop()
	if _phase == RoundPhase.FROZEN:
		# 上一局跑出末帧已在场外，直接接鬼鬼祟祟回场（继承 world 位置）
		_preserve_actor_world_once = true
		_handoff_from_frozen_run_out_hold()
	else:
		_snap_followup_off_scene()
	if not _followup_sneak_anchor_valid:
		_followup_sneak_anchor_pos = global_position
		_followup_sneak_anchor_valid = true
	else:
		global_position = _followup_sneak_anchor_pos
	print(
		"[兜兜] 续局开场 frozen=%s pos=%s 锚点=%s 下一段=%s"
		% [
			str(_phase == RoundPhase.FROZEN),
			global_position,
			_followup_sneak_anchor_pos,
			ACTION_FOLLOWUP_ENTRANCE,
		]
	)
	_start_action_queue([ACTION_FOLLOWUP_ENTRANCE], RoundPhase.SCRIPTED_QUEUE)


func _start_action_queue(ids: Array[String], phase: RoundPhase) -> void:
	_action_queue = ids.duplicate()
	_phase = phase
	_advance_action_queue()


func _advance_action_queue() -> void:
	if _consume_grab_after_current_clip():
		return
	while not _action_queue.is_empty():
		var next_id := _action_queue[0]
		if _player != null and _player.has_animation(next_id):
			_action_queue.remove_at(0)
			_play_catalog_once(next_id, RoundPhase.SCRIPTED_QUEUE)
			return
		_action_queue.remove_at(0)
		push_warning("兜兜跳过缺失动作，继续队列")
	_after_scripted_queue_exhausted()


func _after_scripted_queue_exhausted() -> void:
	if _followup_round and _followup_harassment_pending:
		_followup_harassment_pending = false
		var seq := _resolved_followup_harassment_sequence()
		if not seq.is_empty():
			_start_action_queue(seq, RoundPhase.SCRIPTED_QUEUE)
			print("[兜兜] 第二局捣乱序列：%s" % ", ".join(seq))
			return
	_enter_wait_grab_result_hold(true)


func _is_result_from_hold(action_id: String) -> bool:
	if _phase != RoundPhase.WAIT_GRAB_RESULT:
		return false
	return action_id == ACTION_PLAYER_WIN or action_id == ACTION_PLAYER_LOSE


func _play_catalog_once(action_id: String, phase: RoundPhase) -> void:
	if _player == null or not _player.has_animation(action_id):
		push_error("兜兜缺少动画 clip（检查 catalog / GLB 轨道名）：%s" % action_id)
		return
	if action_id != ACTION_IDLE_HUB:
		_set_hub_idle_breath(false)
	_begin_doudou_face_for_action(action_id)
	var blend_from_hold := _is_result_from_hold(action_id)
	var blend_from_pose := false
	var locked_hip := Vector3.ZERO
	if blend_from_hold:
		# 停帧姿势还在骨骼上：不 reset（避免 T pose），也不做 crossfade（避免脚在两段位置之间滑）。
		# 抱肚笑/甩手第 0 帧胯骨在原点，嘲讽末帧已经走开，播上后把胯骨拉回这个落点。
		locked_hip = _motion_reference_world()
		_clip_ref_tracking = false
		_pose_blend_pin_left = 0.0
		_set_pose_capture(false)
	elif _preserve_actor_world_once:
		# 跑出位移已经记在角色上，只丢掉末帧骨骼，同一帧切到下一段开头。
		_preserve_actor_world_once = false
		_handoff_world_pose_for_next_clip()
		_pose_blend_pin_left = 0.0
		_set_pose_capture(false)
	elif _has_live_body_pose():
		# 上一段姿势还在：记下胯骨，短混进下一段，混的时候把胯骨钉在原地。
		_bake_model_offset_keep_pose()
		locked_hip = _motion_reference_world()
		_pose_blend_hip = locked_hip
		_pose_blend_pin_left = POSE_BLEND_SEC
		_set_pose_capture(true)
		blend_from_pose = true
	else:
		_finalize_clip_root_motion()
		_pose_blend_pin_left = 0.0
		_set_pose_capture(false)
	_phase = phase
	_active_action_id = action_id
	_player.speed_scale = _catalog_action_speed(action_id)
	_start_catalog_anim(action_id, false, 0.0, not blend_from_pose)
	_set_pose_capture(false)
	if blend_from_hold:
		var window := _flow_playback_window(action_id)
		_player.seek(window.x, true)
		_pin_motion_reference_world(locked_hip)
		_clip_ref_start_world = locked_hip
		_clip_ref_tracking = true
		_result_hold_hip = locked_hip
		_result_hold_pin_left = 2
	elif blend_from_pose:
		_pin_motion_reference_world(locked_hip)
		_clip_ref_start_world = locked_hip
		_clip_ref_tracking = true
	else:
		_begin_clip_ref_tracking()
	if _catalog_has_audio_cues(action_id):
		_begin_catalog_audio_cues(action_id)
	else:
		_play_catalog_audio(action_id)
	if action_id == ACTION_FOLLOWUP_ENTRANCE:
		print("[兜兜] 播放鬼鬼祟祟 pos=%s" % global_position)


func _play_catalog_loop(action_id: String, phase: RoundPhase) -> void:
	if _player == null or not _player.has_animation(action_id):
		push_error("兜兜缺少动画 clip（检查 catalog / GLB 轨道名）：%s" % action_id)
		return
	if action_id != ACTION_IDLE_HUB:
		_set_hub_idle_breath(false)
	_begin_doudou_face_for_action(action_id)
	if action_id == ACTION_IDLE_HUB:
		_begin_idle_hub_transition(phase)
		_set_hub_idle_breath(true)
		return
	_finalize_clip_root_motion()
	_phase = phase
	_active_action_id = action_id
	_player.speed_scale = _catalog_action_speed(action_id)
	_start_catalog_anim(action_id, true)
	_begin_clip_ref_tracking()


func _begin_idle_hub_transition(phase: RoundPhase) -> void:
	# 锁上一段末帧（上前嘲讽）模型整体 world 位置 + 朝向/缩放，finalize 后对齐再播叉腰。
	var locked_basis := global_transform.basis
	var pivot_world := _model.global_position if _model != null else global_position
	_finalize_clip_root_motion()
	_align_actor_pivot_world(pivot_world, locked_basis)
	_phase = phase
	_active_action_id = ACTION_IDLE_HUB
	_player.speed_scale = _catalog_action_speed(ACTION_IDLE_HUB)
	_start_catalog_anim(ACTION_IDLE_HUB, true, IDLE_HUB_ENTER_BLEND_SEC)
	_begin_clip_ref_tracking()


func _align_actor_pivot_world(pivot_world: Vector3, locked_basis: Basis) -> void:
	if _model != null:
		var fix := pivot_world - _model.global_position
		if fix.length_squared() > 1e-10:
			global_position += fix
	var gt := global_transform
	gt.basis = locked_basis
	global_transform = gt


func _catalog_playback_window(action_id: String) -> Vector2:
	var entry := EventCatalog.find_entry(action_id)
	if entry.is_empty():
		return Vector2.ZERO
	var clip := _player.get_animation(action_id) if _player != null else null
	var total := clip.length if clip != null else 0.0
	var start := float(entry.get("playback_start", 0.0))
	var end := float(entry.get("playback_end", -1.0))
	if end < 0.0 or end > total:
		end = total
	return Vector2(start, end)


## 默认播满挂载 clip；仅「跑出」允许 catalog 提前结束（根运动裁切）。
func _flow_playback_window(action_id: String) -> Vector2:
	if _player == null or not _player.has_animation(action_id):
		return Vector2.ZERO
	var clip := _player.get_animation(action_id)
	var total := clip.length
	var start := 0.0
	var entry := EventCatalog.find_entry(action_id)
	if not entry.is_empty():
		start = maxf(float(entry.get("playback_start", 0.0)), 0.0)
	if action_id == ACTION_RUN_OUT and not entry.is_empty():
		var end := float(entry.get("playback_end", -1.0))
		if end >= 0.0:
			end = clampf(end, start + 0.05, total)
			return Vector2(start, end)
	# 嘲讽段在沙盒须播满 GLB（≈5s），勿用口型场或其它 runtime 写入的 playback_end。
	if EventCatalog.forces_full_clip_playback(action_id):
		return Vector2(start, total)
	if not entry.is_empty() and entry.has("playback_end"):
		var end := float(entry.get("playback_end", -1.0))
		if end >= 0.0:
			end = clampf(end, start + 0.05, total)
			return Vector2(start, end)
	return Vector2(start, total)


func _scripted_clip_playback_end(action_id: String) -> float:
	return _flow_playback_window(action_id).y


func _scripted_clip_time_complete(action_id: String) -> bool:
	if not EventCatalog.forces_full_clip_playback(action_id):
		return true
	if _player == null or not _player.has_animation(action_id):
		return true
	var end := _scripted_clip_playback_end(action_id)
	if end <= 0.01:
		return true
	return _player.current_animation_position >= end - 0.05


func _resume_scripted_clip_if_short(action_id: String) -> bool:
	if _player == null or not _player.has_animation(action_id):
		return false
	var window := _flow_playback_window(action_id)
	var start := window.x
	var end := window.y
	if end <= start + 0.05:
		return false
	var pos := clampf(_player.current_animation_position, start, end)
	if pos >= end - 0.05:
		return false
	var clip := _player.get_animation(action_id)
	clip.loop_mode = Animation.LOOP_NONE
	_player.speed_scale = _catalog_action_speed(action_id)
	_active_action_id = action_id
	if start > 0.001 or end < clip.length - 0.001:
		_player.play_section(action_id, maxf(pos, start), end, -1.0, 1.0, false)
	else:
		_player.play(action_id, -1.0, 1.0, false)
		_player.seek(maxf(pos, start), true)
	return true


func _poll_scripted_full_clip_playback() -> void:
	if _phase != RoundPhase.SCRIPTED_QUEUE or _active_action_id == "":
		return
	if not EventCatalog.forces_full_clip_playback(_active_action_id):
		return
	if _player == null:
		return
	if _player.is_playing():
		return
	if not _scripted_clip_time_complete(_active_action_id):
		_resume_scripted_clip_if_short(_active_action_id)
		return
	_advance_scripted_queue_after_clip(_active_action_id)


func _advance_scripted_queue_after_clip(action_id: String) -> void:
	if _scripted_queue_finishing:
		return
	if action_id != _active_action_id:
		return
	if not _scripted_clip_time_complete(action_id):
		_resume_scripted_clip_if_short(action_id)
		return
	_scripted_queue_finishing = true
	if _consume_grab_after_current_clip():
		_scripted_queue_finishing = false
		return
	if _action_queue.is_empty():
		_after_scripted_queue_exhausted()
	else:
		_advance_action_queue()
	_scripted_queue_finishing = false


func _catalog_action_speed(action_id: String) -> float:
	var entry := EventCatalog.find_entry(action_id)
	if entry.is_empty():
		return 1.0
	return maxf(float(entry.get("action_speed", 1.0)), 0.01)


func _on_animation_finished(anim_name: StringName) -> void:
	if _suppress_anim_finished:
		return
	var id := String(anim_name)
	if id == ACTION_IDLE_HUB and _phase == RoundPhase.IDLE_HUB:
		if _player != null:
			_player.play(ACTION_IDLE_HUB, -1.0, 1.0, false)
		return
	if _scripted_first_round:
		_on_scripted_animation_finished(id)
	else:
		_on_followup_animation_finished(id)


func _on_scripted_animation_finished(id: String) -> void:
	match _phase:
		RoundPhase.INTRO_ENTRANCE:
			if id == ACTION_ENTRANCE:
				_entrance_scare_armed = false
				if _consume_grab_after_current_clip():
					return
				_phase = RoundPhase.INTRO_WAIT
				_hold_clip_last_frame(ACTION_ENTRANCE)
		RoundPhase.INTRO_TACTICS:
			if id == ACTION_TACTICS:
				_tactics_scare_armed = false
				scripted_tactics_finished.emit()
				if _consume_grab_after_current_clip():
					return
				_phase = RoundPhase.INTRO_WAIT_TAUNT
				_hold_clip_last_frame(ACTION_TACTICS)
		RoundPhase.SCRIPTED_QUEUE:
			if id != _active_action_id:
				return
			_advance_scripted_queue_after_clip(id)
		RoundPhase.OUTCOME:
			if id == _active_action_id:
				_play_run_out_after_result()
		RoundPhase.RUN_OUT:
			if id == ACTION_RUN_OUT:
				_enter_frozen_run_out_hold()


func _on_followup_animation_finished(id: String) -> void:
	match _phase:
		RoundPhase.OUTCOME:
			if id == _active_action_id:
				_play_run_out_after_result()
		RoundPhase.RUN_OUT:
			if id == ACTION_RUN_OUT:
				_enter_frozen_run_out_hold()
		RoundPhase.SCRIPTED_QUEUE:
			if id != _active_action_id:
				return
			_advance_scripted_queue_after_clip(id)
		_:
			_consume_grab_after_current_clip()


func _play_run_out_after_result() -> void:
	if _player != null and _player.has_animation(ACTION_RUN_OUT):
		_play_catalog_once(ACTION_RUN_OUT, RoundPhase.RUN_OUT)
	else:
		push_warning("兜兜缺少跑出：%s" % ACTION_RUN_OUT)
		_phase = RoundPhase.FROZEN


func _enter_frozen_run_out_hold() -> void:
	_finalize_clip_root_motion()
	_phase = RoundPhase.FROZEN
	_set_actor_visible(true)
	_hold_clip_last_frame(ACTION_RUN_OUT)
	print("[兜兜] 跑出末帧停留 pos=%s 直至续局" % global_position)


## 续局前：松开跑出 pause，世界坐标不变。
func _handoff_from_frozen_run_out_hold() -> void:
	_clip_ref_tracking = false


## 下一段 GLB 接管前：只复位骨骼/模型局部，不叠 Actor 位移。
func _handoff_world_pose_for_next_clip() -> void:
	_clip_ref_tracking = false
	_reset_skeleton_to_rest()
	_reset_model_local_transform()


## 单段播完后保持末帧（不在此处 commit 位移，避免骨骼+Actor 双计导致瞬移出画）。
func _hold_clip_last_frame(action_id: String) -> void:
	if _player == null or not _player.has_animation(action_id):
		return
	var clip := _player.get_animation(action_id)
	clip.loop_mode = Animation.LOOP_NONE
	var window := _flow_playback_window(action_id)
	var start := window.x
	var end := window.y
	if end <= start + 0.05:
		end = clip.length
		start = 0.0
	_set_pose_capture(false)
	if start > 0.001 or end < clip.length - 0.001:
		_player.play_section(action_id, start, end, 0.0, 1.0, false)
	else:
		_player.play(action_id, 0.0, 1.0, false)
		end = clip.length
	_player.seek(maxf(end - 0.02, start), true)
	_player.pause()
	_active_action_id = action_id


func _begin_clip_ref_tracking() -> void:
	call_deferred("_deferred_begin_clip_ref_tracking")


func _deferred_begin_clip_ref_tracking() -> void:
	if _model == null:
		return
	_clip_ref_start_world = _motion_reference_world()
	_clip_ref_tracking = true


func _start_catalog_anim(action_id: String, loop: bool, blend_sec: float = 0.0, _apply_now: bool = true) -> void:
	if _player == null or not _player.has_animation(action_id):
		return
	var clip := _player.get_animation(action_id)
	clip.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var window := _flow_playback_window(action_id)
	var start := window.x
	var end := window.y
	var blend := blend_sec if blend_sec >= 0.0 else 0.0
	var trimmed := start > 0.001 or (end > 0.0 and end < clip.length - 0.001)
	# 停掉上一段，避免 play_section 发现当前时间还落在新片段里，从中途接着播。
	_suppress_anim_finished = true
	_player.stop()
	if trimmed and end > start + 0.05:
		_player.play_section(action_id, start, end, blend, 1.0, false)
	else:
		_player.play(action_id, blend, 1.0, false)
	_player.seek(start, true)
	if not _player.is_playing():
		if trimmed and end > start + 0.05:
			_player.play_section(action_id, start, end, blend, 1.0, false)
		else:
			_player.play(action_id, blend, 1.0, false)
		_player.seek(start, true)
	_suppress_anim_finished = false


func _commit_clip_root_motion_delta() -> void:
	if _model == null:
		return
	if _clip_ref_tracking:
		_clip_ref_tracking = false
		var delta := _motion_reference_world() - _clip_ref_start_world
		if delta.length_squared() > 1e-10:
			global_position += delta
	_apply_model_root_motion_fallback()
	_reset_model_local_transform()


func _finalize_clip_root_motion() -> void:
	_commit_clip_root_motion_delta()
	_reset_skeleton_to_rest()


func _has_live_body_pose() -> bool:
	if _player == null or _active_action_id == "":
		return false
	return String(_player.assigned_animation) == _active_action_id


func _bake_model_offset_keep_pose() -> void:
	_clip_ref_tracking = false
	_apply_model_root_motion_fallback()
	_reset_model_local_transform()


func _set_pose_capture(enabled: bool) -> void:
	if _player == null:
		return
	_player.playback_auto_capture = enabled
	if enabled:
		_player.playback_auto_capture_duration = POSE_BLEND_SEC


func _apply_pose_blend_pin(delta: float) -> void:
	if _pose_blend_pin_left <= 0.0:
		return
	_pose_blend_pin_left = maxf(_pose_blend_pin_left - delta, 0.0)
	_pin_motion_reference_world(_pose_blend_hip)
	if _clip_ref_tracking:
		_clip_ref_start_world = _pose_blend_hip


func _apply_pending_result_hold_pin() -> void:
	if _result_hold_pin_left <= 0:
		return
	_result_hold_pin_left -= 1
	_pin_motion_reference_world(_result_hold_hip)
	if _clip_ref_tracking:
		_clip_ref_start_world = _result_hold_hip


func _pin_motion_reference_world(target_hip_world: Vector3) -> void:
	var fix := target_hip_world - _motion_reference_world()
	if fix.length_squared() > 1e-8:
		global_position += fix


func _motion_reference_world() -> Vector3:
	if _model == null:
		return global_position
	var sk := _model.find_child("Skeleton3D", true, false) as Skeleton3D
	if sk == null:
		return _model.global_position
	var idx := _resolve_motion_bone(sk)
	if idx < 0:
		return _model.global_position
	return sk.global_transform * sk.get_bone_pose(idx).origin


func _resolve_motion_bone(sk: Skeleton3D) -> int:
	if _motion_bone_idx >= 0 and _motion_bone_idx < sk.get_bone_count():
		return _motion_bone_idx
	for hint in REF_BONE_HINTS:
		var idx := sk.find_bone(hint)
		if idx >= 0:
			_motion_bone_idx = idx
			return idx
	if sk.get_bone_count() > 0:
		_motion_bone_idx = 0
		return 0
	return -1


func _reset_skeleton_to_rest() -> void:
	if _model == null:
		return
	var sk := _model.find_child("Skeleton3D", true, false) as Skeleton3D
	if sk != null:
		sk.reset_bone_poses()
	if _body_breath != null:
		_body_breath.sync_after_skeleton_reset()


func _apply_model_root_motion_fallback() -> void:
	if _model == null:
		return
	var local := _model.position
	if local.length_squared() < 1e-10:
		return
	global_position += global_transform.basis * local


func _reset_model_local_transform() -> void:
	if _model == null:
		return
	_model.position = Vector3.ZERO
	_model.rotation = Vector3.ZERO


func _set_actor_visible(on: bool) -> void:
	visible = on
	if _body_breath != null:
		_body_breath.set_enabled(on)
		if not on:
			_set_hub_idle_breath(false)
	if not on:
		_end_doudou_split_face()


func _set_hub_idle_breath(on: bool) -> void:
	if _body_breath == null:
		return
	_body_breath.set_hub_idle_prominent(on)
	if on and visible:
		_body_breath.set_enabled(true)


func _catalog_has_audio_cues(action_id: String) -> bool:
	return not _catalog_audio_cue_specs(action_id).is_empty()


func _catalog_audio_cue_specs(action_id: String) -> Array[Dictionary]:
	var entry := EventCatalog.find_entry(action_id)
	if entry.is_empty():
		return []
	var raw: Variant = entry.get("audio_cues", [])
	if typeof(raw) != TYPE_ARRAY:
		return []
	var specs: Array[Dictionary] = []
	for item in raw:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var path := String(item.get("audio", ""))
		if path == "" or not FileAccess.file_exists(path):
			continue
		specs.append({
			"path": path,
			"start_at": maxf(float(item.get("start_at", 0.0)), 0.0),
			"fired": false,
		})
	return specs


func _clear_scheduled_audio_cues() -> void:
	_scheduled_audio_cues.clear()
	_pending_voice_action = ""
	_pending_voice_path = ""
	_pending_voice_delay_left = -1.0


func _begin_catalog_audio_cues(action_id: String) -> void:
	_clear_scheduled_audio_cues()
	_scheduled_audio_cues = _catalog_audio_cue_specs(action_id)
	if _audio != null:
		_audio.stop()


func _action_playback_time() -> float:
	if _player == null or not _player.is_playing():
		return -1.0
	var window := _flow_playback_window(_active_action_id)
	return _player.current_animation_position - window.x


func _try_fire_scheduled_audio_cues(delta: float) -> void:
	_try_fire_pending_catalog_voice(delta)
	if _scheduled_audio_cues.is_empty() or _player == null or not _player.is_playing():
		return
	var t := _action_playback_time()
	if t < 0.0:
		return
	for i in _scheduled_audio_cues.size():
		var cue: Dictionary = _scheduled_audio_cues[i]
		if bool(cue.get("fired", false)):
			continue
		if t + 0.0005 >= float(cue.get("start_at", 0.0)):
			_scheduled_audio_cues[i]["fired"] = true
			_play_voice_path(String(cue.get("path", "")))


func _try_fire_pending_catalog_voice(delta: float) -> void:
	if _pending_voice_path == "" or _pending_voice_action != _active_action_id:
		return
	if _pending_voice_delay_left > 0.0:
		_pending_voice_delay_left -= delta
		if _pending_voice_delay_left > 0.0:
			return
	var path := _pending_voice_path
	var speed := _pending_voice_speed
	_pending_voice_action = ""
	_pending_voice_path = ""
	_pending_voice_delay_left = -1.0
	_play_voice_path(path, speed)


func _play_voice_path(path: String, speed: float = 1.0, from_sec: float = 0.0) -> void:
	if path == "" or not FileAccess.file_exists(path) or _audio == null:
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	_audio.stream = stream
	_audio.pitch_scale = maxf(speed, 0.01)
	_audio.play(maxf(from_sec, 0.0))
	_maybe_start_doudou_action_viseme()


func _play_catalog_audio(action_id: String) -> void:
	var entry := EventCatalog.find_entry(action_id)
	if entry.is_empty():
		return
	var path := String(entry.get("default_audio", ""))
	if path == "" or not FileAccess.file_exists(path):
		return
	var audio_speed := maxf(float(entry.get("audio_speed", 1.0)), 0.01)
	var offset := maxf(float(entry.get("audio_start_offset", 0.0)), 0.0)
	var start := _flow_playback_window(action_id).x
	var action_speed := _catalog_action_speed(action_id)
	_pending_voice_action = action_id
	_pending_voice_path = path
	_pending_voice_speed = audio_speed
	_pending_voice_offset = offset
	_pending_voice_delay_left = maxf(offset - start, 0.0) / action_speed


func _load_all_catalog_clips() -> void:
	if _clips_loaded or _player == null:
		return
	var lib := _player.get_animation_library("")
	if lib == null:
		lib = AnimationLibrary.new()
		_player.add_animation_library("", lib)
	for aid in EventCatalog.get_action_ids():
		var entry := EventCatalog.find_entry(aid)
		var clip := _take_clip_from_entry(entry)
		if clip == null:
			continue
		if lib.has_animation(aid):
			var force_full := (
				EventCatalog.forces_full_clip_playback(aid) or aid == ACTION_IDLE_HUB
			)
			var existing := lib.get_animation(aid)
			var same_len := (
				existing != null and absf(existing.length - clip.length) < 0.02
			)
			if not force_full and same_len:
				continue
			if force_full or not same_len:
				lib.remove_animation(aid)
		lib.add_animation(aid, clip)
	_clips_loaded = true


func _take_clip_from_entry(entry: Dictionary) -> Animation:
	var action_id := String(entry.get("action_id", ""))
	var scene_path := String(entry.get("scene", ""))
	var source_anim := String(entry.get("source_anim", action_id))
	if scene_path == "":
		return null
	var probe: Dictionary = EventCatalog.probe_animation_clip(scene_path, source_anim)
	if not bool(probe.get("ok", false)):
		var packed := load(scene_path) as PackedScene
		if packed == null:
			return null
		var instance := packed.instantiate()
		var source := instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if source == null or source.get_animation_list().is_empty():
			instance.free()
			return null
		source_anim = String(source.get_animation_list()[0])
		instance.free()
	var packed := load(scene_path) as PackedScene
	if packed == null:
		return null
	var instance := packed.instantiate()
	var source := instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if source == null or not source.has_animation(source_anim):
		instance.free()
		push_warning("兜兜 clip 缺失：%s @ %s" % [source_anim, scene_path])
		return null
	var clip := (source.get_animation(source_anim) as Animation).duplicate(true) as Animation
	instance.free()
	if action_id == ACTION_IDLE_HUB:
		clip = _strip_hub_clip_root_translation(clip)
	return clip


## 叉腰循环须原地播；GLB 里胯骨/根骨 position 轨在 finalize+reset 后会再推一截 world 位移（续局蹦蹦跳跳后尤其明显）。
func _strip_hub_clip_root_translation(clip: Animation) -> Animation:
	var out := clip.duplicate(true) as Animation
	for i in range(out.get_track_count() - 1, -1, -1):
		if out.track_get_type(i) != Animation.TYPE_POSITION_3D:
			continue
		if _animation_track_is_root_translation(String(out.track_get_path(i))):
			out.remove_track(i)
	return out


func _animation_track_is_root_translation(path: String) -> bool:
	var lower := path.to_lower()
	if lower.ends_with(":position") and not lower.contains("mixamorig") and not lower.contains("hips"):
		return true
	for token in ["hips", "pelvis"]:
		if token in lower:
			return true
	if "root" in lower and not lower.contains("spine"):
		return true
	return false


func _begin_doudou_face_for_action(action_id: String) -> void:
	_sync_face_catalog_coefficients(action_id)
	_split_timeline_active = SplitTimelines.has_timeline(action_id)
	if _doudou_face != null:
		_doudou_face.set_split_expression_override(_split_timeline_active)
	if not _split_timeline_active:
		_end_doudou_split_face()


func _catalog_viseme_enabled(action_id: String) -> bool:
	var entry := EventCatalog.find_entry(action_id)
	if entry.is_empty():
		return true
	return bool(entry.get("enable_viseme", true))


func _sync_face_catalog_coefficients(action_id: String) -> void:
	_mouth_emotion_coef = FacePresenter.APPROVED_MOUTH_EMOTION_COEF
	_viseme_coef = DoudouFacePresenter.DOUDOU_VISEME_COEF
	var entry := EventCatalog.find_entry(action_id)
	if entry.is_empty():
		return
	if entry.has("mouth_emotion_weight"):
		_mouth_emotion_coef = float(entry.get("mouth_emotion_weight", _mouth_emotion_coef))
	if entry.has("viseme_weight"):
		_viseme_coef = float(entry.get("viseme_weight", _viseme_coef))


func _tick_doudou_split_face() -> void:
	if not visible or not _split_timeline_active or _split_player == null:
		return
	if _player == null or _active_action_id.is_empty():
		return
	var anim_ok := _player.is_playing() and (
		String(_player.current_animation) == _active_action_id
		or String(_player.assigned_animation) == _active_action_id
	)
	var speech := _audio != null and _audio.playing
	var viseme_track := speech and _catalog_viseme_enabled(_active_action_id)
	if not anim_ok and not speech:
		return
	var t := _split_timeline_anim_sec()
	_split_player.set_mouth_emotion_coef(_mouth_emotion_coef)
	_split_player.set_viseme_speech_active(viseme_track)
	_split_player.apply_at_time(_active_action_id, t, true)
	if _direct_viseme != null:
		if viseme_track:
			_maybe_start_doudou_action_viseme()
			_direct_viseme.tick()
		elif _direct_viseme.is_active():
			_direct_viseme.stop()


func _split_timeline_anim_sec() -> float:
	var speed := maxf(_catalog_action_speed(_active_action_id), 0.01)
	var window := _flow_playback_window(_active_action_id)
	return maxf(_player.current_animation_position - window.x, 0.0) / speed


func _maybe_start_doudou_action_viseme() -> void:
	if not _split_timeline_active or _direct_viseme == null:
		return
	if not _catalog_viseme_enabled(_active_action_id):
		return
	if _audio == null or not _audio.playing:
		return
	_direct_viseme.set_viseme_coef(_viseme_coef)
	if _direct_viseme.is_active():
		return
	_direct_viseme.start()


func _on_doudou_voice_finished() -> void:
	if _direct_viseme != null:
		_direct_viseme.stop()


func _end_doudou_split_face() -> void:
	if _direct_viseme != null:
		_direct_viseme.stop()
	if _split_player != null:
		_split_player.clear_timeline_layers()
	_split_timeline_active = false
	if _doudou_face != null:
		_doudou_face.set_split_expression_override(false)


func _setup_doudou_face_rig() -> void:
	_meshes.clear()
	_collect_meshes(_model)
	if _meshes.is_empty():
		push_warning("兜兜沙盒：未找到带 morph 的 MeshInstance3D")
		return
	_doudou_face = DoudouFacePresenter.new()
	_doudou_face.name = "DoudouSandboxFace"
	add_child(_doudou_face)
	_doudou_face.setup(_meshes, FacePresenter.capture_zero_baseline(_meshes))
	_split_player = SplitTimelinePlayer.new()
	_split_player.setup(_meshes)
	_idle_blink = DoudouIdleBlink.new()
	_idle_blink.name = "DoudouIdleBlink"
	add_child(_idle_blink)
	_idle_blink.setup(_meshes)
	_direct_viseme = DirectVisemePlayer.new()
	_direct_viseme.setup(_meshes, _audio, _doudou_face)


func _collect_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		_meshes.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child)


func _ensure_model() -> void:
	if _model != null and is_instance_valid(_model):
		return
	if not FileAccess.file_exists(MODEL_PATH):
		push_error("兜兜模型缺失：" + MODEL_PATH)
		return
	var packed := load(MODEL_PATH) as PackedScene
	if packed == null:
		return
	_model = packed.instantiate() as Node3D
	_model.name = "DoudouSideModel"
	_model.visible = true
	if _world_slot == null:
		_model.scale = Vector3(HEIGHT_SCALE, HEIGHT_SCALE, HEIGHT_SCALE)
	add_child(_model)
	_player = _find_animation_player(_model)
	if _player != null and not _player.animation_finished.is_connected(_on_animation_finished):
		_player.animation_finished.connect(_on_animation_finished)
	_body_breath = DoudouBodyBreath.new()
	_body_breath.name = "DoudouBodyBreath"
	_model.add_child(_body_breath)
	_body_breath.setup(_model, _player)
	_body_breath.set_strength(1.08)
	_body_breath.set_enabled(false)
	_audio = AudioStreamPlayer.new()
	_audio.name = "DoudouSideVoice"
	_audio.volume_db = ClawSceneAudio.VOICE_VOLUME_DB
	add_child(_audio)
	if not _audio.finished.is_connected(_on_doudou_voice_finished):
		_audio.finished.connect(_on_doudou_voice_finished)
	_setup_doudou_face_rig()


func _find_animation_player(root: Node) -> AnimationPlayer:
	var best: AnimationPlayer = null
	var best_count := -1
	for node in root.find_children("*", "AnimationPlayer", true, false):
		var p := node as AnimationPlayer
		var n := p.get_animation_list().size()
		if n > best_count:
			best = p
			best_count = n
	return best
