class_name Actor
extends Node2D
## A character in the world: pixel sprite sheet with a normal map (so 2D
## lights shade it like an HD-2D sprite), a soft ground shadow, walk cycles
## and small cinematic helpers.
##
## Walk sheets are 3x3 frames of 32x48: rows = down, side (facing right), up;
## columns = idle, step A, step B.

const CHAR_DIR := "res://assets/sprites/characters/"
const FRAME_SIZE := Vector2i(32, 48)
const WALK_SEQ := [1, 0, 2, 0]

static var _shadow_tex: GradientTexture2D

var sprite: Sprite2D
var shadow: Sprite2D
var sheet_id: String = ""
var facing: String = "down"
var walking: bool = false
var walk_fps: float = 8.0
var posed: bool = false

var pose_seq: Array = []
var pose_fps: float = 6.0
var _walk_tex: Texture2D
var _anim_t: float = 0.0
var _shake_t: float = 0.0
var _shake_amp: float = 0.0
var _base_offset: Vector2 = Vector2(0, -21)


func _init(id: String = "") -> void:
	sheet_id = id


func _ready() -> void:
	shadow = Sprite2D.new()
	shadow.texture = _get_shadow_tex()
	shadow.scale = Vector2(0.28, 0.09)
	shadow.modulate = Color(0, 0, 0, 0.45)
	shadow.position = Vector2(0, 1)
	add_child(shadow)
	sprite = Sprite2D.new()
	sprite.offset = _base_offset
	add_child(sprite)
	if sheet_id != "":
		set_sheet(sheet_id)


static func clear_caches() -> void:
	_shadow_tex = null


static func _get_shadow_tex() -> GradientTexture2D:
	if _shadow_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		_shadow_tex = GradientTexture2D.new()
		_shadow_tex.gradient = g
		_shadow_tex.fill = GradientTexture2D.FILL_RADIAL
		_shadow_tex.fill_from = Vector2(0.5, 0.5)
		_shadow_tex.fill_to = Vector2(1.0, 0.5)
		_shadow_tex.width = 128
		_shadow_tex.height = 128
	return _shadow_tex


func set_sheet(id: String) -> void:
	sheet_id = id
	_walk_tex = UIKit.lit_tex(CHAR_DIR + id + "_walk.png")
	clear_pose()


func clear_pose() -> void:
	posed = false
	pose_seq = []
	if sprite == null:
		return
	sprite.texture = _walk_tex
	sprite.hframes = 3
	sprite.vframes = 3
	sprite.offset = _base_offset
	_update_frame()


func pose(sheet: String, frame_index: int, hframes: int = 0, frame_size: Vector2i = FRAME_SIZE,
		feet_offset: float = -21.0) -> void:
	## Show a frame of another sheet, e.g. pose("mc_poses", 2).
	posed = true
	walking = false
	var tex := UIKit.lit_tex(CHAR_DIR + sheet + ".png")
	if tex == null:
		return
	sprite.texture = tex
	var cols := hframes if hframes > 0 else maxi(1, int(tex.get_width() / float(frame_size.x)))
	sprite.hframes = cols
	sprite.vframes = maxi(1, int(tex.get_height() / float(frame_size.y)))
	sprite.frame = clampi(frame_index, 0, cols * sprite.vframes - 1)
	sprite.offset = Vector2(0, feet_offset)


func pose_anim(sheet: String, seq: Array, fps: float = 6.0) -> void:
	## Loop a sequence of frames from a pose sheet (e.g. walking with a lantern).
	pose(sheet, int(seq[0]))
	pose_seq = seq
	pose_fps = fps
	_anim_t = 0.0


func face(dir: String) -> void:
	facing = dir
	_update_frame()


func face_towards(p: Vector2) -> void:
	var d := p - global_position
	if absf(d.x) > absf(d.y):
		face("right" if d.x > 0.0 else "left")
	else:
		face("down" if d.y > 0.0 else "up")


func _row() -> int:
	match facing:
		"up":
			return 2
		"left", "right":
			return 1
		_:
			return 0


func _update_frame() -> void:
	if sprite == null or posed or sprite.texture == null:
		return
	var col := 0
	if walking:
		col = WALK_SEQ[int(_anim_t * walk_fps) % WALK_SEQ.size()]
	sprite.frame = _row() * 3 + col
	sprite.flip_h = facing == "left"


func _process(delta: float) -> void:
	if walking:
		_anim_t += delta
		_update_frame()
	elif posed and pose_seq.size() > 1:
		_anim_t += delta
		sprite.frame = clampi(int(pose_seq[int(_anim_t * pose_fps) % pose_seq.size()]), 0,
			sprite.hframes * sprite.vframes - 1)
	if _shake_t > 0.0:
		_shake_t -= delta
		var k := _shake_amp * (_shake_t / 0.4)
		sprite.position = Vector2(randf_range(-k, k), randf_range(-k * 0.5, k * 0.5))
		if _shake_t <= 0.0:
			sprite.position = Vector2.ZERO


func set_walking(on: bool) -> void:
	if posed:
		return
	if on and not walking:
		_anim_t = 0.0
	walking = on
	_update_frame()


func move_to(target: Vector2, speed: float = 55.0, face_dir: bool = true) -> void:
	await StageCamera.wait_tween(walk_to(target, speed, face_dir))


func walk_to(target: Vector2, speed: float = 55.0, face_dir: bool = true) -> Tween:
	## Starts walking and returns the tween (does not wait).
	if posed:
		clear_pose()
	var dist := position.distance_to(target)
	if face_dir and dist > 0.5:
		var d := target - position
		if absf(d.x) > absf(d.y) * 0.8:
			face("right" if d.x > 0.0 else "left")
		else:
			face("down" if d.y > 0.0 else "up")
	set_walking(dist > 0.5)
	var t := create_tween()
	t.tween_property(self, "position", target, maxf(dist / maxf(speed, 1.0), 0.01))
	t.tween_callback(set_walking.bind(false))
	return t


func hop(height: float = 6.0, dur: float = 0.25) -> void:
	var t := create_tween()
	t.tween_property(sprite, "position:y", -height, dur * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(sprite, "position:y", 0.0, dur * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t.finished


func shake(amp: float = 2.0, dur: float = 0.4) -> void:
	_shake_amp = amp
	_shake_t = dur


func flash(color: Color = Color(3, 3, 3), dur: float = 0.25) -> void:
	sprite.modulate = color
	var t := create_tween()
	t.tween_property(sprite, "modulate", Color.WHITE, dur)


func fade(to_alpha: float, dur: float = 0.5) -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", to_alpha, maxf(dur, 0.01))
	await t.finished
