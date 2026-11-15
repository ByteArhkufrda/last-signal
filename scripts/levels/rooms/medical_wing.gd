extends RoomBase
## Last Signal — Medical Wing room (medical_wing), split from
## level_01.gd / level_01.tscn, 2026-11-15.
##
## The top-right wing (pack sprites, 2026-11-15): the ward row, the
## west column, the doctor's desk, wall decor, lights and floor
## clutter, the area console, the crate, the panel/rivet decors and
## the scanner robot at (900, 120). Positions are unchanged; the
## furnishing moved verbatim from _build_medical_props().

func _ready() -> void:
	room_key = "medical_wing"
	area_name = "بخش پزشکی"
	room_rect = Rect2(640, 0, 640, 368)
	room_tile_rect = Rect2i(40, 0, 40, 23)
	area_hint = str(LevelData.AREA_HINTS[area_name])
	spawn_point = Vector2(704, 256)
	tint_color = Color(0.5, 0.9, 0.6, 0.07)
	_build_floor_if_standalone()
	_build_wall_rects(wall_rects())
	_build_tint()
	_build_zone()
	_add_area_console(Vector2(760, 80), "گزارش پزشکی: بعد از تمرین شیوع بیماری، این بخش بسته شد. آذوقه کم است.", "monitor_vitals")
	_add_prop(LevelData.CRATE_TEXTURE, Vector2(1120, 300))
	_add_decor(LevelData.PANEL_TEXTURE, Vector2(700, 340))
	_add_decor(LevelData.RIVET_TEXTURE, Vector2(1240, 80))
	_build_medical_props()


func wall_rects() -> Array[Rect2]:
	return [
		Rect2(624, 0, 16, 240), Rect2(624, 272, 16, 96),
		Rect2(640, 352, 288, 16), Rect2(960, 352, 320, 16),
		Rect2(1264, 0, 16, 368),
	]


func blocked_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = wall_rects()
	rects.append_array(prop_solid_rects())
	return rects


## Every solid prop rect inside this wing (the medical furniture plus
## the crate at (1120, 300), which sits in this rect).
func prop_solid_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for r in LevelData.PROP_SOLID_RECTS:
		if room_rect.intersects(r):
			rects.append(r)
	return rects


## Medical Wing furnishing (pack sprites, 2026-11-15). Solid props get
## a physics body + a PROP_SOLID_RECTS entry (nav grid); wall decor and
## small floor clutter are plain sprites. Nothing solid is placed in
## either doorway approach, in the entry corridor (y 240-272, x 640-800)
## or on the scanner's line of sight (x=900, y 120-200).
func _build_medical_props() -> void:
	# Ward row along the north edge: three beds, an exam bed, monitors.
	_add_prop(_med_texture("bed_standard"), Vector2(700, 64), Vector2(32, 16), "MedBedStandard")
	_add_prop(_med_texture("bed_empty"), Vector2(880, 64), Vector2(32, 16), "MedBedEmpty")
	_add_prop(_med_texture("exam_bed"), Vector2(1080, 64), Vector2(32, 16), "MedExamBed")
	_add_prop(_med_texture("bedside_table"), Vector2(732, 64), Vector2(16, 16), "MedBedsideTable")
	_add_prop(_med_texture("monitor_heart"), Vector2(920, 64), Vector2(16, 16), "MedMonitorHeart")
	_add_prop(_med_texture("defibrillator"), Vector2(1160, 64), Vector2(16, 16), "MedDefibrillator")
	# West column: the disorganized bed, cabinets, oxygen, IV.
	_add_prop(_med_texture("bed_disorganized"), Vector2(700, 160), Vector2(32, 16), "MedBedDisorganized")
	_add_prop(_med_texture("monitor_vitals"), Vector2(732, 160), Vector2(16, 16), "MedMonitorVitals")
	_add_prop(_med_texture("cabinet_open"), Vector2(660, 112), Vector2(16, 16), "MedCabinetOpen")
	_add_prop(_med_texture("cabinet_closed"), Vector2(660, 160), Vector2(16, 16), "MedCabinetClosed")
	_add_prop(_med_texture("oxygen_cylinder"), Vector2(660, 200), Vector2(16, 16), "MedOxygen")
	_add_prop(_med_texture("iv_stand"), Vector2(660, 296), Vector2(16, 16), "MedIvStand")
	_add_prop(_med_texture("cabinet_storage"), Vector2(660, 320), Vector2(16, 16), "MedCabinetStorage")
	_add_prop(_med_texture("cabinet_medicine"), Vector2(700, 320), Vector2(16, 16), "MedCabinetMedicine")
	# Center: lamp, chairs, infusion pump, side table.
	_add_prop(_med_texture("exam_lamp"), Vector2(720, 200), Vector2(16, 16), "MedExamLamp")
	_add_prop(_med_texture("chair_rolling"), Vector2(760, 200), Vector2(16, 16), "MedChairRolling")
	_add_prop(_med_texture("infusion_pump"), Vector2(760, 120), Vector2(16, 16), "MedInfusionPump")
	_add_prop(_med_texture("side_table"), Vector2(940, 240), Vector2(16, 16), "MedSideTable")
	_add_prop(_med_texture("chair_office"), Vector2(1040, 200), Vector2(16, 16), "MedChairOffice")
	# East side: stretcher, doctor's desk, trolley, cart, shelf, boxes.
	_add_prop(_med_texture("stretcher"), Vector2(1080, 160), Vector2(32, 16), "MedStretcher")
	_add_prop(_med_texture("desk_doctor"), Vector2(1080, 256), Vector2(32, 16), "MedDeskDoctor")
	_add_prop(_med_texture("trolley"), Vector2(1160, 240), Vector2(16, 16), "MedTrolley")
	_add_prop(_med_texture("cart_emergency"), Vector2(1020, 300), Vector2(16, 16), "MedCartEmergency")
	_add_prop(_med_texture("shelf_medicine"), Vector2(1240, 200), Vector2(16, 16), "MedShelfMedicine")
	_add_prop(_med_texture("oxygen_unit"), Vector2(1240, 140), Vector2(16, 16), "MedOxygenUnit")
	_add_prop(_med_texture("supply_boxes"), Vector2(1180, 120), Vector2(16, 16), "MedSupplyBoxes")
	_add_prop(_med_texture("waste_bin"), Vector2(1240, 320), Vector2(16, 16), "MedWasteBin")
	_add_prop(_med_texture("cabinet_worn"), Vector2(1180, 320), Vector2(16, 16), "MedCabinetWorn")
	# Wall decor: west divider, south divider, junctions, east wall.
	_add_med_decor("clock_wall", Vector2(632, 40), "MedClock")
	_add_med_decor("wall_access_panel", Vector2(632, 100), "MedAccessPanel")
	_add_med_decor("window_small", Vector2(632, 160), "MedWindowSmall")
	_add_med_decor("grille_vent", Vector2(632, 200), "MedGrilleVent")
	_add_med_decor("panel_wall_small", Vector2(632, 300), "MedWallPanel")
	_add_med_decor("sign_warning", Vector2(632, 320), "MedWarningSign")
	_add_med_decor("window_observation", Vector2(1000, 360), "MedWindowObservation")
	_add_med_decor("wall_cabinet_section", Vector2(1100, 360), "MedWallCabinet")
	_add_med_decor("wall_corner_inner", Vector2(632, 360), "MedCornerSW")
	_add_med_decor("wall_corner_outer", Vector2(1272, 360), "MedCornerSE")
	_add_med_decor("fusebox_closed", Vector2(1272, 60), "MedFusebox")
	_add_med_decor("indicator_emergency", Vector2(1272, 200), "MedIndicator")
	# Lights: ceiling fixtures + small indicators.
	_add_med_decor("light_ceiling", Vector2(800, 40), "MedLightCeilingA")
	_add_med_decor("light_ceiling", Vector2(1100, 320), "MedLightCeilingB")
	_add_med_decor("light_green", Vector2(760, 64), "MedLightGreen")
	_add_med_decor("light_blue", Vector2(860, 40), "MedLightBlue")
	_add_med_decor("light_red", Vector2(1240, 340), "MedLightRed")
	_add_med_decor("light_flicker", Vector2(1100, 200), "MedLightFlicker")
	_add_med_decor("light_damaged", Vector2(1200, 280), "MedLightDamaged")
	# Small floor clutter: supplies, papers, storytelling details.
	_add_med_decor("documents", Vector2(800, 150), "MedDocuments")
	_add_med_decor("bottles_medicine", Vector2(860, 200), "MedBottles")
	_add_med_decor("packages_medicine", Vector2(980, 120), "MedPackages")
	_add_med_decor("gloves", Vector2(820, 300), "MedGloves")
	_add_med_decor("bandages", Vector2(860, 300), "MedBandages")
	_add_med_decor("syringes", Vector2(900, 300), "MedSyringes")
	_add_med_decor("tray_instruments", Vector2(940, 300), "MedTray")
	_add_med_decor("paper_scattered", Vector2(820, 180), "MedPapers")
	_add_med_decor("chair_fallen", Vector2(960, 160), "MedChairFallen")
	_add_med_decor("dust", Vector2(700, 300), "MedDust")
	_add_med_decor("steam", Vector2(1180, 200), "MedSteam")
	_add_med_decor("spark", Vector2(1240, 100), "MedSpark")
	# The doctor's desk: flashlight + handwritten note on its surface.
	_add_med_decor("flashlight", Vector2(1072, 252), "MedFlashlight")
	_add_med_decor("note_doctor", Vector2(1090, 260), "MedNoteDoctor")
