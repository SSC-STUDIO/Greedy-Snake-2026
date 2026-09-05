class_name GamePresentation
extends Control
## Only the world is rasterized at 640x360. Root-window UI is drawn at native size.

var world_viewport: SubViewport
var world_image: TextureRect


func _enter_tree() -> void:
	add_to_group("game_presentation")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	DisplayFit.apply()
	var background := ColorRect.new()
	background.name = "LetterboxBackground"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color.BLACK
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var ui := Node.new()
	ui.name = "UiHost"
	add_child(ui)
	ui.child_entered_tree.connect(func(node: Node) -> void:
		if node is CanvasLayer:
			PresentationMetrics.bind_layer(node))
	world_viewport = SubViewport.new()
	world_viewport.name = "WorldViewport"
	world_viewport.size = PresentationMetrics.WORLD_SIZE
	world_viewport.world_2d = World2D.new()
	world_viewport.disable_3d = true
	world_viewport.snap_2d_transforms_to_pixel = true
	world_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	world_viewport.handle_input_locally = true
	world_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(world_viewport)
	world_image = TextureRect.new()
	world_image.name = "WorldImage"
	world_image.texture = world_viewport.get_texture()
	world_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	world_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(world_image)
	var packed := load(GameContext.WORLD_PATH) as PackedScene
	world_viewport.add_child(packed.instantiate())
	get_tree().root.size_changed.connect(_layout)
	_layout()
	GameContext.suppress_gameplay_input()


func _layout() -> void:
	var rect: Rect2 = PresentationMetrics.for_window(get_tree().root)["canvas_rect"]
	world_image.position = rect.position
	world_image.size = rect.size


func _unhandled_input(event: InputEvent) -> void:
	if world_viewport == null or not GameContext.gameplay_input_enabled():
		return
	var forwarded := event
	if event is InputEventMouse:
		var mouse := event as InputEventMouse
		var rect := Rect2(world_image.position, world_image.size)
		if not rect.has_point(mouse.position):
			GameContext.suppress_gameplay_input()
			return
		var transform := Transform2D.IDENTITY
		transform = transform.scaled(Vector2(PresentationMetrics.WORLD_SIZE) / rect.size)
		transform.origin = -rect.position * transform.get_scale()
		forwarded = event.xformed_by(transform)
	world_viewport.push_input(forwarded, true)
	if world_viewport.is_input_handled():
		get_viewport().set_input_as_handled()
