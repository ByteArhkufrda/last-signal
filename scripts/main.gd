extends Node
## Last Signal — Main scene root (Phase 1). Loads Level 01.

@onready var audio: Node = $AudioManager


func _ready() -> void:
	print("LAST SIGNAL — Phase 10: Testing, Optimization, and Export")
	audio.start_ambient()
