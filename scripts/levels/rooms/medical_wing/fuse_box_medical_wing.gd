## Last Signal — Medical Wing fuse box (P4, 2026-11-25).
extends Node2D
## The room's power puzzle: in the dark, find the FUSE (pickup_medical_wing),
## put it in this box, and the power returns.
##
## Pattern of fuse_box_command_center.gd, but not a "puzzle": the box is
## only in group "interactable" (never "puzzles" or "hidden"), so the
## mission counters and the level's puzzle wiring never see it. It is not
## solid either (nothing is added to the nav grid or prop_solid_rects()).
##
## E without a fuse: a HUD message, nothing else. E with a fuse: the fuse
## is consumed (inventory -1), the box shows fusebox_open, a HUD message,
## then `solved` fires. MedicalWing connects `solved` to the MedicalDarkness
## node (it survives the full-game flatten, this room does not), whose
## restore_power() stops the lights' flicker and plays the chime (the robots
## do NOT wake here: since P7 they wake after the medicine, see
## recovery_medical_wing.gd). After that the box is inert and leaves group
## "interactable".
## Same interactable interface as console.gd: interact_label, interact(),
## set_highlighted(bool); it also talks to the HUD itself.

signal solved

const OPEN_TEXTURE: Texture2D = preload("res://assets/sprites/medical-wing/fusebox_open.png")
const EMPTY_MESSAGE := "جعبه‌ی فیوز خالیه. یه فیوز لازمه."
const DONE_MESSAGE := "فیوز جا خورد. برق اضطراری وصل شد."

@export var interact_label: String = "گذاشتن فیوز"

var is_solved: bool = false

@onready var sprite: Sprite2D = $Sprite2D


func interact() -> void:
	if is_solved:
		return
	var player := _get_player()
	if player == null:
		return
	if int(player.inventory.get("fuse", 0)) <= 0:
		_show_message(EMPTY_MESSAGE)
		return
	player.remove_item("fuse", 1)
	is_solved = true
	sprite.texture = OPEN_TEXTURE
	set_highlighted(false)
	remove_from_group("interactable")
	_show_message(DONE_MESSAGE)
	solved.emit()


func set_highlighted(highlighted: bool) -> void:
	sprite.modulate = Color(1.5, 1.4, 0.7) if highlighted else Color.WHITE


func _show_message(text: String) -> void:
	var hud := _get_hud()
	if hud != null:
		hud.show_message(text)


## The HUD of THIS branch of the tree: a child called "HUD" of an
## ancestor (Main in the full game), like the level wiring does, because
## the "hud" group can still hold a just-freed HUD for a frame; the group
## is only the fallback (level-only tests, a bare standalone room: null).
func _get_hud() -> CanvasLayer:
	var node := get_parent()
	while node != null:
		var found := node.get_node_or_null("HUD") as CanvasLayer
		if found != null:
			return found
		node = node.get_parent()
	return get_tree().get_first_node_in_group("hud") as CanvasLayer


## The player of THIS branch of the tree: the nearest "Player" child of an
## ancestor (Level01 in the full game, the launcher when standalone); the
## "player" group only as a fallback, since it is ambiguous whenever two
## levels are alive at once.
func _get_player() -> Node2D:
	var node := get_parent()
	while node != null:
		var found := node.get_node_or_null("Player") as Node2D
		if found != null:
			return found
		node = node.get_parent()
	return get_tree().get_first_node_in_group("player") as Node2D
