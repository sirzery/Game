extends StageScene
## The player names the Scholar.

var ui: CanvasLayer
var edit: LineEdit
var _submitted: bool = false
var _name: String = ""


func setup() -> void:
	allow_skip = false
	post.apply_preset("title")
	post.set_param("tilt_amount", 0.0)
	add_sky({
		"top_color": Color("050306"), "bottom_color": Color("2a0610"),
		"cloud_dark": Color("0e0408"), "cloud_light": Color("3a0c16"),
		"cloud_cover": 0.45, "cloud_scale": 1.8, "cloud_speed": Vector2(-0.008, 0.0),
	})
	ui = CanvasLayer.new()
	ui.layer = 60
	add_child(ui)
	var root := UIKit.full_rect(Control.new())
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)

	var bd := PortraitBackdrop.new()
	bd.position = Vector2(40, 120)
	bd.size = Vector2(460, 420)
	bd.scale = Vector2(1.2, 1.2)
	bd.set_color(UIKit.SPEAKER_COLORS["mc"])
	root.add_child(bd)
	var portrait := TextureRect.new()
	portrait.texture = UIKit.tex("res://assets/sprites/portraits/mc_neutral.png")
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.position = Vector2(80, 150)
	portrait.size = Vector2(440, 440)
	root.add_child(portrait)

	var deco := NameEntryDeco.new()
	UIKit.full_rect(deco)
	root.add_child(deco)

	var q := UIKit.label("SIAPA NAMAMU?", 92, UIKit.BONE, UIKit.head_font())
	UIKit.shadow(q, Vector2(7, 7), UIKit.RED)
	q.position = Vector2(560, 110)
	q.rotation = deg_to_rad(-5.0)
	root.add_child(q)

	var d := UIKit.label("Cendekia Menara Arsip Valcrest. Terdakwa.\nNama yang akan dibacakan Sinode di hadapan para dewa.",
		24, Color("d8cfc0"), UIKit.body_font(500))
	d.position = Vector2(590, 250)
	d.rotation = deg_to_rad(-5.0)
	root.add_child(d)

	edit = LineEdit.new()
	edit.placeholder_text = GameState.DEFAULT_NAME
	edit.max_length = 12
	edit.position = Vector2(610, 380)
	edit.size = Vector2(520, 76)
	edit.rotation = deg_to_rad(-5.0)
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.add_theme_font_override("font", UIKit.head_font())
	edit.add_theme_font_size_override("font_size", 46)
	edit.add_theme_color_override("font_color", UIKit.BONE)
	edit.add_theme_color_override("font_placeholder_color", Color(1, 1, 1, 0.3))
	edit.add_theme_color_override("caret_color", UIKit.RED)
	var sb := StyleBoxFlat.new()
	sb.bg_color = UIKit.BLACK
	sb.border_color = UIKit.BONE
	sb.set_border_width_all(4)
	sb.skew = Vector2(0.15, 0)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	edit.add_theme_stylebox_override("normal", sb)
	var sbf := sb.duplicate() as StyleBoxFlat
	sbf.border_color = UIKit.RED
	edit.add_theme_stylebox_override("focus", sbf)
	edit.text_submitted.connect(_on_submit)
	root.add_child(edit)

	var hint := UIKit.label("KETIK NAMA  ·  ENTER = KONFIRMASI  ·  KOSONG = \"%s\"" % GameState.DEFAULT_NAME,
		20, Color(1, 1, 1, 0.55), UIKit.body_font(700))
	hint.position = Vector2(620, 492)
	hint.rotation = deg_to_rad(-5.0)
	root.add_child(hint)


func _on_submit(t: String) -> void:
	_name = t
	_submitted = true


func run() -> void:
	Audio.play_music("title", 1.0)
	while true:
		_submitted = false
		edit.editable = true
		edit.grab_focus()
		if Settings.autotest:
			await wait(0.3)
			edit.text = "Elias"
			_on_submit(edit.text)
			await snap("name_entry")
		while not _submitted:
			await get_tree().process_frame
		edit.editable = false
		edit.release_focus()
		var clean := GameState.sanitize_name(_name)
		if clean == "":
			clean = GameState.DEFAULT_NAME
		edit.text = clean
		Audio.sfx("ui_confirm")
		var pick: int = await choose(["Ya. Itu namaku.", "Tunggu, ubah."], "Namamu %s. Benar?" % clean)
		await close_dialogue()
		if pick == 0:
			GameState.player_name = clean
			Audio.stop_music(1.2)
			Router.goto("res://scenes/prologue/p1_tribunal.tscn", "fade")
			return
		edit.text = ""
