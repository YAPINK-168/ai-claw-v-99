class_name SpriteFramePacker
## 序列帧 PNG 解码/裁边（WorkerThreadPool 用静态方法，不绑 Sprite 节点，避免节点释放后卡死）。

static var _decoded: Dictionary = {}
static var _lock: Mutex = Mutex.new()


static func submit_decode(path: String, canvas: Dictionary = {}) -> void:
	WorkerThreadPool.add_task(_decode_worker.bind(path, canvas.duplicate(true)))


static func take_decode(path: String) -> Variant:
	_lock.lock()
	var payload: Variant = null
	if _decoded.has(path):
		payload = _decoded[path]
		_decoded.erase(path)
	_lock.unlock()
	return payload


static func forget_decode(path: String) -> void:
	_lock.lock()
	_decoded.erase(path)
	_lock.unlock()


static func _decode_worker(path: String, canvas: Dictionary) -> void:
	var image := Image.load_from_file(path)
	var payload := pack_frame(image, canvas)
	_lock.lock()
	_decoded[path] = payload
	_lock.unlock()


static func pack_frame(image: Image, canvas: Dictionary = {}) -> Dictionary:
	var empty := {
		"offset": Vector2.ZERO,
		"full_w": 1,
		"full_h": 1,
		"crop_x": 0,
		"crop_y": 0,
		"crop_w": 1,
		"crop_h": 1,
		"min_x": 0,
		"max_x": 0,
		"feet_x": 0,
		"feet_y": 0,
		"body_w": 0,
		"body_h": 0,
		"standing": false,
	}
	if image == null or image.is_empty():
		return empty
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	var origin_x := int(canvas.get("crop_x", 0))
	var origin_y := int(canvas.get("crop_y", 0))
	var canvas_w := int(canvas.get("full_w", 0))
	var canvas_h := int(canvas.get("full_h", 0))
	var canvas_crop_w := int(canvas.get("crop_w", 0))
	var canvas_crop_h := int(canvas.get("crop_h", 0))
	var img_w := image.get_width()
	var img_h := image.get_height()
	var full_w := canvas_w if canvas_w > 0 else img_w
	var full_h := canvas_h if canvas_h > 0 else img_h
	## 压缩工具已按统一 canvas 裁好时，禁止再按 used_rect 二次裁边，否则逐帧 offset 抖动（蹲着待机跳）。
	var pre_cropped := (
		canvas_crop_w > 0
		and canvas_crop_h > 0
		and img_w == canvas_crop_w
		and img_h == canvas_crop_h
	)
	var used := image.get_used_rect()
	var crop := image
	var local_x := 0
	var local_y := 0
	var used_area := used.size.x * used.size.y
	var img_area := img_w * img_h
	if (
		not pre_cropped
		and used.size.x >= 2
		and used.size.y >= 2
		and used_area > 0
		and used_area * 5 < img_area * 4
	):
		crop = image.get_region(used)
		local_x = used.position.x
		local_y = used.position.y
	var crop_x := origin_x + local_x
	var crop_y := origin_y + local_y
	var crop_w := crop.get_width()
	var crop_h := crop.get_height()
	var box_x := used.position.x - local_x
	var box_y := used.position.y - local_y
	var box_w := maxi(used.size.x, 1)
	var box_h := maxi(used.size.y, 1)
	var offset := Vector2(crop_x, crop_y) + Vector2(crop_w, crop_h) * 0.5 - Vector2(full_w, full_h) * 0.5
	return {
		"image": crop,
		"offset": offset,
		"full_w": full_w,
		"full_h": full_h,
		"crop_x": crop_x,
		"crop_y": crop_y,
		"crop_w": crop_w,
		"crop_h": crop_h,
		"min_x": box_x,
		"max_x": box_x + box_w - 1,
		"feet_x": box_x + int(box_w / 2),
		"feet_y": box_y + box_h - 1,
		"body_w": used.size.x,
		"body_h": used.size.y,
		"standing": used.size.y > int(float(used.size.x) * 1.15) and used.size.y > int(float(full_h) * 0.55),
	}
