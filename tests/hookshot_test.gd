extends TestCase
## Melt-hook: facing + LOS, rusty_gate only. No stagger on shields/boss.


const GATE_SCENE := preload("res://scenes/interactables/RustyGate.tscn")
const SHIELD_SCENE := preload("res://scenes/enemies/GearShieldEnemy.tscn")
const BOSS_SCENE := preload("res://scenes/enemies/ExecutionerBoss.tscn")


func _equip_melt(player: Player) -> void:
	player.inventory.add_to_pouch(AbilityCatalog.kiln_core())
	player.inventory.add_to_pouch(AbilityCatalog.tether_core())
	player.inventory.insert_into_socket(0)
	player.inventory.insert_into_socket(1)


func _face(player: Player, dir: int) -> void:
	player.controller.facing = dir
	player.visual.scale.x = float(dir)


func _place_gate(arena: Node2D, pos: Vector2) -> RustyGate:
	var gate := GATE_SCENE.instantiate() as RustyGate
	gate.position = pos
	arena.add_child(gate)
	return gate


func _wall(arena: Node2D, pos: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 200)
	col.shape = shape
	body.add_child(col)
	arena.add_child(body)
	return body


func test_melt_hook_ignores_gate_behind_player() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	_equip_melt(player)
	var gate := _place_gate(arena, player.global_position + Vector2(140, -40))
	await flush(2)
	_face(player, -1)
	ok(not player.hookshot._try_melt_hook(player), "facing away does not melt")
	ok(is_instance_valid(gate) and not gate.is_queued_for_deletion())


func test_melt_hook_blocked_by_wall() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	_equip_melt(player)
	var gate := _place_gate(arena, player.global_position + Vector2(140, -40))
	_wall(arena, player.global_position + Vector2(70, -40))
	await flush(3)
	_face(player, 1)
	ok(not player.hookshot._try_melt_hook(player), "wall blocks melt")
	ok(is_instance_valid(gate) and not gate.is_queued_for_deletion())


func test_melt_hook_melts_gate_in_front_with_los() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	_equip_melt(player)
	var gate := _place_gate(arena, player.global_position + Vector2(140, -40))
	await flush(3)
	_face(player, 1)
	var melted := false
	GameEvents.rusty_gate_melted.connect(func() -> void: melted = true, CONNECT_ONE_SHOT)
	ok(player.hookshot._try_melt_hook(player), "facing + LOS melts")
	ok(melted or gate.is_queued_for_deletion(), "gate consumed")


func test_melt_hook_does_not_stagger_gear_shield() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	_equip_melt(player)
	var guard := SHIELD_SCENE.instantiate() as GearShieldEnemy
	guard.position = player.global_position + Vector2(80, 0)
	arena.add_child(guard)
	await flush(2)
	guard._state = guard.State.BLOCK
	guard._blocking = true
	_face(player, 1)
	ok(not player.hookshot._try_melt_hook(player))
	ok(guard._state != guard.State.STAGGER, "shield is not staggered by hook")


func test_melt_hook_does_not_stagger_boss() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	_equip_melt(player)
	var boss := BOSS_SCENE.instantiate() as ExecutionerBoss
	boss.position = player.global_position + Vector2(90, 0)
	arena.add_child(boss)
	await flush(2)
	boss._state = boss.State.BLOCK
	boss._blocking = true
	_face(player, 1)
	ok(not player.hookshot._try_melt_hook(player))
	ok(boss._state != boss.State.STAGGER, "boss is not staggered by hook")


func test_melt_hook_picks_gate_not_nearby_boss() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	_equip_melt(player)
	var gate := _place_gate(arena, player.global_position + Vector2(140, -40))
	var boss := BOSS_SCENE.instantiate() as ExecutionerBoss
	boss.position = player.global_position + Vector2(90, 0)
	arena.add_child(boss)
	await flush(3)
	boss._state = boss.State.BLOCK
	boss._blocking = true
	_face(player, 1)
	ok(player.hookshot._try_melt_hook(player), "gate still melts with boss in range")
	ok(gate.is_queued_for_deletion() or not is_instance_valid(gate))
	ok(boss._state != boss.State.STAGGER, "nearby boss is not collateral")
