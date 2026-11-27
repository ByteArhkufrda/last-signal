## ORION laboratory — one digit dial of the research vault.
## Same interactable interface as the power switch (group
## "interactable" + interact_label / interact() / set_highlighted()).
## E advances the digit 0-9 (wrapping) and reports the change to the
## vault, which owns the code logic. The dial starts locked — the
## vault unlocks it once the signal puzzle is solved — and locks
## again when the vault opens.
extends Node2D

signal changed(index: int, digit: int)

@export var dial_index: int = 1
@export var interact_label: String = "Turn dial"
@export var locked_message: String = "اول سیگنال را تحلیل کن"

## Locked dials read darker than unlocked ones (Stage 2, B10).
const BOX_LOCKED_COLOR := Color(0.14, 0.15, 0.19)
const BOX_UNLOCKED_COLOR := Color(0.25, 0.26, 0.32)

var digit: int = 0
var _locked: bool = true

@onready var digit_label: Label = $DigitLabel
@onready var box: Polygon2D = $Box


func _ready() -> void:
	_update_label()
	_update_visual()


func interact() -> void:
	if _locked:
		# Solved vault: the dials are locked for good — stay silent
		# instead of claiming the vault is still locked.
		var vault: Node = get_parent()
		if vault != null and bool(vault.get("is_solved")):
			return
		var hud: CanvasLayer = get_tree().get_first_node_in_group("hud")
		if hud != null:
			hud.show_message(locked_message)
		return
	digit = (digit + 1) % 10
	_update_label()
	changed.emit(dial_index, digit)


func set_digit(value: int) -> void:
	digit = clampi(value, 0, 9)
	_update_label()


func set_locked(value: bool) -> void:
	_locked = value
	_update_visual()


func lock() -> void:
	_locked = true
	_update_visual()


func set_highlighted(highlighted: bool) -> void:
	modulate = Color(1.5, 1.4, 0.7) if highlighted else Color.WHITE


func _update_label() -> void:
	if digit_label != null:
		digit_label.text = str(digit)


func _update_visual() -> void:
	if box != null:
		box.color = BOX_LOCKED_COLOR if _locked else BOX_UNLOCKED_COLOR
