class_name NameTag
extends Control
## Tilted white name plate with the speaker's name in black.

var _label: Label
var _color: Color = UIKit.RED
var _w: float = 260.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotation = deg_to_rad(-4.0)


func _ready() -> void:
	_label = UIKit.label("", 34, UIKit.BLACK, UIKit.head_font())
	_label.position = Vector2(34, 4)
	add_child(_label)


func set_text(t: String, accent: Color) -> void:
	if _label == null:
		return
	_label.text = t
	_color = accent
	_w = maxf(200.0, _label.get_minimum_size().x + 74.0)
	queue_redraw()


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-6, 8), Vector2(_w + 10, 4), Vector2(_w - 8, 62),
		Vector2(-22, 64)]), _color)
	draw_colored_polygon(PackedVector2Array([Vector2(10, 0), Vector2(_w, 0), Vector2(_w - 16, 54),
		Vector2(-6, 56)]), UIKit.BONE)
