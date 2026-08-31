extends Node
## SaveData autoload: persist player + world state to user://rustgrave_save.cfg.
## Pure data — works identically in headless runs. Call save_game(node, player)
## from an Ember Nest; load_game() reads the file back into the dictionary.
##
## World persistence: any node in the "persistent" group exports a snapshot via
## get_persistent_state() and restores it via apply_persistent_state(). The
## save stores that data keyed by the node's absolute scene path, which is
## stable because Level01 remains a single static scene.

const SAVE_VERSION := 1

var save_path := "user://rustgrave_save.cfg"

## Currently loaded save dictionary (empty until load_game / save_game).
## Structure:
##   meta      = { version, scene, saved_at }
##   player    = { hp, max_hp, toxin, max_toxin, pos (Vector2), facing }
##   inventory = { pouch: [core ids], sockets: [core ids or ""] }
##   world     = { "/root/Level01../Props/Door": {...}, ... }
var data: Dictionary = {}

## One-shot spawn override consumed by a level right after it instantiates the
## player. Set by respawn flow so the player appears at the last Ember Nest.
var pending_spawn: Vector2 = Vector2.INF

## Absolute node paths of one-shot interactables that died (picked up cores,
## used filter gears, melted gates). Persisted even though their nodes are
## freed from the tree, and replayed to remove them on every reload.
var consumed: PackedStringArray = []

## Ember Nests lit so far; the last one is the respawn point. Stored as scene
## paths so levels can recompute the spawn even before replaying world state.
var lit_nests: PackedStringArray = []

## One-shot story beats already shown (wake, first toxin, first parry…).
var flags: PackedStringArray = []
## "rekindle" / "snuff" once the forge heart is chosen.
var ending: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func has_save() -> bool:
	return FileAccess.file_exists(save_path)

func save_game(scene_path: String, player: Node) -> bool:
	var player_state := _collect_player(player)
	var inv_state := _collect_inventory(player)
	player_state["pouch"] = inv_state["pouch"]
	player_state["sockets"] = inv_state["sockets"]
	var world := _collect_world()
	var cfg := ConfigFile.new()
	data = {
		"meta": {
			"version": SAVE_VERSION,
			"scene": scene_path,
			"saved_at": Time.get_datetime_string_from_system(),
		},
		"player": player_state,
		"world": world,
	}
	cfg.set_value("meta", "version", SAVE_VERSION)
	cfg.set_value("meta", "scene", scene_path)
	cfg.set_value("meta", "saved_at", data["meta"]["saved_at"])
	var ps: Dictionary = player_state
	cfg.set_value("player", "hp", ps.get("hp", 0))
	cfg.set_value("player", "max_hp", ps.get("max_hp", 1))
	cfg.set_value("player", "toxin", ps.get("toxin", 0.0))
	cfg.set_value("player", "max_toxin", ps.get("max_toxin", 100.0))
	cfg.set_value("player", "pos_x", (ps.get("pos", Vector2.ZERO) as Vector2).x)
	cfg.set_value("player", "pos_y", (ps.get("pos", Vector2.ZERO) as Vector2).y)
	cfg.set_value("player", "facing", ps.get("facing", 1))
	var pouch_ids: Array = []
	for core in ps.get("pouch", []):
		pouch_ids.append(core)
	cfg.set_value("player", "pouch", pouch_ids)
	var socket_ids: Array = []
	for core in ps.get("sockets", []):
		socket_ids.append(core)
	cfg.set_value("player", "sockets", socket_ids)
	for key in world:
		cfg.set_value("world", key, world[key])
	cfg.set_value("consumed", "paths", Array(consumed))
	cfg.set_value("lit_nests", "paths", Array(lit_nests))
	cfg.set_value("story", "flags", Array(flags))
	cfg.set_value("meta", "ending", ending)
	var err := cfg.save(save_path)
	if err != OK:
		push_warning("SaveData: failed to save to %s (err %d)" % [save_path, err])
		return false
	GameEvents.game_saved.emit()
	return true

func load_game() -> bool:
	if not has_save():
		data = {}
		return false
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		data = {}
		return false
	data = {}
	data["meta"] = {
		"version": cfg.get_value("meta", "version", 1),
		"scene": cfg.get_value("meta", "scene", ""),
		"saved_at": cfg.get_value("meta", "saved_at", ""),
	}
	data["player"] = {
		"hp": cfg.get_value("player", "hp", 0),
		"max_hp": cfg.get_value("player", "max_hp", 5),
		"toxin": cfg.get_value("player", "toxin", 0.0),
		"max_toxin": cfg.get_value("player", "max_toxin", 100.0),
		"pos": Vector2(cfg.get_value("player", "pos_x", 0.0), cfg.get_value("player", "pos_y", 0.0)),
		"facing": cfg.get_value("player", "facing", 1),
		"pouch": cfg.get_value("player", "pouch", []),
		"sockets": cfg.get_value("player", "sockets", []),
	}
	data["world"] = {}
	if cfg.has_section("world"):
		for key in cfg.get_section_keys("world"):
			data["world"][key] = cfg.get_value("world", key)
	consumed.clear()
	for p in cfg.get_value("consumed", "paths", []):
		consumed.append(String(p))
	lit_nests.clear()
	for p in cfg.get_value("lit_nests", "paths", []):
		lit_nests.append(String(p))
	flags.clear()
	for f in cfg.get_value("story", "flags", []):
		flags.append(String(f))
	ending = String(cfg.get_value("meta", "ending", ""))
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(save_path)
	data = {}
	consumed.clear()
	lit_nests.clear()
	flags.clear()
	ending = ""


## Record that a one-shot interactable at `path` has been consumed (picked up,
## used, melted). Survives node free because it's a plain path list.
func mark_consumed(path: String) -> void:
	if not consumed.has(path):
		consumed.append(path)


func is_consumed(path: String) -> bool:
	return consumed.has(path)


## Remove from the freshly-built scene every one-shot node that was consumed.
func apply_consumed(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	for p in consumed:
		var target := node.get_node_or_null(p)
		if target != null and is_instance_valid(target):
			target.queue_free()


func register_lit_nest(path: String) -> void:
	if not lit_nests.has(path):
		lit_nests.append(path)


func last_lit_nest() -> String:
	return lit_nests[lit_nests.size() - 1] if not lit_nests.is_empty() else ""


func mark_flag(id: String) -> void:
	if not flags.has(id):
		flags.append(id)


func has_flag(id: String) -> bool:
	return flags.has(id)


func peek_ending() -> String:
	if ending != "":
		return ending
	if not has_save():
		return ""
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return ""
	return String(cfg.get_value("meta", "ending", ""))

## Pull a player node's live state into the data dict.
func _collect_player(player: Node) -> Dictionary:
	if player == null:
		return {}
	var hp := player.get_node_or_null("Health") as Health
	var tox := player.get_node_or_null("ToxinMeter") as ToxinMeter
	var state: Dictionary = {}
	state["hp"] = hp.current if hp else 0
	state["max_hp"] = hp.max_hp if hp else 5
	state["toxin"] = tox.toxin if tox else 0.0
	state["max_toxin"] = tox.max_toxin if tox else 100.0
	state["pos"] = player.global_position
	state["facing"] = 1
	if player is Player:
		state["facing"] = (player as Player).controller.facing
	return state


func _collect_inventory(player: Node) -> Dictionary:
	if player is Player:
		var inv := (player as Player).inventory
		var pouch_ids: Array = []
		for core in inv.pouch:
			if core is RustCore:
				pouch_ids.append(String((core as RustCore).id))
		var socket_ids: Array = []
		for core in inv.sockets:
			socket_ids.append(String((core as RustCore).id) if core is RustCore else "")
		return {"pouch": pouch_ids, "sockets": socket_ids}
	return {"pouch": [], "sockets": []}


func _collect_world() -> Dictionary:
	var world: Dictionary = {}
	for node in get_tree().get_nodes_in_group("persistent"):
		if not node.has_method("get_persistent_state"):
			continue
		var state: Dictionary = node.get_persistent_state()
		if not state.is_empty():
			world[String(node.get_path())] = state
	return world


## After a respawn, replay stored world state onto the freshly-built scene.
func apply_world(node: Node) -> void:
	if data.is_empty() or not data.has("world"):
		return
	if node == null or not is_instance_valid(node):
		return
	for key in data["world"]:
		var target := node.get_node_or_null(String(key))
		if target == null or not target.has_method("apply_persistent_state"):
			continue
		target.apply_persistent_state(data["world"][key])


## Populate a freshly-instantiated player from the stored save.
func apply_player(player: Node) -> void:
	if player == null or data.is_empty() or not data.has("player"):
		return
	var p: Dictionary = data["player"]
	var hp := player.get_node_or_null("Health") as Health
	if hp:
		hp.max_hp = int(p.get("max_hp", hp.max_hp))
		hp.current = clampi(int(p.get("hp", hp.max_hp)), 0, hp.max_hp)
		hp.changed.emit(hp.current, hp.max_hp)
	var tox := player.get_node_or_null("ToxinMeter") as ToxinMeter
	if tox:
		tox.toxin = clampf(float(p.get("toxin", 0.0)), 0.0, tox.max_toxin)
	if player is Player:
		var inv := (player as Player).inventory
		inv.pouch.clear()
		inv.sockets.clear()
		for i in inv.socket_count:
			inv.sockets.append(null)
		for id_str in p.get("pouch", []):
			var core := AbilityCatalog.for_id(StringName(id_str))
			if core:
				inv.pouch.append(core)
		var sockets: Array = p.get("sockets", [])
		for i in mini(sockets.size(), inv.socket_count):
			var id_str: String = sockets[i]
			if id_str == "":
				continue
			var core := AbilityCatalog.for_id(StringName(id_str))
			if core:
				inv.sockets[i] = core
		inv.sockets_changed.emit()
		inv.pouch_changed.emit()


## Record the scene we should boot into and the spawn point, then reload there.
func respawn(scene_path: String, spawn: Vector2) -> void:
	pending_spawn = spawn
	Director.fade_to(scene_path)


func consume_pending_spawn() -> Vector2:
	var v := pending_spawn
	pending_spawn = Vector2.INF
	return v


func has_pending_spawn() -> bool:
	return pending_spawn != Vector2.INF
