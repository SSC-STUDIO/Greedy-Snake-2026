class_name ScrapperEnemy
extends CharacterBody2D
## Rust plate-brute: patrols its beat, then charges. Slamming into a wall
## leaves it stunned — the punish window that teaches spacing.

enum State { PATROL, WINDUP, CHARGE, STUN }

const GRAVITY := 980.0

## Overbright modulate clamps to a white silhouette in the LDR framebuffer —
## reads as a hit flash across every ColorRect under $Visual at once, and the
## eye tint keeps following the state machine untouched.
const FLASH_MODULATE := Color(6.0, 6.0, 6.0)

@export var patrol_range: float = 64.0
@export var patrol_speed: float = 40.0
@export var charge_speed: float = 235.0
@export var aggro_range: float = 215.0
@export var windup_time: float = 0.45
@export var charge_max_time: float = 0.95
@export var stun_time: float = 0.95
@export var re_aggro_cooldown: float = 1.15
@export var contact_damage: int = 1

var _state: State = State.PATROL
var _dir: float = -1.0
var _timer: float = 0.0
var _cooldown: float = 0.0
var _anchor_x: float = 0.0
var _flash_tween: Tween

@onready var health: Health = $Health
@onready var charge_box: Hitbox = $ChargeBox
@onready var visual: Node2D = $Visual
@onready var eye: ColorRect = $Visual/Eye

## AI 生成的碎甲者（56px 高，面朝左，紧裁切）。
const AI_TEX_PATH := "res://assets/kenney_clean/enemies_ai/scrapper.png"


func _ready() -> void:
	add_to_group("enemies")
	_anchor_x = global_position.x
	health.max_hp = 3
	health.heal_full()
	health.died.connect(_on_died)
	charge_box.team = &"enemy"
	charge_box.damage = contact_damage
	charge_box.monitoring = false
	GameEvents.hit.connect(_on_hit)
	_build_visual()


func _build_visual() -> void:
	if not ResourceLoader.exists(AI_TEX_PATH):
		return
	var spr := Sprite2D.new()
	spr.name = "BodySprite"
	spr.texture = load(AI_TEX_PATH) as Texture2D
	spr.centered = true
	# 紧裁切：底边是脚，56 高 → 中心在 -28。
	spr.position = Vector2(0, -28)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.add_child(spr)
	# AI 贴图自带造型与橙色独眼：隐藏占位色块（含 Eye，状态由行为/冲锋预告表达）。
	for c in visual.get_children():
		if c is ColorRect:
			c.visible = false


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)

	match _state:
		State.PATROL:
			_tick_patrol(delta)
		State.WINDUP:
			_tick_windup(delta)
		State.CHARGE:
			_tick_charge(delta)
		State.STUN:
			_tick_stun(delta)

	move_and_slide()
	_update_facing()
	# The charge box leads where we are driving toward.
	charge_box.position.x = absf(charge_box.position.x) * signf(_dir)


func _tick_patrol(delta: float) -> void:
	charge_box.monitoring = false
	velocity.x = _dir * patrol_speed
	# Bounce between the anchor posts; walls count too.
	if is_on_wall() or global_position.x < _anchor_x - patrol_range \
			or global_position.x > _anchor_x + patrol_range:
		_dir = -_dir
	var player := get_tree().get_first_node_in_group("player") as Player
	if _cooldown <= 0.0 and player != null:
		var to_player := player.global_position - global_position
		if absf(to_player.x) < aggro_range and absf(to_player.y) < 70.0:
			_dir = signf(to_player.x) if absf(to_player.x) > 4.0 else _dir
			_state = State.WINDUP
			_timer = windup_time
			eye.color = Palette.EMBER


func _tick_windup(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	_timer -= delta
	if _timer <= 0.0:
		_state = State.CHARGE
		_timer = charge_max_time
		charge_box.monitoring = true


func _tick_charge(delta: float) -> void:
	velocity.x = _dir * charge_speed
	_timer -= delta
	if is_on_wall():
		_state = State.STUN
		_timer = stun_time
		charge_box.monitoring = false
		GameEvents.hit.emit(self, self, 0)  # Camera/hear feedback via bus.
	elif _timer <= 0.0:
		_cooldown = re_aggro_cooldown
		_state = State.PATROL
		charge_box.monitoring = false
		eye.color = Palette.TOXIC


func _tick_stun(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	_timer -= delta
	if _timer <= 0.0:
		_cooldown = re_aggro_cooldown
		_state = State.PATROL
		eye.color = Palette.TOXIC


func _update_facing() -> void:
	# Sprite faces travel; positive scale flips to the right.
	visual.scale.x = -_dir if _dir > 0.0 else 1.0


func _on_hit(_attacker: Node, target: Node, _amount: int) -> void:
	if target != self:
		return
	_flash_white()


func _flash_white() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(visual, "modulate", FLASH_MODULATE, 0.03)
	_flash_tween.tween_interval(0.05)
	_flash_tween.tween_property(visual, "modulate", Color.WHITE, 0.12)


func _on_died() -> void:
	Fx.rust_debris(global_position)
	Fx.hit_sparks(global_position)
	GameEvents.announcement.emit("碎甲者崩塌成一堆废铁")
	queue_free()
