extends RefCounted
class_name VoicePipelineFeatureFlags

## 对话默认：NLS WebSocket 流式 ASR、Moonshot 非流式 LLM、百炼 WebSocket 流式 TTS（HTTP 回退保留）。
## 流式 LLM 与新窗口策略仍默认关闭。环境变量 1/true/on 开、0/false/off 关，否则读 ProjectSettings application/config/voice_*。

const ENV_STREAM_ASR := "YOUYOU_VOICE_STREAM_ASR"
const ENV_STREAM_LLM := "YOUYOU_VOICE_STREAM_LLM"
const ENV_STREAM_TTS := "YOUYOU_VOICE_STREAM_TTS"
const ENV_NEW_WINDOW := "YOUYOU_VOICE_NEW_WINDOW_POLICY"

var stream_asr := true
var stream_llm := false
var stream_tts := true
var new_window_policy := false


static func load_current() -> VoicePipelineFeatureFlags:
	var f := VoicePipelineFeatureFlags.new()
	f.stream_asr = _read_bool(ENV_STREAM_ASR, "voice/stream_asr", true)
	f.stream_llm = _read_bool(ENV_STREAM_LLM, "voice/stream_llm", false)
	f.stream_tts = _read_bool(ENV_STREAM_TTS, "voice/stream_tts", true)
	f.new_window_policy = _read_bool(ENV_NEW_WINDOW, "voice/new_window_policy", false)
	return f


func any_experimental_enabled() -> bool:
	return stream_llm or new_window_policy


func stable_path_required() -> bool:
	return not any_experimental_enabled()


func to_dictionary() -> Dictionary:
	return {
		"stream_asr": stream_asr,
		"stream_llm": stream_llm,
		"stream_tts": stream_tts,
		"new_window_policy": new_window_policy,
	}


func status_line() -> String:
	return (
		"voice_flags asr=%s llm=%s tts=%s window=%s"
		% [str(stream_asr), str(stream_llm), str(stream_tts), str(new_window_policy)]
	)


static func _read_bool(env_key: String, project_key: String, default_value: bool) -> bool:
	var raw := OS.get_environment(env_key).strip_edges().to_lower()
	if raw in ["1", "true", "yes", "on"]:
		return true
	if raw in ["0", "false", "no", "off"]:
		return false
	if not raw.is_empty():
		return default_value
	if ProjectSettings.has_setting("application/config/%s" % project_key):
		return bool(ProjectSettings.get_setting("application/config/%s" % project_key))
	return default_value
