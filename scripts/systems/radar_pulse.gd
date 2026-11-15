extends Node2D
## Last Signal — Radar Pulse (Phase 4, occlusion fix 2026-11-12).
##
## An expanding ring (drawn in code with _draw, no sprite needed). As the
## front passes a hidden object it reveals it; the pulse frees itself at
## max_radius. Reveal is distance-based, like interaction in Phase 3.
## Enemies (Phase 5) investigate via the player's `pulse_emitted` signal,
## documented in docs/ARCHITECTURE.md.
##
## Occlusion (2026-11-12): a hidden object now also needs line of sight
## from the pulse origin — a raycast on the wall layer. Walls and crates
## (StaticBody2D, layer 1) block the reveal; the player and enemies
## (CharacterBody2D) are excluded from the ray, so a body standing in
## the way does not block a radar wave. Enemy investigation is separate
## and intentionally NOT occluded: enemies hear the pulse (sound), so
## they react by radius (see security_robot.investigate).

@export var max_radius: float = 160.0
@export var expand_speed: float = 320.0

var current_radius: float = 0.0

var _excluded_rids: Array[RID] = []


func _ready() -> void:
	for node in get_tree().get_nodes_in_group("player"):
		_excluded_rids.append((node as CollisionObject2D).get_rid())
	for node in get_tree().get_nodes_in_group("enemies"):
		_excluded_rids.append((node as CollisionObject2D).get_rid())


func _process(delta: float) -> void:
	current_radius = minf(current_radius + expand_speed * delta, max_radius)
	_reveal_in_range()
	queue_redraw()
	if current_radius >= max_radius:
		queue_free()


func _reveal_in_range() -> void:
	for node in get_tree().get_nodes_in_group("hidden"):
		if node.get("is_revealed"):
			continue
		if global_position.distance_to((node as Node2D).global_position) > current_radius:
			continue
		if _has_line_of_sight((node as Node2D).global_position):
			node.reveal()


## True when no wall (StaticBody2D) stands between the pulse origin and
## the target. Bodies (player/enemies) are excluded from the ray.
func _has_line_of_sight(target: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, target, 1)
	query.exclude = _excluded_rids
	var result := get_world_2d().direct_space_state.intersect_ray(query)
	return result.is_empty()


func _draw() -> void:
	var progress := current_radius / max_radius
	var alpha := 1.0 - progress * 0.7
	draw_arc(Vector2.ZERO, current_radius, 0, TAU, 64, Color(0.3, 0.9, 1.0, alpha), 2.0)
	draw_arc(Vector2.ZERO, current_radius * 0.66, 0, TAU, 48, Color(0.3, 0.9, 1.0, alpha * 0.5), 1.5)
	draw_circle(Vector2.ZERO, current_radius, Color(0.3, 0.9, 1.0, 0.04))
