extends RefCounted
class_name YouyouActionLipsyncApproved

## 已验收动作：权威 JSON + 显式待机/招揽白名单（禁止目录扫描扩池）。

const CONFIG_PATH := "res://config/youyou_action_lipsync_approved.json"

## 通用轻待机（无配音，投币前随机池 kind=general_light）
const GENERAL_LIGHT_WHITELIST: PackedStringArray = [
	"Basic_Idle01",
	"Basic_Idle02",
	"Basic_Idle04",
	"Basic_Idle05",
	"youyou_LookLeftRight",
]

## 角色专属待机（轻待机随机池 kind=exclusive_light）
const LIGHT_IDLE_WHITELIST: PackedStringArray = [
	"youyou_Basic_Idle01",
	"youyou_Basic_Idle02",
	"youyou_Basic_Idle04",
	"youyou_Hello_Idle05",
	"youyou_Hello_Idle08",
]

## 轻招揽随机池
const ATTRACT_WHITELIST: PackedStringArray = [
	"youyou_Hello_Idle01",
	"youyou_Hello_Idle02",
	"youyou_Hello_Idle03",
	"youyou_Hello_Idle05",
	"youyou_Hello_Idle06",
	"youyou_Hello_Idle07",
	"youyou_Hello_Idle08",
]

const CLIP_REGISTRY: Dictionary = {
	"Basic_Idle01": {
		"scene": "res://待机Animation/Basic_Idle01.glb",
		"source_anim": "Basic_Idle01",
	},
	"Basic_Idle02": {
		"scene": "res://待机Animation/Basic_Idle02.glb",
		"source_anim": "Basic_Idle02",
	},
	"Basic_Idle04": {
		"scene": "res://待机Animation/Basic_Idle04.glb",
		"source_anim": "Basic_Idle04",
	},
	"Basic_Idle05": {
		"scene": "res://待机Animation/Basic_Idle05.glb",
		"source_anim": "Basic_Idle05",
	},
	"youyou_LookLeftRight": {
		"scene": "res://柚柚新动作/柚柚操作动作2.0/3.0/5.0/youyou_LookLeftRight(1).glb",
		"source_anim": "Animation",
	},
	"youyou_Basic_Idle01": {
		"scene": "res://待机Animation/youyou_Basic_Idle01.001.glb",
		"source_anim": "youyou_Basic_Idle01_001",
	},
	"youyou_Basic_Idle02": {
		"scene": "res://待机Animation/youyou_Basic_Idle02.glb",
		"source_anim": "youyou_Basic_Idle02",
	},
	"youyou_Basic_Idle03": {
		"scene": "res://待机Animation/youyou_Basic_Idle03.glb",
		"source_anim": "youyou_Basic_Idle03",
	},
	"youyou_Basic_Idle04": {
		"scene": "res://待机Animation/youyou_Basic_Idle04.glb",
		"source_anim": "youyou_Basic_Idle04",
	},
	"youyou_Basic_Idle05": {
		"scene": "res://待机Animation/youyou_Basic_Idle05.glb",
		"source_anim": "youyou_Basic_Idle05",
	},
	"youyou_Hello_Idle01": {
		"scene": "res://待机Animation/youyou_Hello_Idle01.glb",
		"source_anim": "youyou_Hello_Idle01",
	},
	"youyou_Hello_Idle02": {
		"scene": "res://待机Animation/youyou_Hello_Idle02.glb",
		"source_anim": "youyou_Hello_Idle02",
	},
	"youyou_Hello_Idle03": {
		"scene": "res://待机Animation/youyou_Hello_Idle03.glb",
		"source_anim": "youyou_Hello_Idle03",
	},
	"youyou_Hello_Idle05": {
		"scene": "res://待机Animation/youyou_Hello_Idle05.glb",
		"source_anim": "youyou_Hello_Idle05",
	},
	"youyou_Hello_Idle06": {
		"scene": "res://待机Animation/youyou_Hello_Idle06.glb",
		"source_anim": "youyou_Hello_Idle06",
	},
	"youyou_Hello_Idle07": {
		"scene": "res://待机Animation/youyou_Hello_Idle07.glb",
		"source_anim": "youyou_Hello_Idle07",
	},
	"youyou_Hello_Idle08": {
		"scene": "res://待机Animation/youyou_Hello_Idle08.glb",
		"source_anim": "youyou_Hello_Idle08",
	},
}

static var _entries: Dictionary = {}
static var _loaded := false


static func reload() -> void:
	_loaded = false
	_entries = {}
	load_config()


static func load_config() -> bool:
	if _loaded:
		return not _entries.is_empty()
	_loaded = true
	_entries = {}
	if not ResExists.path(CONFIG_PATH):
		push_error("验收配置缺失：" + CONFIG_PATH)
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not (parsed is Dictionary):
		push_error("验收配置 JSON 无效")
		return false
	var entries: Variant = (parsed as Dictionary).get("entries", {})
	if entries is Dictionary:
		_entries = entries as Dictionary
	return true


static func get_general_light_whitelist() -> PackedStringArray:
	return GENERAL_LIGHT_WHITELIST.duplicate()


static func get_light_idle_whitelist() -> PackedStringArray:
	return LIGHT_IDLE_WHITELIST.duplicate()


static func get_attract_whitelist() -> PackedStringArray:
	return ATTRACT_WHITELIST.duplicate()


static func all_whitelisted_action_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	for id in GENERAL_LIGHT_WHITELIST:
		if id not in ids:
			ids.append(id)
	for id in LIGHT_IDLE_WHITELIST:
		if id not in ids:
			ids.append(id)
	for id in ATTRACT_WHITELIST:
		if id not in ids:
			ids.append(id)
	return ids


static func is_general_light(action_id: String) -> bool:
	return action_id in GENERAL_LIGHT_WHITELIST


static func is_whitelisted(action_id: String) -> bool:
	return (
		is_general_light(action_id)
		or action_id in LIGHT_IDLE_WHITELIST
		or action_id in ATTRACT_WHITELIST
	)


static func pool_for(action_id: String) -> String:
	if is_general_light(action_id):
		return "general_light"
	if action_id in LIGHT_IDLE_WHITELIST:
		return "exclusive_light"
	if action_id in ATTRACT_WHITELIST:
		return "attract"
	return ""


## 美术表「通用轻待机」：空白格保持默认 smile，有标注的在此覆盖。
const GENERAL_LIGHT_EMOTION: Dictionary = {
	"Basic_Idle02": "min_smile",
	"Basic_Idle05": "yawn",
}


static func general_light_default_params(action_id: String = "") -> Dictionary:
	var emotion_id := "smile"
	if GENERAL_LIGHT_EMOTION.has(action_id):
		emotion_id = String(GENERAL_LIGHT_EMOTION[action_id])
	return {
		"manual_acceptance_status": "approved",
		"audio_path": "",
		"action_speed": 1.0,
		"emotion_id": emotion_id,
		"emotion_start_offset": 0.0,
		"emotion_lead_time": 0.0,
		"emotion_blend_duration": 0.35,
		"mouth_emotion_weight": 0.35,
		"viseme_weight": 0.75,
		"mouth_release_duration": 0.15,
		"idle_expression_return_duration": 0.5,
		"audio_start_offset": 86400.0,
	}


static func validate_general_light_entry(action_id: String) -> Dictionary:
	var errors: PackedStringArray = []
	if not is_general_light(action_id):
		errors.append("不在通用轻待机白名单")
		return {"ok": false, "errors": errors}
	if not CLIP_REGISTRY.has(action_id):
		errors.append("无 clip 注册信息")
	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"params": general_light_default_params(action_id),
	}


static func validate_for_play(action_id: String) -> Dictionary:
	if is_general_light(action_id):
		return validate_general_light_entry(action_id)
	return validate_entry(action_id)


static func get_params(action_id: String) -> Dictionary:
	load_config()
	var raw: Variant = _entries.get(action_id, {})
	if raw is Dictionary:
		return (raw as Dictionary).duplicate(true)
	return {}


static func validate_entry(action_id: String) -> Dictionary:
	var errors: PackedStringArray = []
	if is_general_light(action_id):
		return validate_general_light_entry(action_id)
	if not is_whitelisted(action_id):
		errors.append("不在白名单")
		return {"ok": false, "errors": errors}
	load_config()
	var params := get_params(action_id)
	if params.is_empty():
		errors.append("验收配置无条目")
	if String(params.get("manual_acceptance_status", "")) != "approved":
		errors.append("未标记 approved")
	var audio := String(params.get("audio_path", ""))
	if audio == "" or not ResExists.path(audio):
		errors.append("配音缺失：" + audio)
	if not CLIP_REGISTRY.has(action_id):
		errors.append("无 clip 注册信息")
	return {"ok": errors.is_empty(), "errors": errors, "params": params}


static func get_clip_registry(action_id: String) -> Dictionary:
	if CLIP_REGISTRY.has(action_id):
		return (CLIP_REGISTRY[action_id] as Dictionary).duplicate()
	return {}


static func take_animation_clip(action_id: String) -> Animation:
	var reg := get_clip_registry(action_id)
	if reg.is_empty():
		return null
	var scene_path := String(reg.get("scene", ""))
	var source_anim := String(reg.get("source_anim", action_id))
	var packed := load(scene_path) as PackedScene
	if packed == null:
		return null
	var instance := packed.instantiate()
	var source := instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if source == null or not source.has_animation(source_anim):
		instance.free()
		return null
	var clip := (source.get_animation(source_anim) as Animation).duplicate(true) as Animation
	instance.free()
	return clip
