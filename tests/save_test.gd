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


func test_resolve_saved_node_accepts_absolute_and_relative() -> void:
	var host := Node2D.new()
	host.name = "LevelHost"
	add_child(host)
	var props := Node2D.new()
	props.name = "Props"
	host.add_child(props)
	var nest := EmberNest.new()
	nest.name = "EmberNest"
	props.add_child(nest)
	await flush(1)
	ok(SaveData.resolve_saved_node(host, "Props/EmberNest") == nest, "relative path")
	ok(SaveData.resolve_saved_node(host, String(nest.get_path())) == nest, "absolute path")
	ok(SaveData.resolve_saved_node(host, "EmberNest") == nest, "unique leaf")


func test_apply_lit_nests_relights_when_world_key_is_stale() -> void:
	var host := Node2D.new()
	add_child(host)
	var nest := EmberNest.new()
	nest.name = "EmberNest"
	host.add_child(nest)
	await flush(1)
	eq(bool(nest.get_persistent_state().get("lit", false)), false)
	SaveData.register_lit_nest("EmberNest")
	SaveData.apply_world(host)
	eq(bool(nest.get_persistent_state().get("lit", false)), false, "stale world dict does not light it")
	SaveData.apply_lit_nests(host)
	ok(bool(nest.get_persistent_state().get("lit", false)), "lit_nests relights the shrine")


func test_delete_save_clears_pending_spawn() -> void:
	SaveData.pending_spawn = Vector2(80, 290)
	SaveData.entering_from_checkpoint = true
	SaveData.mark_consumed("Pickups/Kiln_Pit")
	SaveData.delete_save()
	ok(not SaveData.has_pending_spawn(), "new game cannot inherit a death spawn")
	ok(not SaveData.entering_from_checkpoint)
	ok(not SaveData.is_consumed("Pickups/Kiln_Pit"))


func test_register_lit_nest_moves_to_end() -> void:
	SaveData.register_lit_nest("Props/NestA")
	SaveData.register_lit_nest("Props/NestB")
	SaveData.register_lit_nest("Props/NestA")
	eq(SaveData.last_lit_nest(), "Props/NestA", "re-resting an earlier nest becomes the spawn")
	eq(SaveData.lit_nests.size(), 2, "same nest is not stored twice")


func test_corrupt_save_falls_back_to_bak() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	player.health.current = 3
	ok(SaveData.save_game("res://scenes/levels/Level01_Static.tscn", player))
	ok(FileAccess.file_exists(SaveData.save_path + ".bak") or FileAccess.file_exists(SaveData.save_path))
	# Second save creates .bak from the first file; then smash the main file.
	ok(SaveData.save_game("res://scenes/levels/Level01_Static.tscn", player))
	var smash := FileAccess.open(SaveData.save_path, FileAccess.WRITE)
	ok(smash != null)
	if smash:
		smash.store_string("not-a-config")
		smash.close()
	ok(SaveData.load_game(), "bak recovers a smashed nest file")
	eq(int(SaveData.data["player"]["hp"]), 3)


func test_persist_story_keeps_consumed() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	ok(SaveData.save_game("res://scenes/levels/Level01_Static.tscn", player))
	SaveData.mark_consumed("Pickups/EmberCore")
	SaveData.mark_flag("boss_dead")
	SaveData.persist_story()
	SaveData.consumed.clear()
	SaveData.flags.clear()
	ok(SaveData.load_game())
	ok(SaveData.has_flag("boss_dead"))
	ok(SaveData.is_consumed("Pickups/EmberCore"), "story flush does not drop pickups")


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


func test_progress_write_keeps_checkpoint_and_live_inventory_together() -> void:
	var world := Node2D.new()
	world.name = "AuthoredLevel"
	world.add_to_group("game_world")
	add_child(world)
	build_floor(world)
	var player := await spawn_player(world)
	SaveData.register_lit_nest("Props/EmberNest")
	ok(SaveData.save_game(GameContext.WORLD_PATH, player))
	var checkpoint: Vector2 = SaveData.data["player"]["pos"]
	player.position.x += 500
	player.health.current = 1
	player.inventory.add_to_pouch(AbilityCatalog.kiln_core())
	player.inventory.insert_into_socket(0)
	player.inventory.add_to_pouch(AbilityCatalog.ember_core())
	player.inventory.insert_into_socket(1)
	SaveData.mark_consumed("Pickups/EmberCore")
	SaveData.mark_consumed("Props/RustyGate")
	SaveData.mark_flag("boss_dead")
	ok(SaveData.persist_progress_for_player(player))
	eq(SaveData.data["player"]["pos"], checkpoint, "boss progress preserves nest position in memory")
	SaveData.data.clear()
	SaveData.flags.clear()
	SaveData.consumed.clear()
	ok(SaveData.load_game())
	eq(SaveData.data["meta"]["scene"], GameContext.WORLD_PATH, "save targets authored world")
	eq(SaveData.data["player"]["pos"], checkpoint, "disk keeps the same checkpoint")
	eq(SaveData.data["player"]["hp"], 5, "progress does not replace checkpoint health")
	eq(SaveData.data["player"]["sockets"], ["kiln_core", "ember_core"])
	ok(SaveData.has_flag("boss_dead"))
	ok(SaveData.is_consumed("Props/RustyGate"))
	ok(SaveData.is_consumed("Pickups/EmberCore"))
	eq(SaveData.last_lit_nest(), "Props/EmberNest")
	SaveData.apply_player(player)
	ok(player.inventory.has_ability(AbilityIds.EMBER_STEP))
	ok(player.inventory.has_ability(AbilityIds.HEAT_FORGE))


func test_legacy_progress_repairs_known_cores_once_and_preserves_backup() -> void:
	var backup := SaveData.save_path + ".before_progress_repair.bak"
	SaveData._remove_if_exists(backup)
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", 1)
	cfg.set_value("player", "pouch", [])
	cfg.set_value("player", "sockets", ["", ""])
	cfg.set_value("consumed", "paths", ["/root/OldLevel/Pickups/EmberCore", "Props/RustyGate", "Props/@Area2D@56"])
	ok(cfg.save(SaveData.save_path) == OK)
	var before := FileAccess.get_file_as_string(SaveData.save_path)
	ok(SaveData.load_game())
	eq(SaveData.data["player"]["pouch"], ["ember_core", "kiln_core"])
	eq(SaveData.consumed.size(), 2, "ambiguous lost drop has an obtainable source again")
	eq(FileAccess.get_file_as_string(backup), before, "original is recoverable byte for byte")
	ok(SaveData.load_game())
	eq(SaveData.data["player"]["pouch"], ["ember_core", "kiln_core"], "migration is idempotent")
	SaveData._remove_if_exists(backup)


func test_failed_write_does_not_replace_memory_checkpoint() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	ok(SaveData.save_game(GameContext.WORLD_PATH, player))
	var previous := SaveData.data.duplicate(true)
	var valid_path := SaveData.save_path
	SaveData.save_path = "user://missing-directory/save.cfg"
	player.position.x += 100
	ok(not SaveData.save_game(GameContext.WORLD_PATH, player))
	eq(SaveData.data, previous, "failed disk write cannot claim a new checkpoint")
	SaveData.save_path = valid_path
