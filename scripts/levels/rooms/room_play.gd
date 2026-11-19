extends Node2D
## Last Signal — standalone room launcher (dev tool, 2026-11-15).
##
## Play one room as its own game:
##   godot --path . scenes/levels/rooms/room_play.tscn -- --room=medical_wing
## (add --headless to load and wire it without a window.)
## Default room is command_center. The launcher instances the room
## with standalone = true (so it builds its own floor), spawns the
## player at the room's spawn point, adds a Mission node, builds the
## room's nav grid and wires everything through LevelWiring — the same
## wiring the full level uses.

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player.tscn")
const MISSION_SCRIPT: Script = preload("res://scripts/systems/mission.gd")
const ROOM_SCENES := {
	"command_center": "res://scenes/levels/rooms/command_center.tscn",
	"medical_wing": "res://scenes/levels/rooms/medical_wing.tscn",
	"laboratory": "res://scenes/levels/rooms/laboratory.tscn",
	"engine_room": "res://scenes/levels/rooms/engine_room.tscn",
	"communications": "res://scenes/levels/rooms/communications.tscn",
}

## Area the player is currently in (test hook + HUD naming; the wiring
## keeps it up to date, same as in the full level).
var current_area: String = ""
## Solved-puzzle count, mirrored here by LevelWiring (same test hook
## as the full level's _puzzles_solved).
var _puzzles_solved: int = 0
## Test hook: when set, this room is played instead of the --room= arg.
var room_key_override: String = ""
var room: RoomBase = null
var player: CharacterBody2D = null
var mission: Node = null
var wiring: LevelWiring = null
var nav_grid: AStarGrid2D = null


func _ready() -> void:
	var room_key := room_key_override if room_key_override != "" else "command_center"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--room="):
			room_key = arg.trim_prefix("--room=")
	if not ROOM_SCENES.has(room_key):
		push_error("room_play: unknown room '%s'" % room_key)
		return
	var room_scene: PackedScene = load(ROOM_SCENES[room_key])
	room = room_scene.instantiate()
	room.standalone = true
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
	var inflatable: Array[Rect2] = [Rect2(160, 80, 16, 16)]
	inflatable.append_array(LevelData.PROP_SOLID_RECTS)
	var nav_grid: AStarGrid2D = RoomBase.build_nav_grid(
		room.room_tile_rect, room.blocked_rects(), inflatable)
	self.nav_grid = nav_grid
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_left = int(room.room_rect.position.x)
	camera.limit_top = int(room.room_rect.position.y)
	camera.limit_right = int(room.room_rect.end.x)
	camera.limit_bottom = int(room.room_rect.end.y)
	wiring = LevelWiring.new()
	add_child(wiring)
	# Caught in a standalone room, respawn at that room's spawn — the
	# full game's entrance (320, 184) is outside every other room.
	wiring.setup(self, player, mission, nav_grid, room.blocked_rects(), room.spawn_point)
