"""Print the size of every PNG under the given asset folders (dev helper)."""
import glob
import os
import sys

from PIL import Image

roots = sys.argv[1:] or ["assets/external/gothicvania_patreon"]
for root in roots:
    print("==", root)
    for path in sorted(glob.glob(os.path.join(root, "**", "*.png"), recursive=True)):
        try:
            with Image.open(path) as im:
                print("  ", os.path.relpath(path, root).replace("\\", "/"), im.size)
        except OSError as exc:
            print("  ", path, exc)
