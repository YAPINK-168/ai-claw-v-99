extends YouyouFacePresenter
class_name DoudouFacePresenter

## 兜兜 GLB 内嵌 morph：嘴型 A/E/O + 中文情绪 Eyes_/Mouth_。

## 沙盒/动作配音：嘴型 AEO 略轻于优优默认，便于与 Mouth_情绪 叠加。
const DOUDOU_VISEME_COEF := 0.55

const DOUDOU_VISEME_SHAPE_NAMES: Dictionary = {
	"a": "Mouth_嘴型A",
	"e": "Mouth_嘴型E",
	"i": "Mouth_嘴型E",
	"o": "Mouth_嘴型O",
	"u": "Mouth_嘴型O",
}

const DOUDOU_SPLIT_PROFILES: Dictionary = {
	"smile": {"label": "开心", "eyes": "Eyes_开心", "mouth": "Mouth_开心"},
	"laugh": {"label": "开心", "eyes": "Eyes_开心", "mouth": "Mouth_开心"},
	"grin": {"label": "坏笑", "eyes": "Eyes_坏笑", "mouth": "Mouth_坏笑"},
	"smug_smile": {"label": "坏笑", "eyes": "Eyes_坏笑", "mouth": "Mouth_坏笑"},
	"surprise": {"label": "惊讶", "eyes": "Eyes_惊讶", "mouth": "Mouth_惊讶"},
	"angry": {"label": "愤怒", "eyes": "Eyes_愤怒", "mouth": "Mouth_愤怒"},
	"sad": {"label": "委屈", "eyes": "Eyes_委屈", "mouth": "Mouth_委屈"},
}


func get_viseme_shape_name(viseme_id: String) -> String:
	var vid := viseme_id.to_lower()
	if DOUDOU_VISEME_SHAPE_NAMES.has(vid):
		return String(DOUDOU_VISEME_SHAPE_NAMES[vid])
	return super.get_viseme_shape_name(viseme_id)


func get_split_profile(emotion_id: String) -> Dictionary:
	if DOUDOU_SPLIT_PROFILES.has(emotion_id):
		return DOUDOU_SPLIT_PROFILES[emotion_id]
	return SPLIT_PROFILES.get(emotion_id, {})


func get_emotion_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	for eid in DOUDOU_SPLIT_PROFILES:
		ids.append(eid)
	ids.sort()
	return ids


func get_emotion_label(emotion_id: String) -> String:
	var p: Dictionary = get_split_profile(emotion_id)
	if p.is_empty():
		return super.get_emotion_label(emotion_id)
	return String(p.get("label", emotion_id))


func is_emotion_available(emotion_id: String) -> bool:
	var p: Dictionary = get_split_profile(emotion_id)
	if p.is_empty():
		return super.is_emotion_available(emotion_id)
	return _shape_exists_any_mesh(String(p.get("eyes", ""))) and _shape_exists_any_mesh(String(p.get("mouth", "")))


func is_viseme_participant_mesh(mesh: MeshInstance3D) -> bool:
	if super.is_viseme_participant_mesh(mesh):
		return true
	for vid in VISEME_IDS:
		if mesh.find_blend_shape_by_name(get_viseme_shape_name(vid)) >= 0:
			return true
	return false


func _build_split_shape_list() -> void:
	var keys: Dictionary = {}
	for eid in DOUDOU_SPLIT_PROFILES:
		var p: Dictionary = DOUDOU_SPLIT_PROFILES[eid]
		keys[String(p["eyes"])] = true
		keys[String(p["mouth"])] = true
	_split_shape_names = PackedStringArray(keys.keys())
	_split_shape_names.sort()


func _refresh_emotion_readiness() -> void:
	_emotion_ready.clear()
	for eid in DOUDOU_SPLIT_PROFILES:
		var p: Dictionary = DOUDOU_SPLIT_PROFILES[eid]
		_emotion_ready[eid] = _shape_exists_any_mesh(String(p["eyes"])) and _shape_exists_any_mesh(String(p["mouth"]))

