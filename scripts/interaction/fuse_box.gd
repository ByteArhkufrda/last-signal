extends StaticBody2D
## Last Signal — Fuse box (Phase 7, puzzle 3: item + interaction).
##
## The box needs a fuse from the player's inventory (a hidden fuse sits
## in the room, revealed by radar). E with a fuse: the fuse is consumed,
## the box powers on and emits `solved`. E without one: a HUD message
## says the fuse is missing. Same interactable interface as console.gd.

signal solved

@export var interact_label: String = "گذاشتن فیوز"

## Phase 8: the tower this puzzle powers (set by the level's mapping).
@export var powers_tower: String = "Tower3"

var is_solved: bool = false

@onready var light: Polygon2D = $Light


func interact() -> void:
	if is_solved:
		return
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	if int(player.inventory.get("fuse", 0)) <= 0:
		var hud: CanvasLayer = get_tree().get_first_node_in_group("hud")
		if hud != null:
			hud.show_message("فیوز نیست. یک فیوز پیدا کن.")
		var audio: Node = get_tree().get_first_node_in_group("audio")
		if audio != null:
			audio.play("error")
		return
	player.remove_item("fuse", 1)
	is_solved = true
	light.color = Color(0.2, 0.9, 0.3)
	solved.emit()


func set_highlighted(highlighted: bool) -> void:
	modulate = Color(1.5, 1.4, 0.7) if highlighted else Color.WHITE
