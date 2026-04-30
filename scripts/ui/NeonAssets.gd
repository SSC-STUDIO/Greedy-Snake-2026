extends RefCounted
class_name NeonAssets

const MENU_BACKGROUNDS := preload("res://assets/generated/neon_ecology/menu_backgrounds_sheet.png")
const BRAND_ICON := preload("res://assets/generated/neon_ecology/slices/brand_icon.png")
const SETTINGS_ICON := preload("res://assets/generated/neon_ecology/slices/settings_icon.png")
const QUIT_ICON := preload("res://assets/generated/neon_ecology/slices/quit_icon.png")

const MAIN_MENU_BG := Rect2(0, 0, 768, 512)
const PAUSE_BG := Rect2(768, 0, 768, 512)
const GAME_OVER_BG := Rect2(0, 512, 768, 512)
const SETTINGS_BG := Rect2(768, 512, 768, 512)

static func atlas_texture(source: Texture2D, region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = source
	texture.region = region
	return texture
