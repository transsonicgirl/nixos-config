"""Convert a directory tree of Hald CLUT images to .cube 3D LUTs.

Usage: hald2cube.py SRC_DIR DST_DIR [SIZE]

Hald CLUTs of any level are resampled (trilinear) to a SIZE^3 lattice, 33 by
default, since full level-12 Hald images would be 144^3 = ~100 MB per .cube.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image


def load_hald(path):
    # every film LUT in the pack is 8-bit RGB or grayscale
    a = np.asarray(Image.open(path).convert("RGB"), dtype=np.float64) / 255.0

    level = round(a.shape[0] ** (1 / 3))
    if a.shape[0] != a.shape[1] or level ** 3 != a.shape[0]:
        raise ValueError(f"{path}: {a.shape[1]}x{a.shape[0]} is not a Hald CLUT")
    n = level * level
    # Hald pixel order is red fastest, then green, then blue -> index [b, g, r]
    return a.reshape(n, n, n, 3)


def resample(lut, size):
    n = lut.shape[0]
    if n == size:
        return lut
    x = np.linspace(0, n - 1, size)
    i0 = np.floor(x).astype(int).clip(0, n - 2)
    f = x - i0
    # interpolate one axis at a time: b (0), g (1), r (2)
    for axis in range(3):
        shape = [1, 1, 1, 1]
        shape[axis] = size
        w = f.reshape(shape)
        lut = np.take(lut, i0, axis=axis) * (1 - w) + np.take(lut, i0 + 1, axis=axis) * w
    return lut


def write_cube(path, lut, title):
    size = lut.shape[0]
    rows = lut.reshape(-1, 3)  # [b, g, r] order flattens red-fastest, as .cube expects
    with open(path, "w") as out:
        out.write(f'TITLE "{title}"\n')
        out.write(f"LUT_3D_SIZE {size}\n\n")
        np.savetxt(out, rows.clip(0, 1), fmt="%.6f")


def main():
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])
    size = int(sys.argv[3]) if len(sys.argv) > 3 else 33
    for png in sorted(src.rglob("*.png")):
        rel = png.relative_to(src).with_suffix(".cube")
        if rel.name == "Negative.cube":
            continue  # plain inversion, not a film look
        (dst / rel.parent).mkdir(parents=True, exist_ok=True)
        write_cube(dst / rel, resample(load_hald(png), size), png.stem)
        print(rel)


if __name__ == "__main__":
    main()
