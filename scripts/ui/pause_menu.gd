class_name PauseMenu
extends CanvasLayer
## 暂停菜单：Esc 开合，继续 / 操作说明 / 回到标题。
##
## 整棵子树 PROCESS_MODE_ALWAYS，所以 get_tree().paused 之后自己还能动。
## 操作说明面板与标题屏共用 ControlsPanel。

const TITLE_PATH := "res://scenes/ui/TitleScreen.tscn"

const ID_RESUME := &"resume"
const ID_FULLSCREEN := &"fullscreen"
const ID_FIT_MODE := &"fit_mode"
const ID_CONTROLS := &"controls"
const ID_TITLE := &"title"

var _root: Control
var _menu: MenuList
var _fullscreen_item: MenuItem
var _fit_mode_item: MenuItem
var _res_label: Label
var _controls: ControlsPanel


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	WorldClock.isolate_ui_layer(self)
	_build()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	# 整屏遮罩：2.5K 上半透明卡片会把左上角心槽透出来，先铺实底再压一层渐变。
	var veil := ColorRect.new()
	veil.name = "Veil"
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(UiKit.SCRIM.r, UiKit.SCRIM.g, UiKit.SCRIM.b, 0.90)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(veil)
	_root.add_child(UiKit.scrim(0.46, 0.22, 0.58))

	var frame := UiKit.panel(&"OrnatePanel")
	frame.name = "PauseFrame"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 120.0
	frame.offset_right = -120.0
	frame.offset_top = 36.0
	frame.offset_bottom = -36.0
	_root.add_child(frame)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(column)
	column.add_child(UiKit.label("暂 停", &"HeadLabel", HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(UiKit.divider())

	_menu = MenuList.new()
	_menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_menu)
	_menu.add_item(ID_RESUME, "回 到 锈 墓")
	_fullscreen_item = _menu.add_item(ID_FULLSCREEN, DisplayFit.fullscreen_label())
	_fit_mode_item = _menu.add_item(ID_FIT_MODE, DisplayFit.fit_mode_label())
	_menu.add_item(ID_CONTROLS, "操 作 说 明")
	_menu.add_item(ID_TITLE, "返 回 标 题")
	_menu.chosen.connect(_on_chosen)

	column.add_child(_volume_row("音 效", &"Sfx"))
	column.add_child(_volume_row("氛 围", &"Ambience"))

	_res_label = UiKit.label("视口: %s" % DisplayFit.get_resolution_string(),
			&"FootnoteLabel", HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(_res_label)

	column.add_child(UiKit.label("进度在余烬巢刻录 · 回标题不会丢档",
			&"FootnoteLabel", HORIZONTAL_ALIGNMENT_CENTER))

	_controls = ControlsPanel.new()
	_controls.layer = 21
	_controls.closed.connect(func() -> void: _menu.active = true)
	add_child(_controls)


func _volume_row(label: String, bus: StringName) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var name := UiKit.label(label, &"DimLabel")
	name.custom_minimum_size = Vector2(88, 0)
	row.add_child(name)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.custom_minimum_size = Vector2(240, 22)
	slider.value = Sfx.bus_percent(bus)
	slider.value_changed.connect(func(v: float) -> void: Sfx.set_bus_percent(bus, v))
	row.add_child(slider)
	return row


func is_open() -> bool:
	return visible


func open() -> void:
	if visible or Director.choice_hold:
		return
	visible = true
	_menu.active = true
	_set_play_hud_visible(false)
	if _fit_mode_item != null:
		_fit_mode_item.set_text(DisplayFit.fit_mode_label())
	if _fullscreen_item != null:
		_fullscreen_item.set_text(DisplayFit.fullscreen_label())
	if _res_label != null:
		_res_label.text = "视口: %s" % DisplayFit.get_resolution_string()
	get_tree().paused = true
	Director.suspend()
	Sfx.play(&"ui_select")


func close() -> void:
	if not visible:
		return
	if _controls != null:
		_controls.visible = false
	visible = false
	_set_play_hud_visible(true)
	Sfx.play(&"ui_back")
	if Director.choice_hold:
		return
	get_tree().paused = false
	Director.resume()


func _set_play_hud_visible(show: bool) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var chrome := parent.get_node_or_null("Root") as CanvasItem
	if chrome != null:
		chrome.visible = show


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if Director.choice_hold and not visible:
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
		ID_FULLSCREEN:
			DisplayFit.toggle_fullscreen()
			if _fullscreen_item != null:
				_fullscreen_item.set_text(DisplayFit.fullscreen_label())
			if _res_label != null:
				_res_label.text = "视口: %s" % DisplayFit.get_resolution_string()
		ID_FIT_MODE:
			var label := DisplayFit.cycle_fit_mode(get_tree().root)
			if _fit_mode_item != null:
				_fit_mode_item.set_text(label)
			if _res_label != null:
				_res_label.text = "视口: %s" % DisplayFit.get_resolution_string()
			Sfx.play(&"ui_select")
		ID_CONTROLS:
			_menu.active = false
			_controls.open()
		ID_TITLE:
			get_tree().paused = false
			Director.resume()
			Director.fade_to(TITLE_PATH)
