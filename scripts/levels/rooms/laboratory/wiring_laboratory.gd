extends Node
## Last Signal — wiring for laboratory (ORION, 2026-11-27).
##
## Self-contained copy: stage hints, the area hint and the patrol
## fallback are inlined below, and the ring effect is this room's
## own fx_ring copy. The assembled level keeps the original wiring
## file.
##
## ORION flow: three chained puzzles (power → signal → vault) count
## toward the mission; taking the keycard from the opened vault
## completes the mission and runs the room-ending sequence — lights
## out, the ship AI's warning, "You were not supposed to see
## that.", and a monitor flashing a human brain with the sample's
## signal pattern. The truth (consciousness transfer) is never
## stated; only the suspicion that the sample affects the human mind.

const STAGE_HINTS := {
	0: "با E معماها را حل کن: اول برق، بعد فرکانس سیگنال، بعد رمز محفظه",
	1: "Keycard را از محفظه بردار",
	2: "Keycard را داری — به Core Chamber برو",
}
const AREA_HINT := "آزمایشگاه ORION — نمونه‌ی ناشناخته؛ اول گزارش تحقیقاتی را بخوان"
const _DEFAULT_PATROL: Array[Vector2] = [Vector2(200, 120), Vector2(440, 120), Vector2(440, 280), Vector2(200, 280)]

## The scientist's recovered audio log (puzzle 2), shown as text —
## no audio file is needed.
const SCIENTIST_LOG := "فایل صوتی بازیابی شد — پیام دانشمند:\n«اگر این پیام را دریافت می‌کنید، یعنی آزمایش شکست خورده است. ما اشتباه کردیم. این نمونه فقط به انرژی واکنش نشان نمی‌دهد... انگار می‌تواند حضور ما را احساس کند. دیروز یکی از اعضای تیم گفت که صدای خودش را از داخل محفظه شنیده است. اما وقتی بررسی کردیم، هیچ‌کس داخل محفظه نبود.»"
## The classified report inside the vault (puzzle 3).
const CLASSIFIED_REPORT := "CLASSIFIED REPORT — Subject: Unknown Entity\nآخرین آزمایش نشان داد که نمونه قادر است الگوهای عصبی انسان را شناسایی کند. پس از قرار گرفتن یکی از محققان در معرض تابش مستقیم، فعالیت مغزی او به شکل غیرعادی تغییر کرد. محقق مذکور ادعا کرد که دیگر تنها نیست. دستور تعطیلی کامل آزمایشگاه صادر شد."

const FX_RING_SCENE: PackedScene = preload("res://scenes/levels/rooms/laboratory/fx_ring_laboratory.tscn")

var _root: Node2D = null
var _player: CharacterBody2D = null
var _mission: Node = null
var _nav_grid: AStarGrid2D = null
var _blocked: Array[Rect2] = []
var _puzzles_solved: int = 0
## The single room being played standalone (the room's play_<room>.gd passes its
## own root, which carries `.room`); null in the assembled level.
## Standalone, every position the wiring sees is a LOCAL one, so area,
## patrol and minimap all come from this room instead of the station
## layout in LevelData.
var _standalone_room: Node2D = null

## Room-ending state (test hooks): which phase the keycard ending
## has reached (0 = not started), whether the blackout overlay is
## on, and whether the brain flash has ever been shown.
var ending_phase: int = 0
var blackout_active: bool = false
var brain_flash_shown: bool = false
var _blackout: Polygon2D = null
var _brain_flash: CanvasLayer = null

## Readable log panel (Stage 2, B2): the shared HUD's message line
## has no autowrap and hides after 3 s, so the lab's long story
## texts (research log, scientist log, classified report) go here
## instead — wrapped, on screen until read or its timer ends.
var _log_overlay: CanvasLayer = null
var _log_label: Label = null
var _log_hide_id: int = 0
## Where the player stood when the log opened (Stage 3, Q9): walking
## away from the reading spot closes the panel.
var _log_read_position: Vector2 = Vector2.ZERO


## Where a caught player respawns. The full game uses the entrance
## (LevelData.SPAWN); a standalone room passes its own spawn point
## (2026-11-19: the entrance is outside every other room but Central).
var _respawn_point: Vector2 = Vector2(320, 184)


## Wire `root` (the level, or a standalone room's root). The room
## launcher passes its own root; the assembler passes the level.
func setup(root: Node2D, player: CharacterBody2D, mission: Node, nav_grid: AStarGrid2D, blocked: Array[Rect2], respawn_point: Vector2 = Vector2(320, 184)) -> void:
	_root = root
	_player = player
	_mission = mission
	_nav_grid = nav_grid
	_blocked = blocked
	_respawn_point = respawn_point
	_standalone_room = root.get("room") as Node2D
	# Dynamically spawned pickups (the keycard) find the wiring
	# through this group — they do not exist at setup time.
	add_to_group("room_wiring")
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


func puzzles_solved() -> int:
	return _puzzles_solved


func _area_name_at(_pos: Vector2) -> String:
	# Standalone only: the only area is this room's.
	if _standalone_room != null:
		return _standalone_room.area_name
	return "آزمایشگاه تحقیقاتی"


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


## Short texts fit the HUD's single line; long story texts go to the
## wrapped log panel. The HUD's message slot is narrow — centered at
## x=320 between the radar label and the battery bar, so anything
## wider than ~200 px prints under one of them — so the decision is
## by rendered width (font 16), not just by character count: the
## notes' longest line decides, even for a short-looking multiline
## text. The length fallback covers the no-HUD case.
func _show_text(text: String) -> void:
	var hud: CanvasLayer = _get_hud()
	var wide := text.length() > 150
	if hud != null and not wide:
		var msg_label: Label = hud.get_node_or_null("MessageLabel") as Label
		if msg_label != null:
			var font: Font = msg_label.get_theme_font("font")
			wide = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x > 200.0
	if wide:
		show_log(text)
		return
	if hud != null:
		hud.show_message(text)


## Show a long text in the wrapped log panel (built on first use).
func show_log(text: String) -> void:
	if _log_overlay == null:
		_build_log_overlay()
	_log_label.text = text
	_log_overlay.visible = true
	if _player != null:
		_log_read_position = _player.global_position
	# The robot freezes while the player reads (Stage 3, Q5): no
	# catch mid-sentence.
	_set_robot_reading_paused(true)
	_log_hide_id += 1
	var my_id := _log_hide_id
	# Reading time scales with length: ~25 chars/s, 6-15 s.
	var hold := clampf(float(text.length()) / 25.0, 6.0, 15.0)
	var timer := get_tree().create_timer(hold)
	timer.timeout.connect(_on_log_timer.bind(my_id))


func _on_log_timer(id: int) -> void:
	if id == _log_hide_id:
		_hide_log()


func _hide_log() -> void:
	_log_hide_id += 1
	if _log_overlay != null:
		_log_overlay.visible = false
	_set_robot_reading_paused(false)


func _set_robot_reading_paused(value: bool) -> void:
	var enemy: Node = _root.get_tree().get_first_node_in_group("enemies")
	if enemy != null and enemy.has_method("set_reading_paused"):
		enemy.set_reading_paused(value)


func _process(_delta: float) -> void:
	# Walking away from the reading spot closes the panel (Stage 3,
	# Q9) — on top of Esc and the auto-hide timer.
	if _log_overlay != null and _log_overlay.visible and _player != null:
		if _player.global_position.distance_to(_log_read_position) > 48.0:
			_hide_log()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _log_overlay != null and _log_overlay.visible:
		_hide_log()


## The log panel: a centered dark panel with a word-wrapped label.
## Code-built (no new scene): it lives in this room's wiring only.
func _build_log_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "LogOverlay"
	layer.layer = 4
	layer.visible = false
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	# Grow both ways from the center anchor: the panel's size comes
	# from its content, and without this its top-left sits on the
	# center point and the panel runs off the right/bottom edges.
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.09, 0.94)
	style.set_corner_radius_all(6)
	style.border_color = Color(0.35, 0.5, 0.7)
	style.set_border_width_all(1)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", style)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	_log_label = Label.new()
	_log_label.custom_minimum_size = Vector2(560, 0)
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_log_label)
	var hint := Label.new()
	hint.text = "Esc — بستن"
	hint.add_theme_font_size_override("font_size", 12)
	hint.modulate = Color(0.7, 0.75, 0.8)
	vbox.add_child(hint)
	layer.add_child(panel)
	_root.add_child(layer)
	_log_overlay = layer


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
	elif stage >= 2:
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
			# One robot per area: patrol this room's own loop
			# (local coordinates); Central's loop is only the fallback.
			var local_points: Array[Vector2] = _standalone_room.patrol_points_local()
			enemy.patrol_points = local_points if not local_points.is_empty() else _DEFAULT_PATROL
		_player.pulse_emitted.connect(enemy.investigate)
		enemy.player_caught.connect(_on_player_caught)
	for puzzle in _root.get_tree().get_nodes_in_group("puzzles"):
		if not _root.is_ancestor_of(puzzle):
			continue
		if puzzle.has_signal("solved"):
			puzzle.solved.connect(_on_puzzle_solved.bind(puzzle))


## A dynamically spawned pickup (the keycard) does not exist at
## setup time, so the vault wires it here on spawn.
func wire_keycard_pickup(pickup: Node2D) -> void:
	if pickup.has_signal("collected"):
		pickup.collected.connect(_on_item_collected)


func _on_puzzle_solved(puzzle: Node) -> void:
	_puzzles_solved += 1
	_mission.on_puzzle_solved()
	# Mirror the count onto the level (test hook: level._puzzles_solved).
	_root.set("_puzzles_solved", _puzzles_solved)
	_play_sound("chime")
	var hud: CanvasLayer = _get_hud()
	if hud != null:
		hud.set_puzzles_solved(_puzzles_solved, 3)
		hud.set_objective(_mission.current_text())
	match puzzle.name:
		"PowerPanel":
			_show_text("SIGNAL DETECTED")
		"SignalAnalyzer":
			_show_text(SCIENTIST_LOG)
		"ResearchVault":
			_show_text(CLASSIFIED_REPORT)
		_:
			_show_text(str(puzzle.get("solved_message")))
	_update_stage_hint()
	# Power restored: the sample chamber lights up.
	if puzzle.name == "PowerPanel" and _standalone_room != null and _standalone_room.has_method("set_chamber_active"):
		_standalone_room.set_chamber_active(true)


func _on_interacted(node: Node) -> void:
	if node.get("message") != null:
		_show_text(str(node.get("message")))


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
	if pickup.item_id == "keycard":
		_on_keycard_taken()
		return
	var hud: CanvasLayer = _get_hud()
	if hud != null:
		if pickup.battery_restore > 0.0:
			hud.show_message("%s برداشته شد (+%d باتری)." % [pickup.display_name, int(pickup.battery_restore)])
		else:
			hud.show_message("%s برداشته شد." % pickup.display_name)


## Taking the keycard completes the mission and starts the ending.
func _on_keycard_taken() -> void:
	_mission.on_keycard_taken()
	_play_sound("fanfare")
	var hud: CanvasLayer = _get_hud()
	if hud != null:
		hud.flash(Color(0.3, 1.0, 0.4))
		hud.set_objective(_mission.current_text())
		hud.clear_hint()
	_start_keycard_ending()


## Room ending, four phases (timers in play; tests call
## _apply_ending_phase directly): 1 blackout + AI warning, 2 the
## AI's second line, 3 the brain flash, 4 lights back + final hint.
func _start_keycard_ending() -> void:
	if ending_phase > 0:
		return
	_apply_ending_phase(1)
	_schedule_ending_phase(2, 3.0)
	_schedule_ending_phase(3, 6.0)
	_schedule_ending_phase(4, 8.0)


func _schedule_ending_phase(phase: int, delay: float) -> void:
	var timer := get_tree().create_timer(delay)
	timer.timeout.connect(_apply_ending_phase.bind(phase))


func _apply_ending_phase(phase: int) -> void:
	if phase <= ending_phase:
		return
	ending_phase = phase
	var hud: CanvasLayer = _get_hud()
	match phase:
		1:
			_set_blackout(true)
			# The ship AI's warning is a story beat, not a toast: it
			# is far too wide for the HUD's message slot, so it goes
			# to the log panel verbatim.
			_show_text("WARNING. Unauthorized access to classified research data. Please return the access card.")
		2:
			_show_text("You were not supposed to see that.")
		3:
			_show_brain_flash(true)
		4:
			_show_brain_flash(false)
			_set_blackout(false)
			if hud != null:
				hud.show_message("راه Core Chamber باز است.")
				hud.set_objective(_mission.current_text())


## Full-room blackout overlay (a dark polygon over the room).
func _set_blackout(active: bool) -> void:
	blackout_active = active
	if _standalone_room == null:
		return
	if active and _blackout == null:
		_blackout = Polygon2D.new()
		var r: Rect2 = _standalone_room.room_rect
		_blackout.polygon = PackedVector2Array([
			r.position, r.position + Vector2(r.size.x, 0),
			r.position + r.size, r.position + Vector2(0, r.size.y)])
		_blackout.color = Color(0, 0, 0, 0.85)
		_blackout.z_index = 100
		_standalone_room.add_child(_blackout)
	elif not active and _blackout != null:
		_blackout.queue_free()
		_blackout = null


## The brain flash: a monitor showing a human brain whose activity
## pattern matches the sample's signal, then off again. Screen-space
## (CanvasLayer, Stage 2 B3): the old world-space flash sat on the
## wave monitor at (224,64), but the player is at the vault when the
## ending triggers — ~370 px away, outside the 320x180 camera view —
## so the room's climax never reached the player. Same drawing, now
## centered on screen.
func _show_brain_flash(show: bool) -> void:
	if show:
		brain_flash_shown = true
		# The flash is the climax: the log panel (the AI's warning)
		# must not stay open over it.
		_hide_log()
	if _brain_flash == null:
		_brain_flash = _build_brain_flash()
		_root.add_child(_brain_flash)
	_brain_flash.visible = show


func _build_brain_flash() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = "BrainFlash"
	layer.layer = 5
	layer.visible = false
	var flash := Node2D.new()
	flash.position = Vector2(320, 180)
	var screen := Polygon2D.new()
	screen.polygon = PackedVector2Array([
		Vector2(-56, -24), Vector2(56, -24),
		Vector2(56, 24), Vector2(-56, 24)])
	screen.color = Color(0.05, 0.08, 0.12)
	flash.add_child(screen)
	# Two overlapping lobes, roughly a brain in profile.
	for offset in [Vector2(-14, 0), Vector2(14, 0)]:
		var lobe := Polygon2D.new()
		var points := PackedVector2Array()
		for i in 12:
			var a := TAU * float(i) / 12.0
			points.append(offset + Vector2(cos(a) * 20.0, sin(a) * 14.0))
		lobe.polygon = points
		lobe.color = Color(0.95, 0.45, 0.55)
		flash.add_child(lobe)
	# The sample's three-pulse pattern, drawn over the brain.
	for i in 3:
		var pulse := Polygon2D.new()
		var x := -24.0 + float(i) * 24.0
		pulse.polygon = PackedVector2Array([
			Vector2(x, -6), Vector2(x + 8, -6),
			Vector2(x + 8, 6), Vector2(x, 6)])
		pulse.color = Color(0.2, 0.85, 1.0)
		flash.add_child(pulse)
	var label := Label.new()
	label.position = Vector2(-56, 28)
	label.add_theme_font_size_override("font_size", 10)
	label.text = "NEURAL PATTERN MATCH: 99.7%"
	flash.add_child(label)
	layer.add_child(flash)
	return layer


func _on_player_caught() -> void:
	_player.global_position = _respawn_point
	_player.velocity = Vector2.ZERO
	_play_sound("sting")
	var hud: CanvasLayer = _get_hud()
	if hud != null:
		hud.flash(Color(1.0, 0.2, 0.2))
		hud.show_message("ربات تو را گرفت!")
