extends Node

const MAIN_MENU_SCENE := preload("res://scenes/menus/MainMenu.tscn")
const SETTINGS_SCENE := preload("res://scenes/menus/SettingsMenu.tscn")
const ABOUT_SCENE := preload("res://scenes/menus/AboutMenu.tscn")
const ARENA_SCENE := preload("res://scenes/game/Arena.tscn")

var _root: Node
var _current_scene: Node

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
	_change_to(ARENA_SCENE)

func restart_game() -> void:
	_change_to(ARENA_SCENE)

func quit_game() -> void:
	get_tree().quit()

func _change_to(scene: PackedScene) -> void:
	if _root == null:
		return
	if _current_scene != null:
		_current_scene.queue_free()
		_current_scene = null

	_current_scene = scene.instantiate()
	_root.add_child(_current_scene)
	_wire_scene(_current_scene)

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
