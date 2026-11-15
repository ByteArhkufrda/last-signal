extends RoomBase
## Last Signal — Communications Yard room (communications), split from
## level_01.gd / level_01.tscn, 2026-11-15.
##
## The south annex: its west/east/south walls, the divider to the
## Power Station, the area console, the satellite dish and the yard
## security robot at (800, 840). Positions are unchanged.

func _ready() -> void:
	room_key = "communications"
	area_name = "محوطه‌ی مخابرات"
	room_rect = Rect2(640, 736, 640, 192)
	room_tile_rect = Rect2i(40, 46, 40, 12)
	area_hint = str(LevelData.AREA_HINTS[area_name])
	spawn_point = Vector2(944, 760)
	tint_color = Color(0.3, 0.4, 0.7, 0.12)
	_build_floor_if_standalone()
	_build_wall_rects(wall_rects())
	_build_tint()
	_build_zone()
	_add_area_console(Vector2(900, 820), "گزارش محوطه: آرایه‌ی بشقاب به ماهواره‌ی رله اشاره می‌کند. بدون دکل‌ها سیگنالی نیست.")
	_add_prop(LevelData.DISH_TEXTURE, Vector2(1150, 820))


func wall_rects() -> Array[Rect2]:
	return [
		Rect2(624, 736, 16, 192), Rect2(1264, 736, 16, 192),
		Rect2(640, 920, 640, 16),
		Rect2(640, 728, 288, 16), Rect2(960, 728, 320, 16),
	]


func blocked_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = wall_rects()
	rects.append_array(prop_solid_rects())
	return rects


func prop_solid_rects() -> Array[Rect2]:
	return [Rect2(1142, 812, 16, 16)]
