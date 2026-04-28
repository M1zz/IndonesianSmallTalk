"""Generate a 1024x1024 'Mi Goreng' app icon styled after Indonesian
instant noodle packaging — bright yellow base, red wave banner,
white sun-burst, plate of fried noodles, red 'MI GORENG' ribbon.

Run: python3 scripts/make_app_icon.py
Output: IndonesianSmallTalk/Assets.xcassets/AppIcon.appiconset/AppIcon.png
"""

from PIL import Image, ImageDraw, ImageFilter, ImageFont
import math
import os
import random

W = H = 1024
img = Image.new("RGBA", (W, H), (255, 213, 20, 255))  # Indomie-ish yellow
draw = ImageDraw.Draw(img, "RGBA")

# 1) Subtle radial highlight in the upper-center (warmth)
glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
gd.ellipse((180, 60, 844, 720), fill=(255, 245, 180, 180))
glow = glow.filter(ImageFilter.GaussianBlur(80))
img = Image.alpha_composite(img, glow)
draw = ImageDraw.Draw(img, "RGBA")

# 2) Top red wave banner (curved swoosh)
wave_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
wd = ImageDraw.Draw(wave_layer)
# Build a polygon following a sine wave
wave_pts = [(0, 0)]
for x in range(0, W + 1, 4):
    y = 220 + 40 * math.sin(0.012 * x + 0.6)
    wave_pts.append((x, y))
wave_pts += [(W, 0)]
wd.polygon(wave_pts, fill=(208, 26, 32, 255))
# Highlight ridge along wave
ridge_pts = []
for x in range(0, W + 1, 4):
    y = 220 + 40 * math.sin(0.012 * x + 0.6)
    ridge_pts.append((x, y - 6))
wd.line(ridge_pts, fill=(245, 90, 80, 220), width=4, joint="curve")
img = Image.alpha_composite(img, wave_layer)
draw = ImageDraw.Draw(img, "RGBA")

# 3) Sun-burst behind the plate (white triangular rays)
burst_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
bd = ImageDraw.Draw(burst_layer)
plate_cx, plate_cy = 512, 580
ray_count = 24
inner_r = 360
outer_r = 540
for i in range(ray_count):
    a0 = (i + 0.0) / ray_count * math.tau
    a1 = (i + 0.42) / ray_count * math.tau
    am = (a0 + a1) / 2
    p1 = (plate_cx + inner_r * math.cos(a0), plate_cy + inner_r * math.sin(a0))
    p2 = (plate_cx + outer_r * math.cos(am), plate_cy + outer_r * math.sin(am))
    p3 = (plate_cx + inner_r * math.cos(a1), plate_cy + inner_r * math.sin(a1))
    bd.polygon([p1, p2, p3], fill=(255, 255, 255, 200))
burst_layer = burst_layer.filter(ImageFilter.GaussianBlur(2))
img = Image.alpha_composite(img, burst_layer)
draw = ImageDraw.Draw(img, "RGBA")

# 4) Plate shadow
shadow_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ImageDraw.Draw(shadow_layer).ellipse(
    (140, 640, 884, 920), fill=(0, 0, 0, 130)
)
shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(24))
img = Image.alpha_composite(img, shadow_layer)
draw = ImageDraw.Draw(img, "RGBA")

# 5) Plate (cream circle with double rim)
plate_r = 350
draw.ellipse(
    (plate_cx - plate_r, plate_cy - plate_r, plate_cx + plate_r, plate_cy + plate_r),
    fill=(252, 244, 228, 255),
    outline=(140, 90, 40, 255),
    width=8,
)
draw.ellipse(
    (
        plate_cx - plate_r + 30,
        plate_cy - plate_r + 30,
        plate_cx + plate_r - 30,
        plate_cy + plate_r - 30,
    ),
    outline=(220, 200, 175, 255),
    width=4,
)

# 6) Noodles
def draw_noodle(y_base, amp, freq, phase, color, outline, thickness=20):
    pts = []
    x_start = plate_cx - plate_r + 50
    x_end = plate_cx + plate_r - 50
    for x in range(x_start, x_end + 1, 4):
        y = y_base + amp * math.sin(freq * (x - x_start) + phase)
        if (x - plate_cx) ** 2 + (y - plate_cy) ** 2 < (plate_r - 45) ** 2:
            pts.append((x, y))
    if len(pts) > 1:
        draw.line(pts, fill=outline, width=thickness + 6, joint="curve")
        draw.line(pts, fill=color, width=thickness, joint="curve")

random.seed(7)
noodle_color = (240, 195, 80, 255)
noodle_outline = (155, 95, 25, 255)
for i in range(7):
    yb = plate_cy - 100 + i * 38 + random.randint(-6, 6)
    amp = random.randint(45, 80)
    freq = random.uniform(0.012, 0.018)
    phase = random.uniform(0, math.tau)
    draw_noodle(yb, amp, freq, phase, noodle_color, noodle_outline)

# 7) Fried egg
egg_cx, egg_cy = plate_cx - 60, plate_cy - 80
draw.ellipse(
    (egg_cx - 130, egg_cy - 100, egg_cx + 130, egg_cy + 100),
    fill=(255, 250, 235, 255),
    outline=(215, 200, 170, 255),
    width=4,
)
yolk_cx, yolk_cy = egg_cx + 12, egg_cy - 8
draw.ellipse(
    (yolk_cx - 50, yolk_cy - 50, yolk_cx + 50, yolk_cy + 50),
    fill=(245, 170, 45, 255),
    outline=(195, 120, 25, 255),
    width=3,
)
draw.ellipse(
    (yolk_cx - 36, yolk_cy - 36, yolk_cx - 10, yolk_cy - 16),
    fill=(255, 230, 150, 255),
)

# 8) Red chili
chili_pts = [(620, 700), (700, 730), (770, 770), (815, 808)]
draw.line(chili_pts, fill=(155, 25, 25, 255), width=46, joint="curve")
draw.line(chili_pts, fill=(225, 60, 50, 255), width=34, joint="curve")
draw.line(chili_pts[:2], fill=(255, 110, 90, 220), width=10, joint="curve")
draw.line([(620, 700), (590, 680)], fill=(65, 125, 55, 255), width=14)

# 9) Spring onion bits
random.seed(13)
for _ in range(9):
    px = random.randint(plate_cx - plate_r + 110, plate_cx + plate_r - 110)
    py = random.randint(plate_cy - 70, plate_cy + 150)
    if (px - plate_cx) ** 2 + (py - plate_cy) ** 2 < (plate_r - 90) ** 2:
        draw.ellipse(
            (px - 13, py - 7, px + 13, py + 7),
            fill=(110, 175, 90, 255),
            outline=(70, 120, 55, 255),
            width=2,
        )

# 10) Sesame specks
random.seed(21)
for _ in range(18):
    px = random.randint(plate_cx - plate_r + 110, plate_cx + plate_r - 110)
    py = random.randint(plate_cy - 60, plate_cy + 130)
    if (px - plate_cx) ** 2 + (py - plate_cy) ** 2 < (plate_r - 90) ** 2:
        draw.ellipse(
            (px - 5, py - 3, px + 5, py + 3), fill=(250, 240, 220, 255)
        )

# 11) Steam wisps
steam_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
sd = ImageDraw.Draw(steam_layer)
for cx_off, phase in [(-90, 0.0), (10, 1.2), (110, 0.6)]:
    pts = []
    base_x = plate_cx + cx_off
    for ty in range(0, 180, 6):
        sx = base_x + 16 * math.sin(0.06 * ty + phase)
        sy = 290 - ty
        pts.append((sx, sy))
    sd.line(pts, fill=(255, 255, 255, 130), width=10, joint="curve")
steam_layer = steam_layer.filter(ImageFilter.GaussianBlur(3))
img = Image.alpha_composite(img, steam_layer)
draw = ImageDraw.Draw(img, "RGBA")

# 12) Bottom red banner / ribbon with "MI GORENG"
banner_top = 868
banner_bot = 992
# tilted ribbon shape
ribbon_pts = [
    (-20, banner_top + 24),
    (W + 20, banner_top - 8),
    (W + 20, banner_bot + 8),
    (-20, banner_bot + 24),
]
draw.polygon(ribbon_pts, fill=(208, 26, 32, 255))
# top highlight stripe
hi_pts = [
    (-20, banner_top + 24),
    (W + 20, banner_top - 8),
    (W + 20, banner_top + 4),
    (-20, banner_top + 36),
]
draw.polygon(hi_pts, fill=(245, 90, 80, 220))

# Find a usable bold font on macOS
font = None
font_candidates = [
    "/System/Library/Fonts/Supplemental/Impact.ttf",
    "/System/Library/Fonts/Supplemental/Arial Black.ttf",
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    "/System/Library/Fonts/HelveticaNeue.ttc",
    "/System/Library/Fonts/Helvetica.ttc",
    "/Library/Fonts/Arial Black.ttf",
]
for path in font_candidates:
    if os.path.exists(path):
        try:
            font = ImageFont.truetype(path, 90)
            break
        except Exception:
            continue
if font is None:
    font = ImageFont.load_default()

text = "MI GORENG"
# Center text in the ribbon
bbox = draw.textbbox((0, 0), text, font=font)
tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
tx = (W - tw) // 2 - bbox[0]
ty = (banner_top + banner_bot) // 2 - th // 2 - bbox[1] - 4
# slight tilt: render onto its own layer then rotate small angle
text_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
tdraw = ImageDraw.Draw(text_layer)
# subtle dark stroke
tdraw.text(
    (tx, ty),
    text,
    font=font,
    fill=(255, 255, 255, 255),
    stroke_width=4,
    stroke_fill=(120, 0, 0, 255),
)
text_layer = text_layer.rotate(-2.2, resample=Image.BICUBIC)
img = Image.alpha_composite(img, text_layer)

# 13) Top corner star-burst sticker (small)
star_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
sd2 = ImageDraw.Draw(star_layer)
star_cx, star_cy = 870, 175
points = 12
inner = 38
outer = 70
poly = []
for i in range(points * 2):
    a = i / (points * 2) * math.tau - math.pi / 2
    r = outer if i % 2 == 0 else inner
    poly.append((star_cx + r * math.cos(a), star_cy + r * math.sin(a)))
sd2.polygon(poly, fill=(255, 255, 255, 255), outline=(208, 26, 32, 255))
font_small = None
for path in font_candidates:
    if os.path.exists(path):
        try:
            font_small = ImageFont.truetype(path, 24)
            break
        except Exception:
            continue
if font_small is None:
    font_small = ImageFont.load_default()
hot_text = "HOT!"
hb = sd2.textbbox((0, 0), hot_text, font=font_small)
htw = hb[2] - hb[0]
hth = hb[3] - hb[1]
sd2.text(
    (star_cx - htw // 2 - hb[0], star_cy - hth // 2 - hb[1]),
    hot_text,
    font=font_small,
    fill=(208, 26, 32, 255),
)
star_layer = star_layer.rotate(-15, resample=Image.BICUBIC)
img = Image.alpha_composite(img, star_layer)

# Save
out_dir = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "IndonesianSmallTalk",
    "Assets.xcassets",
    "AppIcon.appiconset",
)
out_path = os.path.join(out_dir, "AppIcon.png")
img.convert("RGB").save(out_path, "PNG", optimize=True)
print(f"Wrote {out_path}")
