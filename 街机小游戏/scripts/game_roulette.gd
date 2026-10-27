extends Control
## 抓取失败后的三款游戏转盘，使用已审核美术。
signal spin_finished(game_id: String)
signal start_requested()
signal transition_finished()
const ART := "res://街机小游戏/assets/roulette/"
const DESIGN := Vector2(1672,941)
const SPIN_DURATION := 3.2
const ENTER_DURATION := 1.05
const PREVIEW_RECT := Rect2(383,140,906,510)
const BUTTON_RECT := Rect2(615,775,445,105)
const DISK_RECT := Rect2(509,196,652,608)
const DISK_SHADER := preload("res://街机小游戏/shaders/roulette_disk.gdshader")
var _ids: PackedStringArray = []
var _results: Dictionary = {}
var _previews: Dictionary = {}
var _wheel: Texture2D
var _disk: TextureRect
var _pointer: Polygon2D
var _disk_material: ShaderMaterial
var _spinning := false
var _spin_t := 0.0
var _angle := 0.0
var _start_angle := 0.0
var _end_angle := 0.0
var _prev_tick := 0
var _result_index := 0
var _mode := "spin"
var _hold := 0.0
var _enter_t := 0.0
var _fit := Rect2()
var _scale := 1.0

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_wheel=load(ART+"wheel_screen.png")
	for game in ArcadeGameCatalog.GAMES:
		var id := str(game["id"])
		_ids.append(id)
		_results[id]=load(ART+"result_"+id+".png")
		_previews[id]=load(ART+"preview_"+id+".png")
	_disk_material=ShaderMaterial.new()
	_disk_material.shader=DISK_SHADER
	_disk=TextureRect.new()
	_disk.texture=load(ART+"wheel_clean.png")
	_disk.material=_disk_material
	_disk.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_disk.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	add_child(_disk)
	_pointer=Polygon2D.new()
	_pointer.texture=load(ART+"wheel_pointer_source.png")
	_pointer.polygon=PackedVector2Array([Vector2(804,155),Vector2(822,149),Vector2(851,150),Vector2(870,155),Vector2(868,169),Vector2(842,230),Vector2(836,239),Vector2(830,234),Vector2(807,178)])
	_pointer.uv=_pointer.polygon
	add_child(_pointer)
	resized.connect(_layout)
	_layout()
	set_process(false)

func _layout() -> void:
	_scale=minf(size.x/DESIGN.x,size.y/DESIGN.y)
	_fit=Rect2((size-DESIGN*_scale)*.5,DESIGN*_scale)
	if _disk:
		_disk.position=_fit.position+DISK_RECT.position*_scale
		_disk.size=DISK_RECT.size*_scale
		_pointer.position=_fit.position
		_pointer.scale=Vector2.ONE*_scale
	queue_redraw()

func is_spinning() -> bool:
	return _spinning or _mode=="hold" or _mode=="enter"

func selected_id() -> String:
	return _ids[_result_index] if not _ids.is_empty() else ""

func start_spin(force_ready_only: bool = false) -> void:
	var choices: Array[String]=[]
	if force_ready_only:
		choices=ArcadeGameCatalog.ready_ids()
	if choices.is_empty():
		for id in _ids:
			choices.append(id)
	var pick: String=choices[randi()%choices.size()]
	_result_index=_ids.find(pick)
	_start_angle=_angle
	var target := fposmod(PI/3.0-float(_result_index)*TAU/3.0,TAU)
	_end_angle=_angle+TAU*float(4+randi()%3)+fposmod(target-_angle,TAU)
	_spin_t=0.0
	_mode="spin"
	_spinning=true
	_prev_tick=int(floor(_angle/(TAU/3.0)))
	_disk.visible=true
	_pointer.visible=true
	visible=true
	ArcadeAudio.sfx_roulette_start()
	set_process(true)
	_layout()

func _process(delta: float) -> void:
	if not visible:
		return
	if _mode=="spin":
		_spin_t+=delta
		var u := clampf(_spin_t/SPIN_DURATION,0,1)
		var ease_out := 1.0-pow(1.0-u,3.0)
		_angle=lerpf(_start_angle,_end_angle,ease_out)
		_disk_material.set_shader_parameter("angle",_angle)
		var tick := int(floor(_angle/(TAU/3.0)))
		if tick!=_prev_tick:
			ArcadeAudio.sfx_roulette_tick(ease_out)
			_prev_tick=tick
		if u>=1.0:
			_spinning=false
			_mode="hold"
			_hold=.45
			ArcadeAudio.sfx_roulette_stop()
	elif _mode=="hold":
		_hold-=delta
		if _hold<=0:
			show_result(selected_id())
			spin_finished.emit(selected_id())
	elif _mode=="enter":
		_enter_t+=delta
		if _enter_t>=ENTER_DURATION:
			_mode="done"
			visible=false
			set_process(false)
			transition_finished.emit()
	queue_redraw()

func show_result(game_id: String) -> void:
	_result_index=_ids.find(game_id)
	_mode="result"
	_spinning=false
	_disk.visible=false
	_pointer.visible=false
	queue_redraw()

func begin_enter() -> void:
	if _mode!="result":
		return
	_mode="enter"
	_enter_t=0
	set_process(true)

func _gui_input(event: InputEvent) -> void:
	var tap: bool = (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed)
	if tap and _mode=="result":
		var point: Vector2=(event.position-_fit.position)/maxf(.001,_scale)
		if BUTTON_RECT.has_point(point):
			accept_event()
			start_requested.emit()

func _draw() -> void:
	if not _wheel:
		return
	if _mode=="spin" or _mode=="hold":
		draw_rect(Rect2(Vector2.ZERO,size),Color("08132D"))
		draw_texture_rect(_wheel,_fit,false)
		return
	var id := selected_id()
	if not _results.has(id):
		return
	var card: Texture2D=_results[id]
	if _mode!="enter":
		draw_rect(Rect2(Vector2.ZERO,size),Color("08132D"))
		draw_texture_rect(card,_fit,false)
		return
	var u := clampf(_enter_t/ENTER_DURATION,0,1)
	var zoom := smoothstep(0.0,.80,u)
	var alpha := 1.0-smoothstep(.79,1.0,u)
	# 展示画面等比放大，淡入实际开局；展示用 Boss 不影响真实进度。
	var target_scale := minf(size.x/1280.0,size.y/720.0)
	var target := Rect2((size-Vector2(1280,720)*target_scale)*.5,Vector2(1280,720)*target_scale)
	var start := Rect2(_fit.position+PREVIEW_RECT.position*_scale,PREVIEW_RECT.size*_scale)
	var dest := Rect2(start.position.lerp(target.position,zoom),start.size.lerp(target.size,zoom))
	if u<.80:
		draw_rect(Rect2(Vector2.ZERO,size),Color("08132D"))
		draw_texture_rect(card,_fit,false,Color(1,1,1,1.0-zoom))
		draw_texture_rect(_previews[id],dest,false)
	else:
		draw_texture_rect(_previews[id],target,false,Color(1,1,1,alpha))

