class_name ArcadeGameCatalog
extends RefCounted
## 积分小游戏目录（代币正式名未定，暂称积分）

const TARGET_AVG_SCORE := 12 ## 普通玩家一局期望积分锚点
const MINIGAME_AUTO_RETURN_SEC := 15
const MINIGAME_RETURN_HINT := "\n%d 秒后自动返回 · 按抓取键立即返回" % MINIGAME_AUTO_RETURN_SEC

## id -> { title, card, scene, ready }
## 抓取失败后随机抽取这三款已开放游戏。
const GAMES: Array[Dictionary] = [
	{
		"id": "plane",
		"title": "霓虹空战",
		"card": "res://街机小游戏/assets/plane/neon/card_plane.png",
		"ready": true,
	},
	{
		"id": "miner",
		"title": "深海寻宝",
		"card": "res://街机小游戏/assets/minigame_cards/card_miner.png",
		"ready": true,
	},
	{
		"id": "balloon",
		"title": "气球拉针",
		"card": "res://街机小游戏/assets/roulette/preview_balloon.png",
		"ready": true,
	},
]


static func count() -> int:
	return GAMES.size()


static func get_game(index: int) -> Dictionary:
	return GAMES[posmod(index, GAMES.size())]


static func find_by_id(id: String) -> Dictionary:
	for g in GAMES:
		if str(g.get("id", "")) == id:
			return g
	return {}


static func ready_ids() -> Array[String]:
	var out: Array[String] = []
	for g in GAMES:
		if bool(g.get("ready", false)):
			out.append(str(g["id"]))
	return out
