"""Key black bg for top bar + 当前投币 panels; crop; clear baked digit for Label."""
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

SRC_BG = Path(r"E:\GodotProjects\ai-claw-v-6\ui分件\ChatGPT Image 2026年10月26日 09_54_17.png")
SRC_COIN = Path(r"E:\GodotProjects\ai-claw-v-6\ui分件\ChatGPT Image 2026年10月26日 09_55_52.png")
OUT = Path(r"E:\GodotProjects\ai-claw-v-6\assets\youyou_ui")


def key_black(arr: np.ndarray, thr: int = 28) -> np.ndarray:
	out = arr.copy()
	r, g, b, a = out[:, :, 0], out[:, :, 1], out[:, :, 2], out[:, :, 3]
	mx = np.maximum(np.maximum(r, g), b)
	black = (mx <= thr) | ((r <= thr) & (g <= thr) & (b <= thr))
	out[:, :, 3] = np.where(black, np.uint8(0), a)
	fringe = (mx <= thr + 40) & (out[:, :, 3] > 0)
	fade = np.clip((mx.astype(np.float32) - thr) / 40.0, 0.0, 1.0)
	out[:, :, 3] = np.where(
		fringe,
		(out[:, :, 3].astype(np.float32) * fade).astype(np.uint8),
		out[:, :, 3],
	)
	return out


def crop_alpha(arr: np.ndarray, pad: int = 4) -> np.ndarray:
	a = arr[:, :, 3]
	ys, xs = np.where(a > 8)
	if len(xs) == 0:
		return arr
	x0 = max(0, int(xs.min()) - pad)
	x1 = min(arr.shape[1], int(xs.max()) + 1 + pad)
	y0 = max(0, int(ys.min()) - pad)
	y1 = min(arr.shape[0], int(ys.max()) + 1 + pad)
	return arr[y0:y1, x0:x1]


def fill_transparent_rgb(arr: np.ndarray, steps: int = 3) -> np.ndarray:
	out = arr.copy()
	h, w = out.shape[:2]
	for _ in range(steps):
		opaque = out[:, :, 3] > 16
		if not opaque.any():
			break
		for c in range(3):
			ch = out[:, :, c].astype(np.float32)
			acc = np.zeros_like(ch)
			cnt = np.zeros_like(ch)
			for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
				y0, y1 = max(0, dy), min(h, h + dy)
				x0, x1 = max(0, dx), min(w, w + dx)
				sy0, sy1 = max(0, -dy), min(h, h - dy)
				sx0, sx1 = max(0, -dx), min(w, w - dx)
				src_a = opaque[sy0:sy1, sx0:sx1]
				acc[y0:y1, x0:x1] += np.where(src_a, ch[sy0:sy1, sx0:sx1], 0)
				cnt[y0:y1, x0:x1] += src_a.astype(np.float32)
			need = (~opaque) & (cnt > 0)
			out[:, :, c] = np.where(
				need,
				(acc / np.maximum(cnt, 1)).astype(np.uint8),
				out[:, :, c],
			)
	return out


def dilate(mask: np.ndarray, iters: int = 2) -> np.ndarray:
	m = mask.astype(np.uint8)
	h, w = m.shape
	for _ in range(iters):
		acc = m.copy()
		for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (-1, 1), (1, -1), (1, 1)):
			y0, y1 = max(0, dy), min(h, h + dy)
			x0, x1 = max(0, dx), min(w, w + dx)
			sy0, sy1 = max(0, -dy), min(h, h - dy)
			sx0, sx1 = max(0, -dx), min(w, w - dx)
			acc[y0:y1, x0:x1] = np.maximum(acc[y0:y1, x0:x1], m[sy0:sy1, sx0:sx1])
		m = acc
	return m.astype(bool)


def clear_digit_hole(arr: np.ndarray) -> tuple[np.ndarray, tuple[int, int, int, int]]:
	"""Clear baked '0' glyph; return (image, label_rect_xywh in local px)."""
	out = arr.copy()
	h, w = out.shape[:2]
	# Number sits after 「当前投币」, before 「枚」 — mid-right of pill body.
	x0, x1 = int(w * 0.50), int(w * 0.74)
	y0, y1 = int(h * 0.22), int(h * 0.82)
	r = out[y0:y1, x0:x1, 0].astype(np.int16)
	g = out[y0:y1, x0:x1, 1].astype(np.int16)
	b = out[y0:y1, x0:x1, 2].astype(np.int16)
	a = out[y0:y1, x0:x1, 3]
	# Dark blue fill of the digit
	dark = (b > r + 15) & (b > g + 5) & (r < 130) & (g < 150) & (a > 40)
	# White outline around digit
	outline = (r > 210) & (g > 210) & (b > 220) & (a > 80)
	# Restrict outline to near dark ink so we don't wipe sparkles
	near = dilate(dark, 4)
	mask = dark | (outline & near)
	mask = dilate(mask, 3)
	region = out[y0:y1, x0:x1].copy()
	keep = (a > 40) & (~mask)
	if keep.any():
		fill_rgb = region[:, :, :3][keep].mean(axis=0).astype(np.uint8)
	else:
		fill_rgb = np.array([195, 225, 248], dtype=np.uint8)
	for c in range(3):
		region[:, :, c] = np.where(mask, fill_rgb[c], region[:, :, c])
	out[y0:y1, x0:x1] = region
	# Label box from mask bbox
	ys, xs = np.where(mask)
	if len(xs) == 0:
		rect = (int(w * 0.55), int(h * 0.30), int(w * 0.16), int(h * 0.45))
	else:
		lx0 = int(xs.min()) + x0 - 8
		lx1 = int(xs.max()) + x0 + 8
		ly0 = int(ys.min()) + y0 - 6
		ly1 = int(ys.max()) + y0 + 6
		rect = (lx0, ly0, lx1 - lx0, ly1 - ly0)
	return out, rect


def process(src: Path, name: str, clear_digit: bool = False):
	arr = np.array(Image.open(src).convert("RGBA"))
	arr = key_black(arr)
	arr = crop_alpha(arr)
	arr = fill_transparent_rgb(arr)
	rect = None
	if clear_digit:
		arr, rect = clear_digit_hole(arr)
	out = OUT / name
	Image.fromarray(arr).save(out)
	print(f"{name}: {arr.shape[1]}x{arr.shape[0]} opaque={float((arr[:,:,3]>8).mean()*100):.1f}%")
	if rect:
		print(f"  digit_rect xywh={rect}")
	return arr, rect


def main() -> None:
	OUT.mkdir(parents=True, exist_ok=True)
	process(SRC_BG, "hud_top_bg.png")
	_, rect = process(SRC_COIN, "hud_coin.png", clear_digit=True)
	process(SRC_COIN, "hud_coin_sample.png", clear_digit=False)
	if rect:
		(OUT / "hud_coin_digit_rect.txt").write_text(
			f"{rect[0]},{rect[1]},{rect[2]},{rect[3]}\n", encoding="utf-8"
		)


if __name__ == "__main__":
	main()
