extends Node
## Last Signal — ORION laboratory mission (2026-11-27).
##
## The room's goal is the keycard for the Core Chamber. Three
## chained puzzles (power → signal → vault), then take the keycard
## from the opened vault. No towers, no transmitter: this room's
## mission ends when the keycard is taken, and the wiring runs the
## room-ending sequence (blackout + ship AI + brain flash).

signal objective_completed(id: String)
signal mission_completed

const TOTAL_PUZZLES := 3

var puzzles_solved: int = 0
var keycard_taken: bool = false
var is_complete: bool = false

## 0 = puzzles, 1 = keycard, 2 = done.
var _stage: int = 0


func current_text() -> String:
	match _stage:
		0:
			return "هدف: معماهای آزمایشگاه را حل کن (%d/3) — اول برق، بعد سیگنال، بعد محفظه" % puzzles_solved
		1:
			return "هدف: Keycard را از محفظه بردار"
		_:
			return "مأموریت کامل شد — Keycard را داری!"


## Current stage (0 = puzzles, 1 = keycard, 2 = done).
## Used by the level for the contextual HUD hint.
func current_stage() -> int:
	return _stage


func on_puzzle_solved() -> void:
	puzzles_solved += 1
	_check_advance()


func on_keycard_taken() -> void:
	if _stage != 1 or is_complete:
		return
	keycard_taken = true
	is_complete = true
	_stage = 2
	mission_completed.emit()


func _check_advance() -> void:
	if _stage == 0 and puzzles_solved >= TOTAL_PUZZLES:
		_stage = 1
		objective_completed.emit("puzzles")
