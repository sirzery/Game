class_name StageScene
extends Node2D
## Base class of every playable/cinematic scene in DOSIER.
##
## Provides: a y-sorted lit `world`, an emissive `glow` layer that follows the
## camera but ignores the darkness of CanvasModulate, a `sky` layer behind
## everything, the HD-2D post-process, the cinematic overlay, the Persona
## dialogue box and the camera. Subclasses override `setup()` (build the
## scene) and `run()` (the async script of the scene).

var cam: StageCamera
var post: PostFX
var cine: CineOverlay
var dlg: DialogueBox
var world: Node2D
var ground: Node2D
var glow: CanvasLayer
var sky: CanvasLayer
var ambient: CanvasModulate
var cutscene: bool = false
var allow_skip: bool = true


func _ready() -> void:
	sky = CanvasLayer.new()
	sky.layer = -10
	add_child(sky)
	ambient = CanvasModulate.new()
	ambient.color = Color(1, 1, 1)
	add_child(ambient)
	ground = Node2D.new()
	ground.name = "Ground"
	add_child(ground)
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	glow = CanvasLayer.new()
	glow.layer = 1
	glow.follow_viewport_enabled = true
	add_child(glow)
	cam = StageCamera.new()
	add_child(cam)
	cam.make_current()
	post = PostFX.new()
	add_child(post)
	cine = CineOverlay.new()
	add_child(cine)
	dlg = DialogueBox.new()
	add_child(dlg)
	setup()
	_start.call_deferred()


func _start() -> void:
	run()


## Override: build the scene (backgrounds, actors, lights).
func setup() -> void:
	pass


## Override: async scene script.
func run() -> void:
	pass


func _process(_delta: float) -> void:
	if Router.busy:
		return
	if Settings.autotest:
		Engine.time_scale = 3.0
	elif cutscene and allow_skip and Input.is_action_pressed("skip"):
		Engine.time_scale = 4.0
	else:
		Engine.time_scale = 1.0


func _exit_tree() -> void:
	Engine.time_scale = 1.0


# ---------------------------------------------------------------------------
# Script helpers
# ---------------------------------------------------------------------------
func wait(sec: float) -> void:
	await get_tree().create_timer(sec, false).timeout


func begin_cutscene() -> void:
	cutscene = true
	await cine.letterbox(true, 0.5)


func end_cutscene() -> void:
	cutscene = false
	await cine.letterbox(false, 0.5)


func say(speaker: String, line: String, expr: String = "neutral", opts: Dictionary = {}) -> void:
	await dlg.say(speaker, line, expr, opts)


func think(line: String, expr: String = "neutral") -> void:
	await dlg.think(line, expr)


func narrate(line: String) -> void:
	await dlg.narrate(line)


func choose(options: Array, prompt: String = "") -> int:
	return await dlg.choose(options, prompt)


func close_dialogue() -> void:
	await dlg.close()


func snap(label: String) -> void:
	await Router.snap(label)


# ---------------------------------------------------------------------------
# Building helpers
# ---------------------------------------------------------------------------
func add_sprite(path: String, pos: Vector2, parent: Node = null, lit: bool = true, centered: bool = true) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = UIKit.lit_tex(path) if lit else UIKit.tex(path)
	s.centered = centered
	s.position = pos
	(parent if parent != null else world).add_child(s)
	return s


func add_prop(path: String, feet: Vector2, parent: Node = null, lit: bool = true) -> Sprite2D:
	## A sprite whose origin is at its bottom-centre (for y-sorting).
	var s := add_sprite(path, feet, parent, lit, true)
	if s.texture:
		s.offset = Vector2(0, -s.texture.get_height() * 0.5)
	return s


func add_glow_sprite(path: String, pos: Vector2, modulate_color: Color = Color.WHITE, centered: bool = true) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = UIKit.tex(path)
	s.centered = centered
	s.position = pos
	s.modulate = modulate_color
	s.material = FX.additive()
	glow.add_child(s)
	return s


func add_light(pos: Vector2, color: Color, energy: float = 1.0, scale_px: float = 160.0, flicker: float = 0.0,
		height: float = 30.0, parent: Node = null) -> FlickerLight:
	var l := FlickerLight.new()
	l.texture = UIKit.radial_light_texture(256)
	l.texture_scale = scale_px / 256.0
	l.color = color
	l.energy = energy
	l.base_energy = energy
	l.flicker = flicker
	l.height = height
	l.position = pos
	(parent if parent != null else self).add_child(l)
	return l


func add_actor(id: String, pos: Vector2, face_dir: String = "down") -> Actor:
	var a := Actor.new(id)
	a.position = pos
	world.add_child(a)
	a.face(face_dir)
	return a


func spawn_fx(p: Node2D, pos: Vector2, on_glow: bool = true) -> Node2D:
	p.position = pos
	if on_glow:
		glow.add_child(p)
	else:
		world.add_child(p)
	return p


func shake(amount: float = 0.6, power: float = 6.0) -> void:
	cam.shake(amount, power)


func add_shaft(top: Vector2, top_w: float, bottom: Vector2, bottom_w: float, color: Color,
		parent: Node = null) -> Polygon2D:
	## Additive god-ray polygon (bright at the top, fading towards the floor).
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([top + Vector2(-top_w * 0.5, 0), top + Vector2(top_w * 0.5, 0),
		bottom + Vector2(bottom_w * 0.5, 0), bottom + Vector2(-bottom_w * 0.5, 0)])
	var c0 := color
	var c1 := Color(color, 0.0)
	poly.vertex_colors = PackedColorArray([c0, c0, c1, c1])
	poly.material = FX.additive()
	(parent if parent != null else glow).add_child(poly)
	return poly


func add_flame(pos: Vector2, scale_k: float = 1.0) -> Flipbook:
	var f := Flipbook.new(UIKit.tex("res://assets/sprites/props/flame.png"), 4, 9.0)
	f.position = pos
	f.scale = Vector2(scale_k, scale_k)
	f.material = FX.additive()
	glow.add_child(f)
	return f


func add_sky(params: Dictionary = {}) -> ShaderMaterial:
	## Full-screen animated pixel sky behind everything (see shaders/sky.gdshader).
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(rect)
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/sky.gdshader") as Shader
	# every uniform that scripts may tween must exist on the material first
	m.set_shader_parameter("lightning", 0.0)
	m.set_shader_parameter("scroll", Vector2.ZERO)
	for k in params.keys():
		m.set_shader_parameter(str(k), params[k])
	rect.material = m
	sky.add_child(rect)
	return m
