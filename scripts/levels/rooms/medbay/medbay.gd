extends Node2D
## Last Signal — medbay (self-contained room module, 2026-11-28).
##
## Absolute separation: this file shares NOTHING with the other
## rooms. The helpers it needs are all inlined here; its wiring,
## player, mission and robot scenes live as copies in this room's
## own folders. Only sprite/texture art (assets/) is still shared —
## art, not logic. No puzzles: this room has no
## power/analyzer/vault/keycard logic at all — its only gameplay is
## exploring the medbay while staying out of the four patrol robots'
## sight (vision radius 60, spawn at the lobby door).
##
## Layout: the Medbay from SS13 (BoxStation), cut to a 53x41 MAP
## (one cell = 32 px, room 1696x1312). Row 0 of the MAP is north.
## '#' is a metal wall (solid, real SS13 wall art per cell), 'X' is
## void/space (solid, NO visual — the floor sprite already paints it
## near-black, and a metal polygon over it would read as wall),
## '.' is corridor floor and the letters are room floors, all
## walkable: W central medbay, L lobby, A rear medbay, T recovery,
## C chemistry, P pharmacy, V virology, G morgue, Y cryo, S surgery,
## O storage, B rest room, Q psychology, N maintenance.
##
## FAITHFUL REBUILD (2026-11-28): every pixel in this room comes
## from the SS13 repo (S.P.L.U.R.T-tg) — nothing is drawn by hand
## and nothing is a lookalike. The floor is one smooth sprite
## (assets/sprites/medbay/floor_medbay.png), painted tile by tile
## with the SOUTH frame of each cell's real turf icon (turf_map.json
## + turf_icons.json in medbay-work/medbay_godot). Walls are
## per-cell sprites from the real wall/reinforced_wall DMIs, chosen
## by each cell's smoothing junction (wall_sheet.png, 30 frames).
## Every prop sprite is the real icon of its SS13 type path
## (real_sprites.json in medbay-work/medbay_godot). Props come from
## medbay_props.json (453 items; the 196 in PROPS below are the
## room brief's set, placed at their exact SS13 positions).
## Lighting is the station's own: uniform neutral white (1,1,1),
## no ceiling lights, no pools of light — SS13 has no global
## darkness. The two bench props keep the real chair sprite: their
## greyscale bench DMI was not locatable in the repo (see the
## final report). One PROPS row (1328,1136) has no matching SS13
## data entry and was kept as-is with the real glass-table art.
##
## Layer structure: Floor (the Sprite2D named
## "Floor"), Walls_And_Hazards (the StaticBody2D named
## "Walls_medbay"), Props_And_Machines (Node2D, non-solid decor).
## Solid props are DIRECT children of the room (StaticBody2D with a
## 32x32 shape, sprite on top), so prop_solid_rects() can feed the
## nav grid exactly like the walls do. No real TileMapLayer:
## the MAP table below IS the tilemap.
##
## Room edges: the MAP is a cut-out of the station, so its border is
## mostly open corridor (159 walkable border cells). There are no
## exits to other rooms (standalone only; LevelData untouched), so
## doorway_gap_rects() returns one outside seal rect per walkable
## border cell and the launcher seals them — the player can stand on
## the edge cells but cannot walk off the room.
##
## Patrol clearance (corrected 2026-11-28): the first build used a
## 32 px margin around the patrol lines and deleted/moved 33 props
## for it — including the surgery room's ONLY operating table. That
## rule was wrong: the robot body is 12x14, so the physical rule is
## that a patrol line must not intersect a solid rect and must keep
## >=10 px from its edges. All props were restored to their exact
## SS13 positions (see patch_plan.json) and the four patrol routes
## below were re-routed around them instead. The lobby route sits
## 96 px from the spawn (vision is 60) — verified by the 10 s idle
## spawn test. Routes verified clear of walls and solid props.

const TILE_SIZE := 16
const CELL := 32
const WALL_TEXTURE: Texture2D = preload("res://assets/sprites/environment/wall_metal.png")
const FLOOR_MEDBAY_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/floor_medbay.png")
const WALL_SHEET_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/wall_sheet.png")
const OPTABLE_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/optable.png")
const CRYO_CELL_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/cryo_cell.png")
const STASIS_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/stasis.png")
const CHEM_DISPENSER_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/chem_dispenser.png")
const CHEM_MASTER_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/chem_master.png")
const CHEM_HEATER_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/chem_heater.png")
const CHEM_MASS_SPEC_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/chem_mass_spec.png")
const REAGENTGRINDER_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/reagentgrinder.png")
const MORGUE_CONTAINER_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/morgue_container.png")
const TABLE_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/table.png")
const TABLE_GLASS_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/table_glass.png")
const TABLE_REINFORCED_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/table_reinforced.png")
const TABLE_RGLASS_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/table_rglass.png")
const TABLE_WOOD_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/table_wood.png")
const TABLE_FANCY_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/table_fancy.png")
const TABLE_FANCY_BLUE_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/table_fancy_blue.png")
const TABLE_FANCY_RED_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/table_fancy_red.png")
const TABLE_GREYSCALE_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/table_greyscale.png")
const BED_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/bed.png")
const BED_DOUBLE_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/bed_double.png")
const BED_EMERG_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/bed_emerg.png")
const LOCKER_BLUE_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/locker_blue.png")
const LOCKER_CHEM_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/locker_chem.png")
const LOCKER_CMO_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/locker_cmo.png")
const LOCKER_MED_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/locker_med.png")
const LOCKER_PARAMED_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/locker_paramed.png")
const LOCKER_ATMOS_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/locker_atmos.png")
const LOCKER_CAP_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/locker_cap.png")
const LOCKER_CABINET_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/locker_cabinet.png")
const LOCKER_ENG_SECURE_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/locker_eng_secure.png")
const LOCKER_SECURE_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/locker_secure.png")
const SMARTFRIDGE_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/smartfridge.png")
const SMARTFRIDGE_ORGAN_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/smartfridge_organ.png")
const MONITOR_OPERATING_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/monitor_operating.png")
const MONITOR_VITALS_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/monitor_vitals.png")
const DEFIB_UNIT_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/defib_unit.png")
const CHAIR_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/chair.png")
const CHAIR_COMFY_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/chair_comfy.png")
const CHAIR_COMFY_TEAL_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/chair_comfy_teal.png")
const CHAIR_SHUTTLE_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/chair_shuttle.png")
const CHAIR_OFFICE_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/chair_office.png")
const CHAIR_OFFICE_DARK_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/chair_office_dark.png")
const CHAIR_STOOL_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/chair_stool.png")
const SOFA_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/sofa.png")
const SOFA_RIGHT_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/sofa_right.png")
const SINK_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/sink.png")
const SHOWER_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/shower.png")
const TOILET_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/toilet.png")
const IV_DRIP_TEXTURE: Texture2D = preload("res://assets/sprites/medbay/iv_drip.png")

## MAP (medbay_map.txt, 53 cols x 41 rows, copied verbatim):
## '#' metal wall | 'X' void/space (solid) | '.' corridor floor |
## 'W' central medbay | 'L' lobby | 'A' rear medbay | 'T' recovery |
## 'C' chemistry | 'P' pharmacy | 'V' virology | 'G' morgue |
## 'Y' cryo | 'S' surgery | 'O' storage | 'B' rest room |
## 'Q' psychology | 'N' maintenance. One cell is 32 px.
const MAP := [
	".....#........#......................................",
	".....#........#......................................",
	"######........#...########LLLLL###################N##",
	"..............#...P..PP.PLLLLLLL#....#...#GG#GGGG#N..",
	".#####........#....PPPPPPLLLLLLL.....#...#GGGGGG.#N#.",
	"...#.##.......#...PPPPPPPLLLLLLL.........#G.GGGG##N#.",
	"...#..##.####.#...#PPPPPPLLLLLL.#....#...#GGGGGG#NN#.",
	"...#........#.#...#PPPPP#LLLLLLL#....#####GGGGGG#NN#.",
	"...#......#.#.#...#PPPP.##WW#.LL#WWWWWWWWGGGGGGGGNN##",
	".###......#.#.#...##PP.P#WWW##W##WWWWWWWW#########N#.",
	"...##########.#...WWWWWWWWWWWWWWWWWWWWWWW#SSSSSSS#N#.",
	"....#X#.......#...WWWWWWWWW.WWWWWWWWW#WWW#SSSSSSS#N#.",
	"....#X#...........##CC###CC###TTTTT###WWW#SSSSSS.#N##",
	"....#X#.......#...#.CCCCCCC#TTTTTTTTT#WWW##S###S##..#",
	"...##.#.......#...CCCCCCCCC#TTTTTTTTTTWWWWWWWWWWWW...",
	"..##..#########...CCCCCCCCCTTTTTTTTTTTWWWWWWWWWWW#..#",
	"..................CCCCCCCCC.TTTTTTTTTTWWW#OOOOOO##.##",
	"..................CCCCCCCCCTTTTTTTTTTTWWW#OOOOOO#...#",
	"..................#CCCCCCCC#TTT.TTTTT#WWW#OOOOOOO...#",
	"..#####.#####N#...#CCCCCCCC#TTT#TTT###WWW#OOOOOO#..##",
	"..#........NNN#####CCCCCCCC.....YYY.YYWWW#OO.OOO#..#.",
	"..#.......##NNNNNNNCCCCCCCC.....YYYYY#AAA#########.#.",
	"..#.......#NNNNNNN#CCCCCCCC.....YYYYYYAAAAAAA#.BB#.#.",
	"..######N##NNNNNNN#CCCCCCCC#...#YYYYY#AAAAAAABBBB#.##",
	"..NNNNNNNNNNNNNNNN#C##C##C############Q##.AA##BBB#.#.",
	"..########NNNNNNNNNNNNNNNNNNNNNNNN#QQQQQ#AAA#BBBBB.#.",
	"...#.....#####N##################N#QQQQQ##V##BBBB#.#.",
	"...#.....#..............#XXXXXXX#N#QQQQQ#VV.##B###...",
	"...#.....#...............X#####X#N#######VVV#BBBB#.#.",
	".........#...............X#...#XNNN#V.VV#VVV######.#.",
	".........................X....#XNNN#VVVV##V##VVVV#.##",
	".........................X#...#XNNN#VVV##.VVVVVVV#.#.",
	".........#...............X#####X#N##VVVVVVVV#VVVV#.#.",
	"...###...#...............X#...#X#NN#####VVVV.VVVV#.##",
	"...#.....................X....#XNNNNNN#VVVVVVVVVV#.#.",
	"...#.....#...............X#...#X####NN#VVVVVVVVVV#.#.",
	"...#...#####...#.........X#####XNNNNNN#VVVVVVVVVV#.#.",
	"..###.##...#...#.........X#...#X#NN##N#VVVVVVVVVV#.#.",
	".......#...#...#.........X....#X#.....##VV########.#.",
	"...........#...#.........X#...#X...#...####...#....#.",
	"..#........#...#.........X#####X...#......#...#....#.",
]

## Wall type per cell, from the SS13 turf data (turf_map.json):
## 'w' = /turf/closed/wall, 'r' = /turf/closed/wall/r_wall,
## ' ' = not a wall. Picks the wall_sheet.png row (0-14 wall,
## 15-29 reinforced) for each cell's junction sprite.
const WALLTYPE := [
	"     r        r                                      ",
	"     r        r                                      ",
	"rrrrrr        r   wwwwwwww     wwwwwwwwwwwwwwwwwww ww",
	"              r                 w    w   w  w    w   ",
	" rrrrr        r                      w   w       w w ",
	"   r rr       r                          w      ww w ",
	"   r  rr rrrr r   w             w    w   w      w  w ",
	"   r        w w   w     w       w    wwwww      w  w ",
	"   r      w w w   w     ww  w   w                  rw",
	" rrr      w w w   ww    w   ww ww        wwwwwwwww r ",
	"   rrrrrrrrrr r                          w       w r ",
	"    w w       r                      w   w       w r ",
	"    w w           rr  rrr  www     www   w       w rr",
	"    w w       r   r        r         w   ww www ww  r",
	"   ww w       r            r                         ",
	"  ww  rrrrrrrrr                                  w  r",
	"                                         w      ww wr",
	"                                         w      r   r",
	"                  r        r         w   w          r",
	"  wwwww wwwww w   r        r   r   www   w      r  rr",
	"  w           wwwwr                      w      r  r ",
	"  w       ww                         w   wwwwwwwww r ",
	"  w       w       r                          w   w r ",
	"  wwwwww ww       r        r   r     w           w rr",
	"                  r rr rr rrrrrrwwwwww ww   ww   w r ",
	"  wrrrrrrr                        w     w   w      r ",
	"   r     rrrrr rrrrrrrrrrwwwwwwww w     ww ww    w r ",
	"   r     w              r       w w     r   rw www   ",
	"   r     w                rrrrr w wrrrrrr   r    w r ",
	"         w                r   r    r    r   rrrrrr r ",
	"                              r    r    rr rr    r rr",
	"                          r   r    r   wr        r r ",
	"         w                rrrrr w wr        r    r r ",
	"   rww   w                r   r w  rrrrw         r rw",
	"   r                          r       r          r r ",
	"   r     w                r   r wwww  r          r r ",
	"   r   rrrrr   w          rrrrr       r          r r ",
	"  wrr rr   r   w          r   r w  ww r          r r ",
	"       w   r   w              r w     rr  rrrrrrrr r ",
	"           r   w          r   r    w   rrrr   w    r ",
	"  w        r   w          rrrrr    w      w   w    r ",
]

## Props ([sprite key, px, py, solid], 196 placed at their exact
## SS13 positions from medbay_props.json — restored 2026-11-28
## after the first build's 32 px clearance rule wrongly deleted
## 8 and moved 18 of them (including the surgery optable; see
## patch_plan.json for the full list, plus two tables the restore
## itself mis-relocated and one it dropped — fixed after the
## first test run: 3592 passed / 2 failed on the double-solid
## cells). Regenerated 2026-11-28 from medbay_props.json with the
## real SS13 sprite key per type (regen_props.py); positions and
## solid flags are unchanged. Positions are pixel centers.
## Solid props get a 32x32 collision rect at the cell center.
## Sprite sizes are the real SS13 icon sizes: 32x32, except
## cryo_cell 32x64 (sprite offset y -16 so its bottom edge sits on
## the cell's bottom edge, collision stays 32x32 at the center),
## all ten lockers 32x48 (offset y -8, bottom edge on the cell's
## bottom edge) and the three fancy tables 32x34 (offset y -1).
## Lockers are keyed by their real SS13 subtype (med_secure,
## chem_secure, cmo, med, paramed_secure, atmos, cap, cabinet,
## eng_secure, secure). vitals_reader monitors are solid here
## although SS13 marks them non-solid — the brief lists them under
## the solid monitors. defib_unit is wall decor (non-solid): all
## five sit against a wall cell. The mass-spec machine keeps its
## real HPLC art under chem_mass_spec (it used to wear the
## chem_heater key).
const PROPS := [
	["chair_comfy", 304, 16, false],
	["chair_comfy", 368, 16, false],
	["table", 144, 48, true],
	["chair", 240, 48, false],
	["chair_shuttle", 272, 112, false],
	["chem_heater", 720, 112, true],
	["table", 816, 112, true],
	["chair", 848, 112, false],
	["chair", 880, 112, false],
	["table_glass", 1136, 112, true],
	["bed_double", 1296, 112, true],
	["table_reinforced", 1360, 112, true],
	["monitor_operating", 1392, 112, true],
	["morgue_container", 1488, 112, true],
	["morgue_container", 1520, 112, true],
	["morgue_container", 1552, 112, true],
	["chair_office_dark", 240, 144, false],
	["table_reinforced", 592, 144, true],
	["chair_office", 624, 144, false],
	["chair_office", 752, 144, false],
	["table_reinforced", 784, 144, true],
	["chair_office", 1104, 144, false],
	["table_glass", 1136, 144, true],
	["chair_office", 1168, 144, false],
	["chair_comfy_teal", 1232, 144, false],
	["optable", 1360, 144, true],
	["table_reinforced", 1424, 144, true],
	["reagentgrinder", 624, 176, true],
	["chem_dispenser", 752, 176, true],
	["smartfridge", 784, 176, true],
	["smartfridge_organ", 1360, 176, true],
	["bed_double", 144, 208, true],
	["locker_chem", 624, 208, true],
	["table_reinforced", 912, 208, true],
	["table_reinforced", 944, 208, true],
	["table_reinforced", 976, 208, true],
	["table_reinforced", 1008, 208, true],
	["locker_cmo", 1296, 208, true],
	["sink", 368, 240, false],
	["chem_heater", 752, 240, true],
	["table_reinforced", 912, 240, true],
	["chair_office", 944, 240, false],
	["chair_office", 1008, 240, false],
	["iv_drip", 1360, 240, false],
	["bed_emerg", 1360, 240, true],
	["morgue_container", 1424, 240, true],
	["morgue_container", 1456, 240, true],
	["morgue_container", 1488, 240, true],
	["morgue_container", 1520, 240, true],
	["chair_comfy", 176, 272, false],
	["toilet", 368, 272, false],
	["chem_master", 688, 272, true],
	["chair_office", 720, 272, false],
	["chem_dispenser", 752, 272, true],
	["table_glass", 1072, 272, true],
	["locker_cap", 272, 304, true],
	["shower", 368, 304, false],
	["smartfridge", 688, 304, true],
	["table_reinforced", 720, 304, true],
	["iv_drip", 816, 304, false],
	["sink", 1072, 304, false],
	["morgue_container", 1680, 304, true],
	["iv_drip", 1296, 336, false],
	["monitor_operating", 1360, 336, true],
	["monitor_vitals", 1360, 336, true],
	["defib_unit", 1392, 336, false],
	["optable", 1392, 336, true],
	["locker_blue", 1424, 336, true],
	["locker_blue", 1488, 336, true],
	["optable", 1520, 336, true],
	["defib_unit", 1520, 336, false],
	["monitor_operating", 1552, 336, true],
	["monitor_vitals", 1552, 336, true],
	["table", 112, 368, true],
	["table", 240, 368, true],
	["table", 272, 368, true],
	["table_glass", 1360, 368, true],
	["iv_drip", 1424, 368, false],
	["iv_drip", 1488, 368, false],
	["table_glass", 1552, 368, true],
	["table", 112, 400, true],
	["chair_stool", 272, 400, false],
	["sink", 1360, 400, false],
	["smartfridge_organ", 1456, 400, true],
	["table_glass", 688, 432, true],
	["chem_master", 784, 432, true],
	["chem_dispenser", 816, 432, true],
	["chem_heater", 848, 432, true],
	["monitor_vitals", 912, 432, true],
	["table_glass", 912, 432, true],
	["defib_unit", 944, 432, false],
	["stasis", 944, 432, true],
	["iv_drip", 976, 432, false],
	["iv_drip", 1104, 432, false],
	["defib_unit", 1136, 432, false],
	["stasis", 1136, 432, true],
	["monitor_vitals", 1168, 432, true],
	["table_glass", 1168, 432, true],
	["table_glass", 1296, 432, true],
	["chair_office", 816, 464, false],
	["table_glass", 912, 464, true],
	["table_glass", 1168, 464, true],
	["table_glass", 784, 496, true],
	["table_glass", 816, 496, true],
	["table_glass", 848, 496, true],
	["reagentgrinder", 848, 496, true],
	["smartfridge", 880, 496, true],
	["shower", 1008, 496, false],
	["shower", 1072, 496, false],
	["chair_office", 848, 528, false],
	["table_reinforced", 880, 528, true],
	["table_glass", 1168, 560, true],
	["locker_paramed", 1360, 560, true],
	["table_reinforced", 1424, 560, true],
	["table", 1520, 560, true],
	["iv_drip", 976, 592, false],
	["iv_drip", 1104, 592, false],
	["defib_unit", 1136, 592, false],
	["table_glass", 1168, 592, true],
	["locker_blue", 1360, 592, true],
	["table_glass", 1360, 624, true],
	["table_glass", 1520, 624, true],
	["table_reinforced", 912, 656, true],
	["table_reinforced", 944, 656, true],
	["locker_blue", 976, 656, true],
	["cryo_cell", 1104, 656, true],
	["cryo_cell", 1168, 656, true],
	["table_glass", 1360, 656, true],
	["table_glass", 1520, 656, true],
	["chair_stool", 144, 688, false],
	["table", 112, 720, true],
	["table", 144, 720, true],
	["table_reinforced", 912, 720, true],
	["chair_office", 944, 720, false],
	["table", 1392, 720, true],
	["table", 1424, 720, true],
	["table_glass", 1520, 720, true],
	["table_glass", 1552, 720, true],
	["table_reinforced", 912, 752, true],
	["locker_secure", 1040, 752, true],
	["table_glass", 1552, 752, true],
	["sofa_right", 1168, 816, false],
	["sofa", 1200, 816, false],
	["sofa", 1520, 848, false],
	["sofa_right", 1552, 848, false],
	["chair_office", 1168, 880, false],
	["locker_cabinet", 1264, 880, true],
	["shower", 1328, 912, false],
	["toilet", 1456, 912, false],
	["sink", 1520, 912, false],
	["shower", 1552, 912, false],
	["chair_stool", 1104, 944, false],
	["bed", 1264, 944, true],
	["sink", 1328, 944, false],
	["table", 1104, 976, true],
	["table", 1168, 976, true],
	["chair_stool", 1200, 976, false],
	["table_reinforced", 112, 1008, true],
	["chair", 144, 1008, false],
	["chair_office_dark", 240, 1008, false],
	["table", 336, 1008, true],
	["chair_stool", 1104, 1008, false],
	["table", 1168, 1008, true],
	["table", 144, 1040, true],
	["table", 176, 1040, true],
	["table", 336, 1040, true],
	["table", 1168, 1040, true],
	["reagentgrinder", 1168, 1040, true],
	["table", 336, 1072, true],
	["sink", 1296, 1072, false],
	["smartfridge", 1264, 1104, true],
	["chair_stool", 1328, 1104, false],
	["chair_stool", 1200, 1136, false],
	["table", 1360, 1136, true],
	["table_glass", 1264, 1168, true],
	["chair_office", 1328, 1168, false],
	["bed", 1456, 1168, true],
	["bed", 1552, 1168, true],
	["locker_eng_secure", 304, 1200, true],
	["shower", 400, 1200, false],
	["locker_atmos", 464, 1200, true],
	["table_glass", 1264, 1200, true],
	["locker_atmos", 464, 1232, true],
	["table", 528, 1232, true],
	["locker_med", 1328, 1232, true],
	["table_reinforced", 80, 1264, true],
	["chair", 112, 1264, false],
	["chair_office_dark", 304, 1264, false],
	["shower", 400, 1264, false],
	["locker_atmos", 464, 1264, true],
	["table", 528, 1264, true],
	["table", 208, 1296, true],
	["table", 272, 1296, true],
	["table", 304, 1296, true],
	["table", 336, 1296, true],
]


## Solid prop rects, filled in by _build_props() during _ready
## (the launcher reads them after add_child, so they are ready).
var _prop_solid_rects: Array[Rect2] = []


## Last Signal — Medbay room (medbay), split out 2026-11-28.
## Layout from medbay_map.txt; room is 1696x1312, spawn (848, 80)
## at the lobby door (MAP cell (26, 2), 'L' floor).

func _ready() -> void:
	room_key = "medbay"
	area_name = "بخش پزشکی"
	room_rect = Rect2(0, 0, 1696, 1312)
	room_tile_rect = Rect2i(0, 0, 106, 82)
	area_hint = "بخش پزشکی — Medbay؛ از دید ربات‌های نگهبان دور بمان"
	spawn_point = Vector2(848, 80)
	tint_color = Color(0.5, 0.9, 0.7, 0.07)
	_build_floor_if_standalone()
	_build_wall_rects(wall_rects())
	_build_tint()
	_build_zone()
	_build_lighting_if_standalone()
	_build_props()


## The MAP's wall cells ('#' and 'X') merged into rects (32 px
## cells; same-char runs merge horizontally, then vertically).
func wall_rects() -> Array[Rect2]:
	var runs: Array = []
	for y in range(41):
		var row: String = MAP[y]
		var x := 0
		while x < 53:
			var ch: String = row[x]
			if ch == "#" or ch == "X":
				var x0 := x
				while x < 53 and row[x] == ch:
					x += 1
				runs.append([x0, y, x - x0, 1, ch])
			else:
				x += 1
	var merged := true
	while merged:
		merged = false
		for i in range(runs.size()):
			var done := false
			for j in range(i + 1, runs.size()):
				var a: Array = runs[i]
				var b: Array = runs[j]
				if a[0] == b[0] and a[2] == b[2] and a[4] == b[4] and a[1] + a[3] == b[1]:
					a[3] += b[3]
					runs.remove_at(j)
					merged = true
					done = true
					break
			if done:
				break
	var out: Array[Rect2] = []
	for r in runs:
		out.append(Rect2(r[0] * CELL, r[1] * CELL, r[2] * CELL, r[3] * CELL))
	return out


func blocked_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = wall_rects()
	rects.append_array(prop_solid_rects())
	return rects


func prop_solid_rects() -> Array[Rect2]:
	return _prop_solid_rects


## Patrol routes (pixels, from medbay_robots.json — verified on
## floor, straight lines clear of walls). Order matters: the wiring
## assigns route N to the Nth robot in the room scene, so the
## medbay.tscn robot children are in this same order.
func patrol_routes_local() -> Array:
	return [
		[Vector2(592, 336), Vector2(1296, 336)],
		[Vector2(816, 176), Vector2(1008, 176)],
		[Vector2(1296, 1072), Vector2(1552, 1072)],
		[Vector2(1392, 624), Vector2(1392, 368)],
	]


## First route (back-compat: the old single-loop contract and the
## wiring fallback). The wiring assigns one route per robot.
func patrol_points_local() -> Array[Vector2]:
	return [Vector2(592, 336), Vector2(1296, 336)]


## No exits: the room is standalone-only and LevelData is untouched,
## so there is nowhere to exit to. The open border cells are sealed
## by the launcher instead (see doorway_gap_rects).
func exits() -> Array[Dictionary]:
	return []


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
## BEFORE add_child. Standalone it is still the station offset, for
## the tests that compare the standalone grid with the assembled one.
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

## Border seals the standalone launcher closes with walls: one rect
## just OUTSIDE the room per walkable border cell (computed from
## the MAP, so the list never drifts from it). There are no exits,
## so every rect here is a seal, not a doorway.
func doorway_gap_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for cx in range(53):
		for cy in [0, 40]:
			if MAP[cy][cx] != "#" and MAP[cy][cx] != "X":
				var y := -CELL if cy == 0 else 41 * CELL
				out.append(Rect2(cx * CELL, y, CELL, CELL))
	for cy in range(41):
		for cx in [0, 52]:
			if MAP[cy][cx] != "#" and MAP[cy][cx] != "X":
				var x := -CELL if cx == 0 else 53 * CELL
				out.append(Rect2(x, cy * CELL, CELL, CELL))
	return out

## Build the room's code-built walls as one StaticBody2D named
## "Walls_<room_key>". Each wall cell gets one Sprite2D cut from
## wall_sheet.png — the real SS13 wall/reinforced_wall icon for
## that cell's smoothing junction (see _wall_junction and
## WALLTYPE). Coordinates are LOCAL; the assembler translates them
## to world coordinates when it flattens the room into the level.
## 'X' (void) rects get collision but NO visual: the floor sprite
## already paints them near-black, and a wall sprite over them
## would read as a wall where there is only space.
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
		# One real SS13 wall sprite per '#' cell in this rect
		# (junction from the MAP neighbours, type from WALLTYPE).
		var x0 := int(r.position.x / CELL)
		var y0 := int(r.position.y / CELL)
		var w := int(r.size.x / CELL)
		var h := int(r.size.y / CELL)
		for cy in range(y0, y0 + h):
			for cx in range(x0, x0 + w):
				# Seal rects sit OUTSIDE the MAP (the launcher closes
				# the open borders with them): they get collision
				# only, no wall sprite — guard the MAP lookup.
				if cx < 0 or cy < 0 or cx >= 53 or cy >= 41:
					continue
				if MAP[cy][cx] != "#":
					continue
				var j := _wall_junction(cx, cy)
				var row := j if (WALLTYPE[cy] as String)[cx] == "w" else 15 + j
				var tex := AtlasTexture.new()
				tex.atlas = WALL_SHEET_TEXTURE
				tex.region = Rect2(0, row * CELL, CELL, CELL)
				var spr := Sprite2D.new()
				spr.texture = tex
				spr.position = Vector2(cx * CELL + CELL / 2, cy * CELL + CELL / 2)
				body.add_child(spr)
	return body


## SS13 wall smoothing junction for a wall cell: cardinal bits
## N=1 S=2 E=4 W=8, plus a diagonal bit (NE=16 NW=32 SE=64 SW=128)
## only when both adjacent cardinals are walls too. In this MAP
## only 0-14 occur (walls are one cell thick, so no 2x2 wall block
## ever sets a diagonal bit) — wall_sheet.png holds exactly those
## 15 frames per wall type.
func _wall_junction(cx: int, cy: int) -> int:
	var n := _is_wall_cell(cx, cy - 1)
	var s := _is_wall_cell(cx, cy + 1)
	var e := _is_wall_cell(cx + 1, cy)
	var w := _is_wall_cell(cx - 1, cy)
	var j := 0
	if n:
		j |= 1
	if s:
		j |= 2
	if e:
		j |= 4
	if w:
		j |= 8
	if n and e and _is_wall_cell(cx + 1, cy - 1):
		j |= 16
	if n and w and _is_wall_cell(cx - 1, cy - 1):
		j |= 32
	if s and e and _is_wall_cell(cx + 1, cy + 1):
		j |= 64
	if s and w and _is_wall_cell(cx - 1, cy + 1):
		j |= 128
	return j


func _is_wall_cell(cx: int, cy: int) -> bool:
	if cx < 0 or cy < 0 or cx >= 53 or cy >= 41:
		return false
	return (MAP[cy] as String)[cx] == "#"

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

## Standalone only: one smooth floor sprite for the whole room
## (1696x1312, painted from the MAP — no tile grid). The assembled
## level keeps the shared TileMap floor; this room builds nothing
## there. Named "Floor" (direct child): test_rooms.gd checks the
## standalone floor by that name and type. No space backdrop: the
## floor sprite covers the whole room, void cells included.
func _build_floor_if_standalone() -> void:
	if not standalone:
		return
	var floor_sprite := Sprite2D.new()
	floor_sprite.name = "Floor"
	floor_sprite.texture = FLOOR_MEDBAY_TEXTURE
	floor_sprite.position = room_rect.get_center()
	add_child(floor_sprite)
	# Bottom of the draw order: the room's .tscn children (the four
	# patrol robots) already exist when _ready runs, and an opaque
	# floor added after them paints over them — the robots were
	# invisible in standalone play when the floor is added after them.
	# Everything else _ready adds draws over the floor.
	move_child(floor_sprite, 1)

## Standalone only: the station's own lighting — uniform neutral
## white (1,1,1), no ceiling lights, no pools of light. SS13 has
## no global darkness, so there is nothing to fake with
## PointLight2D. Gated on standalone on purpose: the room is
## flattened into the assembled level, and a CanvasModulate there
## would re-tint the whole station.
func _build_lighting_if_standalone() -> void:
	if not standalone:
		return
	var mod := CanvasModulate.new()
	mod.name = "AmbientBright"
	mod.color = Color(1, 1, 1)
	add_child(mod)


## Props from the PROPS table. Solid props are direct children
## (StaticBody2D, 32x32 collision at the cell center, sprite on
## top) and feed _prop_solid_rects for the nav grid; non-solid
## decor lives under the Props_And_Machines layer. The cryo cell
## sprite is 32x64, so it hangs 16 px above the body center — its
## bottom edge lands on the cell's bottom edge while the collision
## rect stays 32x32 at the center.
func _build_props() -> void:
	var layer := Node2D.new()
	layer.name = "Props_And_Machines"
	add_child(layer)
	for i in range(PROPS.size()):
		var row: Array = PROPS[i]
		var key: String = row[0]
		var pos := Vector2(row[1], row[2])
		var solid: bool = row[3]
		var tex: Texture2D = _texture_for_key(key)
		if solid:
			var body := StaticBody2D.new()
			body.name = "Prop_%s_%d" % [key, i]
			body.position = pos
			body.collision_layer = 1
			body.collision_mask = 0
			var sprite := Sprite2D.new()
			sprite.texture = tex
			if key == "cryo_cell":
				sprite.position = Vector2(0, -16)
			elif key.begins_with("locker_"):
				# 32x48 locker: bottom edge on the cell's bottom edge.
				sprite.position = Vector2(0, -8)
			elif key.begins_with("table_fancy"):
				# 32x34 fancy table: bottom edge on the cell's bottom edge.
				sprite.position = Vector2(0, -1)
			body.add_child(sprite)
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = Vector2(CELL, CELL)
			shape.shape = rect
			body.add_child(shape)
			add_child(body)
			_prop_solid_rects.append(Rect2(pos - Vector2(CELL, CELL) / 2, Vector2(CELL, CELL)))
		else:
			var sprite2 := Sprite2D.new()
			sprite2.name = "Decor_%s_%d" % [key, i]
			sprite2.texture = tex
			sprite2.position = pos
			layer.add_child(sprite2)


func _texture_for_key(key: String) -> Texture2D:
	match key:
		"optable":
			return OPTABLE_TEXTURE
		"cryo_cell":
			return CRYO_CELL_TEXTURE
		"stasis":
			return STASIS_TEXTURE
		"chem_dispenser":
			return CHEM_DISPENSER_TEXTURE
		"chem_master":
			return CHEM_MASTER_TEXTURE
		"chem_heater":
			return CHEM_HEATER_TEXTURE
		"chem_mass_spec":
			return CHEM_MASS_SPEC_TEXTURE
		"reagentgrinder":
			return REAGENTGRINDER_TEXTURE
		"morgue_container":
			return MORGUE_CONTAINER_TEXTURE
		"table":
			return TABLE_TEXTURE
		"table_glass":
			return TABLE_GLASS_TEXTURE
		"table_reinforced":
			return TABLE_REINFORCED_TEXTURE
		"table_rglass":
			return TABLE_RGLASS_TEXTURE
		"table_wood":
			return TABLE_WOOD_TEXTURE
		"table_fancy":
			return TABLE_FANCY_TEXTURE
		"table_fancy_blue":
			return TABLE_FANCY_BLUE_TEXTURE
		"table_fancy_red":
			return TABLE_FANCY_RED_TEXTURE
		"table_greyscale":
			return TABLE_GREYSCALE_TEXTURE
		"bed":
			return BED_TEXTURE
		"bed_double":
			return BED_DOUBLE_TEXTURE
		"bed_emerg":
			return BED_EMERG_TEXTURE
		"locker_blue":
			return LOCKER_BLUE_TEXTURE
		"locker_chem":
			return LOCKER_CHEM_TEXTURE
		"locker_cmo":
			return LOCKER_CMO_TEXTURE
		"locker_med":
			return LOCKER_MED_TEXTURE
		"locker_paramed":
			return LOCKER_PARAMED_TEXTURE
		"locker_atmos":
			return LOCKER_ATMOS_TEXTURE
		"locker_cap":
			return LOCKER_CAP_TEXTURE
		"locker_cabinet":
			return LOCKER_CABINET_TEXTURE
		"locker_eng_secure":
			return LOCKER_ENG_SECURE_TEXTURE
		"locker_secure":
			return LOCKER_SECURE_TEXTURE
		"smartfridge":
			return SMARTFRIDGE_TEXTURE
		"smartfridge_organ":
			return SMARTFRIDGE_ORGAN_TEXTURE
		"monitor_operating":
			return MONITOR_OPERATING_TEXTURE
		"monitor_vitals":
			return MONITOR_VITALS_TEXTURE
		"defib_unit":
			return DEFIB_UNIT_TEXTURE
		"chair":
			return CHAIR_TEXTURE
		"chair_comfy":
			return CHAIR_COMFY_TEXTURE
		"chair_comfy_teal":
			return CHAIR_COMFY_TEAL_TEXTURE
		"chair_shuttle":
			return CHAIR_SHUTTLE_TEXTURE
		"chair_office":
			return CHAIR_OFFICE_TEXTURE
		"chair_office_dark":
			return CHAIR_OFFICE_DARK_TEXTURE
		"chair_stool":
			return CHAIR_STOOL_TEXTURE
		"sofa":
			return SOFA_TEXTURE
		"sofa_right":
			return SOFA_RIGHT_TEXTURE
		"sink":
			return SINK_TEXTURE
		"shower":
			return SHOWER_TEXTURE
		"toilet":
			return TOILET_TEXTURE
		"iv_drip":
			return IV_DRIP_TEXTURE
		_:
			return WALL_TEXTURE


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

## Wall texture for a code-built wall rect, in LOCAL coordinates.
## '#' is the metal wall; 'X' is void and gets no visual at all
## (null) — the floor sprite already paints it near-black.
## Seal rects (outside the MAP) fall through to metal.
func wall_texture_for_local(r: Rect2) -> Texture2D:
	var cx := clampi(int(r.position.x / CELL), 0, 52)
	var cy := clampi(int(r.position.y / CELL), 0, 40)
	var ch: String = MAP[cy][cx]
	if ch == "X":
		return null
	return WALL_TEXTURE
