class_name DefeatScreen
extends Control
## Game-over screen with a retry option.


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func run() -> int:
	modulate.a = 0.0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.8)
	var big := UIKit.label("KAU TUMBANG", 110, UIKit.RED, UIKit.head_font())
	UIKit.outline(big, 10, UIKit.BLACK)
	big.position = Vector2(110, 140)
	big.rotation = deg_to_rad(-6.0)
	add_child(big)
	var sub := UIKit.label("Catatan kaki terakhir sang cendekia berakhir di sini... atau tidak?", 26,
		UIKit.BONE, UIKit.title_font(600))
	sub.position = Vector2(140, 290)
	sub.rotation = deg_to_rad(-6.0)
	add_child(sub)
	await t.finished
	var menu := PersonaMenu.new(["COBA LAGI", "KEMBALI KE JUDUL"])
	menu.origin = Vector2(160, 420)
	menu.font_size = 48
	add_child(menu)
	var pick: int = await menu.run()
	return maxi(pick, 0)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.04, 0.0, 0.02, 0.88))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 360), Vector2(1280, 250), Vector2(1280, 262),
		Vector2(0, 372)]), UIKit.RED)
