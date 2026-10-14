class_name Player
extends CharacterBody2D
## The Scholar on the field map: 8-way movement, run, footsteps, interaction.

signal interact_target_changed(target: Interactable)

const WALK_SPEED := 62.0
const RUN_SPEED := 104.0

var actor: Actor
var controls_enabled: bool = true
var target: Interactable
var _step_t: float = 0.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10, 6)
	shape.shape = rect
	shape.position = Vector2(0, -2)
	add_child(shape)
	actor = Actor.new("mc")
	add_child(actor)


func _physics_process(delta: float) -> void:
	var dir := Vector2.ZERO
	if controls_enabled and not Router.busy:
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var running := Input.is_action_pressed("run")
	velocity = dir * (RUN_SPEED if running else WALK_SPEED)
	move_and_slide()
	if dir.length() > 0.1:
		if absf(dir.x) > absf(dir.y):
			actor.face("right" if dir.x > 0.0 else "left")
		else:
			actor.face("down" if dir.y > 0.0 else "up")
		actor.walk_fps = 12.0 if running else 8.0
		actor.set_walking(true)
		_step_t += delta * (1.6 if running else 1.0)
		if _step_t > 0.32:
			_step_t = 0.0
			Audio.sfx("footstep", -14.0, randf_range(0.85, 1.15))
	else:
		actor.set_walking(false)
	_update_target()


func _update_target() -> void:
	var best: Interactable = null
	var best_d := 1e9
	if controls_enabled:
		var facing_vec := Vector2.DOWN
		match actor.facing:
			"up":
				facing_vec = Vector2.UP
			"left":
				facing_vec = Vector2.LEFT
			"right":
				facing_vec = Vector2.RIGHT
		var probe := global_position + facing_vec * 6.0
		for n in get_tree().get_nodes_in_group("interactable"):
			var it := n as Interactable
			if it == null or not it.enabled or not it.is_visible_in_tree():
				continue
			var d := probe.distance_to(it.global_position)
			if d < it.radius and d < best_d:
				best = it
				best_d = d
	if best != target:
		target = best
		interact_target_changed.emit(target)


func try_interact() -> bool:
	if controls_enabled and target != null and target.enabled:
		var t := target
		Audio.sfx("ui_confirm", -8.0)
		t.trigger()
		return true
	return false
