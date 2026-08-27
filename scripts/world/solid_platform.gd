class_name SolidPlatform
extends StaticBody2D
## Axis-aligned rust girder. Size is applied in _ready so instances can be configured first.

@export var size: Vector2 = Vector2(64, 16)
@export var fill: Color = Color("#8B4513")


func setup(pos: Vector2, sz: Vector2, col: Color) -> void:
	position = pos
	size = sz
	fill = col


const TILE_TEX_PATH := "res://assets/kenney_clean/tiles/castleCenter.png"
const BRIDGE_TEX_PATH := "res://assets/kenney_clean/tiles/castleMid.png"

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_build_visual()
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	col.position = size * 0.5
	add_child(col)


func _build_visual() -> void:
	# Try to use Kenney tile, fallback to ColorRect if not imported yet.
	var tex: Texture2D = null
	if ResourceLoader.exists(TILE_TEX_PATH):
		tex = load(TILE_TEX_PATH) as Texture2D
	if tex == null:
		var rect := ColorRect.new()
		rect.name = "VisualRect"
		rect.size = size
		rect.color = fill
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)
		return
	# Choose bridge vs block based on aspect ratio: thin platforms use horizontal tile.
	var use_bridge := size.y <= 20.0 and size.x > 48.0 and ResourceLoader.exists(BRIDGE_TEX_PATH)
	if use_bridge:
		tex = load(BRIDGE_TEX_PATH) as Texture2D
	# Tile the texture across the rect via repeated TextureRect chunks.
	var tile_w := float(tex.get_width())
	var tile_h := float(tex.get_height())
	# For thin platforms, stretch height to fit instead of tiling vertically.
	var cols := maxi(1, int(ceil(size.x / tile_w)))
	var rows := maxi(1, int(ceil(size.y / tile_h)))
	if use_bridge:
		rows = 1
	for r in rows:
		for c in cols:
			var spr := Sprite2D.new()
			spr.texture = tex
			spr.centered = false
			spr.position = Vector2(c * tile_w, r * tile_h)
			# Clip overflow by scaling down last tile via region.
			var w := minf(tile_w, size.x - c * tile_w)
			var h := minf(tile_h, size.y - r * tile_h)
			if w < tile_w or h < tile_h:
				spr.region_enabled = true
				spr.region_rect = Rect2(0, 0, w, h)
			# Tint toward palette to keep rust mood; keep a bit desaturated.
			spr.modulate = fill.lerp(Color.WHITE, 0.35)
			spr.z_index = -1
			add_child(spr)
	# Subtle ColorRect overlay at low alpha to unify palette.
	var tint := ColorRect.new()
	tint.name = "Tint"
	tint.size = size
	tint.color = fill
	tint.color.a = 0.18
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint.z_index = 0
	add_child(tint)
