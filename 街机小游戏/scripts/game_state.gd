extends Node
## 全局状态：账户虚拟代币、免费抓娃娃次数（可与真实娃娃机主控对接）
## 代币仅累计入账，不在此兑换抓取次数；后续扩展消费场景

signal tokens_changed(total: int)
signal free_plays_changed(count: int)
signal free_play_earned(reason: String)

var total_tokens: int = 0 ## 账户虚拟货币（可扩展用途）
var free_claw_plays: int = 0 ## 红球等途径获得的免费抓取
signal account_points_changed(points: int, tickets: int)
const PointsWallet := preload("res://街机小游戏/scripts/points_wallet.gd")
var points_wallet := PointsWallet.new()
var _points_sequence := 0
var _points_result: CanvasLayer

func _ready() -> void:
	points_wallet.restore()

func begin_points_round(game_id: String) -> String:
	_points_sequence += 1
	return "%s:%s:%d:%d" % [game_id, str(Time.get_unix_time_from_system()), Time.get_ticks_usec(), _points_sequence]

func finish_points_round(owner_game: Node, game_id: String, round_id: String, score: int) -> Dictionary:
	var receipt: Dictionary = points_wallet.credit(round_id, maxi(0, score))
	if bool(receipt.get("duplicate", false)):
		return receipt
	account_points_changed.emit(points_wallet.balance, points_wallet.tickets)
	if _points_result == null:
		_points_result = load("res://街机小游戏/scripts/account_settlement.gd").new()
		get_tree().root.add_child(_points_result)
	_points_result.open_result(owner_game, game_id, receipt, round_id)
	return receipt

func points_result_is_open() -> bool:
	return is_instance_valid(_points_result) and _points_result.is_open

func points_result_board_key(mask: int) -> void:
	if points_result_is_open():
		_points_result.on_board_key(mask)


func add_tokens(amount: int) -> void:
	if amount <= 0:
		return
	total_tokens += amount
	tokens_changed.emit(total_tokens)


func add_free_play(count: int = 1, reason: String = "奖励") -> void:
	if count <= 0:
		return
	free_claw_plays += count
	free_plays_changed.emit(free_claw_plays)
	free_play_earned.emit(reason)


func consume_free_play() -> bool:
	if free_claw_plays <= 0:
		return false
	free_claw_plays -= 1
	free_plays_changed.emit(free_claw_plays)
	return true
