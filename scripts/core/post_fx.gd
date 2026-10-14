class_name PostFX
extends CanvasLayer
## Full-screen HD-2D post-process (see shaders/post_fx.gdshader).
## Lives between the world (layer 0) and the UI layers (60+).

const PRESETS := {
	"default": {"tilt_amount": 0.55, "bloom_amount": 0.45, "bloom_threshold": 0.6, "vignette": 0.45,
		"saturation": 1.0, "contrast": 1.06, "exposure": 1.0, "tint": Color(1, 1, 1), "lift": Color(0, 0, 0),
		"grain": 0.035, "aberration": 0.8, "focus_center": 0.55, "focus_width": 0.22},
	"tribunal": {"tilt_amount": 0.7, "bloom_amount": 0.75, "bloom_threshold": 0.5, "vignette": 0.6,
		"saturation": 0.95, "contrast": 1.1, "exposure": 1.05, "tint": Color(1.0, 0.95, 0.9),
		"lift": Color(0.04, 0.0, 0.05), "grain": 0.04},
	"storm": {"tilt_amount": 0.6, "bloom_amount": 0.6, "bloom_threshold": 0.55, "vignette": 0.65,
		"saturation": 0.75, "contrast": 1.12, "exposure": 1.0, "tint": Color(0.88, 0.95, 1.08),
		"lift": Color(0.0, 0.02, 0.06), "grain": 0.06},
	"clash": {"tilt_amount": 0.55, "bloom_amount": 1.0, "bloom_threshold": 0.5, "vignette": 0.6,
		"saturation": 0.95, "contrast": 1.15, "exposure": 1.05, "tint": Color(0.95, 0.97, 1.05),
		"lift": Color(0.02, 0.0, 0.06), "grain": 0.05},
	"forest_night": {"tilt_amount": 0.6, "bloom_amount": 0.7, "bloom_threshold": 0.5, "vignette": 0.6,
		"saturation": 0.85, "contrast": 1.08, "tint": Color(0.85, 0.95, 1.1), "lift": Color(0.0, 0.02, 0.05),
		"grain": 0.05},
	"dusk": {"tilt_amount": 0.65, "bloom_amount": 0.6, "bloom_threshold": 0.58, "vignette": 0.45,
		"saturation": 1.05, "contrast": 1.06, "exposure": 1.12, "tint": Color(1.06, 0.97, 0.88),
		"lift": Color(0.04, 0.0, 0.03), "grain": 0.03},
	"night": {"tilt_amount": 0.65, "bloom_amount": 0.9, "bloom_threshold": 0.45, "vignette": 0.6,
		"saturation": 0.9, "contrast": 1.08, "exposure": 1.0, "tint": Color(0.9, 0.95, 1.1),
		"lift": Color(0.0, 0.01, 0.05), "grain": 0.045},
	"synod": {"tilt_amount": 0.7, "bloom_amount": 0.8, "bloom_threshold": 0.5, "vignette": 0.7,
		"saturation": 0.8, "contrast": 1.12, "exposure": 0.98, "tint": Color(1.05, 0.92, 0.88),
		"lift": Color(0.05, 0.0, 0.02), "grain": 0.05},
	"battle": {"tilt_amount": 0.45, "bloom_amount": 0.7, "bloom_threshold": 0.55, "vignette": 0.45,
		"saturation": 1.0, "contrast": 1.1, "tint": Color(0.95, 0.98, 1.06), "lift": Color(0.02, 0.0, 0.05),
		"grain": 0.035, "focus_center": 0.62, "focus_width": 0.3},
	"title": {"tilt_amount": 0.4, "bloom_amount": 0.9, "bloom_threshold": 0.5, "vignette": 0.55,
		"saturation": 1.0, "contrast": 1.1, "grain": 0.05, "tint": Color(1, 1, 1), "lift": Color(0.03, 0.0, 0.02)},
}

var rect: ColorRect
var mat: ShaderMaterial
var _flash_tween: Tween


func _init() -> void:
	layer = 50


func _ready() -> void:
	rect = ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(rect)
	mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/post_fx.gdshader") as Shader
	mat.set_shader_parameter("noise_tex", UIKit.tex("res://assets/sprites/ui/noise.png"))
	rect.material = mat
	add_child(rect)
	apply_preset("default")
	set_param("flash_color", Color(1, 1, 1, 0))


func apply_preset(preset_name: String, dur: float = 0.0) -> void:
	var base: Dictionary = PRESETS["default"]
	var p: Dictionary = PRESETS.get(preset_name, base)
	for key in base.keys():
		var value: Variant = p.get(key, base[key])
		if dur > 0.0:
			tween_param(str(key), value, dur)
		else:
			set_param(str(key), value)


func set_param(param: String, value: Variant) -> void:
	if mat:
		mat.set_shader_parameter(param, value)


func get_param(param: String) -> Variant:
	return mat.get_shader_parameter(param) if mat else null


func tween_param(param: String, to: Variant, dur: float) -> Tween:
	var t := create_tween()
	t.tween_property(mat, "shader_parameter/" + param, to, maxf(dur, 0.01))
	return t


func flash(color: Color = Color.WHITE, dur: float = 0.35, peak: float = 1.0) -> void:
	if _flash_tween:
		_flash_tween.kill()
	var c := color
	c.a = peak
	set_param("flash_color", c)
	var end := c
	end.a = 0.0
	_flash_tween = create_tween()
	_flash_tween.tween_property(mat, "shader_parameter/flash_color", end, maxf(dur, 0.01)) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
