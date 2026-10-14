class_name Interactable
extends Node2D
## Something the player can interact with by pressing "accept" nearby.

signal interacted

var prompt: String = "PERIKSA"
var radius: float = 20.0
var enabled: bool = true
var one_shot: bool = false
var sparkle: CPUParticles2D


func _init(text: String = "PERIKSA", r: float = 20.0) -> void:
	prompt = text
	radius = r


func _ready() -> void:
	add_to_group("interactable")


func add_sparkle(glow_parent: Node) -> void:
	## Small glint so pickups read in the grass (lives on the glow layer).
	sparkle = FX.dust(Vector2(10, 6), 6, Color(1.0, 0.95, 0.6))
	sparkle.position = global_position + Vector2(0, -4)
	glow_parent.add_child(sparkle)


func trigger() -> void:
	if not enabled:
		return
	if one_shot:
		enabled = false
	interacted.emit()


func disable_and_hide() -> void:
	enabled = false
	visible = false
	if sparkle:
		sparkle.queue_free()
		sparkle = null
