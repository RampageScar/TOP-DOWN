# Setup v2: SD 1.5 + pixel-art LoRA + AnimateDiff + Canny ControlNet

Turns one idle sprite into animation frames with ComfyUI, then cleans them into a game sprite sheet.
Files in this folder: `sprite_animatediff_.json` (the ComfyUI API workflow) and `make_spritesheet.py` (post-processing; needs Python 3 + Pillow: `pip install pillow`).

## How this relates to the game
The Godot game (`../timetravel_godot`) does **not** use these sprites yet: every character is drawn in code by `scripts/sprites.gd`, which is the
place to swap in PNG sprite sheets later. The idle art in `../Sprites/StandStill/` is 256x384 per frame with 8 directions, while the in-game hero is about 16x24 with 4 directions.
Decide the target size first (listed under "Decisions pending" in `../IMPROVEMENTS.md`). The workflow's default prompt says "side view", but the game uses a
top-down 3/4 view, so describe the view and direction you need in the positive prompt.

## Props from one generated image: `prep_prop.py`
For a single still prop (no animation), e.g. the courtyard statue. Generate it on a flat background, keep the full-size file in
`../Sprites/Props/`, then shrink it into the game:
```
python Code/prep_prop.py --src Sprites/Props/statue_src.webp --out timetravel_godot/assets/props/statue.png --height 116 --fill 535,870,690,1015 --erase 668,588,762,722 --stone-grey --preview build/statue_x4.png
```
- The background colour is read from the top-left pixel; darker copies of it (a baked shadow) are keyed out too, since the game draws its own shadows.
- `--fill x0,y0,x1,y1` paints out an emblem enclosed by a blue field (the box surrounds the whole field). `--erase` does the same inside an
  ellipse for an emblem that touches its rim. Both take source-pixel coordinates (open the source in any viewer to read them).
- `--stone-grey` turns warm sandstone into the game's statue grey; `--colors` (default 32) limits the palette.
- `--height` is in game pixels (the screen is 480x270; the hero is about 24 px tall).
- Then run Godot's import once (see `../CLAUDE.md`) and check it in the running game.
Pillow is installed per-user for Python 3.14 (`python -m pip install --user pillow`).

## Model files (ComfyUI/models/...)
| Folder | File |
|---|---|
| checkpoints | v1-5-pruned-emaonly.safetensors |
| loras | PixelArtRedmond-Lite64.safetensors |
| animatediff_models | mm_sd_v15_v2.ckpt |
| controlnet | control_v11p_sd15_canny_fp16.safetensors |

Custom node pack needed: ComfyUI-AnimateDiff-Evolved only. (Canny, ControlNet, LoRA and image-batch nodes are built into ComfyUI.)

## Run
1. Restart ComfyUI so it sees the new model files. Optional low-VRAM flag: `--lowvram`.
2. Drag `sprite_animatediff_.json` onto the canvas.
3. In each loader node, check the dropdown shows your file. If a name is missing, the file is in the wrong folder.
4. LoadImage: choose your sprite on a flat magenta (255,0,255) background.
5. Edit the positive prompt. Check the LoRA's download page for a trigger word and add it if one is listed.
6. Queue. Frames appear in `ComfyUI/output/sprite_anim/`.
7. `python make_spritesheet.py --frames <frames folder> --sprite <your sprite> --bg 255,0,255 --out build`

## The two main knobs
- KSampler denoise (0.55): more motion when higher, more faithful when lower.
- ControlNet strength (0.45) and end_percent (0.6): the outline guide. Higher = character keeps its shape but moves less.

## Important limitation
The workflow traces ONE outline (your idle sprite) and uses it for all 16 frames. That keeps the character stable but pulls every frame toward the same pose, so walking motion is weak. If motion is too small:
- lower ControlNet strength to 0.3 and end_percent to 0.4, or
- feed a different outline per frame: draw 4-8 key poses in Aseprite, load them as an image batch and send that into the Canny node's output slot instead of RepeatImageBatch. This is the reliable way to get a proper walk cycle.

## If something fails
- Out of memory: width/height 384 to 320 or 256, or frames 16 to 8.
- Missing node ADE_AnimateDiffLoaderGen1: update AnimateDiff-Evolved, or swap in its loader node and rewire model in/out.
