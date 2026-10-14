class_name DescPanel
extends Control
## Bottom-left description line for the highlighted command.

var _label: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(780, 56)


func _ready() -> void:
	_label = UIKit.label("", 20, UIKit.BONE, UIKit.body_font(600))
	_label.position = Vector2(30, 14)
	_label.size = Vector2(740, 40)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_label)


func set_text(t: String) -> void:
	if _label:
		_label.text = t


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(14, 0), Vector2(790, 0), Vector2(776, 60), Vector2(0, 60)]),
		Color(0, 0, 0, 0.82))
	draw_colored_polygon(PackedVector2Array([Vector2(14, 0), Vector2(24, 0), Vector2(10, 60), Vector2(0, 60)]), UIKit.RED)
