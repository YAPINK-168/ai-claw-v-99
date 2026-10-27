@tool
extends CanvasLayer
class_name YouyouLeftHud
## 在编辑器打开 scenes/ui/youyou_arcade_hud.tscn 调整 TopBanner / 投币数字 / 底部栏位置与大小，保存后运行即对齐。
## 设计分辨率 1920×1080（与 project.godot、claw_sprite_flow_test 一致）；勿在运行时改锚点。

const DESIGN_SIZE := Vector2i(1920, 1080)
const TEX_VOICE_OFF := "res://assets/youyou_ui/hud_voice_off.png"
const TEX_VOICE_ON := "res://assets/youyou_ui/hud_voice_on.png"

@onready var _goal_progress: Label = %GoalProgress
@onready var _coin_value: Label = %CoinValue
@onready var _dialogue: Label = %Dialogue
@onready var _dialogue_root: Control = %DialogueBubble
@onready var _voice_art: TextureRect = %VoiceArt
@onready var _voice_hint: Label = %VoiceHint

var _voice_live := false
var _dialogue_fade_gen := 0


func _ready() -> void:
	layer = 12
	if Engine.is_editor_hint():
		return
	set_round_goal("抓到1个娃娃", "0/1")
	set_coin_count(0)
	set_dialogue("")
	_set_voice_live(false)


func set_character_card(_title: String, _subtitle: String) -> void:
	pass


func set_round_goal(_text: String, progress: String = "") -> void:
	if _goal_progress == null:
		return
	var shown := progress.strip_edges()
	if shown == "":
		shown = "0/1"
	_goal_progress.text = shown


func set_coin_count(count: int) -> void:
	if _coin_value != null:
		_coin_value.text = str(maxi(count, 0))


func set_dialogue(text: String) -> void:
	if _dialogue == null:
		return
	var same := _dialogue.text == text
	_dialogue.text = text
	if _dialogue_root != null:
		_dialogue_root.visible = not text.strip_edges().is_empty()
	if same or not is_inside_tree() or text.strip_edges().is_empty():
		return
	_dialogue_fade_gen += 1
	var gen := _dialogue_fade_gen
	var col := _dialogue.modulate
	col.a = 0.0
	_dialogue.modulate = col
	var tw := create_tween()
	tw.tween_property(_dialogue, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.finished.connect(func() -> void:
		if gen != _dialogue_fade_gen:
			return
		var c := _dialogue.modulate
		c.a = 1.0
		_dialogue.modulate = c
	, CONNECT_ONE_SHOT)


func set_voice_hint(text: String) -> void:
	if _voice_hint != null:
		_voice_hint.text = text


func get_voice_status_label() -> Label:
	return _voice_hint


func bind_voice_ai_bridge(_bridge: PreviewAiVoiceBridge) -> void:
	pass


func apply_voice_status_event(event: String, ctx: Dictionary) -> void:
	match event:
		"wait_listen", "vad_listen", "asr", "llm_think", "tts_prep", "playback":
			_set_voice_live(true)
		"session_closed":
			_set_voice_live(not bool(ctx.get("silent", true)))
		_:
			pass


func set_voice_situation(mode: String, _remain_sec: float = -1.0) -> void:
	_set_voice_live(mode != "" and mode != "idle")


func _set_voice_live(on: bool) -> void:
	_voice_live = on
	if _voice_art == null:
		return
	## 左下角固定位：未开图1（语音未开启），已开图2（语音已开启）
	_voice_art.visible = true
	var path := TEX_VOICE_ON if on else TEX_VOICE_OFF
	var tex := load(path) as Texture2D
	if tex != null:
		_voice_art.texture = tex
