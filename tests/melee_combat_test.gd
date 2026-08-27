extends TestCase
## MeleeCombat state machine driven manually via tick()/start_swing().
## Timings asserted at 60 fps frames from the GDD budget:
## windup ~0.18 s, active ~0.12 s (parry window), recovery ~0.26 s, cooldown gate.


var melee: MeleeCombat


func setup() -> void:
	melee = MeleeCombat.new()
	var hb := Area2D.new()
	hb.name = "Hitbox"
	hb.set_script(load("res://scripts/combat/hitbox.gd"))
	melee.add_child(hb)
	add_child(melee)


func _frames_for(seconds: float) -> int:
	return ceili(seconds * 60.0) + (1 if seconds > 0.0 else 0)


func test_idle_by_default_and_not_parrying() -> void:
	eq(melee.phase_name(), "idle")
	ok(not melee.is_busy())
	ok(not melee.is_parry_window())


func test_swing_walks_windup_active_recovery_and_back_to_idle() -> void:
	ok(melee.start_swing(), "swing starts from idle")
	eq(melee.phase_name(), "windup")

	for i in _frames_for(melee.windup_time):
		melee.tick(1.0 / 60.0)
	eq(melee.phase_name(), "active")
	ok(melee.is_parry_window(), "ACTIVE frames are the parry window")
	ok(mele_hitbox_monitoring())

	for i in _frames_for(melee.active_time):
		melee.tick(1.0 / 60.0)
	eq(melee.phase_name(), "recovery")
	ok(not melee.is_parry_window())
	ok(not mele_hitbox_monitoring(), "hitbox closes after active frames")

	for i in _frames_for(melee.recovery_time):
		melee.tick(1.0 / 60.0)
	eq(melee.phase_name(), "idle")
	ok(not melee.is_busy())


func test_cooldown_blocks_immediate_second_swing() -> void:
	ok(melee.start_swing())
	for i in _frames_for(melee.windup_time + melee.active_time + melee.recovery_time):
		melee.tick(1.0 / 60.0)
	eq(melee.phase_name(), "idle", "back to idle inside cooldown")
	ok(not melee.start_swing(), "cooldown still gating")
	for i in _frames_for(melee.cooldown):
		melee.tick(1.0 / 60.0)
	ok(melee.start_swing(), "cooldown expired")


func test_second_swing_while_busy_is_refused() -> void:
	ok(melee.start_swing())
	ok(not melee.start_swing(), "busy refuses re-entry")


func mele_hitbox_monitoring() -> bool:
	return (melee.hitbox as Area2D).monitoring
