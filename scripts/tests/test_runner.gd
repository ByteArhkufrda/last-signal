extends SceneTree
## Last Signal — headless test runner (Phase 1).
## Pattern: awesome-gamedev-agent-skills godot-gdscript-headless-testing.
## Run: godot --headless --path . --script res://scripts/tests/test_runner.gd
## Exit code 0 = all pass, 1 = any failure. No bare assert() (it hangs the run).

var passed := 0
var failed := 0


func _initialize() -> void:
	await run_tests()
	print("Results: %d passed, %d failed" % [passed, failed])
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
	for t in ["test_input_actions_exist", "test_player_scene_loads", "test_compute_velocity", "test_level_loads_camera_limits", "test_player_moves_and_wall_blocks", "test_diagonal_speed_capped", "test_player_stops_and_is_moving", "test_walk_bob_and_camera_lookahead", "test_interact_action_exists", "test_interactables_present", "test_floor_variation", "test_console_interact", "test_door_toggle", "test_hud_prompt", "test_radar_action_exists", "test_hidden_objects_start_hidden", "test_pulse_reveals_near_hidden", "test_pulse_cooldown_and_signal", "test_hud_radar_status", "test_enemy_patrols", "test_enemy_investigates_pulse", "test_enemy_chases_when_player_visible", "test_enemy_loses_player", "test_enemy_does_not_see_through_walls", "test_player_caught_respawn", "test_battery_drains", "test_radar_costs_battery", "test_radar_blocked_when_battery_low", "test_hidden_pickup_collects", "test_visible_pickup_collects", "test_hud_battery_and_inventory", "test_breaker_wrong_order_resets", "test_breaker_correct_order_solves", "test_wire_panel_solves", "test_fuse_box_needs_fuse", "test_fuse_box_solves_with_fuse", "test_fuse_pickup_collects", "test_hud_puzzle_counter", "test_tower_blocked_without_power", "test_tower_activates_after_puzzle", "test_mission_objectives_advance", "test_transmission_completes_mission", "test_transmit_blocked_early", "test_hud_objective", "test_main_menu_loads", "test_pause_menu_toggles", "test_pause_stops_player", "test_audio_manager_generates_sounds", "test_fx_ring_frees_itself", "test_hud_flash", "test_battery_bar_red_when_low", "test_full_playthrough", "test_win_screen_shows", "test_effect_spam_stress", "test_win_screen_blocks_pause", "test_radar_investigates_inside_radius", "test_radar_ignores_outside_radius", "test_radar_boundary_investigates", "test_radar_does_not_interrupt_chase", "test_radar_multiple_enemies_by_distance", "test_ambient_has_no_fade", "test_sfx_still_fade", "test_ambient_pause_resume_volume", "test_player_walk_down", "test_player_walk_up", "test_player_walk_left", "test_player_walk_right", "test_player_idle_preserves_facing", "test_player_diagonal_uses_cardinal_animation", "test_player_animation_stops_at_wall", "test_player_spriteframes_complete", "test_enemy_path_avoids_crate", "test_enemy_navigates_around_crate", "test_enemy_path_through_doorway", "test_enemy_no_grid_fallback", "test_area_medical_entry", "test_area_wall_blocks_except_doorway", "test_areas_reachable_by_walking", "test_scanner_stays_at_post_and_scans", "test_scanner_chases_visible_player", "test_scanner_returns_to_post", "test_radar_blocked_by_crate", "test_radar_reveals_with_line_of_sight", "test_radar_blocked_by_alcove_wall", "test_environment_props_exist", "test_medical_floor_uses_medical_atlas", "test_medical_props_exist", "test_medical_doorways_stay_open", "test_medical_fuse_texture", "test_minimap_action_exists", "test_minimap_in_hud", "test_minimap_world_to_map", "test_minimap_tracks_player", "test_minimap_tower_states", "test_minimap_enemies_revealed_by_pulse", "test_minimap_toggle", "test_minimap_hidden_objects_only_when_revealed", "test_minimap_area_label", "test_wall_texture_file", "test_wall_texture_applied", "test_persian_font_file", "test_mission_stage_accessor", "test_help_screen_loads", "test_main_menu_help_button", "test_pause_menu_help_button", "test_one_robot_per_area", "test_robots_patrol_own_area", "test_hud_stage_hint", "test_area_entry_shows_hint"]:
		# A failed pause test must not leave the tree paused: physics
		# frames stop while paused, and later tests await them.
		paused = false
		# await works for sync and async test functions alike; a test that
		# aborts on a runtime error yields null instead of true.
		var v = await call(t)
		if v == true:
			passed += 1
			print("PASS %s" % t)
		else:
			failed += 1
			push_error("FAIL %s: did not return true (runtime error?)" % t)


func test_input_actions_exist() -> bool:
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		assert_true(InputMap.has_action(action), "input action exists: " + action)
	return true


func test_player_scene_loads() -> bool:
	var scene: PackedScene = load("res://scenes/characters/player.tscn")
	assert_true(scene != null, "player.tscn loads")
	var player: CharacterBody2D = scene.instantiate()
	assert_true(player is CharacterBody2D, "player is CharacterBody2D")
	assert_eq(player.motion_mode, CharacterBody2D.MOTION_MODE_FLOATING, "player motion mode floating")
	assert_true(player.get_node_or_null("CollisionShape2D") != null, "player has CollisionShape2D")
	assert_true(player.get_node_or_null("Sprite2D") != null, "player has Sprite2D")
	assert_true(player.get_node_or_null("Camera2D") != null, "player has Camera2D")
	assert_eq(player.speed, 200.0, "player speed default 200")
	player.queue_free()
	return true


func test_compute_velocity() -> bool:
	var script: GDScript = load("res://scripts/characters/player.gd")
	assert_eq(script.compute_target_velocity(Vector2(1, 0), 200.0), Vector2(200, 0), "velocity right")
	assert_eq(script.compute_target_velocity(Vector2(0, -1), 200.0), Vector2(0, -200), "velocity up")
	assert_eq(script.compute_target_velocity(Vector2.ZERO, 200.0), Vector2.ZERO, "velocity zero")
	return true


func test_level_loads_camera_limits() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var floor_layer: TileMapLayer = level.get_node("Floor")
	assert_true(floor_layer.tile_set != null, "floor TileSet built")
	assert_true(floor_layer.get_used_cells().size() == 80 * 58, "floor has 80x58 cells")
	var player: CharacterBody2D = level.get_node("Player")
	assert_true(player != null, "level has Player")
	var camera: Camera2D = player.get_node("Camera2D")
	assert_eq(camera.limit_right, 1280, "camera limit_right 1280")
	assert_eq(camera.limit_bottom, 928, "camera limit_bottom 928")
	level.queue_free()
	return true


func test_diagonal_speed_capped() -> bool:
	var script: GDScript = load("res://scripts/characters/player.gd")
	var diagonal: Vector2 = Vector2(1, 1).normalized()
	var v: Vector2 = script.compute_target_velocity(diagonal, 200.0)
	assert_true(absf(v.length() - 200.0) < 0.01, "diagonal speed capped at 200")
	return true


func test_player_stops_and_is_moving() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	Input.action_press("move_right")
	for i in 20:
		await physics_frame
	assert_true(player.is_moving, "player is_moving while walking")
	Input.action_release("move_right")
	for i in 40:
		await physics_frame
	assert_true(player.velocity.length() < 1.0, "player fully stops after release")
	assert_true(not player.is_moving, "player is_moving false after stop")
	level.queue_free()
	return true


func test_walk_bob_and_camera_lookahead() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	var sprite: AnimatedSprite2D = player.get_node("Sprite2D")
	var camera: Camera2D = player.get_node("Camera2D")
	Input.action_press("move_right")
	var bob_values := {}
	for i in 20:
		await physics_frame
		bob_values[int(round(sprite.position.y * 100.0))] = true
	assert_true(bob_values.size() >= 3, "walk bob changes sprite offset while moving")
	for i in 10:
		await physics_frame
	assert_true(camera.offset.x > 5.0, "camera look-ahead offsets right (x=%s)" % camera.offset.x)
	Input.action_release("move_right")
	for i in 60:
		await physics_frame
	assert_true(camera.offset.length() < 5.0, "camera look-ahead returns to center when idle")
	assert_eq(sprite.position.y, -1.0, "walk bob returns sprite to base offset when idle")
	level.queue_free()
	return true


func test_interact_action_exists() -> bool:
	assert_true(InputMap.has_action("interact"), "action interact exists")
	assert_true(InputMap.action_get_events("interact").size() > 0, "interact has a key event")
	return true


func test_interactables_present() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var count := 0
	for node in get_nodes_in_group("interactable"):
		# Switches/terminals are grandchildren (children of their panels).
		if level.is_ancestor_of(node):
			count += 1
	assert_eq(count, 19, "level has 19 interactables (6 consoles + 1 door + 1 visible pickup + 3 switches + 3 terminals + 1 fuse box + 3 towers + 1 transmit console)")
	level.queue_free()
	return true


func test_floor_variation() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var floor_layer: TileMapLayer = level.get_node("Floor")
	var variant := 0
	var used := 0
	for x in 40:
		for y in 23:
			var coords := floor_layer.get_cell_atlas_coords(Vector2i(x, y))
			if coords != Vector2i(-1, -1):
				used += 1
				if coords == Vector2i(1, 0):
					variant += 1
	assert_eq(used, 920, "floor covers all 920 cells")
	assert_true(variant > 50 and variant < 250, "cracked variant scattered (~15%%, got %d)" % variant)
	level.queue_free()
	return true


func test_console_interact() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	var console: Node2D = level.get_node("ConsoleA")
	player.global_position = Vector2(120, 130)
	for i in 5:
		await physics_frame
	assert_true(player._current_interactable == console, "console is the nearest interactable")
	Input.action_press("interact")
	for i in 3:
		await physics_frame
	Input.action_release("interact")
	assert_eq(console.use_count, 1, "console used once after E")
	level.queue_free()
	return true


func test_door_toggle() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	var door: StaticBody2D = level.get_node("Door")
	var shape: CollisionShape2D = door.get_node("CollisionShape2D")
	player.global_position = Vector2(568, 100)
	for i in 5:
		await physics_frame
	assert_true(player._current_interactable == door, "door is the nearest interactable")
	Input.action_press("interact")
	for i in 3:
		await physics_frame
	Input.action_release("interact")
	assert_true(door.is_open, "door opens after E")
	assert_true(shape.disabled, "door collision disabled while open")
	Input.action_press("interact")
	for i in 3:
		await physics_frame
	Input.action_release("interact")
	assert_true(not door.is_open, "door closes after second E")
	assert_true(not shape.disabled, "door collision enabled while closed")
	level.queue_free()
	return true


func test_hud_prompt() -> bool:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)
	await process_frame
	var hud: CanvasLayer = main.get_node("HUD")
	var prompt: Label = hud.get_node("PromptLabel")
	var player: CharacterBody2D = main.get_node("Level01/Player")
	player.global_position = Vector2(120, 130)
	for i in 5:
		await physics_frame
	assert_true(prompt.visible, "HUD prompt visible near console")
	assert_true(prompt.text.contains("استفاده از کنسول"), "HUD prompt names the console")
	player.global_position = Vector2(320, 240)
	for i in 5:
		await physics_frame
	assert_true(not prompt.visible, "HUD prompt hidden when far from interactables")
	main.queue_free()
	return true


func test_radar_action_exists() -> bool:
	assert_true(InputMap.has_action("radar_pulse"), "action radar_pulse exists")
	assert_true(InputMap.action_get_events("radar_pulse").size() > 0, "radar_pulse has a key event")
	return true


func test_hidden_objects_start_hidden() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var count := 0
	for node in get_nodes_in_group("hidden"):
		if node.get_parent() == level:
			count += 1
			assert_true(not node.visible, "hidden object starts invisible")
			assert_true(not node.is_revealed, "hidden object starts unrevealed")
	assert_eq(count, 3, "level has 3 hidden objects (energy cell, battery, fuse)")
	level.queue_free()
	return true


func test_pulse_reveals_near_hidden() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	var near_cache: Node2D = level.get_node("HiddenEnergyCell")
	var far_cache: Node2D = level.get_node("HiddenBattery")
	player.global_position = Vector2(96, 240)
	Input.action_press("radar_pulse")
	for i in 20:
		await physics_frame
	Input.action_release("radar_pulse")
	assert_true(near_cache.is_revealed, "pulse reveals the nearby hidden cache")
	assert_true(near_cache.visible, "revealed cache becomes visible")
	assert_true(not far_cache.is_revealed, "pulse does not reveal the far cache (beyond 160 px)")
	level.queue_free()
	return true


func test_pulse_cooldown_and_signal() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	var fired: Array = []
	player.pulse_emitted.connect(func(origin: Vector2, radius: float) -> void: fired.append([origin, radius]))
	Input.action_press("radar_pulse")
	for i in 3:
		await physics_frame
	Input.action_release("radar_pulse")
	assert_eq(player.pulses_emitted, 1, "first pulse emitted")
	assert_eq(fired.size(), 1, "pulse_emitted signal fired once")
	assert_eq(fired[0][1], 160.0, "pulse signal carries max radius 160")
	Input.action_press("radar_pulse")
	for i in 3:
		await physics_frame
	Input.action_release("radar_pulse")
	assert_eq(player.pulses_emitted, 1, "second pulse blocked during cooldown")
	player._pulse_cooldown_remaining = 0.0
	Input.action_press("radar_pulse")
	for i in 3:
		await physics_frame
	Input.action_release("radar_pulse")
	assert_eq(player.pulses_emitted, 2, "pulse emits again after cooldown reset")
	level.queue_free()
	return true


func test_hud_radar_status() -> bool:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)
	await process_frame
	var hud: CanvasLayer = main.get_node("HUD")
	var radar_label: Label = hud.get_node("RadarLabel")
	var player: CharacterBody2D = main.get_node("Level01/Player")
	for i in 3:
		await physics_frame
	assert_true(radar_label.text.contains("آماده"), "HUD radar status starts ready")
	Input.action_press("radar_pulse")
	for i in 3:
		await physics_frame
	Input.action_release("radar_pulse")
	assert_true(radar_label.text.contains("شارژ"), "HUD radar status shows recharging after pulse")
	player._pulse_cooldown_remaining = 0.0
	for i in 3:
		await physics_frame
	assert_true(radar_label.text.contains("آماده"), "HUD radar status returns to ready")
	main.queue_free()
	return true


# Enemy FSM states (must match security_robot.gd enum order).
const E_PATROL := 0
const E_INVESTIGATE := 1
const E_CHASE := 2


func test_enemy_patrols() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var enemy: CharacterBody2D = level.get_node("SecurityRobot")
	for i in 90:
		await physics_frame
	assert_true(enemy.global_position.x > 220.0, "enemy walks toward its next waypoint")
	assert_eq(enemy.state, E_PATROL, "enemy stays in PATROL while the player is out of sight")
	level.queue_free()
	return true


func test_enemy_investigates_pulse() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var enemy: CharacterBody2D = level.get_node("SecurityRobot")
	var player: CharacterBody2D = level.get_node("Player")
	# The previous test's level is freed on the first idle frame; until then
	# its player overlaps this one at the spawn and physics pushes this
	# player aside. Reset the position after that frame so the pulse origin
	# is exactly the spawn.
	player.global_position = Vector2(320, 184)
	for i in 2:
		await physics_frame
	Input.action_press("radar_pulse")
	for i in 5:
		await physics_frame
	Input.action_release("radar_pulse")
	assert_eq(enemy.state, E_INVESTIGATE, "enemy investigates the radar pulse")
	assert_true(enemy._investigate_target.distance_to(Vector2(320, 184)) < 1.0, "investigate target is the pulse origin")
	level.queue_free()
	return true


func test_enemy_chases_when_player_visible() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var enemy: CharacterBody2D = level.get_node("SecurityRobot")
	var points: Array[Vector2] = [Vector2(300, 120)]
	enemy.patrol_points = points
	for i in 150:
		await physics_frame
		if enemy.global_position.distance_to(Vector2(300, 120)) < 10.0:
			break
	var player: CharacterBody2D = level.get_node("Player")
	player.global_position = Vector2(360, 120)
	for i in 30:
		await physics_frame
	assert_eq(enemy.state, E_CHASE, "enemy chases the player in plain sight")
	level.queue_free()
	return true


func test_enemy_loses_player() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var enemy: CharacterBody2D = level.get_node("SecurityRobot")
	var points: Array[Vector2] = [Vector2(300, 120)]
	enemy.patrol_points = points
	for i in 150:
		await physics_frame
		if enemy.global_position.distance_to(Vector2(300, 120)) < 10.0:
			break
	var player: CharacterBody2D = level.get_node("Player")
	player.global_position = Vector2(360, 120)
	for i in 30:
		await physics_frame
	assert_eq(enemy.state, E_CHASE, "enemy chases before the escape")
	player.global_position = Vector2(560, 40)
	for i in 180:
		await physics_frame
	assert_eq(enemy.state, E_PATROL, "enemy gives up and returns to patrol after losing sight")
	level.queue_free()
	return true


func test_enemy_does_not_see_through_walls() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var enemy: CharacterBody2D = level.get_node("SecurityRobot")
	var points: Array[Vector2] = [Vector2(168, 200), Vector2(168, 140)]
	enemy.patrol_points = points
	for i in 220:
		await physics_frame
		if enemy.global_position.distance_to(Vector2(168, 140)) < 10.0:
			break
	var player: CharacterBody2D = level.get_node("Player")
	player.global_position = Vector2(168, 60)
	for i in 30:
		await physics_frame
	assert_eq(enemy.state, E_PATROL, "enemy does not see the player through the crate")
	level.queue_free()
	return true


func test_player_caught_respawn() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var enemy: CharacterBody2D = level.get_node("SecurityRobot")
	var player: CharacterBody2D = level.get_node("Player")
	player.global_position = enemy.global_position + Vector2(10, 0)
	for i in 10:
		await physics_frame
	assert_true(player.global_position.distance_to(Vector2(320, 184)) < 5.0, "caught player respawns at the entrance")
	assert_eq(enemy.state, E_PATROL, "enemy returns to patrol after a catch")
	level.queue_free()
	return true


func test_battery_drains() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	for i in 60:
		await physics_frame
	assert_true(player.battery > 99.2 and player.battery < 99.8, "battery drains 0.5/s (got %s)" % player.battery)
	level.queue_free()
	return true


func test_radar_costs_battery() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	player.battery = 100.0
	Input.action_press("radar_pulse")
	for i in 3:
		await physics_frame
	Input.action_release("radar_pulse")
	assert_eq(player.pulses_emitted, 1, "pulse emitted")
	assert_true(player.battery > 84.0 and player.battery < 86.0, "pulse costs 15 battery (got %s)" % player.battery)
	level.queue_free()
	return true


func test_radar_blocked_when_battery_low() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	player.battery = 10.0
	Input.action_press("radar_pulse")
	for i in 3:
		await physics_frame
	Input.action_release("radar_pulse")
	assert_eq(player.pulses_emitted, 0, "no pulse below the 15 battery cost")
	assert_true(player.battery < 10.5, "no battery spent on a blocked pulse")
	level.queue_free()
	return true


func test_hidden_pickup_collects() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var enemy: CharacterBody2D = level.get_node("SecurityRobot")
	var far_points: Array[Vector2] = [Vector2(520, 120)]
	enemy.patrol_points = far_points
	var player: CharacterBody2D = level.get_node("Player")
	var cache: Node2D = level.get_node("HiddenEnergyCell")
	player.global_position = Vector2(96, 240)
	Input.action_press("radar_pulse")
	for i in 20:
		await physics_frame
	Input.action_release("radar_pulse")
	assert_true(cache.is_revealed, "cache revealed by the pulse")
	player.global_position = Vector2(96, 280)
	for i in 5:
		await physics_frame
	assert_true(player._current_interactable == cache, "revealed cache is interactable")
	Input.action_press("interact")
	for i in 3:
		await physics_frame
	Input.action_release("interact")
	assert_eq(int(player.inventory.get("energy_cell", 0)), 1, "energy cell added to inventory")
	assert_true(player.battery > 99.0, "pickup restores battery (got %s)" % player.battery)
	assert_true(level.get_node_or_null("HiddenEnergyCell") == null, "collected cache frees itself")
	level.queue_free()
	return true


func test_visible_pickup_collects() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var enemy: CharacterBody2D = level.get_node("SecurityRobot")
	var far_points: Array[Vector2] = [Vector2(120, 120)]
	enemy.patrol_points = far_points
	var player: CharacterBody2D = level.get_node("Player")
	var pickup: Node2D = level.get_node("VisiblePickup")
	player.global_position = Vector2(120, 320)
	for i in 5:
		await physics_frame
	assert_true(player._current_interactable == pickup, "visible pickup is interactable")
	Input.action_press("interact")
	for i in 3:
		await physics_frame
	Input.action_release("interact")
	assert_eq(int(player.inventory.get("energy_cell", 0)), 1, "visible energy cell added to inventory")
	assert_true(level.get_node_or_null("VisiblePickup") == null, "collected pickup frees itself")
	level.queue_free()
	return true


func test_hud_battery_and_inventory() -> bool:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)
	await process_frame
	var hud: CanvasLayer = main.get_node("HUD")
	var bar: ProgressBar = hud.get_node("BatteryBar")
	var label: Label = hud.get_node("InventoryLabel")
	var enemy: CharacterBody2D = main.get_node("Level01/SecurityRobot")
	var far_points: Array[Vector2] = [Vector2(120, 120)]
	enemy.patrol_points = far_points
	var player: CharacterBody2D = main.get_node("Level01/Player")
	for i in 3:
		await physics_frame
	assert_true(bar.value > 99.0 and bar.value <= 100.0, "HUD battery bar shows the charge")
	assert_eq(label.text, "وسایل: —", "HUD inventory starts empty")
	player.global_position = Vector2(120, 320)
	for i in 5:
		await physics_frame
	Input.action_press("interact")
	for i in 3:
		await physics_frame
	Input.action_release("interact")
	assert_true(label.text.contains("سلول انرژی"), "HUD inventory lists the collected cell")
	main.queue_free()
	return true


func test_breaker_wrong_order_resets() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var panel: StaticBody2D = level.get_node("BreakerPanel")
	var player: CharacterBody2D = level.get_node("Player")
	player.global_position = Vector2(64, 180)
	for i in 5:
		await physics_frame
	Input.action_press("interact")
	for i in 3:
		await physics_frame
	Input.action_release("interact")
	assert_true(panel.switch1.is_on == false, "wrong first flip resets all switches off")
	assert_eq(panel._progress, 0, "progress resets to 0")
	assert_true(panel.is_solved == false, "panel not solved by a wrong flip")
	level.queue_free()
	return true


func test_breaker_correct_order_solves() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var panel: StaticBody2D = level.get_node("BreakerPanel")
	var player: CharacterBody2D = level.get_node("Player")
	for pos in [Vector2(64, 204), Vector2(64, 180), Vector2(64, 228)]:
		player.global_position = pos
		for i in 5:
			await physics_frame
		Input.action_press("interact")
		for i in 3:
			await physics_frame
		Input.action_release("interact")
	assert_true(panel.is_solved, "switches 2, 1, 3 solve the breaker panel")
	assert_eq(level._puzzles_solved, 1, "level counts the solved puzzle")
	assert_true(panel.switch2.is_on, "switches stay on after solving")
	player.global_position = Vector2(64, 204)
	for i in 5:
		await physics_frame
	Input.action_press("interact")
	for i in 3:
		await physics_frame
	Input.action_release("interact")
	assert_true(panel.switch2.is_on, "solved panel locks its switches")
	level.queue_free()
	return true


func test_wire_panel_solves() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var panel: StaticBody2D = level.get_node("WirePanel")
	var player: CharacterBody2D = level.get_node("Player")
	for round in 2:
		for pos in [Vector2(576, 180), Vector2(576, 204), Vector2(576, 228)]:
			player.global_position = pos
			for i in 5:
				await physics_frame
			Input.action_press("interact")
			for i in 3:
				await physics_frame
			Input.action_release("interact")
		if round == 0:
			assert_true(panel.is_solved == false, "one flip per terminal is not enough (all blue)")
	assert_true(panel.is_solved, "flipping each terminal twice sets all green")
	for term in [panel.terminal1, panel.terminal2, panel.terminal3]:
		assert_eq(term.color_index, 1, "terminal reads green")
	level.queue_free()
	return true


func test_fuse_box_needs_fuse() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var box: StaticBody2D = level.get_node("FuseBox")
	var player: CharacterBody2D = level.get_node("Player")
	player.global_position = Vector2(320, 312)
	for i in 5:
		await physics_frame
	Input.action_press("interact")
	for i in 3:
		await physics_frame
	Input.action_release("interact")
	assert_true(box.is_solved == false, "fuse box stays unsolved without a fuse")
	level.queue_free()
	return true


func test_fuse_box_solves_with_fuse() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var box: StaticBody2D = level.get_node("FuseBox")
	var player: CharacterBody2D = level.get_node("Player")
	player.add_item("fuse", 1, 0.0)
	player.global_position = Vector2(320, 312)
	for i in 5:
		await physics_frame
	Input.action_press("interact")
	for i in 3:
		await physics_frame
	Input.action_release("interact")
	assert_true(box.is_solved, "fuse box powers on with a fuse")
	assert_eq(int(player.inventory.get("fuse", 0)), 0, "the fuse is consumed")
	assert_eq(level._puzzles_solved, 1, "level counts the solved puzzle")
	level.queue_free()
	return true


func test_fuse_pickup_collects() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	var fuse: Node2D = level.get_node("HiddenFuse")
	player.global_position = Vector2(576, 180)
	Input.action_press("radar_pulse")
	for i in 20:
		await physics_frame
	Input.action_release("radar_pulse")
	assert_true(fuse.is_revealed, "pulse reveals the hidden fuse")
	player.global_position = Vector2(600, 100)
	for i in 5:
		await physics_frame
	Input.action_press("interact")
	for i in 3:
		await physics_frame
	Input.action_release("interact")
	assert_eq(int(player.inventory.get("fuse", 0)), 1, "fuse added to inventory")
	assert_true(level.get_node_or_null("HiddenFuse") == null, "collected fuse frees itself")
	level.queue_free()
	return true


func test_hud_puzzle_counter() -> bool:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)
	await process_frame
	var hud: CanvasLayer = main.get_node("HUD")
	var label: Label = hud.get_node("PuzzlesLabel")
	var player: CharacterBody2D = main.get_node("Level01/Player")
	assert_eq(label.text, "پازل‌های حل‌شده: 0/3", "HUD puzzle counter starts at 0/3")
	for pos in [Vector2(64, 204), Vector2(64, 180), Vector2(64, 228)]:
		player.global_position = pos
		for i in 5:
			await physics_frame
		Input.action_press("interact")
		for i in 3:
			await physics_frame
		Input.action_release("interact")
	assert_eq(label.text, "پازل‌های حل‌شده: 1/3", "HUD counter updates when a puzzle is solved")
	main.queue_free()
	return true


func _teleport_and_press(player: CharacterBody2D, pos: Vector2) -> void:
	player.global_position = pos
	for i in 5:
		await physics_frame
	Input.action_press("interact")
	for i in 3:
		await physics_frame
	Input.action_release("interact")


func _complete_mission_flow(level: Node2D, player: CharacterBody2D) -> void:
	# The robot's vision is disabled for mission-flow tests: they test
	# the mission logic, not stealth (Phase 5 covers the robot).
	var enemy: CharacterBody2D = level.get_node("SecurityRobot")
	enemy.player = null
	for pos in [Vector2(64, 204), Vector2(64, 180), Vector2(64, 228)]:
		await _teleport_and_press(player, pos)
	for round in 2:
		for pos in [Vector2(576, 180), Vector2(576, 204), Vector2(576, 228)]:
			await _teleport_and_press(player, pos)
	player.add_item("fuse", 1, 0.0)
	await _teleport_and_press(player, Vector2(320, 312))
	for pos in [Vector2(80, 72), Vector2(320, 72), Vector2(480, 296)]:
		await _teleport_and_press(player, pos)


func test_tower_blocked_without_power() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var tower: StaticBody2D = level.get_node("Tower1")
	var player: CharacterBody2D = level.get_node("Player")
	await _teleport_and_press(player, Vector2(80, 72))
	assert_true(tower.is_active == false, "tower stays offline before its puzzle is solved")
	assert_true(tower.power_restored == false, "tower has no power yet")
	level.queue_free()
	return true


func test_tower_activates_after_puzzle() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var tower1: StaticBody2D = level.get_node("Tower1")
	var tower2: StaticBody2D = level.get_node("Tower2")
	var mission: Node = level.get_node("Mission")
	var player: CharacterBody2D = level.get_node("Player")
	for pos in [Vector2(64, 204), Vector2(64, 180), Vector2(64, 228)]:
		await _teleport_and_press(player, pos)
	assert_true(tower1.power_restored, "solving the breaker powers Tower 1")
	assert_true(tower2.power_restored == false, "Tower 2 is still unpowered")
	await _teleport_and_press(player, Vector2(80, 72))
	assert_true(tower1.is_active, "powered tower activates on interact")
	assert_eq(mission.towers_active, 1, "mission counts the active tower")
	level.queue_free()
	return true


func test_mission_objectives_advance() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var mission: Node = level.get_node("Mission")
	var player: CharacterBody2D = level.get_node("Player")
	assert_true(mission.current_text().contains("وصل کردن برق"), "mission starts on the puzzles stage")
	await _complete_mission_flow(level, player)
	assert_eq(mission.towers_active, 3, "all 3 towers active")
	assert_true(mission.current_text().contains("سیگنال"), "mission advances to the transmit stage")
	level.queue_free()
	return true


func test_transmission_completes_mission() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var mission: Node = level.get_node("Mission")
	var player: CharacterBody2D = level.get_node("Player")
	await _complete_mission_flow(level, player)
	await _teleport_and_press(player, Vector2(320, 124))
	assert_true(mission.is_complete, "transmitting with all towers online completes the mission")
	assert_eq(mission.current_text(), "مأموریت کامل شد!", "mission text after completion")
	level.queue_free()
	return true


func test_transmit_blocked_early() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var mission: Node = level.get_node("Mission")
	var player: CharacterBody2D = level.get_node("Player")
	await _teleport_and_press(player, Vector2(320, 124))
	assert_true(mission.is_complete == false, "transmitter does nothing before the towers are online")
	assert_true(mission.current_text().contains("وصل کردن برق"), "mission still on the puzzles stage")
	level.queue_free()
	return true


func test_hud_objective() -> bool:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)
	await process_frame
	var hud: CanvasLayer = main.get_node("HUD")
	var label: Label = hud.get_node("ObjectiveLabel")
	var player: CharacterBody2D = main.get_node("Level01/Player")
	assert_true(label.text.contains("وصل کردن برق") and label.text.contains("(0/3)"), "HUD shows the first objective with progress")
	for pos in [Vector2(64, 204), Vector2(64, 180), Vector2(64, 228)]:
		await _teleport_and_press(player, pos)
	assert_true(label.text.contains("(1/3)"), "HUD objective progress updates when a puzzle is solved")
	main.queue_free()
	return true


func test_main_menu_loads() -> bool:
	var scene: PackedScene = load("res://scenes/ui/main_menu.tscn")
	var menu: Control = scene.instantiate()
	root.add_child(menu)
	await process_frame
	var title: Label = menu.get_node("TitleLabel")
	assert_true(title.text.contains("آخرین سیگنال"), "menu shows the game title")
	var start_button: Button = menu.get_node("StartButton")
	var quit_button: Button = menu.get_node("QuitButton")
	assert_true(start_button.pressed.is_connected(menu._on_start_pressed), "Start button is wired")
	assert_true(quit_button.pressed.is_connected(menu._on_quit_pressed), "Quit button is wired")
	assert_true(menu.get_node("ControlsLabel").text.contains("پالس رادار"), "menu lists the controls")
	menu.queue_free()
	return true


func test_pause_menu_toggles() -> bool:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)
	await process_frame
	var pause_menu: CanvasLayer = main.get_node("PauseMenu")
	assert_true(pause_menu.visible == false, "pause menu starts hidden")
	Input.action_press("pause")
	for i in 3:
		await process_frame
	Input.action_release("pause")
	assert_true(paused, "Esc pauses the tree")
	assert_true(pause_menu.visible, "pause menu shows while paused")
	Input.action_press("pause")
	for i in 3:
		await process_frame
	Input.action_release("pause")
	assert_true(paused == false, "Esc again resumes the tree")
	assert_true(pause_menu.visible == false, "pause menu hides on resume")
	main.queue_free()
	return true


func test_pause_stops_player() -> bool:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)
	await process_frame
	var player: CharacterBody2D = main.get_node("Level01/Player")
	var start_pos := player.global_position
	Input.action_press("pause")
	for i in 3:
		await process_frame
	Input.action_release("pause")
	assert_true(paused, "tree is paused for this test")
	Input.action_press("move_right")
	for i in 5:
		await process_frame
	Input.action_release("move_right")
	assert_eq(player.global_position, start_pos, "player does not move while paused")
	Input.action_press("pause")
	for i in 3:
		await process_frame
	Input.action_release("pause")
	main.queue_free()
	return true


func test_audio_manager_generates_sounds() -> bool:
	var audio: Node = load("res://scripts/audio/audio_manager.gd").new()
	root.add_child(audio)
	await process_frame
	for name in ["click", "blip", "pulse", "chime", "error", "sting", "tower", "fanfare", "ambient"]:
		assert_true(audio.has_sound(name), "audio manager has sound: " + name)
		var stream: AudioStreamWAV = audio.streams[name]
		assert_true(stream.data.size() > 0, "sound has generated data: " + name)
		assert_eq(stream.mix_rate, 22050, "sound mix rate: " + name)
	audio.play("pulse")
	audio.queue_free()
	return true


func test_fx_ring_frees_itself() -> bool:
	var scene: PackedScene = load("res://scenes/effects/fx_ring.tscn")
	var ring: Node2D = scene.instantiate()
	ring.duration = 0.2
	root.add_child(ring)
	for i in 30:
		await process_frame
	assert_true(is_instance_valid(ring) == false, "ring frees itself after its duration")
	return true


func test_hud_flash() -> bool:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)
	await process_frame
	var hud: CanvasLayer = main.get_node("HUD")
	hud.flash(Color(1, 0, 0))
	assert_true(hud.get_node("FlashRect").modulate.a > 0.1, "flash sets the overlay visible")
	# Headless frames run faster than real time, so a fixed frame count
	# is not a fixed duration: wait until the 0.5 s fade actually lands.
	for i in 600:
		if hud.get_node("FlashRect").modulate.a < 0.05:
			break
		await process_frame
	assert_true(hud.get_node("FlashRect").modulate.a < 0.05, "flash fades back to transparent")
	main.queue_free()
	return true


func test_battery_bar_red_when_low() -> bool:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)
	await process_frame
	var player: CharacterBody2D = main.get_node("Level01/Player")
	var hud: CanvasLayer = main.get_node("HUD")
	var bar: ProgressBar = hud.get_node("BatteryBar")
	player.battery = 10.0
	for i in 3:
		await physics_frame
	assert_true(bar.modulate.g < 0.5, "battery bar is red when low")
	player.battery = 100.0
	for i in 3:
		await physics_frame
	assert_true(bar.modulate.g > 0.9, "battery bar is white again when full")
	main.queue_free()
	return true


func test_full_playthrough() -> bool:
	# The capstone: the whole mission through real interactions only —
	# no add_item shortcuts. Radar reveals the hidden fuse, E collects
	# it, E inserts it, towers activate, the signal is sent.
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)
	await process_frame
	var level: Node2D = main.get_node("Level01")
	var mission: Node = level.get_node("Mission")
	var player: CharacterBody2D = level.get_node("Player")
	var hud: CanvasLayer = main.get_node("HUD")
	assert_true(hud.get_node("ObjectiveLabel").text.contains("وصل کردن برق"), "playthrough starts on the puzzles stage")
	for pos in [Vector2(64, 204), Vector2(64, 180), Vector2(64, 228)]:
		await _teleport_and_press(player, pos)
	for round in 2:
		for pos in [Vector2(576, 180), Vector2(576, 204), Vector2(576, 228)]:
			await _teleport_and_press(player, pos)
	# Real fuse flow: radar reveals it, E collects it, E inserts it.
	player.global_position = Vector2(576, 100)
	for i in 5:
		await physics_frame
	Input.action_press("radar_pulse")
	for i in 5:
		await physics_frame
	Input.action_release("radar_pulse")
	var fuse: Node = level.get_node("HiddenFuse")
	for i in 120:
		if fuse.visible:
			break
		await physics_frame
	assert_true(fuse.visible, "radar reveals the hidden fuse")
	await _teleport_and_press(player, Vector2(576, 100))
	assert_true(int(player.inventory.get("fuse", 0)) >= 1, "fuse collected")
	assert_true(hud.get_node("InventoryLabel").text.contains("فیوز"), "inventory label names the fuse")
	await _teleport_and_press(player, Vector2(320, 312))
	assert_eq(level._puzzles_solved, 3, "all 3 puzzles solved in the playthrough")
	assert_true(mission.current_text().contains("دکل"), "mission advances to the towers stage")
	for pos in [Vector2(80, 72), Vector2(320, 72), Vector2(480, 296)]:
		await _teleport_and_press(player, pos)
	assert_eq(mission.towers_active, 3, "all 3 towers active in the playthrough")
	# The transmit console's stand position (320, 124) sits 4 px below
	# the robot's top patrol edge: if the robot happens to be passing
	# there, it catches the player mid-press and the E never lands.
	# Wait until it is far away before the final press.
	var enemy: CharacterBody2D = level.get_node("SecurityRobot")
	for i in 600:
		if enemy.global_position.distance_to(Vector2(320, 124)) > 150.0:
			break
		await physics_frame
	await _teleport_and_press(player, Vector2(320, 124))
	assert_true(mission.is_complete, "playthrough completes the mission")
	assert_eq(hud.get_node("ObjectiveLabel").text, "مأموریت کامل شد!", "HUD shows mission complete")
	var win: CanvasLayer = main.get_node("WinScreen")
	assert_true(win.visible, "win screen shows at the end of the playthrough")
	win.hide_win()
	main.queue_free()
	return true


func test_win_screen_shows() -> bool:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)
	await process_frame
	var level: Node2D = main.get_node("Level01")
	var mission: Node = level.get_node("Mission")
	var player: CharacterBody2D = level.get_node("Player")
	await _complete_mission_flow(level, player)
	await _teleport_and_press(player, Vector2(320, 124))
	assert_true(mission.is_complete, "mission completes before the win screen check")
	var win: CanvasLayer = main.get_node("WinScreen")
	assert_true(win.visible, "win screen is visible after the mission completes")
	assert_true(paused, "win screen pauses the tree")
	assert_true(win.get_node("Panel/TitleLabel").text.contains("مأموریت کامل شد"), "win screen has the title")
	assert_true(win.get_node("Panel/AgainButton").text.contains("بازی دوباره"), "win screen offers Play Again")
	win.hide_win()
	main.queue_free()
	return true


func test_effect_spam_stress() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var rings: Array[Node2D] = []
	for i in 20:
		var ring: Node2D = load("res://scenes/effects/fx_ring.tscn").instantiate()
		ring.position = Vector2(320, 184)
		level.add_child(ring)
		rings.append(ring)
	for i in 5:
		var pulse: Node2D = load("res://scenes/systems/radar_pulse.tscn").instantiate()
		level.add_child(pulse)
		pulse.global_position = Vector2(320, 184)
	# Headless frames run faster than real time: wait until the effects
	# actually finish instead of counting frames.
	for i in 600:
		var alive := false
		for ring in rings:
			if is_instance_valid(ring):
				alive = true
				break
		if not alive:
			break
		await process_frame
	for ring in rings:
		assert_true(is_instance_valid(ring) == false, "all spam rings freed themselves")
	var player: CharacterBody2D = level.get_node("Player")
	var start_pos := player.global_position
	Input.action_press("move_right")
	for i in 5:
		await physics_frame
	Input.action_release("move_right")
	assert_true(player.global_position != start_pos, "game still runs after the effect spam")
	level.queue_free()
	return true


func test_win_screen_blocks_pause() -> bool:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)
	await process_frame
	var level: Node2D = main.get_node("Level01")
	var player: CharacterBody2D = level.get_node("Player")
	await _complete_mission_flow(level, player)
	await _teleport_and_press(player, Vector2(320, 124))
	var win: CanvasLayer = main.get_node("WinScreen")
	assert_true(win.visible, "win screen is up for this test")
	var pause_menu: CanvasLayer = main.get_node("PauseMenu")
	Input.action_press("pause")
	for i in 3:
		await process_frame
	Input.action_release("pause")
	assert_true(pause_menu.visible == false, "pause menu stays hidden while the win screen is up")
	assert_true(paused, "tree stays paused by the win screen")
	win.hide_win()
	main.queue_free()
	return true


func test_player_moves_and_wall_blocks() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	var start_x: float = player.global_position.x
	Input.action_press("move_right")
	for i in 30:
		await physics_frame
	Input.action_release("move_right")
	assert_true(player.global_position.x > start_x + 10.0, "player moves right")
	# Push into the left wall: position must never cross the wall inner edge (x=16 + half width 6 = 22).
	player.global_position = Vector2(30, 184)
	player.velocity = Vector2.ZERO
	await physics_frame
	Input.action_press("move_left")
	for i in 60:
		await physics_frame
	Input.action_release("move_left")
	assert_true(player.global_position.x >= 21.0, "left wall blocks player (x=%s)" % player.global_position.x)
	assert_true(player.global_position.x <= 640.0 and player.global_position.y <= 368.0, "player stays in room")
	level.queue_free()
	return true

# --- 2026-11-12 v1.1 fixes: radar radius, ambient audio, walk animation,
# --- pathfinding, areas, scanner, radar occlusion, environment props.
# --- (TDD: each test was written against the pre-fix behavior first.)

func test_radar_investigates_inside_radius() -> bool:
	var scene: PackedScene = load("res://scenes/enemies/security_robot.tscn")
	var enemy: CharacterBody2D = scene.instantiate()
	root.add_child(enemy)
	await process_frame
	enemy.global_position = Vector2(0, 0)
	enemy.investigate(Vector2(100, 0), 160.0)
	assert_eq(enemy.state, E_INVESTIGATE, "enemy inside radius investigates")
	assert_true(enemy._investigate_target.distance_to(Vector2(100, 0)) < 1.0, "investigate target is the pulse origin")
	enemy.queue_free()
	return true


func test_radar_ignores_outside_radius() -> bool:
	var scene: PackedScene = load("res://scenes/enemies/security_robot.tscn")
	var enemy: CharacterBody2D = scene.instantiate()
	root.add_child(enemy)
	await process_frame
	enemy.global_position = Vector2(0, 0)
	enemy.investigate(Vector2(200, 0), 160.0)
	assert_eq(enemy.state, E_PATROL, "enemy outside radius stays in PATROL")
	enemy.queue_free()
	return true


func test_radar_boundary_investigates() -> bool:
	var scene: PackedScene = load("res://scenes/enemies/security_robot.tscn")
	var enemy: CharacterBody2D = scene.instantiate()
	root.add_child(enemy)
	await process_frame
	enemy.global_position = Vector2(0, 0)
	enemy.investigate(Vector2(160, 0), 160.0)
	assert_eq(enemy.state, E_INVESTIGATE, "enemy exactly at the radius investigates")
	enemy.queue_free()
	return true


func test_radar_does_not_interrupt_chase() -> bool:
	var scene: PackedScene = load("res://scenes/enemies/security_robot.tscn")
	var enemy: CharacterBody2D = scene.instantiate()
	root.add_child(enemy)
	await process_frame
	enemy.global_position = Vector2(0, 0)
	enemy.state = E_CHASE
	enemy.investigate(Vector2(10, 0), 160.0)
	assert_eq(enemy.state, E_CHASE, "pulse never interrupts a chase")
	enemy.queue_free()
	return true


func test_radar_multiple_enemies_by_distance() -> bool:
	var scene: PackedScene = load("res://scenes/enemies/security_robot.tscn")
	var near: CharacterBody2D = scene.instantiate()
	var far: CharacterBody2D = scene.instantiate()
	root.add_child(near)
	root.add_child(far)
	await process_frame
	near.global_position = Vector2(50, 0)
	far.global_position = Vector2(500, 0)
	near.investigate(Vector2(0, 0), 160.0)
	far.investigate(Vector2(0, 0), 160.0)
	assert_eq(near.state, E_INVESTIGATE, "near enemy investigates")
	assert_eq(far.state, E_PATROL, "far enemy ignores the same pulse")
	near.queue_free()
	far.queue_free()
	return true


func test_ambient_has_no_fade() -> bool:
	var audio: Node = load("res://scripts/audio/audio_manager.gd").new()
	root.add_child(audio)
	await process_frame
	var stream: AudioStreamWAV = audio.streams["ambient"]
	assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD, "ambient loops forward")
	assert_eq(stream.loop_end, 44100, "ambient loop covers the full 2 s")
	var data: PackedByteArray = stream.data
	var first_max := 0
	for i in 2205:
		first_max = maxi(first_max, absi(data.decode_s16(i * 2)))
	var last_max := 0
	for i in range(44100 - 2205, 44100):
		last_max = maxi(last_max, absi(data.decode_s16(i * 2)))
	assert_true(first_max > 5000, "ambient starts loud (got %s)" % first_max)
	assert_true(last_max > first_max * 0.5, "ambient does not fade out at the loop end (first %s, last %s)" % [first_max, last_max])
	audio.queue_free()
	return true


func test_sfx_still_fade() -> bool:
	var audio: Node = load("res://scripts/audio/audio_manager.gd").new()
	root.add_child(audio)
	await process_frame
	var stream: AudioStreamWAV = audio.streams["pulse"]
	var data: PackedByteArray = stream.data
	var samples := data.size() / 2
	var first_max := 0
	for i in 220:
		first_max = maxi(first_max, absi(data.decode_s16(i * 2)))
	var last_max := 0
	for i in range(samples - 220, samples):
		last_max = maxi(last_max, absi(data.decode_s16(i * 2)))
	assert_true(first_max > 5000, "pulse SFX starts loud")
	assert_true(last_max < first_max * 0.2, "pulse SFX still fades out (first %s, last %s)" % [first_max, last_max])
	audio.queue_free()
	return true


func test_ambient_pause_resume_volume() -> bool:
	var audio: Node = load("res://scripts/audio/audio_manager.gd").new()
	root.add_child(audio)
	await process_frame
	audio.start_ambient()
	assert_true(audio._ambient_player.stream_paused == false, "ambient unpaused after start")
	audio.pause_ambient()
	assert_true(audio._ambient_player.stream_paused == true, "ambient pauses")
	audio.resume_ambient()
	assert_true(audio._ambient_player.stream_paused == false, "ambient resumes")
	audio.set_ambient_volume_db(-12.0)
	assert_eq(audio._ambient_player.volume_db, -12.0, "ambient volume control works")
	audio.stop_ambient()
	audio.queue_free()
	return true


func test_player_walk_down() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	Input.action_press("move_down")
	for i in 20:
		await physics_frame
	assert_eq(player.get_node("Sprite2D").animation, "walk_down", "moving down plays walk_down")
	assert_eq(player.facing_direction, "down", "facing is down")
	Input.action_release("move_down")
	level.queue_free()
	return true


func test_player_walk_up() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	Input.action_press("move_up")
	for i in 20:
		await physics_frame
	assert_eq(player.get_node("Sprite2D").animation, "walk_up", "moving up plays walk_up")
	assert_eq(player.facing_direction, "up", "facing is up")
	Input.action_release("move_up")
	level.queue_free()
	return true


func test_player_walk_left() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	Input.action_press("move_left")
	for i in 20:
		await physics_frame
	assert_eq(player.get_node("Sprite2D").animation, "walk_left", "moving left plays walk_left")
	assert_true(player.get_node("Sprite2D").flip_h, "walk_left flips the sprite")
	Input.action_release("move_left")
	level.queue_free()
	return true


func test_player_walk_right() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	Input.action_press("move_right")
	for i in 20:
		await physics_frame
	assert_eq(player.get_node("Sprite2D").animation, "walk_right", "moving right plays walk_right")
	assert_true(not player.get_node("Sprite2D").flip_h, "walk_right does not flip")
	Input.action_release("move_right")
	level.queue_free()
	return true


func test_player_idle_preserves_facing() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	Input.action_press("move_up")
	for i in 20:
		await physics_frame
	Input.action_release("move_up")
	for i in 40:
		await physics_frame
	assert_eq(player.facing_direction, "up", "facing stays up after stopping")
	assert_eq(player.get_node("Sprite2D").animation, "idle_up", "stopping after moving up plays idle_up")
	level.queue_free()
	return true


func test_player_diagonal_uses_cardinal_animation() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	Input.action_press("move_right")
	Input.action_press("move_up")
	for i in 20:
		await physics_frame
	var anim: String = player.get_node("Sprite2D").animation
	assert_true(anim == "walk_right" or anim == "walk_up", "diagonal uses a cardinal walk animation (got %s)" % anim)
	assert_true(player.velocity.length() <= 201.0, "diagonal speed still capped")
	Input.action_release("move_right")
	Input.action_release("move_up")
	level.queue_free()
	return true


func test_player_animation_stops_at_wall() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	player.global_position = Vector2(30, 184)
	player.velocity = Vector2.ZERO
	await physics_frame
	Input.action_press("move_left")
	for i in 60:
		await physics_frame
	Input.action_release("move_left")
	assert_true(str(player.get_node("Sprite2D").animation).begins_with("idle_"), "pushing into a wall returns to idle (got %s)" % player.get_node("Sprite2D").animation)
	assert_eq(player.facing_direction, "left", "facing is left after pushing the west wall")
	level.queue_free()
	return true


func test_player_spriteframes_complete() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var sprite: AnimatedSprite2D = level.get_node("Player/Sprite2D")
	for anim in ["idle_down", "idle_up", "idle_left", "idle_right", "walk_down", "walk_up", "walk_left", "walk_right"]:
		assert_true(sprite.sprite_frames.has_animation(anim), "animation exists: " + anim)
	for anim in ["walk_down", "walk_up", "walk_left", "walk_right"]:
		assert_eq(sprite.sprite_frames.get_frame_count(anim), 4, "walk animation has 4 frames: " + anim)
		assert_eq(sprite.sprite_frames.get_animation_speed(anim), 8.0, "walk animation runs at 8 FPS: " + anim)
	for anim in ["idle_down", "idle_up", "idle_left", "idle_right"]:
		assert_eq(sprite.sprite_frames.get_frame_count(anim), 1, "idle animation has 1 frame: " + anim)
	# Walk frames must be genuinely different images, not the same frame 4x.
	var f0: Texture2D = sprite.sprite_frames.get_frame_texture("walk_down", 0)
	var f1: Texture2D = sprite.sprite_frames.get_frame_texture("walk_down", 1)
	var f2: Texture2D = sprite.sprite_frames.get_frame_texture("walk_down", 2)
	assert_true(f0 != f1 and f1 != f2 and f0 != f2, "walk_down frames are distinct textures")
	level.queue_free()
	return true


func test_enemy_path_avoids_crate() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var enemy: CharacterBody2D = level.get_node("SecurityRobot")
	assert_true(enemy.nav_grid != null, "level assigns a nav grid to the enemy")
	var path: Array[Vector2] = enemy._compute_path(Vector2(100, 88))
	assert_true(not path.is_empty(), "a path around the crate exists")
	for wp in path:
		var cell := Vector2i(int(wp.x / 16.0), int(wp.y / 16.0))
		assert_true(cell != Vector2i(10, 5), "path never crosses the crate cell (10,5)")
	level.queue_free()
	return true


func test_enemy_navigates_around_crate() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var enemy: CharacterBody2D = level.get_node("SecurityRobot")
	enemy.global_position = Vector2(260, 88)
	enemy.investigate(Vector2(100, 88), 200.0)
	assert_eq(enemy.state, E_INVESTIGATE, "enemy investigates a pulse behind the crate")
	var reached := false
	for i in 600:
		await physics_frame
		if enemy.global_position.distance_to(Vector2(100, 88)) < 24.0:
			reached = true
			break
	assert_true(reached, "enemy reaches the target behind the crate (at %s)" % enemy.global_position)
	level.queue_free()
	return true


func test_enemy_path_through_doorway() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var enemy: CharacterBody2D = level.get_node("SecurityRobot")
	enemy.global_position = Vector2(500, 256)
	var path: Array[Vector2] = enemy._compute_path(Vector2(760, 256))
	var through_door := false
	for wp in path:
		if wp.x > 624.0 and wp.x < 656.0 and wp.y >= 240.0 and wp.y < 272.0:
			through_door = true
	assert_true(through_door, "path to Medical Wing goes through the doorway, not the wall")
	enemy.investigate(Vector2(760, 256), 300.0)
	var reached := false
	for i in 600:
		await physics_frame
		if enemy.global_position.distance_to(Vector2(760, 256)) < 24.0:
			reached = true
			break
	assert_true(reached, "enemy reaches Medical Wing through the doorway (at %s)" % enemy.global_position)
	level.queue_free()
	return true


func test_enemy_no_grid_fallback() -> bool:
	var scene: PackedScene = load("res://scenes/enemies/security_robot.tscn")
	var enemy: CharacterBody2D = scene.instantiate()
	root.add_child(enemy)
	await process_frame
	assert_true(enemy.nav_grid == null, "standalone robot has no nav grid")
	enemy.global_position = Vector2(0, 0)
	var arrived: bool = enemy._move_toward(Vector2(100, 0), 70.0)
	assert_true(not arrived, "not arrived yet")
	assert_true(enemy.velocity.x > 0.0 and absf(enemy.velocity.y) < 0.01, "fallback steers directly at the target")
	enemy.queue_free()
	return true


func test_area_medical_entry() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	player.global_position = Vector2(600, 256)
	player.velocity = Vector2.ZERO
	await physics_frame
	Input.action_press("move_right")
	var entered := false
	for i in 120:
		await physics_frame
		if level.current_area == "بخش پزشکی":
			entered = true
			break
	assert_true(entered, "walking through the doorway enters Medical Wing")
	# The zone fires when the player's leading edge crosses x=640, so
	# keep walking a few frames to get the center fully through.
	for i in 20:
		await physics_frame
	Input.action_release("move_right")
	assert_true(player.global_position.x > 660.0, "player crossed into Medical Wing (x=%s)" % player.global_position.x)
	level.queue_free()
	return true


func test_area_wall_blocks_except_doorway() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	player.global_position = Vector2(600, 100)
	player.velocity = Vector2.ZERO
	await physics_frame
	Input.action_press("move_right")
	for i in 60:
		await physics_frame
	Input.action_release("move_right")
	assert_true(player.global_position.x < 640.0, "wall blocks entry away from the doorway (x=%s)" % player.global_position.x)
	assert_eq(level.current_area, "کنترل مرکزی", "player is still in Central Control")
	level.queue_free()
	return true


func test_areas_reachable_by_walking() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	# Central -> Research Laboratory (doorway x 288-320, y 352-368).
	player.global_position = Vector2(300, 330)
	player.velocity = Vector2.ZERO
	await physics_frame
	Input.action_press("move_down")
	for i in 120:
		await physics_frame
		if level.current_area == "آزمایشگاه تحقیقاتی":
			break
	Input.action_release("move_down")
	assert_eq(level.current_area, "آزمایشگاه تحقیقاتی", "walked into Research Laboratory")
	# Laboratory -> Power Station (doorway y 528-560, x 624-640).
	player.global_position = Vector2(600, 544)
	player.velocity = Vector2.ZERO
	await physics_frame
	Input.action_press("move_right")
	for i in 120:
		await physics_frame
		if level.current_area == "نیروگاه":
			break
	Input.action_release("move_right")
	assert_eq(level.current_area, "نیروگاه", "walked into Power Station")
	# Power Station -> Communication Yard (doorway x 928-960, y 728-736).
	player.global_position = Vector2(944, 700)
	player.velocity = Vector2.ZERO
	await physics_frame
	Input.action_press("move_down")
	for i in 120:
		await physics_frame
		if level.current_area == "محوطه‌ی مخابرات":
			break
	Input.action_release("move_down")
	assert_eq(level.current_area, "محوطه‌ی مخابرات", "walked into Communication Yard")
	level.queue_free()
	return true


func test_scanner_stays_at_post_and_scans() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var scanner: CharacterBody2D = level.get_node("ScannerRobot")
	scanner.scan_interval = 0.5
	var post: Vector2 = scanner.global_position
	for i in 120:
		await physics_frame
	assert_true(scanner.global_position.distance_to(post) < 20.0, "scanner stays at its post")
	assert_true(scanner.scan_count >= 1, "scanner completes scan sweeps")
	level.queue_free()
	return true


func test_scanner_chases_visible_player() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var scanner: CharacterBody2D = level.get_node("ScannerRobot")
	var player: CharacterBody2D = level.get_node("Player")
	scanner._facing = Vector2.DOWN
	player.global_position = Vector2(900, 200)
	var chased := false
	for i in 60:
		await physics_frame
		if scanner.state == E_CHASE:
			chased = true
			break
	assert_true(chased, "scanner chases a player in its wide vision cone")
	level.queue_free()
	return true


func test_scanner_returns_to_post() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var scanner: CharacterBody2D = level.get_node("ScannerRobot")
	var player: CharacterBody2D = level.get_node("Player")
	scanner._facing = Vector2.DOWN
	player.global_position = Vector2(900, 200)
	for i in 60:
		await physics_frame
		if scanner.state == E_CHASE:
			break
	player.global_position = Vector2(100, 100)
	var home := false
	for i in 900:
		await physics_frame
		if scanner.state == E_PATROL and scanner.global_position.distance_to(Vector2(900, 120)) < 24.0:
			home = true
			break
	assert_true(home, "scanner returns to its post after losing the player (at %s, state %s)" % [scanner.global_position, scanner.state])
	level.queue_free()
	return true


func test_radar_blocked_by_crate() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var hidden_scene: PackedScene = load("res://scenes/interaction/hidden_object.tscn")
	var hidden: Node2D = hidden_scene.instantiate()
	hidden.position = Vector2(168, 40)
	level.add_child(hidden)
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	player.global_position = Vector2(168, 140)
	player.velocity = Vector2.ZERO
	for i in 2:
		await physics_frame
	Input.action_press("radar_pulse")
	for i in 5:
		await physics_frame
	Input.action_release("radar_pulse")
	for i in 40:
		await physics_frame
	assert_true(hidden.get("is_revealed") == false, "radar does not reveal through the crate")
	level.queue_free()
	return true


func test_radar_reveals_with_line_of_sight() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var hidden_scene: PackedScene = load("res://scenes/interaction/hidden_object.tscn")
	var hidden: Node2D = hidden_scene.instantiate()
	hidden.position = Vector2(168, 40)
	level.add_child(hidden)
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	player.global_position = Vector2(100, 40)
	player.velocity = Vector2.ZERO
	for i in 2:
		await physics_frame
	Input.action_press("radar_pulse")
	for i in 5:
		await physics_frame
	Input.action_release("radar_pulse")
	for i in 40:
		await physics_frame
	assert_true(hidden.get("is_revealed") == true, "radar reveals with a clear line of sight")
	level.queue_free()
	return true


func test_radar_blocked_by_alcove_wall() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var hidden_scene: PackedScene = load("res://scenes/interaction/hidden_object.tscn")
	var hidden: Node2D = hidden_scene.instantiate()
	hidden.position = Vector2(560, 40)
	level.add_child(hidden)
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	player.global_position = Vector2(320, 184)
	player.velocity = Vector2.ZERO
	for i in 2:
		await physics_frame
	Input.action_press("radar_pulse")
	for i in 5:
		await physics_frame
	Input.action_release("radar_pulse")
	for i in 40:
		await physics_frame
	assert_true(hidden.get("is_revealed") == false, "radar does not reveal inside the alcove through its wall")
	level.queue_free()
	return true


func test_environment_props_exist() -> bool:
	for path in ["res://assets/sprites/props/control_panel.png", "res://assets/sprites/props/fuse_box_prop.png", "res://assets/sprites/props/riveted_panel.png", "res://assets/sprites/characters/scanner_robot.png"]:
		assert_true(FileAccess.file_exists(path), "atlas prop exists: " + path)
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	assert_true(level.get_node_or_null("AreaWalls") != null, "area walls built")
	assert_true(level.get_node_or_null("ScannerRobot") != null, "scanner robot placed in the level")
	level.queue_free()
	return true


## Medical Wing pack (2026-11-15): the wing's floor comes from the
## pack's 12-tile atlas, not the old two-tile atlas; Central is untouched.
func test_medical_floor_uses_medical_atlas() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var floor_layer: TileMapLayer = level.get_node("Floor")
	var central_source: int = floor_layer.get_cell_source_id(Vector2i(5, 5))
	var med_source: int = floor_layer.get_cell_source_id(Vector2i(50, 10))
	assert_true(central_source != med_source, "medical floor uses its own atlas source")
	var wrong := 0
	var seen := {}
	for x in range(40, 80):
		for y in 23:
			if floor_layer.get_cell_source_id(Vector2i(x, y)) != med_source:
				wrong += 1
			seen[floor_layer.get_cell_atlas_coords(Vector2i(x, y))] = true
	assert_eq(wrong, 0, "all 920 medical floor cells use the medical atlas")
	assert_true(seen.size() >= 10, "medical floor shows at least 10 of its 12 tiles (got %d)" % seen.size())
	level.queue_free()
	return true


## Medical Wing pack: every prop file exists and loads, the named
## furniture/decor is placed, and the medical console shows the vitals
## monitor instead of the generic console sprite.
func test_medical_props_exist() -> bool:
	var script: GDScript = load("res://scripts/levels/level_01.gd")
	for key in script.MED_PROP_PATHS:
		var path: String = script.MED_PROP_PATHS[key]
		assert_true(FileAccess.file_exists(path), "medical prop file exists: " + key)
		assert_true(load(path) != null, "medical prop loads: " + key)
	assert_true(FileAccess.file_exists("res://assets/sprites/environment/floor_medical_atlas.png"), "medical floor atlas exists")
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	for node_name in ["MedBedStandard", "MedBedEmpty", "MedExamBed", "MedBedDisorganized", "MedStretcher", "MedDeskDoctor", "MedCabinetOpen", "MedShelfMedicine", "MedFlashlight", "MedNoteDoctor", "MedWindowObservation", "MedCornerSW", "MedCornerSE"]:
		assert_true(level.get_node_or_null(node_name) != null, "medical prop placed: " + node_name)
	var monitor_tex: Texture2D = load("res://assets/sprites/medical-wing/monitor_vitals.png")
	var found := false
	for child in level.get_children():
		if child is Node2D and (child as Node2D).position == Vector2(760, 80):
			var sprite: Sprite2D = (child as Node2D).get_node_or_null("Sprite2D")
			if sprite != null and sprite.texture == monitor_tex:
				found = true
	assert_true(found, "medical console uses the vitals monitor texture")
	level.queue_free()
	return true


## Medical Wing pack: the new solid furniture must not close either
## doorway of the wing in the nav grid.
func test_medical_doorways_stay_open() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var enemy: CharacterBody2D = level.get_node("SecurityRobot")
	assert_true(enemy.nav_grid != null, "level assigns a nav grid to the enemy")
	var grid: AStarGrid2D = enemy.nav_grid
	for cell in [Vector2i(39, 15), Vector2i(39, 16), Vector2i(58, 22), Vector2i(59, 22)]:
		assert_true(not grid.is_point_solid(cell), "medical doorway cell stays open: %s" % cell)
	level.queue_free()
	return true


## Medical Wing pack: the hidden fuse pickup shows the pack's white fuse.
func test_medical_fuse_texture() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var fuse: Node2D = level.get_node("HiddenFuse")
	var sprite: Sprite2D = fuse.get_node("Sprite2D")
	var fuse_tex: Texture2D = load("res://assets/sprites/medical-wing/fuse_a.png")
	assert_true(sprite.texture == fuse_tex, "hidden fuse uses the pack's white fuse")
	level.queue_free()
	return true


func _load_main() -> Node:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)
	return main


func test_minimap_action_exists() -> bool:
	assert_true(InputMap.has_action("toggle_minimap"), "action toggle_minimap exists")
	assert_true(InputMap.action_get_events("toggle_minimap").size() > 0, "toggle_minimap has a key event")
	return true


func test_minimap_in_hud() -> bool:
	var main: Node = _load_main()
	await process_frame
	var hud: CanvasLayer = main.get_node("HUD")
	var minimap: Control = hud.get_node("Minimap")
	assert_true(minimap != null, "HUD has a Minimap node")
	assert_true(minimap.visible, "minimap visible by default")
	assert_true(minimap.size == Vector2(208, 151), "minimap is 208x151")
	assert_true(hud.get_node_or_null("MinimapLabel") != null, "HUD has a MinimapLabel")
	assert_true(hud.get_node_or_null("MinimapLegend") != null, "HUD has a MinimapLegend")
	main.queue_free()
	return true


func test_minimap_world_to_map() -> bool:
	var script: GDScript = load("res://scripts/ui/minimap.gd")
	var minimap: Control = script.new()
	assert_true((minimap.world_to_map(Vector2.ZERO) - Vector2.ZERO).length() < 0.01, "map origin is (0,0)")
	assert_true((minimap.world_to_map(Vector2(1280, 928)) - Vector2(208, 150.8)).length() < 0.01, "map far corner is (208,150.8)")
	assert_true((minimap.world_to_map(Vector2(640, 464)) - Vector2(104, 75.4)).length() < 0.01, "map center is (104,75.4)")
	minimap.queue_free()
	return true


func test_minimap_tracks_player() -> bool:
	var main: Node = _load_main()
	await process_frame
	await process_frame
	var hud: CanvasLayer = main.get_node("HUD")
	var minimap: Control = hud.get_node("Minimap")
	var player: CharacterBody2D = main.get_node("Level01/Player")
	player.global_position = Vector2(320, 184)
	assert_true((minimap.player_map_position() - Vector2(52, 29.9)).length() < 0.05, "player dot follows the player on the map")
	player.global_position = Vector2(960, 800)
	assert_true((minimap.player_map_position() - Vector2(156, 130)).length() < 0.05, "player dot follows into the Power Station")
	main.queue_free()
	return true


func test_minimap_tower_states() -> bool:
	var main: Node = _load_main()
	await process_frame
	await process_frame
	var hud: CanvasLayer = main.get_node("HUD")
	var minimap: Control = hud.get_node("Minimap")
	var tower: Node = main.get_node("Level01/Tower1")
	assert_eq(minimap.tower_state(tower), 0, "tower starts offline on the map")
	tower.power_restored = true
	assert_eq(minimap.tower_state(tower), 1, "powered tower shows powered on the map")
	tower.is_active = true
	assert_eq(minimap.tower_state(tower), 2, "online tower shows online on the map")
	main.queue_free()
	return true


func test_minimap_enemies_revealed_by_pulse() -> bool:
	var main: Node = _load_main()
	await process_frame
	await process_frame
	var hud: CanvasLayer = main.get_node("HUD")
	var minimap: Control = hud.get_node("Minimap")
	var player: CharacterBody2D = main.get_node("Level01/Player")
	var robot: Node = main.get_node("Level01/SecurityRobot")
	var scanner: Node = main.get_node("Level01/ScannerRobot")
	assert_eq(minimap.revealed_enemy_count(), 0, "no enemy on the map before any pulse")
	player.global_position = Vector2(320, 184)
	Input.action_press("radar_pulse")
	for i in 20:
		await physics_frame
	Input.action_release("radar_pulse")
	assert_true(minimap.is_enemy_revealed(robot), "patrol robot marked on the map after a pulse in range")
	assert_true(not minimap.is_enemy_revealed(scanner), "distant scanner not marked by the same pulse")
	# Expired marks disappear: backdate the mark and it must read unrevealed.
	minimap._enemy_marks[robot] = -100.0
	assert_true(not minimap.is_enemy_revealed(robot), "expired pulse mark drops off the map")
	main.queue_free()
	return true


func test_minimap_toggle() -> bool:
	var main: Node = _load_main()
	await process_frame
	var hud: CanvasLayer = main.get_node("HUD")
	var minimap: Control = hud.get_node("Minimap")
	hud.toggle_minimap()
	assert_true(not minimap.visible, "M toggle hides the minimap")
	assert_true(not hud.get_node("MinimapLabel").visible, "M toggle hides the area label too")
	hud.toggle_minimap()
	assert_true(minimap.visible, "M toggle shows the minimap again")
	main.queue_free()
	return true


func test_minimap_hidden_objects_only_when_revealed() -> bool:
	var main: Node = _load_main()
	await process_frame
	await process_frame
	var hud: CanvasLayer = main.get_node("HUD")
	var minimap: Control = hud.get_node("Minimap")
	assert_eq(minimap.hidden_objects.size(), 3, "minimap knows all three hidden caches (cell, battery, fuse)")
	var cache: Node2D = main.get_node("Level01/HiddenEnergyCell")
	assert_true(cache.get("is_revealed") == false, "cache starts unrevealed")
	cache.reveal()
	assert_true(cache.get("is_revealed") == true, "revealed cache is now tracked")
	main.queue_free()
	return true


func test_minimap_area_label() -> bool:
	var main: Node = _load_main()
	await process_frame
	var hud: CanvasLayer = main.get_node("HUD")
	assert_eq(hud.get_node("MinimapLabel").text, "کنترل مرکزی", "area label starts at Central Control")
	hud.set_minimap_area("بخش پزشکی")
	assert_eq(hud.get_node("MinimapLabel").text, "بخش پزشکی", "area label follows the player")
	main.queue_free()
	return true


func test_wall_texture_file() -> bool:
	assert_true(FileAccess.file_exists("res://assets/sprites/environment/wall_metal.png"), "wall tile exists")
	var tex: Texture2D = load("res://assets/sprites/environment/wall_metal.png")
	assert_true(tex != null, "wall tile loads")
	assert_eq(tex.get_width(), 16, "wall tile is 16 px wide")
	assert_eq(tex.get_height(), 16, "wall tile is 16 px tall")
	return true


func test_wall_texture_applied() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var tex: Texture2D = load("res://assets/sprites/environment/wall_metal.png")
	# .tscn ring + alcove walls.
	for node_name in ["Walls/WallTopVisual", "Walls/WallLeftVisual", "AlcoveWalls/WallVVisual", "AlcoveWalls/WallHLeftVisual", "AlcoveWalls/WallHRightVisual"]:
		var poly: Polygon2D = level.get_node(node_name)
		assert_true(poly.texture == tex, "textured wall visual: " + node_name)
		assert_eq(poly.texture_repeat, CanvasItem.TEXTURE_REPEAT_ENABLED, "wall texture repeats: " + node_name)
		assert_true(poly.color == Color.WHITE, "wall visual color is white (no dark multiply): " + node_name)
	# Code-built area walls: every Polygon2D under AreaWalls is textured.
	# The Medical Wing's own walls use the pack's wall tiles instead of
	# wall_metal (2026-11-15); the rest keep wall_metal.
	var med_h: Texture2D = load("res://assets/sprites/medical-wing/wall_h.png")
	var med_v: Texture2D = load("res://assets/sprites/medical-wing/wall_v.png")
	var area_walls: Node2D = level.get_node("AreaWalls")
	var textured := 0
	var med_textured := 0
	for child in area_walls.get_children():
		if child is Polygon2D:
			var t: Texture2D = (child as Polygon2D).texture
			if t == tex or t == med_h or t == med_v:
				textured += 1
			if t == med_h or t == med_v:
				med_textured += 1
	assert_true(textured >= 16, "code-built area walls textured (%d)" % textured)
	assert_eq(med_textured, 5, "five Medical Wing wall visuals use the pack's wall tiles")
	level.queue_free()
	return true


func test_persian_font_file() -> bool:
	assert_true(FileAccess.file_exists("res://assets/fonts/Vazirmatn-Regular.ttf"), "Vazirmatn Regular exists")
	assert_true(FileAccess.file_exists("res://assets/fonts/Vazirmatn-Bold.ttf"), "Vazirmatn Bold exists")
	var font: Font = load("res://assets/fonts/Vazirmatn-Regular.ttf")
	assert_true(font != null, "Vazirmatn Regular loads as a font")
	assert_true(font.get_glyph_index(0x0627, 0, 0) != 0, "font has a glyph for Persian alef")
	assert_true(font.get_glyph_index(0x06CC, 0, 0) != 0, "font has a glyph for Persian ye")
	assert_eq(ProjectSettings.get_setting("gui/theme/default_font"), "res://assets/fonts/Vazirmatn-Regular.ttf", "default UI font is Vazirmatn")
	return true


func test_mission_stage_accessor() -> bool:
	var mission: Node = load("res://scripts/systems/mission.gd").new()
	assert_eq(mission.current_stage(), 0, "mission starts at stage 0")
	assert_true(mission.current_text().contains("پازل"), "stage 0 objective is Persian")
	mission.on_puzzle_solved()
	mission.on_puzzle_solved()
	mission.on_puzzle_solved()
	assert_eq(mission.current_stage(), 1, "three puzzles advance to stage 1")
	assert_true(mission.current_text().contains("دکل"), "stage 1 objective is Persian")
	mission.on_tower_activated()
	mission.on_tower_activated()
	mission.on_tower_activated()
	assert_eq(mission.current_stage(), 2, "three towers advance to stage 2")
	assert_true(mission.current_text().contains("سیگنال"), "stage 2 objective is Persian")
	mission.free()
	return true


func test_help_screen_loads() -> bool:
	var scene: PackedScene = load("res://scenes/ui/help_screen.tscn")
	var help: Control = scene.instantiate()
	root.add_child(help)
	await process_frame
	assert_true(help.get_node("Panel/Scroll/Content/TitleLabel").text.contains("راهنما"), "help screen has the title")
	assert_true(help.get_node("Panel/Scroll/Content/GoalLabel").text.contains("پازل"), "help goal explains the puzzles")
	assert_true(help.get_node("Panel/Scroll/Content/ControlsLabel").text.contains("Q"), "help controls name the radar key")
	assert_true(help.get_node("Panel/Scroll/Content/TipsLabel").text.contains("ربات"), "help tips mention the robots")
	help.show_help()
	assert_true(help.visible, "show_help makes the help screen visible")
	help.hide_help()
	assert_true(not help.visible, "hide_help hides the help screen")
	help.queue_free()
	return true


func test_main_menu_help_button() -> bool:
	var scene: PackedScene = load("res://scenes/ui/main_menu.tscn")
	var menu: Control = scene.instantiate()
	root.add_child(menu)
	await process_frame
	var help_button: Button = menu.get_node("HelpButton")
	assert_true(help_button.text.contains("راهنما"), "main menu has a Help button")
	assert_true(help_button.pressed.is_connected(menu._on_help_pressed), "Help button is wired")
	menu._on_help_pressed()
	assert_true(menu.get_node("HelpScreen").visible, "Help button opens the help screen")
	menu.queue_free()
	return true


func test_pause_menu_help_button() -> bool:
	var scene: PackedScene = load("res://scenes/ui/pause_menu.tscn")
	var pause_menu: CanvasLayer = scene.instantiate()
	root.add_child(pause_menu)
	await process_frame
	var help_button: Button = pause_menu.get_node("Panel/HelpButton")
	assert_true(help_button.text.contains("راهنما"), "pause menu has a Help button")
	assert_true(help_button.pressed.is_connected(pause_menu._on_help_pressed), "pause Help button is wired")
	pause_menu._on_help_pressed()
	assert_true(pause_menu.get_node("HelpScreen").visible, "pause Help button opens the help screen")
	pause_menu.queue_free()
	return true


## One robot per area: exactly one enemy inside each of the five area
## rects (positions from level_01.gd AREAS).
func test_one_robot_per_area() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var rects: Array[Rect2] = [
		Rect2(0, 0, 640, 368), Rect2(640, 0, 640, 368), Rect2(0, 368, 640, 368),
		Rect2(640, 368, 640, 368), Rect2(640, 736, 640, 192),
	]
	var enemies: Array = []
	for node in get_nodes_in_group("enemies"):
		if level.is_ancestor_of(node):
			enemies.append(node)
	assert_eq(enemies.size(), 5, "level has five robots in total")
	for rect in rects:
		var count := 0
		for enemy in enemies:
			if rect.has_point(enemy.global_position):
				count += 1
		assert_eq(count, 1, "exactly one robot in area rect %s" % rect)
	assert_true(level.get_node_or_null("LabRobot") != null, "Lab robot exists")
	assert_true(level.get_node_or_null("PowerScanner") != null, "Power scanner exists")
	assert_true(level.get_node_or_null("YardRobot") != null, "Yard robot exists")
	level.queue_free()
	return true


## Each security robot patrols inside its own area; each scanner stays
## at its single post point.
func test_robots_patrol_own_area() -> bool:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	var rects: Array[Rect2] = [
		Rect2(0, 0, 640, 368), Rect2(640, 0, 640, 368), Rect2(0, 368, 640, 368),
		Rect2(640, 368, 640, 368), Rect2(640, 736, 640, 192),
	]
	for node in get_nodes_in_group("enemies"):
		if not level.is_ancestor_of(node):
			continue
		var area := Rect2()
		for rect in rects:
			if rect.has_point(node.global_position):
				area = rect
		assert_true(area != Rect2(), "robot spawns inside an area: " + node.name)
		if node.is_in_group("scanners"):
			assert_eq(node.patrol_points.size(), 1, "scanner has one post point: " + node.name)
			assert_eq(node.patrol_points[0], node.global_position, "scanner post is its spawn: " + node.name)
		else:
			assert_true(node.patrol_points.size() >= 3, "security robot has a patrol loop: " + node.name)
			for point in node.patrol_points:
				assert_true(area.has_point(point), "patrol point inside the robot's own area: " + node.name)
	level.queue_free()
	return true


func test_hud_stage_hint() -> bool:
	var main: Node = _load_main()
	await process_frame
	await process_frame
	var hud: CanvasLayer = main.get_node("HUD")
	var hint: Label = hud.get_node("HintLabel")
	assert_true(hint.visible, "stage hint is visible at start")
	assert_true(hint.text.contains("پازل"), "stage 0 hint guides the player to the puzzles")
	hud.show_area_hint("راهنمای آزمایشی")
	assert_eq(hint.text, "راهنمای آزمایشی", "area hint overrides the stage hint")
	hud._on_hint_timer_timeout()
	assert_true(hint.text.contains("پازل"), "stage hint returns after the area hint times out")
	hud.clear_hint()
	assert_true(not hint.visible, "clear_hint hides the hint line")
	main.queue_free()
	return true


func test_area_entry_shows_hint() -> bool:
	var main: Node = _load_main()
	await process_frame
	await process_frame
	var level: Node2D = main.get_node("Level01")
	var hud: CanvasLayer = main.get_node("HUD")
	var player: CharacterBody2D = level.get_node("Player")
	player.global_position = Vector2(600, 256)
	player.velocity = Vector2.ZERO
	await physics_frame
	Input.action_press("move_right")
	var entered := false
	for i in 120:
		await physics_frame
		if level.current_area == "بخش پزشکی":
			entered = true
			break
	Input.action_release("move_right")
	assert_true(entered, "walking through the doorway enters Medical Wing")
	assert_true(hud.get_node("HintLabel").text.contains("اسکنر"), "entering Medical Wing shows its robot hint")
	main.queue_free()
	return true
