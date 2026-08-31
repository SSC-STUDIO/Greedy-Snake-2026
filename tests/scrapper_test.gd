extends TestCase


func test_scrapper_starts_on_patrol() -> void:
	var scrap := preload("res://scenes/enemies/ScrapperEnemy.tscn").instantiate() as ScrapperEnemy
	add_child(scrap)
	await flush(2)
	eq(scrap._state, ScrapperEnemy.State.PATROL, "idle beat is patrol")
	ok(scrap.health.current > 0)
