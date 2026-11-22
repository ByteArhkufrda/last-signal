extends RoomBase
## Last Signal — Power Station room (engine_room), split from
## level_01.gd / level_01.tscn, 2026-11-15; local coordinates 2026-11-23.
##
## The bottom-right wing: its divider/east/south walls, the area
## console, the crate, the fuse-box decor and the power scanner
## (local (360, 152); was (1000, 520) in station coordinates).
## Station offset is (40, 23) tiles.

func _ready() -> void:
	room_key = "engine_room"
	area_name = "نیروگاه"
	room_rect = Rect2(0, 0, 640, 368)
	room_tile_rect = Rect2i(0, 0, 40, 23)
	area_hint = str(LevelData.AREA_HINTS[area_name])
	spawn_point = Vector2(60, 32)
	tint_color = Color(1.0, 0.8, 0.4, 0.07)
	_build_floor_if_standalone()
	_build_wall_rects(wall_rects())
	_build_tint()
	_build_zone()
	_add_area_console(Vector2(460, 192), "گزارش ژنراتور: کلیدها دکل 1 را تغذیه می‌کنند، سیم‌کشی دکل 2 را، و فیوز دکل 3 را.")
	_add_prop(LevelData.CRATE_TEXTURE, Vector2(60, 312))
	_add_decor(LevelData.FUSEBOX_TEXTURE, Vector2(560, 272))


func wall_rects() -> Array[Rect2]:
	return [
		Rect2(-16, 0, 16, 160), Rect2(-16, 192, 16, 176),
		Rect2(0, -16, 288, 16), Rect2(320, -16, 320, 16),
		Rect2(624, 0, 16, 368),
		Rect2(0, 360, 288, 16), Rect2(320, 360, 320, 16),
	]


func blocked_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = wall_rects()
	rects.append_array(prop_solid_rects())
	return rects


func prop_solid_rects() -> Array[Rect2]:
	return [Rect2(52, 304, 16, 16)]


func exits() -> Array[Dictionary]:
	return [
		{"id": "north", "edge": "north", "rect": Rect2(288, -16, 32, 16),
			"target_room": "medical_wing", "target_exit": "south"},
		{"id": "west", "edge": "west", "rect": Rect2(-16, 160, 16, 32),
			"target_room": "laboratory", "target_exit": "east"},
		{"id": "south", "edge": "south", "rect": Rect2(288, 360, 32, 16),
			"target_room": "communications", "target_exit": "north"},
	]
