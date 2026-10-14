class_name PauseMenu
extends CanvasLayer
## In-game pause menu (exploration).

var _root: Control


func _init() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS


func run() -> void:
	get_tree().paused = true
	Audio.sfx("ui_open", -4.0)
	_root = UIKit.full_rect(Control.new())
	add_child(_root)
	var bg := PauseBackdrop.new()
	UIKit.full_rect(bg)
	_root.add_child(bg)
	var title := UIKit.label("JEDA", 96, UIKit.BONE, UIKit.head_font())
	UIKit.shadow(title, Vector2(8, 8), UIKit.RED)
	title.position = Vector2(80, 50)
	title.rotation = deg_to_rad(-6.0)
	_root.add_child(title)
	while true:
		var menu := PersonaMenu.new(["LANJUTKAN", "STATUS", "PENGATURAN", "KE LAYAR JUDUL"])
		menu.allow_cancel = true
		menu.origin = Vector2(110, 230)
		_root.add_child(menu)
		var pick: int = await menu.run()
		menu.queue_free()
		if pick == 1:
			var sp := StatusPanel.new()
			_root.add_child(sp)
			await sp.run()
			sp.queue_free()
			continue
		if pick == 2:
			var st := SettingsPanel.new()
			_root.add_child(st)
			await st.run()
			st.queue_free()
			continue
		if pick == 3:
			get_tree().paused = false
			queue_free()
			Router.goto("res://scenes/ui/title.tscn")
			return
		break
	get_tree().paused = false
	queue_free()
