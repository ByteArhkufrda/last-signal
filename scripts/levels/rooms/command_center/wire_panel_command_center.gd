## Per-room copy (absolute separation, 2026-11-23): identical to the shared original; only paths point at this room's own copies.
extends StaticBody2D
## Last Signal — Wire panel (Phase 7, puzzle 2: linked terminals).
##
## Three terminals on the right wall. Flipping terminal i advances its
## color AND the next terminal's color (wires are linked, wrapping from
## 3 back to 1). Colors cycle red → green → blue. Solved when all three
## read green — e.g. flipping each terminal twice from all-red. The clue
## is in Console B's wiring note. Solved: terminals lock, the panel
## emits `solved`, and the light turns green.

signal solved

## Phase 8: the tower this puzzle powers (set by the level's mapping).
@export var powers_tower: String = "Tower2"

var is_solved: bool = false

@onready var terminal1: Node2D = $Terminal1
@onready var terminal2: Node2D = $Terminal2
@onready var terminal3: Node2D = $Terminal3
@onready var light: Polygon2D = $Light


func _ready() -> void:
	for term in [terminal1, terminal2, terminal3]:
		term.flipped.connect(_on_terminal_flipped)


func _on_terminal_flipped(index: int) -> void:
	if is_solved:
		return
	var terms: Array[Node2D] = [terminal1, terminal2, terminal3]
	terms[index - 1].set_color(terms[index - 1].color_index + 1)
	terms[index % 3].set_color(terms[index % 3].color_index + 1)
	for term in terms:
		if term.color_index != 1:
			return
	_solve()


func _solve() -> void:
	is_solved = true
	for term in [terminal1, terminal2, terminal3]:
		term.lock()
	light.color = Color(0.2, 0.9, 0.3)
	solved.emit()
