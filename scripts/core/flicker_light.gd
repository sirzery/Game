class_name FlickerLight
extends PointLight2D
## Point light with a candle / torch flicker.

var base_energy: float = 1.0
var flicker: float = 0.18
var speed: float = 9.0
var _t: float = 0.0


func _init() -> void:
	_t = randf() * 100.0


func _process(delta: float) -> void:
	_t += delta * speed
	if flicker > 0.0:
		var n := sin(_t) * 0.5 + sin(_t * 2.31 + 1.3) * 0.3 + sin(_t * 5.17 + 0.4) * 0.2
		energy = base_energy * (1.0 + n * flicker)
