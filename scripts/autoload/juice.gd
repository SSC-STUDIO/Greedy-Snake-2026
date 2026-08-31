extends Node
## Juice autoload: hit-stop, slow-mo, screen-flash, and camera-shake effects.
## All triggers arrive through the GameEvents signal bus so gameplay modules
## stay decoupled from presentation. Timers use wall-clock milliseconds so
## restoring Engine.time_scale is immune to time_scale itself.

const PRIORITY_HIT := 1
const PRIORITY_PARRY := 2
const PRIORITY_DEATH := 3

## Headless runs never build the overlay nor touch audio-visual state,
## but time-scale effects still resolve deterministically for logic tests.
var _headless := false

var _restore_at_ms: int = 0
var _priority: int = 0

var _flash_layer: CanvasLayer
var _flash_rect: ColorRect

var _shake_intensity := 0.0
var _shake_start_ms := 0
var _shake_end_ms := 0
var _shake_cam: GameCamera = null


func _ready() -> void:
	_headless = DisplayServer.get_name() == "headless"
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not _headless:
		_build_flash_layer()
	GameEvents.hit.connect(_on_hit)
	GameEvents.parried.connect(_on_parried)
	GameEvents.player_died.connect(_on_player_died)


func _process(_delta: float) -> void:
	if Engine.time_scale != 1.0 and Time.get_ticks_msec() >= _restore_at_ms:
		Engine.time_scale = 1.0
		_priority = 0
	if not _headless:
		_update_shake_offset()
		DisplayServer.window_set_title("Rustgrave")


func hit_stop(duration_ms: int, time_scale: float = 0.05) -> void:
	_apply(duration_ms, time_scale, PRIORITY_HIT)


func slow_mo(duration_ms: int, time_scale: float = 0.25) -> void:
	_apply(duration_ms, time_scale, PRIORITY_PARRY)


## Random decaying camera shake in pixels, wall-clock timed so it runs
## identically through hit-stop and slow-mo. Presentation only: it writes
## GameCamera.shake_offset, never gameplay positions. Headless is a full
## no-op — no camera lookup, no coordinate writes.
func shake(intensity_px: float, duration_ms: int) -> void:
	if _headless:
		return
	var now := Time.get_ticks_msec()
	if intensity_px < _shake_intensity and now + duration_ms <= _shake_end_ms:
		return  # A weaker jolt never cuts a stronger ongoing one short.
	_shake_intensity = maxf(intensity_px, 0.0)
	_shake_start_ms = now
	_shake_end_ms = now + maxi(duration_ms, 0)


func _apply(duration_ms: int, time_scale: float, priority: int) -> void:
	if priority < _priority and Engine.time_scale != 1.0:
		return  # Never downgrade an ongoing strong effect.
	var now := Time.get_ticks_msec()
	if priority == _priority and now + duration_ms <= _restore_at_ms:
		return  # Already frozen at least as long.
	Engine.time_scale = clampf(time_scale, 0.01, 1.0)
	_restore_at_ms = now + duration_ms
	_priority = priority


func flash(color: Color, duration_ms: int) -> void:
	if _headless or _flash_rect == null:
		return
	_flash_rect.color = color
	_flash_rect.modulate.a = color.a
	var tween := create_tween()
	tween.tween_property(_flash_rect, "modulate:a", 0.0, maxf(0.03, duration_ms / 1000.0))


func _build_flash_layer() -> void:
	_flash_layer = CanvasLayer.new()
	_flash_layer.layer = 90
	add_child(_flash_layer)
	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.modulate.a = 0.0
	_flash_layer.add_child(_flash_rect)


func _update_shake_offset() -> void:
	if _shake_intensity <= 0.0:
		return
	var cam := _shake_camera()
	if cam == null:
		return
	var now := Time.get_ticks_msec()
	if now >= _shake_end_ms:
		_shake_intensity = 0.0
		cam.shake_offset = Vector2.ZERO
		return
	var span := maxf(1.0, float(_shake_end_ms - _shake_start_ms))
	var energy := float(_shake_end_ms - now) / span
	var jitter := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	cam.shake_offset = jitter * (_shake_intensity * energy)


## The active camera registers itself in the "game_camera" group. Cache it
## and rebind when a scene reload invalidates the old reference.
func _shake_camera() -> GameCamera:
	if _shake_cam != null and is_instance_valid(_shake_cam) and _shake_cam.is_inside_tree():
		return _shake_cam
	_shake_cam = null
	for node in get_tree().get_nodes_in_group("game_camera"):
		var cam := node as GameCamera
		if cam == null:
			continue
		if cam.is_current():
			_shake_cam = cam
			break
		if _shake_cam == null:
			_shake_cam = cam
	return _shake_cam


func _on_hit(attacker: Node, target: Node, amount: int) -> void:
	if attacker == null or target == null:
		return
	if target.is_in_group("player"):
		flash(Color(0.72, 0.22, 0.14, 0.5), 90)
		hit_stop(60, 0.08)
		shake(4.0, 160)
	else:
		# Landing a blow still deserves a beat — shorter and punchier.
		hit_stop(40, 0.12)
		shake(2.0, 90)
		if target is Node2D:
			Fx.hit_sparks((target as Node2D).global_position)


func _on_parried(projectile: Node, _by_actor: Node) -> void:
	slow_mo(120, 0.25)
	flash(Color(0.98, 0.93, 0.82, 0.85), 140)
	shake(3.0, 150)
	if projectile is Node2D:
		Fx.hit_sparks((projectile as Node2D).global_position)


func _on_player_died() -> void:
	flash(Color(0.09, 0.06, 0.05, 0.9), 700)
	slow_mo(650, 0.15)
	shake(6.0, 500)