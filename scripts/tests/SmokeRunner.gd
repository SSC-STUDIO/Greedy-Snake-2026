extends Node

const MAIN_MENU_SCENE := "res://scenes/menus/MainMenu.tscn"
const SETTINGS_SCENE := "res://scenes/menus/SettingsMenu.tscn"
const ABOUT_SCENE := "res://scenes/menus/AboutMenu.tscn"
const ARENA_SCENE := "res://scenes/game/Arena.tscn"
const UpgradeCatalogData := preload("res://scripts/data/UpgradeCatalog.gd")
const RunDataUtil := preload("res://scripts/data/RunData.gd")
const TerrainCatalogData := preload("res://scripts/data/TerrainCatalog.gd")
const TerrainHazardRendererData := preload("res://scripts/game/TerrainHazardRenderer.gd")
const WaveCatalogData := preload("res://scripts/data/WaveCatalog.gd")
const ForestAssetsData := preload("res://scripts/ui/ForestAssets.gd")
const REQUIRED_RUNTIME_ASSETS := [
	"res://assets/generated/neon_ecology/ai_textures/brand_head_ai.png",
	"res://assets/generated/neon_ecology/slices/player_head.png",
	"res://assets/generated/neon_ecology/slices/player_body.png",
	"res://assets/generated/neon_ecology/slices/snake_body_texture.png",
	"res://assets/generated/neon_ecology/slices/snake_body_ai_texture.png",
	"res://assets/generated/neon_ecology/slices/snake_body_elite_texture.png",
	"res://assets/generated/forest_25d/menu_background.png",
	"res://assets/generated/forest_25d/slices/forest_floor.png",
	"res://assets/generated/forest_25d/slices/dirt_path.png",
	"res://assets/generated/forest_25d/slices/dirt_path_patch.png",
	"res://assets/generated/forest_25d/slices/ground_height_overlay.png",
	"res://assets/generated/forest_25d/slices/tree_canopy.png",
	"res://assets/generated/forest_25d/slices/stump.png",
	"res://assets/generated/forest_25d/slices/rock.png",
	"res://assets/generated/forest_25d/slices/root_cluster.png",
	"res://assets/generated/forest_25d/slices/bush.png",
	"res://assets/generated/forest_25d/slices/fallen_log.png",
	"res://assets/generated/forest_25d/slices/foreground_branch.png",
	"res://assets/generated/forest_25d/slices/food_berry.png",
	"res://assets/generated/forest_25d/slices/leaf_shield_ring.png",
	"res://assets/generated/forest_25d/slices/spore_boost_puff.png",
	"res://assets/generated/obsidian_ui/menu_background.png",
	"res://assets/generated/obsidian_ui/settings_background.png",
	"res://assets/generated/obsidian_ui/about_background.png",
	"res://assets/generated/obsidian_ui/dialog_background.png",
	"res://assets/generated/obsidian_ui/panel_texture.png",
	"res://assets/generated/obsidian_ui/obsidian_noise_tile.png",
	"res://assets/fonts/NotoSansCJK-Regular.ttc",
	"res://scripts/systems/LocaleText.gd",
	"res://scripts/ui/UiTheme.gd",
	"res://scripts/ui/ObsidianUiAssets.gd",
	"res://scripts/data/WaveCatalog.gd",
	"res://scripts/game/TerrainHazardRenderer.gd",
	"res://scripts/ui/ForestAssets.gd",
]

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	SettingsStore.sound_on = false
	if not _run_data_smoke():
		get_tree().quit(1)
		return
	if not await _open_scene(MAIN_MENU_SCENE):
		return
	if not await _open_scene(SETTINGS_SCENE):
		return
	if not await _open_scene(ABOUT_SCENE):
		return
	if not await _open_scene(ARENA_SCENE, 8):
		return
	if not await _open_scene(ARENA_SCENE, 8, "_run_follower_damage_smoke"):
		return
	AudioBus.stop_bgm()
	print("SMOKE_TEST_OK")
	await _flush_release_frames(4)
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
	if not _run_wave_catalog_smoke():
		return false
	if not _run_runtime_asset_smoke():
		return false
	if not _run_locale_smoke():
		return false
	var snapshot := SettingsStore.get_snapshot()
	for key in ["bgm_volume", "sfx_volume", "minimap_size", "language"]:
		if not snapshot.has(key):
			push_error("Missing settings key: %s" % key)
			return false
	return true

func _run_locale_smoke() -> bool:
	var previous_language := SettingsStore.language
	SettingsStore.set_language("zh")
	if LocaleText.t("menu.start") != "开始下一局":
		push_error("Chinese menu translation failed.")
		SettingsStore.set_language(previous_language)
		return false
	var upgrade := UpgradeCatalogData.upgrade_by_id("feeder_drone")
	if LocaleText.translate_upgrade_name(upgrade) != "采食无人机":
		push_error("Chinese upgrade translation failed.")
		SettingsStore.set_language(previous_language)
		return false
	if LocaleText.translate_death_reason("Beam") != "光束":
		push_error("Chinese death reason translation failed.")
		SettingsStore.set_language(previous_language)
		return false
	if LocaleText.join_tags(["boost", "summon"]) != "加速, 召唤":
		push_error("Chinese tag translation failed.")
		SettingsStore.set_language(previous_language)
		return false
	SettingsStore.set_language("en")
	if LocaleText.translate_upgrade_name(upgrade) != "Feeder Drone":
		push_error("English upgrade translation failed.")
		SettingsStore.set_language(previous_language)
		return false
	SettingsStore.set_language(previous_language)
	return true

func _run_wave_catalog_smoke() -> bool:
	if WaveCatalogData.wave_count() != 10:
		push_error("Expected exactly 10 campaign waves.")
		return false
	var ids := {}
	for wave_index in range(1, WaveCatalogData.max_wave() + 1):
		var wave := WaveCatalogData.wave_for(wave_index)
		var id := String(wave.get("id", ""))
		var ability := String(wave.get("ability", ""))
		if id == "" or ability == "":
			push_error("Campaign wave is missing id or ability.")
			return false
		if ids.has(id):
			push_error("Campaign wave ids must be unique: %s" % id)
			return false
		ids[id] = true
	if not bool(WaveCatalogData.wave_for(WaveCatalogData.max_wave()).get("final", false)):
		push_error("Final campaign wave must be marked final.")
		return false
	return true

func _run_runtime_asset_smoke() -> bool:
	for asset_path in REQUIRED_RUNTIME_ASSETS:
		if not ResourceLoader.exists(asset_path):
			push_error("Missing required runtime asset: %s" % asset_path)
			return false
	return true

func _run_terrain_smoke() -> bool:
	var play_area := GameConfig.play_area_rect()
	var regions := TerrainCatalogData.terrain_regions(play_area)
	if regions.size() != 1:
		push_error("Expected one unified maze field.")
		return false
	var region: Dictionary = regions[0]
	if String(region.get("id", "")) != "containment_field":
		push_error("Unexpected terrain region id: %s" % String(region.get("id", "")))
		return false
	if region.get("rect", Rect2()) != play_area:
		push_error("Unified terrain must cover the full play area.")
		return false
	var hazard_renderer := TerrainHazardRendererData.new()
	hazard_renderer.generate_hazards(regions, play_area, 12345)
	if hazard_renderer.hazard_cells.size() < 400:
		push_error("Maze terrain must generate enough blocking wall cells.")
		return false
	if not hazard_renderer.get_blocking_cell_near_position(play_area.get_center(), 72.0).is_empty():
		push_error("Terrain hazards must leave the spawn center clear.")
		return false
	for sample in [
		play_area.position + play_area.size * Vector2(0.25, 0.25),
		play_area.position + play_area.size * Vector2(0.75, 0.25),
		play_area.position + play_area.size * Vector2(0.25, 0.75),
		play_area.position + play_area.size * Vector2(0.75, 0.75),
	]:
		var terrain := TerrainCatalogData.terrain_for_position(sample, play_area)
		var id := String(terrain.get("id", ""))
		if id != "containment_field":
			push_error("Unexpected terrain id: %s" % id)
			return false
		if not terrain.has("food_weights"):
			push_error("Terrain is missing food weight modifiers.")
			return false
	return true

func _open_scene(scene_path: String, frames: int = 2, arena_runner := "_run_campaign_progression_smoke") -> bool:
	var packed: PackedScene = load(scene_path)
	var instance := packed.instantiate()
	add_child(instance)
	for i in range(frames):
		await get_tree().process_frame
		await get_tree().physics_frame
	if scene_path == ARENA_SCENE:
		if not has_method(arena_runner):
			push_error("Missing arena smoke runner: %s" % arena_runner)
			get_tree().quit(1)
			return false
		var ok: bool = await call(arena_runner, instance)
		if not ok:
			get_tree().quit(1)
			return false
	instance.queue_free()
	packed = null
	await _flush_release_frames(4)
	return true

func _run_campaign_progression_smoke(instance: Node) -> bool:
	if not instance.has_method("debug_campaign_state") or not instance.has_method("debug_clear_current_wave"):
		push_error("Arena is missing campaign debug hooks.")
		return false
	var state: Dictionary = instance.debug_campaign_state()
	if int(state.get("wave", 0)) != 1:
		push_error("Campaign must start at wave 1.")
		return false
	if not await _run_drone_upgrade_smoke(instance):
		return false
	if not await _run_non_scoring_blast_smoke(instance):
		return false
	for wave_index in range(1, WaveCatalogData.max_wave()):
		if wave_index == 5 and not await _run_split_wave_combat_smoke(instance):
			return false
		instance.debug_clear_current_wave()
		await get_tree().process_frame
		await get_tree().physics_frame
		state = instance.debug_campaign_state()
		if int(state.get("wave", 0)) != wave_index + 1:
			push_error("Expected campaign wave %d, got %d." % [wave_index + 1, int(state.get("wave", 0))])
			return false
		if int(state.get("followers_recruited", 0)) != wave_index * 3:
			push_error("Expected %d recruited followers after wave clear, got %d." % [wave_index * 3, int(state.get("followers_recruited", 0))])
			return false
	instance.debug_clear_current_wave()
	await get_tree().process_frame
	state = instance.debug_campaign_state()
	if not bool(state.get("victory", false)):
		push_error("Final wave clear must trigger victory.")
		return false
	if String(state.get("title", "")) != "Snake Emperor":
		push_error("Victory title must be Snake Emperor.")
		return false
	return true

func _run_split_wave_combat_smoke(instance: Node) -> bool:
	var state: Dictionary = instance.debug_campaign_state()
	if int(state.get("wave", 0)) != 5:
		push_error("Expected to reach split wave for combat smoke.")
		return false
	if not instance.has_method("debug_wave_enemy_state") or not instance.has_method("debug_damage_wave_enemy"):
		push_error("Arena is missing combat debug hooks.")
		return false
	if not bool(instance.debug_damage_wave_enemy(0, 99, 0)):
		push_error("Failed to damage split-wave enemy.")
		return false
	await _flush_release_frames(2)
	var wave_enemies: Array = instance.debug_wave_enemy_state()
	if wave_enemies.size() <= 8:
		push_error("Split enemy death must spawn additional wave members before wave clear.")
		return false
	state = instance.debug_campaign_state()
	if int(state.get("wave", 0)) != 5:
		push_error("Split enemy death must not advance wave before followups resolve.")
		return false
	if int(state.get("remaining", 0)) <= 8:
		push_error("Remaining enemies should include spawned split fragments.")
		return false
	return true

func _run_drone_upgrade_smoke(instance: Node) -> bool:
	if not instance.has_method("debug_apply_upgrade"):
		push_error("Arena is missing upgrade debug hook.")
		return false
	var state: Dictionary = instance.debug_campaign_state()
	if int(state.get("drone_count", -1)) != 0:
		push_error("Campaign should start with zero drones.")
		return false
	if not bool(instance.debug_apply_upgrade("feeder_drone")):
		push_error("Failed to apply feeder_drone in smoke test.")
		return false
	state = instance.debug_campaign_state()
	if int(state.get("drone_count", 0)) != 1:
		push_error("feeder_drone must add one drone.")
		return false
	if not bool(instance.debug_apply_upgrade("nest_signal")):
		push_error("Failed to apply nest_signal in smoke test.")
		return false
	state = instance.debug_campaign_state()
	if int(state.get("drone_count", 0)) != 3:
		push_error("nest_signal must stack drone count to three total.")
		return false
	return true

func _run_non_scoring_blast_smoke(instance: Node) -> bool:
	if not instance.has_method("debug_area_blast_wave_enemy") or not instance.has_method("debug_wave_enemy_state"):
		push_error("Arena is missing non-scoring blast debug hooks.")
		return false
	if not bool(instance.debug_area_blast_wave_enemy(0, 99, false)):
		push_error("Failed to trigger a non-scoring blast in smoke test.")
		return false
	await _flush_release_frames(2)
	var wave_enemies: Array = instance.debug_wave_enemy_state()
	for enemy in wave_enemies:
		if bool(enemy.get("dying", false)) or bool(enemy.get("dead", false)):
			return true
	push_error("Non-scoring blast damage must still kill at least one wave enemy.")
	return false

func _run_follower_damage_smoke(instance: Node) -> bool:
	if not instance.has_method("debug_add_followers") or not instance.has_method("debug_damage_follower"):
		push_error("Arena is missing follower debug hooks.")
		return false
	if not bool(instance.debug_add_followers(2)):
		push_error("Failed to add followers in smoke test.")
		return false
	var state: Dictionary = instance.debug_campaign_state()
	if int(state.get("followers_total", 0)) != 2 or int(state.get("followers_alive", 0)) != 2:
		push_error("Adding followers must update alive/current counts.")
		return false
	if int(state.get("followers_recruited", 0)) != 2:
		push_error("Adding followers must update recruited count.")
		return false
	if not bool(instance.debug_damage_follower(0, 99)):
		push_error("Failed to damage follower in smoke test.")
		return false
	state = instance.debug_campaign_state()
	if int(state.get("followers_total", 0)) != 2:
		push_error("Follower removal should not happen until death dissolve completes.")
		return false
	if int(state.get("followers_alive", 0)) != 1:
		push_error("Follower death must immediately reduce alive pack members.")
		return false
	if int(state.get("followers_recruited", 0)) != 2:
		push_error("Follower death must not reduce recruited follower count.")
		return false
	if not await _wait_for_follower_total(instance, 1, 96):
		push_error("Follower death must eventually shrink the follower list.")
		return false
	state = instance.debug_campaign_state()
	if int(state.get("followers_alive", 0)) != 1:
		push_error("Follower death must leave one living pack member.")
		return false
	if int(state.get("followers_total", 0)) != 1:
		push_error("Follower death must eventually leave one current pack member.")
		return false
	if int(state.get("followers_recruited", 0)) != 2:
		push_error("Recruited follower count must remain historical after death.")
		return false
	return true

func _wait_for_follower_total(instance: Node, expected: int, max_frames: int) -> bool:
	for i in range(maxi(1, max_frames)):
		await get_tree().process_frame
		await get_tree().physics_frame
		var state: Dictionary = instance.debug_campaign_state()
		if int(state.get("followers_total", -1)) == expected:
			return true
	return false

func _flush_release_frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame
		await get_tree().physics_frame
