## Per-room copy (absolute separation, 2026-11-23): identical to the shared original; only paths point at this room's own copies.
extends Node2D
## Last Signal — Pickup (Phase 6).
##
## A visible, collectible item. Same interactable interface as console.gd
## (group "interactable" + interact_label / interact() / set_highlighted()).
## On interact it emits `collected` (carrying itself, so the level can read
## item_id / display_name / battery_restore) and frees itself.
## Consumables apply their effect immediately on pickup via the player's
## add_item(); the inventory still counts them, because Phase 7 puzzles
## will need non-consumable items too.

signal collected(pickup: Node2D)

@export var item_id: String = "energy_cell"
@export var display_name: String = "سلول انرژی"
@export var interact_label: String = "برداشتن سلول انرژی"
@export var amount: int = 1
@export var battery_restore: float = 40.0
@export var sprite_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if sprite_texture != null:
		sprite.texture = sprite_texture


func interact() -> void:
	collected.emit(self)
	queue_free()


func set_highlighted(highlighted: bool) -> void:
	sprite.modulate = Color(1.5, 1.4, 0.7) if highlighted else Color.WHITE
