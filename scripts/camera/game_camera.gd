class_name GameCamera
extends Camera2D
## Smooth follow with a small horizontal look-ahead based on facing / velocity.

@export var follow_speed: float = 6.5
@export var look_ahead: float = 48.0
@export var look_ahead_speed: float = 3.2
@export var vertical_offset: float = -18.0

var _look: float = 0.0


func _ready() -> void:
	make_current()
	position_smoothing_enabled = false
	limit_left = 0
	limit_top = 0
	limit_right = 1600
	limit_bottom = 400


func _physics_process(delta: float) -> void:
	var target := get_tree().get_first_node_in_group("player") as Player
	if target == null:
		return
	var desired := float(target.controller.facing) * look_ahead * 0.45
	if absf(target.velocity.x) > 18.0:
		desired = signf(target.velocity.x) * look_ahead
	_look = lerpf(_look, desired, 1.0 - exp(-look_ahead_speed * delta))
	var dest := target.global_position + Vector2(_look, vertical_offset)
	global_position = global_position.lerp(dest, 1.0 - exp(-follow_speed * delta))
