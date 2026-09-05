extends TestCase


func _spawn_scrap(arena: Node2D) -> ScrapperEnemy:
	var scrap := preload("res://scenes/enemies/ScrapperEnemy.tscn").instantiate() as ScrapperEnemy
	scrap.position = Vector2(320, -20)
	arena.add_child(scrap)
	await flush(2)
	return scrap


func test_scrapper_starts_on_patrol() -> void:
	var scrap := preload("res://scenes/enemies/ScrapperEnemy.tscn").instantiate() as ScrapperEnemy
	add_child(scrap)
	await flush(2)
	eq(scrap._state, ScrapperEnemy.State.PATROL, "idle beat is patrol")
	ok(scrap.health.current > 0)


func test_windup_tints_visual_for_readable_telegraph() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var scrap := await _spawn_scrap(arena)
	scrap._enter_windup()
	eq(scrap._state, ScrapperEnemy.State.WINDUP)
	eq(scrap.visual.modulate, ScrapperEnemy.WINDUP_TINT, "pixel body carries the windup, not the hidden Eye")


func test_charge_clears_already_hit_and_sets_knockback() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var scrap := await _spawn_scrap(arena)
	scrap._dir = 1.0
	scrap.charge_box.already_hit.append(scrap)
	scrap._arm_charge()
	eq(scrap.charge_box.already_hit.size(), 0, "each charge can hit the player again")
	ok(scrap.charge_box.monitoring)
	eq(scrap.charge_box.knockback, Vector2(ScrapperEnemy.CHARGE_KNOCKBACK_X, ScrapperEnemy.CHARGE_KNOCKBACK_Y))


func test_hitstun_keeps_melee_knockback() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var scrap := await _spawn_scrap(arena)
	scrap._state = ScrapperEnemy.State.PATROL
	var box := Hitbox.new()
	box.team = &"player"
	box.knockback = Vector2(90.0, -24.0)
	arena.add_child(box)
	box.global_position = scrap.global_position + Vector2(-20, -8)
	var hurt := scrap.get_node("Hurtbox") as Hurtbox
	scrap.velocity = Vector2.ZERO
	hurt.receive_hit(1, box)
	almost(scrap.velocity.x, 90.0, 0.01, "hurtbox applied knockback")
	ok(scrap._hurt_lock > 0.0, "hitstun latched")
	var held := scrap.velocity.x
	scrap._physics_process(1.0 / 60.0)
	almost(scrap.velocity.x, held, 8.0, "AI did not overwrite knockback during hitstun")


func test_death_disables_charge_box() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var scrap := await _spawn_scrap(arena)
	scrap.charge_box.arm(Vector2(80, -20))
	ok(scrap.charge_box.monitoring)
	scrap.health.take_damage(99, scrap)
	ok(scrap._dead)
	ok(not scrap.charge_box.monitoring, "dying brute cannot still ram the player")
	eq(scrap.collision_layer, 0)
