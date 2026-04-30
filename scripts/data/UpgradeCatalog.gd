extends RefCounted
class_name UpgradeCatalog

const RARITY_COLORS := {
	"common": Color(0.52, 0.92, 0.68),
	"rare": Color(0.38, 0.74, 1.0),
	"epic": Color(0.86, 0.48, 1.0),
	"legendary": Color(1.0, 0.76, 0.28),
}

const FOOD_TYPES := {
	"energy": {
		"name": "Energy",
		"weight": 72,
		"radius": Vector2(2.4, 6.4),
		"score": 1,
		"growth": 1,
		"color": Color(0.22, 1.0, 0.58),
	},
	"combo": {
		"name": "Combo",
		"weight": 10,
		"radius": Vector2(5.4, 8.8),
		"score": 2,
		"growth": 1,
		"color": Color(0.9, 1.0, 0.28),
	},
	"shield": {
		"name": "Shield",
		"weight": 7,
		"radius": Vector2(5.8, 9.4),
		"score": 1,
		"growth": 1,
		"shield": 3.0,
		"color": Color(0.55, 1.0, 0.96),
	},
	"magnet": {
		"name": "Magnet",
		"weight": 5,
		"radius": Vector2(6.0, 9.6),
		"score": 1,
		"growth": 1,
		"magnet": 6.0,
		"color": Color(0.42, 0.72, 1.0),
	},
	"burst": {
		"name": "Burst",
		"weight": 4,
		"radius": Vector2(6.6, 10.2),
		"score": 2,
		"growth": 1,
		"explosion": 180.0,
		"color": Color(1.0, 0.42, 0.16),
	},
	"growth": {
		"name": "Growth",
		"weight": 2,
		"radius": Vector2(7.0, 11.0),
		"score": 4,
		"growth": 3,
		"color": Color(1.0, 0.54, 0.86),
	},
}

const ELITE_AFFIXES := [
	{"id": "swift", "name": "Swift", "speed": 0.22, "color": Color(0.9, 1.0, 0.26)},
	{"id": "splitter", "name": "Splitter", "split": 2, "color": Color(0.44, 1.0, 0.72)},
	{"id": "guarded", "name": "Guarded", "health": 1, "color": Color(0.52, 0.9, 1.0)},
	{"id": "volatile", "name": "Volatile", "death_explosion": 210.0, "color": Color(1.0, 0.36, 0.16)},
	{"id": "tracker", "name": "Tracker", "aggression": 0.28, "color": Color(1.0, 0.28, 0.48)},
	{"id": "toxic", "name": "Toxic", "poison": true, "color": Color(0.2, 1.0, 0.28)},
	{"id": "summoner", "name": "Summoner", "summon": 1, "color": Color(0.78, 0.58, 1.0)},
	{"id": "giant", "name": "Giant", "radius": 1.35, "segments": 5, "color": Color(1.0, 0.64, 0.3)},
	{"id": "blink", "name": "Blink", "blink": true, "color": Color(0.78, 0.9, 1.0)},
	{"id": "frenzy", "name": "Frenzy", "speed": 0.16, "aggression": 0.2, "color": Color(1.0, 0.2, 0.72)},
]

const UPGRADES := [
	{
		"id": "turbo_tendons",
		"name": "Turbo Tendons",
		"rarity": "common",
		"tags": ["boost"],
		"description": "+12% cruise speed.",
		"effects": {"speed_mult": 0.12},
		"icon_region": Rect2i(0, 0, 64, 64),
	},
	{
		"id": "overdrive_core",
		"name": "Overdrive Core",
		"rarity": "rare",
		"tags": ["boost"],
		"description": "Boost is 25% stronger.",
		"effects": {"boost_mult": 0.25},
		"icon_region": Rect2i(64, 0, 64, 64),
	},
	{
		"id": "vector_fins",
		"name": "Vector Fins",
		"rarity": "common",
		"tags": ["boost"],
		"description": "Sharper turning at high speed.",
		"effects": {"turn_response": 0.06},
		"icon_region": Rect2i(128, 0, 64, 64),
	},
	{
		"id": "afterimage_dash",
		"name": "Afterimage Dash",
		"rarity": "rare",
		"tags": ["boost", "explosion"],
		"description": "Boost trails erupt every few seconds.",
		"effects": {"dash_shockwave": 1, "explosion_radius": 35.0},
		"icon_region": Rect2i(192, 0, 64, 64),
	},
	{
		"id": "phase_shell",
		"name": "Phase Shell",
		"rarity": "common",
		"tags": ["shield"],
		"description": "All shields last 3s longer.",
		"effects": {"shield_bonus": 3.0},
		"icon_region": Rect2i(256, 0, 64, 64),
	},
	{
		"id": "prism_guard",
		"name": "Prism Guard",
		"rarity": "rare",
		"tags": ["shield"],
		"description": "Gain a 5s shield now.",
		"effects": {"shield_now": 5.0},
		"icon_region": Rect2i(320, 0, 64, 64),
	},
	{
		"id": "last_chance",
		"name": "Last Chance",
		"rarity": "epic",
		"tags": ["shield"],
		"description": "Survive one fatal hit with a burst.",
		"effects": {"revive_charges": 1},
		"icon_region": Rect2i(384, 0, 64, 64),
	},
	{
		"id": "static_aura",
		"name": "Static Aura",
		"rarity": "common",
		"tags": ["explosion"],
		"description": "Food bursts hit nearby enemies.",
		"effects": {"explosion_radius": 85.0},
		"icon_region": Rect2i(448, 0, 64, 64),
	},
	{
		"id": "chain_bloom",
		"name": "Chain Bloom",
		"rarity": "rare",
		"tags": ["explosion", "consume"],
		"description": "Combos amplify food explosions.",
		"effects": {"combo_explosion": 16.0, "combo_score_bonus": 0.15},
		"icon_region": Rect2i(0, 64, 64, 64),
	},
	{
		"id": "volatile_core",
		"name": "Volatile Core",
		"rarity": "epic",
		"tags": ["explosion"],
		"description": "Kills detonate into another blast.",
		"effects": {"kill_explosion": 220.0},
		"icon_region": Rect2i(64, 64, 64, 64),
	},
	{
		"id": "hunger_gland",
		"name": "Hunger Gland",
		"rarity": "common",
		"tags": ["consume"],
		"description": "+1 score from all food.",
		"effects": {"food_value_bonus": 1},
		"icon_region": Rect2i(128, 64, 64, 64),
	},
	{
		"id": "long_tail",
		"name": "Long Tail",
		"rarity": "common",
		"tags": ["consume"],
		"description": "Every food adds one extra segment.",
		"effects": {"growth_bonus": 1},
		"icon_region": Rect2i(192, 64, 64, 64),
	},
	{
		"id": "combo_lattice",
		"name": "Combo Lattice",
		"rarity": "rare",
		"tags": ["consume"],
		"description": "Longer combo window and more score.",
		"effects": {"combo_window": 1.2, "combo_score_bonus": 0.25},
		"icon_region": Rect2i(256, 64, 64, 64),
	},
	{
		"id": "magnet_bloom",
		"name": "Magnet Bloom",
		"rarity": "common",
		"tags": ["consume", "summon"],
		"description": "Food pickup range expands.",
		"effects": {"magnet_radius": 95.0, "pickup_radius": 10.0},
		"icon_region": Rect2i(320, 64, 64, 64),
	},
	{
		"id": "feeder_drone",
		"name": "Feeder Drone",
		"rarity": "rare",
		"tags": ["summon", "consume"],
		"description": "A drone gathers nearby food.",
		"effects": {"companion_count": 1},
		"icon_region": Rect2i(384, 64, 64, 64),
	},
	{
		"id": "echo_seed",
		"name": "Echo Seed",
		"rarity": "rare",
		"tags": ["summon", "consume"],
		"description": "Special food appears more often.",
		"effects": {"special_food_chance": 0.05},
		"icon_region": Rect2i(448, 64, 64, 64),
	},
	{
		"id": "predator_mark",
		"name": "Predator Mark",
		"rarity": "common",
		"tags": ["boost", "consume"],
		"description": "Enemy kills award 50% more score.",
		"effects": {"kill_score_mult": 0.5},
		"icon_region": Rect2i(0, 128, 64, 64),
	},
	{
		"id": "boss_breaker",
		"name": "Boss Breaker",
		"rarity": "epic",
		"tags": ["explosion", "boost"],
		"description": "Boss damage is doubled.",
		"effects": {"boss_damage": 1},
		"icon_region": Rect2i(64, 128, 64, 64),
	},
	{
		"id": "emergency_battery",
		"name": "Emergency Battery",
		"rarity": "rare",
		"tags": ["shield", "boost"],
		"description": "Leaving the arena grants a brief shield once per wave.",
		"effects": {"edge_shield": 1},
		"icon_region": Rect2i(128, 128, 64, 64),
	},
	{
		"id": "nest_signal",
		"name": "Nest Signal",
		"rarity": "legendary",
		"tags": ["summon"],
		"description": "Gain two drones and a wider magnet field.",
		"effects": {"companion_count": 2, "magnet_radius": 120.0},
		"icon_region": Rect2i(192, 128, 64, 64),
	},
]

static func upgrade_by_id(id: String) -> Dictionary:
	for upgrade in UPGRADES:
		if String(upgrade.get("id", "")) == id:
			return upgrade.duplicate(true)
	return {}

static func random_upgrade_choices(owned_ids: Array, count: int = 3) -> Array:
	var pool: Array = []
	for upgrade in UPGRADES:
		if not owned_ids.has(String(upgrade.get("id", ""))):
			pool.append(upgrade)
	pool.shuffle()
	var result: Array = []
	for upgrade in pool:
		if result.size() >= count:
			break
		result.append(upgrade.duplicate(true))
	return result

static func food_type(kind: String) -> Dictionary:
	if FOOD_TYPES.has(kind):
		return FOOD_TYPES[kind].duplicate(true)
	return FOOD_TYPES["energy"].duplicate(true)

static func random_food_type(special_bonus: float = 0.0, food_weights: Dictionary = {}) -> Dictionary:
	var total := 0.0
	var weighted: Array = []
	for kind in FOOD_TYPES.keys():
		var definition: Dictionary = FOOD_TYPES[kind]
		var weight := float(definition.get("weight", 1))
		if kind != "energy":
			weight *= 1.0 + clampf(special_bonus, 0.0, 1.0) * 2.5
		if food_weights.has(kind):
			weight *= maxf(0.05, float(food_weights.get(kind, 1.0)))
		total += weight
		weighted.append({"kind": kind, "weight": weight})
	var roll := randf() * total
	for item in weighted:
		roll -= float(item["weight"])
		if roll <= 0.0:
			var definition := food_type(String(item["kind"]))
			definition["id"] = String(item["kind"])
			return definition
	var fallback := food_type("energy")
	fallback["id"] = "energy"
	return fallback

static func random_affixes(count: int) -> Array:
	var pool := ELITE_AFFIXES.duplicate(true)
	pool.shuffle()
	var result: Array = []
	for affix in pool:
		if result.size() >= count:
			break
		result.append(affix.duplicate(true))
	return result

static func rarity_color(rarity: String) -> Color:
	return RARITY_COLORS.get(rarity, RARITY_COLORS["common"])

static func summarize_tags(upgrades: Array) -> Array:
	var tag_counts := {}
	for upgrade in upgrades:
		for tag in upgrade.get("tags", []):
			tag_counts[tag] = int(tag_counts.get(tag, 0)) + 1
	var tags: Array = tag_counts.keys()
	tags.sort_custom(func(a, b) -> bool:
		return int(tag_counts[a]) > int(tag_counts[b])
	)
	return tags
