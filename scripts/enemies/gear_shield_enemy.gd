class_name GearShieldEnemy
extends CharacterBody2D
## Rust gear-shield guard. A slow, armored sentinel that guards one facing:
## frontal strikes and deflected bolts are absorbed by its shield, but dodge
## around back and it is plain flesh. Skilled players can reflect its own bolt
## back into the shield to stagger it open - the teachable punish window.
##
## Mirror of GDD "齿轮盾卫": don't trade blows head-on; either flank it or
## feed it its own shot.

enum State { PATROL, BLOCK, CHARGE, STAGGER }

const GRAVITY := 980.0
const PROJECTILE_SCENE := preload("res://scenes/combat/Projectile.tscn")
const FLASH_MODULATE := Color(6.0, 6.0, 6.0)

@export var patrol_range: float = 64.0
@export var patrol_speed: float = 26.0
@export var aggro_range: float = 300.0
@export var shoot_interval: float = 2.4
@export var charge_time: float = 0.5
@export var stagger_time: float = 1.5
@export var projectile_speed: float = 145.0

var _state: State = State.PATROL
var _dir: float = -1.0
var _timer: float = 0.0
var _shoot_timer: float = 0.0
var _anchor_x: float = 0.0
var _shield_facing: int = -1
var _blocking: bool = false
var _flicker_tween: Tween

@onready var health: Health = $Health
@onready var visual: Node2D = $Visual
@onready var shield: CanvasItem = $Visual/Shield
@onready var eye: ColorRect = $Visual/Eye
@onready var hurtbox: Hurtbox = $Hurtbox


func _ready() -> void:
	add_to_group("enemies")
	_anchor_x = global_position.x
	health.max_hp = 4
	health.heal_full()
	health.died.connect(_on_died)
	GameEvents.hit.connect(_on_hit)
	_shoot_timer = shoot_interval * 0.6
	hurtbox.block_check = _shield_block_check


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	match _state:
		State.PATROL:
			_tick_patrol(delta)
		State.BLOCK:
			_tick_block(delta)
		State.CHARGE:
			_tick_charge(delta)
		State.STAGGER:
			_tick_stagger(delta)
	move_and_slide()


func _tick_patrol(delta: float) -> void:
	_set_blocking(false)
	velocity.x = _dir * patrol_speed
	if is_on_wall() or global_position.x < _anchor_x - patrol_range \
			or global_position.x > _anchor_x + patrol_range:
		_dir = -_dir
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null and global_position.distance_to(player.global_position) < aggro_range:
		_enter_block(player)


func _enter_block(player: Player) -> void:
	_state = State.BLOCK
	_shield_facing = 1 if player.global_position.x >= global_position.x else -1
	_timer = 0.0
	_shoot_timer = shoot_interval * 0.5
	_update_visual()


func _tick_block(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		_state = State.CHARGE
		_timer = charge_time
		_flicker_charge()
		return
	_set_blocking(true)


func _tick_charge(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
	_set_blocking(true)
	_timer -= delta
	if _timer <= 0.0:
		_fire()
		_state = State.BLOCK
		_shoot_timer = shoot_interval


func _tick_stagger(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	_timer -= delta
	if _timer <= 0.0:
		_state = State.BLOCK
		_set_blocking(true)
		_update_visual()


func _fire() -> void:
	var proj := PROJECTILE_SCENE.instantiate() as Projectile
	get_tree().current_scene.add_child(proj)
	var player := get_tree().get_first_node_in_group("player") as Player
	var origin := global_position + Vector2(_shield_facing * 14.0, -14.0)
	var target := player.global_position + Vector2(0, -12) if player != null \
			else origin + Vector2(_shield_facing * 40.0, 0)
	proj.setup(origin, target - origin, projectile_speed, &"enemy", self)
	Sfx.play(&"spit")


func _shield_block_check(attacker: Node, _amount: int) -> bool:
	if not _blocking:
		return false
	if not _is_from_front(attacker):
		return false
	if attacker is Projectile and (attacker as Projectile).team == &"player":
		Sfx.play(&"parry")
		attacker.queue_free()
		_enter_stagger()
	else:
		Fx.hit_sparks(global_position + Vector2(_shield_facing * 9.0, -12.0))
		Sfx.play(&"parry")
	_flash_shield()
	return true


func _enter_stagger() -> void:
	_state = State.STAGGER
	_timer = stagger_time
	_set_blocking(false)
	GameEvents.announcement.emit("弹反击碎了齿轮盾！")
	GameEvents.hit.emit(self, self, 0)


func _is_from_front(attacker: Node) -> bool:
	var side: float
	if attacker is Projectile:
		side = (attacker as Projectile).velocity.x
	elif attacker is Node2D:
		side = (attacker as Node2D).global_position.x - global_position.x
	else:
		return false
	return signf(side) == float(_shield_facing)


func _set_blocking(b: bool) -> void:
	if _blocking == b:
		return
	_blocking = b
	shield.modulate.a = 1.0 if b else 0.35


func _update_visual() -> void:
	visual.scale.x = -1.0 if _shield_facing == -1 else 1.0
	eye.color = Palette.EMBER


func _flash_shield() -> void:
	if _flicker_tween != null and _flicker_tween.is_valid():
		_flicker_tween.kill()
	_flicker_tween = create_tween()
	_flicker_tween.tween_property(shield, "modulate", Color(0.9, 0.6, 0.3, 1.0), 0.04)
	_flicker_tween.tween_property(shield, "modulate", Color.WHITE, 0.1)


func _flicker_charge() -> void:
	if _flicker_tween != null and _flicker_tween.is_valid():
		_flicker_tween.kill()
	_flicker_tween = create_tween()
	_flicker_tween.tween_property(shield, "modulate", Palette.TOXIC, charge_time * 0.5)
	_flicker_tween.tween_property(shield, "modulate", Palette.EMBER, charge_time * 0.5)


func _on_hit(_attacker: Node, target: Node, _amount: int) -> void:
	if target != self:
		return
	if _flicker_tween != null and _flicker_tween.is_valid():
		_flicker_tween.kill()
	_flicker_tween = create_tween()
	_flicker_tween.tween_property(visual, "modulate", FLASH_MODULATE, 0.03)
	_flicker_tween.tween_interval(0.05)
	_flicker_tween.tween_property(visual, "modulate", Color.WHITE, 0.12)


func _on_died() -> void:
	Fx.rust_debris(global_position)
	Fx.hit_sparks(global_position)
	GameEvents.announcement.emit("齿轮盾卫崩塌成废铁")
	queue_free()
