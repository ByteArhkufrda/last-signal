## Per-room copy (absolute separation, 2026-11-23): identical to the shared original; only paths point at this room's own copies.
extends Node2D
## Last Signal — One-shot expanding ring effect (Phase 9).
##
## Draws a circle outline that expands and fades, then frees itself.
## Used for pickup collects (gold), tower activations (cyan) and the
## mission-complete signal (green). The radar pulse keeps its own ring
## (Phase 4) — this one is the generic feedback effect.

@export var ring_color: Color = Color(1.0, 0.85, 0.3)
@export var max_radius: float = 24.0
@export var duration: float = 0.4

var _t: float = 0.0


func _process(delta: float) -> void:
	_t += delta
	if _t >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var p := _t / duration
	var c := ring_color
	c.a = 1.0 - p
	draw_arc(Vector2.ZERO, maxf(max_radius * p, 1.0), 0, TAU, 32, c, 2.0)
