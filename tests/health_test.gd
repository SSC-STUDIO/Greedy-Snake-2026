extends TestCase
## Health: i-frames, death latch, heal_full.


func test_damage_reduces_hp_and_signals() -> void:
	var hp := Health.new()
	add_child(hp)
	var changes: Array = []
	hp.changed.connect(func(c, m): changes.append([c, m]))
	eq(hp.current, hp.max_hp)
	ok(hp.take_damage(2), "first hit should land")
	eq(hp.current, hp.max_hp - 2)
	eq(changes.size(), 1)


func test_iframes_block_followup_hits_then_expire() -> void:
	var hp := Health.new()
	add_child(hp)
	ok(hp.take_damage(1), "hit lands")
	ok(not hp.take_damage(1), "iframe blocks immediate re-hit")
	# Burn off the iframe window manually (default 0.45 s).
	for i in 30:
		hp._process(0.02)
	ok(hp.take_damage(1), "iframe expires")


func test_death_fires_once_and_latches_invincible() -> void:
	var hp := Health.new()
	add_child(hp)
	var deaths := [0]
	hp.died.connect(func(): deaths[0] += 1)
	hp.take_damage(hp.max_hp + 10)
	eq(hp.current, 0)
	eq(deaths[0], 1)
	hp.take_damage(5)
	eq(deaths[0], 1, "dead pool must not emit died twice")


func test_heal_full_revives_and_refills() -> void:
	var hp := Health.new()
	add_child(hp)
	hp.take_damage(hp.max_hp)
	for i in 30:
		hp._process(0.02) # burn the post-hit i-frame
	hp.heal_full()
	eq(hp.current, hp.max_hp)
	ok(not hp.is_invincible(), "heal clears death latch")
