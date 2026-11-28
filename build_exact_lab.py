import os
import random
from PIL import Image, ImageDraw

SPRITE_DIR = "assets/sprites/laboratory"
os.makedirs(SPRITE_DIR, exist_ok=True)
random.seed(42)

# 1. ساخت پس‌زمینه فضایی (space_lab.png) دقیقاً طبق تصویر مرجع
def build_space_lab():
    img = Image.new("RGBA", (768, 768), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # ناحیه بالا-چپ: X=0..224, Y=0..288
    draw.rectangle([0, 0, 224, 288], fill=(6, 7, 13, 255))
    # ستاره‌های ریز
    for _ in range(90):
        sx, sy = random.randint(2, 220), random.randint(2, 284)
        c = random.choice([(255, 255, 255, 255), (180, 200, 255, 220), (255, 220, 180, 200)])
        img.putpixel((sx, sy), c)
        
    # سیاره قرمز-نارنجی گدازه‌ای در بالا-چپ (مرکز حدود 105, 115، شعاع 96)
    cx, cy, r = 105, 115, 96
    for y in range(max(0, cy - r), min(288, cy + r)):
        for x in range(max(0, cx - r), min(224, cx + r)):
            dx, dy = x - cx, y - cy
            dist = (dx*dx + dy*dy) ** 0.5
            if dist <= r:
                # سایه‌زنی کروی و رگه‌های نارنجی گدازه‌ای
                shade = max(0.0, 1.0 - (dist / r) ** 1.6)
                vein = abs((dx * 0.12 + dy * 0.08) % 6 - 3) / 3.0
                if abs(dx + dy * 0.4) < 12 or abs(dx * 0.5 - dy) < 10:
                    red = int(min(255, 180 + 75 * shade))
                    green = int(min(255, 45 + 90 * shade * vein))
                    blue = int(10 * shade)
                else:
                    red = int(45 + 145 * shade)
                    green = int(8 + 22 * shade)
                    blue = int(6 + 10 * shade)
                img.putpixel((x, y), (red, green, blue, 255))
                
    # سیارک‌های کوچک کنار سیاره قرمز
    draw.polygon([(12, 195), (26, 190), (32, 205), (18, 212)], fill=(115, 120, 130, 255))
    draw.polygon([(38, 218), (48, 214), (52, 226), (40, 230)], fill=(90, 95, 105, 255))

    # سازه خرپای فلزی افقی بالا-چپ (X=144..224, Y=16..42)
    tx0, ty0, tx1, ty1 = 144, 16, 224, 42
    draw.rectangle([tx0, ty0, tx1, ty1], outline=(95, 102, 115, 255), width=2)
    for step in range(tx0, tx1, 20):
        draw.line([(step, ty0), (step, ty1)], fill=(95, 102, 115, 255), width=2)
        draw.line([(step, ty0), (min(tx1, step + 20), ty1)], fill=(75, 82, 95, 255), width=1)
        draw.line([(step, ty1), (min(tx1, step + 20), ty0)], fill=(75, 82, 95, 255), width=1)

    # ناحیه پایین-چپ: X=0..192, Y=544..768
    draw.rectangle([0, 544, 192, 768], fill=(6, 8, 15, 255))
    for _ in range(70):
        sx, sy = random.randint(36, 188), random.randint(548, 764)
        c = random.choice([(255, 255, 255, 255), (170, 200, 255, 210)])
        img.putpixel((sx, sy), c)
        
    # ستون خرپای فلزی عمودی در لبه چپ (X=14..38, Y=544..768)
    draw.rectangle([14, 544, 38, 768], outline=(90, 98, 110, 255), width=2)
    for y_step in range(544, 768, 24):
        draw.line([(14, y_step), (38, y_step)], fill=(90, 98, 110, 255), width=2)
        draw.line([(14, y_step), (38, y_step + 24)], fill=(70, 78, 90, 255), width=1)
        draw.line([(38, y_step), (14, y_step + 24)], fill=(70, 78, 90, 255), width=1)
        
    # سیارک / ماه خاکستری در پایین-چپ (مرکز 102, 675، شعاع 56)
    mx, my, mr = 102, 675, 56
    for y in range(max(544, my - mr), min(768, my + mr)):
        for x in range(max(38, mx - mr), min(192, mx + mr)):
            dx, dy = x - mx, y - my
            dist = (dx*dx + dy*dy) ** 0.5
            if dist <= mr:
                light = max(0.15, 1.0 - ((dx + 15)**2 + (dy + 15)**2) ** 0.5 / (mr * 1.4))
                c_val = int(45 + 95 * light)
                img.putpixel((x, y), (c_val, int(c_val * 1.05), int(c_val * 1.15), 255))
    # دهانه‌های روی سیارک
    draw.ellipse([86, 650, 102, 664], fill=(42, 48, 56, 255))
    draw.ellipse([115, 682, 128, 694], fill=(38, 44, 52, 255))

    img.save(os.path.join(SPRITE_DIR, "space_lab.png"))

# 2. ساخت کف آزمایشگاه (floor_lab.png) با گرید دقیق، صلیب صورتی، دایره و کمان‌های زرد اتاق بالا
def build_floor_lab():
    MAP = [
        "      ##################",
        "      ##HHHH#HHHHHH#WWW#",
        "      ##DDDD#BBBBBB#WWW#",
        "      ##DDDD#BBBBBB#WWW#",
        "      ##DDDDBBBBBBBWWWW#",
        "      ##DDDDBBBBBBB#WWW#",
        "      #DDDDDBBBBBBB#WWW#",
        "      #DDDDD#HHHHHH#WWW#",
        "      #WWWWHHHHHHHH#WWW#",
        "#HHHHH#WWWPPWWWWWWW#WWW#",
        "#HWWWH#WWWPPWWWWWWW#WWW#",
        "#HWWWHWWWWPPWWWWWWW#WWW ",
        "#HWWWH#WPPPPPPPPWWWWWWW#",
        "#HHHHH#WPPPPPPPPWWW#WWW#",
        "      #WWWPPWWWWWWW#WWW#",
        "      #WWWPPWWWWWWW#WWW#",
        "      #HHWWHHHHHHHH#WWW#",
        "      RDDDDDRBBBBBB#WWW#",
        "      RDDDDDRBBBBBB#WWW#",
        "      RDDDDDRBBBBBBWWWW#",
        "      RDDDDDRBBBBBB#WWW#",
        "      RDDDDDRBBBBBB#WWW#",
        "      RDDDDDRHHHHHH#WWW#",
        "      ##################",
    ]
    CELL = 32
    img = Image.new("RGBA", (768, 768), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    for gy in range(24):
        for gx in range(24):
            ch = MAP[gy][gx]
            x0, y0 = gx * CELL, gy * CELL
            if ch == "W":
                draw.rectangle([x0, y0, x0 + CELL - 1, y0 + CELL - 1], fill=(228, 232, 236, 255), outline=(165, 172, 180, 255))
            elif ch == "P":
                draw.rectangle([x0, y0, x0 + CELL - 1, y0 + CELL - 1], fill=(236, 202, 224, 255), outline=(182, 156, 175, 255))
            elif ch == "D":
                # کف کاشی تیره
                draw.rectangle([x0, y0, x0 + CELL - 1, y0 + CELL - 1], fill=(48, 50, 54, 255), outline=(34, 36, 40, 255))
            elif ch == "B":
                # کف تاریک نقطه‌دار
                draw.rectangle([x0, y0, x0 + CELL - 1, y0 + CELL - 1], fill=(22, 23, 27, 255), outline=(16, 17, 20, 255))
                for _ in range(4):
                    px, py = random.randint(x0 + 2, x0 + 29), random.randint(y0 + 2, y0 + 29)
                    img.putpixel((px, py), (55, 58, 66, 255))

    # چهار کمان گوشه زردرنگ داخل اتاق بالا-وسط (X=9..11, Y=2..5)
    b_col = (195, 185, 65, 255)
    # بالا-چپ
    draw.line([(304, 86), (316, 86)], fill=b_col, width=2)
    draw.line([(304, 86), (304, 98)], fill=b_col, width=2)
    # بالا-راست
    draw.line([(340, 86), (352, 86)], fill=b_col, width=2)
    draw.line([(352, 86), (352, 98)], fill=b_col, width=2)
    # پایین-چپ
    draw.line([(304, 150), (316, 150)], fill=b_col, width=2)
    draw.line([(304, 138), (304, 150)], fill=b_col, width=2)
    # پایین-راست
    draw.line([(340, 150), (352, 150)], fill=b_col, width=2)
    draw.line([(352, 138), (352, 150)], fill=b_col, width=2)

    # دایره هدف صورتی کم‌رنگ در مرکز تالار (سلول 14,13 -> پیکسل 464, 432)
    draw.ellipse([452, 420, 476, 444], outline=(198, 155, 185, 255), width=3)

    img.save(os.path.join(SPRITE_DIR, "floor_lab.png"))

# 3. ساخت اسپرایت‌های اختصاصی وسایل مطابق تصویر مرجع
def build_custom_props():
    # محفظه دایره‌ای مرکزی (chamber_lab.png - 36x36)
    ch = Image.new("RGBA", (36, 36), (0, 0, 0, 0))
    d = ImageDraw.Draw(ch)
    d.ellipse([2, 2, 33, 33], fill=(55, 65, 78, 255), outline=(25, 30, 38, 255), width=2)
    d.ellipse([7, 7, 28, 28], fill=(42, 98, 132, 255), outline=(110, 185, 220, 255), width=2)
    # چهار گیره فلزی اطراف حلقه
    for rx, ry in [(15, 0), (15, 31), (0, 15), (31, 15)]:
        d.rectangle([rx, ry, rx + 4, ry + 4], fill=(130, 140, 152, 255))
    ch.save(os.path.join(SPRITE_DIR, "chamber_lab.png"))

    # دستگاه مخزن/گاوصندوق قرمز و فیروزه‌ای پایین تالار (vault_lab.png - 48x36)
    vl = Image.new("RGBA", (48, 36), (0, 0, 0, 0))
    d = ImageDraw.Draw(vl)
    # بخش پایینی شیشه‌ای فیروزه‌ای
    d.rectangle([2, 12, 45, 34], fill=(115, 195, 210, 255), outline=(45, 60, 70, 255), width=2)
    d.rectangle([8, 16, 39, 30], fill=(165, 225, 235, 255))
    # سقف قرمز با خطوط مورب سفید (شبیه عکس)
    d.polygon([(4, 2), (43, 2), (46, 13), (1, 13)], fill=(215, 35, 45, 255), outline=(90, 15, 20, 255))
    d.line([(14, 4), (10, 11)], fill=(255, 255, 255, 255), width=2)
    d.line([(28, 4), (24, 11)], fill=(255, 255, 255, 255), width=2)
    vl.save(os.path.join(SPRITE_DIR, "vault_lab.png"))

    # مانیتور آبی روشن 4تایی شمال تالار (monitor.png - 32x32)
    mn = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(mn)
    d.rectangle([1, 2, 30, 29], fill=(185, 195, 205, 255), outline=(55, 62, 72, 255), width=2)
    d.rectangle([5, 6, 26, 22], fill=(80, 195, 215, 255), outline=(35, 110, 130, 255))
    d.rectangle([7, 8, 14, 14], fill=(190, 245, 255, 255))
    mn.save(os.path.join(SPRITE_DIR, "monitor.png"))

    # قفسه‌های رنگی اتاق کوچک سمت چپ (آبی، قرمز، سبز)
    colors = {
        "locker_blue.png": ((45, 125, 210, 255), (120, 190, 255, 255)),
        "locker_red.png": ((205, 55, 40, 255), (245, 130, 90, 255)),
        "locker_green.png": ((55, 165, 65, 255), (135, 225, 120, 255)),
    }
    for fname, (main_c, hi_c) in colors.items():
        lk = Image.new("RGBA", (24, 32), (0, 0, 0, 0))
        d = ImageDraw.Draw(lk)
        d.rectangle([2, 2, 21, 29], fill=main_c, outline=(30, 34, 40, 255), width=2)
        d.rectangle([5, 5, 18, 14], fill=hi_c)
        d.rectangle([5, 18, 18, 26], fill=(40, 45, 52, 255))
        lk.save(os.path.join(SPRITE_DIR, fname))

if __name__ == "__main__":
    build_space_lab()
    build_floor_lab()
    build_custom_props()
    print("All exact sprites generated successfully!")

