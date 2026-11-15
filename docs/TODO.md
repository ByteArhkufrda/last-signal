# Last Signal — TODO

## Phase 1 — Project Foundation — DONE (27/27 tests, accepted by the user)
- [x] Project setup, main/player/world scenes, input map, camera, collision
- [x] Atlas pipeline + chosen sprites (player/floor/crate)
- [x] Headless test runner + docs

## Phase 2 — Player Controller and Camera — DONE (38/38 tests, accepted by the user)
- [x] Movement feel: stop snap, diagonal cap, is_moving (measured by tests)
- [x] Walk bobbing: procedural code-driven bob (atlas has no walk cycle; real
  walk frames still open — see KNOWN_ISSUES.md)
- [x] v1.1: real directional walk/idle animations — 4-frame cycles drawn
  from the player's own sprite (atlas has no matching walk frames);
  `is_moving` now from real displacement (velocity lies on a wall slide)
- [x] Camera look-ahead 24 px (deferred from Phase 1)

## Phase 3 — Environment and Interaction — DONE (59/59 tests, accepted by the user)
- [x] Interact action (E) + interactables: 2 consoles + 1 door (alcove, Console B inside)
- [x] HUD prompt + 3 s message (signals, level wires `interacted` to HUD)
- [x] Floor/wall art decision: floor is now a 2-tile atlas (plain + 15% cracked,
  seeded); walls keep code-drawn placeholders with edge highlights — atlas
  doors are wooden/fantasy and were rejected for the sci-fi station

## Phase 4 — Radar Pulse System — DONE (82/82 tests, accepted by the user)
- [x] Pulse wave (Q, 160 px max, 320 px/s, 5 s cooldown), reveal hidden objects
- [x] Enemy investigation hook: player emits `pulse_emitted(origin, radius)`;
  enemies (Phase 5) connect to it — implemented in Phase 5; v1.1 fixed
  the radius being ignored (enemies beyond the radius no longer react)

## Phase 5 — Enemy AI and Stealth — DONE (98/98 tests, accepted by the user)
- [x] Security robot (atlas: `robot companion` 6044, gold robot)
- [x] Patrol / investigate / chase states (enum FSM) + vision cone + LOS
- [x] Catch rule: respawn at the entrance + HUD message (no game-over
  screen — Phase 9 shipped the menus without one)

## Phase 6 — Energy and Inventory — DONE (120/120 tests, accepted by the user)
- [x] Battery: 100 max, 0.5/s drain, radar costs 15 (blocked below cost),
  low warning at 25, HUD battery bar
- [x] Inventory: Dictionary {item_id: count} + HUD list; pickups apply
  their effect immediately AND are counted (for Phase 7 puzzle items)

## Phase 7 — Electrical Puzzles — DONE (150/150 tests, accepted by the user)
- [x] Breaker panel: 3 switches, order 2-1-3 (clue on Console A), wrong
  flip resets, solved locks the switches
- [x] Wire panel: 3 linked terminals (flip advances it + the next one),
  all must read green (clue on Console B)
- [x] Fuse box: needs a fuse item (hidden fuse, atlas row 4172, revealed
  by radar), fuse consumed on use
- [x] HUD puzzle counter (0/3); puzzles gate the towers (wired in Phase 8)

## Phase 8 — Mission and Level Systems — DONE (171/171 tests, accepted by the user)
- [x] 3 communication towers (satellite dish 4553, radar dish 4556,
  signal beacon 2679), each gated by one puzzle
- [x] Mission tracker: puzzles → towers → transmit, HUD objective line,
  TransmitConsole sends the emergency signal ("MISSION COMPLETE")

## Phase 9 — Audio, Visual Effects and UI — DONE (221/221 tests, accepted by the user)
- [x] Main menu (project's main scene) + pause menu (Esc, Resume /
  Restart / Main Menu)
- [x] Procedural audio: 9 sounds generated in code + ambient drone,
  wired to all major events
- [x] VFX: expanding ring, full-screen flash, battery bar red when low

## Phase 10 — Testing, Optimization and Export — DONE (259/259 tests, awaiting user acceptance)
- [x] Full playthrough test (real interactions only) + win screen +
  effect-spam stress test; suite run twice in a row, both green
- [x] Win screen (MISSION COMPLETE, Play Again / Main Menu)
- [x] Battery-bar micro-opt; Windows Desktop export preset + EXPORT.md
- [ ] Export on the user's Windows machine (his step, docs/EXPORT.md)

## v1.1 — Bug-fix pass — DONE (381/381 tests, 2026-11-12)
- [x] P1 radar radius honored (boundary inclusive, never interrupts a chase)
- [x] P2 ambient loops seamlessly (constant envelope); SFX keep decay
- [x] P3 real directional walk/idle animations (drawn leg frames, 8 FPS)
- [x] P4 AStarGrid2D pathfinding (crate/prop inflation, direct fallback)
- [x] P5 five connected areas (doorways, tints, props, consoles, zones)
- [x] P6 Scanner robot (stationary rotating watch, wider/longer detection,
  slower chase, returns to post)
- [x] P7 atlas panel/fuse-box/riveted-panel props; walls/doors stay
  code-drawn (no sci-fi art in the atlas)
- [x] P8 radar reveal needs line of sight; investigation stays radius-based
- [x] P9 docs + stale comments synced
- [x] P10 full regression 381/381
- [ ] P11 Windows build — templates not installed on this VM; export stays
  on the user's Windows machine (docs/EXPORT.md)

## v1.2 — Minimap + real walls — DONE (439/439 tests, 2026-11-12)
- [x] Minimap: areas, walls, player dot, towers by state, revealed
  caches, enemies marked 6 s after a radar pulse in range; M toggles
- [x] Real walls: drawn 16x16 metal panel tile on all wall visuals
- [x] HUD lookup hardened (sibling path + group fallback)
- [x] Docs synced (ARCHITECTURE, PROJECT_STATE, KNOWN_ISSUES, TODO,
  DEVELOPMENT_LOG)

## v1.3 — Persian, help, one robot per area — DONE (512 tests, 2026-11-12)
- [x] All game text Persian (menus, HUD, objectives, messages, areas, items, labels, logs); Vazirmatn font + RTL
- [x] Help screen (goal + keys + tips) from main menu and pause menu; Esc closes help first
- [x] In-game hints: stage hint (which key next) + area hint on entry (6 s, then stage hint returns)
- [x] One robot per area (5 total); per-area patrol rects; scanners stay at post
- [x] 9 new tests; existing English-text assertions updated to Persian
