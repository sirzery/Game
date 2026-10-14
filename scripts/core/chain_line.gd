class_name ChainLine
extends Line2D
## A sagging iron chain between two points, drawn with a tiled link texture.
## snap() breaks it: both halves drop away with sparks.

signal snapped

var a: Vector2
var b: Vector2
var sag: float = 10.0
var broken: bool = false


func _init(from: Vector2 = Vector2.ZERO, to: Vector2 = Vector2.ZERO, sag_px: float = 10.0) -> void:
	a = from
	b = to
	sag = sag_px


func _ready() -> void:
	texture = UIKit.tex("res://assets/sprites/props/chain_link.png")
	texture_mode = Line2D.LINE_TEXTURE_TILE
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	width = 5.0
	joint_mode = Line2D.LINE_JOINT_ROUND
	_rebuild()


func set_ends(from: Vector2, to: Vector2) -> void:
	a = from
	b = to
	_rebuild()


func _rebuild() -> void:
	clear_points()
	var n := 14
	for i in n + 1:
		var t := float(i) / float(n)
		var p := a.lerp(b, t)
		p.y += sin(t * PI) * sag
		add_point(p)


func snap(at: float = 0.5) -> void:
	if broken:
		return
	broken = true
	var mid := a.lerp(b, at)
	mid.y += sin(at * PI) * sag
	visible = false
	var parent := get_parent()
	for half in [[a, mid, -1.0], [b, mid, 1.0]]:
		var piece := Line2D.new()
		piece.texture = texture
		piece.texture_mode = texture_mode
		piece.texture_repeat = texture_repeat
		piece.width = width
		var anchor: Vector2 = half[0]
		var end: Vector2 = half[1]
		piece.add_point(anchor)
		piece.add_point(anchor.lerp(end, 0.5) + Vector2(0, sag * 0.5))
		piece.add_point(end)
		parent.add_child(piece)
		var drop := anchor + Vector2(float(half[2]) * 4.0, 26.0)
		var t := piece.create_tween()
		t.tween_method(func(k: float) -> void:
			piece.set_point_position(2, end.lerp(drop, k))
			piece.set_point_position(1, anchor.lerp(end.lerp(drop, k), 0.5) + Vector2(0, sag * (0.5 + k)))
		, 0.0, 1.0, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	snapped.emit()
