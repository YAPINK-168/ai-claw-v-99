extends Node
## 柚柚场景的背景曲和抓娃娃音效。
## 背景曲来源是 声音/抓娃娃机主题曲.m4a，播放同一首转出的 wav。
## 曲子一直循环。只有小游戏场景挂上之后才暂停，回到娃娃机再继续。
## 每个音效用自己的播放器，不占用柚柚配音。人声 > 背景曲 > 音效。
const VOICE_VOLUME_DB := 4.0
const BGM_VOLUME_DB := -6.0
const SFX_VOLUME_DB := -12.0
const BGM_PATH := "res://声音/抓娃娃机主题曲.wav"
## 摇杆音效最短间隔。四个方向共用这一段，连按不会叠成一团。
const MOVE_REPEAT_GAP_MS := 160
const MOVE_CUES: PackedStringArray = ["left", "right", "up", "down"]

const CUES := {
	"left": "res://声音/control_left.mp3",
	"right": "res://声音/control_right.mp3",
	"up": "res://声音/control_up.mp3",
	"down": "res://声音/control_down.mp3",
	"grab_down": "res://声音/grab_down.mp3",
	"grab_up": "res://声音/grab_up.mp3",
	"success": "res://声音/success.mp3",
	"fail": "res://声音/fail.mp3",
	"coin": "res://声音/coin.MP3",
}

var _sfx: Dictionary = {}
var _bgm: AudioStreamPlayer
var _move_lock_until_msec := 0


func _ready() -> void:
	_bgm = AudioStreamPlayer.new()
	_bgm.name = "Bgm"
	_bgm.volume_db = BGM_VOLUME_DB
	add_child(_bgm)
	var bgm_stream := _open_audio(BGM_PATH)
	if bgm_stream == null:
		push_error("背景曲加载失败：" + BGM_PATH)
	else:
		if bgm_stream is AudioStreamWAV:
			_loop_whole_wav(bgm_stream as AudioStreamWAV)
		_bgm.stream = bgm_stream
	for cue in CUES.keys():
		var player := AudioStreamPlayer.new()
		player.name = "Sfx_" + String(cue)
		player.volume_db = SFX_VOLUME_DB
		add_child(player)
		var stream := _open_audio(String(CUES[cue]))
		if stream == null:
			push_error("音效加载失败：" + String(CUES[cue]))
		else:
			player.stream = stream
		_sfx[String(cue)] = player
	start_bgm()


func start_bgm() -> void:
	if _bgm == null or _bgm.stream == null:
		push_error("背景曲没有加载：" + BGM_PATH)
		return
	_bgm.stream_paused = false
	if not _bgm.playing:
		_bgm.play()
		var loop_end := -1
		if _bgm.stream is AudioStreamWAV:
			loop_end = (_bgm.stream as AudioStreamWAV).loop_end
		print("[背景曲] 开始播放，长度 %.0f 秒，音量 %+.0f dB，循环终点 %d" % [_bgm.stream.get_length(), _bgm.volume_db, loop_end])


func pause_bgm() -> void:
	if _bgm == null or _bgm.stream == null:
		return
	if _bgm.playing and not _bgm.stream_paused:
		_bgm.stream_paused = true


func resume_bgm() -> void:
	if _bgm == null or _bgm.stream == null:
		return
	if _bgm.stream_paused:
		_bgm.stream_paused = false
		if not _bgm.playing:
			_bgm.play()
		return
	if not _bgm.playing:
		_bgm.play()


func play_move(direction: String) -> bool:
	if direction not in MOVE_CUES:
		return false
	var now := Time.get_ticks_msec()
	if now < _move_lock_until_msec:
		return false
	for cue in MOVE_CUES:
		if cue == direction:
			continue
		var other: AudioStreamPlayer = _sfx.get(cue) as AudioStreamPlayer
		if other != null and other.playing:
			other.stop()
	_move_lock_until_msec = now + MOVE_REPEAT_GAP_MS
	return _play(direction)


func play_grab_down() -> bool:
	return _play("grab_down")


func play_grab_up() -> bool:
	var down: AudioStreamPlayer = _sfx.get("grab_down") as AudioStreamPlayer
	if down != null and down.playing:
		down.stop()
	return _play("grab_up")


func play_outcome(success: bool) -> bool:
	return _play("success" if success else "fail")


func play_coin() -> bool:
	return _play("coin")


func _play(cue: String) -> bool:
	var player: AudioStreamPlayer = _sfx.get(cue) as AudioStreamPlayer
	if player == null or player.stream == null:
		return false
	player.stop()
	player.play()
	return true


func _loop_whole_wav(wav: AudioStreamWAV) -> void:
	# loop_end 默认是 0。只打开 LOOP_FORWARD 时，混音器会把循环区间当成空的，播放器显示在播，实际没有声音。
	# 安卓上导入后的 wav 常被压缩，用字节数算循环点会落在曲子中途，听起来就是放到一半又从头播。
	var by_time := maxi(1, int(round(wav.get_length() * float(wav.mix_rate))))
	var frames := by_time
	if wav.format != AudioStreamWAV.FORMAT_IMA_ADPCM and not wav.data.is_empty():
		var bytes_per_frame := 2
		if wav.format == AudioStreamWAV.FORMAT_8_BITS:
			bytes_per_frame = 1
		if wav.stereo:
			bytes_per_frame *= 2
		var by_bytes := int(wav.data.size() / bytes_per_frame)
		if by_bytes > 0 and abs(by_bytes - by_time) <= int(by_time / 5.0):
			frames = by_bytes
	wav.loop_begin = 0
	wav.loop_end = maxi(frames, 1)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD


func _open_audio(path: String) -> AudioStream:
	var bytes := FileAccess.get_file_as_bytes(path)
	if _is_wav(bytes):
		return AudioStreamWAV.load_from_buffer(bytes)
	if ResourceLoader.exists(path):
		var loaded: Variant = load(path)
		if loaded is AudioStream:
			var copy := (loaded as AudioStream).duplicate() as AudioStream
			if copy != null and copy.get_length() > 0.05:
				return copy
	if bytes.is_empty():
		return null
	return AudioStreamMP3.load_from_buffer(bytes)


func _is_wav(bytes: PackedByteArray) -> bool:
	if bytes.size() < 12:
		return false
	return (
		bytes[0] == 0x52
		and bytes[1] == 0x49
		and bytes[2] == 0x46
		and bytes[3] == 0x46
		and bytes[8] == 0x57
		and bytes[9] == 0x41
		and bytes[10] == 0x56
		and bytes[11] == 0x45
	)
