extends StaticBody2D
## Last Signal — ORION laboratory, puzzle 3: Research Vault.
##
## The keycard for the Core Chamber sits in a security vault with a
## three-digit lock. The code comes from the three experiment notes
## scattered around the lab — Experiment 01 (First Contact),
## Experiment 03 (First Response), Experiment 07 (Final Observation)
## — so the code is 137. Each dial is turned with E (0-9, wrapping);
## the vault opens the moment the dials read 1-3-7. The vault stays
## locked until the signal puzzle is solved. Solved: dials lock, the
## keycard pickup spawns beside the vault and the vault emits
## `solved`.

signal solved

const CODE: Array[int] = [1, 3, 7]
const KEYCARD_SCENE: PackedScene = preload("res://scenes/levels/rooms/laboratory/keycard_pickup_laboratory.tscn")
const KEYCARD_OFFSET := Vector2(-40, 0)
## Traffic-light states (Stage 2, B10): red while locked, amber once
## unlocked-but-unsolved, green when solved.
const LOCKED_COLOR := Color(0.9, 0.2, 0.2)
const UNLOCKED_COLOR := Color(1.0, 0.65, 0.1)
const SOLVED_COLOR := Color(0.2, 0.9, 0.3)

@export var solved_message: String = "محفظه باز شد! Keycard و گزارش محرمانه داخل آن است."

var is_solved: bool = false
var unlocked: bool = false
var keycard_spawned: bool = false

@onready var dial1: Node2D = $Dial1
@onready var dial2: Node2D = $Dial2
@onready var dial3: Node2D = $Dial3
@onready var light: Polygon2D = $Light


func _ready() -> void:
	for dial in [dial1, dial2, dial3]:
		dial.changed.connect(_on_dial_changed)


func unlock() -> void:
	unlocked = true
	light.color = UNLOCKED_COLOR
	for dial in [dial1, dial2, dial3]:
		dial.set_locked(false)


func _on_dial_changed(_index: int, _digit: int) -> void:
	if is_solved or not unlocked:
		return
	if dial1.digit == CODE[0] and dial2.digit == CODE[1] and dial3.digit == CODE[2]:
		_solve()


func _solve() -> void:
	is_solved = true
	for dial in [dial1, dial2, dial3]:
		dial.lock()
		# Solved dials stop prompting (Stage 3, Q4): no more
		# "E — turn the first digit" on an opened vault.
		dial.remove_from_group("interactable")
	light.color = SOLVED_COLOR
	solved.emit()
	_spawn_keycard()


func _spawn_keycard() -> void:
	if keycard_spawned:
		return
	keycard_spawned = true
	var kc: Node2D = KEYCARD_SCENE.instantiate()
	kc.name = "KeycardPickup"
	kc.position = position + KEYCARD_OFFSET
	get_parent().add_child(kc)
	# The wiring only connects interactables present at setup; a
	# dynamically spawned pickup must be wired now, or taking it
	# would do nothing.
	var wiring: Node = get_tree().get_first_node_in_group("room_wiring")
	if wiring != null and wiring.has_method("wire_keycard_pickup"):
		wiring.wire_keycard_pickup(kc)
