extends Node2D
## Level01 — static hand-editable chamber (TileMap-ready).
## All collision geometry is placed in the .tscn; this script only spawns actors and wires signals.

const PLAYER := preload("res://scenes/player/Player.tscn")
const CAMERA := preload("res://scenes/camera/GameCamera.tscn")
const HUD := preload("res://scenes/ui/HUD.tscn")
const PICKUP := preload("res://scenes/interactables/CorePickup.tscn")

# Interactables are already placed in the .tscn under $Props; we only wire them here.
@onready var plate: PressurePlate = $Props/PressurePlate
@onready var door: ArenaDoor = $Props/Door


func _ready() -> void:
	_spawn_actors()
	_wire_props()
	_spawn_bonus_pickups()
	GameEvents.announcement.emit("锈墓・壹 — 静态手摆关卡 (640×360, Kenney 贴图已接入，双怪+双核)")


func _wire_props() -> void:
	if plate != null and door != null and not plate.activated.is_connected(door.open_door):
		plate.activated.connect(door.open_door)
	# Keep toxin pit tight to the ground slice.
	var toxin := get_node_or_null("Props/ToxinPool") as ToxinPool
	if toxin != null:
		toxin.configure(Vector2(112, 32))


func _spawn_bonus_pickups() -> void:
	# Reward precise platforming: extra cores floating over the left tower.
	var bonus := [
		[Vector2(60, 120), AbilityCatalog.kiln_core()],
		[Vector2(495, 210), AbilityCatalog.kiln_core()],
	]
	for entry in bonus:
		var pos: Vector2 = entry[0]
		var core: RustCore = entry[1]
		var p: CorePickup = PICKUP.instantiate()
		p.core = core
		add_child(p)
		p.global_position = pos
		# Gentle bob to telegraph collectible.
		var tween := create_tween().set_loops()
		tween.tween_property(p, "position:y", pos.y - 6.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(p, "position:y", pos.y, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _spawn_actors() -> void:
	var player: Player = PLAYER.instantiate()
	player.position = Vector2(96, 290)
	add_child(player)

	var cam: GameCamera = CAMERA.instantiate()
	add_child(cam)
	cam.global_position = player.global_position + Vector2(0, -18)

	var hud: CanvasLayer = HUD.instantiate()
	add_child(hud)
