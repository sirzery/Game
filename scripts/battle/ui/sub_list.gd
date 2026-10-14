class_name SubList
extends Control
## Skill / item list. await run(on_change) -> index or -1 when cancelled.

var entries: Array = []
var title: String = ""
var index: int = 0
var _rows: Array[Label] = []
var _rights: Array[Label] = []


func _init(list: Array = [], heading: String = "") -> void:
	entries = list
	title = heading
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(self)


func _ready() -> void:
	var t := UIKit.label(title, 40, UIKit.BONE, UIKit.head_font())
	UIKit.shadow(t, Vector2(4, 4), UIKit.RED)
	t.position = Vector2(760, 112)
	t.rotation = deg_to_rad(-5.0)
	add_child(t)
	for i in entries.size():
		var e: Dictionary = entries[i]
		var l := UIKit.label(str(e["name"]), 28, UIKit.BONE, UIKit.body_font(800))
		l.position = _pos(i) + Vector2(56, 8)
		add_child(l)
		_rows.append(l)
		var r := UIKit.label(str(e["right"]), 24, UIKit.GOLD, UIKit.head_font())
		r.position = _pos(i) + Vector2(380, 10)
		add_child(r)
		_rights.append(r)
	_refresh()


func _pos(i: int) -> Vector2:
	return Vector2(760.0 + float(i) * 8.0, 180.0 + float(i) * 60.0)


func run(on_change: Callable) -> int:
	on_change.call(index)
	var waited := 0.0
	while true:
		await get_tree().process_frame
		waited += get_process_delta_time()
		if Input.is_action_just_pressed("move_down"):
			index = (index + 1) % entries.size()
			Audio.sfx("ui_move", -8.0)
			on_change.call(index)
			_refresh()
		elif Input.is_action_just_pressed("move_up"):
			index = (index - 1 + entries.size()) % entries.size()
			Audio.sfx("ui_move", -8.0)
			on_change.call(index)
			_refresh()
		elif Input.is_action_just_pressed("accept") and waited > 0.12:
			if bool(entries[index].get("enabled", true)):
				Audio.sfx("ui_confirm")
				return index
			Audio.sfx("ui_cancel")
		elif Input.is_action_just_pressed("cancel"):
			Audio.sfx("ui_cancel")
			return -1
	return -1


func _refresh() -> void:
	for i in _rows.size():
		var en := bool(entries[i].get("enabled", true))
		var col := UIKit.BONE if en else Color(0.5, 0.48, 0.5)
		if i == index and en:
			col = UIKit.BONE
		_rows[i].add_theme_color_override("font_color", col)
	queue_redraw()


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(740, 100), Vector2(1280, 80), Vector2(1280, 600),
		Vector2(720, 620)]), Color(0, 0, 0, 0.78))
	for i in entries.size():
		var p := _pos(i)
		var sel := i == index
		var col := UIKit.RED if sel else Color(0.12, 0.1, 0.14, 0.9)
		draw_colored_polygon(PackedVector2Array([p + Vector2(10, 4), p + Vector2(470, 0), p + Vector2(462, 52),
			p + Vector2(0, 56)]), col)
		var tex := UIKit.tex(str(entries[i].get("icon", "")))
		if tex:
			draw_texture_rect(tex, Rect2(p + Vector2(14, 10), Vector2(32, 32)), false)
