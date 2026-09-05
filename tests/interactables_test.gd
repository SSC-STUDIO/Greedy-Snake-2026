extends TestCase


func setup() -> void:
	Director.abort()


func teardown() -> void:
	Director.abort()


func test_scrap_gives_kiln() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	var pile := ScrapPile.new()
	arena.add_child(pile)
	await flush(1)
	pile.interact(player)
	ok(not pile.can_interact(player))
	eq(player.inventory.pouch.size(), 1)
	eq((player.inventory.pouch[0] as RustCore).ability_id, AbilityIds.HEAT_FORGE)


func test_filter_purifies() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	player.toxin.toxin = 80.0
	var gear := FilterGear.new()
	arena.add_child(gear)
	await flush(1)
	gear.interact(player)
	ok(player.toxin.toxin < 50.0, "filter knocks toxin down")


func test_socket_station_inserts() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	player.collect_core(AbilityCatalog.ember_core())
	var bench := SocketStation.new()
	arena.add_child(bench)
	await flush(1)
	bench.interact(player)
	ok(player.inventory.has_ability(AbilityIds.EMBER_STEP))


func test_shrine_full_cleanse() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	player.toxin.toxin = 90.0
	player.health.current = 1
	var shrine := PurificationShrine.new()
	arena.add_child(shrine)
	await flush(1)
	eq(shrine.get_prompt(player), "E 祈请净化祠")
	shrine.interact(player)
	almost(player.toxin.toxin, 0.0, 0.01)
	eq(player.health.current, player.health.max_hp)
	eq(shrine.get_prompt(player), "净化祠已洁净")


func test_shrine_already_clean_announces() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	var shrine := PurificationShrine.new()
	arena.add_child(shrine)
	await flush(1)
	eq(shrine.get_prompt(player), "净化祠已洁净")
	var heard := [""]
	GameEvents.announcement.connect(func(t: String) -> void: heard[0] = t, CONNECT_ONE_SHOT)
	shrine.interact(player)
	eq(heard[0], "祠里已经没有锈可洗")


func test_closed_door_asks_for_the_plate() -> void:
	var door := ArenaDoor.new()
	add_child(door)
	await flush(1)
	ok(door.can_interact(null), "closed gate stays focusable")
	eq(door.get_prompt(null), "闸门锁死 — 需要压下踏板")
	var heard := [""]
	GameEvents.announcement.connect(func(t: String) -> void: heard[0] = t, CONNECT_ONE_SHOT)
	door.interact(null)
	ok(heard[0].contains("石板"), "E on a locked door points at the plate")
	door.open_door()
	ok(not door.can_interact(null), "open door drops the prompt")


func test_small_prop_collision_uses_reach_pad() -> void:
	var gear := FilterGear.new()
	add_child(gear)
	await flush(1)
	var col: CollisionShape2D = null
	for child in gear.get_children():
		if child is CollisionShape2D:
			col = child
			break
	ok(col != null)
	if col != null:
		var shape := col.shape as RectangleShape2D
		ok(shape != null)
		if shape != null:
			eq(shape.size, Vector2(34, 30), "14×14 gear + reach_pad (10, 8)")


func test_toxin_pool_hints_on_repeat_dip() -> void:
	Director.abort()
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	var pool := ToxinPool.new()
	arena.add_child(pool)
	pool._bodies.append(player)
	var heard := [""]
	var on_ann := func(t: String) -> void: heard[0] = t
	GameEvents.announcement.connect(on_ann)
	eq(pool.surface_rect(), Rect2(pool.global_position, Vector2(112, 32)))
	pool._physics_process(0.1)
	eq(heard[0], "腐液咬着靴底")
	heard[0] = ""
	pool._physics_process(0.1)
	eq(heard[0], "", "standing in the pool does not spam")
	pool._on_body_exited(player)
	heard[0] = ""
	pool._on_body_entered(player)
	pool._physics_process(0.1)
	eq(heard[0], "腐液咬着靴底", "leaving and dipping again re-hints")
	GameEvents.announcement.disconnect(on_ann)
	Director.abort()


func test_toxin_pool_does_not_zero_velocity_or_cap_the_pit() -> void:
	Director.abort()
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	var pool := ToxinPool.new()
	pool.position = player.global_position + Vector2(-56.0, -8.0)
	arena.add_child(pool)
	pool.configure(Vector2(112, 32))
	ok(pool is Area2D, "film is an Area, not a Static lid")
	eq(pool.collision_layer, 128)
	eq(pool.surface_rect().size, Vector2(112, 32))
	pool._bodies.append(player)
	player.velocity = Vector2(90.0, -40.0)
	pool._physics_process(0.16)
	almost(player.velocity.x, 90.0, 0.01, "pool does not clear vx")
	almost(player.velocity.y, -40.0, 0.01, "pool does not clear vy")
	player.controller.physics_tick(player, 1.0 / 60.0, 1.0)
	ok(absf(player.velocity.x) > 1.0 or player.velocity.y != 0.0,
			"locomotion still writes velocity while overlapping the film")
	Director.abort()
