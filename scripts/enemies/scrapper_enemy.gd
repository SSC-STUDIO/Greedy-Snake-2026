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

## Hell Hound 像素帧动画（ansimuz，原图面朝左）：idle 6 / walk 12 / run 5 / jump 5。
## 画布 64x32（run 67x32、jump 78x48），脚底均贴画布底边。
const HOUND_CHAR := "scrapper_hell_hound"
const HOUND_POS := Vector2(0.0, -16.0)        # 32 高画布 → 中心 -16
const HOUND_JUMP_POS := Vector2(0.0, -24.0)   # jump 画布 48 高

var _anim: FrameAnimSprite  # 有帧素材时非 null


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


## 两级回退：Hell Hound 帧动画 → 场景内 ColorRect 占位（headless/缺素材）。
func _build_visual() -> void:
	if not CharFrames.available(HOUND_CHAR):
		return
	_anim = FrameAnimSprite.new()
	_anim.name = "BodySprite"
	_anim.register("idle", CharFrames.anim(HOUND_CHAR, "idle"), 8.0, true, HOUND_POS)
	_anim.register("walk", CharFrames.anim(HOUND_CHAR, "walk"), 10.0, true, HOUND_POS)
	_anim.register("run", CharFrames.anim(HOUND_CHAR, "run"), 14.0, true, HOUND_POS)
	_anim.register("jump", CharFrames.anim(HOUND_CHAR, "jump"), 12.0, true, HOUND_JUMP_POS)
	_anim.play("walk")
	visual.add_child(_anim)
	# 帧动画自带地狱犬造型：隐藏占位色块（含 Eye，状态改由动画/冲锋预告表达）。
	for c in visual.get_children():
		if c is ColorRect:
			c.visible = false


## 状态 → 动画：巡逻小跑 / 预备低吼(慢速待机) / 冲刺疾跑 / 硬直(定格待机)。
func _update_anim() -> void:
	if _anim == null:
		return
	match _state:
		State.PATROL:
			_anim.play("walk")
		State.WINDUP:
			_anim.set_fps("idle", 14.0)  # 蓄势：急促喘息
			_anim.play("idle")
		State.CHARGE:
			_anim.play("run")
		State.STUN:
			_anim.set_fps("idle", 4.0)   # 撞墙眩晕：拖慢到近乎定格
			_anim.play("idle")


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
	_update_anim()
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
	Fx.enemy_death_smoke(global_position)  # 地狱犬无专用死亡帧 → 通用烟雾
	Fx.rust_debris(global_position)
	Fx.hit_sparks(global_position)
	GameEvents.announcement.emit("碎甲者崩塌成一堆废铁")
	queue_free()
