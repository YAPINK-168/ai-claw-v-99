extends Node
## 控制板对接（现有串口指令）· 串口4（COM4 / /dev/ttyS4）
## 抓中/失败判定（与 IO 板一致，安卓不读传感器本身）：
##   · 成功：出礼口 OUTSENTOR → 板子 WINFLAG → 串口 cmd0x01 的 normal_out>0
##   · 失败：心跳/状态 抓取中(0x02)→空闲(0x01) 后，宽限期内没有 normal_out
## 编辑器模拟（勿用 F5–F8）：F7 投币 · 1 失败 · 2 成功 · F9 抓取键 · 方向键=摇杆

signal claw_failed
signal claw_won
signal board_key(key_bits: int)
signal link_status(connected: bool, detail: String)
signal free_num_ack(total: int)
signal debug_info(text: String)
## 机台余币变化（心跳/状态/投币帧里的 balance）
signal credits_changed(credits: int)
## 识别到投币：amount=本次枚数，credits=投完后余币
signal coin_inserted(amount: int, credits: int)
## 机台状态变化：空闲 / 抓取中 等
signal machine_status_changed(status: int)
## 安卓接管娃娃机（cmd 0x06）：true=板子已确认接管，爪子停；false=已释放
signal control_changed(active: bool)
## IO 板 cmd 0x09 机械事件（1 字节 event_id）
signal mech_event(event_id: int)

const HDR_ANDROID := 0x0A
const HDR_IO := 0xFA
const CMD_HEARTBEAT := 0x00
const CMD_COIN := 0x01
const CMD_KEY := 0x02
const CMD_STATUS := 0x03
const CMD_CONTROL := 0x06 ## 安卓接管 / 释放
const CMD_FREE_NUM := 0x07
const CMD_MECH_EVENT := 0x09
const ST_IDLE := 0x01
const ST_PLAYING := 0x02
const ST_CONTROL := 0x03 ## 已被安卓接管（心跳/状态）
const CONTROL_KEEPALIVE_SEC := 25.0 ## 板子约 90s 无控制指令会自动释放
const CONTROL_RETRY_SEC := 0.8
# 实机摇杆上下与控制板 bit0/bit1 相反，此处按手感对调
const KEY_UP := 0x0002
const KEY_DOWN := 0x0001
const KEY_LEFT := 0x0004
const KEY_RIGHT := 0x0008
const KEY_ENTER := 0x0010

const SETTINGS_PORT := "board/serial_port"
const SETTINGS_MOCK := "board/serial_mock"

var _crc_table: Array = []
var _sn: int = 1
var _port_path: String = ""
var _file: FileAccess = null
var _rx := PackedByteArray()
var _connected: bool = false
var _mock: bool = false
var _rx_thread: Thread = null
var _rx_mutex := Mutex.new()
var _file_mutex := Mutex.new()
var _tx_mutex := Mutex.new()
var _tx_queue: Array = [] ## PackedByteArray
var _rx_queue: PackedByteArray = PackedByteArray()
var _rx_running: bool = false
var _boot_open_delay: float = 0.0
var _boot_open_done: bool = false
var _round_active: bool = false
var _round_won: bool = false
var _board_free_num: int = 0
var _rx_bytes: int = 0
var _rx_frames: int = 0
var _last_key: int = 0
var _last_key_bits: int = 0 ## 用于上升沿
var _reconnect_timer: float = 0.0
var _status_query_timer: float = 0.0
var _debug_line: String = ""
## 投币 / 余币（对应控制板 coinin）
var machine_credits: int = 0
var coins_inserted_total: int = 0 ## 本进程累计识别到的投币枚数
var _machine_status: int = ST_IDLE
var _last_coin_sn: int = -1
var _last_gift_sn: int = -1 ## 出礼帧去重
## 安卓要接管娃娃机（贪吃蛇期间）；板子 ACK 后 _control_acked=true
var _want_control: bool = false
var _control_acked: bool = false
var _control_keepalive_timer: float = 0.0
var _control_retry_timer: float = 0.0
## 一局结束后等出礼口传感器上报（OUTSENTOR→normal_out）；礼品下落可能慢于空闲心跳
var _pending_round_end: bool = false
var _round_end_timer: float = 0.0
const ROUND_END_GRACE_SEC := 3.0
const ANDROID_BOOT_OPEN_SEC := 0.8
var _debug_refresh_cooldown: float = 0.0
## mock 模式下是否启用 1/2/F7/F9 等旧键盘模拟（与 youyou_preview CLAW_JOYSTICK_X_INPUT 配合）
var legacy_keyboard_mock := true


func _ready() -> void:
	_init_crc_table()
	_mock = _resolve_mock()
	_port_path = str(ProjectSettings.get_setting(SETTINGS_PORT, _default_port()))
	_boot_open_done = _mock
	set_process(true)
	if _mock:
		_connected = true
		_set_status(true, "模拟: F7投币 1失败 2成功 F9抓取键")
		print("[BoardLink] mock mode")
	else:
		_set_status(false, "启动中…")
		print("[BoardLink] will open serial after UI ready: ", _port_path)


func _resolve_mock() -> bool:
	# 排障包：导出时带 custom feature force_mock_serial = 不开真串口
	if OS.has_feature("force_mock_serial"):
		return true
	# 导出包强制真串口；仅编辑器默认模拟
	if OS.has_feature("android") or OS.has_feature("mobile"):
		return bool(ProjectSettings.get_setting(SETTINGS_MOCK, false))
	if ProjectSettings.has_setting(SETTINGS_MOCK):
		return bool(ProjectSettings.get_setting(SETTINGS_MOCK))
	return OS.has_feature("editor")


func _init_crc_table() -> void:
	_crc_table = [
		0x0000, 0xC0C1, 0xC181, 0x0140, 0xC301, 0x03C0, 0x0280, 0xC241, 0xC601, 0x06C0, 0x0780, 0xC741, 0x0500, 0xC5C1, 0xC481, 0x0440,
		0xCC01, 0x0CC0, 0x0D80, 0xCD41, 0x0F00, 0xCFC1, 0xCE81, 0x0E40, 0x0A00, 0xCAC1, 0xCB81, 0x0B40, 0xC901, 0x09C0, 0x0880, 0xC841,
		0xD801, 0x18C0, 0x1980, 0xD941, 0x1B00, 0xDBC1, 0xDA81, 0x1A40, 0x1E00, 0xDEC1, 0xDF81, 0x1F40, 0xDD01, 0x1DC0, 0x1C80, 0xDC41,
		0x1400, 0xD4C1, 0xD581, 0x1540, 0xD701, 0x17C0, 0x1680, 0xD641, 0xD201, 0x12C0, 0x1380, 0xD341, 0x1100, 0xD1C1, 0xD081, 0x1040,
		0xF001, 0x30C0, 0x3180, 0xF141, 0x3300, 0xF3C1, 0xF281, 0x3240, 0x3600, 0xF6C1, 0xF781, 0x3740, 0xF501, 0x35C0, 0x3480, 0xF441,
		0x3C00, 0xFCC1, 0xFD81, 0x3D40, 0xFF01, 0x3FC0, 0x3E80, 0xFE41, 0xFA01, 0x3AC0, 0x3B80, 0xFB41, 0x3900, 0xF9C1, 0xF881, 0x3840,
		0x2800, 0xE8C1, 0xE981, 0x2940, 0xEB01, 0x2BC0, 0x2A80, 0xEA41, 0xEE01, 0x2EC0, 0x2F80, 0xEF41, 0x2D00, 0xEDC1, 0xEC81, 0x2C40,
		0xE401, 0x24C0, 0x2580, 0xE541, 0x2700, 0xE7C1, 0xE681, 0x2640, 0x2200, 0xE2C1, 0xE381, 0x2340, 0xE101, 0x21C0, 0x2080, 0xE041,
		0xA001, 0x60C0, 0x6180, 0xA141, 0x6300, 0xA3C1, 0xA281, 0x6240, 0x6600, 0xA6C1, 0xA781, 0x6740, 0xA501, 0x65C0, 0x6480, 0xA441,
		0x6C00, 0xACC1, 0xAD81, 0x6D40, 0xAF01, 0x6FC0, 0x6E80, 0xAE41, 0xAA01, 0x6AC0, 0x6B80, 0xAB41, 0x6900, 0xA9C1, 0xA881, 0x6840,
		0x7800, 0xB8C1, 0xB981, 0x7940, 0xBB01, 0x7BC0, 0x7A80, 0xBA41, 0xBE01, 0x7EC0, 0x7F80, 0xBF41, 0x7D00, 0xBDC1, 0xBC81, 0x7C40,
		0xB401, 0x74C0, 0x7580, 0xB541, 0x7700, 0xB7C1, 0xB681, 0x7640, 0x7200, 0xB2C1, 0xB381, 0x7340, 0xB101, 0x71C0, 0x7080, 0xB041,
		0x5000, 0x90C1, 0x9181, 0x5140, 0x9301, 0x53C0, 0x5280, 0x9241, 0x9601, 0x56C0, 0x5780, 0x9741, 0x5500, 0x95C1, 0x9481, 0x5440,
		0x9C01, 0x5CC0, 0x5D80, 0x9D41, 0x5F00, 0x9FC1, 0x9E81, 0x5E40, 0x5A00, 0x9AC1, 0x9B81, 0x5B40, 0x9901, 0x59C0, 0x5880, 0x9841,
		0x8801, 0x48C0, 0x4980, 0x8941, 0x4B00, 0x8BC1, 0x8A81, 0x4A40, 0x4E00, 0x8EC1, 0x8F81, 0x4F40, 0x8D01, 0x4DC0, 0x4C80, 0x8C41,
		0x4400, 0x84C1, 0x8581, 0x4540, 0x8701, 0x47C0, 0x4680, 0x8641, 0x8201, 0x42C0, 0x4380, 0x8341, 0x4100, 0x81C1, 0x8081, 0x4040,
	]


func _crc16(data: PackedByteArray) -> int:
	var crc := 0
	for b in data:
		crc = ((crc >> 8) ^ int(_crc_table[(crc ^ int(b)) & 0xFF])) & 0xFFFF
	return crc


func _build_frame(header: int, cmd: int, payload: PackedByteArray = PackedByteArray()) -> PackedByteArray:
	var body := PackedByteArray()
	body.append(header)
	body.append(0)
	body.append(_sn & 0xFF)
	_sn = (_sn + 1) & 0xFF
	if _sn == 0:
		_sn = 1
	body.append(Time.get_ticks_msec() & 0xFF)
	body.append(cmd)
	body.append_array(payload)
	body[1] = body.size()
	var c := _crc16(body)
	body.append(c & 0xFF)
	body.append((c >> 8) & 0xFF)
	return body


func _default_port() -> String:
	if OS.get_name() == "Windows":
		return "COM4"
	return "/dev/ttyS4"


func _candidate_ports() -> Array[String]:
	var out: Array[String] = []
	var primary := _port_path.strip_edges()
	if primary != "":
		out.append(primary)
	# 安卓：优先配置口，再试常见串口4映射（每个都会先 chmod）
	if OS.has_feature("android") or OS.has_feature("mobile"):
		for p in ["/dev/ttyS4", "/dev/ttyAS4", "/dev/ttysWK3", "/dev/ttyS3", "/dev/ttyS1"]:
			if p not in out:
				out.append(p)
		return out
	if OS.get_name() == "Windows":
		for p in ["COM4", "COM3", "COM5", "COM6"]:
			if p not in out:
				out.append(p)
	else:
		for p in ["/dev/ttyS4", "/dev/ttyS3", "/dev/ttyS1", "/dev/ttyS2", "/dev/ttyUSB0", "/dev/ttyAS4", "/dev/ttysWK3"]:
			if p not in out:
				out.append(p)
	return out


func _prepare_linux_port(path: String) -> void:
	if not path.begins_with("/dev/"):
		return
	# 机台串口默认 root 权限；不做 chmod 时 FileAccess 打不开 → 游戏余币永远 0
	# 在 UI 起来之后再执行，失败忽略
	# 机台串口常常只有 root 能开。chmod 失败时余币会一直停在 0。
	OS.execute("sh", PackedStringArray(["-c", "chmod 666 '%s' 2>/dev/null || su -c 'chmod 666 %s' 2>/dev/null || su 0 chmod 666 '%s' 2>/dev/null || true" % [path, path, path]]), [], false)
	OS.execute("sh", PackedStringArray([
		"-c",
		"stty -F '%s' 115200 cs8 -cstopb -parenb raw -echo clocal cread 2>/dev/null || busybox stty -F '%s' 115200 raw -echo 2>/dev/null || true" % [path, path]
	]), [], false)


func _open_path(path: String) -> FileAccess:
	var open_path := path
	if OS.get_name() == "Windows" and path.to_upper().begins_with("COM"):
		open_path = "\\\\.\\" + path.to_upper()
	elif path.begins_with("/dev/"):
		_prepare_linux_port(path)
	var err_rw := OK
	var f := FileAccess.open(open_path, FileAccess.READ_WRITE)
	if f == null:
		err_rw = FileAccess.get_open_error()
		f = FileAccess.open(open_path, FileAccess.READ)
	if f == null:
		print("[BoardLink] open fail ", open_path, " rw_err=", err_rw, " r_err=", FileAccess.get_open_error())
	else:
		print("[BoardLink] open ok ", open_path)
	return f


func _open_port() -> void:
	_close_port()
	var tried: PackedStringArray = PackedStringArray()
	var f: FileAccess = null
	var used := ""
	for path in _candidate_ports():
		tried.append(path)
		f = _open_path(path)
		if f != null:
			used = path
			break
	if f == null:
		_connected = false
		_set_status(false, "串口失败 试过:%s" % ", ".join(tried))
		print("[BoardLink] open failed: ", tried)
		return
	_port_path = used
	_file_mutex.lock()
	_file = f
	_file_mutex.unlock()
	_tx_mutex.lock()
	_tx_queue.clear()
	_tx_mutex.unlock()
	_connected = true
	_rx_running = true
	_rx_thread = Thread.new()
	_rx_thread.start(_rx_worker)
	_set_status(true, "已连接 %s · RX0" % _port_path)
	print("[BoardLink] opened ", _port_path)
	call_deferred("query_status")


func _rx_worker() -> void:
	while _rx_running:
		var to_send: Array = []
		_tx_mutex.lock()
		if not _tx_queue.is_empty():
			to_send = _tx_queue.duplicate()
			_tx_queue.clear()
		_tx_mutex.unlock()

		_file_mutex.lock()
		var f := _file
		if f == null:
			_file_mutex.unlock()
			OS.delay_msec(20)
			continue
		for packet in to_send:
			f.store_buffer(packet)
			f.flush()
		# 读可能阻塞；关端口时先 close 文件可唤醒
		var b := f.get_8()
		var err := f.get_error()
		_file_mutex.unlock()
		if not _rx_running:
			break
		if err != OK:
			OS.delay_msec(2)
			continue
		_rx_mutex.lock()
		_rx_queue.append(b)
		_rx_mutex.unlock()


func _close_port() -> void:
	# 先关文件再等线程，避免 get_8 阻塞导致死锁
	_rx_running = false
	_file_mutex.lock()
	if _file:
		_file.close()
		_file = null
	_file_mutex.unlock()
	if _rx_thread:
		_rx_thread.wait_to_finish()
		_rx_thread = null
	_tx_mutex.lock()
	_tx_queue.clear()
	_tx_mutex.unlock()
	_connected = false


func _exit_tree() -> void:
	if _want_control:
		_want_control = false
		_send_control_cmd(false)
	_close_port()


func _process(delta: float) -> void:
	if _debug_refresh_cooldown > 0.0:
		_debug_refresh_cooldown -= delta
	_tick_round_end(delta)

	if _mock:
		_tick_control(delta)
		return

	# 等界面起来后再开串口（安卓闪屏阶段开 tty 易崩）
	if not _boot_open_done:
		_boot_open_delay += delta
		var need_delay := OS.has_feature("android") or OS.has_feature("mobile")
		if need_delay and _boot_open_delay < ANDROID_BOOT_OPEN_SEC:
			return
		_boot_open_done = true
		_open_port()
		return

	if not _connected:
		_reconnect_timer += delta
		if _reconnect_timer >= 3.0:
			_reconnect_timer = 0.0
			_open_port()
		return

	_tick_control(delta)

	_status_query_timer += delta
	if _status_query_timer >= 1.5:
		_status_query_timer = 0.0
		query_status()

	_rx_mutex.lock()
	if not _rx_queue.is_empty():
		_rx_bytes += _rx_queue.size()
		_rx.append_array(_rx_queue)
		_rx_queue = PackedByteArray()
		_refresh_debug()
	_rx_mutex.unlock()
	if not _rx.is_empty():
		_parse_rx()


func _tick_round_end(delta: float) -> void:
	if not _pending_round_end:
		return
	_round_end_timer -= delta
	if _round_end_timer > 0.0:
		return
	_pending_round_end = false
	if _round_won:
		return
	# 贪吃蛇已接管时不再报本局失败
	if _want_control:
		return
	claw_failed.emit()
	print("[BoardLink] claw_failed (no OUTSENTOR/normal_out within grace)")


func _tick_control(delta: float) -> void:
	if not _want_control:
		return
	_control_keepalive_timer += delta
	if _control_keepalive_timer >= CONTROL_KEEPALIVE_SEC:
		_control_keepalive_timer = 0.0
		_send_control_cmd(true)
		return
	if not _control_acked:
		_control_retry_timer += delta
		if _control_retry_timer >= CONTROL_RETRY_SEC:
			_control_retry_timer = 0.0
			_send_control_cmd(true)


func _refresh_debug() -> void:
	var ctrl := ""
	if _want_control:
		ctrl = " · 接管OK" if _control_acked else " · 接管中…"
	_debug_line = "%s · 余币%d · 投%d · RX:%d帧%d%s" % [
		("OK " + _port_path) if _connected else "串口断",
		machine_credits,
		coins_inserted_total,
		_rx_bytes,
		_rx_frames,
		ctrl,
	]
	debug_info.emit(_debug_line)
	if _connected:
		link_status.emit(true, _debug_line)
	else:
		link_status.emit(false, _debug_line)


func _set_status(connected: bool, detail: String) -> void:
	_debug_line = detail
	link_status.emit(connected, detail)
	debug_info.emit(detail)


func _unhandled_input(event: InputEvent) -> void:
	if not legacy_keyboard_mock:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_1, KEY_KP_1:
			claw_failed.emit()
			get_viewport().set_input_as_handled()
		KEY_2, KEY_KP_2:
			_round_won = true
			claw_won.emit()
			get_viewport().set_input_as_handled()
		KEY_F9:
			_emit_key_edge(KEY_ENTER)
			get_viewport().set_input_as_handled()
		KEY_F7:
			simulate_coin_insert(1)
			get_viewport().set_input_as_handled()


func _emit_key_edge(bits: int) -> void:
	# 按下有效位；0 表示松开
	_last_key = bits
	board_key.emit(bits)
	_refresh_debug()


func _parse_rx() -> void:
	var i := 0
	while i < _rx.size():
		var hdr := int(_rx[i])
		if hdr != HDR_IO and hdr != HDR_ANDROID:
			i += 1
			continue
		if i + 2 > _rx.size():
			break
		var length := int(_rx[i + 1])
		var total := length + 2
		if length < 5 or total > 256:
			i += 1
			continue
		if i + total > _rx.size():
			break
		var body := _rx.slice(i, i + length)
		var crc_rx := int(_rx[i + length]) | (int(_rx[i + length + 1]) << 8)
		if crc_rx == _crc16(body):
			_rx_frames += 1
			var sn := int(body[2]) if body.size() > 2 else 0
			_handle_frame(int(body[4]), body.slice(5, length), sn)
			_refresh_debug()
			i += total
		else:
			i += 1
	_rx = _rx.slice(i)


func _handle_frame(cmd: int, data: PackedByteArray, sn: int = 0) -> void:
	match cmd:
		CMD_HEARTBEAT, CMD_STATUS:
			if data.is_empty():
				return
			_on_machine_status(int(data[0]))
			# 心跳/状态第 2 字节 = 机台余币 coinin
			if data.size() >= 2:
				_set_credits(int(data[1]), false)
		CMD_COIN:
			_on_coin_report(data, sn)
		CMD_KEY:
			if data.size() >= 2:
				var bits := int(data[0]) | (int(data[1]) << 8)
				_on_key_bits(bits)
		CMD_CONTROL:
			_on_control_ack(int(data[0]) if not data.is_empty() else -1)
		CMD_FREE_NUM:
			if not data.is_empty():
				_board_free_num = int(data[0])
				free_num_ack.emit(_board_free_num)
		CMD_MECH_EVENT:
			if not data.is_empty():
				mech_event.emit(int(data[0]))


## 控制板 SERIAL_SendCoin：coin / normal_out / balance
## normal_out>0 = 出礼口传感器 OUTSENTOR 触发（抓中礼品）
func _on_coin_report(data: PackedByteArray, sn: int) -> void:
	if data.is_empty():
		return
	var coin_delta := int(data[0])
	var normal_out := int(data[1]) if data.size() >= 2 else 0
	var balance := int(data[2]) if data.size() >= 3 else -1

	# 必须按相同 sn 回 ACK，否则板子会连发；ACK 走独立写口，不被读阻塞
	_ack_coin(sn, coin_delta, normal_out)

	if normal_out > 0 and sn != _last_gift_sn:
		_last_gift_sn = sn
		_round_won = true
		_pending_round_end = false
		claw_won.emit()
		print("[BoardLink] claw_won sensor gift normal_out=%d sn=%d" % [normal_out, sn])

	if coin_delta > 0 and sn != _last_coin_sn:
		_last_coin_sn = sn
		coins_inserted_total += coin_delta
		if balance >= 0:
			_set_credits(balance, false)
		else:
			_set_credits(machine_credits + coin_delta, false)
		coin_inserted.emit(coin_delta, machine_credits)
		print("[BoardLink] coin +%d credits=%d sn=%d" % [coin_delta, machine_credits, sn])
	elif balance >= 0:
		_set_credits(balance, false)


func _ack_coin(sn: int, coin: int, normal_out: int) -> void:
	var body := PackedByteArray()
	body.append(HDR_ANDROID)
	body.append(0)
	body.append(sn & 0xFF)
	body.append(Time.get_ticks_msec() & 0xFF)
	body.append(CMD_COIN)
	body.append(coin & 0xFF)
	body.append(normal_out & 0xFF)
	body[1] = body.size()
	var c := _crc16(body)
	body.append(c & 0xFF)
	body.append((c >> 8) & 0xFF)
	_send(body)


func _set_credits(value: int, emit_insert: bool) -> void:
	value = maxi(0, value)
	if value == machine_credits:
		return
	var prev := machine_credits
	machine_credits = value
	credits_changed.emit(machine_credits)
	if emit_insert and machine_credits > prev:
		var delta := machine_credits - prev
		coins_inserted_total += delta
		coin_inserted.emit(delta, machine_credits)
	_refresh_debug()


func _on_key_bits(bits: int) -> void:
	# 始终上报完整键位快照（含摇杆+抓取同时按住），避免玩法侧用 mask 覆盖时丢掉仍按住的键
	if bits == _last_key_bits:
		return
	_last_key_bits = bits
	_last_key = bits
	board_key.emit(bits)
	# 勿每帧刷 debug：会拖慢主线程
	if _debug_refresh_cooldown <= 0.0:
		_debug_refresh_cooldown = 0.25
		_refresh_debug()


func _on_machine_status(status: int) -> void:
	var prev := _machine_status
	_machine_status = status
	if status != prev:
		machine_status_changed.emit(status)

	# 接管态心跳 status=0x03：确认板子已停爪子
	if status == ST_CONTROL:
		_set_control_acked(true)
		return

	# 想要接管但板子又回到空闲（超时释放）→ 立刻重发接管
	if _want_control and status == ST_IDLE:
		_set_control_acked(false)

	if status == ST_PLAYING:
		_round_active = true
		_round_won = false
		_pending_round_end = false
	elif status == ST_IDLE and _round_active:
		# 局结束：先等出礼传感器上报，超时则失败
		_round_active = false
		if _round_won:
			return
		_pending_round_end = true
		_round_end_timer = ROUND_END_GRACE_SEC
		print("[BoardLink] round idle → wait gift sensor %.1fs" % ROUND_END_GRACE_SEC)


func _on_control_ack(status: int) -> void:
	# 0x01 接管成功；0x00 已释放；0x02 忙碌（爪子未回位）
	match status:
		0x01:
			_set_control_acked(true)
			print("[BoardLink] control TAKE ok")
		0x00:
			_set_control_acked(false)
			if not _want_control:
				control_changed.emit(false)
			print("[BoardLink] control RELEASE ack")
		0x02:
			_set_control_acked(false)
			print("[BoardLink] control TAKE busy (beginning!=0), retry")
		_:
			pass


func _set_control_acked(acked: bool) -> void:
	if acked == _control_acked:
		return
	_control_acked = acked
	if _want_control and acked:
		control_changed.emit(true)
	elif not acked and not _want_control:
		control_changed.emit(false)


func get_machine_status_text() -> String:
	match _machine_status:
		ST_PLAYING:
			return "抓取中"
		ST_IDLE:
			return "空闲"
		ST_CONTROL:
			return "安卓接管"
		_:
			return "其它"


func is_linked() -> bool:
	return _connected


func get_debug_line() -> String:
	return _debug_line


func get_credits() -> int:
	return machine_credits


## 真串口已连上时，界面余币以控制板 coinin 为准。
func uses_machine_credits() -> bool:
	return not _mock and _connected


func get_coins_inserted_total() -> int:
	return coins_inserted_total


## 编辑器/演示：模拟投币（走与真机相同信号）
func simulate_coin_insert(amount: int = 1) -> void:
	amount = maxi(1, amount)
	var sn := (_last_coin_sn + 1) if _last_coin_sn >= 0 else 1
	var balance := machine_credits + amount
	inject_rx_bytes(build_coin_frame(sn, amount, 0, balance))
	# 立即处理（不必等下一帧）
	_rx_mutex.lock()
	if not _rx_queue.is_empty():
		_rx.append_array(_rx_queue)
		_rx_queue = PackedByteArray()
	_rx_mutex.unlock()
	_parse_rx()


func query_status() -> void:
	_send(_build_frame(HDR_ANDROID, CMD_STATUS, PackedByteArray([0x00])))


## 进入贪吃蛇前调用：板子停爪子/TIM1，摇杆只给安卓
func get_current_key_bits() -> int:
	return _last_key_bits


func take_control() -> void:
	_want_control = true
	_control_keepalive_timer = 0.0
	_control_retry_timer = 0.0
	_send_control_cmd(true)
	if _mock:
		_set_control_acked(true)
		print("[BoardLink] mock take_control")
	else:
		print("[BoardLink] take_control sent")
		_refresh_debug()

## 返回娃娃机待机时调用：恢复板子控制爪子
func release_control() -> void:
	var was := _want_control or _control_acked
	_want_control = false
	_control_keepalive_timer = 0.0
	_control_retry_timer = 0.0
	_send_control_cmd(false)
	_set_control_acked(false)
	if was:
		control_changed.emit(false)
	if _mock:
		print("[BoardLink] mock release_control")


func is_controlling() -> bool:
	return _want_control and _control_acked


func _send_control_cmd(take: bool) -> void:
	_send(_build_frame(HDR_ANDROID, CMD_CONTROL, PackedByteArray([0x01 if take else 0x00])))


func reset_session_counters() -> void:
	pass


func report_free_play(count: int = 1) -> void:
	_board_free_num = mini(255, _board_free_num + count)
	_send(_build_frame(HDR_ANDROID, CMD_FREE_NUM, PackedByteArray([_board_free_num])))


func report_settle(_tokens: int, _free_add: int = -1) -> void:
	pass


func _send(bytes: PackedByteArray) -> void:
	if _mock:
		print("[BoardLink] TX ", bytes.hex_encode())
		return
	# 入队，由收线程写出；主线程不碰 FileAccess
	_tx_mutex.lock()
	_tx_queue.append(bytes)
	_tx_mutex.unlock()


## —— 测试用：构造控制板按键帧并注入 ——
func build_key_frame(key_bits: int) -> PackedByteArray:
	var body := PackedByteArray()
	body.append(HDR_IO)
	body.append(0x07)
	body.append(0x01)
	body.append(0x00)
	body.append(CMD_KEY)
	body.append(key_bits & 0xFF)
	body.append((key_bits >> 8) & 0xFF)
	var c := _crc16(body)
	body.append(c & 0xFF)
	body.append((c >> 8) & 0xFF)
	return body


## 控制板 SERIAL_SendCoin 同款帧：cmd=0x01, coin, normal_out, balance
func build_coin_frame(sn: int, coin: int, normal_out: int, balance: int) -> PackedByteArray:
	var body := PackedByteArray()
	body.append(HDR_IO)
	body.append(0x08)
	body.append(sn & 0xFF)
	body.append(0x00)
	body.append(CMD_COIN)
	body.append(coin & 0xFF)
	body.append(normal_out & 0xFF)
	body.append(balance & 0xFF)
	var c := _crc16(body)
	body.append(c & 0xFF)
	body.append((c >> 8) & 0xFF)
	return body


## 心跳/状态帧（含余币）
func build_status_frame(status: int, coin_num: int, cmd: int = CMD_STATUS) -> PackedByteArray:
	var body := PackedByteArray()
	body.append(HDR_IO)
	body.append(0x0B)
	body.append(0x01)
	body.append(0x00)
	body.append(cmd)
	body.append(status & 0xFF)
	body.append(coin_num & 0xFF)
	body.append(0x01)
	body.append(0x00)
	body.append(0xA1)
	body.append(0x00)
	var c := _crc16(body)
	body.append(c & 0xFF)
	body.append((c >> 8) & 0xFF)
	return body


func inject_rx_bytes(bytes: PackedByteArray) -> void:
	_rx_mutex.lock()
	_rx_queue.append_array(bytes)
	_rx_bytes += bytes.size()
	_rx_mutex.unlock()


func inject_key(key_bits: int) -> void:
	inject_rx_bytes(build_key_frame(key_bits))
