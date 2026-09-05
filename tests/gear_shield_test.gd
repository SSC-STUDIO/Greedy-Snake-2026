extends TestCase
## GearShieldEnemy: frontal defense blocks damage, flanking lands it, and a
## deflected bolt staggers the shield open. Drives the state machine directly
## through public seams for determinism.


func _spawn(arena: Node2D, x: float) -> GearShieldEnemy:
	const SCENE := preload("res://scenes/enemies/GearShieldEnemy.tscn")
	var g := SCENE.instantiate() as GearShieldEnemy
	g.position = Vector2(x, -20)
	arena.add_child(g)
	await flush(2)
	return g


## Force the guard into its guarding posture facing `side` (1 = right).
func _enter_guard(g: GearShieldEnemy, side: int) -> void:
	g._state = g.State.BLOCK
	g._shield_facing = side
	g._blocking = false
	g._set_blocking(true)
	g._update_visual()


func test_patrol_idle_takes_full_damage() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var g := await _spawn(arena, 320.0)
	g._set_blocking(false)
	var hp := g.health.current
	g.hurtbox.receive_hit(1, g)
	eq(g.health.current, hp - 1, "unguarded hit lands")


func test_frontal_melee_is_absorbed_by_shield() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var g := await _spawn(arena, 320.0)
	_enter_guard(g, 1)  # guarding toward the +x side
	var hp := g.health.current
	# Simulate a player hitbox striking from the guarded side.
	var fake := Node2D.new()
	fake.position = g.global_position + Vector2(30, 0)
	arena.add_child(fake)
	g.hurtbox.receive_hit(2, fake)
	eq(g.health.current, hp, "frontal hit is blocked, no damage")
	ok(g._state == g.State.BLOCK or g._state == g.State.CHARGE, "stays guarding after a blocked melee")


func test_flanking_hit_goes_around_the_shield() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var g := await _spawn(arena, 320.0)
	_enter_guard(g, 1)  # guarding the +x side
	var hp := g.health.current
	var fake := Node2D.new()
	fake.position = g.global_position + Vector2(-30, 0)  # other side = flank
	arena.add_child(fake)
	g.hurtbox.receive_hit(1, fake)
	eq(g.health.current, hp - 1, "flank attack damages")


func test_deflected_bolt_staggers_shield_open() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var g := await _spawn(arena, 320.0)
	_enter_guard(g, -1)  # guarding the -x (left) side
	const PROJ := preload("res://scenes/combat/Projectile.tscn")
	var bolt := PROJ.instantiate() as Projectile
	# A deflected bolt flying back at the guard from the guarded (left) side.
	bolt.setup(g.global_position + Vector2(40, -20), Vector2.LEFT, 200.0, &"player", g)
	arena.add_child(bolt)
	await flush(1)
	g.hurtbox.receive_hit(1, bolt)
	eq(g.health.current, g.health.max_hp, "deflected bolt does not chip HP")
	ok(g._state == g.State.STAGGER, "shield staggered open")
	ok(not g._blocking, "no longer blocking during stagger")


func test_hit_flash_keeps_block_tint() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var g := await _spawn(arena, 320.0)
	_enter_guard(g, 1)
	g._flash_white()
	ok(g._indicator.modulate != Color.WHITE, "block telegraph survives the hit flash")
	eq(g._flash_restore_color(), Color.WHITE, "parent Visual flash still restores to white")


func test_stagger_recovers_to_guarding() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var g := await _spawn(arena, 320.0)
	_enter_guard(g, 1)
	g._enter_stagger()
	ok(g._state == g.State.STAGGER)
	for i in ceili((g.stagger_time + 0.05) * 60.0):
		g._tick_stagger(1.0 / 60.0)
	ok(g._state == g.State.BLOCK, "recovers to guarding")
	ok(g._blocking, "shield raised again")
