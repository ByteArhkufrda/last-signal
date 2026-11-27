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

@export var solved_message: String = "سیگنال تحلیل شد! فایل صوتی دانشمند بازیابی شد."

var is_solved: bool = false
var unlocked: bool = false

@onready var selector1: Node2D = $Selector1
@onready var selector2: Node2D = $Selector2
@onready var selector3: Node2D = $Selector3
@onready var light: Polygon2D = $Light


func _ready() -> void:
	for sel in [selector1, selector2, selector3]:
		sel.selected.connect(_on_pattern_selected)


func unlock() -> void:
	unlocked = true


func _on_pattern_selected(index: int) -> void:
	if is_solved:
		return
	if not unlocked:
		_show_hud("دستگاه خاموش است — اول برق آزمایشگاه را وصل کن.")
		_play_error()
		return
	if index == CORRECT_PATTERN:
		_solve()
	else:
		for sel in [selector1, selector2, selector3]:
			sel.set_selected(false)
		_show_hud("الگوی اشتباه — این فرکانس با گزارش تحقیقاتی جور نیست.")
		_play_error()


func _solve() -> void:
	is_solved = true
	for sel in [selector1, selector2, selector3]:
		sel.set_selected(sel.pattern_index == CORRECT_PATTERN)
		sel.lock()
	light.color = Color(0.2, 0.9, 0.3)
	solved.emit()


func _show_hud(text: String) -> void:
	var hud: CanvasLayer = get_tree().get_first_node_in_group("hud")
	if hud != null:
		hud.show_message(text)


func _play_error() -> void:
	var audio: Node = get_tree().get_first_node_in_group("audio")
	if audio != null:
		audio.play("error")
