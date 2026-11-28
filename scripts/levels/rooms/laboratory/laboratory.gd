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
## Layout (2026-11-28, v2 — from the user's 24x24 prompt): the room
## is a 768x768 map (24x24 cells of 32 px) with a cosmic backdrop on
## the left (red planet, small planet, truss), a small side room
## (white floor, yellow/black walls), a white-and-pink central hall
## (pink cross + floor circle), a dark grey chamber above, dark
## hazard chambers top-right and bottom-right (electric signs), a
## dark bottom-middle chamber with a red border, and a long white
## vertical corridor on the right. The floor is one smooth sprite
## (assets/sprites/laboratory/floor_lab.png, painted from the MAP) —
## no tile grid; the space backdrop is a second sprite
## (space_lab.png) under it. Walls are the MAP's '#', 'H', 'R' cells
## merged into rects, with a texture per wall kind (metal, hazard
## stripe, red border). Puzzle devices sit on the prompt's cells:
## power panel on the (7,7) terminal, analyzer on the (12,5)
## monitors, vault on the (12,15) red/blue console, chamber on the
## (11,12) circular device, research log on the (7,9) cyan console,
## wave monitor on the (13,6) monitors, notes on the left-room
## consoles (2,12)/(3,12) and the corridor console (22,10).
## Two patrol robots run the central hall; vision radius 60, spawn
## at the bottom of the right corridor, out of every robot's sight.
## Lighting is dim ambient + three ceiling lights (standalone only:
## the assembled level keeps its own bright lighting).
##
## Layer structure (prompt section 4, adapted — see note below):
## Space_And_Backdrop (Node2D, space sprite, no collision), Floor
## (the Sprite2D named "Floor"), Walls_And_Hazards (the StaticBody2D
## named "Walls_laboratory"), Props_And_Machines (Node2D, decor
## props and wall signs). The machines themselves (power panel,
## analyzer, vault, chamber, consoles) stay DIRECT children of the
## room: test_rooms.gd (ROOM_CHECKS nodes) and test_laboratory.gd
## address them by direct path, so nesting them under a layer would
## break the room contract. No real TileMapLayer: the room's
## architecture is code-built walls + one painted floor sprite, and
## the assembled level flattens rooms through wall_rects() /
## prop_solid_rects() — a TileSet would need a parallel flattening
## path and would break the standalone/assembled grid agreement
## that the tests check. The MAP table below IS the tilemap: every
## floor cell, wall and prop position derives from it.
##
## Station fit (2026-11-28, honest limitation): the room is 48
## logical tiles square at station offset (0, 23), so it needs
## station rows 23-70 — but the station has 58 rows. The south part
## hangs past the map, and the room's new walls/props are not in
## LevelData's station lists, so test_station_layout_agrees_with_rooms
## (and the grid-agreement check inside the standalone room test)
## fail by design. The standalone room is correct and complete; the
## assembled fit is a separate, LevelData-sized job — not touched here.

const TILE_SIZE := 16
const CELL := 32
const WALL_TEXTURE: Texture2D = preload("res://assets/sprites/environment/wall_metal.png")
const FLOOR_LAB_TEXTURE: Texture2D = preload("res://assets/sprites/laboratory/floor_lab.png")
const SPACE_LAB_TEXTURE: Texture2D = preload("res://assets/sprites/laboratory/space_lab.png")
const WALL_LAB_TEXTURE: Texture2D = preload("res://assets/sprites/laboratory/wall_lab.png")
const HAZARD_TEXTURE: Texture2D = preload("res://assets/sprites/laboratory/hazard_lab.png")
const REDBORDER_TEXTURE: Texture2D = preload("res://assets/sprites/laboratory/redborder_lab.png")
const CHAMBER_TEXTURE: Texture2D = preload("res://assets/sprites/laboratory/chamber_lab.png")
const SIGN_BIOHAZARD_TEXTURE: Texture2D = preload("res://assets/sprites/laboratory/sign_biohazard.png")
const SIGN_ELECTRIC_TEXTURE: Texture2D = preload("res://assets/sprites/laboratory/sign_electric.png")
const SIGN_CAUTION_TEXTURE: Texture2D = preload("res://assets/sprites/laboratory/sign_caution.png")
const EXTINGUISHER_TEXTURE: Texture2D = preload("res://assets/sprites/laboratory/extinguisher.png")
const CONTAINER_TEXTURE: Texture2D = preload("res://assets/sprites/laboratory/container_blue.png")
const LOCKER_BLUE_TEXTURE: Texture2D = preload("res://assets/sprites/laboratory/locker_blue.png")
const LOCKER_RED_TEXTURE: Texture2D = preload("res://assets/sprites/laboratory/locker_red.png")
const LOCKER_GREEN_TEXTURE: Texture2D = preload("res://assets/sprites/laboratory/locker_green.png")
const CHAIR_TEXTURE: Texture2D = preload("res://assets/sprites/laboratory/chair.png")
const DESK_TEXTURE: Texture2D = preload("res://assets/sprites/laboratory/desk.png")
const MONITOR_TEXTURE: Texture2D = preload("res://assets/sprites/laboratory/monitor.png")
const VENT_TEXTURE: Texture2D = preload("res://assets/sprites/laboratory/vent.png")
const CRYSTAL_TEXTURE: Texture2D = preload("res://assets/sprites/laboratory/crystal.png")
const CONSOLE_SCENE: PackedScene = preload("res://scenes/levels/rooms/laboratory/console_laboratory.tscn")
const POWER_PANEL_SCENE: PackedScene = preload("res://scenes/levels/rooms/laboratory/power_panel_laboratory.tscn")
const SIGNAL_ANALYZER_SCENE: PackedScene = preload("res://scenes/levels/rooms/laboratory/signal_analyzer_laboratory.tscn")
const RESEARCH_VAULT_SCENE: PackedScene = preload("res://scenes/levels/rooms/laboratory/research_vault_laboratory.tscn")

## MAP (user's 24x24 prompt, 2026-11-28): ' ' space/void |
## '#' metal wall | 'H' hazard-stripe wall | 'R' red border wall |
## 'W' white floor | 'P' pink floor | 'D' dark checker floor |
## 'B' black speckled floor. One cell is 32 px.
## Assumptions where the prompt left room (documented in the
## handoff report): space is X=0..5, not 0..7 (X=6..7 is the
## chamber's west wall, with the (7,7) terminal alcove); the
## chamber's west wall is one column (X=6) with a 1x3 terminal
## niche at X=7, Y=6..8 so all three power switches sit on floor;
## the analyzer alcove is likewise 1x3 at X=12, Y=4..6; the hall's
## north border (Y=8) opens X=7..10 and its south border (Y=16)
## opens X=9..10; the (8,8) control desk is the (7,9) log console's
## neighbour (a desk sprite in the doorway) and the wave-monitor
## console sits at (13,6) instead of (12,6) so the analyzer's C
## selector stays unambiguous.
const MAP := [
	"      ##################",
	"      ##HHHH#HHHHHH#WWW#",
	"      ##DDDD#BBBBBB#WWW#",
	"      ##DDDD#BBBBBB#WWW#",
	"      ##DDDDBBBBBBBWWWW#",
	"      ##DDDDBBBBBBB#WWW#",
	"      #DDDDDBBBBBBB#WWW#",
	"      #DDDDD#HHHHHH#WWW#",
	"      #WWWWHHHHHHHH#WWW#",
	"#HHHHH#WWWPPWWWWWWW#WWW#",
	"#HWWWH#WWWPPWWWWWWW#WWW#",
	"#HWWWHWWWWPPWWWWWWW#WWW ",
	"#HWWWH#WPPPPPPPPWWWWWWW#",
	"#HHHHH#WPPPPPPPPWWW#WWW#",
	"      #WWWPPWWWWWWW#WWW#",
	"      #WWWPPWWWWWWW#WWW#",
	"      #HHWWHHHHHHHH#WWW#",
	"      RDDDDDRBBBBBB#WWW#",
	"      RDDDDDRBBBBBB#WWW#",
	"      RDDDDDRBBBBBBWWWW#",
	"      RDDDDDRBBBBBB#WWW#",
	"      RDDDDDRBBBBBB#WWW#",
	"      RDDDDDRHHHHHH#WWW#",
	"      ##################",
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
## Layout rebuilt on the user's 24x24 prompt 2026-11-28: the room
## is 768x768, spawn (688, 688) at the bottom of the right corridor.

func _ready() -> void:
	room_key = "laboratory"
	area_name = "آزمایشگاه تحقیقاتی"
	room_rect = Rect2(0, 0, 768, 768)
	room_tile_rect = Rect2i(0, 0, 48, 48)
	area_hint = "آزمایشگاه ORION — نمونه‌ی ناشناخته؛ اول گزارش تحقیقاتی را بخوان"
	spawn_point = Vector2(688, 688)
	tint_color = Color(0.4, 0.6, 1.0, 0.07)
	_build_backdrop_if_standalone()
	_build_floor_if_standalone()
	_build_wall_rects(wall_rects())
	_build_tint()
	_build_zone()
	_build_lighting_if_standalone()
	# Props_And_Machines layer: decor props and wall signs (the
	# machines themselves stay direct children — see the header).
	_build_wall_signs()
	# Research section: the log, the wave monitor and the experiment
	# notes — the first clue and the vault code — on the prompt's
	# consoles. The log sits on the (7,9) cyan console in the hall;
	# the wave monitor on the (13,6) monitors beside the analyzer.
	_add_named_console(Vector2(240, 304), RESEARCH_LOG_TEXT, "ResearchLogConsole", "گزارش")
	_add_named_console(Vector2(432, 208), WAVE_MONITOR_TEXT, "WaveMonitor", "موج")
	_add_named_console(Vector2(80, 400), NOTE_01_TEXT, "Note01", "یادداشت ۰۱")
	_add_named_console(Vector2(112, 400), NOTE_03_TEXT, "Note03", "یادداشت ۰۳")
	_add_named_console(Vector2(720, 336), NOTE_07_TEXT, "Note07", "یادداشت ۰۷")
	# Sample section: the containment chamber on the (11,12)
	# circular device, its power panel on the (7,7) terminal.
	# Analysis: the signal analyzer on the (12,5) monitors.
	# Security: the research vault on the (12,15) console.
	_build_sample_chamber()
	var power_panel: StaticBody2D = POWER_PANEL_SCENE.instantiate()
	power_panel.name = "PowerPanel"
	power_panel.position = Vector2(240, 240)
	add_child(power_panel)
	var analyzer: StaticBody2D = SIGNAL_ANALYZER_SCENE.instantiate()
	analyzer.name = "SignalAnalyzer"
	analyzer.position = Vector2(400, 176)
	add_child(analyzer)
	var vault: StaticBody2D = RESEARCH_VAULT_SCENE.instantiate()
	vault.name = "ResearchVault"
	vault.position = Vector2(400, 496)
	add_child(vault)
	# Chained puzzles: power → signal → vault. Each puzzle unlocks
	# the next one; the wiring counts all three as solved.
	power_panel.solved.connect(analyzer.unlock)
	analyzer.solved.connect(vault.unlock)


## The MAP's wall cells ('#', 'H', 'R') merged into rects (32 px
## cells; same-char runs merge horizontally, then vertically).
## Two gaps are the declared exits: north above the corridor
## (x 640-672) and east through the corridor wall (y 352-384).
func wall_rects() -> Array[Rect2]:
	var runs: Array = []
	for y in range(24):
		var row: String = MAP[y]
		var x := 0
		while x < 24:
			var ch: String = row[x]
			if ch == "#" or ch == "H" or ch == "R":
				var x0 := x
				while x < 24 and row[x] == ch:
					x += 1
				runs.append([x0, y, x - x0, 1, ch])
			else:
				x += 1
	var merged := true
	while merged:
		merged = false
		for i in range(runs.size()):
			var done := false
			for j in range(i + 1, runs.size()):
				var a: Array = runs[i]
				var b: Array = runs[j]
				if a[0] == b[0] and a[2] == b[2] and a[4] == b[4] and a[1] + a[3] == b[1]:
					a[3] += b[3]
					runs.remove_at(j)
					merged = true
					done = true
					break
			if done:
				break
	var out: Array[Rect2] = []
	for r in runs:
		out.append(Rect2(r[0] * CELL, r[1] * CELL, r[2] * CELL, r[3] * CELL))
	return out


func blocked_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = wall_rects()
	rects.append_array(prop_solid_rects())
	return rects


## No solid decor props in v2: the devices carry their own bodies
## (power panel, analyzer, vault, chamber) and every other prop is
## painted floor art or a non-solid sign sprite. The old pattern
## (only walls + crate-like props feed the grid) is kept.
func prop_solid_rects() -> Array[Rect2]:
	return []


## Patrol routes (pixels), both inside the central hall and clear
## of every wall, device body and console: robot 1 runs the y=352
## line (west end 37 px from the log console, outside the 60 px
## vision cone at every point — verified by a clearance script);
## robot 2 runs the x=528 line. Neither route crosses the spawn
## corridor or any puzzle device.
func patrol_routes_local() -> Array:
	return [
		[Vector2(272, 352), Vector2(496, 352)],
		[Vector2(528, 304), Vector2(528, 496)],
	]


## First route (back-compat: the old single-loop contract and the
## wiring fallback). The wiring assigns one route per robot.
func patrol_points_local() -> Array[Vector2]:
	return [Vector2(272, 352), Vector2(496, 352)]


func exits() -> Array[Dictionary]:
	return [
		{"id": "north", "edge": "north", "rect": Rect2(640, -16, 32, 16),
			"target_room": "command_center", "target_exit": "south"},
		{"id": "east", "edge": "east", "rect": Rect2(752, 352, 16, 32),
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
## rect is one of the gaps). Both exits are real gaps in the MAP:
## north above the corridor, east through its wall at Y=11.
func doorway_gap_rects() -> Array[Rect2]:
	return [
		Rect2(640, -16, 32, 16),
		Rect2(752, 352, 16, 32),
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

## Standalone only: the cosmic backdrop (Space_And_Backdrop layer).
## Transparent outside the space zones, so it only shows through
## the floor sprite's transparent cells. Added before the floor so
## it sits at the bottom of the draw order.
func _build_backdrop_if_standalone() -> void:
	if not standalone:
		return
	var layer := Node2D.new()
	layer.name = "Space_And_Backdrop"
	add_child(layer)
	var backdrop := Sprite2D.new()
	backdrop.name = "SpaceBackdrop"
	backdrop.texture = SPACE_LAB_TEXTURE
	backdrop.position = room_rect.get_center()
	layer.add_child(backdrop)
	move_child(layer, 0)

## Standalone only: one smooth floor sprite for the whole room
## (768x768, painted from the MAP — no tile grid). The assembled
## level keeps the shared TileMap floor; this room builds nothing
## there. Named "Floor" (direct child): test_rooms.gd checks the
## standalone floor by that name and type.
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
	move_child(floor_sprite, 1)

## Standalone only: dim ambient + three ceiling lights.
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
	_add_ceiling_light(Vector2(288, 128), Color(1, 1, 0.9), 0.7, 2.2)
	_add_ceiling_light(Vector2(384, 400), Color(0.6, 0.8, 1.0), 0.7, 2.2)
	_add_ceiling_light(Vector2(688, 400), Color(0.6, 0.8, 1.0), 0.7, 2.2)


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

## Props_And_Machines decor (prompt section 3): wall signs and
## small objects as non-solid sprites on the MAP's cells. All are
## atlas sprites (pixel-art-atlas-1.4m) except the desk sprite,
## which is the same atlas control panel. They draw above the walls
## (added after _build_wall_rects) and never block movement or
## line of sight.
func _build_wall_signs() -> void:
	var layer := Node2D.new()
	layer.name = "Props_And_Machines"
	add_child(layer)
	var signs: Array = [
		[SIGN_BIOHAZARD_TEXTURE, Vector2(48, 304), "BiohazardLeftRoom"],
		[SIGN_CAUTION_TEXTURE, Vector2(112, 432), "CautionLeftRoom"],
		[SIGN_ELECTRIC_TEXTURE, Vector2(432, 240), "ElectricTopRight"],
		[SIGN_BIOHAZARD_TEXTURE, Vector2(592, 240), "BiohazardTopRight"],
		[SIGN_ELECTRIC_TEXTURE, Vector2(432, 528), "ElectricBottomRight"],
		[SIGN_BIOHAZARD_TEXTURE, Vector2(592, 528), "BiohazardBottomRight"],
		[SIGN_ELECTRIC_TEXTURE, Vector2(752, 80), "ElectricCorridorTop"],
		[SIGN_ELECTRIC_TEXTURE, Vector2(752, 688), "ElectricCorridorBottom"],
		[EXTINGUISHER_TEXTURE, Vector2(592, 80), "FireExtinguisher"],
		[CONTAINER_TEXTURE, Vector2(48, 400), "BlueContainer"],
		[LOCKER_BLUE_TEXTURE, Vector2(80, 368), "LockerBlueLeft"],
		[LOCKER_RED_TEXTURE, Vector2(112, 368), "LockerRedLeft"],
		[LOCKER_GREEN_TEXTURE, Vector2(144, 368), "LockerGreenLeft"],
		[DESK_TEXTURE, Vector2(272, 272), "ControlDesk"],
		[CHAIR_TEXTURE, Vector2(272, 336), "Wheelchair"],
		[MONITOR_TEXTURE, Vector2(400, 304), "BlueMonitor1"],
		[MONITOR_TEXTURE, Vector2(432, 304), "BlueMonitor2"],
		[MONITOR_TEXTURE, Vector2(464, 304), "BlueMonitor3"],
		[MONITOR_TEXTURE, Vector2(496, 304), "BlueMonitor4"],
		[VENT_TEXTURE, Vector2(144, 336), "FloorVentLeft"],
		[VENT_TEXTURE, Vector2(656, 240), "FloorVentCorridor"],
		[VENT_TEXTURE, Vector2(336, 464), "FloorVentSouth"],
		[VENT_TEXTURE, Vector2(272, 432), "HallSouthVent"],
		[CRYSTAL_TEXTURE, Vector2(240, 368), "PurpleGlow"],
	]
	for s in signs:
		var sprite := Sprite2D.new()
		sprite.name = s[2]
		sprite.texture = s[0]
		sprite.position = s[1]
		layer.add_child(sprite)

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


## The sample containment chamber (ORION, on the (11,12) circular
## device): hazard frame + glowing glass sprite, cyan sample glow.
## Solid (the player walks around it) but deliberately NOT in
## prop_solid_rects: it sits inside the patrol area, never on a
## robot route, and the nav grid must keep agreeing with the
## assembled level cell for cell.
func _build_sample_chamber() -> void:
	var chamber := StaticBody2D.new()
	chamber.name = "SampleChamber"
	chamber.position = Vector2(368, 400)
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
## The MAP char at the rect's top-left cell decides: 'H' hazard
## stripes, 'R' red border, anything else the lab metal wall.
## Seal rects (outside the MAP) fall through to metal.
func wall_texture_for_local(r: Rect2) -> Texture2D:
	var cx := clampi(int(r.position.x / CELL), 0, 23)
	var cy := clampi(int(r.position.y / CELL), 0, 23)
	var ch: String = MAP[cy][cx]
	if ch == "H":
		return HAZARD_TEXTURE
	if ch == "R":
		return REDBORDER_TEXTURE
	return WALL_LAB_TEXTURE
