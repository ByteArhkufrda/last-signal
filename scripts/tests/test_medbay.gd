extends SceneTree
## Last Signal — Medbay room tests (2026-11-28).
##
## Run: godot --headless --path . --script res://scripts/tests/test_medbay.gd
## Exit code 0 = all pass, 1 = any failure. No bare assert() (it hangs
## the run). Modelled on test_laboratory.gd, minus the puzzles:
## this room has no puzzles, no keycard, no ending sequence — only
## exploration under four patrol robots.

const PLAY_SCENE := "res://scenes/levels/rooms/medbay/play_medbay.tscn"
const MISSION_SCRIPT: Script = preload("res://scripts/levels/rooms/medbay/mission_medbay.gd")
const ROOM_SCRIPT: Script = preload("res://scripts/levels/rooms/medbay/medbay.gd")

const SPRITES := {
	"floor": "res://assets/sprites/medbay/floor_medbay.png",
	"wall_sheet": "res://assets/sprites/medbay/wall_sheet.png",
	"optable": "res://assets/sprites/medbay/optable.png",
	"cryo_cell": "res://assets/sprites/medbay/cryo_cell.png",
	"stasis": "res://assets/sprites/medbay/stasis.png",
	"chem_dispenser": "res://assets/sprites/medbay/chem_dispenser.png",
	"chem_master": "res://assets/sprites/medbay/chem_master.png",
	"chem_heater": "res://assets/sprites/medbay/chem_heater.png",
	"chem_mass_spec": "res://assets/sprites/medbay/chem_mass_spec.png",
	"reagentgrinder": "res://assets/sprites/medbay/reagentgrinder.png",
	"morgue_container": "res://assets/sprites/medbay/morgue_container.png",
	"table": "res://assets/sprites/medbay/table.png",
	"table_glass": "res://assets/sprites/medbay/table_glass.png",
	"table_reinforced": "res://assets/sprites/medbay/table_reinforced.png",
	"table_rglass": "res://assets/sprites/medbay/table_rglass.png",
	"table_wood": "res://assets/sprites/medbay/table_wood.png",
	"table_fancy": "res://assets/sprites/medbay/table_fancy.png",
	"table_fancy_blue": "res://assets/sprites/medbay/table_fancy_blue.png",
	"table_fancy_red": "res://assets/sprites/medbay/table_fancy_red.png",
	"table_greyscale": "res://assets/sprites/medbay/table_greyscale.png",
	"bed": "res://assets/sprites/medbay/bed.png",
	"bed_double": "res://assets/sprites/medbay/bed_double.png",
	"bed_emerg": "res://assets/sprites/medbay/bed_emerg.png",
	"locker_blue": "res://assets/sprites/medbay/locker_blue.png",
	"locker_chem": "res://assets/sprites/medbay/locker_chem.png",
	"locker_cmo": "res://assets/sprites/medbay/locker_cmo.png",
	"locker_med": "res://assets/sprites/medbay/locker_med.png",
	"locker_paramed": "res://assets/sprites/medbay/locker_paramed.png",
	"locker_atmos": "res://assets/sprites/medbay/locker_atmos.png",
	"locker_cap": "res://assets/sprites/medbay/locker_cap.png",
	"locker_cabinet": "res://assets/sprites/medbay/locker_cabinet.png",
	"locker_eng_secure": "res://assets/sprites/medbay/locker_eng_secure.png",
	"locker_secure": "res://assets/sprites/medbay/locker_secure.png",
	"smartfridge": "res://assets/sprites/medbay/smartfridge.png",
	"smartfridge_organ": "res://assets/sprites/medbay/smartfridge_organ.png",
	"monitor_operating": "res://assets/sprites/medbay/monitor_operating.png",
	"monitor_vitals": "res://assets/sprites/medbay/monitor_vitals.png",
	"defib_unit": "res://assets/sprites/medbay/defib_unit.png",
	"chair": "res://assets/sprites/medbay/chair.png",
	"chair_comfy": "res://assets/sprites/medbay/chair_comfy.png",
	"chair_comfy_teal": "res://assets/sprites/medbay/chair_comfy_teal.png",
	"chair_shuttle": "res://assets/sprites/medbay/chair_shuttle.png",
	"chair_office": "res://assets/sprites/medbay/chair_office.png",
	"chair_office_dark": "res://assets/sprites/medbay/chair_office_dark.png",
	"chair_stool": "res://assets/sprites/medbay/chair_stool.png",
	"sofa": "res://assets/sprites/medbay/sofa.png",
	"sofa_right": "res://assets/sprites/medbay/sofa_right.png",
	"sink": "res://assets/sprites/medbay/sink.png",
	"shower": "res://assets/sprites/medbay/shower.png",
	"toilet": "res://assets/sprites/medbay/toilet.png",
	"iv_drip": "res://assets/sprites/medbay/iv_drip.png",
	"player": "res://assets/sprites/medbay/player.png",
	"robot": "res://assets/sprites/medbay/robot.png"
}
var passed := 0
var failed := 0

## Catches counted by test_spawn_is_safe (signal handler target).
var _spawn_caught := 0


func _on_spawn_caught() -> void:
	_spawn_caught += 1


func _initialize() -> void:
	await run_tests()
	print("Results: %d passed, %d failed, 0 skipped" % [passed, failed])
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
	for t in ["test_room_geometry", "test_floor_and_sprites",
			"test_solid_props_on_floor", "test_spawn_is_safe",
			"test_robot_routes_clear", "test_robots_patrol",
			"test_standalone_has_hud", "test_mission_objective",
			"test_robot_catch_respawns", "test_bright_lighting",
			"test_seals_close_borders"]:
		paused = false
		var v = await call(t)
		if v == true:
			passed += 1
			print("PASS %s" % t)
		else:
			failed += 1
			push_error("FAIL %s: did not return true (runtime error?)" % t)


func _map() -> Array:
	return ROOM_SCRIPT.MAP


func _char_at(cx: int, cy: int) -> String:
	return (_map()[cy] as String)[cx]


func _is_walkable(cx: int, cy: int) -> bool:
	var ch := _char_at(cx, cy)
	return ch != "#" and ch != "X"


func test_room_geometry() -> bool:
	var map: Array = _map()
	assert_eq(map.size(), 41, "geo: MAP has 41 rows")
	for row in map:
		assert_eq((row as String).length(), 53, "geo: every MAP row is 53 chars")
	var allowed := "#X.WLATCPVGYSOBQN"
	var wall_cells := 0
	for y in range(41):
		for x in range(53):
			var ch: String = (map[y] as String)[x]
			assert_true(allowed.contains(ch), "geo: MAP char '%s' is known" % ch)
			if ch == "#" or ch == "X":
				wall_cells += 1
	assert_eq(wall_cells, 544, "geo: 544 wall/void cells in the MAP")
	var play: Node2D = load(PLAY_SCENE).instantiate()
	root.add_child(play)
	var room: Node2D = play.room
	assert_eq(room.room_rect, Rect2(0, 0, 1696, 1312), "geo: room is 1696x1312")
	assert_eq(room.room_tile_rect, Rect2i(0, 0, 106, 82), "geo: tile rect is 106x82")
	assert_eq(room.spawn_point, Vector2(848, 80), "geo: spawn at the lobby door")
	var rects: Array[Rect2] = room.wall_rects()
	assert_eq(rects.size(), 170, "geo: 170 merged wall rects")
	var area := 0.0
	for r in rects:
		area += r.size.x * r.size.y
	assert_eq(area, 544.0 * 32.0 * 32.0, "geo: wall rects cover exactly the wall cells")
	for y in range(41):
		for x in range(53):
			var ch := _char_at(x, y)
			if ch == "#" or ch == "X":
				var center := Vector2(x * 32 + 16, y * 32 + 16)
				var hits := 0
				for r in rects:
					if r.has_point(center):
						hits += 1
				assert_eq(hits, 1, "geo: wall cell (%d,%d) covered exactly once" % [x, y])
	var walls: Node = room.get_node_or_null("Walls_medbay")
	assert_true(walls != null, "geo: wall body exists")
	if walls != null:
		# '#' rects get shape + one junction sprite per cell;
		# 'X' (void) rects get collision only (1 child).
		var expected_children := 0
		for r in rects:
			var cells := int(r.size.x / 32) * int(r.size.y / 32)
			var cx := clampi(int(r.position.x / 32), 0, 52)
			var cy := clampi(int(r.position.y / 32), 0, 40)
			expected_children += 1 if _char_at(cx, cy) == "X" else 1 + cells
		assert_eq(walls.get_child_count(), expected_children, "geo: wall body children match the rects")
	# Every wall cell's smoothing junction fits the wall sheet
	# (0-14 per type) and WALLTYPE agrees with the MAP.
	for y in range(41):
		for x in range(53):
			if _char_at(x, y) == "#":
				var j: int = room._wall_junction(x, y)
				assert_true(j >= 0 and j <= 14, "geo: wall junction (%d,%d) is 0-14" % [x, y])
				assert_true((ROOM_SCRIPT.WALLTYPE[y] as String)[x] == "w" or (ROOM_SCRIPT.WALLTYPE[y] as String)[x] == "r", "geo: WALLTYPE (%d,%d) is w or r" % [x, y])
	assert_true(room.exits().is_empty(), "geo: no exits (standalone-only room)")
	play.queue_free()
	await process_frame
	await process_frame
	return true


func test_floor_and_sprites() -> bool:
	var floor_tex: Texture2D = load(SPRITES["floor"])
	assert_true(floor_tex != null, "sprites: floor texture loads")
	if floor_tex != null:
		assert_eq(floor_tex.get_size(), Vector2(1696, 1312), "sprites: floor is 1696x1312")
	var expected_sizes := {
		"cryo_cell": Vector2(32, 64),
		"locker_blue": Vector2(32, 48), "locker_chem": Vector2(32, 48),
		"locker_cmo": Vector2(32, 48), "locker_med": Vector2(32, 48),
		"locker_paramed": Vector2(32, 48), "locker_atmos": Vector2(32, 48),
		"locker_cap": Vector2(32, 48), "locker_cabinet": Vector2(32, 48),
		"locker_eng_secure": Vector2(32, 48), "locker_secure": Vector2(32, 48),
		"table_fancy": Vector2(32, 34), "table_fancy_blue": Vector2(32, 34),
		"table_fancy_red": Vector2(32, 34),
		"wall_sheet": Vector2(32, 960),
		"player": Vector2(16, 16), "robot": Vector2(16, 16),
	}
	for key in SPRITES.keys():
		if key == "floor":
			continue
		var tex: Texture2D = load(SPRITES[key])
		assert_true(tex != null, "sprites: %s loads" % key)
		if tex != null:
			var want: Vector2 = expected_sizes.get(key, Vector2(32, 32))
			assert_eq(tex.get_size(), want, "sprites: %s is %s" % [key, want])
	var play: Node2D = load(PLAY_SCENE).instantiate()
	root.add_child(play)
	var floor_node: Sprite2D = play.room.get_node_or_null("Floor") as Sprite2D
	assert_true(floor_node != null, "sprites: room has a Floor node")
	assert_true(floor_node != null and floor_node.texture == floor_tex, "sprites: Floor uses the medbay floor")
	play.queue_free()
	await process_frame
	await process_frame
	return true


func test_solid_props_on_floor() -> bool:
	var play: Node2D = load(PLAY_SCENE).instantiate()
	root.add_child(play)
	var room: Node2D = play.room
	var expected_solid := 0
	for row in ROOM_SCRIPT.PROPS:
		if bool((row as Array)[3]):
			expected_solid += 1
	var rects: Array[Rect2] = room.prop_solid_rects()
	assert_eq(rects.size(), expected_solid, "props: %d solid rects built" % expected_solid)
	var walls: Array[Rect2] = room.wall_rects()
	for r in rects:
		assert_eq(r.size, Vector2(32, 32), "props: solid rect is 32x32")
		var cx := int(r.get_center().x / 32)
		var cy := int(r.get_center().y / 32)
		assert_true(_is_walkable(cx, cy), "props: solid rect at (%d,%d) sits on floor" % [cx, cy])
		var overlaps_wall := false
		for w in walls:
			if r.intersects(w):
				overlaps_wall = true
				break
		assert_true(not overlaps_wall, "props: solid rect at (%d,%d) does not overlap a wall" % [cx, cy])
	# Four cells carry two solid props (a monitor on a table, per the
	# SS13 data): both rects exist and the nav grid still marks the
	# cell once — no crash, no dedup.
	for cell in [Vector2i(28, 13), Vector2i(36, 13), Vector2i(36, 32), Vector2i(48, 10)]:
		var center := Vector2(cell.x * 32 + 16, cell.y * 32 + 16)
		var hits := 0
		for r in rects:
			if r.get_center() == center:
				hits += 1
		assert_eq(hits, 2, "props: double-solid cell (%d,%d) keeps both rects" % [cell.x, cell.y])
	# The two cryo cells hang 16 px above their body center (32x64
	# sprite, bottom edge on the cell's bottom edge).
	var cryo_bodies := 0
	for child in room.get_children():
		if child is StaticBody2D and (child as Node).name.begins_with("Prop_cryo_cell"):
			cryo_bodies += 1
			var sprite: Sprite2D = (child as Node).get_child(0) as Sprite2D
			assert_true(sprite != null, "props: cryo body has a sprite")
			if sprite != null:
				assert_eq(sprite.position, Vector2(0, -16), "props: cryo sprite offset is (0,-16)")
	assert_eq(cryo_bodies, 2, "props: two cryo cells")
	play.queue_free()
	await process_frame
	await process_frame
	return true


func test_spawn_is_safe() -> bool:
	var play: Node2D = load(PLAY_SCENE).instantiate()
	root.add_child(play)
	var player: CharacterBody2D = play.player
	assert_eq(player.global_position, Vector2(848, 80), "spawn: player starts at the lobby door")
	var robots: Array = play.get_tree().get_nodes_in_group("enemies")
	assert_eq(robots.size(), 4, "spawn: four patrol robots")
	_spawn_caught = 0
	for r in robots:
		(r as Node).player_caught.connect(_on_spawn_caught)
	var spotted := false
	for i in 600:
		await physics_frame
		for r in robots:
			if int((r as Node).get("state")) != 0:
				spotted = true
	assert_true(not spotted, "spawn: no robot spots the idle player in 10 s")
	assert_eq(_spawn_caught, 0, "spawn: no catch in 10 s at spawn")
	play.queue_free()
	await process_frame
	await process_frame
	return true


func test_robot_routes_clear() -> bool:
	var play: Node2D = load(PLAY_SCENE).instantiate()
	root.add_child(play)
	var room: Node2D = play.room
	var routes: Array = room.patrol_routes_local()
	assert_eq(routes.size(), 4, "routes: four patrol routes")
	var solids: Array[Rect2] = room.blocked_rects()
	for ri in routes.size():
		var route: Array = routes[ri]
		for i in range(route.size() - 1):
			var a: Vector2 = route[i]
			var b: Vector2 = route[i + 1]
			var steps: int = int(a.distance_to(b) / 8.0) + 1
			var blocked := false
			for s in range(steps + 1):
				var p: Vector2 = a.lerp(b, float(s) / float(steps))
				for r in solids:
					if r.has_point(p):
						blocked = true
						break
				if blocked:
					break
			assert_true(not blocked, "routes: route %d leg %d is clear" % [ri + 1, i + 1])
	play.queue_free()
	await process_frame
	await process_frame
	return true


func test_robots_patrol() -> bool:
	var play: Node2D = load(PLAY_SCENE).instantiate()
	root.add_child(play)
	var room: Node2D = play.room
	var robots: Array = play.get_tree().get_nodes_in_group("enemies")
	assert_eq(robots.size(), 4, "patrol: four robots in the enemies group")
	var want_routes: Array = room.patrol_routes_local()
	var got_routes: Array = []
	for r in robots:
		assert_eq((r as Node).get("detection_radius"), 60.0, "patrol: %s vision radius is 60" % (r as Node).name)
		var pts: Array = (r as Node).get("patrol_points")
		assert_eq(pts.size(), 2, "patrol: %s has two waypoints" % (r as Node).name)
		got_routes.append(pts)
	for route in want_routes:
		var found := false
		for got in got_routes:
			if (got as Array)[0] == (route as Array)[0] and (got as Array)[1] == (route as Array)[1]:
				found = true
		assert_true(found, "patrol: route %s is assigned to a robot" % str(route))
	# Waypoints sit on walkable floor.
	for route in want_routes:
		for p in (route as Array):
			var cx := int((p as Vector2).x / 32)
			var cy := int((p as Vector2).y / 32)
			assert_true(_is_walkable(cx, cy), "patrol: waypoint (%d,%d) is on floor" % [cx, cy])
	play.queue_free()
	await process_frame
	await process_frame
	return true


func test_standalone_has_hud() -> bool:
	var play: Node2D = load(PLAY_SCENE).instantiate()
	root.add_child(play)
	var hud: CanvasLayer = play.get_node_or_null("HUD") as CanvasLayer
	assert_true(hud != null, "hud: standalone play has a HUD child")
	assert_true(hud != null and hud.is_in_group("hud"), "hud: HUD is in the hud group")
	assert_true(play.wiring._get_hud() != null, "hud: wiring resolves the HUD")
	assert_true(hud != null and hud.get_node_or_null("PromptLabel") != null, "hud: prompt label exists")
	assert_true(hud != null and hud.get_node_or_null("MessageLabel") != null, "hud: message label exists")
	assert_true(hud != null and hud.get_node_or_null("ObjectiveLabel") != null, "hud: objective label exists")
	assert_true(hud != null and hud.get_node_or_null("HintLabel").visible, "hud: area hint shown at spawn")
	var objective: Label = hud.get_node("ObjectiveLabel") as Label
	var font: Font = objective.get_theme_font("font")
	var w: float = font.get_string_size(objective.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	assert_true(w <= 580.0, "hud: objective fits the bottom-center label")
	var mission_probe: Node = MISSION_SCRIPT.new()
	var tw: float = font.get_string_size(mission_probe.current_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	assert_true(tw <= 580.0, "hud: mission objective fits the bottom-center label")
	play.queue_free()
	await process_frame
	await process_frame
	return true


func test_mission_objective() -> bool:
	var mission: Node = MISSION_SCRIPT.new()
	assert_eq(mission.current_stage(), 0, "mission: single standing stage")
	assert_true(not mission.is_complete, "mission: never completes (exploration only)")
	assert_eq(mission.current_text(), "Medbay را بگرد؛ دیده نشو", "mission: objective text")
	assert_true(get_nodes_in_group("interactable").is_empty(), "mission: no interactables in this room")
	return true


func test_robot_catch_respawns() -> bool:
	var play: Node2D = load(PLAY_SCENE).instantiate()
	root.add_child(play)
	var player: CharacterBody2D = play.player
	var hud: CanvasLayer = play.get_node("HUD") as CanvasLayer
	var robots: Array = play.get_tree().get_nodes_in_group("enemies")
	assert_true(robots.size() == 4, "catch: four robots to catch the player")
	var robot: Node = robots[0]
	var caught := false
	for i in 120:
		player.global_position = robot.global_position
		await physics_frame
		if player.global_position.distance_to(Vector2(848, 80)) < 5.0:
			caught = true
			break
	assert_true(caught, "catch: walking into a robot respawns the player at spawn")
	var msg_label: Label = hud.get_node("MessageLabel") as Label
	assert_true(msg_label.text.contains("ربات تو را گرفت!"), "catch: HUD shows the catch banner")
	play.queue_free()
	await process_frame
	await process_frame
	return true


func test_bright_lighting() -> bool:
	var play: Node2D = load(PLAY_SCENE).instantiate()
	root.add_child(play)
	var room: Node2D = play.room
	var mod: CanvasModulate = room.get_node_or_null("AmbientBright") as CanvasModulate
	assert_true(mod != null, "light: bright ambient node exists")
	if mod != null:
		assert_eq(mod.color, Color(1, 1, 1), "light: ambient is neutral white (1,1,1), no tint")
	var lights := 0
	for child in room.get_children():
		if child is PointLight2D:
			lights += 1
	assert_eq(lights, 0, "light: no ceiling lights (uniform station lighting)")
	play.queue_free()
	await process_frame
	await process_frame
	return true


func test_seals_close_borders() -> bool:
	var play: Node2D = load(PLAY_SCENE).instantiate()
	root.add_child(play)
	var room: Node2D = play.room
	var seals: Array[Rect2] = room.doorway_gap_rects()
	assert_eq(seals.size(), 159, "seals: 159 open border cells sealed")
	for r in seals:
		assert_eq(r.size, Vector2(32, 32), "seals: seal rect is one cell")
		var outside := r.position.x == -32 or r.position.x == 1696 or r.position.y == -32 or r.position.y == 1312
		assert_true(outside, "seals: seal rect sits just outside the room")
	var seal_body: Node = room.get_node_or_null("WallsSeal_medbay")
	assert_true(seal_body != null, "seals: seal body exists in standalone play")
	if seal_body != null:
		# One collision shape per seal rect, no wall sprites: the
		# seals sit outside the MAP (a bounds bug here once left
		# the seal body half-built with a SCRIPT ERROR).
		assert_eq(seal_body.get_child_count(), 159, "seals: seal body has one shape per seal rect")
	play.queue_free()
	await process_frame
	await process_frame
	return true
