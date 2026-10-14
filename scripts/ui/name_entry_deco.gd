class_name NameEntryDeco
extends Control
## Crimson slashes for the naming screen.


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(520, 0), Vector2(1280, 0), Vector2(1280, 720), Vector2(420, 720)]),
		Color(0, 0, 0, 0.55))
	draw_colored_polygon(PackedVector2Array([Vector2(540, 232), Vector2(1280, 168), Vector2(1280, 180),
		Vector2(540, 244)]), UIKit.RED)
	draw_colored_polygon(PackedVector2Array([Vector2(560, 560), Vector2(1280, 500), Vector2(1280, 506),
		Vector2(560, 566)]), UIKit.BONE)
