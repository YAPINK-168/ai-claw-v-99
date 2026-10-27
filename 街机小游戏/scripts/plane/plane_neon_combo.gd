extends Node2D
## Approved B crystal wings; names stay editable and tier thresholds follow PlaneView.
const KEYS := ["qishi", "mengong", "luanwu", "wushuang", "fengshen"]
const NAMES := ["骑士", "猛攻", "乱舞", "无双", "封神"]
var _frames: Array[Texture2D] = []
var _font: Font
var _key := ""
var _previous := ""
var _popup_key := ""
var _popup_t := 0.0
var _playing := false

func reset_state() -> void:
	_key = ""
	_previous = ""
	_popup_key = ""
	_popup_t = 0.0
	queue_redraw()

func show_peak(key: String) -> void:
	_popup_key = key if key in KEYS else "fengshen"
	_popup_t = 1.8
	queue_redraw()

func sync_state(logic: PlaneLogic, view: Node2D, font: Font, delta: float) -> void:
	if _frames.is_empty():
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		for key in KEYS:
			_frames.append(load("res://街机小游戏/assets/plane/neon/combo_wings_%s.png" % key) as Texture2D)
	_font = font if font else ThemeDB.fallback_font
	_playing = logic.playing
	_key = view._combo_tier_tex_key(logic.combo) if _playing else ""
	_popup_t = maxf(0.0, _popup_t - delta)
	if _key != _previous and not _key.is_empty():
		show_peak(_key)
	if _key.is_empty() and _popup_key != "fengshen":
		_popup_t = 0.0
	_previous = _key
	queue_redraw()

func _badge(key: String, rect: Rect2, alpha: float) -> void:
	var index := KEYS.find(key)
	if index < 0 or index >= _frames.size() or _frames[index] == null:
		return
	draw_texture_rect(_frames[index], rect, false, Color(1,1,1,alpha))
	var px := roundi(rect.size.y * 0.32)
	var name: String = NAMES[index]
	var width := _font.get_string_size(name,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x
	var at := rect.position + Vector2((rect.size.x-width)*0.5, rect.size.y*0.61)
	draw_string_outline(_font,at,name,HORIZONTAL_ALIGNMENT_LEFT,-1,px,4,Color(0.01,0.03,0.16,alpha))
	draw_string(_font,at,name,HORIZONTAL_ALIGNMENT_LEFT,-1,px,Color(0.94,0.99,1,alpha))

func _draw() -> void:
	if _font == null:
		return
	draw_set_transform(Vector2.ZERO,0,get_viewport_rect().size/Vector2(1280,720))
	var dock := Rect2(1036,566,226,112)
	if not _key.is_empty() and _popup_t <= 0.0:
		_badge(_key,dock,0.95)
	if _popup_t > 0.0:
		var progress := clampf((0.65-_popup_t)/0.65,0,1)
		progress = progress*progress*(3-2*progress)
		var rect := Rect2(Vector2(450,150).lerp(dock.position,progress),Vector2(380,188).lerp(dock.size,progress))
		_badge(_popup_key,rect,minf(1.0,_popup_t*4.0))
