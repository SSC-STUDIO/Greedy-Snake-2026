class_name ForgeHeart
extends Interactable
## 锻炉残芯：复燃或熄灭。写入 SaveData.ending 后淡回标题。

const TITLE_PATH := "res://scenes/ui/TitleScreen.tscn"
const ID_REKINDLE := &"rekindle"
const ID_SNUFF := &"snuff"

var unlocked: bool = false
var _choosing := false
var _layer: CanvasLayer
var _menu: MenuList


func _ready() -> void:
	super._ready()
	prompt = "E 触碰炉心"
	ensure_sprite("res://assets/env/bg_altar.png", Vector2(36, 40), Vector2(-10, -8), Palette.EMBER)
	if SaveData.has_flag("boss_dead"):
		unlock()
	else:
		lock()


func can_interact(_actor: Node) -> bool:
	return unlocked


func lock() -> void:
	unlocked = false
	visible = false
	monitoring = false
	monitorable = false


func unlock() -> void:
	unlocked = true
	visible = true
	monitoring = true
	monitorable = true


func interact(actor: Node) -> void:
	if _choosing or not actor is Player or not can_interact(actor):
		return
	_choosing = true
	_open_choice()


func _open_choice() -> void:
	Director.choice_hold = true
	Director.suspend()
	_layer = CanvasLayer.new()
	_layer.layer = 25
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(root)
	root.add_child(UiKit.scrim(0.72, 0.72, 0.72))
	var frame := UiKit.panel(&"OrnatePanel")
	frame.set_anchors_preset(Control.PRESET_CENTER)
	frame.grow_horizontal = Control.GROW_DIRECTION_BOTH
	frame.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(frame)
	var column := VBoxContainer.new()
	frame.add_child(column)
	column.add_child(UiKit.label("炉 心 还 在 跳", &"HeadLabel", HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(UiKit.divider())
	column.add_child(UiKit.label("复燃会唤醒整座陵墓。熄灭，连你一并散掉。",
			&"DimLabel", HORIZONTAL_ALIGNMENT_CENTER))
	_menu = MenuList.new()
	column.add_child(_menu)
	_menu.add_item(ID_REKINDLE, "复 燃")
	_menu.add_item(ID_SNUFF, "熄 灭")
	_menu.chosen.connect(_on_chosen)
	get_tree().paused = true


func _on_chosen(id: StringName) -> void:
	Director.choice_hold = false
	Director.resume()
	get_tree().paused = false
	if _layer:
		_layer.queue_free()
	var kind := "rekindle" if id == ID_REKINDLE else "snuff"
	SaveData.ending = kind
	GameEvents.ending_chosen.emit(id)
	var player := get_tree().get_first_node_in_group("player")
	if player:
		SaveData.save_game(get_tree().current_scene.scene_file_path, player)
	var line := "陵墓在锈里睁开眼。" if kind == "rekindle" else "余烬落回炉灰。骑士也是。"
	Director.play([
		{"kind": "lock"},
		{"kind": "caption", "text": line, "hold": 2.2},
		{"kind": "wait", "seconds": 0.2},
		{"kind": "unlock"},
	])
	await Director.finished
	Director.fade_to(TITLE_PATH)
