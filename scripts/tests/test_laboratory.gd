extends SceneTree
## Last Signal — ORION laboratory tests (2026-11-27).
##
## Run: godot --headless --path . --script res://scripts/tests/test_laboratory.gd
## Exit code 0 = all pass, 1 = any failure. No bare assert() (it hangs
## the run). Unit tests drive the three puzzle scenes directly;
## test_full_chain_live drives the standalone room with real input
## (teleport + E), like test_rooms.gd test_standalone_room_fixes.

const POWER_PANEL_SCENE := "res://scenes/levels/rooms/laboratory/power_panel_laboratory.tscn"
const SIGNAL_ANALYZER_SCENE := "res://scenes/levels/rooms/laboratory/signal_analyzer_laboratory.tscn"
const RESEARCH_VAULT_SCENE := "res://scenes/levels/rooms/laboratory/research_vault_laboratory.tscn"
const PLAY_SCENE := "res://scenes/levels/rooms/laboratory/play_laboratory.tscn"
const MISSION_SCRIPT: Script = preload("res://scripts/levels/rooms/laboratory/mission_laboratory.gd")

var passed := 0
var failed := 0


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
	for t in ["test_power_panel_sequence", "test_signal_analyzer",
			"test_research_vault", "test_mission_flow",
			"test_full_chain_live"]:
		paused = false
		var v = await call(t)
		if v == true:
			passed += 1
			print("PASS %s" % t)
		else:
			failed += 1
			push_error("FAIL %s: did not return true (runtime error?)" % t)


func _add_panel(path: String) -> Node:
	var panel: Node = load(path).instantiate()
	root.add_child(panel)
	return panel


func test_power_panel_sequence() -> bool:
	var panel: Node = _add_panel(POWER_PANEL_SCENE)
	var s1: Node = panel.get_node("Switch1")
	var s2: Node = panel.get_node("Switch2")
	var s3: Node = panel.get_node("Switch3")
	# Wrong order first: containment before cooling resets everything.
	s3.interact()
	assert_true(not panel.is_solved, "power: containment first does not solve")
	assert_true(not s3.is_on, "power: wrong flip resets the switch")
	# Wrong middle step resets too.
	s1.interact()
	s3.interact()
	assert_true(not panel.is_solved, "power: 1 then 3 does not solve")
	assert_true(not s1.is_on, "power: wrong sequence resets switch 1")
	# Correct order: cooling → stabilizer → containment.
	s1.interact()
	s2.interact()
	s3.interact()
	assert_true(panel.is_solved, "power: 1-2-3 solves")
	assert_true(s1.is_on and s2.is_on and s3.is_on, "power: all switches on after solve")
	# Solved panel ignores further flips.
	s1.interact()
	assert_true(panel.is_solved, "power: solved panel stays solved")
	panel.queue_free()
	await process_frame
	await process_frame
	return true


func test_signal_analyzer() -> bool:
	var analyzer: Node = _add_panel(SIGNAL_ANALYZER_SCENE)
	var a: Node = analyzer.get_node("Selector1")
	var b: Node = analyzer.get_node("Selector2")
	var c: Node = analyzer.get_node("Selector3")
	# Locked: the analyzer is dark until the power puzzle solves.
	c.interact()
	assert_true(not analyzer.is_solved, "analyzer: locked C does not solve")
	analyzer.unlock()
	# Wrong patterns do not solve.
	a.interact()
	assert_true(not analyzer.is_solved, "analyzer: pattern A does not solve")
	b.interact()
	assert_true(not analyzer.is_solved, "analyzer: pattern B does not solve")
	# Pattern C (three consecutive pulses) solves.
	c.interact()
	assert_true(analyzer.is_solved, "analyzer: pattern C solves")
	assert_true(c.is_selected, "analyzer: C stays selected after solve")
	analyzer.queue_free()
	await process_frame
	await process_frame
	return true


func test_research_vault() -> bool:
	var holder := Node2D.new()
	root.add_child(holder)
	var vault: Node = load(RESEARCH_VAULT_SCENE).instantiate()
	vault.position = Vector2(552, 312)
	holder.add_child(vault)
	var d1: Node = vault.get_node("Dial1")
	var d2: Node = vault.get_node("Dial2")
	var d3: Node = vault.get_node("Dial3")
	# Locked: dials do not turn before the signal puzzle solves.
	d1.interact()
	assert_eq(d1.digit, 0, "vault: locked dial does not turn")
	vault.unlock()
	# Wrong code does not open the vault. Enter 138 dial-first so
	# the sweep never passes through 137 on the way.
	for i in 8:
		d3.interact()
	for i in 1:
		d1.interact()
	for i in 3:
		d2.interact()
	assert_true(not vault.is_solved, "vault: code 138 does not solve")
	# Correct code 137: dial 3 wraps 8 → 9 → 0 → … → 7.
	for i in 9:
		d3.interact()
	assert_true(vault.is_solved, "vault: code 137 solves")
	assert_true(vault.keycard_spawned, "vault: keycard spawns on solve")
	assert_true(holder.get_node_or_null("KeycardPickup") != null, "vault: keycard node exists")
	assert_eq((holder.get_node("KeycardPickup") as Node2D).position, Vector2(512, 312), "vault: keycard spawns beside the vault")
	holder.queue_free()
	await process_frame
	await process_frame
	return true


func test_mission_flow() -> bool:
	var mission: Node = MISSION_SCRIPT.new()
	assert_eq(mission.current_stage(), 0, "mission: starts at puzzle stage")
	assert_true(not mission.is_complete, "mission: not complete at start")
	# Keycard before the puzzles does nothing.
	mission.on_keycard_taken()
	assert_true(not mission.is_complete, "mission: keycard early does not complete")
	mission.on_puzzle_solved()
	mission.on_puzzle_solved()
	assert_eq(mission.current_stage(), 0, "mission: still puzzles at 2/3")
	mission.on_puzzle_solved()
	assert_eq(mission.current_stage(), 1, "mission: keycard stage at 3/3")
	mission.on_keycard_taken()
	assert_true(mission.is_complete, "mission: keycard completes it")
	assert_eq(mission.current_stage(), 2, "mission: done stage after keycard")
	return true


## Teleport next to `pos` and press E exactly once. The lab robot
## patrols near the vault, so if it catches the player mid-sequence
## (respawn at the spawn point) the helper re-teleports before
## pressing — the 2 s catch grace then covers the press.
func _press_e_near(player: CharacterBody2D, pos: Vector2) -> void:
	player.global_position = pos
	for i in 5:
		await physics_frame
	if player.global_position.distance_to(pos) > 5.0:
		# Caught and respawned: the 2 s catch grace covers the retry.
		player.global_position = pos
		for i in 2:
			await physics_frame
	Input.action_press("interact")
	for i in 3:
		await physics_frame
	Input.action_release("interact")


func test_full_chain_live() -> bool:
	var play: Node2D = load(PLAY_SCENE).instantiate()
	root.add_child(play)
	var player: CharacterBody2D = play.player
	var room: Node2D = play.room
	var mission: Node = play.mission
	var wiring: Node = play.wiring
	var panel: Node = room.get_node("PowerPanel")
	var analyzer: Node = room.get_node("SignalAnalyzer")
	var vault: Node = room.get_node("ResearchVault")
	assert_true(panel != null and analyzer != null and vault != null, "live: all three puzzles exist")
	assert_true(not analyzer.unlocked, "live: analyzer locked at start")
	assert_true(not vault.unlocked, "live: vault locked at start")
	# Puzzle 1: power, cooling → stabilizer → containment.
	await _press_e_near(player, Vector2(204, 152))
	await _press_e_near(player, Vector2(204, 176))
	await _press_e_near(player, Vector2(204, 200))
	assert_true(panel.is_solved, "live: power panel solves")
	assert_true(room.chamber_active, "live: chamber lights up after power")
	assert_true(analyzer.unlocked, "live: power unlocks the analyzer")
	assert_eq(mission.puzzles_solved, 1, "live: mission counts 1 puzzle")
	# Puzzle 2: wrong pattern first, then C.
	await _press_e_near(player, Vector2(516, 72))
	assert_true(not analyzer.is_solved, "live: pattern A does not solve")
	await _press_e_near(player, Vector2(516, 120))
	assert_true(analyzer.is_solved, "live: pattern C solves")
	assert_true(vault.unlocked, "live: signal unlocks the vault")
	assert_eq(mission.puzzles_solved, 2, "live: mission counts 2 puzzles")
	# Puzzle 3: dials to 1-3-7.
	await _press_e_near(player, Vector2(528, 340))
	for i in 3:
		await _press_e_near(player, Vector2(552, 340))
	for i in 7:
		await _press_e_near(player, Vector2(576, 340))
	assert_true(vault.is_solved, "live: vault solves with 137")
	assert_true(room.get_node_or_null("KeycardPickup") != null, "live: keycard spawns")
	assert_eq(mission.current_stage(), 1, "live: mission reaches keycard stage")
	# Take the keycard: mission completes and the ending starts.
	await _press_e_near(player, Vector2(512, 340))
	assert_true(int(player.inventory.get("keycard", 0)) >= 1, "live: keycard in inventory")
	assert_true(mission.is_complete, "live: mission completes on keycard")
	assert_true(wiring.ending_phase >= 1, "live: ending starts")
	assert_true(wiring.blackout_active, "live: blackout on after keycard")
	# Ending phases advance deterministically (timers in play).
	wiring._apply_ending_phase(2)
	wiring._apply_ending_phase(3)
	assert_true(wiring.brain_flash_shown, "live: brain flash shows")
	wiring._apply_ending_phase(4)
	assert_eq(wiring.ending_phase, 4, "live: ending reaches phase 4")
	assert_true(not wiring.blackout_active, "live: blackout lifts at the end")
	play.queue_free()
	await process_frame
	await process_frame
	return true
