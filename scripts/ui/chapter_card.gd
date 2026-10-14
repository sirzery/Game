class_name ChapterCard
extends Control
## Full-screen chapter title card: crimson slash, big headline and subtitle.

var _top: String
var _title: String
var _sub: String
var _slash: float = 0.0:
	set(v):
		_slash = v
		queue_redraw()


func _init(top: String = "", title: String = "", sub: String = "") -> void:
	_top = top
	_title = title
	_sub = sub
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func play(hold: float) -> void:
	modulate.a = 0.0
	var top_l := UIKit.label(_top, 30, UIKit.RED, UIKit.head_font(), HORIZONTAL_ALIGNMENT_CENTER)
	top_l.position = Vector2(0, 230)
	top_l.size = Vector2(1280, 40)
	add_child(top_l)
	var title_l := UIKit.label(_title, 92, UIKit.BONE, UIKit.title_font(800), HORIZONTAL_ALIGNMENT_CENTER)
	UIKit.shadow(title_l, Vector2(6, 6), UIKit.RED_DARK)
	title_l.position = Vector2(0, 270)
	title_l.size = Vector2(1280, 120)
	add_child(title_l)
	var sub_l := UIKit.label(_sub, 28, UIKit.GOLD, UIKit.title_font(600), HORIZONTAL_ALIGNMENT_CENTER)
	sub_l.position = Vector2(0, 410)
	sub_l.size = Vector2(1280, 40)
	add_child(sub_l)
	Audio.sfx("gavel", -4.0)
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.5)
	t.parallel().tween_property(self, "_slash", 1.0, 0.45).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await t.finished
	var elapsed := 0.0
	while elapsed < hold:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		if Input.is_action_just_pressed("accept"):
			break
	var t2 := create_tween()
	t2.tween_property(self, "modulate:a", 0.0, 0.6)
	await t2.finished


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.92))
	if _slash <= 0.001:
		return
	var w := 1400.0 * _slash
	draw_colored_polygon(PackedVector2Array([Vector2(-60, 470), Vector2(-60 + w, 300), Vector2(-60 + w, 326),
		Vector2(-60, 496)]), UIKit.RED)
	draw_colored_polygon(PackedVector2Array([Vector2(1340, 210), Vector2(1340 - w * 0.7, 260),
		Vector2(1340 - w * 0.7, 268), Vector2(1340, 218)]), UIKit.BONE)
