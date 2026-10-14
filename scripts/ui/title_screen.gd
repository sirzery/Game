extends StageScene
## Title screen: the Scholar under the mountain-stone, a crimson moon and the
## Persona-style main menu.

const SPR := "res://assets/sprites/"

var ui: CanvasLayer
var menu: PersonaMenu
var _crows: Array[Sprite2D] = []
var _t: float = 0.0


func setup() -> void:
	allow_skip = false
	post.apply_preset("title")
	cam.position = Vector2.ZERO
	cam.zoom = Vector2(3, 3)
	add_sky({
		"top_color": Color("0c0410"), "bottom_color": Color("6a1424"),
		"cloud_dark": Color("1e0a14"), "cloud_light": Color("5a1a28"),
		"cloud_cover": 0.55, "cloud_scale": 2.6, "cloud_speed": Vector2(0.01, 0.0),
		"moon_visible": 1.0, "moon_pos": Vector2(0.6, 0.2), "moon_size": 0.1,
		"moon_color": Color("ff6a40"), "stars": 0.35,
	})
	ambient.color = Color(0.72, 0.6, 0.66)
	var far := add_sprite(SPR + "backgrounds/peak_far.png", Vector2(0, 30), ground, false)
	far.modulate = Color(0.35, 0.12, 0.16)
	var mid := add_sprite(SPR + "backgrounds/peak_mid.png", Vector2(0, 62), ground, false)
	mid.modulate = Color(0.2, 0.06, 0.1)
	var cliff := add_sprite(SPR + "backgrounds/peak_ground.png", Vector2(60, 140), ground, true)
	cliff.modulate = Color(0.55, 0.45, 0.5)

	# the colossal stone and the Scholar beneath it
	var stone := add_sprite(SPR + "backgrounds/stone_colossal.png", Vector2(110, -33), ground, true)
	stone.scale = Vector2(0.42, 0.42)
	stone.modulate = Color(0.85, 0.72, 0.8)
	var runes := add_glow_sprite(SPR + "backgrounds/stone_colossal_e.png", Vector2(110, -33), Color(0.6, 1.0, 1.1))
	runes.scale = Vector2(0.42, 0.42)
	var mc := add_actor("mc", Vector2(110, 96))
	mc.pose("mc_poses", 2)
	for side in [-1.0, 1.0]:
		var stake := add_prop(SPR + "props/iron_stake.png", Vector2(110 + side * 46.0, 98))
		stake.modulate = Color(0.8, 0.8, 0.85)
		var ch := ChainLine.new(Vector2(110 + side * 9.0, 92), Vector2(110 + side * 46.0, 82), 6.0)
		world.add_child(ch)

	add_light(Vector2(220, -60), Color("ff5a3a"), 1.4, 520.0, 0.0, 60.0)
	add_light(Vector2(110, 40), Color("40e8ff"), 0.7, 180.0, 0.25, 20.0)
	add_light(Vector2(-160, 40), Color("8a2a4a"), 0.6, 400.0, 0.0, 40.0)

	spawn_fx(FX.ash(Vector2(520, 10), 70), Vector2(0, -150), false)
	spawn_fx(FX.embers(Vector2(420, 60), 30, Color(1.0, 0.4, 0.2)), Vector2(0, 110))

	for i in 3:
		var c := Sprite2D.new()
		c.texture = UIKit.tex(SPR + "characters/crow.png")
		c.hframes = 2
		c.frame = 1
		c.position = Vector2(-260.0 - float(i) * 70.0, -70.0 + float(i) * 14.0)
		c.modulate = Color(0.1, 0.05, 0.08)
		world.add_child(c)
		_crows.append(c)

	_build_ui()


func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 60
	add_child(ui)
	var root := UIKit.full_rect(Control.new())
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)

	var slash := TitleSlash.new()
	UIKit.full_rect(slash)
	root.add_child(slash)

	var small := UIKit.label("SEBUAH KISAH DARI TEOKRASI VALCREST", 22, UIKit.GOLD, UIKit.head_font())
	small.position = Vector2(84, 58)
	small.rotation = deg_to_rad(-4.0)
	root.add_child(small)

	var logo := UIKit.label("DOSIER", 150, UIKit.BONE, UIKit.title_font(900))
	UIKit.shadow(logo, Vector2(8, 8), UIKit.RED)
	UIKit.outline(logo, 4, UIKit.BLACK)
	logo.position = Vector2(64, 76)
	logo.rotation = deg_to_rad(-4.0)
	root.add_child(logo)

	var sub := UIKit.label("PROLOG  ·  BEBAN SANG CENDEKIA", 30, UIKit.BLACK, UIKit.head_font())
	sub.position = Vector2(118, 268)
	sub.rotation = deg_to_rad(-4.0)
	root.add_child(sub)

	var tagline := UIKit.label("Mereka membakar catatannya. Ia mengingat setiap halaman.", 20,
		Color(1, 0.92, 0.85, 0.85), UIKit.title_font(600))
	tagline.position = Vector2(96, 318)
	tagline.rotation = deg_to_rad(-4.0)
	root.add_child(tagline)

	var footer := UIKit.label("v0.1 PROLOG  ·  ↑↓ PILIH  ·  ENTER KONFIRMASI", 18, Color(1, 1, 1, 0.5),
		UIKit.body_font(700))
	footer.position = Vector2(800, 684)
	root.add_child(footer)

	menu = PersonaMenu.new(["MULAI BARU", "LANJUTKAN", "PENGATURAN", "KELUAR"],
		[false, not GameState.has_save(), false, false])
	menu.origin = Vector2(96, 400)
	menu.spacing = 66.0
	menu.font_size = 50
	if GameState.has_save():
		menu.index = 1
	root.add_child(menu)


func _process(delta: float) -> void:
	super._process(delta)
	_t += delta
	for i in _crows.size():
		var c := _crows[i]
		c.position.x += delta * (22.0 + float(i) * 6.0)
		c.position.y += sin(_t * 2.0 + float(i)) * delta * 4.0
		c.frame = int(_t * 6.0 + float(i)) % 2
		if c.position.x > 260.0:
			c.position.x = -260.0


func run() -> void:
	Audio.play_music("title", 1.5)
	Audio.play_ambience("wind")
	await wait(0.6)
	await snap("title")
	if Settings.autotest:
		Settings.autotest_title_visits += 1
		if Settings.autotest_title_visits >= 2 or OS.get_cmdline_user_args().has("--title-only"):
			print("[autotest] COMPLETE: returned to title, play-through finished without stalls.")
			get_tree().quit()
			return
	while true:
		menu.autotest_pick = 0
		var choice: int = await menu.run()
		match choice:
			0:
				GameState.new_game()
				Audio.stop_ambience(0.8)
				Router.goto("res://scenes/ui/name_entry.tscn")
				return
			1:
				if GameState.load_game():
					Audio.stop_ambience(0.8)
					Router.goto(GameState.checkpoint)
					return
			2:
				var panel := SettingsPanel.new()
				ui.add_child(panel)
				menu.visible = false
				await panel.run()
				panel.queue_free()
				menu.visible = true
			3:
				get_tree().quit()
				return
