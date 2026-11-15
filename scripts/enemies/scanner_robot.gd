extends "res://scripts/enemies/security_robot.gd"
## Last Signal — Scanner robot (2026-11-12, second enemy archetype).
##
## Same FSM and pathfinding as the security robot (extends it — no
## duplicated AI code), but a genuinely different role:
## - Stationary post: it does NOT patrol. It sits at its post and slowly
##   rotates, sweeping its vision cone 360 degrees.
## - Wide, long watch: detection_radius 180 (vs 100) and vision cone
##   ±1.2 rad (vs ±0.7), so it sees more — but it chases slower
##   (chase_speed 100 vs 140), so the player can outrun it.
## - Periodic scan: every scan_interval it completes a sweep
##   (scan_count, test hook); the rotation is the visible tell.
## - When it loses the player it walks back to its post (pathfinding)
##   and resumes rotating instead of patrolling.
## Sprite: atlas row 949119, "top-down squat robot with a single round
## eye" — the single lens reads as a scanner; CC0, same 16x16 style.
## (The black/red robot 15415 was the alternate distinct archetype; the
## one-eye robot was chosen because the lens sells the scanner role.)

@export var scan_interval: float = 3.0
@export var rotate_speed: float = 1.0

## Completed scan sweeps (test hook).
var scan_count: int = 0

var _scan_cycle_timer: float = 0.0


func _state_patrol(delta: float) -> void:
	if _sees_player:
		state = State.CHASE
		_lose_timer = 0.0
		return
	var post: Vector2 = patrol_points[0] if not patrol_points.is_empty() else global_position
	if global_position.distance_to(post) > 16.0:
		# Walked back after a chase: return to the post, then scan.
		_move_toward(post, investigate_speed)
		return
	velocity = Vector2.ZERO
	_facing = _facing.rotated(rotate_speed * delta)
	_scan_cycle_timer += delta
	if _scan_cycle_timer >= scan_interval:
		_scan_cycle_timer = 0.0
		scan_count += 1
