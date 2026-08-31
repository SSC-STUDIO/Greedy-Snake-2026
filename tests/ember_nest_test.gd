extends TestCase
## EmberNest shrine fire is a looping pixel strip shown only while lit.


func setup() -> void:
	WorldClock.reset()
	WorldClock.menu_hold = false
	Director.abort()
	Director.choice_hold = false


func teardown() -> void:
	WorldClock.reset()
	WorldClock.menu_hold = false
	Director.abort()
	Director.choice_hold = false


func test_flame_uses_looping_strip() -> void:
	var nest := EmberNest.new()
	add_child(nest)
	await flush(1)
	var flame := nest.get_node_or_null("Flame") as Sprite2D
	ok(flame != null, "Flame node exists")
	if flame == null:
		return
	ok(flame.texture != null, "flame has a texture")
	if flame.texture != null:
		eq(String(flame.texture.resource_path), "res://assets/fx/shrine_flame.png")
	eq(flame.hframes, 8, "8-frame strip")
	eq(flame.vframes, 1)
	eq(flame.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	nest.apply_persistent_state({"lit": true})
	var f0 := flame.frame
	nest._process(0.20)
	ok(flame.frame != f0, "frame advances instead of sitting still")


func test_unlit_hides_flame() -> void:
	var nest := EmberNest.new()
	add_child(nest)
	await flush(1)
	var flame := nest.get_node_or_null("Flame") as Sprite2D
	ok(flame != null, "Flame node exists")
	if flame == null:
		return
	eq(nest.get_persistent_state()["lit"], false)
	ok(not flame.visible, "unlit nest shows no flame")
	ok(flame.modulate != Color(0.62, 0.70, 0.92, 0.72), "unlit is not a gray/cold flame")
	var sparks := nest.get_node_or_null("Sparks") as Node2D
	ok(sparks != null, "Sparks node exists")
	if sparks != null:
		ok(not sparks.visible, "unlit nest shows no sparks")
		eq(sparks.get_child_count(), 0, "unlit nest has no spark children")
	var f0 := flame.frame
	nest._process(1.0)
	eq(flame.frame, f0, "unlit flame does not animate")
	if sparks != null:
		eq(sparks.get_child_count(), 0, "unlit nest still has no sparks after process")


func test_lit_shows_warm_flame() -> void:
	var nest := EmberNest.new()
	add_child(nest)
	await flush(1)
	var flame := nest.get_node_or_null("Flame") as Sprite2D
	ok(flame != null, "Flame node exists")
	if flame == null:
		return
	nest.apply_persistent_state({"lit": true})
	eq(nest.get_persistent_state()["lit"], true)
	ok(flame.visible, "lit nest shows the flame")
	var hot := flame.modulate
	eq(hot, Color(1.0, 0.92, 0.62, 1.0), "lit fire is warm orange-yellow")
	ok(hot.r > hot.b, "lit fire is warm, not gray")
	var sparks := nest.get_node_or_null("Sparks") as Node2D
	ok(sparks != null, "Sparks node exists")
	if sparks != null:
		ok(sparks.visible, "lit nest can emit sparks")
	nest.apply_persistent_state({"lit": false})
	ok(not flame.visible, "relit-off hides the flame again")


func test_collision_unchanged_by_flame() -> void:
	var nest := EmberNest.new()
	add_child(nest)
	await flush(2)
	var col: CollisionShape2D = null
	for child in nest.get_children():
		if child is CollisionShape2D:
			col = child
			break
	ok(col != null, "collision still created by ensure_sprite")
	if col == null:
		return
	var shape := col.shape as RectangleShape2D
	ok(shape != null)
	if shape != null:
		eq(shape.size, Vector2(18, 22))
	eq(nest.collision_layer, 64)
	eq(nest.collision_mask, 2)
	ok(nest.get_node_or_null("Fill") != null, "tombstone sprite still named Fill")


func test_unlit_has_no_nest_light() -> void:
	var nest := EmberNest.new()
	add_child(nest)
	await flush(1)
	var light := nest.get_node_or_null("NestLight") as PointLight2D
	ok(light != null, "NestLight exists so night can use it")
	if light == null:
		return
	eq(nest.get_persistent_state()["lit"], false)
	ok(not light.enabled, "unlit nest emits no point light")
	almost(light.energy, 0.0, 0.001, "unlit energy is zero, not a gray fire")


func test_lit_night_glow_stronger_than_day() -> void:
	var nest := EmberNest.new()
	add_child(nest)
	await flush(1)
	var light := nest.get_node_or_null("NestLight") as PointLight2D
	ok(light != null, "NestLight exists")
	if light == null:
		return
	WorldClock.set_time(0.80)
	nest.apply_persistent_state({"lit": true})
	ok(light.enabled, "lit nest enables the warm pool")
	var night_e := light.energy
	WorldClock.set_time(0.28)
	nest.apply_persistent_state({"lit": true})
	var day_e := light.energy
	ok(night_e > day_e + 0.40, "night energy is clearly above day")
	ok(day_e > 0.0 and day_e < 0.30, "day lit glow is a tongue, not a floodlight")
	ok(night_e >= 0.90)
	ok(light.color.r > light.color.b, "glow stays warm orange-yellow")
	nest.apply_persistent_state({"lit": false})
	ok(not light.enabled, "extinguishing snaps the light off")
	almost(light.energy, 0.0, 0.001)
