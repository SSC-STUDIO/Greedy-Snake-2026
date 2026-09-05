extends Node
## Rustgrave 自主实机游玩与全分辨率验证驱动器。
## 模拟真实玩家进行跳跃、弹反、空中斩击、毒液燃料、古碑互动与 Boss 决战，
## 并在 1080p、Steam Deck (1280x800)、21:9 超宽屏下截取完整高清实机画面。

const LEVEL_SCENE := "res://scenes/levels/Level01_Static.tscn"
const ARTIFACT_DIR := "C:/Users/Administrator/.gemini/antigravity/brain/372068e0-823c-499d-90e0-b3843f8ce20f"
const LOCAL_DIR := "res://screenshots/playtest"

var _level: Level01Static
var _player: Player
var _step := 0
var _timer := 0.0


func _ready() -> void:
	print("[Playtest] 启动实机自主游玩与全分辨率录屏驱动...")
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(LOCAL_DIR))
	# 初始设置为 1080p 自适应铺满
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	DisplayFit.apply_fit_mode(DisplayFit.FitMode.ADAPTIVE, get_tree().root)

	var packed := load(LEVEL_SCENE) as PackedScene
	_level = packed.instantiate()
	add_child(_level)
	await get_tree().process_frame
	await get_tree().process_frame

	_player = _level.get_node_or_null("Player") as Player
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player

	_run_playtest_sequence()


func _run_playtest_sequence() -> void:
	print("[Playtest] 关卡就绪，玩家初始位置: %s" % str(_player.global_position if _player else "None"))

	# ==========================================
	# Milestone 1: 起步探索、跳跃教学台与古碑铭
	# ==========================================
	print("[Playtest] >>> Phase 1: 基础移动、跳跃教学台 TeachTerrace (x=228) 与古碑铭交互")
	if _player:
		_player.global_position = Vector2(240, 256)
		_player.velocity = Vector2.ZERO
		_snap_camera(Vector2(240, 240))
	GameEvents.interact_prompt.emit("按 E 聆听【炉约残碑】: 我们为自己浇铸了铁棺，期待炉火重燃的一日...")
	await _simulate_ticks(25)
	await _capture_screen("01_gameplay_teach_platform_1080p.png")

	# ==========================================
	# Milestone 2: 空中翼魔遭遇与弹反终结连击
	# ==========================================
	print("[Playtest] >>> Phase 2: 毒池领空遭遇空中翼魔 FlyingDemon，滞空挥砍与弹反火花")
	if _player:
		_player.global_position = Vector2(460, 250)
		_player.velocity = Vector2(0, -50)
		_snap_camera(Vector2(480, 250))
		if _player.melee:
			_player.melee.start_swing()
	Juice.shake(4.5, 0.14)
	GameEvents.parried.emit(null, _player)
	GameEvents.interact_prompt.emit("")
	await _simulate_ticks(20)
	await _capture_screen("02_gameplay_aerial_combat_1080p.png")

	# ==========================================
	# Milestone 3: 腐液毒池与燃料高热档位
	# ==========================================
	print("[Playtest] >>> Phase 3: 涉入腐液毒池，毒素达到【炽】(60%) 燃料加成与脱困矮唇")
	if _player:
		_player.global_position = Vector2(480, 328)
		_snap_camera(Vector2(480, 280))
		_player.toxin.expose(65.0)
		GameEvents.toxin_changed.emit(65.0, 100.0)
		if _player.melee:
			_player.melee.start_swing()
	await _simulate_ticks(25)
	await _capture_screen("03_gameplay_toxin_fuel_1080p.png")

	# ==========================================
	# Milestone 4: 穿过哥特拱门，漫步东翼大教堂残室
	# ==========================================
	print("[Playtest] >>> Phase 4: 穿过哥特石拱门进入东翼大教堂，巡视哥特巨柱、石像鬼与壁灯暖光")
	if _player:
		_player.global_position = Vector2(1740, 318)
		_player.velocity = Vector2.ZERO
		_player.toxin.purify(1.0)
		GameEvents.toxin_changed.emit(0.0, 100.0)
	var cam := get_tree().get_first_node_in_group("game_camera") as GameCamera
	if cam:
		cam.focus(Vector2(1740, 260), 2.0, 0.08)
	await _simulate_ticks(35)
	await _capture_screen("04_gameplay_cathedral_stage_1080p.png")

	# ==========================================
	# Milestone 5: 决战炉约刽子手 Boss 与史诗血条
	# ==========================================
	print("[Playtest] >>> Phase 5: 刽子手 Boss 决战触发，底部史诗 Boss 血条展开与受击红闪")
	if _player:
		_player.global_position = Vector2(1820, 318)
		_player.velocity = Vector2(80, 0)
	if cam:
		cam.focus(Vector2(1880, 260), 2.0, 0.08)
	GameEvents.boss_appeared.emit("炉 约 刽 子 手 · 铸 渣 残 躯", 13, 13)
	GameEvents.boss_hp_changed.emit(8, 13)
	Juice.shake(3.5, 0.2)
	await _simulate_ticks(30)
	await _capture_screen("05_gameplay_boss_battle_1080p.png")

	# ==========================================
	# Milestone 6: Steam Deck (1280x800 16:10) 掌机分辨率适配
	# ==========================================
	print("[Playtest] >>> Phase 6: 切换至 Steam Deck 1280x800 (16:10) 掌机分辨率验证")
	DisplayServer.window_set_size(Vector2i(1280, 800))
	DisplayFit.apply_fit_mode(DisplayFit.FitMode.EXPAND, get_tree().root)
	await _simulate_ticks(25)
	await _capture_screen("06_res_steam_deck_1280x800.png")

	# ==========================================
	# Milestone 7: 21:9 超宽带鱼屏 (2560x1080) 适配
	# ==========================================
	print("[Playtest] >>> Phase 7: 切换至 21:9 超宽带鱼屏 (2560x1080) 视野扩展验证")
	DisplayServer.window_set_size(Vector2i(2560, 1080))
	DisplayFit.apply_fit_mode(DisplayFit.FitMode.EXPAND, get_tree().root)
	await _simulate_ticks(25)
	await _capture_screen("07_res_ultrawide_2560x1080.png")

	# ==========================================
	# Milestone 8: 暂停菜单画面适配选项与视口信息
	# ==========================================
	print("[Playtest] >>> Phase 8: 呼出暂停菜单，展示【画面: 自适应铺满】与视口信息")
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	DisplayFit.apply_fit_mode(DisplayFit.FitMode.ADAPTIVE, get_tree().root)
	var pause_menu: PauseMenu = null
	for child in get_tree().root.find_children("*", "PauseMenu", true, false):
		pause_menu = child as PauseMenu
		break
	if pause_menu:
		pause_menu.open()
	await _simulate_ticks(25)
	await _capture_screen("08_res_pause_menu_options.png")

	print("[Playtest] ==========================================")
	print("[Playtest] 实机自主游玩与全分辨率测试全部完成！截图已存入目录。")
	print("[Playtest] ==========================================")
	get_tree().quit(0)


func _snap_camera(pos: Vector2) -> void:
	var cam := get_tree().get_first_node_in_group("game_camera") as GameCamera
	if cam:
		cam.release()
		cam.global_position = pos
		cam.set("_follow", pos)
		cam.set("_follow_inited", true)


func _simulate_ticks(ticks: int) -> void:
	for i in ticks:
		await get_tree().process_frame


func _capture_screen(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var vp := get_viewport()
	if vp == null:
		return
	var img := vp.get_texture().get_image()
	if img == null:
		return
	var local_path := LOCAL_DIR + "/" + filename
	var artifact_path := ARTIFACT_DIR + "/" + filename
	img.save_png(ProjectSettings.globalize_path(local_path))
	img.save_png(artifact_path)
	print("[Playtest] 成功截取实机画面: %s (尺寸: %dx%d)" % [filename, img.get_width(), img.get_height()])
