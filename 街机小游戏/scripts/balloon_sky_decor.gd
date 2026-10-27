extends Node2D
## Background sprites only: no collision, input, prizes or gameplay RNG.
const TEXTURES := [
	preload("res://街机小游戏/assets/balloon/carnival/hot_air_variant_0.png"),
	preload("res://街机小游戏/assets/balloon/carnival/hot_air_variant_1.png"),
	preload("res://街机小游戏/assets/balloon/carnival/hot_air_variant_2.png"),
]
var _rng := RandomNumberGenerator.new()
var _pool: Array[Sprite2D] = []
var _flights: Array[Dictionary] = []
var _wait := 4.0

func _ready() -> void:
	name = "SkyBalloonDecor"
	z_index = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_rng.randomize()
	for i in 3:
		var sprite := Sprite2D.new()
		sprite.visible = false
		add_child(sprite)
		_pool.append(sprite)
		_flights.append({"live":false,"age":0.0})
	reset()

func reset() -> void:
	_wait = _rng.randf_range(3.0,6.0)
	for i in _pool.size():
		_pool[i].visible = false
		_flights[i].live = false

func _spawn(size_px: Vector2) -> void:
	var count := _rng.randi_range(2,3)
	var center := _rng.randf_range(.28,.32)
	var first_texture := _rng.randi_range(0,TEXTURES.size()-1)
	for i in _pool.size():
		if bool(_flights[i].live):
			continue
		var sprite := _pool[i]
		sprite.texture = TEXTURES[(first_texture+i)%TEXTURES.size()]
		var height := _rng.randf_range(92.0,115.0)*size_px.y/720.0
		sprite.scale = Vector2.ONE*height/sprite.texture.get_height()
		_flights[i] = {"live":true,"age":-float(i)*1.2,"duration":_rng.randf_range(11.0,14.0),"x":center+float(i)*.105,"phase":_rng.randf()*TAU}
		count -= 1
		if count <= 0:
			break

func step(delta: float, size_px: Vector2, playing: bool) -> void:
	visible = playing
	if not playing:
		return
	_wait -= delta
	var live := 0
	for flight in _flights:
		if bool(flight.live):
			live += 1
	if _wait <= 0.0 and live == 0:
		_spawn(size_px)
		_wait = _rng.randf_range(6.0,10.0)
	for i in _pool.size():
		var flight := _flights[i]
		if not bool(flight.live):
			_pool[i].visible = false
			continue
		flight.age += delta
		var t := clampf(float(flight.age)/float(flight.duration),0.0,1.0)
		var sprite := _pool[i]
		sprite.position = Vector2(size_px.x*float(flight.x)+sin(float(flight.age)*.7+float(flight.phase))*7.0*size_px.y/720.0,size_px.y*lerpf(.68,.17,t))
		sprite.rotation = sin(float(flight.age)*.65+float(flight.phase))*.035
		sprite.modulate = Color(.92,.96,1.0,.68*minf(clampf(t/.12,0,1),clampf((1.0-t)/.15,0,1)))
		sprite.visible = t < 1.0
		if t >= 1.0:
			flight.live = false
			_wait = _rng.randf_range(6.0,10.0)
