extends TestCase
## Ending choice and pause must not fight over tree.paused.


func setup() -> void:
	Director.choice_hold = false
	if get_tree().paused:
		get_tree().paused = false


func teardown() -> void:
	Director.choice_hold = false
	Director.resume()
	if get_tree().paused:
		get_tree().paused = false


func test_choice_hold_blocks_pause_open() -> void:
	var menu := PauseMenu.new()
	add_child(menu)
	await flush(1)
	Director.choice_hold = true
	get_tree().paused = true
	menu.open()
	ok(not menu.is_open(), "choice hold blocks Esc pause")
	ok(get_tree().paused, "ending stay paused")


func test_choice_hold_close_does_not_unpause() -> void:
	var menu := PauseMenu.new()
	add_child(menu)
	await flush(1)
	menu.open()
	ok(menu.is_open())
	ok(get_tree().paused)
	Director.choice_hold = true
	menu.close()
	ok(not menu.is_open(), "pause layer hides")
	ok(get_tree().paused, "close does not resume the tree during ending")
