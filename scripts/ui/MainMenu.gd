extends Control

signal start_game_requested
signal settings_requested
signal about_requested
signal quit_requested

const GameConfigData := preload("res://scripts/data/GameConfig.gd")
const NeonAssetsData := preload("res://scripts/ui/NeonAssets.gd")
const MENU_BACKGROUND_TEXTURE := preload("res://assets/generated/obsidian_ui/menu_background.png")
const Responsive := preload("res://scripts/ui/ResponsiveLayout.gd")
const UiMotion := preload("res://scripts/ui/UiAnimations.gd")
const UiThemeData := preload("res://scripts/ui/UiTheme.gd")

const TITLE_COLOR := Color(0.9, 1.0, 0.82)
const MUTED_COLOR := Color(0.68, 0.82, 0.62)
const ACCENT_COLOR := Color(0.38, 0.72, 0.28)
const PANEL_COLOR := Color(0.022, 0.045, 0.024, 0.76)
const OUTLINE_COLOR := Color(0.72, 0.9, 0.42, 0.3)

func _ready() -> void:
	Responsive.update_scale()
	_build()
	_play_intro()

func _build() -> void:
	_add_background()

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 54)
	margin.add_theme_constant_override("margin_right", 54)
	margin.add_theme_constant_override("margin_top", 42)
	margin.add_theme_constant_override("margin_bottom", 34)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)

	layout.add_child(_build_top_bar())

	var hero := HBoxContainer.new()
	hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero.alignment = BoxContainer.ALIGNMENT_CENTER
	hero.add_theme_constant_override("separation", 42)
	layout.add_child(hero)

	var brand := _build_brand_column()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero.add_child(brand)

	var commands := _build_command_column()
	commands.size_flags_horizontal = Control.SIZE_SHRINK_END
	hero.add_child(commands)

	layout.add_child(_build_bottom_bar())

func _add_background() -> void:
	var background := TextureRect.new()
	background.texture = MENU_BACKGROUND_TEXTURE
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.012, 0.006, 0.4)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var vignette := ColorRect.new()
	vignette.color = Color(0.0, 0.0, 0.0, 0.2)
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.offset_left = 0
	add_child(vignette)

	var scanline := ColorRect.new()
	scanline.color = Color(0.76, 1.0, 0.42, 0.055)
	scanline.set_anchors_preset(Control.PRESET_TOP_WIDE)
	scanline.offset_top = 82
	scanline.offset_bottom = 84
	add_child(scanline)

func _build_top_bar() -> Control:
	var bar := HBoxContainer.new()
	bar.custom_minimum_size = Vector2(1, 62)
	bar.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = LocaleText.t("menu.sector")
	UiThemeData.apply_font(label)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.78, 0.96, 0.66))
	bar.add_child(label)

	var line := ColorRect.new()
	line.color = Color(0.78, 1.0, 0.36, 0.24)
	line.custom_minimum_size = Vector2(1, 2)
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(line)

	bar.add_child(_make_icon_button(LocaleText.t("menu.settings"), NeonAssetsData.SETTINGS_ICON, Color(0.12, 0.24, 0.14), func() -> void:
		AudioBus.play_button()
		settings_requested.emit()
	))
	bar.add_child(_make_icon_button(LocaleText.t("menu.quit"), NeonAssetsData.QUIT_ICON, Color(0.32, 0.12, 0.06), func() -> void:
		AudioBus.play_button()
		quit_requested.emit()
	))
	return bar

func _build_brand_column() -> Control:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)

	var icon := TextureRect.new()
	icon.texture = NeonAssetsData.BRAND_HEAD_AI
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(270, 270)
	box.add_child(icon)

	var title := Label.new()
	title.text = LocaleText.t("menu.title")
	UiThemeData.apply_font(title)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 58)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = LocaleText.t("menu.subtitle")
	UiThemeData.apply_font(subtitle)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", MUTED_COLOR)
	box.add_child(subtitle)

	var telemetry := Label.new()
	telemetry.text = LocaleText.format("menu.telemetry", [RunRecords.daily_seed()])
	UiThemeData.apply_font(telemetry)
	telemetry.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	telemetry.add_theme_font_size_override("font_size", 13)
	telemetry.add_theme_color_override("font_color", Color(0.66, 0.96, 0.46, 0.72))
	box.add_child(telemetry)

	return box

func _build_command_column() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(362, 438)
	panel.add_theme_stylebox_override("panel", _panel_style())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var eyebrow := Label.new()
	eyebrow.text = LocaleText.t("menu.eyebrow")
	UiThemeData.apply_font(eyebrow)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 15)
	eyebrow.add_theme_color_override("font_color", Color(0.78, 1.0, 0.52))
	box.add_child(eyebrow)

	var start_button := _make_button(LocaleText.t("menu.start"), ACCENT_COLOR, 68, 25)
	start_button.pressed.connect(func() -> void:
		AudioBus.play_button()
		start_game_requested.emit()
	)
	box.add_child(start_button)

	var settings_button := _make_button(LocaleText.t("menu.settings"), Color(0.2, 0.38, 0.16), 52, 19)
	settings_button.pressed.connect(func() -> void:
		AudioBus.play_button()
		settings_requested.emit()
	)
	box.add_child(settings_button)

	var about_button := _make_button(LocaleText.t("menu.about"), Color(0.18, 0.28, 0.12), 46, 18)
	about_button.pressed.connect(func() -> void:
		AudioBus.play_button()
		about_requested.emit()
	)
	box.add_child(about_button)

	var divider := ColorRect.new()
	divider.color = Color(0.78, 1.0, 0.46, 0.24)
	divider.custom_minimum_size = Vector2(1, 2)
	box.add_child(divider)

	var meta := GridContainer.new()
	meta.columns = 2
	meta.add_theme_constant_override("h_separation", 8)
	meta.add_theme_constant_override("v_separation", 8)
	box.add_child(meta)
	meta.add_child(_make_stat(LocaleText.t("menu.difficulty"), String(LocaleText.difficulty_labels()[SettingsStore.difficulty])))
	meta.add_child(_make_stat(LocaleText.t("menu.speed"), String(LocaleText.speed_labels()[SettingsStore.snake_speed])))
	meta.add_child(_make_stat(LocaleText.t("menu.best"), str(RunRecords.get_best_score())))
	meta.add_child(_make_stat(LocaleText.t("menu.seed"), str(RunRecords.daily_seed())))

	return panel

func _build_bottom_bar() -> Control:
	var bar := HBoxContainer.new()
	bar.custom_minimum_size = Vector2(1, 46)
	bar.add_theme_constant_override("separation", 10)

	bar.add_child(_make_chip(String(LocaleText.difficulty_labels()[SettingsStore.difficulty])))
	bar.add_child(_make_chip(String(LocaleText.speed_labels()[SettingsStore.snake_speed])))
	bar.add_child(_make_chip("%s %d" % [LocaleText.t("menu.best"), RunRecords.get_best_score()]))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	var build := Label.new()
	build.text = "2026"
	UiThemeData.apply_font(build)
	build.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	build.add_theme_font_size_override("font_size", 14)
	build.add_theme_color_override("font_color", Color(0.56, 0.66, 0.62))
	bar.add_child(build)
	return bar

func _make_button(text: String, color: Color, height: int, font_size: int) -> Button:
	var button := Button.new()
	UiThemeData.apply_button_font(button)
	button.text = text
	button.custom_minimum_size = Responsive.scale_vector(Vector2(292, height))
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", Responsive.scale_font(font_size))
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(color.darkened(0.18), Color(0.9, 1.0, 0.96, 0.22)))
	button.add_theme_stylebox_override("hover", _button_style(color.lightened(0.06), Color(0.9, 1.0, 0.96, 0.55)))
	button.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.24), Color(1.0, 0.8, 0.42, 0.72)))
	button.add_theme_stylebox_override("focus", _button_style(color.lightened(0.08), Color(0.9, 1.0, 0.96, 0.78)))
	UiMotion.bind_button_motion(button, Vector2(1.026, 1.035), Vector2(0.965, 0.94))
	return button

func _make_icon_button(label: String, texture: Texture2D, color: Color, callback: Callable) -> Button:
	var button := Button.new()
	UiThemeData.apply_button_font(button)
	button.tooltip_text = label
	button.icon = texture
	button.expand_icon = true
	button.custom_minimum_size = Vector2(58, 58)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_constant_override("icon_max_width", 46)
	button.add_theme_stylebox_override("normal", _icon_button_style(color, Color(0.9, 1.0, 0.96, 0.16)))
	button.add_theme_stylebox_override("hover", _icon_button_style(color.lightened(0.08), Color(0.9, 1.0, 0.96, 0.46)))
	button.add_theme_stylebox_override("pressed", _icon_button_style(color.darkened(0.16), Color(0.9, 1.0, 0.96, 0.62)))
	button.add_theme_stylebox_override("focus", _icon_button_style(color, Color(0.9, 1.0, 0.96, 0.72)))
	UiMotion.bind_button_motion(button, Vector2(1.08, 1.08), Vector2(0.94, 0.94))
	button.pressed.connect(callback)
	return button

func _make_stat(label_text: String, value_text: String) -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(132, 54)
	box.add_theme_constant_override("separation", 0)

	var label := Label.new()
	UiThemeData.apply_font(label)
	label.text = label_text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.52, 0.68, 0.62))
	box.add_child(label)

	var value := Label.new()
	UiThemeData.apply_font(value)
	value.text = value_text
	value.add_theme_font_size_override("font_size", 18)
	value.add_theme_color_override("font_color", Color(0.86, 1.0, 0.92))
	box.add_child(value)
	return box

func _make_chip(text: String) -> Label:
	var chip := Label.new()
	UiThemeData.apply_font(chip)
	chip.text = text
	chip.custom_minimum_size = Vector2(96, 34)
	chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.add_theme_font_size_override("font_size", 14)
	chip.add_theme_color_override("font_color", Color(0.75, 0.92, 0.84))
	chip.add_theme_stylebox_override("normal", _chip_style())
	return chip

func _panel_style() -> StyleBoxTexture:
	var style := UiThemeData.textured_panel_style(PANEL_COLOR, OUTLINE_COLOR, 18)
	return style

func _button_style(fill: Color, border: Color) -> StyleBoxTexture:
	var style := UiThemeData.textured_button_style(fill, border, 14)
	style.content_margin_left = 22
	style.content_margin_right = 22
	return style

func _icon_button_style(fill: Color, border: Color) -> StyleBoxTexture:
	var style := _button_style(fill, border)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _chip_style() -> StyleBoxTexture:
	return UiThemeData.textured_panel_style(Color(0.025, 0.07, 0.035, 0.72), Color(0.72, 0.92, 0.42, 0.34), 12)

func _play_intro() -> void:
	if not SettingsStore.animations_on:
		return
	modulate.a = 0.0
	scale = Vector2(0.988, 0.988)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.52).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
