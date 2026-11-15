class_name MedicalData
## Last Signal — Medical Wing pack data (split from level_01.gd, 2026-11-15).
##
## 83 sprites from the pixel-art atlas (CC0) + hand-drawn tiles, in
## res://assets/sprites/medical-wing/. Only the Medical Wing uses them.

const MED_FLOOR_TEXTURE_PATH := "res://assets/sprites/environment/floor_medical_atlas.png"
const MED_FLOOR_WEIGHTS := [0.70, 0.78, 0.84, 0.85, 0.87, 0.89, 0.92, 0.94, 0.97, 0.98, 0.99, 1.0]
const MED_RECT_TILES := Rect2i(40, 0, 40, 23)
const MED_WALL_H_TEXTURE: Texture2D = preload("res://assets/sprites/medical-wing/wall_h.png")
const MED_WALL_V_TEXTURE: Texture2D = preload("res://assets/sprites/medical-wing/wall_v.png")

## Medical Wing prop textures. Keys are the pack sprite keys.
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


## The pack's wall tile for a code-built wall rect, or null to keep
## wall_metal. Only the Medical Wing's own walls are retextured.
static func wall_texture_for(r: Rect2) -> Texture2D:
	if r == Rect2(624, 0, 16, 240) or r == Rect2(624, 272, 16, 96):
		return MED_WALL_V_TEXTURE
	if r == Rect2(640, 352, 288, 16) or r == Rect2(960, 352, 320, 16):
		return MED_WALL_H_TEXTURE
	if r == Rect2(1264, 0, 16, 368):
		return MED_WALL_V_TEXTURE
	return null
