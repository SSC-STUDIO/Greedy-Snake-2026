class_name SlashArc
extends Sprite2D
## 一次性挥砍弧光（纯表现层）。
## 用 AtlasTexture 从 3x3 雪碧图（每帧 64x47）切出 9 帧，播放约 0.12s 后自毁。
## 由 player.gd 轮询 melee.phase_name()=="active" 的上升沿后生成；
## 招架成功（GameEvents.parried）时把活跃弧光提亮为近白、放大并延长存活。
## headless 安全：素材缺失时立即退场，不影响任何逻辑判定。

const SHEET_PATH := "res://assets/kenney_clean/vfx/slash_spritesheet.png"
const FRAME_SIZE := Vector2i(64, 47)
const SHEET_COLS := 3
const SHEET_ROWS := 3
const PLAY_FRAMES := 4          # 播放前 4 帧
const PLAY_SECONDS := 0.12
const PARRY_MODULATE := Color(2.2, 2.2, 2.2)
const PARRY_SCALE := Vector2(1.4, 1.4)
const PARRY_SECONDS := 0.2

## 切帧结果按进程缓存，避免每次挥砍重复建 AtlasTexture。
static var _frame_cache: Array[AtlasTexture] = []

var _frames: Array[AtlasTexture] = []
var _elapsed := 0.0
var _lifetime := PLAY_SECONDS


static func sheet_available() -> bool:
	return ResourceLoader.exists(SHEET_PATH)


static func _get_frames() -> Array[AtlasTexture]:
	if not _frame_cache.is_empty() or not sheet_available():
		return _frame_cache
	var sheet := load(SHEET_PATH) as Texture2D
	if sheet == null:
		return _frame_cache
	for i in range(SHEET_COLS * SHEET_ROWS):
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(
			(i % SHEET_COLS) * FRAME_SIZE.x,
			int(i / float(SHEET_COLS)) * FRAME_SIZE.y,
			FRAME_SIZE.x,
			FRAME_SIZE.y
		)
		_frame_cache.append(frame)
	return _frame_cache


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 10
	_frames = _get_frames()
	if _frames.is_empty():
		queue_free()  # 缺素材（如 headless 未导入）：立即退场
		return
	texture = _frames[0]
	GameEvents.parried.connect(_on_parried)


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _lifetime:
		queue_free()
		return
	var count := mini(PLAY_FRAMES, _frames.size())
	var idx: int = clampi(int(_elapsed / _lifetime * count), 0, count - 1)
	texture = _frames[idx]


func _on_parried(_projectile: Node, _by_actor: Node) -> void:
	# 招架瞬间：同屏活跃弧光炸亮为近白、放大 1.4 倍并延长存活。
	modulate = PARRY_MODULATE
	scale = PARRY_SCALE
	_lifetime = PARRY_SECONDS
