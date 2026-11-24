## Per-room copy (absolute separation, 2026-11-23): identical to the shared original; only paths point at this room's own copies.
extends Node2D
## Last Signal — Console interactable (Phase 3).
##
## Interactable interface (see docs/ARCHITECTURE.md): a node in the
## "interactable" group with interact_label, interact() and
## set_highlighted(bool). The player duck-types this interface; no base
## class, so a StaticBody2D door can be an interactable too.
## The console never touches the HUD: it emits `interacted` and the level
## wires that signal to the HUD message.

signal interacted(console: Node2D)

@export var interact_label: String = "استفاده از کنسول"
@export var message: String = "گزارش پزشکی: بعد از تمرین شیوع بیماری، این بخش بسته شد. آذوقه کم است."
@export var sprite_texture: Texture2D
## Phase 8: when true, the level handles this console as the emergency
## transmitter instead of showing its message.
@export var is_transmit_console: bool = false

var use_count: int = 0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if sprite_texture != null:
		sprite.texture = sprite_texture


func interact() -> void:
	use_count += 1
	interacted.emit(self)


func set_highlighted(highlighted: bool) -> void:
	sprite.modulate = Color(1.5, 1.4, 0.7) if highlighted else Color.WHITE
