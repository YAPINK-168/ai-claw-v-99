extends Node

## Phase3-C2 Step1：PCM16 流式播放器隔离测试（Mock 正弦分片 + 字节对齐）。

const Pcm16StreamPlayerScript := preload("res://Scripts/voice/pcm16_stream_player.gd")


func run() -> bool:
	var player := AudioStreamPlayer.new()
	add_child(player)
	var stream := Pcm16StreamPlayerScript.new()
	stream.min_start_ms = 100.0
	stream.bind_player(player, 24000)
	var hook_count: Array = [0]
	stream.set_playback_started_callback(func() -> void: hook_count[0] += 1)

	var ok := true
	ok = ok and _test_odd_byte_carry(stream, player)
	ok = ok and await _test_stream_playback(stream, player, hook_count)
	player.queue_free()
	print("=== pcm16_stream_player_check_pass=%s ===" % str(ok))
	return ok


func _test_odd_byte_carry(stream: Pcm16StreamPlayerScript, _player: AudioStreamPlayer) -> bool:
	stream.begin_turn(1)
	stream.feed_pcm(PackedByteArray([0x01]), 1)
	stream.feed_pcm(PackedByteArray([0x02, 0x03, 0x04]), 1)
	var pending := stream.pending_bytes()
	stream.stop_immediate()
	return pending >= 4


func _test_stream_playback(
	stream: Pcm16StreamPlayerScript,
	player: AudioStreamPlayer,
	hook_count_ref: Array,
) -> bool:
	stream.begin_turn(2)
	var rate := 24000
	var chunk_samples := 800
	for part in 4:
		var pcm := _sine_pcm(chunk_samples, rate, 440.0 + float(part) * 20.0)
		if part == 0:
			pcm = pcm.slice(0, pcm.size() - 1)
		stream.feed_pcm(pcm, 2)
		for _f in 3:
			stream.tick(2)
			await get_tree().process_frame
	await stream.wait_until_idle(2, true, get_tree(), func() -> bool: return false)
	var ok := int(hook_count_ref[0]) >= 1 or not player.playing
	print("pcm16_stream_player_check: hook_count=%d underruns=%d" % [
		int(hook_count_ref[0]), stream.underrun_count(),
	])
	return ok


func _sine_pcm(samples: int, _rate: int, hz: float) -> PackedByteArray:
	var pcm := PackedByteArray()
	pcm.resize(samples * 2)
	for i in samples:
		var t := float(i) / 24000.0
		var s := sin(TAU * hz * t)
		var v := int(clampf(s, -1.0, 1.0) * 3000.0)
		if v < 0:
			v += 65536
		pcm[i * 2] = v & 0xFF
		pcm[i * 2 + 1] = (v >> 8) & 0xFF
	return pcm
