extends Node
class_name YouyouMinigameInviteFlow

## 失败后小游戏引导：Speak 表现 + 流式 ASR 意愿识别（阶段 B）。

const SPEAK_ACTION := "youyou_Speak_Idle05"
const GUIDE_AUDIO := "res://配音/失败引导小游戏2.mp3"

const InviteListenConfig := preload("res://Scripts/voice/invite_listen_config.gd")
const MinigameIntentRules := preload("res://Scripts/voice/minigame_intent_rules.gd")
const InviteStreamingAsr := preload("res://Scripts/voice/invite_streaming_asr.gd")
const InviteMicCapture := preload("res://Scripts/voice/invite_mic_capture.gd")
const AliyunNlsConfig := preload("res://Scripts/voice/aliyun_nls_config.gd")
const NlsTokenProvider := preload("res://Scripts/voice/nls_token_provider.gd")
const YouyouVoiceSecrets := preload("res://Scripts/voice/youyou_voice_secrets.gd")
const MoonshotLlmClient := preload("res://Scripts/voice/moonshot_llm_client.gd")
const BailianTtsConfig := preload("res://Scripts/voice/bailian_tts_config.gd")

enum Phase { IDLE, PLAYING, WAITING_ANSWER, LISTENING, COMMITTED, CANCELLED }

var mock_asr := false

var _host: Node
var _event: Node
var _adapter: Node
var _player: Node
var _phase := Phase.IDLE
var _business_token := -1
var _expect_token := -1
var _invite_session_id := 0
var _listen_gen := 0
var _listen_epoch := 0
var _asr_fail_ignore_until_ms := 0
var _cancelled := false
var _mic_active := false
var _stream_open := false
var _pcm_pending: Array = []
var _guide_audio_armed := false
var _unknown_retries := 0
var _committed_intent := ""
var _commit_reason := ""
var _stable_intent := ""
var _stable_since_ms := 0
var _speech_started_ms := 0
var _listen_started_ms := 0
var _timings: Dictionary = {}
var _suppress_asr_failure := false

var _asr: InviteStreamingAsr
var _mic: InviteMicCapture
var _nls: AliyunNlsConfig
var _tokens: NlsTokenProvider


func setup(host: Node, event_performance: Node = null, adapter: Node = null, player: Node = null) -> void:
	_host = host
	_event = event_performance
	_adapter = adapter
	_player = player
	process_priority = 88
	_nls = AliyunNlsConfig.new()
	_nls.name = "InviteNlsConfig"
	add_child(_nls)
	_tokens = NlsTokenProvider.new()
	_tokens.name = "InviteNlsTokens"
	add_child(_tokens)
	_tokens.setup(_nls)
	var moon := MoonshotLlmClient.new()
	var bailian := BailianTtsConfig.new()
	var cfg_msg := YouyouVoiceSecrets.load_into(_nls, moon, bailian)
	if not cfg_msg.is_empty():
		_log(cfg_msg)
	moon.queue_free()
	_asr = InviteStreamingAsr.new()
	_asr.name = "InviteStreamingAsr"
	add_child(_asr)
	_asr.setup(_nls, _tokens, Callable(self, "_asr_log"))
	_mic = InviteMicCapture.new()
	_mic.name = "InviteMicCapture"
	add_child(_mic)
	_mic.pcm_chunk.connect(_on_pcm_chunk)
	_mic.speech_started.connect(_on_speech_started)
	_asr.partial_text.connect(_on_partial)
	_asr.sentence_end.connect(_on_sentence_end)
	_asr.session_failed.connect(_on_asr_failed)
	if _event != null and not _event.performance_finished.is_connected(_on_performance_finished):
		_event.performance_finished.connect(_on_performance_finished)
	if _event != null and not _event.performance_failed.is_connected(_on_performance_failed):
		_event.performance_failed.connect(_on_performance_failed)


func preconnect_for_upcoming_listen() -> void:
	if _asr != null:
		_asr.begin_preconnect()


## 引导动作已由宿主播完（序列帧邀请语），只开麦识别意愿。
func begin_listen_after_guide(business_token: int = -1) -> void:
	if _phase != Phase.IDLE:
		return
	_reset_round()
	_invite_session_id += 1
	_cancelled = false
	if business_token >= 0:
		_business_token = business_token
	_phase = Phase.WAITING_ANSWER
	_log_flow_snapshot("begin_listen_after_guide")
	_asr.begin_preconnect()
	call_deferred("_begin_listen_after_settle")


func begin_invite(business_token: int) -> void:
	if _phase != Phase.IDLE:
		_log("引导已在进行，忽略重复邀请")
		return
	if not ResExists.path(GUIDE_AUDIO):
		_log("引导配音不存在：%s" % GUIDE_AUDIO)
		_fail_invite(business_token)
		return
	_reset_round()
	_invite_session_id += 1
	_cancelled = false
	_business_token = business_token
	_phase = Phase.PLAYING
	_log_flow_snapshot("begin_invite")
	_expect_token = business_token
	_mark("guide_begin")
	_asr.begin_preconnect()
	if _host != null and _host.has_method("prepare_business_event_from_show"):
		_host.prepare_business_event_from_show()
	if _event == null or not _event.play_event(SPEAK_ACTION, business_token, true, true, 0.25):
		_log("引导动作播放失败 %s" % SPEAK_ACTION)
		_fail_invite(business_token)
		return
	_log("播放小游戏引导 %s + 引导语音" % SPEAK_ACTION)


func notify_presence_released() -> void:
	if _phase == Phase.IDLE or _phase == Phase.CANCELLED:
		return
	if _phase == Phase.COMMITTED:
		if _committed_intent == "PLAY":
			_stop_listen("presence_after_accept")
			_phase = Phase.IDLE
			_log("玩家离开，已接受 PLAY 保留业务状态")
			_log_flow_snapshot("presence_after_play")
		return
	_phase = Phase.CANCELLED
	_cancelled = true
	_stop_listen("presence_cancel")
	_business_token = -1
	_expect_token = -1
	if _host != null and _host.has_method("minigame_invite_cancelled"):
		_host.minigame_invite_cancelled(true)
	_log("玩家离开，取消小游戏引导（不算拒绝）")
	_log_flow_snapshot("presence_cancel")


func accept_keyboard_intent(intent: String) -> void:
	if intent != "PLAY" and intent != "DECLINE":
		return
	if not holds_schedule():
		return
	_commit_intent(intent, "keyboard")


func holds_schedule() -> bool:
	return (
		_phase == Phase.PLAYING
		or _phase == Phase.WAITING_ANSWER
		or _phase == Phase.LISTENING
	)


func phase_name() -> String:
	return Phase.keys()[_phase]


func listen_remaining_sec() -> float:
	if _phase != Phase.LISTENING or _listen_started_ms <= 0:
		return -1.0
	var elapsed := float(Time.get_ticks_msec() - _listen_started_ms) / 1000.0
	return maxf(InviteListenConfig.LISTEN_TIMEOUT_SEC - elapsed, 0.0)


func is_waiting_answer() -> bool:
	return _phase == Phase.WAITING_ANSWER or _phase == Phase.LISTENING


func committed_intent() -> String:
	return _committed_intent


func invite_session_id() -> int:
	return _invite_session_id


func commit_reason() -> String:
	return _commit_reason


func listen_round() -> int:
	return _unknown_retries + 1 if _phase == Phase.LISTENING else _unknown_retries


func is_cancelled() -> bool:
	return _cancelled


func debug_snapshot() -> Dictionary:
	return {
		"session": _invite_session_id,
		"phase": phase_name(),
		"listen_gen": _listen_gen,
		"listen_epoch": _listen_epoch,
		"listen_round": _unknown_retries + 1,
		"intent": _committed_intent,
		"reason": _commit_reason,
		"cancelled": _cancelled,
		"mic_active": _mic_active,
	}


func debug_enable_mock_asr(enabled: bool) -> void:
	mock_asr = enabled
	if _asr != null:
		_asr.mock_mode = enabled


func debug_inject_partial(text: String, final_line: bool = false) -> void:
	if _asr != null:
		_asr.inject_mock_partial(text, final_line)


func debug_unknown_retry_count() -> int:
	return _unknown_retries


func debug_simulate_listen_timeout() -> void:
	if _phase != Phase.LISTENING or _committed_intent != "":
		return
	_handle_unknown_final("listen_timeout")


func debug_simulate_asr_failed(reason: String) -> void:
	_asr_fail_ignore_until_ms = 0
	_on_asr_failed(reason)


func debug_cancel_invite() -> void:
	notify_presence_released()


func debug_session_id() -> int:
	return _invite_session_id


func notify_minigame_started() -> void:
	if _phase == Phase.COMMITTED or _phase == Phase.CANCELLED:
		_phase = Phase.IDLE
		_log("小游戏已启动，邀请监听流复位")
		_log_flow_snapshot("minigame_started")


func halt_for_other_show() -> void:
	if _phase == Phase.IDLE:
		return
	if _host != null and _host.has_method("sync_business_invite_preempted_by_show"):
		_host.sync_business_invite_preempted_by_show()
	_stop_listen("other_show")
	_phase = Phase.IDLE
	_committed_intent = ""
	_commit_reason = ""
	_cancelled = false
	_business_token = -1
	_expect_token = -1
	_log("其他演出开始，停止小游戏监听（非玩家拒绝、非识别 ERROR）")


func debug_reset_flow() -> void:
	_stop_listen("debug_reset")
	_phase = Phase.IDLE
	_committed_intent = ""
	_commit_reason = ""
	_cancelled = false
	_business_token = -1
	_expect_token = -1


func debug_begin_mock_listen_round() -> void:
	mock_asr = true
	if _asr != null:
		_asr.mock_mode = true
	_invite_session_id += 1
	_reset_round()
	_business_token = 9001
	_phase = Phase.WAITING_ANSWER
	_asr.begin_preconnect()
	call_deferred("_start_listening")


func debug_jump_to_next_listen_round() -> void:
	if _asr != null:
		_asr.mock_mode = true
	_phase = Phase.WAITING_ANSWER
	_stable_intent = ""
	_speech_started_ms = 0
	_listen_started_ms = 0
	_asr.begin_preconnect()
	call_deferred("_start_listening")


func _process(delta: float) -> void:
	if _phase == Phase.PLAYING and not _guide_audio_armed:
		var tl: YouyouActionLipsyncTimeline = null
		if _event != null and _event.has_method("get_timeline"):
			tl = _event.call("get_timeline") as YouyouActionLipsyncTimeline
		if tl != null and tl.is_audio_playing():
			_guide_audio_armed = true
			_mark("guide_audio_start")
			_asr.begin_preconnect()
	if _phase == Phase.LISTENING and _mic_active and not _stream_open and _committed_intent == "":
		if _asr.is_ready():
			_try_open_asr_stream(_listen_gen)
		elif _listen_started_ms > 0:
			var connect_elapsed := float(Time.get_ticks_msec() - _listen_started_ms) / 1000.0
			if connect_elapsed >= InviteListenConfig.PRECONNECT_WAIT_SEC:
				_log("麦克风已开，但识别连接超时")
				_handle_unknown_final("preconnect_timeout")
	if _is_listen_epoch_active() and _committed_intent == "":
		_poll_stable_intent()
		if _listen_started_ms > 0:
			var elapsed := float(Time.get_ticks_msec() - _listen_started_ms) / 1000.0
			if elapsed >= InviteListenConfig.LISTEN_TIMEOUT_SEC:
				if _speech_started_ms <= 0:
					_log("监听超时且未检测到起说，请检查系统麦克风权限与音量")
				_handle_unknown_final("listen_timeout")


func _on_performance_finished(token: int, action_id: String, _reason: String) -> void:
	if token != _expect_token or action_id != SPEAK_ACTION:
		return
	if _phase != Phase.PLAYING:
		return
	_expect_token = -1
	_phase = Phase.WAITING_ANSWER
	var on_idle := _player != null and String(_player.get("assigned_animation")) == "Basic_Idle"
	_log("引导语结束，回到待机=%s，进入等待回答" % str(on_idle))
	if _adapter != null and _adapter.has_method("complete_minigame_invite"):
		_adapter.complete_minigame_invite(_business_token)
	call_deferred("_begin_listen_after_settle")


func _begin_listen_after_settle() -> void:
	if _phase != Phase.WAITING_ANSWER:
		return
	await get_tree().create_timer(InviteListenConfig.POST_GUIDE_SETTLE_SEC).timeout
	if _phase != Phase.WAITING_ANSWER:
		return
	_start_listening()


func _start_listening() -> void:
	_listen_gen += 1
	var gen := _listen_gen
	_listen_epoch = gen
	_phase = Phase.LISTENING
	_listen_started_ms = Time.get_ticks_msec()
	_stream_open = false
	_pcm_pending.clear()
	_log("开始第 %d 轮监听 unknown_retries=%d" % [gen, _unknown_retries])
	_mark("mic_open")
	if not _mic_active:
		_mic.start_capture()
		_mic_active = true
		_log("麦克风已打开，不等待识别连接")
	if _host != null and _host.has_method("minigame_invite_listen_ready"):
		_host.minigame_invite_listen_ready()
	_try_open_asr_stream(gen)


func _try_open_asr_stream(gen: int) -> void:
	if gen != _listen_gen or _phase != Phase.LISTENING or _stream_open:
		return
	if not _asr.is_ready():
		return
	_asr.begin_stream()
	_stream_open = true
	_log("识别流已接上，开始上传 %d 段缓存" % _pcm_pending.size())
	var pending: Array = _pcm_pending.duplicate()
	_pcm_pending.clear()
	for chunk in pending:
		_asr.send_pcm(chunk)


func _ensure_asr_ready(gen: int) -> bool:
	if _asr.is_ready():
		return true
	var waited := 0.0
	while waited < InviteListenConfig.PRECONNECT_WAIT_SEC:
		if gen != _listen_gen:
			return false
		if _asr.is_ready():
			_log("复用已就绪的流式连接")
			return true
		await get_tree().process_frame
		waited += get_process_delta_time()
	_log("预连接未就绪，尝试重新建连")
	_asr.force_reconnect()
	waited = 0.0
	while waited < InviteListenConfig.PRECONNECT_WAIT_SEC:
		if gen != _listen_gen:
			return false
		if _asr.is_ready():
			return true
		await get_tree().process_frame
		waited += get_process_delta_time()
	return false


func _on_pcm_chunk(pcm: PackedByteArray) -> void:
	if not _is_listen_epoch_active() or _committed_intent != "":
		return
	if _stream_open:
		_asr.send_pcm(pcm)
		return
	_pcm_pending.append(pcm)
	while _pcm_pending.size() > 20:
		_pcm_pending.pop_front()


func _on_speech_started() -> void:
	if _speech_started_ms <= 0:
		_speech_started_ms = Time.get_ticks_msec()
		_mark("vad_start")


func _on_partial(text: String) -> void:
	if not _is_listen_epoch_active() or _committed_intent != "":
		return
	if not _timings.has("first_partial"):
		_mark("first_partial")
	_log("partial=%s" % text)
	_update_stable(text)


func _on_sentence_end(text: String) -> void:
	if not _is_listen_epoch_active() or _committed_intent != "":
		return
	var intent := MinigameIntentRules.classify(text)
	if intent == "UNKNOWN":
		_handle_unknown_final("stream_final")
	else:
		_commit_intent(intent, "stream_final")


func _poll_stable_intent() -> void:
	if _stable_intent == "" or not MinigameIntentRules.can_early_commit(_stable_intent):
		return
	var elapsed_ms := Time.get_ticks_msec() - _stable_since_ms
	if elapsed_ms >= int(InviteListenConfig.STABLE_INTENT_SEC * 1000.0):
		_commit_intent(_stable_intent, "stable_window")


func _update_stable(text: String) -> void:
	var intent := MinigameIntentRules.classify(text)
	if not MinigameIntentRules.can_early_commit(intent):
		_stable_intent = ""
		_stable_since_ms = 0
		return
	if intent != _stable_intent:
		_stable_intent = intent
		_stable_since_ms = Time.get_ticks_msec()


func _commit_intent(intent: String, reason: String) -> void:
	if _phase == Phase.CANCELLED or _committed_intent != "":
		return
	var session := _invite_session_id
	_committed_intent = intent
	_commit_reason = reason
	_phase = Phase.COMMITTED
	_expect_token = -1
	_stop_listen("intent_committed")
	_mark("intent_commit")
	if _speech_started_ms > 0:
		var latency := Time.get_ticks_msec() - _speech_started_ms
		_log("意图=%s 原因=%s 起说→提交=%dms session=%d" % [intent, reason, latency, session])
	else:
		_log("意图=%s 原因=%s（无起说） session=%d" % [intent, reason, session])
	_log_flow_snapshot("intent_committed")
	if session != _invite_session_id:
		return
	if _host != null and _host.has_method("minigame_invite_on_intent"):
		_host.minigame_invite_on_intent(intent, session, reason)


func _commit_listen_error(reason: String) -> void:
	if _phase == Phase.CANCELLED or _committed_intent != "":
		return
	var session := _invite_session_id
	_committed_intent = "ERROR"
	_commit_reason = reason
	_phase = Phase.COMMITTED
	_stop_listen("listen_error")
	_log("识别异常收尾 原因=%s session=%d" % [reason, session])
	_log_flow_snapshot("listen_error")
	if session != _invite_session_id:
		return
	if _host != null and _host.has_method("minigame_invite_on_error"):
		_host.minigame_invite_on_error(reason, session)


func _handle_unknown_final(reason: String) -> void:
	if _phase == Phase.CANCELLED or _committed_intent != "":
		return
	if _unknown_retries < InviteListenConfig.MAX_UNKNOWN_REASK:
		_unknown_retries += 1
		_log("UNKNOWN 重问 %d/%d 原因=%s listen_epoch=%d" % [
			_unknown_retries, InviteListenConfig.MAX_UNKNOWN_REASK, reason, _listen_epoch,
		])
		_phase = Phase.PLAYING
		_stop_listen("reask")
		_reask_guide()
		return
	if reason.begins_with("asr_"):
		_log("ASR 异常在重问后仍未恢复，按识别异常收尾（listen_epoch=%d）" % _listen_epoch)
		_commit_listen_error(reason)
		return
	_log("UNKNOWN 二次仍无法识别，按识别失败收尾（listen_epoch=%d）" % _listen_epoch)
	_commit_listen_error("unknown_twice")


func _reask_guide() -> void:
	_guide_audio_armed = false
	_stable_intent = ""
	_speech_started_ms = 0
	_listen_started_ms = 0
	_stream_open = false
	_pcm_pending.clear()
	_expect_token = _business_token
	_asr.begin_preconnect()
	if _event != null:
		if not _event.play_event(SPEAK_ACTION, _business_token, true, true, 0.25):
			_commit_intent("DECLINE", "reask_play_fail")
		return
	if _host != null and _host.has_method("minigame_invite_reask"):
		_host.minigame_invite_reask(_business_token)
	_phase = Phase.WAITING_ANSWER
	call_deferred("_begin_listen_after_settle")


func _on_asr_failed(reason: String) -> void:
	_log("ASR 失败：%s" % reason)
	if Time.get_ticks_msec() < _asr_fail_ignore_until_ms:
		_log("ASR 失败已忽略(停麦窗口) %s" % reason)
		return
	if _suppress_asr_failure or _phase == Phase.PLAYING or _phase == Phase.CANCELLED:
		return
	if not _is_listen_epoch_active() or _committed_intent != "":
		_log("ASR 失败已忽略(非当前监听轮) %s" % reason)
		return
	_handle_unknown_final("asr_%s" % reason)


func _stop_listen(reason: String) -> void:
	_listen_epoch = 0
	_asr_fail_ignore_until_ms = Time.get_ticks_msec() + 400
	_listen_gen += 1
	_stream_open = false
	_pcm_pending.clear()
	if _mic_active:
		_suppress_asr_failure = true
		_mic.stop_capture()
		_asr.stop_session()
		_suppress_asr_failure = false
		_mic_active = false
	if _host != null and _host.has_method("minigame_invite_listen_ended"):
		_host.minigame_invite_listen_ended()
	_mark("listen_stop")
	_log("停止监听 原因=%s" % reason)


func _on_performance_failed(token: int, action_id: String, _code: String, message: String) -> void:
	if token != _expect_token or action_id != SPEAK_ACTION:
		return
	_log("引导表现失败 %s：%s" % [action_id, message])
	_fail_invite(token)


func _fail_invite(token: int) -> void:
	_stop_listen("invite_fail")
	_phase = Phase.IDLE
	_expect_token = -1
	_business_token = -1
	if _adapter != null and _adapter.has_method("fail_minigame_invite"):
		_adapter.fail_minigame_invite(token)


func _is_listen_epoch_active() -> bool:
	return _phase == Phase.LISTENING and _listen_epoch > 0 and _listen_epoch == _listen_gen


func _log_flow_snapshot(tag: String) -> void:
	var biz_phase := ""
	var biz_stage := ""
	if _host != null and _host.has_method("invite_business_snapshot"):
		var snap: Dictionary = _host.invite_business_snapshot()
		biz_stage = String(snap.get("stage", ""))
		biz_phase = String(snap.get("result_phase", ""))
	_log(
		"snapshot tag=%s session=%d phase=%s listen_gen=%d round=%d intent=%s reason=%s cancelled=%s mic=%s biz=%s/%s"
		% [
			tag, _invite_session_id, phase_name(), _listen_gen, _unknown_retries + 1,
			_committed_intent, _commit_reason, str(_cancelled), str(_mic_active),
			biz_stage, biz_phase,
		]
	)


func _reset_round() -> void:
	_guide_audio_armed = false
	_unknown_retries = 0
	_listen_epoch = 0
	_cancelled = false
	_mic_active = false
	_committed_intent = ""
	_commit_reason = ""
	_stable_intent = ""
	_stable_since_ms = 0
	_speech_started_ms = 0
	_listen_started_ms = 0
	_timings.clear()


func _mark(key: String) -> void:
	_timings[key] = Time.get_ticks_msec()
	_log("timing %s=%d" % [key, _timings[key]])


func _asr_log(msg: String) -> void:
	_log("asr %s" % msg)


func _log(message: String) -> void:
	if _host != null and _host.has_method("grab_log"):
		_host.grab_log("[小游戏引导] " + message)
	else:
		push_warning("[小游戏引导] " + message)
