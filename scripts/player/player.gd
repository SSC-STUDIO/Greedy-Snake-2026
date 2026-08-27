class_name Player
extends CharacterBody2D
## Ember-Knight root. Movement, combat, toxin, and cores live on child nodes.

@onready var controller: PlayerController = $PlayerController
@onready var health: Health = $Health
@onready var toxin: ToxinMeter = $ToxinMeter
@onready var inventory: RustCoreInventory = $RustCoreInventory
@onready var melee: MeleeCombat = $MeleeCombat
@onready var sensor: InteractionSensor = $InteractionSensor
@onready var visual: Node2D = $Visual


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	health.changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	toxin.overflow_tick.connect(_on_toxin_overflow)
	GameEvents.player_health_changed.emit(health.current, health.max_hp)
	GameEvents.toxin_changed.emit(toxin.toxin, toxin.max_toxin)


func _physics_process(delta: float) -> void:
	if health.is_invincible() and health.current <= 0:
		return
	health.invincible = controller.is_invincible()
	var move_scale := 0.42 if melee.is_busy() else 1.0
	controller.physics_tick(self, delta, move_scale)
	move_and_slide()
	var face := float(controller.facing)
	visual.scale.x = face
	melee.scale.x = face
	_poll_interact()
	_poll_sockets()
	_poll_hookshot()


func is_invincible() -> bool:
	return controller.is_invincible() or health.is_invincible()


func collect_core(core: RustCore) -> void:
	inventory.add_to_pouch(core)


func _poll_interact() -> void:
	var focus := sensor.get_focus()
	if focus:
		GameEvents.interact_prompt.emit(focus.get_prompt(self))
	else:
		GameEvents.interact_prompt.emit("")
	if focus and Input.is_action_just_pressed("interact"):
		focus.interact(self)


func _poll_sockets() -> void:
	if Input.is_action_just_pressed("socket_1"):
		inventory.insert_into_socket(0)
	elif Input.is_action_just_pressed("socket_2"):
		inventory.insert_into_socket(1)


func _poll_hookshot() -> void:
	if not Input.is_action_just_pressed("hookshot"):
		return
	if inventory.has_ability(AbilityIds.HOOKSHOT_TETHER):
		GameEvents.announcement.emit("钩锁尚未锻成 — Hookshot Tether is still cooling.")
	else:
		GameEvents.announcement.emit("需要钩锁核（Hookshot Tether）")


func _on_health_changed(current: int, maximum: int) -> void:
	GameEvents.player_health_changed.emit(current, maximum)


func _on_toxin_overflow() -> void:
	health.take_damage(1, self)


func _on_died() -> void:
	set_physics_process(false)
	GameEvents.player_died.emit()
	GameEvents.announcement.emit("余烬熄灭…")
	await get_tree().create_timer(1.15).timeout
	get_tree().reload_current_scene()
