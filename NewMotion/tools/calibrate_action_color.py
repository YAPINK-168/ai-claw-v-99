# -*- coding: utf-8 -*-
"""校准 NewMotion 序列帧色差（AI 视频片段色调不一致）。

用参考动作的角色像素 Lab 均值/方差，对目标动作做 Reinhard 色彩迁移；
只改不透明角色像素，保留 Alpha。

用法（工程根目录）:
  py -3 NewMotion/tools/calibrate_action_color.py --ref youyou_Idlebreath --prefix youyou_ --report
  py -3 NewMotion/tools/calibrate_action_color.py --ref youyou_Idlebreath --prefix youyou_ --apply --backup
  py -3 NewMotion/tools/calibrate_action_color.py --actions youyou_control2_4,youyou_standby_4 --apply
  py -3 NewMotion/tools/calibrate_action_color.py --ref youyou_Idlebreath --prefix AI- --write-profile

默认只 --report，不改文件。--apply 才会写回序列帧。
--write-profile 写出 NewMotion/动作/_color_profile.json，供运行时 modulate 轻量纠色。
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

PROJECT_ROOT = Path(__file__).resolve().parents[2]
ACTION_ROOT = PROJECT_ROOT / "NewMotion" / "动作"
PROFILE_NAME = "_color_profile.json"
BACKUP_DIR_NAME = "_color_backup"


@dataclass
class LabStats:
	mean: np.ndarray
	std: np.ndarray
	sample_pixels: int
	frame_count: int


def list_frame_files(folder: Path) -> list[Path]:
	pngs = sorted(folder.glob("*.png"))
	if pngs:
		return pngs
	return sorted(folder.glob("*.webp"))


def character_mask(rgba: np.ndarray) -> np.ndarray:
	"""Opaque character pixels; drop leftover greenscreen / near-black voids."""
	a = rgba[..., 3]
	rgb = rgba[..., :3].astype(np.int16)
	r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
	mx = np.maximum(np.maximum(r, g), b)
	chroma = (g >= r + 16) & (g >= b + 16) & (r <= 110) & (b <= 110)
	return (a > 128) & (mx > 40) & ~chroma


def load_rgba(path: Path) -> np.ndarray:
	return np.array(Image.open(path).convert("RGBA"))


def lab_pixels(rgba: np.ndarray, mask: np.ndarray) -> np.ndarray:
	bgr = cv2.cvtColor(rgba[..., :3], cv2.COLOR_RGB2BGR)
	lab = cv2.cvtColor(bgr, cv2.COLOR_BGR2LAB).astype(np.float32)
	return lab[mask]


def sample_indices(n: int, samples: int) -> list[int]:
	if n <= 0:
		return []
	k = min(samples, n)
	if k == 1:
		return [n // 2]
	return [int(i) for i in np.linspace(0, n - 1, num=k)]


def measure_clip(folder: Path, samples: int) -> LabStats | None:
	files = list_frame_files(folder)
	if not files:
		return None
	chunks: list[np.ndarray] = []
	for i in sample_indices(len(files), samples):
		rgba = load_rgba(files[i])
		mask = character_mask(rgba)
		if int(mask.sum()) < 200:
			continue
		chunks.append(lab_pixels(rgba, mask))
	if not chunks:
		return None
	allp = np.concatenate(chunks, axis=0)
	std = allp.std(axis=0)
	std = np.maximum(std, 1.0)
	return LabStats(allp.mean(axis=0), std, int(allp.shape[0]), len(files))


def reinhard_lab(src: LabStats, ref: LabStats, strength: float) -> tuple[np.ndarray, np.ndarray]:
	"""Return (scale, bias) such that out = src * scale + bias in Lab."""
	scale = ref.std / src.std
	bias = ref.mean - src.mean * scale
	# strength=1 full match; 0 identity
	scale = 1.0 + (scale - 1.0) * strength
	bias = bias * strength
	return scale.astype(np.float32), bias.astype(np.float32)


def apply_lab_to_rgba(rgba: np.ndarray, scale: np.ndarray, bias: np.ndarray) -> np.ndarray:
	out = rgba.copy()
	a = out[..., 3]
	fixable = a > 0
	if not writable.any():
		return out
	bgr = cv2.cvtColor(out[..., :3], cv2.COLOR_RGB2BGR)
	lab = cv2.cvtColor(bgr, cv2.COLOR_BGR2LAB).astype(np.float32)
	lab[writable] = lab[writable] * scale + bias
	lab[..., 0] = np.clip(lab[..., 0], 0, 255)
	lab[..., 1] = np.clip(lab[..., 1], 0, 255)
	lab[..., 2] = np.clip(lab[..., 2], 0, 255)
	bgr2 = cv2.cvtColor(lab.astype(np.uint8), cv2.COLOR_LAB2BGR)
	rgb2 = cv2.cvtColor(bgr2, cv2.COLOR_BGR2RGB)
	out[..., :3] = np.where(writable[..., None], rgb2, out[..., :3])
	# wipe RGB under fully transparent pixels (matches other tools)
	out[a == 0, :3] = 0
	return out


def rgb_gain_from_lab_shift(src: LabStats, ref: LabStats, strength: float) -> list[float]:
	"""Approximate RGB modulate for runtime preview (mean match only)."""
	# Convert mean Lab back to RGB roughly via a 1x1 image
	def lab_mean_to_rgb(mean: np.ndarray) -> np.ndarray:
		lab = np.zeros((1, 1, 3), np.uint8)
		lab[0, 0] = np.clip(mean, 0, 255).astype(np.uint8)
		bgr = cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)
		rgb = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)[0, 0].astype(np.float32)
		return np.maximum(rgb, 1.0)

	src_rgb = lab_mean_to_rgb(src.mean)
	ref_rgb = lab_mean_to_rgb(ref.mean)
	gain = ref_rgb / src_rgb
	gain = 1.0 + (gain - 1.0) * strength
	gain = np.clip(gain, 0.75, 1.35)
	return [float(gain[0]), float(gain[1]), float(gain[2])]


def save_frame(path: Path, rgba: np.ndarray) -> None:
	img = Image.fromarray(rgba, "RGBA")
	ext = path.suffix.lower()
	if ext == ".webp":
		img.save(path, "WEBP", quality=95, method=4)
	else:
		img.save(path, "PNG", optimize=True)


def backup_file(src: Path, backup_root: Path, action: str) -> None:
	dest = backup_root / action / src.name
	dest.parent.mkdir(parents=True, exist_ok=True)
	if not dest.exists():
		shutil.copy2(src, dest)


def resolve_actions(prefix: str, actions: str | None, ref: str) -> list[str]:
	names: list[str] = []
	if actions:
		names = [a.strip() for a in actions.split(",") if a.strip()]
	else:
		for p in sorted(ACTION_ROOT.iterdir()):
			if not p.is_dir() or p.name.startswith("_"):
				continue
			if prefix and not p.name.startswith(prefix):
				continue
			names.append(p.name)
	return [n for n in names if n != ref]


def format_delta(src: LabStats, ref: LabStats) -> str:
	d = src.mean - ref.mean
	return f"dLab=({d[0]:+.2f},{d[1]:+.2f},{d[2]:+.2f}) |dL|={abs(d[0]):.2f}"


def process_clip(
	action: str,
	ref: LabStats,
	*,
	samples: int,
	strength: float,
	apply: bool,
	backup: bool,
	backup_root: Path,
) -> dict:
	folder = ACTION_ROOT / action
	src = measure_clip(folder, samples)
	if src is None:
		return {"action": action, "ok": False, "error": "no_frames_or_mask"}
	scale, bias = reinhard_lab(src, ref, strength)
	gain = rgb_gain_from_lab_shift(src, ref, strength)
	delta = (src.mean - ref.mean).tolist()
	row = {
		"action": action,
		"ok": True,
		"frames": src.frame_count,
		"sample_pixels": src.sample_pixels,
		"lab_mean": src.mean.tolist(),
		"lab_std": src.std.tolist(),
		"delta_lab": delta,
		"rgb_gain": gain,
		"applied": False,
		"changed_files": 0,
	}
	print(f"  {action}: {format_delta(src, ref)} gainRGB=({gain[0]:.3f},{gain[1]:.3f},{gain[2]:.3f})")
	if not apply:
		return row
	files = list_frame_files(folder)
	changed = 0
	for path in files:
		rgba = load_rgba(path)
		fixed = apply_lab_to_rgba(rgba, scale, bias)
		if np.array_equal(fixed, rgba):
			continue
		if backup:
			backup_file(path, backup_root, action)
		save_frame(path, fixed)
		changed += 1
	row["applied"] = True
	row["changed_files"] = changed
	print(f"    wrote {changed}/{len(files)} frames")
	return row


def write_profile(ref_name: str, ref: LabStats, rows: list[dict], strength: float) -> Path:
	path = ACTION_ROOT / PROFILE_NAME
	clips: dict = {}
	refs: dict = {}
	if path.is_file():
		try:
			old = json.loads(path.read_text(encoding="utf-8"))
			if isinstance(old.get("clips"), dict):
				clips.update(old["clips"])
			if isinstance(old.get("refs"), dict):
				refs.update(old["refs"])
		except (OSError, json.JSONDecodeError):
			pass
	refs[ref_name] = {
		"lab_mean": ref.mean.tolist(),
		"lab_std": ref.std.tolist(),
		"strength": strength,
	}
	for row in rows:
		if not row.get("ok"):
			continue
		clips[row["action"]] = {
			"ref": ref_name,
			"rgb_gain": row["rgb_gain"],
			"delta_lab": row["delta_lab"],
		}
	payload = {
		"version": 1,
		"refs": refs,
		"clips": clips,
		"notes": "runtime 用 rgb_gain 作 self_modulate；像素级校准请 --apply",
	}
	path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
	return path


def main() -> int:
	parser = argparse.ArgumentParser(description="校准 NewMotion 动作序列帧色差")
	parser.add_argument("--ref", default="youyou_Idlebreath", help="参考动作名")
	parser.add_argument("--prefix", default="", help="只处理此前缀动作，如 youyou_ / AI- / doudou_")
	parser.add_argument("--actions", default="", help="逗号分隔动作名；指定后忽略 --prefix 枚举")
	parser.add_argument("--samples", type=int, default=5, help="每动作抽样帧数")
	parser.add_argument("--strength", type=float, default=1.0, help="校准强度 0~1")
	parser.add_argument("--report", action="store_true", help="只报告色差（默认）")
	parser.add_argument("--apply", action="store_true", help="写回校准后的序列帧")
	parser.add_argument("--backup", action="store_true", help="--apply 前备份到 NewMotion/动作/_color_backup/")
	parser.add_argument("--write-profile", action="store_true", help="写出 _color_profile.json")
	args = parser.parse_args()

	if not ACTION_ROOT.is_dir():
		print(f"找不到动作目录: {ACTION_ROOT}", file=sys.stderr)
		return 1

	strength = float(np.clip(args.strength, 0.0, 1.0))
	ref_folder = ACTION_ROOT / args.ref
	if not ref_folder.is_dir():
		print(f"参考动作不存在: {args.ref}", file=sys.stderr)
		return 1

	ref = measure_clip(ref_folder, args.samples)
	if ref is None:
		print(f"参考动作无法采样: {args.ref}", file=sys.stderr)
		return 1

	targets = resolve_actions(args.prefix, args.actions or None, args.ref)
	if not targets:
		print("没有待处理动作")
		return 1

	mode = "APPLY" if args.apply else "REPORT"
	print(f"[{mode}] ref={args.ref} Lab mean={ref.mean} std={ref.std}")
	print(f"targets={len(targets)} strength={strength}")

	backup_root = ACTION_ROOT / BACKUP_DIR_NAME
	rows: list[dict] = []
	for name in targets:
		rows.append(
			process_clip(
				name,
				ref,
				samples=args.samples,
				strength=strength,
				apply=args.apply,
				backup=args.backup,
				backup_root=backup_root,
			)
		)

	ok_rows = [r for r in rows if r.get("ok")]
	if ok_rows:
		dls = [abs(r["delta_lab"][0]) for r in ok_rows]
		print(
			f"done: {len(ok_rows)} clips, |dL| avg={sum(dls)/len(dls):.2f} max={max(dls):.2f}"
		)

	if args.write_profile or args.apply:
		path = write_profile(args.ref, ref, rows, strength)
		print(f"profile: {path}")

	# always write a report json next to tool for convenience
	report_path = Path(__file__).with_name("_color_report.json")
	report_path.write_text(
		json.dumps(
			{"ref": args.ref, "strength": strength, "applied": args.apply, "clips": rows},
			ensure_ascii=False,
			indent=2,
		),
		encoding="utf-8",
	)
	print(f"report: {report_path}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
