class_name ActionBanner
extends Control
## Slanted banner announcing the current action.

var _label: Label
var _k: float = 0.0:
	set(v):
		_k = v
		queue_redraw()
var _color: Color = UIKit.BLACK
var _w: float = 400.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(1280, 70)


func _ready() -> void:
	_label = UIKit.label("", 32, UIKit.BONE, UIKit.head_font(), HORIZONTAL_ALIGNMENT_CENTER)
	_label.size = Vector2(1280, 50)
	_label.position = Vector2(0, 8)
	_label.modulate.a = 0.0
	add_child(_label)


func show_text(t: String, color: Color) -> void:
	_label.text = t
	_color = color
	_w = _label.get_minimum_size().x + 120.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "_k", 1.0, 0.15)
	tw.tween_property(_label, "modulate:a", 1.0, 0.15)


func hide_text() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "_k", 0.0, 0.15)
	tw.tween_property(_label, "modulate:a", 0.0, 0.15)


func _draw() -> void:
	if _k <= 0.01:
		return
	var w := _w * _k
	var x0 := 640.0 - w * 0.5
	draw_colored_polygon(PackedVector2Array([Vector2(x0 + 16, 6), Vector2(x0 + w + 16, 0), Vector2(x0 + w, 60),
		Vector2(x0, 64)]), UIKit.RED)
	draw_colored_polygon(PackedVector2Array([Vector2(x0 + 22, 10), Vector2(x0 + w + 8, 5), Vector2(x0 + w - 6, 54),
		Vector2(x0 + 8, 58)]), _color)
