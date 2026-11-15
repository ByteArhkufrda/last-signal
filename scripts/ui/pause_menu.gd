extends CanvasLayer
## Last Signal — Pause menu (Phase 9).
##
## process_mode is ALWAYS (set in the scene) so this node keeps running
## while the tree is paused: Esc toggles the pause, and the buttons stay
## clickable. The toggle is polled in _process (is_action_just_pressed)
## rather than _unhandled_input, so it also works with synthetic input.
## The pause menu lives in the main scene, hidden until needed.

@onready var resume_button: Button = $Panel/ResumeButton
@onready var restart_button: Button = $Panel/RestartButton
@onready var help_button: Button = $Panel/HelpButton
@onready var menu_button: Button = $Panel/MenuButton
@onready var help_screen: Control = $HelpScreen


func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	help_button.pressed.connect(_on_help_pressed)
	menu_button.pressed.connect(_on_menu_pressed)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		# Esc closes the help overlay first; only a second Esc resumes.
		if help_screen.is_help_visible():
			_play_click()
			help_screen.hide_help()
			return
		# Bugfix (review 2026-11-12): when the win screen is up the tree
		# is already paused by it. Without this guard, Esc here would
		# "resume" — unpausing the game behind the MISSION COMPLETE
		# screen, where the robot could catch the player mid-celebration.
		var win: CanvasLayer = get_tree().get_first_node_in_group("win")
		if win != null and win.visible:
			return
		if get_tree().paused:
			_on_resume_pressed()
		else:
			show_pause()


func show_pause() -> void:
	get_tree().paused = true
	visible = true
	resume_button.grab_focus()


func hide_pause() -> void:
	get_tree().paused = false
	visible = false


func _play_click() -> void:
	var audio: Node = get_tree().get_first_node_in_group("audio")
	if audio != null:
		audio.play("click")


func _on_resume_pressed() -> void:
	_play_click()
	hide_pause()


func _on_restart_pressed() -> void:
	_play_click()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_help_pressed() -> void:
	_play_click()
	help_screen.show_help()


func _on_menu_pressed() -> void:
	_play_click()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
