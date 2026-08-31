extends TestCase
## SaveData round-trip: persistence of player/inventory/world/consumed state.
## Uses a throwaway save path so it never touches real progress.


func setup() -> void:
	SaveData.save_path = "user://rustgrave_test_save.cfg"
	SaveData.delete_save()


func teardown() -> void:
	SaveData.delete_save()
	SaveData.save_path = "user://rustgrave_save.cfg"


func test_roundtrip_persists_player_and_inventory() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	player.health.current = 3
	player.toxin.toxin = 40.0
	var inv := player.inventory
	inv.add_to_pouch(AbilityCatalog.kiln_core())
	inv.add_to_pouch(AbilityCatalog.tether_core())
	inv.insert_into_socket(0)  # kiln into socket 0; pouch = [tether]

	ok(SaveData.save_game("res://scenes/levels/Level01_Static.tscn", player))
	ok(SaveData.has_save())
	ok(SaveData.load_game())

	eq(int(SaveData.data["player"]["hp"]), 3)
	eq(float(SaveData.data["player"]["toxin"]), 40.0)
	var inv_data: Dictionary = SaveData.data["player"]
	eq(inv_data["pouch"], ["tether_core"])
	eq(inv_data["sockets"], ["kiln_core", ""])

	SaveData.delete_save()
	ok(not SaveData.has_save(), "delete clears the file")


func test_apply_player_restores_live_state() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	player.health.current = 2
	player.toxin.toxin = 60.0
	player.inventory.add_to_pouch(AbilityCatalog.tether_core())
	player.inventory.insert_into_socket(0)
	SaveData.save_game("res://scenes/levels/Level01_Static.tscn", player)

	# Wipe the live instance back to defaults, then restore from the save.
	player.health.current = 5
	player.toxin.toxin = 0.0
	SaveData.load_game()
	SaveData.apply_player(player)

	eq(player.health.current, 2, "hp restored")
	ok(player.inventory.has_ability(AbilityIds.HOOKSHOT_TETHER), "socketed core rehydrated")
	eq(player.inventory.pouch.size(), 0)


func test_consumed_paths_mark_and_query() -> void:
	SaveData.delete_save()
	ok(not SaveData.is_consumed("/root/Props/ScrapPile"))
	SaveData.mark_consumed("/root/Props/ScrapPile")
	ok(SaveData.is_consumed("/root/Props/ScrapPile"))
	SaveData.delete_save()
	ok(not SaveData.is_consumed("/root/Props/ScrapPile"), "delete clears consumed list")


func test_unknown_core_id_rehydrates_to_null() -> void:
	ok(AbilityCatalog.for_id(&"kiln_core") != null)
	ok(AbilityCatalog.for_id(&"tether_core") != null)
	ok(AbilityCatalog.for_id(&"ember_core") != null)
	ok(AbilityCatalog.for_id(&"nonexistent") == null, "unknown ids degrade to null")


func test_ember_core_survives_roundtrip() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	player.inventory.add_to_pouch(AbilityCatalog.ember_core())
	player.inventory.insert_into_socket(0)
	ok(SaveData.save_game("res://scenes/levels/Level01_Static.tscn", player))
	ok(SaveData.load_game())
	eq(SaveData.data["player"]["sockets"], ["ember_core", ""])
	player.inventory.sockets[0] = null
	SaveData.apply_player(player)
	ok(player.inventory.has_ability(AbilityIds.EMBER_STEP))


func test_boss_dead_flag_survives_load_when_persisted() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	ok(SaveData.save_game("res://scenes/levels/Level01_Static.tscn", player))
	ok(Level01Static.should_spawn_executioner(), "fresh save still has the boss")
	Level01Static.mark_executioner_slain()
	ok(SaveData.has_flag("boss_dead"))
	SaveData.flags.clear()
	ok(not SaveData.has_flag("boss_dead"), "memory wiped")
	ok(SaveData.load_game())
	ok(SaveData.has_flag("boss_dead"), "persist_story wrote boss_dead")
	ok(not Level01Static.should_spawn_executioner(), "reload skips Executioner")
	ok(Level01Static.should_unlock_forge())


func test_ember_nest_restore_is_silent() -> void:
	var nest := EmberNest.new()
	add_child(nest)
	await flush(1)
	var heard: Array[String] = []
	var on_announce := func(text: String) -> void:
		heard.append(text)
	GameEvents.announcement.connect(on_announce)
	nest.apply_persistent_state({"lit": true})
	ok(bool(nest.get_persistent_state().get("lit", false)), "lit flag restored")
	eq(heard.size(), 0, "apply_persistent_state does not announce")
	nest.apply_persistent_state({"lit": false})
	eq(heard.size(), 0, "unlit restore is also silent")
	GameEvents.announcement.disconnect(on_announce)


func test_ember_nest_interact_still_announces() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	var nest := EmberNest.new()
	arena.add_child(nest)
	await flush(1)
	var heard: Array[String] = []
	GameEvents.announcement.connect(func(text: String) -> void: heard.append(text), CONNECT_ONE_SHOT)
	nest.interact(player)
	ok(not heard.is_empty(), "resting at the nest still announces")
	ok(heard[0].contains("余烬"), "live rest uses the kindle line, not a load-restore hint")


func test_boss_dead_flag_lost_on_load_without_persist() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	ok(SaveData.save_game("res://scenes/levels/Level01_Static.tscn", player))
	SaveData.mark_flag("boss_dead")
	ok(SaveData.has_flag("boss_dead"))
	ok(SaveData.load_game())
	ok(not SaveData.has_flag("boss_dead"), "in-memory flag is not on disk")
	ok(Level01Static.should_spawn_executioner(), "unpersisted kill respawns the boss")
