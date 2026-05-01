extends Node

const MAIN_MENU_SCENE := preload("res://scenes/menus/MainMenu.tscn")
const SETTINGS_SCENE := preload("res://scenes/menus/SettingsMenu.tscn")
const ABOUT_SCENE := preload("res://scenes/menus/AboutMenu.tscn")
const ARENA_SCENE := preload("res://scenes/game/Arena.tscn")

var _root: Node
var _current_scene: Node
var _transitioning := false

## 场景切换过渡动画持续时间
const FADE_OUT_DURATION := 0.2
const FADE_IN_DURATION := 0.25

func bootstrap(root: Node) -> void:
	_root = root
	show_main_menu()

func show_main_menu() -> void:
	AudioBus.play_bgm()
	_change_to(MAIN_MENU_SCENE)

func show_settings() -> void:
	_change_to(SETTINGS_SCENE)

func show_about() -> void:
	_change_to(ABOUT_SCENE)

func start_game() -> void:
	AudioBus.stop_bgm()
	_change_to(ARENA_SCENE)

func restart_game() -> void:
	_change_to(ARENA_SCENE)

func quit_game() -> void:
	get_tree().quit()

func _change_to(scene: PackedScene) -> void:
	if _root == null or _transitioning:
		return
	_transitioning = true

	# 1. 淡出当前场景
	if _current_scene != null:
		if SettingsStore.animations_on:
			var tween := _current_scene.create_tween()
			tween.tween_property(_current_scene, "modulate:a", 0.0, FADE_OUT_DURATION)
			await tween.finished
		_current_scene.queue_free()
		_current_scene = null

	# 2. 实例化新场景
	_current_scene = scene.instantiate()
	if SettingsStore.animations_on:
		_current_scene.modulate.a = 0.0
	_root.add_child(_current_scene)
	_wire_scene(_current_scene)

	# 3. 淡入新场景
	if SettingsStore.animations_on:
		var tween := _current_scene.create_tween()
		tween.tween_property(_current_scene, "modulate:a", 1.0, FADE_IN_DURATION)
		await tween.finished

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
