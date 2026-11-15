extends StaticBody2D
## Last Signal — Communication tower (Phase 8).
##
## One of the three towers. It stays offline (dim) until the level sets
## power_restored — each tower is gated by one Phase 7 puzzle (the panel
## names its tower in `powers_tower`). E activates it once powered;
## activating emits `activated` for the mission tracker. Same
## interactable interface as console.gd.

signal activated(tower: Node2D)

@export var tower_name: String = "Tower 1"
@export var interact_label: String = "روشن کردن دکل"
@export var sprite_texture: Texture2D

var power_restored: bool = false
var is_active: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var light: Polygon2D = $Light


func _ready() -> void:
	if sprite_texture != null:
		sprite.texture = sprite_texture
	sprite.modulate = Color(0.45, 0.45, 0.5)


func interact() -> void:
	if is_active:
		_show_message("دکل قبلاً روشن شده است.")
		return
	if not power_restored:
		_show_message("دکل خاموش است — اول برق را وصل کن.")
		return
	is_active = true
	sprite.modulate = Color.WHITE
	light.color = Color(0.2, 0.9, 0.3)
	activated.emit(self)


func set_highlighted(highlighted: bool) -> void:
	modulate = Color(1.5, 1.4, 0.7) if highlighted else Color.WHITE


func _show_message(text: String) -> void:
	var hud: CanvasLayer = get_tree().get_first_node_in_group("hud")
	if hud != null:
		hud.show_message(text)
