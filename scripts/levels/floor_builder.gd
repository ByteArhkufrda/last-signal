class_name FloorBuilder
## Last Signal — deterministic floor builder (split from level_01.gd, 2026-11-15).
##
## The floor TileSet is built in code (a hand-authored .tres is
## error-prone) and the per-cell variant rolls come from one seeded
## RandomNumberGenerator, so the layout is deterministic. The roll order
## is exactly the original one — x outer, y inner, one roll per cell —
## so the Central floor pattern (and its test) is unchanged by the split.
## Rooms build only their own tile rect; the assembler builds the whole
## map. Both read the same rolls, so assembled and standalone floors
## agree cell for cell.

## The whole hospital floor is one uniform tile (2026-11-23):
## the plain light tile (index 4) of the medical atlas — one
## big block across the whole wing, no per-cell variation.
const MED_FLOOR_TILE := Vector2i(4, 0)

static var _rolls: PackedFloat32Array = PackedFloat32Array()


static func _ensure_rolls() -> void:
	if not _rolls.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = LevelData.FLOOR_RNG_SEED
	_rolls.resize(LevelData.ROOM_COLS * LevelData.ROOM_ROWS)
	for x in LevelData.ROOM_COLS:
		for y in LevelData.ROOM_ROWS:
			_rolls[x * LevelData.ROOM_ROWS + y] = rng.randf()


## Roll for one cell, in the original generation order.
static func roll_at(cell: Vector2i) -> float:
	_ensure_rolls()
	return _rolls[cell.x * LevelData.ROOM_ROWS + cell.y]


static func build_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(LevelData.TILE_SIZE, LevelData.TILE_SIZE)
	var source := TileSetAtlasSource.new()
	source.texture = load(LevelData.FLOOR_TEXTURE_PATH)
	source.texture_region_size = Vector2i(LevelData.TILE_SIZE, LevelData.TILE_SIZE)
	source.create_tile(Vector2i.ZERO)
	source.create_tile(Vector2i(1, 0))
	tileset.add_source(source)
	# Medical Wing floor: the pack's 12-tile atlas. Cells outside the
	# wing keep the old two tiles.
	var med_source := TileSetAtlasSource.new()
	med_source.texture = load(MedicalData.MED_FLOOR_TEXTURE_PATH)
	med_source.texture_region_size = Vector2i(LevelData.TILE_SIZE, LevelData.TILE_SIZE)
	for i in 12:
		med_source.create_tile(Vector2i(i, 0))
	tileset.add_source(med_source)
	return tileset



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
			if MedicalData.MED_RECT_TILES.has_point(global_cell):
				layer.set_cell(Vector2i(x, y), 1, MED_FLOOR_TILE)
			else:
				var coord := Vector2i(1, 0) if roll < LevelData.FLOOR_VARIANT_CHANCE else Vector2i.ZERO
				layer.set_cell(Vector2i(x, y), 0, coord)
