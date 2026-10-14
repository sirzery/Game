class_name CineOverlay
extends CanvasLayer
## Cinematic presentation layer: letterbox bars, Persona-style location
## plates, narration cards, chapter cards, objective pop-ups and the
## button-mash QTE used in the prologue.

var top_bar: ColorRect
var bottom_bar: ColorRect
var black: ColorRect
var root: Control
var skip_hint: Label
var _bars_tween: Tween


func _init() -> void:
	layer = 70


func _ready() -> void:
	root = UIKit.full_rect(Control.new())
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	black = ColorRect.new()
	black.color = Color(0, 0, 0, 0)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(black)
	root.add_child(black)
	top_bar = _bar()
	bottom_bar = _bar()
	_place_bars(0.0)
	skip_hint = UIKit.label("TAHAN CTRL · PERCEPAT", 16, Color(1, 1, 1, 0.5), UIKit.head_font())
	skip_hint.position = Vector2(1060, 8)
	skip_hint.visible = false
	root.add_child(skip_hint)


func _bar() -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.0, 0.0, 0.0, 1.0)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(r)
	return r


func _place_bars(h: float) -> void:
	top_bar.position = Vector2(0, 0)
	top_bar.size = Vector2(1280, h)
	bottom_bar.position = Vector2(0, 720 - h)
	bottom_bar.size = Vector2(1280, h)


var _bar_h: float = 0.0
var bar_height: float:
	get:
		return _bar_h
	set(v):
		_bar_h = v
		_place_bars(v)


func letterbox(on: bool, dur: float = 0.6) -> void:
	if _bars_tween:
		_bars_tween.kill()
	_bars_tween = create_tween()
	_bars_tween.tween_property(self, "bar_height", 72.0 if on else 0.0, maxf(dur, 0.01)) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	skip_hint.visible = on
	await _bars_tween.finished


func set_black(alpha: float) -> void:
	black.color.a = alpha


func fade_black(to: float, dur: float = 0.8) -> void:
	var t := create_tween()
	t.tween_property(black, "color:a", to, maxf(dur, 0.01))
	await t.finished


# ---------------------------------------------------------------------------
# Persona-style location plate (top-left)
# ---------------------------------------------------------------------------
func location(place: String, when: String, hold: float = 3.0) -> void:
	var plate := LocationPlate.new(place, when)
	root.add_child(plate)
	plate.position = Vector2(-520, 92)
	Audio.sfx("ui_open", -8.0)
	var t := create_tween()
	t.tween_property(plate, "position:x", 0.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(hold)
	t.tween_property(plate, "position:x", -560.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_callback(plate.queue_free)


# ---------------------------------------------------------------------------
# Narration on black (prologue text)
# ---------------------------------------------------------------------------
func narration(lines: Array, hold: float = 2.6, keep_black: bool = false) -> void:
	await fade_black(1.0, 0.6)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	UIKit.full_rect(box)
	box.add_theme_constant_override("separation", 22)
	root.add_child(box)
	for line in lines:
		var l := UIKit.label(GameState.fmt(str(line)), 34, UIKit.BONE, UIKit.title_font(600),
			HORIZONTAL_ALIGNMENT_CENTER)
		l.modulate.a = 0.0
		box.add_child(l)
		var t := create_tween()
		t.tween_property(l, "modulate:a", 1.0, 1.1)
		await t.finished
		await _hold(hold)
	var tout := create_tween()
	tout.tween_property(box, "modulate:a", 0.0, 0.9)
	await tout.finished
	box.queue_free()
	if not keep_black:
		await fade_black(0.0, 0.9)


func _hold(sec: float) -> void:
	## Waits, but the player may cut the wait short with "accept".
	var elapsed := 0.0
	while elapsed < sec:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		if Input.is_action_just_pressed("accept"):
			break


# ---------------------------------------------------------------------------
# Big chapter / title cards
# ---------------------------------------------------------------------------
func chapter_card(top: String, title: String, sub: String = "", hold: float = 3.0) -> void:
	var card := ChapterCard.new(top, title, sub)
	UIKit.full_rect(card)
	root.add_child(card)
	await card.play(hold)
	card.queue_free()


func banner(text: String, color: Color = UIKit.RED, hold: float = 1.2, size_px: int = 96) -> void:
	## Slanted comic-book banner across the middle of the screen ("BREAK!", "HANTAM!").
	var b := SlashBanner.new(text, color, size_px)
	UIKit.full_rect(b)
	root.add_child(b)
	await b.play(hold)
	b.queue_free()


# ---------------------------------------------------------------------------
# QTE: mash the accept button to fill the meter before time runs out.
# ---------------------------------------------------------------------------
func qte_mash(prompt: String, presses: int = 10, time_limit: float = 6.0) -> bool:
	var q := QTEMash.new(prompt, presses, time_limit)
	UIKit.full_rect(q)
	root.add_child(q)
	var ok: bool = await q.run()
	q.queue_free()
	return ok


# ---------------------------------------------------------------------------
# Small toast in the bottom-right corner ("Didapat: Dahan Kering")
# ---------------------------------------------------------------------------
func toast(text: String, color: Color = UIKit.GOLD) -> void:
	var panel := PanelToast.new(text, color)
	root.add_child(panel)
	panel.position = Vector2(1300, 600)
	var t := create_tween()
	t.tween_property(panel, "position:x", 1280.0 - panel.get_width(), 0.25).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	t.tween_interval(1.8)
	t.tween_property(panel, "modulate:a", 0.0, 0.4)
	t.tween_callback(panel.queue_free)
