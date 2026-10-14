class_name Battler
extends Node2D
## A combatant on the battlefield (the Scholar or an enemy).

var id: String = ""
var display_name: String = ""
var short_name: String = ""
var is_player: bool = false

var hp: int = 1
var max_hp: int = 1
var sp: int = 0
var max_sp: int = 0
var atk: int = 10
var def: int = 5
var mag: int = 10
var spd: int = 10

var max_shield: int = 0
var shield: int = 0
var weak: Array = []
var revealed: Dictionary = {}  # element -> true
var observed: bool = false
var broken_turns: int = 0
var guarding: bool = false
var charging: Dictionary = {}  # telegraphed move waiting to fire
var atk_buff: float = 0.0
var buff_turns: int = 0
var bp: int = 1
var boosted_last: bool = false
var data: Dictionary = {}

var sprite: Sprite2D
var shadow: Sprite2D
var home: Vector2
var frames: Dictionary = {}
var _idle_t: float = 0.0
var _state: String = "idle"
var _shake: float = 0.0


func _ready() -> void:
	shadow = Sprite2D.new()
	shadow.texture = Actor._get_shadow_tex()
	shadow.modulate = Color(0, 0, 0, 0.5)
	add_child(shadow)
	sprite = Sprite2D.new()
	add_child(sprite)


func setup_player(stats: Dictionary, player_name: String) -> void:
	id = "mc"
	is_player = true
	display_name = player_name
	short_name = player_name.to_upper()
	max_hp = int(stats["max_hp"])
	hp = clampi(int(stats["hp"]), 1, max_hp)
	max_sp = int(stats["max_sp"])
	sp = clampi(int(stats["sp"]), 0, max_sp)
	atk = int(stats["atk"])
	def = int(stats["def"])
	mag = int(stats["mag"])
	spd = int(stats["spd"])
	bp = 1
	sprite.texture = UIKit.lit_tex("res://assets/sprites/characters/mc_battle.png")
	sprite.hframes = 7
	sprite.flip_h = true
	sprite.offset = Vector2(0, -21)
	frames = {"idle": [0, 1], "attack": 2, "hurt": 3, "cast": 4, "guard": 5, "down": 6}
	shadow.scale = Vector2(0.3, 0.09)
	_apply_frame()


func setup_enemy(enemy_id: String) -> void:
	data = BattleData.ENEMIES[enemy_id]
	id = enemy_id
	is_player = false
	display_name = str(data["name"])
	short_name = str(data["short"])
	max_hp = int(data["hp"])
	hp = max_hp
	atk = int(data["atk"])
	def = int(data["def"])
	mag = int(data["mag"])
	spd = int(data["spd"])
	max_shield = int(data["shield"])
	shield = max_shield
	weak = (data["weak"] as Array).duplicate()
	var fs: Vector2i = data["frame_size"]
	sprite.texture = UIKit.lit_tex("res://assets/sprites/characters/%s.png" % str(data["sheet"]))
	if sprite.texture:
		sprite.hframes = maxi(1, int(sprite.texture.get_width() / float(fs.x)))
	var sc := float(data.get("scale", 1.0))
	sprite.scale = Vector2(sc, sc)
	sprite.offset = Vector2(0, -fs.y * 0.5 + 2)
	frames = data["frames"]
	shadow.scale = Vector2(0.45 * sc, 0.12 * sc)
	_apply_frame()


func alive() -> bool:
	return hp > 0


func is_broken() -> bool:
	return broken_turns > 0


func effective_atk() -> float:
	return float(atk) * (1.0 + atk_buff)


func _process(delta: float) -> void:
	_idle_t += delta
	if _state == "idle":
		_apply_frame()
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta)
		sprite.position.x = randf_range(-2.0, 2.0) * (_shake / 0.35)
	elif _state == "idle":
		sprite.position.x = 0.0
	if is_broken() and alive():
		sprite.modulate = Color(0.75, 0.75, 0.9).lerp(Color.WHITE, 0.5 + 0.5 * sin(_idle_t * 6.0))
	elif sprite.modulate != Color.WHITE and _state == "idle" and alive():
		sprite.modulate = Color.WHITE


func set_state(s: String) -> void:
	_state = s
	_apply_frame()


func _apply_frame() -> void:
	if sprite == null or sprite.texture == null:
		return
	var f: Variant = frames.get(_state, frames.get("idle", 0))
	if typeof(f) == TYPE_ARRAY:
		var arr: Array = f
		var speed := 2.0 if not is_broken() else 0.8
		sprite.frame = clampi(int(arr[int(_idle_t * speed) % arr.size()]), 0, sprite.hframes - 1)
	else:
		sprite.frame = clampi(int(f), 0, sprite.hframes - 1)
	if guarding and is_player and _state == "idle":
		sprite.frame = int(frames.get("guard", 0))


# ---------------------------------------------------------------------------
# Animations
# ---------------------------------------------------------------------------
func lunge(to: Vector2) -> void:
	set_state("attack")
	var t := create_tween()
	t.tween_property(self, "position", position.lerp(to, 0.7), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t.finished


func return_home() -> void:
	var t := create_tween()
	t.tween_property(self, "position", home, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await t.finished
	set_state("idle")


func hurt() -> void:
	set_state("hurt")
	_shake = 0.35
	sprite.modulate = Color(3.0, 2.2, 2.2)
	var t := create_tween()
	t.tween_property(sprite, "modulate", Color.WHITE, 0.25)
	await get_tree().create_timer(0.35, false).timeout
	if alive():
		set_state("idle")


func cast() -> void:
	set_state("cast" if frames.has("cast") else "charge")
	await get_tree().create_timer(0.35, false).timeout


func die() -> void:
	set_state("hurt")
	var t := create_tween()
	t.tween_property(sprite, "modulate", Color(3.0, 0.6, 0.6, 1.0), 0.15)
	t.tween_property(sprite, "modulate", Color(1.0, 0.2, 0.3, 0.0), 0.7)
	t.parallel().tween_property(shadow, "modulate:a", 0.0, 0.7)
	await t.finished
	visible = false
