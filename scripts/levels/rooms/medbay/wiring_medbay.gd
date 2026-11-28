extends Node
## Last Signal — wiring for medbay (2026-11-28).
##
## Self-contained copy: stage hints, the area hint and the patrol
## fallback are inlined below, and the ring effect is this room's
## own fx_ring copy. No puzzles here — no power/signal/vault chain,
## no keycard, no ending sequence, no readable-log overlay (there
## are no consoles or long story texts in this room). What the
## wiring does: area hints, the objective + stage hint on the HUD,
## the minimap feed, robot patrol assignment (one route per robot),
## radar-pulse investigation, and the caught → respawn flow.

const STAGE_HINTS := {
	0: "با Q رادار بزن؛ از دید ربات‌های نگهبان دور بمان",
}
const AREA_HINT := "بخش پزشکی — Medbay؛ از دید ربات‌های نگهبان دور بمان"
const _DEFAULT_PATROL: Array[Vector2] = [Vector2(592, 496), Vector2(1552, 496)]

const FX_RING_SCENE: PackedScene = preload("res://scenes/levels/rooms/medbay/fx_ring_medbay.tscn")

var _root: Node2D = null
var _player: CharacterBody2D = null
var _mission: Node = null
var _nav_grid: AStarGrid2D = null
var _blocked: Array[Rect2] = []
## The single room being played standalone (the room's play_<room>.gd passes its
## own root, which carries `.room`); null in the assembled level.
## Standalone, every position the wiring sees is a LOCAL one, so area,
## patrol and minimap all come from this room instead of the station
## layout in LevelData.
var _standalone_room: Node2D = null


## Where a caught player respawns. The full game uses the entrance
## (LevelData.SPAWN); a standalone room passes its own spawn point
## (the entrance is outside every other room but the one played).
var _respawn_point: Vector2 = Vector2(848, 80)


## Wire `root` (the level, or a standalone room's root). The room
## launcher passes its own root; the assembler passes the level.
func setup(root: Node2D, player: CharacterBody2D, mission: Node, nav_grid: AStarGrid2D, blocked: Array[Rect2], respawn_point: Vector2 = Vector2(848, 80)) -> void:
	_root = root
	_player = player
	_mission = mission
	_nav_grid = nav_grid
	_blocked = blocked
	_respawn_point = respawn_point
	_standalone_room = root.get("room") as Node2D
	_wire_interactables()
	for zone in _root.find_children("AreaZone_*", "Area2D", true, false):
		zone.body_entered.connect(_on_area_body_entered.bind(str(zone.get_meta("area_name"))))
	_root.set("current_area", _area_name_at(_player.global_position))
	# The minimap reads the pulse signal too: enemies inside the radius
	# are marked on the map for a few seconds (see minimap.gd).
	_player.pulse_emitted.connect(_on_pulse_for_minimap)
	# Standalone only: the HUD exists now (the launcher adds it), so
	# feed it the room layout, the objective and the standing hint, and
	# show the area hint once — spawning inside the area never fires
	# the area-enter event that shows it in the full game.
	_setup_minimap()
	_update_objective_hud()
	_update_stage_hint()
	var hud0: CanvasLayer = _get_hud()
	if hud0 != null:
		hud0.show_area_hint(AREA_HINT)


func _area_name_at(_pos: Vector2) -> String:
	# Standalone only: the only area is this room's.
	if _standalone_room != null:
		return _standalone_room.area_name
	return "بخش پزشکی"


## The HUD is a sibling of the level under Main. Resolve it by the
## sibling path first: get_first_node_in_group("hud") can return a
## stale HUD from a just-freed scene (queue_free deletes at end of
## frame, but a deferred call can run while it still lingers in the
## group — measured 2026-11-12: the minimap stayed empty in the test
## suite because setup landed on the previous test's HUD). Falls back
## to the group lookup for level-only tests, where there is no Main.
func _get_hud() -> CanvasLayer:
	# Standalone: the launcher adds the HUD as a child of the play
	# root — prefer it over the group lookup, which can return a
	# stale HUD from a just-freed scene.
	var own: Node = _root.get_node_or_null("HUD")
	if own is CanvasLayer:
		return own
	var parent: Node = _root.get_parent()
	if parent != null:
		var sibling: Node = parent.get_node_or_null("HUD")
		if sibling is CanvasLayer:
			return sibling
	return _root.get_tree().get_first_node_in_group("hud")


func _update_objective_hud() -> void:
	var hud: CanvasLayer = _get_hud()
	if hud != null:
		hud.set_objective(_mission.current_text())

## Show the hint for the mission's current stage (the standing guide:
## which key to press next). Null-safe in level-only tests (no HUD).
func _update_stage_hint() -> void:
	var hud: CanvasLayer = _get_hud()
	if hud == null:
		return
	var stage: int = _mission.current_stage()
	if STAGE_HINTS.has(stage):
		hud.set_stage_hint(str(STAGE_HINTS[stage]))
	else:
		hud.clear_hint()


## Feed the minimap its static layout + live node refs. Null-safe in
## level-only tests (no HUD there). Scoped to the wired root's subtree
## so a freed level's nodes can't leak in.
func _setup_minimap() -> void:
	var hud: CanvasLayer = _get_hud()
	if hud == null:
		return
	var tower_nodes: Array = []
	var hidden_nodes: Array = []
	var enemy_nodes: Array = []
	for node in _root.get_tree().get_nodes_in_group("towers"):
		if _root.is_ancestor_of(node):
			tower_nodes.append(node)
	for node in _root.get_tree().get_nodes_in_group("hidden"):
		if _root.is_ancestor_of(node):
			hidden_nodes.append(node)
	for node in _root.get_tree().get_nodes_in_group("enemies"):
		if _root.is_ancestor_of(node):
			enemy_nodes.append(node)
	# Standalone only: the minimap shows only this room (local rect,
	# local walls).
	var areas: Array = [{"name": _standalone_room.area_name,
		"rect": _standalone_room.room_rect,
		"tint": _standalone_room.tint_color}]
	hud.setup_minimap(areas, _blocked, _player, tower_nodes, hidden_nodes, enemy_nodes)
	hud.set_minimap_area(str(_root.get("current_area")))


func _on_pulse_for_minimap(origin: Vector2, radius: float) -> void:
	var hud: CanvasLayer = _get_hud()
	if hud != null:
		hud.mark_minimap_enemies(origin, radius)


func _on_area_body_entered(body: Node2D, area_name: String) -> void:
	if body != _player or area_name == str(_root.get("current_area")):
		return
	_root.set("current_area", area_name)
	var hud: CanvasLayer = _get_hud()
	if hud != null:
		hud.show_message(area_name)
		hud.set_minimap_area(area_name)
		hud.show_area_hint(AREA_HINT)


func _wire_interactables() -> void:
	for node in _root.get_tree().get_nodes_in_group("interactable"):
		if not _root.is_ancestor_of(node):
			continue
		if node.has_signal("interacted"):
			node.interacted.connect(_on_interacted)
	for node in _root.get_tree().get_nodes_in_group("hidden"):
		if not _root.is_ancestor_of(node):
			continue
		if node.has_signal("revealed"):
			node.revealed.connect(_on_interacted)
	# Four robots, four routes: robot N runs route N from the room's
	# patrol_routes_local(); a robot past the routes list falls back
	# to route 1. (Medbay has no consoles or interactables right now,
	# so the loop above finds nothing — it stays for a future one.)
	var enemy_index := 0
	for enemy in _root.get_tree().get_nodes_in_group("enemies"):
		if not _root.is_ancestor_of(enemy):
			continue
		enemy.player = _player
		enemy.nav_grid = _nav_grid
		if enemy.is_in_group("scanners"):
			# The scanner stays at its post; it never patrols.
			var post_points: Array[Vector2] = [enemy.global_position]
			enemy.patrol_points = post_points
		else:
			var routes: Array = _standalone_room.patrol_routes_local()
			var route_points: Array[Vector2] = []
			if enemy_index < routes.size():
				var raw: Array = routes[enemy_index]
				for p in raw:
					route_points.append(p)
			if route_points.is_empty():
				route_points = _standalone_room.patrol_points_local()
			enemy.patrol_points = route_points if not route_points.is_empty() else _DEFAULT_PATROL
			enemy_index += 1
		_player.pulse_emitted.connect(enemy.investigate)
		enemy.player_caught.connect(_on_player_caught)


func _on_interacted(node: Node) -> void:
	if node.get("message") != null:
		var hud: CanvasLayer = _get_hud()
		if hud != null:
			hud.show_message(str(node.get("message")))


# Sound + one-shot ring effect. Both are null-safe in level-only
# tests, where there is no AudioManager. No pickup uses the ring
# yet; it stays as the room's generic feedback effect.
func _play_sound(sound_name: String) -> void:
	var audio: Node = _root.get_tree().get_first_node_in_group("audio")
	if audio != null:
		audio.play(sound_name)


func _spawn_ring(pos: Vector2, color: Color, radius: float) -> void:
	var ring: Node2D = FX_RING_SCENE.instantiate()
	ring.position = pos
	ring.ring_color = color
	ring.max_radius = radius
	_root.add_child(ring)


func _on_player_caught() -> void:
	_player.global_position = _respawn_point
	_player.velocity = Vector2.ZERO
	_play_sound("sting")
	var hud: CanvasLayer = _get_hud()
	if hud != null:
		hud.flash(Color(1.0, 0.2, 0.2))
		hud.show_message("ربات تو را گرفت!")
