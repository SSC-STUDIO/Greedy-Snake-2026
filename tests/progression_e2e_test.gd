extends TestCase
## Gate chain: plate opens door, kiln melts the rust gate, heart stays locked.


func setup() -> void:
	SaveData.flags.clear()
	Director.abort()


func teardown() -> void:
	SaveData.flags.clear()
	Director.abort()
	if get_tree().paused:
		get_tree().paused = false


func test_plate_opens_door_then_kiln_melts_gate() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	var plate := PressurePlate.new()
	plate.position = player.global_position
	arena.add_child(plate)
	var door := ArenaDoor.new()
	door.position = Vector2(player.global_position.x + 80.0, player.global_position.y - 32.0)
	arena.add_child(door)
	plate.activated.connect(door.open_door)
	await flush(8)
	ok(door.is_open, "weight on the plate rusts the latch")
	player.collect_core(AbilityCatalog.kiln_core())
	ok(player.inventory.insert_into_socket(0))
	ok(player.inventory.has_ability(AbilityIds.HEAT_FORGE))
	var gate := RustyGate.new()
	gate.position = Vector2(player.global_position.x + 40.0, player.global_position.y - 32.0)
	arena.add_child(gate)
	await flush(1)
	gate.melt(player)
	ok(gate._melted, "kiln melts the rust gate")


func test_heart_lock_follows_boss_flag() -> void:
	SaveData.flags.clear()
	var heart := ForgeHeart.new()
	add_child(heart)
	await flush(1)
	ok(not heart.unlocked, "heart locked before the executioner falls")
	ok(not heart.can_interact(null))
	SaveData.mark_flag("boss_dead")
	heart.unlock()
	ok(heart.unlocked)
	ok(heart.can_interact(null))
