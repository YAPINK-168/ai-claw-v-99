extends Node

## C2.1 Step1：Mock 稳定供数 — 验证 underrun 计数不误报（播放前/结束后不计入）。

const Pcm16StreamPlayerScript := preload("res://Scripts/voice/pcm16_stream_player.gd")


func run() -> bool:
	var player := AudioStreamPlayer.new()
	add_child(player)
	var stream := Pcm16StreamPlayerScript.new()
	stream.min_start_ms = 100.0
	stream.bind_player(player, 24000)
	stream.begin_turn(1)

	stream.set_expecting_pcm(false)
	for _t in 30:
		stream.tick(1)
		await get_tree().process_frame
	var pre_skips := stream.underrun_count()

	stream.set_expecting_pcm(true)
	var pcm := _sine_pcm(24000 * 2)
	var offset := 0
	var step := 2400
	while offset < pcm.size():
		var slice := pcm.slice(offset, mini(offset + step, pcm.size()))
		stream.feed_pcm(slice, 1)
		for _k in 4:
			stream.tick(1)
		await get_tree().process_frame
		offset += step
	stream.set_expecting_pcm(false)
	for _d in 120:
		stream.tick(1)
		await get_tree().process_frame

	var ok := pre_skips == 0
	ok = ok and stream.underrun_count() < 50
	print(
		"pcm16_underrun_check: pre=%d during=%d raw_skips=%d pass=%s"
		% [pre_skips, stream.underrun_count(), stream.raw_skips_total(), str(ok)]
	)
	player.queue_free()
	print("=== pcm16_stream_player_underrun_check_pass=%s ===" % str(ok))
	return ok


func _sine_pcm(num_bytes: int) -> PackedByteArray:
	var samples := num_bytes / 2
	var pcm := PackedByteArray()
	pcm.resize(samples * 2)
	for i in samples:
		var s := sin(TAU * 440.0 * float(i) / 24000.0)
		var v := int(clampf(s, -1.0, 1.0) * 8000.0)
		if v < 0:
			v += 65536
		pcm[i * 2] = v & 0xFF
		pcm[i * 2 + 1] = (v >> 8) & 0xFF
	return pcm
