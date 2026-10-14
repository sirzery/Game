class_name DossierCard
extends Control
## Close-up of the Synod's dossier on the Scholar, with a stamped verdict.

var _stamp_k: float = 0.0:
	set(v):
		_stamp_k = v
		queue_redraw()
var _stamp: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	var paper := Control.new()
	paper.position = Vector2(270, 70)
	paper.rotation = deg_to_rad(-4.0)
	add_child(paper)
	var head := UIKit.label("SINODE CAHAYA ABADI  ·  ARSIP RAHASIA", 20, Color("5a2a1a"), UIKit.title_font(800))
	head.position = Vector2(60, 30)
	paper.add_child(head)
	var title := UIKit.label("DOSIER  No. 0114", 54, Color("2a1410"), UIKit.title_font(900))
	title.position = Vector2(60, 60)
	paper.add_child(title)
	var pic := TextureRect.new()
	pic.texture = UIKit.tex("res://assets/sprites/portraits/mc_neutral.png")
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.size = Vector2(150, 150)
	pic.position = Vector2(548, 6)
	pic.modulate = Color(0.95, 0.8, 0.62)
	paper.add_child(pic)
	var rows := [
		["SUBJEK", GameState.player_name],
		["ASAL", "Menara Arsip Valcrest"],
		["DAKWAAN", "Penyesatan, pengukuran mukjizat,"],
		["", "bersekutu dengan Yang Terbuang (dugaan)"],
		["HUKUMAN", "Beban di Puncak Penyesalan"],
		["STATUS", "HILANG. Batu Penebus hancur."],
		["PERINTAH", "Temukan. Bawa kembali. HIDUP."],
	]
	var y := 160.0
	for r in rows:
		if str(r[0]) != "":
			var k := UIKit.label(str(r[0]), 20, Color("7a2a1a"), UIKit.head_font())
			k.position = Vector2(60, y + 2)
			paper.add_child(k)
		var v := UIKit.label(str(r[1]), 20, Color("2a1410"), UIKit.title_font(700))
		v.position = Vector2(190, y)
		paper.add_child(v)
		y += 40.0
	_stamp = UIKit.label("BURONAN", 92, Color(0.75, 0.08, 0.12, 0.0), UIKit.head_font())
	_stamp.position = Vector2(500, 500)
	_stamp.pivot_offset = Vector2(150, 50)
	_stamp.rotation = deg_to_rad(-14.0)
	add_child(_stamp)


func show_card() -> void:
	modulate.a = 0.0
	position.y = 60.0
	Audio.sfx("swoosh_big", -6.0)
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "modulate:a", 1.0, 0.4)
	t.tween_property(self, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await t.finished


func stamp() -> void:
	_stamp.scale = Vector2(2.2, 2.2)
	var t := create_tween().set_parallel(true)
	t.tween_property(_stamp, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(_stamp, "theme_override_colors/font_color", Color(0.75, 0.08, 0.12, 0.92), 0.12)
	await t.finished
	Audio.sfx("gavel", 0.0)
	_stamp_k = 1.0


func hide_card() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.5)
	await t.finished


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.6))
	draw_set_transform(Vector2(270, 70), deg_to_rad(-4.0), Vector2.ONE)
	draw_rect(Rect2(10, 10, 720, 560), Color(0, 0, 0, 0.5))
	draw_rect(Rect2(0, 0, 720, 560), Color("e8d8b4"))
	draw_rect(Rect2(0, 0, 720, 560), Color("8a6a40"), false, 4.0)
	draw_line(Vector2(50, 128), Vector2(530, 128), Color("7a2a1a"), 3.0)
	# photo clipped to the corner of the file
	draw_rect(Rect2(540, -2, 166, 166), Color("f4ecd8"))
	draw_rect(Rect2(540, -2, 166, 166), Color("8a6a40"), false, 2.0)
	draw_rect(Rect2(600, -16, 14, 34), Color("7a7c88"))
	for i in 6:
		draw_circle(Vector2(30 + i * 120, 540), 3.0 + float(i % 3), Color(0.5, 0.35, 0.2, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _stamp_k > 0.0:
		draw_circle(Vector2(650, 550), 60.0, Color(0.75, 0.08, 0.12, 0.12))
