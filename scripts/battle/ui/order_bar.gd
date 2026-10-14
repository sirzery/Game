class_name OrderBar
extends Control
## Top strip showing the turn order of the current round.

var _names: Array = []
var _players: Array = []
var _current: int = 0
var _labels: Array[Label] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_order(order: Array, current: int) -> void:
	_names.clear()
	_players.clear()
	for b in order:
		var bat: Battler = b
		if bat.alive():
			_names.append(bat.short_name)
			_players.append(bat.is_player)
	_current = current
	for l in _labels:
		l.queue_free()
	_labels.clear()
	var x := 110.0
	for i in _names.size():
		var l := UIKit.label(str(_names[i]), 22, UIKit.BONE if i != _current else UIKit.BLACK, UIKit.head_font())
		l.position = Vector2(x, 6)
		add_child(l)
		_labels.append(l)
		x += maxf(110.0, l.get_minimum_size().x + 40.0)
	queue_redraw()


func _draw() -> void:
	var title := "GILIRAN"
	draw_colored_polygon(PackedVector2Array([Vector2(0, 2), Vector2(96, 0), Vector2(90, 40), Vector2(-6, 42)]), UIKit.RED)
	var f := UIKit.head_font()
	draw_string(f, Vector2(10, 32), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, UIKit.BONE)
	for i in _labels.size():
		var l := _labels[i]
		var w := l.get_minimum_size().x + 26.0
		var p := l.position - Vector2(13, 6)
		var col := UIKit.BONE if i == _current else (Color("1e2a50") if _players[i] else UIKit.BLACK)
		draw_colored_polygon(PackedVector2Array([p + Vector2(8, 0), p + Vector2(w + 8, 0), p + Vector2(w, 40),
			p + Vector2(0, 40)]), col)
