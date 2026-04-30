## Central data catalog for all upgrade, food, and elite definitions.
##
## Holds every design-tuning constant in one place so that gameplay
## balancing can happen without touching logic code.  Nothing here
## mutates at runtime — all look-ups return [code]duplicate(true)[/code]
## copies to keep the source tables immutable.
extends RefCounted
class_name UpgradeCatalog

## Rarity-tier display colours used by UI to tint upgrade cards.
const RARITY_COLORS := {
	"common": Color(0.52, 0.92, 0.68),
	"rare": Color(0.38, 0.74, 1.0),
	"epic": Color(0.86, 0.48, 1.0),
	"legendary": Color(1.0, 0.76, 0.28),
}

## Food spawn definitions with weighted selection.
##
## Each entry defines the visual (radius, color) and gameplay (score,
## growth, special effects) properties for a food type.  The [code]weight[/code]
## field controls spawn probability — energy food dominates at 72% base.
##
## @experimental: Special foods (shield, magnet, burst, growth) are
## subject to ongoing balance tuning.
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

## Elite enemy modifier pool — each affix adds a behaviour twist to a
## standard enemy when it spawns as "elite".
##
## Affixes are chosen at random (without replacement) at spawn time.
## Up to [code]count[/code] affixes can stack on a single elite, making
## high-count spawns exponentially more dangerous.
##
## Key effects:
## - [code]speed[/code]: additive speed multiplier (0.22 ≈ +22 %).
## - [code]split[/code]: number of smaller copies produced on death.
## - [code]health[/code]: extra hit-points beyond the base 1.
## - [code]death_explosion[/code]: blast radius triggered on death.
## - [code]aggression[/code]: tendency to chase the player (0–1 scale).
## - [code]poison[/code]: attacks apply a damage-over-time debuff.
## - [code]summon[/code]: number of minion enemies spawned periodically.
## - [code]radius[/code] / [code]segments[/code]: physical size override.
## - [code]blink[/code]: enemy periodically teleports short distances.
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

## Player upgrade pool — the core progression mechanic.
##
## Each upgrade is a one-time pick offered between waves.  Upgrades are
## grouped by [code]tags[/code] (boost / shield / explosion / consume / summon)
## so that [method summarize_tags] can surface the player's build archetype.
##
## Rarity distribution (for reference):
## - common (6): small incremental bonuses that define early runs.
## - rare   (9): build-warping effects that open new strategies.
## - epic   (3): high-impact, build-defining keystones.
## - legendary (1): the capstone — [code]nest_signal[/code] doubles drone
##   count and magnet range for a fully self-sustaining run.
##
## [code]icon_region[/code] points into a shared 5×3 atlas of 64×64 icons.
##
## @experimental: Numbers are placeholders until playtest balancing.
const UPGRADES := [
	## [common | boost] Raw speed increase.
	{
		"id": "turbo_tendons",
		"name": "Turbo Tendons",
		"rarity": "common",
		"tags": ["boost"],
		"description": "+12% cruise speed.",
		"effects": {"speed_mult": 0.12},
		"icon_region": Rect2i(0, 0, 64, 64),
	},
	## [rare | boost] Amplifies the active boost multiplier.
	{
		"id": "overdrive_core",
		"name": "Overdrive Core",
		"rarity": "rare",
		"tags": ["boost"],
		"description": "Boost is 25% stronger.",
		"effects": {"boost_mult": 0.25},
		"icon_region": Rect2i(64, 0, 64, 64),
	},
	## [common | boost] Improves turn fidelity during high-speed movement.
	{
		"id": "vector_fins",
		"name": "Vector Fins",
		"rarity": "common",
		"tags": ["boost"],
		"description": "Sharper turning at high speed.",
		"effects": {"turn_response": 0.06},
		"icon_region": Rect2i(128, 0, 64, 64),
	},
	## [rare | boost | explosion] Boost trails detonate periodically.
	{
		"id": "afterimage_dash",
		"name": "Afterimage Dash",
		"rarity": "rare",
		"tags": ["boost", "explosion"],
		"description": "Boost trails erupt every few seconds.",
		"effects": {"dash_shockwave": 1, "explosion_radius": 35.0},
		"icon_region": Rect2i(192, 0, 64, 64),
	},
	## [common | shield] Extends shield duration across all sources.
	{
		"id": "phase_shell",
		"name": "Phase Shell",
		"rarity": "common",
		"tags": ["shield"],
		"description": "All shields last 3s longer.",
		"effects": {"shield_bonus": 3.0},
		"icon_region": Rect2i(256, 0, 64, 64),
	},
	## [rare | shield] Grants an immediate 5s shield on pickup.
	{
		"id": "prism_guard",
		"name": "Prism Guard",
		"rarity": "rare",
		"tags": ["shield"],
		"description": "Gain a 5s shield now.",
		"effects": {"shield_now": 5.0},
		"icon_region": Rect2i(320, 0, 64, 64),
	},
	## [epic | shield] Prevents one lethal hit with a protective burst.
	{
		"id": "last_chance",
		"name": "Last Chance",
		"rarity": "epic",
		"tags": ["shield"],
		"description": "Survive one fatal hit with a burst.",
		"effects": {"revive_charges": 1},
		"icon_region": Rect2i(384, 0, 64, 64),
	},
	## [common | explosion] Food bursts damage nearby enemies on pickup.
	{
		"id": "static_aura",
		"name": "Static Aura",
		"rarity": "common",
		"tags": ["explosion"],
		"description": "Food bursts hit nearby enemies.",
		"effects": {"explosion_radius": 85.0},
		"icon_region": Rect2i(448, 0, 64, 64),
	},
	## [rare | explosion | consume] Combo streaks scale explosion power.
	{
		"id": "chain_bloom",
		"name": "Chain Bloom",
		"rarity": "rare",
		"tags": ["explosion", "consume"],
		"description": "Combos amplify food explosions.",
		"effects": {"combo_explosion": 16.0, "combo_score_bonus": 0.15},
		"icon_region": Rect2i(0, 64, 64, 64),
	},
	## [epic | explosion] Killing an enemy triggers a chain explosion.
	{
		"id": "volatile_core",
		"name": "Volatile Core",
		"rarity": "epic",
		"tags": ["explosion"],
		"description": "Kills detonate into another blast.",
		"effects": {"kill_explosion": 220.0},
		"icon_region": Rect2i(64, 64, 64, 64),
	},
	## [common | consume] Flat +1 score from every food eaten.
	{
		"id": "hunger_gland",
		"name": "Hunger Gland",
		"rarity": "common",
		"tags": ["consume"],
		"description": "+1 score from all food.",
		"effects": {"food_value_bonus": 1},
		"icon_region": Rect2i(128, 64, 64, 64),
	},
	## [common | consume] Each food grants an extra body segment.
	{
		"id": "long_tail",
		"name": "Long Tail",
		"rarity": "common",
		"tags": ["consume"],
		"description": "Every food adds one extra segment.",
		"effects": {"growth_bonus": 1},
		"icon_region": Rect2i(192, 64, 64, 64),
	},
	## [rare | consume] Extends combo window and score multiplier.
	{
		"id": "combo_lattice",
		"name": "Combo Lattice",
		"rarity": "rare",
		"tags": ["consume"],
		"description": "Longer combo window and more score.",
		"effects": {"combo_window": 1.2, "combo_score_bonus": 0.25},
		"icon_region": Rect2i(256, 64, 64, 64),
	},
	## [common | consume | summon] Expands passive food attraction radius.
	{
		"id": "magnet_bloom",
		"name": "Magnet Bloom",
		"rarity": "common",
		"tags": ["consume", "summon"],
		"description": "Food pickup range expands.",
		"effects": {"magnet_radius": 95.0, "pickup_radius": 10.0},
		"icon_region": Rect2i(320, 64, 64, 64),
	},
	## [rare | summon | consume] Autonomous drone that collects nearby food.
	{
		"id": "feeder_drone",
		"name": "Feeder Drone",
		"rarity": "rare",
		"tags": ["summon", "consume"],
		"description": "A drone gathers nearby food.",
		"effects": {"companion_count": 1},
		"icon_region": Rect2i(384, 64, 64, 64),
	},
	## [rare | summon | consume] Raises the spawn rate of special food.
	{
		"id": "echo_seed",
		"name": "Echo Seed",
		"rarity": "rare",
		"tags": ["summon", "consume"],
		"description": "Special food appears more often.",
		"effects": {"special_food_chance": 0.05},
		"icon_region": Rect2i(448, 64, 64, 64),
	},
	## [common | boost | consume] Increases score gained from enemy kills.
	{
		"id": "predator_mark",
		"name": "Predator Mark",
		"rarity": "common",
		"tags": ["boost", "consume"],
		"description": "Enemy kills award 50% more score.",
		"effects": {"kill_score_mult": 0.5},
		"icon_region": Rect2i(0, 128, 64, 64),
	},
	## [epic | explosion | boost] Doubles damage dealt to boss enemies.
	{
		"id": "boss_breaker",
		"name": "Boss Breaker",
		"rarity": "epic",
		"tags": ["explosion", "boost"],
		"description": "Boss damage is doubled.",
		"effects": {"boss_damage": 1},
		"icon_region": Rect2i(64, 128, 64, 64),
	},
	## [rare | shield | boost] Arena exit grants a one-time brief shield per wave.
	{
		"id": "emergency_battery",
		"name": "Emergency Battery",
		"rarity": "rare",
		"tags": ["shield", "boost"],
		"description": "Leaving the arena grants a brief shield once per wave.",
		"effects": {"edge_shield": 1},
		"icon_region": Rect2i(128, 128, 64, 64),
	},
	## [legendary | summon] Two drones + expanded magnet — the capstone pick.
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

## Returns a copy of an upgrade definition by its unique identifier.
##
## Returns an empty dictionary if [param id] is not found.
static func upgrade_by_id(id: String) -> Dictionary:
	for upgrade in UPGRADES:
		if String(upgrade.get("id", "")) == id:
			return upgrade.duplicate(true)
	return {}

## Picks a random selection of upgrades for the player to choose from.
##
## Filters out any upgrades the player already owns, shuffles the remaining
## pool, and returns up to [param count] choices.  The caller (usually the
## upgrade UI) then presents these as options.
##
## [param owned_ids] — array of upgrade IDs the player has already picked.
## [param count] — maximum number of choices to return (default: 3).
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

## Returns a deep copy of a food type definition by key.
##
## Falls back to "energy" if [param kind] is not recognised.
static func food_type(kind: String) -> Dictionary:
	if FOOD_TYPES.has(kind):
		return FOOD_TYPES[kind].duplicate(true)
	return FOOD_TYPES["energy"].duplicate(true)

## Selects a random food type using weighted probability.
##
## Base weights come from [constant FOOD_TYPES], then:
## - Special (non-energy) foods are boosted by [param special_bonus]
##   (clamped 0–1, then multiplied by 2.5×).  This lets upgrades like
##   [code]echo_seed[/code] shift the spawn distribution.
## - [param food_weights] provides per-type multipliers; values below
##   0.05 are clamped to avoid zero-weight entries.
##
## The returned dictionary includes an injected [code]id[/code] field
## matching the FOOD_TYPES key.
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

## Selects [param count] random elite affixes without replacement.
##
## Used when spawning an elite enemy to determine its modifiers.
## Returns deep copies so callers can mutate without affecting the pool.
static func random_affixes(count: int) -> Array:
	var pool := ELITE_AFFIXES.duplicate(true)
	pool.shuffle()
	var result: Array = []
	for affix in pool:
		if result.size() >= count:
			break
		result.append(affix.duplicate(true))
	return result

## Returns the display colour for a rarity tier.
##
## Falls back to "common" colour for unknown rarity strings.
static func rarity_color(rarity: String) -> Color:
	return RARITY_COLORS.get(rarity, RARITY_COLORS["common"])

## Extracts and ranks the tag distribution from a list of upgrades.
##
## Counts how many times each tag (boost / shield / explosion / consume /
## summon) appears across [param upgrades], then returns the tags sorted
## by frequency (descending).  Useful for displaying the player's current
## build archetype or for conditional upgrade logic.
##
## Example: [code]["explosion", "boost", "consume"][/code] means the player
## leans heavily into explosion synergy.
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
