extends Node2D
## Last Signal — Medical Wing pain (P7, 2026-11-27).
##
## Story: the character wakes in pain and must find medicine. Until the
## medicine is collected, while the player is inside the room, the screen
## edges pulse dark: a slow vignette whose opacity swings 0 -> MAX_ALPHA -> 0
## every PULSE_PERIOD seconds. When the medicine is taken, relieve() makes it
## fade out over RELIEF_FADE_SECONDS, and it never comes back (not when the
## player leaves and re-enters, not ever).
##
## The opacity at any moment is
##   MAX_ALPHA x pulse(clock) x presence x (1 - relief)
## where `clock` is the seconds stepped so far, pulse() is a raised cosine
## (0 at clock 0, 1 at half a period), `presence` fades 0 <-> 1 over
## ENTER_FADE_SECONDS while the player is outside <-> inside the room's rect,
## and `relief` goes 0 -> 1 over RELIEF_FADE_SECONDS once relieve() was
## called. Everything runs from step(delta) (_process only forwards the
## frame time), so tests drive it with exact deltas: the same sequence of
## deltas always gives the same opacities.
##
## How it is drawn: one ColorRect in the WORLD canvas covering the room's
## rect plus MARGIN on every side, with a canvas_item shader
## (pain_medical_wing.gdshader, next to the room scene) that computes the
## vignette from the position ON SCREEN. The HUD is a CanvasLayer, which
## always draws above the world canvas, so the vignette can never cover it;
## a CanvasLayer of our own would have to share the HUD's layer 1 (an
## undefined draw order) or go above it. The visible part of the rect is
## read every frame from the viewport's canvas transform, so the effect
## follows the camera and its zoom. GL Compatibility only (UV and uniforms).
##
## Coordinates, like MedicalDarkness: the node sits at the room's own (0, 0),
## `room_rect` and the overlay are in the node's LOCAL space, and everything
## that touches the player goes through to_local, so it keeps working after
## the full-game flatten (level_01.gd moves this node into Level01 with
## position += the room's offset and frees the room). Nothing here refers to
## the room, and this node never touches the HUD.

const SHADER: Shader = preload("res://scenes/levels/rooms/medical_wing/pain_medical_wing.gdshader")
## Opacity of the vignette at the screen edge at the peak of a pulse.
const MAX_ALPHA := 0.35
## Seconds of one full pulse (clear -> darkest -> clear).
const PULSE_PERIOD := 2.5
## Seconds the vignette takes to fade in / out when the player enters /
## leaves the room.
const ENTER_FADE_SECONDS := 0.3
## Seconds the vignette takes to fade out for good once the medicine is taken.
const RELIEF_FADE_SECONDS := 1.5
## Colour of the vignette (a very dark red; its alpha is the script's).
const VIGNETTE_COLOR := Color(0.1, 0.0, 0.02)
## How far the covered rect reaches beyond the room's rect on every side, in
## world px: more than half a screen at zoom 1 (320 x 180), so it covers the
## whole view whenever the player is in the room.
const MARGIN := 340.0
## Above the world and above the darkness overlay (z_index 100), still a
## world-canvas item (so under every CanvasLayer, the HUD included).
const OVERLAY_Z_INDEX := 101

## The room's rect in THIS node's local space; set by MedicalWing before
## add_child (its own room_rect, which is local too).
var room_rect: Rect2 = Rect2(0, 0, 640, 368)
## True once relieve() was called (the medicine was taken).
var is_relieved: bool = false

var _clock: float = 0.0
var _presence: float = 0.0
var _relief: float = 0.0
var _alpha: float = 0.0
var _player: Node2D = null
var _overlay: ColorRect = null
var _material: ShaderMaterial = null


func _ready() -> void:
	z_index = OVERLAY_Z_INDEX
	# After the player and its camera have moved for the frame.
	process_priority = 100
	_overlay = ColorRect.new()
	_overlay.name = "Overlay"
	_overlay.position = room_rect.position - Vector2(MARGIN, MARGIN)
	_overlay.size = room_rect.size + Vector2(MARGIN, MARGIN) * 2.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter("rect_size", _overlay.size)
	_material.set_shader_parameter("vignette_color", VIGNETTE_COLOR)
	_overlay.material = _material
	add_child(_overlay)
	_apply()


func _process(delta: float) -> void:
	step(delta)


## True while the player is inside the room's rect.
func player_inside() -> bool:
	var player := _get_player()
	return player != null and room_rect.has_point(to_local(player.global_position))


## The medicine was taken: the vignette fades out over RELIEF_FADE_SECONDS
## and never returns. Calling it again does nothing.
func relieve() -> void:
	is_relieved = true


## True once the fade-out has finished: the pain is over for good.
func is_pain_over() -> bool:
	return _relief >= 1.0


## The pulse shape at `seconds`: 0 at 0, 1 at half a period, 0 at a full one.
func pulse_at(seconds: float) -> float:
	return 0.5 * (1.0 - cos(TAU * seconds / PULSE_PERIOD))


## Seconds stepped so far (it stops once the pain is over).
func clock() -> float:
	return _clock


## 0 .. 1: how much the vignette is shown for the player's position (fades
## over ENTER_FADE_SECONDS).
func presence() -> float:
	return _presence


## 0 .. 1: how far the fade-out after the medicine has gone.
func relief_amount() -> float:
	return _relief


## The vignette's opacity at the screen edge right now, 0 .. MAX_ALPHA.
func vignette_alpha() -> float:
	return _alpha


## Advance the clock and the fades by delta seconds and refresh the overlay.
## _process calls it every frame; tests call it directly for a deterministic
## clock (any delta, however large, gives the same result as the same time in
## smaller steps).
func step(delta: float) -> void:
	if _relief < 1.0:
		_clock += delta
		if is_relieved:
			_relief = move_toward(_relief, 1.0, delta / RELIEF_FADE_SECONDS)
		_presence = move_toward(_presence, 1.0 if player_inside() else 0.0, delta / ENTER_FADE_SECONDS)
		_alpha = MAX_ALPHA * pulse_at(_clock) * _presence * (1.0 - _relief)
	else:
		_presence = 0.0
		_alpha = 0.0
	_apply()


func _apply() -> void:
	if _overlay == null:
		return
	_overlay.visible = _alpha > 0.0
	_material.set_shader_parameter("strength", _alpha)
	# The part of the overlay the camera shows: the viewport's visible rect
	# through the inverse canvas transform (world px), then local to this
	# node, then relative to the overlay's corner (the shader works in px
	# from the overlay's top-left).
	var viewport := get_viewport()
	var seen: Rect2 = viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
	var corner := to_local(seen.position) - _overlay.position
	_material.set_shader_parameter("view_rect", Vector4(corner.x, corner.y, seen.size.x, seen.size.y))


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
