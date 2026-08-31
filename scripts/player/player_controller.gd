class_name PlayerController
extends Node
## Heavy-momentum locomotion for the Ember-Knight.
## Variable acceleration (not snappy), gravity-scaled fall, gated extra jump, dash i-frames.

signal dashed
signal jumped(is_extra: bool)

@export_group("Move")
@export var max_speed: float = 108.0
@export var acceleration: float = 360.0
@export var deceleration: float = 420.0
@export var air_acceleration: float = 220.0
@export var air_deceleration: float = 130.0

@export_group("Jump")
@export var jump_velocity: float = -268.0
@export var extra_jumps: int = 1
@export var extra_jumps_unlocked: bool = false
@export var extra_jump_scale: float = 0.92
@export var fall_gravity_scale: float = 1.85
@export var jump_cut_gravity_scale: float = 2.15
@export var coyote_time: float = 0.08
@export var jump_buffer_time: float = 0.12

@export_group("Dash")
@export var dash_speed: float = 236.0
@export var dash_duration: float = 0.13
@export var dash_cooldown: float = 0.42
@export var iframe_duration: float = 0.13
@export var air_dashes: int = 1

var facing: int = 1
var _coyote: float = 0.0
var _buffer: float = 0.0
var _jumps_left: int = 0
var _dash_timer: float = 0.0
var _dash_cd: float = 0.0
var _iframe: float = 0.0
var _air_dashes_left: int = 0
var _dash_dir: float = 1.0
var _commit_lock: bool = false


func is_dashing() -> bool:
	return _dash_timer > 0.0


func is_invincible() -> bool:
	return _iframe > 0.0


func set_commit_lock(locked: bool) -> void:
	_commit_lock = locked


func grant_air_jump() -> void:
	_jumps_left = maxi(_jumps_left, 1)


func physics_tick(body: CharacterBody2D, delta: float, move_scale: float) -> void:
	if _dash_cd > 0.0:
		_dash_cd = maxf(0.0, _dash_cd - delta)
	if _iframe > 0.0:
		_iframe = maxf(0.0, _iframe - delta)

	var on_floor := body.is_on_floor()
	if on_floor:
		_coyote = coyote_time
		_jumps_left = extra_jumps if extra_jumps_unlocked else 0
		_air_dashes_left = air_dashes
	else:
		_coyote = maxf(0.0, _coyote - delta)

	if Input.is_action_just_pressed("jump"):
		_buffer = jump_buffer_time
	else:
		_buffer = maxf(0.0, _buffer - delta)

	if is_dashing():
		_dash_timer = maxf(0.0, _dash_timer - delta)
		var speed := dash_speed
		if body is Player and (body as Player).toxin.potency() >= 0.5:
			speed *= 1.12
		body.velocity.x = _dash_dir * speed
		body.velocity.y = 0.0
		return

	_apply_gravity(body, delta)

	if not _commit_lock and Input.is_action_just_pressed("dash"):
		_try_dash(body)

	if _buffer > 0.0:
		_try_jump(body)

	var axis := Input.get_axis("move_left", "move_right")
	_apply_move(body, axis, delta, move_scale)

	if absf(axis) > 0.2:
		facing = 1 if axis > 0.0 else -1


func _apply_gravity(body: CharacterBody2D, delta: float) -> void:
	var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	var scale := 1.0
	if body.velocity.y > 0.0:
		scale = fall_gravity_scale
	elif not Input.is_action_pressed("jump") and body.velocity.y < 0.0:
		scale = jump_cut_gravity_scale
	body.velocity.y += gravity * scale * delta


func _apply_move(body: CharacterBody2D, axis: float, delta: float, move_scale: float) -> void:
	var on_floor := body.is_on_floor()
	var target := axis * max_speed * move_scale
	var accel := acceleration if on_floor else air_acceleration
	var decel := deceleration if on_floor else air_deceleration
	if _commit_lock:
		accel *= 0.35
		decel *= 0.8
		target *= 0.45

	if absf(axis) > 0.05:
		var turning := signf(axis) != signf(body.velocity.x) and absf(body.velocity.x) > 8.0
		var rate := accel * (1.55 if turning else 1.0)
		body.velocity.x = move_toward(body.velocity.x, target, rate * delta)
	else:
		body.velocity.x = move_toward(body.velocity.x, 0.0, decel * delta)


func _try_jump(body: CharacterBody2D) -> void:
	if _coyote > 0.0:
		_do_jump(body, false)
		return
	if extra_jumps_unlocked and _jumps_left > 0 and not body.is_on_floor():
		_jumps_left -= 1
		_do_jump(body, true)


func _do_jump(body: CharacterBody2D, is_extra: bool) -> void:
	_buffer = 0.0
	_coyote = 0.0
	var power := jump_velocity
	if is_extra:
		power *= extra_jump_scale
	body.velocity.y = power
	jumped.emit(is_extra)
	GameEvents.jumped.emit(is_extra)
	Sfx.play(&"jump")


func _try_dash(body: CharacterBody2D) -> void:
	if _dash_cd > 0.0:
		return
	if not body.is_on_floor() and _air_dashes_left <= 0:
		return
	if not body.is_on_floor():
		_air_dashes_left -= 1

	var axis := Input.get_axis("move_left", "move_right")
	if absf(axis) > 0.2:
		_dash_dir = signf(axis)
		facing = int(_dash_dir)
	else:
		_dash_dir = float(facing)

	var speed := dash_speed
	if body is Player and (body as Player).toxin.potency() >= 0.5:
		speed *= 1.12
	_dash_timer = dash_duration
	_dash_cd = dash_cooldown
	_iframe = iframe_duration
	body.velocity.x = _dash_dir * speed
	body.velocity.y = 0.0
	dashed.emit()
	GameEvents.dash_performed.emit()
	Sfx.play(&"dash")
