class_name PresentationMetrics
extends RefCounted
## Physical integer world pixels; UI remains vector/font drawing in the root canvas.

const WORLD_SIZE := Vector2i(640, 360)
const UI_SIZE := Vector2i(1280, 720)


static func calculate(window_size: Vector2i) -> Dictionary:
	var physical := Vector2(maxi(window_size.x, 640), maxi(window_size.y, 360))
	var integer_scale := maxi(1, int(floor(minf(physical.x / 640.0, physical.y / 360.0))))
	var content_size := Vector2(WORLD_SIZE) * integer_scale
	var origin := ((physical - content_size) * 0.5).floor()
	# The native root stretches per axis. Compensate here so Godot never rounds
	# an aspect-preserved render target (1366x768 otherwise becomes 1365x768).
	var root_scale := physical / Vector2(UI_SIZE)
	var canvas_origin := origin / root_scale
	var ui_scale := float(integer_scale) * 0.5
	return {
		"scale": integer_scale,
		"physical_rect": Rect2(origin, content_size),
		"canvas_rect": Rect2(canvas_origin, content_size / root_scale),
		"ui_transform": Transform2D(0.0, Vector2.ONE * ui_scale / root_scale, 0.0, canvas_origin),
	}


static func for_window(win: Window) -> Dictionary:
	return calculate(win.size if win != null else UI_SIZE)


static func apply_layer(layer: CanvasLayer) -> void:
	if not is_instance_valid(layer) or not layer.is_inside_tree():
		return
	layer.transform = for_window(layer.get_tree().root)["ui_transform"]


static func bind_layer(layer: CanvasLayer) -> void:
	if layer == null or not layer.is_inside_tree() or layer.has_meta("presentation_bound"):
		return
	layer.set_meta("presentation_bound", true)
	layer.add_child(LayerBinding.new())
	apply_layer(layer)


class LayerBinding extends Node:
	func _ready() -> void:
		get_tree().root.size_changed.connect(_refresh)


	func _refresh() -> void:
		PresentationMetrics.apply_layer(get_parent() as CanvasLayer)
