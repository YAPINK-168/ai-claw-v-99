extends RefCounted
## Local account points and redeemed ticket balance, separate from board tokens.
const RATE := 1000
var balance := 0
var tickets := 0
var credits: Dictionary = {}
var exchanges: Dictionary = {}
var save_path := "user://arcade_points_wallet.cfg"
var persistence_enabled := true

func restore() -> void:
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return
	balance = maxi(0, int(config.get_value("wallet", "points", 0)))
	tickets = maxi(0, int(config.get_value("wallet", "tickets", 0)))
	credits = config.get_value("wallet", "credits", {})
	exchanges = config.get_value("wallet", "exchanges", {})

func _save() -> bool:
	if not persistence_enabled:
		return true
	var config := ConfigFile.new()
	config.set_value("wallet", "points", balance)
	config.set_value("wallet", "tickets", tickets)
	config.set_value("wallet", "credits", credits)
	config.set_value("wallet", "exchanges", exchanges)
	return config.save(save_path) == OK

func credit(round_id: String, amount: int) -> Dictionary:
	if round_id.is_empty() or amount < 0:
		return {"ok":false,"error":"本局积分无效"}
	if credits.has(round_id):
		var duplicate: Dictionary = credits[round_id].duplicate()
		duplicate["duplicate"] = true
		return duplicate
	var receipt := {"ok":true,"id":round_id,"earned":amount,"before":balance,"after":balance + amount}
	balance += amount
	credits[round_id] = receipt
	if not _save():
		balance -= amount
		credits.erase(round_id)
		return {"ok":false,"error":"积分保存失败，请重试"}
	return receipt

func quote() -> Dictionary:
	var count := balance / RATE
	return {"points":balance,"count":count,"cost":count * RATE,"remaining":balance % RATE,"tickets":tickets}

func redeem(exchange_id: String, expected_points: int) -> Dictionary:
	if exchanges.has(exchange_id):
		var duplicate: Dictionary = exchanges[exchange_id].duplicate()
		duplicate["duplicate"] = true
		return duplicate
	if exchange_id.is_empty() or expected_points != balance:
		return {"ok":false,"error":"账户积分已更新，请确认最新数量"}
	var offer := quote()
	if int(offer.count) <= 0:
		return {"ok":false,"error":"账户积分不足1000"}
	var receipt := {"ok":true,"count":offer.count,"cost":offer.cost,"before":balance,"after":offer.remaining,"tickets":tickets + int(offer.count)}
	balance = int(offer.remaining)
	tickets = int(receipt.tickets)
	exchanges[exchange_id] = receipt
	if not _save():
		balance = int(receipt.before)
		tickets -= int(receipt.count)
		exchanges.erase(exchange_id)
		return {"ok":false,"error":"兑换保存失败，积分未扣除"}
	return receipt
