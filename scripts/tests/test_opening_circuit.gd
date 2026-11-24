extends SceneTree
## Last Signal — opening sequence circuit-puzzle tests (headless).
## Pattern: same as scripts/tests/test_runner.gd (SceneTree, _initialize,
## assert helpers, "Results:" line, exit 1 on any failure).
## Run: godot --headless --path . --script res://scripts/tests/test_opening_circuit.gd
## Exit code 0 = all pass, 1 = any failure. No bare assert().

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
	for t in ["test_predefined_layout_is_solvable", "test_scrambled_layout_is_not_solved", "test_one_rotation_can_complete_it", "test_fuse_disconnected_is_not_solved", "test_solved_follows_connectivity_not_rotation_count", "test_source_and_output_do_not_rotate", "test_straight_returns_after_two_rotations", "test_solve_path_runs_through_fuse", "test_manual_action_exists", "test_opening_scene_loads"]:
		var v = await call(t)
		if v == true:
			passed += 1
			print("PASS %s" % t)
		else:
			failed += 1
			push_error("FAIL %s: did not return true (runtime error?)" % t)


func _solved_puzzle() -> CircuitPuzzle:
	var puzzle := CircuitPuzzle.default_puzzle()
	# The four solution-path tiles, rotated into their solved orientations.
	puzzle.rotate(Vector2i(1, 1))
	puzzle.rotate(Vector2i(2, 1))
	puzzle.rotate(Vector2i(3, 1))
	puzzle.rotate(Vector2i(3, 2))
	puzzle.rotate(Vector2i(3, 2))
	return puzzle


func test_predefined_layout_is_solvable() -> bool:
	var puzzle := _solved_puzzle()
	assert_true(puzzle.is_solved(), "predefined layout solves with 5 rotations")
	assert_eq(puzzle.solve_path().size(), 6, "solve path has 6 cells (source + 4 + output)")
	assert_eq(puzzle.solve_path()[0], CircuitPuzzle.SOURCE_CELL, "solve path starts at source")
	assert_eq(puzzle.solve_path()[-1], CircuitPuzzle.OUTPUT_CELL, "solve path ends at output")
	return true


func test_scrambled_layout_is_not_solved() -> bool:
	var puzzle := CircuitPuzzle.default_puzzle()
	assert_true(not puzzle.is_solved(), "scrambled layout is not solved")
	assert_true(puzzle.solve_path().is_empty(), "scrambled layout has no solve path")
	return true


func test_one_rotation_can_complete_it() -> bool:
	var puzzle := CircuitPuzzle.default_puzzle()
	puzzle.rotate(Vector2i(1, 1))
	puzzle.rotate(Vector2i(2, 1))
	puzzle.rotate(Vector2i(3, 1))
	puzzle.rotate(Vector2i(3, 2))
	assert_true(not puzzle.is_solved(), "one rotation short is not solved")
	puzzle.rotate(Vector2i(3, 2))
	assert_true(puzzle.is_solved(), "final rotation completes the circuit")
	return true


func test_fuse_disconnected_is_not_solved() -> bool:
	var puzzle := _solved_puzzle()
	assert_true(puzzle.is_solved(), "solved before breaking the fuse")
	puzzle.rotate(Vector2i(2, 1))
	assert_true(not puzzle.is_solved(), "rotating the fuse away breaks the circuit")
	# A live path that avoids the fuse must NOT count: reconnect the
	# neighbours around the fuse while the fuse itself stays vertical.
	puzzle.rotate(Vector2i(2, 1))
	assert_true(puzzle.is_solved(), "fuse back in place solves again")
	return true


func test_solved_follows_connectivity_not_rotation_count() -> bool:
	var puzzle := _solved_puzzle()
	assert_true(puzzle.is_solved(), "solved first")
	# Rotating filler tiles off the path changes the rotation count but
	# must not change the solved state.
	puzzle.rotate(Vector2i(0, 0))
	puzzle.rotate(Vector2i(0, 0))
	puzzle.rotate(Vector2i(0, 0))
	puzzle.rotate(Vector2i(4, 3))
	assert_true(puzzle.is_solved(), "filler rotations keep the circuit solved")
	# And many rotations with a broken path still do not solve it.
	var broken := CircuitPuzzle.default_puzzle()
	for i in 12:
		broken.rotate(Vector2i(0, 0))
		broken.rotate(Vector2i(4, 3))
		broken.rotate(Vector2i(1, 0))
	assert_true(not broken.is_solved(), "rotations alone never solve a broken circuit")
	return true


func test_source_and_output_do_not_rotate() -> bool:
	var puzzle := CircuitPuzzle.default_puzzle()
	var source_ports: Array[int] = puzzle.ports_at(CircuitPuzzle.SOURCE_CELL)
	var output_ports: Array[int] = puzzle.ports_at(CircuitPuzzle.OUTPUT_CELL)
	puzzle.rotate(CircuitPuzzle.SOURCE_CELL)
	puzzle.rotate(CircuitPuzzle.OUTPUT_CELL)
	assert_eq(puzzle.ports_at(CircuitPuzzle.SOURCE_CELL), source_ports, "source ports never rotate")
	assert_eq(puzzle.ports_at(CircuitPuzzle.OUTPUT_CELL), output_ports, "output ports never rotate")
	assert_eq(puzzle.rotation_at(CircuitPuzzle.SOURCE_CELL), 0, "source rotation stays 0")
	return true


func test_straight_returns_after_two_rotations() -> bool:
	var puzzle := CircuitPuzzle.default_puzzle()
	var before: Array[int] = puzzle.ports_at(Vector2i(1, 1))
	puzzle.rotate(Vector2i(1, 1))
	puzzle.rotate(Vector2i(1, 1))
	assert_eq(puzzle.ports_at(Vector2i(1, 1)), before, "straight tile returns after 2 rotations")
	return true


func test_solve_path_runs_through_fuse() -> bool:
	var puzzle := _solved_puzzle()
	var path: Array[Vector2i] = puzzle.solve_path()
	assert_true(path.has(CircuitPuzzle.FUSE_CELL), "solve path includes the fuse")
	assert_true(path.has(Vector2i(1, 1)), "solve path includes (1,1)")
	assert_true(path.has(Vector2i(3, 1)), "solve path includes (3,1)")
	assert_true(path.has(Vector2i(3, 2)), "solve path includes (3,2)")
	return true


func test_manual_action_exists() -> bool:
	assert_true(InputMap.has_action("manual"), "manual action exists")
	assert_true(InputMap.has_action("interact"), "interact action exists")
	return true


func test_opening_scene_loads() -> bool:
	var scene: PackedScene = load("res://scenes/opening/opening_sequence.tscn")
	assert_true(scene != null, "opening_sequence.tscn loads")
	var opening: Node2D = scene.instantiate()
	assert_true(opening is Node2D, "opening is Node2D")
	root.add_child(opening)
	await process_frame
	await process_frame
	await process_frame
	assert_true(opening.get_node_or_null("Player") != null, "opening has a Player")
	assert_true(opening.get_node_or_null("CanvasModulate") != null, "opening has a CanvasModulate")
	assert_true(opening.get_node_or_null("PowerPanel") != null, "opening has a PowerPanel")
	assert_true(opening.get_node_or_null("HUD/ManualHint") != null, "opening has a manual hint")
	var player: CharacterBody2D = opening.get_node("Player")
	assert_eq(player.motion_mode, CharacterBody2D.MOTION_MODE_GROUNDED, "side player is grounded")
	opening.queue_free()
	return true
