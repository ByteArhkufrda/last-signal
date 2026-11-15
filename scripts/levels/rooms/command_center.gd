extends RoomBase
## Last Signal — Central Control room (command_center), split from
## level_01.gd / level_01.tscn, 2026-11-15.
##
## The original 40x23 hall: the ring walls, the alcove, all three
## puzzles (breaker, wire, fuse), all three towers, the transmit
## console and the security robot. The .tscn nodes moved verbatim from
## level_01.tscn with positions unchanged; the code-built east/south
## divider walls are built here (shared with the Medical Wing and the
## Laboratory — the neighbours build the same rects, the assembler
## keeps one copy).

func _ready() -> void:
	room_key = "command_center"
	area_name = "کنترل مرکزی"
	room_rect = Rect2(0, 0, 640, 368)
	room_tile_rect = Rect2i(0, 0, 40, 23)
	area_hint = str(LevelData.AREA_HINTS[area_name])
	spawn_point = Vector2(320, 184)
	tint_color = Color(0, 0, 0, 0)
	_build_floor_if_standalone()
	_build_wall_rects(wall_rects())
	_build_tint()
	_build_zone()


func wall_rects() -> Array[Rect2]:
	return [
		Rect2(624, 0, 16, 240), Rect2(624, 272, 16, 96),
		Rect2(0, 352, 288, 16), Rect2(320, 352, 320, 16),
	]


func blocked_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = wall_rects()
	# The .tscn ring walls, alcove walls and crate.
	rects.append_array([
		Rect2(0, 0, 640, 16), Rect2(0, 0, 16, 368),
		Rect2(496, 16, 16, 48), Rect2(512, 56, 40, 16), Rect2(584, 56, 40, 16),
		Rect2(160, 80, 16, 16),
	])
	return rects


func prop_solid_rects() -> Array[Rect2]:
	return [Rect2(160, 80, 16, 16)]
