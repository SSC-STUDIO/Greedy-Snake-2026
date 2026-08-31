class_name GameCamera
extends Camera2D
## Smooth follow with a small horizontal look-ahead based on facing / velocity,
## plus a decaying trauma shake that nudges `offset` (never the limits), and an
## external decaying jolt written by the Juice autoload via `shake_offset`.

## 视口已是 1280x720；zoom=2.0 让可视范围回到 640x360 世界单位，
## 因此速度/碰撞盒/关卡坐标无需改动，只是每个世界单位渲染成 2x2 像素。
## 改这个值等于改画面取景（WorldScale 不变，看得更多或更少）。
const ZOOM := 2.0

@export var follow_speed: float = 6.5
@export var look_ahead: float = 48.0
@export var look_ahead_speed: float = 3.2
@export var vertical_offset: float = -18.0

@export var max_shake_offset := Vector2(7.0, 5.0)
@export var max_shake_roll: float = 0.035
@export var trauma_decay: float = 1.7

var _look: float = 0.0
var _trauma: float = 0.0
var _noise := FastNoiseLite.new()
var _noise_t := 0.0

## External decaying shake, written by Juice every frame while a jolt is
## active (Vector2.ZERO otherwise). Folded into `offset` in _apply_shake so
## it stacks with the trauma shake instead of stomping it.
var shake_offset := Vector2.ZERO

var _focused: bool = false
var _focus_node: Node2D
var _focus_pos: Vector2 = Vector2.ZERO
var _focus_zoom: float = ZOOM
var _focus_speed: float = 4.0


func _ready() -> void:
	make_current()
	# Camera2D.offset 与世界坐标同空间，会随 zoom 线性放大；但世界内容也同比例放大，
	# 震屏的“相对幅度”不变，所以 max_shake_offset 无需按 ZOOM 补偿。
	zoom = Vector2(ZOOM, ZOOM)
	position_smoothing_enabled = false
	limit_left = 0
	limit_top = 0
	limit_right = 1600
	limit_bottom = 400
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.9
	_noise.seed = randi()
	add_to_group("game_camera")
	GameEvents.hit.connect(_on_hit)
	GameEvents.parried.connect(_on_parried)
	# The chain finisher is a big committed swing — sell it with a shake.
	GameEvents.swing_started.connect(func(combo_index: int) -> void:
		if combo_index >= 2:
			add_trauma(0.30)
	)
	GameEvents.rusty_gate_melted.connect(func(): add_trauma(0.38))
	GameEvents.player_died.connect(func(): add_trauma(0.55))


## Public juice entry point. Strength is clamped to [0, 1].
func add_trauma(strength: float) -> void:
	_trauma = clampf(maxf(_trauma, strength), 0.0, 1.0)


func focus(target: Variant, zoom: float = ZOOM, duration: float = 0.55) -> void:
	_focused = true
	_focus_zoom = zoom
	_focus_speed = 1.0 / maxf(duration, 0.08)
	if target is Node2D:
		_focus_node = target
		_focus_pos = (target as Node2D).global_position
	elif target is Vector2:
		_focus_node = null
		_focus_pos = target


func release() -> void:
	_focused = false
	_focus_node = null
	zoom = Vector2(ZOOM, ZOOM)


func _physics_process(delta: float) -> void:
	if _focused:
		if _focus_node != null and is_instance_valid(_focus_node):
			_focus_pos = _focus_node.global_position
		global_position = global_position.lerp(_focus_pos + Vector2(0, vertical_offset),
				1.0 - exp(-_focus_speed * delta))
		var z := lerpf(zoom.x, _focus_zoom, 1.0 - exp(-_focus_speed * delta))
		zoom = Vector2(z, z)
		_apply_shake(delta)
		return
	var target := get_tree().get_first_node_in_group("player") as Player
	if target == null:
		return
	var desired := float(target.controller.facing) * look_ahead * 0.45
	if absf(target.velocity.x) > 18.0:
		desired = signf(target.velocity.x) * look_ahead
	_look = lerpf(_look, desired, 1.0 - exp(-look_ahead_speed * delta))
	var dest := target.global_position + Vector2(_look, vertical_offset)
	global_position = global_position.lerp(dest, 1.0 - exp(-follow_speed * delta))
	_apply_shake(delta)


func _apply_shake(delta: float) -> void:
	if _trauma <= 0.0:
		offset = shake_offset
		rotation = 0.0
		return
	_noise_t += delta * 24.0
	var power := _trauma * _trauma
	offset = shake_offset + Vector2(
		_noise.get_noise_2d(_noise_t, 0.0) * max_shake_offset.x * power,
		_noise.get_noise_2d(_noise_t, 100.0) * max_shake_offset.y * power
	)
	rotation = _noise.get_noise_2d(_noise_t, 200.0) * max_shake_roll * power
	_trauma = maxf(0.0, _trauma - trauma_decay * delta)


func _on_hit(attacker: Node, target: Node, _amount: int) -> void:
	if attacker == null or target == null:
		return
	add_trauma(0.34 if target.is_in_group("player") else 0.18)


func _on_parried(_projectile: Node, _by_actor: Node) -> void:
	add_trauma(0.45)
