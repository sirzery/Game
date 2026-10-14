class_name Flipbook
extends Sprite2D
## Looping sprite-sheet animation (flames, campfire, crows...).

var fps: float = 8.0
var frames: int = 1
var first: int = 0
var playing: bool = true
var _t: float = 0.0


func _init(tex: Texture2D = null, frame_count: int = 1, rate: float = 8.0) -> void:
	texture = tex
	frames = maxi(1, frame_count)
	hframes = frames
	fps = rate
	_t = randf() * 10.0


func _process(delta: float) -> void:
	if not playing:
		return
	_t += delta
	var count := maxi(1, frames - first)
	frame = first + int(_t * fps) % count
