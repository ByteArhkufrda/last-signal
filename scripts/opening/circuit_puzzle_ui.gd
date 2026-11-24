class_name CircuitPuzzleUI
extends Control
## Last Signal — opening sequence: electrical circuit puzzle UI.
##
## Grid UI over the pure CircuitPuzzle logic (scripts/opening/
## circuit_puzzle.gd). Click a tile to rotate it 90 degrees; hover (or
## arrow keys) selects a tile and Space / E rotates it; Escape closes
## the panel and keeps the puzzle state. Tiles show their connection
## ports; live wires glow amber, the solved path glows bright green with
## a travelling current pulse. Solved is reported only when the logic's
## real connectivity says so — the UI never decides on its own. The
## orchestrator listens for `solved` and runs the restoration sequence.

signal solved
signal closed

const TILE_SIZE := 48
const GRID_COLS := 5

const WIRE_OFF := Color(0.32, 0.38, 0.44)
const WIRE_LIVE := Color(0.95, 0.68, 0.2)
const WIRE_PATH := Color(0.35, 1.0, 0.65)
const TILE_BG := Color(0.08, 0.11, 0.15)
const TILE_BORDER := Color(0.2, 0.26, 0.32)
const SELECT_BORDER := Color(0.95, 0.72, 0.25)

var puzzle: CircuitPuzzle
var audio: Node = null

var _tiles: Dictionary = {}
var _selected := Vector2i(1, 1)
var _is_open := false
var _is_solved := false
var _flow_t := 0.0
var _status_label: Label
var _panel: PanelContainer


## One grid cell. Draws its wire ports, fuse/source/output symbols and
## the travelling current pulse when it sits on the solved path.
class PuzzleTile extends Control:
	var cell := Vector2i.ZERO
	var kind := CircuitPuzzle.Kind.STRAIGHT
	var ports: Array[int] = []
	var energized := false
	var on_path := false
	var flow_phase := -1.0  # -1 = no pulse here; else 0..1 across the tile
	var selected := false
	var ui: CircuitPuzzleUI

	func _init(p_ui: CircuitPuzzleUI, p_cell: Vector2i) -> void:
		ui = p_ui
		cell = p_cell
		custom_minimum_size = Vector2(CircuitPuzzleUI.TILE_SIZE, CircuitPuzzleUI.TILE_SIZE)
		mouse_filter = MOUSE_FILTER_STOP

	func _port_point(port: int) -> Vector2:
		var half := CircuitPuzzleUI.TILE_SIZE * 0.5
		match port:
			0:
				return Vector2(half, 0)
			1:
				return Vector2(CircuitPuzzleUI.TILE_SIZE, half)
			2:
				return Vector2(half, CircuitPuzzleUI.TILE_SIZE)
			_:
				return Vector2(0, half)

	func _draw() -> void:
		var size := Vector2(CircuitPuzzleUI.TILE_SIZE, CircuitPuzzleUI.TILE_SIZE)
		draw_rect(Rect2(Vector2.ZERO, size), CircuitPuzzleUI.TILE_BG)
		draw_rect(Rect2(Vector2.ZERO, size),
			CircuitPuzzleUI.SELECT_BORDER if selected else CircuitPuzzleUI.TILE_BORDER, false, 2.0)
		var center := size * 0.5
		var wire := CircuitPuzzleUI.WIRE_OFF
		if on_path:
			wire = CircuitPuzzleUI.WIRE_PATH
		elif energized:
			wire = CircuitPuzzleUI.WIRE_LIVE
		for port in ports:
			draw_line(center, _port_point(port), wire, 5.0)
		draw_circle(center, 4.0, wire)
		match kind:
			CircuitPuzzle.Kind.FUSE:
				var rect := Rect2(center - Vector2(9, 6), Vector2(18, 12))
				draw_rect(rect, Color(0.85, 0.85, 0.8))
				draw_rect(rect, Color(0.3, 0.3, 0.28), false, 1.0)
				draw_line(center + Vector2(-5, 0), center + Vector2(-2, -3), Color(0.3, 0.3, 0.28), 1.5)
				draw_line(center + Vector2(-2, -3), center + Vector2(2, 3), Color(0.3, 0.3, 0.28), 1.5)
				draw_line(center + Vector2(2, 3), center + Vector2(5, 0), Color(0.3, 0.3, 0.28), 1.5)
			CircuitPuzzle.Kind.SOURCE:
				var bolt := PackedVector2Array([
					center + Vector2(2, -11), center + Vector2(-5, 2),
					center + Vector2(-1, 2), center + Vector2(-3, 11),
					center + Vector2(5, -2), center + Vector2(1, -2)])
				draw_colored_polygon(bolt, Color(1.0, 0.85, 0.25) if energized else Color(0.6, 0.55, 0.3))
			CircuitPuzzle.Kind.OUTPUT:
				var glow := Color(1.0, 0.85, 0.3) if on_path else Color(0.5, 0.5, 0.45)
				draw_circle(center, 8.0, glow)
				draw_arc(center, 8.0, 0, TAU, 20, Color(0.2, 0.2, 0.18), 1.5)
		if flow_phase >= 0.0:
			# The pulse travels from the entry port to the exit port.
			var entry := center
			var exit := center
			if ports.size() >= 2:
				entry = _port_point(ports[0])
				exit = _port_point(ports[1])
			var pos := entry.lerp(exit, flow_phase)
			draw_circle(pos, 5.0, Color(0.8, 1.0, 0.85, 0.85))
			draw_circle(pos, 2.5, Color(1, 1, 1))

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var button := event as InputEventMouseButton
			if button.button_index == MOUSE_BUTTON_LEFT and button.pressed:
				ui.rotate_tile(cell)
				accept_event()

	func _on_mouse_entered() -> void:
		ui.select_tile(cell)


func _ready() -> void:
	puzzle = CircuitPuzzle.default_puzzle()
	mouse_filter = MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(380, 330)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.12, 0.98)
	style.border_color = Color(0.78, 0.56, 0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(vbox)
	var title := Label.new()
	title.text = "پنل برق اضطراری  //  تعمیر مدار"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.95, 0.75, 0.35))
	vbox.add_child(title)
	var hint := Label.new()
	hint.text = "روی یک سیم کلیک کن تا بچرخد. منبع را از راه فیوز به خروجی وصل کن."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.65, 0.72, 0.76))
	vbox.add_child(hint)
	var grid_wrap := CenterContainer.new()
	vbox.add_child(grid_wrap)
	var grid := GridContainer.new()
	grid.columns = GRID_COLS
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	grid_wrap.add_child(grid)
	for y in CircuitPuzzle.ROWS:
		for x in CircuitPuzzle.COLS:
			var cell := Vector2i(x, y)
			var tile := PuzzleTile.new(self, cell)
			tile.mouse_entered.connect(tile._on_mouse_entered)
			grid.add_child(tile)
			_tiles[cell] = tile
	_status_label = Label.new()
	_status_label.text = "مدار ناقص است"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
	vbox.add_child(_status_label)
	var close_button := Button.new()
	close_button.text = "بستن  [Esc]"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(close)
	vbox.add_child(close_button)
	_refresh()


func _unhandled_key_input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event.is_action_pressed("interact") or (event is InputEventKey and (event as InputEventKey).keycode == KEY_SPACE and event.pressed and not event.echo):
		rotate_tile(_selected)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		var next := _selected
		match key.keycode:
			KEY_LEFT:
				next.x = maxi(0, _selected.x - 1)
			KEY_RIGHT:
				next.x = mini(CircuitPuzzle.COLS - 1, _selected.x + 1)
			KEY_UP:
				next.y = maxi(0, _selected.y - 1)
			KEY_DOWN:
				next.y = mini(CircuitPuzzle.ROWS - 1, _selected.y + 1)
		if next != _selected:
			select_tile(next)
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _is_open or not _is_solved:
		return
	_flow_t += delta
	var path: Array[Vector2i] = puzzle.solve_path()
	if path.is_empty():
		return
	# One pulse loops along the whole path, ~1.6 s per traversal.
	var pos := fposmod(_flow_t / 1.6, 1.0) * path.size()
	for i in path.size():
		var tile: PuzzleTile = _tiles[path[i]]
		var local := pos - float(i)
		tile.flow_phase = local if local >= 0.0 and local < 1.0 else -1.0
		tile.queue_redraw()


func is_open() -> bool:
	return _is_open


func select_tile(cell: Vector2i) -> void:
	if not puzzle.in_bounds(cell):
		return
	_selected = cell
	_refresh()


func rotate_tile(cell: Vector2i) -> void:
	if not _is_open or _is_solved:
		return
	if not puzzle.is_rotatable(cell):
		return
	puzzle.rotate(cell)
	_selected = cell
	if audio != null:
		audio.play("rotate")
	_refresh()
	if puzzle.is_solved():
		_on_solved()


func open() -> void:
	if _is_open:
		return
	_is_open = true
	visible = true
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.2)
	_refresh()


func close() -> void:
	if not _is_open:
		return
	_is_open = false
	visible = false
	closed.emit()


func _on_solved() -> void:
	_is_solved = true
	_status_label.text = "مدار کامل شد — برق جاری است"
	_status_label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.6))
	if audio != null:
		audio.play("connect")
		audio.play("power_up")
	_refresh()
	# Let the current pulse travel once before the room restores.
	var timer := get_tree().create_timer(1.4)
	timer.timeout.connect(func() -> void: solved.emit())


func _refresh() -> void:
	var energized := puzzle.energized_cells()
	var path: Array[Vector2i] = puzzle.solve_path()
	for y in CircuitPuzzle.ROWS:
		for x in CircuitPuzzle.COLS:
			var cell := Vector2i(x, y)
			var tile: PuzzleTile = _tiles[cell]
			tile.kind = puzzle.kind_at(cell)
			tile.ports = puzzle.ports_at(cell)
			tile.energized = energized.has(cell)
			tile.on_path = path.has(cell)
			tile.selected = cell == _selected
			tile.queue_redraw()
