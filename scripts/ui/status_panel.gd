class_name StatusPanel
extends Control
## Persona-style status page: stats and inventory. await run() until closed.


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	UIKit.full_rect(self)


func _ready() -> void:
	var m := GameState.mc
	var title := UIKit.label("STATUS", 72, UIKit.BONE, UIKit.head_font())
	UIKit.shadow(title, Vector2(6, 6), UIKit.RED)
	title.position = Vector2(100, 40)
	title.rotation = deg_to_rad(-4.0)
	add_child(title)
	var portrait := TextureRect.new()
	portrait.texture = UIKit.tex("res://assets/sprites/portraits/mc_smirk.png")
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.size = Vector2(360, 360)
	portrait.position = Vector2(60, 200)
	add_child(portrait)
	var nm := UIKit.label(GameState.player_name.to_upper(), 54, UIKit.BONE, UIKit.head_font())
	UIKit.outline(nm, 8, UIKit.BLACK)
	nm.position = Vector2(470, 150)
	add_child(nm)
	var cls := UIKit.label("CENDEKIA BURONAN  ·  LV %d" % int(m["level"]), 24, UIKit.GOLD, UIKit.head_font())
	cls.position = Vector2(474, 222)
	add_child(cls)
	var stats := [
		["HP", "%d / %d" % [int(m["hp"]), int(m["max_hp"])]],
		["SP", "%d / %d" % [int(m["sp"]), int(m["max_sp"])]],
		["SERANG", str(m["atk"])],
		["CENDEKIA", str(m["mag"])],
		["BERTAHAN", str(m["def"])],
		["KECEPATAN", str(m["spd"])],
		["EXP", "%d / %d" % [int(m["exp"]), int(m["next"])]],
	]
	var y := 270.0
	for row in stats:
		var k := UIKit.label(str(row[0]), 26, Color("c8c0b8"), UIKit.head_font())
		k.position = Vector2(480, y)
		add_child(k)
		var v := UIKit.label(str(row[1]), 26, UIKit.BONE, UIKit.head_font())
		v.position = Vector2(660, y)
		add_child(v)
		y += 40.0
	var inv_t := UIKit.label("KANTONG", 34, UIKit.BONE, UIKit.head_font())
	UIKit.shadow(inv_t, Vector2(4, 4), UIKit.RED)
	inv_t.position = Vector2(880, 250)
	add_child(inv_t)
	var iy := 304.0
	var names := {"dahan": "Dahan Kering", "batu": "Batu Pipih", "kantong_air": "Kantong Air"}
	for id in GameState.inventory.keys():
		var label_text := str(names.get(id, id))
		if BattleData.ITEMS.has(id):
			label_text = str(BattleData.ITEMS[id]["name"])
		var l := UIKit.label("%s  x%d" % [label_text, int(GameState.inventory[id])], 22, UIKit.BONE, UIKit.body_font(700))
		l.position = Vector2(890, iy)
		add_child(l)
		iy += 34.0
	if GameState.inventory.is_empty():
		var e := UIKit.label("(kosong)", 22, Color(1, 1, 1, 0.5), UIKit.body_font(500))
		e.position = Vector2(890, iy)
		add_child(e)
	var hint := UIKit.label("ESC / ENTER · KEMBALI", 20, Color(1, 1, 1, 0.55), UIKit.head_font())
	hint.position = Vector2(1000, 670)
	add_child(hint)


func run() -> void:
	var waited := 0.0
	while true:
		await get_tree().process_frame
		waited += get_process_delta_time()
		if Settings.autotest and waited > 0.3:
			break
		if waited > 0.15 and (Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("accept")):
			break
	Audio.sfx("ui_cancel", -4.0)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.03, 0.01, 0.03, 0.94))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 640), Vector2(1280, 520), Vector2(1280, 720), Vector2(0, 720)]),
		UIKit.RED_DARK)
	draw_colored_polygon(PackedVector2Array([Vector2(440, 140), Vector2(1240, 120), Vector2(1220, 600),
		Vector2(430, 620)]), Color(0, 0, 0, 0.6))
