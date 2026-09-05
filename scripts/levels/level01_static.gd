class_name Level01Static
extends Node2D
## Level01 — 静态手摆关卡。
## 锚点、拾取物、视差背景等全部固化在 .tscn 里，可直接在 Godot 编辑器中
## 可视化编辑；本脚本只负责生成玩家/相机/HUD 三件套并接线机关信号。

const PLAYER := preload("res://scenes/player/Player.tscn")
const CAMERA := preload("res://scenes/camera/GameCamera.tscn")
const HUD := preload("res://scenes/ui/HUD.tscn")

@onready var plate: PressurePlate = get_node_or_null("Props/PressurePlate")
@onready var door: ArenaDoor = get_node_or_null("Props/Door")

const DEFAULT_SPAWN := Vector2(96, 290)
const GROUND_TOP := 320.0
const JUMP_REACH := 37.0
const STEP_RISE := 32.0
const TEACH_TERRACE_POS := Vector2(228, 288)
const TEACH_TERRACE_SIZE := Vector2(40, 32)
const TEACH_MID_Y := 256.0
const PLATFORM := preload("res://scenes/world/Platform.tscn")

const EAST_LIMIT := Level01EastWing.EAST_LIMIT
const EAST_FLOOR_X := Level01EastWing.EAST_FLOOR_X

var _player: Player
var _boss: ExecutionerBoss
var _wing: Level01EastWing
var _beats: Level01StoryBeats
## Tests that only need the game_world group skip actor/layout boot.
var run_slice := true


func _enter_tree() -> void:
	add_to_group("game_world")


func _ready() -> void:
	if not run_slice:
		return
	var restored := false
	if SaveData.has_save():
		restored = SaveData.load_game()
	_extend_east()
	_tune_play_layout()
	_spawn_decor()
	_build_parallax_extras()
	_spawn_actors(restored)
	_wire_props()
	_bind_story()
	call_deferred("_try_wake")


func _wire_props() -> void:
	if plate != null and door != null and not plate.activated.is_connected(door.open_door):
		plate.activated.connect(door.open_door)
	var toxin := get_node_or_null("Props/ToxinPool") as ToxinPool
	if toxin != null:
		toxin.configure(Level01EastWing.PIT_WATER_SIZE)


func _spawn_actors(restored: bool = false) -> void:
	_player = PLAYER.instantiate()
	_player.position = DEFAULT_SPAWN
	add_child(_player)

	var from_checkpoint := SaveData.entering_from_checkpoint
	if SaveData.has_pending_spawn():
		_player.position = SaveData.consume_pending_spawn()
	elif restored and SaveData.data.has("player") and (SaveData.data["player"] as Dictionary).has("pos"):
		_player.position = SaveData.data["player"]["pos"]
	if restored:
		SaveData.apply_player(_player)
		SaveData.apply_world(self)
		SaveData.apply_consumed(self)
	if from_checkpoint:
		_player.health.heal_full()
		_player.toxin.purify(1.0)
		GameEvents.player_health_changed.emit(_player.health.current, _player.health.max_hp)

	var cam: GameCamera = CAMERA.instantiate()
	add_child(cam)
	cam.limit_right = EAST_LIMIT
	cam.global_position = _player.global_position + Vector2(0, -18)

	var hud: CanvasLayer = HUD.instantiate()
	GameContext.ui_host(self).add_child(hud)


func _tune_play_layout() -> void:
	var platforms := get_node_or_null("Platforms") as Node2D
	place_teach_layout(platforms)


func place_teach_layout(platforms: Node2D) -> void:
	if platforms == null:
		return
	if platforms.get_node_or_null("TeachTerrace") == null:
		var terrace: SolidPlatform = PLATFORM.instantiate()
		terrace.name = "TeachTerrace"
		terrace.skin = "ground"
		terrace.position = TEACH_TERRACE_POS
		terrace.size = TEACH_TERRACE_SIZE
		terrace.cap_left = true
		terrace.cap_right = true
		platforms.add_child(terrace)
	var mid := platforms.get_node_or_null("Plat_268_248") as SolidPlatform
	if mid != null:
		mid.position.y = TEACH_MID_Y


func _spawn_decor() -> void:
	var layer := Node2D.new()
	layer.name = "GraveDecor"
	layer.z_index = -2
	add_child(layer)
	Level01Env.plant(layer, Level01Env.DECOR_TREE_1, Vector2(8, 320), 0.50)
	Level01Env.plant(layer, Level01Env.DECOR_BUSH_L, Vector2(78, 320), 0.65)
	Level01Env.plant(layer, Level01Env.DECOR_STONE_1, Vector2(210, 320), 1.0)
	Level01Env.plant(layer, Level01Env.DECOR_TREE_2, Vector2(268, 320), 0.46)
	Level01Env.plant(layer, Level01Env.DECOR_STONE_3, Vector2(360, 320), 1.0)
	Level01Env.plant(layer, Level01Env.DECOR_TREE_3, Vector2(540, 320), 0.40)
	Level01Env.plant(layer, Level01Env.DECOR_BUSH_S, Vector2(620, 320), 1.0)
	Level01Env.plant(layer, Level01Env.DECOR_STATUE, Vector2(880, 320), 0.82)
	Level01Env.plant(layer, Level01Env.DECOR_STONE_2, Vector2(1020, 320), 1.0)
	Level01Env.plant(layer, Level01Env.DECOR_TREE_1, Vector2(1210, 320), 0.48)
	Level01Env.plant(layer, Level01Env.DECOR_BUSH_L, Vector2(1440, 320), 0.62)
	Level01Env.plant(layer, Level01Env.DECOR_STONE_1, Vector2(1540, 320), 1.0)


func _build_parallax_extras() -> void:
	var extras := Level01Parallax.new()
	extras.name = "ParallaxExtras"
	add_child(extras)
	extras.build(self)


func _extend_east() -> void:
	_wing = Level01EastWing.new()
	_wing.name = "EastWing"
	add_child(_wing)
	_boss = _wing.build(self)


func _bind_story() -> void:
	_beats = Level01StoryBeats.new()
	_beats.name = "StoryBeats"
	add_child(_beats)
	_beats.bind(self, _player, _boss)
	if _wing != null:
		if not _wing.boss_gate_entered.is_connected(_beats.on_boss_gate):
			_wing.boss_gate_entered.connect(_beats.on_boss_gate)
		if not _wing.boss_slain.is_connected(_beats.on_boss_slain):
			_wing.boss_slain.connect(_beats.on_boss_slain)


func _try_wake() -> void:
	if _beats != null:
		_beats.try_wake()
	SaveData.entering_from_checkpoint = false


static func should_spawn_executioner() -> bool:
	return Level01EastWing.should_spawn_executioner()


static func should_unlock_forge() -> bool:
	return Level01EastWing.should_unlock_forge()


static func east_floor_rect() -> Rect2:
	return Level01EastWing.east_floor_rect()


static func mark_executioner_slain() -> void:
	Level01EastWing.mark_executioner_slain()
