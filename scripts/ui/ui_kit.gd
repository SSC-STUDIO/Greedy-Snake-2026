class_name UiKit
extends Object
## UI 共用素材路径、配色与构件工厂。
##
## 外观规则全部写在 assets/ui/theme_rust.tres（项目默认主题）里，这里只提供
## “按主题变体造节点”的快捷方式和主题表达不了的东西（贴图路径、粒子）。
## 界面脚本不应再出现 add_theme_*_override —— 需要新样式就去加主题变体。

const THEME_PATH := "res://assets/ui/theme_rust.tres"

const TEX_TITLE_LOGO := "res://assets/ui/title_logo.png"
const TEX_DIVIDER := "res://assets/ui/divider.png"
const TEX_CORNER := "res://assets/ui/corner_bracket.png"
const TEX_CURSOR := "res://assets/ui/cursor_spike.png"
const TEX_HEART_SLOT := "res://assets/ui/heart_slot.png"
const TEX_VIGNETTE := "res://assets/ui/vignette_blood.png"
const TEX_BAND := "res://assets/ui/band_edge.png"

## 余烬帧表：由 CC0 的 CodeManu 火焰帧在 tools/gen_ui_kit.py 里蒸馏成 6x6 像素，
## 因此只能以整数倍缩放绘制 —— 非整数倍会让 6px 的粒子直接糊成一团。
const TEX_EMBER_MOTES := "res://assets/ui/ember_motes.png"
const MOTE_FRAMES := 8

## 代码侧需要的颜色（tint / 呼吸），与主题里的文字色同源。
const EMBER := Color("#FFC14A")
const EMBER_ASH := Color("#E8B090")
const RUST_MID := Color("#A0522D")
const ASH := Color("#8A8680")
const SCRIM := Color(0.02, 0.01, 0.03)


static func tex(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


## 主题变体标签。variation 为空则用 Label 基础样式。
static func label(text: String, variation: StringName = &"",
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if variation != &"":
		l.theme_type_variation = variation
	return l


static func panel(variation: StringName = &"") -> PanelContainer:
	var p := PanelContainer.new()
	if variation != &"":
		p.theme_type_variation = variation
	return p


## 像素贴图矩形：统一关掉过滤，避免 9-slice 之外的散件被插值糊掉。
static func sprite_rect(path: String) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex(path)
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.stretch_mode = TextureRect.STRETCH_KEEP
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## 装饰横线。放进容器里也不会被拉伸变形（自然尺寸居中绘制）。
static func divider() -> TextureRect:
	var r := sprite_rect(TEX_DIVIDER)
	r.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	var art := r.texture
	if art != null:
		r.custom_minimum_size = art.get_size()
	return r


## 四角哥特花饰。inset 为距边缘的像素数，bottom_inset 可单独避开底部装饰带。
static func corner_brackets(parent: Control, inset: float = 10.0,
		bottom_inset: float = -1.0) -> void:
	var art := tex(TEX_CORNER)
	if art == null:
		return
	if bottom_inset < 0.0:
		bottom_inset = inset
	for i in 4:
		var r := TextureRect.new()
		r.texture = art
		r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.flip_h = i % 2 == 1
		r.flip_v = i >= 2
		r.anchor_left = 1.0 if r.flip_h else 0.0
		r.anchor_right = r.anchor_left
		r.anchor_top = 1.0 if r.flip_v else 0.0
		r.anchor_bottom = r.anchor_top
		var w := float(art.get_width())
		var h := float(art.get_height())
		r.offset_left = -(w + inset) if r.flip_h else inset
		r.offset_right = r.offset_left + w
		r.offset_top = -(h + bottom_inset) if r.flip_v else inset
		r.offset_bottom = r.offset_top + h
		r.modulate = Color(1, 1, 1, 0.85)
		parent.add_child(r)


## 竖向渐变遮罩：给 keyart 压暗上下两端，让标题与菜单文字站得住。
## 用渐变贴图而不是纯色块，避免出现生硬的色带边缘。
static func scrim(top: float, mid: float, bottom: float) -> TextureRect:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.42, 0.62, 1.0])
	grad.colors = PackedColorArray([
		Color(SCRIM.r, SCRIM.g, SCRIM.b, top),
		Color(SCRIM.r, SCRIM.g, SCRIM.b, mid),
		Color(SCRIM.r, SCRIM.g, SCRIM.b, mid),
		Color(SCRIM.r, SCRIM.g, SCRIM.b, bottom),
	])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.width = 4
	gt.height = 256
	gt.fill_from = Vector2(0.0, 0.0)
	gt.fill_to = Vector2(0.0, 1.0)
	var r := TextureRect.new()
	r.texture = gt
	r.stretch_mode = TextureRect.STRETCH_SCALE
	# 渐变要平滑，这一层是唯一允许线性过滤的 UI 贴图。
	r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## 一片余烬：6x6 的蒸馏帧，随机上升或飘落。UI 层用，不参与玩法。
class EmberMote extends Sprite2D:
	const FRAME_STEP := 0.11

	var _bounds := Rect2(Vector2.ZERO, Vector2(1280, 720))
	var _drift := Vector2.ZERO
	var _sway_amp := 8.0
	var _sway_freq := 1.4
	var _phase := 0.0
	var _age := 0.0
	var _frame0 := 0

	func setup(sheet: Texture2D, bounds: Rect2, falling: bool) -> void:
		_bounds = bounds
		texture = sheet
		hframes = UiKit.MOTE_FRAMES
		vframes = 1
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_frame0 = randi_range(0, UiKit.MOTE_FRAMES - 1)
		frame = _frame0
		_phase = randf() * TAU
		_sway_amp = randf_range(5.0, 16.0)
		_sway_freq = randf_range(0.8, 2.0)
		# 只允许整数倍缩放：远处的一格，近处的两格。
		var zoom := 1 if randf() < 0.65 else 2
		scale = Vector2(zoom, zoom)
		if falling:
			_drift = Vector2(0.0, randf_range(9.0, 24.0))
			modulate = UiKit.ASH.lerp(UiKit.EMBER_ASH, randf() * 0.5)
			modulate.a = randf_range(0.30, 0.55)
		else:
			_drift = Vector2(0.0, -randf_range(18.0, 48.0))
			modulate = UiKit.EMBER.lerp(UiKit.RUST_MID, randf() * 0.6)
			modulate.a = randf_range(0.55, 1.0)
		position = Vector2(randf_range(_bounds.position.x, _bounds.end.x),
				randf_range(_bounds.position.y, _bounds.end.y))

	func _process(delta: float) -> void:
		_age += delta
		position += _drift * delta
		position.x += sin(_age * _sway_freq + _phase) * _sway_amp * delta
		frame = (_frame0 + int(_age / FRAME_STEP)) % UiKit.MOTE_FRAMES
		# 出界后从对侧重新入场，保持恒定密度。
		if _drift.y < 0.0 and position.y < _bounds.position.y - 8.0:
			position = Vector2(randf_range(_bounds.position.x, _bounds.end.x), _bounds.end.y + 6.0)
		elif _drift.y > 0.0 and position.y > _bounds.end.y + 8.0:
			position = Vector2(randf_range(_bounds.position.x, _bounds.end.x), _bounds.position.y - 6.0)


## 余烬粒子层。挂在界面根节点上；headless 或缺帧表时自动退化为空层。
class EmberField extends Node2D:
	static func build(bounds: Rect2, rising: int, falling: int) -> EmberField:
		var field := EmberField.new()
		field.name = "EmberField"
		var sheet := UiKit.tex(UiKit.TEX_EMBER_MOTES)
		if sheet == null or DisplayServer.get_name() == "headless":
			return field
		for i in rising + falling:
			var mote := EmberMote.new()
			field.add_child(mote)
			mote.setup(sheet, bounds, i >= rising)
		return field
