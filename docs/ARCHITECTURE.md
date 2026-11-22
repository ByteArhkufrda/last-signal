# Last Signal — Architecture

Engine: Godot 4.7.2 (Standard, GDScript) · Platform: Windows · Camera: Top-Down 2D
Layout: split layout (GodotPrompter godot-project-setup).

## Skills applied (Phase 1)
- **awesome-gamedev-agent-skills router** → Godot 4.7; disciplines input-systems,
  camera-systems, level-design; skills `godot-2d-movement`, `godot-tilemap`,
  `godot-gdscript-headless-testing`.
- **godot-tutorials** → pixel art: Nearest texture filter; 2D top-down setup.
- **GodotPrompter** → `player-controller` (accel/friction top-down),
  `input-handling` (custom actions, poll in `_physics_process`),
  `camera-system` (Camera2D child + smoothing + limits),
  `godot-project-setup` (split layout).
- **godot-ai** → editor MCP plugin, copied to `addons/godot_ai/` for the user's
  Windows editor. Needs live Godot 4.7+ editor + `uv`; cannot connect on this
  headless VM. Telemetry is ON by default — opt out with
  `GODOT_AI_DISABLE_TELEMETRY=true`.

## Design decisions (Phase 1)
- **Movement**: accel 1500 / friction 1200, speed 200, `MOTION_MODE_FLOATING`,
  `Input.get_vector("move_left", ...)` in `_physics_process`, `move_and_slide()`.
  Rejected: instant `velocity = input * speed` (stiff feel).
- **Camera**: `Camera2D` child of Player, smoothing on, zoom 2x, limits set by
  the level script to room bounds. Rejected: separate manual smooth-follow
  script with look-ahead (overkill for Phase 1; can add later).
- **Input**: custom `move_*` actions (WASD + arrows). Rejected: built-in `ui_*`
  actions (would clash with UI navigation later).
- **Floor**: `TileMapLayer` + TileSet built in code (`level_01.gd`), 80x58 cells
  across five areas (Central Control, Medical Wing, Research Laboratory,
  Power Station, Communication Yard).
  Rejected: hand-authored TileSet `.tres` (text format is error-prone; code-built
  is verified by tests).
- **Walls**: `StaticBody2D` ring + dark placeholder rectangles (code-drawn, not
  atlas art — the atlas has no sci-fi wall segment). See KNOWN_ISSUES.md.
- **Sprites**: 16x16 atlas PNGs, `Nearest` filter, viewport 640x360.

## Structure
```
res://
├── project.godot            # main scene, input map, GL Compatibility, Nearest filter
├── addons/godot_ai/         # editor MCP plugin (Windows editor only)
├── assets/sprites/          # characters/player.png, environment/floor_atlas.png, props/crate.png + console_a/b.png
│   └── sprites/atlas-candidates/   # 58 inspected atlas candidates (player/floor/wall/props)
├── scenes/characters/player.tscn
├── scenes/interaction/console.tscn  # Node2D interactable (sprite texture overridable per instance)
├── scenes/interaction/door.tscn     # StaticBody2D interactable, two code-drawn leaves
├── scenes/levels/level_01.tscn    # Floor TileMapLayer, Walls, AlcoveWalls, Crate, Consoles, Door, Player
├── scenes/ui/hud.tscn             # CanvasLayer: prompt + message labels
├── scenes/main.tscn               # root, instances Level 01 + HUD
├── scenes/systems/radar_pulse.tscn  # Node2D ring, frees itself at max radius
├── scenes/interaction/hidden_object.tscn  # Node2D, group "hidden", sprite overridable
├── scenes/enemies/security_robot.tscn  # CharacterBody2D, group "enemies"
├── scripts/systems/radar_pulse.gd   # expanding ring + reveal-on-front
├── scripts/interaction/hidden_object.gd  # invisible until reveal()
├── scripts/enemies/security_robot.gd  # enum FSM: patrol / investigate / chase
├── scenes/interaction/pickup.tscn  # Node2D, group "interactable"
├── scripts/interaction/pickup.gd  # collectible: `collected` signal + frees itself
├── scenes/interaction/breaker_panel.tscn  # StaticBody2D, group "puzzles"
├── scripts/interaction/breaker_panel.gd  # sequence puzzle (order 2-1-3)
├── scripts/interaction/puzzle_switch.gd  # one breaker switch
├── scenes/interaction/wire_panel.tscn  # StaticBody2D, group "puzzles"
├── scripts/interaction/wire_panel.gd  # linked-terminal puzzle
├── scripts/interaction/puzzle_terminal.gd  # one wire terminal
├── scenes/interaction/fuse_box.tscn  # StaticBody2D, groups "interactable"+"puzzles"
├── scripts/interaction/fuse_box.gd  # needs + consumes a fuse item
├── scenes/interaction/tower.tscn  # StaticBody2D, groups "interactable"+"towers"
├── scripts/interaction/tower.gd  # gated by `power_restored`, `activated` signal
├── scripts/systems/mission.gd  # 3-stage mission tracker (puzzles → towers → transmit)
├── scenes/ui/main_menu.tscn  # the project's main scene (Phase 9)
├── scripts/ui/main_menu.gd  # Start → game scene, Quit → quit
├── scenes/ui/pause_menu.tscn  # CanvasLayer, process_mode ALWAYS, hidden
├── scripts/ui/pause_menu.gd  # Esc toggle, Resume/Restart/Main Menu
├── scripts/audio/audio_manager.gd  # procedural sounds, group "audio"
├── scenes/effects/fx_ring.tscn  # one-shot expanding ring
├── scripts/effects/fx_ring.gd
├── scenes/ui/win_screen.tscn  # MISSION COMPLETE screen, group "win"
├── scripts/ui/win_screen.gd
├── export_presets.cfg  # Windows Desktop preset (Phase 10)
├── docs/EXPORT.md  # export checklist for the user's Windows machine
├── scripts/characters/player.gd   # movement + interaction (nearest in group "interactable") + radar pulse emit
├── scripts/interaction/console.gd # interactable: use_count, `interacted` signal
├── scripts/interaction/door.gd    # interactable: open/close toggle
├── scripts/levels/level_01.gd     # floor TileSet build + camera limits + signal wiring
├── scripts/ui/hud.gd              # prompt / 3 s message
├── scripts/tests/test_runner.gd   # SceneTree runner, exit 1 on any failure
├── tools/                   # atlas search/extract scripts (not game code)
└── docs/                    # this file set
```
Atlas parquet store (398 MB) lives OUTSIDE the project at `~/workspace/pixel-atlas/`
so it is never imported or exported with the game.

## Rooms: fully separate, no shared files (2026-11-23)

Each room is a self-contained folder — `scenes/levels/rooms/<room>/` for
its scenes and `scripts/levels/rooms/<room>/` for its scripts — and shares
NO file with any other room: its own room script (the former `RoomBase`
helpers and the floor builder inlined, with its own textures, hints and
medical data), its own wiring copy, its own player / mission / radar-pulse
/ fx-ring copies, its own launcher (`play_<room>.tscn`), and its own
copies of the interaction and enemy scenes it uses (console, panels,
tower, robots). Verified by grep: no code reference in a room folder
points outside that folder (except shared sprite/texture art in
`assets/`, which is art, not logic). A bug is fixed in one room's copy
only; the copies can drift apart, and that is the price of the
separation — re-joining the rooms later means picking one copy per
system again. `RoomBase` is deleted.

Each room still builds only its own area — walls, tint, zone, props,
consoles, puzzles, its robot — in LOCAL coordinates, origin (0, 0), with
its own wall rects, solid-prop rects, patrol loop, spawn and doorway
`exits()` (local gap rect + target room/exit); it never reads the global
wall/prop/patrol tables and never names a neighbour's coordinates.

`level_01.gd` is the only place that knows the station layout
(`ROOM_TILE_OFFSETS`): it instances each room at its offset, flattens the
children into the level tree translating every child by the offset (so
assembled world positions are unchanged), derives the nav grid / blocked
rects from the rooms, and builds only the two south-west-quarter walls no
room owns. A shared divider's texture is a property of its world rect
(`MedicalData.wall_texture_for_station_rect`), applied by the assembler on
flatten. Standalone, `play_<room>.tscn` plays a room at (0, 0) with its
exits sealed; the floor pattern still matches the assembled map because
rolls are read at the global cell (local + station tile offset).
`LevelData.AREAS / AREA_WALL_RECTS / PROP_SOLID_RECTS / PATROL_RECTS`
remain as the station-layout reference for the assembled level's own
wiring/minimap (`scripts/levels/level_wiring.gd`, `level_data.gd`,
`floor_builder.gd`, `medical_data.gd` — used only by `level_01.gd` and
the unit tests now, never by a room), and `test_rooms.gd` asserts the
rooms' translated geometry agrees with them.

## Design decisions (Phase 2)
- **Movement state**: plain `is_moving` bool. Rejected: full state-machine node
  for two states (idle/moving) — the FSM arrived with enemy AI in Phase 5.
- **Walk bob**: code-driven sine on distance moved (1 px). Rejected:
  AnimationPlayer clip (needs walk frames the atlas does not have).
  v1.1 (2026-11-12): real walk cycles now exist — 4-frame
  `AnimatedSprite2D` animations per direction, drawn from the player's
  own sprite (leg pixels only); the bob stays as a 1 px supplement.
  `is_moving` is now measured from real displacement, not `velocity`
  (Godot does not zero velocity on a wall slide, so the old check kept
  the walk animation playing while the player was stuck on a wall).
- **Camera look-ahead**: `Camera2D.offset` lerped 24 px toward movement.
  Camera stays a child of the player; no separate follow script.

## Design decisions (Phase 3)
- **Interactable interface** (duck-typed, no base class): any node in group
  `"interactable"` with `interact_label`, `interact()` and
  `set_highlighted(bool)`. The player finds the nearest one within 40 px
  each physics frame and E calls its `interact()`. Rejected:
  GodotPrompter `component-system` InteractableComponent (Area2D overlap)
  — more moving parts (layers, overlap edge cases) for 3–5 interactables;
  revisit if the count grows (Phase 5 enemies, Phase 8 towers).
- **HUD**: `CanvasLayer` with a prompt label and a 3 s message label. The HUD
  knows nothing about interactables; the player drives the prompt, the
  level wires `interacted` signals to the message. HUD lookup is lazy via
  group `"hud"` and null-guarded (level tests run without the Main scene).
- **Floor variation**: two-tile atlas (`floor_atlas.png`: plain + cracked),
  15% cracked scattered with a fixed seed (deterministic layout, testable).
- **Door**: `StaticBody2D` that toggles its collision shape deferred and
  slides its two code-drawn leaves apart. Visual is placeholder metal —
  the atlas has no sci-fi door (its doors are wooden/fantasy).

## Design decisions (Phase 4)
- **Radar Pulse**: Q, expanding ring drawn in code (`_draw`, arcs + faint
  fill, no sprite), 160 px max radius at 320 px/s (0.5 s to full), 5 s
  cooldown. Reveal is distance-based: a hidden object reveals when the
  front reaches it.
- **Hidden objects**: nodes in group `"hidden"`, invisible until revealed,
  then permanently visible. They are the Phase 6 pickup items (energy cell,
  battery) — revealed now, collectible in Phase 6.
- **Battery cost**: implemented in Phase 6 — each pulse costs 15 battery
  and is blocked below that.
- **Wall occlusion**: since v1.1 (2026-11-12) the pulse raycasts the wall
  layer — a hidden object behind a wall or crate does not reveal. The
  player and enemies are excluded from the ray, so bodies do not block
  a radar wave. Enemy investigation is intentionally NOT occluded:
  enemies hear the pulse (sound), so they react by radius.
- **Investigation contract**: the player emits `pulse_emitted(origin,
  max_radius)` on every pulse. Phase 5 enemies connect to it and
  investigate the origin. The pulse itself knows nothing about enemies.

## Design decisions (Phase 5)
- **Enemy FSM**: enum-based, 3 states (PATROL / INVESTIGATE / CHASE) —
  the node-based FSM was rejected (only pays off at 5+ states with their
  own enter/exit logic). Speeds: patrol 70, investigate 110, chase 140
  (player 200 — the player can outrun the robot).
- **Movement**: since v1.1 (2026-11-12), `AStarGrid2D` pathfinding on a
  grid the level builds from the real wall/crate/prop geometry
  (same rect list feeds the physics walls and the grid, so they cannot
  disagree). The enemy follows cell-center waypoints, repaths when the
  target moves or once a second, and falls back to direct steering when
  no grid is assigned. NavigationAgent2D was rejected (one open room,
  a baked nav polygon is overkill); the old direct steering got stuck
  sliding on the crate's corner (measured: wedged at (182, 73)). The
  grid inflates the crate and solid props by one cell — a 12x14 body on
  a cell-center path passes within 1 px of a 16x16 obstacle's corner
  otherwise. Walls are NOT inflated (the 32 px doorways would close).
- **Detection**: radius 100 + vision cone ±0.7 rad around facing + raycast
  line of sight (layer 1, self and player RIDs excluded). Checked every
  0.1 s. The cone is what keeps the player spawn (room center) safe from
  the patrol loop.
- **Investigate**: on `pulse_emitted` the robot goes to the exact pulse
  origin, scans 2 s, then returns to the nearest waypoint. A pulse never
  interrupts a chase. Since v1.1 the radius is honored: an enemy farther
  than the emitted pulse radius from the origin does not react (the old
  code ignored the radius argument entirely).
- **Second archetype (v1.1)**: the Scanner robot (`scanner_robot.gd`,
  extends the security robot — same FSM and pathfinding, no duplicated
  AI). It stays at its post, rotates its cone 360°, detects at 180 px /
  ±1.2 rad, chases slower (100 px/s), and walks back to its post when
  it loses the player. Sprite: atlas row 949119 (single-eye top-down
  robot, CC0).
- **Catch**: touching the player emits `player_caught`; the level respawns
  the player at the entrance + HUD message. No game-over screen —
  Phase 9 shipped the menus without one; adding one is an open design
  decision (see KNOWN_ISSUES.md).
- **Vision cone**: drawn in code (`_draw`, faint red sector), brighter red
  while chasing — the player can read the robot's facing and range.

## Design decisions (Phase 6)
- **Battery**: player-owned vars (max 100, drain 0.5/s, radar cost 15).
  Below the cost the pulse is blocked with a HUD message; at 0 the radar
  is dead but movement is unaffected (no fail state — Phase 9 shipped
  without one; whether battery 0 should have a consequence is an open
  design decision, see KNOWN_ISSUES.md).
  Low warning at 25, re-arms above 30.
- **Inventory**: plain Dictionary `{item_id: count}` on the player.
  Resource-based items + capacity limits (awesome-gamedev
  survival-crafting points at `godot-resources` for that) were rejected
  as overkill for 2 consumables — revisit when Phase 7 puzzle items
  arrive.
- **Pickups**: `pickup.gd` is the base (interactable, `collected` signal
  carrying itself). `hidden_object.gd` extends it: invisible + outside
  the "interactable" group until a pulse reveals it. One visible energy
  cell sits in the open so collection can be learned without radar.
- **Signal wiring scope**: the level wires only its own subtree
  (`is_ancestor_of`). Tree-wide wiring double-connected a revealed hidden
  object (it is in BOTH groups) when a freed level's nodes still lingered
  — fixed in Phase 6, see DEVELOPMENT_LOG.md.

## Design decisions (Phase 7)
- **Puzzles are interactive mini-puzzles** (the user's choice), not
  find-the-item fetch quests: each one is solved by pressing E on its
  parts, with the clue readable on a console in the room.
- **Breaker panel**: 3 switches as separate interactables (nearest wins
  within 40 px); the panel owns the order [2, 1, 3]; a wrong flip resets
  all switches. Solved switches lock.
- **Wire panel**: flipping terminal i advances i AND i+1 (wrapping).
  Target: all green (flipping each twice from all-red solves it — the
  linear system mod 3 has that solution). The green dot above each
  terminal marks the target color.
- **Fuse box**: needs a fuse in the inventory; consumes it on use. The
  fuse is a third hidden object (atlas row 4172), so radar + inventory
  + puzzle chain together.
- **Clues live on consoles**: Console A holds the breaker order, Console B
  the wiring note — no new UI screens.
- **Panels are code-drawn** (Polygon2D boxes, levers, lights) like the
  walls and door — no atlas art for panels exists; only the fuse sprite
  is atlas art (row 4172, yellow fuse with red stripe).
- **tscn lesson (root cause of 10 test failures)**: in a `.tscn` node
  block, `script = ...` must come BEFORE any custom exported properties
  — properties set before the script attaches are silently dropped
  (all switches/terminals kept their default index 1). Always put the
  script line first.

## Design decisions (Phase 10)
- **Win screen**: a CanvasLayer in the main scene (group "win",
  process_mode ALWAYS, hidden), shown by the level on transmit success.
  It pauses the tree so the robot can't catch the player mid-celebration.
- **Battery-bar micro-opt**: the bar updated every physics frame even
  though the battery changes by ~0.008/frame. It now updates in 0.1-unit
  steps (5x/second instead of 60x) — visually identical on a ~100 px bar.
  The review found nothing else worth optimizing: the interactable scan
  is 15 nodes/frame, enemy detection is one raycast per 0.1 s, the floor
  is a single TileMapLayer.
- **Export**: `export_presets.cfg` (Windows Desktop, runnable, 64-bit)
  is checked in so the user's editor offers it with one click; templates
  are deliberately NOT installed on this VM (user's decision — export
  happens on his Windows machine). `docs/EXPORT.md` is the checklist.
- **Playthrough test design**: the capstone drives the whole mission
  through real interactions only (real E presses, real radar revealing
  the hidden fuse — no add_item shortcut). Lesson: the transmit console's
  stand position (320, 124) sits 4 px below the robot's top patrol edge,
  so the robot can catch the player mid-press and the E never lands —
  the test waits until the robot is > 150 px away before the final press.
  This is a test-timing guard, not a game bug: in real play the player
  can simply press E again.

## Design decisions (Phase 9)
- **No autoload for audio**: the AudioManager is a plain child node of
  the main scene (and of the main menu), found via group "audio" — the
  same lookup pattern the HUD uses. An autoload would be idiomatic, but
  it was rejected to keep headless level-only tests working without a
  singleton and to stay consistent with this codebase's HUD lookups.
- **All audio is procedural**: 9 sounds generated in code as
  AudioStreamWAV data (sine/square tones with frequency ramps, 22050 Hz
  16-bit). There are no audio files in the project, so nothing here is
  a fake asset. The ambient drone is a 2.0 s 55 Hz sine loop — exactly
  110 cycles, so the loop is seamless.
- **Pause**: the pause menu's CanvasLayer has process_mode ALWAYS, and
  the Esc toggle is polled in _process with is_action_just_pressed
  (not _unhandled_input, which synthetic test input doesn't produce).
  The tree is paused; the player/enemies freeze; the menu stays live.
- **VFX**: one generic `fx_ring` Node2D (expands + fades, frees itself)
  for pickup/tower/mission-complete feedback; a HUD full-screen flash
  (kills its previous tween before starting a new one); the battery bar
  tints red below 25.
- **Timing lesson**: headless frames run faster than real time, so a
  fixed frame count is not a fixed duration — the flash test waits in a
  bounded loop until the 0.5 s fade actually lands instead of awaiting
  60 frames.
- **Test-runner lesson**: the runner extends SceneTree, so it has no
  get_tree() — use the `paused` property directly (4 parse errors fixed).
- **`--quit-after` leak warning**: the ambient loop's AudioStreamWAV +
  its playback are reported leaked at exit because the process is killed
  while the loop is playing; a normal quit frees them. Benign.

## Design decisions (Phase 8)
- **Mission tracker**: a plain Node (`mission.gd`) in the level, 3 stages
  (puzzles → towers → transmit). Progress counts regardless of order —
  a tower activated early still counts — so the mission can never get
  stuck by doing things "too early".
- **Puzzle → tower mapping**: each panel names its tower in the
  `powers_tower` export (breaker→Tower 1, wire→Tower 2, fuse→Tower 3);
  the level sets `power_restored` on the named tower when the puzzle
  solves. Towers are dim until powered, bright + green light when active.
- **Transmit console**: a normal console with `is_transmit_console`;
  the level handles its `interacted` as the mission's final step instead
  of showing its message.
- **Mission complete ≠ game over**: after the signal is sent the game
  keeps running in a sandbox. The win screen and menus shipped in
  Phase 9.
- **Timing lesson**: the level's `_ready` runs before the HUD sibling's
  `_ready` (siblings ready in tree order), so the HUD's `@onready` labels
  are still null there — the initial objective is set with
  `call_deferred`. Also: GDScript has no `bool()` constructor (use
  `== true` or plain truthiness) — both fixed in Phase 8 after the first
  green-but-noisy run.

## Design decisions (v1.1 fixes — 2026-11-12)
- **Areas**: one level, five named areas (Central Control, Medical Wing,
  Research Laboratory, Power Station, Communication Yard) as rects in
  `level_01.gd`, connected by 32 px doorways in code-built divider walls
  (the east/south ring walls moved from the .tscn into the same rect
  list). Each area has a floor tint, props, a console with an area log,
  and an Area2D entry zone that names the area on the HUD. The Medical
  doorway sits at y 240-272, not 160-192: the wire panel (16x72 at
  (600, 204)) stands in the y 160-192 gap and leaves only an 8 px slot.
- **Player animation**: `AnimatedSprite2D` + `SpriteFrames` built in code
  (8 animations: idle/walk x down/up/left/right, walk at 8 FPS). The
  atlas has NO walk frames for this character (full-atlas search:
  17 "walking scientist" rows, all single standing poses, 0 sheets), so
  the 4 walk frames per direction are drawn from the player's own
  16x16 sprite by moving only its leg pixels 1 px per pose; the up
  frames recolour the face to hair (back view of the same character).
  Left/right share the down frames with `flip_h` — no side profiles
  exist in the atlas. No unrelated character was substituted.
- **Ambient audio**: the drone is built with a constant envelope (no
  decay), so it loops seamlessly; one-shot SFX keep their decay
  envelope. `start/stop/pause/resume_ambient` + `set_ambient_volume_db`.
- **Environment props**: atlas control panel (942608) and fuse box
  (941762) are used as decorative wall props in the new areas; the
  riveted panel (943554) is a wall plate. Walls and doors stay
  code-drawn — the atlas has no sci-fi wall segment and no metal door
  (verified across all 1.4M rows). Breaker/wire/fuse boxes stay
  code-drawn too: the atlas panel sprites are single 16x16 props that
  do not fit the 16x72 multi-switch layout.

## Design decisions (v1.2 — minimap + real walls, 2026-11-12)
- **Minimap** (`scripts/ui/minimap.gd`, HUD top-right, 208x151, M to
  toggle): drawn in code. Always shows the five area tints, the walls
  (doorway gaps visible because walls are separate rects), the player
  dot, and the three towers by state (offline grey / powered amber /
  online green). Hidden caches appear only once revealed. Enemies are
  NOT on the map by default — that would trivialize stealth; a radar
  pulse marks every enemy inside its radius for 6 s (the pulse is
  sound, so the map shows what the pulse heard). The level feeds the
  map once (deferred) with the same wall list that builds physics and
  the nav grid, so the three can never disagree.
- **Real walls**: the atlas has no sci-fi wall segment, so the wall art
  is a 16x16 seamless metal panel tile drawn for this project
  (`assets/sprites/environment/wall_metal.png`: paneled steel, rivets,
  top highlight). It repeats every 16 px on every wall Polygon2D
  (code-built area walls + the .tscn ring/alcove walls) via UVs set to
  world coordinates + `TEXTURE_REPEAT_ENABLED`. Two traps: the
  Polygon2D color must be white (it multiplies the texture — the old
  dark flat color would hide the tile), and in Godot 4.7 the repeat
  enum is DISABLED=1 / ENABLED=2 / MIRROR=3 (not 0/1/2).
- **HUD lookup**: the level resolves the HUD by the sibling path
  (parent Main → child "HUD"), falling back to the group lookup.
  `get_first_node_in_group("hud")` can return a stale HUD from a
  just-freed scene: `queue_free` deletes at end of frame, but a
  deferred call can run while the old HUD still lingers in the group
  (measured: the minimap stayed empty in the test suite because setup
  landed on the previous test's HUD).

## Design decisions (v1.3 — Persian, help & hints, one robot per area, 2026-11-12)
- **Persian-only, no translation system**: all user-facing strings
  are Persian literals in the scenes/scripts (no `tr()` catalog).
  Key names stay Latin (WASD, E, Q, M, Esc); counts use Latin
  digits so `%d` matches. There is no settings screen — "settings"
  means the controls list + pause menu, both Persian.
- **Font**: Vazirmatn v33.003 (OFL), Regular + Bold in
  `assets/fonts/`, set as the project default UI font
  (`gui/theme/default_font`). New font files need a real import
  (`godot --headless --import`): headless test runs do NOT import
  them, and `load()` fails with "No loader found" until imported.
  RTL: every UI label/button sets `text_direction = 3`. Shaping
  verified against Godot's HarfBuzz TextServer ("سلام" -> 3 glyphs,
  lam-alef ligature).
- **Help screen**: one reusable overlay scene (`help_screen.tscn` +
  `help_screen.gd`), instanced hidden in the main menu and the pause
  menu; texts live in the script consts (the .tscn stays free of
  multi-line strings). Content: goal, keys, tips. Esc in pause
  closes help first, then resumes.
- **Hints**: HUD HintLabel + 6 s HintTimer. `set_stage_hint` stores
  the standing guide (mission stage -> which key next, via the new
  `mission.current_stage()` accessor); `show_area_hint` overrides it
  on area entry and the timer restores the stage hint; `clear_hint`
  on mission complete.
- **One robot per area**: 5 enemies (Central security, Medical
  scanner, Lab security, Power scanner, Yard security). Patrol
  rects per area (PATROL_RECTS in level_01.gd); scanners get a
  single post point. Trap: the dict holds plain Arrays but
  `patrol_points` is typed `Array[Vector2]` — a direct assignment
  aborts the whole `_wire_interactables` (pulse, puzzles and towers
  unwired at once), so convert with `assign()` first.

## Signals / decoupling
- Phase 3: `interacted` signal on consoles and the door; the level connects
  it to the HUD message. First real cross-system signal in the project.
- Phase 4: `revealed` on hidden objects (level → HUD message);
  `pulse_emitted` on the player (future: enemies).
- Phase 5: `pulse_emitted` now drives enemy investigation (level wires
  player → robot); `player_caught` on the robot (level → respawn + HUD).
- Phase 6: `collected` on pickups (level → player inventory + HUD message).
- Phase 7: `solved` on each puzzle panel (level → counter + HUD message);
  `flipped` on switches/terminals (panel → order/color logic).
- Phase 8: `activated` on towers (level → mission tracker + HUD);
  `objective_completed` / `mission_completed` on the mission node.
- Later phases use signals between independent systems (radar, enemies,
  inventory), per the master instructions.
