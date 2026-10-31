"""prep_prop.py - turn one large generated prop image (flat background) into a small, crisp game PNG.

Steps, in order, all at the source resolution until the last two:
  1. key out the flat background (sampled from the top-left corner). Pixels that are a darker copy of the background colour
     (a baked cast shadow) are keyed out too: the game draws its own shadows (Props.shadow).
  2. --fill: paint over an emblem with the colour of the field around it. The box must surround the field (e.g. a whole shield);
     everything inside it that is not field-coloured AND not connected to the box edge is a "hole" and gets filled.
  3. --stone-grey: recolour warm, low-saturation stone (sandstone / tan) to the game's cool statue grey, keeping brightness.
     Strongly saturated gold trim, greens and blues are left alone.
  4. crop to the content and shrink to --height pixels tall (box filter, alpha-weighted), then make alpha hard (on/off).
  5. reduce to --colors colours so the result reads as pixel art instead of a blurred photo.

Needs Python 3 + Pillow (`pip install pillow`). Example (the courtyard statue):
  python Code/prep_prop.py --src statue_src.webp --out timetravel_godot/assets/props/statue.png --height 116 \
      --fill 640,530,780,800 --fill 535,870,690,1015 --stone-grey --preview build/statue_x4.png
"""
import argparse, colorsys
from collections import deque
from PIL import Image


def key_background(im, tol):
    px = im.load()
    W, H = im.size
    bg = px[0, 0][:3]
    bb = sum(c * c for c in bg)
    for y in range(H):
        for x in range(W):
            r, g, b, a = px[x, y]
            k = (r * bg[0] + g * bg[1] + b * bg[2]) / bb          # how much of the background colour this pixel holds
            res = ((r - k * bg[0]) ** 2 + (g - k * bg[1]) ** 2 + (b - k * bg[2]) ** 2) ** 0.5
            if 0.45 < k < 1.2 and res < tol:
                px[x, y] = (0, 0, 0, 0)


def _is_field(p):
    r, g, b, a = p
    return a > 0 and b > r + 15 and b > g + 5                     # the blue heraldic field


def fill_holes(im, box):
    x0, y0, x1, y1 = box
    px = im.load()
    field = [px[x, y] for y in range(y0, y1) for x in range(x0, x1) if _is_field(px[x, y])]
    if not field:
        print("fill: no field colour found in", box)
        return
    avg = tuple(sum(p[i] for p in field) // len(field) for i in range(3)) + (255,)
    # flood from the box edge over non-field pixels: whatever non-field pixel is left unreached sits inside the field
    seen = set()
    q = deque()
    for x in range(x0, x1):
        q.extend([(x, y0), (x, y1 - 1)])
    for y in range(y0, y1):
        q.extend([(x0, y), (x1 - 1, y)])
    while q:
        x, y = q.popleft()
        if (x, y) in seen or not (x0 <= x < x1 and y0 <= y < y1) or _is_field(px[x, y]):
            continue
        seen.add((x, y))
        q.extend([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)])
    n = 0
    for y in range(y0, y1):
        for x in range(x0, x1):
            if (x, y) not in seen and not _is_field(px[x, y]):
                px[x, y] = avg
                n += 1
    print("fill", box, "->", n, "px")


def erase_ellipse(im, box):
    # for an emblem that touches the field's rim (so fill_holes can't tell it apart): repaint everything that isn't field-coloured
    # inside the ellipse that fits the box. Keep the box tight around the emblem so the rim stays outside it.
    x0, y0, x1, y1 = box
    px = im.load()
    cx, cy, rx, ry = (x0 + x1) / 2, (y0 + y1) / 2, (x1 - x0) / 2, (y1 - y0) / 2
    inside = [(x, y) for y in range(y0, y1) for x in range(x0, x1) if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1]
    field = [px[p] for p in inside if _is_field(px[p])]
    if not field:
        print("erase: no field colour found in", box)
        return
    avg = tuple(sum(p[i] for p in field) // len(field) for i in range(3)) + (255,)
    n = 0
    for p in inside:
        if not _is_field(px[p]):
            px[p] = avg
            n += 1
    print("erase", box, "->", n, "px")


def stone_grey(im, sat_max):
    px = im.load()
    W, H = im.size
    for y in range(H):
        for x in range(W):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if 0.03 < h < 0.16 and s < sat_max:                   # warm hue (orange..yellow), not strongly saturated
                L = 0.299 * r + 0.587 * g + 0.114 * b
                # same tint as castle_props.gd SG (#a8a59b): a touch warm in red, cooler in blue
                px[x, y] = (min(255, int(L * 1.02)), min(255, int(L)), min(255, int(L * 0.94)), a)


def shrink(im, height):
    im = im.crop(im.getbbox())
    w = max(1, round(im.width * height / im.height))
    small = im.convert("RGBa").resize((w, height), Image.BOX).convert("RGBA")
    px = small.load()
    for y in range(small.height):
        for x in range(small.width):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255) if a >= 128 else (0, 0, 0, 0)
    return small


def reduce_colours(im, n):
    alpha = im.getchannel("A")
    q = im.convert("RGB").quantize(colors=n, method=Image.Quantize.MEDIANCUT).convert("RGB")
    q.putalpha(alpha)
    return q


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--height", type=int, required=True, help="target height in game pixels")
    ap.add_argument("--tol", type=float, default=22.0, help="background key tolerance")
    ap.add_argument("--fill", action="append", default=[], help="x0,y0,x1,y1 in source pixels (repeatable)")
    ap.add_argument("--erase", action="append", default=[], help="x0,y0,x1,y1: emblem touching its rim, erased inside this ellipse")
    ap.add_argument("--stone-grey", action="store_true")
    ap.add_argument("--stone-sat-max", type=float, default=0.6)
    ap.add_argument("--colors", type=int, default=32)
    ap.add_argument("--preview", help="also save a 4x nearest-neighbour preview here")
    a = ap.parse_args()

    im = Image.open(a.src).convert("RGBA")
    key_background(im, a.tol)
    for f in a.fill:
        fill_holes(im, tuple(int(v) for v in f.split(",")))
    for e in a.erase:
        erase_ellipse(im, tuple(int(v) for v in e.split(",")))
    if a.stone_grey:
        stone_grey(im, a.stone_sat_max)
    out = reduce_colours(shrink(im, a.height), a.colors)
    out.save(a.out)
    print("saved", a.out, out.size)
    if a.preview:
        out.resize((out.width * 4, out.height * 4), Image.NEAREST).save(a.preview)


if __name__ == "__main__":
    main()
