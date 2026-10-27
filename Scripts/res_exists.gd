extends RefCounted
class_name ResExists

## 导出后，已导入的 mp3 / glb 不在原始路径上，FileAccess 会误判缺失。
## 原始 json、bin 仍以 FileAccess 为准。


static func path(resource_path: String) -> bool:
	if resource_path.is_empty():
		return false
	if FileAccess.file_exists(resource_path):
		return true
	return ResourceLoader.exists(resource_path)
