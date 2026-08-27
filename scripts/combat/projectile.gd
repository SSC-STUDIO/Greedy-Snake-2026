class_name Projectile
extends Area2D
## Hostile slag bolt. During a slash active-frame overlap it is deflected home.

var velocity: Vector2 = Vector2.ZERO
var team: StringName = &"enemy"
var source: Node2D
var damage: int = 1
var deflected: bool = false
var lifetime: float = 4.5

@onready var _fill: ColorRect = $Fill


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	collision_layer = 16
	collision_mask = 1 | 8 | 32 # world, player_hitbox, hurtbox
	_update_visual()


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
	if _fill == null:
		return
	_fill.color = Palette.TEAL if deflected else Palette.TOXIC
