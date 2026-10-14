class_name PeakStage
extends StageScene
## Shared set for the Peak of Penance (PROLOG II and III): storm sky,
## parallax mountains, the mountain-stone, chains, rain and lightning.

const SPR := "res://assets/sprites/"
const MC_POS := Vector2(240, 222)

var mc: Actor
var stone: Sprite2D
var runes: Sprite2D
var sky_mat: ShaderMaterial
var chains: Array[ChainLine] = []
var parallax: Array = []  # [Node2D, base_position, factor]
var cam_start: Vector2 = Vector2(240, 160)
var lightning_light: PointLight2D
var sky_light: DirectionalLight2D
var rune_light: FlickerLight
var crow: Sprite2D
var tally: Node2D
var _breath_t: float = 0.0
var burdened: bool = true


func setup() -> void:
	post.apply_preset("storm")
	ambient.color = Color(0.64, 0.68, 0.8)
	cam.position = cam_start
	cam.zoom = Vector2(3, 3)
	sky_mat = add_sky({
		"top_color": Color("06080e"), "bottom_color": Color("2a3044"),
		"cloud_dark": Color("10121a"), "cloud_light": Color("3a4258"),
		"cloud_cover": 0.75, "cloud_scale": 2.2, "cloud_speed": Vector2(0.03, 0.004),
	})
	var far := add_sprite(SPR + "backgrounds/peak_far.png", Vector2(240, 150), ground, false)
	far.modulate = Color(0.55, 0.6, 0.75)
	parallax.append([far, far.position, 0.75])
	var mid := add_sprite(SPR + "backgrounds/peak_mid.png", Vector2(240, 190), ground, false)
	mid.modulate = Color(0.5, 0.52, 0.62)
	parallax.append([mid, mid.position, 0.5])
	add_sprite(SPR + "backgrounds/peak_ground.png", Vector2(240, 262), ground, true)

	# Batu Penebus: a whole mountain on one man's back
	stone = add_sprite(SPR + "backgrounds/stone_colossal.png", Vector2(240, -62), ground, true)
	runes = add_glow_sprite(SPR + "backgrounds/stone_colossal_e.png", Vector2(240, -62), Color(0.7, 1.0, 1.1, 0.9))
	rune_light = add_light(Vector2(240, 160), Color("40e8ff"), 0.8, 260.0, 0.2, 40.0)

	mc = add_actor("mc", MC_POS)
	mc.pose("mc_poses", 2)
	for e in [[Vector2(-10, -6), Vector2(-52, 6)], [Vector2(10, -6), Vector2(52, 6)],
			[Vector2(-5, 0), Vector2(-34, 22)], [Vector2(5, 0), Vector2(34, 22)]]:
		var a: Vector2 = MC_POS + (e[0] as Vector2)
		var b: Vector2 = MC_POS + (e[1] as Vector2)
		add_prop(SPR + "props/iron_stake.png", b + Vector2(0, 10))
		var ch := ChainLine.new(a, b + Vector2(0, -6), 5.0)
		world.add_child(ch)
		chains.append(ch)

	# tally marks scratched in the dirt (revealed during the montage)
	tally = Node2D.new()
	tally.position = MC_POS + Vector2(-30, 14)
	tally.visible = false
	ground.add_child(tally)
	for i in 12:
		var l := Line2D.new()
		l.width = 1.0
		l.default_color = Color(0.8, 0.78, 0.85, 0.7)
		var x := float(i) * 3.0 + floorf(i / 5.0) * 3.0
		if i % 5 == 4:
			l.add_point(Vector2(x - 13, 1))
			l.add_point(Vector2(x, 5))
		else:
			l.add_point(Vector2(x, 0))
			l.add_point(Vector2(x, 6))
		tally.add_child(l)

	crow = Sprite2D.new()
	crow.texture = UIKit.tex(SPR + "characters/crow.png")
	crow.hframes = 2
	crow.position = Vector2(560, 120)
	crow.visible = false
	world.add_child(crow)

	# diffuse overcast light from above so the daytime storm still reads
	sky_light = DirectionalLight2D.new()
	sky_light.color = Color(0.72, 0.78, 0.95)
	sky_light.energy = 0.42
	sky_light.height = 0.6
	sky_light.rotation_degrees = -25.0
	add_child(sky_light)
	lightning_light = PointLight2D.new()
	lightning_light.texture = UIKit.radial_light_texture(256)
	lightning_light.texture_scale = 4.0
	lightning_light.color = Color(0.75, 0.82, 1.0)
	lightning_light.energy = 0.0
	lightning_light.height = 120.0
	lightning_light.position = Vector2(140, -120)
	add_child(lightning_light)

	var rain_layer := CanvasLayer.new()
	rain_layer.layer = 2
	add_child(rain_layer)
	var rain_root := Node2D.new()
	rain_root.scale = Vector2(3, 3)
	rain_layer.add_child(rain_root)
	var r := FX.rain(Vector2(520, 10), 380)
	r.position = Vector2(200, -10)
	rain_root.add_child(r)


func _process(delta: float) -> void:
	super._process(delta)
	for p in parallax:
		var n: Node2D = p[0]
		var base: Vector2 = p[1]
		var f: float = p[2]
		n.position = base + (cam.position - cam_start) * f
	_breath_t += delta
	if burdened and mc != null and mc.posed:
		mc.sprite.frame = 2 + int(_breath_t * 1.5) % 2


func lightning(strength: float = 1.0) -> void:
	Audio.sfx("thunder", -3.0 + strength * 2.0, randf_range(0.9, 1.1))
	var t := create_tween()
	t.tween_property(sky_mat, "shader_parameter/lightning", strength, 0.05)
	t.parallel().tween_property(lightning_light, "energy", 2.2 * strength, 0.05)
	t.tween_property(sky_mat, "shader_parameter/lightning", 0.0, 0.12)
	t.parallel().tween_property(lightning_light, "energy", 0.0, 0.12)
	t.tween_property(sky_mat, "shader_parameter/lightning", strength * 0.7, 0.04)
	t.parallel().tween_property(lightning_light, "energy", 1.6 * strength, 0.04)
	t.tween_property(sky_mat, "shader_parameter/lightning", 0.0, 0.5)
	t.parallel().tween_property(lightning_light, "energy", 0.0, 0.5)
	post.flash(Color(0.85, 0.9, 1.0), 0.25, 0.25 * strength)


func set_time_of_day(night: bool, dur: float = 1.5) -> void:
	var t := create_tween().set_parallel(true)
	t.tween_property(ambient, "color", Color(0.32, 0.34, 0.52) if night else Color(0.64, 0.68, 0.8), dur)
	t.tween_property(sky_mat, "shader_parameter/bottom_color", Color("141828") if night else Color("2a3044"), dur)
	t.tween_property(sky_mat, "shader_parameter/cloud_light", Color("1e2232") if night else Color("3a4258"), dur)
	t.tween_property(rune_light, "base_energy", 1.4 if night else 0.8, dur)
	t.tween_property(sky_light, "energy", 0.1 if night else 0.42, dur)


func day_card(day: String) -> void:
	await cine.fade_black(1.0, 0.7)
	await wait(0.3)
	cine.location("PUNCAK PENYESALAN", day, 2.6)
	await cine.fade_black(0.0, 0.8)
