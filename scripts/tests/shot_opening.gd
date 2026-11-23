extends SceneTree
## Diagnostic: screenshot the side-view opening sequence.
## Headless Godot renders nothing, so run under Xvfb:
##   Xvfb :99 -screen 0 1280x720x24 &
##   DISPLAY=:99 godot --path . --resolution 1280x720 --script res://scripts/tests/shot_opening.gd
## Saves /tmp/lastsignal_opening.png (wake caption + dim room + flashlight).
## Waits by wall-clock time (not frames: Xvfb rendering is slow, so a
## frame count would overshoot the caption window).

func _initialize() -> void:
	var play: Node = load("res://scenes/opening/play_opening.tscn").instantiate()
	root.add_child(play)
	await create_timer(2.2).timeout
	for i in 5:
		await process_frame
	var img: Image = root.get_texture().get_image()
	img.save_png("/tmp/lastsignal_opening.png")
	print("saved /tmp/lastsignal_opening.png")
	quit()
