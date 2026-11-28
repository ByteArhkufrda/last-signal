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
const KEYCARD_SCENE := "res://scenes/levels/rooms/laboratory/keycard_pickup_laboratory.tscn"
const PLAY_SCENE := "res://scenes/levels/rooms/laboratory/play_laboratory.tscn"
const MISSION_SCRIPT: Script = preload("res://scripts/levels/rooms/laboratory/mission_laboratory.gd")

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
	for t in ["test_power_panel_sequence", "test_signal_analyzer",
			"test_research_vault", "test_mission_flow",
			"test_standalone_has_hud", "test_log_panel_long_text",
			"test_brain_flash_on_screen", "test_warning_label_fits",
			"test_wrong_move_flashes_light", "test_unlock_changes_light_state",
			"test_show_text_routes_by_width", "test_hud_feedback_fits",
			"test_console_name_labels", "test_analyzer_waveforms",
			"test_keycard_pulses", "test_solved_devices_leave_interactables",
			"test_robot_pauses_while_reading",
			"test_log_panel_closes_when_walking_away",
			"test_chamber_glow_pulses",
			"test_room_geometry_v2", "test_spawn_is_safe",
			"test_robot_routes_clear",
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
	vault.position = Vector2(80, 464)
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
	assert_eq((holder.get_node("KeycardPickup") as Node2D).position, Vector2(40, 464), "vault: keycard spawns beside the vault")
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


## Stage 2 (2026-11-28): the standalone room must ship a HUD — every
## puzzle/console message is routed through it, so without one the
## whole story is silent (B1).
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
	# Spawn shows the area hint once (entering the area never fires at spawn).
	assert_true(hud != null and hud.get_node_or_null("HintLabel").visible, "hud: area hint shown at spawn")
	# The objective is centered at x=320 while the "puzzles solved"
	# label sits top-left and the minimap top-right on the same row —
	# a wide objective prints under one of them (the old text was
	# 520 px wide; its "هدف:" prefix hid behind the minimap).
	var objective: Label = hud.get_node("ObjectiveLabel") as Label
	var font: Font = objective.get_theme_font("font")
	var w: float = font.get_string_size(objective.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	assert_true(w <= 200.0, "hud: objective fits between the puzzles label and the minimap")
	# Every stage's objective text must fit the same slot.
	var mission_probe: Node = MISSION_SCRIPT.new()
	for i in 3:
		var tw: float = font.get_string_size(mission_probe.current_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		assert_true(tw <= 200.0, "hud: stage %d objective fits (%s)" % [mission_probe.current_stage(), mission_probe.current_text()])
		mission_probe.on_puzzle_solved()
	var tw1: float = font.get_string_size(mission_probe.current_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	assert_true(tw1 <= 200.0, "hud: keycard-stage objective fits")
	mission_probe.on_keycard_taken()
	var tw2: float = font.get_string_size(mission_probe.current_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	assert_true(tw2 <= 200.0, "hud: done objective fits")
	play.queue_free()
	await process_frame
	await process_frame
	return true


## Stage 2 (B2): long story texts must go through a wrapped log panel,
## not the HUD's single-line message (no autowrap there, 3 s timer).
func test_log_panel_long_text() -> bool:
	var play: Node2D = load(PLAY_SCENE).instantiate()
	root.add_child(play)
	var wiring: Node = play.wiring
	var long_text: String = "فایل صوتی بازیابی شد — پیام دانشمند:\n«اگر این پیام را دریافت می‌کنید، یعنی آزمایش شکست خورده است. ما اشتباه کردیم. این نمونه فقط به انرژی واکنش نشان نمی‌دهد... انگار می‌تواند حضور ما را احساس کند.»"
	wiring.show_log(long_text)
	assert_true(wiring._log_overlay != null, "log: overlay exists after show_log")
	assert_true(wiring._log_overlay.visible, "log: overlay visible for long text")
	var label: Label = wiring._log_label
	assert_true(label != null, "log: label exists")
	assert_eq(label.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, "log: label wraps words")
	assert_true(label.text.contains("دانشمند"), "log: label carries the log text")
	assert_true(label.custom_minimum_size.x <= 640.0, "log: panel width bounded to the screen")
	wiring._hide_log()
	assert_true(not wiring._log_overlay.visible, "log: overlay hides on close")
	play.queue_free()
	await process_frame
	await process_frame
	return true


## Stage 2 (B2, width routing): the HUD's message slot is only ~200 px
## wide (radar label left, battery bar right), so the router decides
## by rendered width, not by character count — a short-looking
## multiline note still goes to the log panel.
func test_show_text_routes_by_width() -> bool:
	var play: Node2D = load(PLAY_SCENE).instantiate()
	root.add_child(play)
	var wiring: Node = play.wiring
	var hud: CanvasLayer = play.get_node("HUD") as CanvasLayer
	var msg_label: Label = hud.get_node("MessageLabel") as Label
	wiring._show_text("الگوی اشتباه است")
	assert_true(msg_label.visible, "route: short feedback shows on the HUD")
	assert_true(wiring._log_overlay == null or not wiring._log_overlay.visible, "route: short feedback does not open the log panel")
	wiring._show_text("Experiment 01 — First Contact\nاولین تماس با نمونه: واکنش به محرک الکتریکی ضعیف. یک پالس نوری کوتاه ثبت شد.")
	assert_true(wiring._log_overlay.visible, "route: a note opens the log panel")
	assert_true(str(wiring._log_label.text).contains("First Contact"), "route: the note text is in the panel")
	wiring._hide_log()
	# The ship AI's ending warning keeps its exact wording and goes
	# to the panel too — it is ~700 px wide as a HUD message.
	wiring._apply_ending_phase(1)
	assert_true(wiring._log_overlay.visible, "route: the AI warning opens the log panel")
	assert_true(str(wiring._log_label.text).contains("Unauthorized access"), "route: the AI warning text is in the panel")
	play.queue_free()
	await process_frame
	await process_frame
	return true


## Stage 2 (B2, HUD feedback): every wrong-move / locked toast the
## player can trigger must fit the HUD's ~200 px message slot.
func test_hud_feedback_fits() -> bool:
	var play: Node2D = load(PLAY_SCENE).instantiate()
	root.add_child(play)
	var player: CharacterBody2D = play.player
	var hud: CanvasLayer = play.get_node("HUD") as CanvasLayer
	var msg_label: Label = hud.get_node("MessageLabel") as Label
	var font: Font = msg_label.get_theme_font("font")
	# Wrong power flip.
	await _press_e_near(player, Vector2(272, 264))
	assert_true(_hud_text_fits(msg_label, font), "hud-fit: wrong power flip toast fits")
	# Analyzer while the power is off.
	await _press_e_near(player, Vector2(368, 152))
	assert_true(_hud_text_fits(msg_label, font), "hud-fit: locked analyzer toast fits")
	# Solve the power, then a wrong pattern.
	await _press_e_near(player, Vector2(272, 216))
	await _press_e_near(player, Vector2(272, 240))
	await _press_e_near(player, Vector2(272, 264))
	assert_true(_hud_text_fits(msg_label, font), "hud-fit: power solved toast fits")
	await _press_e_near(player, Vector2(368, 152))
	assert_true(_hud_text_fits(msg_label, font), "hud-fit: wrong pattern toast fits")
	# Vault dial while locked.
	await _press_e_near(player, Vector2(376, 464))
	assert_true(_hud_text_fits(msg_label, font), "hud-fit: locked vault toast fits")
	play.queue_free()
	await process_frame
	await process_frame
	return true


func _hud_text_fits(msg_label: Label, font: Font) -> bool:
	if not msg_label.visible:
		return false
	return font.get_string_size(msg_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x <= 200.0


## Stage 3 (Q1): the five consoles must carry a name label, so the
## player can tell them apart without reading each one.
func test_console_name_labels() -> bool:
	var play: Node2D = load(PLAY_SCENE).instantiate()
	root.add_child(play)
	var room: Node2D = play.room
	var expected := {
		"ResearchLogConsole": "گزارش",
		"WaveMonitor": "موج",
		"Note01": "یادداشت ۰۱",
		"Note03": "یادداشت ۰۳",
		"Note07": "یادداشت ۰۷",
	}
	for node_name in expected.keys():
		var console: Node2D = room.get_node_or_null(node_name)
		assert_true(console != null, "labels: %s exists" % node_name)
		var label: Label = null
		if console != null:
			for child in console.get_children():
				if child is Label:
					label = child
					break
		assert_true(label != null, "labels: %s has a name label" % node_name)
		if label != null:
			assert_eq(label.text, str(expected[node_name]), "labels: %s label text" % node_name)
			assert_true(label.position.x > 0.0, "labels: %s label sits beside the console" % node_name)
	play.queue_free()
	await process_frame
	await process_frame
	return true


## Stage 3 (Q2): the analyzer must draw the three wave patterns the
## design doc promises — A steady, B irregular, C three pulses.
func test_analyzer_waveforms() -> bool:
	var analyzer: Node = _add_panel(SIGNAL_ANALYZER_SCENE)
	for wave_name in ["WaveA", "WaveB", "WaveC"]:
		var wave: Line2D = analyzer.get_node_or_null(wave_name) as Line2D
		assert_true(wave != null, "waves: %s exists" % wave_name)
		if wave != null:
			assert_true(wave.points.size() >= 8, "waves: %s has enough points" % wave_name)
	var wave_c: Line2D = analyzer.get_node("WaveC") as Line2D
	var peaks := 0
	for p in wave_c.points:
		if p.y < 20.0:
			peaks += 1
	assert_eq(peaks, 3, "waves: pattern C shows exactly three pulses")
	var wave_a: Line2D = analyzer.get_node("WaveA") as Line2D
	var min_y := INF
	var max_y := -INF
	for p in wave_a.points:
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	assert_true(max_y - min_y <= 8.0, "waves: pattern A is steady")
	var wave_b: Line2D = analyzer.get_node("WaveB") as Line2D
	var biggest_jump := 0.0
	for i in range(1, wave_b.points.size()):
		biggest_jump = maxf(biggest_jump, absf(wave_b.points[i].y - wave_b.points[i - 1].y))
	assert_true(biggest_jump > 4.0, "waves: pattern B is irregular")
	analyzer.queue_free()
	await process_frame
	await process_frame
	return true


## Stage 3 (Q3): the keycard pickup must pulse gently so the player
## notices the small gold card when the vault opens.
func test_keycard_pulses() -> bool:
	var kc: Node2D = load(KEYCARD_SCENE).instantiate()
	root.add_child(kc)
	assert_true(kc.get("_pulse_tween") != null, "keycard: pulse tween exists")
	var t: Tween = kc.get("_pulse_tween")
	assert_true(t != null and t.is_valid(), "keycard: pulse tween is valid")
	assert_true(t.is_running(), "keycard: pulse tween runs")
	kc.queue_free()
	await process_frame
	await process_frame
	return true


## Stage 3 (Q4): solved devices stop prompting — no more
## "E — turn the first digit" on a solved vault.
func test_solved_devices_leave_interactables() -> bool:
	var panel: Node = _add_panel(POWER_PANEL_SCENE)
	var s1: Node = panel.get_node("Switch1")
	var s2: Node = panel.get_node("Switch2")
	var s3: Node = panel.get_node("Switch3")
	assert_true(s1.is_in_group("interactable"), "prompts: switch in group before solving")
	s1.interact()
	s2.interact()
	s3.interact()
	assert_true(panel.is_solved, "prompts: panel solves")
	assert_true(not s1.is_in_group("interactable"), "prompts: switch 1 leaves the group when solved")
	assert_true(not s2.is_in_group("interactable"), "prompts: switch 2 leaves the group when solved")
	assert_true(not s3.is_in_group("interactable"), "prompts: switch 3 leaves the group when solved")
	panel.queue_free()
	await process_frame
	await process_frame
	var analyzer: Node = _add_panel(SIGNAL_ANALYZER_SCENE)
	analyzer.unlock()
	var a: Node = analyzer.get_node("Selector3")
	a.interact()
	assert_true(analyzer.is_solved, "prompts: analyzer solves")
	assert_true(not a.is_in_group("interactable"), "prompts: selector leaves the group when solved")
	analyzer.queue_free()
	await process_frame
	await process_frame
	var vault: Node = load(RESEARCH_VAULT_SCENE).instantiate()
	root.add_child(vault)
	vault.unlock()
	var d1: Node = vault.get_node("Dial1")
	var d2: Node = vault.get_node("Dial2")
	var d3: Node = vault.get_node("Dial3")
	d1.interact()
	for i in 3:
		d2.interact()
	for i in 7:
		d3.interact()
	assert_true(vault.is_solved, "prompts: vault solves")
	assert_true(not d1.is_in_group("interactable"), "prompts: dial 1 leaves the group when solved")
	assert_true(not d2.is_in_group("interactable"), "prompts: dial 2 leaves the group when solved")
	assert_true(not d3.is_in_group("interactable"), "prompts: dial 3 leaves the group when solved")
	vault.queue_free()
	await process_frame
	await process_frame
	return true


## Stage 3 (Q5): the robot freezes while the player reads a log —
## no catch mid-sentence — and resumes when the panel closes.
func test_robot_pauses_while_reading() -> bool:
	var play: Node2D = load(PLAY_SCENE).instantiate()
	root.add_child(play)
	var wiring: Node = play.wiring
	var robot: CharacterBody2D = play.get_tree().get_first_node_in_group("enemies")
	assert_true(robot != null, "pause: robot exists")
	wiring.show_log("متن بلند برای تست مکث ربات موقع خواندن لاگ توسط بازیکن.")
	assert_true(robot.get("reading_paused") == true, "pause: robot paused while the panel is open")
	var p0: Vector2 = robot.global_position
	for i in 60:
		await physics_frame
	assert_true(robot.global_position.distance_to(p0) < 0.5, "pause: robot does not move while the panel is open")
	wiring._hide_log()
	assert_true(robot.get("reading_paused") == false, "pause: robot resumes when the panel closes")
	# 120 frames: the robot may be in its 1 s waypoint wait when the
	# panel closes, so a shorter window could catch it standing still.
	for i in 120:
		await physics_frame
	assert_true(robot.global_position.distance_to(p0) > 5.0, "pause: robot moves again after the panel closes")
	play.queue_free()
	await process_frame
	await process_frame
	return true


## Stage 3 (Q9): the log panel closes when the player walks away
## from the spot where they started reading.
func test_log_panel_closes_when_walking_away() -> bool:
	var play: Node2D = load(PLAY_SCENE).instantiate()
	root.add_child(play)
	var wiring: Node = play.wiring
	var player: CharacterBody2D = play.player
	wiring.show_log("متن بلند برای تست بسته‌شدن پنل با دور شدن بازیکن از محل خواندن.")
	assert_true(wiring._log_overlay.visible, "walkaway: panel open after reading")
	player.global_position = play.player.global_position + Vector2(100, 0)
	for i in 5:
		await process_frame
	assert_true(not wiring._log_overlay.visible, "walkaway: panel closes after walking away")
	play.queue_free()
	await process_frame
	await process_frame
	return true


## Stage 3 (Q10): after the power puzzle, the sample chamber glow
## pulses instead of sitting static.
func test_chamber_glow_pulses() -> bool:
	var play: Node2D = load(PLAY_SCENE).instantiate()
	root.add_child(play)
	var room: Node2D = play.room
	room.set_chamber_active(true)
	assert_true(room.get("_glow_tween") != null, "glow: pulse tween exists")
	var t: Tween = room.get("_glow_tween")
	assert_true(t != null and t.is_valid(), "glow: pulse tween is valid")
	play.queue_free()
	await process_frame
	await process_frame
	return true


## Stage 2 (B3): the ending's brain flash must be on screen — the player
## is at the vault when the ending triggers, so a world-space flash at
## the wave monitor (224,64) never enters the 320x180 camera view.
func test_brain_flash_on_screen() -> bool:
	var play: Node2D = load(PLAY_SCENE).instantiate()
	root.add_child(play)
	var wiring: Node = play.wiring
	wiring._apply_ending_phase(1)
	wiring._apply_ending_phase(3)
	assert_true(wiring._brain_flash != null, "flash: brain flash node exists at phase 3")
	assert_true(wiring._brain_flash is CanvasLayer, "flash: brain flash is screen-space (CanvasLayer)")
	assert_true(wiring._brain_flash.visible, "flash: brain flash visible at phase 3")
	assert_true(wiring.brain_flash_shown, "flash: brain flash flag set")
	# Phase 1 opened the log panel with the AI warning; the flash is
	# the climax and must not play over the panel.
	assert_true(not wiring._log_overlay.visible, "flash: brain flash closes the log panel")
	wiring._apply_ending_phase(4)
	assert_true(not wiring._brain_flash.visible, "flash: brain flash hides at phase 4")
	play.queue_free()
	await process_frame
	await process_frame
	return true


## Stage 2 (B4): the power panel warning must fit its own rect — the old
## 110-char text wrapped to 4 lines and overflowed as a floating wall of
## text, clipped from the spawn view. The rule itself must stay.
func test_warning_label_fits() -> bool:
	var panel: Node = _add_panel(POWER_PANEL_SCENE)
	var label: Label = panel.get_node("WarningLabel") as Label
	assert_true(label.get_line_count() <= 3, "warning: label fits in at most 3 lines")
	var low: String = label.text.to_lower()
	assert_true(low.contains("containment"), "warning: rule still names containment")
	assert_true(low.contains("cooling"), "warning: rule still names cooling")
	assert_true(low.contains("stabilization"), "warning: rule still names stabilization")
	assert_true(panel.get_node_or_null("WarningBacking") != null, "warning: label has a backing panel")
	panel.queue_free()
	await process_frame
	await process_frame
	return true


## Stage 2 (B5): a wrong move must be visible — the panel light was
## already red before solving, so "red alert" read as nothing.
func test_wrong_move_flashes_light() -> bool:
	var panel: Node = _add_panel(POWER_PANEL_SCENE)
	var s3: Node = panel.get_node("Switch3")
	s3.interact()
	assert_eq(panel.light.color, panel.FLASH_COLOR, "power: wrong flip flashes the light")
	panel.queue_free()
	await process_frame
	await process_frame
	var analyzer: Node = _add_panel(SIGNAL_ANALYZER_SCENE)
	analyzer.unlock()
	var a: Node = analyzer.get_node("Selector1")
	a.interact()
	assert_eq(analyzer.light.color, analyzer.FLASH_COLOR, "analyzer: wrong pattern flashes the light")
	analyzer.queue_free()
	await process_frame
	await process_frame
	return true


## Stage 2 (B10): locked vs unlocked devices must look different — the
## analyzer and vault lights stayed red in both states, the dials identical.
func test_unlock_changes_light_state() -> bool:
	var analyzer: Node = _add_panel(SIGNAL_ANALYZER_SCENE)
	assert_eq(analyzer.light.color, Color(0.9, 0.2, 0.2), "unlock: analyzer light red while locked")
	analyzer.unlock()
	assert_eq(analyzer.light.color, analyzer.UNLOCKED_COLOR, "unlock: analyzer light amber when unlocked")
	analyzer.queue_free()
	await process_frame
	await process_frame
	var vault: Node = load(RESEARCH_VAULT_SCENE).instantiate()
	root.add_child(vault)
	var d1: Node = vault.get_node("Dial1")
	var locked_color: Color = (d1.get_node("Box") as Polygon2D).color
	vault.unlock()
	assert_eq(vault.light.color, vault.UNLOCKED_COLOR, "unlock: vault light amber when unlocked")
	assert_true((d1.get_node("Box") as Polygon2D).color != locked_color, "unlock: dial brightens when unlocked")
	vault.queue_free()
	await process_frame
	await process_frame
	return true


## Teleport next to `pos` and press E exactly once. If a robot
## catches the player mid-sequence (respawn at the spawn point) the
## helper re-teleports before pressing — the 2 s catch grace then
## covers the press.
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
	await _press_e_near(player, Vector2(272, 216))
	await _press_e_near(player, Vector2(272, 240))
	await _press_e_near(player, Vector2(272, 264))
	assert_true(panel.is_solved, "live: power panel solves")
	assert_true(room.chamber_active, "live: chamber lights up after power")
	assert_true(analyzer.unlocked, "live: power unlocks the analyzer")
	assert_eq(mission.puzzles_solved, 1, "live: mission counts 1 puzzle")
	# Puzzle 2: wrong pattern first, then C.
	await _press_e_near(player, Vector2(368, 152))
	assert_true(not analyzer.is_solved, "live: pattern A does not solve")
	await _press_e_near(player, Vector2(368, 200))
	assert_true(analyzer.is_solved, "live: pattern C solves")
	assert_true(vault.unlocked, "live: signal unlocks the vault")
	assert_eq(mission.puzzles_solved, 2, "live: mission counts 2 puzzles")
	# The scientist log reaches the player as a readable wrapped panel.
	assert_true(wiring._log_overlay != null and wiring._log_overlay.visible, "live: scientist log panel shows")
	assert_true(str(wiring._log_label.text).contains("دانشمند"), "live: scientist log text shown")
	# Puzzle 3: dials to 1-3-7.
	await _press_e_near(player, Vector2(376, 464))
	for i in 3:
		await _press_e_near(player, Vector2(400, 464))
	for i in 7:
		await _press_e_near(player, Vector2(424, 464))
	assert_true(vault.is_solved, "live: vault solves with 137")
	assert_true(room.get_node_or_null("KeycardPickup") != null, "live: keycard spawns")
	assert_eq(mission.current_stage(), 1, "live: mission reaches keycard stage")
	# Take the keycard: mission completes and the ending starts.
	await _press_e_near(player, Vector2(360, 464))
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


## Stage 4 (2026-11-28, 24x24 rebuild): the room is 768x768 on the
## user's MAP, every device/console/robot sits on its prompt cell,
## and the wall body is 27 merged rects x 3 children.
func test_room_geometry_v2() -> bool:
	var play: Node2D = load(PLAY_SCENE).instantiate()
	root.add_child(play)
	var room: Node2D = play.room
	assert_eq(room.room_rect, Rect2(0, 0, 768, 768), "geo: room is 768x768")
	assert_eq(room.room_tile_rect, Rect2i(0, 0, 48, 48), "geo: tile rect is 48x48")
	assert_eq(room.spawn_point, Vector2(688, 688), "geo: spawn at the corridor bottom")
	assert_eq(room.wall_rects().size(), 27, "geo: 27 merged wall rects")
	var walls: Node = room.get_node_or_null("Walls_laboratory")
	assert_true(walls != null, "geo: wall body exists")
	if walls != null:
		assert_eq(walls.get_child_count(), 81, "geo: 3 children per wall rect")
	var exits: Array = room.exits()
	assert_eq(exits.size(), 2, "geo: two exits")
	assert_eq(exits[0]["rect"], Rect2(640, -16, 32, 16), "geo: north exit above the corridor")
	assert_eq(exits[1]["rect"], Rect2(752, 352, 16, 32), "geo: east exit through the corridor wall")
	var nodes := {
		"PowerPanel": Vector2(240, 240), "SignalAnalyzer": Vector2(400, 176),
		"ResearchVault": Vector2(400, 496), "SampleChamber": Vector2(368, 400),
		"ResearchLogConsole": Vector2(240, 304), "WaveMonitor": Vector2(432, 208),
		"Note01": Vector2(80, 400), "Note03": Vector2(112, 400), "Note07": Vector2(720, 336),
		"LabRobot": Vector2(272, 352), "LabRobot2": Vector2(528, 304),
	}
	for n in nodes.keys():
		var node: Node2D = room.get_node_or_null(n)
		assert_true(node != null, "geo: %s exists" % n)
		if node != null:
			assert_eq(node.position, nodes[n], "geo: %s at the prompt cell" % n)
	var robot: Node = room.get_node("LabRobot")
	assert_eq(robot.get("detection_radius"), 60.0, "geo: robot vision radius is 60")
	play.queue_free()
	await process_frame
	await process_frame
	return true


## Stage 4 (2026-11-28): the spawn must be safe — the old spawn sat
## inside robot 1's sight and the player was caught ~1.5 s in. Ten
## seconds idle at the new spawn: no robot may spot the player
## (state leaves PATROL) or catch them.
func test_spawn_is_safe() -> bool:
	var play: Node2D = load(PLAY_SCENE).instantiate()
	root.add_child(play)
	var player: CharacterBody2D = play.player
	assert_eq(player.global_position, Vector2(688, 688), "spawn: player starts at the corridor bottom")
	var robots: Array = play.get_tree().get_nodes_in_group("enemies")
	assert_eq(robots.size(), 2, "spawn: two patrol robots")
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


## Stage 4 (2026-11-28): both patrol routes must run clear of every
## wall and every device body — a route through a wall or a device
## leaves the robot stuck sliding on it.
func test_robot_routes_clear() -> bool:
	var play: Node2D = load(PLAY_SCENE).instantiate()
	root.add_child(play)
	var room: Node2D = play.room
	var routes: Array = room.patrol_routes_local()
	assert_eq(routes.size(), 2, "routes: two patrol routes")
	var solids: Array[Rect2] = room.blocked_rects()
	solids.append(Rect2(232, 204, 16, 72))  # PowerPanel body
	solids.append(Rect2(392, 140, 16, 72))  # SignalAnalyzer body
	solids.append(Rect2(364, 488, 72, 16))  # ResearchVault body
	solids.append(Rect2(334, 374, 68, 52))  # SampleChamber body
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
