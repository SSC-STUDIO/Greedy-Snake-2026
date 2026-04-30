extends RefCounted
class_name GameConfig

const BASE_WINDOW_WIDTH := 1280
const BASE_WINDOW_HEIGHT := 720
const PLAY_AREA_SCALE := 10
const INITIAL_SNAKE_RADIUS := 22.0
const SNAKE_SEGMENT_SPACING := 24.0
const DEFAULT_RECORD_INTERVAL := 0.05
const FOOD_GRID_CELL_SIZE := 200
const MAX_FOOD_COUNT := 5660
const AI_SPAWN_RADIUS := 2200.0
const AI_DIRECTION_CHANGE_TIME := 0.6
const AI_MIN_SPEED_MULTIPLIER := 0.5
const AI_MAX_SPEED_MULTIPLIER := 0.9
const COLLISION_GRACE_PERIOD := 5.0
const DEFAULT_VOLUME := 0.85
const BOOST_MULTIPLIER := 1.65
const CAMERA_SMOOTHNESS := 8.0

const PLAYER_SPEEDS := [180.0, 250.0, 320.0]
const SPEED_LABELS := ["Slow", "Normal", "Fast"]
const DIFFICULTY_LABELS := ["Easy", "Normal", "Hard"]
const EFFECT_QUALITY_LABELS := ["Low", "Balanced", "High"]
const MINIMAP_SIZE_LABELS := ["Compact", "Standard", "Large"]
const DIFFICULTIES := [
	{
		"player_speed": 200.0,
		"ai_count": 10,
		"ai_aggression": 0.3,
		"food_spawn_rate": 1.2,
		"lava_warning_time": 7.0,
	},
	{
		"player_speed": 250.0,
		"ai_count": 20,
		"ai_aggression": 0.6,
		"food_spawn_rate": 1.0,
		"lava_warning_time": 5.0,
	},
	{
		"player_speed": 300.0,
		"ai_count": 30,
		"ai_aggression": 0.9,
		"food_spawn_rate": 0.8,
		"lava_warning_time": 3.0,
	},
]

static func play_area_rect() -> Rect2:
	var width := float(BASE_WINDOW_WIDTH * PLAY_AREA_SCALE * 2)
	var height := float(BASE_WINDOW_HEIGHT * PLAY_AREA_SCALE * 2)
	return Rect2(Vector2(-width * 0.5, -height * 0.5), Vector2(width, height))

static func clamp_difficulty(value: int) -> int:
	return clampi(value, 0, DIFFICULTIES.size() - 1)

static func clamp_speed(value: int) -> int:
	return clampi(value, 0, PLAYER_SPEEDS.size() - 1)

static func clamp_effects_quality(value: int) -> int:
	return clampi(value, 0, EFFECT_QUALITY_LABELS.size() - 1)

static func clamp_minimap_size(value: int) -> int:
	return clampi(value, 0, MINIMAP_SIZE_LABELS.size() - 1)

static func difficulty(index: int) -> Dictionary:
	return DIFFICULTIES[clamp_difficulty(index)]

static func player_speed_for(speed_index: int, difficulty_index: int) -> float:
	var speed_setting: float = float(PLAYER_SPEEDS[clamp_speed(speed_index)])
	var difficulty_setting := float(difficulty(difficulty_index)["player_speed"])
	return maxf(speed_setting, difficulty_setting)
