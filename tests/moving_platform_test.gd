extends TestCase
## 吊台：余弦往返、链条到顶、骑士站上去跟着走。


func test_shuttle_math_and_visuals() -> void:
	var arena := Node2D.new()
	add_child(arena)
	var lift := MovingPlatform.new()
	lift.position = Vector2(100, 200)
	lift.travel = Vector2(0, -80)
	lift.period = 4.0
	lift.width = 48.0
	lift.chain_top_y = 0.0
	arena.add_child(lift)
	await flush(1)
	eq(lift.start_position(), Vector2(100, 200))
	eq(lift.end_position(), Vector2(100, 120))
	almost(lift.position_at(0.0).y, 200.0, 0.01)
	almost(lift.position_at(2.0).y, 120.0, 0.01, "half period = far end")
	almost(lift.position_at(1.0).y, 160.0, 0.01, "quarter period = midway (cosine ease)")
	ok(lift.sync_to_physics)
	var col := lift.get_node("CollisionShape2D") as CollisionShape2D
	eq((col.shape as RectangleShape2D).size, Vector2(48, 16))
	var chain := lift.get_node("Chain0") as Line2D
	ok(chain.visible, "chains hang from the ceiling")
	ok(chain.points[1].y < 0.0, "chain reaches up to chain_top_y")
	var sprites := 0
	for child in lift.get_children():
		if child is Sprite2D:
			sprites += 1
	ok(sprites == 3 or lift.get_node_or_null("VisualRect") != null, "three moss pieces (or the headless fallback)")


func test_knight_rides_the_lift() -> void:
	var arena := Node2D.new()
	add_child(arena)
	var lift := MovingPlatform.new()
	lift.position = Vector2(0, 100)
	lift.travel = Vector2(160, 0)
	lift.period = 2.0
	lift.width = 96.0
	arena.add_child(lift)
	var player := await spawn_player(arena)
	player.global_position = Vector2(48, 100)
	player.velocity = Vector2.ZERO
	await flush(2)
	var start_x := player.global_position.x
	await flush(45)  # ~0.75s: lift is well on its way to x=160
	ok(player.is_on_floor(), "knight stands on the moving deck")
	ok(player.global_position.x > start_x + 40.0,
			"knight carried along (%.0f → %.0f)" % [start_x, player.global_position.x])
	ok(absf(player.global_position.y - lift.position.y) < 3.0, "knight stays on the deck surface")
