# Last Signal — Known Issues

## Open

- **Floor tile is generic.** `1002_floor_tile` is a plain dark tile, not a
  sci-fi floor panel. Phase 3 improved it with a cracked variant scattered
  at 15% (seeded) — still generic, but less flat. A better floor can be
  picked from the atlas later (e.g. "concrete slab" candidates exist).
- **Door visual is a placeholder, not atlas art.** The atlas doors are
  wooden/fantasy (rows 1005, 2826, 3747, 4658 — visually inspected); none
  fits a sci-fi station. The door is code-drawn metal with a yellow stripe.
- **Battery at 0 has no fail state.** The radar just stops working;
  movement is unaffected. Phase 9 shipped the menus without adding a
  consequence — whether battery 0 should cause a game over or a
  slowdown is an open design decision, not a scheduled feature.
- **`--quit-after` reports 2 leaked ObjectDB instances** (the ambient
  loop's AudioStreamWAV + playback, still playing when the process is
  killed mid-run). A normal quit frees them — benign, verified with
  `--verbose`.
- **Inventory has no capacity limit.** Any number of items can be carried.
  The survival-crafting skill warns this removes logistics tension — a
  cap (slots/weight) is a Phase 7+ decision, when puzzle items arrive.
- **No true side-profile player art.** The walk cycles are drawn from the
  player's front-facing sprite; left/right are mirrored front views
  (the atlas has no side profiles for this character).
- **No visual check on this VM.** Movement/collision are proven numerically
  by headless tests, but nobody has *seen* the game run. Check in the Windows
  editor before calling the look "done".
- **godot-ai MCP not connected here.** The plugin is in `addons/godot_ai/`
  for the Windows editor; on this VM there is no live-editor link.
- **Export templates not installed here.** User exports on Windows by design.
- **Atlas captions are approximate** (dataset card's own warning: a sprite may
  not match its caption). Every sprite used was visually inspected on a
  contact sheet before use.

## Fixed (v1.2, 2026-11-12)
- **Walls were flat dark placeholders.** The atlas still has no sci-fi
  wall segment (verified across all 1.4M rows), so a 16x16 seamless
  metal panel tile was drawn for this project (paneled steel, rivets,
  top highlight) and tiled on every wall — code-built area walls and
  the .tscn ring/alcove walls. Do NOT claim the walls are atlas art;
  they are drawn art, like the walk frames.
- **No minimap.** The HUD now has a live 208x151 map (M toggles):
  area tints, walls with doorway gaps, player dot, towers by state,
  revealed caches, and enemies only for 6 s after a radar pulse in
  range.
- **Stale HUD race.** The level resolved the HUD with
  `get_first_node_in_group("hud")`, which can return a just-freed
  scene's HUD (queue_free deletes at end of frame; a deferred call
  can run while it still lingers). The level now resolves the HUD by
  sibling path (parent Main → "HUD") with group fallback.

## Fixed (v1.1, 2026-11-12)
- **Radar investigation ignored its radius.** `investigate(origin, _radius)`
  never read `_radius` — every enemy in the level reacted to every pulse.
  Now: distance-checked (boundary inclusive), never interrupts a chase.
- **Ambient audio faded to silence every 2 s.** The decay envelope was
  applied to the looping drone too. Now the ambient is built with a
  constant envelope and loops seamlessly; SFX keep their decay envelopes.
  Pause/resume + volume control added.
- **Radar pulse ignored walls.** Reveal now needs line of sight (raycast
  on the wall layer; bodies excluded). Enemy investigation is
  intentionally still radius-based: enemies hear the pulse.
- **Only one security robot.** A second archetype, the Scanner robot
  (atlas row 949119, single-eye top-down robot), now watches the Medical
  Wing: stationary, rotating 360° cone, 180 px / ±1.2 rad detection,
  slower chase (100 px/s), returns to its post.
- **No enemy pathfinding.** AStarGrid2D on a grid the level builds from
  the real wall/crate/prop geometry, with the crate and solid props
  inflated by one cell (a 12x14 body on a cell-center path wedged on
  the crate's corner at (182, 73) without it). Direct steering remains
  as the fallback when no grid is assigned.
- **Player had no walk animation frames.** The atlas still has no
  matching walk frames (full-atlas search: 17 "walking scientist" rows,
  all single standing poses, 0 sprite sheets; the only other top-down
  candidate, 1090676 "wild hair", is a different-haired standing
  figure). The walk cycles are drawn from the player's own sprite:
  4 frames per direction, leg pixels moved 1 px per pose, up frames
  recolour the face to hair (back view); left/right share the down
  frames with flip_h. No unrelated character was substituted.
- **`is_moving` lied while pushing a wall.** Godot does not zero
  `velocity` on a wall slide, so the walk animation played while the
  player was stuck. Now measured from real displacement.
- **Medical doorway was blocked by the wire panel.** The y 160-192 gap
  left only an 8 px slot next to the panel (16x72 at (600, 204)). The
  doorway moved to y 240-272.
- **Test-runner exit now reports 7 leaked ObjectDB instances** (was 2 in
  v1.0) — AudioStreamWAVs + players from the audio-manager instances
  the tests create; a normal quit frees them. Benign.

## Fixed (Phase 1)
- `motion_mode` only set in `_ready()` → also set in `player.tscn`.
- Two truncated atlas shard downloads → resumed and verified.
- `GDScriptFunctionState` does not exist in Godot 4.7 → runner now uses
  `await call(t)` for sync and async tests alike.

## Fixed (Phase 3)
- `get_tree()` does not exist on SceneTree (the test runner) → runner uses
  its own `get_nodes_in_group()`.
- New PNGs (floor_atlas, console_a/b) had no `.import` files → ran
  `godot --headless --path . --import` once; new sprites need an import
  pass before the first test run that uses them.
