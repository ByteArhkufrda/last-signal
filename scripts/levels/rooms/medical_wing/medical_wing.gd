extends Node2D
## Last Signal — medical_wing (Godot 4.3+).
## Data-driven props, optional atmospheric effects and a room-local objective.
## Existing scenes, art and room/level integration remain external dependencies.
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
const MED_RECT_TILES := Rect2i(40, 0, 40, 23)
const MED_FLOOR_TILE := Vector2i(4, 0)
const WALL_TEXTURE: Texture2D = preload("res://assets/sprites/environment/wall_metal.png")
const CONSOLE_SCENE: PackedScene = preload("res://scenes/levels/rooms/medical_wing/console_medical_wing.tscn")
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
	"sink_ceramic": "res://assets/sprites/medical-wing/sink_ceramic.png",
	"wheelchair": "res://assets/sprites/medical-wing/wheelchair.png",
	"curtain_privacy": "res://assets/sprites/medical-wing/curtain_privacy.png",
	"fridge_medical": "res://assets/sprites/medical-wing/fridge_medical.png",
	"door_open": "res://assets/sprites/medical-wing/door_open.png",
	"door_frame": "res://assets/sprites/medical-wing/door_frame.png",
	"door_closed": "res://assets/sprites/medical-wing/door_closed.png",
	# Telegram hospital pack (room-1 clinic redesign, 2026-11-24).
	"tg_lab_sink": "res://assets/sprites/medical-wing/telegram/lab_sink.png",
	"tg_lab_computer": "res://assets/sprites/medical-wing/telegram/lab_computer.png",
	"tg_lab_refrigerator": "res://assets/sprites/medical-wing/telegram/lab_refrigerator.png",
	"tg_lab_wooden_cabinet": "res://assets/sprites/medical-wing/telegram/lab_wooden_cabinet.png",
	"tg_lab_wooden_cabinet_full": "res://assets/sprites/medical-wing/telegram/lab_wooden_cabinet_full.png",
	"tg_lab_large_table": "res://assets/sprites/medical-wing/telegram/lab_large_table.png",
	"tg_lab_medium_table": "res://assets/sprites/medical-wing/telegram/lab_medium_table.png",
	"tg_lab_automation_robot": "res://assets/sprites/medical-wing/telegram/lab_automation_robot.png",
	"tg_lab_microscope_h": "res://assets/sprites/medical-wing/telegram/lab_microscope_h.png",
	"tg_lab_microscope_v": "res://assets/sprites/medical-wing/telegram/lab_microscope_v.png",
	"tg_lab_sample_centrifuge": "res://assets/sprites/medical-wing/telegram/lab_sample_centrifuge.png",
	"tg_lab_sample_vials": "res://assets/sprites/medical-wing/telegram/lab_sample_vials.png",
	"tg_lab_vial_001": "res://assets/sprites/medical-wing/telegram/lab_vial_001.png",
	"tg_lab_vial_002": "res://assets/sprites/medical-wing/telegram/lab_vial_002.png",
	"tg_lab_vial_003": "res://assets/sprites/medical-wing/telegram/lab_vial_003.png",
	"tg_lab_vial_004": "res://assets/sprites/medical-wing/telegram/lab_vial_004.png",
	"tg_lab_books": "res://assets/sprites/medical-wing/telegram/lab_books.png",
	"tg_lab_paper_dispenser": "res://assets/sprites/medical-wing/telegram/lab_paper_dispenser.png",
	"tg_maternity_bed": "res://assets/sprites/medical-wing/telegram/maternity_bed.png",
	"tg_maternity_chair": "res://assets/sprites/medical-wing/telegram/maternity_chair.png",
	"tg_maternity_table": "res://assets/sprites/medical-wing/telegram/maternity_table.png",
	"tg_maternity_ball": "res://assets/sprites/medical-wing/telegram/maternity_ball.png",
	"tg_maternity_light": "res://assets/sprites/medical-wing/telegram/maternity_light.png",
	"tg_maternity_work_cabinet": "res://assets/sprites/medical-wing/telegram/maternity_work_cabinet.png",
	"tg_maternity_carpet": "res://assets/sprites/medical-wing/telegram/maternity_carpet.png",
	"tg_maternity_birthing_rope": "res://assets/sprites/medical-wing/telegram/maternity_birthing_rope.png",
	"tg_maternity_cottons": "res://assets/sprites/medical-wing/telegram/maternity_cottons.png",
	"tg_maternity_towel_01": "res://assets/sprites/medical-wing/telegram/maternity_towel_01.png",
	"tg_maternity_towel_02": "res://assets/sprites/medical-wing/telegram/maternity_towel_02.png",
	"tg_operation_table": "res://assets/sprites/medical-wing/telegram/operation_table.png",
	"tg_operation_light": "res://assets/sprites/medical-wing/telegram/operation_light.png",
	"tg_operation_ct_scanner": "res://assets/sprites/medical-wing/telegram/operation_ct_scanner.png",
	"tg_operation_ultrasound_machine": "res://assets/sprites/medical-wing/telegram/operation_ultrasound_machine.png",
	"tg_operation_ecg_full": "res://assets/sprites/medical-wing/telegram/operation_ecg_full.png",
	"tg_operation_ecg_screen": "res://assets/sprites/medical-wing/telegram/operation_ecg_screen.png",
	"tg_operation_console_full": "res://assets/sprites/medical-wing/telegram/operation_console_full.png",
	"tg_operation_console_table": "res://assets/sprites/medical-wing/telegram/operation_console_table.png",
	"tg_operation_console_computer": "res://assets/sprites/medical-wing/telegram/operation_console_computer.png",
	"tg_operation_accessories_table": "res://assets/sprites/medical-wing/telegram/operation_accessories_table.png",
	"tg_operation_accessories_table_full": "res://assets/sprites/medical-wing/telegram/operation_accessories_table_full.png",
	"tg_operation_scalpel_01": "res://assets/sprites/medical-wing/telegram/operation_scalpel_01.png",
	"tg_operation_scalpel_02": "res://assets/sprites/medical-wing/telegram/operation_scalpel_02.png",
	"tg_operation_radiation_sign": "res://assets/sprites/medical-wing/telegram/operation_radiation_sign.png",
	"tg_room_bed_h": "res://assets/sprites/medical-wing/telegram/room_bed_h.png",
	"tg_room_bed_v": "res://assets/sprites/medical-wing/telegram/room_bed_v.png",
	"tg_room_bed_meal": "res://assets/sprites/medical-wing/telegram/room_bed_meal.png",
	"tg_room_bedside_table": "res://assets/sprites/medical-wing/telegram/room_bedside_table.png",
	"tg_room_armchair": "res://assets/sprites/medical-wing/telegram/room_armchair.png",
	"tg_room_cabinet": "res://assets/sprites/medical-wing/telegram/room_cabinet.png",
	"tg_room_ecg_cart": "res://assets/sprites/medical-wing/telegram/room_ecg_cart.png",
	"tg_room_ecg_screen": "res://assets/sprites/medical-wing/telegram/room_ecg_screen.png",
	"tg_room_iv_stand_b": "res://assets/sprites/medical-wing/telegram/room_iv_stand_b.png",
	"tg_room_iv_stand_g": "res://assets/sprites/medical-wing/telegram/room_iv_stand_g.png",
	"tg_room_iv_stand_w": "res://assets/sprites/medical-wing/telegram/room_iv_stand_w.png",
	"tg_room_biohazard_bin": "res://assets/sprites/medical-wing/telegram/room_biohazard_bin.png",
	"tg_room_biohazard_bin_y": "res://assets/sprites/medical-wing/telegram/room_biohazard_bin_y.png",
	"tg_room_trash_bin": "res://assets/sprites/medical-wing/telegram/room_trash_bin.png",
	"tg_room_table_meal_v": "res://assets/sprites/medical-wing/telegram/room_table_meal_v.png",
	"tg_room_pharmacy_shelf": "res://assets/sprites/medical-wing/telegram/room_pharmacy_shelf.png",
	"tg_room_anatomy_poster": "res://assets/sprites/medical-wing/telegram/room_anatomy_poster.png",
	"tg_room_hand_sanitizer": "res://assets/sprites/medical-wing/telegram/room_hand_sanitizer.png",
	"tg_room_flower": "res://assets/sprites/medical-wing/telegram/room_flower.png",
	"tg_room_meal_tray": "res://assets/sprites/medical-wing/telegram/room_meal_tray.png",
	"tg_room_soup": "res://assets/sprites/medical-wing/telegram/room_soup.png",
	"tg_room_pear": "res://assets/sprites/medical-wing/telegram/room_pear.png",
	"tg_room_table_meal_h": "res://assets/sprites/medical-wing/telegram/room_table_meal_h.png",
	"tg_room_table_meal_bed": "res://assets/sprites/medical-wing/telegram/room_table_meal_bed.png",
	"tg_room_pills_01": "res://assets/sprites/medical-wing/telegram/room_pills_01.png",
	"tg_room_pills_02": "res://assets/sprites/medical-wing/telegram/room_pills_02.png",
	# Telegram small photos, keyed to transparent PNGs (design §5.2).
	"ph_287167626_astronaut": "res://assets/sprites/medical-wing/telegram-photos/287167626_astronaut.png",
	"ph_287167627_wheelchair_dark": "res://assets/sprites/medical-wing/telegram-photos/287167627_wheelchair_dark.png",
	"ph_287167628_pill_bottle_redlabel": "res://assets/sprites/medical-wing/telegram-photos/287167628_pill_bottle_redlabel.png",
	"ph_287167629_medicine_jar_heart": "res://assets/sprites/medical-wing/telegram-photos/287167629_medicine_jar_heart.png",
	"ph_287167630_blister_green": "res://assets/sprites/medical-wing/telegram-photos/287167630_blister_green.png",
	"ph_287167631_medicine_jar_blue": "res://assets/sprites/medical-wing/telegram-photos/287167631_medicine_jar_blue.png",
	"ph_287167632_syringe_pink": "res://assets/sprites/medical-wing/telegram-photos/287167632_syringe_pink.png",
	"ph_287167633_bandage_plaster": "res://assets/sprites/medical-wing/telegram-photos/287167633_bandage_plaster.png",
	"ph_287167634_bandage_roll": "res://assets/sprites/medical-wing/telegram-photos/287167634_bandage_roll.png",
	"ph_287167635_firstaid_white_green": "res://assets/sprites/medical-wing/telegram-photos/287167635_firstaid_white_green.png",
	"ph_287167636_firstaid_white_blue": "res://assets/sprites/medical-wing/telegram-photos/287167636_firstaid_white_blue.png",
	"ph_287167637_firstaid_box_cardboard": "res://assets/sprites/medical-wing/telegram-photos/287167637_firstaid_box_cardboard.png",
	"ph_287167638_iv_bag_orange": "res://assets/sprites/medical-wing/telegram-photos/287167638_iv_bag_orange.png",
	"ph_287167639_sink_basin": "res://assets/sprites/medical-wing/telegram-photos/287167639_sink_basin.png",
	"ph_287167640_wheelchair_green": "res://assets/sprites/medical-wing/telegram-photos/287167640_wheelchair_green.png",
	"ph_287167641_firstaid_white_red": "res://assets/sprites/medical-wing/telegram-photos/287167641_firstaid_white_red.png",
	"ph_287167642_blood_bag": "res://assets/sprites/medical-wing/telegram-photos/287167642_blood_bag.png",
	"ph_287167643_oxygen_tank": "res://assets/sprites/medical-wing/telegram-photos/287167643_oxygen_tank.png",
	"ph_287167644_vial_green_small": "res://assets/sprites/medical-wing/telegram-photos/287167644_vial_green_small.png",
	"ph_287167645_syringe_blue": "res://assets/sprites/medical-wing/telegram-photos/287167645_syringe_blue.png",
	"ph_287167646_box_red_white": "res://assets/sprites/medical-wing/telegram-photos/287167646_box_red_white.png",
	"ph_287167647_medicine_jar_heart_white": "res://assets/sprites/medical-wing/telegram-photos/287167647_medicine_jar_heart_white.png",
	"ph_287167648_wheelchair_dark2": "res://assets/sprites/medical-wing/telegram-photos/287167648_wheelchair_dark2.png",
	"ph_287167649_syringe_teal": "res://assets/sprites/medical-wing/telegram-photos/287167649_syringe_teal.png",
	"ph_287167650_hospital_bed_iso": "res://assets/sprites/medical-wing/telegram-photos/287167650_hospital_bed_iso.png",
	"ph_287167651_pill_bottle_orangecap": "res://assets/sprites/medical-wing/telegram-photos/287167651_pill_bottle_orangecap.png",
	"ph_287167652_medicine_bottle_orangecap": "res://assets/sprites/medical-wing/telegram-photos/287167652_medicine_bottle_orangecap.png",
	"ph_287167653_monitor_desktop": "res://assets/sprites/medical-wing/telegram-photos/287167653_monitor_desktop.png",
	"ph_287167654_medicine_bottle_whitelabel": "res://assets/sprites/medical-wing/telegram-photos/287167654_medicine_bottle_whitelabel.png",
	"ph_287167655_medicine_carton": "res://assets/sprites/medical-wing/telegram-photos/287167655_medicine_carton.png",
	"ph_287167656_blister_pink": "res://assets/sprites/medical-wing/telegram-photos/287167656_blister_pink.png",
	"ph_287167657_syringe_redwhite": "res://assets/sprites/medical-wing/telegram-photos/287167657_syringe_redwhite.png",
	"ph_287167658_syringe_redblue": "res://assets/sprites/medical-wing/telegram-photos/287167658_syringe_redblue.png",
	"ph_287167659_firstaid_chest_red": "res://assets/sprites/medical-wing/telegram-photos/287167659_firstaid_chest_red.png",
	"ph_287167660_canister_orange": "res://assets/sprites/medical-wing/telegram-photos/287167660_canister_orange.png",
	"ph_287167661_pill_bottle_orangeband": "res://assets/sprites/medical-wing/telegram-photos/287167661_pill_bottle_orangeband.png",
	"ph_287167662_firstaid_red": "res://assets/sprites/medical-wing/telegram-photos/287167662_firstaid_red.png",
	"ph_287167663_firstaid_white_redside": "res://assets/sprites/medical-wing/telegram-photos/287167663_firstaid_white_redside.png",
	"ph_287167664_microscope_side": "res://assets/sprites/medical-wing/telegram-photos/287167664_microscope_side.png",
	"ph_287167665_test_tube_red": "res://assets/sprites/medical-wing/telegram-photos/287167665_test_tube_red.png",
	"ph_287167666_flask_green": "res://assets/sprites/medical-wing/telegram-photos/287167666_flask_green.png",
	"ph_287167667_wheelchair_red": "res://assets/sprites/medical-wing/telegram-photos/287167667_wheelchair_red.png",
	"ph_287167668_robot_white": "res://assets/sprites/medical-wing/telegram-photos/287167668_robot_white.png",
	"ph_287167669_thermometer": "res://assets/sprites/medical-wing/telegram-photos/287167669_thermometer.png",
	"ph_287167670_iv_bag_red": "res://assets/sprites/medical-wing/telegram-photos/287167670_iv_bag_red.png",
	"ph_287167671_firstaid_white_circle": "res://assets/sprites/medical-wing/telegram-photos/287167671_firstaid_white_circle.png",
}

## One source of truth for sprite, body and navigation geometry.
## Entries: [texture key, local centre, collision size, node name].
const MED_SOLID_LAYOUT := [
	["bed_standard", Vector2(48, 56), Vector2(32, 16), "MedBedStandard"],
	["bed_empty", Vector2(96, 56), Vector2(32, 16), "MedBedEmpty"],
	["bed_standard", Vector2(144, 56), Vector2(32, 16), "MedBed3"],
	["bed_disorganized", Vector2(144, 104), Vector2(32, 16), "MedBedDisorganized"],
	["bed_standard", Vector2(48, 104), Vector2(32, 16), "MedBed4"],
	["bed_empty", Vector2(96, 104), Vector2(32, 16), "MedBed5"],
	["bedside_table", Vector2(72, 104), Vector2(16, 16), "MedBedsideB1"],
	["bedside_table", Vector2(120, 104), Vector2(16, 16), "MedBedsideB2"],
	["bedside_table", Vector2(72, 56), Vector2(16, 16), "MedBedside1"],
	["bedside_table", Vector2(120, 56), Vector2(16, 16), "MedBedside2"],
	["bedside_table", Vector2(168, 56), Vector2(16, 16), "MedBedside3"],
	["bedside_table", Vector2(216, 56), Vector2(16, 16), "MedBedside4"],
	["monitor_vitals", Vector2(40, 40), Vector2(16, 16), "MedMonitorWard1"],
	["monitor_heart", Vector2(136, 40), Vector2(16, 16), "MedMonitorWard2"],
	["exam_bed", Vector2(352, 56), Vector2(32, 16), "MedExamBed"],
	["exam_lamp", Vector2(392, 56), Vector2(16, 16), "MedExamLamp"],
	["monitor_heart", Vector2(328, 40), Vector2(16, 16), "MedMonitorExam"],
	["sink_ceramic", Vector2(408, 40), Vector2(16, 16), "MedSink"],
	["infusion_pump", Vector2(424, 56), Vector2(16, 16), "MedInfusionPump"],
	["stretcher", Vector2(48, 216), Vector2(32, 16), "MedStretcher"],
	["defibrillator", Vector2(72, 216), Vector2(16, 16), "MedDefibrillator"],
	["cart_emergency", Vector2(88, 216), Vector2(16, 16), "MedCartEmergency"],
	["wheelchair", Vector2(24, 280), Vector2(16, 16), "MedWheelchair"],
	["oxygen_cylinder", Vector2(24, 200), Vector2(16, 16), "MedOxygenCyl"],
	["cabinet_medicine", Vector2(360, 344), Vector2(16, 16), "MedCabinetMedicine"],
	["shelf_medicine", Vector2(392, 344), Vector2(16, 16), "MedShelfMedicine"],
	["cabinet_storage", Vector2(424, 344), Vector2(16, 16), "MedCabinetStorage"],
	["fridge_medical", Vector2(456, 344), Vector2(16, 16), "MedFridge"],
	["cabinet_closed", Vector2(488, 344), Vector2(16, 16), "MedCabinetClosed"],
	["cabinet_open", Vector2(520, 344), Vector2(16, 16), "MedCabinetOpen"],
	["desk_doctor", Vector2(512, 296), Vector2(32, 16), "MedDeskDoctor"],
	["chair_office", Vector2(536, 296), Vector2(16, 16), "MedChairOffice"],
	["side_table", Vector2(568, 280), Vector2(16, 16), "MedSideTableOffice"],
	["supply_boxes", Vector2(40, 328), Vector2(16, 16), "MedSupplyBoxes"],
	["oxygen_unit", Vector2(56, 328), Vector2(16, 16), "MedOxygenUnit"],
	["waste_bin", Vector2(88, 328), Vector2(16, 16), "MedWasteBin"],
	["cabinet_worn", Vector2(72, 344), Vector2(16, 16), "MedCabinetWorn"],
	["side_table", Vector2(392, 152), Vector2(16, 16), "MedSideTable"],
	["chair_rolling", Vector2(408, 152), Vector2(16, 16), "MedChairRolling"],
	["trolley", Vector2(328, 168), Vector2(16, 16), "MedTrolley"],
	# Clinic redesign (2026-11-24): Telegram hospital pack + photos.
	["tg_lab_sink", Vector2(464, 40), Vector2(32, 16), "MedLabSink"],
	["tg_lab_computer", Vector2(488, 40), Vector2(16, 16), "MedLabComputer"],
	["tg_lab_refrigerator", Vector2(520, 48), Vector2(16, 32), "MedLabFridge"],
	["tg_lab_wooden_cabinet", Vector2(552, 48), Vector2(16, 32), "MedLabCabinet"],
	["tg_lab_wooden_cabinet_full", Vector2(584, 48), Vector2(16, 32), "MedLabCabinetFull"],
	["tg_lab_large_table", Vector2(528, 112), Vector2(64, 32), "MedLabBench"],
	["tg_lab_medium_table", Vector2(576, 104), Vector2(32, 16), "MedLabTableMed"],
	["tg_lab_automation_robot", Vector2(496, 72), Vector2(32, 16), "MedLabRobot"],
	["tg_maternity_bed", Vector2(224, 224), Vector2(32, 32), "MedMatBed"],
	["tg_maternity_chair", Vector2(264, 216), Vector2(16, 16), "MedMatChair"],
	["tg_maternity_table", Vector2(296, 216), Vector2(16, 16), "MedMatTable"],
	["tg_maternity_ball", Vector2(232, 184), Vector2(16, 16), "MedMatBall"],
	["tg_maternity_light", Vector2(296, 184), Vector2(16, 16), "MedMatLamp"],
	["tg_maternity_work_cabinet", Vector2(312, 208), Vector2(16, 32), "MedMatCabinet"],
	["tg_operation_table", Vector2(496, 168), Vector2(32, 48), "MedOpTable"],
	["tg_operation_ct_scanner", Vector2(584, 176), Vector2(48, 64), "MedCTScanner"],
	["tg_operation_ultrasound_machine", Vector2(520, 176), Vector2(16, 32), "MedUltrasound"],
	["tg_operation_ecg_full", Vector2(456, 144), Vector2(16, 32), "MedOpECG"],
	["tg_operation_console_full", Vector2(496, 136), Vector2(32, 16), "MedOpConsoleFull"],
	["tg_operation_console_table", Vector2(560, 136), Vector2(32, 16), "MedOpConsoleTable"],
	# Review pass 1 (2026-11-24): design §3.3 put this tray at (464,192);
	# the tile-centre nudge moved it to (456,184), exactly onto the
	# pre-existing MedChairFallen decor — tray + fallen chair + scalpel
	# stacked on one point. Moved to (472,184): tile-centre aligned
	# (the first try, (472,192), put the centre on a tile edge in y and
	# broke test_rooms' standalone/assembled grid agreement by 3 cells),
	# clear of the chair (edge touch at x=464 only), still beside
	# MedOpTable.
	["tg_operation_accessories_table", Vector2(472, 184), Vector2(16, 16), "MedOpTrayEmpty"],
	["tg_operation_accessories_table_full", Vector2(520, 200), Vector2(16, 16), "MedOpTrayFull"],
	# Review pass 1 (2026-11-24): design §3.4 put this bed at (224,56),
	# exactly on top of the pre-existing MedBedside4 (216,56) — the table
	# was fully hidden under the bed sprite (identical 32x16/16x16 rects).
	# Moved +16x to (240,56): bedside table visible again, bed still in
	# the observation bay (cols 14-15), abutting MedObsTable (264,56).
	["tg_room_bed_h", Vector2(240, 56), Vector2(32, 16), "MedObsBedH"],
	["tg_room_bed_v", Vector2(296, 48), Vector2(16, 32), "MedObsBedV"],
	["tg_room_bed_meal", Vector2(440, 48), Vector2(16, 32), "MedExamCouch2"],
	["tg_room_bedside_table", Vector2(264, 56), Vector2(16, 16), "MedObsTable"],
	["tg_room_armchair", Vector2(184, 56), Vector2(16, 16), "MedArmchairWard"],
	["tg_room_cabinet", Vector2(232, 40), Vector2(16, 16), "MedCabinetWard"],
	["tg_room_ecg_cart", Vector2(184, 104), Vector2(16, 16), "MedECGCart"],
	["tg_room_iv_stand_b", Vector2(24, 56), Vector2(16, 16), "MedIVB"],
	["tg_room_iv_stand_g", Vector2(24, 104), Vector2(16, 16), "MedIVG"],
	["tg_room_iv_stand_w", Vector2(168, 104), Vector2(16, 16), "MedIVW"],
	["tg_room_biohazard_bin", Vector2(200, 56), Vector2(16, 16), "MedBiohazard"],
	["tg_room_biohazard_bin_y", Vector2(216, 104), Vector2(16, 16), "MedBiohazardY"],
	["tg_room_trash_bin", Vector2(216, 88), Vector2(16, 16), "MedTrashWard"],
	["tg_room_table_meal_v", Vector2(248, 88), Vector2(16, 16), "MedMealTableV"],
	["tg_room_pharmacy_shelf", Vector2(552, 344), Vector2(16, 16), "MedPharmacyShelf"],
	["ph_287167643_oxygen_tank", Vector2(24, 184), Vector2(16, 16), "MedOxygenTank2"],
	["ph_287167668_robot_white", Vector2(456, 104), Vector2(16, 16), "MedPhotoRobot668"],
	["ph_287167639_sink_basin", Vector2(56, 184), Vector2(16, 16), "MedPhotoSink639"],
	["ph_287167650_hospital_bed_iso", Vector2(104, 328), Vector2(16, 16), "MedPhotoBed650"],
	# DEVIATION from design §4.5 (see build log): the design puts this bay
	# at row 14 (y232, x24/56/88), but the three wheelchairs' nav-grid
	# inflation (+1 cell) seals row 15 across cols 0-6 — the only detour
	# around the pre-existing MedWheelchair (24,280), whose own inflation
	# blocks row 16 at cols 0-2. test_enemy_path_through_doorway then has
	# no route through the west door (68-waypoint southern detour instead).
	# Bay moved one zone north to row 12 (y200), cols 3/5/7 (x56/88/120):
	# still the emergency wheelchair bay north of the entry corridor; col 1
	# is taken by the existing MedOxygenCyl (24,200). Row 15 stays open.
	["ph_287167627_wheelchair_dark", Vector2(56, 200), Vector2(16, 16), "MedWheelchair2"],
	["ph_287167640_wheelchair_green", Vector2(88, 200), Vector2(16, 16), "MedWheelchair3"],
	["ph_287167648_wheelchair_dark2", Vector2(120, 200), Vector2(16, 16), "MedWheelchair4"],
	# DEVIATION from design §4.5 (see build log): the design puts this at
	# (120, 280), but its nav-grid inflation (+1 cell) covers local cell
	# (7, 16) — the exact target of test_enemy_path_through_doorway, whose
	# A* path to station (760, 256) then comes back empty. Moved 2 tiles
	# east, same row: still the waiting-area wheelchair by the entrance.
	["ph_287167667_wheelchair_red", Vector2(152, 280), Vector2(16, 16), "MedWheelchairWait"],
	["ph_287167626_astronaut", Vector2(104, 344), Vector2(16, 16), "MedPhotoSuit626"],
]

## Non-solid decoration: [texture key, local centre, node name].
const MED_DECOR_LAYOUT := [
	["door_open", Vector2(-8, 248), "MedDoorWestA"],
	["door_open", Vector2(-8, 264), "MedDoorWestB"],
	["door_open", Vector2(296, 360), "MedDoorSouthA"],
	["door_open", Vector2(312, 360), "MedDoorSouthB"],
	["clock_wall", Vector2(-8, 40), "MedClock"],
	["wall_access_panel", Vector2(-8, 100), "MedAccessPanel"],
	["window_small", Vector2(-8, 160), "MedWindowSmall"],
	["grille_vent", Vector2(-8, 200), "MedGrilleVent"],
	["panel_wall_small", Vector2(-8, 300), "MedWallPanel"],
	["sign_warning", Vector2(-8, 320), "MedWarningSign"],
	["window_observation", Vector2(360, 360), "MedWindowObservation"],
	["wall_cabinet_section", Vector2(460, 360), "MedWallCabinet"],
	["wall_corner_inner", Vector2(-8, 360), "MedCornerSW"],
	["wall_corner_outer", Vector2(632, 360), "MedCornerSE"],
	["fusebox_closed", Vector2(632, 60), "MedFusebox"],
	["indicator_emergency", Vector2(632, 200), "MedIndicator"],
	["light_ceiling", Vector2(160, 40), "MedLightCeilingA"],
	["light_ceiling", Vector2(460, 320), "MedLightCeilingB"],
	["light_green", Vector2(120, 64), "MedLightGreen"],
	["light_blue", Vector2(220, 40), "MedLightBlue"],
	["light_red", Vector2(600, 340), "MedLightRed"],
	["light_flicker", Vector2(460, 200), "MedLightFlicker"],
	["light_damaged", Vector2(560, 280), "MedLightDamaged"],
	["documents", Vector2(160, 150), "MedDocuments"],
	["bottles_medicine", Vector2(376, 328), "MedBottles"],
	["packages_medicine", Vector2(440, 328), "MedPackages"],
	["gloves", Vector2(180, 300), "MedGloves"],
	["bandages", Vector2(220, 300), "MedBandages"],
	["syringes", Vector2(260, 300), "MedSyringes"],
	["tray_instruments", Vector2(376, 72), "MedTray"],
	["paper_scattered", Vector2(360, 136), "MedPapers"],
	["chair_fallen", Vector2(456, 184), "MedChairFallen"],
	["dust", Vector2(60, 300), "MedDust"],
	["steam", Vector2(540, 200), "MedSteam"],
	["spark", Vector2(600, 100), "MedSpark"],
	["flashlight", Vector2(504, 292), "MedFlashlight"],
	["documents", Vector2(516, 292), "MedDocumentsDesk"],
	["note_doctor", Vector2(520, 300), "MedNoteDoctor"],
	# Clinic redesign (2026-11-24): Telegram hospital pack + photos.
	["tg_lab_microscope_h", Vector2(504, 112), "MedLabMicroH"],
	["tg_lab_microscope_v", Vector2(552, 112), "MedLabMicroV"],
	["tg_lab_sample_centrifuge", Vector2(520, 112), "MedLabCentrifuge"],
	["tg_lab_sample_vials", Vector2(536, 112), "MedLabVialRack"],
	["tg_lab_vial_001", Vector2(568, 104), "MedLabVial1"],
	["tg_lab_vial_002", Vector2(576, 104), "MedLabVial2"],
	["tg_lab_vial_003", Vector2(584, 104), "MedLabVial3"],
	["tg_lab_vial_004", Vector2(592, 104), "MedLabVial4"],
	["tg_lab_books", Vector2(552, 40), "MedLabBooks"],
	["tg_lab_paper_dispenser", Vector2(616, 24), "MedLabDispenser"],
	["tg_maternity_carpet", Vector2(264, 232), "MedMatCarpet"],
	["tg_maternity_birthing_rope", Vector2(216, 200), "MedMatRope"],
	["tg_maternity_cottons", Vector2(296, 216), "MedMatCottons"],
	["tg_maternity_towel_01", Vector2(224, 224), "MedMatTowel1"],
	["tg_maternity_towel_02", Vector2(264, 216), "MedMatTowel2"],
	["tg_operation_light", Vector2(496, 152), "MedOpLight"],
	["tg_operation_ecg_screen", Vector2(496, 124), "MedOpECGScreen"],
	["tg_operation_console_computer", Vector2(560, 136), "MedOpConsolePC"],
	["tg_operation_scalpel_01", Vector2(472, 184), "MedOpScalpel1"],
	["tg_operation_scalpel_02", Vector2(520, 200), "MedOpScalpel2"],
	["tg_operation_radiation_sign", Vector2(632, 176), "MedRadiationSign"],
	["tg_room_ecg_screen", Vector2(184, 40), "MedECGScreenWard"],
	["tg_room_anatomy_poster", Vector2(24, 24), "MedPosterAnatomy"],
	["tg_room_hand_sanitizer", Vector2(216, 24), "MedSanitizer"],
	["tg_room_flower", Vector2(72, 56), "MedFlower"],
	["tg_room_meal_tray", Vector2(120, 56), "MedMealTray"],
	["tg_room_soup", Vector2(120, 104), "MedSoup"],
	["tg_room_pear", Vector2(72, 104), "MedPear"],
	["tg_room_table_meal_h", Vector2(96, 56), "MedMealTableH"],
	["tg_room_table_meal_bed", Vector2(96, 104), "MedMealTableBed"],
	["tg_room_pills_01", Vector2(392, 336), "MedPills1"],
	["tg_room_pills_02", Vector2(520, 336), "MedPills2"],
	["ph_287167628_pill_bottle_redlabel", Vector2(356, 340), "MedPhotoPill628"],
	["ph_287167651_pill_bottle_orangecap", Vector2(388, 340), "MedPhotoPill651"],
	["ph_287167652_medicine_bottle_orangecap", Vector2(420, 340), "MedPhotoPill652"],
	["ph_287167654_medicine_bottle_whitelabel", Vector2(452, 340), "MedPhotoPill654"],
	["ph_287167661_pill_bottle_orangeband", Vector2(484, 340), "MedPhotoPill661"],
	["ph_287167629_medicine_jar_heart", Vector2(516, 340), "MedPhotoJar629"],
	["ph_287167631_medicine_jar_blue", Vector2(548, 340), "MedPhotoJar631"],
	["ph_287167647_medicine_jar_heart_white", Vector2(364, 340), "MedPhotoJar647"],
	["ph_287167630_blister_green", Vector2(396, 340), "MedPhotoBlister630"],
	["ph_287167656_blister_pink", Vector2(524, 340), "MedPhotoBlister656"],
	["ph_287167655_medicine_carton", Vector2(428, 340), "MedPhotoCarton655"],
	["ph_287167646_box_red_white", Vector2(460, 340), "MedPhotoBox646"],
	["ph_287167660_canister_orange", Vector2(556, 340), "MedPhotoCanister660"],
	["ph_287167671_firstaid_white_circle", Vector2(400, 336), "MedKitPharm"],
	["ph_287167637_firstaid_box_cardboard", Vector2(360, 336), "MedKitBox637"],
	["ph_287167657_syringe_redwhite", Vector2(394, 340), "MedSyringe657"],
	# Review pass 1 (2026-11-24): design §4.2 put this kit at (-8,200),
	# exactly on top of the pre-existing MedGrilleVent — the vent was
	# fully hidden behind the kit (kit art fills 14x14 of the 16x16).
	# Moved one tile north to (-8,184), still the west-wall kit column.
	["ph_287167635_firstaid_white_green", Vector2(-8, 184), "MedKitWall1"],
	["ph_287167641_firstaid_white_red", Vector2(-8, 216), "MedKitWall2"],
	["ph_287167662_firstaid_red", Vector2(-8, 232), "MedKitWall3"],
	["ph_287167636_firstaid_white_blue", Vector2(88, 216), "MedKitCart"],
	["ph_287167663_firstaid_white_redside", Vector2(72, 216), "MedKitDefib"],
	["ph_287167659_firstaid_chest_red", Vector2(48, 216), "MedKitChest659"],
	["ph_287167642_blood_bag", Vector2(24, 104), "MedBloodBag642"],
	["ph_287167670_iv_bag_red", Vector2(168, 104), "MedBloodBag670"],
	["ph_287167632_syringe_pink", Vector2(392, 56), "MedSyringe632"],
	["ph_287167645_syringe_blue", Vector2(424, 56), "MedSyringe645"],
	["ph_287167649_syringe_teal", Vector2(356, 52), "MedSyringe649"],
	["ph_287167633_bandage_plaster", Vector2(348, 60), "MedBandage633"],
	["ph_287167634_bandage_roll", Vector2(392, 152), "MedBandage634"],
	["ph_287167669_thermometer", Vector2(360, 60), "MedThermo669"],
	["ph_287167658_syringe_redblue", Vector2(328, 168), "MedSyringe658"],
	["ph_287167664_microscope_side", Vector2(588, 100), "MedPhotoMicro664"],
	["ph_287167665_test_tube_red", Vector2(512, 108), "MedPhotoTube665"],
	["ph_287167666_flask_green", Vector2(544, 108), "MedPhotoFlask666"],
	["ph_287167644_vial_green_small", Vector2(572, 100), "MedPhotoVial644"],
	["ph_287167638_iv_bag_orange", Vector2(24, 56), "MedIVBag638"],
	["ph_287167653_monitor_desktop", Vector2(568, 280), "MedPhotoMonitor653"],
]

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
	area_hint = "بخش پزشکی — یک ربات اسکنر اینجا نگهبانی می‌دهد؛ در دیدش نمان"
	spawn_point = Vector2(64, 256)
	tint_color = Color(0.5, 0.9, 0.6, 0.07)
	_build_floor_if_standalone()
	_build_wall_rects(wall_rects())
	_build_tint()
	_build_zone()
	_add_area_console(Vector2(120, 80), "گزارش پزشکی: بعد از تمرین شیوع بیماری، این بخش بسته شد. آذوقه کم است.", "monitor_vitals")
	_add_prop(preload("res://assets/sprites/props/crate.png"), Vector2(40, 296))
	_add_decor(preload("res://assets/sprites/props/control_panel.png"), Vector2(60, 340))
	_add_decor(preload("res://assets/sprites/props/riveted_panel.png"), Vector2(600, 80))
	_build_medical_props()
	_build_enhancements()


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
## medical furniture plus the crate, whose centre is (40, 296)).
func prop_solid_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for entry in MED_SOLID_LAYOUT:
		var center: Vector2 = entry[1]
		var size: Vector2 = entry[2]
		rects.append(Rect2(center - size * 0.5, size))
	# The original crate is a shared prop, not part of the medical atlas.
	rects.append(Rect2(32, 288, 16, 16))
	return rects


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


## Medical Wing furnishing — clinic redesign (2026-11-23): zones are
## ward (6 beds in two rows of three, north), exam (north-east), emergency (west, by the
## entry), pharmacy (south wall), doctor's office (south-east) and
## storage (south-west); doors are open double doors on both exits.
## Solid props get a physics body + a prop_solid_rects() entry (nav
## grid); wall decor and small floor clutter are plain sprites.
## Nothing solid is placed in either doorway approach, in the entry
## corridor (y 240-272, x 0-160) or on the scanner's line of sight
## (x=260, y 120-200). Beds are 2x1 tiles with 1-tile gaps; main
## circulation stays 2 tiles wide.
func _build_medical_props() -> void:
	for entry in MED_SOLID_LAYOUT:
		_add_prop(_med_texture(entry[0]), entry[1], entry[2], entry[3])
	for entry in MED_DECOR_LAYOUT:
		_add_med_decor(entry[0], entry[1], entry[2])


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
		# floor/ceil also behave correctly for negative or non-aligned rects.
		var min_cell := Vector2i(floori(r.position.x / TILE_SIZE) - 1, floori(r.position.y / TILE_SIZE) - 1)
		var max_cell := Vector2i(ceili(r.end.x / TILE_SIZE) + 1, ceili(r.end.y / TILE_SIZE) + 1)
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
	if not MED_PROP_PATHS.has(key):
		push_warning("Medical wing: unknown texture key '%s'." % key)
		return null
	if not _med_tex.has(key):
		var path: String = MED_PROP_PATHS[key]
		if ResourceLoader.exists(path):
			_med_tex[key] = load(path)
		else:
			push_warning("Medical wing: missing texture '%s'; using a visible placeholder." % path)
			var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
			image.fill(Color(0.75, 0.22, 0.48, 1.0))
			_med_tex[key] = ImageTexture.create_from_image(image)
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
	if cell.x < 0 or cell.x >= ROOM_COLS or cell.y < 0 or cell.y >= ROOM_ROWS:
		# Deterministic fallback instead of reading outside the roll buffer.
		return float(posmod(hash(cell), 1000000)) / 1000000.0
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
	# Medical Wing floor: the pack's 12-tile atlas is loaded, but
	# only its plain tile (index 4) is used — the whole wing is one
	# uniform block. Cells outside the wing keep the old two tiles.
	var med_source := TileSetAtlasSource.new()
	med_source.texture = load(MED_FLOOR_TEXTURE_PATH)
	med_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for i in 12:
		med_source.create_tile(Vector2i(i, 0))
	tileset.add_source(med_source)
	return tileset



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
				layer.set_cell(Vector2i(x, y), 1, MED_FLOOR_TILE)
			else:
				var coord := Vector2i(1, 0) if roll < FLOOR_VARIANT_CHANCE else Vector2i.ZERO
				layer.set_cell(Vector2i(x, y), 0, coord)


# Optional enhancements are self-contained children. This also keeps their
# behaviour alive if the level assembler reparents room children into a level.
class MedicalAtmosphere extends Node2D:
	var lighting_enabled: bool = true
	var audio_enabled: bool = true
	var audio_volume_db: float = -34.0
	var hum: AudioStreamWAV
	var _lamps: Array[PointLight2D] = []
	var _elapsed: float = 0.0

	func _ready() -> void:
		name = "MedicalAtmosphere"
		if lighting_enabled:
			var texture := _make_light_texture()
			_add_light(texture, Vector2(160, 88), Color(0.66, 1.0, 0.84), 0.22, 1.8)
			_add_light(texture, Vector2(460, 200), Color(0.52, 0.82, 1.0), 0.15, 1.5)
			_add_light(texture, Vector2(594, 320), Color(1.0, 0.30, 0.28), 0.12, 1.2)
			# Clinic redesign (§5.4): lab-bench cyan info light + warm-white
			# operating-table light. Both static (the _process pulse below
			# only touches _lamps[0..2]); texture_scale 0.75 on the 128 px
			# gradient gives the design's 48 px radius.
			_add_light(texture, Vector2(528, 112), Color(0.24, 0.78, 0.88), 0.15, 0.75)
			_add_light(texture, Vector2(496, 176), Color(0.91, 0.93, 0.97), 0.12, 0.75)
		if audio_enabled and hum != null:
			var player := AudioStreamPlayer2D.new()
			player.name = "MedicalVentilationHum"
			player.position = Vector2(320, 184)
			player.max_distance = 800.0
			player.volume_db = audio_volume_db
			player.stream = hum
			add_child(player)
			player.play()

	func _make_light_texture() -> GradientTexture2D:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 0.68))
		gradient.set_color(1, Color(1, 1, 1, 0))
		var texture := GradientTexture2D.new()
		texture.width = 128
		texture.height = 128
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(1.0, 0.5)
		texture.gradient = gradient
		return texture

	func _add_light(texture: Texture2D, pos: Vector2, color: Color, energy: float, scale_factor: float) -> void:
		var light := PointLight2D.new()
		light.texture = texture
		light.position = pos
		light.color = color
		light.energy = energy
		light.texture_scale = scale_factor
		add_child(light)
		_lamps.append(light)

	func _process(delta: float) -> void:
		if not lighting_enabled:
			return
		_elapsed += delta
		# A slow pulse and a brief, deterministic flicker; no gameplay state
		# or global random number generator is changed by these effects.
		_lamps[0].energy = 0.21 + 0.015 * sin(_elapsed * 1.4)
		var flicker := 0.35 if fposmod(_elapsed, 7.3) < 0.09 else 1.0
		_lamps[1].energy = (0.14 + 0.015 * sin(_elapsed * 2.2)) * flicker
		_lamps[2].energy = 0.09 + 0.035 * (0.5 + 0.5 * sin(_elapsed * 2.5))


class MedicalMarker extends Node2D:
	var caption: String = ""
	var marker_color: Color = Color(0.47, 1.0, 0.77)
	var _elapsed: float = 0.0

	func _ready() -> void:
		z_index = 4
		var label := Label.new()
		label.text = caption
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(-65, -37)
		label.size = Vector2(130, 22)
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", Color(0.9, 1.0, 0.94, 0.95))
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		add_child(label)

	func _process(delta: float) -> void:
		_elapsed += delta
		queue_redraw()

	func _draw() -> void:
		var radius := 10.0 + 1.2 * sin(_elapsed * 3.0)
		var halo := marker_color
		halo.a = 0.16
		draw_circle(Vector2.ZERO, radius + 4.0, halo)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, marker_color, 1.25, true)
		draw_line(Vector2(-4, 0), Vector2(4, 0), marker_color, 1.5, true)
		draw_line(Vector2(0, -4), Vector2(0, 4), marker_color, 1.5, true)


class MedicalInvestigation extends Node2D:
	signal progress_changed(found: int, total: int)
	signal objective_completed

	var player_group: StringName = &"player"
	var detection_mask: int = 1
	var feedback_sound: AudioStreamWAV
	var feedback_volume_db: float = -28.0
	var _found: Dictionary = {"record": false, "supplies": false}
	var _complete: bool = false
	var _return_marker: MedicalMarker
	var _hud: CanvasLayer
	var _label: Label
	var _hide_timer: Timer
	var _feedback: AudioStreamPlayer

	func _ready() -> void:
		name = "MedicalWingInvestigation"
		add_to_group("medical_wing_gameplay")
		_build_hud()
		if feedback_sound != null:
			_feedback = AudioStreamPlayer.new()
			_feedback.name = "MedicalFeedback"
			_feedback.stream = feedback_sound
			_feedback.volume_db = feedback_volume_db
			add_child(_feedback)
		_add_pickup("record", Vector2(520, 320), "یادداشت پزشک")
		_add_pickup("supplies", Vector2(392, 304), "بستهٔ پزشکی")
		_add_return_point(Vector2(120, 96))
		_add_room_trigger()

	func _is_player(body: Node2D) -> bool:
		# No dependency on a particular player script or an input action.
		# Rename the group in the Inspector if the project uses another one.
		if not body is CharacterBody2D:
			return false
		return body.is_in_group(player_group) or body.name.to_lower().begins_with("player")

	func _make_trigger(pos: Vector2, radius: float, trigger_name: String) -> Area2D:
		var area := Area2D.new()
		area.name = trigger_name
		area.position = pos
		area.collision_layer = 0
		area.collision_mask = detection_mask
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = radius
		shape.shape = circle
		area.add_child(shape)
		add_child(area)
		return area

	func _add_pickup(id: String, pos: Vector2, caption: String) -> void:
		var area := _make_trigger(pos, 19.0, "Investigation_" + id)
		var marker := MedicalMarker.new()
		marker.caption = caption
		area.add_child(marker)
		area.body_entered.connect(_on_pickup_entered.bind(id, area))

	func _add_return_point(pos: Vector2) -> void:
		var area := _make_trigger(pos, 22.0, "Investigation_Return")
		_return_marker = MedicalMarker.new()
		_return_marker.caption = "بازگشت به کنسول"
		_return_marker.marker_color = Color(0.55, 0.83, 1.0)
		_return_marker.visible = false
		area.add_child(_return_marker)
		area.body_entered.connect(_on_return_entered)

	func _add_room_trigger() -> void:
		var area := Area2D.new()
		area.name = "Investigation_RoomTrigger"
		area.collision_layer = 0
		area.collision_mask = detection_mask
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(640, 368)
		shape.shape = rectangle
		shape.position = Vector2(320, 184)
		area.add_child(shape)
		add_child(area)
		area.body_entered.connect(_on_room_entered)

	func _build_hud() -> void:
		_hud = CanvasLayer.new()
		_hud.name = "MedicalInvestigationHUD"
		_hud.layer = 30
		_hud.visible = false
		add_child(_hud)
		var panel := PanelContainer.new()
		panel.anchor_left = 0.1
		panel.anchor_right = 0.9
		panel.offset_left = 0
		panel.offset_right = 0
		panel.offset_top = 12
		panel.offset_bottom = 54
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.035, 0.085, 0.085, 0.9)
		style.border_color = Color(0.38, 0.8, 0.66, 0.8)
		style.set_border_width_all(1)
		style.set_corner_radius_all(5)
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		panel.add_theme_stylebox_override("panel", style)
		_hud.add_child(panel)
		_label = Label.new()
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label.add_theme_font_size_override("font_size", 13)
		_label.add_theme_color_override("font_color", Color(0.9, 1, 0.96))
		panel.add_child(_label)
		_hide_timer = Timer.new()
		_hide_timer.one_shot = true
		_hide_timer.wait_time = 5.0
		_hide_timer.timeout.connect(func() -> void: _hud.visible = false)
		add_child(_hide_timer)

	func _notify(message: String) -> void:
		_label.text = message
		_hud.visible = true
		_hide_timer.start()

	func _play_feedback() -> void:
		if _feedback != null:
			_feedback.play()

	func _on_room_entered(body: Node2D) -> void:
		if not _is_player(body) or _complete:
			return
		var count := _count_found()
		if count == 2:
			_notify("هر دو مورد پیدا شد؛ به کنسول پزشکی برگرد.")
		else:
			_notify("هدف اختیاری: یادداشت و بستهٔ پزشکی را پیدا کن. (%d/2)" % count)

	func _count_found() -> int:
		return int(_found["record"]) + int(_found["supplies"])

	func _on_pickup_entered(body: Node2D, id: String, area: Area2D) -> void:
		if not _is_player(body) or _complete or _found[id]:
			return
		_found[id] = true
		area.queue_free()
		_play_feedback()
		var count := _count_found()
		progress_changed.emit(count, 2)
		if count == 2:
			_return_marker.visible = true
			_notify("هر دو مورد پیدا شد؛ به کنسول پزشکی برگرد.")
		else:
			_notify("مورد پیدا شد. برای تکمیل جست‌وجو، مورد دیگر را بیاب. (1/2)")

	func _on_return_entered(body: Node2D) -> void:
		if not _is_player(body) or _complete or _count_found() != 2:
			return
		_complete = true
		_return_marker.visible = false
		_play_feedback()
		_notify("جست‌وجوی بخش پزشکی کامل شد.")
		objective_completed.emit()


static func _make_synth_sound(duration: float, frequencies: Array[float], looped: bool) -> AudioStreamWAV:
	# Tiny generated PCM sounds; no extra audio files or licenses required.
	const SAMPLE_RATE := 22050
	var sample_count := int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for i in range(sample_count):
		var t := float(i) / SAMPLE_RATE
		var sample := 0.0
		for n in range(frequencies.size()):
			sample += sin(TAU * frequencies[n] * t) / float(n + 1)
		var envelope := 1.0
		if not looped:
			envelope = minf(1.0, t / 0.015) * minf(1.0, (duration - t) / 0.08)
		var value := int(clampf(sample * envelope * 0.16, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, value)
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = SAMPLE_RATE
	sound.stereo = false
	sound.data = bytes
	if looped:
		sound.loop_mode = AudioStreamWAV.LOOP_FORWARD
		sound.loop_begin = 0
		sound.loop_end = sample_count
	return sound


signal investigation_progress(found: int, total: int)
signal investigation_completed

@export_group("Medical wing enhancements")
## Adds subtle local light pulses. Disable when the project supplies its own lighting.
@export var medical_lighting_enabled: bool = true
## Adds a quiet spatial ventilation hum and feedback beeps, without external assets.
@export var medical_audio_enabled: bool = true
@export_range(-60.0, 0.0, 1.0, "suffix:dB") var medical_hum_volume_db: float = -34.0
## A self-contained optional objective; it does not change health or inventory.
@export var medical_investigation_enabled: bool = true
## Player must be a CharacterBody2D and belong to this group, or have a name starting with 'Player'.
@export var medical_player_group: StringName = &"player"
@export_flags_2d_physics var medical_player_collision_mask: int = 1


func _build_enhancements() -> void:
	var hum: AudioStreamWAV = null
	var feedback: AudioStreamWAV = null
	if medical_audio_enabled:
		hum = _make_synth_sound(2.0, [55.0, 110.0, 165.0], true)
	if medical_audio_enabled and medical_investigation_enabled:
		feedback = _make_synth_sound(0.16, [660.0, 990.0], false)
	if medical_lighting_enabled or medical_audio_enabled:
		var atmosphere := MedicalAtmosphere.new()
		atmosphere.lighting_enabled = medical_lighting_enabled
		atmosphere.audio_enabled = medical_audio_enabled
		atmosphere.audio_volume_db = medical_hum_volume_db
		atmosphere.hum = hum
		add_child(atmosphere)
	if medical_investigation_enabled:
		var investigation := MedicalInvestigation.new()
		investigation.player_group = medical_player_group
		investigation.detection_mask = medical_player_collision_mask
		investigation.feedback_sound = feedback
		investigation.progress_changed.connect(_on_investigation_progress)
		investigation.objective_completed.connect(_on_investigation_completed)
		add_child(investigation)


func _on_investigation_progress(found: int, total: int) -> void:
	investigation_progress.emit(found, total)


func _on_investigation_completed() -> void:
	investigation_completed.emit()

