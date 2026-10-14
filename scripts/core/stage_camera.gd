class_name StageCamera
extends Camera2D
## Cinematic camera: smooth pans/zooms and trauma-based screen shake.

var trauma: float = 0.0
var shake_power: float = 6.0
var _noise_t: float = 0.0
var _base_offset: Vector2 = Vector2.ZERO


func _init() -> void:
	zoom = Vector2(3, 3)
	process_callback = Camera2D.CAMERA2D_PROCESS_IDLE


func _process(delta: float) -> void:
	_noise_t += delta * 30.0
	if trauma > 0.0:
		trauma = maxf(0.0, trauma - delta * 1.4)
		var amt := trauma * trauma * shake_power
		if not Settings.screen_shake:
			amt *= 0.2
		offset = _base_offset + Vector2(sin(_noise_t * 1.7) * amt, cos(_noise_t * 2.3) * amt)
	else:
		offset = _base_offset


func shake(amount: float = 0.6, power: float = 6.0) -> void:
	trauma = clampf(maxf(trauma, amount), 0.0, 1.0)
	shake_power = power


func pan_to(target: Vector2, dur: float = 1.0, trans: Tween.TransitionType = Tween.TRANS_SINE) -> void:
	await StageCamera.wait_tween(pan_tween(target, dur, trans))


func pan_tween(target: Vector2, dur: float = 1.0, trans: Tween.TransitionType = Tween.TRANS_SINE) -> Tween:
	var t := create_tween()
	t.tween_property(self, "position", target, maxf(dur, 0.01)).set_trans(trans).set_ease(Tween.EASE_IN_OUT)
	return t


func zoom_to(z: float, dur: float = 1.0) -> void:
	var t := create_tween()
	t.tween_property(self, "zoom", Vector2(z, z), maxf(dur, 0.01)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await StageCamera.wait_tween(t)


func pan_zoom(target: Vector2, z: float, dur: float = 1.0) -> void:
	await StageCamera.wait_tween(pan_zoom_tween(target, z, dur))


func pan_zoom_tween(target: Vector2, z: float, dur: float = 1.0) -> Tween:
	## Starts a pan+zoom without waiting; await StageCamera.wait_tween(t) later.
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "position", target, maxf(dur, 0.01)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, "zoom", Vector2(z, z), maxf(dur, 0.01)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return t


static func wait_tween(t: Tween) -> void:
	## Awaits a tween only if it is still running (awaiting a finished tween would hang).
	if t != null and t.is_valid() and t.is_running():
		await t.finished
