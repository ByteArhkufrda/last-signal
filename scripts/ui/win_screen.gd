extends CanvasLayer
## Last Signal — Mission-complete screen (Phase 10).
##
## Shown by the level when the emergency signal is sent. Pauses the
## tree (like the pause menu) so the robot can't catch the player while
## the win screen is up; process_mode is ALWAYS so the buttons stay
## live. Lives in the main scene, hidden until needed, found via group
## "win".

@onready var again_button: Button = $Panel/AgainButton
@onready var menu_button: Button = $Panel/MenuButton


func _ready() -> void:
	again_button.pressed.connect(_on_again_pressed)
	menu_button.pressed.connect(_on_menu_pressed)


func show_win() -> void:
	get_tree().paused = true
	visible = true
	again_button.grab_focus()


func hide_win() -> void:
	get_tree().paused = false
	visible = false


func _play_click() -> void:
	var audio: Node = get_tree().get_first_node_in_group("audio")
	if audio != null:
		audio.play("click")


func _on_again_pressed() -> void:
	_play_click()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	_play_click()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
