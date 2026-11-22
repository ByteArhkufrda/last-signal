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
## plus code-built divider/exterior walls, built by the rooms themselves
## in LOCAL coordinates and translated here to world coordinates. The
## same translated rects feed the navigation grid, so walls and
## pathfinding can never disagree about what is solid.
##
## Assembly (2026-11-23, local-coordinate rebase): each room is a
## self-contained module at its own (0, 0). This file is the ONLY place
## that knows where rooms sit in the station (ROOM_TILE_OFFSETS). It
## instances each room at its offset, flattens the children into the
## level tree (translating every child by the offset, so assembled world
## positions are unchanged), and derives the nav grid / blocked rects
## from the rooms. No room knows any neighbour's coordinates.
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
## Station position of each room, in tiles. The single source of
## truth for where rooms sit; rooms themselves never see this.
const ROOM_TILE_OFFSETS := {
	"command_center": Vector2i(0, 0),
	"medical_wing": Vector2i(40, 0),
	"laboratory": Vector2i(0, 23),
	"engine_room": Vector2i(40, 23),
	"communications": Vector2i(40, 46),
}
## Walls no room owns: the south-west quarter (floored, no area) has
## no room, so the assembler seals its west/south edges itself.
const STATION_ONLY_WALLS := [
	Rect2(0, 736, 16, 192), Rect2(0, 920, 640, 16),
]
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
var _instanced_rooms: Array[Node2D] = []
## What the instanced rooms already built, cached as data (not nodes):
## the rooms are queue_free'd by the flatten, so the legacy builders
## below — which run AFTER the flatten — must read these caches, not
## the freed room nodes.
var _instanced_wall_rects_cache: Array[Rect2] = []
var _instanced_area_names_cache: Array[String] = []
## The rooms' blocked / prop rects, translated to WORLD coordinates
## (same reason as the wall cache above).
var _instanced_blocked_cache: Array[Rect2] = []
var _instanced_prop_cache: Array[Rect2] = []
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
	_build_station_walls()
	_build_area_tints()
	_build_nav_grid()
	_build_area_zones()
	_apply_camera_limits()
	# All signal wiring lives in LevelWiring now; the standalone rooms
	# have their own wiring copies, so a room plays the same wired.
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


## Build only the walls no room owns (STATION_ONLY_WALLS, the
## south-west quarter). Every other wall is built by its room and
## flattened into AreaWalls by _flatten_rooms. Wall art is plain metal
## here — the Medical Wing's pack tiles are chosen by the room itself
## (the room's wall_texture_for_local).
func _build_station_walls() -> void:
	var body: StaticBody2D = _get_or_create_area_walls()
	for wall in STATION_ONLY_WALLS:
		var r: Rect2 = wall
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
		# dark flat color would hide the tile entirely.
		visual.uv = visual.polygon
		visual.texture = WALL_TEXTURE
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
	# Inflatable props are the rooms' own prop rects, in world coords.
	var inflatable: Array[Rect2] = _instanced_prop_rects()
	_nav_grid = build_nav_grid(
		Rect2i(0, 0, ROOM_COLS, ROOM_ROWS), _blocked_rects(), inflatable)


## Navigation grid for a tile region. The assembler's own copy of the
## grid builder (each room has its own copy too): walls are solid but
## NOT inflated (the 32 px doorways would close); props are inflated
## by one cell (a 12x14 body following a cell-center path passes
## within 1 px of a 16x16 obstacle's corner and gets stuck sliding on
## it — measured 2026-11-12).
static func build_nav_grid(tile_rect: Rect2i, blocked: Array[Rect2], inflatable: Array[Rect2]) -> AStarGrid2D:
	var grid := AStarGrid2D.new()
	grid.region = tile_rect
	grid.cell_size = Vector2(LevelData.TILE_SIZE, LevelData.TILE_SIZE)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for x in range(tile_rect.position.x, tile_rect.end.x):
		for y in range(tile_rect.position.y, tile_rect.end.y):
			var cell := Rect2(x * LevelData.TILE_SIZE, y * LevelData.TILE_SIZE, LevelData.TILE_SIZE, LevelData.TILE_SIZE)
			for r in blocked:
				if cell.intersects(r):
					grid.set_point_solid(Vector2i(x, y), true)
					break
	for r in inflatable:
		var min_cell := Vector2i(int(r.position.x / LevelData.TILE_SIZE) - 1, int(r.position.y / LevelData.TILE_SIZE) - 1)
		var max_cell := Vector2i(int(r.end.x / LevelData.TILE_SIZE) + 1, int(r.end.y / LevelData.TILE_SIZE) + 1)
		for cx in range(min_cell.x, max_cell.x):
			for cy in range(min_cell.y, max_cell.y):
				if tile_rect.has_point(Vector2i(cx, cy)):
					grid.set_point_solid(Vector2i(cx, cy), true)
	return grid


## Every solid rect the grid must know about, derived from the rooms:
## each room's blocked rects translated to world coordinates, plus the
## station-only walls. The .tscn ring walls, alcove walls and crate
## are inside command_center's blocked rects. The alcove door itself
## is NOT in the list — it opens and closes, so a static grid cannot
## own it; an enemy pathing through it slides on the door instead.
func _blocked_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = _instanced_blocked_cache.duplicate()
	rects.append_array(STATION_ONLY_WALLS)
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
## Every room is split now: tints and zones are built by the rooms
## themselves (_build_area_tints / _build_area_zones skip whatever the
## instanced rooms already built), and walls come from the rooms too —
## the assembler only builds the station-only walls itself.
const ROOM_SCENES := {
	"command_center": "res://scenes/levels/rooms/command_center/command_center.tscn",
	"medical_wing": "res://scenes/levels/rooms/medical_wing/medical_wing.tscn",
	"laboratory": "res://scenes/levels/rooms/laboratory/laboratory.tscn",
	"engine_room": "res://scenes/levels/rooms/engine_room/engine_room.tscn",
	"communications": "res://scenes/levels/rooms/communications/communications.tscn",
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
		var room: Node2D = load(path).instantiate()
		room.name = ROOM_NODE_NAMES[room_key]
		# Place the room at its station offset BEFORE add_child, so
		# _ready builds with the right tile offset (floor rolls) and
		# the node itself sits at the offset its children are local to.
		var tile_offset: Vector2i = ROOM_TILE_OFFSETS[room_key]
		room.tile_offset = tile_offset
		room.map_offset = Vector2(tile_offset) * TILE_SIZE
		room.position = room.map_offset
		add_child(room)
		_instanced_rooms.append(room)
		for r in room.wall_rects():
			_instanced_wall_rects_cache.append(room.to_world_rect(r))
		for r in room.blocked_rects():
			_instanced_blocked_cache.append(room.to_world_rect(r))
		for r in room.prop_solid_rects():
			_instanced_prop_cache.append(room.to_world_rect(r))
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
	# All rects here are WORLD rects: the rooms' local geometry is
	# translated by each room's map offset on the way in.
	var seen_wall_rects: Array[Rect2] = []
	for room in _instanced_rooms:
		var offset: Vector2 = room.map_offset
		var children: Array[Node] = room.get_children()
		for child in children:
			# Wall bodies dissolve into the shared AreaWalls body.
			if child.name == "Walls_" + room.room_key:
				var wall_children: Array[Node] = child.get_children()
				var i := 0
				while i < wall_children.size():
					# One wall rect = shape + visual + highlight, in
					# that order (the room's _build_wall_rects). The
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
						var r := Rect2(visual.polygon[0] + offset, visual.polygon[2] - visual.polygon[0])
						if r in seen_wall_rects:
							wall_children[i].queue_free()
							wall_children[i + 1].queue_free()
							wall_children[i + 2].queue_free()
						else:
							seen_wall_rects.append(r)
							for k in range(3):
								var piece: Node = wall_children[i + k]
								_translate_wall_piece(piece, offset)
								# A shared divider's texture is a
								# property of its WORLD rect, not of
								# whichever neighbour built the
								# surviving copy (see MedicalData):
								# retexture the visual on the way in.
								if piece is Polygon2D and (piece as Polygon2D).texture != null:
									var station_tex: Texture2D = MedicalData.wall_texture_for_station_rect(r)
									if station_tex != null:
										(piece as Polygon2D).texture = station_tex
								child.remove_child(piece)
								walls_body.add_child(piece)
						i += 3
					else:
						# Unexpected node shape: move it rather than
						# lose it.
						var grandchild: Node = wall_children[i]
						_translate_wall_piece(grandchild, offset)
						child.remove_child(grandchild)
						walls_body.add_child(grandchild)
						i += 1
				child.queue_free()
				continue
			# Every other child keeps its LOCAL geometry; translating
			# the child's own position by the room offset puts it at
			# its world position (zones, tints, consoles, robots,
			# towers, puzzles, the player — all Node2D).
			if child is Node2D:
				(child as Node2D).position += offset
			room.remove_child(child)
			add_child(child)
		room.queue_free()
	_instanced_rooms.clear()


## Translate one wall-body piece (shape / visual / highlight) from a
## room's local coordinates to world coordinates. Shapes carry their
## position; polygons carry their points (and UVs, which equal the
## points for wall visuals).
func _translate_wall_piece(node: Node, offset: Vector2) -> void:
	if node is CollisionShape2D:
		(node as CollisionShape2D).position += offset
	elif node is Polygon2D:
		var poly: Polygon2D = node as Polygon2D
		var points := PackedVector2Array()
		for p in poly.polygon:
			points.append(p + offset)
		poly.polygon = points
		if not poly.uv.is_empty():
			var uvs := PackedVector2Array()
			for p in poly.uv:
				uvs.append(p + offset)
			poly.uv = uvs


func _get_or_create_area_walls() -> StaticBody2D:
	var body: StaticBody2D = get_node_or_null("AreaWalls")
	if body == null:
		body = StaticBody2D.new()
		body.name = "AreaWalls"
		body.collision_layer = 1
		body.collision_mask = 0
		add_child(body)
	return body


## Wall rects the instanced rooms already built, in WORLD coordinates
## (shared dividers are in here twice — once per neighbour — but a
## rect is a rect).
func _instanced_wall_rects() -> Array[Rect2]:
	return _instanced_wall_rects_cache


## Blocked / solid-prop rects the instanced rooms already built, in
## WORLD coordinates (feeds the nav grid and the minimap).
func _instanced_blocked_rects() -> Array[Rect2]:
	return _instanced_blocked_cache


func _instanced_prop_rects() -> Array[Rect2]:
	return _instanced_prop_cache


func _instanced_area_names() -> Array[String]:
	return _instanced_area_names_cache
