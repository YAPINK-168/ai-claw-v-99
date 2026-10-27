extends RefCounted
class_name PreviewAiVoicePlayerStatus

## 正式场景玩家可见 AI 语音状态（单条提示，generation 守卫）。

const PreviewVadEventLog := preload("res://Scripts/voice/preview_vad_event_log.gd")

const MSG_WAIT := "柚柚正在等待与你互动..."
const MSG_VAD := "柚柚正在聆听你的声音..."
const MSG_ASR := "柚柚正在识别你说的话..."
const MSG_LLM := "柚柚正在思考..."
const MSG_TTS := "柚柚正在准备回答..."
const MSG_PLAYBACK := "柚柚正在和你说话..."
const MSG_ASR_EMPTY := "刚才没听清，我们再试一次吧！"
const MSG_PIPELINE_FAIL := "这次没成功，再试一次吧！"
const MSG_TIMEOUT := "这次聊得有点久啦，我们再聊吧！"

const _PHASE_RANK: Dictionary = {
	"hidden": -1,
	"wait_listen": 0,
	"vad_listen": 10,
	"asr": 20,
	"llm_think": 30,
	"tts_prep": 40,
	"playback": 50,
	"feedback": 100,
}

var _label: Label
var _host: Node
var _session_gen := -1
var _phase_rank := -1
var _clear_timer: SceneTreeTimer


func bind(host: Node, label: Label) -> void:
	_host = host
	_label = label
	_hide()


func handle(event: String, ctx: Dictionary) -> void:
	if _label == null:
		return
	if event == "session_closed":
		if bool(ctx.get("silent", true)):
			force_clear()
			_log_status("hidden", String(ctx.get("reason", "closed")), int(ctx.get("session_gen", -1)))
		return
	var gen := int(ctx.get("session_gen", -1))
	if not _accepts_generation(gen, event):
		return
	match event:
		"wait_listen":
			_session_gen = gen
			_show_phase("wait_listen", MSG_WAIT, "session_ready")
		"vad_listen":
			_show_phase("vad_listen", MSG_VAD, "vad_started")
		"asr":
			_show_phase("asr", MSG_ASR, "speech_ended")
		"llm_think":
			_show_phase("llm_think", MSG_LLM, "voice_thinking")
		"tts_prep":
			_show_phase("tts_prep", MSG_TTS, "voice_synthesizing")
		"playback":
			_show_phase("playback", MSG_PLAYBACK, "tts_playback_started")
		"asr_empty":
			_show_feedback(MSG_ASR_EMPTY, "asr_empty")
		"asr_failed", "pipeline_failed":
			_show_feedback(_pipeline_fail_text(ctx), String(ctx.get("fail_kind", event)))
		_:
			pass


func on_window_closed(reason: String) -> void:
	_cancel_clear_timer()
	_session_gen = -1
	_phase_rank = -1
	match reason:
		"window_timeout":
			_set_visible_text(MSG_TIMEOUT)
			_log_status("window_timeout", "timeout_feedback", -1)
			_schedule_clear(4.0)
		"player_left", "player_leave_debug":
			_hide()
			_log_status("session_closed", reason, -1)
		_:
			_hide()
			_log_status("session_closed", reason, -1)


func force_clear() -> void:
	_cancel_clear_timer()
	_session_gen = -1
	_phase_rank = -1
	_hide()


func current_message() -> String:
	if _label == null or not _label.visible:
		return ""
	return _label.text


func current_phase_rank() -> int:
	return _phase_rank


func _accepts_generation(gen: int, event: String) -> bool:
	if gen < 0:
		return false
	if _session_gen < 0:
		return event == "wait_listen"
	if gen != _session_gen:
		return false
	return true


func _show_phase(phase_id: String, text: String, log_reason: String) -> void:
	var rank := int(_PHASE_RANK.get(phase_id, 0))
	if rank < _phase_rank and phase_id != "wait_listen":
		return
	_cancel_clear_timer()
	_phase_rank = rank
	_set_visible_text(text)
	_log_status(phase_id, log_reason, _session_gen)


func _show_feedback(text: String, log_reason: String) -> void:
	_cancel_clear_timer()
	_phase_rank = int(_PHASE_RANK["feedback"])
	_set_visible_text(text)
	_log_status("feedback", log_reason, _session_gen)
	_schedule_clear(3.5)


func _pipeline_fail_text(ctx: Dictionary) -> String:
	var kind := String(ctx.get("fail_kind", ""))
	if kind == "llm":
		return MSG_PIPELINE_FAIL
	if kind == "tts":
		return MSG_PIPELINE_FAIL
	if kind == "asr":
		return MSG_PIPELINE_FAIL
	return MSG_PIPELINE_FAIL


func _set_visible_text(text: String) -> void:
	if _label == null:
		return
	_label.text = text
	_label.visible = not text.is_empty()


func _hide() -> void:
	if _label == null:
		return
	_label.text = ""
	_label.visible = false


func _schedule_clear(seconds: float) -> void:
	if _host == null or not _host.is_inside_tree():
		return
	_clear_timer = _host.get_tree().create_timer(seconds)
	_clear_timer.timeout.connect(_on_clear_timeout, CONNECT_ONE_SHOT)


func _cancel_clear_timer() -> void:
	_clear_timer = null


func _on_clear_timeout() -> void:
	_hide()
	_phase_rank = -1


func _log_status(phase: String, reason: String, session_gen: int) -> void:
	PreviewVadEventLog.push(
		"ai_voice_status",
		{"phase": phase, "reason": reason, "session_gen": session_gen},
	)
	print("ai_voice_status phase=%s reason=%s session_gen=%s" % [phase, reason, str(session_gen)])
