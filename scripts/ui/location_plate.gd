class_name LocationPlate
extends Control
## Top-left plate announcing place and time, styled after Persona's calendar.

var _place: String
var _when: String


func _init(place: String = "", when: String = "") -> void:
	_place = place
	_when = when
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(540, 120)


var _pw: float = 520.0
var _ww: float = 330.0


func _ready() -> void:
	var p := UIKit.label(_place, 44, UIKit.BONE, UIKit.head_font())
	UIKit.shadow(p, Vector2(4, 4), UIKit.RED_DARK)
	p.position = Vector2(48, 6)
	p.rotation = deg_to_rad(-3.0)
	add_child(p)
	var w := UIKit.label(_when, 22, UIKit.BLACK, UIKit.body_font(800))
	w.position = Vector2(70, 74)
	w.rotation = deg_to_rad(-3.0)
	add_child(w)
	_pw = maxf(420.0, p.get_minimum_size().x + 110.0)
	_ww = maxf(240.0, w.get_minimum_size().x + 60.0)
	size = Vector2(_pw + 20.0, 120)
	queue_redraw()


func _draw() -> void:
	# every edge follows the same -3 degree slant as the labels
	var k := tan(deg_to_rad(3.0))
	var pw := _pw
	var ww := _ww
	draw_colored_polygon(PackedVector2Array([Vector2(0, 8), Vector2(pw + 10.0, 8.0 - k * (pw + 10.0)),
		Vector2(pw - 20.0, 76.0 - k * (pw - 20.0)), Vector2(0, 76)]), UIKit.BLACK)
	draw_colored_polygon(PackedVector2Array([Vector2(0, 76), Vector2(pw - 20.0, 76.0 - k * (pw - 20.0)),
		Vector2(pw - 26.0, 86.0 - k * (pw - 26.0)), Vector2(0, 86)]), UIKit.RED)
	draw_colored_polygon(PackedVector2Array([Vector2(56, 70), Vector2(56.0 + ww, 70.0 - k * ww),
		Vector2(48.0 + ww, 110.0 - k * ww), Vector2(50, 112)]), UIKit.BONE)
