extends Node2D
## Last Signal — medical_wing (self-contained room module, 2026-11-23).
##
## Absolute separation: this file shares NOTHING with the other
## rooms. The former RoomBase helpers, the floor builder, the
## textures and hints it needs are all inlined here; its wiring,
## player, mission and interaction/enemy scenes live as copies
## in this room's own folders. Only sprite/texture art (assets/)
## is still shared — art, not logic. The assembled level
## (level_01.gd) keeps the original shared files; no room reads
## them.

const TILE_SIZE := 16
const ROOM_COLS := 80
const ROOM_ROWS := 58
const FLOOR_TEXTURE_PATH := "res://assets/sprites/environment/floor_atlas.png"
const FLOOR_VARIANT_CHANCE := 0.15
const FLOOR_RNG_SEED := 17
const MED_FLOOR_TEXTURE_PATH := "res://assets/sprites/environment/floor_medical_atlas.png"
const MED_FLOOR_WEIGHTS := [0.70, 0.78, 0.84, 0.85, 0.87, 0.89, 0.92, 0.94, 0.97, 0.98, 0.99, 1.0]
const MED_RECT_TILES := Rect2i(40, 0, 40, 23)
const WALL_TEXTURE: Texture2D = preload("res://assets/sprites/environment/wall_metal.png")
const CONSOLE_SCENE: PackedScene = preload("res://scenes/levels/rooms/medical_wing/console_medical_wing.tscn")
const PICKUP_SCENE: PackedScene = preload("res://scenes/levels/rooms/medical_wing/pickup_medical_wing.tscn")
const FUSE_BOX_SCENE: PackedScene = preload("res://scenes/levels/rooms/medical_wing/fuse_box_medical_wing.tscn")
const CABINET_SCENE: PackedScene = preload("res://scenes/levels/rooms/medical_wing/cabinet_medical_wing.tscn")
const MEDICAL_PAIN: GDScript = preload("res://scripts/levels/rooms/medical_wing/pain_medical_wing.gd")
const MEDICAL_RECOVERY: GDScript = preload("res://scripts/levels/rooms/medical_wing/recovery_medical_wing.gd")
const MED_WALL_H_TEXTURE: Texture2D = preload("res://assets/sprites/medical-wing/wall_h.png")
const MED_WALL_V_TEXTURE: Texture2D = preload("res://assets/sprites/medical-wing/wall_v.png")
const MED_PROP_PATHS := {
	"bed_standard": "res://assets/sprites/medical-wing/bed_standard.png",
	"bed_empty": "res://assets/sprites/medical-wing/bed_empty.png",
	"bed_disorganized": "res://assets/sprites/medical-wing/bed_disorganized.png",
	"bedside_table": "res://assets/sprites/medical-wing/bedside_table.png",
	"exam_bed": "res://assets/sprites/medical-wing/exam_bed.png",
	"stretcher": "res://assets/sprites/medical-wing/stretcher.png",
	"desk_doctor": "res://assets/sprites/medical-wing/desk_doctor.png",
	"cabinet_storage": "res://assets/sprites/medical-wing/cabinet_storage.png",
	"cabinet_medicine": "res://assets/sprites/medical-wing/cabinet_medicine.png",
	"cabinet_open": "res://assets/sprites/medical-wing/cabinet_open.png",
	"cabinet_closed": "res://assets/sprites/medical-wing/cabinet_closed.png",
	"cabinet_worn": "res://assets/sprites/medical-wing/cabinet_worn.png",
	"shelf_medicine": "res://assets/sprites/medical-wing/shelf_medicine.png",
	"monitor_vitals": "res://assets/sprites/medical-wing/monitor_vitals.png",
	"monitor_heart": "res://assets/sprites/medical-wing/monitor_heart.png",
	"oxygen_cylinder": "res://assets/sprites/medical-wing/oxygen_cylinder.png",
	"oxygen_unit": "res://assets/sprites/medical-wing/oxygen_unit.png",
	"iv_stand": "res://assets/sprites/medical-wing/iv_stand.png",
	"infusion_pump": "res://assets/sprites/medical-wing/infusion_pump.png",
	"exam_lamp": "res://assets/sprites/medical-wing/exam_lamp.png",
	"defibrillator": "res://assets/sprites/medical-wing/defibrillator.png",
	"waste_bin": "res://assets/sprites/medical-wing/waste_bin.png",
	"trolley": "res://assets/sprites/medical-wing/trolley.png",
	"cart_emergency": "res://assets/sprites/medical-wing/cart_emergency.png",
	"chair_rolling": "res://assets/sprites/medical-wing/chair_rolling.png",
	"chair_office": "res://assets/sprites/medical-wing/chair_office.png",
	"side_table": "res://assets/sprites/medical-wing/side_table.png",
	"supply_boxes": "res://assets/sprites/medical-wing/supply_boxes.png",
	"clock_wall": "res://assets/sprites/medical-wing/clock_wall.png",
	"wall_access_panel": "res://assets/sprites/medical-wing/wall_access_panel.png",
	"window_small": "res://assets/sprites/medical-wing/window_small.png",
	"window_observation": "res://assets/sprites/medical-wing/window_observation.png",
	"wall_cabinet_section": "res://assets/sprites/medical-wing/wall_cabinet_section.png",
	"wall_corner_inner": "res://assets/sprites/medical-wing/wall_corner_inner.png",
	"wall_corner_outer": "res://assets/sprites/medical-wing/wall_corner_outer.png",
	"grille_vent": "res://assets/sprites/medical-wing/grille_vent.png",
	"panel_wall_small": "res://assets/sprites/medical-wing/panel_wall_small.png",
	"sign_warning": "res://assets/sprites/medical-wing/sign_warning.png",
	"fusebox_closed": "res://assets/sprites/medical-wing/fusebox_closed.png",
	"indicator_emergency": "res://assets/sprites/medical-wing/indicator_emergency.png",
	"light_ceiling": "res://assets/sprites/medical-wing/light_ceiling.png",
	"light_green": "res://assets/sprites/medical-wing/light_green.png",
	"light_red": "res://assets/sprites/medical-wing/light_red.png",
	"light_blue": "res://assets/sprites/medical-wing/light_blue.png",
	"light_flicker": "res://assets/sprites/medical-wing/light_flicker.png",
	"light_damaged": "res://assets/sprites/medical-wing/light_damaged.png",
	"documents": "res://assets/sprites/medical-wing/documents.png",
	"bottles_medicine": "res://assets/sprites/medical-wing/bottles_medicine.png",
	"packages_medicine": "res://assets/sprites/medical-wing/packages_medicine.png",
	"gloves": "res://assets/sprites/medical-wing/gloves.png",
	"bandages": "res://assets/sprites/medical-wing/bandages.png",
	"syringes": "res://assets/sprites/medical-wing/syringes.png",
	"tray_instruments": "res://assets/sprites/medical-wing/tray_instruments.png",
	"paper_scattered": "res://assets/sprites/medical-wing/paper_scattered.png",
	"chair_fallen": "res://assets/sprites/medical-wing/chair_fallen.png",
	"dust": "res://assets/sprites/medical-wing/dust.png",
	"steam": "res://assets/sprites/medical-wing/steam.png",
	"spark": "res://assets/sprites/medical-wing/spark.png",
	"flashlight": "res://assets/sprites/medical-wing/flashlight.png",
	"note_doctor": "res://assets/sprites/medical-wing/note_doctor.png",
}

## Last Signal — Medical Wing room (medical_wing), split from
## level_01.gd / level_01.tscn, 2026-11-15.
##
## The top-right wing (pack sprites, 2026-11-15): the ward row, the
## west column, the doctor's desk, wall decor, lights and floor
## clutter, the area console, the crate, the panel/rivet decors and
## the scanner robot at local (260, 120) (was (900, 120) in
## station coordinates). Station offset is (40, 0) tiles; positions below
## are all local. The
## furnishing moved verbatim from _build_medical_props().
##
## Story notes (P1, 2026-11-23): three note consoles that reveal the
## "outbreak" was a cover story — see NOTE_CONSOLES / _build_note_consoles().
##
## Darkness (P2, 2026-11-24; reworked in P5, 2026-11-26): the wing runs on
## EMERGENCY power: it is lit from the start, its lights flicker, and one
## spot of it, the dark zone (see DARK_ZONE), is always dark. The child
## node "MedicalDarkness" (darkness_medical_wing.gd) draws both, with a
## light circle around the player (the flashlight item makes it bigger).
## CAUTION: the assembler (level_01.gd _flatten_rooms) frees THIS node and
## keeps its children, so power_on / power_restored / restore_power() below
## work only standalone. In the full game, call restore_power() on the
## surviving level.get_node("MedicalDarkness") instead.
##
## Dormant robots (P3, 2026-11-24; P7, 2026-11-27): the robots in this room
## are dormant (MedicalDarkness sets their `dormant` flag) until
## MedicalDarkness.wake_robots(), which the recovery sequence calls after the
## medicine is taken. The fuse box no longer wakes them.
##
## Power puzzle (P4, 2026-11-25; P5, 2026-11-26): take the FLASHLIGHT that
## lies on the doctor's desk (MedDeskDoctor/MedFlashlight, see
## FLASHLIGHT_PICKUP), go into the dark zone, find the FUSE there
## (MedFusePickup, see FUSE_PICKUP), put it in the FUSE BOX (MedFuseBox,
## see FUSE_BOX) and MedicalDarkness stabilises the local power: the
## flicker stops and the chime plays (the robots stay dormant, see P7).
##
## Medical Recovery (P6, 2026-11-26): read the notes (each ends with one code
## digit, see NOTE_DIGITS), set the code on the three dials of the CABINET
## (MedCabinetWorn/MedCabinet, see CABINET) and take the MEDICINE it gives
## (see MEDICINE_PICKUP): the HUD says the pain is gone. No door depends on
## it yet.
##
## Pain and recovery (P7, 2026-11-27): until the medicine is taken, a slow
## dark vignette pulses at the screen edges while the player is in the room
## (MedicalPain, pain_medical_wing.gd). Taking the medicine makes it fade out
## for good and starts MedicalRecovery (recovery_medical_wing.gd): the central
## AI's two garbled HUD messages, then MedicalDarkness.wake_robots(); it also
## emits `medical_recovery_done` once and ticks off task 0 on a HUD that has
## set_task_done(). Both nodes are children, so they survive the full-game
## flatten; this node's own `medical_recovery_done` works only standalone.
##
## None of these nodes is in group "puzzles" or "hidden": the mission
## counters and the pinned 3 puzzles / 3 hidden objects do not know them.

## Sprite and prompt of the note consoles. "note_doctor" is the pack's
## handwritten-note sprite (it used to lie on the doctor's desk as an
## inert decor; NoteConsole2 now sits there as a real, readable note).
const NOTE_TEXTURE_KEY := "note_doctor"
const NOTE_LABEL := "خواندن یادداشت"
## Name, LOCAL position and HUD text of each note console; an "on" key
## parents the console to that prop's body (see _add_note_console). The text
## is the BASE text: the code digit is appended in code (see NOTE_DIGITS).
## Placement rules: off both doorways (the entry corridor y 240-272
## x 0-160, the south gap x 288-320), off the scanner's line of sight
## (x=260, y 120-200), 230+ px from the scanner itself, and 100+ px from
## each other and from the area console, so the player's
## nearest-interactable pick (range 40) is never ambiguous. Except for
## the one on the desk, each also sits on free floor (no sprite or solid
## within 24 px). Positions are pinned in test_rooms.gd.
const NOTE_CONSOLES := [
	{
		"name": "NoteConsole1", "pos": Vector2(140, 320),
		"text": "پزشک: هیچ بیماری‌ای نیست. دستور اومد بخش رو ببندیم.",
	},
	{
		"name": "NoteConsole2", "pos": Vector2(450, 260), "on": "MedDeskDoctor",
		"text": "پزشک: هر بار پیام می‌فرستادیم، یه چیزی جواب می‌داد.",
	},
	{
		"name": "NoteConsole3", "pos": Vector2(560, 160),
		"text": "پزشک: هر سیگنالی که بفرستیم، فقط ما رو نجات نمی‌ده.",
	},
]

## The cabinet's code (P6): one digit per note (note 1, 2, 3 = dial 1, 2, 3).
## Each note's HUD message ends with its digit, appended in code
## (_note_message) and NOT stored in the NOTE_CONSOLES texts, so the texts
## can be rewritten without touching the code. HUD messages do not wrap
## (600 px label): base text + "  (رقم اول: ۴)" must stay <= 72 characters.
const NOTE_DIGITS := [4, 1, 7]
## How the digits are named, in code order: each note's message ends with
## "(<name>: <digit>)" and each dial's prompt is "چرخاندن <name>", so the
## player knows which dial a digit belongs to whatever order the notes are
## read in. (The HUD's code line is «کد: ۴۱۷», one number: P7b.)
const DIGIT_NAMES := ["رقم اول", "رقم دوم", "رقم سوم"]
const PERSIAN_DIGITS := "۰۱۲۳۴۵۶۷۸۹"

## The power puzzle (P4). LOCAL positions, pinned in test_rooms.gd.
##
## The fuse box stands where the P3 placeholder switch stood, in the
## north-east corner next to the fuse-box decor (MedFusebox, east wall):
## free floor, 330+ px from the scanner (260, 120) and clear of both
## doorways, so standing at it never puts the player in the scanner's
## reach when the robots wake up. It is not solid (nothing is added to
## the nav grid or to prop_solid_rects()).
##
## The dark zone (P5): a LOCAL rect, 120 x 90 px, dark whenever the player
## is in the room (flicker or not, even after restore_power()). It is the
## free alcove along the north wall between MedMonitorHeart and
## MedExamBed: every real corner of this room holds solid props, and this
## is the only 120 x 90 area that touches no solid prop (8 px off the
## monitor and the bed, the north wall on its back), no doorway
## approach and not the scanner's line of sight (the strip
## Rect2(232,100,56,120)). It is open to the south, so it is reachable,
## and holds no sprite or console. Pinned in test_rooms.gd.
const DARK_ZONE := Rect2(296, 16, 120, 90)

## The fuse (P4, moved into the dark zone in P5): a visible pickup (NOT
## in group "hidden": no radar needed) in the middle of the zone (52 px
## from its west and east sides), 40 px from the nearest sprite (24+
## wanted), off every doorway approach and the scanner's line of sight,
## 217+ px from every console (the nearest-interactable range is 40) and
## 235 px (200+ wanted) from the fuse box, so the player carries it
## across the room. It is only ~111 px from the scanner, inside the
## scanner's 180 px detection radius, which is safe: the scanner is
## dormant until the power is back.
const FUSE_BOX := {
	"name": "MedFuseBox", "pos": Vector2(590, 44),
}
const FUSE_PICKUP := {
	"name": "MedFusePickup", "pos": Vector2(356, 64),
}

## The code cabinet (P6): the solid cabinet prop MedCabinetWorn in the
## south-east corner (its body, sprite and nav-grid rect stay as they were).
## Its interactable child "MedCabinet" sits at the prop's centre
## (540, 320) and carries three dials (MedDial1-3, built by
## cabinet_medical_wing.gd) in a row 20 px north of it, on the room side:
## local (520, 300), (540, 300), (560, 300): dial 1 is the LEFTMOST dial (P7b)
## so the boxes read 4 1 7 left to right, like the HUD's «کد: ۴۱۷». The corner
## is far from everything: 80+ px from every console (the nearest-interactable
## range is 40), 255+ px from the fuse box, 310+ px from the scanner, off both
## doorway approaches and the scanner's line of sight, and the dial plates
## (14 px) touch no solid prop
## or wall (25+ px from every other solid prop, 5 px from the cabinet itself
## and from the MedLightDamaged decor). Reachable from the entry corridor.
## Pinned in test_rooms.gd.
const CABINET := {"prop": "MedCabinetWorn", "name": "MedCabinet"}

## The medicine (P6): what the open cabinet gives, a visible pickup that
## appears at "offset" from the cabinet prop's body, i.e. at local (530, 276),
## in front of the dials: 9 px above them, 14 px from the MedLightDamaged
## decor, 80+ px from every console. Item "medicine" (display «مسکّن», the
## medical pack's blister pack of pills); collecting it also shows "message"
## instead of the usual "<name> برداشته شد.".
const MEDICINE_PICKUP := {
	"name": "MedMedicinePickup", "offset": Vector2(-10, -44),
	"item": "medicine", "display": "مسکّن", "label": "برداشتن مسکّن",
	"texture": "packages_medicine", "message": "درد کم شد. حالم بهتر شد.",
}

## The flashlight (P5; the desk's own MedFlashlight since P6): the ONE
## flashlight of the wing, a visible pickup that lies on the doctor's desk
## where the MedFlashlight decor used to lie, at local (432, 252). There is no
## separate floor pickup and no decor any more. Like NoteConsole2 it is a
## CHILD of the desk's body (the only solid rect it may overlap, so the
## player's line-of-sight ray ignores that body): "pos" is its LOCAL spot,
## "on" the prop it hangs from. It is 19.7 px from NoteConsole2 (west half of
## the desk against the east half), so the nearest-interactable pick depends
## on the side the player stands on; it is well outside the dark zone (the
## player must take it before going in).
const FLASHLIGHT_PICKUP := {
	"name": "MedFlashlight", "pos": Vector2(432, 252), "on": "MedDeskDoctor",
	"item": "flashlight", "display": "چراغ‌قوه", "label": "برداشتن چراغ‌قوه",
	"texture": "flashlight",
}

## Emitted once, when the power comes back (the darkness node's signal).
signal power_restored
## Emitted once, when the medicine is collected (the recovery node's signal);
## standalone only, like power_restored: in the full game connect to
## level.get_node("MedicalRecovery").medical_recovery_done.
signal medical_recovery_done

const MEDICAL_DARKNESS: GDScript = preload("res://scripts/levels/rooms/medical_wing/darkness_medical_wing.gd")

## False until restore_power(): until then the wing runs on emergency
## power (lit, flickering, robots dormant).
var power_on: bool = false

var _darkness: Node2D = null
var _pain: Node2D = null
var _recovery: Node = null


func _ready() -> void:
	room_key = "medical_wing"
	area_name = "بخش پزشکی"
	room_rect = Rect2(0, 0, 640, 368)
	room_tile_rect = Rect2i(0, 0, 40, 23)
	area_hint = "بخش پزشکی — یک ربات اسکنر اینجا نگهبانی می‌دهد؛ در دیدش نمان"
	spawn_point = Vector2(64, 256)
	tint_color = Color(0.5, 0.9, 0.6, 0.07)
	_build_floor_if_standalone()
	_build_wall_rects(wall_rects())
	_build_tint()
	_build_zone()
	_add_area_console(Vector2(120, 80), "گزارش پزشکی: بعد از تمرین شیوع بیماری، این بخش بسته شد. آذوقه کم است.", "monitor_vitals")
	_add_prop(preload("res://assets/sprites/props/crate.png"), Vector2(480, 300))
	_add_decor(preload("res://assets/sprites/props/control_panel.png"), Vector2(60, 340))
	_add_decor(preload("res://assets/sprites/props/riveted_panel.png"), Vector2(600, 80))
	_build_medical_props()
	_build_note_consoles()
	_build_darkness()
	_build_pain()
	_build_recovery()
	_build_flashlight_pickup()
	_build_cabinet()
	_build_fuse_pickup()
	_build_fuse_box()


func wall_rects() -> Array[Rect2]:
	return [
		Rect2(-16, 0, 16, 240), Rect2(-16, 272, 16, 96),
		Rect2(0, 352, 288, 16), Rect2(320, 352, 320, 16),
		Rect2(624, 0, 16, 368),
		# North exterior (2026-11-19: this edge had no wall — the
		# player walked off the map above the wing, in the full game).
		Rect2(0, 0, 640, 16),
	]


func blocked_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = wall_rects()
	rects.append_array(prop_solid_rects())
	return rects


## Every solid prop rect inside this wing, in LOCAL coordinates (the
## medical furniture plus the crate, whose centre is (480, 300)).
func prop_solid_rects() -> Array[Rect2]:
	return [
		Rect2(44, 56, 32, 16), Rect2(224, 56, 32, 16), Rect2(424, 56, 32, 16),
		Rect2(44, 152, 32, 16), Rect2(424, 152, 32, 16), Rect2(424, 248, 32, 16),
		Rect2(84, 56, 16, 16), Rect2(84, 152, 16, 16), Rect2(272, 56, 16, 16),
		Rect2(12, 152, 16, 16), Rect2(12, 104, 16, 16), Rect2(12, 192, 16, 16),
		Rect2(12, 288, 16, 16), Rect2(12, 312, 16, 16), Rect2(52, 312, 16, 16),
		Rect2(72, 192, 16, 16), Rect2(112, 192, 16, 16), Rect2(112, 112, 16, 16),
		Rect2(592, 192, 16, 16), Rect2(592, 132, 16, 16), Rect2(532, 112, 16, 16),
		Rect2(512, 56, 16, 16), Rect2(592, 312, 16, 16), Rect2(512, 232, 16, 16),
		Rect2(372, 292, 16, 16), Rect2(392, 192, 16, 16), Rect2(292, 232, 16, 16),
		Rect2(532, 312, 16, 16), Rect2(472, 292, 16, 16),
	]


## The pack's wall tile for a code-built wall rect, in LOCAL
## coordinates: the west divider and east wall use the vertical pack
## tile, the south divider the horizontal one, the rest wall_metal.
func wall_texture_for_local(r: Rect2) -> Texture2D:
	if r in [Rect2(-16, 0, 16, 240), Rect2(-16, 272, 16, 96),
			Rect2(624, 0, 16, 368)]:
		return MED_WALL_V_TEXTURE
	if r in [Rect2(0, 352, 288, 16), Rect2(320, 352, 320, 16)]:
		return MED_WALL_H_TEXTURE
	return WALL_TEXTURE


func exits() -> Array[Dictionary]:
	return [
		{"id": "west", "edge": "west", "rect": Rect2(-16, 240, 16, 32),
			"target_room": "command_center", "target_exit": "east"},
		{"id": "south", "edge": "south", "rect": Rect2(288, 352, 32, 16),
			"target_room": "engine_room", "target_exit": "north"},
	]


## Medical Wing furnishing (pack sprites, 2026-11-15). Solid props get
## a physics body + a prop_solid_rects() entry (nav grid); wall decor and
## small floor clutter are plain sprites. Nothing solid is placed in
## either doorway approach, in the entry corridor (y 240-272, x 0-160)
## or on the scanner's line of sight (x=260, y 120-200).
func _build_medical_props() -> void:
	# Ward row along the north edge: three beds, an exam bed, monitors.
	_add_prop(_med_texture("bed_standard"), Vector2(60, 64), Vector2(32, 16), "MedBedStandard")
	_add_prop(_med_texture("bed_empty"), Vector2(240, 64), Vector2(32, 16), "MedBedEmpty")
	_add_prop(_med_texture("exam_bed"), Vector2(440, 64), Vector2(32, 16), "MedExamBed")
	_add_prop(_med_texture("bedside_table"), Vector2(92, 64), Vector2(16, 16), "MedBedsideTable")
	_add_prop(_med_texture("monitor_heart"), Vector2(280, 64), Vector2(16, 16), "MedMonitorHeart")
	_add_prop(_med_texture("defibrillator"), Vector2(520, 64), Vector2(16, 16), "MedDefibrillator")
	# West column: the disorganized bed, cabinets, oxygen, IV.
	_add_prop(_med_texture("bed_disorganized"), Vector2(60, 160), Vector2(32, 16), "MedBedDisorganized")
	_add_prop(_med_texture("monitor_vitals"), Vector2(92, 160), Vector2(16, 16), "MedMonitorVitals")
	_add_prop(_med_texture("cabinet_open"), Vector2(20, 112), Vector2(16, 16), "MedCabinetOpen")
	_add_prop(_med_texture("cabinet_closed"), Vector2(20, 160), Vector2(16, 16), "MedCabinetClosed")
	_add_prop(_med_texture("oxygen_cylinder"), Vector2(20, 200), Vector2(16, 16), "MedOxygen")
	_add_prop(_med_texture("iv_stand"), Vector2(20, 296), Vector2(16, 16), "MedIvStand")
	_add_prop(_med_texture("cabinet_storage"), Vector2(20, 320), Vector2(16, 16), "MedCabinetStorage")
	_add_prop(_med_texture("cabinet_medicine"), Vector2(60, 320), Vector2(16, 16), "MedCabinetMedicine")
	# Center: lamp, chairs, infusion pump, side table.
	_add_prop(_med_texture("exam_lamp"), Vector2(80, 200), Vector2(16, 16), "MedExamLamp")
	_add_prop(_med_texture("chair_rolling"), Vector2(120, 200), Vector2(16, 16), "MedChairRolling")
	_add_prop(_med_texture("infusion_pump"), Vector2(120, 120), Vector2(16, 16), "MedInfusionPump")
	_add_prop(_med_texture("side_table"), Vector2(300, 240), Vector2(16, 16), "MedSideTable")
	_add_prop(_med_texture("chair_office"), Vector2(400, 200), Vector2(16, 16), "MedChairOffice")
	# East side: stretcher, doctor's desk, trolley, cart, shelf, boxes.
	_add_prop(_med_texture("stretcher"), Vector2(440, 160), Vector2(32, 16), "MedStretcher")
	_add_prop(_med_texture("desk_doctor"), Vector2(440, 256), Vector2(32, 16), "MedDeskDoctor")
	_add_prop(_med_texture("trolley"), Vector2(520, 240), Vector2(16, 16), "MedTrolley")
	_add_prop(_med_texture("cart_emergency"), Vector2(380, 300), Vector2(16, 16), "MedCartEmergency")
	_add_prop(_med_texture("shelf_medicine"), Vector2(600, 200), Vector2(16, 16), "MedShelfMedicine")
	_add_prop(_med_texture("oxygen_unit"), Vector2(600, 140), Vector2(16, 16), "MedOxygenUnit")
	_add_prop(_med_texture("supply_boxes"), Vector2(540, 120), Vector2(16, 16), "MedSupplyBoxes")
	_add_prop(_med_texture("waste_bin"), Vector2(600, 320), Vector2(16, 16), "MedWasteBin")
	_add_prop(_med_texture("cabinet_worn"), Vector2(540, 320), Vector2(16, 16), "MedCabinetWorn")
	# Wall decor: west divider, south divider, junctions, east wall.
	_add_med_decor("clock_wall", Vector2(-8, 40), "MedClock")
	_add_med_decor("wall_access_panel", Vector2(-8, 100), "MedAccessPanel")
	_add_med_decor("window_small", Vector2(-8, 160), "MedWindowSmall")
	_add_med_decor("grille_vent", Vector2(-8, 200), "MedGrilleVent")
	_add_med_decor("panel_wall_small", Vector2(-8, 300), "MedWallPanel")
	_add_med_decor("sign_warning", Vector2(-8, 320), "MedWarningSign")
	_add_med_decor("window_observation", Vector2(360, 360), "MedWindowObservation")
	_add_med_decor("wall_cabinet_section", Vector2(460, 360), "MedWallCabinet")
	_add_med_decor("wall_corner_inner", Vector2(-8, 360), "MedCornerSW")
	_add_med_decor("wall_corner_outer", Vector2(632, 360), "MedCornerSE")
	_add_med_decor("fusebox_closed", Vector2(632, 60), "MedFusebox")
	_add_med_decor("indicator_emergency", Vector2(632, 200), "MedIndicator")
	# Lights: ceiling fixtures + small indicators.
	_add_med_decor("light_ceiling", Vector2(160, 40), "MedLightCeilingA")
	_add_med_decor("light_ceiling", Vector2(460, 320), "MedLightCeilingB")
	_add_med_decor("light_green", Vector2(120, 64), "MedLightGreen")
	_add_med_decor("light_blue", Vector2(220, 40), "MedLightBlue")
	_add_med_decor("light_red", Vector2(600, 340), "MedLightRed")
	_add_med_decor("light_flicker", Vector2(460, 200), "MedLightFlicker")
	_add_med_decor("light_damaged", Vector2(560, 280), "MedLightDamaged")
	# Small floor clutter: supplies, papers, storytelling details.
	_add_med_decor("documents", Vector2(160, 150), "MedDocuments")
	_add_med_decor("bottles_medicine", Vector2(220, 200), "MedBottles")
	_add_med_decor("packages_medicine", Vector2(340, 120), "MedPackages")
	_add_med_decor("gloves", Vector2(180, 300), "MedGloves")
	_add_med_decor("bandages", Vector2(220, 300), "MedBandages")
	_add_med_decor("syringes", Vector2(260, 300), "MedSyringes")
	_add_med_decor("tray_instruments", Vector2(300, 300), "MedTray")
	_add_med_decor("paper_scattered", Vector2(180, 180), "MedPapers")
	_add_med_decor("chair_fallen", Vector2(320, 160), "MedChairFallen")
	_add_med_decor("dust", Vector2(60, 300), "MedDust")
	_add_med_decor("steam", Vector2(540, 200), "MedSteam")
	_add_med_decor("spark", Vector2(600, 100), "MedSpark")
	# The handwritten note on the doctor's desk is NoteConsole2
	# (_build_note_consoles) and its flashlight is the pickup MedFlashlight
	# (_build_flashlight_pickup): neither is a decor any more.


## The three story-note consoles (non-solid: nothing is added to the nav
## grid or to prop_solid_rects()). Added after the props so they draw
## above any floor clutter.
func _build_note_consoles() -> void:
	for i in NOTE_CONSOLES.size():
		var note: Dictionary = NOTE_CONSOLES[i]
		_add_note_console(note["name"], note["pos"], _note_message(i), note.get("on", ""))


## The HUD message of note `index`: its base text plus the code digit,
## e.g. "...  (رقم اول: ۴)" (DIGIT_NAMES[index], then the Persian digit
## NOTE_DIGITS[index]).
func _note_message(index: int) -> String:
	var digit := int(NOTE_DIGITS[index])
	return str(NOTE_CONSOLES[index]["text"]) + "  (" + DIGIT_NAMES[index] + ": " + PERSIAN_DIGITS[digit] + ")"


## The dark zone's LOCAL rect (the room contract is untouched: this is an
## addition, used by the tests and by whoever places things in the zone).
func dark_zone_rect() -> Rect2:
	return DARK_ZONE


## The flicker + dark-zone darkness (a child node, so the flatten keeps it
## alive — see the header note). room_rect and zone_rect are local, and so
## is the node.
func _build_darkness() -> void:
	_darkness = MEDICAL_DARKNESS.new()
	_darkness.name = "MedicalDarkness"
	_darkness.room_rect = room_rect
	_darkness.zone_rect = DARK_ZONE
	_darkness.power_restored.connect(_on_power_restored)
	add_child(_darkness)


## The local power stabilises: the flicker stops and the chime plays (the dark
## zone stays dark and the robots stay dormant until the medicine, see
## MedicalRecovery). Works while this node is alive (standalone); in the full
## game use level.get_node("MedicalDarkness").restore_power() (the fuse box
## does, through its `solved` signal).
func restore_power() -> void:
	if _darkness != null:
		_darkness.restore_power()


func _on_power_restored() -> void:
	power_on = true
	power_restored.emit()


## The pain vignette (P7): a child node (so the flatten keeps it alive) that
## pulses at the screen edges while the player is in the room, until the
## medicine is taken. room_rect is local, and so is the node.
func _build_pain() -> void:
	_pain = MEDICAL_PAIN.new()
	_pain.name = "MedicalPain"
	_pain.room_rect = room_rect
	add_child(_pain)


## The recovery sequence (P7): what follows the medicine (pain fade, the AI's
## messages, the robots waking). A plain Node child, so the flatten keeps it
## alive. It needs the pain and the darkness nodes, built before it.
func _build_recovery() -> void:
	_recovery = MEDICAL_RECOVERY.new()
	_recovery.name = "MedicalRecovery"
	_recovery.pain = _pain
	_recovery.darkness = _darkness
	_recovery.medical_recovery_done.connect(_on_recovery_done)
	add_child(_recovery)


func _on_recovery_done() -> void:
	medical_recovery_done.emit()


## The flashlight (P5; the desk's own MedFlashlight since P6): an instance of
## this room's pickup copy with the item id, texts and sprite of
## FLASHLIGHT_PICKUP, hung from the desk's body (see FLASHLIGHT_PICKUP). The
## player's inventory then holds "flashlight", which MedicalDarkness reads to
## widen the light. Built after the props (the desk is one of them).
func _build_flashlight_pickup() -> void:
	var desk: Node2D = get_node(FLASHLIGHT_PICKUP["on"])
	var pos: Vector2 = FLASHLIGHT_PICKUP["pos"]
	var pickup: Node2D = PICKUP_SCENE.instantiate()
	pickup.name = FLASHLIGHT_PICKUP["name"]
	pickup.position = pos - desk.position
	pickup.item_id = FLASHLIGHT_PICKUP["item"]
	pickup.display_name = FLASHLIGHT_PICKUP["display"]
	pickup.interact_label = FLASHLIGHT_PICKUP["label"]
	pickup.sprite_texture = _med_texture(FLASHLIGHT_PICKUP["texture"])
	pickup.amount = 1
	pickup.battery_restore = 0.0
	desk.add_child(pickup)


## The code cabinet (P6): an interactable child of the body of the solid
## prop CABINET["prop"] (the nav grid and prop_solid_rects() are untouched;
## the prop's name, sprite and collision stay). It builds its own three dials
## and, when the dials equal NOTE_DIGITS, opens and spawns the medicine in
## front of itself (MEDICINE_PICKUP). It never refers to this room, so it
## keeps working after the full-game flatten frees the room node. Its
## `reward_collected` signal (the medicine was taken) starts the recovery
## sequence (P7), a sibling node that survives the flatten too.
func _build_cabinet() -> void:
	var body: Node2D = get_node(CABINET["prop"])
	var cabinet: Node2D = CABINET_SCENE.instantiate()
	cabinet.name = CABINET["name"]
	cabinet.code = NOTE_DIGITS.duplicate()
	cabinet.digit_names = DIGIT_NAMES.duplicate()
	cabinet.reward_node_name = MEDICINE_PICKUP["name"]
	cabinet.reward_offset = MEDICINE_PICKUP["offset"]
	cabinet.reward_item = MEDICINE_PICKUP["item"]
	cabinet.reward_display = MEDICINE_PICKUP["display"]
	cabinet.reward_label = MEDICINE_PICKUP["label"]
	cabinet.reward_message = MEDICINE_PICKUP["message"]
	cabinet.reward_texture = _med_texture(MEDICINE_PICKUP["texture"])
	cabinet.reward_collected.connect(_recovery.medicine_collected)
	body.add_child(cabinet)


## The fuse (P4): an instance of this room's pickup copy, whose defaults
## are item "fuse" x1, no battery. Same interactable interface as every
## pickup; the level's wiring listens to `collected`, adds the item to the
## player's inventory and shows the HUD message.
func _build_fuse_pickup() -> void:
	var pickup: Node2D = PICKUP_SCENE.instantiate()
	pickup.name = FUSE_PICKUP["name"]
	pickup.position = FUSE_PICKUP["pos"]
	pickup.item_id = "fuse"
	pickup.display_name = "فیوز"
	pickup.interact_label = "برداشتن فیوز"
	pickup.amount = 1
	pickup.battery_restore = 0.0
	add_child(pickup)


## The fuse box (P4): its `solved` signal is bound to MedicalDarkness.
## That node survives the full-game flatten, so the box keeps working
## there; a connection to this room would not (the flatten frees it).
## The box talks to the player and the HUD itself.
func _build_fuse_box() -> void:
	var box: Node2D = FUSE_BOX_SCENE.instantiate()
	box.name = FUSE_BOX["name"]
	box.position = FUSE_BOX["pos"]
	add_child(box)
	box.solved.connect(_darkness.restore_power)


## One note console. Same pattern as _add_area_console (console scene +
## message + a medical sprite), plus a node name (so tests and later steps
## can find it; the flatten into Level01 keeps it) and a "read note"
## prompt instead of "use console". With on_prop, the console becomes a
## child of that prop's body: the player's line-of-sight ray excludes the
## target's parent bodies, so a note lying ON a solid prop stays readable,
## like the panel switches on their panel. pos is LOCAL either way.
func _add_note_console(node_name: String, pos: Vector2, message: String, on_prop: String = "") -> void:
	var console: Node2D = CONSOLE_SCENE.instantiate()
	console.name = node_name
	console.message = message
	console.interact_label = NOTE_LABEL
	console.sprite_texture = _med_texture(NOTE_TEXTURE_KEY)
	if on_prop == "":
		console.position = pos
		add_child(console)
	else:
		var prop: Node2D = get_node(on_prop)
		console.position = pos - prop.position
		prop.add_child(console)


## Room key, e.g. "command_center". Also the wall-body suffix.
var room_key: String = ""
## Area name as in LevelData.AREAS, e.g. "کنترل مرکزی".
var area_name: String = ""
## Pixel rect of the area, in LOCAL coordinates: position is (0, 0).
var room_rect: Rect2 = Rect2()
## Tile rect of the area, in LOCAL coordinates: position is (0, 0).
var room_tile_rect: Rect2i = Rect2i()
## The room's position in the station map, in tiles. Set by the
## assembler (level_01.gd) or the standalone launcher (room_play.gd)
## BEFORE add_child, so _ready can use it. It only feeds the floor
## builder: rolls are read at the GLOBAL cell, so the standalone floor
## matches the assembled floor. Standalone it is still the station
## offset — the floor pattern belongs to the station, not the room.
var tile_offset: Vector2i = Vector2i.ZERO
## Where this room node actually sits, in pixels. The assembler sets
## it to tile_offset * TILE_SIZE (and room.position to match); the
## standalone launcher leaves it at (0, 0), so local == global there.
var map_offset: Vector2 = Vector2.ZERO
## HUD hint shown on entering the area.
var area_hint: String = ""
## Where the player spawns when the room is played standalone.
var spawn_point: Vector2 = Vector2.ZERO
## Floor tint (Color(0,0,0,0) = no tint).
var tint_color: Color = Color(0, 0, 0, 0)
## Set by the launcher for standalone play.
var standalone: bool = false

var _med_tex: Dictionary = {}


## This room's pixel rect in STATION (world) coordinates.
func world_rect() -> Rect2:
	return Rect2(room_rect.position + map_offset, room_rect.size)

## A local rect translated to station (world) coordinates.
func to_world_rect(r: Rect2) -> Rect2:
	return Rect2(r.position + map_offset, r.size)

## A local point translated to station (world) coordinates.
func to_world_point(p: Vector2) -> Vector2:
	return p + map_offset

func _wall_texture_for(r: Rect2) -> Texture2D:
	return wall_texture_for_local(r)

## Doorway gaps in this room's walls, for the standalone launcher.
## In the full map the gaps open into the neighbouring rooms; in
## standalone there is nothing beyond them, so the launcher seals them
## with walls. Computed from wall_rects(): on each wall line (one x
## for vertical walls, one y for horizontal), the intervals the
## room's wall rects do not cover, bounded by the room's own extent.
## Walls the .tscn builds (Central's north/west ring) are not in
## wall_rects(), so they never produce a spurious gap here.
func doorway_gap_rects() -> Array[Rect2]:
	var gaps: Array[Rect2] = []
	var vertical: Dictionary = {}
	var horizontal: Dictionary = {}
	for r in wall_rects():
		if r.size.x == 16 and r.size.y > 16:
			if not vertical.has(r.position.x):
				vertical[r.position.x] = []
			(vertical[r.position.x] as Array).append(r)
		elif r.size.y == 16 and r.size.x > 16:
			if not horizontal.has(r.position.y):
				horizontal[r.position.y] = []
			(horizontal[r.position.y] as Array).append(r)
	for x in vertical.keys():
		var rects: Array = vertical[x]
		rects.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.y < b.position.y)
		var covered: float = room_rect.position.y
		for r in rects:
			if r.position.y > covered:
				gaps.append(Rect2(x, covered, 16, r.position.y - covered))
			covered = maxf(covered, r.end.y)
		if covered < room_rect.end.y:
			gaps.append(Rect2(x, covered, 16, room_rect.end.y - covered))
	for y in horizontal.keys():
		var rects: Array = horizontal[y]
		rects.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.x < b.position.x)
		var covered: float = room_rect.position.x
		for r in rects:
			if r.position.x > covered:
				gaps.append(Rect2(covered, y, r.position.x - covered, 16))
			covered = maxf(covered, r.end.x)
		if covered < room_rect.end.x:
			gaps.append(Rect2(covered, y, room_rect.end.x - covered, 16))
	return gaps

## Build the room's code-built walls as one StaticBody2D named
## "Walls_<room_key>". Textured Polygon2D (UVs = the rect's coords,
## texture repeats every 16 px, white color) + a darker edge
## highlight. Coordinates are LOCAL; the assembler translates them to
## world coordinates when it flattens the room into the level.
func _build_wall_rects(rects: Array[Rect2], body_name: String = "") -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = body_name if body_name != "" else "Walls_" + room_key
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	for r in rects:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(r.size.x, r.size.y)
		shape.shape = rect
		shape.position = r.get_center()
		body.add_child(shape)
		var visual := Polygon2D.new()
		visual.polygon = PackedVector2Array([
			r.position, r.position + Vector2(r.size.x, 0),
			r.position + r.size, r.position + Vector2(0, r.size.y)])
		visual.uv = visual.polygon
		var wall_tex: Texture2D = _wall_texture_for(r)
		visual.texture = wall_tex if wall_tex != null else WALL_TEXTURE
		visual.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		visual.color = Color.WHITE
		body.add_child(visual)
		var highlight := Polygon2D.new()
		if r.size.x >= r.size.y:
			highlight.polygon = PackedVector2Array([
				r.position + Vector2(0, r.size.y - 4), r.position + Vector2(r.size.x, r.size.y - 4),
				r.position + r.size, r.position + Vector2(0, r.size.y)])
		else:
			highlight.polygon = PackedVector2Array([
				r.position + Vector2(r.size.x - 4, 0), r.position + Vector2(r.size.x, 0),
				r.position + r.size, r.position + Vector2(r.size.x - 4, r.size.y)])
		highlight.color = Color(0.22, 0.24, 0.32, 1)
		body.add_child(highlight)
	return body

## Area floor tint polygon (skipped when the tint is transparent).
func _build_tint() -> void:
	if tint_color.a <= 0.0:
		return
	var r: Rect2 = room_rect
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		r.position, r.position + Vector2(r.size.x, 0),
		r.position + r.size, r.position + Vector2(0, r.size.y)])
	poly.color = tint_color
	add_child(poly)

## Entry zone for the area. It only carries the area name as metadata;
## the assembler / launcher connects body_entered to the wiring.
func _build_zone() -> void:
	var r: Rect2 = room_rect
	var zone := Area2D.new()
	zone.name = "AreaZone_" + area_name.replace(" ", "")
	zone.set_meta("area_name", area_name)
	zone.collision_layer = 0
	zone.collision_mask = 1
	zone.monitoring = true
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = r.size
	shape.shape = rect
	shape.position = r.get_center()
	zone.add_child(shape)
	add_child(zone)

## Standalone only: build this room's floor tiles (its tile rect) with
## the same seeded rolls the whole-map floor uses, so the standalone
## floor matches the assembled floor cell for cell. Rolls are read at
## the GLOBAL cell (local + tile_offset); cells are written locally.
func _build_floor_if_standalone() -> void:
	if not standalone:
		return
	var layer := TileMapLayer.new()
	layer.name = "Floor"
	layer.tile_set = build_tileset()
	add_child(layer)
	build_floor(layer, room_tile_rect, tile_offset)

## Interactable area console with a log message (verbatim from
## level_01.gd). texture_key loads a medical sprite for the console.
func _add_area_console(pos: Vector2, message: String, texture_key: String = "") -> void:
	var console: Node2D = CONSOLE_SCENE.instantiate()
	console.position = pos
	console.message = message
	if texture_key != "":
		console.sprite_texture = _med_texture(texture_key)
	add_child(console)

## Solid prop: sprite + physics body (verbatim from level_01.gd).
func _add_prop(texture: Texture2D, pos: Vector2, size: Vector2 = Vector2(16, 16), prop_name: String = "") -> void:
	var body := StaticBody2D.new()
	if prop_name != "":
		body.name = prop_name
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	var sprite := Sprite2D.new()
	sprite.texture = texture
	body.add_child(sprite)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)

## A plain non-solid decor sprite.
func _add_decor(texture: Texture2D, pos: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = pos
	add_child(sprite)

## Navigation grid for a tile region. Verbatim logic from level_01.gd
## _build_nav_grid, parameterized: walls are solid but NOT inflated
## (the 32 px doorways would close); props are inflated by one cell
## (a 12x14 body following a cell-center path passes within 1 px of a
## 16x16 obstacle's corner and gets stuck sliding on it — measured
## 2026-11-12).
static func build_nav_grid(tile_rect: Rect2i, blocked: Array[Rect2], inflatable: Array[Rect2]) -> AStarGrid2D:
	var grid := AStarGrid2D.new()
	grid.region = tile_rect
	grid.cell_size = Vector2(TILE_SIZE, TILE_SIZE)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for x in range(tile_rect.position.x, tile_rect.end.x):
		for y in range(tile_rect.position.y, tile_rect.end.y):
			var cell := Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
			for r in blocked:
				if cell.intersects(r):
					grid.set_point_solid(Vector2i(x, y), true)
					break
	for r in inflatable:
		var min_cell := Vector2i(int(r.position.x / TILE_SIZE) - 1, int(r.position.y / TILE_SIZE) - 1)
		var max_cell := Vector2i(int(r.end.x / TILE_SIZE) + 1, int(r.end.y / TILE_SIZE) + 1)
		for cx in range(min_cell.x, max_cell.x):
			for cy in range(min_cell.y, max_cell.y):
				if tile_rect.has_point(Vector2i(cx, cy)):
					grid.set_point_solid(Vector2i(cx, cy), true)
	return grid

## Security-robot patrol points, in LOCAL coordinates. Scanner rooms
## leave this empty — the wiring posts a scanner at its own position.
func patrol_points_local() -> Array[Vector2]:
	return []

## Cached loader for the medical prop textures (MedicalData).
func _med_texture(key: String) -> Texture2D:
	if not _med_tex.has(key):
		_med_tex[key] = load(MED_PROP_PATHS[key])
	return _med_tex[key]

## A named, non-solid medical decor sprite (pack texture by key).
func _add_med_decor(key: String, pos: Vector2, node_name: String) -> void:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = _med_texture(key)
	sprite.position = pos
	add_child(sprite)


static var _rolls: PackedFloat32Array = PackedFloat32Array()


static func _ensure_rolls() -> void:
	if not _rolls.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = FLOOR_RNG_SEED
	_rolls.resize(ROOM_COLS * ROOM_ROWS)
	for x in ROOM_COLS:
		for y in ROOM_ROWS:
			_rolls[x * ROOM_ROWS + y] = rng.randf()


## Roll for one cell, in the original generation order.
static func roll_at(cell: Vector2i) -> float:
	_ensure_rolls()
	return _rolls[cell.x * ROOM_ROWS + cell.y]


static func build_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var source := TileSetAtlasSource.new()
	source.texture = load(FLOOR_TEXTURE_PATH)
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	source.create_tile(Vector2i.ZERO)
	source.create_tile(Vector2i(1, 0))
	tileset.add_source(source)
	# Medical Wing floor: the pack's 12-tile atlas. Cells outside the
	# wing keep the old two tiles.
	var med_source := TileSetAtlasSource.new()
	med_source.texture = load(MED_FLOOR_TEXTURE_PATH)
	med_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for i in 12:
		med_source.create_tile(Vector2i(i, 0))
	tileset.add_source(med_source)
	return tileset


## First weight threshold above the roll: the medical floor tile index.
static func medical_floor_index(roll: float) -> int:
	for i in MED_FLOOR_WEIGHTS.size():
		if roll < MED_FLOOR_WEIGHTS[i]:
			return i
	return 0


## Fill `layer` (which must already have the tileset from
## build_tileset()) for the given tile rect. Source 0 is the standard
## two-tile atlas, source 1 the medical 12-tile atlas.
## `tile_rect` is in the layer's own (local) coordinates; `tile_offset`
## is the room's position in the station map, in tiles. Rolls and the
## medical-floor check use the GLOBAL cell (local + offset), so a room's
## standalone floor matches the assembled floor cell for cell, while
## the cells themselves are written at local coordinates.
static func build_floor(layer: TileMapLayer, tile_rect: Rect2i, tile_offset: Vector2i = Vector2i.ZERO) -> void:
	_ensure_rolls()
	for x in range(tile_rect.position.x, tile_rect.end.x):
		for y in range(tile_rect.position.y, tile_rect.end.y):
			var global_cell := Vector2i(x, y) + tile_offset
			var roll: float = roll_at(global_cell)
			if MED_RECT_TILES.has_point(global_cell):
				layer.set_cell(Vector2i(x, y), 1, Vector2i(medical_floor_index(roll), 0))
			else:
				var coord := Vector2i(1, 0) if roll < FLOOR_VARIANT_CHANCE else Vector2i.ZERO
				layer.set_cell(Vector2i(x, y), 0, coord)
