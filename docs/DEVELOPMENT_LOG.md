# Last Signal — Development Log

## 2026-11-12 — Phase 1: Project Foundation
- Audit (read-only): Godot 4.7.2.stable.official.ed1daf0bf installed at
  `~/workspace/tools/godot/4.7.2/`; no Last Signal project existed; only the
  earlier `test-project` sample. No Godot MCP connection on this headless VM.
- Atlas: `Angais/pixel-art-atlas-1.4m` — 1,409,404 synthetic 16x16 sprites,
  CC0 1.0. Downloaded all 15 train shards + validation (434 MB parquet,
  1,405,308 train rows verified). Two shards (train-01, train-010) arrived
  truncated in a parallel download; re-downloaded with resume, verified
  row counts (93,688 / 93,687 per shard).
- Sprite search: no scientist/astronaut in shard 0; characters live in later
  shards. Visually inspected contact sheets (player/floor/wall, 8x upscale).
  - Player: `952623_scientist.png` — "top-down walking white scientist with
    a lab coat" (row 952623, train-010).
  - Floor: `1002_floor_tile.png` — dark gray tile.
  - Crate: `309_shipping_crate.png`.
  - Wall: NO sci-fi wall segment exists in the atlas (searched all shards:
    metal/steel plate, bulkhead, wall panel — 0 hits). Walls are code-drawn
    placeholder rectangles, honestly labeled.
- Skills used: router + godot-2d-movement + godot-tilemap +
  godot-gdscript-headless-testing + GodotPrompter player-controller /
  input-handling / camera-system / godot-project-setup + godot-tutorials +
  godot-ai (plugin copied to `addons/godot_ai/`).
- Built: project.godot (input map, Nearest filter, 640x360), player scene +
  script, level 01 (floor TileSet in code, wall ring, crate), main scene,
  headless test runner.
- Tooling fix: system numpy 1.26 broke pyarrow 26 (needs numpy>=2); pyarrow 17
  + numpy 1.26 fixed it. (pyarrow/numpy live in `~/.local`, VM-wide.)
- Test results: first run 26/27 — `motion_mode` was only set in `_ready()`;
  fixed by also setting `motion_mode = 1` in `player.tscn`. Second run
  **27/27 pass, exit 0**. Main scene headless run: exit 0, no errors.
  Wall-block test: player pushed left stops at x=22.003 (wall inner edge
  16 + half-width 6 = 22).

## 2026-11-12 — Phase 2: Player Controller and Camera
- Skills: GodotPrompter `player-controller` + `camera-system` (re-read) +
  `animation-system` (code-driven animation section); full state machine
  rejected for two states (idle/moving) — FSM comes with enemy AI, Phase 5.
- Movement: stop snap below 8 px/s (full stop < 1 px/s after release),
  diagonal speed capped at 200 (verified), `is_moving` bool after collision.
  Measured: time to full speed 200/1500 = 0.133 s; stop time 200/1200 = 0.167 s.
- Walk bob: procedural sine on distance moved (1 px amplitude, 0.35 cycles/px),
  sprite returns exactly to base offset when idle. No fake walk frames.
- Camera: look-ahead 24 px toward movement direction, lerped at 4/s, returns
  to center when idle. Camera stays a child of the player (no separate
  follow script).
- Tests: 3 new tests added (diagonal cap, stop/is_moving, bob + look-ahead).
  **38/38 pass, exit 0.** Main scene headless run: exit 0, no errors.
  No test failures during Phase 2.

## 2026-11-12 — Phase 3: Environment and Interaction
- Skills: GodotPrompter `component-system` (InteractableComponent pattern
  read; Area2D overlap rejected for 3–5 interactables — distance checks are
  simpler and fully testable headless; revisit if the count grows).
- Interaction: `interact` action (E, physical keycode 69); player finds the
  nearest node in group "interactable" within 40 px, highlights it (yellow
  tint) and shows "E — <label>" in the HUD; E calls its interact().
  Interface is duck-typed (interact_label / interact() / set_highlighted())
  so a StaticBody2D door can be an interactable too — no base class.
- Consoles: atlas computer towers, visually inspected (6633 black/green for
  A, 145 blue for B). Console B sits inside a new top-right alcove.
- Door: StaticBody2D, toggles collision deferred + slides two code-drawn
  leaves apart; label flips Open/Close. Atlas doors are wooden/fantasy and
  were rejected — door visual is placeholder metal with a yellow stripe.
- HUD: CanvasLayer, prompt label + 3 s message label. First real signal in
  the project: level wires `interacted` to the HUD message. HUD lookup is
  lazy via group "hud" and null-guarded (level tests run without Main).
- Environment: floor is now a 2-tile atlas (plain 1002 + cracked 15119),
  15% cracked scattered with fixed seed 17 (deterministic, ~138 of 920
  cells). Walls got 4 px lighter edge highlights.
- Fixes during Phase 3: (1) test runner used `get_tree()` — SceneTree has
  no such method, use its own `get_nodes_in_group()`; (2) new PNGs had no
  `.import` files — one `godot --headless --path . --import` fixed it.
- Tests: 6 new tests added (interact action, 3 interactables, floor
  variation, console use, door toggle, HUD prompt). **59/59 pass, exit 0.**
  Main scene headless run: exit 0, no errors.

## 2026-11-12 — Phase 4: Radar Pulse
- Radar: Q action (physical keycode 81); player emits an expanding ring
  (code-drawn arcs, 160 px max, 320 px/s, 0.5 s to full), 5 s cooldown.
  Battery cost deferred to Phase 6 — pulse costs only cooldown for now.
- Hidden objects: 2 in Level 01 (energy cell at (96, 280), battery at
  (560, 320)), group "hidden", invisible until the pulse front reaches
  them, then permanently visible. They are the Phase 6 pickup items —
  revealed now, collectible in Phase 6.
- HUD: radar status label top-left ("Radar [Q] ready" / "Radar
  recharging… Ns"), updated only when the text changes.
- Investigation hook: player emits `pulse_emitted(origin, max_radius)` on
  every pulse. No enemies exist yet (Phase 5), so only the contract is
  implemented — the pulse itself knows nothing about enemies.
- Simplification documented: the pulse ignores walls (reveals within 160 px
  even behind a wall).
- Tests: 5 new tests added (radar action, hidden objects start hidden,
  near/far reveal, cooldown + signal, HUD radar status). **82/82 pass,
  exit 0.** Main scene headless run: exit 0, no errors.

## 2026-11-12 — Phase 5: Enemy AI and Stealth
- Skills: GodotPrompter `state-machine` (enum-based for 3 states; node-based
  rejected) + `ai-navigation` (NavigationAgent2D read and rejected: one open
  room, a baked nav polygon is overkill) + awesome-gamedev `godot-physics`
  (raycast: exclude self and player RIDs).
- Robot: atlas gold robot 6044 (visually inspected, Phase 3 sheet). FSM:
  PATROL (waypoints around the room center, 1 s wait each) / INVESTIGATE
  (pulse origin, scan 2 s, back to nearest waypoint) / CHASE (140 px/s).
  Detection: 100 px + cone ±0.7 rad + raycast LOS, checked every 0.1 s.
  The cone is what keeps the player spawn safe from the patrol loop.
  Vision cone drawn in code (faint red, brighter while chasing).
- Catch: touch → `player_caught` → level respawns the player at the
  entrance + HUD message. No game-over screen yet (Phase 9).
- Fixes during Phase 5: (1) enemy spawns ON waypoint 0, so it waits 1 s
  before moving — patrol test now waits 90 frames; (2) assigning an
  untyped Array literal to a typed `Array[Vector2]` property fails — tests
  build a typed local first; (3) a freed level's player overlaps the new
  level's player at the spawn for a frame and physics pushes the new one
  ~12 px aside — the investigate test now resets the player position
  after the first idle frame. Lesson: tests that depend on exact spawn
  position must reset it after creation.
- Tests: 6 new tests added (patrol, investigate, chase, lose player,
  no-see-through-crate, caught respawn). **98/98 pass, exit 0.** Main
  scene headless run: exit 0, no errors.

## 2026-11-12 — Phase 6: Energy and Inventory
- Skills: awesome-gamedev `survival-crafting` (points at `godot-resources`
  for items-as-data + warns that unlimited inventory removes tension).
  Decision: plain Dictionary inventory for now (2 consumables);
  Resource-based items + a cap are a Phase 7 decision.
- Battery: 100 max, 0.5/s passive drain, radar costs 15 (the cost deferred
  from Phase 4). Below 15 the pulse is blocked with a HUD message; at 0
  the radar is dead, movement unaffected (no fail state yet — Phase 9).
  Low warning at 25, re-arms above 30. HUD battery bar (ProgressBar,
  top-right, with percentage) + inventory label (bottom-left).
- Inventory: `{item_id: count}` on the player. Consumables apply their
  effect immediately on pickup (+40 battery, capped at 100) AND are
  counted — Phase 7 puzzles will need non-consumable items.
- Pickups: `pickup.gd` base (interactable, `collected` signal carrying
  itself); `hidden_object.gd` now extends it — invisible + outside the
  "interactable" group until a pulse reveals it. One visible energy cell
  added at (120, 320) so collection can be learned without radar.
- Fix during Phase 6: level signal wiring was tree-wide, so a revealed
  hidden object (in BOTH groups) got its `collected` connected twice when
  a freed level's nodes still lingered — wiring is now scoped to the
  level's own subtree (`is_ancestor_of`). The interactables test was also
  updated: 4 now (2 consoles + door + visible pickup).
- Tests: 6 new tests added (drain, radar cost, blocked-when-low, hidden
  pickup collects, visible pickup collects, HUD battery + inventory).
  **120/120 pass, exit 0.** Main scene headless run: exit 0, no errors.

## 2026-11-12 — Phase 7: Electrical Puzzles
- User's choice: interactive mini-puzzles (not fetch quests).
- Puzzle 1 — breaker panel (left wall): 3 switches, order 2-1-3, clue on
  Console A; wrong flip resets all switches; solved switches lock.
- Puzzle 2 — wire panel (right wall): flipping terminal i advances i AND
  i+1 (wrapping); all three must read green (flipping each twice from
  all-red solves it); clue on Console B; green dot marks the target.
- Puzzle 3 — fuse box (bottom wall): needs a fuse from the inventory,
  consumed on use. The fuse is a third hidden object (atlas row 4172,
  yellow fuse with red stripe, chosen from 4 candidates on a sheet) at
  (600, 100) — radar + inventory + puzzle chain together.
- HUD puzzle counter (top-left, "Puzzles solved: n/3"). Puzzles gate
  nothing yet — Phase 8 wires them to the towers.
- Root-cause fix during Phase 7: in a `.tscn` node block, `script = ...`
  must come BEFORE custom exported properties — properties set first are
  silently dropped, so every switch/terminal kept its default index 1
  (10 test failures, all from this one cause). Fixed by reordering the
  script line first in both panel scenes; recorded in ARCHITECTURE.md.
  Two test fixes too: the "far" spot in the HUD prompt test was 36 px
  from the new fuse box (moved to (320, 240)), and the hidden-object
  count went 2 → 3.
- Tests: 7 new tests added (wrong order resets, correct order solves +
  locks, wire panel solves, fuse box needs fuse, fuse box solves +
  consumes, fuse pickup collects, HUD puzzle counter). **150/150 pass,
  exit 0.** Main scene headless run: exit 0, no errors.

## 2026-11-12 — Phase 8: Mission and Level Systems
- Skills: none new — the mission tracker is a plain Node with stage
  logic; the tower is a gated interactable reusing the Phase 3 interface.
- Towers: 3 atlas sprites (satellite dish 4553, radar dish 4556, signal
  beacon 2679 — chosen from 5 candidates on a sheet, distinct looks).
  Each tower is gated by one puzzle (breaker→Tower 1, wire→Tower 2,
  fuse→Tower 3 via the panels' `powers_tower` export); offline towers
  are dim, active ones bright with a green light.
- Mission: 3 stages (puzzles → towers → transmit) with a HUD objective
  line showing the current stage + progress. Progress counts regardless
  of order, so activating a tower early can never stall the mission.
  The TransmitConsole (a console with `is_transmit_console`) sends the
  emergency signal once all towers are online — "MISSION COMPLETE",
  and the game keeps running in a sandbox (no end screen yet — Phase 9).
- Fixes during Phase 8: the first run was green (171/171) but noisy —
  (1) GDScript has no `bool()` constructor (fixed with `== true`);
  (2) the level's `_ready` runs before the HUD sibling's `_ready`, so
  the initial objective set hit a null label (fixed with
  `call_deferred`). Final run: **171/171 pass, exit 0, zero errors.**
  Main scene headless run: exit 0, no errors.
- Tests: 6 new tests added (tower blocked without power, tower activates
  after its puzzle + mapping check, mission stages advance, transmission
  completes the mission, transmit blocked early, HUD objective line).

## 2026-11-12 — Phase 9: Audio, VFX, and UI
- Skills: none new — menus, procedural audio and the ring effect are
  plain Godot (Control/Button/CanvasLayer/AudioStreamWAV).
- Main menu (now the project's main scene): title, subtitle, Start Game
  (loads the game scene), Quit, controls list. Pause menu on Esc:
  Resume / Restart / Main Menu, process_mode ALWAYS so it stays live
  while the tree is paused; the toggle is polled in _process (synthetic
  test input doesn't produce _unhandled_input events). Verified first
  that `process_frame` still fires while paused (10/10 in a debug run).
- Audio: 9 sounds generated in code (no audio files) — click, blip,
  pulse, chime, error, sting, tower, fanfare + a looping 55 Hz ambient
  drone (2.0 s = exactly 110 cycles, seamless loop). Wired to: pulse,
  pickup, puzzle solved, wrong breaker flip, missing fuse, tower
  activation, caught, mission complete, menu clicks. No autoload — the
  manager is a child node found via group "audio" (same as the HUD).
- VFX: expanding ring on pickup (gold), tower (cyan), mission complete
  (green); full-screen flash (red when caught, green on complete);
  battery bar turns red below 25.
- Fixes during Phase 9: the runner extends SceneTree, so it has no
  get_tree() (4 parse errors); the flash test awaited a fixed 60 frames
  but headless frames run faster than real time, so it now waits in a
  bounded loop until the fade lands. Final run: **221/221 pass, exit 0,
  zero errors.** Game scene + menu scene headless runs: exit 0.
- Tests: 7 new tests added (menu loads + buttons wired, pause toggles
  with Esc, pause freezes the player, audio manager generates all 9
  sounds, ring frees itself, HUD flash fades, battery bar red when low).

## 2026-11-12 — Phase 10: Testing, Optimization, and Export
- Skills: none new — the win screen reuses the pause-menu pattern;
  the export preset is a hand-written `export_presets.cfg`.
- Win screen: MISSION COMPLETE + Play Again / Main Menu, pauses the
  tree when shown (group "win", process_mode ALWAYS).
- Optimization review: the only change is the battery bar updating in
  0.1-unit steps instead of every physics frame. Everything else was
  measured as already cheap (15-node interactable scan, one raycast per
  0.1 s, single TileMapLayer floor) and left alone.
- Export prep: Windows Desktop preset checked in + `docs/EXPORT.md`
  (Godot 4.7.2 on Windows, install export templates once, export to
  .exe + .pck). The export itself happens on the user's machine.
- Capstone test: a full playthrough through real interactions only —
  breaker, wire, radar revealing the hidden fuse, fuse insert, 3 towers,
  transmit → MISSION COMPLETE + win screen. First run failed at the
  final press: the console's stand position sits 4 px below the robot's
  top patrol edge, so the robot caught the player mid-press. Fixed in
  the test by waiting until the robot is > 150 px away (a timing guard,
  not a game bug — in real play you just press E again). Final run:
  **259/259 pass, exit 0, zero errors — twice in a row.** Game scene +
  menu scene headless runs: exit 0. Full re-import: exit 0.
- Tests: 3 new tests added (full playthrough, win screen, effect-spam
  stress: 20 rings + 5 pulses at once, game still runs).

## 2026-11-12 — Post-Phase-10 bug review (user asked for a check)
- Full read of every game script + targeted probes. Two real bugs found
  (both reproduced by a failing test first, then fixed):
  1. **Esc unpaused the game behind the win screen.** The pause menu
     polls Esc in _process (process_mode ALWAYS), so with MISSION
     COMPLETE up, Esc "resumed" — the tree unpaused while the win screen
     was still visible, letting the robot catch the player and the battery
     drain behind it. Fix: the pause menu ignores Esc while the win
     screen (group "win") is visible. Test: test_win_screen_blocks_pause.
  2. **Inventory label showed "fuse" instead of "Fuse".** ITEM_DISPLAY
     had no "fuse" entry, so it fell back to the raw item id (lowercase).
     Fix: added "fuse": "Fuse". (The fuse pickup's own display_name was
     already correct — only the inventory label was wrong.) Test: the
     playthrough now asserts the label contains "Fuse".
- Checked and cleared (no bug): the player's `_current_interactable`
  after a pickup is collected — a probe confirmed a freed reference
  compares `== null` in Godot 4, so the existing `!= null` guard covers
  it; double `solved`/`activated` emission is impossible (all panels and
  towers guard + lock); the door can't soft-lock the alcove (reopenable
  from inside); the robot can't catch the player at the center spawn
  (vision cone); scene Restart / Play Again correctly unpause before
  reloading; the `--quit-after` leak warning is the ambient loop only.
- Final run after the fixes: **264/264 pass, exit 0, zero errors —
  twice in a row.** Game + menu headless runs: exit 0.

## 2026-11-12 — v1.1 bug-fix pass (P1–P11, user-assigned)
- Baseline first: the v1.0 zip is byte-identical to the workspace copy;
  baseline suite run **264/264 pass, exit 0** (the first two attempts ran
  without `--script` and idled on the main menu — the runner must be
  started as `godot --headless --path . --script
  res://scripts/tests/test_runner.gd`).
- Atlas investigation (subagent, visual inspection of every candidate):
  no genuine walk frames for the player exist in the 1.4M-row atlas
  (17 "walking scientist" rows, all single standing poses, 0 sheets);
  no sci-fi/metal wall segment and no metal door exist (wall segments
  are brick + castle only; doors are all wooden). Usable: control panel
  942608, fuse box 941762, riveted panel 943554, Scanner robot 949119
  (single-eye top-down robot).
- P1: `investigate()` now honors its radius (boundary inclusive, never
  interrupts a chase). P2: ambient built with a constant envelope —
  seamless loop; SFX keep decay; pause/resume + volume added.
- P3: 8 animations (idle/walk x 4 directions, walk 8 FPS) on
  AnimatedSprite2D + code-built SpriteFrames. Frames are drawn from the
  player's own sprite (leg pixels only, 1 px per pose; up = back view
  by recolouring the face to hair). Left/right share down frames with
  flip_h. `is_moving` now uses real displacement — velocity stays
  (-200, 0) on a wall slide, so the old check played the walk animation
  while stuck (measured, then fixed).
- P4: AStarGrid2D pathfinding, grid built from the same rect list as the
  physics walls; crate + solid props inflated by one cell (enemy wedged
  on the crate's corner at (182, 73) without it). Direct steering kept
  as the fallback.
- P5: map 40x23 → 80x58, five areas (Central Control, Medical Wing,
  Research Laboratory, Power Station, Communication Yard) with 32 px
  doorways, floor tints, props, area consoles, entry zones. The Medical
  doorway moved from y 160-192 to y 240-272 — the wire panel (16x72 at
  (600, 204)) blocked the first gap down to an 8 px slot (measured:
  player pushed back to x=586).
- P6: Scanner robot (extends the security robot; stationary rotating
  watch, 180 px / ±1.2 rad, chase 100, returns to post).
- P7: atlas panel/fuse-box/riveted-panel used as area props; walls,
  doors, breaker/wire/fuse boxes stay code-drawn (no fitting atlas art).
- P8: radar reveal needs line of sight (walls/crates block); enemy
  investigation stays radius-based by design (sound).
- P9: docs + stale comments synced (PROJECT_STATE, ARCHITECTURE, TODO,
  KNOWN_ISSUES, this log; player.gd Phase 4 note, radar_pulse.gd header).
- P10: full regression after the fixes — **381/381 pass, exit 0, zero
  errors** (31 new tests, 117 new assertions; 3 iterations to green:
  PackedVector2Array needs an Array literal; scanner patrol_points
  needs a typed Array[Vector2]; the patrol_points error aborted level
  wiring and broke every puzzle test until fixed).
- P11: export templates are NOT installed here (empty
  `~/.local/share/godot/export_templates/`); no Windows build was
  produced or claimed. Export stays on the user's Windows machine.

## 2026-11-12 — v1.2 minimap + real walls (user-assigned, after v1.1)
- Minimap (`scripts/ui/minimap.gd`, HUD top-right 208x151, M toggles):
  area tints + walls (doorway gaps visible), player dot, towers by
  state (offline / powered / online), hidden caches only once
  revealed, enemies only 6 s after a radar pulse in range. The level
  feeds it the same wall list as physics + nav grid, so the three
  cannot disagree. Wired via HUD `setup_minimap` (deferred, like the
  objective) + `pulse_emitted` → mark handler + area label updates.
- Real walls: a 16x16 seamless metal panel tile drawn with PIL
  (paneled steel, rivets, top highlight — visually inspected on a
  contact sheet) at `assets/sprites/environment/wall_metal.png`,
  tiled on every wall Polygon2D (code-built area walls + .tscn
  ring/alcove walls) via UVs = world coords + TEXTURE_REPEAT_ENABLED.
  The atlas has no sci-fi wall segment, so this is drawn art, not
  atlas art (same honesty rule as the walk frames).
- Three root-cause bugs found by the first suite run (428 pass,
  9 fail):
  1. **Stale HUD race** — the minimap stayed empty in the suite but
     worked in isolation. Cause: `get_first_node_in_group("hud")`
     returns the previous test's HUD, because queue_free deletes at
     end of frame while a deferred setup call can run while the old
     HUD still lingers in the group. Fix: `_get_hud()` resolves the
     HUD by sibling path (parent Main → "HUD") with group fallback;
     all 10 HUD lookups in level_01.gd use it now.
  2. **TextureRepeat enum is 1/2/3, not 0/1/2** in Godot 4.7
     (DISABLED=1, ENABLED=2, MIRROR=3 — measured with a diag
     script). The .tscn had `texture_repeat = 1` = DISABLED; fixed
     to 2. The code-built walls used the constant and were right.
  3. **There are 3 hidden objects, not 2** (cell, battery, fuse) —
     the test expectation was wrong, not the game.
- Full regression after the fixes — **439/439 pass, exit 0** (11 new
  tests). Main scene headless run: exit 0, no errors.

## 2026-11-12 — Windows export of v1.2 (user-assigned)
- Source: the working copy `~/workspace/last-signal/` at v1.2 (no git
  repo; docs + file dates confirm; nothing newer than the v1.2 zip).
  Pre-export validation: 439/439 tests pass.
- Templates were absent (empty export_templates dir — the earlier
  decision). User explicitly approved downloading them: official
  Godot 4.7.2 .tpz, 1,281,349,702 bytes, size-verified, installed to
  `~/.local/share/godot/export_templates/4.7.2.stable/` (35 files).
  The .tpz was deleted after install.
- First export failed: the exporter looked for
  `windows_release_0.exe` / `windows_debug_0.exe`. Root cause: the
  preset stored `binary_format/architecture=0` (int); Godot 4.7.2
  stringifies that value into the template filename, so it wants the
  literal string "x86_64". Fix: preset now has
  `binary_format/architecture="x86_64"`. (Also learned: in 4.7 the
  TextureRepeat enum is 1/2/3 — same "int is not what it looks like"
  family of surprises.)
- Export succeeded, 0 errors, 0 warnings, 610 files packed:
  `build/windows/LastSignal.exe` (109,224,448 bytes, PE32+ x86-64)
  + `LastSignal.pck` (1,637,268 bytes, GDPC v4) +
  `LastSignal_Windows_Latest.zip` (39,618,588 bytes).
- Not run on Windows (Linux VM) — binary verified, runtime untested.

## 2026-11-12 — v1.3 Persian, help & hints, one robot per area (user-assigned)
- Language: everything Persian (menus, HUD, objectives, messages,
  area/item names, interact labels, console logs). Key names stay
  Latin; counts use Latin digits. No settings screen exists, so
  "settings" here means the controls list + pause menu — all Persian.
- Font: Vazirmatn v33.003 (OFL), Regular + Bold in assets/fonts/,
  set as the project default UI font. Imported with
  `godot --headless --import` (headless test runs do NOT import new
  files on their own — the font load failed until imported).
  Shaping verified against Godot's HarfBuzz TextServer: "سلام" -> 3
  glyphs (lam-alef ligature). Labels/buttons use text_direction RTL.
- Help screen: one reusable overlay scene, instanced hidden in the
  main menu and the pause menu; goal + keys + tips; Back button.
  Esc in pause closes help first, then resumes.
- Hints: HUD HintLabel + 6 s timer. Stage hints (0 puzzles / 1
  towers / 2 transmit) via mission.current_stage() (new accessor);
  area hints on entry, then the stage hint returns. Cleared on win.
- Robots: 3 added (Lab security at (200,560), Power scanner at
  (1000,520), Yard security at (800,840)) — one per area, 5 total.
  Patrol rects per area (PATROL_RECTS); Lab rect starts at x=160 so
  the patrol edge does not run through the Lab console at (120,560).
- Root cause found en route: PATROL_RECTS holds plain Arrays, but
  patrol_points is typed Array[Vector2] — the assignment aborted the
  whole _wire_interactables, silently unwiring pulse, puzzles and
  towers (35 tests failed at once). Fix: convert with assign().
  Same family as the 4.7 TextureRepeat enum surprise: Godot 4.7
  types are strict about ints/arrays that look interchangeable.
- Also localized 4 messages found by sweeping (breaker wrong order,
  fuse missing, tower already online/offline) + the door message.
- Existing test assertions that checked English text were updated to
  the Persian strings (same behavior, new wording); 9 new tests.
  Final run: 512 passed, 0 failed (exit 0). The Windows v1.2 build
  is now stale (English) — re-export pending.
- Re-exported for v1.3 the same evening (~22:40): exe 109,224,448
  bytes + pck 1,807,076 bytes (618 files, fonts + help screen in
  the pack) + zip 39,783,205 bytes; 0 export errors. Still not run
  on Windows (Linux VM) — binary verified, runtime untested.

## v1.4 — Medical Wing pack wired in (2026-11-15, ~14:15)
- The 83-sprite Medical Wing pack (medical-wing-pack/, built earlier the
  same day) is now live in the game — code only, no export (per the
  user's standing order: no builds until he says so).
- Assets: the 83 authoritative sprites copied to
  assets/sprites/medical-wing/ (+ manifest.json/MANIFEST.md); the 12
  floor tiles composed into assets/sprites/environment/
  floor_medical_atlas.png (192x16).
- Floor: the Medical Wing's 920 cells (tiles x 40-79, y 0-22) use the
  pack's 12-tile atlas with weights standard 70 / alt 8 / cracked 6 /
  broken 1 / stains 4 / footprints 3 / tracks 2 / debris 3 / hatch 1 /
  grille 1 / panel 1. One rng roll per cell, as before, so the Central
  floor pattern is unchanged. First weights (50/25/...) made the floor
  read as a dark/light checkerboard in the Xvfb screenshot; the reweight
  fixed it (screenshot verified).
- Walls: the wing's own walls use the pack's tiles — west divider +
  east exterior (Medical half) get wall_v, south divider gets wall_h.
  The east exterior rect was split at y=368 (same union, so collision
  and the nav grid are unchanged). test_wall_texture_applied updated:
  it now accepts all three wall textures and asserts exactly 5 medical
  wall visuals.
- Furniture: 27 solid props (6 wide 32x16: 3 beds, exam bed, stretcher,
  doctor's desk; 21 small: cabinets, shelf, monitors, oxygen, IV,
  pump, lamp, defibrillator, trolley, cart, chairs, tables, boxes,
  bin) with PROP_SOLID_RECTS entries, so nav grid, physics and minimap
  agree. ~30 decor sprites: wall clock/panel/window/grille/sign,
  observation window, corners, fuse box, ceiling + indicator lights,
  supplies, scattered papers, fallen chair, steam/spark/dust, and the
  flashlight + handwritten note on the doctor's desk.
- Medical console (760,80) now shows the vitals monitor texture.
- Hidden fuse pickup now shows the pack's white fuse (atlas row 165).
- NOT done, on purpose: the door sprites have no door to replace (the
  alcove door is code-drawn sliding leaves in Central; the medical
  doorway is an open gap), and the fuse-box puzzle is code-drawn in
  Central — the pack's fusebox_closed is placed as decor in the wing.
- Constraints kept: 19 interactables (no new ones), both medical
  doorways open in the nav grid, scanner line of sight (x=900,
  y 120-200) clear, entry corridor (y 240-272) clear. 4 new tests
  (medical floor atlas, props exist, doorways open, fuse texture).
- Final run: 661 passed, 0 failed (exit 0), up from 512. Visual check:
  Xvfb screenshots docs/medical-wing-preview-{full,beds,desk}.png.
  The brownish wash in the shots is the scanner's vision cone, not
  the new floor. The Windows v1.3 build is now stale (old medical
  look) — re-export pending the user's word.
