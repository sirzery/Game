extends StageScene
## PROLOG V — Tepi Hutan Brindlemere.
## Free exploration at dusk: gather materials, keep away from the village,
## read your own wanted poster, raise a camp. At night: a goat, a bread
## heist, and a girl with a lantern.

const SPR := "res://assets/sprites/"
const SELF_PATH := "res://scenes/prologue/p5_wilds.tscn"
const MAP := Vector2(960, 720)
const VILLAGE_EDGE := 770.0
const CAMP := Vector2(430, 238)
const BOAR_ZONE := Rect2(40, 540, 140, 150)

var player: Player
var sun: DirectionalLight2D
var hud: CanvasLayer
var tracker: ObjectiveTracker
var prompt: InteractPrompt
var boar: Sprite2D
var boar_target: Vector2
var boar_timer: float = 0.0
var camp_fire: Flipbook
var camp_light: FlickerLight
var night_fx: Array[Node] = []
var window_glows: Array[Node2D] = []
var sun_rays: Array[Polygon2D] = []
var busy: bool = false
var exploring: bool = false
var _boundary_cooldown: float = 0.0
var _boar_grace: float = 0.0
var _rng := RandomNumberGenerator.new()
var _blocked: Array = []  # [Vector2, radius] areas kept free of trees


func setup() -> void:
	_rng.seed = 1114
	post.apply_preset("dusk")
	ambient.color = Color(0.88, 0.76, 0.7)
	cam.zoom = Vector2(3, 3)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(MAP.x)
	cam.limit_bottom = int(MAP.y)
	add_sprite(SPR + "backgrounds/wilds_ground.png", Vector2.ZERO, ground, true, false)

	sun = DirectionalLight2D.new()
	sun.color = Color(1.0, 0.7, 0.42)
	sun.energy = 0.55
	sun.height = 0.35
	sun.rotation_degrees = -70.0
	add_child(sun)

	_build_bounds()
	_build_village()
	_build_camp_site()
	_build_points_of_interest()
	_build_forest()
	_build_boar()

	player = Player.new()
	world.add_child(player)
	player.interact_target_changed.connect(_on_target_changed)
	spawn_fx(FX.dust(MAP, 120, Color(1.0, 0.85, 0.55)), MAP * 0.5)
	# low dusk sun: slanted god-rays falling through the canopy
	for i in 9:
		var x := -60.0 + float(i) * 118.0 + _rng.randf_range(-20.0, 20.0)
		var ray := add_shaft(Vector2(x, -40), 26.0 + _rng.randf_range(0.0, 16.0), Vector2(x + 260.0, 760),
			90.0 + _rng.randf_range(0.0, 50.0), Color(1.0, 0.78, 0.5, 0.075))
		sun_rays.append(ray)
	# glints on the stream
	for y in [120.0, 300.0, 480.0, 640.0]:
		spawn_fx(FX.dust(Vector2(10, 90), 10, Color(0.75, 0.9, 1.0)), Vector2(WildsLayout.stream_x_at(y), y))
	_build_hud()


# ---------------------------------------------------------------------------
# World building
# ---------------------------------------------------------------------------
func _wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = rect.size
	shape.shape = r
	shape.position = rect.position + rect.size * 0.5
	body.add_child(shape)
	add_child(body)


func _solid_circle(pos: Vector2, radius: float) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = radius
	shape.shape = c
	body.add_child(shape)
	add_child(body)


func _build_bounds() -> void:
	_wall(Rect2(-20, -20, MAP.x + 40, 26))
	_wall(Rect2(-20, MAP.y - 6, MAP.x + 40, 26))
	_wall(Rect2(-20, -20, 26, MAP.y + 40))
	_wall(Rect2(MAP.x - 6, -20, 26, MAP.y + 40))


func _block(pos: Vector2, radius: float) -> void:
	_blocked.append([pos, radius])


func _is_free(pos: Vector2, margin: float) -> bool:
	if absf(pos.y - WildsLayout.path_y_at(pos.x)) < 26.0 + margin:
		return false
	if absf(pos.x - WildsLayout.stream_x_at(pos.y)) < 20.0 + margin:
		return false
	for b in _blocked:
		var bp: Vector2 = b[0]
		if pos.distance_to(bp) < float(b[1]) + margin:
			return false
	return true


func _build_village() -> void:
	var houses := [[Vector2(858, 300), 0], [Vector2(905, 470), 1], [Vector2(842, 610), 2], [Vector2(930, 210), 1]]
	for h in houses:
		var pos: Vector2 = h[0]
		var idx: int = h[1]
		add_prop(SPR + "props/house_%d.png" % idx, pos)
		var g := Sprite2D.new()
		g.texture = UIKit.tex(SPR + "props/house_%d_e.png" % idx)
		g.position = pos + Vector2(0, -32)
		g.material = FX.additive()
		g.modulate = Color(1.2, 1.0, 0.8, 0.0)
		glow.add_child(g)
		window_glows.append(g)
		var wl := add_light(pos + Vector2(0, -12), Color(1.0, 0.7, 0.35), 0.0, 120.0, 0.12, 20.0)
		window_glows.append(wl)
		var body := StaticBody2D.new()
		body.position = pos + Vector2(0, -12)
		var shape := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(58, 24)
		shape.shape = r
		body.add_child(shape)
		add_child(body)
		_block(pos, 50.0)
	add_prop(SPR + "props/well.png", Vector2(820, 470))
	_solid_circle(Vector2(820, 464), 12.0)
	_block(Vector2(820, 470), 30.0)
	for i in 6:
		var p := Vector2(790, 150 + i * 32)
		add_prop(SPR + "props/fence.png", p)
	for x in [790.0, 900.0]:
		var lp := Vector2(x, WildsLayout.path_y_at(x) - 24.0)
		add_prop(SPR + "props/lamp_post.png", lp)
		var lg := Sprite2D.new()
		lg.texture = UIKit.tex(SPR + "props/lamp_post_e.png")
		lg.position = lp + Vector2(0, -20)
		lg.material = FX.additive()
		lg.modulate = Color(1, 1, 1, 0.0)
		glow.add_child(lg)
		window_glows.append(lg)
		var ll := add_light(lp + Vector2(4, -26), Color(1.0, 0.75, 0.4), 0.0, 140.0, 0.15, 30.0)
		window_glows.append(ll)
		_block(lp, 18.0)
	spawn_fx(FX.smoke(Vector2(6, 4), 8), Vector2(872, 262), false)


func _build_camp_site() -> void:
	var big := add_prop(SPR + "props/tree_big.png", CAMP + Vector2(0, -10))
	big.offset.x = 0.0
	_solid_circle(CAMP + Vector2(0, -14), 9.0)
	_block(CAMP, 70.0)
	var spot := Interactable.new("DIRIKAN KEMAH", 26.0)
	spot.position = CAMP + Vector2(0, 26)
	world.add_child(spot)
	spot.interacted.connect(_on_camp)


func _build_points_of_interest() -> void:
	# wanted poster by the road
	var px := 610.0
	var poster_pos := Vector2(px, WildsLayout.path_y_at(px) - 30.0)
	add_prop(SPR + "props/wanted_post.png", poster_pos)
	_solid_circle(poster_pos + Vector2(0, -2), 4.0)
	var poster := Interactable.new("BACA POSTER", 22.0)
	poster.position = poster_pos + Vector2(0, 4)
	world.add_child(poster)
	poster.interacted.connect(_on_poster)
	_block(poster_pos, 26.0)

	# water at the stream
	var wy := 486.0
	var water := Interactable.new("ISI KANTONG AIR", 26.0)
	water.position = Vector2(WildsLayout.stream_x_at(wy) + 4.0, wy)
	world.add_child(water)
	water.interacted.connect(_on_water.bind(water))
	water.add_sparkle(glow)
	_block(water.position, 26.0)

	var pickups := [
		["dahan", Vector2(128, 250)], ["dahan", Vector2(530, 522)], ["dahan", Vector2(690, 214)],
		["batu", Vector2(WildsLayout.stream_x_at(300.0) - 26.0, 300)],
		["batu", Vector2(WildsLayout.stream_x_at(600.0) + 28.0, 600)], ["batu", Vector2(372, 600)],
		["akar", Vector2(84, 612)], ["akar", Vector2(650, 300)],
	]
	for i in pickups.size():
		var kind: String = pickups[i][0]
		var pos: Vector2 = pickups[i][1]
		var flag := "pick_%s_%d" % [kind, i]
		_block(pos, 22.0)
		if GameState.has_flag(flag):
			continue
		var tex_name := str(PICK_TEX[kind])
		var spr := add_prop(SPR + "props/%s.png" % tex_name, pos)
		var it := Interactable.new(str(PICK_PROMPT[kind]), 20.0)
		it.position = pos
		world.add_child(it)
		it.add_sparkle(glow)
		it.interacted.connect(_on_pickup.bind(kind, flag, it, spr))


func _build_forest() -> void:
	var tree_tex := ["tree_0", "tree_1", "tree_2", "pine_0", "pine_1", "pine_1"]
	var radius := {"tree_0": 6.0, "tree_1": 7.0, "tree_2": 6.0, "pine_0": 4.0, "pine_1": 5.0}
	var placed := 0
	var tries := 0
	while placed < 70 and tries < 2500:
		tries += 1
		var pos := Vector2(_rng.randf_range(10.0, VILLAGE_EDGE - 10.0), _rng.randf_range(30.0, MAP.y - 6.0))
		if not _is_free(pos, 10.0):
			continue
		var t: String = tree_tex[_rng.randi() % tree_tex.size()]
		add_prop(SPR + "props/%s.png" % t, pos)
		_solid_circle(pos + Vector2(0, -3), float(radius[t]))
		_block(pos, 26.0)
		placed += 1
	# a ring of trees along the northern and southern edges for framing
	var x := 0.0
	while x < VILLAGE_EDGE:
		for y in [14.0, MAP.y - 4.0]:
			var p := Vector2(x + _rng.randf_range(-6.0, 6.0), y)
			if _is_free(p, 0.0):
				add_prop(SPR + "props/%s.png" % ("pine_1" if _rng.randf() < 0.6 else "tree_1"), p)
				_solid_circle(p + Vector2(0, -3), 6.0)
		x += 34.0
	var deco := 0
	tries = 0
	while deco < 40 and tries < 1500:
		tries += 1
		var p := Vector2(_rng.randf_range(10.0, MAP.x - 10.0), _rng.randf_range(20.0, MAP.y - 10.0))
		if not _is_free(p, 0.0):
			continue
		var kind := _rng.randi() % 5
		if kind <= 2:
			add_prop(SPR + "props/bush_%d.png" % (_rng.randi() % 2), p)
		elif kind == 3:
			add_prop(SPR + "props/rock_%d.png" % (_rng.randi() % 2), p)
			_solid_circle(p + Vector2(0, -4), 7.0)
		else:
			add_prop(SPR + "props/log.png", p)
			_solid_circle(p + Vector2(0, -4), 8.0)
		_block(p, 18.0)
		deco += 1


func _build_boar() -> void:
	if GameState.has_flag("beat_boar"):
		return
	boar = Sprite2D.new()
	boar.texture = UIKit.lit_tex(SPR + "characters/boar.png")
	boar.hframes = 4
	boar.offset = Vector2(0, -14)
	boar.position = BOAR_ZONE.get_center()
	boar_target = boar.position
	world.add_child(boar)


func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 60
	add_child(hud)
	tracker = ObjectiveTracker.new()
	tracker.visible = false
	hud.add_child(tracker)
	prompt = InteractPrompt.new()
	hud.add_child(prompt)


# ---------------------------------------------------------------------------
# Main script
# ---------------------------------------------------------------------------
func run() -> void:
	Audio.play_ambience("forest")
	var mem: Dictionary = GameState.scene_memory.get("wilds", {})
	if mem.has("pos"):
		# returning from a battle or loading a save
		player.position = mem["pos"]
		cam.position = player.position
		_boar_grace = 4.0
		if boar != null:
			# after fleeing, the boar wanders off to the far side of its meadow
			boar.position = Vector2(BOAR_ZONE.end.x - 10.0, BOAR_ZONE.end.y - 10.0)
			boar_target = boar.position
		_set_objectives()
		Audio.play_music("wilds", 1.0)
		cine.location("TEPI HUTAN BRINDLEMERE", "SENJA", 2.5)
		_start_exploring()
		return
	player.position = Vector2(10, WildsLayout.path_y_at(10.0))
	cam.position = player.position + Vector2(80, 0)
	player.controls_enabled = false
	cutscene = true
	cine.set_black(1.0)
	await cine.letterbox(true, 0.01)
	await cine.narration(["Tiga hari kemudian."], 1.6, true)
	Audio.play_music("wilds", 2.0)
	await cine.fade_black(0.0, 1.5)
	cine.location("TEPI HUTAN BRINDLEMERE", "SENJA  ·  TIGA HARI SETELAH PELARIAN", 3.0)
	await walk_player(Vector2(96, WildsLayout.path_y_at(96.0)), 40.0)
	await snap("wilds_arrival")
	await think("Asap dapur. Suara ayam. Seseorang memaki keledainya. Sebuah desa—dan tidak ada yang sedang menghakimi siapa pun.", "closed")
	await think("Aku tidak boleh masuk. Belum. Wajahku mungkin sudah tertempel di setiap pintu.", "neutral")
	await think("Rencana: kemah sementara. Dekat air, jauh dari jalan, cukup dekat untuk mengamati. Pohon besar di utara itu sempurna.", "smirk")
	await think("Bahan: dahan kering untuk kerangka, batu pipih untuk tungku, dan air. Kebutuhan dasar manusia, versi cendekia.", "neutral")
	await close_dialogue()
	_set_objectives()
	await end_cutscene()
	GameState.set_flag("wilds_intro")
	_remember()
	GameState.save_game(SELF_PATH)
	Audio.sfx("save", -6.0)
	cine.toast("Permainan tersimpan")
	_start_exploring()


func _set_objectives() -> void:
	GameState.add_objective("dahan", "Kumpulkan dahan kering", 3)
	GameState.add_objective("batu", "Kumpulkan batu pipih", 3)
	GameState.add_objective("air", "Isi kantong air di sungai", 1)
	GameState.add_objective("kemah", "Dirikan kemah di pohon besar", 1)
	GameState.add_objective("akar", "(Opsional) Petik akar pahit", 2, true)


func _start_exploring() -> void:
	tracker.visible = true
	tracker.refresh()
	player.controls_enabled = true
	exploring = true
	cutscene = false
	if Settings.autotest:
		_autoplay()


func walk_player(target: Vector2, speed: float = 55.0) -> void:
	## Scripted walk of the player body (cutscenes; ignores collisions).
	var d := target - player.position
	if d.length() < 0.5:
		return
	if absf(d.x) > absf(d.y):
		player.actor.face("right" if d.x > 0.0 else "left")
	else:
		player.actor.face("down" if d.y > 0.0 else "up")
	player.actor.set_walking(true)
	var t := create_tween()
	t.tween_property(player, "position", target, d.length() / maxf(speed, 1.0))
	await t.finished
	player.actor.set_walking(false)


func _remember() -> void:
	GameState.scene_memory["wilds"] = {"pos": player.position}


func _process(delta: float) -> void:
	super._process(delta)
	if player == null:
		return
	# camera follow
	cam.position = cam.position.lerp(player.position + Vector2(0, -12), minf(1.0, delta * 5.0))
	# interaction prompt
	if prompt.visible and player.target != null:
		prompt.position = get_viewport().get_canvas_transform() * (player.target.global_position + Vector2(-10, -40))
	if not exploring or busy:
		return
	if Input.is_action_just_pressed("pause"):
		_open_pause()
		return
	if Input.is_action_just_pressed("accept") and not dlg.is_open:
		player.try_interact()
	_boundary_cooldown = maxf(0.0, _boundary_cooldown - delta)
	if player.position.x > VILLAGE_EDGE and _boundary_cooldown <= 0.0:
		_on_village_edge()
	_update_boar(delta)


func _on_target_changed(t: Interactable) -> void:
	if t == null or busy or not exploring:
		prompt.visible = false
	else:
		prompt.show_for(t.prompt)


func _open_pause() -> void:
	busy = true
	player.controls_enabled = false
	_remember()
	var pm := PauseMenu.new()
	add_child(pm)
	await pm.run()
	if is_inside_tree():
		busy = false
		player.controls_enabled = exploring


func _lock() -> void:
	busy = true
	player.controls_enabled = false
	prompt.visible = false


func _unlock() -> void:
	busy = false
	player.controls_enabled = true
	_on_target_changed(player.target)


# ---------------------------------------------------------------------------
# Interactions
# ---------------------------------------------------------------------------
const PICK_LINES := {
	"dahan": "Dahan kering, ringan, tidak lapuk. Kerangka kemah yang baik selalu dimulai dari kayu yang jujur.",
	"batu": "Batu pipih dari tepi sungai. Bisa jadi tungku. Bisa juga dilempar ke kepala anjing suci. Serbaguna.",
	"akar": "Akar pahit. Menghentikan pendarahan dan menghapus keinginan untuk hidup bahagia. Obat yang efektif.",
}
const ITEM_NAMES := {"dahan": "Dahan Kering", "batu": "Batu Pipih", "akar": "Akar Pahit"}
const PICK_TEX := {"dahan": "pickup_branch", "batu": "pickup_stone", "akar": "pickup_herb"}
const PICK_PROMPT := {"dahan": "AMBIL DAHAN", "batu": "AMBIL BATU", "akar": "PETIK AKAR"}


func _on_pickup(kind: String, flag: String, it: Interactable, spr: Sprite2D) -> void:
	if busy:
		return
	_lock()
	GameState.set_flag(flag)
	it.disable_and_hide()
	spr.queue_free()
	Audio.sfx("pickup", -2.0)
	var item_id := "akar_pahit" if kind == "akar" else kind
	GameState.add_item(item_id)
	cine.toast("Didapat: %s" % str(ITEM_NAMES[kind]))
	var first := not GameState.has_flag("first_" + kind)
	GameState.set_flag("first_" + kind)
	var done := GameState.progress_objective(kind)
	if first:
		await think(str(PICK_LINES[kind]), "smirk" if kind != "akar" else "pain")
		await close_dialogue()
	if done:
		Audio.sfx("weak", -6.0)
		cine.toast("Tujuan selesai!", UIKit.RED)
	_check_camp_ready()
	_unlock()


func _on_water(it: Interactable) -> void:
	if busy:
		return
	if GameState.objective_done("air"):
		_lock()
		await think("Kantong airku sudah penuh. Sungai ini tidak akan lari ke mana-mana.", "neutral")
		await close_dialogue()
		_unlock()
		return
	_lock()
	Audio.sfx("heal", -8.0, 0.7)
	await think("Air sungai, jernih dan dingin. Kantong kulit curian dari gudang penjara akhirnya berguna.", "closed")
	await think("Kalau Sinode menghitung kantong ini sebagai dosa tambahan, aku akan memasukkannya ke catatan kaki.", "smirk")
	await close_dialogue()
	GameState.add_item("kantong_air")
	GameState.progress_objective("air")
	cine.toast("Kantong air terisi")
	if it.sparkle:
		it.sparkle.emitting = false
	_check_camp_ready()
	_unlock()


func _on_poster() -> void:
	if busy:
		return
	_lock()
	if GameState.has_flag("poster_read"):
		await think("Masih tidak mirip. Hidungku jelas lebih kecil. Aku sudah mengukurnya dengan jari.", "angry")
		await close_dialogue()
		_unlock()
		return
	GameState.set_flag("poster_read")
	await cam.zoom_to(4.0, 0.5)
	await narrate("DICARI — CENDEKIA SESAT. Penyesatan, pengukuran mukjizat, persekutuan dengan Yang Terbuang. HADIAH: 500 keping perak. Diserahkan HIDUP kepada Sinode.")
	await say("mc", "...Gambarnya tidak mirip. Hidungku tidak sebesar itu.", "angry")
	await say("mc", "...Kan?", "surprised")
	await think("Lima ratus keping perak. Aku tersanjung sekaligus tersinggung. Menara Arsip menggajiku tiga keping sebulan.", "smirk")
	await think("'Diserahkan hidup.' Sinode tidak menginginkan mayat. Mereka menginginkan apa yang ada di kepalaku.", "closed")
	await close_dialogue()
	await cam.zoom_to(3.0, 0.5)
	_unlock()


func _on_village_edge() -> void:
	_lock()
	_boundary_cooldown = 2.0
	await think("Belum. Satu poster saja sudah cukup untuk membuat seluruh desa membawa garpu rumput.", "neutral")
	await close_dialogue()
	await walk_player(player.position + Vector2(-26, 0), 50.0)
	player.actor.face("left")
	_unlock()


func _check_camp_ready() -> void:
	if GameState.required_objectives_done(["dahan", "batu", "air"]) and not GameState.has_flag("camp_hint"):
		GameState.set_flag("camp_hint")
		cine.toast("Bahan lengkap — kembali ke pohon besar", UIKit.RED)


func _on_camp() -> void:
	if busy:
		return
	if not GameState.required_objectives_done(["dahan", "batu", "air"]):
		_lock()
		await think("Tempat yang bagus: akar besar menahan angin, cabangnya menutup asap. Tapi bahannya belum cukup.", "neutral")
		await close_dialogue()
		_unlock()
		return
	exploring = false
	_lock()
	tracker.visible = false
	await _camp_scene()


# ---------------------------------------------------------------------------
# Boar (optional battle)
# ---------------------------------------------------------------------------
func _update_boar(delta: float) -> void:
	if boar == null:
		return
	_boar_grace = maxf(0.0, _boar_grace - delta)
	boar_timer -= delta
	if boar_timer <= 0.0 or boar.position.distance_to(boar_target) < 2.0:
		boar_timer = _rng.randf_range(2.0, 4.0)
		boar_target = Vector2(_rng.randf_range(BOAR_ZONE.position.x, BOAR_ZONE.end.x),
			_rng.randf_range(BOAR_ZONE.position.y, BOAR_ZONE.end.y))
	var d := boar_target - boar.position
	if d.length() > 1.0:
		boar.position += d.normalized() * 16.0 * delta
		boar.flip_h = d.x < 0.0
		boar.frame = int(Time.get_ticks_msec() / 250.0) % 2
	if _boar_grace <= 0.0 and boar.position.distance_to(player.position) < 20.0:
		_start_boar_battle()


func _start_boar_battle() -> void:
	_lock()
	exploring = false
	Audio.sfx("growl", 0.0, 1.3)
	boar.frame = 2
	post.flash(Color(1.0, 0.2, 0.25), 0.4, 0.5)
	shake(0.5, 5.0)
	var away := (player.position - boar.position).normalized() * 30.0
	GameState.scene_memory["wilds"] = {"pos": player.position + away}
	await cine.banner("SERANGAN!", UIKit.RED, 0.3, 110)
	GameState.battle_config = {
		"enemies": ["boar"],
		"bg": "res://assets/sprites/backgrounds/battle_forest.png",
		"music": "battle",
		"next": SELF_PATH,
		"flee_to": SELF_PATH,
		"tutorial": false,
		"can_flee": true,
		"win_flag": "beat_boar",
		"intro": "Babi hutan berlumut. Jujur saja, aku lebih takut pada jamur di punggungnya.",
	}
	Router.goto("res://scenes/battle/battle.tscn")


# ---------------------------------------------------------------------------
# Night at the camp
# ---------------------------------------------------------------------------
func _camp_scene() -> void:
	cutscene = true
	await begin_cutscene()
	await cine.fade_black(1.0, 0.8)
	GameState.remove_item("dahan", 3)
	GameState.remove_item("batu", 3)
	GameState.progress_objective("kemah")
	add_prop(SPR + "props/lean_to.png", CAMP + Vector2(-26, 22))
	add_prop(SPR + "props/bedroll.png", CAMP + Vector2(-18, 30))
	camp_fire = Flipbook.new(UIKit.tex(SPR + "props/campfire.png"), 5, 9.0)
	camp_fire.first = 1
	camp_fire.offset = Vector2(0, -10)
	camp_fire.position = CAMP + Vector2(14, 40)
	camp_fire.material = FX.unshaded()
	world.add_child(camp_fire)
	camp_light = add_light(CAMP + Vector2(14, 30), Color(1.0, 0.6, 0.3), 0.0, 260.0, 0.22, 26.0)
	player.position = CAMP + Vector2(-6, 44)
	player.actor.face("right")
	cam.position = CAMP + Vector2(6, 30)
	cam.zoom = Vector2(4, 4)
	GameState.heal_full()
	await wait(0.5)
	# dusk -> night
	Audio.play_music("camp", 2.0)
	Audio.play_ambience("night", "fire")
	var t := create_tween().set_parallel(true)
	t.tween_property(ambient, "color", Color(0.24, 0.26, 0.44), 1.0)
	t.tween_property(sun, "energy", 0.0, 1.0)
	for r in sun_rays:
		t.tween_property(r, "modulate:a", 0.0, 1.0)
	t.tween_property(camp_light, "base_energy", 1.6, 1.0)
	for g in window_glows:
		if g is FlickerLight:
			t.tween_property(g, "base_energy", 0.9, 1.0)
		else:
			t.tween_property(g, "modulate:a", 1.0, 1.0)
	post.apply_preset("night", 1.0)
	var ff := FX.fireflies(Vector2(520, 360), 36)
	spawn_fx(ff, CAMP + Vector2(0, 120))
	spawn_fx(FX.embers(Vector2(8, 4), 14), CAMP + Vector2(14, 34))
	Audio.sfx("fire_ignite", -2.0)
	await cine.fade_black(0.0, 1.5)
	cine.location("KEMAH SEMENTARA", "MALAM PERTAMA DI BRINDLEMERE", 3.0)
	await snap("camp_night")
	player.actor.pose("mc_poses", 0)
	await think("Api. Atap dari dahan. Perut yang hanya setengah kosong. Untuk pertama kalinya dalam empat bulan, aku tidak memikul apa pun.", "closed")
	await think("Dosierku dibakar. Tapi aku ingat setiap halamannya. Hampir.", "sad")
	await think("Halaman satu, ditulis ulang di kulit kayu birch: 'Yang Terbuang bisa bicara. Dan ia bertanya apakah aku mencatat.'", "neutral")
	await think("Halaman dua: 'Seorang santa bisa menghancurkan gunung—dan tidak menganggap seorang tahanan cukup penting untuk dibunuh.'", "smirk")
	await close_dialogue()

	# The bread heist
	var goat := Sprite2D.new()
	goat.texture = UIKit.lit_tex(SPR + "characters/goat.png")
	goat.hframes = 5
	goat.offset = Vector2(0, -10)
	goat.position = CAMP + Vector2(120, 50)
	goat.flip_h = true
	world.add_child(goat)
	Audio.sfx("goat", -2.0)
	await wait(0.4)
	await think("...Ada yang mendekat. Patroli? Pemburu?", "surprised")
	await close_dialogue()
	player.actor.clear_pose()
	player.actor.face("right")
	var gt := create_tween()
	gt.tween_property(goat, "position", CAMP + Vector2(-4, 34), 1.6)
	for i in 6:
		goat.frame = 2 + i % 2
		await wait(0.27)
	await StageCamera.wait_tween(gt)
	goat.frame = 4
	Audio.sfx("comedy", -2.0)
	await say("goat", "Mbeeek.")
	await say("mc", "...Itu rotiku. Itu roti TERAKHIRku. Roti dengan nilai sejarah!", "surprised", {"shout": true})
	await close_dialogue()
	goat.flip_h = false
	var run_away := create_tween()
	run_away.tween_property(goat, "position", CAMP + Vector2(200, 70), 1.0)
	walk_player(player.position + Vector2(40, 0), 70.0)
	for i in 4:
		goat.frame = 2 + i % 2
		await wait(0.22)
	await player.actor.hop(5.0, 0.25)
	await StageCamera.wait_tween(run_away)
	goat.visible = false
	await say("mc", "Dikalahkan oleh kambing. Seratus empat belas hari memikul gunung, dan aku dikalahkan oleh kambing.", "pain")
	await close_dialogue()

	# Maren
	var maren := Actor.new("maren")
	maren.position = CAMP + Vector2(220, 60)
	world.add_child(maren)
	maren.pose_anim("maren_poses", [1, 2, 1, 3], 7.0)
	maren.sprite.flip_h = true
	var lantern := add_light(Vector2(-8, -12), Color(1.0, 0.72, 0.35), 1.0, 150.0, 0.18, 20.0, maren)
	lantern.base_energy = 1.0
	Audio.sfx("goat", -10.0, 1.1)
	var mt := create_tween()
	mt.tween_property(maren, "position", player.actor.global_position + Vector2(52, 0), 2.6)
	await say("girl", "PANGERAN! Pangeran, pulang sekarang juga atau kujadikan kau sup!", "angry", {"shout": true})
	await StageCamera.wait_tween(mt)
	maren.pose("maren_poses", 1)
	maren.sprite.flip_h = true
	await cam.pan_zoom(player.actor.global_position + Vector2(26, -12), 4.2, 0.6)
	await say("mc", "...Pangeran?", "surprised")
	await say("girl", "Oh.", "surprised")
	await say("girl", "...Kau bukan kambing.", "surprised")
	await snap("camp_maren")
	var pick: int = await choose([
		"\"Aku bukan pencuri kambing, kalau itu yang kau pikirkan.\"",
		"\"Kambingmu baru saja merampokku. Dengan kekerasan.\"",
		"\"Kambing itu... seorang bangsawan?\"",
	])
	match pick:
		0:
			GameState.set_flag("maren_first", "honest")
			await say("mc", "Aku bukan pencuri kambing, kalau itu yang kau pikirkan.", "neutral")
			await say("girl", "Aku belum memikirkan apa-apa. Tapi sekarang aku jadi memikirkannya.", "angry")
		1:
			GameState.set_flag("maren_first", "funny")
			await say("mc", "Kambingmu baru saja merampokku. Dengan kekerasan. Ada saksi—aku.", "angry")
			await say("girl", "...Ia mengambil rotimu?", "surprised")
			await say("girl", "Pfft— maaf. Maaf! Ia memang begitu. Ia mengambil apa pun yang kelihatan menyedihkan.", "smile")
			await say("mc", "Terima kasih. Itu sangat membantu harga diriku.", "smirk")
		_:
			GameState.set_flag("maren_first", "curious")
			await say("mc", "Kambing itu... seorang bangsawan?", "surprised")
			await say("girl", "Namanya Pangeran karena ia makan seperti raja dan bekerja seperti pangeran. Artinya: tidak sama sekali.", "smile")
	await say("girl", "Kau berkemah di sini? Jauh dari jalan, dekat sungai, di bawah pohon tua...", "neutral")
	await say("girl", "...seperti seseorang yang tidak ingin ditemukan.", "neutral")
	Audio.sfx("heartbeat", -4.0)
	await think("Ia melihat pergelangan tanganku. Bekas rantai. Merah, belum sembuh. Bodoh—aku lupa menutupinya.", "pain")
	await say("girl", "Bekas rantai.", "sad")
	await say("girl", "...Aku tidak melihat apa-apa. Aku cuma mencari kambing.", "closed")
	await say("girl", "Ini. Roti. Ganti yang dimakan Pangeran. Jangan bilang ayahku—ia menghitung rotinya seperti Sinode menghitung dosa.", "flustered")
	GameState.add_item("roti_maren", 2)
	Audio.sfx("pickup", -2.0)
	cine.toast("Didapat: Roti Maren x2")
	await say("girl", "Dan jangan nyalakan api terlalu besar. Patroli Sinode lewat jalan utara setiap tiga hari.", "neutral")
	await say("mc", "...Kenapa kau memberitahuku semua ini?", "surprised")
	await say("girl", "Karena orang yang dicari Sinode biasanya bukan orang jahat. Biasanya cuma orang yang terlalu banyak bertanya.", "sad")
	await say("girl", "Namaku Maren, omong-omong. Bukan 'gadis kambing'. Dan kau?", "smile", {"name": "Maren"})
	var name_pick: int = await choose([
		"\"{name}.\" (Nama asli)",
		"\"...Seorang pengembara.\"",
	])
	if name_pick == 0:
		GameState.set_flag("told_maren_name", true)
		await say("mc", "{name}.", "neutral")
		await say("maren", "{name}. Nama yang bagus untuk seseorang yang tidak ingin ditemukan.", "smile")
		await say("maren", "Jangan khawatir. Aku pandai menyimpan rahasia. Tanyakan saja pada Pangeran.", "flustered")
	else:
		GameState.set_flag("told_maren_name", false)
		await say("mc", "...Seorang pengembara.", "smirk")
		await say("maren", "Pengembara. Tentu. Pengembara dengan bekas rantai dan kosakata seorang pustakawan.", "angry")
		await say("maren", "Baiklah, Tuan Pengembara. Rahasiamu aman. Untuk sekarang.", "smile")
	await close_dialogue()
	maren.pose_anim("maren_poses", [1, 2, 1, 3], 7.0)
	maren.sprite.flip_h = false
	var leave := create_tween()
	leave.tween_property(maren, "position", maren.position + Vector2(200, 30), 2.6)
	await say("maren", "PANGERAN! Kau tidur di kandang malam ini!", "angry", {"shout": true})
	await close_dialogue()
	await StageCamera.wait_tween(leave)
	maren.visible = false
	await cam.pan_zoom(player.actor.global_position + Vector2(0, -10), 4.0, 0.8)
	player.actor.face("down")
	await think("Aku baru saja diselamatkan oleh gadis pemilik kambing bangsawan.", "closed")
	await think("Catatan untuk dosier, halaman tiga: 'Penduduk Brindlemere tidak sepenuhnya patuh pada Sinode.' Menarik.", "smirk")
	await think("...Dan wajahnya agak sulit dilupakan. Itu bukan catatan ilmiah. Abaikan.", "flustered")
	await close_dialogue()
	GameState.set_flag("camp_built")
	GameState.clear_objectives()
	GameState.scene_memory.erase("wilds")
	await wait(0.6)
	Audio.stop_music(2.0)
	await cine.fade_black(1.0, 1.6)
	Router.goto("res://scenes/prologue/p6_synod.tscn", "fade")


# ---------------------------------------------------------------------------
# Automated play-test: collect everything and build the camp.
# ---------------------------------------------------------------------------
func _autoplay() -> void:
	await wait(0.5)
	await snap("wilds_explore")
	var nodes := get_tree().get_nodes_in_group("interactable")
	var order: Array = []
	for n in nodes:
		var it := n as Interactable
		if it == null:
			continue
		if it.prompt == "DIRIKAN KEMAH":
			continue
		order.append(it)
	for n in order:
		var it: Interactable = n
		if not it.enabled or not is_inside_tree():
			continue
		if boar != null and BOAR_ZONE.grow(30.0).has_point(it.global_position):
			continue
		player.position = it.global_position + Vector2(0, 8)
		player.actor.face("up")
		await wait(0.15)
		it.trigger()
		while busy:
			await get_tree().process_frame
	if boar != null:
		# meet the boar on purpose: tests the optional battle and the return trip
		while _boar_grace > 0.0:
			await get_tree().process_frame
		player.position = boar.position + Vector2(12, 0)
		return
	for n in nodes:
		var it := n as Interactable
		if it != null and it.prompt == "DIRIKAN KEMAH":
			player.position = it.global_position + Vector2(0, 8)
			await wait(0.2)
			it.trigger()
			return
