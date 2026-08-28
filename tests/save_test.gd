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
	ok(AbilityCatalog.for_id(&"nonexistent") == null, "unknown ids degrade to null")
