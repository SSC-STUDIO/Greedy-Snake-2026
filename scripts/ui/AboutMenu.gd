extends Control

signal menu_requested

const NeonAssetsData := preload("res://scripts/ui/NeonAssets.gd")
const UiMotion := preload("res://scripts/ui/UiAnimations.gd")
const ABOUT_BACKGROUND_TEXTURE := preload("res://assets/generated/obsidian_ui/about_background.png")
const UiThemeData := preload("res://scripts/ui/UiTheme.gd")

const TITLE_COLOR := Color(0.9, 1.0, 0.82)
const MUTED_COLOR := Color(0.7, 0.82, 0.62)

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
	title.text = LocaleText.t("about.title")
	UiThemeData.apply_font(title)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	layout.add_child(title)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 32)
	layout.add_child(body)

	var icon := TextureRect.new()
	icon.texture = NeonAssetsData.BRAND_HEAD_AI
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
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
	UiThemeData.apply_font(name)
	name.add_theme_font_size_override("font_size", 30)
	name.add_theme_color_override("font_color", TITLE_COLOR)
	info.add_child(name)

	info.add_child(_info_row(LocaleText.t("about.edition"), LocaleText.t("about.edition_value")))
	info.add_child(_info_row(LocaleText.t("about.engine"), "Godot 4.6"))
	info.add_child(_info_row(LocaleText.t("about.build"), "2026.05.02"))
	info.add_child(_info_row(LocaleText.t("about.visual_pack"), LocaleText.t("about.visual_pack_value")))
	info.add_child(_info_row(LocaleText.t("about.habitat"), LocaleText.t("about.habitat_value")))
	info.add_child(_info_row(LocaleText.t("about.mission"), LocaleText.t("about.mission_value")))

	var note := Label.new()
	note.text = LocaleText.t("about.note")
	UiThemeData.apply_font(note)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 16)
	note.add_theme_color_override("font_color", MUTED_COLOR)
	info.add_child(note)

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	layout.add_child(bottom)

	var back := Button.new()
	UiThemeData.apply_button_font(back)
	back.text = LocaleText.t("settings.back")
	back.custom_minimum_size = Vector2(148, 46)
	back.add_theme_font_size_override("font_size", 18)
	back.add_theme_color_override("font_color", Color(0.94, 1.0, 0.84))
	back.add_theme_color_override("font_hover_color", Color.WHITE)
	back.add_theme_stylebox_override("normal", _button_style(Color(0.18, 0.38, 0.14).darkened(0.12), Color(0.84, 1.0, 0.52, 0.22)))
	back.add_theme_stylebox_override("hover", _button_style(Color(0.18, 0.38, 0.14).lightened(0.1), Color(0.9, 1.0, 0.62, 0.5)))
	back.add_theme_stylebox_override("pressed", _button_style(Color(0.18, 0.38, 0.14).darkened(0.22), Color(1.0, 0.78, 0.38, 0.72)))
	UiMotion.bind_button_motion(back)
	back.pressed.connect(func() -> void:
		AudioBus.play_button()
		menu_requested.emit()
	)
	bottom.add_child(back)

func _add_background() -> void:
	var background := TextureRect.new()
	background.texture = ABOUT_BACKGROUND_TEXTURE
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.014, 0.006, 0.76)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

func _info_row(label_text: String, value_text: String) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(1, 30)
	row.add_theme_constant_override("separation", 18)

	var label := Label.new()
	UiThemeData.apply_font(label)
	label.text = label_text
	label.custom_minimum_size = Vector2(130, 1)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.72, 1.0, 0.46))
	row.add_child(label)

	var value := Label.new()
	UiThemeData.apply_font(value)
	value.text = value_text
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.add_theme_font_size_override("font_size", 17)
	value.add_theme_color_override("font_color", Color(0.88, 0.96, 0.82))
	row.add_child(value)
	return row

func _panel_style() -> StyleBoxTexture:
	return UiThemeData.textured_panel_style(Color(0.022, 0.05, 0.024, 0.78), Color(0.72, 0.92, 0.42, 0.3), 10)

func _button_style(fill: Color, border: Color) -> StyleBoxTexture:
	return UiThemeData.textured_button_style(fill, border, 12)
