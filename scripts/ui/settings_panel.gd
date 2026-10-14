class_name SettingsPanel
extends Control
## Persona-style settings screen. await run() until the player leaves it.

const ROWS := [
	["master", "VOLUME UTAMA"],
	["music", "MUSIK"],
	["sfx", "EFEK SUARA"],
	["text", "KECEPATAN TEKS"],
	["shake", "GETARAN LAYAR"],
	["full", "LAYAR PENUH"],
	["back", "KEMBALI"],
]

var _index: int = 0
var _labels: Array[Label] = []
var _values: Array[Label] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	UIKit.full_rect(self)


func _ready() -> void:
	var title := UIKit.label("PENGATURAN", 72, UIKit.BONE, UIKit.head_font())
	UIKit.shadow(title, Vector2(6, 6), UIKit.RED)
	title.position = Vector2(110, 54)
	title.rotation = deg_to_rad(-4.0)
	add_child(title)
	for i in ROWS.size():
		var row: Array = ROWS[i]
		var l := UIKit.label(str(row[1]), 34, UIKit.BONE, UIKit.head_font())
		l.position = _row_pos(i) + Vector2(36, 6)
		add_child(l)
		_labels.append(l)
		var v := UIKit.label("", 30, UIKit.GOLD, UIKit.head_font())
		v.position = _row_pos(i) + Vector2(560, 8)
		add_child(v)
		_values.append(v)
	var hint := UIKit.label("↑↓ PILIH   ←→ UBAH   ESC KEMBALI", 22, Color(1, 1, 1, 0.6), UIKit.body_font(700))
	hint.position = Vector2(110, 660)
	add_child(hint)
	_refresh()


func _row_pos(i: int) -> Vector2:
	return Vector2(150.0 + float(i) * 10.0, 170.0 + float(i) * 66.0)


func run() -> void:
	var waited := 0.0
	while true:
		await get_tree().process_frame
		waited += get_process_delta_time()
		if Settings.autotest and waited > 0.3:
			break
		if Input.is_action_just_pressed("move_down"):
			_index = (_index + 1) % ROWS.size()
			Audio.sfx("ui_move", -8.0)
		elif Input.is_action_just_pressed("move_up"):
			_index = (_index - 1 + ROWS.size()) % ROWS.size()
			Audio.sfx("ui_move", -8.0)
		elif Input.is_action_just_pressed("move_left"):
			_change(-1)
		elif Input.is_action_just_pressed("move_right"):
			_change(1)
		elif Input.is_action_just_pressed("accept") and waited > 0.1:
			if ROWS[_index][0] == "back":
				break
			_change(1)
		elif Input.is_action_just_pressed("cancel") and waited > 0.1:
			break
		_refresh()
	Audio.sfx("ui_cancel", -6.0)
	Settings.save_settings()


func _change(dir: int) -> void:
	var key: String = ROWS[_index][0]
	match key:
		"master":
			Settings.master_volume = clampf(Settings.master_volume + 0.1 * dir, 0.0, 1.0)
		"music":
			Settings.music_volume = clampf(Settings.music_volume + 0.1 * dir, 0.0, 1.0)
		"sfx":
			Settings.sfx_volume = clampf(Settings.sfx_volume + 0.1 * dir, 0.0, 1.0)
		"text":
			Settings.text_speed = clampf(Settings.text_speed + 12.0 * dir, 12.0, 120.0)
		"shake":
			Settings.screen_shake = not Settings.screen_shake
		"full":
			Settings.fullscreen = not Settings.fullscreen
		_:
			return
	Settings.apply()
	Audio.sfx("ui_move", -6.0)


func _refresh() -> void:
	for i in ROWS.size():
		var key: String = ROWS[i][0]
		var txt := ""
		match key:
			"master":
				txt = _bar(Settings.master_volume)
			"music":
				txt = _bar(Settings.music_volume)
			"sfx":
				txt = _bar(Settings.sfx_volume)
			"text":
				txt = _bar((Settings.text_speed - 12.0) / 108.0)
			"shake":
				txt = "AKTIF" if Settings.screen_shake else "MATI"
			"full":
				txt = "YA" if Settings.fullscreen else "TIDAK"
		_values[i].text = txt
		_labels[i].add_theme_color_override("font_color", UIKit.BONE if i == _index else Color("9a929a"))
	queue_redraw()


static func _bar(v: float) -> String:
	return "%d%%" % int(round(clampf(v, 0.0, 1.0) * 100.0))


func _numeric(i: int) -> float:
	match str(ROWS[i][0]):
		"master":
			return Settings.master_volume
		"music":
			return Settings.music_volume
		"sfx":
			return Settings.sfx_volume
		"text":
			return (Settings.text_speed - 12.0) / 108.0
	return -1.0


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.02, 0.01, 0.02, 0.92))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 150), Vector2(1280, 120), Vector2(1280, 128),
		Vector2(0, 158)]), UIKit.RED)
	for i in ROWS.size():
		var p := _row_pos(i)
		var sel := i == _index
		var w := 900.0
		if sel:
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, 6), p + Vector2(w, 0), p + Vector2(w - 14, 56),
				p + Vector2(-14, 60)]), UIKit.RED)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-40, 18), p + Vector2(-10, 30), p + Vector2(-40, 42)]),
				UIKit.BONE)
		else:
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, 6), p + Vector2(w, 0), p + Vector2(w - 14, 56),
				p + Vector2(-14, 60)]), Color(0, 0, 0, 0.6))
		var v := _numeric(i)
		if v >= 0.0:
			var filled := int(round(clampf(v, 0.0, 1.0) * 10.0))
			for k in 10:
				var bx := p + Vector2(360.0 + float(k) * 18.0, 16.0)
				var c := UIKit.BONE if k < filled else Color(1, 1, 1, 0.18)
				draw_colored_polygon(PackedVector2Array([bx + Vector2(4, 0), bx + Vector2(14, 0), bx + Vector2(10, 26),
					bx + Vector2(0, 26)]), c)
