class_name PauseMenu
extends CanvasLayer
## 暂停菜单：Esc 开合，继续 / 操作说明 / 回到标题。
##
## 整棵子树 PROCESS_MODE_ALWAYS，所以 get_tree().paused 之后自己还能动。
## 操作说明面板与标题屏共用 ControlsPanel。

const TITLE_PATH := "res://scenes/ui/TitleScreen.tscn"

const ID_RESUME := &"resume"
const ID_CONTROLS := &"controls"
const ID_TITLE := &"title"

var _root: Control
var _menu: MenuList
var _controls: ControlsPanel


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	# 不加屏幕四角花饰：那是标题屏的排场，这里会跟左上角的状态板撞在一起。
	_root.add_child(UiKit.scrim(0.78, 0.78, 0.78))

	var frame := UiKit.panel(&"OrnatePanel")
	frame.set_anchors_preset(Control.PRESET_CENTER)
	frame.grow_horizontal = Control.GROW_DIRECTION_BOTH
	frame.grow_vertical = Control.GROW_DIRECTION_BOTH
	_root.add_child(frame)

	var column := VBoxContainer.new()
	frame.add_child(column)
	column.add_child(UiKit.label("暂 停", &"HeadLabel", HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(UiKit.divider())

	_menu = MenuList.new()
	column.add_child(_menu)
	_menu.add_item(ID_RESUME, "回 到 锈 墓")
	_menu.add_item(ID_CONTROLS, "操 作 说 明")
	_menu.add_item(ID_TITLE, "返 回 标 题")
	_menu.chosen.connect(_on_chosen)

	column.add_child(UiKit.label("进度在余烬巢刻录 · 回标题不会丢档",
			&"FootnoteLabel", HORIZONTAL_ALIGNMENT_CENTER))

	_controls = ControlsPanel.new()
	_controls.layer = 21
	_controls.closed.connect(func() -> void: _menu.active = true)
	add_child(_controls)


func is_open() -> bool:
	return visible


func open() -> void:
	if visible:
		return
	visible = true
	_menu.active = true
	get_tree().paused = true
	Director.suspend()
	Sfx.play(&"ui_select")


func close() -> void:
	if not visible:
		return
	_controls.visible = false
	visible = false
	get_tree().paused = false
	Director.resume()
	Sfx.play(&"ui_back")


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	# 操作说明自己会吃掉 ui_cancel，走到这里说明它没开着。
	if visible:
		close()
	else:
		open()
	get_viewport().set_input_as_handled()


func _on_chosen(id: StringName) -> void:
	match id:
		ID_RESUME:
			close()
		ID_CONTROLS:
			_menu.active = false
			_controls.open()
		ID_TITLE:
			get_tree().paused = false
			Director.resume()
			Director.fade_to(TITLE_PATH)
