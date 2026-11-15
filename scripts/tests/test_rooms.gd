extends SceneTree
## Last Signal — headless room tests (2026-11-15).
##
## Run: godot --headless --path . --script res://scripts/tests/test_rooms.gd
## Exit code 0 = all pass, 1 = any failure. No bare assert() (it hangs
## the run). A room whose scene does not exist yet is SKIPPED (its
## branch has not landed), not failed — the split lands room by room.
##
## For every split room this verifies, standalone via room_play.tscn:
## the floor covers exactly the room's tile rect, the expected nodes
## exist at their exact positions, the wiring sets the area, the
## robot(s) patrol inside the room, a nav path exists from the spawn,
## and — against one assembled level instance — the standalone nav
## grid agrees cell for cell with the full level's grid.

const ROOM_SCENES := {
	"command_center": "res://scenes/levels/rooms/command_center.tscn",
	"medical_wing": "res://scenes/levels/rooms/medical_wing.tscn",
	"laboratory": "res://scenes/levels/rooms/laboratory.tscn",
	"engine_room": "res://scenes/levels/rooms/engine_room.tscn",
	"communications": "res://scenes/levels/rooms/communications.tscn",
}
## area, tile rect, standalone spawn, a walkable target cell for the
## nav-path check, expected named nodes with positions, expected group
## sizes inside the room, expected children of the "Walls_<key>" body
## (3 per wall rect: shape + visual + highlight).
const ROOM_CHECKS := {
	"command_center": {
		"area": "کنترل مرکزی", "tile_rect": Rect2i(0, 0, 40, 23),
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
		"area": "بخش پزشکی", "tile_rect": Rect2i(40, 0, 40, 23),
		"spawn": Vector2(704, 256), "target_cell": Vector2i(50, 10),
		"nodes": {
			"ScannerRobot": Vector2(900, 120), "MedBedStandard": Vector2(700, 64),
		},
		"towers": 0, "puzzles": 0, "enemies": 1, "wall_children": 15,
	},
	"laboratory": {
		"area": "آزمایشگاه تحقیقاتی", "tile_rect": Rect2i(0, 23, 40, 23),
		"spawn": Vector2(320, 400), "target_cell": Vector2i(10, 30),
		"nodes": {"LabRobot": Vector2(200, 560)},
		"towers": 0, "puzzles": 0, "enemies": 1, "wall_children": 15,
	},
	"engine_room": {
		"area": "نیروگاه", "tile_rect": Rect2i(40, 23, 40, 23),
		"spawn": Vector2(700, 400), "target_cell": Vector2i(50, 30),
		"nodes": {"PowerScanner": Vector2(1000, 520)},
		"towers": 0, "puzzles": 0, "enemies": 1, "wall_children": 21,
	},
	"communications": {
		"area": "محوطه‌ی مخابرات", "tile_rect": Rect2i(40, 46, 40, 12),
		"spawn": Vector2(944, 760), "target_cell": Vector2i(55, 50),
		"nodes": {"YardRobot": Vector2(800, 840)},
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
			"test_room_play_scene_loads"]:
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
	var play_scene: PackedScene = load("res://scenes/levels/rooms/room_play.tscn")
	var play: Node2D = play_scene.instantiate()
	play.room_key_override = room_key
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
	# Standalone grid agrees with the assembled level's grid, cell for cell.
	var level: Node2D = _get_level()
	var level_grid: AStarGrid2D = level.get("_nav_grid")
	var mismatch := 0
	for x in range(tile_rect.position.x, tile_rect.end.x):
		for y in range(tile_rect.position.y, tile_rect.end.y):
			if play.nav_grid.is_point_solid(Vector2i(x, y)) != level_grid.is_point_solid(Vector2i(x, y)):
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
		for node_name in (check["nodes"] as Dictionary).keys():
			var node: Node2D = level.get_node_or_null(node_name)
			assert_true(node != null, "assembled level has %s" % node_name)
			if node != null:
				assert_eq(node.global_position, check["nodes"][node_name], "assembled %s position" % node_name)
	# All five area zones exist with their area names.
	for area in ["کنترل مرکزی", "بخش پزشکی", "آزمایشگاه تحقیقاتی", "نیروگاه", "محوطه‌ی مخابرات"]:
		var zone: Area2D = level.get_node_or_null("AreaZone_" + area.replace(" ", ""))
		assert_true(zone != null, "assembled zone %s" % area)
	return true


func test_room_play_scene_loads() -> bool:
	var scene: PackedScene = load("res://scenes/levels/rooms/room_play.tscn")
	assert_true(scene != null, "room_play.tscn loads")
	var play: Node2D = scene.instantiate()
	assert_true(play.get("room_key_override") != null, "room_play has room_key_override")
	play.queue_free()
	return true
