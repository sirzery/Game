extends StageScene
## PROLOG IV — Pelarian.
## Down the northern slope at night. A Synod hound picks up the Scholar's
## scent: the first battle (tutorial).

const SPR := "res://assets/sprites/"
const SELF_PATH := "res://scenes/prologue/p4_escape.tscn"

var mc: Actor
var hound: Sprite2D


func setup() -> void:
	post.apply_preset("forest_night")
	ambient.color = Color(0.42, 0.46, 0.66)
	cam.position = Vector2(200, 150)
	cam.zoom = Vector2(3, 3)
	add_sprite(SPR + "backgrounds/battle_forest.png", Vector2.ZERO, ground, false, false)
	add_light(Vector2(360, 40), Color(0.75, 0.82, 1.0), 1.0, 600.0, 0.0, 120.0)
	spawn_fx(FX.fireflies(Vector2(440, 100), 16), Vector2(240, 200))
	var rain_layer := CanvasLayer.new()
	rain_layer.layer = 2
	add_child(rain_layer)
	var rr := Node2D.new()
	rr.scale = Vector2(3, 3)
	rain_layer.add_child(rr)
	var r := FX.rain(Vector2(520, 10), 160)
	r.position = Vector2(200, -10)
	rr.add_child(r)
	for x in [40.0, 120.0, 400.0, 450.0]:
		add_prop(SPR + "props/bush_%d.png" % (int(x) % 2), Vector2(x, 262))
	mc = add_actor("mc", Vector2(-20, 238), "right")
	hound = Sprite2D.new()
	hound.texture = UIKit.lit_tex(SPR + "characters/hound.png")
	hound.hframes = 5
	hound.flip_h = true
	hound.scale = Vector2(1.2, 1.2)
	hound.offset = Vector2(0, -14)
	hound.position = Vector2(520, 238)
	world.add_child(hound)
	var hl := PointLight2D.new()
	hl.texture = UIKit.radial_light_texture(128)
	hl.color = Color(1.0, 0.75, 0.35)
	hl.energy = 0.8
	hl.texture_scale = 0.6
	hl.position = Vector2(-12, -14)
	hound.add_child(hl)


func run() -> void:
	GameState.save_game(SELF_PATH)
	cutscene = true
	cine.set_black(1.0)
	await cine.letterbox(true, 0.01)
	Audio.play_ambience("rain", "forest")
	Audio.play_music("burden", 1.5)
	await cine.fade_black(0.0, 1.2)
	cine.location("HUTAN LERENG UTARA", "MALAM YANG SAMA", 3.0)
	await mc.move_to(Vector2(150, 238), 46.0)
	await think("Kakiku lupa caranya berjalan. Seratus empat belas hari hanya berlutut membuat lutut jadi pemberontak.", "pain")
	await think("Arah: turun. Selalu turun. Sungai mengalir ke lembah, lembah berarti desa, desa berarti roti.", "neutral")
	await close_dialogue()
	await mc.move_to(Vector2(210, 238), 46.0)
	Audio.stop_music(0.6)
	Audio.sfx("growl", 0.0)
	shake(0.3, 3.0)
	mc.face("right")
	mc.shake(1.5, 0.3)
	await wait(0.5)
	var t := create_tween()
	t.tween_property(hound, "position", Vector2(330, 238), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await StageCamera.wait_tween(t)
	hound.frame = 4
	await cam.pan_zoom(Vector2(270, 200), 3.6, 0.6)
	await snap("escape_hound")
	await say("mc", "Anjing Pemburu Sinode. Mereka dilatih mencium bau dosa.", "surprised")
	await say("mc", "...Atau mungkin hanya bau orang yang 114 hari tidak mandi. Pertanyaan ilmiah yang menarik. Nanti.", "smirk")
	await think("Lari tidak mungkin—kakinya empat, kakiku dua dan setengah gemetar. Senjata: rantai putus, batu, otak.", "angry")
	await think("Cukup. Seorang cendekia yang tahu kelemahan lawannya tidak butuh pedang.", "angry")
	await close_dialogue()
	hound.frame = 2
	Audio.sfx("roar", -6.0, 1.6)
	post.flash(Color(1.0, 0.2, 0.25), 0.4, 0.5)
	shake(0.6, 6.0)
	await cine.banner("SERANGAN!", UIKit.RED, 0.3, 110)
	GameState.set_flag("escaped_peak")
	GameState.battle_config = {
		"enemies": ["hound"],
		"bg": "res://assets/sprites/backgrounds/battle_forest.png",
		"music": "battle",
		"next": "res://scenes/prologue/p5_wilds.tscn",
		"tutorial": true,
		"can_flee": false,
		"win_flag": "beat_hound",
	}
	Router.goto("res://scenes/battle/battle.tscn")
