class_name TutorialCard
extends Control
## Modal tutorial card ("PANDUAN").

var _title: String
var _body: String


func _init(title: String = "", body: String = "") -> void:
	_title = title
	_body = body
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	var t := UIKit.label("PANDUAN", 24, UIKit.BLACK, UIKit.head_font())
	t.position = Vector2(300, 196)
	t.rotation = deg_to_rad(-3.0)
	add_child(t)
	var h := UIKit.label(_title, 48, UIKit.BONE, UIKit.head_font())
	UIKit.shadow(h, Vector2(4, 4), UIKit.RED)
	h.position = Vector2(300, 236)
	h.rotation = deg_to_rad(-3.0)
	add_child(h)
	var b := RichTextLabel.new()
	b.bbcode_enabled = true
	b.fit_content = true
	b.scroll_active = false
	b.position = Vector2(304, 318)
	b.size = Vector2(680, 200)
	b.add_theme_font_override("normal_font", UIKit.body_font(500))
	b.add_theme_font_override("bold_font", UIKit.body_font(800))
	b.add_theme_font_size_override("normal_font_size", 24)
	b.add_theme_font_size_override("bold_font_size", 24)
	b.add_theme_color_override("default_color", UIKit.BONE)
	b.text = _body
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(b)
	var k := UIKit.label("ENTER · LANJUT", 22, UIKit.GOLD, UIKit.head_font())
	k.position = Vector2(820, 520)
	add_child(k)
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.18)
	Audio.sfx("ui_open", -6.0)


func run() -> void:
	var waited := 0.0
	while true:
		await get_tree().process_frame
		waited += get_process_delta_time()
		if Settings.autotest and waited > 0.3:
			break
		if waited > 0.3 and Input.is_action_just_pressed("accept"):
			break
	Audio.sfx("ui_confirm", -4.0)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.55))
	draw_colored_polygon(PackedVector2Array([Vector2(270, 200), Vector2(1020, 170), Vector2(1000, 570),
		Vector2(250, 590)]), UIKit.BONE)
	draw_colored_polygon(PackedVector2Array([Vector2(280, 210), Vector2(1008, 182), Vector2(990, 560),
		Vector2(262, 578)]), UIKit.BLACK)
	draw_colored_polygon(PackedVector2Array([Vector2(290, 196), Vector2(430, 190), Vector2(426, 226),
		Vector2(286, 232)]), UIKit.GOLD)
