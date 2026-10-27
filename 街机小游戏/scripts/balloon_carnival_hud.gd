extends Node2D
const DIR := "res://街机小游戏/assets/balloon/carnival/"
const INK := Color("68170E")
var _game: Node
var _font: Font
var _skins: Dictionary = {}
var _last_rects: Dictionary = {}
const PROGRESS_STAR := preload("res://街机小游戏/assets/balloon/carnival/prize_star_v2.png")
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei","Noto Sans CJK SC"])
	font.font_weight = 800
	_font = font
	for key in ["time","score","target","speech","pull","progress"]:
		var tex := load(DIR+"ui_"+key+".png") as Texture2D
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(tex.get_image().get_used_rect())
		_skins[key] = atlas
func sync_state(game: Node) -> void:
	_game = game
	visible = game.visible
	queue_redraw()
func fitted(key: String,box: Rect2) -> Rect2:
	var tex: Texture2D = _skins[key]
	var factor := minf(box.size.x/tex.get_width(),box.size.y/tex.get_height())
	var size := tex.get_size()*factor
	return Rect2(box.get_center()-size*0.5,size)
func skin(key: String,box: Rect2) -> Rect2:
	var rect := fitted(key,box)
	_last_rects[key] = rect
	draw_texture_rect(_skins[key],rect,false)
	return rect
func inner(rect: Rect2,area: Rect2) -> Rect2:
	return Rect2(rect.position+area.position*rect.size,area.size*rect.size)
func text_center(rect: Rect2,value: String,px: int,color: Color=INK,outline: int=0) -> void:
	while px>10 and _font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x>rect.size.x:
		px-=1
	var w := _font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x
	var at := Vector2(rect.get_center().x-w*0.5,rect.get_center().y+(_font.get_ascent(px)-_font.get_descent(px))*0.5)
	if outline>0:
		draw_string_outline(_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,px,outline,Color("6E1722"))
	draw_string(_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,px,color)
func star(center: Vector2,radius: float,on: bool) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI/2+float(i)*PI/5
		pts.append(center+Vector2(cos(a),sin(a))*(radius if i%2==0 else radius*0.48))
	draw_colored_polygon(pts,Color("FFE357") if on else Color("996561"))
	pts.append(pts[0])
	draw_polyline(pts,Color("FFF6C9"),2.0,true)
func arcade_button(center: Vector2,radius: float) -> void:
	draw_circle(center+Vector2(0,3),radius+3,Color("8D2C18"))
	draw_circle(center,radius+2,Color("FFDA70"))
	draw_circle(center,radius-1,Color("F74B48"))
	draw_arc(center,radius-4,PI*1.12,PI*1.82,24,Color("FFD1B9"),2.5,true)
	draw_arc(center,radius*0.39,0,TAU,40,Color.WHITE,2.5,true)
func _draw() -> void:
	if _game==null or _font==null:
		return
	var vp := get_viewport_rect().size
	var factor := minf(vp.x/1280.0,vp.y/720.0)
	draw_set_transform((vp-Vector2(1280,720)*factor)*0.5,0,Vector2.ONE*factor)
	var timer := skin("time",Rect2(18,8,280,96))
	var row := inner(timer,Rect2(0.36,0.29,0.57,0.51))
	text_center(inner(row,Rect2(0,0,0.30,1)),"剩余",18,Color("FFF7E6"),1)
	text_center(inner(row,Rect2(0.31,0,0.43,1)),str(maxi(0,ceili(_game._time_left))),32,Color("FFE676"),1)
	text_center(inner(row,Rect2(0.78,0,0.18,1)),"秒",18,Color("FFF7E6"),1)
	var score := skin("score",Rect2(998,8,264,96))
	row = inner(score,Rect2(0.345,0.20,0.61,0.55))
	text_center(inner(row,Rect2(0,0,0.30,1)),"积分",18,Color("FFF7E6"),1)
	text_center(inner(row,Rect2(0.33,0,0.67,1)),str(_game._score),31,Color("FFE676"),1)
	var progress := skin("progress",Rect2(420,8,440,100))
	var fraction := clampf(_game._progress_display/100.0,0,1)
	if fraction>0:
		var start := progress.position+progress.size*Vector2(0.225,0.55)
		draw_line(start,start+Vector2(progress.size.x*0.55*fraction,0),Color("FFB947"),progress.size.y*0.07,true)
	for i in 4:
		var center := progress.position+progress.size*Vector2(0.30+float(i)*0.40/3.0,0.55)
		var size := PROGRESS_STAR.get_size()*(progress.size.y*0.37/PROGRESS_STAR.get_height())
		var on: bool = (_game._progress_milestones_claimed & (1<<i))!=0
		draw_texture_rect(PROGRESS_STAR,Rect2(center-size*0.5,size),false,Color.WHITE if on else Color("967C6F"))
	var target := skin("target",Rect2(1082,209,184,171))
	text_center(inner(target,Rect2(0.23,0.12,0.54,0.12)),"本轮目标",17,Color.WHITE,1)
	text_center(inner(target,Rect2(0.12,0.42,0.76,0.14)),"戳破气球 %d/6" % mini(6,_game._carnival_pops),16)
	text_center(inner(target,Rect2(0.12,0.66,0.76,0.14)),"获得 80 分 ✓" if _game._score>=80 else "获得 %d / 80 分" % _game._score,15)
	if _game._phase=="play":
		# Leave a gap beside the hair while keeping the left decoration on screen.
		var speech := skin("speech",Rect2(4,328,148,136))
		text_center(inner(speech,Rect2(0.21,0.27,0.58,0.17)),"加油！",18)
		text_center(inner(speech,Rect2(0.15,0.47,0.70,0.12)),"用力拉绳子，",14)
		text_center(inner(speech,Rect2(0.12,0.63,0.76,0.12)),"戳破那些气球吧！",12)
		text_center(Rect2(1080,385,188,26),"钻石气球：抓娃娃 +1",14,Color("FFF7DA"),2)
		if _game._claw_bonuses>0:
			text_center(Rect2(1080,411,188,24),"本局已获 %d 次" % _game._claw_bonuses,14,Color("FFF7DA"),2)
		var pull := skin("pull",Rect2(464,598,352,110))
		# Lay out all three items on the same content row, including the button shadow.
		var center := pull.position+pull.size*Vector2(0.50,0.515)
		var row_left := center.x-64.0
		arcade_button(Vector2(row_left+53,center.y-1.5),18)
		text_center(Rect2(row_left,center.y-18,22,36),"按",22)
		text_center(Rect2(row_left+84,center.y-18,44,36),"拉绳",22)
	else:
		var panel := skin("target",Rect2(431,238,418,370))
		text_center(inner(panel,Rect2(0.18,0.16,0.64,0.10)),"本局结算",28,Color.WHITE,1)
		text_center(inner(panel,Rect2(0.10,0.32,0.80,0.11)),"积分 %d" % _game._score,34)
		var counts: Array = _game._pop_counts
		var lines := [
			"本轮戳破 %d 个普通气球，%d 个条纹气球，" % [int(counts[0]), int(counts[1])],
			"%d 个星星球，%d 个爱心气球，" % [int(counts[2]), int(counts[3])],
			"%d 个金色球，%d 个钻石球" % [int(counts[4]), int(counts[5])],
		]
		for i in lines.size():
			text_center(inner(panel, Rect2(0.06, 0.46 + float(i) * 0.11, 0.88, 0.10)), lines[i], 16)
		if _game._claw_bonuses > 0:
			text_center(inner(panel, Rect2(0.10, 0.80, 0.80, 0.10)), "抓娃娃机会 +%d" % _game._claw_bonuses, 20)
