extends Node

const MAIN_MENU_SCENE := preload("res://scenes/menus/MainMenu.tscn")
const SETTINGS_SCENE := preload("res://scenes/menus/SettingsMenu.tscn")
const ABOUT_SCENE := preload("res://scenes/menus/AboutMenu.tscn")
const ARENA_SCENE := preload("res://scenes/game/Arena.tscn")

var _root: Node
var _current_scene: Node
var _transitioning := false
var _transition_layer: CanvasLayer
var _transition_overlay: Control
var _transition_wash: ColorRect
var _transition_beam: ColorRect
var _transition_core: ColorRect

## 场景切换过渡动画持续时间
const FADE_OUT_DURATION := 0.22
const FADE_IN_DURATION := 0.32

func bootstrap(root: Node) -> void:
	_root = root
	_ensure_transition_layer()
	show_main_menu()

func show_main_menu() -> void:
	_change_to(MAIN_MENU_SCENE)

func show_settings() -> void:
	_change_to(SETTINGS_SCENE)

func show_about() -> void:
	_change_to(ABOUT_SCENE)

func start_game() -> void:
	AudioBus.play_game_bgm()
	_change_to(ARENA_SCENE)

func restart_game() -> void:
	AudioBus.play_game_bgm()
	_change_to(ARENA_SCENE)

func quit_game() -> void:
	get_tree().quit()

func _change_to(scene: PackedScene) -> void:
	if _root == null or _transitioning:
		return
	_transitioning = true
	_ensure_transition_layer()

	# 1. 用全屏遮罩扫出当前场景，避免廉价的硬淡入淡出。
	if _current_scene != null:
		if SettingsStore.animations_on:
			await _play_transition_cover(_current_scene)
		_current_scene.queue_free()
		_current_scene = null

	# 2. 实例化新场景
	_current_scene = scene.instantiate()
	_root.add_child(_current_scene)
	_wire_scene(_current_scene)

	# 3. 揭开新场景，同时给新画面一个轻微的镜头落位。
	if SettingsStore.animations_on:
		await _play_transition_reveal(_current_scene)

	_transitioning = false

func _wire_scene(scene: Node) -> void:
	if scene.has_signal("start_game_requested"):
		scene.start_game_requested.connect(start_game)
	if scene.has_signal("settings_requested"):
		scene.settings_requested.connect(show_settings)
	if scene.has_signal("about_requested"):
		scene.about_requested.connect(show_about)
	if scene.has_signal("menu_requested"):
		scene.menu_requested.connect(show_main_menu)
	if scene.has_signal("quit_requested"):
		scene.quit_requested.connect(quit_game)

func _ensure_transition_layer() -> void:
	if _transition_layer != null and is_instance_valid(_transition_layer):
		return
	if _root == null:
		return
	_transition_layer = CanvasLayer.new()
	_transition_layer.name = "TransitionLayer"
	_transition_layer.layer = 120
	_root.add_child(_transition_layer)

	_transition_overlay = Control.new()
	_transition_overlay.name = "TransitionOverlay"
	_transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_overlay.visible = false
	_transition_layer.add_child(_transition_overlay)

	_transition_wash = ColorRect.new()
	_transition_wash.color = Color(0.004, 0.016, 0.006, 0.0)
	_transition_wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_overlay.add_child(_transition_wash)

	_transition_beam = ColorRect.new()
	_transition_beam.color = Color(0.7, 1.0, 0.32, 0.0)
	_transition_overlay.add_child(_transition_beam)

	_transition_core = ColorRect.new()
	_transition_core.color = Color(0.95, 0.66, 0.24, 0.0)
	_transition_overlay.add_child(_transition_core)

func _play_transition_cover(scene: Node) -> void:
	_prepare_transition_bars(-0.42)
	_transition_overlay.visible = true
	_transition_wash.color.a = 0.0
	_transition_beam.color.a = 0.0
	_transition_core.color.a = 0.0

	var tween := _transition_overlay.create_tween()
	tween.set_parallel(true)
	tween.tween_property(_transition_wash, "color:a", 0.88, FADE_OUT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_transition_beam, "position:x", -_viewport_size().x * 0.08, FADE_OUT_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_transition_beam, "color:a", 0.34, FADE_OUT_DURATION * 0.72)
	tween.tween_property(_transition_core, "position:x", _viewport_size().x * 0.18, FADE_OUT_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_transition_core, "color:a", 0.26, FADE_OUT_DURATION * 0.6)
	if scene is CanvasItem:
		tween.tween_property(scene, "modulate:a", 0.0, FADE_OUT_DURATION * 0.85)
		if scene is Control or scene is Node2D:
			tween.tween_property(scene, "scale", Vector2(1.012, 1.012), FADE_OUT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished

func _play_transition_reveal(scene: Node) -> void:
	if scene is CanvasItem:
		scene.modulate.a = 0.0
	if scene is Control or scene is Node2D:
		scene.scale = Vector2(0.985, 0.985)
	_prepare_transition_bars(-0.08)
	_transition_overlay.visible = true
	_transition_wash.color.a = 0.88
	_transition_beam.color.a = 0.3
	_transition_core.color.a = 0.24

	var tween := _transition_overlay.create_tween()
	tween.set_parallel(true)
	tween.tween_property(_transition_wash, "color:a", 0.0, FADE_IN_DURATION).set_delay(0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_transition_beam, "position:x", _viewport_size().x * 1.16, FADE_IN_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_transition_beam, "color:a", 0.0, FADE_IN_DURATION * 0.68).set_delay(0.12)
	tween.tween_property(_transition_core, "position:x", _viewport_size().x * 1.34, FADE_IN_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_transition_core, "color:a", 0.0, FADE_IN_DURATION * 0.6).set_delay(0.08)
	if scene is CanvasItem:
		tween.tween_property(scene, "modulate:a", 1.0, FADE_IN_DURATION * 0.72).set_delay(0.05)
	if scene is Control or scene is Node2D:
		tween.tween_property(scene, "scale", Vector2.ONE, FADE_IN_DURATION).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	await tween.finished
	_transition_overlay.visible = false

func _prepare_transition_bars(start_ratio: float) -> void:
	var viewport_size := _viewport_size()
	var beam_width := viewport_size.x * 0.72
	_transition_beam.size = Vector2(beam_width, viewport_size.y * 1.35)
	_transition_beam.position = Vector2(viewport_size.x * start_ratio, viewport_size.y * -0.16)
	_transition_beam.rotation = -0.13
	_transition_core.size = Vector2(beam_width * 0.32, viewport_size.y * 1.42)
	_transition_core.position = Vector2(viewport_size.x * (start_ratio - 0.18), viewport_size.y * -0.19)
	_transition_core.rotation = -0.13

func _viewport_size() -> Vector2:
	if _root != null:
		return _root.get_viewport().get_visible_rect().size
	return Vector2(1280.0, 720.0)
