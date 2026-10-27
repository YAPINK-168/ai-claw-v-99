extends Node2D
## Live, resolution-independent HUD matching the approved cyan/magenta concept.
const CYAN := Color("49E7FF")
const PINK := Color("D65CFF")
const GOLD := Color("FFF16D")
const INK := Color(0.025, 0.045, 0.15, 0.88)
var _logic: PlaneLogic
var _view: Node2D
var _font: Font

func sync_state(logic: PlaneLogic, view: Node2D, font: Font) -> void:
	_logic = logic
	_view = view
	_font = font if font else ThemeDB.fallback_font
	queue_redraw()

func _panel(rect: Rect2) -> void:
	var x := rect.position.x
	var y := rect.position.y
	var w := rect.size.x
	var h := rect.size.y
	var pts := PackedVector2Array([Vector2(x+10,y),Vector2(x+w,y),Vector2(x+w-5,y+h-10),Vector2(x+w-15,y+h),Vector2(x,y+h),Vector2(x,y+10),Vector2(x+10,y)])
	draw_colored_polygon(pts, INK)
	draw_polyline(pts, Color(0.34,0.46,0.85,0.75), 1.0, true)
	draw_polyline(PackedVector2Array([Vector2(x,y+16),Vector2(x,y+10),Vector2(x+10,y),Vector2(x+w*0.46,y)]), CYAN, 2.5, true)
	draw_polyline(PackedVector2Array([Vector2(x+w,y+h-18),Vector2(x+w-5,y+h-10),Vector2(x+w-15,y+h),Vector2(x+w*0.53,y+h)]), PINK, 2.5, true)

func _text(at: Vector2, text: String, px: int, color: Color = Color.WHITE) -> void:
	draw_string_outline(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, 3, Color(0.015,0.025,0.1,0.85))
	draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)

func _number(value: int) -> String:
	var raw := str(maxi(0, value))
	var result := ""
	for i in raw.length():
		if i > 0 and (raw.length()-i) % 3 == 0:
			result += ","
		result += raw[i]
	return result

func pickup_label_position(sprite: Sprite2D, text: String) -> Vector2:
	var bottom := sprite.get_global_transform_with_canvas() * Vector2(0, sprite.texture.get_height() * .5)
	var at := bottom * Vector2(1280,720) / get_viewport_rect().size
	var width := _font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
	return at + Vector2(-width * .5, 6.0 + _font.get_ascent(13))

func _heart(center: Vector2, live: bool) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var t := TAU * float(i) / 32.0
		pts.append(center + Vector2(16.0*pow(sin(t),3), -(13.0*cos(t)-5.0*cos(2.0*t)-2.0*cos(3.0*t)-cos(4.0*t))) * 0.58)
	draw_colored_polygon(pts, Color("FF68CC") if live else Color("343052"))
	pts.append(pts[0])
	draw_polyline(pts, Color("FFA0ED") if live else Color("656080"), 1.2, true)

func _draw() -> void:
	if _logic == null or _font == null:
		return
	var vp := get_viewport_rect().size
	draw_set_transform(Vector2.ZERO, 0.0, vp / Vector2(1280,720))
	_panel(Rect2(16,18,174,84))
	_text(Vector2(28,43), "百万大奖", 19)
	_text(Vector2(27,84), _number(_view.arcade_jackpot), 34, GOLD)
	_panel(Rect2(16,114,174,80))
	_text(Vector2(28,139), "本机奖励", 19)
	_text(Vector2(28,178), _number(_view.arcade_local_bonus), 32, CYAN)
	_panel(Rect2(16,206,174,68))
	_text(Vector2(28,230), "下一次：", 17)
	_text(Vector2(28,256), _view.arcade_next_tip.trim_prefix("下一次："), 17)
	_panel(Rect2(16,286,174,75))
	_text(Vector2(28,311), "投币", 19)
	_text(Vector2(28,345), "%02d/%02d" % [_view.arcade_coin_in, _view.arcade_coin_need], 28, CYAN)
	_panel(Rect2(1086,18,178,50))
	_text(Vector2(1098,48), "得分", 19)
	var score_text := _number(_logic.score)
	var score_size := 29 if score_text.length() < 8 else 23
	var sw := _font.get_string_size(score_text, HORIZONTAL_ALIGNMENT_LEFT, -1, score_size).x
	_text(Vector2(1250-sw,52), score_text, score_size, GOLD)
	_panel(Rect2(1108,78,156,40))
	_text(Vector2(1119,104), "生命", 18)
	for i in 3:
		_heart(Vector2(1187+i*25,99), i < _logic.hp)
	_panel(Rect2(1204,146,59,326))
	var fill := clampf(float(_logic.combo) / float(PlaneLogic.COMBO_TIER_FENGSHEN),0.0,1.0)
	var lit := maxi(1, ceili(fill*10.0)) if _logic.combo > 0 else 0
	for i in 10:
		var cell := StyleBoxFlat.new()
		cell.bg_color = CYAN if i < lit else Color("25254C")
		cell.border_color = Color("86F1FF") if i < lit else Color("60619E")
		cell.set_border_width_all(1)
		cell.set_corner_radius_all(4)
		draw_style_box(cell, Rect2(1217,162+i*29,33,23))
	_panel(Rect2(1175,484,88,64))
	_text(Vector2(1187,508), "连击", 18)
	_text(Vector2(1181,538), "×%d" % _logic.combo, 29, GOLD)
	_panel(Rect2(384,664,512,34))
	_text(Vector2(399,687), "火力 %d倍 / %d倍" % [_logic.power_multiplier(),PlaneLogic.POWER_MAX], 17)
	for i in PlaneLogic.POWER_MAX:
		draw_rect(Rect2(536+i*42,674,36,14), CYAN if i < _logic.power_multiplier() else Color("28274C"))
	_panel(Rect2(16,656,174,42))
	_text(Vector2(29,686), "霓虹空战", 24)
	var status := ""
	if _logic.shield:
		status += "护盾  "
	if _logic.laser_t > 0.0:
		status += "激光 %.1fs  " % _logic.laser_t
	if _logic.super_t > 0.0:
		status += "超级武器 %.1fs  " % _logic.super_t
	status += "炸弹 ×%d" % _logic.bombs
	_text(Vector2(390,652), status, 15, CYAN)
	var names := ["火力+1档","护盾","护盾","炸弹","生命"]
	for i in _logic.items.size():
		var item: Dictionary = _logic.items[i]
		if not bool(item.get("live",false)):
			continue
		if i >= _view._item_pool.size():
			continue
		var sprite: Sprite2D = _view._item_pool[i]
		if not sprite.visible or sprite.texture == null:
			continue
		var title: String = names[clampi(int(item["kind"]),0,4)]
		_text(pickup_label_position(sprite,title),title,13,CYAN)
