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
	var backdrop := ParallaxBackground.new()
	backdrop.name = "ParallaxBackdrop"
	host.add_child(backdrop)
	var far := ParallaxLayer.new()
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
