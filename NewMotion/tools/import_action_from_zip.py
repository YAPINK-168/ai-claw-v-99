"""Import a green-screen PNG sequence zip into NewMotion/动作 for newmotion_action_preview.

Usage:
  py -3 NewMotion/tools/import_action_from_zip.py <zip_path> [action_name]

If action_name is omitted, uses the zip file stem (e.g. 欢迎.zip -> 欢迎).
Writes transparent PNGs to: res://NewMotion/动作/<action_name>/
Also mirrors to E:/GodotProjects/video/动作/<action_name>/ when that folder exists.
Deletes the source zip after a successful import.
"""

from __future__ import annotations

import os
import shutil
import stat
import sys
import tempfile
import zipfile
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

PROJECT_ROOT = Path(__file__).resolve().parents[2]
ACTION_ROOT = PROJECT_ROOT / "NewMotion" / "动作"
VIDEO_ACTION_ROOT = Path(r"E:\GodotProjects\video\动作")


def key_frame(rgb: np.ndarray) -> np.ndarray:
	r = rgb[..., 0].astype(np.int16)
	g = rgb[..., 1].astype(np.int16)
	b = rgb[..., 2].astype(np.int16)
	key = (g >= 80) & (g >= r + 25) & (g >= b + 25) & (r <= 80) & (b <= 80)
	rgba = np.dstack([rgb, np.where(key, 0, 255).astype(np.uint8)])
	edge = rgba[..., 3] > 0
	gdom = (rgba[..., 1].astype(int) > rgba[..., 0] + 12) & (
		rgba[..., 1].astype(int) > rgba[..., 2] + 12
	)
	rgba[edge & gdom & (rgba[..., 1] > 170) & (rgba[..., 0] < 60) & (rgba[..., 2] < 60), 3] = 0
	mx = np.maximum(np.maximum(r, g), b)
	near_black = (rgba[..., 3] > 0) & (mx <= 26)
	if near_black.any():
		rgba[near_black, 3] = 0
	return fill_transparent_rgb(rgba)


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
		spread = cv2.dilate(rgb, kernel)
		rgb = np.where(mask[..., None] > 0, rgb, spread)
		mask = cv2.dilate(mask, kernel)
	out = arr.copy()
	out[..., :3] = rgb
	out[a == 0, 3] = 0
	return out


def extract_pngs(zip_path: Path, work_dir: Path) -> list[Path]:
	with zipfile.ZipFile(zip_path, "r") as zf:
		zf.extractall(work_dir)
	pngs = sorted(p for p in work_dir.rglob("*.png") if p.is_file())
	if not pngs:
		raise SystemExit(f"zip 里没有 png: {zip_path}")
	return pngs


def _unlink(path: Path) -> None:
	try:
		if path.is_file():
			path.unlink()
	except OSError:
		pass


def drop_godot_import(out_dir: Path) -> None:
	if not out_dir.is_dir():
		return
	for imp in list(out_dir.glob("*.png.import")):
		text = imp.read_text(encoding="utf-8", errors="ignore")
		for line in text.splitlines():
			if "res://.godot/imported/" not in line:
				continue
			rel = line.split("res://", 1)[-1].strip().strip('"]')
			ctex = PROJECT_ROOT / rel
			_unlink(ctex)
			_unlink(ctex.with_suffix(".md5"))
		_unlink(imp)


def write_action(pngs: list[Path], out_dir: Path) -> int:
	drop_godot_import(out_dir)
	if out_dir.exists():
		shutil.rmtree(out_dir)
	out_dir.mkdir(parents=True, exist_ok=True)
	for i, src in enumerate(pngs, 1):
		im = Image.open(src)
		if im.mode == "RGBA":
			arr = np.asarray(im)
			if int((arr[..., 3] < 250).sum()) > 100:
				rgba = fill_transparent_rgb(arr)
			else:
				rgba = key_frame(arr[..., :3])
		else:
			rgba = key_frame(np.asarray(im.convert("RGB")))
		Image.fromarray(rgba, "RGBA").save(out_dir / f"{i:03d}.png")
		if i == 1 or i == len(pngs) or i % 40 == 0:
			print(f"  {out_dir.name} {i}/{len(pngs)}", flush=True)
	return len(pngs)


def delete_zip(zip_path: Path) -> None:
	try:
		zip_path.chmod(stat.S_IWRITE)
	except OSError:
		pass
	try:
		os.system(f'attrib -R "{zip_path}" >nul 2>&1')
	except OSError:
		pass
	try:
		zip_path.unlink()
		print(f"deleted zip: {zip_path}", flush=True)
	except OSError as err:
		print(f"WARN could not delete zip: {zip_path} ({err})", flush=True)


def import_zip(zip_path: Path, action_name: str | None = None) -> int:
	if not zip_path.is_file():
		raise SystemExit(f"找不到 zip: {zip_path}")
	name = action_name if action_name else zip_path.stem
	with tempfile.TemporaryDirectory() as tmp:
		pngs = extract_pngs(zip_path, Path(tmp))
		out_dir = ACTION_ROOT / name
		count = write_action(pngs, out_dir)
		print(f"wrote {count} frames -> {out_dir}", flush=True)
		VIDEO_ACTION_ROOT.mkdir(parents=True, exist_ok=True)
		dst = VIDEO_ACTION_ROOT / name
		if dst.exists():
			shutil.rmtree(dst)
		shutil.copytree(out_dir, dst)
		print(f"mirrored -> {dst}", flush=True)
	delete_zip(zip_path)
	return count


def main() -> None:
	if len(sys.argv) < 2:
		raise SystemExit(__doc__)
	zip_path = Path(sys.argv[1]).resolve()
	action_name = sys.argv[2] if len(sys.argv) > 2 else None
	import_zip(zip_path, action_name)
	print("Open scenes/newmotion/newmotion_action_preview.tscn to preview.", flush=True)


if __name__ == "__main__":
	main()
