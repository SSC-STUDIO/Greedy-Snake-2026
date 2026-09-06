extends TestCase
## Flying demon enemy tests: spawning, hover state, hurtbox, taking damage, and death.

const DEMON_SCENE := preload("res://scenes/enemies/FlyingDemonEnemy.tscn")


func test_flying_demon_spawns_and_takes_damage() -> void:
	var arena := Node2D.new()
	add_child(arena)
	var demon := DEMON_SCENE.instantiate() as FlyingDemonEnemy
	demon.position = Vector2(100, 100)
	arena.add_child(demon)
	await flush(2)

	ok(demon.has_node("Health"), "demon has health node")
	eq(demon.health.max_hp, 3, "demon max hp is 3")
	eq(demon.health.current, 3, "demon starts at full hp")

	# Take 1 damage
	demon.health.take_damage(1, arena)
	await flush(2)
	eq(demon.health.current, 2, "demon takes 1 damage")
	ok(demon.is_hurt_locked(), "demon enters hurt lock")

	# Kill demon (clear iframe to simulate follow-up blow)
	demon.health._hit_iframe = 0.0
	demon.health.take_damage(2, arena)
	await flush(2)
	ok(not is_instance_valid(demon), "demon is released after death")


func test_flying_demon_drops_aggro_when_target_invalid() -> void:
	var arena := Node2D.new()
	add_child(arena)
	var player := await spawn_player(arena)
	var demon := DEMON_SCENE.instantiate() as FlyingDemonEnemy
	demon.position = Vector2(100, 100)
	arena.add_child(demon)
	await flush(2)
	player.controller._iframe = 0.2
	demon._state = FlyingDemonEnemy.State.AGGRO
	demon._target_player = player
	demon._tick_state(0.016)
	ok(demon._state == FlyingDemonEnemy.State.PATROL,
		"aggro returns to patrol when target becomes invincible")


func test_hovering_over_the_knight_does_not_spin() -> void:
	var arena := Node2D.new()
	add_child(arena)
	var player := await spawn_player(arena)
	var demon := DEMON_SCENE.instantiate() as FlyingDemonEnemy
	demon.position = player.global_position + Vector2(4.0, -90.0)
	arena.add_child(demon)
	await flush(2)
	demon.set_physics_process(false)
	demon._state = FlyingDemonEnemy.State.AGGRO
	demon._target_player = player
	demon._shoot_timer = 999.0
	var flips := 0
	var last := demon._dir
	# Straddle the knight: dx alternates sign every tick, as it does in play.
	for i in 60:
		demon.global_position.x = player.global_position.x + (6.0 if i % 2 == 0 else -6.0)
		demon._tick_state(1.0 / 60.0)
		demon._after_move()
		if demon._dir != last:
			flips += 1
			last = demon._dir
	eq(flips, 0, "inside the facing dead zone the demon holds its heading")
	ok(absf(demon.velocity.x) < 1.0, "overhead it hovers instead of hunting the sign of dx")
	# Far to one side it does turn — once, then respects the cooldown.
	demon.global_position.x = player.global_position.x - 80.0
	demon._tick_state(1.0 / 60.0)
	eq(demon._dir, 1.0, "demon turns to face the knight on its right")
	demon.global_position.x = player.global_position.x + 80.0
	demon._tick_state(1.0 / 60.0)
	eq(demon._dir, 1.0, "a second flip within the cooldown is ignored")
	demon._tick_state(FlyingDemonEnemy.FLIP_COOLDOWN + 0.01)
	eq(demon._dir, -1.0, "after the cooldown it turns to face the knight again")
	demon._after_move()
	eq(demon.visual.scale.x, 1.0, "visual mirrors the heading")


func test_wings_keep_looping_after_attack_without_spray_projectiles() -> void:
	var arena := Node2D.new()
	add_child(arena)
	var demon := DEMON_SCENE.instantiate() as FlyingDemonEnemy
	arena.add_child(demon)
	demon.set_physics_process(false)
	demon._start_attack()
	await flush(12)
	var first: Texture2D = demon._anim.texture
	await flush(7)
	ok(demon._anim.texture != first, "wings change frames throughout windup")
	demon._state = FlyingDemonEnemy.State.SWOOP
	demon._state_timer = 0.01
	demon._tick_state(0.02)
	await flush(8)
	eq(demon._anim.current(), "idle", "recovery uses the looping wing animation")
	ok(not demon.hitbox.monitoring, "swoop damage ends during recovery")
	for child in arena.get_children():
		ok(not child is Projectile, "flying demon never emits the spray projectile")
