extends RefCounted
class_name VoiceTtsSplitConfig

## TTS 分句策略（逗号阈值等）。与 InviteListenConfig 同级：env → ProjectSettings → 默认。

const ENV_COMMA_MIN := "YOUYOU_TTS_COMMA_MIN_CHARS"
const ENV_RELAX_COMMA := "YOUYOU_TTS_RELAX_COMMA"
const PROJECT_COMMA_KEY := "voice/tts_comma_break_min_chars"
const COMMA_MIN_DEFAULT := 24
const COMMA_MIN_LEGACY := 8
const COMMA_MIN_CLAMP_LO := 8
const COMMA_MIN_CLAMP_HI := 120

static var _logged := false


static func comma_break_min_chars() -> int:
	return _resolve_comma_min()


static func comma_break_source() -> String:
	var raw := OS.get_environment(ENV_COMMA_MIN).strip_edges()
	if raw.is_valid_int():
		return "env_comma_min"
	var relax := OS.get_environment(ENV_RELAX_COMMA).strip_edges().to_lower()
	if relax in ["1", "true", "yes", "on"]:
		return "env_relax_comma"
	if relax in ["0", "false", "no", "off"]:
		return "env_relax_comma_off"
	if ProjectSettings.has_setting("application/config/%s" % PROJECT_COMMA_KEY):
		return "project"
	return "default"


static func log_effective_once() -> void:
	if _logged:
		return
	_logged = true
	var ms := comma_break_min_chars()
	print("tts_split_config comma_break_min_chars=%d source=%s" % [ms, comma_break_source()])


static func reset_log_for_tests() -> void:
	_logged = false


static func _resolve_comma_min() -> int:
	var raw := OS.get_environment(ENV_COMMA_MIN).strip_edges()
	if raw.is_valid_int():
		return clampi(int(raw), COMMA_MIN_CLAMP_LO, COMMA_MIN_CLAMP_HI)
	var relax := OS.get_environment(ENV_RELAX_COMMA).strip_edges().to_lower()
	if relax in ["1", "true", "yes", "on"]:
		return 24
	if relax in ["0", "false", "no", "off"]:
		return COMMA_MIN_LEGACY
	if ProjectSettings.has_setting("application/config/%s" % PROJECT_COMMA_KEY):
		var from_proj := int(ProjectSettings.get_setting("application/config/%s" % PROJECT_COMMA_KEY))
		return clampi(from_proj, COMMA_MIN_CLAMP_LO, COMMA_MIN_CLAMP_HI)
	return COMMA_MIN_DEFAULT
