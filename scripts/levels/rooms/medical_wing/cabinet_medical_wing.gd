## Last Signal — Medical Wing code cabinet (P6, 2026-11-26).
extends Node2D
## The first puzzle of the wing: a locked cabinet with three dials. This node
## is a CHILD OF THE BODY of a solid cabinet prop (MedCabinetWorn), the way
## NoteConsole2 sits on the doctor's desk: the prop keeps its sprite, its
## collision and its nav-grid rect untouched, and this node only adds the
## interaction. The three dials (dial_medical_wing.tscn) are its children.
##
## E on a dial cycles its digit 0-9 (wrapping) and shows «کد: ۰۰۰» (the
## current digits as ONE number, no spaces; dial 1 is the first digit and the
## LEFTMOST dial, so the boxes and the number read the same way). When the
## digits equal `code` (the room passes NOTE_DIGITS) the cabinet opens: the
## prop's sprite becomes cabinet_open, the HUD says «کابینت باز شد.», the
## dials lock, the cabinet and the dials leave group "interactable", and the
## reward pickup (the room sets it: the medicine) appears in front of it. A
## wrong code does nothing else: no sound, no penalty. E on the closed
## cabinet itself only says it is locked.
##
## Same interactable interface as console.gd: group "interactable" +
## interact_label / interact() / set_highlighted(bool). Never in groups
## "puzzles" or "hidden". The only signal is `opened`; it has no
## `interacted`, `collected` or `solved`, so the wiring never touches it.
##
## It talks to the player and the HUD itself (as fuse_box_medical_wing.gd
## does) and keeps working after the full-game flatten (level_01.gd frees the
## room node and keeps its children): it never refers to the room.
##
## The reward pickup appears long after the level's wiring connected the
## pickups that existed at start, so the wiring never sees it. This node
## therefore connects the pickup's `collected` itself and does what the
## wiring does for a pickup: inventory, blip, ring, HUD message (the room's
## own `reward_message` when it sets one, else "<name> برداشته شد.").
##
## `reward_collected(item_id)` (P7) is emitted at the end of that handling,
## once the reward is in the inventory and its message is up: MedicalWing
## connects the medicine's recovery sequence to it (recovery_medical_wing.gd),
## since the pickup itself only exists after the cabinet opens.

signal opened
## The reward pickup was collected and handled (item id of the reward).
signal reward_collected(item_id: String)

const DIAL_SCENE: PackedScene = preload("res://scenes/levels/rooms/medical_wing/dial_medical_wing.tscn")
const PICKUP_SCENE: PackedScene = preload("res://scenes/levels/rooms/medical_wing/pickup_medical_wing.tscn")
const FX_RING_SCENE: PackedScene = preload("res://scenes/levels/rooms/medical_wing/fx_ring_medical_wing.tscn")
const OPEN_TEXTURE: Texture2D = preload("res://assets/sprites/medical-wing/cabinet_open.png")
const PERSIAN_DIGITS := "۰۱۲۳۴۵۶۷۸۹"
const LOCKED_MESSAGE := "کابینت قفله. رمز سه‌رقمی می‌خواد."
const OPEN_MESSAGE := "کابینت باز شد."
## The dial row, relative to this node (the cabinet's centre): DIAL_ROW_Y px
## in front of the cabinet (on the room side), DIAL_SPACING px between
## neighbouring dials, so the player's nearest-interactable pick (range 40)
## is clear.
const DIAL_ROW_Y := -20.0
const DIAL_SPACING := 20.0
## Dial positions, dial 1 first. Dial 1 is the LEFTMOST dial and dial 3 the
## rightmost, so the boxes read 4 1 7 left to right, the same as the number in
## «کد: ۴۱۷» (digits are left-to-right even inside right-to-left text).
const DIAL_OFFSETS: Array[Vector2] = [
	Vector2(-DIAL_SPACING, DIAL_ROW_Y),
	Vector2(0.0, DIAL_ROW_Y),
	Vector2(DIAL_SPACING, DIAL_ROW_Y)]

@export var interact_label: String = "بررسی کابینت"

## The code, one digit per dial (dial 1 first). Empty: it never opens.
var code: Array = []
## What each dial's prompt calls its digit ("چرخاندن <name>"), in code order;
## set by the room before add_child (DIGIT_NAMES). A dial without a name
## falls back to "رقم <its number>".
var digit_names: Array = []
## The pickup that appears in front of the cabinet when it opens (set by the
## room before add_child). An empty reward_item: nothing appears.
var reward_item: String = ""
var reward_display: String = ""
var reward_label: String = ""
## The HUD message when the reward is collected; empty: the usual
## "<display name> برداشته شد.".
var reward_message: String = ""
var reward_node_name: String = "Pickup"
var reward_texture: Texture2D = null
## Where it appears, relative to the cabinet prop's body (same space as the
## body's own position, whatever node the body hangs from).
var reward_offset: Vector2 = Vector2.ZERO

var is_open: bool = false

var _dials: Array[Node2D] = []


func _ready() -> void:
	for i in DIAL_OFFSETS.size():
		var dial: Node2D = DIAL_SCENE.instantiate()
		dial.name = "MedDial%d" % (i + 1)
		dial.position = DIAL_OFFSETS[i]
		dial.dial_index = i + 1
		var digit_name := "رقم " + PERSIAN_DIGITS[i + 1]
		if i < digit_names.size():
			digit_name = str(digit_names[i])
		dial.interact_label = "چرخاندن " + digit_name
		dial.turned.connect(_on_dial_turned)
		add_child(dial)
		_dials.append(dial)


func interact() -> void:
	if is_open:
		return
	_show_message(LOCKED_MESSAGE)


## The prop's sprite is the cabinet's look, so it is what lights up.
func set_highlighted(highlighted: bool) -> void:
	var sprite := _body_sprite()
	if sprite != null:
		sprite.modulate = Color(1.5, 1.4, 0.7) if highlighted else Color.WHITE


## The dials in order (dial 1 first), for the room's tests and for whoever
## places something next to them.
func dials() -> Array[Node2D]:
	return _dials


## The dials' digits as ONE Persian number, dial 1 first, no spaces: "۰۰۰".
## Persian digits are bidi class EN: as one run they keep their left-to-right
## order inside the right-to-left HUD text («کد: ۴۱۷» reads 4 1 7); with
## spaces between them the paragraph direction would reverse them.
func code_text() -> String:
	var text := ""
	for dial in _dials:
		text += PERSIAN_DIGITS[int(dial.digit)]
	return text


func _on_dial_turned(_index: int) -> void:
	if is_open:
		return
	if _code_matches():
		_open()
	else:
		_show_message("کد: " + code_text())


func _code_matches() -> bool:
	if code.size() != _dials.size():
		return false
	for i in _dials.size():
		if int(_dials[i].digit) != int(code[i]):
			return false
	return true


func _open() -> void:
	is_open = true
	var sprite := _body_sprite()
	if sprite != null:
		sprite.texture = OPEN_TEXTURE
	set_highlighted(false)
	for dial in _dials:
		dial.lock()
	remove_from_group("interactable")
	_show_message(OPEN_MESSAGE)
	_spawn_reward()
	opened.emit()


func _spawn_reward() -> void:
	var body := get_parent() as Node2D
	if reward_item == "" or body == null or body.get_parent() == null:
		return
	var pickup: Node2D = PICKUP_SCENE.instantiate()
	pickup.name = reward_node_name
	pickup.position = body.position + reward_offset
	pickup.item_id = reward_item
	pickup.display_name = reward_display
	pickup.interact_label = reward_label
	pickup.amount = 1
	pickup.battery_restore = 0.0
	pickup.sprite_texture = reward_texture
	pickup.collected.connect(_on_reward_collected)
	body.get_parent().add_child(pickup)


## What the wiring does for a collected pickup (it never saw this one).
func _on_reward_collected(pickup: Node2D) -> void:
	var player := _get_player()
	if player != null:
		player.add_item(pickup.item_id, pickup.amount, pickup.battery_restore)
	_play_sound("blip")
	var ring: Node2D = FX_RING_SCENE.instantiate()
	ring.position = pickup.position
	ring.ring_color = Color(1.0, 0.85, 0.3)
	ring.max_radius = 24.0
	pickup.get_parent().add_child(ring)
	if reward_message != "":
		_show_message(reward_message)
	else:
		_show_message(pickup.display_name + " برداشته شد.")
	reward_collected.emit(pickup.item_id)


## The prop's own sprite: the only Sprite2D child of the body this node hangs
## from (the dials are grandchildren, so they never match).
func _body_sprite() -> Sprite2D:
	var body := get_parent()
	if body == null:
		return null
	for child in body.get_children():
		if child is Sprite2D:
			return child as Sprite2D
	return null


func _show_message(text: String) -> void:
	var hud := _get_hud()
	if hud != null:
		hud.show_message(text)


## Null-safe, like the wiring's helper (no AudioManager in level-only tests).
func _play_sound(sound_name: String) -> void:
	var audio: Node = get_tree().get_first_node_in_group("audio")
	if audio != null:
		audio.play(sound_name)


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


## The player of THIS branch of the tree: the nearest "Player" child of an
## ancestor (Level01 in the full game, the launcher when standalone); the
## "player" group only as a fallback, since it is ambiguous whenever two
## levels are alive at once.
func _get_player() -> Node2D:
	var node := get_parent()
	while node != null:
		var found := node.get_node_or_null("Player") as Node2D
		if found != null:
			return found
		node = node.get_parent()
	return get_tree().get_first_node_in_group("player") as Node2D
