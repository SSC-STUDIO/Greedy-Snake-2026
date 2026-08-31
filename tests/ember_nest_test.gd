extends TestCase
## EmberNest shrine fire is a looping pixel strip, not a modulate-only glow.


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
	var f0 := flame.frame
	nest._process(0.20)
	ok(flame.frame != f0, "frame advances instead of sitting still")


func test_lit_state_warms_the_flame() -> void:
	var nest := EmberNest.new()
	add_child(nest)
	await flush(1)
	var flame := nest.get_node_or_null("Flame") as Sprite2D
	ok(flame != null, "Flame node exists")
	if flame == null:
		return
	var cold := flame.modulate
	eq(nest.get_persistent_state()["lit"], false)
	ok(cold.b > cold.r, "unlit fire is cold / blue-gray")
	nest.apply_persistent_state({"lit": true})
	eq(nest.get_persistent_state()["lit"], true)
	var hot := flame.modulate
	ok(hot.r > cold.r, "lit fire is warmer")
	ok(hot.a > cold.a, "lit fire is brighter")


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
