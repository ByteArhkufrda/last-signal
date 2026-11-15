extends Node2D
## Last Signal — Level 01, station K-17 (Phase 1 + Phase 3, areas + nav 2026-11-12).
##
## Room: 80 x 58 tiles of 16px = 1280 x 928 world pixels, five areas:
## Central Control (the original 40x23 hall, top-left, unchanged),
## Medical Wing (top-right), Research Laboratory (bottom-left),
## Power Station (bottom-right) and Communication Yard (south annex).
## Areas are connected by 32 px doorways in the divider walls; each area
## has its own floor tint, props, a console with an area log, and an
## entry zone that names the area on the HUD.
## Floor: TileMapLayer filled from a runtime-built TileSet (two-tile atlas
## res://assets/sprites/environment/floor_atlas.png: plain tile at (0,0),
## cracked variant at (1,0), scattered 15% with a fixed seed so the layout
## is deterministic). A TileSet .tres was NOT hand-authored: its text format
## is error-prone, so the TileSet is built in code and verified by the
## headless test runner instead.
## Walls: StaticBody2D ring in the .tscn (placeholder dark metal rectangles —
## the pixel atlas has no sci-fi wall segment; see docs/KNOWN_ISSUES.md)
## plus code-built divider/exterior walls for the new areas (see
## AREA_WALL_RECTS — the same list feeds the navigation grid, so walls
## and pathfinding can never disagree about what is solid).
## Phase 3: an alcove in the top-right corner, closed by an interactable
## door; Console B sits inside it. Interactable signals are wired here to
## the HUD message (consoles/door never touch the HUD themselves).
## Phase 4: two hidden objects (energy cell, battery) that a radar pulse
## reveals; their `revealed` signals are wired here the same way.
## Phase 5: one security robot patrolling a rectangle around the room
## center. The level assigns its waypoints and player reference, connects
## the player's pulse signal to its investigate(), and handles its
## player_caught signal by respawning the player at the entrance.
## Persian update (2026-11-12): one robot per area — five in total.
## Central Control keeps the security robot; Medical Wing the scanner;
## Research Laboratory a second security robot; Power Station a second
## scanner; Communication Yard a third security robot. Each security
## robot patrols a rectangle inside its own area (PATROL_RECTS); the
## wiring below assigns patrol points by the enemy's area, so a new
## robot never inherits Central's loop.
## Phase 6: pickups (one visible energy cell + the two hidden objects
## once revealed) emit `collected`; the level hands them to the player's
## inventory and shows a HUD message.
## Phase 7: three electrical puzzles (breaker panel, wire panel, fuse
## box) emit `solved`; the level counts them and updates the HUD counter.
## Phase 8: each solved puzzle restores power to one tower (the panel
## names it in `powers_tower`); the Mission node tracks the three stages
## (puzzles → towers → transmit) and the TransmitConsole sends the
## emergency signal once all towers are online.

## Shared level data lives in LevelData / MedicalData now (room split,
## 2026-11-15). These aliases mirror the shared constants for the live
## builders below. MED_PROP_PATHS is kept because the tests read it
## from this script (test_medical_props_exist).
const TILE_SIZE := LevelData.TILE_SIZE
const ROOM_COLS := LevelData.ROOM_COLS
const ROOM_ROWS := LevelData.ROOM_ROWS
const FLOOR_TEXTURE_PATH := LevelData.FLOOR_TEXTURE_PATH
const FLOOR_VARIANT_CHANCE := LevelData.FLOOR_VARIANT_CHANCE
const FLOOR_RNG_SEED := LevelData.FLOOR_RNG_SEED
const CONSOLE_SCENE: PackedScene = LevelData.CONSOLE_SCENE
const CRATE_TEXTURE: Texture2D = LevelData.CRATE_TEXTURE
const DISH_TEXTURE: Texture2D = LevelData.DISH_TEXTURE
const PANEL_TEXTURE: Texture2D = LevelData.PANEL_TEXTURE
const FUSEBOX_TEXTURE: Texture2D = LevelData.FUSEBOX_TEXTURE
const RIVET_TEXTURE: Texture2D = LevelData.RIVET_TEXTURE
const WALL_TEXTURE: Texture2D = LevelData.WALL_TEXTURE
const SPAWN := LevelData.SPAWN
const PATROL_POINTS: Array[Vector2] = LevelData.PATROL_POINTS
const PATROL_RECTS := LevelData.PATROL_RECTS
const PUZZLE_TOTAL := LevelData.PUZZLE_TOTAL
const STAGE_HINTS := LevelData.STAGE_HINTS
const AREA_HINTS := LevelData.AREA_HINTS
const AREAS := LevelData.AREAS
const AREA_WALL_RECTS := LevelData.AREA_WALL_RECTS
const PROP_SOLID_RECTS := LevelData.PROP_SOLID_RECTS
## Medical Wing pack (2026-11-15): 83 sprites from the pixel-art atlas
## (CC0) + hand-drawn tiles, copied to res://assets/sprites/medical-wing/.
## Only the Medical Wing uses them; the other areas keep the old look.
const MED_PROP_PATHS := MedicalData.MED_PROP_PATHS

## Solved-puzzle count (test hook: the tests read level._puzzles_solved).
## The count itself lives in LevelWiring; this mirrors it.
var _puzzles_solved: int = 0
var _nav_grid: AStarGrid2D = null
## Shared signal wiring (LevelWiring) and the room scenes this level
## instanced (kept for the flatten step in _ready).
var _wiring: LevelWiring = null
var _instanced_rooms: Array[RoomBase] = []
## What the instanced rooms already built, cached as data (not nodes):
## the rooms are queue_free'd by the flatten, so the legacy builders
## below — which run AFTER the flatten — must read these caches, not
## the freed room nodes.
var _instanced_wall_rects_cache: Array[Rect2] = []
var _instanced_area_names_cache: Array[String] = []
## Area the player is currently in (test hook + HUD naming).
var current_area: String = "کنترل مرکزی"

@onready var floor_layer: TileMapLayer = $Floor
## Player and Mission live in the command_center room scene now, so
## they only exist under this level after _flatten_rooms() in _ready.
var player: CharacterBody2D = null
var mission: Node = null


func _ready() -> void:
	_build_floor()
	_get_or_create_area_walls()
	_instance_rooms()
	_flatten_rooms()
	player = get_node("Player")
	mission = get_node("Mission")
	_build_area_walls()
	_build_area_tints()
	_build_nav_grid()
	_build_area_zones()
	_apply_camera_limits()
	# All signal wiring lives in LevelWiring now (shared with the
	# standalone room launcher), so a room plays the same wired.
	_wiring = LevelWiring.new()
	add_child(_wiring)
	_wiring.setup(self, player, mission, _nav_grid, _blocked_rects())
	# Deferred: the HUD's @onready vars are not assigned yet when this
	# level readies (siblings ready in tree order), so a direct call here
	# would hit a null label.
	_wiring.call_deferred("_update_objective_hud")
	_wiring.call_deferred("_update_stage_hint")
	_wiring.call_deferred("_setup_minimap")


## Room assembly (room split, 2026-11-15). See _instance_rooms /
## _flatten_rooms at the end of this file.


func _build_floor() -> void:
	floor_layer.tile_set = FloorBuilder.build_tileset()
	FloorBuilder.build_floor(floor_layer, Rect2i(0, 0, ROOM_COLS, ROOM_ROWS))


## The pack's wall tile for a code-built wall rect, or null to keep
## wall_metal. Only the Medical Wing's own walls are retextured.
func _medical_wall_texture(r: Rect2) -> Texture2D:
	return MedicalData.wall_texture_for(r)


func _build_area_walls() -> void:
	var body: StaticBody2D = _get_or_create_area_walls()
	for wall in AREA_WALL_RECTS:
		var r: Rect2 = wall
		# A wall an instanced room already built is skipped here: the
		# room's copy was flattened into this same body, so building
		# it again would double the shapes and the visuals.
		if r in _instanced_wall_rects():
			continue
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(r.size.x, r.size.y)
		shape.shape = rect
		shape.position = r.get_center()
		body.add_child(shape)
		var visual := Polygon2D.new()
		visual.polygon = PackedVector2Array([
			r.position, r.position + Vector2(r.size.x, 0),
			r.position + r.size, r.position + Vector2(0, r.size.y)])
		# Real wall art: the metal tile repeats every 16 px along the
		# wall (UVs = world coords, texture_repeat tiles them). The
		# color must be white — it multiplies the texture, and the old
		# dark flat color would hide the tile entirely. The Medical
		# Wing's own walls use the pack's wall tiles instead.
		visual.uv = visual.polygon
		var wall_tex: Texture2D = _medical_wall_texture(r)
		visual.texture = wall_tex if wall_tex != null else WALL_TEXTURE
		visual.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		visual.color = Color.WHITE
		body.add_child(visual)
		var highlight := Polygon2D.new()
		if r.size.x >= r.size.y:
			highlight.polygon = PackedVector2Array([
				r.position + Vector2(0, r.size.y - 4), r.position + Vector2(r.size.x, r.size.y - 4),
				r.position + r.size, r.position + Vector2(0, r.size.y)])
		else:
			highlight.polygon = PackedVector2Array([
				r.position + Vector2(r.size.x - 4, 0), r.position + Vector2(r.size.x, 0),
				r.position + r.size, r.position + Vector2(r.size.x - 4, r.size.y)])
		highlight.color = Color(0.22, 0.24, 0.32, 1)
		body.add_child(highlight)


func _build_area_tints() -> void:
	for area in AREAS:
		var tint: Color = area["tint"]
		if tint.a <= 0.0:
			continue
		# An instanced room already built its own tint; skip it here.
		if str(area["name"]) in _instanced_area_names():
			continue
		var r: Rect2 = area["rect"]
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([
			r.position, r.position + Vector2(r.size.x, 0),
			r.position + r.size, r.position + Vector2(0, r.size.y)])
		poly.color = tint
		add_child(poly)


func _build_nav_grid() -> void:
	var inflatable: Array[Rect2] = [Rect2(160, 80, 16, 16)]
	inflatable.append_array(PROP_SOLID_RECTS)
	_nav_grid = RoomBase.build_nav_grid(
		Rect2i(0, 0, ROOM_COLS, ROOM_ROWS), _blocked_rects(), inflatable)


## Every solid rect the grid must know about: the .tscn ring walls
## (with the two doorway gaps), the alcove walls, the crate, all
## code-built area walls, and the solid props. The alcove door itself
## is NOT in the list — it opens and closes, so a static grid cannot
## own it; an enemy pathing through it slides on the door instead.
func _blocked_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = [
		Rect2(0, 0, 640, 16), Rect2(0, 0, 16, 368),
		Rect2(624, 0, 16, 240), Rect2(624, 272, 16, 96),
		Rect2(0, 352, 288, 16), Rect2(320, 352, 320, 16),
		Rect2(496, 16, 16, 48), Rect2(512, 56, 40, 16), Rect2(584, 56, 40, 16),
		Rect2(160, 80, 16, 16),
	]
	rects.append_array(AREA_WALL_RECTS)
	rects.append_array(PROP_SOLID_RECTS)
	return rects


func _build_area_zones() -> void:
	for area in AREAS:
		# An instanced room already built its own zone; skip it here.
		if str(area["name"]) in _instanced_area_names():
			continue
		var r: Rect2 = area["rect"]
		var zone := Area2D.new()
		zone.name = "AreaZone_" + str(area["name"]).replace(" ", "")
		zone.set_meta("area_name", str(area["name"]))
		zone.collision_layer = 0
		zone.collision_mask = 1
		zone.monitoring = true
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = r.size
		shape.shape = rect
		shape.position = r.get_center()
		zone.add_child(shape)
		add_child(zone)


func _apply_camera_limits() -> void:
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = ROOM_COLS * TILE_SIZE
	camera.limit_bottom = ROOM_ROWS * TILE_SIZE



## Room assembly (room split, 2026-11-15).
##
## Each room scene (scenes/levels/rooms/<room>.tscn) builds its own
## area: walls, tint, zone, props, consoles, puzzles and its robot, at
## the exact positions this file used to build them. The assembler
## instances the rooms that exist, then FLATTENS their children into
## this level's tree and frees the empty room node — because the tests
## and the interaction panels read nodes by direct path from the level
## (level.get_node("Tower1"), "SecurityRobot", "AreaZone_...", and
## breaker_panel's get_node_or_null("Tower1")), and flattening keeps
## every one of those paths. A room's wall body is the one exception:
## its children (shapes, visuals, highlights) move into the shared
## "AreaWalls" body instead, so the wall-texture test still finds every
## Polygon2D directly under AreaWalls.
## Rooms not split yet are still built by the legacy builders below
## (_build_area_walls / _build_area_tints / _build_area_zones skip
## whatever the instanced rooms already built), so the level stays
## green at every step of the split.
const ROOM_SCENES := {
	"command_center": "res://scenes/levels/rooms/command_center.tscn",
	"medical_wing": "res://scenes/levels/rooms/medical_wing.tscn",
	"laboratory": "res://scenes/levels/rooms/laboratory.tscn",
	"engine_room": "res://scenes/levels/rooms/engine_room.tscn",
	"communications": "res://scenes/levels/rooms/communications.tscn",
}
const ROOM_NODE_NAMES := {
	"command_center": "CommandCenter",
	"medical_wing": "MedicalWing",
	"laboratory": "Laboratory",
	"engine_room": "EngineRoom",
	"communications": "CommunicationsYard",
}


func _instance_rooms() -> void:
	for room_key in ROOM_SCENES.keys():
		var path: String = ROOM_SCENES[room_key]
		if not ResourceLoader.exists(path):
			continue
		var room: RoomBase = load(path).instantiate()
		room.name = ROOM_NODE_NAMES[room_key]
		add_child(room)
		_instanced_rooms.append(room)
		_instanced_wall_rects_cache.append_array(room.wall_rects())
		_instanced_area_names_cache.append(room.area_name)


func _flatten_rooms() -> void:
	var walls_body: StaticBody2D = _get_or_create_area_walls()
	# Shared dividers are built by BOTH neighbouring rooms (exact
	# duplicates — e.g. the x=624 divider belongs to command_center
	# and medical_wing alike). The assembler keeps only one copy:
	# a wall rect already flattened from an earlier room is freed
	# instead of moved into AreaWalls a second time. Without this,
	# the second neighbouring room to land doubles its divider's
	# shapes and visuals (seen at the medical-wing merge: 7 medical
	# wall visuals instead of 5, 18 textured visuals instead of 16).
	var seen_wall_rects: Array[Rect2] = []
	for room in _instanced_rooms:
		var children: Array[Node] = room.get_children()
		for child in children:
			# Wall bodies dissolve into the shared AreaWalls body.
			if child.name == "Walls_" + room.room_key:
				var wall_children: Array[Node] = child.get_children()
				var i := 0
				while i < wall_children.size():
					# One wall rect = shape + visual + highlight, in
					# that order (RoomBase._build_wall_rects). The
					# visual's polygon encodes the rect: its first
					# point is the position, its third point is
					# position + size.
					if (
						i + 2 < wall_children.size()
						and wall_children[i] is CollisionShape2D
						and wall_children[i + 1] is Polygon2D
						and wall_children[i + 2] is Polygon2D
						and (wall_children[i + 1] as Polygon2D).polygon.size() >= 3
					):
						var visual: Polygon2D = wall_children[i + 1]
						var r := Rect2(visual.polygon[0], visual.polygon[2] - visual.polygon[0])
						if r in seen_wall_rects:
							wall_children[i].queue_free()
							wall_children[i + 1].queue_free()
							wall_children[i + 2].queue_free()
						else:
							seen_wall_rects.append(r)
							for k in range(3):
								child.remove_child(wall_children[i + k])
								walls_body.add_child(wall_children[i + k])
						i += 3
					else:
						# Unexpected node shape: move it rather than
						# lose it.
						var grandchild: Node = wall_children[i]
						child.remove_child(grandchild)
						walls_body.add_child(grandchild)
						i += 1
				child.queue_free()
				continue
			room.remove_child(child)
			add_child(child)
		room.queue_free()
	_instanced_rooms.clear()


func _get_or_create_area_walls() -> StaticBody2D:
	var body: StaticBody2D = get_node_or_null("AreaWalls")
	if body == null:
		body = StaticBody2D.new()
		body.name = "AreaWalls"
		body.collision_layer = 1
		body.collision_mask = 0
		add_child(body)
	return body


## Wall rects the instanced rooms already built (shared dividers are
## in here twice — once per neighbour — but a rect is a rect).
func _instanced_wall_rects() -> Array[Rect2]:
	return _instanced_wall_rects_cache


func _instanced_area_names() -> Array[String]:
	return _instanced_area_names_cache
