# Room 1 — Clinic redesign (medical wing), build document

Status: **design only — no code or scene was changed.** Branch: `room-1-matin`
(do not switch branches). The implementer builds from this file; a reviewer
checks the build against it three times. All coordinates are **local to the
room** (origin top-left, 640×368 px, 40×23 tiles of 16 px) unless marked
"station". Tile `(col, row)` is 0-based; the pixel centre of tile
`(col, row)` is `(16·col+8, 16·row+8)`. A "centre" in the tables is the
`_add_prop` / decor position (sprite centre). Solid = physics body +
`prop_solid_rects()` entry (nav grid). Decor = plain non-solid sprite.

Sources read for this design (all on disk, no browser):

- `docs/room1-telegram-assets-inventory.md` — Telegram assets inventory
  (**corrected 2026-11-24, see §0**).
- `~/workspace/Ahura/01-room-medical.md` — room 1 design doc (fuse-box
  fiction, notes N1-01..N1-03, voice A1-01, flashlight on bedside table,
  `QUARANTINE MODE` monitor, 20×14 suggestion — superseded by the real
  40×23 room).
- `~/workspace/your_files/game-rooms-explanations-fa.md` — the user's
  Persian explanations (room 1: side-view opening = 6 beds in two rows of
  three + medicine trolley + nurse station; top-down clinic = 4 beds +
  exam/sink/emergency/pharmacy/doctor office/storage).
- `~/workspace/Ahura/17-frontend-rendering-lighting-camera.md` — palette
  (32 colours; red = danger, amber = interactive, green = safe,
  cyan = radar/info) and lighting (medical darkness 0.92).
- `scripts/levels/rooms/medical_wing/medical_wing.gd` (947 lines, read fully)
  — current implementation; `MED_SOLID_LAYOUT` / `MED_DECOR_LAYOUT` /
  `MED_PROP_PATHS` are the data the implementer extends.
- Skills: `awesome-gamedev-agent-skills/skills/disciplines/level-design`
  (block out → reachability/pacing checks → dress last; critical path,
  gating, no soft-locks) and `.../skills/godot/godot-tilemap`
  (TileMapLayer/TileSet practice; collision data lives on the tile/prop,
  never hand-edited scene bytes). Applied here: the critical path
  (spawn → flashlight → console → pickups → exits) is laid out first and
  every new prop is checked against it (§6); art is dressing on top of
  the validated blockout, not a reshuffle of it.
- Sample maps viewed: `~/workspace/telegram-bot/media/287167607.jpg`,
  `608`, `609`, `618`, `621`, `623`, `624`, `625` (all 8, individually).
- Small photos viewed: 626 (astronaut), 627 (wheelchair), 635 (first-aid
  kit), 660 (canister); the rest per the inventory's contact-sheet
  identification. Corner pixels of 640/641 measured `(0,0,0)` — pure
  black background, confirmed.
- Every zip PNG's alpha bounding box measured with PIL (§2, "art" column)
  — collision sizes in this document come from the art, not the canvas.

## §0. Inventory correction (verified against the filesystem)

`Pngs/` holds **69 PNGs, not 70**: lab 18, maternity 11, operation 14,
room 26 (the inventory's own table only ever listed 26 `room_*` rows;
its summary said 27 and its zone-counts line double-counted
`room_pharmacy_shelf.png`). Total files catalogued: **140, not 141**
(69 PNG + 1 `.aseprite` + 4 spritesheets + 1 README + 65 photos).
The inventory file has been fixed accordingly (2026-11-24).

## §1. Bed-count decision (mandatory)

**DECISION: 6 ward beds in two rows of three in the top-down clinic,
matching the side-view opening exactly.**

Reasoning: the side-view opening and the top-down clinic are two views of
the *same* room (user's own note), and the player sees the side-view
first — 6 beds there and 4 beds here would read as a continuity error.
The 4-bed layout (2026-11-23) predates the Telegram pack; the pack's bed
variants make a second row dressable without new art. The space for row B
comes from the currently empty central-north floor (rows 4–6, cols 1–13 —
open floor between the old ward row and the console/scanner area), not
from any other zone: the 2-tile aisle between the rows (rows 4–5) is
kept, every fixed point is untouched, and row B is cleanly removable
(delete `MedBed4`, `MedBed5`, `MedBedDisorganized`, 2 bedside tables,
`MedIVW`, `MedECGCart`, `MedBiohazardY`) if a review ever wants 4 beds
back. Sleep surfaces in the final room (11 total, each a different
object, no double-counting):

| # | Surface | Node | Position (centre) |
|---|---|---|---|
| 1–3 | Ward row A (north) | `MedBedStandard` (FIXED), `MedBedEmpty`, `MedBed3` | (48,56), (96,56), (144,56) |
| 4–6 | Ward row B (south) | `MedBed4` (new), `MedBed5` (new), `MedBedDisorganized` (**moved** from (192,56)) | (48,104), (96,104), (144,104) |
| 7–8 | Observation bay | `MedObsBedH`, `MedObsBedV` (zip `room_bed_h` / `room_bed_v`) | (224,56), (296,48) |
| 9 | Exam bed | `MedExamBed` (unchanged) | (352,56) |
| 10 | Stretcher (emergency) | `MedStretcher` (unchanged) | (48,216) |
| 11 | Recovery bed (physio corner) | `MedMatBed` (zip `maternity_bed`) | (232,224) |

Ward-bed textures (existing atlas sprites, reused): `bed_standard` ×3
(Standard, Bed3, Bed4), `bed_empty` ×2 (BedEmpty, Bed5),
`bed_disorganized` ×1 (row B east end — the unmade bed, "someone left in
a hurry", stays visible from the entrance aisle). Beds stay 2×1 tiles
with 1-tile gaps, per the hard constraint. The zip bed sprites are
**not** ward beds: `room_bed_h` (canvas 32×32, art 28×24) and
`room_bed_v` (16×32) are the two observation-bay beds, and
`room_bed_meal` (art is vertical, 19×28) is the second exam couch (§3).

## §2. Zone map (40×23)

Zones (tile rects, inclusive):

| Zone | Tiles (cols × rows) | Map inspiration |
|---|---|---|
| Ward (6 beds, 2 rows of 3) | cols 1–13, rows 1–7 | **607** — ward sample map: bed flanked by two armchairs, bedside table with flowers, tall cabinet + biohazard bin on the right wall, anatomy poster + sanitiser on the wall |
| Observation bay | cols 14–19, rows 1–5 | 607 (second bed + IV stand) + **621** (exam-room beds row) |
| Exam | cols 20–27, rows 1–5 | **621** (exam room top-right: bed, cabinets, sink) + **614** (EXAM labelled sheet) |
| Lab corner | cols 28–38, rows 1–7 | **608** — lab sample map, followed literally: back wall sink → computer → fridge → wooden cabinet; long centre bench with microscope/centrifuge/computer; stools replaced by the lab robot (no stool file exists) |
| Operation + imaging | cols 28–38, rows 8–14 | **609** — theatre vignette: table centre under twin light, anaesthesia/ECG left, monitor right, instrument table; **624/625** — radiology: CT on the wall, monitor + radiation sign, X-ray table |
| Nurse station | cols 20–26, rows 9–10 | 621 (corridor nurse station) + 612 (STATION sheet); trolley + side table + rolling chair, unchanged |
| Recovery / physio corner (maternity, repurposed — §7) | cols 13–19, rows 11–14 | **624** centre room (maternity: bassinets along the top wall, changing table, cot) — layout rhythm only; the furniture is repurposed, see §3 |
| Emergency / west bay | cols 1–6, rows 11–17 | **618** — emergency/ambulance bay: wheelchair + stretcher by the entrance, first-aid on the wall |
| Entrance corridor + waiting | rows 15–16, cols 0–19 (corridor); waiting chair col 7, row 17 | 618/621 (corridor with benches + wheelchair) |
| Storage SW | cols 1–6, rows 18–21 | 612 (STAFF / storage) |
| Pharmacy (south wall) | cols 22–34, row 21 | **621** — pharmacy top row (green chequered floor, medicine shelves, counter) |
| Doctor's office SE | cols 31–35, rows 17–20 | 621 (reception/office: desk + office chairs) |
| Circulation (kept clear) | rows 15–16 E–W; cols 17–18 N–S link; rows 17–19 south | 618/621 (corridor as the spine every room opens onto) |

ASCII grid (40 cols × 23 rows; `#` wall, `=` open door gap, `.` open
floor, `B` bed, `b` bedside table, `M` monitor/ECG, `I` IV stand,
`E` exam, `L` lab, `O` operation/imaging, `P` pharmacy, `F` office,
`S` storage, `N` nurse station, `W` emergency, `R` recovery/physio,
`X` scanner, `C` console, `H` wheelchair, `x` bin, `a` armchair,
`T` table/trolley, `*` small decor, `o` investigation trigger):

```
row 0  ########################################
row 1  #*...........*........................*#
row 2  #.M.....M..m..k...B.M....E.ELLL.L.L.L..#
row 3  #IBBbBBbBBbaxBB.b.B..BB.E.EE...........#
row 4  #.............................RR.......#
row 5  #......C.....x.T.......................#
row 6  #IBBbBBbBBIM.x..............l..LLLLLL..#
row 7  #...............X..............LLLL....#
row 8  #...........................O.OO..OO...#
row 9  #.......................NN..O.OO...OOO.#
row 10 #...................N.........OOO..OOO.#
row 11 #W.W..........................OOO..OOO.#
row 12 #W............R...RR........W...O..OOO.#
row 13 #.WWWW.......RR.R.RR............O......#
row 14 #H.H.H.......RR.**.....................#
row 15 =......................................#
row 16 =...S..................................#
row 17 #H.....H...........................F...#
row 18 #.S............................FFF.....#
row 19 #.......................o..............#
row 20 #.SS.SS.........................o......#
row 21 #...S.S...............P.P.P.P.P.P.P....#
row 22 ##################==####################
```

Read the grid with the tables in §3–§4 (a glyph may cover a multi-tile
prop; the tables are authoritative for exact centres).

## §3. Placement — zip PNGs (69/69)

Rules applied to every file ("what every sprite in means"):

- **Orientation variants** (`room_bed_h` vs `room_bed_v`,
  `lab_microscope_h` vs `_v`, `room_table_meal_h` vs `_v`): each file is
  its own object; the orientation that fits the spot is placed. Beds:
  `_h` = observation bed 1 (horizontal), `_v` = observation bed 2
  (vertical). Microscopes: both on the lab bench, side by side.
  Meal tables: `_h` = decor on ward bed A2, `_v` = solid table in the
  observation bay, `table_meal_bed` = decor on ward bed B2.
- **Numbered variants** (`lab_vial_001–004`, `room_pills_01–02`,
  `operation_scalpel_01–02`, `maternity_towel_01–02`): each file is its
  own small prop, placed individually (vials in a row on the lab bench
  table; pills on pharmacy shelves; scalpels on the two instrument
  tables; towels on the recovery bed / chair).
- **Colour variants** (`room_iv_stand_b/g/w`, `room_biohazard_bin` /
  `_y`): each is its own prop (three IV stands at three bed heads; red
  bin in the ward, yellow bin at row B).
- **`_full` composites** (`lab_wooden_cabinet_full`,
  `operation_accessories_table_full`, `operation_console_full`,
  `operation_ecg_full`): each is placed as **one single prop** (the
  stocked/complete version of the object), next to its empty sibling —
  never sliced apart. `operation_console_computer` (32×16) is the one
  exception: it is placed as **decor stacked on**
  `operation_console_table` (same centre), i.e. the computer sitting on
  its console desk.
- **Collision = art, not canvas.** `art` below is the measured
  non-transparent bounding box (x0,y0,x1,y1 in canvas px). Collision
  sizes follow the art rounded to 16 px, never the canvas (e.g. the CT
  scanner's canvas is 64×80 but its art is 49×69, so collision is
  48×64). Where art overhangs the collision by a few px the overhang
  always faces a wall or free floor, never a walkway.
- New node names use the `Med*` convention. New texture keys go in
  `MED_PROP_PATHS` under `assets/sprites/medical-wing/telegram/`
  (room-owned folder; nothing outside the room's three folders).

### 3.1 Lab (18/18) — lab corner, after 608

| File | Art (canvas) | Solid / decor | Centre (tile) | Node / purpose |
|---|---|---|---|---|
| `lab_sink.png` | (6,4,25,24) of 32×32 | solid 32×16 | (464,40) c28–29,r2 | `MedLabSink` — back-wall sink unit, west end of the lab wall |
| `lab_computer.png` | (2,6,14,23) of 16×32 | solid 16×16 | (496,40) c30,r2 | `MedLabComputer` — desktop PC + monitor on the back wall (art overhangs 10 px north into the wall row) |
| `lab_refrigerator.png` | (0,0,16,30) of 16×32 | solid 16×32 | (520,48) c32,r2–3 | `MedLabFridge` — tall lab fridge |
| `lab_wooden_cabinet.png` | (8,3,25,30) of 32×32 | solid 16×32 | (552,48) c34,r2–3 | `MedLabCabinet` — wooden cabinet, closed |
| `lab_wooden_cabinet_full.png` | (8,3,25,30) of 32×32 | solid 16×32 | (584,48) c36,r2–3 | `MedLabCabinetFull` — same cabinet, stocked/open |
| `lab_large_table.png` | (0,8,64,32) of 64×32 | solid 64×32 | (528,112) c31–34,r6–7 | `MedLabBench` — long centre bench (608's bench; walkway rows 4–5 kept between it and the back wall) |
| `lab_medium_table.png` | (3,1,29,16) of 32×16 | solid 32×16 | (576,104) c35–36,r6 | `MedLabTableMed` — second bench, vial row on top |
| `lab_automation_robot.png` | (7,1,25,15) of 32×16 | solid 32×16 | (496,80) c30–31,r4 | `MedLabRobot` — small top-down lab robot, parked in the walkway (leaves row 5 free) |
| `lab_microscope_h.png` | (3,2,12,14) of 16×16 | decor on bench | (504,112) | `MedLabMicroH` — on `MedLabBench` |
| `lab_microscope_v.png` | (5,3,11,14) of 16×16 | decor on bench | (552,112) | `MedLabMicroV` — on `MedLabBench` |
| `lab_sample_centrifuge.png` | (2,1,14,16) of 16×16 | decor on bench | (520,112) | `MedLabCentrifuge` — on `MedLabBench` |
| `lab_sample_vials.png` | (2,5,13,12) of 16×16 | decor on bench | (536,112) | `MedLabVialRack` — vial rack on `MedLabBench` |
| `lab_vial_001.png` | (7,7,9,10) of 16×16 | decor on med table | (568,104) | `MedLabVial1` |
| `lab_vial_002.png` | (7,6,9,10) of 16×16 | decor on med table | (576,104) | `MedLabVial2` |
| `lab_vial_003.png` | (7,7,9,10) of 16×16 | decor on med table | (584,104) | `MedLabVial3` |
| `lab_vial_004.png` | (7,7,9,10) of 16×16 | decor on med table | (592,104) | `MedLabVial4` |
| `lab_books.png` | (5,6,11,10) of 16×16 | decor on cabinet | (552,40) | `MedLabBooks` — book stack on `MedLabCabinet` |
| `lab_paper_dispenser.png` | (3,2,13,14) of 16×16 | decor, wall | (616,24) c38,r1 | `MedLabDispenser` — wall-mounted above the lab bench row, north wall |

### 3.2 Maternity (11/11) — recovery / physio corner, repurposed (§7)

The station has a 5-person crew and no maternity ward; the set is used
as the clinic's **recovery/physio corner** (the pack's only soft
furniture — a bare-metal clinic needs it to read lived-in). Every piece
keeps its file; only its in-fiction label changes, except the rope
(weakest repurpose, flagged in §7).

| File | Art (canvas) | Solid / decor | Centre (tile) | Node / purpose |
|---|---|---|---|---|
| `maternity_bed.png` | full 27×35 | solid 32×32 | (232,224) c13–14,r13–14 | `MedMatBed` — adjustable recovery bed (sleep surface 11) |
| `maternity_chair.png` | full 16×20 | solid 16×16 | (264,216) c16,r13 | `MedMatChair` — recovery chair beside the bed (south of the scanner LOS end, y208 > 200) |
| `maternity_table.png` | full 13×13 | solid 16×16 | (296,216) c18,r13 | `MedMatTable` — side table for the recovery bed |
| `maternity_ball.png` | full 13×12 | solid 16×16 | (232,192) c14,r11–12 | `MedMatBall` — physio/exercise ball |
| `maternity_light.png` | full 19×34 | solid 16×16 | (296,192) c18,r11–12 | `MedMatLamp` — floor lamp (base collides; art overhangs north) |
| `maternity_work_cabinet.png` | full 16×36 | solid 16×32 | (312,208) c19,r12–13 | `MedMatCabinet` — linen/supply cabinet |
| `maternity_carpet.png` | full 36×18 | decor, floor | (264,232) c16–17,r14 | `MedMatCarpet` — rug under chair/table |
| `maternity_birthing_rope.png` | full 12×49 | decor, hanging | (216,200) c13,r11–14 | `MedMatRope` — suspension-therapy strap hanging beside the recovery bed (see §7) |
| `maternity_cottons.png` | full 9×9 | decor on table | (296,216) | `MedMatCottons` — cotton balls on `MedMatTable` |
| `maternity_towel_01.png` | full 8×7 | decor on bed | (232,224) | `MedMatTowel1` — folded towel on `MedMatBed` |
| `maternity_towel_02.png` | full 8×7 | decor on chair | (264,216) | `MedMatTowel2` — towel on `MedMatChair` |

### 3.3 Operation + imaging (14/14) — after 609 and 624/625

| File | Art (canvas) | Solid / decor | Centre (tile) | Node / purpose |
|---|---|---|---|---|
| `operation_table.png` | (4,0,29,44) of 32×48 | solid 32×48 | (496,176) c30–31,r9–11 | `MedOpTable` — operating table, centre of the theatre |
| `operation_light.png` | (5,0,26,28) of 32×32 | decor, hanging | (496,152) | `MedOpLight` — twin surgical light hung over `MedOpTable` (non-solid: it hangs from the ceiling, 609) |
| `operation_ct_scanner.png` | (8,7,57,76) of 64×80 | solid 48×64 | (584,176) c35–37,r9–12 | `MedCTScanner` — CT/imaging scanner against the east wall (largest piece in the pack; approach from col 34, kept free) |
| `operation_ultrasound_machine.png` | (6,2,24,32) of 32×32 | solid 16×32 | (528,176) c32,r10–11 | `MedUltrasound` — ultrasound machine east of the table |
| `operation_ecg_full.png` | (7,7,25,32) of 32×32 | solid 16×32 | (464,144) c28,r8–9 | `MedOpECG` — complete ECG unit west of the table |
| `operation_ecg_screen.png` | (1,3,15,16) of 16×16 | decor, wall | (496,124) | `MedOpECGScreen` — ECG screen mounted above `MedOpConsoleFull` |
| `operation_console_full.png` | (4,9,28,32) of 32×32 | solid 32×16 | (496,136) c30–31,r8 | `MedOpConsoleFull` — complete console north of the table |
| `operation_console_table.png` | (4,0,28,16) of 32×16 | solid 32×16 | (560,136) c34–35,r8 | `MedOpConsoleTable` — console desk east of the above |
| `operation_console_computer.png` | (2,4,20,16) of 32×16 | decor on table | (560,136) | `MedOpConsolePC` — computer sitting on `MedOpConsoleTable` |
| `operation_accessories_table.png` | (2,0,15,16) of 16×16 | solid 16×16 | (464,192) c28,r11–12 | `MedOpTrayEmpty` — instrument table, empty |
| `operation_accessories_table_full.png` | (2,0,15,16) of 16×16 | solid 16×16 | (528,208) c32,r12–13 | `MedOpTrayFull` — instrument table, stocked |
| `operation_scalpel_01.png` | (5,7,11,8) of 16×16 | decor on tray | (464,192) | `MedOpScalpel1` — on `MedOpTrayEmpty` |
| `operation_scalpel_02.png` | (5,7,11,8) of 16×16 | decor on tray | (528,208) | `MedOpScalpel2` — on `MedOpTrayFull` |
| `operation_radiation_sign.png` | (0,1,15,15) of 16×16 | decor, wall | (632,176) | `MedRadiationSign` — radiation warning on the east wall beside the CT (existing `x=632` wall-decor convention) |

`operation_ecg_table.aseprite` (720 B, **not a PNG**): source file for
the ECG table only — **not placed**. The ECG is represented by
`operation_ecg_full` + `operation_ecg_screen` above. Do not invent an
ECG-table PNG from it without opening it in Aseprite.

### 3.4 Room / ward (26/26)

Existing ward furniture keeps its current nodes/positions unless noted.
New ward row B nodes: `MedBed4` (48,104), `MedBed5` (96,104);
`MedBedDisorganized` **moves** (192,56) → (144,104).

| File | Art (canvas) | Solid / decor | Centre (tile) | Node / purpose |
|---|---|---|---|---|
| `room_bed_h.png` | (0,8,28,32) of 32×32 | solid 32×16 | (224,56) c13–14,r3 | `MedObsBedH` — observation bed 1 (art overhangs 8 px south; faces free floor) |
| `room_bed_v.png` | (0,0,15,28) of 16×32 | solid 16×32 | (296,48) c18,r2–3 | `MedObsBedV` — observation bed 2, vertical |
| `room_bed_meal.png` | (12,0,31,28) of 32×32 | solid 16×32 | (440,48) c27,r2–3 | `MedExamCouch2` — second exam/recovery couch (bed with meal tray; art is vertical) |
| `room_bedside_table.png` | (3,0,13,12) of 16×16 | solid 16×16 | (264,56) c16,r3 | `MedObsTable` — shared bedside table between the two observation beds |
| `room_armchair.png` | (2,12,14,32) of 16×32 | solid 16×16 | (184,56) c11,r3 | `MedArmchairWard` — visitor armchair, east end of ward row A (607: two armchairs flank the bed — the second armchair is the existing `MedChairOffice` family; no second file exists) |
| `room_cabinet.png` | (1,8,16,32) of 16×32 | solid 16×16 | (232,40) c14,r2 | `MedCabinetWard` — tall cabinet at the head of `MedObsBedH` (art overhangs north into row 1) |
| `room_ecg_cart.png` | (0,12,16,32) of 16×32 | solid 16×16 | (184,104) c11,r6 | `MedECGCart` — ECG cart, east end of ward row B |
| `room_ecg_screen.png` | (2,5,14,16) of 16×16 | decor, wall | (184,40) c11,r2 | `MedECGScreenWard` — wall monitor above the armchair |
| `room_iv_stand_b.png` | (0,0,16,29) of 16×32 | solid 16×16 | (24,56) c1,r3 | `MedIVB` — IV stand, head of `MedBedStandard` (base collides; pole art overhangs north) |
| `room_iv_stand_g.png` | (0,0,11,25) of 16×32 | solid 16×16 | (24,104) c1,r6 | `MedIVG` — IV stand, head of `MedBed4` |
| `room_iv_stand_w.png` | (0,0,16,29) of 16×32 | solid 16×16 | (168,104) c10,r6 | `MedIVW` — IV stand, east end of `MedBedDisorganized` |
| `room_biohazard_bin.png` | (4,2,13,14) of 16×16 | solid 16×16 | (200,56) c12,r3 | `MedBiohazard` — red biohazard bin, ward row A (607, right wall) |
| `room_biohazard_bin_y.png` | (4,2,13,14) of 16×16 | solid 16×16 | (216,104) c13,r6 | `MedBiohazardY` — yellow biohazard bin, ward row B |
| `room_trash_bin.png` | (7,2,16,16) of 16×16 | solid 16×16 | (216,88) c13,r5 | `MedTrashWard` — trash bin in the ward aisle (row 4 stays free beside it) |
| `room_table_meal_v.png` | (4,14,12,32) of 16×32 | solid 16×16 | (248,88) c15,r5 | `MedMealTableV` — over-bed meal table between the observation beds |
| `room_pharmacy_shelf.png` | (0,3,15,13) of 16×16 | solid 16×16 | (552,344) c34,r21 | `MedPharmacyShelf` — the zip's only pharmacy shelf; extends the pharmacy east (see §4 for the bottles on it) |
| `room_anatomy_poster.png` | (3,2,13,14) of 16×16 | decor, wall | (24,24) c1,r1 | `MedPosterAnatomy` — anatomy poster, north wall above bed 1 (607) |
| `room_hand_sanitizer.png` | (5,3,10,12) of 16×16 | decor, wall | (216,24) c13,r1 | `MedSanitizer` — hand-sanitiser dispenser, north wall (607, top-right) |
| `room_flower.png` | (4,0,13,13) of 16×16 | decor on table | (72,56) | `MedFlower` — flowers on `MedBedside1` (607) |
| `room_meal_tray.png` | (2,5,14,12) of 16×16 | decor on table | (120,56) | `MedMealTray` — meal tray on `MedBedside2` |
| `room_soup.png` | (5,4,11,11) of 16×16 | decor on table | (120,104) | `MedSoup` — soup bowl on row-B bedside table 2 |
| `room_pear.png` | (5,5,9,10) of 16×16 | decor on table | (72,104) | `MedPear` — pear on row-B bedside table 1 |
| `room_table_meal_h.png` | (0,0,13,16) of 16×16 | decor on bed | (96,56) | `MedMealTableH` — over-bed table on `MedBedEmpty` |
| `room_table_meal_bed.png` | (0,0,13,16) of 16×16 | decor on bed | (96,104) | `MedMealTableBed` — over-bed table on `MedBed5` |
| `room_pills_01.png` | (5,4,10,12) of 16×16 | decor on shelf | (392,336) | `MedPills1` — pills on `MedShelfMedicine` (top edge) |
| `room_pills_02.png` | (6,5,10,11) of 16×16 | decor on cabinet | (520,336) | `MedPills2` — pills on `MedCabinetOpen` (top edge) |

Unchanged existing ward/exam/emergency/pharmacy/office/storage props
(kept at their current centres — the implementer does not move them):
beds row A + 4 bedside tables + monitors (40,40)/(136,40), exam bed /
lamp / monitor / sink / infusion pump, stretcher / defibrillator /
cart / wheelchair / oxygen cylinder, pharmacy row (360–520,344),
doctor desk / chair / side table, storage boxes / oxygen unit / waste
bin / worn cabinet, nurse-station trolley / side table / rolling chair,
crate (40,296), all wall decor and lights. Two moves only:
`MedBedDisorganized` (192,56) → (144,104) (§1), and nothing else.

## §4. Placement — small photos (46/46)

Source files: `~/workspace/telegram-bot/media/287167626.jpg` …
`287167671.jpg`. All are 101×101 JPG, one icon per photo on a **pure
black** background (corner pixels measured `(0,0,0)`), icon ≈ 60–70 px
across, isometric-ish style, different from the zip pack. Import per
§5; positions below are the **in-game** centres after conversion
(16×16 unless noted). Rule: photo sprites are **decor clutter, never
interactables** — they sit on top of furniture that already exists, so
they can never be mistaken for an amber-pulsed interactive (§5.3).
"Stacked" = decor sprite at (or a few px beside) the named solid prop's
centre, drawn above it.

### 4.1 Pharmacy (14) — on the south-wall pharmacy row (§3.4)

Offsets are ±4–8 px around the furniture top edge (y≈336–340) so the
tiny icons read as separate bottles on a shelf, not one blob.

| Photo | Identified sprite | Centre | Node / on top of |
|---|---|---|---|
| 287167628 | Pill bottle, red label | (356,340) | `MedPhotoPill628` on `MedCabinetMedicine` (360,344) |
| 287167651 | Pill bottle, orange cap | (388,340) | `MedPhotoPill651` on `MedShelfMedicine` (392,344) |
| 287167652 | Medicine bottle, orange cap | (420,340) | `MedPhotoPill652` on `MedCabinetStorage` (424,344) |
| 287167654 | Medicine bottle, orange cap, white label | (452,340) | `MedPhotoPill654` on `MedFridge` (456,344) |
| 287167661 | Pill bottle, orange, white band | (484,340) | `MedPhotoPill661` on `MedCabinetClosed` (488,344) |
| 287167629 | Medicine jar, cork lid, red heart | (516,340) | `MedPhotoJar629` on `MedCabinetOpen` (520,344) |
| 287167631 | Medicine jar, blue liquid | (548,340) | `MedPhotoJar631` on `MedPharmacyShelf` (552,344) |
| 287167647 | Medicine jar, white label, red heart | (364,340) | `MedPhotoJar647` on `MedCabinetMedicine` |
| 287167630 | Blister pack, green pills | (396,340) | `MedPhotoBlister630` on `MedShelfMedicine` |
| 287167656 | Blister pack, pink pills | (524,340) | `MedPhotoBlister656` on `MedCabinetOpen` |
| 287167655 | Medicine carton, white/red stripe | (428,340) | `MedPhotoCarton655` on `MedCabinetStorage` |
| 287167646 | Red-and-white box (medicine/first-aid box — ID uncertain, inventory §7) | (460,340) | `MedPhotoBox646` on `MedFridge` |
| 287167660 | Lidded canister/jar, orange, patterned front (verified visually 2026-11-24: squat cylindrical jar with a lid — "specimen canister") | (556,340) | `MedPhotoCanister660` on `MedPharmacyShelf` |

### 4.2 Emergency (11) — west bay, after 618

| Photo | Identified sprite | Solid / decor | Centre (tile) | Node / purpose |
|---|---|---|---|---|
| 287167635 | First-aid kit, white, green cross | decor, wall | (-8,200) | `MedKitWall1` — wall-mounted kit, west wall row 12 |
| 287167641 | First-aid kit, white, red cross | decor, wall | (-8,216) | `MedKitWall2` — west wall row 13 |
| 287167662 | First-aid kit, red, white cross | decor, wall | (-8,232) | `MedKitWall3` — west wall row 14 |
| 287167636 | First-aid kit, white, blue cross | decor on cart | (88,216) | `MedKitCart` — on `MedCartEmergency` |
| 287167663 | First-aid kit, white, red cross, red side | decor on defib | (72,216) | `MedKitDefib` — on `MedDefibrillator` |
| 287167671 | First-aid kit, white, red cross in circle | decor on shelf | (400,336) | `MedKitPharm` — on `MedShelfMedicine` (the 6th kit lives in pharmacy, where kits are stored) |
| 287167637 | First-aid / medicine box, cardboard, red cross + heart | decor on cabinet | (360,336) | `MedKitBox637` — on `MedCabinetMedicine` |
| 287167659 | Red chest, white-cross lid (first-aid box — ID uncertain) | decor on stretcher | (48,216) | `MedKitChest659` — on `MedStretcher` |
| 287167642 | Blood bag, white/red, hanging | decor on IV stand | (24,104) | `MedBloodBag642` — hanging on `MedIVG` |
| 287167670 | Blood / IV bag, red, with tubes | decor on IV stand | (168,104) | `MedBloodBag670` — hanging on `MedIVW` |
| 287167643 | Oxygen tank, teal cylinder with hose | solid 16×16 | (24,184) c1,r11 | `MedOxygenTank2` — second oxygen tank, beside `MedOxygenCyl` (24,200) |

### 4.3 Exam (7) — exam zone + nurse station

| Photo | Identified sprite | Centre | Node / on top of |
|---|---|---|---|
| 287167632 | Syringe, vertical, pink/red | (392,56) | `MedSyringe632` on `MedExamLamp` |
| 287167645 | Syringe, diagonal, blue/white | (424,56) | `MedSyringe645` on `MedInfusionPump` |
| 287167649 | Syringe, diagonal, teal/grey | (356,52) | `MedSyringe649` on `MedExamBed` (exam tray, NW corner) |
| 287167657 | Syringe, diagonal, red/white | (394,340) | `MedSyringe657` on `MedShelfMedicine` (pharmacy keeps one syringe tray) |
| 287167658 | Syringe, diagonal, red/blue | (328,168) | `MedSyringe658` on `MedTrolley` (nurse station) |
| 287167633 | Adhesive bandage / plaster, diagonal | (348,60) | `MedBandage633` on `MedExamBed` (exam tray, SW corner) |
| 287167634 | Bandage / gauze roll, yellow-blue | (392,152) | `MedBandage634` on `MedSideTable` (nurse station) |
| 287167669 | Thermometer, red/white, vertical | (360,60) | `MedThermo669` on `MedExamBed` (exam tray, SE corner) |

(Exam tray = 3 tiny decors on `MedExamBed` at (348,60), (356,52),
(360,60) — they do not overlap each other.)

### 4.4 Lab (6) — lab corner

| Photo | Identified sprite | Centre | Node / on top of |
|---|---|---|---|
| 287167664 | Microscope, side view, grey/green | (588,100) | `MedPhotoMicro664` on `MedLabTableMed` |
| 287167665 | Test tube, red liquid | (512,108) | `MedPhotoTube665` on `MedLabBench` |
| 287167666 | Green lab flask / bottle | (544,108) | `MedPhotoFlask666` on `MedLabBench` |
| 287167644 | Small green bottle / vial | (572,100) | `MedPhotoVial644` on `MedLabTableMed` |
| 287167668 | Small white robot, blue eyes, front view | (464,112) solid 16×16, c28,r6 | `MedPhotoRobot668` — service robot parked at the west end of the lab bench (front-facing cute robot vs. the zip's top-down robot — style clash noted in §5.3; it is small and reads as a service unit) |
| 287167639 | Sink / pedestal wash basin with taps | (56,184) solid 16×16, c3,r11 | `MedPhotoSink639` — scrub sink in the emergency bay (the lab already has `lab_sink`; a second basin belongs by the stretcher, 618) |

### 4.5 Beds ward (2), entrance (4), doctor office (1), misc (1)

| Photo | Identified sprite | Solid / decor | Centre (tile) | Node / purpose |
|---|---|---|---|---|
| 287167638 | IV / fluid bag, orange liquid, 3 drip lines | decor on IV stand | (24,56) | `MedIVBag638` — hanging on `MedIVB` (head of `MedBedStandard`) |
| 287167650 | Hospital bed, isometric, white | solid 16×16 | (104,328) c6,r20 | `MedPhotoBed650` — **folded spare bed in storage** (isometric angle would clash as a made-up bed; folded/leaning in storage it reads correctly — see §7) |
| 287167627 | Wheelchair, dark, side view | solid 16×16 | (24,232) c1,r14 | `MedWheelchair2` — wheelchair bay, emergency (north of the entry corridor) |
| 287167640 | Wheelchair, green, side view | solid 16×16 | (56,232) c3,r14 | `MedWheelchair3` — wheelchair bay |
| 287167648 | Wheelchair, dark, side view | solid 16×16 | (88,232) c5,r14 | `MedWheelchair4` — wheelchair bay |
| 287167667 | Wheelchair, red, side view | solid 16×16 | (120,280) c7,r17 | `MedWheelchairWait` — waiting-area wheelchair by the entrance (618/621 show wheelchairs at entrances) |
| 287167653 | Computer monitor, desktop | decor on table | (568,280) | `MedPhotoMonitor653` — spare monitor on `MedSideTableOffice` |
| 287167626 | Astronaut, white suit, red trim | solid 16×16 | (104,344) c6,r21 | `MedPhotoSuit626` — **EVA suit on a rack in storage** (a crew member's suit stored in the clinic's storage; it is not a hospital prop and is not presented as one) |

## §5. Spritesheets, JPG import, palette & lighting

### 5.1 Spritesheets (4) — backup sources, 0 props placed directly

All four are 128×128 RGBA = an 8×8 grid of 16×16 cells. They
**duplicate** the `Pngs/` files (inventory §3, confirmed by cell-alpha
analysis below), so no prop is placed from a sheet as a primary source —
the `Pngs/` files are used directly. The sheets' role is **fallback**:
if a `Pngs/` file is ever missing/corrupt, slice the matching tile from
its sheet (find the cell by visual match against the PNG). The one
sheet-only item (a first-aid box on sheet 01, inventory §3) needs no
slice: first-aid boxes are already covered six times over by photos
635/636/641/662/663/671 (§4.2).

Measured non-empty 16×16 cells (alpha pixels > 10, per cell; `.` =
empty; multi-tile sprites span cells, e.g. sheet 02 rows 4–5 cols 1–2
are fully opaque 256-px cells = the CT scanner):

- `spritesheet_hospital_01.png` (ward): row 0: all 8 cells; row 1: all
  8; row 2: all 8; row 3: all 8; row 4: all 8; row 5: cols 0–4; row 6:
  cols 3–4; row 7: empty.
- `spritesheet_hospital_02.png` (operation/imaging): row 0: all 8;
  row 1: all 8; row 2: all 8; row 3: cols 1–7; row 4: cols 0–6;
  row 5: cols 0–3, 5–6; row 6: cols 0–5; row 7: cols 1–2, 4–5.
- `spritesheet_hospital_lab.png` (lab): rows 0–1: all 8; row 2: all 8;
  row 3: cols 0–1, 3–7; row 4: cols 0–1, 3–7; row 5: cols 0–1, 3–4;
  rows 6–7: empty.
- `spritesheet_hospital_maternity.png` (maternity): row 0: cols 0–1,
  3–7; row 1: all 8; row 2: cols 0–6; row 3: cols 1–3; row 4: cols
  0–3; row 5: col 0; row 6: col 0; row 7: empty.

Do not re-slice a sheet into 16×16 tiles as a runtime atlas: the pack
is already split into files, and a sliced atlas would duplicate the
same art under two paths.

### 5.2 JPG import (46 photos) — decision

**Primary treatment for all 46: batch-convert the JPG to PNG with the
black background keyed out.** No photo is used as a JPG in-game.
Implementer script (new, room-owned, e.g.
`scripts/levels/rooms/medical_wing/tools/import_photo_sprites.py`,
PIL only — do not hand-convert 46 files):

1. Load the 101×101 JPG. Flood-fill from the four edges on near-black
   (`RGB < 16` on all channels) — this removes the background *and*
   the JPEG halo around the icon without eating dark icon pixels that
   are not connected to the edge.
2. Crop to the content bounding box; pad to square; resize to fit
   16×16 with LANCZOS (the icons are ~60–70 px of detail; NEAREST
   downscale would shatter them — LANCZOS, then no further filtering).
3. 1-px alpha erosion on the cut edge (kills the remaining dark
   fringe); save RGBA PNG to
   `assets/sprites/medical-wing/telegram-photos/<id>_<name>.png`.
4. Wheelchairs (627/640/648/667) and the bed (650) are wider than tall:
   fit to 16 wide, keep aspect (they will sit in a 16×16 collision
   with vertical padding — correct, they are side-view objects).
5. Verify each output visually at 4× before use; any sprite whose key
   leaves a visible black box is **not** placed from the JPG — use its
   pixel-DB stand-in below instead, and note the swap in the build log.

**Pixel-DB stand-ins (optional, fallback only).** The 200 transparent
16×16 clinic sprites in `~/workspace/your_files/clinic-sprites/`
(CC0, `CLINIC_SPRITES.md`) are used **only** if a JPG keys badly.
Planned fallback mapping (check the named file visually before use;
row_ids from `CLINIC_SPRITES.md`):

| Photo | Risk | Stand-in if keying fails |
|---|---|---|
| 660 canister | patterned front, mid-tones near black | `030_medicine_bottle.png` (row_id 2373) — clean medicine bottle |
| 646 red/white box | top pattern not legible at 101 px | `044_box_of_bandages.png` (row_id 1519) — red box |
| 655 medicine carton | white box, thin red stripe, soft edges | keep the keyed JPG (boxes key cleanly); no stand-in assigned — if it fails, drop to a plain white-box recolour of 044 |
| 659 red chest | white dots on red, soft edges | `045_first_aid_kit.png` (row_id 2571) — red first-aid kit |
| 637 cardboard box | brown cardboard, mid-tones | `044_box_of_bandages.png` (row_id 1519) |
| all others | hard edges, high contrast vs black | key cleanly; stand-ins exist for the same objects if ever needed (syringe 039/040/041, first-aid 045/046/047, thermometer 061/062, wheelchair 076/077/078, microscope 053/054, flask 058/158, oxygen 027/028, blood bag 081/082, bandage 042/043/044, sink 072/073, monitor 022–026, astronaut 021/121, robot 093/094) |

No pixel-DB sprite is placed as a primary prop. Do not import the 200
as a set; only the named fallback files, only if needed.

**Photos that are reference only (not sprites on disk):** the 11
tileset/labelled/prop sheets (610–617, 619, 620, 622) and the 8 sample
maps are layout references, not importable art — their tiles exist
only as pixels inside JPG screenshots. No tile is traced or cut out of
them. (Consequence in §7: dental, reception desk, X-ray table and
lead aprons cannot be built from files on disk.)

### 5.3 Palette & lighting (doc 17)

- Floor stays the uniform medical tile (4,0) on all 920 cells — the
  pack's light-blue floor tiles are **not** used, so there is no floor
  clash. Walls stay the existing `wall_metal` / pack wall tiles.
- Palette roles are preserved: **red** = danger (biohazard bins,
  first-aid kits, oxygen-tank red trim, emergency light, radiation
  sign — all danger/medical-alert objects, consistent); **amber** =
  interactive only (the engine's amber pulse outline on interactables
  — console, pickups, note). The photo pill bottles are orange/amber
  but they are **decor only, never outlined**, so they cannot be read
  as interactables; their amber reads as "medicine label", not "use
  me". **Green** = safe/monitor (vitals-monitor screens, ECG screens,
  the `MedLightGreen` lamp). The operation set's scrub-green furniture
  (table, ECG unit) is the one risk: green furniture could read as
  "safe" — mitigation is to add **no green light** to the theatre and
  keep the green to the monitor screens only; at 0.92 darkness the
  furniture greens go near-black anyway. **Cyan** = radar/info (the
  new lab-bench light, §5.4; the console screen).
- Style clashes, handled honestly:
  - Zip pack (16-bit top-down, light blue/grey) vs. existing medical
    atlas: compatible — same top-down pixel style, same 16-px grid.
    Leave as-is.
  - Maternity set (warm wood browns, pink rope/carpet): wood brown and
    dusty pink are **outside the 32-colour palette** — accepted as
    furniture-material colours, not signal colours. At 0.92 darkness
    they mute to near-steel. If a review finds them loud, quantize
    the maternity set toward the steel/pale-steel ramp; do not
    recolour by hand per sprite.
  - Photo sprites (isometric-ish, saturated reds/oranges, front-facing
    robot 668, side-view wheelchairs): saturated colours are confined
    to ≤16-px shelf clutter / parked props, never to interactables.
    The wheelchairs are side-view in a top-down room — accepted: a
    parked wheelchair reads side-on in real clinics too, and all four
    sit in the wheelchair bay / waiting area, not mid-walkway. The
    isometric bed (650) is placed only as a folded spare in storage
    for the same reason.
  - V2.0 dark-background sheets (617–622) and light-grey labelled
    sheets (610–616): reference only, not imported (§5.2) — no clash
    can occur.
- **No sprite is excluded for colour.** The only exclusions in this
  design are things with no file on disk (§7).

### 5.4 Lighting changes

Medical darkness stays **0.92** (doc 17 §4.2). The existing
`MedicalAtmosphere` lights stay: green pulse (160,88), blue (460,200),
red (594,320). Add **two** `PointLight2D`s (total 5 on screen, under
the ≤12 cap), both static, no flicker:

| Light | Position | Colour / role | Energy | Radius |
|---|---|---|---|---|
| Lab bench | (528,112) | cyan `#3ec6e0` / info | 0.15 | 48 px |
| Operating table | (496,176) | warm white `#e8eef7` (not green, §5.3) | 0.12 | 48 px |

The surgical-light decor (`MedOpLight`) is visual only; the table's
light above is the real one. Monitor screens (vitals, ECG, console)
keep their existing emissive treatment (depth 2050 per doc 17). The
red emergency light stays the room's only red light source. No light
is added to the pharmacy, storage, or physio corner — they stay dark
until the flashlight finds them (tutorial: the flashlight is the
discovery tool).

## §6. Gameplay preservation checklist

Checked against `medical_wing.gd`, `scripts/tests/test_runner.gd`
(`test_medical_props_exist` — existence only, positions free except
§6.1; `test_medical_doorways_stay_open`; `test_medical_floor_*` —
920 uniform cells) and `scripts/tests/test_rooms.gd` (spawn (64,256),
target cell local (10,10), `ScannerRobot` (260,120),
`MedBedStandard` (48,56)).

| Item | Status |
|---|---|
| `MedBedStandard` at local (48,56) | **Unmoved.** Row A bed 1. |
| Area console at (120,80), vitals-monitor texture | **Unmoved.** Sits in the ward aisle (rows 4–5) between the two bed rows — reachable from both. Station (760,80) check unaffected. |
| Scanner robot at (260,120); LOS x=260, y120–200 clear | **Clear.** Nearest solids: `MedMealTableV` ends x256 (4 px clear); physio chair (264,216) starts y208 (below the LOS end); nothing intersects the segment. Scanner cell itself (col 16, row 7) is free. |
| Spawn (64,256) | **Unmoved, free.** West exit corridor around it is clear. |
| West exit gap y240–272; south exit gap x288–320 | **Both clear.** No solid in either gap or approach (see below). |
| Entry corridor (y240–272, x0–160) | **Clear.** Nearest props are the row-14 wheelchairs (y224–240, touching the corridor's north edge but not entering it). |
| Nav doorway cells (39,15),(39,16),(58,22),(59,22) (station-global; = local south-gap cells (18,22),(19,22) + the cells just west of the west gap) | **Open.** No prop at local col 0; no prop within 1 cell of local (18,22)/(19,22) — nearest are the physio cabinet (col 19, rows 12–13) and the pharmacy row (row 21, cols ≥22). Props are inflated by 1 cell in the nav grid; the 1-cell buffer is respected everywhere (§6, approach rows). |
| Main circulation 2 tiles wide | E–W corridor rows 15–16 fully clear; ward aisle rows 4–5 fully clear except `MedTrashWard` (col 13, row 5 — row 4 stays free beside it); south area rows 17–19 clear except the waiting wheelchair (col 7, row 17). |
| Nav target cell local (10,10) reachable from spawn | **Yes.** Spawn (4,16) → east on rows 15–16 → north through cols 10–13 (rows 7–14 free there) → (10,10). No new prop touches cols 10–13, rows 7–14. |
| Flashlight pickup `MedFlashlight` (504,292) on the doctor's desk | **Unmoved, reachable.** Approach from the south (row 19, free) or west (col 30, row 18, free). Desk, chair, side table unchanged. |
| Notes: N1-01 (doctor's desk), N1-02 (metal cabinet), N1-03 (patient folder); voice A1-01 (monitor by the bed) | Assigned, no code change: N1-01 `MedNoteDoctor` (520,300) on the desk (unchanged); N1-02 on `MedCabinetWorn` (72,344), the metal storage cabinet; N1-03 on `MedBedside1` (72,56), the patient folder by `MedBedStandard`; A1-01 on `MedMonitorWard1` (40,40), the vitals monitor by the bed (after the circuit is powered, per doc 01). |
| Investigation pickups: "record" (520,320), "supplies" (392,304); return point (120,96) | **Unmoved.** Record: row 20 south of the desk, approached from row 19 (free). Supplies: row 19, approached from row 18/20 (free). Return: aisle col 7 at the top of row 6 — the player stands at (120,88) in the aisle, inside the 22-px trigger radius; the row-B bedside table at (120,104) is inside the radius but is not the standing spot. Doctor's desk and pharmacy are **not moved**, so no pickup coordinate changes. |
| Fuse puzzle (FuseBox, breaker/wire panels, HiddenFuse) | **Untouched — lives in command_center scope.** The room's `MedFusebox` decor (632,60) stays decor. No design change to it. |
| Hiding / cover | Room 1 has no patrol robot and no hide mechanic (doc 01: "robot: none"). Cover is positional only: the scanner looks south down col 16, so every zone except the col-16 strip is outside its cone; tall furniture (CT, lab fridge/cabinet row, pharmacy row, maternity cabinet) breaks lateral sightlines. Do not add hide-in spots — there is nothing to hide from in this room. |
| Floor | Uniform tile (4,0), all 920 cells — **no floor change**. Zone identity comes from furniture, not floor tiles. |
| Named nodes the tests require | All 17 kept: `MedBedStandard`, `MedBedEmpty`, `MedBed3`, `MedExamBed`, `MedBedDisorganized` (moved (192,56)→(144,104)), `MedStretcher`, `MedDeskDoctor`, `MedCabinetOpen`, `MedShelfMedicine`, `MedSink`, `MedFridge`, `MedWheelchair`, `MedFlashlight`, `MedNoteDoctor`, `MedWindowObservation`, `MedCornerSW`, `MedCornerSE`. `test_medical_props_exist` checks existence only. |

## §7. What cannot fit logically (plainly) + options

**Everything that exists as a file fits: 115 of 115 objects placed**
(69 zip PNGs + 46 photos; 0 silently dropped). The things below have
**no file on disk** — they exist only as pixels inside the JPG
screenshots — so they cannot be built from the material supplied, and
are not counted against the 115.

| Cannot fit / cannot build | Why | Options |
|---|---|---|
| **Dental** — 2 teal dental chairs + lamp arm (photos 623, 624) | No dental PNG on disk (zip has no dental files; the chairs exist only in the V2.0 screenshots). | (a) **Leave out (chosen)** — not part of "every sprite" since no file exists. (b) Ask the user for the V2.0 tileset PNGs; if supplied, a 2-chair dental nook would go in the lab corner's east strip (cols 37–38, rows 4–7, currently open) — but that space is the CT approach, so the nook would need the op corner re-planned. (c) Do not fake it with the exam bed — a dental chair is not an exam bed. |
| **Front / reception desk** (photos 619, 621) | No reception-desk file on disk. | (a) **Leave out (chosen)** — the nurse station + waiting wheelchair already cover the "front" function in-fiction. (b) V2.0 tileset, same as dental. |
| **Radiology X-ray table + lead aprons** (photo 625) | No X-ray-table or apron file on disk. | (a) **Leave out (chosen)** — imaging is covered by the CT scanner + ultrasound + radiation sign. (b) V2.0 tileset. Do not relabel `operation_table`: it is the surgical table. |
| **Ambulance bay** (photo 618: ambulances, cones, asphalt) | Exterior scene; cannot fit inside a 40×23 interior room, and no ambulance file exists. | (a) **Leave out (chosen)** — the emergency bay (§4.2) is its interior echo: stretcher + 5 wheelchairs + first-aid wall. (b) Nothing else is honest. |
| **Maternity as a maternity ward** | A birthing suite on a 5-crew station breaks the fiction (crew: Nahid, Parsa, Laila, Kaveh, the technician). | **Repurposed, not dropped (§3.2):** recovery/physio corner. Weakest single repurpose is the birthing rope → "suspension-therapy strap": options are (a) keep as hanging decor (chosen — it is placed, it reads as a strap, it harms nothing), (b) move it to storage as a coiled rope (same file, less visible), (c) omit it — rejected, it would break "every sprite in". |
| **Nursery / kids** (photos 613–614: bassinets, rocking horse, toy box) | No nursery/kids files on disk. | Leave out — same reason as dental. The maternity set does **not** become a nursery: bassinets are not in the files. |
| **ICU** (photo 614: ventilator, dialysis, AED) | No ICU files on disk. | Leave out — the defibrillator + ECG + oxygen already in the room cover the ICU function at this room's scale. |

## §8. Placement totals (for the build check)

| Group | Placed as solid floor props | Placed as decor (incl. stacked on furniture / wall / floor) | Placed from spritesheets | Total |
|---|---|---|---|---|
| Zip PNGs — lab (18) | 8 | 10 | 0 | 18 |
| Zip PNGs — maternity (11) | 6 | 5 | 0 | 11 |
| Zip PNGs — operation (14) | 8 | 6 | 0 | 14 |
| Zip PNGs — room (26) | 15 | 11 | 0 | 26 |
| **Zip subtotal (69)** | **37** | **32** | **0** | **69** |
| Small photos (46) | 9 (4 wheelchairs, sink, oxygen tank, bed, robot, EVA suit) | 37 | 0 | 46 |
| **Grand total** | **46** | **69** | **0** | **115 / 115** |
| Spritesheets (4) | 0 (backup sources only, §5.1) | 0 | 0 | — |
| `.aseprite` (1) | 0 (source file only, §3.3) | 0 | 0 | — |

## §9. Implementation notes (for the builder, not the design)

1. **Files to add (room-owned only):**
   `assets/sprites/medical-wing/telegram/*.png` (69 zip PNGs, copied
   as-is, same filenames) and
   `assets/sprites/medical-wing/telegram-photos/*.png` (46 converted
   PNGs, §5.2). No other room, no shared file, no `develop` change.
   Absolute room separation holds: only
   `scenes/levels/rooms/medical_wing/`,
   `scripts/levels/rooms/medical_wing/`,
   `assets/sprites/medical-wing/`.
2. **Code change (one file):** extend `MED_PROP_PATHS`,
   `MED_SOLID_LAYOUT`, `MED_DECOR_LAYOUT` in
   `scripts/levels/rooms/medical_wing/medical_wing.gd` with the
   entries in §3–§4, using the collision sizes in the tables (not the
   canvas sizes). Add the two `PointLight2D`s of §5.4 to
   `MedicalAtmosphere` (or as siblings with the same positions).
   Add `MedBed4` / `MedBed5` nodes; move `MedBedDisorganized` to
   (144,104). Nothing else moves. Do not touch the fuse puzzle,
   the investigation code, or the floor builder.
3. **New texture keys** must load through `_med_texture()` so a missing
   file degrades to the magenta placeholder instead of crashing.
   Run the import script (§5.2) before the build; verify every
   converted photo at 4×.
4. **Tests to run after building:** `test_runner` (661) +
   `test_rooms` (328) — the binding checks are `test_medical_props_exist`
   (17 named nodes), `test_medical_doorways_stay_open` (cells
   (39,15),(39,16),(58,22),(59,22) global), `test_medical_floor_*`
   (920 uniform cells), `test_rooms` medical-wing standalone (spawn,
   target cell (10,10), `ScannerRobot` (260,120), `MedBedStandard`
   (48,56)). If any fails, the layout — not the test — is wrong.
5. **Review points for the 3 reviews:** (a) bed count 6 vs 4 (§1 —
   row B is cleanly removable); (b) maternity repurpose, especially
   the rope (§7); (c) photo-sprite keying quality at 4× (§5.2) and
   the isometric bed / side-view wheelchairs in situ; (d) theatre
   green vs. "green = safe" (§5.3); (e) whether the room reads
   crowded — if it does, the first things to thin are the stacked
   shelf clutter (§4.1, 16 tiny decors), never the furniture, never
   the circulation.

## §10. زبان — فارسی (دستور کاربر، پیام تلگرام ۲۱۹، ۲۰۲۶-۱۱-۲۴)

> «بازی راهنما و بقیه چیزها فارسی باشن» — راهنمای بازی و بقیه‌ی چیزها
> فارسی باشند.

**قانون:** داخل محدوده‌ی اتاق یک **همه‌ی متن‌های نمایشی فارسی‌اند**.
کنوانسیون قدیمی سند `01-room-medical.md` («متن‌ها به فارسی + پیام‌های
سیستم به انگلیسی») با این دستور **لغو شده** و فقط برای اتاق یک اعتبار
ندارد. نام‌های کلید (`E` ،`Q` ،`Esc`)، نام ایستگاه (`K-17`)، نام
هوش مصنوعی (`NEXUS`) و نماد شیمیایی (`O2`) لاتین می‌مانند — اسم‌اند،
متن نیستند. رقم‌ها لاتین می‌مانند (مطابق رشته‌های فارسی موجود مثل
`%d/3`) و علامت درصد `%` همان است.

محدوده‌ی اتاق یک در این بخش = سکانس آغازین سایدویو
(`scripts/opening/`) + درمانگاه top-down
(`scripts/levels/rooms/medical_wing/` و صحنه‌هایش). شاخه‌ی جاری هنگام
نگارش این بخش `room-1-standalone` است (نه `room-1-matin`؛ شاخه عوض
نشده و عوض نمی‌شود).

### ۱۰.۱ متن‌هایی که همین حالا فارسی‌اند — دست نزن، دوباره ترجمه نکن

| متن | محل | متن فارسی (فعلی، قطعی) |
|---|---|---|
| `area_hint` / `AREA_HINT` | `medical_wing.gd` / `wiring_medical_wing.gd` | «بخش پزشکی — یک ربات اسکنر اینجا نگهبانی می‌دهد؛ در دیدش نمان» |
| پیام کنسول | `medical_wing.gd` (`_add_area_console`) | «گزارش پزشکی: بعد از تمرین شیوع بیماری، این بخش بسته شد. آذوقه کم است.» |
| کپشن مارکر «record» | `MedicalInvestigation` | «یادداشت پزشک» |
| کپشن مارکر «supplies» | `MedicalInvestigation` | «بستهٔ پزشکی» |
| کپشن مارکر بازگشت | `MedicalInvestigation` | «بازگشت به کنسول» |
| اعلان ورود به اتاق (۰/۲) | `MedicalInvestigation._on_room_entered` | «هدف اختیاری: یادداشت و بستهٔ پزشکی را پیدا کن. (%d/2)» |
| اعلان پیدا شدن (۱/۲) | `MedicalInvestigation._on_pickup_entered` | «مورد پیدا شد. برای تکمیل جست‌وجو، مورد دیگر را بیاب. (1/2)» |
| اعلان پیدا شدن (۲/۲) | همان | «هر دو مورد پیدا شد؛ به کنسول پزشکی برگرد.» |
| اعلان تکمیل | `MedicalInvestigation._on_return_entered` | «جست‌وجوی بخش پزشکی کامل شد.» |
| راهنمای مرحله‌ها | `wiring_medical_wing.gd` (`STAGE_HINTS`) | «با E پازل‌ها را حل کن؛ با Q رادار بزن تا چیزهای مخفی را پیدا کنی» / «دکل‌ها را با E روشن کن — هر 3 دکل» / «به فرستنده برو و با E سیگنال اضطراری را بفرست» |
| متن مأموریت | `mission_medical_wing.gd` (`current_text`) | «هدف: وصل کردن برق — پازل‌ها را حل کن (%d/3)» / «هدف: روشن کردن دکل‌ها (%d/3)» / «هدف: ارسال سیگنال اضطراری» / «مأموریت کامل شد!» |
| نام منطقه | `medical_wing.gd` (`area_name`) | «بخش پزشکی» |
| نام آیتم‌ها | `player_medical_wing.gd` (`ITEM_DISPLAY`) | «سلول انرژی» / «باتری» / «فیوز» |

### ۱۰.۲ متن‌های انگلیسی سکانس آغازین — معادل فارسی قطعی (پیاده‌سازی شود)

همه در `scripts/opening/`؛ متن انگلیسی از کد خوانده شده و معادل فارسی
آن دقیقاً همین است که در جدول آمده — سازنده همان را جایگذاری می‌کند،
نه ترجمه‌ی دیگری.

| # | محل در کد | متن انگلیسی فعلی | متن فارسی (قطعی) |
|---|---|---|---|
| 1 | `opening_sequence.gd:165` (`WakeCaption`) | `You wake up in a hospital bed.\nYou don't remember who you are — or how you got here.` | «در یک تخت بیمارستان بیدار می‌شوی.\nیادت نمی‌آید کی هستی — یا چطور به اینجا آمده‌ای.» |
| 2 | `opening_sequence.gd:473` (`ManualHint`) | `[Q]  Press Q to view the emergency manual.` | «[Q] برای دیدن دفترچه‌ی اضطراری Q را بزن.» |
| 3 | `opening_sequence.gd:482` (`PromptLabel`) | `Press E to inspect the emergency power panel.` | «برای بررسی پنل برق اضطراری E را بزن.» |
| 4 | `opening_sequence.gd:201` (`NotificationLabel`) | `Medical Section Power Restored.` | «برق بخش پزشکی وصل شد.» |
| 5 | `opening_sequence.gd:313` (`DiagnosticsLabel`) | `SYS DIAG // O2 98% // PWR NOMINAL` | «عیب‌یابی سیستم // O2 98% // برق عادی» |
| 6 | `emergency_manual.gd` (عنوان) | `EMERGENCY MANUAL  //  K-17` | «دفترچه‌ی اضطراری  //  K-17» |
| 7 | `emergency_manual.gd` (`MANUAL_TEXT`) | متن کامل پروتکل — رجوع به ۱۰٫۳ | متن کامل فارسی ۱۰٫۳ |
| 8 | `emergency_manual.gd:35` (برچسب دیاگرام) | `DAMAGED CABLE` | «کابل آسیب‌دیده» |
| 9 | `emergency_manual.gd:113` (پاصفحه) | `Press Q or Escape to close` | «برای بستن Q یا Escape را بزن» |
| 10 | `circuit_puzzle_ui.gd:150` (عنوان) | `EMERGENCY POWER PANEL  //  CIRCUIT REPAIR` | «پنل برق اضطراری  //  تعمیر مدار» |
| 11 | `circuit_puzzle_ui.gd:156` (راهنما) | `Click a wire to rotate it. Connect the source to the output through the fuse.` | «روی یک سیم کلیک کن تا بچرخد. منبع را از راه فیوز به خروجی وصل کن.» |
| 12 | `circuit_puzzle_ui.gd:177` (وضعیت) | `CIRCUIT INCOMPLETE` | «مدار ناقص است» |
| 13 | `circuit_puzzle_ui.gd:278` (وضعیت) | `CIRCUIT COMPLETE  —  POWER FLOWING` | «مدار کامل شد — برق جاری است» |
| 14 | `circuit_puzzle_ui.gd:183` (دکمه) | `Close  [Esc]` | «بستن  [Esc]» |
| 15 | `power_panel.gd:54` (وضعیت) | `POWER FAILURE` | «قطع برق» |
| 16 | `power_panel.gd:120` (وضعیت) | `EMERGENCY POWER RESTORED` | «برق اضطراری وصل شد» |

### ۱۰.۳ متن کامل دفترچه‌ی اضطراری (جایگزین `MANUAL_TEXT`)

عنوان: «پروتکل بازیابی برق اضطراری»

> در صورت قطع بحرانی برق، سیستم برق پشتیبان اضطراری سفینه به‌صورت
> خودکار فعال می‌شود.
>
> اما بار ناگهانی و فشار الکتریکی ممکن است باعث پاره‌شدن یا جدا شدن
> کابل‌ها شود.
>
> ممکن است منبع برق اضطراری سالم باشد، اما اتصالات آسیب‌دیده مانع
> رسیدن برق به بخش‌های مختلف سفینه شوند.
>
> پنل توزیع برق اضطراری را بررسی کن، اتصالات آسیب‌دیده را پیدا کن و
> مدار را وصل کن تا برق به این بخش برگردد.
>
> هشدار: تا وقتی همه‌ی اتصالات لازم وصل نشده‌اند، سیستم را فعال نکن.

ساختار (تیتر + ۴ پاراگراف + هشدار) دقیقاً مثل متن انگلیسی است؛ فقط
زبان عوض شده. دیاگرام مدار (باتری ← کابل پاره ← فیوز ← لامپ) بدون
تغییر می‌ماند؛ فقط برچسبش فارسی می‌شود (ردیف ۸ جدول ۱۰٫۲).

### ۱۰.۴ کارت پایان سکانس آغازین

متن انگلیسی از دستور کاربر: `END OF OPENING SEQUENCE / Press any key
to exit` — معادل فارسی قطعی:

> «پایان سکانس آغازین»
> «برای خروج هر کلیدی را بزن»

**هشدار راستی‌آزمایی (خوانده‌شده از کد، ۲۰۲۶-۱۱-۲۴):** این کارت در
شاخه‌ی جاری (`room-1-standalone`) در کد وجود ندارد —
`opening_sequence.gd` بعد از حل معما مستقیم فید می‌کند و صحنه را به
`res://scenes/levels/rooms/medical_wing/play_medical_wing.tscn`
عوض می‌کند؛ هیچ برچسب پایانی‌ای در `scripts/opening/` نیست. سازنده
باید اول پیدا کند کارت کجاست (احتمالاً در شاخه‌ی `room-1-matin` یا در
جریان رندر/شات) و متن فارسی بالا را همان‌جا اعمال کند؛ اگر کارتی
وجود ندارد، کارت تازه ساخته نمی‌شود — این بخش فقط ترجمه‌ی متن است،
نه دستور ساخت کارت.

### ۱۰.۵ متن مانیتور کنار تخت (داستان سند ۰۱، هنوز در کد نیست)

سند `01-room-medical.md` §۲ روی مانیتور کنار تخت می‌نویسد
`QUARANTINE MODE — MAIN POWER OFFLINE`. این رشته در کد این شاخه نیست
(جست‌وجو: هیچ `QUARANTINE` در کد بازی نیست)؛ وقتی مانیتور پیاده شد،
متن آن این است:

> «حالت قرنطینه — برق اصلی قطع است»

یادداشت‌های N1-01 تا N1-03 و ویس A1-01 در سند ۰۱ از اول فارسی‌اند و
تغییری نمی‌کنند.

### ۱۰.۶ نکته‌ی فنی: فونت و چیدمان

- رشته‌های فارسی اتاق یک (مأموریت، راهنما، اعلان‌ها) همین حالا با فونت
  فارسی رندر می‌شوند (تست `test_persian_font_file` در مجموعه‌ی تست).
  برچسب‌های سکانس آغازین (`WakeCaption` ،`ManualHint` ،`PromptLabel`،
  `NotificationLabel` ،`DiagnosticsLabel` و همه‌ی لیبل‌های
  `EmergencyManual` / `CircuitPuzzleUI` / `PowerPanel`) باید به **همان
  فونت فارسی** وصل شوند — فونت پیش‌فرض/بیت‌مپ انگلیسی حروف فارسی را
  نشان نمی‌دهد.
- دفترچه‌ی اضطراری طولانی‌ترین متن فارسی بازی است؛ در بازبینی اول
  شکل حروف (چسبان‌بودن) و راست‌به‌چپ بودن پاراگراف‌ها در
  `EmergencyManual` چشمی چک شود. اگر موتور حروف را جدا نشان داد،
  این یک مانع ساخت (build blocker) است و باید گزارش شود، نه اینکه
  متن به انگلیسی برگردد.

### ۱۰.۷ خارج از محدوده — دست نزن (برای این‌ها متن فارسی پیشنهاد نمی‌شود)

- منوی اصلی، منوی توقف، صفحه‌ی پیروزی/باخت، صفحه‌ی تنظیمات و صفحه‌ی
  راهنمای سراسری (`scripts/ui/`) — مشترک بین همه‌ی اتاق‌ها.
- HUD مشترک (نوار باتری، نشانگر رادار، بنر هدف سراسری) و مأموریت
  سطح (`level_01` / `level_wiring`) — نسخه‌ی کپی اتاق یک در ۱۰٫۱
  فارسی است و همان می‌ماند؛ اصل مشترک دست نمی‌خورد.
- معمای جعبه‌ی فیوز اتاق فرماندهی (`FuseBox`، پنل‌های breaker/wire،
  `HiddenFuse` و پیام‌هایش مثل `FUSE_BOX: 0/3` و `OVERLOAD`) — در
  محدوده‌ی `command_center` است، نه اتاق یک (§6).
- متن‌های اتاق‌های ۲ تا ۵ و راهروها.
- کامنت‌های کد، نام گره‌ها، لاگ‌ها و متن‌های تست — متن نمایشی نیستند.
