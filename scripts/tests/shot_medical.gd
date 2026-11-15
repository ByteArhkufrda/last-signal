extends SceneTree
## Diagnostic: screenshot the Medical Wing for visual review.
## Headless Godot renders nothing, so run under Xvfb:
##   Xvfb :99 -screen 0 1280x720x24 &
##   DISPLAY=:99 godot --path . --script res://scripts/tests/shot_medical.gd
## Two shots: the whole wing (player camera at its center) and a 2x
## close-up of the north ward row (beds, monitors, defibrillator).

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/levels/level_01.tscn")
	var level: Node2D = scene.instantiate()
	root.add_child(level)
	await process_frame
	await process_frame
	var player: CharacterBody2D = level.get_node("Player")
	var camera: Camera2D = player.get_node("Camera2D")
	# Whole wing: camera centers on the player at the wing's center.
	player.global_position = Vector2(960, 184)
	camera.reset_smoothing()
	for i in 15:
		await process_frame
	_save_shot("/tmp/medical_wing_full.png")
	# Close-up: 2x zoom on the north ward row.
	camera.zoom = Vector2(2, 2)
	player.global_position = Vector2(800, 120)
	camera.reset_smoothing()
	for i in 15:
		await process_frame
	_save_shot("/tmp/medical_wing_beds.png")
	# Close-up: 2x zoom on the doctor's desk + east side.
	player.global_position = Vector2(1080, 256)
	camera.reset_smoothing()
	for i in 15:
		await process_frame
	_save_shot("/tmp/medical_wing_desk.png")
	print("medical wing shots saved")
	quit()


func _save_shot(path: String) -> void:
	var img: Image = root.get_texture().get_image()
	img.save_png(path)
	print("saved " + path)
