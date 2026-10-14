class_name PauseBackdrop
extends Control
## Red/black diagonal backdrop of the pause menu.


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.55))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(620, 0), Vector2(420, 720), Vector2(0, 720)]),
		Color(0.04, 0.0, 0.02, 0.92))
	draw_colored_polygon(PackedVector2Array([Vector2(620, 0), Vector2(660, 0), Vector2(460, 720), Vector2(420, 720)]),
		UIKit.RED)
