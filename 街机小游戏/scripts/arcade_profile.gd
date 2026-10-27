extends Node
## PC 编辑器与 RK3288 APK 共用同一套「街机配置」判定

const SETTING := "application/config/simulate_rk3288"


func use_arcade_profile() -> bool:
	if OS.has_feature("android") or OS.has_feature("mobile"):
		return true
	return bool(ProjectSettings.get_setting(SETTING, true))


func profile_label() -> String:
	if OS.has_feature("android") or OS.has_feature("mobile"):
		return "device_apk"
	if use_arcade_profile():
		return "editor_arcade_sim"
	return "editor_high"


## 飞机大战：RK/街机走 Beat Hazard 式轻量 FX（少 Sprite、多 shader + 全屏节拍泛光）
func plane_low_fx() -> bool:
	return use_arcade_profile()


func plane_max_sparks() -> int:
	return 80 if plane_low_fx() else 288


func plane_use_shader_sky() -> bool:
	## 单块 ColorRect + fract 滚动；避免双 Sprite 各带一条 seal 横带
	return true
