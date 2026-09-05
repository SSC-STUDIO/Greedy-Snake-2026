class_name PressurePlate
extends Interactable
## Weighted trigger. The knight's mass (and future pommel slams) press this.

signal activated
signal deactivated

var _count: int = 0


func _ready() -> void:
	# 视觉仍是 32×10 石唇；判定加高，落地瞬间脚还在空中也能压上。
	reach_pad = Vector2(4, 8)
	super._ready()
	add_to_group("pressure_plate")
	prompt = ""
	# 教堂石板唇沿（原生 32x10）：一块平放的踏板，而不是被压扁的墓碑。
	ensure_sprite("res://assets/env/plate_stone.png", Vector2(32, 10), Vector2(-4, -2), Palette.RUST_MID)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func can_interact(_actor: Node) -> bool:
	return false


func slam() -> void:
	if _count == 0:
		activated.emit()
		_set_pressed(true)
		get_tree().create_timer(0.45).timeout.connect(func() -> void:
			if _count == 0:
				deactivated.emit()
				_set_pressed(false)
		)


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
	var fill := get_node_or_null("Fill") as Node2D
	if fill:
		fill.position.y = 4.0 if down else -2.0
		fill.modulate = Color(1.25, 0.95, 0.7) if down else Color.WHITE
	if down:
		Sfx.play(&"insert")
