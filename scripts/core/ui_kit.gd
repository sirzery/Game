class_name UIKit
extends RefCounted
## Shared look of the Persona-inspired interface: palette, fonts and small
## factory helpers for labels and textures.

const RED := Color("c8102e")
const RED_DARK := Color("6a0816")
const BLACK := Color("0b090d")
const INK := Color("16121a")
const BONE := Color("f2ece0")
const GOLD := Color("e0b04a")
const CYAN := Color("40e8ff")
const GREY := Color("8a8494")

const FONT_HEAD := "res://assets/fonts/Anton-Regular.ttf"
const FONT_BODY := "res://assets/fonts/NotoSans-Variable.ttf"
const FONT_TITLE := "res://assets/fonts/Cinzel-Variable.ttf"
const FONT_PIXEL := "res://assets/fonts/PixelifySans-Variable.ttf"

## Colour accents per speaker (used for the portrait backdrop & name tag).
const SPEAKER_COLORS := {
	"mc": Color("2e3a6a"),
	"arbiter": Color("8a1424"),
	"council": Color("a07a2a"),
	"saint": Color("e0c060"),
	"exiled": Color("1a6a7a"),
	"maren": Color("3e6a46"),
	"guard": Color("5a5e6e"),
	"hunter": Color("4a0c18"),
	"narrator": Color("2a2430"),
}

static var _fonts: Dictionary = {}
## Keeps textures alive: a texture loaded inside _draw() would otherwise be
## freed as soon as the function returns and render as a white square.
static var _textures: Dictionary = {}


static func clear_caches() -> void:
	_fonts.clear()
	_textures.clear()


static func font(path: String, weight: int = 400) -> Font:
	var key := "%s@%d" % [path, weight]
	if _fonts.has(key):
		return _fonts[key]
	var base := load(path) as Font
	if base == null:
		base = ThemeDB.fallback_font
	var f: Font = base
	if weight != 400:
		var fv := FontVariation.new()
		fv.base_font = base
		var ts := TextServerManager.get_primary_interface()
		fv.variation_opentype = {ts.name_to_tag("wght"): weight}
		f = fv
	_fonts[key] = f
	return f


static func head_font() -> Font:
	return font(FONT_HEAD)


static func body_font(weight: int = 500) -> Font:
	return font(FONT_BODY, weight)


static func title_font(weight: int = 700) -> Font:
	return font(FONT_TITLE, weight)


static func label(text: String, size: int = 24, color: Color = BONE, f: Font = null,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", f if f != null else body_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func outline(l: Label, size: int = 6, color: Color = BLACK) -> Label:
	l.add_theme_constant_override("outline_size", size)
	l.add_theme_color_override("font_outline_color", color)
	return l


static func shadow(l: Label, offset: Vector2 = Vector2(4, 4), color: Color = Color(0, 0, 0, 0.85)) -> Label:
	l.add_theme_color_override("font_shadow_color", color)
	l.add_theme_constant_override("shadow_offset_x", int(offset.x))
	l.add_theme_constant_override("shadow_offset_y", int(offset.y))
	return l


static func tex(path: String) -> Texture2D:
	if path == "":
		return null
	if _textures.has(path):
		return _textures[path]
	if not ResourceLoader.exists(path):
		push_warning("Tekstur tidak ditemukan: %s" % path)
		return null
	var t := load(path) as Texture2D
	_textures[path] = t
	return t


static func lit_tex(path: String) -> Texture2D:
	## Diffuse texture + its auto-generated "_n" normal map, if present.
	var key := "lit:" + path
	if _textures.has(key):
		return _textures[key]
	var diffuse := tex(path)
	var npath := path.replace(".png", "_n.png")
	if diffuse == null or not ResourceLoader.exists(npath):
		return diffuse
	var ct := CanvasTexture.new()
	ct.diffuse_texture = diffuse
	ct.normal_texture = tex(npath)
	_textures[key] = ct
	return ct


static func radial_light_texture(size: int = 256, soft: float = 1.0) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.35 * soft, Color(1, 1, 1, 0.55))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = size
	t.height = size
	return t


static func linear_gradient_texture(top: Color, bottom: Color, w: int = 8, h: int = 128) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, top)
	g.set_color(1, bottom)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill_from = Vector2(0.5, 0.0)
	t.fill_to = Vector2(0.5, 1.0)
	t.width = w
	t.height = h
	return t


static func full_rect(c: Control) -> Control:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.offset_left = 0
	c.offset_top = 0
	c.offset_right = 0
	c.offset_bottom = 0
	return c
