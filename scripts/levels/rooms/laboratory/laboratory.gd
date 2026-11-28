extends Node2D
## Last Signal — laboratory (self-contained room module, 2026-11-23).
##
## Absolute separation: this file shares NOTHING with the other
## rooms. The former RoomBase helpers and the textures and hints it
## needs are all inlined here; its wiring, player, mission and
## interaction/enemy scenes live as copies in this room's own
## folders. Only sprite/texture art (assets/) is still shared — art,
## not logic. The assembled level (level_01.gd) keeps the original
## shared files; no room reads them.
##
## Layout (2026-11-28, from the user's main.gd reference): the room
## is the reference's L-shaped lab, 640x576 px (20x18 cells of 32 px
## = 40x36 logical 16 px tiles). White lab block top-left (rows 0-5),
## dark station hall below and right, a blue trim row, and the purple
## escape strip along the bottom. The floor is ONE smooth sprite
## (assets/sprites/laboratory/floor_lab.png, painted from the MAP) —
## no tile grid. Walls are the MAP's '#' cells merged into rects.
## Puzzle devices sit on the MAP's PROPS: chamber on pod_right,
## power panel on the generator, analyzer on the terminal, vault on
## the supply shelf, consoles on the computer / med bed / surgery
## arm / counter / console row. The other PROPS are solid decor.
## Two patrol robots run main.gd's two straight routes. Lighting is
## main.gd's dim ambient + three ceiling lights (standalone only:
## the assembled level keeps its own bright lighting).
##
## Station fit (2026-11-28, honest limitation): the room is 36
## logical tiles tall at station offset (0, 23), so it needs station
## rows 23-59 — but the station has 58 rows. Rows 58-59 exist only
## standalone; in the assembled level the room's south strip hangs
## past the map (no floor tiles there, no nav-grid cells), and the
## room's new walls/props are not in LevelData's station lists, so
## test_station_layout_agrees_with_rooms (and the grid-agreement
## check inside the standalone room test) fail by design. The
## standalone room is correct and complete; the assembled fit is a
## separate, LevelData-sized job.

const TILE_SIZE := 16
const WALL_TEXTURE: Texture2D = preload("res://assets/sprites/environment/wall_metal.png")
const FLOOR_LAB_TEXTURE: Texture2D = preload("res://assets/sprites/laboratory/floor_lab.png")
const WALL_LAB_TEXTURE: Texture2D = preload("res://assets/sprites/laboratory/wall_lab.png")
const CHAMBER_TEXTURE: Texture2D = preload("res://assets/sprites/laboratory/chamber_lab.png")
const CONSOLE_SCENE: PackedScene = preload("res://scenes/levels/rooms/laboratory/console_laboratory.tscn")
const POWER_PANEL_SCENE: PackedScene = preload("res://scenes/levels/rooms/laboratory/power_panel_laboratory.tscn")
const SIGNAL_ANALYZER_SCENE: PackedScene = preload("res://scenes/levels/rooms/laboratory/signal_analyzer_laboratory.tscn")
const RESEARCH_VAULT_SCENE: PackedScene = preload("res://scenes/levels/rooms/laboratory/research_vault_laboratory.tscn")

## MAP (main.gd, verbatim): '#' wall | 'W' lab floor | '.' station
## floor | 'b' blue trim | 'p' purple strip | ' ' void. One cell
## is 32 px = 2x2 logical tiles.
const MAP := [
	"############        ",
	"#WWWWWWWWWW#        ",
	"#WWWWWWWWWW#        ",
	"#WWWWWWWWWW#        ",
	"#WWWWWWWWWW#        ",
	"#bbbbbbbbbb#        ",
	"#..........#########",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#bbbbbbbbbbbbbbbbbb#",
	"#pppppppppppppppppp#",
	"####################",
]

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
## Layout rebased on the user's main.gd reference 2026-11-28: the
## room is the reference's L-shaped lab, 640x576, spawn (208, 336).

func _ready() -> void:
	room_key = "laboratory"
	area_name = "آزمایشگاه تحقیقاتی"
	room_rect = Rect2(0, 0, 640, 576)
	room_tile_rect = Rect2i(0, 0, 40, 36)
	area_hint = "آزمایشگاه ORION — نمونه‌ی ناشناخته؛ اول گزارش تحقیقاتی را بخوان"
	spawn_point = Vector2(208, 336)
	tint_color = Color(0.4, 0.6, 1.0, 0.07)
	_build_floor_if_standalone()
	_build_wall_rects(wall_rects())
	_build_tint()
	_build_zone()
	_build_lighting_if_standalone()
	# Decor props (main.gd PROPS): flat-colour rects. Solid ones
	# block movement; visual-only ones sit under a device or console
	# (see _add_flat_prop: a solid body under an interactable would
	# block every line-of-sight ray to it).
	_build_decor_props()
	# Research section: the log, the wave monitor and the experiment
	# notes — the first clue and the vault code — on the MAP's consoles.
	_add_named_console(Vector2(48, 48), RESEARCH_LOG_TEXT, "ResearchLogConsole", "گزارش")
	_add_named_console(Vector2(64, 112), NOTE_07_TEXT, "Note07", "یادداشت ۰۷")
	_add_named_console(Vector2(304, 80), WAVE_MONITOR_TEXT, "WaveMonitor", "موج")
	_add_named_console(Vector2(400, 272), NOTE_01_TEXT, "Note01", "یادداشت ۰۱")
	_add_named_console(Vector2(480, 464), NOTE_03_TEXT, "Note03", "یادداشت ۰۳")
	# Sample section: the containment chamber on pod_right, its power
	# panel on the generator. Analysis: the signal analyzer on the
	# terminal. Security: the research vault on the supply shelf.
	_build_sample_chamber()
	var power_panel: StaticBody2D = POWER_PANEL_SCENE.instantiate()
	power_panel.name = "PowerPanel"
	power_panel.position = Vector2(48, 336)
	add_child(power_panel)
	var analyzer: StaticBody2D = SIGNAL_ANALYZER_SCENE.instantiate()
	analyzer.name = "SignalAnalyzer"
	analyzer.position = Vector2(528, 272)
	add_child(analyzer)
	var vault: StaticBody2D = RESEARCH_VAULT_SCENE.instantiate()
	vault.name = "ResearchVault"
	vault.position = Vector2(80, 464)
	add_child(vault)
	# Chained puzzles: power → signal → vault. Each puzzle unlocks
	# the next one; the wiring counts all three as solved.
	power_panel.solved.connect(analyzer.unlock)
	analyzer.solved.connect(vault.unlock)


## The MAP's '#' cells merged into wall rects (32 px cells; adjacent
## cells share one rect, not one body per cell). Two gaps are the
## declared exits: north x 288-320 (to command_center) and east
## y 336-368 (the reference's east doorway; see exits() for why the
## declared east exit rect still sits at y 160-192).
func wall_rects() -> Array[Rect2]:
	return [
		Rect2(0, 0, 32, 576),
		Rect2(32, 0, 256, 32), Rect2(320, 0, 64, 32),
		Rect2(352, 32, 32, 160),
		Rect2(352, 192, 288, 32),
		Rect2(608, 224, 32, 112), Rect2(608, 368, 32, 208),
		Rect2(32, 544, 576, 32),
	]


func blocked_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = wall_rects()
	rects.append_array(prop_solid_rects())
	return rects


## Solid decor only (main.gd PROPS with no device on them). Puzzle
## devices and consoles are NOT in here: the devices carry their own
## bodies, and a console has none — the old pattern (only walls +
## crate-like props feed the grid).
func prop_solid_rects() -> Array[Rect2]:
	return [
		Rect2(32, 224, 32, 32), Rect2(320, 224, 32, 32),
		Rect2(32, 256, 32, 32), Rect2(32, 384, 32, 32),
		Rect2(256, 448, 64, 32),
	]


## main.gd's two patrol routes (pixels): robot 1 runs the y=304
## line, robot 2 the y=400 line. Both lines are clear of every wall,
## solid prop and device body (verified by a clearance script
## 2026-11-28: swept 12x14 bodies hit nothing).
func patrol_routes_local() -> Array:
	return [
		[Vector2(144, 304), Vector2(496, 304)],
		[Vector2(464, 400), Vector2(176, 400)],
	]


## First route (back-compat: the old single-loop contract and the
## wiring fallback). The wiring assigns one route per robot.
func patrol_points_local() -> Array[Vector2]:
	return [Vector2(144, 304), Vector2(496, 304)]


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
## BEFORE add_child. Standalone it is still the station offset, for
## the tests that compare the standalone grid with the assembled one.
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

## Doorway gaps the standalone launcher seals with walls. The two
## declared exits must be in here (the room test asserts every exit
## rect is one of the gaps), plus the REAL east gap in the new wall
## (y 336-368): the declared east exit rect (624, 160) still pairs
## with engine_room's west exit in world coordinates, but in the new
## MAP that rect floats in the void east of the lab block — the wall
## gap that actually opens the room is at y 336-368. The launcher
## seals all three; the void seal is unreachable and harmless.
func doorway_gap_rects() -> Array[Rect2]:
	return [
		Rect2(288, -16, 32, 16),
		Rect2(624, 160, 16, 32),
		Rect2(608, 336, 32, 32),
	]

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

## Standalone only: one smooth floor sprite for the whole room
## (640x576, painted from the MAP — no tile grid). The assembled
## level keeps the shared TileMap floor; this room builds nothing
## there.
func _build_floor_if_standalone() -> void:
	if not standalone:
		return
	var floor_sprite := Sprite2D.new()
	floor_sprite.name = "Floor"
	floor_sprite.texture = FLOOR_LAB_TEXTURE
	floor_sprite.position = room_rect.get_center()
	add_child(floor_sprite)
	# Bottom of the draw order: the room's .tscn children (the two
	# patrol robots) already exist when _ready runs, and an opaque
	# floor added after them paints over them — the robots were
	# invisible in standalone play (measured 2026-11-28: no robot
	# in any screenshot; the old TileMap floor had the same
	# defect). Everything else _ready adds draws over the floor.
	move_child(floor_sprite, 0)

## Standalone only: main.gd's dim ambient + three ceiling lights.
## Gated on standalone on purpose: the room is flattened into the
## assembled level, and a CanvasModulate there would darken the
## whole station (the assembled level keeps its own bright light).
func _build_lighting_if_standalone() -> void:
	if not standalone:
		return
	var mod := CanvasModulate.new()
	mod.name = "AmbientDim"
	mod.color = Color(0.28, 0.30, 0.42)
	add_child(mod)
	_add_ceiling_light(Vector2(160, 80), Color(1, 1, 0.9), 0.7, 2.2)
	_add_ceiling_light(Vector2(192, 288), Color(0.6, 0.8, 1.0), 0.7, 2.2)
	_add_ceiling_light(Vector2(480, 352), Color(0.6, 0.8, 1.0), 0.7, 2.2)


func _add_ceiling_light(pos: Vector2, color: Color, energy: float, tex_scale: float) -> void:
	var light := _make_light(color, energy, tex_scale)
	light.position = pos
	add_child(light)


## Radial light texture (main.gd's _make_light, verbatim).
func _make_light(color: Color, energy: float, tex_scale: float) -> PointLight2D:
	var grad := Gradient.new()
	grad.set_color(0, Color.WHITE)
	grad.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	var light := PointLight2D.new()
	light.texture = tex
	light.color = color
	light.energy = energy
	light.texture_scale = tex_scale
	return light

## main.gd PROPS as flat-colour rects: [rect, colour, solid?, name].
## Solid ones (pods, machines, vending) block movement and feed the
## nav grid. Visual-only ones sit under a device or a console: a
## solid body under an interactable blocks every line-of-sight ray
## to it — the vault dials behind a solid shelf, or a console on a
## solid bed, are unreachable from all four sides (the raycast the
## player uses excludes only the target's own assembly, not the
## decor under it). The device's own body is the obstacle there.
func _build_decor_props() -> void:
	var props: Array = [
		[Rect2(32, 32, 32, 32), Color("dfe6ea"), false, "Computer"],
		[Rect2(32, 96, 64, 32), Color("f0f0f0"), false, "MedBed"],
		[Rect2(288, 32, 32, 96), Color("6f8fd8"), false, "SurgeryArm"],
		[Rect2(32, 224, 32, 32), Color("1a1c22"), true, "PodLeft"],
		[Rect2(320, 224, 32, 32), Color("1a1c22"), true, "PodRight"],
		[Rect2(32, 256, 32, 32), Color("3a63b8"), true, "MachineA"],
		[Rect2(32, 320, 32, 32), Color("7a6a5a"), false, "Generator"],
		[Rect2(32, 384, 32, 32), Color("3a63b8"), true, "MachineB"],
		[Rect2(352, 256, 96, 32), Color("9aa0a6"), false, "Counter"],
		[Rect2(512, 256, 32, 32), Color("2e7d32"), false, "Terminal"],
		[Rect2(32, 448, 96, 32), Color("c0392b"), false, "SupplyShelf"],
		[Rect2(256, 448, 64, 32), Color("2c5ec9"), true, "Vending"],
		[Rect2(416, 448, 128, 32), Color("b0b6bd"), false, "ConsoleRow"],
	]
	for p in props:
		_add_flat_prop(p[0], p[1], p[2], p[3])


func _add_flat_prop(rect: Rect2, color: Color, solid: bool, prop_name: String = "") -> void:
	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([
		rect.position, rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size, rect.position + Vector2(0, rect.size.y)])
	vis.color = color
	if not solid:
		add_child(vis)
		return
	var body := StaticBody2D.new()
	if prop_name != "":
		body.name = prop_name
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	shape.position = rect.get_center()
	body.add_child(shape)
	body.add_child(vis)
	add_child(body)

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


## The sample containment chamber (ORION, on pod_right): hazard
## frame + glowing glass sprite, cyan sample glow. Solid (the
## player walks around it) but deliberately NOT in
## prop_solid_rects: it sits inside the patrol area, never on a
## robot route, and the nav grid must keep agreeing with the
## assembled level cell for cell.
func _build_sample_chamber() -> void:
	var chamber := StaticBody2D.new()
	chamber.name = "SampleChamber"
	chamber.position = Vector2(336, 240)
	chamber.collision_layer = 1
	chamber.collision_mask = 0
	var frame := Sprite2D.new()
	frame.name = "ChamberSprite"
	frame.texture = CHAMBER_TEXTURE
	chamber.add_child(frame)
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
	return WALL_LAB_TEXTURE
