class_name WorldAtmosphere
extends Node
## One presentation transition for the play canvas, backdrop and local lights.
## WorldClock owns simulation state; this node never changes it.

const FOLLOW_RATE := 3.5
var indoor_weight := 0.0
var _world_tint: CanvasModulate
var _backdrop_tint: CanvasModulate
var _foreground_tint: CanvasModulate
var _moon_fill: DirectionalLight2D


static func for_node(node: Node) -> WorldAtmosphere:
	if not node.is_inside_tree():
		return null
	for candidate in node.get_tree().get_nodes_in_group("world_atmosphere"):
		if candidate.get_viewport() == node.get_viewport():
			return candidate as WorldAtmosphere
	return null


func build(host: Node2D, backdrop: ParallaxBackground, foreground: ParallaxBackground = null) -> void:
	add_to_group("world_atmosphere")
	_world_tint = _tint(host, "MoodTint")
	_backdrop_tint = _tint(backdrop, "BackdropTint")
	if foreground != null:
		_foreground_tint = _tint(foreground, "ForegroundTint")
	_moon_fill = host.get_node_or_null("MoonFill") as DirectionalLight2D
	if _moon_fill == null:
		_moon_fill = DirectionalLight2D.new()
		_moon_fill.name = "MoonFill"
		_moon_fill.color = Color(0.72, 0.80, 1.0)
		_moon_fill.shadow_enabled = true
		_moon_fill.height = 0.65
		_moon_fill.rotation = deg_to_rad(-18.0)
		host.add_child(_moon_fill)
	indoor_weight = 1.0 if WorldClock.zone == WorldClock.Zone.INDOORS else 0.0
	_apply(1.0)


func _process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	var blend := 1.0 - exp(-FOLLOW_RATE * maxf(delta, 0.0))
	var target := 1.0 if WorldClock.zone == WorldClock.Zone.INDOORS else 0.0
	indoor_weight = lerpf(indoor_weight, target, blend)
	_apply(blend)


func _apply(blend: float) -> void:
	var ambient: Color = WorldClock.outdoor_tint().lerp(WorldClock.indoor_tint(), indoor_weight)
	if _world_tint != null:
		_world_tint.color = _world_tint.color.lerp(ambient, blend)
	# Separate CanvasLayers need their own tint; background never outranks actors.
	var distant: Color = ambient.darkened(0.24)
	if _backdrop_tint != null:
		_backdrop_tint.color = _backdrop_tint.color.lerp(distant, blend)
	if _foreground_tint != null:
		_foreground_tint.color = _foreground_tint.color.lerp(ambient, blend)
	if _moon_fill != null:
		var target: float = WorldClock.outdoor_moon_energy() * (1.0 - indoor_weight)
		_moon_fill.energy = lerpf(_moon_fill.energy, target, blend)
		_moon_fill.enabled = _moon_fill.energy > 0.001


func _tint(host: Node, node_name: String) -> CanvasModulate:
	var result := host.get_node_or_null(node_name) as CanvasModulate
	if result == null:
		result = CanvasModulate.new()
		result.name = node_name
		host.add_child(result)
	return result
