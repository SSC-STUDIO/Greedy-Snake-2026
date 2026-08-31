class_name Level01Static
extends Node2D
## Level01 — 静态手摆关卡。
## 锚点、拾取物、视差背景等全部固化在 .tscn 里，可直接在 Godot 编辑器中
## 可视化编辑；本脚本只负责生成玩家/相机/HUD 三件套并接线机关信号。

const PLAYER := preload("res://scenes/player/Player.tscn")
const CAMERA := preload("res://scenes/camera/GameCamera.tscn")
const HUD := preload("res://scenes/ui/HUD.tscn")

@onready var plate: PressurePlate = $Props/PressurePlate
@onready var door: ArenaDoor = $Props/Door

const DEFAULT_SPAWN := Vector2(96, 290)

const EAST_LIMIT := Level01EastWing.EAST_LIMIT
const EAST_FLOOR_X := Level01EastWing.EAST_FLOOR_X

var _player: Player
var _boss: ExecutionerBoss
var _wing: Level01EastWing
var _beats: Level01StoryBeats


func _ready() -> void:
	_extend_east()
	_spawn_decor()
	_build_parallax_extras()
	_spawn_actors()
	_wire_props()
	_bind_story()
	call_deferred("_try_wake")


func _wire_props() -> void:
	if plate != null and door != null and not plate.activated.is_connected(door.open_door):
		plate.activated.connect(door.open_door)
	var toxin := get_node_or_null("Props/ToxinPool") as ToxinPool
	if toxin != null:
		toxin.configure(Vector2(112, 32))


func _spawn_actors() -> void:
	_player = PLAYER.instantiate()
	_player.position = DEFAULT_SPAWN
	add_child(_player)

	if SaveData.has_save():
		SaveData.load_game()
		if SaveData.pending_spawn != Vector2.INF:
			_player.position = SaveData.consume_pending_spawn()
		elif SaveData.data.has("player") and (SaveData.data["player"] as Dictionary).has("pos"):
			_player.position = SaveData.data["player"]["pos"]
		SaveData.apply_player(_player)
		SaveData.apply_world(self)
		SaveData.apply_consumed(self)

	var cam: GameCamera = CAMERA.instantiate()
	add_child(cam)
	cam.limit_right = EAST_LIMIT
	cam.global_position = _player.global_position + Vector2(0, -18)

	var hud: CanvasLayer = HUD.instantiate()
	add_child(hud)


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


static func should_spawn_executioner() -> bool:
	return Level01EastWing.should_spawn_executioner()


static func should_unlock_forge() -> bool:
	return Level01EastWing.should_unlock_forge()


static func east_floor_rect() -> Rect2:
	return Level01EastWing.east_floor_rect()


static func mark_executioner_slain() -> void:
	Level01EastWing.mark_executioner_slain()
