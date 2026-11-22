extends Node2D
## Last Signal — communications (self-contained room module, 2026-11-23).
##
## Absolute separation: this file shares NOTHING with the other
## rooms. The former RoomBase helpers, the floor builder, the
## textures and hints it needs are all inlined here; its wiring,
## player, mission and interaction/enemy scenes live as copies
## in this room's own folders. Only sprite/texture art (assets/)
## is still shared — art, not logic. The assembled level
## (level_01.gd) keeps the original shared files; no room reads
## them.

const TILE_SIZE := 16
const ROOM_COLS := 80
const ROOM_ROWS := 58
const FLOOR_TEXTURE_PATH := "res://assets/sprites/environment/floor_atlas.png"
const FLOOR_VARIANT_CHANCE := 0.15
const FLOOR_RNG_SEED := 17
const MED_FLOOR_TEXTURE_PATH := "res://assets/sprites/environment/floor_medical_atlas.png"
const MED_FLOOR_WEIGHTS := [0.70, 0.78, 0.84, 0.85, 0.87, 0.89, 0.92, 0.94, 0.97, 0.98, 0.99, 1.0]
const MED_RECT_TILES := Rect2i(40, 0, 40, 23)
const WALL_TEXTURE: Texture2D = preload("res://assets/sprites/environment/wall_metal.png")
const CONSOLE_SCENE: PackedScene = preload("res://scenes/levels/rooms/communications/console_communications.tscn")

## Last Signal — Communications Yard room (communications), split from
## level_01.gd / level_01.tscn, 2026-11-15; local coordinates 2026-11-23.
##
## The south annex: its west/east/south walls, the divider to the
## Power Station, the area console, the satellite dish and the yard
## security robot (local (160, 104); was (800, 840) in station
## coordinates). Station offset is (40, 46) tiles.

func _ready() -> void:
	room_key = "communications"
	area_name = "محوطه‌ی مخابرات"
	room_rect = Rect2(0, 0, 640, 192)
	room_tile_rect = Rect2i(0, 0, 40, 12)
	area_hint = "محوطه‌ی مخابرات — بشقاب‌های ماهواره اینجاست؛ یک ربات امنیتی گشت می‌زند"
	spawn_point = Vector2(304, 24)
	tint_color = Color(0.3, 0.4, 0.7, 0.12)
	_build_floor_if_standalone()
	_build_wall_rects(wall_rects())
	_build_tint()
	_build_zone()
	_add_area_console(Vector2(260, 84), "گزارش محوطه: آرایه‌ی بشقاب به ماهواره‌ی رله اشاره می‌کند. بدون دکل‌ها سیگنالی نیست.")
	_add_prop(preload("res://assets/sprites/props/tower_1_satellite.png"), Vector2(510, 84))


func wall_rects() -> Array[Rect2]:
	return [
		Rect2(-16, 0, 16, 192), Rect2(624, 0, 16, 192),
		Rect2(0, 184, 640, 16),
		Rect2(0, -8, 288, 16), Rect2(320, -8, 320, 16),
	]


func blocked_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = wall_rects()
	rects.append_array(prop_solid_rects())
	return rects


func prop_solid_rects() -> Array[Rect2]:
	return [Rect2(502, 76, 16, 16)]


func patrol_points_local() -> Array[Vector2]:
	return [
		Vector2(80, 54), Vector2(540, 54),
		Vector2(540, 144), Vector2(80, 144),
	]


func exits() -> Array[Dictionary]:
	return [
		{"id": "north", "edge": "north", "rect": Rect2(288, -8, 32, 16),
			"target_room": "engine_room", "target_exit": "south"},
	]


## Room key, e.g. "command_center". Also the wall-body suffix.
var room_key: String = ""
## Area name as in LevelData.AREAS, e.g. "کنترل مرکزی".
var area_name: String = ""
## Pixel rect of the area, in LOCAL coordinates: position is (0, 0).
var room_rect: Rect2 = Rect2()
## Tile rect of the area, in LOCAL coordinates: position is (0, 0).
var room_tile_rect: Rect2i = Rect2i()
## The room's position in the station map, in tiles. Set by the
## assembler (level_01.gd) or the standalone launcher (room_play.gd)
## BEFORE add_child, so _ready can use it. It only feeds the floor
## builder: rolls are read at the GLOBAL cell, so the standalone floor
## matches the assembled floor. Standalone it is still the station
## offset — the floor pattern belongs to the station, not the room.
var tile_offset: Vector2i = Vector2i.ZERO
## Where this room node actually sits, in pixels. The assembler sets
## it to tile_offset * TILE_SIZE (and room.position to match); the
## standalone launcher leaves it at (0, 0), so local == global there.
var map_offset: Vector2 = Vector2.ZERO
## HUD hint shown on entering the area.
var area_hint: String = ""
## Where the player spawns when the room is played standalone.
var spawn_point: Vector2 = Vector2.ZERO
## Floor tint (Color(0,0,0,0) = no tint).
var tint_color: Color = Color(0, 0, 0, 0)
## Set by the launcher for standalone play.
var standalone: bool = false


## This room's pixel rect in STATION (world) coordinates.
func world_rect() -> Rect2:
	return Rect2(room_rect.position + map_offset, room_rect.size)

## A local rect translated to station (world) coordinates.
func to_world_rect(r: Rect2) -> Rect2:
	return Rect2(r.position + map_offset, r.size)

## A local point translated to station (world) coordinates.
func to_world_point(p: Vector2) -> Vector2:
	return p + map_offset

func _wall_texture_for(r: Rect2) -> Texture2D:
	return wall_texture_for_local(r)

## Doorway gaps in this room's walls, for the standalone launcher.
## In the full map the gaps open into the neighbouring rooms; in
## standalone there is nothing beyond them, so the launcher seals them
## with walls. Computed from wall_rects(): on each wall line (one x
## for vertical walls, one y for horizontal), the intervals the
## room's wall rects do not cover, bounded by the room's own extent.
## Walls the .tscn builds (Central's north/west ring) are not in
## wall_rects(), so they never produce a spurious gap here.
func doorway_gap_rects() -> Array[Rect2]:
	var gaps: Array[Rect2] = []
	var vertical: Dictionary = {}
	var horizontal: Dictionary = {}
	for r in wall_rects():
		if r.size.x == 16 and r.size.y > 16:
			if not vertical.has(r.position.x):
				vertical[r.position.x] = []
			(vertical[r.position.x] as Array).append(r)
		elif r.size.y == 16 and r.size.x > 16:
			if not horizontal.has(r.position.y):
				horizontal[r.position.y] = []
			(horizontal[r.position.y] as Array).append(r)
	for x in vertical.keys():
		var rects: Array = vertical[x]
		rects.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.y < b.position.y)
		var covered: float = room_rect.position.y
		for r in rects:
			if r.position.y > covered:
				gaps.append(Rect2(x, covered, 16, r.position.y - covered))
			covered = maxf(covered, r.end.y)
		if covered < room_rect.end.y:
			gaps.append(Rect2(x, covered, 16, room_rect.end.y - covered))
	for y in horizontal.keys():
		var rects: Array = horizontal[y]
		rects.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.x < b.position.x)
		var covered: float = room_rect.position.x
		for r in rects:
			if r.position.x > covered:
				gaps.append(Rect2(covered, y, r.position.x - covered, 16))
			covered = maxf(covered, r.end.x)
		if covered < room_rect.end.x:
			gaps.append(Rect2(covered, y, room_rect.end.x - covered, 16))
	return gaps

## Build the room's code-built walls as one StaticBody2D named
## "Walls_<room_key>". Textured Polygon2D (UVs = the rect's coords,
## texture repeats every 16 px, white color) + a darker edge
## highlight. Coordinates are LOCAL; the assembler translates them to
## world coordinates when it flattens the room into the level.
func _build_wall_rects(rects: Array[Rect2], body_name: String = "") -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = body_name if body_name != "" else "Walls_" + room_key
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	for r in rects:
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
		visual.uv = visual.polygon
		var wall_tex: Texture2D = _wall_texture_for(r)
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
	return body

## Area floor tint polygon (skipped when the tint is transparent).
func _build_tint() -> void:
	if tint_color.a <= 0.0:
		return
	var r: Rect2 = room_rect
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		r.position, r.position + Vector2(r.size.x, 0),
		r.position + r.size, r.position + Vector2(0, r.size.y)])
	poly.color = tint_color
	add_child(poly)

## Entry zone for the area. It only carries the area name as metadata;
## the assembler / launcher connects body_entered to the wiring.
func _build_zone() -> void:
	var r: Rect2 = room_rect
	var zone := Area2D.new()
	zone.name = "AreaZone_" + area_name.replace(" ", "")
	zone.set_meta("area_name", area_name)
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

## Standalone only: build this room's floor tiles (its tile rect) with
## the same seeded rolls the whole-map floor uses, so the standalone
## floor matches the assembled floor cell for cell. Rolls are read at
## the GLOBAL cell (local + tile_offset); cells are written locally.
func _build_floor_if_standalone() -> void:
	if not standalone:
		return
	var layer := TileMapLayer.new()
	layer.name = "Floor"
	layer.tile_set = build_tileset()
	add_child(layer)
	build_floor(layer, room_tile_rect, tile_offset)

## Interactable area console with a log message (verbatim from
## level_01.gd). texture_key loads a medical sprite for the console.
func _add_area_console(pos: Vector2, message: String, texture_key: String = "") -> void:
	var console: Node2D = CONSOLE_SCENE.instantiate()
	console.position = pos
	console.message = message
	add_child(console)

## Solid prop: sprite + physics body (verbatim from level_01.gd).
func _add_prop(texture: Texture2D, pos: Vector2, size: Vector2 = Vector2(16, 16), prop_name: String = "") -> void:
	var body := StaticBody2D.new()
	if prop_name != "":
		body.name = prop_name
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	var sprite := Sprite2D.new()
	sprite.texture = texture
	body.add_child(sprite)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)

## A plain non-solid decor sprite.
func _add_decor(texture: Texture2D, pos: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = pos
	add_child(sprite)

## Navigation grid for a tile region. Verbatim logic from level_01.gd
## _build_nav_grid, parameterized: walls are solid but NOT inflated
## (the 32 px doorways would close); props are inflated by one cell
## (a 12x14 body following a cell-center path passes within 1 px of a
## 16x16 obstacle's corner and gets stuck sliding on it — measured
## 2026-11-12).
static func build_nav_grid(tile_rect: Rect2i, blocked: Array[Rect2], inflatable: Array[Rect2]) -> AStarGrid2D:
	var grid := AStarGrid2D.new()
	grid.region = tile_rect
	grid.cell_size = Vector2(TILE_SIZE, TILE_SIZE)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for x in range(tile_rect.position.x, tile_rect.end.x):
		for y in range(tile_rect.position.y, tile_rect.end.y):
			var cell := Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
			for r in blocked:
				if cell.intersects(r):
					grid.set_point_solid(Vector2i(x, y), true)
					break
	for r in inflatable:
		var min_cell := Vector2i(int(r.position.x / TILE_SIZE) - 1, int(r.position.y / TILE_SIZE) - 1)
		var max_cell := Vector2i(int(r.end.x / TILE_SIZE) + 1, int(r.end.y / TILE_SIZE) + 1)
		for cx in range(min_cell.x, max_cell.x):
			for cy in range(min_cell.y, max_cell.y):
				if tile_rect.has_point(Vector2i(cx, cy)):
					grid.set_point_solid(Vector2i(cx, cy), true)
	return grid

## Wall texture for a code-built wall rect, in LOCAL coordinates.
## Default is wall_metal; a room with its own wall art (Medical Wing)
## overrides this for its own rects.
func wall_texture_for_local(_r: Rect2) -> Texture2D:
	return WALL_TEXTURE


static var _rolls: PackedFloat32Array = PackedFloat32Array()


static func _ensure_rolls() -> void:
	if not _rolls.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = FLOOR_RNG_SEED
	_rolls.resize(ROOM_COLS * ROOM_ROWS)
	for x in ROOM_COLS:
		for y in ROOM_ROWS:
			_rolls[x * ROOM_ROWS + y] = rng.randf()


## Roll for one cell, in the original generation order.
static func roll_at(cell: Vector2i) -> float:
	_ensure_rolls()
	return _rolls[cell.x * ROOM_ROWS + cell.y]


static func build_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var source := TileSetAtlasSource.new()
	source.texture = load(FLOOR_TEXTURE_PATH)
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	source.create_tile(Vector2i.ZERO)
	source.create_tile(Vector2i(1, 0))
	tileset.add_source(source)
	# Medical Wing floor: the pack's 12-tile atlas. Cells outside the
	# wing keep the old two tiles.
	var med_source := TileSetAtlasSource.new()
	med_source.texture = load(MED_FLOOR_TEXTURE_PATH)
	med_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for i in 12:
		med_source.create_tile(Vector2i(i, 0))
	tileset.add_source(med_source)
	return tileset


## First weight threshold above the roll: the medical floor tile index.
static func medical_floor_index(roll: float) -> int:
	for i in MED_FLOOR_WEIGHTS.size():
		if roll < MED_FLOOR_WEIGHTS[i]:
			return i
	return 0


## Fill `layer` (which must already have the tileset from
## build_tileset()) for the given tile rect. Source 0 is the standard
## two-tile atlas, source 1 the medical 12-tile atlas.
## `tile_rect` is in the layer's own (local) coordinates; `tile_offset`
## is the room's position in the station map, in tiles. Rolls and the
## medical-floor check use the GLOBAL cell (local + offset), so a room's
## standalone floor matches the assembled floor cell for cell, while
## the cells themselves are written at local coordinates.
static func build_floor(layer: TileMapLayer, tile_rect: Rect2i, tile_offset: Vector2i = Vector2i.ZERO) -> void:
	_ensure_rolls()
	for x in range(tile_rect.position.x, tile_rect.end.x):
		for y in range(tile_rect.position.y, tile_rect.end.y):
			var global_cell := Vector2i(x, y) + tile_offset
			var roll: float = roll_at(global_cell)
			if MED_RECT_TILES.has_point(global_cell):
				layer.set_cell(Vector2i(x, y), 1, Vector2i(medical_floor_index(roll), 0))
			else:
				var coord := Vector2i(1, 0) if roll < FLOOR_VARIANT_CHANCE else Vector2i.ZERO
				layer.set_cell(Vector2i(x, y), 0, coord)
