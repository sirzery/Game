class_name PortraitBackdrop
extends Control
## Coloured comic-style burst behind dialogue portraits.

var flip: bool = false:
	set(v):
		flip = v
		queue_redraw()
var _color: Color = UIKit.RED
var _k: float = 1.0:
	set(v):
		_k = v
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_color(c: Color) -> void:
	_color = c
	queue_redraw()


func pop() -> void:
	_k = 0.2
	var t := create_tween()
	t.tween_property(self, "_k", 1.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var c := Vector2(230, 210)
	var pts := PackedVector2Array()
	var n := 14
	for i in n * 2:
		var a := float(i) / float(n * 2) * TAU + 0.2
		var r := (190.0 if i % 2 == 0 else 140.0) * _k
		if i % 5 == 0:
			r *= 1.12
		var p := c + Vector2(cos(a), sin(a) * 0.95) * r
		if flip:
			p.x = 460.0 - p.x
		pts.append(p)
	draw_colored_polygon(pts, _color.darkened(0.25))
	# halftone-ish diagonal stripes
	var inner := PackedVector2Array()
	for p in pts:
		inner.append(c + (p - c) * 0.82)
	draw_colored_polygon(inner, _color)
	for k in range(-6, 8):
		var x := 230.0 + float(k) * 34.0
		draw_line(Vector2(x - 120, 40), Vector2(x + 120, 380), Color(0, 0, 0, 0.18), 10.0)
