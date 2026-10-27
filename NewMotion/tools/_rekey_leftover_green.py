# -*- coding: utf-8 -*-
"""Re-key leftover greenscreen and wipe green RGB from transparent pixels."""
from __future__ import annotations

import shutil
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

PROJECT_ROOT = Path(r"E:\GodotProjects\ai-claw-v-6")
NM_ROOT = PROJECT_ROOT / "NewMotion" / "动作"
CUTOUT_ROOT = Path(r"E:\GodotProjects\cutout_png")
ACTIONS = [
	"摇杆轻轻左右扭",
	"欢迎回来在证明一次你自己",
	"玩游戏机",
	"看起来很有经验的样子",
	"这次我们稳一点",
	"蹲着",
	"蹲着待机",
]


def leftover_mask(arr: np.ndarray) -> np.ndarray:
	a = arr[..., 3]
	rgb = arr[..., :3].astype(np.int16)
	r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
	mx = np.maximum(np.maximum(r, g), b)
	near_black = (a > 0) & (mx <= 28)
	chroma = (
		(a > 0)
		& (g >= r + 16)
		& (g >= b + 16)
		& (r <= 110)
		& (b <= 110)
		& (g >= 40)
	)
	dark_green = (a > 0) & (g >= r) & (g >= b) & (r <= 52) & (b <= 52) & (g <= 90) & (mx <= 90)
	return near_black | chroma | dark_green


def character_mask(arr: np.ndarray) -> np.ndarray:
	a = arr[..., 3]
	rgb = arr[..., :3].astype(np.int16)
	r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
	mx = np.maximum(np.maximum(r, g), b)
	chroma = (g >= r + 16) & (g >= b + 16) & (r <= 110) & (b <= 110)
	return (a > 16) & (mx > 36) & ~chroma


def flood_from_edge(void: np.ndarray) -> np.ndarray:
	h, w = void.shape
	seed = np.where(void, np.uint8(255), np.uint8(0))
	mask = np.zeros((h + 2, w + 2), np.uint8)
	margin = 20
	band = np.zeros_like(void)
	band[:margin] = True
	band[-margin:] = True
	band[:, :margin] = True
	band[:, -margin:] = True
	ys, xs = np.where(void & band)
	if len(xs) == 0:
		ys, xs = np.where(void)
		if len(xs) == 0:
			return np.zeros_like(void)
	cv2.floodFill(seed, mask, (int(xs[0]), int(ys[0])), 128, loDiff=0, upDiff=0, flags=4)
	return seed == 128


def main_blob(char: np.ndarray) -> np.ndarray:
	n, labels, stats, _ = cv2.connectedComponentsWithStats(char.astype(np.uint8), 8)
	if n <= 1:
		return char
	largest = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
	return labels == largest


def despill_edge(arr: np.ndarray) -> np.ndarray:
	a = arr[..., 3]
	rgb = arr[..., :3].astype(np.int16)
	r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
	opaque = a >= 200
	kernel = np.ones((3, 3), np.uint8)
	erode = cv2.erode(opaque.astype(np.uint8), kernel, iterations=2).astype(bool)
	fringe = (a > 0) & ~erode
	cap = np.maximum(r, b) + 8
	spill = fringe & (g > cap) & (g >= r + 8) & (g >= b + 8)
	out = arr.copy()
	if spill.any():
		out[..., 1] = np.where(spill, np.minimum(g, cap).astype(np.uint8), out[..., 1])
	green_fringe = fringe & (g >= r + 16) & (g >= b + 16) & (r <= 90) & (b <= 90)
	if green_fringe.any():
		out[green_fringe, 3] = 0
	return out


def fill_transparent_rgb(arr: np.ndarray, steps: int = 4) -> np.ndarray:
	a = arr[..., 3]
	opaque = a > 0
	out = arr.copy()
	out[a == 0, :3] = 0
	if not opaque.any():
		return out
	rgb = out[..., :3].copy()
	mask = opaque.astype(np.uint8)
	kernel = np.ones((3, 3), np.uint8)
	for _ in range(steps):
		spread = cv2.dilate(rgb, kernel)
		rgb = np.where(mask[..., None] > 0, rgb, spread)
		mask = cv2.dilate(mask, kernel)
	out[..., :3] = rgb
	out[a == 0, 3] = 0
	return out


def clean(arr: np.ndarray) -> np.ndarray:
	void = leftover_mask(arr)
	out = arr.copy()
	if void.any():
		reach = flood_from_edge(void)
		grow = cv2.dilate((reach | void).astype(np.uint8), np.ones((3, 3), np.uint8), iterations=2).astype(bool)
		grow &= ~character_mask(arr)
		out[grow, 3] = 0
	char = character_mask(out)
	if char.any():
		main = main_blob(char)
		keep = cv2.dilate(main.astype(np.uint8), np.ones((5, 5), np.uint8), iterations=2).astype(bool)
		orphan = (out[..., 3] > 0) & ~keep
		if orphan.any():
			out[orphan, 3] = 0
		ring = cv2.dilate(main.astype(np.uint8), np.ones((5, 5), np.uint8), iterations=1).astype(bool) & ~main
		mx = out[..., :3].astype(np.int16).max(axis=2)
		halo = ring & (out[..., 3] > 0) & (mx <= 90)
		if halo.any():
			out[halo, 3] = 0
	out = despill_edge(out)
	return fill_transparent_rgb(out)


def leftover_green_px(arr: np.ndarray) -> int:
	a = arr[..., 3]
	rgb = arr[..., :3].astype(np.int16)
	r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
	opaque_green = (a > 0) & (g >= r + 16) & (g >= b + 16) & (r <= 110) & (b <= 110) & (g >= 40)
	trans_green = (a == 0) & (g >= r + 20) & (g >= b + 20) & (g > 80)
	return int(opaque_green.sum() + trans_green.sum())


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
			for path in (ctex, ctex.with_suffix(".md5")):
				if path.is_file():
					path.unlink()
					n += 1
		imp.unlink()
		n += 1
	return n


def process_folder(folder: Path) -> tuple[int, int, int]:
	files = sorted(folder.glob("*.png"))
	before = 0
	after = 0
	for i, path in enumerate(files, 1):
		arr = np.array(Image.open(path).convert("RGBA"))
		before += leftover_green_px(arr)
		out = clean(arr)
		after += leftover_green_px(out)
		Image.fromarray(out, "RGBA").save(path)
		if i == 1 or i == len(files) or i % 30 == 0:
			print(f"  {folder.name} {i}/{len(files)}", flush=True)
	return len(files), before, after


def main() -> None:
	for name in ACTIONS:
		folder = NM_ROOT / name
		if not folder.is_dir():
			print("missing", folder, flush=True)
			continue
		n, before, after = process_folder(folder)
		dropped = drop_godot_import(name)
		print(f"{name}: files={n} leftover {before}->{after} import_drop={dropped}", flush=True)
		cut = CUTOUT_ROOT / name
		if cut.is_dir():
			for path in sorted(folder.glob("*.png")):
				shutil.copy2(path, cut / path.name)
			print(f"  synced cutout_png/{name}", flush=True)


if __name__ == "__main__":
	main()
