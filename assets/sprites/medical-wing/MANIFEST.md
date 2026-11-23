# Last Signal — Medical Wing Asset Pack / پک دارایی بخش پزشکی

پک کامل محیط بخش پزشکی ایستگاه K-17 برای بازی Last Signal — سال ۲۰۸۹.
ساخته‌شده در سه مرحله (طبق نکته‌ی اجرایی پرامپت): ۱) کف و دیوارها، ۲) تجهیزات و مبلمان،
۳) اشیای داستانی و جلوه‌های نوری. تولید یک‌جا انجام نشد تا جزئیات و اندازه‌ی اسپرایت‌ها حفظ شود.

**آمار:** 87 اسپرایت — 48 از اطلس، 39 ترسیمی، 0 جاافتاده.
واحد پایه: اسپرایت ۱۶×۱۶ = یک تایل ۴۸ پیکسلی (مقیاس ۳×). اشیای بزرگ ۲×۱ یا ۲×۲ تایل‌اند.
کف و دیوار کاملاً مات‌اند؛ بقیه‌ی اسپرایت‌ها پس‌زمینه‌ی شفاف دارند.

## منبع تصویرها

- **اطلس:** دیتاست `Angais/pixel-art-atlas-1.4m` (CC0 1.0) — جستجو در `sprites.db` با امتیازدهی به کپشن‌ها
  (ترجیح فلز/سفید/شیشه/مدرن/پزشکی، جریمه‌ی چوبی/قرون‌وسطایی/فانتزی؛ تطابق کلمه‌ی کامل برای جلوگیری از
  تله‌هایی مثل vent در adventurer یا cart در carton). سه فیوز با row_id ثابت پین شده‌اند تا بازتولیدپذیر باشند.
- **ترسیمی:** با PIL و پالت پزشکی پرامپت کشیده شده‌اند — مواردی که در اطلس نمونه‌ی قابل‌استفاده نداشتند
  (همه‌ی کف‌های آسیب‌دیده/لکه/ردپا برای seamless بودن، همه‌ی دیوارها چون اطلس فقط دیوار آجری/قلعه دارد،
  جعبه‌ی فیوز، کمد باز، چراغ‌های نشانگر، ترولی، قفسه‌ی دارو، اسناد).

## پالت

سفید مایل به خاکستری `#E8EEF7`، خاکستری روشن `#B8C6DC`، خاکستری فلزی `#7A8FB0`، استیل `#4A5D7E`،
خاکستری تیره `#2E3D5E`، سبز پزشکی `#6FA287`، سبز مانیتور `#39D98A`، فیروزه‌ای `#3EC6E0`، آبی ملایم `#6B8FD4`،
قرمز اضطراری `#D62839`، زرد هشدار `#F4A62A`، زیتونی `#7A7A52`.

## فایل‌ها

- `stage1.png` — کف و دیوارها (۲۵ اسپرایت)
- `stage2.png` — تجهیزات و مبلمان پزشکی (۳۸ اسپرایت)
- `stage3.png` — اشیای داستانی، فیوزها و جلوه‌های نوری (۲۰ اسپرایت)
- `atlas/` — تک‌تک اسپرایت‌های اطلسی در اندازه‌ی اصلی ۱۶×۱۶ (یا ۳۲×۱۶)
- `drawn/` — تک‌تک اسپرایت‌های ترسیمی در اندازه‌ی اصلی
- `manifest.json` / `_manifest.csv` — مختصات هر اسپرایت در شیت (x, y, w, h به پیکسل) + منبع
- `build_pack.py` — اسکریپت ساخت پک (قابل بازتولید: جستجو + امتیازدهی + ترسیم + چیدمان شیت)

## استفاده در Godot 4

دو راه: (۱) فایل‌های تکی `atlas/` و `drawn/` را مستقیم به‌عنوان Sprite2D/TileSet استفاده کنید
(۱۶×۱۶، مقیاس ۳× = تایل ۴۸)؛ (۲) از شیت‌ها با AtlasTexture و مختصات `manifest.json` استفاده کنید
(هر سلول ۴۸×۴۸، فاصله‌ی شفاف ۶ پیکسل بین سلول‌ها).

## جدول اسپرایت‌ها

| key | نام | مرحله | اندازه (تایل) | منبع |
|---|---|---|---|---|
| `floor_standard` | کف استاندارد پزشکی | 1 | 1×1 | atlas row 183112 — gray floor tile |
| `floor_alt` | کف متناوب سفید/خاکستری | 1 | 1×1 | atlas row 1002 — floor tile |
| `floor_cracked` | کف ترک‌خورده | 1 | 1×1 | procedural (floor_cracked) |
| `floor_broken` | کف شکسته / کاشی گمشده | 1 | 1×1 | procedural (floor_broken) |
| `floor_stain_water` | لکه آب | 1 | 1×1 | procedural (floor_stain_water) |
| `floor_stain_chemical` | لکه شیمیایی | 1 | 1×1 | procedural (floor_stain_chemical) |
| `floor_footprints` | رد پا | 1 | 1×1 | procedural (floor_footprints) |
| `floor_wheel_tracks` | رد چرخ تخت | 1 | 1×1 | procedural (floor_wheel_tracks) |
| `floor_debris` | خرده‌های پزشکی پراکنده | 1 | 1×1 | procedural (floor_debris) |
| `floor_hatch` | دریچه فلزی کف | 1 | 1×1 | procedural (floor_hatch) |
| `floor_grille` | گریل تهویه کف | 1 | 1×1 | procedural (floor_grille) |
| `floor_panel` | پنل نگهداری کف | 1 | 1×1 | procedural (floor_panel) |
| `wall_h` | دیوار افقی | 1 | 1×1 | procedural (wall_h) |
| `wall_v` | دیوار عمودی | 1 | 1×1 | procedural (wall_v) |
| `wall_corner_inner` | گوشه داخلی دیوار | 1 | 1×1 | procedural (wall_corner_inner) |
| `wall_corner_outer` | گوشه خارجی دیوار | 1 | 1×1 | procedural (wall_corner_outer) |
| `wall_end` | انتهای دیوار | 1 | 1×1 | procedural (wall_end) |
| `wall_trim` | تریم فلزی دیوار | 1 | 1×1 | procedural (wall_trim) |
| `wall_access_panel` | پنل دسترسی دیوار | 1 | 1×1 | procedural (wall_access_panel) |
| `wall_cabinet_section` | کابینت دیواری توکار | 1 | 1×1 | procedural (wall_cabinet_section) |
| `window_observation` | پنجره مشاهده بزرگ | 1 | 2×1 | atlas row 19716 — gray window with light shining through |
| `window_small` | پنجره کوچک تقویت‌شده | 1 | 1×1 | atlas row 89782 — glowing blue window |
| `door_closed` | در اتوماتیک بسته | 1 | 1×1 | atlas row 47212 — white door |
| `door_open` | در اتوماتیک باز | 1 | 1×1 | procedural (door_open) |
| `door_frame` | چارچوب در پزشکی | 1 | 1×1 | procedural (door_frame) |
| `bed_standard` | تخت بیمارستان استاندارد | 2 | 2×1 | atlas row 5764 — blue bed with white piping |
| `bed_empty` | تخت خالی | 2 | 2×1 | atlas row 11323 — plush bed with white piping |
| `bed_disorganized` | تخت با ملحفه به‌هم‌ریخته | 2 | 2×1 | atlas row 11998 — gray bed with a polka dot pattern |
| `bedside_table` | میز کنار تخت | 2 | 1×1 | atlas row 32581 — white table with brass accents |
| `exam_bed` | تخت معاینه قابل‌تنظیم | 2 | 2×1 | atlas row 12555 — plush green bed |
| `stretcher` | برانکارد چرخ‌دار | 2 | 2×1 | atlas row 27746 — spotless green stretcher with a blue accent |
| `chair_rolling` | صندلی چرخ‌دار پزشکی | 2 | 1×1 | atlas row 41617 — giant green chair |
| `desk_doctor` | میز دکتر | 2 | 2×1 | atlas row 16663 — blue desk with white paint |
| `chair_office` | صندلی اداری | 2 | 1×1 | atlas row 42150 — polished green chair |
| `side_table` | میز کوچک پزشکی | 2 | 1×1 | atlas row 83051 — elegant oak table with white paint |
| `trolley` | ترولی لوازم پزشکی | 2 | 1×1 | procedural (cart) |
| `monitor_vitals` | مانیتور علائم حیاتی | 2 | 1×1 | atlas row 29958 — gray computer monitor with a green screen |
| `monitor_heart` | مانیتور قلب قابل‌حمل | 2 | 1×1 | atlas row 17424 — futuristic crt monitor with a green screen |
| `oxygen_cylinder` | کپسول اکسیژن | 2 | 1×1 | atlas row 273397 — futuristic blue oxygen tank |
| `oxygen_unit` | واحد تأمین اکسیژن | 2 | 1×1 | atlas row 37754 — glowing white oxygen tank with a sparkle |
| `iv_stand` | پایه سرم با کیسه | 2 | 1×1 | atlas row 463305 — top-down rolling blue iv stand in warm colors |
| `infusion_pump` | پمپ تزریق | 2 | 1×1 | procedural (infusion_pump) |
| `exam_lamp` | چراغ معاینه | 2 | 1×1 | atlas row 49509 — sleek red desk lamp with a blue accent |
| `cart_emergency` | ترولی اورژانس | 2 | 1×1 | procedural (cart) |
| `defibrillator` | دفیبریلاتور | 2 | 1×1 | atlas row 516187 — top-down compact blue defibrillator with a heart symbol |
| `waste_bin` | سطل زباله پزشکی | 2 | 1×1 | atlas row 91408 — shiny green trash can with a blue stripe |
| `cabinet_storage` | کابینت ذخیره پزشکی | 2 | 1×1 | atlas row 3340 — black cabinet with white paint |
| `cabinet_medicine` | کابینت دارو | 2 | 1×1 | atlas row 12064 — cabinet with brass accents |
| `shelf_medicine` | قفسه دارو | 2 | 1×1 | atlas row 73461 — blue wall shelf |
| `supply_boxes` | جعبه‌های لوازم پزشکی | 2 | 1×1 | atlas row 13697 — spotless gray box of bandages with a green cross |
| `documents` | اسناد پزشکی پراکنده | 2 | 1×1 | procedural (documents) |
| `bottles_medicine` | بطری‌های دارو | 2 | 1×1 | atlas row 13360 — tiny glass bottle with a blue painted pattern |
| `packages_medicine` | بسته‌های دارو | 2 | 1×1 | atlas row 57429 — white blister pack of pills with a blue accent |
| `gloves` | دستکش پزشکی | 2 | 1×1 | atlas row 81932 — gloves with silver studs |
| `bandages` | بسته بانداژ | 2 | 1×1 | atlas row 163506 — clean white adhesive bandage with a blue stripe |
| `syringes` | سرنگ یک‌بارمصرف | 2 | 1×1 | atlas row 140356 — spotless gray syringe with a green accent |
| `tray_instruments` | سینی ابزار | 2 | 1×1 | procedural (tray) |
| `clock_wall` | ساعت دیواری | 2 | 1×1 | atlas row 1791 — blue clock icon |
| `sign_warning` | تابلوی هشدار پزشکی | 2 | 1×1 | procedural (sign_warning) |
| `light_ceiling` | چراغ سقفی پزشکی | 2 | 1×1 | atlas row 59955 — modern gray ceiling lamp with a green glow |
| `indicator_emergency` | چراغ نشانگر اضطراری | 2 | 1×1 | procedural (indicator_red) |
| `grille_vent` | گریل تهویه دیواری | 2 | 1×1 | atlas row 36568 — dark gray steam vent |
| `panel_wall_small` | پنل کنترل دیواری کوچک | 2 | 1×1 | procedural (panel_small) |
| `cabinet_closed` | کمد فلزی بسته (فیوز A) | 3 | 1×1 | atlas row 44168 — cabinet |
| `cabinet_open` | کمد باز با قفسه‌ها | 3 | 1×1 | procedural (cabinet_open) |
| `cabinet_worn` | کمد فلزی فرسوده | 3 | 1×1 | atlas row 79249 — brand new cabinet |
| `fuse_a` | فیوز A — سفید | 3 | 1×1 | atlas row 165 — white fuse |
| `fuse_b` | فیوز B — زرد با نوار قرمز | 3 | 1×1 | atlas row 4172 — yellow fuse with a red stripe |
| `fuse_c` | فیوز C — نقره‌ای با نماد برق | 3 | 1×1 | atlas row 4282 — tiny silver fuse with a lightning bolt symbol |
| `flashlight` | چراغ‌قوه روی میز دکتر | 3 | 1×1 | atlas row 4782 — sleek gray flashlight |
| `note_doctor` | یادداشت دست‌نویس دکتر | 3 | 1×1 | atlas row 12656 — tiny white sticky note pad with a blue accent |
| `fusebox_closed` | جعبه فیوز بسته | 3 | 1×1 | procedural (fusebox_closed) |
| `fusebox_open` | جعبه فیوز باز — ۳ شیار خالی | 3 | 1×1 | procedural (fusebox_open) |
| `light_blue` | چراغ آبی ملایم سقفی | 3 | 1×1 | procedural (light_blue) |
| `light_green` | چراغ سبز نشانگر پزشکی | 3 | 1×1 | procedural (light_green) |
| `light_red` | چراغ قرمز اضطراری | 3 | 1×1 | procedural (light_red) |
| `light_flicker` | چراغ چشمک‌زن | 3 | 1×1 | procedural (light_flicker) |
| `light_damaged` | چراغ سقفی آسیب‌دیده | 3 | 1×1 | procedural (light_damaged) |
| `spark` | جرقه الکتریکی | 3 | 1×1 | atlas row 364722 — blue spark burst with a bright white core |
| `steam` | بخار تهویه | 3 | 1×1 | procedural (steam) |
| `dust` | ذرات غبار | 3 | 1×1 | atlas row 441351 — clumped white dust puff with curled edges |
| `paper_scattered` | کاغذهای پراکنده (شواهد تخلیه) | 3 | 1×1 | procedural (paper_scattered) |
| `chair_fallen` | صندلی افتاده | 3 | 1×1 | procedural (chair_fallen) |
| `sink_ceramic` | روشویی سرامیکی سفید | 4 | 1×1 | atlas row 4928 — ceramic bathroom sink with water droplets |
| `wheelchair` | ویلچر | 4 | 1×1 | atlas row 429 — wheelchair |
| `curtain_privacy` | پرده حریم خصوصی تخت | 4 | 1×1 | atlas row 707 — curtain |
| `fridge_medical` | یخچال دارویی با چراغ آبی | 4 | 1×1 | atlas row 6622 — tiny refrigerator with a blue light |

## نکته‌های صادقانه

- اسپرایت‌های اطلسی ذاتاً سبک یکدست ندارند (دیتاست عمومی است)؛ امتیازدهی کپشن بهترین نمونه‌های
  موجود را انتخاب کرده، ولی چند مورد (مثلاً دستکش قهوه‌ای، میز کناری بلوطی) هنوز حس چوبی/گرم دارند.
- کف‌های استاندارد اطلسی‌اند ولی نسخه‌های آسیب‌دیده و لکه‌دار ترسیمی‌اند تا بدون درز تکرار شوند.
- دیوارهای اطلس فقط آجری/قلعه بودند، پس کل سیستم دیوار پزشکی ترسیمی است و با کف هماهنگ است.
- صدا/نریشن در این پک نیست؛ یادداشت دکتر فقط اسپرایت کاغذ است، متن آن در `story.gd` بازی است.
## مرحله‌ی ۴ — بازطراحی درمانگاه (۲۳ نوامبر ۲۰۲۶)

چهار اسپرایت تازه از همان اطلس `Angais/pixel-art-atlas-1.4m` (CC0) برای
چیدمان تازه‌ی درمانگاه: روشویی کنار تخت معاینه، ویلچر کنار در ورودی،
پرده‌ی حریم بین تخت‌ها و یخچال دارویی در داروخانه. درهای باز (`door_open`،
موجود در پک ولی استفاده‌نشده) هم به‌عنوان دکور روی هر دو خروجی گذاشته شدند.
کف یکدست شد: فقط تایل روشن شماره‌ی ۴ اطلس کف پزشکی (روشن‌ترین و یکنواخت‌ترین
تایل؛ تایل ۰ خاکستری تیره بود و اشتباه انتخاب شده بود).
