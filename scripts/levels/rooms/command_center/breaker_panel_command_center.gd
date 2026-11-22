## Per-room copy (absolute separation, 2026-11-23): identical to the shared original; only paths point at this room's own copies.
extends StaticBody2D
## Last Signal — Breaker panel (Phase 7, puzzle 1: sequence).
##
## Three switches on the left wall. They must be flipped in the order
## 2, 1, 3 — the order is written in Console A's station log. A wrong
## flip resets all switches to off. Solved: switches lock, the panel
## emits `solved` (the level counts it), and the light turns green.

signal solved

const SEQUENCE: Array[int] = [2, 1, 3]

## Phase 8: the tower this puzzle powers (set by the level's mapping).
@export var powers_tower: String = "Tower1"

var is_solved: bool = false

var _progress: int = 0

@onready var switch1: Node2D = $Switch1
@onready var switch2: Node2D = $Switch2
@onready var switch3: Node2D = $Switch3
@onready var light: Polygon2D = $Light


func _ready() -> void:
	for sw in [switch1, switch2, switch3]:
		sw.flipped.connect(_on_switch_flipped)


func _on_switch_flipped(index: int) -> void:
	if is_solved:
		return
	if index == SEQUENCE[_progress]:
		_progress += 1
		if _progress >= SEQUENCE.size():
			_solve()
	else:
		_reset()


func _reset() -> void:
	_progress = 0
	for sw in [switch1, switch2, switch3]:
		sw.set_on(false)
	var hud: CanvasLayer = get_tree().get_first_node_in_group("hud")
	if hud != null:
		hud.show_message("ترتیب اشتباه است — کلیدها ریست شدند.")
	var audio: Node = get_tree().get_first_node_in_group("audio")
	if audio != null:
		audio.play("error")


func _solve() -> void:
	is_solved = true
	for sw in [switch1, switch2, switch3]:
		sw.lock()
	light.color = Color(0.2, 0.9, 0.3)
	solved.emit()
