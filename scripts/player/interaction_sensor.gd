class_name InteractionSensor
extends Area2D
## Finds the nearest Interactable overlapping the knight.

var _nearby: Array = []


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	collision_layer = 0
	collision_mask = 64 # interact


func get_focus() -> Interactable:
	var best: Interactable = null
	var best_d := INF
	var actor := get_parent()
	for area in _nearby:
		if not is_instance_valid(area):
			continue
		if not area is Interactable:
			continue
		var inter := area as Interactable
		if not inter.can_interact(actor):
			continue
		var d: float = global_position.distance_squared_to(inter.global_position)
		if d < best_d:
			best_d = d
			best = inter
	return best


func _on_area_entered(area: Area2D) -> void:
	if area is Interactable and not _nearby.has(area):
		_nearby.append(area)


func _on_area_exited(area: Area2D) -> void:
	_nearby.erase(area)
