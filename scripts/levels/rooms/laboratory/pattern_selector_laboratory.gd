## ORION laboratory — one wave-pattern selector of the signal
## analyzer. Same interactable interface as the power switch (group
## "interactable" + interact_label / interact() / set_highlighted()).
## E reports the selection to the analyzer, which owns the logic; the
## selector itself never decides. The analyzer can highlight it
## (selected) or lock it (solved).
extends Node2D

signal selected(index: int)

@export var pattern_index: int = 1
@export var interact_label: String = "Select pattern"

const COLOR_OFF := Color(0.45, 0.48, 0.55)
const COLOR_ON := Color(0.2, 0.85, 1.0)

var is_selected: bool = false
var _locked: bool = false

@onready var box: Polygon2D = $Box


func interact() -> void:
	if _locked:
		return
	selected.emit(pattern_index)


func set_selected(value: bool) -> void:
	is_selected = value
	_update_visual()


func lock() -> void:
	_locked = true


func set_highlighted(highlighted: bool) -> void:
	modulate = Color(1.5, 1.4, 0.7) if highlighted else Color.WHITE


func _update_visual() -> void:
	box.color = COLOR_ON if is_selected else COLOR_OFF
