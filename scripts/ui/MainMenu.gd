extends Control

signal start_game_requested
signal settings_requested
signal about_requested
signal quit_requested

const GameConfigData := preload("res://scripts/data/GameConfig.gd")
const NeonAssetsData := preload("res://scripts/ui/NeonAssets.gd")

const TITLE_COLOR := Color(0.88, 1.0, 0.92)
const MUTED_COLOR := Color(0.62, 0.76, 0.71)
const ACCENT_COLOR := Color(0.18, 0.9, 0.5)
const PANEL_COLOR := Color(0.018, 0.045, 0.047, 0.72)
const OUTLINE_COLOR := Color(0.42, 0.95, 0.7, 0.28)

func _ready() -> void:
	_build()

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
	background.texture = NeonAssetsData.atlas_texture(NeonAssetsData.MENU_BACKGROUNDS, NeonAssetsData.MAIN_MENU_BG)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.016, 0.018, 0.54)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var vignette := ColorRect.new()
	vignette.color = Color(0.0, 0.0, 0.0, 0.18)
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.offset_left = 0
	add_child(vignette)

func _build_top_bar() -> Control:
	var bar := HBoxContainer.new()
	bar.custom_minimum_size = Vector2(1, 62)
	bar.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = "SECTOR A-01"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.68, 0.9, 0.8))
	bar.add_child(label)

	var line := Control.new()
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(line)

	bar.add_child(_make_icon_button("Settings", NeonAssetsData.SETTINGS_ICON, Color(0.08, 0.3, 0.35), func() -> void:
		AudioBus.play_button()
		settings_requested.emit()
	))
	bar.add_child(_make_icon_button("Quit", NeonAssetsData.QUIT_ICON, Color(0.42, 0.11, 0.08), func() -> void:
		AudioBus.play_button()
		quit_requested.emit()
	))
	return bar

func _build_brand_column() -> Control:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)

	var icon := TextureRect.new()
	icon.texture = NeonAssetsData.BRAND_ICON
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(250, 250)
	box.add_child(icon)

	var title := Label.new()
	title.text = "GREEDY\nSNAKE 2026"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 58)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Neon Ecology Containment Run"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", MUTED_COLOR)
	box.add_child(subtitle)

	return box

func _build_command_column() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(340, 414)
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
	eyebrow.text = "READY"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 15)
	eyebrow.add_theme_color_override("font_color", Color(0.54, 1.0, 0.72))
	box.add_child(eyebrow)

	var start_button := _make_button("Start Next Run", ACCENT_COLOR, 68, 25)
	start_button.pressed.connect(func() -> void:
		AudioBus.play_button()
		start_game_requested.emit()
	)
	box.add_child(start_button)

	var settings_button := _make_button("Settings", Color(0.12, 0.44, 0.5), 52, 19)
	settings_button.pressed.connect(func() -> void:
		AudioBus.play_button()
		settings_requested.emit()
	)
	box.add_child(settings_button)

	var about_button := _make_button("About", Color(0.1, 0.32, 0.36), 46, 18)
	about_button.pressed.connect(func() -> void:
		AudioBus.play_button()
		about_requested.emit()
	)
	box.add_child(about_button)

	var divider := ColorRect.new()
	divider.color = Color(0.6, 1.0, 0.78, 0.16)
	divider.custom_minimum_size = Vector2(1, 1)
	box.add_child(divider)

	var meta := GridContainer.new()
	meta.columns = 2
	meta.add_theme_constant_override("h_separation", 8)
	meta.add_theme_constant_override("v_separation", 8)
	box.add_child(meta)
	meta.add_child(_make_stat("Difficulty", String(GameConfigData.DIFFICULTY_LABELS[SettingsStore.difficulty])))
	meta.add_child(_make_stat("Speed", String(GameConfigData.SPEED_LABELS[SettingsStore.snake_speed])))
	meta.add_child(_make_stat("Best", str(RunRecords.get_best_score())))
	meta.add_child(_make_stat("Seed", str(RunRecords.daily_seed())))

	return panel

func _build_bottom_bar() -> Control:
	var bar := HBoxContainer.new()
	bar.custom_minimum_size = Vector2(1, 46)
	bar.add_theme_constant_override("separation", 10)

	bar.add_child(_make_chip("Normal" if SettingsStore.difficulty == 1 else String(GameConfigData.DIFFICULTY_LABELS[SettingsStore.difficulty])))
	bar.add_child(_make_chip(String(GameConfigData.SPEED_LABELS[SettingsStore.snake_speed])))
	bar.add_child(_make_chip("Best %d" % RunRecords.get_best_score()))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	var build := Label.new()
	build.text = "2026"
	build.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	build.add_theme_font_size_override("font_size", 14)
	build.add_theme_color_override("font_color", Color(0.56, 0.66, 0.62))
	bar.add_child(build)
	return bar

func _make_button(text: String, color: Color, height: int, font_size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(292, height)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(color.darkened(0.12), Color(0.9, 1.0, 0.96, 0.18)))
	button.add_theme_stylebox_override("hover", _button_style(color, Color(0.9, 1.0, 0.96, 0.44)))
	button.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.18), Color(0.9, 1.0, 0.96, 0.62)))
	button.add_theme_stylebox_override("focus", _button_style(color, Color(0.9, 1.0, 0.96, 0.72)))

	# 添加按下动画
	button.button_down.connect(func() -> void:
		if SettingsStore.animations_on:
			var tween := button.create_tween()
			tween.tween_property(button, "scale", Vector2(0.96, 0.96), 0.08)
	)
	button.button_up.connect(func() -> void:
		if SettingsStore.animations_on:
			var tween := button.create_tween()
			tween.tween_property(button, "scale", Vector2.ONE, 0.12)
	)
	return button

func _make_icon_button(label: String, texture: Texture2D, color: Color, callback: Callable) -> Button:
	var button := Button.new()
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
	button.pressed.connect(callback)
	return button

func _make_stat(label_text: String, value_text: String) -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(132, 54)
	box.add_theme_constant_override("separation", 0)

	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.52, 0.68, 0.62))
	box.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 18)
	value.add_theme_color_override("font_color", Color(0.86, 1.0, 0.92))
	box.add_child(value)
	return box

func _make_chip(text: String) -> Label:
	var chip := Label.new()
	chip.text = text
	chip.custom_minimum_size = Vector2(96, 34)
	chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.add_theme_font_size_override("font_size", 14)
	chip.add_theme_color_override("font_color", Color(0.75, 0.92, 0.84))
	chip.add_theme_stylebox_override("normal", _chip_style())
	return chip

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = OUTLINE_COLOR
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	return style

func _icon_button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := _button_style(fill, border)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _chip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.055, 0.052, 0.62)
	style.border_color = Color(0.45, 0.95, 0.7, 0.22)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style
