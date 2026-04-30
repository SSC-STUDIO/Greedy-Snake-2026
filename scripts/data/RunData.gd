extends RefCounted
class_name RunData

static func new_modifier_state() -> Dictionary:
	return {
		"speed_mult": 0.0,
		"boost_mult": 0.0,
		"turn_response": 0.0,
		"shield_bonus": 0.0,
		"shield_now": 0.0,
		"revive_charges": 0,
		"explosion_radius": 0.0,
		"combo_explosion": 0.0,
		"kill_explosion": 0.0,
		"food_value_bonus": 0,
		"growth_bonus": 0,
		"combo_window": 0.0,
		"combo_score_bonus": 0.0,
		"magnet_radius": 0.0,
		"magnet_duration_bonus": 0.0,
		"pickup_radius": 0.0,
		"companion_count": 0,
		"special_food_chance": 0.0,
		"kill_score_mult": 0.0,
		"boss_damage": 0,
		"dash_shockwave": 0,
		"edge_shield": 0,
	}

static func new_wave_state() -> Dictionary:
	return {
		"elapsed": 0.0,
		"wave": 1,
		"pressure": 1.0,
		"next_wave_time": 60.0,
		"next_elite_time": 42.0,
		"boss_warning": false,
		"boss_spawned": false,
		"boss_defeated": false,
		"edge_shield_wave": -1,
		"last_event": "Wave 1",
		"event_time": 3.0,
	}

static func new_run_stats() -> Dictionary:
	return {
		"score": 0,
		"food_eaten": 0,
		"kills": 0,
		"elite_kills": 0,
		"boss_kills": 0,
		"max_combo": 0,
		"duration": 0.0,
		"death_reason": "",
		"upgrades": [],
		"build_tags": [],
		"waves": 1,
		"challenge_seed": challenge_seed_for_today(),
	}

static func new_unlock_state() -> Dictionary:
	return {
		"achievements": [],
		"skins": ["neon_green"],
		"codex": [],
		"talents": {},
	}

static func challenge_seed_for_today() -> int:
	var date := Time.get_date_dict_from_system()
	return challenge_seed_for_date(int(date.get("year", 2026)), int(date.get("month", 1)), int(date.get("day", 1)))

static func challenge_seed_for_date(year: int, month: int, day: int) -> int:
	var value := year * 10000 + month * 100 + day
	value = int(posmod(value * 1103515245 + 12345, 2147483647))
	return 100000 + value % 900000

static func format_duration(seconds: float) -> String:
	var total: int = maxi(0, int(round(seconds)))
	var minutes: int = int(total / 60)
	var remainder: int = total % 60
	return "%02d:%02d" % [minutes, remainder]
