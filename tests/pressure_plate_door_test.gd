extends TestCase


func test_slam_opens_persistent_door() -> void:
	var door := ArenaDoor.new()
	add_child(door)
	var plate := PressurePlate.new()
	add_child(plate)
	plate.activated.connect(door.open_door)
	await flush(1)
	ok(not door.is_open)
	plate.slam()
	ok(door.is_open)
	var state := door.get_persistent_state()
	eq(state.get("open"), true)
	var other := ArenaDoor.new()
	add_child(other)
	await flush(1)
	other.apply_persistent_state(state)
	ok(other.is_open, "door remembers the latch")


func test_plate_trigger_is_taller_than_the_stone() -> void:
	var plate := PressurePlate.new()
	add_child(plate)
	await flush(1)
	var col: CollisionShape2D = null
	for child in plate.get_children():
		if child is CollisionShape2D:
			col = child
			break
	ok(col != null, "plate still has a trigger box")
	if col == null:
		return
	var shape := col.shape as RectangleShape2D
	ok(shape != null)
	if shape != null:
		eq(shape.size, Vector2(40, 26), "32×10 stone + reach_pad (4, 8)")
		ok(shape.size.y > 10.0, "trigger is taller than the lip")
