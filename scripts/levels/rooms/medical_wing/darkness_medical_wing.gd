extends Node2D
## Last Signal — Medical Wing darkness (P2, 2026-11-24, reworked in P5,
## 2026-11-26) and power state (P3, 2026-11-24).
##
## Story (P5): the wing runs on EMERGENCY power. The room is lit from the
## start but its lights flicker; the main power comes back later, in
## another room. Two kinds of darkness share one overlay:
##   * FLICKER: every FLICKER_WAIT_MIN..MAX s (5-11) the whole room goes
##     dark in 1-3 quick pulses, each PULSE_MIN..MAX s (0.12-0.3) long
##     with a short lit gap between them. A seeded RandomNumberGenerator
##     drives it from step(delta), so it is deterministic: the same seed
##     and the same sequence of deltas always give the same pulses.
##     restore_power() stops it for good ("local power stabilises").
##   * DARK ZONE: `zone_rect` (LOCAL), the room's one permanently dark
##     spot. It is dark whenever the player is in the room, whatever the
##     flicker does, and it stays dark after restore_power().
## The player's light is a soft circle cut out of both: LIGHT_RADIUS_SCREEN
## (70 screen px) with the "flashlight" item, TINY_RADIUS_SCREEN (24) without
## it; a flicker pulse without the flashlight has no circle at all.
## Everything is only drawn while the player is inside the room's rect.
##
## How it is drawn: one ColorRect that covers exactly the room's rect
## (so no other room is ever darkened), with a canvas_item shader that
## cuts a soft hole around the player (darkness_medical_wing.gdshader, next
## to the room scene). A high z_index keeps it above the world; the HUD
## is a CanvasLayer, which always draws above the world, so the HUD is
## never darkened either. No CanvasModulate.
##
## Coordinates (this is what keeps it right after the flatten): the node
## sits at the room's own (0, 0), `room_rect`, `zone_rect` and the overlay
## are in the node's LOCAL space, and everything that touches the player
## goes through this node's own transform (to_local). Standalone the node
## is at (0, 0); in the full game level_01.gd _flatten_rooms moves it into
## Level01 with position += the room's offset, and the overlay (a child)
## travels with it — no offset is ever written in this file.
##
## Where the state lives: the assembler frees the MedicalWing node and
## keeps its children, so in the full game THIS node —
## level.get_node("MedicalDarkness") — is what stays alive.
## MedicalWing.power_on / power_restored / restore_power() are a facade
## over it (they work in the standalone room); the fuse box calls
## restore_power() on this node through its `solved` signal.
##
## Dormant robots (P3): until restore_power(), every enemy under this
## node's parent whose position is inside the room's rect gets
## `dormant = true` (see security_robot_medical_wing.gd) and does
## nothing; restore_power() wakes them at once. Only enemies of the same
## branch are touched (two levels alive at once never fight over each
## other's robots), and only enemies that HAVE a `dormant` flag: the
## other rooms' robots are their own per-room copies and stay as they are.

## Emitted once, by the first restore_power().
signal power_restored

const SHADER: Shader = preload("res://scenes/levels/rooms/medical_wing/darkness_medical_wing.gdshader")
## Light radius in SCREEN px at the 640x360 base resolution. The player
## camera zooms 2x, so the radius in world px is this / zoom.
const LIGHT_RADIUS_SCREEN := 70.0
## The tiny circle the player always has without the flashlight.
const TINY_RADIUS_SCREEN := 24.0
## Inventory item that turns the tiny circle into the flashlight.
const FLASHLIGHT_ITEM := "flashlight"
## Opacity of the darkness outside the light (1.0 would be pure black).
const MAX_DARKNESS := 0.95
## Fade seconds of the dark zone when the player enters / leaves the room.
const ROOM_FADE_SECONDS := 0.25
## Fade seconds of a flicker pulse (it must stay well under PULSE_MIN).
const PULSE_FADE_SECONDS := 0.02
const OVERLAY_Z_INDEX := 100
## Flicker: seconds of normal light between two flicker events, pulses
## per event, seconds one pulse stays dark, lit seconds between the
## pulses of one event.
const FLICKER_WAIT_MIN := 5.0
const FLICKER_WAIT_MAX := 11.0
const PULSES_MIN := 1
const PULSES_MAX := 3
const PULSE_MIN := 0.12
const PULSE_MAX := 0.30
const PULSE_GAP_MIN := 0.06
const PULSE_GAP_MAX := 0.14
const FLICKER_SEED := 11
## AudioManager sound played when the power stabilises (the same chime as
## a solved puzzle); looked up through the "audio" group, so it is silent
## wherever there is no AudioManager (level-only tests, the standalone
## room). Read-only use of the group: nothing shared is touched.
const POWER_SOUND := "chime"

## The room's rect in THIS node's local space; set by MedicalWing before
## add_child (its own room_rect, which is local too).
var room_rect: Rect2 = Rect2(0, 0, 640, 368)
## The dark zone in THIS node's local space; set by MedicalWing before
## add_child. An empty rect means "no zone".
var zone_rect: Rect2 = Rect2()
## False until restore_power(): until then the wing runs on emergency
## power (lit, flickering, robots dormant).
var power_on: bool = false
## The lights flicker while this is true; restore_power() turns it off.
## (Tests that need a calm room set it false themselves.)
var flicker_enabled: bool = true

var _rng := RandomNumberGenerator.new()
## Flicker state machine: `_flicker_dark` is "a pulse is on right now",
## `_phase_left` the seconds until the next change, `_pulses_left` the
## pulses still to come in the current event (counting the one running).
var _flicker_dark: bool = false
var _phase_left: float = 0.0
var _pulses_left: int = 0
var _room_amount: float = 0.0
var _zone_amount: float = 0.0
var _player: Node2D = null
var _overlay: ColorRect = null
var _material: ShaderMaterial = null


func _ready() -> void:
	z_index = OVERLAY_Z_INDEX
	# After the player and its camera have moved for the frame.
	process_priority = 100
	_rng.seed = FLICKER_SEED
	_phase_left = _rng.randf_range(FLICKER_WAIT_MIN, FLICKER_WAIT_MAX)
	_overlay = ColorRect.new()
	_overlay.name = "Overlay"
	_overlay.position = room_rect.position
	_overlay.size = room_rect.size
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter("rect_size", room_rect.size)
	var zone_in_overlay := Rect2(zone_rect.position - _overlay.position, zone_rect.size)
	_material.set_shader_parameter("zone_rect", Vector4(zone_in_overlay.position.x, zone_in_overlay.position.y, zone_in_overlay.size.x, zone_in_overlay.size.y))
	_overlay.material = _material
	add_child(_overlay)
	_apply()
	# Robots in the room are off from the very first physics tick.
	_update_dormancy()


func _process(delta: float) -> void:
	step(delta)


## True while the player is inside the room's rect. Nothing is drawn
## otherwise (the visible fades lag behind this; see room_darkness() and
## zone_darkness()).
func player_inside() -> bool:
	var player := _get_player()
	return player != null and room_rect.has_point(to_local(player.global_position))


## True while a flicker pulse is on (the whole room is dark), whether or
## not the player is in the room.
func is_flicker_dark() -> bool:
	return _flicker_dark


## Current opacity of the whole-room darkness (a flicker pulse), 0 (none)
## .. 1 (full), including its fade.
func room_darkness() -> float:
	return _room_amount


## Current opacity of the dark zone's darkness, 0 .. 1, including its fade.
func zone_darkness() -> float:
	return _zone_amount


## Current darkness of either kind, 0 .. 1: the darker of the two.
func darkness() -> float:
	return maxf(_room_amount, _zone_amount)


## True when the player carries the flashlight item.
func has_flashlight() -> bool:
	var player := _get_player()
	return player != null and "inventory" in player and int(player.inventory.get(FLASHLIGHT_ITEM, 0)) > 0


## The player's light radius in SCREEN px right now: the flashlight's
## circle with the item, the tiny circle without it, and no circle at all
## in a flicker pulse without the flashlight.
func light_radius_screen() -> float:
	if has_flashlight():
		return LIGHT_RADIUS_SCREEN
	if _flicker_dark:
		return 0.0
	return TINY_RADIUS_SCREEN


## The local power stabilises: the flicker stops for good, the robots in
## the room wake up and the chime plays. The dark zone stays dark.
## Calling it again does nothing.
func restore_power() -> void:
	if power_on:
		return
	power_on = true
	flicker_enabled = false
	_flicker_dark = false
	_pulses_left = 0
	_update_dormancy()
	_play_chime()
	power_restored.emit()


## Advance the flicker and the fades by delta seconds and refresh the
## overlay. _process calls it every frame; tests call it directly for a
## deterministic clock (any delta, however large, gives the same result
## as the same time in smaller steps).
func step(delta: float) -> void:
	_advance_flicker(delta)
	var inside := player_inside()
	_zone_amount = move_toward(_zone_amount, 1.0 if inside else 0.0, delta / ROOM_FADE_SECONDS)
	_room_amount = move_toward(_room_amount, 1.0 if inside and _flicker_dark else 0.0, delta / PULSE_FADE_SECONDS)
	_apply()
	_update_dormancy()


## Run the flicker clock: idle wait -> pulse -> (lit gap -> pulse)* ->
## idle wait -> ... Every duration is drawn from the seeded generator at
## the moment its phase starts, so the sequence only depends on the seed.
func _advance_flicker(delta: float) -> void:
	if not flicker_enabled:
		return
	var left := delta
	while left >= _phase_left:
		left -= _phase_left
		_next_phase()
	_phase_left -= left


func _next_phase() -> void:
	if _flicker_dark:
		# A pulse just ended: a short gap if the event has more, else the
		# long wait until the next event.
		_flicker_dark = false
		_pulses_left -= 1
		if _pulses_left > 0:
			_phase_left = _rng.randf_range(PULSE_GAP_MIN, PULSE_GAP_MAX)
		else:
			_phase_left = _rng.randf_range(FLICKER_WAIT_MIN, FLICKER_WAIT_MAX)
	else:
		# The wait (or a gap) is over: a pulse starts. A new event first
		# decides how many pulses it has.
		if _pulses_left <= 0:
			_pulses_left = _rng.randi_range(PULSES_MIN, PULSES_MAX)
		_flicker_dark = true
		_phase_left = _rng.randf_range(PULSE_MIN, PULSE_MAX)


func _play_chime() -> void:
	var audio: Node = get_tree().get_first_node_in_group("audio")
	if audio != null and audio.has_method("play"):
		audio.play(POWER_SOUND)


## Robots inside the room's rect are dormant until the power stabilises.
## A robot that walks in (a chaser from the next room, say) freezes where
## it crosses the line; one that is awake outside is untouched. The rect
## is local, so the position goes through to_local like the player's.
func _update_dormancy() -> void:
	var scope := get_parent()
	if scope == null or not is_inside_tree():
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not scope.is_ancestor_of(enemy) or not ("dormant" in enemy):
			continue
		enemy.dormant = not power_on and room_rect.has_point(to_local((enemy as Node2D).global_position))


func _apply() -> void:
	if _overlay == null:
		return
	_overlay.visible = _room_amount > 0.0 or _zone_amount > 0.0
	_material.set_shader_parameter("room_darkness", _room_amount * MAX_DARKNESS)
	_material.set_shader_parameter("zone_darkness", _zone_amount * MAX_DARKNESS)
	_material.set_shader_parameter("light_radius", light_radius_screen() / _zoom())
	var player := _get_player()
	if player != null:
		# Local to this node, then relative to the overlay's corner (the
		# shader works in px from the overlay's top-left).
		_material.set_shader_parameter("light_center", to_local(player.global_position) - _overlay.position)


## Camera zoom as the viewport's canvas transform reports it (1 when no
## camera is active). A world px is `zoom` screen px, so a light's world
## radius is its screen radius / zoom.
func _zoom() -> float:
	var zoom := get_viewport().get_canvas_transform().get_scale().x
	return zoom if zoom > 0.01 else 1.0


## The player of THIS branch of the tree: the nearest "Player" child of
## an ancestor (Level01 in the full game, the launcher when standalone).
## A group lookup would be ambiguous whenever two levels are alive at once.
func _get_player() -> Node2D:
	if _player != null and is_instance_valid(_player):
		return _player
	var node := get_parent()
	while node != null:
		var found := node.get_node_or_null("Player") as Node2D
		if found != null:
			_player = found
			return _player
		node = node.get_parent()
	return null
