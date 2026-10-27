extends Node
class_name YouyouFormalVoiceOrchestrator

## 正式场景投币前 AI：持续监听 + 动作/口型协调，不接管 ClawBusiness。

const ContinuousCapture := preload("res://Scripts/voice/continuous_utterance_capture.gd")
const VoiceInteractionControllerScript := preload("res://Scripts/voice/voice_interaction_controller.gd")
const SpeechInputScript := preload("res://Scripts/voice/speech_input.gd")
const VisemeProceduralDriverScript := preload("res://Scripts/voice/viseme_procedural_driver.gd")

enum Phase {
	CLOSED,
	OPEN_ATTRACT,
	USER_SPEAKING,
	USER_PROCESSING,
	AI_SPEAKING,
}

signal phase_changed(old_phase: Phase, new_phase: Phase)

const SPEAK_ANIM := "youyou_Speak_Idle05"

var _host: Node
var _voice: VoiceInteractionControllerScript
var _speech: SpeechInputScript
var _capture: ContinuousUtteranceCapture
var _viseme: VisemeProceduralDriverScript
var _tts_player: AudioStreamPlayer

var _phase := Phase.CLOSED
var _window_gen := 0
var _utterance_busy := false
var _mock_asr_text := ""
var _mock_asr_enabled := false
var _preempted := false


func setup(
	host: Node,
	voice: VoiceInteractionControllerScript,
	speech: SpeechInputScript,
	viseme: VisemeProceduralDriverScript,
	tts_player: AudioStreamPlayer,
) -> void:
	_host = host
	_voice = voice
	_speech = speech
	_viseme = viseme
	_tts_player = tts_player
	_capture = ContinuousCapture.new()
	_capture.name = "FormalContinuousCapture"
	add_child(_capture)
	_capture.speech_started.connect(_on_speech_started)
	_capture.speech_ended.connect(_on_speech_ended)
	_capture.utterance_rejected.connect(_on_utterance_rejected)
	if _voice != null:
		if not _voice.state_changed.is_connected(_on_voice_state_changed):
			_voice.state_changed.connect(_on_voice_state_changed)
		if not _voice.turn_finished.is_connected(_on_voice_turn_finished):
			_voice.turn_finished.connect(_on_voice_turn_finished)


func get_phase() -> Phase:
	return _phase


func get_phase_name() -> String:
	return Phase.keys()[_phase]


func is_window_open() -> bool:
	return _phase != Phase.CLOSED


func holds_precoin_schedule() -> bool:
	return _phase in [Phase.USER_SPEAKING, Phase.USER_PROCESSING, Phase.AI_SPEAKING]


func open_window() -> void:
	if _phase != Phase.CLOSED:
		return
	if not _can_run_formal_voice():
		return
	_preempted = false
	_window_gen += 1
	_set_phase(Phase.OPEN_ATTRACT)
	_capture.mock_mode = _mock_asr_enabled
	_capture.start_capture()


func close_window(reason: String = "close") -> void:
	if _phase == Phase.CLOSED:
		return
	_window_gen += 1
	_utterance_busy = false
	_capture.stop_capture()
	_stop_ai_viseme_and_speak_pose()
	if _voice != null and _voice.is_busy():
		await _voice.cancel_turn()
	_set_phase(Phase.CLOSED)
	if _host != null and _host.has_method("formal_voice_log"):
		_host.formal_voice_log("窗口关闭 reason=%s" % reason)


func preempt(reason: String) -> void:
	if _phase == Phase.CLOSED:
		return
	_preempted = true
	var gen := _window_gen
	_capture.stop_capture()
	_stop_ai_viseme_and_speak_pose()
	if _voice != null:
		await _voice.cancel_turn()
	if gen != _window_gen:
		return
	_set_phase(Phase.CLOSED)
	if _host != null and _host.has_method("formal_voice_log"):
		_host.formal_voice_log("业务抢占 reason=%s gen=%d" % [reason, gen])


func debug_enable_mock_asr(text: String) -> void:
	_mock_asr_enabled = true
	_mock_asr_text = text
	if _capture != null:
		_capture.mock_mode = true


func debug_trigger_mock_utterance() -> void:
	if _capture != null:
		_capture.debug_emit_mock_utterance()


func debug_snapshot() -> Dictionary:
	return {
		"phase": get_phase_name(),
		"window_open": is_window_open(),
		"utterance_busy": _utterance_busy,
		"voice_state": _voice.get_state_name() if _voice != null else "",
		"preempted": _preempted,
	}


func _can_run_formal_voice() -> bool:
	if _host == null or _voice == null or _speech == null:
		return false
	if _host.has_method("formal_voice_blocked_by_business") and _host.formal_voice_blocked_by_business():
		return false
	return true


func _set_phase(next: Phase) -> void:
	if _phase == next:
		return
	var old := _phase
	_phase = next
	phase_changed.emit(old, next)
	match next:
		Phase.OPEN_ATTRACT:
			_capture.set_paused(false)
		Phase.USER_SPEAKING, Phase.USER_PROCESSING, Phase.AI_SPEAKING:
			_capture.set_paused(true)


func _on_speech_started() -> void:
	if _phase != Phase.OPEN_ATTRACT or _utterance_busy or _preempted:
		return
	if _voice != null and _voice.is_busy():
		return
	_set_phase(Phase.USER_SPEAKING)
	if _host != null and _host.has_method("formal_voice_enter_listen_pose"):
		_host.formal_voice_enter_listen_pose()


func _on_utterance_rejected(_reason: String) -> void:
	if _phase == Phase.USER_SPEAKING:
		_set_phase(Phase.OPEN_ATTRACT)
		if _host != null and _host.has_method("formal_voice_resume_attract"):
			_host.formal_voice_resume_attract()


func _on_speech_ended(pcm: PackedByteArray, sample_rate: int) -> void:
	if _phase != Phase.USER_SPEAKING or _utterance_busy or _preempted:
		return
	_utterance_busy = true
	var win_gen := _window_gen
	_set_phase(Phase.USER_PROCESSING)
	var text := _mock_asr_text if _mock_asr_enabled else await _speech.recognize_pcm16(pcm, sample_rate)
	if win_gen != _window_gen or _preempted:
		_utterance_busy = false
		return
	if text.strip_edges().is_empty():
		_utterance_busy = false
		if _phase == Phase.USER_PROCESSING:
			_set_phase(Phase.OPEN_ATTRACT)
			if _host != null and _host.has_method("formal_voice_resume_attract"):
				_host.formal_voice_resume_attract()
		return
	if _voice != null:
		await _voice.submit_text(text)
	_utterance_busy = false


func _on_voice_state_changed(_old: int, new_state: int) -> void:
	if _phase == Phase.CLOSED or _preempted:
		return
	var win_gen := _window_gen
	match new_state:
		VoiceInteractionControllerScript.State.THINKING, VoiceInteractionControllerScript.State.RECOGNIZING:
			if _phase == Phase.USER_SPEAKING:
				_set_phase(Phase.USER_PROCESSING)
		VoiceInteractionControllerScript.State.SYNTHESIZING:
			_set_phase(Phase.USER_PROCESSING)
		VoiceInteractionControllerScript.State.SPEAKING:
			if win_gen != _window_gen:
				return
			_on_ai_playback_started()
		VoiceInteractionControllerScript.State.IDLE, VoiceInteractionControllerScript.State.ERROR:
			if _phase == Phase.AI_SPEAKING or _phase == Phase.USER_PROCESSING:
				pass


func _on_ai_playback_started() -> void:
	if _phase == Phase.CLOSED or _preempted:
		return
	_set_phase(Phase.AI_SPEAKING)
	if _host != null and _host.has_method("formal_voice_enter_speak_pose"):
		_host.formal_voice_enter_speak_pose()
	if _viseme != null:
		_viseme.start()


func notify_ai_playback_started() -> void:
	if _voice == null:
		return
	_voice.notify_tts_playback_started()
	if _voice.get_state() == VoiceInteractionControllerScript.State.SPEAKING:
		_on_ai_playback_started()


func _on_voice_turn_finished(reason: String) -> void:
	if _phase == Phase.CLOSED or _preempted:
		return
	var win_gen := _window_gen
	_stop_ai_viseme_and_speak_pose()
	if win_gen != _window_gen:
		return
	if not is_window_open():
		return
	_set_phase(Phase.OPEN_ATTRACT)
	_capture.set_paused(false)
	if _host != null and _host.has_method("formal_voice_resume_attract"):
		_host.formal_voice_resume_attract()
	if _host != null and _host.has_method("formal_voice_log"):
		_host.formal_voice_log("轮次结束 reason=%s" % reason)


func _stop_ai_viseme_and_speak_pose() -> void:
	if _viseme != null:
		_viseme.stop()
	if _host != null and _host.has_method("formal_voice_leave_speak_pose"):
		_host.formal_voice_leave_speak_pose()
