extends TestCase


func setup() -> void:
	SaveData.pending_spawn = Vector2.INF
	SaveData.lit_nests.clear()


func teardown() -> void:
	SaveData.pending_spawn = Vector2.INF
	SaveData.lit_nests.clear()


func test_pending_spawn_is_consumed_once() -> void:
	ok(not SaveData.has_pending_spawn())
	SaveData.pending_spawn = Vector2(150, 290)
	ok(SaveData.has_pending_spawn())
	var pos := SaveData.consume_pending_spawn()
	eq(pos, Vector2(150, 290))
	ok(not SaveData.has_pending_spawn(), "second consume is empty")


func test_unlit_path_has_no_pending_spawn() -> void:
	eq(SaveData.lit_nests.size(), 0)
	ok(not SaveData.has_pending_spawn(), "no nest means no override spawn")
