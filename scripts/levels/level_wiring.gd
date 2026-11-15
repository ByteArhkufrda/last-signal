class_name LevelWiring
extends Node
## Last Signal — shared signal wiring for a level (split from level_01.gd, 2026-11-15).
##
## Owns everything that connects the level's nodes to each other and to
## the HUD: interactables, hidden objects, enemies (patrol assignment,
## pulse, caught), puzzles, towers, the transmit console, pickups, area
## zones, the minimap feed and the stage hints. The level assembler
## (level_01.gd) and the room launcher (room_play.gd) both use it, so a
## room played standalone wires exactly like the full level.
##
## All lookups are scoped to the wired root's subtree: a freed level's
## nodes linger in the tree for a frame, and a revealed hidden object
## is in BOTH groups ("hidden" + "interactable") — wiring tree-wide
## double-connects it.

const FX_RING_SCENE: PackedScene = preload("res://scenes/effects/fx_ring.tscn")

var _root: Node2D = null
var _player: CharacterBody2D = null
var _mission: Node = null
var _nav_grid: AStarGrid2D = null
var _blocked: Array[Rect2] = []
var _puzzles_solved: int = 0


## Wire `root` (the level, or a standalone room's root). The room
## launcher passes its own root; the assembler passes the level.
func setup(root: Node2D, player: CharacterBody2D, mission: Node, nav_grid: AStarGrid2D, blocked: Array[Rect2]) -> void:
	_root = root
	_player = player
	_mission = mission
	_nav_grid = nav_grid
	_blocked = blocked
	_wire_interactables()
	for zone in _root.find_children("AreaZone_*", "Area2D", true, false):
		zone.body_entered.connect(_on_area_body_entered.bind(str(zone.get_meta("area_name"))))
	_root.set("current_area", _area_name_at(_player.global_position))
	# The minimap reads the pulse signal too: enemies inside the radius
	# are marked on the map for a few seconds (see minimap.gd).
	_player.pulse_emitted.connect(_on_pulse_for_minimap)


func puzzles_solved() -> int:
	return _puzzles_solved


func _area_name_at(pos: Vector2) -> String:
	for area in LevelData.AREAS:
		if (area["rect"] as Rect2).has_point(pos):
			return str(area["name"])
	return "Central Control"


## The HUD is a sibling of the level under Main. Resolve it by the
## sibling path first: get_first_node_in_group("hud") can return a
## stale HUD from a just-freed scene (queue_free deletes at end of
## frame, but a deferred call can run while it still lingers in the
## group — measured 2026-11-12: the minimap stayed empty in the test
## suite because setup landed on the previous test's HUD). Falls back
## to the group lookup for level-only tests, where there is no Main.
func _get_hud() -> CanvasLayer:
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
	if LevelData.STAGE_HINTS.has(stage):
		hud.set_stage_hint(str(LevelData.STAGE_HINTS[stage]))
	elif stage >= 3:
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
	hud.setup_minimap(LevelData.AREAS, _blocked, _player, tower_nodes, hidden_nodes, enemy_nodes)
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
		if LevelData.AREA_HINTS.has(area_name):
			hud.show_area_hint(str(LevelData.AREA_HINTS[area_name]))


func _wire_interactables() -> void:
	for node in _root.get_tree().get_nodes_in_group("interactable"):
		if not _root.is_ancestor_of(node):
			continue
		if node.has_signal("interacted"):
			node.interacted.connect(_on_interacted)
		if node.has_signal("collected"):
			node.collected.connect(_on_item_collected)
	for node in _root.get_tree().get_nodes_in_group("hidden"):
		if not _root.is_ancestor_of(node):
			continue
		if node.has_signal("revealed"):
			node.revealed.connect(_on_interacted)
		if node.has_signal("collected"):
			node.collected.connect(_on_item_collected)
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
			# One robot per area: patrol the rectangle of the area the
			# robot spawns in, never Central's loop by default. The
			# dict holds plain Arrays, but patrol_points is typed
			# Array[Vector2] — assigning a plain Array aborts the
			# whole wiring function (measured 2026-11-12: pulse,
			# puzzles and towers all stopped working), so convert
			# with assign() first.
			var area_name: String = _area_name_at(enemy.global_position)
			if LevelData.PATROL_RECTS.has(area_name):
				var points: Array[Vector2] = []
				points.assign(LevelData.PATROL_RECTS[area_name])
				enemy.patrol_points = points
			else:
				enemy.patrol_points = LevelData.PATROL_POINTS
		_player.pulse_emitted.connect(enemy.investigate)
		enemy.player_caught.connect(_on_player_caught)
	for puzzle in _root.get_tree().get_nodes_in_group("puzzles"):
		if not _root.is_ancestor_of(puzzle):
			continue
		if puzzle.has_signal("solved"):
			puzzle.solved.connect(_on_puzzle_solved.bind(puzzle))
	for tower in _root.get_tree().get_nodes_in_group("towers"):
		if not _root.is_ancestor_of(tower):
			continue
		if tower.has_signal("activated"):
			tower.activated.connect(_on_tower_activated)


func _on_puzzle_solved(puzzle: Node) -> void:
	_puzzles_solved += 1
	_mission.on_puzzle_solved()
	# Mirror the count onto the level (test hook: level._puzzles_solved).
	_root.set("_puzzles_solved", _puzzles_solved)
	var tower_name: String = str(puzzle.get("powers_tower"))
	var tower: StaticBody2D = _root.get_node_or_null(tower_name)
	if tower != null:
		tower.power_restored = true
	_play_sound("chime")
	var hud: CanvasLayer = _get_hud()
	if hud != null:
		hud.set_puzzles_solved(_puzzles_solved, LevelData.PUZZLE_TOTAL)
		hud.set_objective(_mission.current_text())
		var display: String = tower.tower_name if tower != null else tower_name
		hud.show_message("پازل حل شد! برق %s وصل شد." % display)
	_update_stage_hint()


func _on_tower_activated(tower: Node) -> void:
	_mission.on_tower_activated()
	_play_sound("tower")
	_spawn_ring(tower.global_position, Color(0.3, 0.9, 1.0), 48.0)
	var hud: CanvasLayer = _get_hud()
	if hud != null:
		hud.set_objective(_mission.current_text())
		hud.show_message("%s روشن شد! (%d/3 دکل)" % [tower.tower_name, _mission.towers_active])
	_update_stage_hint()


func _on_interacted(node: Node) -> void:
	if node.get("is_transmit_console") == true:
		_on_transmit_console()
		return
	var hud: CanvasLayer = _get_hud()
	if hud != null and node.get("message") != null:
		hud.show_message(str(node.get("message")))


func _on_transmit_console() -> void:
	var hud: CanvasLayer = _get_hud()
	if _mission.try_transmit():
		_play_sound("fanfare")
		var console: Node2D = _root.get_node_or_null("TransmitConsole")
		if console != null:
			_spawn_ring(console.global_position, Color(0.3, 1.0, 0.4), 64.0)
		if hud != null:
			hud.flash(Color(0.3, 1.0, 0.4))
			hud.set_objective(_mission.current_text())
			hud.clear_hint()
			hud.show_message("مأموریت کامل شد — سیگنال اضطراری فرستاده شد!")
		# Phase 10: the win screen pauses the game and offers Play Again
		# / Main Menu. Null-safe in level-only tests (no win screen there).
		var win: CanvasLayer = _root.get_tree().get_first_node_in_group("win")
		if win != null:
			win.show_win()
	elif hud != null:
		hud.show_message("فرستنده خاموش است — اول هر 3 دکل را روشن کن.")


# Phase 9 helpers: sound + one-shot ring effect. Both are null-safe in
# level-only tests, where there is no AudioManager.
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


func _on_item_collected(pickup: Node) -> void:
	_player.add_item(pickup.item_id, pickup.amount, pickup.battery_restore)
	_play_sound("blip")
	_spawn_ring(pickup.global_position, Color(1.0, 0.85, 0.3), 24.0)
	var hud: CanvasLayer = _get_hud()
	if hud != null:
		if pickup.battery_restore > 0.0:
			hud.show_message("%s برداشته شد (+%d باتری)." % [pickup.display_name, int(pickup.battery_restore)])
		else:
			hud.show_message("%s برداشته شد." % pickup.display_name)


func _on_player_caught() -> void:
	_player.global_position = LevelData.SPAWN
	_player.velocity = Vector2.ZERO
	_play_sound("sting")
	var hud: CanvasLayer = _get_hud()
	if hud != null:
		hud.flash(Color(1.0, 0.2, 0.2))
		hud.show_message("ربات امنیتی تو را گرفت! به ورودی برگشتی.")
