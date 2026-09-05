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


## 打开判定并清 already_hit。冲锋/挥砍每次出手都要调用，否则第一下命中后永远打不中。
func arm(p_knockback: Vector2 = Vector2.ZERO) -> void:
	already_hit.clear()
	knockback = p_knockback
	monitoring = true


func disarm() -> void:
	monitoring = false
	already_hit.clear()


func _physics_process(_delta: float) -> void:
	if not monitoring:
		return
	# A hurtbox can overlap the sword before the active window begins.
	# Toggling monitoring does not re-emit its area_entered signal. Sweep the
	# current pairs as well; already_hit still limits damage to once per swing.
	for area in get_overlapping_areas():
		if area is Hurtbox:
			area._on_area_entered(self)
