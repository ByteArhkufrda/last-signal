## Per-room copy (P4, 2026-11-25): pattern of pickup_command_center.gd, with the Medical Wing's fuse as its defaults.
extends Node2D
## Last Signal — Medical Wing fuse pickup (P4).
##
## A visible, collectible item (NOT in group "hidden": no radar needed).
## Same interactable interface as console.gd (group "interactable" +
## interact_label / interact() / set_highlighted()). On interact it emits
## `collected` (carrying itself, so the level's wiring can read item_id /
## display_name / amount / battery_restore, add it to the player's
## inventory and show the HUD message) and frees itself.
## The defaults are the fuse of the power puzzle: item "fuse", no battery.

signal collected(pickup: Node2D)

@export var item_id: String = "fuse"
@export var display_name: String = "فیوز"
@export var interact_label: String = "برداشتن فیوز"
@export var amount: int = 1
@export var battery_restore: float = 0.0
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
