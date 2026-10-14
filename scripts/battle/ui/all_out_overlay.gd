class_name AllOutOverlay
extends Control
## The "HABISI!" finisher cut-in (in the spirit of Persona's All-Out Attack).

var _portrait: Texture2D
var _k: float = 0.0:
	set(v):
		_k = v
		queue_redraw()
var _flash: float = 0.0:
	set(v):
		_flash = v
		queue_redraw()
var _slashes: Array = []


func _init(portrait: Texture2D = null) -> void:
	_portrait = portrait
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func run() -> void:
	Audio.sfx("allout", 0.0)
	var t := create_tween()
	t.tween_property(self, "_k", 1.0, 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await t.finished
	var pr := TextureRect.new()
	pr.texture = _portrait
	pr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pr.size = Vector2(480, 480)
	pr.position = Vector2(1300, 130)
	add_child(pr)
	var word := UIKit.label("HABISI!", 170, UIKit.BONE, UIKit.head_font())
	UIKit.outline(word, 16, UIKit.BLACK)
	word.position = Vector2(-900, 220)
	word.rotation = deg_to_rad(-10.0)
	add_child(word)
	var t2 := create_tween().set_parallel(true)
	t2.tween_property(pr, "position:x", 720.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t2.tween_property(word, "position:x", 80.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t2.finished
	for i in 7:
		_slashes.append([Vector2(randf_range(0, 1280), randf_range(0, 720)), randf_range(-PI, PI)])
		Audio.sfx("hit_blunt" if i % 2 == 0 else "hit_pierce", -2.0, randf_range(0.9, 1.3))
		_flash = 1.0
		var tf := create_tween()
		tf.tween_property(self, "_flash", 0.0, 0.1)
		await tf.finished
	Audio.sfx("crit", 0.0)
	_flash = 1.0
	var t3 := create_tween()
	t3.tween_property(self, "_flash", 0.0, 0.4)
	t3.parallel().tween_property(self, "modulate:a", 0.0, 0.45)
	await t3.finished


func _draw() -> void:
	if _k <= 0.001:
		return
	draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.75 * _k))
	var ax: float = -900.0 + 1100.0 * _k
	draw_colored_polygon(PackedVector2Array([Vector2(ax, 720), Vector2(ax + 420.0, -100), Vector2(ax + 820.0, -100),
		Vector2(ax + 400.0, 720)]), UIKit.RED)
	for s in _slashes:
		var p: Vector2 = s[0]
		var a: float = s[1]
		var d := Vector2(cos(a), sin(a)) * 420.0
		draw_line(p - d, p + d, UIKit.BONE, 10.0)
		draw_line(p - d, p + d, UIKit.BLACK, 3.0)
	if _flash > 0.0:
		draw_rect(Rect2(0, 0, 1280, 720), Color(1, 1, 1, _flash * 0.8))
