"""Render labelled crops of a sprite sheet to one PNG (dev helper).

Usage: python tools/contact_sheet.py <png> <out.png> x,y,w,h [x,y,w,h ...]
"""
import sys

from PIL import Image, ImageDraw

src = Image.open(sys.argv[1]).convert("RGBA")
out_path = sys.argv[2]
boxes = [tuple(int(v) for v in arg.split(",")) for arg in sys.argv[3:]]
SCALE = 3
PAD = 12
cells = []
for box in boxes:
    x, y, w, h = box
    crop = src.crop((x, y, x + w, y + h)).resize((w * SCALE, h * SCALE), Image.NEAREST)
    cells.append((box, crop))
row_h = max(c.height for _, c in cells) + 28
total_w = sum(c.width for _, c in cells) + PAD * (len(cells) + 1)
sheet = Image.new("RGBA", (total_w, row_h + PAD), (40, 40, 48, 255))
draw = ImageDraw.Draw(sheet)
cx = PAD
for box, crop in cells:
    sheet.alpha_composite(crop, (cx, 20))
    draw.text((cx, 4), "%d,%d %dx%d" % box, fill=(255, 255, 255, 255))
    cx += crop.width + PAD
sheet.save(out_path)
print(out_path, sheet.size)
