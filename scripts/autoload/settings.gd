extends Node
## Player settings (volume, text speed, display) and the input map.
##
## Input actions are registered at runtime so the project works even if the
## input map in project.godot is edited or reset.

signal changed

const PATH := "user://settings.cfg"

var master_volume: float = 0.9
var music_volume: float = 0.75
var sfx_volume: float = 0.85
var text_speed: float = 48.0  # characters per second
var screen_shake: bool = true
var fullscreen: bool = false

## Set by the automated play-test (`-- --autotest`). Speeds everything up and
## lets scripts make choices automatically.
var autotest: bool = false
var autotest_shots_dir: String = ""
var autotest_title_visits: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_inputs()
	load_settings()
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a == "--autotest":
			autotest = true
		elif a.begins_with("--shots="):
			autotest_shots_dir = a.trim_prefix("--shots=")
	apply()


func apply() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	changed.emit()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	master_volume = float(cfg.get_value("audio", "master", master_volume))
	music_volume = float(cfg.get_value("audio", "music", music_volume))
	sfx_volume = float(cfg.get_value("audio", "sfx", sfx_volume))
	text_speed = float(cfg.get_value("game", "text_speed", text_speed))
	screen_shake = bool(cfg.get_value("game", "screen_shake", screen_shake))
	fullscreen = bool(cfg.get_value("display", "fullscreen", fullscreen))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("game", "text_speed", text_speed)
	cfg.set_value("game", "screen_shake", screen_shake)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.save(PATH)


# ---------------------------------------------------------------------------
# Input map
# ---------------------------------------------------------------------------
func _register_inputs() -> void:
	_action("move_up", [KEY_UP, KEY_W], [JOY_BUTTON_DPAD_UP], [[JOY_AXIS_LEFT_Y, -1.0]])
	_action("move_down", [KEY_DOWN, KEY_S], [JOY_BUTTON_DPAD_DOWN], [[JOY_AXIS_LEFT_Y, 1.0]])
	_action("move_left", [KEY_LEFT, KEY_A], [JOY_BUTTON_DPAD_LEFT], [[JOY_AXIS_LEFT_X, -1.0]])
	_action("move_right", [KEY_RIGHT, KEY_D], [JOY_BUTTON_DPAD_RIGHT], [[JOY_AXIS_LEFT_X, 1.0]])
	_action("accept", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_Z, KEY_E], [JOY_BUTTON_A], [])
	_action("cancel", [KEY_ESCAPE, KEY_BACKSPACE, KEY_X], [JOY_BUTTON_B], [])
	_action("pause", [KEY_ESCAPE, KEY_TAB], [JOY_BUTTON_START], [])
	_action("skip", [KEY_CTRL], [JOY_BUTTON_Y], [])
	_action("run", [KEY_SHIFT], [JOY_BUTTON_X], [])


func _action(action: String, keys: Array, buttons: Array, axes: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.35)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
	for b in buttons:
		var jb := InputEventJoypadButton.new()
		jb.button_index = b
		InputMap.action_add_event(action, jb)
	for a in axes:
		var jm := InputEventJoypadMotion.new()
		jm.axis = a[0]
		jm.axis_value = a[1]
		InputMap.action_add_event(action, jm)
