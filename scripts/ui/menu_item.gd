class_name MenuItem
extends Control
## 一行菜单：主题的 Button 样式盒 + 余烬光标 + 选中呼吸。
##
## 不用 Button，因为选中态需要在键盘导航下自己控制（Button 的 focus 框会叠在
## normal 之上），而且要挂帧动画火苗。样式仍然只从主题取，保证与全局一致。
##
## 刻意不做几何缩放：像素字体一旦被非整数倍缩放就会出灰边，所以“呼吸”走
## modulate 亮度，位移走整数像素。

signal activated
## 鼠标移到本行上时发出，菜单容器据此把选中项挪过来。
signal hover_requested

const HEIGHT := 52.0
const SELECTED_INDENT := 8.0
const BREATH_PERIOD := 1.6
const BREATH_MIN := 1.0
const BREATH_MAX := 1.18

var disabled := false:
	set(value):
		disabled = value
		_refresh()

var selected := false:
	set(value):
		if selected == value:
			return
		selected = value
		_refresh()

var _text := ""
var _panel: Panel
var _label: Label
var _cursor: TextureRect
var _brazier: Node2D
var _time := 0.0


func _init(text: String = "") -> void:
	_text = text


func _ready() -> void:
	custom_minimum_size = Vector2(420.0, HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	_label = UiKit.label(_text, &"MenuItemLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_label)

	# 选中行左侧点一小簇余烬，是标题屏那套粒子的缩小版。
	_brazier = UiKit.EmberField.build(Rect2(14.0, 8.0, 22.0, HEIGHT - 16.0), 4, 0)
	add_child(_brazier)

	_cursor = UiKit.sprite_rect(UiKit.TEX_CURSOR)
	var art := _cursor.texture
	_cursor.position = Vector2(38.0, (HEIGHT - (art.get_height() if art != null else 28)) * 0.5)
	add_child(_cursor)

	mouse_entered.connect(func() -> void:
		if not disabled:
			hover_requested.emit())
	_refresh()


func set_text(value: String) -> void:
	_text = value
	if _label != null:
		_label.text = value


func _process(delta: float) -> void:
	if not selected or disabled:
		return
	_time += delta
	var breath := lerpf(BREATH_MIN, BREATH_MAX, 0.5 + 0.5 * sin(TAU * _time / BREATH_PERIOD))
	modulate = Color(breath, breath, breath)


func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton and event.pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		activated.emit()
		accept_event()


func _refresh() -> void:
	if _panel == null:
		return
	if disabled:
		_panel.theme_type_variation = &"MenuRowDisabled"
		_label.theme_type_variation = &"MenuItemLabelDisabled"
	elif selected:
		_panel.theme_type_variation = &"MenuRowSelected"
		_label.theme_type_variation = &"MenuItemLabelSelected"
	else:
		_panel.theme_type_variation = &"MenuRowNormal"
		_label.theme_type_variation = &"MenuItemLabel"
	position.x = SELECTED_INDENT if selected and not disabled else 0.0
	var lit := selected and not disabled
	_cursor.visible = lit
	_brazier.visible = lit
	if not lit:
		modulate = Color.WHITE
		_time = 0.0
	set_process(lit)
