extends StageScene
## PROLOG I — Pengadilan Sinode.
## The Scholar is judged by the masked Synod and sentenced to the Penance of
## the Burden.

const SPR := "res://assets/sprites/"
const SELF_PATH := "res://scenes/prologue/p1_tribunal.tscn"

var mc: Actor
var arbiter: Actor
var council: Array[Actor] = []
var guards: Array[Actor] = []
var sigil_light: FlickerLight
var shafts: Array[Polygon2D] = []
var window_glow: Sprite2D


func setup() -> void:
	post.apply_preset("tribunal")
	ambient.color = Color(0.36, 0.3, 0.44)
	cam.position = Vector2(240, 60)
	cam.zoom = Vector2(4, 4)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = 480
	cam.limit_bottom = 270

	add_sprite(SPR + "backgrounds/tribunal.png", Vector2.ZERO, ground, true, false)
	# window glow sits on the ground layer so characters stay in front of it
	window_glow = Sprite2D.new()
	window_glow.texture = UIKit.tex(SPR + "backgrounds/tribunal_e.png")
	window_glow.centered = false
	window_glow.material = FX.additive()
	window_glow.modulate = Color(1.6, 1.5, 1.6, 0.9)
	ground.add_child(window_glow)

	# god-rays from the three stained-glass windows
	var ray_cols := [Color(0.9, 0.35, 0.5, 0.20), Color(1.0, 0.8, 0.45, 0.26), Color(0.45, 0.5, 1.0, 0.2)]
	var xs := [96.0, 240.0, 384.0]
	for i in 3:
		var x: float = xs[i]
		shafts.append(add_shaft(Vector2(x, 30), 34.0, Vector2(x + 34.0, 262), 92.0, ray_cols[i]))
		add_light(Vector2(x + 20.0, 170), Color(ray_cols[i], 1.0), 0.55, 190.0, 0.0, 70.0)
	spawn_fx(FX.dust(Vector2(420, 220), 70, Color(1.0, 0.92, 0.75)), Vector2(240, 150))

	# candelabras along the carpet
	for p in [Vector2(196, 196), Vector2(284, 196), Vector2(186, 246), Vector2(294, 246)]:
		add_prop(SPR + "props/candelabra.png", p)
		for dx in [-5.0, 0.0, 5.0]:
			add_flame(p + Vector2(dx, -31))
		add_light(p + Vector2(0, -30), Color(1.0, 0.62, 0.3), 0.9, 120.0, 0.22, 20.0)

	# foreground pillars for depth
	add_prop(SPR + "props/pillar.png", Vector2(26, 286))
	add_prop(SPR + "props/pillar.png", Vector2(454, 286))

	# the Synod behind the bench
	var cx := [172.0, 206.0, 274.0, 308.0]
	for i in 4:
		council.append(add_actor("council", Vector2(cx[i], 110)))
	arbiter = add_actor("arbiter", Vector2(240, 112))
	sigil_light = add_light(Vector2(240, 120), Color("ffcc60"), 0.0, 140.0, 0.1, 30.0)

	# the accused
	mc = add_actor("mc", Vector2(240, 214))
	mc.pose("mc_poses", 5)
	guards.append(add_actor("guard", Vector2(212, 222), "up"))
	guards.append(add_actor("guard", Vector2(268, 222), "up"))


func run() -> void:
	GameState.chapter = "prolog"
	GameState.save_game(SELF_PATH)
	cutscene = true
	cine.set_black(1.0)
	Audio.play_ambience("hall")
	await cine.letterbox(true, 0.01)
	await cine.narration([
		"Di Teokrasi Valcrest, cahaya para dewa adalah hukum.",
		"Dan setiap hukum membutuhkan seseorang untuk dihukum.",
	], 2.4, true)
	Audio.play_music("tribunal", 2.0)
	var t := cam.pan_zoom_tween(Vector2(240, 150), 3.0, 6.0)
	await cine.fade_black(0.0, 2.0)
	cine.location("KATEDRAL SINODE", "VALCREST  ·  HARI PENGHAKIMAN", 3.5)
	await StageCamera.wait_tween(t)
	await snap("tribunal_wide")

	for i in 3:
		Audio.sfx("gavel", -2.0)
		shake(0.25, 3.0)
		await wait(0.55)

	await cam.pan_zoom(Vector2(240, 120), 3.4, 1.2)
	await say("arbiter", "Berlututlah lebih dalam, Cendekia... ah. Maaf. Rantaimu memang terlalu berat untuk itu.")
	await say("council1", "Terdakwa: {name}. Cendekia Menara Arsip Valcrest. Penjaga gulungan tingkat tiga.")
	await say("council2", "Dakwaan pertama: menyalin kitab-kitab yang telah dibakar oleh Sinode.")
	await say("council3", "Dakwaan kedua: menulis bahwa mukjizat para dewa... dapat diukur. Dengan timbangan. Seperti gandum.")
	Audio.sfx("heartbeat", -4.0)
	await say("council4", "Dakwaan ketiga, dan yang paling keji: menyusun sebuah dosier tentang Yang Terbuang.")
	await say("arbiter", "Dosier itu telah kami bakar. Halaman demi halaman. Baunya seperti kebohongan yang akhirnya diam.")

	await cam.pan_zoom(Vector2(240, 180), 3.6, 1.0)
	mc.pose("mc_poses", 0)
	await say("mc", "...Kalian membakar tiga ratus dua belas halaman catatan kaki.", "pain")
	await say("mc", "Itu kejahatan yang jauh lebih berat daripada apa pun yang pernah kutulis.", "smirk")
	await cam.pan_zoom(Vector2(240, 120), 3.4, 0.8)
	await say("council5", "Ia tidak menyesal.")
	await say("arbiter", "Tentu saja tidak. Orang pintar jarang menyesal. Mereka hanya... menghitung ulang.")
	await say("arbiter", "Bicaralah untuk terakhir kalinya di hadapan cahaya, {name}. Apa pembelaanmu?")

	var pick: int = await choose([
		"\"Aku hanya mencatat apa yang kulihat.\"",
		"\"Kalau cahaya kalian nyata, kenapa takut diukur?\"",
		"(Diam. Tatap topeng Arbiter.)",
	])
	await cam.pan_zoom(Vector2(240, 180), 3.6, 0.6)
	match pick:
		0:
			GameState.set_flag("tribunal_answer", "honest")
			await say("mc", "Aku hanya mencatat apa yang kulihat. Seorang cendekia tidak memilih kebenarannya.", "neutral")
			await say("arbiter", "Mata adalah pintu dosa yang paling lebar. Dan kau membiarkannya terbuka lebar-lebar.")
		1:
			GameState.set_flag("tribunal_answer", "defiant")
			await say("mc", "Kalau cahaya kalian memang nyata... kenapa kalian begitu takut ia diukur?", "angry")
			Audio.sfx("gavel", 0.0)
			shake(0.5, 5.0)
			post.flash(Color(1.0, 0.3, 0.2), 0.3, 0.35)
			await say("arbiter", "...Lancang.")
			await say("council2", "Bahkan sekarang ia masih berkhotbah dengan lidah sesatnya.")
		_:
			GameState.set_flag("tribunal_answer", "silent")
			await think("Topeng perak. Mata merah di balik celahnya. Dari jarak ini aku bisa menghitung ukirannya: empat belas garis.", "closed")
			await say("arbiter", "Diam. Akhirnya, sesuatu yang bijaksana keluar darimu.")

	# The sentence
	await cam.pan_zoom(Vector2(240, 118), 3.2, 1.0)
	arbiter.pose("synod_poses", 0)
	for c in council:
		c.pose("synod_poses", 1)
	Audio.duck_music(-14.0, 0.5)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(sigil_light, "base_energy", 2.2, 1.2)
	for s in shafts:
		tw.tween_property(s, "modulate", Color(1.6, 1.4, 1.2), 1.2)
	await say("arbiter", "Maka dengarlah keputusan Sinode Cahaya Abadi.")
	await say("arbiter", "Tangan yang menulis akan dirantai. Kaki yang berjalan ke arsip terlarang akan dirantai.")
	await say("arbiter", "Dan punggung yang memikul kesombongan itu... akan memikul gunung.", "neutral", {"shout": true})
	Audio.sfx("thunder", -2.0)
	post.flash(Color(1.0, 0.95, 0.8), 0.6, 0.8)
	shake(0.7, 6.0)
	await snap("tribunal_sentence")
	await cam.pan_zoom(Vector2(240, 180), 3.6, 0.6)
	mc.pose("mc_poses", 1)
	await say("mc", "Maaf— gunung? Secara harfiah? Atau ini kiasan teologis yang belum kubaca?", "surprised")
	await cam.pan_zoom(Vector2(240, 125), 3.3, 0.6)
	await say("arbiter", "Di Puncak Penyesalan, kau akan memikul Batu Penebus sampai dosamu terbayar... atau tulangmu menyerah.")
	await say("arbiter", "Mana yang lebih dulu, biarlah para dewa yang memutuskan. Bawa dia.")
	await close_dialogue()
	Audio.sfx("gavel", 0.0)
	shake(0.4, 4.0)

	# Guards drag the Scholar away
	for g in guards:
		g.face("down")
	mc.clear_pose()
	mc.face("down")
	await wait(0.4)
	Audio.unduck_music(1.0)
	var m1 := mc.walk_to(Vector2(240, 300), 26.0)
	guards[0].walk_to(Vector2(212, 306), 26.0)
	guards[1].walk_to(Vector2(268, 306), 26.0)
	await cam.pan_zoom(Vector2(240, 150), 3.0, 1.5)
	await StageCamera.wait_tween(m1)
	await cine.fade_black(1.0, 1.2)
	Audio.stop_music(2.0)
	await cine.narration([
		"Batu itu tidak pernah dibuat untuk diangkat.",
		"Ia dibuat untuk diingat.",
	], 2.2, true)
	Audio.stop_ambience(1.0)
	Router.goto("res://scenes/prologue/p2_burden.tscn", "fade")
