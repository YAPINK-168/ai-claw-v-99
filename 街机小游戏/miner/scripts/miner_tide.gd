class_name MinerTideState
extends RefCounted

enum Phase { HIGH_HOLD, EBBING, LOW_HOLD }

const EBB_START := 30.0
## 30s 只切到退潮阶段（横幅）。背景视频海面约 34.5s 才下沉，40.5s 落稳。
const EBB_END := 41.0
const Y_HIGH := 0.0
const Y_LOW := 162.0
## 局内秒, 进度。取样 miner_bg.ogv 海面亮度跌落，归一化到落稳为 1。
const VIDEO_WATER_KEYS: Array[float] = [
	34.5, 0.05,
	35.0, 0.13,
	35.5, 0.20,
	36.0, 0.29,
	36.5, 0.38,
	37.0, 0.48,
	37.5, 0.57,
	38.0, 0.67,
	38.5, 0.74,
	39.0, 0.83,
	39.5, 0.90,
	40.0, 0.96,
	40.5, 1.00,
]
const BLOOD_FADE := 0.8

var phase: Phase = Phase.HIGH_HOLD
var tide_layer_y: float = Y_HIGH
var ebb_bar_ratio: float = 1.0
var elapsed: float = 0.0
var blood_moon: bool = false
var blood: float = 0.0

var _ebb_banner_pending: bool = false
var _blood_banner_pending: bool = false


func reset() -> void:
	phase = Phase.HIGH_HOLD
	tide_layer_y = Y_HIGH
	ebb_bar_ratio = 1.0
	elapsed = 0.0
	blood_moon = false
	blood = 0.0
	_ebb_banner_pending = false
	_blood_banner_pending = false


func advance(p_elapsed: float, _fish_y_min: float, _fish_y_max: float) -> void:
	var prev_phase := phase
	var prev_elapsed := elapsed
	elapsed = maxf(p_elapsed, 0.0)
	if blood_moon:
		phase = Phase.HIGH_HOLD
		tide_layer_y = Y_HIGH
		ebb_bar_ratio = 1.0
		if elapsed < EBB_START:
			blood = 0.0
		else:
			blood = smoothstep(0.0, 1.0, clampf((elapsed - EBB_START) / BLOOD_FADE, 0.0, 1.0))
		if prev_elapsed < EBB_START and elapsed >= EBB_START:
			_blood_banner_pending = true
		return
	blood = 0.0
	if elapsed < EBB_START:
		phase = Phase.HIGH_HOLD
		tide_layer_y = Y_HIGH
		ebb_bar_ratio = 1.0
	elif elapsed < EBB_END:
		phase = Phase.EBBING
		var t := ebb_motion_progress()
		tide_layer_y = lerpf(Y_HIGH, Y_LOW, t)
		ebb_bar_ratio = 1.0 - t
	else:
		phase = Phase.LOW_HOLD
		tide_layer_y = Y_LOW
		ebb_bar_ratio = 0.0
	if prev_phase == Phase.HIGH_HOLD and phase == Phase.EBBING:
		_ebb_banner_pending = true


func ebb_motion_progress() -> float:
	return _video_water_progress(elapsed)


func ebb_fish_progress() -> float:
	return _video_water_progress(elapsed)


func _video_water_progress(t_elapsed: float) -> float:
	var keys := VIDEO_WATER_KEYS
	var n := keys.size()
	if n < 4:
		return 0.0
	if t_elapsed <= keys[0]:
		return 0.0
	if t_elapsed >= keys[n - 2]:
		return keys[n - 1]
	var i := 0
	while i + 3 < n:
		var t1: float = keys[i + 2]
		if t_elapsed <= t1:
			var t0: float = keys[i]
			var span := maxf(t1 - t0, 0.001)
			var u := clampf((t_elapsed - t0) / span, 0.0, 1.0)
			return lerpf(keys[i + 1], keys[i + 3], u)
		i += 2
	return keys[n - 1]


func consume_blood_banner() -> bool:
	if not _blood_banner_pending:
		return false
	_blood_banner_pending = false
	return true


func consume_ebb_banner() -> bool:
	if not _ebb_banner_pending:
		return false
	_ebb_banner_pending = false
	return true


func get_fish_swim_y_max(fish_y_min: float, fish_y_max: float) -> float:
	if phase == Phase.HIGH_HOLD:
		return fish_y_max
	## 退潮后仍保留约三分之一鱼群：活动下沿不要收到只剩顶层，否则会被边界剔除杀光
	var low_band_max := lerpf(fish_y_min, fish_y_max, 0.48)
	if phase == Phase.LOW_HOLD:
		return low_band_max
	var t := ebb_fish_progress()
	return lerpf(fish_y_max, low_band_max, t)


func should_purge_all_fish() -> bool:
	if blood_moon:
		return false
	return elapsed >= EBB_END
