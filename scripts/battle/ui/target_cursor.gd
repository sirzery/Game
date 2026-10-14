class_name TargetCursor
extends Control
## Bouncing crimson arrow over the selected target.

var _t: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var y := sin(_t * 8.0) * 6.0
	draw_colored_polygon(PackedVector2Array([Vector2(-20, -30 + y), Vector2(20, -30 + y), Vector2(0, y)]), UIKit.BONE)
	draw_colored_polygon(PackedVector2Array([Vector2(-14, -26 + y), Vector2(14, -26 + y), Vector2(0, -4 + y)]), UIKit.RED)
