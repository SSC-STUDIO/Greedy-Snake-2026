extends TestCase
## Parry economy: purify on deflect + resonance window timing.


func test_potency_bands() -> void:
	var t := ToxinMeter.new()
	eq(t.band(), &"cold")
	almost(t.potency(), 0.0, 0.01)
	t.toxin = 30.0
	eq(t.band(), &"warm")
	almost(t.potency(), 0.5, 0.01)
	t.toxin = 60.0
	eq(t.band(), &"hot")
	almost(t.potency(), 0.85, 0.01)
	t.toxin = 100.0
	eq(t.band(), &"overflow")
	almost(t.potency(), 1.0, 0.01)
	t.free()


func test_resonance_pulse_expires() -> void:
	var r := Resonance.new()
	add_child(r)
	ok(not r.is_active())
	r.pulse()
	ok(r.is_active())
	r._process(1.0)
	ok(r.is_active(), "still live after 1s")
	r._process(1.1)
	ok(not r.is_active(), "expires after 2s")


func test_deflect_purifies_and_pulses_resonance() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	player.toxin.toxin = 50.0
	const PROJ := preload("res://scenes/combat/Projectile.tscn")
	var shooter := Node2D.new()
	shooter.position = Vector2(480, -38)
	arena.add_child(shooter)
	var bolt: Projectile = PROJ.instantiate()
	bolt.setup(Vector2(340, -38), Vector2.LEFT, 40.0, &"enemy", shooter)
	arena.add_child(bolt)
	await flush(2)
	ok(player.melee.start_swing())
	await wait_until(func() -> bool: return player.melee.is_parry_window(), 60)
	player.toxin.toxin = 50.0
	ok(player.melee.try_deflect(bolt))
	almost(player.toxin.toxin, 38.0, 0.2, "parry purifies 12%")
	ok(player.resonance.is_active(), "resonance window opened")
