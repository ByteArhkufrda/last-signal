# Room 1 — Telegram hospital/clinic assets inventory

Source: files the user sent via Telegram, catalogued 2026-11-24 (visually inspected).
No game code, scene, or repo file was changed. Nothing committed.

- Zip source (already extracted): `~/workspace/telegram-bot/media/topdown_hospital_Assets/topdown_hospital_Assets/`
- Photos: `~/workspace/telegram-bot/media/287167607.jpg` … `287167671.jpg`
- Branch at time of writing: `room-1-matin` (not switched, nothing committed)

## 1. Totals

| Group | Count |
|---|---|
| Zip PNGs in `Pngs/` | 69 |
| — lab | 18 |
| — maternity | 11 |
| — operation | 14 |
| — room (ward) | 26 |
| `.aseprite` file in `Pngs/` | 1 (`operation_ecg_table.aseprite`, 720 B — source for the ECG table; not a PNG, not measured as an image) |
| Spritesheets in `Spritesheets/` | 4 (all 128×128) |
| `README.txt` | 1 (licence/usage — see §2) |
| Large photos 287167607–625 | 19 |
| Small photos 287167626–671 (101×101 thumbnails) | 46 |
| **Total files catalogued** | **140** (69 PNG + 1 aseprite + 4 spritesheets + 1 README + 65 photos) |

> Correction 2026-11-24 (design pass): the first version of this file said 70 PNGs /
> room 27 / 141 total. Recounted against the filesystem (`ls Pngs/*.png` = 69;
> per-folder: lab 18, maternity 11, operation 14, room 26) — the `room_*` table
> itself only ever listed 26 rows, and the zone-counts line double-counted
> `room_pharmacy_shelf.png` (once under "beds ward 26", once under "pharmacy 1").
> Correct: 69 PNGs, 140 files total.

Style note: the zip pack is one consistent 16-bit top-down pixel style (mostly 16×16 tiles, some
multi-tile pieces). The photos mix **two different packs**: (a) a labelled light-grey-background
tileset ("Modern Hospital" style, photos 610–616, with text labels under every sprite), and
(b) "Modern Hospital V2.0 / Modern Hospital & Clinic Tileset 16x16" on a dark background
(photos 617–625, with on-image titles). The 46 small photos are a **third, different style**:
isometric-ish single icons on a black background. The three styles do **not** match each other
or the zip pack — do not mix them in one room without rework.

### Licence (from zip `README.txt`, "Top Down Hospital")

Free to use in personal and commercial projects, game jams, prototypes and educational games;
may be modified and combined with other assets. May NOT be redistributed or sold as-is, claimed
as own work, or included in another asset pack for resale. Credit not required but appreciated.
No licence text was visible in any of the 65 photos — the Modern Hospital V2.0 pack's licence
is **not** established by this inventory.

## 2. Zip PNGs — `Pngs/` (69)

All RGBA. Dimensions and sizes measured with PIL. Zones use the clinic-zone list from the task.

| File | Size px | File size | Zone | Notes |
|---|---|---|---|---|
| `lab_automation_robot.png` | 32×16 | 0.4 KB | lab | Small top-down robot |
| `lab_books.png` | 16×16 | 0.1 KB | lab | Books stack |
| `lab_computer.png` | 16×32 | 0.2 KB | lab | Desktop PC + monitor |
| `lab_large_table.png` | 64×32 | 0.2 KB | lab | Long lab bench |
| `lab_medium_table.png` | 32×16 | 0.2 KB | lab | Lab bench |
| `lab_microscope_h.png` | 16×16 | 0.2 KB | lab | Microscope, horizontal |
| `lab_microscope_v.png` | 16×16 | 0.2 KB | lab | Microscope, vertical |
| `lab_paper_dispenser.png` | 16×16 | 0.2 KB | lab | Wall paper/towel dispenser |
| `lab_refrigerator.png` | 16×32 | 0.2 KB | lab | Tall fridge |
| `lab_sample_centrifuge.png` | 16×16 | 0.3 KB | lab | Centrifuge |
| `lab_sample_vials.png` | 16×16 | 0.2 KB | lab | Vial rack |
| `lab_sink.png` | 32×32 | 0.3 KB | lab | Sink unit |
| `lab_vial_001.png` | 16×16 | 0.1 KB | lab | Single vial |
| `lab_vial_002.png` | 16×16 | 0.1 KB | lab | Single vial |
| `lab_vial_003.png` | 16×16 | 0.1 KB | lab | Single vial |
| `lab_vial_004.png` | 16×16 | 0.1 KB | lab | Single vial |
| `lab_wooden_cabinet.png` | 32×32 | 0.3 KB | lab | Wooden cabinet |
| `lab_wooden_cabinet_full.png` | 32×32 | 0.5 KB | lab | Wooden cabinet, stocked |
| `maternity_ball.png` | 13×12 | 0.2 KB | maternity | Birthing/exercise ball |
| `maternity_bed.png` | 27×35 | 0.5 KB | maternity | Birthing bed |
| `maternity_birthing_rope.png` | 12×49 | 0.3 KB | maternity | Hanging birthing rope |
| `maternity_carpet.png` | 36×18 | 0.4 KB | maternity | Rug/carpet |
| `maternity_chair.png` | 16×20 | 0.3 KB | maternity | Chair |
| `maternity_cottons.png` | 9×9 | 0.2 KB | maternity | Cotton balls |
| `maternity_light.png` | 19×34 | 0.3 KB | maternity | Floor lamp |
| `maternity_table.png` | 13×13 | 0.2 KB | maternity | Small table |
| `maternity_towel_01.png` | 8×7 | 0.1 KB | maternity | Towel |
| `maternity_towel_02.png` | 8×7 | 0.1 KB | maternity | Towel |
| `maternity_work_cabinet.png` | 16×36 | 0.2 KB | maternity | Tall work cabinet |
| `operation_accessories_table.png` | 16×16 | 0.2 KB | operation | Instrument table |
| `operation_accessories_table_full.png` | 16×16 | 0.3 KB | operation | Instrument table, stocked |
| `operation_console_computer.png` | 32×16 | 0.3 KB | operation | Console computer |
| `operation_console_full.png` | 32×32 | 0.4 KB | operation | Console, complete |
| `operation_console_table.png` | 32×16 | 0.2 KB | operation | Console table |
| `operation_ct_scanner.png` | 64×80 | 1.1 KB | operation | CT scanner (largest zip PNG) |
| `operation_ecg_full.png` | 32×32 | 0.5 KB | operation | ECG unit, complete |
| `operation_ecg_screen.png` | 16×16 | 0.2 KB | operation | ECG screen only |
| `operation_light.png` | 32×32 | 0.5 KB | operation | Surgical light |
| `operation_radiation_sign.png` | 16×16 | 0.2 KB | operation | Radiation warning sign |
| `operation_scalpel_01.png` | 16×16 | 0.1 KB | operation | Scalpel |
| `operation_scalpel_02.png` | 16×16 | 0.1 KB | operation | Scalpel |
| `operation_table.png` | 32×48 | 0.4 KB | operation | Operating table |
| `operation_ultrasound_machine.png` | 32×32 | 0.5 KB | operation | Ultrasound machine |
| `room_anatomy_poster.png` | 16×16 | 0.2 KB | beds ward | Anatomy poster |
| `room_armchair.png` | 16×32 | 0.3 KB | beds ward | Armchair |
| `room_bed_h.png` | 32×32 | 0.3 KB | beds ward | Bed, horizontal |
| `room_bed_meal.png` | 32×32 | 0.6 KB | beds ward | Bed with meal tray |
| `room_bed_v.png` | 16×32 | 0.4 KB | beds ward | Bed, vertical |
| `room_bedside_table.png` | 16×16 | 0.2 KB | beds ward | Bedside table |
| `room_biohazard_bin.png` | 16×16 | 0.2 KB | beds ward | Biohazard bin |
| `room_biohazard_bin_y.png` | 16×16 | 0.2 KB | beds ward | Biohazard bin, yellow variant |
| `room_cabinet.png` | 16×32 | 0.2 KB | beds ward | Cabinet |
| `room_ecg_cart.png` | 16×32 | 0.3 KB | beds ward | ECG cart |
| `room_ecg_screen.png` | 16×16 | 0.2 KB | beds ward | ECG screen |
| `room_flower.png` | 16×16 | 0.3 KB | beds ward | Flower / small plant |
| `room_hand_sanitizer.png` | 16×16 | 0.1 KB | beds ward | Hand-sanitizer bottle |
| `room_iv_stand_b.png` | 16×32 | 0.5 KB | beds ward | IV stand, blue |
| `room_iv_stand_g.png` | 16×32 | 0.4 KB | beds ward | IV stand, green |
| `room_iv_stand_w.png` | 16×32 | 0.4 KB | beds ward | IV stand, white |
| `room_meal_tray.png` | 16×16 | 0.1 KB | beds ward | Meal tray |
| `room_pear.png` | 16×16 | 0.1 KB | beds ward | Pear (fruit) |
| `room_pharmacy_shelf.png` | 16×16 | 0.2 KB | pharmacy | Pharmacy shelf |
| `room_pills_01.png` | 16×16 | 0.2 KB | pharmacy | Pills |
| `room_pills_02.png` | 16×16 | 0.1 KB | pharmacy | Pills |
| `room_soup.png` | 16×16 | 0.1 KB | beds ward | Soup bowl |
| `room_table_meal_bed.png` | 16×16 | 0.2 KB | beds ward | Over-bed meal table |
| `room_table_meal_h.png` | 16×16 | 0.3 KB | beds ward | Meal table, horizontal |
| `room_table_meal_v.png` | 16×32 | 0.3 KB | beds ward | Meal table, vertical |
| `room_trash_bin.png` | 16×16 | 0.2 KB | beds ward | Trash bin |

Zone counts in the zip: lab 18, maternity 11, operation 14, room 26
(of the 26 `room_*` files, 23 are ward furniture and 3 are the pharmacy family:
`room_pharmacy_shelf.png`, `room_pills_01.png`, `room_pills_02.png`).
No zip PNGs for: exam, emergency, doctor office, nurse station, entrance/corridor,
storage, dental, radiology (the CT scanner is filed under operation here, but it is imaging
equipment), kids/nursery, front/reception.

## 3. Spritesheets — `Spritesheets/` (4)

All 128×128 RGBA. Contents verified visually (upscaled view); individual sprites inside the
sheets are **not** separately catalogued — the sheets largely duplicate the `Pngs/` files above.

| File | Size px | File size | Contents (visual check) |
|---|---|---|---|
| `spritesheet_hospital_01.png` | 128×128 | 4.5 KB | Ward set: beds (h/v, with meal tray), IV stands, biohazard bins, cabinet, bedside tables, ECG cart/screen, flower, anatomy poster, first-aid box, meal tables — i.e. the `room_*` PNGs assembled |
| `spritesheet_hospital_02.png` | 128×128 | 3.9 KB | Operation/imaging set: operating table, surgical light, CT scanner (large), consoles, ECG units, radiation sign — the `operation_*` PNGs assembled |
| `spritesheet_hospital_lab.png` | 128×128 | 2.6 KB | Lab set: fridge, computers, microscopes, centrifuge, sink, vials, wooden cabinets, large/medium tables — the `lab_*` PNGs assembled |
| `spritesheet_hospital_maternity.png` | 128×128 | 2.6 KB | Maternity set: chair, lamp, carpet, birthing rope, ball, cottons, towels, table — the `maternity_*` PNGs assembled (sparser sheet, much empty space) |

## 4. Large photos 287167607–625 (19)

Type: **S** = sample map / scene, **T** = tileset / labelled sprite sheet, **P** = promo/prop sheet.
All 19 were viewed individually.

### Sample maps (S) — layout references for the designer

**607 — Ward sample map (S, 790×1000).** Single patient room, one door at bottom centre.
Two beds: one vertical bed top-centre with a meal tray and an ECG/monitor cabinet behind it,
one horizontal bed mid-left with an IV stand. Two blue armchairs flank the top bed; a bedside
table with orange flowers sits between the right chair and the bed. Right wall: tall cabinet
with bottles on top and a red biohazard bin beside it. Wall posters (anatomy + green-cross sign)
top-left, hand-sanitizer dispenser top-right. Light-blue tiled floor, cream/blue walls.

**608 — Lab sample map (S, 790×1000).** Single lab room, one door at bottom centre, green walls.
Back wall (left→right): sink unit, computer desk, tall fridge, wooden cabinet with books/bottles.
Centre: one long lab bench with microscope, test-tube rack, centrifuge and a second computer;
three blue stools around it (one left, two below). Paper dispenser on the back wall above the sink.
Same room shell as 607, different furniture/wall colour — a good template for re-skinning rooms.

**609 — Operating-theatre sample scene (S, 794×577).** Open floor, no walls/door (a vignette, not
a room). Centre: green operating table under a twin surgical light; a surgeon in green scrubs
stands behind it. Around it: anaesthesia machine (left), ECG/vitals monitor on a stand (right),
a second monitor on a pole (far left), a stool and a small instrument table. Two characters at
the edges (patient/visitor bottom-left, nurse bottom-right with a trolley). Note: different art
style from the zip and from the labelled sheets — greener palette, larger characters.

**618 — Full hospital sample map (S, 794×446).** "WARD, RESTROOMS, ELEVATOR & AMBULANCE BAY".
Top strip: corridor with benches, plants, signs and a reception-style counter. Middle-left: two
identical restroom/ward rooms (green curtains, sinks, toilets) plus a small ward with beds.
Middle-right: **Emergency / ambulance bay** — red-brick exterior, "EMERGENCY" sign, two ambulances
parked on asphalt with dashed lane markings, traffic cones, a wheelchair and a stretcher.
Bottom strip: pharmacy shelves and counters. Best single reference for how the zones connect
(corridor → rooms → emergency exterior).

**621 — Full hospital sample map (S, 794×446).** "MODERN HOSPITAL & CLINIC TILESET 16X16 —
RECEPTION, PHARMACY, EXAM ROOM, OPERATING THEATRE — SAMPLE MAP". Top row (left→right): waiting
area with blue chairs and vending machines; **Reception** (wood floor, desk, office chairs);
**Pharmacy** (green chequered floor, medicine shelves, counter); exam room (bed, cabinets).
Middle: a long corridor with benches, signs, plants and a wheelchair. Bottom row: operating
theatre (beds, curtains, monitors) and restrooms, with the Emergency/ambulance bay at bottom-right
(same art as 618). The most complete multi-zone layout in the set — use as the master reference.

**623 — Dental sample map, close-up (S, 794×446).** "DENTAL — CHAIRS, LAMP, CABINETS, POSTER",
tagged "NEW IN V2.0". One room, mint-green walls: two teal dental chairs side by side, each
with an overhead lamp arm; a small blue stool below the left chair; wall cabinets and a tooth
poster along the top wall. No door visible in the crop. Minimal, clean two-chair layout.

**624 — V2.0 sample map: Radiology / Maternity / Dental wing (S, 794×446).** "V2.0 SAMPLE MAP —
RADIOLOGY, MATERNITY, DENTAL WING", "INCLUDED AS A TILED .TMX + PNG". Three rooms over one
corridor. Left — **Radiology**: CT/MRI scanner, X-ray table, monitor, lead-apron rack, radiation
sign. Centre — **Maternity**: blue-tiled floor, three bassinets/incubators along the top wall,
a changing table and a cot at the bottom, clock and pink sign on the wall. Right — **Dental**:
same two teal chairs as 623. Corridor below with bench, vending machine, wheelchair, plant and
signs; each room has its own door to the corridor. **The** reference for the three new V2.0 wings.

**625 — Radiology sample map, close-up (S, 794×446).** "RADIOLOGY — MRI, CT, X-RAY TABLE, LEAD
APRONS", "NEW IN V2.0". Left room: large CT scanner on the left wall, MRI ring + table centre,
X-ray table bottom-right, ECG monitor and lead-apron rack on the right wall, radiation and
X-ray signs on the top wall. Right room (partially cropped): maternity, blue tiles, bassinets
along the top wall. Door at bottom centre of the radiology room. Use with 624 for the radiology
room's exact furniture placement.

### Tilesets / labelled sheets / prop sheets (T/P)

| Photo | Size px | Type | What it is |
|---|---|---|---|
| 610 | 794×389 | T | "TILES" — floor tiles (brick, tile, carpet, checker), wall caps, and 4 wall styles: HOSP, SCRUB, TILE, WOOD (each with windows, double doors, lockers). The wall/floor kit for building rooms. |
| 611 | 794×584 | T | Labelled sheet: THEATRE CONT. (surgical lights), WALL (alarm beacon, BP cuff, call light/panel, clock, gas outlets, gel dispenser, info/notice boards, pictograms, EXIT/ICU/LAB/PHARMACY/THEATRE/WARD signs, X-ray sign, sink, TV, whiteboard), WARD (balloons, beds in 4 colours with/without patient, bedside tables, cots, curtains in 3 colours, flowers, folding screens, IV stands, laundry hamper, overbed table, recliners, visitor chairs, vitals monitor, wardrobes). |
| 612 | 794×621 | T | Labelled sheet: PHARMACY (counter, glass cabinet, 3 medicine shelves, wide shelf, vaccine fridge), SMALL (~50 items: apple, bandage, blister pack, blood bag, books, cane, charts, clipboard, coffee, crutches, first-aid kit, flasks, gel bottle, get-well card, glasses, gloves, IV bag, kidney dish, mask box, meal tray, med boxes, papers, pen cup, petri dish, phone, pill bottles, pill organiser, scissors, stethoscope, syringe, teddy, test tubes, thermometer, walking frame, water cup, X-ray film), STAFF (chairs, counters, fridge, lockers, on-call beds, sofas, tables, toaster, wall cupboard), STATION (2 nurse stations), THEATRE (anaesthesia machine, back table, crash cart, glove rack, instrument trolleys, operating table + patient, scrub sink, scrubs shelf, sterilizer, stools). |
| 613 | 794×770 | T | Labelled sheet: IMAGING (CT scanner, lead aprons, MRI scanner, X-ray table), KIDS (blocks, play rug, rocking horse, table, toy box), LAB (benches, centrifuge, fume hood, microscope, tube rack), MEDICAL (biohazard bin, oxygen tanks, sharps bin), NURSERY (baby scale, bassinets blue/pink/yellow, changing table, crib mobile, incubators, rocking chair), OFFICE (chairs, desk, filing cabinets, PC, printer). |
| 614 | 794×770 | T | Labelled sheet: DECOR (bins, plants, sanitiser stand, wet-floor sign), DENTAL (2 chairs), EXAM (exam tables in 3 colours, eye chart, height scale, lightbox, skeleton), FRONT (barrier, bench, coat rack, coffee table, reception desks, donation box, fish tank, kiosk, magazine rack, reception desk, waiting seats/sofas, ticket machine, vending machines, water cooler, wheelchairs in 3 colours), ICU (AED, dialysis, ECG cart, gurneys, pump stands, ultrasound, ventilator). |
| 615 | 794×397 | T | Labelled sheet "OBJECTS CONT.": curtains, defibrillator, dialysis, ECG cart/monitor, fish tank, incubator, IV drip, kiosk, lifts (hosp/scrub/tile/wood, open/closed), lightbox, MRI scanner, patients sleeping, PC, printer, queue display, sink, sliding doors (4 styles, open/closed), swing doors (4 styles, open/closed), TV, ultrasound, vaccine fridge, vending machines, ventilator, water cooler. |
| 616 | 794×589 | T | Labelled sheet: CAST / PATIENT and CAST / SURGEON — full animation frame sets (block, fight idle, get up, hurt, idle, kick, knockdown, knocked out, punch combo, walk; 4 directions each) for a patient character and a surgeon character; plus OBJECTS row (alarm beacon, anaesthesia machine, balloons, call light, centrifuge, clock, coffee machine, crib mobile, CT scanner, curtains). |
| 617 | 794×446 | P | "PROPS: THEATRE, WARD, RESTROOMS, AMBULANCE" (dark background, Modern Hospital V2.0): operating-theatre props, patient-ward beds/cabinets, curtains (3 colours × 6), restroom fixtures, ambulance bay (2 ambulances, signs, cones). A selection — "every prop is in the download". |
| 619 | 794×446 | P | "PROPS: RECEPTION, WAITING ROOM, PHARMACY, EXAM ROOM" (dark background): waiting-room chairs/sofas, vending machines, info desk / nurse station / pharmacy counters (3 styles × 6 pieces), counter-top items, pharmacy shelves/fridges, exam-room props, office & nurse-station props. |
| 620 | 794×446 | T | "TERRAIN TILES — FLOORS, WALLS, WALL TOPS, GLASS, DECALS (16X16, SHADOW VARIANT SHOWN)": 10×3 floors (clean/shadow/scuffed), 18 walls, wall tops (16 masks × 3 tones), glass partitions (clear + frosted), 17 floor decals, plus an in-use example strip. The tile kit for the V2.0 pack. |
| 622 | 794×446 | P | "MODERN HOSPITAL V2.0 — 23 NEW OBJECTS": MRI/CT/X-ray machines, lab benches, nursery/maternity furniture, lockers, cabinets, test-tube racks. "Added below the V1 rows — your maps keep working." Small, sparse sheet; individual objects not legible at this size. |

Sample-map count: **8** (607, 608, 609, 618, 621, 623, 624, 625). Tileset/labelled/prop sheets: **11**
(610–617, 619, 620, 622). Note 609's style differs from the rest; 617–622 are the V2.0 dark-background
pack, 610–616 the light-grey labelled pack, 607–608 the zip pack's own style.

## 5. Small photos 287167626–671 (46)

All 101×101 JPG thumbnails, single icon per photo on a black background, isometric-ish style
(different from both the zip pack and the labelled sheets). Viewed via 6 contact sheets
(8 per sheet, upscaled 4× NEAREST, labelled by update id). "Duplicate of zip?" = **Yes** if the
same object (or same object family, e.g. pill bottle vs. pills) exists as a zip PNG, even in a
different style/angle; **No** = no matching zip PNG. Counts: **Yes 18, No 28**.

| Photo id | Identified sprite | Zone | Duplicate of zip? | Notes |
|---|---|---|---|---|
| 287167626 | Astronaut (white suit, red trim) | misc | No | Character, not a hospital prop; no zip match |
| 287167627 | Wheelchair, dark, side view | entrance/corridor | No | Zip has no wheelchair |
| 287167628 | Pill bottle, red label | pharmacy | Yes — `room_pills_01/02` | Same family, different style |
| 287167629 | Medicine jar, cork lid, red heart on label | pharmacy | Yes — `lab_vial_001–004` | Jar vs. vial; same family |
| 287167630 | Blister pack, green pills (diagonal) | pharmacy | Yes — `room_pills_01/02` | |
| 287167631 | Medicine jar, cork lid, blue liquid | pharmacy | Yes — `lab_vial_001–004` | Variant of 629/647 without heart |
| 287167632 | Syringe, vertical, pink/red | exam | No | Zip has scalpels only, no syringe |
| 287167633 | Adhesive bandage / plaster, diagonal | exam | No | No zip match |
| 287167634 | Roll of bandage / gauze tape, yellow-blue | exam | No | No zip match |
| 287167635 | First-aid kit, white, green cross | emergency | No | No zip match |
| 287167636 | First-aid kit, white, blue cross/stripe | emergency | No | Variant of 635/641/662/663/671 |
| 287167637 | First-aid / medicine box, cardboard, red cross + heart | emergency | No | No zip match |
| 287167638 | IV / fluid bag, orange liquid, 3 drip lines | beds ward | No | Zip has IV *stands* (`room_iv_stand_*`) but no bag |
| 287167639 | Sink / pedestal wash basin with taps | lab | Yes — `lab_sink.png` | Different style (basin vs. unit) |
| 287167640 | Wheelchair, green, side view | entrance/corridor | No | Variant of 627/648/667 |
| 287167641 | First-aid kit, white, red cross | emergency | No | Variant of 635/636/662/663/671 |
| 287167642 | Blood bag, white/red, hanging | emergency | No | No zip match |
| 287167643 | Oxygen tank, teal/green cylinder with hose | emergency | No | No zip match |
| 287167644 | Small green bottle / vial | lab | Yes — `lab_vial_001–004` | Same family; exact contents unclear at 101 px |
| 287167645 | Syringe, diagonal, blue/white | exam | No | Variant of 632/649/657/658 |
| 287167646 | Red-and-white box (medicine/first-aid box?) | pharmacy | No | Identification uncertain — see §7 |
| 287167647 | Medicine jar, white label, red heart, cork lid | pharmacy | Yes — `lab_vial_001–004` | Variant of 629 |
| 287167648 | Wheelchair, dark, side view | entrance/corridor | No | Variant of 627/640/667 |
| 287167649 | Syringe, diagonal, teal/grey | exam | No | Variant of 632/645/657/658 |
| 287167650 | Hospital bed, isometric, white | beds ward | Yes — `room_bed_h.png` / `room_bed_v.png` | Different angle/style |
| 287167651 | Pill bottle, orange cap, orange/white label | pharmacy | Yes — `room_pills_01/02` | |
| 287167652 | Medicine bottle, orange cap, red/white label | pharmacy | Yes — `room_pills_01/02` | |
| 287167653 | Computer monitor, desktop | doctor office | Yes — `lab_computer.png` | Same object, different style |
| 287167654 | Medicine bottle, orange cap, white label | pharmacy | Yes — `room_pills_01/02` | Variant of 651/652 |
| 287167655 | Medicine carton/box, white with red stripe | pharmacy | No | No zip match; ID slightly uncertain |
| 287167656 | Blister pack, pink pills, 6 capsules | pharmacy | Yes — `room_pills_01/02` | Variant of 630 |
| 287167657 | Syringe, diagonal, red/white | exam | No | Variant of 632/645/649/658 |
| 287167658 | Syringe, diagonal, red/blue | exam | No | Variant of 632/645/649/657 |
| 287167659 | Red box/chest with white-cross lid (first-aid box?) | emergency | No | Identification uncertain — see §7 |
| 287167660 | Cylindrical canister/jar, orange, patterned front | pharmacy | No | Unidentified — see §7 |
| 287167661 | Pill bottle, orange, white band label | pharmacy | Yes — `room_pills_01/02` | Variant of 651/652/654 |
| 287167662 | First-aid kit, red, white cross | emergency | No | Variant of 635/636/641/663/671 |
| 287167663 | First-aid kit, white, red cross, red side | emergency | No | Variant of 635/636/641/662/671 |
| 287167664 | Microscope, side view, grey/green | lab | Yes — `lab_microscope_h.png` / `lab_microscope_v.png` | |
| 287167665 | Test tube, vertical, red liquid | lab | Yes — `lab_vial_001–004` / `lab_sample_vials.png` | |
| 287167666 | Green lab flask / bottle | lab | Yes — `lab_vial_001–004` | Same family; flask vs. vial |
| 287167667 | Wheelchair, red, side view | entrance/corridor | No | Variant of 627/640/648 |
| 287167668 | Small white robot, blue eyes, front view | lab | Yes — `lab_automation_robot.png` | Same object type, very different depiction (cute front-facing robot vs. top-down robot) |
| 287167669 | Thermometer, red/white, vertical | exam | No | No zip match |
| 287167670 | Blood / IV bag, red, with tubes | emergency | No | Variant of 642 (and 638) |
| 287167671 | First-aid kit, white, red cross in circle | emergency | No | Variant of 635/636/641/662/663 |

Zone counts among the 46: pharmacy 14, emergency 11, exam 7, lab 6, entrance/corridor 4,
beds ward 2, doctor office 1, misc 1. No maternity, operation, nurse station or storage items
among the small photos.

Repeated variants inside the 46 (same object, several styles): first-aid kits ×6 (635, 636, 641,
662, 663, 671), syringes ×5 (632, 645, 649, 657, 658), pill/medicine bottles ×5 (628, 651, 652,
654, 661), medicine jars ×3 (629, 631, 647), wheelchairs ×4 (627, 640, 648, 667), blood/IV bags
×3 (638, 642, 670), blister packs ×2 (630, 656).

## 6. Duplicates summary (photos vs. zip)

- **18 of 46 small photos** show the same object/family as a zip PNG (different style/angle):
  pill bottles/pills (628, 630, 651, 652, 654, 656, 661), medicine jars/vials (629, 631, 644,
  647, 665, 666), sink (639), bed (650), monitor (653), microscope (664), robot (668).
- **28 of 46 small photos** are unique to the photos — no matching zip PNG. The unique set is
  where the photos add real value: **syringes ×5, first-aid kits ×6, wheelchairs ×4, blood/IV
  bags ×3, bandage/plaster + bandage roll (633, 634), oxygen tank (643), thermometer (669),
  astronaut (626), first-aid/medicine boxes (637, 659), medicine carton (655), canister (660),
  red/white box (646)**.
- The labelled large sheets (611–615) overlap the zip heavily too (beds, IV stands, ECG, CT,
  microscope, centrifuge, sink, etc. all appear in both), but at tileset level, not as 1:1 files.
- Net: the zip covers ward/lab/maternity/operation furniture; the photos add the small
  hand-held medical items (syringe, bandage, blood bag, oxygen tank, thermometer, first-aid kit)
  and wheelchairs that the zip lacks — plus whole extra zones (exam, emergency, pharmacy depth,
  front/reception, dental, radiology, nursery/kids, ICU) visible only in the large sheets.

## 7. Gaps / uncertainties

- **287167646** — red-and-white box: probably a medicine/first-aid box, but the top pattern is
  not legible at 101 px. Recorded as uncertain.
- **287167655** — white box with red stripe: probably a medicine carton; not certain.
- **287167659** — red chest/box with white-cross lid and white dots: probably a first-aid box;
  not certain.
- **287167660** — orange cylindrical canister with a patterned front: **unidentified**. Could be
  a pill jar/canister; the front pattern is not legible. Do not use without a closer look.
- **287167644** — small green bottle: vial family, but exact contents/type unclear at 101 px.
- **287167622** (V2.0 23 new objects) — individual objects are not legible at the sheet's size;
  only the sheet as a whole is catalogued.
- **287167609** — theatre scene is a different art style from everything else; its exact pack
  of origin is not established by the images.
- **Licence** of the Modern Hospital / V2.0 pack in the photos is not established (no licence
  text visible in any photo); only the zip pack's README licence is recorded (§1).
- **No .tmx / .png map files** were in the material catalogued — photo 624 says a Tiled .tmx +
  PNG are "included" in the V2.0 download, but no such files were on disk here; only the
  screenshots. The actual tileset PNGs for the Modern Hospital packs are **not** present as
  separate files — only screenshots of them.
- The `.aseprite` file (`operation_ecg_table.aseprite`, 720 B) was not opened (no Aseprite
  available); its contents are assumed to be the ECG table from its name.
- All 65 photos were readable; nothing was missing or corrupt. Photo dimensions verified with
  PIL (607–608: 790×1000; 609–625: 794 px wide, heights 389–770; 626–671: all 101×101).
