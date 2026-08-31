extends TestCase
## apply_player 必须还原朝向，并广播毒素，避免 HUD 停在读档前的档位。


func setup() -> void:
	SaveData.save_path = "user://rustgrave_test_save_facing.cfg"
	SaveData.delete_save()


func teardown() -> void:
	SaveData.delete_save()
	SaveData.save_path = "user://rustgrave_save.cfg"


func test_apply_player_restores_facing_and_emits_toxin() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	player.controller.facing = -1
	player.visual.scale.x = -1.0
	player.toxin.toxin = 60.0
	ok(SaveData.save_game("res://scenes/levels/Level01_Static.tscn", player))
	player.controller.facing = 1
	player.visual.scale.x = 1.0
	player.toxin.toxin = 0.0
	ok(SaveData.load_game())
	eq(int(SaveData.data["player"]["facing"]), -1)
	var heard := [0.0]
	GameEvents.toxin_changed.connect(func(cur: float, _m: float) -> void: heard[0] = cur, CONNECT_ONE_SHOT)
	SaveData.apply_player(player)
	eq(player.controller.facing, -1, "facing restored")
	eq(int(player.visual.scale.x), -1, "sprite faces the saved side")
	almost(player.toxin.toxin, 60.0, 0.01)
	almost(heard[0], 60.0, 0.01, "apply_player emits toxin_changed for HUD")
