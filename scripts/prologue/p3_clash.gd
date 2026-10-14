extends PeakStage
## PROLOG III — Benturan.
## Saint Ilvaine hunts the Exiled across the Peak. Her stray lances snap the
## Scholar's chains and crack the binding runes; the Scholar shatters the
## stone himself — with a broken chain and a scholar's insight, not power.

const SELF_PATH := "res://scenes/prologue/p3_clash.tscn"
const EXILED_POS := Vector2(505, 236)
const SAINT_POS := Vector2(-6, 96)

var exiled: Sprite2D
var exiled_eyes: Array[Sprite2D] = []
var saint: Actor
var saint_light: PointLight2D
var halo_glow: Sprite2D
var cracks: Array[Line2D] = []
var fires: Array[Node2D] = []


func setup() -> void:
	super.setup()
	set_time_of_day(true, 0.01)
	ambient.color = Color(0.3, 0.32, 0.5)
	post.apply_preset("clash")
	cam.position = Vector2(240, 165)
	add_prop(SPR + "props/rock_1.png", EXILED_POS + Vector2(0, 8))
	add_prop(SPR + "props/rock_0.png", Vector2(-40, 250))
	add_prop(SPR + "props/rock_1.png", Vector2(560, 248))

	exiled = Sprite2D.new()
	exiled.texture = UIKit.lit_tex(SPR + "characters/exiled.png")
	exiled.hframes = 4
	exiled.offset = Vector2(0, -44)
	exiled.position = EXILED_POS + Vector2(0, -400)
	exiled.visible = false
	world.add_child(exiled)
	var ex_light := PointLight2D.new()
	ex_light.texture = UIKit.radial_light_texture(256)
	ex_light.texture_scale = 0.9
	ex_light.color = Color("40e8ff")
	ex_light.energy = 1.1
	ex_light.height = 30.0
	ex_light.position = Vector2(-20, -50)
	exiled.add_child(ex_light)
	for i in 2:
		var e := Sprite2D.new()
		e.texture = FX.soft_tex()
		e.scale = Vector2(0.5, 0.22)
		e.modulate = Color(0.4, 2.2, 2.6, 0.0)
		e.material = FX.additive()
		e.position = Vector2(330.0 + float(i) * 22.0, -10.0)
		glow.add_child(e)
		exiled_eyes.append(e)

	saint = Actor.new("saint")
	saint.position = SAINT_POS + Vector2(-60, -260)
	saint.visible = false
	world.add_child(saint)
	saint_light = PointLight2D.new()
	saint_light.texture = UIKit.radial_light_texture(256)
	saint_light.texture_scale = 1.2
	saint_light.color = Color("ffe090")
	saint_light.energy = 0.0
	saint_light.height = 40.0
	saint.add_child(saint_light)
	halo_glow = Sprite2D.new()
	halo_glow.texture = FX.soft_tex()
	halo_glow.scale = Vector2(1.2, 1.2)
	halo_glow.modulate = Color(1.4, 1.2, 0.7, 0.0)
	halo_glow.material = FX.additive()
	glow.add_child(halo_glow)


func _process(delta: float) -> void:
	super._process(delta)
	if saint and saint.visible:
		saint.sprite.position.y = sin(Time.get_ticks_msec() / 400.0) * 2.0
		halo_glow.position = saint.position + Vector2(0, -38)


# ---------------------------------------------------------------------------
# Effects
# ---------------------------------------------------------------------------
func impact(pos: Vector2, big: bool = false) -> void:
	spawn_fx(FX.burst(Color(1.0, 0.8, 0.4), 30 if big else 18, 140.0 if big else 90.0, 0.7), pos)
	spawn_fx(FX.debris(10 if big else 5, Color(0.3, 0.28, 0.34)), pos, false)
	var l := PointLight2D.new()
	l.texture = UIKit.radial_light_texture(256)
	l.texture_scale = 1.4 if big else 0.8
	l.color = Color("ffd070")
	l.energy = 2.5
	l.height = 20.0
	l.position = pos
	add_child(l)
	var t := l.create_tween()
	t.tween_property(l, "energy", 0.0, 0.5)
	t.tween_callback(l.queue_free)
	Audio.sfx("lance_impact", -8.0 if not big else -3.0, randf_range(0.9, 1.15))
	shake(0.45 if big else 0.25, 6.0 if big else 4.0)


func fire_lance(from: Vector2, to: Vector2, dur: float = 0.32, big: bool = false) -> void:
	var s := add_glow_sprite(SPR + "props/light_lance.png", from, Color(1.5, 1.35, 1.0))
	s.rotation = (to - from).angle()
	if big:
		s.scale = Vector2(1.6, 1.6)
	Audio.sfx("lance_whoosh", -14.0, randf_range(0.9, 1.25))
	var t := s.create_tween()
	t.tween_property(s, "position", to, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t.finished
	s.queue_free()
	impact(to, big)


func volley(targets: Array, spread_delay: float = 0.08) -> void:
	for tgt in targets:
		var to: Vector2 = tgt
		var from := Vector2(randf_range(-120.0, 160.0), randf_range(-170.0, -90.0))
		fire_lance(from, to, randf_range(0.25, 0.4))
		await wait(spread_delay)
	await wait(0.45)


func add_fire(pos: Vector2) -> void:
	var f := Flipbook.new(UIKit.tex(SPR + "props/flame.png"), 4, 10.0)
	f.position = pos
	f.scale = Vector2(2.0, 2.0)
	f.material = FX.additive()
	glow.add_child(f)
	fires.append(f)
	add_light(pos, Color(1.0, 0.55, 0.25), 1.1, 110.0, 0.3, 12.0)
	spawn_fx(FX.embers(Vector2(16, 6), 10), pos)


func crack_stone(level: int) -> void:
	Audio.sfx("stone_crack", -2.0, randf_range(0.85, 1.0))
	shake(0.5, 5.0)
	var l := Line2D.new()
	l.width = 1.5
	l.default_color = Color(1.6, 0.9, 0.6) if level > 1 else Color(0.6, 1.6, 1.8)
	l.material = FX.additive()
	var p := Vector2(240.0 + randf_range(-40.0, 40.0), 195.0)
	l.add_point(p)
	for i in 8 + level * 3:
		p += Vector2(randf_range(-14.0, 14.0), randf_range(-26.0, -10.0))
		l.add_point(p)
	glow.add_child(l)
	cracks.append(l)
	var t := create_tween()
	t.tween_property(runes, "modulate", Color(1.8, 0.7, 0.5, 1.0) if level > 1 else Color(1.2, 1.2, 1.2, 1.0), 0.08)
	t.tween_property(runes, "modulate", Color(0.7, 1.0, 1.1, 0.4 + 0.2 / float(level)), 0.4)
	rune_light.flicker = 0.6 + 0.2 * float(level)


# ---------------------------------------------------------------------------
# Script
# ---------------------------------------------------------------------------
func run() -> void:
	GameState.save_game(SELF_PATH)
	cutscene = true
	cine.set_black(1.0)
	await cine.letterbox(true, 0.01)
	Audio.play_ambience("rain", "wind")
	cam.position = Vector2(240, 160)
	cam.zoom = Vector2(3, 3)
	await cine.fade_black(0.0, 1.5)
	cine.location("PUNCAK PENYESALAN", "HARI KE-114  ·  MALAM BADAI", 3.0)
	await wait(1.0)
	lightning(1.0)
	await wait(0.6)

	# eyes in the clouds
	await cam.pan_zoom(Vector2(330, 40), 2.6, 1.6)
	for e in exiled_eyes:
		var te := create_tween()
		te.tween_property(e, "modulate:a", 1.0, 0.6)
	Audio.sfx("growl", -4.0, 0.7)
	await wait(1.2)
	await think("Dua titik cahaya. Terlalu tinggi untuk bintang. Terlalu biru untuk obor Sinode.", "surprised")
	await close_dialogue()

	# the Exiled lands
	for e in exiled_eyes:
		e.visible = false
	Audio.play_music("clash", 0.4)
	exiled.visible = true
	exiled.frame = 3
	var drop := create_tween()
	drop.tween_property(exiled, "position", EXILED_POS, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await cam.pan_zoom(Vector2(330, 165), 2.4, 0.4)
	await StageCamera.wait_tween(drop)
	exiled.frame = 0
	shake(1.0, 9.0)
	Audio.sfx("lance_impact", 0.0, 0.6)
	spawn_fx(FX.debris(40), EXILED_POS, false)
	spawn_fx(FX.smoke(Vector2(60, 10), 10), EXILED_POS + Vector2(0, -4), false)
	await wait(0.6)
	exiled.frame = 2
	Audio.sfx("roar", 0.0)
	shake(0.8, 7.0)
	post.flash(Color(0.4, 0.9, 1.0), 0.4, 0.3)
	await wait(1.4)
	exiled.frame = 0
	await snap("clash_exiled")
	await think("Yang Terbuang. Mereka nyata. Seluruh dosierku tentang mereka... nyata.", "surprised")
	await think("Dan— oh. Ia besar. Catatan kaki: SANGAT besar.", "pain")
	await close_dialogue()

	# the Saint descends
	await cam.pan_zoom(Vector2(150, 110), 2.2, 1.0)
	saint.visible = true
	var sh := add_shaft(Vector2(SAINT_POS.x, -300), 30.0, SAINT_POS + Vector2(0, 30), 60.0, Color(1.0, 0.9, 0.6, 0.5))
	sh.modulate.a = 0.0
	var ts := create_tween().set_parallel(true)
	ts.tween_property(saint, "position", SAINT_POS, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	ts.tween_property(saint_light, "energy", 0.9, 1.6)
	ts.tween_property(halo_glow, "modulate:a", 0.35, 1.6)
	ts.tween_property(sh, "modulate:a", 1.0, 0.8)
	Audio.sfx("hit_holy", -2.0, 0.8)
	saint.face("right")
	await StageCamera.wait_tween(ts)
	var tsh := create_tween()
	tsh.tween_property(sh, "modulate:a", 0.0, 1.5)
	await snap("clash_saint")
	await say("saint", "Makhluk tanpa nama. Kau kabur dari pengasingan untuk kesekian kalinya.", "closed")
	await say("exiled", "...CAHAYA... MEMBAKAR... TAPI... TIDAK... BENAR...")
	await say("saint", "Para dewa telah menimbangmu. Tombak Kesembilan akan menyelesaikan timbangan itu.", "angry")
	await close_dialogue()

	# First volley: the chains start to break
	saint.pose("saint_poses", 1)
	post.flash(Color(1.0, 0.9, 0.6), 0.4, 0.4)
	Audio.sfx("hit_holy", 0.0)
	await cam.pan_zoom(Vector2(260, 150), 2.0, 0.6)
	add_fire(Vector2(150, 238))
	await volley([EXILED_POS + Vector2(-30, -10), Vector2(300, 240), EXILED_POS + Vector2(20, -40),
		Vector2(196, 230), Vector2(400, 236)])
	chains[0].snap(0.6)
	Audio.sfx("chain_snap", 0.0)
	spawn_fx(FX.burst(Color(1.0, 0.9, 0.7), 16, 70.0, 0.4), MC_POS + Vector2(-30, -4))
	mc.shake(2.0, 0.4)
	await wait(0.3)
	await cam.pan_zoom(MC_POS + Vector2(0, -20), 3.4, 0.5)
	await think("!! Rantai tangan kiriku—", "surprised")
	await close_dialogue()
	await cam.pan_zoom(Vector2(260, 150), 2.0, 0.5)
	exiled.frame = 3
	var dodge := create_tween()
	dodge.tween_property(exiled, "position", EXILED_POS + Vector2(-30, 0), 0.25)
	dodge.tween_property(exiled, "position", EXILED_POS, 0.4)
	await volley([Vector2(330, 236), MC_POS + Vector2(34, 22), EXILED_POS + Vector2(-50, 0), Vector2(120, 246),
		Vector2(260, 250), EXILED_POS + Vector2(10, -20)], 0.07)
	exiled.frame = 0
	chains[3].snap(0.5)
	Audio.sfx("chain_snap", 0.0, 1.1)
	add_fire(Vector2(330, 244))
	await think("Ia tidak membidikku. Ia bahkan tidak MELIHATku. Aku cuma... latar belakang.", "pain")
	await close_dialogue()

	# A lance strikes the stone itself
	fire_lance(Vector2(-40, -120), Vector2(250, 150), 0.4, true)
	await wait(0.45)
	crack_stone(1)
	mc.shake(2.5, 0.6)
	await wait(0.6)
	chains[1].snap(0.4)
	Audio.sfx("chain_snap", 0.0, 0.9)
	await snap("clash_volley")

	# The Exiled lunges; the fight moves into the sky
	exiled.frame = 3
	Audio.sfx("roar", -2.0, 1.1)
	var lunge := create_tween().set_parallel(true)
	lunge.tween_property(exiled, "position", SAINT_POS + Vector2(60, -40), 0.5).set_trans(Tween.TRANS_EXPO) \
		.set_ease(Tween.EASE_IN)
	await StageCamera.wait_tween(lunge)
	post.flash(Color.WHITE, 0.5, 0.9)
	shake(1.0, 10.0)
	Audio.sfx("lance_impact", 0.0, 0.7)
	var away := create_tween().set_parallel(true)
	away.tween_property(exiled, "position", Vector2(-200, -400), 0.7)
	away.tween_property(saint, "position", Vector2(-160, -420), 0.7)
	away.tween_property(halo_glow, "modulate:a", 0.0, 0.7)
	await StageCamera.wait_tween(away)
	exiled.visible = false
	saint.visible = false
	for i in 3:
		await wait(0.5)
		lightning(0.6)
		Audio.sfx("lance_impact", -12.0, 0.6)

	# Realisation
	await cam.pan_zoom(MC_POS + Vector2(0, -26), 3.6, 1.0)
	Audio.duck_music(-12.0, 0.6)
	await think("Rune-rune itu retak. Batu ini hanya sekuat doa yang mengikatnya...", "surprised")
	await think("...dan doa itu baru saja ditusuk oleh doa yang lain. Sigil di bawah batu. Tepat di atas kepalaku.", "angry")
	await think("Satu rantai lagi masih terpasang. Tapi rantai yang putus di tanganku... cukup berat untuk dijadikan palu.", "angry")
	await close_dialogue()
	Audio.unduck_music(0.3)

	# QTE — strike the cracked sigil
	burdened = false
	mc.pose("mc_poses", 1)
	var ok := false
	var attempt := 0
	while not ok:
		attempt += 1
		ok = await cine.qte_mash("HANTAM!", 12, 6.0)
		if not ok:
			Audio.sfx("stone_crack", -4.0, 0.7)
			shake(0.6, 6.0)
			mc.pose("mc_poses", 2)
			mc.shake(2.0, 0.5)
			await think("Batu itu menekan lagi. Belum cukup. Lagi. Ayo, lengan kurus...", "pain")
			await close_dialogue()
			mc.pose("mc_poses", 1)
		else:
			crack_stone(2)
	GameState.set_flag("qte_attempts", attempt)

	# The mountain falls apart
	Audio.stop_music(0.2)
	post.flash(Color(0.8, 1.0, 1.0), 1.2, 1.0)
	Audio.sfx("stone_shatter", 0.0)
	shake(1.0, 12.0)
	chains[2].snap(0.5)
	for c in cracks:
		c.visible = false
	var ts2 := create_tween().set_parallel(true)
	ts2.tween_property(stone, "modulate:a", 0.0, 0.5)
	ts2.tween_property(runes, "modulate:a", 0.0, 0.3)
	ts2.tween_property(rune_light, "base_energy", 0.0, 0.5)
	for i in 6:
		spawn_fx(FX.debris(40, Color(0.32, 0.3, 0.36)), Vector2(randf_range(100.0, 380.0), randf_range(20.0, 190.0)), false)
	spawn_fx(FX.smoke(Vector2(220, 40), 26), MC_POS + Vector2(0, -20), false)
	spawn_fx(FX.burst(Color(0.5, 1.0, 1.0), 60, 200.0, 1.2, 40.0), MC_POS + Vector2(0, -40))
	await wait(1.6)
	stone.visible = false
	runes.visible = false
	await cam.pan_zoom(MC_POS + Vector2(0, -20), 3.2, 1.5)
	mc.clear_pose()
	mc.face("down")
	await snap("clash_free")
	await wait(0.8)
	await say("mc", "...Aku... berdiri.", "surprised")
	await think("Punggungku mengeluarkan bunyi yang tidak seharusnya keluar dari punggung manusia.", "pain")
	await think("Seratus empat belas hari. Satu gunung. Nol penyesalan. Akan kucatat semuanya.", "smirk")
	await close_dialogue()

	# Eye contact with the Exiled
	exiled.visible = true
	exiled.frame = 0
	exiled.position = EXILED_POS + Vector2(20, -6)
	exiled.modulate.a = 0.0
	var tx := create_tween()
	tx.tween_property(exiled, "modulate:a", 1.0, 0.8)
	await cam.pan_zoom(Vector2(380, 190), 2.6, 1.2)
	mc.face("right")
	Audio.sfx("growl", -6.0, 0.9)
	await say("exiled", "...KAU... MENCATAT...?")
	await say("mc", "...Apa?", "surprised")
	await close_dialogue()
	exiled.frame = 2
	Audio.sfx("roar", -2.0, 1.2)
	shake(0.6, 6.0)
	var leap := create_tween()
	leap.tween_property(exiled, "position", Vector2(700, -260), 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await StageCamera.wait_tween(leap)
	exiled.visible = false

	# The Saint notices... and does not care
	saint.visible = true
	saint.clear_pose()
	saint.face("right")
	saint.position = Vector2(200, -160)
	var ts3 := create_tween().set_parallel(true)
	ts3.tween_property(saint, "position", Vector2(160, 120), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	ts3.tween_property(halo_glow, "modulate:a", 0.35, 1.0)
	await cam.pan_zoom(Vector2(200, 160), 2.8, 1.0)
	await StageCamera.wait_tween(ts3)
	mc.face("left")
	await say("saint", "Seorang tahanan.", "neutral")
	await wait(0.4)
	await say("saint", "...Bukan urusanku malam ini.", "closed")
	await close_dialogue()
	var ts4 := create_tween().set_parallel(true)
	ts4.tween_property(saint, "position", Vector2(720, -300), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	ts4.tween_property(halo_glow, "modulate:a", 0.0, 0.9)
	Audio.sfx("lance_whoosh", -2.0, 0.7)
	await StageCamera.wait_tween(ts4)
	saint.visible = false
	await think("Ia melihatku. Lalu memutuskan aku tidak penting. Itu... sebenarnya kabar baik.", "smirk")
	await think("Pergi. Sekarang. Sebelum dewa mana pun berubah pikiran.", "angry")
	await close_dialogue()
	Audio.play_music("burden", 2.0)
	var go := mc.walk_to(Vector2(40, 240), 60.0)
	await wait(1.4)
	await cine.fade_black(1.0, 1.2)
	await StageCamera.wait_tween(go)
	Router.goto("res://scenes/prologue/p4_escape.tscn", "fade")
