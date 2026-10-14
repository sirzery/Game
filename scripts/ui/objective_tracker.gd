class_name ObjectiveTracker
extends Control
## Persona-style objective list (top-right corner).

var _labels: Array[Label] = []
var _title: Label
var _rows: Array = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(880, 96)
	size = Vector2(400, 300)


func _ready() -> void:
	_title = UIKit.label("TUJUAN", 30, UIKit.BLACK, UIKit.head_font())
	_title.position = Vector2(34, -2)
	_title.rotation = deg_to_rad(-4.0)
	add_child(_title)
	GameState.objectives_changed.connect(refresh)
	refresh()


func refresh() -> void:
	for l in _labels:
		l.queue_free()
	_labels.clear()
	_rows.clear()
	var y := 48.0
	for o in GameState.objectives:
		var od: Dictionary = o
		var txt := str(od["text"])
		if int(od["max"]) > 1:
			txt += "  %d/%d" % [int(od["cur"]), int(od["max"])]
		var done := bool(od["done"])
		var col := Color(0.62, 0.6, 0.62) if done else UIKit.BONE
		if bool(od.get("optional", false)) and not done:
			col = Color("c8c0a8")
		var l := UIKit.label(txt, 20, col, UIKit.body_font(700 if not done else 500))
		UIKit.outline(l, 5, UIKit.BLACK)
		l.position = Vector2(46, y)
		add_child(l)
		_labels.append(l)
		_rows.append([y, done])
		y += 34.0
	size.y = y + 10.0
	queue_redraw()


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(20, 4), Vector2(170, -6), Vector2(164, 36), Vector2(14, 44)]),
		UIKit.BONE)
	draw_colored_polygon(PackedVector2Array([Vector2(10, 44), Vector2(400, 36), Vector2(400, size.y),
		Vector2(0, size.y + 6)]), Color(0, 0, 0, 0.55))
	for r in _rows:
		var y: float = r[0]
		var done: bool = r[1]
		var box := Rect2(Vector2(18, y + 6), Vector2(16, 16))
		draw_rect(box, UIKit.BONE, false, 2.0)
		if done:
			draw_line(box.position + Vector2(3, 8), box.position + Vector2(7, 13), UIKit.RED, 3.0)
			draw_line(box.position + Vector2(7, 13), box.position + Vector2(15, 1), UIKit.RED, 3.0)
