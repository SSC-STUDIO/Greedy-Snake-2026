class_name PresentationMetrics
extends Object
## Integer content rectangle for the 640×360 world image inside a 1280×720 UI.

const WORLD_SIZE := Vector2i(640, 360)
const UI_SIZE := Vector2i(1280, 720)


static func calculate(window_size: Vector2i) -> Dictionary:
	var scale := maxi(1, mini(window_size.x / WORLD_SIZE.x, window_size.y / WORLD_SIZE.y))
	var content := Vector2i(WORLD_SIZE.x * scale, WORLD_SIZE.y * scale)
	var origin := Vector2i(
			int((window_size.x - content.x) / 2.0),
			int((window_size.y - content.y) / 2.0))
	var physical := Rect2(Vector2(origin), Vector2(content))
	var to_canvas := Vector2(UI_SIZE) / Vector2(window_size)
	var canvas_rect := Rect2(physical.position * to_canvas, physical.size * to_canvas)
	var ui_transform := Transform2D(
			Vector2(canvas_rect.size.x / float(UI_SIZE.x), 0.0),
			Vector2(0.0, canvas_rect.size.y / float(UI_SIZE.y)),
			canvas_rect.position)
	return {
		"scale": scale,
		"physical_rect": physical,
		"canvas_rect": canvas_rect,
		"ui_transform": ui_transform,
	}


static func for_window(win: Window) -> Dictionary:
	return calculate(win.size)


static func bind_layer(layer: CanvasLayer) -> void:
	if layer == null:
		return
	WorldClock.isolate_ui_layer(layer)
	if not layer.is_inside_tree():
		return
	var metrics := for_window(layer.get_tree().root)
	layer.transform = metrics["ui_transform"]


static func unbind_layer(layer: CanvasLayer) -> void:
	if layer == null:
		return
	layer.transform = Transform2D.IDENTITY


static func bind_descendants(root: Node) -> void:
	if root == null:
		return
	if root is CanvasLayer:
		bind_layer(root)
	for child in root.get_children():
		bind_descendants(child)


static func bind_runtime_overlays(scene_tree: SceneTree = null) -> void:
	if scene_tree == null:
		scene_tree = Engine.get_main_loop() as SceneTree
	if scene_tree == null:
		return
	for autoload_name in ["Director", "Juice"]:
		var node := scene_tree.root.get_node_or_null(autoload_name)
		if node != null:
			bind_descendants(node)
	var presentation := scene_tree.get_first_node_in_group("game_presentation")
	if presentation != null:
		bind_descendants(presentation.get_node_or_null("UiHost"))


static func unbind_runtime_overlays(scene_tree: SceneTree = null) -> void:
	if scene_tree == null:
		scene_tree = Engine.get_main_loop() as SceneTree
	if scene_tree == null:
		return
	for autoload_name in ["Director", "Juice"]:
		var node := scene_tree.root.get_node_or_null(autoload_name)
		if node == null:
			continue
		for child in node.get_children():
			if child is CanvasLayer:
				unbind_layer(child)
