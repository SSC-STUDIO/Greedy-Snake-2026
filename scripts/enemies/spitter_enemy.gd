class_name SpitterEnemy
extends Node2D
## Stationary rust-spitter. Teaches parry: its slag bolts can be sent home.

const PROJECTILE_SCENE := preload("res://scenes/combat/Projectile.tscn")
const PICKUP_SCENE := preload("res://scenes/interactables/CorePickup.tscn")

@export var shoot_interval: float = 1.85
@export var projectile_speed: float = 150.0
@export var aggro_range: float = 380.0

## Telegraph: the nozzle glows toxic-orange and the body puffs up before the
## bolt actually flies, then snaps back on release. Pure presentation — the
## firing cadence (shoot_interval) and hit logic are untouched.
const CHARGE_TIME := 0.45
const CHARGE_TINT_WEIGHT := 0.65
const CHARGE_SCALE := Vector2(1.1, 1.1)
## Overbright modulate clamps to a white silhouette in the LDR framebuffer,
## which reads as a hit flash for both the Sprite2D and ColorRect bodies.
const FLASH_MODULATE := Color(6.0, 6.0, 6.0)

@onready var health: Health = $Health
@onready var muzzle: Marker2D = $Muzzle

var _body: CanvasItem
var _base_modulate := Color.WHITE
var _charging := false
var _charge_timer: Timer
var _visual_tween: Tween


const FLY_TEX_PATH := "res://assets/kenney_clean/enemies/flyFly1.png"
const SLIME_TEX_PATH := "res://assets/kenney_clean/enemies/slimeWalk1.png"
## AI 生成的喷吐者（64px 高，面朝左，紧裁切）。
const AI_TEX_PATH := "res://assets/kenney_clean/enemies_ai/spitter.png"


func _ready() -> void:
	health.max_hp = 2
	health.heal_full()
	health.died.connect(_on_died)
	var timer := Timer.new()
	timer.wait_time = shoot_interval
	timer.autostart = true
	timer.timeout.connect(_on_shoot_tick)
	add_child(timer)
	_charge_timer = Timer.new()
	_charge_timer.wait_time = CHARGE_TIME
	_charge_timer.one_shot = true
	_charge_timer.timeout.connect(_on_charged)
	add_child(_charge_timer)
	_build_visual()
	GameEvents.hit.connect(_on_hit)


func _build_visual() -> void:
	var existing := get_node_or_null("Body") as CanvasItem
	if existing != null:
		_body = existing
		_base_modulate = existing.modulate
		return
	var tex: Texture2D = null
	if ResourceLoader.exists(AI_TEX_PATH):
		tex = load(AI_TEX_PATH) as Texture2D
	elif ResourceLoader.exists(FLY_TEX_PATH):
		tex = load(FLY_TEX_PATH) as Texture2D
	if tex != null:
		var spr := Sprite2D.new()
		spr.name = "Body"
		spr.texture = tex
		# AI 贴图紧裁切（底边是脚）：64 高 → 中心在 -32；Kenney 回退用旧偏移。
		spr.position = Vector2(0, -32) if tex.get_height() > 48 else Vector2(0, -10)
		if tex.get_height() > 48:
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		else:
			spr.modulate = Palette.RUST_MID.lerp(Color.WHITE, 0.25)
		add_child(spr)
		_body = spr
		_base_modulate = spr.modulate
		if tex.get_height() <= 48:
			var nozzle := ColorRect.new()
			nozzle.size = Vector2(10, 4)
			nozzle.position = Vector2(-14, -14)
			nozzle.color = Palette.TOXIC
			nozzle.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(nozzle)
		return
	var body := ColorRect.new()
	body.name = "Body"
	body.size = Vector2(16, 20)
	body.position = Vector2(-8, -20)
	body.color = Palette.RUST_MID
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)
	_body = body
	_base_modulate = Color.WHITE
	var nozzle2 := ColorRect.new()
	nozzle2.size = Vector2(10, 4)
	nozzle2.position = Vector2(-14, -14)
	nozzle2.color = Palette.TOXIC
	nozzle2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(nozzle2)


func _on_shoot_tick() -> void:
	if health.current <= 0 or _charging:
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	if global_position.distance_to(player.global_position) > aggro_range:
		return
	_begin_charge()


func _begin_charge() -> void:
	_charging = true
	_face_player()
	_kill_visual_tween()
	_visual_tween = create_tween()
	_visual_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_visual_tween.tween_property(_body, "modulate", _charge_modulate(), CHARGE_TIME)
	_visual_tween.parallel().tween_property(
		_body, "scale", Vector2(signf(_body.scale.x) * CHARGE_SCALE.x, CHARGE_SCALE.y), CHARGE_TIME
	)
	_charge_timer.start()


func _on_charged() -> void:
	_charging = false
	_kill_visual_tween()
	_visual_tween = create_tween()
	_visual_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_visual_tween.tween_property(_body, "modulate", _base_modulate, 0.08)
	_visual_tween.parallel().tween_property(
		_body, "scale", Vector2(signf(_body.scale.x), 1.0), 0.08
	)
	if health.current <= 0:
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	_fire(player)


func _fire(player: Player) -> void:
	var proj := PROJECTILE_SCENE.instantiate() as Projectile
	get_tree().current_scene.add_child(proj)
	var origin := muzzle.global_position
	var dir := player.global_position + Vector2(0, -12) - origin
	proj.setup(origin, dir, projectile_speed, &"enemy", self)


func _on_hit(_attacker: Node, target: Node, _amount: int) -> void:
	if target != self:
		return
	_flash_white()


func _flash_white() -> void:
	_kill_visual_tween()
	var restore_to := _charge_modulate() if _charging else _base_modulate
	_visual_tween = create_tween()
	_visual_tween.tween_property(_body, "modulate", FLASH_MODULATE, 0.03)
	_visual_tween.tween_interval(0.05)
	_visual_tween.tween_property(_body, "modulate", restore_to, 0.12)


func _charge_modulate() -> Color:
	return _base_modulate.lerp(Palette.TOXIC, CHARGE_TINT_WEIGHT)


## AI 贴图面朝左：玩家在右侧时水平翻转，蓄力朝向更可读。
func _face_player() -> void:
	if _body == null:
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	_body.scale.x = 1.0 if player.global_position.x < global_position.x else -1.0


func _kill_visual_tween() -> void:
	if _visual_tween != null and _visual_tween.is_valid():
		_visual_tween.kill()


func _on_died() -> void:
	Fx.rust_debris(global_position)
	Fx.hit_sparks(global_position)
	var pickup := PICKUP_SCENE.instantiate() as CorePickup
	pickup.core = AbilityCatalog.tether_core()
	get_parent().add_child(pickup)
	pickup.global_position = global_position + Vector2(0, -8)
	GameEvents.announcement.emit("喷吐者崩解，掉落钩锁核")
	queue_free()
