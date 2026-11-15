extends RoomBase
## Last Signal — Power Station room (engine_room), split from
## level_01.gd / level_01.tscn, 2026-11-15.
##
## The bottom-right wing: its divider/east/south walls, the area
## console, the crate, the fuse-box decor and the power scanner at
## (1000, 520). Positions are unchanged.

func _ready() -> void:
	room_key = "engine_room"
	area_name = "نیروگاه"
	room_rect = Rect2(640, 368, 640, 368)
	room_tile_rect = Rect2i(40, 23, 40, 23)
	area_hint = str(LevelData.AREA_HINTS[area_name])
	spawn_point = Vector2(700, 400)
	tint_color = Color(1.0, 0.8, 0.4, 0.07)
	_build_floor_if_standalone()
	_build_wall_rects(wall_rects())
	_build_tint()
	_build_zone()
	_add_area_console(Vector2(1100, 560), "گزارش ژنراتور: کلیدها دکل 1 را تغذیه می‌کنند، سیم‌کشی دکل 2 را، و فیوز دکل 3 را.")
	_add_prop(LevelData.CRATE_TEXTURE, Vector2(700, 680))
	_add_decor(LevelData.FUSEBOX_TEXTURE, Vector2(1200, 640))


func wall_rects() -> Array[Rect2]:
	return [
		Rect2(624, 368, 16, 160), Rect2(624, 560, 16, 176),
		Rect2(640, 352, 288, 16), Rect2(960, 352, 320, 16),
		Rect2(1264, 368, 16, 368),
		Rect2(640, 728, 288, 16), Rect2(960, 728, 320, 16),
	]


func blocked_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = wall_rects()
	rects.append_array(prop_solid_rects())
	return rects


func prop_solid_rects() -> Array[Rect2]:
	return [Rect2(692, 672, 16, 16)]
