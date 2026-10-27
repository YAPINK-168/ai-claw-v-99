extends Node3D

const FacePresenter := preload("res://Scripts/youyou_face_presenter.gd")
const PerformancePoseController := preload("res://Scripts/youyou_performance_pose.gd")
const Approved := preload("res://Scripts/youyou_action_lipsync_approved.gd")
const ApprovedPerformance := preload("res://Scripts/youyou_approved_action_performance.gd")
const GazeController := preload("res://Scripts/youyou_eye_gaze_controller.gd")
const HeadFollow := preload("res://Scripts/youyou_head_follow_controller.gd")
const IdleLife := preload("res://Scripts/youyou_idle_life_controller.gd")
const EventActionPerformance := preload("res://Scripts/youyou_event_action_performance.gd")
const ClawShowAdapter := preload("res://Scripts/youyou_claw_show_adapter.gd")
const EventCatalog := preload("res://Scripts/youyou_action_event_catalog.gd")
const SplitTimelines := preload("res://Scripts/youyou_action_split_expression_timelines.gd")
const PrecoinScheduler := preload("res://Scripts/youyou_precoin_scheduler.gd")
const GrabFlow := preload("res://Scripts/youyou_grab_show_flow.gd")
const MinigameInviteFlow := preload("res://Scripts/youyou_minigame_invite_flow.gd")
const InviteListenConfig := preload("res://Scripts/voice/invite_listen_config.gd")
const ClawBusinessNode := preload("res://Scripts/business/claw_business.gd")
const ClawBoardBridge := preload("res://Scripts/business/claw_board_bridge.gd")
const MinigamePortNode := preload("res://Scripts/business/claw_minigame_port.gd")
const MinigameHostNode := preload("res://Scripts/business/claw_minigame_host.gd")
const ClawSceneAudio := preload("res://Scripts/audio/claw_scene_audio.gd")
const PreviewAiVoiceBridge := preload("res://Scripts/voice/preview_ai_voice_bridge.gd")
const PreviewAiVoicePrecoinCheckRunner := preload(
	"res://Scripts/voice/preview_ai_voice_precoin_check_runner.gd"
)
const PreviewAiVoiceObservabilityCheckRunner := preload(
	"res://Scripts/voice/preview_ai_voice_observability_check_runner.gd"
)
const PreviewAiVoiceStatusCheckRunner := preload(
	"res://Scripts/voice/preview_ai_voice_status_check_runner.gd"
)
const PreviewAiVoicePlayerStatus := preload("res://Scripts/voice/preview_ai_voice_player_status.gd")
const PreviewAiVoicePhase2RegressionRunner := preload(
	"res://Scripts/voice/preview_ai_voice_phase2_regression_runner.gd"
)
const FormalStreamingAsrCheckRunner := preload(
	"res://Scripts/voice/formal_streaming_asr_check_runner.gd"
)
const PreviewVadEventLog := preload("res://Scripts/voice/preview_vad_event_log.gd")
const PreviewDebugPanel := preload("res://Scripts/youyou_preview_debug_panel.gd")
const YouyouLeftHud := preload("res://Scripts/youyou_left_hud.gd")
const YouyouRightHud := preload("res://Scripts/youyou_right_hud.gd")
const PreviewVisualTuning := preload("res://Scripts/youyou_preview_visual_tuning.gd")
const VoiceSubtitleCatalog := preload("res://Scripts/youyou_voice_subtitle_catalog.gd")
const PREVIEW_AI_SPEAK_ANIM := "youyou_Speak_Idle05"

const MODEL_PATH := "res://柚柚.glb"
const CLOTHES_PATH := "res://新衣服/柚柚衣服.glb"
const IDLE_SCENE_PATH := "res://待机Animation/Basic_Idle.glb"
const HELLO_SCENE_PATH := "res://待机Animation/youyou_Hello_Idle01.glb"
const IDLE_ANIM := "Basic_Idle"
const HELLO_ANIM := "youyou_Hello_Idle01"
## 预览主场景用修复骨骼替换对应动作。表情时间轴和配音偏移仍用原登记。
const PREVIEW_BODY_REPLACEMENTS: Dictionary = {
	"Basic_Idle": "res://柚柚新动作/Basic_Idle.glb",
	"Basic_Idle01": "res://柚柚新动作/Basic_Idle01.glb",
	"Basic_Idle02": "res://柚柚新动作/Basic_Idle02.glb",
	"Basic_Idle04": "res://柚柚新动作/Basic_Idle04.glb",
	"Basic_Idle05": "res://柚柚新动作/Basic_Idle05.glb",
	"youyou_Basic_Idle02": "res://柚柚新动作/youyou_Basic_Idle02.glb",
	"youyou_Hello_Idle01": "res://柚柚新动作/youyou_Hello_Idle01.glb",
}
const SHOE_MESH_NAMES: PackedStringArray = ["鞋子左", "鞋子右"]
const FLOOR_SOLE_CLEARANCE := 0.0015
const FLOOR_ALIGN_ANIMS: PackedStringArray = [
	IDLE_ANIM,
	HELLO_ANIM,
	"youyou_Speak_Idle01",
	"youyou_fail01",
	"youyou_victory01",
]
const BLEND_BASE_TO_LIGHT := 0.25
const BLEND_LIGHT_TO_BASE := 0.30
const BLEND_BASE_TO_ATTRACT := 0.25
const BLEND_LIGHT_TO_ATTRACT := 0.20
const BLEND_ATTRACT_TO_BASE := 0.30
const BLEND_MANUAL := 0.25
## 口型测试键（A/E 已被待机动画占用）：[ ] ; ' /
const VISEME_KEYS := {
	KEY_BRACKETLEFT: "a",
	KEY_BRACKETRIGHT: "e",
	KEY_SEMICOLON: "i",
	KEY_APOSTROPHE: "o",
	KEY_SLASH: "u",
}
const EMOTE_KEYS := {
	KEY_1: "smile",
	KEY_2: "surprise",
	KEY_3: "laugh",
	KEY_C: "angry",
	KEY_V: "sad",
	KEY_P: "grin",
	KEY_J: "wink",
	KEY_K: "lookleft",
	KEY_L: "lookright",
}
const EXTENDED_EMOTE_KEYS := {
	KEY_COMMA: "think",
	KEY_PERIOD: "sleepy",
	KEY_MINUS: "serious",
	KEY_EQUAL: "smug_smile",
	KEY_BACKSLASH: "yawn",
}
const BATCH_ONESHOTS := {
	KEY_4: "hello01",
	KEY_5: "Hand Wave_rig_01",
	KEY_6: "youyou_Hello_Idle02",
	KEY_7: "youyou_Hello_Idle03",
	KEY_8: "youyou_Hello_Idle06",
	KEY_9: "youyou_Hello_Idle07",
	KEY_B: "youyou_Hello_Idle08",
	KEY_N: "youyou_Hello_Idle09",
}
## true 时：静音 F5/数字8 等，仅 WASD/X 模拟摇杆与抓取键；false 时使用下方调试键
const CLAW_JOYSTICK_X_INPUT := false
## 键盘 WASD 与串口摇杆键位对齐（W上/S下/A左/D右），并驱动眼/头；与 CLAW_JOYSTICK_X_INPUT 独立
const CLAW_WASD_BOARD_SIM := true
## false：表情/待机/Shift+F1–F4 等仅 Shift+键 生效，避免与娃娃机 WASD、F 键业务抢键
const PREVIEW_FACE_DEBUG_KEYS := false

const PREVIEW_EVENT_KEYS := {
	KEY_F1: "youyou_coin01",
	KEY_F2: "youyou_fail01",
	KEY_F3: "youyou_victory01",
	KEY_F4: "youyou_claw crane01_01",
}
const IDLE_VARIANTS := {
	KEY_Q: "Basic_Idle01",
	KEY_W: "Basic_Idle02",
	KEY_E: "youyou_LookLeftRight",
	KEY_T: "Basic_Idle04",
	KEY_A: "Basic_Idle05",
	KEY_X: "youyou_Basic_Idle01",
	KEY_S: "youyou_Basic_Idle02",
	KEY_D: "youyou_Basic_Idle03",
	KEY_F: "youyou_Basic_Idle04",
	KEY_G: "youyou_Basic_Idle05",
	KEY_Z: "youyou_Basic_Idle06",
}
const CLIP_ALIASES := {
	"youyou_Basic_Idle01": {
		"scene": "res://待机Animation/youyou_Basic_Idle01.001.glb",
		"source": "youyou_Basic_Idle01_001",
	},
}
const NEW_CLIP_NAMES: PackedStringArray = [
	"youyou_Basic_Idle01",
	"youyou_Hello_Idle02",
	"youyou_Hello_Idle03",
	"youyou_Hello_Idle06",
	"youyou_Hello_Idle07",
	"youyou_Hello_Idle08",
	"youyou_Hello_Idle09",
]
enum ScheduleMode { BASE_IDLE, LIGHT_IDLE, ATTRACT, MANUAL_TEST }
enum BackdropKind { LOBBY_3D, STUDIO_2_5D }

@export var backdrop_kind := BackdropKind.STUDIO_2_5D

## 屏幕四角安全区，避免挡住画面中央的柚柚。
const UI_SAFE_MARGIN := 16.0
const UI_SAFE_WIDTH := 318.0
const UI_HELP_BOTTOM := 12.0
const UI_HELP_HEIGHT := 36.0
const UI_GRAB_BANNER_BOTTOM := 52.0
const UI_GRAB_BANNER_HEIGHT := 76.0
const UI_INVITE_BANNER_BOTTOM := 136.0
const UI_INVITE_BANNER_HEIGHT := 92.0
const UI_AI_PROMPT_TOP := 8.0
const UI_AI_PROMPT_HEIGHT := 40.0
const UI_AI_PROMPT_WIDTH := 480.0
const UI_AI_PROMPT_HEAD_CLEARANCE := 0.28
## 抓取特写主要靠相机正交缩放；模型仅微补偿，避免与镜头双重放大。
const GRAB_CLOSEUP_CAMERA_ENABLED := false
const GRAB_CLOSEUP_MODEL_SCALE := 1.0
const GRAB_CLOSEUP_MODEL_IN_SEC := 0.88
const GRAB_CLOSEUP_MODEL_OUT_SEC := 1.35
var _model: Node3D
var _grab_closeup_model_tween: Tween
var _player: AnimationPlayer
var _skeleton: Skeleton3D
var _meshes: Array[MeshInstance3D] = []
var _default_shapes: Dictionary = {}
var _hello_active := false
var _oneshot_name := ""
var _status_label: Label
var _log_lines: PackedStringArray = []
var _reference_bones: Dictionary = {}
var _compat_lines: PackedStringArray = []
var _mode := ScheduleMode.MANUAL_TEST
var _schedule_enabled := false
var _wait_timer: Timer
var _general_light_pool: PackedStringArray = []
var _light_pool: PackedStringArray = []
var _attract_pool: PackedStringArray = []
var _last_light := ""
var _last_attract := ""
var _active_finish_anim := ""
var _planned_wait := 0.0
var _wait_armed_msec := 0
var _auto_return_count := 0
var _last_blend := 0.0
var _pending_attract_request := false
var _basic_idle_prev_pos := -1.0
var _face: FacePresenter
var _patch_apply_result: Dictionary = {}
var _emotion_restore_primary := FacePresenter.NEUTRAL_EMOTION_ID
var _viseme_clear_busy := false
var _performance_pose: Node
var _hello_perf_gen := 0
var _auto_perf_gen := 0
var _manual_perf_gen := 0
var _approved_perf: Node
var _event_perf: YouyouEventActionPerformance
var _show_adapter: YouyouClawShowAdapter
var _event_playing := false
var _saved_mode_before_event := ScheduleMode.BASE_IDLE
var _resume_schedule_after_event := false
var _event_play_token := 0
var _preview_event_token := -1
var _idle_life: Node
var _split_idle_life_suppressed := 0
var _presence_camera: Camera3D
var _precoin: YouyouPrecoinScheduler
var _precoin_enabled := false
var _grab_flow: YouyouGrabShowFlow
var _claw_audio: Node
var _invite_flow: YouyouMinigameInviteFlow
var _round_business: ClawBusiness
var _board_bridge: ClawBoardBridge
var _sim_joystick_bits := 0
var _sim_grab_held := false
var _sim_x_edge_armed := true
var _stick_operating_sent := false
var _board_stick_hooked := false
var _serial_key_bits := 0
var _claw_watch_pose := false
var _minigame_port: ClawMinigamePort
var _minigame_host: Node2D
var _minigame_launch_pending := false
var _auto_launch_minigame_on_play := true
var _show_claimed := false
var _result_banner: Label
var _invite_listen_banner: Label
var _ai_voice_bridge: PreviewAiVoiceBridge
var _preview_ai_speak_active := false
var _debug_panel: CanvasLayer
@onready var _left_hud: YouyouLeftHud = get_node_or_null("LeftHud") as YouyouLeftHud
var _right_hud: YouyouRightHud
var _debug_log_lines: PackedStringArray = []
var _last_precoin_play_result := ""
var _debug_panel_accum := 0.0
var _ai_player_prompt: Label
var _ai_player_status: PreviewAiVoicePlayerStatus
var _ctrl_latched := false
## 进了语音交互后，连续这么久不说话就离开交互区并开始招揽。
const VOICE_SILENCE_LEAVE_SEC := 5.0
var _silence_leave_at_msec := 0


func use_studio_2_5d_backdrop() -> void:
	backdrop_kind = BackdropKind.STUDIO_2_5D


func _ready() -> void:
	_status_label = get_node_or_null("StatusLayer/StatusLabel") as Label
	if _status_label != null:
		_status_label.visible = false
	_init_preview_debug_panel()
	_init_left_hud()
	_init_right_hud()
	_apply_backdrop_mode()
	_ensure_wait_timer()
	var args := _cmdline_args_for_checks()
	if "--preview-ai-voice-precoin-check" in args:
		var ai_runner := PreviewAiVoicePrecoinCheckRunner.new()
		add_child(ai_runner)
		var ai_ok: bool = await ai_runner.run()
		get_tree().quit(0 if ai_ok else 1)
		return
	if "--preview-ai-voice-observability-check" in args:
		var obs_runner := PreviewAiVoiceObservabilityCheckRunner.new()
		add_child(obs_runner)
		var obs_ok: bool = await obs_runner.run()
		get_tree().quit(0 if obs_ok else 1)
		return
	if "--preview-ai-voice-status-check" in args:
		var status_runner := PreviewAiVoiceStatusCheckRunner.new()
		add_child(status_runner)
		var status_ok: bool = await status_runner.run()
		get_tree().quit(0 if status_ok else 1)
		return
	if "--preview-ai-voice-phase2-regression" in args:
		var phase2_runner := PreviewAiVoicePhase2RegressionRunner.new()
		add_child(phase2_runner)
		var phase2_ok: bool = await phase2_runner.run()
		get_tree().quit(0 if phase2_ok else 1)
		return
	if "--vad-endpoint-check" in args:
		var VadEndpointCheckRunner := preload("res://Scripts/voice/vad_endpoint_check_runner.gd")
		var vad_runner := VadEndpointCheckRunner.new()
		add_child(vad_runner)
		var vad_ok: bool = await vad_runner.run()
		get_tree().quit(0 if vad_ok else 1)
		return
	if "--preview-ai-voice-ws-default-regression" in args:
		var WsDefaultRunner := preload(
			"res://Scripts/voice/preview_ai_voice_ws_default_regression_runner.gd"
		)
		var ws_def := WsDefaultRunner.new()
		add_child(ws_def)
		var ws_def_ok: bool = await ws_def.run()
		get_tree().quit(0 if ws_def_ok else 1)
		return
	if "--youyou-persona-check" in args:
		var PersonaCheck := preload("res://Scripts/voice/youyou_persona_check_runner.gd")
		var persona_runner := PersonaCheck.new()
		add_child(persona_runner)
		var persona_ok: bool = await persona_runner.run()
		get_tree().quit(0 if persona_ok else 1)
		return
	if "--tts-chunk-diagnostic" in args:
		var TtsChunkDiag := preload("res://Scripts/voice/voice_tts_chunk_diagnostic_runner.gd")
		var chunk_runner := TtsChunkDiag.new()
		add_child(chunk_runner)
		var chunk_ok: bool = await chunk_runner.run()
		get_tree().quit(0 if chunk_ok else 1)
		return
	if "--tts-voice-ab-export" in args:
		var TtsAbExport := preload("res://Scripts/voice/voice_tts_ab_export_runner.gd")
		var export_runner := TtsAbExport.new()
		add_child(export_runner)
		var export_ok: bool = await export_runner.run()
		get_tree().quit(0 if export_ok else 1)
		return
	if "--tts-comma-policy-ab" in args:
		var CommaAb := preload("res://Scripts/voice/voice_tts_comma_policy_ab_runner.gd")
		var comma_ab := CommaAb.new()
		add_child(comma_ab)
		var comma_ok: bool = await comma_ab.run()
		get_tree().quit(0 if comma_ok else 1)
		return
	if "--formal-streaming-asr-check" in args:
		var asr_runner := FormalStreamingAsrCheckRunner.new()
		add_child(asr_runner)
		var asr_ok: bool = await asr_runner.run()
		get_tree().quit(0 if asr_ok else 1)
		return
	if "--formal-streaming-asr-d1-check" in args:
		var AsrD1 := preload("res://Scripts/voice/formal_streaming_asr_d1_check_runner.gd")
		var d1_runner := AsrD1.new()
		add_child(d1_runner)
		var d1_ok: bool = await d1_runner.run()
		get_tree().quit(0 if d1_ok else 1)
		return
	if "--bailian-tts-isolated-check" in args:
		var BailianTtsIsolatedCheckRunner := preload(
			"res://Scripts/voice/bailian_tts_isolated_check_runner.gd"
		)
		var tts_ab_runner := BailianTtsIsolatedCheckRunner.new()
		add_child(tts_ab_runner)
		var tts_ab_ok: bool = await tts_ab_runner.run()
		get_tree().quit(0 if tts_ab_ok else 1)
		return
	if "--pcm16-stream-player-check" in args:
		var Pcm16StreamPlayerCheckRunner := preload(
			"res://Scripts/voice/pcm16_stream_player_check_runner.gd"
		)
		var pcm_runner := Pcm16StreamPlayerCheckRunner.new()
		add_child(pcm_runner)
		var pcm_ok: bool = await pcm_runner.run()
		get_tree().quit(0 if pcm_ok else 1)
		return
	if "--voice-output-stream-tts-check" in args:
		var VoiceOutputStreamTtsCheckRunner := preload(
			"res://Scripts/voice/voice_output_stream_tts_check_runner.gd"
		)
		var vo_runner := VoiceOutputStreamTtsCheckRunner.new()
		add_child(vo_runner)
		var vo_ok: bool = await vo_runner.run()
		get_tree().quit(0 if vo_ok else 1)
		return
	if "--stream-tts-preempt-check" in args:
		var StreamTtsPreemptRunner := preload("res://Scripts/voice/stream_tts_preempt_check_runner.gd")
		var pr_runner := StreamTtsPreemptRunner.new()
		add_child(pr_runner)
		var pr_ok: bool = await pr_runner.run()
		get_tree().quit(0 if pr_ok else 1)
		return
	if "--stream-tts-lifecycle-check" in args:
		var StreamTtsLifecycleRunner := preload(
			"res://Scripts/voice/stream_tts_lifecycle_check_runner.gd"
		)
		var lc_runner := StreamTtsLifecycleRunner.new()
		add_child(lc_runner)
		var lc_ok: bool = await lc_runner.run()
		get_tree().quit(0 if lc_ok else 1)
		return
	if "--pcm16-stream-player-underrun-check" in args:
		var Pcm16UnderrunRunner := preload(
			"res://Scripts/voice/pcm16_stream_player_underrun_check_runner.gd"
		)
		var ur_runner := Pcm16UnderrunRunner.new()
		add_child(ur_runner)
		var ur_ok: bool = await ur_runner.run()
		get_tree().quit(0 if ur_ok else 1)
		return
	if "--voice-output-tts-playback-ab" in args:
		var VoiceOutputTtsPlaybackAbRunner := preload(
			"res://Scripts/voice/voice_output_tts_playback_ab_runner.gd"
		)
		var ab_runner := VoiceOutputTtsPlaybackAbRunner.new()
		add_child(ab_runner)
		var ab_ok: bool = await ab_runner.run()
		get_tree().quit(0 if ab_ok else 1)
		return
	if "--voice-output-stream-tts-playback-check" in args:
		var VoiceOutputStreamTtsPlaybackCheckRunner := preload(
			"res://Scripts/voice/voice_output_stream_tts_playback_check_runner.gd"
		)
		var play_runner := VoiceOutputStreamTtsPlaybackCheckRunner.new()
		add_child(play_runner)
		var play_ok: bool = await play_runner.run()
		get_tree().quit(0 if play_ok else 1)
		return
	if _cmdline_wants_minigame_invite_headless(args):
		if not _bootstrap_minigame_invite_headless():
			push_error("小游戏意愿 headless 检查：动画/业务引导失败，无法执行断言。")
			get_tree().quit(1)
			return
		_run_cmdline_check_branch(args)
		return
	if OS.has_feature("android") or OS.has_feature("mobile"):
		_relax_mobile_environment()
		_show_boot_wait("正在准备柚柚的动作和表情，请稍等。")
		await get_tree().process_frame
		if not is_inside_tree():
			return
	if not _load_model():
		_hide_boot_wait()
		if _cmdline_has_automated_check(args):
			push_error("自动化检查中止：角色模型加载失败。")
			get_tree().quit(1)
		return
	if not _load_clips():
		_hide_boot_wait()
		if _cmdline_has_automated_check(args):
			push_error("自动化检查中止：动画库加载失败。")
			get_tree().quit(1)
		return
	_apply_floor_alignment()
	_bind_foot_shadow()
	_patch_apply_result = FacePresenter.apply_split_patch_to_model(_model)
	if not bool(_patch_apply_result.get("ok", false)):
		_note("拆分补丁部分成功 %d/%d（舌头未匹配，口型仍用原 GLB）。" % [
			int(_patch_apply_result.get("success_count", 0)),
			int(_patch_apply_result.get("total_count", 0)),
		])
	_hide_boot_wait()
	_default_shapes = FacePresenter.capture_zero_baseline(_meshes)
	_init_face_presenter()
	_init_performance_pose_controller()
	_init_approved_performance()
	_init_event_action_performance()
	_init_idle_presence()
	_init_grab_flow()
	_init_claw_audio()
	_init_minigame_invite_flow()
	_init_preview_ai_voice()
	_start_idle(true)
	_run_cmdline_check_branch(args)


func _bind_foot_shadow() -> void:
	if backdrop_kind != BackdropKind.STUDIO_2_5D or _model == null:
		return
	var backdrop := get_node_or_null("Youyou2_5dBackdrop")
	if backdrop != null and backdrop.has_method("set_follow_target"):
		backdrop.call("set_follow_target", _model)


func _apply_backdrop_mode() -> void:
	var lobby := get_node_or_null("LobbySet") as Node3D
	var backdrop := get_node_or_null("Youyou2_5dBackdrop")
	var observe := get_node_or_null("ObservePivot")
	if backdrop_kind == BackdropKind.STUDIO_2_5D:
		if lobby != null:
			lobby.visible = false
		if backdrop != null:
			backdrop.visible = true
		if observe != null and observe.has_method("set_studio_2_5d_mode"):
			observe.call("set_studio_2_5d_mode", true)
			# 沙盒主场景 ObservePivot 默认膝上正交（见 youyou_observe_camera.gd STUDIO_*）
		var help := get_node_or_null("StatusLayer/ObserveHelp") as Label
		if help != null:
			help.text = "固定 2.5D 机位    R：重置镜头"
		PreviewVisualTuning.apply_studio_2_5d(self)
		_apply_hud_visual_cohesion()
	else:
		if lobby != null:
			lobby.visible = true
		if backdrop != null:
			backdrop.visible = false
		if observe != null and observe.has_method("set_studio_2_5d_mode"):
			observe.call("set_studio_2_5d_mode", false)
		var key_restore := get_node_or_null("KeyLight") as DirectionalLight3D
		if key_restore != null:
			key_restore.light_energy = 0.58
			key_restore.shadow_enabled = true
		var fill_restore := get_node_or_null("FillLight") as DirectionalLight3D
		if fill_restore != null:
			fill_restore.light_energy = 0.24
		var face_restore := get_node_or_null("ObservePivot/Camera3D/FaceFill") as OmniLight3D
		if face_restore != null:
			face_restore.light_energy = 0.14
	_apply_character_safe_ui_layout()


func _layout_bottom_left_label(label: Control, height: float, margin_bottom: float) -> void:
	label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	label.anchor_top = 1.0
	label.anchor_right = 0.0
	label.anchor_bottom = 1.0
	label.grow_horizontal = Control.GROW_DIRECTION_END
	label.offset_left = UI_SAFE_MARGIN
	label.offset_top = -(margin_bottom + height)
	label.offset_right = UI_SAFE_MARGIN + UI_SAFE_WIDTH
	label.offset_bottom = -margin_bottom


func _layout_ai_prompt_above_character() -> void:
	if _ai_player_prompt == null or not _ai_player_prompt.visible:
		return
	var vp := get_viewport().get_visible_rect().size
	if vp.x < 1.0 or vp.y < 1.0:
		return
	var width := minf(UI_AI_PROMPT_WIDTH, vp.x * 0.42)
	var height := UI_AI_PROMPT_HEIGHT
	var x := (vp.x - width) * 0.5
	var y := UI_AI_PROMPT_TOP
	var cam := get_viewport().get_camera_3d()
	var head := _ai_prompt_head_world()
	if cam != null and head != Vector3.INF and not cam.is_position_behind(head):
		var screen := cam.unproject_position(head + Vector3(0.0, UI_AI_PROMPT_HEAD_CLEARANCE, 0.0))
		x = screen.x - width * 0.5
		y = screen.y - height * 0.5
	var side_pad := 340.0
	if vp.x < side_pad * 2.0 + width:
		side_pad = maxf((vp.x - width) * 0.5, 8.0)
	x = clampf(x, side_pad, vp.x - width - side_pad)
	y = clampf(y, 6.0, vp.y * 0.28)
	_ai_player_prompt.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_ai_player_prompt.offset_left = x
	_ai_player_prompt.offset_top = y
	_ai_player_prompt.offset_right = x + width
	_ai_player_prompt.offset_bottom = y + height
	_ai_player_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ai_player_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _ai_prompt_head_world() -> Vector3:
	if _skeleton == null:
		return Vector3.INF
	var idx := _skeleton.find_bone(&"mixamorig_Head")
	if idx < 0:
		return Vector3.INF
	return _skeleton.global_transform * _skeleton.get_bone_global_pose(idx).origin


func _layout_top_left_label(label: Control, top: float, height: float) -> void:
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	label.anchor_right = 0.0
	label.offset_left = UI_SAFE_MARGIN
	label.offset_top = top
	label.offset_right = UI_SAFE_MARGIN + UI_SAFE_WIDTH
	label.offset_bottom = top + height


func _apply_character_safe_ui_layout() -> void:
	var help := get_node_or_null("StatusLayer/ObserveHelp") as Label
	if help != null:
		_layout_bottom_left_label(help, UI_HELP_HEIGHT, UI_HELP_BOTTOM)
		help.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if _result_banner != null:
		_layout_bottom_left_label(_result_banner, UI_GRAB_BANNER_HEIGHT, UI_GRAB_BANNER_BOTTOM)
		_result_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if _invite_listen_banner != null:
		_layout_bottom_left_label(_invite_listen_banner, UI_INVITE_BANNER_HEIGHT, UI_INVITE_BANNER_BOTTOM)
		_invite_listen_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if _ai_player_prompt != null:
		_layout_ai_prompt_above_character()


func _cmdline_args_for_checks() -> PackedStringArray:
	var merged := OS.get_cmdline_user_args()
	for arg in OS.get_cmdline_args():
		if arg not in merged:
			merged.append(arg)
	return merged


func _cmdline_wants_minigame_invite_headless(args: PackedStringArray) -> bool:
	return "--minigame-invite-halt-sync-check" in args or "--minigame-invite-phase-c-check" in args


func _cmdline_has_automated_check(args: PackedStringArray) -> bool:
	for arg in args:
		if arg.ends_with("-check") or arg == "--viseme-diagnose":
			return true
	return false


func _bootstrap_minigame_invite_headless() -> bool:
	if _invite_flow != null and _round_business != null and _event_perf != null:
		return true
	if _model == null:
		var anchor := Node3D.new()
		anchor.name = "HeadlessCheckAnchor"
		add_child(anchor)
		_model = anchor
	_meshes.clear()
	if _player == null and not _load_clips():
		return false
	if _face == null:
		_default_shapes = {}
		if not _meshes.is_empty():
			_default_shapes = FacePresenter.capture_zero_baseline(_meshes)
		_face = FacePresenter.new()
		_face.name = "YouyouFacePresenter"
		add_child(_face)
		_face.setup(_meshes, _default_shapes)
	_init_event_action_performance()
	_init_minigame_invite_flow()
	_ensure_standalone_business()
	return (
		_player != null
		and _event_perf != null
		and _show_adapter != null
		and _invite_flow != null
		and _round_business != null
	)


func _abort_minigame_invite_check(reason: String) -> void:
	push_error(reason)
	print("minigame_invite_check_aborted=", reason)
	get_tree().quit(1)


func _run_cmdline_check_branch(args: PackedStringArray) -> void:
	if "--phase-a-check" in args:
		_run_phase_a_check()
	elif "--batch-check" in args:
		_run_batch_check()
	elif "--idle-check" in args:
		_run_idle_check()
	elif "--new-anim-check" in args:
		_run_new_anim_check()
	elif "--approved-pool-check" in args:
		_run_approved_pool_check()
	elif "--schedule-check" in args:
		_schedule_enabled = true
		_mode = ScheduleMode.BASE_IDLE
		_arm_wait()
		_run_schedule_check()
	elif "--blend-check" in args:
		_schedule_enabled = true
		_mode = ScheduleMode.BASE_IDLE
		_arm_wait()
		_run_blend_check()
	elif "--pending-attract-check" in args:
		_schedule_enabled = true
		_mode = ScheduleMode.BASE_IDLE
		_arm_wait()
		_run_pending_attract_check()
	elif "--expression-check" in args:
		_schedule_enabled = true
		_mode = ScheduleMode.BASE_IDLE
		_arm_wait()
		_run_expression_check()
	elif "--expression-smooth-transition-check" in args:
		_run_expression_smooth_transition_check()
	elif "--expression-integration-check" in args:
		_run_expression_integration_check()
	elif "--expression-extension-check" in args:
		_run_expression_extension_check()
	elif "--expression-isolation-check" in args:
		_run_expression_isolation_check()
	elif "--viseme-check" in args:
		_run_viseme_check()
	elif "--viseme-diagnose" in args:
		_run_viseme_diagnose()
	elif "--viseme-coord-check" in args:
		_run_viseme_coord_check()
	elif "--performance-expression-check" in args:
		_schedule_enabled = true
		_mode = ScheduleMode.BASE_IDLE
		_arm_wait()
		_run_performance_expression_check()
	elif "--idle-presence-check" in args:
		_schedule_enabled = true
		_mode = ScheduleMode.BASE_IDLE
		_arm_wait()
		_run_idle_presence_check()
	elif "--preview-event-check" in args:
		_run_preview_event_check()
	elif "--precoin-schedule-check" in args:
		_run_precoin_schedule_check()
	elif "--grab-flow-check" in args:
		_run_grab_flow_check()
	elif "--minigame-invite-phase-a-check" in args:
		_run_minigame_invite_phase_a_check()
	elif "--minigame-invite-phase-b-check" in args:
		_run_minigame_invite_phase_b_check()
	elif "--minigame-invite-state-check" in args:
		_run_minigame_invite_state_check()
	elif "--minigame-invite-phase-c-check" in args:
		_run_minigame_invite_phase_c_check()
	elif "--minigame-invite-phase-d-check" in args:
		_run_minigame_invite_phase_d_check()
	elif "--minigame-invite-halt-sync-check" in args:
		_run_minigame_invite_halt_sync_check()
	elif "--coin-phase1-check" in args:
		_run_coin_phase1_check()
	elif "--success-continue-check" in args:
		_run_success_continue_check()
	elif "--fail-continue-check" in args:
		_run_fail_continue_check()
	elif "--preview-ai-voice-precoin-check" in args:
		pass
	elif "--preview-ai-voice-observability-check" in args:
		pass
	elif "--preview-ai-voice-status-check" in args:
		pass
	elif "--preview-ai-voice-phase2-regression" in args:
		pass
	elif "--formal-streaming-asr-check" in args:
		pass
	elif "--bailian-tts-isolated-check" in args:
		pass
	elif "--pcm16-stream-player-check" in args:
		pass
	elif "--voice-output-stream-tts-check" in args:
		pass
	elif "--voice-output-stream-tts-playback-check" in args:
		pass
	else:
		_start_precoin()
		if _idle_life != null:
			_idle_life.set_process(true)
			_sync_idle_presence()
		call_deferred("_ensure_standalone_business")


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		_note_ctrl(event as InputEventKey)
	if _handle_claw_stick_input(event):
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key := event as InputEventKey
	if _handle_round_keys(key):
		return
	if not PREVIEW_FACE_DEBUG_KEYS and not key.shift_pressed and _is_motion_debug_key(key):
		return
	if _invite_blocks_idle_schedule() and _is_idle_schedule_key(key):
		_note("[小游戏引导] 等待回答期间不接受待机或招揽按键")
		return
	if _grab_blocks_idle_schedule() and _is_idle_schedule_key(key):
		_note("[抓取] 抓取阶段不接受待机或招揽按键")
		return
	if (_claw_stick_control_active() and _is_wasd_key(key)) or (
		CLAW_JOYSTICK_X_INPUT and (_is_wasd_key(key) or _is_grab_action_key(key))
	):
		return
	if _should_block_wasd() and _is_wasd_key(key):
		if _grab_flow != null and _grab_flow.blocks_wasd_variants():
			_play_claw_move(key)
		return
	if IDLE_VARIANTS.has(event.keycode):
		_play_idle_variant(String(IDLE_VARIANTS[event.keycode]))
		return
	if BATCH_ONESHOTS.has(event.keycode):
		_play_batch_oneshot(String(BATCH_ONESHOTS[event.keycode]))
		return
	if EMOTE_KEYS.has(event.keycode):
		_apply_emote(String(EMOTE_KEYS[event.keycode]))
		return
	if EXTENDED_EMOTE_KEYS.has(event.keycode):
		_apply_emote(String(EXTENDED_EMOTE_KEYS[event.keycode]))
		return
	if VISEME_KEYS.has(event.keycode):
		_apply_viseme(String(VISEME_KEYS[event.keycode]))
		return
	if PREVIEW_EVENT_KEYS.has(event.keycode):
		_event_play_token += 1
		_play_preview_event(String(PREVIEW_EVENT_KEYS[event.keycode]), _event_play_token)
		return
	match event.keycode:
		KEY_BACKSPACE:
			_clear_viseme()
			return
		KEY_I:
			if _precoin_enabled:
				_resume_precoin_from_i()
			elif _schedule_enabled:
				_resume_auto_from_i()
			else:
				_start_idle(false)
		KEY_M:
			if CLAW_JOYSTICK_X_INPUT and not _vad_ab_dev_keyboard():
				return
			if _precoin_enabled:
				_simulate_player_enter_interaction()
			elif _schedule_enabled:
				_on_player_passed()
		KEY_H:
			_start_hello()
		KEY_0:
			_restore_default_expression()
		KEY_U:
			_request_missing_animation()
		KEY_Y:
			_apply_emote("missing_expression_probe")
		KEY_F12:
			if event.shift_pressed:
				_run_viseme_diagnose()


func _process(delta: float) -> void:
	_layout_ai_prompt_above_character()
	_poll_voice_silence_leave()
	_sync_voice_panel_situation()
	_debug_panel_accum += delta
	if _debug_panel_accum >= 0.2:
		_debug_panel_accum = 0.0
		_refresh_debug_panel()
	if _player == null:
		return
	if _grab_blocks_idle_schedule():
		_sync_idle_presence()
		return
	if _precoin_enabled and _precoin != null and not _event_playing:
		_precoin.poll_playback(String(_player.assigned_animation), _player.is_playing())
	if _event_playing:
		_sync_idle_presence()
		return
	if _schedule_enabled:
		_poll_pending_attract_on_basic_idle_cycle()
	if _schedule_enabled and (_mode == ScheduleMode.LIGHT_IDLE or _mode == ScheduleMode.ATTRACT):
		if _active_finish_anim != "" and _player.assigned_animation == _active_finish_anim and not _player.is_playing():
			_on_auto_performance_finished()
		_sync_idle_presence()
		return
	if _hello_active and _player.assigned_animation == HELLO_ANIM and not _player.is_playing():
		if _performance_pose.consume_hello_end(_hello_perf_gen):
			_note("招揽播放结束，表现层回到待机。")
			_hello_active = false
			_start_idle(true)
		_sync_idle_presence()
		return
	if _oneshot_name != "" and _player.assigned_animation == _oneshot_name and not _player.is_playing():
		_note("单次动画结束，表现层回到待机：" + _oneshot_name)
		_start_idle(true)
	_sync_idle_presence()


func _load_model() -> bool:
	var packed := load(MODEL_PATH) as PackedScene
	if packed == null:
		_fail("模型加载失败：" + MODEL_PATH)
		return false
	var instance := packed.instantiate()
	if not instance is Node3D:
		_fail("模型根节点不是 Node3D：" + MODEL_PATH)
		instance.free()
		return false
	_model = instance as Node3D
	_model.name = "YouyouModel"
	add_child(_model)
	_skeleton = _model.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
	if _skeleton == null:
		_fail("未找到骨架 Armature/Skeleton3D。")
		return false
	if _skeleton.find_bone("mixamorig_Hips") < 0:
		_fail("骨架中没有 mixamorig_Hips，动画轨道无法对应。")
		return false
	_equip_outfit()
	_collect_meshes(_model)
	if _meshes.is_empty():
		_fail("模型中没有网格，无法设置表情。")
		return false
	_hide_headphones()
	return true


func _load_clips() -> bool:
	if not Approved.load_config():
		_fail("无法加载已验收动作配置，基础待机仍会播放。")
	var idle_clip := _take_clip(IDLE_SCENE_PATH, IDLE_ANIM)
	if idle_clip == null:
		return false
	idle_clip = _apply_preview_body_replacement(IDLE_ANIM, idle_clip)
	idle_clip.loop_mode = Animation.LOOP_LINEAR
	_reference_bones = _bones_in_clip(idle_clip)
	_player = AnimationPlayer.new()
	_player.name = "PreviewAnimationPlayer"
	_player.process_priority = 0
	_player.playback_default_blend_time = 0.0
	_model.add_child(_player)
	var library := AnimationLibrary.new()
	library.add_animation(IDLE_ANIM, idle_clip)
	for action_id in Approved.all_whitelisted_action_ids():
		if not _add_approved_clip(library, action_id):
			push_error("动作 clip 接入失败，跳过：" + action_id)
	_player.add_animation_library(&"", library)
	_player.animation_finished.connect(_on_animation_finished)
	_build_schedule_pools()
	if not _player.has_animation(HELLO_ANIM):
		_note("键盘 H 使用已验收招揽：" + HELLO_ANIM + "（需成功接入动画库）。")
	if _general_light_pool.is_empty() or _light_pool.is_empty() or _attract_pool.is_empty():
		_fail("有动作池为空，基础待机仍会播放。")
	return true


func _show_boot_wait(message: String) -> void:
	if _status_label == null:
		return
	_status_label.text = message
	_status_label.visible = true


func _hide_boot_wait() -> void:
	if _status_label == null:
		return
	_status_label.visible = false
	_status_label.text = ""


func _relax_mobile_environment() -> void:
	var env_node := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if env_node == null or env_node.environment == null:
		return
	var env := env_node.environment
	env.ssr_enabled = false
	env.ssao_enabled = false
	env.glow_enabled = false


func _take_clip(scene_path: String, anim_name: String) -> Animation:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		_fail("动画场景加载失败：" + scene_path)
		return null
	var instance := packed.instantiate()
	var source := instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if source == null or not source.has_animation(anim_name):
		var available := ""
		if source != null:
			available = ",".join(source.get_animation_list())
		_fail("动画不存在：" + anim_name + "，文件：" + scene_path + "，实际列表：" + available)
		instance.free()
		return null
	var clip := (source.get_animation(anim_name) as Animation).duplicate(true) as Animation
	instance.free()
	return clip


func _clip_location(display_name: String) -> Dictionary:
	if CLIP_ALIASES.has(display_name):
		return CLIP_ALIASES[display_name]
	return {
		"scene": "res://待机Animation/%s.glb" % display_name,
		"source": display_name,
	}


func _add_approved_clip(library: AnimationLibrary, action_id: String) -> bool:
	var check: Dictionary = Approved.validate_for_play(action_id)
	if not bool(check.get("ok", false)):
		for err in check.get("errors", []):
			push_error("%s: %s" % [action_id, str(err)])
		return false
	var clip := Approved.take_animation_clip(action_id)
	if clip == null:
		push_error("clip 提取失败：" + action_id)
		return false
	clip = _apply_preview_body_replacement(action_id, clip)
	clip.loop_mode = Animation.LOOP_NONE
	library.add_animation(action_id, clip)
	var reg: Dictionary = Approved.get_clip_registry(action_id)
	_report_track_compatibility(action_id, clip, String(reg.get("source_anim", action_id)))
	return true


func _apply_preview_body_replacement(action_id: String, original: Animation) -> Animation:
	if not PREVIEW_BODY_REPLACEMENTS.has(action_id):
		return original
	var scene_path := String(PREVIEW_BODY_REPLACEMENTS[action_id])
	var replacement := _take_clip(scene_path, action_id)
	if replacement == null:
		_fail("%s 修复动作加载失败，继续使用原片" % action_id)
		return original
	var new_length := replacement.length
	_retarget_skeleton_paths(original, replacement)
	var kept := _copy_expression_tracks(original, replacement)
	replacement.length = new_length
	_note("%s 已换修复骨骼 %s；表情登记未改，原片表情轨道 %d 条（原长 %.3f / 新长 %.3f）" % [
		action_id, scene_path, kept, original.length, new_length,
	])
	return replacement


func _retarget_skeleton_paths(original: Animation, replacement: Animation) -> void:
	var from_root := _track_node_path(replacement, "mixamorig_Hips")
	var to_root := _track_node_path(original, "mixamorig_Hips")
	if from_root == "" or to_root == "" or from_root == to_root:
		return
	for index in replacement.get_track_count():
		var path := replacement.track_get_path(index)
		var node := String(path.get_concatenated_names())
		if node != from_root and not node.begins_with(from_root + "/"):
			continue
		var rebuilt := to_root + node.substr(from_root.length())
		var bone := String(path.get_concatenated_subnames())
		if bone != "":
			rebuilt += ":" + bone
		replacement.track_set_path(index, NodePath(rebuilt))


func _track_node_path(anim: Animation, bone_name: String) -> String:
	for index in anim.get_track_count():
		var path := anim.track_get_path(index)
		if String(path.get_concatenated_subnames()) == bone_name:
			return String(path.get_concatenated_names())
	return ""


func _is_expression_track(anim: Animation, index: int) -> bool:
	if anim.track_get_type(index) == Animation.TYPE_BLEND_SHAPE:
		return true
	return ":weights" in str(anim.track_get_path(index))


func _copy_expression_tracks(original: Animation, replacement: Animation) -> int:
	for index in range(replacement.get_track_count() - 1, -1, -1):
		if _is_expression_track(replacement, index):
			replacement.remove_track(index)
	var kept := 0
	for index in original.get_track_count():
		if not _is_expression_track(original, index):
			continue
		_copy_animation_track(original, index, replacement)
		kept += 1
	return kept


func _copy_animation_track(src: Animation, src_index: int, dst: Animation) -> void:
	var dst_index := dst.add_track(src.track_get_type(src_index))
	dst.track_set_path(dst_index, src.track_get_path(src_index))
	dst.track_set_interpolation_type(dst_index, src.track_get_interpolation_type(src_index))
	dst.track_set_interpolation_loop_wrap(dst_index, src.track_get_interpolation_loop_wrap(src_index))
	dst.track_set_enabled(dst_index, src.track_is_enabled(src_index))
	for key_index in src.track_get_key_count(src_index):
		dst.track_insert_key(
			dst_index,
			src.track_get_key_time(src_index, key_index),
			src.track_get_key_value(src_index, key_index),
			src.track_get_key_transition(src_index, key_index),
		)


func _add_mapped_clip(library: AnimationLibrary, display_name: String, loop_mode: Animation.LoopMode) -> void:
	var location := _clip_location(display_name)
	var clip := _take_clip(String(location["scene"]), String(location["source"]))
	if clip == null:
		return
	clip.loop_mode = loop_mode
	library.add_animation(display_name, clip)
	if display_name in NEW_CLIP_NAMES:
		_report_track_compatibility(display_name, clip, String(location["source"]))


func _bones_in_clip(clip: Animation) -> Dictionary:
	var bones := {}
	for index in clip.get_track_count():
		var bone := String(clip.track_get_path(index).get_concatenated_subnames())
		if bone != "":
			bones[bone] = true
	return bones


func _report_track_compatibility(display_name: String, clip: Animation, source_name: String) -> void:
	if _skeleton == null:
		return
	var bones := _bones_in_clip(clip)
	var missing: PackedStringArray = []
	var extra: PackedStringArray = []
	for bone_name in bones.keys():
		var bone := String(bone_name)
		if _skeleton.find_bone(bone) < 0:
			missing.append(bone)
		elif not _reference_bones.has(bone):
			extra.append(bone)
	var hips := bones.has("mixamorig_Hips")
	var summary := "%s source=%s tracks=%d bones=%d hips=%s missing=%d extra=%d" % [
		display_name, source_name, clip.get_track_count(), bones.size(), hips, missing.size(), extra.size()
	]
	if missing.size() > 0:
		summary += " missing_bones=" + ",".join(missing.slice(0, 8))
	if extra.size() > 0:
		summary += " extra_bones=" + ",".join(extra.slice(0, 8))
	_compat_lines.append(summary)
	if not hips:
		_fail(display_name + " 没有 mixamorig_Hips 轨道，不能确认它驱动当前骨架。")
	elif missing.size() > 0:
		_fail(display_name + " 有轨道指向当前骨架不存在的骨骼：" + ",".join(missing.slice(0, 8)))
	else:
		_note(display_name + " 轨道与当前骨架兼容，展示名已映射，源动画名 " + source_name + "。")


func _equip_outfit() -> void:
	var packed := load(CLOTHES_PATH) as PackedScene
	if packed == null:
		_fail("新衣服加载失败，继续使用原衣服：" + CLOTHES_PATH)
		return
	var inst := packed.instantiate()
	var outfit := _find_skinned_mesh(inst)
	if outfit == null:
		_fail("新衣服里没有带蒙皮的网格，继续使用原衣服：" + CLOTHES_PATH)
		inst.free()
		return
	var missing := _missing_skin_bones(outfit)
	if not missing.is_empty():
		_fail("新衣服骨骼对不上身体骨架，继续使用原衣服：" + ",".join(missing.slice(0, 8)))
		inst.free()
		return
	var old := _skeleton.get_node_or_null("衣服") as MeshInstance3D
	if old != null:
		_skeleton.remove_child(old)
		old.free()
	var previous_parent := outfit.get_parent()
	if previous_parent != null:
		previous_parent.remove_child(outfit)
	outfit.owner = null
	outfit.name = "衣服"
	_skeleton.add_child(outfit)
	outfit.skeleton = outfit.get_path_to(_skeleton)
	inst.free()
	_note("已换上新衣服。")


func _find_skinned_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and (node as MeshInstance3D).skin != null:
		return node
	for child in node.get_children():
		var found := _find_skinned_mesh(child)
		if found != null:
			return found
	return null


func _missing_skin_bones(mesh: MeshInstance3D) -> PackedStringArray:
	var missing: PackedStringArray = []
	var skin := mesh.skin
	if skin == null:
		return missing
	var named := 0
	for i in skin.get_bind_count():
		var bone_name := String(skin.get_bind_name(i))
		if bone_name == "":
			continue
		named += 1
		if _skeleton.find_bone(bone_name) < 0:
			missing.append(bone_name)
	if named == 0:
		missing.append("皮肤没有骨骼名")
	return missing


func _apply_floor_alignment() -> void:
	if _model == null or _skeleton == null or _player == null:
		return
	var min_y := INF
	for anim_name in FLOOR_ALIGN_ANIMS:
		if not _player.has_animation(anim_name):
			continue
		min_y = minf(min_y, _sample_lowest_shoe_y(anim_name, 10))
	if not is_finite(min_y) or min_y >= FLOOR_SOLE_CLEARANCE:
		return
	var lift := FLOOR_SOLE_CLEARANCE - min_y
	_model.position.y += lift
	_note("鞋底贴地校正：抬高 %.1f mm。" % (lift * 1000.0))


func _sample_lowest_shoe_y(anim_name: String, samples: int) -> float:
	var clip := _player.get_animation(anim_name) as Animation
	var length := maxf(clip.length, 0.0001)
	var min_y := INF
	var count := maxi(samples, 1)
	_player.play(anim_name)
	for i in count:
		var t := 0.0
		if count > 1:
			t = length * float(i) / float(count - 1)
		if i == count - 1 and length > 0.05:
			t = maxf(length - 0.02, 0.0)
		_player.seek(t, true)
		_player.advance(0.0)
		min_y = minf(min_y, _lowest_shoe_world_y())
	_player.stop()
	return min_y


func _lowest_shoe_world_y() -> float:
	var lowest := INF
	for node in _model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if String(mesh.name) not in SHOE_MESH_NAMES or mesh.mesh == null or mesh.skin == null:
			continue
		lowest = minf(lowest, _skinned_mesh_min_world_y(mesh))
	return lowest


func _skinned_mesh_min_world_y(mesh: MeshInstance3D) -> float:
	var arrays: Array = mesh.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	if verts.is_empty() or bones.is_empty() or weights.is_empty():
		return INF
	var skin := mesh.skin
	var bind_xforms: Array[Transform3D] = []
	bind_xforms.resize(skin.get_bind_count())
	for i in skin.get_bind_count():
		var bone_index := skin.get_bind_bone(i)
		if bone_index < 0:
			bone_index = _skeleton.find_bone(String(skin.get_bind_name(i)))
		if bone_index < 0:
			bind_xforms[i] = Transform3D.IDENTITY
		else:
			bind_xforms[i] = _skeleton.get_bone_global_pose(bone_index) * skin.get_bind_pose(i)
	var min_y := INF
	var world := _skeleton.global_transform
	for v in verts.size():
		var point := Vector3.ZERO
		var weight_sum := 0.0
		for k in 4:
			var weight := weights[v * 4 + k]
			if weight <= 0.0001:
				continue
			var bind_index := bones[v * 4 + k]
			if bind_index < 0 or bind_index >= bind_xforms.size():
				continue
			point += bind_xforms[bind_index] * verts[v] * weight
			weight_sum += weight
		if weight_sum <= 0.0:
			continue
		min_y = minf(min_y, (world * (point / weight_sum)).y)
	return min_y


func _hide_headphones() -> void:
	var hidden := 0
	for mesh in _meshes:
		if String(mesh.name) == "耳机":
			mesh.visible = false
			hidden += 1
	if hidden == 0:
		_fail("未找到耳机网格，无法隐藏。")


func _collect_meshes(node: Node) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		_meshes.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child)


func _init_face_presenter() -> void:
	_face = FacePresenter.new()
	_face.name = "YouyouFacePresenter"
	add_child(_face)
	_face.setup(_meshes, _default_shapes)
	_face.configure_patch_readiness(_patch_apply_result.get("diagnostics", []))
	_face.apply_approved_coefficients()
	_face.configure_performance_blend(FacePresenter.TRANSITION_BLEND_TIME_DEFAULT)
	_face.clear_to_neutral(0.0)
	_note("面部表现：拆分 Eyes_*/Mouth_*；基础待机无主表情，眨眼/转眼仍由待机生命感驱动。")


func _init_approved_performance() -> void:
	_approved_perf = ApprovedPerformance.new()
	_approved_perf.name = "ApprovedActionPerformance"
	add_child(_approved_perf)
	_approved_perf.call("setup", self, _player, _face)


func _init_event_action_performance() -> void:
	_event_perf = EventActionPerformance.new()
	_event_perf.name = "EventActionPerformance"
	add_child(_event_perf)
	_event_perf.setup(self, _player, _face, IDLE_ANIM)
	if not _event_perf.performance_finished.is_connected(_on_event_performance_finished):
		_event_perf.performance_finished.connect(_on_event_performance_finished)
	if not _event_perf.performance_failed.is_connected(_on_event_performance_failed):
		_event_perf.performance_failed.connect(_on_event_performance_failed)
	_show_adapter = ClawShowAdapter.new()
	_show_adapter.name = "ClawShowAdapter"
	add_child(_show_adapter)
	_show_adapter.setup(_event_perf, self)


func halt_stale_invite_for_show() -> void:
	if _invite_flow != null and _invite_flow.has_method("halt_for_other_show"):
		_invite_flow.halt_for_other_show()


## 其他演出抢占小游戏引导/监听：结束业务 invite_listen，不算明确拒绝。
func sync_business_invite_preempted_by_show() -> void:
	if _round_business != null and _round_business.is_invite_listen():
		minigame_invite_cancelled(false)
	else:
		_clear_invite_listen_banner()


func prepare_business_event() -> void:
	_prepare_business_event(false)


func prepare_business_event_from_show() -> void:
	_prepare_business_event(true)


func _prepare_business_event(from_show: bool) -> void:
	_preview_ai_preempt("business_event")
	if not _event_playing:
		_saved_mode_before_event = _mode
		_resume_schedule_after_event = _schedule_enabled
	if _grab_flow != null:
		_grab_flow.stop_ambient()
	if _precoin_enabled and _precoin != null:
		_precoin.enter_business(from_show)
	_enter_manual()
	_event_playing = true


func _play_preview_event(action_id: String, token: int) -> void:
	if _event_perf == null:
		_fail("事件表现未初始化。")
		return
	_preview_event_token = token
	prepare_business_event()
	_note("请求事件动作 %s（token=%d）。" % [action_id, token])
	if SplitTimelines.has_timeline(action_id):
		_push_split_idle_life_suppression()
	if not _event_perf.play_event(action_id, token):
		if SplitTimelines.has_timeline(action_id):
			_pop_split_idle_life_suppression()
		_event_playing = false
		if _precoin_enabled and _precoin != null:
			_precoin.resume_after_preview_package()
		else:
			_restore_schedule_after_event()


func _on_event_performance_finished(token: int, action_id: String, reason: String) -> void:
	if not _event_playing:
		return
	if SplitTimelines.has_timeline(action_id):
		_pop_split_idle_life_suppression()
	_event_playing = false
	_note("事件动作完成 %s token=%d（%s）。" % [action_id, token, reason])
	if _precoin_enabled and _precoin != null:
		if token == _preview_event_token:
			_preview_event_token = -1
			_precoin.resume_after_preview_package()
		else:
			_note("[待机] 业务接管保持，不自行恢复待机调度")
		_sync_idle_presence()
		return
	_restore_schedule_after_event()


func _on_event_performance_failed(token: int, action_id: String, code: String, message: String) -> void:
	if _event_playing:
		_event_playing = false
	_fail("事件动作失败 %s token=%d [%s]: %s" % [action_id, token, code, message])
	if _precoin_enabled and _precoin != null:
		if token == _preview_event_token:
			_preview_event_token = -1
			_precoin.resume_after_preview_package()
		_sync_idle_presence()
		return
	_restore_schedule_after_event()


func get_claw_show_adapter() -> YouyouClawShowAdapter:
	_show_claimed = true
	return _show_adapter


func get_event_action_performance() -> YouyouEventActionPerformance:
	return _event_perf


func _restore_schedule_after_event() -> void:
	_sync_performance_base_idle()
	if _resume_schedule_after_event and _saved_mode_before_event != ScheduleMode.MANUAL_TEST:
		_mode = _saved_mode_before_event
		if _schedule_enabled:
			_arm_wait()
	else:
		_mode = ScheduleMode.MANUAL_TEST


func _init_performance_pose_controller() -> void:
	_performance_pose = PerformancePoseController.new()
	_performance_pose.name = "YouyouPerformancePoseController"
	add_child(_performance_pose)
	_performance_pose.setup(
		_face,
		func() -> bool:
			return _face != null and _face.get_active_viseme() != ""
	)
	_performance_pose.apply_pose(PerformancePoseController.POSE_BASE_IDLE, true)
	_emotion_restore_primary = FacePresenter.NEUTRAL_EMOTION_ID


func _sync_performance_base_idle() -> void:
	if _performance_pose == null:
		return
	if _performance_pose.apply_pose(PerformancePoseController.POSE_BASE_IDLE):
		_emotion_restore_primary = _performance_pose.sync_emotion_restore_primary()


func _apply_viseme(viseme_id: String) -> void:
	if _face == null:
		_fail("面部控制器未初始化。")
		return
	if _face.get_active_viseme() == "":
		_emotion_restore_primary = _face.get_emotion_restore_primary()
	if not _face.set_viseme(viseme_id):
		_fail("口型不存在或不受支持：" + viseme_id)
		return
	_note("口型 %s，强度 1.0，过渡 %.2f 秒。" % [viseme_id, FacePresenter.VISEME_BLEND_TIME])


func _clear_viseme() -> void:
	if _face == null or _viseme_clear_busy:
		return
	_viseme_clear_busy = true
	_run_clear_viseme_coordinator()


func _run_clear_viseme_coordinator() -> void:
	var blend := FacePresenter.VISEME_BLEND_TIME
	_face.clear_viseme(blend)
	await get_tree().create_timer(blend + 0.08).timeout
	if not _face.all_visemes_near_zero(0.03):
		_face.clear_viseme(0.0)
		_note("口型二次清零。")
	else:
		_note("已清除口型，情绪由面部模块恢复：" + _face.get_active_emotion())
	_viseme_clear_busy = false


func _is_gaze_emote(shape_name: String) -> bool:
	return shape_name in FacePresenter.GAZE_KEYS


func _is_split_emote(shape_name: String) -> bool:
	return shape_name in FacePresenter.SPLIT_EMOTION_IDS


func _start_idle(from_hello_end: bool) -> void:
	_stop_approved_performance()
	_hello_active = false
	_oneshot_name = ""
	if _player == null or not _player.has_animation(IDLE_ANIM):
		_fail("无法播放待机，动画不存在：" + IDLE_ANIM)
		return
	if not from_hello_end and _player.assigned_animation == IDLE_ANIM and _player.is_playing():
		_note("待机已在播放，忽略重复请求。")
		return
	if not from_hello_end:
		_performance_pose.invalidate_hello()
	var blend := _blend_into_idle()
	_play_clip(IDLE_ANIM, blend)
	_sync_performance_base_idle()
	_note("播放待机 %s，混合 %.2f 秒，循环。" % [IDLE_ANIM, blend])


func _start_hello() -> void:
	_enter_manual()
	_oneshot_name = ""
	if _player == null or not _player.has_animation(HELLO_ANIM):
		_fail("无法播放招揽，动画不存在：" + HELLO_ANIM)
		_start_idle(true)
		return
	var restarting := _player.assigned_animation == HELLO_ANIM and _player.is_playing()
	_hello_perf_gen = _performance_pose.begin_hello_performance(false)
	_hello_active = true
	_play_clip(HELLO_ANIM, BLEND_MANUAL)
	_start_approved_performance(HELLO_ANIM, _hello_perf_gen)
	_emotion_restore_primary = String(
		Approved.get_params(HELLO_ANIM).get("emotion_id", _performance_pose.sync_emotion_restore_primary())
	)
	if restarting:
		_note("招揽尚未结束，已从头混合重播。")
	else:
		_note("播放招揽 %s，混合 %.2f 秒，单次。结束后只恢复表现。" % [HELLO_ANIM, BLEND_MANUAL])


func _play_idle_variant(anim_name: String) -> void:
	_enter_manual()
	if not _is_approved_action(anim_name):
		_fail("未验收待机动作，正式场景拒绝播放：" + anim_name)
		return
	if _player == null or not _player.has_animation(anim_name):
		_fail("无法播放待机变体，动画不存在：" + anim_name)
		return
	var restarting := _player.assigned_animation == anim_name and _player.is_playing()
	_hello_active = false
	_oneshot_name = ""
	_manual_perf_gen = _performance_pose.bump_auto_session()
	_play_clip(anim_name, BLEND_MANUAL)
	_start_approved_performance(anim_name, _manual_perf_gen)
	if restarting:
		_note("待机变体已从头混合重播：" + anim_name)
	else:
		_note("播放 %s，混合 %.2f 秒，副本循环。按 I 回到 Basic_Idle。" % [anim_name, BLEND_MANUAL])


func _play_batch_oneshot(anim_name: String) -> void:
	_enter_manual()
	if not _is_approved_action(anim_name):
		_fail("未验收招揽/单次动作，正式场景拒绝播放：" + anim_name)
		return
	if _player == null or not _player.has_animation(anim_name):
		_fail("无法播放单次动画，动画不存在：" + anim_name)
		_start_idle(true)
		return
	var restarting := _player.assigned_animation == anim_name and _player.is_playing()
	_hello_active = false
	_oneshot_name = anim_name
	_manual_perf_gen = _performance_pose.bump_auto_session()
	_play_clip(anim_name, BLEND_MANUAL)
	_start_approved_performance(anim_name, _manual_perf_gen)
	if restarting:
		_note("单次动画尚未结束，已从头混合重播：" + anim_name)
	else:
		_note("播放单次动画 %s，混合 %.2f 秒。结束后回到待机。" % [anim_name, BLEND_MANUAL])


func _on_animation_finished(anim_name: StringName) -> void:
	var finished := String(anim_name)
	if _event_playing and _event_perf != null:
		_event_perf.notify_animation_finished(anim_name)
	if _grab_blocks_idle_schedule():
		return
	if _precoin_enabled and _precoin != null and not _event_playing:
		if _precoin.notify_animation_finished(finished):
			return
	if _schedule_enabled and (_mode == ScheduleMode.LIGHT_IDLE or _mode == ScheduleMode.ATTRACT):
		if anim_name != StringName(_active_finish_anim):
			return
		if not _performance_pose.auto_finish_may_run(_auto_perf_gen):
			return
		if _approved_perf != null:
			_approved_perf.call("on_action_animation_finished", finished, _auto_perf_gen)
		_on_auto_performance_finished()
		return
	if anim_name == HELLO_ANIM and _hello_active:
		if not _performance_pose.consume_hello_end(_hello_perf_gen):
			return
		if _approved_perf != null:
			_approved_perf.call("on_action_animation_finished", finished, _hello_perf_gen)
		_note("收到招揽结束信号，表现层回到待机。")
		_hello_active = false
		_start_idle(true)
		return
	if _oneshot_name != "" and anim_name == StringName(_oneshot_name):
		if _approved_perf != null:
			_approved_perf.call("on_action_animation_finished", finished, _manual_perf_gen)
		_note("收到单次动画结束信号，表现层回到待机：" + _oneshot_name)
		_start_idle(true)


func _apply_emote(shape_name: String) -> void:
	if _face == null:
		_fail("面部控制器未初始化。")
		return
	var ok := false
	if _is_gaze_emote(shape_name):
		ok = _face.set_gaze(shape_name)
	elif _is_split_emote(shape_name):
		ok = _face.set_emotion(shape_name)
	else:
		_fail("表情形态键不存在或不受支持：" + shape_name)
		return
	if not ok:
		_fail("表情形态键不存在或不受支持：" + shape_name)
		return
	_emotion_restore_primary = _face.get_emotion_restore_primary()
	var blend_note := _face.get_last_blend_duration() if _face != null else FacePresenter.VISEME_BLEND_TIME
	_note("表情切换到 " + shape_name + "，过渡 " + str(blend_note) + " 秒。")
	_sync_idle_presence()


func _restore_default_expression() -> void:
	if _face == null:
		return
	if _face.get_active_viseme() != "":
		_emotion_restore_primary = FacePresenter.NEUTRAL_EMOTION_ID
		_clear_viseme()
		return
	_face.clear_to_neutral(FacePresenter.VISEME_BLEND_TIME)
	_performance_pose.note_pose(PerformancePoseController.POSE_BASE_IDLE)
	_emotion_restore_primary = FacePresenter.NEUTRAL_EMOTION_ID
	_note("已恢复基础待机脸（无主表情，眨眼/转眼仍由待机生命感驱动）。")
	_sync_idle_presence()


func _request_missing_animation() -> void:
	_enter_manual()
	var missing_name := "missing_animation_probe"
	if _player != null and _player.has_animation(missing_name):
		_play_clip(missing_name, 0.0)
		return
	_fail("请求了不存在的动画：" + missing_name)
	if _player == null or not _player.is_playing():
		_start_idle(true)


func _ensure_wait_timer() -> void:
	_wait_timer = Timer.new()
	_wait_timer.name = "LightIdleWait"
	_wait_timer.one_shot = true
	_wait_timer.timeout.connect(_on_light_wait_timeout)
	add_child(_wait_timer)


func _build_schedule_pools() -> void:
	_general_light_pool = _build_validated_pool(Approved.get_general_light_whitelist(), "通用轻待机")
	_light_pool = _build_validated_pool(Approved.get_light_idle_whitelist(), "专属轻待机")
	_attract_pool = _build_validated_pool(Approved.get_attract_whitelist(), "招揽")


func _combined_light_pool() -> PackedStringArray:
	var combined := _general_light_pool.duplicate()
	for action_id in _light_pool:
		if action_id not in combined:
			combined.append(action_id)
	return combined


func _is_light_idle_anim(anim_name: String) -> bool:
	return anim_name in _general_light_pool or anim_name in _light_pool


func _build_validated_pool(whitelist: PackedStringArray, label: String) -> PackedStringArray:
	var found := PackedStringArray()
	for action_id in whitelist:
		var check: Dictionary = Approved.validate_for_play(action_id)
		if not bool(check.get("ok", false)):
			for err in check.get("errors", []):
				push_error("%s池跳过 %s: %s" % [label, action_id, str(err)])
			continue
		if _player == null or not _player.has_animation(action_id):
			push_error("%s池跳过 %s: 动画未接入" % [label, action_id])
			continue
		found.append(action_id)
	if found.is_empty():
		_fail("%s池为空：无有效已验收动作。" % label)
	return found


func _is_approved_action(anim_name: String) -> bool:
	return bool(Approved.validate_for_play(anim_name).get("ok", false))


func _stop_approved_performance() -> void:
	if _approved_perf != null:
		_approved_perf.call("stop")


func _start_approved_performance(anim_name: String, session_gen: int) -> void:
	if _approved_perf == null:
		return
	if not _is_approved_action(anim_name):
		push_error("拒绝播放未验收动作：" + anim_name)
		return
	if SplitTimelines.has_timeline(anim_name):
		_push_split_idle_life_suppression()
	if not bool(_approved_perf.call("start", anim_name, session_gen)):
		push_error("已验收表演启动失败：" + anim_name)
		if SplitTimelines.has_timeline(anim_name):
			_pop_split_idle_life_suppression()


func _push_split_idle_life_suppression() -> void:
	_split_idle_life_suppressed += 1
	if _split_idle_life_suppressed == 1 and _idle_life != null:
		_idle_life.call("set_performance_state", IdleLife.PerfState.PERFORMANCE)


func _pop_split_idle_life_suppression() -> void:
	if _split_idle_life_suppressed <= 0:
		return
	_split_idle_life_suppressed -= 1
	if _split_idle_life_suppressed == 0 and _idle_life != null:
		_idle_life.call("set_performance_state", IdleLife.PerfState.BASE_IDLE)


func _enter_manual() -> void:
	_stop_approved_performance()
	if _wait_timer != null:
		_wait_timer.stop()
	if _precoin_enabled and _precoin != null and not _precoin.is_business():
		_precoin.suspend_for_manual()
	_clear_pending_attract()
	_restore_light_loops()
	_active_finish_anim = ""
	_mode = ScheduleMode.MANUAL_TEST
	_hello_active = false
	_oneshot_name = ""
	if _performance_pose != null:
		_performance_pose.invalidate_hello()
		_performance_pose.invalidate_auto()


func _resume_auto_from_i() -> void:
	var already_waiting := _mode == ScheduleMode.BASE_IDLE and _wait_timer != null and not _wait_timer.is_stopped() and _player != null and _player.assigned_animation == IDLE_ANIM and _player.is_playing()
	if already_waiting:
		_note("自动待机已在进行。")
		return
	if _wait_timer != null:
		_wait_timer.stop()
	_clear_pending_attract()
	_restore_light_loops()
	_active_finish_anim = ""
	_mode = ScheduleMode.BASE_IDLE
	_start_idle(false)
	if _player == null or _player.assigned_animation != IDLE_ANIM or not _player.is_playing():
		_mode = ScheduleMode.MANUAL_TEST
		return
	_arm_wait()


func _on_player_passed() -> void:
	_queue_pending_attract()


func _queue_pending_attract() -> void:
	if _mode == ScheduleMode.ATTRACT or _mode == ScheduleMode.MANUAL_TEST:
		_note("当前不能插入招揽，忽略 M。")
		return
	if _mode != ScheduleMode.BASE_IDLE and _mode != ScheduleMode.LIGHT_IDLE:
		return
	if _pending_attract_request:
		_note("已有待处理招揽，忽略 M。")
		return
	_pending_attract_request = true
	if _wait_timer != null:
		_wait_timer.stop()
	if _mode == ScheduleMode.BASE_IDLE and _player.assigned_animation == IDLE_ANIM:
		_basic_idle_prev_pos = _player.current_animation_position
	else:
		_basic_idle_prev_pos = -1.0
	_note("已记录玩家经过，当前动作自然结束后再播放招揽。")


func _clear_pending_attract() -> void:
	_pending_attract_request = false
	_basic_idle_prev_pos = -1.0


func _poll_pending_attract_on_basic_idle_cycle() -> void:
	if not _pending_attract_request or _mode != ScheduleMode.BASE_IDLE:
		_basic_idle_prev_pos = -1.0
		return
	if _player.assigned_animation != IDLE_ANIM or not _player.is_playing():
		return
	var pos := _player.current_animation_position
	var length := _player.current_animation_length
	if length <= 0.0:
		return
	if _basic_idle_prev_pos >= 0.0 and _basic_idle_prev_pos >= length * 0.70 and pos <= length * 0.30:
		_clear_pending_attract()
		_play_auto_attract()
		return
	_basic_idle_prev_pos = pos


func _on_auto_performance_finished() -> void:
	if _mode == ScheduleMode.LIGHT_IDLE and _pending_attract_request:
		_clear_pending_attract()
		_play_auto_attract()
		return
	_return_auto_base()


func _arm_wait() -> void:
	if not _schedule_enabled or _mode != ScheduleMode.BASE_IDLE or _wait_timer == null:
		return
	if _pending_attract_request:
		return
	_wait_timer.stop()
	_planned_wait = randf_range(2.0, 4.0)
	_wait_armed_msec = Time.get_ticks_msec()
	_wait_timer.start(_planned_wait)
	_note("基础待机，%.2f 秒后播放轻待机。" % _planned_wait)


func _on_light_wait_timeout() -> void:
	if not _schedule_enabled or _mode != ScheduleMode.BASE_IDLE:
		return
	if _pending_attract_request:
		return
	if _player == null or _player.assigned_animation != IDLE_ANIM or not _player.is_playing():
		return
	_play_auto_light()


func _play_auto_light() -> void:
	var anim_name := _pick_name(_combined_light_pool(), _last_light)
	if anim_name == "":
		_fail("没有可播放的轻待机。")
		return
	_last_light = anim_name
	if _wait_timer != null:
		_wait_timer.stop()
	_restore_light_loops()
	_hello_active = false
	_oneshot_name = ""
	_mode = ScheduleMode.LIGHT_IDLE
	_active_finish_anim = anim_name
	_auto_perf_gen = _performance_pose.bump_auto_session()
	var clip := _player.get_animation(anim_name)
	clip.loop_mode = Animation.LOOP_NONE
	_play_clip(anim_name, BLEND_BASE_TO_LIGHT)
	_start_approved_performance(anim_name, _auto_perf_gen)
	_note("自动轻待机 %s，混合 %.2f 秒，单次。" % [anim_name, BLEND_BASE_TO_LIGHT])


func _play_auto_attract() -> void:
	_clear_pending_attract()
	var anim_name := _pick_name(_attract_pool, _last_attract)
	if anim_name == "":
		_fail("没有可播放的轻招揽。")
		return
	_last_attract = anim_name
	var from_light := _mode == ScheduleMode.LIGHT_IDLE
	var blend := BLEND_LIGHT_TO_ATTRACT if from_light else BLEND_BASE_TO_ATTRACT
	var outgoing := String(_player.assigned_animation) if from_light else ""
	if _wait_timer != null:
		_wait_timer.stop()
	_restore_light_loops(outgoing)
	_hello_active = false
	_oneshot_name = ""
	_mode = ScheduleMode.ATTRACT
	_active_finish_anim = anim_name
	_auto_perf_gen = _performance_pose.begin_auto_attract_performance(false)
	_play_clip(anim_name, blend)
	_start_approved_performance(anim_name, _auto_perf_gen)
	_emotion_restore_primary = String(
		Approved.get_params(anim_name).get("emotion_id", "smile")
	)
	_note("自动轻招揽 %s，混合 %.2f 秒，单次。" % [anim_name, blend])


func _return_auto_base() -> void:
	if _mode != ScheduleMode.LIGHT_IDLE and _mode != ScheduleMode.ATTRACT:
		return
	if not _performance_pose.auto_finish_may_run(_auto_perf_gen):
		return
	_performance_pose.consume_auto_finish(_auto_perf_gen)
	var finished := _active_finish_anim
	_auto_return_count += 1
	_mode = ScheduleMode.BASE_IDLE
	_active_finish_anim = ""
	_restore_light_loops()
	_hello_active = false
	_oneshot_name = ""
	_start_idle(true)
	_note("自动表演结束，回到基础待机：" + finished)
	_arm_wait()


func _restore_light_loops(except_name: String = "") -> void:
	if _player == null:
		return
	for anim_name in _combined_light_pool():
		if anim_name == except_name:
			continue
		if _player.has_animation(anim_name):
			_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR


func _play_clip(anim_name: String, blend: float) -> void:
	var same := _player.assigned_animation == anim_name and _player.is_playing()
	var hold_pose := blend > 0.0 and not _player.is_playing() and String(_player.assigned_animation) != ""
	_last_blend = blend
	if _is_approved_action(anim_name):
		var p: Dictionary = Approved.get_params(anim_name)
		_player.speed_scale = float(p.get("action_speed", 1.0))
	elif anim_name == IDLE_ANIM:
		_player.speed_scale = 1.0
	if hold_pose:
		# Godot 4.7：capture 第一个参数是动画名，第二个是过渡时长；不能写成 capture(blend)。
		_player.play_with_capture(anim_name, blend, blend)
	elif same:
		_player.play(anim_name, blend)
		_player.seek(0.0, false)
	else:
		_player.play(anim_name, blend)


func _blend_into_idle() -> float:
	if _player == null:
		return 0.0
	var current := String(_player.assigned_animation)
	if current == "" or current == IDLE_ANIM:
		return 0.0
	if _is_light_idle_anim(current):
		return BLEND_LIGHT_TO_BASE
	if current in _attract_pool or current == HELLO_ANIM:
		return BLEND_ATTRACT_TO_BASE
	return BLEND_MANUAL


func _pick_name(pool: PackedStringArray, previous: String) -> String:
	if pool.is_empty():
		return ""
	if pool.size() < 2:
		return pool[0]
	var choices := PackedStringArray()
	for anim_name in pool:
		if anim_name != previous:
			choices.append(anim_name)
	if choices.is_empty():
		choices = pool
	return choices[randi() % choices.size()]


func _run_phase_a_check() -> void:
	var lines: PackedStringArray = []
	lines.append("players=" + str(_count_players(_model)))
	lines.append("idle_loop=" + str(_player.get_animation(IDLE_ANIM).loop_mode))
	lines.append("hello_loop=" + str(_player.get_animation(HELLO_ANIM).loop_mode))
	lines.append("idle_length=" + str(_player.get_animation(IDLE_ANIM).length))
	lines.append("hello_length=" + str(_player.get_animation(HELLO_ANIM).length))
	lines.append("blend=" + str(_player.playback_default_blend_time))
	lines.append("startup=" + _player.assigned_animation + " playing=" + str(_player.is_playing()))
	_start_idle(false)
	lines.append("repeat_idle_ignored=" + str("忽略重复请求" in _log_lines[_log_lines.size() - 1]))
	_player.seek(_player.current_animation_length - 0.05, true)
	_player.advance(0.2)
	lines.append("idle_after_wrap=" + _player.assigned_animation + " playing=" + str(_player.is_playing()) + " pos=" + str(_player.current_animation_position))
	var hips := _skeleton.find_bone("mixamorig_Hips")
	var pose_before := _skeleton.get_bone_pose_rotation(hips)
	_start_hello()
	_player.seek(2.0, true)
	_player.advance(0.0)
	var pose_after := _skeleton.get_bone_pose_rotation(hips)
	lines.append("hello_current=" + _player.assigned_animation)
	lines.append("hello_pose_changed=" + str(not pose_before.is_equal_approx(pose_after)))
	_player.seek(3.0, true)
	_start_hello()
	lines.append("hello_restart_pos=" + str(_player.current_animation_position))
	_apply_emote("surprise")
	var body := _find_mesh("人体_001")
	var laugh_index := body.find_blend_shape_by_name("laugh") if body != null else -1
	var surprise_index := body.find_blend_shape_by_name("surprise") if body != null else -1
	var surprise_before := body.get_blend_shape_value(surprise_index) if surprise_index >= 0 else -1.0
	_start_hello()
	_player.seek(1.5, true)
	_player.advance(0.0)
	var laugh_during := body.get_blend_shape_value(laugh_index) if laugh_index >= 0 else -1.0
	_player.speed_scale = 40.0
	_start_hello()
	await get_tree().create_timer(0.45).timeout
	_player.speed_scale = 1.0
	var laugh_after_hello := body.get_blend_shape_value(laugh_index) if laugh_index >= 0 else -1.0
	lines.append("surprise_before_manual=" + str(surprise_before))
	lines.append("laugh_during_hello=" + str(laugh_during))
	lines.append("laugh_after_hello=" + str(laugh_after_hello))
	lines.append("hello_overrides_manual_emote=" + str(laugh_during > 0.5))
	lines.append("after_hello=" + _player.assigned_animation + " playing=" + str(_player.is_playing()))
	_start_hello()
	_start_idle(false)
	_start_hello()
	_start_idle(true)
	lines.append("alternate_final=" + _player.assigned_animation)
	lines.append("players_after=" + str(_count_players(_model)))
	_request_missing_animation()
	_apply_emote("missing_expression_probe")
	var joined := "\n".join(_log_lines)
	lines.append("missing_anim_visible=" + str("missing_animation_probe" in joined))
	lines.append("missing_expr_visible=" + str("missing_expression_probe" in joined))
	lines.append("missing_still=" + _player.assigned_animation + " playing=" + str(_player.is_playing()))
	var output := "\n".join(lines)
	print(output)
	var file := FileAccess.open("user://phase_a_check.txt", FileAccess.WRITE)
	if file != null:
		file.store_string(output)
		file.close()
	get_tree().quit()


func _run_batch_check() -> void:
	var lines: PackedStringArray = []
	for anim_name in ["hello01", "Hand Wave_rig_01"]:
		var hips := _skeleton.find_bone("mixamorig_Hips")
		var before := _skeleton.get_bone_pose_rotation(hips)
		_play_batch_oneshot(anim_name)
		var shot_time := minf(4.0, _player.get_animation(anim_name).length * 0.45)
		_player.seek(shot_time, true)
		_player.advance(0.0)
		var during := _skeleton.get_bone_pose_rotation(hips)
		lines.append(anim_name + "_playing=" + _player.assigned_animation)
		lines.append(anim_name + "_pose_changed=" + str(not before.is_equal_approx(during)))
		lines.append(anim_name + "_loop=" + str(_player.get_animation(anim_name).loop_mode))
		await _save_check_png("C:/Users/29385/AppData/Local/Temp/youyou_batch_%s.png" % anim_name.replace(" ", "_"))
		_player.speed_scale = 40.0
		var finished := false
		var waited := 0.0
		while waited < 1.2:
			await get_tree().process_frame
			waited += get_process_delta_time()
			if _player.assigned_animation == IDLE_ANIM and _player.is_playing() and _oneshot_name == "":
				finished = true
				break
		_player.speed_scale = 1.0
		lines.append(anim_name + "_returned=" + str(finished) + " anim=" + _player.assigned_animation)
	_apply_emote("surprise")
	_play_batch_oneshot("hello01")
	var body := _find_mesh("人体_001")
	var surprise_index := body.find_blend_shape_by_name("surprise")
	_push_key(KEY_I)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("interrupt_anim=" + _player.assigned_animation)
	lines.append("interrupt_oneshot=" + _oneshot_name)
	lines.append("surprise_after_interrupt=" + str(body.get_blend_shape_value(surprise_index)))
	_push_key(KEY_4)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("key4=" + _player.assigned_animation)
	_push_key(KEY_5)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("key5=" + _player.assigned_animation)
	_start_hello()
	lines.append("hello_still=" + _player.assigned_animation + " active=" + str(_hello_active))
	print("\n".join(lines))
	get_tree().quit()


func _run_idle_check() -> void:
	var lines: PackedStringArray = []
	var hips := _skeleton.find_bone("mixamorig_Hips")
	for keycode in IDLE_VARIANTS.keys():
		var anim_name := String(IDLE_VARIANTS[keycode])
		_play_idle_variant(anim_name)
		var anim := _player.get_animation(anim_name)
		_player.seek(0.0, true)
		var start_pose := _skeleton.get_bone_pose_rotation(hips)
		_player.seek(anim.length * 0.4, true)
		_player.advance(0.0)
		var mid_pose := _skeleton.get_bone_pose_rotation(hips)
		lines.append("%s loop=%s len=%.3f moved=%s" % [anim_name, anim.loop_mode, anim.length, not start_pose.is_equal_approx(mid_pose)])
		await _save_check_png("C:/Users/29385/AppData/Local/Temp/youyou_idle_%s.png" % anim_name)
		_player.seek(maxf(anim.length - 0.05, 0.0), true)
		_player.advance(0.2)
		var wrapped := _player.assigned_animation == anim_name and _player.is_playing() and _player.current_animation_position < 0.5
		lines.append("%s wrapped=%s pos=%.3f" % [anim_name, wrapped, _player.current_animation_position])
	_push_key(KEY_I)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("after_i=" + _player.assigned_animation)
	_push_key(KEY_Q)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("key_q=" + _player.assigned_animation)
	_push_key(KEY_Z)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("key_z=" + _player.assigned_animation)
	_push_key(KEY_4)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("key_4=" + _player.assigned_animation + " oneshot=" + _oneshot_name)
	print("\n".join(lines))
	get_tree().quit()


func _run_new_anim_check() -> void:
	for _i in 5:
		await get_tree().process_frame
	var pivot := get_node("ObservePivot") as Node3D
	var camera := pivot.get_node("Camera3D") as Camera3D
	var pivot_before := pivot.global_transform
	var camera_before := camera.global_transform
	var body := _find_mesh("人体_001")
	var surprise_index := body.find_blend_shape_by_name("surprise")
	_apply_emote("surprise")
	var lines: PackedStringArray = []
	lines.append_array(_compat_lines)
	lines.append("alias=youyou_Basic_Idle01<=youyou_Basic_Idle01_001")
	lines.append("source_name_hidden=" + str(not _player.has_animation("youyou_Basic_Idle01_001")))
	lines.append("skipped_04=" + str(not _player.has_animation("youyou_Hello_Idle04")))
	lines.append("skipped_05=" + str(not _player.has_animation("youyou_Hello_Idle05")))
	lines.append("kept_hello01=" + str(_player.has_animation(HELLO_ANIM)))
	lines.append("kept_hello=" + str(_player.has_animation("hello01")))
	lines.append("kept_wave=" + str(_player.has_animation("Hand Wave_rig_01")))
	var hips := _skeleton.find_bone("mixamorig_Hips")
	var idle_name := "youyou_Basic_Idle01"
	var idle_clip := _player.get_animation(idle_name)
	_play_idle_variant(idle_name)
	_player.seek(0.0, true)
	_player.advance(0.0)
	var idle_start := _skeleton.get_bone_pose_rotation(hips)
	_player.seek(idle_clip.length * 0.4, true)
	_player.advance(0.0)
	var idle_mid := _skeleton.get_bone_pose_rotation(hips)
	lines.append("youyou_Basic_Idle01_loop=%s len=%.3f moved=%s playing=%s" % [
		idle_clip.loop_mode, idle_clip.length, not idle_start.is_equal_approx(idle_mid), _player.assigned_animation
	])
	await _save_check_png("C:/Users/29385/AppData/Local/Temp/youyou_new_youyou_Basic_Idle01.png")
	_player.seek(maxf(idle_clip.length - 0.05, 0.0), true)
	_player.advance(0.2)
	var wrapped := _player.assigned_animation == idle_name and _player.is_playing() and _player.current_animation_position < 0.5
	lines.append("youyou_Basic_Idle01_wrapped=%s pos=%.3f" % [wrapped, _player.current_animation_position])
	_push_key(KEY_I)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("youyou_Basic_Idle01_after_i=%s surprise=%.1f" % [
		_player.assigned_animation, body.get_blend_shape_value(surprise_index)
	])
	var attract_names: PackedStringArray = Approved.get_attract_whitelist()
	attract_names.erase("youyou_Hello_Idle01")
	for anim_name in attract_names:
		var clip := _player.get_animation(anim_name)
		var before := _skeleton.get_bone_pose_rotation(hips)
		_play_batch_oneshot(anim_name)
		_player.seek(minf(1.2, clip.length * 0.35), true)
		_player.advance(0.0)
		var during := _skeleton.get_bone_pose_rotation(hips)
		lines.append("%s loop=%s len=%.3f moved=%s playing=%s" % [
			anim_name, clip.loop_mode, clip.length, not before.is_equal_approx(during), _player.assigned_animation
		])
		await _save_check_png("C:/Users/29385/AppData/Local/Temp/youyou_new_%s.png" % anim_name)
		_player.speed_scale = 40.0
		var finished := false
		var waited := 0.0
		while waited < 2.0:
			await get_tree().process_frame
			waited += get_process_delta_time()
			if _player.assigned_animation == IDLE_ANIM and _player.is_playing() and _oneshot_name == "" and not _hello_active:
				finished = true
				break
		_player.speed_scale = 1.0
		lines.append("%s returned=%s anim=%s surprise=%.1f" % [
			anim_name, finished, _player.assigned_animation, body.get_blend_shape_value(surprise_index)
		])
	_play_batch_oneshot("youyou_Hello_Idle02")
	_player.seek(0.8, true)
	_push_key(KEY_I)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("interrupt_i=%s oneshot=%s hello=%s surprise=%.1f" % [
		_player.assigned_animation, _oneshot_name, _hello_active, body.get_blend_shape_value(surprise_index)
	])
	_play_batch_oneshot("youyou_Hello_Idle03")
	_push_key(KEY_H)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("interrupt_h=%s hello_active=%s" % [_player.assigned_animation, _hello_active])
	_play_batch_oneshot("youyou_Hello_Idle06")
	_push_key(KEY_4)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("interrupt_4=%s oneshot=%s" % [_player.assigned_animation, _oneshot_name])
	var key_to_name := {
		KEY_X: "youyou_Basic_Idle01",
		KEY_6: "youyou_Hello_Idle02",
		KEY_7: "youyou_Hello_Idle03",
		KEY_8: "youyou_Hello_Idle06",
		KEY_9: "youyou_Hello_Idle07",
		KEY_B: "youyou_Hello_Idle08",
		KEY_N: "youyou_Hello_Idle09",
		KEY_Q: "Basic_Idle01",
		KEY_4: "hello01",
		KEY_5: "Hand Wave_rig_01",
	}
	for keycode in key_to_name.keys():
		_push_key(keycode)
		await get_tree().process_frame
		await get_tree().process_frame
		lines.append("key_%s=%s" % [key_to_name[keycode], _player.assigned_animation])
	_push_key(KEY_H)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("key_H=%s" % _player.assigned_animation)
	lines.append("pivot_same=" + str(pivot.global_transform.is_equal_approx(pivot_before)))
	lines.append("camera_same=" + str(camera.global_transform.is_equal_approx(camera_before)))
	lines.append("surprise_final=%.1f" % body.get_blend_shape_value(surprise_index))
	print("\n".join(lines))
	get_tree().quit()


func _run_preview_event_check() -> void:
	var lines: PackedStringArray = []
	var ok := true
	EventCatalog.ensure_loaded()
	for action_id in EventActionPerformance.PREVIEW_EVENT_WHITELIST:
		var check: Dictionary = _event_perf.validate_event(action_id)
		var pass_entry := bool(check.get("ok", false))
		lines.append(
			"%s ok=%s scene=%s audio=%s errors=%s"
			% [
				action_id,
				str(pass_entry),
				String(check.get("scene", "")),
				String(check.get("audio", "")),
				",".join(check.get("errors", [])),
			]
		)
		ok = ok and pass_entry
	var coin_map := _show_adapter != null
	lines.append("show_adapter_ready=%s" % str(coin_map))
	lines.append("=== preview_event_check_pass=%s ===" % str(ok))
	var report := "\n".join(lines)
	print(report)
	get_tree().quit()


func _run_approved_pool_check() -> void:
	var lines: PackedStringArray = []
	lines.append("general_light_pool=" + ",".join(_general_light_pool))
	lines.append("light_pool=" + ",".join(_light_pool))
	lines.append("attract_pool=" + ",".join(_attract_pool))
	var ok := _general_light_pool.size() == Approved.get_general_light_whitelist().size()
	ok = ok and _light_pool.size() == Approved.get_light_idle_whitelist().size()
	ok = ok and _attract_pool.size() == Approved.get_attract_whitelist().size()
	for action_id in ["hello01", "Hand Wave_rig_01", "youyou_Hello_Idle04", "youyou_Hello_Idle09", "youyou_Basic_Idle06"]:
		var absent := not _player.has_animation(action_id)
		lines.append("unapproved_absent_%s=%s" % [action_id, str(absent)])
		ok = ok and absent
	ok = ok and _player.has_animation("Basic_Idle01")
	ok = ok and ("youyou_Hello_Idle05" in _attract_pool)
	ok = ok and _is_approved_action("youyou_Basic_Idle01")
	var sample: Dictionary = Approved.get_params("youyou_Hello_Idle08")
	ok = ok and float(sample.get("audio_start_offset", 0.0)) > 3.0
	lines.append("sample_hello08_offset=%.2f" % float(sample.get("audio_start_offset", 0.0)))
	lines.append("=== approved_pool_check_pass=%s ===" % str(ok))
	print("\n".join(lines))
	get_tree().quit()


func _run_schedule_check() -> void:
	for _frame in 4:
		await get_tree().process_frame
	var pivot := get_node("ObservePivot") as Node3D
	var camera := pivot.get_node("Camera3D") as Camera3D
	var pivot_before := pivot.global_transform
	var camera_before := camera.global_transform
	var lines: PackedStringArray = []
	var hips := _skeleton.find_bone("mixamorig_Hips")
	var body := _find_mesh("人体_001")
	var surprise_index := body.find_blend_shape_by_name("surprise")
	lines.append("light_pool=" + ",".join(_light_pool))
	lines.append("attract_pool=" + ",".join(_attract_pool))
	lines.append("timer_count=" + str(_count_timers(self)))
	lines.append("startup_anim=" + _player.assigned_animation)
	var light1 := await _await_auto_light(lines, "cycle1", hips)
	var light2 := await _await_auto_light(lines, "cycle2", hips)
	lines.append("light_not_repeat=" + str(light1 != "" and light2 != "" and light1 != light2))
	var attract1 := await _await_attract_from_base(lines, "pass1", hips)
	await _finish_auto_to_base(lines, "pass1")
	_player.seek(1.0, true)
	var held_anim := _player.assigned_animation
	var held_pos := _player.current_animation_position
	_push_key(KEY_M)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("m_during_attract_anim=" + _player.assigned_animation)
	lines.append("m_during_attract_same=" + str(_player.assigned_animation == held_anim and _player.current_animation_position > held_pos - 0.05))
	lines.append("m_during_attract_pending=" + str(_pending_attract_request))
	lines.append("m_during_attract_pos=" + str(snapped(_player.current_animation_position, 0.01)) + " from=" + str(snapped(held_pos, 0.01)))
	await _finish_auto_to_base(lines, "attract1")
	var attract2 := ""
	if _mode == ScheduleMode.BASE_IDLE:
		_push_key(KEY_M)
		await get_tree().process_frame
		await get_tree().process_frame
		attract2 = await _wait_for_attract_playing(3.0)
		lines.append("pass2_anim=" + attract2 + " mode=" + str(_mode) + " in_pool=" + str(attract2 in _attract_pool))
		lines.append("attract_not_repeat=" + str(attract1 != "" and attract2 != attract1))
		await _finish_auto_to_base(lines, "attract2")
	_wait_timer.stop()
	_on_light_wait_timeout()
	var interrupted_light := _player.assigned_animation
	_push_key(KEY_M)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("m_light_pending from=" + interrupted_light + " still=" + _player.assigned_animation + " pending=" + str(_pending_attract_request) + " mode=" + str(_mode))
	_push_key(KEY_H)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("manual_h=" + _player.assigned_animation + " mode=" + str(_mode) + " timer_stopped=" + str(_wait_timer.is_stopped()))
	_player.seek(1.0, true)
	var manual_anim := _player.assigned_animation
	var manual_pos := _player.current_animation_position
	_push_key(KEY_M)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("m_during_manual_same=" + str(_player.assigned_animation == manual_anim and absf(_player.current_animation_position - manual_pos) < 0.2))
	_player.speed_scale = 40.0
	var manual_returned := false
	var manual_waited := 0.0
	while manual_waited < 2.0:
		await get_tree().process_frame
		manual_waited += get_process_delta_time()
		if _player.assigned_animation == IDLE_ANIM and _player.is_playing() and _mode == ScheduleMode.MANUAL_TEST and _wait_timer.is_stopped():
			manual_returned = true
			break
	_player.speed_scale = 1.0
	lines.append("manual_end_no_auto=" + str(manual_returned) + " mode=" + str(_mode) + " timer_stopped=" + str(_wait_timer.is_stopped()))
	_push_key(KEY_I)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("after_i=%s mode=%s timer=%s wait=%.2f" % [_player.assigned_animation, _mode, not _wait_timer.is_stopped(), _planned_wait])
	_push_key(KEY_2)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("expr_anim=%s mode=%s timer=%s surprise=%.1f" % [
		_player.assigned_animation, _mode, not _wait_timer.is_stopped(), body.get_blend_shape_value(surprise_index)
	])
	_push_key(KEY_X)
	await get_tree().process_frame
	await get_tree().process_frame
	var x_loop := -1
	if _player.has_animation("youyou_Basic_Idle01"):
		x_loop = _player.get_animation("youyou_Basic_Idle01").loop_mode
	lines.append("key_x=%s loop=%s mode=%s timer_stopped=%s" % [
		_player.assigned_animation, x_loop, _mode, _wait_timer.is_stopped()
	])
	_push_key(KEY_4)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("key_4=" + _player.assigned_animation + " mode=" + str(_mode))
	_push_key(KEY_5)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("key_5=" + _player.assigned_animation)
	_push_key(KEY_I)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("i_restores=%s mode=%s timer=%s" % [_player.assigned_animation, _mode, not _wait_timer.is_stopped()])
	var previous := ""
	var adjacent := 0
	var seen := {}
	for _i in 40:
		var picked := _pick_name(_light_pool, previous)
		if picked == previous:
			adjacent += 1
		seen[picked] = true
		previous = picked
	lines.append("light_pick_adjacent=" + str(adjacent) + " unique=" + str(seen.size()) + " pool=" + str(_light_pool.size()))
	previous = ""
	adjacent = 0
	seen = {}
	for _i in 40:
		var picked := _pick_name(_attract_pool, previous)
		if picked == previous:
			adjacent += 1
		seen[picked] = true
		previous = picked
	lines.append("attract_pick_adjacent=" + str(adjacent) + " unique=" + str(seen.size()) + " pool=" + str(_attract_pool.size()))
	lines.append("excluded_04=" + str(not ("youyou_Hello_Idle04" in _attract_pool)))
	lines.append("included_05=" + str("youyou_Hello_Idle05" in _attract_pool))
	lines.append("excluded_09=" + str(not ("youyou_Hello_Idle09" in _attract_pool)))
	lines.append("excluded_youyou06=" + str(not ("youyou_Basic_Idle06" in _light_pool)))
	lines.append("excluded_hello01=" + str(not _player.has_animation("hello01")))
	lines.append("excluded_hand_wave=" + str(not _player.has_animation("Hand Wave_rig_01")))
	lines.append("pivot_same=" + str(pivot.global_transform.is_equal_approx(pivot_before)))
	lines.append("camera_same=" + str(camera.global_transform.is_equal_approx(camera_before)))
	_player.speed_scale = 1.0
	print("\n".join(lines))
	get_tree().quit()


func _await_auto_light(lines: PackedStringArray, label: String, hips: int) -> String:
	var started_msec := _wait_armed_msec
	var planned := _planned_wait
	var seen := ""
	var waited := 0.0
	while waited < 5.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
		if _mode == ScheduleMode.LIGHT_IDLE:
			seen = _player.assigned_animation
			break
	var elapsed := (Time.get_ticks_msec() - started_msec) / 1000.0
	var moved := false
	var loop_mode := -1
	if seen != "":
		var before := _skeleton.get_bone_pose_rotation(hips)
		_player.seek(minf(0.8, _player.get_animation(seen).length * 0.35), true)
		_player.advance(0.0)
		moved = not before.is_equal_approx(_skeleton.get_bone_pose_rotation(hips))
		loop_mode = _player.get_animation(seen).loop_mode
	lines.append("%s light=%s in_pool=%s loop=%s moved=%s planned=%.2f elapsed=%.2f" % [
		label, seen, seen in _light_pool, loop_mode, moved, planned, elapsed
	])
	await _finish_auto_to_base(lines, label)
	return seen


func _await_attract_from_base(lines: PackedStringArray, label: String, hips: int) -> String:
	_push_key(KEY_M)
	await get_tree().process_frame
	await get_tree().process_frame
	var queued := _pending_attract_request
	var still_idle := _player.assigned_animation == IDLE_ANIM and _mode == ScheduleMode.BASE_IDLE
	lines.append("%s queued=%s still_idle=%s timer_stopped=%s" % [label, queued, still_idle, _wait_timer.is_stopped()])
	var anim_name := await _wait_for_attract_playing(4.0)
	var before := _skeleton.get_bone_pose_rotation(hips)
	if _player.has_animation(anim_name):
		_player.seek(minf(0.8, _player.get_animation(anim_name).length * 0.25), true)
		_player.advance(0.0)
	var moved := not before.is_equal_approx(_skeleton.get_bone_pose_rotation(hips))
	var loop_mode := _player.get_animation(anim_name).loop_mode if _player.has_animation(anim_name) else -1
	lines.append("%s attract=%s mode=%s in_pool=%s loop=%s moved=%s" % [
		label, anim_name, _mode, anim_name in _attract_pool, loop_mode, moved
	])
	return anim_name


func _wait_for_attract_playing(limit: float) -> String:
	var length := _player.current_animation_length
	_player.seek(maxf(length - 0.04, 0.0), true)
	var waited := 0.0
	while waited < limit:
		await get_tree().process_frame
		waited += get_process_delta_time()
		_player.advance(get_process_delta_time())
		if _mode == ScheduleMode.ATTRACT and _player.assigned_animation in _attract_pool:
			return String(_player.assigned_animation)
	return String(_player.assigned_animation)


func _finish_auto_to_base(lines: PackedStringArray, label: String) -> void:
	_player.speed_scale = 40.0
	var returned := false
	var waited := 0.0
	while waited < 2.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
		if _mode == ScheduleMode.BASE_IDLE and _player.assigned_animation == IDLE_ANIM and _player.is_playing() and not _wait_timer.is_stopped():
			returned = true
			break
	_player.speed_scale = 1.0
	lines.append("%s returned=%s anim=%s mode=%s wait=%.2f timer=%s" % [
		label, returned, _player.assigned_animation, _mode, _planned_wait, not _wait_timer.is_stopped()
	])


func _count_timers(node: Node) -> int:
	var count := 1 if node is Timer else 0
	for child in node.get_children():
		count += _count_timers(child)
	return count


func _run_expression_check() -> void:
	for _frame in 3:
		await get_tree().process_frame
	var body := _find_mesh("人体_001")
	if body == null:
		body = _find_mesh("人体.001")
	var lines: PackedStringArray = []
	var smile_i := body.find_blend_shape_by_name("smile")
	lines.append("mesh_count=%d" % _meshes.size())
	lines.append("startup_active=" + _face.get_active_primary())
	lines.append("startup_legacy_smile=%.3f eyes_smile=%.3f mouth_smile=%.3f" % [
		body.get_blend_shape_value(smile_i) if smile_i >= 0 else -1.0,
		_face.read_shape_on_body("Eyes_smile"),
		_face.read_shape_on_body("Mouth_smile"),
	])
	_apply_emote("smile")
	await get_tree().create_timer(0.25).timeout
	lines.append("after_1_smile split=%.3f legacy=%.3f" % [
		_face.read_primary_on_mesh(body, "smile"), body.get_blend_shape_value(smile_i) if smile_i >= 0 else -1.0
	])
	_apply_emote("surprise")
	await get_tree().create_timer(0.25).timeout
	lines.append("after_2_surprise split=%.3f legacy=%.3f active=%s" % [
		_face.read_primary_on_mesh(body, "surprise"),
		_read_legacy_on_body(body, "surprise"),
		_face.get_active_primary(),
	])
	_apply_emote("sad")
	await get_tree().create_timer(0.25).timeout
	lines.append("after_v_sad split=%.3f" % [_face.read_primary_on_mesh(body, "sad")])
	_apply_emote("laugh")
	await get_tree().create_timer(0.25).timeout
	lines.append("chain_laugh split=%.3f" % [_face.read_primary_on_mesh(body, "laugh")])
	_apply_emote("laugh")
	await get_tree().process_frame
	_apply_emote("angry")
	await get_tree().create_timer(0.25).timeout
	lines.append("rapid_to_angry surprise_legacy=%.3f angry_split=%.3f active=%s" % [
		_read_legacy_on_body(body, "surprise"), _face.read_primary_on_mesh(body, "angry"), _face.get_active_primary()
	])
	var synced := 0
	var mesh_count := 0
	for mesh in _meshes:
		var ev := mesh.find_blend_shape_by_name("Eyes_angry")
		var mv := mesh.find_blend_shape_by_name("Mouth_angry")
		if ev < 0 and mv < 0:
			continue
		mesh_count += 1
		var peak := 0.0
		if ev >= 0:
			peak = maxf(peak, mesh.get_blend_shape_value(ev))
		if mv >= 0:
			peak = maxf(peak, mesh.get_blend_shape_value(mv))
		if peak > 0.5:
			synced += 1
	lines.append("angry_sync_meshes=%d/%d" % [synced, mesh_count])
	_push_key(KEY_J)
	await get_tree().create_timer(0.25).timeout
	var wink_i := body.find_blend_shape_by_name("wink")
	lines.append("after_j_wink composite=%.3f active=%s" % [
		body.get_blend_shape_value(wink_i) if wink_i >= 0 else -1.0, _face.get_active_primary()
	])
	_push_key(KEY_K)
	await get_tree().create_timer(0.25).timeout
	var look_i := body.find_blend_shape_by_name("lookleft")
	lines.append("after_k_lookleft composite=%.3f" % [body.get_blend_shape_value(look_i) if look_i >= 0 else -1.0])
	for keycode in [KEY_C, KEY_V, KEY_P, KEY_L]:
		_push_key(keycode)
		await get_tree().create_timer(0.22).timeout
	lines.append("after_cvpL_active=" + _face.get_active_primary())
	_push_key(KEY_0)
	await get_tree().create_timer(0.25).timeout
	lines.append("after_0_split_smile=%.3f legacy_smile=%.3f active=%s" % [
		_face.read_primary_on_mesh(body, "smile"),
		body.get_blend_shape_value(smile_i) if smile_i >= 0 else -1.0,
		_face.get_active_primary(),
	])
	_push_key(KEY_4)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("key4_anim=%s face=%s" % [_player.assigned_animation, _face.get_active_primary()])
	_push_key(KEY_M)
	await get_tree().process_frame
	lines.append("m_pending=%s anim=%s face=%s" % [_pending_attract_request, _player.assigned_animation, _face.get_active_primary()])
	_apply_emote("missing_expression_probe")
	lines.append("missing_failed=" + str("missing_expression_probe" in "\n".join(_log_lines)))
	var ok: bool = (
		_face.read_shape_on_body("Eyes_smile") > 0.85
		and _read_legacy_on_body(body, "smile") < 0.05
		and synced >= maxi(mesh_count - 1, 1)
	)
	lines.append("=== face_expression_check_pass=%s ===" % str(ok))
	print("\n".join(lines))
	get_tree().quit()


func _run_expression_smooth_transition_check() -> void:
	for _frame in 3:
		await get_tree().process_frame
	var body := _find_mesh("人体_001")
	if body == null:
		body = _find_mesh("人体.001")
	var lines: PackedStringArray = []
	if body == null or _face == null:
		lines.append("=== expression_smooth_transition_check_pass=false ===")
		print("\n".join(lines))
		get_tree().quit()
		return
	_face.reset_all(0.0)
	await get_tree().process_frame
	_apply_emote("smile")
	await get_tree().create_timer(0.35).timeout
	var smile_before := _face.read_primary_on_mesh(body, "smile")
	_apply_emote("surprise")
	await get_tree().create_timer(0.08).timeout
	var smile_mid := _face.read_primary_on_mesh(body, "smile")
	var surprise_mid := _face.read_primary_on_mesh(body, "surprise")
	var test_a := smile_before > 0.85 and smile_mid > 0.05 and smile_mid < 0.95 and surprise_mid > 0.02
	lines.append("A_smile_to_surprise_mid smile=%.3f surprise=%.3f ok=%s" % [smile_mid, surprise_mid, str(test_a)])
	var snap_before_interrupt := surprise_mid
	_apply_emote("laugh")
	await get_tree().process_frame
	var surprise_after_interrupt := _face.read_primary_on_mesh(body, "surprise")
	var laugh_after_interrupt := _face.read_primary_on_mesh(body, "laugh")
	var jump := absf(surprise_after_interrupt - snap_before_interrupt)
	var test_c := jump < 0.15 and laugh_after_interrupt < 0.98
	lines.append("C_interrupt jump=%.4f laugh=%.3f ok=%s" % [jump, laugh_after_interrupt, str(test_c)])
	_apply_emote("smile")
	await get_tree().process_frame
	_apply_emote("smile")
	var test_h_skip := not _face.is_transition_running()
	lines.append("H_duplicate_smile_skip=%s" % str(test_h_skip))
	var missing_ok := not _face.set_emotion("missing_expression_probe")
	lines.append("H_missing_id=%s" % str(missing_ok))
	var dur_surprise := FacePresenter.TransitionConfig.resolve_emotion_duration("smile", "surprise", -1.0)
	var dur_sad := FacePresenter.TransitionConfig.resolve_emotion_duration("laugh", "sad", -1.0)
	lines.append("config_surprise=%.2f config_sad=%.2f" % [dur_surprise, dur_sad])
	var ok := test_a and test_c and test_h_skip and missing_ok and dur_surprise > 0.0
	lines.append("=== expression_smooth_transition_check_pass=%s ===" % str(ok))
	print("\n".join(lines))
	get_tree().quit()


func _expected_emotion_wall_for_action(action_id: String) -> float:
	var params: Dictionary = Approved.get_params(action_id)
	if params.is_empty():
		return 0.35
	var audio_at := float(params.get("audio_start_offset", 1.667))
	var speed := maxf(float(params.get("action_speed", 1.0)), 0.01)
	var lead := maxf(float(params.get("emotion_lead_time", 0.0)), 0.0)
	return maxf(audio_at / speed - lead, 0.0)


func _face_sample_line(tag: String, body: MeshInstance3D) -> String:
	var blink := 0.0
	if _idle_life != null:
		blink = float(_idle_life.call("get_debug_snapshot").get("blink_weight", 0.0))
	var anim := String(_player.assigned_animation) if _player != null else ""
	var pos := _player.current_animation_position if _player != null and _player.is_playing() else -1.0
	return (
		tag
		+ " anim=" + anim
		+ " pos=" + str(snapped(pos, 0.01))
		+ " smile=" + str(snapped(_face.read_primary_on_mesh(body, "smile"), 0.001))
		+ " surprise=" + str(snapped(_face.read_primary_on_mesh(body, "surprise"), 0.001))
		+ " laugh=" + str(snapped(_face.read_primary_on_mesh(body, "laugh"), 0.001))
		+ " sad=" + str(snapped(_face.read_primary_on_mesh(body, "sad"), 0.001))
		+ " emo=" + _face.get_active_emotion()
		+ " vis=" + _face.get_active_viseme()
		+ " prog=" + str(snapped(_face.get_transition_progress(), 0.001))
		+ " blink=" + str(snapped(blink, 0.001))
		+ " eyes_surp=" + str(snapped(_face.read_shape_on_body("Eyes_surprise"), 0.001))
		+ " mouth_A=" + str(snapped(_face.read_viseme_on_mesh(body, "a"), 0.001))
	)


func _run_expression_integration_check() -> void:
	for _frame in 4:
		await get_tree().process_frame
	var body := _find_mesh("人体_001")
	if body == null:
		body = _find_mesh("人体.001")
	var lines: PackedStringArray = []
	if body == null or _face == null or _player == null:
		lines.append("=== expression_integration_check_pass=false ===")
		print("\n".join(lines))
		get_tree().quit()
		return
	_stop_approved_performance()
	_face.reset_all(0.0)
	await get_tree().process_frame
	lines.append(_face_sample_line("setup", body))
	var hello_params: Dictionary = Approved.get_params(HELLO_ANIM)
	var audio_offset := float(hello_params.get("audio_start_offset", 2.01))
	var action_speed := maxf(float(hello_params.get("action_speed", 1.15)), 0.01)
	var emotion_lead := float(hello_params.get("emotion_lead_time", 0.96))
	var expected_audio_wall := audio_offset / action_speed
	var expected_emotion_wall := _expected_emotion_wall_for_action(HELLO_ANIM)
	lines.append(
		"B_plan hello=%s audio_wall=%.3f emotion_wall=%.3f lead=%.3f target=%s"
		% [HELLO_ANIM, expected_audio_wall, expected_emotion_wall, emotion_lead, hello_params.get("emotion_id", "")]
	)
	_enter_manual()
	_hello_active = false
	_start_hello()
	var elapsed := 0.0
	var first_laugh_wall := -1.0
	var laugh_at_emotion_wall := -1.0
	var laugh_at_audio_wall := -1.0
	while elapsed < expected_audio_wall + 0.45:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		var laugh_v := _face.read_primary_on_mesh(body, "laugh")
		if first_laugh_wall < 0.0 and laugh_v > 0.12:
			first_laugh_wall = elapsed
			lines.append(_face_sample_line("B_first_laugh_t=%.3f" % elapsed, body))
		if laugh_at_emotion_wall < 0.0 and elapsed >= expected_emotion_wall - 0.04:
			laugh_at_emotion_wall = laugh_v
		if laugh_at_audio_wall < 0.0 and elapsed >= expected_audio_wall - 0.04:
			laugh_at_audio_wall = laugh_v
			lines.append(_face_sample_line("B_near_audio", body))
	var test_b := (
		first_laugh_wall >= 0.0
		and first_laugh_wall < expected_audio_wall - 0.25
		and first_laugh_wall >= expected_emotion_wall - 0.12
	)
	lines.append(
		"B_attract_timing first_laugh=%.3f emotion_wall=%.3f laugh@emotion=%.3f laugh@audio=%.3f ok=%s"
		% [first_laugh_wall, expected_emotion_wall, laugh_at_emotion_wall, laugh_at_audio_wall, str(test_b)]
	)
	_stop_approved_performance()
	await get_tree().process_frame
	_apply_emote("surprise")
	await get_tree().create_timer(0.18).timeout
	var surprise_hold := _face.read_primary_on_mesh(body, "surprise")
	lines.append(_face_sample_line("D_before_hello", body))
	_start_hello()
	await get_tree().create_timer(0.12).timeout
	var surprise_mid := _face.read_primary_on_mesh(body, "surprise")
	var laugh_mid := _face.read_primary_on_mesh(body, "laugh")
	_stop_approved_performance()
	_play_clip(IDLE_ANIM, 0.25)
	await get_tree().create_timer(0.08).timeout
	var surprise_after_cut := _face.read_primary_on_mesh(body, "surprise")
	var laugh_after_cut := _face.read_primary_on_mesh(body, "laugh")
	var smile_after_cut := _face.read_primary_on_mesh(body, "smile")
	var no_smile_snap := not (smile_after_cut > 0.92 and surprise_after_cut < 0.08)
	var still_performance_face := surprise_after_cut > 0.35 or laugh_after_cut > 0.03 or surprise_mid > 0.35
	var test_d := surprise_hold > 0.55 and no_smile_snap and still_performance_face
	lines.append(_face_sample_line("D_after_cut", body))
	lines.append(
		"D_action_interrupt hold=%.3f mid=%.3f after=%.3f laugh=%.3f ok=%s"
		% [surprise_hold, surprise_mid, surprise_after_cut, laugh_after_cut, str(test_d)]
	)
	_stop_approved_performance()
	_mode = ScheduleMode.BASE_IDLE
	_hello_active = false
	_oneshot_name = ""
	if _player.has_animation(IDLE_ANIM):
		_player.get_animation(IDLE_ANIM).loop_mode = Animation.LOOP_LINEAR
	_play_clip(IDLE_ANIM, 0.0)
	_sync_idle_presence()
	if _idle_life != null:
		_idle_life.set_process(true)
		_idle_life.call("set_performance_state", IdleLife.PerfState.BASE_IDLE)
	_apply_emote("surprise")
	await get_tree().create_timer(0.32).timeout
	var blink_during := 0
	var eyes_peak := 0.0
	for _step in 220:
		_idle_life.call("process_life", 0.02, get_viewport())
		var snap: Dictionary = _idle_life.call("get_debug_snapshot")
		if float(snap.get("blink_weight", 0.0)) > 0.55:
			blink_during += 1
		eyes_peak = maxf(eyes_peak, _face.read_shape_on_body("Eyes_surprise"))
	await get_tree().process_frame
	lines.append(_face_sample_line("E_after_blink_sim", body))
	var test_e := blink_during >= 2 and eyes_peak > 0.35
	lines.append("E_blink_during_transition peaks=%d eyes_surp_peak=%.3f ok=%s" % [blink_during, eyes_peak, str(test_e)])
	_face.clear_viseme(0.0)
	await get_tree().process_frame
	_apply_emote("surprise")
	await get_tree().create_timer(0.22).timeout
	_apply_viseme("a")
	await get_tree().create_timer(0.18).timeout
	var a_during := _face.read_viseme_on_mesh(body, "a")
	var eyes_during := _face.read_shape_on_body("Eyes_surprise")
	await _run_clear_viseme_coordinator()
	await get_tree().create_timer(0.28).timeout
	var mouth_after := _face.read_shape_on_body("Mouth_surprise")
	var a_after := _face.read_viseme_on_mesh(body, "a")
	lines.append(_face_sample_line("F_after_speech", body))
	var test_f := a_during > 0.28 and eyes_during > 0.45 and a_after < 0.12 and mouth_after > 0.15
	lines.append(
		"F_viseme_coord A_during=%.3f eyes=%.3f mouth_after=%.3f A_after=%.3f ok=%s"
		% [a_during, eyes_during, mouth_after, a_after, str(test_f)]
	)
	_stop_approved_performance()
	_apply_emote("surprise")
	await get_tree().create_timer(0.35).timeout
	var surprise_before_loop := _face.read_primary_on_mesh(body, "surprise")
	if _player.has_animation(IDLE_ANIM):
		_player.get_animation(IDLE_ANIM).loop_mode = Animation.LOOP_LINEAR
	_play_clip(IDLE_ANIM, 0.0)
	var loop_elapsed := 0.0
	var loop_samples: PackedStringArray = []
	_player.speed_scale = 3.5
	while loop_elapsed < 2.8:
		await get_tree().process_frame
		loop_elapsed += get_process_delta_time()
		if loop_samples.size() < 4 and fmod(loop_elapsed, 0.7) < get_process_delta_time() * 1.5:
			loop_samples.append(_face_sample_line("G_loop_t=%.2f" % loop_elapsed, body))
	_player.speed_scale = 1.0
	for sample in loop_samples:
		lines.append(sample)
	var surprise_after_loop := _face.read_primary_on_mesh(body, "surprise")
	var legacy_smile := _read_legacy_on_body(body, "smile")
	var test_g := surprise_before_loop > 0.65 and surprise_after_loop > 0.55 and legacy_smile < 0.12
	lines.append(
		"G_idle_loop before=%.3f after=%.3f legacy_smile=%.3f ok=%s"
		% [surprise_before_loop, surprise_after_loop, legacy_smile, str(test_g)]
	)
	var test_evt := true
	if _event_perf != null:
		_enter_manual()
		_event_playing = true
		_event_perf.play_event("youyou_fail01", 8801)
		elapsed = 0.0
		var first_sad := -1.0
		var fail_params := EventCatalog.find_entry("youyou_fail01")
		var fail_lead := float(fail_params.get("emotion_lead_time", 0.35))
		var fail_audio := float(fail_params.get("audio_start_offset", 1.667))
		var fail_speed := maxf(float(fail_params.get("action_speed", 1.0)), 0.01)
		var fail_emotion_wall := maxf(fail_audio / fail_speed - fail_lead, 0.0)
		while elapsed < fail_emotion_wall + 1.2:
			await get_tree().process_frame
			elapsed += get_process_delta_time()
			var sad_v := _face.read_primary_on_mesh(body, "sad")
			if first_sad < 0.0 and sad_v > 0.12:
				first_sad = elapsed
				lines.append(_face_sample_line("EVT_fail_first_sad_t=%.3f" % elapsed, body))
		test_evt = first_sad >= 0.0 and first_sad <= fail_emotion_wall + 0.15
		lines.append(
			"EVT_fail_sad_timing first=%.3f wall=%.3f ok=%s"
			% [first_sad, fail_emotion_wall, str(test_evt)]
		)
		_event_perf.stop_event(true)
		_event_playing = false
	else:
		test_evt = false
		lines.append("EVT_fail_skipped=no_event_perf")
	var ok := test_b and test_d and test_e and test_f and test_g and test_evt
	lines.append("=== expression_integration_check_pass=%s ===" % str(ok))
	print("\n".join(lines))
	get_tree().quit()


func _run_expression_extension_check() -> void:
	for _frame in 4:
		await get_tree().process_frame
	var body := _find_mesh("人体_001")
	if body == null:
		body = _find_mesh("人体.001")
	var lines: PackedStringArray = []
	if body == null or _face == null:
		lines.append("=== expression_extension_check_pass=false ===")
		print("\n".join(lines))
		get_tree().quit(1)
		return
	const EXTENDED_ONLY: PackedStringArray = [
		"think", "sleepy", "yawn", "min_smile", "mid_smile", "whistle", "puff",
		"bite_wink", "smug_smile", "serious",
	]
	var readiness := _face.get_emotion_readiness()
	var ready_all := true
	for eid in EXTENDED_ONLY:
		var ready := bool(readiness.get(eid, false))
		lines.append("ready_%s=%s" % [eid, str(ready)])
		ready_all = ready_all and ready
	lines.append(
		"patch_ok=%s success=%d/%d"
		% [
			str(_patch_apply_result.get("ok", false)),
			int(_patch_apply_result.get("success_count", 0)),
			int(_patch_apply_result.get("total_count", 0)),
		]
	)
	_face.reset_all(0.0)
	await get_tree().process_frame
	_apply_emote("think")
	await get_tree().create_timer(0.28).timeout
	var think_peak := _face.read_primary_on_mesh(body, "think")
	_apply_viseme("a")
	await get_tree().create_timer(0.2).timeout
	var a_during := _face.read_viseme_on_mesh(body, "a")
	var eyes_during := _face.read_shape_on_body("Eyes_think")
	var mouth_during := _face.read_shape_on_body("Mouth_think")
	await _run_clear_viseme_coordinator()
	await get_tree().create_timer(0.25).timeout
	var mouth_after := _face.read_shape_on_body("Mouth_think")
	var a_after := _face.read_viseme_on_mesh(body, "a")
	lines.append(_face_sample_line("think_speech", body))
	var speech_ok := (
		think_peak > 0.45
		and a_during > 0.28
		and eyes_during > 0.35
		and a_after < 0.12
		and mouth_after > 0.12
	)
	lines.append(
		"think_viseme think=%.3f A=%.3f eyes=%.3f mouth_d=%.3f mouth_a=%.3f ok=%s"
		% [think_peak, a_during, eyes_during, mouth_during, mouth_after, str(speech_ok)]
	)
	_apply_emote("min_smile")
	await get_tree().create_timer(0.22).timeout
	var min_smile_peak := _face.read_primary_on_mesh(body, "min_smile")
	_apply_emote("smile")
	await get_tree().create_timer(0.35).timeout
	var smile_after := _face.read_primary_on_mesh(body, "smile")
	var chain_ok := min_smile_peak > 0.45 and smile_after > 0.55
	lines.append("joy_chain min_smile=%.3f smile=%.3f ok=%s" % [min_smile_peak, smile_after, str(chain_ok)])
	var lash_ok := true
	var lash := _find_mesh("睫毛")
	if lash == null:
		lash_ok = false
		lines.append("lash_isolation skipped=no_lash_mesh")
	else:
		for squint_id in ["grin", "yawn"]:
			_apply_emote(squint_id)
			await get_tree().create_timer(0.48).timeout
			var eyes_shape := "Eyes_%s" % squint_id
			var body_eyes := _face.read_shape_on_body(eyes_shape)
			var lash_idx := lash.find_blend_shape_by_name(eyes_shape)
			var lash_eyes := lash.get_blend_shape_value(lash_idx) if lash_idx >= 0 else -1.0
			var masked := (
				_idle_life != null
				and bool(_idle_life.call("is_blink_masked"))
			)
			var case_ok := (
				body_eyes > 0.35
				and lash_eyes > 0.35
				and absf(lash_eyes - body_eyes) < 0.12
				and masked
			)
			lash_ok = lash_ok and case_ok
			lines.append(
				"lash_%s body=%.3f lash=%.3f blink_masked=%s ok=%s"
				% [squint_id, body_eyes, lash_eyes, str(masked), str(case_ok)]
			)
		_apply_emote("sad")
		await get_tree().create_timer(0.48).timeout
		var sad_body := _face.read_shape_on_body("Eyes_sad")
		var sad_lash_idx := lash.find_blend_shape_by_name("Eyes_sad")
		var sad_lash := lash.get_blend_shape_value(sad_lash_idx) if sad_lash_idx >= 0 else -1.0
		var sad_lash_ok := sad_body > 0.35 and sad_lash > 0.35
		lash_ok = lash_ok and sad_lash_ok
		lines.append(
			"lash_sad body=%.3f lash=%.3f ok=%s" % [sad_body, sad_lash, str(sad_lash_ok)]
		)
	var ok := ready_all and speech_ok and chain_ok and lash_ok
	lines.append("=== expression_extension_check_pass=%s ===" % str(ok))
	print("\n".join(lines))
	get_tree().quit(0 if ok else 1)


func _read_legacy_on_body(body: MeshInstance3D, shape_name: String) -> float:
	var idx := body.find_blend_shape_by_name(shape_name)
	if idx < 0:
		return -1.0
	return body.get_blend_shape_value(idx)


func _run_viseme_coord_check() -> void:
	for _frame in 3:
		await get_tree().process_frame
	var body := _find_mesh("人体_001")
	if body == null:
		body = _find_mesh("人体.001")
	var lines: PackedStringArray = []
	_face.reset_all(0.0)
	await get_tree().process_frame
	_apply_emote("surprise")
	await get_tree().create_timer(0.25).timeout
	_apply_viseme("a")
	await get_tree().create_timer(0.25).timeout
	var a_body: float = _face.read_viseme_on_mesh(body, "a")
	var eyes_surprise_during: float = _face.read_shape_on_body("Eyes_surprise")
	lines.append("surprise_plus_a split_surprise=%.3f legacy_smile=%.3f A=%.3f mouth_surprise=%.3f eyes=%.3f" % [
		_face.read_primary_on_mesh(body, "surprise"),
		_read_legacy_on_body(body, "smile"),
		a_body,
		_face.read_shape_on_body("Mouth_surprise"),
		eyes_surprise_during,
	])
	var tooth := _find_mesh("上牙")
	var tongue := _find_mesh("舌头")
	lines.append("participants_a tooth=%.3f tongue=%.3f leak=%.4f" % [
		_face.read_viseme_on_mesh(tooth, "a"), _face.read_viseme_on_mesh(tongue, "a"),
		_face.max_viseme_weight_excluding("a", 0.03)
	])
	await _run_clear_viseme_coordinator()
	await get_tree().create_timer(0.3).timeout
	lines.append("after_clear_surprise split=%.3f all_zero=%s restore=%s" % [
		_face.read_primary_on_mesh(body, "surprise"), _face.all_visemes_near_zero(0.03),
		_face.get_active_primary()
	])
	_apply_viseme("u")
	await get_tree().process_frame
	_apply_emote("laugh")
	await get_tree().process_frame
	await _run_clear_viseme_coordinator()
	await get_tree().create_timer(0.3).timeout
	lines.append("defer_laugh split=%.3f u=%.3f" % [
		_face.read_primary_on_mesh(body, "laugh"), _face.read_viseme_on_mesh(body, "u")
	])
	_apply_emote("smile")
	await get_tree().create_timer(0.2).timeout
	_apply_viseme("o")
	await get_tree().process_frame
	_apply_viseme("e")
	await get_tree().process_frame
	_apply_viseme("i")
	await get_tree().create_timer(0.25).timeout
	lines.append("rapid_i leak=%.4f" % _face.max_viseme_weight_excluding("i", 0.03))
	await _run_clear_viseme_coordinator()
	await get_tree().create_timer(0.3).timeout
	lines.append("final_smile=%.3f visemes_zero=%s" % [
		_face.read_primary_on_mesh(body, "smile"), _face.all_visemes_near_zero(0.03)
	])
	_push_key(KEY_4)
	await get_tree().process_frame
	var viseme_min: float = FacePresenter.APPROVED_VISEME_COEF * 0.92
	var ok: bool = (
		a_body > viseme_min
		and eyes_surprise_during > 0.85
		and _face.read_primary_on_mesh(body, "smile") > 0.85
		and _face.all_visemes_near_zero(0.03)
	)
	lines.append("=== viseme_coord_check_pass=%s ===" % str(ok))
	lines.append("regression_anim=%s" % _player.assigned_animation)
	print("\n".join(lines))
	get_tree().quit()


func _run_viseme_check() -> void:
	for _frame in 3:
		await get_tree().process_frame
	var body := _find_mesh("人体_001")
	if body == null:
		body = _find_mesh("人体.001")
	var lines: PackedStringArray = []
	for vid in ["a", "e", "i", "o", "u"]:
		_apply_viseme(vid)
		await get_tree().create_timer(0.25).timeout
		lines.append("viseme_%s sample=%.3f" % [vid, _face.read_viseme_on_mesh(body, vid)])
	var synced := 0
	var mesh_count := 0
	for mesh in _meshes:
		if not _face.is_viseme_participant_mesh(mesh):
			continue
		var v: float = _face.read_viseme_on_mesh(mesh, "u")
		if v < 0.0:
			continue
		mesh_count += 1
		if v > 0.85:
			synced += 1
	lines.append("viseme_u_participant_sync=%d/%d" % [synced, mesh_count])
	_apply_viseme("o")
	await get_tree().create_timer(0.25).timeout
	var brow := _find_mesh("眉毛")
	var eye_r := _find_mesh("眼睛右")
	var brow_o: float = _face.read_viseme_on_mesh(brow, "o") if brow != null else -1.0
	var eye_o: float = _face.read_viseme_on_mesh(eye_r, "o") if eye_r != null else -1.0
	var body_o: float = _face.read_viseme_on_mesh(body, "o")
	lines.append("partition_brow_o=%.3f eye_r_o=%.3f body_o=%.3f" % [brow_o, eye_o, body_o])
	_apply_viseme("a")
	await get_tree().process_frame
	_apply_viseme("o")
	await get_tree().create_timer(0.25).timeout
	lines.append("switch_a_to_o a=%.3f o=%.3f" % [
		_face.read_viseme_on_mesh(body, "a"), _face.read_viseme_on_mesh(body, "o")
	])
	await _run_clear_viseme_coordinator()
	await get_tree().create_timer(0.08).timeout
	lines.append("after_clear active=%s o=%.3f" % [_face.get_active_viseme(), _face.read_viseme_on_mesh(body, "o")])
	_apply_emote("smile")
	_apply_viseme("a")
	await get_tree().create_timer(0.25).timeout
	lines.append("coexist_smile_a split=%.3f A=%.3f face=%s" % [
		_face.read_primary_on_mesh(body, "smile"), _face.read_viseme_on_mesh(body, "a"), _face.get_active_primary()
	])
	_apply_emote("surprise")
	_apply_viseme("u")
	await get_tree().create_timer(0.25).timeout
	lines.append("coexist_surprise_u split=%.3f u=%.3f" % [
		_face.read_primary_on_mesh(body, "surprise"), _face.read_viseme_on_mesh(body, "u")
	])
	_apply_viseme("e")
	await get_tree().process_frame
	_apply_viseme("i")
	await get_tree().process_frame
	_apply_viseme("e")
	await get_tree().create_timer(0.25).timeout
	lines.append("rapid_e_i_e e=%.3f i=%.3f" % [_face.read_viseme_on_mesh(body, "e"), _face.read_viseme_on_mesh(body, "i")])
	if not _face.set_viseme("invalid_viseme"):
		lines.append("missing_viseme_rejected=true")
	_push_key(KEY_4)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("regression_key4=%s face=%s viseme=%s" % [
		_player.assigned_animation, _face.get_active_primary(), _face.get_active_viseme()
	])
	print("\n".join(lines))
	get_tree().quit()


func _run_expression_isolation_check() -> void:
	for _frame in 3:
		await get_tree().process_frame
	var body := _find_mesh("人体_001")
	if body == null:
		body = _find_mesh("人体.001")
	var lines: PackedStringArray = []
	for primary in ["smile", "surprise", "laugh", "wink", "grin", "angry"]:
		_apply_emote(primary)
		await get_tree().create_timer(0.25).timeout
		var ok := false
		if primary in FacePresenter.GAZE_KEYS:
			var idx := body.find_blend_shape_by_name(primary)
			var v := body.get_blend_shape_value(idx) if idx >= 0 else -1.0
			ok = v > 0.85 and _read_legacy_on_body(body, "smile") < 0.05
			lines.append("isolated_%s composite=%.3f ok=%s" % [primary, v, str(ok)])
		else:
			var split_v: float = _face.read_primary_on_mesh(body, primary)
			var legacy_v := _read_legacy_on_body(body, primary)
			ok = split_v > 0.85 and legacy_v < 0.05
			lines.append("isolated_%s split=%.3f legacy=%.3f ok=%s" % [primary, split_v, legacy_v, str(ok)])
	print("\n".join(lines))
	get_tree().quit()


func _run_pending_attract_check() -> void:
	for _frame in 4:
		await get_tree().process_frame
	var lines: PackedStringArray = []
	_wait_timer.stop()
	_mode = ScheduleMode.BASE_IDLE
	_start_idle(true)
	lines.append("idle_len=%.3f" % _player.current_animation_length)
	_push_key(KEY_M)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("base_m queued=%s anim=%s mode=%s timer_stopped=%s" % [
		_pending_attract_request, _player.assigned_animation, _mode, _wait_timer.is_stopped()
	])
	_on_light_wait_timeout()
	lines.append("pending_blocks_light=%s" % str(_player.assigned_animation == IDLE_ANIM and _mode == ScheduleMode.BASE_IDLE))
	_push_key(KEY_M)
	await get_tree().process_frame
	lines.append("duplicate_m_ignored=%s" % str(_pending_attract_request))
	var attract_after_cycle := await _wait_for_attract_playing(4.0)
	lines.append("base_cycle_attract=%s mode=%s pending=%s" % [attract_after_cycle, _mode, _pending_attract_request])
	_player.speed_scale = 40.0
	await _finish_auto_to_base(lines, "attract_return")
	_player.speed_scale = 1.0
	_wait_timer.stop()
	_on_light_wait_timeout()
	var light_name := String(_player.assigned_animation)
	_push_key(KEY_M)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("light_m queued=%s still_light=%s anim=%s" % [
		_pending_attract_request, _player.assigned_animation == light_name and _mode == ScheduleMode.LIGHT_IDLE, _player.assigned_animation
	])
	_player.speed_scale = 40.0
	var waited := 0.0
	var direct_attract := ""
	while waited < 3.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
		if _mode == ScheduleMode.ATTRACT:
			direct_attract = String(_player.assigned_animation)
			break
	_player.speed_scale = 1.0
	lines.append("light_to_attract=%s skipped_base=%s" % [direct_attract, direct_attract != "" and direct_attract in _attract_pool])
	await _finish_auto_to_base(lines, "light_chain")
	_wait_timer.stop()
	_play_auto_attract()
	await get_tree().process_frame
	await get_tree().process_frame
	var during := String(_player.assigned_animation)
	var during_mode := _mode
	_push_key(KEY_M)
	await get_tree().process_frame
	_push_key(KEY_M)
	await get_tree().process_frame
	lines.append("attract_double_m pending=%s anim=%s mode=%s held=%s" % [
		_pending_attract_request, during, during_mode, _player.assigned_animation == during and _mode == ScheduleMode.ATTRACT
	])
	_push_key(KEY_H)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("manual_m_ignored pending=%s mode=%s" % [_pending_attract_request, _mode])
	_push_key(KEY_I)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("i_clears pending=%s timer=%s anim=%s" % [_pending_attract_request, not _wait_timer.is_stopped(), _player.assigned_animation])
	print("\n".join(lines))
	get_tree().quit()


func _run_blend_check() -> void:
	_wait_timer.stop()
	for _frame in 4:
		await get_tree().process_frame
	var pivot := get_node("ObservePivot") as Node3D
	var camera := pivot.get_node("Camera3D") as Camera3D
	var pivot_before := pivot.global_transform
	var camera_before := camera.global_transform
	var lines: PackedStringArray = []
	var body := _find_mesh("人体_001")
	var surprise_index := body.find_blend_shape_by_name("surprise")
	lines.append("default_blend=" + str(_player.playback_default_blend_time))
	var saved_rots: Dictionary = _snapshot_bone_rotations()
	var returns_before := _auto_return_count
	_play_auto_light()
	var light_name := String(_player.assigned_animation)
	var light_pos := _player.current_animation_position
	var gap := _largest_rotation_gap(saved_rots, light_name)
	var gap_bone := String(gap["bone"])
	var gap_amount := float(gap["gap"])
	var bone_index := _skeleton.find_bone(gap_bone)
	await get_tree().process_frame
	var early_delta := _rotation_delta(saved_rots, gap_bone)
	await get_tree().create_timer(0.12).timeout
	var mid_delta := _rotation_delta(saved_rots, gap_bone)
	await get_tree().create_timer(0.2).timeout
	var late_delta := _rotation_delta(saved_rots, gap_bone)
	var late_to_target := 0.0
	if bone_index >= 0:
		var target_now := _bone_rotation_at(light_name, gap_bone, _player.current_animation_position)
		late_to_target = _skeleton.get_bone_pose_rotation(bone_index).angle_to(target_now)
	var root_delta := _hips_position_at(IDLE_ANIM, 0.0).distance_to(_hips_position_at(light_name, 0.0))
	lines.append("base_to_light anim=%s loop=%s start_pos=%.3f blend=%.2f bone=%s gap=%.4f early=%.4f mid=%.4f late=%.4f late_to_target=%.4f root_delta=%.4f" % [
		light_name, _player.get_animation(light_name).loop_mode, light_pos, _last_blend, gap_bone, gap_amount, early_delta, mid_delta, late_delta, late_to_target, root_delta
	])
	lines.append("base_to_light_eased=" + str(gap_amount > 0.05 and early_delta < gap_amount * 0.45 and late_delta > early_delta))
	_player.seek(maxf(_player.current_animation_length - 0.04, 0.0), true)
	var end_pose := _snapshot_bone_rotations()
	var back_gap := _largest_rotation_gap(end_pose, IDLE_ANIM)
	var back_bone := String(back_gap["bone"])
	var back_amount := float(back_gap["gap"])
	var back_root := _skeleton.get_bone_pose_position(_skeleton.find_bone("mixamorig_Hips")).distance_to(_hips_position_at(IDLE_ANIM, 0.0))
	await get_tree().create_timer(0.08).timeout
	var back_early := _rotation_delta(end_pose, back_bone)
	await get_tree().create_timer(0.15).timeout
	var back_mid := _rotation_delta(end_pose, back_bone)
	await get_tree().create_timer(0.2).timeout
	var back_late := _rotation_delta(end_pose, back_bone)
	lines.append("light_to_base bone=%s gap=%.4f early=%.4f mid=%.4f late=%.4f blend=%.2f anim=%s root=%.4f" % [
		back_bone, back_amount, back_early, back_mid, back_late, _last_blend, _player.assigned_animation, back_root
	])
	lines.append("light_to_base_eased=" + str(back_amount > 0.15 and back_early < back_amount * 0.55 and back_late > back_early))
	_player.speed_scale = 40.0
	var light_returned := await _await_base_idle(2.0)
	_player.speed_scale = 1.0
	lines.append("light_returned=%s returns=%d anim=%s blend=%.2f timer=%s" % [
		light_returned, _auto_return_count - returns_before, _player.assigned_animation, _last_blend, not _wait_timer.is_stopped()
	])
	_wait_timer.stop()
	returns_before = _auto_return_count
	_push_key(KEY_M)
	await get_tree().process_frame
	await get_tree().process_frame
	var attract_name := String(_player.assigned_animation)
	await get_tree().create_timer(0.12).timeout
	lines.append("base_to_attract anim=%s blend=%.2f mode=%s still=%s timer_stopped=%s" % [
		attract_name, _last_blend, _mode, _player.assigned_animation == attract_name and _mode == ScheduleMode.ATTRACT, _wait_timer.is_stopped()
	])
	_player.speed_scale = 40.0
	var attract_returned := await _await_base_idle(2.0)
	_player.speed_scale = 1.0
	lines.append("attract_returned=%s returns=%d anim=%s blend=%.2f" % [
		attract_returned, _auto_return_count - returns_before, _player.assigned_animation, _last_blend
	])
	_wait_timer.stop()
	_play_auto_light()
	var interrupted := String(_player.assigned_animation)
	_player.seek(maxf(_player.current_animation_length - 0.05, 0.0), true)
	returns_before = _auto_return_count
	_push_key(KEY_M)
	await get_tree().process_frame
	await get_tree().process_frame
	var interrupt_blend := _last_blend
	var interrupt_anim := String(_player.assigned_animation)
	await get_tree().create_timer(0.45).timeout
	lines.append("m_interrupts from=%s to=%s blend=%.2f held=%s mode=%s returns=%d" % [
		interrupted, interrupt_anim, interrupt_blend, _player.assigned_animation == interrupt_anim and _mode == ScheduleMode.ATTRACT, _mode, _auto_return_count - returns_before
	])
	_player.seek(1.2, true)
	var held_pos := _player.current_animation_position
	_push_key(KEY_M)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("m_ignored anim=%s pos=%.2f" % [_player.assigned_animation, _player.current_animation_position])
	lines.append("m_ignored_held=" + str(_player.assigned_animation == interrupt_anim and _player.current_animation_position > held_pos - 0.05))
	_player.speed_scale = 40.0
	var interrupt_returned := await _await_base_idle(2.0)
	_player.speed_scale = 1.0
	lines.append("interrupt_returned=%s anim=%s" % [interrupt_returned, _player.assigned_animation])
	_push_key(KEY_H)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("key_h=%s mode=%s timer_stopped=%s" % [_player.assigned_animation, _mode, _wait_timer.is_stopped()])
	_player.seek(2.0, true)
	_push_key(KEY_H)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("hello_restart_pos=%.3f" % _player.current_animation_position)
	_push_key(KEY_4)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("key_4=" + _player.assigned_animation)
	_push_key(KEY_5)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("key_5=" + _player.assigned_animation)
	_push_key(KEY_X)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("key_x=%s loop=%s" % [_player.assigned_animation, _player.get_animation("youyou_Basic_Idle01").loop_mode])
	_push_key(KEY_6)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("key_6=" + _player.assigned_animation)
	_push_key(KEY_I)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("key_i=%s mode=%s timer=%s" % [_player.assigned_animation, _mode, not _wait_timer.is_stopped()])
	_push_key(KEY_2)
	await get_tree().process_frame
	await get_tree().process_frame
	lines.append("expr anim=%s timer=%s surprise=%.1f" % [
		_player.assigned_animation, not _wait_timer.is_stopped(), body.get_blend_shape_value(surprise_index)
	])
	lines.append("pivot_same=" + str(pivot.global_transform.is_equal_approx(pivot_before)))
	lines.append("camera_same=" + str(camera.global_transform.is_equal_approx(camera_before)))
	lines.append("default_blend_after=" + str(_player.playback_default_blend_time))
	_player.speed_scale = 1.0
	print("\n".join(lines))
	get_tree().quit()


func _await_base_idle(limit: float) -> bool:
	var waited := 0.0
	while waited < limit:
		await get_tree().process_frame
		waited += get_process_delta_time()
		if _mode == ScheduleMode.BASE_IDLE and _player.assigned_animation == IDLE_ANIM and _player.is_playing() and not _wait_timer.is_stopped():
			return true
	return false


func _snapshot_bone_rotations() -> Dictionary:
	var saved: Dictionary = {}
	for index in _skeleton.get_bone_count():
		saved[_skeleton.get_bone_name(index)] = _skeleton.get_bone_pose_rotation(index)
	return saved


func _largest_rotation_gap(saved: Dictionary, anim_name: String) -> Dictionary:
	var best_bone := ""
	var best_gap := 0.0
	var clip := _player.get_animation(anim_name)
	for index in clip.get_track_count():
		if clip.track_get_type(index) != Animation.TYPE_ROTATION_3D:
			continue
		var bone_name := String(clip.track_get_path(index).get_concatenated_subnames())
		if not saved.has(bone_name) or _skeleton.find_bone(bone_name) < 0:
			continue
		var target := clip.rotation_track_interpolate(index, 0.0)
		var gap := (saved[bone_name] as Quaternion).angle_to(target)
		if gap > best_gap:
			best_gap = gap
			best_bone = bone_name
	return {"bone": best_bone, "gap": best_gap}


func _rotation_delta(saved: Dictionary, bone_name: String) -> float:
	var index := _skeleton.find_bone(bone_name)
	if index < 0 or not saved.has(bone_name):
		return 0.0
	return (saved[bone_name] as Quaternion).angle_to(_skeleton.get_bone_pose_rotation(index))


func _bone_rotation_at(anim_name: String, bone_name: String, time: float) -> Quaternion:
	var clip := _player.get_animation(anim_name)
	for index in clip.get_track_count():
		if clip.track_get_type(index) != Animation.TYPE_ROTATION_3D:
			continue
		if String(clip.track_get_path(index).get_concatenated_subnames()) != bone_name:
			continue
		return clip.rotation_track_interpolate(index, time)
	return Quaternion.IDENTITY


func _hips_rotation_at(anim_name: String, time: float) -> Quaternion:
	var track := _hips_track(anim_name, Animation.TYPE_ROTATION_3D)
	if track < 0:
		return Quaternion.IDENTITY
	return _player.get_animation(anim_name).rotation_track_interpolate(track, time)


func _hips_position_at(anim_name: String, time: float) -> Vector3:
	var track := _hips_track(anim_name, Animation.TYPE_POSITION_3D)
	if track < 0:
		return Vector3.ZERO
	return _player.get_animation(anim_name).position_track_interpolate(track, time)


func _hips_track(anim_name: String, track_type: Animation.TrackType) -> int:
	if _player == null or not _player.has_animation(anim_name):
		return -1
	var clip := _player.get_animation(anim_name)
	for index in clip.get_track_count():
		if clip.track_get_type(index) != track_type:
			continue
		if String(clip.track_get_path(index).get_concatenated_subnames()) == "mixamorig_Hips":
			return index
	return -1


func _save_check_png(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	print("png %s err=%s" % [path, err])


const VISEME_DIAG_WATCH: PackedStringArray = [
	"A", "E", "i", "o", "u",
	"smile", "surprise", "laugh",
	"jawOpen", "mouthSmileLeft", "mouthSmileRight",
	"noseSneerLeft", "noseSneerRight", "jawForward",
]


func _run_viseme_diagnose() -> void:
	_schedule_enabled = false
	if _wait_timer != null:
		_wait_timer.stop()
	await get_tree().process_frame
	await get_tree().process_frame
	_diagnose_freeze_idle_pose()
	var lines: PackedStringArray = []
	lines.append("=== viseme_diagnose_begin ===")
	lines.append("face_meshes=" + _diagnose_face_mesh_catalog())
	lines.append("anim=" + str(_player.assigned_animation if _player else "") + " playing=" + str(_player.is_playing() if _player else false))
	for vid in ["a", "e", "i", "o", "u"]:
		for group in ["A", "B", "C", "D"]:
			await _diagnose_apply_group(group, vid)
			await get_tree().create_timer(FacePresenter.VISEME_BLEND_TIME + 0.15).timeout
			var leak := _diagnose_viseme_leak(vid)
			lines.append("--- viseme=%s group=%s leak_other_viseme_max=%.4f ---" % [vid, group, leak])
			for mesh in _diagnose_face_meshes():
				lines.append(_diagnose_mesh_row(group, vid, mesh))
			if group == "B" or group == "C" or group == "D":
				lines.append(_diagnose_body_summary(group, vid))
	_diagnose_restore_production_default()
	lines.append("restore smile=" + _diagnose_read_shape(_find_body_mesh(), "smile"))
	lines.append("restore viseme_active=" + str(_face.get_active_viseme()))
	lines.append("=== viseme_diagnose_end ===")
	print("\n".join(lines))
	get_tree().quit()


func _diagnose_freeze_idle_pose() -> void:
	if _player == null:
		return
	if _player.has_animation(IDLE_ANIM):
		_player.play(IDLE_ANIM, 0.0)
		_player.seek(0.0, true)
		_player.pause()


func _diagnose_face_meshes() -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for mesh in _meshes:
		if mesh.find_blend_shape_by_name("A") >= 0:
			out.append(mesh)
	return out


func _diagnose_viseme_participant_meshes() -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if _face == null:
		return out
	for mesh in _meshes:
		if _face.is_viseme_participant_mesh(mesh):
			out.append(mesh)
	return out


func _diagnose_face_mesh_catalog() -> String:
	var parts: PackedStringArray = []
	var idx := 0
	for mesh in _diagnose_face_meshes():
		parts.append("%d:%s" % [idx, mesh.name])
		idx += 1
	return "|".join(parts)


func _find_body_mesh() -> MeshInstance3D:
	var body := _find_mesh("人体_001")
	if body == null:
		body = _find_mesh("人体.001")
	if body == null and not _diagnose_face_meshes().is_empty():
		body = _diagnose_face_meshes()[0]
	return body


func _diagnose_restore_production_default() -> void:
	if _face != null:
		_face.reset_all(0.0)


func _diagnose_apply_group(group: String, viseme_id: String) -> void:
	match group:
		"A":
			_diagnose_restore_production_default()
		"B":
			_diagnose_restore_production_default()
			_face.set_emotion("smile", 0.0)
			_face.set_viseme(viseme_id, 0.0)
		"C":
			_diagnose_restore_production_default()
			_face.set_viseme(viseme_id, 0.0)
		"D":
			_diagnose_restore_production_default()
			_face.set_viseme(viseme_id, FacePresenter.VISEME_BLEND_TIME)
		_:
			pass


func _diagnose_set_all_primary_weights(_smile_weight: float) -> void:
	if _face != null:
		_face.set_emotion("smile", 0.0)


func _diagnose_reset_p1_micro_baseline() -> void:
	pass


func _diagnose_read_shape(mesh: MeshInstance3D, shape_name: String) -> String:
	if mesh == null:
		return "na"
	var index := mesh.find_blend_shape_by_name(shape_name)
	if index < 0:
		return "miss"
	return "%.3f" % mesh.get_blend_shape_value(index)


func _diagnose_viseme_leak(active_vid: String) -> float:
	var shape_for: Dictionary = {"a": "A", "e": "E", "i": "i", "o": "o", "u": "u"}
	var active_shape := String(shape_for.get(active_vid, ""))
	var max_leak := 0.0
	for mesh in _diagnose_face_meshes():
		for vid in ["a", "e", "i", "o", "u"]:
			var sh := String(FacePresenter.VISEME_SHAPE_NAMES[vid])
			if sh == active_shape:
				continue
			var index := mesh.find_blend_shape_by_name(sh)
			if index >= 0:
				max_leak = maxf(max_leak, mesh.get_blend_shape_value(index))
	return max_leak


func _diagnose_mesh_row(group: String, viseme_id: String, mesh: MeshInstance3D) -> String:
	var cols: PackedStringArray = ["grp=%s" % group, "v=%s" % viseme_id, "mesh=%s" % mesh.name]
	for shape_name in VISEME_DIAG_WATCH:
		cols.append("%s=%s" % [shape_name, _diagnose_read_shape(mesh, shape_name)])
	return " ".join(cols)


func _diagnose_body_summary(group: String, viseme_id: String) -> String:
	var body := _find_body_mesh()
	var shape_name := String(FacePresenter.VISEME_SHAPE_NAMES.get(viseme_id, ""))
	return "summary grp=%s v=%s body_%s=%s smile=%s anim_track_probe=%s" % [
		group, viseme_id, shape_name, _diagnose_read_shape(body, shape_name),
		_diagnose_read_shape(body, "smile"),
		_diagnose_animation_blendshape_probe(body)
	]


func _diagnose_animation_blendshape_probe(body: MeshInstance3D) -> String:
	if _player == null or body == null:
		return "no_player"
	var anim := _player.get_animation(_player.assigned_animation)
	if anim == null:
		return "no_anim"
	var hits := 0
	for i in anim.get_track_count():
		if anim.track_get_type(i) != Animation.TYPE_BLEND_SHAPE:
			continue
		var path := String(anim.track_get_path(i))
		if body.name in path or "smile" in path or "A" in path:
			hits += 1
	return "blend_shape_tracks=" + str(hits)


func _push_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	event.echo = false
	get_viewport().push_input(event)


func _find_mesh(mesh_name: String) -> MeshInstance3D:
	for mesh in _meshes:
		if mesh.name == mesh_name:
			return mesh
	return null


func _count_players(node: Node) -> int:
	var count := 1 if node is AnimationPlayer else 0
	for child in node.get_children():
		count += _count_players(child)
	return count


func _run_performance_expression_check() -> void:
	for _i in 3:
		await get_tree().process_frame
	var body := _find_mesh("人体_001")
	var lines: PackedStringArray = []
	lines.append("startup_anim=%s face=%s pose=%s" % [
		_player.assigned_animation, _face.get_active_primary(), _performance_pose.get_current_pose()
	])
	lines.append("startup_smile=%.3f" % _face.read_primary_on_mesh(body, "smile"))

	var gen_before := _hello_perf_gen
	_start_hello()
	await get_tree().process_frame
	lines.append("hello_started laugh=%.3f gen=%s pose=%s" % [
		_face.read_primary_on_mesh(body, "laugh"), _hello_perf_gen, _performance_pose.get_current_pose()
	])
	var hello_emotion_wall := _expected_emotion_wall_for_action(HELLO_ANIM)
	await get_tree().create_timer(hello_emotion_wall + 0.12).timeout
	var laugh_mid: float = _face.read_primary_on_mesh(body, "laugh")
	lines.append("hello_mid_laugh=%.3f progress=%.3f emotion_wall=%.3f" % [
		laugh_mid, _face.get_transition_progress(), hello_emotion_wall
	])

	_play_batch_oneshot("hello01")
	await get_tree().process_frame
	lines.append("interrupt_oneshot anim=%s hello_active=%s" % [_player.assigned_animation, _hello_active])
	_player.speed_scale = 35.0
	var waited := 0.0
	while waited < 2.5:
		await get_tree().process_frame
		waited += get_process_delta_time()
		if _player.assigned_animation == IDLE_ANIM and _player.is_playing():
			break
	_player.speed_scale = 1.0
	await get_tree().create_timer(_performance_pose.performance_blend_duration() + 0.12).timeout
	var smile_after_oneshot: float = _face.read_primary_on_mesh(body, "smile")
	lines.append("after_oneshot_smile=%.3f" % smile_after_oneshot)

	_start_hello()
	var stale_gen := gen_before
	_play_batch_oneshot("Hand Wave_rig_01")
	await get_tree().process_frame
	lines.append("stale_hello_gen=%s current_gen=%s" % [stale_gen, _hello_perf_gen])
	if _performance_pose.hello_end_may_run(stale_gen):
		lines.append("stale_hello_leak=true")
	else:
		lines.append("stale_hello_blocked=true")

	_start_hello()
	await get_tree().process_frame
	_start_hello()
	await get_tree().process_frame
	lines.append("double_hello laugh=%.3f" % _face.read_primary_on_mesh(body, "laugh"))

	_wait_timer.stop()
	_mode = ScheduleMode.BASE_IDLE
	await get_tree().create_timer(0.12).timeout
	_apply_emote("sad")
	await get_tree().create_timer(0.08).timeout
	var sad_mid: float = _face.read_primary_on_mesh(body, "sad")
	_start_hello()
	await get_tree().process_frame
	lines.append("expr_interrupt sad_mid=%.3f laugh=%.3f" % [
		sad_mid, _face.read_primary_on_mesh(body, "laugh")
	])

	_enter_manual()
	_start_idle(true)
	await get_tree().create_timer(_performance_pose.performance_blend_duration() + 0.15).timeout
	lines.append("hello_end_smile=%.3f" % _face.read_primary_on_mesh(body, "smile"))

	_mode = ScheduleMode.BASE_IDLE
	_play_auto_attract()
	var attract_anim := String(_player.assigned_animation)
	var attract_wall := _expected_emotion_wall_for_action(attract_anim)
	var attract_waited := 0.0
	while attract_waited < attract_wall + 0.35:
		await get_tree().process_frame
		attract_waited += get_process_delta_time()
	lines.append("auto_attract anim=%s wall=%.3f laugh=%.3f mode=%s" % [
		attract_anim, attract_wall, _face.read_primary_on_mesh(body, "laugh"), _mode
	])
	_enter_manual()
	_start_idle(true)
	await get_tree().create_timer(_performance_pose.performance_blend_duration() + 0.15).timeout
	lines.append("auto_attract_interrupt_smile=%.3f" % _face.read_primary_on_mesh(body, "smile"))

	var face_peak_after_oneshot := maxf(
		_face.read_primary_on_mesh(body, "smile"),
		_face.read_primary_on_mesh(body, "laugh"),
	)
	var ok: bool = (
		lines.has("stale_hello_blocked=true")
		and laugh_mid > 0.05
		and face_peak_after_oneshot > 0.85
		and _face.read_primary_on_mesh(body, "smile") > 0.85
	)
	lines.append("=== performance_expression_check_pass=%s ===" % str(ok))
	print("\n".join(lines))
	get_tree().quit()


func _init_idle_presence() -> void:
	_presence_camera = get_node_or_null("ObservePivot/Camera3D") as Camera3D
	var gaze := GazeController.new()
	gaze.name = "EyeGazeController"
	add_child(gaze)
	gaze.setup(_model, _presence_camera)
	var head := HeadFollow.new()
	head.name = "HeadFollowController"
	add_child(head)
	head.setup(_model)
	_idle_life = IdleLife.new()
	_idle_life.name = "IdleLifeController"
	add_child(_idle_life)
	_idle_life.call("setup", gaze, head)
	_idle_life.call("set_manual_input_enabled", false)
	_idle_life.call("set_performance_state", IdleLife.PerfState.BASE_IDLE)
	_idle_life.set_process(false)


func _is_presence_base_idle() -> bool:
	return (
		_player != null
		and _mode == ScheduleMode.BASE_IDLE
		and not _hello_active
		and _oneshot_name == ""
		and _player.assigned_animation == IDLE_ANIM
		and _player.is_playing()
	)


func _sync_idle_presence() -> void:
	if _idle_life == null:
		return
	var on := _is_presence_base_idle()
	_idle_life.call("set_blink_channel", true)
	var wink_active := _face != null and _face.get_active_primary() == "wink"
	var squint_emotion := (
		_face != null
		and FacePresenter.emotion_should_mask_blink(_face.get_active_emotion())
	)
	_idle_life.call("set_blink_masked", wink_active or squint_emotion)
	if (_grab_flow != null and _grab_flow.wants_look()) or _claw_stick_control_active():
		_idle_life.set_process(true)
		_idle_life.call("set_gaze_channel", true)
		_idle_life.call("set_head_channel", true)
		_idle_life.call("set_manual_input_enabled", true)
		return
	_idle_life.call("set_gaze_channel", on)
	_idle_life.call("set_head_channel", on)


func _mesh_named(mesh_name: String) -> MeshInstance3D:
	for mesh in _meshes:
		if String(mesh.name) == mesh_name:
			return mesh
	return null


func _run_idle_presence_check() -> void:
	for _i in 3:
		await get_tree().process_frame
	if _idle_life != null:
		_idle_life.set_process(false)
	var lines: PackedStringArray = []
	var ok := _idle_life != null and _player != null
	ok = ok and not _idle_life.call("is_manual_input_enabled")
	_mode = ScheduleMode.BASE_IDLE
	_hello_active = false
	_oneshot_name = ""
	if _player.assigned_animation != IDLE_ANIM or not _player.is_playing():
		_start_idle(true)
	_sync_idle_presence()
	ok = ok and _is_presence_base_idle()
	ok = ok and _idle_life.call("is_blink_channel_enabled")
	ok = ok and _idle_life.call("is_gaze_channel_enabled")
	ok = ok and _idle_life.call("is_head_channel_enabled")
	seed(90210)
	var blink_peaks := 0
	var glance_peaks := 0
	var head_peaks := 0
	for _step in 900:
		_idle_life.call("process_life", 0.02, get_viewport())
		var snap: Dictionary = _idle_life.call("get_debug_snapshot")
		if float(snap.get("blink_weight", 0.0)) > 0.65:
			blink_peaks += 1
		if float(snap.get("look_peak", 0.0)) > 0.02:
			glance_peaks += 1
		var head_motion := maxf(
			absf(float(snap.get("head_yaw_deg", 0.0))),
			absf(float(snap.get("head_pitch_deg", 0.0))),
		)
		if head_motion > 0.03:
			head_peaks += 1
	ok = ok and blink_peaks > 3 and glance_peaks > 5 and head_peaks > 3
	lines.append("base_blink=%d base_glance=%d base_head=%d" % [blink_peaks, glance_peaks, head_peaks])
	var eye := _mesh_named("眼睛左")
	var body := _mesh_named("人体_001")
	var look_i := eye.find_blend_shape_by_name("eyeLookOutLeft") if eye != null else -1
	var mouth_i := body.find_blend_shape_by_name("A") if body != null else -1
	var head_idx := _skeleton.find_bone("mixamorig_Head") if _skeleton != null else -1
	_play_auto_light()
	_sync_idle_presence()
	var light_split: bool = (
		_idle_life.call("is_blink_channel_enabled")
		and not _idle_life.call("is_gaze_channel_enabled")
		and not _idle_life.call("is_head_channel_enabled")
	)
	ok = ok and light_split and _mode == ScheduleMode.LIGHT_IDLE
	_idle_life.call("process_life", 0.02, get_viewport())
	if look_i >= 0:
		eye.set_blend_shape_value(look_i, 0.41)
	if mouth_i >= 0:
		body.set_blend_shape_value(mouth_i, 0.66)
	var head_before := _skeleton.get_bone_pose_rotation(head_idx) if head_idx >= 0 else Quaternion.IDENTITY
	for _hold in 4:
		_idle_life.call("process_life", 0.02, get_viewport())
	var look_held := eye.get_blend_shape_value(look_i) if look_i >= 0 else -1.0
	var mouth_held := body.get_blend_shape_value(mouth_i) if mouth_i >= 0 else -1.0
	var head_after := _skeleton.get_bone_pose_rotation(head_idx) if head_idx >= 0 else Quaternion.IDENTITY
	ok = ok and absf(look_held - 0.41) < 0.02
	ok = ok and absf(mouth_held - 0.66) < 0.02
	ok = ok and head_before.is_equal_approx(head_after)
	lines.append("light_hold look=%.3f mouth=%.3f" % [look_held, mouth_held])
	var phase_before: String = String(_idle_life.call("get_debug_snapshot").get("blink_phase", ""))
	_play_auto_attract()
	_sync_idle_presence()
	var switched_clean: bool = (
		_mode == ScheduleMode.ATTRACT
		and not _is_presence_base_idle()
		and _idle_life.call("is_blink_channel_enabled")
		and not _idle_life.call("is_gaze_channel_enabled")
		and String(_idle_life.call("get_debug_snapshot").get("blink_phase", "")) == phase_before
	)
	ok = ok and switched_clean
	lines.append("light_to_attract_clean=%s" % str(switched_clean))
	var attract_blinks := 0
	for _step in 500:
		_idle_life.call("process_life", 0.02, get_viewport())
		if float(_idle_life.call("get_debug_snapshot").get("blink_weight", 0.0)) > 0.65:
			attract_blinks += 1
	ok = ok and attract_blinks > 3
	lines.append("attract_blink_frames=%d" % attract_blinks)
	_start_hello()
	_sync_idle_presence()
	ok = ok and _mode == ScheduleMode.MANUAL_TEST and not _idle_life.call("is_head_channel_enabled")
	lines.append("interrupt_manual=%s" % str(_mode == ScheduleMode.MANUAL_TEST))
	_hello_active = false
	_oneshot_name = ""
	_mode = ScheduleMode.BASE_IDLE
	_start_idle(true)
	_sync_idle_presence()
	ok = ok and _is_presence_base_idle() and _idle_life.call("is_blink_channel_enabled")
	if mouth_i >= 0:
		ok = ok and absf(body.get_blend_shape_value(mouth_i) - 0.66) < 0.02
	lines.append("restored_base=%s mouth_kept=%.3f" % [
		str(_is_presence_base_idle()),
		body.get_blend_shape_value(mouth_i) if mouth_i >= 0 else -1.0,
	])
	_face.set_gaze("wink", 0.0)
	_sync_idle_presence()
	var phase_wink: String = String(_idle_life.call("get_debug_snapshot").get("blink_phase", ""))
	for _mask in 12:
		_idle_life.call("process_life", 0.05, get_viewport())
	var snap_wink: Dictionary = _idle_life.call("get_debug_snapshot")
	var wink_ok: bool = (
		_idle_life.call("is_blink_masked")
		and String(snap_wink.get("blink_phase", "")) == phase_wink
		and float(snap_wink.get("blink_weight", 1.0)) < 0.08
	)
	ok = ok and wink_ok
	lines.append("wink_mask=%s phase=%s weight=%.3f" % [
		str(wink_ok), String(snap_wink.get("blink_phase", "")), float(snap_wink.get("blink_weight", -1.0))
	])
	_face.set_emotion("smile", 0.0)
	lines.append("=== idle_presence_check_pass=%s ===" % str(ok))
	print("\n".join(lines))
	get_tree().quit()


func _vad_ab_dev_keyboard() -> bool:
	var raw := OS.get_environment("YOUYOU_VAD_DEV_KEYS").strip_edges().to_lower()
	return raw in ["1", "true", "yes", "on"]


func _is_keycode(key: InputEventKey, code: Key) -> bool:
	return key.keycode == code or key.physical_keycode == code


func _start_precoin() -> void:
	if _precoin_enabled:
		return
	_schedule_enabled = false
	if _wait_timer != null:
		_wait_timer.stop()
	_precoin = PrecoinScheduler.new()
	_precoin.name = "PrecoinScheduler"
	add_child(_precoin)
	_precoin.setup(self, _precoin_entries(), {
		"to_light": BLEND_BASE_TO_LIGHT,
		"to_attract": BLEND_BASE_TO_ATTRACT,
		"light_to_base": BLEND_LIGHT_TO_BASE,
		"attract_to_base": BLEND_ATTRACT_TO_BASE,
	})
	_precoin_enabled = true
	_mode = ScheduleMode.BASE_IDLE
	_precoin.start()
	_note(
		"投币前调度已启动。M 进入语音交互；连续 %.0f 秒不说话则离开并开始招揽。Ctrl+T 投币。"
		% VOICE_SILENCE_LEAVE_SEC
	)


func _precoin_entries() -> Array:
	var entries: Array = []
	var general: Array = []
	for action_id in _general_light_pool:
		general.append(action_id)
	general.shuffle()
	for action_id in general:
		entries.append({
			"id": action_id,
			"kind": "general_light",
			"weight": 1.0,
		})
	var exclusive: Array = []
	for action_id in _light_pool:
		exclusive.append(action_id)
	exclusive.shuffle()
	for action_id in exclusive:
		entries.append({
			"id": action_id,
			"kind": "exclusive_light",
			"weight": 1.0,
		})
	var attract: Array = []
	for action_id in _attract_pool:
		attract.append(action_id)
	attract.shuffle()
	for action_id in attract:
		entries.append({
			"id": action_id,
			"kind": "attract",
			"weight": 1.0,
		})
	return entries


func precoin_log(message: String) -> void:
	_note("[待机] " + message)


func get_precoin_last_play_result() -> String:
	return _last_precoin_play_result


func precoin_should_defer_schedule() -> bool:
	if _event_playing:
		return true
	if _invite_blocks_idle_schedule() or _grab_blocks_idle_schedule():
		return true
	if _ai_voice_bridge != null and _ai_voice_bridge.holds_precoin_schedule():
		return true
	return false


func precoin_play_action(action_id: String, kind: String) -> bool:
	if _ai_voice_bridge != null and _ai_voice_bridge.holds_precoin_schedule():
		_last_precoin_play_result = "blocked_ai_phase id=%s" % action_id
		var perf := ""
		var coord = _ai_voice_bridge.get_coordinator()
		if coord != null:
			perf = coord.get_perf_state_name()
		PreviewVadEventLog.push("precoin_play_blocked", {
			"precoin_play": _last_precoin_play_result,
			"perf_state": perf,
		})
		precoin_log("拒绝招揽 %s（AI阶段=%s）" % [action_id, perf if perf != "" else "?"])
		return false
	if _invite_blocks_idle_schedule():
		_last_precoin_play_result = "blocked_minigame_invite id=%s" % action_id
		_note("[小游戏引导] 等待回答期间拒绝待机或招揽动作 %s" % action_id)
		return false
	if _grab_blocks_idle_schedule():
		_last_precoin_play_result = "blocked_grab id=%s" % action_id
		_note("[抓取] 抓取阶段拒绝待机或招揽动作 %s" % action_id)
		return false
	if _player == null:
		_last_precoin_play_result = "no_player id=%s" % action_id
		precoin_log("无法播放 %s：%s" % [action_id, _last_precoin_play_result])
		return false
	if not _player.has_animation(action_id):
		_last_precoin_play_result = "missing_anim id=%s" % action_id
		precoin_log("无法播放 %s：%s" % [action_id, _last_precoin_play_result])
		return false
	if not _is_approved_action(action_id):
		_last_precoin_play_result = "not_approved id=%s" % action_id
		precoin_log("无法播放 %s：%s" % [action_id, _last_precoin_play_result])
		return false
	if kind != "general_light" and kind != "exclusive_light" and kind != "attract":
		_last_precoin_play_result = "bad_kind=%s id=%s" % [kind, action_id]
		return false
	var blend := BLEND_BASE_TO_ATTRACT if kind == "attract" else BLEND_BASE_TO_LIGHT
	_hello_active = false
	_oneshot_name = ""
	_mode = ScheduleMode.ATTRACT if kind == "attract" else ScheduleMode.LIGHT_IDLE
	_active_finish_anim = action_id
	var clip := _player.get_animation(action_id)
	clip.loop_mode = Animation.LOOP_NONE
	_auto_perf_gen = _performance_pose.bump_auto_session()
	_play_clip(action_id, blend)
	_start_approved_performance(action_id, _auto_perf_gen)
	_last_precoin_play_result = "ok id=%s kind=%s" % [action_id, kind]
	return true


func precoin_return_to_base(action_id: String) -> float:
	if _approved_perf != null:
		_approved_perf.call("on_action_animation_finished", action_id, _auto_perf_gen)
	_mode = ScheduleMode.BASE_IDLE
	_active_finish_anim = ""
	_hello_active = false
	_oneshot_name = ""
	_start_idle(true)
	return _last_blend


func precoin_ensure_base_idle() -> void:
	_hello_active = false
	_oneshot_name = ""
	if _player != null and String(_player.assigned_animation) == IDLE_ANIM and _player.is_playing():
		_mode = ScheduleMode.BASE_IDLE
		return
	_mode = ScheduleMode.BASE_IDLE
	_start_idle(true)


func _init_preview_ai_voice() -> void:
	if _ai_voice_bridge != null:
		return
	_ai_voice_bridge = PreviewAiVoiceBridge.new()
	_ai_voice_bridge.name = "PreviewAiVoiceBridge"
	add_child(_ai_voice_bridge)
	_ai_voice_bridge.setup(self)
	if _ai_player_status == null:
		_ai_player_status = PreviewAiVoicePlayerStatus.new()
	var status_label: Label = null
	if _left_hud != null:
		status_label = _left_hud.get_voice_status_label()
		_left_hud.bind_voice_ai_bridge(_ai_voice_bridge)
	if status_label == null:
		_ensure_ai_player_prompt()
		status_label = _ai_player_prompt
	_ai_player_status.bind(self, status_label)


func get_face_presenter() -> FacePresenter:
	return _face


func _preview_ai_preempt(reason: String, resume_attract: bool = false) -> void:
	if _ai_voice_bridge != null:
		_ai_voice_bridge.request_preempt(reason, resume_attract)


func _ai_open_interaction_window() -> void:
	if _ai_voice_bridge != null:
		_ai_voice_bridge.open_interaction_window()


func _simulate_player_enter_interaction() -> void:
	if _round_business != null:
		var entered: Dictionary = _submit_round(ClawBusinessNode.PLAYER_ENTERED)
		if not bool(entered.get("ok", false)) and not _round_business.has_visitor():
			return
	elif _precoin != null:
		_precoin.set_player_present(true)
	else:
		return
	_ai_open_interaction_window()
	_arm_voice_silence_leave()


func _note_ctrl(key: InputEventKey) -> void:
	var is_ctrl_key := key.keycode == KEY_CTRL or key.physical_keycode == KEY_CTRL
	if is_ctrl_key:
		if key.pressed:
			_ctrl_latched = true
		else:
			_ctrl_latched = Input.is_physical_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_CTRL)
		return
	if key.ctrl_pressed or Input.is_physical_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_CTRL):
		_ctrl_latched = true


func _is_ctrl_combo(key: InputEventKey) -> bool:
	if not key.pressed or key.echo:
		return false
	if key.shift_pressed or key.alt_pressed or key.meta_pressed:
		return false
	if key.keycode == KEY_CTRL or key.physical_keycode == KEY_CTRL:
		return false
	return key.ctrl_pressed or _ctrl_latched or Input.is_physical_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_CTRL)


func _arm_voice_silence_leave() -> void:
	_silence_leave_at_msec = Time.get_ticks_msec() + int(VOICE_SILENCE_LEAVE_SEC * 1000.0)


func _sync_voice_panel_situation() -> void:
	if _left_hud == null or not _left_hud.has_method("set_voice_situation"):
		return
	var mode := ""
	var remain := -1.0
	if _invite_flow != null:
		match _invite_flow.phase_name():
			"PLAYING":
				mode = "invite_ask"
			"WAITING_ANSWER":
				mode = "invite_wait"
			"LISTENING":
				mode = "invite_listen"
				remain = _invite_flow.listen_remaining_sec()
	_left_hud.set_voice_situation(mode, remain)


func _poll_voice_silence_leave() -> void:
	if _silence_leave_at_msec <= 0:
		return
	if _ai_voice_bridge == null or not _ai_voice_bridge.is_window_armed():
		_silence_leave_at_msec = 0
		return
	if Time.get_ticks_msec() < _silence_leave_at_msec:
		return
	_silence_leave_at_msec = 0
	_preview_ai_preempt("silence_leave", true)


func _begin_attract_after_voice() -> void:
	if _precoin != null:
		_precoin.release_to_presence(true)
		return
	on_show_presence_request("attract")


func _keyboard_minigame_choice(play: bool) -> bool:
	if _invite_flow == null or not _invite_flow.holds_schedule():
		return false
	if _round_business == null:
		return false
	var intent := "PLAY" if play else "DECLINE"
	if not _round_business.is_invite_listen():
		_round_business.arm_keyboard_invite(intent)
	_invite_flow.accept_keyboard_intent(intent)
	_note("[小游戏] 键盘选择：%s。" % ("进入" if play else "不进入"))
	return true


func _simulate_player_leave_interaction() -> void:
	if _round_business != null:
		_submit_round(ClawBusinessNode.PLAYER_LEFT)
	else:
		_preview_ai_preempt("player_left", false)
		if _precoin != null:
			_precoin.set_player_present(false)


func preview_ai_on_window_closed(reason: String, resume_attract: bool) -> void:
	match reason:
		"silence_leave":
			_note("[AI] 五秒没有说话，离开语音交互，开始招揽。")
			_begin_attract_after_voice()
		"window_timeout":
			_note("[AI] 交互窗口超时，已关闭。按 M 可再进入。")
		"player_left", "player_leave_debug":
			_note("[AI] 玩家已离开交互区，AI 已关闭。")
		_:
			if reason != "":
				_note("[AI] 交互关闭 reason=%s" % reason)
	_silence_leave_at_msec = 0
	if resume_attract and reason != "silence_leave" and _precoin != null and _precoin.is_player_present() and not _precoin.is_business():
		_precoin.nudge_attract_after_voice_turn()
	if _ai_player_status != null:
		_ai_player_status.on_window_closed(reason)
	_refresh_debug_panel()


func preview_ai_voice_status(event: String, ctx: Dictionary) -> void:
	match event:
		"vad_listen", "asr", "llm_think", "tts_prep", "playback":
			_silence_leave_at_msec = 0
			if _ai_voice_bridge != null:
				_ai_voice_bridge.bump_window_for_activity()
		"wait_listen":
			if _ai_voice_bridge != null and _ai_voice_bridge.is_window_armed():
				_arm_voice_silence_leave()
	if _ai_player_status != null:
		_ai_player_status.handle(event, ctx)
	if _left_hud != null:
		_left_hud.apply_voice_status_event(event, ctx)


func _ensure_ai_player_prompt() -> void:
	if _ai_player_prompt != null:
		return
	var layer := get_node_or_null("StatusLayer")
	if layer == null:
		return
	var panel := Label.new()
	panel.name = "AiVoicePlayerPrompt"
	panel.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	panel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_theme_font_size_override("font_size", 20)
	panel.add_theme_color_override("font_color", Color("FFF4E6"))
	panel.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	panel.add_theme_constant_override("shadow_offset_x", 2)
	panel.add_theme_constant_override("shadow_offset_y", 2)
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)
	_ai_player_prompt = panel
	_layout_ai_prompt_above_character()


func _init_preview_debug_panel() -> void:
	if _debug_panel != null:
		return
	_debug_panel = PreviewDebugPanel.new()
	_debug_panel.name = "PreviewDebugPanel"
	add_child(_debug_panel)


func _init_left_hud() -> void:
	if _left_hud != null:
		return
	push_error("YouyouPreview: 请在场景里放置 LeftHud（实例 youyou_arcade_hud.tscn）。")


func get_left_hud() -> YouyouLeftHud:
	return _left_hud


func _init_right_hud() -> void:
	if _right_hud != null:
		return
	_right_hud = YouyouRightHud.new()
	_right_hud.name = "RightHud"
	add_child(_right_hud)


func get_right_hud() -> YouyouRightHud:
	return _right_hud


func _apply_hud_visual_cohesion() -> void:
	PreviewVisualTuning.apply_ui_canvas(_left_hud)
	PreviewVisualTuning.apply_ui_canvas(_right_hud)
	if _debug_panel != null:
		PreviewVisualTuning.apply_ui_canvas(_debug_panel)


func on_voice_subtitle_audio(audio_path: String) -> void:
	if _left_hud == null:
		return
	var line := VoiceSubtitleCatalog.subtitle_for_audio_path(audio_path)
	if line.is_empty():
		return
	_left_hud.set_dialogue(line)


func _sync_left_hud_business() -> void:
	if _left_hud == null:
		return
	var board_credits := 0
	if BoardLink != null and BoardLink.has_method("get_credits"):
		board_credits = int(BoardLink.get_credits())
	if _round_business != null and BoardLink != null and BoardLink.has_method("uses_machine_credits") and BoardLink.uses_machine_credits():
		_round_business.sync_machine_credits(board_credits)
	if _round_business != null:
		_left_hud.set_coin_count(_round_business.coin_balance())
	else:
		_left_hud.set_coin_count(board_credits)


func _refresh_debug_panel() -> void:
	_sync_left_hud_business()
	if _debug_panel == null:
		return
	var lines: PackedStringArray = []
	lines.append("调试")
	if _round_business != null:
		var stage := _round_business.stage_name()
		var phase := _round_business.result_phase()
		var biz := "业务  %s  币 %d" % [stage, _round_business.coin_balance()]
		if phase != "":
			biz += "  · %s" % phase
		lines.append(biz)
	elif _precoin != null:
		var here := "在" if _precoin.is_player_present() else "离"
		lines.append("业务  投币前  玩家%s场" % here)
	else:
		lines.append("业务  —")
	if _grab_flow != null and _grab_flow.wants_look():
		lines.append("抓取  %s  · 可转头" % _grab_flow.phase_name())
	elif _grab_flow != null and _grab_flow.phase_name() != "IDLE":
		lines.append("抓取  %s" % _grab_flow.phase_name())
	var player_txt := "—"
	if _precoin != null:
		player_txt = "交互区" if _precoin.is_player_present() else "已离开"
	var session_txt := "未开"
	var phase_txt := "—"
	var mic_txt := "停"
	var remain_txt := ""
	if _ai_voice_bridge != null:
		var snap: Dictionary = _ai_voice_bridge.snapshot()
		var armed := bool(snap.get("window_armed", false))
		var active := bool(snap.get("session_active", false))
		if armed and active:
			session_txt = "进行中"
		elif String(snap.get("last_close_reason", "")) != "":
			session_txt = "已关"
		phase_txt = _map_ai_phase_label(String(snap.get("perf_state", "")))
		if bool(snap.get("capture_listening", false)) and active:
			mic_txt = "听" if String(snap.get("perf_state", "")) in ["ATTRACT", "LISTENING"] else "停"
		var rem := float(snap.get("window_remaining_sec", 0.0))
		if rem > 0.05:
			remain_txt = "  %.0fs" % rem
		var lat := String(snap.get("latency_last_line", ""))
		if lat != "" and lat != "-":
			lines.append("AI  %s  %s  麦%s%s" % [session_txt, phase_txt, mic_txt, remain_txt])
			lines.append("    %s" % lat)
		else:
			lines.append("AI  %s  %s  麦%s%s  玩家%s" % [session_txt, phase_txt, mic_txt, remain_txt, player_txt])
	else:
		lines.append("AI  —  玩家%s" % player_txt)
	if _last_precoin_play_result.begins_with("blocked"):
		lines.append("待机  %s" % _last_precoin_play_result)
	if not _debug_log_lines.is_empty():
		lines.append("—")
		var log_cap := mini(_debug_log_lines.size(), 6)
		for i in log_cap:
			lines.append(_debug_log_lines[i])
	_debug_panel.set_body("\n".join(lines))


func preview_ai_on_coord_debug(_tag: String, _detail: String) -> void:
	pass


func _map_ai_phase_label(perf_state: String) -> String:
	match perf_state:
		"ATTRACT":
			return "招揽"
		"LISTENING":
			return "倾听"
		"AI_SPEAKING":
			return "AI 回答"
		"RESUME_ATTRACT":
			return "恢复招揽"
		"CANCELLED":
			return "关闭"
		_:
			return "关闭" if perf_state == "" else perf_state


func preview_ai_may_continuous_listen() -> bool:
	if not _precoin_enabled or _precoin == null:
		return false
	if _precoin.is_business():
		return false
	if _event_playing:
		return false
	if _invite_blocks_idle_schedule():
		return false
	if _grab_blocks_idle_schedule():
		return false
	if _round_business != null:
		if _round_business.current_stage() != ClawBusinessNode.Stage.STANDBY:
			return false
		if not _round_business.has_visitor():
			return false
	elif not _precoin.is_player_present():
		return false
	return true


func preview_ai_may_resume_attract() -> bool:
	return preview_ai_may_continuous_listen()


func perf_resume_precoin_attract() -> void:
	if not preview_ai_may_resume_attract():
		return
	if _precoin != null:
		_precoin.nudge_attract_after_voice_turn()


func perf_play_listen_idle() -> void:
	_preview_ai_speak_active = false
	if _idle_life != null:
		_idle_life.set_process(false)
	_sync_idle_presence()
	if _approved_perf != null:
		_approved_perf.call("stop", true)
	if _precoin_enabled and _precoin != null and _precoin.is_player_present():
		_precoin.interrupt_current_action_for_voice()
	else:
		precoin_ensure_base_idle()
	if _idle_life != null:
		_idle_life.set_process(true)
	_sync_idle_presence()


func perf_play_ai_speak() -> void:
	_preview_ai_speak_active = true
	if _approved_perf != null:
		_approved_perf.call("stop", true)
	if _idle_life != null:
		_idle_life.set_process(false)
	if _player == null:
		return
	if _event_perf != null and _event_perf.arm_body_clip(PREVIEW_AI_SPEAK_ANIM):
		var clip := _player.get_animation(PREVIEW_AI_SPEAK_ANIM)
		clip.loop_mode = Animation.LOOP_LINEAR
		_play_clip(PREVIEW_AI_SPEAK_ANIM, BLEND_BASE_TO_ATTRACT)
	elif _player.has_animation(PREVIEW_AI_SPEAK_ANIM):
		_player.get_animation(PREVIEW_AI_SPEAK_ANIM).loop_mode = Animation.LOOP_LINEAR
		_play_clip(PREVIEW_AI_SPEAK_ANIM, BLEND_BASE_TO_ATTRACT)


func perf_stop_ai_speak_pose() -> void:
	_preview_ai_speak_active = false
	if _player != null and String(_player.assigned_animation) == PREVIEW_AI_SPEAK_ANIM:
		_player.stop()


func perf_clear_presentation() -> void:
	_preview_ai_speak_active = false
	if _approved_perf != null:
		_approved_perf.call("stop", true)
	perf_stop_ai_speak_pose()
	if _idle_life != null:
		_idle_life.set_process(false)


func on_show_presence_request(action_id: String) -> void:
	_event_playing = false
	if _invite_flow != null and _invite_flow.phase_name() in ["PLAYING", "WAITING_ANSWER", "LISTENING"]:
		_invite_flow.notify_presence_released()
	if _grab_flow != null:
		_grab_flow.notify_presence_released()
		_release_grab_closeup_camera()
	if not _precoin_enabled or _precoin == null:
		return
	if action_id == "idle_base" and _round_business != null and (
		_round_business.is_success_hold() or _round_business.is_fail_hold()
	):
		precoin_ensure_base_idle()
		return
	if action_id == "attract":
		_precoin.release_to_presence(true)
	elif action_id == "idle_base":
		_precoin.release_to_presence(false)


func _resume_precoin_from_i() -> void:
	if _precoin == null:
		return
	if _precoin.is_business():
		_note("[待机] 业务接管中，忽略恢复待机")
		return
	if _precoin.is_idle_dwell() and not _precoin.is_suspended():
		_note("[待机] 自动待机已在进行")
		return
	_hello_active = false
	_oneshot_name = ""
	_start_idle(true)
	_mode = ScheduleMode.BASE_IDLE
	_precoin.resume_after_manual()


func _push_key_ctrl(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	event.echo = false
	event.ctrl_pressed = true
	get_viewport().push_input(event)


func _await_precoin_action(limit: float) -> String:
	var waited := 0.0
	while waited < limit:
		if (
			_precoin != null
			and _precoin.is_action_playing()
			and _player.assigned_animation == _precoin.current_action_id()
			and _player.is_playing()
		):
			return _precoin.current_action_id()
		await get_tree().process_frame
		waited += get_process_delta_time()
	return ""


func _await_precoin_dwell(limit: float) -> bool:
	var waited := 0.0
	while waited < limit:
		if (
			_precoin != null
			and _precoin.phase_name() == "DWELL"
			and _player.assigned_animation == IDLE_ANIM
			and _player.is_playing()
		):
			return true
		await get_tree().process_frame
		waited += get_process_delta_time()
	return false


func _rush_precoin_action() -> void:
	if _player != null:
		_player.speed_scale = 40.0


func _run_precoin_schedule_check() -> void:
	for _frame in 3:
		await get_tree().process_frame
	_start_precoin()
	if _idle_life != null:
		_idle_life.set_process(false)
	var lines: PackedStringArray = []
	var ok := true
	var general := _precoin.count_kind("general_light")
	var exclusive := _precoin.count_kind("exclusive_light")
	var attract_count := _precoin.count_kind("attract")
	lines.append("general=%d exclusive=%d attract=%d" % [general, exclusive, attract_count])
	ok = ok and general == _general_light_pool.size() and general >= 2
	ok = ok and exclusive == _light_pool.size() and exclusive >= 2
	ok = ok and attract_count == _attract_pool.size() and attract_count >= 2
	for action_id in _general_light_pool:
		var reg_g: Dictionary = Approved.get_clip_registry(action_id)
		lines.append("general %s scene=%s" % [action_id, reg_g.get("scene", "")])
	for action_id in _light_pool:
		var reg: Dictionary = Approved.get_clip_registry(action_id)
		var audio := String(Approved.get_params(action_id).get("audio_path", ""))
		lines.append("exclusive %s scene=%s audio=%s" % [action_id, reg.get("scene", ""), audio])
	for action_id in _attract_pool:
		var reg: Dictionary = Approved.get_clip_registry(action_id)
		var audio := String(Approved.get_params(action_id).get("audio_path", ""))
		lines.append("attract %s scene=%s audio=%s" % [action_id, reg.get("scene", ""), audio])
	for banned in ["youyou_claw crane01_01", "youyou_Basic_Idle06", "youyou_Hello_Idle04", "youyou_Hello_Idle09", "hello01"]:
		var absent := not _precoin.has_action(banned)
		lines.append("banned_%s=%s" % [banned.replace(" ", "_"), str(absent)])
		ok = ok and absent
	var initial_idle := _player.assigned_animation == IDLE_ANIM and _player.is_playing()
	lines.append("initial_idle=%s anim=%s" % [str(initial_idle), _player.assigned_animation])
	ok = ok and initial_idle
	await _save_check_png("C:/Users/29385/AppData/Local/Temp/youyou_precoin_idle.png")
	var first := await _await_precoin_action(5.5)
	lines.append("first=%s kind=%s" % [first, _precoin.current_kind()])
	ok = ok and (
		(first in _general_light_pool and _precoin.current_kind() == "general_light")
		or (first in _light_pool and _precoin.current_kind() == "exclusive_light")
	)
	await get_tree().create_timer(0.8).timeout
	await _save_check_png("C:/Users/29385/AppData/Local/Temp/youyou_precoin_action.png")
	_sync_idle_presence()
	var blink_state := int(_idle_life.call("get_performance_state"))
	var blink_triggered: bool = _idle_life.call("trigger_test_blink")
	_idle_life.call("process_life", 0.05, get_viewport())
	var blink_weight := float(_idle_life.call("get_debug_snapshot").get("blink_weight", 0.0))
	var blink_on: bool = _idle_life.call("is_blink_channel_enabled")
	lines.append("blink_state=%d triggered=%s weight=%.3f channel=%s" % [blink_state, str(blink_triggered), blink_weight, str(blink_on)])
	ok = ok and blink_state == 0 and blink_triggered and blink_weight > 0.1 and blink_on
	_precoin.configure_dwells(0.12, 0.2, 0.08, 0.14)
	_rush_precoin_action()
	var back1 := await _await_precoin_dwell(4.0)
	lines.append("after_first_idle=%s trace_begin=%s trace_end=%s" % [
		str(back1), str(_precoin.trace_contains("过渡开始")), str(_precoin.trace_contains("过渡结束"))
	])
	ok = ok and back1 and _precoin.trace_contains("过渡开始") and _precoin.trace_contains("过渡结束")
	var second := await _await_precoin_action(3.0)
	lines.append("second=%s different=%s" % [second, str(second != "" and second != first)])
	ok = ok and (second in _general_light_pool or second in _light_pool) and second != first
	_push_key(KEY_M)
	await get_tree().process_frame
	await get_tree().process_frame
	var m_held := _player.assigned_animation == second and _precoin.is_player_present()
	lines.append("m_no_cut=%s mode=%s" % [str(m_held), _precoin.target_mode_name()])
	ok = ok and m_held and _precoin.target_mode_name() == "ATTRACT"
	var mark_m := _precoin.trace_size()
	_rush_precoin_action()
	var idle_before_attract := await _await_precoin_dwell(4.0)
	var attract1 := await _await_precoin_action(3.0)
	var via_idle := idle_before_attract and _precoin.trace_has_from(mark_m, "过渡结束")
	lines.append("attract1=%s via_idle=%s" % [attract1, str(via_idle)])
	ok = ok and attract1 in _attract_pool and via_idle
	_push_key(KEY_M)
	await get_tree().process_frame
	await get_tree().process_frame
	var m_repeat := _player.assigned_animation == attract1 and _precoin.trace_contains("重复进入")
	lines.append("m_repeat=%s" % str(m_repeat))
	ok = ok and m_repeat
	_rush_precoin_action()
	var between_attract := await _await_precoin_dwell(4.0)
	var attract2 := await _await_precoin_action(3.0)
	lines.append("attract2=%s idle_between=%s different=%s" % [attract2, str(between_attract), str(attract2 != attract1)])
	ok = ok and between_attract and attract2 in _attract_pool and attract2 != attract1
	_push_key_ctrl(KEY_L)
	await get_tree().process_frame
	await get_tree().process_frame
	var leave_held := _player.assigned_animation == attract2 and not _precoin.is_player_present()
	lines.append("leave_no_cut=%s mode=%s" % [str(leave_held), _precoin.target_mode_name()])
	ok = ok and leave_held and _precoin.target_mode_name() == "IDLE"
	_push_key_ctrl(KEY_L)
	await get_tree().process_frame
	ok = ok and _precoin.trace_contains("重复离开")
	_rush_precoin_action()
	var idle_after_leave := await _await_precoin_dwell(4.0)
	var light_after := await _await_precoin_action(3.0)
	lines.append("resume_light=%s via_idle=%s" % [light_after, str(idle_after_leave)])
	ok = ok and idle_after_leave and (light_after in _general_light_pool or light_after in _light_pool)
	_push_key(KEY_M)
	await get_tree().process_frame
	_push_key_ctrl(KEY_L)
	await get_tree().process_frame
	_push_key(KEY_F5)
	await get_tree().process_frame
	_push_key(KEY_F6)
	await get_tree().process_frame
	_push_key(KEY_M)
	await get_tree().process_frame
	await get_tree().process_frame
	var rapid_held := _player.assigned_animation == light_after and _precoin.target_mode_name() == "ATTRACT"
	lines.append("rapid_held=%s" % str(rapid_held))
	ok = ok and rapid_held
	_rush_precoin_action()
	ok = ok and await _await_precoin_dwell(4.0)
	var attract3 := await _await_precoin_action(3.0)
	lines.append("rapid_final=%s" % attract3)
	ok = ok and attract3 in _attract_pool
	_precoin.debug_reject_current()
	var stale_consumed := _precoin.notify_animation_finished(attract3)
	lines.append("stale_consumed=%s stale_logged=%s" % [str(stale_consumed), str(_precoin.trace_contains("过期回调被忽略"))])
	ok = ok and not stale_consumed and _precoin.trace_contains("过期回调被忽略")
	_precoin.enter_business(true)
	_push_key(KEY_M)
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	var held_business := _precoin.is_business() and _precoin.target_mode_name() == "BUSINESS" and not _precoin.is_action_playing()
	lines.append("business_hold=%s ignored_m=%s" % [str(held_business), str(_precoin.trace_contains("业务接管中，忽略待机请求"))])
	ok = ok and held_business and _precoin.trace_contains("业务接管中，忽略待机请求")
	on_show_presence_request("idle_base")
	lines.append("business_return=%s" % _precoin.target_mode_name())
	ok = ok and _precoin.target_mode_name() == "IDLE" and not _precoin.is_business()
	var coin_token := 100001
	_play_preview_event("youyou_coin01", coin_token)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var coin_anim := String(_player.assigned_animation)
	var coin_ok := _precoin.is_business() and (_event_perf.is_playing() or coin_anim == "youyou_coin01")
	lines.append("coin_takeover anim=%s business=%s playing=%s" % [coin_anim, str(_precoin.is_business()), str(_event_perf.is_playing())])
	ok = ok and coin_ok and coin_anim != attract3
	var mix := _probe_precoin_mix()
	var single := _probe_precoin_single()
	lines.append("mix=%s single_hold=%s" % [str(mix), str(single)])
	ok = ok and mix and single
	_sync_idle_presence()
	ok = ok and _idle_life.call("is_blink_channel_enabled")
	lines.append("=== precoin_schedule_check_pass=%s ===" % str(ok))
	print("\n".join(lines))
	get_tree().quit(0 if ok else 1)


func _probe_precoin_mix() -> bool:
	var probe := PrecoinScheduler.new()
	probe.name = "PrecoinMixProbe"
	add_child(probe)
	probe.setup(self, [
		{"id": "g_a", "kind": "general_light", "weight": 1.0},
		{"id": "e_b", "kind": "exclusive_light", "weight": 1.0},
		{"id": "e_c", "kind": "exclusive_light", "weight": 1.0},
	])
	var previous := ""
	var saw_general := false
	var saw_exclusive := false
	var adjacent := 0
	var kinds := PackedStringArray(["general_light", "exclusive_light"])
	for _i in 40:
		var decision: Dictionary = probe.debug_decision(kinds, previous)
		var action_id := String(decision.get("id", ""))
		if action_id == "" or action_id == previous:
			adjacent += 1
			continue
		if String(decision.get("kind", "")) == "general_light":
			saw_general = true
		elif String(decision.get("kind", "")) == "exclusive_light":
			saw_exclusive = true
		previous = action_id
	probe.queue_free()
	return saw_general and saw_exclusive and adjacent == 0


func _probe_precoin_single() -> bool:
	var probe := PrecoinScheduler.new()
	probe.name = "PrecoinSingleProbe"
	add_child(probe)
	probe.setup(self, [{"id": "only_attract", "kind": "attract", "weight": 1.0}])
	var first: Dictionary = probe.debug_decision(PackedStringArray(["attract"]), "")
	var second: Dictionary = probe.debug_decision(PackedStringArray(["attract"]), String(first.get("id", "")))
	probe.queue_free()
	return String(first.get("id", "")) == "only_attract" and String(second.get("hold", "")) == "single_or_empty"


func _note(message: String) -> void:
	_log_lines.append(message)
	if _log_lines.size() > 32:
		_log_lines.remove_at(0)
	print(message)
	if PreviewDebugPanel.log_worthy(message):
		_debug_log_lines.append(message)
		if _debug_log_lines.size() > 5:
			_debug_log_lines.remove_at(0)
		_refresh_debug_panel()


func _fail(message: String) -> void:
	push_error(message)
	_note("错误：" + message)


func _init_minigame_invite_flow() -> void:
	if _invite_flow != null or _event_perf == null or _show_adapter == null:
		return
	_invite_flow = MinigameInviteFlow.new()
	_invite_flow.name = "MinigameInviteFlow"
	add_child(_invite_flow)
	_invite_flow.setup(self, _event_perf, _show_adapter, _player)


func begin_minigame_invite(token: int) -> void:
	_preview_ai_preempt("minigame_invite")
	if _invite_flow != null:
		_invite_flow.begin_invite(token)


func minigame_invite_listen_ready() -> void:
	_note("[小游戏引导] 麦克风已开启，等待流式识别意愿。")
	_show_invite_listen_banner()


func minigame_invite_listen_ended() -> void:
	_clear_invite_listen_banner()


func invite_business_snapshot() -> Dictionary:
	if _round_business == null:
		return {}
	return {
		"stage": _round_business.stage_name(),
		"result_phase": _round_business.result_phase(),
		"invite_session": _round_business.invite_listen_session(),
	}


func minigame_invite_on_intent(intent: String, session: int = -1, reason: String = "") -> void:
	if _round_business == null:
		return
	if session >= 0 and _invite_flow != null and session != _invite_flow.invite_session_id():
		grab_log("[小游戏引导] 意愿=%s 已忽略（session=%d 过期）。" % [intent, session])
		return
	var result: Dictionary = _round_business.submit_invite_intent(intent)
	_log_invite_outcome(intent, reason, result)
	_after_invite_business(intent)


func minigame_invite_on_error(reason: String, session: int = -1) -> void:
	if _round_business == null:
		return
	if session >= 0 and _invite_flow != null and session != _invite_flow.invite_session_id():
		grab_log("[小游戏引导] 识别异常已忽略（session 过期）。")
		return
	var result: Dictionary = _round_business.finalize_invite_listen_error(
		"语音识别异常：%s" % reason
	)
	_log_invite_outcome("ERROR", reason, result)
	_after_invite_business("ERROR")


func minigame_invite_cancelled(clear_visitor: bool = false) -> void:
	if _round_business == null:
		return
	_round_business.cancel_invite_listen(clear_visitor)
	_note("[小游戏引导] 已取消等待（不算拒绝）。")
	_sync_idle_presence()


func _log_invite_outcome(label: String, reason: String, result: Dictionary) -> void:
	var biz := invite_business_snapshot()
	grab_log(
		"[小游戏引导] 业务提交 label=%s reason=%s ok=%s note=%s biz=%s/%s session=%s"
		% [
			label,
			reason,
			str(result.get("ok", false)),
			String(result.get("note", "")),
			String(biz.get("stage", "")),
			String(biz.get("result_phase", "")),
			str(biz.get("invite_session", "")),
		]
	)


func _after_invite_business(outcome: String) -> void:
	if _round_business == null:
		return
	if outcome == "PLAY":
		_note("[小游戏引导] 状态=invite_play_accepted，即将进入抽取转盘（非直接进具体游戏）。")
		_sync_idle_presence()
		if _auto_launch_minigame_on_play:
			call_deferred("_request_draw_scene_after_invite_play", "voice_play")
		return
	if outcome == "ERROR":
		_sync_idle_presence()
		return
	if outcome == "DECLINE":
		if _invite_flow != null and _invite_flow.has_method("halt_for_other_show"):
			_invite_flow.halt_for_other_show()
		_sync_idle_presence()


func set_auto_launch_minigame_on_play(enabled: bool) -> void:
	_auto_launch_minigame_on_play = enabled


func _request_draw_scene_after_invite_play(reason: String) -> void:
	if _round_business == null or not _round_business.is_invite_play_accepted():
		return
	if _minigame_launch_pending:
		grab_log("[小游戏抽取] 启动请求已排队，忽略重复 reason=%s" % reason)
		return
	_minigame_launch_pending = true
	grab_log("[小游戏抽取] 启动抽取场景 reason=%s session=%s" % [
		reason, str(_invite_flow.invite_session_id() if _invite_flow != null else -1),
	])
	var result: Dictionary = _round_business.begin_minigame_after_invite_play()
	grab_log(
		"[小游戏抽取] 业务 ok=%s note=%s stage=%s"
		% [str(result.get("ok", false)), String(result.get("note", "")), _round_business.stage_name()]
	)
	if not result.get("ok", false):
		_minigame_launch_pending = false
		return
	if _invite_flow != null:
		_invite_flow.notify_minigame_started()
	if _minigame_host != null and _minigame_host.has_method("covers_screen") and _minigame_host.covers_screen():
		var draw_only: bool = _minigame_host.has_method("is_draw_flow_active") and _minigame_host.is_draw_flow_active()
		grab_log("[小游戏抽取] Host 已打开 draw_only=%s phase=%s" % [
			str(draw_only),
			String(_minigame_host.draw_phase_name()) if _minigame_host.has_method("draw_phase_name") else "?",
		])
	else:
		grab_log("[小游戏抽取] 警告：Host 未显示。")
	_on_minigame_session_started()
	_minigame_launch_pending = false


func _on_minigame_session_started() -> void:
	_pause_show_for_minigame(true)
	if _board_bridge != null:
		_board_bridge.on_minigame_overlay_started()
	_sync_idle_presence()
	_sync_minigame_overlay_chrome()


func _on_minigame_port_opened(_token: int) -> void:
	_sync_minigame_overlay_chrome()


func _on_lobby_music_suspended(suspended: bool) -> void:
	_set_claw_bgm_suspended(suspended)


func _on_minigame_play_scene(active: bool) -> void:
	_sync_minigame_overlay_chrome()
	if active:
		_set_claw_bgm_suspended(true)


func _set_claw_bgm_suspended(suspended: bool) -> void:
	if _claw_audio == null:
		return
	if suspended and _claw_audio.has_method("pause_bgm"):
		_claw_audio.pause_bgm()
	elif not suspended and _claw_audio.has_method("resume_bgm"):
		_claw_audio.resume_bgm()


func _on_minigame_session_ended(another_grab: bool, token: int) -> void:
	grab_log("[小游戏] 结束 another_grab=%s token=%d → %s" % [
		str(another_grab), token, _round_business.stage_name() if _round_business != null else "?",
	])
	if _minigame_host != null and _minigame_host.has_method("close_round"):
		_minigame_host.close_round()
	_pause_show_for_minigame(false)
	if _invite_flow != null:
		_invite_flow.notify_minigame_started()
	if _board_bridge != null and not another_grab:
		_board_bridge.on_minigame_settled()
	_sync_idle_presence()
	_sync_minigame_overlay_chrome()


func _minigame_covers_ui() -> bool:
	return _minigame_host != null and _minigame_host.has_method("covers_screen") and _minigame_host.covers_screen()


func _sync_minigame_overlay_chrome() -> void:
	var hide := _minigame_covers_ui()
	var layer := get_node_or_null("StatusLayer") as CanvasLayer
	if layer != null:
		layer.visible = not hide
	if _left_hud != null:
		_left_hud.visible = not hide
	if _right_hud != null:
		_right_hud.visible = not hide
	if _debug_panel != null and _debug_panel.has_method("set_gameplay_hidden"):
		_debug_panel.call("set_gameplay_hidden", hide)
	if _ai_player_prompt != null:
		_ai_player_prompt.visible = not hide
	if hide:
		clear_grab_result_banner()
		_clear_invite_listen_banner()


func _pause_show_for_minigame(pause: bool) -> void:
	if _event_perf != null and _event_perf.has_method("set_minigame_overlay_active"):
		_event_perf.set_minigame_overlay_active(pause)
	elif pause and _event_playing:
		pass
	if pause:
		_schedule_enabled = false
		if _precoin != null:
			_precoin.set_process(false)
	else:
		if _precoin_enabled and _precoin != null:
			_precoin.set_process(true)


func _init_grab_flow() -> void:
	if _grab_flow != null or _event_perf == null or _show_adapter == null:
		return
	_grab_flow = GrabFlow.new()
	_grab_flow.name = "GrabShowFlow"
	add_child(_grab_flow)
	_grab_flow.setup(
		self,
		_event_perf,
		_show_adapter,
		_face,
		_player,
		_idle_life,
		get_node_or_null("EyeGazeController"),
		get_node_or_null("HeadFollowController"),
	)


func _init_claw_audio() -> void:
	if _claw_audio != null:
		return
	_claw_audio = ClawSceneAudio.new()
	_claw_audio.name = "ClawSceneAudio"
	add_child(_claw_audio)
	# 父节点还在 _ready 里时，子节点的 _ready 可能还没跑，不能立刻 start。
	if _claw_audio.is_node_ready() and _claw_audio.has_method("start_bgm"):
		_claw_audio.start_bgm()


func _play_claw_move(key: InputEventKey) -> void:
	if _claw_audio == null or not _claw_audio.has_method("play_move"):
		return
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	match code:
		KEY_D:
			_claw_audio.play_move("left")
		KEY_A:
			_claw_audio.play_move("right")
		KEY_W:
			_claw_audio.play_move("up")
		KEY_S:
			_claw_audio.play_move("down")


func _play_grab_down() -> void:
	if _claw_audio != null and _claw_audio.has_method("play_grab_down"):
		_claw_audio.play_grab_down()


func _play_coin() -> void:
	if _claw_audio != null and _claw_audio.has_method("play_coin"):
		_claw_audio.play_coin()


func _play_grab_up() -> void:
	if _claw_audio != null and _claw_audio.has_method("play_grab_up"):
		_claw_audio.play_grab_up()


func begin_success_continue_guide(token: int) -> bool:
	const GUIDE_AUDIO := "res://配音/成功引导小游戏1-手感正好.mp3"
	const GUIDE_ACTION := "youyou_Speak_Idle05"
	if not ResExists.path(GUIDE_AUDIO):
		push_error("成功续玩引导配音不存在：" + GUIDE_AUDIO)
		return false
	if _event_perf == null:
		return false
	grab_log("[续玩] 播放 %s + %s" % [GUIDE_ACTION, GUIDE_AUDIO])
	return _event_perf.play_event(GUIDE_ACTION, token, true, true, 0.25, GUIDE_AUDIO)


func begin_fail_continue_guide(token: int) -> bool:
	const GUIDE_AUDIO := "res://配音/抓取失败引导抓娃娃1.mp3"
	const GUIDE_ACTION := "youyou_Speak_Idle05"
	if not ResExists.path(GUIDE_AUDIO):
		push_error("失败续玩引导配音不存在：" + GUIDE_AUDIO)
		return false
	if _event_perf == null:
		push_error("失败续玩引导：事件表现未初始化。")
		return false
	if _invite_flow != null and _invite_flow.has_method("halt_for_other_show"):
		_invite_flow.halt_for_other_show()
	_event_perf.stop_event(true)
	grab_log("[失败续玩] 播放 %s + %s" % [GUIDE_ACTION, GUIDE_AUDIO])
	return _event_perf.play_event(GUIDE_ACTION, token, true, true, 0.25, GUIDE_AUDIO)


func begin_paid_observe(token: int) -> bool:
	if _grab_flow == null:
		return false
	var started := _grab_flow.begin_paid_observe(token)
	if started:
		_begin_grab_closeup_camera()
	return started


func begin_coin_welcome(token: int, speech_id: String = "") -> void:
	if _grab_flow != null:
		_grab_flow.begin_coin_welcome(token, speech_id)


func on_coin_welcome_finished() -> void:
	if _show_adapter != null and _show_adapter.has_method("notify_welcome_finished"):
		_show_adapter.notify_welcome_finished()
	_refresh_debug_panel()


func begin_opening_sequence(token: int) -> void:
	begin_coin_welcome(token)


func begin_operate_hold() -> void:
	if _grab_flow != null:
		_grab_flow.begin_operate()


func begin_deeper_crouch() -> void:
	if _grab_flow != null:
		_grab_flow.begin_deeper()


func enter_claw_watch_keeping_speech() -> void:
	if _minigame_consumes_joystick():
		return
	if _round_business != null and _round_business.current_stage() == ClawBusinessNode.Stage.GRABBING:
		return
	if not _claw_watch_pose:
		_begin_grab_closeup_camera()
		_claw_watch_pose = true
	if _grab_flow != null:
		_grab_flow.begin_watch_keeping_speech()
	if _precoin != null and not _precoin.is_business():
		_precoin.enter_business(true)
	if _round_business != null and _round_business.has_method("note_claw_operated"):
		_round_business.note_claw_operated()


func sync_stick_gaze_now() -> void:
	_sync_gaze_head_from_stick_bits(_serial_key_bits, true)


func latch_machine_grab_result(success: bool) -> void:
	if _grab_flow != null and _grab_flow.accepts_machine_result():
		_grab_flow.notify_machine_result(success)
		return
	submit_simulated_grab_result(success)


func real_machine_sensors() -> bool:
	return BoardLink != null and BoardLink.has_method("uses_machine_credits") and BoardLink.uses_machine_credits()


func arm_machine_grab() -> void:
	if _grab_flow != null:
		_grab_flow.arm_chained_machine_grab()


func _reset_youyou_for_retest() -> void:
	if _event_perf != null and _event_perf.has_method("stop_event"):
		_event_perf.stop_event(true)
	if _grab_flow != null and _grab_flow.has_method("reset_to_idle"):
		_grab_flow.reset_to_idle()
	if _invite_flow != null and _invite_flow.has_method("halt_for_other_show"):
		_invite_flow.halt_for_other_show()
	_release_grab_closeup_camera()
	_event_playing = false
	_hello_active = false
	_oneshot_name = ""
	if _precoin != null:
		_precoin.release_to_presence(false)
	if _round_business != null and _round_business.has_method("reset_for_retest"):
		_round_business.reset_for_retest()
	_start_idle(true)
	_note("[测试] Ctrl+Q：柚柚已回到初始待机。余币仍按控制板。")


func prepare_coin_body() -> void:
	_enter_manual()
	_event_playing = true


func grab_mark_event(active: bool) -> void:
	_event_playing = active


func grab_log(message: String) -> void:
	_note("[抓取] " + message)


func _observe_pivot() -> Node:
	return get_node_or_null("ObservePivot")


func _begin_grab_closeup_camera() -> void:
	if not GRAB_CLOSEUP_CAMERA_ENABLED:
		return
	var pivot := _observe_pivot()
	if pivot != null and pivot.has_method("begin_grab_round_closeup"):
		pivot.call("begin_grab_round_closeup")
	_tween_grab_closeup_model_scale(GRAB_CLOSEUP_MODEL_SCALE, GRAB_CLOSEUP_MODEL_IN_SEC)


func _release_grab_closeup_camera() -> void:
	_claw_watch_pose = false
	if not GRAB_CLOSEUP_CAMERA_ENABLED:
		return
	var pivot := _observe_pivot()
	if pivot != null and pivot.has_method("release_grab_round_closeup"):
		pivot.call("release_grab_round_closeup")
	_tween_grab_closeup_model_scale(1.0, GRAB_CLOSEUP_MODEL_OUT_SEC)


func _tween_grab_closeup_model_scale(uniform: float, duration: float) -> void:
	if _model == null:
		return
	if _grab_closeup_model_tween != null and _grab_closeup_model_tween.is_valid():
		_grab_closeup_model_tween.kill()
	var target := Vector3.ONE * uniform
	_grab_closeup_model_tween = create_tween()
	_grab_closeup_model_tween.set_ease(Tween.EASE_IN_OUT)
	_grab_closeup_model_tween.set_trans(Tween.TRANS_SINE)
	_grab_closeup_model_tween.tween_property(_model, "scale", target, duration)


func precoin_begin_handoff() -> String:
	_preview_ai_preempt("coin_handoff")
	if _precoin == null:
		return ""
	return _precoin.begin_handoff()


func precoin_abort_for_coin(_action_id: String) -> void:
	_preview_ai_preempt("coin_abort")
	_hello_active = false
	_oneshot_name = ""
	_pending_attract_request = false
	_active_finish_anim = ""
	if _approved_perf != null:
		_approved_perf.call("stop", true)
	_auto_perf_gen = _performance_pose.bump_auto_session()
	if _player != null and _player.is_playing():
		_player.speed_scale = 1.0


func precoin_yield_finished(anim_name: String) -> void:
	if _approved_perf != null:
		_approved_perf.call("on_action_animation_finished", anim_name, _auto_perf_gen)
	if _grab_flow != null:
		_grab_flow.notify_precoin_yielded()


func submit_simulated_grab_result(success: bool) -> void:
	_release_grab_closeup_camera()
	_show_grab_result_banner(success)
	if _claw_audio != null and _claw_audio.has_method("play_outcome"):
		_claw_audio.play_outcome(success)
	if _round_business == null:
		_note("[抓取] 没有业务控制器，结果无法交回")
		return
	var event_id := ClawBusinessNode.GRAB_SUCCEEDED if success else ClawBusinessNode.GRAB_FAILED
	var result: Dictionary = _round_business.submit(event_id)
	_note("[抓取] " + String(result.get("note", "")))


func hold_grab_surprise() -> void:
	if _face == null:
		return
	if _face.get_active_emotion() == "surprise":
		return
	_face.set_emotion("surprise", 0.2)


func hold_body_for_grab() -> void:
	_preview_ai_preempt("grab")
	_hello_active = false
	_oneshot_name = ""
	_pending_attract_request = false
	_schedule_enabled = false
	if _wait_timer != null:
		_wait_timer.stop()
	if _approved_perf != null:
		_approved_perf.call("stop", true)
	if _precoin_enabled and _precoin != null and not _precoin.is_business():
		_precoin.enter_business(true)


func _invite_blocks_idle_schedule() -> bool:
	if _round_business != null and _round_business.current_stage() == ClawBusinessNode.Stage.MINIGAME:
		return true
	if _minigame_host != null and _minigame_host.has_method("covers_screen") and _minigame_host.covers_screen():
		return true
	return _invite_flow != null and _invite_flow.holds_schedule()


func _grab_blocks_idle_schedule() -> bool:
	return _grab_flow != null and _grab_flow.holds_exclusive_body()


func _is_idle_schedule_key(key: InputEventKey) -> bool:
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	return IDLE_VARIANTS.has(code) or BATCH_ONESHOTS.has(code) or code == KEY_H or code == KEY_I


func _ensure_result_banner() -> void:
	if _result_banner != null:
		return
	var layer := get_node_or_null("StatusLayer")
	if layer == null:
		return
	var banner := Label.new()
	banner.name = "GrabResultBanner"
	banner.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner.add_theme_font_size_override("font_size", 32)
	banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	banner.add_theme_constant_override("shadow_offset_x", 2)
	banner.add_theme_constant_override("shadow_offset_y", 2)
	banner.visible = false
	layer.add_child(banner)
	_result_banner = banner
	_layout_bottom_left_label(_result_banner, UI_GRAB_BANNER_HEIGHT, UI_GRAB_BANNER_BOTTOM)
	_result_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


func _show_grab_result_banner(success: bool) -> void:
	if _minigame_covers_ui():
		return
	_ensure_result_banner()
	if _result_banner == null:
		return
	if success:
		_result_banner.text = "抓取成功！你太厉害啦！"
		_result_banner.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35, 1))
	else:
		_result_banner.text = "差一点点！再试一次！"
		_result_banner.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45, 1))
	_result_banner.visible = true


func clear_grab_result_banner() -> void:
	if _result_banner != null:
		_result_banner.visible = false
		_result_banner.text = ""


func _ensure_invite_listen_banner() -> void:
	if _invite_listen_banner != null:
		return
	var layer := get_node_or_null("StatusLayer")
	if layer == null:
		return
	var banner := Label.new()
	banner.name = "InviteListenBanner"
	banner.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner.add_theme_font_size_override("font_size", 26)
	banner.add_theme_color_override("font_color", Color(0.55, 0.95, 1.0, 1))
	banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.92))
	banner.add_theme_constant_override("shadow_offset_x", 2)
	banner.add_theme_constant_override("shadow_offset_y", 2)
	banner.visible = false
	layer.add_child(banner)
	_invite_listen_banner = banner
	_layout_bottom_left_label(_invite_listen_banner, UI_INVITE_BANNER_HEIGHT, UI_INVITE_BANNER_BOTTOM)
	_invite_listen_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


func _show_invite_listen_banner() -> void:
	_ensure_invite_listen_banner()
	if _invite_listen_banner == null:
		return
	_invite_listen_banner.text = "麦克风已打开\n请直接说：想玩 / 不玩"
	_invite_listen_banner.visible = true


func _clear_invite_listen_banner() -> void:
	if _invite_listen_banner != null:
		_invite_listen_banner.visible = false
		_invite_listen_banner.text = ""


func grab_result_banner_text() -> String:
	if _result_banner == null or not _result_banner.visible:
		return ""
	return _result_banner.text


func _ensure_standalone_business() -> void:
	if _show_claimed or _round_business != null:
		return
	var mini := MinigamePortNode.new()
	mini.name = "ClawMinigamePort"
	add_child(mini)
	_minigame_port = mini
	var host := MinigameHostNode.new()
	host.name = "ClawMinigameHost"
	add_child(host)
	host.setup(mini)
	if not mini.opened.is_connected(host.open_round):
		mini.opened.connect(host.open_round)
	if host.has_signal("play_scene_active") and not host.play_scene_active.is_connected(_on_minigame_play_scene):
		host.play_scene_active.connect(_on_minigame_play_scene)
	if host.has_signal("lobby_music_suspended") and not host.lobby_music_suspended.is_connected(_on_lobby_music_suspended):
		host.lobby_music_suspended.connect(_on_lobby_music_suspended)
	_minigame_host = host
	var biz := ClawBusinessNode.new()
	biz.name = "ClawBusiness"
	add_child(biz)
	biz.bind(_show_adapter, mini)
	if not mini.finished.is_connected(_on_claw_minigame_port_finished):
		mini.finished.connect(_on_claw_minigame_port_finished)
	if not mini.opened.is_connected(_on_minigame_port_opened):
		mini.opened.connect(_on_minigame_port_opened)
	if not biz.situation_changed.is_connected(_refresh_debug_panel):
		biz.situation_changed.connect(_refresh_debug_panel)
	_round_business = biz
	if _board_bridge == null:
		_board_bridge = ClawBoardBridge.new()
		_board_bridge.name = "ClawBoardBridge"
		add_child(_board_bridge)
		_board_bridge.setup(biz, self)
	if not biz.situation_changed.is_connected(_on_claw_stick_business_changed):
		biz.situation_changed.connect(_on_claw_stick_business_changed)
	_hook_board_stick_for_gaze()
	BoardLink.legacy_keyboard_mock = CLAW_JOYSTICK_X_INPUT
	_refresh_debug_panel()
	_print_claw_preview_key_help()


func _on_claw_minigame_port_finished(token: int, another_grab: bool) -> void:
	_on_minigame_session_ended(another_grab, token)


func _handle_round_keys(key: InputEventKey) -> bool:
	if CLAW_JOYSTICK_X_INPUT and not _vad_ab_dev_keyboard():
		return _consume_legacy_round_key(key)
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	var ctrl := _is_ctrl_combo(key)
	if _minigame_consumes_joystick():
		return false
	if ctrl and code == KEY_T:
		if _round_business == null:
			return true
		var coin_result: Dictionary = _submit_round(ClawBusinessNode.COIN_ACCEPTED)
		if bool(coin_result.get("ok", false)):
			_play_coin()
		return true
	if ctrl and code == KEY_G:
		if _round_business == null:
			return true
		var grabbed: Dictionary = _submit_round(ClawBusinessNode.GRAB_PRESSED)
		if bool(grabbed.get("ok", false)):
			_play_grab_down()
		else:
			_note("[业务] 还不能下抓。先 Ctrl+T 投够币，等进入操作后再按 Ctrl+G。")
		return true
	if ctrl and code == KEY_B:
		if _grab_flow != null and _grab_flow.request_judgment():
			_play_grab_up()
		else:
			_note("[抓取] 现在还不能上抓。先 Ctrl+G 下抓，等爪子停住后再按 Ctrl+B。")
		return true
	if ctrl and code == KEY_Z:
		if _round_business == null:
			return true
		if _round_business.is_replay_hold() or _round_business.can_request_followup_from_standby():
			_submit_round(ClawBusinessNode.SUCCESS_REPLAY)
		else:
			var hint := _round_business.explain()
			if hint.is_empty():
				hint = "有余币时随时 Ctrl+Z 开续局；余额为 0 时 10 秒内投币仍算续局，超时则下次为首局。"
			_note("[业务] " + hint)
		return true
	if ctrl and code == KEY_Q:
		_reset_youyou_for_retest()
		return true
	if code == KEY_M and not ctrl:
		_simulate_player_enter_interaction()
		return true
	if not ctrl and (code == KEY_ENTER or code == KEY_KP_ENTER):
		_simulate_player_enter_interaction()
		_note("[感应] 回车：有人走近。")
		return true
	if not ctrl and code == KEY_SPACE:
		_simulate_player_leave_interaction()
		_note("[感应] 空格：人离开了。")
		return true
	if not ctrl and (code == KEY_1 or code == KEY_KP_1):
		return _keyboard_minigame_choice(true)
	if not ctrl and (code == KEY_2 or code == KEY_KP_2):
		return _keyboard_minigame_choice(false)
	return false


func _is_motion_debug_key(key: InputEventKey) -> bool:
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	if IDLE_VARIANTS.has(code) or BATCH_ONESHOTS.has(code):
		return true
	if EMOTE_KEYS.has(code) or EXTENDED_EMOTE_KEYS.has(code) or VISEME_KEYS.has(code):
		return true
	if PREVIEW_EVENT_KEYS.has(code):
		return true
	return code == KEY_U or code == KEY_Y


func _print_claw_preview_key_help() -> void:
	if CLAW_JOYSTICK_X_INPUT:
		print(
			"【抓娃娃·串口模拟】WASD 摇杆 · X 抓取键；投币/成败由 BoardLink 帧模拟（legacy F7/F9/1/2）。"
		)
		return
	print(
		(
			"【抓娃娃】回车有人走近 · 空格人离开 · 柚柚询问小游戏时 1 进入、2 不进入 · Ctrl+Q 重置柚柚到初始待机 · M 进入语音交互（连续 %.0f 秒不说话则离开并招揽）· Ctrl+T 投币 · WASD 摇杆 · "
			+ "Ctrl+G 下抓 · Ctrl+B 上抓（随后随机成功或失败）· Ctrl+Z 有余币再开一局。"
		)
		% VOICE_SILENCE_LEAVE_SEC
	)


func _consume_legacy_round_key(key: InputEventKey) -> bool:
	if not key.pressed or key.echo:
		return false
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	if _is_keycode(key, KEY_F5) or _is_keycode(key, KEY_F6) or _is_keycode(key, KEY_F7):
		return true
	if code == KEY_M:
		return true
	return false


func _minigame_consumes_joystick() -> bool:
	if _minigame_host == null:
		return false
	if _minigame_host.has_method("covers_screen") and _minigame_host.covers_screen():
		return true
	return false


func _is_grab_action_key(key: InputEventKey) -> bool:
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	return code == KEY_X


func _hook_board_stick_for_gaze() -> void:
	if _board_stick_hooked:
		return
	if not BoardLink.board_key.is_connected(_on_board_stick_key):
		BoardLink.board_key.connect(_on_board_stick_key)
	_board_stick_hooked = true


func _on_claw_stick_business_changed() -> void:
	if _round_business == null:
		return
	if _round_business.current_stage() == ClawBusinessNode.Stage.OPERATE:
		_stick_operating_sent = false


func _claw_stick_control_active() -> bool:
	if _minigame_consumes_joystick():
		return false
	if _round_business != null:
		var st := _round_business.current_stage()
		if (
			st == ClawBusinessNode.Stage.WAIT_START
			or st == ClawBusinessNode.Stage.OPERATE
			or st == ClawBusinessNode.Stage.GRABBING
		):
			return true
	if _grab_flow != null:
		if _grab_flow.wants_look() or _grab_flow.blocks_wasd_variants():
			return true
	return false


func _claw_operate_gaze_and_sfx_enabled() -> bool:
	if _grab_flow != null and _grab_flow.blocks_wasd_variants():
		return _grab_flow.is_operate_look_enabled()
	return true


func _wasd_to_board_bit(keycode: Key) -> int:
	# 与 BoardLink / IO 板 SERIAL_SendKey 一致（上下已对调以贴合手感）
	match keycode:
		KEY_W:
			return BoardLink.KEY_UP
		KEY_S:
			return BoardLink.KEY_DOWN
		KEY_A:
			return BoardLink.KEY_LEFT
		KEY_D:
			return BoardLink.KEY_RIGHT
		_:
			return 0


func _board_bits_to_gaze_flags(bits: int) -> Array:
	return [
		(bits & BoardLink.KEY_LEFT) != 0,
		(bits & BoardLink.KEY_RIGHT) != 0,
		(bits & BoardLink.KEY_UP) != 0,
		(bits & BoardLink.KEY_DOWN) != 0,
	]


func _sync_gaze_head_from_stick_bits(bits: int, from_serial: bool = false) -> void:
	if not _claw_stick_control_active():
		return
	if _idle_life != null:
		_idle_life.set_process(true)
		_idle_life.call("set_manual_input_enabled", true)
		_idle_life.call("set_gaze_channel", true)
		_idle_life.call("set_head_channel", true)
	# 键盘 WASD：EyeGazeController 自己读键；真机串口键位用 debug 对齐方向
	if not from_serial:
		return
	var gaze := get_node_or_null("EyeGazeController")
	if gaze == null:
		return
	var flags: Array = _board_bits_to_gaze_flags(bits)
	var any_stick: bool = flags[0] or flags[1] or flags[2] or flags[3]
	gaze.call(
		"debug_set_keys",
		flags[0],
		flags[1],
		flags[2],
		flags[3],
		any_stick,
	)


func _on_board_stick_key(bits: int) -> void:
	var prev := _serial_key_bits
	_serial_key_bits = bits
	var moving := bits & (
		BoardLink.KEY_LEFT | BoardLink.KEY_RIGHT | BoardLink.KEY_UP | BoardLink.KEY_DOWN
	)
	if moving != 0 and _claw_operate_gaze_and_sfx_enabled():
		enter_claw_watch_keeping_speech()
	if _claw_operate_gaze_and_sfx_enabled():
		_sync_gaze_head_from_stick_bits(bits, true)
	if bits != 0:
		_try_player_operating_from_stick()
	var grab_pressed := (bits & BoardLink.KEY_ENTER) != 0 and (prev & BoardLink.KEY_ENTER) == 0
	if grab_pressed and _board_bridge != null:
		_board_bridge.on_action_button_pressed()


func _try_player_operating_from_stick() -> void:
	if _stick_operating_sent or _round_business == null:
		return
	if _round_business.current_stage() != ClawBusinessNode.Stage.OPERATE:
		return
	var result: Dictionary = _round_business.submit(ClawBusinessNode.PLAYER_OPERATING)
	if bool(result.get("ok", false)):
		_stick_operating_sent = true


func _inject_claw_stick_bits(bits: int) -> void:
	if CLAW_WASD_BOARD_SIM or CLAW_JOYSTICK_X_INPUT:
		BoardLink.inject_key(bits)


func _handle_claw_stick_input(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false
	var key := event as InputEventKey
	if key.echo:
		return false
	if _minigame_consumes_joystick():
		return false
	if CLAW_JOYSTICK_X_INPUT and _is_grab_action_key(key):
		return _handle_claw_grab_key(key)
	if not _is_wasd_key(key):
		return false
	if not CLAW_WASD_BOARD_SIM and not CLAW_JOYSTICK_X_INPUT:
		return false
	if not _claw_stick_control_active():
		return false
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	var bit := _wasd_to_board_bit(code)
	if bit == 0:
		return false
	if key.pressed:
		_sim_joystick_bits |= bit
	else:
		_sim_joystick_bits &= ~bit
	var bits := _sim_joystick_bits
	if _sim_grab_held:
		bits |= BoardLink.KEY_ENTER
	var stick_mask := (
		BoardLink.KEY_LEFT | BoardLink.KEY_RIGHT | BoardLink.KEY_UP | BoardLink.KEY_DOWN
	)
	_inject_claw_stick_bits(bits)
	if _claw_operate_gaze_and_sfx_enabled():
		if key.pressed and (bits & stick_mask) != 0:
			enter_claw_watch_keeping_speech()
		_sync_gaze_head_from_stick_bits(bits, false)
	if bits != 0:
		_try_player_operating_from_stick()
	if key.pressed and _claw_stick_control_active():
		_play_claw_move(key)
	return true


func _handle_claw_grab_key(key: InputEventKey) -> bool:
	if not key.pressed:
		_sim_grab_held = false
		_sim_x_edge_armed = true
		_inject_claw_stick_bits(_sim_joystick_bits)
		return true
	if not _sim_x_edge_armed:
		return true
	_sim_x_edge_armed = false
	_sim_grab_held = true
	_inject_claw_stick_bits(_sim_joystick_bits | BoardLink.KEY_ENTER)
	if _board_bridge != null:
		_board_bridge.on_action_button_pressed()
	return true


func _submit_round(event_id: String, extra: Dictionary = {}) -> Dictionary:
	if _round_business == null:
		return {}
	if event_id == ClawBusinessNode.COIN_ACCEPTED:
		_preview_ai_preempt("coin")
	if event_id == ClawBusinessNode.PLAYER_LEFT:
		_preview_ai_preempt("player_left")
	var result: Dictionary = _round_business.submit(event_id, extra)
	_note("[业务] " + String(result.get("note", "")))
	_refresh_debug_panel()
	return result


func coin_balance_text() -> String:
	var balance := 0
	if _round_business != null:
		balance = _round_business.coin_balance()
	return "币：%d" % balance


func _should_block_wasd() -> bool:
	if _event_playing:
		return true
	return _grab_flow != null and _grab_flow.blocks_wasd_variants()


func _is_wasd_key(key: InputEventKey) -> bool:
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	return code == KEY_W or code == KEY_A or code == KEY_S or code == KEY_D


func _hips_height() -> float:
	if _skeleton == null:
		return 0.0
	var idx := _skeleton.find_bone("mixamorig_Hips")
	if idx < 0:
		return 0.0
	return _skeleton.get_bone_global_pose(idx).origin.y


func _active_show_event() -> String:
	if _event_perf == null:
		return ""
	return _event_perf.get_active_action_id()


func _confirm_result_playback(action_id: String, success: bool) -> Dictionary:
	var saw_idle := false
	var started := false
	var advanced := false
	var voice := false
	var pos := -1.0
	var waited := 0.0
	while waited < 6.0:
		var current := String(_player.current_animation)
		var assigned := String(_player.assigned_animation)
		if current == IDLE_ANIM or assigned == IDLE_ANIM or current.begins_with("youyou_Hello") or assigned.begins_with("youyou_Hello") or current.begins_with("youyou_Basic_Idle") or assigned.begins_with("youyou_Basic_Idle"):
			saw_idle = true
		if current == action_id and _player.is_playing():
			started = true
			var now := _player.current_animation_position
			if pos < 0.0:
				pos = now
			elif now > pos + 0.05:
				advanced = true
		var timeline: Node = _event_perf.get_timeline() if _event_perf != null else null
		if timeline != null and bool(timeline.call("is_audio_playing")):
			voice = true
		if started and advanced and voice and not saw_idle:
			break
		await get_tree().process_frame
		waited += get_process_delta_time()
	var banner := grab_result_banner_text()
	var want_banner := "抓取成功！你太厉害啦！" if success else "差一点点！再试一次！"
	var event_id := _active_show_event()
	var playing_now := String(_player.current_animation) == action_id and _player.is_playing()
	var ok := (
		started
		and advanced
		and voice
		and playing_now
		and not saw_idle
		and event_id == action_id
		and banner == want_banner
		and _grab_flow.result_success() == success
		and _round_business.stage_name() == "结果"
	)
	return {
		"ok": ok,
		"event_id": event_id,
		"current": String(_player.current_animation),
		"playing": _player.is_playing(),
		"advanced": advanced,
		"voice": voice,
		"idle": saw_idle,
		"banner": banner,
		"pos": pos,
	}


func _run_success_continue_check() -> void:
	var lines: PackedStringArray = []
	var ok := true
	_start_precoin()
	ok = ok and _precoin_enabled and _precoin != null
	_ensure_standalone_business()
	if _grab_flow != null:
		_grab_flow.set_chain_speed(8.0)
	ok = ok and await _drive_paid_round_to_operate()
	lines.append("reach_operate=%s balance=%d" % [str(ok), _round_business.coin_balance()])
	var paid_before := _round_business.paid_round_count()
	ok = ok and await _drive_grab_success()
	var saw_victory_before_guide := false
	var guide_after_victory := false
	var guide_audio_ok := false
	var waited := 0.0
	while waited < 40.0 and not _round_business.is_success_hold():
		var phase := _round_business.result_phase()
		var anim := String(_player.assigned_animation)
		if phase == "feedback" and anim == "youyou_victory01":
			saw_victory_before_guide = true
		if phase == "success_guide" and anim == "youyou_Speak_Idle05":
			guide_after_victory = saw_victory_before_guide
			var timeline: Node = _event_perf.get_timeline() if _event_perf != null else null
			if timeline != null and timeline.has_method("get_audio_path"):
				guide_audio_ok = String(timeline.get_audio_path()) == "res://配音/成功引导小游戏1-手感正好.mp3"
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and saw_victory_before_guide and guide_after_victory and guide_audio_ok
	ok = ok and _round_business.is_success_hold()
	var idle_ok := false
	waited = 0.0
	while waited < 3.0:
		if String(_player.assigned_animation) == IDLE_ANIM:
			idle_ok = true
			break
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and idle_ok
	lines.append("guide_order victory=%s speak=%s audio=%s idle=%s" % [
		str(saw_victory_before_guide), str(guide_after_victory), str(guide_audio_ok), str(idle_ok),
	])
	var hold_balance := _round_business.coin_balance()
	ok = ok and hold_balance < 2
	await get_tree().create_timer(1.0).timeout
	_push_key_ctrl(KEY_T)
	await get_tree().process_frame
	_push_key_ctrl(KEY_T)
	await get_tree().process_frame
	ok = ok and _round_business.coin_balance() == hold_balance + 2
	ok = ok and _round_business.is_success_hold()
	ok = ok and _round_business.paid_round_count() == paid_before
	ok = ok and _round_business.welcome_play_count() == 1
	ok = ok and coin_balance_text() == "币：%d" % _round_business.coin_balance()
	lines.append("funded_during_wait balance=%d still_hold=%s welcome=%d" % [
		_round_business.coin_balance(), str(_round_business.is_success_hold()), _round_business.welcome_play_count(),
	])
	var before_replay := _round_business.paid_round_count()
	_push_key_ctrl(KEY_Z)
	await get_tree().process_frame
	await get_tree().process_frame
	ok = ok and _round_business.paid_round_count() == before_replay + 1
	ok = ok and _round_business.coin_balance() == hold_balance
	ok = ok and _round_business.stage_name() == "等待开始"
	var saw_crane01 := false
	var saw_idle_gap := false
	var operate_ok := false
	var saw_return_welcome := false
	waited = 0.0
	while waited < 20.0:
		var anim_now := String(_player.assigned_animation)
		if anim_now == "youyou_coin01" or _active_show_event() == "youyou_coin01":
			var return_audio := ""
			if _event_perf != null and _event_perf.get_timeline() != null:
				return_audio = String(_event_perf.get_timeline().get_audio_path())
			if return_audio.ends_with("第二次抓娃欢迎.mp3"):
				saw_return_welcome = true
		if anim_now == "youyou_claw crane01_01":
			saw_crane01 = true
		elif saw_crane01 and anim_now == IDLE_ANIM:
			saw_idle_gap = true
		if _round_business.stage_name() == "玩家操作" and anim_now == "youyou_claw crane01_02":
			operate_ok = true
			break
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and saw_return_welcome and saw_crane01 and operate_ok and not saw_idle_gap
	lines.append("replay return=%s crane01=%s crane02=%s idle_gap=%s deducted=%d" % [
		str(saw_return_welcome), str(saw_crane01), str(operate_ok), str(saw_idle_gap), _round_business.paid_round_count(),
	])
	_push_key_ctrl(KEY_T)
	await get_tree().process_frame
	_push_key_ctrl(KEY_T)
	await get_tree().process_frame
	ok = ok and _round_business.coin_balance() == 2
	ok = ok and _round_business.stage_name() == "玩家操作"
	ok = ok and await _drive_grab_success()
	waited = 0.0
	while waited < 40.0 and not _round_business.is_success_hold():
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and _round_business.is_success_hold() and _round_business.coin_balance() == 2
	var before_second := _round_business.paid_round_count()
	_push_key_ctrl(KEY_Z)
	await get_tree().process_frame
	await get_tree().process_frame
	ok = ok and _round_business.paid_round_count() == before_second + 1
	ok = ok and _round_business.coin_balance() == 0
	lines.append("second_replay balance=%d paid=%d" % [
		_round_business.coin_balance(), _round_business.paid_round_count(),
	])
	_round_business.debug_reset_standalone_for_check()
	if _invite_flow != null:
		_invite_flow.debug_reset_flow()
	if _grab_flow != null:
		_grab_flow.notify_presence_released()
	await get_tree().process_frame
	var paid_before_low := _round_business.paid_round_count()
	var low_paid := await _drive_paid_round_to_operate()
	low_paid = low_paid and _round_business.paid_round_count() > paid_before_low
	if not low_paid:
		_submit_round(ClawBusinessNode.COIN_ACCEPTED)
		await get_tree().process_frame
		_submit_round(ClawBusinessNode.COIN_ACCEPTED)
		waited = 0.0
		while waited < 25.0:
			if _round_business.stage_name() == "玩家操作" and String(_player.assigned_animation) == "youyou_claw crane01_02":
				low_paid = true
				break
			await get_tree().process_frame
			waited += get_process_delta_time()
	var low_grab := false
	if low_paid:
		low_grab = await _drive_grab_success()
	waited = 0.0
	while waited < 40.0 and not _round_business.is_success_hold():
		await get_tree().process_frame
		waited += get_process_delta_time()
	var entered_hold := _round_business.is_success_hold() and _round_business.coin_balance() < 2
	var paid_at_hold := _round_business.paid_round_count()
	await get_tree().create_timer(10.4).timeout
	var timed_out := _round_business.stage_name() == "待机"
	timed_out = timed_out and _round_business.paid_round_count() == 0
	timed_out = timed_out and not _round_business.is_success_hold()
	var welcome_before_again := _round_business.welcome_play_count()
	ok = ok and low_paid and low_grab and entered_hold and timed_out
	_submit_round(ClawBusinessNode.COIN_ACCEPTED)
	await get_tree().process_frame
	_submit_round(ClawBusinessNode.COIN_ACCEPTED)
	await get_tree().process_frame
	ok = ok and _round_business.welcome_play_count() == welcome_before_again + 1
	lines.append("timeout_standby=%s stage=%s low_paid=%s low_grab=%s hold=%s rewelcome=%s" % [
		str(timed_out), _round_business.stage_name(), str(low_paid), str(low_grab), str(entered_hold), str(_round_business.welcome_play_count() == welcome_before_again + 1),
	])
	lines.append("=== success_continue_check_pass=%s ===" % str(ok))
	print("\n".join(lines))
	get_tree().quit(0 if ok else 1)


func _drive_paid_round_to_operate() -> bool:
	_push_key_ctrl(KEY_T)
	var waited := 0.0
	while waited < 8.0 and _round_business.coin_balance() < 1:
		await get_tree().process_frame
		waited += get_process_delta_time()
	_push_key_ctrl(KEY_T)
	waited = 0.0
	while waited < 25.0:
		if _round_business.stage_name() == "玩家操作" and String(_player.assigned_animation) == "youyou_claw crane01_02":
			return true
		await get_tree().process_frame
		waited += get_process_delta_time()
	return false


func _drive_grab_success() -> bool:
	if _grab_flow != null:
		_grab_flow.debug_force_next_result(true)
	_push_key_ctrl(KEY_G)
	var waited := 0.0
	while waited < 15.0 and _grab_flow.phase_name() != "WAIT":
		await get_tree().process_frame
		waited += get_process_delta_time()
	if _grab_flow.phase_name() != "WAIT":
		return false
	_push_key_ctrl(KEY_B)
	var after := 0.0
	while after < 2.0:
		if _round_business.stage_name() == "结果":
			return true
		await get_tree().process_frame
		after += get_process_delta_time()
	return false


func _drive_grab_fail() -> bool:
	if _grab_flow != null:
		_grab_flow.debug_force_next_result(false)
	_push_key_ctrl(KEY_G)
	var waited := 0.0
	while waited < 15.0 and _grab_flow.phase_name() != "WAIT":
		await get_tree().process_frame
		waited += get_process_delta_time()
	if _grab_flow.phase_name() != "WAIT":
		return false
	_push_key_ctrl(KEY_B)
	var after := 0.0
	while after < 2.0:
		if _round_business.stage_name() == "结果":
			return true
		await get_tree().process_frame
		after += get_process_delta_time()
	return false


func _run_fail_continue_check() -> void:
	var lines: PackedStringArray = []
	var ok := true
	set_auto_launch_minigame_on_play(false)
	_start_precoin()
	ok = ok and _precoin_enabled and _precoin != null
	_ensure_standalone_business()
	if _grab_flow != null:
		_grab_flow.set_chain_speed(8.0)
	if _invite_flow != null:
		_invite_flow.debug_enable_mock_asr(true)
	ok = ok and await _drive_paid_round_to_operate()
	lines.append("reach_operate=%s balance=%d" % [str(ok), _round_business.coin_balance()])
	ok = ok and await _drive_grab_fail()
	var waited := 0.0
	while waited < 45.0 and not _round_business.is_invite_listen():
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and _round_business.is_invite_listen()
	lines.append("invite_listen=%s" % str(_round_business.is_invite_listen()))
	if _invite_flow != null:
		_invite_flow.debug_inject_partial("不要了", true)
	else:
		_round_business.submit_invite_intent("DECLINE")
	waited = 0.0
	var saw_fail_guide := false
	var guide_audio_ok := false
	while waited < 45.0 and not _round_business.is_fail_hold():
		var phase := _round_business.result_phase()
		if phase == "fail_continue_guide":
			saw_fail_guide = true
			var timeline: Node = _event_perf.get_timeline() if _event_perf != null else null
			if timeline != null and timeline.has_method("get_audio_path"):
				guide_audio_ok = String(timeline.get_audio_path()) == "res://配音/抓取失败引导抓娃娃1.mp3"
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and saw_fail_guide and guide_audio_ok and _round_business.is_fail_hold()
	var idle_ok := false
	waited = 0.0
	while waited < 3.0:
		if String(_player.assigned_animation) == IDLE_ANIM:
			idle_ok = true
			break
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and idle_ok
	lines.append("fail_guide audio=%s idle=%s hold=%s" % [str(guide_audio_ok), str(idle_ok), str(_round_business.is_fail_hold())])
	var hold_balance := _round_business.coin_balance()
	ok = ok and hold_balance < 2
	var paid_before := _round_business.paid_round_count()
	_push_key_ctrl(KEY_Z)
	await get_tree().process_frame
	ok = ok and _round_business.is_fail_hold() and _round_business.paid_round_count() == paid_before
	_push_key_ctrl(KEY_T)
	await get_tree().process_frame
	ok = ok and _round_business.coin_balance() == hold_balance + 1
	ok = ok and _round_business.is_fail_hold()
	_push_key_ctrl(KEY_T)
	await get_tree().process_frame
	await get_tree().process_frame
	ok = ok and _round_business.paid_round_count() == paid_before + 1
	ok = ok and _round_business.coin_balance() == hold_balance
	ok = ok and _round_business.stage_name() == "等待开始"
	lines.append("coin_reopen balance=%d stage=%s" % [
		_round_business.coin_balance(), _round_business.stage_name(),
	])
	var saw_crane01 := false
	var saw_idle_gap := false
	var operate_ok := false
	waited = 0.0
	while waited < 20.0:
		var anim_now := String(_player.assigned_animation)
		if anim_now == "youyou_claw crane01_01":
			saw_crane01 = true
		elif saw_crane01 and anim_now == IDLE_ANIM:
			saw_idle_gap = true
		if _round_business.stage_name() == "玩家操作" and anim_now == "youyou_claw crane01_02":
			operate_ok = true
			break
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and saw_crane01 and operate_ok and not saw_idle_gap
	lines.append("replay_y crane01=%s crane02=%s idle_gap=%s deducted=%d" % [
		str(saw_crane01), str(operate_ok), str(saw_idle_gap), _round_business.paid_round_count(),
	])
	_round_business.debug_reset_standalone_for_check()
	if _invite_flow != null:
		_invite_flow.debug_reset_flow()
	if _grab_flow != null:
		_grab_flow.notify_presence_released()
	await get_tree().process_frame
	var paid_before_low := _round_business.paid_round_count()
	var low_paid := await _drive_paid_round_to_operate()
	low_paid = low_paid and _round_business.paid_round_count() > paid_before_low
	if not low_paid:
		_submit_round(ClawBusinessNode.COIN_ACCEPTED)
		await get_tree().process_frame
		_submit_round(ClawBusinessNode.COIN_ACCEPTED)
		waited = 0.0
		while waited < 25.0:
			if _round_business.stage_name() == "玩家操作" and String(_player.assigned_animation) == "youyou_claw crane01_02":
				low_paid = true
				break
			await get_tree().process_frame
			waited += get_process_delta_time()
	var low_fail := false
	if low_paid:
		low_fail = await _drive_grab_fail()
	waited = 0.0
	while waited < 45.0 and not _round_business.is_invite_listen():
		await get_tree().process_frame
		waited += get_process_delta_time()
	if _invite_flow != null and _round_business.is_invite_listen():
		_invite_flow.debug_inject_partial("不想玩", true)
	waited = 0.0
	while waited < 45.0 and not _round_business.is_fail_hold():
		await get_tree().process_frame
		waited += get_process_delta_time()
	var entered_hold := _round_business.is_fail_hold() and _round_business.coin_balance() < 2
	await get_tree().create_timer(10.4).timeout
	var returned_standby := _round_business.stage_name() == "待机"
	returned_standby = returned_standby and not _round_business.is_fail_hold()
	returned_standby = returned_standby and _round_business.paid_round_count() == 0
	ok = ok and low_paid and low_fail and entered_hold and returned_standby
	lines.append("timeout_to_standby=%s stage=%s low_paid=%s low_fail=%s hold=%s" % [
		str(returned_standby), _round_business.stage_name(), str(low_paid), str(low_fail), str(entered_hold),
	])
	lines.append("=== fail_continue_check_pass=%s ===" % str(ok))
	print("\n".join(lines))
	get_tree().quit(0 if ok else 1)


func _run_coin_phase1_check() -> void:
	var lines: PackedStringArray = []
	var ok := true
	_ensure_standalone_business()
	if _grab_flow != null:
		_grab_flow.set_chain_speed(8.0)
	_push_key_ctrl(KEY_T)
	await get_tree().process_frame
	await get_tree().process_frame
	ok = ok and _round_business.coin_balance() == 1
	ok = ok and _round_business.welcome_play_count() == 0
	ok = ok and _round_business.stage_name() == "待机"
	ok = ok and coin_balance_text() == "币：1"
	ok = ok and _active_show_event() != "youyou_coin01" and _active_show_event() != "youyou_coin02"
	ok = ok and String(_player.assigned_animation) != "youyou_coin01" and String(_player.assigned_animation) != "youyou_coin02"
	lines.append("first_coin balance=%d ui=%s welcome=%d stage=%s" % [
		_round_business.coin_balance(), coin_balance_text(), _round_business.welcome_play_count(), _round_business.stage_name(),
	])
	_push_key_ctrl(KEY_T)
	await get_tree().process_frame
	ok = ok and _round_business.welcome_play_count() == 1
	ok = ok and _round_business.coin_balance() == 2
	ok = ok and coin_balance_text() == "币：2"
	var waited := 0.0
	var saw_crane01 := false
	var saw_idle_gap := false
	var seen_coin := false
	var operate_ok := false
	waited = 0.0
	while waited < 45.0:
		var anim_now := String(_player.assigned_animation)
		if anim_now == "youyou_coin02" or _active_show_event() == "youyou_coin02":
			seen_coin = true
		elif seen_coin and not saw_crane01 and anim_now == IDLE_ANIM:
			saw_idle_gap = true
		if anim_now == "youyou_claw crane01_01":
			saw_crane01 = true
		if _round_business.stage_name() == "玩家操作" and anim_now == "youyou_claw crane01_02":
			operate_ok = true
			break
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and seen_coin and saw_crane01 and not saw_idle_gap and operate_ok
	ok = ok and _round_business.coin_balance() == 0 and _round_business.paid_round_count() == 1
	ok = ok and coin_balance_text() == "币：0"
	lines.append("chain crane01=%s idle_gap=%s operate=%s balance=%d ui=%s deducted=%d" % [
		str(saw_crane01), str(saw_idle_gap), str(operate_ok), _round_business.coin_balance(), coin_balance_text(), _round_business.paid_round_count(),
	])
	_push_key_ctrl(KEY_T)
	await get_tree().process_frame
	ok = ok and _round_business.coin_balance() == 1
	ok = ok and _round_business.welcome_play_count() == 1
	ok = ok and _round_business.paid_round_count() == 1
	ok = ok and _round_business.stage_name() == "玩家操作"
	ok = ok and coin_balance_text() == "币：1"
	lines.append("extra_coin balance=%d welcome=%d stage=%s" % [
		_round_business.coin_balance(), _round_business.welcome_play_count(), _round_business.stage_name(),
	])
	lines.append("=== coin_phase1_check_pass=%s ===" % str(ok))
	print("\n".join(lines))
	get_tree().quit(0 if ok else 1)


func _run_grab_flow_check() -> void:
	var lines: PackedStringArray = []
	var ok := true
	_start_precoin()
	if _precoin != null:
		_precoin.configure_dwells(0.05, 0.08, 0.05, 0.08)
	_ensure_standalone_business()
	if _grab_flow != null:
		_grab_flow.set_chain_speed(8.0)
		_grab_flow.set_idle_gap(0.35)
	ok = _grab_flow != null and _round_business != null and _grab_flow.debug_simulate_open_failure()
	lines.append("load_fail_stops=%s" % str(ok))
	var idle_hips := _hips_height()
	await get_tree().process_frame
	var early_grab: Dictionary = {"ok": true}
	if _round_business != null:
		early_grab = _round_business.submit(ClawBusinessNode.GRAB_PRESSED)
	ok = ok and early_grab.get("ok", true) == false and _round_business.stage_name() == "待机"
	lines.append("early_grab_rejected=%s" % str(early_grab.get("ok", true) == false))
	var early_judge: bool = _grab_flow.request_judgment() if _grab_flow != null else true
	ok = ok and not early_judge
	lines.append("early_judge_rejected=%s" % str(not early_judge))
	if _player != null:
		_player.speed_scale = 20.0
	_push_key(KEY_F5)
	var attract_id := await _await_precoin_action(8.0)
	ok = ok and attract_id != ""
	lines.append("handoff_from=%s" % attract_id)
	_push_key_ctrl(KEY_T)
	await get_tree().process_frame
	var yielded := _precoin != null and _precoin.is_yielding()
	ok = ok and not yielded
	var coin_interrupt := false
	var waited := 0.0
	while waited < 2.0:
		if _active_show_event() == "youyou_coin02" or String(_player.assigned_animation) == "youyou_coin02":
			coin_interrupt = true
			break
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and coin_interrupt
	lines.append("yielded=%s coin_interrupt=%s stage=%s" % [str(yielded), str(coin_interrupt), _round_business.stage_name()])
	var coin_seen := ""
	waited = 0.0
	while waited < 30.0 and coin_seen != "youyou_coin02":
		coin_seen = _active_show_event()
		if coin_seen == "youyou_coin02":
			break
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and coin_seen == "youyou_coin02" and _round_business.stage_name() == "待机"
	ok = ok and _round_business.coin_balance() == 1
	ok = ok and _round_business.welcome_play_count() == 1
	lines.append("coin=%s balance=%d welcome=%d" % [coin_seen, _round_business.coin_balance(), _round_business.welcome_play_count()])
	if _player != null:
		_player.speed_scale = 1.0
	_push_key_ctrl(KEY_T)
	await get_tree().process_frame
	ok = ok and _round_business.welcome_play_count() == 1
	ok = ok and _round_business.coin_balance() >= 1
	lines.append("second_coin_balance=%d welcome=%d stage=%s" % [
		_round_business.coin_balance(), _round_business.welcome_play_count(), _round_business.stage_name(),
	])
	var operate_ok := false
	var saw_crane01 := false
	var saw_idle_gap := false
	var seen_coin := false
	waited = 0.0
	while waited < 45.0:
		var anim_now := String(_player.assigned_animation)
		if anim_now == "youyou_coin02" or _active_show_event() == "youyou_coin02":
			seen_coin = true
		elif seen_coin and not saw_crane01 and anim_now == IDLE_ANIM:
			saw_idle_gap = true
		if anim_now == "youyou_claw crane01_01":
			saw_crane01 = true
		if _round_business.stage_name() == "玩家操作" and anim_now == "youyou_claw crane01_02":
			operate_ok = true
			break
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and operate_ok and saw_crane01 and not saw_idle_gap
	ok = ok and _round_business.coin_balance() == 0 and _round_business.paid_round_count() == 1
	lines.append("operate_loop_pending=%s crane01=%s idle_gap=%s balance=%d" % [
		str(operate_ok), str(saw_crane01), str(saw_idle_gap), _round_business.coin_balance(),
	])
	var operate_clip := _player.get_animation("youyou_claw crane01_02") if _player.has_animation("youyou_claw crane01_02") else null
	var looping := operate_clip != null and operate_clip.loop_mode == Animation.LOOP_LINEAR and _player.is_playing()
	ok = ok and looping
	lines.append("operate_loop=%s anim=%s" % [str(looping), String(_player.assigned_animation)])
	lines.append("hips_idle=%.3f hips_operate=%.3f" % [idle_hips, _hips_height()])
	await get_tree().process_frame
	var shot: Image = get_viewport().get_texture().get_image()
	if shot != null:
		shot.save_png("C:/Users/29385/AppData/Local/Temp/youyou_grab_operate.png")
	var voice_ok: bool = _grab_flow.debug_force_voice()
	await get_tree().create_timer(0.35).timeout
	voice_ok = voice_ok and _grab_flow.is_viseme_active() and _face.get_active_viseme() != ""
	_grab_flow.stop_ambient()
	await get_tree().process_frame
	voice_ok = voice_ok and not _grab_flow.is_voice_playing() and not _grab_flow.is_viseme_active() and _face.get_active_viseme() == ""
	ok = ok and voice_ok and String(_player.assigned_animation) == "youyou_claw crane01_02"
	lines.append("operate_voice=%s viseme_clear=%s" % [str(voice_ok), str(_face.get_active_viseme() == "")])
	var gaze: Node = get_node_or_null("EyeGazeController")
	var head: Node = get_node_or_null("HeadFollowController")
	var look_ok := gaze != null and head != null
	if look_ok:
		gaze.call("debug_set_keys", true, true, true, true, true)
		for _i in 8:
			_idle_life.call("process_life", 0.03, get_viewport())
		var cancelled: Vector2 = gaze.call("get_keyboard_gaze")
		look_ok = cancelled.length() < 0.03
		gaze.call("debug_set_keys", false, true, false, false, true)
		for _i in 18:
			_idle_life.call("process_life", 0.03, get_viewport())
		var moved: Vector2 = gaze.call("get_keyboard_gaze")
		var yaw := float(head.call("get_current_yaw"))
		var max_x := float(gaze.call("get_max_horizontal"))
		look_ok = look_ok and moved.x > 0.05 and moved.x <= max_x + 0.001 and yaw > 0.004 and absf(yaw) < 0.16
		gaze.call("debug_set_keys", false, false, false, false, false)
		for _i in 40:
			_idle_life.call("process_life", 0.03, get_viewport())
		var back: Vector2 = gaze.call("get_keyboard_gaze")
		var mouse_rest: Vector2 = gaze.call("get_mouse_gaze_target")
		look_ok = look_ok and back.distance_to(mouse_rest) < 0.08 and String(_player.assigned_animation) == "youyou_claw crane01_02"
		lines.append("look x=%.3f yaw=%.3f rest=%.3f" % [moved.x, yaw, back.distance_to(mouse_rest)])
	ok = ok and look_ok
	lines.append("look_ok=%s" % str(look_ok))
	_grab_flow.debug_force_voice()
	await get_tree().create_timer(0.2).timeout
	_push_key_ctrl(KEY_G)
	await get_tree().process_frame
	var grabbed: bool = _round_business.stage_name() == "正在抓" and not _grab_flow.is_voice_playing() and _face.get_active_viseme() == ""
	ok = ok and grabbed
	_push_key_ctrl(KEY_G)
	await get_tree().process_frame
	ok = ok and _round_business.stage_name() == "正在抓"
	lines.append("grab_once=%s" % str(grabbed))
	var wait_ok := false
	var saw_idle_during_grab := false
	waited = 0.0
	while waited < 12.0:
		var grab_anim := String(_player.assigned_animation)
		if grab_anim == IDLE_ANIM:
			saw_idle_during_grab = true
		if _grab_flow.phase_name() == "WAIT" and grab_anim == "youyou_claw crane01_04" and _player.is_playing():
			wait_ok = true
			break
		await get_tree().process_frame
		waited += get_process_delta_time()
	var wait_clip := _player.get_animation("youyou_claw crane01_04") if _player.has_animation("youyou_claw crane01_04") else null
	wait_ok = wait_ok and wait_clip != null and wait_clip.loop_mode == Animation.LOOP_LINEAR
	ok = ok and wait_ok and not saw_idle_during_grab and _precoin.is_business()
	lines.append("wait_loop=%s idle_insert=%s business=%s" % [str(wait_ok), str(saw_idle_during_grab), str(_precoin.is_business())])
	for action_id in ["youyou_coin01", "youyou_claw crane01_01", "youyou_claw crane01_02", "youyou_claw crane01_03", "youyou_claw crane01_04", "youyou_claw crane01_05", "youyou_victory01", "youyou_fail01"]:
		if _player.has_animation(action_id):
			lines.append("clip %s len=%.2f" % [action_id, _player.get_animation(action_id).length])
	_grab_flow.debug_force_voice()
	await get_tree().create_timer(0.15).timeout
	var surprise_held: bool = _face.get_active_emotion() == "surprise"
	var look_during_grab: bool = _grab_flow.wants_look()
	var gaze_grab: Node = get_node_or_null("EyeGazeController")
	if look_during_grab and gaze_grab != null:
		var before_grab: Vector2 = gaze_grab.call("get_keyboard_gaze")
		gaze_grab.call("debug_set_keys", false, true, false, false, true)
		for _step in 12:
			_idle_life.call("process_life", 0.03, get_viewport())
		var after_grab: Vector2 = gaze_grab.call("get_keyboard_gaze")
		look_during_grab = after_grab.x > before_grab.x + 0.04 and String(_player.assigned_animation) == "youyou_claw crane01_04"
		gaze_grab.call("debug_set_keys", false, false, false, false, false)
	ok = ok and surprise_held and look_during_grab
	lines.append("grab_surprise=%s grab_look=%s" % [str(surprise_held), str(look_during_grab)])
	_push_key_ctrl(KEY_J)
	await get_tree().process_frame
	var j_ignored: bool = _grab_flow.phase_name() == "WAIT" and not _grab_flow.result_latched()
	ok = ok and j_ignored
	lines.append("ctrl_j_ignored=%s" % str(j_ignored))
	_grab_flow.debug_force_next_result(false)
	_push_key_ctrl(KEY_B)
	await get_tree().process_frame
	var judged: bool = _grab_flow.phase_name() == "STAND" and not _grab_flow.result_latched() and not _grab_flow.is_voice_playing()
	var judged_again: bool = _grab_flow.request_judgment()
	ok = ok and judged and not judged_again
	lines.append("stand_before_roll=%s repeat=%s" % [str(judged), str(judged_again)])
	var fail_play: Dictionary = await _confirm_result_playback("youyou_fail01", false)
	ok = ok and bool(fail_play.get("ok", false))
	lines.append(
		"fail_playback ok=%s event=%s current=%s playing=%s advanced=%s voice=%s idle=%s banner=%s pos=%.3f"
		% [
			str(fail_play.get("ok", false)),
			str(fail_play.get("event_id", "")),
			str(fail_play.get("current", "")),
			str(fail_play.get("playing", false)),
			str(fail_play.get("advanced", false)),
			str(fail_play.get("voice", false)),
			str(fail_play.get("idle", false)),
			str(fail_play.get("banner", "")),
			float(fail_play.get("pos", -1.0)),
		]
	)
	if _event_perf != null:
		_event_perf.stop_event(true)
	_round_business.debug_resume_grabbing()
	_grab_flow.debug_rearm_wait()
	_grab_flow.debug_force_next_result(true)
	_push_key_ctrl(KEY_B)
	await get_tree().process_frame
	var second_stand: bool = _grab_flow.phase_name() == "STAND" and not _grab_flow.result_latched()
	ok = ok and second_stand
	lines.append("second_stand=%s" % str(second_stand))
	var win_play: Dictionary = await _confirm_result_playback("youyou_victory01", true)
	ok = ok and bool(win_play.get("ok", false))
	lines.append(
		"success_playback ok=%s event=%s current=%s playing=%s advanced=%s voice=%s idle=%s banner=%s pos=%.3f"
		% [
			str(win_play.get("ok", false)),
			str(win_play.get("event_id", "")),
			str(win_play.get("current", "")),
			str(win_play.get("playing", false)),
			str(win_play.get("advanced", false)),
			str(win_play.get("voice", false)),
			str(win_play.get("idle", false)),
			str(win_play.get("banner", "")),
			float(win_play.get("pos", -1.0)),
		]
	)
	var phase_before: String = _grab_flow.phase_name()
	_grab_flow.debug_stale_finish()
	ok = ok and _grab_flow.phase_name() == phase_before and _grab_flow.trace_has("过期回调被忽略")
	lines.append("stale_ignored=%s" % str(_grab_flow.trace_has("过期回调被忽略")))
	lines.append("=== grab_flow_check_pass=%s ===" % str(ok))
	print("\n".join(lines))
	get_tree().quit(0 if ok else 1)


func _run_minigame_invite_phase_a_check() -> void:
	var lines: PackedStringArray = []
	var ok := true
	_start_precoin()
	_ensure_standalone_business()
	if _grab_flow != null:
		_grab_flow.set_chain_speed(8.0)
		_grab_flow.set_idle_gap(0.35)
	if _precoin != null:
		_precoin.configure_dwells(0.05, 0.08, 0.05, 0.08)
	ok = ok and _invite_flow != null and _round_business != null
	var audio_ok := FileAccess.file_exists("res://配音/失败引导小游戏2.mp3")
	ok = ok and audio_ok
	lines.append("audio_exists=%s" % str(audio_ok))
	var validate: Dictionary = _event_perf.validate_event("youyou_Speak_Idle05")
	ok = ok and bool(validate.get("ok", false))
	lines.append("speak05_validate=%s" % str(validate.get("ok", false)))
	_push_key(KEY_F5)
	await get_tree().process_frame
	_push_key_ctrl(KEY_T)
	var waited := 0.0
	while waited < 35.0 and _round_business.stage_name() != "玩家操作":
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and _round_business.stage_name() == "玩家操作"
	lines.append("operate_stage=%s" % _round_business.stage_name())
	_push_key_ctrl(KEY_G)
	await get_tree().process_frame
	waited = 0.0
	while waited < 12.0:
		if _round_business.stage_name() == "正在抓" and String(_player.assigned_animation) == "youyou_claw crane01_04":
			break
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and _round_business.stage_name() == "正在抓"
	_grab_flow.debug_force_next_result(false)
	_push_key_ctrl(KEY_B)
	await get_tree().process_frame
	waited = 0.0
	while waited < 20.0 and not _grab_flow.result_latched():
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and _grab_flow.result_latched()
	var fail_ok := false
	waited = 0.0
	while waited < 20.0:
		if String(_player.assigned_animation) == "youyou_fail01" and _player.is_playing():
			fail_ok = true
			break
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and fail_ok
	lines.append("fail01_playing=%s" % str(fail_ok))
	waited = 0.0
	var invite_listen := false
	var saw_speak := false
	while waited < 30.0:
		var anim := String(_player.assigned_animation)
		if anim == "youyou_Speak_Idle05":
			saw_speak = true
		if _round_business.is_invite_listen():
			invite_listen = true
			break
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and saw_speak and invite_listen
	ok = ok and String(_player.assigned_animation) == IDLE_ANIM
	ok = ok and _invite_flow.is_waiting_answer()
	lines.append("saw_speak05=%s invite_listen=%s idle=%s phase=%s" % [
		str(saw_speak), str(invite_listen), String(_player.assigned_animation), _invite_flow.phase_name(),
	])
	var victory_submit: Dictionary = _round_business.submit(ClawBusinessNode.GRAB_SUCCEEDED)
	ok = ok and victory_submit.get("ok", true) == false
	lines.append("success_blocked_during_invite=%s" % str(victory_submit.get("ok", true) == false))
	lines.append("=== minigame_invite_phase_a_check_pass=%s ===" % str(ok))
	print("\n".join(lines))
	get_tree().quit(0 if ok else 1)


func _run_minigame_invite_phase_b_check() -> void:
	var lines: PackedStringArray = []
	var ok := true
	set_auto_launch_minigame_on_play(false)
	const Rules := preload("res://Scripts/voice/minigame_intent_rules.gd")
	ok = ok and Rules.classify("我想玩") == "PLAY"
	ok = ok and Rules.classify("不想玩") == "DECLINE"
	ok = ok and Rules.classify("不") == "UNKNOWN"
	ok = ok and Rules.classify("我想") == "UNKNOWN"
	ok = ok and Rules.classify("玩") == "PLAY"
	ok = ok and Rules.classify("不要了") == "DECLINE"
	ok = ok and Rules.classify("我不想玩") == "DECLINE"
	ok = ok and Rules.classify("不是") == "UNKNOWN"
	ok = ok and not Rules.can_early_commit("UNKNOWN")
	lines.append("rules_ok=%s" % str(ok))
	_invite_flow.debug_enable_mock_asr(true)
	_start_precoin()
	_ensure_standalone_business()
	if _grab_flow != null:
		_grab_flow.set_chain_speed(8.0)
		_grab_flow.set_idle_gap(0.35)
	_push_key(KEY_F5)
	await get_tree().process_frame
	_push_key_ctrl(KEY_T)
	var waited := 0.0
	while waited < 35.0 and _round_business.stage_name() != "玩家操作":
		await get_tree().process_frame
		waited += get_process_delta_time()
	_push_key_ctrl(KEY_G)
	await get_tree().process_frame
	waited = 0.0
	while waited < 12.0 and String(_player.assigned_animation) != "youyou_claw crane01_04":
		await get_tree().process_frame
		waited += get_process_delta_time()
	_grab_flow.debug_force_next_result(false)
	_push_key_ctrl(KEY_B)
	waited = 0.0
	while waited < 20.0 and not _grab_flow.result_latched():
		await get_tree().process_frame
		waited += get_process_delta_time()
	waited = 0.0
	while waited < 25.0 and not _invite_flow.is_waiting_answer():
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and _invite_flow.is_waiting_answer()
	lines.append("listening=%s phase=%s" % [str(_invite_flow.is_waiting_answer()), _invite_flow.phase_name()])
	await get_tree().create_timer(InviteListenConfig.POST_GUIDE_SETTLE_SEC + 0.05).timeout
	if _invite_flow.phase_name() == "LISTENING":
		_invite_flow.debug_inject_partial("我想玩", true)
	waited = 0.0
	while waited < 5.0 and _invite_flow.committed_intent() != "PLAY":
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and _invite_flow.committed_intent() == "PLAY"
	ok = ok and _round_business.is_invite_play_accepted()
	lines.append("intent=%s accepted=%s" % [_invite_flow.committed_intent(), str(_round_business.is_invite_play_accepted())])
	_invite_flow.debug_inject_partial("再来一次玩", false)
	await get_tree().process_frame
	ok = ok and _invite_flow.committed_intent() == "PLAY"
	lines.append("no_double_commit=%s" % str(_invite_flow.committed_intent() == "PLAY"))
	lines.append("=== minigame_invite_phase_b_check_pass=%s ===" % str(ok))
	print("\n".join(lines))
	get_tree().quit(0 if ok else 1)


func _run_minigame_invite_state_check() -> void:
	var lines: PackedStringArray = []
	var ok := true
	const NlsHexIdScript := preload("res://Scripts/voice/nls_hex_id.gd")
	const InviteStreamingAsrScript := preload("res://Scripts/voice/invite_streaming_asr.gd")
	var sample_id := NlsHexIdScript.new_id32()
	ok = ok and NlsHexIdScript.is_valid_id32(sample_id)
	ok = ok and not NlsHexIdScript.is_valid_id32("12345")
	ok = ok and not NlsHexIdScript.is_valid_id32("%d-%d" % [Time.get_ticks_usec(), randi()])
	lines.append("hex_id_ok=%s" % str(ok))
	var asr_probe := InviteStreamingAsrScript.new()
	asr_probe.mock_mode = true
	add_child(asr_probe)
	asr_probe.setup(_invite_flow.get_node("InviteNlsConfig"), _invite_flow.get_node("InviteNlsTokens"))
	var task_flags := {"seen": false}
	asr_probe.session_failed.connect(func(reason: String) -> void:
		if reason.begins_with("task_failed:"):
			task_flags["seen"] = true
	)
	asr_probe.debug_simulate_task_failed("mock_task_failed")
	ok = ok and bool(task_flags["seen"])
	asr_probe.queue_free()
	lines.append("task_failed_mock=%s" % str(bool(task_flags["seen"])))
	_ensure_standalone_business()
	_invite_flow.debug_enable_mock_asr(true)
	_invite_flow.debug_begin_mock_listen_round()
	var waited := 0.0
	while waited < 3.0 and _invite_flow.phase_name() != "LISTENING":
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and _invite_flow.phase_name() == "LISTENING"
	_invite_flow.debug_simulate_listen_timeout()
	await get_tree().process_frame
	ok = ok and _invite_flow.debug_unknown_retry_count() == 1
	ok = ok and _invite_flow.committed_intent() == ""
	ok = ok and _invite_flow.phase_name() == "PLAYING"
	lines.append("first_unknown_reask=%s" % str(ok))
	_invite_flow.debug_simulate_asr_failed("websocket_closed")
	await get_tree().process_frame
	ok = ok and _invite_flow.committed_intent() == ""
	ok = ok and _invite_flow.debug_unknown_retry_count() == 1
	lines.append("reask_late_close_ignored=%s" % str(_invite_flow.committed_intent() == ""))
	_invite_flow.debug_jump_to_next_listen_round()
	waited = 0.0
	while waited < 3.0 and _invite_flow.phase_name() != "LISTENING":
		await get_tree().process_frame
		waited += get_process_delta_time()
	ok = ok and _invite_flow.phase_name() == "LISTENING"
	_invite_flow.debug_simulate_listen_timeout()
	await get_tree().process_frame
	ok = ok and _invite_flow.committed_intent() == "DECLINE"
	lines.append("second_unknown_decline=%s" % _invite_flow.committed_intent())
	_invite_flow.debug_begin_mock_listen_round()
	waited = 0.0
	while waited < 3.0 and _invite_flow.phase_name() != "LISTENING":
		await get_tree().process_frame
		waited += get_process_delta_time()
	_round_business.debug_enter_invite_listen_for_check()
	_invite_flow.debug_cancel_invite()
	_invite_flow.debug_inject_partial("我想玩", true)
	await get_tree().process_frame
	ok = ok and _invite_flow.committed_intent() != "PLAY"
	ok = ok and not _round_business.is_invite_play_accepted()
	lines.append("cancel_blocks_late_intent=%s" % str(ok))
	lines.append("=== minigame_invite_state_check_pass=%s ===" % str(ok))
	print("\n".join(lines))
	get_tree().quit(0 if ok else 1)


func _run_minigame_invite_phase_c_check() -> void:
	if _invite_flow == null or _round_business == null:
		_abort_minigame_invite_check("phase_c 缺少 invite/business 节点")
		return
	var lines: PackedStringArray = []
	var ok := true
	set_auto_launch_minigame_on_play(false)
	_ensure_standalone_business()
	_invite_flow.debug_enable_mock_asr(true)

	_round_business.debug_reset_standalone_for_check()
	_invite_flow.debug_reset_flow()
	_round_business.debug_enter_invite_listen_for_check()
	_invite_flow.debug_begin_mock_listen_round()
	ok = ok and await _wait_invite_phase("LISTENING", 3.0)
	_invite_flow.debug_inject_partial("好", true)
	await get_tree().process_frame
	ok = ok and _round_business.is_invite_play_accepted()
	var dup_play: Dictionary = _round_business.submit_invite_intent("PLAY")
	ok = ok and dup_play.get("ok", false)
	ok = ok and _invite_flow.committed_intent() == "PLAY"
	lines.append("play_once_accepted=%s" % str(ok))

	_round_business.debug_reset_standalone_for_check()
	_invite_flow.debug_reset_flow()
	_round_business.debug_enter_invite_listen_for_check()
	_invite_flow.debug_begin_mock_listen_round()
	ok = ok and await _wait_invite_phase("LISTENING", 3.0)
	var fail_stage_before := _round_business.stage_name()
	_invite_flow.debug_inject_partial("不要了", true)
	var decline_waited := 0.0
	while decline_waited < 40.0 and not _round_business.is_fail_hold():
		await get_tree().process_frame
		decline_waited += get_process_delta_time()
	ok = ok and _round_business.is_fail_hold()
	ok = ok and fail_stage_before == "结果"
	ok = ok and _round_business.current_stage() != ClawBusinessNode.Stage.MINIGAME
	var regrab: Dictionary = _round_business.submit(ClawBusinessNode.GRAB_FAILED)
	ok = ok and regrab.get("ok", true) == false
	lines.append("decline_to_fail_hold_no_refail=%s" % str(ok))

	_round_business.debug_reset_standalone_for_check()
	_invite_flow.debug_reset_flow()
	_round_business.debug_enter_invite_listen_for_check()
	_invite_flow.debug_begin_mock_listen_round()
	ok = ok and await _wait_invite_phase("LISTENING", 3.0)
	_invite_flow.debug_simulate_listen_timeout()
	await get_tree().process_frame
	ok = ok and _invite_flow.debug_unknown_retry_count() == 1
	ok = ok and _round_business.is_invite_listen()
	lines.append("unknown_reask_once=%s" % str(ok))

	_invite_flow.debug_jump_to_next_listen_round()
	ok = ok and await _wait_invite_phase("LISTENING", 3.0)
	_invite_flow.debug_simulate_listen_timeout()
	await get_tree().process_frame
	ok = ok and _invite_flow.committed_intent() == "ERROR"
	ok = ok and _round_business.stage_name() == "待机"
	ok = ok and not _round_business.is_fail_continue_guide()
	lines.append("second_unknown_listen_error=%s" % str(ok))

	_round_business.debug_reset_standalone_for_check()
	_invite_flow.debug_reset_flow()
	_round_business.debug_enter_invite_listen_for_check()
	_invite_flow.debug_begin_mock_listen_round()
	ok = ok and await _wait_invite_phase("LISTENING", 3.0)
	minigame_invite_cancelled(true)
	_invite_flow.debug_inject_partial("玩", true)
	await get_tree().process_frame
	ok = ok and not _round_business.is_invite_play_accepted()
	ok = ok and _invite_flow.committed_intent() != "PLAY"
	lines.append("cancel_no_decline=%s" % str(ok))

	_round_business.debug_reset_standalone_for_check()
	_invite_flow.debug_reset_flow()
	_round_business.debug_enter_invite_listen_for_check()
	_invite_flow.debug_begin_mock_listen_round()
	ok = ok and await _wait_invite_phase("LISTENING", 3.0)
	_invite_flow.debug_inject_partial("玩", true)
	await get_tree().process_frame
	_invite_flow.debug_simulate_listen_timeout()
	await get_tree().process_frame
	ok = ok and _round_business.is_invite_play_accepted()
	lines.append("play_beats_late_timeout=%s" % str(ok))

	_round_business.debug_reset_standalone_for_check()
	_invite_flow.debug_reset_flow()
	var locked: Dictionary = _round_business.submit_invite_intent("PLAY")
	ok = ok and locked.get("ok", true) == false
	lines.append("duplicate_while_not_listen=%s" % str(locked.get("ok", true) == false))

	_round_business.debug_reset_standalone_for_check()
	_invite_flow.debug_reset_flow()
	_round_business.debug_enter_invite_listen_for_check()
	_invite_flow.debug_begin_mock_listen_round()
	ok = ok and await _wait_invite_phase("LISTENING", 3.0)
	var stale_session := _invite_flow.invite_session_id() - 1
	minigame_invite_on_intent("PLAY", stale_session, "stale_test")
	ok = ok and not _round_business.is_invite_play_accepted()
	lines.append("stale_session_ignored=%s" % str(ok))

	_round_business.debug_reset_standalone_for_check()
	_invite_flow.debug_reset_flow()
	_round_business.debug_enter_invite_listen_for_check()
	_round_business._visitor = true
	minigame_invite_cancelled(true)
	ok = ok and not _round_business.has_visitor()
	ok = ok and not _round_business.explain().contains("招揽")
	lines.append("leave_no_attract=%s" % str(ok))

	_round_business.debug_reset_standalone_for_check()
	_invite_flow.debug_reset_flow()
	_round_business.debug_enter_invite_listen_for_check()
	_invite_flow.debug_begin_mock_listen_round()
	ok = ok and await _wait_invite_phase("LISTENING", 3.0)
	await get_tree().process_frame
	await get_tree().process_frame
	_invite_flow.debug_simulate_asr_failed("websocket_closed")
	await get_tree().process_frame
	ok = ok and _round_business.is_invite_listen()
	ok = ok and not _round_business.is_invite_listen_error()
	lines.append("asr_first_not_decline=%s" % str(ok))

	_round_business.debug_reset_standalone_for_check()
	_invite_flow.debug_reset_flow()
	_round_business.debug_enter_invite_listen_for_check()
	_invite_flow.debug_begin_mock_listen_round()
	ok = ok and await _wait_invite_phase("LISTENING", 3.0)
	await get_tree().process_frame
	_invite_flow.debug_simulate_asr_failed("websocket_closed")
	await get_tree().process_frame
	ok = ok and _invite_flow.debug_unknown_retry_count() == 1
	_invite_flow.debug_jump_to_next_listen_round()
	ok = ok and await _wait_invite_phase("LISTENING", 3.0)
	await get_tree().process_frame
	_invite_flow.debug_simulate_asr_failed("connect_timeout")
	await get_tree().process_frame
	ok = ok and _invite_flow.committed_intent() == "ERROR"
	ok = ok and not _round_business.explain().contains("暂不玩")
	lines.append("asr_second_error_not_decline=%s" % str(ok))

	lines.append("=== minigame_invite_phase_c_check_pass=%s ===" % str(ok))
	print("\n".join(lines))
	get_tree().quit(0 if ok else 1)


func _run_minigame_invite_phase_d_check() -> void:
	var lines: PackedStringArray = []
	var ok := true
	set_auto_launch_minigame_on_play(true)
	_ensure_standalone_business()
	_invite_flow.debug_enable_mock_asr(true)
	for game_id in ["plane", "miner", "balloon"]:
		var scene_path := ClawMinigameCatalog.scene_path(game_id)
		var scene_ok := ResourceLoader.exists(scene_path)
		ok = ok and scene_ok
		lines.append("scene_exists %s=%s path=%s" % [game_id, str(scene_ok), scene_path])

	_round_business.debug_reset_standalone_for_check()
	_invite_flow.debug_reset_flow()
	_round_business.debug_enter_invite_listen_for_check()
	_invite_flow.debug_begin_mock_listen_round()
	ok = ok and await _wait_invite_phase("LISTENING", 3.0)
	_invite_flow.debug_inject_partial("好", true)
	ok = ok and _round_business.is_invite_play_accepted()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	ok = ok and _round_business.current_stage() == ClawBusinessNode.Stage.MINIGAME
	ok = ok and _round_business.launched_minigame_from_invite_play()
	ok = ok and _minigame_host != null and _minigame_host.covers_screen()
	ok = ok and _minigame_host.has_method("inner_game_loaded") and not _minigame_host.inner_game_loaded()
	ok = ok and _minigame_host.is_draw_flow_active()
	lines.append("play_opens_draw_not_inner=%s phase=%s" % [
		str(ok), _minigame_host.draw_phase_name() if _minigame_host != null else "?",
	])

	if _minigame_host.has_method("debug_wait_spin_finished"):
		ok = ok and await _minigame_host.debug_wait_spin_finished(6.0)
	await get_tree().process_frame
	var drawn: String = str(_minigame_host.drawn_game_id())
	var expected_scene: String = ClawMinigameCatalog.scene_path(drawn)
	ok = ok and ClawMinigameCatalog.is_playable(drawn)
	ok = ok and _minigame_host.draw_phase_name() == "PLAY"
	ok = ok and _minigame_host.inner_game_loaded()
	ok = ok and _minigame_host.debug_inner_launch_count() == 1
	var inner := _minigame_host.get_node_or_null("PlayLayer/Minigame_%s" % drawn)
	if inner == null:
		inner = _minigame_host.get_node_or_null("Minigame_%s" % drawn)
	ok = ok and inner != null and inner.scene_file_path == expected_scene
	lines.append("spin_auto_loads_game=%s drawn=%s launches=%s" % [
		str(ok), drawn, str(_minigame_host.debug_inner_launch_count()),
	])

	_minigame_host.debug_replay_spin_finished("miner")
	await get_tree().process_frame
	ok = ok and _minigame_host.debug_inner_launch_count() == 1
	lines.append("duplicate_spin_ignored=%s" % str(_minigame_host.debug_inner_launch_count() == 1))

	var dup_launch: Dictionary = _round_business.begin_minigame_after_invite_play()
	ok = ok and dup_launch.get("ok", true) == false
	lines.append("no_double_launch=%s" % str(dup_launch.get("ok", true) == false))

	var grab_while_game: Dictionary = _round_business.submit(ClawBusinessNode.GRAB_PRESSED)
	ok = ok and grab_while_game.get("ok", true) == false
	lines.append("grab_blocked_in_minigame=%s" % str(grab_while_game.get("ok", true) == false))

	if _minigame_port != null:
		_minigame_port.notify_finished(false)
	await get_tree().process_frame
	ok = ok and _round_business.stage_name() == "待机"
	ok = ok and not (_minigame_host != null and _minigame_host.covers_screen())
	lines.append("minigame_return_standby=%s" % str(ok))

	_round_business.debug_reset_standalone_for_check()
	_invite_flow.debug_reset_flow()
	_round_business.debug_enter_invite_listen_for_check()
	_invite_flow.debug_begin_mock_listen_round()
	ok = ok and await _wait_invite_phase("LISTENING", 3.0)
	_invite_flow.debug_inject_partial("嗯", true)
	await get_tree().process_frame
	_invite_flow.debug_simulate_listen_timeout()
	await get_tree().process_frame
	_invite_flow.debug_jump_to_next_listen_round()
	ok = ok and await _wait_invite_phase("LISTENING", 3.0)
	_invite_flow.debug_simulate_listen_timeout()
	await get_tree().process_frame
	ok = ok and _invite_flow.committed_intent() == "ERROR"
	ok = ok and _invite_flow.commit_reason() == "unknown_twice"
	ok = ok and _round_business.current_stage() != ClawBusinessNode.Stage.MINIGAME
	ok = ok and _round_business.stage_name() == "待机"
	ok = ok and not _round_business.is_fail_hold()
	lines.append("unknown_twice_listen_error=%s reason=%s" % [str(ok), _invite_flow.commit_reason()])

	lines.append("=== minigame_invite_phase_d_check_pass=%s ===" % str(ok))
	print("\n".join(lines))
	get_tree().quit(0 if ok else 1)


func _run_minigame_invite_halt_sync_check() -> void:
	if _invite_flow == null or _round_business == null:
		_abort_minigame_invite_check("halt_sync 缺少 invite/business 节点")
		return
	var lines: PackedStringArray = []
	var ok := true
	set_auto_launch_minigame_on_play(false)
	_ensure_standalone_business()
	_invite_flow.debug_enable_mock_asr(true)

	_round_business.debug_reset_standalone_for_check()
	_invite_flow.debug_reset_flow()
	_round_business.debug_enter_invite_listen_for_check()
	_invite_flow.debug_begin_mock_listen_round()
	ok = ok and await _wait_invite_phase("LISTENING", 3.0)
	ok = ok and _round_business.is_invite_listen()
	var snap_before := _invite_flow.debug_snapshot()
	ok = ok and bool(snap_before.get("mic_active", false))
	halt_stale_invite_for_show()
	await get_tree().process_frame
	var snap_after := _invite_flow.debug_snapshot()
	ok = ok and _invite_flow.phase_name() == "IDLE"
	ok = ok and not bool(snap_after.get("mic_active", false))
	ok = ok and not _round_business.is_invite_listen()
	ok = ok and _round_business.stage_name() == "待机"
	ok = ok and not _round_business.is_fail_continue_guide()
	ok = ok and not _round_business.is_fail_hold()
	var session_at_halt := int(snap_before.get("session", -1))
	_invite_flow.debug_inject_partial("玩", true)
	await get_tree().process_frame
	ok = ok and not _round_business.is_invite_play_accepted()
	ok = ok and _invite_flow.committed_intent() == ""
	lines.append("halt_sync=%s session=%d" % [str(ok), session_at_halt])

	_round_business.debug_reset_standalone_for_check()
	_invite_flow.debug_reset_flow()
	_round_business.debug_enter_invite_listen_for_check()
	_invite_flow.debug_begin_mock_listen_round()
	ok = ok and await _wait_invite_phase("LISTENING", 3.0)
	_invite_flow.debug_inject_partial("不要了", true)
	var decline_waited := 0.0
	while decline_waited < 40.0 and not _round_business.is_fail_hold():
		await get_tree().process_frame
		decline_waited += get_process_delta_time()
	ok = ok and _round_business.is_fail_hold()
	ok = ok and _round_business.result_phase() == "fail_hold"
	lines.append("decline_still_ok=%s" % str(_round_business.is_fail_hold()))

	_round_business.debug_reset_standalone_for_check()
	_invite_flow.debug_reset_flow()
	_round_business.debug_enter_invite_listen_for_check()
	_invite_flow.debug_begin_mock_listen_round()
	ok = ok and await _wait_invite_phase("LISTENING", 3.0)
	_invite_flow.debug_simulate_listen_timeout()
	await get_tree().process_frame
	_invite_flow.debug_jump_to_next_listen_round()
	ok = ok and await _wait_invite_phase("LISTENING", 3.0)
	_invite_flow.debug_simulate_listen_timeout()
	await get_tree().process_frame
	ok = ok and _invite_flow.committed_intent() == "ERROR"
	ok = ok and _round_business.stage_name() == "待机"
	lines.append("unknown_twice_still_ok=%s" % str(_invite_flow.committed_intent() == "ERROR"))

	_round_business.debug_reset_standalone_for_check()
	_invite_flow.debug_reset_flow()
	_round_business.debug_enter_invite_listen_for_check()
	_invite_flow.debug_begin_mock_listen_round()
	ok = ok and await _wait_invite_phase("LISTENING", 3.0)
	_invite_flow.debug_inject_partial("好", true)
	await get_tree().process_frame
	ok = ok and _round_business.is_invite_play_accepted()
	lines.append("play_accept_still_ok=%s" % str(_round_business.is_invite_play_accepted()))

	lines.append("=== minigame_invite_halt_sync_check_pass=%s ===" % str(ok))
	print("\n".join(lines))
	get_tree().quit(0 if ok else 1)


func _wait_invite_phase(name: String, sec: float) -> bool:
	var waited := 0.0
	while waited < sec and _invite_flow.phase_name() != name:
		await get_tree().process_frame
		waited += get_process_delta_time()
	return _invite_flow.phase_name() == name
