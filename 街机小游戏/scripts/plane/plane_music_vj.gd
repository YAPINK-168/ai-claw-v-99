extends Node2D
## Background-only geometry; music energy and beat phase drive all opacity.
var area := Vector2.ZERO
var tone := Color.CYAN
var energy := 0.0
var phase := 0.0
var beat := 0.0
func sync(size_px: Vector2, color: Color, amplitude: float, beat_phase: float, beat_number: float, playing: bool) -> void:
	area = size_px
	tone = color
	energy = clampf(amplitude / 1.75,0,1)
	phase = clampf(beat_phase,0,1)
	beat = beat_number
	visible = playing
	queue_redraw()
func _draw() -> void:
	if not visible or area.y < 1:
		return
	var u := area.y / 720.0
	var center := area * Vector2(.5,.45)
	var pulse := 1.0 - phase
	for ring in 3:
		var points := PackedVector2Array()
		var radius := (115.0 + float(ring)*85.0 + phase*70.0) * u
		for i in 49:
			var angle := float(i)*TAU/48.0 + beat*.035*(1 if ring%2==0 else -1)
			points.append(center+Vector2(cos(angle),sin(angle))*radius)
		var tint := tone
		tint.a = (.045+energy*.13+pulse*.10)*(1.0-float(ring)*.19)
		draw_polyline(points,Color(tint.r,tint.g,tint.b,tint.a*.25),7*u,true)
		draw_polyline(points,tint,1.5*u,true)
	for side in [-1,1]:
		for ray in 4:
			var start := Vector2(area.x*.5,area.y*.93)
			var x := area.x*(.5 + float(side)*(.17+float(ray)*.09))
			var tint := tone
			tint.a = (.025+energy*.08+pulse*.055)*(1-float(ray)*.12)
			draw_line(start,Vector2(x,area.y*.08),tint,(1.5+pulse*1.2)*u,true)
