## Per-room copy (absolute separation, 2026-11-23): identical to the shared original; only paths point at this room's own copies.
extends CharacterBody2D
## Last Signal — Security robot (Phase 5, fixes 2026-11-12).
##
## Enum-based FSM (GodotPrompter state-machine: 3 states, low complexity —
## the node-based FSM was rejected, it only pays off at 5+ states with
## their own enter/exit logic).
## Detection: radius 100 + vision cone (±0.7 rad around facing) + line of
## sight via PhysicsRayQueryParameters2D (awesome-gamedev godot-physics:
## exclude self and player RIDs, else the ray always hits the player).
## Detection runs every 0.1 s, not every frame. The cone keeps the player
## spawn (room center) safe from the patrol loop.
## Catch rule (Phase 5): touching the player emits player_caught; the
## level respawns the player at the entrance. A game-over screen comes
## with the menus in Phase 9.
##
## 2026-11-12 fixes:
## - investigate() now respects the radar radius it is given: an enemy
##   farther than the pulse radius from the origin does not react. The
##   radius comes from the signal (player.radar_max_radius), never a
##   hardcoded duplicate.
## - Pathfinding: when the level assigns nav_grid (an AStarGrid2D built
##   from the real wall/crate geometry), _move_toward follows a grid path
##   around obstacles instead of steering straight into them. Without a
##   grid the old direct steering is kept as a fallback (level-only
##   tests that instantiate the robot without a level still work).

enum State { PATROL, INVESTIGATE, CHASE }

signal player_caught

@export var patrol_speed: float = 70.0
@export var investigate_speed: float = 110.0
@export var chase_speed: float = 140.0
@export var detection_radius: float = 100.0
@export var vision_half_angle: float = 0.7
@export var lose_radius: float = 150.0
@export var lose_delay: float = 1.5
@export var scan_time: float = 2.0
@export var waypoint_wait: float = 1.0
@export var catch_distance: float = 18.0
@export var detection_interval: float = 0.1

var state: State = State.PATROL
var patrol_points: Array[Vector2] = []
var player: Node2D = null
## Frozen while the player reads a log (Stage 3, Q5): set by the
## wiring when the log panel opens, cleared when it closes.
var reading_paused: bool = false
## AStarGrid2D built by the level from the real collision geometry
## (walls, crate, alcove). Null = direct steering fallback.
var nav_grid: AStarGrid2D = null

var _waypoint_index: int = 0
var _investigate_target: Vector2 = Vector2.ZERO
var _wait_timer: float = 0.0
var _scan_timer: float = 0.0
var _lose_timer: float = 0.0
var _detection_timer: float = 0.0
var _sees_player: bool = false
var _catch_grace: float = 0.0
var _facing: Vector2 = Vector2.DOWN
## Current grid path (world-space waypoints) and its target, for repathing.
var _path: Array[Vector2] = []
var _path_target: Vector2 = Vector2.ZERO
var _repath_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	if patrol_points.is_empty():
		patrol_points = [global_position]


func _physics_process(delta: float) -> void:
	# Frozen while the player reads: no patrol, no detection, no
	# catch. Timers freeze too — the pause is a real pause.
	if reading_paused:
		return
	if _catch_grace > 0.0:
		_catch_grace -= delta
	if _repath_timer > 0.0:
		_repath_timer -= delta
	_detection_timer -= delta
	if _detection_timer <= 0.0:
		_detection_timer = detection_interval
		_sees_player = _can_see_player()
	match state:
		State.PATROL:
			_state_patrol(delta)
		State.INVESTIGATE:
			_state_investigate(delta)
		State.CHASE:
			_state_chase(delta)
	if velocity.length() > 5.0:
		_facing = velocity.normalized()
	move_and_slide()
	queue_redraw()
	_check_catch()


func _state_patrol(delta: float) -> void:
	if _sees_player:
		state = State.CHASE
		_lose_timer = 0.0
		return
	if _wait_timer > 0.0:
		_wait_timer -= delta
		velocity = Vector2.ZERO
		return
	if _waypoint_index >= patrol_points.size():
		_waypoint_index = 0
	var target: Vector2 = patrol_points[_waypoint_index]
	if _move_toward(target, patrol_speed):
		_wait_timer = waypoint_wait
		_waypoint_index = (_waypoint_index + 1) % patrol_points.size()


func _state_investigate(delta: float) -> void:
	if _sees_player:
		state = State.CHASE
		_lose_timer = 0.0
		return
	if global_position.distance_to(_investigate_target) > 8.0:
		_move_toward(_investigate_target, investigate_speed)
		_scan_timer = 0.0
	else:
		velocity = Vector2.ZERO
		_scan_timer += delta
		if _scan_timer >= scan_time:
			_return_to_patrol()


func _state_chase(delta: float) -> void:
	if player == null:
		_return_to_patrol()
		return
	if _sees_player and global_position.distance_to(player.global_position) <= lose_radius:
		_lose_timer = 0.0
	else:
		_lose_timer += delta
		if _lose_timer >= lose_delay:
			_return_to_patrol()
			return
	_move_toward(player.global_position, chase_speed)


## Moves toward target at speed. Returns true when arrived (within 8 px).
## With nav_grid, follows an AStarGrid2D path around solid cells and
## repaths when the target moved or once a second; without a grid it
## steers directly (old behavior, kept for grid-less use).
func _move_toward(target: Vector2, speed: float) -> bool:
	if nav_grid == null:
		return _move_direct(target, speed)
	if global_position.distance_to(target) <= 8.0:
		velocity = Vector2.ZERO
		_path.clear()
		return true
	if _path.is_empty() or _path_target.distance_to(target) > 16.0 or _repath_timer <= 0.0:
		_path = _compute_path(target)
		_path_target = target
		_repath_timer = 1.0
	if _path.is_empty():
		return _move_direct(target, speed)
	var waypoint: Vector2 = _path[0]
	if global_position.distance_to(waypoint) <= 8.0:
		_path.remove_at(0)
		if _path.is_empty():
			return _move_direct(target, speed)
		waypoint = _path[0]
	velocity = (waypoint - global_position).normalized() * speed
	return false


func _move_direct(target: Vector2, speed: float) -> bool:
	var to: Vector2 = target - global_position
	if to.length() <= 8.0:
		velocity = Vector2.ZERO
		return true
	velocity = to.normalized() * speed
	return false


## Grid path from the current cell to the target cell, as world-space
## cell centers (skipping the start cell). Empty = no route / same cell.
func _compute_path(target: Vector2) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var from_cell := _world_to_cell(global_position)
	var to_cell := _world_to_cell(target)
	if from_cell == to_cell:
		return out
	var cells: PackedVector2Array = nav_grid.get_id_path(from_cell, to_cell)
	for i in range(1, cells.size()):
		out.append(_cell_to_world(cells[i]))
	return out


func _world_to_cell(world_pos: Vector2) -> Vector2i:
	var region: Rect2i = nav_grid.region
	var cell := Vector2i(int(world_pos.x / 16.0), int(world_pos.y / 16.0))
	cell.x = clampi(cell.x, region.position.x, region.end.x - 1)
	cell.y = clampi(cell.y, region.position.y, region.end.y - 1)
	return cell


func _cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * 16.0 + Vector2(8.0, 8.0)


func _return_to_patrol() -> void:
	state = State.PATROL
	_wait_timer = 0.0
	_scan_timer = 0.0
	_lose_timer = 0.0
	_path.clear()
	var best := 0
	var best_dist := INF
	for i in patrol_points.size():
		var d := global_position.distance_to(patrol_points[i])
		if d < best_dist:
			best_dist = d
			best = i
	_waypoint_index = best


## Freeze / unfreeze while the player reads a log (Stage 3, Q5).
func set_reading_paused(value: bool) -> void:
	reading_paused = value
	if value:
		velocity = Vector2.ZERO


## Called by the level when the player emits a radar pulse. Chasing is
## never interrupted by a pulse, and a pulse beyond the radar radius
## (the radius the player actually emitted) is ignored.
func investigate(origin: Vector2, radius: float) -> void:
	if state == State.CHASE:
		return
	if radius <= 0.0 or global_position.distance_to(origin) > radius:
		return
	_investigate_target = origin
	_scan_timer = 0.0
	state = State.INVESTIGATE


func _can_see_player() -> bool:
	if player == null or _catch_grace > 0.0:
		return false
	var to_player: Vector2 = player.global_position - global_position
	if to_player.length() > detection_radius:
		return false
	if absf(_facing.angle_to(to_player.normalized())) > vision_half_angle:
		return false
	var query := PhysicsRayQueryParameters2D.create(global_position, player.global_position, 1)
	query.exclude = [get_rid(), player.get_rid()]
	var result := get_world_2d().direct_space_state.intersect_ray(query)
	return result.is_empty()


func _check_catch() -> void:
	if player == null or _catch_grace > 0.0:
		return
	if global_position.distance_to(player.global_position) <= catch_distance:
		_catch_grace = 2.0
		state = State.PATROL
		player_caught.emit()


func _draw() -> void:
	var half_angle := vision_half_angle
	var points := PackedVector2Array([Vector2.ZERO])
	var base_angle := _facing.angle()
	for i in 9:
		var a := base_angle - half_angle + (2.0 * half_angle * i / 8.0)
		points.append(Vector2(cos(a), sin(a)) * detection_radius)
	var alpha := 0.15 if state == State.CHASE else 0.07
	draw_colored_polygon(points, Color(1.0, 0.2, 0.2, alpha))
