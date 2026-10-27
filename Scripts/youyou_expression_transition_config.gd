extends RefCounted
class_name YouyouExpressionTransitionConfig

## 情绪表情过渡时长（秒）：集中配置，业务脚本可显式 override。

const EMOTION_IDS: PackedStringArray = [
	"smile", "surprise", "laugh", "angry", "sad", "grin",
	"think", "sleepy", "yawn", "min_smile", "mid_smile", "whistle", "puff",
	"bite_wink", "smug_smile", "serious",
]

const TO_SURPRISE := 0.15
const JOY_CHAIN := 0.26
const SLOW_AFFECT := 0.55
const ANGRY_SERIOUS := 0.30
const RESTORE_BASE := 0.40
const NEUTRAL_SWITCH := 0.45

const DEFAULT_PER_EMOTION: Dictionary = {
	"smile": 0.45,
	"surprise": 0.15,
	"laugh": 0.26,
	"angry": 0.30,
	"sad": 0.55,
	"grin": 0.40,
	"think": 0.50,
	"sleepy": 0.55,
	"yawn": 0.45,
	"min_smile": 0.38,
	"mid_smile": 0.30,
	"whistle": 0.35,
	"puff": 0.28,
	"bite_wink": 0.25,
	"smug_smile": 0.35,
	"serious": 0.30,
}

const JOY_GROUP: PackedStringArray = [
	"smile", "laugh", "grin", "min_smile", "mid_smile", "smug_smile",
]

const SLOW_GROUP: PackedStringArray = ["sleepy", "yawn", "think"]


static func resolve_emotion_duration(from_id: String, to_id: String, explicit: float = -1.0) -> float:
	if explicit >= 0.0:
		return explicit
	if to_id.is_empty() or to_id not in EMOTION_IDS:
		return NEUTRAL_SWITCH
	if from_id == to_id:
		return 0.0
	if to_id == "surprise":
		return TO_SURPRISE
	if to_id == "sad" or to_id in SLOW_GROUP:
		return SLOW_AFFECT
	if to_id == "angry" or to_id == "serious":
		return ANGRY_SERIOUS
	if to_id == "smile" and from_id != "" and from_id != "smile":
		return RESTORE_BASE
	if from_id in JOY_GROUP and to_id in JOY_GROUP:
		return JOY_CHAIN
	return float(DEFAULT_PER_EMOTION.get(to_id, NEUTRAL_SWITCH))


static func resolve_gaze_duration(_from_gaze: String, _to_gaze: String, explicit: float = -1.0) -> float:
	if explicit >= 0.0:
		return explicit
	return 0.22
