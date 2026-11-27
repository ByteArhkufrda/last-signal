## Per-room copy (ORION laboratory, 2026-11-27): same interface as the
## command-center breaker switch — one switch of the power panel.
## E toggles it and reports the flip to the panel, which owns the
## sequence logic. The panel can force it off (wrong order) or lock it
## (solved).
extends Node2D

signal flipped(index: int)

@export var switch_index: int = 1
@export var interact_label: String = "Flip switch 1"

const COLOR_OFF := Color(0.55, 0.55, 0.58)
const COLOR_ON := Color(0.2, 0.9, 0.3)

var is_on: bool = false
var _locked: bool = false

@onready var lever: Polygon2D = $Lever


func interact() -> void:
	if _locked:
		return
	is_on = not is_on
	_update_visual()
	flipped.emit(switch_index)


func set_on(value: bool) -> void:
	is_on = value
	_update_visual()


func lock() -> void:
	_locked = true


func set_highlighted(highlighted: bool) -> void:
	modulate = Color(1.5, 1.4, 0.7) if highlighted else Color.WHITE


func _update_visual() -> void:
	lever.color = COLOR_ON if is_on else COLOR_OFF
