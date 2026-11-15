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
	player = PLAYER_SCENE.instantiate()
	player.name = "Player"
	player.position = room.spawn_point
	add_child(player)
	mission = MISSION_SCRIPT.new()
	mission.name = "Mission"
	add_child(mission)
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
	wiring.setup(self, player, mission, nav_grid, room.blocked_rects())
