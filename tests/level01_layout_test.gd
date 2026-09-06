extends TestCase
## Level01 split: east wing still places heart/gate/Boss; story beats still fire.


func setup() -> void:
	SaveData.flags.clear()
	SaveData.pending_spawn = Vector2.INF
	Director.abort()
	Director.resume()
	Director.choice_hold = false


func teardown() -> void:
	SaveData.flags.clear()
	SaveData.pending_spawn = Vector2.INF
	Director.abort()
	Director.resume()
	Director.choice_hold = false
	if get_tree().paused:
		get_tree().paused = false


func test_teach_terrace_is_a_single_jump() -> void:
	almost(Level01Static.GROUND_TOP - Level01Static.TEACH_TERRACE_POS.y, Level01Static.STEP_RISE, 0.01)
	ok(Level01Static.STEP_RISE < Level01Static.JUMP_REACH, "32px step stays under the 37px jump")
	almost(Level01Static.TEACH_TERRACE_POS.y - Level01Static.TEACH_MID_Y, Level01Static.STEP_RISE, 0.01)
	var platforms := Node2D.new()
	platforms.name = "Platforms"
	add_child(platforms)
	var level := Level01Static.new()
	level.place_teach_layout(platforms)
	var terrace := platforms.get_node_or_null("TeachTerrace") as SolidPlatform
	ok(terrace != null, "teach terrace is placed")
	if terrace != null:
		eq(terrace.position, Level01Static.TEACH_TERRACE_POS)
		eq(terrace.size, Level01Static.TEACH_TERRACE_SIZE)
	level.free()


func test_east_pit_steps_are_single_jump_readable() -> void:
	almost(320.0 - Level01EastWing.PIT_CROSS_POS.y, 32.0, 0.01, "pit stone is a 32px hop")
	ok(Level01EastWing.PIT_CLIMB_LEFT_POS.y - Level01EastWing.PIT_LIP_LEFT_POS.y <= 32.0,
			"left bank cap must be reachable from the water lip")
	ok(Level01EastWing.PIT_CLIMB_RIGHT_POS.y - Level01EastWing.PIT_STEP_LOW_POS.y <= 32.0,
			"right bank cap must be reachable from the water lip")
	almost(Level01EastWing.PIT_STEP_LOW_POS.y - Level01EastWing.PIT_STEP_HIGH_POS.y, 32.0, 0.01, "high step is +32px")
	ok(Level01EastWing.PIT_CROSS_POS.x >= 400.0 and Level01EastWing.PIT_CROSS_POS.x + Level01EastWing.PIT_CROSS_SIZE.x <= 512.0,
			"crossing stone sits over the pit, not the walkway")
	var host := _make_host()
	var wing := Level01EastWing.new()
	add_child(wing)
	wing.build(host)
	for pair in [
		["PitClimbLeft", Level01EastWing.PIT_CLIMB_LEFT_POS],
		["PitClimbRight", Level01EastWing.PIT_CLIMB_RIGHT_POS],
		["PitLipLeft", Level01EastWing.PIT_LIP_LEFT_POS],
		["PitCross", Level01EastWing.PIT_CROSS_POS],
		["PitStepLow", Level01EastWing.PIT_STEP_LOW_POS],
		["PitStepHigh", Level01EastWing.PIT_STEP_HIGH_POS],
	]:
		var node := host.get_node_or_null("Platforms/%s" % String(pair[0])) as SolidPlatform
		ok(node != null, "%s was placed" % String(pair[0]))
		if node != null:
			eq(node.position, pair[1])


func test_pit_escape_is_a_single_jump() -> void:
	ok(Level01EastWing.pit_floor_to_bank() <= Level01Static.JUMP_REACH,
			"pit floor to bank is within a held single jump")
	ok(Level01EastWing.water_to_bank() <= Level01Static.JUMP_REACH,
			"water film to bank is within a single jump")
	almost(Level01EastWing.PIT_WATER_Y - Level01EastWing.PIT_CLIMB_LEFT_POS.y, 0.0, 0.01,
			"climb lip is at the water film")
	ok(Level01EastWing.PIT_FLOOR_Y - Level01EastWing.PIT_CLIMB_LEFT_POS.y <= Level01Static.JUMP_REACH,
			"pit floor to water lip is a single jump")
	ok(Level01EastWing.PIT_CLIMB_LEFT_POS.y - Level01EastWing.PIT_BANK_Y <= Level01Static.JUMP_REACH,
			"water lip to bank is a single jump")
	almost(Level01EastWing.PIT_CLIMB_LEFT_POS.y + Level01EastWing.PIT_CLIMB_LEFT_SIZE.y,
			Level01EastWing.PIT_FLOOR_Y, 0.01, "left climb sits on the pit floor")
	almost(Level01EastWing.PIT_CLIMB_RIGHT_POS.y + Level01EastWing.PIT_CLIMB_RIGHT_SIZE.y,
			Level01EastWing.PIT_FLOOR_Y, 0.01, "right climb sits on the pit floor")
	ok(Level01EastWing.PIT_CLIMB_LEFT_POS.x >= Level01EastWing.PIT_X0 - 0.01)
	ok(Level01EastWing.PIT_CLIMB_RIGHT_POS.x + Level01EastWing.PIT_CLIMB_RIGHT_SIZE.x
			<= Level01EastWing.PIT_X1 + 0.01)
	var open_w := Level01EastWing.PIT_CLIMB_RIGHT_POS.x \
			- (Level01EastWing.PIT_CLIMB_LEFT_POS.x + Level01EastWing.PIT_CLIMB_LEFT_SIZE.x)
	ok(open_w > 14.0, "open sludge is wider than the knight so they are not crushed")


func test_old_toxin_pit_is_raised_to_jump_reach() -> void:
	var host := _make_host()
	var pit: SolidPlatform = preload("res://scenes/world/Platform.tscn").instantiate()
	pit.name = "ToxinPit"
	pit.skin = "ground"
	pit.position = Vector2(400, 368)
	pit.size = Vector2(112, 32)
	host.get_node("Platforms").add_child(pit)
	var wing := Level01EastWing.new()
	add_child(wing)
	wing.build(host)
	var tuned := host.get_node_or_null("Platforms/ToxinPit") as SolidPlatform
	ok(tuned != null, "pit floor remains")
	if tuned != null:
		almost(tuned.position.y, Level01EastWing.PIT_FLOOR_Y, 0.01)
		eq(tuned.size, Level01EastWing.PIT_FLOOR_SIZE)


func test_knight_can_jump_from_pit_floor_onto_climb_lip() -> void:
	var arena := Node2D.new()
	add_child(arena)
	_plat(arena, Vector2(0, 320), Vector2(400, 80))
	_plat(arena, Vector2(Level01EastWing.PIT_X0, Level01EastWing.PIT_FLOOR_Y),
			Level01EastWing.PIT_FLOOR_SIZE)
	_plat(arena, Level01EastWing.PIT_CLIMB_LEFT_POS, Level01EastWing.PIT_CLIMB_LEFT_SIZE)
	_plat(arena, Level01EastWing.PIT_CLIMB_RIGHT_POS, Level01EastWing.PIT_CLIMB_RIGHT_SIZE)
	# Include the bank caps: omitting them hid a real 48px exit wall.
	_plat(arena, Level01EastWing.PIT_LIP_LEFT_POS, Level01EastWing.PIT_LIP_LEFT_SIZE)
	_plat(arena, Level01EastWing.PIT_STEP_LOW_POS, Level01EastWing.PIT_STEP_LOW_SIZE)
	_plat(arena, Level01EastWing.PIT_STEP_HIGH_POS, Level01EastWing.PIT_STEP_HIGH_SIZE)
	_plat(arena, Vector2(512, 320), Vector2(200, 80))
	var pool := ToxinPool.new()
	pool.position = Vector2(Level01EastWing.PIT_X0, Level01EastWing.PIT_WATER_Y)
	arena.add_child(pool)
	pool.configure(Vector2(112, 32))
	eq(pool.surface_rect().position.y, Level01EastWing.PIT_WATER_Y)
	var player: Player = preload("res://scenes/player/Player.tscn").instantiate()
	player.position = Vector2(448, 348)
	arena.add_child(player)
	await flush(20)
	ok(player.is_on_floor(), "settled on the pit floor")
	ok(player.global_position.y > Level01EastWing.PIT_WATER_Y + 4.0, "started below the water lip")
	player.controller.call("_do_jump", player, false)
	player.controller._cut_armed = false
	var lip_top := Level01EastWing.PIT_CLIMB_LEFT_POS.y
	var landed := false
	for i in 48:
		player.controller._apply_gravity(player, 1.0 / 60.0)
		player.velocity.x = -player.controller.max_speed
		player.move_and_slide()
		player.controller.settle_after_slide(player)
		await get_tree().physics_frame
		if player.is_on_floor() and player.global_position.y <= lip_top + 2.0 \
				and player.global_position.x < 440.0:
			landed = true
			break
	ok(landed, "jump from the sludge lands on the left climb lip")
	if landed:
		player.controller.call("_do_jump", player, false)
		player.controller._cut_armed = false
		var banked := false
		for i in 48:
			player.controller._apply_gravity(player, 1.0 / 60.0)
			player.velocity.x = -player.controller.max_speed
			player.move_and_slide()
			player.controller.settle_after_slide(player)
			await get_tree().physics_frame
			if player.is_on_floor() and player.global_position.y <= Level01EastWing.PIT_BANK_Y + 2.0 \
					and player.global_position.x < Level01EastWing.PIT_X0 + 2.0:
				banked = true
				break
		ok(banked, "second hop from the water lip lands on the bank")


func _plat(parent: Node2D, pos: Vector2, size: Vector2) -> void:
	var p: SolidPlatform = preload("res://scenes/world/Platform.tscn").instantiate()
	p.skin = "ground"
	p.position = pos
	p.size = size
	parent.add_child(p)


func test_waymarks_name_the_route() -> void:
	eq(Level01Static.WAYMARKS.size(), 4)
	var labels: Array[String] = []
	for item in Level01Static.WAYMARKS:
		var feet: Vector2 = item[0]
		almost(feet.y, Level01Static.GROUND_TOP, 0.01, "%s sits on the ground top" % String(item[1]))
		ok(feet.x < 400.0 or feet.x >= 512.0, "%s is not planted in the pit" % String(item[1]))
		labels.append(String(item[1]))
	ok(labels.has("腐液"))
	ok(labels.has("东翼"))
	ok(labels.has("压板"))
	ok(labels.has("余烬"))


func test_east_constants_stay_aligned() -> void:
	eq(Level01Static.EAST_LIMIT, Level01EastWing.EAST_LIMIT)
	almost(Level01Static.EAST_FLOOR_X, Level01EastWing.EAST_FLOOR_X, 0.01)
	var r := Level01EastWing.east_floor_rect()
	almost(r.position.x, Level01EastWing.EAST_FLOOR_X, 0.01)
	almost(r.end.x, float(Level01EastWing.EAST_LIMIT), 0.01, "east floor meets WallRight")
	ok(r.size.x > 608.0, "old 608px floor left a 32px pit")


func test_east_wing_places_heart_gate_and_boss() -> void:
	var host := _make_host()
	var wing := Level01EastWing.new()
	add_child(wing)
	var boss := wing.build(host)
	ok(boss != null, "fresh run spawns Executioner")
	ok(is_instance_valid(boss))
	var heart := host.get_node_or_null("Props/ForgeHeart") as ForgeHeart
	ok(heart != null, "ForgeHeart lives on Props")
	ok(not heart.unlocked, "heart stays locked while boss lives")
	ok(host.get_node_or_null("BossGate") != null, "BossGate on the level root")
	ok(host.get_node_or_null("Pickups/EmberCore") != null, "east ember pickup has a stable save path")
	var shelter := host.get_node_or_null("ForgeShelter") as AtmosphereZone
	ok(shelter != null, "forge remnant is an indoor AtmosphereZone")
	if shelter != null:
		eq(shelter.zone, WorldClock.Zone.INDOORS)
		eq(shelter.position, Level01EastWing.FORGE_SHELTER_POS)
	eq(host.get_node("BossGate").position, Vector2(1688, 280))
	var wall := host.get_node("Platforms/WallRight") as Node2D
	almost(wall.position.x, float(Level01EastWing.EAST_LIMIT), 0.01, "WallRight moved to east limit")
	var placed := false
	for child in host.get_node("Platforms").get_children():
		if child is SolidPlatform and absf(child.position.x - Level01EastWing.EAST_FLOOR_X) < 0.1 \
				and child.size.y >= 80.0:
			almost(child.position.x + child.size.x, float(Level01EastWing.EAST_LIMIT), 0.01,
					"spawned east floor meets the wall")
			ok(child.size.x > 608.0, "spawned floor is not the old 608px span")
			placed = true
	ok(placed, "east floor platform was placed")


func test_east_wing_skips_boss_and_unlocks_heart() -> void:
	SaveData.mark_flag("boss_dead")
	var host := _make_host()
	var wing := Level01EastWing.new()
	add_child(wing)
	var boss := wing.build(host)
	ok(boss == null, "flagged run skips Executioner")
	var heart := host.get_node_or_null("Props/ForgeHeart") as ForgeHeart
	ok(heart != null)
	ok(heart.unlocked, "flagged run lights the heart")


func test_first_toxin_starts_cutscene() -> void:
	var beats := _bind_beats()
	GameEvents.toxin_changed.emit(12.0, 100.0)
	ok(SaveData.has_flag("toxin"))
	ok(Director.playing, "first toxin queues Director")
	GameEvents.toxin_changed.emit(40.0, 100.0)
	eq(SaveData.flags.count("toxin"), 1, "repeat toxin does not re-flag")
	beats.queue_free()


func test_first_core_and_parry_start_cutscenes() -> void:
	var beats := _bind_beats()
	GameEvents.core_acquired.emit(AbilityCatalog.ember_core())
	ok(SaveData.has_flag("core"))
	ok(Director.playing, "first core queues Director")
	Director.abort()
	GameEvents.parried.emit(null, null)
	ok(SaveData.has_flag("parry"))
	ok(Director.playing, "first parry queues Director")
	beats.queue_free()


func test_wake_cutscene_marks_flag() -> void:
	var beats := _bind_beats()
	beats.try_wake()
	ok(SaveData.has_flag("wake"))
	ok(Director.playing, "first wake queues Director")
	Director.abort()
	beats.try_wake()
	ok(not Director.playing, "second wake is an announcement, not a script")
	beats.queue_free()


func test_boss_slain_unlocks_heart_and_plays() -> void:
	var host := _make_host()
	var wing := Level01EastWing.new()
	add_child(wing)
	wing.build(host)
	var beats := Level01StoryBeats.new()
	add_child(beats)
	beats.bind(host, null, wing.boss)
	beats.on_boss_slain()
	ok(SaveData.has_flag("boss_dead"))
	var heart := host.get_node("Props/ForgeHeart") as ForgeHeart
	ok(heart.unlocked, "slain beat unlocks the heart")
	ok(Director.playing, "slain beat queues Director")


func test_parallax_adds_mood_tint() -> void:
	var host := Node2D.new()
	add_child(host)
	var backdrop := CanvasLayer.new()
	backdrop.name = "ParallaxBackdrop"
	host.add_child(backdrop)
	var far := Parallax2D.new()
	far.name = "Far"
	backdrop.add_child(far)
	var extras := Level01Parallax.new()
	add_child(extras)
	extras.build(host)
	ok(host.get_node_or_null("MoodTint") != null, "mood tint lands on the host")


func _bind_beats() -> Level01StoryBeats:
	var beats := Level01StoryBeats.new()
	add_child(beats)
	beats.bind(self, null, null)
	return beats


func _make_host() -> Node2D:
	var host := Node2D.new()
	add_child(host)
	for folder in ["Platforms", "Hooks", "Pickups", "Props"]:
		var node := Node2D.new()
		node.name = folder
		host.add_child(node)
	var wall := Node2D.new()
	wall.name = "WallRight"
	wall.position = Vector2(1600, 0)
	host.get_node("Platforms").add_child(wall)
	return host
