class_name PowerPanel
extends Node2D
## Last Signal — opening sequence: emergency electrical distribution
## panel. Wall-mounted on the back wall of the medical section.
##
## Visuals: fuse-box body (existing medical-wing art), a blinking red
## warning light, a damaged cable hanging from the panel with a visible
## gap and intermittent sparks, and a status label that reads
## "POWER FAILURE" until the circuit is repaired. `set_restored()`
## switches the label to "EMERGENCY POWER RESTORED", steadies the light
## green, closes the cable gap and stops the sparks. The orchestrator
## asks `is_player_near()` for the "Press E" prompt and calls
## `set_restored()` after the puzzle is solved.

const PANEL_TEXTURE: Texture2D = preload("res://assets/sprites/medical-wing/fusebox_closed.png")
const INDICATOR_TEXTURE: Texture2D = preload("res://assets/sprites/medical-wing/indicator_emergency.png")

const NEAR_DISTANCE := 56.0
const CABLE_GAP := Vector2(-14, -16)

var restored := false

var _elapsed := 0.0
var _blink_on := true
var _spark_on := false
var _warning_light: PointLight2D
var _status_label: Label
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 1234
	var body := Sprite2D.new()
	body.name = "PanelBody"
	body.texture = PANEL_TEXTURE
	body.scale = Vector2(2, 3)
	body.position = Vector2(0, -24)
	add_child(body)
	var indicator := Sprite2D.new()
	indicator.name = "WarningIndicator"
	indicator.texture = INDICATOR_TEXTURE
	indicator.position = Vector2(0, -56)
	add_child(indicator)
	_warning_light = PointLight2D.new()
	_warning_light.name = "WarningLight"
	_warning_light.position = Vector2(0, -56)
	_warning_light.texture = _make_glow_texture()
	_warning_light.color = Color(1.0, 0.25, 0.2)
	_warning_light.energy = 0.7
	_warning_light.texture_scale = 0.45
	add_child(_warning_light)
	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.text = "POWER FAILURE"
	_status_label.position = Vector2(-52, -76)
	_status_label.size = Vector2(104, 14)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 10)
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.3))
	add_child(_status_label)


func _process(delta: float) -> void:
	_elapsed += delta
	if restored:
		return
	# Blink ~1 Hz; sparks burst in short random windows.
	var blink := fposmod(_elapsed, 1.0) < 0.55
	if blink != _blink_on:
		_blink_on = blink
		_warning_light.energy = 0.7 if blink else 0.08
		queue_redraw()
	var spark := fposmod(_elapsed, 0.9) < 0.12
	if spark != _spark_on:
		_spark_on = spark
		queue_redraw()


func _draw() -> void:
	# Damaged cable: from the panel's bottom edge down to a floor
	# junction, with a gap at the break while power is out.
	var top := Vector2(-8, 0)
	var break_point := CABLE_GAP + Vector2(0, 8)
	var bottom := Vector2(-20, 0)
	if restored:
		draw_line(top, bottom, Color(0.85, 0.8, 0.6), 2.0)
	else:
		draw_line(top, break_point, Color(0.85, 0.8, 0.6), 2.0)
		draw_line(break_point + Vector2(4, 6), bottom, Color(0.85, 0.8, 0.6), 2.0)
		if _spark_on:
			var c := Color(1.0, 0.9, 0.4)
			draw_line(break_point + Vector2(-3, 0), break_point + Vector2(1, 3), c, 1.5)
			draw_line(break_point + Vector2(1, 3), break_point + Vector2(-2, 6), c, 1.5)
			draw_line(break_point + Vector2(-2, 6), break_point + Vector2(3, 8), c, 1.5)
			draw_circle(break_point, 2.5, Color(1.0, 0.95, 0.6, 0.7))


func is_player_near(player_pos: Vector2) -> bool:
	return global_position.distance_to(player_pos) < NEAR_DISTANCE


## Radial gradient texture for the warning light (same as the room's
## emergency lights: the default light texture is too faint to read).
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


func set_restored() -> void:
	restored = true
	_status_label.text = "EMERGENCY POWER RESTORED"
	_status_label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.6))
	_warning_light.color = Color(0.4, 1.0, 0.55)
	_warning_light.energy = 0.5
	_spark_on = false
	queue_redraw()
