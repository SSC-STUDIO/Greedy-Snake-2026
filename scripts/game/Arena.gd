extends Node2D

const GameConfigData := preload("res://scripts/data/GameConfig.gd")
const UpgradeCatalogData := preload("res://scripts/data/UpgradeCatalog.gd")
const RunDataUtil := preload("res://scripts/data/RunData.gd")
const TerrainCatalogData := preload("res://scripts/data/TerrainCatalog.gd")
const UPGRADE_PICKER_SCRIPT := preload("res://scripts/ui/UpgradePicker.gd")
const HUD_SCENE := preload("res://scenes/ui/Hud.tscn")
const PAUSE_SCENE := preload("res://scenes/ui/PauseOverlay.tscn")
const GAME_OVER_SCENE := preload("res://scenes/ui/GameOverDialog.tscn")
const ENVIRONMENT_ATLAS := preload("res://assets/generated/neon_ecology/environment_tiles_atlas.png")
const PLAYER_HEAD_TEXTURE := preload("res://assets/generated/neon_ecology/slices/player_head.png")
const PLAYER_BODY_TEXTURE := preload("res://assets/generated/neon_ecology/slices/player_body.png")
const AI_HEAD_TEXTURE := preload("res://assets/generated/neon_ecology/slices/ai_head.png")
const ELITE_HEAD_TEXTURE := preload("res://assets/generated/neon_ecology/slices/elite_head.png")
const FOOD_SEED_TEXTURE := preload("res://assets/generated/neon_ecology/slices/food_seed.png")
const SHIELD_RING_TEXTURE := preload("res://assets/generated/neon_ecology/slices/shield_ring.png")
const BOOST_PUFF_TEXTURE := preload("res://assets/generated/neon_ecology/slices/boost_puff.png")
const MAX_VFX_PARTICLES := 260
const MAX_SHOCKWAVES := 18
const LAVA_EDGE_WIDTH := 220.0
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
const BOSS_WAVE := 4
const AI_DEATH_DISSOLVE_TIME := 0.72

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

func _ready() -> void:
	randomize()
	_modifiers = RunDataUtil.new_modifier_state()
	_wave_state = RunDataUtil.new_wave_state()
	_run_stats = RunDataUtil.new_run_stats()
	_initialize_food_pulse_table()
	AudioBus.play_bgm()
	_play_area = GameConfigData.play_area_rect()
	_terrain_regions = TerrainCatalogData.terrain_regions(_play_area)
	_difficulty = GameConfigData.difficulty(SettingsStore.difficulty)
	_base_player_speed = GameConfigData.player_speed_for(SettingsStore.snake_speed, SettingsStore.difficulty)
	_grid_offset = Vector2(randf_range(0.0, 240.0), randf_range(0.0, 240.0))

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
	_queue_story(TerrainCatalogData.START_STORY, 3.2, "start", 999.0)
	_update_terrain_state()
	_spawn_foods()
	_spawn_ai_snakes()
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
	_update_player(clamped_delta)
	_update_terrain_state()
	_update_ai(clamped_delta)
	_refresh_visible_food_cache(_visible_world_rect().grow(VISIBLE_FOOD_MARGIN))
	_update_magnet_pickups(clamped_delta)
	_update_companions(clamped_delta)
	_check_food_collisions()
	_check_snake_collisions()
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
	_draw_shockwaves()
	_draw_food(visible)
	var snake_visible := visible.grow(260.0)
	for ai in _ai_snakes:
		if _is_snake_visible(ai, snake_visible):
			_draw_snake(ai, false)
	_draw_snake(_player, true)
	_draw_companions()
	_draw_particles()

func _reset_player() -> void:
	_player = SnakeAgent.new()
	_player.position = Vector2.ZERO
	_player.previous_position = _player.position
	_player.direction = Vector2.DOWN
	_player.color = Color(0.08, 0.86, 0.42)
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
	_follow_segments(_player)

	if _invulnerability_timer > 0.0:
		_invulnerability_timer = maxf(0.0, _invulnerability_timer - delta)

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
		var to_player: Vector2 = _player.position - ai.position
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
			var target: Vector2 = ai.direction
			if distance_squared > 100.0 * 100.0 and randf() < ai.aggression * 0.5:
				target = to_player / sqrt(distance_squared)
			elif randf() < 0.55:
				target = ai.direction.rotated(randf_range(-PI / 3.0, PI / 3.0)).normalized()
			target = _wall_avoidance_direction(ai.position, target)
			ai.direction = _smooth_direction(ai.direction, target, 0.18)

		var pressure := float(_wave_state.get("pressure", 1.0))
		if ai.is_boss:
			ai.phase_timer += delta
			if ai.phase_timer >= 5.5:
				ai.phase_timer = 0.0
				ai.direction = (_player.position - ai.position).normalized()
				_spawn_warning_ring(ai.position, Color(1.0, 0.32, 0.14))
			elif ai.phase_timer < 0.55:
				pressure += 0.75
		var speed: float = _base_player_speed * ai.speed_multiplier * pressure * _terrain_speed_multiplier(ai.position)
		ai.position += ai.direction * speed * delta
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

func _update_ai_death(ai: SnakeAgent, delta: float) -> void:
	ai.death_timer += delta
	if not ai.drop_done:
		_drop_food_for_snake(ai, ai.drop_value)
		_spawn_death_followups(ai)
		ai.drop_done = true
	ai.body_timer -= delta
	if ai.body_timer <= 0.0:
		_spawn_snake_dissolve_sparks(ai)
		ai.body_timer = 0.055 if SettingsStore.animations_on else 0.16
	if ai.death_timer >= AI_DEATH_DISSOLVE_TIME:
		ai.dead = true

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

func _check_snake_collisions() -> void:
	_refresh_player_body_bounds()
	var player_body_radius: float = _player.radius * 0.82
	var has_player_body := not _player.segments.is_empty()
	for ai in _ai_snakes:
		if ai.dead or ai.dying:
			continue
		if _circles_overlap(_player.position, _player.radius, ai.position, ai.radius):
			if not _resolve_player_enemy_contact(ai):
				return

		var ai_body_radius: float = ai.radius * 0.82
		for segment in ai.segments:
			if _circles_overlap(_player.position, _player.radius, segment, ai_body_radius):
				if not _resolve_player_enemy_contact(ai):
					return

		if has_player_body and _player_body_bounds.grow(ai.radius + player_body_radius).has_point(ai.position):
			for player_segment in _player.segments:
				if _circles_overlap(ai.position, ai.radius, player_segment, player_body_radius):
					if not _resolve_player_enemy_contact(ai):
						return
					break

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
		_set_event("Emergency shield")
		_spawn_warning_ring(_player.position, Color(0.62, 1.0, 0.96))

	_lava_timer += delta
	_start_screen_shake(1.4 + _lava_timer * 0.35, 0.08)
	_spawn_lava_warning_sparks(delta)
	if _lava_timer >= float(_difficulty.get("lava_warning_time", 5.0)):
		_trigger_game_over("Lava")

func _update_effects(delta: float) -> void:
	_world_time += delta

	for i in range(_particles.size() - 1, -1, -1):
		var particle: VfxParticle = _particles[i]
		particle.update(delta)
		if not particle.alive():
			_particles.remove_at(i)

	for i in range(_shockwaves.size() - 1, -1, -1):
		var shockwave: Shockwave = _shockwaves[i]
		shockwave.update(delta)
		if not shockwave.alive():
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
	_foods.append(_make_food(ai.position + Vector2(randf_range(-18.0, 18.0), randf_range(-18.0, 18.0))))
	var remaining := amount - 1
	var segment_index := 0
	while remaining > 0 and segment_index < ai.segments.size():
		_foods.append(_make_food(ai.segments[segment_index] + Vector2(randf_range(-18.0, 18.0), randf_range(-18.0, 18.0))))
		remaining -= 1
		segment_index += 1
	while _foods.size() > GameConfigData.MAX_FOOD_COUNT:
		_foods.pop_front()
	_food_grid.build(_foods)
	_visible_food_cache_valid = false

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
	_wave_state["elapsed"] = float(_wave_state.get("elapsed", 0.0)) + delta
	var elapsed := float(_wave_state.get("elapsed", 0.0))
	while elapsed >= float(_wave_state.get("next_wave_time", 60.0)):
		_wave_state["wave"] = int(_wave_state.get("wave", 1)) + 1
		_wave_state["pressure"] = 1.0 + float(int(_wave_state.get("wave", 1)) - 1) * 0.1
		_wave_state["next_wave_time"] = float(_wave_state.get("next_wave_time", 60.0)) + 60.0
		_spawn_reinforcements(2 + int(_wave_state.get("wave", 1)))
		_set_event("Wave %d" % int(_wave_state.get("wave", 1)))
		_queue_story(TerrainCatalogData.wave_story(int(_wave_state.get("wave", 1))), 3.0, "wave_%d" % int(_wave_state.get("wave", 1)), 999.0)
	if elapsed >= float(_wave_state.get("next_elite_time", 42.0)):
		_spawn_elite()
		_wave_state["next_elite_time"] = elapsed + maxf(32.0, 70.0 - float(_wave_state.get("wave", 1)) * 5.0)
	if not bool(_wave_state.get("boss_warning", false)) and int(_wave_state.get("wave", 1)) >= BOSS_WAVE - 1:
		_wave_state["boss_warning"] = true
		_set_event("Boss signal detected", 4.0)
		_queue_story("A rogue core is waking below the ecology grid.", 3.0, "boss_warning", 999.0)
	if not bool(_wave_state.get("boss_spawned", false)) and int(_wave_state.get("wave", 1)) >= BOSS_WAVE:
		_spawn_boss()

func _spawn_reinforcements(count: int) -> void:
	var limit := int(_difficulty.get("ai_count", 20)) + int(_wave_state.get("wave", 1)) * 4
	for i in range(count):
		if _ai_snakes.size() >= limit:
			return
		_ai_snakes.append(_make_ai_snake())

func _spawn_elite() -> void:
	var affix_count := clampi(1 + floori(float(_wave_state.get("wave", 1)) / 3.0), 1, 3)
	var affixes := UpgradeCatalogData.random_affixes(affix_count)
	var elite := _make_ai_snake(Vector2.INF, affixes, false)
	elite.score_value = 30 + int(_wave_state.get("wave", 1)) * 5
	_ai_snakes.append(elite)
	var names: Array = []
	for affix in affixes:
		names.append(String(affix.get("name", "Elite")))
	_set_event("Elite  %s" % " / ".join(names), 3.2)
	_queue_story("Mutation logged: %s elite adapting to the sector." % " / ".join(names), 2.8, "elite_story", 18.0)
	_spawn_warning_ring(elite.position, elite.color)

func _spawn_boss() -> void:
	_wave_state["boss_spawned"] = true
	var boss := _make_ai_snake(_random_ai_spawn_position(), UpgradeCatalogData.random_affixes(2), true)
	_ai_snakes.append(boss)
	_set_event("Boss Wave", 4.0)
	_queue_story("The containment core is hostile. Break its growth cycle.", 3.4, "boss_spawn", 999.0)
	_spawn_warning_ring(boss.position, Color(1.0, 0.32, 0.14))

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
		_set_event("Shield +%.0fs" % food.shield_time, 1.8)
	if food.magnet_time > 0.0:
		_magnet_timer = maxf(_magnet_timer, food.magnet_time + float(_modifiers.get("magnet_duration_bonus", 0.0)))
		_set_event("Magnet field", 1.8)
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
	_set_event("Upgrade ready", 1.4)
	_upgrade_picker.show_choices(choices, _current_build_tags())

func _select_upgrade(upgrade: Dictionary) -> void:
	if not _upgrade_choice_active:
		return
	_apply_upgrade(upgrade)
	_upgrade_choice_active = false
	_upgrade_picker.hide()
	_set_event(String(upgrade.get("name", "Upgrade")), 2.4)
	_update_hud()

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
	var companions := int(_modifiers.get("companion_count", 0))
	if companions <= 0:
		return
	_companion_timer -= delta
	if _companion_timer > 0.0:
		return
	_companion_timer = COMPANION_PICKUP_INTERVAL
	for companion_index in range(mini(companions, 4)):
		var angle := _world_time * (1.4 + companion_index * 0.18) + TAU * float(companion_index) / float(maxi(1, companions))
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
	if _try_revive("Last chance"):
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

func _damage_enemy(ai: SnakeAgent, damage: int, food_value: int) -> void:
	if ai.dead or ai.dying:
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
	_add_shockwave(Shockwave.new(position, color.lightened(0.22), radius, 0.34))
	for ai in _ai_snakes:
		if ai.dead or ai.dying:
			continue
		if position.distance_squared_to(ai.position) <= pow(radius + ai.radius, 2.0):
			if award_score:
				_damage_enemy(ai, damage, 12)
			else:
				ai.health -= damage

func _award_kill_score(ai: SnakeAgent) -> void:
	var points := int(round(float(ai.score_value) * (1.0 + float(_modifiers.get("kill_score_mult", 0.0)))))
	_score += points
	_run_stats["kills"] = int(_run_stats.get("kills", 0)) + 1
	if ai.is_elite:
		_run_stats["elite_kills"] = int(_run_stats.get("elite_kills", 0)) + 1
	if ai.is_boss:
		_run_stats["boss_kills"] = int(_run_stats.get("boss_kills", 0)) + 1
		_wave_state["boss_defeated"] = true
		_set_event("Boss defeated", 4.0)
		_queue_story("Rogue core suppressed. SECTOR A-01 is breathing again.", 3.4, "boss_defeated", 999.0)

func _spawn_death_followups(ai: SnakeAgent) -> void:
	if ai.death_explosion > 0.0:
		_area_blast(ai.position, ai.death_explosion + float(_modifiers.get("kill_explosion", 0.0)), 1, ai.color)
	elif float(_modifiers.get("kill_explosion", 0.0)) > 0.0:
		_area_blast(ai.position, float(_modifiers.get("kill_explosion", 0.0)), 1, ai.color)
	for i in range(ai.split_count):
		var split := _make_ai_snake(ai.position + Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(70.0, 150.0), [], false)
		split.radius *= 0.82
		split.speed_multiplier *= 1.08
		_ai_snakes.append(split)
	for i in range(ai.summon_count):
		_ai_snakes.append(_make_ai_snake(ai.position + Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * 170.0, [], false))

func _spawn_warning_ring(position: Vector2, color: Color) -> void:
	_add_shockwave(Shockwave.new(position, color.lightened(0.18), 120.0, 0.32))

func _set_event(text: String, duration := 2.6) -> void:
	_wave_state["last_event"] = text
	_wave_state["event_time"] = duration

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
	var terrain := _terrain_for_position(_player.position)
	var terrain_id := String(terrain.get("id", ""))
	if terrain_id == "" or terrain_id == _current_player_terrain_id:
		return
	_current_player_terrain_id = terrain_id
	if not _seen_terrain_ids.has(terrain_id):
		_seen_terrain_ids[terrain_id] = true
		_queue_story(String(terrain.get("story_intro", "")), 2.8, "terrain_%s" % terrain_id, 999.0)

func _terrain_for_position(position: Vector2) -> Dictionary:
	return TerrainCatalogData.terrain_for_position(position, _play_area)

func _terrain_speed_multiplier(position: Vector2) -> float:
	var terrain := _terrain_for_position(position)
	return clampf(float(terrain.get("speed_multiplier", 1.0)), 0.92, 1.08)

func _current_build_tags() -> Array:
	return UpgradeCatalogData.summarize_tags(_owned_upgrades)

func _upgrade_names() -> Array:
	var names: Array = []
	for upgrade in _owned_upgrades:
		names.append(String(upgrade.get("name", "Upgrade")))
	return names

func _build_snapshot() -> Dictionary:
	return {
		"build_tags": _current_build_tags(),
		"upgrade_names": _upgrade_names(),
		"wave": int(_wave_state.get("wave", 1)),
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
		_add_particle(VfxParticle.new(
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
		_add_particle(VfxParticle.new(
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
		_add_particle(VfxParticle.new(
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
		_add_particle(VfxParticle.new(
			_player.position + offset,
			velocity,
			Color(0.36, 1.0, 0.48, 0.72),
			randf_range(3.0, 6.5),
			randf_range(0.16, 0.28),
			0.82
		))

func _spawn_food_burst(position: Vector2, color: Color) -> void:
	_add_shockwave(Shockwave.new(position, color.lightened(0.24), 58.0, 0.22))
	var burst_count := 12 if SettingsStore.animations_on else 3
	for i in range(burst_count):
		var direction := Vector2.RIGHT.rotated(randf_range(0.0, TAU))
		_add_particle(VfxParticle.new(
			position,
			direction * randf_range(55.0, 165.0),
			color.lightened(randf_range(0.0, 0.35)),
			randf_range(2.0, 5.0),
			randf_range(0.22, 0.46),
			0.88
		))

func _spawn_death_burst(position: Vector2, color: Color) -> void:
	_add_shockwave(Shockwave.new(position, color.lightened(0.18), 170.0, 0.48))
	_add_shockwave(Shockwave.new(position, Color(1.0, 0.38, 0.16), 95.0, 0.32))
	var burst_count := 42 if SettingsStore.animations_on else 10
	for i in range(burst_count):
		var direction := Vector2.RIGHT.rotated(randf_range(0.0, TAU))
		var burst_color := color.lerp(Color(1.0, 0.42, 0.12), randf_range(0.15, 0.65))
		_add_particle(VfxParticle.new(
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
		_add_particle(VfxParticle.new(
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
		_particles.remove_at(0)
	_particles.append(particle)

func _add_shockwave(shockwave: Shockwave) -> void:
	var budget := _shockwave_budget()
	if budget <= 0:
		return
	if _shockwaves.size() >= budget:
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
	_hud_snapshot["pressure"] = float(_wave_state.get("pressure", 1.0))
	_hud_snapshot["build_tags"] = _current_build_tags()
	_hud_snapshot["event_text"] = String(_wave_state.get("last_event", "")) if float(_wave_state.get("event_time", 0.0)) > 0.0 else ""
	var terrain := _terrain_for_position(_player.position)
	_hud_snapshot["terrain_name"] = String(terrain.get("name", "Unknown Sector"))
	_hud_snapshot["terrain_color"] = terrain.get("accent", Color(0.48, 1.0, 0.7, 0.6))
	_hud_snapshot["terrain_regions"] = _terrain_regions
	_hud_snapshot["in_lava"] = _lava_timer > 0.0
	_hud_snapshot["lava_time"] = maxf(0.0, float(_difficulty.get("lava_warning_time", 5.0)) - _lava_timer)
	_hud_snapshot["paused"] = _paused
	_hud_snapshot["ai_alive"] = alive_count
	_hud_snapshot["ai_total"] = maxi(int(_difficulty.get("ai_count", 20)), _ai_snakes.size())
	_hud_snapshot["world_rect"] = _play_area
	_hud_snapshot["player_position"] = _player.position
	_hud_snapshot["ai_positions"] = _hud_ai_positions
	_hud_snapshot["food_count"] = _foods.size()
	_hud.update_snapshot(_hud_snapshot)

func _draw_lava_edge(visible: Rect2) -> void:
	var pulse := 0.5 + 0.5 * sin(_world_time * 2.8)
	var hot := Color(1.0, 0.22, 0.06, 0.22 + pulse * 0.08)
	var ember := Color(1.0, 0.55, 0.14, 0.42)
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
		draw_circle(ember_position, ember_radius * 2.4, Color(1.0, 0.16, 0.04, 0.08))
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
	draw_rect(_play_area.grow(900.0), Color(0.38, 0.06, 0.02), true)
	_draw_lava_edge(visible)
	draw_rect(_play_area, Color(0.018, 0.04, 0.043), true)
	_draw_terrain_regions(visible)
	draw_texture_rect_region(ENVIRONMENT_ATLAS, _play_area, Rect2(16, 848, 152, 143), Color(1.0, 1.0, 1.0, 0.28))
	_draw_grid(visible)
	var boundary_alpha := 0.72 + 0.2 * sin(_world_time * 4.0)
	draw_rect(_play_area, Color(1.0, 0.42, 0.18, boundary_alpha), false, 7.0)
	draw_rect(_play_area.grow(-10.0), Color(0.14, 0.95, 0.62, 0.16), false, 2.0)
	var edge_warning := _edge_warning_ratio()
	if edge_warning > 0.0 and _lava_timer <= 0.0:
		var warning_pulse := 0.5 + 0.5 * sin(_world_time * 10.0)
		draw_arc(_player.position, _player.radius * (2.25 + warning_pulse * 0.12), 0.0, TAU, 42, Color(1.0, 0.62, 0.18, edge_warning * 0.42), 2.0)
	if _lava_timer > 0.0:
		var warning_pulse := 0.5 + 0.5 * sin(_world_time * 12.0)
		draw_circle(_player.position, _player.radius * (2.15 + warning_pulse * 0.24), Color(1.0, 0.22, 0.08, 0.2))
		draw_arc(_player.position, _player.radius * (2.55 + warning_pulse * 0.25), 0.0, TAU, 54, Color(1.0, 0.54, 0.18, 0.58), 3.0)

func _draw_terrain_regions(visible: Rect2) -> void:
	var boss_pollution := bool(_wave_state.get("boss_spawned", false)) and not bool(_wave_state.get("boss_defeated", false))
	for raw_terrain in _terrain_regions:
		var terrain: Dictionary = raw_terrain
		var rect: Rect2 = terrain.get("rect", Rect2())
		if not rect.intersects(visible):
			continue
		var terrain_color: Color = terrain.get("color", Color(0.1, 0.3, 0.25, 0.15))
		var accent: Color = terrain.get("accent", Color(0.4, 1.0, 0.7, 0.4))
		draw_rect(rect, terrain_color, true)
		draw_rect(rect, _color_alpha(accent, 0.24), false, 3.0)
		if boss_pollution:
			var pulse := 0.5 + 0.5 * sin(_world_time * 5.0)
			draw_rect(rect, Color(1.0, 0.18, 0.08, 0.035 + pulse * 0.025), true)
		_draw_terrain_marks(rect, String(terrain.get("id", "")), accent, visible)

func _draw_terrain_marks(rect: Rect2, terrain_id: String, color: Color, visible: Rect2) -> void:
	var seed_offset: float = float(abs(hash(terrain_id)) % 997)
	var step: float = 520.0
	var start_x: float = floor((visible.position.x - rect.position.x) / step) * step + rect.position.x
	var end_x: float = minf(rect.position.x + rect.size.x, visible.position.x + visible.size.x)
	var x: float = start_x
	while x <= end_x:
		var start_y: float = floor((visible.position.y - rect.position.y) / step) * step + rect.position.y
		var end_y: float = minf(rect.position.y + rect.size.y, visible.position.y + visible.size.y)
		var y: float = start_y
		while y <= end_y:
			var position := Vector2(x, y) + Vector2(
				sin(seed_offset + x * 0.01) * 80.0,
				cos(seed_offset + y * 0.01) * 80.0
			)
			if rect.has_point(position) and visible.has_point(position):
				match terrain_id:
					"bloom_nursery":
						draw_circle(position, 22.0, _color_alpha(color, 0.08))
						draw_arc(position, 38.0, 0.0, TAU, 24, _color_alpha(color, 0.22), 1.5)
					"ion_marsh":
						draw_line(position - Vector2(34.0, 0.0), position + Vector2(34.0, 0.0), _color_alpha(color, 0.18), 2.0)
						draw_line(position - Vector2(0.0, 22.0), position + Vector2(0.0, 22.0), _color_alpha(color, 0.12), 1.5)
					"glass_reef":
						draw_rect(Rect2(position - Vector2(18.0, 18.0), Vector2(36.0, 36.0)), _color_alpha(color, 0.09), false, 2.0)
					"ember_vein":
						draw_arc(position, 32.0, -PI * 0.2, PI * 1.1, 18, _color_alpha(color, 0.2), 2.0)
			y += step
		x += step

func _draw_grid(visible: Rect2) -> void:
	var quality := _effects_quality()
	var minor_step := 60.0 if SettingsStore.animations_on and quality >= 2 else 120.0
	if SettingsStore.animations_on and quality == 1:
		minor_step = 90.0
	var minor_start_x: float = floor((visible.position.x + _grid_offset.x) / minor_step) * minor_step - _grid_offset.x
	var minor_end_x := visible.position.x + visible.size.x
	var minor_x: float = minor_start_x
	while minor_x <= minor_end_x:
		draw_line(Vector2(minor_x, visible.position.y), Vector2(minor_x, visible.position.y + visible.size.y), Color(0.08, 0.18, 0.17, 0.11), 1.0)
		minor_x += minor_step

	var minor_start_y: float = floor((visible.position.y + _grid_offset.y) / minor_step) * minor_step - _grid_offset.y
	var minor_end_y := visible.position.y + visible.size.y
	var minor_y: float = minor_start_y
	while minor_y <= minor_end_y:
		draw_line(Vector2(visible.position.x, minor_y), Vector2(visible.position.x + visible.size.x, minor_y), Color(0.08, 0.18, 0.17, 0.11), 1.0)
		minor_y += minor_step

	var step := 240.0
	var start_x: float = floor((visible.position.x + _grid_offset.x) / step) * step - _grid_offset.x
	var end_x := visible.position.x + visible.size.x
	var x: float = start_x
	while x <= end_x:
		var line_alpha := 0.24 + 0.06 * sin(_world_time * 1.6 + x * 0.01)
		draw_line(Vector2(x, visible.position.y), Vector2(x, visible.position.y + visible.size.y), Color(0.13, 0.42, 0.34, line_alpha), 1.0)
		x += step

	var start_y: float = floor((visible.position.y + _grid_offset.y) / step) * step - _grid_offset.y
	var end_y := visible.position.y + visible.size.y
	var y: float = start_y
	while y <= end_y:
		var line_alpha := 0.24 + 0.06 * sin(_world_time * 1.6 + y * 0.01)
		draw_line(Vector2(visible.position.x, y), Vector2(visible.position.x + visible.size.x, y), Color(0.13, 0.42, 0.34, line_alpha), 1.0)
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

func _draw_companions() -> void:
	var companions := int(_modifiers.get("companion_count", 0))
	if companions <= 0:
		return
	for companion_index in range(mini(companions, 4)):
		var angle := _world_time * (1.4 + companion_index * 0.18) + TAU * float(companion_index) / float(maxi(1, companions))
		var position := _player.position + Vector2.RIGHT.rotated(angle) * (92.0 + float(companion_index) * 16.0)
		draw_circle(position, 13.0, Color(0.0, 0.0, 0.0, 0.24))
		draw_circle(position, 9.0, Color(0.55, 1.0, 0.82, 0.86))
		draw_arc(position, 18.0, 0.0, TAU, 28, Color(0.36, 1.0, 0.58, 0.42), 2.0)

func _draw_snake(agent: SnakeAgent, is_player: bool) -> void:
	if agent.dead:
		return
	var base_color := agent.color
	if agent.blink and not is_player:
		base_color.a = 0.45 + 0.55 * abs(sin(_world_time * 7.0))
	var death_progress := clampf(agent.death_timer / AI_DEATH_DISSOLVE_TIME, 0.0, 1.0) if agent.dying else 0.0
	var death_alpha := 1.0 - death_progress
	base_color.a *= death_alpha
	var segment_count := agent.segments.size()
	var point_count := segment_count + 1

	if segment_count > 0:
		for i in range(segment_count - 1, -1, -1):
			var current: Vector2 = agent.segments[i]
			var previous: Vector2 = agent.position if i == 0 else agent.segments[i - 1]
			var ratio := float(i + 1) / float(point_count)
			var width := agent.radius * (1.75 - ratio * 0.44) * (1.0 - death_progress * 0.32)
			draw_line(current, previous, Color(0.0, 0.0, 0.0, 0.2 * death_alpha), width + 4.0)
			draw_line(current, previous, base_color.darkened(ratio * 0.22), width)

	for i in range(segment_count - 1, -1, -1):
		var ratio := float(i + 1) / float(segment_count + 1)
		var segment_radius := agent.radius * (1.0 - ratio * 0.28) * (1.0 - death_progress * 0.4)
		var dissolve_offset := Vector2.ZERO
		if agent.dying:
			dissolve_offset = Vector2.RIGHT.rotated(float(i) * 2.399 + _world_time * 1.6) * death_progress * agent.radius * 0.22
		var segment_position: Vector2 = agent.segments[i] + dissolve_offset
		draw_circle(segment_position, segment_radius + 2.0, Color(0.0, 0.0, 0.0, 0.18 * death_alpha))
		_draw_texture_centered(PLAYER_BODY_TEXTURE, segment_position, Vector2.ONE * segment_radius * 2.7, 0.0, base_color.darkened(ratio * 0.18))
		draw_circle(segment_position - Vector2(segment_radius * 0.22, segment_radius * 0.25), segment_radius * 0.32, _color_alpha(base_color.lightened(0.42), 0.24 * death_alpha))

	if is_player and _invulnerability_timer > 0.0:
		var pulse := 0.5 + 0.5 * sin((GameConfigData.COLLISION_GRACE_PERIOD - _invulnerability_timer) * 8.0)
		var shield_arc_points := 48 if _effects_quality() >= 2 else 32
		_draw_texture_centered(SHIELD_RING_TEXTURE, agent.position, Vector2.ONE * agent.radius * (4.2 + pulse * 0.24), 0.0, Color(0.8, 1.0, 1.0, 0.62))
		draw_arc(agent.position, agent.radius * (1.35 + pulse * 0.08), 0.0, TAU, shield_arc_points, Color(0.62, 0.98, 1.0, 0.72), 2.0)

	if is_player and _is_boosting():
		var boost_pulse := 0.5 + 0.5 * sin(_world_time * 20.0)
		var boost_arc_points := 42 if _effects_quality() >= 2 else 28
		_draw_texture_centered(BOOST_PUFF_TEXTURE, agent.position - agent.direction.normalized() * agent.radius * 1.6, Vector2(agent.radius * 3.8, agent.radius * 2.5), agent.direction.angle() - PI, Color(0.75, 1.0, 0.78, 0.62))
		draw_arc(agent.position, agent.radius * (1.28 + boost_pulse * 0.06), -PI * 0.15, TAU - PI * 0.15, boost_arc_points, Color(0.72, 1.0, 0.45, 0.58), 2.5)

	var head_radius := agent.radius * (1.0 - death_progress * 0.28)
	draw_circle(agent.position, head_radius + 3.5, Color(0.0, 0.0, 0.0, 0.24 * death_alpha))
	var head_texture: Texture2D = PLAYER_HEAD_TEXTURE if is_player else AI_HEAD_TEXTURE
	if not is_player and (agent.is_elite or agent.is_boss or (agent.color.r > 0.75 and agent.color.b > 0.55)):
		head_texture = ELITE_HEAD_TEXTURE
	_draw_texture_centered(head_texture, agent.position, Vector2.ONE * head_radius * 3.25, _texture_rotation_for_direction(agent.direction), base_color.lightened(0.06))
	draw_circle(agent.position - Vector2(head_radius * 0.22, head_radius * 0.26), head_radius * 0.42, _color_alpha(base_color.lightened(0.5), 0.28 * death_alpha))
	if not is_player and not agent.dying and agent.max_health > 1:
		var width := head_radius * (2.2 if agent.is_boss else 1.55)
		var top := agent.position + Vector2(-width * 0.5, -head_radius * 2.0)
		draw_rect(Rect2(top, Vector2(width, 5.0)), Color(0.0, 0.0, 0.0, 0.42), true)
		draw_rect(Rect2(top, Vector2(width * clampf(float(agent.health) / float(agent.max_health), 0.0, 1.0), 5.0)), Color(1.0, 0.36, 0.2, 0.86), true)

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
	return Vector2(
		randf_range(_play_area.position.x, _play_area.position.x + _play_area.size.x),
		randf_range(_play_area.position.y, _play_area.position.y + _play_area.size.y)
	)

func _random_ai_spawn_position() -> Vector2:
	for i in range(32):
		var position := Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(420.0, GameConfigData.AI_SPAWN_RADIUS)
		if _play_area.has_point(position) and position.distance_to(_player.position) > 360.0:
			return position
	return _random_position_in_play_area()

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
