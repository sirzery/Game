class_name QTEMash
extends Control
## Button-mash quick time event: press "accept" repeatedly to fill the meter.

var _prompt: String
var _presses: int
var _limit: float
var _count: int = 0
var _time: float = 0.0
var _done: bool = false
var _success: bool = false
var _pulse: float = 0.0
var _label: Label
var _key: Label


func _init(prompt: String = "HANTAM!", presses: int = 10, time_limit: float = 6.0) -> void:
	_prompt = prompt
	_presses = maxi(1, presses)
	_limit = time_limit
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_label = UIKit.label(_prompt, 110, UIKit.BONE, UIKit.head_font(), HORIZONTAL_ALIGNMENT_CENTER)
	UIKit.outline(_label, 16, UIKit.BLACK)
	_label.size = Vector2(1280, 150)
	_label.position = Vector2(0, 150)
	_label.pivot_offset = Vector2(640, 75)
	_label.rotation = deg_to_rad(-5.0)
	add_child(_label)
	_key = UIKit.label("TEKAN [ENTER / SPASI / Z] BERULANG KALI!", 26, UIKit.BONE, UIKit.head_font(),
		HORIZONTAL_ALIGNMENT_CENTER)
	UIKit.outline(_key, 8, UIKit.BLACK)
	_key.size = Vector2(1280, 40)
	_key.position = Vector2(0, 470)
	add_child(_key)


func run() -> bool:
	_count = 0
	_time = 0.0
	_done = false
	while not _done:
		await get_tree().process_frame
		var dt := get_process_delta_time() / maxf(Engine.time_scale, 0.001)
		_time += dt
		_pulse = maxf(0.0, _pulse - dt * 4.0)
		var pressed := Input.is_action_just_pressed("accept")
		if Settings.autotest and fmod(_time, 0.12) < dt:
			pressed = true
		if pressed:
			_count += 1
			_pulse = 1.0
			Audio.sfx("hit_blunt", -6.0, 1.0 + float(_count) * 0.04)
			if _label:
				_label.scale = Vector2(1.12, 1.12)
		if _label:
			_label.scale = _label.scale.lerp(Vector2.ONE, minf(1.0, dt * 10.0))
		if _count >= _presses:
			_done = true
			_success = true
		elif _time >= _limit:
			_done = true
			_success = false
		queue_redraw()
	return _success


func _draw() -> void:
	var w := 760.0
	var x0 := (1280.0 - w) * 0.5
	var y0 := 400.0
	var fill := clampf(float(_count) / float(_presses), 0.0, 1.0)
	var time_left := clampf(1.0 - _time / maxf(_limit, 0.01), 0.0, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(x0 + 20, y0), Vector2(x0 + w + 20, y0),
		Vector2(x0 + w, y0 + 50), Vector2(x0, y0 + 50)]), UIKit.BLACK)
	var fw := (w - 16) * fill
	if fw > 0.0:
		draw_colored_polygon(PackedVector2Array([Vector2(x0 + 26, y0 + 8), Vector2(x0 + 26 + fw, y0 + 8),
			Vector2(x0 + 10 + fw, y0 + 42), Vector2(x0 + 10, y0 + 42)]),
			UIKit.RED.lerp(UIKit.BONE, _pulse * 0.6))
	draw_rect(Rect2(x0, y0 + 58, w * time_left, 6), UIKit.GOLD)
