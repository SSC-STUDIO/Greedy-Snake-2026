class_name TorchLight
extends Node2D
## Gothic wall torch with atmospheric flickering point light and embers.
## The 64×192 wall plate goes through RuinPlate (8px columns, broken crown)
## so the bastion reads as ruined masonry instead of a hard-edged dark box.

const TORCH_TEX := "res://assets/env/bg_wall_torch.png"
## 火把在贴图 y≈96–150；切口最深 6 档 × 8px = 48px，不会碰到火焰。
const CROWN_MAX_STEPS := 6

@export var light_color: Color = Color(1.0, 0.65, 0.32, 1.0)
@export var base_energy: float = 0.60
@export var light_radius: float = 64.0

var _light: WorldLight
var _sprite: Node2D
var _time: float = 0.0
var _seed: float = 0.0


func _ready() -> void:
	z_index = -1
	_seed = randf() * 100.0
	_setup_sprite()
	_setup_light()


func _setup_sprite() -> void:
	if not ResourceLoader.exists(TORCH_TEX):
		return
	var tex := load(TORCH_TEX) as Texture2D
	if tex == null:
		return
	_sprite = Node2D.new()
	_sprite.name = "TorchSprite"
	# Keep the old centered-sprite footprint: plate top-left at (-w/2, -h/2).
	_sprite.position = -Vector2(float(tex.get_width()), float(tex.get_height())) * 0.5
	add_child(_sprite)
	RuinPlate.build(_sprite, tex, global_position, CROWN_MAX_STEPS)


func crown_profile(strips: int) -> PackedInt32Array:
	return RuinPlate.crown_profile(strips, global_position, CROWN_MAX_STEPS)


func _setup_light() -> void:
	_light = WorldLight.new()
	_light.name = "FlameGlow"
	_light.follow = &"torch"
	_light.lit = true
	_light.flicker = true
	# WorldLight controls shadowing through its presentation defaults; Godot 4's
	# PointLight2D has no casts_shadow property.
	_light.color = light_color
	_light.energy = base_energy
	_light.texture_scale = light_radius / 32.0
	_light.position = Vector2(0.0, -8.0)
	add_child(_light)
	_light.shadow_enabled = false


func _process(delta: float) -> void:
	if _light == null:
		return
	_time += delta * 8.0
	_light.set_flame_frame(int(_time + _seed) % 8)
