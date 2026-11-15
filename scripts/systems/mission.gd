extends Node
## Last Signal — Mission tracker (Phase 8).
##
## Three stages: restore power (solve 3 puzzles) → activate the 3
## communication towers → send the emergency transmission. Progress is
## counted regardless of order: a tower activated early still counts
## (checked in _check_advance), so the mission can never get stuck by
## doing things "too early". Completing the mission sets is_complete and
## emits mission_completed; the level shows the win screen (Phase 10),
## which pauses the game.

signal objective_completed(id: String)
signal mission_completed

const TOTAL_PUZZLES := 3
const TOTAL_TOWERS := 3

var puzzles_solved: int = 0
var towers_active: int = 0
var is_complete: bool = false

## 0 = puzzles, 1 = towers, 2 = transmit, 3 = done.
var _stage: int = 0


func current_text() -> String:
	match _stage:
		0:
			return "هدف: وصل کردن برق — پازل‌ها را حل کن (%d/3)" % puzzles_solved
		1:
			return "هدف: روشن کردن دکل‌ها (%d/3)" % towers_active
		2:
			return "هدف: ارسال سیگنال اضطراری"
		_:
			return "مأموریت کامل شد!"


## Current stage (0 = puzzles, 1 = towers, 2 = transmit, 3 = done).
## Used by the level for the contextual HUD hint.
func current_stage() -> int:
	return _stage


func on_puzzle_solved() -> void:
	puzzles_solved += 1
	_check_advance()


func on_tower_activated() -> void:
	towers_active += 1
	_check_advance()


func try_transmit() -> bool:
	if _stage != 2 or is_complete:
		return false
	is_complete = true
	_stage = 3
	mission_completed.emit()
	return true


func _check_advance() -> void:
	if _stage == 0 and puzzles_solved >= TOTAL_PUZZLES:
		_stage = 1
		objective_completed.emit("puzzles")
	elif _stage == 1 and towers_active >= TOTAL_TOWERS:
		_stage = 2
		objective_completed.emit("towers")
