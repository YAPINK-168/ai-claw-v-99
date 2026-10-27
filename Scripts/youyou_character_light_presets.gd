extends RefCounted
class_name YouyouCharacterLightPresets
## 2.5D 人物灯光预设。只描述角色受光，不改背景贴图与 UI。
## 在 YouyouPreviewVisualTuning 里切换 ACTIVE_PRESET 即可。

enum Id { SKY_DAY, NEON_ARCADE, WARM_ARCADE }

## 调整前的蓝天棚拍（便于恢复）。
static func sky_day() -> Dictionary:
	return {
		"id": "sky_day",
		"ambient_color": Color(0.78, 0.88, 0.98, 1.0),
		"ambient_energy": 0.42,
		"key_color": Color(1.0, 0.98, 0.94, 1.0),
		"key_energy": 0.56,
		"fill_color": Color(0.72, 0.86, 1.0, 1.0),
		"fill_energy": 0.30,
		"face_color": Color(1.0, 0.98, 0.96, 1.0),
		"face_energy": 0.14,
		"rim_color": Color(0.98, 0.95, 1.0, 1.0),
		"rim_energy": 0.08,
		"shadow_color": Color(0.05, 0.08, 0.12, 1.0),
		"shadow_strength": 0.28,
	}


## 霓虹电玩城：中性暖白主光、冷白补光、很弱的蓝紫轮廓。不用粉色环境光。
static func neon_arcade() -> Dictionary:
	return {
		"id": "neon_arcade",
		"ambient_color": Color(0.90, 0.92, 0.98, 1.0),
		"ambient_energy": 0.30,
		"key_color": Color(1.0, 0.961, 0.922, 1.0),
		"key_energy": 0.62,
		"fill_color": Color(0.898, 0.906, 1.0, 1.0),
		"fill_energy": 0.16,
		"face_color": Color(0.96, 0.97, 1.0, 1.0),
		"face_energy": 0.08,
		"rim_color": Color(0.773, 0.647, 1.0, 1.0),
		"rim_energy": 0.045,
		"shadow_color": Color(0.18, 0.10, 0.24, 1.0),
		"shadow_strength": 0.24,
	}


## 暖色电玩城的简单配置，未单独精调。
static func warm_arcade() -> Dictionary:
	return {
		"id": "warm_arcade",
		"ambient_color": Color(1.0, 0.86, 0.78, 1.0),
		"ambient_energy": 0.16,
		"key_color": Color(1.0, 0.90, 0.72, 1.0),
		"key_energy": 0.42,
		"fill_color": Color(1.0, 0.72, 0.62, 1.0),
		"fill_energy": 0.08,
		"face_color": Color(1.0, 0.95, 0.88, 1.0),
		"face_energy": 0.06,
		"rim_color": Color(1.0, 0.62, 0.45, 1.0),
		"rim_energy": 0.08,
		"shadow_color": Color(0.28, 0.12, 0.08, 1.0),
		"shadow_strength": 0.26,
	}


static func get_preset(preset_id: Id) -> Dictionary:
	match preset_id:
		Id.SKY_DAY:
			return sky_day()
		Id.WARM_ARCADE:
			return warm_arcade()
		_:
			return neon_arcade()
