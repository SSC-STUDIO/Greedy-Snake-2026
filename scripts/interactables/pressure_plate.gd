class_name PressurePlate
extends Interactable
## Weighted trigger. The knight's mass (and future pommel slams) press this.

signal activated
signal deactivated

var _count: int = 0


func _ready() -> void:
	super._ready()
	prompt = ""
	ensure_rect(Vector2(28, 6), Palette.RUST_MID)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func can_interact(_actor: Node) -> bool:
	return false


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_count += 1
		if _count == 1:
			activated.emit()
			_set_pressed(true)


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_count = maxi(0, _count - 1)
		if _count == 0:
			deactivated.emit()
			_set_pressed(false)


func _set_pressed(down: bool) -> void:
	var fill := get_node_or_null("Fill") as ColorRect
	if fill:
		fill.position.y = 3.0 if down else 0.0
		fill.color = Palette.EMBER if down else Palette.RUST_MID
