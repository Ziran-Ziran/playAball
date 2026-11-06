extends SceneTree
## 只做尺寸采样与ICO封装；角色绘画来自内置生图，不在工具里重绘。
func _init() -> void:
	var source := Image.load_from_file("res://assets/ui/app_icon/playaball.png")
	if source == null or source.get_width() != source.get_height():
		push_error("游戏图标必须为正方形PNG")
		quit(1)
		return
	var sizes: Array[int] = [16, 24, 32, 48, 64, 128, 256]
	var payloads: Array[PackedByteArray] = []
	for size in sizes:
		var sample: Image = source.duplicate()
		sample.resize(size, size, Image.INTERPOLATE_LANCZOS)
		payloads.append(sample.save_png_to_buffer())
	var file := FileAccess.open("res://assets/ui/app_icon/playaball.ico", FileAccess.WRITE)
	if file == null:
		push_error("无法写入ICO")
		quit(1)
		return
	file.store_16(0)
	file.store_16(1)
	file.store_16(sizes.size())
	var offset: int = 6 + 16 * sizes.size()
	for index in sizes.size():
		file.store_8(sizes[index] % 256)
		file.store_8(sizes[index] % 256)
		file.store_8(0)
		file.store_8(0)
		file.store_16(1)
		file.store_16(32)
		file.store_32(payloads[index].size())
		file.store_32(offset)
		offset += payloads[index].size()
	for payload in payloads:
		file.store_buffer(payload)
	file.close()
	print("ICON BUILT: 7 PNG frames, 16..256px")
	quit()
