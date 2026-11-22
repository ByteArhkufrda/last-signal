# Last Signal — Project State

Updated: 2026-11-23 (rooms fully separated — no shared files; MERGED into develop, commit 3b2efa8)

## Current development phase
**Rooms fully separate (local coordinates) — DONE, unmerged** (verified by test run, 2026-11-23: test_runner 661/661 + test_rooms 315/315; every room now builds in its own (0, 0) space with its own walls/props/patrol/exits, the assembler alone knows the station offsets, and the assembled world positions are unchanged; branch `refactor/standalone-rooms`, awaiting user review — no export taken, user said no builds until he says so)

**Rooms absolutely separate — no shared file — DONE, unmerged** (verified by test run, 2026-11-23: test_runner 661/661 + test_rooms 328/328; every room is now a self-contained folder with its own copies of the room script (base helpers + floor builder inlined), wiring, player, mission, radar pulse, fx ring, launcher and the interaction/enemy scenes it uses — 98 files across 5 rooms, zero code references between rooms, verified by grep; `RoomBase` and the shared `room_play` are deleted; the shared originals (`level_wiring.gd`, `level_data.gd`, `floor_builder.gd`, `medical_data.gd`, player/mission/interaction/enemy scenes) remain only for the assembled level and the unit tests; branch `refactor/absolute-room-separation`, **merged into develop 2026-11-23 (merge commit `3b2efa8`, pushed, tests re-run on the merge: 661/661 + 328/328)** — no export taken, user said no builds until he says so)
**v1.4 Medical Wing pack — DONE** (verified by test run, 2026-11-15: 661 passed, 0 failed; Xvfb screenshots in docs/medical-wing-preview-*.png; no export taken — user said no builds until he says so)
**v1.3 Persian, help & hints, one robot per area — DONE** (verified by test run, 2026-11-12)
**v1.2 minimap + real walls — DONE** (verified by test run, 2026-11-12)
**v1.1 bug fixes (P1–P11) — DONE** (verified by test run, 2026-11-12)
**Phase 10: Testing, Optimization, and Export — DONE** (verified by test run, awaiting user acceptance)
**Phase 9: Audio, VFX, and UI — DONE** (accepted by the user on 2026-11-12)
**Phase 8: Mission and Level Systems — DONE** (accepted by the user on 2026-11-12)
**Phase 7: Electrical Puzzles — DONE** (accepted by the user on 2026-11-12)
**Phase 6: Energy and Inventory — DONE** (accepted by the user on 2026-11-12)
**Phase 5: Enemy AI and Stealth — DONE** (accepted by the user on 2026-11-12)
**Phase 4: Radar Pulse — DONE** (accepted by the user on 2026-11-12)
**Phase 3: Environment and Interaction — DONE** (accepted by the user on 2026-11-12)
**Phase 2: Player Controller and Camera — DONE** (accepted by the user on 2026-11-12)
**Phase 1: Project Foundation — DONE** (accepted by the user on 2026-11-12)

## Completed features
- Godot 4.7.2 project (`~/workspace/last-signal/`, main scene `scenes/ui/main_menu.tscn`)
- Player scene: top-down `CharacterBody2D`, accel/friction movement, sprite flip, Camera2D child (zoom 2x, smoothing, limits = room bounds)
- Level 01 (station K-17): 80x58 tile floor from atlas art across five
  connected areas (Central Control, Medical Wing, Research Laboratory,
  Power Station, Communication Yard), wall ring + divider walls + crate
  obstacles with collision, area entry zones that name the area on the HUD
- Input Map: `move_left/right/up/down` (WASD + arrow keys)
- Headless test runner: **661/661 tests pass, exit 0** (`scripts/tests/test_runner.gd`)
  (v1.3 was 512/512; v1.4 added 4 medical tests + ~145 assertions)
- Headless room tests: **315/315 checks pass** (`scripts/tests/test_rooms.gd`,
  2026-11-23: local-coordinate contract — standalone positions/nav are local,
  assembled positions are local + station offset, exits pair up, and the
  rooms' translated walls/props agree with the station layout in LevelData)
- Post-Phase-10 review (2026-11-12): full code read + probes found and
  fixed 2 bugs — Esc unpausing the game behind the win screen, and the
  inventory label showing "fuse" instead of "Fuse" (see DEVELOPMENT_LOG)
- Main scene and main menu run headless clean, exit 0, no errors
  (note: `--quit-after` reports 2 leaked ObjectDB instances — the
  ambient loop's AudioStreamWAV + its playback, still playing when the
  process is killed mid-run; a normal quit frees them. Benign.)
- Full re-import (`--import`) clean, exit 0

## Quality bar (from the master plan) — all met
- [x] Complete beginning + ending: main menu → mission → MISSION
  COMPLETE win screen (Play Again / Main Menu)
- [x] Responsive controls (WASD/arrows, E, Q, Esc)
- [x] Consistent pixel art (all sprites from the CC0 atlas)
- [x] Working Radar Pulse (reveals hidden objects, enemies investigate)
- [x] Enemy AI (security robot: patrol / investigate / chase)
- [x] 3 puzzles, 3 towers, one complete playable mission
- [x] Main menu + pause menu, no critical runtime errors
- [ ] Windows export — on the user's machine (see docs/EXPORT.md);
  export templates are deliberately not installed on this VM
- Phase 2: stop snap (full stop < 1 px/s after release), diagonal speed capped
  at 200, `is_moving` state (measured from real displacement since v1.1 —
  velocity stays (-200, 0) on a wall slide), real 4-frame directional walk
  cycles at 8 FPS (v1.1) + procedural walk bob (1 px, distance-based),
  camera look-ahead 24 px toward movement (returns to center when idle)
- Phase 3: `interact` action (E), nearest-interactable system (40 px range),
  2 consoles (atlas computer towers) + 1 door toggling an alcove (Console B
  inside), HUD prompt + 3 s message, floor variation (15% cracked tiles,
  seeded), wall edge highlights
- Phase 4: `radar_pulse` action (Q), expanding ring (160 px max, 320 px/s,
  5 s cooldown), 2 hidden objects revealed as the front passes them
  (energy cell, battery), HUD radar status (ready/recharging),
  `pulse_emitted` signal as the Phase 5 investigation hook; since v1.1
  the reveal needs line of sight (walls/crates block it) while enemy
  investigation stays radius-based (they hear the pulse)
- Phase 5: security robot (atlas gold robot), enum FSM with 3 states
  (patrol 70 / investigate 110 / chase 140 px/s), vision cone ±0.7 rad +
  100 px radius + raycast line of sight, pulse investigation (goes to the
  exact pulse origin, scans 2 s, returns to patrol; since v1.1 only when
  within the emitted pulse radius), catch = respawn at the entrance with
  a HUD message, red vision cone drawn on screen; since v1.1 the robot
  navigates with AStarGrid2D (crate/prop-inflated grid) and a second
  archetype, the Scanner robot (stationary, rotating 360° watch,
  180 px / ±1.2 rad, slower chase), patrols the Medical Wing
- Phase 6: battery (100 max, 0.5/s drain, radar costs 15, blocked below
  cost, low warning at 25), inventory Dictionary {item_id: count},
  pickups: 1 visible energy cell + 2 hidden objects collectible after
  reveal (each +40 battery), HUD battery bar + inventory list
- Phase 7: 3 interactive electrical puzzles — breaker panel (flip 3
  switches in order 2-1-3, clue on Console A, wrong flip resets),
  wire panel (flip a terminal advances it and the next one; all three
  must read green, clue on Console B), fuse box (needs a fuse item,
  consumed on use; hidden fuse at (600, 100)). HUD puzzle counter 0/3
- Phase 8: 3 communication towers (satellite dish / radar dish / signal
  beacon, atlas rows 4553 / 4556 / 2679), each gated by one puzzle
  (breaker→Tower 1, wire→Tower 2, fuse→Tower 3); mission tracker with
  3 stages (puzzles → towers → transmit) + HUD objective line; the
  TransmitConsole sends the emergency signal once all towers are online
  ("MISSION COMPLETE"), game keeps running in a sandbox after that
- Phase 9: main menu (title, Start/Quit, controls list — now the
  project's main scene) + pause menu (Esc, Resume/Restart/Main Menu,
  process_mode ALWAYS); procedural audio (9 sounds generated in code,
  no audio files: click/blip/pulse/chime/error/sting/tower/fanfare +
  looping 55 Hz ambient drone) wired to pulse, pickups, puzzle solve /
  wrong flip, tower activation, caught, mission complete; VFX: expanding
  ring on pickup/tower/mission-complete, full-screen flash (red caught,
  green complete), battery bar turns red below 25
- Phase 10: MISSION COMPLETE win screen (pauses the game, Play Again /
  Main Menu); battery-bar micro-opt (0.1-unit steps, 5 updates/s
  instead of 60); Windows Desktop export preset + docs/EXPORT.md;
  capstone full-playthrough test (real interactions only, incl. radar
  revealing the hidden fuse) + win-screen test + effect-spam stress test
- Pixel art pipeline: full atlas (1,405,308 sprites, 398 MB parquet) at `~/workspace/pixel-atlas/`; chosen sprites copied into `assets/sprites/`
- godot-ai editor plugin copied to `addons/godot_ai/` (for the user's Windows editor; NOT active on this VM)

## v1.3 — Persian localization, help & hints, one robot per area (2026-11-12)
- The whole game is Persian now: menus, HUD, objectives, messages,
  area names, item names, interact labels, console logs. Key names
  stay Latin (WASD, E, Q, M, Esc) and counts use Latin digits.
- Font: Vazirmatn Regular (default UI font via project setting) +
  Bold, OFL-licensed, in `assets/fonts/` (v33.003, from
  github.com/rastikerdar/vazirmatn). All UI labels/buttons use RTL
  text direction. Shaping verified with Godot's HarfBuzz engine:
  "سلام" shapes to 3 glyphs (lam-alef ligature).
- Help screen (`scenes/ui/help_screen.tscn`, reusable overlay):
  goal, keys, tips; opened from the main menu and the pause menu
  (Esc closes it first, a second Esc resumes).
- In-game hints: a HUD hint line shows the standing guide for the
  mission stage (which key to press next); entering a new area shows
  that area's hint for 6 s, then the stage hint returns. Cleared on
  mission complete.
- One robot per area (5 total): Central security, Medical scanner,
  Lab security, Power scanner, Yard security. Each security robot
  patrols a rectangle inside its own area (PATROL_RECTS); scanners
  stay at their post.
- Tests: 512 passed, 0 failed (9 new: font, mission stage accessor,
  help screen, menu/pause help buttons, one robot per area, patrol
  rects, stage hint, area-entry hint).

## Windows build (2026-11-12, v1.2)
- Exported from this working copy with Godot 4.7.2 + official 4.7.2
  export templates (installed on this VM at the user's explicit
  request — this reverses the earlier "no templates here" decision).
- Output: `build/windows/LastSignal.exe` (109,224,448 bytes, PE32+
  x86-64) + `LastSignal.pck` (1,637,268 bytes, 610 files) +
  `build/windows/LastSignal_Windows_Latest.zip` (39,618,588 bytes).
- Preset fix: `binary_format/architecture` must be the string
  `"x86_64"` in Godot 4.7.2 — the old int `0` made the exporter look
  for a nonexistent `windows_release_0.exe`. The preset file was
  corrected (was the only change needed to export).
- Not tested on Windows: this VM is Linux; the binary is verified as
  a valid PE32+ x86-64 executable, but no Windows runtime test was run.
- Re-exported 2026-11-12 ~22:40 for v1.3 (Persian, help, 5 robots):
  `LastSignal.exe` (109,224,448 bytes) + `LastSignal.pck`
  (1,807,076 bytes, 618 files incl. the Vazirmatn fonts and the help
  screen) + `LastSignal_Windows_Latest.zip` (39,783,205 bytes).
  Export log: 0 errors.

## v1.2 additions (2026-11-12, all verified by tests)
- Minimap (HUD top-right, 208x151, M toggles): area tints + walls with
  doorway gaps, player dot, three towers by state (offline / powered /
  online), hidden caches only once revealed, enemies only for 6 s after
  a radar pulse that caught them in range (11 tests)
- Real walls: a drawn 16x16 seamless metal panel tile (rivets, top
  highlight) tiled on every wall — code-built area walls and the .tscn
  ring/alcove walls. The atlas has no sci-fi wall segment, so the tile
  was drawn for this project.
- HUD lookup hardened: the level resolves the HUD by sibling path
  (parent Main → "HUD") with group fallback — the group lookup could
  return a stale HUD from a just-freed scene.

## v1.1 fixes (2026-11-12, all verified by tests)
- P1: radar investigation honors the emitted radius (boundary inclusive,
  never interrupts a chase; 5 tests)
- P2: ambient drone loops seamlessly (constant envelope, no 2 s fade);
  SFX keep their decay envelopes; pause/resume + volume control (3 tests)
- P3: real directional walk/idle animations (8 animations, 4 walk frames
  per direction at 8 FPS, frames drawn from the player's own sprite —
  the atlas has no matching walk frames; 8 tests)
- P4: AStarGrid2D enemy pathfinding with crate/prop inflation and direct
  steering fallback (4 tests)
- P5: five connected areas with doorways, tints, props, consoles, entry
  zones (3 tests)
- P6: Scanner robot second archetype (3 tests)
- P7: atlas control panel / fuse box / riveted panel as area props;
  walls and doors remain code-drawn (no sci-fi art in the atlas)
- P8: radar reveal now needs line of sight; investigation stays
  radius-based by design (3 tests)
- P9: docs/comments synced (this file, ARCHITECTURE, TODO, KNOWN_ISSUES,
  DEVELOPMENT_LOG, player.gd and radar_pulse.gd stale comments)
- P10: full regression — 381/381 pass
- P11: Windows export templates were installed on this VM on 2026-11-12
  at the user's explicit request (reversing the earlier "no templates
  here" decision); the v1.2 Windows build was produced — see the
  "Windows build" section above.

## Incomplete features
- None known in the 10 phases + v1.1 fixes. Open items live in
  KNOWN_ISSUES.md (door still code-drawn — the walls got real art in
  v1.2, battery at 0 has no fail state, no inventory cap).

## Current errors
- None. Last test run: 439 passed, 0 failed.

## Verification limits (honest)
- No Godot MCP connection on this VM: godot-ai needs a live Godot editor + `uv`; this VM is headless, so there is no live-editor link. Verification is via the headless test runner + headless game runs, not via MCP tools.
- No visual/screenshot check here (no display/GPU). Movement + collision are proven numerically by tests; how it *looks* must be checked in the user's Windows editor.
- Export templates are NOT installed here (user exports on their own Windows machine).

## Next development task
None — all 10 phases are done. Remaining work is on the user's Windows
machine: export (docs/EXPORT.md) and a human playthrough with sound.
