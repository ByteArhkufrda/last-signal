extends StaticBody2D
## Last Signal — Automatic door (map redesign 2026-11-25).
##
## No interaction key: a sensor Area2D around the door opens it whenever
## the player or any robot (CharacterBody2D) is close, and closes it a
## moment after the last body leaves. Opening disables the collision
## shape (deferred, so it is safe mid-physics) and slides the two leaves
## apart. A closed door blocks movement and line of sight (walls and
## doors share collision layer 1); an open one does not.
## Horizontal by default; the level rotates it 90 degrees for doors in
## vertical walls (the leaves slide along the local x axis, so they
## follow the rotation).

signal state_changed(is_open: bool)

@export var close_delay: float = 0.35
@export var sensor_size: Vector2 = Vector2(64, 64)

var is_open: bool = false

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var leaf_left: Polygon2D = $LeafLeft
@onready var leaf_right: Polygon2D = $LeafRight

var _leaf_left_base_x: float = 0.0
var _leaf_right_base_x: float = 0.0
var _bodies: Array = []
var _close_timer: float = 0.0


func _ready() -> void:
	add_to_group("doors")
	_leaf_left_base_x = leaf_left.position.x
	_leaf_right_base_x = leaf_right.position.x
	var sensor := Area2D.new()
	sensor.name = "Sensor"
	sensor.collision_layer = 0
	sensor.collision_mask = 1
	sensor.monitoring = true
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = sensor_size
	shape.shape = rect
	sensor.add_child(shape)
	add_child(sensor)
	sensor.body_entered.connect(_on_body_entered)
	sensor.body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	_bodies = _bodies.filter(func(b): return is_instance_valid(b))
	if not _bodies.is_empty():
		_close_timer = close_delay
		if not is_open:
			_set_open(true)
	elif is_open:
		_close_timer -= delta
		if _close_timer <= 0.0:
			_set_open(false)


func _on_body_entered(body: Node2D) -> void:
	# Walls and props are StaticBody2D; only characters open the door.
	if body is CharacterBody2D and not _bodies.has(body):
		_bodies.append(body)


func _on_body_exited(body: Node2D) -> void:
	_bodies.erase(body)


func _set_open(value: bool) -> void:
	if value == is_open:
		return
	is_open = value
	collision.set_deferred("disabled", is_open)
	leaf_left.position.x = _leaf_left_base_x - 14.0 if is_open else _leaf_left_base_x
	leaf_right.position.x = _leaf_right_base_x + 14.0 if is_open else _leaf_right_base_x
	state_changed.emit(is_open)
