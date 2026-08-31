extends TestCase
## 过场锁：满溢不伤、毒池停灌、敌人停手、fade_to 掐剧本。


func setup() -> void:
	Director.abort()
	Director.resume()
	Director.choice_hold = false


func teardown() -> void:
	Director.abort()
	Director.resume()


func test_overflow_does_not_damage_while_cutscene_locked() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	var hp := player.health.current
	player.cutscene_locked = true
	player._on_toxin_overflow()
	eq(player.health.current, hp, "locked knight is not overflow-chipped")
	player.cutscene_locked = false
	player._on_toxin_overflow()
	eq(player.health.current, hp - 1, "overflow resumes after unlock")


func test_toxin_pool_stops_expose_while_director_locked() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	var pool := ToxinPool.new()
	arena.add_child(pool)
	pool._bodies.append(player)
	player.toxin.toxin = 10.0
	Director.play([{"kind": "lock"}, {"kind": "wait", "seconds": 8.0}])
	ok(Director.is_input_locked())
	pool._physics_process(1.0)
	almost(player.toxin.toxin, 10.0, 0.01, "pool does not fill during lock")
	Director.abort()
	ok(not Director.is_input_locked())
	pool._physics_process(1.0)
	ok(player.toxin.toxin > 10.0, "pool resumes after unlock")


func test_gear_shield_freezes_ai_while_locked() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	const SCENE := preload("res://scenes/enemies/GearShieldEnemy.tscn")
	var guard := SCENE.instantiate() as GearShieldEnemy
	guard.position = player.global_position + Vector2(40, 0)
	arena.add_child(guard)
	await flush(2)
	guard._state = guard.State.BLOCK
	guard._shoot_timer = 0.05
	Director.play([{"kind": "lock"}, {"kind": "wait", "seconds": 8.0}])
	await flush(10)
	eq(guard._state, guard.State.BLOCK, "cutscene freeze keeps the guard from charging")
	almost(guard._shoot_timer, 0.05, 0.02, "shoot clock does not advance")
	Director.abort()


func test_fade_to_aborts_playing_cutscene() -> void:
	Director.play([
		{"kind": "lock"},
		{"kind": "wait", "seconds": 8.0},
		{"kind": "unlock"},
	])
	ok(Director.playing)
	ok(Director.is_input_locked())
	Director.fade_to("res://scenes/ui/TitleScreen.tscn")
	ok(not Director.playing, "fade_to abort()s the live script")
	ok(not Director.is_input_locked(), "lock does not survive the fade")
	var done := await wait_until(func() -> bool: return not Director.is_fading(), 120)
	ok(done, "fade still completes")
