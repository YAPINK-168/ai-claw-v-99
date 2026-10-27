extends Node

## 尾静音按采样累计，以及结束前短尾块。不连真实麦克风或网络。

const CaptureScript := preload("res://Scripts/voice/continuous_utterance_capture.gd")
const ConfigScript := preload("res://Scripts/voice/invite_listen_config.gd")
const AsrScript := preload("res://Scripts/voice/invite_streaming_asr.gd")
const CtrlScript := preload("res://Scripts/voice/formal_streaming_asr_controller.gd")
const SpeechScript := preload("res://Scripts/voice/speech_input.gd")
const NlsScript := preload("res://Scripts/voice/aliyun_nls_config.gd")
const TokenScript := preload("res://Scripts/voice/nls_token_provider.gd")

const RATE := 48000
var _bus_serial := 0


func run() -> bool:
	var ok := true
	ok = ok and _test_trailing_config()
	ok = ok and _test_gap_matrix()
	ok = ok and _test_tail_chunk()
	ok = ok and _test_quiet_noise_short_pause()
	ok = ok and _test_two_turns()
	ok = ok and await _test_pcm_before_end_and_cancel()
	print("=== vad_endpoint_check_pass=%s ===" % str(ok))
	return ok


func _test_trailing_config() -> bool:
	OS.set_environment("YOUYOU_VAD_TRAILING_MS", "")
	ConfigScript.reset_trailing_runtime_log()
	var ok := ConfigScript.trailing_silence_ms() == 800
	OS.set_environment("YOUYOU_VAD_TRAILING_MS", "400")
	ok = ok and ConfigScript.trailing_silence_ms() == 400
	OS.set_environment("YOUYOU_VAD_TRAILING_MS", "800")
	ok = ok and ConfigScript.trailing_silence_ms() == 800
	OS.set_environment("YOUYOU_VAD_TRAILING_MS", "50")
	ok = ok and ConfigScript.trailing_silence_ms() == 200
	OS.set_environment("YOUYOU_VAD_TRAILING_MS", "9000")
	ok = ok and ConfigScript.trailing_silence_ms() == 1200
	OS.set_environment("YOUYOU_VAD_TRAILING_MS", "nope")
	ok = ok and ConfigScript.trailing_silence_ms() == 800
	ConfigScript.reset_trailing_runtime_log()
	OS.set_environment("YOUYOU_VAD_TRAILING_MS", "600")
	if not ok:
		push_error("vad_endpoint_check trailing config")
	return ok


func _test_gap_matrix() -> bool:
	var ok := true
	for mode in ["30", "60", "unstable"]:
		var keep200 := _feed_gap(200, mode, 600)
		var keep400 := _feed_gap(400, mode, 600)
		var cut700 := _feed_gap(700, mode, 600)
		var samples200 := int(keep200["samples"])
		var samples400 := int(keep400["samples"])
		var samples700 := int(cut700["samples"])
		var case_ok := (
			int(keep200["ended"]) == 1
			and int(keep400["ended"]) == 1
			and int(cut700["ended"]) == 1
			and samples200 == _expected_samples(200, 600)
			and samples400 == _expected_samples(400, 600)
			and samples700 == _expected_samples(700, 600)
			and absf(float(cut700["actual"]) - 600.0) < 1.0
		)
		print(
			"vad_case gap mode=%s s200=%d s400=%d s700=%d actual700=%.1f ok=%s"
			% [mode, samples200, samples400, samples700, float(cut700["actual"]), str(case_ok)]
		)
		ok = ok and case_ok
	var at400 := _feed_gap(400, "60", 400)
	var at400_keep := _feed_gap(200, "60", 400)
	var at800 := _feed_gap(700, "60", 800)
	var cand_ok := (
		int(at400["ended"]) == 1
		and int(at400["samples"]) == _expected_samples(400, 400)
		and int(at400_keep["ended"]) == 1
		and int(at400_keep["samples"]) == _expected_samples(200, 400)
		and int(at800["ended"]) == 1
		and int(at800["samples"]) == _expected_samples(700, 800)
	)
	print(
		"vad_case candidates cut400=%d keep200_at400=%d keep700_at800=%d ok=%s"
		% [int(at400["samples"]), int(at400_keep["samples"]), int(at800["samples"]), str(cand_ok)]
	)
	if not (ok and cand_ok):
		push_error("vad_endpoint_check gap matrix")
	return ok and cand_ok


func _test_tail_chunk() -> bool:
	var row := _feed_audio(_tone(280) + _silence(600), "60", 600, true)
	var chunks: Array = row["chunks"]
	var ended_pcm: PackedByteArray = row["ended_pcm"]
	var tail := int(chunks[chunks.size() - 1]) if not chunks.is_empty() else 0
	var sum := 0
	for n in chunks:
		sum += int(n)
	var order: Array = row["order"]
	var ended_at := order.find("ended")
	var order_ok := ended_at > 0
	for i in ended_at:
		if str(order[i]) != "chunk" and str(order[i]) != "started":
			order_ok = false
	var ok := (
		int(row["samples"]) == _ms_samples(880)
		and tail == 2560
		and tail < 3200
		and tail > 0
		and sum == int(row["chunk_bytes"])
		and ended_pcm.size() == sum
		and ended_pcm.size() == 28160
		and order_ok
		and str(order[order.size() - 1]) == "ended"
	)
	print(
		"vad_case tail samples=%d tail_bytes=%d chunk_sum=%d rest_bytes=%d ok=%s"
		% [int(row["samples"]), tail, sum, ended_pcm.size(), str(ok)]
	)
	if not ok:
		push_error("vad_endpoint_check tail chunk order=%s" % str(order))
	return ok


func _test_quiet_noise_short_pause() -> bool:
	var quiet := _feed_audio(_tone_amp(280, 0.008) + _silence(600), "60", 600, true)
	var noise := _feed_audio(_tone_amp(800, 0.02), "60", 600, false)
	var room := _feed_audio(_tone_amp(500, 0.001), "60", 600, false)
	var too_brief := _feed_audio(_tone(20) + _silence(600), "60", 600, false)
	var short_ok := _feed_audio(_tone(40) + _silence(600), "60", 600, true)
	var paused := _new_cap(600)
	paused.set_paused(true)
	paused.debug_feed_samples(_tone(500))
	var preempt := _new_cap(600)
	preempt.debug_feed_samples(_tone(100))
	var started := preempt.is_speech_active()
	preempt.set_paused(true)
	preempt.debug_feed_samples(_tone(400))
	var preempt_ok := started and not preempt.is_speech_active() and preempt.debug_last_endpoint().is_empty()
	var ok := (
		str(quiet["event"]) == "too_quiet"
		and int(quiet["reject_quiet"]) >= 1
		and int(noise["ended"]) == 0
		and bool(noise["started"])
		and int(room["ended"]) == 0
		and not bool(room["started"])
		and int(too_brief["ended"]) == 0
		and str(short_ok["event"]) == "speech_ended"
		and int(paused.debug_last_endpoint().size()) == 0
		and preempt_ok
	)
	print(
		"vad_case edge quiet=%s noise_started=%s room_started=%s brief_ended=%d short=%s preempt=%s ok=%s"
		% [
			str(quiet["event"]),
			str(noise["started"]),
			str(room["started"]),
			int(too_brief["ended"]),
			str(short_ok["event"]),
			str(preempt_ok),
			str(ok),
		]
	)
	if not ok:
		push_error("vad_endpoint_check edge cases")
	return ok


func _test_two_turns() -> bool:
	var cap := _new_cap(600)
	var turns: Array = []
	var current: Array = []
	cap.pcm_chunk.connect(func(pcm: PackedByteArray) -> void:
		current.append(pcm.size())
	)
	cap.speech_ended.connect(func(_pcm: PackedByteArray, _rate: int) -> void:
		var copied: Array = current.duplicate()
		turns.append(copied)
		current.clear()
		cap.set_paused(true)
	)
	cap.debug_feed_samples(_tone(280) + _silence(600))
	cap.set_paused(false, true)
	cap.debug_feed_samples(_tone(280) + _silence(600))
	var first := 0
	var second := 0
	if turns.size() == 2:
		for n in turns[0]:
			first += int(n)
		for n in turns[1]:
			second += int(n)
	var ok := turns.size() == 2 and first > 0 and first == second
	print("vad_case turns=%d first_bytes=%d second_bytes=%d ok=%s" % [turns.size(), first, second, str(ok)])
	if not ok:
		push_error("vad_endpoint_check two turns")
	return ok


func _test_pcm_before_end_and_cancel() -> bool:
	var nls := NlsScript.new()
	add_child(nls)
	var tokens := TokenScript.new()
	tokens.setup(nls)
	add_child(tokens)
	var speech := SpeechScript.new()
	add_child(speech)
	var asr := AsrScript.new()
	asr.mock_mode = true
	add_child(asr)
	asr.setup(nls, tokens)
	var ctrl := CtrlScript.new()
	add_child(ctrl)
	ctrl.setup(asr, speech)
	ctrl.set_feature_enabled(true)
	ctrl.mock_stream_result = "顺序"
	ctrl.on_session_started(1)
	ctrl.on_vad_speech_started(1, [])
	var pcm := PackedByteArray()
	pcm.resize(100)
	ctrl.push_pcm(pcm)
	var text: String = await ctrl.finalize_utterance(pcm, 16000, 1)
	var order_ok := (
		text == "顺序"
		and asr.sent_pcm_bytes == 100
		and asr.last_pcm_sent_msec >= 0
		and asr.utterance_end_msec >= asr.last_pcm_sent_msec
	)
	var asr2 := AsrScript.new()
	asr2.mock_mode = true
	add_child(asr2)
	asr2.setup(nls, tokens)
	var ctrl2 := CtrlScript.new()
	add_child(ctrl2)
	ctrl2.setup(asr2, speech)
	ctrl2.set_feature_enabled(true)
	ctrl2.on_session_started(2)
	ctrl2.on_vad_speech_started(2, [])
	ctrl2.push_pcm(pcm)
	ctrl2.cancel_active_turn(false)
	await get_tree().create_timer(0.2).timeout
	var cancel_ok := asr2.sent_pcm_bytes == 0
	print(
		"vad_case asr_order sent=%d end_minus_pcm=%d cancel_sent=%d ok=%s"
		% [
			asr.sent_pcm_bytes,
			asr.utterance_end_msec - asr.last_pcm_sent_msec,
			asr2.sent_pcm_bytes,
			str(order_ok and cancel_ok),
		]
	)
	if not (order_ok and cancel_ok):
		push_error("vad_endpoint_check asr order text=%s" % text)
	return order_ok and cancel_ok


func _feed_gap(gap_ms: int, mode: String, trailing_ms: int) -> Dictionary:
	var audio := _tone(300) + _silence(gap_ms) + _tone(300) + _silence(trailing_ms)
	return _feed_audio(audio, mode, trailing_ms, true)


func _expected_samples(gap_ms: int, trailing_ms: int) -> int:
	if gap_ms >= trailing_ms:
		return _ms_samples(300 + trailing_ms)
	return _ms_samples(300 + gap_ms + 300 + trailing_ms)


func _feed_audio(audio: PackedFloat32Array, mode: String, trailing_ms: int, pause_on_end: bool) -> Dictionary:
	var cap := _new_cap(trailing_ms)
	var order: Array = []
	var chunks: Array = []
	var ended := [0]
	var started := [false]
	var ended_holder: Array = [PackedByteArray()]
	cap.speech_started.connect(func() -> void:
		started[0] = true
		order.append("started")
	)
	cap.pcm_chunk.connect(func(pcm: PackedByteArray) -> void:
		order.append("chunk")
		chunks.append(pcm.size())
	)
	cap.speech_ended.connect(func(pcm: PackedByteArray, _rate: int) -> void:
		order.append("ended")
		ended[0] += 1
		ended_holder[0] = pcm
		if pause_on_end:
			cap.set_paused(true)
	)
	cap.utterance_rejected.connect(func(reason: String) -> void:
		order.append(reason)
	)
	_feed_sliced(cap, audio, mode)
	var ep: Dictionary = cap.debug_last_endpoint()
	return {
		"samples": int(ep.get("utterance_samples", 0)),
		"actual": float(ep.get("actual_trailing_ms", -1.0)),
		"ended": ended[0],
		"started": started[0],
		"event": str(ep.get("event", "")),
		"tail_bytes": int(ep.get("tail_bytes", 0)),
		"chunk_bytes": int(ep.get("chunk_bytes", 0)),
		"reject_quiet": int(ep.get("reject_quiet", 0)),
		"chunks": chunks,
		"order": order,
		"ended_pcm": ended_holder[0],
	}


func _new_cap(trailing_ms: int) -> CaptureScript:
	OS.set_environment("YOUYOU_VAD_TRAILING_MS", str(trailing_ms))
	_bus_serial += 1
	var cap := CaptureScript.new()
	cap.record_bus_name = "VadEndpointCheck%d" % _bus_serial
	add_child(cap)
	cap.debug_set_mix_rate(RATE)
	return cap


func _feed_sliced(cap: CaptureScript, audio: PackedFloat32Array, mode: String) -> void:
	var steps: Array[int] = []
	match mode:
		"30":
			steps = [maxi(1, int(RATE / 30.0))]
		"60":
			steps = [maxi(1, int(RATE / 60.0))]
		_:
			steps = [maxi(1, int(RATE / 120.0)), maxi(1, int(RATE / 20.0)), maxi(1, int(RATE / 45.0))]
	var index := 0
	var step_i := 0
	while index < audio.size():
		var count: int = steps[step_i % steps.size()]
		step_i += 1
		var end := mini(index + count, audio.size())
		cap.debug_feed_samples(audio.slice(index, end))
		index = end


func _ms_samples(ms: int) -> int:
	return int(RATE * ms / 1000.0)


func _tone(ms: int) -> PackedFloat32Array:
	return _tone_amp(ms, 0.2)


func _tone_amp(ms: int, amp: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(_ms_samples(ms))
	for i in out.size():
		out[i] = amp
	return out


func _silence(ms: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(_ms_samples(ms))
	return out
