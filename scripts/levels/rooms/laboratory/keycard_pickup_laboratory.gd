extends Node2D
## Last Signal — ORION laboratory keycard pickup.
##
## Same interactable interface as the other pickups (group
## "interactable" + interact_label / interact() / set_highlighted()).
## On interact it emits `collected` (carrying itself, so the wiring
## can read item_id) and frees itself. The wiring adds the keycard
## to the player's inventory and starts the room-ending sequence.
## With no wiring connected (assembled level: the room wiring only
## runs standalone), it collects directly so the keycard is never
## lost — the full-game ending hook is still to be wired.

signal collected(pickup: Node2D)

@export var item_id: String = "keycard"
@export var display_name: String = "کارت دسترسی (Keycard)"
@export var interact_label: String = "برداشتن Keycard"
@export var amount: int = 1
@export var battery_restore: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

var _pulse_tween: Tween = null


func _ready() -> void:
	# Gentle scale pulse (Stage 3, Q3): the card is a small 16x10
	# gold slab, and without motion it is easy to miss when the
	# vault opens right beside the player.
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.6)
	_pulse_tween.tween_property(self, "scale", Vector2.ONE, 0.6)


func interact() -> void:
	if collected.get_connections().is_empty():
		var player: Node2D = get_tree().get_first_node_in_group("player")
		if player != null and player.has_method("add_item"):
			player.add_item(item_id, amount, battery_restore)
	collected.emit(self)
	queue_free()


func set_highlighted(highlighted: bool) -> void:
	sprite.modulate = Color(1.5, 1.4, 0.7) if highlighted else Color.WHITE
