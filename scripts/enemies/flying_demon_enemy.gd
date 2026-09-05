class_name FlyingDemonEnemy
extends EnemyBase
## Airborne gargoyle-demon that patrols the skies and perches above hazards.
## Keeps flapping while it winds up, swoops, then returns to its patrol height.

const DEMON_CHAR := "flying_demon_px"
const DEMON_POS := Vector2(0.0, 0.0)

enum State { PATROL, AGGRO, ATTACK, SWOOP, RECOVERY }

@export var fly_speed: float = 48.0
@export var aggro_range: float = 240.0
@export var attack_interval: float = 2.4
@export var swoop_speed: float = 120.0

var _state: State = State.PATROL
var _state_timer: float = 0.0
var _shoot_timer: float = 0.0
var _origin_y: float = 0.0
var _hover_t: float = 0.0
var _target_player: Player = null
var _swoop_direction := Vector2.DOWN

@onready var visual: Node2D = $Visual
@onready var hitbox: Hitbox = $Hitbox


func _enemy_ready() -> void:
	health.max_hp = 3
	health.heal_full()
	_origin_y = global_position.y
	_shoot_timer = randf_range(1.0, attack_interval)
	if hitbox != null:
		hitbox.team = &"enemy"
		hitbox.damage = 1
		hitbox.monitoring = false
	_build_visual()


func _build_visual() -> void:
	_anim = _build_frame_anim(DEMON_CHAR, [
		["idle", "idle", 10.0, true, DEMON_POS],
	])
	if _anim != null:
		_anim.scale = Vector2.ONE
		visual.add_child(_anim)
		_flash_target = _anim
		_hide_placeholder_rects(visual)
		_anim.play("idle")
	elif visual.has_node("Placeholder"):
		_flash_target = visual.get_node("Placeholder") as CanvasItem


func _physics_process(delta: float) -> void:
	if _dead:
		return
	if Director.is_input_locked():
		return
	if _hurt_lock > 0.0:
		_hurt_lock = maxf(0.0, _hurt_lock - delta)
		move_and_slide()
		_after_move()
		return
	_tick_state(delta)
	move_and_slide()
	_after_move()


func _tick_state(delta: float) -> void:
	_hover_t += delta * 2.5
	var hover_offset := sin(_hover_t) * 14.0
	_poll_player()

	match _state:
		State.PATROL:
			_patrol_step()
			velocity.y = ((_origin_y + hover_offset) - global_position.y) * 4.0
			if _target_player != null:
				_state = State.AGGRO
				_state_timer = 0.5
		State.AGGRO:
			if _target_player == null or not is_instance_valid(_target_player):
				_state = State.PATROL
				velocity = Vector2.ZERO
				return
			_dir = signf(_target_player.global_position.x - global_position.x)
			if _dir == 0.0:
				_dir = 1.0
			velocity.x = move_toward(velocity.x, _dir * fly_speed * 0.8, 160.0 * delta)
			velocity.y = ((_origin_y + hover_offset - 20.0) - global_position.y) * 4.0
			_shoot_timer -= delta
			if _shoot_timer <= 0.0:
				_start_attack()
		State.ATTACK:
			if _target_player == null or not is_instance_valid(_target_player):
				_state = State.RECOVERY
				_state_timer = 0.2
				return
			_state_timer -= delta
			velocity = velocity.move_toward(Vector2.ZERO, 200.0 * delta)
			if _state_timer <= 0.0:
				_state = State.SWOOP
				_state_timer = 0.85
				_swoop_direction = (_target_player.global_position + Vector2(0, -14) - global_position).normalized()
				hitbox.arm(_swoop_direction * 75.0)
		State.SWOOP:
			velocity = _swoop_direction * swoop_speed
			_state_timer -= delta
			if _state_timer <= 0.0 or is_on_wall() or is_on_floor():
				hitbox.disarm()
				_state = State.RECOVERY
				_state_timer = 1.0
				if _anim != null:
					_anim.modulate = Color.WHITE
					_anim.set_fps("idle", 10.0)
		State.RECOVERY:
			_state_timer -= delta
			velocity.y = ((_origin_y + hover_offset) - global_position.y) * 3.0
			if _state_timer <= 0.0:
				_state = State.AGGRO if _target_player != null else State.PATROL
				_shoot_timer = attack_interval


func _after_move() -> void:
	if visual != null:
		visual.scale.x = -_dir if _dir != 0.0 else 1.0


func _poll_player() -> void:
	var p := get_tree().get_first_node_in_group("player") as Player
	if p != null and not p.is_invincible() and p.health.current > 0:
		if global_position.distance_to(p.global_position) <= aggro_range:
			_target_player = p
			return
	_target_player = null


func _start_attack() -> void:
	_state = State.ATTACK
	_state_timer = 0.55
	if _anim != null:
		_anim.play("idle")
		_anim.set_fps("idle", 15.0)
		_anim.modulate = Color(1.25, 0.82, 0.66)
	Sfx.play(&"swing", 0.12, -4.0)


func _on_died() -> void:
	GameEvents.announcement.emit("恶魔在锈风中坠解")
	_death_burst([] as Array[Texture2D], 12.0, false, 0.0, "")
