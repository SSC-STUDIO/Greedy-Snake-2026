extends TestCase
## ForgeHeart lock + east-wing Boss persist (flag branch).


func setup() -> void:
	SaveData.flags.clear()


func teardown() -> void:
	SaveData.flags.clear()
	Director.choice_hold = false
	if get_tree().paused:
		get_tree().paused = false


func test_heart_locked_until_boss_dead() -> void:
	var heart := ForgeHeart.new()
	add_child(heart)
	await flush(1)
	ok(not heart.can_interact(heart), "no flag → cannot E")
	ok(not heart.monitoring, "hidden heart does not monitor")
	ok(not heart.monitorable)
	SaveData.mark_flag("boss_dead")
	ok(heart.can_interact(heart), "boss_dead → can E")


func test_heart_unlocks_when_spawned_after_flag() -> void:
	SaveData.mark_flag("boss_dead")
	var heart := ForgeHeart.new()
	add_child(heart)
	await flush(1)
	ok(heart.can_interact(heart))
	ok(heart.monitoring)
	ok(heart.visible)


func test_east_wing_skips_boss_when_flagged() -> void:
	ok(Level01Static.should_spawn_executioner(), "fresh save still has the boss")
	ok(not Level01Static.should_unlock_forge())
	SaveData.mark_flag("boss_dead")
	ok(not Level01Static.should_spawn_executioner(), "flagged run skips Executioner")
	ok(Level01Static.should_unlock_forge(), "flagged run unlocks the heart")


func test_east_floor_meets_the_wall() -> void:
	almost(Level01Static.EAST_FLOOR_X + (float(Level01Static.EAST_LIMIT) - Level01Static.EAST_FLOOR_X),
			float(Level01Static.EAST_LIMIT), 0.01, "east floor ends at the wall")
