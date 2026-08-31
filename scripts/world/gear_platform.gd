class_name GearPlatform
extends StaticBody2D
## Small hovering stone foothold (octagon collision, church slab block).
## 悬空物件走"石造台子"皮肤家族，与接地的草顶土地明确区分。

@export var radius: float = 16.0
@export var fill: Color = Color("#2a1e32")

const BLOCK_PATH := "res://assets/env/float_small.png"
const FLOAT_TONE := Color(0.82, 0.8, 0.95)
const WORLD := 16.0


func setup(pos: Vector2, r: float) -> void:
	position = pos
	radius = r


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var pts := PackedVector2Array()
	for i in 8:
		var a := deg_to_rad(22.5 + float(i) * 45.0)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	_build_visual()
	var col := CollisionPolygon2D.new()
	col.polygon = pts
	add_child(col)


func _build_visual() -> void:
	if ResourceLoader.exists(BLOCK_PATH):
		var tex := load(BLOCK_PATH) as Texture2D
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.centered = false
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# 八边形碰撞顶边在 y≈-0.92*radius；石台顶面与其对齐。
		var s := (radius * 2.0) / float(tex.get_width())
		spr.scale = Vector2(s, s)
		spr.position = Vector2(-radius, -0.92 * radius)
		spr.modulate = FLOAT_TONE
		add_child(spr)
		return
	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 8:
		var a := deg_to_rad(22.5 + float(i) * 45.0)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	poly.polygon = pts
	poly.color = fill
	add_child(poly)
