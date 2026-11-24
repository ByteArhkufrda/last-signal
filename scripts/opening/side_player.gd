class_name SidePlayer
extends CharacterBody2D
## Last Signal — opening sequence: side-view player controller.
##
## Ground-based side-scroller (MOTION_MODE_GROUNDED, gravity from the
## project settings). No jump: the opening room has a flat floor. Left /
## right accelerate with friction; the sprite flips with the facing
## direction. The orchestrator sets `controls_locked` while the manual or
## the puzzle overlay is open. Collision layer 1, like the top-down
## player. The top-down player script is untouched; this is a separate
## controller for the side-view opening only.

const SPEED := 120.0
const ACCEL := 900.0
const FRICTION := 1200.0

## The sprite is flipped by facing; the flashlight reads this too.
var facing := 1
var controls_locked := false

var _sprite: Sprite2D


func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 1
	_sprite = get_node_or_null("Sprite2D")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	else:
		velocity.y = 0.0
	var direction := 0.0
	if not controls_locked:
		direction = Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		facing = 1 if direction > 0.0 else -1
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCEL * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	if _sprite != null:
		_sprite.flip_h = facing < 0
	move_and_slide()
