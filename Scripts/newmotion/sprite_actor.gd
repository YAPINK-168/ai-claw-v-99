extends AnimatedSprite2D
class_name NewMotionSpriteActor

## 从 NewMotion/动作/<名>/ 按磁盘路径加载 png/webp（该目录有 .gdignore，不走编辑器导入）。
## 两段非待机动作之间先播一轮呼吸待机，再接下一段。
## 内存里只留正在播的、马上要播的；播完的收掉，不进场就撕开整库。

signal clip_started(clip_name: String, is_bridge: bool)
signal target_finished
signal pose_clip_finished(clip_name: String)
signal scrub_returned

const ClawSceneAudio := preload("res://Scripts/audio/claw_scene_audio.gd")
const ACTION_ROOT := "res://NewMotion/动作"
const COLOR_PROFILE_PATH := "res://NewMotion/动作/_color_profile.json"
const VOICE_MAP_PATH := "res://config/newmotion_action_voice_map.json"
const IDLE_CLIP := "youyou_Idlebreath"
const PLAYBACK_FPS := 24.0
const VIEWPORT_SIZE := Vector2i(1920, 1080)
const CHARACTER_HEIGHT_RATIO := 0.60
const PREFETCH_IN_FLIGHT := 1
const PREFETCH_COMMIT_BUDGET := 1
## 待播/操作关键片（左右看）加快提交，避免按 A/D 时整段一次性灌进 SpriteFrames 卡顿
const PREFETCH_COMMIT_URGENT := 10
const DECODE_TIMEOUT_MS := 12000
static var _upload_frame := 0
static var _uploads := 0
## 倾身待机第 0 帧的身体高度和脚点。新导入的柚柚站立片子按这个身高对齐。
const YOUYOU_REF_BODY_H := 1036.0
const YOUYOU_REF_FEET := Vector2(964, 1076)
const YOUYOU_REF_CENTER := Vector2(960, 540)
## standup 第 0 帧实测身体高和脚点。蹲着待机按这个人和这个落点摆。
const YOUYOU_STANDUP_BODY_H := 894.0
const YOUYOU_STANDUP_FEET := Vector2(963, 1078)
## 呼吸待机第 0 帧脚点（1280×720 画布）。倾听等语音片按这个落点接上。
const YOUYOU_BREATH_FEET := Vector2(638, 718)
const YOUYOU_BREATH_CANVAS := Vector2(1280, 720)
## 柚柚和兜兜共用的下移（屏幕像素，正值向下）。
const STAGE_DROP_Y := 48.0
## 只抬柚柚，避开底部招揽条。兜兜仍用 STAGE_DROP_Y。
const YOUYOU_UI_LIFT_Y := 100.0
## 兜兜待机第 0 帧的身体高度。兜兜的片子按这个身高，不跟柚柚走。
const DOUDOU_REF_BODY_H := 784.0
const REF_CANVAS_H := 1080.0
const YOUYOU_LOCKED_PLACEMENT: Array[String] = [
	"youyou_Idlebreath",
	"AI-listen",
	"youyou_Basecontrol_lean",
	"youyou_Basecontrol_keeplean",
	"youyou_Basecontrol_lookleft",
	"youyou_Basecontrol_lookright",
	"youyou_control_lookforward",
	"youyou_control_lookback",
	"youyou_Basecontrol_squat",
	"youyou_Basecontrol_keepSquat",
	"youyou_Basecontrol_standup",
]

var _shared_frames: SpriteFrames = SpriteFrames.new()
var _bank: SpriteFrames = SpriteFrames.new()
var _retiring: SpriteFrames
var _playing := ""
var _looping := false
var _queued_name := ""
var _queued_loop := false
var _bridging := false
var _finished_hooked := false
var _shared_ready := false
var _suppress_target := false
var _scrub := false
var _scrub_hold := false
var _scrub_at_end := false

var _pinned := {}
var _prefetch_queue: Array[String] = []
var _prefetch_files := {}
var _prefetch_index := {}
var _expected_frames := {}
var _prefetch_slots := {}
var _prefetch_commit := {}
var _flight_paths: Array[String] = []
var _flight_action := {}
var _flight_index := {}
var _flight_started_at := {}
var _decode_slots := 0
var _evict_pending: Array[String] = []
var _pending_name := ""
var _alive := true
var _pending_loop := false
var _pending_scrub := false
## 倾身待机这类长循环：有首帧就开播，后面边播边补，避免干等全片齐了才切。
var _streaming_name := ""
var _stream_speed := 1.0
var _ready_frames: Array = []
var _focus_name := ""
var _hot_next := ""
var _body_cache := {}
var _frame_meta := {}

## 测试场景可关，避免和预览播放器叠音；正式调用保持开启。
var auto_play_voice := true
## 按 NewMotion/动作/_color_profile.json 对片段做 RGB gain（像素级校准后可关）。
@export var auto_color_match := true
## 兜兜把整张 1920 画布贴在画面上，人物位置跟着片子走，不再按柚柚脚点重摆。
@export var pin_idle_on_ready := true
@export var fit_frame_to_view := false
## 兜兜整张画布先贴进画面，再按兜兜待机的身高修正。不跟柚柚的身高走。
@export var frame_fit_scale := 1.0
## 画面上的额外位移。兜兜用一点上移，显得站在柚柚后面。
@export var frame_depth_offset := Vector2.ZERO
var frame_offset := Vector2.ZERO
var _voice_entries: Dictionary = {}
var _voice_player: AudioStreamPlayer
var _voice_delay_left := -1.0
var _waiting_voice := false
## [{ "left": float, "stream": AudioStream, "pitch": float }, ...]
var _voice_cue_queue: Array = []
var _cue_players: Array[AudioStreamPlayer] = []
var _color_gains: Dictionary = {}
var _color_profile_loaded := false


func _exit_tree() -> void:
	_alive = false
	set_process(false)
	for path in _flight_paths:
		SpriteFramePacker.forget_decode(path)
	_flight_paths.clear()
	_flight_action.clear()
	_flight_index.clear()
	_flight_started_at.clear()
	_decode_slots = 0
	_evict_pending.clear()
	_ready_frames.clear()
	_retiring = null


func _ready() -> void:
	_alive = true
	if not frame_changed.is_connected(_apply_frame_offset):
		frame_changed.connect(_apply_frame_offset)
	_load_voice_map()
	_load_color_profile()
	_ensure_voice_player()
	_ensure_shared_frames()
	if pin_idle_on_ready:
		prefetch_clip(IDLE_CLIP, true)


func reload_voice_map() -> void:
	_load_voice_map()


func reload_color_profile() -> void:
	_color_profile_loaded = false
	_load_color_profile()
	if _playing != "":
		_apply_color_match(_playing)


func apply_voice_entry(action_name: String, entry: Dictionary) -> void:
	if action_name == "":
		return
	_voice_entries[action_name] = entry.duplicate(true)


func is_voice_playing() -> bool:
	if _waiting_voice or not _voice_cue_queue.is_empty():
		return true
	if _voice_player != null and _voice_player.playing:
		return true
	for player in _cue_players:
		if is_instance_valid(player) and player.playing:
			return true
	return false


func stop_playback() -> void:
	_stop_voice()
	super.stop()


func hold_current_frame() -> void:
	_queued_name = ""
	_queued_loop = false
	_bridging = false
	_stop_voice()
	pause()


func current_clip() -> String:
	return _playing


func is_looping_clip() -> bool:
	return _looping


func is_bridging() -> bool:
	return _bridging or _queued_name != ""


func is_scrubbing() -> bool:
	return _scrub


func is_scrub_at_end() -> bool:
	return _scrub and _scrub_at_end


func has_clip_ready(action_name: String) -> bool:
	return _is_resident(action_name)


func is_clip_streaming(action_name: String = "") -> bool:
	if _streaming_name == "":
		return false
	if action_name == "":
		return true
	return _streaming_name == action_name


func clip_frame_count(action_name: String) -> int:
	if not _is_resident(action_name):
		return 0
	return _frame_count(action_name)


func clip_frame_texture(action_name: String, frame_index: int) -> Texture2D:
	if not _is_resident(action_name):
		return null
	return _frame_texture(action_name, frame_index)


func current_frame_texture() -> Texture2D:
	if _playing == "" or not _is_resident(_playing):
		return null
	return _frame_texture(_playing, frame)


func set_frame_offset(offset: Vector2) -> void:
	frame_offset = offset


func set_target_suppressed(on: bool) -> void:
	_suppress_target = on


## 当前帧脚点的屏幕坐标（用于对戏片脚点承接）。
func capture_feet_screen() -> Vector2:
	return _feet_screen_for(String(animation), frame)


## 把当前帧脚点挪到 target 屏幕坐标（播下一段前调用，承接上一段结束位）。
func align_feet_to_screen(target: Vector2) -> void:
	var now := _feet_screen_for(String(animation), frame)
	var delta := target - now
	if delta.length_squared() < 0.01:
		return
	if fit_frame_to_view:
		frame_offset += delta
		position = Vector2(VIEWPORT_SIZE) * 0.5 + frame_offset + frame_depth_offset
		position.y += STAGE_DROP_Y
	else:
		position += delta


func _feet_screen_for(clip_name: String, frame_index: int) -> Vector2:
	if clip_name == "":
		return position
	var layout := frame_layout(clip_name, frame_index)
	var scale_factor := scale.x
	if layout.is_empty():
		return position
	var feet_full := Vector2(
		float(layout.get("crop_x", 0)) + float(layout.get("feet_x", 0)),
		float(layout.get("crop_y", 0)) + float(layout.get("feet_y", 0))
	)
	var full_center := Vector2(
		float(layout.get("full_w", VIEWPORT_SIZE.x)) * 0.5,
		float(layout.get("full_h", VIEWPORT_SIZE.y)) * 0.5
	)
	return position + (feet_full - full_center) * scale_factor


## 按住时正放。松手从当前帧倒放，回到第 0 帧后发出 scrub_returned。
func begin_scrub(action_name: String) -> bool:
	_queued_name = ""
	_queued_loop = false
	if not _is_resident(action_name):
		_arm_pending(action_name, false, true)
		return true
	_pending_name = ""
	_scrub = false
	_scrub_hold = true
	_scrub_at_end = false
	if not _start_clip(action_name, false, false):
		return false
	_stop_voice()
	_scrub = true
	_scrub_hold = true
	_scrub_at_end = false
	speed_scale = 1.0
	return true


func set_scrub_hold(held: bool) -> void:
	if not _scrub:
		return
	if held:
		_scrub_hold = true
		if _scrub_at_end:
			return
		var held_frame := frame
		speed_scale = 1.0
		if not is_playing():
			play(_playing)
			set_frame_and_progress(held_frame, 0.0)
		return
	if not _scrub_hold and speed_scale < 0.0:
		return
	_scrub_hold = false
	if frame <= 0 and not _scrub_at_end:
		_finish_scrub()
		return
	var held_frame := frame
	if _scrub_at_end:
		held_frame = maxi(0, _shared_frames.get_frame_count(_playing) - 1)
	_scrub_at_end = false
	var was_playing := is_playing()
	speed_scale = -1.0
	if not was_playing:
		play(_playing)
		frame = held_frame


func cancel_scrub() -> void:
	_scrub = false
	_scrub_hold = false
	_scrub_at_end = false
	if speed_scale < 0.0:
		speed_scale = 1.0


func pin_clips(action_names: PackedStringArray) -> void:
	## 钉住的可并存预载，不走 hot_next 互挤（否则左右看只会留一边）
	for action_name in action_names:
		if action_name == "":
			continue
		_pinned[action_name] = true
		if _is_resident(action_name):
			continue
		_enqueue_prefetch(action_name, false)
		set_process(true)


func unpin_clips(action_names: PackedStringArray) -> void:
	for action_name in action_names:
		_pinned.erase(action_name)
	_evict_unpinned()


func discard_unused_clips() -> void:
	_hot_next = ""
	_focus_name = ""
	_queued_name = ""
	_pending_name = ""
	_streaming_name = ""
	_prefetch_queue.clear()
	_prefetch_files.clear()
	_prefetch_index.clear()
	_prefetch_slots.clear()
	_prefetch_commit.clear()
	_ready_frames.clear()
	_evict_unpinned()


## 马上要播的这一段。和「下一段」分开，避免下一段把当前这段从队列里挤掉。
func focus_clip(action_name: String) -> void:
	if action_name == "" or action_name == _playing:
		return
	if _is_resident(action_name):
		if _focus_name == action_name:
			_focus_name = ""
		return
	if _focus_name != action_name:
		var old := _focus_name
		_focus_name = action_name
		if old != "":
			_release_unneeded(old)
	_enqueue_prefetch(action_name, true)
	set_process(true)


## 只保留一个下一段。新的下一段会换掉上一个还没播的预加载。
func prefetch_clip(action_name: String, urgent: bool = false) -> void:
	if (
		action_name == ""
		or action_name == _playing
		or action_name == _pending_name
		or action_name == _focus_name
	):
		return
	if action_name == _hot_next:
		if not _is_resident(action_name):
			_enqueue_prefetch(action_name, urgent)
			set_process(true)
		return
	var old := _hot_next
	_hot_next = action_name
	if old != "" and old != action_name:
		_release_unneeded(old)
	if _is_resident(action_name):
		_evict_unpinned()
		return
	_enqueue_prefetch(action_name, urgent)
	set_process(true)


func play_clip(action_name: String, loop: bool, via_idle: bool = true) -> bool:
	if action_name == "":
		return false
	_ensure_shared_frames()
	_ensure_finished_hook()
	var want_bridge := (
		via_idle
		and action_name != IDLE_CLIP
		and _playing != ""
		and _playing != IDLE_CLIP
		and _playing != action_name
		and _is_resident(IDLE_CLIP)
	)
	if want_bridge:
		_pending_name = ""
		_queued_name = action_name
		_queued_loop = loop
		var ok := _start_clip(IDLE_CLIP, false, true)
		prefetch_clip(action_name, true)
		if ok:
			_evict_unpinned()
		return ok
	_queued_name = ""
	_queued_loop = false
	_bridging = false
	if _is_resident(action_name):
		_pending_name = ""
		var started := _start_clip(action_name, loop, false)
		if started:
			_evict_unpinned()
		return started
	_arm_pending(action_name, loop, false)
	## 长片不必等全齐：第 0 帧在就能切过去，剩下的边播边补。
	_try_stream_pending()
	return true


func _process(delta: float) -> void:
	if not _alive:
		return
	_pump_prefetch(delta)
	_retire_one()
	_drain_evict_one()
	if _waiting_voice:
		_voice_delay_left -= delta
		if _voice_delay_left <= 0.0:
			_waiting_voice = false
			if _voice_player != null and _voice_player.stream != null:
				_voice_player.play()
	_tick_voice_cues(delta)
	_hold_stream_frontier()
	if (
		_prefetch_queue.is_empty()
		and _pending_name == ""
		and _streaming_name == ""
		and _focus_name == ""
		and _hot_next == ""
		and _flight_paths.is_empty()
		and _ready_frames.is_empty()
		and _retiring == null
		and _evict_pending.is_empty()
		and not _waiting_voice
		and _voice_cue_queue.is_empty()
	):
		set_process(false)


func _ensure_finished_hook() -> void:
	if _finished_hooked:
		return
	if not animation_finished.is_connected(_on_own_finished):
		animation_finished.connect(_on_own_finished)
	_finished_hooked = true


func _on_own_finished() -> void:
	if _scrub:
		_on_scrub_finished()
		return
	if _queued_name != "":
		var next_name := _queued_name
		var next_loop := _queued_loop
		_queued_name = ""
		_queued_loop = false
		if _is_resident(next_name):
			_start_clip(next_name, next_loop, false)
			_evict_unpinned()
		else:
			_arm_pending(next_name, next_loop, false)
		return
	if _bridging:
		return
	if _streaming_name != "" and _playing == _streaming_name and not _is_resident(_playing):
		_pin_stream_playhead()
		return
	if _looping:
		# 循环片交给 SpriteFrames.loop，不要再 play() 一次，否则会闪回第 0 帧。
		if _playing != "" and _is_resident(_playing):
			_shared_frames.set_animation_loop(_playing, true)
		return
	var finished := _playing
	pose_clip_finished.emit(finished)
	if _playing != finished or _pending_name != "" or _queued_name != "":
		return
	if _suppress_target:
		return
	target_finished.emit()


func _on_scrub_finished() -> void:
	if speed_scale < 0.0 or frame <= 0:
		_finish_scrub()
		return
	_scrub_at_end = true
	var last := maxi(0, _shared_frames.get_frame_count(_playing) - 1)
	frame = last
	pause()
	if not _scrub_hold:
		set_scrub_hold(false)


func _finish_scrub() -> void:
	if not _scrub:
		return
	_scrub = false
	_scrub_hold = false
	_scrub_at_end = false
	speed_scale = 1.0
	pause()
	scrub_returned.emit()


func _start_clip(action_name: String, loop: bool, is_bridge: bool) -> bool:
	_scrub = false
	_scrub_hold = false
	_scrub_at_end = false
	_ensure_shared_frames()
	var full := _is_resident(action_name)
	if _frame_count(action_name) < 1 or _frame_texture(action_name, 0) == null:
		return false
	if not full and _streaming_name != action_name:
		return false
	_promote_bank(action_name)
	## 还没齐时先别循环，否则播到已有末帧会跳回第 0 帧。
	_shared_frames.set_animation_loop(action_name, loop and full)
	var sample := _shared_frames.get_frame_texture(action_name, 0)
	if sample == null:
		return false
	if sprite_frames != _shared_frames:
		sprite_frames = _shared_frames
	var same_clip := _playing == action_name and animation == action_name and is_playing()
	animation = action_name
	_place_character(sample)
	if is_bridge:
		speed_scale = 1.0
		_stop_voice()
	else:
		_apply_mapped_voice(action_name)
	if same_clip and loop:
		_playing = action_name
		_looping = loop
		_bridging = is_bridge
		return true
	play(action_name)
	set_frame_and_progress(0, 0.0)
	_playing = action_name
	_looping = loop
	_bridging = is_bridge
	_apply_color_match(action_name)
	_apply_frame_offset()
	## offset 落定后再按脚点微调一次，避免 meta 晚到时蹲着待机对不齐 standup。
	if action_name == "youyou_Basecontrol_keepSquat":
		_snap_keep_squat_feet_to_standup()
	clip_started.emit(action_name, is_bridge)
	return true


func _ensure_shared_frames() -> void:
	if _shared_ready:
		return
	if _shared_frames.has_animation(&"default"):
		_shared_frames.remove_animation(&"default")
	sprite_frames = _shared_frames
	_shared_ready = true


func _is_resident(action_name: String) -> bool:
	if action_name == "" or not _expected_frames.has(action_name):
		return false
	return _frame_count(action_name) >= int(_expected_frames[action_name])


func _frame_count(action_name: String) -> int:
	var count := 0
	if _shared_frames.has_animation(action_name):
		count = _shared_frames.get_frame_count(action_name)
	if _bank.has_animation(action_name):
		count = maxi(count, _bank.get_frame_count(action_name))
	return count


func _frame_texture(action_name: String, frame_index: int) -> Texture2D:
	if _shared_frames.has_animation(action_name):
		var count := _shared_frames.get_frame_count(action_name)
		if frame_index >= 0 and frame_index < count:
			return _shared_frames.get_frame_texture(action_name, frame_index)
	if _bank.has_animation(action_name):
		var count := _bank.get_frame_count(action_name)
		if frame_index >= 0 and frame_index < count:
			return _bank.get_frame_texture(action_name, frame_index)
	return null


func _promote_bank(action_name: String) -> void:
	## 只把目标动画并进 shared，禁止整库交换（否则倾身待机上百帧一次性换掉会卡一下）
	if not _bank.has_animation(action_name):
		return
	var bank_count := _bank.get_frame_count(action_name)
	var shared_count := 0
	if _shared_frames.has_animation(action_name):
		shared_count = _shared_frames.get_frame_count(action_name)
	## bank 更完整时整段替换 shared（勿逐帧 remove_frame，会触发 atlas 卡死）
	if bank_count > 0 and bank_count >= shared_count:
		if _shared_frames.has_animation(action_name):
			_shared_frames.remove_animation(action_name)
		_shared_frames.add_animation(action_name)
		_shared_frames.set_animation_speed(action_name, PLAYBACK_FPS)
		_shared_frames.set_animation_loop(action_name, _bank.get_animation_loop(action_name))
		for i in bank_count:
			_shared_frames.add_frame(
				action_name,
				_bank.get_frame_texture(action_name, i),
				_bank.get_frame_duration(action_name, i)
			)
	_bank.remove_animation(action_name)
	if sprite_frames != _shared_frames:
		sprite_frames = _shared_frames
	_shared_ready = true


func _retire_one() -> void:
	if _retiring == null:
		return
	# 旧 SpriteFrames 整库释放；逐帧 remove_frame 会反复触发引擎 atlas 打包导致长时间卡死。
	_retiring = null


func _list_png_names(action_name: String) -> PackedStringArray:
	var file_names := NewMotionActionFs.list_frame_names(action_name)
	if file_names.is_empty():
		push_error("打不开动作: %s" % NewMotionActionFs.clip_dir(action_name))
	return file_names


func _arm_pending(action_name: String, loop: bool, as_scrub: bool) -> void:
	_pending_name = action_name
	_pending_loop = loop
	_pending_scrub = as_scrub
	prefetch_clip(action_name, true)


func _enqueue_prefetch(action_name: String, urgent: bool) -> void:
	var kept: Array[String] = []
	for queued in _prefetch_queue:
		if queued != action_name:
			kept.append(queued)
	if urgent:
		var front: Array[String] = [action_name]
		front.append_array(kept)
		_prefetch_queue = front
	else:
		kept.append(action_name)
		_prefetch_queue = kept


func _pump_prefetch(delta: float = 0.0) -> void:
	if _streaming_name != "" and not _is_resident(_streaming_name):
		_focus_name = _streaming_name
	elif _focus_name != "" and _focus_name == _playing:
		_focus_name = ""
	var target := ""
	if _streaming_name != "" and not _is_resident(_streaming_name):
		target = _streaming_name
	elif _pending_name != "" and not _is_resident(_pending_name):
		target = _pending_name
	elif _focus_name != "" and not _is_resident(_focus_name):
		target = _focus_name
	elif _hot_next != "" and not _is_resident(_hot_next):
		target = _hot_next
	elif not _prefetch_queue.is_empty():
		target = _prefetch_queue[0]
	if target != "" and _is_resident(target):
		_drop_queued(target)
		if _pending_name == target:
			_start_pending()
		target = ""
	## 待播 scrub / 钉住片加载时不因帧时过长停解码（否则 A/D 一直等）
	var urgent := _pending_name != "" or _pending_scrub or (_focus_name != "" and not _is_resident(_focus_name))
	var busy := (not urgent) and is_playing() and delta > 0.034
	if target != "" and not busy:
		_ensure_prefetch_job(target)
		_request_prefetch(target)
	_collect_prefetch(not busy, urgent and _streaming_name == "")
	_try_stream_pending()
	if target != "" and _is_resident(target):
		_drop_queued(target)
		if _pending_name == target:
			_start_pending()
		elif _streaming_name == target:
			_finish_stream()


func _ensure_prefetch_job(action_name: String) -> void:
	if _prefetch_files.has(action_name):
		return
	var files := _list_png_names(action_name)
	if files.is_empty():
		push_error("动作没有序列帧: %s" % action_name)
		_drop_queued(action_name)
		if _pending_name == action_name:
			_pending_name = ""
		return
	_prefetch_files[action_name] = files
	_prefetch_index[action_name] = 0
	_prefetch_commit[action_name] = 0
	_expected_frames[action_name] = files.size()
	var slots: Array = []
	slots.resize(files.size())
	_prefetch_slots[action_name] = slots
	var metas: Array = []
	metas.resize(files.size())
	_frame_meta[action_name] = metas
	if not _bank.has_animation(action_name):
		_bank.add_animation(action_name)
		_bank.set_animation_speed(action_name, PLAYBACK_FPS)


func _request_prefetch(action_name: String) -> void:
	if not _prefetch_files.has(action_name):
		return
	var files: PackedStringArray = _prefetch_files[action_name]
	var next := int(_prefetch_index[action_name])
	var folder := NewMotionActionFs.clip_dir(action_name)
	while _decode_slots < PREFETCH_IN_FLIGHT and _flight_paths.size() + _ready_frames.size() < PREFETCH_IN_FLIGHT and next < files.size():
		var path := folder.path_join(files[next])
		SpriteFramePacker.submit_decode(path, NewMotionActionFs.load_canvas(action_name))
		_decode_slots += 1
		_flight_paths.append(path)
		_flight_action[path] = action_name
		_flight_index[path] = next
		_flight_started_at[path] = Time.get_ticks_msec()
		next += 1
	_prefetch_index[action_name] = next


func _collect_prefetch(allow_upload: bool, urgent: bool = false) -> void:
	if not _alive:
		return
	var still: Array[String] = []
	for path in _flight_paths:
		var payload: Variant = SpriteFramePacker.take_decode(path)
		if payload == null:
			var started := int(_flight_started_at.get(path, 0))
			if started > 0 and Time.get_ticks_msec() - started > DECODE_TIMEOUT_MS:
				SpriteFramePacker.forget_decode(path)
				_decode_slots = maxi(0, _decode_slots - 1)
				_flight_action.erase(path)
				_flight_index.erase(path)
				_flight_started_at.erase(path)
				push_warning("序列帧解码超时，已跳过: %s" % path)
			else:
				still.append(path)
			continue
		_decode_slots = maxi(0, _decode_slots - 1)
		var action_name := String(_flight_action.get(path, ""))
		var index := int(_flight_index.get(path, -1))
		_flight_action.erase(path)
		_flight_index.erase(path)
		_flight_started_at.erase(path)
		if _prefetch_slots.has(action_name):
			_ready_frames.append({"action": action_name, "index": index, "payload": payload})
	_flight_paths = still
	if not allow_upload or _ready_frames.is_empty() or not _take_upload_slot():
		return
	if not _ready_frames.is_empty():
		var item: Dictionary = _ready_frames.pop_front()
		var ready_action := String(item.get("action", ""))
		var ready_index := int(item.get("index", -1))
		var payload: Variant = item.get("payload")
		var ready_image: Image = null
		var meta: Dictionary = {}
		if payload is Dictionary:
			meta = (payload as Dictionary).duplicate()
			ready_image = meta.get("image")
			meta.erase("image")
		elif payload is Image:
			ready_image = payload
		var texture: Texture2D = null
		if ready_image != null and not ready_image.is_empty() and _prefetch_slots.has(ready_action):
			texture = ImageTexture.create_from_image(ready_image)
		if ready_action != "" and ready_index >= 0:
			_store_prefetched_frame(ready_action, ready_index, texture, meta)
	var budget := PREFETCH_COMMIT_URGENT if urgent else PREFETCH_COMMIT_BUDGET
	var committed := 0
	var actions: Array = _prefetch_slots.keys()
	## 待播 / 钉住片优先提交
	actions.sort_custom(func(a, b) -> bool:
		return _commit_priority(String(a)) > _commit_priority(String(b))
	)
	for action_name in actions:
		committed += _commit_prefetched(String(action_name), budget - committed)
		if committed >= budget:
			break


func _take_upload_slot() -> bool:
	var now := Engine.get_process_frames()
	if now != _upload_frame:
		_upload_frame = now
		_uploads = 0
	if _uploads >= 1:
		return false
	_uploads += 1
	return true


func _store_prefetched_frame(action_name: String, index: int, texture: Texture2D, meta: Dictionary = {}) -> void:
	if not _prefetch_slots.has(action_name):
		return
	var slots: Array = _prefetch_slots[action_name]
	if index < 0 or index >= slots.size() or slots[index] != null:
		return
	slots[index] = texture if texture != null else _blank_frame()
	_prefetch_slots[action_name] = slots
	if not _frame_meta.has(action_name):
		return
	var metas: Array = _frame_meta[action_name]
	if index < 0 or index >= metas.size() or metas[index] != null:
		return
	if meta.is_empty():
		meta = {
			"offset": Vector2.ZERO,
			"full_w": 4,
			"full_h": 4,
			"crop_x": 0,
			"crop_y": 0,
			"crop_w": 4,
			"crop_h": 4,
			"min_x": 0,
			"max_x": 0,
			"feet_x": 2,
			"feet_y": 3,
			"body_w": 0,
			"body_h": 0,
			"standing": false,
		}
	metas[index] = meta


func _commit_priority(action_name: String) -> int:
	if action_name == _pending_name:
		return 3
	if action_name == _focus_name:
		return 2
	if _pinned.has(action_name):
		return 1
	return 0


func _commit_dest(action_name: String) -> SpriteFrames:
	## 已开始写入的目的地必须固定：看那边预载待机进 bank 后 focus 切 shared，
	## 若中途换 dest 会把前后半段拆开，has_clip_ready 永远等不到 → 不进待机/战术指导。
	var shared_n := 0
	if _shared_frames.has_animation(action_name):
		shared_n = _shared_frames.get_frame_count(action_name)
	var bank_n := 0
	if _bank.has_animation(action_name):
		bank_n = _bank.get_frame_count(action_name)
	if shared_n > 0:
		return _shared_frames
	if bank_n > 0:
		return _bank
	## 钉住 / 待播 / 焦点片直接进 shared，按 A/D 时不必再整段 promote
	if (
		_pinned.has(action_name)
		or action_name == _pending_name
		or action_name == _focus_name
	):
		return _shared_frames
	return _bank


func _commit_prefetched(action_name: String, budget: int) -> int:
	if budget <= 0 or not _prefetch_slots.has(action_name):
		return 0
	var dest := _commit_dest(action_name)
	if not dest.has_animation(action_name):
		dest.add_animation(action_name)
		dest.set_animation_speed(action_name, PLAYBACK_FPS)
	var slots: Array = _prefetch_slots[action_name]
	var cursor := int(_prefetch_commit.get(action_name, 0))
	var added := 0
	while added < budget and cursor < slots.size() and slots[cursor] != null:
		dest.add_frame(action_name, slots[cursor])
		cursor += 1
		added += 1
	_prefetch_commit[action_name] = cursor
	if cursor >= slots.size():
		_expected_frames[action_name] = maxi(dest.get_frame_count(action_name), 1)
		_prefetch_slots.erase(action_name)
	return added


func _blank_frame() -> Texture2D:
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(image)


func _drop_queued(action_name: String) -> void:
	if action_name == "":
		return
	var kept: Array[String] = []
	for queued in _prefetch_queue:
		if queued != action_name:
			kept.append(queued)
	_prefetch_queue = kept


func _try_stream_pending() -> void:
	if _pending_name == "" or _pending_scrub or _playing == _pending_name:
		return
	if _frame_count(_pending_name) < 1 or _frame_texture(_pending_name, 0) == null:
		return
	var action_name := _pending_name
	var loop := _pending_loop
	_pending_name = ""
	_pending_loop = false
	_streaming_name = action_name
	_stream_speed = 1.0
	_focus_name = action_name
	if _start_clip(action_name, loop, false):
		_hold_stream_frontier()
		return
	_streaming_name = ""
	_pending_name = action_name
	_pending_loop = loop


func _hold_stream_frontier() -> void:
	if _streaming_name == "" or _playing != _streaming_name:
		return
	if _is_resident(_streaming_name):
		_finish_stream()
		return
	var have := _frame_count(_playing)
	if have <= 0:
		return
	if frame >= have - 1:
		_pin_stream_playhead()
	elif speed_scale == 0.0 and _stream_speed != 0.0:
		speed_scale = _stream_speed


func _pin_stream_playhead() -> void:
	var have := _frame_count(_playing)
	if have <= 0:
		return
	var last := have - 1
	if speed_scale != 0.0:
		_stream_speed = speed_scale
	var restart := not is_playing()
	frame = last
	frame_progress = 0.0
	speed_scale = 0.0
	if restart:
		play(_playing)
		frame = last
		frame_progress = 0.0
		speed_scale = 0.0


func _finish_stream() -> void:
	var action_name := _streaming_name
	if action_name == "":
		return
	_streaming_name = ""
	if _focus_name == action_name:
		_focus_name = ""
	if _shared_frames.has_animation(action_name):
		_shared_frames.set_animation_loop(action_name, _looping and _playing == action_name)
	var resume := _stream_speed if _stream_speed != 0.0 else 1.0
	if _playing != action_name:
		return
	if speed_scale == 0.0:
		speed_scale = resume
	if _looping and not is_playing():
		var held := frame
		var progress := frame_progress
		play(action_name)
		frame = held
		frame_progress = progress
		speed_scale = resume


func _start_pending() -> void:
	var action_name := _pending_name
	var loop := _pending_loop
	var as_scrub := _pending_scrub
	_pending_name = ""
	_pending_scrub = false
	if action_name == "":
		return
	if as_scrub:
		begin_scrub(action_name)
		return
	if _playing == action_name:
		_streaming_name = ""
		if speed_scale == 0.0:
			speed_scale = _stream_speed if _stream_speed != 0.0 else 1.0
		return
	if _start_clip(action_name, loop, false):
		_evict_unpinned()


func _keep_loaded(anim_name: String) -> bool:
	return (
		_pinned.has(anim_name)
		or anim_name == _playing
		or anim_name == _queued_name
		or anim_name == _pending_name
		or anim_name == _focus_name
		or anim_name == _hot_next
		or anim_name == _streaming_name
	)


func _release_unneeded(action_name: String) -> void:
	if action_name == "" or _keep_loaded(action_name):
		return
	_drop_queued(action_name)
	_prefetch_files.erase(action_name)
	_prefetch_index.erase(action_name)
	_prefetch_slots.erase(action_name)
	_prefetch_commit.erase(action_name)
	_expected_frames.erase(action_name)
	_frame_meta.erase(action_name)
	_body_cache.erase(action_name)
	var kept_ready: Array = []
	for item in _ready_frames:
		if typeof(item) != TYPE_DICTIONARY or String(item.get("action", "")) != action_name:
			kept_ready.append(item)
	_ready_frames = kept_ready
	_queue_evict_animation(action_name)


func _queue_evict_animation(action_name: String) -> void:
	if action_name == "" or _keep_loaded(action_name):
		return
	if action_name in _evict_pending:
		return
	_evict_pending.append(action_name)
	set_process(true)


func _drain_evict_one() -> void:
	if _evict_pending.is_empty():
		return
	var action_name := _evict_pending[0]
	_evict_pending.remove_at(0)
	if _keep_loaded(action_name):
		return
	if _shared_frames.has_animation(action_name) and action_name != _playing:
		_shared_frames.remove_animation(action_name)
	if _bank.has_animation(action_name):
		_bank.remove_animation(action_name)


func _evict_unpinned() -> void:
	var drop: Array[String] = []
	for anim_name in _shared_frames.get_animation_names():
		var name := String(anim_name)
		if not _keep_loaded(name):
			drop.append(name)
	for anim_name in _bank.get_animation_names():
		var name := String(anim_name)
		if not _keep_loaded(name) and name not in drop:
			drop.append(name)
	for name in drop:
		_release_unneeded(name)


func frame_layout(action_name: String, frame_index: int) -> Dictionary:
	if action_name == "" or not _frame_meta.has(action_name):
		return {}
	var metas: Array = _frame_meta[action_name]
	if frame_index < 0 or frame_index >= metas.size():
		return {}
	var meta: Variant = metas[frame_index]
	if typeof(meta) != TYPE_DICTIONARY:
		return {}
	return meta


func _apply_frame_offset() -> void:
	var clip := String(animation)
	## 蹲着待机脚在画面里几乎不动，但逐帧 offset 会把整个人抬上抬下。锁在第 0 帧的落点。
	if clip == "youyou_Basecontrol_keepSquat":
		var keep_layout := _keep_squat_layout(clip, current_frame_texture())
		offset = keep_layout.get("offset", Vector2.ZERO)
		return
	var layout := frame_layout(clip, frame)
	offset = layout.get("offset", Vector2.ZERO)


func _full_canvas(clip_name: String, sample: Texture2D) -> Vector2:
	var layout := frame_layout(clip_name, 0)
	if not layout.is_empty():
		return Vector2(float(layout.get("full_w", 1)), float(layout.get("full_h", 1)))
	## meta 还没到时也读 canvas.json，避免把裁图高度当成整幅画布把人放大。
	if clip_name != "":
		var canvas := NewMotionActionFs.load_canvas(clip_name)
		if not canvas.is_empty():
			return Vector2(float(canvas.get("full_w", 1920)), float(canvas.get("full_h", 1080)))
	if sample != null:
		return Vector2(sample.get_width(), sample.get_height())
	return Vector2(1920, 1080)


func uniform_scale_for_texture(tex: Texture2D, clip_name: String) -> float:
	if tex == null:
		return 1.0
	var tex_h := _full_canvas(clip_name, tex).y
	var viewport_y := float(VIEWPORT_SIZE.y)
	if tex_h <= 1.0:
		return 1.0
	if fit_frame_to_view:
		var canvas_scale := viewport_y / tex_h * frame_fit_scale
		var body := _metrics_for(clip_name, tex)
		if body.is_empty() or not bool(body.get("standing", false)):
			return canvas_scale
		var ref_screen := DOUDOU_REF_BODY_H * viewport_y / REF_CANVAS_H * frame_fit_scale
		var body_h := float(body.get("h", 0.0))
		if body_h < 8.0:
			return canvas_scale
		return ref_screen / body_h
	return viewport_y * CHARACTER_HEIGHT_RATIO / tex_h


func _place_character(sample: Texture2D) -> void:
	var clip_name := String(animation)
	var viewport := Vector2(VIEWPORT_SIZE)
	var scale_factor := uniform_scale_for_texture(sample, clip_name)
	scale = Vector2(scale_factor, scale_factor)
	if fit_frame_to_view:
		position = viewport * 0.5 + frame_offset + frame_depth_offset
		position.y += STAGE_DROP_Y
		return
	var matched := _youyou_body_match(clip_name, sample)
	if not matched.is_empty():
		var ref_scale := viewport.y * CHARACTER_HEIGHT_RATIO / REF_CANVAS_H
		var ref_feet_screen := viewport * 0.5 + (YOUYOU_REF_FEET - YOUYOU_REF_CENTER) * ref_scale
		var center := Vector2(float(matched.get("tex_w", sample.get_width())), float(matched.get("tex_h", sample.get_height()))) * 0.5
		var feet := Vector2(float(matched.get("feet_x", 0.0)), float(matched.get("feet_y", 0.0)))
		var body_h := float(matched.get("h", 1.0))
		var matched_scale := YOUYOU_REF_BODY_H * ref_scale / body_h
		scale = Vector2(matched_scale, matched_scale)
		position = ref_feet_screen - (feet - center) * matched_scale
		position.y += _youyou_stage_drop()
		return
	position = viewport * 0.5
	# 向前看、仰头都是整幅画布，人比紧裁的倾身待机小。缩到倾身待机同一身高，脚点对齐。
	if clip_name == "youyou_control_lookforward" or clip_name == "youyou_control_lookback":
		var layout := frame_layout(clip_name, 0)
		var body_h := float(layout.get("body_h", 0.0))
		if body_h > 8.0:
			var lean_scale := viewport.y * CHARACTER_HEIGHT_RATIO / 1058.0
			var lean_feet := viewport * 0.5 + Vector2(-1.5, 528.0) * lean_scale
			var look_scale := lean_scale * 1042.0 / body_h
			scale = Vector2(look_scale, look_scale)
			var crop_center := Vector2(float(layout.get("crop_w", 1.0)), float(layout.get("crop_h", 1.0))) * 0.5
			var feet_local := Vector2(float(layout.get("feet_x", 0.0)), float(layout.get("feet_y", 0.0))) - crop_center
			var sprite_offset: Vector2 = layout.get("offset", Vector2.ZERO)
			position = lean_feet - (sprite_offset + feet_local) * look_scale
	# 蹲着待机裁图更矮，按裁图高度会放大。按 standup 第 0 帧身高和脚点对齐。
	if clip_name == "youyou_Basecontrol_keepSquat":
		_align_keep_squat_to_standup(clip_name, sample)
	# 倾听与呼吸待机同是 1280 画布，但裁图更宽、脚点偏左。缩到同一比例后把脚对齐呼吸待机。
	if clip_name == "AI-listen":
		_align_to_breath_idle(clip_name, sample, scale_factor)
	position.y += _youyou_stage_drop()


func _youyou_stage_drop() -> float:
	return STAGE_DROP_Y - YOUYOU_UI_LIFT_Y


func _align_keep_squat_to_standup(clip_name: String, sample: Texture2D) -> void:
	var base_scale := float(VIEWPORT_SIZE.y) * CHARACTER_HEIGHT_RATIO / REF_CANVAS_H
	var layout := _keep_squat_layout(clip_name, sample)
	var body_h := float(layout.get("body_h", 0.0))
	var placed := base_scale
	if body_h > 8.0:
		placed = base_scale * YOUYOU_STANDUP_BODY_H / body_h
	scale = Vector2(placed, placed)
	## 先写入 offset，后面脚点按「position + (feet - center) * scale」才和画面一致。
	offset = layout.get("offset", Vector2.ZERO)
	var feet := Vector2(
		float(layout.get("crop_x", 0)) + float(layout.get("feet_x", 0)),
		float(layout.get("crop_y", 0)) + float(layout.get("feet_y", 0))
	)
	var full_center := Vector2(
		float(layout.get("full_w", 1920)) * 0.5,
		float(layout.get("full_h", 1080)) * 0.5
	)
	## 与 standup 锁定摆位同一套：先不算 UI 上移，外层再统一加 stage drop。
	var standup_feet_screen := (
		Vector2(VIEWPORT_SIZE) * 0.5
		+ (YOUYOU_STANDUP_FEET - Vector2(960, 540)) * base_scale
	)
	position = standup_feet_screen - (feet - full_center) * placed


func _keep_squat_layout(clip_name: String, sample: Texture2D) -> Dictionary:
	var layout := frame_layout(clip_name, 0)
	if not layout.is_empty() and float(layout.get("body_h", 0.0)) > 8.0:
		return layout
	var canvas := NewMotionActionFs.load_canvas(clip_name)
	var full_w := float(canvas.get("full_w", 1920))
	var full_h := float(canvas.get("full_h", 1080))
	var crop_x := float(canvas.get("crop_x", 0))
	var crop_y := float(canvas.get("crop_y", 0))
	var crop_w := float(canvas.get("crop_w", 0))
	var crop_h := float(canvas.get("crop_h", 0))
	if sample != null:
		crop_w = float(sample.get_width())
		crop_h = float(sample.get_height())
	var body_w := YOUYOU_STANDUP_BODY_H
	var body_h := YOUYOU_STANDUP_BODY_H
	var feet_x := crop_w * 0.5
	var feet_y := crop_h - 1.0
	var measured := _measure_texture(sample)
	if not measured.is_empty():
		body_w = float(measured.get("w", body_w))
		body_h = float(measured.get("h", body_h))
		feet_x = float(measured.get("feet_x", feet_x))
		feet_y = float(measured.get("feet_y", feet_y))
	var offset := Vector2(crop_x, crop_y) + Vector2(crop_w, crop_h) * 0.5 - Vector2(full_w, full_h) * 0.5
	return {
		"offset": offset,
		"full_w": full_w,
		"full_h": full_h,
		"crop_x": crop_x,
		"crop_y": crop_y,
		"crop_w": crop_w,
		"crop_h": crop_h,
		"feet_x": feet_x,
		"feet_y": feet_y,
		"body_w": body_w,
		"body_h": body_h,
	}


func _snap_keep_squat_feet_to_standup() -> void:
	if String(animation) != "youyou_Basecontrol_keepSquat":
		return
	var base_scale := float(VIEWPORT_SIZE.y) * CHARACTER_HEIGHT_RATIO / REF_CANVAS_H
	var target := (
		Vector2(VIEWPORT_SIZE) * 0.5
		+ (YOUYOU_STANDUP_FEET - Vector2(960, 540)) * base_scale
		+ Vector2(0.0, _youyou_stage_drop())
	)
	var layout := _keep_squat_layout(String(animation), current_frame_texture())
	var feet := Vector2(
		float(layout.get("crop_x", 0)) + float(layout.get("feet_x", 0)),
		float(layout.get("crop_y", 0)) + float(layout.get("feet_y", 0))
	)
	var full_center := Vector2(
		float(layout.get("full_w", 1920)) * 0.5,
		float(layout.get("full_h", 1080)) * 0.5
	)
	var now := position + (feet - full_center) * scale.x
	var delta := target - now
	if delta.length_squared() < 0.25:
		return
	position += delta


func _align_to_breath_idle(clip_name: String, sample: Texture2D, scale_factor: float) -> void:
	var breath_scale := float(VIEWPORT_SIZE.y) * CHARACTER_HEIGHT_RATIO / YOUYOU_BREATH_CANVAS.y
	if breath_scale <= 0.0:
		breath_scale = scale_factor
	scale = Vector2(breath_scale, breath_scale)
	var layout := frame_layout(clip_name, 0)
	if layout.is_empty():
		var canvas := _full_canvas(clip_name, sample)
		layout = {
			"crop_x": 0,
			"crop_y": 0,
			"feet_x": canvas.x * 0.5,
			"feet_y": canvas.y - 1.0,
			"full_w": canvas.x,
			"full_h": canvas.y,
		}
	var feet := Vector2(
		float(layout.get("crop_x", 0)) + float(layout.get("feet_x", 0)),
		float(layout.get("crop_y", 0)) + float(layout.get("feet_y", 0))
	)
	var full_center := Vector2(
		float(layout.get("full_w", YOUYOU_BREATH_CANVAS.x)) * 0.5,
		float(layout.get("full_h", YOUYOU_BREATH_CANVAS.y)) * 0.5
	)
	var breath_feet_screen := (
		Vector2(VIEWPORT_SIZE) * 0.5
		+ (YOUYOU_BREATH_FEET - YOUYOU_BREATH_CANVAS * 0.5) * breath_scale
	)
	## 与呼吸待机同一套：position 居中 + AnimatedSprite offset 承画布裁切；这里只把脚挪到呼吸待机落点。
	position = breath_feet_screen - (feet - full_center) * breath_scale


func _youyou_body_match(clip_name: String, sample: Texture2D) -> Dictionary:
	if clip_name == "" or clip_name in YOUYOU_LOCKED_PLACEMENT:
		return {}
	var body := _metrics_for(clip_name, sample)
	if body.is_empty() or not bool(body.get("standing", false)):
		return {}
	var tex_h := float(body.get("tex_h", 1.0))
	var body_h := float(body.get("h", 0.0))
	if tex_h <= 1.0 or body_h / tex_h >= 0.92:
		return {}
	return body


func _metrics_for(clip_name: String, fallback: Texture2D) -> Dictionary:
	if clip_name != "" and _body_cache.has(clip_name):
		return _body_cache[clip_name]
	var metrics := _metrics_from_frames(clip_name)
	if metrics.is_empty():
		metrics = _measure_texture(fallback)
		if clip_name != "" and _is_resident(clip_name):
			if metrics.is_empty() or not bool(metrics.get("standing", false)):
				var count := _frame_count(clip_name)
				if count > 2:
					var mid := _frame_texture(clip_name, int(count / 2))
					var mid_metrics := _measure_texture(mid)
					if not mid_metrics.is_empty():
						metrics = mid_metrics
	if clip_name != "":
		_body_cache[clip_name] = metrics
	return metrics


func _metrics_from_frames(clip_name: String) -> Dictionary:
	if clip_name == "" or not _frame_meta.has(clip_name):
		return {}
	var metas: Array = _frame_meta[clip_name]
	if metas.is_empty() or typeof(metas[0]) != TYPE_DICTIONARY:
		return {}
	var pick: Dictionary = metas[0]
	if not bool(pick.get("standing", false)) and metas.size() > 2:
		var mid: Variant = metas[int(metas.size() / 2)]
		if typeof(mid) == TYPE_DICTIONARY and bool((mid as Dictionary).get("standing", false)):
			pick = mid
	var full_h := int(pick.get("full_h", 0))
	if full_h <= 0:
		return {}
	return {
		"w": int(pick.get("body_w", 0)),
		"h": int(pick.get("body_h", 0)),
		"feet_x": int(pick.get("crop_x", 0)) + int(pick.get("feet_x", 0)),
		"feet_y": int(pick.get("crop_y", 0)) + int(pick.get("feet_y", 0)),
		"tex_w": int(pick.get("full_w", 0)),
		"tex_h": full_h,
		"standing": bool(pick.get("standing", false)),
	}


func _measure_texture(tex: Texture2D) -> Dictionary:
	if tex == null:
		return {}
	var image := tex.get_image()
	if image == null or image.is_empty():
		return {}
	var width := image.get_width()
	var height := image.get_height()
	var small := image
	var sample_w := 96
	if width > sample_w:
		small = image.duplicate()
		var sample_h := maxi(1, int(round(float(height) * float(sample_w) / float(width))))
		small.resize(sample_w, sample_h, Image.INTERPOLATE_NEAREST)
	var scale_x := float(width) / float(small.get_width())
	var scale_y := float(height) / float(small.get_height())
	var min_x := width
	var max_x := -1
	var min_y := height
	var max_y := -1
	for y in range(small.get_height()):
		for x in range(small.get_width()):
			if small.get_pixel(x, y).a <= 0.06:
				continue
			var px := int(float(x) * scale_x)
			var py := int(float(y) * scale_y)
			min_x = mini(min_x, px)
			max_x = maxi(max_x, px)
			min_y = mini(min_y, py)
			max_y = maxi(max_y, py)
	if max_x < 0:
		return {}
	var body_w := max_x - min_x
	var body_h := max_y - min_y
	return {
		"w": body_w,
		"h": body_h,
		"feet_x": int((min_x + max_x) / 2),
		"feet_y": max_y,
		"tex_w": width,
		"tex_h": height,
		"standing": body_h > int(float(body_w) * 1.15) and body_h > int(float(height) * 0.55),
	}


func _load_color_profile() -> void:
	_color_gains.clear()
	_color_profile_loaded = true
	if not FileAccess.file_exists(COLOR_PROFILE_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(COLOR_PROFILE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var clips: Variant = (parsed as Dictionary).get("clips", {})
	if typeof(clips) != TYPE_DICTIONARY:
		return
	for action_name in (clips as Dictionary).keys():
		var entry: Variant = (clips as Dictionary)[action_name]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var gain: Variant = (entry as Dictionary).get("rgb_gain", [])
		if typeof(gain) != TYPE_ARRAY or (gain as Array).size() < 3:
			continue
		_color_gains[String(action_name)] = Color(
			float((gain as Array)[0]),
			float((gain as Array)[1]),
			float((gain as Array)[2]),
			1.0
		)


func _apply_color_match(action_name: String) -> void:
	if not auto_color_match:
		self_modulate = Color.WHITE
		return
	if not _color_profile_loaded:
		_load_color_profile()
	if _color_gains.has(action_name):
		self_modulate = _color_gains[action_name] as Color
	else:
		self_modulate = Color.WHITE


func _load_voice_map() -> void:
	_voice_entries.clear()
	if not FileAccess.file_exists(VOICE_MAP_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(VOICE_MAP_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var entries: Variant = (parsed as Dictionary).get("entries", {})
	if entries is Dictionary:
		_voice_entries = (entries as Dictionary).duplicate(true)


func _ensure_voice_player() -> void:
	if _voice_player != null:
		return
	_voice_player = get_node_or_null("MappedVoice") as AudioStreamPlayer
	if _voice_player == null:
		_voice_player = AudioStreamPlayer.new()
		_voice_player.name = "MappedVoice"
		add_child(_voice_player)
	_voice_player.volume_db = ClawSceneAudio.VOICE_VOLUME_DB


func _voice_entry_for(action_name: String) -> Dictionary:
	if action_name == "" or not _voice_entries.has(action_name):
		return {}
	var raw: Variant = _voice_entries[action_name]
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	return raw as Dictionary


func _apply_mapped_voice(action_name: String) -> void:
	var entry := _voice_entry_for(action_name)
	speed_scale = maxf(float(entry.get("action_speed", 1.0)), 0.05)
	_stop_voice()
	if not auto_play_voice:
		return
	var cues: Variant = entry.get("audio_cues", [])
	if cues is Array and not (cues as Array).is_empty():
		_arm_voice_cues(cues as Array, float(entry.get("audio_speed", 1.0)))
		return
	var audio_path := str(entry.get("audio_path", ""))
	if audio_path == "":
		return
	YouyouVoiceSubtitleCatalog.notify_audio(self, audio_path)
	_ensure_voice_player()
	var stream := _load_audio_stream(audio_path)
	if stream == null:
		push_warning("配音加载失败: %s → %s" % [action_name, audio_path])
		return
	_voice_player.stream = stream
	_voice_player.pitch_scale = maxf(float(entry.get("audio_speed", 1.0)), 0.05)
	var delay := maxf(float(entry.get("audio_start_offset", 0.0)), 0.0)
	if delay <= 0.0:
		_voice_player.play()
		return
	_voice_delay_left = delay
	_waiting_voice = true
	set_process(true)


func _arm_voice_cues(cues: Array, default_pitch: float) -> void:
	_voice_cue_queue.clear()
	var pitch := maxf(default_pitch, 0.05)
	for item in cues:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var d := item as Dictionary
		var path := str(d.get("audio", ""))
		if path == "":
			continue
		var stream := _load_audio_stream(path)
		if stream == null:
			push_warning("配音加载失败: %s" % path)
			continue
		YouyouVoiceSubtitleCatalog.notify_audio(self, path)
		var start_at := maxf(float(d.get("start_at", 0.0)), 0.0)
		var cue_pitch := maxf(float(d.get("audio_speed", pitch)), 0.05)
		if start_at <= 0.0:
			_play_cue_now(stream, cue_pitch)
		else:
			_voice_cue_queue.append({"left": start_at, "stream": stream, "pitch": cue_pitch})
	if not _voice_cue_queue.is_empty():
		set_process(true)


func _tick_voice_cues(delta: float) -> void:
	if _voice_cue_queue.is_empty():
		return
	var kept: Array = []
	for item in _voice_cue_queue:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var d := item as Dictionary
		var left := float(d.get("left", 0.0)) - delta
		if left <= 0.0:
			_play_cue_now(d.get("stream") as AudioStream, float(d.get("pitch", 1.0)))
		else:
			d["left"] = left
			kept.append(d)
	_voice_cue_queue = kept


func _play_cue_now(stream: AudioStream, pitch: float) -> void:
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.name = "MappedVoiceCue_%d" % _cue_players.size()
	player.volume_db = ClawSceneAudio.VOICE_VOLUME_DB
	add_child(player)
	player.stream = stream
	player.pitch_scale = maxf(pitch, 0.05)
	player.finished.connect(func() -> void:
		if is_instance_valid(player):
			_cue_players.erase(player)
			player.queue_free()
	, CONNECT_ONE_SHOT)
	_cue_players.append(player)
	player.play()


func _load_audio_stream(audio_path: String) -> AudioStream:
	if audio_path == "":
		return null
	var stream := ResourceLoader.load(audio_path, "AudioStream") as AudioStream
	if stream != null:
		return stream
	var bytes := FileAccess.get_file_as_bytes(audio_path)
	if bytes.is_empty():
		bytes = FileAccess.get_file_as_bytes(ProjectSettings.globalize_path(audio_path))
	if bytes.is_empty():
		return null
	if audio_path.get_extension().to_lower() != "mp3":
		return null
	var mp3 := AudioStreamMP3.new()
	mp3.data = bytes
	return mp3


func _stop_voice() -> void:
	_waiting_voice = false
	_voice_delay_left = -1.0
	_voice_cue_queue.clear()
	for player in _cue_players:
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	_cue_players.clear()
	if _voice_player != null and _voice_player.playing:
		_voice_player.stop()
	if _voice_player != null:
		_voice_player.stream = null
