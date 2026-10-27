extends Node2D
## Approved holographic B-style Boss warning, title and two-pipe health display.
const CYAN := Color("57EAFF")
const PINK := Color("F35BE4")
var _logic: PlaneLogic
var _view: Node2D
var _font: Font
var _skins: Array[Texture2D] = []
func sync_state(logic: PlaneLogic, view: Node2D, font: Font) -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_logic = logic
	_view = view
	_font = font if font else ThemeDB.fallback_font
	if _skins.is_empty():
		for name in ["boss_ui_warning","boss_ui_nameplate","boss_ui_health"]:
			var path: String = "res://街机小游戏/assets/plane/neon/"+name+".png"
			_skins.append(load(path) as Texture2D if ResourceLoader.exists(path) else null)
	queue_redraw()
func _shape(r: Rect2, inset: float = 0.0) -> PackedVector2Array:
	var a := r.grow(-inset)
	var x := a.position.x
	var y := a.position.y
	var w := a.size.x
	var h := a.size.y
	var c := minf(12.0,minf(h*0.24,w*0.24))
	return PackedVector2Array([Vector2(x+c,y),Vector2(x+w,y),Vector2(x+w,y+h-c),Vector2(x+w-c,y+h),Vector2(x,y+h),Vector2(x,y+c)])
func _glass(r: Rect2, danger: bool = false) -> void:
	var skin := 2 if r.size.y <= 50.0 else (0 if danger else 1)
	if _skins.size() == 3 and _skins[skin] != null:
		draw_colored_polygon(_shape(r),Color(0.025,0.045,0.16,0.85))
		draw_texture_rect(_skins[skin],r,false)
		return
	var shape := _shape(r)
	draw_colored_polygon(shape,Color(0.025,0.045,0.16,0.92))
	var line := shape.duplicate()
	line.append(shape[0])
	draw_polyline(line,Color(0.26,0.50,0.95,0.6),5.0,true)
	draw_polyline(line,PINK if danger else CYAN,2.0,true)
	var inner := _shape(r,4.0)
	inner.append(inner[0])
	draw_polyline(inner,Color(0.72,0.80,1.0,0.65),1.0,true)
	var x := r.position.x
	var y := r.position.y
	var w := r.size.x
	var h := r.size.y
	for i in 3:
		var dx := x+18.0+float(i)*17.0
		draw_colored_polygon(PackedVector2Array([Vector2(dx,y+5),Vector2(dx+29,y+5),Vector2(dx+6,y+h-5),Vector2(dx-4,y+h-5)]),Color(0.1,0.8,1.0,0.10+float(i)*0.025))
	draw_colored_polygon(PackedVector2Array([Vector2(x+w-74,y+4),Vector2(x+w-5,y+4),Vector2(x+w-9,y+h-10)]),Color(0.7,0.15,1.0,0.23))
	draw_line(Vector2(x+14,y+2),Vector2(x+w*0.40,y+2),Color("BAF8FF"),3.0,true)
	draw_line(Vector2(x+w*0.60,y+h-2),Vector2(x+w-15,y+h-2),PINK,3.0,true)
	for i in 17:
		var px := x+12.0+fposmod(float(i*43),w-24.0)
		var py := y+8.0+fposmod(float(i*19),maxf(h-16.0,1.0))
		draw_circle(Vector2(px,py),0.6,Color(0.4,0.8,1.0,0.22))
func _text(at: Vector2, value: String, size: int, color: Color = Color.WHITE) -> void:
	draw_string_outline(_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,3,Color("101735"))
	draw_string_outline(_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,1,color)
	draw_string(_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func _center_text(r: Rect2, value: String, size: int, color: Color = Color.WHITE, stretch_x: float = 1.0) -> void:
	var use_size := size
	while use_size > 12 and _font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,use_size).x * stretch_x > r.size.x:
		use_size -= 1
	var sw := _font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,use_size).x
	var at := Vector2(r.position.x+(r.size.x-sw*stretch_x)*0.5,r.position.y+r.size.y*0.5+float(use_size)*0.34)
	if not is_equal_approx(stretch_x,1.0):
		var base := get_viewport_rect().size/Vector2(1280,720)
		draw_set_transform(at*base,0.0,base*Vector2(stretch_x,1.0))
		_text(Vector2.ZERO,value,use_size,color)
		draw_set_transform(Vector2.ZERO,0.0,base)
	else:
		_text(at,value,use_size,color)
func _crystal(center: Vector2, radius: float) -> void:
	var top := center+Vector2(0,-radius)
	var left := center+Vector2(-radius*0.62,0)
	var right := center+Vector2(radius*0.62,0)
	var bottom := center+Vector2(0,radius)
	draw_colored_polygon(PackedVector2Array([top,right,bottom,left]),Color("665DFF"))
	draw_colored_polygon(PackedVector2Array([top,center,left]),CYAN)
	draw_colored_polygon(PackedVector2Array([center,right,bottom]),PINK)
	draw_polyline(PackedVector2Array([top,right,bottom,left,top]),Color("C8F8FF"),1.0,true)
func _draw() -> void:
	if _logic == null or _font == null:
		return
	draw_set_transform(Vector2.ZERO,0.0,get_viewport_rect().size/Vector2(1280,720))
	var boss := _logic.live_boss()
	if _logic.playing and not boss.is_empty():
		_draw_health(boss)
	if _logic.playing and _logic.warning_t > 0.0:
		_draw_warning()
	elif _logic.playing and _view._title_t > 0.0:
		_draw_title()
func _draw_health(boss: Dictionary) -> void:
	var rect := Rect2(340,18,600,48)
	_glass(rect)
	var nm := _logic.boss_name_for_style(int(boss.get("boss_style",0)))
	_center_text(Rect2(350,23,124,36),nm,21)
	_crystal(Vector2(480,42),11.0)
	var ratio := clampf(float(boss.get("hp",0))/maxf(1.0,float(boss.get("pipe_max",1))),0.0,1.0)
	var pipe := int(boss.get("pipe",1))
	for i in 2:
		var x := 498.0+float(i)*210.0
		var r := Rect2(x,39,201,17)
		_center_text(Rect2(x,20,201,18),"I" if i==0 else "II",15,Color("FFB5F5") if i==pipe-1 else Color("929AC6"))
		draw_colored_polygon(_shape(r),Color("292344"))
		var fill := (ratio if pipe==1 else 0.0) if i==0 else (1.0 if pipe==1 else ratio)
		if fill > 0.0:
			var f := Rect2(r.position,r.size*Vector2(fill,1.0))
			draw_colored_polygon(_shape(f),Color("F13BBE") if i==pipe-1 else Color("AD2B91"))
			if f.size.x > 8.0:
				draw_line(f.position+Vector2(5,3),f.position+Vector2(f.size.x-3,3),Color("FFBDF7"),2.0,true)
		var line := _shape(r)
		line.append(line[0])
		draw_polyline(line,Color("D684E6"),1.0,true)
	if bool(boss.get("breaking",false)):
		_center_text(Rect2(498,19,410,38),"阶段切换",20,Color("E9F8FF"))
func _draw_warning() -> void:
	var r := Rect2(342,225,596,112)
	_glass(r,true)
	for side in [-1,1]:
		for i in 3:
			var x := 640.0+float(side)*(312.0+float(i)*18.0)
			draw_line(Vector2(x-7,239),Vector2(x+7,320),Color(0.8,0.18,1.0,0.34),6.0,true)
	# Keep both text rows inside the frame's inner opening, away from its bright bevels.
	_center_text(Rect2(394,245,492,44),"WARNING",48,Color("FFF2FD"),1.75)
	_center_text(Rect2(422,290,436,26),"强敌接近",21,CYAN)
	var line_y := 238.0+fposmod(_view._anim*43.0,88.0)
	draw_line(Vector2(362,line_y),Vector2(918,line_y),Color(0.4,0.85,1.0,0.14),1.0,true)
func _draw_title() -> void:
	var r := Rect2(400,222,480,104)
	_glass(r)
	_crystal(Vector2(444,272),29.0)
	# Both rows share a centerline and fit inside the frame's recessed opening.
	_center_text(Rect2(480,246,360,40),_view._title_name,34)
	_center_text(Rect2(480,284,360,23),_view._title_sub,18,Color("9CEEFF"))
