class_name ArenaDoor
extends Interactable
## Blocks a corridor until a pressure plate rusts the latch open.

var is_open: bool = false


func _ready() -> void:
	super._ready()
	add_to_group("persistent")
	prompt = ""
	ensure_rect(Vector2(16, 64), Palette.IRON)
	if get_node_or_null("Solid") == null:
		var solid := StaticBody2D.new()
		solid.name = "Solid"
		solid.collision_layer = 1
		solid.collision_mask = 0
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(16, 64)
		col.shape = shape
		col.position = Vector2(8, 32)
		solid.add_child(col)
		add_child(solid)


func can_interact(_actor: Node) -> bool:
	return false


func open_door() -> void:
	if is_open:
		return
	is_open = true
	var solid := get_node_or_null("Solid") as StaticBody2D
	if solid:
		solid.collision_layer = 0
	var fill := get_node_or_null("Fill") as ColorRect
	if fill:
		fill.modulate.a = 0.22
	GameEvents.announcement.emit("闸门锈死在开启位置")


## --- persistence ---------------------------------------------------------
func get_persistent_state() -> Dictionary:
	return {"open": is_open}


func apply_persistent_state(state: Dictionary) -> void:
	if bool(state.get("open", false)):
		is_open = true
		var solid := get_node_or_null("Solid") as StaticBody2D
		if solid:
			solid.collision_layer = 0
		var fill := get_node_or_null("Fill") as ColorRect
		if fill:
			fill.modulate.a = 0.22
