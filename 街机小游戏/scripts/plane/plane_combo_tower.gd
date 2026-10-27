extends Control
class_name PlaneComboTower
## 豪华连击能量塔（即梦贴图：框 / 六边形 / 链 / 雷 / 冠 / 断连）

const TEX_DIR := "res://街机小游戏/assets/plane/combo_tower/"
const FRAME_ASPECT := 241.0 / 511.0
const CHAIN_LINKS := 5
const GLOW_TEX_ASPECT := 332.0 / 512.0
const VISUAL_HEX_SLOTS := 10
const BEAT_BAR_MAX := 32
const BEAT_SHADER := preload("res://街机小游戏/scripts/plane/plane_combo_beat_bar.gdshader")

var combo := 0
var lit_segments := 0
var segment_total := 18
var break_k := 0.0
var decay_warn := false
var beat_flash := 0.0
var energy := 0.0
var anim_t := 0.0
var punch := 0.0
var hot_color := Color(1.0, 0.82, 0.28, 1.0)
var beat_amps: PackedFloat32Array = PackedFloat32Array()
var beat_hue := 0.0
var beat_tier := 0.0
var rainbow_beat_v2 := true

var _tex: Dictionary = {}
var _beat_bars: Array[ColorRect] = []
var _beat_axis: ColorRect
var _glow: TextureRect
var _bolt_l: TextureRect
var _bolt_r: TextureRect
var _hex_slots: Array[TextureRect] = []
var _chain_l: Array[TextureRect] = []
var _chain_r: Array[TextureRect] = []
var _frame: TextureRect
var _crown: TextureRect
var _break_shards: TextureRect
var _break_text: TextureRect


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	_load_textures()
	_build_nodes()


func _load_textures() -> void:
	var names := [
		"combo_tower_glow",
		"combo_tower_frame",
		"combo_hex_off",
		"combo_hex_lit",
		"combo_hex_hot",
		"combo_chain_link",
		"combo_chain_link_glow",
		"combo_lightning_cyan",
		"combo_lightning_gold",
		"combo_tower_crown",
		"combo_break_shards",
		"combo_break_text",
	]
	for name in names:
		var p: String = TEX_DIR + name + ".png"
		if ResourceLoader.exists(p):
			_tex[name] = load(p)


func _mk_tex_rect(tex_key: String) -> TextureRect:
	var tr := TextureRect.new()
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if _tex.has(tex_key):
		tr.texture = _tex[tex_key]
	return tr


func _mk_beat_bar() -> ColorRect:
	var bar := ColorRect.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.visible = false
	bar.color = Color.WHITE
	var sm := ShaderMaterial.new()
	sm.shader = BEAT_SHADER
	bar.material = sm
	return bar


func _build_nodes() -> void:
	_glow = _mk_tex_rect("combo_tower_glow")
	_glow.z_index = -3
	var glow_mat := CanvasItemMaterial.new()
	glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = glow_mat
	add_child(_glow)
	_beat_axis = ColorRect.new()
	_beat_axis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_beat_axis.visible = false
	_beat_axis.z_index = -1
	var axis_mat := CanvasItemMaterial.new()
	axis_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_beat_axis.material = axis_mat
	_beat_axis.color = Color(0.75, 0.95, 1.0, 0.35)
	add_child(_beat_axis)
	for _i in BEAT_BAR_MAX:
		var bar := _mk_beat_bar()
		bar.z_index = -1
		add_child(bar)
		_beat_bars.append(bar)
	_bolt_l = _mk_tex_rect("combo_lightning_cyan")
	_bolt_l.z_index = -2
	_bolt_l.visible = false
	add_child(_bolt_l)
	_bolt_r = _mk_tex_rect("combo_lightning_cyan")
	_bolt_r.z_index = -2
	var bolt_mat := CanvasItemMaterial.new()
	bolt_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_bolt_l.material = bolt_mat
	_bolt_r.material = bolt_mat
	_bolt_r.visible = false
	add_child(_bolt_r)
	for side in 2:
		var arr: Array[TextureRect] = []
		for _j in CHAIN_LINKS:
			var ln := _mk_tex_rect("combo_chain_link")
			ln.z_index = 0
			add_child(ln)
			arr.append(ln)
		if side == 0:
			_chain_l = arr
		else:
			_chain_r = arr
	for _i in segment_total:
		var hx := _mk_tex_rect("combo_hex_off")
		hx.z_index = 1
		add_child(hx)
		_hex_slots.append(hx)
	_frame = _mk_tex_rect("combo_tower_frame")
	_frame.z_index = 2
	add_child(_frame)
	_crown = _mk_tex_rect("combo_tower_crown")
	_crown.z_index = 3
	_crown.visible = false
	add_child(_crown)
	_break_shards = _mk_tex_rect("combo_break_shards")
	_break_shards.z_index = 5
	_break_shards.visible = false
	add_child(_break_shards)
	_break_text = _mk_tex_rect("combo_break_text")
	_break_text.z_index = 6
	_break_text.visible = false
	add_child(_break_text)


func tick(_delta: float) -> void:
	anim_t += _delta
	_layout()
	_apply_state()


func _inner_rect() -> Rect2:
	var w := size.x
	var h := size.y
	var pad_x := w * 0.20
	var pad_top := h * 0.16
	var pad_bot := h * 0.14
	return Rect2(pad_x, pad_top, w - pad_x * 2.0, h - pad_top - pad_bot)


func _layout() -> void:
	if size.x < 8.0 or size.y < 8.0:
		return
	var w := size.x
	var h := size.y
	var glow_h := h * 1.02
	var glow_w := glow_h * GLOW_TEX_ASPECT
	_glow.size = Vector2(glow_w, glow_h)
	_glow.position = Vector2(w * 0.5 - glow_w * 0.5, h * 0.5 - glow_h * 0.5)
	_frame.position = Vector2.ZERO
	_frame.size = size
	var inner := _inner_rect()
	var n := clampi(segment_total, 1, VISUAL_HEX_SLOTS)
	var step := inner.size.y / float(n)
	var hex_h := step * 0.98
	var hex_w := minf(hex_h * 1.08, inner.size.x * 0.98)
	var hx0 := inner.position.x + inner.size.x * 0.5 - hex_w * 0.5
	for i in _hex_slots.size():
		var slot := _hex_slots[i]
		if i >= n:
			slot.visible = false
			continue
		slot.visible = true
		var cy := inner.position.y + inner.size.y - step * (float(i) + 0.5)
		var off_y := break_k * 18.0 * float(i + 1) * 0.06 if break_k > 0.0 else 0.0
		slot.size = Vector2(hex_w, hex_h)
		slot.position = Vector2(hx0, cy - hex_h * 0.5 + off_y)
	_layout_chains(inner, step, n, hex_w)
	_layout_bolts(w, h)
	_layout_crown(inner, step, n, hex_w)
	_layout_beat_bars(inner)
	_layout_break(w, h)


func _layout_chains(inner: Rect2, step: float, n: int, hex_w: float) -> void:
	var spin := anim_t * (1.4 + float(combo) * 0.035)
	var link_h := step * 0.78
	var link_w := link_h * 0.62
	for side_idx in 2:
		var side: float = -1.0 if side_idx == 0 else 1.0
		var arr := _chain_l if side_idx == 0 else _chain_r
		var x_base := inner.position.x + inner.size.x * 0.5 + side * (hex_w * 0.58 + link_w * 1.05)
		for j in arr.size():
			var t := float(j) / float(maxi(1, arr.size() - 1))
			var cy := inner.position.y + inner.size.y - step * float(n - 1) * t * 0.94
			var lx := x_base + sin(spin + t * 7.0 + side * 1.1) * 1.5
			var ln := arr[j]
			ln.size = Vector2(link_w, link_h)
			ln.position = Vector2(lx - link_w * 0.5, cy - link_h * 0.5)
			ln.rotation = 0.0
			var chain_on := combo >= 4 and lit_segments > 0
			ln.visible = chain_on
			if not chain_on:
				continue


func _layout_bolts(w: float, h: float) -> void:
	var show := visible and combo >= 8 and break_k < 0.35
	_bolt_l.visible = show
	_bolt_r.visible = show
	if not show:
		return
	var bolt_key := (
		"combo_lightning_gold" if combo >= PlaneLogic.COMBO_TIER_LUANWU else "combo_lightning_cyan"
	)
	if _tex.has(bolt_key):
		_bolt_l.texture = _tex[bolt_key]
		_bolt_r.texture = _tex[bolt_key]
	var bh := h * 0.68
	var bw := w * 0.26
	var sway := sin(anim_t * 11.0) * 2.0
	_bolt_l.size = Vector2(bw, bh)
	_bolt_l.position = Vector2(w * 0.5 - bw * 0.95 + sway, h * 0.16)
	_bolt_r.size = Vector2(bw, bh)
	_bolt_r.position = Vector2(w * 0.5 - bw * 0.05 - sway, h * 0.16)


func _layout_crown(inner: Rect2, step: float, n: int, hex_w: float) -> void:
	if lit_segments <= 0 or break_k >= 0.4:
		_crown.visible = false
		return
	_crown.visible = true
	var top_i := mini(lit_segments - 1, n - 1)
	var cy := inner.position.y + inner.size.y - step * (float(top_i) + 0.5)
	var cw := hex_w * 1.35
	var ch := cw * 0.62
	_crown.size = Vector2(cw, ch)
	_crown.position = Vector2(
		inner.position.x + inner.size.x * 0.5 - cw * 0.5,
		cy - step * 0.55 - ch * 0.35
	)


func _layout_beat_bars(inner: Rect2) -> void:
	var n := mini(_beat_bars.size(), BEAT_BAR_MAX)
	if n < 1:
		return
	var use_v2 := rainbow_beat_v2
	var mid_y := inner.position.y + inner.size.y * 0.5
	var col_w := inner.size.x / float(n)
	var show_eq := visible and combo >= 1 and break_k < 0.92
	if _beat_axis:
		_beat_axis.visible = show_eq and use_v2
		if _beat_axis.visible:
			_beat_axis.position = Vector2(inner.position.x, mid_y - 1.0)
			_beat_axis.size = Vector2(inner.size.x, 2.0)
			_beat_axis.color = Color(0.65, 0.92, 1.0, 0.22 + beat_flash * 0.18 + energy * 0.12)
	for i in n:
		var bar := _beat_bars[i]
		var amp := 0.0
		if i < beat_amps.size():
			amp = beat_amps[i]
		if not show_eq or amp < 0.03:
			bar.visible = false
			continue
		if use_v2:
			var bar_w := maxf(2.0, col_w * 0.62)
			var bar_h := maxf(4.0, inner.size.y * amp * 0.92)
			var cx := inner.position.x + col_w * (float(i) + 0.5)
			bar.visible = true
			bar.position = Vector2(cx - bar_w * 0.5, mid_y - bar_h * 0.5)
			bar.size = Vector2(bar_w, bar_h)
			var hue := fmod(beat_hue + float(i) / float(n) * 0.72, 1.0)
			var mat := bar.material as ShaderMaterial
			if mat:
				mat.set_shader_parameter("amp", amp)
				mat.set_shader_parameter("hue", hue)
				mat.set_shader_parameter("flash", beat_flash)
		else:
			var seg_h := inner.size.y / float(n)
			var hc := Color.from_hsv(beat_hue, 0.90, 1.0)
			var bright := 0.35 + amp * 0.72
			var bar_h2 := maxf(2.0, seg_h * 1.08)
			var y0 := inner.position.y + seg_h * float(i) + (seg_h - bar_h2) * 0.5
			var bar_w2 := 3.0 + amp * inner.size.x * 0.82
			bar.visible = true
			bar.material = null
			bar.position = Vector2(inner.position.x + inner.size.x * 0.5 - bar_w2 * 0.5, y0)
			bar.size = Vector2(bar_w2, bar_h2)
			var bar_mat := CanvasItemMaterial.new()
			bar_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			bar.material = bar_mat
			bar.color = Color(
				hc.r * (0.88 + bright * 0.62),
				hc.g * (0.98 + bright * 0.52),
				hc.b * (0.90 + bright * 0.30),
				0.30 + amp * 0.62
			)


func _layout_break(w: float, h: float) -> void:
	var show := break_k > 0.02
	_break_shards.visible = show
	_break_text.visible = show
	if not show:
		return
	var a := clampf(1.0 - break_k * 0.55, 0.25, 1.0)
	var sw := w * 1.35
	var sh := sw * 0.85
	_break_shards.size = Vector2(sw, sh)
	_break_shards.position = Vector2(w * 0.5 - sw * 0.5, h * 0.22 - break_k * 12.0)
	_break_shards.modulate = Color(1, 1, 1, a)
	var tw := w * 1.05
	var th := tw * 0.48
	_break_text.size = Vector2(tw, th)
	_break_text.position = Vector2(w * 0.5 - tw * 0.5, h * 0.38 + break_k * 8.0)
	_break_text.modulate = Color(1, 1, 1, a)


func _apply_state() -> void:
	var n := clampi(segment_total, 1, VISUAL_HEX_SLOTS)
	var glow_show := combo >= 6
	_glow.visible = glow_show
	var glow_a := (0.06 + energy * 0.1 + beat_flash * 0.08) * clampf(float(combo) / 18.0, 0.2, 1.0)
	_glow.modulate = Color(hot_color.r, hot_color.g, hot_color.b, glow_a)
	_glow.scale = Vector2.ONE * (1.0 + punch * 0.04 + beat_flash * 0.02)
	var bolt_a := 0.42 + beat_flash * 0.28 + energy * 0.12
	_bolt_l.modulate = Color(1, 1, 1, bolt_a)
	_bolt_r.modulate = _bolt_l.modulate
	var crown_a := 0.7 + beat_flash * 0.3 + punch * 0.2
	_crown.modulate = Color(1, 1, 1, crown_a)
	for i in n:
		if i >= _hex_slots.size():
			break
		var slot := _hex_slots[i]
		var lit := i < lit_segments
		var is_hot := lit and i == lit_segments - 1
		slot.visible = true
		var tex_key := "combo_hex_off"
		if lit:
			tex_key = "combo_hex_hot" if is_hot else "combo_hex_lit"
		if _tex.has(tex_key):
			slot.texture = _tex[tex_key]
		var col := Color.WHITE
		if not lit and break_k <= 0.0:
			col = Color(0.62, 0.72, 0.88, 0.38)
		elif break_k > 0.0:
			col.a = 1.0 - break_k * 0.7
		elif is_hot and decay_warn and fmod(anim_t * 9.0, 1.0) < 0.45:
			col = Color(1.0, 0.35, 0.28, 1.0)
		else:
			col.a = 0.82 + beat_flash * 0.18 + energy * 0.1
		if is_hot and lit:
			var pulse := 1.0 + sin(anim_t * 10.0 + float(i) * 0.6) * 0.05 * (0.4 + beat_flash)
			slot.scale = Vector2(pulse, pulse)
			slot.pivot_offset = slot.size * 0.5
		else:
			slot.scale = Vector2.ONE
		slot.modulate = col
	_apply_chains()


func _apply_chains() -> void:
	var glow_tex: Texture2D = _tex.get("combo_chain_link_glow", null)
	var spin := anim_t * (1.4 + float(combo) * 0.035)
	for side_idx in 2:
		var arr := _chain_l if side_idx == 0 else _chain_r
		for j in arr.size():
			var ln := arr[j]
			var t := float(j) / float(maxi(1, arr.size() - 1))
			if not ln.visible:
				continue
			var lit_link := j < lit_segments
			if lit_link and glow_tex != null:
				ln.texture = glow_tex
			elif _tex.has("combo_chain_link"):
				ln.texture = _tex["combo_chain_link"]
			var col := Color(0.75, 0.78, 0.85, 0.35)
			if lit_link:
				col = hot_color.lerp(Color(0.98, 0.82, 0.28, 1.0), 0.4)
				col.a = 0.65 + energy * 0.2 + beat_flash * 0.12
			col.a *= 0.85 + sin(spin + t * 5.0) * 0.08
			ln.modulate = col
