# -*- coding: utf-8 -*-
"""Clear leftover plate/halo on crouch clips and fill transparent RGB so filtered sprites have no black fringe."""
from pathlib import Path
import shutil
import sys
import cv2
import numpy as np
from PIL import Image

NM_ROOT = Path(r"E:\GodotProjects\ai-claw-v-6\NewMotion\动作")
VIDEO_ROOT = Path(r"E:\GodotProjects\video\动作")
PROJECT_ROOT = Path(r"E:\GodotProjects\ai-claw-v-6")
ACTIONS = ["蹲着待机", "下蹲", "站起"]


def leftover_mask(arr: np.ndarray) -> np.ndarray:
    a = arr[..., 3]
    rgb = arr[..., :3].astype(np.int16)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    mx = np.maximum(np.maximum(r, g), b)
    near_black = (a > 0) & (mx <= 32)
    chroma = (
        (a > 0)
        & (g >= r + 12)
        & (g >= b + 12)
        & (r <= 110)
        & (b <= 110)
        & (g >= 36)
        & (g <= 220)
        & (mx <= 160)
    )
    dark_green = (a > 0) & (g >= r) & (g >= b) & (r <= 52) & (b <= 52) & (g <= 82) & (mx <= 82)
    return near_black | chroma | dark_green


def character_mask(arr: np.ndarray) -> np.ndarray:
    a = arr[..., 3]
    rgb = arr[..., :3].astype(np.int16)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    mx = np.maximum(np.maximum(r, g), b)
    chroma = (g >= r + 12) & (g >= b + 12) & (r <= 110) & (b <= 110) & (mx <= 160)
    return (a > 16) & (mx > 40) & ~chroma


def flood_from_edge(void: np.ndarray) -> np.ndarray:
    h, w = void.shape
    seed = np.where(void, np.uint8(255), np.uint8(0))
    mask = np.zeros((h + 2, w + 2), np.uint8)
    margin = 16
    band = np.zeros_like(void)
    band[:margin] = True
    band[-margin:] = True
    band[:, :margin] = True
    band[:, -margin:] = True
    ys, xs = np.where(void & band)
    if len(xs) == 0:
        return np.zeros_like(void)
    cv2.floodFill(seed, mask, (int(xs[0]), int(ys[0])), 128, loDiff=0, upDiff=0, flags=4)
    return seed == 128


def main_blob(char: np.ndarray) -> np.ndarray:
    n, labels, stats, _cents = cv2.connectedComponentsWithStats(char.astype(np.uint8), 8)
    if n <= 1:
        return char
    largest = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
    return labels == largest


def fill_transparent_rgb(arr: np.ndarray, steps: int = 4) -> np.ndarray:
    """Copy opaque RGB into neighboring transparent pixels so linear filtering cannot sample leftover black/green."""
    a = arr[..., 3]
    opaque = a > 0
    if not opaque.any():
        out = arr.copy()
        out[..., :3] = 0
        return out
    rgb = arr[..., :3].copy()
    mask = opaque.astype(np.uint8)
    kernel = np.ones((3, 3), np.uint8)
    for _ in range(steps):
        dilated_mask = cv2.dilate(mask, kernel)
        for c in range(3):
            ch = rgb[..., c]
            spread = cv2.dilate(ch, kernel)
            rgb[..., c] = np.where(mask > 0, ch, spread)
        mask = dilated_mask
    out = arr.copy()
    out[..., :3] = rgb
    out[a == 0, 3] = 0
    return out


def despill_edge(arr: np.ndarray) -> np.ndarray:
    a = arr[..., 3]
    rgb = arr[..., :3].astype(np.int16)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    mx = np.maximum(np.maximum(r, g), b)
    opaque = a >= 250
    kernel = np.ones((3, 3), np.uint8)
    erode = cv2.erode(opaque.astype(np.uint8), kernel, iterations=2).astype(bool)
    fringe = opaque & ~erode
    cap = np.maximum(r, b) + 6
    spill = fringe & (g > cap)
    if not spill.any():
        return arr
    out = arr.copy()
    g2 = np.minimum(g, cap).astype(np.uint8)
    out[..., 1] = np.where(spill, g2, out[..., 1])
    dark = fringe & (mx <= 48)
    if dark.any():
        out[dark, 3] = 0
    return out


def clean(arr: np.ndarray) -> np.ndarray:
    void = leftover_mask(arr)
    out = arr
    if void.any():
        reach = flood_from_edge(void)
        grow = cv2.dilate((reach | void).astype(np.uint8), np.ones((3, 3), np.uint8), iterations=3).astype(bool)
        grow &= ~character_mask(arr)
        if grow.any():
            out = out.copy()
            out[grow, 3] = 0
    char = character_mask(out)
    if char.any():
        main = main_blob(char)
        keep = cv2.dilate(main.astype(np.uint8), np.ones((5, 5), np.uint8), iterations=2).astype(bool)
        orphan = (out[..., 3] > 0) & ~keep
        if orphan.any():
            out = out.copy()
            out[orphan, 3] = 0
        ring = cv2.dilate(main.astype(np.uint8), np.ones((5, 5), np.uint8), iterations=1).astype(bool) & ~main
        rgb = out[..., :3].astype(np.int16)
        mx = rgb.max(axis=2)
        halo = ring & (out[..., 3] > 0) & (mx <= 90)
        if halo.any():
            out = out.copy()
            out[halo, 3] = 0
    out = despill_edge(out)
    return fill_transparent_rgb(out)


def process_folder(folder: Path) -> tuple[int, int]:
    files = sorted(folder.glob("*.png"))
    changed = 0
    total = 0
    for i, p in enumerate(files, 1):
        arr = np.array(Image.open(p).convert("RGBA"))
        out = clean(arr)
        delta = int(np.abs(out.astype(np.int16) - arr.astype(np.int16)).sum() > 0)
        n = int(((arr[..., 3] > 0) & (out[..., 3] == 0)).sum())
        total += n
        Image.fromarray(out, "RGBA").save(p)
        changed += 1
        if i == 1 or i == len(files) or i % 25 == 0:
            print(f"  {folder.name} {i}/{len(files)} keyed={n} touched={delta}", flush=True)
    return changed, total


def _unlink(path: Path) -> bool:
    try:
        if path.is_file():
            path.unlink()
            return True
    except OSError:
        pass
    return False


def drop_godot_import(action_name: str) -> int:
    folder = NM_ROOT / action_name
    n = 0
    for imp in list(folder.glob("*.png.import")):
        text = imp.read_text(encoding="utf-8", errors="ignore")
        for line in text.splitlines():
            if "res://.godot/imported/" not in line:
                continue
            rel = line.split("res://", 1)[-1].strip().strip('"]')
            ctex = PROJECT_ROOT / rel
            if _unlink(ctex):
                n += 1
            if _unlink(ctex.with_suffix(".md5")):
                n += 1
        if _unlink(imp):
            n += 1
    return n


def main() -> None:
    for name in ACTIONS:
        folder = NM_ROOT / name
        if not folder.is_dir():
            print("missing", folder, flush=True)
            continue
        c, n = process_folder(folder)
        print(f"NewMotion {name}: files={c} keyed_px={n}", flush=True)
        dst = VIDEO_ROOT / name
        dst.mkdir(parents=True, exist_ok=True)
        for p in sorted(folder.glob("*.png")):
            shutil.copy2(p, dst / p.name)
        print(f"mirrored -> {dst}", flush=True)
        dropped = drop_godot_import(name)
        print(f"dropped import cache {dropped}", flush=True)


if __name__ == "__main__":
    main()
    sys.stdout.flush()
