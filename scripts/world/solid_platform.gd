class_name SolidPlatform
extends StaticBody2D
## Axis-aligned rust girder. Size is applied in _ready so instances can be configured first.

@export var size: Vector2 = Vector2(64, 16)
@export var fill: Color = Color("#8B4513")


func setup(pos: Vector2, sz: Vector2, col: Color) -> void:
	position = pos
	size = sz
	fill = col


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var rect := ColorRect.new()
	rect.size = size
	rect.color = fill
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	col.position = size * 0.5
	add_child(col)
