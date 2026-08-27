extends TestCase
## Integration: the slash ACTIVE window deflects an incoming slag bolt home.
## Uses the real Player + Projectile scenes; drives the swing via start_swing()
## (input-free by design) and lets physics resolve the overlap.


func test_active_window_deflects_incoming_bolt_at_spitter() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena, Vector2(320, -24))
	almost(player.global_position.y, 0.0, 6.0, "settled onto floor")

	const PROJ := preload("res://scenes/combat/Projectile.tscn")
	var shooter := Node2D.new()
	shooter.position = Vector2(480, -38)
	arena.add_child(shooter)

	var bolt: Projectile = PROJ.instantiate()
	bolt.setup(Vector2(340, -38), Vector2.LEFT, 40.0, &"enemy", shooter)
	arena.add_child(bolt)
	await flush(2)

	# Swing, ride out wind-up into the ACTIVE (parry) window...
	ok(player.melee.start_swing(), "swing armed")
	var active := await wait_until(func() -> bool:
		return player.melee.is_parry_window(), 60)
	ok(active, "reached the active parry window")

	# ...and hand the overlapping bolt to the production deflect path
	# (this is exactly what the hitbox sweep feeds it each idle frame).
	player.melee._on_hitbox_area_entered(bolt)
	ok(bolt.deflected, "bolt deflected through the melee hook")
	eq(bolt.team, &"player")
	ok(bolt.velocity.x > 0.0, "reflected back toward its source")

	var untouched := player.health.current == player.health.max_hp
	ok(untouched, "player took no damage")
	await wait_until(func() -> bool:
		return player.melee.phase_name() == "idle", 80)
	eq(player.melee.phase_name(), "idle", "swing finished cleanly")


func test_double_deflect_is_refused() -> void:
	const PROJ := preload("res://scenes/combat/Projectile.tscn")
	var arena := Node2D.new()
	add_child(arena)
	var shooter := Node2D.new()
	shooter.position = Vector2(100, 0)
	arena.add_child(shooter)

	var bolt: Projectile = PROJ.instantiate()
	bolt.setup(Vector2.ZERO, Vector2.RIGHT, 10.0, &"enemy", shooter)
	arena.add_child(bolt)
	await flush(2)
	ok(bolt.can_deflect())
	bolt.deflect(shooter)
	ok(not bolt.can_deflect(), "second deflect attempt is a no-op")
