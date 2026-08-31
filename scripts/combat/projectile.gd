class_name Projectile
extends Area2D
## Hostile slag bolt. During a slash active-frame overlap it is deflected home.

var velocity: Vector2 = Vector2.ZERO
var team: StringName = &"enemy"
var source: Node2D
var damage: int = 1
var deflected: bool = false
var lifetime: float = 4.5

const BOLT_PATH := "res://assets/env/fireball_1.png"
## Hell Beast 火球 3 帧（19x16，火头朝右 → rotation=velocity.angle() 直接可用）。
const BOLT_CHAR := "spitter_hell_beast"

@onready var _fill: ColorRect = $Fill
var _sprite: Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	collision_layer = 16
	collision_mask = 1 | 8 | 32
	_setup_sprite()
	_update_visual()


## 三级回退：帧动画火球 → 静态 fireball 贴图 → ColorRect 占位。
## 只换外观，弹反（deflect/parry）判定路径不碰。
func _setup_sprite() -> void:
	var frames := CharFrames.anim(BOLT_CHAR, "projectile")
	if not frames.is_empty():
		if _fill:
			_fill.visible = false
		var anim := FrameAnimSprite.new()
		anim.name = "BoltSprite"
		anim.register("fly", frames, 12.0, true)
		anim.play("fly")
		add_child(anim)
		_sprite = anim
		return
	if not ResourceLoader.exists(BOLT_PATH):
		return
	if _fill:
		_fill.visible = false
	_sprite = Sprite2D.new()
	_sprite.name = "BoltSprite"
	_sprite.texture = load(BOLT_PATH) as Texture2D
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.centered = true
	_sprite.scale = Vector2(0.28, 0.28)
	add_child(_sprite)


func setup(origin: Vector2, direction: Vector2, speed: float, p_team: StringName, p_source: Node2D) -> void:
	global_position = origin
	velocity = direction.normalized() * speed
	team = p_team
	source = p_source
	_update_visual()


func can_deflect() -> bool:
	return not deflected and team != &"player"


func deflect(by: Node2D) -> void:
	if not can_deflect():
		return
	deflected = true
	team = &"player"
	var aim := -velocity.normalized()
	if source != null and is_instance_valid(source):
		aim = (source.global_position - global_position).normalized()
	velocity = aim * maxf(velocity.length() * 1.45, 180.0)
	GameEvents.parried.emit(self, by)
	GameEvents.announcement.emit("弹反！")
	Sfx.play(&"parry")
	_update_visual()


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	if velocity.length_squared() > 4.0:
		rotation = velocity.angle()
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	_try_parry_overlap()


func _try_parry_overlap() -> void:
	if not can_deflect():
		return
	for area in get_overlapping_areas():
		if area is Hitbox:
			var box := area as Hitbox
			if box.monitoring and box.team == &"player":
				var melee := box.get_parent()
				if melee is MeleeCombat and (melee as MeleeCombat).is_parry_window():
					deflect(melee.get_parent())
					return


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		return
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		var box := area as Hitbox
		if can_deflect() and box.monitoring and box.team == &"player":
			var melee := box.get_parent()
			if melee is MeleeCombat and (melee as MeleeCombat).is_parry_window():
				deflect(melee.get_parent())


func _update_visual() -> void:
	if _sprite is FrameAnimSprite:
		# 帧火球本身就是橙红：敌方保持原色，弹反后压成冷青色标记归属反转。
		_sprite.modulate = Color(0.55, 1.35, 1.6) if deflected else Color.WHITE
	elif _sprite:
		_sprite.modulate = Color(0.72, 0.42, 0.28) if deflected else Color(0.78, 0.38, 0.22)
	elif _fill:
		_fill.color = Palette.TEAL if deflected else Palette.TOXIC
