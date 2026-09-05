class_name GameContext
extends RefCounted
## The authored level owns physics and save paths; presentation owns screen UI.

const WORLD_PATH := "res://scenes/levels/Level01_Static.tscn"
const PRESENTATION_PATH := "res://scenes/ui/GamePresentation.tscn"
static var _blocked_through_frame: int = -1


static func tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


static func world_root(node: Node = null) -> Node:
	var cursor := node
	while cursor != null:
		if cursor.is_in_group("game_world"):
			return cursor
		cursor = cursor.get_parent()
	var scene_tree := tree()
	if scene_tree == null:
		return null
	var worlds := scene_tree.get_nodes_in_group("game_world")
	if worlds.size() == 1:
		return worlds[0]
	return node.get_parent() if node != null else scene_tree.current_scene


static func world_scene_path(node: Node = null) -> String:
	var world := world_root(node)
	return world.scene_file_path if world != null and world.scene_file_path != "" else WORLD_PATH


static func world_effects(node: Node = null) -> Node:
	var world := world_root(node)
	if world == null:
		return null
	var effects := world.get_node_or_null("WorldEffects")
	if effects == null:
		effects = Node2D.new()
		effects.name = "WorldEffects"
		effects.z_index = 8
		world.add_child(effects)
	return effects


static func free_after(node: Node, seconds: float) -> void:
	if node == null or not is_instance_valid(node):
		return
	var tw := node.create_tween()
	tw.tween_interval(seconds)
	tw.tween_callback(node.queue_free)


static func ui_host(node: Node = null) -> Node:
	var scene_tree := tree()
	if scene_tree != null:
		var presentation := scene_tree.get_first_node_in_group("game_presentation")
		if presentation != null:
			return presentation.get_node("UiHost")
	return world_root(node)


static func suppress_gameplay_input() -> void:
	_blocked_through_frame = Engine.get_physics_frames() + 1


static func gameplay_input_enabled() -> bool:
	var scene_tree := tree()
	return scene_tree != null and not scene_tree.paused \
			and not Director.is_input_locked() and not Director.choice_hold \
			and Engine.get_physics_frames() > _blocked_through_frame


static func route_scene(path: String) -> String:
	return PRESENTATION_PATH if path == WORLD_PATH else path
