extends TestCase


func test_spitter_drops_tether_on_death() -> void:
	var arena := Node2D.new()
	add_child(arena)
	var spit := preload("res://scenes/enemies/SpitterEnemy.tscn").instantiate()
	spit.position = Vector2(80, 0)
	arena.add_child(spit)
	await flush(2)
	ok(spit.has_node("Health"))
	(spit.get_node("Health") as Health).take_damage(99, spit)
	await flush(2)
	var found := false
	for child in arena.get_children():
		if child is CorePickup:
			found = true
			eq((child as CorePickup).core.ability_id, AbilityIds.HOOKSHOT_TETHER)
	ok(found, "spitter leaves a tether core")
