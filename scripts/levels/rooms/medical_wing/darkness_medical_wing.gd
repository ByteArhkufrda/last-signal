extends Node2D
## Last Signal — Medical Wing darkness (P2, 2026-11-24; port of step 4)
## and power state (P3, 2026-11-24; port of step 5).
##
## The game starts with the power OUT: while power is off AND the player
## is inside the medical room's rect, the room is dark except a soft
## circular flashlight around the player. restore_power() fades the
## darkness out (about 1 s); a puzzle will call it in a later step.
##
## How it is drawn: one ColorRect that covers exactly the room's rect
## (so no other room is ever darkened), with a canvas_item shader that
## cuts a soft hole around the player (darkness_medical_wing.gdshader, next
## to the room scene). A high z_index keeps it above the world; the HUD
## is a CanvasLayer, which always draws above the world, so the HUD is
## never darkened either. No CanvasModulate.
##
## Coordinates (this is what keeps it right after the flatten): the node
## sits at the room's own (0, 0), `room_rect` and the overlay are in the
## node's LOCAL space, and everything that touches the player goes
## through this node's own transform (to_local). Standalone the node is
## at (0, 0); in the full game level_01.gd _flatten_rooms moves it into
## Level01 with position += the room's offset, and the overlay (a child)
## travels with it — no offset is ever written in this file.
##
## Where the state lives: the assembler frees the MedicalWing node and
## keeps its children, so in the full game THIS node —
## level.get_node("MedicalDarkness") — is what stays alive.
## MedicalWing.power_on / power_restored / restore_power() are a facade
## over it (they work in the standalone room); the puzzle that restores
## power in the full game has to call restore_power() on this node.
##
## Dormant robots (P3): while the power is off, every enemy under this
## node's parent whose position is inside the room's rect gets
## `dormant = true` (see security_robot_medical_wing.gd) and does
## nothing; restore_power() wakes them at once. Only enemies of the same
## branch are touched (two levels alive at once never fight over each
## other's robots), and only enemies that HAVE a `dormant` flag: the
## other rooms' robots are their own per-room copies and stay as they are.
##
## The placeholder power switch (P3): a console that the room hands to
## bind_switch(); its first use calls restore_power(). The HUD text comes
## from the console's own message, shown by the level's wiring.

## Emitted once, by the first restore_power().
signal power_restored

const SHADER: Shader = preload("res://scenes/levels/rooms/medical_wing/darkness_medical_wing.gdshader")
## Flashlight radius in SCREEN px at the 640x360 base resolution. The
## player camera zooms 2x, so the radius in world px is this / zoom.
const LIGHT_RADIUS_SCREEN := 70.0
## Opacity of the darkness outside the light (1.0 would be pure black).
const MAX_DARKNESS := 0.95
## Fade seconds when the player enters / leaves the room.
const ROOM_FADE_SECONDS := 0.25
## Fade seconds of the darkness after restore_power().
const POWER_FADE_SECONDS := 1.0
const OVERLAY_Z_INDEX := 100
## AudioManager sound played when the power returns (the same chime as a
## solved puzzle); looked up through the "audio" group, so it is silent
## wherever there is no AudioManager (level-only tests, the standalone
## room). Read-only use of the group: nothing shared is touched.
const POWER_SOUND := "chime"

## The room's rect in THIS node's local space; set by MedicalWing before
## add_child (its own room_rect, which is local too).
var room_rect: Rect2 = Rect2(0, 0, 640, 368)
var power_on: bool = false

var _amount: float = 0.0
var _fade_seconds: float = ROOM_FADE_SECONDS
var _player: Node2D = null
var _overlay: ColorRect = null
var _material: ShaderMaterial = null
var _switch: Node2D = null


func _ready() -> void:
	z_index = OVERLAY_Z_INDEX
	# After the player and its camera have moved for the frame.
	process_priority = 100
	_overlay = ColorRect.new()
	_overlay.name = "Overlay"
	_overlay.position = room_rect.position
	_overlay.size = room_rect.size
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter("rect_size", room_rect.size)
	_overlay.material = _material
	add_child(_overlay)
	_apply()
	# Robots in the dark room are off from the very first physics tick.
	_update_dormancy()


func _process(delta: float) -> void:
	step(delta)


## True while the room should be dark: power off AND the player inside
## the room's rect. (The visible fade lags behind this; see darkness().)
func is_dark() -> bool:
	if power_on:
		return false
	var player := _get_player()
	return player != null and room_rect.has_point(to_local(player.global_position))


## Current darkness, 0 (none) .. 1 (full), including the fades.
func darkness() -> float:
	return _amount


## Power is back: the darkness fades out over POWER_FADE_SECONDS and
## never returns, the robots in the room wake up, the power switch is
## used up and the chime plays. Calling it again does nothing.
func restore_power() -> void:
	if power_on:
		return
	power_on = true
	_fade_seconds = POWER_FADE_SECONDS
	_update_dormancy()
	_retire_switch()
	_play_chime()
	power_restored.emit()


## Hand over the placeholder power switch (a console): using it restores
## the power. Called by MedicalWing right after it builds the console.
func bind_switch(switch_console: Node2D) -> void:
	_switch = switch_console
	switch_console.interacted.connect(_on_switch_interacted)


## Advance the fade by delta seconds and refresh the overlay. _process
## calls it every frame; tests call it directly for deterministic fades.
func step(delta: float) -> void:
	var target := 1.0 if is_dark() else 0.0
	_amount = move_toward(_amount, target, delta / _fade_seconds)
	_apply()
	_update_dormancy()


func _on_switch_interacted(_console: Node2D) -> void:
	restore_power()


## The switch works once: after the power is back (by the switch or by
## anything else) it leaves the "interactable" group, so the player never
## targets it again and nothing happens on E. The player un-highlights it
## and hides the prompt on its own next frame.
func _retire_switch() -> void:
	if _switch != null and is_instance_valid(_switch):
		_switch.remove_from_group("interactable")


func _play_chime() -> void:
	var audio: Node = get_tree().get_first_node_in_group("audio")
	if audio != null and audio.has_method("play"):
		audio.play(POWER_SOUND)


## Robots inside the room's rect are dormant while the power is off. A
## robot that walks in (a chaser from the next room, say) freezes where it
## crosses the line; one that is awake outside is untouched. The rect is
## local, so the position goes through to_local like the player's.
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
	_overlay.visible = _amount > 0.0
	_material.set_shader_parameter("darkness", _amount * MAX_DARKNESS)
	_material.set_shader_parameter("light_radius", LIGHT_RADIUS_SCREEN / _zoom())
	var player := _get_player()
	if player != null:
		# Local to this node, then relative to the overlay's corner (the
		# shader works in px from the overlay's top-left).
		_material.set_shader_parameter("light_center", to_local(player.global_position) - _overlay.position)


## Camera zoom as the viewport's canvas transform reports it (1 when no
## camera is active). A world px is `zoom` screen px, so the light's
## world radius is LIGHT_RADIUS_SCREEN / zoom.
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
