class_name RoomBase
extends Node2D
## Last Signal — base class for the five room modules (2026-11-15).
##
## A room builds only its own area: walls, tint, zone, props, consoles,
## puzzles and its robot, at the exact positions level_01.gd used.
## Shared systems (player, interaction panels, mission, radar, enemy AI,
## audio, UI) are never duplicated here — rooms only instance them.
##
## Two modes:
## - assembled (standalone = false): the level assembler instances the
##   room, then flattens its children into the level tree (see
##   level_01.gd _flatten_rooms). Node paths the tests read
##   (level.get_node("Tower1"), "SecurityRobot", "AreaZone_...") are
##   preserved by the flatten, so no test changes.
## - standalone (standalone = true): the room builds its own floor
##   (only its tile rect) so a developer can play it as its own game
##   through room_play.tscn.
##
## Shared dividers are built by BOTH neighbouring rooms (exact
## duplicates, no gameplay effect); the assembler keeps only one copy
## (see _instanced_wall_rects in level_01.gd). The floor is built only
## in standalone mode — the assembler builds the whole map floor once.

## Room key, e.g. "command_center". Also the wall-body suffix.
var room_key: String = ""
## Area name as in LevelData.AREAS, e.g. "کنترل مرکزی".
var area_name: String = ""
## Pixel rect of the area (from LevelData.AREAS).
var room_rect: Rect2 = Rect2()
## Tile rect of the area (room_rect / 16).
var room_tile_rect: Rect2i = Rect2i()
## HUD hint shown on entering the area.
var area_hint: String = ""
## Where the player spawns when the room is played standalone.
var spawn_point: Vector2 = Vector2.ZERO
## Floor tint (Color(0,0,0,0) = no tint).
var tint_color: Color = Color(0, 0, 0, 0)
## Set by the launcher for standalone play.
var standalone: bool = false

var _med_tex: Dictionary = {}


## Code-built wall rects of this room (from LevelData.AREA_WALL_RECTS,
## including the dividers shared with neighbours). Override per room.
func wall_rects() -> Array[Rect2]:
	return []


## Solid rects this room adds to the nav grid: its walls + its props.
## The assembler unions every room's list with the legacy
## _blocked_rects() so assembled and legacy grids agree.
func blocked_rects() -> Array[Rect2]:
	return wall_rects()


## Solid prop rects (subset of LevelData.PROP_SOLID_RECTS) of this room.
func prop_solid_rects() -> Array[Rect2]:
	return []


## Wall texture for a code-built wall rect. The texture is a property
## of the RECT, not the room: the Medical Wing's own walls (the x=624
## divider, its south divider and its east wall) use the pack's wall
## tiles, everything else uses wall_metal — the same rule the legacy
## builder used, so a shared divider gets the same texture whichever
## neighbour builds it.
func _wall_texture_for(r: Rect2) -> Texture2D:
	var med: Texture2D = MedicalData.wall_texture_for(r)
	return med if med != null else LevelData.WALL_TEXTURE


## Build the room's code-built walls as one StaticBody2D named
## "Walls_<room_key>". Visuals are built exactly like level_01.gd
## _build_area_walls: textured Polygon2D (UVs = world coords, texture
## repeats every 16 px, white color) + a darker edge highlight.
func _build_wall_rects(rects: Array[Rect2]) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = "Walls_" + room_key
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
		visual.texture = wall_tex if wall_tex != null else LevelData.WALL_TEXTURE
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
## floor matches the assembled floor cell for cell.
func _build_floor_if_standalone() -> void:
	if not standalone:
		return
	var layer := TileMapLayer.new()
	layer.name = "Floor"
	layer.tile_set = FloorBuilder.build_tileset()
	add_child(layer)
	FloorBuilder.build_floor(layer, room_tile_rect)


## Cached loader for the medical prop textures (MedicalData).
func _med_texture(key: String) -> Texture2D:
	if not _med_tex.has(key):
		_med_tex[key] = load(MedicalData.MED_PROP_PATHS[key])
	return _med_tex[key]


## Interactable area console with a log message (verbatim from
## level_01.gd). texture_key loads a medical sprite for the console.
func _add_area_console(pos: Vector2, message: String, texture_key: String = "") -> void:
	var console: Node2D = LevelData.CONSOLE_SCENE.instantiate()
	console.position = pos
	console.message = message
	if texture_key != "":
		console.sprite_texture = _med_texture(texture_key)
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


## A named, non-solid medical decor sprite (pack texture by key).
func _add_med_decor(key: String, pos: Vector2, node_name: String) -> void:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = _med_texture(key)
	sprite.position = pos
	add_child(sprite)


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
