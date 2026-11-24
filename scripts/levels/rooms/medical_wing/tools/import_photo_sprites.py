#!/usr/bin/env python3
"""Convert the 46 small Telegram hospital photos (101x101 JPG, icon on a
pure-black background) into 16x16 transparent PNGs for the medical wing.

Design: docs/room1-clinic-redesign.md §5.2.
  1. Flood-fill from the four edges on near-black (RGB < 16 on all
     channels) — removes the background and the JPEG halo without
     eating dark icon pixels that are not connected to the edge.
  2. Crop to the content bounding box; pad to square; resize to fit
     16x16 with LANCZOS.
  3. 1-px alpha erosion on the cut edge (kills the remaining dark
     fringe); save RGBA PNG.
  4. Wheelchairs (627/640/648/667) and the bed (650) are wider than
     tall: fit to 16 wide, keep aspect.

Usage (from the repo root):
    python3 scripts/levels/rooms/medical_wing/tools/import_photo_sprites.py
Input : ~/workspace/telegram-bot/media/287167626.jpg ... 287167671.jpg
Output: assets/sprites/medical-wing/telegram-photos/<id>_<name>.png
Only PIL is required. Idempotent: re-running overwrites the same files.
"""

import sys
from collections import deque
from pathlib import Path

from PIL import Image

# Photo id -> short descriptive name (identifications from
# docs/room1-telegram-assets-inventory.md §5).
PHOTOS = {
    287167626: "astronaut",
    287167627: "wheelchair_dark",
    287167628: "pill_bottle_redlabel",
    287167629: "medicine_jar_heart",
    287167630: "blister_green",
    287167631: "medicine_jar_blue",
    287167632: "syringe_pink",
    287167633: "bandage_plaster",
    287167634: "bandage_roll",
    287167635: "firstaid_white_green",
    287167636: "firstaid_white_blue",
    287167637: "firstaid_box_cardboard",
    287167638: "iv_bag_orange",
    287167639: "sink_basin",
    287167640: "wheelchair_green",
    287167641: "firstaid_white_red",
    287167642: "blood_bag",
    287167643: "oxygen_tank",
    287167644: "vial_green_small",
    287167645: "syringe_blue",
    287167646: "box_red_white",
    287167647: "medicine_jar_heart_white",
    287167648: "wheelchair_dark2",
    287167649: "syringe_teal",
    287167650: "hospital_bed_iso",
    287167651: "pill_bottle_orangecap",
    287167652: "medicine_bottle_orangecap",
    287167653: "monitor_desktop",
    287167654: "medicine_bottle_whitelabel",
    287167655: "medicine_carton",
    287167656: "blister_pink",
    287167657: "syringe_redwhite",
    287167658: "syringe_redblue",
    287167659: "firstaid_chest_red",
    287167660: "canister_orange",
    287167661: "pill_bottle_orangeband",
    287167662: "firstaid_red",
    287167663: "firstaid_white_redside",
    287167664: "microscope_side",
    287167665: "test_tube_red",
    287167666: "flask_green",
    287167667: "wheelchair_red",
    287167668: "robot_white",
    287167669: "thermometer",
    287167670: "iv_bag_red",
    287167671: "firstaid_white_circle",
}

# Wider-than-tall side-view objects: fit to 16 wide, keep aspect.
WIDE_IDS = {287167627, 287167640, 287167648, 287167667, 287167650}

SRC_DIR = Path.home() / "workspace/telegram-bot/media"
OUT_DIR = Path(__file__).resolve().parents[5] / "assets/sprites/medical-wing/telegram-photos"
NEAR_BLACK = 16


def _is_bg(px) -> bool:
    return px[0] < NEAR_BLACK and px[1] < NEAR_BLACK and px[2] < NEAR_BLACK


def key_out_background(img: Image.Image) -> Image.Image:
    """Flood-fill near-black connected to the edges; everything else
    becomes the alpha mask. Returns an RGBA image."""
    rgb = img.convert("RGB")
    w, h = rgb.size
    px = rgb.load()
    bg = bytearray(w * h)  # 1 = background (to key out)
    queue: deque = deque()
    for x in range(w):
        for y in (0, h - 1):
            if _is_bg(px[x, y]):
                bg[y * w + x] = 1
                queue.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if not bg[y * w + x] and _is_bg(px[x, y]):
                bg[y * w + x] = 1
                queue.append((x, y))
    while queue:
        x, y = queue.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not bg[ny * w + nx]:
                if _is_bg(px[nx, ny]):
                    bg[ny * w + nx] = 1
                    queue.append((nx, ny))
    alpha = Image.new("L", (w, h), 0)
    apx = alpha.load()
    for y in range(h):
        for x in range(w):
            if not bg[y * w + x]:
                apx[x, y] = 255
    out = rgb.convert("RGBA")
    out.putalpha(alpha)
    return out


def erode_alpha_1px(img: Image.Image) -> Image.Image:
    """Clear a 1-px ring of alpha around the content edge."""
    alpha = img.split()[3]
    w, h = alpha.size
    apx = alpha.load()
    edge = []
    for y in range(h):
        for x in range(w):
            if apx[x, y] > 0:
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if not (0 <= nx < w and 0 <= ny < h) or apx[nx, ny] == 0:
                        edge.append((x, y))
                        break
    for x, y in edge:
        apx[x, y] = 0
    img.putalpha(alpha)
    return img


def convert_one(photo_id: int, name: str) -> Path:
    src = SRC_DIR / f"{photo_id}.jpg"
    if not src.exists():
        raise FileNotFoundError(f"missing source photo: {src}")
    img = key_out_background(Image.open(src))
    bbox = img.getbbox()
    if bbox is None:
        raise ValueError(f"photo {photo_id} keyed out to nothing")
    img = img.crop(bbox)
    # Pad to square, then fit to 16x16 with LANCZOS.
    side = max(img.size)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(img, ((side - img.width) // 2, (side - img.height) // 2))
    if photo_id in WIDE_IDS:
        # Wider than tall: fit width to 16, keep aspect (vertical padding).
        new_w = 16
        new_h = max(1, round(img.height * 16 / img.width))
        small = img.resize((new_w, new_h), Image.LANCZOS)
        canvas = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        canvas.paste(small, (0, (16 - new_h) // 2))
    else:
        canvas = canvas.resize((16, 16), Image.LANCZOS)
    canvas = erode_alpha_1px(canvas)
    out = OUT_DIR / f"{photo_id}_{name}.png"
    canvas.save(out)
    return out


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    missing = []
    for photo_id, name in sorted(PHOTOS.items()):
        try:
            out = convert_one(photo_id, name)
            print(f"ok {photo_id} -> {out.name}")
        except Exception as exc:  # noqa: BLE001 - report and continue
            missing.append((photo_id, str(exc)))
            print(f"FAIL {photo_id}: {exc}", file=sys.stderr)
    if missing:
        print(f"{len(missing)} failures", file=sys.stderr)
        return 1
    print(f"converted {len(PHOTOS)} photos to {OUT_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
