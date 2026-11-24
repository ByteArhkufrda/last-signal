extends SceneTree
## Last Signal — headless room tests (2026-11-15).
##
## Run: godot --headless --path . --script res://scripts/tests/test_rooms.gd
## Exit code 0 = all pass, 1 = any failure. No bare assert() (it hangs
## the run). A room whose scene does not exist yet is SKIPPED (its
## branch has not landed), not failed — the split lands room by room.
##
## For every split room this verifies, standalone via its own
## play_<room>.tscn: the floor covers exactly the room's tile rect,
## the floor covers exactly the room's tile rect, the expected nodes
## exist at their exact positions, the wiring sets the area, the
## robot(s) patrol inside the room, a nav path exists from the spawn,
## and — against one assembled level instance — the standalone nav
## grid agrees cell for cell with the full level's grid.
##
## Local-coordinate contract (2026-11-23): every position in
## ROOM_CHECKS is LOCAL — the room's own (0, 0) origin. "offset" is
## the room's station position in tiles; the assembled level must show
## each node at local + offset * 16, and the standalone nav grid cell
## (local) must match the assembled grid cell (local + offset).

const ROOM_SCENES := {
	"command_center": "res://scenes/levels/rooms/command_center/command_center.tscn",
	"medical_wing": "res://scenes/levels/rooms/medical_wing/medical_wing.tscn",
	"laboratory": "res://scenes/levels/rooms/laboratory/laboratory.tscn",
	"engine_room": "res://scenes/levels/rooms/engine_room/engine_room.tscn",
	"communications": "res://scenes/levels/rooms/communications/communications.tscn",
}
## Each room's own standalone launcher (absolute separation: no shared
## launcher file).
const PLAY_SCENES := {
	"command_center": "res://scenes/levels/rooms/command_center/play_command_center.tscn",
	"medical_wing": "res://scenes/levels/rooms/medical_wing/play_medical_wing.tscn",
	"laboratory": "res://scenes/levels/rooms/laboratory/play_laboratory.tscn",
	"engine_room": "res://scenes/levels/rooms/engine_room/play_engine_room.tscn",
	"communications": "res://scenes/levels/rooms/communications/play_communications.tscn",
}
## area, LOCAL tile rect, LOCAL standalone spawn, a walkable LOCAL
## target cell for the nav-path check, expected named nodes with LOCAL
## positions, expected group sizes inside the room, expected children
## of the "Walls_<key>" body (3 per wall rect: shape + visual +
## highlight), and the room's station offset in tiles.
const ROOM_CHECKS := {
	"command_center": {
		"area": "کنترل مرکزی", "tile_rect": Rect2i(0, 0, 40, 23),
		"offset": Vector2i(0, 0),
		"spawn": Vector2(320, 184), "target_cell": Vector2i(10, 10),
		"nodes": {
			"Tower1": Vector2(80, 48), "Tower2": Vector2(320, 48),
			"Tower3": Vector2(480, 320), "TransmitConsole": Vector2(320, 100),
			"BreakerPanel": Vector2(40, 204), "WirePanel": Vector2(600, 204),
			"FuseBox": Vector2(320, 336), "SecurityRobot": Vector2(200, 120),
			"ConsoleA": Vector2(120, 100), "ConsoleB": Vector2(560, 40),
			"Door": Vector2(568, 64), "Crate": Vector2(168, 88),
			"HiddenEnergyCell": Vector2(96, 280), "HiddenBattery": Vector2(560, 320),
			"VisiblePickup": Vector2(120, 320), "HiddenFuse": Vector2(600, 100),
		},
		"towers": 3, "puzzles": 3, "enemies": 1, "wall_children": 12,
	},
	"medical_wing": {
		"area": "بخش پزشکی", "tile_rect": Rect2i(0, 0, 40, 23),
		"offset": Vector2i(40, 0),
		"spawn": Vector2(64, 256), "target_cell": Vector2i(10, 10),
		"nodes": {
			"ScannerRobot": Vector2(260, 120), "MedBedStandard": Vector2(60, 64),
			# Story notes (P1, 2026-11-23); NoteConsole2 lies on the doctor's
			# desk, as a child of its body (the path is relative to the room).
			"NoteConsole1": Vector2(140, 320),
			"MedDeskDoctor/NoteConsole2": Vector2(450, 260),
			"NoteConsole3": Vector2(560, 160),
		},
		"towers": 0, "puzzles": 0, "enemies": 1, "wall_children": 18,
	},
	"laboratory": {
		"area": "آزمایشگاه تحقیقاتی", "tile_rect": Rect2i(0, 0, 40, 23),
		"offset": Vector2i(0, 23),
		"spawn": Vector2(320, 32), "target_cell": Vector2i(10, 7),
		"nodes": {"LabRobot": Vector2(200, 192)},
		"towers": 0, "puzzles": 0, "enemies": 1, "wall_children": 18,
	},
	"engine_room": {
		"area": "نیروگاه", "tile_rect": Rect2i(0, 0, 40, 23),
		"offset": Vector2i(40, 23),
		"spawn": Vector2(60, 32), "target_cell": Vector2i(10, 7),
		"nodes": {"PowerScanner": Vector2(360, 152)},
		"towers": 0, "puzzles": 0, "enemies": 1, "wall_children": 21,
	},
	"communications": {
		"area": "محوطه‌ی مخابرات", "tile_rect": Rect2i(0, 0, 40, 12),
		"offset": Vector2i(40, 46),
		"spawn": Vector2(304, 24), "target_cell": Vector2i(15, 4),
		"nodes": {"YardRobot": Vector2(160, 104)},
		"towers": 0, "puzzles": 0, "enemies": 1, "wall_children": 15,
	},
}

var passed := 0
var failed := 0
var skipped := 0
var _level: Node2D = null


func _initialize() -> void:
	await run_tests()
	print("Results: %d passed, %d failed, %d skipped" % [passed, failed, skipped])
	quit(1 if failed > 0 else 0)


func assert_eq(actual, expected, label: String) -> void:
	if actual == expected:
		passed += 1
		print("PASS %s" % label)
	else:
		failed += 1
		push_error("FAIL %s: expected %s, got %s" % [label, expected, actual])


func assert_true(value: bool, label: String) -> void:
	assert_eq(value, true, label)


func run_tests() -> void:
	await process_frame
	for t in ["test_command_center_standalone", "test_medical_wing_standalone",
			"test_laboratory_standalone", "test_engine_room_standalone",
			"test_communications_standalone", "test_assembled_level_keeps_positions",
			"test_room_play_scene_loads", "test_standalone_room_fixes",
			"test_rooms_are_local", "test_exits_pair_up",
			"test_station_layout_agrees_with_rooms",
			"test_medical_note_consoles", "test_medical_scanner_tuning"]:
		paused = false
		var v = await call(t)
		if v == true:
			passed += 1
			print("PASS %s" % t)
		else:
			failed += 1
			push_error("FAIL %s: did not return true (runtime error?)" % t)


func _count_in_subtree(group_name: String, ancestor: Node) -> int:
	var n := 0
	for node in get_nodes_in_group(group_name):
		if ancestor.is_ancestor_of(node):
			n += 1
	return n


func _get_level() -> Node2D:
	if _level == null:
		var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
		_level = scene.instantiate()
		root.add_child(_level)
		# No await here: the level builds everything in _ready, which
		# runs synchronously on add_child — and awaiting a frame would
		# let the patrolling robots walk away from their spawn points
		# before the position checks below.
	return _level


func _test_room_standalone(room_key: String) -> bool:
	var check: Dictionary = ROOM_CHECKS[room_key]
	if not ResourceLoader.exists(ROOM_SCENES[room_key]):
		skipped += 1
		print("SKIP %s: scene not split yet" % room_key)
		return true
	var play_scene: PackedScene = load(PLAY_SCENES[room_key])
	var play: Node2D = play_scene.instantiate()
	root.add_child(play)
	# No await: the room builds and wires in _ready (synchronous on
	# add_child), and a frame would let its robot walk off its spawn.
	var room: Node2D = play.room
	var tile_rect: Rect2i = check["tile_rect"]
	# Standalone floor: exactly the room's tile rect, no more, no less.
	var floor_layer: TileMapLayer = room.get_node_or_null("Floor")
	assert_true(floor_layer != null, "%s standalone floor exists" % room_key)
	if floor_layer != null:
		assert_eq(floor_layer.get_used_cells().size(), tile_rect.get_area(), "%s floor covers its tile rect" % room_key)
	# Expected nodes at their exact positions.
	for node_name in (check["nodes"] as Dictionary).keys():
		var node: Node2D = room.get_node_or_null(node_name)
		assert_true(node != null, "%s has %s" % [room_key, node_name])
		if node != null:
			assert_eq(node.global_position, check["nodes"][node_name], "%s %s position" % [room_key, node_name])
	# Code-built walls: one body, 3 children per rect.
	var wall_body: Node = room.get_node_or_null("Walls_" + room_key)
	assert_true(wall_body != null, "%s wall body exists" % room_key)
	if wall_body != null:
		assert_eq(wall_body.get_child_count(), check["wall_children"], "%s wall children" % room_key)
	# Central keeps its .tscn ring + alcove walls.
	if room_key == "command_center":
		assert_true(room.get_node_or_null("Walls") != null, "command_center keeps tscn Walls")
		assert_true(room.get_node_or_null("AlcoveWalls") != null, "command_center keeps AlcoveWalls")
	# Entry zone carries the area name.
	var zone: Area2D = room.get_node_or_null("AreaZone_" + str(check["area"]).replace(" ", ""))
	assert_true(zone != null, "%s zone exists" % room_key)
	if zone != null:
		assert_eq(str(zone.get_meta("area_name")), check["area"], "%s zone meta" % room_key)
	# Wiring: player spawned in the room, area set, groups scoped.
	assert_eq(play.player.global_position, check["spawn"], "%s player spawn" % room_key)
	assert_eq(play.current_area, check["area"], "%s current area" % room_key)
	assert_eq(_count_in_subtree("towers", room), check["towers"], "%s towers in room" % room_key)
	assert_eq(_count_in_subtree("puzzles", room), check["puzzles"], "%s puzzles in room" % room_key)
	assert_eq(_count_in_subtree("enemies", room), check["enemies"], "%s enemies in room" % room_key)
	# Robot patrol stays inside the room.
	for enemy in get_nodes_in_group("enemies"):
		if not room.is_ancestor_of(enemy):
			continue
		for p in enemy.patrol_points:
			assert_true((room.room_rect as Rect2).has_point(p), "%s patrol point in room" % room_key)
	# Nav: a path exists from the spawn cell to a walkable target cell.
	var spawn_cell := Vector2i(int((check["spawn"] as Vector2).x / 16), int((check["spawn"] as Vector2).y / 16))
	var path: Array = play.nav_grid.get_id_path(spawn_cell, check["target_cell"])
	assert_true(path.size() > 0, "%s nav path from spawn" % room_key)
	# Standalone grid agrees with the assembled level's grid, cell for
	# cell: the standalone cell is LOCAL, the assembled cell is the
	# same cell translated by the room's station offset.
	var level: Node2D = _get_level()
	var level_grid: AStarGrid2D = level.get("_nav_grid")
	var offset: Vector2i = check["offset"]
	var mismatch := 0
	for x in range(tile_rect.position.x, tile_rect.end.x):
		for y in range(tile_rect.position.y, tile_rect.end.y):
			if play.nav_grid.is_point_solid(Vector2i(x, y)) != level_grid.is_point_solid(Vector2i(x, y) + offset):
				mismatch += 1
	assert_eq(mismatch, 0, "%s standalone grid matches assembled grid" % room_key)
	play.queue_free()
	await process_frame
	await process_frame
	return true


func test_command_center_standalone() -> bool:
	return await _test_room_standalone("command_center")


func test_medical_wing_standalone() -> bool:
	return await _test_room_standalone("medical_wing")


func test_laboratory_standalone() -> bool:
	return await _test_room_standalone("laboratory")


func test_engine_room_standalone() -> bool:
	return await _test_room_standalone("engine_room")


func test_communications_standalone() -> bool:
	return await _test_room_standalone("communications")


## Local-coordinate contract: every room's own rect starts at (0, 0),
## its spawn sits inside it, and every exit it declares is one of its
## doorway gaps (the launcher seals exactly those gaps standalone).
func test_rooms_are_local() -> bool:
	for room_key in ROOM_CHECKS.keys():
		var check: Dictionary = ROOM_CHECKS[room_key]
		var room = load(ROOM_SCENES[room_key]).instantiate()
		root.add_child(room)
		assert_eq(room.room_rect.position, Vector2.ZERO, "%s room_rect starts at (0, 0)" % room_key)
		assert_eq(room.room_tile_rect.position, Vector2i.ZERO, "%s room_tile_rect starts at (0, 0)" % room_key)
		assert_true((room.room_rect as Rect2).has_point(room.spawn_point), "%s spawn is inside its own rect" % room_key)
		assert_eq(room.spawn_point, check["spawn"], "%s spawn is the local spawn" % room_key)
		var gaps: Array[Rect2] = room.doorway_gap_rects()
		for exit in room.exits():
			assert_true((exit["rect"] as Rect2) in gaps, "%s exit %s is a doorway gap" % [room_key, str(exit["id"])])
		room.queue_free()
		await process_frame
		await process_frame
	return true


## Exits pair up: for every exit, the neighbour's matching exit lands
## on the same world rect once both rooms sit at their station offsets.
func test_exits_pair_up() -> bool:
	var world_exits := {}
	for room_key in ROOM_CHECKS.keys():
		var check: Dictionary = ROOM_CHECKS[room_key]
		var offset_px := Vector2(check["offset"]) * 16.0
		var room = load(ROOM_SCENES[room_key]).instantiate()
		root.add_child(room)
		for exit in room.exits():
			var r: Rect2 = exit["rect"]
			world_exits["%s:%s" % [room_key, str(exit["id"])]] = Rect2(r.position + offset_px, r.size)
		room.queue_free()
		await process_frame
		await process_frame
	for room_key in ROOM_CHECKS.keys():
		var room = load(ROOM_SCENES[room_key]).instantiate()
		root.add_child(room)
		for exit in room.exits():
			var target_key := "%s:%s" % [str(exit["target_room"]), str(exit["target_exit"])]
			assert_true(world_exits.has(target_key), "%s exit %s has a target exit" % [room_key, str(exit["id"])])
			if world_exits.has(target_key):
				var offset_px := Vector2((ROOM_CHECKS[room_key] as Dictionary)["offset"]) * 16.0
				var r: Rect2 = exit["rect"]
				assert_eq(Rect2(r.position + offset_px, r.size), world_exits[target_key], "%s exit %s coincides with its pair" % [room_key, str(exit["id"])])
		room.queue_free()
		await process_frame
		await process_frame
	return true


func _rect_set(rects: Array) -> Dictionary:
	var s := {}
	for r in rects:
		s[r] = true
	return s


## The station layout in LevelData agrees with the rooms: the union of
## the rooms' translated wall rects is AREA_WALL_RECTS minus the two
## south-west-quarter walls no room owns, and the translated prop
## rects are PROP_SOLID_RECTS plus Central's crate (which the global
## list never contained — it lives in command_center's blocked rects).
func test_station_layout_agrees_with_rooms() -> bool:
	var level: Node2D = _get_level()
	var walls := _rect_set(level.get("_instanced_wall_rects_cache"))
	var expected_walls := _rect_set(LevelData.AREA_WALL_RECTS)
	expected_walls.erase(Rect2(0, 736, 16, 192))
	expected_walls.erase(Rect2(0, 920, 640, 16))
	assert_eq(walls.size(), expected_walls.size(), "room wall count agrees with AREA_WALL_RECTS")
	for r in walls.keys():
		assert_true(expected_walls.has(r), "room wall %s is in AREA_WALL_RECTS" % str(r))
	var props := _rect_set(level.get("_instanced_prop_cache"))
	var expected_props := _rect_set(LevelData.PROP_SOLID_RECTS)
	expected_props[Rect2(160, 80, 16, 16)] = true
	assert_eq(props.size(), expected_props.size(), "room prop count agrees with PROP_SOLID_RECTS")
	for r in props.keys():
		assert_true(expected_props.has(r), "room prop %s is in PROP_SOLID_RECTS" % str(r))
	return true


## The assembled level keeps every room's key nodes at their exact
## positions, whether the room is split yet or still built by legacy code.
## Uses a FRESH level instance and checks synchronously (no await):
## the cached level has already run physics frames, and its patrolling
## robots have walked off their spawn points by then.
func test_assembled_level_keeps_positions() -> bool:
	if _level != null:
		_level.queue_free()
		_level = null
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	_level = level
	for room_key in ROOM_CHECKS.keys():
		var check: Dictionary = ROOM_CHECKS[room_key]
		# Assembled, a node sits at its LOCAL position plus the
		# room's station offset in pixels.
		var offset_px := Vector2(check["offset"]) * 16.0
		for node_name in (check["nodes"] as Dictionary).keys():
			var node: Node2D = level.get_node_or_null(node_name)
			assert_true(node != null, "assembled level has %s" % node_name)
			if node != null:
				assert_eq(node.global_position, (check["nodes"][node_name] as Vector2) + offset_px, "assembled %s position" % node_name)
	# No duplicates from the split: one textured wall visual per
	# AREA_WALL_RECTS rect, and exactly 5 area zones.
	var walls: StaticBody2D = level.get_node("AreaWalls")
	var visuals := 0
	for child in walls.get_children():
		if child is Polygon2D and (child as Polygon2D).texture != null:
			visuals += 1
	assert_eq(visuals, LevelData.AREA_WALL_RECTS.size(), "assembled AreaWalls has one textured wall visual per AREA_WALL_RECTS rect")
	var zones := 0
	for child in level.get_children():
		if child is Area2D and child.name.begins_with("AreaZone_"):
			zones += 1
	assert_eq(zones, 5, "assembled level has exactly 5 area zones")
	# All five area zones exist with their area names.
	for area in ["کنترل مرکزی", "بخش پزشکی", "آزمایشگاه تحقیقاتی", "نیروگاه", "محوطه‌ی مخابرات"]:
		var zone: Area2D = level.get_node_or_null("AreaZone_" + area.replace(" ", ""))
		assert_true(zone != null, "assembled zone %s" % area)
	return true


func test_room_play_scene_loads() -> bool:
	for room_key in PLAY_SCENES.keys():
		var scene: PackedScene = load(PLAY_SCENES[room_key])
		assert_true(scene != null, "play_%s.tscn loads" % room_key)
		var play: Node2D = scene.instantiate()
		root.add_child(play)
		assert_true(play.room != null, "play_%s builds its room" % room_key)
		assert_eq(play.room.room_key, room_key, "play_%s room key" % room_key)
		play.queue_free()
		await process_frame
		await process_frame
	return true


## Regression tests for the six room bugs found by live debugging
## (2026-11-19): twin players, towers never powering standalone,
## open map edges, caught respawn outside the room, open doorway gaps
## in standalone, and through-wall interaction.
func test_standalone_room_fixes() -> bool:
	# A cached assembled level from the earlier tests would pollute
	# the global "interactable" group — its switches sit at the same
	# coordinates as the room's, and the player would flip the
	# level's panel instead of the room's. Free it first; _get_level()
	# rebuilds a fresh one for the edge checks below.
	if _level != null:
		_level.queue_free()
		_level = null
		await process_frame
		await process_frame
	# Twin players (F): standalone Central has exactly one player
	# and one Mission — the room's own, re-used by the launcher.
	var play_scene: PackedScene = load(PLAY_SCENES["command_center"])
	var play: Node2D = play_scene.instantiate()
	root.add_child(play)
	var players := 0
	for node in get_nodes_in_group("player"):
		if play.is_ancestor_of(node):
			players += 1
	assert_eq(players, 1, "standalone command_center has exactly one player")
	assert_true(play.mission == play.room.get_node("Mission"), "launcher re-uses the room's Mission")
	# Towers power standalone (A): solve all three puzzles and the
	# mission reaches the transmit stage.
	var panel: StaticBody2D = play.room.get_node("BreakerPanel")
	var player: CharacterBody2D = play.player
	for pos in [Vector2(64, 204), Vector2(64, 180), Vector2(64, 228)]:
		player.global_position = pos
		for i in 5:
			await physics_frame
		Input.action_press("interact")
		for i in 3:
			await physics_frame
		Input.action_release("interact")
	assert_true(panel.is_solved, "standalone breaker solves")
	assert_true((play.room.get_node("Tower1") as StaticBody2D).power_restored, "standalone Tower1 powers on")
	var wire: StaticBody2D = play.room.get_node("WirePanel")
	for round in 2:
		for pos in [Vector2(576, 180), Vector2(576, 204), Vector2(576, 228)]:
			player.global_position = pos
			for i in 5:
				await physics_frame
			Input.action_press("interact")
			for i in 3:
				await physics_frame
			Input.action_release("interact")
	assert_true(wire.is_solved, "standalone wire panel solves")
	assert_true((play.room.get_node("Tower2") as StaticBody2D).power_restored, "standalone Tower2 powers on")
	var box: StaticBody2D = play.room.get_node("FuseBox")
	player.add_item("fuse", 1, 0.0)
	player.global_position = Vector2(320, 312)
	for i in 5:
		await physics_frame
	Input.action_press("interact")
	for i in 3:
		await physics_frame
	Input.action_release("interact")
	assert_true(box.is_solved, "standalone fuse box solves with a fuse")
	assert_true((play.room.get_node("Tower3") as StaticBody2D).power_restored, "standalone Tower3 powers on")
	# Powered is not active: each tower needs E once powered (the
	# mission only reaches the transmit stage after all three).
	for tower_pos in [Vector2(80, 80), Vector2(288, 48), Vector2(448, 320)]:
		player.global_position = tower_pos
		for i in 5:
			await physics_frame
		Input.action_press("interact")
		for i in 3:
			await physics_frame
		Input.action_release("interact")
	for tower_name in ["Tower1", "Tower2", "Tower3"]:
		assert_true((play.room.get_node(tower_name) as StaticBody2D).is_active, "standalone %s activates" % tower_name)
	assert_true(play.mission.try_transmit(), "standalone command_center is winnable")
	play.queue_free()
	await process_frame
	await process_frame
	# Doorway seals (D): every room seals its gaps in standalone
	# (3 children per sealed rect: shape + visual + highlight).
	for key in ["command_center", "medical_wing", "laboratory", "engine_room", "communications"]:
		var p: Node2D = load(PLAY_SCENES[key]).instantiate()
		root.add_child(p)
		var rbase = p.room
		var gaps: Array[Rect2] = rbase.doorway_gap_rects()
		var seal: Node = p.room.get_node_or_null("WallsSeal_" + key)
		assert_true(seal != null, "%s doorway seal exists" % key)
		if seal != null:
			assert_eq(seal.get_child_count(), gaps.size() * 3, "%s seal children" % key)
		p.queue_free()
		await process_frame
		await process_frame
	# Caught respawn (C): standalone Medical respawns inside its room.
	var med: Node2D = load(PLAY_SCENES["medical_wing"]).instantiate()
	root.add_child(med)
	var med_wiring = med.wiring
	med_wiring._on_player_caught()
	assert_eq(med.player.global_position, Vector2(64, 256), "caught player respawns at the medical spawn")
	med.queue_free()
	await process_frame
	await process_frame
	# Map edges (B): the two missing outer walls are solid in the
	# assembled grid — north row above Medical, west column of the Lab.
	var level: Node2D = _get_level()
	var grid: AStarGrid2D = level.get("_nav_grid")
	assert_true(grid.is_point_solid(Vector2i(50, 0)), "assembled grid: medical north edge is solid")
	assert_true(grid.is_point_solid(Vector2i(0, 30)), "assembled grid: laboratory west edge is solid")
	# Through-wall interact (E1): the FuseBox is 39 px from the lab
	# side of the divider — in range, but behind a wall.
	var fuse: Node2D = level.get_node("FuseBox")
	var lplayer: CharacterBody2D = level.get_node("Player")
	lplayer.global_position = Vector2(320, 375)
	for i in 5:
		await physics_frame
	assert_true(lplayer.global_position.distance_to(fuse.global_position) < 40.0, "player is within interact range of the fuse box")
	assert_true(lplayer.get("_current_interactable") == null, "fuse box is not interactable through the wall")
	return true


## Medical Wing story notes (P1, 2026-11-23, port of old steps 1-2),
## standalone via play_medical_wing.tscn, LOCAL coordinates. ROOM_CHECKS
## already pins the three positions (standalone and assembled); this pins
## what it cannot: the HUD texts, the doctor's-note sprite and the "read
## note" prompt, the placement rules (not inside a wall or a solid prop,
## clear of both doorway approaches and of the scanner's line of sight,
## far enough apart that the nearest-interactable pick is never
## ambiguous) and reachability: standing beside a note makes it the
## player's current interactable, and E uses it once.
func test_medical_note_consoles() -> bool:
	if not ResourceLoader.exists(ROOM_SCENES["medical_wing"]):
		skipped += 1
		print("SKIP medical note consoles: scene not split yet")
		return true
	# A cached assembled level holds the same consoles (offset by the
	# room's station position) and the player's nearest-interactable pick
	# could land on them instead (same reason as
	# test_standalone_room_fixes): free it.
	if _level != null:
		_level.queue_free()
		_level = null
		await process_frame
		await process_frame
	# NoteConsole2 lies ON the doctor's desk: it is a child of the desk's
	# body (so the player's line-of-sight ray ignores that body) and the
	# only one allowed to overlap a solid, and only the desk's own rect.
	var notes := [
		{
			"name": "NoteConsole1", "path": "NoteConsole1", "stand": Vector2(140, 296),
			"text": "یادداشت پزشک ایستگاه: هیچ بیماری‌ای در کار نیست. دستور اومد این بخش رو ببندیم.",
		},
		{
			"name": "NoteConsole2", "path": "MedDeskDoctor/NoteConsole2", "on_desk": true,
			"stand": Vector2(470, 262),
			"text": "یادداشت پزشک ایستگاه: هر بار پیام می‌فرستادیم، یه چیزی جوابمون رو می‌داد.",
		},
		{
			"name": "NoteConsole3", "path": "NoteConsole3", "stand": Vector2(536, 160),
			"text": "یادداشت پزشک ایستگاه: هر سیگنالی که بفرستیم، فقط ما رو نجات نمی‌ده.",
		},
	]
	var play: Node2D = load(PLAY_SCENES["medical_wing"]).instantiate()
	root.add_child(play)
	var room: Node2D = play.room
	var player: CharacterBody2D = play.player
	var note_tex: Texture2D = load("res://assets/sprites/medical-wing/note_doctor.png")
	var solids: Array[Rect2] = room.blocked_rects()
	var desk_rect := Rect2(424, 248, 32, 16)
	assert_true(solids.has(desk_rect), "the doctor's desk is one of the solid rects")
	assert_true(room.get_node_or_null("MedNoteDoctor") == null, "the inert desk note decor is gone")
	# Keep-out zones: the west doorway's entry corridor (y 240-272,
	# x 0-160) and the south gap's approach (x 288-320), each with a
	# margin, and the scanner's line of sight (x=260, y 120-200).
	var keep_out: Array[Rect2] = [
		Rect2(0, 224, 160, 64), Rect2(272, 288, 64, 64), Rect2(232, 100, 56, 120),
	]
	# Console centres for the spacing check; the area console is first.
	var centers: Array[Vector2] = [Vector2(120, 80)]
	for note in notes:
		var label: String = note["name"]
		var console: Node2D = room.get_node_or_null(str(note["path"]))
		assert_true(console != null, "%s exists" % label)
		if console == null:
			continue
		assert_true(console.is_in_group("interactable"), "%s is an interactable" % label)
		assert_eq(console.message, note["text"], "%s message text" % label)
		assert_eq((console.get_node("Sprite2D") as Sprite2D).texture, note_tex, "%s uses the doctor's note sprite" % label)
		assert_eq(console.interact_label, "خواندن یادداشت", "%s prompt says read note" % label)
		var rect := Rect2(console.global_position - Vector2(8, 8), Vector2(16, 16))
		var in_solid := false
		for r in solids:
			if note.get("on_desk", false) and r == desk_rect:
				continue
			if rect.intersects(r):
				in_solid = true
		assert_true(not in_solid, "%s is not inside a wall or a solid prop (bar the desk it lies on)" % label)
		var in_keep_out := false
		for r in keep_out:
			if rect.intersects(r):
				in_keep_out = true
		assert_true(not in_keep_out, "%s is clear of the doorways and the scanner's line of sight" % label)
		centers.append(console.global_position)
		# Reachable: beside it, it is the nearest interactable; E uses it
		# once. (For the desk note this is what pins the parenting: a
		# console left at room level inside the desk's solid rect would be
		# blocked by the desk body in the line-of-sight ray.)
		player.global_position = note["stand"]
		player.velocity = Vector2.ZERO
		for i in 5:
			await physics_frame
		assert_true(player._current_interactable == console, "%s is the nearest interactable when standing beside it" % label)
		Input.action_press("interact")
		for i in 3:
			await physics_frame
		Input.action_release("interact")
		assert_eq(console.use_count, 1, "%s used once after E" % label)
	var spaced := true
	for i in centers.size():
		for j in range(i + 1, centers.size()):
			if centers[i].distance_to(centers[j]) < 48.0:
				spaced = false
	assert_true(spaced, "note consoles and the area console are 48+ px apart")
	play.queue_free()
	await process_frame
	await process_frame
	return true


## Medical Wing scanner (P1, 2026-11-23, port of old step 2): easier to
## evade than the default scanner scene (detection_radius 180,
## vision_half_angle 1.2), through instance overrides in
## medical_wing.tscn only.
func test_medical_scanner_tuning() -> bool:
	if not ResourceLoader.exists(ROOM_SCENES["medical_wing"]):
		skipped += 1
		print("SKIP medical scanner tuning: scene not split yet")
		return true
	var play: Node2D = load(PLAY_SCENES["medical_wing"]).instantiate()
	root.add_child(play)
	var scanner: CharacterBody2D = play.room.get_node_or_null("ScannerRobot")
	assert_true(scanner != null, "medical wing scanner exists")
	if scanner != null:
		assert_eq(scanner.detection_radius, 120.0, "medical wing scanner detection radius is 120")
		assert_eq(scanner.vision_half_angle, 0.8, "medical wing scanner vision half-angle is 0.8")
	play.queue_free()
	await process_frame
	await process_frame
	return true
