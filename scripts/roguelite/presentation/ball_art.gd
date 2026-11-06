class_name DemoBallArt
extends RefCounted
## 只保存表现素材；等级读取出生最大生命，受伤不改变敌人的身份。
const TEXTURES: Dictionary = {
	"hero": preload("res://assets/roguelite/ball_art_r4/hero.png"),
	"gpt": preload("res://assets/roguelite/ball_art_r4/gpt.png"),
	"claude": preload("res://assets/roguelite/ball_art_r4/claude.png"),
	"qwen": preload("res://assets/roguelite/ball_art_r4/qwen.png"),
	"virus_low": preload("res://assets/roguelite/ball_art_r4/virus_low.png"),
	"virus_mid": preload("res://assets/roguelite/ball_art_r4/virus_mid.png"),
	"virus_high": preload("res://assets/roguelite/ball_art_r4/virus_high.png")}
static var _regions: Dictionary = {}

static func texture_for(id: String) -> Texture2D:
	return TEXTURES.get(id) as Texture2D

static func companion_id(slot: int) -> String:
	return ["gpt", "claude", "qwen"][posmod(slot, 3)]

static func enemy_id(max_hp: int) -> String:
	return "virus_low" if max_hp <= 1 else ("virus_mid" if max_hp <= 3 else "virus_high")

static func region_for(texture: Texture2D) -> Rect2:
	var key: int = texture.get_instance_id()
	if not _regions.has(key):
		# 使用实际导入后的透明边界；size_limit或导出重导入不会沿用原PNG像素裁切。
		_regions[key] = Rect2(texture.get_image().get_used_rect())
	return _regions[key]

static func rect_for(texture: Texture2D, extent: float, center: Vector2 = Vector2.ZERO) -> Rect2:
	var size: Vector2 = region_for(texture).size
	var fitted: Vector2 = size * extent / maxf(1.0, maxf(size.x, size.y))
	return Rect2(center - fitted * 0.5, fitted)

# 每格独立透明边界，AtlasTexture引用原sheet，不另造位图。
static var _animation_frames: Dictionary = {}
static func animation_frame(id: String, frame: int) -> Texture2D:
	var key: String = id + str(frame)
	if _animation_frames.has(key): return _animation_frames[key]
	var path: String = "res://assets/roguelite/ball_animation_r5/" + id + "_sheet.png"
	if not ResourceLoader.exists(path): return texture_for(id)
	var sheet: Texture2D = load(path)
	var cell: Vector2i = Vector2i(sheet.get_size()) / 2
	var origin: Vector2i = Vector2i(frame % 2, frame / 2) * cell
	var used: Rect2i = sheet.get_image().get_region(Rect2i(origin, cell)).get_used_rect()
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(origin + used.position, used.size)
	atlas.filter_clip = true
	_animation_frames[key] = atlas
	return atlas
