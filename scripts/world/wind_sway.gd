class_name WindSway
extends Node
## Rotates the parent Node2D around its origin (planted at the sprite's feet).
## Reads WorldClock; never owns particles or clock state.

@export var amplitude: float = 1.0
@export var freq: float = 0.85

var phase: float = 0.0


func _ready() -> void:
	if is_equal_approx(phase, 0.0):
		phase = randf() * TAU
	_apply()


func _process(delta: float) -> void:
	if not WorldClock.is_frozen():
		phase += delta * freq
	_apply()


func _apply() -> void:
	var host := get_parent() as Node2D
	if host == null:
		return
	host.rotation = WorldClock.sway_radians() * amplitude * (0.72 + 0.28 * cos(phase))
