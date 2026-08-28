extends Node2D
## Level01 — 静态手摆关卡。
## 锚点、拾取物、视差背景等全部固化在 .tscn 里，可直接在 Godot 编辑器中
## 可视化编辑；本脚本只负责生成玩家/相机/HUD 三件套并接线机关信号。

const PLAYER := preload("res://scenes/player/Player.tscn")
const CAMERA := preload("res://scenes/camera/GameCamera.tscn")
const HUD := preload("res://scenes/ui/HUD.tscn")

# Interactables are already placed in the .tscn under $Props; we only wire them here.
@onready var plate: PressurePlate = $Props/PressurePlate
@onready var door: ArenaDoor = $Props/Door


const DEFAULT_SPAWN := Vector2(96, 290)


func _ready() -> void:
	_spawn_actors()
	_wire_props()
	GameEvents.announcement.emit("锈墓・壹 — 腐液回廊")


func _wire_props() -> void:
	if plate != null and door != null and not plate.activated.is_connected(door.open_door):
		plate.activated.connect(door.open_door)
	# Keep toxin pit tight to the ground slice.
	var toxin := get_node_or_null("Props/ToxinPool") as ToxinPool
	if toxin != null:
		toxin.configure(Vector2(112, 32))


func _spawn_actors() -> void:
	var player: Player = PLAYER.instantiate()
	player.position = DEFAULT_SPAWN
	add_child(player)

	# Restore a save if we're continuing or respawning from a dead knight.
	if SaveData.has_save():
		SaveData.load_game()
		if SaveData.pending_spawn != Vector2.INF:
			player.position = SaveData.consume_pending_spawn()
		elif SaveData.data.has("player") and (SaveData.data["player"] as Dictionary).has("pos"):
			player.position = SaveData.data["player"]["pos"]
		SaveData.apply_player(player)
		SaveData.apply_world(self)
		SaveData.apply_consumed(self)

	var cam: GameCamera = CAMERA.instantiate()
	add_child(cam)
	cam.global_position = player.global_position + Vector2(0, -18)

	var hud: CanvasLayer = HUD.instantiate()
	add_child(hud)
