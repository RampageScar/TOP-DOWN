#!/usr/bin/env python3
"""Turn ComfyUI AnimateDiff output frames into clean game-sprite frames.

Steps per frame:
  1. Chroma-key the flat background colour to transparent.
  2. Downscale with NEAREST to the original sprite size.
  3. Snap every pixel to the palette of your original sprite (keeps the look).
Then writes individual PNGs, a horizontal sprite sheet, and a preview GIF.

Usage:
  python make_spritesheet.py --frames output/sprite_anim --sprite character_idle.png \
      --bg 255,0,255 --out build
"""
import argparse, glob, os
from PIL import Image


def parse_rgb(s):
    r, g, b = (int(x) for x in s.split(","))
    return (r, g, b)


def palette_of(sprite, bg):
    px = sprite.convert("RGBA")
    cols = {p[:3] for p in px.getdata() if p[3] > 0 and p[:3] != bg}
    return sorted(cols)


def snap(img, palette, bg, tol):
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    src, dst = img.convert("RGB").load(), out.load()
    for y in range(img.height):
        for x in range(img.width):
            c = src[x, y]
            if sum((a - b) ** 2 for a, b in zip(c, bg)) <= tol ** 2:
                continue  # background -> transparent
            best = min(palette, key=lambda p: sum((a - b) ** 2 for a, b in zip(c, p)))
            dst[x, y] = best + (255,)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--frames", required=True, help="folder with ComfyUI PNG frames")
    ap.add_argument("--sprite", required=True, help="original sprite (for size + palette)")
    ap.add_argument("--bg", default="255,0,255", help="flat background colour R,G,B")
    ap.add_argument("--tol", type=int, default=80, help="background key tolerance")
    ap.add_argument("--out", default="build")
    ap.add_argument("--fps", type=int, default=8)
    a = ap.parse_args()

    bg = parse_rgb(a.bg)
    sprite = Image.open(a.sprite)
    size = sprite.size
    pal = palette_of(sprite, bg)
    if not pal:
        raise SystemExit("No palette found in sprite; check --bg")

    files = sorted(glob.glob(os.path.join(a.frames, "*.png")))
    if not files:
        raise SystemExit(f"No PNGs in {a.frames}")
    os.makedirs(a.out, exist_ok=True)

    frames = []
    for i, f in enumerate(files):
        im = Image.open(f).convert("RGB").resize(size, Image.NEAREST)
        fr = snap(im, pal, bg, a.tol)
        fr.save(os.path.join(a.out, f"frame_{i:02d}.png"))
        frames.append(fr)

    sheet = Image.new("RGBA", (size[0] * len(frames), size[1]), (0, 0, 0, 0))
    for i, fr in enumerate(frames):
        sheet.paste(fr, (i * size[0], 0))
    sheet.save(os.path.join(a.out, "spritesheet.png"))

    frames[0].save(
        os.path.join(a.out, "preview.gif"), save_all=True, append_images=frames[1:],
        duration=int(1000 / a.fps), loop=0, disposal=2, transparency=0,
    )
    print(f"{len(frames)} frames -> {a.out}/ (sheet {sheet.size[0]}x{sheet.size[1]})")


if __name__ == "__main__":
    main()
