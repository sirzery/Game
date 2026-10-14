extends Node
## Scene changes with Persona-style diagonal wipes, plus global fades and
## screenshot capture for the automated play-test.

signal scene_changed(path: String)

var busy: bool = false
var current_path: String = ""

var _layer: CanvasLayer
var _wipe: WipeOverlay
var _fade: ColorRect
var _shot_index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 120
	add_child(_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(_fade)
	_layer.add_child(_fade)
	_wipe = WipeOverlay.new()
	UIKit.full_rect(_wipe)
	_layer.add_child(_wipe)
	var scene := get_tree().current_scene
	if scene != null:
		current_path = scene.scene_file_path


func _exit_tree() -> void:
	# release static caches before the engine checks for leaked resources
	UIKit.clear_caches()
	FX.clear_caches()
	Actor.clear_caches()


func goto(path: String, style: String = "persona") -> void:
	if busy:
		return
	if Settings.autotest and OS.get_cmdline_user_args().has("--single"):
		# test a single scene: stop when it tries to leave
		print("[autotest] scene finished, next would be ", path)
		get_tree().quit()
		return
	busy = true
	if style == "persona":
		Audio.sfx("ui_open", -6.0)
		await _wipe.play(true, 0.42)
	else:
		await fade_out(0.6)
	Engine.time_scale = 1.0
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Gagal memuat scene %s (%s)" % [path, error_string(err)])
	current_path = path
	await get_tree().process_frame
	await get_tree().process_frame
	scene_changed.emit(path)
	if style == "persona":
		await _wipe.play(false, 0.42)
	else:
		_fade.color.a = 1.0
		await fade_in(0.6)
	busy = false


func fade_out(dur: float = 0.8, color: Color = Color.BLACK) -> void:
	var c := color
	c.a = _fade.color.a
	_fade.color = c
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, maxf(dur, 0.01))
	await t.finished


func fade_in(dur: float = 0.8) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", 0.0, maxf(dur, 0.01))
	await t.finished


func is_faded() -> bool:
	return _fade.color.a > 0.5


func snap(label: String) -> void:
	## Saves a screenshot when running the automated play-test with --shots=DIR.
	if Settings.autotest_shots_dir == "":
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img == null:
		return
	DirAccess.make_dir_recursive_absolute(Settings.autotest_shots_dir)
	_shot_index += 1
	var path := "%s/%02d_%s.png" % [Settings.autotest_shots_dir, _shot_index, label]
	img.save_png(path)
	print("[autotest] screenshot ", path)
