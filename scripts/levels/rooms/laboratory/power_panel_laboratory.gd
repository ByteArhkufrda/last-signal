extends StaticBody2D
## Last Signal — ORION laboratory, puzzle 1: Power Restoration.
##
## Three switches beside the sample containment chamber. They must be
## flipped in the order Cooling System → Energy Stabilizer →
## Containment Chamber — the order is written on the panel warning
## ("The containment system must never be activated before the cooling
## and stabilization systems"). A wrong flip resets all switches to
## off and raises a red alert. Solved: switches lock, the chamber
## powers on (the wiring lights the sample glow) and the panel emits
## `solved` (the level counts it), and the light turns green.

signal solved

const SEQUENCE: Array[int] = [1, 2, 3]

@export var solved_message: String = "برق وصل شد! محفظه‌ی نمونه فعال شد."

var is_solved: bool = false

var _progress: int = 0

@onready var switch1: Node2D = $Switch1
@onready var switch2: Node2D = $Switch2
@onready var switch3: Node2D = $Switch3
@onready var light: Polygon2D = $Light


func _ready() -> void:
	for sw in [switch1, switch2, switch3]:
		sw.flipped.connect(_on_switch_flipped)


func _on_switch_flipped(index: int) -> void:
	if is_solved:
		return
	if index == SEQUENCE[_progress]:
		_progress += 1
		if _progress >= SEQUENCE.size():
			_solve()
	else:
		_reset()


func _reset() -> void:
	_progress = 0
	for sw in [switch1, switch2, switch3]:
		sw.set_on(false)
	var hud: CanvasLayer = get_tree().get_first_node_in_group("hud")
	if hud != null:
		hud.show_message("ترتیب اشتباه است — هشدار قرمز! اول خنک‌کننده، بعد تثبیت‌کننده، بعد محفظه.")
	var audio: Node = get_tree().get_first_node_in_group("audio")
	if audio != null:
		audio.play("error")


func _solve() -> void:
	is_solved = true
	for sw in [switch1, switch2, switch3]:
		sw.lock()
	light.color = Color(0.2, 0.9, 0.3)
	solved.emit()
