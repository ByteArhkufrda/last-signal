extends Node
## Last Signal — Medical Wing recovery (P7, 2026-11-27).
##
## Story, mission 1 "Medical Recovery": the character wakes in pain and must
## find medicine. When the medicine is taken, the pain ends, the central AI
## starts sending garbled messages and, shortly after, the AI's robots in the
## room wake up. This node runs that second half. In order, from the moment
## medicine_collected() is called (the cabinet's `reward_collected` signal):
##   1. the pain fades (MedicalPain.relieve(): its own 1.5 s fade);
##   2. `medical_recovery_done` is emitted once, and the HUD's
##      set_task_done(TASK_DONE_INDEX) is called if the HUD has that method
##      (the task list does not exist yet: no error without it);
##   3. SEQUENCE_DELAY seconds later (the cabinet's relief message, 3 s, is
##      on screen until then) the HUD shows each AI_MESSAGES entry for
##      MESSAGE_SECONDS each;
##   4. WAKE_DELAY seconds after the last message, MedicalDarkness.wake_robots().
## The timing runs from step(delta) (_process only forwards the frame time),
## so it is deterministic and, being a child of the scene, cannot outlive it:
## there are no SceneTreeTimers.
##
## Why a node of its own: the full-game assembler (level_01.gd _flatten_rooms)
## frees the MedicalWing node and keeps its children, so anything that must
## still happen later has to live in one of them. This node, like
## MedicalDarkness and MedicalPain, does: in the full game it is
## level.get_node("MedicalRecovery"). The room re-emits `medical_recovery_done`
## as its own room-level signal, but that works only while the room node is
## alive (standalone), like power_restored.
##
## The messages go to the HUD found the way the fuse box does it: a child
## called "HUD" of an ancestor, the "hud" group as a fallback; no HUD, no
## message and no error.

## Emitted once, when the medicine is collected (not when the sequence ends).
signal medical_recovery_done

## The central AI's garbled messages, in the order they are shown. Each one
## stays on the HUD MESSAGE_SECONDS; the HUD label has no wrapping and is 600 px
## wide, so each must stay <= 72 characters.
const AI_MESSAGES := [
	"هشدار... هشدار... ورودی ناشناس... ناشنا...",
	"سیستم... مرکزی... بازیابی... شد؟ هس... هسته...",
]
## Seconds from the medicine to the first AI message: the cabinet's relief
## message («درد کم شد...») lasts about 3 s and is read first.
const SEQUENCE_DELAY := 3.0
## Seconds each AI message has the HUD to itself.
const MESSAGE_SECONDS := 3.0
## Seconds from the end of the last message to the robots waking up.
const WAKE_DELAY := 0.5
## The HUD method that ticks the first task off, and its argument. The HUD
## has no task list yet, so it is only called when it exists.
const TASK_DONE_METHOD := "set_task_done"
const TASK_DONE_INDEX := 0

## The pain vignette and the darkness node (the robots' owner), siblings that
## survive the flatten; set by MedicalWing before add_child. Either may be
## null (the step then skips it).
var pain: Node = null
var darkness: Node = null
## True once the medicine was collected.
var is_done: bool = false

var _elapsed: float = 0.0
var _messages_shown: int = 0
var _woke: bool = false


func _process(delta: float) -> void:
	step(delta)


## The medicine was collected (the signal argument, the item id, is ignored).
## Runs once; later calls do nothing.
func medicine_collected(_item_id: String = "") -> void:
	if is_done:
		return
	is_done = true
	_elapsed = 0.0
	if pain != null:
		pain.relieve()
	medical_recovery_done.emit()
	_mark_task_done()


## Seconds from the medicine to the robots waking up.
func sequence_seconds() -> float:
	return SEQUENCE_DELAY + AI_MESSAGES.size() * MESSAGE_SECONDS + WAKE_DELAY


## Seconds from the medicine to AI message `index` appearing.
func message_time(index: int) -> float:
	return SEQUENCE_DELAY + index * MESSAGE_SECONDS


## True once the robots have been told to wake up.
func robots_woken() -> bool:
	return _woke


## How many AI messages have been shown so far.
func messages_shown() -> int:
	return _messages_shown


## Advance the sequence by delta seconds: every message and the wake-up that
## fall due are done in order, whatever the size of delta. Nothing happens
## before the medicine is collected.
func step(delta: float) -> void:
	if not is_done or _woke:
		return
	_elapsed += delta
	while _messages_shown < AI_MESSAGES.size() and _elapsed >= message_time(_messages_shown):
		_show_message(AI_MESSAGES[_messages_shown])
		_messages_shown += 1
	if _messages_shown >= AI_MESSAGES.size() and _elapsed >= sequence_seconds():
		_woke = true
		if darkness != null:
			darkness.wake_robots()


func _show_message(text: String) -> void:
	var hud := _get_hud()
	if hud != null:
		hud.show_message(text)


## The HUD's task hook: guarded by has_method, because the HUD may not have
## it yet, and called through `call` so nothing here is checked against a
## method the HUD does not declare.
func _mark_task_done() -> void:
	var hud := _get_hud()
	if hud != null and hud.has_method(TASK_DONE_METHOD):
		hud.call(TASK_DONE_METHOD, TASK_DONE_INDEX)


## The HUD of THIS branch of the tree: a child called "HUD" of an
## ancestor (Main in the full game), like the level wiring does, because
## the "hud" group can still hold a just-freed HUD for a frame; the group
## is only the fallback (level-only tests, a bare standalone room: null).
func _get_hud() -> CanvasLayer:
	var node := get_parent()
	while node != null:
		var found := node.get_node_or_null("HUD") as CanvasLayer
		if found != null:
			return found
		node = node.get_parent()
	return get_tree().get_first_node_in_group("hud") as CanvasLayer
