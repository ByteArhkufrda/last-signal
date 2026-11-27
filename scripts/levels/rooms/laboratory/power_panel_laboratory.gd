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
## Bright flash on a wrong flip (Stage 2, B5): the light is already
## red before solving, so a "red alert" alone reads as nothing.
const FLASH_COLOR := Color(1.0, 1.0, 0.9)
const LIGHT_OFF_COLOR := Color(0.9, 0.2, 0.2)
const LIGHT_ON_COLOR := Color(0.2, 0.9, 0.3)

@export var solved_message: String = "برق وصل شد! محفظه‌ی نمونه فعال شد."

var is_solved: bool = false

var _progress: int = 0
var _light_tween: Tween = null

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
	_flash_light()
	var hud: CanvasLayer = get_tree().get_first_node_in_group("hud")
	if hud != null:
		# Short toast: the HUD's message slot fits ~200 px, and the
		# order itself is on the panel warning and the stage hint.
		hud.show_message("ترتیب اشتباه است!")
	var audio: Node = get_tree().get_first_node_in_group("audio")
	if audio != null:
		audio.play("error")


## Flash the light bright, then settle back to its state color.
func _flash_light() -> void:
	if _light_tween != null and _light_tween.is_valid():
		_light_tween.kill()
	light.color = FLASH_COLOR
	var target: Color = LIGHT_ON_COLOR if is_solved else LIGHT_OFF_COLOR
	_light_tween = create_tween()
	_light_tween.tween_property(light, "color", target, 0.6)


func _solve() -> void:
	is_solved = true
	for sw in [switch1, switch2, switch3]:
		sw.lock()
		# Solved switches stop prompting (Stage 3, Q4): the player
		# no longer gets "E — flip switch" on a locked panel.
		sw.remove_from_group("interactable")
	light.color = LIGHT_ON_COLOR
	solved.emit()
