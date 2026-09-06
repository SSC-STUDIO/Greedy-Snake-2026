"""List bounding boxes of opaque islands in a sprite sheet (dev helper).

Usage: python tools/sheet_regions.py <png> [min_area]
"""
import sys
from collections import deque

from PIL import Image

path = sys.argv[1]
min_area = int(sys.argv[2]) if len(sys.argv) > 2 else 16
im = Image.open(path).convert("RGBA")
w, h = im.size
alpha = im.getchannel("A").load()
seen = bytearray(w * h)
boxes = []
for y in range(h):
    for x in range(w):
        if seen[y * w + x] or alpha[x, y] == 0:
            continue
        queue = deque([(x, y)])
        seen[y * w + x] = 1
        x0 = x1 = x
        y0 = y1 = y
        count = 0
        while queue:
            cx, cy = queue.popleft()
            count += 1
            x0, x1 = min(x0, cx), max(x1, cx)
            y0, y1 = min(y0, cy), max(y1, cy)
            for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx] and alpha[nx, ny] != 0:
                    seen[ny * w + nx] = 1
                    queue.append((nx, ny))
        if count >= min_area:
            boxes.append((x0, y0, x1 - x0 + 1, y1 - y0 + 1))
boxes.sort(key=lambda b: (b[1] // 16, b[0]))
for b in boxes:
    print("x=%d y=%d w=%d h=%d" % b)
