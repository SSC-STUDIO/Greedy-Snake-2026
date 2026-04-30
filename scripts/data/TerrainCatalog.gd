extends RefCounted
class_name TerrainCatalog

const TERRAINS := [
	{
		"id": "bloom_nursery",
		"name": "Bloom Nursery",
		"quadrant": Vector2i(-1, -1),
		"color": Color(0.08, 0.42, 0.2, 0.2),
		"accent": Color(0.36, 1.0, 0.56, 0.5),
		"particle_color": Color(0.48, 1.0, 0.62, 0.3),
		"speed_multiplier": 1.02,
		"food_weights": {"growth": 2.7, "shield": 1.2},
		"story_intro": "Bloom Nursery online. Growth energy is clustering.",
	},
	{
		"id": "ion_marsh",
		"name": "Ion Marsh",
		"quadrant": Vector2i(1, -1),
		"color": Color(0.06, 0.26, 0.46, 0.2),
		"accent": Color(0.36, 0.76, 1.0, 0.52),
		"particle_color": Color(0.42, 0.78, 1.0, 0.3),
		"speed_multiplier": 0.94,
		"food_weights": {"magnet": 3.0, "shield": 1.3},
		"story_intro": "Ion Marsh detected. Movement resistance rising.",
	},
	{
		"id": "glass_reef",
		"name": "Glass Reef",
		"quadrant": Vector2i(-1, 1),
		"color": Color(0.12, 0.18, 0.5, 0.18),
		"accent": Color(0.64, 0.56, 1.0, 0.5),
		"particle_color": Color(0.62, 0.72, 1.0, 0.28),
		"speed_multiplier": 1.06,
		"food_weights": {"combo": 2.8, "magnet": 1.2},
		"story_intro": "Glass Reef is refracting combo signals.",
	},
	{
		"id": "ember_vein",
		"name": "Ember Vein",
		"quadrant": Vector2i(1, 1),
		"color": Color(0.48, 0.12, 0.04, 0.18),
		"accent": Color(1.0, 0.36, 0.12, 0.54),
		"particle_color": Color(1.0, 0.42, 0.14, 0.3),
		"speed_multiplier": 0.98,
		"food_weights": {"burst": 3.2, "combo": 1.15},
		"story_intro": "Ember Vein active. Volatile nutrients ahead.",
	},
]

const START_STORY := "SECTOR A-01 link restored. Feed the biosnake and purge the rogue swarm."

static func terrain_defs() -> Array:
	return TERRAINS.duplicate(true)

static func terrain_by_id(id: String) -> Dictionary:
	for terrain in TERRAINS:
		if String(terrain.get("id", "")) == id:
			return terrain.duplicate(true)
	return {}

static func terrain_for_position(position: Vector2, play_area: Rect2) -> Dictionary:
	var quadrant := Vector2i(-1 if position.x < play_area.get_center().x else 1, -1 if position.y < play_area.get_center().y else 1)
	for terrain in TERRAINS:
		if terrain.get("quadrant", Vector2i.ZERO) == quadrant:
			return terrain.duplicate(true)
	return TERRAINS[0].duplicate(true)

static func terrain_rect(terrain: Dictionary, play_area: Rect2) -> Rect2:
	var center := play_area.get_center()
	var quadrant: Vector2i = terrain.get("quadrant", Vector2i(-1, -1))
	var x := play_area.position.x if quadrant.x < 0 else center.x
	var y := play_area.position.y if quadrant.y < 0 else center.y
	return Rect2(Vector2(x, y), play_area.size * 0.5)

static func terrain_regions(play_area: Rect2) -> Array:
	var regions: Array = []
	for terrain in TERRAINS:
		var definition: Dictionary = terrain.duplicate(true)
		definition["rect"] = terrain_rect(definition, play_area)
		regions.append(definition)
	return regions

static func wave_story(wave: int) -> String:
	if wave <= 1:
		return START_STORY
	if wave == 2:
		return "Second pressure wave rising. The habitat is testing your pattern."
	if wave == 3:
		return "Containment seals are weakening. Boss signal may surface soon."
	return "Wave %d crossing all ecology lanes." % wave
