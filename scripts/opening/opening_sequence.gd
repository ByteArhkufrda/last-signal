class_name OpeningSequence
extends Node2D
## Last Signal — opening sequence: Emergency Power Restoration.
##
## Side-view opening aboard the damaged station. The player wakes up in
## the medical section with no memory, explores a dim room with a
## flashlight, reads the emergency manual (Q), finds the damaged power
## panel, solves a circuit puzzle (E) and restores power. In the full
## game the scene then continues into the main scene; in this standalone
## build it ends on an end card instead (see _run_restoration).
##
## Flow (state machine): WAKE (fade-in + caption, controls locked) ->
## EXPLORE (manual hint, panel prompt) -> RESTORING (gradual lighting
## return, monitors on, door unlock) -> main.tscn (full game) or end card
## (standalone build). The manual and the
## puzzle are overlays that lock movement while open; the orchestrator
## alone routes Q / E / Escape so the overlays never fight each other.
##
## Everything visual is built here in code from existing art (medical
## pack, floor/wall atlases, player sprite); sounds are generated in
## code by OpeningAudio. No existing gameplay file is touched.

const ROOM_WIDTH := 640
const ROOM_HEIGHT := 240
const FLOOR_TOP := 200
const CAMERA_ZOOM := 1.5

const PLAYER_TEXTURE: Texture2D = preload("res://assets/sprites/characters/player_side.png")
const BED_TEXTURE: Texture2D = preload("res://assets/sprites/medical-wing/bed_standard.png")
const BED_EMPTY_TEXTURE: Texture2D = preload("res://assets/sprites/medical-wing/bed_empty.png")
const BED_MESSY_TEXTURE: Texture2D = preload("res://assets/sprites/medical-wing/bed_disorganized.png")
const MONITOR_VITALS_TEXTURE: Texture2D = preload("res://assets/sprites/medical-wing/monitor_vitals.png")
const MONITOR_HEART_TEXTURE: Texture2D = preload("res://assets/sprites/medical-wing/monitor_heart.png")
const CABINET_TEXTURE: Texture2D = preload("res://assets/sprites/medical-wing/cabinet_medicine.png")
const SHELF_TEXTURE: Texture2D = preload("res://assets/sprites/medical-wing/shelf_medicine.png")
const TROLLEY_TEXTURE: Texture2D = preload("res://assets/sprites/medical-wing/trolley.png")
const DESK_TEXTURE: Texture2D = preload("res://assets/sprites/medical-wing/desk_doctor.png")
const CHAIR_TEXTURE: Texture2D = preload("res://assets/sprites/medical-wing/chair_office.png")
const DOOR_CLOSED_TEXTURE: Texture2D = preload("res://assets/sprites/medical-wing/door_closed.png")
const DOOR_OPEN_TEXTURE: Texture2D = preload("res://assets/sprites/medical-wing/door_open.png")
const FLOOR_ATLAS: Texture2D = preload("res://assets/sprites/environment/floor_medical_atlas.png")
const WALL_TEXTURE: Texture2D = preload("res://assets/sprites/environment/wall_metal.png")

const DIM_COLOR := Color(0.45, 0.47, 0.55)
const LIT_COLOR := Color(0.95, 0.95, 1.0)

enum State { WAKE, EXPLORE, RESTORING, DONE }

var _state: int = State.WAKE
var _player: SidePlayer
var _flashlight: Flashlight
var _panel: PowerPanel
var _audio: OpeningAudio
var _manual: EmergencyManual
var _puzzle_ui: CircuitPuzzleUI
var _modulate: CanvasModulate
var _elapsed := 0.0
var _restored := false

var _caption: Label
var _manual_hint: PanelContainer
var _prompt: Label
var _notification: Label
var _fade_rect: ColorRect
var _end_label: Label
var _can_exit := false
var _lights: Array[PointLight2D] = []
var _monitors: Array[Sprite2D] = []
var _monitor_screens: Array[Sprite2D] = []
var _diag_label: Label
var _door_sprite: Sprite2D
var _door_light: PointLight2D


func _ready() -> void:
	_build_room()
	_build_player()
	_build_hud()
	_audio = OpeningAudio.new()
	add_child(_audio)
	_manual = load("res://scenes/opening/emergency_manual.tscn").instantiate()
	$HUD.add_child(_manual)
	_manual.closed.connect(_on_manual_closed)
	_puzzle_ui = load("res://scenes/opening/circuit_puzzle_ui.tscn").instantiate()
	$HUD.add_child(_puzzle_ui)
	_puzzle_ui.audio = _audio
	_puzzle_ui.closed.connect(_on_puzzle_closed)
	_puzzle_ui.solved.connect(_on_puzzle_solved)
	_run_wake()


func _process(delta: float) -> void:
	_elapsed += delta
	if _flashlight != null and _player != null:
		_flashlight.set_facing(_player.facing)
	if not _restored:
		# Emergency lights flicker: a slow wobble plus occasional
		# dropouts, each light on its own phase.
		for i in _lights.size():
			var light := _lights[i]
			var phase := _elapsed * 9.0 + float(i) * 2.4
			var level := 0.62 + 0.28 * sin(phase) + 0.1 * sin(phase * 2.7)
			if fposmod(_elapsed + float(i) * 3.1, 7.0) < 0.18:
				level = 0.15
			light.energy = clampf(level, 0.1, 1.0)
		if randf() < delta * 0.4:
			_audio.play("buzz")
	if _state == State.EXPLORE and _panel != null and _player != null:
		_prompt.visible = _panel.is_player_near(_player.global_position)


func _unhandled_input(event: InputEvent) -> void:
	if _can_exit:
		# End card is showing: any key or click quits the game.
		if event is InputEventKey and event.pressed and not event.echo:
			get_tree().quit()
		elif event is InputEventMouseButton and event.pressed:
			get_tree().quit()
		return
	if _state != State.EXPLORE:
		return
	if event.is_action_pressed("manual"):
		if _manual.is_open():
			_manual.close()
			_audio.play("manual_close")
			_player.controls_locked = false
		elif not _puzzle_ui.is_open():
			_manual.open()
			_audio.play("manual_open")
			_player.controls_locked = true
			_manual_hint.visible = false
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		# Escape closes the manual. (Escape inside the puzzle is
		# handled by the puzzle UI itself, which marks it handled.)
		if _manual.is_open():
			_manual.close()
			_audio.play("manual_close")
			_player.controls_locked = false
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		if not _manual.is_open() and not _puzzle_ui.is_open() and _panel.is_player_near(_player.global_position):
			_puzzle_ui.open()
			_player.controls_locked = true
			get_viewport().set_input_as_handled()


func _on_manual_closed() -> void:
	_player.controls_locked = false


func _on_puzzle_closed() -> void:
	if _state == State.EXPLORE:
		_player.controls_locked = false


func _on_puzzle_solved() -> void:
	if _state != State.EXPLORE:
		return
	_state = State.RESTORING
	_puzzle_ui.close()
	_player.controls_locked = true
	_prompt.visible = false
	_run_restoration()


func _run_wake() -> void:
	_player.controls_locked = true
	_audio.start_ambient()
	_audio.play("alarm")
	var tw := create_tween()
	tw.tween_property(_fade_rect, "modulate:a", 0.0, 1.2)
	await get_tree().create_timer(1.4).timeout
	if not is_inside_tree():
		return
	_caption.text = "You wake up in a hospital bed.\nYou don't remember who you are — or how you got here."
	_fade_label(_caption, true)
	await get_tree().create_timer(3.0).timeout
	if not is_inside_tree():
		return
	_fade_label(_caption, false)
	await get_tree().create_timer(0.6).timeout
	if not is_inside_tree():
		return
	_state = State.EXPLORE
	_player.controls_locked = false
	_manual_hint.visible = true
	_manual_hint.modulate.a = 0.0
	var hint_tw := create_tween()
	hint_tw.tween_property(_manual_hint, "modulate:a", 1.0, 0.6)


func _run_restoration() -> void:
	# Step 1-2: the panel already showed the current flow; now it
	# reports the restored state.
	_panel.set_restored()
	# Step 3: smooth lighting return — never an instant switch.
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_modulate, "color", LIT_COLOR, 2.5)
	for light in _lights:
		tw.tween_property(light, "energy", 0.45, 2.5)
	for monitor in _monitors:
		tw.tween_property(monitor, "modulate", Color.WHITE, 1.5)
	_restored = true
	await get_tree().create_timer(1.2).timeout
	if not is_inside_tree():
		return
	for screen in _monitor_screens:
		screen.visible = true
	_diag_label.visible = true
	# Step 4: narrative feedback.
	_notification.text = "Medical Section Power Restored."
	_fade_label(_notification, true)
	# The east door receives power and unlocks.
	_door_sprite.texture = DOOR_OPEN_TEXTURE
	_door_light.color = Color(0.4, 1.0, 0.55)
	_door_light.energy = 0.5
	await get_tree().create_timer(2.6).timeout
	if not is_inside_tree():
		return
	_state = State.DONE
	var fade_tw := create_tween()
	fade_tw.tween_property(_fade_rect, "modulate:a", 1.0, 0.8)
	await fade_tw.finished
	if not is_inside_tree():
		return
	# Standalone build: the full game would continue into main.tscn
	# here, but main.tscn is excluded from this export — show the end
	# card and wait for any key to quit (see _unhandled_input).
	_end_label.visible = true
	_can_exit = true


func _fade_label(label: Label, show: bool) -> void:
	if show:
		label.visible = true
		label.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(label, "modulate:a", 1.0, 0.5)
	else:
		var tw := create_tween()
		tw.tween_property(label, "modulate:a", 0.0, 0.5)
		tw.tween_callback(func() -> void: label.visible = false)


## Stamps one 16x16 atlas tile across a rectangle into a single texture.
func _stamp_tiles(atlas: Texture2D, tile: Rect2i, width: int, height: int) -> ImageTexture:
	var source := atlas.get_image()
	# blit_rect requires matching formats; the wall atlas is RGB.
	if source.get_format() != Image.FORMAT_RGBA8:
		source.convert(Image.FORMAT_RGBA8)
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in range(0, height, 16):
		for x in range(0, width, 16):
			image.blit_rect(source, tile, Vector2i(x, y))
	return ImageTexture.create_from_image(image)


func _build_room() -> void:
	_modulate = CanvasModulate.new()
	_modulate.name = "CanvasModulate"
	_modulate.color = DIM_COLOR
	add_child(_modulate)
	# Back wall and floor, stamped from the existing atlases.
	var wall := Sprite2D.new()
	wall.name = "BackWall"
	wall.texture = _stamp_tiles(WALL_TEXTURE, Rect2i(0, 0, 16, 16), ROOM_WIDTH, FLOOR_TOP)
	wall.centered = false
	wall.position = Vector2.ZERO
	wall.modulate = Color(0.72, 0.74, 0.82)
	add_child(wall)
	var floor := Sprite2D.new()
	floor.name = "Floor"
	floor.texture = _stamp_tiles(FLOOR_ATLAS, Rect2i(64, 0, 16, 16), ROOM_WIDTH, ROOM_HEIGHT - FLOOR_TOP)
	floor.centered = false
	floor.position = Vector2(0, FLOOR_TOP)
	floor.modulate = Color(0.78, 0.8, 0.86)
	add_child(floor)
	# Collision: floor + end walls.
	var floor_body := StaticBody2D.new()
	floor_body.name = "FloorBody"
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var floor_shape := CollisionShape2D.new()
	var floor_rect := RectangleShape2D.new()
	floor_rect.size = Vector2(ROOM_WIDTH, ROOM_HEIGHT - FLOOR_TOP)
	floor_shape.shape = floor_rect
	floor_shape.position = Vector2(ROOM_WIDTH * 0.5, FLOOR_TOP + (ROOM_HEIGHT - FLOOR_TOP) * 0.5)
	floor_body.add_child(floor_shape)
	add_child(floor_body)
	for x in [8.0, ROOM_WIDTH - 8.0]:
		var wall_body := StaticBody2D.new()
		wall_body.collision_layer = 1
		wall_body.collision_mask = 0
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(16, ROOM_HEIGHT)
		shape.shape = rect
		shape.position = Vector2(x, ROOM_HEIGHT * 0.5)
		wall_body.add_child(shape)
		add_child(wall_body)
	# The ward: six beds in two rows of three. The back row sits
	# higher and darker (further from the viewer); the front row sits
	# on the floor, staggered so both rows read. The player wakes
	# beside the front-middle bed. Beds are scenery: the player walks
	# the aisle in front of them, so they carry no collision.
	var back_row := Color(0.7, 0.7, 0.72)
	_add_prop(BED_MESSY_TEXTURE, Vector2(84, FLOOR_TOP - 22), "BedBack1", back_row)
	_add_prop(BED_TEXTURE, Vector2(148, FLOOR_TOP - 22), "BedBack2", back_row)
	_add_prop(BED_EMPTY_TEXTURE, Vector2(212, FLOOR_TOP - 22), "BedBack3", back_row)
	_add_prop(BED_EMPTY_TEXTURE, Vector2(108, FLOOR_TOP - 8), "BedFront1")
	_add_prop(BED_TEXTURE, Vector2(172, FLOOR_TOP - 8), "BedWake")
	_add_prop(BED_MESSY_TEXTURE, Vector2(236, FLOOR_TOP - 8), "BedFront3")
	# Monitors above the ward (dark until power returns) with screens
	# and a diagnostics line that only appear after restoration.
	_add_monitor(MONITOR_VITALS_TEXTURE, Vector2(100, 156))
	_add_monitor(MONITOR_HEART_TEXTURE, Vector2(210, 156))
	# Medicine area: cabinets, shelf and the medicine trolley.
	_add_prop(CABINET_TEXTURE, Vector2(292, FLOOR_TOP - 8), "CabinetMedicine")
	_add_prop(SHELF_TEXTURE, Vector2(322, FLOOR_TOP - 8), "ShelfMedicine")
	_add_prop(TROLLEY_TEXTURE, Vector2(354, FLOOR_TOP - 8), "MedicineTrolley")
	# Nurse station: desk, chair and a monitor on the desk.
	_add_prop(DESK_TEXTURE, Vector2(410, FLOOR_TOP - 8), "NurseDesk")
	_add_prop(CHAIR_TEXTURE, Vector2(438, FLOOR_TOP - 8), "NurseChair")
	_add_monitor(MONITOR_VITALS_TEXTURE, Vector2(404, 170))
	_diag_label = Label.new()
	_diag_label.name = "DiagnosticsLabel"
	_diag_label.text = "SYS DIAG // O2 98% // PWR NOMINAL"
	_diag_label.position = Vector2(360, 148)
	_diag_label.add_theme_font_size_override("font_size", 8)
	_diag_label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.6))
	_diag_label.visible = false
	add_child(_diag_label)
	# Emergency lights on the ceiling (flicker until restored).
	_add_emergency_light(Vector2(200, 24), Color(1.0, 0.3, 0.25))
	_add_emergency_light(Vector2(450, 24), Color(1.0, 0.65, 0.25))
	# The damaged power panel and the locked east door.
	_panel = PowerPanel.new()
	_panel.name = "PowerPanel"
	_panel.position = Vector2(540, FLOOR_TOP)
	add_child(_panel)
	_door_sprite = Sprite2D.new()
	_door_sprite.name = "ExitDoor"
	_door_sprite.texture = DOOR_CLOSED_TEXTURE
	_door_sprite.scale = Vector2(1, 2)
	_door_sprite.position = Vector2(610, FLOOR_TOP - 16)
	add_child(_door_sprite)
	_door_light = PointLight2D.new()
	_door_light.name = "DoorLight"
	_door_light.position = Vector2(610, FLOOR_TOP - 36)
	_door_light.texture = _make_glow_texture()
	_door_light.color = Color(1.0, 0.25, 0.2)
	_door_light.energy = 0.0
	_door_light.texture_scale = 0.4
	add_child(_door_light)


func _add_prop(texture: Texture2D, pos: Vector2, prop_name: String, modulate := Color.WHITE) -> void:
	var sprite := Sprite2D.new()
	sprite.name = prop_name
	sprite.texture = texture
	sprite.position = pos
	sprite.modulate = modulate
	add_child(sprite)


func _add_monitor(texture: Texture2D, pos: Vector2) -> void:
	var monitor := Sprite2D.new()
	monitor.texture = texture
	monitor.position = pos
	monitor.modulate = Color(0.22, 0.22, 0.24)
	add_child(monitor)
	_monitors.append(monitor)
	var screen := Sprite2D.new()
	screen.texture = _make_screen_texture()
	screen.position = pos + Vector2(0, -1)
	screen.visible = false
	add_child(screen)
	_monitor_screens.append(screen)


func _add_emergency_light(pos: Vector2, color: Color) -> void:
	var light := PointLight2D.new()
	light.position = pos
	light.texture = _make_glow_texture()
	light.color = color
	light.energy = 0.9
	light.texture_scale = 0.8
	add_child(light)
	_lights.append(light)


## Radial gradient texture for point lights: Godot's default light
## texture is too faint to read against the dim room, so the emergency
## lights, the door light and the panel warning light share this one.
func _make_glow_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 0.85))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new()
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = gradient
	return texture


func _make_screen_texture() -> ImageTexture:
	var image := Image.create(10, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.3, 1.0, 0.5, 0.9))
	return ImageTexture.create_from_image(image)


func _build_player() -> void:
	_player = SidePlayer.new()
	_player.name = "Player"
	_player.position = Vector2(140, FLOOR_TOP)
	add_child(_player)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 20)
	shape.shape = rect
	shape.position = Vector2(0, -10)
	_player.add_child(shape)
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = PLAYER_TEXTURE
	sprite.position = Vector2(0, -10)
	_player.add_child(sprite)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position = Vector2(0, -10)
	camera.zoom = Vector2(CAMERA_ZOOM, CAMERA_ZOOM)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = ROOM_WIDTH
	camera.limit_bottom = ROOM_HEIGHT
	_player.add_child(camera)
	camera.make_current()
	_flashlight = Flashlight.new()
	_flashlight.name = "Flashlight"
	_player.add_child(_flashlight)


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)
	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeRect"
	_fade_rect.color = Color(0, 0, 0, 1)
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_fade_rect)
	_caption = Label.new()
	_caption.name = "WakeCaption"
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_caption.position = Vector2(-320, 250)
	_caption.size = Vector2(640, 60)
	_caption.add_theme_font_size_override("font_size", 16)
	_caption.add_theme_color_override("font_color", Color(0.92, 0.94, 0.96))
	_caption.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_caption.add_theme_constant_override("shadow_offset_y", 1)
	_caption.visible = false
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_caption)
	_manual_hint = PanelContainer.new()
	_manual_hint.name = "ManualHint"
	_manual_hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_manual_hint.position = Vector2(-268, 12)
	_manual_hint.size = Vector2(256, 30)
	var hint_style := StyleBoxFlat.new()
	hint_style.bg_color = Color(0.05, 0.08, 0.12, 0.85)
	hint_style.border_color = Color(0.78, 0.56, 0.2)
	hint_style.set_border_width_all(1)
	hint_style.set_corner_radius_all(3)
	hint_style.content_margin_left = 8
	hint_style.content_margin_right = 8
	hint_style.content_margin_top = 4
	hint_style.content_margin_bottom = 4
	_manual_hint.add_theme_stylebox_override("panel", hint_style)
	var hint_label := Label.new()
	hint_label.text = "[Q]  Press Q to view the emergency manual."
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color(0.9, 0.92, 0.94))
	_manual_hint.add_child(hint_label)
	_manual_hint.visible = false
	_manual_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_manual_hint)
	_prompt = Label.new()
	_prompt.name = "PromptLabel"
	_prompt.text = "Press E to inspect the emergency power panel."
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.position = Vector2(-320, -48)
	_prompt.size = Vector2(640, 24)
	_prompt.add_theme_font_size_override("font_size", 14)
	_prompt.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	_prompt.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_prompt.add_theme_constant_override("shadow_offset_y", 1)
	_prompt.visible = false
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_prompt)
	_notification = Label.new()
	_notification.name = "NotificationLabel"
	_notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notification.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_notification.position = Vector2(-320, 24)
	_notification.size = Vector2(640, 24)
	_notification.add_theme_font_size_override("font_size", 15)
	_notification.add_theme_color_override("font_color", Color(0.45, 1.0, 0.6))
	_notification.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_notification.add_theme_constant_override("shadow_offset_y", 1)
	_notification.visible = false
	_notification.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_notification)
	# Standalone end card: shown over the fade-out at the end of the
	# sequence (the full game continues into main.tscn instead).
	_end_label = Label.new()
	_end_label.name = "EndLabel"
	_end_label.text = "END OF OPENING SEQUENCE\n\nPress any key to exit."
	_end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_end_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_end_label.add_theme_font_size_override("font_size", 20)
	_end_label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.96))
	_end_label.visible = false
	_end_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_end_label)
