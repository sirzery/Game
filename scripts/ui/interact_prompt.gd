class_name InteractPrompt
extends Control
## Small slanted tag floating over the current interaction target.

var _label: Label
var _w: float = 160.0
var _t: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _ready() -> void:
	_label = UIKit.label("", 22, UIKit.BONE, UIKit.head_font())
	_label.position = Vector2(46, -2)
	add_child(_label)


func show_for(text: String) -> void:
	_label.text = text
	_w = _label.get_minimum_size().x + 64.0
	visible = true
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if visible:
		_label.position.y = -2.0 + sin(_t * 5.0) * 2.0


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(8, 0), Vector2(_w, -4), Vector2(_w - 8, 30), Vector2(0, 34)]),
		UIKit.BLACK)
	draw_colored_polygon(PackedVector2Array([Vector2(6, 2), Vector2(38, 0), Vector2(32, 32), Vector2(0, 34)]), UIKit.RED)
	draw_string(UIKit.head_font(), Vector2(10, 26), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, UIKit.BONE)
