class_name Hurtbox
extends Area2D
## Receives melee and projectile hits. Team string prevents friendly fire.

signal hurt(amount: int, attacker: Node)

@export var team: StringName = &"player"
@export var damage_owner_path: NodePath = NodePath("..")

var _health: Health


func _ready() -> void:
	monitorable = true
	monitoring = true
	collision_layer = 32 # hurtbox
	collision_mask = 8 | 16 # player_hitbox + projectile
	area_entered.connect(_on_area_entered)
	var owner_node := get_node_or_null(damage_owner_path)
	if owner_node:
		_health = owner_node.get_node_or_null("Health") as Health


func receive_hit(amount: int, attacker: Node) -> void:
	hurt.emit(amount, attacker)
	if _health:
		_health.take_damage(amount, attacker)


func _on_area_entered(area: Area2D) -> void:
	if area is Projectile:
		var projectile := area as Projectile
		if projectile.team == team:
			return
		if _is_owner_invincible():
			return
		receive_hit(projectile.damage, projectile)
		projectile.queue_free()
		return
	if area is Hitbox:
		var box := area as Hitbox
		if box.team == team:
			return
		if not box.monitoring:
			return
		if box.already_hit.has(self):
			return
		if _is_owner_invincible():
			return
		box.already_hit.append(self)
		receive_hit(box.damage, box)


func _is_owner_invincible() -> bool:
	if _health and _health.is_invincible():
		return true
	var body := get_parent()
	if body is Player:
		return (body as Player).is_invincible()
	return false
