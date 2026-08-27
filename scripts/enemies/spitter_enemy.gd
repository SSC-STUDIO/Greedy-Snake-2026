class_name SpitterEnemy
extends Node2D
## Stationary rust-spitter. Teaches parry: its slag bolts can be sent home.

const PROJECTILE_SCENE := preload("res://scenes/combat/Projectile.tscn")
const PICKUP_SCENE := preload("res://scenes/interactables/CorePickup.tscn")

@export var shoot_interval: float = 1.85
@export var projectile_speed: float = 150.0
@export var aggro_range: float = 380.0

@onready var health: Health = $Health
@onready var muzzle: Marker2D = $Muzzle


func _ready() -> void:
	health.max_hp = 2
	health.heal_full()
	health.died.connect(_on_died)
	var timer := Timer.new()
	timer.wait_time = shoot_interval
	timer.autostart = true
	timer.timeout.connect(_shoot)
	add_child(timer)
	_build_visual()


const FLY_TEX_PATH := "res://assets/kenney_clean/enemies/flyFly1.png"
const SLIME_TEX_PATH := "res://assets/kenney_clean/enemies/slimeWalk1.png"

func _build_visual() -> void:
	if get_node_or_null("Body") != null:
		return
	var tex: Texture2D = null
	if ResourceLoader.exists(FLY_TEX_PATH):
		tex = load(FLY_TEX_PATH) as Texture2D
	if tex != null:
		var spr := Sprite2D.new()
		spr.name = "Body"
		spr.texture = tex
		spr.position = Vector2(0, -10)
		spr.modulate = Palette.RUST_MID.lerp(Color.WHITE, 0.25)
		add_child(spr)
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
	var nozzle2 := ColorRect.new()
	nozzle2.size = Vector2(10, 4)
	nozzle2.position = Vector2(-14, -14)
	nozzle2.color = Palette.TOXIC
	nozzle2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(nozzle2)


func _shoot() -> void:
	if health.current <= 0:
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	if global_position.distance_to(player.global_position) > aggro_range:
		return
	var proj := PROJECTILE_SCENE.instantiate() as Projectile
	get_tree().current_scene.add_child(proj)
	var origin := muzzle.global_position
	var dir := player.global_position + Vector2(0, -12) - origin
	proj.setup(origin, dir, projectile_speed, &"enemy", self)


func _on_died() -> void:
	var pickup := PICKUP_SCENE.instantiate() as CorePickup
	pickup.core = AbilityCatalog.tether_core()
	get_parent().add_child(pickup)
	pickup.global_position = global_position + Vector2(0, -8)
	GameEvents.announcement.emit("喷吐者崩解，掉落钩锁核")
	queue_free()
