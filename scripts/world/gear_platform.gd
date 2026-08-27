class_name GearPlatform
extends StaticBody2D
## Broken gear foothold. Octagon reads as a rusted cog from a distance.

@export var radius: float = 22.0
@export var fill: Color = Color("#8B4513")


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
	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.color = fill
	add_child(poly)
	var col := CollisionPolygon2D.new()
	col.polygon = pts
	add_child(col)
