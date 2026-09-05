class_name WeatherFx
extends CanvasLayer
## Rain is drawn on the 640×360 canvas so MoodTint cannot crush it, but every
## drop is simulated in world space: the streak tip is the collision point.
## Hits (ground layer 1, toxin volume, Ember Nest bowl) splash and recycle
## above the camera. Embers stay decorative screen-space motes.

const DROP_COUNT := 64
const DROP_H := 6.0
const FALL_SPEED := 240.0
const EMBER_COUNT := 20
const EMBER_PATH := "res://assets/ui/ember_motes.png"
const EMBER_FRAMES := 8
const EMBER_DRIFT := 78.0
const GROUND_MASK := 1
const SPLASH_RATE := 56.0
const SPLASH_BURST := 18.0

var _drops: Array[Sprite2D] = []
var _world: Array[Vector2] = []
var _embers: Array[Sprite2D] = []
var _alpha := 0.0
var _ember_alpha := 0.0
var _tex: Texture2D
var _ember_tex: Texture2D
var _splash_budget := 0.0
var _warm := 0.12


func _ready() -> void:
	layer = 4
	follow_viewport_enabled = false
	add_to_group("weather_fx")
	if DisplayServer.get_name() == "headless":
		set_process(false)
		return
	var bounds := _bounds()
	_tex = _make_drop_tex()
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for i in DROP_COUNT:
		var spr := Sprite2D.new()
		spr.texture = _tex
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.centered = false
		spr.material = add
		spr.position = Vector2(randf() * bounds.x, randf() * bounds.y)
		spr.modulate = Color(0.86, 0.90, 0.96, 0.0)
		add_child(spr)
		_drops.append(spr)
	_ember_tex = _load_ember_tex()
	for i in EMBER_COUNT:
		var spr := Sprite2D.new()
		spr.texture = _ember_tex
		if _ember_tex != null and _ember_tex.get_width() >= EMBER_FRAMES:
			spr.hframes = EMBER_FRAMES
			spr.frame = randi() % EMBER_FRAMES
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.centered = true
		spr.position = Vector2(randf() * bounds.x, randf() * bounds.y)
		spr.modulate = Color(1.0, 0.62, 0.38, 0.0)
		spr.scale = Vector2(0.85, 0.85)
		add_child(spr)
		_embers.append(spr)
	var rain0 := WorldClock.rain_opacity()
	if rain0 > 0.0:
		_alpha = rain0


func _process(delta: float) -> void:
	var target := WorldClock.rain_opacity()
	_alpha = move_toward(_alpha, target, delta / 2.2)
	# 锈色只跟锈雨天气走。夜晚普通雨的 soak 仍由 rust_rain_mix 处理，
	# 但银白雨丝被lerp成锈橙后再叠 MoodTint 会发脏、盖住骑士。
	var rust := WorldClock.weather_weight(WorldClock.Weather.RUST_RAIN) if WorldClock.weather_fx_allowed() else 0.0
	var rain_col := Color(0.90, 0.94, 1.0).lerp(Color(0.86, 0.52, 0.36), clampf(rust, 0.0, 1.0))
	if _alpha <= 0.001 and target <= 0.0:
		for spr in _drops:
			if spr.modulate.a > 0.0:
				spr.modulate.a = 0.0
	else:
		_ensure_world_positions()
		var vis := _alpha * 0.95
		var view := _camera_world_rect()
		_splash_budget = minf(_splash_budget + SPLASH_RATE * delta, SPLASH_BURST)
		_warm = maxf(0.0, _warm - delta)
		var wind := rain_wind_x() * delta
		var fall := Vector2(wind, FALL_SPEED * delta)
		for i in _drops.size():
			var from := _world[i]
			var to := from + fall
			if to.x < view.position.x - 8.0:
				to.x = view.end.x + 8.0
			elif to.x > view.end.x + 8.0:
				to.x = view.position.x - 8.0
			var hit := resolve_fall(from, to, view)
			_world[i] = hit["world"]
			if _warm <= 0.0 and hit["kind"] != &"":
				_try_splash(hit["kind"], hit["point"])
			_drops[i].position = _tip_to_canvas(_world[i])
			_drops[i].modulate = Color(rain_col.r, rain_col.g, rain_col.b, vis)
	_tick_embers(delta)


func _tick_embers(delta: float) -> void:
	var target := WorldClock.ember_wind_opacity()
	_ember_alpha = move_toward(_ember_alpha, target, delta / 4.0)
	if _ember_alpha <= 0.001 and target <= 0.0:
		for spr in _embers:
			if spr.modulate.a > 0.0:
				spr.modulate.a = 0.0
		return
	var vis := _ember_alpha * 0.28
	var bounds := _bounds()
	for spr in _embers:
		var p := spr.position
		p.x += rain_wind_x() * (EMBER_DRIFT / 36.0) * delta
		p.y += sin(p.x * 0.04 + p.y * 0.01) * 10.0 * delta
		if p.x < -10.0:
			p.x = bounds.x + 10.0
			p.y = randf() * bounds.y
		elif p.x > bounds.x + 10.0:
			p.x = -10.0
			p.y = randf() * bounds.y
		elif p.y < -10.0:
			p.y = bounds.y + 8.0
		elif p.y > bounds.y + 10.0:
			p.y = -8.0
		spr.position = Vector2(roundf(p.x), roundf(p.y))
		if spr.hframes > 1 and randf() < delta * 6.0:
			spr.frame = (spr.frame + 1) % spr.hframes
		spr.modulate = Color(1.0, 0.62, 0.38, vis)


func _bounds() -> Vector2:
	var host := get_parent()
	if host != null:
		var host_vp := host.get_viewport()
		if host_vp != null:
			var host_size := host_vp.get_visible_rect().size
			if host_size.x > 1.0 and host_size.y > 1.0:
				return host_size
	var vp := get_viewport()
	if vp != null:
		var size := vp.get_visible_rect().size
		if size.x > 1.0 and size.y > 1.0:
			return size
	return Vector2(PresentationMetrics.WORLD_SIZE)


func rain_wind_x() -> float:
	var v := WorldClock.wind_vector().x
	if absf(v) < 0.02:
		return -36.0
	return v * 150.0


func _ensure_world_positions() -> void:
	if _world.size() == _drops.size() and not _world.is_empty():
		return
	_world.clear()
	var view := _camera_world_rect()
	for spr in _drops:
		var p := Vector2(
			view.position.x + randf() * maxf(view.size.x, 1.0),
			view.position.y + randf() * maxf(view.size.y, 1.0)
		)
		_world.append(p)
		spr.centered = false
		spr.position = _tip_to_canvas(p)


func _camera_world_rect() -> Rect2:
	var size := _bounds()
	var cam := _active_camera()
	if cam == null:
		return Rect2(Vector2.ZERO, size)
	var center := cam.get_screen_center_position()
	return Rect2(center - size * 0.5, size)


func _as_view(view: Variant) -> Rect2:
	if view is Rect2:
		return view
	if view is Vector2:
		return Rect2(Vector2.ZERO, view)
	return _camera_world_rect()


func _recycle_world(view: Rect2) -> Vector2:
	return Vector2(
		view.position.x + randf() * maxf(view.size.x, 1.0),
		view.position.y - randf_range(4.0, 18.0)
	)


func _tip_to_canvas(tip: Vector2) -> Vector2:
	var canvas := world_to_canvas(tip)
	return Vector2(roundf(canvas.x - 1.0), roundf(canvas.y - DROP_H))


## Viewport (canvas) → world. CanvasLayer can miss Viewport.get_camera_2d(),
## so we also look at the parent world and the game_camera group.
func canvas_to_world(canvas: Vector2) -> Vector2:
	var cam := _active_camera()
	if cam == null:
		return canvas
	var size := _bounds()
	var zoom := cam.zoom
	if zoom.x == 0.0 or zoom.y == 0.0:
		zoom = Vector2.ONE
	return cam.get_screen_center_position() + (canvas - size * 0.5) / zoom


func world_to_canvas(world: Vector2) -> Vector2:
	var cam := _active_camera()
	if cam == null:
		return world
	var size := _bounds()
	var zoom := cam.zoom
	if zoom.x == 0.0 or zoom.y == 0.0:
		zoom = Vector2.ONE
	return size * 0.5 + (world - cam.get_screen_center_position()) * zoom


func _active_camera() -> Camera2D:
	var host := get_parent()
	if host != null:
		var host_vp := host.get_viewport()
		if host_vp != null:
			var cam := host_vp.get_camera_2d()
			if cam != null:
				return cam
	var tree := get_tree()
	if tree != null:
		var grouped := tree.get_first_node_in_group("game_camera")
		if grouped is Camera2D:
			return grouped as Camera2D
	var own := get_viewport()
	if own != null:
		return own.get_camera_2d()
	return null


## Move a drop tip from `from_world` toward `to_world`. On nest / pool / ground
## the streak recycles above the view. Kind is empty when it only wraps.
func resolve_fall(from_world: Vector2, to_world: Vector2, view: Variant) -> Dictionary:
	var rect := _as_view(view)
	var hit := probe_segment(from_world, to_world)
	if hit["kind"] != &"":
		var recycled := _recycle_world(rect)
		return {
			"canvas": world_to_canvas(recycled),
			"world": recycled,
			"kind": hit["kind"],
			"point": hit["point"],
			"recycled": true,
		}
	if to_world.y > rect.end.y + 8.0:
		var wrapped := _recycle_world(rect)
		return {
			"canvas": world_to_canvas(wrapped),
			"world": wrapped,
			"kind": &"",
			"world_miss": to_world,
			"point": to_world,
			"recycled": true,
		}
	return {
		"canvas": world_to_canvas(to_world),
		"world": to_world,
		"kind": &"",
		"point": to_world,
		"recycled": false,
	}


func probe_segment(from_world: Vector2, to_world: Vector2) -> Dictionary:
	var empty := {"kind": &"", "point": to_world}
	var nest_hit := _probe_nests(from_world, to_world)
	if nest_hit["kind"] != &"":
		return nest_hit
	var pool_hit := _probe_pools(from_world, to_world)
	var ground_hit := _probe_ground(from_world, to_world, empty)
	if pool_hit["kind"] != &"" and ground_hit["kind"] != &"":
		var pool_y := (pool_hit["point"] as Vector2).y
		var ground_y := (ground_hit["point"] as Vector2).y
		# 坑唇草皮比水膜高：溅在石头上，不要绿水吻盖过踏步。
		if ground_y <= pool_y + 1.5:
			return ground_hit
		return pool_hit
	if pool_hit["kind"] != &"":
		return pool_hit
	return ground_hit


func _probe_nests(from_world: Vector2, to_world: Vector2) -> Dictionary:
	var tree := get_tree()
	if tree == null:
		return {"kind": &"", "point": to_world}
	for node in tree.get_nodes_in_group("ember_nests"):
		var nest := node as EmberNest
		if nest == null or not is_instance_valid(nest):
			continue
		var rect: Rect2 = nest.rain_hit_rect()
		if rect.has_point(to_world) or _segment_hits_rect(from_world, to_world, rect):
			var kind := &"nest_lit" if nest.is_lit() else &"nest"
			var at := Vector2(to_world.x, rect.position.y + 6.0)
			return {"kind": kind, "point": at}
	return {"kind": &"", "point": to_world}


func _probe_pools(from_world: Vector2, to_world: Vector2) -> Dictionary:
	var tree := get_tree()
	if tree == null:
		return {"kind": &"", "point": to_world}
	for node in tree.get_nodes_in_group("toxin_pools"):
		var pool := node as ToxinPool
		if pool == null or not is_instance_valid(pool):
			continue
		var volume: Rect2 = pool.volume_rect()
		if volume.has_point(to_world) or _segment_hits_rect(from_world, to_world, volume):
			return {"kind": &"toxin", "point": pool.splash_point(to_world.x)}
	return {"kind": &"", "point": to_world}


func _probe_ground(from_world: Vector2, to_world: Vector2, empty: Dictionary) -> Dictionary:
	var space := _space_state()
	if space == null:
		return empty
	if from_world.distance_squared_to(to_world) > 0.01:
		var ray := PhysicsRayQueryParameters2D.create(from_world, to_world, GROUND_MASK)
		ray.collide_with_areas = false
		ray.collide_with_bodies = true
		var hit := space.intersect_ray(ray)
		if not hit.is_empty():
			return {"kind": &"ground", "point": hit["position"]}
	var pq := PhysicsPointQueryParameters2D.new()
	pq.position = to_world
	pq.collision_mask = GROUND_MASK
	pq.collide_with_bodies = true
	pq.collide_with_areas = false
	var pts := space.intersect_point(pq, 1)
	if not pts.is_empty():
		return {"kind": &"ground", "point": to_world}
	return empty


func _space_state() -> PhysicsDirectSpaceState2D:
	var host := get_parent()
	if host is Node2D:
		var world := (host as Node2D).get_world_2d()
		if world != null:
			return world.direct_space_state
	var vp := get_viewport()
	if vp == null or vp.world_2d == null:
		return null
	return vp.world_2d.direct_space_state


static func _segment_hits_rect(from_p: Vector2, to_p: Vector2, rect: Rect2) -> bool:
	if rect.has_point(from_p) or rect.has_point(to_p):
		return true
	var corners := PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	])
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		if Geometry2D.segment_intersects_segment(from_p, to_p, a, b) != null:
			return true
	return false


func _try_splash(kind: StringName, world_pos: Vector2) -> void:
	if _splash_budget < 1.0:
		return
	_splash_budget -= 1.0
	var splash_kind := kind
	if kind == &"ground" and WorldClock.is_rust_raining():
		splash_kind = &"rust"
	Fx.rain_splash(world_pos, splash_kind)


func _load_ember_tex() -> Texture2D:
	if ResourceLoader.exists(EMBER_PATH):
		var tex := load(EMBER_PATH) as Texture2D
		if tex != null:
			return tex
	return _make_ember_tex()


func _make_ember_tex() -> Texture2D:
	var img := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.set_pixel(1, 1, Color(1.0, 0.62, 0.34, 0.85))
	img.set_pixel(1, 0, Color(1.0, 0.78, 0.42, 0.45))
	img.set_pixel(0, 1, Color(0.90, 0.40, 0.22, 0.35))
	return ImageTexture.create_from_image(img)


func _make_drop_tex() -> Texture2D:
	var img := Image.create(2, int(DROP_H), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.set_pixel(0, 0, Color(0.84, 0.90, 1.00, 0.28))
	img.set_pixel(1, 1, Color(0.92, 0.96, 1.00, 0.82))
	img.set_pixel(0, 2, Color(0.98, 1.00, 1.00, 1.00))
	img.set_pixel(1, 3, Color(0.94, 0.97, 1.00, 0.88))
	img.set_pixel(0, 4, Color(0.88, 0.93, 1.00, 0.55))
	img.set_pixel(1, 5, Color(0.82, 0.88, 0.98, 0.28))
	return ImageTexture.create_from_image(img)
