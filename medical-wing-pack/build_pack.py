#!/usr/bin/env python3
"""Last Signal - Medical Wing pixel-art asset pack builder.

Stages (per the design note: build in stages, not all in one image):
  1. floors + walls
  2. furniture + medical equipment
  3. story-critical objects + lighting / effects

Source policy (user's rule): find everything in the Angais/pixel-art-atlas-1.4m
atlas first (CC0, via ~/workspace/pixel-atlas-db/sprites.db + parquet shards);
draw procedurally with PIL only what has no usable atlas match.
Base unit: 16x16 sprite = 1 tile (48px at 3x scale). Big objects are 32x16
(2x1 tiles) or 32x32 (2x2). Sheets use 48px cells, 6px transparent gutters,
3x nearest-neighbour scale. Floor/wall tiles are opaque; props are transparent.

Palette (prompt section 3 + Last Signal house palette):
  off-white #E8EEF7, pale #B8C6DC, light gray #7A8FB0, steel #4A5D7E,
  dark gray #2E3D5E, void #0B0F1A, muted medical green #6FA287,
  monitor green #39D98A, cyan #3EC6E0, soft blue #6B8FD4,
  emergency red #D62839, warning yellow #F4A62A, olive #7A7A52.
"""
import csv, json, os, re, sqlite3
from collections import deque

import pyarrow.parquet as pq
from PIL import Image, ImageDraw

DB = "/home/hatch/workspace/pixel-atlas-db/sprites.db"
SRC = "/home/hatch/workspace/pixel-atlas"
OUT = "/home/hatch/workspace/last-signal/medical-wing-pack"
ATLAS_DIR = os.path.join(OUT, "atlas")
DRAWN_DIR = os.path.join(OUT, "drawn")

# ---- palette ----
OFFWHITE = (232, 238, 247, 255)
PALE = (184, 198, 220, 255)
LGRAY = (122, 143, 176, 255)
STEEL = (74, 93, 126, 255)
DGRAY = (46, 61, 94, 255)
VOID = (11, 15, 26, 255)
MEDGREEN = (111, 162, 135, 255)
MONGREEN = (57, 217, 138, 255)
CYAN = (62, 198, 224, 255)
SOFTBLUE = (107, 143, 212, 255)
RED = (214, 40, 57, 255)
DARKRED = (140, 28, 42, 255)
AMBER = (244, 166, 42, 255)
OLIVE = (122, 122, 82, 255)
WHITE = (244, 247, 251, 255)
BLACK = (16, 20, 32, 255)
SHADOW = (20, 26, 44, 160)

# ---- item table ----
# key, fa_name, stage, w_tiles, h_tiles, opaque, searches, draw_id (None = atlas only)
ITEMS = [
    # ---- stage 1: floors + walls ----
    ("floor_standard", "کف استاندارد پزشکی", 1, 1, 1, True, ["subject:floor tile"], None),
    ("floor_alt", "کف متناوب سفید/خاکستری", 1, 1, 1, True, ["subject:floor tile"], None),
    ("floor_cracked", "کف ترک‌خورده", 1, 1, 1, True, [], "floor_cracked"),
    ("floor_broken", "کف شکسته / کاشی گمشده", 1, 1, 1, True, [], "floor_broken"),
    ("floor_stain_water", "لکه آب", 1, 1, 1, True, [], "floor_stain_water"),
    ("floor_stain_chemical", "لکه شیمیایی", 1, 1, 1, True, [], "floor_stain_chemical"),
    ("floor_footprints", "رد پا", 1, 1, 1, True, [], "floor_footprints"),
    ("floor_wheel_tracks", "رد چرخ تخت", 1, 1, 1, True, [], "floor_wheel_tracks"),
    ("floor_debris", "خرده‌های پزشکی پراکنده", 1, 1, 1, True, [], "floor_debris"),
    ("floor_hatch", "دریچه فلزی کف", 1, 1, 1, True, [], "floor_hatch"),
    ("floor_grille", "گریل تهویه کف", 1, 1, 1, True, [], "floor_grille"),
    ("floor_panel", "پنل نگهداری کف", 1, 1, 1, True, [], "floor_panel"),
    ("wall_h", "دیوار افقی", 1, 1, 1, True, [], "wall_h"),
    ("wall_v", "دیوار عمودی", 1, 1, 1, True, [], "wall_v"),
    ("wall_corner_inner", "گوشه داخلی دیوار", 1, 1, 1, True, [], "wall_corner_inner"),
    ("wall_corner_outer", "گوشه خارجی دیوار", 1, 1, 1, True, [], "wall_corner_outer"),
    ("wall_end", "انتهای دیوار", 1, 1, 1, True, [], "wall_end"),
    ("wall_trim", "تریم فلزی دیوار", 1, 1, 1, True, [], "wall_trim"),
    ("wall_access_panel", "پنل دسترسی دیوار", 1, 1, 1, True, [], "wall_access_panel"),
    ("wall_cabinet_section", "کابینت دیواری توکار", 1, 1, 1, True, [], "wall_cabinet_section"),
    ("window_observation", "پنجره مشاهده بزرگ", 1, 2, 1, True, ["subject:window"], None),
    ("window_small", "پنجره کوچک تقویت‌شده", 1, 1, 1, True, ["subject:window"], None),
    ("door_closed", "در اتوماتیک بسته", 1, 1, 1, True, ["subject:door"], None),
    ("door_open", "در اتوماتیک باز", 1, 1, 1, True, [], "door_open"),
    ("door_frame", "چارچوب در پزشکی", 1, 1, 1, True, [], "door_frame"),
    # ---- stage 2: furniture + equipment ----
    ("bed_standard", "تخت بیمارستان استاندارد", 2, 2, 1, False, ["subject:bed"], None),
    ("bed_empty", "تخت خالی", 2, 2, 1, False, ["subject:bed"], None),
    ("bed_disorganized", "تخت با ملحفه به‌هم‌ریخته", 2, 2, 1, False, ["subject:bed"], "bed_sheets"),
    ("bedside_table", "میز کنار تخت", 2, 1, 1, False, ["subj_like:bedside", "subject:table"], None),
    ("exam_bed", "تخت معاینه قابل‌تنظیم", 2, 2, 1, False, ["subject:bed"], None),
    ("stretcher", "برانکارد چرخ‌دار", 2, 2, 1, False, ["subject:stretcher"], None),
    ("chair_rolling", "صندلی چرخ‌دار پزشکی", 2, 1, 1, False, ["subject:chair"], None),
    ("desk_doctor", "میز دکتر", 2, 2, 1, False, ["subject:desk"], None),
    ("chair_office", "صندلی اداری", 2, 1, 1, False, ["subject:chair"], None),
    ("side_table", "میز کوچک پزشکی", 2, 1, 1, False, ["subject:table"], None),
    ("trolley", "ترولی لوازم پزشکی", 2, 1, 1, False, [], "cart"),
    ("monitor_vitals", "مانیتور علائم حیاتی", 2, 1, 1, False, ["subj_like:computer monitor", "subject:monitor"], None),
    ("monitor_heart", "مانیتور قلب قابل‌حمل", 2, 1, 1, False, ["subj_like:monitor", "subject:computer tower"], None),
    ("oxygen_cylinder", "کپسول اکسیژن", 2, 1, 1, False, ["subject:oxygen tank"], None),
    ("oxygen_unit", "واحد تأمین اکسیژن", 2, 1, 1, False, ["subject:oxygen tank"], None),
    ("iv_stand", "پایه سرم با کیسه", 2, 1, 1, False, ["subject:IV stand", "cap_like:IV stand"], None),
    ("infusion_pump", "پمپ تزریق", 2, 1, 1, False, [], "infusion_pump"),
    ("exam_lamp", "چراغ معاینه", 2, 1, 1, False, ["subject:desk lamp"], None),
    ("cart_emergency", "ترولی اورژانس", 2, 1, 1, False, [], "cart"),
    ("defibrillator", "دفیبریلاتور", 2, 1, 1, False, ["subject:defibrillator"], None),
    ("waste_bin", "سطل زباله پزشکی", 2, 1, 1, False, ["subj_like:trash", "subj_like:bin"], None),
    ("cabinet_storage", "کابینت ذخیره پزشکی", 2, 1, 1, False, ["subject:cabinet"], None),
    ("cabinet_medicine", "کابینت دارو", 2, 1, 1, False, ["subject:cabinet"], None),
    ("shelf_medicine", "قفسه دارو", 2, 1, 1, False, ["subject:wall shelf"], "shelf_medicine"),
    ("supply_boxes", "جعبه‌های لوازم پزشکی", 2, 1, 1, False, ["subject:box of bandages", "subject:crate"], None),
    ("documents", "اسناد پزشکی پراکنده", 2, 1, 1, False, [], "documents"),
    ("bottles_medicine", "بطری‌های دارو", 2, 1, 1, False, ["subject:bottle"], None),
    ("packages_medicine", "بسته‌های دارو", 2, 1, 1, False, ["subject:blister pack of pills", "subject:pill bottle"], None),
    ("gloves", "دستکش پزشکی", 2, 1, 1, False, ["subject:gloves"], None),
    ("bandages", "بسته بانداژ", 2, 1, 1, False, ["subject:adhesive bandage", "subject:bandage roll"], None),
    ("syringes", "سرنگ یک‌بارمصرف", 2, 1, 1, False, ["subject:syringe"], None),
    ("tray_instruments", "سینی ابزار", 2, 1, 1, False, [], "tray"),
    ("clock_wall", "ساعت دیواری", 2, 1, 1, False, ["subject:clock icon", "subject:alarm clock"], None),
    ("sign_warning", "تابلوی هشدار پزشکی", 2, 1, 1, False, [], "sign_warning"),
    ("light_ceiling", "چراغ سقفی پزشکی", 2, 1, 1, False, ["subject:ceiling lamp"], None),
    ("indicator_emergency", "چراغ نشانگر اضطراری", 2, 1, 1, False, [], "indicator_red"),
    ("grille_vent", "گریل تهویه دیواری", 2, 1, 1, False, ["subj_like:vent"], None),
    ("panel_wall_small", "پنل کنترل دیواری کوچک", 2, 1, 1, False, [], "panel_small"),
    # ---- stage 3: story + lighting ----
    ("cabinet_closed", "کمد فلزی بسته (فیوز A)", 3, 1, 1, False, ["subject:cabinet"], None),
    ("cabinet_open", "کمد باز با قفسه‌ها", 3, 1, 1, False, [], "cabinet_open"),
    ("cabinet_worn", "کمد فلزی فرسوده", 3, 1, 1, False, ["subject:cabinet"], None),
    ("fuse_a", "فیوز A — سفید", 3, 1, 1, False, ["row:165"], None),
    ("fuse_b", "فیوز B — زرد با نوار قرمز", 3, 1, 1, False, ["row:4172"], None),
    ("fuse_c", "فیوز C — نقره‌ای با نماد برق", 3, 1, 1, False, ["row:4282"], None),
    ("flashlight", "چراغ‌قوه روی میز دکتر", 3, 1, 1, False, ["subject:flashlight"], None),
    ("note_doctor", "یادداشت دست‌نویس دکتر", 3, 1, 1, False, ["subj_like:note", "subj_like:paper note"], None),
    ("fusebox_closed", "جعبه فیوز بسته", 3, 1, 1, False, [], "fusebox_closed"),
    ("fusebox_open", "جعبه فیوز باز — ۳ شیار خالی", 3, 1, 1, False, [], "fusebox_open"),
    ("light_blue", "چراغ آبی ملایم سقفی", 3, 1, 1, False, [], "light_blue"),
    ("light_green", "چراغ سبز نشانگر پزشکی", 3, 1, 1, False, [], "light_green"),
    ("light_red", "چراغ قرمز اضطراری", 3, 1, 1, False, [], "light_red"),
    ("light_flicker", "چراغ چشمک‌زن", 3, 1, 1, False, [], "light_flicker"),
    ("light_damaged", "چراغ سقفی آسیب‌دیده", 3, 1, 1, False, [], "light_damaged"),
    ("spark", "جرقه الکتریکی", 3, 1, 1, False, ["subject:spark burst", "subject:fire spark"], None),
    ("steam", "بخار تهویه", 3, 1, 1, False, [], "steam"),
    ("dust", "ذرات غبار", 3, 1, 1, False, ["subject:dust puff", "subject:dust bunny"], None),
    ("paper_scattered", "کاغذهای پراکنده (شواهد تخلیه)", 3, 1, 1, False, [], "paper_scattered"),
    ("chair_fallen", "صندلی افتاده", 3, 1, 1, False, [], "chair_fallen"),
]


def slug(s):
    s = re.sub(r"[^a-z0-9]+", "_", s.lower()).strip("_")
    return s[:50] or "sprite"


def find_candidates(con, term, limit=60):
    kind, q = term.split(":", 1)
    if kind == "subject":
        rows = con.execute(
            "SELECT split,row_id,shard,caption,subject FROM sprites WHERE subject=? ORDER BY row_id LIMIT ?",
            (q, limit)).fetchall()
    elif kind == "row":
        rows = con.execute(
            "SELECT split,row_id,shard,caption,subject FROM sprites WHERE row_id=? LIMIT 1",
            (int(q),)).fetchall()
    elif kind == "subj_like":
        rows = con.execute(
            "SELECT split,row_id,shard,caption,subject FROM sprites WHERE subject LIKE ? ORDER BY row_id LIMIT ?",
            (f"%{q}%", limit)).fetchall()
    elif kind == "cap_like":
        rows = con.execute(
            "SELECT split,row_id,shard,caption,subject FROM sprites WHERE caption LIKE ? ORDER BY row_id LIMIT ?",
            (f"%{q}%", limit)).fetchall()
    else:
        rows = []
    return rows


GOOD_WORDS = ["metal", "steel", "chrome", "glass", "white", "modern", "futuristic",
               "sci-fi", "medical", "hospital", "electric", "silver", "gray", "grey",
               "plastic", "digital", "clean", "spotless", "sleek", "compact",
               "blue", "green"]
BAD_WORDS = ["wooden", "wood", "vine", "cobweb", "castle", "medieval", "fantasy",
             "pumpkin", "hay", "carton", "toilet", "hatbox", "mahogany", "walnut",
             "rustic", "carved", "floral", "locomotive", "monster", "skull",
             "boot", "shoe", "hat", "vase", "barrel", "straw", "leather",
             "fancy", "gold trim", "old", "pine", "varnish", "clay", "bronze",
             "solar", "weathered", "crumbling", "chipped", "broken", "rusty",
             "orange", "pink", "food", "feast", "mossy", "moss", "snow",
             "vines", "ancient", "dusty", "enchanted", "lantern", "tram",
             "tackle", "dripping", "cracked", "missing", "damaged", "suede",
             "scuffed", "corroded", "scorch", "antique", "birch"]


def _word_hit(text, term):
    return re.search(r"\b" + re.escape(term) + r"\b", text or "", re.I) is not None


def caption_score(caption, subject):
    text = f"{caption or ''} {subject or ''}".lower()
    s = 0
    for w in GOOD_WORDS:
        if w in text:
            s += 2
    for w in BAD_WORDS:
        if w in text:
            s -= 4
    if "top-down" in text:
        s += 3
    return s


class Atlas:
    def __init__(self, con):
        self.con = con
        self.cache = {}
        self.used = set()

    def get_image_bytes(self, shard, row_id):
        if shard not in self.cache:
            self.cache[shard] = pq.read_table(os.path.join(SRC, shard), columns=["image", "row_id"])
        t = self.cache[shard]
        key = shard + "_idx"
        if key not in self.cache:
            self.cache[key] = {r: i for i, r in enumerate(t.column("row_id").to_pylist())}
        idx = self.cache[key].get(row_id)
        if idx is None:
            return None
        return t.column("image").to_pylist()[idx]["bytes"]

    def pick(self, searches, prefer_topdown=True):
        """Return (row, img_bytes, term) for the best unused match, else None.
        subj_like/cap_like must match as whole words (kills the 'vent' in
        'adventurer', 'cart' in 'carton', 'iv' in 'locomotive' traps), and
        candidates are scored for sci-fi medical fit before picking."""
        for term in searches:
            kind, q = term.split(":", 1)
            cands = find_candidates(self.con, term)
            if kind in ("subj_like", "cap_like"):
                field = 4 if kind == "subj_like" else 3  # subject / caption col
                cands = [c for c in cands if _word_hit(c[field], q)]
            cands.sort(key=lambda r: (-caption_score(r[3], r[4]),
                                      0 if "top-down" in (r[3] or "").lower() else 1,
                                      r[1]))
            for c in cands:
                if c[1] not in self.used:
                    img = self.get_image_bytes(c[2], c[1])
                    if img is None:
                        continue
                    self.used.add(c[1])
                    return c, img, term
        return None


def normalize_transparency(img, opaque):
    """Atlas sprites sometimes sit on a solid background. If all four corners
    share one opaque colour, flood-fill that colour from the border to alpha.
    Opaque tiles (floor/wall) are never touched."""
    img = img.convert("RGBA")
    if opaque:
        return img
    w, h = img.size
    px = img.load()
    corners = [px[0, 0], px[w - 1, 0], px[0, h - 1], px[w - 1, h - 1]]
    if len(set(corners)) != 1 or corners[0][3] == 0:
        return img
    bg = corners[0][:3]
    # only treat it as background if it is a near-uniform flat colour
    seen = set()
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            if px[x, y][:3] == bg:
                q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if px[x, y][:3] == bg:
                q.append((x, y))
    while q:
        x, y = q.popleft()
        if (x, y) in seen or not (0 <= x < w and 0 <= y < h):
            continue
        if px[x, y][:3] != bg:
            continue
        seen.add((x, y))
        px[x, y] = (0, 0, 0, 0)
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen:
                q.append((nx, ny))
    return img


# ---- procedural drawing (only for items with no usable atlas match) ----
def new(w, h):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def R(d, x, y, w, h, c):
    d.rectangle([x, y, x + w - 1, y + h - 1], fill=c)


def P(d, x, y, c):
    d.point((x, y), fill=c)


def base_floor():
    img, d = new(16, 16)
    R(d, 0, 0, 16, 16, OFFWHITE)
    # subtle alternating tone + seams on top/left edges only (seamless tiling)
    R(d, 0, 0, 16, 1, PALE)
    R(d, 0, 0, 1, 16, PALE)
    R(d, 8, 0, 1, 16, (200, 210, 228, 255))
    R(d, 0, 8, 16, 1, (200, 210, 228, 255))
    P(d, 3, 3, (225, 232, 242, 255))
    P(d, 11, 11, (225, 232, 242, 255))
    return img, d


def base_wall():
    img, d = new(16, 16)
    R(d, 0, 0, 16, 16, WHITE)
    R(d, 0, 0, 16, 2, PALE)
    R(d, 0, 14, 16, 2, STEEL)  # wall-to-floor trim
    R(d, 0, 13, 16, 1, LGRAY)
    P(d, 3, 6, LGRAY)
    P(d, 12, 6, LGRAY)
    P(d, 3, 10, LGRAY)
    P(d, 12, 10, LGRAY)
    return img, d


def draw_floor_cracked(w, h):
    img, d = base_floor()
    # dark crack lines branching from the top-right corner
    for x, y in [(12, 1), (11, 2), (10, 3), (9, 4), (8, 5), (7, 6), (9, 5), (10, 6), (11, 7), (6, 7), (5, 8), (4, 9), (13, 3), (14, 4), (13, 5)]:
        P(d, x, y, DGRAY)
    P(d, 8, 4, BLACK)
    P(d, 5, 8, BLACK)
    return img


def draw_floor_broken(w, h):
    img, d = base_floor()
    # missing tile corner (bottom-right) + ceramic fragments
    R(d, 10, 10, 6, 6, DGRAY)
    R(d, 11, 11, 4, 4, VOID)
    for x, y in [(9, 12), (12, 9), (8, 14), (13, 13), (7, 10)]:
        P(d, x, y, PALE)
    P(d, 9, 13, WHITE)
    P(d, 12, 12, (160, 170, 190, 255))
    return img


def draw_floor_stain_water(w, h):
    img, d = base_floor()
    blob = [(5, 8), (6, 8), (7, 8), (8, 8), (5, 9), (6, 9), (7, 9), (8, 9), (9, 9), (6, 10), (7, 10), (8, 10), (7, 11)]
    for x, y in blob:
        P(d, x, y, (150, 180, 205, 255))
    P(d, 6, 9, (170, 200, 225, 255))
    P(d, 8, 9, (170, 200, 225, 255))
    return img


def draw_floor_stain_chemical(w, h):
    img, d = base_floor()
    blob = [(4, 5), (5, 5), (6, 5), (4, 6), (5, 6), (6, 6), (7, 6), (5, 7), (6, 7), (6, 8)]
    for x, y in blob:
        P(d, x, y, (140, 160, 90, 255))
    P(d, 5, 6, (170, 190, 110, 255))
    P(d, 10, 10, (150, 170, 100, 255))
    P(d, 11, 11, (140, 160, 90, 255))
    return img


def draw_floor_footprints(w, h):
    img, d = base_floor()
    for y in (2, 6, 10, 14):
        P(d, 5, y, (170, 180, 200, 255))
        P(d, 6, y, (170, 180, 200, 255))
        P(d, 10, y + 2, (170, 180, 200, 255))
        P(d, 11, y + 2, (170, 180, 200, 255))
    return img


def draw_floor_wheel_tracks(w, h):
    img, d = base_floor()
    for y in range(1, 15):
        P(d, 4, y, (165, 175, 195, 255))
        P(d, 11, y, (165, 175, 195, 255))
    return img


def draw_floor_debris(w, h):
    img, d = base_floor()
    R(d, 3, 4, 3, 2, WHITE)          # paper scrap
    P(d, 4, 4, LGRAY)
    R(d, 10, 9, 2, 2, AMBER)         # pill
    P(d, 12, 12, RED)                # small cap
    P(d, 6, 11, STEEL)
    P(d, 7, 12, STEEL)
    R(d, 12, 3, 2, 3, MEDGREEN)     # bottle shard
    return img


def draw_floor_grille(w, h):
    img, d = base_floor()
    R(d, 2, 2, 12, 12, DGRAY)
    R(d, 3, 3, 10, 10, STEEL)
    for y in (5, 7, 9, 11):
        R(d, 4, y, 8, 1, BLACK)
    for x, y in [(2, 2), (13, 2), (2, 13), (13, 13)]:
        P(d, x, y, BLACK)
    return img


def draw_floor_hatch(w, h):
    img, d = base_floor()
    R(d, 2, 2, 12, 12, LGRAY)
    R(d, 3, 3, 10, 10, STEEL)
    R(d, 4, 4, 8, 8, DGRAY)
    for x, y in [(2, 2), (13, 2), (2, 13), (13, 13)]:
        P(d, x, y, BLACK)
    R(d, 7, 7, 2, 2, BLACK)  # handle slot
    return img


def draw_floor_panel(w, h):
    img, d = base_floor()
    R(d, 3, 3, 10, 10, PALE)
    R(d, 4, 4, 8, 8, LGRAY)
    for x, y in [(3, 3), (12, 3), (3, 12), (12, 12)]:
        P(d, x, y, DGRAY)
    R(d, 6, 7, 4, 2, STEEL)
    return img


def draw_wall_corner_inner(w, h):
    img, d = base_wall()
    R(d, 0, 0, 6, 16, DGRAY)
    R(d, 0, 0, 16, 6, DGRAY)
    R(d, 6, 0, 1, 16, STEEL)
    R(d, 0, 6, 16, 1, STEEL)
    R(d, 6, 6, 1, 1, LGRAY)
    return img


def draw_wall_corner_outer(w, h):
    img, d = base_wall()
    R(d, 0, 10, 16, 6, STEEL)
    R(d, 10, 0, 6, 16, STEEL)
    R(d, 10, 10, 6, 6, DGRAY)
    R(d, 0, 14, 16, 2, DGRAY)
    return img


def draw_wall_end(w, h):
    img, d = base_wall()
    R(d, 12, 0, 4, 16, DGRAY)
    R(d, 11, 0, 1, 16, STEEL)
    R(d, 12, 0, 4, 2, PALE)
    return img


def draw_wall_trim(w, h):
    img, d = base_wall()
    R(d, 0, 6, 16, 3, LGRAY)
    R(d, 0, 6, 16, 1, STEEL)
    R(d, 0, 8, 16, 1, STEEL)
    for x in (2, 6, 10, 14):
        P(d, x, 7, DGRAY)
    return img


def draw_wall_access_panel(w, h):
    img, d = base_wall()
    R(d, 3, 3, 10, 8, PALE)
    R(d, 4, 4, 8, 6, LGRAY)
    for x, y in [(3, 3), (12, 3), (3, 10), (12, 10)]:
        P(d, x, y, DGRAY)
    R(d, 6, 6, 4, 2, STEEL)
    P(d, 7, 6, MONGREEN)
    return img


def draw_wall_cabinet_section(w, h):
    img, d = base_wall()
    R(d, 2, 2, 12, 10, LGRAY)
    R(d, 3, 3, 5, 8, PALE)
    R(d, 8, 3, 5, 8, PALE)
    R(d, 7, 3, 1, 8, STEEL)
    P(d, 6, 6, DGRAY)
    P(d, 9, 6, DGRAY)
    return img


def draw_door_open(w, h):
    img, d = new(16, 16)
    R(d, 0, 0, 16, 16, (0, 0, 0, 0))
    R(d, 0, 0, 3, 16, STEEL)   # frame left
    R(d, 13, 0, 3, 16, STEEL)  # frame right
    R(d, 0, 0, 16, 2, STEEL)   # header
    R(d, 3, 2, 2, 14, LGRAY)   # slid-open panel left
    R(d, 11, 2, 2, 14, LGRAY)  # slid-open panel right
    R(d, 5, 2, 6, 14, VOID)    # open passage (dark)
    R(d, 6, 0, 4, 1, MONGREEN)  # green open indicator
    return img


def draw_door_frame(w, h):
    img, d = new(16, 16)
    R(d, 0, 0, 16, 16, (0, 0, 0, 0))
    R(d, 0, 0, 3, 16, STEEL)
    R(d, 13, 0, 3, 16, STEEL)
    R(d, 0, 0, 16, 2, STEEL)
    R(d, 3, 2, 10, 14, (0, 0, 0, 0))
    P(d, 1, 6, MONGREEN)
    P(d, 14, 6, MONGREEN)
    return img


def draw_bed_sheets(w, h):
    # 32x16: bed frame + mattress + disorganized sheets + pillow askew
    img, d = new(32, 16)
    R(d, 1, 2, 30, 12, STEEL)
    R(d, 2, 3, 28, 10, OFFWHITE)
    R(d, 2, 3, 7, 10, PALE)        # pillow area
    R(d, 4, 5, 4, 6, WHITE)         # pillow, askew
    R(d, 9, 3, 21, 10, (210, 225, 238, 255))  # sheet, rumpled
    R(d, 12, 6, 6, 4, (190, 205, 225, 255))
    R(d, 20, 9, 7, 4, (190, 205, 225, 255))
    R(d, 2, 13, 2, 2, DGRAY)       # wheels
    R(d, 28, 13, 2, 2, DGRAY)
    P(d, 15, 4, LGRAY)
    P(d, 24, 5, LGRAY)
    return img


def draw_infusion_pump(w, h):
    img, d = new(16, 16)
    R(d, 7, 1, 2, 14, LGRAY)       # pole
    R(d, 5, 12, 6, 2, DGRAY)       # base
    R(d, 4, 3, 8, 6, STEEL)        # pump body
    R(d, 5, 4, 6, 3, DGRAY)        # screen
    P(d, 6, 5, MONGREEN)
    P(d, 8, 5, AMBER)
    R(d, 11, 9, 1, 5, CYAN)        # tube
    P(d, 11, 14, CYAN)
    return img


def draw_tray(w, h):
    img, d = new(16, 16)
    R(d, 2, 5, 12, 8, LGRAY)
    R(d, 3, 6, 10, 6, PALE)
    R(d, 4, 7, 6, 1, STEEL)        # scalpel
    P(d, 10, 7, STEEL)
    R(d, 4, 9, 3, 2, WHITE)        # gauze
    R(d, 9, 9, 3, 2, AMBER)        # small pack
    return img


def draw_sign_warning(w, h):
    img, d = new(16, 16)
    R(d, 3, 2, 10, 12, AMBER)
    R(d, 4, 3, 8, 10, (250, 200, 80, 255))
    R(d, 7, 5, 2, 4, BLACK)
    P(d, 7, 10, BLACK)
    P(d, 8, 10, BLACK)
    R(d, 3, 2, 10, 1, BLACK)
    return img


def draw_indicator_red(w, h):
    img, d = new(16, 16)
    R(d, 6, 2, 4, 4, DGRAY)
    R(d, 7, 3, 2, 2, RED)
    P(d, 7, 3, (255, 120, 120, 255))
    R(d, 6, 8, 4, 6, STEEL)
    P(d, 7, 10, LGRAY)
    return img


def draw_cabinet_open(w, h):
    img, d = new(16, 16)
    R(d, 2, 1, 12, 14, STEEL)      # body
    R(d, 3, 2, 10, 12, DGRAY)      # interior
    R(d, 3, 6, 10, 1, LGRAY)       # shelf
    R(d, 3, 10, 10, 1, LGRAY)      # shelf
    R(d, 4, 3, 2, 2, WHITE)        # box
    R(d, 9, 3, 2, 2, MEDGREEN)     # bottle
    R(d, 5, 7, 2, 2, AMBER)        # small fuse visible on middle shelf
    P(d, 5, 7, RED)
    R(d, 0, 2, 2, 12, LGRAY)       # open door left
    R(d, 14, 2, 2, 12, LGRAY)      # open door right
    P(d, 1, 8, DGRAY)
    P(d, 14, 8, DGRAY)
    return img


def draw_fusebox_closed(w, h):
    img, d = new(16, 16)
    R(d, 3, 2, 10, 12, DGRAY)
    R(d, 4, 3, 8, 10, STEEL)
    R(d, 5, 4, 6, 8, LGRAY)
    R(d, 6, 6, 1, 4, DGRAY)
    R(d, 9, 6, 1, 4, DGRAY)
    P(d, 7, 4, RED)                # warning indicator
    P(d, 5, 12, AMBER)
    R(d, 3, 2, 10, 1, PALE)
    return img


def draw_fusebox_open(w, h):
    img, d = new(16, 16)
    R(d, 3, 2, 10, 12, DGRAY)
    R(d, 4, 3, 8, 10, (30, 40, 60, 255))  # interior
    # three empty fuse slots
    for sx in (5, 7, 9):
        R(d, sx, 5, 2, 4, BLACK)
        R(d, sx, 5, 2, 1, LGRAY)
    R(d, 5, 10, 6, 1, MONGREEN)    # circuit trace
    P(d, 6, 10, CYAN)
    P(d, 10, 10, CYAN)
    P(d, 12, 4, RED)               # emergency indicator
    P(d, 12, 12, AMBER)
    R(d, 3, 2, 10, 1, PALE)
    return img


def draw_light_blue(w, h):
    img, d = new(16, 16)
    R(d, 3, 5, 10, 4, LGRAY)
    R(d, 4, 6, 8, 2, (170, 205, 245, 255))
    P(d, 5, 6, WHITE)
    P(d, 8, 6, WHITE)
    R(d, 2, 4, 12, 1, STEEL)
    R(d, 2, 9, 12, 1, STEEL)
    return img


def draw_light_green(w, h):
    img, d = new(16, 16)
    R(d, 6, 6, 4, 4, DGRAY)
    R(d, 7, 7, 2, 2, MONGREEN)
    P(d, 7, 7, (200, 255, 220, 255))
    R(d, 5, 11, 6, 2, STEEL)
    return img


def draw_light_red(w, h):
    img, d = new(16, 16)
    R(d, 6, 6, 4, 4, DGRAY)
    R(d, 7, 7, 2, 2, RED)
    P(d, 7, 7, (255, 140, 140, 255))
    R(d, 5, 11, 6, 2, STEEL)
    return img


def draw_light_flicker(w, h):
    img, d = new(16, 16)
    R(d, 3, 5, 10, 4, LGRAY)
    R(d, 4, 6, 3, 2, (170, 205, 245, 255))
    R(d, 9, 6, 3, 2, (120, 140, 165, 255))  # half-lit, flickering
    P(d, 5, 6, WHITE)
    R(d, 2, 4, 12, 1, STEEL)
    R(d, 2, 9, 12, 1, STEEL)
    return img


def draw_light_damaged(w, h):
    img, d = new(16, 16)
    R(d, 3, 5, 10, 4, LGRAY)
    R(d, 4, 6, 8, 2, (90, 100, 120, 255))   # dead tube
    R(d, 7, 6, 2, 2, DGRAY)
    P(d, 9, 5, BLACK)
    R(d, 2, 4, 12, 1, STEEL)
    R(d, 11, 9, 1, 3, STEEL)       # hanging wire
    return img


def draw_chair_fallen(w, h):
    img, d = new(16, 16)
    R(d, 3, 8, 10, 3, STEEL)       # seat on its side
    R(d, 3, 11, 10, 2, DGRAY)
    R(d, 12, 5, 2, 6, LGRAY)       # backrest, tipped over
    P(d, 5, 7, PALE)
    P(d, 8, 7, PALE)
    R(d, 2, 6, 2, 2, BLACK)        # wheel
    return img


def draw_cart(w, h):
    # medical trolley / emergency cart: steel frame, two shelves, red cross
    img, d = new(16, 16)
    R(d, 3, 2, 10, 2, STEEL)       # top shelf
    R(d, 3, 8, 10, 2, STEEL)       # bottom shelf
    R(d, 3, 2, 1, 12, LGRAY)       # legs
    R(d, 12, 2, 1, 12, LGRAY)
    R(d, 4, 3, 3, 2, WHITE)        # box on top shelf
    R(d, 9, 3, 2, 2, MEDGREEN)     # bottle
    R(d, 5, 9, 4, 2, RED)          # red cross panel
    P(d, 6, 9, WHITE)
    P(d, 7, 10, WHITE)
    R(d, 4, 14, 2, 2, DGRAY)       # wheels
    R(d, 10, 14, 2, 2, DGRAY)
    return img


def draw_steam(w, h):
    img, d = new(16, 16)
    puffs = [(5, 10), (6, 10), (7, 9), (8, 9), (9, 8), (10, 8), (7, 11), (8, 11), (9, 10), (6, 8), (10, 6), (11, 6)]
    for x, y in puffs:
        P(d, x, y, (210, 220, 235, 220))
    P(d, 7, 9, (235, 240, 248, 235))
    P(d, 9, 8, (235, 240, 248, 235))
    P(d, 5, 12, (190, 200, 215, 200))
    return img


def draw_wall_h(w, h):
    img, d = base_wall()
    # horizontal wall segment: panel joints + top highlight
    for x in (5, 10):
        R(d, x, 2, 1, 11, LGRAY)
    P(d, 2, 4, STEEL)
    P(d, 8, 4, STEEL)
    P(d, 13, 4, STEEL)
    return img


def draw_wall_v(w, h):
    img, d = base_wall()
    # vertical wall segment: steel side strip + vertical joints
    R(d, 0, 0, 2, 16, STEEL)
    R(d, 13, 0, 2, 16, STEEL)
    for y in (5, 10):
        R(d, 2, y, 11, 1, LGRAY)
    P(d, 8, 4, STEEL)
    P(d, 8, 12, STEEL)
    return img


def draw_documents(w, h):
    img, d = new(16, 16)
    R(d, 3, 2, 8, 11, WHITE)        # main sheet
    R(d, 4, 4, 6, 1, LGRAY)
    R(d, 4, 6, 6, 1, LGRAY)
    R(d, 4, 8, 4, 1, LGRAY)
    R(d, 4, 10, 6, 1, RED)          # urgent line
    R(d, 8, 5, 6, 9, PALE)          # second sheet underneath
    R(d, 9, 7, 4, 1, LGRAY)
    R(d, 9, 9, 4, 1, LGRAY)
    return img


def draw_paper_scattered(w, h):
    img, d = new(16, 16)
    R(d, 2, 3, 5, 4, WHITE)
    P(d, 3, 4, LGRAY)
    P(d, 4, 5, LGRAY)
    R(d, 9, 8, 5, 4, PALE)
    P(d, 10, 9, LGRAY)
    P(d, 11, 10, LGRAY)
    R(d, 5, 11, 4, 3, WHITE)
    P(d, 6, 12, RED)
    return img


def draw_panel_small(w, h):
    img, d = new(16, 16)
    R(d, 3, 2, 10, 12, STEEL)
    R(d, 4, 3, 8, 4, DGRAY)         # screen
    P(d, 5, 4, CYAN)
    P(d, 7, 5, MONGREEN)
    P(d, 9, 4, CYAN)
    R(d, 5, 9, 2, 2, MONGREEN)      # green button
    R(d, 9, 9, 2, 2, RED)           # red button
    P(d, 4, 12, LGRAY)
    P(d, 11, 12, LGRAY)
    return img


def draw_shelf_medicine(w, h):
    img, d = new(16, 16)
    R(d, 2, 4, 12, 1, STEEL)        # top board
    R(d, 2, 10, 12, 1, STEEL)       # bottom board
    R(d, 2, 4, 1, 11, DGRAY)
    R(d, 13, 4, 1, 11, DGRAY)
    R(d, 4, 5, 2, 5, WHITE)         # bottle
    P(d, 4, 5, CYAN)
    R(d, 7, 6, 2, 4, MEDGREEN)      # bottle
    R(d, 10, 5, 2, 5, AMBER)        # box
    R(d, 5, 11, 2, 2, AMBER)        # tiny fuse hidden on lower shelf
    P(d, 5, 11, RED)
    R(d, 9, 11, 3, 2, WHITE)        # small pack
    return img


DRAW_FNS = {
    "floor_cracked": draw_floor_cracked,
    "floor_broken": draw_floor_broken,
    "floor_stain_water": draw_floor_stain_water,
    "floor_stain_chemical": draw_floor_stain_chemical,
    "floor_footprints": draw_floor_footprints,
    "floor_wheel_tracks": draw_floor_wheel_tracks,
    "floor_debris": draw_floor_debris,
    "floor_hatch": draw_floor_hatch,
    "floor_grille": draw_floor_grille,
    "floor_panel": draw_floor_panel,
    "wall_corner_inner": draw_wall_corner_inner,
    "wall_corner_outer": draw_wall_corner_outer,
    "wall_end": draw_wall_end,
    "wall_trim": draw_wall_trim,
    "wall_access_panel": draw_wall_access_panel,
    "wall_cabinet_section": draw_wall_cabinet_section,
    "door_open": draw_door_open,
    "door_frame": draw_door_frame,
    "bed_sheets": draw_bed_sheets,
    "infusion_pump": draw_infusion_pump,
    "tray": draw_tray,
    "sign_warning": draw_sign_warning,
    "indicator_red": draw_indicator_red,
    "cabinet_open": draw_cabinet_open,
    "fusebox_closed": draw_fusebox_closed,
    "fusebox_open": draw_fusebox_open,
    "light_blue": draw_light_blue,
    "light_green": draw_light_green,
    "light_red": draw_light_red,
    "light_flicker": draw_light_flicker,
    "light_damaged": draw_light_damaged,
    "chair_fallen": draw_chair_fallen,
    "cart": draw_cart,
    "steam": draw_steam,
    "wall_h": draw_wall_h,
    "wall_v": draw_wall_v,
    "documents": draw_documents,
    "paper_scattered": draw_paper_scattered,
    "panel_small": draw_panel_small,
    "shelf_medicine": draw_shelf_medicine,
}


# ---- build ----
CELL = 48      # 16px sprite at 3x
GUTTER = 6
COLS = 8       # cells per row


def build():
    con = sqlite3.connect(DB)
    atlas = Atlas(con)
    os.makedirs(ATLAS_DIR, exist_ok=True)
    os.makedirs(DRAWN_DIR, exist_ok=True)
    entries = []
    stats = {"atlas": 0, "drawn": 0, "missing": []}

    for key, fa, stage, wt, ht, opaque, searches, draw_id in ITEMS:
        w_px, h_px = wt * 16, ht * 16
        img = None
        source = None
        if searches:
            got = atlas.pick(searches)
            if got:
                (split, row_id, shard, caption, subject), raw, term = got
                img = Image.open(__import__("io").BytesIO(raw))
                img = normalize_transparency(img, opaque)
                if img.size != (w_px, h_px):
                    # atlas sprites are 16x16; stretch 2-tile objects from the
                    # single sprite only if sizes differ by cropping/padding
                    canvas = Image.new("RGBA", (w_px, h_px), (0, 0, 0, 0))
                    iw, ih = img.size
                    canvas.paste(img.resize((w_px, h_px), Image.NEAREST) if (iw, ih) != (w_px, h_px) else img, (0, 0))
                    img = canvas
                p = os.path.join(ATLAS_DIR, key + ".png")
                img.save(p)
                source = {"type": "atlas", "row_id": row_id, "shard": shard,
                          "subject": subject, "caption": caption, "term": term,
                          "file": "atlas/" + key + ".png"}
                stats["atlas"] += 1
        if img is None and draw_id and draw_id in DRAW_FNS:
            img = DRAW_FNS[draw_id](w_px, h_px)
            p = os.path.join(DRAWN_DIR, key + ".png")
            img.save(p)
            source = {"type": "procedural", "draw": draw_id, "file": "drawn/" + key + ".png"}
            stats["drawn"] += 1
        if img is None:
            stats["missing"].append(key)
            print(f"MISSING {key} ({fa})")
            continue
        entries.append({"key": key, "fa": fa, "stage": stage, "w_tiles": wt,
                        "h_tiles": ht, "opaque": opaque, "source": source,
                        "img": img})
        print(f"ok {key:22s} stage{stage} {wt}x{ht} "
              f"{'atlas row ' + str(source.get('row_id', '')) if source['type'] == 'atlas' else 'drawn:' + source['draw']}")

    # ---- compose the three stage sheets ----
    manifest = []
    for stage in (1, 2, 3):
        stage_entries = [e for e in entries if e["stage"] == stage]
        # place entries in a cell grid, wrapping at COLS
        cx, cy, row_h = 0, 0, 0
        placed = []
        for e in stage_entries:
            if cx + e["w_tiles"] > COLS:
                cx = 0
                cy += row_h
                row_h = 0
            placed.append((e, cx, cy))
            cx += e["w_tiles"]
            row_h = max(row_h, e["h_tiles"])
        cols = COLS
        rows = cy + row_h
        W = cols * CELL + (cols + 1) * GUTTER
        H = rows * CELL + (rows + 1) * GUTTER
        sheet = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        for e, gx, gy in placed:
            x = GUTTER + gx * (CELL + GUTTER)
            y = GUTTER + gy * (CELL + GUTTER)
            big = e["img"].resize((e["w_tiles"] * CELL, e["h_tiles"] * CELL), Image.NEAREST)
            sheet.paste(big, (x, y), big)
            manifest.append({
                "key": e["key"], "fa": e["fa"], "stage": stage,
                "sheet": f"stage{stage}.png",
                "x": x, "y": y, "w": e["w_tiles"] * CELL, "h": e["h_tiles"] * CELL,
                "tiles_w": e["w_tiles"], "tiles_h": e["h_tiles"],
                "opaque": e["opaque"], "source": e["source"],
            })
        path = os.path.join(OUT, f"stage{stage}.png")
        sheet.save(path)
        print(f"stage{stage}: {len(stage_entries)} sprites -> {path} ({W}x{H})")

    # ---- contact sheet of atlas picks (4x, for visual review) ----
    picks = [e for e in entries if e["source"]["type"] == "atlas"]
    n = len(picks)
    cols = 10
    rows = (n + cols - 1) // cols
    contact = Image.new("RGBA", (cols * 72, rows * 72), (30, 34, 48, 255))
    for i, e in enumerate(picks):
        x = (i % cols) * 72 + 4
        y = (i // cols) * 72 + 4
        contact.paste(e["img"].resize((64, 64), Image.NEAREST), (x, y))
    contact.save(os.path.join(OUT, "contact_atlas.png"))
    print(f"contact sheet: {n} atlas picks -> contact_atlas.png")

    with open(os.path.join(OUT, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump({"pack": "last-signal-medical-wing", "base_tile_px": 48,
                   "sprite_unit_px": 16, "scale": 3, "gutter_px": GUTTER,
                   "counts": stats, "sprites": manifest}, f, ensure_ascii=False, indent=1)
    with open(os.path.join(OUT, "_manifest.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["key", "fa", "stage", "sheet", "x", "y", "w", "h", "tiles_w", "tiles_h", "source_type", "row_id", "caption"])
        for m in manifest:
            s = m["source"]
            w.writerow([m["key"], m["fa"], m["stage"], m["sheet"], m["x"], m["y"], m["w"], m["h"],
                        m["tiles_w"], m["tiles_h"], s["type"], s.get("row_id", ""), s.get("caption", "")])
    print(f"TOTAL: atlas={stats['atlas']} drawn={stats['drawn']} missing={len(stats['missing'])}")


if __name__ == "__main__":
    build()
