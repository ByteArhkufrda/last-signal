extends Node2D
## Last Signal — standalone launcher for medbay (self-contained copy, 2026-11-28).
##
## Play this room as its own game:
##   godot --path . scenes/levels/rooms/medbay/play_medbay.tscn
## (add --headless to load and wire it without a window.)
## Same behaviour as the old shared room_play, but every file
## it touches is this room's own copy: room, wiring, player,
## mission, nav grid. No puzzles in this room: the launcher only
## wires movement, robots, HUD and the standing mission objective.

const PLAYER_SCENE: PackedScene = preload("res://scenes/levels/rooms/medbay/player_medbay.tscn")
const MISSION_SCRIPT: Script = preload("res://scripts/levels/rooms/medbay/mission_medbay.gd")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/hud.tscn")
## Station position of this room, in tiles. Medbay is NOT in
## LevelData (standalone only), so there is no station offset: zero.
## The room itself is placed at (0, 0), so every global position in
## standalone play is a LOCAL one.
const ROOM_TILE_OFFSET := Vector2i.ZERO
const ROOM_SCENE := "res://scenes/levels/rooms/medbay/medbay.tscn"

## Area the player is currently in (test hook + HUD naming; the wiring
## keeps it up to date, same as in the full level).
var current_area: String = ""
var room: Node2D = null
var player: CharacterBody2D = null
var mission: Node = null
var wiring = null
var nav_grid: AStarGrid2D = null


func _ready() -> void:
	var room_key := "medbay"
	var room_scene: PackedScene = load(ROOM_SCENE)
	room = room_scene.instantiate()
	room.standalone = true
	# Local play: the room sits at (0, 0), so global == local. The
	# tile offset is zero (this room has no station position).
	room.tile_offset = ROOM_TILE_OFFSET
	room.map_offset = Vector2.ZERO
	room.position = Vector2.ZERO
	add_child(room)
	# The room scene ships only the robots; the Player and Mission
	# are spawned here instead of a second pair (two players fought
	# each other — the pair drifted left on its own, input came out
	# inverted, and every E fired twice). If a future room scene
	# ships its own pair, re-use them instead.
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
	# Seal the open border: the MAP is a cut-out of the station, so
	# its edges are mostly open corridor (159 walkable border cells)
	# with nothing beyond them — the player walked out of standalone
	# rooms through such gaps before. The seal is a separate body
	# and stays OUT of the nav grid: no path ever needs to cross it
	# (the player is sealed inside).
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
	# Standalone HUD: every mission/area message is routed through
	# the HUD — without one the objective is silent. The shared HUD
	# scene is only referenced, never modified.
	var hud: CanvasLayer = HUD_SCENE.instantiate()
	hud.name = "HUD"
	add_child(hud)
	# No puzzles in this room: the shared HUD's PuzzlesLabel would
	# otherwise sit at a wrong "0/3" forever. Hiding the instance's
	# label here (the shared hud.tscn itself is untouched).
	var puzzles_label: Label = hud.get_node_or_null("PuzzlesLabel") as Label
	if puzzles_label != null:
		puzzles_label.hide()
	# The shared HUD's labels are plain white, which is unreadable
	# on this room's bright hospital floor (the lab has the same
	# open issue on its pale floor). A dark outline on this
	# instance's labels only — again, the shared scene is untouched.
	for label in hud.find_children("*", "Label", true, false):
		(label as Label).add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		(label as Label).add_theme_constant_override("outline_size", 6)
	wiring = WIRING_SCRIPT.new()
	add_child(wiring)
	# Caught in a standalone room, respawn at that room's spawn
	# (848, 80) — the full game's entrance is outside this room.
	wiring.setup(self, player, mission, nav_grid, room.blocked_rects(), room.spawn_point)
const ROOM_SCRIPT: GDScript = preload("res://scripts/levels/rooms/medbay/medbay.gd")
const WIRING_SCRIPT: Script = preload("res://scripts/levels/rooms/medbay/wiring_medbay.gd")

