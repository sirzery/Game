class_name TitleSlash
extends Control
## Decorative crimson slashes behind the DOSIER logo.

var _t: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	# dark wedge so the logo reads over the sky
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(720, 0), Vector2(560, 720), Vector2(0, 720)]),
		Color(0.02, 0.0, 0.02, 0.55))
	var k := 0.5 + 0.5 * sin(_t * 1.3)
	draw_colored_polygon(PackedVector2Array([Vector2(30, 250), Vector2(700, 160), Vector2(700, 176),
		Vector2(30, 268)]), UIKit.RED)
	draw_colored_polygon(PackedVector2Array([Vector2(104, 268), Vector2(590, 234), Vector2(584, 270),
		Vector2(98, 306)]), UIKit.BONE)
	draw_line(Vector2(0, 380 + k * 4.0), Vector2(640, 336 + k * 4.0), Color(UIKit.RED, 0.5), 2.0)
	# menu backdrop stripe
	draw_colored_polygon(PackedVector2Array([Vector2(0, 372), Vector2(520, 340), Vector2(470, 720),
		Vector2(0, 720)]), Color(0, 0, 0, 0.35))
