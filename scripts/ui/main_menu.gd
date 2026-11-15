extends Control
## Last Signal — Main menu (Phase 9).
##
## The project's main scene (see project.godot). Start loads the game
## scene; Quit closes the game. The menu has its own AudioManager child
## (group "audio") so button clicks have sound here too.

@onready var start_button: Button = $StartButton
@onready var help_button: Button = $HelpButton
@onready var quit_button: Button = $QuitButton
@onready var help_screen: Control = $HelpScreen
@onready var audio: Node = $AudioManager


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	help_button.pressed.connect(_on_help_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	start_button.grab_focus()
	audio.start_ambient()


func _on_start_pressed() -> void:
	audio.play("click")
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_help_pressed() -> void:
	audio.play("click")
	help_screen.show_help()


func _on_quit_pressed() -> void:
	audio.play("click")
	get_tree().quit()
