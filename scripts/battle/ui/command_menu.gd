class_name CommandMenu
extends Control
## Persona-style diagonal battle command list with BOOST selection.

var labels: Array = []
var index: int = 0
var boost: int = 0
var boost_max: int = 0
var bp: int = 0
var _items: Array[Label] = []
var _anim: Array[float] = []
var _boost_label: Label


func _init(entries: Array = []) -> void:
	labels = entries
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(self)


func _ready() -> void:
	for i in labels.size():
		var l := UIKit.label(str(labels[i]), 44, UIKit.BONE, UIKit.head_font())
		UIKit.outline(l, 8, UIKit.BLACK)
		l.rotation = deg_to_rad(-8.0)
		add_child(l)
		_items.append(l)
		_anim.append(1.0 if i == index else 0.0)
	_boost_label = UIKit.label("", 26, UIKit.GOLD, UIKit.head_font())
	UIKit.outline(_boost_label, 6, UIKit.BLACK)
	_boost_label.position = Vector2(836, 448)
	add_child(_boost_label)
	_layout(0.0)


func _pos(i: int) -> Vector2:
	return Vector2(830.0 + float(i) * 16.0, 150.0 + float(i) * 58.0)


func run(on_change: Callable) -> int:
	var waited := 0.0
	on_change.call(index)
	while true:
		await get_tree().process_frame
		var dt := get_process_delta_time()
		waited += dt
		_layout(dt)
		if Input.is_action_just_pressed("move_down"):
			index = (index + 1) % labels.size()
			Audio.sfx("ui_move", -8.0)
			on_change.call(index)
		elif Input.is_action_just_pressed("move_up"):
			index = (index - 1 + labels.size()) % labels.size()
			Audio.sfx("ui_move", -8.0)
			on_change.call(index)
		elif Input.is_action_just_pressed("move_right"):
			if boost < boost_max:
				boost += 1
				Audio.sfx("boost", -4.0, 1.0 + float(boost) * 0.1)
		elif Input.is_action_just_pressed("move_left"):
			if boost > 0:
				boost -= 1
				Audio.sfx("ui_move", -6.0)
		elif Input.is_action_just_pressed("accept") and waited > 0.12:
			Audio.sfx("ui_confirm")
			return index
	return index


func _layout(dt: float) -> void:
	for i in _items.size():
		var target := 1.0 if i == index else 0.0
		_anim[i] = lerpf(_anim[i], target, minf(1.0, dt * 16.0)) if dt > 0.0 else target
		var l := _items[i]
		l.position = _pos(i) + Vector2(30.0 - _anim[i] * 34.0, -6.0)
		var s := 1.0 + _anim[i] * 0.15
		l.scale = Vector2(s, s)
		l.add_theme_color_override("font_color", UIKit.BONE if i == index else Color("b8b0a8"))
	if _boost_label:
		if boost_max <= 0:
			_boost_label.text = "BOOST  —  BP %d" % bp
		else:
			_boost_label.text = "BOOST  %d / %d   (KIRI / KANAN)" % [boost, boost_max]
	queue_redraw()


func _draw() -> void:
	# backdrop
	draw_colored_polygon(PackedVector2Array([Vector2(800, 120), Vector2(1280, 90), Vector2(1280, 560),
		Vector2(780, 600)]), Color(0, 0, 0, 0.45))
	for i in labels.size():
		if i != index:
			continue
		var p := _pos(i) - Vector2(_anim[i] * 34.0, 0.0)
		var r := deg_to_rad(-8.0)
		var dir := Vector2(cos(r), sin(r))
		var down := Vector2(-sin(r), cos(r))
		var w := float(str(labels[i]).length()) * 30.0 + 80.0
		var a := p + down * 4.0 + Vector2(-6, 0)
		draw_colored_polygon(PackedVector2Array([a + Vector2(-4, -2), a + dir * (w + 12.0), a + dir * w + down * 66.0,
			a + down * 70.0 + Vector2(-16, 0)]), UIKit.BONE)
		draw_colored_polygon(PackedVector2Array([a, a + dir * w, a + dir * (w - 12.0) + down * 60.0, a + down * 62.0]),
			UIKit.RED)
	# boost pips under the menu
	var bp_icon := UIKit.tex("res://assets/sprites/ui/icon_boost.png")
	var bp_empty := UIKit.tex("res://assets/sprites/ui/icon_boost_empty.png")
	for k in 5:
		var tex := bp_empty
		if k < bp:
			tex = bp_icon
		var pos := Vector2(840 + k * 36, 486)
		if tex:
			var sz := Vector2(32, 32) if k >= boost else Vector2(40, 40)
			draw_texture_rect(tex, Rect2(pos - (sz - Vector2(32, 32)) * 0.5, sz), false,
				Color(1, 1, 1) if k >= boost else Color(1.6, 1.3, 1.0))
