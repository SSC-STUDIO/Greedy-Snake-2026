extends Node2D

const GameConfigData := preload("res://scripts/data/GameConfig.gd")
const UpgradeCatalogData := preload("res://scripts/data/UpgradeCatalog.gd")
const RunDataUtil := preload("res://scripts/data/RunData.gd")
const TerrainCatalogData := preload("res://scripts/data/TerrainCatalog.gd")
const WaveCatalogData := preload("res://scripts/data/WaveCatalog.gd")
const TerrainHazardRendererData := preload("res://scripts/game/TerrainHazardRenderer.gd")
const UPGRADE_PICKER_SCRIPT := preload("res://scripts/ui/UpgradePicker.gd")
const NOISE_TILE_TEXTURE := preload("res://assets/generated/obsidian_ui/obsidian_noise_tile.png")
const HUD_SCENE := preload("res://scenes/ui/Hud.tscn")
const PAUSE_SCENE := preload("res://scenes/ui/PauseOverlay.tscn")
const GAME_OVER_SCENE := preload("res://scenes/ui/GameOverDialog.tscn")
const PLAYER_HEAD_TEXTURE := preload("res://assets/generated/neon_ecology/slices/player_head.png")
const PLAYER_BODY_TEXTURE := preload("res://assets/generated/neon_ecology/slices/snake_body_texture.png")
const AI_HEAD_TEXTURE := preload("res://assets/generated/neon_ecology/slices/ai_head.png")
const AI_BODY_TEXTURE := preload("res://assets/generated/neon_ecology/slices/snake_body_ai_texture.png")
const ELITE_HEAD_TEXTURE := preload("res://assets/generated/neon_ecology/slices/elite_head.png")
const ELITE_BODY_TEXTURE := preload("res://assets/generated/neon_ecology/slices/snake_body_elite_texture.png")
const FOOD_SEED_TEXTURE := preload("res://assets/generated/forest_25d/slices/food_berry.png")
const SHIELD_RING_TEXTURE := preload("res://assets/generated/forest_25d/slices/leaf_shield_ring.png")
const BOOST_PUFF_TEXTURE := preload("res://assets/generated/forest_25d/slices/spore_boost_puff.png")
const BODY_RENDER_ROTATION_OFFSET := PI * 0.5
const FOREST_FLOOR_TEXTURE := preload("res://assets/generated/forest_25d/slices/forest_floor.png")
const DIRT_PATH_PATCH_TEXTURE := preload("res://assets/generated/forest_25d/slices/dirt_path_patch.png")
const GROUND_HEIGHT_TEXTURE := preload("res://assets/generated/forest_25d/slices/ground_height_overlay.png")
const TREE_CANOPY_TEXTURE := preload("res://assets/generated/forest_25d/slices/tree_canopy.png")
const STUMP_TEXTURE := preload("res://assets/generated/forest_25d/slices/stump.png")
const ROCK_TEXTURE := preload("res://assets/generated/forest_25d/slices/rock.png")
const ROOT_CLUSTER_TEXTURE := preload("res://assets/generated/forest_25d/slices/root_cluster.png")
const BUSH_TEXTURE := preload("res://assets/generated/forest_25d/slices/bush.png")
const FALLEN_LOG_TEXTURE := preload("res://assets/generated/forest_25d/slices/fallen_log.png")
const FOREGROUND_BRANCH_TEXTURE := preload("res://assets/generated/forest_25d/slices/foreground_branch.png")
const MAX_VFX_PARTICLES := 260
const MAX_SHOCKWAVES := 18
const PARTICLE_POOL_SIZE := 300
const SHOCKWAVE_POOL_SIZE := 22
const LAVA_EDGE_WIDTH := 220.0
const FOREST_TILE_WORLD_SIZE := 1536.0
const FOREST_HEIGHT_TILE_WORLD_SIZE := 1536.0
const FOREST_PATH_TILE_WORLD_SIZE := 768.0
const VISIBLE_FOOD_MARGIN := 120.0
const FOOD_PULSE_TABLE_SIZE := 64
const LOW_PARTICLE_BUDGET := 56
const BALANCED_PARTICLE_BUDGET := 150
const LOW_SHOCKWAVE_BUDGET := 4
const BALANCED_SHOCKWAVE_BUDGET := 10
const LOW_FOOD_GLOW_LIMIT := 90
const BALANCED_FOOD_GLOW_LIMIT := 130
const FULL_FOOD_GLOW_LIMIT := 190
const AMBIENT_PARTICLE_LIMIT_RATIO := 0.82
const BASE_COMBO_WINDOW := 2.8
const UPGRADE_FOOD_THRESHOLDS := [14, 36, 68, 112, 166, 230, 304, 392]
const UPGRADE_TIME_THRESHOLDS := [18.0, 42.0, 74.0, 112.0, 156.0, 206.0, 262.0, 324.0]
const BASE_MAGNET_RADIUS := 34.0
const COMPANION_PICKUP_INTERVAL := 0.2
const AI_DEATH_DISSOLVE_TIME := 0.72
const PLAYER_LENGTH_RADIUS_STEP := 14
const PLAYER_LENGTH_RADIUS_MAX := 9.0
const FOLLOWERS_PER_WAVE := 3
const WAVE_REWARD_TIME := 2.1
const CORONATION_TIME := 3.4
const FRIENDLY_CONTACT_DAMAGE_COOLDOWN := 0.45
const AI_OBSTACLE_PROBE_DISTANCE := 170.0
const AI_FLANK_DISTANCE := 280.0
const AI_ROUTE_SAMPLE_STEP := 78.0
const AI_ROUTE_SAMPLE_COUNT := 5

class FoodDot:
	var position := Vector2.ZERO
	var radius := 4.0
	var color := Color.WHITE
	var kind := "energy"
	var name := "Energy"
	var score_value := 1
	var growth := 1
	var shield_time := 0.0
	var magnet_time := 0.0
	var explosion_radius := 0.0

	func _init(initial_position := Vector2.ZERO, initial_radius := 4.0, initial_color := Color.WHITE, definition := {}) -> void:
		position = initial_position
		radius = initial_radius
		color = initial_color
		if not definition.is_empty():
			kind = String(definition.get("id", kind))
			name = String(definition.get("name", name))
			score_value = int(definition.get("score", score_value))
			growth = int(definition.get("growth", growth))
			shield_time = float(definition.get("shield", 0.0))
			magnet_time = float(definition.get("magnet", 0.0))
			explosion_radius = float(definition.get("explosion", 0.0))

class SnakeAgent:
	var position := Vector2.ZERO
	var previous_position := Vector2.ZERO
	var direction := Vector2.DOWN
	var segments: Array = []
	var radius := GameConfigData.INITIAL_SNAKE_RADIUS
	var color := Color(0.12, 0.92, 0.46)
	var speed_multiplier := 1.0
	var aggression := 0.6
	var turn_timer := 0.0
	var dying := false
	var dead := false
	var death_timer := 0.0
	var drop_done := false
	var body_timer := 0.0
	var is_elite := false
	var is_boss := false
	var affixes: Array = []
	var health := 1
	var max_health := 1
	var score_value := 5
	var drop_value := 10
	var split_count := 0
	var death_explosion := 0.0
	var summon_count := 0
	var blink := false
	var phase_timer := 0.0
	var team := "enemy"
	var enemy_type := "hunter"
	var ability := "hunter"
	var follower_index := -1
	var attack_timer := 0.0
	var attack_phase := 0
	var attack_cooldown := 0.0
	var contact_cooldown := 0.0
	var shield_timer := 0.0
	var status_timer := 0.0
	var spawned_children := 0
	var wave_member := true
	var target_position := Vector2.ZERO
	var beam_direction := Vector2.DOWN

class VfxParticle:
	var position := Vector2.ZERO
	var velocity := Vector2.ZERO
	var color := Color.WHITE
	var radius := 4.0
	var lifetime := 0.4
	var age := 0.0
	var drag := 0.9

	func _init(initial_position := Vector2.ZERO, initial_velocity := Vector2.ZERO, initial_color := Color.WHITE, initial_radius := 4.0, initial_lifetime := 0.4, initial_drag := 0.9) -> void:
		position = initial_position
		velocity = initial_velocity
		color = initial_color
		radius = initial_radius
		lifetime = initial_lifetime
		drag = initial_drag

	func update(delta: float) -> void:
		age += delta
		position += velocity * delta
		velocity *= pow(drag, delta * 60.0)

	func alive() -> bool:
		return age < lifetime

	func progress() -> float:
		if lifetime <= 0.001:
			return 1.0
		return clampf(age / lifetime, 0.0, 1.0)

class Shockwave:
	var position := Vector2.ZERO
	var color := Color.WHITE
	var max_radius := 120.0
	var lifetime := 0.42
	var age := 0.0

	func _init(initial_position := Vector2.ZERO, initial_color := Color.WHITE, initial_max_radius := 120.0, initial_lifetime := 0.42) -> void:
		position = initial_position
		color = initial_color
		max_radius = initial_max_radius
		lifetime = initial_lifetime

	func update(delta: float) -> void:
		age += delta

	func alive() -> bool:
		return age < lifetime

	func progress() -> float:
		if lifetime <= 0.001:
			return 1.0
		return clampf(age / lifetime, 0.0, 1.0)

class HazardZone:
	var position := Vector2.ZERO
	var radius := 80.0
	var color := Color.WHITE
	var damage := 1
	var slow := 0.0
	var lifetime := 2.0
	var age := 0.0
	var team := "enemy"

	func _init(initial_position := Vector2.ZERO, initial_radius := 80.0, initial_color := Color.WHITE, initial_damage := 1, initial_lifetime := 2.0, initial_team := "enemy", initial_slow := 0.0) -> void:
		position = initial_position
		radius = initial_radius
		color = initial_color
		damage = initial_damage
		lifetime = initial_lifetime
		team = initial_team
		slow = initial_slow

	func update(delta: float) -> void:
		age += delta

	func alive() -> bool:
		return age < lifetime

	func progress() -> float:
		if lifetime <= 0.001:
			return 1.0
		return clampf(age / lifetime, 0.0, 1.0)

class BeamStrike:
	var origin := Vector2.ZERO
	var direction := Vector2.DOWN
	var color := Color.WHITE
	var width := 34.0
	var length := 720.0
	var damage := 1
	var warning_time := 0.7
	var active_time := 0.25
	var age := 0.0
	var fired := false
	var team := "enemy"

	func _init(initial_origin := Vector2.ZERO, initial_direction := Vector2.DOWN, initial_color := Color.WHITE, initial_team := "enemy", initial_damage := 1, initial_width := 34.0, initial_length := 720.0) -> void:
		origin = initial_origin
		direction = initial_direction.normalized() if initial_direction.length_squared() > 0.001 else Vector2.DOWN
		color = initial_color
		team = initial_team
		damage = initial_damage
		width = initial_width
		length = initial_length

	func update(delta: float) -> void:
		age += delta
		if age >= warning_time:
			fired = true

	func alive() -> bool:
		return age < warning_time + active_time

	func is_active() -> bool:
		return age >= warning_time and alive()

class FoodSpatialGrid:
	var cell_size := GameConfigData.FOOD_GRID_CELL_SIZE
	var origin := Vector2.ZERO
	var columns := 0
	var rows := 0
	var cells: Array = []
	var index_to_cell: Array = []

	func initialize(rect: Rect2) -> void:
		origin = rect.position
		columns = int(ceil(rect.size.x / float(cell_size))) + 1
		rows = int(ceil(rect.size.y / float(cell_size))) + 1
		cells.clear()
		cells.resize(columns * rows)
		for i in range(cells.size()):
			cells[i] = []
		index_to_cell.clear()

	func build(foods: Array) -> void:
		for cell in cells:
			cell.clear()
		index_to_cell.clear()
		index_to_cell.resize(foods.size())
		index_to_cell.fill(-1)
		for i in range(foods.size()):
			var food: FoodDot = foods[i]
			if food.radius <= 0.0:
				continue
			var cell_position := _cell_for(food.position)
			var cell_index := cell_position.y * columns + cell_position.x
			cells[cell_index].append(i)
			index_to_cell[i] = cell_index

	func query_rect(rect: Rect2) -> Array:
		var result: Array = []
		query_rect_into(rect, result)
		return result

	func query_rect_into(rect: Rect2, result: Array) -> void:
		result.clear()
		if columns <= 0 or rows <= 0:
			return
		var min_cell := _cell_for(rect.position)
		var max_cell := _cell_for(rect.position + rect.size)
		for y in range(min_cell.y, max_cell.y + 1):
			for x in range(min_cell.x, max_cell.x + 1):
				result.append_array(cells[y * columns + x])

	func upsert_index(foods: Array, index: int) -> void:
		if index < 0 or index >= foods.size() or columns <= 0 or rows <= 0:
			return
		if index_to_cell.size() < foods.size():
			var old_size := index_to_cell.size()
			index_to_cell.resize(foods.size())
			for i in range(old_size, index_to_cell.size()):
				index_to_cell[i] = -1

		var previous_cell := int(index_to_cell[index])
		if previous_cell >= 0 and previous_cell < cells.size():
			cells[previous_cell].erase(index)
		index_to_cell[index] = -1

		var food: FoodDot = foods[index]
		if food.radius <= 0.0:
			return
		var cell_position := _cell_for(food.position)
		var cell_index := cell_position.y * columns + cell_position.x
		cells[cell_index].append(index)
		index_to_cell[index] = cell_index

	func _cell_for(position: Vector2) -> Vector2i:
		var x := clampi(int(floor((position.x - origin.x) / float(cell_size))), 0, columns - 1)
		var y := clampi(int(floor((position.y - origin.y) / float(cell_size))), 0, rows - 1)
		return Vector2i(x, y)

var _camera: Camera2D
var _canvas: CanvasLayer
var _hud
var _pause_overlay
var _game_over_dialog
var _upgrade_picker: UpgradePicker
var _player := SnakeAgent.new()
var _ai_snakes: Array = []
var _follower_snakes: Array = []
var _foods: Array = []
var _food_grid := FoodSpatialGrid.new()
var _visible_food_indices: Array = []
var _visible_food_rect := Rect2()
var _visible_food_cache_valid := false
var _food_query_indices: Array = []
var _food_pulse_table: Array = []
var _hud_snapshot := {}
var _hud_ai_positions: Array = []
var _player_body_bounds := Rect2()
var _play_area := Rect2()
var _difficulty := {}
var _base_player_speed := 250.0
var _score := 0
var _food_eaten := 0
var _combo_count := 0
var _combo_timer := 0.0
var _max_combo := 0
var _magnet_timer := 0.0
var _dash_shockwave_timer := 0.0
var _companion_timer := 0.0
var _lava_timer := 0.0
var _invulnerability_timer := GameConfigData.COLLISION_GRACE_PERIOD
var _paused := false
var _game_over := false
var _mouse_control_enabled := true
var _target_direction := Vector2.DOWN
var _grid_offset := Vector2.ZERO
var _world_time := 0.0
var _particles: Array = []
var _shockwaves: Array = []
var _hazard_zones: Array = []
var _beam_strikes: Array = []
var _particle_pool: Array = []
var _shockwave_pool: Array = []
var _shake_timer := 0.0
var _shake_duration := 0.0
var _shake_strength := 0.0
var _boost_trail_timer := 0.0
var _ambient_particle_timer := 0.0
var _shield_particle_timer := 0.0
var _lava_spark_timer := 0.0
var _upgrade_choice_active := false
var _next_upgrade_index := 0
var _upgrade_choices: Array = []
var _owned_upgrade_ids: Array = []
var _owned_upgrades: Array = []
var _modifiers := RunDataUtil.new_modifier_state()
var _wave_state := RunDataUtil.new_wave_state()
var _run_stats := RunDataUtil.new_run_stats()
var _terrain_regions: Array = []
var _story_queue: Array = []
var _story_cooldowns := {}
var _seen_terrain_ids := {}
var _current_player_terrain_id := ""
# Terrain hazard system
var _terrain_hazard_renderer: TerrainHazardRenderer = null
var _hazard_damage_cooldown: float = 0.0
var _follower_serial := 0
var _victory_triggered := false

func _ready() -> void:
	randomize()
	_modifiers = RunDataUtil.new_modifier_state()
	_wave_state = RunDataUtil.new_wave_state()
	_run_stats = RunDataUtil.new_run_stats()
	_initialize_food_pulse_table()
	_preallocate_pools()
	AudioBus.play_bgm()
	_play_area = GameConfigData.play_area_rect()
	_terrain_regions = TerrainCatalogData.terrain_regions(_play_area)
	_difficulty = GameConfigData.difficulty(SettingsStore.difficulty)
	_base_player_speed = GameConfigData.player_speed_for(SettingsStore.snake_speed, SettingsStore.difficulty)
	_grid_offset = Vector2(randf_range(0.0, 240.0), randf_range(0.0, 240.0))

	# Initialize terrain hazard renderer
	_terrain_hazard_renderer = TerrainHazardRendererData.new()
	_terrain_hazard_renderer.generate_hazards(_terrain_regions, _play_area, randi())
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	_camera = Camera2D.new()
	_camera.name = "ArenaCamera"
	_camera.position = Vector2.ZERO
	_camera.enabled = true
	add_child(_camera)
	_camera.make_current()

	_canvas = CanvasLayer.new()
	_canvas.name = "UiLayer"
	add_child(_canvas)
	_hud = HUD_SCENE.instantiate()
	_canvas.add_child(_hud)
	_pause_overlay = PAUSE_SCENE.instantiate()
	_pause_overlay.hide()
	_pause_overlay.resume_requested.connect(func() -> void: _set_paused(false))
	_pause_overlay.restart_requested.connect(func() -> void: SceneRouter.restart_game())
	_pause_overlay.menu_requested.connect(func() -> void: SceneRouter.show_main_menu())
	_canvas.add_child(_pause_overlay)
	_game_over_dialog = GAME_OVER_SCENE.instantiate()
	_game_over_dialog.restart_requested.connect(func() -> void: SceneRouter.restart_game())
	_game_over_dialog.menu_requested.connect(func() -> void: SceneRouter.show_main_menu())
	_canvas.add_child(_game_over_dialog)
	_upgrade_picker = UPGRADE_PICKER_SCRIPT.new()
	_upgrade_picker.hide()
	_upgrade_picker.upgrade_selected.connect(_select_upgrade)
	_canvas.add_child(_upgrade_picker)

	_reset_player()
	_queue_story(LocaleText.t("story.start"), 3.2, "start", 999.0)
	_update_terrain_state()
	_spawn_foods()
	_start_campaign_wave(1)
	_update_hud()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				if _upgrade_choice_active:
					_upgrade_picker.choose_index(0)
			KEY_2:
				if _upgrade_choice_active:
					_upgrade_picker.choose_index(1)
			KEY_3:
				if _upgrade_choice_active:
					_upgrade_picker.choose_index(2)
			KEY_ESCAPE, KEY_P:
				if not _game_over and not _upgrade_choice_active:
					_set_paused(not _paused)
			KEY_R:
				if _game_over:
					SceneRouter.restart_game()
			KEY_UP, KEY_W:
				_set_keyboard_direction(Vector2.UP)
			KEY_DOWN, KEY_S:
				_set_keyboard_direction(Vector2.DOWN)
			KEY_LEFT, KEY_A:
				_set_keyboard_direction(Vector2.LEFT)
			KEY_RIGHT, KEY_D:
				_set_keyboard_direction(Vector2.RIGHT)
	elif event is InputEventMouseMotion:
		_mouse_control_enabled = true

## 主游戏循环，每物理帧调用一次。
##
## 负责更新所有游戏状态：玩家移动、AI行为、碰撞检测、
## 食物拾取、波次推进、视觉特效和摄像机跟踪。
## 当游戏暂停、结束或显示升级选择器时，仅更新HUD和渲染。
## 参数 delta: 自上一帧经过的时间（秒）。
func _physics_process(delta: float) -> void:
	if _paused or _game_over or _upgrade_choice_active:
		if _game_over:
			_update_effects(minf(delta, 0.1))
			_update_camera(minf(delta, 0.1))
		_update_hud()
		queue_redraw()
		return

	var clamped_delta := minf(delta, 0.1)
	_update_run_timers(clamped_delta)
	_update_wave(clamped_delta)
	if _game_over:
		_update_effects(clamped_delta)
		_update_camera(clamped_delta)
		_update_hud()
		queue_redraw()
		return
	_update_player(clamped_delta)
	_update_terrain_state()
	_update_ai(clamped_delta)
	_update_followers(clamped_delta)
	_update_companions(clamped_delta)
	_update_combat_zones(clamped_delta)
	_refresh_visible_food_cache(_visible_world_rect().grow(VISIBLE_FOOD_MARGIN))
	_update_magnet_pickups(clamped_delta)
	_check_food_collisions()
	_check_snake_collisions()
	_check_follower_collisions()
	_check_terrain_hazards(clamped_delta)
	_update_lava(clamped_delta)
	_update_particle_emitters(clamped_delta)
	_update_effects(clamped_delta)
	_update_camera(clamped_delta)
	_update_hud()
	queue_redraw()

func _draw() -> void:
	var visible := _visible_world_rect().grow(120.0)
	_refresh_visible_food_cache(visible)
	_draw_world(visible)
	_draw_hazard_zones()
	_draw_beam_strikes()
	_draw_shockwaves()
	_draw_food(visible)
	var snake_visible := visible.grow(260.0)
	for ai in _ai_snakes:
		if _is_snake_visible(ai, snake_visible):
			_draw_snake(ai, false)
	for follower in _follower_snakes:
		if _is_snake_visible(follower, snake_visible):
			_draw_snake(follower, false)
	_draw_snake(_player, true)
	_draw_particles()

func _reset_player() -> void:
	_player = SnakeAgent.new()
	_player.position = Vector2.ZERO
	_player.previous_position = _player.position
	_player.direction = Vector2.DOWN
	_player.color = Color(0.08, 0.86, 0.42)
	_update_player_radius()
	_player.segments.clear()
	for i in range(5):
		_player.segments.append(_player.position - Vector2.DOWN * GameConfigData.SNAKE_SEGMENT_SPACING * float(i + 1))
	_target_direction = _player.direction
	_camera.position = _player.position
	_ambient_particle_timer = 0.0
	_shield_particle_timer = 0.0
	_lava_spark_timer = 0.0
	_combo_count = 0
	_combo_timer = 0.0
	_max_combo = 0
	_magnet_timer = 0.0
	_dash_shockwave_timer = 0.0
	_companion_timer = 0.0
	_story_queue.clear()
	_story_cooldowns.clear()
	_seen_terrain_ids.clear()
	_current_player_terrain_id = ""
	_update_player_radius()

func _spawn_foods() -> void:
	_foods.clear()
	for i in range(GameConfigData.MAX_FOOD_COUNT):
		_foods.append(_make_food())
	_food_grid.initialize(_play_area)
	_food_grid.build(_foods)
	_visible_food_cache_valid = false

func _spawn_ai_snakes() -> void:
	_ai_snakes.clear()
	var ai_count := int(_difficulty.get("ai_count", 20))
	for i in range(ai_count):
		_ai_snakes.append(_make_ai_snake())

func _start_campaign_wave(wave: int) -> void:
	var definition := WaveCatalogData.wave_for(wave)
	_ai_snakes.clear()
	_hazard_zones.clear()
	_beam_strikes.clear()
	_wave_state["wave"] = wave
	_wave_state["phase"] = "fighting"
	_wave_state["wave_time"] = 0.0
	_wave_state["reward_timer"] = 0.0
	_wave_state["pressure"] = 1.0 + float(wave - 1) * 0.12
	_wave_state["enemy_type"] = String(definition.get("name", "Hunter"))
	_wave_state["title"] = String(definition.get("title", "Lone Snake"))
	_wave_state["remaining_enemies"] = int(definition.get("count", 0))
	_sync_follower_counters()
	_set_event(LocaleText.wave_event(wave, String(definition.get("event", "Wave %d" % wave))), 3.0)
	_queue_story(LocaleText.wave_story(wave, String(definition.get("story", LocaleText.terrain_wave_story(wave)))), 3.1, "campaign_wave_%d" % wave, 999.0)
	for i in range(int(definition.get("count", 1))):
		_ai_snakes.append(_make_campaign_enemy(definition, i))
	for follower in _follower_snakes:
		if follower.dead:
			continue
		follower.position = _player.position + Vector2.RIGHT.rotated(float(follower.follower_index) * 2.1) * (150.0 + float(follower.follower_index % 3) * 24.0)
		follower.previous_position = follower.position
		follower.direction = (_player.position - follower.position).normalized()
		_rebuild_segments(follower, follower.segments.size())

func _make_campaign_enemy(definition: Dictionary, index: int) -> SnakeAgent:
	var enemy := _make_ai_snake(_random_ai_spawn_position(), [], bool(definition.get("final", false)))
	enemy.enemy_type = String(definition.get("id", "hunter"))
	enemy.ability = String(definition.get("ability", enemy.enemy_type))
	enemy.team = "enemy"
	enemy.wave_member = true
	enemy.is_elite = int(_wave_state.get("wave", 1)) >= 5 or bool(definition.get("final", false))
	enemy.is_boss = bool(definition.get("final", false)) or enemy.ability == "devour"
	enemy.color = definition.get("color", enemy.color)
	enemy.speed_multiplier = float(definition.get("speed", enemy.speed_multiplier)) * randf_range(0.94, 1.06)
	enemy.aggression = float(definition.get("aggression", enemy.aggression))
	enemy.health = int(definition.get("health", enemy.health))
	enemy.max_health = enemy.health
	enemy.score_value = int(definition.get("score", 12 + int(_wave_state.get("wave", 1)) * 4))
	enemy.drop_value = int(definition.get("drop", 8 + int(_wave_state.get("wave", 1)) * 2))
	enemy.radius *= float(definition.get("radius", 1.0))
	enemy.attack_cooldown = randf_range(0.5, 2.6) + float(index % 3) * 0.28
	if enemy.ability == "split":
		enemy.split_count = 2
	elif enemy.ability == "summon":
		enemy.summon_count = 1
	elif enemy.ability == "mine":
		enemy.attack_cooldown = randf_range(1.2, 2.2)
	elif enemy.ability == "beam":
		enemy.attack_cooldown = randf_range(1.4, 2.5)
	elif enemy.ability == "emperor":
		enemy.split_count = 2
		enemy.summon_count = 2
		enemy.death_explosion = 300.0
		enemy.attack_cooldown = 0.8
	_rebuild_segments(enemy, enemy.segments.size() + int(definition.get("segments", 0)))
	return enemy

func _make_follower_snake(index: int) -> SnakeAgent:
	var follower := SnakeAgent.new()
	follower.team = "follower"
	follower.enemy_type = "follower"
	follower.ability = "follower"
	follower.follower_index = index
	follower.position = _player.position + Vector2.RIGHT.rotated(float(index) * 2.399) * (130.0 + float(index % 4) * 22.0)
	follower.previous_position = follower.position
	follower.direction = (_player.position - follower.position).normalized()
	follower.radius = GameConfigData.INITIAL_SNAKE_RADIUS * 0.72
	follower.color = Color(0.1, 0.95, 0.62).lerp(Color(0.38, 1.0, 0.95), float(index % 5) / 8.0)
	follower.speed_multiplier = 1.03 + float(index % 3) * 0.035
	follower.aggression = 0.95
	follower.health = 2
	follower.max_health = 2
	follower.score_value = 0
	follower.drop_value = 0
	_rebuild_segments(follower, 4)
	return follower

func _rebuild_segments(agent: SnakeAgent, count: int) -> void:
	agent.segments.clear()
	var safe_dir := agent.direction.normalized() if agent.direction.length_squared() > 0.001 else Vector2.DOWN
	for i in range(maxi(1, count)):
		agent.segments.append(agent.position - safe_dir * GameConfigData.SNAKE_SEGMENT_SPACING * float(i + 1))

func _make_food(position := Vector2.INF) -> FoodDot:
	var food_position := position
	if not food_position.is_finite():
		food_position = _random_position_in_play_area()
	var terrain := _terrain_for_position(food_position)
	var food_weights: Dictionary = terrain.get("food_weights", {})
	var definition := UpgradeCatalogData.random_food_type(float(_modifiers.get("special_food_chance", 0.0)), food_weights)
	var radius_range: Vector2 = definition.get("radius", Vector2(2.0, 7.0))
	var base_color: Color = definition.get("color", Color.WHITE)
	var color := base_color.lerp(Color.from_hsv(randf(), 0.85, 1.0), 0.18 if String(definition.get("id", "energy")) == "energy" else 0.06)
	return FoodDot.new(
		food_position,
		randf_range(radius_range.x, radius_range.y),
		color,
		definition
	)

func _make_ai_snake(position := Vector2.INF, affixes: Array = [], boss := false) -> SnakeAgent:
	var ai := SnakeAgent.new()
	ai.position = position if position.is_finite() else _random_ai_spawn_position()
	ai.previous_position = ai.position
	ai.direction = Vector2.RIGHT.rotated(randf_range(0.0, TAU)).normalized()
	ai.color = Color.from_hsv(randf(), 0.78, 0.94)
	ai.speed_multiplier = randf_range(GameConfigData.AI_MIN_SPEED_MULTIPLIER, GameConfigData.AI_MAX_SPEED_MULTIPLIER)
	ai.aggression = float(_difficulty.get("ai_aggression", 0.6))
	ai.is_elite = not affixes.is_empty()
	ai.is_boss = boss
	ai.affixes = affixes.duplicate(true)
	ai.score_value = 28 if ai.is_elite else 5
	if ai.is_boss:
		ai.radius = GameConfigData.INITIAL_SNAKE_RADIUS * 1.95
		ai.speed_multiplier = 0.66
		ai.aggression = 1.0
		ai.health = 7
		ai.max_health = 7
		ai.score_value = 120
		ai.color = Color(1.0, 0.34, 0.18)
	elif ai.is_elite:
		ai.color = Color(1.0, 0.34, 0.52)
		ai.health = 1
		ai.max_health = 1
		for affix in affixes:
			ai.color = ai.color.lerp(affix.get("color", ai.color), 0.42)
			ai.speed_multiplier += float(affix.get("speed", 0.0))
			ai.aggression += float(affix.get("aggression", 0.0))
			ai.radius *= float(affix.get("radius", 1.0))
			ai.health += int(affix.get("health", 0))
			ai.max_health = ai.health
			ai.split_count += int(affix.get("split", 0))
			ai.death_explosion = maxf(ai.death_explosion, float(affix.get("death_explosion", 0.0)))
			ai.summon_count += int(affix.get("summon", 0))
			ai.blink = ai.blink or bool(affix.get("blink", false))
	for i in range(5):
		ai.segments.append(ai.position - ai.direction * GameConfigData.SNAKE_SEGMENT_SPACING * float(i + 1))
	if ai.is_boss:
		for i in range(12):
			ai.segments.append(ai.position - ai.direction * GameConfigData.SNAKE_SEGMENT_SPACING * float(i + 6))
	elif ai.is_elite:
		for affix in affixes:
			for i in range(int(affix.get("segments", 0))):
				ai.segments.append(ai.position - ai.direction * GameConfigData.SNAKE_SEGMENT_SPACING * float(ai.segments.size() + 1))
	return ai

## 更新玩家蛇的位置与方向。
##
## 根据鼠标或键盘输入计算目标方向，平滑插值到该方向，
## 应用速度修正（地形、加速、升级加成），移动蛇头，
## 并驱动蛇身段跟随。同时递减无敌时间。
## 加速状态下生成尾迹粒子，并可能触发冲刺冲击波。
## 参数 delta: 自上一帧经过的时间（秒）。
func _update_player(delta: float) -> void:
	_player.previous_position = _player.position
	if _mouse_control_enabled:
		var mouse_direction := get_global_mouse_position() - _player.position
		if mouse_direction.length_squared() > 64.0:
			_target_direction = mouse_direction.normalized()

	var desired_direction := _target_direction.normalized()
	if desired_direction.length_squared() > 0.001:
		_player.direction = _smooth_direction(_player.direction, desired_direction, 0.22 + float(_modifiers.get("turn_response", 0.0)))

	var speed := _base_player_speed * (1.0 + float(_modifiers.get("speed_mult", 0.0))) * _terrain_speed_multiplier(_player.position)
	if _is_boosting():
		speed *= GameConfigData.BOOST_MULTIPLIER + float(_modifiers.get("boost_mult", 0.0))
		_boost_trail_timer -= delta
		if _boost_trail_timer <= 0.0:
			_spawn_boost_trail()
			_boost_trail_timer = 0.028 if SettingsStore.animations_on else 0.075
		if int(_modifiers.get("dash_shockwave", 0)) > 0:
			_dash_shockwave_timer -= delta
			if _dash_shockwave_timer <= 0.0:
				_area_blast(_player.position, 120.0 + float(_modifiers.get("explosion_radius", 0.0)), 1, Color(0.58, 1.0, 0.52), false)
				_dash_shockwave_timer = 2.2
	else:
		_boost_trail_timer = 0.0
		_dash_shockwave_timer = minf(_dash_shockwave_timer, 0.35)
	_player.position += _player.direction * speed * delta
	_resolve_blocking_hazard(_player)
	_follow_segments(_player)

	if _invulnerability_timer > 0.0:
		_invulnerability_timer = maxf(0.0, _invulnerability_timer - delta)

## 更新所有AI蛇的行为与移动。
##
## 遍历AI列表，移除已死亡个体，处理正在死亡中的个体。
## 存活的AI根据与玩家的距离调整转向频率：远离玩家时降低
## 决策频率以节省性能。根据侵略度概率朝玩家方向转向，
## 同时执行墙壁回避。Boss型AI有周期性冲锋阶段。
## 远离视野的AI降低蛇身跟随频率。
## 超出竞技场边界的AI立即死亡。
## 参数 delta: 自上一帧经过的时间（秒）。
func _update_ai(delta: float) -> void:
	var active_view := _visible_world_rect().grow(420.0)
	var i := 0
	while i < _ai_snakes.size():
		var ai: SnakeAgent = _ai_snakes[i]
		if ai.dead:
			_ai_snakes.remove_at(i)
			continue
		if ai.dying:
			_update_ai_death(ai, delta)
			i += 1
			continue

		ai.previous_position = ai.position
		_update_enemy_ability(ai, delta)
		var target_position := _enemy_target_position(ai)
		var to_player: Vector2 = target_position - ai.position
		var distance_squared := to_player.length_squared()
		var near_player := distance_squared <= 900.0 * 900.0
		var far_offscreen := distance_squared > 2200.0 * 2200.0 and not active_view.has_point(ai.position)
		var turn_interval := GameConfigData.AI_DIRECTION_CHANGE_TIME
		if far_offscreen:
			turn_interval *= 2.15
		elif not near_player and not active_view.has_point(ai.position):
			turn_interval *= 1.45

		ai.turn_timer += delta
		if ai.turn_timer >= turn_interval:
			ai.turn_timer = 0.0
			var target: Vector2 = _choose_ai_direction(ai, target_position, distance_squared, near_player)
			ai.direction = _smooth_direction(ai.direction, target, 0.22 + ai.aggression * 0.08)

		var pressure := float(_wave_state.get("pressure", 1.0))
		var ability_speed_bonus := 0.0
		if ai.status_timer > 0.0:
			ai.status_timer = maxf(0.0, ai.status_timer - delta)
			ability_speed_bonus = 0.75
		if ai.is_boss:
			ai.phase_timer += delta
			if ai.phase_timer >= 5.5:
				ai.phase_timer = 0.0
				ai.direction = (_player.position - ai.position).normalized()
				_spawn_warning_ring(ai.position, Color(1.0, 0.32, 0.14))
			elif ai.phase_timer < 0.55:
				pressure += 0.75
		var speed: float = _base_player_speed * (ai.speed_multiplier + ability_speed_bonus) * pressure * _terrain_speed_multiplier(ai.position)
		ai.position += ai.direction * speed * delta
		_resolve_blocking_hazard(ai)
		var body_interval := 0.0
		if far_offscreen:
			body_interval = 0.085
		elif not near_player and not active_view.has_point(ai.position):
			body_interval = 0.045
		ai.body_timer += delta
		if body_interval <= 0.0 or ai.body_timer >= body_interval:
			_follow_segments(ai)
			ai.body_timer = 0.0
		if not _is_circle_inside_play_area(ai.position, ai.radius):
			_start_ai_death(ai, 10, false)
		i += 1

func _enemy_target_position(ai: SnakeAgent) -> Vector2:
	var target := _player.position
	var best_distance := ai.position.distance_squared_to(target)
	for follower in _follower_snakes:
		if follower.dead or follower.dying:
			continue
		var distance := ai.position.distance_squared_to(follower.position)
		if distance < best_distance * 0.82:
			best_distance = distance
			target = follower.position
	return target

func _choose_ai_direction(ai: SnakeAgent, target_position: Vector2, distance_squared: float, near_player: bool) -> Vector2:
	var to_target := target_position - ai.position
	var direct := to_target.normalized() if to_target.length_squared() > 0.001 else ai.direction
	var target := direct
	if distance_squared > 100.0 * 100.0:
		var flank_weight := clampf(ai.aggression * (0.34 if near_player else 0.18), 0.0, 0.42)
		var hash_cell := Vector2i(floori(ai.position.x / 64.0), floori(ai.position.y / 64.0))
		var side_sign := -1.0 if _cell_hash_int(hash_cell, 2) == 0 else 1.0
		var flank_target := target_position + direct.orthogonal() * AI_FLANK_DISTANCE * side_sign
		target = direct.lerp((flank_target - ai.position).normalized(), flank_weight).normalized()
	elif randf() < 0.4:
		target = ai.direction.rotated(randf_range(-PI / 4.0, PI / 4.0)).normalized()
	var candidates := _ai_direction_candidates(ai.direction, target, direct)
	return _best_ai_route_direction(ai, target_position, candidates, near_player)

func _ai_direction_candidates(current: Vector2, target: Vector2, direct: Vector2) -> Array:
	var safe_current := current.normalized() if current.length_squared() > 0.001 else Vector2.DOWN
	var safe_target := target.normalized() if target.length_squared() > 0.001 else safe_current
	var safe_direct := direct.normalized() if direct.length_squared() > 0.001 else safe_target
	return [
		safe_target,
		safe_direct,
		safe_current,
		safe_target.rotated(0.36),
		safe_target.rotated(-0.36),
		safe_target.rotated(0.72),
		safe_target.rotated(-0.72),
		safe_current.rotated(0.52),
		safe_current.rotated(-0.52),
		safe_direct.orthogonal(),
		-safe_direct.orthogonal(),
	]

func _best_ai_route_direction(ai: SnakeAgent, target_position: Vector2, candidates: Array, near_player: bool) -> Vector2:
	var best_direction := ai.direction.normalized() if ai.direction.length_squared() > 0.001 else Vector2.DOWN
	var best_score := -INF
	for candidate in candidates:
		var direction: Vector2 = candidate
		if direction.length_squared() <= 0.001:
			continue
		direction = direction.normalized()
		var score := _score_ai_route(ai, direction, target_position, near_player)
		if score > best_score:
			best_score = score
			best_direction = direction
	return _wall_avoidance_direction(ai.position, best_direction).normalized()

func _score_ai_route(ai: SnakeAgent, direction: Vector2, target_position: Vector2, near_player: bool) -> float:
	var safe_radius := ai.radius * 1.2
	var score := 0.0
	var origin_distance := ai.position.distance_to(target_position)
	var current_direction := ai.direction.normalized() if ai.direction.length_squared() > 0.001 else direction
	score += direction.dot(current_direction) * 42.0
	score += direction.dot((target_position - ai.position).normalized()) * (80.0 + ai.aggression * 60.0)
	for step in range(1, AI_ROUTE_SAMPLE_COUNT + 1):
		var distance := AI_ROUTE_SAMPLE_STEP * float(step)
		var sample := ai.position + direction * distance
		var sample_weight := float(AI_ROUTE_SAMPLE_COUNT - step + 1)
		if not _is_circle_inside_play_area(sample, safe_radius):
			score -= 260.0 * sample_weight
			continue
		if _terrain_hazard_renderer != null and not _terrain_hazard_renderer.get_blocking_cell_near_position(sample, safe_radius).is_empty():
			score -= 340.0 * sample_weight
			continue
		score += sample_weight * 18.0
		score += (origin_distance - sample.distance_to(target_position)) * (0.18 if near_player else 0.12)
		for zone in _hazard_zones:
			if zone.team == "enemy":
				continue
			if sample.distance_squared_to(zone.position) <= pow(zone.radius + safe_radius, 2.0):
				score -= 90.0 * sample_weight
	for beam in _beam_strikes:
		if beam.team != "enemy" and _point_in_beam(ai.position + direction * AI_ROUTE_SAMPLE_STEP, safe_radius, beam):
			score -= 160.0
	return score

func _update_enemy_ability(ai: SnakeAgent, delta: float) -> void:
	ai.attack_timer += delta
	ai.attack_cooldown = maxf(0.0, ai.attack_cooldown - delta)
	ai.contact_cooldown = maxf(0.0, ai.contact_cooldown - delta)
	ai.shield_timer = maxf(0.0, ai.shield_timer - delta)
	if ai.attack_cooldown > 0.0:
		return
	match ai.ability:
		"dash":
			_enemy_dash(ai)
			ai.attack_cooldown = randf_range(3.0, 4.6)
		"shield":
			ai.shield_timer = 1.45
			_spawn_warning_ring(ai.position, ai.color.lightened(0.28))
			ai.attack_cooldown = randf_range(4.2, 5.8)
		"venom":
			_spawn_hazard_zone(ai.position, 96.0, ai.color, 1, 3.2, "enemy", 0.35)
			ai.attack_cooldown = randf_range(2.3, 3.5)
		"mine":
			_spawn_hazard_zone(ai.position - ai.direction.normalized() * 70.0, 62.0, ai.color, 1, 6.0, "enemy")
			ai.attack_cooldown = randf_range(2.0, 3.0)
		"beam":
			_spawn_beam(ai, 1)
			ai.attack_cooldown = randf_range(3.4, 5.2)
		"devour":
			_enemy_devour(ai)
			ai.attack_cooldown = randf_range(2.2, 3.4)
		"emperor":
			_enemy_emperor_attack(ai)
			ai.attack_cooldown = randf_range(1.35, 2.35)
		_:
			pass

func _enemy_dash(ai: SnakeAgent) -> void:
	var target := _enemy_target_position(ai)
	var direction := (target - ai.position).normalized()
	if direction.length_squared() <= 0.001:
		direction = ai.direction
	ai.direction = direction
	ai.phase_timer = 0.0
	ai.status_timer = 0.55
	_spawn_warning_ring(ai.position, Color(0.45, 0.8, 1.0))
	_add_particle(_get_particle(ai.position, -direction * 80.0, ai.color.lightened(0.24), 6.0, 0.34, 0.82))

func _enemy_devour(ai: SnakeAgent) -> void:
	var best_index := -1
	var best_distance := INF
	var query := Rect2(ai.position - Vector2(260.0, 260.0), Vector2(520.0, 520.0))
	for index in _food_indices_for_rect(query):
		var food: FoodDot = _foods[index]
		if food.radius <= 0.0:
			continue
		var distance := ai.position.distance_squared_to(food.position)
		if distance < best_distance:
			best_distance = distance
			best_index = index
	if best_index >= 0:
		_foods[best_index] = _make_food()
		_food_grid.upsert_index(_foods, best_index)
		ai.health = mini(ai.max_health, ai.health + 1)
		ai.speed_multiplier += 0.05
		_spawn_warning_ring(ai.position, Color(1.0, 0.38, 0.58))

func _enemy_emperor_attack(ai: SnakeAgent) -> void:
	var phase := ai.attack_phase % 4
	ai.attack_phase += 1
	match phase:
		0:
			_enemy_dash(ai)
		1:
			_spawn_beam(ai, 2)
		2:
			_spawn_hazard_zone(ai.position, 130.0, Color(0.36, 1.0, 0.24), 1, 3.4, "enemy", 0.4)
		_:
			if ai.spawned_children < 8:
				ai.spawned_children += 1
				var definition := WaveCatalogData.wave_for(6)
				var summon := _make_campaign_enemy(definition, ai.spawned_children)
				summon.position = ai.position + Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * 180.0
				summon.wave_member = true
				_ai_snakes.append(summon)
				_spawn_warning_ring(summon.position, summon.color)

func _spawn_beam(ai: SnakeAgent, damage: int) -> void:
	var target := _enemy_target_position(ai)
	var direction := (target - ai.position).normalized()
	if direction.length_squared() <= 0.001:
		direction = ai.direction
	_beam_strikes.append(BeamStrike.new(ai.position, direction, ai.color.lightened(0.2), "enemy", damage, 34.0 + float(damage) * 8.0, 920.0))
	_spawn_warning_ring(ai.position, ai.color)

func _update_followers(delta: float) -> void:
	var i := 0
	while i < _follower_snakes.size():
		var follower: SnakeAgent = _follower_snakes[i]
		if follower.dead:
			_follower_snakes.remove_at(i)
			continue
		if follower.dying:
			_update_ai_death(follower, delta)
			i += 1
			continue
		follower.previous_position = follower.position
		follower.contact_cooldown = maxf(0.0, follower.contact_cooldown - delta)
		var target := _nearest_enemy_position(follower.position)
		if target == Vector2.INF:
			target = _player.position + Vector2.RIGHT.rotated(_world_time * 0.9 + float(follower.follower_index) * 2.399) * (130.0 + float(follower.follower_index % 4) * 28.0)
		var desired := (target - follower.position).normalized()
		if desired.length_squared() <= 0.001:
			desired = follower.direction
		follower.direction = _smooth_direction(follower.direction, _wall_avoidance_direction(follower.position, desired), 0.24)
		var speed := _base_player_speed * follower.speed_multiplier * (1.0 + float(_wave_state.get("wave", 1)) * 0.018)
		follower.position += follower.direction * speed * delta
		_resolve_blocking_hazard(follower)
		_follow_segments(follower)
		if not _is_circle_inside_play_area(follower.position, follower.radius):
			follower.position = follower.position.lerp(_player.position, 0.08)
		_update_follower_pickup(follower)
		i += 1

func _nearest_enemy_position(from: Vector2) -> Vector2:
	var target := Vector2.INF
	var best_distance := INF
	for enemy in _ai_snakes:
		if enemy.dead or enemy.dying:
			continue
		var distance := from.distance_squared_to(enemy.position)
		if distance < best_distance:
			best_distance = distance
			target = enemy.position
	return target

func _update_follower_pickup(follower: SnakeAgent) -> void:
	if int(_world_time * 10.0 + follower.follower_index) % 3 != 0:
		return
	var pickup_radius := 54.0 + float(_modifiers.get("magnet_radius", 0.0)) * 0.18
	var query := Rect2(follower.position - Vector2(pickup_radius, pickup_radius), Vector2(pickup_radius * 2.0, pickup_radius * 2.0))
	var best_index := -1
	var best_distance := INF
	for index in _food_indices_for_rect(query):
		var food: FoodDot = _foods[index]
		if food.radius <= 0.0:
			continue
		var distance := follower.position.distance_squared_to(food.position)
		if distance < best_distance:
			best_distance = distance
			best_index = index
	if best_index >= 0:
		_consume_food(best_index, false)
		_foods[best_index] = _make_food()
		_food_grid.upsert_index(_foods, best_index)

func _update_ai_death(ai: SnakeAgent, delta: float) -> void:
	ai.death_timer += delta
	if not ai.drop_done:
		if ai.team == "enemy":
			_drop_food_for_snake(ai, ai.drop_value)
			_spawn_death_followups(ai)
		ai.drop_done = true
	ai.body_timer -= delta
	if ai.body_timer <= 0.0:
		_spawn_snake_dissolve_sparks(ai)
		ai.body_timer = 0.055 if SettingsStore.animations_on else 0.16
	if ai.death_timer >= AI_DEATH_DISSOLVE_TIME:
		ai.dead = true

## 检测玩家与食物的碰撞并处理拾取。
##
## 使用空间网格加速查询，在玩家拾取半径内搜索可接触的食物。
## 匹配到的食物调用 _consume_food 处理计分与效果，
## 然后在该位置重新生成一个新食物并更新空间网格。
## 如果吃到了食物则播放音效并刷新可见食物缓存。
func _check_food_collisions() -> void:
	var search_radius := _player.radius + 12.0 + float(_modifiers.get("pickup_radius", 0.0))
	var query := Rect2(_player.position - Vector2(search_radius, search_radius), Vector2(search_radius * 2.0, search_radius * 2.0))
	var eaten := false
	for index in _food_indices_for_rect(query):
		var food: FoodDot = _foods[index]
		if food.radius <= 0.0:
			continue
		var eat_radius := _player.radius + food.radius + float(_modifiers.get("pickup_radius", 0.0))
		if _player.position.distance_squared_to(food.position) <= eat_radius * eat_radius:
			_consume_food(index, true)
			_foods[index] = _make_food()
			_food_grid.upsert_index(_foods, index)
			eaten = true
	if eaten:
		AudioBus.play_eat()
		_visible_food_cache_valid = false

## 检测玩家与AI蛇的碰撞。
##
## 分三层检测：(1)玩家头与AI头、(2)玩家头与AI蛇身、
## (3)AI头与玩家蛇身。先通过AABB包围盒粗筛减少计算量。
## 碰撞后调用 _resolve_player_enemy_contact 处理结果，
## 无敌或加速状态下伤害敌人，否则触发游戏结束。
## 任一碰撞导致游戏结束后立即返回，跳过后续检测。
func _check_snake_collisions() -> void:
	_refresh_player_body_bounds()
	var player_body_radius: float = _collision_body_radius(_player)
	var has_player_body := not _player.segments.is_empty()
	for ai in _ai_snakes:
		if ai.dead or ai.dying:
			continue
		if _circles_overlap(_player.position, _player.radius, ai.position, ai.radius):
			if not _resolve_player_enemy_contact(ai):
				return

		for segment_index in range(ai.segments.size()):
			var segment: Vector2 = ai.segments[segment_index]
			var ai_body_radius: float = _collision_body_radius(ai, float(segment_index + 1) / float(ai.segments.size() + 1))
			if _circles_overlap(_player.position, _player.radius, segment, ai_body_radius):
				if not _resolve_player_enemy_contact(ai):
					return

		if has_player_body and _player_body_bounds.grow(ai.radius + player_body_radius).has_point(ai.position):
			for player_index in range(_player.segments.size()):
				var player_segment: Vector2 = _player.segments[player_index]
				var current_player_body_radius: float = _collision_body_radius(_player, float(player_index + 1) / float(_player.segments.size() + 1))
				if _circles_overlap(ai.position, ai.radius, player_segment, current_player_body_radius):
					if not _resolve_player_enemy_contact(ai):
						return
					break

func _check_follower_collisions() -> void:
	for follower in _follower_snakes:
		if follower.dead or follower.dying:
			continue
		for enemy in _ai_snakes:
			if enemy.dead or enemy.dying:
				continue
			if _circles_overlap(follower.position, follower.radius, enemy.position, enemy.radius):
				if follower.contact_cooldown <= 0.0:
					follower.contact_cooldown = FRIENDLY_CONTACT_DAMAGE_COOLDOWN
					_damage_enemy(enemy, 1, 8)
					_spawn_warning_ring(enemy.position, follower.color)
				if enemy.contact_cooldown <= 0.0:
					enemy.contact_cooldown = FRIENDLY_CONTACT_DAMAGE_COOLDOWN
					_damage_follower(follower, 1, enemy.color)
			for segment_index in range(enemy.segments.size()):
				var segment: Vector2 = enemy.segments[segment_index]
				var enemy_radius := _collision_body_radius(enemy, float(segment_index + 1) / float(enemy.segments.size() + 1))
				if _circles_overlap(follower.position, follower.radius, segment, enemy_radius):
					if enemy.contact_cooldown <= 0.0:
						enemy.contact_cooldown = FRIENDLY_CONTACT_DAMAGE_COOLDOWN
						_damage_follower(follower, 1, enemy.color)
					break

func _damage_follower(follower: SnakeAgent, damage: int, color: Color) -> void:
	if follower.dead or follower.dying:
		return
	follower.health -= maxi(1, damage)
	_spawn_warning_ring(follower.position, color)
	if follower.health <= 0:
		_start_ai_death(follower, 0, false)
		_set_event(LocaleText.t("event.follower_lost"), 1.4)

func _update_lava(delta: float) -> void:
	if _invulnerability_timer > 0.0:
		_lava_timer = 0.0
		return

	if _is_circle_inside_play_area(_player.position, _player.radius):
		_lava_timer = 0.0
		return

	if int(_modifiers.get("edge_shield", 0)) > 0 and int(_wave_state.get("edge_shield_wave", -1)) != int(_wave_state.get("wave", 1)):
		_wave_state["edge_shield_wave"] = int(_wave_state.get("wave", 1))
		_invulnerability_timer = maxf(_invulnerability_timer, 2.5 + float(_modifiers.get("shield_bonus", 0.0)))
		_set_event(LocaleText.t("event.emergency_shield"))
		_spawn_warning_ring(_player.position, Color(0.62, 1.0, 0.96))

	_lava_timer += delta
	_start_screen_shake(1.4 + _lava_timer * 0.35, 0.08)
	_spawn_lava_warning_sparks(delta)
	if _lava_timer >= float(_difficulty.get("lava_warning_time", 5.0)):
		_trigger_game_over("Lava")

## Check terrain hazards (thorn roots, mud slows, and blocking trunks).
func _check_terrain_hazards(delta: float) -> void:
	if _terrain_hazard_renderer == null or _invulnerability_timer > 0.0:
		return

	# Update cooldown
	if _hazard_damage_cooldown > 0.0:
		_hazard_damage_cooldown -= delta
		return

	var hazard: Dictionary = _terrain_hazard_renderer.get_hazard_at_position(_player.position)
	if hazard.is_empty():
		return

	var hazard_type: String = hazard.get("hazard_type", "none")
	match hazard_type:
		"damage":
			# Thorn or toxic ground damage.
			var damage: int = int(hazard.get("hazard_damage", 1))
			_spawn_damage_particles(_player.position, 5 + damage * 2)
			_start_screen_shake(1.6 + float(damage) * 0.5, 0.1)
			# For now, damage triggers invulnerability and visual feedback
			_invulnerability_timer = 0.5
			_hazard_damage_cooldown = 1.0
			_set_event(LocaleText.t("event.thorn_strike"))
		"slow":
			# Mud slows are handled in speed calculation via terrain_speed_multiplier.
			pass
		"block":
			_resolve_blocking_hazard(_player, true)
			_hazard_damage_cooldown = 0.3

func _update_combat_zones(delta: float) -> void:
	for i in range(_hazard_zones.size() - 1, -1, -1):
		var zone: HazardZone = _hazard_zones[i]
		zone.update(delta)
		if not zone.alive():
			_hazard_zones.remove_at(i)
			continue
		_apply_hazard_zone(zone)
		if _game_over:
			return
	for i in range(_beam_strikes.size() - 1, -1, -1):
		var beam: BeamStrike = _beam_strikes[i]
		var was_active := beam.is_active()
		beam.update(delta)
		if beam.is_active() and not was_active:
			_apply_beam_strike(beam)
			if _game_over:
				return
			_add_shockwave(_get_shockwave(beam.origin + beam.direction * minf(beam.length * 0.3, 260.0), beam.color, 130.0, 0.24))
		if not beam.alive():
			_beam_strikes.remove_at(i)

func _spawn_hazard_zone(position: Vector2, radius: float, color: Color, damage: int, lifetime: float, team := "enemy", slow := 0.0) -> void:
	_hazard_zones.append(HazardZone.new(position, radius, color, damage, lifetime, team, slow))
	_add_shockwave(_get_shockwave(position, color.lightened(0.16), radius, 0.34))

func _apply_hazard_zone(zone: HazardZone) -> void:
	if zone.team == "enemy":
		if _player.position.distance_squared_to(zone.position) <= pow(zone.radius + _player.radius, 2.0):
			if _hazard_damage_cooldown <= 0.0 and _invulnerability_timer <= 0.0:
				_hazard_damage_cooldown = 0.65
				if zone.damage > 0 and not _try_revive(LocaleText.t("event.revive_toxic_guard")):
					_trigger_game_over("Venom")
					return
			if zone.slow > 0.0:
				_player.direction = _smooth_direction(_player.direction, -(_player.position - zone.position).normalized(), zone.slow * 0.08)
		for follower in _follower_snakes:
			if follower.dead or follower.dying:
				continue
			if follower.position.distance_squared_to(zone.position) <= pow(zone.radius + follower.radius, 2.0) and follower.contact_cooldown <= 0.0:
				follower.contact_cooldown = 0.65
				_damage_follower(follower, zone.damage, zone.color)
	else:
		for enemy in _ai_snakes:
			if enemy.dead or enemy.dying:
				continue
			if enemy.position.distance_squared_to(zone.position) <= pow(zone.radius + enemy.radius, 2.0):
				_damage_enemy(enemy, zone.damage, 8)

func _apply_beam_strike(beam: BeamStrike) -> void:
	if beam.team == "enemy":
		if _point_in_beam(_player.position, _player.radius, beam):
			if _invulnerability_timer > 0.0 or _try_revive(LocaleText.t("event.revive_beam_guard")):
				pass
			else:
				_trigger_game_over("Beam")
				return
		for follower in _follower_snakes:
			if follower.dead or follower.dying:
				continue
			if _point_in_beam(follower.position, follower.radius, beam):
				_damage_follower(follower, beam.damage, beam.color)
	else:
		for enemy in _ai_snakes:
			if enemy.dead or enemy.dying:
				continue
			if _point_in_beam(enemy.position, enemy.radius, beam):
				_damage_enemy(enemy, beam.damage, 10)

func _point_in_beam(position: Vector2, radius: float, beam: BeamStrike) -> bool:
	var relative: Vector2 = position - beam.origin
	var forward: float = relative.dot(beam.direction)
	if forward < 0.0 or forward > beam.length:
		return false
	var side: float = abs(relative.dot(beam.direction.orthogonal()))
	return side <= beam.width * 0.5 + radius

func _update_effects(delta: float) -> void:
	_world_time += delta

	for i in range(_particles.size() - 1, -1, -1):
		var particle: VfxParticle = _particles[i]
		particle.update(delta)
		if not particle.alive():
			_return_particle(_particles[i])
			_particles.remove_at(i)

	for i in range(_shockwaves.size() - 1, -1, -1):
		var shockwave: Shockwave = _shockwaves[i]
		shockwave.update(delta)
		if not shockwave.alive():
			_return_shockwave(_shockwaves[i])
			_shockwaves.remove_at(i)

	if _shake_timer > 0.0:
		_shake_timer = maxf(0.0, _shake_timer - delta)
		if _shake_timer <= 0.0:
			_camera.offset = Vector2.ZERO

func _update_camera(delta: float) -> void:
	var weight := 1.0 - exp(-GameConfigData.CAMERA_SMOOTHNESS * delta)
	_camera.position = _camera.position.lerp(_player.position, weight)
	if _shake_timer > 0.0 and _shake_duration > 0.001:
		var shake_progress := 1.0 - (_shake_timer / _shake_duration)
		var amplitude := _shake_strength * (1.0 - clampf(shake_progress, 0.0, 1.0))
		_camera.offset = Vector2(randf_range(-amplitude, amplitude), randf_range(-amplitude, amplitude))
	else:
		_camera.offset = Vector2.ZERO

func _follow_segments(agent: SnakeAgent) -> void:
	var leader := agent.position
	for i in range(agent.segments.size()):
		var segment: Vector2 = agent.segments[i]
		var offset := leader - segment
		var distance := offset.length()
		if distance > GameConfigData.SNAKE_SEGMENT_SPACING and distance > 0.001:
			segment = leader - offset.normalized() * GameConfigData.SNAKE_SEGMENT_SPACING
		else:
			segment = segment.lerp(leader - agent.direction * GameConfigData.SNAKE_SEGMENT_SPACING, 0.08)
		agent.segments[i] = segment
		leader = segment

func _refresh_player_body_bounds() -> void:
	if _player.segments.is_empty():
		_player_body_bounds = Rect2(_player.position, Vector2.ZERO)
		return
	var first: Vector2 = _player.segments[0]
	var min_position := first
	var max_position := first
	for i in range(1, _player.segments.size()):
		var segment: Vector2 = _player.segments[i]
		min_position.x = minf(min_position.x, segment.x)
		min_position.y = minf(min_position.y, segment.y)
		max_position.x = maxf(max_position.x, segment.x)
		max_position.y = maxf(max_position.y, segment.y)
	_player_body_bounds = Rect2(min_position, max_position - min_position)

func _grow_player() -> void:
	var tail := _player.position
	if not _player.segments.is_empty():
		tail = _player.segments.back()
	_player.segments.append(tail - _player.direction * GameConfigData.SNAKE_SEGMENT_SPACING)
	_update_player_radius()

func _update_player_radius() -> void:
	var length_bonus: float = minf(PLAYER_LENGTH_RADIUS_MAX, float(_player.segments.size()) / float(PLAYER_LENGTH_RADIUS_STEP))
	_player.radius = GameConfigData.INITIAL_SNAKE_RADIUS + length_bonus

func _visual_radius_for_agent(agent: SnakeAgent, ratio: float = 0.0) -> float:
	var length_bonus: float = minf(0.24, float(agent.segments.size()) / 90.0)
	var taper: float = 1.0 - ratio * (0.24 + length_bonus * 0.45)
	return agent.radius * clampf(taper, 0.54, 1.24)

func _collision_body_radius(agent: SnakeAgent, ratio: float = 0.5) -> float:
	return _visual_radius_for_agent(agent, ratio) * 0.78

func _resolve_blocking_hazard(agent: SnakeAgent, force_feedback: bool = false) -> bool:
	if _terrain_hazard_renderer == null:
		return false
	var hit: Dictionary = _terrain_hazard_renderer.get_blocking_cell_near_position(agent.position, agent.radius * 0.9)
	if hit.is_empty():
		return false
	var center: Vector2 = hit.get("center", agent.position)
	var push_dir: Vector2 = agent.position - center
	if push_dir.length_squared() <= 0.001:
		push_dir = -agent.direction if agent.direction.length_squared() > 0.001 else Vector2.UP
	push_dir = push_dir.normalized()
	var cell_size: float = _terrain_hazard_renderer.get_cell_size()
	var target_distance: float = agent.radius + cell_size * 0.54
	agent.position = center + push_dir * target_distance
	agent.direction = _smooth_direction(agent.direction, push_dir.rotated(randf_range(-0.35, 0.35)).normalized(), 0.38)
	if agent == _player or force_feedback:
		_spawn_obstacle_impact(agent.position, push_dir)
		_start_screen_shake(1.8, 0.07)
		_set_event(LocaleText.t("event.wall_impact"), 0.9)
	return true

func _spawn_obstacle_impact(position: Vector2, normal: Vector2) -> void:
	var tangent: Vector2 = normal.orthogonal()
	for i in range(7):
		var velocity: Vector2 = normal * randf_range(55.0, 130.0) + tangent * randf_range(-60.0, 60.0)
		var color := Color(0.08, 0.24, 0.22, 0.9).lerp(Color(0.2, 1.0, 0.68, 0.86), randf())
		_add_particle(_get_particle(position + tangent * randf_range(-9.0, 9.0), velocity, color, randf_range(2.5, 5.5), randf_range(0.22, 0.44), 0.86))

func _start_ai_death(ai: SnakeAgent, food_value: int, award_score := true) -> void:
	if ai.dying or ai.dead:
		return
	ai.dying = true
	ai.death_timer = 0.0
	ai.drop_done = false
	ai.drop_value = food_value
	if award_score:
		_award_kill_score(ai)
	_spawn_death_burst(ai.position, ai.color)
	_start_screen_shake(5.5, 0.16)
	AudioBus.play_explosion()

func _drop_food_for_snake(ai: SnakeAgent, amount: int) -> void:
	if amount <= 0:
		return
	# Collect drop positions first
	var positions := [ai.position + Vector2(randf_range(-18.0, 18.0), randf_range(-18.0, 18.0))]
	var remaining := amount - 1
	var segment_index := 0
	while remaining > 0 and segment_index < ai.segments.size():
		positions.append(ai.segments[segment_index] + Vector2(randf_range(-18.0, 18.0), randf_range(-18.0, 18.0)))
		remaining -= 1
		segment_index += 1
	# When at capacity, overwrite oldest slots from the front (O(1) each)
	# instead of append + pop_front (O(n) per pop due to array shift).
	# The spatial grid is rebuilt below, so index reordering is safe.
	var write_index := 0
	for i in range(positions.size()):
		if _foods.size() < GameConfigData.MAX_FOOD_COUNT:
			_foods.append(_make_food(positions[i]))
		else:
			_foods[write_index] = _make_food(positions[i])
			write_index += 1
	_food_grid.build(_foods)
	_visible_food_cache_valid = false

## 触发游戏结束流程。
##
## 标记游戏为结束状态，记录死亡原因，生成死亡粒子特效
## 和强屏幕震动，播放死亡音效。构建运行摘要并提交至排行榜，
## 然后在游戏结束对话框中展示结果。防止重复触发。
## 参数 reason: 死亡原因描述，如 "Collision"、"Lava"。
func _trigger_game_over(reason := "Collision") -> void:
	if _game_over:
		return
	_game_over = true
	_run_stats["death_reason"] = reason
	_spawn_death_burst(_player.position, Color(1.0, 0.34, 0.18))
	_start_screen_shake(9.0, 0.32)
	AudioBus.play_death()
	var summary := _build_run_summary()
	summary["record"] = RunRecords.submit_run(summary)
	_game_over_dialog.show_result(summary)
	_update_hud()

func _update_run_timers(delta: float) -> void:
	if _combo_timer > 0.0:
		_combo_timer = maxf(0.0, _combo_timer - delta)
		if _combo_timer <= 0.0:
			_combo_count = 0
	if _magnet_timer > 0.0:
		_magnet_timer = maxf(0.0, _magnet_timer - delta)
	_update_story_events(delta)

func _update_wave(delta: float) -> void:
	var phase := String(_wave_state.get("phase", "fighting"))
	if _game_over and phase != "victory":
		return
	_wave_state["elapsed"] = float(_wave_state.get("elapsed", 0.0)) + delta
	_wave_state["wave_time"] = float(_wave_state.get("wave_time", 0.0)) + delta
	if phase == "victory":
		_wave_state["coronation_timer"] = maxf(0.0, float(_wave_state.get("coronation_timer", 0.0)) - delta)
		return
	if phase == "reward":
		var timer := maxf(0.0, float(_wave_state.get("reward_timer", 0.0)) - delta)
		_wave_state["reward_timer"] = timer
		if timer <= 0.0:
			var next_wave := int(_wave_state.get("wave", 1)) + 1
			if next_wave <= WaveCatalogData.max_wave():
				_start_campaign_wave(next_wave)
		return
	var remaining := _count_living_wave_enemies()
	_wave_state["remaining_enemies"] = remaining
	_sync_follower_counters()
	if remaining <= 0 and not bool(_wave_state.get("wave_clear_pending", false)):
		_wave_state["wave_clear_pending"] = true
		_complete_campaign_wave()

func _count_living_wave_enemies() -> int:
	var count := 0
	for enemy in _ai_snakes:
		if enemy.dead:
			continue
		if enemy.wave_member:
			count += 1
	return count

func _complete_campaign_wave() -> void:
	var wave := int(_wave_state.get("wave", 1))
	_run_stats["waves"] = maxi(int(_run_stats.get("waves", 1)), wave)
	if wave >= WaveCatalogData.max_wave():
		_trigger_victory()
		return
	_add_wave_followers(FOLLOWERS_PER_WAVE)
	_wave_state["phase"] = "reward"
	_wave_state["reward_timer"] = WAVE_REWARD_TIME
	_wave_state["wave_clear_pending"] = false
	var title := WaveCatalogData.title_for_wave(wave)
	_wave_state["title"] = title
	_run_stats["title"] = title
	if wave == 5:
		_set_event(LocaleText.t("event.snake_king"), 3.2)
	else:
		_set_event(LocaleText.t("event.wave_clear"), 2.8)
	_queue_story(LocaleText.t("event.wave_clear"), 2.8, "wave_clear_%d" % wave, 999.0)

func _add_wave_followers(count: int) -> void:
	for i in range(count):
		_follower_serial += 1
		var follower := _make_follower_snake(_follower_serial)
		_follower_snakes.append(follower)
	_run_stats["followers_recruited"] = int(_run_stats.get("followers_recruited", 0)) + count
	_sync_follower_counters()

func _living_followers() -> int:
	var count := 0
	for follower in _follower_snakes:
		if not follower.dead and not follower.dying:
			count += 1
	return count

func _sync_follower_counters() -> void:
	var alive := _living_followers()
	var total := _follower_snakes.size()
	var recruited := int(_run_stats.get("followers_recruited", 0))
	_wave_state["followers_alive"] = alive
	_wave_state["followers_total"] = total
	_wave_state["followers_recruited"] = recruited
	_run_stats["followers_alive"] = alive
	_run_stats["followers_total"] = total

func _trigger_victory() -> void:
	if _victory_triggered:
		return
	_victory_triggered = true
	_game_over = true
	_wave_state["phase"] = "victory"
	_wave_state["coronation_timer"] = CORONATION_TIME
	_wave_state["title"] = "Snake Emperor"
	_run_stats["victory"] = true
	_run_stats["title"] = "Snake Emperor"
	_run_stats["death_reason"] = "Victory"
	_run_stats["followers_recruited"] = int(_run_stats.get("followers_recruited", 0))
	_sync_follower_counters()
	_set_event(LocaleText.t("event.snake_emperor"), CORONATION_TIME)
	_spawn_coronation_burst()
	_start_screen_shake(4.5, 0.34)
	var summary := _build_run_summary()
	summary["record"] = RunRecords.submit_run(summary)
	_game_over_dialog.show_result(summary)
	_update_hud()

func _spawn_coronation_burst() -> void:
	for i in range(5):
		_add_shockwave(_get_shockwave(_player.position, Color(1.0, 0.82, 0.28).lerp(Color(0.2, 1.0, 0.62), float(i) / 5.0), 160.0 + float(i) * 80.0, 0.72 + float(i) * 0.08))
	for i in range(80 if SettingsStore.animations_on else 20):
		var direction := Vector2.RIGHT.rotated(randf_range(0.0, TAU))
		_add_particle(_get_particle(_player.position + direction * randf_range(0.0, 32.0), direction * randf_range(120.0, 420.0), Color(1.0, 0.78, 0.24).lerp(Color(0.26, 1.0, 0.68), randf()), randf_range(3.0, 8.0), randf_range(0.5, 1.0), 0.9))

## 处理食物拾取效果，计分并应用特殊属性。
##
## 注册连击计数并计算连击倍率，更新分数与已吃食物数。
## 根据食物的 growth 值增加蛇身长度。
## 若食物携带 shield_time 或 magnet_time，则延长对应计时器。
## 若食物有 explosion_radius，则触发区域爆炸伤害敌人。
## 生成拾取粒子特效和屏幕震动。玩家拾取时检查升级解锁。
## 参数 index: 食物在数组中的索引。
## 参数 player_pickup: 是否为玩家拾取（否则为同伴拾取）。
func _consume_food(index: int, player_pickup := true) -> void:
	if index < 0 or index >= _foods.size():
		return
	var food: FoodDot = _foods[index]
	if food.radius <= 0.0:
		return
	_register_combo(food.kind)
	var combo_multiplier := 1.0 + maxf(0.0, float(_combo_count - 1)) * (0.08 + float(_modifiers.get("combo_score_bonus", 0.0)))
	var points := int(round(float(food.score_value + int(_modifiers.get("food_value_bonus", 0))) * combo_multiplier))
	_score += maxi(1, points)
	_food_eaten += 1
	_run_stats["food_eaten"] = _food_eaten
	_grow_player_by(maxi(1, food.growth + int(_modifiers.get("growth_bonus", 0))))
	if food.shield_time > 0.0:
		_invulnerability_timer = maxf(_invulnerability_timer, food.shield_time + float(_modifiers.get("shield_bonus", 0.0)))
		_set_event(LocaleText.format("event.shield_seconds", [food.shield_time]), 1.8)
	if food.magnet_time > 0.0:
		_magnet_timer = maxf(_magnet_timer, food.magnet_time + float(_modifiers.get("magnet_duration_bonus", 0.0)))
		_set_event(LocaleText.t("event.magnet_field"), 1.8)
	var explosion := food.explosion_radius + float(_modifiers.get("explosion_radius", 0.0))
	if explosion > 0.0:
		explosion += float(_modifiers.get("combo_explosion", 0.0)) * float(_combo_count)
		_area_blast(food.position, explosion, 1, food.color)
	_spawn_food_burst(food.position, food.color)
	_start_screen_shake(2.0 + minf(float(_combo_count) * 0.18, 4.0), 0.07)
	if player_pickup:
		_maybe_offer_upgrade()

func _register_combo(food_kind: String) -> void:
	if _combo_timer > 0.0:
		_combo_count += 1
	else:
		_combo_count = 1
	if food_kind == "combo":
		_combo_count += 1
	_combo_timer = BASE_COMBO_WINDOW + float(_modifiers.get("combo_window", 0.0))
	_max_combo = maxi(_max_combo, _combo_count)
	_run_stats["max_combo"] = _max_combo

func _grow_player_by(amount: int) -> void:
	for i in range(maxi(1, amount)):
		_grow_player()

func _maybe_offer_upgrade() -> void:
	if _upgrade_choice_active:
		return
	if _next_upgrade_index >= UPGRADE_FOOD_THRESHOLDS.size():
		return
	if _food_eaten < int(UPGRADE_FOOD_THRESHOLDS[_next_upgrade_index]):
		return
	if _next_upgrade_index < UPGRADE_TIME_THRESHOLDS.size() and float(_wave_state.get("elapsed", 0.0)) < float(UPGRADE_TIME_THRESHOLDS[_next_upgrade_index]):
		return
	var choices := UpgradeCatalogData.random_upgrade_choices(_owned_upgrade_ids, 3)
	if choices.is_empty():
		return
	_next_upgrade_index += 1
	_upgrade_choices = choices
	_upgrade_choice_active = true
	_set_event(LocaleText.t("event.upgrade_ready"), 1.4)
	_upgrade_picker.show_choices(choices, _current_build_tags())

func _select_upgrade(upgrade: Dictionary) -> void:
	if not _upgrade_choice_active:
		return
	_apply_upgrade(upgrade)
	_upgrade_choice_active = false
	_upgrade_picker.hide()
	_set_event(LocaleText.translate_upgrade_name(upgrade), 2.4)
	_update_hud()

## 应用升级效果到玩家属性修饰符。
##
## 记录升级ID防止重复获取，将效果值累加到 _modifiers 字典中。
## 整数类型效果以整数累加，浮点类型效果以浮点累加。
## shield_now 效果直接延长无敌时间而非累加修饰符。
## 更新运行统计中的升级名称和构建标签。
## 参数 upgrade: 升级定义字典，包含 id、name、effects 等字段。
func _apply_upgrade(upgrade: Dictionary) -> void:
	var id := String(upgrade.get("id", ""))
	if id == "" or _owned_upgrade_ids.has(id):
		return
	_owned_upgrade_ids.append(id)
	_owned_upgrades.append(upgrade.duplicate(true))
	var effects: Dictionary = upgrade.get("effects", {})
	for key in effects.keys():
		var value = effects[key]
		if key == "shield_now":
			_invulnerability_timer = maxf(_invulnerability_timer, float(value) + float(_modifiers.get("shield_bonus", 0.0)))
			continue
		if value is int:
			_modifiers[key] = int(_modifiers.get(key, 0)) + int(value)
		else:
			_modifiers[key] = float(_modifiers.get(key, 0.0)) + float(value)
	_run_stats["upgrades"] = _upgrade_names()
	_run_stats["build_tags"] = _current_build_tags()
	_sync_follower_counters()

func _update_magnet_pickups(delta: float) -> void:
	var radius := BASE_MAGNET_RADIUS + float(_modifiers.get("magnet_radius", 0.0))
	if _magnet_timer > 0.0:
		radius += 165.0
	if radius <= BASE_MAGNET_RADIUS + 0.1:
		return
	var query := Rect2(_player.position - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0))
	var processed := 0
	for index in _food_indices_for_rect(query):
		if processed >= 60:
			break
		var food: FoodDot = _foods[index]
		if food.radius <= 0.0:
			continue
		var distance := _player.position.distance_to(food.position)
		if distance > radius or distance <= _player.radius:
			continue
		var pull := clampf((radius - distance) / radius, 0.0, 1.0)
		food.position = food.position.lerp(_player.position, clampf(delta * (2.4 + pull * 7.0), 0.0, 0.8))
		_food_grid.upsert_index(_foods, index)
		processed += 1

func _update_companions(delta: float) -> void:
	var drone_count := int(_modifiers.get("drone_count", 0))
	if drone_count <= 0:
		return
	_companion_timer -= delta
	if _companion_timer > 0.0:
		return
	_companion_timer = COMPANION_PICKUP_INTERVAL
	for companion_index in range(mini(drone_count, 4)):
		var angle := _world_time * (1.4 + companion_index * 0.18) + TAU * float(companion_index) / float(maxi(1, drone_count))
		var companion_position := _player.position + Vector2.RIGHT.rotated(angle) * (92.0 + float(companion_index) * 16.0)
		var pickup_radius := 82.0 + float(_modifiers.get("magnet_radius", 0.0)) * 0.35
		var query := Rect2(companion_position - Vector2(pickup_radius, pickup_radius), Vector2(pickup_radius * 2.0, pickup_radius * 2.0))
		var best_index := -1
		var best_distance := INF
		for index in _food_indices_for_rect(query):
			var food: FoodDot = _foods[index]
			if food.radius <= 0.0:
				continue
			var distance := companion_position.distance_squared_to(food.position)
			if distance < best_distance:
				best_distance = distance
				best_index = index
		if best_index >= 0:
			_consume_food(best_index, false)
			_foods[best_index] = _make_food()
			_food_grid.upsert_index(_foods, best_index)

func _resolve_player_enemy_contact(ai: SnakeAgent) -> bool:
	if _invulnerability_timer > 0.0 or _is_boosting():
		_damage_enemy(ai, 1, 12)
		_start_screen_shake(5.5, 0.12)
		return true
	if _try_revive(LocaleText.t("event.revive_last_chance")):
		return true
	_trigger_game_over("Collision")
	return false

func _try_revive(label: String) -> bool:
	var charges := int(_modifiers.get("revive_charges", 0))
	if charges <= 0:
		return false
	_modifiers["revive_charges"] = charges - 1
	_invulnerability_timer = 3.5 + float(_modifiers.get("shield_bonus", 0.0))
	_area_blast(_player.position, 240.0, 2, Color(0.8, 1.0, 0.96))
	_set_event(label, 2.2)
	return true

## 对AI蛇造成伤害，若生命值归零则触发死亡。
##
## 计算实际伤害（对Boss有额外伤害加成），扣除AI生命值。
## 若AI存活则仅生成警告环特效；若死亡则调用 _start_ai_death
## 开始死亡流程，掉落食物并计分。精英和Boss有额外掉落奖励。
## 参数 ai: 目标AI蛇代理。
## 参数 damage: 基础伤害值。
## 参数 food_value: 死亡时掉落的食物价值（用于计分）。
func _damage_enemy(ai: SnakeAgent, damage: int, food_value: int) -> void:
	if ai.dead or ai.dying:
		return
	if ai.ability == "shield" and ai.shield_timer > 0.0 and damage <= 1:
		_spawn_warning_ring(ai.position, Color(0.72, 1.0, 1.0))
		return
	var actual_damage := damage + (int(_modifiers.get("boss_damage", 0)) if ai.is_boss else 0)
	ai.health -= maxi(1, actual_damage)
	if ai.health > 0:
		_spawn_warning_ring(ai.position, ai.color)
		return
	_start_ai_death(ai, food_value + (10 if ai.is_elite else 0) + (28 if ai.is_boss else 0), true)

func _area_blast(position: Vector2, radius: float, damage: int, color: Color, award_score := true) -> void:
	if radius <= 0.0:
		return
	_add_shockwave(_get_shockwave(position, color.lightened(0.22), radius, 0.34))
	for ai in _ai_snakes:
		if ai.dead or ai.dying:
			continue
		if position.distance_squared_to(ai.position) <= pow(radius + ai.radius, 2.0):
			if award_score:
				_damage_enemy(ai, damage, 12)
			else:
				ai.health -= damage
				if ai.health > 0:
					_spawn_warning_ring(ai.position, ai.color)
					continue
				_start_ai_death(ai, maxi(0, ai.drop_value), false)

func _award_kill_score(ai: SnakeAgent) -> void:
	var points := int(round(float(ai.score_value) * (1.0 + float(_modifiers.get("kill_score_mult", 0.0)))))
	_score += points
	_run_stats["kills"] = int(_run_stats.get("kills", 0)) + 1
	if ai.is_elite:
		_run_stats["elite_kills"] = int(_run_stats.get("elite_kills", 0)) + 1
	if ai.is_boss:
		_run_stats["boss_kills"] = int(_run_stats.get("boss_kills", 0)) + 1
		_set_event(LocaleText.t("event.boss_defeated"), 4.0)
		_queue_story(LocaleText.t("event.boss_story"), 3.4, "boss_defeated", 999.0)

func _spawn_death_followups(ai: SnakeAgent) -> void:
	if ai.death_explosion > 0.0:
		_area_blast(ai.position, ai.death_explosion + float(_modifiers.get("kill_explosion", 0.0)), 1, ai.color)
	elif float(_modifiers.get("kill_explosion", 0.0)) > 0.0:
		_area_blast(ai.position, float(_modifiers.get("kill_explosion", 0.0)), 1, ai.color)
	for i in range(ai.split_count):
		var split := _make_ai_snake(ai.position + Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(70.0, 150.0), [], false)
		split.team = "enemy"
		split.enemy_type = "split_fragment"
		split.ability = "hunter"
		split.wave_member = ai.wave_member
		split.color = ai.color.lightened(0.08)
		split.health = 1
		split.max_health = 1
		split.score_value = max(4, int(ai.score_value * 0.35))
		split.drop_value = max(2, int(ai.drop_value * 0.35))
		split.radius *= 0.82
		split.speed_multiplier *= 1.08
		_ai_snakes.append(split)
	for i in range(ai.summon_count):
		if ai.spawned_children >= 6:
			break
		ai.spawned_children += 1
		var summon := _make_ai_snake(ai.position + Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * 170.0, [], false)
		summon.team = "enemy"
		summon.enemy_type = "brood_guard"
		summon.ability = "hunter"
		summon.wave_member = ai.wave_member
		summon.color = ai.color.lerp(Color(0.2, 1.0, 0.6), 0.25)
		summon.health = 1
		summon.max_health = 1
		summon.score_value = 6
		summon.drop_value = 4
		_ai_snakes.append(summon)

func _spawn_warning_ring(position: Vector2, color: Color) -> void:
	_add_shockwave(_get_shockwave(position, color.lightened(0.18), 120.0, 0.32))

## Spawn damage particles at a position (for hazard damage feedback)
func _spawn_damage_particles(position: Vector2, count: int) -> void:
	for i in range(count):
		var p: VfxParticle = _get_particle(
			position + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0)),
			Vector2(randf_range(-60.0, 60.0), randf_range(-80.0, -20.0)),
			Color(1.0, 0.35, 0.1, 0.9),
			randf_range(2.0, 5.0),
			randf_range(0.25, 0.55)
		)
		_add_particle(p)

func _set_event(text: String, duration := 2.6) -> void:
	_wave_state["last_event"] = text
	_wave_state["event_time"] = duration

func _localized_wave_event(wave: int, fallback: String) -> String:
	return LocaleText.wave_event(wave, fallback)

func _queue_story(text: String, duration := 2.8, key := "", cooldown := 10.0) -> void:
	if text == "":
		return
	var cooldown_key := key if key != "" else text
	if _story_cooldowns.has(cooldown_key):
		return
	_story_cooldowns[cooldown_key] = cooldown
	_story_queue.append({"text": text, "duration": duration})
	if float(_wave_state.get("event_time", 0.0)) <= 0.0:
		_advance_story_queue()

func _update_story_events(delta: float) -> void:
	if float(_wave_state.get("event_time", 0.0)) > 0.0:
		_wave_state["event_time"] = maxf(0.0, float(_wave_state.get("event_time", 0.0)) - delta)
	var cooldown_keys: Array = _story_cooldowns.keys()
	for key in cooldown_keys:
		var next_value := float(_story_cooldowns.get(key, 0.0)) - delta
		if next_value <= 0.0:
			_story_cooldowns.erase(key)
		else:
			_story_cooldowns[key] = next_value
	if float(_wave_state.get("event_time", 0.0)) <= 0.0:
		_advance_story_queue()

func _advance_story_queue() -> void:
	if _story_queue.is_empty():
		return
	var item: Dictionary = _story_queue.pop_front()
	_set_event(String(item.get("text", "")), float(item.get("duration", 2.8)))

func _update_terrain_state() -> void:
	var terrain: Dictionary = _terrain_for_position(_player.position)
	var terrain_id: String = String(terrain.get("id", ""))
	if terrain_id != "":
		_current_player_terrain_id = terrain_id

func _terrain_for_position(position: Vector2) -> Dictionary:
	return TerrainCatalogData.terrain_for_position(position, _play_area)

func _terrain_speed_multiplier(position: Vector2) -> float:
	var terrain: Dictionary = _terrain_for_position(position)
	var base_speed: float = clampf(float(terrain.get("speed_multiplier", 1.0)), 0.92, 1.08)

	# Apply hazard slow if on ice crack
	if _terrain_hazard_renderer != null:
		var hazard_slow: float = _terrain_hazard_renderer.get_slow_multiplier(position)
		base_speed *= hazard_slow

	return base_speed

func _current_build_tags() -> Array:
	return UpgradeCatalogData.summarize_tags(_owned_upgrades)

func _upgrade_names() -> Array:
	var names: Array = []
	for upgrade in _owned_upgrades:
		names.append(LocaleText.translate_upgrade_name(upgrade))
	return names

func _build_snapshot() -> Dictionary:
	return {
		"build_tags": _current_build_tags(),
		"upgrade_names": _upgrade_names(),
		"wave": int(_wave_state.get("wave", 1)),
		"title": String(_wave_state.get("title", "Lone Snake")),
		"followers_alive": _living_followers(),
		"followers_total": _follower_snakes.size(),
		"followers_recruited": int(_run_stats.get("followers_recruited", 0)),
		"drone_count": int(_modifiers.get("drone_count", 0)),
		"max_combo": _max_combo,
	}

func _build_run_summary() -> Dictionary:
	var summary := _run_stats.duplicate(true)
	summary["score"] = _score
	summary["food_eaten"] = _food_eaten
	summary["max_combo"] = _max_combo
	summary["duration"] = float(_wave_state.get("elapsed", 0.0))
	summary["upgrades"] = _upgrade_names()
	summary["build_tags"] = _current_build_tags()
	summary["waves"] = int(_wave_state.get("wave", 1))
	summary["victory"] = bool(_run_stats.get("victory", false))
	summary["title"] = String(_run_stats.get("title", _wave_state.get("title", "Lone Snake")))
	summary["followers_alive"] = _living_followers()
	summary["followers_total"] = _follower_snakes.size()
	summary["followers_recruited"] = int(_run_stats.get("followers_recruited", 0))
	summary["drone_count"] = int(_modifiers.get("drone_count", 0))
	summary["challenge_seed"] = int(_run_stats.get("challenge_seed", RunRecords.daily_seed()))
	if String(summary.get("death_reason", "")) == "":
		summary["death_reason"] = "Unknown"
	return summary

func _set_paused(value: bool) -> void:
	_paused = value
	_pause_overlay.visible = _paused
	if _paused:
		_pause_overlay.set_build_snapshot(_build_snapshot())
	_update_hud()

func _debug_enabled() -> bool:
	return OS.is_debug_build() or DisplayServer.get_name() == "headless"

func debug_campaign_state() -> Dictionary:
	if not _debug_enabled():
		return {}
	return {
		"wave": int(_wave_state.get("wave", 1)),
		"phase": String(_wave_state.get("phase", "fighting")),
		"remaining": _count_living_wave_enemies(),
		"followers_alive": _living_followers(),
		"followers_total": _follower_snakes.size(),
		"followers_recruited": int(_run_stats.get("followers_recruited", 0)),
		"drone_count": int(_modifiers.get("drone_count", 0)),
		"victory": bool(_run_stats.get("victory", false)),
		"title": String(_wave_state.get("title", "Lone Snake")),
	}

func debug_clear_current_wave() -> void:
	if not _debug_enabled():
		return
	for enemy in _ai_snakes:
		enemy.dead = true
		enemy.dying = false
	_update_wave(0.0)
	if String(_wave_state.get("phase", "")) == "reward":
		_wave_state["reward_timer"] = 0.0
		_update_wave(0.0)

func debug_wave_enemy_state() -> Array:
	if not _debug_enabled():
		return []
	var enemies: Array = []
	for enemy in _ai_snakes:
		if not enemy.wave_member:
			continue
		enemies.append({
			"enemy_type": enemy.enemy_type,
			"dead": enemy.dead,
			"dying": enemy.dying,
			"health": enemy.health,
		})
	return enemies

func debug_damage_wave_enemy(index: int, damage: int = 99, food_value: int = 0) -> bool:
	if not _debug_enabled():
		return false
	var wave_index := -1
	for enemy in _ai_snakes:
		if not enemy.wave_member or enemy.dead:
			continue
		wave_index += 1
		if wave_index == index:
			_damage_enemy(enemy, damage, food_value)
			return true
	return false

func debug_area_blast_wave_enemy(index: int, damage: int = 99, award_score := false) -> bool:
	if not _debug_enabled():
		return false
	var wave_index := -1
	for enemy in _ai_snakes:
		if not enemy.wave_member or enemy.dead:
			continue
		wave_index += 1
		if wave_index == index:
			_area_blast(enemy.position, enemy.radius + 18.0, damage, enemy.color, award_score)
			return true
	return false

func debug_apply_upgrade(id: String) -> bool:
	if not _debug_enabled():
		return false
	var upgrade := UpgradeCatalogData.upgrade_by_id(id)
	if upgrade.is_empty():
		return false
	_apply_upgrade(upgrade)
	return true

func debug_add_followers(count: int) -> bool:
	if not _debug_enabled():
		return false
	if count <= 0:
		return false
	_add_wave_followers(count)
	return true

func debug_damage_follower(index: int, damage: int = 99) -> bool:
	if not _debug_enabled():
		return false
	var follower_index := -1
	for follower in _follower_snakes:
		if follower.dead:
			continue
		follower_index += 1
		if follower_index == index:
			_damage_follower(follower, damage, Color(1.0, 0.3, 0.2))
			return true
	return false

func _set_keyboard_direction(direction: Vector2) -> void:
	if _game_over:
		return
	_mouse_control_enabled = false
	_target_direction = direction

func _is_boosting() -> bool:
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not _paused and not _game_over and not _upgrade_choice_active

func _update_particle_emitters(delta: float) -> void:
	if not SettingsStore.animations_on:
		return
	var quality := _effects_quality()
	var budget := _particle_budget()

	if quality > 0 and _particles.size() < int(float(budget) * AMBIENT_PARTICLE_LIMIT_RATIO):
		_ambient_particle_timer -= delta
		if _ambient_particle_timer <= 0.0:
			_spawn_ambient_motes(2 if quality >= 2 else 1)
			_ambient_particle_timer = 0.16 if quality >= 2 else 0.32

	if _invulnerability_timer > 0.0:
		_shield_particle_timer -= delta
		if _shield_particle_timer <= 0.0:
			_spawn_shield_sparkles(2 if quality >= 2 else 1)
			_shield_particle_timer = 0.075 if quality >= 2 else 0.13

func _spawn_ambient_motes(count: int) -> void:
	var visible := _visible_world_rect().grow(80.0)
	for i in range(count):
		var position := Vector2(
			randf_range(visible.position.x, visible.position.x + visible.size.x),
			randf_range(visible.position.y, visible.position.y + visible.size.y)
		)
		var terrain := _terrain_for_position(position)
		var mote_color: Color = terrain.get("particle_color", Color(0.26, 1.0, 0.68, 0.24))
		_add_particle(_get_particle(
			position,
			Vector2(randf_range(-10.0, 10.0), randf_range(-26.0, -8.0)),
			_color_alpha(mote_color, randf_range(0.16, 0.3)),
			randf_range(1.6, 3.4),
			randf_range(0.7, 1.2),
			0.96
		))

func _spawn_shield_sparkles(count: int) -> void:
	for i in range(count):
		var direction := Vector2.RIGHT.rotated(randf_range(0.0, TAU))
		_add_particle(_get_particle(
			_player.position + direction * randf_range(_player.radius * 1.25, _player.radius * 1.95),
			direction * randf_range(16.0, 52.0),
			Color(0.68, 1.0, 0.95, 0.58),
			randf_range(2.0, 4.2),
			randf_range(0.22, 0.42),
			0.9
		))

func _spawn_lava_warning_sparks(delta: float) -> void:
	if not SettingsStore.animations_on:
		return
	_lava_spark_timer -= delta
	if _lava_spark_timer > 0.0:
		return
	var quality := _effects_quality()
	var spark_count := 3 if quality >= 2 else 1
	if quality == 1:
		spark_count = 2
	_lava_spark_timer = 0.08 if quality >= 2 else 0.16
	for i in range(spark_count):
		var direction := Vector2.RIGHT.rotated(randf_range(0.0, TAU))
		_add_particle(_get_particle(
			_player.position + direction * randf_range(_player.radius * 0.4, _player.radius * 1.4),
			direction * randf_range(60.0, 140.0) + Vector2(0.0, randf_range(-28.0, 12.0)),
			Color(1.0, randf_range(0.28, 0.62), 0.12, 0.68),
			randf_range(2.5, 6.0),
			randf_range(0.18, 0.34),
			0.84
		))

func _spawn_boost_trail() -> void:
	if not SettingsStore.animations_on:
		return
	var back := -_player.direction.normalized()
	var side := Vector2(-_player.direction.y, _player.direction.x)
	var particle_count := 2 if _particles.size() < _particle_budget() * 0.75 else 1
	for i in range(particle_count):
		var offset := back * randf_range(_player.radius * 0.75, _player.radius * 1.45) + side * randf_range(-_player.radius * 0.5, _player.radius * 0.5)
		var velocity := back * randf_range(90.0, 190.0) + side * randf_range(-28.0, 28.0)
		_add_particle(_get_particle(
			_player.position + offset,
			velocity,
			Color(0.36, 1.0, 0.48, 0.72),
			randf_range(3.0, 6.5),
			randf_range(0.16, 0.28),
			0.82
		))

func _spawn_food_burst(position: Vector2, color: Color) -> void:
	_add_shockwave(_get_shockwave(position, color.lightened(0.24), 58.0, 0.22))
	var burst_count := 12 if SettingsStore.animations_on else 3
	for i in range(burst_count):
		var direction := Vector2.RIGHT.rotated(randf_range(0.0, TAU))
		_add_particle(_get_particle(
			position,
			direction * randf_range(55.0, 165.0),
			color.lightened(randf_range(0.0, 0.35)),
			randf_range(2.0, 5.0),
			randf_range(0.22, 0.46),
			0.88
		))

func _spawn_death_burst(position: Vector2, color: Color) -> void:
	_add_shockwave(_get_shockwave(position, color.lightened(0.18), 170.0, 0.48))
	_add_shockwave(_get_shockwave(position, Color(1.0, 0.38, 0.16), 95.0, 0.32))
	var burst_count := 42 if SettingsStore.animations_on else 10
	for i in range(burst_count):
		var direction := Vector2.RIGHT.rotated(randf_range(0.0, TAU))
		var burst_color := color.lerp(Color(1.0, 0.42, 0.12), randf_range(0.15, 0.65))
		_add_particle(_get_particle(
			position + direction * randf_range(0.0, 18.0),
			direction * randf_range(95.0, 360.0),
			burst_color,
			randf_range(2.5, 8.0),
			randf_range(0.32, 0.7),
			0.86
		))

func _spawn_snake_dissolve_sparks(ai: SnakeAgent) -> void:
	if not SettingsStore.animations_on:
		return
	var point_count := ai.segments.size() + 1
	var spark_count := 3 if _effects_quality() >= 2 else 1
	for i in range(spark_count):
		var point_index := randi_range(0, point_count - 1)
		var source: Vector2 = ai.position if point_index == 0 else ai.segments[point_index - 1]
		var direction := Vector2.RIGHT.rotated(randf_range(0.0, TAU))
		_add_particle(_get_particle(
			source + direction * randf_range(0.0, ai.radius * 0.8),
			direction * randf_range(42.0, 130.0),
			ai.color.lightened(randf_range(0.08, 0.34)),
			randf_range(2.0, 5.4),
			randf_range(0.18, 0.38),
			0.84
		))

func _start_screen_shake(strength: float, duration: float) -> void:
	if not SettingsStore.screen_shake_on:
		_shake_timer = 0.0
		_camera.offset = Vector2.ZERO
		return
	if strength <= _shake_strength and _shake_timer > 0.0:
		_shake_timer = maxf(_shake_timer, minf(duration, 0.18))
		return
	_shake_strength = strength
	_shake_duration = duration
	_shake_timer = duration

func _add_particle(particle: VfxParticle) -> void:
	var budget := _particle_budget()
	if budget <= 0:
		return
	if _particles.size() >= budget:
		_return_particle(_particles[0])
		_particles.remove_at(0)
	_particles.append(particle)

func _add_shockwave(shockwave: Shockwave) -> void:
	var budget := _shockwave_budget()
	if budget <= 0:
		return
	if _shockwaves.size() >= budget:
		_return_shockwave(_shockwaves[0])
		_shockwaves.remove_at(0)
	_shockwaves.append(shockwave)

func _color_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)

func _update_hud() -> void:
	var alive_count := 0
	_hud_ai_positions.clear()
	for ai in _ai_snakes:
		if not ai.dead:
			alive_count += 1
			_hud_ai_positions.append(ai.position)

	_hud_snapshot["score"] = _score
	_hud_snapshot["boosting"] = _is_boosting() and not _paused and not _game_over
	_hud_snapshot["invulnerable"] = _invulnerability_timer > 0.0
	_hud_snapshot["invulnerability_time"] = _invulnerability_timer
	_hud_snapshot["combo"] = _combo_count
	_hud_snapshot["combo_time"] = _combo_timer
	_hud_snapshot["wave"] = int(_wave_state.get("wave", 1))
	_hud_snapshot["max_wave"] = WaveCatalogData.max_wave()
	_hud_snapshot["pressure"] = float(_wave_state.get("pressure", 1.0))
	_hud_snapshot["wave_phase"] = String(_wave_state.get("phase", "fighting"))
	_hud_snapshot["enemy_type"] = String(_wave_state.get("enemy_type", "Hunter"))
	_hud_snapshot["remaining_enemies"] = int(_wave_state.get("remaining_enemies", alive_count))
	_hud_snapshot["title"] = String(_wave_state.get("title", "Lone Snake"))
	_hud_snapshot["followers_alive"] = _living_followers()
	_hud_snapshot["followers_total"] = _follower_snakes.size()
	_hud_snapshot["followers_recruited"] = int(_run_stats.get("followers_recruited", 0))
	_hud_snapshot["drone_count"] = int(_modifiers.get("drone_count", 0))
	_hud_snapshot["build_tags"] = _current_build_tags()
	_hud_snapshot["event_text"] = String(_wave_state.get("last_event", "")) if float(_wave_state.get("event_time", 0.0)) > 0.0 else ""
	var terrain := _terrain_for_position(_player.position)
	_hud_snapshot["terrain_name"] = String(terrain.get("name", "Obsidian Maze"))
	_hud_snapshot["terrain_color"] = terrain.get("accent", Color(0.48, 1.0, 0.7, 0.6))
	_hud_snapshot["in_lava"] = _lava_timer > 0.0
	_hud_snapshot["lava_time"] = maxf(0.0, float(_difficulty.get("lava_warning_time", 5.0)) - _lava_timer)
	_hud_snapshot["paused"] = _paused
	_hud_snapshot["ai_alive"] = alive_count
	_hud_snapshot["ai_total"] = maxi(int(_wave_state.get("remaining_enemies", alive_count)), _ai_snakes.size())
	_hud_snapshot["world_rect"] = _play_area
	_hud_snapshot["player_position"] = _player.position
	_hud_snapshot["ai_positions"] = _hud_ai_positions
	_hud_snapshot["food_count"] = _foods.size()
	_hud.update_snapshot(_hud_snapshot)

func _draw_lava_edge(visible: Rect2) -> void:
	var pulse := 0.5 + 0.5 * sin(_world_time * 2.8)
	var hot := Color(0.18, 0.06, 0.025, 0.26 + pulse * 0.08)
	var ember := Color(0.95, 0.58, 0.2, 0.38)
	var left := Rect2(_play_area.position - Vector2(LAVA_EDGE_WIDTH, 0.0), Vector2(LAVA_EDGE_WIDTH, _play_area.size.y))
	var right := Rect2(Vector2(_play_area.position.x + _play_area.size.x, _play_area.position.y), Vector2(LAVA_EDGE_WIDTH, _play_area.size.y))
	var top := Rect2(_play_area.position - Vector2(0.0, LAVA_EDGE_WIDTH), Vector2(_play_area.size.x, LAVA_EDGE_WIDTH))
	var bottom := Rect2(Vector2(_play_area.position.x, _play_area.position.y + _play_area.size.y), Vector2(_play_area.size.x, LAVA_EDGE_WIDTH))
	draw_rect(left, hot, true)
	draw_rect(right, hot, true)
	draw_rect(top, hot, true)
	draw_rect(bottom, hot, true)

	var quality := _effects_quality()
	var ember_count := 54 if SettingsStore.animations_on and quality >= 2 else 14
	if SettingsStore.animations_on and quality == 1:
		ember_count = 34
	var perimeter := (_play_area.size.x + _play_area.size.y) * 2.0
	var ember_visible := visible.grow(80.0)
	for i in range(ember_count):
		var travel := fmod(_world_time * 95.0 + float(i) * 397.0, perimeter)
		var position := _point_on_play_area_perimeter(travel)
		if not ember_visible.has_point(position):
			continue
		var normal := _boundary_outward_normal(position)
		var wobble := Vector2(-normal.y, normal.x) * sin(_world_time * 2.7 + float(i)) * 26.0
		var offset_amount: float = 18.0 + 68.0 * abs(sin(float(i) * 12.989 + _world_time * 0.4))
		var ember_position: Vector2 = position + normal * offset_amount + wobble
		var ember_radius: float = 2.0 + 2.0 * abs(sin(_world_time * 3.1 + float(i) * 0.7))
		draw_circle(ember_position, ember_radius * 2.4, Color(0.98, 0.42, 0.08, 0.07))
		draw_circle(ember_position, ember_radius, ember)

func _draw_shockwaves() -> void:
	var drawn := 0
	var quality := _effects_quality()
	var arc_points := 72 if SettingsStore.animations_on and quality >= 2 else 36
	if SettingsStore.animations_on and quality == 1:
		arc_points = 54
	var budget := _shockwave_budget()
	for shockwave in _shockwaves:
		if drawn >= budget:
			break
		var progress: float = shockwave.progress()
		var radius: float = shockwave.max_radius * progress
		var alpha: float = (1.0 - progress) * 0.45
		if radius <= 1.0 or alpha <= 0.01:
			continue
		draw_arc(shockwave.position, radius, 0.0, TAU, arc_points, _color_alpha(shockwave.color, alpha), 4.0 * (1.0 - progress) + 1.0)
		if SettingsStore.animations_on:
			draw_circle(shockwave.position, radius * 0.32, _color_alpha(shockwave.color, alpha * 0.14))
		drawn += 1

func _draw_hazard_zones() -> void:
	for zone in _hazard_zones:
		var progress: float = zone.progress()
		var alpha: float = (1.0 - progress) * 0.26 + 0.08
		draw_circle(zone.position, zone.radius, _color_alpha(zone.color, alpha))
		draw_arc(zone.position, zone.radius * (0.82 + progress * 0.18), 0.0, TAU, 48, _color_alpha(zone.color.lightened(0.18), alpha * 1.7), 2.2)
		if SettingsStore.animations_on:
			draw_circle(zone.position, zone.radius * 0.28, _color_alpha(zone.color.lightened(0.28), alpha * 0.45))

func _draw_beam_strikes() -> void:
	for beam in _beam_strikes:
		var end: Vector2 = beam.origin + beam.direction * beam.length
		var alpha: float = 0.34
		var width: float = beam.width * 0.42
		if beam.is_active():
			alpha = 0.82
			width = beam.width
		draw_line(beam.origin, end, _color_alpha(beam.color, alpha * 0.18), width + 18.0)
		draw_line(beam.origin, end, _color_alpha(beam.color.lightened(0.24), alpha), width)
		draw_line(beam.origin, end, _color_alpha(Color.WHITE, alpha * 0.42), maxf(2.0, width * 0.18))

func _draw_particles() -> void:
	var visible := _visible_world_rect().grow(140.0)
	var drawn := 0
	var budget := _particle_budget()
	var draw_glow := SettingsStore.animations_on and _effects_quality() >= 1
	for particle in _particles:
		if drawn >= budget:
			break
		if not visible.has_point(particle.position):
			continue
		var progress: float = particle.progress()
		var alpha: float = (1.0 - progress) * particle.color.a
		var radius: float = particle.radius * (1.0 + progress * 0.65)
		if draw_glow:
			draw_circle(particle.position, radius * 2.2, _color_alpha(particle.color, alpha * 0.16))
		draw_circle(particle.position, radius, _color_alpha(particle.color, alpha))
		drawn += 1

func _draw_world(visible: Rect2) -> void:
	draw_rect(_play_area.grow(900.0), Color(0.035, 0.005, 0.002), true)
	_draw_lava_edge(visible)
	draw_rect(_play_area, Color(0.004, 0.009, 0.011), true)
	_draw_unified_field(visible)
	_draw_noise_overlay(visible)
	_draw_grid(visible)
	_draw_terrain_hazards(visible)
	var boundary_alpha := 0.72 + 0.18 * sin(_world_time * 4.0)
	draw_rect(_play_area, Color(1.0, 0.42, 0.18, boundary_alpha), false, 7.0)
	draw_rect(_play_area.grow(-10.0), Color(0.14, 0.95, 0.62, 0.16), false, 2.0)
	var edge_warning := _edge_warning_ratio()
	if edge_warning > 0.0 and _lava_timer <= 0.0:
		var warning_pulse := 0.5 + 0.5 * sin(_world_time * 10.0)
		draw_arc(_player.position, _player.radius * (2.25 + warning_pulse * 0.12), 0.0, TAU, 42, Color(0.96, 0.64, 0.22, edge_warning * 0.42), 2.0)
	if _lava_timer > 0.0:
		var warning_pulse := 0.5 + 0.5 * sin(_world_time * 12.0)
		draw_circle(_player.position, _player.radius * (2.15 + warning_pulse * 0.24), Color(0.72, 0.24, 0.08, 0.18))
		draw_arc(_player.position, _player.radius * (2.55 + warning_pulse * 0.25), 0.0, TAU, 54, Color(0.96, 0.62, 0.22, 0.52), 3.0)

func _draw_unified_field(visible: Rect2) -> void:
	var field := _play_area.intersection(visible)
	if field.size.x <= 0.0 or field.size.y <= 0.0:
		return
	draw_rect(field, Color(0.006, 0.015, 0.018), true)
	var wash_alpha := 0.035 + 0.012 * sin(_world_time * 0.9)
	draw_rect(field, Color(0.0, 0.22, 0.16, wash_alpha), true)
	var boss_pollution := String(_wave_state.get("enemy_type", "")) == "Emperor Core" and String(_wave_state.get("phase", "fighting")) == "fighting"
	if boss_pollution:
		var pulse := 0.5 + 0.5 * sin(_world_time * 5.0)
		draw_rect(field, Color(0.95, 0.2, 0.08, 0.04 + pulse * 0.03), true)

func _draw_noise_overlay(visible: Rect2) -> void:
	var field := _play_area.intersection(visible)
	if field.size.x <= 0.0 or field.size.y <= 0.0:
		return
	_draw_aligned_tiled_texture(NOISE_TILE_TEXTURE, field, 1024.0, Color(0.32, 0.72, 0.62, 0.075))

func _draw_forest_paths(visible: Rect2) -> void:
	pass

func _draw_soft_path(points: Array[Vector2], width: float, visible: Rect2) -> void:
	for segment_index in range(points.size() - 1):
		var start_point: Vector2 = points[segment_index]
		var end_point: Vector2 = points[segment_index + 1]
		var segment := end_point - start_point
		var length := segment.length()
		if length <= 1.0:
			continue
		var segment_bounds := Rect2(start_point, Vector2.ZERO).expand(end_point).grow(width * 1.35)
		if not segment_bounds.intersects(visible.grow(width)):
			continue
		var direction := segment / length
		var normal := direction.orthogonal()
		var stamp_count: int = maxi(1, ceili(length / (width * 0.54)))
		for stamp_index in range(stamp_count + 1):
			var t: float = clampf(float(stamp_index) / float(stamp_count), 0.0, 1.0)
			var cell := Vector2i(segment_index, stamp_index)
			var offset := normal * ((_cell_hash_float(cell, 113) - 0.5) * width * 0.16)
			var position := start_point.lerp(end_point, t) + offset
			if not visible.grow(width * 1.3).has_point(position):
				continue
			var rotation := direction.angle() + (_cell_hash_float(cell, 127) - 0.5) * 0.18
			var length_scale := 1.36 + _cell_hash_float(cell, 139) * 0.18
			var width_scale := 1.18 + _cell_hash_float(cell, 151) * 0.14
			_draw_texture_centered(DIRT_PATH_PATCH_TEXTURE, position, Vector2(width * length_scale, width * width_scale), rotation, Color(0.86, 0.74, 0.54, 0.48))

func _points_bounds(points: Array[Vector2]) -> Rect2:
	if points.is_empty():
		return Rect2()
	var min_position := points[0]
	var max_position := points[0]
	for i in range(1, points.size()):
		var point := points[i]
		min_position.x = minf(min_position.x, point.x)
		min_position.y = minf(min_position.y, point.y)
		max_position.x = maxf(max_position.x, point.x)
		max_position.y = maxf(max_position.y, point.y)
	return Rect2(min_position, max_position - min_position)

func _draw_ground_detail(visible: Rect2) -> void:
	pass

func _draw_terrain_hazards(visible: Rect2) -> void:
	if _terrain_hazard_renderer == null:
		return
	var cell_size: float = _terrain_hazard_renderer.get_cell_size()
	var padded: Rect2 = visible.grow(cell_size)
	var min_cell: Vector2i = Vector2i(floori(padded.position.x / cell_size), floori(padded.position.y / cell_size))
	var max_cell: Vector2i = Vector2i(floori((padded.position.x + padded.size.x) / cell_size), floori((padded.position.y + padded.size.y) / cell_size))
	for cy in range(min_cell.y, max_cell.y + 1):
		for cx in range(min_cell.x, max_cell.x + 1):
			var cell: Vector2i = Vector2i(cx, cy)
			if _terrain_hazard_renderer.hazard_cells.has(cell):
				_draw_hazard_cell(cell, _terrain_hazard_renderer.hazard_cells[cell], cell_size)

func _draw_hazard_cell(cell: Vector2i, data: Dictionary, cell_size: float) -> void:
	var hazard_type: String = String(data.get("hazard_type", "none"))
	var pos: Vector2 = Vector2(float(cell.x) * cell_size, float(cell.y) * cell_size)
	var center: Vector2 = pos + Vector2(cell_size * 0.5, cell_size * 0.5)
	match hazard_type:
		"damage":
			draw_circle(center, cell_size * 0.48, Color(0.55, 0.12, 0.04, 0.18))
			draw_arc(center, cell_size * 0.35, 0.0, TAU, 28, Color(0.95, 0.42, 0.12, 0.46), 2.0)
		"slow":
			draw_circle(center, cell_size * 0.48, Color(0.12, 0.32, 0.08, 0.16))
			var crack_color: Color = Color(0.42, 0.74, 0.28, 0.34)
			draw_line(center, pos + Vector2(cell_size * 0.18, cell_size * 0.28), crack_color, 1.4)
			draw_line(center, pos + Vector2(cell_size * 0.82, cell_size * 0.72), crack_color, 1.4)
			draw_line(center, pos + Vector2(cell_size * 0.62, cell_size * 0.14), crack_color, 1.0)
		"block":
			_draw_wall_obstacle(cell, center, cell_size)

func _draw_grid(visible: Rect2) -> void:
	var clipped := _play_area.intersection(visible)
	if clipped.size.x <= 0.0 or clipped.size.y <= 0.0:
		return
	var quality := _effects_quality()
	var minor_step := 60.0 if SettingsStore.animations_on and quality >= 2 else 120.0
	if SettingsStore.animations_on and quality == 1:
		minor_step = 90.0
	var minor_start_x: float = floor((clipped.position.x + _grid_offset.x) / minor_step) * minor_step - _grid_offset.x
	var minor_end_x := clipped.position.x + clipped.size.x
	var minor_x: float = minor_start_x
	while minor_x <= minor_end_x:
		draw_line(Vector2(minor_x, clipped.position.y), Vector2(minor_x, clipped.position.y + clipped.size.y), Color(0.08, 0.18, 0.17, 0.10), 1.0)
		minor_x += minor_step

	var minor_start_y: float = floor((clipped.position.y + _grid_offset.y) / minor_step) * minor_step - _grid_offset.y
	var minor_end_y := clipped.position.y + clipped.size.y
	var minor_y: float = minor_start_y
	while minor_y <= minor_end_y:
		draw_line(Vector2(clipped.position.x, minor_y), Vector2(clipped.position.x + clipped.size.x, minor_y), Color(0.08, 0.18, 0.17, 0.10), 1.0)
		minor_y += minor_step

	var step := 240.0
	var start_x: float = floor((clipped.position.x + _grid_offset.x) / step) * step - _grid_offset.x
	var end_x := clipped.position.x + clipped.size.x
	var x: float = start_x
	while x <= end_x:
		var line_alpha := 0.22 + 0.06 * sin(_world_time * 1.6 + x * 0.01)
		draw_line(Vector2(x, clipped.position.y), Vector2(x, clipped.position.y + clipped.size.y), Color(0.13, 0.42, 0.34, line_alpha), 1.0)
		x += step

	var start_y: float = floor((clipped.position.y + _grid_offset.y) / step) * step - _grid_offset.y
	var end_y := clipped.position.y + clipped.size.y
	var y: float = start_y
	while y <= end_y:
		var line_alpha := 0.22 + 0.06 * sin(_world_time * 1.6 + y * 0.01)
		draw_line(Vector2(clipped.position.x, y), Vector2(clipped.position.x + clipped.size.x, y), Color(0.13, 0.42, 0.34, line_alpha), 1.0)
		y += step

func _draw_food(visible: Rect2) -> void:
	var visible_indices := _food_indices_for_rect(visible)
	var detail_level := _food_detail_level(visible_indices.size())
	for index in visible_indices:
		var food: FoodDot = _foods[index]
		if food.radius <= 0.0:
			continue
		var pulse := _food_pulse(index)
		if detail_level >= 1:
			draw_circle(food.position, food.radius * (3.0 + pulse * 1.2), Color(food.color.r, food.color.g, food.color.b, 0.08 + pulse * 0.06))
		if food.kind != "energy":
			draw_arc(food.position, food.radius * (2.35 + pulse * 0.35), 0.0, TAU, 24, _color_alpha(food.color.lightened(0.18), 0.52), 2.0)
		draw_circle(food.position, food.radius + 2.4, Color(0.0, 0.0, 0.0, 0.22))
		_draw_texture_centered(FOOD_SEED_TEXTURE, food.position, Vector2.ONE * maxf(22.0, food.radius * 6.6), 0.0, food.color.lightened(0.08))
		if detail_level >= 2:
			draw_circle(food.position - Vector2(food.radius * 0.24, food.radius * 0.24), maxf(1.0, food.radius * 0.34), Color(1.0, 1.0, 1.0, 0.42))

func _draw_snake(agent: SnakeAgent, is_player: bool) -> void:
	if agent.dead:
		return
	var use_player_skin := _agent_uses_player_skin(agent)
	var base_color: Color = agent.color
	if agent.blink and not is_player:
		base_color.a = 0.45 + 0.55 * abs(sin(_world_time * 7.0))
	var death_progress: float = clampf(agent.death_timer / AI_DEATH_DISSOLVE_TIME, 0.0, 1.0) if agent.dying else 0.0
	var death_alpha: float = 1.0 - death_progress
	base_color.a *= death_alpha
	var segment_count: int = agent.segments.size()
	var point_count: int = segment_count + 1
	var body_texture: Texture2D = _snake_body_texture_for_agent(agent, use_player_skin)

	if segment_count > 0:
		for i in range(segment_count - 1, -1, -1):
			var current: Vector2 = agent.segments[i]
			var previous: Vector2 = agent.position if i == 0 else agent.segments[i - 1]
			var ratio: float = float(i + 1) / float(point_count)
			var width: float = _visual_radius_for_agent(agent, ratio) * 1.84 * (1.0 - death_progress * 0.32)
			draw_line(current, previous, Color(0.0, 0.0, 0.0, 0.2 * death_alpha), width + 4.0)
			draw_line(current, previous, base_color.darkened(ratio * 0.22), width)

	for i in range(segment_count - 1, -1, -1):
		var ratio: float = float(i + 1) / float(segment_count + 1)
		var segment_radius: float = _visual_radius_for_agent(agent, ratio) * (1.0 - death_progress * 0.4)
		var dissolve_offset: Vector2 = Vector2.ZERO
		if agent.dying:
			dissolve_offset = Vector2.RIGHT.rotated(float(i) * 2.399 + _world_time * 1.6) * death_progress * agent.radius * 0.22
		var segment_position: Vector2 = agent.segments[i] + dissolve_offset
		var next_point: Vector2 = agent.position if i == 0 else agent.segments[i - 1]
		var previous_point: Vector2 = agent.segments[i + 1] if i + 1 < segment_count else segment_position - agent.direction * GameConfigData.SNAKE_SEGMENT_SPACING
		var segment_direction: Vector2 = (next_point - previous_point).normalized()
		if segment_direction.length_squared() <= 0.001:
			segment_direction = agent.direction
		_draw_snake_body_segment(segment_position, segment_direction.rotated(BODY_RENDER_ROTATION_OFFSET), segment_radius, body_texture, use_player_skin, base_color, death_alpha)

	if is_player and _invulnerability_timer > 0.0:
		var pulse: float = 0.5 + 0.5 * sin((GameConfigData.COLLISION_GRACE_PERIOD - _invulnerability_timer) * 8.0)
		var shield_arc_points: int = 48 if _effects_quality() >= 2 else 32
		_draw_texture_centered(SHIELD_RING_TEXTURE, agent.position, Vector2.ONE * agent.radius * (4.2 + pulse * 0.24), 0.0, Color(0.8, 1.0, 1.0, 0.62))
		draw_arc(agent.position, agent.radius * (1.35 + pulse * 0.08), 0.0, TAU, shield_arc_points, Color(0.62, 0.98, 1.0, 0.72), 2.0)

	if is_player and _is_boosting():
		var boost_pulse: float = 0.5 + 0.5 * sin(_world_time * 20.0)
		var boost_arc_points: int = 42 if _effects_quality() >= 2 else 28
		_draw_texture_centered(BOOST_PUFF_TEXTURE, agent.position - agent.direction.normalized() * agent.radius * 1.6, Vector2(agent.radius * 3.8, agent.radius * 2.5), agent.direction.angle() - PI, Color(0.75, 1.0, 0.78, 0.62))
		draw_arc(agent.position, agent.radius * (1.28 + boost_pulse * 0.06), -PI * 0.15, TAU - PI * 0.15, boost_arc_points, Color(0.72, 1.0, 0.45, 0.58), 2.5)

	var head_radius: float = _visual_radius_for_agent(agent, 0.0) * (1.0 - death_progress * 0.28)
	_draw_snake_head(agent, head_radius, is_player, use_player_skin, base_color, death_alpha)
	if agent.team == "enemy" and not agent.dying and agent.max_health > 1:
		var width: float = head_radius * (2.2 if agent.is_boss else 1.55)
		var top: Vector2 = agent.position + Vector2(-width * 0.5, -head_radius * 2.0)
		draw_rect(Rect2(top, Vector2(width, 5.0)), Color(0.0, 0.0, 0.0, 0.42), true)
		draw_rect(Rect2(top, Vector2(width * clampf(float(agent.health) / float(agent.max_health), 0.0, 1.0), 5.0)), Color(1.0, 0.36, 0.2, 0.86), true)

func _draw_snake_head(agent: SnakeAgent, head_radius: float, is_player: bool, use_player_skin: bool, base_color: Color, alpha: float) -> void:
	var dir: Vector2 = agent.direction.normalized()
	if dir.length_squared() <= 0.001:
		dir = Vector2.DOWN
	var texture: Texture2D = _snake_head_texture_for_agent(agent, use_player_skin)
	var tint := base_color.lightened(0.06)
	tint.a *= alpha
	var scale: float = 3.25 if is_player else (3.45 if agent.is_boss else 3.05)
	var head_size := Vector2(head_radius * scale * 0.72, head_radius * scale)
	draw_circle(agent.position + Vector2(6.0, 10.0), head_radius * 1.42, Color(0.0, 0.0, 0.0, 0.28 * alpha))
	_draw_texture_centered(texture, agent.position, head_size, _texture_rotation_for_direction(dir), tint)
	_draw_snake_head_lighting(agent.position, dir, head_radius * 1.04, alpha)

func _agent_uses_player_skin(agent: SnakeAgent) -> bool:
	return agent == _player or agent.team == "follower"

func _snake_uses_elite_texture(agent: SnakeAgent) -> bool:
	return agent.is_elite or agent.is_boss or (agent.color.r > 0.75 and agent.color.b > 0.55)

func _snake_head_texture_for_agent(agent: SnakeAgent, use_player_skin: bool) -> Texture2D:
	if use_player_skin:
		return PLAYER_HEAD_TEXTURE
	if _snake_uses_elite_texture(agent):
		return ELITE_HEAD_TEXTURE
	return AI_HEAD_TEXTURE

func _snake_body_texture_for_agent(agent: SnakeAgent, use_player_skin: bool) -> Texture2D:
	if use_player_skin:
		return PLAYER_BODY_TEXTURE
	if _snake_uses_elite_texture(agent):
		return ELITE_BODY_TEXTURE
	return AI_BODY_TEXTURE

func _draw_snake_body_segment(position: Vector2, direction: Vector2, radius: float, texture: Texture2D, is_player: bool, base_color: Color, alpha: float) -> void:
	var safe_dir: Vector2 = direction.normalized()
	if safe_dir.length_squared() <= 0.001:
		safe_dir = Vector2.DOWN
	var tint := base_color.lightened(0.08 if is_player else 0.06)
	tint.a *= alpha
	var body_size := Vector2(GameConfigData.SNAKE_SEGMENT_SPACING * 1.28, radius * 2.18)
	draw_circle(position + Vector2(4.0, 7.0), radius * 1.27, Color(0.0, 0.0, 0.0, 0.24 * alpha))
	_draw_texture_centered(texture, position, body_size, _texture_rotation_for_direction(safe_dir), tint)

func _draw_forest_obstacle(cell: Vector2i, center: Vector2, cell_size: float) -> void:
	_draw_wall_obstacle(cell, center, cell_size)

func _draw_forest_foreground(visible: Rect2) -> void:
	pass

func _draw_wall_obstacle(cell: Vector2i, center: Vector2, cell_size: float) -> void:
	var base_size := cell_size * (0.9 + _cell_hash_float(cell, 19) * 0.05)
	var rect := Rect2(center - Vector2.ONE * base_size * 0.5, Vector2.ONE * base_size)
	var bevel := cell_size * 0.14
	var top_lift := cell_size * (0.12 + _cell_hash_float(cell, 31) * 0.08)
	var shadow_rect := rect.grow(cell_size * 0.08)
	shadow_rect.position += Vector2(cell_size * 0.16, cell_size * 0.2)
	draw_rect(shadow_rect, Color(0.0, 0.0, 0.0, 0.34), true)
	draw_rect(rect, Color(0.012, 0.032, 0.036, 0.98), true)
	var top_points: PackedVector2Array = [
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + Vector2(rect.size.x - bevel, bevel + top_lift),
		rect.position + Vector2(bevel, bevel + top_lift),
	]
	draw_colored_polygon(top_points, Color(0.035, 0.11, 0.105, 0.96))
	var side_points: PackedVector2Array = [
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + rect.size - Vector2(bevel, bevel),
		rect.position + Vector2(rect.size.x - bevel, bevel + top_lift),
	]
	draw_colored_polygon(side_points, Color(0.006, 0.018, 0.022, 0.98))
	var rim_alpha := 0.42 + 0.12 * sin(_world_time * 2.4 + float(cell.x * 3 + cell.y * 5))
	draw_rect(rect, Color(0.14, 0.95, 0.62, rim_alpha), false, 1.4)
	if _cell_hash_int(cell, 5) == 0:
		var glint_y := rect.position.y + rect.size.y * (0.28 + _cell_hash_float(cell, 53) * 0.28)
		draw_line(Vector2(rect.position.x + cell_size * 0.16, glint_y), Vector2(rect.position.x + rect.size.x - cell_size * 0.18, glint_y), Color(0.6, 1.0, 0.78, 0.16), 1.2)

func _draw_aligned_tiled_texture(texture: Texture2D, rect: Rect2, tile_size: float, modulate: Color = Color.WHITE) -> void:
	if texture == null or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var start := Vector2(
		floor(rect.position.x / tile_size) * tile_size,
		floor(rect.position.y / tile_size) * tile_size
	)
	var end := rect.position + rect.size
	var y := start.y
	while y < end.y:
		var x := start.x
		while x < end.x:
			var tile_rect := Rect2(Vector2(x, y), Vector2(tile_size, tile_size))
			var clipped := tile_rect.intersection(rect)
			if clipped.size.x > 0.0 and clipped.size.y > 0.0:
				var source_position := (clipped.position - tile_rect.position) / tile_size * texture_size
				var source_size := clipped.size / tile_size * texture_size
				draw_texture_rect_region(texture, clipped, Rect2(source_position, source_size), modulate)
			x += tile_size
		y += tile_size

func _cell_hash_int(cell: Vector2i, modulo: int) -> int:
	var value := int(abs(cell.x * 73856093) + abs(cell.y * 19349663) + 83492791)
	if modulo <= 0:
		return value
	return value % modulo

func _cell_hash_float(cell: Vector2i, salt: int = 0) -> float:
	var value := int(cell.x * 92837111) ^ int(cell.y * 689287499) ^ int(salt * 283923481)
	value = abs(value % 1000003)
	value = (value * 110351 + 12345) % 1000003
	return float(value) / 1000003.0

func _draw_snake_head_lighting(position: Vector2, direction: Vector2, radius: float, alpha: float) -> void:
	var safe_dir: Vector2 = direction.normalized()
	if safe_dir.length_squared() <= 0.001:
		safe_dir = Vector2.DOWN
	var side: Vector2 = safe_dir.orthogonal()
	draw_arc(position - safe_dir * radius * 0.12, radius * 1.02, -PI * 0.86, PI * 0.08, 24, _color_alpha(Color(0.78, 1.0, 0.68), 0.28 * alpha), maxf(1.5, radius * 0.1))
	draw_arc(position + safe_dir * radius * 0.2, radius * 1.15, PI * 0.16, PI * 1.08, 24, _color_alpha(Color(0.0, 0.02, 0.012), 0.24 * alpha), maxf(1.5, radius * 0.11))
	for side_sign in [-1.0, 1.0]:
		var glow_center: Vector2 = position + safe_dir * radius * 0.28 + side * radius * 0.52 * side_sign
		draw_circle(glow_center, radius * 0.14, _color_alpha(Color(0.18, 1.0, 0.78), 0.22 * alpha))

func _visible_world_rect() -> Rect2:
	var size := get_viewport_rect().size
	if _camera != null:
		size /= _camera.zoom
		return Rect2(_camera.position - size * 0.5, size)
	return Rect2(Vector2.ZERO, size)

func _initialize_food_pulse_table() -> void:
	_food_pulse_table.clear()
	for i in range(FOOD_PULSE_TABLE_SIZE):
		_food_pulse_table.append(0.5 + 0.5 * sin(float(i) * TAU / float(FOOD_PULSE_TABLE_SIZE)))

func _food_pulse(index: int) -> float:
	if _food_pulse_table.is_empty():
		return 0.5
	var frame := int(_world_time * 30.0)
	return float(_food_pulse_table[(frame + index * 7) % FOOD_PULSE_TABLE_SIZE])

func _refresh_visible_food_cache(rect: Rect2) -> void:
	if _visible_food_cache_valid and _rect_covers(_visible_food_rect, rect):
		return
	_visible_food_rect = rect
	_food_grid.query_rect_into(rect, _visible_food_indices)
	_visible_food_cache_valid = true

func _food_indices_for_rect(rect: Rect2) -> Array:
	if _visible_food_cache_valid and _rect_covers(_visible_food_rect, rect):
		return _visible_food_indices
	_food_grid.query_rect_into(rect, _food_query_indices)
	return _food_query_indices

func _rect_covers(outer: Rect2, inner: Rect2) -> bool:
	return inner.position.x >= outer.position.x \
		and inner.position.y >= outer.position.y \
		and inner.position.x + inner.size.x <= outer.position.x + outer.size.x \
		and inner.position.y + inner.size.y <= outer.position.y + outer.size.y

func _food_detail_level(visible_count: int) -> int:
	if not SettingsStore.animations_on:
		return 0
	var quality := _effects_quality()
	if quality <= 0:
		return 0
	if quality == 1:
		return 1 if visible_count <= BALANCED_FOOD_GLOW_LIMIT else 0
	if visible_count <= LOW_FOOD_GLOW_LIMIT:
		return 2
	if visible_count <= FULL_FOOD_GLOW_LIMIT:
		return 1
	return 0

func _effects_quality() -> int:
	return GameConfigData.clamp_effects_quality(SettingsStore.effects_quality)

func _particle_budget() -> int:
	if not SettingsStore.animations_on:
		return LOW_PARTICLE_BUDGET
	match _effects_quality():
		0:
			return LOW_PARTICLE_BUDGET
		1:
			return BALANCED_PARTICLE_BUDGET
	return MAX_VFX_PARTICLES

func _shockwave_budget() -> int:
	if not SettingsStore.animations_on:
		return LOW_SHOCKWAVE_BUDGET
	match _effects_quality():
		0:
			return LOW_SHOCKWAVE_BUDGET
		1:
			return BALANCED_SHOCKWAVE_BUDGET
	return MAX_SHOCKWAVES

func _is_snake_visible(agent: SnakeAgent, visible: Rect2) -> bool:
	if visible.has_point(agent.position):
		return true
	for segment in agent.segments:
		if visible.has_point(segment):
			return true
	return false

func _draw_texture_centered(texture: Texture2D, position: Vector2, size: Vector2, rotation: float = 0.0, modulate: Color = Color.WHITE) -> void:
	if texture == null:
		return
	draw_set_transform(position, rotation, Vector2.ONE)
	draw_texture_rect(texture, Rect2(-size * 0.5, size), false, modulate)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _texture_rotation_for_direction(direction: Vector2) -> float:
	if direction.length_squared() <= 0.001:
		return 0.0
	return direction.angle() - Vector2.DOWN.angle()

func _random_position_in_play_area() -> Vector2:
	for i in range(48):
		var position := Vector2(
			randf_range(_play_area.position.x, _play_area.position.x + _play_area.size.x),
			randf_range(_play_area.position.y, _play_area.position.y + _play_area.size.y)
		)
		if _is_spawn_position_clear(position, 28.0):
			return position
	return _play_area.get_center()

func _random_ai_spawn_position() -> Vector2:
	for i in range(32):
		var position := Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(420.0, GameConfigData.AI_SPAWN_RADIUS)
		if _play_area.has_point(position) and position.distance_to(_player.position) > 360.0 and _is_spawn_position_clear(position, GameConfigData.INITIAL_SNAKE_RADIUS * 1.6):
			return position
	return _random_position_in_play_area()

func _is_spawn_position_clear(position: Vector2, radius: float) -> bool:
	if not _play_area.has_point(position):
		return false
	if _terrain_hazard_renderer == null:
		return true
	return _terrain_hazard_renderer.get_blocking_cell_near_position(position, radius).is_empty()

func _point_on_play_area_perimeter(distance: float) -> Vector2:
	var width := _play_area.size.x
	var height := _play_area.size.y
	var left := _play_area.position.x
	var top := _play_area.position.y
	var right := left + width
	var bottom := top + height

	if distance < width:
		return Vector2(left + distance, top)
	distance -= width
	if distance < height:
		return Vector2(right, top + distance)
	distance -= height
	if distance < width:
		return Vector2(right - distance, bottom)
	distance -= width
	return Vector2(left, bottom - distance)

func _boundary_outward_normal(position: Vector2) -> Vector2:
	var left_distance: float = abs(position.x - _play_area.position.x)
	var right_distance: float = abs(position.x - (_play_area.position.x + _play_area.size.x))
	var top_distance: float = abs(position.y - _play_area.position.y)
	var bottom_distance: float = abs(position.y - (_play_area.position.y + _play_area.size.y))
	var best: float = minf(minf(left_distance, right_distance), minf(top_distance, bottom_distance))
	if best == left_distance:
		return Vector2.LEFT
	if best == right_distance:
		return Vector2.RIGHT
	if best == top_distance:
		return Vector2.UP
	return Vector2.DOWN

func _edge_warning_ratio() -> float:
	var left_distance: float = _player.position.x - _play_area.position.x
	var right_distance: float = _play_area.position.x + _play_area.size.x - _player.position.x
	var top_distance: float = _player.position.y - _play_area.position.y
	var bottom_distance: float = _play_area.position.y + _play_area.size.y - _player.position.y
	var nearest := minf(minf(left_distance, right_distance), minf(top_distance, bottom_distance))
	return clampf(1.0 - nearest / 420.0, 0.0, 1.0)

func _wall_avoidance_direction(position: Vector2, preferred: Vector2) -> Vector2:
	var warning := 320.0
	var avoidance := Vector2.ZERO
	if position.x < _play_area.position.x + warning:
		avoidance.x += 1.0
	if position.x > _play_area.position.x + _play_area.size.x - warning:
		avoidance.x -= 1.0
	if position.y < _play_area.position.y + warning:
		avoidance.y += 1.0
	if position.y > _play_area.position.y + _play_area.size.y - warning:
		avoidance.y -= 1.0
	if avoidance.length_squared() <= 0.001:
		return preferred
	return (preferred + avoidance.normalized() * 0.75).normalized()

func _avoid_blocking_hazards(position: Vector2, preferred: Vector2, radius: float) -> Vector2:
	if _terrain_hazard_renderer == null:
		return preferred
	var safe_preferred := preferred.normalized() if preferred.length_squared() > 0.001 else Vector2.DOWN
	var probe := position + safe_preferred * AI_OBSTACLE_PROBE_DISTANCE
	if _terrain_hazard_renderer.get_blocking_cell_near_position(probe, radius).is_empty():
		return safe_preferred
	var left := safe_preferred.rotated(PI * 0.5)
	var right := safe_preferred.rotated(-PI * 0.5)
	var left_hit := _terrain_hazard_renderer.get_blocking_cell_near_position(position + left * AI_OBSTACLE_PROBE_DISTANCE, radius)
	var right_hit := _terrain_hazard_renderer.get_blocking_cell_near_position(position + right * AI_OBSTACLE_PROBE_DISTANCE, radius)
	if left_hit.is_empty() and not right_hit.is_empty():
		return (safe_preferred * 0.35 + left).normalized()
	if right_hit.is_empty() and not left_hit.is_empty():
		return (safe_preferred * 0.35 + right).normalized()
	return safe_preferred.rotated(0.72 if randf() < 0.5 else -0.72).normalized()

func _smooth_direction(current: Vector2, target: Vector2, weight: float) -> Vector2:
	var normalized_current := current.normalized() if current.length_squared() > 0.001 else target.normalized()
	var normalized_target := target.normalized()
	if normalized_current.dot(normalized_target) <= -0.999:
		normalized_target = Vector2(-normalized_current.y, normalized_current.x)
	return normalized_current.lerp(normalized_target, clampf(weight, 0.0, 1.0)).normalized()

func _is_circle_inside_play_area(position: Vector2, radius: float) -> bool:
	return position.x - radius >= _play_area.position.x \
		and position.y - radius >= _play_area.position.y \
		and position.x + radius <= _play_area.position.x + _play_area.size.x \
		and position.y + radius <= _play_area.position.y + _play_area.size.y

func _circles_overlap(a_position: Vector2, a_radius: float, b_position: Vector2, b_radius: float) -> bool:
	var radius := a_radius + b_radius
	return a_position.distance_squared_to(b_position) <= radius * radius

func _preallocate_pools() -> void:
	for i in range(PARTICLE_POOL_SIZE):
		_particle_pool.append(VfxParticle.new())
	for i in range(SHOCKWAVE_POOL_SIZE):
		_shockwave_pool.append(Shockwave.new())

func _get_particle(initial_position := Vector2.ZERO, initial_velocity := Vector2.ZERO, initial_color := Color.WHITE, initial_radius := 4.0, initial_lifetime := 0.4, initial_drag := 0.9) -> VfxParticle:
	var particle: VfxParticle
	if not _particle_pool.is_empty():
		particle = _particle_pool.pop_back()
	else:
		particle = VfxParticle.new()
	particle.position = initial_position
	particle.velocity = initial_velocity
	particle.color = initial_color
	particle.radius = initial_radius
	particle.lifetime = initial_lifetime
	particle.age = 0.0
	particle.drag = initial_drag
	return particle

func _return_particle(particle: VfxParticle) -> void:
	if _particle_pool.size() < PARTICLE_POOL_SIZE:
		_particle_pool.append(particle)

func _get_shockwave(initial_position := Vector2.ZERO, initial_color := Color.WHITE, initial_max_radius := 120.0, initial_lifetime := 0.42) -> Shockwave:
	var shockwave: Shockwave
	if not _shockwave_pool.is_empty():
		shockwave = _shockwave_pool.pop_back()
	else:
		shockwave = Shockwave.new()
	shockwave.position = initial_position
	shockwave.color = initial_color
	shockwave.max_radius = initial_max_radius
	shockwave.lifetime = initial_lifetime
	shockwave.age = 0.0
	return shockwave

func _return_shockwave(shockwave: Shockwave) -> void:
	if _shockwave_pool.size() < SHOCKWAVE_POOL_SIZE:
		_shockwave_pool.append(shockwave)
