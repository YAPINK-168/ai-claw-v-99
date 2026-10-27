# -*- coding: utf-8 -*-
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(r"E:\GodotProjects\ai-claw-v-6\NewMotion\动作")
NAMES = ["蹲着待机", "下蹲", "倾身待机", "站起"]


def load(folder: Path, name: str) -> np.ndarray:
    return np.array(Image.open(folder / name).convert("RGBA"))


def stats(name: str) -> None:
    folder = ROOT / name
    files = sorted(folder.glob("*.png"))
    print(f"\n=== {name} n={len(files)} ===")
    if not files:
        return
    sizes = {}
    black_edge = 0
    green_edge = 0
    darkg = 0
    zero = 0
    for p in files:
        if p.stat().st_size == 0:
            zero += 1
            continue
        arr = load(folder, p.name)
        sizes[arr.shape[:2]] = sizes.get(arr.shape[:2], 0) + 1
        a = arr[..., 3]
        rgb = arr[..., :3].astype(np.int16)
        mx = rgb.max(axis=2)
        r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
        black = (a > 8) & (mx <= 22)
        green = (a > 8) & (g >= 70) & (g >= r + 18) & (g >= b + 18) & (r <= 90) & (b <= 90)
        dg = (a > 8) & (g >= r) & (g >= b) & (r <= 45) & (b <= 45) & (g <= 70)
        black_edge += int(black.sum())
        green_edge += int(green.sum())
        darkg += int(dg.sum())
    print("sizes", sizes, "zero", zero)
    print("opaque-near-black px total", black_edge, "green", green_edge, "darkg", darkg)
    first = load(folder, files[0].name)
    last = load(folder, files[-1].name)
    print("first", files[0].name, first.shape, "corner", tuple(first[0, 0]), "mid-bottom", tuple(first[-1, first.shape[1] // 2]))
    print("last", files[-1].name, last.shape, "corner", tuple(last[0, 0]), "mid-bottom", tuple(last[-1, last.shape[1] // 2]))
    if first.shape == last.shape:
        da = np.abs(first.astype(np.int16) - last.astype(np.int16)).mean()
        print("first-last mean abs", round(float(da), 3))
        # character bbox
        char = first[..., 3] > 16
        ys, xs = np.where(char)
        if len(xs):
            print("first bbox", int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max()))
        char2 = last[..., 3] > 16
        ys, xs = np.where(char2)
        if len(xs):
            print("last bbox", int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max()))
    # bottom 4 rows leftover
    bot = first[-6:]
    print("bottom6 opaque", int((bot[..., 3] > 8).sum()), "greenish", int(((bot[..., 3] > 8) & (bot[..., 1] > bot[..., 0] + 10)).sum()))
    # edge ring
    h, w = first.shape[:2]
    ring = np.zeros((h, w), dtype=bool)
    ring[:3] = True
    ring[-3:] = True
    ring[:, :3] = True
    ring[:, -3:] = True
    print("ring opaque", int(((first[..., 3] > 8) & ring).sum()))


for n in NAMES:
    stats(n)

idle = ROOT / "蹲着待机"
crouch = ROOT / "下蹲"
idle_files = sorted(idle.glob("*.png"))
crouch_files = sorted(crouch.glob("*.png"))
a = load(idle, idle_files[0].name)
b = load(crouch, crouch_files[-1].name)
print("\n=== transition 下蹲 last vs 蹲着待机 first ===")
print("sizes", b.shape, a.shape)
if a.shape == b.shape:
    print("mean abs", round(float(np.abs(a.astype(np.int16) - b.astype(np.int16)).mean()), 3))
