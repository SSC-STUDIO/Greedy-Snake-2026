class_name TestCase
extends Node
## Minimal zero-dependency test base. Cases live in res://tests/*_test.gd,
## discovered and driven by tests/run_tests.gd (see tests/run_tests.tscn).

var _case_failures: PackedStringArray = []
var _case_passed: int = 0


func setup() -> void:
	pass


func teardown() -> void:
	pass


func ok(cond: bool, msg: String = "") -> void:
	if cond:
		_case_passed += 1
	else:
		_case_failures.append(msg if msg != "" else "(unnamed assertion)")


func eq(got, expected, msg: String = "") -> void:
	var label := msg if msg != "" else "expected <%s> got <%s>" % [str(expected), str(got)]
	ok(got == expected, label)


func almost(got: float, expected: float, eps: float = 0.001, msg: String = "") -> void:
	var label := msg if msg != "" else "expected ~%f got %f (eps %f)" % [expected, got, eps]
	ok(absf(got - expected) <= eps, label)


func failure_count() -> int:
	return _case_failures.size()


func failures() -> PackedStringArray:
	return _case_failures


## Await N physics frames (lets Areas/Bodies sync).
func flush(frames: int) -> void:
	for i in frames:
		await get_tree().physics_frame


## Await until predicate() is true, guarding against infinite hangs.
func wait_until(predicate: Callable, max_frames: int = 180) -> bool:
	for i in max_frames:
		if predicate.call():
			return true
		await get_tree().physics_frame
	return predicate.call()


## Grounded-rig fixture: infinite-thickness floor whose top surface is y == 0.
func build_floor(parent: Node, x_center: float = 320.0) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = "Floor"
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector2(x_center, 30)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(4000, 60)
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)
	return body


## Spawn the real Player scene over the floor and settle it onto the ground.
func spawn_player(parent: Node2D, pos: Vector2 = Vector2(320, -24)) -> Player:
	const PLAYER := preload("res://scenes/player/Player.tscn")
	var player: Player = PLAYER.instantiate()
	player.position = pos
	parent.add_child(player)
	player.velocity.y = 10.0
	await flush(24)
	return player
