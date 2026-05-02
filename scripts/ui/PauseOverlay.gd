extends Control

signal resume_requested
signal restart_requested
signal menu_requested

const UiMotion := preload("res://scripts/ui/UiAnimations.gd")
const DIALOG_BACKGROUND_TEXTURE := preload("res://assets/generated/obsidian_ui/dialog_background.png")
const UiThemeData := preload("res://scripts/ui/UiTheme.gd")

var _build_label: Label
var _stats_label: Label

func _ready() -> void:
	_build()

func set_build_snapshot(snapshot: Dictionary) -> void:
	if _build_label == null:
		return
	var tags: Array = snapshot.get("build_tags", [])
	var upgrades: Array = snapshot.get("upgrade_names", [])
	_build_label.text = LocaleText.format("hud.build", [LocaleText.join_tags(tags)])
	_stats_label.text = LocaleText.format("pause.stats", [
		int(snapshot.get("wave", 1)),
		int(snapshot.get("max_combo", 0)),
		int(snapshot.get("followers_alive", 0)),
		int(snapshot.get("followers_total", 0)),
		int(snapshot.get("followers_recruited", 0)),
		int(snapshot.get("drone_count", 0)),
		", ".join(upgrades.slice(maxi(0, upgrades.size() - 4), upgrades.size())) if not upgrades.is_empty() else LocaleText.t("common.no_upgrades"),
	])

	# 入场动画：淡入+缩放
	if SettingsStore.animations_on and not visible:
		modulate.a = 0.0
		scale = Vector2(0.96, 0.92)
		show()
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2.ONE, 0.34).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	else:
		show()

func _build() -> void:
	var background := TextureRect.new()
	background.texture = DIALOG_BACKGROUND_TEXTURE
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.58)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 352)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var title := Label.new()
	title.text = LocaleText.t("pause.title")
	UiThemeData.apply_font(title)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.9, 1.0, 0.82))
	layout.add_child(title)

	var line := ColorRect.new()
	line.color = Color(0.78, 1.0, 0.42, 0.24)
	line.custom_minimum_size = Vector2(1, 2)
	layout.add_child(line)

	_build_label = Label.new()
	_build_label.text = LocaleText.format("hud.build", [LocaleText.t("common.none")])
	UiThemeData.apply_font(_build_label)
	_build_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_build_label.add_theme_font_size_override("font_size", 16)
	_build_label.add_theme_color_override("font_color", Color(0.78, 1.0, 0.52))
	layout.add_child(_build_label)

	_stats_label = Label.new()
	_stats_label.text = LocaleText.format("pause.stats", [1, 0, 0, 0, 0, 0, LocaleText.t("common.no_upgrades")])
	UiThemeData.apply_font(_stats_label)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stats_label.add_theme_font_size_override("font_size", 14)
	_stats_label.add_theme_color_override("font_color", Color(0.76, 0.86, 0.66))
	layout.add_child(_stats_label)

	layout.add_child(_make_button(LocaleText.t("pause.resume"), Callable(self, "_emit_resume")))
	layout.add_child(_make_button(LocaleText.t("pause.restart"), Callable(self, "_emit_restart")))
	layout.add_child(_make_button(LocaleText.t("pause.menu"), Callable(self, "_emit_menu")))

func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	UiThemeData.apply_button_font(button)
	button.text = text
	button.custom_minimum_size = Vector2(210, 44)
	button.add_theme_font_size_override("font_size", 18)
	_apply_button_style(button, Color(0.18, 0.38, 0.14))
	button.pressed.connect(func() -> void:
		AudioBus.play_button()
		callback.call()
	)
	return button

func _panel_style() -> StyleBoxTexture:
	return UiThemeData.textured_panel_style(Color(0.02, 0.045, 0.022, 0.94), Color(0.72, 0.96, 0.38, 0.52), 18)

func _apply_button_style(button: Button, color: Color) -> void:
	UiThemeData.apply_button_font(button)
	button.add_theme_color_override("font_color", Color(0.94, 1.0, 0.84))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(color.darkened(0.12), Color(0.84, 1.0, 0.52, 0.22)))
	button.add_theme_stylebox_override("hover", _button_style(color.lightened(0.1), Color(0.9, 1.0, 0.62, 0.5)))
	button.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.22), Color(1.0, 0.78, 0.38, 0.72)))
	UiMotion.bind_button_motion(button)

func _button_style(fill: Color, border: Color) -> StyleBoxTexture:
	return UiThemeData.textured_button_style(fill, border, 12)

func _emit_resume() -> void:
	resume_requested.emit()

func _emit_restart() -> void:
	restart_requested.emit()

func _emit_menu() -> void:
	menu_requested.emit()
