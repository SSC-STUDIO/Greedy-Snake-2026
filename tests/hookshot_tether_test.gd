extends TestCase
## Tether pull (not melt-hook).


func test_try_fire_locks_onto_anchor() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena, Vector2(320, -24))
	player.collect_core(AbilityCatalog.tether_core())
	player.inventory.insert_into_socket(0)
	var hook := preload("res://scenes/interactables/HookAnchor.tscn").instantiate() as Node2D
	hook.position = player.global_position + Vector2(90, -48)
	arena.add_child(hook)
	await flush(2)
	ok(player.hookshot.try_fire(player), "tether finds the anchor")
	ok(player.hookshot.is_active())
	var before := player.global_position.x
	player.hookshot.apply_tether_velocity(player)
	ok(player.velocity.x > 0.0, "pull aims at the anchor")
	ok(player.global_position.x >= before)
