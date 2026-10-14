class_name PanelToast
extends Control
## Small slanted notification ("Didapat: Dahan Kering x1").

var _text: String
var _color: Color
var _w: float = 300.0


func _init(text: String = "", color: Color = UIKit.GOLD) -> void:
	_text = text
	_color = color
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	var l := UIKit.label(_text, 22, UIKit.BONE, UIKit.body_font(700))
	l.position = Vector2(34, 10)
	add_child(l)
	_w = maxf(260.0, l.get_minimum_size().x + 70.0)
	size = Vector2(_w, 52)
	queue_redraw()


func get_width() -> float:
	return _w


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(14, 0), Vector2(_w, 0), Vector2(_w, 50), Vector2(0, 50)]),
		UIKit.BLACK)
	draw_colored_polygon(PackedVector2Array([Vector2(14, 0), Vector2(24, 0), Vector2(10, 50), Vector2(0, 50)]), _color)
