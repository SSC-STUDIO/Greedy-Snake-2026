class_name TitleScreen
extends Control
## 标题屏：keyart + 像素锈蚀标题牌 + 余烬粒子 + 四项菜单。
##
## 菜单由 MenuList 负责键鼠导航，操作说明复用 ControlsPanel（与暂停菜单同一份）。
## 气氛三件套：keyart 火光呼吸、标题牌辉光呼吸、上升余烬与飘落灰烬。

const KEYART_PATH := "res://assets/kenney_clean/backgrounds/title_keyart.png"
const LEVEL_PATH := "res://scenes/levels/Level01_Static.tscn"

const EMBERS_RISING := 30
const EMBERS_FALLING := 14
const KEYART_BREATH_PERIOD := 5.5
const LOGO_BREATH_PERIOD := 3.2
const FADE_OUT := 0.7
const BAND_HEIGHT := 34.0
## 角饰要躲开底部装饰带，否则会跟署名文字撞在一起。
const CORNER_INSET := 16.0

const ID_NEW := &"new"
const ID_CONTINUE := &"continue"
const ID_CONTROLS := &"controls"
const ID_QUIT := &"quit"

var _started := false
var _time := 0.0
var _keyart: TextureRect
var _logo: TextureRect
var _menu: MenuList
var _controls: ControlsPanel
var _fade: ColorRect


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	DisplayServer.window_set_title("Rustgrave")
	_build_backdrop()
	_build_masthead()
	_build_menu()
	_build_chrome()
	# 覆盖层最后加：Control 的绘制与鼠标拾取都按子节点顺序，越后越上。
	_build_overlays()


func _build_backdrop() -> void:
	_keyart = TextureRect.new()
	_keyart.name = "Keyart"
	_keyart.set_anchors_preset(Control.PRESET_FULL_RECT)
	_keyart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_keyart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_keyart.texture = UiKit.tex(KEYART_PATH)
	_keyart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_keyart)

	# 上下压暗：给标题牌和菜单垫底，同时盖掉 keyart 右下角的水印。
	add_child(UiKit.scrim(0.62, 0.20, 0.90))
	add_child(UiKit.EmberField.build(Rect2(Vector2.ZERO, Vector2(1280, 720)),
			EMBERS_RISING, EMBERS_FALLING))
	UiKit.corner_brackets(self, CORNER_INSET, BAND_HEIGHT + CORNER_INSET)


func _build_masthead() -> void:
	_logo = UiKit.sprite_rect(UiKit.TEX_TITLE_LOGO)
	_logo.name = "TitleLogo"
	_logo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_logo.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_logo.offset_top = 44.0
	add_child(_logo)

	var subtitle := UiKit.label("锈 墓 · 余 烬 骑 士", &"SubHeadLabel",
			HORIZONTAL_ALIGNMENT_CENTER)
	subtitle.anchor_left = 0.0
	subtitle.anchor_right = 1.0
	subtitle.offset_top = 164.0
	subtitle.offset_bottom = 196.0
	add_child(subtitle)

	var rule := UiKit.divider()
	rule.set_anchors_preset(Control.PRESET_CENTER_TOP)
	rule.grow_horizontal = Control.GROW_DIRECTION_BOTH
	rule.offset_top = 202.0
	add_child(rule)


func _build_menu() -> void:
	_menu = MenuList.new()
	_menu.name = "Menu"
	_menu.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_menu.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_menu.offset_top = 254.0
	add_child(_menu)

	_menu.add_item(ID_NEW, "点 燃 余 烬")
	var cont := "回 看 余 烬" if SaveData.peek_ending() != "" else "继 续 旅 程"
	_menu.add_item(ID_CONTINUE, cont, not SaveData.has_save())
	_menu.add_item(ID_CONTROLS, "操 作 说 明")
	_menu.add_item(ID_QUIT, "离 开 锈 墓")
	_menu.chosen.connect(_on_chosen)


## 底部装饰带：署名靠左、导航提示靠右，都排进同一条锈色铆钉带里。
func _build_chrome() -> void:
	var band := UiKit.panel(&"BandPanel")
	band.anchor_left = 0.0
	band.anchor_right = 1.0
	band.anchor_top = 1.0
	band.anchor_bottom = 1.0
	band.offset_top = -BAND_HEIGHT
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(band)

	var row := HBoxContainer.new()
	band.add_child(row)

	var credits := UiKit.label(
			"美术 ansimuz · aamatniekss · Kronovi · CodeManu · Kenney — 音频 Kenney",
			&"FootnoteLabel")
	credits.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(credits)

	row.add_child(UiKit.label("字体 Fusion Pixel (OFL) · ↑↓ 选择 · Enter 确认",
			&"FootnoteLabel", HORIZONTAL_ALIGNMENT_RIGHT))


func _build_overlays() -> void:
	_controls = ControlsPanel.new()
	_controls.layer = 5
	_controls.closed.connect(func() -> void: _menu.active = true)
	add_child(_controls)

	_fade = ColorRect.new()
	_fade.name = "Fade"
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)


func _process(delta: float) -> void:
	_time += delta
	DisplayServer.window_set_title("Rustgrave")
	# 火光呼吸：keyart 整体在暖色间轻微起伏，标题牌辉光跟着更快一点的节奏。
	var warm := 0.5 + 0.5 * sin(TAU * _time / KEYART_BREATH_PERIOD)
	_keyart.modulate = Color(1.0, 1.0, 1.0).lerp(Color(1.06, 0.94, 0.86), warm)
	var glow := 0.5 + 0.5 * sin(TAU * _time / LOGO_BREATH_PERIOD)
	_logo.modulate = Color(0.94, 0.94, 0.94).lerp(Color(1.10, 1.04, 0.98), glow)


func _on_chosen(id: StringName) -> void:
	if _started:
		return
	match id:
		ID_NEW:
			_start(false)
		ID_CONTINUE:
			_start(true)
		ID_CONTROLS:
			_menu.active = false
			_controls.open()
		ID_QUIT:
			get_tree().quit()


func _start(continue_game: bool) -> void:
	_started = true
	_menu.active = false
	if continue_game:
		SaveData.load_game()
	else:
		SaveData.delete_save()
	Sfx.play(&"gate")
	Director.fade_to(LEVEL_PATH, FADE_OUT)
