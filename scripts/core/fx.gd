class_name FX
extends RefCounted
## Factory for particle effects (CPU particles: work on every renderer).

static var _dot: ImageTexture
static var _streak: ImageTexture
static var _soft: GradientTexture2D


static func clear_caches() -> void:
	_dot = null
	_streak = null
	_soft = null


static func dot_tex() -> ImageTexture:
	if _dot == null:
		var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_dot = ImageTexture.create_from_image(img)
	return _dot


static func streak_tex() -> ImageTexture:
	if _streak == null:
		var img := Image.create(1, 7, false, Image.FORMAT_RGBA8)
		for y in 7:
			img.set_pixel(0, y, Color(1, 1, 1, float(y + 1) / 7.0))
		_streak = ImageTexture.create_from_image(img)
	return _streak


static func soft_tex() -> GradientTexture2D:
	if _soft == null:
		_soft = UIKit.radial_light_texture(32)
	return _soft


static func additive() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return m


static func unshaded() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return m


static func _ramp(colors: Array) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, colors[0])
	g.set_color(1, colors[colors.size() - 1])
	for i in range(1, colors.size() - 1):
		g.add_point(float(i) / float(colors.size() - 1), colors[i])
	return g


static func rain(area: Vector2, amount: int = 420) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = 0.7
	p.preprocess = 1.0
	p.texture = streak_tex()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(area.x * 0.6, 4)
	p.direction = Vector2(0.18, 1.0)
	p.spread = 2.0
	p.gravity = Vector2(0, 200)
	p.initial_velocity_min = 330.0
	p.initial_velocity_max = 420.0
	p.particle_flag_align_y = true
	p.color = Color(0.7, 0.8, 1.0, 0.55)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 1.6
	p.material = unshaded()
	return p


static func embers(area: Vector2, amount: int = 40, color: Color = Color(1.0, 0.55, 0.2)) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = 2.6
	p.preprocess = 2.0
	p.texture = dot_tex()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = area * 0.5
	p.direction = Vector2(0.2, -1.0)
	p.spread = 30.0
	p.gravity = Vector2(4, -12)
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 26.0
	p.angular_velocity_min = -90.0
	p.angular_velocity_max = 90.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	p.color_ramp = _ramp([Color(color, 0.0), Color(color * 1.6, 1.0), Color(color, 0.8), Color(color, 0.0)])
	p.material = additive()
	return p


static func dust(area: Vector2, amount: int = 50, color: Color = Color(1.0, 0.95, 0.8)) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.texture = dot_tex()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = area * 0.5
	p.direction = Vector2(1, 0.2)
	p.spread = 180.0
	p.gravity = Vector2(0, 1.5)
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 5.0
	p.scale_amount_min = 0.3
	p.scale_amount_max = 0.7
	p.color_ramp = _ramp([Color(color, 0.0), Color(color, 0.7), Color(color, 0.0)])
	p.material = additive()
	return p


static func ash(area: Vector2, amount: int = 60) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.texture = dot_tex()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(area.x * 0.5, 4)
	p.direction = Vector2(0.3, 1.0)
	p.spread = 25.0
	p.gravity = Vector2(3, 6)
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 14.0
	p.angular_velocity_min = -60.0
	p.angular_velocity_max = 60.0
	p.scale_amount_min = 0.4
	p.scale_amount_max = 1.0
	p.color_ramp = _ramp([Color(0.8, 0.75, 0.8, 0.0), Color(0.85, 0.8, 0.85, 0.6), Color(0.6, 0.55, 0.6, 0.0)])
	return p


static func fireflies(area: Vector2, amount: int = 24) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = 5.0
	p.preprocess = 5.0
	p.texture = dot_tex()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = area * 0.5
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 9.0
	p.orbit_velocity_min = -0.05
	p.orbit_velocity_max = 0.05
	p.scale_amount_min = 0.5
	p.scale_amount_max = 0.9
	var c := Color(0.75, 1.0, 0.45)
	p.color_ramp = _ramp([Color(c, 0.0), Color(c * 1.5, 1.0), Color(c, 0.2), Color(c * 1.5, 1.0), Color(c, 0.0)])
	p.material = additive()
	return p


static func burst(color: Color, amount: int = 24, speed: float = 90.0, life: float = 0.6,
		gravity: float = 120.0) -> CPUParticles2D:
	## One-shot spark burst; frees itself.
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = amount
	p.lifetime = life
	p.texture = dot_tex()
	p.spread = 180.0
	p.gravity = Vector2(0, gravity)
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.3
	p.color_ramp = _ramp([Color(color * 2.0, 1.0), Color(color, 0.9), Color(color, 0.0)])
	p.material = additive()
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


static func debris(amount: int = 30, color: Color = Color(0.35, 0.3, 0.38)) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 0.85
	p.amount = amount
	p.lifetime = 1.6
	p.texture = dot_tex()
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.gravity = Vector2(0, 320)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 170.0
	p.angular_velocity_min = -200.0
	p.angular_velocity_max = 200.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 3.0
	p.color = color
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


static func smoke(area: Vector2, amount: int = 14) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = 4.0
	p.preprocess = 4.0
	p.texture = soft_tex()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = area * 0.5
	p.direction = Vector2(0.2, -1)
	p.spread = 12.0
	p.gravity = Vector2(3, -4)
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 12.0
	p.scale_amount_min = 0.25
	p.scale_amount_max = 0.6
	p.color_ramp = _ramp([Color(0.6, 0.6, 0.65, 0.0), Color(0.5, 0.5, 0.55, 0.25), Color(0.4, 0.4, 0.45, 0.0)])
	return p
