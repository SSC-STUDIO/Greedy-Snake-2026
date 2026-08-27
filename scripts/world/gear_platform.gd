class_name GearPlatform
extends StaticBody2D
## Broken gear foothold. Octagon reads as a rusted cog from a distance.

@export var radius: float = 22.0
@export var fill: Color = Color("#8B4513")


func setup(pos: Vector2, r: float) -> void:
	position = pos
	radius = r


const GEAR_TEX_PATH := "res://assets/kenney_clean/tiles/box.png"

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var pts := PackedVector2Array()
	for i in 8:
		var a := deg_to_rad(22.5 + float(i) * 45.0)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	_build_visual(pts)
	var col := CollisionPolygon2D.new()
	col.polygon = pts
	add_child(col)


func _build_visual(pts: PackedVector2Array) -> void:
	var tex: Texture2D = null
	if ResourceLoader.exists(GEAR_TEX_PATH):
		tex = load(GEAR_TEX_PATH) as Texture2D
	if tex == null:
		var poly := Polygon2D.new()
		poly.polygon = pts
		poly.color = fill
		add_child(poly)
		return
	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.texture = tex
	poly.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	# UVs scaled so texture tiles roughly every 22px.
	var uvs := PackedVector2Array()
	for p in pts:
		uvs.append((p + Vector2(radius, radius)) / 22.0)
	poly.uv = uvs
	poly.color = fill.lerp(Color.WHITE, 0.3)
	add_child(poly)
	var outline := Line2D.new()
	outline.points = pts + PackedVector2Array([pts[0]])
	outline.width = 2.0
	outline.default_color = Palette.RUST_SHADOW
	outline.closed = true
	add_child(outline)
