# -*- coding: utf-8 -*-
"""Warp 倾身待机 so the character overlaps 向左看 frame 1. Mirror to video/动作."""
from pathlib import Path
import shutil
import sys
import cv2
import numpy as np
from PIL import Image

NM_ROOT = Path(r"E:\GodotProjects\ai-claw-v-6\NewMotion\动作")
VIDEO_ROOT = Path(r"E:\GodotProjects\video\动作")
PROJECT_ROOT = Path(r"E:\GodotProjects\ai-claw-v-6")
SRC_ACTION = "倾身待机"
REF_ACTION = "向左看"


def opaque_bbox(arr: np.ndarray) -> tuple[int, int, int, int]:
    ys, xs = np.where(arr[..., 3] > 16)
    return int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())


def fill_transparent_rgb(arr: np.ndarray, steps: int = 3) -> np.ndarray:
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
        for c in range(3):
            ch = rgb[..., c]
            spread = cv2.dilate(ch, kernel)
            rgb[..., c] = np.where(mask > 0, ch, spread)
        mask = cv2.dilate(mask, kernel)
    out = arr.copy()
    out[..., :3] = rgb
    out[a == 0, 3] = 0
    return out


def affine_from_bboxes(src: tuple[int, int, int, int], ref: tuple[int, int, int, int]) -> np.ndarray:
    sx0, sy0, sx1, sy1 = src
    rx0, ry0, rx1, ry1 = ref
    sw = float(sx1 - sx0 + 1)
    sh = float(sy1 - sy0 + 1)
    rw = float(rx1 - rx0 + 1)
    rh = float(ry1 - ry0 + 1)
    scale = rh / sh
    src_cx = (sx0 + sx1) * 0.5
    src_feet = float(sy1)
    ref_cx = (rx0 + rx1) * 0.5
    ref_feet = float(ry1)
    # Keep width scale equal to height so the character does not squash.
    return np.array(
        [[scale, 0.0, ref_cx - scale * src_cx], [0.0, scale, ref_feet - scale * src_feet]],
        dtype=np.float32,
    )


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
    src_folder = NM_ROOT / SRC_ACTION
    ref_path = NM_ROOT / REF_ACTION / "001.png"
    files = sorted(src_folder.glob("*.png"))
    ref = np.array(Image.open(ref_path).convert("RGBA"))
    first = np.array(Image.open(files[0]).convert("RGBA"))
    src_bb = opaque_bbox(first)
    ref_bb = opaque_bbox(ref)
    matrix = affine_from_bboxes(src_bb, ref_bb)
    print("src bbox", src_bb, "ref bbox", ref_bb, "M", matrix.tolist(), flush=True)
    h, w = first.shape[:2]
    for i, p in enumerate(files, 1):
        arr = np.array(Image.open(p).convert("RGBA"))
        warped = cv2.warpAffine(
            arr,
            matrix,
            (w, h),
            flags=cv2.INTER_LINEAR,
            borderMode=cv2.BORDER_CONSTANT,
            borderValue=(0, 0, 0, 0),
        )
        out = fill_transparent_rgb(warped)
        Image.fromarray(out, "RGBA").save(p)
        if i == 1 or i == len(files) or i % 25 == 0:
            bb = opaque_bbox(out)
            print(f"  {p.name} bbox {bb}", flush=True)
    dst = VIDEO_ROOT / SRC_ACTION
    dst.mkdir(parents=True, exist_ok=True)
    for p in files:
        shutil.copy2(p, dst / p.name)
    print("mirrored ->", dst, flush=True)
    print("dropped import", drop_godot_import(SRC_ACTION), flush=True)


if __name__ == "__main__":
    main()
    sys.stdout.flush()
