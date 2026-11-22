extends RoomBase
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
	area_hint = str(LevelData.AREA_HINTS[area_name])
	spawn_point = Vector2(304, 24)
	tint_color = Color(0.3, 0.4, 0.7, 0.12)
	_build_floor_if_standalone()
	_build_wall_rects(wall_rects())
	_build_tint()
	_build_zone()
	_add_area_console(Vector2(260, 84), "گزارش محوطه: آرایه‌ی بشقاب به ماهواره‌ی رله اشاره می‌کند. بدون دکل‌ها سیگنالی نیست.")
	_add_prop(LevelData.DISH_TEXTURE, Vector2(510, 84))


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
