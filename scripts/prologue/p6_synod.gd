extends StageScene
## PROLOG VI — Ruang Arsip Sinode (epilogue).
## The High Arbiter opens a dossier on the escaped Scholar and sends a hunter.

const SPR := "res://assets/sprites/"
const SELF_PATH := "res://scenes/prologue/p6_synod.tscn"

var arbiter: Actor
var hunter: Actor
var window_glow: Sprite2D


func setup() -> void:
	post.apply_preset("synod")
	ambient.color = Color(0.32, 0.26, 0.36)
	cam.position = Vector2(213, 130)
	cam.zoom = Vector2(3, 3)
	add_sprite(SPR + "backgrounds/synod_chamber.png", Vector2.ZERO, ground, true, false)
	window_glow = Sprite2D.new()
	window_glow.texture = UIKit.tex(SPR + "backgrounds/synod_chamber_e.png")
	window_glow.centered = false
	window_glow.material = FX.additive()
	window_glow.modulate = Color(1.2, 0.8, 0.9, 0.8)
	ground.add_child(window_glow)
	add_shaft(Vector2(213, 30), 40.0, Vector2(250, 236), 110.0, Color(0.55, 0.6, 1.0, 0.16))
	add_light(Vector2(220, 120), Color(0.55, 0.6, 1.0), 0.5, 260.0, 0.0, 80.0)
	spawn_fx(FX.dust(Vector2(200, 200), 30, Color(0.8, 0.85, 1.0)), Vector2(220, 140))
	arbiter = add_actor("arbiter", Vector2(213, 168), "down")
	add_prop(SPR + "props/desk.png", Vector2(213, 194))
	add_flame(Vector2(180, 151))
	add_sprite(SPR + "props/candelabra.png", Vector2(180, 170), world)
	add_light(Vector2(180, 150), Color(1.0, 0.6, 0.3), 1.3, 170.0, 0.25, 18.0)
	hunter = add_actor("hunter", Vector2(213, 226), "up")


func run() -> void:
	GameState.save_game(SELF_PATH)
	cutscene = true
	cine.set_black(1.0)
	await cine.letterbox(true, 0.01)
	Audio.play_music("synod", 2.0)
	Audio.play_ambience("hall")
	await cine.fade_black(0.0, 1.5)
	cine.location("KATEDRAL SINODE · RUANG ARSIP", "MALAM YANG SAMA", 3.0)
	await cam.pan_zoom(Vector2(213, 150), 3.4, 2.5)
	await snap("synod_room")
	await say("arbiter", "Batu Penebus hancur. Rantainya putus. Tahanannya hilang.")
	await say("hunter", "Dan Santa Ilvaine?", "neutral")
	await say("arbiter", "Santa Ilvaine sedang memburu sesuatu yang lebih besar. Atau begitulah yang ia yakini.")
	await say("arbiter", "Ia meninggalkan seorang cendekia hidup-hidup di bawah reruntuhan. Para santa memang tidak pernah pandai menghitung.")
	await say("hunter", "Anjing pemburu yang dikirim ke lereng utara juga tidak kembali.", "closed")
	await say("arbiter", "Maka mulailah dari tempat anjing itu mati.")
	await close_dialogue()

	var card := DossierCard.new()
	UIKit.full_rect(card)
	cine.root.add_child(card)
	await card.show_card()
	await wait(0.6)
	await card.stamp()
	shake(0.3, 3.0)
	await snap("synod_dossier")
	await say("arbiter", "Ia menulis tentang kami, Corvin. Sebuah dosier. Halaman demi halaman.")
	await say("arbiter", "Sekarang giliran kami menulis tentang dia.")
	await close_dialogue()
	await card.hide_card()
	card.queue_free()

	await say("hunter", "Hidup atau mati?", "angry")
	await say("arbiter", "Hidup. Orang mati tidak bisa memberi tahu kita...")
	await say("arbiter", "...siapa lagi yang sudah membaca catatannya.")
	await say("hunter", "Seperti kehendak Sinode.", "closed")
	await close_dialogue()
	hunter.face("down")
	await hunter.move_to(Vector2(213, 300), 40.0)
	Audio.sfx("crow", -4.0)
	await wait(0.5)
	await cam.pan_zoom(Vector2(213, 110), 3.8, 1.5)
	var t := create_tween()
	t.tween_property(window_glow, "modulate", Color(2.0, 0.4, 0.4, 1.0), 1.5)
	Audio.sfx("heartbeat", 0.0)
	await say("arbiter", "Kau melihat sesuatu di puncak itu, Cendekia.")
	await say("arbiter", "Dan aku ingin tahu apa.", "neutral", {"shout": true})
	await close_dialogue()
	Audio.stop_music(2.0)
	await cine.fade_black(1.0, 1.5)

	GameState.set_flag("prologue_complete")
	GameState.chapter = "bab1"
	GameState.save_game(SELF_PATH)
	cine.skip_hint.visible = false
	await cine.chapter_card("DOSIER", "PROLOG", "Beban Sang Cendekia — Selesai", 2.6)
	Audio.play_music("title", 1.5)
	var end := EndingCard.new()
	UIKit.full_rect(end)
	cine.root.add_child(end)
	await end.run()
	Router.goto("res://scenes/ui/title.tscn")
