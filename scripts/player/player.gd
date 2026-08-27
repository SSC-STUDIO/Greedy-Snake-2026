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


const P_STAND_PATH := "res://assets/kenney_clean/player/p1_stand.png"
const P_JUMP_PATH := "res://assets/kenney_clean/player/p1_jump.png"
const P_HURT_PATH := "res://assets/kenney_clean/player/p1_hurt.png"
var _sprites: Dictionary = {}
var _sprite_root: Sprite2D

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	health.changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	toxin.overflow_tick.connect(_on_toxin_overflow)
	GameEvents.player_health_changed.emit(health.current, health.max_hp)
	GameEvents.toxin_changed.emit(toxin.toxin, toxin.max_toxin)
	_setup_kenney_sprite()


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
	_update_kenney_sprite()
	_poll_interact()
	_poll_sockets()
	_poll_hookshot()


func _setup_kenney_sprite() -> void:
	if not ResourceLoader.exists(P_STAND_PATH):
		return
	# Hide placeholder ColorRects but keep them for headless fallback.
	for c in visual.get_children():
		if c is ColorRect or c is Polygon2D:
			c.visible = false
	_sprite_root = Sprite2D.new()
	_sprite_root.name = "KenneySprite"
	_sprite_root.centered = true
	_sprite_root.position = Vector2(0, -13)
	_sprite_root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.add_child(_sprite_root)
	_sprites["stand"] = load(P_STAND_PATH) as Texture2D
	if ResourceLoader.exists(P_JUMP_PATH):
		_sprites["jump"] = load(P_JUMP_PATH) as Texture2D
	if ResourceLoader.exists(P_HURT_PATH):
		_sprites["hurt"] = load(P_HURT_PATH) as Texture2D
	_sprite_root.texture = _sprites["stand"]
	_sprite_root.modulate = Color(1, 1, 1, 1)


func _update_kenney_sprite() -> void:
	if _sprite_root == null:
		return
	var tex: Texture2D = _sprites.get("stand") as Texture2D
	if health.current <= 0:
		tex = _sprites.get("hurt", tex) as Texture2D
	elif controller.is_dashing():
		tex = _sprites.get("jump", tex) as Texture2D
	elif not is_on_floor():
		tex = _sprites.get("jump", tex) as Texture2D
	elif absf(velocity.x) > 12.0:
		# No walk cycle in Kenney base stand only — tint to show motion.
		_sprite_root.modulate = Color(1.0, 0.95, 0.9, 1.0)
		tex = _sprites.get("stand") as Texture2D
	else:
		_sprite_root.modulate = Color.WHITE
	if tex != null and _sprite_root.texture != tex:
		_sprite_root.texture = tex


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
