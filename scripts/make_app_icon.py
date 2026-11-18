"""말문(Malmun) 앱 아이콘 — 맞물린 말풍선 두 개. 둥근 네모 둘은 '말문'의 두 ㅁ이기도 하다.
흰 풍선(내 말)에 주황 풍선(돌아오는 말)이 물려 있다. 납작한 면, 그림자 없음.

Run: python3 scripts/make_app_icon.py
Output:
  IndonesianSmallTalk/Assets.xcassets/AppIcon.appiconset/AppIcon.png   (1024, 앱 아이콘)
  IndonesianSmallTalk/Assets.xcassets/BrandMark.imageset/BrandMark.png (512, 앱 안 로고 · 지금 재생 그림)
  docs/app-icon.png (512), docs/icon.png (256)                         (소개 페이지 · 스토어 그림 재료)
색은 앱 코드의 Brand(LanguagePickerView.swift)와 같다. 바탕은 Brand.gradient 그대로다.
"""

import json
import os

from PIL import Image, ImageDraw

S = 4  # 4배로 그린 뒤 줄여서 가장자리를 매끄럽게
W = 1024 * S

BLUE = (59, 76, 202)    # Brand.solidBlue
DEEP = (30, 41, 120)    # Brand.deep
GLOW = (255, 181, 71)   # Brand.glow
EMBER = (255, 132, 61)
WHITE = (255, 255, 255)

SIDE = 410              # 풍선 한 변
RADIUS = 128            # 둥근 귀퉁이
TIP = 22                # 꼬리 쪽 귀퉁이 (거의 각지게)
GAP = 32                # 두 풍선 사이 띄움
FRONT = (182, 224)      # 흰 풍선 왼쪽 위
BACK = (432, 390)       # 주황 풍선 왼쪽 위


def gradient(size, c1, c2, diagonal):
    """c1 → c2. diagonal 이면 왼쪽 위 → 오른쪽 아래, 아니면 위 → 아래."""
    n = 64
    ramp = Image.new("L", (n, n))
    ramp.putdata([int(255 * ((x + y) / (2 * n - 2) if diagonal else y / (n - 1)))
                  for y in range(n) for x in range(n)])
    ramp = ramp.resize(size, Image.BICUBIC)
    return Image.composite(Image.new("RGB", size, c2), Image.new("RGB", size, c1), ramp)


def bubble_mask(origin, tail, grow=0):
    """한 귀퉁이(tail: 'bl' | 'br')만 각진 둥근 네모."""
    l, t = origin[0] - grow, origin[1] - grow
    r, b = origin[0] + SIDE + grow, origin[1] + SIDE + grow
    mask = Image.new("L", (W, W), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([v * S for v in (l, t, r, b)], radius=(RADIUS + grow) * S, fill=255)
    cx, cy = (l + r) / 2, (t + b) / 2
    quarter = (l, cy, cx, b) if tail == "bl" else (cx, cy, r, b)
    d.rounded_rectangle([v * S for v in quarter], radius=(TIP + grow) * S, fill=255)
    return mask


background = gradient((W, W), BLUE, DEEP, diagonal=True)
img = background.copy()

# 1) 뒤 풍선: 돌아오는 말 (꼬리는 오른쪽 아래)
back = bubble_mask(BACK, "br")
box = back.getbbox()
img.paste(gradient((box[2] - box[0], box[3] - box[1]), GLOW, EMBER, diagonal=False), box[:2], back.crop(box))

# 2) 앞 풍선 둘레를 바탕으로 띄운다
img.paste(background, (0, 0), bubble_mask(FRONT, "bl", grow=GAP))

# 3) 앞 풍선: 내 말 (꼬리는 왼쪽 아래)
img.paste(WHITE, (0, 0), bubble_mask(FRONT, "bl"))

icon = img.resize((1024, 1024), Image.LANCZOS)

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
assets = os.path.join(root, "IndonesianSmallTalk", "Assets.xcassets")
icon.save(os.path.join(assets, "AppIcon.appiconset", "AppIcon.png"))

mark_dir = os.path.join(assets, "BrandMark.imageset")
os.makedirs(mark_dir, exist_ok=True)
icon.resize((512, 512), Image.LANCZOS).save(os.path.join(mark_dir, "BrandMark.png"))
with open(os.path.join(mark_dir, "Contents.json"), "w") as f:
    json.dump({"images": [{"filename": "BrandMark.png", "idiom": "universal"}],
               "info": {"author": "xcode", "version": 1}}, f, indent=2)

icon.resize((512, 512), Image.LANCZOS).save(os.path.join(root, "docs", "app-icon.png"))
icon.resize((256, 256), Image.LANCZOS).save(os.path.join(root, "docs", "icon.png"))
print("saved")
