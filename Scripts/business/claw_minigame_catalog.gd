extends RefCounted
class_name ClawMinigameCatalog

## 抽取结果 id → 街机包里的小游戏场景。

const ENTRIES: Dictionary = {
	"plane": {
		"title": "霓虹空战",
		"scene": "res://街机小游戏/scenes/plane_game.tscn",
	},
	"miner": {
		"title": "深海寻宝",
		"scene": "res://街机小游戏/scenes/miner_game.tscn",
	},
	"balloon": {
		"title": "气球拉针",
		"scene": "res://街机小游戏/scenes/balloon_game.tscn",
	},
}


static func title_for(game_id: String) -> String:
	var row: Variant = ENTRIES.get(game_id, null)
	if row is Dictionary:
		return String((row as Dictionary).get("title", game_id))
	return game_id


static func scene_path(game_id: String) -> String:
	var row: Variant = ENTRIES.get(game_id, null)
	if row is Dictionary:
		return String((row as Dictionary).get("scene", ""))
	return ""


static func is_playable(game_id: String) -> bool:
	var path := scene_path(game_id)
	return path != "" and ResourceLoader.exists(path)


static func registered_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for key in ENTRIES.keys():
		out.append(String(key))
	return out
