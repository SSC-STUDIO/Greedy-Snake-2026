class_name TorchLight
extends Node2D
## Gothic wall torch with atmospheric flickering point light and embers.

const TORCH_TEX := "res://assets/env/bg_wall_torch.png"

@export var light_color: Color = Color(1.0, 0.65, 0.32, 1.0)
@export var base_energy: float = 0.60
@export var light_radius: float = 64.0

var _light: WorldLight
var _sprite: Sprite2D
var _time: float = 0.0
var _seed: float = 0.0


func _ready() -> void:
	z_index = -1
	_seed = randf() * 100.0
	_setup_sprite()
	_setup_light()


func _setup_sprite() -> void:
	if ResourceLoader.exists(TORCH_TEX):
		_sprite = Sprite2D.new()
		_sprite.name = "TorchSprite"
		_sprite.texture = load(TORCH_TEX) as Texture2D
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_sprite.centered = true
		add_child(_sprite)


func _setup_light() -> void:
	_light = WorldLight.new()
	_light.name = "FlameGlow"
	_light.follow = &"torch"
	_light.lit = true
	_light.flicker = true
	_light.casts_shadow = false
	_light.color = light_color
	_light.base_energy = base_energy
	_light.base_radius = light_radius
	_light.position = Vector2(0.0, -8.0)
	add_child(_light)


func _process(delta: float) -> void:
	if _light == null:
		return
	_time += delta * 8.0
	_light.set_flame_frame(int(_time + _seed) % 8)
