extends RefCounted
class_name TerrainCatalog

const UNIFIED_FIELD := {
	"id": "containment_field",
	"name": "Obsidian Maze",
	"color": Color(0.005, 0.01, 0.012, 0.8),
	"accent": Color(0.14, 0.96, 0.62, 0.62),
	"particle_color": Color(0.18, 0.95, 0.72, 0.26),
	"speed_multiplier": 1.0,
	"food_weights": {
		"growth": 1.5,
		"shield": 1.25,
		"magnet": 1.35,
		"combo": 1.35,
		"burst": 1.15,
	},
	"story_intro": "Obsidian Maze online. Feed the crown snake and break the rogue swarm.",
	"hazard_type": "block",
	"hazard_layout": "wall_maze",
	"hazard_density": 0.0,
	"hazard_damage": 0,
	"wall_spacing_cells": 34,
	"wall_barricade_count": 36,
}

const TERRAINS := [UNIFIED_FIELD]

const START_STORY := "Obsidian grid restored. Feed the crown snake and break the rogue swarm."

static func terrain_defs() -> Array:
	return TERRAINS.duplicate(true)

static func terrain_by_id(id: String) -> Dictionary:
	for terrain in TERRAINS:
		if String(terrain.get("id", "")) == id:
			return terrain.duplicate(true)
	return {}

static func terrain_for_position(position: Vector2, play_area: Rect2) -> Dictionary:
	return UNIFIED_FIELD.duplicate(true)

static func terrain_rect(terrain: Dictionary, play_area: Rect2) -> Rect2:
	return play_area

static func terrain_regions(play_area: Rect2) -> Array:
	var regions: Array = []
	for terrain in TERRAINS:
		var definition: Dictionary = terrain.duplicate(true)
		definition["rect"] = play_area
		regions.append(definition)
	return regions

static func wave_story(wave: int) -> String:
	if wave <= 1:
		return START_STORY
	if wave == 2:
		return "Second pressure wave rising. The maze is testing your route."
	if wave == 3:
		return "Containment walls are shifting. Boss signal may surface soon."
	return "Wave %d crossing the Obsidian Maze." % wave
