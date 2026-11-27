extends Node2D
## Last Signal — Level 01, the "Orion" ship map (traced redesign 2026-11-25).
##
## The map is the reference floor plan itself, 1:1 (1280 x 720 px):
## - Look: assets/sprites/environment/ship_map.png, a smooth flat-colour
##   render (light walls, one dark floor colour, no pixel-art tiles) of the
##   same polygons the physics uses. It is drawn at 3x resolution and
##   scaled down, so edges stay clean at any zoom.
## - Collision: scripts/levels/ship_map_data.gd holds the walkable
##   outline(s) traced from the image. Each outline becomes a
##   CollisionPolygon2D in SEGMENTS mode on one StaticBody2D (layer 1), so
##   the walls block the player and also rays (radar / line of sight).
## - Doors: eight automatic doors (scenes/interaction/door.tscn) sit in
##   the wall gaps; a sensor opens them for the player.
## The level contains no furniture, items, puzzles or robots: only the
## player, the walls and the automatic doors.

const MapData := preload("res://scripts/levels/ship_map_data.gd")
const DOOR_SCENE: PackedScene = preload("res://scenes/interaction/door.tscn")
const FX_RING_SCENE: PackedScene = preload("res://scenes/effects/fx_ring.tscn")
const SHIP_TEXTURE: Texture2D = preload("res://assets/sprites/environment/ship_map.png")
const SHIP_TEXTURE_SCALE := 3.0  # texture pixels per image pixel
## The map keeps the traced shape but is MAP_SCALE times larger.
const MAP_SCALE := 3.0
const WORLD_SIZE := Vector2(1280, 720) * MAP_SCALE

const HUB_NAME := "راهروی مرکزی"
const SPAWN := Vector2(520, 350) * MAP_SCALE
const PUZZLE_TOTAL := 3
const STAGE_HINTS := {}
const AREA_HINTS := {}

## Named areas (bounding rects of the rooms, in image pixels). Anything else
## is the central corridor. Tints are unused (transparent).
const AREAS := [
	{"name": "راهروی مرکزی", "rect": Rect2(280, 240, 700, 200), "tint": Color(0, 0, 0, 0)},
	{"name": "آزمایشگاه تحقیقاتی", "rect": Rect2(360, 130, 256, 138), "tint": Color(0, 0, 0, 0)},
	{"name": "کنترل مرکزی", "rect": Rect2(710, 158, 240, 168), "tint": Color(0, 0, 0, 0)},
	{"name": "بخش پزشکی", "rect": Rect2(342, 412, 264, 182), "tint": Color(0, 0, 0, 0)},
	{"name": "نیروگاه", "rect": Rect2(702, 438, 254, 142), "tint": Color(0, 0, 0, 0)},
	{"name": "کابین خلبان", "rect": Rect2(80, 258, 192, 190), "tint": Color(0, 0, 0, 0)},
	{"name": "محوطه‌ی مخابرات", "rect": Rect2(1030, 232, 160, 240), "tint": Color(0, 0, 0, 0)},
]

## Automatic doors, in image pixels (times MAP_SCALE at build): pos = centre,
## rot = 0 for a door in
## a horizontal wall, 90 for a door in a vertical wall.
const DOORS := [
	{"pos": Vector2(704, 248), "rot": 90.0},   # corridor <-> Command Centre
	{"pos": Vector2(417, 263), "rot": 0.0},    # corridor <-> Research Lab (west)
	{"pos": Vector2(521, 290), "rot": 0.0},    # corridor <-> Research Lab
	{"pos": Vector2(835, 322), "rot": 0.0},    # corridor <-> Command Centre
	{"pos": Vector2(279, 345), "rot": 90.0},   # corridor <-> Pilot Cabin
	{"pos": Vector2(418, 408), "rot": 0.0},    # corridor <-> Medical Wing
	{"pos": Vector2(825, 439), "rot": 0.0},    # corridor <-> Engineering Room
	{"pos": Vector2(604, 490), "rot": 90.0},   # corridor <-> Medical Wing (east)
]

var _puzzles_solved: int = 0
## Area the player is currently in (test hook + HUD naming).
var current_area: String = HUB_NAME

@onready var player: CharacterBody2D = $Player
@onready var mission: Node = $Mission


func _ready() -> void:
	_build_ship_visual()
	_build_walls()
	_build_doors()
	_apply_camera_limits()
	_wire_interactables()
	current_area = _area_name_at(player.global_position)
	player.pulse_emitted.connect(_on_pulse_for_minimap)
	# Deferred: the HUD's @onready vars are not assigned yet when this
	# level readies (siblings ready in tree order).
	call_deferred("_update_objective_hud")
	call_deferred("_setup_minimap")


## The HUD is a sibling of this level under Main. Resolve it by the
## sibling path first: get_first_node_in_group("hud") can return a
## stale HUD from a just-freed scene (queue_free deletes at end of
## frame, but a deferred call can run while it still lingers in the
## group — measured 2026-11-12: the minimap stayed empty in the test
## suite because setup landed on the previous test's HUD). Falls back
## to the group lookup for level-only tests, where there is no Main.
func _get_hud() -> CanvasLayer:
	var parent: Node = get_parent()
	if parent != null:
		var sibling: Node = parent.get_node_or_null("HUD")
		if sibling is CanvasLayer:
			return sibling
	return get_tree().get_first_node_in_group("hud")


func _update_objective_hud() -> void:
	var hud: CanvasLayer = _get_hud()
	if hud != null:
		hud.set_objective(mission.current_text())


## Show the hint for the mission's current stage (the standing guide:
## which key to press next). Null-safe in level-only tests (no HUD).
func _update_stage_hint() -> void:
	# No mission in this version: the standing hint stays hidden.
	pass


## Feed the minimap the ship outline. Null-safe in level-only tests
## (no HUD there).
func _setup_minimap() -> void:
	var hud: CanvasLayer = _get_hud()
	if hud == null:
		return
	var no_walls: Array[Rect2] = []
	hud.setup_minimap(AREAS, no_walls, player, [], [], [])
	hud.set_minimap_outline(MapData.polygons(false), MapData.polygons(true))
	hud.set_minimap_area(current_area)


func _on_pulse_for_minimap(origin: Vector2, radius: float) -> void:
	var hud: CanvasLayer = _get_hud()
	if hud != null:
		hud.mark_minimap_enemies(origin, radius)


## The flat-colour ship render, drawn behind everything (3x texture
## scaled down, linear filtering: smooth edges, no pixel pattern).
func _build_ship_visual() -> void:
	var sprite := Sprite2D.new()
	sprite.name = "ShipMap"
	sprite.texture = SHIP_TEXTURE
	sprite.centered = false
	sprite.scale = Vector2.ONE * MAP_SCALE / SHIP_TEXTURE_SCALE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.z_index = -10
	add_child(sprite)


## Walls = the traced floor outlines (the walkable outline and the
## solid islands inside it) as segment shapes on one static body.
func _build_walls() -> void:
	var body := StaticBody2D.new()
	body.name = "ShipWalls"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	for holes in [false, true]:
		for poly in MapData.polygons(holes):
			var shape := CollisionPolygon2D.new()
			shape.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
			shape.polygon = poly
			body.add_child(shape)


func _build_doors() -> void:
	var index := 1
	for door_data in DOORS:
		var door: StaticBody2D = DOOR_SCENE.instantiate()
		door.name = "AutoDoor%d" % index
		door.position = (door_data["pos"] as Vector2) * MAP_SCALE
		door.scale = Vector2.ONE * MAP_SCALE
		door.rotation_degrees = float(door_data["rot"])
		add_child(door)
		index += 1


func _area_name_at(pos: Vector2) -> String:
	for area in AREAS:
		var scaled := Rect2((area["rect"] as Rect2).position * MAP_SCALE, (area["rect"] as Rect2).size * MAP_SCALE)
		if area["name"] != HUB_NAME and scaled.has_point(pos):
			return str(area["name"])
	return HUB_NAME


func _physics_process(_delta: float) -> void:
	# Corridor/room naming without extra zones: re-check the player's area
	# and announce changes.
	var area := _area_name_at(player.global_position)
	if area != current_area:
		current_area = area
		var hud: CanvasLayer = _get_hud()
		if hud != null:
			hud.show_message(area)
			hud.set_minimap_area(area)


func _apply_camera_limits() -> void:
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(WORLD_SIZE.x)
	camera.limit_bottom = int(WORLD_SIZE.y)


func _wire_interactables() -> void:
	# Scope to this level's own subtree: a freed level's nodes linger in
	# the tree for a frame, and a revealed hidden object is in BOTH groups
	# ("hidden" + "interactable") — wiring tree-wide double-connects it.
	for node in get_tree().get_nodes_in_group("interactable"):
		if not is_ancestor_of(node):
			continue
		if node.has_signal("interacted"):
			node.interacted.connect(_on_interacted)
		if node.has_signal("collected"):
			node.collected.connect(_on_item_collected)
	for node in get_tree().get_nodes_in_group("hidden"):
		if not is_ancestor_of(node):
			continue
		if node.has_signal("revealed"):
			node.revealed.connect(_on_interacted)
		if node.has_signal("collected"):
			node.collected.connect(_on_item_collected)
	for puzzle in get_tree().get_nodes_in_group("puzzles"):
		if not is_ancestor_of(puzzle):
			continue
		if puzzle.has_signal("solved"):
			puzzle.solved.connect(_on_puzzle_solved.bind(puzzle))
	for tower in get_tree().get_nodes_in_group("towers"):
		if not is_ancestor_of(tower):
			continue
		if tower.has_signal("activated"):
			tower.activated.connect(_on_tower_activated)


func _on_puzzle_solved(puzzle: Node) -> void:
	_puzzles_solved += 1
	mission.on_puzzle_solved()
	var tower_name: String = str(puzzle.get("powers_tower"))
	var tower: StaticBody2D = get_node_or_null(tower_name)
	if tower != null:
		tower.power_restored = true
	_play_sound("chime")
	var hud: CanvasLayer = _get_hud()
	if hud != null:
		hud.set_puzzles_solved(_puzzles_solved, PUZZLE_TOTAL)
		hud.set_objective(mission.current_text())
		var display: String = tower.tower_name if tower != null else tower_name
		hud.show_message("پازل حل شد! برق %s وصل شد." % display)
	_update_stage_hint()


func _on_tower_activated(tower: Node) -> void:
	mission.on_tower_activated()
	_play_sound("tower")
	_spawn_ring(tower.global_position, Color(0.3, 0.9, 1.0), 48.0)
	var hud: CanvasLayer = _get_hud()
	if hud != null:
		hud.set_objective(mission.current_text())
		hud.show_message("%s روشن شد! (%d/3 دکل)" % [tower.tower_name, mission.towers_active])
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
	if mission.try_transmit():
		_play_sound("fanfare")
		var console: Node2D = get_node_or_null("TransmitConsole")
		if console != null:
			_spawn_ring(console.global_position, Color(0.3, 1.0, 0.4), 64.0)
		if hud != null:
			hud.flash(Color(0.3, 1.0, 0.4))
			hud.set_objective(mission.current_text())
			hud.clear_hint()
			hud.show_message("مأموریت کامل شد — سیگنال اضطراری فرستاده شد!")
		# Phase 10: the win screen pauses the game and offers Play Again
		# / Main Menu. Null-safe in level-only tests (no win screen there).
		var win: CanvasLayer = get_tree().get_first_node_in_group("win")
		if win != null:
			win.show_win()
	elif hud != null:
		hud.show_message("فرستنده خاموش است — اول هر 3 دکل را روشن کن.")


# Phase 9 helpers: sound + one-shot ring effect. Both are null-safe in
# level-only tests, where there is no AudioManager.
func _play_sound(sound_name: String) -> void:
	var audio: Node = get_tree().get_first_node_in_group("audio")
	if audio != null:
		audio.play(sound_name)


func _spawn_ring(pos: Vector2, color: Color, radius: float) -> void:
	var ring: Node2D = FX_RING_SCENE.instantiate()
	ring.position = pos
	ring.ring_color = color
	ring.max_radius = radius
	add_child(ring)


func _on_item_collected(pickup: Node) -> void:
	player.add_item(pickup.item_id, pickup.amount, pickup.battery_restore)
	_play_sound("blip")
	_spawn_ring(pickup.global_position, Color(1.0, 0.85, 0.3), 24.0)
	var hud: CanvasLayer = _get_hud()
	if hud != null:
		if pickup.battery_restore > 0.0:
			hud.show_message("%s برداشته شد (+%d باتری)." % [pickup.display_name, int(pickup.battery_restore)])
		else:
			hud.show_message("%s برداشته شد." % pickup.display_name)


func _on_player_caught() -> void:
	player.global_position = SPAWN
	player.velocity = Vector2.ZERO
	_play_sound("sting")
	var hud: CanvasLayer = _get_hud()
	if hud != null:
		hud.flash(Color(1.0, 0.2, 0.2))
		hud.show_message("ربات امنیتی تو را گرفت! به ورودی برگشتی.")
