extends RoomBase
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

func _ready() -> void:
	room_key = "medical_wing"
	area_name = "بخش پزشکی"
	room_rect = Rect2(0, 0, 640, 368)
	room_tile_rect = Rect2i(0, 0, 40, 23)
	area_hint = str(LevelData.AREA_HINTS[area_name])
	spawn_point = Vector2(64, 256)
	tint_color = Color(0.5, 0.9, 0.6, 0.07)
	_build_floor_if_standalone()
	_build_wall_rects(wall_rects())
	_build_tint()
	_build_zone()
	_add_area_console(Vector2(120, 80), "گزارش پزشکی: بعد از تمرین شیوع بیماری، این بخش بسته شد. آذوقه کم است.", "monitor_vitals")
	_add_prop(LevelData.CRATE_TEXTURE, Vector2(480, 300))
	_add_decor(LevelData.PANEL_TEXTURE, Vector2(60, 340))
	_add_decor(LevelData.RIVET_TEXTURE, Vector2(600, 80))
	_build_medical_props()


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
		return MedicalData.MED_WALL_V_TEXTURE
	if r in [Rect2(0, 352, 288, 16), Rect2(320, 352, 320, 16)]:
		return MedicalData.MED_WALL_H_TEXTURE
	return LevelData.WALL_TEXTURE


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
	# The doctor's desk: flashlight + handwritten note on its surface.
	_add_med_decor("flashlight", Vector2(432, 252), "MedFlashlight")
	_add_med_decor("note_doctor", Vector2(450, 260), "MedNoteDoctor")
