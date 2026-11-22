extends SceneTree
## Diagnostic: screenshot one standalone room via its own play_<room>.tscn.
## Headless Godot renders nothing, so run under Xvfb:
##   Xvfb :99 -screen 0 1280x720x24 &
##   DISPLAY=:99 godot --path . --resolution 1280x720 --script res://scripts/tests/shot_room.gd -- --room=medical_wing
## Saves /tmp/lastsignal_room_<room>.png (one wide shot at spawn).

func _initialize() -> void:
	var room_key := "medical_wing"
	var focus := Vector2.INF
	var wait_frames := 30
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--room="):
			room_key = arg.trim_prefix("--room=")
		elif arg.begins_with("--wait="):
			wait_frames = int(arg.trim_prefix("--wait="))
		elif arg.begins_with("--focus="):
			var parts: PackedStringArray = arg.trim_prefix("--focus=").split(",")
			focus = Vector2(float(parts[0]), float(parts[1]))
	var play: Node2D = load(
		"res://scenes/levels/rooms/%s/play_%s.tscn" % [room_key, room_key]).instantiate()
	root.add_child(play)
	for i in wait_frames:
		await process_frame
	var player: CharacterBody2D = play.get_node("Player")
	var camera: Camera2D = player.get_node("Camera2D")
	camera.reset_smoothing()
	for i in 15:
		await process_frame
	_save_shot("/tmp/lastsignal_room_%s.png" % room_key, player)
	if focus != Vector2.INF:
		camera.zoom = Vector2(2, 2)
		player.global_position = focus
		camera.reset_smoothing()
		for i in 15:
			await process_frame
		_save_shot("/tmp/lastsignal_room_%s_close.png" % room_key, player)
	quit()


func _save_shot(path: String, player: CharacterBody2D) -> void:
	var img: Image = root.get_texture().get_image()
	img.save_png(path)
	print("saved " + path + " player at " + str(player.global_position))
