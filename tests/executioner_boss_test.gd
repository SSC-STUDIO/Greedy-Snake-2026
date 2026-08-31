extends TestCase
## ExecutionerBoss: half-HP enrage, starting HP.


func _spawn(arena: Node2D) -> ExecutionerBoss:
	const SCENE := preload("res://scenes/enemies/ExecutionerBoss.tscn")
	var b := SCENE.instantiate() as ExecutionerBoss
	b.position = Vector2(320, -20)
	arena.add_child(b)
	await flush(2)
	return b


func test_starts_with_boss_hp_and_not_enraged() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var b := await _spawn(arena)
	eq(b.health.max_hp, 13)
	eq(b.health.current, 13)
	ok(not b.is_enraged())


func test_enrages_at_half_hp() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var b := await _spawn(arena)
	b._set_blocking(false)
	b.health.take_damage(7, b)
	ok(b.is_enraged(), "half HP trips phase two")
	eq(b.health.current, 6)
