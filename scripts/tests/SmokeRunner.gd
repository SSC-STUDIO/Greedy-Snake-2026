extends Node

const MAIN_MENU_SCENE := "res://scenes/menus/MainMenu.tscn"
const SETTINGS_SCENE := "res://scenes/menus/SettingsMenu.tscn"
const ABOUT_SCENE := "res://scenes/menus/AboutMenu.tscn"
const ARENA_SCENE := "res://scenes/game/Arena.tscn"
const UpgradeCatalogData := preload("res://scripts/data/UpgradeCatalog.gd")
const RunDataUtil := preload("res://scripts/data/RunData.gd")
const TerrainCatalogData := preload("res://scripts/data/TerrainCatalog.gd")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	SettingsStore.sound_on = false
	if not _run_data_smoke():
		get_tree().quit(1)
		return
	await _open_scene(MAIN_MENU_SCENE)
	await _open_scene(SETTINGS_SCENE)
	await _open_scene(ABOUT_SCENE)
	await _open_scene(ARENA_SCENE, 8)
	AudioBus.stop_bgm()
	await get_tree().process_frame
	await get_tree().physics_frame
	print("SMOKE_TEST_OK")
	get_tree().quit()

func _run_data_smoke() -> bool:
	var choices := UpgradeCatalogData.random_upgrade_choices([], 3)
	if choices.size() != 3:
		push_error("Expected three upgrade choices.")
		return false
	var ids := {}
	for choice in choices:
		var id := String(choice.get("id", ""))
		if id == "" or ids.has(id):
			push_error("Upgrade choices must be non-empty and unique.")
			return false
		ids[id] = true
	var seed_a := RunDataUtil.challenge_seed_for_date(2026, 4, 30)
	var seed_b := RunDataUtil.challenge_seed_for_date(2026, 4, 30)
	if seed_a != seed_b:
		push_error("Challenge seed must be stable for the same date.")
		return false
	if not _run_terrain_smoke():
		return false
	var snapshot := SettingsStore.get_snapshot()
	for key in ["bgm_volume", "sfx_volume", "minimap_size"]:
		if not snapshot.has(key):
			push_error("Missing settings key: %s" % key)
			return false
	return true

func _run_terrain_smoke() -> bool:
	var play_area := GameConfig.play_area_rect()
	var regions := TerrainCatalogData.terrain_regions(play_area)
	if regions.size() != 4:
		push_error("Expected four ecology terrain regions.")
		return false
	var expected_ids := {
		"bloom_nursery": false,
		"ion_marsh": false,
		"glass_reef": false,
		"ember_vein": false,
	}
	for sample in [
		play_area.position + play_area.size * Vector2(0.25, 0.25),
		play_area.position + play_area.size * Vector2(0.75, 0.25),
		play_area.position + play_area.size * Vector2(0.25, 0.75),
		play_area.position + play_area.size * Vector2(0.75, 0.75),
	]:
		var terrain := TerrainCatalogData.terrain_for_position(sample, play_area)
		var id := String(terrain.get("id", ""))
		if not expected_ids.has(id):
			push_error("Unexpected terrain id: %s" % id)
			return false
		expected_ids[id] = true
		if not terrain.has("food_weights"):
			push_error("Terrain is missing food weight modifiers.")
			return false
	for id in expected_ids.keys():
		if not bool(expected_ids[id]):
			push_error("Missing terrain coverage: %s" % id)
			return false
	return true

func _open_scene(scene_path: String, frames: int = 2) -> void:
	var packed: PackedScene = load(scene_path)
	var instance := packed.instantiate()
	add_child(instance)
	for i in range(frames):
		await get_tree().process_frame
		await get_tree().physics_frame
	instance.queue_free()
	packed = null
	await get_tree().process_frame
	await get_tree().process_frame
