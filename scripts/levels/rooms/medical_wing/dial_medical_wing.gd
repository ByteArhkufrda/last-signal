## Last Signal — Medical Wing cabinet dial (P6, 2026-11-26).
extends Node2D
## One digit dial of the code cabinet's lock (cabinet_medical_wing.gd builds
## three of them). Pattern of puzzle_switch.gd, as this room's own file.
##
## Same interactable interface as console.gd: group "interactable" (from the
## scene) + interact_label / interact() / set_highlighted(bool). E cycles the
## digit 0 -> 9 -> 0 and reports it with `turned(index)`; the cabinet owns the
## code check and the HUD message. The cabinet locks the dial when it opens:
## lock() makes E do nothing and leaves group "interactable".
##
## Not in group "puzzles" or "hidden". It has no `interacted`, `collected` or
## `solved` signal, so no wiring ever touches it. The look is built in code
## (a small plate and a Persian digit), so the scene stays a bare node.

signal turned(index: int)

const PERSIAN_DIGITS := "۰۱۲۳۴۵۶۷۸۹"
const PLATE_HALF := 6.0
const COLOR_RIM := Color(0.62, 0.66, 0.74)
const COLOR_PLATE := Color(0.13, 0.15, 0.2)
const COLOR_DIGIT := Color(0.85, 1.0, 0.9)
const DIGIT_FONT_SIZE := 10
## The digit's Label is 16 x 16 px around the dial's centre and centres its
## LINE BOX, not the ink of the digit. Vazirmatn's line box at
## DIGIT_FONT_SIZE 10 is ~15.6 px (ascent 2100/2048 em = 10.3 px, descent
## 1100/2048 em = 5.4 px) and a Persian digit is ~6.5 px tall (1336/2048 em)
## and sits on the baseline with no descender, so where the ink lands inside
## the box depends on how the Label places that line. This offset moves the
## whole Label (px, negative = up) to put the ink in the middle of the plate;
## it was started at -2 from the playtest (the digit looked too low) and is
## the one number to tune by eye.
const DIGIT_Y_OFFSET := -2.0

## 1-based position in the code (dial 1 is the first digit).
@export var dial_index: int = 1
@export var interact_label: String = "چرخاندن رقم اول"

## The digit the dial shows now, 0-9.
var digit: int = 0

var _locked: bool = false
var _label: Label = null


func _ready() -> void:
	var rim := Polygon2D.new()
	rim.polygon = _square(PLATE_HALF + 1.0)
	rim.color = COLOR_RIM
	add_child(rim)
	var plate := Polygon2D.new()
	plate.polygon = _square(PLATE_HALF)
	plate.color = COLOR_PLATE
	add_child(plate)
	_label = Label.new()
	_label.size = Vector2(16, 16)
	_label.position = Vector2(-8.0, -8.0 + DIGIT_Y_OFFSET)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", DIGIT_FONT_SIZE)
	_label.add_theme_color_override("font_color", COLOR_DIGIT)
	add_child(_label)
	_refresh()


func interact() -> void:
	if _locked:
		return
	set_digit(digit + 1)
	turned.emit(dial_index)


## Show `value` (wrapped into 0-9). Does not emit `turned`.
func set_digit(value: int) -> void:
	digit = posmod(value, 10)
	_refresh()


## The cabinet opened: the dial stops reacting and leaves "interactable".
func lock() -> void:
	_locked = true
	set_highlighted(false)
	remove_from_group("interactable")


func is_locked() -> bool:
	return _locked


func set_highlighted(highlighted: bool) -> void:
	modulate = Color(1.5, 1.4, 0.7) if highlighted else Color.WHITE


func _refresh() -> void:
	if _label != null:
		_label.text = PERSIAN_DIGITS[digit]


func _square(half: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half),
		Vector2(half, half), Vector2(-half, half)])
