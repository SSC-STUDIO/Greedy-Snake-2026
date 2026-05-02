extends RefCounted
class_name UiTheme

const CJK_FONT := preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
const PANEL_TEXTURE := preload("res://assets/generated/obsidian_ui/panel_texture.png")

static func apply_font(label: Control) -> void:
	label.add_theme_font_override("font", CJK_FONT)

static func label(text: String, font_size: int, color: Color) -> Label:
	var node := Label.new()
	node.text = text
	apply_font(node)
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	return node

static func apply_button_font(button: Button) -> void:
	apply_font(button)

static func textured_panel_style(fill: Color, border: Color, corner_radius := 14) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = PANEL_TEXTURE
	style.modulate_color = fill
	style.draw_center = true
	style.texture_margin_left = 18
	style.texture_margin_top = 18
	style.texture_margin_right = 18
	style.texture_margin_bottom = 18
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

static func textured_button_style(fill: Color, border: Color, corner_radius := 12) -> StyleBoxTexture:
	var style := textured_panel_style(fill, border, corner_radius)
	style.texture_margin_left = 14
	style.texture_margin_top = 14
	style.texture_margin_right = 14
	style.texture_margin_bottom = 14
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
