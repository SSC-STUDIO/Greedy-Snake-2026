class_name ToxinPool
extends Area2D
## Orange sludge. Standing in it fills the knight's toxin meter.

@export var toxin_per_second: float = 36.0

var _bodies: Array = []


func _ready() -> void:
	collision_layer = 128
	collision_mask = 2
	monitoring = true
	monitorable = true
	body_entered.connect(func(b: Node2D) -> void: _bodies.append(b))
	body_exited.connect(func(b: Node2D) -> void: _bodies.erase(b))
	if get_node_or_null("Fill") == null:
		var fill := ColorRect.new()
		fill.name = "Fill"
		fill.size = Vector2(112, 48)
		fill.color = Color(Palette.TOXIC.r, Palette.TOXIC.g, Palette.TOXIC.b, 0.78)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(fill)
	if get_node_or_null("CollisionShape2D") == null:
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(112, 48)
		col.shape = shape
		col.position = Vector2(56, 24)
		add_child(col)


func configure(size: Vector2) -> void:
	var fill := get_node_or_null("Fill") as ColorRect
	if fill:
		fill.size = size
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col and col.shape is RectangleShape2D:
		(col.shape as RectangleShape2D).size = size
		col.position = size * 0.5


func _physics_process(delta: float) -> void:
	for body in _bodies:
		if body is Player:
			(body as Player).toxin.expose(toxin_per_second * delta)
