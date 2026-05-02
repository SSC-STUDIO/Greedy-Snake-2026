extends Node

const LANGUAGES := ["en", "zh"]
const LANGUAGE_LABELS := ["English", "中文"]
const EN := "en"
const ZH := "zh"

const UPGRADE_NAME_KEYS := {
	"turbo_tendons": "upgrade.turbo_tendons.name",
	"overdrive_core": "upgrade.overdrive_core.name",
	"vector_fins": "upgrade.vector_fins.name",
	"afterimage_dash": "upgrade.afterimage_dash.name",
	"phase_shell": "upgrade.phase_shell.name",
	"prism_guard": "upgrade.prism_guard.name",
	"last_chance": "upgrade.last_chance.name",
	"static_aura": "upgrade.static_aura.name",
	"chain_bloom": "upgrade.chain_bloom.name",
	"volatile_core": "upgrade.volatile_core.name",
	"hunger_gland": "upgrade.hunger_gland.name",
	"long_tail": "upgrade.long_tail.name",
	"combo_lattice": "upgrade.combo_lattice.name",
	"magnet_bloom": "upgrade.magnet_bloom.name",
	"feeder_drone": "upgrade.feeder_drone.name",
	"echo_seed": "upgrade.echo_seed.name",
	"predator_mark": "upgrade.predator_mark.name",
	"boss_breaker": "upgrade.boss_breaker.name",
	"emergency_battery": "upgrade.emergency_battery.name",
	"nest_signal": "upgrade.nest_signal.name",
}

const UPGRADE_DESCRIPTION_KEYS := {
	"turbo_tendons": "upgrade.turbo_tendons.desc",
	"overdrive_core": "upgrade.overdrive_core.desc",
	"vector_fins": "upgrade.vector_fins.desc",
	"afterimage_dash": "upgrade.afterimage_dash.desc",
	"phase_shell": "upgrade.phase_shell.desc",
	"prism_guard": "upgrade.prism_guard.desc",
	"last_chance": "upgrade.last_chance.desc",
	"static_aura": "upgrade.static_aura.desc",
	"chain_bloom": "upgrade.chain_bloom.desc",
	"volatile_core": "upgrade.volatile_core.desc",
	"hunger_gland": "upgrade.hunger_gland.desc",
	"long_tail": "upgrade.long_tail.desc",
	"combo_lattice": "upgrade.combo_lattice.desc",
	"magnet_bloom": "upgrade.magnet_bloom.desc",
	"feeder_drone": "upgrade.feeder_drone.desc",
	"echo_seed": "upgrade.echo_seed.desc",
	"predator_mark": "upgrade.predator_mark.desc",
	"boss_breaker": "upgrade.boss_breaker.desc",
	"emergency_battery": "upgrade.emergency_battery.desc",
	"nest_signal": "upgrade.nest_signal.desc",
}

const TAG_KEYS := {
	"boost": "tag.boost",
	"shield": "tag.shield",
	"explosion": "tag.explosion",
	"consume": "tag.consume",
	"summon": "tag.summon",
}

const DEATH_REASON_KEYS := {
	"Collision": "death.collision",
	"Lava": "death.lava",
	"Venom": "death.venom",
	"Beam": "death.beam",
	"Victory": "death.victory",
	"Unknown": "death.unknown",
}

const TEXT := {
	"en": {
		"language.en": "English",
		"language.zh": "中文",
		"common.on": "On",
		"common.off": "Off",
		"common.none": "none",
		"common.new_run": "new run",
		"common.no_upgrades": "No upgrades yet",
		"common.unknown": "Unknown",
		"menu.sector": "OBSIDIAN MAZE",
		"menu.title": "GREEDY\nSNAKE 2026",
		"menu.subtitle": "2.5D Obsidian Crown Campaign",
		"menu.telemetry": "GRID-LINK: STABLE     SWARM: ACTIVE     RUN-SEED: %d",
		"menu.eyebrow": "OBSIDIAN THRONE",
		"menu.start": "Start Next Run",
		"menu.settings": "Settings",
		"menu.about": "About",
		"menu.quit": "Quit",
		"menu.difficulty": "Difficulty",
		"menu.speed": "Speed",
		"menu.best": "Best",
		"menu.seed": "Seed",
		"settings.title": "System Settings",
		"settings.gameplay": "Gameplay",
		"settings.display": "Display",
		"settings.audio": "Audio",
		"settings.language": "Language",
		"settings.snake_speed": "Snake speed",
		"settings.effects": "Effects",
		"settings.animations": "Animations",
		"settings.screen_shake": "Screen shake",
		"settings.minimap": "Mini-map",
		"settings.map_size": "Map size",
		"settings.antialiasing": "Anti-aliasing",
		"settings.fullscreen": "Fullscreen",
		"settings.master": "Master",
		"settings.bgm": "BGM",
		"settings.sfx": "SFX",
		"settings.sound": "Sound",
		"settings.reset": "Reset",
		"settings.back": "Back",
		"about.title": "About",
		"about.edition": "Edition",
		"about.edition_value": "Obsidian Crown",
		"about.engine": "Engine",
		"about.build": "Build",
		"about.visual_pack": "Visual Pack",
		"about.visual_pack_value": "Generated obsidian UI atlas",
		"about.habitat": "Arena",
		"about.habitat_value": "Obsidian Maze",
		"about.mission": "Mission",
		"about.mission_value": "Break rogue AI snakes",
		"about.note": "A crown snake feeds through a black maze, recruits followers, and survives escalating waves to become Snake Emperor.",
		"pause.title": "Paused",
		"pause.resume": "Resume",
		"pause.restart": "Restart",
		"pause.menu": "Menu",
		"pause.stats": "Wave %d  Combo %d  Pack %d/%d  Recruited %d  Drone %d\n%s",
		"gameover.fallen": "Crown Fallen",
		"gameover.score": "Score  %d",
		"gameover.victory": "Victory",
		"gameover.death": "Death  %s",
		"gameover.detail": "Time %s  Kills %d  Combo %d\n%s  Wave %d  Pack %d/%d  Recruited %d  Drone %d\nBuild  %s",
		"gameover.best": "Best  %d",
		"gameover.new_record": "New record  %d",
		"gameover.gap": "Best  %d  Gap  %d",
		"gameover.seed": "%s  Seed %d",
		"hud.enemy": "Enemy  %d  Pack %d/%d  Recruited %d  Drone %d",
		"hud.wave": "Wave  %d/%d  %s",
		"hud.combo": "Combo  x%d  %.1fs",
		"hud.build": "Build  %s",
		"hud.boost": "Boost",
		"hud.cruise": "Cruise",
		"hud.shield": "%s  Shield %.1fs",
		"hud.lava": "Lava  %.1fs",
		"hud.score": "Score  %d",
		"upgrade.title": "Choose Upgrade",
		"upgrade.build": "Build  %s",
		"labels.easy": "Easy",
		"labels.normal": "Normal",
		"labels.hard": "Hard",
		"labels.slow": "Slow",
		"labels.fast": "Fast",
		"labels.low": "Low",
		"labels.balanced": "Balanced",
		"labels.high": "High",
		"labels.compact": "Compact",
		"labels.standard": "Standard",
		"labels.large": "Large",
		"title.lone_snake": "Lone Snake",
		"title.rising_fang": "Rising Fang",
		"title.armored_coil": "Armored Coil",
		"title.venom_crown": "Venom Crown",
		"title.snake_king": "Snake King",
		"title.brood_king": "Brood King",
		"title.mine_tyrant": "Mine Tyrant",
		"title.beam_regent": "Beam Regent",
		"title.devourer_king": "Devourer King",
		"title.snake_emperor": "Snake Emperor",
		"enemy.hunter": "Hunter",
		"enemy.dasher": "Dasher",
		"enemy.shellback": "Shellback",
		"enemy.venom": "Venom",
		"enemy.splitter": "Splitter",
		"enemy.broodcaller": "Broodcaller",
		"enemy.minecoil": "Minecoil",
		"enemy.beamer": "Beamer",
		"enemy.devourer": "Devourer",
		"enemy.emperor_core": "Emperor Core",
		"event.wave_1": "Wave 1  Hunter swarm",
		"event.wave_2": "Wave 2  Dashers",
		"event.wave_3": "Wave 3  Shellbacks",
		"event.wave_4": "Wave 4  Venom trails",
		"event.wave_5": "Wave 5  Splitters",
		"event.wave_6": "Wave 6  Broodcallers",
		"event.wave_7": "Wave 7  Minecoils",
		"event.wave_8": "Wave 8  Beamers",
		"event.wave_9": "Wave 9  Devourers",
		"event.wave_10": "Wave 10  Emperor Core",
		"event.wave_clear": "Wave cleared  +3 followers",
		"event.snake_king": "Snake King  +3 followers",
		"event.snake_emperor": "Snake Emperor",
		"event.follower_lost": "Follower lost",
		"event.wall_impact": "Wall impact",
		"event.shield_seconds": "Shield +%.0fs",
		"event.emergency_shield": "Emergency shield",
		"event.thorn_strike": "Thorn strike",
		"event.magnet_field": "Magnet field",
		"event.upgrade_ready": "Upgrade ready",
		"event.boss_defeated": "Boss defeated",
		"event.boss_story": "Rogue core suppressed. The maze is breathing again.",
		"event.revive_last_chance": "Last chance",
		"event.revive_toxic_guard": "Toxic guard",
		"event.revive_beam_guard": "Beam guard",
		"tag.boost": "boost",
		"tag.shield": "shield",
		"tag.explosion": "explosion",
		"tag.consume": "consume",
		"tag.summon": "summon",
		"death.collision": "Collision",
		"death.lava": "Lava",
		"death.venom": "Venom",
		"death.beam": "Beam",
		"death.victory": "Victory",
		"death.unknown": "Unknown",
		"story.start": "Obsidian grid restored. Feed the crown snake and break the rogue swarm.",
		"story.wave_1": "You begin alone. Clear the hunters and claim the first followers.",
		"story.wave_2": "Dashers telegraph a charge, then cut straight through the field.",
		"story.wave_3": "Shellbacks raise a timed guard. Strike between shield pulses.",
		"story.wave_4": "Venom snakes leave toxic blooms. Keep the pack moving.",
		"story.wave_5": "Splitters burst into smaller snakes. Clear every fragment to become Snake King.",
		"story.wave_6": "Broodcallers summon guards. Kill callers before the swarm thickens.",
		"story.wave_7": "Minecoils seed explosive spores. Watch the ground they leave behind.",
		"story.wave_8": "Beamers lock a line before firing. Side-step the warning beam.",
		"story.wave_9": "Devourers eat field energy to heal and surge. Starve them out.",
		"story.wave_10": "The final core combines every pressure pattern. Break it and become Snake Emperor.",
		"terrain.wave_2": "Second pressure wave rising. The maze is testing your route.",
		"terrain.wave_3": "Containment walls are shifting. Boss signal may surface soon.",
		"terrain.wave_generic": "Wave %d crossing the Obsidian Maze.",
		"upgrade.turbo_tendons.name": "Turbo Tendons",
		"upgrade.turbo_tendons.desc": "+12% cruise speed.",
		"upgrade.overdrive_core.name": "Overdrive Core",
		"upgrade.overdrive_core.desc": "Boost is 25% stronger.",
		"upgrade.vector_fins.name": "Vector Fins",
		"upgrade.vector_fins.desc": "Sharper turning at high speed.",
		"upgrade.afterimage_dash.name": "Afterimage Dash",
		"upgrade.afterimage_dash.desc": "Boost trails erupt every few seconds.",
		"upgrade.phase_shell.name": "Phase Shell",
		"upgrade.phase_shell.desc": "All shields last 3s longer.",
		"upgrade.prism_guard.name": "Prism Guard",
		"upgrade.prism_guard.desc": "Gain a 5s shield now.",
		"upgrade.last_chance.name": "Last Chance",
		"upgrade.last_chance.desc": "Survive one fatal hit with a burst.",
		"upgrade.static_aura.name": "Static Aura",
		"upgrade.static_aura.desc": "Food bursts hit nearby enemies.",
		"upgrade.chain_bloom.name": "Chain Bloom",
		"upgrade.chain_bloom.desc": "Combos amplify food explosions.",
		"upgrade.volatile_core.name": "Volatile Core",
		"upgrade.volatile_core.desc": "Kills detonate into another blast.",
		"upgrade.hunger_gland.name": "Hunger Gland",
		"upgrade.hunger_gland.desc": "+1 score from all food.",
		"upgrade.long_tail.name": "Long Tail",
		"upgrade.long_tail.desc": "Every food adds one extra segment.",
		"upgrade.combo_lattice.name": "Combo Lattice",
		"upgrade.combo_lattice.desc": "Longer combo window and more score.",
		"upgrade.magnet_bloom.name": "Magnet Bloom",
		"upgrade.magnet_bloom.desc": "Food pickup range expands.",
		"upgrade.feeder_drone.name": "Feeder Drone",
		"upgrade.feeder_drone.desc": "A drone gathers nearby food.",
		"upgrade.echo_seed.name": "Echo Seed",
		"upgrade.echo_seed.desc": "Special food appears more often.",
		"upgrade.predator_mark.name": "Predator Mark",
		"upgrade.predator_mark.desc": "Enemy kills award 50% more score.",
		"upgrade.boss_breaker.name": "Boss Breaker",
		"upgrade.boss_breaker.desc": "Boss damage is doubled.",
		"upgrade.emergency_battery.name": "Emergency Battery",
		"upgrade.emergency_battery.desc": "Leaving the arena grants a brief shield once per wave.",
		"upgrade.nest_signal.name": "Nest Signal",
		"upgrade.nest_signal.desc": "Gain two drones and a wider magnet field.",
	},
	"zh": {
		"language.en": "English",
		"language.zh": "中文",
		"common.on": "开",
		"common.off": "关",
		"common.none": "无",
		"common.new_run": "新局",
		"common.no_upgrades": "尚未获得升级",
		"common.unknown": "未知",
		"menu.sector": "黑曜迷宫",
		"menu.title": "贪吃蛇\n2026",
		"menu.subtitle": "2.5D 黑曜蛇王战役",
		"menu.telemetry": "迷宫链路：稳定     蛇群：活跃     种子：%d",
		"menu.eyebrow": "黑曜王座",
		"menu.start": "开始下一局",
		"menu.settings": "设置",
		"menu.about": "关于",
		"menu.quit": "退出",
		"menu.difficulty": "难度",
		"menu.speed": "速度",
		"menu.best": "最高分",
		"menu.seed": "种子",
		"settings.title": "系统设置",
		"settings.gameplay": "游戏",
		"settings.display": "显示",
		"settings.audio": "音频",
		"settings.language": "语言",
		"settings.snake_speed": "蛇速度",
		"settings.effects": "特效",
		"settings.animations": "动画",
		"settings.screen_shake": "屏幕震动",
		"settings.minimap": "小地图",
		"settings.map_size": "地图大小",
		"settings.antialiasing": "抗锯齿",
		"settings.fullscreen": "全屏",
		"settings.master": "主音量",
		"settings.bgm": "音乐",
		"settings.sfx": "音效",
		"settings.sound": "声音",
		"settings.reset": "重置",
		"settings.back": "返回",
		"about.title": "关于",
		"about.edition": "版本",
		"about.edition_value": "黑曜王冠",
		"about.engine": "引擎",
		"about.build": "构建",
		"about.visual_pack": "视觉包",
		"about.visual_pack_value": "生成式黑曜 UI 图集",
		"about.habitat": "竞技场",
		"about.habitat_value": "黑曜迷宫",
		"about.mission": "任务",
		"about.mission_value": "击破失控 AI 蛇群",
		"about.note": "王蛇在黑色迷宫中吞噬能量、招募跟班，并在不断升级的波次中成为蛇帝。",
		"pause.title": "已暂停",
		"pause.resume": "继续",
		"pause.restart": "重新开始",
		"pause.menu": "主菜单",
		"pause.stats": "波次 %d  连击 %d  蛇群 %d/%d  已招募 %d  无人机 %d\n%s",
		"gameover.fallen": "王冠坠落",
		"gameover.score": "分数  %d",
		"gameover.victory": "胜利",
		"gameover.death": "死亡  %s",
		"gameover.detail": "时间 %s  击杀 %d  连击 %d\n%s  波次 %d  蛇群 %d/%d  已招募 %d  无人机 %d\n构筑  %s",
		"gameover.best": "最高分  %d",
		"gameover.new_record": "新纪录  %d",
		"gameover.gap": "最高分  %d  差距  %d",
		"gameover.seed": "%s  种子 %d",
		"hud.enemy": "敌人  %d  蛇群 %d/%d  已招募 %d  无人机 %d",
		"hud.wave": "波次  %d/%d  %s",
		"hud.combo": "连击  x%d  %.1fs",
		"hud.build": "构筑  %s",
		"hud.boost": "加速",
		"hud.cruise": "巡航",
		"hud.shield": "%s  护盾 %.1fs",
		"hud.lava": "熔岩  %.1fs",
		"hud.score": "分数  %d",
		"upgrade.title": "选择升级",
		"upgrade.build": "构筑  %s",
		"labels.easy": "简单",
		"labels.normal": "普通",
		"labels.hard": "困难",
		"labels.slow": "慢速",
		"labels.fast": "快速",
		"labels.low": "低",
		"labels.balanced": "均衡",
		"labels.high": "高",
		"labels.compact": "紧凑",
		"labels.standard": "标准",
		"labels.large": "大型",
		"title.lone_snake": "孤蛇",
		"title.rising_fang": "升牙",
		"title.armored_coil": "甲环",
		"title.venom_crown": "毒冠",
		"title.snake_king": "蛇王",
		"title.brood_king": "巢王",
		"title.mine_tyrant": "雷巢暴君",
		"title.beam_regent": "光束摄政",
		"title.devourer_king": "吞噬王",
		"title.snake_emperor": "蛇帝",
		"enemy.hunter": "猎蛇",
		"enemy.dasher": "冲锋蛇",
		"enemy.shellback": "甲背蛇",
		"enemy.venom": "毒蛇",
		"enemy.splitter": "分裂蛇",
		"enemy.broodcaller": "唤巢蛇",
		"enemy.minecoil": "雷环蛇",
		"enemy.beamer": "光束蛇",
		"enemy.devourer": "吞噬蛇",
		"enemy.emperor_core": "帝核",
		"event.wave_1": "第 1 波  猎蛇群",
		"event.wave_2": "第 2 波  冲锋蛇",
		"event.wave_3": "第 3 波  甲背蛇",
		"event.wave_4": "第 4 波  毒蛇轨迹",
		"event.wave_5": "第 5 波  分裂蛇",
		"event.wave_6": "第 6 波  唤巢蛇",
		"event.wave_7": "第 7 波  雷环蛇",
		"event.wave_8": "第 8 波  光束蛇",
		"event.wave_9": "第 9 波  吞噬蛇",
		"event.wave_10": "第 10 波  帝核",
		"event.wave_clear": "波次清除  +3 跟班",
		"event.snake_king": "蛇王  +3 跟班",
		"event.snake_emperor": "蛇帝",
		"event.follower_lost": "失去跟班",
		"event.wall_impact": "撞墙",
		"event.shield_seconds": "护盾 +%.0f秒",
		"event.emergency_shield": "紧急护盾",
		"event.thorn_strike": "尖刺命中",
		"event.magnet_field": "磁力场",
		"event.upgrade_ready": "可选择升级",
		"event.boss_defeated": "Boss 已击破",
		"event.boss_story": "失控核心已压制，迷宫重新开始呼吸。",
		"event.revive_last_chance": "最后机会",
		"event.revive_toxic_guard": "毒雾护卫",
		"event.revive_beam_guard": "光束护卫",
		"tag.boost": "加速",
		"tag.shield": "护盾",
		"tag.explosion": "爆破",
		"tag.consume": "吞噬",
		"tag.summon": "召唤",
		"death.collision": "碰撞",
		"death.lava": "越界熔毁",
		"death.venom": "毒雾",
		"death.beam": "光束",
		"death.victory": "胜利",
		"death.unknown": "未知",
		"story.start": "黑曜网格已恢复。喂养王蛇，击破失控蛇群。",
		"story.wave_1": "你从孤身开始。清除猎蛇，夺取第一批跟班。",
		"story.wave_2": "冲锋蛇会先预警，然后直线切穿战场。",
		"story.wave_3": "甲背蛇会周期性抬盾。抓住护盾间隙攻击。",
		"story.wave_4": "毒蛇会留下毒性绽放。保持蛇群移动。",
		"story.wave_5": "分裂蛇会爆成小蛇。清除全部碎片即可成为蛇王。",
		"story.wave_6": "唤巢蛇会召来护卫。蛇群变厚前先击杀召唤者。",
		"story.wave_7": "雷环蛇会播撒爆裂孢子。注意它们留下的地面。",
		"story.wave_8": "光束蛇会锁定直线后开火。看到预警就侧移。",
		"story.wave_9": "吞噬蛇会吃掉场上能量来回血并加速。断掉它的补给。",
		"story.wave_10": "最终帝核结合所有压迫模式。击破它，成为蛇帝。",
		"terrain.wave_2": "第二轮压力正在升起，迷宫开始测试你的路线。",
		"terrain.wave_3": "收容墙体正在移动，Boss 信号可能即将出现。",
		"terrain.wave_generic": "第 %d 波正在穿过黑曜迷宫。",
		"upgrade.turbo_tendons.name": "涡轮蛇筋",
		"upgrade.turbo_tendons.desc": "巡航速度 +12%。",
		"upgrade.overdrive_core.name": "超载核心",
		"upgrade.overdrive_core.desc": "加速强度提升 25%。",
		"upgrade.vector_fins.name": "矢量鳍",
		"upgrade.vector_fins.desc": "高速时转向更锐利。",
		"upgrade.afterimage_dash.name": "残影冲刺",
		"upgrade.afterimage_dash.desc": "加速尾迹会周期性爆发。",
		"upgrade.phase_shell.name": "相位壳",
		"upgrade.phase_shell.desc": "所有护盾持续时间 +3 秒。",
		"upgrade.prism_guard.name": "棱镜守卫",
		"upgrade.prism_guard.desc": "立即获得 5 秒护盾。",
		"upgrade.last_chance.name": "最后机会",
		"upgrade.last_chance.desc": "抵挡一次致命伤害并爆发。",
		"upgrade.static_aura.name": "静电光环",
		"upgrade.static_aura.desc": "拾取食物会伤害附近敌人。",
		"upgrade.chain_bloom.name": "连锁绽放",
		"upgrade.chain_bloom.desc": "连击会增强食物爆炸。",
		"upgrade.volatile_core.name": "挥发核心",
		"upgrade.volatile_core.desc": "击杀敌人会触发连锁爆炸。",
		"upgrade.hunger_gland.name": "饥饿腺体",
		"upgrade.hunger_gland.desc": "所有食物分数 +1。",
		"upgrade.long_tail.name": "长尾",
		"upgrade.long_tail.desc": "每个食物额外增加一节身体。",
		"upgrade.combo_lattice.name": "连击晶格",
		"upgrade.combo_lattice.desc": "连击窗口更长，分数更高。",
		"upgrade.magnet_bloom.name": "磁力绽放",
		"upgrade.magnet_bloom.desc": "食物拾取范围扩大。",
		"upgrade.feeder_drone.name": "采食无人机",
		"upgrade.feeder_drone.desc": "一架无人机会收集附近食物。",
		"upgrade.echo_seed.name": "回声种子",
		"upgrade.echo_seed.desc": "特殊食物出现得更频繁。",
		"upgrade.predator_mark.name": "掠食标记",
		"upgrade.predator_mark.desc": "击杀敌人分数提高 50%。",
		"upgrade.boss_breaker.name": "Boss 破甲器",
		"upgrade.boss_breaker.desc": "对 Boss 造成双倍伤害。",
		"upgrade.emergency_battery.name": "应急电池",
		"upgrade.emergency_battery.desc": "每波首次离开竞技场会获得短暂护盾。",
		"upgrade.nest_signal.name": "巢群信号",
		"upgrade.nest_signal.desc": "获得两架无人机和更大的磁力范围。",
	},
}

func current_language() -> String:
	if has_node("/root/SettingsStore"):
		return String(SettingsStore.language)
	return EN

func t(key: String) -> String:
	var language := current_language()
	var table: Dictionary = TEXT.get(language, TEXT[EN])
	if table.has(key):
		return String(table[key])
	return String(TEXT[EN].get(key, key))

func format(key: String, values: Array = []) -> String:
	return t(key) % values

func label_for_options(keys: Array) -> Array:
	var labels: Array = []
	for key in keys:
		labels.append(t(String(key)))
	return labels

func difficulty_labels() -> Array:
	return label_for_options(["labels.easy", "labels.normal", "labels.hard"])

func speed_labels() -> Array:
	return label_for_options(["labels.slow", "labels.normal", "labels.fast"])

func effects_labels() -> Array:
	return label_for_options(["labels.low", "labels.balanced", "labels.high"])

func minimap_size_labels() -> Array:
	return label_for_options(["labels.compact", "labels.standard", "labels.large"])

func language_labels() -> Array:
	return [t("language.en"), t("language.zh")]

func language_index(language: String) -> int:
	var index := LANGUAGES.find(language)
	return maxi(0, index)

func translate_title(title: String) -> String:
	match title:
		"Lone Snake": return t("title.lone_snake")
		"Rising Fang": return t("title.rising_fang")
		"Armored Coil": return t("title.armored_coil")
		"Venom Crown": return t("title.venom_crown")
		"Snake King": return t("title.snake_king")
		"Brood King": return t("title.brood_king")
		"Mine Tyrant": return t("title.mine_tyrant")
		"Beam Regent": return t("title.beam_regent")
		"Devourer King": return t("title.devourer_king")
		"Snake Emperor": return t("title.snake_emperor")
		_: return title

func translate_enemy(name: String) -> String:
	match name:
		"Hunter": return t("enemy.hunter")
		"Dasher": return t("enemy.dasher")
		"Shellback": return t("enemy.shellback")
		"Venom": return t("enemy.venom")
		"Splitter": return t("enemy.splitter")
		"Broodcaller": return t("enemy.broodcaller")
		"Minecoil": return t("enemy.minecoil")
		"Beamer": return t("enemy.beamer")
		"Devourer": return t("enemy.devourer")
		"Emperor Core": return t("enemy.emperor_core")
		_: return name

func translate_upgrade_name(upgrade: Dictionary) -> String:
	var id := String(upgrade.get("id", ""))
	if UPGRADE_NAME_KEYS.has(id):
		return t(String(UPGRADE_NAME_KEYS[id]))
	return String(upgrade.get("name", t("common.unknown")))

func translate_upgrade_description(upgrade: Dictionary) -> String:
	var id := String(upgrade.get("id", ""))
	if UPGRADE_DESCRIPTION_KEYS.has(id):
		return t(String(UPGRADE_DESCRIPTION_KEYS[id]))
	return String(upgrade.get("description", ""))

func translate_tag(tag: String) -> String:
	if TAG_KEYS.has(tag):
		return t(String(TAG_KEYS[tag]))
	return tag

func translate_tags(tags: Array) -> Array:
	var translated: Array = []
	for tag in tags:
		translated.append(translate_tag(String(tag)))
	return translated

func join_tags(tags: Array, fallback_key := "common.none") -> String:
	if tags.is_empty():
		return t(fallback_key)
	return ", ".join(translate_tags(tags))

func translate_death_reason(reason: String) -> String:
	if DEATH_REASON_KEYS.has(reason):
		return t(String(DEATH_REASON_KEYS[reason]))
	return reason

func wave_event(wave: int, fallback: String) -> String:
	var key := "event.wave_%d" % wave
	var value := t(key)
	return value if value != key else fallback

func wave_story(wave: int, fallback: String) -> String:
	var key := "story.wave_%d" % wave
	var value := t(key)
	return value if value != key else fallback

func terrain_wave_story(wave: int) -> String:
	if wave <= 1:
		return t("story.start")
	if wave == 2:
		return t("terrain.wave_2")
	if wave == 3:
		return t("terrain.wave_3")
	return format("terrain.wave_generic", [wave])
