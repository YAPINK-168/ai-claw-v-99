extends RefCounted
class_name InviteListenConfig

## 小游戏意愿识别：能量门控、稳定窗、超时与重试（集中配置）。

const POST_GUIDE_SETTLE_SEC := 0.05
const STABLE_INTENT_SEC := 0.2
const PRECONNECT_WAIT_SEC := 8.0
const LISTEN_TIMEOUT_SEC := 12.0
const PCM_CHUNK_MS := 100
const SAMPLE_RATE := 16000

const ENERGY_THRESHOLD := 0.006
const ENERGY_START_FRAMES := 2
## 邀请麦仍按渲染帧使用。正式对话尾静音改看 trailing_silence_ms()。
const ENERGY_END_FRAMES := 18
## 正式对话 VAD 分析窗。只按采样时长推进，不按渲染帧。
const ANALYSIS_HOP_MS := 20
const TRAILING_MS_DEFAULT := 800
const TRAILING_MS_MIN := 200
const TRAILING_MS_MAX := 1200
const PROJECT_TRAILING_KEY := "voice/trailing_silence_ms"
const POST_TTS_LISTEN_COOLDOWN_MS_DEFAULT := 1200
const POST_TTS_LISTEN_COOLDOWN_MS_MIN := 0
const POST_TTS_LISTEN_COOLDOWN_MS_MAX := 5000
const PROJECT_POST_TTS_COOLDOWN_KEY := "voice/post_tts_listen_cooldown_ms"
const ENV_POST_TTS_COOLDOWN := "YOUYOU_POST_TTS_LISTEN_COOLDOWN_MS"

static var _trailing_warn_key := ""
static var _logged_effective := false
static var _logged_post_tts_cooldown := false


## 优先级：YOUYOU_VAD_TRAILING_MS → ProjectSettings application/config/voice/trailing_silence_ms → 800。
static func trailing_silence_ms() -> int:
	var ms := _resolve_trailing_ms()
	if not _logged_effective:
		_logged_effective = true
		print("vad_config trailing_silence_ms=%d source=%s" % [ms, trailing_silence_source()])
	return ms


static func trailing_silence_source() -> String:
	var raw := OS.get_environment("YOUYOU_VAD_TRAILING_MS").strip_edges()
	if not raw.is_empty():
		return "env"
	if ProjectSettings.has_setting("application/config/%s" % PROJECT_TRAILING_KEY):
		return "project"
	return "default"


static func _resolve_trailing_ms() -> int:
	var raw := OS.get_environment("YOUYOU_VAD_TRAILING_MS").strip_edges()
	if not raw.is_empty():
		if not raw.is_valid_int():
			_warn_trailing(raw, TRAILING_MS_DEFAULT, "非法")
			return TRAILING_MS_DEFAULT
		return _clamp_trailing(int(raw), raw)
	if ProjectSettings.has_setting("application/config/%s" % PROJECT_TRAILING_KEY):
		var from_proj := int(ProjectSettings.get_setting("application/config/%s" % PROJECT_TRAILING_KEY))
		return _clamp_trailing(from_proj, str(from_proj))
	return TRAILING_MS_DEFAULT


static func _clamp_trailing(ms: int, raw_for_warn: String) -> int:
	if ms >= TRAILING_MS_MIN and ms <= TRAILING_MS_MAX:
		return ms
	var clamped := clampi(ms, TRAILING_MS_MIN, TRAILING_MS_MAX)
	_warn_trailing(raw_for_warn, clamped, "越界")
	return clamped


static func reset_trailing_runtime_log() -> void:
	_logged_effective = false


## AI 播完一句后延迟再开麦，避免扬声器尾音/回声立刻触发 VAD。
static func post_tts_listen_cooldown_ms() -> int:
	var ms := _resolve_post_tts_cooldown_ms()
	if not _logged_post_tts_cooldown:
		_logged_post_tts_cooldown = true
		print("vad_config post_tts_listen_cooldown_ms=%d" % ms)
	return ms


static func _resolve_post_tts_cooldown_ms() -> int:
	var raw := OS.get_environment(ENV_POST_TTS_COOLDOWN).strip_edges()
	if not raw.is_empty():
		if not raw.is_valid_int():
			return POST_TTS_LISTEN_COOLDOWN_MS_DEFAULT
		return clampi(int(raw), POST_TTS_LISTEN_COOLDOWN_MS_MIN, POST_TTS_LISTEN_COOLDOWN_MS_MAX)
	if ProjectSettings.has_setting("application/config/%s" % PROJECT_POST_TTS_COOLDOWN_KEY):
		var from_proj := int(ProjectSettings.get_setting("application/config/%s" % PROJECT_POST_TTS_COOLDOWN_KEY))
		return clampi(from_proj, POST_TTS_LISTEN_COOLDOWN_MS_MIN, POST_TTS_LISTEN_COOLDOWN_MS_MAX)
	return POST_TTS_LISTEN_COOLDOWN_MS_DEFAULT


static func _warn_trailing(raw: String, used: int, reason: String) -> void:
	var key := "%s|%d|%s" % [raw, used, reason]
	if key == _trailing_warn_key:
		return
	_trailing_warn_key = key
	push_warning(
		"YOUYOU_VAD_TRAILING_MS %s（%s），使用 %dms" % [reason, raw, used]
	)

const MAX_UNKNOWN_REASK := 1
