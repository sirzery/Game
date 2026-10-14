class_name EnemyPlate
extends Control
## Floating plate over an enemy: shield counter, weaknesses, HP (after AMATI),
## BREAK state and the observed intent.

var b: Battler
var _name: Label
var _shield: Label
var _intent: Label
var _t: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(260, 90)


func _ready() -> void:
	_name = UIKit.label("", 20, UIKit.BONE, UIKit.head_font())
	UIKit.outline(_name, 6, UIKit.BLACK)
	_name.position = Vector2(54, -26)
	add_child(_name)
	_shield = UIKit.label("", 26, UIKit.BONE, UIKit.head_font(), HORIZONTAL_ALIGNMENT_CENTER)
	UIKit.outline(_shield, 6, UIKit.BLACK)
	_shield.position = Vector2(0, 4)
	_shield.size = Vector2(48, 40)
	add_child(_shield)
	_intent = UIKit.label("", 18, UIKit.GOLD, UIKit.body_font(800))
	UIKit.outline(_intent, 5, UIKit.BLACK)
	_intent.position = Vector2(54, 58)
	add_child(_intent)


func bind(bat: Battler) -> void:
	b = bat


func refresh() -> void:
	if b == null or _name == null:
		return
	_name.text = b.display_name
	_shield.text = "" if b.is_broken() else str(b.shield)
	if b.observed and not b.charging.is_empty():
		_intent.text = "NIAT: " + str(b.charging.get("name", "")).to_upper()
	elif b.observed:
		_intent.text = ""
	else:
		_intent.text = ""
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if b != null and b.is_broken():
		queue_redraw()


func _draw() -> void:
	if b == null:
		return
	draw_colored_polygon(PackedVector2Array([Vector2(44, -26), Vector2(250, -30), Vector2(246, 52), Vector2(40, 56)]),
		Color(0, 0, 0, 0.6))
	var shield_tex := UIKit.tex("res://assets/sprites/ui/icon_broken.png" if b.is_broken() else
		"res://assets/sprites/ui/icon_shield.png")
	if shield_tex:
		draw_texture_rect(shield_tex, Rect2(Vector2(0, 0), Vector2(48, 48)), false)
	if b.is_broken():
		var k := 0.6 + 0.4 * sin(_t * 10.0)
		draw_string(UIKit.head_font(), Vector2(-6, 76), "BREAK", HORIZONTAL_ALIGNMENT_LEFT, -1, 26,
			Color(1.0, 0.3 * k, 0.3 * k))
	# weaknesses
	var x := 54.0
	for w in b.weak:
		var el := str(w)
		var path := BattleData.element_icon(el) if b.revealed.has(el) else "res://assets/sprites/ui/icon_unknown.png"
		var tex := UIKit.tex(path)
		draw_rect(Rect2(Vector2(x - 2, 4), Vector2(36, 36)), Color(0.1, 0.1, 0.12, 0.9))
		if tex:
			draw_texture_rect(tex, Rect2(Vector2(x, 6), Vector2(32, 32)), false)
		x += 40.0
	# HP bar (only once observed)
	if b.observed:
		var k2 := clampf(float(b.hp) / float(maxi(b.max_hp, 1)), 0.0, 1.0)
		draw_rect(Rect2(Vector2(54, 44), Vector2(180, 8)), Color(0.2, 0.2, 0.25))
		draw_rect(Rect2(Vector2(54, 44), Vector2(180 * k2, 8)), UIKit.RED)
