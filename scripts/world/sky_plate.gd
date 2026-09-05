class_name SkyPlate
extends RefCounted
## Cut units from the authored Gothicvania sky / cloud plates, then scatter.
## Algorithm only places / wraps / seeds. Pixels stay from the original art.

const SKY_SRC := "res://assets/env/normalized/parallax_sky_px.png"
const SKY_FALLBACK := "res://assets/env/parallax_sky.png"
const CLOUD_FAR_SRC := "res://assets/env/normalized/parallax_clouds_px.png"
const CLOUD_LOW_SRC := "res://assets/env/normalized/parallax_clouds_low_px.png"
const FOG_SRC := "res://assets/env/normalized/parallax_fog_px.png"

const SKY_H := 448
const WASH_W := 1
const WASH_SAMPLE_W := 64
const WASH_SMOOTH_RADIUS := 12
const SKY_COVER_W := 1280
const MOON_SRC := "res://assets/env/normalized/moon.png"
const UNIT_MIN := 24
const UNIT_MAX := 240
const UNIT_MAX_H := 80

const CLOUD_FAR_FIELD := 2200.0
const CLOUD_LOW_FIELD := 1680.0
const FOG_RIDGE_FIELD := 1500.0
const FOG_FAR_FIELD := 1860.0
const FOG_NEAR_FIELD := 2040.0

const STAR_FIELD_W := 960
const STAR_FIELD_H := 188
const STAR_MIN := 40
const STAR_MAX := 58
const CLOUD_FAR_LO := 10
const CLOUD_FAR_HI := 14
const CLOUD_LOW_LO := 8
const CLOUD_LOW_HI := 12

static var _wash: ImageTexture
static var _moon: ImageTexture
static var _moon_img: Image
static var _clouds: Array[Texture2D] = []
static var _fogs: Array[Texture2D] = []
static var _star_palette: Array[Color] = []


static func sky_wash() -> ImageTexture:
	if _wash != null:
		return _wash
	_wash = _tex(sky_wash_image())
	return _wash


static func sky_wash_image() -> Image:
	var src := _load_rgba(SKY_SRC)
	if src == null:
		src = _load_rgba(SKY_FALLBACK)
	var img := Image.create(WASH_W, SKY_H, false, Image.FORMAT_RGBA8)
	if src == null:
		img.fill(Color8(2, 0, 35))
		return img
	var sh := src.get_height()
	var sample_width := mini(WASH_SAMPLE_W, src.get_width())
	var rows: Array[Color] = []
	for y in range(SKY_H):
		var sy := mini(sh - 1, int(round(float(y) * float(sh - 1) / float(SKY_H - 1))))
		var row := Color(0, 0, 0, 0)
		for x in range(sample_width):
			row += src.get_pixel(x, sy)
		rows.append(row / float(sample_width))
	# Keep the authored colour profile, without repeating a 32-pixel cloud cut
	# across the whole sky. Clouds are separate, irregularly spaced stamps.
	for y in range(SKY_H):
		var row := Color(0, 0, 0, 0)
		var first := maxi(0, y - WASH_SMOOTH_RADIUS)
		var last := mini(SKY_H - 1, y + WASH_SMOOTH_RADIUS)
		for sample_y in range(first, last + 1):
			row += rows[sample_y]
		img.set_pixel(0, y, _nighten_wash(row / float(last - first + 1), y))
	return img


static func moon_tex() -> ImageTexture:
	if _moon != null:
		return _moon
	_moon = _tex(moon_image())
	return _moon


static func moon_image() -> Image:
	if _moon_img == null:
		_moon_img = _load_rgba(MOON_SRC)
	return _moon_img


static func cloud_units() -> Array[Texture2D]:
	if not _clouds.is_empty():
		return _clouds
	for cut in _cut_units(CLOUD_FAR_SRC):
		_clouds.append(_tex(cut))
	for cut in _cut_units(CLOUD_LOW_SRC):
		_clouds.append(_tex(cut))
	return _clouds


static func fog_units() -> Array[Texture2D]:
	if not _fogs.is_empty():
		return _fogs
	for cut in _cut_units(FOG_SRC):
		_fogs.append(_tex(cut))
	for cut in _cut_strips(FOG_SRC, 186):
		_fogs.append(_tex(cut))
	return _fogs


static func layout(seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed if seed != 0 else 1
	var clouds := cloud_units()
	var fogs := fog_units()
	return {
		"moon": {
			"x": rng.randi_range(340, 500),
			"y": rng.randi_range(56, 92),
			"scale": 1,
		},
		"stars": _plan_stars(rng),
		"clouds_far": _plan(
				rng, CLOUD_FAR_LO, CLOUD_FAR_HI, CLOUD_FAR_FIELD, 0.0, 92.0, 1, 1,
				clouds.size(), clouds),
		"clouds_low": _plan(
				rng, CLOUD_LOW_LO, CLOUD_LOW_HI, CLOUD_LOW_FIELD, 6.0, 50.0, 1, 1,
				clouds.size(), clouds),
		"fog_ridge": _plan(rng, 4, 6, FOG_RIDGE_FIELD, 0.0, 18.0, 1, 2, fogs.size()),
		"fog_far": _plan(rng, 4, 6, FOG_FAR_FIELD, 0.0, 16.0, 1, 2, fogs.size()),
		"fog_near": _plan(rng, 5, 7, FOG_NEAR_FIELD, 0.0, 14.0, 1, 2, fogs.size()),
	}


static func moon_stats(img: Image) -> Dictionary:
	var w := img.get_width()
	var h := img.get_height()
	var sx := 0
	var sy := 0
	var n := 0
	for y in range(h):
		for x in range(w):
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			if c.r > 0.70 and c.b > 0.28 and c.r >= c.g + 0.05:
				sx += x
				sy += y
				n += 1
	if n == 0:
		return {"count": 0, "cx": 0.0, "cy": 0.0, "dark": 0}
	var cx := float(sx) / float(n)
	var cy := float(sy) / float(n)
	var dark := 0
	for y in range(maxi(0, int(cy) - 50), mini(h, int(cy) + 50)):
		for x in range(maxi(0, int(cx) - 50), mini(w, int(cx) + 50)):
			var dx := float(x) - cx
			var dy := float(y) - cy
			if dx * dx + dy * dy > 42.0 * 42.0:
				continue
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			if maxf(c.r, maxf(c.g, c.b)) < 0.28 and c.r < 0.22:
				dark += 1
	return {"count": n, "cx": cx, "cy": cy, "dark": dark}


static func star_count(plan: Dictionary = {}) -> int:
	if plan.is_empty():
		return 0
	return (plan.get("stars", []) as Array).size()


static func star_brightness(spec: Dictionary, t: float) -> float:
	var period := maxf(0.55, float(spec.get("period", 2.6)))
	var phase := float(spec.get("phase", 0.0))
	var amp := clampf(float(spec.get("amp", 0.32)), 0.12, 0.50)
	var base := clampf(float(spec.get("base", 0.82)), 0.45, 1.0)
	var wave := 0.5 + 0.5 * sin(t * TAU / period + phase)
	## Four pixel-art steps so the blink reads as a pip, not a fade.
	var stepped := floorf(wave * 3.999) / 3.0
	var bright := clampf(base * (1.0 - amp + amp * stepped), 0.30, 1.12)
	var flash_span := maxf(3.2, float(spec.get("flash", 8.0)))
	var slot := int(floor(t / flash_span))
	var hid := int(spec.get("x", 0)) * 13 + int(spec.get("y", 0)) * 7 + slot * 17
	if posmod(hid, 29) == 0:
		bright = minf(1.22, bright + 0.22)
	return bright


static func star_field_luma(stars: Array, t: float) -> float:
	var s := 0.0
	for item in stars:
		s += star_brightness(item as Dictionary, t)
	return s


static func paint_stars(img: Image, stars: Array, t: float) -> void:
	if img == null:
		return
	img.fill(Color(0, 0, 0, 0))
	for item in stars:
		_stamp_star(img, item as Dictionary, star_brightness(item as Dictionary, t))


static func star_field_image(stars: Array, t: float = 0.0) -> Image:
	var img := Image.create(STAR_FIELD_W, STAR_FIELD_H, false, Image.FORMAT_RGBA8)
	paint_stars(img, stars, t)
	return img


static func _plan_stars(rng: RandomNumberGenerator) -> Array:
	var palette := _star_colors()
	var cols := 12
	var rows := 5
	var cells: Array[Vector2i] = []
	for row in range(rows):
		for col in range(cols):
			cells.append(Vector2i(col, row))
	for i in range(cells.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Vector2i = cells[i]
		cells[i] = cells[j]
		cells[j] = tmp
	var n := rng.randi_range(STAR_MIN, mini(STAR_MAX, cells.size()))
	var cell_w := float(STAR_FIELD_W) / float(cols)
	var cell_h := float(STAR_FIELD_H - 18) / float(rows)
	var out: Array = []
	for i in range(n):
		var cell: Vector2i = cells[i]
		var x := int(cell.x * cell_w + rng.randf_range(6.0, cell_w - 6.0))
		var y := int(12.0 + cell.y * cell_h + rng.randf_range(3.0, cell_h - 4.0))
		x = clampi(x, 2, STAR_FIELD_W - 3)
		y = clampi(y, 6, STAR_FIELD_H - 4)
		out.append({
			"x": x,
			"y": y,
			"kind": 1 if rng.randf() < 0.24 else 0,
			"color": palette[rng.randi_range(0, palette.size() - 1)],
			"phase": rng.randf() * TAU,
			"period": rng.randf_range(1.7, 4.6),
			"amp": rng.randf_range(0.22, 0.40),
			"flash": rng.randf_range(5.5, 13.0),
			"base": rng.randf_range(0.62, 0.98),
		})
	return out


static func _star_colors() -> Array[Color]:
	if not _star_palette.is_empty():
		return _star_palette
	var samples: Array[Color] = []
	var src := _load_rgba(SKY_SRC)
	if src == null:
		src = _load_rgba(SKY_FALLBACK)
	if src != null:
		var w := src.get_width()
		var h := src.get_height()
		for y in range(6, mini(h, 140), 8):
			for x in range(0, w, 10):
				var c := src.get_pixel(x, y)
				if c.a < 0.35 or _is_near_black(c) or _is_moon_px(c):
					continue
				var mx := maxf(c.r, maxf(c.g, c.b))
				if mx < 0.20 or mx > 0.82:
					continue
				if c.b >= c.g * 0.88 or c.r >= c.g:
					samples.append(Color(
							minf(1.0, c.r * 1.18 + 0.10),
							minf(1.0, c.g * 1.10 + 0.12),
							minf(1.0, c.b * 1.22 + 0.16),
							1.0))
	_star_palette = [
		Color8(236, 240, 255),
		Color8(255, 228, 246),
		Color8(208, 214, 255),
		Color8(248, 246, 255),
	]
	var take := mini(6, samples.size())
	var step := 1 if take <= 0 else maxi(1, int(samples.size() / take))
	var i := 0
	while i < samples.size() and _star_palette.size() < 10:
		_star_palette.append(samples[i])
		i += step
	return _star_palette


static func _stamp_star(img: Image, spec: Dictionary, bright: float) -> void:
	var x := int(spec.get("x", 0))
	var y := int(spec.get("y", 0))
	var col: Color = spec.get("color", Color8(236, 240, 255))
	var a := clampf(bright, 0.0, 1.0)
	_put_star_px(img, x, y, Color(col.r, col.g, col.b, a))
	if int(spec.get("kind", 0)) != 1:
		return
	var arm := Color(col.r, col.g, col.b, a * 0.42)
	_put_star_px(img, x - 1, y, arm)
	_put_star_px(img, x + 1, y, arm)
	_put_star_px(img, x, y - 1, arm)
	_put_star_px(img, x, y + 1, arm)


static func _put_star_px(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	img.set_pixel(x, y, c)


static func _nighten_wash(c: Color, y: int) -> Color:
	## Keep the authored night columns. Deepen the mid vault a little so the
	## empty sky reads as night, without rewriting the ramp by hand.
	var yn := float(y) / float(maxi(1, SKY_H - 1))
	var vault := clampf((yn - 0.08) / 0.36, 0.0, 1.0)
	vault *= vault
	var k := 1.0 - 0.11 * vault
	return Color(c.r * k, c.g * k * 0.98, minf(1.0, c.b * k + 0.012 * vault), c.a)


static func _plan(
		rng: RandomNumberGenerator,
		lo: int,
		hi: int,
		field: float,
		y0: float,
		y1: float,
		s0: int,
		s1: int,
		unit_n: int,
		units: Array = []) -> Array:
	var out: Array = []
	if unit_n <= 0:
		return out
	var n := rng.randi_range(lo, hi)
	var pool: Array[int] = []
	for i in range(unit_n):
		if units.is_empty():
			pool.append(i)
			continue
		var tex := units[i] as Texture2D
		if tex != null and tex.get_width() >= maxi(48, int(float(tex.get_height()) * 1.25)):
			pool.append(i)
	if pool.is_empty():
		for i in range(unit_n):
			pool.append(i)
	var margin := 48.0
	var span := maxf(120.0, field - margin * 2.0)
	for i in range(n):
		out.append({
			"unit": pool[rng.randi_range(0, pool.size() - 1)],
			"x": margin + span * (float(i) + rng.randf_range(0.08, 0.86)) / float(n),
			"y": rng.randf_range(y0, y1),
			"scale": rng.randi_range(s0, s1),
			"flip": rng.randf() < 0.45,
		})
	return out


static func _cut_moon(src: Image) -> Image:
	var empty := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	empty.fill(Color(0, 0, 0, 0))
	if src == null:
		return empty
	var w := src.get_width()
	var h := src.get_height()
	var best := 0
	var brow := 0
	var x0 := 0
	var x1 := 0
	for y in range(h):
		var x := 0
		while x < w:
			if not _is_moon_px(src.get_pixel(x, y)):
				x += 1
				continue
			var a := x
			while x < w and _is_moon_px(src.get_pixel(x, y)):
				x += 1
			if x - a > best:
				best = x - a
				brow = y
				x0 = a
				x1 = x
	if best < 40:
		return empty
	var cx := float(x0 + x1 - 1) * 0.5
	var cy := float(brow)
	var radius := float(best) * 0.5
	var pad := 8
	var r := int(ceil(radius)) + pad
	var ox := maxi(0, int(cx) - r)
	var oy := maxi(0, int(cy) - r)
	var bw := mini(w, int(cx) + r + 1) - ox
	var bh := mini(h, int(cy) + r + 1) - oy
	var img := Image.create(bw, bh, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var body := Color8(220, 86, 158)
	var samples: Array[Color] = []
	var r2 := (radius + 3.0) * (radius + 3.0)
	var core2 := (radius * 0.92) * (radius * 0.92)
	for y in range(bh):
		for x in range(bw):
			var sx := ox + x
			var sy := oy + y
			var dx := float(sx) - cx
			var dy := float(sy) - cy
			var d2 := dx * dx + dy * dy
			if d2 > r2:
				continue
			var c := src.get_pixel(sx, sy)
			if d2 <= core2:
				if _is_near_black(c):
					continue
				img.set_pixel(x, y, c)
				if _is_moon_px(c):
					samples.append(c)
			elif _is_moon_px(c):
				img.set_pixel(x, y, c)
	if not samples.is_empty():
		body = samples[int(samples.size() / 2)]
	_heal_moon_disk(img, int(cx) - ox, int(cy) - oy, int(radius), body)
	return img


static func _heal_moon_disk(img: Image, cx: int, cy: int, radius: int, body: Color) -> void:
	var r2 := (radius + 1) * (radius + 1)
	for y in range(cy - radius - 1, cy + radius + 2):
		for x in range(cx - radius - 1, cx + radius + 2):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) > r2:
				continue
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			if maxf(c.r, maxf(c.g, c.b)) < 0.28 and c.r < 0.22:
				img.set_pixel(x, y, body)


static func _cut_sky_clouds() -> Array[Image]:
	var src := _load_rgba(SKY_SRC)
	if src == null:
		return []
	var w := src.get_width()
	var h := src.get_height()
	var moon := _moon_guess(src)
	var keyed := Image.create(w, h, false, Image.FORMAT_RGBA8)
	keyed.fill(Color(0, 0, 0, 0))
	var mcx := moon.x
	var mcy := moon.y
	var mr2 := (moon.z + 6.0) * (moon.z + 6.0)
	for y in range(h):
		for x in range(w):
			var c := src.get_pixel(x, y)
			if c.a < 0.2 or _is_near_black(c):
				continue
			var dx := float(x) - mcx
			var dy := float(y) - mcy
			if dx * dx + dy * dy <= mr2:
				continue
			if _is_moon_px(c) and dy < 0.0:
				continue
			keyed.set_pixel(x, y, c)
	return _blobs_from(keyed)


static func _moon_guess(src: Image) -> Vector3:
	var w := src.get_width()
	var h := src.get_height()
	var best := 0
	var brow := 0
	var x0 := 0
	var x1 := 0
	for y in range(h):
		var x := 0
		while x < w:
			if not _is_moon_px(src.get_pixel(x, y)):
				x += 1
				continue
			var a := x
			while x < w and _is_moon_px(src.get_pixel(x, y)):
				x += 1
			if x - a > best:
				best = x - a
				brow = y
				x0 = a
				x1 = x
	if best < 20:
		return Vector3(360.0, 72.0, 70.0)
	return Vector3(float(x0 + x1 - 1) * 0.5, float(brow), float(best) * 0.5)


static func _cut_strips(path: String, slice_w: int) -> Array[Image]:
	var src := _load_rgba(path)
	var out: Array[Image] = []
	if src == null:
		return out
	var w := src.get_width()
	var h := src.get_height()
	var step := maxi(32, slice_w - 24)
	var x := 0
	while x < w - 24:
		var bw := mini(slice_w, w - x)
		var opaque := 0
		for yy in range(h):
			for xx in range(x, x + bw):
				if src.get_pixel(xx, yy).a >= 0.20:
					opaque += 1
		if opaque >= 40:
			var stamp := Image.create(bw, h, false, Image.FORMAT_RGBA8)
			stamp.fill(Color(0, 0, 0, 0))
			stamp.blit_rect(src, Rect2i(x, 0, bw, h), Vector2i.ZERO)
			out.append(stamp)
		x += step
	return out


static func _cut_units(path: String) -> Array[Image]:
	var src := _load_rgba(path)
	if src == null:
		return []
	return _blobs_from(src)


static func _blobs_from(src: Image) -> Array[Image]:
	var out: Array[Image] = []
	var w := src.get_width()
	var h := src.get_height()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var dirs: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
	]
	for y in range(h):
		for x in range(w):
			var i := y * w + x
			if seen[i] != 0 or src.get_pixel(x, y).a < 0.20:
				continue
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			seen[i] = 1
			var cells: Array[Vector2i] = []
			var min_x := x
			var min_y := y
			var max_x := x
			var max_y := y
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				cells.append(p)
				min_x = mini(min_x, p.x)
				min_y = mini(min_y, p.y)
				max_x = maxi(max_x, p.x)
				max_y = maxi(max_y, p.y)
				for d in dirs:
					var nxt: Vector2i = p + d
					if nxt.x < 0 or nxt.y < 0 or nxt.x >= w or nxt.y >= h:
						continue
					var ni: int = nxt.y * w + nxt.x
					if seen[ni] != 0 or src.get_pixel(nxt.x, nxt.y).a < 0.20:
						continue
					seen[ni] = 1
					stack.append(nxt)
			var bw := max_x - min_x + 1
			var bh := max_y - min_y + 1
			if cells.size() < 24 or bw < UNIT_MIN or bh < 8:
				continue
			if bw > UNIT_MAX or bh > UNIT_MAX_H:
				continue
			var stamp := Image.create(bw, bh, false, Image.FORMAT_RGBA8)
			stamp.fill(Color(0, 0, 0, 0))
			for p in cells:
				stamp.set_pixel(p.x - min_x, p.y - min_y, src.get_pixel(p.x, p.y))
			out.append(stamp)
	return out


static func _is_moon_px(c: Color) -> bool:
	return c.a > 0.04 and c.r > 0.74 and c.b > 0.30 and c.r >= c.g + 0.05 and c.r > c.b


static func _is_near_black(c: Color) -> bool:
	return maxf(c.r, maxf(c.g, c.b)) < 0.16


static func _load_rgba(path: String) -> Image:
	if not ResourceLoader.exists(path):
		return null
	var tex := load(path) as Texture2D
	if tex == null:
		return null
	var img := tex.get_image()
	if img == null:
		return null
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	return img


static func _tex(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)
