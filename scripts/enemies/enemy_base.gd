class_name EnemyBase
extends CharacterBody2D
## 敌人通用基类：编组/血量接线、受击白闪、CharFrames 帧动画装配、
## 死亡演出（尸体帧或通用烟雾 + 锈屑/火花 + 播报）、巡逻折返移动。
## 子类只保留各自的状态机与特殊攻击；静止敌人（喷吐者）把 _mobile
## 置 false，基类不施重力、不 move_and_slide。

const GRAVITY := 980.0
## Overbright modulate clamps to a white silhouette in the LDR framebuffer,
## which reads as a hit flash for sprites and ColorRect bodies alike.
const FLASH_MODULATE := Color(6.0, 6.0, 6.0)
## 受击硬直：挡住状态机改 velocity，否则巡逻/冲锋下一帧就把击退盖掉。
const HURT_LOCK := 0.12
## 与玩家身体重叠时的挤开半径（像素）；不改玩家碰撞层，只推开重叠。
const BODY_SEPARATE_X := 16.0
const BODY_SEPARATE_Y := 26.0

@export var patrol_range: float = 64.0
@export var patrol_speed: float = 40.0

var health: Health
var _dir: float = -1.0
var _anchor_x: float = 0.0
var _anim: FrameAnimSprite     # 有帧素材时非 null
var _flash_target: CanvasItem  # 受击白闪作用的节点（默认 $Visual）
var _flash_tween: Tween
var _recoil_tween: Tween
## 静止敌人置 false：跳过重力与 move_and_slide。
var _mobile := true
var _dead := false
var _hurt_lock: float = 0.0
var _recoil_home_x: float = 0.0
var _recoil_home_ready := false


func _ready() -> void:
	add_to_group("enemies")
	_anchor_x = global_position.x
	health = get_node_or_null("Health") as Health
	if health != null:
		health.died.connect(_on_died)
	GameEvents.hit.connect(_on_hit)
	_flash_target = get_node_or_null("Visual") as CanvasItem
	_enemy_ready()


## 子类初始化钩子：设 max_hp、装配视觉、接特有信号等。
func _enemy_ready() -> void:
	pass


func is_hurt_locked() -> bool:
	return _dead or _hurt_lock > 0.0


func _physics_process(delta: float) -> void:
	if _dead:
		return
	# 过场锁玩家时敌人也停手，否则 Boss 介绍里仍会被砍/被射。
	if Director.is_input_locked():
		if _mobile:
			if not is_on_floor():
				velocity.y += GRAVITY * delta
			velocity.x = 0.0
			move_and_slide()
		return
	if _hurt_lock > 0.0:
		_hurt_lock = maxf(0.0, _hurt_lock - delta)
		if _mobile:
			if not is_on_floor():
				velocity.y += GRAVITY * delta
			move_and_slide()
			_after_move()
			_separate_from_player()
		return
	if not _mobile:
		_tick_state(delta)
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	_tick_state(delta)
	move_and_slide()
	_after_move()
	_separate_from_player()


## 子类状态机步进（move_and_slide 之前）。
func _tick_state(_delta: float) -> void:
	pass


## move_and_slide 之后的收尾（更新朝向/动画等）。
func _after_move() -> void:
	pass


## 巡逻折返：先按边界/撞墙修正方向，再赋速度。
## （bug fix）旧实现先赋速再翻向，越界帧速度仍朝外、下一帧又满足越界条件
## 再翻一次，敌人会在巡逻边界原地两帧振荡；改为越界时直接把方向定为
## "朝锚点回走"，判定收敛、不再抖动。
func _patrol_step() -> void:
	if global_position.x < _anchor_x - patrol_range:
		_dir = 1.0
	elif global_position.x > _anchor_x + patrol_range:
		_dir = -1.0
	elif is_on_wall():
		_dir = -_dir
	velocity.x = _dir * patrol_speed


## 受击白闪：闪至过曝白再落回 _flash_restore_color()（喷吐者蓄力时覆写）。
func _flash_white() -> void:
	if _flash_target == null:
		return
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash_target, "modulate", FLASH_MODULATE, 0.03)
	_flash_tween.tween_interval(0.06)
	_flash_tween.tween_property(_flash_target, "modulate", _flash_restore_color(), 0.10)


func _flash_restore_color() -> Color:
	return Color.WHITE


func _on_hit(attacker: Node, target: Node, amount: int) -> void:
	if target != self or _dead:
		return
	_flash_white()
	if amount <= 0:
		return
	_hurt_lock = HURT_LOCK
	_pixel_recoil(attacker)


## 受击往攻击者反方向挪 2px，再弹回。只动视觉节点，不改碰撞原点。
func _pixel_recoil(attacker: Node) -> void:
	if _flash_target == null:
		return
	if not _recoil_home_ready:
		_recoil_home_x = _flash_target.position.x
		_recoil_home_ready = true
	var dir := -_dir
	if attacker is Node2D:
		var ax := (attacker as Node2D).global_position.x
		if absf(ax - global_position.x) > 0.5:
			dir = signf(global_position.x - ax)
	if dir == 0.0:
		dir = -1.0
	if _recoil_tween != null and _recoil_tween.is_valid():
		_recoil_tween.kill()
	_flash_target.position.x = _recoil_home_x + dir * 2.0
	_recoil_tween = create_tween()
	_recoil_tween.tween_property(_flash_target, "position:x", _recoil_home_x, 0.10)


## 玩家与敌人互相不在对方 collision_mask 里，会穿模。从敌人侧把重叠的玩家挤开，
## 不改玩家移动公式、也不让冲锋把玩家当成墙。
func _separate_from_player() -> void:
	if not _mobile:
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or player.is_invincible():
		return
	var to_p := player.global_position - global_position
	if absf(to_p.x) > BODY_SEPARATE_X or absf(to_p.y) > BODY_SEPARATE_Y:
		return
	var push := signf(to_p.x)
	if push == 0.0:
		push = -_dir if _dir != 0.0 else 1.0
	if absf(player.velocity.x) < 90.0 or signf(player.velocity.x) != push:
		player.velocity.x = push * 88.0


## 装配 CharFrames 帧动画。specs 每行 [动作名, 帧目录名("" = 同动作名),
## fps, 是否循环, 基线位置]。素材缺失返回 null，调用方自行回退占位视觉。
func _build_frame_anim(char_name: String, specs: Array) -> FrameAnimSprite:
	if not CharFrames.available(char_name):
		return null
	var anim := FrameAnimSprite.new()
	anim.name = "BodySprite"
	for spec in specs:
		var action := String(spec[1])
		if action == "":
			action = String(spec[0])
		anim.register(String(spec[0]), CharFrames.anim(char_name, action),
				float(spec[2]), bool(spec[3]), spec[4])
	return anim


## 帧动画自带造型：隐藏容器下的占位色块。
static func _hide_placeholder_rects(container: Node) -> void:
	for c in container.get_children():
		if c is ColorRect:
			c.visible = false


## 死亡通用演出：尸体帧动画（空帧列表退化为通用烟雾）+ 锈屑 + 火花 +
## 播报，最后 queue_free。掉落物等差异由子类在调用前自行生成。
func _death_burst(frames: Array[Texture2D], fps: float, flip: bool,
		baseline: float, message: String) -> void:
	_disable_combat()
	if frames.is_empty():
		Fx.enemy_death_smoke(global_position)
	else:
		Fx.play_frames_once(frames, global_position, fps, flip, baseline)
	Fx.rust_debris(global_position)
	Fx.hit_sparks(global_position)
	if message != "":
		GameEvents.announcement.emit(message)
	Sfx.play(&"hit_flesh")
	queue_free()


## 死亡当帧立刻收刀：关掉 hit/hurt、去掉身体碰撞，并挡住本帧剩余 AI。
func _disable_combat() -> void:
	_dead = true
	_hurt_lock = 0.0
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	for node in get_children():
		if node is Hitbox or node is Hurtbox:
			var area := node as Area2D
			area.monitoring = false
			area.monitorable = false
			area.collision_layer = 0
			area.collision_mask = 0


## 子类死亡回调（health.died）。
func _on_died() -> void:
	_death_burst([] as Array[Texture2D], 12.0, false, 0.0, "")
