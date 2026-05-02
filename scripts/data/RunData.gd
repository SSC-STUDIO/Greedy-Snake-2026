extends RefCounted
class_name RunData

## 返回初始修改器状态字典。
##
## 字段说明：
##   speed_mult: float - 移动速度加成倍率（叠加式），单位：倍，默认 0.0
##   boost_mult: float - 加速强度加成倍率（叠加式），单位：倍，默认 0.0
##   turn_response: float - 转向响应加成（叠加式），单位：倍，默认 0.0
##   shield_bonus: float - 护盾上限加成（叠加式），单位：点，默认 0.0
##   shield_now: float - 当前护盾值，单位：点，默认 0.0
##   revive_charges: int - 复活次数，单位：次，默认 0
##   explosion_radius: float - 爆炸半径加成（叠加式），单位：格，默认 0.0
##   combo_explosion: float - 连击触发爆炸阈值，单位：连击数，默认 0.0
##   kill_explosion: float - 击杀触发爆炸概率，单位：概率（0-1），默认 0.0
##   food_value_bonus: int - 食物价值加成（叠加式），单位：点，默认 0
##   growth_bonus: int - 成长度加成（叠加式），单位：点，默认 0
##   combo_window: float - 连击时间窗口加成（叠加式），单位：秒，默认 0.0
##   combo_score_bonus: float - 连击分数加成倍率（叠加式），单位：倍，默认 0.0
##   magnet_radius: float - 磁力吸引半径，单位：格，默认 0.0
##   magnet_duration_bonus: float - 磁力持续时间加成（叠加式），单位：秒，默认 0.0
##   pickup_radius: float - 自动拾取半径，单位：格，默认 0.0
##   drone_count: int - 自动拾取无人机数量，单位：个，默认 0
##   special_food_chance: float - 特殊食物出现概率加成（叠加式），单位：概率（0-1），默认 0.0
##   kill_score_mult: float - 击杀分数倍率加成（叠加式），单位：倍，默认 0.0
##   boss_damage: int - Boss伤害加成（叠加式），单位：点，默认 0
##   dash_shockwave: int - 冲刺冲击波强度，单位：级，默认 0
##   edge_shield: int - 边界护盾剩余次数，单位：次，默认 0
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
		"drone_count": 0,
		"special_food_chance": 0.0,
		"kill_score_mult": 0.0,
		"boss_damage": 0,
		"dash_shockwave": 0,
		"edge_shield": 0,
	}

## 返回初始波次状态字典。
##
## 字段说明：
##   elapsed: float - 当前波次已用时间，单位：秒，默认 0.0
##   wave: int - 当前波次编号，单位：波，默认 1
##   pressure: float - 压力系数（控制敌人密度/难度），单位：倍，默认 1.0
##   phase: String - 当前阶段（fighting / reward / victory），默认 fighting
##   wave_time: float - 当前波内已用时间，单位：秒，默认 0.0
##   reward_timer: float - 奖励阶段剩余时间，单位：秒，默认 0.0
##   coronation_timer: float - 通关加冕阶段剩余时间，单位：秒，默认 0.0
##   enemy_type: String - 当前波敌人类型标识，默认 Hunter
##   remaining_enemies: int - 当前仍在场的波次敌人数，默认 0
##   followers_alive: int - 当前存活跟班数，默认 0
##   followers_total: int - 当前跟班列表总数（含濒死未移除），默认 0
##   followers_recruited: int - 本局累计招募的跟班总数，默认 0
##   title: String - 当前称号/波次标题，默认 Lone Snake
##   edge_shield_wave: int - 边界护盾生效的波次，-1 表示未激活，默认 -1
##   last_event: String - 上一次事件描述文本，默认 "Wave 1"
##   event_time: float - 事件显示倒计时，单位：秒，默认 3.0
static func new_wave_state() -> Dictionary:
	return {
		"elapsed": 0.0,
		"wave": 1,
		"pressure": 1.0,
		"phase": "fighting",
		"wave_time": 0.0,
		"reward_timer": 0.0,
		"coronation_timer": 0.0,
		"enemy_type": "Hunter",
		"remaining_enemies": 0,
		"followers_alive": 0,
		"followers_total": 0,
		"followers_recruited": 0,
		"title": "Lone Snake",
		"wave_clear_pending": false,
		"edge_shield_wave": -1,
		"last_event": "Wave 1",
		"event_time": 3.0,
	}

## 返回初始运行统计字典。
##
## 字段说明：
##   score: int - 本局累计分数，单位：分，默认 0
##   food_eaten: int - 吃掉的食物总数，单位：个，默认 0
##   kills: int - 击杀普通敌人总数，单位：个，默认 0
##   elite_kills: int - 击杀精英敌人总数，单位：个，默认 0
##   boss_kills: int - 击杀Boss总数，单位：个，默认 0
##   max_combo: int - 本局最高连击数，单位：连击，默认 0
##   duration: float - 本局游戏时长，单位：秒，默认 0.0
##   death_reason: String - 死亡原因描述，空字符串表示存活，默认 ""
##   upgrades: Array - 已获取的升级列表（字符串数组），默认 []
##   build_tags: Array - 当前构建标签列表（字符串数组），默认 []
##   waves: int - 到达的最高波次，单位：波，默认 1
##   challenge_seed: int - 每日挑战种子值，默认 今日种子
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
		"victory": false,
		"title": "Lone Snake",
		"followers_alive": 0,
		"followers_total": 0,
		"followers_recruited": 0,
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
