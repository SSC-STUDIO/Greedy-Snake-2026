extends TestCase
## Heat-forge fire trail is a world-space residue, not a child of Player.


func test_fire_trail_is_not_parented_to_player() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	var before: Array = []
	for child in get_tree().current_scene.get_children():
		before.append(child)
	player._spawn_fire_trail()
	var trail: Hitbox = null
	for child in get_tree().current_scene.get_children():
		if child is Hitbox and not before.has(child):
			trail = child
			break
	ok(trail != null, "trail spawned in the world")
	ok(trail.get_parent() != player, "trail parent is not Player")
	ok(not player.get_children().has(trail), "trail is not a player child")
	var parked := trail.global_position
	player.global_position += Vector2(180, 0)
	await flush(1)
	almost(trail.global_position.x, parked.x, 0.5, "trail stays in world space")
	almost(trail.global_position.y, parked.y, 0.5)
