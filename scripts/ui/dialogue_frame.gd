class_name DialogueFrame
extends Control
## The jagged black text window of the dialogue box.

var inner: bool = false
var narration: bool = false
var pop: float = 1.0:
	set(v):
		pop = v
		queue_redraw()

const SHAPE := [Vector2(70, 512), Vector2(520, 500), Vector2(540, 488), Vector2(560, 499), Vector2(1238, 488),
	Vector2(1216, 702), Vector2(44, 710)]


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := Vector2(640, 600)
	draw_set_transform(c, 0.0, Vector2(1.0, maxf(pop, 0.01)))
	var pts := PackedVector2Array()
	for p in SHAPE:
		pts.append((p as Vector2) - c)
	var fill := UIKit.BLACK
	var border := UIKit.BONE
	if inner:
		fill = Color("0d1426")
		border = Color("8aa0d0")
	elif narration:
		fill = Color("120e10")
		border = UIKit.GOLD
	# drop shadow
	var shadow := PackedVector2Array()
	for p in pts:
		shadow.append(p + Vector2(10, 10))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.55))
	draw_colored_polygon(pts, fill)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, border, 5.0)
	# crimson accent stripe
	draw_line(Vector2(-560, 96), Vector2(-150, 92), UIKit.RED, 4.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
