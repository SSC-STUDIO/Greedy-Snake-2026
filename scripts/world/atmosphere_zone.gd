class_name AtmosphereZone
extends Area2D
## Reusable indoor / outdoor trigger. Clock keeps running; WorldClock.zone
## only swaps lighting + weather particles. Future rooms call the same API.

@export var zone: int = 1


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body != null and body.is_in_group("player"):
		WorldClock.enter_zone(zone)


func _on_body_exited(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	WorldClock.leave_zone()
