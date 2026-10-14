class_name VictoryScreen
extends Control
## Persona-style results screen.

var _lines: Array = []
var _k: float = 0.0:
	set(v):
		_k = v
		queue_redraw()


func _init(lines: Array = []) -> void:
	_lines = lines
	mouse_filter = Control.MOUSE_FILTER_STOP


func run() -> void:
	var big := UIKit.label("MENANG!", 150, UIKit.BONE, UIKit.head_font())
	UIKit.shadow(big, Vector2(10, 10), UIKit.BLACK)
	big.position = Vector2(-700, 70)
	big.rotation = deg_to_rad(-8.0)
	add_child(big)
	var t := create_tween()
	t.tween_property(self, "_k", 1.0, 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(big, "position:x", 90.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished
	var y := 330.0
	for line in _lines:
		var l := UIKit.label(str(line), 34, UIKit.BONE, UIKit.head_font())
		UIKit.outline(l, 8, UIKit.BLACK)
		l.position = Vector2(1300, y)
		l.rotation = deg_to_rad(-4.0)
		add_child(l)
		var tl := create_tween()
		tl.tween_property(l, "position:x", 160.0 + (y - 330.0) * 0.2, 0.25).set_trans(Tween.TRANS_BACK) \
			.set_ease(Tween.EASE_OUT)
		Audio.sfx("ui_move", -4.0)
		await tl.finished
		y += 56.0
	var hint := UIKit.label("ENTER · LANJUTKAN", 24, UIKit.GOLD, UIKit.head_font())
	hint.position = Vector2(1000, 650)
	add_child(hint)
	var waited := 0.0
	while true:
		await get_tree().process_frame
		waited += get_process_delta_time()
		if Settings.autotest and waited > 0.4:
			break
		if waited > 0.4 and Input.is_action_just_pressed("accept"):
			break
	Audio.sfx("ui_confirm")


func _draw() -> void:
	if _k <= 0.001:
		return
	draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.45 * _k))
	var w := 1500.0 * _k
	draw_colored_polygon(PackedVector2Array([Vector2(-100, 80), Vector2(-100 + w, -40), Vector2(-100 + w, 300),
		Vector2(-100, 420)]), UIKit.RED)
	draw_colored_polygon(PackedVector2Array([Vector2(-100, 420), Vector2(-100 + w, 300), Vector2(-100 + w, 316),
		Vector2(-100, 436)]), UIKit.BONE)
