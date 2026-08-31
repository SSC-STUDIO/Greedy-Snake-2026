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

@export var patrol_range: float = 64.0
@export var patrol_speed: float = 40.0

var health: Health
var _dir: float = -1.0
var _anchor_x: float = 0.0
var _anim: FrameAnimSprite     # 有帧素材时非 null
var _flash_target: CanvasItem  # 受击白闪作用的节点（默认 $Visual）
var _flash_tween: Tween
## 静止敌人置 false：跳过重力与 move_and_slide。
var _mobile := true


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


func _physics_process(delta: float) -> void:
	# 过场锁玩家时敌人也停手，否则 Boss 介绍里仍会被砍/被射。
	if Director.is_input_locked():
		if _mobile:
			if not is_on_floor():
				velocity.y += GRAVITY * delta
			velocity.x = 0.0
			move_and_slide()
		return
	if not _mobile:
		_tick_state(delta)
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	_tick_state(delta)
	move_and_slide()
	_after_move()


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
	_flash_tween.tween_interval(0.05)
	_flash_tween.tween_property(_flash_target, "modulate", _flash_restore_color(), 0.12)


func _flash_restore_color() -> Color:
	return Color.WHITE


func _on_hit(_attacker: Node, target: Node, _amount: int) -> void:
	if target != self:
		return
	_flash_white()


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


## 子类死亡回调（health.died）。
func _on_died() -> void:
	_death_burst([] as Array[Texture2D], 12.0, false, 0.0, "")
