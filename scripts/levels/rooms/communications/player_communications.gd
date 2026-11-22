## Per-room copy (absolute separation, 2026-11-23): identical to the shared original; only paths point at this room's own copies.
extends CharacterBody2D
## Last Signal — Player controller (Phase 1 + Phase 2, animation rework 2026-11-12).
##
## Pattern (GodotPrompter player-controller + awesome-gamedev godot-2d-movement):
## top-down CharacterBody2D, MOTION_MODE_FLOATING, accel/friction in
## _physics_process, Input.get_vector over custom move_* actions, move_and_slide().
## Rejected alternative: instant velocity = input * speed (no accel/friction,
## feels stiff) and using built-in ui_* actions (conflicts with UI navigation later).
##
## Phase 6 additions (Energy and Inventory):
## - Battery: max 100, passive drain 0.5/s, radar pulse costs 15 (the cost
##   deferred from Phase 4). Below the cost the pulse is blocked with a HUD
##   message. At 0 the radar is dead but movement is unaffected (no fail
##   state yet — that comes with Phase 9 menus).
## - Inventory: a plain Dictionary {item_id: count}. Consumables apply
##   their effect immediately on pickup AND are counted, because Phase 7
##   puzzles will need non-consumable items too. Rejected alternative:
##   Resource-based items + capacity limits (awesome-gamedev
##   survival-crafting points at godot-resources for that) — overkill for
##   2 consumables; revisit when puzzle items arrive in Phase 7.
##
## Phase 4 additions (Radar Pulse):
## - Q emits an expanding ring (scenes/systems/radar_pulse.tscn). Cooldown
##   5 s, max radius 160 px, expand 320 px/s (reaches max in 0.5 s).
## - Battery cost (Phase 6, implemented): each pulse costs 15 battery and
##   is blocked below that. (This comment previously said the cost was
##   deferred — it was added in Phase 6; fixed 2026-11-12.)
## - Investigation hook for Phase 5: signal pulse_emitted(origin, radius).
##   Enemies connect to it and investigate the origin. The pulse itself
##   does not know about enemies.
##
## Phase 3 additions (interaction):
## - Interaction is distance-based: the nearest node in group "interactable"
##   within INTERACT_RANGE is the current target; E (action "interact")
##   calls its interact(). Rejected alternative: Area2D overlap detection
##   (GodotPrompter component-system InteractableComponent) — more moving
##   parts (layers, overlap edge cases) for 3-5 interactables; distance
##   checks are simpler and fully testable headless. Revisit if the count
##   grows (Phase 8 towers, Phase 5 enemies).
## - HUD is looked up lazily via group "hud" and may be absent (level tests
##   load the level without the Main scene); all HUD calls are null-guarded.
##
## Animation rework (2026-11-12, replaces the Phase 2 procedural bob as the
## sole walk visual — the bob is kept as a 1 px supplement, not the walk):
## - AnimatedSprite2D + SpriteFrames built in code (same pattern as the
##   code-built floor TileSet in level_01.gd: no hand-authored .tres).
## - 8 animations: idle_down/up/left/right (1 frame) and
##   walk_down/up/left/right (4 frames each, 8 FPS). Direction comes from
##   the post-collision velocity, so pushing into a wall stops the walk
##   animation instead of moonwalking. Facing is remembered when idle.
## - Diagonal movement picks the dominant axis (see _dominant_direction),
##   so diagonals use a cardinal animation and never speed up.
## - Frames: the atlas has NO walk frames for this character (full-atlas
##   search 2026-11-12: 17 "walking scientist" rows, all single standing
##   poses, 0 sprite sheets). The walk frames are drawn from the player's
##   own 16x16 sprite (atlas row 952623) by moving only its leg pixels
##   (rows 13-15) 1 px per pose; the up frames additionally recolour the
##   face to hair (back view of the same character). No unrelated
##   character was substituted. Left/right share the down frames with
##   flip_h — the atlas has no side/profile frames either. See
##   docs/KNOWN_ISSUES.md for the exact limitation.
## - Phase 2 additions (GodotPrompter camera-system + animation-system):
## - Movement state is a plain bool (is_moving). Rejected: a full state-machine
##   node for two states (idle/moving) — that comes with enemy AI in Phase 5.
## - Walk bob is code-driven (sin on distance moved), NOT an AnimationPlayer
##   clip: the atlas has no walk frames, and a keyframed clip would need art
##   that does not exist. Honest placeholder until real walk sprites exist.
## - Camera look-ahead: Camera2D.offset lerped toward the movement direction
##   (adapted from the camera-system manual-follow pattern; the camera stays
##   a child of the player, so no separate follow script is needed).

@export var speed: float = 200.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0
@export var stop_speed: float = 8.0
@export var bob_amplitude: float = 1.0
@export var bob_cycles_per_pixel: float = 0.35
@export var look_ahead_distance: float = 24.0
@export var look_ahead_speed: float = 4.0
@export var radar_cooldown: float = 5.0
@export var radar_max_radius: float = 160.0
@export var radar_expand_speed: float = 320.0
@export var max_battery: float = 100.0
@export var passive_drain: float = 0.5
@export var radar_cost: float = 15.0
## Walk-cycle playback speed (frames per second). 8 FPS is the middle of
## the 6-10 FPS pixel-art range; at speed 200 px/s a step lands about
## every 25 px of travel, so there is no visible foot sliding.
@export var walk_fps: float = 8.0

## Emitted when a pulse goes out — the investigation hook for Phase 5 enemies.
signal pulse_emitted(origin: Vector2, max_radius: float)

## True while the body is actually moving (after collision resolution).
var is_moving: bool = false

## Last cardinal facing direction ("down", "up", "left", "right").
## Idle animations use this, so stopping keeps the direction faced.
var facing_direction: String = "down"

## Pulses emitted so far (test hook).
var pulses_emitted: int = 0

## Current battery charge (0..max_battery).
var battery: float = 100.0

## Inventory: {item_id: count}.
var inventory: Dictionary = {}

const ITEM_DISPLAY := {"energy_cell": "سلول انرژی", "battery": "باتری", "fuse": "فیوز"}

## Nearest interactable in range right now (null when none).
var _current_interactable: Node = null

const INTERACT_RANGE: float = 40.0
const WALK_FRAME_PATHS := {
	"down": ["res://assets/sprites/characters/player_walk/walk_down_0.png", "res://assets/sprites/characters/player_walk/walk_down_1.png", "res://assets/sprites/characters/player_walk/walk_down_2.png", "res://assets/sprites/characters/player_walk/walk_down_3.png"],
	"up": ["res://assets/sprites/characters/player_walk/walk_up_0.png", "res://assets/sprites/characters/player_walk/walk_up_1.png", "res://assets/sprites/characters/player_walk/walk_up_2.png", "res://assets/sprites/characters/player_walk/walk_up_3.png"],
}

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D

var _bob_phase: float = 0.0
var _sprite_base_y: float = 0.0
## Position on the previous physics frame, for the real (post-collision)
## velocity. Godot's move_and_slide does NOT zero `velocity` when the
## body slides along a wall (measured 2026-11-12: velocity stayed
## (-200, 0) while the player was pressed against the west wall), so
## is_moving and the walk bob must use actual displacement, not the
## requested velocity — otherwise the walk animation plays while the
## player is stuck against a wall.
var _prev_position: Vector2 = Vector2.ZERO
var _real_velocity: Vector2 = Vector2.ZERO
var _hud: CanvasLayer = null
var _pulse_cooldown_remaining: float = 0.0
var _last_radar_status: String = ""
var _low_battery_warned: bool = false

const RADAR_PULSE_SCENE: PackedScene = preload("res://scenes/levels/rooms/communications/radar_pulse_communications.tscn")


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_build_sprite_frames()
	_sprite_base_y = sprite.position.y
	_prev_position = global_position
	sprite.play("idle_down")


func _physics_process(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var target: Vector2 = compute_target_velocity(input_dir, speed)
	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(target, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		if velocity.length() < stop_speed:
			velocity = Vector2.ZERO
	move_and_slide()
	if delta > 0.0:
		_real_velocity = (global_position - _prev_position) / delta
	_prev_position = global_position
	is_moving = _real_velocity.length() > 10.0
	_update_animation()
	_update_interaction()
	_update_radar(delta)
	_update_battery(delta)
	_update_bob(delta)
	_update_look_ahead(delta)


## Builds the 8-animation SpriteFrames from the walk-frame PNGs. Runs once
## in _ready; no textures are loaded per frame. Left/right reuse the down
## frames (flipped at runtime) — the atlas has no side-profile frames.
func _build_sprite_frames() -> void:
	var frames := SpriteFrames.new()
	for dir in ["down", "up", "left", "right"]:
		var base_paths: Array = WALK_FRAME_PATHS["up" if dir == "up" else "down"]
		frames.add_animation("idle_" + dir)
		frames.set_animation_loop("idle_" + dir, true)
		frames.set_animation_speed("idle_" + dir, walk_fps)
		frames.add_frame("idle_" + dir, load(base_paths[0]))
		frames.add_animation("walk_" + dir)
		frames.set_animation_loop("walk_" + dir, true)
		frames.set_animation_speed("walk_" + dir, walk_fps)
		for path in base_paths:
			frames.add_frame("walk_" + dir, load(path))
	sprite.sprite_frames = frames


## Animation state lives here, separate from movement: direction comes
## from the post-collision velocity, facing is remembered when idle, and
## play() is only called when the animation actually changes (replaying
## every frame would restart the cycle and stutter).
func _update_animation() -> void:
	var wanted: String
	if is_moving:
		facing_direction = _dominant_direction(velocity)
		wanted = "walk_" + facing_direction
	else:
		wanted = "idle_" + facing_direction
	sprite.flip_h = facing_direction == "left"
	if sprite.animation != wanted or not sprite.is_playing():
		sprite.play(wanted)


## Dominant axis wins, so diagonals get a consistent cardinal animation.
## Ties (|x| == |y|) prefer the horizontal axis.
static func _dominant_direction(v: Vector2) -> String:
	if absf(v.x) >= absf(v.y):
		return "right" if v.x > 0.0 else "left"
	return "down" if v.y > 0.0 else "up"


func _update_battery(delta: float) -> void:
	battery = maxf(battery - passive_drain * delta, 0.0)
	if battery <= 25.0 and not _low_battery_warned:
		_low_battery_warned = true
		var hud := _get_hud()
		if hud != null:
			hud.show_message("باتری کم است!")
	elif battery > 30.0:
		_low_battery_warned = false
	var hud2 := _get_hud()
	if hud2 != null:
		hud2.set_battery(battery, max_battery)


func add_item(item_id: String, amount: int, battery_restore: float) -> void:
	inventory[item_id] = int(inventory.get(item_id, 0)) + amount
	if battery_restore > 0.0:
		battery = minf(max_battery, battery + battery_restore)
	_update_inventory_hud()


func remove_item(item_id: String, amount: int) -> void:
	var count: int = int(inventory.get(item_id, 0)) - amount
	if count <= 0:
		inventory.erase(item_id)
	else:
		inventory[item_id] = count
	_update_inventory_hud()


func _update_inventory_hud() -> void:
	var hud := _get_hud()
	if hud == null:
		return
	if inventory.is_empty():
		hud.set_inventory_text("وسایل: —")
		return
	var parts: Array[String] = []
	for item_id in inventory.keys():
		var label: String = ITEM_DISPLAY.get(item_id, item_id)
		parts.append("%s ×%d" % [label, int(inventory[item_id])])
	hud.set_inventory_text("وسایل: " + ", ".join(parts))


func _update_radar(delta: float) -> void:
	if _pulse_cooldown_remaining > 0.0:
		_pulse_cooldown_remaining = maxf(_pulse_cooldown_remaining - delta, 0.0)
	if Input.is_action_just_pressed("radar_pulse"):
		_emit_radar_pulse()
	var hud := _get_hud()
	if hud != null:
		var status := "رادار [Q] آماده است" if _pulse_cooldown_remaining <= 0.0 else "شارژ رادار… %d ثانیه" % ceili(_pulse_cooldown_remaining)
		if status != _last_radar_status:
			_last_radar_status = status
			hud.set_radar_status(status)


func _emit_radar_pulse() -> void:
	if _pulse_cooldown_remaining > 0.0:
		return
	if battery < radar_cost:
		var hud := _get_hud()
		if hud != null:
			hud.show_message("باتری برای رادار کم است.")
		return
	battery -= radar_cost
	_pulse_cooldown_remaining = radar_cooldown
	var pulse: Node2D = RADAR_PULSE_SCENE.instantiate()
	pulse.max_radius = radar_max_radius
	pulse.expand_speed = radar_expand_speed
	get_parent().add_child(pulse)
	pulse.global_position = global_position
	pulses_emitted += 1
	pulse_emitted.emit(global_position, radar_max_radius)
	_play_sound("pulse")


func _update_interaction() -> void:
	var nearest: Node = _find_nearest_interactable()
	if nearest != _current_interactable:
		if _current_interactable != null and _current_interactable.has_method("set_highlighted"):
			_current_interactable.set_highlighted(false)
		_current_interactable = nearest
		if nearest != null and nearest.has_method("set_highlighted"):
			nearest.set_highlighted(true)
	var hud := _get_hud()
	if nearest != null:
		if hud != null:
			hud.show_prompt("E — " + str(nearest.get("interact_label")))
		if Input.is_action_just_pressed("interact") and nearest.has_method("interact"):
			nearest.interact()
	elif hud != null:
		hud.hide_prompt()


func _find_nearest_interactable() -> Node:
	var best: Node = null
	var best_dist := INTERACT_RANGE
	for node in get_tree().get_nodes_in_group("interactable"):
		var d := global_position.distance_to((node as Node2D).global_position)
		if d < best_dist and _has_line_of_sight(node as Node2D):
			best_dist = d
			best = node
	return best


## True when no wall stands between the player and the target — the
## same wall-layer raycast the robots and the radar pulse use
## (2026-11-19: the FuseBox was reachable from the Laboratory, 39 px
## away through the divider wall). The target's own body is excluded,
## and so are the bodies of its assembly: the panel switches sit ON
## the panel's body, so a ray to a switch must not stop at the panel.
func _has_line_of_sight(target: Node2D) -> bool:
	var exclude: Array[RID] = [get_rid()]
	var node: Node = target
	while node != null:
		if node is CollisionObject2D:
			exclude.append((node as CollisionObject2D).get_rid())
		node = node.get_parent()
	for desc in target.find_children("*", "CollisionObject2D", true, false):
		exclude.append((desc as CollisionObject2D).get_rid())
	var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 1)
	query.exclude = exclude
	var result := get_world_2d().direct_space_state.intersect_ray(query)
	return result.is_empty()


func _get_hud() -> CanvasLayer:
	if _hud == null:
		_hud = get_tree().get_first_node_in_group("hud")
	return _hud


func _play_sound(sound_name: String) -> void:
	var audio: Node = get_tree().get_first_node_in_group("audio")
	if audio != null:
		audio.play(sound_name)


func _update_bob(delta: float) -> void:
	if is_moving:
		_bob_phase += _real_velocity.length() * delta * bob_cycles_per_pixel
		sprite.position.y = _sprite_base_y + sin(_bob_phase) * bob_amplitude
	else:
		sprite.position.y = _sprite_base_y


func _update_look_ahead(delta: float) -> void:
	var desired := Vector2.ZERO
	if velocity.length() > 20.0:
		desired = velocity.normalized() * look_ahead_distance
	camera.offset = camera.offset.lerp(desired, look_ahead_speed * delta)


## Pure helper, unit-tested by scripts/tests/test_runner.gd.
static func compute_target_velocity(input_dir: Vector2, p_speed: float) -> Vector2:
	return input_dir * p_speed
