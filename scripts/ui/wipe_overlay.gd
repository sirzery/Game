class_name WipeOverlay
extends Control
## Persona-style transition: slanted black and crimson shards sweep across
## the screen. play(true) covers the screen, play(false) reveals it again.

const BANDS := 9

var progress: float = 0.0:
	set(v):
		progress = v
		queue_redraw()
var covering: bool = true


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func play(cover: bool, dur: float = 0.45) -> void:
	covering = cover
	progress = 0.0
	visible = true
	var t := create_tween()
	t.tween_property(self, "progress", 1.0, maxf(dur, 0.01)).set_trans(Tween.TRANS_CUBIC).set_ease(
		Tween.EASE_IN_OUT if cover else Tween.EASE_OUT)
	await t.finished
	if not cover:
		visible = false
		progress = 0.0


func _draw() -> void:
	if progress <= 0.0 and covering:
		return
	var sz := size
	if sz.x <= 1.0:
		sz = get_viewport_rect().size
	var skew := sz.y * 0.35
	var spacing := (sz.x + skew) / float(BANDS)
	var band_w := spacing * 1.25
	for i in BANDS:
		var local := clampf(progress * 1.7 - float(i) * 0.07, 0.0, 1.0)
		if covering:
			if local <= 0.0:
				continue
		elif local >= 1.0:
			continue
		var x0 := float(i) * spacing - skew - 4.0
		var w := band_w + 8.0
		var a := x0
		var b := x0 + w
		if covering:
			b = x0 + w * local
		else:
			a = x0 + w * local
		if b - a < 0.5:
			continue
		var pts := PackedVector2Array([
			Vector2(a + skew, 0), Vector2(b + skew, 0), Vector2(b, sz.y), Vector2(a, sz.y)
		])
		var col := UIKit.BLACK if i % 3 != 1 else UIKit.RED
		draw_colored_polygon(pts, col)
		# thin bone-white edge on the leading side for the comic-book feel
		if covering and local < 1.0:
			draw_line(Vector2(b + skew, 0), Vector2(b, sz.y), UIKit.BONE, 3.0)
	if covering and progress >= 1.0:
		draw_rect(Rect2(Vector2.ZERO, sz), UIKit.BLACK)
