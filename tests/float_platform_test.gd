extends TestCase
## Floating slabs stay thin and top-aligned; ground skin stays grass.


const FLOAT_PATHS: Array[String] = [
	"res://assets/env/float_left.png",
	"res://assets/env/float_right.png",
	"res://assets/env/float_mid_a.png",
	"res://assets/env/float_mid_b.png",
	"res://assets/env/float_mid_c.png",
	"res://assets/env/float_mid_d.png",
	"res://assets/env/float_small.png",
]


func test_float_textures_are_thin_slabs() -> void:
	for path in FLOAT_PATHS:
		ok(ResourceLoader.exists(path), "missing %s" % path)
		var tex := load(path) as Texture2D
		ok(tex != null, "failed to load %s" % path)
		if tex == null:
			continue
		ok(tex.get_height() <= 16, "%s is %dpx tall (want <= 16)" % [path, tex.get_height()])
		ok(tex.get_height() >= 10, "%s is %dpx tall (want hang leftover)" % [path, tex.get_height()])


func test_floating_sprites_hang_from_collision_top() -> void:
	var plat := SolidPlatform.new()
	plat.skin = "floating"
	plat.size = Vector2(64, 16)
	plat.position = Vector2(100, 200)
	add_child(plat)
	var sprites := 0
	for child in plat.get_children():
		if child is Sprite2D:
			sprites += 1
			almost(child.position.y, 0.0, 0.01, "float sprite must hang from collision top")
			ok(child.texture.get_height() <= 16, "in-game float sprite taller than 16px")
	ok(sprites >= 3, "left + mid + right pieces")
	var col: CollisionShape2D
	for child in plat.get_children():
		if child is CollisionShape2D:
			col = child
	ok(col != null, "floating platform keeps a collision box")
	var shape := col.shape as RectangleShape2D
	almost(shape.size.y, 16.0, 0.01, "collision height must stay 16px")
	almost(col.position.y, 8.0, 0.01, "collision stays centered on the 16px box")
	almost(plat.position.y, 200.0, 0.01, "platform origin must not move")


func test_ground_skin_does_not_use_float_tiles() -> void:
	var plat := SolidPlatform.new()
	plat.skin = "ground"
	plat.size = Vector2(64, 16)
	add_child(plat)
	var sprites := 0
	for child in plat.get_children():
		if child is Sprite2D:
			sprites += 1
			ok(not child.texture.resource_path.contains("float_"),
					"ground used float tile %s" % child.texture.resource_path)
	ok(sprites >= 1, "ground skin still paints tiles")
