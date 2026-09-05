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
	ok(not heart.can_interact(heart), "flag alone does not unlock a locked heart")
	ok(not heart.monitoring, "flag does not turn monitoring back on")
	heart.unlock()
	await flush(1)
	ok(heart.can_interact(heart), "unlock → can E")
	ok(heart.monitoring)


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
	var r := Level01Static.east_floor_rect()
	almost(r.position.x, Level01Static.EAST_FLOOR_X, 0.01, "east floor starts at GroundRight end")
	almost(r.end.x, float(Level01Static.EAST_LIMIT), 0.01, "east floor ends at WallRight")
	ok(r.size.x > 608.0, "old 608px floor left a 32px pit before the wall")
	almost(r.size.x, float(Level01Static.EAST_LIMIT) - Level01Static.EAST_FLOOR_X, 0.01)


func test_locked_heart_is_not_sensor_focus() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	var heart := ForgeHeart.new()
	heart.position = player.global_position
	arena.add_child(heart)
	await flush(3)
	ok(not heart.can_interact(player))
	ok(player.sensor.get_focus() != heart, "locked heart is not an E target")
	heart.unlock()
	await flush(1)
	player.sensor._on_area_entered(heart)
	eq(player.sensor.get_focus(), heart, "unlocked heart is focusable")
