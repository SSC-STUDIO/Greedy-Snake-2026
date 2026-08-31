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
