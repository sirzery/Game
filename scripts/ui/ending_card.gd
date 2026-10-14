class_name EndingCard
extends Control
## "Prolog selesai" summary with the player's choices.

var _k: float = 0.0:
	set(v):
		_k = v
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func run() -> void:
	var t := create_tween()
	t.tween_property(self, "_k", 1.0, 0.6).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await t.finished
	var big := UIKit.label("PROLOG SELESAI", 104, UIKit.BONE, UIKit.head_font())
	UIKit.shadow(big, Vector2(8, 8), UIKit.RED)
	big.position = Vector2(80, 60)
	big.rotation = deg_to_rad(-5.0)
	add_child(big)
	var sub := UIKit.label("BEBAN SANG CENDEKIA", 32, UIKit.GOLD, UIKit.title_font(800))
	sub.position = Vector2(110, 196)
	sub.rotation = deg_to_rad(-5.0)
	add_child(sub)
	var answers := {"honest": "Mencatat apa yang dilihat", "defiant": "Menantang cahaya Sinode",
		"silent": "Diam dan menghitung"}
	var meets := {"honest": "Jujur (dan dicurigai)", "funny": "Korban perampokan kambing", "curious": "Penasaran soal bangsawan kambing"}
	var secs := int(GameState.play_time)
	var lines := [
		["CATATAN SANG CENDEKIA", ""],
		["Pembelaan di pengadilan", str(answers.get(str(GameState.get_flag("tribunal_answer", "silent")), "-"))],
		["Kesan pertama Maren", str(meets.get(str(GameState.get_flag("maren_first", "honest")), "-"))],
		["Nama yang kau berikan", GameState.player_name if bool(GameState.get_flag("told_maren_name", false)) else "\"Seorang pengembara\""],
		["Babi hutan berlumut", "Dikalahkan" if GameState.has_flag("beat_boar") else "Dibiarkan hidup tenang"],
		["Level", str(GameState.mc["level"])],
		["Waktu bermain", "%02d:%02d" % [int(secs / 60.0), secs % 60]],
	]
	var y := 290.0
	for l in lines:
		var a := UIKit.label(str(l[0]), 26 if str(l[1]) != "" else 30, Color("c8c0b8") if str(l[1]) != "" else UIKit.RED,
			UIKit.head_font())
		a.position = Vector2(140, y)
		add_child(a)
		if str(l[1]) != "":
			var b := UIKit.label(str(l[1]), 26, UIKit.BONE, UIKit.body_font(700))
			b.position = Vector2(500, y)
			add_child(b)
		y += 42.0
	var next := UIKit.label("BAB I  ·  DESA DI UJUNG PETA  —  SEGERA", 30, UIKit.BONE, UIKit.head_font())
	UIKit.outline(next, 6, UIKit.BLACK)
	next.position = Vector2(620, 620)
	next.rotation = deg_to_rad(-3.0)
	add_child(next)
	var hint := UIKit.label("ENTER · KEMBALI KE LAYAR JUDUL", 20, UIKit.GOLD, UIKit.head_font())
	hint.position = Vector2(140, 668)
	add_child(hint)
	await Router.snap("prologue_end")
	var waited := 0.0
	while true:
		await get_tree().process_frame
		waited += get_process_delta_time()
		if Settings.autotest and waited > 0.6:
			break
		if waited > 0.8 and Input.is_action_just_pressed("accept"):
			break
	Audio.sfx("ui_confirm")


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.02, 0.0, 0.02, _k))
	if _k <= 0.001:
		return
	var w := 1400.0 * _k
	draw_colored_polygon(PackedVector2Array([Vector2(-60, 250), Vector2(-60 + w, 170), Vector2(-60 + w, 186),
		Vector2(-60, 266)]), UIKit.RED)
	draw_colored_polygon(PackedVector2Array([Vector2(1340, 610), Vector2(1340 - w * 0.6, 600), Vector2(1340 - w * 0.6, 664),
		Vector2(1340, 670)]), UIKit.RED_DARK)
