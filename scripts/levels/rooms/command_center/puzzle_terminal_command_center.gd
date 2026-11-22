## Per-room copy (absolute separation, 2026-11-23): identical to the shared original; only paths point at this room's own copies.
extends Node2D
## Last Signal — Wire terminal (Phase 7).
##
## One terminal of the wire panel. Same interactable interface as
## console.gd. E reports the flip to the panel; the panel advances this
## terminal AND the next one (linked wires) and owns the solved check.
## Colors: 0 red, 1 green, 2 blue. The green dot above is the target:
## all three terminals must read green.

signal flipped(index: int)

@export var terminal_index: int = 1
@export var interact_label: String = "Flip terminal 1"

const COLORS: Array[Color] = [
	Color(0.9, 0.2, 0.2),
	Color(0.2, 0.9, 0.3),
	Color(0.2, 0.4, 0.9),
]

var color_index: int = 0
var _locked: bool = false

@onready var circle: Polygon2D = $Circle


func interact() -> void:
	if _locked:
		return
	flipped.emit(terminal_index)


func set_color(value: int) -> void:
	color_index = value % 3
	circle.color = COLORS[color_index]


func lock() -> void:
	_locked = true


func set_highlighted(highlighted: bool) -> void:
	modulate = Color(1.5, 1.4, 0.7) if highlighted else Color.WHITE
