extends Node
## Last Signal — medbay mission (2026-11-28).
##
## Per-room copy, written for this room: no puzzles, no keycard, no
## ending sequence. The room's only goal is to explore the medbay
## while staying out of the four patrol robots' sight. The mission
## never completes — it is a standing objective, shown on the HUD
## by the wiring, exactly like the template room shows its own.

signal objective_completed(id: String)
signal mission_completed

var is_complete: bool = false

## The single standing objective (kept short on purpose: the shared
## HUD centers the objective at x=320, and a text wider than
## ~200 px prints under the puzzles label or the minimap).
func current_text() -> String:
	return "Medbay را بگرد؛ دیده نشو"


## Current stage (0 = the only stage). Used by the wiring for the
## contextual HUD hint.
func current_stage() -> int:
	return 0
