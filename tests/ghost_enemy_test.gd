extends TestCase
## 地窟幽魂：沉睡 → 靠近凝出 → 实体追猎 → 到时散雾 → 从骑士背后重新凝出。

const GHOST := preload("res://scenes/enemies/GhostEnemy.tscn")


func _spawn(arena: Node2D, pos: Vector2) -> GhostEnemy:
	var ghost := GHOST.instantiate() as GhostEnemy
	ghost.position = pos
	arena.add_child(ghost)
	return ghost


func test_dormant_ghost_is_invisible_and_intangible_until_the_knight_is_near() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	var ghost := _spawn(arena, player.global_position + Vector2(400, -40))
	await flush(3)
	eq(ghost.state(), GhostEnemy.State.DORMANT, "far away it sleeps")
	ok(not ghost.visual.visible, "sleeping ghost is not drawn")
	ok(not ghost.is_tangible(), "sleeping ghost cannot be hit or hurt")
	ok(not ghost.hurtbox.monitorable, "hurtbox stays off while dormant")
	ghost.global_position = player.global_position + Vector2(120, -40)
	await flush(2)
	eq(ghost.state(), GhostEnemy.State.APPEAR, "within wake range it condenses")
	ok(ghost.visual.visible)
	ok(not ghost.is_tangible(), "still untouchable while appearing")


func test_haunting_ghost_drifts_toward_the_knight_through_walls() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	# A wall between them: ghosts do not care.
	var wall := StaticBody2D.new()
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(16, 120)
	col.shape = shape
	wall.add_child(col)
	wall.position = player.global_position + Vector2(50, -40)
	wall.collision_layer = 1
	arena.add_child(wall)
	var ghost := _spawn(arena, player.global_position + Vector2(140, -40))
	ghost.drift_speed = 120.0
	await flush(2)
	# Skip the appear animation.
	for i in 60:
		await flush(1)
		if ghost.state() == GhostEnemy.State.HAUNT:
			break
	eq(ghost.state(), GhostEnemy.State.HAUNT)
	ok(ghost.is_tangible(), "haunting ghost can be struck")
	var start_dx := absf(ghost.global_position.x - player.global_position.x)
	await flush(80)
	var now_dx := absf(ghost.global_position.x - player.global_position.x)
	ok(now_dx < start_dx - 40.0, "ghost closed distance (%.0f -> %.0f)" % [start_dx, now_dx])
	ok(ghost.global_position.x < wall.position.x, "ghost passed the wall line (x=%.0f, wall=%.0f)" % [ghost.global_position.x, wall.position.x])


func test_ghost_rephases_behind_the_knight_after_haunting_too_long() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	player.visual.scale.x = 1.0 # facing right
	var ghost := _spawn(arena, player.global_position + Vector2(100, -40))
	ghost.haunt_time = 0.3
	ghost.gone_time = 0.1
	ghost.drift_speed = 0.0
	await flush(2)
	var saw_vanish := false
	for i in 120:
		await flush(1)
		if ghost.state() == GhostEnemy.State.VANISH or ghost.state() == GhostEnemy.State.GONE:
			saw_vanish = true
			ok(not ghost.is_tangible(), "vanishing ghost is untouchable")
		if ghost.rephase_count() >= 1 and ghost.state() == GhostEnemy.State.APPEAR:
			break
	ok(saw_vanish, "ghost dissolved after its haunt time")
	eq(ghost.rephase_count(), 1, "one rephase happened")
	ok(ghost.global_position.x < player.global_position.x, "it re-formed behind a right-facing knight")
	almost(absf(ghost.global_position.x - player.global_position.x), GhostEnemy.REPHASE_OFFSET, 0.5)


func test_two_hits_dissolve_the_ghost() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	var ghost := _spawn(arena, player.global_position + Vector2(60, -40))
	await flush(2)
	for i in 60:
		await flush(1)
		if ghost.state() == GhostEnemy.State.HAUNT:
			break
	eq(ghost.health.max_hp, 2)
	ghost.hurtbox.receive_hit(1, player)
	await flush(1)
	ok(is_instance_valid(ghost) and not ghost._dead, "one hit leaves it haunting")
	await flush(30)  # past Health's 0.45s i-frames
	ghost.hurtbox.receive_hit(1, player)
	await flush(2)
	ok(not is_instance_valid(ghost) or ghost._dead, "second hit dissolves it")
