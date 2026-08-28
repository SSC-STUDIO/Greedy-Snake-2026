class_name Hitbox
extends Area2D
## Player (or enemy) melee volume. Monitoring is toggled by MeleeCombat.

@export var damage: int = 1
@export var knockback: Vector2 = Vector2.ZERO
var team: StringName = &"player"
var already_hit: Array = []


func _ready() -> void:
	monitoring = false
	monitorable = true
	collision_layer = 8 # player_hitbox
	collision_mask = 16 | 32 # projectile + hurtbox
