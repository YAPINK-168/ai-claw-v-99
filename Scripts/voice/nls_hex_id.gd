extends RefCounted
class_name NlsHexId

## 阿里云 NLS WebSocket：message_id / task_id 必须为 32 位小写十六进制（无连字符）。


static func new_id32() -> String:
	var b := PackedByteArray()
	b.resize(16)
	for i in 16:
		b[i] = randi() % 256
	var hex := ""
	for i in 16:
		hex += "%02x" % b[i]
	return hex


static func is_valid_id32(text: String) -> bool:
	if text.length() != 32:
		return false
	for i in text.length():
		var c := text[i]
		var ok := (c >= "0" and c <= "9") or (c >= "a" and c <= "f") or (c >= "A" and c <= "F")
		if not ok:
			return false
	return true
