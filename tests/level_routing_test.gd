extends TestCase
## Multi-level routing: presentation shell picks the pending level, save paths
## are namespaced per level, and continue returns to the saved level.


func teardown() -> void:
	GameContext.pending_world_path = GameContext.WORLD_PATH
	SaveData.data = {}
	SaveData.consumed.clear()
	SaveData.lit_nests.clear()


func test_levels_are_registered_and_routed_through_the_presentation() -> void:
	ok(GameContext.is_world_scene(GameContext.WORLD_PATH))
	ok(GameContext.is_world_scene(GameContext.LEVEL02_PATH))
	ok(not GameContext.is_world_scene("res://scenes/ui/TitleScreen.tscn"))
	ok(ResourceLoader.exists(GameContext.LEVEL02_PATH), "Level02 scene exists on disk")
	eq(GameContext.route_scene(GameContext.LEVEL02_PATH), GameContext.PRESENTATION_PATH)
	eq(GameContext.pending_world_path, GameContext.LEVEL02_PATH, "routing remembers which level to load")
	eq(GameContext.route_scene(GameContext.WORLD_PATH), GameContext.PRESENTATION_PATH)
	eq(GameContext.pending_world_path, GameContext.WORLD_PATH)
	eq(GameContext.route_scene("res://scenes/ui/TitleScreen.tscn"), "res://scenes/ui/TitleScreen.tscn")
	eq(GameContext.pending_world_path, GameContext.WORLD_PATH, "non-level routes leave the pending level alone")


func test_level_ids_keep_level01_bare() -> void:
	eq(GameContext.level_id(GameContext.WORLD_PATH), "", "Level01 saves keep their legacy bare paths")
	eq(GameContext.level_id(GameContext.LEVEL02_PATH), "level02")
	eq(GameContext.level_id("res://nowhere.tscn"), "")


func _world(scene_path: String, world_name: String) -> Node2D:
	var world := Node2D.new()
	world.name = world_name
	world.scene_file_path = scene_path
	world.add_to_group("game_world")
	add_child(world)
	var props := Node2D.new()
	props.name = "Props"
	world.add_child(props)
	var thing := Node2D.new()
	thing.name = "EmberNest"
	props.add_child(thing)
	return world


func test_level02_save_paths_are_namespaced_and_do_not_cross_levels() -> void:
	var world2 := _world(GameContext.LEVEL02_PATH, "Level02_Undercroft")
	var nest2 := world2.get_node("Props/EmberNest")
	eq(SaveData.persist_path(nest2), "level02:Props/EmberNest", "level02 paths carry the level prefix")
	eq(SaveData.resolve_saved_node(world2, "level02:Props/EmberNest"), nest2)
	ok(SaveData.resolve_saved_node(world2, "Props/EmberNest") == null,
			"a bare Level01 path never resolves inside level02")
	SaveData.mark_consumed(String(nest2.get_path()))
	ok(SaveData.is_consumed("level02:Props/EmberNest"))
	ok(SaveData.consumed.has("level02:Props/EmberNest"), "stored form is the prefixed relative path")
	world2.free()
	var world1 := _world(GameContext.WORLD_PATH, "Level01_Static")
	var nest1 := world1.get_node("Props/EmberNest")
	eq(SaveData.persist_path(nest1), "Props/EmberNest", "Level01 stays bare")
	eq(SaveData.resolve_saved_node(world1, "Props/EmberNest"), nest1)
	ok(SaveData.resolve_saved_node(world1, "level02:Props/EmberNest") == null,
			"a level02 path never resolves inside Level01")
	ok(not SaveData.is_consumed(String(nest1.get_path())),
			"consuming level02's nest did not consume Level01's same-named nest")


func test_saved_scene_falls_back_to_level01_for_unknown_scenes() -> void:
	SaveData.data = {"meta": {"scene": GameContext.LEVEL02_PATH}}
	eq(SaveData.saved_scene(), GameContext.LEVEL02_PATH)
	SaveData.data = {"meta": {"scene": "res://scenes/levels/Deleted.tscn"}}
	eq(SaveData.saved_scene(), GameContext.WORLD_PATH)
	SaveData.data = {}
	eq(SaveData.saved_scene(), GameContext.WORLD_PATH)


func test_save_game_can_record_an_arrival_point_in_another_level() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	var previous_path := SaveData.save_path
	SaveData.save_path = "user://test_level_routing.cfg"
	var saved := SaveData.save_game(GameContext.LEVEL02_PATH, player, Level02Layout.ENTRY_SPAWN)
	ok(saved)
	eq(SaveData.data["meta"]["scene"], GameContext.LEVEL02_PATH)
	eq(SaveData.data["player"]["pos"], Level02Layout.ENTRY_SPAWN, "arrival point replaces the live position")
	ok(SaveData.load_game())
	eq(SaveData.saved_scene(), GameContext.LEVEL02_PATH, "continue would boot into level02")
	SaveData.delete_save()
	SaveData.save_path = previous_path
