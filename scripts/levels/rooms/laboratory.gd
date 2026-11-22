extends RoomBase
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
	area_hint = str(LevelData.AREA_HINTS[area_name])
	spawn_point = Vector2(320, 32)
	tint_color = Color(0.4, 0.6, 1.0, 0.07)
	_build_floor_if_standalone()
	_build_wall_rects(wall_rects())
	_build_tint()
	_build_zone()
	_add_area_console(Vector2(120, 192), "یادداشت‌های تحقیقاتی: برای آرایه‌ی سیگنال باید هر 3 دکل روشن باشند.")
	_add_prop(LevelData.CRATE_TEXTURE, Vector2(480, 272))


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
