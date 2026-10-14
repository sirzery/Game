class_name PersonaMenu
extends Control
## Big slanted menu (title / pause). await run() -> index (or -1 on cancel).

var items: Array = []
var disabled: Array = []
var allow_cancel: bool = false
var font_size: int = 54
var spacing: float = 74.0
var origin: Vector2 = Vector2(90, 380)
var step_x: float = 18.0
var index: int = 0
var autotest_pick: int = 0

var _labels: Array[Label] = []
var _anim: Array[float] = []


func _init(entries: Array = [], disabled_flags: Array = []) -> void:
	items = entries
	disabled = disabled_flags
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(self)


func _ready() -> void:
	for i in items.size():
		var l := UIKit.label(str(items[i]), font_size, UIKit.BONE, UIKit.head_font())
		UIKit.outline(l, 8, UIKit.BLACK)
		l.rotation = deg_to_rad(-6.0)
		add_child(l)
		_labels.append(l)
		_anim.append(0.0)
	while index < items.size() and _is_disabled(index):
		index += 1
	index = clampi(index, 0, maxi(items.size() - 1, 0))
	for i in _anim.size():
		_anim[i] = 1.0 if i == index else 0.0
	_animate(0.0)


func _is_disabled(i: int) -> bool:
	return i < disabled.size() and bool(disabled[i])


func _pos(i: int) -> Vector2:
	return origin + Vector2(float(i) * step_x, float(i) * spacing)


func run() -> int:
	var waited := 0.0
	while true:
		await get_tree().process_frame
		var dt := get_process_delta_time() / maxf(Engine.time_scale, 0.001)
		waited += dt
		_animate(dt)
		if Settings.autotest and waited > 0.4:
			index = clampi(autotest_pick, 0, items.size() - 1)
			Audio.sfx("ui_confirm")
			return index
		if Input.is_action_just_pressed("move_down"):
			_move(1)
		elif Input.is_action_just_pressed("move_up"):
			_move(-1)
		elif Input.is_action_just_pressed("accept") and waited > 0.15:
			if _is_disabled(index):
				Audio.sfx("ui_cancel", -4.0)
			else:
				Audio.sfx("ui_confirm")
				return index
		elif allow_cancel and Input.is_action_just_pressed("cancel") and waited > 0.15:
			Audio.sfx("ui_cancel")
			return -1
	return index


func _move(dir: int) -> void:
	if items.is_empty():
		return
	for _i in items.size():
		index = (index + dir + items.size()) % items.size()
		if not _is_disabled(index):
			break
	Audio.sfx("ui_move", -6.0)


func _animate(dt: float) -> void:
	for i in _labels.size():
		var target := 1.0 if i == index else 0.0
		_anim[i] = lerpf(_anim[i], target, minf(1.0, dt * 14.0))
		var l := _labels[i]
		l.position = _pos(i) + Vector2(24.0 + _anim[i] * 26.0, -4.0)
		var s := 1.0 + _anim[i] * 0.12
		l.scale = Vector2(s, s)
		var col := UIKit.BONE
		if _is_disabled(i):
			col = Color(0.45, 0.42, 0.45)
		elif i != index:
			col = Color("c8c0b8")
		l.add_theme_color_override("font_color", col)
	queue_redraw()


func _draw() -> void:
	for i in items.size():
		if i != index:
			continue
		var p := _pos(i) + Vector2(_anim[i] * 26.0, 0.0)
		var w := float(font_size) * 0.62 * float(str(items[i]).length()) + 90.0
		var r := deg_to_rad(-6.0)
		var dir := Vector2(cos(r), sin(r))
		var down := Vector2(-sin(r), cos(r))
		var h := float(font_size) * 1.25 * _anim[i]
		if h < 1.0:
			continue
		var a := p + down * 6.0
		draw_colored_polygon(PackedVector2Array([a, a + dir * w, a + dir * (w - 18.0) + down * h, a + down * h]),
			UIKit.RED)
		draw_colored_polygon(PackedVector2Array([a + Vector2(-40, 20), a + Vector2(-8, 34), a + Vector2(-40, 48)]),
			UIKit.BONE)
