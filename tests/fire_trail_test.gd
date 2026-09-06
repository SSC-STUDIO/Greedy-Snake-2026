extends TestCase
## Heat-forge fire trail is a world-space residue, not a child of Player.


func test_fire_trail_is_not_parented_to_player() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	var effects := GameContext.world_effects(player)
	var before: Array = []
	for child in effects.get_children():
		before.append(child)
	player._spawn_fire_trail()
	var trail: Hitbox = null
	for child in effects.get_children():
		if child is Hitbox and not before.has(child):
			trail = child
			break
	ok(trail != null, "trail spawned in the world")
	if trail == null:
		return
	ok(trail.get_world_2d() == player.get_world_2d(), "trail collides in the player's world")
	ok(trail.get_parent() != player, "trail parent is not Player")
	ok(not player.get_children().has(trail), "trail is not a player child")
	var parked := trail.global_position
	player.global_position += Vector2(180, 0)
	await flush(1)
	almost(trail.global_position.x, parked.x, 0.5, "trail stays in world space")
	almost(trail.global_position.y, parked.y, 0.5)


func test_fx_one_shots_host_inside_the_game_world() -> void:
	# No level registered: the autoload keeps hosting itself (TestArena, F6 runs).
	eq(Fx._effects_host(), Fx, "without a game_world, Fx hosts its own particles")
	var world := Node2D.new()
	world.name = "Level01_Static"
	world.add_to_group("game_world")
	add_child(world)
	var host := Fx._effects_host()
	ok(host != Fx, "with a game_world, particles leave the root-window autoload")
	eq(host.name, "WorldEffects")
	eq(host.get_parent(), world, "dust/sparks render under the level, inside its viewport")
	world.queue_free()
	await flush(1)
	eq(Fx._effects_host(), Fx, "freed level releases the host again")
