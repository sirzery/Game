class_name ChoiceList
extends Control
## Persona-style vertical choice menu. await run() returns the chosen index.

var _options: Array = []
var _labels: Array[Label] = []
var _index: int = 0
var _anim: Array[float] = []


func _init(options: Array = []) -> void:
	_options = options
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(self)


func _ready() -> void:
	for i in _options.size():
		var l := UIKit.label(GameState.fmt(str(_options[i])), 28, UIKit.BONE, UIKit.body_font(800))
		l.position = _item_pos(i) + Vector2(40, 8)
		l.rotation = deg_to_rad(-3.0)
		add_child(l)
		_labels.append(l)
		_anim.append(0.0)
	Audio.sfx("ui_open", -10.0)


func _item_pos(i: int) -> Vector2:
	var count := _options.size()
	var y0 := 470.0 - float(count) * 64.0
	return Vector2(760.0 + float(i) * 14.0, y0 + float(i) * 64.0)


func run() -> int:
	var waited := 0.0
	while true:
		await get_tree().process_frame
		var dt := get_process_delta_time()
		waited += dt
		for i in _anim.size():
			var target := 1.0 if i == _index else 0.0
			_anim[i] = lerpf(_anim[i], target, minf(1.0, dt * 14.0))
			_labels[i].position = _item_pos(i) + Vector2(40.0 - _anim[i] * 30.0, 8.0)
			_labels[i].add_theme_color_override("font_color", UIKit.BONE if i == _index else Color("b8b0a8"))
		queue_redraw()
		if Settings.autotest and waited > 0.2:
			Audio.sfx("ui_confirm", -6.0)
			return _index
		if Input.is_action_just_pressed("move_down"):
			_index = (_index + 1) % _options.size()
			Audio.sfx("ui_move", -8.0)
		elif Input.is_action_just_pressed("move_up"):
			_index = (_index - 1 + _options.size()) % _options.size()
			Audio.sfx("ui_move", -8.0)
		elif Input.is_action_just_pressed("accept") and waited > 0.15:
			Audio.sfx("ui_confirm", -6.0)
			return _index
	return _index


func _draw() -> void:
	for i in _options.size():
		var p := _item_pos(i) - Vector2(_anim[i] * 30.0, 0.0)
		var w := 470.0
		var sel := i == _index
		var col := UIKit.RED if sel else UIKit.BLACK
		if sel:
			draw_colored_polygon(PackedVector2Array([p + Vector2(8, 8), p + Vector2(w + 18, 0), p + Vector2(w + 4, 62),
				p + Vector2(-8, 66)]), UIKit.BONE)
		draw_colored_polygon(PackedVector2Array([p + Vector2(14, 10), p + Vector2(w + 10, 4), p + Vector2(w, 56),
			p + Vector2(0, 60)]), col)
		if sel:
			draw_colored_polygon(PackedVector2Array([p + Vector2(-26, 22), p + Vector2(4, 32), p + Vector2(-26, 42)]),
				UIKit.BONE)
