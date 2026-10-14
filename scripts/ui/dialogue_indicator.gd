class_name DialogueIndicator
extends Control
## Bobbing crimson arrow shown when a line has finished typing.


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-2, -2), Vector2(30, -2), Vector2(14, 22)]), UIKit.BLACK)
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(26, 0), Vector2(13, 18)]), UIKit.RED)
