class_name EmergencyManual
extends Control
## Last Signal — opening sequence: emergency manual overlay.
##
## Reusable UI component: a dark industrial sci-fi instruction book. The
## game world stays visible but dimmed behind it; the orchestrator pauses
## character movement while it is open. Opens with a fade + scale
## animation; the orchestrator closes it on Q or Escape. The manual text
## is the exact protocol from the opening design spec.

signal closed

const MANUAL_TEXT := """EMERGENCY POWER RESTORATION PROTOCOL

In the event of a critical power failure, the spacecraft's emergency backup power system is automatically activated.

However, the sudden power load and electrical pressure may cause cables to rupture or disconnect.

The emergency power supply may be operational, but damaged electrical connections can prevent power from reaching individual sections of the spacecraft.

Inspect the emergency electrical distribution panel, identify the damaged connections, and restore the circuit to bring power back to this section.

WARNING: Do not activate the system until all required electrical connections have been restored."""

var _is_open := false
var _book: PanelContainer


## Small technical illustration: battery -> broken cable -> fuse ->
## unlit bulb, drawn with code (no assets).
class CircuitDiagram extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(420, 64)
		var label := Label.new()
		label.text = "DAMAGED CABLE"
		label.position = Vector2(120, 44)
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color(0.85, 0.6, 0.3))
		add_child(label)

	func _draw() -> void:
		var wire := Color(0.75, 0.62, 0.3)
		var dim := Color(0.45, 0.5, 0.55)
		var y := 32.0
		# Battery (left).
		draw_rect(Rect2(8, y - 12, 26, 24), Color(0.2, 0.25, 0.3))
		draw_rect(Rect2(8, y - 12, 26, 24), wire, false, 1.5)
		draw_line(Vector2(38, y - 6), Vector2(38, y + 6), wire, 2.0)
		draw_line(Vector2(44, y - 9), Vector2(44, y + 9), wire, 2.0)
		# Wire to the break.
		draw_line(Vector2(44, y), Vector2(150, y), wire, 2.0)
		# The break: two bare ends with a spark.
		draw_line(Vector2(150, y - 5), Vector2(156, y + 2), Color(1, 0.9, 0.4), 1.5)
		draw_line(Vector2(156, y + 2), Vector2(150, y + 6), Color(1, 0.9, 0.4), 1.5)
		draw_line(Vector2(164, y - 6), Vector2(158, y + 1), Color(1, 0.9, 0.4), 1.5)
		draw_line(Vector2(158, y + 1), Vector2(164, y + 5), Color(1, 0.9, 0.4), 1.5)
		draw_line(Vector2(170, y), Vector2(240, y), wire, 2.0)
		# Fuse (middle-right).
		draw_rect(Rect2(240, y - 8, 44, 16), Color(0.2, 0.25, 0.3))
		draw_rect(Rect2(240, y - 8, 44, 16), wire, false, 1.5)
		draw_line(Vector2(248, y), Vector2(256, y - 5), wire, 1.5)
		draw_line(Vector2(256, y - 5), Vector2(264, y + 5), wire, 1.5)
		draw_line(Vector2(264, y + 5), Vector2(272, y - 5), wire, 1.5)
		draw_line(Vector2(272, y - 5), Vector2(280, y), wire, 1.5)
		draw_line(Vector2(284, y), Vector2(330, y), wire, 2.0)
		# Unlit bulb (right).
		draw_arc(Vector2(352, y - 2), 14, 0, TAU, 24, dim, 1.5)
		draw_line(Vector2(344, y + 10), Vector2(360, y + 10), dim, 1.5)
		draw_line(Vector2(346, y + 14), Vector2(358, y + 14), dim, 1.5)


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_book = PanelContainer.new()
	_book.custom_minimum_size = Vector2(480, 320)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.12, 0.98)
	style.border_color = Color(0.78, 0.56, 0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 12
	_book.add_theme_stylebox_override("panel", style)
	center.add_child(_book)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_book.add_child(vbox)
	var title := Label.new()
	title.text = "EMERGENCY MANUAL  //  K-17"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.95, 0.75, 0.35))
	vbox.add_child(title)
	var sep := HSeparator.new()
	vbox.add_child(sep)
	var body := Label.new()
	body.text = MANUAL_TEXT
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 13)
	body.add_theme_color_override("font_color", Color(0.88, 0.92, 0.94))
	vbox.add_child(body)
	vbox.add_child(CircuitDiagram.new())
	var footer := Label.new()
	footer.text = "Press Q or Escape to close"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Color(0.6, 0.68, 0.72))
	vbox.add_child(footer)


func is_open() -> bool:
	return _is_open


func open() -> void:
	if _is_open:
		return
	_is_open = true
	visible = true
	modulate.a = 0.0
	_book.pivot_offset = _book.size * 0.5
	_book.scale = Vector2(0.96, 0.96)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.22)
	tw.tween_property(_book, "scale", Vector2.ONE, 0.22)


func close() -> void:
	if not _is_open:
		return
	_is_open = false
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func() -> void:
		visible = false
		closed.emit())
