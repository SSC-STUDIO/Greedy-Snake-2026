extends SceneTree

func _init() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(70, 70)
	var paths := [
		"res://assets/kenney_clean/tiles/castleCenter.png",
		"res://assets/kenney_clean/tiles/castleMid.png",
		"res://assets/kenney_clean/tiles/grassMid.png",
		"res://assets/kenney_clean/tiles/box.png",
	]
	for i in paths.size():
		var path: String = paths[i]
		if not ResourceLoader.exists(path):
			print("skip missing ", path)
			continue
		var tex: Texture2D = load(path) as Texture2D
		if tex == null:
			print("failed load ", path)
			continue
		var src := TileSetAtlasSource.new()
		src.texture = tex
		src.texture_region_size = Vector2i(70, 70)
		var sid := ts.add_source(src)
		# Create a single tile at 0,0 for this source.
		src.create_tile(Vector2i(0, 0))
		# For ground tiles, add a full collision square for visual-only layer we won't use for physics,
		# but keep a placeholder polygon so the editor shows it.
		print("added source ", sid, " for ", path)
	var out := "res://assets/tilesets/kenney_ground.tres"
	var err := ResourceSaver.save(ts, out)
	print("save ", out, " err=", err)
	quit(0)
