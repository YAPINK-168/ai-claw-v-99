extends RefCounted
## Boss 炮口：贴图像素相对内容中心，再换算到 logic 的 0~1 战场坐标。

const BOSS_TEX_SIZE := 512.0

const BOSS1_DRAW_PX := 236.0 ## plane_view.BOSS_PX[0]
const BOSS2_DRAW_PX := 258.0 ## plane_view.BOSS_PX[1]
const BOSS3_DRAW_PX := 272.0 ## plane_view.BOSS_PX[2]
const BOSS4_DRAW_PX := 298.0 ## plane_view.BOSS_PX[3]
const BOSS5_DRAW_PX := 336.0 ## plane_view.BOSS_PX[4]

enum Boss1Slot { WING_L, WING_R, LAUNCHER, REAR }

## 相对贴图内容中心 (≈255,255)，+X 右、+Y 下（与屏幕一致）
const BOSS1_TEX_OFF: Dictionary = {
	Boss1Slot.WING_L: Vector2(-145.0, 10.0),
	Boss1Slot.WING_R: Vector2(145.0, 10.0),
	Boss1Slot.LAUNCHER: Vector2(0.0, -138.0),
	Boss1Slot.REAR: Vector2(0.0, 214.0),
}


enum Boss2Slot { WING_L, WING_R, LAUNCHER }

const BOSS2_TEX_OFF: Dictionary = {
	Boss2Slot.WING_L: Vector2(-180.0, 23.0),
	Boss2Slot.WING_R: Vector2(180.0, 23.0),
	Boss2Slot.LAUNCHER: Vector2(0.0, -202.0),
}


enum Boss3Slot { WING_L, WING_R, LAUNCHER, CENTER_FAN }

const BOSS3_TEX_OFF: Dictionary = {
	Boss3Slot.WING_L: Vector2(-226.0, 117.0),
	Boss3Slot.WING_R: Vector2(226.0, 117.0),
	Boss3Slot.LAUNCHER: Vector2(0.0, -112.0),
	Boss3Slot.CENTER_FAN: Vector2(0.0, 147.0),
}


enum Boss4Slot { SLICE_T1, SLICE_T2, SLICE_T3, DECK, SALVO_L, SALVO_R }

## 三刀切掉落带中心 + 甲板导弹巢（512 归一化切带中心换算）
const BOSS4_TEX_OFF: Dictionary = {
	Boss4Slot.SLICE_T1: Vector2(0.0, -208.0),
	Boss4Slot.SLICE_T2: Vector2(0.0, -152.0),
	Boss4Slot.SLICE_T3: Vector2(0.0, -96.0),
	Boss4Slot.DECK: Vector2(0.0, -8.0),
	Boss4Slot.SALVO_L: Vector2(-128.0, -50.0),
	Boss4Slot.SALVO_R: Vector2(128.0, -50.0),
}


enum Boss5Slot { LAUNCHER, WING_L, WING_R, BELLY, SALVO_L, SALVO_R }

const BOSS5_TEX_OFF: Dictionary = {
	Boss5Slot.LAUNCHER: Vector2(0.0, -123.0),
	Boss5Slot.WING_L: Vector2(-169.0, 32.0),
	Boss5Slot.WING_R: Vector2(169.0, 32.0),
	Boss5Slot.BELLY: Vector2(0.0, -42.0),
	Boss5Slot.SALVO_L: Vector2(-104.0, -31.0),
	Boss5Slot.SALVO_R: Vector2(104.0, -31.0),
}

## One source for shader cuts, dropped texture regions and their world origins.
static func approved_art_cuts(style: int) -> Array[Rect2]:
	match style:
		0:
			return [Rect2(236,48,40,140),Rect2(38,60,140,424),Rect2(334,60,140,424)]
		2:
			return [Rect2(222,104,68,80),Rect2(12,164,182,228),Rect2(318,164,182,228)]
		3:
			return [Rect2(180,20,152,56),Rect2(180,76,152,56),Rect2(180,132,152,56)]
	return []


static func _norm_tex(tex: Vector2, draw_px: float, play_size: Vector2) -> Vector2:
	var pw := maxf(play_size.x, 1.0)
	var ph := maxf(play_size.y, 1.0)
	var sc := draw_px / BOSS_TEX_SIZE
	return Vector2(tex.x * sc / pw, tex.y * sc / ph)


static func boss1_norm(slot: int, play_size: Vector2) -> Vector2:
	var tex: Vector2 = BOSS1_TEX_OFF.get(slot, Vector2.ZERO)
	return _norm_tex(tex, BOSS1_DRAW_PX, play_size)


static func boss2_norm(slot: int, play_size: Vector2) -> Vector2:
	var tex: Vector2 = BOSS2_TEX_OFF.get(slot, Vector2.ZERO)
	return _norm_tex(tex, BOSS2_DRAW_PX, play_size)


static func boss1_world(bx: float, by: float, slot: int, play_size: Vector2) -> Vector2:
	var off := boss1_norm(slot, play_size)
	return Vector2(bx + off.x, by + off.y)


static func boss1_muzzle_offs(play_size: Vector2) -> Array:
	return [
		boss1_norm(Boss1Slot.WING_L, play_size),
		boss1_norm(Boss1Slot.WING_R, play_size),
		boss1_norm(Boss1Slot.LAUNCHER, play_size),
	]


static func boss2_world(bx: float, by: float, slot: int, play_size: Vector2) -> Vector2:
	var off := boss2_norm(slot, play_size)
	return Vector2(bx + off.x, by + off.y)


static func boss2_muzzle_offs(play_size: Vector2) -> Array:
	return [
		boss2_norm(Boss2Slot.WING_L, play_size),
		boss2_norm(Boss2Slot.WING_R, play_size),
		boss2_norm(Boss2Slot.LAUNCHER, play_size),
	]


static func boss3_norm(slot: int, play_size: Vector2) -> Vector2:
	var tex: Vector2 = BOSS3_TEX_OFF.get(slot, Vector2.ZERO)
	return _norm_tex(tex, BOSS3_DRAW_PX, play_size)


static func boss3_world(bx: float, by: float, slot: int, play_size: Vector2) -> Vector2:
	var off := boss3_norm(slot, play_size)
	return Vector2(bx + off.x, by + off.y)


static func boss3_muzzle_offs(play_size: Vector2) -> Array:
	return [
		boss3_norm(Boss3Slot.WING_L, play_size),
		boss3_norm(Boss3Slot.CENTER_FAN, play_size),
		boss3_norm(Boss3Slot.WING_R, play_size),
	]


static func boss4_norm(slot: int, play_size: Vector2) -> Vector2:
	var tex: Vector2 = BOSS4_TEX_OFF.get(slot, Vector2.ZERO)
	return _norm_tex(tex, BOSS4_DRAW_PX, play_size)


static func boss4_world(bx: float, by: float, slot: int, play_size: Vector2) -> Vector2:
	var off := boss4_norm(slot, play_size)
	return Vector2(bx + off.x, by + off.y)


static func boss4_muzzle_offs(play_size: Vector2) -> Array:
	var d := boss4_norm(Boss4Slot.DECK, play_size)
	return [d, d, d]


static func boss5_norm(slot: int, play_size: Vector2) -> Vector2:
	var tex: Vector2 = BOSS5_TEX_OFF.get(slot, Vector2.ZERO)
	return _norm_tex(tex, BOSS5_DRAW_PX, play_size)


static func boss5_world(bx: float, by: float, slot: int, play_size: Vector2) -> Vector2:
	var off := boss5_norm(slot, play_size)
	return Vector2(bx + off.x, by + off.y)


static func boss5_muzzle_offs(play_size: Vector2) -> Array:
	return [
		boss5_norm(Boss5Slot.SALVO_L, play_size),
		boss5_norm(Boss5Slot.BELLY, play_size),
		boss5_norm(Boss5Slot.SALVO_R, play_size),
	]


static func part_origin_norm(boss_style: int, part: int, play_size: Vector2) -> Vector2:
	## part: 0=launcher 1=wing_l 2=wing_r
	if boss_style in [0,2,3]:
		var cuts := approved_art_cuts(boss_style)
		var center := cuts[clampi(part,0,2)].get_center()-Vector2(256,256)
		var draw_px: float = [BOSS1_DRAW_PX,BOSS2_DRAW_PX,BOSS3_DRAW_PX,BOSS4_DRAW_PX,BOSS5_DRAW_PX][boss_style]
		return _norm_tex(center,draw_px,play_size)
	if boss_style == 1:
		var s1 := [Boss2Slot.LAUNCHER, Boss2Slot.WING_L, Boss2Slot.WING_R]
		return boss2_norm(s1[clampi(part, 0, 2)], play_size)
	if boss_style == 4:
		var s4 := [Boss5Slot.LAUNCHER, Boss5Slot.WING_L, Boss5Slot.WING_R]
		return boss5_norm(s4[clampi(part, 0, 2)], play_size)
	return Vector2.ZERO
