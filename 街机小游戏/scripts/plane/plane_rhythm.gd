extends RefCounted
class_name PlaneRhythm
## 原中央缩圈打拍（已关闭）；保留类供 PlaneView 引用，节拍视觉改由 BGM 能量驱动侧栏/子弹。

const APPROACH_SCALE_START := 1.72
const EARLY_GRACE_SEC := 0.42
const LATE_GRACE_SEC := 1.08
const PERFECT_EARLY_SEC := 0.26
const PERFECT_LATE_SEC := 0.68

var window_open := false
var awaiting_tap := false
var combo := 0
var _beat_idx := -1
var _last_idx := -1
var _next_tap_beat := -1


func reset() -> void:
	window_open = false
	awaiting_tap = false
	combo = 0
	_beat_idx = -1
	_last_idx = -1
	_next_tap_beat = _find_next_tap_beat(0)


func on_music_beat(_beat_idx: int) -> void:
	pass


func approach_scale() -> float:
	if _beat_idx < 0:
		return APPROACH_SCALE_START
	var dt := ArcadeAudio.plane_rhythm_hit_delta_sec(_beat_idx)
	var dur := _approach_duration_sec()
	if dt > LATE_GRACE_SEC:
		return 1.0
	if dt >= 0.0:
		return 1.0
	var u := clampf((dt + dur) / maxf(dur, 0.001), 0.0, 1.0)
	return lerpf(APPROACH_SCALE_START, 1.0, _ease(u))


func try_tap() -> Dictionary:
	return {}


func tick(_playing: bool) -> void:
	window_open = false
	awaiting_tap = false
	_beat_idx = -1


func _should_offer_window_at(current_idx: int, target: int) -> bool:
	if target < 0:
		return false
	if target == 0:
		return current_idx == 0
	var prep := target - 1
	return current_idx == prep or current_idx == target


func _find_next_tap_beat(from: int) -> int:
	var n := ArcadeAudio.plane_beat_count()
	for i in range(maxi(0, from), n):
		if ArcadeAudio.plane_rhythm_tap_beat(i):
			return i
	return -1


func _approach_duration_sec() -> float:
	if _beat_idx <= 0:
		return ArcadeAudio.plane_beat_duration_at(_beat_idx)
	return ArcadeAudio.plane_beat_duration_at(_beat_idx - 1)


func _open_window(beat_idx: int) -> void:
	if beat_idx != _next_tap_beat:
		return
	window_open = true
	awaiting_tap = true
	_beat_idx = beat_idx


func _register_miss() -> void:
	var missed := _beat_idx
	awaiting_tap = false
	window_open = false
	_beat_idx = -1
	combo = 0
	if missed >= 0:
		_next_tap_beat = _find_next_tap_beat(missed + 1)
	else:
		_next_tap_beat = _find_next_tap_beat(0)


static func _ease(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)
