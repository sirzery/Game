class_name SlashBanner
extends Control
## Comic-book banner that slams across the screen ("BREAK!", "HANTAM!").

var _text: String
var _color: Color
var _size: int
var _k: float = 0.0:
	set(v):
		_k = v
		queue_redraw()
var _label: Label


func _init(text: String = "", color: Color = UIKit.RED, size_px: int = 96) -> void:
	_text = text
	_color = color
	_size = size_px
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func play(hold: float) -> void:
	_label = UIKit.label(_text, _size, UIKit.BONE, UIKit.head_font(), HORIZONTAL_ALIGNMENT_CENTER)
	UIKit.outline(_label, 14, UIKit.BLACK)
	_label.size = Vector2(1280, _size * 1.4)
	_label.position = Vector2(-1280, 360 - _size * 0.7)
	_label.pivot_offset = Vector2(640, _size * 0.7)
	_label.rotation = deg_to_rad(-6.0)
	add_child(_label)
	var t := create_tween()
	t.tween_property(self, "_k", 1.0, 0.18).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_label, "position:x", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(hold)
	t.tween_property(_label, "position:x", 1400.0, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(self, "_k", 0.0, 0.2)
	await t.finished


func _draw() -> void:
	if _k <= 0.001:
		return
	var h := 120.0 * _k
	var c := _color
	draw_colored_polygon(PackedVector2Array([Vector2(0, 360 - h + 40), Vector2(1280, 360 - h - 40),
		Vector2(1280, 360 + h - 40), Vector2(0, 360 + h + 40)]), c)
	draw_colored_polygon(PackedVector2Array([Vector2(0, 360 + h + 40), Vector2(1280, 360 + h - 40),
		Vector2(1280, 360 + h - 28), Vector2(0, 360 + h + 52)]), UIKit.BLACK)
