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
	shrine.interact(player)
	almost(player.toxin.toxin, 0.0, 0.01)
	eq(player.health.current, player.health.max_hp)
