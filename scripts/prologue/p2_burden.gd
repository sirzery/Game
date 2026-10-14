extends PeakStage
## PROLOG II — Puncak Penyesalan.
## The Penance of the Burden: a mountain-stone chained to the Scholar's back.
## A montage of days, survival and stubborn humour.

const SELF_PATH := "res://scenes/prologue/p2_burden.tscn"


func run() -> void:
	GameState.save_game(SELF_PATH)
	cutscene = true
	cine.set_black(1.0)
	await cine.letterbox(true, 0.01)
	Audio.play_ambience("rain", "wind")
	Audio.play_music("burden", 2.5)
	cam.position = MC_POS + Vector2(0, -6)
	cam.zoom = Vector2(5, 5)
	await cine.fade_black(0.0, 2.0)
	cine.location("PUNCAK PENYESALAN", "HARI KE-1", 3.0)
	await think("Tanganku dirantai. Kakiku dirantai. Dan di punggungku...", "pain")
	# the reveal: pan up along the stone into the storm
	lightning(0.6)
	await cam.pan_zoom(Vector2(240, 120), 3.0, 2.5)
	await cam.pan_zoom(Vector2(240, -250), 2.4, 5.0)
	lightning(1.0)
	await snap("burden_peak")
	await wait(1.2)
	await cam.pan_zoom(Vector2(240, 165), 3.0, 3.5)
	await think("...sebuah gunung. Lengkap dengan salju dan pohon cemara di puncaknya. Sinode memang tidak pernah setengah-setengah.", "pain")
	await think("Tapi batu ini tidak menindihku sepenuhnya. Rune-rune itu menahannya. Cukup ringan agar tulangku tidak remuk...", "closed")
	await think("...dan cukup berat agar aku tidak pernah lupa sedang dihukum. Desain yang elegan. Akan kupuji, kalau aku bukan bahan percobaannya.", "smirk")
	await close_dialogue()
	await snap("burden_mc")

	# Day 9 — the crow
	await day_card("HARI KE-9")
	crow.visible = true
	crow.position = Vector2(420, 60)
	var ct := create_tween()
	ct.tween_property(crow, "position", MC_POS + Vector2(14, -30), 1.6).set_trans(Tween.TRANS_SINE)
	await StageCamera.wait_tween(ct)
	crow.frame = 0
	Audio.sfx("crow", -2.0)
	await cam.pan_zoom(MC_POS + Vector2(0, -16), 4.0, 1.0)
	await say("crow", "Kaak.")
	await say("mc", "Kau lagi. Dengar, aku tahu aku terlihat seperti makanan. Tapi aku sedang bekerja.", "angry")
	await say("crow", "Kaak.")
	await say("mc", "...Argumen yang kuat. Baiklah. Kau boleh tinggal, tapi jangan mematuk catatanku.", "smirk")
	tally.visible = true
	await think("Catatan. Garis-garis di tanah, digurat dengan kuku. Satu garis untuk satu hari. Seorang cendekia tetap butuh arsip.", "neutral")
	await close_dialogue()
	var cf := create_tween()
	cf.tween_property(crow, "position", Vector2(560, -40), 1.5)
	crow.frame = 1
	await cam.pan_zoom(Vector2(240, 165), 3.0, 1.0)

	# Day 40 — the guard
	await day_card("HARI KE-40")
	var guard := add_actor("guard", Vector2(20, 236), "right")
	await guard.move_to(MC_POS + Vector2(-40, 12), 40.0)
	await say("guard", "Masih hidup, Cendekia? Taruhan di barak bilang kau sudah mati minggu lalu.")
	await say("mc", "Sampaikan pada mereka: aku masih menghitung. Hari ke-40. Hujan turun dua puluh tiga kali.", "pain")
	await say("mc", "Ada empat ribu seratus tujuh belas retakan di batu ini. Yang paling kecil kunamai 'Sinode'.", "smirk")
	await say("guard", "Hah! Mulutmu belum ikut dirantai rupanya. Nikmati gunungmu.")
	await close_dialogue()
	await guard.move_to(Vector2(-30, 236), 50.0)
	guard.queue_free()

	# Day 113 — night, survival
	set_time_of_day(true, 0.1)
	await day_card("HARI KE-113  ·  MALAM")
	await think("Air hujan: tiga teguk, ditadah lewat celah batu. Lumut di bawah lutut: pahit, tapi bukan racun. Mungkin.", "closed")
	await think("Kalau aku mati di sini, dosierku hanya akan tersisa di dalam kepalaku. Maka aku tidak boleh mati.", "sad")
	await think("...Kesimpulan yang logis. Aku selalu menyukai kesimpulan yang logis.", "smirk")
	await close_dialogue()
	await wait(0.8)

	# Something else in the storm
	Audio.duck_music(-20.0, 1.0)
	lightning(0.8)
	await wait(0.6)
	Audio.sfx("roar", -6.0, 0.8)
	shake(0.5, 4.0)
	mc.shake(1.5, 0.6)
	await wait(1.2)
	await think("...Itu bukan guntur.", "surprised")
	await close_dialogue()
	await cam.pan_zoom(Vector2(240, 60), 2.6, 2.0)
	lightning(1.0)
	await wait(0.8)
	Audio.stop_music(1.5)
	await cine.fade_black(1.0, 1.0)
	Router.goto("res://scenes/prologue/p3_clash.tscn", "fade")
