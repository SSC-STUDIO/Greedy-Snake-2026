extends Node

const RunDataUtil := preload("res://scripts/data/RunData.gd")
const SAVE_PATH := "user://greedy_snake_2026_progress.cfg"
const MAX_RECORDS := 10

var _records: Array = []
var _achievements: Array = []
var _codex: Array = []

func _ready() -> void:
	load_progress()

func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	_records = config.get_value("leaderboard", "records", [])
	_achievements = config.get_value("unlocks", "achievements", [])
	_codex = config.get_value("unlocks", "codex", [])

func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("leaderboard", "records", _records)
	config.set_value("unlocks", "achievements", _achievements)
	config.set_value("unlocks", "codex", _codex)
	config.save(SAVE_PATH)

func submit_run(summary: Dictionary) -> Dictionary:
	var previous_best := get_best_score()
	var record := {
		"score": int(summary.get("score", 0)),
		"duration": float(summary.get("duration", 0.0)),
		"kills": int(summary.get("kills", 0)),
		"max_combo": int(summary.get("max_combo", 0)),
		"death_reason": String(summary.get("death_reason", "")),
		"build_tags": summary.get("build_tags", []),
		"upgrades": summary.get("upgrades", []),
		"challenge_seed": int(summary.get("challenge_seed", RunDataUtil.challenge_seed_for_today())),
		"timestamp": Time.get_unix_time_from_system(),
	}
	_records.append(record)
	_records.sort_custom(func(a, b) -> bool:
		var score_a := int(a.get("score", 0))
		var score_b := int(b.get("score", 0))
		if score_a == score_b:
			return float(a.get("duration", 0.0)) > float(b.get("duration", 0.0))
		return score_a > score_b
	)
	while _records.size() > MAX_RECORDS:
		_records.pop_back()
	_unlock_from_run(record)
	save_progress()
	return {
		"rank": _records.find(record) + 1,
		"previous_best": previous_best,
		"best_score": get_best_score(),
		"is_record": int(record.get("score", 0)) > previous_best,
	}

func get_best_score() -> int:
	if _records.is_empty():
		return 0
	return int(_records[0].get("score", 0))

func get_leaderboard() -> Array:
	return _records.duplicate(true)

func get_achievements() -> Array:
	return _achievements.duplicate()

func daily_seed() -> int:
	return RunDataUtil.challenge_seed_for_today()

func _unlock_from_run(record: Dictionary) -> void:
	_unlock_if("first_run", true)
	_unlock_if("combo_10", int(record.get("max_combo", 0)) >= 10)
	_unlock_if("hunter_5", int(record.get("kills", 0)) >= 5)
	_unlock_if("score_100", int(record.get("score", 0)) >= 100)
	for tag in record.get("build_tags", []):
		if not _codex.has(tag):
			_codex.append(tag)

func _unlock_if(id: String, condition: bool) -> void:
	if condition and not _achievements.has(id):
		_achievements.append(id)
