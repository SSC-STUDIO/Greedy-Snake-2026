## TerrainHazardRenderer stores terrain hazard cells for collision and Arena drawing.
extends RefCounted
class_name TerrainHazardRenderer

## Set of Vector2i cells that contain hazards (for collision queries)
var hazard_cells: Dictionary = {}  # Vector2i -> { terrain_id, hazard_type, hazard_damage }

## Cell size for hazard grid (should match Arena's visual grid)
const CELL_SIZE: float = 48.0
const SAFE_ZONE_RADIUS: float = 220.0
const CENTER_CORRIDOR_HALF_WIDTH_CELLS: int = 5
const DEFAULT_WALL_SPACING_CELLS: int = 36
const DEFAULT_WALL_BARRICADE_COUNT: int = 32
const MAZE_EDGE_INSET_CELLS: int = 8
const CLUSTER_OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(1, 1),
]

## Generate hazard cells for all terrain regions. Call after terrain is built.
func generate_hazards(terrain_regions: Array, play_area: Rect2, seed_value: int = 12345) -> void:
	hazard_cells.clear()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var safe_center := play_area.get_center()

	for region in terrain_regions:
		var terrain_id: String = region.get("id", "")
		var rect: Rect2 = region.get("rect", Rect2())
		var hazard_type: String = region.get("hazard_type", "none")
		if hazard_type == "none":
			continue
		var density: float = region.get("hazard_density", 0.0)
		var damage: int = region.get("hazard_damage", 0)
		var layout: String = String(region.get("hazard_layout", "cluster"))

		# Convert rect to cell coordinates. floor/ceil keeps negative-world cells aligned.
		var x0: int = floori(rect.position.x / CELL_SIZE)
		var y0: int = floori(rect.position.y / CELL_SIZE)
		var x1: int = ceili((rect.position.x + rect.size.x) / CELL_SIZE)
		var y1: int = ceili((rect.position.y + rect.size.y) / CELL_SIZE)
		var cell_bounds := Rect2i(Vector2i(x0, y0), Vector2i(x1 - x0, y1 - y0))

		if layout == "wall_maze" and hazard_type == "block":
			_generate_wall_maze(region, cell_bounds, safe_center, rng)
			continue

		# Generate hazard cells with clustering (not purely random)
		for cy in range(y0, y1):
			for cx in range(x0, x1):
				if rng.randf() < density:
					var cell: Vector2i = Vector2i(cx, cy)
					if _cell_in_safe_zone(cell, safe_center):
						continue
					_write_hazard_cell(cell, terrain_id, hazard_type, damage)
					# Cluster: add neighbors with higher probability
					for offset in CLUSTER_OFFSETS:
						var neighbor: Vector2i = cell + offset
						if neighbor.x >= x0 and neighbor.x < x1 and neighbor.y >= y0 and neighbor.y < y1:
							if rng.randf() < density * 1.5 and not hazard_cells.has(neighbor) and not _cell_in_safe_zone(neighbor, safe_center):
								_write_hazard_cell(neighbor, terrain_id, hazard_type, damage)

## Check if a world position has a hazard and return its data, or empty dict if safe
func get_hazard_at_position(world_pos: Vector2) -> Dictionary:
	var cell: Vector2i = _cell_for_world(world_pos)
	return hazard_cells.get(cell, {})

## Check if a world position is blocked by a trunk, rock, or root cluster.
func is_position_blocked(world_pos: Vector2) -> bool:
	var cell: Vector2i = _cell_for_world(world_pos)
	if not hazard_cells.has(cell):
		return false
	return hazard_cells[cell].get("hazard_type", "") == "block"

func get_blocking_cell_near_position(world_pos: Vector2, radius: float) -> Dictionary:
	var min_cell: Vector2i = _cell_for_world(world_pos - Vector2(radius, radius))
	var max_cell: Vector2i = _cell_for_world(world_pos + Vector2(radius, radius))
	var best: Dictionary = {}
	var best_distance_sq: float = INF
	for cy in range(min_cell.y, max_cell.y + 1):
		for cx in range(min_cell.x, max_cell.x + 1):
			var cell: Vector2i = Vector2i(cx, cy)
			if not hazard_cells.has(cell):
				continue
			var data: Dictionary = hazard_cells[cell]
			if data.get("hazard_type", "") != "block":
				continue
			var center: Vector2 = (Vector2(float(cell.x), float(cell.y)) + Vector2(0.5, 0.5)) * CELL_SIZE
			var distance_sq: float = world_pos.distance_squared_to(center)
			var hit_radius: float = radius + CELL_SIZE * 0.48
			if distance_sq <= hit_radius * hit_radius and distance_sq < best_distance_sq:
				best_distance_sq = distance_sq
				best = {
					"cell": cell,
					"center": center,
					"data": data,
				}
	return best

## Get slow multiplier for a position (returns 1.0 if not slowed)
func get_slow_multiplier(world_pos: Vector2) -> float:
	var cell: Vector2i = _cell_for_world(world_pos)
	if not hazard_cells.has(cell):
		return 1.0
	var data: Dictionary = hazard_cells[cell]
	if data.get("hazard_type", "") == "slow":
		return 0.6  # 40% slow
	return 1.0

## Check if position has damage hazard and return damage amount
func get_damage_at_position(world_pos: Vector2) -> int:
	var cell: Vector2i = _cell_for_world(world_pos)
	if not hazard_cells.has(cell):
		return 0
	var data: Dictionary = hazard_cells[cell]
	if data.get("hazard_type", "") == "damage":
		return int(data.get("hazard_damage", 0))
	return 0

func get_cell_size() -> float:
	return CELL_SIZE

func _cell_in_safe_zone(cell: Vector2i, safe_center: Vector2) -> bool:
	var center := (Vector2(float(cell.x), float(cell.y)) + Vector2(0.5, 0.5)) * CELL_SIZE
	return center.distance_squared_to(safe_center) <= SAFE_ZONE_RADIUS * SAFE_ZONE_RADIUS

func _write_hazard_cell(cell: Vector2i, terrain_id: String, hazard_type: String, damage: int) -> void:
	hazard_cells[cell] = {
		"terrain_id": terrain_id,
		"hazard_type": hazard_type,
		"hazard_damage": damage,
	}

func _generate_wall_maze(region: Dictionary, cell_bounds: Rect2i, safe_center: Vector2, rng: RandomNumberGenerator) -> void:
	var terrain_id: String = String(region.get("id", ""))
	var damage: int = int(region.get("hazard_damage", 0))
	var spacing: int = maxi(18, int(region.get("wall_spacing_cells", DEFAULT_WALL_SPACING_CELLS)))
	var barricade_count: int = maxi(0, int(region.get("wall_barricade_count", DEFAULT_WALL_BARRICADE_COUNT)))
	var center_cell := _cell_for_world(safe_center)
	var x0 := cell_bounds.position.x + MAZE_EDGE_INSET_CELLS
	var y0 := cell_bounds.position.y + MAZE_EDGE_INSET_CELLS
	var x1 := cell_bounds.position.x + cell_bounds.size.x - MAZE_EDGE_INSET_CELLS
	var y1 := cell_bounds.position.y + cell_bounds.size.y - MAZE_EDGE_INSET_CELLS

	# Long broken walls create the readable maze silhouette; periodic gates keep routes open.
	var half_spacing := maxi(1, int(spacing / 2))
	var start_x := x0 + int(rng.randi_range(0, half_spacing))
	for cx in range(start_x, x1, spacing):
		if abs(cx - center_cell.x) <= CENTER_CORRIDOR_HALF_WIDTH_CELLS:
			continue
		var gate_period := int(rng.randi_range(16, 24))
		var gate_width := int(rng.randi_range(4, 7))
		_write_wall_segment(Vector2i(cx, y0), Vector2i(cx, y1), terrain_id, damage, cell_bounds, safe_center, rng, gate_period, gate_width)

	var start_y := y0 + int(rng.randi_range(0, half_spacing))
	for cy in range(start_y, y1, spacing):
		if abs(cy - center_cell.y) <= CENTER_CORRIDOR_HALF_WIDTH_CELLS:
			continue
		var gate_period := int(rng.randi_range(15, 23))
		var gate_width := int(rng.randi_range(4, 7))
		_write_wall_segment(Vector2i(x0, cy), Vector2i(x1, cy), terrain_id, damage, cell_bounds, safe_center, rng, gate_period, gate_width)

	# Courtyard walls give the field complex "enclosure" shapes without fully sealing areas.
	var courtyard_fractions: Array[Vector2] = [
		Vector2(0.24, 0.24),
		Vector2(0.76, 0.24),
		Vector2(0.22, 0.72),
		Vector2(0.78, 0.76),
		Vector2(0.50, 0.18),
		Vector2(0.50, 0.82),
	]
	for fraction in courtyard_fractions:
		var courtyard_center := Vector2i(
			cell_bounds.position.x + int(round(float(cell_bounds.size.x) * fraction.x)),
			cell_bounds.position.y + int(round(float(cell_bounds.size.y) * fraction.y))
		)
		var half_width := int(rng.randi_range(8, 15))
		var half_height := int(rng.randi_range(5, 10))
		_write_open_courtyard(courtyard_center, half_width, half_height, terrain_id, damage, cell_bounds, safe_center, rng)

	# Short barricades break up long lanes and make collisions happen away from only grid lines.
	for i in range(barricade_count):
		var horizontal := rng.randf() < 0.5
		var length := int(rng.randi_range(5, 15))
		var start := Vector2i(
			int(rng.randi_range(x0, x1)),
			int(rng.randi_range(y0, y1))
		)
		var end := start + (Vector2i(length, 0) if horizontal else Vector2i(0, length))
		_write_wall_segment(start, end, terrain_id, damage, cell_bounds, safe_center, rng, 0, 0)

func _write_open_courtyard(center: Vector2i, half_width: int, half_height: int, terrain_id: String, damage: int, cell_bounds: Rect2i, safe_center: Vector2, rng: RandomNumberGenerator) -> void:
	var left := center.x - half_width
	var right := center.x + half_width
	var top := center.y - half_height
	var bottom := center.y + half_height
	var horizontal_gate_width := int(rng.randi_range(4, 7))
	var vertical_gate_width := int(rng.randi_range(3, 6))
	_write_wall_segment(Vector2i(left, top), Vector2i(right, top), terrain_id, damage, cell_bounds, safe_center, rng, half_width * 2 + 2, horizontal_gate_width)
	_write_wall_segment(Vector2i(left, bottom), Vector2i(right, bottom), terrain_id, damage, cell_bounds, safe_center, rng, half_width * 2 + 2, horizontal_gate_width)
	_write_wall_segment(Vector2i(left, top), Vector2i(left, bottom), terrain_id, damage, cell_bounds, safe_center, rng, half_height * 2 + 2, vertical_gate_width)
	_write_wall_segment(Vector2i(right, top), Vector2i(right, bottom), terrain_id, damage, cell_bounds, safe_center, rng, half_height * 2 + 2, vertical_gate_width)

func _write_wall_segment(start: Vector2i, end: Vector2i, terrain_id: String, damage: int, cell_bounds: Rect2i, safe_center: Vector2, rng: RandomNumberGenerator, gate_period: int, gate_width: int) -> void:
	var delta := end - start
	var step := Vector2i(signi(delta.x), signi(delta.y))
	if step.x != 0 and step.y != 0:
		step.y = 0
	if step == Vector2i.ZERO:
		_write_wall_cell_if_allowed(start, terrain_id, damage, cell_bounds, safe_center)
		return
	var length := maxi(abs(delta.x), abs(delta.y)) + 1
	var gate_offset := int(rng.randi_range(0, maxi(1, gate_period - 1))) if gate_period > 0 else 0
	for i in range(length):
		if gate_period > 0 and gate_width > 0 and ((i + gate_offset) % gate_period) < gate_width:
			continue
		_write_wall_cell_if_allowed(start + step * i, terrain_id, damage, cell_bounds, safe_center)

func _write_wall_cell_if_allowed(cell: Vector2i, terrain_id: String, damage: int, cell_bounds: Rect2i, safe_center: Vector2) -> void:
	if not cell_bounds.has_point(cell):
		return
	if _cell_in_safe_zone(cell, safe_center) or _cell_in_center_corridor(cell, safe_center):
		return
	_write_hazard_cell(cell, terrain_id, "block", damage)

func _cell_in_center_corridor(cell: Vector2i, safe_center: Vector2) -> bool:
	var center_cell := _cell_for_world(safe_center)
	return abs(cell.x - center_cell.x) <= CENTER_CORRIDOR_HALF_WIDTH_CELLS \
		or abs(cell.y - center_cell.y) <= CENTER_CORRIDOR_HALF_WIDTH_CELLS

func _cell_for_world(world_pos: Vector2) -> Vector2i:
	return Vector2i(floori(world_pos.x / CELL_SIZE), floori(world_pos.y / CELL_SIZE))
