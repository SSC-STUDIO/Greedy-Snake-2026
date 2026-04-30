extends Control

signal menu_requested

const NeonAssetsData := preload("res://scripts/ui/NeonAssets.gd")

const TITLE_COLOR := Color(0.88, 1.0, 0.92)
const MUTED_COLOR := Color(0.62, 0.76, 0.71)

func _ready() -> void:
	_build()

func _build() -> void:
	_add_background()

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 68)
	margin.add_theme_constant_override("margin_right", 68)
	margin.add_theme_constant_override("margin_top", 52)
	margin.add_theme_constant_override("margin_bottom", 46)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "About"
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	layout.add_child(title)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 32)
	layout.add_child(body)

	var icon := TextureRect.new()
	icon.texture = NeonAssetsData.BRAND_ICON
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(260, 260)
	body.add_child(icon)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 360)
	panel.add_theme_stylebox_override("panel", _panel_style())
	body.add_child(panel)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 24)
	panel_margin.add_theme_constant_override("margin_right", 24)
	panel_margin.add_theme_constant_override("margin_top", 22)
	panel_margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(panel_margin)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 13)
	panel_margin.add_child(info)

	var name := Label.new()
	name.text = "GREEDY SNAKE 2026"
	name.add_theme_font_size_override("font_size", 30)
	name.add_theme_color_override("font_color", TITLE_COLOR)
	info.add_child(name)

	info.add_child(_info_row("Edition", "Neon Ecology"))
	info.add_child(_info_row("Engine", "Godot 4.6"))
	info.add_child(_info_row("Build", "2026.04.29"))
	info.add_child(_info_row("Visual Pack", "Generated neon ecology atlas"))
	info.add_child(_info_row("Sector", "A-01 containment habitat"))
	info.add_child(_info_row("Mission", "Purge rogue AI growth"))

	var note := Label.new()
	note.text = "A restoration biosnake feeds through Bloom Nursery, Ion Marsh, Glass Reef, and Ember Vein while the sector broadcasts each containment failure."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 16)
	note.add_theme_color_override("font_color", MUTED_COLOR)
	info.add_child(note)

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	layout.add_child(bottom)

	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(148, 46)
	back.add_theme_font_size_override("font_size", 18)
	back.pressed.connect(func() -> void:
		AudioBus.play_button()
		menu_requested.emit()
	)
	bottom.add_child(back)

func _add_background() -> void:
	var background := TextureRect.new()
	background.texture = NeonAssetsData.atlas_texture(NeonAssetsData.MENU_BACKGROUNDS, NeonAssetsData.SETTINGS_BG)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.016, 0.018, 0.78)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

func _info_row(label_text: String, value_text: String) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(1, 30)
	row.add_theme_constant_override("separation", 18)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(130, 1)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.48, 1.0, 0.7))
	row.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.add_theme_font_size_override("font_size", 17)
	value.add_theme_color_override("font_color", Color(0.84, 0.94, 0.9))
	row.add_child(value)
	return row

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.045, 0.047, 0.76)
	style.border_color = Color(0.42, 0.95, 0.7, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style
