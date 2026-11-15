# Pixel Art Sources — Last Signal

All pixel designs come from this dataset (user's instruction):

- **Dataset:** https://huggingface.co/datasets/Angais/pixel-art-atlas-1.4m
- **Contents:** 1,409,404 synthetic 16x16 game sprites with English captions,
  6,194 subjects. Generated with Krea 2 Turbo + pixel art LoRA.
- **License:** CC0 1.0 (Angais dedication; does not grant rights in third-party
  material/trademarks, and does not override the Krea 2 Community License /
  Acceptable Use Policy — see the dataset card).
- **Local copy:** `~/workspace/pixel-atlas/` — all 15 train shards +
  validation (434 MB parquet, 1,405,308 train rows + 4,096 validation).
  Kept OUTSIDE the Godot project so it is never imported/exported.
- **Caption warning:** captions are approximate labels (dataset card). Every
  sprite used in-game was visually inspected first.

## Sprites used in-game (Phase 1)
| Use | File | Atlas row | Subject / caption |
|-----|------|-----------|-------------------|
| Player | `assets/sprites/characters/player.png` | 952623 (train-010) | scientist / "top-down walking white scientist with a lab coat" |
| Floor | `assets/sprites/environment/floor_tile.png` | 1002 (train-000) | floor tile / "floor tile" |
| Crate | `assets/sprites/props/crate.png` | 309 (train-000) | shipping crate / "weathered wooden shipping crate" |

## Sprites used in-game (Phase 3)
| Use | File | Atlas row | Subject / caption |
|-----|------|-----------|-------------------|
| Floor (plain + cracked) | `assets/sprites/environment/floor_atlas.png` | 1002 + 15119 (train-000) | floor tile / "floor tile" + "cracked floor tile" |
| Console A | `assets/sprites/props/console_a.png` | 6633 | computer tower / "black computer tower with green lights" |
| Console B | `assets/sprites/props/console_b.png` | 145 | computer tower / "blue computer tower" |

Door visual is code-drawn placeholder metal, not atlas art: the atlas doors
(wooden/fantasy, e.g. rows 1005, 2826) do not fit a sci-fi station.

## Sprites used in-game (Phase 4)
| Use | File | Atlas row | Subject / caption |
|-----|------|-----------|-------------------|
| Hidden energy cell | `assets/sprites/props/hidden_energy_cell.png` | 4129 | energy cell / "red energy cell" |
| Hidden battery | `assets/sprites/props/hidden_battery.png` | 1116 | battery / "black battery" |

Both were visually inspected on the Phase 3 props contact sheet. The radar
ring itself is code-drawn (no sprite).

## Sprites used in-game (Phase 5)
| Use | File | Atlas row | Subject / caption |
|-----|------|-----------|-------------------|
| Security robot | `assets/sprites/characters/enemy_robot.png` | 6044 | robot companion / "gold robot" |

Visually inspected on the Phase 3 props contact sheet (index 13). The
variant 6426 is the same gold robot with a different pose — kept as a
candidate for a second enemy type later.

## Sprites used in-game (Phase 7)
| Use | File | Atlas row | Subject / caption |
|-----|------|-----------|-------------------|
| Fuse (hidden pickup) | `assets/sprites/props/fuse.png` | 4172 | fuse / "yellow fuse with a red stripe" |

Chosen from 4 fuse candidates (165 white, 4172 yellow/red stripe, 4282
silver/lightning, 9231 black/red stripe) on a contact sheet — 4172 reads
most clearly as a fuse (yellow body, red stripe, metal caps). The panels
themselves are code-drawn; no atlas panel art was used.

## Sprites used in-game (Phase 8)
| Use | File | Atlas row | Subject / caption |
|-----|------|-----------|-------------------|
| Tower 1 | `assets/sprites/props/tower_1_satellite.png` | 4553 | satellite dish |
| Tower 2 | `assets/sprites/props/tower_2_radar.png` | 4556 | radar dish / red orb on a stand |
| Tower 3 | `assets/sprites/props/tower_3_beacon.png` | 2679 | signal beacon / blue glowing beacon |

Chosen from 5 candidates on a contact sheet (4553, 812 satellite dishes;
4556, 51 radar dishes; 2679 beacon) — the three picked look distinct
from each other; 812 (green dish) and 51 (messy green dish) were passed
over. The TransmitConsole reuses the console_a sprite.

## Candidates inspected (not yet used)
`assets/sprites/atlas-candidates/` — 58 sprites in player/floor/wall/props,
including robot companion, security camera, battery, energy cell, satellite
dish, radar dish, signal beacon, computer tower, door. Extraction script:
`tools/extract.py` (search scripts: `tools/search_all.py`).
