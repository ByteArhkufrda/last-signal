# Export — Last Signal (Windows)

The project is built and tested here; the Windows export is done on the
user's own Windows machine (per the agreed division of labor: Muse
builds the project and code, the user exports).

## One-time setup (Windows, Godot 4.7.2)

1. Install Godot 4.7.2 (Standard edition) from
   https://godotengine.org/download — the same version used here.
2. Open the project folder in the editor (import once; it rebuilds the
   `.godot` cache).
3. Editor → Manage Export Templates → Download and Install (one-time,
   ~400 MB). Without this, the Windows export button is disabled.

## Exporting

1. Project → Export… — the **Windows Desktop** preset is already in
   `export_presets.cfg` (runnable, 64-bit, all resources).
2. Pick an output path, e.g. `LastSignal.exe`, and press Export Project.
3. The export produces `LastSignal.exe` + `LastSignal.pck` — keep them
   together; the `.pck` holds all game data.

## Before shipping — quick checklist

- Play the full mission once: menu → Start → solve 3 puzzles → activate
  3 towers → transmit → the MISSION COMPLETE screen appears.
- Check the sound (the headless tests here can't hear anything): radar
  pulse, pickup blip, puzzle chime, tower sound, ambient drone.
- Known placeholders (see `docs/KNOWN_ISSUES.md`): walls and puzzle
  panels are code-drawn, the player has no walk-cycle frames (procedural
  bob only), the radar pulse ignores walls.

## What is NOT needed here

- Export templates are deliberately NOT installed on the Linux VM used
  for development (the user asked to skip them); the export happens on
  Windows only.
