extends StaticBody2D
## Last Signal — ORION laboratory, puzzle 2: Signal Frequency.
##
## The energy analyzer shows three wave patterns on its display:
## A (uniform wave), B (irregular wave), C (three consecutive
## pulses). The research log says the sample responded only to the
## third frequency pattern, so the answer is Pattern C. The analyzer
## stays dark until the power puzzle is solved (locked); a wrong
## pattern shows an error and clears the selection. Solved: selectors
## lock, the scientist's audio log is recovered (the wiring shows its
## text) and the analyzer emits `solved`.

signal solved

const CORRECT_PATTERN := 3
## Traffic-light states (Stage 2, B10): red while locked, amber once
## unlocked-but-unsolved, green when solved. Bright flash on a wrong
## pick (B5): the light was already red, so "red alert" read as nothing.
const FLASH_COLOR := Color(1.0, 1.0, 0.9)
const LOCKED_COLOR := Color(0.9, 0.2, 0.2)
const UNLOCKED_COLOR := Color(1.0, 0.65, 0.1)
const SOLVED_COLOR := Color(0.2, 0.9, 0.3)

@export var solved_message: String = "سیگنال تحلیل شد! فایل صوتی دانشمند بازیابی شد."

var is_solved: bool = false
var unlocked: bool = false

var _light_tween: Tween = null


func _ready() -> void:
	_build_waves()
	for sel in [selector1, selector2, selector3]:
		sel.selected.connect(_on_pattern_selected)


## The three wave patterns the design doc's wave monitor promises,
## drawn beside the selector each belongs to (Stage 3, Q2): A steady
## sine, B irregular, C three pulses. Schematic Line2Ds, same visual
## language as the room's other drawn shapes.
func _build_waves() -> void:
	# West of the panel (Stage 3, Q2 fix): the east side sits under
	# the HUD minimap when the player stands at the analyzer, so
	# the waves were unreadable exactly where they matter.
	var wave_a := Line2D.new()
	wave_a.name = "WaveA"
	wave_a.width = 1.0
	wave_a.default_color = Color(0.2, 0.85, 1.0)
	var points_a := PackedVector2Array()
	for i in 13:
		points_a.append(Vector2(-32.4 + float(i) * 1.7, -24.0 + sin(float(i) / 12.0 * TAU) * 3.0))
	wave_a.points = points_a
	add_child(wave_a)
	var wave_b := Line2D.new()
	wave_b.name = "WaveB"
	wave_b.width = 1.0
	wave_b.default_color = Color(0.2, 0.85, 1.0)
	var offsets_b := [0.0, -4.0, 3.0, -2.0, 5.0, -5.0, 2.0, -3.0, 4.0, -1.0, 3.0, -4.0, 0.0]
	var points_b := PackedVector2Array()
	for i in offsets_b.size():
		points_b.append(Vector2(-32.4 + float(i) * 1.7, 0.0 + offsets_b[i]))
	wave_b.points = points_b
	add_child(wave_b)
	var wave_c := Line2D.new()
	wave_c.name = "WaveC"
	wave_c.width = 1.0
	wave_c.default_color = Color(0.2, 0.85, 1.0)
	var points_c := PackedVector2Array()
	for i in 13:
		var y := 24.0
		if i == 2 or i == 6 or i == 10:
			y = 16.0
		points_c.append(Vector2(-32.4 + float(i) * 1.7, y))
	wave_c.points = points_c
	add_child(wave_c)

@onready var selector1: Node2D = $Selector1
@onready var selector2: Node2D = $Selector2
@onready var selector3: Node2D = $Selector3
@onready var light: Polygon2D = $Light


func unlock() -> void:
	unlocked = true
	light.color = UNLOCKED_COLOR


func _on_pattern_selected(index: int) -> void:
	if is_solved:
		return
	if not unlocked:
		_show_hud("اول برق را وصل کن")
		_play_error()
		_flash_light()
		return
	if index == CORRECT_PATTERN:
		_solve()
	else:
		for sel in [selector1, selector2, selector3]:
			sel.set_selected(false)
		_show_hud("الگوی اشتباه است")
		_play_error()
		_flash_light()


func _solve() -> void:
	is_solved = true
	for sel in [selector1, selector2, selector3]:
		sel.set_selected(sel.pattern_index == CORRECT_PATTERN)
		sel.lock()
		# Solved selectors stop prompting (Stage 3, Q4).
		sel.remove_from_group("interactable")
	light.color = SOLVED_COLOR
	solved.emit()


## Flash the light bright, then settle back to its state color.
func _flash_light() -> void:
	if _light_tween != null and _light_tween.is_valid():
		_light_tween.kill()
	light.color = FLASH_COLOR
	var target: Color = SOLVED_COLOR if is_solved else (UNLOCKED_COLOR if unlocked else LOCKED_COLOR)
	_light_tween = create_tween()
	_light_tween.tween_property(light, "color", target, 0.6)


func _show_hud(text: String) -> void:
	var hud: CanvasLayer = get_tree().get_first_node_in_group("hud")
	if hud != null:
		hud.show_message(text)


func _play_error() -> void:
	var audio: Node = get_tree().get_first_node_in_group("audio")
	if audio != null:
		audio.play("error")
