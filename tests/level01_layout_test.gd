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


func test_pit_floor_is_within_jump_reach() -> void:
	ok(Level01EastWing.PIT_FLOOR_Y - Level01EastWing.PIT_BANK_Y <= Level01Static.JUMP_REACH)
	almost(Level01EastWing.PIT_WATER_Y, Level01EastWing.PIT_CLIMB_LEFT_POS.y, 0.01)
	eq(Level01EastWing.PIT_WATER_SIZE, Vector2(112, 32))
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
	ok(tuned != null)
	if tuned != null:
		almost(tuned.position.y, Level01EastWing.PIT_FLOOR_Y, 0.01)
		eq(tuned.size, Level01EastWing.PIT_FLOOR_SIZE)
	ok(host.get_node_or_null("Platforms/PitClimbLeft") != null)
	ok(host.get_node_or_null("Platforms/PitClimbRight") != null)


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
	var backdrop := CanvasLayer.new()
	backdrop.name = "ParallaxBackdrop"
	host.add_child(backdrop)
	var far := Parallax2D.new()
	far.name = "Far"
	far.follow_viewport = false
	backdrop.add_child(far)
	var extras := Level01Parallax.new()
	add_child(extras)
	extras.build(host)
	ok(host.get_node_or_null("MoodTint") != null, "mood tint lands on the host")
	var sil := backdrop.get_node_or_null("NearSilhouette")
	ok(sil != null, "silhouette strip is planted")
	if sil != null:
		for child in sil.get_children():
			var path := ""
			if child is Sprite2D and (child as Sprite2D).texture != null:
				path = (child as Sprite2D).texture.resource_path
			elif child.get_child_count() > 0:
				var spr := child.get_child(0)
				if spr is Sprite2D and (spr as Sprite2D).texture != null:
					path = (spr as Sprite2D).texture.resource_path
			if path != "":
				ok(Level01Env.is_foliage(path), "silhouette stays foliage, not stone")


func test_mountain_tile_is_narrower_than_the_640_view() -> void:
	var tile := 192.0 * 1.7
	almost(tile, 326.4, 0.01)
	ok(tile * 2.0 < float(PresentationMetrics.WORLD_SIZE.x) + Level01Parallax.COVER_PAD,
			"one Godot mirror of 326px cannot cover 640 plus look-ahead")
	ok(Level01Parallax.copies_for_view(tile) >= Level01Parallax.MIN_REPEAT_TIMES)
	ok(float(Level01Parallax.copies_for_view(tile)) * floorf(tile)
			>= float(PresentationMetrics.WORLD_SIZE.x) + Level01Parallax.COVER_PAD)


func test_cover_layer_repeats_mountains_across_the_view() -> void:
	var layer := Parallax2D.new()
	add_child(layer)
	var spr := Sprite2D.new()
	spr.name = "Sprite"
	spr.centered = false
	spr.texture = load("res://assets/env/parallax_mountains.png") as Texture2D
	spr.scale = Vector2(1.7, 1.7)
	layer.add_child(spr)
	var extra := spr.duplicate() as Sprite2D
	extra.name = "Sprite_1"
	extra.position.x = 326.4
	layer.add_child(extra)
	layer.repeat_size = Vector2(326.4, 0)
	layer.repeat_times = 1
	Level01Parallax.cover_layer(layer)
	var n := 0
	for child in layer.get_children():
		if child is Sprite2D:
			n += 1
	eq(n, 1, "Parallax2D keeps one plate and repeats it")
	ok(not layer.follow_viewport, "plates live on a screen-space CanvasLayer")
	eq(layer.repeat_size.x, 326.0)
	ok(layer.repeat_times >= Level01Parallax.MIN_REPEAT_TIMES)
	ok(layer.repeat_size.x * float(layer.repeat_times)
			>= float(PresentationMetrics.WORLD_SIZE.x) + Level01Parallax.COVER_PAD)
	Level01Parallax.cover_layer(layer)
	var n2 := 0
	for child in layer.get_children():
		if child is Sprite2D:
			n2 += 1
	eq(n2, 1, "covering twice does not keep cloning")


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
