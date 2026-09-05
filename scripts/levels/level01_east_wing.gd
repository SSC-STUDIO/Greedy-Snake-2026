class_name Level01EastWing
extends Node
## Level01 east wing: pit beams, east floor, ember ledge, Boss, ForgeHeart, gate.
## Builds into the host's existing Platforms / Hooks / Pickups / Props folders
## so authored node paths stay valid. Not a PackedScene — instancing a sub-scene
## would reparent those nodes and break SaveData / story lookups.

const PLATFORM := preload("res://scenes/world/Platform.tscn")
const ANCHOR := preload("res://scenes/interactables/HookAnchor.tscn")
const PICKUP := preload("res://scenes/interactables/CorePickup.tscn")
const BOSS := preload("res://scenes/enemies/ExecutionerBoss.tscn")
const FORGE := preload("res://scenes/interactables/ForgeHeart.tscn")

const EAST_LIMIT := 2240
const EAST_FLOOR_X := 1600.0
## Roofed forge remnant past the Executioner — indoor lighting, rain stops.
const FORGE_SHELTER_POS := Vector2(2112, 240)
const FORGE_SHELTER_SIZE := Vector2(256, 160)
const PIT_X0 := 400.0
const PIT_X1 := 512.0
const PIT_BANK_Y := 320.0
const PIT_WATER_Y := 336.0
const PIT_FLOOR_Y := 352.0
const PIT_FLOOR_SIZE := Vector2(112, 48)
const PIT_WATER_SIZE := Vector2(112, 32)
const PIT_CLIMB_LEFT_POS := Vector2(400, 336)
const PIT_CLIMB_LEFT_SIZE := Vector2(32, 16)
const PIT_CLIMB_RIGHT_POS := Vector2(480, 336)
const PIT_CLIMB_RIGHT_SIZE := Vector2(32, 16)

signal boss_gate_entered(body: Node)
signal boss_slain

var boss: ExecutionerBoss
var heart: ForgeHeart


static func should_spawn_executioner() -> bool:
	return not SaveData.has_flag("boss_dead")


static func should_unlock_forge() -> bool:
	return SaveData.has_flag("boss_dead")


## GroundRight in Level01_Static.tscn is (512, 320) size (1088, 80) → ends at 1600.
## Floor must reach EAST_LIMIT (WallRight) or the boss room drops 32px into the void.
static func east_floor_rect() -> Rect2:
	return Rect2(EAST_FLOOR_X, 320.0, float(EAST_LIMIT) - EAST_FLOOR_X, 80.0)


static func mark_executioner_slain() -> void:
	SaveData.mark_flag("boss_dead")
	SaveData.persist_story()


func build(host: Node2D) -> ExecutionerBoss:
	var platforms := host.get_node_or_null("Platforms") as Node2D
	var hooks := host.get_node_or_null("Hooks") as Node2D
	var pickups := host.get_node_or_null("Pickups") as Node2D
	var props := host.get_node_or_null("Props") as Node2D
	if platforms == null or hooks == null or pickups == null or props == null:
		return null

	# 毒坑：抬底 + 两岸矮唇，单跳能爬回地面。高踏石仍是可选路线。
	_tune_toxin_pit(platforms)
	_place_pit_step(platforms, "PitClimbLeft", "ground", PIT_CLIMB_LEFT_POS, PIT_CLIMB_LEFT_SIZE)
	_place_pit_step(platforms, "PitClimbRight", "ground", PIT_CLIMB_RIGHT_POS, PIT_CLIMB_RIGHT_SIZE)
	var beam := PLATFORM.instantiate()
	beam.name = "PitStepHigh"
	beam.skin = "floating"
	beam.position = Vector2(548, 220)
	beam.size = Vector2(64, 16)
	platforms.add_child(beam)
	var pit_ledge := PLATFORM.instantiate()
	pit_ledge.name = "PitStepLow"
	pit_ledge.skin = "floating"
	pit_ledge.position = Vector2(496, 256)
	pit_ledge.size = Vector2(48, 16)
	platforms.add_child(pit_ledge)
	var wall := platforms.get_node_or_null("WallRight") as Node2D
	if wall:
		wall.position.x = float(EAST_LIMIT)
	var floor_rect := east_floor_rect()
	var floor := PLATFORM.instantiate()
	floor.skin = "ground"
	floor.position = floor_rect.position
	floor.size = floor_rect.size
	floor.cap_left = false
	floor.cap_right = false
	platforms.add_child(floor)
	var ledge := PLATFORM.instantiate()
	ledge.skin = "floating"
	ledge.position = Vector2(1528, 112)
	ledge.size = Vector2(80, 16)
	platforms.add_child(ledge)
	var hook := ANCHOR.instantiate()
	hook.position = Vector2(1568, 48)
	hooks.add_child(hook)
	var ember := PICKUP.instantiate() as CorePickup
	ember.position = Vector2(1568, 96)
	ember.core = AbilityCatalog.ember_core()
	pickups.add_child(ember)
	var shrine := props.get_node_or_null("PurificationShrine") as Node2D
	if shrine:
		shrine.position = Vector2(1464, 288)
	if should_spawn_executioner():
		boss = BOSS.instantiate()
		boss.position = Vector2(1860, 320)
		props.add_child(boss)
		boss.slain.connect(_on_boss_slain)
	heart = FORGE.instantiate()
	heart.position = Vector2(2064, 292)
	heart.name = "ForgeHeart"
	props.add_child(heart)
	if should_unlock_forge():
		heart.unlock()
	else:
		heart.lock()
	var zone := Area2D.new()
	zone.name = "BossGate"
	zone.collision_layer = 0
	zone.collision_mask = 2
	zone.monitoring = true
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 80)
	shape.shape = rect
	zone.add_child(shape)
	zone.position = Vector2(1688, 280)
	host.add_child(zone)
	zone.body_entered.connect(_on_boss_gate)
	place_forge_shelter(host)
	return boss


static func place_forge_shelter(host: Node2D) -> AtmosphereZone:
	var existing := host.get_node_or_null("ForgeShelter") as AtmosphereZone
	if existing != null:
		return existing
	var shelter := AtmosphereZone.new()
	shelter.name = "ForgeShelter"
	shelter.zone = WorldClock.Zone.INDOORS
	shelter.position = FORGE_SHELTER_POS
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = FORGE_SHELTER_SIZE
	shape.shape = rect
	shelter.add_child(shape)
	var pool := WorldLight.new()
	pool.name = "WarmPool"
	pool.follow = &"indoor"
	pool.lit = true
	pool.color = Color(1.0, 0.62, 0.38)
	pool.position = Vector2(0.0, -12.0)
	shelter.add_child(pool)
	host.add_child(shelter)
	return shelter


func _tune_toxin_pit(platforms: Node2D) -> void:
	var pit := platforms.get_node_or_null("ToxinPit") as SolidPlatform
	if pit == null:
		return
	pit.position = Vector2(PIT_X0, PIT_FLOOR_Y)
	pit.size = PIT_FLOOR_SIZE


func _place_pit_step(platforms: Node2D, node_name: String, skin: String, pos: Vector2, size: Vector2) -> void:
	if platforms.get_node_or_null(node_name) != null:
		return
	var step: SolidPlatform = PLATFORM.instantiate()
	step.name = node_name
	step.skin = skin
	step.position = pos
	step.size = size
	platforms.add_child(step)


func _on_boss_gate(body: Node) -> void:
	boss_gate_entered.emit(body)


func _on_boss_slain() -> void:
	boss_slain.emit()
