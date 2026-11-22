## Per-room copy (absolute separation, 2026-11-23): identical to the shared original; only paths point at this room's own copies.
extends "res://scripts/levels/rooms/command_center/pickup_command_center.gd"
## Last Signal — Hidden object (Phase 4 + Phase 6).
##
## A Pickup that starts invisible and out of the "interactable" group.
## A radar pulse front reveals it (visible + joins "interactable"); from
## then on it collects exactly like a normal pickup (Phase 6).
## The level wires the `revealed` signal to the HUD message, like
## `interacted` in Phase 3.

signal revealed(obj: Node2D)

@export var message: String = "Radar revealed a hidden cache!"

var is_revealed: bool = false


func _ready() -> void:
	super._ready()
	visible = false


func reveal() -> void:
	if is_revealed:
		return
	is_revealed = true
	visible = true
	add_to_group("interactable")
	revealed.emit(self)
