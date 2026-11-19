extends RoomBase
## Last Signal — Research Laboratory room (laboratory), split from
## level_01.gd / level_01.tscn, 2026-11-15.
##
## The bottom-left wing: its divider walls, the area console, the
## crate and the lab security robot at (200, 560). Positions are
## unchanged.

func _ready() -> void:
	room_key = "laboratory"
	area_name = "آزمایشگاه تحقیقاتی"
	room_rect = Rect2(0, 368, 640, 368)
	room_tile_rect = Rect2i(0, 23, 40, 23)
	area_hint = str(LevelData.AREA_HINTS[area_name])
	spawn_point = Vector2(320, 400)
	tint_color = Color(0.4, 0.6, 1.0, 0.07)
	_build_floor_if_standalone()
	_build_wall_rects(wall_rects())
	_build_tint()
	_build_zone()
	_add_area_console(Vector2(120, 560), "یادداشت‌های تحقیقاتی: برای آرایه‌ی سیگنال باید هر 3 دکل روشن باشند.")
	_add_prop(LevelData.CRATE_TEXTURE, Vector2(480, 640))


func wall_rects() -> Array[Rect2]:
	return [
		Rect2(624, 368, 16, 160), Rect2(624, 560, 16, 176),
		Rect2(0, 352, 288, 16), Rect2(320, 352, 320, 16),
		Rect2(0, 728, 640, 16),
		# West exterior (2026-11-19: this edge had no wall — the
		# player walked off the map beside the lab, in the full game).
		Rect2(0, 368, 16, 368),
	]


func blocked_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = wall_rects()
	rects.append_array(prop_solid_rects())
	return rects


func prop_solid_rects() -> Array[Rect2]:
	return [Rect2(472, 632, 16, 16)]
