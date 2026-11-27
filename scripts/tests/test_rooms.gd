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
			# Power puzzle (P4, 2026-11-25; P5, 2026-11-26): the fuse box
			# (where the P3 placeholder switch stood), the visible fuse
			# pickup (moved into the dark zone in P5) and the visible
			# flashlight pickup, the desk's own MedFlashlight since P6 (a
			# child of the desk's body, where the decor lay).
			"MedFuseBox": Vector2(590, 44),
			"MedFusePickup": Vector2(356, 64),
			"MedDeskDoctor/MedFlashlight": Vector2(432, 252),
			# Medical Recovery (P6, 2026-11-26): the code cabinet (an
			# interactable child of the MedCabinetWorn prop) and its three
			# dials, dial 1 on the right. The medicine only appears when the
			# cabinet opens.
			"MedCabinetWorn/MedCabinet": Vector2(540, 320),
			"MedCabinetWorn/MedCabinet/MedDial1": Vector2(560, 300),
			"MedCabinetWorn/MedCabinet/MedDial2": Vector2(540, 300),
			"MedCabinetWorn/MedCabinet/MedDial3": Vector2(520, 300),
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

## Robot states (security_robot_medical_wing.gd State enum), as in test_runner.gd.
const E_PATROL := 0
const E_CHASE := 2

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
			"test_medical_note_consoles", "test_medical_scanner_tuning",
			"test_medical_darkness_standalone", "test_medical_darkness_assembled",
			"test_medical_flicker", "test_medical_cabinet", "test_medical_flashlight",
			"test_medical_robots_dormant", "test_medical_fuse_puzzle",
			"test_medical_fuse_full_game", "test_medical_cone_readability"]:
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
			"text": "یادداشت پزشک: هیچ بیماری‌ای نیست. دستور اومد بخش رو ببندیم.",
			"digit": "۴",
		},
		{
			"name": "NoteConsole2", "path": "MedDeskDoctor/NoteConsole2", "on_desk": true,
			"stand": Vector2(470, 262),
			"text": "یادداشت پزشک: هر بار پیام می‌فرستادیم، یه چیزی جواب می‌داد.",
			"digit": "۱",
		},
		{
			"name": "NoteConsole3", "path": "NoteConsole3", "stand": Vector2(536, 160),
			"text": "یادداشت پزشک: هر سیگنالی که بفرستیم، فقط ما رو نجات نمی‌ده.",
			"digit": "۷",
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
	# The code digits (P6): one per note, appended to the message in code and
	# NOT part of the text constants.
	var room_script: GDScript = room.get_script()
	assert_eq(room_script.NOTE_DIGITS, [4, 1, 7], "the code digits are 4 1 7, one per note")
	# Keep-out zones: the west doorway's entry corridor (y 240-272,
	# x 0-160) and the south gap's approach (x 288-320), each with a
	# margin, and the scanner's line of sight (x=260, y 120-200).
	var keep_out: Array[Rect2] = [
		Rect2(0, 224, 160, 64), Rect2(272, 288, 64, 64), Rect2(232, 100, 56, 120),
	]
	# Console centres for the spacing check; the area console is first.
	var centers: Array[Vector2] = [Vector2(120, 80)]
	for n in notes.size():
		var note: Dictionary = notes[n]
		var label: String = note["name"]
		var console: Node2D = room.get_node_or_null(str(note["path"]))
		assert_true(console != null, "%s exists" % label)
		if console == null:
			continue
		assert_true(console.is_in_group("interactable"), "%s is an interactable" % label)
		assert_eq(console.message, note["text"] + "  (رمز: " + note["digit"] + ")", "%s message is its text plus the code digit" % label)
		assert_true(console.message.length() <= 72, "%s message fits the HUD (72 characters at most)" % label)
		assert_eq(room_script.NOTE_CONSOLES[n]["text"], note["text"], "%s text constant holds no code digit" % label)
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


## Medical Wing darkness (P2, 2026-11-24; reworked in P5, 2026-11-26),
## standalone room: LOCAL coordinates, the darkness node sits at (0, 0).
## The wing runs on emergency power: lit at spawn, one permanently dark
## zone, a light circle around the player (tiny without the "flashlight"
## item, 70 screen px with it). Everything goes through
## MedicalDarkness.step(delta), so the test is deterministic: no frame
## passes between a position change and its check (the node's own _process
## only runs during awaits). The flicker is switched off here;
## test_medical_flicker covers it.
func test_medical_darkness_standalone() -> bool:
	if not ResourceLoader.exists(ROOM_SCENES["medical_wing"]):
		skipped += 1
		print("SKIP medical darkness: scene not split yet")
		return true
	var play: Node2D = load(PLAY_SCENES["medical_wing"]).instantiate()
	root.add_child(play)
	var room: Node2D = play.room
	var player: CharacterBody2D = play.player
	var dark: Node2D = room.get_node_or_null("MedicalDarkness")
	assert_true(dark != null, "medical wing has a MedicalDarkness node")
	if dark == null:
		play.queue_free()
		await process_frame
		await process_frame
		return true
	var overlay: ColorRect = dark.get_node("Overlay")
	var material: ShaderMaterial = overlay.material
	var rect: Rect2 = room.room_rect
	var zone: Rect2 = room.dark_zone_rect()
	# The overlay covers exactly the medical room (local rect): no other
	# room is ever darkened. Shader and script live in the room's folders.
	assert_eq(Rect2(overlay.position, overlay.size), rect, "darkness overlay covers exactly the medical room")
	assert_eq(material.shader.resource_path, "res://scenes/levels/rooms/medical_wing/darkness_medical_wing.gdshader", "the darkness uses the room's own shader")
	assert_eq(dark.z_index, 100, "the darkness draws above the world (z_index 100)")
	assert_true(play.find_children("*", "CanvasModulate", true, false).is_empty(), "the standalone room has no CanvasModulate")
	# The dark zone: the north alcove, clear of solids, doorways and the
	# scanner's line of sight.
	assert_eq(zone, Rect2(296, 16, 120, 90), "the dark zone is the north alcove (296, 16, 120, 90)")
	assert_eq(dark.zone_rect, zone, "the darkness node holds the zone")
	assert_true(rect.encloses(zone), "the dark zone lies inside the room")
	assert_eq(material.get_shader_parameter("zone_rect"), Vector4(296, 16, 120, 90), "the shader gets the zone in px from the overlay's corner")
	var zone_hits := false
	for r in room.blocked_rects():
		if zone.intersects(r):
			zone_hits = true
	assert_true(not zone_hits, "the dark zone overlaps no wall or solid prop")
	var keep_hits := false
	for r in [Rect2(0, 224, 160, 64), Rect2(272, 288, 64, 64), Rect2(232, 100, 56, 120)]:
		if zone.intersects(r):
			keep_hits = true
	assert_true(not keep_hits, "the dark zone is clear of both doorway approaches and the scanner's line of sight")
	# Emergency power: lit at spawn; only the zone is dark.
	dark.flicker_enabled = false
	assert_true(not room.power_on, "the wing starts on emergency power: power_on is false")
	assert_true(not zone.has_point(player.global_position), "the player spawns outside the dark zone")
	dark.step(5.0)
	assert_true(not dark.is_flicker_dark() and is_equal_approx(dark.room_darkness(), 0.0), "no darkness at spawn: the room starts lit")
	assert_true(is_equal_approx(material.get_shader_parameter("room_darkness"), 0.0), "no whole-room darkness reaches the shader at spawn")
	assert_true(dark.player_inside(), "the player starts inside the room")
	assert_true(is_equal_approx(dark.zone_darkness(), 1.0), "the dark zone is fully dark once the player is in the room")
	assert_true(is_equal_approx(material.get_shader_parameter("zone_darkness"), 0.95), "the zone's opacity is 0.95 after the fade-in")
	assert_true(overlay.visible, "the overlay is shown for the dark zone")
	assert_eq(material.get_shader_parameter("light_center"), player.global_position, "the light is centred on the player")
	player.global_position = Vector2(500, 200)
	dark.step(0.0)
	assert_eq(material.get_shader_parameter("light_center"), Vector2(500, 200), "the light follows the player")
	# Inside the zone: a tiny circle (24 screen px) without the flashlight,
	# the soft 70 screen px circle with it. The radius is in SCREEN px, so
	# it reads the real zoom of the viewport's canvas transform (the player
	# camera zooms 2x).
	player.global_position = Vector2(356, 80)
	assert_true(zone.has_point(player.global_position), "the test player stands inside the dark zone")
	var saved_canvas: Transform2D = root.canvas_transform
	root.canvas_transform = Transform2D.IDENTITY.scaled(Vector2(2, 2))
	dark.step(0.0)
	assert_true(not dark.has_flashlight(), "the player starts without the flashlight")
	assert_true(is_equal_approx(material.get_shader_parameter("light_radius"), 12.0), "in the zone without the flashlight: a tiny circle, 12 world px at zoom 2 (24 screen px)")
	root.canvas_transform = Transform2D.IDENTITY
	dark.step(0.0)
	assert_true(is_equal_approx(material.get_shader_parameter("light_radius"), 24.0), "in the zone without the flashlight: 24 world px at zoom 1")
	player.inventory["flashlight"] = 1
	dark.step(0.0)
	assert_true(dark.has_flashlight(), "the flashlight item is seen in the inventory")
	assert_true(is_equal_approx(material.get_shader_parameter("light_radius"), 70.0), "in the zone with the flashlight: 70 world px at zoom 1 (70 screen px)")
	root.canvas_transform = Transform2D.IDENTITY.scaled(Vector2(2, 2))
	dark.step(0.0)
	assert_true(is_equal_approx(material.get_shader_parameter("light_radius"), 35.0), "in the zone with the flashlight: 35 world px at zoom 2")
	assert_true(is_equal_approx(material.get_shader_parameter("zone_darkness"), 0.95), "the zone is just as dark with the flashlight: the light changes, not the dark")
	player.inventory.erase("flashlight")
	root.canvas_transform = saved_canvas
	# Outside the room (west of the doorway): nothing is drawn.
	player.global_position = Vector2(-40, 256)
	dark.step(5.0)
	assert_true(not dark.player_inside(), "not inside while the player is west of the doorway")
	assert_true(is_equal_approx(dark.zone_darkness(), 0.0), "no darkness while the player is outside")
	assert_true(not overlay.visible, "the overlay is hidden while the player is outside")
	# The other three sides: inside first, then outside means no darkness.
	for outside in [Vector2(700, 200), Vector2(300, -40), Vector2(300, 420)]:
		player.global_position = room.spawn_point
		dark.step(5.0)
		player.global_position = outside
		dark.step(5.0)
		assert_true(not dark.player_inside() and not overlay.visible and is_equal_approx(dark.zone_darkness(), 0.0), "no darkness with the player outside the room at %s" % outside)
	# Back inside: the zone fades in over 0.25 s.
	player.global_position = room.spawn_point
	assert_true(dark.player_inside(), "inside again when the player comes back in")
	dark.step(0.125)
	assert_true(is_equal_approx(dark.zone_darkness(), 0.5), "the zone is half dark 0.125 s after entering")
	dark.step(0.125)
	assert_true(is_equal_approx(dark.zone_darkness(), 1.0), "the zone is fully dark 0.25 s after entering")
	# restore_power(): the local power stabilises. Signal once, flicker
	# stopped for good; the dark zone stays dark.
	var fired := [0]
	room.power_restored.connect(func() -> void: fired[0] += 1)
	dark.flicker_enabled = true
	room.restore_power()
	assert_true(room.power_on, "power_on is true after restore_power()")
	assert_true(dark.power_on, "the darkness node holds the power state")
	assert_eq(fired[0], 1, "power_restored is emitted once")
	assert_true(not dark.flicker_enabled, "restore_power() stops the flicker")
	dark.step(5.0)
	assert_true(is_equal_approx(dark.zone_darkness(), 1.0), "the dark zone stays dark after restore_power()")
	room.restore_power()
	assert_eq(fired[0], 1, "a second restore_power() does nothing")
	play.queue_free()
	await process_frame
	await process_frame
	return true


## Step `dark` by `dt` for `seconds` and return the flicker pulses that
## completed, as [start, end] pairs in seconds (edges are seen at step
## boundaries, so they are right to within dt). No frame passes.
func _flicker_pulses(dark: Node2D, seconds: float, dt: float) -> Array:
	var pulses: Array = []
	var t := 0.0
	var start := 0.0
	var was: bool = dark.is_flicker_dark()
	while t < seconds:
		dark.step(dt)
		t += dt
		var now: bool = dark.is_flicker_dark()
		if now and not was:
			start = t
		elif was and not now:
			pulses.append([start, t])
		was = now
	return pulses


## Group pulses into flicker events: pulses less than a second apart
## belong to the same event.
func _flicker_events(pulses: Array) -> Array:
	var events: Array = []
	for p in pulses:
		if not events.is_empty() and p[0] - events[-1][-1][1] < 1.0:
			events[-1].append(p)
		else:
			events.append([p])
	return events


## The seeded flicker of the emergency lights (P5, 2026-11-26), standalone
## room. Two fresh rooms run for 120 s of 1/60 s steps must give identical
## pulses (deterministic); the pulses must follow the spec — every 5-11 s
## an event of 1-3 pulses, each 0.12-0.3 s dark, a short lit gap between
## them; a pulse darkens the whole room (a light circle only with the
## flashlight) but only while the player is in it; restore_power() stops
## it for good. No frame passes between a node's creation and its stepping,
## so the node's own _process never moves the clock.
func test_medical_flicker() -> bool:
	if not ResourceLoader.exists(ROOM_SCENES["medical_wing"]):
		skipped += 1
		print("SKIP medical flicker: scene not split yet")
		return true
	var runs: Array = []
	for run in 2:
		var scene: Node2D = load(PLAY_SCENES["medical_wing"]).instantiate()
		root.add_child(scene)
		runs.append(_flicker_pulses(scene.room.get_node("MedicalDarkness"), 120.0, FLICKER_DT))
		scene.queue_free()
		await process_frame
		await process_frame
	var pulses: Array = runs[0]
	assert_eq(runs[0], runs[1], "two fresh rooms flicker identically (seeded, deterministic)")
	var events := _flicker_events(pulses)
	assert_true(events.size() >= 9, "at least 9 flicker events in 120 s (every 5-11 s)")
	assert_true(not pulses.is_empty() and pulses[0][0] >= 5.0 - FLICKER_DT and pulses[0][0] <= 11.0 + FLICKER_DT, "the first event starts 5-11 s in")
	var counts_ok := true
	var waits_ok := true
	var lengths_ok := true
	var gaps_ok := true
	for i in events.size():
		var event: Array = events[i]
		if event.size() < 1 or event.size() > 3:
			counts_ok = false
		for k in event.size():
			var length: float = event[k][1] - event[k][0]
			if length < 0.12 - FLICKER_DT or length > 0.30 + FLICKER_DT:
				lengths_ok = false
			if k > 0:
				var gap: float = event[k][0] - event[k - 1][1]
				if gap < 0.06 - FLICKER_DT or gap > 0.14 + FLICKER_DT:
					gaps_ok = false
		if i > 0:
			var wait: float = event[0][0] - events[i - 1][-1][1]
			if wait < 5.0 - FLICKER_DT or wait > 11.0 + FLICKER_DT:
				waits_ok = false
	assert_true(counts_ok, "every flicker event has 1-3 pulses")
	assert_true(waits_ok, "events are 5-11 s apart")
	assert_true(lengths_ok, "every pulse is dark for 0.12-0.3 s")
	assert_true(gaps_ok, "pulses of one event are 0.06-0.14 s apart")
	# One more room, this time looking at what a pulse does to the overlay.
	var play: Node2D = load(PLAY_SCENES["medical_wing"]).instantiate()
	root.add_child(play)
	var room: Node2D = play.room
	var player: CharacterBody2D = play.player
	var dark: Node2D = room.get_node("MedicalDarkness")
	var material: ShaderMaterial = dark.get_node("Overlay").material
	var saved_canvas: Transform2D = root.canvas_transform
	root.canvas_transform = Transform2D.IDENTITY.scaled(Vector2(2, 2))
	var first := 0.0
	while not dark.is_flicker_dark() and first < 20.0:
		dark.step(FLICKER_DT)
		first += FLICKER_DT
	assert_true(is_equal_approx(first, pulses[0][0]), "the third room's first pulse starts at the same moment")
	assert_true(dark.is_flicker_dark(), "a pulse is on")
	dark.step(0.02)
	assert_true(is_equal_approx(dark.room_darkness(), 1.0), "a pulse fully darkens the whole room")
	assert_true(is_equal_approx(material.get_shader_parameter("room_darkness"), 0.95), "the shader gets the whole-room opacity (0.95)")
	assert_true(is_equal_approx(material.get_shader_parameter("light_radius"), 0.0), "without the flashlight a pulse has no light circle at all")
	player.inventory["flashlight"] = 1
	dark.step(0.0)
	assert_true(is_equal_approx(material.get_shader_parameter("light_radius"), 35.0), "with the flashlight a pulse keeps the 70 screen px circle")
	player.inventory.erase("flashlight")
	player.global_position = Vector2(-40, 256)
	dark.step(0.025)
	assert_true(dark.is_flicker_dark() and is_equal_approx(dark.room_darkness(), 0.0), "a pulse is not drawn while the player is outside the room")
	player.global_position = room.spawn_point
	while dark.is_flicker_dark():
		dark.step(FLICKER_DT)
	dark.step(0.025)
	assert_true(not dark.is_flicker_dark() and is_equal_approx(dark.room_darkness(), 0.0), "the room is lit again after the pulse")
	root.canvas_transform = saved_canvas
	# The local power stabilises: no pulse ever again.
	room.restore_power()
	assert_true(not dark.flicker_enabled and not dark.is_flicker_dark(), "restore_power() stops the flicker")
	assert_true(_flicker_pulses(dark, 120.0, FLICKER_DT).is_empty(), "no pulse in 120 s after restore_power()")
	assert_true(is_equal_approx(dark.room_darkness(), 0.0), "the room stays lit after restore_power()")
	play.queue_free()
	await process_frame
	await process_frame
	return true


## Medical Wing darkness (P2; reworked in P5, 2026-11-26), full game: the
## level starts in command_center without darkness, walking east into the
## medical wing shows the dark zone (and, in a pulse, the whole wing),
## going back hides it. The assembler frees the MedicalWing node and moves
## its children into the level translated by (640, 0), so the live API is
## level.get_node("MedicalDarkness"), and it must keep working in WORLD
## coordinates (rect, zone, light, inside test).
func test_medical_darkness_assembled() -> bool:
	if not ResourceLoader.exists(ROOM_SCENES["medical_wing"]):
		skipped += 1
		print("SKIP medical darkness (assembled): scene not split yet")
		return true
	# A fresh level, so "starts in command_center" is the real start state.
	if _level != null:
		_level.queue_free()
		_level = null
		await process_frame
		await process_frame
	var level := _get_level()
	var dark: Node2D = level.get_node_or_null("MedicalDarkness")
	assert_true(dark != null, "the assembled level keeps MedicalDarkness at level.get_node(...)")
	if dark == null:
		return true
	var overlay: ColorRect = dark.get_node("Overlay")
	var material: ShaderMaterial = overlay.material
	# After the flatten the node sits in the level at the wing's offset and
	# its overlay covers the wing's WORLD rect.
	assert_eq(dark.get_parent(), level, "MedicalDarkness is a direct child of the level after the flatten")
	assert_eq(dark.global_position, Vector2(640, 0), "the flatten moved it by the medical wing's station offset")
	assert_eq(Rect2(overlay.global_position, overlay.size), Rect2(640, 0, 640, 368), "the overlay covers exactly the medical wing in world coordinates")
	assert_true(level.find_children("*", "CanvasModulate", true, false).is_empty(), "the level has no global CanvasModulate")
	assert_eq(Rect2(dark.to_global(dark.zone_rect.position), dark.zone_rect.size), Rect2(936, 16, 120, 90), "the dark zone sits at its local spot plus the wing's offset")
	assert_true(not dark.player_inside(), "the full game starts outside the wing (command_center)")
	dark.step(5.0)
	assert_true(is_equal_approx(dark.zone_darkness(), 0.0) and is_equal_approx(dark.room_darkness(), 0.0), "no darkness of either kind at the start of the full game")
	assert_true(not overlay.visible, "the overlay is hidden at the start of the full game")
	# Into the wing, flicker off: the zone is dark, the rest of the wing lit.
	dark.flicker_enabled = false
	level.player.global_position = Vector2(900, 200)
	dark.step(5.0)
	assert_true(dark.player_inside(), "walking east into the medical wing counts as inside")
	assert_true(is_equal_approx(dark.zone_darkness(), 1.0), "the dark zone is dark inside the medical wing")
	assert_true(is_equal_approx(dark.room_darkness(), 0.0), "the rest of the wing is lit: no whole-room darkness")
	assert_true(overlay.visible, "the overlay is shown inside the medical wing")
	assert_eq(material.get_shader_parameter("light_center"), Vector2(260, 200), "the light is at the player's spot in wing px (world 900 - 640, 200)")
	assert_true(not dark.zone_rect.has_point(dark.to_local(Vector2(900, 200))), "world (900, 200) is outside the dark zone")
	level.player.global_position = Vector2(996, 80)
	dark.step(0.0)
	assert_true(dark.zone_rect.has_point(dark.to_local(level.player.global_position)), "world (996, 80) is inside the dark zone")
	assert_eq(material.get_shader_parameter("light_center"), Vector2(356, 80), "the light follows the player into the zone, in wing px")
	var tiny: float = material.get_shader_parameter("light_radius")
	level.player.inventory["flashlight"] = 1
	dark.step(0.0)
	var wide: float = material.get_shader_parameter("light_radius")
	assert_true(is_equal_approx(wide / tiny, 70.0 / 24.0), "in the full game the flashlight widens the light from 24 to 70 screen px")
	level.player.inventory.erase("flashlight")
	# The wing's world rect (640, 0, 640, 368): corners just inside are
	# inside, points just outside each side are not.
	for inside in [Vector2(641, 2), Vector2(1279, 2), Vector2(641, 366), Vector2(1279, 366)]:
		level.player.global_position = inside
		assert_true(dark.player_inside(), "inside just inside the wing's corner at %s" % inside)
	for outside in [Vector2(639, 200), Vector2(1281, 200), Vector2(900, -2), Vector2(900, 370)]:
		level.player.global_position = outside
		assert_true(not dark.player_inside(), "never inside just outside the wing at %s" % outside)
	level.player.global_position = Vector2(320, 184)
	dark.step(5.0)
	assert_true(not dark.player_inside() and is_equal_approx(dark.zone_darkness(), 0.0), "back in command_center there is no darkness")
	assert_true(not overlay.visible, "the overlay is hidden again in command_center")
	# A flicker pulse darkens the whole wing, but only for a player inside.
	dark.flicker_enabled = true
	var waited := 0.0
	while not dark.is_flicker_dark() and waited < 20.0:
		dark.step(FLICKER_DT)
		waited += FLICKER_DT
	assert_true(dark.is_flicker_dark() and is_equal_approx(dark.room_darkness(), 0.0), "a pulse is not drawn while the player is in command_center")
	level.player.global_position = Vector2(900, 200)
	dark.step(0.02)
	assert_true(is_equal_approx(material.get_shader_parameter("room_darkness"), 0.95), "a pulse darkens the whole wing for a player inside it")
	# The local power stabilises: restore_power() on the surviving node.
	var fired := [0]
	dark.power_restored.connect(func() -> void: fired[0] += 1)
	dark.restore_power()
	assert_true(dark.power_on and not dark.flicker_enabled and not dark.is_flicker_dark(), "restore_power() on the node stops the flicker")
	assert_true(_flicker_pulses(dark, 60.0, FLICKER_DT).is_empty(), "no pulse in 60 s after restore_power() in the full game")
	dark.step(5.0)
	assert_true(is_equal_approx(dark.zone_darkness(), 1.0) and is_equal_approx(dark.room_darkness(), 0.0), "after restore_power() the zone stays dark and the rest of the wing lit")
	assert_eq(fired[0], 1, "power_restored is emitted once in the full game")
	dark.restore_power()
	assert_eq(fired[0], 1, "a second restore_power() does nothing in the full game")
	_level.queue_free()
	_level = null
	await process_frame
	await process_frame
	return true


## The Persian digits 0-9 in order (what the notes and the dials show).
const TEST_DIGITS := "۰۱۲۳۴۵۶۷۸۹"


## How many items with `item_id` are interactable pickups under `ancestor`.
func _count_item(item_id: String, ancestor: Node) -> int:
	var n := 0
	for node in get_nodes_in_group("interactable"):
		if ancestor.is_ancestor_of(node) and "item_id" in node and node.item_id == item_id:
			n += 1
	return n


## The code cabinet (P6, 2026-11-26), standalone room (a HUD is added first,
## the launcher has none): MedCabinetWorn keeps being a solid prop and gains
## the interactable child MedCabinet with three dials in front of it (dial 1
## on the right). E on a dial cycles its digit 0-9 and wraps, the HUD shows
## «کد: ...»; a wrong code changes nothing else; the right code (the note
## digits 4 1 7) opens the cabinet exactly once: cabinet_open sprite, «کابینت
## باز شد.», dials locked and out of the interactable group, ONE medicine
## pickup in front of it. Collecting it gives the "medicine" item and shows
## «درد کم شد. حالم بهتر شد.». The cabinet never gives a flashlight (the
## desk's MedFlashlight is the only one, see test_medical_flashlight).
func test_medical_cabinet() -> bool:
	if not ResourceLoader.exists(ROOM_SCENES["medical_wing"]):
		skipped += 1
		print("SKIP medical cabinet: scene not split yet")
		return true
	if _level != null:
		_level.queue_free()
		_level = null
		await process_frame
		await process_frame
	var hud: CanvasLayer = (load("res://scenes/ui/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	var play: Node2D = load(PLAY_SCENES["medical_wing"]).instantiate()
	root.add_child(play)
	var room: Node2D = play.room
	var player: CharacterBody2D = play.player
	var body: Node2D = room.get_node_or_null("MedCabinetWorn")
	var cabinet: Node2D = room.get_node_or_null("MedCabinetWorn/MedCabinet")
	assert_true(body != null and cabinet != null, "the cabinet prop MedCabinetWorn has the interactable child MedCabinet")
	if body == null or cabinet == null:
		play.queue_free()
		hud.queue_free()
		await process_frame
		await process_frame
		return true
	var dials: Array = cabinet.dials()
	assert_eq(dials.size(), 3, "the cabinet has three dials")
	if dials.size() != 3:
		play.queue_free()
		hud.queue_free()
		await process_frame
		await process_frame
		return true
	var worn_tex: Texture2D = load("res://assets/sprites/medical-wing/cabinet_worn.png")
	var open_tex: Texture2D = load("res://assets/sprites/medical-wing/cabinet_open.png")
	var prop_sprite: Sprite2D = null
	for child in body.get_children():
		if child is Sprite2D:
			prop_sprite = child
	# What it is.
	assert_true(room.blocked_rects().has(Rect2(532, 312, 16, 16)), "the cabinet prop is still a solid rect")
	assert_true(prop_sprite != null and prop_sprite.texture == worn_tex, "the closed cabinet shows the worn cabinet sprite")
	assert_true(cabinet.is_in_group("interactable") and not cabinet.is_in_group("puzzles") and not cabinet.is_in_group("hidden"), "the cabinet is an interactable, neither a puzzle nor hidden")
	assert_eq([str(dials[0].name), str(dials[1].name), str(dials[2].name)], ["MedDial1", "MedDial2", "MedDial3"], "the dials are MedDial1-3, dial 1 first")
	var dials_ok := true
	for d in dials:
		if not d.is_in_group("interactable") or d.is_in_group("puzzles") or d.is_in_group("hidden") or d.is_locked():
			dials_ok = false
	assert_true(dials_ok, "the three dials are unlocked interactables, neither puzzles nor hidden")
	assert_eq(cabinet.code_text(), "۰ ۰ ۰", "the dials start at 0 0 0")
	var room_script: GDScript = room.get_script()
	assert_eq(cabinet.code, room_script.NOTE_DIGITS, "the cabinet's code is the room's NOTE_DIGITS")
	assert_true(not cabinet.is_open, "the cabinet starts closed")
	assert_eq(_count_item("medicine", room), 0, "no medicine exists before the cabinet opens")
	assert_true(room.get_node_or_null("MedMedicinePickup") == null, "no medicine pickup lies around before the cabinet opens")
	# Placement: the dial plates (14 px) touch no wall or solid prop and sit
	# clear of the doorways and the scanner's line of sight, 20 px apart, and
	# well away from every console.
	var in_solid := false
	var in_keep_out := false
	var nearest_console := INF
	for d in dials:
		var rect := Rect2(d.global_position - Vector2(7, 7), Vector2(14, 14))
		for r in room.blocked_rects():
			if rect.intersects(r):
				in_solid = true
		for r in [Rect2(0, 224, 160, 64), Rect2(272, 288, 64, 64), Rect2(232, 100, 56, 120)]:
			if rect.intersects(r):
				in_keep_out = true
		for c in [Vector2(120, 80), room.get_node("NoteConsole1").global_position,
				room.get_node("MedDeskDoctor/NoteConsole2").global_position,
				room.get_node("NoteConsole3").global_position]:
			nearest_console = minf(nearest_console, d.global_position.distance_to(c))
	assert_true(not in_solid, "the dial plates touch no wall or solid prop")
	assert_true(not in_keep_out, "the dial plates are clear of the doorways and the scanner's line of sight")
	assert_true(nearest_console >= 78.0, "the dials are at least 78 px from every console")
	assert_true(dials[0].global_position.distance_to(dials[1].global_position) >= 20.0 and dials[1].global_position.distance_to(dials[2].global_position) >= 20.0, "neighbouring dials are at least 20 px apart")
	# Through the real player: beside a dial it is the nearest interactable,
	# E turns it once and the HUD shows the code.
	player.global_position = Vector2(560, 284)
	player.velocity = Vector2.ZERO
	for i in 5:
		await physics_frame
	assert_true(player._current_interactable == dials[0], "beside dial 1 it is the nearest interactable")
	assert_eq(hud.prompt_label.text, "E — چرخاندن رمز ۱", "the HUD prompt beside dial 1")
	await _press_interact()
	assert_eq(dials[0].digit, 1, "E turns dial 1 from 0 to 1")
	assert_eq(hud.message_label.text, "کد: ۱ ۰ ۰", "the HUD shows the code after the first turn")
	assert_true(not cabinet.is_open, "a wrong code leaves the cabinet closed")
	player.global_position = Vector2(540, 284)
	player.velocity = Vector2.ZERO
	for i in 5:
		await physics_frame
	assert_true(player._current_interactable == dials[1], "beside dial 2 it is the nearest interactable")
	assert_eq(hud.prompt_label.text, "E — چرخاندن رمز ۲", "the HUD prompt beside dial 2")
	player.global_position = Vector2(520, 284)
	player.velocity = Vector2.ZERO
	for i in 5:
		await physics_frame
	assert_true(player._current_interactable == dials[2], "beside dial 3 it is the nearest interactable")
	assert_eq(hud.prompt_label.text, "E — چرخاندن رمز ۳", "the HUD prompt beside dial 3")
	# The cabinet itself, from its south-east side: it only says it is locked.
	player.global_position = Vector2(558, 330)
	player.velocity = Vector2.ZERO
	for i in 5:
		await physics_frame
	assert_true(player._current_interactable == cabinet, "beside the cabinet itself it is the nearest interactable")
	assert_eq(hud.prompt_label.text, "E — بررسی کابینت", "the HUD prompt beside the cabinet")
	await _press_interact()
	assert_eq(hud.message_label.text, "کابینت قفله. رمز سه‌رقمی می‌خواد.", "E on the closed cabinet says it is locked")
	assert_true(not cabinet.is_open and dials[0].digit == 1, "the locked message changes nothing")
	# A dial cycles 0-9 and wraps: ten turns from 0 show 1 ... 9, 0.
	for d in dials:
		d.set_digit(0)
	var seen: Array = []
	for i in 10:
		dials[0].interact()
		seen.append(dials[0].digit)
	assert_eq(seen, [1, 2, 3, 4, 5, 6, 7, 8, 9, 0], "a dial cycles 0-9 and wraps to 0")
	assert_eq(hud.message_label.text, "کد: ۰ ۰ ۰", "the HUD shows the wrapped code")
	dials[1].set_digit(9)
	assert_eq(dials[1].digit, 9, "set_digit shows a digit directly")
	dials[1].set_digit(10)
	assert_eq(dials[1].digit, 0, "set_digit wraps too")
	# Wrong codes (also near misses) never open it and change nothing else.
	var opened_count := [0]
	cabinet.opened.connect(func() -> void: opened_count[0] += 1)
	for wrong in [[1, 4, 7], [4, 1, 8], [5, 1, 7], [7, 1, 4], [4, 1, 6]]:
		dials[0].set_digit(wrong[0])
		dials[1].set_digit(wrong[1])
		dials[2].set_digit(int(wrong[2]) - 1)
		dials[2].interact()
	assert_true(not cabinet.is_open and opened_count[0] == 0, "wrong codes, near misses included, never open the cabinet")
	assert_eq(hud.message_label.text, "کد: ۴ ۱ ۶", "after the last wrong code the HUD shows it")
	assert_true(prop_sprite.texture == worn_tex, "a wrong code leaves the sprite alone")
	assert_eq(_count_item("medicine", room), 0, "a wrong code spawns nothing")
	var still_live := true
	for d in dials:
		if not d.is_in_group("interactable") or d.is_locked():
			still_live = false
	assert_true(still_live and cabinet.is_in_group("interactable"), "after wrong codes the dials and the cabinet are still interactable")
	# The right code (4 1 7) opens it, once.
	dials[0].set_digit(4)
	dials[1].set_digit(1)
	dials[2].set_digit(6)
	dials[2].interact()
	assert_true(cabinet.is_open, "the code 4 1 7 opens the cabinet")
	assert_true(prop_sprite.texture == open_tex, "the open cabinet shows the cabinet_open sprite")
	assert_eq(hud.message_label.text, "کابینت باز شد.", "the HUD says the cabinet is open")
	assert_eq(opened_count[0], 1, "the cabinet opens exactly once")
	var locked_all := true
	for d in dials:
		if not d.is_locked() or d.is_in_group("interactable"):
			locked_all = false
	assert_true(locked_all, "the dials lock and leave the interactable group")
	assert_true(not cabinet.is_in_group("interactable"), "the open cabinet leaves the interactable group")
	assert_eq(_count_item("medicine", room), 1, "exactly one medicine pickup appears")
	assert_eq(_count_item("flashlight", room), 1, "the cabinet gives no flashlight: the desk's is still the only one")
	# Locked dials ignore further turns; nothing is spawned or opened twice.
	dials[0].interact()
	dials[2].interact()
	assert_eq(dials[0].digit, 4, "a locked dial no longer turns")
	assert_eq(opened_count[0], 1, "the cabinet does not open a second time")
	assert_eq(_count_item("medicine", room), 1, "still exactly one medicine pickup")
	var item: Node2D = room.get_node_or_null("MedMedicinePickup")
	assert_true(item != null, "the medicine pickup is named MedMedicinePickup")
	if item == null:
		play.queue_free()
		hud.queue_free()
		await process_frame
		await process_frame
		return true
	# What the medicine is.
	assert_eq(item.get_script().resource_path, "res://scripts/levels/rooms/medical_wing/pickup_medical_wing.gd", "the medicine is the room's own pickup copy")
	assert_true(item.is_in_group("interactable") and not item.is_in_group("hidden") and not item.is_in_group("puzzles"), "the medicine is an interactable, neither hidden nor a puzzle")
	assert_eq(item.item_id, "medicine", "the medicine's item id")
	assert_eq(item.display_name, "مسکّن", "the medicine's display name")
	assert_eq(item.interact_label, "برداشتن مسکّن", "the medicine's prompt text")
	assert_eq(item.amount, 1, "the medicine is one item")
	assert_eq((item.get_node("Sprite2D") as Sprite2D).texture, load("res://assets/sprites/medical-wing/packages_medicine.png"), "the medicine uses the medical pack's pills sprite")
	assert_eq(item.global_position, Vector2(530, 276), "the medicine appears in front of the cabinet")
	var item_rect := Rect2(item.global_position - Vector2(8, 8), Vector2(16, 16))
	var item_in_solid := false
	for r in room.blocked_rects():
		if item_rect.intersects(r):
			item_in_solid = true
	assert_true(not item_in_solid, "the medicine is not inside a wall or a solid prop")
	# Collect it through the real player: one medicine, the pain message.
	player.global_position = Vector2(530, 262)
	player.velocity = Vector2.ZERO
	for i in 5:
		await physics_frame
	assert_true(player._current_interactable == item, "beside it, the medicine is the nearest interactable")
	assert_eq(hud.prompt_label.text, "E — برداشتن مسکّن", "the HUD prompt beside the medicine")
	assert_eq(int(player.inventory.get("medicine", 0)), 0, "no medicine in the inventory before E")
	await _press_interact()
	assert_eq(int(player.inventory.get("medicine", 0)), 1, "E on the medicine puts one medicine in the inventory")
	assert_eq(hud.inventory_label.text, "وسایل: مسکّن ×1", "the HUD inventory shows the medicine")
	assert_eq(hud.message_label.text, "درد کم شد. حالم بهتر شد.", "collecting the medicine shows the pain-gone message")
	assert_true(not is_instance_valid(item), "the medicine pickup is gone once collected")
	await _press_interact()
	assert_eq(int(player.inventory.get("medicine", 0)), 1, "a second E does not give a second medicine")
	assert_eq(int(player.inventory.get("flashlight", 0)), 0, "the cabinet's medicine is not a flashlight")
	play.queue_free()
	hud.queue_free()
	await process_frame
	await process_frame
	return true


## The flashlight (P5, 2026-11-26; the desk's own MedFlashlight since P6),
## standalone room: the ONE flashlight is a visible pickup that lies on the
## doctor's desk (a child of the desk's body, like NoteConsole2) from the
## start; there is no floor pickup and no decor any more. E puts exactly one
## "flashlight" in the inventory (HUD «چراغ‌قوه»), and the light circle in the
## zone grows from the tiny one to the soft 70 screen px one. A HUD is added
## first (the standalone launcher has none).
func test_medical_flashlight() -> bool:
	if not ResourceLoader.exists(ROOM_SCENES["medical_wing"]):
		skipped += 1
		print("SKIP medical flashlight: scene not split yet")
		return true
	if _level != null:
		_level.queue_free()
		_level = null
		await process_frame
		await process_frame
	var hud: CanvasLayer = (load("res://scenes/ui/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	var play: Node2D = load(PLAY_SCENES["medical_wing"]).instantiate()
	root.add_child(play)
	var room: Node2D = play.room
	var player: CharacterBody2D = play.player
	var dark: Node2D = room.get_node("MedicalDarkness")
	var item: Node2D = room.get_node_or_null("MedDeskDoctor/MedFlashlight")
	assert_true(item != null, "the doctor's desk carries the MedFlashlight pickup")
	if item == null:
		play.queue_free()
		hud.queue_free()
		await process_frame
		await process_frame
		return true
	dark.flicker_enabled = false
	var zone: Rect2 = room.dark_zone_rect()
	# There is only ONE flashlight: no floor pickup, no second node with the
	# name, no second item with the id.
	assert_eq(_count_item("flashlight", room), 1, "the wing holds exactly one flashlight item")
	assert_true(room.get_node_or_null("MedFlashlightPickup") == null, "there is no separate floor pickup")
	assert_eq(room.find_children("MedFlashlight*", "", true, false).size(), 1, "exactly one node is called MedFlashlight")
	# What it is.
	assert_eq(item.get_script().resource_path, "res://scripts/levels/rooms/medical_wing/pickup_medical_wing.gd", "the flashlight is the room's own pickup copy, not the inert decor")
	assert_true(item.is_in_group("interactable"), "the flashlight is an interactable")
	assert_true(not item.is_in_group("hidden") and not item.is_in_group("puzzles"), "the flashlight is neither hidden nor a puzzle")
	assert_eq(item.item_id, "flashlight", "the flashlight's item id")
	assert_eq(item.display_name, "چراغ‌قوه", "the flashlight's display name")
	assert_eq(item.interact_label, "برداشتن چراغ‌قوه", "the flashlight's prompt text")
	assert_eq(item.amount, 1, "the flashlight is one item")
	assert_eq((item.get_node("Sprite2D") as Sprite2D).texture, load("res://assets/sprites/medical-wing/flashlight.png"), "the flashlight uses the medical flashlight sprite")
	# Placement: on the desk (the only solid rect it overlaps, and the desk
	# body is its parent), clear of the doorways and the scanner's line of
	# sight, well outside the dark zone (it must be takeable before going in).
	assert_eq(item.get_parent(), room.get_node("MedDeskDoctor"), "the flashlight hangs from the desk's body")
	assert_eq(item.global_position, Vector2(432, 252), "the flashlight lies where the desk decor lay")
	var item_rect := Rect2(item.global_position - Vector2(8, 8), Vector2(16, 16))
	var overlapped: Array = []
	for r in room.blocked_rects():
		if item_rect.intersects(r):
			overlapped.append(r)
	assert_eq(overlapped, [Rect2(424, 248, 32, 16)], "the flashlight overlaps no solid but the desk it lies on")
	var in_keep_out := false
	for r in [Rect2(0, 224, 160, 64), Rect2(272, 288, 64, 64), Rect2(232, 100, 56, 120)]:
		if item_rect.intersects(r):
			in_keep_out = true
	assert_true(not in_keep_out, "the flashlight is clear of the doorways and the scanner's line of sight")
	assert_true(not item_rect.grow(40.0).intersects(zone), "the flashlight is at least 40 px outside the dark zone")
	# E on it from the desk's west side (NoteConsole2 is 40+ px away there):
	# exactly one flashlight in the inventory, the pickup is gone.
	player.global_position = Vector2(410, 252)
	player.velocity = Vector2.ZERO
	for i in 5:
		await physics_frame
	assert_true(player._current_interactable == item, "beside it, the flashlight is the nearest interactable")
	assert_eq(hud.prompt_label.text, "E — برداشتن چراغ‌قوه", "the HUD prompt beside the flashlight")
	assert_true(not dark.has_flashlight(), "no flashlight before E")
	await _press_interact()
	assert_eq(int(player.inventory.get("flashlight", 0)), 1, "E on the flashlight puts one flashlight in the inventory")
	assert_eq(hud.inventory_label.text, "وسایل: چراغ‌قوه ×1", "the HUD inventory shows the flashlight")
	assert_eq(hud.message_label.text, "چراغ‌قوه برداشته شد.", "the flashlight-collected message")
	assert_true(not is_instance_valid(item), "the flashlight pickup is gone once collected")
	await _press_interact()
	assert_eq(int(player.inventory.get("flashlight", 0)), 1, "a second E does not give a second flashlight")
	# In the dark zone the light is now the 70 screen px circle; the zone
	# is as dark as ever.
	player.global_position = Vector2(356, 80)
	var saved_canvas: Transform2D = root.canvas_transform
	root.canvas_transform = Transform2D.IDENTITY.scaled(Vector2(2, 2))
	dark.step(5.0)
	var material: ShaderMaterial = dark.get_node("Overlay").material
	assert_true(dark.has_flashlight() and is_equal_approx(dark.light_radius_screen(), 70.0), "with the flashlight the light is 70 screen px")
	assert_true(is_equal_approx(material.get_shader_parameter("light_radius"), 35.0), "the shader radius is 35 world px at zoom 2")
	assert_true(is_equal_approx(material.get_shader_parameter("zone_darkness"), 0.95), "the zone is still fully dark with the flashlight")
	root.canvas_transform = saved_canvas
	play.queue_free()
	hud.queue_free()
	await process_frame
	await process_frame
	return true


## Seconds per step when a test drives MedicalDarkness.step(): 60 Hz.
const FLICKER_DT := 1.0 / 60.0


## Hold E for three physics frames (one just-pressed edge), then release.
func _press_interact() -> void:
	Input.action_press("interact")
	for i in 3:
		await physics_frame
	Input.action_release("interact")


## True when an AudioManager player is playing the "chime" stream now.
func _chime_playing(audio: Node) -> bool:
	for p in audio._players:
		if p.playing and p.stream == audio.streams["chime"]:
			return true
	return false


## Put a fresh medical-copy scanner at WORLD position `pos` in `level`, step
## the darkness once and report whether the robot went dormant. The robot is
## freed before any frame passes, so it never acts.
func _walker_dormant_at(level: Node2D, dark: Node2D, pos: Vector2) -> bool:
	var scene: PackedScene = load("res://scenes/levels/rooms/medical_wing/scanner_robot_medical_wing.tscn")
	var walker: CharacterBody2D = scene.instantiate()
	level.add_child(walker)
	walker.global_position = pos
	dark.step(0.0)
	var asleep: bool = walker.dormant
	walker.free()
	return asleep


## Dormant robots (P3, 2026-11-24, port of old step 5), standalone room,
## LOCAL coordinates: with the power out the Medical Wing scanner does not
## move, rotate its scan, detect, answer a radar pulse or catch the player
## — and it is not hidden — and it wakes the moment the power is restored.
## (Robots elsewhere staying untouched is checked in
## test_medical_fuse_full_game.)
func test_medical_robots_dormant() -> bool:
	if not ResourceLoader.exists(ROOM_SCENES["medical_wing"]):
		skipped += 1
		print("SKIP medical robots dormant: scene not split yet")
		return true
	# A cached assembled level holds another medical scanner.
	if _level != null:
		_level.queue_free()
		_level = null
		await process_frame
		await process_frame
	var play: Node2D = load(PLAY_SCENES["medical_wing"]).instantiate()
	root.add_child(play)
	var room: Node2D = play.room
	var player: CharacterBody2D = play.player
	var scanner: CharacterBody2D = room.get_node("ScannerRobot")
	var post: Vector2 = scanner.global_position
	var facing0: Vector2 = scanner._facing
	assert_true(scanner.dormant, "the scanner starts dormant (the power is out)")
	assert_true(is_equal_approx(scanner.self_modulate.a, 0.0), "the dormant scanner's vision cone is hidden")
	assert_true(scanner.is_visible_in_tree() and scanner.get_node("Sprite2D").is_visible_in_tree(), "the dormant scanner itself is not hidden")
	# In its cone, 30 px below it: nothing happens for ten physics frames,
	# not even for a radar pulse that reaches it.
	player.global_position = Vector2(260, 150)
	player.velocity = Vector2.ZERO
	scanner.investigate(Vector2(260, 150), 300.0)
	for i in 10:
		await physics_frame
	assert_eq(scanner.global_position, post, "the dormant scanner does not move")
	assert_eq(scanner._facing, facing0, "the dormant scanner does not rotate its scan")
	assert_true(not scanner._sees_player, "the dormant scanner does not detect a player in its cone")
	assert_eq(scanner.state, E_PATROL, "the dormant scanner ignores a radar pulse and does not chase")
	# Standing on it (inside the catch distance): no catch either.
	var caught := [0]
	scanner.player_caught.connect(func() -> void: caught[0] += 1)
	player.global_position = Vector2(260, 130)
	for i in 5:
		await physics_frame
	assert_true(player.global_position.distance_to(scanner.global_position) <= scanner.catch_distance, "the player stands inside the scanner's catch distance")
	assert_eq(caught[0], 0, "the dormant scanner does not catch a player standing on it")
	# Power back: it wakes at once and chases the player in its cone.
	player.global_position = Vector2(260, 150)
	player.velocity = Vector2.ZERO
	room.restore_power()
	assert_true(not scanner.dormant, "the scanner wakes the moment the power is restored")
	assert_true(is_equal_approx(scanner.self_modulate.a, 1.0), "the awake scanner's vision cone is back")
	for i in 4:
		await physics_frame
	assert_eq(scanner.state, E_CHASE, "the awake scanner sees and chases the player")
	play.queue_free()
	await process_frame
	await process_frame
	return true


## The power puzzle (P4, 2026-11-25; replaces the P3 placeholder switch;
## P5, 2026-11-26: the fuse now lies in the dark zone and the box stops
## the flicker), standalone room, LOCAL coordinates: a visible FUSE pickup
## inside the dark zone and a FUSE BOX that refuses without a fuse and,
## with one, consumes it and stabilises the power once. Neither is a
## puzzle or a hidden object.
## The positions are pinned in ROOM_CHECKS. A HUD is added before the room
## (the standalone launcher has none), so the HUD texts and the inventory
## line can be read.
func test_medical_fuse_puzzle() -> bool:
	if not ResourceLoader.exists(ROOM_SCENES["medical_wing"]):
		skipped += 1
		print("SKIP medical fuse puzzle: scene not split yet")
		return true
	# Same reason as test_medical_note_consoles: free the cached level.
	if _level != null:
		_level.queue_free()
		_level = null
		await process_frame
		await process_frame
	var hud: CanvasLayer = (load("res://scenes/ui/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	var play: Node2D = load(PLAY_SCENES["medical_wing"]).instantiate()
	root.add_child(play)
	var room: Node2D = play.room
	var player: CharacterBody2D = play.player
	var scanner: CharacterBody2D = room.get_node("ScannerRobot")
	var dark: Node2D = room.get_node("MedicalDarkness")
	var box: Node2D = room.get_node_or_null("MedFuseBox")
	var fuse: Node2D = room.get_node_or_null("MedFusePickup")
	assert_true(box != null and fuse != null, "the medical wing has a MedFuseBox and a MedFusePickup")
	if box == null or fuse == null:
		play.queue_free()
		hud.queue_free()
		await process_frame
		await process_frame
		return true
	assert_true(room.get_node_or_null("PowerSwitch") == null, "the placeholder PowerSwitch is gone")
	# What they are.
	assert_eq(fuse.get_script().resource_path, "res://scripts/levels/rooms/medical_wing/pickup_medical_wing.gd", "the fuse is the room's own pickup copy")
	assert_true(fuse.is_in_group("interactable"), "the fuse is an interactable")
	assert_true(not fuse.is_in_group("hidden") and not fuse.is_in_group("puzzles"), "the fuse is neither hidden nor a puzzle")
	assert_eq(fuse.item_id, "fuse", "the fuse's item id")
	assert_eq(fuse.interact_label, "برداشتن فیوز", "the fuse's prompt text")
	assert_eq(fuse.amount, 1, "the fuse is one item")
	assert_eq((fuse.get_node("Sprite2D") as Sprite2D).texture, load("res://assets/sprites/medical-wing/fuse_a.png"), "the fuse uses the medical fuse_a sprite")
	assert_eq(box.get_script().resource_path, "res://scripts/levels/rooms/medical_wing/fuse_box_medical_wing.gd", "the fuse box is the room's own script")
	assert_true(box.is_in_group("interactable"), "the fuse box is an interactable")
	assert_true(not box.is_in_group("puzzles") and not box.is_in_group("hidden"), "the fuse box is neither a puzzle nor a hidden object")
	assert_eq(box.interact_label, "گذاشتن فیوز", "the fuse box prompt text")
	var closed_tex: Texture2D = load("res://assets/sprites/medical-wing/fusebox_closed.png")
	var open_tex: Texture2D = load("res://assets/sprites/medical-wing/fusebox_open.png")
	assert_eq((box.get_node("Sprite2D") as Sprite2D).texture, closed_tex, "the fuse box starts closed")
	# Fuse placement: free floor, clear of both doorways and the scanner's
	# line of sight, 24+ px from every sprite, 200+ px from the box, and
	# apart from the consoles so the nearest-interactable pick is clear.
	var fuse_rect := Rect2(fuse.global_position - Vector2(8, 8), Vector2(16, 16))
	var in_solid := false
	for r in room.blocked_rects():
		if fuse_rect.intersects(r):
			in_solid = true
	assert_true(not in_solid, "the fuse is not inside a wall or a solid prop")
	assert_true(room.dark_zone_rect().encloses(fuse_rect), "the fuse lies inside the dark zone")
	var in_keep_out := false
	for r in [Rect2(0, 224, 160, 64), Rect2(272, 288, 64, 64), Rect2(232, 100, 56, 120)]:
		if fuse_rect.intersects(r):
			in_keep_out = true
	assert_true(not in_keep_out, "the fuse is clear of the doorways and the scanner's line of sight")
	assert_true(fuse.global_position.distance_to(box.global_position) >= 200.0, "the fuse is at least 200 px from the fuse box")
	var nearest_console := INF
	for c in [Vector2(120, 80), room.get_node("NoteConsole1").global_position,
			room.get_node("MedDeskDoctor/NoteConsole2").global_position,
			room.get_node("NoteConsole3").global_position]:
		nearest_console = minf(nearest_console, fuse.global_position.distance_to(c))
	assert_true(nearest_console >= 90.0, "the fuse is at least 90 px from every console")
	var too_close := ""
	for node in room.find_children("*", "Sprite2D", true, false):
		var sprite := node as Sprite2D
		if sprite.texture == null or fuse.is_ancestor_of(sprite) or box.is_ancestor_of(sprite):
			continue
		var sprite_size: Vector2 = sprite.texture.get_size() * sprite.global_scale
		var sprite_rect := Rect2(sprite.global_position - sprite_size / 2.0, sprite_size)
		if fuse_rect.grow(24.0).intersects(sprite_rect):
			too_close = str(sprite.name)
	assert_eq(too_close, "", "the fuse is at least 24 px from every sprite in the room")
	# The room starts dark; the scanner is dormant until the power is back.
	var fired := [0]
	room.power_restored.connect(func() -> void: fired[0] += 1)
	assert_true(not room.power_on and scanner.dormant, "the wing starts on emergency power and the scanner is dormant")
	assert_true(dark.flicker_enabled, "the lights flicker until the box is solved")
	# E on the box WITHOUT a fuse: a message, nothing else.
	player.global_position = Vector2(590, 70)
	player.velocity = Vector2.ZERO
	for i in 5:
		await physics_frame
	assert_true(player._current_interactable == box, "beside it, the fuse box is the nearest interactable")
	assert_eq(hud.prompt_label.text, "E — گذاشتن فیوز", "the HUD prompt beside the fuse box")
	await _press_interact()
	assert_eq(hud.message_label.text, "جعبه‌ی فیوز خالیه. یه فیوز لازمه.", "the empty-box message")
	assert_true(not room.power_on and fired[0] == 0, "an empty-handed E does not restore the power")
	assert_true(scanner.dormant, "the scanner stays dormant after an empty-handed E")
	assert_true(box.is_in_group("interactable") and not box.is_solved, "the box is not used up by an empty-handed E")
	assert_eq((box.get_node("Sprite2D") as Sprite2D).texture, closed_tex, "the box stays closed after an empty-handed E")
	assert_eq(int(player.inventory.get("fuse", 0)), 0, "the player holds no fuse yet")
	# E on the fuse: exactly one fuse in the inventory, the pickup is gone.
	player.global_position = Vector2(356, 86)
	player.velocity = Vector2.ZERO
	for i in 5:
		await physics_frame
	assert_true(player._current_interactable == fuse, "beside it, the fuse is the nearest interactable")
	assert_eq(hud.prompt_label.text, "E — برداشتن فیوز", "the HUD prompt beside the fuse")
	await _press_interact()
	assert_eq(int(player.inventory.get("fuse", 0)), 1, "E on the fuse puts one fuse in the inventory")
	assert_eq(hud.inventory_label.text, "وسایل: فیوز ×1", "the HUD inventory shows the fuse")
	assert_eq(hud.message_label.text, "فیوز برداشته شد.", "the fuse-collected message")
	assert_true(not is_instance_valid(fuse), "the fuse pickup is gone once collected")
	await _press_interact()
	assert_eq(int(player.inventory.get("fuse", 0)), 1, "a second E does not give a second fuse")
	# E on the box WITH the fuse: consumed, open, power back, once.
	player.global_position = Vector2(590, 70)
	player.velocity = Vector2.ZERO
	for i in 5:
		await physics_frame
	assert_true(player._current_interactable == box, "with the fuse, the fuse box is the nearest interactable")
	await _press_interact()
	assert_true(room.power_on, "E on the box with a fuse restores the power")
	assert_eq(fired[0], 1, "power_restored is emitted once")
	assert_true(not scanner.dormant, "the scanner wakes when the box restores the power")
	assert_true(not dark.flicker_enabled and not dark.is_flicker_dark(), "the flicker stops once the box is solved")
	assert_eq(int(player.inventory.get("fuse", 0)), 0, "the box consumes the fuse")
	assert_eq(hud.inventory_label.text, "وسایل: —", "the HUD inventory is empty again")
	assert_eq((box.get_node("Sprite2D") as Sprite2D).texture, open_tex, "the box shows fusebox_open")
	assert_eq(hud.message_label.text, "فیوز جا خورد. برق اضطراری وصل شد.", "the power-restored message")
	assert_true(not box.is_in_group("interactable"), "the used box leaves the interactable group")
	# After that it is inert: no target, no message, no second restore.
	hud.message_label.text = ""
	hud.message_label.visible = false
	for i in 5:
		await physics_frame
	assert_true(player._current_interactable != box, "the used box is not targeted again")
	await _press_interact()
	assert_eq(hud.message_label.text, "", "a second E on the used box shows nothing")
	assert_eq(fired[0], 1, "still one power_restored after a second E")
	# The mission does not know the puzzle.
	assert_eq([play.mission.puzzles_solved, play.mission.towers_active, play.mission.current_stage(), play._puzzles_solved], [0, 0, 0, 0], "the fuse puzzle leaves the mission counters alone")
	assert_eq([_count_in_subtree("puzzles", room), _count_in_subtree("hidden", room)], [0, 0], "the medical wing still has no puzzle and no hidden object")
	play.queue_free()
	hud.queue_free()
	await process_frame
	await process_frame
	return true


## Full game (main.tscn, so the HUD and AudioManager exist), P4
## (2026-11-25; replaces the P3 switch test; P5, 2026-11-26: the fuse lies
## in the dark zone, the box stops the flicker; P6, 2026-11-26: the desk's
## flashlight is the pickup, and the cabinet chain notes -> code -> medicine
## runs at the end): only the medical wing's scanner is dormant at the start; a
## robot with the medical copy is dormant inside the medical rect (WORLD
## (640, 0, 640, 368)) only until the power stabilises; a robot of another
## room is left alone; the fuse puzzle works through the real player, HUD
## and wiring (empty box, pickup, box, chime), wakes the scanner, stops the
## flicker, works once and leaves every mission counter, the 3 puzzles and
## the 3 hidden objects alone. The shared player has no display names for
## the flashlight and the medicine yet, so their HUD inventory lines are not
## pinned here (the fuse's are checked with contains()).
func test_medical_fuse_full_game() -> bool:
	if not ResourceLoader.exists(ROOM_SCENES["medical_wing"]):
		skipped += 1
		print("SKIP medical fuse puzzle (full game): scene not split yet")
		return true
	if _level != null:
		_level.queue_free()
		_level = null
		await process_frame
		await process_frame
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var level: Node2D = main.get_node("Level01")
	var hud: CanvasLayer = main.get_node("HUD")
	var audio: Node = main.get_node("AudioManager")
	var player: CharacterBody2D = level.get_node("Player")
	var mission: Node = level.get_node("Mission")
	var dark: Node2D = level.get_node_or_null("MedicalDarkness")
	var box: Node2D = level.get_node_or_null("MedFuseBox")
	var fuse: Node2D = level.get_node_or_null("MedFusePickup")
	assert_true(box != null and fuse != null and dark != null, "the assembled level keeps MedFuseBox, MedFusePickup and MedicalDarkness at level.get_node(...)")
	if box == null or fuse == null or dark == null:
		main.queue_free()
		await process_frame
		await process_frame
		return true
	assert_true(level.get_node_or_null("PowerSwitch") == null, "the placeholder PowerSwitch is gone from the assembled level")
	assert_eq(box.global_position, Vector2(1230, 44), "the fuse box sits at its local spot plus the wing's offset")
	assert_eq(fuse.global_position, Vector2(996, 64), "the fuse sits at its local spot plus the wing's offset")
	assert_true(dark.zone_rect.has_point(dark.to_local(fuse.global_position)), "the fuse lies inside the dark zone")
	var scanner: CharacterBody2D = level.get_node("ScannerRobot")
	var asleep: Array = []
	for enemy in get_nodes_in_group("enemies"):
		if level.is_ancestor_of(enemy) and "dormant" in enemy and enemy.dormant:
			asleep.append(str(enemy.name))
	assert_eq(asleep, ["ScannerRobot"], "at the start only the medical wing's scanner is dormant; the other robots are untouched")
	var counts_before := [_count_in_subtree("puzzles", level), _count_in_subtree("hidden", level)]
	assert_eq(counts_before, [3, 3], "the level has 3 puzzles and 3 hidden objects")
	# A robot of another room (its own copy, no dormant switch) that walks
	# into the wing is left alone.
	var other: CharacterBody2D = level.get_node("SecurityRobot")
	var home: Vector2 = other.global_position
	other.global_position = Vector2(700, 300)
	dark.step(0.0)
	assert_true(other.is_physics_processing(), "a robot of another room that walks into the wing is left alone")
	other.global_position = home
	# A robot with the medical copy: awake outside the wing's world rect,
	# dormant inside it while the power is out.
	assert_true(not _walker_dormant_at(level, dark, Vector2(320, 300)), "a robot outside the medical rect is awake")
	assert_true(_walker_dormant_at(level, dark, Vector2(700, 300)), "a robot that walks into the medical rect while the power is out is dormant")
	var chimed := [false]
	dark.power_restored.connect(func() -> void: chimed[0] = chimed[0] or _chime_playing(audio))
	# The ONE flashlight lies on the doctor's desk from the start (a child of
	# the desk's body); collected through the level's wiring (its HUD
	# inventory line is the shared player's, which has no display name for it
	# yet: not pinned).
	var flash: Node2D = level.get_node_or_null("MedDeskDoctor/MedFlashlight")
	assert_true(flash != null and level.get_node_or_null("MedFlashlightPickup") == null, "the assembled level has the desk's flashlight pickup and no floor one")
	if flash == null:
		main.queue_free()
		await process_frame
		await process_frame
		return true
	assert_eq(flash.global_position, Vector2(1072, 252), "the flashlight lies on the desk, offset by the wing's position")
	player.global_position = Vector2(1050, 252)
	player.velocity = Vector2.ZERO
	for i in 5:
		await physics_frame
	assert_eq(hud.prompt_label.text, "E — برداشتن چراغ‌قوه", "the HUD prompt beside the flashlight")
	await _press_interact()
	assert_eq(int(player.inventory.get("flashlight", 0)), 1, "E on the flashlight puts one flashlight in the inventory")
	assert_eq(hud.message_label.text, "چراغ‌قوه برداشته شد.", "the HUD shows the flashlight-collected message")
	assert_true(dark.has_flashlight(), "the darkness node sees the flashlight")
	assert_true(not is_instance_valid(flash), "the flashlight pickup is gone once collected")
	# Empty-handed E on the box: a message, nothing else.
	player.global_position = Vector2(1230, 70)
	player.velocity = Vector2.ZERO
	for i in 5:
		await physics_frame
	assert_eq(hud.prompt_label.text, "E — گذاشتن فیوز", "the HUD prompt beside the fuse box")
	await _press_interact()
	assert_eq(hud.message_label.text, "جعبه‌ی فیوز خالیه. یه فیوز لازمه.", "the HUD shows the empty-box message")
	assert_true(not dark.power_on and not chimed[0], "an empty-handed E restores no power and plays no chime")
	assert_true(scanner.dormant, "the scanner stays dormant after an empty-handed E")
	# Collect the fuse through the level's wiring.
	player.global_position = Vector2(996, 86)
	player.velocity = Vector2.ZERO
	for i in 5:
		await physics_frame
	assert_eq(hud.prompt_label.text, "E — برداشتن فیوز", "the HUD prompt beside the fuse")
	await _press_interact()
	assert_eq(int(player.inventory.get("fuse", 0)), 1, "E on the fuse puts exactly one fuse in the inventory")
	assert_true(hud.inventory_label.text.contains("فیوز ×1"), "the HUD inventory lists the fuse")
	assert_eq(hud.message_label.text, "فیوز برداشته شد.", "the HUD shows the fuse-collected message")
	assert_true(not is_instance_valid(fuse), "the fuse pickup is gone once collected")
	# Put it in the box.
	player.global_position = Vector2(1230, 70)
	player.velocity = Vector2.ZERO
	for i in 5:
		await physics_frame
	await _press_interact()
	assert_true(dark.power_on, "E on the box with a fuse restores the power in the full game")
	assert_eq(hud.message_label.text, "فیوز جا خورد. برق اضطراری وصل شد.", "the HUD shows the power-restored message")
	assert_true(chimed[0], "the chime plays when the power returns")
	assert_true(not scanner.dormant, "the scanner wakes in the full game")
	assert_true(not dark.flicker_enabled and not dark.is_flicker_dark(), "the flicker stops once the box is solved in the full game")
	assert_true(_flicker_pulses(dark, 60.0, FLICKER_DT).is_empty(), "no pulse in 60 s after the box is solved")
	assert_eq(int(player.inventory.get("fuse", 0)), 0, "the box consumes the fuse")
	assert_true(not hud.inventory_label.text.contains("فیوز"), "the HUD inventory no longer lists the fuse")
	assert_eq((box.get_node("Sprite2D") as Sprite2D).texture, load("res://assets/sprites/medical-wing/fusebox_open.png"), "the box shows fusebox_open")
	assert_eq([mission.puzzles_solved, mission.towers_active, mission.current_stage(), level._puzzles_solved], [0, 0, 0, 0], "the fuse puzzle leaves the mission counters alone")
	assert_eq([_count_in_subtree("puzzles", level), _count_in_subtree("hidden", level)], counts_before, "the puzzle and hidden-object counts are unchanged")
	assert_true(not _walker_dormant_at(level, dark, Vector2(700, 300)), "with the power back a robot inside the medical rect is awake")
	# Second E: no message, no prompt, no second use.
	hud.message_label.text = ""
	hud.message_label.visible = false
	for i in 5:
		await physics_frame
	await _press_interact()
	assert_eq(hud.message_label.text, "", "a second E on the used box shows nothing")
	assert_true(not hud.prompt_label.visible, "the prompt is gone once the box is used")
	assert_true(not box.is_in_group("interactable"), "the used box stays out of the interactable group")
	# Medical Recovery through the real player, HUD and wiring: read the three
	# notes, set the code they spell, open the cabinet, take the medicine (its
	# HUD inventory line is the shared player's, which has no display name for
	# it yet: not pinned).
	var cabinet: Node2D = level.get_node_or_null("MedCabinetWorn/MedCabinet")
	assert_true(cabinet != null and level.get_node_or_null("MedMedicinePickup") == null, "the assembled level has the cabinet and no medicine yet")
	if cabinet == null:
		main.queue_free()
		await process_frame
		await process_frame
		return true
	var digits: Array = []
	var messages_fit := true
	for stand in [Vector2(780, 296), Vector2(1110, 262), Vector2(1176, 160)]:
		player.global_position = stand
		player.velocity = Vector2.ZERO
		for i in 5:
			await physics_frame
		await _press_interact()
		var note_message: String = hud.message_label.text
		if note_message.length() > 72 or not note_message.ends_with(")"):
			messages_fit = false
		digits.append(TEST_DIGITS.find(note_message.substr(note_message.length() - 2, 1)))
	assert_true(messages_fit, "the three notes show a message of at most 72 characters that ends with the code digit")
	assert_eq(digits, [4, 1, 7], "the three notes spell the code 4 1 7 through the real HUD")
	var dials: Array = cabinet.dials()
	var dial_x := [1200.0, 1180.0, 1160.0]
	for d in 3:
		player.global_position = Vector2(dial_x[d], 284)
		player.velocity = Vector2.ZERO
		for i in 5:
			await physics_frame
		for t in int(digits[d]):
			await _press_interact()
		if d == 1:
			assert_true(not cabinet.is_open, "with only dials 1 and 2 set the cabinet is still closed")
			assert_eq(hud.message_label.text, "کد: ۴ ۱ ۰", "the HUD shows the code so far")
	assert_true(cabinet.is_open, "the code the notes spell opens the cabinet in the full game")
	assert_eq(hud.message_label.text, "کابینت باز شد.", "the HUD says the cabinet is open")
	assert_eq([dials[0].digit, dials[1].digit, dials[2].digit], [4, 1, 7], "the dials show 4 1 7")
	var medicine: Node2D = level.get_node_or_null("MedMedicinePickup")
	assert_true(medicine != null, "the open cabinet gives a MedMedicinePickup in the level")
	if medicine == null:
		main.queue_free()
		await process_frame
		await process_frame
		return true
	assert_eq(medicine.global_position, Vector2(1170, 276), "the medicine appears in front of the cabinet, offset by the wing's position")
	player.global_position = Vector2(1170, 262)
	player.velocity = Vector2.ZERO
	for i in 5:
		await physics_frame
	assert_eq(hud.prompt_label.text, "E — برداشتن مسکّن", "the HUD prompt beside the medicine")
	await _press_interact()
	assert_eq(int(player.inventory.get("medicine", 0)), 1, "E on the medicine puts exactly one medicine in the inventory")
	assert_eq(hud.message_label.text, "درد کم شد. حالم بهتر شد.", "collecting the medicine shows the pain-gone message")
	assert_true(not is_instance_valid(medicine), "the medicine pickup is gone once collected")
	await _press_interact()
	assert_eq(int(player.inventory.get("medicine", 0)), 1, "a second E gives no second medicine")
	assert_eq([mission.puzzles_solved, mission.towers_active, mission.current_stage(), level._puzzles_solved], [0, 0, 0, 0], "the cabinet chain leaves the mission counters alone")
	assert_eq([_count_in_subtree("puzzles", level), _count_in_subtree("hidden", level)], counts_before, "the cabinet chain leaves the puzzle and hidden-object counts alone")
	main.queue_free()
	await process_frame
	await process_frame
	return true


## Cone readability (P3, 2026-11-24): the medical scanner's vision cone is
## stronger (idle alpha 0.22, chase 0.40 — up from 0.07 / 0.15) and has a
## thin outline (alpha 0.6) so it reads on the bright medical floor; all
## three are @export vars of the room's own robot copy.
func test_medical_cone_readability() -> bool:
	if not ResourceLoader.exists(ROOM_SCENES["medical_wing"]):
		skipped += 1
		print("SKIP medical cone readability: scene not split yet")
		return true
	var play: Node2D = load(PLAY_SCENES["medical_wing"]).instantiate()
	root.add_child(play)
	var scanner: CharacterBody2D = play.room.get_node_or_null("ScannerRobot")
	assert_true(scanner != null, "medical wing scanner exists")
	if scanner == null:
		play.queue_free()
		await process_frame
		await process_frame
		return true
	assert_eq(scanner.cone_alpha_idle, 0.22, "idle cone alpha is 0.22")
	assert_eq(scanner.cone_alpha_chase, 0.40, "chase cone alpha is 0.40")
	assert_eq(scanner.cone_outline_alpha, 0.6, "cone outline alpha is 0.6")
	var exported: Array = []
	for prop in scanner.get_property_list():
		if (int(prop["usage"]) & PROPERTY_USAGE_EDITOR) != 0 and str(prop["name"]).begins_with("cone_"):
			exported.append(str(prop["name"]))
	exported.sort()
	assert_eq(exported, ["cone_alpha_chase", "cone_alpha_idle", "cone_outline_alpha"], "the three cone values are @export vars")
	assert_eq(scanner.cone_fill_color(), Color(1.0, 0.2, 0.2, 0.22), "the idle cone fill uses the idle alpha")
	scanner.state = E_CHASE
	assert_eq(scanner.cone_fill_color(), Color(1.0, 0.2, 0.2, 0.40), "the chase cone fill uses the chase alpha")
	scanner.state = E_PATROL
	assert_eq(scanner.cone_outline_color(), Color(1.0, 0.2, 0.2, 0.6), "the cone outline colour uses the outline alpha")
	var points: PackedVector2Array = scanner.cone_points()
	assert_eq(points.size(), 10, "the cone polygon is the robot plus nine arc points")
	assert_eq(points[0], Vector2.ZERO, "the cone starts at the robot")
	assert_true(is_equal_approx(points[9].length(), scanner.detection_radius), "the cone's arc ends at the detection radius")
	play.queue_free()
	await process_frame
	await process_frame
	return true
