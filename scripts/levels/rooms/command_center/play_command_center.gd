extends Node2D
## Last Signal — standalone launcher for command_center (self-contained copy, 2026-11-23).
##
## Play this room as its own game:
##   godot --path . scenes/levels/rooms/command_center/play_command_center.tscn
## (add --headless to load and wire it without a window.)
## Same behaviour as the old shared room_play, but every file
## it touches is this room's own copy: room, wiring, player,
## mission, nav grid.

const PLAYER_SCENE: PackedScene = preload("res://scenes/levels/rooms/command_center/player_command_center.tscn")
const MISSION_SCRIPT: Script = preload("res://scripts/levels/rooms/command_center/mission_command_center.gd")
## Station position of each room, in tiles. Only the floor builder
## reads this (rolls are station-global); the room itself is placed at
## (0, 0), so every global position in standalone play is a LOCAL one.
const ROOM_TILE_OFFSET := Vector2i(0, 0)
const ROOM_SCENE := "res://scenes/levels/rooms/command_center/command_center.tscn"

## Area the player is currently in (test hook + HUD naming; the wiring
## keeps it up to date, same as in the full level).
var current_area: String = ""
## Solved-puzzle count, mirrored here by LevelWiring (same test hook
## as the full level's _puzzles_solved).
var _puzzles_solved: int = 0
var room: Node2D = null
var player: CharacterBody2D = null
var mission: Node = null
var wiring = null
var nav_grid: AStarGrid2D = null


func _ready() -> void:
	var room_key := "command_center"
	var room_scene: PackedScene = load(ROOM_SCENE)
	room = room_scene.instantiate()
	room.standalone = true
	# Local play: the room sits at (0, 0), so global == local. The
	# tile offset is still the station offset, so the floor pattern
	# matches the assembled map cell for cell.
	room.tile_offset = ROOM_TILE_OFFSET
	room.map_offset = Vector2.ZERO
	room.position = Vector2.ZERO
	add_child(room)
	# Central Control ships its own Player and Mission in the .tscn;
	# re-use them instead of spawning a second pair (2026-11-19: two
	# players fought each other — the pair drifted left on its own,
	# input came out inverted, every E fired twice, and the fuse box
	# read the wrong player's empty inventory).
	var room_player: CharacterBody2D = room.get_node_or_null("Player") as CharacterBody2D
	if room_player != null:
		player = room_player
	else:
		player = PLAYER_SCENE.instantiate()
		player.name = "Player"
		add_child(player)
	player.position = room.spawn_point
	var room_mission: Node = room.get_node_or_null("Mission")
	if room_mission != null:
		mission = room_mission
	else:
		mission = MISSION_SCRIPT.new()
		mission.name = "Mission"
		add_child(mission)
	# Seal the doorway gaps: in the full map they open into the
	# neighbours, here there is nothing beyond them (2026-11-19: the
	# player walked out of standalone rooms through the 32 px gaps).
	# The seal is a separate body and stays OUT of the nav grid — same
	# precedent as the alcove door: no path ever needs to cross it
	# (the player is sealed inside), and the grid must keep agreeing
	# with the full level's grid cell for cell.
	var seal: Array[Rect2] = room.doorway_gap_rects()
	if not seal.is_empty():
		room._build_wall_rects(seal, "WallsSeal_" + room_key)
	# Inflatable props are the room's own, in local coordinates.
	var inflatable: Array[Rect2] = room.prop_solid_rects()
	var nav_grid: AStarGrid2D = ROOM_SCRIPT.build_nav_grid(
		room.room_tile_rect, room.blocked_rects(), inflatable)
	self.nav_grid = nav_grid
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_left = int(room.room_rect.position.x)
	camera.limit_top = int(room.room_rect.position.y)
	camera.limit_right = int(room.room_rect.end.x)
	camera.limit_bottom = int(room.room_rect.end.y)
	wiring = WIRING_SCRIPT.new()
	add_child(wiring)
	# Caught in a standalone room, respawn at that room's spawn — the
	# full game's entrance (320, 184) is outside every other room.
	wiring.setup(self, player, mission, nav_grid, room.blocked_rects(), room.spawn_point)
const ROOM_SCRIPT: GDScript = preload("res://scripts/levels/rooms/command_center/command_center.gd")
const WIRING_SCRIPT: Script = preload("res://scripts/levels/rooms/command_center/wiring_command_center.gd")

