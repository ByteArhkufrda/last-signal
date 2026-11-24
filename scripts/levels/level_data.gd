class_name LevelData
## Last Signal — shared level data (split from level_01.gd, 2026-11-15).
##
## The constants that describe the whole station live here so the level
## assembler (level_01.gd) and the shared wiring (level_wiring.gd) read
## the same values. Gameplay values are unchanged: 80x58 tiles of
## 16 px = 1280x928, five areas, three puzzles -> three towers ->
## transmit.
##
## Local-coordinate rebase (2026-11-23): the room modules
## (scripts/levels/rooms/*) NO LONGER read AREAS, AREA_WALL_RECTS,
## PROP_SOLID_RECTS or PATROL_RECTS — each room owns its own geometry
## in local coordinates. Those lists stay here as the STATION layout:
## the assembled wiring/minimap read them, and the room tests assert
## the rooms' translated geometry agrees with them, so the two can
## never silently drift apart.

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
const WALL_TEXTURE: Texture2D = preload("res://assets/sprites/environment/wall_metal.png")
const SPAWN := Vector2(320, 184)
const PATROL_POINTS: Array[Vector2] = [
	Vector2(200, 120), Vector2(440, 120), Vector2(440, 280), Vector2(200, 280)
]
## One patrol rectangle per area with a security robot. Each rectangle
## stays inside its area and clear of consoles and solid props.
const PATROL_RECTS := {
	"کنترل مرکزی": [Vector2(200, 120), Vector2(440, 120), Vector2(440, 280), Vector2(200, 280)],
	"آزمایشگاه تحقیقاتی": [Vector2(160, 480), Vector2(520, 480), Vector2(520, 640), Vector2(160, 640)],
	"محوطه‌ی مخابرات": [Vector2(720, 790), Vector2(1180, 790), Vector2(1180, 880), Vector2(720, 880)],
}
const PUZZLE_TOTAL := 3

## Contextual HUD hints: the stage hint is the standing guide (which
## key to press next); entering a new area shows that area's hint for a
## few seconds, then the stage hint returns (see hud.gd show_area_hint).
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
## the whole map except the empty south-west quarter (x 0-39, y 46-57
## tiles), which has no area.
const AREAS := [
	{"name": "کنترل مرکزی", "rect": Rect2(0, 0, 640, 368), "tint": Color(0, 0, 0, 0)},
	{"name": "بخش پزشکی", "rect": Rect2(640, 0, 640, 368), "tint": Color(0.5, 0.9, 0.6, 0.07)},
	{"name": "آزمایشگاه تحقیقاتی", "rect": Rect2(0, 368, 640, 368), "tint": Color(0.4, 0.6, 1.0, 0.07)},
	{"name": "نیروگاه", "rect": Rect2(640, 368, 640, 368), "tint": Color(1.0, 0.8, 0.4, 0.07)},
	{"name": "محوطه‌ی مخابرات", "rect": Rect2(640, 736, 640, 192), "tint": Color(0.3, 0.4, 0.7, 0.12)},
]

## Code-built walls (x, y, w, h). Every rect here is also solid in the
## navigation grid (see RoomBase.build_nav_grid), so walls and
## pathfinding can never disagree about what is solid.
const AREA_WALL_RECTS := [
	# Vertical divider x=624 (Central/Medical, then Lab/Power), with the
	# doorway gaps (y 240-272 and y 528-560).
	Rect2(624, 0, 16, 240), Rect2(624, 272, 16, 96),
	Rect2(624, 368, 16, 160), Rect2(624, 560, 16, 176),
	# Horizontal divider y=352 (Central/Lab, then Medical/Power), with
	# the doorway gaps (x 288-320 and x 928-960).
	Rect2(0, 352, 288, 16), Rect2(320, 352, 320, 16),
	Rect2(640, 352, 288, 16), Rect2(960, 352, 320, 16),
	# East exterior (new areas) and south exterior of the Lab.
	Rect2(1264, 0, 16, 368), Rect2(1264, 368, 16, 368),
	Rect2(0, 728, 640, 16),
	# Power Station south wall = divider to the Yard, with its doorway gap.
	Rect2(640, 728, 288, 16), Rect2(960, 728, 320, 16),
	# Communication Yard: west, east and south walls.
	Rect2(624, 736, 16, 192), Rect2(1264, 736, 16, 192), Rect2(640, 920, 640, 16),
	# Outer boundary, closed 2026-11-19 (debug: these two edges had no
	# wall at all — the player walked off the map north of the Medical
	# Wing and west of the Laboratory, in the full game).
	Rect2(640, 0, 640, 16), Rect2(0, 368, 16, 368),
	# South-west quarter (floored, no area): close its west/south edges
	# so the dead space is sealed as well.
	Rect2(0, 736, 16, 192), Rect2(0, 920, 640, 16),
]

## Solid props (crates + the yard dish) as 16x16 rects, for the nav grid.
const PROP_SOLID_RECTS := [
	Rect2(472, 632, 16, 16), Rect2(692, 672, 16, 16),
	Rect2(1142, 812, 16, 16),
	# Medical Wing — clinic redesign (2026-11-23): ward, exam,
	# emergency, pharmacy, office, storage, center. World coords
	# (local + (640, 0)); must match the room's prop_solid_rects().
	Rect2(656, 192, 16, 16), Rect2(656, 272, 16, 16), Rect2(672, 32, 16, 16),
	Rect2(672, 48, 32, 16), Rect2(672, 208, 32, 16), Rect2(672, 288, 16, 16),
	Rect2(672, 320, 16, 16), Rect2(688, 320, 16, 16), Rect2(704, 48, 16, 16),
	Rect2(704, 208, 16, 16), Rect2(704, 336, 16, 16), Rect2(720, 48, 32, 16),
	Rect2(720, 208, 16, 16), Rect2(720, 320, 16, 16), Rect2(752, 48, 16, 16),
	Rect2(768, 32, 16, 16), Rect2(768, 48, 32, 16), Rect2(800, 48, 16, 16),
	Rect2(848, 48, 16, 16), Rect2(960, 32, 16, 16),
	Rect2(960, 160, 16, 16), Rect2(976, 48, 32, 16), Rect2(992, 336, 16, 16),
	Rect2(1024, 48, 16, 16), Rect2(1024, 144, 16, 16), Rect2(1024, 336, 16, 16),
	Rect2(1040, 32, 16, 16), Rect2(1040, 144, 16, 16), Rect2(1056, 48, 16, 16),
	Rect2(1056, 336, 16, 16), Rect2(1088, 336, 16, 16), Rect2(1120, 336, 16, 16),
	Rect2(1136, 288, 32, 16), Rect2(1152, 336, 16, 16), Rect2(1168, 288, 16, 16),
	Rect2(1200, 272, 16, 16),

	# Clinic redesign (2026-11-24): Telegram hospital pack + photos.
	# New room props, world coords (local + (640, 0)); must match the
	# room's prop_solid_rects() — see test_station_layout_agrees_with_rooms.
	Rect2(768, 96, 32, 16), Rect2(672, 96, 32, 16), Rect2(720, 96, 32, 16),
	Rect2(704, 96, 16, 16), Rect2(752, 96, 16, 16), Rect2(1088, 32, 32, 16),
	Rect2(1120, 32, 16, 16), Rect2(1152, 32, 16, 32), Rect2(1184, 32, 16, 32),
	Rect2(1216, 32, 16, 32), Rect2(1136, 96, 64, 32), Rect2(1200, 96, 32, 16),
	Rect2(1120, 64, 32, 16), Rect2(848, 208, 32, 32), Rect2(896, 208, 16, 16),
	Rect2(928, 208, 16, 16), Rect2(864, 176, 16, 16), Rect2(928, 176, 16, 16),
	Rect2(944, 192, 16, 32), Rect2(1120, 144, 32, 48), Rect2(1200, 144, 48, 64),
	Rect2(1152, 160, 16, 32), Rect2(1088, 128, 16, 32), Rect2(1120, 128, 32, 16),
	Rect2(1184, 128, 32, 16), Rect2(1088, 176, 16, 16), Rect2(1152, 192, 16, 16),
	Rect2(848, 48, 32, 16), Rect2(928, 32, 16, 32), Rect2(1072, 32, 16, 32),
	Rect2(896, 48, 16, 16), Rect2(816, 48, 16, 16), Rect2(864, 32, 16, 16),
	Rect2(816, 96, 16, 16), Rect2(656, 48, 16, 16), Rect2(656, 96, 16, 16),
	Rect2(800, 96, 16, 16), Rect2(832, 48, 16, 16), Rect2(848, 96, 16, 16),
	Rect2(848, 80, 16, 16), Rect2(880, 80, 16, 16), Rect2(1184, 336, 16, 16),
	Rect2(656, 176, 16, 16), Rect2(1088, 96, 16, 16), Rect2(688, 176, 16, 16),
	Rect2(736, 320, 16, 16), Rect2(688, 192, 16, 16), Rect2(720, 192, 16, 16),
	Rect2(752, 192, 16, 16), Rect2(784, 272, 16, 16), Rect2(736, 336, 16, 16),
]
