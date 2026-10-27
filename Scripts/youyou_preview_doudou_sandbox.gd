extends "res://Scripts/youyou_preview.gd"

## 正式 preview 的沙盒副本：首局 crane03 + 兜兜对表；续局 crane01、兜兜关闭。

const DoudouSideActor := preload("res://Scripts/doudou/doudou_side_actor.gd")
const DoudouSandboxLayout := preload("res://Scripts/doudou/doudou_sandbox_layout.gd")
const DoudouActDirector := preload("res://Scripts/doudou/doudou_sandbox_act_director.gd")
const YouyouEventCatalog := preload("res://Scripts/youyou_action_event_catalog.gd")
const YouyouSplitTimelines := preload("res://Scripts/youyou_action_split_expression_timelines.gd")

const SANDBOX_OPERATE_5_0 := "res://柚柚新动作/柚柚操作动作2.0/3.0/5.0/"
const SANDBOX_OPERATE_5_0_FILES: Dictionary = {
	"youyou_claw_crane02_01": "youyou_claw_crane02_01.glb",
	"youyou_claw_crane02_02": "youyou_claw_crane02_02.glb",
	"youyou_claw_crane02_03": "youyou_claw_crane02_03.glb",
	"youyou_claw_crane02_04": "youyou_claw_crane02_04(2).glb",
	"youyou_claw_crane02_05": "youyou_claw_crane02_05.glb",
	"youyou_claw_crane02_06": "youyou_claw_crane02_06(2).glb",
	"youyou_claw_crane02_07": "youyou_claw_crane02_07.glb",
}

var _doudou_side: DoudouSideActor
var _layout: DoudouSandboxLayout
var _act_director: DoudouSandboxActDirector
var _doudou_action_label: Label
var _doudou_action_hud_last := ""


func _ready() -> void:
	YouyouEventCatalog.reload_from_disk()
	YouyouSplitTimelines.reload()
	_patch_sandbox_operate_loop_glb()
	super._ready()
	_layout = get_node_or_null("EditorLayout") as DoudouSandboxLayout
	call_deferred("_hide_sandbox_ui")
	call_deferred("_ensure_sandbox_voice_hud")
	call_deferred("_setup_doudou_action_hud")
	call_deferred("_setup_doudou_side")
	call_deferred("_setup_act_director")


func _patch_sandbox_operate_loop_glb() -> void:
	for action_id in SANDBOX_OPERATE_5_0_FILES.keys():
		var scene_path := SANDBOX_OPERATE_5_0 + String(SANDBOX_OPERATE_5_0_FILES[action_id])
		YouyouEventCatalog.set_runtime_patch(
			String(action_id),
			{
				"scene": scene_path,
				"source_anim": String(action_id),
				"notes": "兜兜沙盒 · 操作动作 5.0",
			},
		)


func _hide_sandbox_ui() -> void:
	var layer := get_node_or_null("StatusLayer") as CanvasLayer
	if layer != null:
		layer.visible = false
		var help := layer.get_node_or_null("ObserveHelp") as Label
		if help != null:
			help.visible = false
	# 左侧四块 UI（角色卡 / 投币 / 目标 / 台词）保持显示
	if _right_hud != null:
		_right_hud.visible = false
	if _debug_panel != null:
		_debug_panel.visible = false
	if _status_label != null:
		_status_label.visible = false
	if _ai_player_prompt != null:
		_ai_player_prompt.visible = false


func _ensure_sandbox_voice_hud() -> void:
	if _left_hud == null or _ai_voice_bridge == null:
		return
	_left_hud.visible = true
	_left_hud.bind_voice_ai_bridge(_ai_voice_bridge)
	if _ai_player_status != null:
		var status_label := _left_hud.get_voice_status_label()
		if status_label != null:
			_ai_player_status.bind(self, status_label)


func _setup_doudou_action_hud() -> void:
	if _doudou_action_label != null:
		return
	var hud := CanvasLayer.new()
	hud.name = "DoudouActionHud"
	hud.layer = 12
	add_child(hud)
	_doudou_action_label = Label.new()
	_doudou_action_label.name = "DoudouActionLabel"
	_doudou_action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_doudou_action_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_doudou_action_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_doudou_action_label.offset_left = -480.0
	_doudou_action_label.offset_top = 14.0
	_doudou_action_label.offset_right = -16.0
	_doudou_action_label.offset_bottom = 52.0
	_doudou_action_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	_doudou_action_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.88))
	_doudou_action_label.add_theme_constant_override("shadow_offset_x", 1)
	_doudou_action_label.add_theme_constant_override("shadow_offset_y", 1)
	_doudou_action_label.add_theme_font_size_override("font_size", 20)
	_doudou_action_label.text = "兜兜动作：—"
	hud.add_child(_doudou_action_label)


func _process(delta: float) -> void:
	super._process(delta)
	_refresh_doudou_action_hud()


func _refresh_doudou_action_hud() -> void:
	if _doudou_action_label == null:
		return
	var action := "—"
	if _doudou_side != null and is_instance_valid(_doudou_side):
		action = _doudou_side.get_playback_action_label()
	var line := "兜兜动作：%s" % action
	if line == _doudou_action_hud_last:
		return
	_doudou_action_hud_last = line
	_doudou_action_label.text = line


func _apply_editor_layout_to_youyou() -> void:
	if _layout == null or _model == null:
		return
	var slot := _layout.get_youyou_slot()
	if slot != null:
		_model.global_transform = slot.global_transform
	_layout.hide_editor_previews()


func _setup_doudou_side() -> void:
	if _model == null or not is_instance_valid(_model):
		call_deferred("_setup_doudou_side")
		return
	_apply_editor_layout_to_youyou()
	if _doudou_side != null and is_instance_valid(_doudou_side):
		return
	_doudou_side = DoudouSideActor.new()
	_doudou_side.name = "DoudouSideActor"
	add_child(_doudou_side)
	var doudou_slot := _find_doudou_slot()
	if doudou_slot != null:
		_doudou_side.setup_from_slot(doudou_slot, _model)
	else:
		push_warning("沙盒未找到 EditorLayout/DoudouSlot，兜兜使用柚柚旁默认偏移")
		_doudou_side.setup(_model)


func _find_doudou_slot() -> Node3D:
	if _layout != null:
		var slotted := _layout.get_doudou_slot()
		if slotted != null:
			return slotted
	var layout := get_node_or_null("EditorLayout")
	if layout == null:
		return null
	return layout.get_node_or_null("DoudouSlot") as Node3D


func _setup_act_director() -> void:
	if _act_director != null or _doudou_side == null or _grab_flow == null or _event_perf == null:
		if _doudou_side == null or _grab_flow == null:
			call_deferred("_setup_act_director")
		return
	_act_director = DoudouActDirector.new()
	_act_director.name = "DoudouActDirector"
	add_child(_act_director)
	_act_director.setup(self, _doudou_side, _grab_flow, _event_perf, _face)


func on_coin_welcome_finished() -> void:
	var first_in_session := (
		_round_business != null and _round_business.is_session_first_coin_welcome()
	)
	if _grab_flow != null:
		_grab_flow.set_crane03_profile(first_in_session)
	if _act_director != null:
		if first_in_session:
			_act_director.begin_first_round_after_welcome()
		else:
			_act_director.begin_followup_round()
	super.on_coin_welcome_finished()
	if not first_in_session:
		call_deferred("_apply_sandbox_operate_wasd_look")


func begin_operate_hold() -> void:
	if _grab_flow != null and _grab_flow.is_scripted_body_locked():
		return
	super.begin_operate_hold()
	_apply_sandbox_operate_wasd_look()


func enter_claw_watch_keeping_speech() -> void:
	if _grab_flow != null and _grab_flow.is_scripted_body_locked():
		return
	super.enter_claw_watch_keeping_speech()
	_apply_sandbox_operate_wasd_look()


func _sync_idle_presence() -> void:
	if _grab_flow != null and _grab_flow.is_scripted_body_locked() and _idle_life != null:
		_idle_life.set_process(true)
		_idle_life.call("set_blink_channel", true)
		_idle_life.call("set_manual_input_enabled", false)
		_idle_life.call("set_gaze_channel", false)
		_idle_life.call("set_head_channel", false)
		return
	super._sync_idle_presence()


func _apply_sandbox_operate_wasd_look() -> void:
	if _grab_flow == null:
		return
	if _grab_flow.is_scripted_body_locked():
		_sync_idle_presence()
		return
	# 回到 02/05 维持站立后，才与 preview 一样用 WASD 转头转眼。
	_grab_flow.set_operate_look_enabled(true)
	if _grab_flow.has_method("refresh_operate_stick_look"):
		_grab_flow.refresh_operate_stick_look()
	_sync_idle_presence()


func _play_grab_down() -> void:
	super._play_grab_down()
	if _doudou_side != null:
		_doudou_side.notify_grab_down()


func submit_simulated_grab_result(success: bool) -> void:
	if _doudou_side != null and _doudou_side.responds_to_grab_result():
		_doudou_side.notify_grab_result(success)
	super.submit_simulated_grab_result(success)


func _reset_youyou_for_retest() -> void:
	super._reset_youyou_for_retest()
	if _grab_flow != null:
		_grab_flow.set_crane03_profile(false)
	if _act_director != null:
		_act_director.begin_followup_round()
	if _doudou_side != null:
		_doudou_side.reset_to_layout_slot()
	_doudou_action_hud_last = ""
	_refresh_doudou_action_hud()
