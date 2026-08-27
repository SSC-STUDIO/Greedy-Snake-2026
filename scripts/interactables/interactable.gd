class_name Interactable
extends Area2D
## Base for E-key objects. Pressure plates may extend this but return false from can_interact.

@export var prompt: String = "E 交互"


func _ready() -> void:
	collision_layer = 64
	collision_mask = 2
	monitoring = true
	monitorable = true


func can_interact(_actor: Node) -> bool:
	return true


func interact(_actor: Node) -> void:
	pass


func get_prompt(_actor: Node) -> String:
	return prompt


func ensure_rect(size: Vector2, color: Color, offset: Vector2 = Vector2.ZERO) -> void:
	if get_node_or_null("Fill") == null:
		var fill := ColorRect.new()
		fill.name = "Fill"
		fill.size = size
		fill.position = offset
		fill.color = color
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(fill)
	if get_node_or_null("CollisionShape2D") == null:
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = size
		col.shape = shape
		col.position = offset + size * 0.5
		add_child(col)
