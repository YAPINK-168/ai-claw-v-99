extends CanvasLayer
## Shared result / account / ticket UI for the three roulette minigames.
const NAMES := {"plane":"霓虹空战","miner":"深海寻宝","balloon":"气球拉针"}
const GOLD := Color("FFE184")
const CREAM := Color("FFF5D8")
const INK := Color("623819")
var is_open := false
var stage := "score"
var receipt: Dictionary = {}
var offer: Dictionary = {}
var exchange: Dictionary = {}
var game_id := ""
var round_id := ""
var owner_game: Node
var _view: Control
var _frame: Texture2D
var _background: Texture2D
var _font: Font
var _age := 0.0
var _stage_age := 0.0
var _input_cooldown := 0.0
var _selected := 1
var _previous_mask := 0
var _hidden_layers: Array[Node] = []
var _owner_process_mode := Node.PROCESS_MODE_INHERIT
var _legacy_hold_left := 0.0

class ResultView extends Control:
	var host: Node
	func _draw() -> void:
		host.render(self)

func _ready() -> void:
	layer = 65
	name = "AccountSettlement"
	_frame = load("res://街机小游戏/assets/account_settlement/frame.png")
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC"])
	font.font_weight = 800
	_font = font
	_view = ResultView.new()
	_view.host = self
	_view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_view)
	BoardLink.board_key.connect(on_board_key)
	visible = false
	set_process(false)
	set_process_input(false)

func open_result(game: Node, id: String, result: Dictionary, key: String) -> void:
	if is_open:
		return
	is_open = true
	owner_game = game
	game_id = id
	round_id = key
	receipt = result
	exchange = {}
	stage = "score" if bool(result.get("ok", false)) else "error"
	_age = 0.0
	_stage_age = 0.0
	_input_cooldown = .4
	_selected = 1
	_previous_mask = 0
	_hidden_layers.clear()
	_legacy_hold_left = 3.0 if game_id in ["miner", "balloon"] else 0.0
	_owner_process_mode = owner_game.process_mode
	# Let the old game finish its end callback, then hide its HUD before capture.
	await get_tree().process_frame
	if game_id == "plane":
		# Preserve the original five-second ticket burst/gather before the new UI.
		while is_open and is_instance_valid(owner_game) and owner_game._settle_roll_active:
			await get_tree().process_frame
	elif game_id == "miner":
		# The original bubble finale must finish and reveal its score/rank/prizes.
		while is_open and is_instance_valid(owner_game) and is_instance_valid(owner_game._inner) and not owner_game._inner._hud.can_restart():
			await get_tree().process_frame
	# Keep the original result readable before appending the account result.
	while is_open and is_instance_valid(owner_game) and _legacy_hold_left > 0.0:
		await get_tree().process_frame
		_legacy_hold_left -= get_process_delta_time()
	if not is_open or not is_instance_valid(owner_game):
		return
	_hide_game_ui(owner_game)
	if game_id == "plane":
		owner_game._stop_settle_roll()
		for hud in [owner_game.view._neon_hud, owner_game.view._neon_boss_hud]:
			if is_instance_valid(hud) and hud.visible:
				_hidden_layers.append(hud)
				hud.visible = false
	owner_game.process_mode = Node.PROCESS_MODE_DISABLED
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
	if not is_open:
		return
	if DisplayServer.get_name() != "headless":
		_background = ImageTexture.create_from_image(get_viewport().get_texture().get_image())
	BoardLink.take_control()
	visible = true
	set_process(true)
	set_process_input(true)
	_view.queue_redraw()

func _hide_game_ui(node: Node) -> void:
	for child in node.get_children():
		if child is CanvasLayer and child.layer >= 0 and child.visible:
			_hidden_layers.append(child)
			child.visible = false
		elif child.name == "CarnivalHud" and child is CanvasItem and child.visible:
			_hidden_layers.append(child)
			child.visible = false
		_hide_game_ui(child)

func _process(delta: float) -> void:
	_age += delta
	_stage_age += delta
	_input_cooldown = maxf(0.0, _input_cooldown - delta)
	if stage == "score" and _stage_age >= 2.8:
		_show_exchange()
	_view.queue_redraw()

func _show_exchange() -> void:
	stage = "exchange"
	offer = GameState.points_wallet.quote()
	_stage_age = 0.0
	_input_cooldown = .3
	_selected = 1
	_view.queue_redraw()

func activate(primary: bool) -> void:
	if not is_open or not visible or _input_cooldown > 0.0:
		return
	_input_cooldown = .3
	if stage == "score":
		_show_exchange()
	elif stage == "exchange":
		if not primary or int(offer.count) <= 0:
			close_result()
			return
		exchange = GameState.points_wallet.redeem(round_id + ":tickets", int(offer.points))
		if bool(exchange.get("ok", false)):
			stage = "success"
			GameState.account_points_changed.emit(GameState.points_wallet.balance, GameState.points_wallet.tickets)
		else:
			offer = GameState.points_wallet.quote()
		_stage_age = 0.0
	elif stage == "success":
		close_result()
	elif stage == "error":
		var retry: Dictionary = GameState.points_wallet.credit(round_id, int(owner_game.session_points) if game_id != "balloon" else int(owner_game._score))
		receipt = retry
		if bool(retry.get("ok", false)):
			GameState.account_points_changed.emit(GameState.points_wallet.balance, GameState.points_wallet.tickets)
			stage = "score"
			_age = 0.0
			_stage_age = 0.0
	_view.queue_redraw()

func close_result() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	set_process(false)
	set_process_input(false)
	BoardLink.release_control()
	for node in _hidden_layers:
		if is_instance_valid(node):
			node.visible = true
	_hidden_layers.clear()
	if is_instance_valid(owner_game):
		owner_game.process_mode = _owner_process_mode
		owner_game.stop_and_hide()
		owner_game.ask_return_hub.emit()
	owner_game = null
	_background = null

func on_board_key(mask: int) -> void:
	if not is_open:
		return
	var edge := mask & ~_previous_mask
	_previous_mask = mask
	if edge & BoardLink.KEY_LEFT:
		_selected = 0
	if edge & BoardLink.KEY_RIGHT:
		_selected = 1
	if edge & BoardLink.KEY_ENTER:
		activate(_selected == 1)
	_view.queue_redraw()

func _input(event: InputEvent) -> void:
	if not is_open or not visible:
		return
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode in [KEY_LEFT, KEY_A]:
				_selected = 0
			elif event.keycode in [KEY_RIGHT, KEY_D]:
				_selected = 1
			elif event.keycode in [KEY_O, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
				activate(_selected == 1)
		get_viewport().set_input_as_handled()
	elif (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
		var position: Vector2 = event.position
		var vp := get_viewport().get_visible_rect().size
		var scale := minf(vp.x / 1280.0, vp.y / 720.0)
		position = (position - (vp - Vector2(1280,720) * scale) * .5) / scale
		if Rect2(440,532,310,108).has_point(position):
			activate(false)
		elif Rect2(775,532,373,108).has_point(position):
			activate(true)
		get_viewport().set_input_as_handled()

func _text(canvas: Control, rect: Rect2, text: String, px: int, color: Color = CREAM, outline: int = 3) -> void:
	while px > 11 and _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > rect.size.x:
		px -= 1
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var at := Vector2(rect.get_center().x - width * .5, rect.get_center().y + (_font.get_ascent(px) - _font.get_descent(px)) * .5)
	if outline > 0:
		canvas.draw_string_outline(_font, at + Vector2(0,1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, outline, Color("48301D"))
	canvas.draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)

func render(canvas: Control) -> void:
	if not is_open:
		return
	var viewport := get_viewport().get_visible_rect().size
	if _background:
		canvas.draw_texture_rect(_background, Rect2(Vector2.ZERO,viewport), false)
	canvas.draw_rect(Rect2(Vector2.ZERO,viewport), Color(0.015,0.025,0.06,.22))
	var factor := minf(viewport.x / 1280.0, viewport.y / 720.0)
	canvas.draw_set_transform((viewport - Vector2(1280,720)*factor)*.5,0,Vector2.ONE*factor)
	canvas.draw_texture_rect(_frame, Rect2(0,0,1280,720),false)
	_text(canvas,Rect2(55,83,220,61),"账户信息",32,GOLD,4)
	_text(canvas,Rect2(52,312,220,40),"账户积分",28)
	var current := GameState.points_wallet.balance
	if stage == "score":
		var progress := smoothstep(0.0,1.0,clampf((_age-.5)/1.2,0,1))
		current = int(round(lerpf(float(receipt.get("before",0)),float(receipt.get("after",0)),progress)))
	_text(canvas,Rect2(40,356,246,66),str(current),52,GOLD,4)
	var status := "本局 +%d 已入账" % int(receipt.get("earned",0))
	if stage == "error":
		status = "本局积分待保存"
	if stage == "success":
		status = "已兑换 %d 张彩票" % int(exchange.count)
	_text(canvas,Rect2(58,440,210,34),status,19)
	_text(canvas,Rect2(59,531,214,45),"小游戏积分可累计",20,INK,0)
	var title: String = {"score":"游戏结算","exchange":"彩票兑换","success":"兑换成功","error":"积分保存失败"}.get(stage,"游戏结算")
	_text(canvas,Rect2(606,140,342,75),title,40,GOLD,4)
	_text(canvas,Rect2(553,222,420,35),NAMES.get(game_id, "小游戏"),24)
	var subtitle := "本局获得"
	var main := "+%d" % int(round(int(receipt.get("earned",0)) * smoothstep(0,1,clampf(_age/.65,0,1))))
	var summary := "账户积分  %d → %d" % [int(receipt.get("before",0)),int(receipt.get("after",0))]
	var note := "积分已累加到账户，可继续游戏累计"
	var left := "兑换彩票"
	var right := "继续"
	if stage == "exchange":
		subtitle = "可兑换彩票"
		main = "%d 张" % int(offer.count)
		summary = "扣除 %d 积分　剩余 %d 积分" % [int(offer.cost), int(offer.remaining)]
		note = "兑换比例：1000 积分 = 1 张彩票"
		left = "保留积分"
		right = "兑换" if int(offer.count) > 0 else "返回"
		if int(offer.count) <= 0:
			summary = "还差 %d 积分即可兑换 1 张" % (1000 - int(offer.points))
		if not exchange.is_empty() and not bool(exchange.get("ok",true)):
			note = str(exchange.error)
	elif stage == "success":
		subtitle = "获得账户彩票"
		main = "+%d 张" % int(exchange.count)
		summary = "剩余积分 %d　累计彩票 %d 张" % [int(exchange.after),int(exchange.tickets)]
		note = "彩票已存入账户，剩余积分继续累计"
		left = "已兑换"
		right = "返回"
	elif stage == "error":
		subtitle = "积分尚未入账"
		main = "请重试"
		summary = str(receipt.get("error","保存失败"))
		note = "请按 O 重新保存本局积分"
		left = "等待重试"
		right = "重试"
	_text(canvas,Rect2(525,263,500,38),subtitle,30)
	_text(canvas,Rect2(480,302,600,93),main,82,GOLD,4)
	_text(canvas,Rect2(465,425,655,46),summary,27)
	_text(canvas,Rect2(455,488,665,32),note,22)
	_text(canvas,Rect2(540,549,184,50),left,27,INK,0)
	_text(canvas,Rect2(896,550,218,50),"按 O "+right,29,CREAM,3)
	var selected := Rect2(437,532,311,103) if _selected == 0 else Rect2(777,532,371,103)
	var focus_x := selected.get_center().x
	canvas.draw_circle(Vector2(focus_x,647),3.2,Color(1,.88,.44,.65+.25*sin(_age*4)))
	if stage == "score" and _age > .65 and _age < 1.85:
		for i in 6:
			var t := clampf((_age-.65-float(i)*.07)/.75,0,1)
			if t <= 0 or t >= 1:
				continue
			var p := Vector2(700,350).lerp(Vector2(165,370),t) + Vector2(0,-sin(t*PI)*85)
			canvas.draw_circle(p,9,GOLD)
			canvas.draw_circle(p,6,Color("F5B825"))
	canvas.draw_set_transform(Vector2.ZERO)
