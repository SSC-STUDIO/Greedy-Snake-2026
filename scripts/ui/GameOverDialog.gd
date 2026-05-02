extends Control

signal restart_requested
signal menu_requested

const UiMotion := preload("res://scripts/ui/UiAnimations.gd")
const DIALOG_BACKGROUND_TEXTURE := preload("res://assets/generated/obsidian_ui/dialog_background.png")
const RunDataUtil := preload("res://scripts/data/RunData.gd")
const UiThemeData := preload("res://scripts/ui/UiTheme.gd")

var _score_label: Label
var _detail_label: Label
var _record_label: Label
var _title_label: Label

func _ready() -> void:
	_build()
	hide()

func show_result(result) -> void:
	var summary := {}
	if result is Dictionary:
		summary = result
	else:
		summary = {"score": int(result)}
	var tags: Array = summary.get("build_tags", [])
	var victory := bool(summary.get("victory", false))
	var title := String(summary.get("title", "Snake Emperor" if victory else "Crown Fallen"))
	_title_label.text = LocaleText.translate_title(title) if victory else LocaleText.t("gameover.fallen")
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.28) if victory else Color(0.96, 0.58, 0.36))
	_score_label.text = LocaleText.format("gameover.score", [int(summary.get("score", 0))])
	var result_label := LocaleText.t("gameover.victory") if victory else LocaleText.format("gameover.death", [LocaleText.translate_death_reason(String(summary.get("death_reason", LocaleText.t("common.unknown"))))])
	_detail_label.text = LocaleText.format("gameover.detail", [
		RunDataUtil.format_duration(float(summary.get("duration", 0.0))),
		int(summary.get("kills", 0)),
		int(summary.get("max_combo", 0)),
		result_label,
		int(summary.get("waves", 1)),
		int(summary.get("followers_alive", 0)),
		int(summary.get("followers_total", 0)),
		int(summary.get("followers_recruited", 0)),
		int(summary.get("drone_count", 0)),
		LocaleText.join_tags(tags),
	])
	var record: Dictionary = summary.get("record", {})
	var record_text := LocaleText.format("gameover.best", [int(record.get("best_score", RunRecords.get_best_score()))])
	if bool(record.get("is_record", false)):
		record_text = LocaleText.format("gameover.new_record", [int(record.get("best_score", 0))])
	elif int(record.get("previous_best", 0)) > 0:
		var gap := int(record.get("previous_best", 0)) - int(summary.get("score", 0))
		if gap > 0:
			record_text = LocaleText.format("gameover.gap", [int(record.get("previous_best", 0)), gap])
	_record_label.text = LocaleText.format("gameover.seed", [record_text, int(summary.get("challenge_seed", RunRecords.daily_seed()))])
	show()

	# 入场动画：淡入+缩放
	if SettingsStore.animations_on:
		modulate.a = 0.0
		scale = Vector2(0.96, 0.9)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "modulate:a", 1.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2.ONE, 0.42).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)

func _build() -> void:
	var background := TextureRect.new()
	background.texture = DIALOG_BACKGROUND_TEXTURE
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.62)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(470, 414)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 26)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	_title_label = Label.new()
	_title_label.text = LocaleText.t("gameover.fallen")
	UiThemeData.apply_font(_title_label)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 34)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.58, 0.46))
	layout.add_child(_title_label)

	var line := ColorRect.new()
	line.color = Color(0.9, 0.64, 0.24, 0.32)
	line.custom_minimum_size = Vector2(1, 2)
	layout.add_child(line)

	_score_label = Label.new()
	_score_label.text = LocaleText.format("gameover.score", [0])
	UiThemeData.apply_font(_score_label)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 24)
	_score_label.add_theme_color_override("font_color", Color(0.9, 1.0, 0.82))
	layout.add_child(_score_label)

	_detail_label = Label.new()
	UiThemeData.apply_font(_detail_label)
	_detail_label.text = ""
	_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_label.add_theme_font_size_override("font_size", 16)
	_detail_label.add_theme_color_override("font_color", Color(0.76, 0.88, 0.68))
	layout.add_child(_detail_label)

	_record_label = Label.new()
	UiThemeData.apply_font(_record_label)
	_record_label.text = ""
	_record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_record_label.add_theme_font_size_override("font_size", 15)
	_record_label.add_theme_color_override("font_color", Color(0.94, 1.0, 0.56))
	layout.add_child(_record_label)

	layout.add_child(_make_button(LocaleText.t("pause.restart"), Callable(self, "_emit_restart")))
	layout.add_child(_make_button(LocaleText.t("pause.menu"), Callable(self, "_emit_menu")))

func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	UiThemeData.apply_button_font(button)
	button.text = text
	button.custom_minimum_size = Vector2(220, 44)
	button.add_theme_font_size_override("font_size", 18)
	_apply_button_style(button, Color(0.56, 0.18, 0.12))
	button.pressed.connect(func() -> void:
		AudioBus.play_button()
		callback.call()
	)
	return button

func _panel_style() -> StyleBoxTexture:
	return UiThemeData.textured_panel_style(Color(0.036, 0.028, 0.018, 0.96), Color(0.94, 0.62, 0.24, 0.62), 18)

func _apply_button_style(button: Button, color: Color) -> void:
	UiThemeData.apply_button_font(button)
	button.add_theme_color_override("font_color", Color(1.0, 0.94, 0.88))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(color.darkened(0.12), Color(1.0, 0.72, 0.42, 0.26)))
	button.add_theme_stylebox_override("hover", _button_style(color.lightened(0.08), Color(1.0, 0.86, 0.58, 0.55)))
	button.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.24), Color(1.0, 0.9, 0.62, 0.72)))
	UiMotion.bind_button_motion(button)

func _button_style(fill: Color, border: Color) -> StyleBoxTexture:
	return UiThemeData.textured_button_style(fill, border, 12)

func _emit_restart() -> void:
	restart_requested.emit()

func _emit_menu() -> void:
	menu_requested.emit()
