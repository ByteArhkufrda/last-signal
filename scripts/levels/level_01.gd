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

const TILE_SIZE := 16
const ROOM_COLS := 80
const ROOM_ROWS := 58
const FLOOR_TEXTURE_PATH := "res://assets/sprites/environment/floor_atlas.png"
const FLOOR_VARIANT_CHANCE := 0.15
const FLOOR_RNG_SEED := 17
const CONSOLE_SCENE: PackedScene = preload("res://scenes/interaction/console.tscn")
const CRATE_TEXTURE: Texture2D = preload("res://assets/sprites/props/crate.png")
const DISH_TEXTURE: Texture2D = preload("res://assets/sprites/props/tower_1_satellite.png")
const PANEL_TEXTURE: Texture2D = preload("res://assets/sprites/props/control_panel.png")
const FUSEBOX_TEXTURE: Texture2D = preload("res://assets/sprites/props/fuse_box_prop.png")
const RIVET_TEXTURE: Texture2D = preload("res://assets/sprites/props/riveted_panel.png")
## Medical Wing pack (2026-11-15): 83 sprites from the pixel-art atlas
## (CC0) + hand-drawn tiles, copied to res://assets/sprites/medical-wing/.
## Only the Medical Wing uses them; the other areas keep the old look.
## Floor atlas order (12 tiles, 16 px each): standard, alt, cracked,
## broken, water stain, chemical stain, footprints, wheel tracks, debris,
## hatch, grille, panel. Weights are cumulative thresholds on one
## randf() roll per cell — the same single roll the old floor used, so
## the Central floor pattern (and its test) is unchanged.
const MED_FLOOR_TEXTURE_PATH := "res://assets/sprites/environment/floor_medical_atlas.png"
const MED_FLOOR_WEIGHTS := [0.70, 0.78, 0.84, 0.85, 0.87, 0.89, 0.92, 0.94, 0.97, 0.98, 0.99, 1.0]
const MED_RECT_TILES := Rect2i(40, 0, 40, 23)
const MED_WALL_H_TEXTURE: Texture2D = preload("res://assets/sprites/medical-wing/wall_h.png")
const MED_WALL_V_TEXTURE: Texture2D = preload("res://assets/sprites/medical-wing/wall_v.png")
## Medical Wing prop textures, loaded on demand by _med_texture().
## Keys are the pack sprite keys (see assets/sprites/medical-wing/).
const MED_PROP_PATHS := {
	"bed_standard": "res://assets/sprites/medical-wing/bed_standard.png",
	"bed_empty": "res://assets/sprites/medical-wing/bed_empty.png",
	"bed_disorganized": "res://assets/sprites/medical-wing/bed_disorganized.png",
	"bedside_table": "res://assets/sprites/medical-wing/bedside_table.png",
	"exam_bed": "res://assets/sprites/medical-wing/exam_bed.png",
	"stretcher": "res://assets/sprites/medical-wing/stretcher.png",
	"desk_doctor": "res://assets/sprites/medical-wing/desk_doctor.png",
	"cabinet_storage": "res://assets/sprites/medical-wing/cabinet_storage.png",
	"cabinet_medicine": "res://assets/sprites/medical-wing/cabinet_medicine.png",
	"cabinet_open": "res://assets/sprites/medical-wing/cabinet_open.png",
	"cabinet_closed": "res://assets/sprites/medical-wing/cabinet_closed.png",
	"cabinet_worn": "res://assets/sprites/medical-wing/cabinet_worn.png",
	"shelf_medicine": "res://assets/sprites/medical-wing/shelf_medicine.png",
	"monitor_vitals": "res://assets/sprites/medical-wing/monitor_vitals.png",
	"monitor_heart": "res://assets/sprites/medical-wing/monitor_heart.png",
	"oxygen_cylinder": "res://assets/sprites/medical-wing/oxygen_cylinder.png",
	"oxygen_unit": "res://assets/sprites/medical-wing/oxygen_unit.png",
	"iv_stand": "res://assets/sprites/medical-wing/iv_stand.png",
	"infusion_pump": "res://assets/sprites/medical-wing/infusion_pump.png",
	"exam_lamp": "res://assets/sprites/medical-wing/exam_lamp.png",
	"defibrillator": "res://assets/sprites/medical-wing/defibrillator.png",
	"waste_bin": "res://assets/sprites/medical-wing/waste_bin.png",
	"trolley": "res://assets/sprites/medical-wing/trolley.png",
	"cart_emergency": "res://assets/sprites/medical-wing/cart_emergency.png",
	"chair_rolling": "res://assets/sprites/medical-wing/chair_rolling.png",
	"chair_office": "res://assets/sprites/medical-wing/chair_office.png",
	"side_table": "res://assets/sprites/medical-wing/side_table.png",
	"supply_boxes": "res://assets/sprites/medical-wing/supply_boxes.png",
	"clock_wall": "res://assets/sprites/medical-wing/clock_wall.png",
	"wall_access_panel": "res://assets/sprites/medical-wing/wall_access_panel.png",
	"window_small": "res://assets/sprites/medical-wing/window_small.png",
	"window_observation": "res://assets/sprites/medical-wing/window_observation.png",
	"wall_cabinet_section": "res://assets/sprites/medical-wing/wall_cabinet_section.png",
	"wall_corner_inner": "res://assets/sprites/medical-wing/wall_corner_inner.png",
	"wall_corner_outer": "res://assets/sprites/medical-wing/wall_corner_outer.png",
	"grille_vent": "res://assets/sprites/medical-wing/grille_vent.png",
	"panel_wall_small": "res://assets/sprites/medical-wing/panel_wall_small.png",
	"sign_warning": "res://assets/sprites/medical-wing/sign_warning.png",
	"fusebox_closed": "res://assets/sprites/medical-wing/fusebox_closed.png",
	"indicator_emergency": "res://assets/sprites/medical-wing/indicator_emergency.png",
	"light_ceiling": "res://assets/sprites/medical-wing/light_ceiling.png",
	"light_green": "res://assets/sprites/medical-wing/light_green.png",
	"light_red": "res://assets/sprites/medical-wing/light_red.png",
	"light_blue": "res://assets/sprites/medical-wing/light_blue.png",
	"light_flicker": "res://assets/sprites/medical-wing/light_flicker.png",
	"light_damaged": "res://assets/sprites/medical-wing/light_damaged.png",
	"documents": "res://assets/sprites/medical-wing/documents.png",
	"bottles_medicine": "res://assets/sprites/medical-wing/bottles_medicine.png",
	"packages_medicine": "res://assets/sprites/medical-wing/packages_medicine.png",
	"gloves": "res://assets/sprites/medical-wing/gloves.png",
	"bandages": "res://assets/sprites/medical-wing/bandages.png",
	"syringes": "res://assets/sprites/medical-wing/syringes.png",
	"tray_instruments": "res://assets/sprites/medical-wing/tray_instruments.png",
	"paper_scattered": "res://assets/sprites/medical-wing/paper_scattered.png",
	"chair_fallen": "res://assets/sprites/medical-wing/chair_fallen.png",
	"dust": "res://assets/sprites/medical-wing/dust.png",
	"steam": "res://assets/sprites/medical-wing/steam.png",
	"spark": "res://assets/sprites/medical-wing/spark.png",
	"flashlight": "res://assets/sprites/medical-wing/flashlight.png",
	"note_doctor": "res://assets/sprites/medical-wing/note_doctor.png",
}
const FX_RING_SCENE: PackedScene = preload("res://scenes/effects/fx_ring.tscn")
## Real wall art (v1.2): a 16x16 seamless metal panel tile drawn for this
## project (assets/sprites/environment/wall_metal.png) — the atlas has no
## sci-fi wall segment, so the walls were flat dark rectangles until now.
const WALL_TEXTURE: Texture2D = preload("res://assets/sprites/environment/wall_metal.png")
const SPAWN := Vector2(320, 184)
const PATROL_POINTS: Array[Vector2] = [
	Vector2(200, 120), Vector2(440, 120), Vector2(440, 280), Vector2(200, 280)
]
## One patrol rectangle per area with a security robot (Persian update
## 2026-11-12: one robot per area). Each rectangle stays inside its
## area and clear of consoles and solid props. Scanners never use
## these — they stay at their post (see _wire_interactables).
const PATROL_RECTS := {
	"کنترل مرکزی": [Vector2(200, 120), Vector2(440, 120), Vector2(440, 280), Vector2(200, 280)],
	"آزمایشگاه تحقیقاتی": [Vector2(160, 480), Vector2(520, 480), Vector2(520, 640), Vector2(160, 640)],
	"محوطه‌ی مخابرات": [Vector2(720, 790), Vector2(1180, 790), Vector2(1180, 880), Vector2(720, 880)],
}
const PUZZLE_TOTAL := 3

## Contextual HUD hints (Persian update 2026-11-12): the stage hint is
## the standing guide (which key to press next); entering a new area
## shows that area's hint for a few seconds, then the stage hint
## returns (see hud.gd show_area_hint).
const STAGE_HINTS := {
	0: "با E پازل‌ها را حل کن؛ با Q رادار بزن تا چیزهای مخفی را پیدا کنی",
	1: "دکل‌ها را با E روشن کن — هر 3 دکل",
	2: "به فرستنده برو و با E سیگنال اضطراری را بفرست",
}
const AREA_HINTS := {
	"کنترل مرکزی": "کنترل مرکزی — پازل‌ها، دکل‌ها و فرستنده اینجاست؛ مراقب ربات امنیتی باش",
	"بخش پزشکی": "بخش پزشکی — یک ربات اسکنر اینجا نگهبانی می‌دهد؛ در دیدش نمان",
	"آزمایشگاه تحقیقاتی": "آزمایشگاه — یک ربات امنیتی اینجا گشت می‌زند",
	"نیروگاه": "نیروگاه — یک ربات اسکنر اینجا نگهبانی می‌دهد؛ در دیدش نمان",
	"محوطه‌ی مخابرات": "محوطه‌ی مخابرات — بشقاب‌های ماهواره اینجاست؛ یک ربات امنیتی گشت می‌زند",
}

## Five areas: name, pixel rect, floor tint (Central Control keeps the
## original untinted look). The rects are disjoint; together they cover
## the whole map.
const AREAS := [
	{"name": "کنترل مرکزی", "rect": Rect2(0, 0, 640, 368), "tint": Color(0, 0, 0, 0)},
	{"name": "بخش پزشکی", "rect": Rect2(640, 0, 640, 368), "tint": Color(0.5, 0.9, 0.6, 0.07)},
	{"name": "آزمایشگاه تحقیقاتی", "rect": Rect2(0, 368, 640, 368), "tint": Color(0.4, 0.6, 1.0, 0.07)},
	{"name": "نیروگاه", "rect": Rect2(640, 368, 640, 368), "tint": Color(1.0, 0.8, 0.4, 0.07)},
	{"name": "محوطه‌ی مخابرات", "rect": Rect2(640, 736, 640, 192), "tint": Color(0.3, 0.4, 0.7, 0.12)},
]

## Code-built walls (x, y, w, h). The .tscn keeps only the top and left
## ring walls; the east and south ring walls moved here so their doorways
## (Central→Medical at y 160-192, Central→Lab at x 288-320) live in the
## same list as the divider walls. Every rect here is also solid in the
## navigation grid (see _blocked_rects).
const AREA_WALL_RECTS := [
	# Vertical divider x=624 (Central/Medical, then Lab/Power), with the
	# doorway gaps (y 240-272 and y 528-560). This wall IS Central's
	# east ring wall — one wall, not two. The Medical doorway sits south
	# of the wire panel (which ends at y=240); at y=160-192 the panel
	# blocked the gap down to an 8 px slot.
	Rect2(624, 0, 16, 240), Rect2(624, 272, 16, 96),
	Rect2(624, 368, 16, 160), Rect2(624, 560, 16, 176),
	# Horizontal divider y=352 (Central/Lab, then Medical/Power), with
	# the doorway gaps (x 288-320 and x 928-960). Also Central's south
	# ring wall.
	Rect2(0, 352, 288, 16), Rect2(320, 352, 320, 16),
	Rect2(640, 352, 288, 16), Rect2(960, 352, 320, 16),
	# East exterior (new areas) and south exterior of the Lab.
	# Split at y=368 so only the Medical half gets the pack's vertical
	# wall tile; the Power half keeps wall_metal. Same union, so
	# collision and the nav grid are unchanged.
	Rect2(1264, 0, 16, 368), Rect2(1264, 368, 16, 368),
	Rect2(0, 728, 640, 16),
	# Power Station south wall = divider to the Yard, with its doorway gap.
	Rect2(640, 728, 288, 16), Rect2(960, 728, 320, 16),
	# Communication Yard: west, east and south walls.
	Rect2(624, 736, 16, 192), Rect2(1264, 736, 16, 192), Rect2(640, 920, 640, 16),
]

## Solid props (crates + the yard dish) as 16x16 rects, for the nav grid.
## Medical Wing furniture (beds/desk are 32x16) is listed here too, so
## the nav grid and the minimap agree with the physics bodies built by
## _build_medical_props(). Nothing here touches either medical doorway
## (x 624-640, y 240-272 and x 928-960, y 352-368) or the scanner's
## line of sight (x=900, y 120-200) — see the doorway/LOS tests.
const PROP_SOLID_RECTS := [
	Rect2(1112, 292, 16, 16), Rect2(472, 632, 16, 16), Rect2(692, 672, 16, 16),
	Rect2(1142, 812, 16, 16),
	# Medical Wing (pack sprites, 2026-11-15).
	Rect2(684, 56, 32, 16), Rect2(864, 56, 32, 16), Rect2(1064, 56, 32, 16),
	Rect2(684, 152, 32, 16), Rect2(1064, 152, 32, 16), Rect2(1064, 248, 32, 16),
	Rect2(724, 56, 16, 16), Rect2(724, 152, 16, 16), Rect2(912, 56, 16, 16),
	Rect2(652, 152, 16, 16), Rect2(652, 104, 16, 16), Rect2(652, 192, 16, 16),
	Rect2(652, 288, 16, 16), Rect2(652, 312, 16, 16), Rect2(692, 312, 16, 16),
	Rect2(712, 192, 16, 16), Rect2(752, 192, 16, 16), Rect2(752, 112, 16, 16),
	Rect2(1232, 192, 16, 16), Rect2(1232, 132, 16, 16), Rect2(1172, 112, 16, 16),
	Rect2(1152, 56, 16, 16), Rect2(1232, 312, 16, 16), Rect2(1152, 232, 16, 16),
	Rect2(1012, 292, 16, 16), Rect2(1032, 192, 16, 16), Rect2(932, 232, 16, 16),
	Rect2(1172, 312, 16, 16),
]

var _puzzles_solved: int = 0
var _nav_grid: AStarGrid2D = null
## Cache for the medical prop textures (see _med_texture()).
var _med_tex: Dictionary = {}
## Area the player is currently in (test hook + HUD naming).
var current_area: String = "کنترل مرکزی"

@onready var floor_layer: TileMapLayer = $Floor
@onready var player: CharacterBody2D = $Player
@onready var mission: Node = $Mission


func _ready() -> void:
	_build_floor()
	_build_area_walls()
	_build_area_tints()
	_build_area_props()
	_build_nav_grid()
	_build_area_zones()
	_apply_camera_limits()
	_wire_interactables()
	current_area = _area_name_at(player.global_position)
	# The minimap reads the pulse signal too: enemies inside the radius
	# are marked on the map for a few seconds (see minimap.gd).
	player.pulse_emitted.connect(_on_pulse_for_minimap)
	# Deferred: the HUD's @onready vars are not assigned yet when this
	# level readies (siblings ready in tree order), so a direct call here
	# would hit a null label.
	call_deferred("_update_objective_hud")
	call_deferred("_update_stage_hint")
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
	var hud: CanvasLayer = _get_hud()
	if hud == null:
		return
	var stage: int = mission.current_stage()
	if STAGE_HINTS.has(stage):
		hud.set_stage_hint(str(STAGE_HINTS[stage]))
	elif stage >= 3:
		hud.clear_hint()


## Feed the minimap its static layout + live node refs. Null-safe in
## level-only tests (no HUD there). Scoped to this level's subtree so a
## freed level's nodes can't leak in.
func _setup_minimap() -> void:
	var hud: CanvasLayer = _get_hud()
	if hud == null:
		return
	var tower_nodes: Array = []
	var hidden_nodes: Array = []
	var enemy_nodes: Array = []
	for node in get_tree().get_nodes_in_group("towers"):
		if is_ancestor_of(node):
			tower_nodes.append(node)
	for node in get_tree().get_nodes_in_group("hidden"):
		if is_ancestor_of(node):
			hidden_nodes.append(node)
	for node in get_tree().get_nodes_in_group("enemies"):
		if is_ancestor_of(node):
			enemy_nodes.append(node)
	hud.setup_minimap(AREAS, _blocked_rects(), player, tower_nodes, hidden_nodes, enemy_nodes)
	hud.set_minimap_area(current_area)


func _on_pulse_for_minimap(origin: Vector2, radius: float) -> void:
	var hud: CanvasLayer = _get_hud()
	if hud != null:
		hud.mark_minimap_enemies(origin, radius)


func _build_floor() -> void:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var source := TileSetAtlasSource.new()
	source.texture = load(FLOOR_TEXTURE_PATH)
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	source.create_tile(Vector2i.ZERO)
	source.create_tile(Vector2i(1, 0))
	var source_id: int = tileset.add_source(source)
	# Medical Wing floor: the pack's 12-tile atlas (standard, alt,
	# cracked, broken, stains, footprints, tracks, debris, hatch,
	# grille, panel). Cells outside the wing keep the old two tiles.
	var med_source := TileSetAtlasSource.new()
	med_source.texture = load(MED_FLOOR_TEXTURE_PATH)
	med_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for i in 12:
		med_source.create_tile(Vector2i(i, 0))
	var med_source_id: int = tileset.add_source(med_source)
	floor_layer.tile_set = tileset
	var rng := RandomNumberGenerator.new()
	rng.seed = FLOOR_RNG_SEED
	for x in ROOM_COLS:
		for y in ROOM_ROWS:
			# Exactly one roll per cell, as before: the Central pattern
			# (and its test) is unchanged by the medical branch.
			var roll: float = rng.randf()
			if MED_RECT_TILES.has_point(Vector2i(x, y)):
				floor_layer.set_cell(Vector2i(x, y), med_source_id, Vector2i(_medical_floor_index(roll), 0))
			else:
				var coord := Vector2i(1, 0) if roll < FLOOR_VARIANT_CHANCE else Vector2i.ZERO
				floor_layer.set_cell(Vector2i(x, y), source_id, coord)


## First weight threshold above the roll: the medical floor tile index.
func _medical_floor_index(roll: float) -> int:
	for i in MED_FLOOR_WEIGHTS.size():
		if roll < MED_FLOOR_WEIGHTS[i]:
			return i
	return 0


## The pack's wall tile for a code-built wall rect, or null to keep
## wall_metal. Only the Medical Wing's own walls are retextured.
func _medical_wall_texture(r: Rect2) -> Texture2D:
	if r == Rect2(624, 0, 16, 240) or r == Rect2(624, 272, 16, 96):
		return MED_WALL_V_TEXTURE
	if r == Rect2(640, 352, 288, 16) or r == Rect2(960, 352, 320, 16):
		return MED_WALL_H_TEXTURE
	if r == Rect2(1264, 0, 16, 368):
		return MED_WALL_V_TEXTURE
	return null


## Cached loader for the medical prop textures (MED_PROP_PATHS).
func _med_texture(key: String) -> Texture2D:
	if not _med_tex.has(key):
		_med_tex[key] = load(MED_PROP_PATHS[key])
	return _med_tex[key]


func _build_area_walls() -> void:
	var body := StaticBody2D.new()
	body.name = "AreaWalls"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	for wall in AREA_WALL_RECTS:
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
		var r: Rect2 = area["rect"]
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([
			r.position, r.position + Vector2(r.size.x, 0),
			r.position + r.size, r.position + Vector2(0, r.size.y)])
		poly.color = tint
		add_child(poly)


## Area consoles (interactable logs), solid crate/dish props and
## decorative atlas panel sprites. Consoles are added before wiring, so
## the level's signal wiring picks them up like the .tscn ones.
func _build_area_props() -> void:
	_add_area_console(Vector2(760, 80), "گزارش پزشکی: بعد از تمرین شیوع بیماری، این بخش بسته شد. آذوقه کم است.", "monitor_vitals")
	_add_area_console(Vector2(120, 560), "یادداشت‌های تحقیقاتی: برای آرایه‌ی سیگنال باید هر 3 دکل روشن باشند.")
	_add_area_console(Vector2(1100, 560), "گزارش ژنراتور: کلیدها دکل 1 را تغذیه می‌کنند، سیم‌کشی دکل 2 را، و فیوز دکل 3 را.")
	_add_area_console(Vector2(900, 820), "گزارش محوطه: آرایه‌ی بشقاب به ماهواره‌ی رله اشاره می‌کند. بدون دکل‌ها سیگنالی نیست.")
	_add_prop(CRATE_TEXTURE, Vector2(1120, 300))
	_add_prop(CRATE_TEXTURE, Vector2(480, 640))
	_add_prop(CRATE_TEXTURE, Vector2(700, 680))
	_add_prop(DISH_TEXTURE, Vector2(1150, 820))
	_add_decor(PANEL_TEXTURE, Vector2(700, 340))
	_add_decor(FUSEBOX_TEXTURE, Vector2(1200, 640))
	_add_decor(RIVET_TEXTURE, Vector2(1240, 80))
	_build_medical_props()


## Medical Wing furnishing (pack sprites, 2026-11-15). Solid props get
## a physics body + a PROP_SOLID_RECTS entry (nav grid); wall decor and
## small floor clutter are plain sprites. Nothing solid is placed in
## either doorway approach, in the entry corridor (y 240-272, x 640-800)
## or on the scanner's line of sight (x=900, y 120-200).
func _build_medical_props() -> void:
	# Ward row along the north edge: three beds, an exam bed, monitors.
	_add_prop(_med_texture("bed_standard"), Vector2(700, 64), Vector2(32, 16), "MedBedStandard")
	_add_prop(_med_texture("bed_empty"), Vector2(880, 64), Vector2(32, 16), "MedBedEmpty")
	_add_prop(_med_texture("exam_bed"), Vector2(1080, 64), Vector2(32, 16), "MedExamBed")
	_add_prop(_med_texture("bedside_table"), Vector2(732, 64), Vector2(16, 16), "MedBedsideTable")
	_add_prop(_med_texture("monitor_heart"), Vector2(920, 64), Vector2(16, 16), "MedMonitorHeart")
	_add_prop(_med_texture("defibrillator"), Vector2(1160, 64), Vector2(16, 16), "MedDefibrillator")
	# West column: the disorganized bed, cabinets, oxygen, IV.
	_add_prop(_med_texture("bed_disorganized"), Vector2(700, 160), Vector2(32, 16), "MedBedDisorganized")
	_add_prop(_med_texture("monitor_vitals"), Vector2(732, 160), Vector2(16, 16), "MedMonitorVitals")
	_add_prop(_med_texture("cabinet_open"), Vector2(660, 112), Vector2(16, 16), "MedCabinetOpen")
	_add_prop(_med_texture("cabinet_closed"), Vector2(660, 160), Vector2(16, 16), "MedCabinetClosed")
	_add_prop(_med_texture("oxygen_cylinder"), Vector2(660, 200), Vector2(16, 16), "MedOxygen")
	_add_prop(_med_texture("iv_stand"), Vector2(660, 296), Vector2(16, 16), "MedIvStand")
	_add_prop(_med_texture("cabinet_storage"), Vector2(660, 320), Vector2(16, 16), "MedCabinetStorage")
	_add_prop(_med_texture("cabinet_medicine"), Vector2(700, 320), Vector2(16, 16), "MedCabinetMedicine")
	# Center: lamp, chairs, infusion pump, side table.
	_add_prop(_med_texture("exam_lamp"), Vector2(720, 200), Vector2(16, 16), "MedExamLamp")
	_add_prop(_med_texture("chair_rolling"), Vector2(760, 200), Vector2(16, 16), "MedChairRolling")
	_add_prop(_med_texture("infusion_pump"), Vector2(760, 120), Vector2(16, 16), "MedInfusionPump")
	_add_prop(_med_texture("side_table"), Vector2(940, 240), Vector2(16, 16), "MedSideTable")
	_add_prop(_med_texture("chair_office"), Vector2(1040, 200), Vector2(16, 16), "MedChairOffice")
	# East side: stretcher, doctor's desk, trolley, cart, shelf, boxes.
	_add_prop(_med_texture("stretcher"), Vector2(1080, 160), Vector2(32, 16), "MedStretcher")
	_add_prop(_med_texture("desk_doctor"), Vector2(1080, 256), Vector2(32, 16), "MedDeskDoctor")
	_add_prop(_med_texture("trolley"), Vector2(1160, 240), Vector2(16, 16), "MedTrolley")
	_add_prop(_med_texture("cart_emergency"), Vector2(1020, 300), Vector2(16, 16), "MedCartEmergency")
	_add_prop(_med_texture("shelf_medicine"), Vector2(1240, 200), Vector2(16, 16), "MedShelfMedicine")
	_add_prop(_med_texture("oxygen_unit"), Vector2(1240, 140), Vector2(16, 16), "MedOxygenUnit")
	_add_prop(_med_texture("supply_boxes"), Vector2(1180, 120), Vector2(16, 16), "MedSupplyBoxes")
	_add_prop(_med_texture("waste_bin"), Vector2(1240, 320), Vector2(16, 16), "MedWasteBin")
	_add_prop(_med_texture("cabinet_worn"), Vector2(1180, 320), Vector2(16, 16), "MedCabinetWorn")
	# Wall decor: west divider, south divider, junctions, east wall.
	_add_med_decor("clock_wall", Vector2(632, 40), "MedClock")
	_add_med_decor("wall_access_panel", Vector2(632, 100), "MedAccessPanel")
	_add_med_decor("window_small", Vector2(632, 160), "MedWindowSmall")
	_add_med_decor("grille_vent", Vector2(632, 200), "MedGrilleVent")
	_add_med_decor("panel_wall_small", Vector2(632, 300), "MedWallPanel")
	_add_med_decor("sign_warning", Vector2(632, 320), "MedWarningSign")
	_add_med_decor("window_observation", Vector2(1000, 360), "MedWindowObservation")
	_add_med_decor("wall_cabinet_section", Vector2(1100, 360), "MedWallCabinet")
	_add_med_decor("wall_corner_inner", Vector2(632, 360), "MedCornerSW")
	_add_med_decor("wall_corner_outer", Vector2(1272, 360), "MedCornerSE")
	_add_med_decor("fusebox_closed", Vector2(1272, 60), "MedFusebox")
	_add_med_decor("indicator_emergency", Vector2(1272, 200), "MedIndicator")
	# Lights: ceiling fixtures + small indicators.
	_add_med_decor("light_ceiling", Vector2(800, 40), "MedLightCeilingA")
	_add_med_decor("light_ceiling", Vector2(1100, 320), "MedLightCeilingB")
	_add_med_decor("light_green", Vector2(760, 64), "MedLightGreen")
	_add_med_decor("light_blue", Vector2(860, 40), "MedLightBlue")
	_add_med_decor("light_red", Vector2(1240, 340), "MedLightRed")
	_add_med_decor("light_flicker", Vector2(1100, 200), "MedLightFlicker")
	_add_med_decor("light_damaged", Vector2(1200, 280), "MedLightDamaged")
	# Small floor clutter: supplies, papers, storytelling details.
	_add_med_decor("documents", Vector2(800, 150), "MedDocuments")
	_add_med_decor("bottles_medicine", Vector2(860, 200), "MedBottles")
	_add_med_decor("packages_medicine", Vector2(980, 120), "MedPackages")
	_add_med_decor("gloves", Vector2(820, 300), "MedGloves")
	_add_med_decor("bandages", Vector2(860, 300), "MedBandages")
	_add_med_decor("syringes", Vector2(900, 300), "MedSyringes")
	_add_med_decor("tray_instruments", Vector2(940, 300), "MedTray")
	_add_med_decor("paper_scattered", Vector2(820, 180), "MedPapers")
	_add_med_decor("chair_fallen", Vector2(960, 160), "MedChairFallen")
	_add_med_decor("dust", Vector2(700, 300), "MedDust")
	_add_med_decor("steam", Vector2(1180, 200), "MedSteam")
	_add_med_decor("spark", Vector2(1240, 100), "MedSpark")
	# The doctor's desk: flashlight + handwritten note on its surface.
	_add_med_decor("flashlight", Vector2(1072, 252), "MedFlashlight")
	_add_med_decor("note_doctor", Vector2(1090, 260), "MedNoteDoctor")


func _add_area_console(pos: Vector2, message: String, texture_key: String = "") -> void:
	var console: Node2D = CONSOLE_SCENE.instantiate()
	console.position = pos
	console.message = message
	if texture_key != "":
		console.sprite_texture = _med_texture(texture_key)
	add_child(console)


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


func _add_decor(texture: Texture2D, pos: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = pos
	add_child(sprite)


func _build_nav_grid() -> void:
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(0, 0, ROOM_COLS, ROOM_ROWS)
	grid.cell_size = Vector2(TILE_SIZE, TILE_SIZE)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	var blocked := _blocked_rects()
	for x in ROOM_COLS:
		for y in ROOM_ROWS:
			var cell := Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
			for r in blocked:
				if cell.intersects(r):
					grid.set_point_solid(Vector2i(x, y), true)
					break
	# Inflate the crate and the solid props by one cell in every
	# direction: a 12x14 body whose center follows a cell-center path
	# passes within 1 px of a 16x16 obstacle's corner and gets stuck
	# sliding on it (measured 2026-11-12: enemy wedged at (182, 73)).
	# Walls are NOT inflated — the 32 px doorways would close.
	var inflatable: Array[Rect2] = [Rect2(160, 80, 16, 16)]
	inflatable.append_array(PROP_SOLID_RECTS)
	for r in inflatable:
		var min_cell := Vector2i(int(r.position.x / TILE_SIZE) - 1, int(r.position.y / TILE_SIZE) - 1)
		var max_cell := Vector2i(int(r.end.x / TILE_SIZE) + 1, int(r.end.y / TILE_SIZE) + 1)
		for cx in range(min_cell.x, max_cell.x):
			for cy in range(min_cell.y, max_cell.y):
				if cx >= 0 and cy >= 0 and cx < ROOM_COLS and cy < ROOM_ROWS:
					grid.set_point_solid(Vector2i(cx, cy), true)
	_nav_grid = grid


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
		var r: Rect2 = area["rect"]
		var zone := Area2D.new()
		zone.name = "AreaZone_" + str(area["name"]).replace(" ", "")
		zone.collision_layer = 0
		zone.collision_mask = 1
		zone.monitoring = true
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = r.size
		shape.shape = rect
		shape.position = r.get_center()
		zone.add_child(shape)
		zone.body_entered.connect(_on_area_body_entered.bind(str(area["name"])))
		add_child(zone)


func _area_name_at(pos: Vector2) -> String:
	for area in AREAS:
		if (area["rect"] as Rect2).has_point(pos):
			return str(area["name"])
	return "Central Control"


func _on_area_body_entered(body: Node2D, area_name: String) -> void:
	if body != player or area_name == current_area:
		return
	current_area = area_name
	var hud: CanvasLayer = _get_hud()
	if hud != null:
		hud.show_message(area_name)
		hud.set_minimap_area(area_name)
		if AREA_HINTS.has(area_name):
			hud.show_area_hint(str(AREA_HINTS[area_name]))


func _apply_camera_limits() -> void:
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = ROOM_COLS * TILE_SIZE
	camera.limit_bottom = ROOM_ROWS * TILE_SIZE


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
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_ancestor_of(enemy):
			continue
		enemy.player = player
		enemy.nav_grid = _nav_grid
		if enemy.is_in_group("scanners"):
			# The scanner stays at its post; it never patrols.
			var post_points: Array[Vector2] = [enemy.global_position]
			enemy.patrol_points = post_points
		else:
			# One robot per area: patrol the rectangle of the area the
			# robot spawns in, never Central's loop by default. The
			# dict holds plain Arrays, but patrol_points is typed
			# Array[Vector2] — assigning a plain Array aborts the
			# whole wiring function (measured 2026-11-12: pulse,
			# puzzles and towers all stopped working), so convert
			# with assign() first.
			var area_name: String = _area_name_at(enemy.global_position)
			if PATROL_RECTS.has(area_name):
				var points: Array[Vector2] = []
				points.assign(PATROL_RECTS[area_name])
				enemy.patrol_points = points
			else:
				enemy.patrol_points = PATROL_POINTS
		player.pulse_emitted.connect(enemy.investigate)
		enemy.player_caught.connect(_on_player_caught)
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
