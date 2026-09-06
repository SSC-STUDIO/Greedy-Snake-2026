extends Node2D
## Fx autoload: presentation-only particle effects — drifting embers, dust
## puffs, weapon-hit sparks, rust debris, and toxin bubbles. Pure visuals,
## never gameplay state. Headless runs and missing art degrade silently.
##
## Particles are lightweight self-managing Node2D/Polygon2D squares or
## Sprite2D sheet cuts (no GPUParticles2D). One-shot effects parent here in
## world space and free themselves; attach_ember parents to its target so
## scene reloads clean it up automatically.

const WEAPONHIT_SHEET_PATH := "res://assets/kenney_clean/vfx/10_weaponhit_spritesheet.png"
const BUBBLES_SHEET_PATH := "res://assets/kenney_clean/vfx/20_magicbubbles_spritesheet.png"
const BRIGHTFIRE_SHEET_PATH := "res://assets/kenney_clean/vfx/9_brightfire_spritesheet.png"

## One-shot particles live under this autoload, which sits early in the tree
## (autoloads come before the current scene), so z_index must lift them above
## scene content to stay visible.
const FX_Z := 100

const EMBER_FIELD_NAME := "FxEmberField"

var _headless := false
var _weaponhit_sheet: Texture2D = null
var _bubbles_sheet: Texture2D = null
var _brightfire_sheet: Texture2D = null
static var _additive: CanvasItemMaterial = null


## Shared additive material so night CanvasModulate cannot crush 2px motes.
static func additive_mat() -> CanvasItemMaterial:
	if _additive == null:
		_additive = CanvasItemMaterial.new()
		_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _additive


func _ready() -> void:
	_headless = DisplayServer.get_name() == "headless"
	if _headless:
		set_process(false)
		return
	if ResourceLoader.exists(WEAPONHIT_SHEET_PATH):
		_weaponhit_sheet = load(WEAPONHIT_SHEET_PATH) as Texture2D
	if ResourceLoader.exists(BUBBLES_SHEET_PATH):
		_bubbles_sheet = load(BUBBLES_SHEET_PATH) as Texture2D
	if ResourceLoader.exists(BRIGHTFIRE_SHEET_PATH):
		_brightfire_sheet = load(BRIGHTFIRE_SHEET_PATH) as Texture2D


## One-shot particles must render inside the world viewport. The level runs in
## GamePresentation's 640×360 SubViewport with its own World2D and camera, so
## anything parented to this autoload would sit in root-window space and never
## line up with the knight. Fall back to self for standalone scenes (TestArena).
func _effects_host() -> Node:
	var scene_tree := get_tree()
	if scene_tree != null and scene_tree.get_first_node_in_group("game_world") != null:
		var host := GameContext.world_effects()
		if host != null and host.is_inside_tree():
			return host
	return self


## Persistent embers drifting around a living actor (the ember knight keeps
## its trail). Idempotent: repeated calls never stack. The emitter parents to
## the target so death / reload_scene clears it with the target itself.
func attach_ember(target: Node2D) -> void:
	if _headless or target == null or not is_instance_valid(target):
		return
	if target.get_node_or_null(EMBER_FIELD_NAME) != null:
		return
	var field := EmberField.new()
	field.name = EMBER_FIELD_NAME
	field.sheet = _brightfire_sheet
	target.add_child(field)


## Dust kicked up by landing or dashing. `dir` is the outward heading in
## radians (0.0 = right); motes scatter outward with an upward bias.
func dust_puff(pos: Vector2, dir: float = 0.0) -> void:
	if _headless:
		return
	var host := _effects_host()
	for i in randi_range(4, 6):
		var mote := DustMote.new()
		mote.launch(pos, dir)
		mote.z_index = FX_Z
		host.add_child(mote)


## Weapon-hit flash: first six frames of the CC0 Kenney/CodeManu sheet,
## ~0.25 s end to end, then freed. Missing art degrades to nothing.
func hit_sparks(pos: Vector2) -> void:
	if _headless or _weaponhit_sheet == null:
		return
	var spark := HitSpark.new(_weaponhit_sheet)
	spark.position = pos
	spark.z_index = FX_Z
	_effects_host().add_child(spark)


## Rust debris bursting out of a destroyed enemy: gravity, a floor bounce,
## then gone.
func rust_debris(pos: Vector2) -> void:
	if _headless:
		return
	var host := _effects_host()
	for i in randi_range(6, 8):
		var bit := RustDebris.new()
		bit.launch(pos)
		bit.z_index = FX_Z
		host.add_child(bit)


## 世界坐标一次性帧动画（敌人死亡尸体动画/烟雾等）。播完自毁；headless 或
## 空帧列表时静默退化——调用方逻辑（queue_free 等）不受影响。
## `pos` 为脚底世界坐标；`baseline` 为帧画布内容的基线偏移
## （centered Sprite：-(画布高/2 - 底部透明边距)）。
func play_frames_once(frames: Array[Texture2D], pos: Vector2, fps: float,
		flip: bool = false, baseline: float = 0.0) -> void:
	if _headless or frames.is_empty():
		return
	var player := OneShotFrames.new(frames, fps)
	player.position = pos + Vector2(0.0, baseline)
	player.flip_h = flip
	player.z_index = FX_Z
	_effects_host().add_child(player)


## 通用敌人死亡烟雾（Gothicvania cemetery 5 帧，44x52，底部留白 2px）。
func enemy_death_smoke(pos: Vector2) -> void:
	play_frames_once(CharFrames.anim("fx_enemy_death", "death"), pos, 12.0, false, -24.0)


## One toxin bubble rising out of `rect` (parent-local coordinates) and
## popping as it fades. Tinted orange, pressed toward Palette.TOXIC.
func toxin_bubbles(parent: Node2D, rect: Rect2) -> void:
	if _headless or _bubbles_sheet == null:
		return
	if parent == null or not is_instance_valid(parent):
		return
	var bubble := ToxinBubble.new(_bubbles_sheet)
	bubble.position = rect.position + Vector2(randf() * rect.size.x, randf() * rect.size.y)
	bubble.modulate = Color(0.45, 0.78, 0.55, 0.75)
	parent.add_child(bubble)


## 一次性帧序列播放器：固定 fps 播完即自由。像素素材 NEAREST。
class OneShotFrames extends Sprite2D:
	var _frames: Array[Texture2D] = []
	var _fps := 12.0
	var _age := 0.0


	func _init(frames: Array[Texture2D], fps: float) -> void:
		_frames = frames
		_fps = maxf(fps, 0.001)
		texture = _frames[0]
		centered = true
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


	func _process(delta: float) -> void:
		_age += delta
		var idx := int(_age * _fps)
		if idx >= _frames.size():
			queue_free()
			return
		if texture != _frames[idx]:
			texture = _frames[idx]


## Spawns and owns up to six drifting embers around the target's body.
## Actor origins sit near the feet, so embers spread upward and sideways.
class EmberField extends Node2D:
	const MAX_EMBERS := 3
	const SPAWN_INTERVAL := 0.7

	## brightfire 帧动画表（可为 null → EmberBit 回退为色块方形）。
	var sheet: Texture2D = null

	var _accum := 0.25


	func _process(delta: float) -> void:
		_accum += delta
		if _accum >= SPAWN_INTERVAL and get_child_count() < MAX_EMBERS:
			_accum = 0.0
			var bit := EmberBit.new(sheet)
			bit.position = Vector2(randf_range(-8.0, 8.0), randf_range(-40.0, -12.0))
			add_child(bit)


## One rising, swaying, fading ember. With the brightfire sheet available it
## plays a tiny flame-lick animation; otherwise an orange square (2-3 px).
class EmberBit extends Node2D:
	## brightfire: 8x8 grid of 100px frames, 61 frames populated.
	const SHEET_HFRAMES := 8
	const SHEET_VFRAMES := 8
	const SHEET_FRAME_COUNT := 61
	const FRAME_STEP := 0.09

	var _age := 0.0
	var _lifetime := 2.0
	var _rise := 8.0
	var _sway_amp := 6.0
	var _sway_freq := 2.0
	var _phase := 0.0
	var _sheet: Texture2D = null
	var _sprite: Sprite2D = null
	var _frame_start := 0


	func _init(sheet: Texture2D = null) -> void:
		_sheet = sheet
		_lifetime = randf_range(1.5, 3.0)
		_rise = randf_range(5.0, 12.0)
		_sway_amp = randf_range(4.0, 10.0)
		_sway_freq = randf_range(1.5, 3.5)
		_phase = randf() * TAU


	func _ready() -> void:
		if _sheet != null:
			_sprite = Sprite2D.new()
			_sprite.texture = _sheet
			_sprite.hframes = SHEET_HFRAMES
			_sprite.vframes = SHEET_VFRAMES
			_frame_start = randi_range(0, SHEET_FRAME_COUNT - 1)
			_sprite.frame = _frame_start
			# 100px 帧里的火苗 ~20px 高；缩到 ~5px 的余烬尺度。
			var s := randf_range(0.035, 0.055)
			_sprite.scale = Vector2(s, s)
			_sprite.modulate = Color(1.0, 0.62, 0.38, 0.55)
			add_child(_sprite)
			return
		var half := randf_range(1.0, 1.5)
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(-half, -half), Vector2(half, -half),
			Vector2(half, half), Vector2(-half, half),
		])
		poly.color = Palette.EMBER.lerp(Palette.TOXIC, randf() * 0.7)
		add_child(poly)


	func _process(delta: float) -> void:
		_age += delta
		if _age >= _lifetime:
			queue_free()
			return
		position.y -= _rise * delta
		position.x += sin(_age * _sway_freq + _phase) * _sway_amp * delta
		if _sprite != null:
			_sprite.frame = (_frame_start + int(_age / FRAME_STEP)) % SHEET_FRAME_COUNT
		var k := _age / _lifetime
		modulate.a = minf(k * 8.0, 1.0) * (1.0 - k)


## A gray dust square scattering outward and upward, then settling and
## dissolving.
class DustMote extends Node2D:
	var _velocity := Vector2.ZERO
	## Sub-pixel position; `position` is snapped so NEAREST never smears.
	var _drift := Vector2.ZERO
	var _age := 0.0
	var _lifetime := 0.5


	func _init() -> void:
		_lifetime = randf_range(0.35, 0.6)


	func launch(pos: Vector2, dir: float) -> void:
		_drift = pos
		position = Vector2(roundf(pos.x), roundf(pos.y))
		var angle := dir + randf_range(-0.85, 0.85)
		var speed := randf_range(26.0, 62.0)
		_velocity = Vector2(cos(angle), sin(angle)) * speed
		_velocity.y -= randf_range(18.0, 42.0)


	func _ready() -> void:
		var half := randf_range(1.2, 1.8)
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(-half, -half), Vector2(half, -half),
			Vector2(half, half), Vector2(-half, half),
		])
		# 夜廊的 CanvasModulate 会把中灰压成看不见；加法 + 提亮后落地尘在夜色里仍可读。
		poly.color = Palette.IRON.lerp(Palette.CONCRETE, randf()) * 1.35
		poly.material = Fx.additive_mat()
		add_child(poly)


	func _process(delta: float) -> void:
		_age += delta
		if _age >= _lifetime:
			queue_free()
			return
		_velocity.x *= maxf(0.0, 1.0 - 3.2 * delta)
		_velocity.y += 90.0 * delta
		_drift += _velocity * delta
		position = Vector2(roundf(_drift.x), roundf(_drift.y))
		var k := _age / _lifetime
		modulate.a = minf(k * 10.0, 1.0) * (1.0 - k)


## Sprite-sheet hit flash: 6 frames across, ~0.25 s, scale ~0.5.
class HitSpark extends Sprite2D:
	const DURATION := 0.25
	const FRAME_COUNT := 6

	var _age := 0.0


	func _init(sheet: Texture2D) -> void:
		texture = sheet
		hframes = 6
		vframes = 6
		scale = Vector2(0.5, 0.5)


	func _process(delta: float) -> void:
		_age += delta
		if _age >= DURATION:
			queue_free()
			return
		frame = mini(int(_age / DURATION * FRAME_COUNT), FRAME_COUNT - 1)


## A rust-colored square arcing out, bouncing once on a virtual floor, then
## fading away.
class RustDebris extends Node2D:
	var _velocity := Vector2.ZERO
	var _age := 0.0
	var _lifetime := 1.0
	var _gravity := 240.0
	var _floor_y := 0.0


	func _init() -> void:
		_lifetime = randf_range(0.7, 1.2)
		_gravity = randf_range(220.0, 300.0)


	func launch(pos: Vector2) -> void:
		position = pos
		_floor_y = pos.y + randf_range(6.0, 24.0)
		var angle := -randf_range(PI * 0.2, PI * 0.8)
		var speed := randf_range(40.0, 115.0)
		_velocity = Vector2(cos(angle), sin(angle)) * speed


	func _ready() -> void:
		var half := randf_range(1.0, 1.5)
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(-half, -half), Vector2(half, -half),
			Vector2(half, half), Vector2(-half, half),
		])
		poly.color = Palette.RUST_SHADOW.lerp(Palette.RUST_MID, randf())
		add_child(poly)


	func _process(delta: float) -> void:
		_age += delta
		if _age >= _lifetime:
			queue_free()
			return
		_velocity.y += _gravity * delta
		position += _velocity * delta
		if _velocity.y > 0.0 and position.y >= _floor_y:
			position.y = _floor_y
			_velocity.y *= -randf_range(0.3, 0.5)
			_velocity.x *= 0.6
		var k := _age / _lifetime
		modulate.a = clampf((1.0 - k) * 2.0, 0.0, 1.0)


## One small sludge bubble: three-frame wiggle, upward drift, fade-out pop.
class ToxinBubble extends Sprite2D:
	const FRAME_STEP := 0.14

	var _age := 0.0
	var _lifetime := 1.2
	var _rise := 10.0
	var _phase := 0.0


	func _init(sheet: Texture2D) -> void:
		texture = sheet
		hframes = 8
		vframes = 8
		_lifetime = randf_range(0.9, 1.6)
		_rise = randf_range(7.0, 14.0)
		_phase = randf() * TAU
		var s := randf_range(0.06, 0.1)
		scale = Vector2(s, s)


	func _process(delta: float) -> void:
		_age += delta
		if _age >= _lifetime:
			queue_free()
			return
		position.y -= _rise * delta
		position.x += sin(_age * 2.2 + _phase) * 3.0 * delta
		frame = int(_age / FRAME_STEP) % 3
		var k := _age / _lifetime
		modulate.a = minf(k * 10.0, 1.0) * clampf((1.0 - k) * 2.5, 0.0, 1.0)
