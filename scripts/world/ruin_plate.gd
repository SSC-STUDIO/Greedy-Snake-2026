class_name RuinPlate
extends Object
## Slices a rectangular wall plate into 8px columns with a broken crown so
## bastion masonry reads as ruins, not hard-edged boxes. Deterministic per
## placement: a reload never re-rolls the skyline. Only for plates whose top
## band is plain wall (torch walls, altar backdrop, gargoyle plinth) — arch
## plates keep their authored crowns.

const STRIP_W := 8
const CROWN_STEP := 8
const DEFAULT_MAX_STEPS := 6


## Random walk across the crown; the two outer columns crumble one step lower.
## `max_steps` × CROWN_STEP is the deepest cut (48px by default).
static func crown_profile(strips: int, seed_pos: Vector2, max_steps: int = DEFAULT_MAX_STEPS) -> PackedInt32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3(seed_pos.x, seed_pos.y, 7.0))
	var profile := PackedInt32Array()
	var cut := rng.randi_range(1, mini(3, max_steps))
	for i in strips:
		if i > 0:
			cut = clampi(cut + rng.randi_range(-2, 2), 0, maxi(0, max_steps - 1))
		profile.append(cut)
	if strips >= 2:
		profile[0] = mini(profile[0] + 1, max_steps)
		profile[strips - 1] = mini(profile[strips - 1] + 1, max_steps)
	return profile


## Builds the sliced plate under `root` with the plate's top-left at (0, 0).
## Callers position / scale / tint the root as they would a single sprite.
static func build(root: Node2D, tex: Texture2D, seed_pos: Vector2, max_steps: int = DEFAULT_MAX_STEPS) -> void:
	if root == null or tex == null:
		return
	var w := tex.get_width()
	var h := tex.get_height()
	var strips := maxi(1, w / STRIP_W)
	var profile := crown_profile(strips, seed_pos, max_steps)
	for i in strips:
		var cut := profile[i] * CROWN_STEP
		var strip := Sprite2D.new()
		strip.name = "Strip%d" % i
		strip.texture = tex
		strip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		strip.centered = false
		strip.region_enabled = true
		var sw := mini(STRIP_W, w - i * STRIP_W)
		strip.region_rect = Rect2(float(i * STRIP_W), float(cut), float(sw), float(h - cut))
		strip.position = Vector2(float(i * STRIP_W), float(cut))
		root.add_child(strip)
