"""말문(Malmun) 앱 아이콘 — 남색 바탕 위 흰 말풍선, 그 안에 빛이 새어 나오는 열린 문.
'말문이 트이다' 를 그림으로: 말풍선(말) + 문(문) + 문틈의 따뜻한 빛.

Run: python3 scripts/make_app_icon.py
Output:
  IndonesianSmallTalk/Assets.xcassets/AppIcon.appiconset/AppIcon.png  (1024, 앱 아이콘)
  IndonesianSmallTalk/Assets.xcassets/BrandMark.imageset/BrandMark.png (512, 앱 안 로고·지금 재생 그림)
색은 앱 코드의 Brand(LanguagePickerView.swift)와 같다.
"""

import json
import os

from PIL import Image, ImageDraw, ImageFilter

S = 4  # 4배로 그린 뒤 줄여서 가장자리를 매끄럽게
W = H = 1024 * S

BLUE = (59, 76, 202)    # Brand.blue
DEEP = (30, 41, 120)    # Brand.deep
GLOW = (255, 181, 71)   # Brand.glow
EMBER = (255, 132, 61)
WHITE = (255, 255, 255)


def p(*xy):
    return [v * S for v in xy]


def diagonal_gradient(size, c1, c2):
    w, h = size
    grad = Image.new("RGB", (w, h))
    px = grad.load()
    for y in range(h):
        for x in range(0, w, 4):
            t = (x + y) / (w + h)
            c = tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))
            for dx in range(4):
                if x + dx < w:
                    px[x + dx, y] = c
    return grad


def vertical_gradient(size, top, bottom):
    w, h = size
    grad = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(grad)
    for y in range(h):
        t = y / max(h - 1, 1)
        d.line([(0, y), (w, y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return grad


# 1) 바탕: 파랑 → 남색 대각선 + 위쪽 은은한 빛
img = diagonal_gradient((W, H), BLUE, DEEP).convert("RGBA")
halo = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ImageDraw.Draw(halo).ellipse(p(120, -260, 900, 520), fill=(130, 150, 255, 90))
img = Image.alpha_composite(img, halo.filter(ImageFilter.GaussianBlur(120 * S)))

# 2) 말풍선 그림자
shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
sd = ImageDraw.Draw(shadow)
sd.rounded_rectangle(p(196, 236, 828, 756), radius=180 * S, fill=(10, 14, 50, 120))
sd.polygon(p(300, 720, 236, 880, 450, 740), fill=(10, 14, 50, 120))
img = Image.alpha_composite(img, shadow.filter(ImageFilter.GaussianBlur(26 * S)))

# 3) 말풍선 (꼬리는 왼쪽 아래)
bubble = Image.new("RGBA", (W, H), (0, 0, 0, 0))
bd = ImageDraw.Draw(bubble)
bd.rounded_rectangle(p(196, 214, 828, 734), radius=180 * S, fill=WHITE)
bd.polygon(p(296, 690, 228, 862, 452, 716), fill=WHITE)
img = Image.alpha_composite(img, bubble)

# 4) 문틈: 안에서 새어 나오는 빛 (위 노랑 → 아래 주황)
DX = -34  # 문·빛·말소리 묶음을 말풍선 가운데로
door_l, door_t, door_r, door_b = 470 + DX, 318, 626 + DX, 628
light = vertical_gradient((int((door_r - door_l) * S), int((door_b - door_t) * S)), GLOW, EMBER).convert("RGBA")
mask = Image.new("L", light.size, 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, light.size[0] - 1, light.size[1] - 1], radius=10 * S, fill=255)
img.paste(light, (door_l * S, door_t * S), mask)

# 5) 바닥에 번지는 빛
spill = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ImageDraw.Draw(spill).polygon(p(470 + DX, 628, 626 + DX, 628, 700 + DX, 700, 440 + DX, 700), fill=GLOW + (120,))
img = Image.alpha_composite(img, spill.filter(ImageFilter.GaussianBlur(6 * S)))

# 6) 열린 문짝 (왼쪽 경첩, 보는 쪽으로 열려 있음)
panel = Image.new("RGBA", (W, H), (0, 0, 0, 0))
pd = ImageDraw.Draw(panel)
pd.polygon(p(470 + DX, 318, 392 + DX, 286, 392 + DX, 664, 470 + DX, 628), fill=BLUE)
pd.polygon(p(470 + DX, 318, 458 + DX, 313, 458 + DX, 633, 470 + DX, 628), fill=DEEP)  # 문짝 두께
pd.ellipse(p(404 + DX, 466, 424 + DX, 486), fill=GLOW)                      # 손잡이
img = Image.alpha_composite(img, panel)

# 7) 문틀 위 작은 말소리 (호 두 개)
waves = Image.new("RGBA", (W, H), (0, 0, 0, 0))
wd = ImageDraw.Draw(waves)
for i, r in enumerate((70, 120)):
    cx, cy = 650 + DX, 372
    wd.arc(p(cx - r, cy - r, cx + r, cy + r), start=-60, end=10, fill=BLUE + (255 - i * 70,), width=18 * S)
img = Image.alpha_composite(img, waves)

icon = img.convert("RGB").resize((1024, 1024), Image.LANCZOS)

root = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "IndonesianSmallTalk", "Assets.xcassets")
icon.save(os.path.join(root, "AppIcon.appiconset", "AppIcon.png"))

mark_dir = os.path.join(root, "BrandMark.imageset")
os.makedirs(mark_dir, exist_ok=True)
icon.resize((512, 512), Image.LANCZOS).save(os.path.join(mark_dir, "BrandMark.png"))
with open(os.path.join(mark_dir, "Contents.json"), "w") as f:
    json.dump({"images": [{"filename": "BrandMark.png", "idiom": "universal"}],
               "info": {"author": "xcode", "version": 1}}, f, indent=2)
print("saved")
