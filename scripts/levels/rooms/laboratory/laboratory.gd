extends Node2D
## Last Signal — laboratory (self-contained room module, 2026-11-23).
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
const CONSOLE_SCENE: PackedScene = preload("res://scenes/levels/rooms/laboratory/console_laboratory.tscn")
const POWER_PANEL_SCENE: PackedScene = preload("res://scenes/levels/rooms/laboratory/power_panel_laboratory.tscn")
const SIGNAL_ANALYZER_SCENE: PackedScene = preload("res://scenes/levels/rooms/laboratory/signal_analyzer_laboratory.tscn")
const RESEARCH_VAULT_SCENE: PackedScene = preload("res://scenes/levels/rooms/laboratory/research_vault_laboratory.tscn")

## ORION texts (design doc, 2026-11-27). The research log is the
## first clue; the notes carry the vault code (01 / 03 / 07 → 137).
const RESEARCH_LOG_TEXT := "Research Log — 17/08/2089\nنمونه‌ی دریافتی از ناهنجاری فضایی برخلاف تمام پیش‌بینی‌های ما رفتار می‌کند.\nاین نمونه هیچ ساختار زیستی شناخته‌شده‌ای ندارد، اما به محرک‌های الکتریکی واکنش نشان می‌دهد.\nدکتر آریا معتقد است نمونه نوعی آگاهی مستقل دارد.\nدر آخرین آزمایش، پس از افزایش انرژی ورودی، نمونه شروع به انتشار پالس‌های نوری کرد.\nنمونه فقط به سومین الگوی فرکانسی ثبت‌شده پاسخ داد.\nدستور توقف آزمایش صادر شد.\nارتباط با تیم تحقیقاتی قطع شده است."
const WAVE_MONITOR_TEXT := "مانیتور موج — سه الگوی ثبت‌شده:\nPattern A: موج یکنواخت\nPattern B: موج نامنظم\nPattern C: سه پالس متوالی با فاصله‌های مشخص"
const NOTE_01_TEXT := "Experiment 01 — First Contact\nاولین تماس با نمونه: واکنش به محرک الکتریکی ضعیف. یک پالس نوری کوتاه ثبت شد."
const NOTE_03_TEXT := "Experiment 03 — First Response\nاولین پاسخ معنادار: نمونه به الگوی سوم فرکانس واکنش نشان داد. سه پالس متوالی."
const NOTE_07_TEXT := "Experiment 07 — Final Observation\nمشاهده‌ی نهایی: یکی از اعضای تیم گفت صدای خودش را از داخل محفظه شنیده است. اما هیچ‌کس داخل محفظه نبود."

## Sample chamber glow state (set by the wiring when puzzle 1 solves).
var chamber_active: bool = false
var _chamber_glow: Polygon2D = null
var _glow_tween: Tween = null

## Last Signal — Research Laboratory room (laboratory), split from
## level_01.gd / level_01.tscn, 2026-11-15; local coordinates 2026-11-23.
##
## The bottom-left wing: its divider walls, the area console, the
## crate and the lab security robot (local (200, 192); was (200, 560)
## in station coordinates). Station offset is (0, 23) tiles.

func _ready() -> void:
	room_key = "laboratory"
	area_name = "آزمایشگاه تحقیقاتی"
	room_rect = Rect2(0, 0, 640, 368)
	room_tile_rect = Rect2i(0, 0, 40, 23)
	area_hint = "آزمایشگاه ORION — نمونه‌ی ناشناخته؛ اول گزارش تحقیقاتی را بخوان"
	spawn_point = Vector2(320, 32)
	tint_color = Color(0.4, 0.6, 1.0, 0.07)
	_build_floor_if_standalone()
	_build_wall_rects(wall_rects())
	_build_tint()
	_build_zone()
	# Research section (north-west): the log, the wave monitor and
	# the experiment notes — the first clue and the vault code.
	_add_named_console(Vector2(80, 64), RESEARCH_LOG_TEXT, "ResearchLogConsole", "گزارش")
	_add_named_console(Vector2(144, 64), NOTE_07_TEXT, "Note07", "یادداشت ۰۷")
	_add_named_console(Vector2(224, 64), WAVE_MONITOR_TEXT, "WaveMonitor", "موج")
	_add_named_console(Vector2(80, 128), NOTE_01_TEXT, "Note01", "یادداشت ۰۱")
	_add_named_console(Vector2(480, 80), NOTE_03_TEXT, "Note03", "یادداشت ۰۳")
	# Sample section (centre): the containment chamber and its power
	# panel. Analysis (east): the signal analyzer. Security
	# (south-east): the research vault holding the keycard.
	_build_sample_chamber()
	var power_panel: StaticBody2D = POWER_PANEL_SCENE.instantiate()
	power_panel.name = "PowerPanel"
	power_panel.position = Vector2(240, 176)
	add_child(power_panel)
	var analyzer: StaticBody2D = SIGNAL_ANALYZER_SCENE.instantiate()
	analyzer.name = "SignalAnalyzer"
	analyzer.position = Vector2(552, 96)
	add_child(analyzer)
	var vault: StaticBody2D = RESEARCH_VAULT_SCENE.instantiate()
	vault.name = "ResearchVault"
	vault.position = Vector2(552, 312)
	add_child(vault)
	# Chained puzzles: power → signal → vault. Each puzzle unlocks
	# the next one; the wiring counts all three as solved.
	power_panel.solved.connect(analyzer.unlock)
	analyzer.solved.connect(vault.unlock)
	_add_prop(preload("res://assets/sprites/props/crate.png"), Vector2(480, 272))


func wall_rects() -> Array[Rect2]:
	return [
		Rect2(624, 0, 16, 160), Rect2(624, 192, 16, 176),
		Rect2(0, -16, 288, 16), Rect2(320, -16, 320, 16),
		Rect2(0, 360, 640, 16),
		# West exterior (2026-11-19: this edge had no wall — the
		# player walked off the map beside the lab, in the full game).
		Rect2(0, 0, 16, 368),
	]


func blocked_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = wall_rects()
	rects.append_array(prop_solid_rects())
	return rects


func prop_solid_rects() -> Array[Rect2]:
	return [Rect2(472, 264, 16, 16)]


func patrol_points_local() -> Array[Vector2]:
	return [
		Vector2(160, 112), Vector2(520, 112),
		Vector2(520, 272), Vector2(160, 272),
	]


func exits() -> Array[Dictionary]:
	return [
		{"id": "north", "edge": "north", "rect": Rect2(288, -16, 32, 16),
			"target_room": "command_center", "target_exit": "south"},
		{"id": "east", "edge": "east", "rect": Rect2(624, 160, 16, 32),
			"target_room": "engine_room", "target_exit": "west"},
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


## Named console (ORION): same as _add_area_console, but the node
## gets a stable name so tests and the assembled level can find it,
## plus a small name label above it (Stage 3, Q1): all five consoles
## share one sprite, so without a label the player cannot tell the
## research log from a note without reading each one.
func _add_named_console(pos: Vector2, message: String, node_name: String, label_text: String = "") -> void:
	var console: Node2D = CONSOLE_SCENE.instantiate()
	console.name = node_name
	console.position = pos
	console.message = message
	add_child(console)
	if label_text != "":
		var label := Label.new()
		label.name = "NameLabel"
		label.text = label_text
		# Beside the console, not above it (Stage 3, Q1 fix): a label
		# above the north-row consoles lands on the HUD's objective
		# line when the player stands south of them, and 96 px wide
		# labels on consoles 64 px apart print over each other.
		# Short names + right-side placement clear both.
		label.position = Vector2(12, -6)
		label.size = Vector2(64, 12)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.add_theme_font_size_override("font_size", 9)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		label.add_theme_constant_override("outline_size", 2)
		console.add_child(label)


## The sample containment chamber (ORION, centre of the room):
## hazard-striped frame, dark interior, cyan sample glow. Solid
## (the player walks around it) but deliberately NOT in
## prop_solid_rects: it sits inside the patrol rectangle, never on
## the robot's loop, and the nav grid must keep agreeing with the
## assembled level cell for cell.
func _build_sample_chamber() -> void:
	var chamber := StaticBody2D.new()
	chamber.name = "SampleChamber"
	chamber.position = Vector2(320, 176)
	chamber.collision_layer = 1
	chamber.collision_mask = 0
	var frame := Polygon2D.new()
	frame.polygon = PackedVector2Array([
		Vector2(-34, -26), Vector2(34, -26),
		Vector2(34, 26), Vector2(-34, 26)])
	frame.color = Color(0.85, 0.7, 0.1)
	chamber.add_child(frame)
	var inner := Polygon2D.new()
	inner.polygon = PackedVector2Array([
		Vector2(-30, -22), Vector2(30, -22),
		Vector2(30, 22), Vector2(-30, 22)])
	inner.color = Color(0.08, 0.1, 0.14)
	chamber.add_child(inner)
	_chamber_glow = Polygon2D.new()
	_chamber_glow.polygon = PackedVector2Array([
		Vector2(-18, -14), Vector2(18, -14),
		Vector2(18, 14), Vector2(-18, 14)])
	_chamber_glow.color = Color(0.1, 0.35, 0.6)
	chamber.add_child(_chamber_glow)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(68, 52)
	shape.shape = rect
	chamber.add_child(shape)
	add_child(chamber)


## Light the sample glow (called by the wiring when puzzle 1 solves).
## Active, the glow pulses gently (Stage 3, Q10): a static cyan slab
## reads as painted on, a slow pulse reads as a living sample.
func set_chamber_active(active: bool) -> void:
	chamber_active = active
	if _chamber_glow == null:
		return
	if _glow_tween != null and _glow_tween.is_valid():
		_glow_tween.kill()
		_glow_tween = null
	if active:
		_chamber_glow.color = Color(0.2, 0.85, 1.0)
		_glow_tween = create_tween().set_loops()
		_glow_tween.tween_property(_chamber_glow, "color", Color(0.45, 0.95, 1.0), 0.9)
		_glow_tween.tween_property(_chamber_glow, "color", Color(0.2, 0.85, 1.0), 0.9)
	else:
		_chamber_glow.color = Color(0.1, 0.35, 0.6)

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
