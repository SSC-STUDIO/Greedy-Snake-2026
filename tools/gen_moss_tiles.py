"""Cut the Level02 "moss" platform skin out of the Old Dark Castle interior set.

Outputs (assets/env/):
  moss_slab_a/b/c.png  48x48  moss cap (16px) + two rows of teal brick body
  moss_float_left/mid/right.png 16x21  small mossy block split into end/mid/end
  moss_fill.png 16x16 plain teal brick for deep rows
  moss_stair.png 32x41 stepped moss block (decor / small ledges)
  moss_arch.png 96x48 drain arch (decor)
  moss_vine.png 16x64 hanging vine strip (decor)
  moss_door.png 48x64 wooden door in stone frame (decor / level exit)
Run once, then `godot --headless --path . --import`.
"""
import os

from PIL import Image

SRC = "assets/external/gothicvania_patreon/Old-dark-Castle-tileset-Files/PNG/old-dark-castle-interior-tileset.png"
OUT = "assets/env"
sheet = Image.open(SRC).convert("RGBA")


def crop(x, y, w, h):
    return sheet.crop((x, y, x + w, y + h))


def save(img, name):
    path = os.path.join(OUT, name)
    img.save(path)
    print(path, img.size)


# --- moss caps: three 32px-wide moss tops, take their top 16px -------------
caps = [crop(416, 154, 32, 16), crop(464, 154, 32, 16), crop(608, 154, 32, 16)]
# body bricks: 32x32 blocks from the fill row
bodies = [crop(576, 80, 32, 32), crop(534, 80, 26, 32), crop(624, 80, 26, 32)]
for i, (cap, body) in enumerate(zip(caps, bodies)):
    slab = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    # cap row: 48px from a 32px cap by tiling (offset the seam per slab)
    for x in (0, 32):
        slab.alpha_composite(cap, (x, 0))
    slab.alpha_composite(cap.crop((0, 0, 16, 16)), (32, 0))
    # two body rows
    body = body.resize((32, 32), Image.NEAREST) if body.width != 32 else body
    for x in (0, 32):
        slab.alpha_composite(body.crop((0, 0, min(32, 48 - x), 32)), (x, 16))
    # make the cap read as a lip: darken the row just under the moss slightly
    px = slab.load()
    for y in range(16, 18):
        for x in range(48):
            r, g, b, a = px[x, y]
            px[x, y] = (int(r * 0.78), int(g * 0.78), int(b * 0.78), a)
    save(slab, "moss_slab_%s.png" % "abc"[i])

# --- floating moss block 48x21 -> three 16px pieces -----------------------
block = crop(64, 91, 48, 21)
save(block.crop((0, 0, 16, 21)), "moss_float_left.png")
save(block.crop((16, 0, 32, 21)), "moss_float_mid.png")
save(block.crop((32, 0, 48, 21)), "moss_float_right.png")

# --- deep fill ------------------------------------------------------------
fill = crop(48, 144, 16, 16)
px = fill.load()
for y in range(16):
    for x in range(16):
        r, g, b, a = px[x, y]
        px[x, y] = (int(r * 0.7), int(g * 0.7), int(b * 0.72), a)
save(fill, "moss_fill.png")

# --- decor ----------------------------------------------------------------
save(crop(224, 183, 32, 41), "moss_stair.png")
save(crop(80, 144, 96, 48), "moss_arch.png")
save(crop(720, 48, 16, 64), "moss_vine.png")
save(crop(656, 48, 48, 64), "moss_door.png")
save(crop(560, 146, 32, 30), "moss_rubble.png")
save(crop(304, 32, 160, 83), "moss_wall_block.png")
