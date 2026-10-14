class_name StatusCard
extends Control
## Bottom-right party card: portrait, name, HP/SP bars and boost pips.

var mc: Battler
var _name: Label
var _hp: Label
var _sp: Label
var _portrait: TextureRect
var _shown_hp: float = 0.0
var _shown_sp: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(400, 150)


func _ready() -> void:
	_portrait = TextureRect.new()
	_portrait.texture = UIKit.tex("res://assets/sprites/portraits/mc_angry.png")
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.size = Vector2(150, 150)
	_portrait.position = Vector2(-40, -36)
	add_child(_portrait)
	_name = UIKit.label("", 34, UIKit.BONE, UIKit.head_font())
	UIKit.outline(_name, 6, UIKit.BLACK)
	_name.position = Vector2(118, -6)
	_name.rotation = deg_to_rad(-4.0)
	add_child(_name)
	_hp = UIKit.label("", 22, UIKit.BONE, UIKit.head_font())
	_hp.position = Vector2(126, 52)
	add_child(_hp)
	_sp = UIKit.label("", 22, UIKit.BONE, UIKit.head_font())
	_sp.position = Vector2(126, 88)
	add_child(_sp)


func bind(b: Battler) -> void:
	mc = b
	_shown_hp = float(b.hp)
	_shown_sp = float(b.sp)
	refresh()


func refresh() -> void:
	if mc == null or _name == null:
		return
	_name.text = mc.display_name.to_upper()
	_hp.text = "HP  %d / %d" % [mc.hp, mc.max_hp]
	_sp.text = "SP  %d / %d" % [mc.sp, mc.max_sp]


func _process(delta: float) -> void:
	if mc == null:
		return
	_shown_hp = lerpf(_shown_hp, float(mc.hp), minf(1.0, delta * 6.0))
	_shown_sp = lerpf(_shown_sp, float(mc.sp), minf(1.0, delta * 6.0))
	queue_redraw()


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(30, 10), Vector2(420, -10), Vector2(410, 150), Vector2(10, 160)]),
		UIKit.BONE)
	draw_colored_polygon(PackedVector2Array([Vector2(40, 18), Vector2(410, 0), Vector2(400, 142), Vector2(22, 150)]),
		UIKit.BLACK)
	if mc == null:
		return
	var hp_k := clampf(_shown_hp / float(maxi(mc.max_hp, 1)), 0.0, 1.0)
	var sp_k := clampf(_shown_sp / float(maxi(mc.max_sp, 1)), 0.0, 1.0)
	var hp_col := Color("5ad06a").lerp(UIKit.RED, 1.0 - hp_k) if hp_k > 0.3 else UIKit.RED
	_bar(Vector2(126, 80), 250.0, hp_k, hp_col)
	_bar(Vector2(126, 116), 250.0, sp_k, Color("4aa8f0"))
	# boost pips
	var bp_icon := UIKit.tex("res://assets/sprites/ui/icon_boost.png")
	var bp_empty := UIKit.tex("res://assets/sprites/ui/icon_boost_empty.png")
	for i in 5:
		var tex := bp_icon if i < mc.bp else bp_empty
		if tex:
			draw_texture_rect(tex, Rect2(Vector2(250 + i * 30, 26), Vector2(28, 28)), false)


func _bar(p: Vector2, w: float, k: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([p + Vector2(6, 0), p + Vector2(w + 6, -3), p + Vector2(w, 9),
		p + Vector2(0, 12)]), Color(0.2, 0.2, 0.25))
	if k > 0.0:
		draw_colored_polygon(PackedVector2Array([p + Vector2(6, 0), p + Vector2(6 + w * k, -3 * k), p + Vector2(w * k, 9),
			p + Vector2(0, 12)]), col)
