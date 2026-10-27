extends RefCounted
class_name PlaneLogic
## 飞机大战纯逻辑：无时限生存、心形三命、单局节奏（热身→推进→五 Boss）。坐标 0～1。

const BossMuzzleLayout = preload("res://街机小游戏/scripts/plane/boss_muzzle_layout.gd")

const ROUND_WARMUP_SEC := 3.0 ## 少量敌机、不开火
const ROUND_WAVE2_START_SEC := 9.0 ## 第二波（海量）起点
const ROUND_WAVE3_START_SEC := 15.0 ## 第三段：更高密度刷怪
const ROUND_PUSH_END_SEC := 20.0 ## 杂兵阶段结束；Boss 从 20s 入场
const BOSS_CHAIN_FIRST_INDEX := 1 ## 正式链跳过 1 号 Boss，从 2 号（双炮舰）起
const BOSS_CHAIN_BOSS_COUNT := 4 ## 2～5 号共四场
const SIM_TIMEOUT := 90.0
const MAX_HP := 3
const MAX_ENEMIES := 10
const MAX_BULLETS := 64
const MAX_EBULLETS := 16
const EBULLET_CAP_FOB := 6
const EBULLET_CAP_BOSS := 14
const EBULLET_BOSS_P2_RESERVE := 8 ## 破管后留给 Boss 齐射/导弹，避免伴飞杂兵占满池子
const MAX_ITEMS := 2
const MAX_BOSS_PARTS := 10
const BOSS_PART_HIT_W := 0.072
const BOSS_PART_HIT_H := 0.052
const MAX_FX := 12
const MAX_MISSILES := 4
const MAX_WINGS := 2
const POWER_MAX := 8
const WING_OFFSET_X := 0.065 ## 独立僚机贴合新版主机翼展，发射点同步对齐
const WING_OFFSET_Y := 0.008
const POWER_TITLES := ["", "双管", "重炮", "僚机", "扇形", "穿甲", "追踪", "全开", "终极"]
const SCORE_SOFT_CAP := 24
const BOMB_MAX := 2
const BOMB_START := 1
const WAVE_PHRASE_MAX := 3
const POWER_STEP_LOCK := 8.0
const GRAZE_PAD := 0.04
const GRAZE_AMT := 0.7
const GRAZE_MAX_PER_SEC := 3
const COMBO_WINDOW := 1.2
const COMBO_TIER_LUANWU := 50
const COMBO_TIER_WUSHUANG := 100
const COMBO_TIER_FENGSHEN := 160
const SCORE_GREEN_GEM := 121
const SCORE_RUBY_GEM := 348
const COMBO_EXTRA_MAX := 1

const PLAYER_Y := 0.82 ## 出生点；实机用 player_y
const PLAYER_Y_MIN := 0.18
const PLAYER_Y_MAX := 0.90
const PLAYER_X_MIN := 0.08
const PLAYER_X_MAX := 0.92
const MOVE_SPEED := 0.46 ## 实机略慢，便于躲弹
const PLAYER_HIT_W := 0.062 ## 视觉缩小后仍约 60% 机身
const PLAYER_HIT_H := 0.036
const BULLET_HIT := 0.022
const BULLET_SPEED := 1.22
const BULLET_SPEED_DOUBLE := 1.30
const SHOOT_CD := 0.075
const SHOOT_CD_DOUBLE := 0.048
const MISSILE_CD := 0.25
const WING_SHOOT_CD := 0.065
const DIVE_WARN := 0.28
const DIVE_Y := 0.38
const EBULLET_SPEED := 0.34 ## 杂兵 wave≥6
const EBULLET_SPEED_TEACH := 0.28 ## 杂兵教学 / 1～3 号
const EBULLET_SPEED_LATE := 0.38 ## 仅 4～5 号 Boss
const LASER_SEC := 2.4
const LASER_TICK := 0.14
const LASER_TICK_BOSS := 0.18
const LASER_TICK_BOSS_LATE := 0.20
const LASER_W := 0.07
const LASER_GAP_MIN := 22.0
const LASER_SPAWN_MAX := 2
const SUPER_SEC := 5.0
const SUPER_TICK := 0.10
const SUPER_TICK_BOSS := 0.22
const SUPER_W := 0.046
const SUPER_SPREAD := 0.46 ## 左右斜线收窄，更接近金刃参考图
const SUPER_DMG := 2
const SUPER_BOSS_DMG := 1
const ENERGY_MAX := 100.0
const ENERGY_KILL := 2.6 ## ordinary 一局大约一管
const ENERGY_ELITE := 3.0
const ENERGY_BOSS := 7.0
const ENERGY_SUPER_MUL := 0.40
const NUKE_SCORE := 2
const NUKE_MAX := 3
const BOSS_Y := 0.23
const BOSS_X_MIN := 0.12
const BOSS_X_MAX := 0.88
const BOSS_Y_MIN := 0.12
const BOSS_Y_MAX := 0.52 ## 可压到中场，但仍高于玩家活动区下限
## 台架 TTK：站桩无道具 ≥7s；激光+双连发 7～15 且不得 <5。数字高于文案「约22」是为了过台架。
const BOSS_TTK_MUL := 0.8 ## Boss 本体与导弹血量统一下调（当前 -20%）
const BOSS_HP_BASE := [38, 42, 54, 68, 86]
const BOSS_HP_CAP := 132
const BOSS_HP_CAP_LATE := 180
const EBULLET_HIT := 0.024
const EBULLET_HIT_BOSS := 0.030
const EBULLET_HOME_SEC := 0.8 ## Boss 弹短时追踪时长
const CARRIER_HOME_SEC := 1.90
const CARRIER_HOME_SEC_P2 := 2.35
const CARRIER_TURN := 2.60
const CARRIER_TURN_P2 := 3.20
const CARRIER_MISSILE_SPD := 0.44
const BOSS_MISSILE_HP := 5 ## 玩家连射约需数发；激光/大招可较快清
const BOSS_MISSILE_HIT_GAP := 0.10 ## 同帧三连发只算一伤
const BOSS_MISSILE_LASER_DMG := 2
const BOSS_MISSILE_SUPER_DMG := 3
const BOSS_HIT_W := 0.18
const BOSS_HIT_H := 0.10
const BOSS_TOUCH_W := 0.12
const BOSS_TOUCH_H := 0.068
const BOSS_ENTER_INVULN := 0.70
const BOSS_CLEAR_SEC := 0.30
const BOSS_WARN_SEC := 2.0 ## 对齐 B 站参考：3 拍蜂鸣脉冲 (~0.64s×3)
const BOSS_TITLE_SEC := 0.95
const BOSS_PIPE_BREAK_SEC := 0.90
const BOSS_OUTRO_SEC := 0.70
const BOSS_HIT_GAP := 0.18
const BOSS_SCORE := 3
const BOSS_NAMES := ["裂锋巡洋", "轨道晶核", "弧刃阵列", "逐影母舰", "霸王舰"]
const BOSS_SUBS := ["海岸封锁", "交错火网", "三角压制", "锁定猎杀", "终局旗舰"]
const BOSS_PARK_Y := [0.23, 0.20, 0.26, 0.20, 0.24]

const KIND_RED := 0
const KIND_CYAN := 1
const KIND_PURPLE := 2
const KIND_GOLD := 3
const KIND_HP := [2, 2, 5, 4]
const KIND_SCORE := [1, 1, 2, 2]
const SCORE_POINT_SCALE := 256
const BOSS_DISPLAY_SCORE := 8000
const COMBO_DISPLAY_BONUS := 256
## 约 75% 可见机身，擦到翅膀算中
const KIND_HIT_W := [0.092, 0.080, 0.120, 0.100]
const KIND_HIT_H := [0.072, 0.068, 0.092, 0.080]

const ITEM_DOUBLE := 0
const ITEM_SHIELD := 1
const ITEM_LASER := 2
const ITEM_NUKE := 3 ## 现为炸弹补充，不再当场清屏
const ITEM_BOMB := 3
const ITEM_HEART := 4
const DOUBLE_SEC := 8.0
const BOMB_SCORE := 2
const BOMB_IFRAMES := 0.8
const HURT_IFRAMES := 0.48
const ITEM_GAP_MIN := 11.0
const ITEM_GAP_FORCE := 20.0

var playing := false
var ended := false
var end_reason := ""
var elapsed := 0.0
var time_left := 0.0
var score := 0
var token_score := 0
var hp := MAX_HP
var wave := 1
var bombs := BOMB_MAX
var player_x := 0.5
## 战场像素尺寸（由 PlaneView 每帧写入），用于 Boss 炮口贴图对齐
var play_size_px := Vector2(1766.4, 928.8)
var player_y := PLAYER_Y
var player_vx := 0.0
var player_vy := 0.0
var invuln := 0.0
var shield := false
var power_lv := 0
var double_t := 0.0
var laser_t := 0.0
var laser_cd := 0.0
var energy := 0.0
var super_t := 0.0
var super_cd := 0.0
var super_uses := 0
var missile_cd := 0.0
var show_shield_t := 0.0
var power_forced := false
var muzzle_t := 0.0
var shoot_cd := 0.0
var spawn_cd := 0.18
var spawn_total := 0
var volley_n := 0
var nukes_spawned := 0
var lasers_spawned := 0
var laser_picks := 0
var laser_early2 := false
var last_laser_at := -99.0
var wave_special_dropped := false
var last_item_at := -20.0
var combo := 0
var combo_bonus := 0
var last_kill_at := -10.0
var kills := 0
var flash_text := ""
var flash_t := 0.0
var wave_t := 0.0
var wave1_fired := false
var boss_phase := 0
var boss_phase_t := 0.0
var bosses_fought := 0
var bosses_killed := 0
var last_boss_kill_t := 0.0
var boss_fight_t := 0.0
var boss_order: Array[int] = []
var wings: Array[Dictionary] = []
var sweep_on := false
var sweep_x := 0.5
var sweep_y := 0.80
var sweep_kind := 0
var sweep_t := 0.0
var sweep_hit := false
var sweep_vx := 0.0
var sweep_w := 0.26
var warning_t := 0.0
var last_power_gain := -99.0
var item_from_boss := false
var wave_phrases := 0
var wave_chunk := 0
var theme_spawns := 0
var chunk_spawns := 0
var max_wave_chunk := 0
var wave_had_meteor := false
var wave_had_orbit := false
var peak_power := 0
var t_lv4 := 0.0
var t_lv7 := 0.0
var boss1_t := 0.0
var graze_window := 0.0
var graze_n := 0

var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var ebullets: Array[Dictionary] = []
var items: Array[Dictionary] = []
var boss_parts: Array[Dictionary] = []
var bootstrap_events: Array[Dictionary] = []


func reset() -> void:
	playing = true
	ended = false
	end_reason = ""
	elapsed = 0.0
	time_left = 0.0
	score = 0
	token_score = 0
	hp = MAX_HP
	wave = 1
	bombs = BOMB_START
	player_x = 0.5
	player_y = PLAYER_Y
	player_vx = 0.0
	player_vy = 0.0
	invuln = 0.0
	shield = false
	power_lv = 0
	double_t = 0.0
	laser_t = 0.0
	laser_cd = 0.0
	energy = 0.0
	super_t = 0.0
	super_cd = 0.0
	super_uses = 0
	missile_cd = 0.0
	show_shield_t = 0.0
	power_forced = false
	muzzle_t = 0.0
	shoot_cd = 0.08
	spawn_cd = 1.45
	spawn_total = 0
	volley_n = 0
	nukes_spawned = 0
	lasers_spawned = 0
	laser_picks = 0
	laser_early2 = false
	last_laser_at = -99.0
	wave_special_dropped = false
	last_item_at = -20.0
	combo = 0
	combo_bonus = 0
	last_kill_at = -10.0
	kills = 0
	flash_text = ""
	flash_t = 0.0
	wave_t = 0.0
	wave1_fired = false
	boss_phase = 0
	boss_phase_t = 0.0
	bosses_fought = 0
	bosses_killed = 0
	last_boss_kill_t = 0.0
	boss_fight_t = 0.0
	boss_order.clear()
	sweep_on = false
	sweep_t = 0.0
	sweep_hit = false
	sweep_vx = 0.0
	sweep_w = 0.26
	warning_t = 0.0
	last_power_gain = -99.0
	item_from_boss = false
	wave_phrases = 0
	wave_chunk = 0
	theme_spawns = 0
	chunk_spawns = 0
	max_wave_chunk = 0
	wave_had_meteor = false
	wave_had_orbit = false
	peak_power = 0
	t_lv4 = 0.0
	t_lv7 = 0.0
	boss1_t = 0.0
	graze_window = 0.0
	graze_n = 0
	bootstrap_events.clear()
	enemies.clear()
	bullets.clear()
	ebullets.clear()
	items.clear()
	boss_parts.clear()
	wings.clear()
	for i in MAX_ENEMIES:
		enemies.append(_dead_enemy())
	for i in MAX_BULLETS:
		bullets.append(_dead_bullet())
	for i in MAX_EBULLETS:
		ebullets.append(_dead_bullet())
	for i in MAX_ITEMS:
		items.append(_dead_item())
	for i in MAX_BOSS_PARTS:
		boss_parts.append(_dead_boss_part())
	for i in MAX_WINGS:
		wings.append({"live": false, "x": 0.4, "y": PLAYER_Y, "shoot_cd": 0.2})


func tempo() -> float:
	return 1.0


func phase() -> int:
	if elapsed < ROUND_WARMUP_SEC:
		return 0
	if elapsed < ROUND_WAVE2_START_SEC:
		return 1 ## 3～9s 第一波强攻
	if elapsed < ROUND_WAVE3_START_SEC:
		return 2 ## 9～15s 海量
	if elapsed < ROUND_PUSH_END_SEC:
		return 3 ## 15～20s 饱和刷怪
	if wave <= 2:
		return 0
	if wave <= 5:
		return 1
	return 2


func _fodder_may_shoot() -> bool:
	return elapsed >= ROUND_WARMUP_SEC


func _in_boss_chain() -> bool:
	return elapsed >= ROUND_PUSH_END_SEC and bosses_fought < BOSS_CHAIN_BOSS_COUNT


func _boss_chain_roster_index() -> int:
	return BOSS_CHAIN_FIRST_INDEX + bosses_fought


func _boss_fodder_active() -> bool:
	return boss_phase == 5 or boss_phase == 7


func _spawn_chunk_is_wave1() -> bool:
	if _boss_fodder_active():
		return true
	return phase() == 1 and elapsed < ROUND_WAVE2_START_SEC


func _try_start_next_boss(events: Array[Dictionary]) -> bool:
	if not _in_boss_chain():
		return false
	if bosses_fought != bosses_killed:
		return false
	if not live_boss().is_empty():
		return false
	_begin_boss_wave(events)
	return true


func settle_score() -> int:
	return mini(token_score, SCORE_SOFT_CAP)


func power_multiplier() -> int:
	return clampi(power_lv, 1, POWER_MAX)


func _shot_dmg() -> int:
	if power_lv >= 5:
		return 2
	return 1


func power_title(lv: int) -> String:
	if lv <= 0 or lv >= POWER_TITLES.size():
		return ""
	return str(POWER_TITLES[lv])


func _laser_dmg() -> int:
	return 1


func _laser_boss_dmg() -> int:
	return 1


func _fodder_hp_mult() -> float:
	var t := maxf(0.0, float(wave - 1))
	# 前 3 波略缓；越接近 Boss3/4/5 波次（12/16/20…）杂兵越厚
	return 1.0 + t * 0.14 + maxf(0.0, t - 3.0) * 0.11 + maxf(0.0, t - 7.0) * 0.06


func _kind_hp(kind: int) -> int:
	var k := clampi(kind, 0, KIND_HP.size() - 1)
	var base := int(KIND_HP[k])
	var mult := _fodder_hp_mult()
	if k == KIND_PURPLE:
		mult += maxf(0.0, float(wave - 1)) * 0.05
	elif k == KIND_GOLD:
		mult += maxf(0.0, float(wave - 1)) * 0.035
	return maxi(base, int(round(float(base) * mult)))


func _speed_mul() -> float:
	if wave <= 3:
		return 1.0
	return minf(1.30, 1.0 + float(wave - 3) * 0.043)


func live_enemy_count() -> int:
	var n := 0
	for e in enemies:
		if bool(e["live"]) and int(e["hp"]) > 0:
			n += 1
	return n


func live_bullet_count() -> int:
	var n := 0
	for b in bullets:
		if bool(b["live"]):
			n += 1
	return n


func live_ebullet_count() -> int:
	var n := 0
	for b in ebullets:
		if bool(b["live"]):
			n += 1
	return n


func live_item_count() -> int:
	var n := 0
	for it in items:
		if bool(it["live"]):
			n += 1
	return n


func nudge(dir: float, dir_y: float = 0.0) -> void:
	player_x = clampf(player_x + dir * 0.036, PLAYER_X_MIN, PLAYER_X_MAX)
	player_y = clampf(player_y + dir_y * 0.036, PLAYER_Y_MIN, PLAYER_Y_MAX)
	player_vx = dir
	player_vy = dir_y


func try_bomb() -> Dictionary:
	return {}


func apply_rhythm_hit(judgement: String) -> Dictionary:
	if not playing or ended:
		return {}
	var gain := 0
	if judgement == "perfect":
		gain = _add_display(SCORE_POINT_SCALE + COMBO_DISPLAY_BONUS)
		_flash("Perfect +%d" % gain)
	elif judgement == "good":
		gain = _add_display(SCORE_POINT_SCALE / 2)
		_flash("Good +%d" % gain)
	else:
		_flash("Miss")
	return {"type": "rhythm", "judgement": judgement, "gain": gain}


func queue_boss_warning_start(boss_num: int = 1) -> void:
	## 跳过杂兵波，直接第 boss_num 个 Boss 的 WARNING（仅 plane_game 开发入口用）
	var n := clampi(boss_num, 1, 99)
	wave = n * 4
	wave1_fired = true
	wave_t = 0.0
	wave_phrases = 0
	spawn_cd = 99.0
	spawn_total = 0
	bosses_fought = n - 1
	boss_order.clear()
	for i in n - 1:
		boss_order.append(boss_style_for_index(i))
	boss_phase = 2
	boss_phase_t = BOSS_WARN_SEC
	boss_fight_t = 0.0
	warning_t = BOSS_WARN_SEC
	_flash("WARNING")
	var idx := bosses_fought
	var nm := boss_name_for_index(idx)
	var sub := boss_sub_for_index(idx)
	bootstrap_events.append({"type": "warning", "wave": wave, "name": nm, "sub": sub})


func tick(delta: float, hold_l: bool, hold_r: bool, hold_u: bool = false, hold_d: bool = false, hold_fire: bool = false) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not playing:
		return events
	if not bootstrap_events.is_empty():
		events.append_array(bootstrap_events)
		bootstrap_events.clear()

	elapsed += delta
	if flash_t > 0.0:
		flash_t -= delta
	if muzzle_t > 0.0:
		muzzle_t -= delta
	if invuln > 0.0:
		invuln -= delta
	if show_shield_t > 0.0:
		show_shield_t = maxf(0.0, show_shield_t - delta)
	if double_t > 0.0:
		double_t = maxf(0.0, double_t - delta)
	if missile_cd > 0.0:
		missile_cd = maxf(0.0, missile_cd - delta)
	if super_t > 0.0:
		super_t = maxf(0.0, super_t - delta)
	elif laser_t > 0.0:
		laser_t = maxf(0.0, laser_t - delta)
	graze_window += delta
	if graze_window >= 1.0:
		graze_window -= 1.0
		graze_n = 0
	if power_lv > peak_power:
		peak_power = power_lv
	if power_lv >= 4 and t_lv4 <= 0.0:
		t_lv4 = elapsed
	if power_lv >= 7 and t_lv7 <= 0.0:
		t_lv7 = elapsed
	if warning_t > 0.0:
		warning_t = maxf(0.0, warning_t - delta)
	if sweep_t > 0.0:
		sweep_t = maxf(0.0, sweep_t - delta)
		if sweep_t <= 0.0:
			sweep_on = false
	if sweep_on and sweep_kind == 2:
		sweep_x += sweep_vx * delta
	if combo > 0 and elapsed - last_kill_at > COMBO_WINDOW:
		_combo_cashout(events, false)

	_tick_wave(delta, events)
	_force_early_power(events)

	_tick_move(delta, hold_l, hold_r, hold_u, hold_d)
	_tick_shoot(delta, events, hold_fire)
	_tick_wings(delta, events, hold_fire)
	_try_missiles(events, hold_fire)
	_tick_laser(delta, events)
	_tick_super(delta, events)
	_tick_spawn(delta, events)
	_tick_bullets(delta)
	_tick_ebullets(delta)
	_tick_enemies(delta, events)
	_tick_boss_parts(delta, events)
	_tick_items(delta, events)
	_collide_shots(events)
	_tick_graze()
	_collide_player(events)
	_tick_sweep_hit(events)

	return events


## 开局倒计时：只允许移动/试射，不开波次与刷怪
func tick_warmup(delta: float, hold_l: bool, hold_r: bool, hold_u: bool = false, hold_d: bool = false, hold_fire: bool = false) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if muzzle_t > 0.0:
		muzzle_t = maxf(0.0, muzzle_t - delta)
	_tick_move(delta, hold_l, hold_r, hold_u, hold_d)
	_tick_shoot(delta, events, hold_fire)
	_tick_bullets(delta)
	## 清理飞出屏幕的弹，避免预热期堆积
	for b in bullets:
		if bool(b["live"]) and (float(b["y"]) < -0.08 or float(b["x"]) < -0.06 or float(b["x"]) > 1.06):
			b["live"] = false
	return events


func simulate_bot(skill: float, limit: float = -1.0) -> Dictionary:
	reset()
	var cap := SIM_TIMEOUT if limit <= 0.0 else limit
	var dt := 1.0 / 30.0
	var peak := 0
	var mid := 0
	var peak_b := 0
	var samples := 0
	var ge5 := 0
	while playing and not ended:
		var hold_l := false
		var hold_r := false
		var hold_u := false
		var hold_d := false
		if skill > 0.04:
			var it0 := _nearest_item()
			var ev0 := _ebullet_steer() if skill >= 0.20 else Vector2.ZERO
			var greed := skill >= 0.22 and not it0.is_empty() \
				and ev0 == Vector2.ZERO \
				and absf(float(it0["x"]) - player_x) < 0.32 \
				and float(it0["y"]) < player_y + 0.10 \
				and float(it0["y"]) > player_y - 0.70 \
				and (power_lv < 3 or skill >= 0.50 or int(it0.get("kind", 0)) == ITEM_DOUBLE)
			if greed:
				var d0 := float(it0["x"]) - player_x
				if d0 < -0.04:
					hold_l = true
				elif d0 > 0.04:
					hold_r = true
				var iy0 := float(it0["y"]) - player_y
				if iy0 < -0.05:
					hold_u = true
				elif iy0 > 0.05:
					hold_d = true
			elif skill > 0.04 and boss_phase >= 4:
				var steer := _boss_bot_steer()
				hold_l = steer.x < 0.0
				hold_r = steer.x > 0.0
				hold_u = steer.y < 0.0
				hold_d = steer.y > 0.0
			elif skill > 0.04:
				var ev := _ebullet_steer() if skill >= 0.20 else Vector2.ZERO
				if ev != Vector2.ZERO:
					hold_l = ev.x < 0.0
					hold_r = ev.x > 0.0
					hold_u = ev.y < 0.0
					hold_d = ev.y > 0.0
				else:
					var threat := _nearest_threat(0.16 if skill >= 0.40 else 0.40)
					if not threat.is_empty() and (skill >= 0.40 or randf() > 0.12):
						var tx := float(threat.get("aim_x", threat["x"])) if bool(threat.get("diving", false)) or float(threat.get("warn_t", 0.0)) > 0.0 else float(threat["x"])
						var ty := float(threat.get("y", player_y))
						var dx := tx - player_x
						var dy := ty - player_y
						if absf(dx) < (0.18 if skill >= 0.50 else 0.12):
							if dx >= 0.0:
								hold_l = true
							else:
								hold_r = true
						if absf(dx) < 0.10 and absf(dy) < 0.14:
							if dy > 0.02 and player_y > PLAYER_Y_MIN + 0.04:
								hold_u = true
							elif dy < -0.02 and player_y < PLAYER_Y_MAX - 0.04:
								hold_d = true
					elif skill >= 0.50 and hp <= 1:
						var tgt := _nearest_heart()
						if not tgt.is_empty() and absf(float(tgt["x"]) - player_x) < 0.22:
							var d2 := float(tgt["x"]) - player_x
							if d2 < -0.04:
								hold_l = true
							elif d2 > 0.04:
								hold_r = true
					elif absf(player_y - 0.80) > 0.06:
						if player_y < 0.74:
							hold_d = true
						elif player_y > 0.86:
							hold_u = true
		if elapsed >= cap:
			return _sim_result("timeout", peak, mid, peak_b, ge5, samples)
		tick(dt, hold_l, hold_r, hold_u, hold_d, true)
		var live := live_enemy_count()
		var lb := live_bullet_count()
		if live > peak:
			peak = live
		if lb > peak_b:
			peak_b = lb
		samples += 1
		if live >= 5:
			ge5 += 1
		if elapsed > 20.0 and elapsed < 50.0 and live > mid:
			mid = live
		if energy >= ENERGY_MAX and super_t <= 0.0 and boss_phase >= 5:
			try_bomb()
		elif skill >= 0.50 and bombs > 0 and energy < ENERGY_MAX and (_dive_on_player() or (hp <= 2 and (live >= 2 or boss_phase >= 5))):
			try_bomb()
		elif skill >= 0.22 and hp <= 1 and bombs > 0 and energy < ENERGY_MAX and (live >= 2 or boss_phase >= 5):
			try_bomb()
	return _sim_result(end_reason, peak, mid, peak_b, ge5, samples)


func _sim_result(reason: String, peak: int, mid: int, peak_b: int, ge5: int, samples: int) -> Dictionary:
	return {
		"score": score,
		"settle": settle_score(),
		"kills": kills,
		"reason": reason,
		"hp": hp,
		"time": elapsed,
		"wave": wave,
		"bombs": bombs,
		"peak": peak,
		"mid": mid,
		"peak_b": peak_b,
		"ge5": float(ge5) / float(maxi(1, samples)),
		"boss_seen": bosses_fought,
		"boss_kill": bosses_killed,
		"boss_t": last_boss_kill_t,
		"boss_order": boss_order.duplicate(),
		"laser_pick": laser_picks,
		"laser_early2": laser_early2,
		"laser_spawn": lasers_spawned,
		"super_uses": super_uses,
		"energy": energy,
		"peak_lv": peak_power,
		"t_lv4": t_lv4,
		"t_lv7": t_lv7,
		"boss1_t": boss1_t,
		"theme_spawns": theme_spawns,
		"chunk_spawns": chunk_spawns,
		"max_wave_chunk": max_wave_chunk,
	}


func simulate_boss_bench(powered: bool, style: int = 0, lv7_laser: bool = false) -> Dictionary:
	reset()
	player_x = 0.5
	if lv7_laser:
		power_lv = POWER_MAX
		_refresh_wings()
		laser_t = 22.0
		laser_cd = 0.0
	elif powered:
		power_lv = 3
		_refresh_wings()
		laser_t = 0.0
	shoot_cd = SHOOT_CD
	_spawn_true_boss(style, true)
	boss_phase = 5
	boss_fight_t = 0.0
	var dt := 1.0 / 30.0
	var t := 0.0
	while playing and not ended and t < 22.0:
		player_x = 0.5
		player_y = PLAYER_Y
		tick(dt, false, false, false, false, true)
		t += dt
		if live_boss().is_empty():
			break
	return {
		"powered": powered,
		"style": style,
		"time": t,
		"killed": bosses_killed > 0,
		"hp_left": int(live_boss().get("hp", 0)),
	}


func simulate_super_boss_bench(style: int = 0) -> Dictionary:
	reset()
	player_x = 0.5
	player_y = PLAYER_Y
	super_t = SUPER_SEC
	super_cd = 0.0
	energy = ENERGY_MAX
	_spawn_true_boss(style, true)
	boss_phase = 5
	boss_fight_t = 0.0
	var dt := 1.0 / 30.0
	var t := 0.0
	while playing and not ended and t < 8.0:
		player_x = 0.5
		player_y = PLAYER_Y
		tick(dt, false, false, false, false, true)
		t += dt
		if live_boss().is_empty() and bosses_killed > 0:
			break
	return {
		"style": style,
		"time": t,
		"killed": bosses_killed > 0,
		"hp_left": int(live_boss().get("hp", 0)),
		"super_left": super_t,
	}


func live_boss() -> Dictionary:
	for e in enemies:
		if not bool(e["live"]) or not bool(e.get("is_boss", false)):
			continue
		if int(e["hp"]) > 0 or bool(e.get("breaking", false)):
			return e
	return {}


func _dive_on_player() -> bool:
	for e in enemies:
		if not bool(e["live"]) or int(e["hp"]) <= 0 or bool(e.get("is_boss", false)):
			continue
		if not bool(e.get("diving", false)) and float(e.get("warn_t", 0.0)) <= 0.0:
			continue
		if float(e["y"]) < 0.48:
			continue
		if absf(float(e["x"]) - player_x) < 0.16:
			return true
	return false


func _ebullet_steer() -> Vector2:
	var out := Vector2.ZERO
	for b in ebullets:
		if not bool(b["live"]):
			continue
		var by := float(b["y"])
		if by < player_y - 0.22 or by > player_y + 0.10:
			continue
		var dx := float(b["x"]) - player_x
		if absf(dx) >= 0.10:
			continue
		out.x = -1.0 if dx >= 0.0 else 1.0
		if float(b.get("vy", 0.0)) <= 0.0 and by > player_y and player_y < PLAYER_Y_MAX - 0.06:
			out.y = 1.0
		break
	return out


func _boss_bot_steer() -> Vector2:
	var out := Vector2.ZERO
	var bo := live_boss()
	if bo.is_empty():
		return out
	var bx := float(bo["x"])
	if (sweep_on or float(bo.get("sweep_arm", 0.0)) > 0.0) and sweep_kind == 2:
		if absf(player_y - sweep_y) < 0.10:
			out.y = -1.0 if player_y >= sweep_y else 1.0
			if player_y < 0.42:
				out.y = 1.0
		if out != Vector2.ZERO:
			return out
	var ev := _ebullet_steer()
	if ev != Vector2.ZERO:
		return ev
	if sweep_on and sweep_kind == 1 and absf(player_x - sweep_x) < 0.09:
		out.x = -1.0 if player_x >= sweep_x else 1.0
		return out
	var park := bx
	if bool(bo.get("phase2", false)) and int(bo.get("boss_style", 0)) == 0:
		var gi := posmod(int(bo.get("gap_i", 0)), 7)
		if bo.has("gap_x"):
			park = float(bo["gap_x"])
		else:
			park = _boss_column_x(gi, 7)
	elif int(bo.get("boss_style", 0)) == 1 and bool(bo.get("phase2", false)):
		park = 0.20 if bx >= 0.5 else 0.80
	if player_x < park - 0.035:
		out.x = 1.0
	elif player_x > park + 0.035:
		out.x = -1.0
	if player_y < 0.72:
		out.y = 1.0
	elif player_y > 0.86:
		out.y = -1.0
	return out


func live_escort_count() -> int:
	var n := 0
	for e in enemies:
		if bool(e["live"]) and int(e["hp"]) > 0 and not bool(e.get("is_boss", false)):
			n += 1
	return n


func _tick_wave(delta: float, events: Array[Dictionary]) -> void:
	if boss_phase > 0:
		_tick_boss_phase(delta, events)
		return
	var frozen := live_boss()
	if not frozen.is_empty() and bool(frozen.get("frozen", false)):
		return
	if _try_start_next_boss(events):
		return
	if elapsed < ROUND_WARMUP_SEC:
		return
	if elapsed >= ROUND_PUSH_END_SEC:
		return
	if not wave1_fired and elapsed >= ROUND_WARMUP_SEC:
		wave1_fired = true
		wave = 1
		wave_t = 0.0
		wave_special_dropped = false
		_reset_wave_spawn()
		var title := _spawn_fodder_theme(1)
		wave_phrases = 1
		theme_spawns += 1
		spawn_cd = minf(spawn_cd, randf_range(0.12, 0.22))
		events.append({"type": "wave", "wave": 1, "title": title})
		return
	if wave1_fired and wave < 2 and elapsed >= ROUND_WAVE2_START_SEC:
		wave = 2
		wave_t = 0.0
		wave_special_dropped = false
		_reset_wave_spawn()
		var title2 := _spawn_fodder_theme(2)
		wave_phrases = 1
		theme_spawns += 1
		spawn_cd = minf(spawn_cd, randf_range(0.10, 0.18))
		events.append({"type": "wave", "wave": 2, "title": title2})
		return
	if wave1_fired and wave < 3 and elapsed >= ROUND_WAVE3_START_SEC:
		wave = 3
		wave_t = 0.0
		wave_special_dropped = false
		_reset_wave_spawn()
		var title3 := _spawn_fodder_theme(3)
		wave_phrases = 1
		theme_spawns += 1
		spawn_cd = minf(spawn_cd, randf_range(0.06, 0.12))
		events.append({"type": "wave", "wave": 3, "title": title3})


func _reset_wave_spawn() -> void:
	wave_phrases = 0
	wave_chunk = 0
	wave_had_meteor = false
	wave_had_orbit = false


func _begin_boss_wave(events: Array[Dictionary]) -> void:
	boss_phase = 1
	boss_phase_t = BOSS_CLEAR_SEC
	boss_fight_t = 0.0
	for e in enemies:
		if not bool(e["live"]):
			continue
		if bool(e.get("meteor", false)) or bool(e.get("is_boss", false)):
			continue
		e["pattern"] = "flee"
		e["vx"] = 0.55 if float(e["x"]) >= 0.5 else -0.55
		e["vy"] = 0.22
		e["diver"] = false
	events.append({"type": "wave", "wave": wave, "title": "空域清场"})


func _tick_boss_phase(delta: float, events: Array[Dictionary]) -> void:
	boss_phase_t -= delta
	if boss_phase == 1:
		if boss_phase_t <= 0.0:
			for e in enemies:
				if bool(e["live"]) and not bool(e.get("meteor", false)) and not bool(e.get("is_boss", false)):
					e["live"] = false
					e["hp"] = 0
			for b in ebullets:
				b["live"] = false
			sweep_on = false
			boss_phase = 2
			boss_phase_t = BOSS_WARN_SEC
			warning_t = BOSS_WARN_SEC
			_flash("WARNING")
			var ri_w := _boss_chain_roster_index()
			var nm_w := boss_name_for_index(ri_w)
			var sub_w := boss_sub_for_index(ri_w)
			events.append({"type": "warning", "wave": wave, "name": nm_w, "sub": sub_w})
		return
	if boss_phase == 2:
		if boss_phase_t <= 0.0:
			var ri := _boss_chain_roster_index()
			var nm := boss_name_for_index(ri)
			var sub := boss_sub_for_index(ri)
			_flash(nm + "  " + sub)
			events.append({"type": "boss_title", "name": nm, "sub": sub})
			boss_phase = 3
			boss_phase_t = BOSS_TITLE_SEC
		return
	if boss_phase == 3:
		if boss_phase_t <= 0.0:
			_spawn_true_boss()
			boss_phase = 4
			boss_phase_t = BOSS_ENTER_INVULN
		return
	if boss_phase == 4:
		var entering := live_boss()
		if not entering.is_empty() and bool(entering.get("entering", false)):
			return
		boss_phase = 5
		boss_fight_t = 0.0
		spawn_cd = randf_range(0.14, 0.26)
		return
	if boss_phase == 5 or boss_phase == 7:
		boss_fight_t += delta
		if live_boss().is_empty():
			boss_phase = 8
			boss_phase_t = BOSS_OUTRO_SEC
		return
	if boss_phase == 6:
		if boss_phase_t <= 0.0:
			var bo := live_boss()
			if not bo.is_empty():
				bo["breaking"] = false
				bo["hp"] = int(bo.get("pipe_max", bo.get("hp", 1)))
				bo["max_hp"] = int(bo.get("pipe_max", 1))
				bo["phase2"] = true
				bo["shoot_cd"] = 0.40
				bo["left_cd"] = 0.20
				bo["right_cd"] = 0.45
				bo["beat"] = 0
				bo["atk_step"] = 0
				bo["overlord_p2_i"] = 0
				bo["preflash"] = false
			boss_phase = 7
			boss_fight_t = 0.0
			spawn_cd = randf_range(0.14, 0.26)
		return
	if boss_phase == 8:
		if boss_phase_t <= 0.0:
			boss_phase = 0
			spawn_cd = randf_range(0.22, 0.36) if not _in_boss_chain() else 99.0
			sweep_on = false
		return


func boss_style_for_index(idx: int) -> int:
	if idx < 5:
		return idx
	return 3 + ((idx - 5) % 2)


func boss_name_for_index(idx: int) -> String:
	return str(BOSS_NAMES[boss_style_for_index(idx)])


func boss_name_for_style(st: int) -> String:
	if st < 0 or st >= BOSS_NAMES.size():
		return "BOSS"
	return str(BOSS_NAMES[st])


func boss_sub_for_index(idx: int) -> String:
	return boss_sub_for_style(boss_style_for_index(idx))


func boss_sub_for_style(st: int) -> String:
	if st < 0 or st >= BOSS_SUBS.size():
		return ""
	return str(BOSS_SUBS[st])


func _boss_park_y(st: int) -> float:
	if st < 0 or st >= BOSS_PARK_Y.size():
		return BOSS_Y
	return float(BOSS_PARK_Y[st])


func _scale_boss_hp(hp: int) -> int:
	return maxi(1, int(round(float(hp) * BOSS_TTK_MUL)))


func _boss_missile_hp(phase2: bool) -> int:
	var raw := BOSS_MISSILE_HP + (2 if phase2 else 1)
	return _scale_boss_hp(raw)


func _boss_hp_for_index(idx: int) -> int:
	var st := boss_style_for_index(idx)
	var hp := int(BOSS_HP_BASE[st]) + idx * 12
	match idx:
		2:
			hp += 10
		3:
			hp += 22
		4:
			hp += 44
	if idx < 5:
		return _scale_boss_hp(mini(BOSS_HP_CAP, hp))
	## 第二圈起更厚；高 Index 面向能活到后期的极少数玩家。
	return _scale_boss_hp(mini(BOSS_HP_CAP_LATE, hp + 16 + maxi(0, idx - 4) * 10))


func _spawn_true_boss(style: int = -1, frozen: bool = false) -> void:
	if not live_boss().is_empty():
		return
	var idx := bosses_fought
	if style < 0 and elapsed >= ROUND_PUSH_END_SEC:
		idx = _boss_chain_roster_index()
	var st := style if style >= 0 else boss_style_for_index(idx)
	var hp0 := _scale_boss_hp(mini(BOSS_HP_CAP, int(BOSS_HP_BASE[st]))) if style >= 0 else _boss_hp_for_index(idx)
	var py := _boss_park_y(st)
	if not frozen:
		bosses_fought += 1
		boss_order.append(st)
	var pipe := int(ceili(float(hp0) * 0.5))
	_spawn_enemy(KIND_PURPLE, 0.5, false, false, {
		"is_boss": true,
		"boss_style": st,
		"hp": pipe,
		"x": 0.5,
		"y": -0.16 if not frozen else py,
		"vy": 0.0,
		"pattern": "boss",
		"hit_w": BOSS_HIT_W,
		"hit_h": BOSS_HIT_H,
		"boss_invuln": 0.0 if frozen else BOSS_ENTER_INVULN,
		"entering": not frozen,
		"frozen": frozen,
		"dir": 1.0,
		"turn_t": 0.0,
		"bvx": 0.0,
		"bvy": 0.0,
		"rest": false,
		"alt": false,
		"phase2": false,
		"aim_t": 0.0,
		"laser_cd": 0.0,
		"hit_gap": 0.0,
		"park_y": py,
		"pipe": 1,
		"pipe_max": pipe,
		"total_hp": hp0,
		"breaking": false,
		"sweep_cd": 2.4,
		"sweep_arm": 0.0,
		"shoot_cd": 0.45,
		"left_cd": 0.20,
		"right_cd": 0.50,
		"gap_i": randi() % 5,
		"beat": 0,
		"atk_step": 0,
		"muzzle_i": 0,
		"want_sweep": false,
		"preflash": false,
		"burst_mode": 0,
		"burst_cd": 0.0,
		"boss_part_stage": 0,
		"boss_hp_lost": 0,
	})


func _hurt_boss(e: Dictionary, dmg: int, events: Array[Dictionary], gap: float = -1.0) -> int:
	if float(e.get("boss_invuln", 0.0)) > 0.0 or bool(e.get("breaking", false)):
		return 0
	if float(e.get("hit_gap", 0.0)) > 0.0:
		return 0
	e["hp"] = int(e["hp"]) - dmg
	e["flash"] = 0.10
	e["punch"] = 0.12
	e["hit_gap"] = BOSS_HIT_GAP if gap < 0.0 else gap
	e["boss_hp_lost"] = int(e.get("boss_hp_lost", 0)) + dmg
	_update_boss_part_stage(e, events)
	if int(e["hp"]) <= 0 and int(e.get("pipe", 1)) <= 1:
		e["hp"] = 0
		return 2
	return 1


func _start_pipe_break(e: Dictionary, events: Array[Dictionary]) -> void:
	e["breaking"] = true
	e["pipe"] = 2
	e["phase2"] = true
	e["boss_invuln"] = BOSS_PIPE_BREAK_SEC
	e["flash"] = 0.45
	e["punch"] = 0.28
	for b in ebullets:
		b["live"] = false
	sweep_on = false
	sweep_t = 0.0
	show_shield_t = 0.80
	invuln = maxf(invuln, 0.80)
	boss_phase = 6
	boss_phase_t = BOSS_PIPE_BREAK_SEC
	_flash("破管")
	events.append({
		"type": "pipe_break",
		"x": float(e["x"]),
		"y": float(e["y"]),
		"style": int(e.get("boss_style", 0)),
	})
	events.append({
		"type": "boom",
		"x": float(e["x"]),
		"y": float(e["y"]),
		"big": true,
		"n": 5,
		## 爆炸音改由 pipe_break → sfx_plane_boss_part，避免盖掉碎片声
		"silent": true,
	})


func _start_hsweep(e: Dictionary, dur: float, wide: float, rest: float, events: Array[Dictionary]) -> void:
	var from_left := randf() < 0.5
	sweep_kind = 2
	## 扫射高度跟随玩家；旧版固定 ≥0.5 时，躲左上角/右上角完全无伤
	sweep_y = clampf(player_y, PLAYER_Y_MIN + 0.02, PLAYER_Y_MAX - 0.04)
	sweep_x = PLAYER_X_MIN if from_left else PLAYER_X_MAX
	sweep_vx = (0.84 / maxf(0.20, dur)) * (1.0 if from_left else -1.0)
	sweep_w = wide
	sweep_on = false
	sweep_hit = false
	sweep_t = 0.25 + dur
	e["sweep_arm"] = 0.25
	e["sweep_dur"] = dur
	e["shoot_cd"] = 0.25 + dur + rest
	e["flash"] = 0.22
	e["muzzle_i"] = 1
	events.append({"type": "sweep", "kind": 2, "x": sweep_x, "y": sweep_y})


func _tick_hsweep_arm(e: Dictionary, delta: float) -> void:
	if float(e.get("sweep_arm", 0.0)) <= 0.0:
		return
	e["sweep_arm"] = float(e["sweep_arm"]) - delta
	if float(e["sweep_arm"]) <= 0.0:
		sweep_on = true
		sweep_hit = false


func _tick_sweep_hit(events: Array[Dictionary]) -> void:
	if not sweep_on or ended or invuln > 0.0 or sweep_hit:
		return
	if sweep_kind == 1:
		if absf(player_x - sweep_x) < 0.055:
			sweep_hit = true
			_hurt_player(events, player_x, player_y)
		return
	if sweep_kind == 2:
		var y_tol := 0.042 if player_y < 0.42 else 0.036
		if absf(player_x - sweep_x) < sweep_w * 0.5 and absf(player_y - sweep_y) < y_tol:
			sweep_hit = true
			_hurt_player(events, player_x, player_y)


func _boss_bomb_damage(e: Dictionary) -> int:
	return maxi(6, int(ceili(float(int(e.get("total_hp", e.get("max_hp", 28)))) * 0.25)))


func _blast_screen(events: Array[Dictionary], is_nuke: bool) -> Dictionary:
	var spots: Array[Vector2] = []
	var cleared := 0
	for e in enemies:
		if not bool(e["live"]):
			continue
		spots.append(Vector2(float(e["x"]), float(e["y"])))
		if bool(e.get("is_boss", false)):
			var hr := _hurt_boss(e, _boss_bomb_damage(e), events)
			if hr == 2:
				_start_pipe_break(e, events)
			elif hr > 0 and int(e["hp"]) <= 0:
				_kill_enemy(e, events)
			continue
		e["live"] = false
		e["hp"] = 0
		cleared += 1
	for b in ebullets:
		b["live"] = false
	var gain := 0
	if cleared > 0 and token_score < 10:
		var bomb_gems := NUKE_SCORE if is_nuke else BOMB_SCORE
		gain = _add_display(bomb_gems * SCORE_GREEN_GEM)
		_add_token(bomb_gems)
	return {"cleared": cleared, "gain": gain, "spots": spots}


func _tick_boss_unit(e: Dictionary, delta: float, events: Array[Dictionary]) -> void:
	if float(e.get("dying", 0.0)) > 0.0:
		e["dying"] = float(e["dying"]) - delta
		e["punch"] = maxf(0.0, float(e.get("punch", 0.0)) - delta)
		if float(e["dying"]) <= 0.0:
			e["live"] = false
		return
	if float(e.get("boss_invuln", 0.0)) > 0.0:
		e["boss_invuln"] = float(e["boss_invuln"]) - delta
	if float(e.get("hit_gap", 0.0)) > 0.0:
		e["hit_gap"] = float(e["hit_gap"]) - delta
	if float(e.get("flash", 0.0)) > 0.0:
		e["flash"] = float(e["flash"]) - delta
	if float(e.get("punch", 0.0)) > 0.0:
		e["punch"] = float(e["punch"]) - delta
	if float(e.get("warn_t", 0.0)) > 0.0 and float(e.get("aim_t", 0.0)) <= 0.0:
		e["warn_t"] = maxf(0.0, float(e["warn_t"]) - delta)
	var py := float(e.get("park_y", BOSS_Y))
	if bool(e.get("frozen", false)):
		e["x"] = 0.5
		e["y"] = py
		return
	if bool(e.get("entry_salvo_pending", false)):
		if _boss_entry_salvo(e, delta, events):
			e["entry_salvo_pending"] = false
			e.erase("entry_salvo_active")
			e.erase("entry_salvo_t")
			e.erase("entry_salvo_shot")
			e.erase("entry_salvo_burst_ok")
		return
	if bool(e.get("entering", false)):
		e["boss_invuln"] = maxf(float(e.get("boss_invuln", 0.0)), 0.08)
		e["y"] = move_toward(float(e["y"]), py, 0.38 * delta)
		e["x"] = 0.5
		if absf(float(e["y"]) - py) <= 0.008:
			e["entering"] = false
			e["y"] = py
			if _boss_wants_entry_salvo(e):
				e["entry_salvo_pending"] = true
		return
	_tick_hsweep_arm(e, delta)
	var style := int(e.get("boss_style", 0))
	## 瞄准预警期仍可缓慢机动，避免傻站
	if float(e.get("aim_t", 0.0)) > 0.0:
		e["aim_t"] = float(e["aim_t"]) - delta
		e["aim_x"] = player_x
		e["warn_t"] = maxf(float(e.get("warn_t", 0.0)), float(e["aim_t"]))
		_boss_move(e, style, delta, py, 0.42)
		if float(e["aim_t"]) <= 0.0:
			if bool(e.get("want_sweep", false)):
				e["want_sweep"] = false
				_start_hsweep(e, 0.80, 0.26, 0.55, events)
			elif style == 3:
				_boss_fire_carrier(e, events)
			else:
				_boss_fire_aimed(e, events)
				e["shoot_cd"] = randf_range(0.55, 0.68)
		return
	_boss_move(e, style, delta, py, 1.0)
	if boss_phase != 5 and boss_phase != 7:
		return
	if float(e.get("boss_invuln", 0.0)) > 0.0:
		return
	if sweep_on and sweep_kind == 2:
		e["shoot_cd"] = float(e.get("shoot_cd", 0.0)) - delta
		return
	if float(e.get("sweep_arm", 0.0)) > 0.0:
		e["shoot_cd"] = float(e.get("shoot_cd", 0.0)) - delta
		return
	if style == 1 and not bool(e.get("phase2", false)):
		_tick_twin_async(e, delta, events)
		return
	e["shoot_cd"] = float(e.get("shoot_cd", 0.0)) - delta
	if float(e["shoot_cd"]) > 0.0 and float(e["shoot_cd"]) <= 0.20 and not bool(e.get("preflash", false)):
		e["flash"] = 0.20
		e["preflash"] = true
	if float(e["shoot_cd"]) > 0.0:
		return
	e["preflash"] = false
	_boss_attack(e, style, events)


func _boss_move(e: Dictionary, style: int, delta: float, py: float, spd_mul: float = 1.0) -> void:
	## 全屏追玩家：跟 X + 压 Y，带侧向游走；不再左右傻平移
	var chase := 0.20
	var weave := 0.10
	var y_bias := 0.55
	match style:
		0:
			chase = 0.13
			weave = 0.08
			y_bias = 0.45
		1:
			chase = 0.16
			weave = 0.10
			y_bias = 0.50
		2:
			chase = 0.15
			weave = 0.14
			y_bias = 0.52
		3:
			chase = 0.19
			weave = 0.11
			y_bias = 0.62
		4:
			chase = 0.22
			weave = 0.14
			y_bias = 0.72
		_:
			chase = 0.20
			weave = 0.12
			y_bias = 0.68
	chase *= spd_mul * 0.82 ## 整体再慢一截，别贴脸太快
	## 目标点：对准玩家 X，Y 在驻守高度与「压向玩家」之间插值
	var prefer_y := lerpf(py, clampf(player_y - 0.38, BOSS_Y_MIN, BOSS_Y_MAX), y_bias)
	## 轻微超前预判（玩家水平速度用位移差分近似不够，改用当前位置偏移）
	var lead_x := clampf(player_x + (player_x - 0.5) * 0.04, BOSS_X_MIN, BOSS_X_MAX)
	## 侧向 8 字 / 正弦游走，避免直线贴脸
	var wox := sin(elapsed * (1.1 + float(style) * 0.12) + float(e.get("phase", 0.0))) * weave
	var woy := cos(elapsed * (0.85 + float(style) * 0.08)) * weave * 0.55
	var tx := clampf(lead_x + wox, BOSS_X_MIN, BOSS_X_MAX)
	var ty := clampf(prefer_y + woy, BOSS_Y_MIN, BOSS_Y_MAX)
	## 相位 2 更凶：更贴近玩家高度
	if bool(e.get("phase2", false)):
		ty = clampf(lerpf(ty, player_y - 0.28, 0.35), BOSS_Y_MIN, BOSS_Y_MAX)
		chase *= 1.18
	var bvx := float(e.get("bvx", 0.0))
	var bvy := float(e.get("bvy", 0.0))
	var dx := tx - float(e["x"])
	var dy := ty - float(e["y"])
	## 加速度追目标，带阻尼，手感像在「追」而不是瞬移
	var accel := chase * 3.4
	bvx = move_toward(bvx, clampf(dx * 2.4, -chase, chase), accel * delta)
	bvy = move_toward(bvy, clampf(dy * 2.2, -chase * 0.85, chase * 0.85), accel * 0.9 * delta)
	e["bvx"] = bvx
	e["bvy"] = bvy
	e["x"] = clampf(float(e["x"]) + bvx * delta, BOSS_X_MIN, BOSS_X_MAX)
	e["y"] = clampf(float(e["y"]) + bvy * delta, BOSS_Y_MIN, BOSS_Y_MAX)
	## 撞边弹开一点速度，避免贴边抖
	if float(e["x"]) <= BOSS_X_MIN + 0.01 or float(e["x"]) >= BOSS_X_MAX - 0.01:
		e["bvx"] = -bvx * 0.55
	if float(e["y"]) <= BOSS_Y_MIN + 0.01 or float(e["y"]) >= BOSS_Y_MAX - 0.01:
		e["bvy"] = -bvy * 0.45


func _boss_attack(e: Dictionary, style: int, events: Array[Dictionary]) -> void:
	match style:
		0:
			_boss_atk_cruiser(e, events)
		1:
			_boss_atk_twin(e, events)
		2:
			_boss_atk_fan(e, events)
		3:
			_boss_atk_carrier(e, events)
		_:
			_boss_atk_overlord(e, events)
	if _player_top_corner_camp():
		_boss_corner_suppress(e, events, _boss_attack_spd(style))


const CRUISER_ENTRY_WINDUP := 0.16
const CRUISER_ENTRY_STAGGER := 0.028
const CRUISER_ENTRY_FAN_N := 4
const CRUISER_ENTRY_LEFT_DEG := [4.0, -22.0, -46.0, -72.0]
const CRUISER_ENTRY_RIGHT_DEG := [-4.0, 22.0, 46.0, 72.0]


func _boss1_gun(e: Dictionary, slot: int) -> Vector2:
	return BossMuzzleLayout.boss1_world(float(e["x"]), float(e["y"]), slot, play_size_px)


func _boss2_gun(e: Dictionary, slot: int) -> Vector2:
	return BossMuzzleLayout.boss2_world(float(e["x"]), float(e["y"]), slot, play_size_px)


func _boss3_gun(e: Dictionary, slot: int) -> Vector2:
	return BossMuzzleLayout.boss3_world(float(e["x"]), float(e["y"]), slot, play_size_px)


func _boss_wants_entry_salvo(e: Dictionary) -> bool:
	var st := int(e.get("boss_style", 0))
	if st >= BOSS_CHAIN_FIRST_INDEX:
		return bosses_fought == st
	return bosses_fought == st + 1


func _entry_salvo_turret_pos(e: Dictionary) -> Dictionary:
	var st := int(e.get("boss_style", 0))
	var wl: Vector2
	var wr: Vector2
	if st == 1:
		wl = _boss2_gun(e, BossMuzzleLayout.Boss2Slot.WING_L)
		wr = _boss2_gun(e, BossMuzzleLayout.Boss2Slot.WING_R)
	elif st == 2:
		wl = _boss3_gun(e, BossMuzzleLayout.Boss3Slot.WING_L)
		wr = _boss3_gun(e, BossMuzzleLayout.Boss3Slot.WING_R)
	elif st == 3:
		wl = _boss4_gun(e, BossMuzzleLayout.Boss4Slot.SALVO_L)
		wr = _boss4_gun(e, BossMuzzleLayout.Boss4Slot.SALVO_R)
	elif st == 4:
		wl = _boss5_gun(e, BossMuzzleLayout.Boss5Slot.SALVO_L)
		wr = _boss5_gun(e, BossMuzzleLayout.Boss5Slot.SALVO_R)
	else:
		wl = _boss1_gun(e, BossMuzzleLayout.Boss1Slot.WING_L)
		wr = _boss1_gun(e, BossMuzzleLayout.Boss1Slot.WING_R)
	return {"cx": float(e["x"]), "y": wl.y, "lx": wl.x, "rx": wr.x}


func _fire_entry_salvo_pair(e: Dictionary, fan_i: int) -> void:
	var pos := _entry_salvo_turret_pos(e)
	var spd := EBULLET_SPEED_LATE + 0.10 + float(fan_i) * 0.038
	var extras := {"home_t": 0.68, "home_turn": 1.52, "flash": 0.16}
	var la := deg_to_rad(CRUISER_ENTRY_LEFT_DEG[fan_i])
	var ra := deg_to_rad(CRUISER_ENTRY_RIGHT_DEG[fan_i])
	_acquire_ebullet(pos["lx"], pos["y"], sin(la) * spd, cos(la) * spd, true, extras)
	_acquire_ebullet(pos["rx"], pos["y"], sin(ra) * spd, cos(ra) * spd, true, extras)


func _boss_entry_salvo(e: Dictionary, delta: float, events: Array[Dictionary]) -> bool:
	## 铁甲巡洋～追瞄母舰入场：短蓄力 → 双舷「烟花」由内向外 stagger 扇射
	if not bool(e.get("entry_salvo_active", false)):
		e["entry_salvo_active"] = true
		e["entry_salvo_t"] = CRUISER_ENTRY_WINDUP
		e["entry_salvo_shot"] = 0
		e["entry_salvo_burst_ok"] = false
	e["entry_salvo_t"] = float(e["entry_salvo_t"]) - delta
	if not bool(e.get("entry_salvo_burst_ok", false)):
		var wind_left := maxf(0.0, float(e["entry_salvo_t"]))
		e["flash"] = maxf(float(e.get("flash", 0.0)), 0.14 + 0.20 * (1.0 - wind_left / CRUISER_ENTRY_WINDUP))
		e["muzzle_i"] = -1
		if wind_left > 0.0:
			return false
		var pos0 := _entry_salvo_turret_pos(e)
		events.append({
			"type": "entry_salvo",
			"phase": "burst",
			"x": pos0["cx"],
			"y": pos0["y"],
			"lx": pos0["lx"],
			"rx": pos0["rx"],
		})
		e["entry_salvo_burst_ok"] = true
		e["entry_salvo_t"] = 0.0
		e["flash"] = 0.44
		e["punch"] = maxf(float(e.get("punch", 0.0)), 0.24)
	if int(e.get("entry_salvo_shot", 0)) >= CRUISER_ENTRY_FAN_N:
		e["shoot_cd"] = 1.48
		e["flash"] = maxf(float(e.get("flash", 0.0)), 0.34)
		e["muzzle_i"] = -1
		return true
	if float(e["entry_salvo_t"]) > 0.0:
		return false
	if not _room_eb(2):
		e["entry_salvo_t"] = 0.04
		return false
	var shot_i := int(e["entry_salvo_shot"])
	_fire_entry_salvo_pair(e, shot_i)
	var pos1 := _entry_salvo_turret_pos(e)
	events.append({
		"type": "entry_salvo",
		"phase": "shot",
		"lx": pos1["lx"],
		"rx": pos1["rx"],
		"y": pos1["y"],
		"i": shot_i,
	})
	e["entry_salvo_shot"] = shot_i + 1
	e["entry_salvo_t"] = CRUISER_ENTRY_STAGGER
	e["flash"] = 0.28
	e["muzzle_i"] = shot_i % 2
	return false


func _boss_atk_cruiser(e: Dictionary, events: Array[Dictionary]) -> void:
	var top := _boss1_gun(e, BossMuzzleLayout.Boss1Slot.LAUNCHER)
	var x := float(e["x"])
	if bool(e.get("phase2", false)):
		## 二阶段：顶炮扇射封锁弹幕（留一列空隙）
		if not _room_eb(6):
			e["shoot_cd"] = 0.12
			return
		var cols := 7
		var gap := posmod(int(e.get("gap_i", 0)), cols)
		var target_y := clampf(player_y + 0.06, 0.70, 0.92)
		var spd := EBULLET_SPEED_TEACH
		for i in cols:
			if i == gap:
				continue
			var tx := _boss_column_x(i, cols)
			var mx := lerpf(top.x, tx, 0.12)
			var aim := _aim_vel(mx, top.y, tx, target_y, spd)
			if aim.y < spd * 0.55:
				aim = _aim_vel(mx, top.y, lerpf(mx, tx, 0.45), target_y, spd)
			_fire_eb(mx, top.y, aim.x, aim.y, true)
		e["gap_x"] = _boss_column_x(gap, cols)
		e["gap_i"] = gap + 1
		e["shoot_cd"] = 0.60
		e["muzzle_i"] = 2
	else:
		if not _room_eb(1):
			e["shoot_cd"] = 0.12
			return
		var left := not bool(e.get("alt", false))
		e["alt"] = left
		var slot := BossMuzzleLayout.Boss1Slot.WING_L if left else BossMuzzleLayout.Boss1Slot.WING_R
		var muzzle := _boss1_gun(e, slot)
		_fire_eb(muzzle.x, muzzle.y, 0.0, EBULLET_SPEED_TEACH, true)
		e["muzzle_i"] = 0 if left else 1
		e["atk_step"] = int(e.get("atk_step", 0)) + 1
		if int(e["atk_step"]) >= 4:
			e["atk_step"] = 0
			e["shoot_cd"] = 0.60
			if _player_top_corner_camp() and _room_eb(1):
				var tgt := _boss_aim_point()
				var aim := _aim_vel(top.x, top.y, tgt.x, tgt.y, EBULLET_SPEED_TEACH)
				_fire_eb(top.x, top.y, aim.x, aim.y, true)
				e["muzzle_i"] = 2
		else:
			e["shoot_cd"] = 0.55
	events.append({"type": "eshot", "boss": true, "x": x, "y": top.y})


func _tick_twin_async(e: Dictionary, delta: float, events: Array[Dictionary]) -> void:
	var ml := _boss2_gun(e, BossMuzzleLayout.Boss2Slot.WING_L)
	var mr := _boss2_gun(e, BossMuzzleLayout.Boss2Slot.WING_R)
	e["left_cd"] = float(e.get("left_cd", 0.70)) - delta
	e["right_cd"] = float(e.get("right_cd", 0.95)) - delta
	if float(e["left_cd"]) <= 0.20 and float(e["left_cd"]) > 0.0:
		e["flash"] = 0.20
		e["muzzle_i"] = 0
	if float(e["right_cd"]) <= 0.20 and float(e["right_cd"]) > 0.0:
		e["flash"] = 0.20
		e["muzzle_i"] = 1
	if float(e["left_cd"]) <= 0.0:
		if _room_eb(1):
			var tgt := _boss_aim_point()
			var vl := _aim_vel(ml.x, ml.y, tgt.x - 0.03, tgt.y, EBULLET_SPEED_TEACH)
			if _fire_eb(ml.x, ml.y, vl.x, vl.y, true):
				e["left_cd"] = 0.70
				e["muzzle_i"] = 0
				events.append({"type": "eshot", "boss": true, "x": ml.x, "y": ml.y})
		else:
			e["left_cd"] = 0.12
	if float(e["right_cd"]) <= 0.0:
		if _room_eb(1):
			var tgt2 := _boss_aim_point()
			var vr := _aim_vel(mr.x, mr.y, tgt2.x + 0.03, tgt2.y, EBULLET_SPEED_TEACH)
			if _fire_eb(mr.x, mr.y, vr.x, vr.y, true):
				e["right_cd"] = 0.95
				e["muzzle_i"] = 1
				events.append({"type": "eshot", "boss": true, "x": mr.x, "y": mr.y})
		else:
			e["right_cd"] = 0.12


func _boss_atk_twin(e: Dictionary, events: Array[Dictionary]) -> void:
	var ml := _boss2_gun(e, BossMuzzleLayout.Boss2Slot.WING_L)
	var mr := _boss2_gun(e, BossMuzzleLayout.Boss2Slot.WING_R)
	if not _room_eb(2):
		e["shoot_cd"] = 0.12
		return
	var tgt := _boss_aim_point()
	var vl := _aim_vel(ml.x, ml.y, tgt.x, tgt.y, EBULLET_SPEED_TEACH)
	var vr := _aim_vel(mr.x, mr.y, tgt.x, tgt.y, EBULLET_SPEED_TEACH)
	_fire_eb(ml.x, ml.y, vl.x, vl.y, true)
	_fire_eb(mr.x, mr.y, vr.x, vr.y, true)
	e["shoot_cd"] = 0.50
	e["muzzle_i"] = -1
	events.append({"type": "eshot", "boss": true, "x": float(e["x"]), "y": ml.y})


func _boss3_bullet_spd() -> float:
	return lerpf(EBULLET_SPEED_TEACH, EBULLET_SPEED + 0.02, clampf(float(wave - 4) / 10.0, 0.0, 1.0))


func _boss_atk_fan(e: Dictionary, events: Array[Dictionary]) -> void:
	var fan := _boss3_gun(e, BossMuzzleLayout.Boss3Slot.CENTER_FAN)
	var x := fan.x
	var y := fan.y
	var spd := _boss3_bullet_spd()
	var step := int(e.get("atk_step", 0))
	if bool(e.get("phase2", false)):
		match step % 3:
			0:
				var gap := clampf(
					atan2(player_x - x, maxf(0.08, player_y - y)),
					deg_to_rad(-32.0),
					deg_to_rad(32.0)
				)
				if not _fire_ring_gap(x, y, 9, spd, gap):
					e["shoot_cd"] = 0.10
					return
				e["shoot_cd"] = 0.50
			1:
				if not _room_eb(5):
					e["shoot_cd"] = 0.10
					return
				var aim := _aim_vel(x, y, player_x, player_y, spd * 1.06)
				_fire_eb(x, y, aim.x, aim.y, true)
				_fire_eb(x - 0.065, y, aim.x * 0.82, aim.y, true)
				_fire_eb(x + 0.065, y, aim.x * 0.82, aim.y, true)
				_fire_fan(x, y + 0.012, 3, 12.0, spd * 0.9, true)
				e["shoot_cd"] = 0.46
			_:
				if not _fire_fan(x, y, 5, 24.0, spd, true):
					e["shoot_cd"] = 0.10
					return
				e["shoot_cd"] = 0.54
		e["atk_step"] = step + 1
	else:
		if step % 2 == 0:
			if not _fire_fan(x, y, 5, 22.0, spd, true):
				e["shoot_cd"] = 0.10
				return
			e["shoot_cd"] = 0.56
		else:
			if not _room_eb(3):
				e["shoot_cd"] = 0.10
				return
			var aim := _aim_vel(x, y, player_x, minf(player_y + 0.05, 0.90), spd)
			_fire_eb(x, y, aim.x, aim.y, true)
			_fire_eb(x - 0.055, y, -spd * 0.42, spd * 0.94, true)
			_fire_eb(x + 0.055, y, spd * 0.42, spd * 0.94, true)
			e["shoot_cd"] = 0.50
		e["atk_step"] = step + 1
	e["muzzle_i"] = 1
	events.append({"type": "eshot", "boss": true, "x": x, "y": y})


func _boss_atk_carrier(e: Dictionary, events: Array[Dictionary]) -> void:
	var p2 := bool(e.get("phase2", false))
	e["volley"] = int(e.get("volley", 0)) + 1
	var step := int(e.get("atk_step", 0))
	e["atk_step"] = step + 1
	e["aim_t"] = 0.34 if p2 else 0.40
	e["aim_x"] = player_x
	e["warn_t"] = float(e["aim_t"])
	e["flash"] = 0.22
	e["want_sweep"] = p2 and (step % 4 == 1)
	e["want_escort"] = (not p2) and step % 3 == 2
	e["carrier_salvo"] = step
	e["shoot_cd"] = 9.0
	e["muzzle_i"] = -1
	events.append({"type": "dive_warn", "x": float(e["x"]), "y": float(e["y"]), "aim": player_x})


func _boss4_gun(e: Dictionary, slot: int) -> Vector2:
	return BossMuzzleLayout.boss4_world(float(e["x"]), float(e["y"]), slot, play_size_px)


func _boss5_gun(e: Dictionary, slot: int) -> Vector2:
	return BossMuzzleLayout.boss5_world(float(e["x"]), float(e["y"]), slot, play_size_px)


func _boss_fire_carrier(e: Dictionary, events: Array[Dictionary]) -> void:
	var muzzle := _boss4_gun(e, BossMuzzleLayout.Boss4Slot.DECK)
	var x := muzzle.x
	var y := muzzle.y
	if int(e.get("boss_style", 0)) != 3:
		x = float(e["x"])
		y = float(e["y"]) + 0.078
	var p2 := bool(e.get("phase2", false))
	var salvo := posmod(int(e.get("carrier_salvo", 0)), 3 if not p2 else 4)
	var spd := CARRIER_MISSILE_SPD if not p2 else CARRIER_MISSILE_SPD + 0.05
	var lead := clampf(player_x + player_vx * 0.28, PLAYER_X_MIN + 0.03, PLAYER_X_MAX - 0.03)
	var n := 3
	if p2 and salvo == 0:
		n = 4
	elif p2 and salvo == 2:
		n = 4
	elif not p2 and salvo == 1:
		n = 2
	if not _room_eb(n):
		e["shoot_cd"] = 0.16
		return
	if not p2:
		if salvo == 0:
			_fire_carrier_missile(x - 0.08, y, _aim_vel(x - 0.08, y, lead - 0.10, player_y, spd), p2)
			_fire_carrier_missile(x, y, _aim_vel(x, y, lead, player_y, spd), p2)
			_fire_carrier_missile(x + 0.08, y, _aim_vel(x + 0.08, y, lead + 0.10, player_y, spd), p2)
		elif salvo == 1:
			_fire_carrier_missile(x - 0.09, y, Vector2(-0.18, spd * 0.86), p2)
			_fire_carrier_missile(x + 0.09, y, Vector2(0.18, spd * 0.86), p2)
		else:
			_fire_carrier_missile(x, y, _aim_vel(x, y, lead, player_y, spd + 0.08), p2)
			_fire_carrier_missile(x - 0.07, y, Vector2(-0.10, spd * 0.78), p2)
			_fire_carrier_missile(x + 0.07, y, Vector2(0.10, spd * 0.78), p2)
	else:
		if salvo == 0:
			for ox in [-0.11, -0.04, 0.04, 0.11]:
				_fire_carrier_missile(x + ox, y, _aim_vel(x + ox, y, lead + ox * 0.55, player_y, spd), p2)
		elif salvo == 2:
			_fire_carrier_missile(x - 0.10, y, Vector2(-0.22, spd * 0.80), p2)
			_fire_carrier_missile(x + 0.10, y, Vector2(0.22, spd * 0.80), p2)
			_fire_carrier_missile(x - 0.04, y, _aim_vel(x - 0.04, y, lead, player_y, spd + 0.04), p2)
			_fire_carrier_missile(x + 0.04, y, _aim_vel(x + 0.04, y, lead, player_y, spd + 0.04), p2)
		else:
			_fire_carrier_missile(x - 0.08, y, _aim_vel(x - 0.08, y, lead - 0.08, player_y, spd), p2)
			_fire_carrier_missile(x, y, _aim_vel(x, y, lead, player_y, spd + 0.06), p2)
			_fire_carrier_missile(x + 0.08, y, _aim_vel(x + 0.08, y, lead + 0.08, player_y, spd), p2)
	if bool(e.get("want_escort", false)) and live_escort_count() < 2:
		e["want_escort"] = false
		var sx := clampf(x + (0.16 if x < 0.5 else -0.16), 0.14, 0.86)
		if randf() < 0.55:
			_spawn_enemy(KIND_CYAN, sx, false, false, {"x": sx, "y": y + 0.08})
		else:
			_spawn_enemy(KIND_RED, sx, true, false, {"x": sx, "y": y + 0.06})
	e["shoot_cd"] = 0.58 if p2 else 0.76
	e["muzzle_i"] = -1
	e["warn_t"] = 0.10
	events.append({"type": "eshot", "boss": true, "x": x, "y": y})


func _fire_carrier_missile(x: float, y: float, vel: Vector2, phase2: bool) -> bool:
	return _acquire_ebullet(x, y, vel.x, vel.y, true, {
		"home_t": CARRIER_HOME_SEC_P2 if phase2 else CARRIER_HOME_SEC,
		"home_turn": CARRIER_TURN_P2 if phase2 else CARRIER_TURN,
		"hp": _boss_missile_hp(phase2),
	})


func _boss_fire_aimed(e: Dictionary, events: Array[Dictionary]) -> void:
	var x := float(e["x"])
	var y := float(e["y"]) + 0.078
	if not _room_eb(2):
		e["shoot_cd"] = 0.16
		return
	var spd := EBULLET_SPEED_LATE
	var aim := _aim_vel(x, y, float(e.get("aim_x", player_x)), player_y, spd)
	_fire_eb(x, y, aim.x, aim.y, true)
	_fire_eb(x, y + 0.02, 0.0, 0.36, true)
	e["warn_t"] = 0.12
	if bool(e.get("want_escort", false)) and live_escort_count() < 2:
		e["want_escort"] = false
		var sx := clampf(x + (0.16 if x < 0.5 else -0.16), 0.14, 0.86)
		if randf() < 0.55:
			_spawn_enemy(KIND_CYAN, sx, false, false, {"x": sx, "y": y + 0.08})
		else:
			_spawn_enemy(KIND_RED, sx, true, false, {"x": sx, "y": y + 0.06})
	events.append({"type": "eshot", "boss": true, "x": x, "y": y})


func _boss_atk_overlord(e: Dictionary, events: Array[Dictionary]) -> void:
	var belly := _boss5_gun(e, BossMuzzleLayout.Boss5Slot.BELLY)
	var xl := _boss5_gun(e, BossMuzzleLayout.Boss5Slot.SALVO_L)
	var xr := _boss5_gun(e, BossMuzzleLayout.Boss5Slot.SALVO_R)
	var x := belly.x
	var y := belly.y
	var spd := EBULLET_SPEED_LATE
	var step := int(e.get("atk_step", 0))
	if not bool(e.get("phase2", false)):
		match step % 4:
			0:
				if not _fire_fan(x, y, 5, 22.0, spd):
					e["shoot_cd"] = 0.12
					return
				e["muzzle_i"] = 1
			1:
				if not _room_eb(5):
					e["shoot_cd"] = 0.12
					return
				_fire_eb(xl.x, xl.y, 0.0, spd, true)
				_fire_eb(xr.x, xr.y, 0.0, spd, true)
				var tx := clampf(player_x, PLAYER_X_MIN + 0.02, PLAYER_X_MAX - 0.02)
				var aim0 := _aim_vel(x, y, tx, _boss_aim_point().y, spd)
				_fire_eb(x, y, aim0.x, aim0.y, true)
				_fire_eb(xl.x, xl.y, -spd * 0.38, spd * 0.90, true)
				_fire_eb(xr.x, xr.y, spd * 0.38, spd * 0.90, true)
				e["muzzle_i"] = -1
			2:
				if not _fire_fan(x, y, 7, 15.0, spd * 1.04):
					e["shoot_cd"] = 0.12
					return
				e["muzzle_i"] = 1
			_:
				if not _room_eb(5):
					e["shoot_cd"] = 0.12
					return
				_fire_eb(xl.x, xl.y, -spd * 0.32, spd * 0.94, true)
				_fire_eb(xr.x, xr.y, spd * 0.32, spd * 0.94, true)
				var aim1 := _aim_vel(x, y, player_x, minf(player_y + 0.04, 0.90), spd + 0.02)
				_fire_eb(x, y, aim1.x, aim1.y, true)
				_fire_eb(x - 0.048, y, aim1.x * 0.78, aim1.y, true)
				_fire_eb(x + 0.048, y, aim1.x * 0.78, aim1.y, true)
				e["muzzle_i"] = -1
		e["atk_step"] = step + 1
		e["shoot_cd"] = 0.48 if step % 4 == 3 else 0.52
		events.append({"type": "eshot", "boss": true, "x": x, "y": y})
		return
	var beat := posmod(int(e.get("beat", 0)), 4)
	match beat:
		0:
			if not _room_eb(8):
				e["shoot_cd"] = 0.12
				return
			_fire_fan(x, y, 3, 10.0, spd * 0.62, true)
			if not _fire_fan(x, y + 0.008, 5, 20.0, spd, true):
				e["shoot_cd"] = 0.12
				return
			e["beat"] = 1
			e["shoot_cd"] = 0.38
			e["muzzle_i"] = 1
		1:
			if not _room_eb(6):
				e["shoot_cd"] = 0.12
				return
			_fire_eb(xl.x, xl.y, 0.0, spd, true)
			_fire_eb(xr.x, xr.y, 0.0, spd, true)
			var aim := _aim_vel(x, y, player_x, player_y, spd + 0.02)
			_fire_eb(x, y, aim.x, aim.y, true)
			var aim_l := _aim_vel(xl.x, xl.y, player_x - 0.05, player_y, spd * 0.96)
			var aim_r := _aim_vel(xr.x, xr.y, player_x + 0.05, player_y, spd * 0.96)
			_fire_eb(xl.x, xl.y, aim_l.x, aim_l.y, true)
			_fire_eb(xr.x, xr.y, aim_r.x, aim_r.y, true)
			e["beat"] = 2
			e["shoot_cd"] = 0.34
			e["muzzle_i"] = -1
		2:
			_start_hsweep(e, 0.58, 0.24, 0.36, events)
			e["beat"] = 3
			return
		_:
			var lead := clampf(player_x + player_vx * 0.22, PLAYER_X_MIN + 0.03, PLAYER_X_MAX - 0.03)
			var n_miss := 2
			if not _room_eb(n_miss + 3):
				e["shoot_cd"] = 0.12
				return
			_fire_carrier_missile(
				xl.x, xl.y, _aim_vel(xl.x, xl.y, lead - 0.08, player_y, CARRIER_MISSILE_SPD + 0.06), true
			)
			_fire_carrier_missile(
				xr.x, xr.y, _aim_vel(xr.x, xr.y, lead + 0.08, player_y, CARRIER_MISSILE_SPD + 0.06), true
			)
			_fire_fan(x, y, 3, 14.0, spd * 0.94, true)
			var p2_i := int(e.get("overlord_p2_i", 0)) + 1
			e["overlord_p2_i"] = p2_i
			if p2_i % 4 == 0 and live_escort_count() < 2:
				var sx := clampf(x + (0.18 if x < 0.5 else -0.18), 0.14, 0.86)
				if randf() < 0.62:
					_spawn_enemy(KIND_CYAN, sx, false, false, {"x": sx, "y": y + 0.10})
				else:
					_spawn_enemy(KIND_RED, sx, true, false, {"x": sx, "y": y + 0.08})
			e["beat"] = 0
			e["shoot_cd"] = 0.64
			e["muzzle_i"] = 1
	events.append({"type": "eshot", "boss": true, "x": x, "y": y})


func _aim_vel(x0: float, y0: float, x1: float, y1: float, spd: float) -> Vector2:
	var dx := x1 - x0
	var dy := y1 - y0
	var L := maxf(0.12, sqrt(dx * dx + dy * dy))
	return Vector2(dx / L * spd, dy / L * spd)


func _boss_aim_point() -> Vector2:
	return Vector2(player_x, clampf(player_y, PLAYER_Y_MIN, PLAYER_Y_MAX))


func _boss_column_x(i: int, n: int) -> float:
	return lerpf(PLAYER_X_MIN + 0.02, PLAYER_X_MAX - 0.02, float(i) / float(maxi(1, n - 1)))


func _player_top_corner_camp() -> bool:
	return player_y < 0.34 and (player_x <= PLAYER_X_MIN + 0.06 or player_x >= PLAYER_X_MAX - 0.06)


func _boss_attack_spd(style: int) -> float:
	match style:
		2:
			return _boss3_bullet_spd()
		3, 4:
			return EBULLET_SPEED_LATE
		_:
			return EBULLET_SPEED_TEACH


func _boss_corner_suppress(e: Dictionary, _events: Array[Dictionary], spd: float) -> void:
	if not _room_eb(2):
		return
	var x := float(e["x"])
	var y := float(e["y"]) + 0.078
	var tgt := _boss_aim_point()
	var aim := _aim_vel(x, y, tgt.x, tgt.y, spd)
	_fire_eb(x, y, aim.x, aim.y, true)
	var sx := PLAYER_X_MIN + 0.02 if tgt.x < 0.5 else PLAYER_X_MAX - 0.02
	var sy := clampf(tgt.y + 0.05, PLAYER_Y_MIN + 0.04, 0.42)
	var aim2 := _aim_vel(sx, sy, tgt.x, tgt.y, spd * 0.94)
	_fire_eb(sx, sy, aim2.x, aim2.y, true)


func _fire_fan(x: float, y: float, n: int, deg: float, spd: float, fat: bool = true) -> bool:
	if n <= 1:
		return _fire_eb(x, y, 0.0, spd, fat)
	if not _room_eb(n):
		return false
	var start := -deg * float(n - 1) * 0.5
	for i in n:
		var a := deg_to_rad(start + deg * float(i))
		_fire_eb(x, y, sin(a) * spd, cos(a) * spd, fat)
	return true


func _fire_ring_gap(x: float, y: float, n: int, spd: float, gap_ang: float) -> bool:
	var shots := maxi(1, n - 1)
	if not _room_eb(shots):
		return false
	var step := TAU / float(n)
	var skip := 0
	var best := 99.0
	for i in n:
		var d := absf(angle_difference(step * float(i), gap_ang))
		if d < best:
			best = d
			skip = i
	for i in n:
		if i == skip:
			continue
		var a := step * float(i)
		_fire_eb(x, y, sin(a) * spd, cos(a) * spd, true)
	return true


func _fire_eb(x: float, y: float, vx: float, vy: float, fat: bool) -> bool:
	return _acquire_ebullet(x, y, vx, vy, fat)


func _room_eb(n: int) -> bool:
	return live_ebullet_count() + n <= _ebullet_cap()


func _room_eb_fodder(n: int) -> bool:
	return live_ebullet_count() + n <= _ebullet_cap_for_fodder()


func _boss_reserves_ebullets() -> int:
	if boss_phase != 5 and boss_phase != 7:
		return 0
	var bo := live_boss()
	if bo.is_empty() or not bool(bo.get("phase2", false)):
		return 0
	return EBULLET_BOSS_P2_RESERVE


func _ebullet_cap_for_fodder() -> int:
	var cap := _ebullet_cap()
	var reserve := _boss_reserves_ebullets()
	if reserve <= 0:
		return cap
	return mini(cap, maxi(EBULLET_CAP_FOB, cap - reserve))


func _eb_spd_fob() -> float:
	if wave >= 6:
		return EBULLET_SPEED
	return EBULLET_SPEED_TEACH


func _ebullet_cap() -> int:
	if boss_phase == 5 or boss_phase == 7:
		return mini(MAX_EBULLETS, EBULLET_CAP_BOSS)
	if boss_phase >= 3:
		return mini(MAX_EBULLETS, EBULLET_CAP_BOSS)
	return EBULLET_CAP_FOB


func _tick_move(delta: float, hold_l: bool, hold_r: bool, hold_u: bool = false, hold_d: bool = false) -> void:
	var ax := 0.0
	var ay := 0.0
	if hold_l:
		ax -= 1.0
	if hold_r:
		ax += 1.0
	if hold_u:
		ay -= 1.0
	if hold_d:
		ay += 1.0
	if ax != 0.0 and ay != 0.0:
		ax *= 0.707
		ay *= 0.707
	player_vx = ax
	player_vy = ay
	if ax != 0.0:
		player_x = clampf(player_x + ax * MOVE_SPEED * delta, PLAYER_X_MIN, PLAYER_X_MAX)
	if ay != 0.0:
		player_y = clampf(player_y + ay * MOVE_SPEED * delta, PLAYER_Y_MIN, PLAYER_Y_MAX)


func _tick_shoot(delta: float, events: Array[Dictionary], hold_fire: bool = false) -> void:
	if laser_t > 0.0 or super_t > 0.0:
		return
	shoot_cd -= delta
	if not hold_fire:
		return
	if shoot_cd > 0.0:
		return
	var lv := power_lv
	if lv >= 7:
		shoot_cd = 0.042
	elif lv >= 5:
		shoot_cd = 0.036
	elif lv >= 2:
		shoot_cd = 0.040
	elif lv >= 1:
		shoot_cd = SHOOT_CD_DOUBLE
	else:
		shoot_cd = SHOOT_CD
	volley_n += 1
	var fired := 0
	var y0 := player_y - 0.05
	var spd := BULLET_SPEED_DOUBLE if lv >= 1 else BULLET_SPEED
	var fat := lv >= 2
	var boost := lv >= 1
	if lv >= 4:
		var spread := 0.12 if lv >= 7 else 0.08
		if _acquire_bullet(player_x - 0.018, y0, -spread, -spd, fat, true):
			fired += 1
		if _acquire_bullet(player_x, y0, 0.0, -spd, fat, true):
			fired += 1
		if _acquire_bullet(player_x + 0.018, y0, spread, -spd, fat, true):
			fired += 1
	elif lv >= 1:
		if _acquire_bullet(player_x - 0.014, y0, 0.0, -spd, fat, true):
			fired += 1
		if _acquire_bullet(player_x + 0.014, y0, 0.0, -spd, fat, true):
			fired += 1
	else:
		if _acquire_bullet(player_x, y0, 0.0, -spd, false, false):
			fired += 1
	if fired > 0:
		muzzle_t = 0.05 if boost else 0.06
		events.append({"type": "shoot", "double": boost, "n": fired, "lv": lv})


func _try_missiles(events: Array[Dictionary], hold_fire: bool = false) -> void:
	if not hold_fire:
		return
	if power_lv < 6 or laser_t > 0.0 or super_t > 0.0:
		return
	if missile_cd > 0.0:
		return
	var n := 2
	if _live_missiles() + n > MAX_MISSILES:
		return
	missile_cd = 0.22 if power_lv >= 7 else 0.26
	var y0 := player_y - 0.07
	_acquire_bullet(player_x - 0.04, y0, -0.10, -0.72, false, true, true, 1)
	_acquire_bullet(player_x + 0.04, y0, 0.10, -0.72, false, true, true, 1)
	events.append({"type": "missile", "n": n})


func _live_missiles() -> int:
	var n := 0
	for b in bullets:
		if bool(b["live"]) and bool(b.get("homing", false)):
			n += 1
	return n


func _refresh_wings() -> void:
	var on := power_lv >= 3
	for i in wings.size():
		wings[i]["live"] = on
		if on:
			wings[i]["x"] = player_x + (-WING_OFFSET_X if i == 0 else WING_OFFSET_X)
			wings[i]["y"] = player_y + WING_OFFSET_Y


func _tick_wings(delta: float, _events: Array[Dictionary], hold_fire: bool = false) -> void:
	_refresh_wings()
	if power_lv < 3 or laser_t > 0.0 or super_t > 0.0:
		return
	var wcd := 0.048 if power_lv >= 7 else (0.055 if power_lv >= 5 else WING_SHOOT_CD)
	var wfat := power_lv >= 5
	var wdmg := 1
	for i in wings.size():
		var w: Dictionary = wings[i]
		if not bool(w["live"]):
			continue
		var tx := player_x + (-WING_OFFSET_X if i == 0 else WING_OFFSET_X)
		w["x"] = lerpf(float(w["x"]), tx, clampf(delta * 8.0, 0.0, 1.0))
		w["y"] = lerpf(float(w["y"]), player_y + WING_OFFSET_Y, clampf(delta * 8.0, 0.0, 1.0))
		w["shoot_cd"] = float(w.get("shoot_cd", 0.0)) - delta
		if not hold_fire:
			continue
		if float(w["shoot_cd"]) > 0.0:
			continue
		w["shoot_cd"] = wcd
		_acquire_bullet(float(w["x"]), float(w["y"]) - 0.04, 0.0, -BULLET_SPEED_DOUBLE, wfat, true, false, wdmg)


func _force_early_power(events: Array[Dictionary]) -> void:
	if power_forced or power_lv > 0 or elapsed < 8.0:
		return
	if live_item_count() >= MAX_ITEMS:
		return
	power_forced = true
	_spawn_item(clampf(player_x, 0.18, 0.82), clampf(player_y - 0.08, 0.20, 0.86), ITEM_DOUBLE)
	events.append({"type": "flash", "text": "火力"})


func _occupancy() -> int:
	if _boss_fodder_active():
		return 9 ## Boss + 杂兵，总量对齐 WAVE1（约 9 架）
	if elapsed < ROUND_WARMUP_SEC:
		return 6
	if elapsed < ROUND_WAVE2_START_SEC:
		return 9
	if elapsed < ROUND_WAVE3_START_SEC:
		return MAX_ENEMIES
	if elapsed < ROUND_PUSH_END_SEC:
		return MAX_ENEMIES
	if wave <= 2:
		return 5
	if wave <= 4:
		return 7
	if wave <= 7:
		return 8
	if wave <= 11:
		return 9
	return 10


func _tick_laser(delta: float, events: Array[Dictionary]) -> void:
	if laser_t <= 0.0 or super_t > 0.0 or ended:
		return
	laser_cd -= delta
	var fodder_ready := laser_cd <= 0.0
	_damage_boss_missiles_in_beam(LASER_W, BOSS_MISSILE_LASER_DMG, events)
	for e in enemies:
		if not bool(e["live"]) or int(e["hp"]) <= 0:
			continue
		if float(e["y"]) >= player_y:
			continue
		if absf(float(e["x"]) - player_x) >= LASER_W:
			continue
		if bool(e.get("is_boss", false)):
			e["laser_cd"] = float(e.get("laser_cd", 0.0)) - delta
			if float(e.get("boss_invuln", 0.0)) > 0.0:
				continue
			if float(e["laser_cd"]) > 0.0:
				continue
			var hr := _hurt_boss(e, _laser_boss_dmg(), events)
			if hr == 0:
				continue
			e["laser_cd"] = LASER_TICK_BOSS_LATE if int(e.get("boss_style", 0)) >= 3 else LASER_TICK_BOSS
			if hr == 2:
				_start_pipe_break(e, events)
			elif int(e["hp"]) <= 0:
				_kill_enemy(e, events)
			continue
		if not fodder_ready:
			continue
		e["hp"] = int(e["hp"]) - _laser_dmg()
		e["flash"] = 0.08
		e["punch"] = 0.10
		if int(e["hp"]) <= 0:
			_kill_enemy(e, events)
	if fodder_ready:
		laser_cd = LASER_TICK


func super_angles() -> Array[float]:
	var out: Array[float] = [-SUPER_SPREAD, 0.0, SUPER_SPREAD]
	return out


func super_beam_origin(i: int) -> Vector2:
	match i:
		0:
			return Vector2(player_x - 0.050, player_y - 0.034)
		2:
			return Vector2(player_x + 0.050, player_y - 0.034)
		_:
			return Vector2(player_x, player_y - 0.060)


func super_hits_enemy(e: Dictionary, ang: float, ox: float = -1.0, oy: float = -1.0) -> bool:
	if not bool(e.get("live", false)) or int(e.get("hp", 0)) <= 0:
		return false
	if ox < 0.0:
		ox = player_x
		oy = player_y - 0.048
	var dx := sin(ang)
	var dy := -cos(ang)
	var ex := float(e["x"])
	var ey := float(e["y"])
	if ey >= player_y + 0.02:
		return false
	var px := ex - ox
	var py := ey - oy
	var t := px * dx + py * dy
	if t < 0.0:
		return false
	var cx := ox + dx * t
	var cy := oy + dy * t
	var dist := Vector2(ex - cx, ey - cy).length()
	var hw := BOSS_HIT_W * 0.42 if bool(e.get("is_boss", false)) else float(KIND_HIT_W[clampi(int(e.get("kind", 0)), 0, KIND_HIT_W.size() - 1)]) * 0.42
	return dist <= SUPER_W + hw


func _enemy_hit_by_super(e: Dictionary) -> bool:
	var angs: Array[float] = super_angles()
	for i in angs.size():
		var o := super_beam_origin(i)
		if super_hits_enemy(e, angs[i], o.x, o.y):
			return true
	return false


func _tick_super(delta: float, events: Array[Dictionary]) -> void:
	if super_t <= 0.0 or ended:
		return
	super_cd -= delta
	var fodder_ready := super_cd <= 0.0
	## 超级火力同样可打爆路上的 Boss 导弹
	for eb in ebullets:
		if not bool(eb["live"]) or not bool(eb.get("fat", false)):
			continue
		if float(eb["y"]) >= player_y + 0.02:
			continue
		var hit := false
		var angs: Array[float] = super_angles()
		for i in angs.size():
			var o := super_beam_origin(i)
			var dx := sin(angs[i])
			var dy := -cos(angs[i])
			var px := float(eb["x"]) - o.x
			var py := float(eb["y"]) - o.y
			var t := px * dx + py * dy
			if t < 0.0:
				continue
			var cx := o.x + dx * t
			var cy := o.y + dy * t
			if Vector2(float(eb["x"]) - cx, float(eb["y"]) - cy).length() <= SUPER_W + EBULLET_HIT_BOSS:
				hit = true
				break
		if hit:
			_hurt_boss_missile(eb, BOSS_MISSILE_SUPER_DMG, events)
	for e in enemies:
		if not bool(e["live"]) or int(e["hp"]) <= 0:
			continue
		if not _enemy_hit_by_super(e):
			continue
		if bool(e.get("is_boss", false)):
			e["laser_cd"] = float(e.get("laser_cd", 0.0)) - delta
			if float(e.get("boss_invuln", 0.0)) > 0.0:
				continue
			if float(e["laser_cd"]) > 0.0:
				continue
			var hr := _hurt_boss(e, SUPER_BOSS_DMG, events, SUPER_TICK_BOSS)
			if hr == 0:
				continue
			e["laser_cd"] = SUPER_TICK_BOSS
			if hr == 2:
				_start_pipe_break(e, events)
			elif int(e["hp"]) <= 0:
				_kill_enemy(e, events)
			continue
		if not fodder_ready:
			continue
		e["hp"] = int(e["hp"]) - SUPER_DMG
		e["flash"] = 0.08
		e["punch"] = 0.12
		if int(e["hp"]) <= 0:
			_kill_enemy(e, events)
	if fodder_ready:
		super_cd = SUPER_TICK


func _grant_energy(_e: Dictionary, _events: Array[Dictionary]) -> void:
	pass


func _activate_super(events: Array[Dictionary]) -> void:
	if super_t > 0.0:
		return
	super_t = SUPER_SEC
	super_cd = 0.0
	energy = 0.0
	super_uses += 1
	if flash_t <= 0.0:
		_flash("超级武器")
	events.append({"type": "super"})


func _tick_spawn(delta: float, events: Array[Dictionary]) -> void:
	var boss_escort := _boss_fodder_active()
	if boss_phase != 0 and not boss_escort:
		return
	if not boss_escort and _in_boss_chain() and bosses_fought != bosses_killed:
		return
	var bo := live_boss()
	if not bo.is_empty() and bool(bo.get("frozen", false)):
		return
	if live_enemy_count() >= mini(MAX_ENEMIES, _occupancy()):
		return
	spawn_cd -= delta
	if spawn_cd > 0.0:
		return
	if boss_escort:
		spawn_cd = randf_range(0.20, 0.30)
	elif elapsed < ROUND_WARMUP_SEC:
		spawn_cd = randf_range(0.36, 0.50)
	else:
		var ph := phase()
		if ph == 1:
			spawn_cd = randf_range(0.20, 0.30)
		elif ph == 2:
			spawn_cd = randf_range(0.12, 0.20)
		elif ph == 3:
			spawn_cd = randf_range(0.08, 0.14)
		elif ph == 0:
			spawn_cd = randf_range(0.40, 0.52)
		else:
			spawn_cd = randf_range(0.22, 0.34)
	_spawn_chunk(events)
	chunk_spawns += 1
	wave_chunk += 1
	if wave_chunk > max_wave_chunk:
		max_wave_chunk = wave_chunk
	if wave >= 5 and live_enemy_count() < 6:
		spawn_cd = minf(spawn_cd, 0.22)


func _spawn_late_phrase() -> void:
	if randf() < 0.50:
		_spawn_enemy(KIND_GOLD, 0.18 if randf() < 0.5 else 0.82, true, false)
	else:
		_spawn_enemy(KIND_PURPLE, randf_range(0.34, 0.66), false, false)


func _spawn_chunk(_events: Array[Dictionary]) -> void:
	var room := mini(MAX_ENEMIES, _occupancy()) - live_enemy_count()
	if room <= 0:
		return
	if elapsed < ROUND_WARMUP_SEC:
		if spawn_total >= 14 or live_enemy_count() >= 6:
			return
		var wroll := randf()
		if wroll < 0.38 and room >= 2:
			var n_w := mini(2, room)
			for _wi in n_w:
				_spawn_enemy(KIND_RED, randf_range(0.30, 0.70), false, false, {
					"hold_t": 0.22,
					"shoot_cd": 99.0,
				})
		elif wroll < 0.62 and room >= 2:
			_spawn_enemy(KIND_RED, randf_range(0.32, 0.44), false, false, {"hold_t": 0.22, "shoot_cd": 99.0})
			_spawn_enemy(KIND_RED, randf_range(0.56, 0.68), false, false, {"hold_t": 0.22, "shoot_cd": 99.0})
		else:
			_spawn_enemy(KIND_RED, randf_range(0.34, 0.66), false, false, {
				"hold_t": 0.25,
				"shoot_cd": 99.0,
			})
		return
	var ph := phase()
	var roll := randf()
	if ph == 0:
		if spawn_total < 2 or elapsed < 2.0:
			_spawn_enemy(KIND_RED, randf_range(0.42, 0.58), false, false)
			return
		if roll < 0.28:
			_spawn_enemy(_pick_kind_for_phase(), randf_range(0.44, 0.56), false, false)
		else:
			_spawn_line(mini(2, room), 0.16, false)
		return
	if _spawn_chunk_is_wave1():
		var dive_p := 0.62
		if roll < 0.10 and room >= 1:
			_spawn_enemy(KIND_GOLD, 0.16 if randf() < 0.5 else 0.84, true, false)
		elif roll < 0.28 and room >= 2:
			_spawn_purple_escort(room)
		elif roll < 0.72:
			_spawn_line(mini(3 if randf() < 0.55 else 4, room), 0.14, randf() < dive_p)
		else:
			_spawn_stagger(mini(3 if randf() < 0.50 else 4, room), randf() < dive_p)
		return
	if ph == 2:
		if roll < 0.12 and room >= 2:
			_spawn_side_cut(mini(2, room))
		elif roll < 0.42:
			_spawn_line(mini(4, room), 0.13, randf() < 0.82)
		elif roll < 0.68:
			_spawn_stagger(mini(4, room), randf() < 0.78)
		elif roll < 0.84 and room >= 2:
			_spawn_purple_escort(room)
		else:
			_spawn_vee(mini(3, room), randf() < 0.55)
		return
	if ph == 3:
		var room2 := room
		if roll < 0.18 and room2 >= 2:
			_spawn_side_cut(mini(2, room2))
			room2 = mini(MAX_ENEMIES, _occupancy()) - live_enemy_count()
		if room2 <= 0:
			return
		if roll < 0.48:
			_spawn_line(mini(4, room2), 0.12, randf() < 0.90)
			room2 = mini(MAX_ENEMIES, _occupancy()) - live_enemy_count()
			if room2 >= 2 and randf() < 0.55:
				_spawn_stagger(mini(2, room2), randf() < 0.85)
		elif roll < 0.72:
			_spawn_purple_escort(room2)
			room2 = mini(MAX_ENEMIES, _occupancy()) - live_enemy_count()
			if room2 >= 2:
				_spawn_enemy(KIND_CYAN, _lane_away(0.18), true, false)
		elif roll < 0.86:
			_spawn_snake(mini(3, room2))
		else:
			_spawn_vee(mini(3, room2), true)
			room2 = mini(MAX_ENEMIES, _occupancy()) - live_enemy_count()
			if room2 >= 1 and randf() < 0.45:
				_spawn_enemy(KIND_GOLD, 0.16 if randf() < 0.5 else 0.84, true, false)
		return
	if ph == 1:
		var dive_p := 0.48 if wave <= 3 else 0.68
		if roll < 0.08 and room >= 1:
			_spawn_enemy(KIND_GOLD, 0.16 if randf() < 0.5 else 0.84, true, false)
		elif roll < 0.24 and room >= 2:
			_spawn_purple_escort(room)
		elif roll < 0.78:
			_spawn_line(mini(2 if randf() < 0.62 else 3, room), 0.15, randf() < dive_p)
		else:
			_spawn_stagger(mini(2 if randf() < 0.45 else 3, room), randf() < dive_p)
		return
	if roll < 0.10 and room >= 1:
		_spawn_side_cut(mini(2, room))
	elif roll < 0.38:
		_spawn_enemy(KIND_CYAN, _lane_away(0.20), true, false)
		if room >= 2:
			_spawn_enemy(KIND_RED if randf() < 0.35 else KIND_CYAN, _lane_away(0.24), randf() < 0.70, false)
	elif roll < 0.44 and room >= 1:
		_spawn_enemy(KIND_GOLD, 0.16 if randf() < 0.5 else 0.84, true, false)
	elif roll < 0.58:
		_spawn_purple_escort(room)
	else:
		_spawn_line(mini(2 if randf() < 0.32 else 3, room), 0.14, randf() < 0.90)


func _wave_room() -> int:
	return maxi(0, mini(MAX_ENEMIES, _occupancy()) - live_enemy_count())


func _fodder_theme_id(w: int) -> int:
	if w <= 1:
		return 0
	var fodder_n := w - int(w / 4)
	return 1 + (fodder_n - 2) % 7


func _spawn_fodder_theme(w: int) -> String:
	var room := _wave_room()
	match _fodder_theme_id(w):
		0:
			_spawn_enemy(KIND_RED, 0.38, false, false, {"hold_t": 0.25, "shoot_cd": 1.10})
			_spawn_enemy(KIND_RED, 0.62, false, false, {"hold_t": 0.25, "shoot_cd": 1.10})
			return "双机入场"
		1:
			var n2 := mini(3, maxi(0, room))
			for i in n2:
				_spawn_enemy(KIND_RED, 0.34 + float(i) * 0.16, false, false, {"hold_t": 0.25, "shoot_cd": 1.20})
			return "横排出击"
		2:
			_spawn_vee(mini(3, room), true)
			return "俯冲三角"
		3:
			var gx := 0.16 if randf() < 0.5 else 0.84
			if room >= 1:
				_spawn_enemy(KIND_GOLD, gx, true, false)
			if room >= 2:
				_spawn_enemy(KIND_RED, clampf(gx + (0.14 if gx < 0.5 else -0.14), 0.12, 0.88), false, false)
			if room >= 3:
				_spawn_enemy(KIND_RED, clampf(gx + (0.26 if gx < 0.5 else -0.26), 0.12, 0.88), false, false)
			return "金机护送"
		4:
			_spawn_side_cut(room)
			return "侧翼切入"
		5:
			_spawn_snake(room)
			return "蛇形编队"
		6:
			if wave_had_meteor:
				_spawn_line(mini(2, maxi(1, room)), 0.16, false)
				return "横排出击"
			_spawn_meteor()
			wave_had_meteor = true
			return "空袭预警"
		_:
			if wave_had_orbit:
				_spawn_snake(room)
				return "蛇形编队"
			_spawn_orbit(room)
			wave_had_orbit = true
			return "回旋切入"


func _spawn_side_cut(room: int) -> void:
	var n := mini(2, maxi(0, room))
	for i in n:
		var from_left := i == 0
		var dest := 0.30 if from_left else 0.70
		_spawn_enemy(KIND_CYAN if i == 0 else KIND_RED, dest, false, false, {
			"pattern": "side",
			"x": -0.10 if from_left else 1.10,
			"y": randf_range(0.18, 0.34),
			"vx": 0.46 if from_left else -0.46,
		})


func _spawn_snake(room: int) -> void:
	var n := mini(3, maxi(0, room))
	var mid := randf_range(0.32, 0.68)
	for i in n:
		_spawn_enemy(KIND_CYAN if i == 0 else KIND_RED, mid + float(i - 1) * 0.10, false, false, {
			"pattern": "snake",
			"weave": 0.18,
			"freq": 2.05,
			"phase": float(i) * 2.35,
			"y": -0.06 - float(i) * 0.12,
		})


func _spawn_orbit(room: int) -> void:
	if room <= 0:
		return
	_spawn_enemy(KIND_CYAN, 0.18, false, false, {
		"pattern": "orbit",
		"x": 0.08,
		"y": -0.04,
		"orbit_t": 0.0,
	})


func _live_meteor_count() -> int:
	var n := 0
	for e in enemies:
		if bool(e["live"]) and bool(e.get("meteor", false)):
			n += 1
	return n


func _spawn_meteor() -> void:
	if _live_meteor_count() >= 1:
		return
	_spawn_enemy(KIND_PURPLE, randf_range(0.26, 0.74), false, false, {
		"meteor": true,
		"pattern": "meteor",
		"hp": 3,
		"vy": 0.082,
		"weave": 0.0,
		"hit_w": 0.16,
		"hit_h": 0.14,
	})


func _live_dive_count() -> int:
	var n := 0
	for e in enemies:
		if not bool(e["live"]) or int(e["hp"]) <= 0:
			continue
		if bool(e.get("is_boss", false)) or bool(e.get("meteor", false)):
			continue
		if bool(e.get("diving", false)) or float(e.get("warn_t", 0.0)) > 0.0 or (bool(e.get("diver", false)) and not bool(e.get("warned", false))):
			n += 1
	return n


func _spawn_vee(n: int, dive_tip: bool = false) -> void:
	if n <= 0:
		return
	var mid := randf_range(0.34, 0.66)
	var tip := KIND_CYAN if phase() >= 1 else KIND_RED
	_spawn_enemy(tip, mid, dive_tip and _live_dive_count() < 2, false)
	if n >= 2:
		_spawn_enemy(KIND_RED, clampf(mid - 0.13, 0.12, 0.88), false, false)
		var a := _last_live()
		if not a.is_empty():
			a["y"] = -0.14
	if n >= 3:
		_spawn_enemy(KIND_RED, clampf(mid + 0.13, 0.12, 0.88), false, false)
		var b := _last_live()
		if not b.is_empty():
			b["y"] = -0.14


func _lane_away(min_d: float) -> float:
	var dir := -1.0 if player_x >= 0.5 else 1.0
	if randf() < 0.22:
		dir = -dir
	return clampf(player_x + dir * randf_range(min_d, min_d + 0.14), 0.14, 0.86)


func _spawn_line(n: int, gap: float, dive: bool) -> void:
	var mid := _lane_away(0.26 + gap * float(n - 1) * 0.5)
	mid = clampf(mid, 0.18 + gap * float(n - 1) * 0.5, 0.82 - gap * float(n - 1) * 0.5)
	for i in n:
		var k := KIND_CYAN if phase() == 2 and randf() < 0.45 else KIND_RED
		if phase() == 1 and randf() < 0.22:
			k = KIND_CYAN
		var want_dive := dive and i == n / 2 and _live_dive_count() < 2
		_spawn_enemy(k, mid + (float(i) - float(n - 1) * 0.5) * gap, want_dive, false, {"hold_t": 0.25, "shoot_cd": 1.15})


func _spawn_stagger(n: int, dive: bool) -> void:
	var x0 := _lane_away(0.16)
	var dir := 1.0 if x0 < 0.5 else -1.0
	for i in n:
		var k := KIND_CYAN if (phase() >= 1 and i == 0) else KIND_RED
		_spawn_enemy(k, clampf(x0 + dir * float(i) * 0.13, 0.12, 0.88), dive and i == 0 and _live_dive_count() < 2, false)
		## 错开进场：后进的 y 稍高（更靠屏幕外）
		var last := _last_live()
		if not last.is_empty():
			last["y"] = -0.06 - float(i) * 0.07


func _spawn_purple_escort(room: int) -> void:
	var px := _lane_away(0.18)
	_spawn_enemy(KIND_PURPLE, px, false, false)
	if room >= 2:
		_spawn_enemy(KIND_RED, clampf(px + (0.16 if px < 0.5 else -0.16), 0.12, 0.88), false, false)


func _last_live() -> Dictionary:
	for i in range(enemies.size() - 1, -1, -1):
		if bool(enemies[i]["live"]):
			return enemies[i]
	return {}


func _tick_bullets(delta: float) -> void:
	for b in bullets:
		if not bool(b["live"]):
			continue
		if bool(b.get("homing", false)):
			var tgt := _nearest_target()
			if not tgt.is_empty():
				var dx := float(tgt["x"]) - float(b["x"])
				var dy := float(tgt["y"]) - float(b["y"])
				var L := maxf(0.08, sqrt(dx * dx + dy * dy))
				b["vx"] = lerpf(float(b.get("vx", 0.0)), dx / L * 0.85, clampf(delta * 6.0, 0.0, 1.0))
				b["vy"] = lerpf(float(b["vy"]), dy / L * 0.85, clampf(delta * 6.0, 0.0, 1.0))
		b["x"] = float(b["x"]) + float(b.get("vx", 0.0)) * delta
		b["y"] = float(b["y"]) + float(b["vy"]) * delta
		if float(b["y"]) < -0.08 or float(b["x"]) < -0.06 or float(b["x"]) > 1.06:
			b["live"] = false


func _tick_ebullets(delta: float) -> void:
	var boss_alive := not live_boss().is_empty()
	for b in ebullets:
		if not bool(b["live"]):
			continue
		if float(b.get("hit_cd", 0.0)) > 0.0:
			b["hit_cd"] = maxf(0.0, float(b["hit_cd"]) - delta)
		if float(b.get("flash", 0.0)) > 0.0:
			b["flash"] = maxf(0.0, float(b["flash"]) - delta)
		## Boss 弹：短时弱追踪；Boss 死后或超时一律直线
		if bool(b.get("fat", false)) and bool(b.get("homing", false)):
			b["home_t"] = maxf(0.0, float(b.get("home_t", 0.0)) - delta)
			if (not boss_alive) or float(b["home_t"]) <= 0.0:
				b["homing"] = false
			else:
				var vx0 := float(b.get("vx", 0.0))
				var vy0 := float(b.get("vy", 0.22))
				var spd := maxf(0.16, sqrt(vx0 * vx0 + vy0 * vy0))
				var want := _aim_vel(float(b["x"]), float(b["y"]), player_x, player_y, spd)
				var turn := float(b.get("home_turn", 0.0))
				if turn <= 0.0:
					turn = 1.35
					var bo: Dictionary = live_boss()
					if not bo.is_empty() and bool(bo.get("phase2", false)):
						turn = 1.65
				var k := clampf(delta * turn, 0.0, 1.0)
				var nvx := lerpf(vx0, want.x, k)
				var nvy := lerpf(vy0, want.y, k)
				var L := maxf(0.08, sqrt(nvx * nvx + nvy * nvy))
				b["vx"] = nvx / L * spd
				b["vy"] = nvy / L * spd
		b["x"] = float(b["x"]) + float(b.get("vx", 0.0)) * delta
		b["y"] = float(b["y"]) + float(b["vy"]) * delta
		if float(b["y"]) > 1.08 or float(b["x"]) < -0.08 or float(b["x"]) > 1.08:
			b["live"] = false


func _clear_boss_bullet_homing() -> void:
	for b in ebullets:
		if bool(b["live"]) and bool(b.get("fat", false)):
			b["homing"] = false
			b["home_t"] = 0.0


func _tick_enemies(delta: float, events: Array[Dictionary]) -> void:
	for e in enemies:
		if not bool(e["live"]):
			continue
		if float(e.get("dying", 0.0)) > 0.0:
			e["dying"] = float(e["dying"]) - delta
			e["punch"] = maxf(0.0, float(e.get("punch", 0.0)) - delta)
			if float(e["dying"]) <= 0.0:
				e["live"] = false
			continue
		var pat := str(e.get("pattern", ""))
		if bool(e.get("is_boss", false)):
			_tick_boss_unit(e, delta, events)
			continue
		if pat == "flee":
			e["x"] = float(e["x"]) + float(e.get("vx", 0.0)) * delta
			e["y"] = float(e["y"]) + float(e.get("vy", 0.25)) * delta
			if float(e["x"]) < -0.12 or float(e["x"]) > 1.12 or float(e["y"]) > 1.08:
				e["live"] = false
			continue
		if pat == "orbit":
			e["orbit_t"] = float(e.get("orbit_t", 0.0)) + delta
			var ot := float(e["orbit_t"])
			if ot < 0.55:
				e["x"] = lerpf(float(e["x"]), 0.50, 2.2 * delta)
				e["y"] = lerpf(float(e["y"]), 0.34, 2.0 * delta)
			elif ot < 1.35:
				var ang := (ot - 0.55) * 3.6
				e["x"] = 0.50 + cos(ang) * 0.16
				e["y"] = 0.34 + sin(ang) * 0.10
			else:
				e["pattern"] = ""
				e["base_x"] = float(e["x"])
				e["vy"] = maxf(float(e["vy"]), 0.16)
			continue
		if pat == "side":
			e["x"] = float(e["x"]) + float(e.get("vx", 0.0)) * delta
			e["y"] = float(e["y"]) + float(e["vy"]) * 0.42 * delta
			var reached := (float(e.get("vx", 0.0)) > 0.0 and float(e["x"]) >= float(e["base_x"])) \
				or (float(e.get("vx", 0.0)) < 0.0 and float(e["x"]) <= float(e["base_x"]))
			if reached or float(e["y"]) > 0.52:
				e["pattern"] = ""
				e["base_x"] = float(e["x"])
				e["vx"] = 0.0
			if float(e["x"]) < -0.16 or float(e["x"]) > 1.16:
				e["live"] = false
			continue
		if pat == "meteor":
			e["y"] = float(e["y"]) + float(e["vy"]) * delta
			e["x"] = clampf(float(e["base_x"]) + sin(elapsed * 0.9) * 0.018, 0.10, 0.90)
			if float(e.get("flash", 0.0)) > 0.0:
				e["flash"] = float(e["flash"]) - delta
			if float(e.get("punch", 0.0)) > 0.0:
				e["punch"] = float(e["punch"]) - delta
			if float(e["y"]) > 1.08:
				e["live"] = false
			continue
		var warn_t := float(e.get("warn_t", 0.0))
		if float(e.get("hold_t", 0.0)) > 0.0:
			e["hold_t"] = float(e["hold_t"]) - delta
			e["y"] = float(e["y"]) + float(e["vy"]) * 0.12 * delta
			e["x"] = clampf(float(e.get("base_x", e["x"])), 0.07, 0.93)
			if float(e.get("flash", 0.0)) > 0.0:
				e["flash"] = float(e["flash"]) - delta
			if float(e["hold_t"]) <= 0.0:
				e["flash"] = maxf(float(e.get("flash", 0.0)), 0.18)
			if float(e["y"]) > 1.06:
				e["live"] = false
			continue
		if warn_t > 0.0:
			e["warn_t"] = warn_t - delta
			e["y"] = float(e["y"]) + float(e["vy"]) * 0.28 * delta
			if float(e["warn_t"]) <= 0.0:
				e["diving"] = true
				e["vy"] = float(e["vy"]) * 2.15
			e["x"] = float(e.get("warn_x", e["base_x"]))
		elif bool(e.get("diving", false)):
			e["y"] = float(e["y"]) + float(e["vy"]) * delta
			## 先沿侧线下落，接近玩家高度再切向锁定 X，站桩打不掉、躲才活
			var t := clampf((float(e["y"]) - 0.64) / 0.18, 0.0, 1.0)
			e["x"] = lerpf(float(e.get("warn_x", e["base_x"])), float(e.get("aim_x", e["base_x"])), t * t)
		else:
			e["y"] = float(e["y"]) + float(e["vy"]) * delta
			e["x"] = clampf(
				float(e["base_x"]) + sin(elapsed * float(e["freq"]) + float(e["phase"])) * float(e["weave"]),
				0.07,
				0.93
			)
			if bool(e.get("diver", false)) and not bool(e.get("warned", false)) and float(e["y"]) >= DIVE_Y:
				if _live_dive_count() >= 3 and int(e["kind"]) != KIND_GOLD:
					e["diver"] = false
				else:
					e["warned"] = true
					e["warn_t"] = 0.20 if int(e["kind"]) == KIND_GOLD else DIVE_WARN
					e["warn_x"] = float(e["x"])
					e["aim_x"] = player_x
					e["flash"] = 0.35
					events.append({"type": "dive_warn", "x": float(e["x"]), "y": float(e["y"]), "aim": player_x})
		if float(e.get("flash", 0.0)) > 0.0:
			e["flash"] = float(e["flash"]) - delta
		if float(e.get("punch", 0.0)) > 0.0:
			e["punch"] = float(e["punch"]) - delta
		_tick_fodder_gun(e, delta, events)
		if float(e["y"]) > 1.06:
			e["live"] = false


func _tick_fodder_gun(e: Dictionary, delta: float, events: Array[Dictionary]) -> void:
	if not _fodder_may_shoot():
		return
	var kind := int(e["kind"])
	var y := float(e["y"])
	if int(e.get("burst_left", 0)) > 0:
		e["burst_cd"] = float(e.get("burst_cd", 0.0)) - delta
		if float(e["burst_cd"]) > 0.0:
			return
		if y < 0.14 or y > 0.64 or not _room_eb_fodder(1):
			e["burst_cd"] = 0.06
			return
		var spd := _eb_spd_fob()
		if int(e.get("burst_mode", 0)) == 2:
			var dir := signf(player_x - float(e["x"]))
			if dir == 0.0:
				dir = 1.0
			_fire_eb(float(e["x"]), y + 0.04, dir * 0.14, spd, false)
		else:
			_fire_eb(float(e["x"]), y + 0.04, 0.0, spd, false)
		e["burst_left"] = int(e["burst_left"]) - 1
		events.append({"type": "eshot", "kind": kind, "boss": false, "x": float(e["x"]), "y": y})
		return
	e["shoot_cd"] = float(e.get("shoot_cd", 0.0)) - delta
	if float(e["shoot_cd"]) > 0.0 or y < 0.14 or y > 0.62:
		return
	var spd2 := _eb_spd_fob()
	if kind == KIND_RED:
		if not _room_eb_fodder(1):
			return
		_fire_eb(float(e["x"]), y + 0.04, 0.0, spd2, false)
		e["shoot_cd"] = randf_range(1.12, 1.55)
		events.append({"type": "eshot", "kind": kind, "boss": false, "x": float(e["x"]), "y": y})
		return
	if kind == KIND_CYAN:
		var n := 2 if wave >= 2 else 1
		if not _room_eb_fodder(n):
			if n == 2 and _room_eb_fodder(1):
				n = 1
			else:
				return
		var dir2 := signf(player_x - float(e["x"]))
		if dir2 == 0.0:
			dir2 = 1.0
		_fire_eb(float(e["x"]), y + 0.04, dir2 * 0.14, spd2, false)
		if n >= 2:
			e["burst_left"] = 1
			e["burst_cd"] = 0.20
			e["burst_mode"] = 2
		e["shoot_cd"] = randf_range(1.15, 1.55)
		events.append({"type": "eshot", "kind": kind, "boss": false, "x": float(e["x"]), "y": y})
		return
	if kind != KIND_PURPLE or wave < 2:
		return
	if not _room_eb_fodder(3):
		return
	if not _fire_fan(float(e["x"]), y + 0.04, 3, 14.0, spd2, false):
		return
	e["shoot_cd"] = randf_range(0.95, 1.30)
	events.append({"type": "eshot", "kind": kind, "boss": false, "x": float(e["x"]), "y": y})


func _tick_items(delta: float, events: Array[Dictionary]) -> void:
	for it in items:
		if not bool(it["live"]):
			continue
		var ix := float(it["x"])
		var iy := float(it["y"])
		iy += 0.20 * delta
		if iy > player_y - 0.22 and absf(ix - player_x) < 0.16:
			ix += signf(player_x - ix) * 0.22 * delta
		it["x"] = ix
		it["y"] = iy
		if iy > 1.04:
			it["live"] = false
			continue
		if absf(ix - player_x) < 0.12 and absf(iy - player_y) < 0.11:
			it["live"] = false
			item_from_boss = bool(it.get("from_boss", false))
			_apply_item(int(it["kind"]), events)


func _collide_shots(events: Array[Dictionary]) -> void:
	for b in bullets:
		if not bool(b["live"]):
			continue
		var bx := float(b["x"])
		var by := float(b["y"])
		## 玩家弹可打爆 Boss 导弹（fat 敌弹）
		if _try_break_boss_missile(bx, by, maxi(1, int(b.get("dmg", 1))), events):
			b["live"] = false
			continue
		for e in enemies:
			if not bool(e["live"]) or int(e["hp"]) <= 0:
				continue
			var kind := int(e["kind"])
			var slim := 0.62 if bool(e.get("diving", false)) or float(e.get("warn_t", 0.0)) > 0.0 else 1.0
			var hw: float = (float(e.get("hit_w", KIND_HIT_W[kind])) + BULLET_HIT) * slim
			var hh: float = (float(e.get("hit_h", KIND_HIT_H[kind])) + BULLET_HIT) * slim
			if absf(bx - float(e["x"])) < hw * 0.5 and absf(by - float(e["y"])) < hh * 0.5:
				b["live"] = false
				if bool(e.get("is_boss", false)):
					var raw := maxi(1, int(b.get("dmg", 1)))
					if bool(b.get("homing", false)) or power_lv >= 5:
						raw = 1
					var hr := _hurt_boss(e, raw, events)
					if hr == 2:
						_start_pipe_break(e, events)
					elif hr > 0 and int(e["hp"]) <= 0:
						_kill_enemy(e, events)
					elif hr > 0:
						events.append({
							"type": "hit",
							"kind": kind,
							"boss": true,
							"x": float(e["x"]),
							"y": float(e["y"]),
						})
				else:
					e["hp"] = int(e["hp"]) - maxi(1, int(b.get("dmg", 1)))
					e["flash"] = 0.08
					e["punch"] = 0.14
					if int(e["hp"]) <= 0:
						_kill_enemy(e, events)
					else:
						events.append({
							"type": "hit",
							"kind": kind,
							"boss": false,
							"x": float(e["x"]),
							"y": float(e["y"]),
						})
				break


## 命中 Boss 导弹：有血量 + 短无敌间隔；返回 true 表示吞掉玩家弹
func _try_break_boss_missile(bx: float, by: float, dmg: int, events: Array[Dictionary]) -> bool:
	for eb in ebullets:
		if not bool(eb["live"]) or not bool(eb.get("fat", false)):
			continue
		## 导弹细长：判定略宽于普通敌弹
		var hw := (EBULLET_HIT_BOSS + BULLET_HIT) * 0.72
		var hh := (EBULLET_HIT_BOSS + BULLET_HIT) * 0.95
		if absf(bx - float(eb["x"])) >= hw:
			continue
		if absf(by - float(eb["y"])) >= hh:
			continue
		_hurt_boss_missile(eb, dmg, events)
		return true
	return false


func _hurt_boss_missile(eb: Dictionary, dmg: int, events: Array[Dictionary]) -> void:
	if not bool(eb.get("live", false)):
		return
	if float(eb.get("hit_cd", 0.0)) > 0.0:
		return
	eb["hit_cd"] = BOSS_MISSILE_HIT_GAP
	eb["flash"] = 0.12
	eb["hp"] = int(eb.get("hp", BOSS_MISSILE_HP)) - maxi(1, dmg)
	if int(eb["hp"]) > 0:
		return
	_break_boss_missile(eb, events)


func _break_boss_missile(eb: Dictionary, events: Array[Dictionary]) -> void:
	eb["live"] = false
	eb["homing"] = false
	eb["home_t"] = 0.0
	eb["hp"] = 0
	events.append({
		"type": "boom",
		"x": float(eb["x"]),
		"y": float(eb["y"]),
		"big": false,
		"n": 1,
		"kind": 0,
		"boss": false,
		"missile": true,
	})


func _damage_boss_missiles_in_beam(beam_w: float, dmg: int, events: Array[Dictionary]) -> void:
	for eb in ebullets:
		if not bool(eb["live"]) or not bool(eb.get("fat", false)):
			continue
		if float(eb["y"]) >= player_y:
			continue
		if absf(float(eb["x"]) - player_x) >= beam_w:
			continue
		_hurt_boss_missile(eb, dmg, events)


func _tick_graze() -> void:
	if ended or invuln > 0.0:
		return
	for b in ebullets:
		if not bool(b["live"]) or bool(b.get("grazed", false)):
			continue
		var eh: float = EBULLET_HIT_BOSS if bool(b.get("fat", false)) else EBULLET_HIT
		var hw := PLAYER_HIT_W * 0.5 + eh * 0.5
		var hh := PLAYER_HIT_H * 0.5 + eh * 0.5
		var dx := absf(float(b["x"]) - player_x)
		var dy := absf(float(b["y"]) - player_y)
		if dx < hw and dy < hh:
			continue
		if dx < hw + GRAZE_PAD and dy < hh + GRAZE_PAD:
			b["grazed"] = true
			if graze_n >= GRAZE_MAX_PER_SEC:
				continue
			graze_n += 1


func _collide_player(events: Array[Dictionary]) -> void:
	if ended or invuln > 0.0:
		return
	for p in boss_parts:
		if not bool(p["live"]):
			continue
		var hw := float(p.get("hit_w", BOSS_PART_HIT_W)) * 0.5
		var hh := float(p.get("hit_h", BOSS_PART_HIT_H)) * 0.5
		if absf(float(p["x"]) - player_x) >= hw + PLAYER_HIT_W * 0.5:
			continue
		if absf(float(p["y"]) - player_y) >= hh + PLAYER_HIT_H * 0.5:
			continue
		p["live"] = false
		_hurt_player(events, float(p["x"]), float(p["y"]))
		events.append({"type": "boom", "x": float(p["x"]), "y": float(p["y"]), "big": false, "n": 2})
		return
	for b in ebullets:
		if not bool(b["live"]):
			continue
		var eh: float = EBULLET_HIT_BOSS if bool(b.get("fat", false)) else EBULLET_HIT
		if absf(float(b["x"]) - player_x) < PLAYER_HIT_W * 0.5 + eh * 0.5 and absf(float(b["y"]) - player_y) < PLAYER_HIT_H * 0.5 + eh * 0.5:
			b["live"] = false
			_hurt_player(events, float(b["x"]), float(b["y"]))
			return
	for e in enemies:
		if not bool(e["live"]) or int(e["hp"]) <= 0:
			continue
		var kind := int(e["kind"])
		var tw: float = BOSS_TOUCH_W if bool(e.get("is_boss", false)) else float(e.get("hit_w", KIND_HIT_W[kind])) * 0.42 + PLAYER_HIT_W * 0.5
		var th: float = BOSS_TOUCH_H if bool(e.get("is_boss", false)) else float(e.get("hit_h", KIND_HIT_H[kind])) * 0.42 + PLAYER_HIT_H * 0.5
		if absf(float(e["x"]) - player_x) >= tw:
			continue
		if absf(float(e["y"]) - player_y) >= th:
			continue
		if not bool(e.get("is_boss", false)):
			e["live"] = false
			e["hp"] = 0
		_hurt_player(events, float(e["x"]), float(e["y"]))
		return


func _hurt_player(events: Array[Dictionary], x: float, y: float) -> void:
	if show_shield_t > 0.0:
		show_shield_t = 0.0
		invuln = maxf(invuln, 0.35)
		_flash("护盾抵挡")
		events.append({"type": "shield_block", "x": x, "y": y})
		return
	if shield:
		shield = false
		invuln = maxf(invuln, 0.45)
		_flash("护盾抵挡")
		events.append({"type": "shield_block", "x": x, "y": y})
		return
	hp -= 1
	if power_lv > 0:
		power_lv -= 1
		_refresh_wings()
		_flash("火力 -1")
	else:
		_flash("受伤 -1" if hp > 1 else "最后一条命")
	invuln = HURT_IFRAMES
	events.append({"type": "hurt", "hp": hp, "x": player_x, "y": player_y, "lv": power_lv})
	if hp <= 0:
		_finish("被击落", events)


func _kill_enemy(e: Dictionary, events: Array[Dictionary]) -> void:
	e["hp"] = 0
	e["dying"] = 0.22 if bool(e.get("is_boss", false)) else 0.12
	e["punch"] = 0.16 if bool(e.get("is_boss", false)) else 0.12
	e["flash"] = 0.16
	kills += 1
	var kind := int(e["kind"])
	var extra := _combo_extra()
	var green_gems := _green_gems_for_kill(kind, e) + extra
	var gain := _add_display(green_gems * SCORE_GREEN_GEM)
	_add_token(_token_points(kind, e))
	if extra > 0:
		_add_token(extra)
	_maybe_drop(e)
	if bool(e.get("is_boss", false)):
		bosses_killed += 1
		last_boss_kill_t = boss_fight_t
		if boss1_t <= 0.0:
			boss1_t = elapsed
		boss_phase = 8
		boss_phase_t = BOSS_OUTRO_SEC
		sweep_on = false
		_clear_boss_bullet_homing()
		_flash("霸王击破" if int(e.get("boss_style", 0)) >= 4 else "击破")
		events.append({
			"type": "boss_kill",
			"kind": kind,
			"gain": gain,
			"x": float(e["x"]),
			"y": float(e["y"]),
			"style": int(e.get("boss_style", 0)),
			"t": last_boss_kill_t,
		})
	elif gain > 0:
		_flash("+%d" % gain)
	events.append({
		"type": "kill",
		"kind": kind,
		"gain": gain,
		"combo": combo,
		"boss": bool(e.get("is_boss", false)),
		"x": float(e["x"]),
		"y": float(e["y"]),
		"gold": kind == KIND_GOLD,
	})
	if combo >= COMBO_TIER_FENGSHEN:
		_combo_cashout(events, true)
	events.append({
		"type": "boom",
		"x": float(e["x"]),
		"y": float(e["y"]),
		"big": bool(e.get("is_boss", false)) or kind == KIND_GOLD,
		"n": 6 if bool(e.get("is_boss", false)) else (3 if kind == KIND_GOLD else 1),
		"kind": kind,
		"boss": bool(e.get("is_boss", false)),
	})
	_grant_energy(e, events)


## 与 plane_game 飞出绿宝石数量一致（1 颗 = SCORE_GREEN_GEM 分）
func _green_gems_for_kill(kind: int, e: Dictionary = {}) -> int:
	if bool(e.get("is_boss", false)):
		return 10
	if kind == KIND_GOLD:
		return 3
	if kind == KIND_PURPLE:
		return 5
	return 1


func _display_points(kind: int, e: Dictionary = {}) -> int:
	return _green_gems_for_kill(kind, e) * SCORE_GREEN_GEM


func _token_points(kind: int, e: Dictionary = {}) -> int:
	if bool(e.get("is_boss", false)):
		return BOSS_SCORE
	if bool(e.get("meteor", false)):
		return 1 if token_score < 12 else 0
	if bool(e.get("boss", false)):
		if token_score < 12:
			return 3
		return 1 if token_score < 16 else 0
	if kind == KIND_GOLD:
		if token_score < 10:
			return 2
		return 1 if token_score < 14 else 0
	if kind == KIND_PURPLE:
		if token_score < 10:
			return 2
		return 1 if token_score < 13 else 0
	if token_score >= 8 or wave >= 3:
		return 0
	return 1


func _combo_cashout(events: Array[Dictionary], fengshen_peak: bool) -> void:
	if combo < 3:
		combo = 0
		combo_bonus = 0
		return
	var prev_combo := combo
	combo = 0
	combo_bonus = 0
	var rubies := _combo_break_ruby_count(prev_combo)
	if rubies <= 0:
		return
	var gain := _add_display(rubies * SCORE_RUBY_GEM)
	_add_token(rubies)
	events.append({
		"type": "combo_break",
		"combo": prev_combo,
		"gems": rubies,
		"gain": gain,
		"fengshen": fengshen_peak,
	})


func _combo_break_ruby_count(c: int) -> int:
	if c < 3:
		return 0
	if c < 10:
		return 1
	if c < COMBO_TIER_LUANWU:
		return 3
	if c < COMBO_TIER_WUSHUANG:
		return 5
	if c < COMBO_TIER_FENGSHEN:
		return 10
	return 20


func _combo_extra() -> int:
	if elapsed - last_kill_at > COMBO_WINDOW:
		combo = 0
		combo_bonus = 0
	combo += 1
	last_kill_at = elapsed
	if power_lv >= 2 or token_score >= 10:
		return 0
	if combo < 3 or combo_bonus >= COMBO_EXTRA_MAX:
		return 0
	combo_bonus += 1
	return 1


func _apply_item(kind: int, events: Array[Dictionary]) -> void:
	match kind:
		ITEM_DOUBLE:
			item_from_boss = false
			var banner := "火力"
			if power_lv < POWER_MAX:
				power_lv = mini(POWER_MAX, power_lv + 1)
				last_power_gain = elapsed
				_refresh_wings()
				double_t = 0.40
				var title := power_title(power_lv)
				banner = "火力 Lv%d %s" % [power_lv, title] if title != "" else "火力 Lv%d" % power_lv
			else:
				double_t = DOUBLE_SEC
				banner = "火力已满"
			_flash(banner)
			events.append({"type": "item", "kind": kind, "lv": power_lv, "banner": banner})
		ITEM_SHIELD:
			shield = true
			_flash("护盾")
			events.append({"type": "item", "kind": kind})
		ITEM_LASER:
			shield = true
			_flash("护盾")
			events.append({"type": "item", "kind": ITEM_SHIELD})
		ITEM_NUKE:
			var g := _add_display(SCORE_POINT_SCALE)
			_flash("+%d" % g)
			events.append({"type": "item", "kind": kind, "banner": "+%d" % g})
		ITEM_HEART:
			if hp < MAX_HP:
				hp += 1
				_flash("+1")
				events.append({"type": "heal", "kind": kind, "hp": hp})
			else:
				_flash("满血")
				events.append({"type": "item", "kind": kind})
		_:
			events.append({"type": "item", "kind": kind})


func _do_nuke(events: Array[Dictionary]) -> void:
	invuln = maxf(invuln, BOMB_IFRAMES)
	var r := _blast_screen(events, true)
	var banner := "全屏清除" if int(r.get("cleared", 0)) > 0 or not live_boss().is_empty() else "空袭"
	_flash(banner)
	events.append({
		"type": "nuke",
		"kind": ITEM_NUKE,
		"cleared": int(r.get("cleared", 0)),
		"gain": int(r.get("gain", 0)),
		"banner": banner,
		"spots": r.get("spots", []),
	})


func _spawn_enemy(kind: int, base_x: float, diver: bool, _unused: bool, extras: Dictionary = {}) -> void:
	var slot := _acquire_enemy_slot()
	if slot < 0:
		return
	var pattern := str(extras.get("pattern", ""))
	if pattern != "side":
		base_x = clampf(base_x, 0.12, 0.88)
	var vy := 0.14
	var weave := 0.04
	var freq := 2.1
	match kind:
		KIND_RED:
			vy = randf_range(0.148, 0.170) + float(mini(wave, 6)) * 0.003
			weave = 0.028
			freq = 1.8
		KIND_CYAN:
			vy = randf_range(0.188, 0.214) + float(mini(wave, 6)) * 0.004
			weave = 0.038
			freq = 2.8
		KIND_PURPLE:
			vy = randf_range(0.082, 0.100) + float(mini(wave, 6)) * 0.0025
			weave = 0.022
			freq = 1.4
			diver = false
		KIND_GOLD:
			vy = randf_range(0.064, 0.079)
			weave = 0.030
			freq = 1.5
	if extras.has("vy"):
		vy = float(extras["vy"])
	if extras.has("weave"):
		weave = float(extras["weave"])
	if extras.has("freq"):
		freq = float(extras["freq"])
	vy *= _speed_mul()
	if bool(extras.get("meteor", false)) or bool(extras.get("is_boss", false)) or bool(extras.get("boss", false)):
		diver = false
	var hp0: int = _kind_hp(kind)
	if extras.has("hp"):
		hp0 = int(extras["hp"])
	var sx := float(extras.get("x", base_x))
	var sy := float(extras.get("y", -0.06))
	enemies[slot] = {
		"live": true,
		"kind": kind,
		"hp": hp0,
		"max_hp": hp0,
		"x": sx,
		"y": sy,
		"base_x": base_x,
		"vy": vy,
		"vx": float(extras.get("vx", 0.0)),
		"weave": weave,
		"freq": freq,
		"phase": float(extras.get("phase", randf() * TAU)),
		"flash": 0.0,
		"punch": 0.0,
		"diver": diver,
		"warned": false,
		"warn_t": 0.0,
		"warn_x": sx,
		"diving": false,
		"aim_x": base_x,
		"dying": 0.0,
		"shoot_cd": float(extras.get("shoot_cd", 0.45 if bool(extras.get("is_boss", false)) else randf_range(0.8, 1.6))),
		"pattern": pattern,
		"boss": bool(extras.get("boss", false)),
		"is_boss": bool(extras.get("is_boss", false)),
		"boss_style": int(extras.get("boss_style", 0)),
		"boss_invuln": float(extras.get("boss_invuln", 0.0)),
		"entering": bool(extras.get("entering", false)),
		"frozen": bool(extras.get("frozen", false)),
		"dir": float(extras.get("dir", 1.0)),
		"turn_t": float(extras.get("turn_t", 0.0)),
		"rest": bool(extras.get("rest", false)),
		"laser_cd": float(extras.get("laser_cd", 0.0)),
		"hit_gap": float(extras.get("hit_gap", 0.0)),
		"orbit_t": float(extras.get("orbit_t", 0.0)),
		"meteor": bool(extras.get("meteor", false)),
		"hit_w": float(extras.get("hit_w", KIND_HIT_W[kind])),
		"hit_h": float(extras.get("hit_h", KIND_HIT_H[kind])),
		"alt": bool(extras.get("alt", false)),
		"phase2": bool(extras.get("phase2", false)),
		"aim_t": float(extras.get("aim_t", 0.0)),
		"park_y": float(extras.get("park_y", BOSS_Y)),
		"burst_left": int(extras.get("burst_left", 0)),
		"burst_cd": float(extras.get("burst_cd", 0.0)),
		"burst_mode": int(extras.get("burst_mode", 0)),
		"volley": int(extras.get("volley", 0)),
		"want_escort": bool(extras.get("want_escort", false)),
		"want_sweep": bool(extras.get("want_sweep", false)),
		"pipe": int(extras.get("pipe", 1)),
		"pipe_max": int(extras.get("pipe_max", extras.get("hp", 1))),
		"total_hp": int(extras.get("total_hp", extras.get("hp", 1))),
		"breaking": bool(extras.get("breaking", false)),
		"sweep_cd": float(extras.get("sweep_cd", 2.4)),
		"sweep_arm": float(extras.get("sweep_arm", 0.0)),
		"left_cd": float(extras.get("left_cd", 0.70)),
		"right_cd": float(extras.get("right_cd", 0.95)),
		"gap_i": int(extras.get("gap_i", 0)),
		"beat": int(extras.get("beat", 0)),
		"atk_step": int(extras.get("atk_step", 0)),
		"muzzle_i": int(extras.get("muzzle_i", 0)),
		"preflash": bool(extras.get("preflash", false)),
		"hold_t": float(extras.get("hold_t", 0.0)),
		"boss_part_stage": int(extras.get("boss_part_stage", 0)),
		"boss_hp_lost": int(extras.get("boss_hp_lost", 0)),
	}
	spawn_total += 1


func _laser_allowed() -> bool:
	# 激光玩法已移除，不再掉落激光道具
	return false


func _alt_common_item(except: int) -> int:
	if hp < MAX_HP and except != ITEM_HEART and not _has_live_item(ITEM_HEART):
		return ITEM_HEART
	if except != ITEM_DOUBLE and not _has_live_item(ITEM_DOUBLE):
		return ITEM_DOUBLE
	if except != ITEM_SHIELD and not _has_live_item(ITEM_SHIELD):
		return ITEM_SHIELD
	if except != ITEM_DOUBLE:
		return ITEM_DOUBLE
	return ITEM_SHIELD


func _bomb_item_wanted() -> bool:
	return false


func _pick_special_power() -> int:
	var r := randf()
	var double_p := 0.55
	if power_lv >= 6:
		double_p *= 0.25
	elif power_lv >= 4:
		double_p *= 0.50
	if r < double_p:
		return ITEM_DOUBLE
	if r < 0.85:
		return ITEM_SHIELD
	if _bomb_item_wanted():
		return ITEM_NUKE
	return ITEM_SHIELD if randf() < 0.50 else ITEM_DOUBLE


func _pick_boss_drop(style: int = 0) -> int:
	if power_lv < 4:
		if hp <= 1 and randf() < 0.32:
			return ITEM_HEART
		return ITEM_DOUBLE
	if hp < MAX_HP:
		var p := 0.48 if hp <= 1 else 0.26
		if wave >= 6:
			p *= 0.5
		if style >= 4:
			p = maxf(p, 0.22 if wave < 8 else 0.14)
		if randf() < p:
			return ITEM_HEART
	if bombs <= 0 and _bomb_item_wanted() and randf() < 0.28:
		return ITEM_NUKE
	if hp >= MAX_HP and power_lv >= POWER_MAX:
		return ITEM_SHIELD
	return ITEM_DOUBLE


func _has_live_item(kind: int) -> bool:
	for it in items:
		if bool(it["live"]) and int(it["kind"]) == kind:
			return true
	return false


func _roll_item_kind() -> int:
	var r := randf()
	if hp < MAX_HP:
		var heart_w := 0.32 if hp <= 1 else 0.22
		if wave >= 6:
			heart_w *= 0.5
		if r < heart_w:
			return ITEM_HEART
		r = (r - heart_w) / maxf(0.001, 1.0 - heart_w)
	var double_w := 0.50 if power_lv < POWER_MAX else 0.18
	if power_lv >= 6:
		double_w *= 0.25
	elif power_lv >= 4:
		double_w *= 0.50
	if r < 0.06 + double_w:
		return ITEM_DOUBLE
	if _bomb_item_wanted() and r < 0.06 + double_w + 0.12:
		return ITEM_NUKE
	return ITEM_SHIELD


func _maybe_drop(e: Dictionary) -> void:
	if bool(e.get("meteor", false)):
		return
	if live_item_count() >= MAX_ITEMS:
		return
	var force := elapsed - last_item_at >= ITEM_GAP_FORCE
	if bool(e.get("is_boss", false)) or bool(e.get("boss", false)):
		item_from_boss = true
		var drop_x := lerpf(float(e["x"]), player_x, 0.28)
		_spawn_item(clampf(drop_x, 0.14, 0.86), float(e["y"]), _pick_boss_drop(int(e.get("boss_style", 0))))
		item_from_boss = false
		return
	var kind := int(e["kind"])
	if kind == KIND_GOLD:
		_spawn_item(float(e["x"]), float(e["y"]), ITEM_DOUBLE if power_lv < 3 else ITEM_SHIELD)
		return
	if kind == KIND_PURPLE:
		if not wave_special_dropped:
			wave_special_dropped = true
			_spawn_item(float(e["x"]), float(e["y"]), _pick_special_power())
			return
		if randf() < 0.40:
			_spawn_item(float(e["x"]), float(e["y"]), -1)
			return
	if force and elapsed - last_item_at >= ITEM_GAP_MIN:
		var ox := 0.12 if float(e["x"]) < 0.5 else -0.12
		var fk := ITEM_DOUBLE if power_lv < 3 else -1
		_spawn_item(clampf(float(e["x"]) + ox, 0.14, 0.86), float(e["y"]), fk)


func _spawn_item(x: float, y: float, force_kind: int = -1) -> void:
	if live_item_count() >= MAX_ITEMS:
		return
	var kind := force_kind if force_kind >= 0 else _roll_item_kind()
	if kind == ITEM_HEART and hp >= MAX_HP:
		kind = ITEM_DOUBLE if randf() < 0.55 else ITEM_SHIELD
	if kind == ITEM_NUKE and (nukes_spawned >= NUKE_MAX or bombs >= BOMB_MAX):
		kind = ITEM_SHIELD
	if kind == ITEM_LASER:
		kind = _alt_common_item(ITEM_LASER)
	if (kind == ITEM_DOUBLE or kind == ITEM_SHIELD or kind == ITEM_HEART or kind == ITEM_NUKE) and _has_live_item(kind):
		kind = _alt_common_item(kind)
	if kind == ITEM_NUKE:
		nukes_spawned += 1
	for it in items:
		if bool(it["live"]):
			continue
		it["live"] = true
		it["kind"] = kind
		it["x"] = x
		it["y"] = y
		it["from_boss"] = item_from_boss
		last_item_at = elapsed
		return


func _pick_kind_for_phase() -> int:
	var w: Array
	if wave <= 2:
		w = [72, 24, 4, 0]
	elif wave <= 5:
		w = [30, 50, 14, 6]
	else:
		w = [16, 58, 18, 8]
	var r := randi() % 100
	var acc := 0
	for i in 4:
		acc += int(w[i])
		if r < acc:
			return i
	return KIND_RED


func _acquire_enemy_slot() -> int:
	for i in enemies.size():
		if not bool(enemies[i]["live"]):
			return i
	return -1


func _evict_one_fodder_ebullet() -> void:
	for b in ebullets:
		if not bool(b["live"]):
			continue
		if bool(b.get("fat", false)) and int(b.get("hp", 1)) > 1:
			continue
		b["live"] = false
		return


func _acquire_bullet(x: float, y: float, vx: float, vy: float, fat: bool, boost: bool, homing: bool = false, dmg: int = -1) -> bool:
	for b in bullets:
		if bool(b["live"]):
			continue
		b["live"] = true
		b["x"] = x
		b["y"] = y
		b["vx"] = vx
		b["vy"] = vy
		b["fat"] = fat
		b["boost"] = boost
		b["homing"] = homing
		b["enemy"] = false
		b["dmg"] = _shot_dmg() if dmg < 0 else dmg
		return true
	return false


func _acquire_ebullet(x: float, y: float, vx: float = 0.0, vy: float = EBULLET_SPEED, fat: bool = false, extras: Dictionary = {}) -> bool:
	if live_ebullet_count() >= _ebullet_cap():
		if fat and float(extras.get("home_turn", 0.0)) > 0.0:
			_evict_one_fodder_ebullet()
		if live_ebullet_count() >= _ebullet_cap():
			return false
	for b in ebullets:
		if bool(b["live"]):
			continue
		b["live"] = true
		b["x"] = x
		b["y"] = y
		b["vx"] = vx
		b["vy"] = vy
		b["fat"] = fat
		b["homing"] = fat ## Boss 弹短时追踪；杂兵直线
		b["home_t"] = float(extras.get("home_t", EBULLET_HOME_SEC if fat else 0.0))
		b["home_turn"] = float(extras.get("home_turn", 0.0))
		b["hp"] = int(extras.get("hp", BOSS_MISSILE_HP if fat else 1))
		b["hit_cd"] = 0.0
		b["flash"] = float(extras.get("flash", 0.0))
		b["enemy"] = true
		b["grazed"] = false
		return true
	return false


func _add_display(n: int) -> int:
	var g := maxi(0, n)
	score += g
	return g


func _add_token(n: int) -> int:
	var g := maxi(0, n)
	token_score += g
	return g


func _flash(t: String) -> void:
	flash_text = t
	flash_t = 0.85


func _finish(reason: String, events: Array[Dictionary]) -> void:
	if ended:
		return
	playing = false
	ended = true
	end_reason = reason
	events.append({"type": "end", "reason": reason, "score": score})


func _nearest_threat(min_y: float) -> Dictionary:
	var best: Dictionary = {}
	var best_d := 99.0
	for e in enemies:
		if not bool(e["live"]) or int(e["hp"]) <= 0:
			continue
		var ey := float(e["y"])
		var warned := float(e.get("warn_t", 0.0)) > 0.0 or bool(e.get("diving", false))
		if ey < min_y and not warned:
			continue
		var d := absf(float(e["x"]) - player_x)
		if d < best_d:
			best_d = d
			best = e
	for b in ebullets:
		if not bool(b["live"]) or float(b["y"]) < min_y:
			continue
		var d2 := absf(float(b["x"]) - player_x)
		if d2 < best_d:
			best_d = d2
			best = b
	return best


func _nearest_target() -> Dictionary:
	var best: Dictionary = {}
	var best_y := 2.0
	for e in enemies:
		if not bool(e["live"]) or int(e["hp"]) <= 0:
			continue
		var ey := float(e["y"])
		if ey < best_y and ey < 0.78:
			best_y = ey
			best = e
	return best


func _nearest_item() -> Dictionary:
	var best: Dictionary = {}
	var best_d := 99.0
	for it in items:
		if not bool(it["live"]):
			continue
		var d := absf(float(it["x"]) - player_x)
		if d < best_d:
			best_d = d
			best = it
	return best


func _nearest_heart() -> Dictionary:
	var best: Dictionary = {}
	var best_d := 99.0
	for it in items:
		if not bool(it["live"]) or int(it["kind"]) != ITEM_HEART:
			continue
		var d := absf(float(it["x"]) - player_x)
		if d < best_d:
			best_d = d
			best = it
	return best


func _nearest_gold() -> Dictionary:
	var best: Dictionary = {}
	var best_y := 2.0
	for e in enemies:
		if not bool(e["live"]) or int(e["hp"]) <= 0:
			continue
		if int(e["kind"]) != KIND_GOLD:
			continue
		var ey := float(e["y"])
		if ey < best_y and ey < 0.82:
			best_y = ey
			best = e
	return best


func _dead_enemy() -> Dictionary:
	return {
		"live": false, "kind": 0, "hp": 0, "max_hp": 1,
		"x": 0.0, "y": -1.0, "base_x": 0.0, "vy": 0.0,
		"weave": 0.0, "freq": 1.0, "phase": 0.0, "flash": 0.0, "punch": 0.0,
		"diver": false, "warned": false, "warn_t": 0.0, "warn_x": 0.5,
		"diving": false, "aim_x": 0.5, "dying": 0.0, "shoot_cd": 0.0,
	}


func _dead_bullet() -> Dictionary:
	return {"live": false, "x": 0.0, "y": -1.0, "vx": 0.0, "vy": 0.0, "fat": false, "boost": false, "homing": false, "home_t": 0.0, "home_turn": 0.0, "enemy": false, "dmg": 1, "grazed": false, "hp": 1, "hit_cd": 0.0, "flash": 0.0}


func _dead_item() -> Dictionary:
	return {"live": false, "kind": 0, "x": 0.0, "y": -1.0, "from_boss": false}


func _dead_boss_part() -> Dictionary:
	return {
		"live": false,
		"boss_style": 0,
		"part": 0,
		"x": 0.0,
		"y": -1.0,
		"vx": 0.0,
		"vy": 0.0,
		"rot": 0.0,
		"rot_v": 0.0,
		"hit_w": BOSS_PART_HIT_W,
		"hit_h": BOSS_PART_HIT_H,
		"flash": 0.0,
	}


func _boss_part_origin(style: int, part: int) -> Vector2:
	var st := clampi(style, 0, 4)
	var p := clampi(part, 0, 2)
	if st >= 0 and st <= 4:
		return BossMuzzleLayout.part_origin_norm(st, p, play_size_px)
	const OFF := [
		[Vector2(0.07, 0.03), Vector2(-0.09, 0.01), Vector2(0.0, -0.06)],
		[Vector2(0.07, 0.02), Vector2(-0.08, 0.0), Vector2(0.0, -0.05)],
		[Vector2(0.06, 0.0), Vector2(-0.08, -0.01), Vector2(0.0, -0.05)],
		[Vector2(0.08, 0.04), Vector2(-0.10, 0.02), Vector2(0.0, -0.06)],
		[Vector2(0.10, 0.05), Vector2(-0.11, 0.02), Vector2(0.0, -0.05)],
	]
	return OFF[st][p]


func _boss_part_hit(style: int, part: int) -> Vector2:
	var p := clampi(part, 0, 2)
	var base := Vector2(BOSS_PART_HIT_W, BOSS_PART_HIT_H)
	if style == 3:
		if p == 0:
			return base * Vector2(1.45, 0.58)
		if p == 1:
			return base * Vector2(1.55, 0.66)
		return base * Vector2(1.6, 0.72)
	if style == 4:
		if p == 0:
			return base * Vector2(1.2, 0.95)
		if p == 1:
			return base * Vector2(1.35, 1.05)
		return base * Vector2(1.35, 1.05)
	if p == 0:
		return base * Vector2(1.05, 1.12)
	if p == 1:
		return base * Vector2(1.18, 0.92)
	return base * Vector2(1.22, 0.78)


func _update_boss_part_stage(e: Dictionary, events: Array[Dictionary]) -> void:
	if not bool(e.get("is_boss", false)):
		return
	var total := maxi(1, int(e.get("total_hp", int(e.get("pipe_max", 1)) * 2)))
	var lost := int(e.get("boss_hp_lost", 0))
	var remain := 1.0 - float(lost) / float(total)
	var want := 0
	if remain <= 0.25:
		want = 3
	elif remain <= 0.50:
		want = 2
	elif remain <= 0.75:
		want = 1
	var cur := int(e.get("boss_part_stage", 0))
	while cur < want:
		cur += 1
		_spawn_boss_part_drop(e, cur, events)
	e["boss_part_stage"] = cur


func _spawn_boss_part_drop(boss: Dictionary, stage: int, events: Array[Dictionary]) -> void:
	var part := clampi(stage - 1, 0, 2)
	var slot := -1
	for i in MAX_BOSS_PARTS:
		if not bool(boss_parts[i]["live"]):
			slot = i
			break
	if slot < 0:
		return
	var st := clampi(int(boss.get("boss_style", 0)), 0, 4)
	var off := _boss_part_origin(st, part)
	var bx := float(boss["x"])
	var by := float(boss["y"])
	var hit := _boss_part_hit(st, part)
	var side := -1.0 if part == 1 else (1.0 if part == 0 else 0.0)
	boss_parts[slot] = {
		"live": true,
		"boss_style": st,
		"part": part,
		"x": clampf(bx + off.x, 0.08, 0.92),
		"y": clampf(by + off.y, 0.06, 0.94),
		"vx": side * randf_range(0.04, 0.11),
		"vy": randf_range(0.20, 0.28),
		"rot": randf_range(-0.4, 0.4),
		"rot_v": randf_range(-1.6, 1.6) * (1.0 if randf() < 0.5 else -1.0),
		"hit_w": hit.x,
		"hit_h": hit.y,
		"flash": 0.35,
	}
	events.append({
		"type": "part_drop",
		"x": float(boss_parts[slot]["x"]),
		"y": float(boss_parts[slot]["y"]),
	})
	events.append({
		"type": "boom",
		"x": float(boss_parts[slot]["x"]),
		"y": float(boss_parts[slot]["y"]),
		"big": false,
		"n": 2,
		"wreck": true,
	})


func _tick_boss_parts(delta: float, events: Array[Dictionary]) -> void:
	for p in boss_parts:
		if not bool(p["live"]):
			continue
		p["x"] = clampf(float(p["x"]) + float(p["vx"]) * delta, 0.06, 0.94)
		p["y"] = float(p["y"]) + float(p["vy"]) * delta
		p["vy"] = float(p["vy"]) + 0.12 * delta
		p["rot"] = float(p.get("rot", 0.0)) + float(p.get("rot_v", 0.0)) * delta
		if float(p.get("flash", 0.0)) > 0.0:
			p["flash"] = maxf(0.0, float(p["flash"]) - delta)
		if float(p["y"]) > 1.10:
			p["live"] = false
