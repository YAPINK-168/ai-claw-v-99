extends Node
class_name PreviewAiVoiceBridge

## 正式场景投币前 AI：协调 AiPerformanceCoordinator、交互窗口与 Precoin（时长见 WINDOW_SECONDS）。

const AiPerformanceCoordinatorScript := preload("res://Scripts/voice/ai_performance_coordinator.gd")
const VoiceInteractionControllerScript := preload("res://Scripts/voice/voice_interaction_controller.gd")
const SpeechInputScript := preload("res://Scripts/voice/speech_input.gd")
const VoiceOutputScript := preload("res://Scripts/voice/voice_output.gd")
const VisemeProceduralDriverScript := preload("res://Scripts/voice/viseme_procedural_driver.gd")
const AliyunNlsConfigScript := preload("res://Scripts/voice/aliyun_nls_config.gd")
const NlsTokenProviderScript := preload("res://Scripts/voice/nls_token_provider.gd")
const MoonshotLlmClientScript := preload("res://Scripts/voice/moonshot_llm_client.gd")
const YouyouDialogueClientScript := preload("res://Scripts/voice/youyou_dialogue_client.gd")
const BailianTtsConfigScript := preload("res://Scripts/voice/bailian_tts_config.gd")
const YouyouVoiceSecretsScript := preload("res://Scripts/voice/youyou_voice_secrets.gd")
const VoiceTurnLatencyScript := preload("res://Scripts/voice/voice_turn_latency.gd")
const PreviewVadEventLog := preload("res://Scripts/voice/preview_vad_event_log.gd")
const VoicePipelineFeatureFlagsScript := preload("res://Scripts/voice/voice_pipeline_feature_flags.gd")
const VoicePipelineBaselineStatsScript := preload("res://Scripts/voice/voice_pipeline_baseline_stats.gd")
const InviteStreamingAsrScript := preload("res://Scripts/voice/invite_streaming_asr.gd")
const FormalStreamingAsrControllerScript := preload("res://Scripts/voice/formal_streaming_asr_controller.gd")

const CAPTURE_BUS := "PreviewAiVoiceRecord"
const WINDOW_SECONDS := 45.0

signal interaction_window_closed(reason: String, resume_attract: bool)

var _host: Node
var _coord: AiPerformanceCoordinatorScript
var _voice: VoiceInteractionControllerScript
var _voice_output: VoiceOutputScript
var _preempt_count := 0
var _window_armed := false
var _window_deadline_msec := 0
var _last_close_reason := ""
var _window_seconds := WINDOW_SECONDS
var _closing := false
var _latency: VoiceTurnLatencyScript
var _moonshot: MoonshotLlmClientScript
var _feature_flags: VoicePipelineFeatureFlagsScript
var _formal_stream_ctrl: FormalStreamingAsrControllerScript


func setup(host: Node) -> void:
	_host = host
	if _host == null:
		return
	_feature_flags = VoicePipelineFeatureFlagsScript.load_current()
	_emit_debug("voice_flags", _feature_flags.status_line())
	if _feature_flags.stream_llm or _feature_flags.new_window_policy:
		push_warning(
			"PreviewAiVoiceBridge: 以下实验开关尚未接入，已忽略 — %s"
			% _feature_flags.status_line()
		)
	if _feature_flags.stream_tts:
		_emit_debug("voice_flags", "stream_tts=on (WebSocket PCM)")
	if _feature_flags.stream_asr:
		_emit_debug("voice_flags", "stream_asr=on (NLS WebSocket，REST 回退仍保留)")
	_build_voice_stack()
	_coord = AiPerformanceCoordinatorScript.new()
	_coord.name = "AiPerformanceCoordinator"
	_coord.precoin_attract_mode = true
	add_child(_coord)
	_coord.setup(_host, _voice, _speech, _viseme, CAPTURE_BUS)
	_latency = VoiceTurnLatencyScript.new()
	_latency.enabled = true
	_coord.set_latency_tracker(_latency)
	if _formal_stream_ctrl != null:
		_coord.configure_stream_asr(_feature_flags.stream_asr, _formal_stream_ctrl)
	if _voice != null:
		_voice.moonshot_client = _moonshot
		_voice.bind_latency_tracker(_latency)
	if _voice_output != null:
		_voice_output.set_playback_started_hook(_coord.notify_tts_playback_started)
	if not _coord.debug_event.is_connected(_on_coord_debug):
		_coord.debug_event.connect(_on_coord_debug)


func get_coordinator() -> AiPerformanceCoordinatorScript:
	return _coord


func get_voice_controller() -> VoiceInteractionControllerScript:
	return _voice


func get_voice_output() -> VoiceOutput:
	return _voice_output


func holds_precoin_schedule() -> bool:
	return _coord != null and _coord.holds_precoin_schedule()


func is_window_armed() -> bool:
	return _window_armed


func is_session_active() -> bool:
	return _coord != null and _coord.is_session_active()


func get_last_close_reason() -> String:
	return _last_close_reason


func bump_window_for_activity() -> void:
	if not _window_armed:
		return
	_window_deadline_msec = Time.get_ticks_msec() + int(_window_seconds * 1000.0)


func get_window_remaining_sec() -> float:
	if not _window_armed:
		return 0.0
	var left := (_window_deadline_msec - Time.get_ticks_msec()) / 1000.0
	return maxf(left, 0.0)


func debug_set_window_seconds(seconds: float) -> void:
	_window_seconds = maxf(seconds, 0.5)


func debug_enable_mock_asr(text: String = "你好") -> void:
	if _coord != null:
		_coord.debug_enable_mock_asr(text)


func debug_trigger_mock_utterance() -> void:
	if _coord != null:
		_coord.debug_trigger_mock_utterance()


func debug_preempt_count() -> int:
	return _preempt_count


func open_interaction_window() -> void:
	if _coord == null or _host == null:
		return
	if _window_armed and _coord.is_session_active():
		return
	if not _host.call("preview_ai_may_continuous_listen"):
		return
	_window_armed = true
	_last_close_reason = ""
	_window_deadline_msec = Time.get_ticks_msec() + int(_window_seconds * 1000.0)
	_coord.precoin_attract_mode = true
	_coord.start_session()
	set_process(true)
	_kick_nls_token_warmup()


func request_preempt(reason: String, resume_attract: bool = false) -> void:
	if not _window_armed and (_coord == null or not _coord.is_session_active()):
		return
	_preempt_count += 1
	VoicePipelineBaselineStatsScript.record_preempt(reason)
	call_deferred("_close_async", reason, resume_attract)


func try_open_session() -> void:
	open_interaction_window()


func try_reopen_after_business_release() -> void:
	pass


func get_latency_tracker() -> VoiceTurnLatencyScript:
	return _latency


func snapshot() -> Dictionary:
	if _coord != null:
		var snap: Dictionary = _coord.snapshot()
		var lat_line := VoiceTurnLatencyScript.get_last_abort_summary()
		if lat_line.is_empty():
			var hist := VoiceTurnLatencyScript.get_history()
			if not hist.is_empty():
				lat_line = VoiceTurnLatencyScript.static_format_metrics(hist[hist.size() - 1])
		var flags := _feature_flags.to_dictionary() if _feature_flags != null else {}
		return {
			"window_armed": _window_armed,
			"window_remaining_sec": get_window_remaining_sec(),
			"last_close_reason": _last_close_reason,
			"session_active": snap.get("session_active", false),
			"perf_state": snap.get("perf_state", ""),
			"voice_state": snap.get("voice_state", ""),
			"session_gen": snap.get("session_gen", 0),
			"capture_listening": snap.get("capture_listening", false),
			"vad_last_brief": PreviewVadEventLog.format_last_brief(),
			"latency_last_line": lat_line,
			"preempt_count": _preempt_count,
			"feature_flags": flags,
			"baseline_stats": VoicePipelineBaselineStatsScript.snapshot(),
		}
	return {
		"window_armed": _window_armed,
		"window_remaining_sec": get_window_remaining_sec(),
		"last_close_reason": _last_close_reason,
	}


func _process(_delta: float) -> void:
	if not _window_armed:
		set_process(false)
		return
	if Time.get_ticks_msec() >= _window_deadline_msec:
		request_preempt("window_timeout", true)


func _close_async(reason: String, resume_attract: bool) -> void:
	if _closing:
		return
	_closing = true
	_window_armed = false
	set_process(false)
	_window_deadline_msec = 0
	_last_close_reason = reason
	if _coord != null:
		await _coord.stop_session(reason)
	interaction_window_closed.emit(reason, resume_attract)
	if _host != null and _host.has_method("preview_ai_on_window_closed"):
		_host.preview_ai_on_window_closed(reason, resume_attract)
	_closing = false


func _on_coord_debug(tag: String, detail: String) -> void:
	_emit_debug(tag, detail)


func _formal_stream_asr_log_line(line: String) -> void:
	print(line)


func _emit_debug(tag: String, detail: String) -> void:
	if _host != null and _host.has_method("preview_ai_on_coord_debug"):
		_host.preview_ai_on_coord_debug(tag, detail)


## 开窗后后台预热 NLS Token；不 await，不阻塞 session / 监听 / 招揽。
func _kick_nls_token_warmup() -> void:
	if _nls_tokens == null:
		return
	_run_nls_token_warmup_async()


func _run_nls_token_warmup_async() -> void:
	var ok: bool = await _nls_tokens.warmup()
	if ok:
		_emit_debug("nls_token", "warmup_ok")
	else:
		push_warning("PreviewAiVoiceBridge: NLS token 预热未成功，后续 ASR 仍会按原逻辑 get_token")
		_emit_debug("nls_token", "warmup_failed")


func _build_voice_stack() -> void:
	if _voice != null:
		return
	var services := Node.new()
	services.name = "PreviewAiVoiceServices"
	add_child(services)
	var nls := AliyunNlsConfigScript.new()
	services.add_child(nls)
	var tokens := NlsTokenProviderScript.new()
	tokens.setup(nls)
	services.add_child(tokens)
	_nls_tokens = tokens
	_speech = SpeechInputScript.new()
	_speech.name = "SpeechInput"
	_speech.setup(nls, tokens)
	services.add_child(_speech)
	var stream_asr := InviteStreamingAsrScript.new()
	stream_asr.name = "FormalStreamingAsr"
	services.add_child(stream_asr)
	var formal_asr_log := Callable(self, "_formal_stream_asr_log_line")
	stream_asr.setup(nls, tokens, formal_asr_log)
	_formal_stream_ctrl = FormalStreamingAsrControllerScript.new()
	_formal_stream_ctrl.name = "FormalStreamingAsrController"
	services.add_child(_formal_stream_ctrl)
	_formal_stream_ctrl.setup(stream_asr, _speech)
	_formal_stream_ctrl.set_log_fn(formal_asr_log)
	_moonshot = MoonshotLlmClientScript.new()
	services.add_child(_moonshot)
	var moon := _moonshot
	var dialogue := YouyouDialogueClientScript.new()
	dialogue.setup(moon)
	services.add_child(dialogue)
	var bailian := BailianTtsConfigScript.new()
	bailian.apply_fixed_defaults()
	YouyouVoiceSecretsScript.load_into(nls, moon, bailian)
	var tts_player := AudioStreamPlayer.new()
	tts_player.name = "PreviewTtsAudioPlayer"
	tts_player.volume_db = preload("res://Scripts/audio/claw_scene_audio.gd").VOICE_VOLUME_DB
	add_child(tts_player)
	_voice_output = VoiceOutputScript.new()
	_voice_output.setup(nls, tokens, tts_player, bailian)
	_voice_output.set_stream_tts_enabled(_feature_flags.stream_tts)
	services.add_child(_voice_output)
	_viseme = VisemeProceduralDriverScript.new()
	_viseme.name = "PreviewAiViseme"
	add_child(_viseme)
	var face = null
	if _host != null and _host.has_method("get_face_presenter"):
		face = _host.get_face_presenter()
	if face != null:
		_viseme.setup(face, tts_player)
	_voice = VoiceInteractionControllerScript.new()
	_voice.setup(_speech, dialogue, _voice_output, face, _viseme)
	_voice.manage_viseme = false
	add_child(_voice)


var _speech: SpeechInputScript
var _viseme: VisemeProceduralDriverScript
var _nls_tokens: NlsTokenProviderScript
