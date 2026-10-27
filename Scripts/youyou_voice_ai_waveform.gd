extends Control
class_name YouyouVoiceAiWaveform
## 顶部蓝色栏内的竖条波形（纯 UI，不影响语音链路）。

const BAR_COUNT := 12
const BAR_WIDTH := 4.0
const BAR_GAP := 2.5
const CORNER := 1.5

var _drive_mode := "idle"
var _levels: PackedFloat32Array = PackedFloat32Array()
var _targets: PackedFloat32Array = PackedFloat32Array()
var _external_level := 0.0
var _phase := 0.0


func _ready() -> void:
	_levels.resize(BAR_COUNT)
	_targets.resize(BAR_COUNT)
	for i in BAR_COUNT:
		_levels[i] = 0.15
		_targets[i] = 0.15
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_drive_mode(mode: String) -> void:
	_drive_mode = mode


func set_external_level(level: float) -> void:
	_external_level = clampf(level, 0.0, 1.0)


func _process(delta: float) -> void:
	_phase += delta
	var base := 0.12
	var spread := 0.22
	match _drive_mode:
		"mic", "tts":
			base = 0.18 + _external_level * 0.72
			spread = 0.28 + _external_level * 0.35
		"processing":
			base = 0.22
			spread = 0.26
		_:
			base = 0.14
			spread = 0.16
	for i in BAR_COUNT:
		var wobble := sin(_phase * (2.4 + float(i) * 0.17) + float(i) * 0.55)
		var tgt := clampf(base + wobble * spread, 0.06, 1.0)
		if _drive_mode in ["mic", "tts"] and _external_level > 0.05:
			var bias: float = 1.0 - abs(float(i) - float(BAR_COUNT - 1) * 0.5) / float(BAR_COUNT) * 0.35
			tgt = clampf(base * bias + _external_level * 0.55, 0.08, 1.0)
		_targets[i] = tgt
		_levels[i] = lerpf(_levels[i], _targets[i], 1.0 - exp(-14.0 * delta))
	queue_redraw()


func _draw() -> void:
	var h := size.y
	var avail := size.x
	if h <= 1.0 or avail <= 1.0:
		return
	var natural := BAR_COUNT * BAR_WIDTH + (BAR_COUNT - 1) * BAR_GAP
	var scale := 1.0 if natural <= avail else avail / natural
	var bar_w := BAR_WIDTH * scale
	var gap := BAR_GAP * scale
	var total_w := BAR_COUNT * bar_w + (BAR_COUNT - 1) * gap
	var x0 := maxf(0.0, (avail - total_w) * 0.5)
	var col := Color(1.0, 1.0, 1.0, 0.92)
	for i in BAR_COUNT:
		var lvl := _levels[i]
		var bar_h := clampf(h * lvl * 1.08, 3.0, h)
		var x := x0 + float(i) * (bar_w + gap)
		var y := (h - bar_h) * 0.5
		draw_rect(Rect2(x, y, bar_w, bar_h), col, true, -1.0, true)
