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

	# 毒坑两级踏脚。旧坐标把低梁贴在地面行人头顶（424,300），
	# 小台埋进 GroundRight 土层（496,336）。单跳约 37px（v=-268,g=980），
	# 低台离地 64px、高台再高 36px，coyote 单跳能从低接到高。
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
	return boss


func _on_boss_gate(body: Node) -> void:
	boss_gate_entered.emit(body)


func _on_boss_slain() -> void:
	boss_slain.emit()
