extends Control

class MiniMapView:
	extends Control

	const MAX_FOOD_FOR_ALPHA := 5660.0

	var world_rect := Rect2()
	var player_position := Vector2.ZERO
	var ai_positions: Array = []
	var terrain_regions: Array = []
	var food_count := 0

	func _ready() -> void:
		custom_minimum_size = Vector2(164, 112)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func update_map(snapshot: Dictionary) -> void:
		match SettingsStore.minimap_size:
			0:
				custom_minimum_size = Vector2(132, 92)
			2:
				custom_minimum_size = Vector2(218, 148)
			_:
				custom_minimum_size = Vector2(164, 112)
		world_rect = snapshot.get("world_rect", Rect2())
		player_position = snapshot.get("player_position", Vector2.ZERO)
		ai_positions = snapshot.get("ai_positions", [])
		terrain_regions = snapshot.get("terrain_regions", [])
		food_count = int(snapshot.get("food_count", 0))
		queue_redraw()

	func _draw() -> void:
		var bounds := Rect2(Vector2.ZERO, size)
		draw_rect(bounds, Color(0.02, 0.045, 0.05, 0.84), true)
		draw_rect(bounds, Color(0.25, 0.48, 0.42, 0.65), false, 1.0)
		if world_rect.size.x <= 0.0 or world_rect.size.y <= 0.0:
			return
		for raw_region in terrain_regions:
			var region: Dictionary = raw_region
			var region_rect: Rect2 = region.get("rect", Rect2())
			var region_color: Color = region.get("color", Color(0.16, 0.5, 0.34, 0.18))
			draw_rect(_world_rect_to_map(region_rect), Color(region_color.r, region_color.g, region_color.b, 0.24), true)
		var food_alpha := clampf(float(food_count) / MAX_FOOD_FOR_ALPHA, 0.08, 0.35)
		draw_rect(bounds.grow(-6), Color(0.28, 0.86, 0.48, food_alpha), true)
		for ai_position in ai_positions:
			draw_circle(_world_to_map(ai_position), 2.2, Color(0.96, 0.36, 0.28))
		draw_circle(_world_to_map(player_position), 3.6, Color(0.2, 1.0, 0.58))

	func _world_to_map(position: Vector2) -> Vector2:
		var normalized := Vector2(
			(position.x - world_rect.position.x) / world_rect.size.x,
			(position.y - world_rect.position.y) / world_rect.size.y
		)
		return Vector2(
			clampf(normalized.x, 0.0, 1.0) * size.x,
			clampf(normalized.y, 0.0, 1.0) * size.y
		)

	func _world_rect_to_map(rect: Rect2) -> Rect2:
		var top_left := _world_to_map(rect.position)
		var bottom_right := _world_to_map(rect.position + rect.size)
		return Rect2(top_left, bottom_right - top_left)

var _score_label: Label
var _status_label: Label
var _combo_label: Label
var _terrain_label: Label
var _wave_label: Label
var _build_label: Label
var _event_label: Label
var _lava_label: Label
var _ai_label: Label
var _pause_label: Label
var _right_panel: PanelContainer
var _mini_map: MiniMapView

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()

func update_snapshot(snapshot: Dictionary) -> void:
	if _score_label == null:
		return
	_set_label_text(_score_label, "Score  %d" % int(snapshot.get("score", 0)))
	_set_label_text(_ai_label, "AI  %d/%d" % [int(snapshot.get("ai_alive", 0)), int(snapshot.get("ai_total", 0))])
	_set_label_text(_wave_label, "Wave  %d  %.0f%%" % [int(snapshot.get("wave", 1)), float(snapshot.get("pressure", 1.0)) * 100.0])
	_set_label_text(_terrain_label, String(snapshot.get("terrain_name", "Unknown Sector")))
	var terrain_color: Color = snapshot.get("terrain_color", Color(0.66, 1.0, 0.8))
	_terrain_label.add_theme_color_override("font_color", Color(terrain_color.r, terrain_color.g, terrain_color.b, 0.95))
	_set_label_text(_combo_label, "Combo  x%d  %.1fs" % [int(snapshot.get("combo", 0)), float(snapshot.get("combo_time", 0.0))])
	var tags: Array = snapshot.get("build_tags", [])
	_set_label_text(_build_label, "Build  %s" % (", ".join(tags) if not tags.is_empty() else "none"))
	var event_text := String(snapshot.get("event_text", ""))
	_event_label.visible = event_text != ""
	_set_label_text(_event_label, event_text)

	var boost_text := "Boost" if bool(snapshot.get("boosting", false)) else "Cruise"
	if bool(snapshot.get("invulnerable", false)):
		_set_label_text(_status_label, "%s  Shield %.1fs" % [boost_text, float(snapshot.get("invulnerability_time", 0.0))])
	else:
		_set_label_text(_status_label, boost_text)

	if bool(snapshot.get("in_lava", false)):
		_lava_label.visible = true
		_set_label_text(_lava_label, "Lava  %.1fs" % float(snapshot.get("lava_time", 0.0)))
	else:
		_lava_label.visible = false

	_pause_label.visible = bool(snapshot.get("paused", false))
	_right_panel.visible = SettingsStore.minimap_on
	if _right_panel.visible:
		_mini_map.update_map(snapshot)

func _build() -> void:
	var top := MarginContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 128
	top.add_theme_constant_override("margin_left", 18)
	top.add_theme_constant_override("margin_right", 18)
	top.add_theme_constant_override("margin_top", 14)
	add_child(top)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	top.add_child(row)

	var left_panel := _make_panel(Vector2(244, 112))
	row.add_child(left_panel)

	var left_margin := MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", 14)
	left_margin.add_theme_constant_override("margin_right", 14)
	left_margin.add_theme_constant_override("margin_top", 10)
	left_margin.add_theme_constant_override("margin_bottom", 10)
	left_panel.add_child(left_margin)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 4)
	left_margin.add_child(left)

	_score_label = _make_label("Score  0", 24, Color(0.88, 1.0, 0.92))
	left.add_child(_score_label)
	_status_label = _make_label("Cruise", 15, Color(0.62, 0.82, 0.76))
	left.add_child(_status_label)
	_combo_label = _make_label("Combo  x0", 15, Color(0.88, 0.95, 0.62))
	left.add_child(_combo_label)
	_lava_label = _make_label("Lava", 17, Color(1.0, 0.42, 0.24))
	_lava_label.visible = false
	left.add_child(_lava_label)

	var filler := Control.new()
	filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(filler)

	_right_panel = _make_panel(Vector2(228, 218))
	row.add_child(_right_panel)

	var right_margin := MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", 12)
	right_margin.add_theme_constant_override("margin_right", 12)
	right_margin.add_theme_constant_override("margin_top", 10)
	right_margin.add_theme_constant_override("margin_bottom", 12)
	_right_panel.add_child(right_margin)

	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_BEGIN
	right.add_theme_constant_override("separation", 6)
	right_margin.add_child(right)
	_ai_label = _make_label("AI  0/0", 17, Color(0.82, 0.9, 0.86))
	_ai_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(_ai_label)
	_wave_label = _make_label("Wave  1", 16, Color(0.66, 1.0, 0.8))
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(_wave_label)
	_terrain_label = _make_label("Unknown Sector", 15, Color(0.62, 0.9, 0.78))
	_terrain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(_terrain_label)
	_mini_map = MiniMapView.new()
	right.add_child(_mini_map)
	_build_label = _make_label("Build  none", 13, Color(0.62, 0.76, 0.71))
	_build_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_build_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_build_label)

	_event_label = _make_label("", 28, Color(0.94, 1.0, 0.78))
	_event_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_event_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_event_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_event_label.offset_left = -260
	_event_label.offset_right = 260
	_event_label.offset_top = 96
	_event_label.offset_bottom = 136
	_event_label.visible = false
	add_child(_event_label)

	_pause_label = _make_label("Paused", 26, Color(0.86, 1.0, 0.92))
	_pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_pause_label.set_anchors_preset(Control.PRESET_CENTER)
	_pause_label.offset_left = -90
	_pause_label.offset_right = 90
	_pause_label.offset_top = -24
	_pause_label.offset_bottom = 24
	_pause_label.visible = false
	add_child(_pause_label)

func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _set_label_text(label: Label, value: String) -> void:
	if label.text != value:
		label.text = value

func _make_panel(minimum_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.045, 0.047, 0.74)
	style.border_color = Color(0.35, 0.86, 0.62, 0.28)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	return panel
