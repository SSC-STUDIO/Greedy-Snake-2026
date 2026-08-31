class_name Caption
extends CanvasLayer
## 底部打字机字幕。过场专用，和 HUD 播报横幅分开，互不覆盖。

const CPS := 22.0

var _panel: PanelContainer
var _label: Label
var _full: String = ""
var _shown: int = 0
var _cps: float = CPS
var _accum: float = 0.0
var _typing: bool = false


func _ready() -> void:
	layer = 16
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = UiKit.panel(&"BannerPanel")
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.offset_left = -320.0
	_panel.offset_right = 320.0
	_panel.offset_top = -92.0
	_panel.offset_bottom = -48.0
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_label = UiKit.label("", &"AnnounceLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_label)


func show_line(text: String, cps: float = CPS) -> void:
	_full = text
	_shown = 0
	_cps = maxf(8.0, cps)
	_accum = 0.0
	_typing = not text.is_empty()
	_label.text = ""
	_panel.visible = text != ""
	if DisplayServer.get_name() == "headless":
		reveal()


func reveal() -> void:
	_shown = _full.length()
	_label.text = _full
	_typing = false


func hide_line() -> void:
	_typing = false
	_full = ""
	_shown = 0
	_label.text = ""
	_panel.visible = false


func is_typing() -> bool:
	return _typing


func _process(delta: float) -> void:
	if not _typing:
		return
	_accum += delta * _cps
	var add := int(_accum)
	if add <= 0:
		return
	_accum -= float(add)
	_shown = mini(_full.length(), _shown + add)
	_label.text = _full.substr(0, _shown)
	if _shown >= _full.length():
		_typing = false
