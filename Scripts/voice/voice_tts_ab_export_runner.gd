extends Node

## Phase4-B：导出 HTTP 整句 / WS 单句 / WS 多分句 WAV，供人工听感 A/B。
## 需 YOUYOU_TTS_VOICE_AB_EXPORT=1 与有效百炼配置。

const BailianTtsConfigScript := preload("res://Scripts/voice/bailian_tts_config.gd")
const BailianTtsClientScript := preload("res://Scripts/voice/bailian_tts_client.gd")
const BailianTtsWsClientScript := preload("res://Scripts/voice/bailian_tts_ws_client.gd")
const VoiceOutputScript := preload("res://Scripts/voice/voice_output.gd")
const AudioBytesUtilScript := preload("res://Scripts/voice/audio_bytes_util.gd")
const YouyouVoiceSecretsScript := preload("res://Scripts/voice/youyou_voice_secrets.gd")
const AliyunNlsConfigScript := preload("res://Scripts/voice/aliyun_nls_config.gd")
const MoonshotLlmClientScript := preload("res://Scripts/voice/moonshot_llm_client.gd")

const DEFAULT_TEXT := "粉色兔子超软萌，要不要我帮你抓一只呀？"


func run() -> bool:
	if not _env_truthy("YOUYOU_TTS_VOICE_AB_EXPORT"):
		print("voice_tts_ab_export: SKIP (set YOUYOU_TTS_VOICE_AB_EXPORT=1)")
		return true
	var cfg := BailianTtsConfigScript.new()
	YouyouVoiceSecretsScript.load_into(AliyunNlsConfigScript.new(), MoonshotLlmClientScript.new(), cfg)
	var cfg_err := cfg.validate_for_tts()
	if not cfg_err.is_empty():
		push_error("voice_tts_ab_export: config: " + cfg_err)
		return false
	var text := _env_str("YOUYOU_BAILIAN_TTS_AB_TEXT", DEFAULT_TEXT)
	var instruction := _env_str("YOUYOU_BAILIAN_TTS_AB_INSTRUCTION", "情绪：开心")
	var out_dir := _env_str("YOUYOU_TTS_AB_OUT_DIR", "res://_ab_logs/tts_voice_ab/latest")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var rate := cfg.sample_rate if cfg.sample_rate > 0 else 24000
	print("voice_tts_ab_export: out=%s text_len=%d" % [out_dir, text.length()])

	var http := BailianTtsClientScript.new()
	var ws := BailianTtsWsClientScript.new()
	add_child(http)
	add_child(ws)
	http.setup(cfg)
	ws.setup(cfg)

	var a_ok := await _export_http(http, text, instruction, out_dir + "/A_http_full.wav")
	var b_ok := await _export_ws_single(ws, text, instruction, rate, out_dir + "/B_ws_single.wav")
	var c_ok := await _export_ws_multi_chunks(ws, text, instruction, rate, out_dir + "/C_ws_multi_concat.wav")

	http.queue_free()
	ws.queue_free()
	var ok := a_ok and b_ok and c_ok
	print("voice_tts_ab_export: done ok=%s files=A_http_full B_ws_single C_ws_multi_concat" % str(ok))
	print("voice_tts_ab_export: listen_compare=人工对比音色/音高/语速/分句停顿")
	return ok


func _export_http(
	client: BailianTtsClientScript,
	text: String,
	instruction: String,
	path: String,
) -> bool:
	var res: Dictionary = await client.synthesize_text(text, instruction)
	if not res.get("ok", false):
		push_error("voice_tts_ab_export: HTTP failed: " + str(res.get("error", "")))
		return false
	var audio: PackedByteArray = res.get("audio", PackedByteArray())
	return _write_audio_bytes(path, audio)


func _export_ws_single(
	ws: BailianTtsWsClientScript,
	text: String,
	instruction: String,
	rate: int,
	path: String,
) -> bool:
	ws.cancel()
	var res: Dictionary = await ws.synthesize_pcm(text, instruction, false)
	if not res.get("ok", false):
		push_error("voice_tts_ab_export: WS single failed: " + str(res.get("error", "")))
		return false
	var pcm: PackedByteArray = res.get("pcm", PackedByteArray())
	return _write_pcm_wav(path, pcm, rate)


func _export_ws_multi_chunks(
	ws: BailianTtsWsClientScript,
	text: String,
	instruction: String,
	rate: int,
	path: String,
) -> bool:
	var vo := VoiceOutputScript.new()
	var chunks: PackedStringArray = vo.peek_tts_chunks(text)
	vo.free()
	print("voice_tts_ab_export: C chunks=%d" % chunks.size())
	var all_pcm := PackedByteArray()
	for i in chunks.size():
		ws.cancel()
		var reuse := i > 0
		var res: Dictionary = await ws.synthesize_pcm(chunks[i], instruction, reuse)
		if not res.get("ok", false):
			push_error("voice_tts_ab_export: WS chunk %d failed: %s" % [i, res.get("error", "")])
			return false
		var pcm: PackedByteArray = res.get("pcm", PackedByteArray())
		all_pcm.append_array(pcm)
		var chunk_path := path.get_basename() + "_chunk%d.wav" % i
		_write_pcm_wav(chunk_path, pcm, rate)
	return _write_pcm_wav(path, all_pcm, rate)


func _write_audio_bytes(path: String, audio: PackedByteArray) -> bool:
	var abs := ProjectSettings.globalize_path(path)
	var f := FileAccess.open(abs, FileAccess.WRITE)
	if f == null:
		push_error("voice_tts_ab_export: cannot write " + abs)
		return false
	f.store_buffer(audio)
	f.close()
	print("voice_tts_ab_export: wrote %s bytes=%d" % [path, audio.size()])
	return true


func _write_pcm_wav(path: String, pcm: PackedByteArray, rate: int) -> bool:
	var wav := AudioBytesUtilScript.pcm16_le_to_wav(pcm, rate, 1)
	return _write_audio_bytes(path, wav)


func _env_truthy(name: String) -> bool:
	var v := OS.get_environment(name).strip_edges().to_lower()
	return v in ["1", "true", "yes", "on"]


func _env_str(name: String, default: String) -> String:
	var v := OS.get_environment(name).strip_edges()
	return default if v.is_empty() else v
