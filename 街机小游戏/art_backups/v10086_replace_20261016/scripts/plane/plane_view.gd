extends Node2D
class_name PlaneView
## 飞机大战表现：滚动天空 shader + additive 火花粒子池（无 CPUParticles 嵌 Control 的兼容坑）。
const PATH_SKY := "res://assets/plane/bg_sky.png"
const PATH_SKY_JPG := "res://assets/plane/bg_sky.jpg"
const PATH_SKY_TILE := "res://assets/plane/designs/bg_sky_user_crop_tile.jpg"
const PATH_SKY_LONG := "res://assets/plane/bg_sky_long.jpg"
const PATH_SKY_SHADER := "res://scripts/plane/plane_sky_scroll.gdshader"
const PATH_STARS := "res://assets/plane/bg_stars.png"
const PATH_CLOUD := "res://assets/plane/bg_cloud.png"
const PATH_PLAYER := "res://assets/plane/player_ship.png"
const PATH_PLAYER_LV: Array[String] = [
	"res://assets/plane/player_ship_1.png",
	"res://assets/plane/player_ship_2.png",
	"res://assets/plane/player_ship_3.png",
	"res://assets/plane/player_ship_4.png",
	"res://assets/plane/player_ship_5.png",
	"res://assets/plane/player_ship_6.png",
	"res://assets/plane/player_ship_7.png",
	"res://assets/plane/player_ship_8.png",
	"res://assets/plane/player_ship_9.png",
]
const PATH_ENEMY := [
	"res://assets/plane/enemy_small.png",
	"res://assets/plane/enemy_fast.png",
	"res://assets/plane/enemy_big.png",
	"res://assets/plane/enemy_gold.png",
]
const PATH_BULLET := "res://assets/plane/bullet_player.png"
const PATH_BULLET_FAT := "res://assets/plane/bullet_player_fat.png"
const PATH_BULLET_GOLD := "res://assets/plane/bullet_player_gold.png"
const PATH_MISSILE := "res://assets/plane/bullet_missile.png"
const PATH_BULLET_TRAIL := "res://assets/plane/bullet_trail.png"
const PATH_BULLET_PULSE_SHADER := "res://scripts/plane/plane_bullet_pulse.gdshader"
const SIDE_BEAT_BIN_MAX := 52
const SIDE_BEAT_CHIP_MAX := 24
## 音乐同步版侧栏条：比初版略短（原 0.16/132 → 0.10/78）
const SIDE_BEAT_INTO_FRAC := 0.10
const SIDE_BEAT_INTO_MIN := 38.0
const SIDE_BEAT_INTO_MAX := 78.0
const SIDE_BEAT_INTO_AMP := 0.82
const SIDE_BEAT_OUT_FRAC := 0.07
## 节拍频谱：false=战斗区右侧竖条，true=连击塔内框（还原见 scripts/plane/_backup_before_tower_beat_20250928/）
const SIDE_BEAT_IN_COMBO_TOWER := true
const SIDE_BEAT_SHOW_RIGHT := false
const SIDE_BEAT_SHOW_LEFT := false
const HORIZONTAL_BEAT_ENABLED := true
const HORIZONTAL_BEAT_SHADER := preload("res://scripts/plane/plane_horiz_beat_bar.gdshader")
const HORIZONTAL_BEAT_Y_FRAC := 0.705
const HORIZONTAL_BEAT_CENTER_GAP_FRAC := 0.052
const HORIZONTAL_BEAT_SIDE_MARGIN := 3.0
const HORIZONTAL_BEAT_HALF_H := 78.0
const HORIZONTAL_BEAT_OUTER_Y_DROP := 22.0
const HORIZONTAL_BEAT_INNER_Y_LIFT := 14.0
const HORIZONTAL_BEAT_ARC_CURVE := 0.82
const HORIZONTAL_BEAT_DEPTH_NEAR := 3.05
const HORIZONTAL_BEAT_DEPTH_FAR := 0.28
const HORIZONTAL_BEAT_WIDTH_NEAR := 1.08
const HORIZONTAL_BEAT_WIDTH_FAR := 0.44
const HORIZONTAL_BEAT_BINS := 156
const HORIZONTAL_BEAT_BINS_LOW := 104
const HORIZONTAL_BEAT_BAR_WIDTH_FRAC := 0.26
const HORIZONTAL_BEAT_AMP_CURVE := 1.62
const HORIZONTAL_BEAT_AMP_PEAK_MUL := 1.28
const HORIZONTAL_BEAT_AMP_MAX := 1.52
const COMBO_TOWER_BEAT_BINS := 32
const COMBO_TOWER_RAINBOW_BEAT_V2 := true
const BULLET_BEAD_MAX := 5
const PATH_MUZZLE_PLAYER := "res://assets/plane/fx_muzzle_player.png"
const PATH_POP_FONT := "res://assets/plane/fonts/SmileySans-Oblique.otf"
const PATH_RHYTHM_RING := "res://assets/plane/designs/rhythm_ring_glow.png"
const _RhythmScript := preload("res://scripts/plane/plane_rhythm.gd")
const RHYTHM_RING_PX := 200.0
const PATH_BOMB := "res://assets/plane/bomb_flash.png"
const PATH_ITEM := [
	"res://assets/plane/item_double.png",
	"res://assets/plane/item_shield.png",
	"res://assets/plane/item_laser.png",
	"res://assets/plane/item_nuke.png",
	"res://assets/plane/item_heart.png",
]
const PATH_SCORE_GEM := "res://assets/plane/score_gem.png"
const PATH_SCORE_RUBY := "res://assets/plane/score_ruby.png"
const SCORE_GEM_BURST_OUT := 0.36
const SCORE_GEM_GATHER_FROM := 0.48
const SCORE_GEM_GATHER_TO := 0.88
const SCORE_GEM_BURST_DIST_MIN := 38.0
const SCORE_GEM_BURST_DIST_MAX := 112.0
const SCORE_GEM_PX := 48.0
const SCORE_RUBY_BREAK_SIZE_MUL := 2.84
const COMBO_TOWER_SEGS := 10
## 满格 = 封神档（与 PlaneLogic.COMBO_TIER_FENGSHEN 一致）
const COMBO_TOWER_FILL_AT := float(PlaneLogic.COMBO_TIER_FENGSHEN)
const COMBO_TOWER_HEIGHT_FRAC := 0.52
const COMBO_TOWER_MIN_H := 260.0
const COMBO_TOWER_MAX_H := 420.0
const COMBO_TOWER_CENTER_Y_FRAC := 0.50
const COMBO_TOWER_FRAME_ASPECT := 241.0 / 511.0
const COMBO_TOWER_GAP := 2.0
const COMBO_TOWER_Z := 24
const COMBO_TIER_FLY_HOLD := 0.88
const COMBO_TIER_FLY_MOVE := 0.92
const COMBO_TIER_FLY_START_Y_FRAC := 0.24
const COMBO_TIER_FLY_START_H_FRAC := 0.30
const COMBO_TIER_FLY_START_H_MIN := 142.0
const COMBO_TIER_FLY_START_H_MAX := 228.0
const COMBO_TIER_PEAK_HOLD := 1.22
const COMBO_TIER_PEAK_H_FRAC := 0.36
const COMBO_TIER_PEAK_H_MIN := 168.0
const COMBO_TIER_PEAK_H_MAX := 300.0
const COMBO_TIER_PEAK_Y_FRAC := 0.46
const PATH_COMBO_TOWER := "res://assets/plane/combo_tower/"
const PATH_STAR := "res://assets/plane/fx_star.png"
const PATH_SPARK := "res://assets/plane/fx_spark.png"
const PATH_GLOW := "res://assets/plane/fx_glow.png"
const PATH_RING_FX := "res://assets/plane/fx_ring_fx.png"
const PATH_FLASH := "res://assets/plane/fx_flash.png"
const PATH_STAR8 := "res://assets/plane/fx_star8.png"
const PATH_SHADOW := "res://assets/plane/fx_shadow.png"
const PATH_SHIP_LIT := "res://scripts/plane/plane_sprite_lit.gdshader"
const FX_FLASH := 10
const FX_GLOW := 11
const FX_RING := 12
const FX_STAR := 13
const FX_BLOOM := 14
const MAX_BOOM_SPR := 24
const PATH_BOSS := [
	"res://assets/plane/boss_1.png",
	"res://assets/plane/boss_2.png",
	"res://assets/plane/boss_3.png",
	"res://assets/plane/boss_4.png",
	"res://assets/plane/boss_5.png",
]
const BOSS_STAGE_KEYS := ["full", "hp75", "hp50", "hp25"]
const BOSS_DROP_KEYS := ["launcher", "wing_l", "wing_r"]
const BOSS_PART_PX: Array[float] = [96.0, 88.0, 102.0]
const PATH_EBULLET := "res://assets/plane/bullet_enemy.png"
const PATH_EBULLET_BOSS := "res://assets/plane/bullet_boss.png"
const PATH_BOOM := [
	"res://assets/plane/fx_boom_0.png",
	"res://assets/plane/fx_boom_1.png",
	"res://assets/plane/fx_boom_2.png",
	"res://assets/plane/fx_boom_3.png",
]
const PATH_BOOM_S := [
	"res://assets/plane/fx_boom_s_0.png",
	"res://assets/plane/fx_boom_s_1.png",
	"res://assets/plane/fx_boom_s_2.png",
	"res://assets/plane/fx_boom_s_3.png",
]
const PATH_BOOM_M := [
	"res://assets/plane/fx_boom_m_0.png",
	"res://assets/plane/fx_boom_m_1.png",
	"res://assets/plane/fx_boom_m_2.png",
	"res://assets/plane/fx_boom_m_3.png",
]
const PATH_BOOM_L := [
	"res://assets/plane/fx_boom_l_0.png",
	"res://assets/plane/fx_boom_l_1.png",
	"res://assets/plane/fx_boom_l_2.png",
	"res://assets/plane/fx_boom_l_3.png",
]
const PATH_BOOM_B := [
	"res://assets/plane/fx_boom_b_0.png",
	"res://assets/plane/fx_boom_b_1.png",
	"res://assets/plane/fx_boom_b_2.png",
	"res://assets/plane/fx_boom_b_3.png",
]
const PATH_BOOM_BOSS := "res://assets/plane/fx_boom_boss.png"
const PATH_LASER_BEAM := "res://assets/plane/fx_laser_beam.png"
const PATH_LASER_BEAM_B := "res://assets/plane/fx_laser_beam_b.png"
const PATH_LASER_MUZZLE := "res://assets/plane/fx_laser_muzzle.png"
const PATH_LASER_IMPACT := "res://assets/plane/fx_laser_impact.png"
const PATH_RING := "res://assets/plane/fx_bomb_ring.png"
const BOSS_PX := [236.0, 258.0, 272.0, 298.0, 336.0]
const BOOM_OFFS := [
	Vector2(0.0, 0.0),
	Vector2(0.07, -0.055),
	Vector2(-0.08, 0.03),
	Vector2(0.055, 0.07),
	Vector2(-0.04, -0.07),
	Vector2(0.09, 0.015),
]
const BossMuzzleLayout = preload("res://scripts/plane/boss_muzzle_layout.gd")

const MUZZLE_OFFS := [
	[], ## 铁甲巡洋：见 _boss_muzzle_offs()
	[Vector2(-0.078, 0.078), Vector2(0.078, 0.078)],
	[Vector2(-0.06, 0.07), Vector2(0.0, 0.078), Vector2(0.06, 0.07)],
	[Vector2(-0.05, 0.07), Vector2(0.0, 0.078), Vector2(0.05, 0.07)],
	[Vector2(-0.11, 0.082), Vector2(0.0, 0.082), Vector2(0.11, 0.082)],
]

const COL_CABINET := Color("0C1016")
const COL_BEZEL := Color("2FE4EE")
const COL_BEZEL_GOLD := Color("E8C070")
const PLAYER_PX := 118.0
const KIND_PX := [86.0, 70.0, 156.0, 136.0]
const BULLET_PX := 17.0
const BULLET_PX_DOUBLE := 17.0
const BULLET_PX_FAT := 18.0
const BULLET_PX_GOLD := 18.0
const MISSILE_PX := 28.0
const MUZZLE_PX := 34.0
const MUZZLE_PX_DOUBLE := 52.0
const EBULLET_PX := 68.0
const EBULLET_PX_BOSS := 82.0
const EBULLET_PX_KING := 92.0
const ITEM_PX := 42.0
const RAINBOW_BEATS_CYCLE := 56.0
const MAX_FLOATS := 6
const MAX_WARNS := 4
const HUD_CAP_FONT := 24
const HUD_SCORE_FONT := 52
const HUD_PIP_PX := 22.0
const HUD_PIP_GAP := 8.0
const HUD_HEART_PX := 28.0
const HUD_HEART_GAP := 7.0
## 右上角：得分 / 生命
const HUD_TR_CAP_FS := 32
const HUD_TR_SCORE_FS := 68
const HUD_TR_COL_W := 300.0
const HUD_JACKPOT_INIT := 752982
const HUD_LOCAL_BONUS_INIT := 5284
const HUD_COIN_COUNT_MAX := 999
const HUD_COIN_DENOM := 2
const HUD_NEXT_TIP := "下一次：柚柚陪你玩"
## 左上街机栏：字号/行高（铺满红框高度）
const HUD_ARCADE_CAP_FS := 40
const HUD_ARCADE_JACKPOT_FS := 64
const HUD_ARCADE_LOCAL_FS := 58
const HUD_ARCADE_NEXT_FS := 36
const HUD_ARCADE_COIN_CAP_FS := 40
const HUD_ARCADE_COIN_FS := 50
const HUD_ARCADE_BLOCK_GAP := 36.0

var _built := false
var _play := Rect2()
var _anim := 0.0
var _shake := 0.0
var _hurt_t := 0.0
var _bomb_t := 0.0
var _blast_t := 0.0
var _pollute := 0.0
var _ring_t := 0.0
var _wave_t := 0.0
var _title_t := 0.0
var _title_name := ""
var _title_sub := ""
var _double_flash := 0.0
var _scroll_sky := 0.0
var _scroll_stars := 0.0
var _scroll_cloud := 0.0

var _cabinet: ColorRect
var _bezel: ColorRect
var _bezel_gold: ColorRect
var _frames: Array[ColorRect] = []
var _shake_root: Node2D
var _play_clip: Control
var _play_fill: ColorRect
var _low_hp_edges: Array[ColorRect] = []
var _sky_a: Sprite2D
var _sky_b: Sprite2D
var _sky_scroll: ColorRect
var _sky_mat: ShaderMaterial
var _spark_pool: Array[Sprite2D] = []
var _spark_life: PackedFloat32Array = PackedFloat32Array()
var _spark_max: PackedFloat32Array = PackedFloat32Array()
var _spark_vel: Array[Vector2] = []
var _stars_a: Sprite2D
var _stars_b: Sprite2D
var _side_stars_a: Sprite2D
var _side_stars_b: Sprite2D
var _cloud_a: Sprite2D
var _cloud_b: Sprite2D
var _player: Sprite2D
var _player_shadow: Sprite2D
var _muzzle: Sprite2D
var _shield_ring: Sprite2D
var _lock_ring: Sprite2D
var _hurt: ColorRect
var _bomb_flash: ColorRect
var _wave_label: Label
var _flash_label: Label
var _double_bar_bg: ColorRect
var _double_bar_fill: ColorRect
var _double_bar_label: Label
var _laser_bar_bg: ColorRect
var _laser_bar_fill: ColorRect
var _laser_bar_label: Label
var _energy_bar_bg: ColorRect
var _energy_bar_fill: ColorRect
var _energy_bar_label: Label
var _pickup_flash: ColorRect
var _laser_beam: Sprite2D
var _laser_muzzle_fx: Sprite2D
var _laser_impact: Sprite2D
var _super_beams: Array[Sprite2D] = []
var _super_halos: Array[Sprite2D] = []
var _super_cores: Array[Sprite2D] = []
var _super_muzzles: Array[Sprite2D] = []
var _super_impacts: Array[Sprite2D] = []
var _gold_add_mat: CanvasItemMaterial
var _fx_add_mat: CanvasItemMaterial
var _ship_lit_mat: ShaderMaterial
var _wave_title := ""
var _warning_label: Label
var _boss_title: Label
var _boss_sub: Label
var _boss_dim: ColorRect
var _announce_veil: ColorRect
var _announce_bar: ColorRect
var _announce_bar2: ColorRect
var _countdown_veil: ColorRect
var _countdown_num: Label
var _countdown_ready: Label
var _countdown_plate: TextureRect
var _countdown_howto: PlaneCountdownHowto
var _countdown_step_t := 0.0
var _sweep_beam: ColorRect
var _sweep_warn: Line2D
var _bomb_ring: Sprite2D
var _power_label: Label
var _hearts: Array[Sprite2D] = []
var _heart_slots: Array[Sprite2D] = []
var _tex_heart: Texture2D
var _heart_punch := 0.0
var _bombs: Array[Sprite2D] = []
var _bomb_slots: Array[Sprite2D] = []
var _tex_hud_bomb: Texture2D
var _bomb_hud_punch := 0.0
var _bomb_label: Label
var _score_cap: Label
var _score_val: Label
var _tex_score_gem: Texture2D
var _tex_score_ruby: Texture2D
var _gem_canvas: CanvasLayer
var _gem_layer: Control
var _gem_flies: Array[Dictionary] = []
var _score_gem_punch := 0.0
var _combo_tower_panel: PlaneComboTower
var _combo_cap: Label
var _combo_mul_root: Control
var _combo_mul_glow_root: Control
var _combo_tier_tex: TextureRect
var _combo_tier_fly_tex: TextureRect
var _combo_tier_anim_t := 1.0
var _combo_tier_anim_from_pos := Vector2.ZERO
var _combo_tier_anim_from_size := Vector2.ZERO
var _combo_tier_anim_to_pos := Vector2.ZERO
var _combo_tier_anim_to_size := Vector2.ZERO
var _combo_tier_peak_t := 0.0
var _tex_combo_mul_x: Texture2D
var _tex_combo_digits: Array[Texture2D] = []
var _tex_combo_tiers: Dictionary = {}
var _combo_display_prev := 0
var _combo_punch := 0.0
var _combo_break_t := 0.0
var _life_cap: Label
var _info_jackpot_cap: Label
var _info_jackpot_val: Label
var _info_local_cap: Label
var _info_local_val: Label
var _info_next: Label
var _info_coin_cap: Label
var _info_coin: Label
## 左上角街机信息（由 PlaneGame 写入）
var arcade_jackpot := HUD_JACKPOT_INIT
var arcade_local_bonus := HUD_LOCAL_BONUS_INIT
var arcade_coin_in := 0 ## 娃娃机实机余币（左侧 xx/02）
var arcade_coin_need := HUD_COIN_DENOM
var arcade_next_tip := HUD_NEXT_TIP
var _life_pips: Array[ColorRect] = []
var _bomb_cap: Label
var _bomb_pips: Array[ColorRect] = []
var _tex_bosses: Array[Texture2D] = []
var _tex_boss_stages: Array = [] ## Array of Array[Texture2D] per boss
var _tex_boss_drops: Array = [] ## Array of Array[Texture2D] per boss
var _boss_part_pool: Array[Sprite2D] = []
var _boss_part_was_live: Array[bool] = []
var _tex_ebullet: Texture2D
var _tex_ebullet_boss: Texture2D
var _boss_bar_bg: ColorRect
var _boss_bar_fill: ColorRect
var _boss_bar_edge: ColorRect
var _boss_bar_label: Label
var _boss_bar_punch := 0.0

var _enemy_pool: Array[Sprite2D] = []
var _enemy_shadows: Array[Sprite2D] = []
var _bullet_pool: Array[Sprite2D] = []
var _bullet_glows: Array[Sprite2D] = []
var _ebullet_pool: Array[Sprite2D] = []
var _ebullet_glow: Array[Sprite2D] = []
var _item_pool: Array[Sprite2D] = []
var _warn_lines: Array[Line2D] = []
var _bullet_trails: Array[Line2D] = []
var _bullet_streaks: Array[Sprite2D] = []
var _bullet_beads: Array[Sprite2D] = []
var _trail_grad: Gradient
var _bullet_pulse_mat: ShaderMaterial
var _beat_glow := 0.0
var _side_beat_pulse := 0.0
var _side_beat_veil_l: ColorRect
var _side_beat_veil_r: ColorRect
var _side_beat_haze_l: ColorRect
var _side_beat_haze_r: ColorRect
var _side_beat_spine_l: ColorRect
var _side_beat_spine_r: ColorRect
var _side_beat_spike_l: Array[ColorRect] = []
var _side_beat_spike_r: Array[ColorRect] = []
var _side_beat_chip_l: Array[ColorRect] = []
var _side_beat_chip_r: Array[ColorRect] = []
var _horiz_beat_l_bars: Array[ColorRect] = []
var _horiz_beat_r_bars: Array[ColorRect] = []
var _shield_flash := 0.0
var _climax_tier := 0
var _rainbow_hue := 0.0
var _stars: Array[Sprite2D] = []
var _star_life: PackedFloat32Array = PackedFloat32Array()
var _star_max: PackedFloat32Array = PackedFloat32Array()
var _star_vel: Array[Vector2] = []
var _booms: Array[Sprite2D] = []
var _boom_life: PackedFloat32Array = PackedFloat32Array()
var _boom_max: PackedFloat32Array = PackedFloat32Array()
var _boom_px: PackedFloat32Array = PackedFloat32Array()
var _boom_set: PackedByteArray = PackedByteArray()
var _boom_rot: PackedFloat32Array = PackedFloat32Array()
var _wings: Array[Sprite2D] = []
var _wing_trails: Array[Line2D] = []
var _muzzle_glows: Array[Sprite2D] = []
var _pfx_spark_t := 0.0
var _bullet_pollute_cd := 0.0
var _floats: Array[Label] = []
var _float_life: PackedFloat32Array = PackedFloat32Array()
var _float_max: PackedFloat32Array = PackedFloat32Array()
var _float_tilt: PackedFloat32Array = PackedFloat32Array()
var _font_pop: Font
var _rhythm
var _rhythm_target: Sprite2D
var _rhythm_approach: Sprite2D
var _tex_rhythm_ring: Texture2D
var _rhythm_hit_flash := 0.0
var _rhythm_center_label: Label
var _rhythm_center_life := 0.0
var _rhythm_center_max := 0.0
var _rhythm_center_y_norm := 0.48

var _tex_sky: Texture2D
var _sky_oneshot := false
var _tex_stars: Texture2D
var _tex_cloud: Texture2D
var _tex_player: Texture2D
var _tex_players: Array[Texture2D] = []
var _tex_enemies: Array[Texture2D] = []
var _tex_bullet: Texture2D
var _tex_bullet_fat: Texture2D
var _tex_bullet_gold: Texture2D
var _tex_missile: Texture2D
var _tex_trail: Texture2D
var _tex_muzzle: Texture2D
var _tex_muzzle_player: Texture2D
var _tex_bomb: Texture2D
var _tex_items: Array[Texture2D] = []
var _tex_star: Texture2D
var _tex_spark: Texture2D
var _tex_glow: Texture2D
var _tex_ring_fx: Texture2D
var _tex_flash: Texture2D
var _tex_star8: Texture2D
var _tex_shadow: Texture2D
var _tex_boom_s: Array[Texture2D] = []
var _tex_boom_m: Array[Texture2D] = []
var _tex_boom_l: Array[Texture2D] = []
var _tex_boom_b: Array[Texture2D] = []
var _tex_boom_boss: Texture2D
var _tex_laser_beam: Texture2D
var _tex_laser_beam_b: Texture2D
var _tex_laser_muzzle: Texture2D
var _tex_laser_impact: Texture2D
var _tex_gold_beam: Texture2D
var _tex_gold_beam_b: Texture2D
var _tex_gold_halo: Texture2D
var _tex_gold_core: Texture2D
var _tex_gold_muzzle: Texture2D
var _tex_gold_impact: Texture2D
var _tex_ring: Texture2D


func _ready() -> void:
	_ensure_built()


func reset() -> void:
	_ensure_built()
	_tex_sky = _load_best_sky()
	_tex_bullet = _load_or_paint(PATH_BULLET, _paint_bullet)
	_tex_bullet_fat = _load_or_paint(PATH_BULLET_FAT, _paint_bullet)
	_tex_bullet_gold = _load_or_paint(PATH_BULLET_GOLD, _paint_bullet)
	_tex_trail = _load_or_paint(PATH_BULLET_TRAIL, _paint_bullet_trail)
	_anim = 0.0
	_shake = 0.0
	_hurt_t = 0.0
	_bomb_t = 0.0
	_blast_t = 0.0
	_pollute = 0.0
	_ring_t = 0.0
	_wave_t = 0.0
	_title_t = 0.0
	_title_name = ""
	_title_sub = ""
	_double_flash = 0.0
	_shield_flash = 0.0
	_side_beat_pulse = 0.0
	_scroll_sky = 0.0
	_scroll_stars = 0.0
	_scroll_cloud = 0.0
	_pfx_spark_t = 0.0
	_bullet_pollute_cd = 0.0
	_rainbow_hue = 0.0
	_rhythm_hit_flash = 0.0
	_rhythm_center_life = 0.0
	if _rhythm_center_label:
		_rhythm_center_label.visible = false
	_combo_tier_peak_t = 0.0
	_combo_tier_anim_t = 1.0
	if _combo_tier_fly_tex:
		_combo_tier_fly_tex.visible = false
	if _rhythm:
		_rhythm.reset()
	_boss_part_was_live.clear()
	for i in _boss_part_pool.size():
		_boss_part_was_live.append(false)
	_clear_score_gems()
	_score_gem_punch = 0.0
	_combo_display_prev = 0
	_combo_punch = 0.0
	_combo_break_t = 0.0
	if _shake_root:
		_shake_root.position = Vector2.ZERO
	_player.visible = true
	if _player_shadow:
		_player_shadow.visible = true
	if _lock_ring:
		_lock_ring.visible = false
	_muzzle.visible = false
	_shield_ring.visible = false
	_hurt.visible = false
	_bomb_flash.visible = false
	if _bomb_ring:
		_bomb_ring.visible = false
	if _warning_label:
		_warning_label.visible = false
	if _boss_title:
		_boss_title.visible = false
		_boss_sub.visible = false
	if _announce_veil:
		_announce_veil.visible = false
	if _announce_bar:
		_announce_bar.visible = false
	if _announce_bar2:
		_announce_bar2.visible = false
	_hide_countdown()
	if _boss_dim:
		_boss_dim.visible = false
	if _sweep_beam:
		_sweep_beam.visible = false
	if _sweep_warn:
		_sweep_warn.visible = false
	if _laser_beam:
		_laser_beam.visible = false
	if _laser_muzzle_fx:
		_laser_muzzle_fx.visible = false
	if _laser_impact:
		_laser_impact.visible = false
	for s in _super_beams:
		s.visible = false
	for s in _super_halos:
		s.visible = false
	for s in _super_cores:
		s.visible = false
	for s in _super_muzzles:
		s.visible = false
	for s in _super_impacts:
		s.visible = false
	if _power_label:
		_power_label.visible = false
	for e in _low_hp_edges:
		e.visible = false
	_wave_label.visible = false
	_flash_label.visible = false
	_wave_title = ""
	if _double_bar_bg:
		_double_bar_bg.visible = false
		_double_bar_fill.visible = false
		_double_bar_label.visible = false
	if _laser_bar_bg:
		_laser_bar_bg.visible = false
		_laser_bar_fill.visible = false
		_laser_bar_label.visible = false
	if _energy_bar_bg:
		_energy_bar_bg.visible = false
		_energy_bar_fill.visible = false
		_energy_bar_label.visible = false
	if _pickup_flash:
		_pickup_flash.visible = false
	_heart_punch = 0.0
	_bomb_hud_punch = 0.0
	_boss_bar_punch = 0.0
	if _boss_bar_bg:
		_boss_bar_bg.visible = false
		_boss_bar_fill.visible = false
		_boss_bar_label.visible = false
		if _boss_bar_edge:
			_boss_bar_edge.visible = false
	for s in _hearts:
		s.visible = false
	for s in _heart_slots:
		s.visible = false
	for s in _bombs:
		s.visible = false
	for s in _bomb_slots:
		s.visible = false
	for p in _life_pips:
		p.visible = false
	for p in _bomb_pips:
		p.visible = false
	if _bomb_label:
		_bomb_label.visible = false
	if _score_cap:
		_score_cap.visible = false
	if _score_val:
		_score_val.visible = false
	if _life_cap:
		_life_cap.visible = false
	if _bomb_cap:
		_bomb_cap.visible = false
	if _info_jackpot_cap:
		_info_jackpot_cap.visible = false
	if _info_jackpot_val:
		_info_jackpot_val.visible = false
	if _info_local_cap:
		_info_local_cap.visible = false
	if _info_local_val:
		_info_local_val.visible = false
	if _info_next:
		_info_next.visible = false
	if _info_coin_cap:
		_info_coin_cap.visible = false
	if _info_coin:
		_info_coin.visible = false
	for p in _bomb_pips:
		p.visible = false
	for ln in _bullet_trails:
		ln.visible = false
	for s in _enemy_pool:
		s.visible = false
	for s in _enemy_shadows:
		s.visible = false
	for s in _bullet_pool:
		s.visible = false
	for s in _bullet_glows:
		s.visible = false
	for s in _bullet_beads:
		s.visible = false
	for s in _ebullet_glow:
		s.visible = false
	for s in _ebullet_pool:
		s.visible = false
	for ln in _warn_lines:
		ln.visible = false
	for s in _item_pool:
		s.visible = false
	for i in _stars.size():
		_stars[i].visible = false
		_star_life[i] = 0.0
		if i < _star_max.size():
			_star_max[i] = 0.0
	for i in _spark_pool.size():
		_spark_pool[i].visible = false
		if i < _spark_life.size():
			_spark_life[i] = 0.0
		if i < _spark_max.size():
			_spark_max[i] = 0.0
	for i in _booms.size():
		_booms[i].visible = false
		_boom_life[i] = 0.0
		if i < _boom_max.size():
			_boom_max[i] = 0.0
	for s in _wings:
		s.visible = false
	for ln in _wing_trails:
		ln.visible = false
	for s in _muzzle_glows:
		s.visible = false
	for i in _floats.size():
		_floats[i].visible = false
		_floats[i].scale = Vector2.ONE
		_float_life[i] = 0.0
		if i < _float_max.size():
			_float_max[i] = 0.0
		if i < _float_tilt.size():
			_float_tilt[i] = 0.0
		_floats[i].rotation_degrees = 0.0


func spray_muzzle(nx: float, ny: float, volley: int) -> void:
	var origin := _to_screen(nx, ny)
	var n := mini(14, 4 + volley)
	_emit_sparks(origin, n, false, false, true, Vector2(0.0, -1.0))
	_pollute = maxf(_pollute, 0.03 + float(volley) * 0.004)


func punch(px: float) -> void:
	_shake = minf(7.0, _shake + px)


func bg_clean_report() -> String:
	_ensure_built()
	var fill_ok := _play_fill != null and _play_fill.color.a >= 0.99
	var sky_ok := _tex_sky != null and not _scan_checker(_tex_sky)
	var star_ok := not _scan_checker(_tex_stars)
	var cloud_ok := not _scan_checker(_tex_cloud)
	return "fill=%s sky=%s stars_paint=%s cloud_paint=%s" % [str(fill_ok), str(sky_ok), str(star_ok), str(cloud_ok)]


func _scan_checker(tex: Texture2D) -> bool:
	if tex == null:
		return true
	var img := tex.get_image()
	if img == null:
		return false
	var w := img.get_width()
	var h := img.get_height()
	var hits := 0
	var n := 0
	var y := 0
	while y < h:
		var x := 0
		while x < w:
			n += 1
			var c := img.get_pixel(x, y)
			if c.a > 0.28 and absf(c.r - c.g) < 0.03 and absf(c.g - c.b) < 0.03 and c.r > 0.48 and c.r < 0.82:
				hits += 1
			x += 6
		y += 6
	return hits > maxi(8, n / 12)


func flash_hurt() -> void:
	_hurt_t = 0.15
	punch(3.2)


func flash_bomb() -> void:
	_bomb_t = 0.055
	_ring_t = 0.46
	_bomb_hud_punch = 0.28
	punch(5.6)


func flash_bomb_stock() -> void:
	_bomb_hud_punch = 0.32
	punch(2.2)


func flash_double() -> void:
	_double_flash = 0.28
	punch(4.8)


func flash_laser() -> void:
	_double_flash = 0.20
	punch(4.0)


func flash_heal() -> void:
	_heart_punch = 0.28
	punch(2.4)


func flash_shield() -> void:
	_shield_flash = 0.34
	_side_beat_pulse = maxf(_side_beat_pulse, 0.72)
	punch(3.4)


func show_wave(n: int, title: String = "") -> void:
	_wave_title = title
	_wave_label.text = "WAVE %d" % n if title == "" else "WAVE %d  %s" % [n, title]
	_wave_label.visible = true
	_wave_t = 1.35


func show_pickup(text: String) -> void:
	_flash_label.text = text
	_flash_label.visible = true
	_flash_label.modulate = Color(1, 0.92, 0.55, 1)
	_flash_label.add_theme_font_size_override("font_size", 34)


func show_warning() -> void:
	if _warning_label:
		_warning_label.visible = true
	punch(4.8)


func show_boss_title(nm: String, sub: String) -> void:
	_title_name = nm
	_title_sub = sub
	_title_t = 1.20
	if _boss_title:
		_boss_title.text = nm
		_boss_title.visible = true
	if _boss_sub:
		_boss_sub.text = sub
		_boss_sub.visible = true
	punch(3.6)


func show_countdown(step_text: String) -> void:
	_ensure_built()
	_countdown_step_t = 0.0
	if _countdown_veil:
		_countdown_veil.visible = false
	if _countdown_num:
		_countdown_num.visible = false
	if _countdown_plate:
		_countdown_plate.visible = false
	if _countdown_ready:
		_countdown_ready.visible = false
	if _countdown_howto:
		_countdown_howto.visible = true
		_countdown_howto.modulate.a = 1.0
		if _countdown_howto.has_method("set_step"):
			_countdown_howto.set_step(step_text)
	_layout_countdown(0.78)
	punch(2.8 if step_text == "START" else 1.6)


func hide_countdown() -> void:
	_hide_countdown()


func _hide_countdown() -> void:
	if _countdown_veil:
		_countdown_veil.visible = false
	if _countdown_num:
		_countdown_num.visible = false
		_countdown_num.scale = Vector2.ONE
	if _countdown_plate:
		_countdown_plate.visible = false
	if _countdown_ready:
		_countdown_ready.visible = false
	if _countdown_howto:
		_countdown_howto.visible = false


func tick_countdown(delta: float) -> void:
	if _countdown_howto == null or not _countdown_howto.visible:
		return
	_countdown_step_t += delta
	var k := clampf(_countdown_step_t / 0.20, 0.0, 1.0)
	var sc := lerpf(0.88, 1.04, k)
	_layout_countdown(sc)


func _layout_countdown(_num_scale: float = 1.0) -> void:
	if _play == null or _countdown_howto == null:
		return
	var pw := _play.size.x
	var ph := _play.size.y
	var ox := _play.position.x
	var oy := _play.position.y
	if _countdown_veil:
		_countdown_veil.position = Vector2(ox, oy)
		_countdown_veil.size = Vector2(pw, ph)
		_countdown_veil.z_index = 48
		_countdown_veil.color = Color(0, 0, 0, 0)
	if _countdown_num:
		_countdown_num.visible = false
	if _countdown_plate:
		_countdown_plate.visible = false
	if _countdown_ready:
		_countdown_ready.visible = false
	_countdown_howto.position = Vector2(ox, oy)
	_countdown_howto.size = Vector2(pw, ph)
	_countdown_howto.z_index = 50


func spawn_booms(nx: float, ny: float, n: int, big: bool, kind: int = -1) -> void:
	var tier := _boom_tier(n, big, kind)
	var gold := kind == 3
	var px := 128.0
	match tier:
		1:
			px = 156.0
		2:
			px = 198.0
		3:
			px = 248.0
		_:
			px = 132.0
	## 分层爆炸，但不铺全屏；敌弹 z 更高，光晕在底层
	_alloc_fx(nx, ny, FX_BLOOM, 0.26 + float(tier) * 0.05, px * 1.42, Color(1.55, 1.18, 0.42, 1) if not gold else Color(1.65, 1.35, 0.35, 1), 0.0)
	_alloc_fx(nx, ny, FX_GLOW, 0.38 + float(tier) * 0.05, px, Color(1.55, 1.05, 0.32, 1) if not gold else Color(1.6, 1.25, 0.28, 1), randf_range(-0.2, 0.2))
	_alloc_fx(nx, ny, FX_RING, 0.34 + float(tier) * 0.04, px * 1.08, Color(1.5, 0.32, 0.10, 1), randf_range(-0.4, 0.4))
	_alloc_fx(nx, ny, FX_FLASH, 0.11 if tier < 3 else 0.14, px * 0.78, Color(1.6, 1.48, 1.18, 1), 0.0)
	if tier >= 2:
		_alloc_fx(nx, ny, FX_STAR, 0.22, px * 0.92, Color(1.45, 1.15, 0.40, 1), randf() * TAU)
	var spark_n := 6 if tier <= 1 else (8 if tier == 2 else 10)
	burst_stars(nx, ny, spark_n, Color(1.45, 1.02, 0.28, 1))
	_emit_sparks(_to_screen(nx, ny), 18 + tier * 6, true, gold)
	_blast_t = maxf(_blast_t, 0.05 if tier >= 2 else 0.028)
	_pollute = maxf(_pollute, 0.12 + float(tier) * 0.07)
	punch(0.7 + float(tier) * 0.45)


func _alloc_fx(nx: float, ny: float, kind: int, life: float, px: float, col: Color, rot: float) -> void:
	var slot := _free_boom()
	if slot < 0:
		return
	_boom_life[slot] = life
	_boom_max[slot] = life
	_boom_px[slot] = px
	_boom_set[slot] = kind
	_boom_rot[slot] = rot
	_booms[slot].position = _to_screen(nx, ny)
	_booms[slot].rotation = rot
	_booms[slot].texture = _fx_tex(kind)
	_booms[slot].material = _fx_add_material()
	_booms[slot].modulate = col
	_fit_px(_booms[slot], px * 0.48)
	_booms[slot].visible = true
	var z := 5
	match kind:
		FX_FLASH:
			z = 6
		FX_STAR:
			z = 6
		FX_BLOOM:
			z = 4
		_:
			z = 5
	_booms[slot].z_index = z


func _boom_tier(n: int, big: bool, kind: int) -> int:
	if big and n >= 4:
		return 3
	if kind == 2 or kind == 3 or n >= 3:
		return 2
	if kind == 1:
		return 1
	if big and n <= 1:
		return 2
	return 0


func float_text(text: String, nx: float, ny: float, color: Color) -> void:
	for i in _floats.size():
		if _float_life[i] > 0.0:
			continue
		var huge := text == "连击" or text == "破管" or text == "击破" or text.begins_with("霸王") or text.begins_with("火力")
		_float_life[i] = 1.05 if huge else 0.92
		_float_max[i] = _float_life[i]
		_floats[i].text = text
		_floats[i].modulate = color
		_apply_pop_font(_floats[i])
		_floats[i].add_theme_font_size_override("font_size", 50 if huge else 38)
		_floats[i].size = Vector2(280.0, 64.0)
		_floats[i].pivot_offset = Vector2(140.0, 32.0)
		_floats[i].scale = Vector2(0.38, 0.38)
		var tilt := randf_range(-18.0, 14.0)
		if i < _float_tilt.size():
			_float_tilt[i] = tilt
		_floats[i].rotation_degrees = tilt
		_floats[i].position = _to_world(nx, ny) + Vector2(-140.0 + randf_range(-10.0, 10.0), -40.0)
		_floats[i].visible = true
		_floats[i].z_index = 24
		return


func show_combo_tier_peak_center(tier: String = "fengshen") -> void:
	## 封神等峰值：屏幕中央大字图（即时结算清零连击后仍要播完）
	if _combo_tower_panel == null:
		_build_combo_tower()
	_load_combo_hud_textures()
	var tk := tier if tier != "" else "fengshen"
	if not _tex_combo_tiers.has(tk) or _play == null:
		float_text_play_center("封神", Color("FFD700"), 76, COMBO_TIER_PEAK_Y_FRAC)
		punch(5.2)
		return
	var tt: Texture2D = _tex_combo_tiers[tk]
	var pr := Rect2(_play.position, _play.size)
	var th := clampf(pr.size.y * COMBO_TIER_PEAK_H_FRAC, COMBO_TIER_PEAK_H_MIN, COMBO_TIER_PEAK_H_MAX)
	var tw := th
	if tt.get_height() > 0:
		tw = th * float(tt.get_width()) / float(tt.get_height())
	var pos := Vector2(
		pr.position.x + pr.size.x * 0.5 - tw * 0.5,
		pr.position.y + pr.size.y * COMBO_TIER_PEAK_Y_FRAC - th * 0.5
	)
	_combo_tier_anim_from_pos = pos
	_combo_tier_anim_from_size = Vector2(tw, th)
	_combo_tier_anim_to_pos = pos
	_combo_tier_anim_to_size = Vector2(tw * 0.94, th * 0.94)
	if _combo_tier_fly_tex == null:
		return
	_combo_tier_fly_tex.texture = tt
	_combo_tier_fly_tex.position = pos
	_combo_tier_fly_tex.size = Vector2(tw, th)
	_combo_tier_fly_tex.scale = Vector2.ONE
	_combo_tier_fly_tex.modulate = Color(1, 1, 1, 1)
	_combo_tier_fly_tex.visible = true
	_combo_tier_anim_t = 0.0
	_combo_tier_peak_t = COMBO_TIER_PEAK_HOLD + COMBO_TIER_FLY_MOVE
	_combo_punch = maxf(_combo_punch, 0.72)
	punch(5.4)


func float_text_play_center(text: String, color: Color, font_px: int = 52, y_norm: float = 0.48) -> void:
	if _rhythm_center_label == null:
		return
	_rhythm_center_y_norm = y_norm
	_rhythm_center_life = 0.95
	_rhythm_center_max = _rhythm_center_life
	_rhythm_center_label.text = text
	_rhythm_center_label.modulate = color
	_apply_pop_font(_rhythm_center_label)
	_rhythm_center_label.add_theme_font_size_override("font_size", font_px)
	_layout_rhythm_center_label()
	_rhythm_center_label.scale = Vector2(0.42, 0.42)
	_rhythm_center_label.rotation_degrees = 0.0
	_rhythm_center_label.visible = true


func _layout_rhythm_center_label() -> void:
	if _rhythm_center_label == null or _play == null:
		return
	var cx := _play.position.x + _play.size.x * 0.5
	var cy := _play.position.y + _play.size.y * _rhythm_center_y_norm
	_rhythm_center_label.size = Vector2(360.0, 80.0)
	_rhythm_center_label.pivot_offset = Vector2(180.0, 40.0)
	_rhythm_center_label.position = Vector2(cx - 180.0, cy - 40.0)


func burst_stars(nx: float, ny: float, n: int, tint: Color = Color(1, 0.86, 0.58, 1)) -> void:
	var origin := _to_screen(nx, ny)
	var spark: Texture2D = _tex_spark if _tex_spark else _tex_star
	var add := _fx_add_material()
	var left := mini(n, PlaneLogic.MAX_FX)
	for k in left:
		var slot := _free_star()
		if slot < 0:
			return
		var life := randf_range(0.40, 0.68)
		_star_life[slot] = life
		if slot < _star_max.size():
			_star_max[slot] = life
		var ang := (TAU * float(k) / float(maxi(1, left))) + randf_range(-0.42, 0.42)
		var spd := randf_range(64.0, 170.0)
		_star_vel[slot] = Vector2(cos(ang), sin(ang)) * spd
		_stars[slot].texture = spark
		_stars[slot].material = add
		_stars[slot].position = origin
		_stars[slot].modulate = tint
		_stars[slot].rotation = ang
		_stars[slot].z_index = 5
		_fit_px(_stars[slot], randf_range(14.0, 26.0))
		_stars[slot].visible = true


func sync(logic: PlaneLogic, delta: float) -> void:
	_ensure_built()
	_layout()
	if _play != null and _play.size.x > 1.0:
		logic.play_size_px = _play.size
	_anim += delta
	if logic.playing:
		ArcadeAudio.plane_tick_reactive(delta)
	_beat_glow = ArcadeAudio.plane_beat_energy()
	_climax_tier = ArcadeAudio.plane_climax_tier()
	_tick_rainbow_hue(logic, delta)
	if _bullet_pulse_mat:
		_bullet_pulse_mat.set_shader_parameter("beat", _beat_glow)
		_bullet_pulse_mat.set_shader_parameter("climax", float(_climax_tier))
	var beat_hit: Dictionary = ArcadeAudio.plane_beat_fired()
	if logic.playing and bool(beat_hit.get("hit", false)):
		_birth_beat_particles(logic, bool(beat_hit.get("bar", false)), int(beat_hit.get("climax", _climax_tier)))
		_side_beat_pulse = 1.0
		_rainbow_hue = fmod(_rainbow_hue + (0.05 if bool(beat_hit.get("bar", false)) else 0.028), 1.0)
	if logic.playing:
		var beat_ph := ArcadeAudio.plane_music_beat_phase()
		_side_beat_pulse = maxf(
			_side_beat_pulse,
			(1.0 - beat_ph) * clampf(_beat_glow / 1.55, 0.0, 1.0) * 0.42
		)
		if logic.muzzle_t > 0.0:
			_side_beat_pulse = maxf(_side_beat_pulse, 0.38 + clampf(_beat_glow / 1.75, 0.0, 1.0) * 0.28)
		_side_beat_pulse = maxf(0.0, _side_beat_pulse - delta * 6.4)
	else:
		_side_beat_pulse = 0.0
	if HORIZONTAL_BEAT_ENABLED:
		_sync_horizontal_beat_bars(logic)
	else:
		_sync_side_beat_bars(logic)
	var bossing := logic.boss_phase >= 2
	_scroll_sky -= 42.0 * delta
	_update_sky_shader(bossing)
	if _stars_a:
		_stars_a.visible = false
		_stars_b.visible = false
	if _cloud_a:
		_cloud_a.visible = false
		_cloud_b.visible = false
	if _side_stars_a:
		_side_stars_a.visible = false
		_side_stars_b.visible = false
	if _boss_dim:
		_boss_dim.visible = bossing and logic.playing
		_boss_dim.color = Color(0.02, 0.02, 0.06, 0.22 if bossing else 0.0)

	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 14.0)
		_shake_root.position = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
	else:
		_shake_root.position = Vector2.ZERO

	var ppos := _to_screen(logic.player_x, logic.player_y)
	var boosted := logic.power_lv >= 1
	var pulse := 1.0 + (0.05 * sin(_anim * 14.0) if boosted else 0.03 * sin(_anim * 8.0))
	var y_sc := 1.0 - clampf(logic.player_vy, -1.0, 1.0) * 0.06
	_player.texture = _player_tex_for(logic.power_lv)
	_fit_py(_player, PLAYER_PX * pulse)
	_player.scale.y *= y_sc
	_player.position = ppos
	_player.rotation_degrees = clampf(logic.player_vx * 12.0, -14.0, 14.0)
	var blink := logic.invuln > 0.0 and fmod(logic.invuln, 0.12) < 0.06
	_player.visible = not blink
	if logic.super_t > 0.0:
		_player.modulate = Color(1.28, 1.12, 0.78, 1)
	else:
		_player.modulate = Color.WHITE
	if _player_shadow:
		_player_shadow.visible = _player.visible
		_player_shadow.position = ppos + Vector2(0, 14)
		_player_shadow.scale = Vector2(1.15, 0.7)
	_muzzle.visible = logic.muzzle_t > 0.0 and logic.laser_t <= 0.0 and logic.super_t <= 0.0
	_muzzle.material = _fx_add_material()
	_muzzle.texture = _tex_flash if _tex_flash else (_tex_muzzle_player if _tex_muzzle_player else (_tex_muzzle if _tex_muzzle else _tex_bullet))
	_muzzle.position = _to_screen(logic.player_x, logic.player_y - 0.062)
	var mz_flick: float = 0.88 + 0.22 * absf(sin(_anim * 48.0))
	_fit_px(_muzzle, (MUZZLE_PX_DOUBLE if boosted else MUZZLE_PX) * mz_flick)
	if logic.power_lv >= 2:
		_muzzle.modulate = Color(1.45, 1.12, 0.52, 0.85 + _beat_glow * 0.35)
	else:
		_muzzle.modulate = Color(0.92, 1.28, 1.52, 0.82 + _beat_glow * 0.38)
	_sync_laser(logic)
	_sync_wings(logic)
	_sync_muzzles(logic)
	_sync_sweep(logic)
	var ring_on := _hurt_t > 0.0 or _bomb_t > 0.0
	_lock_ring.visible = ring_on
	if ring_on:
		_lock_ring.position = ppos
		_lock_ring.rotation = _anim * 1.2
		_fit_px(_lock_ring, 108.0)
		_lock_ring.modulate = Color(1, 1, 1, 0.55 if _hurt_t > 0.0 else 0.70)
	var shield_on := logic.shield or logic.show_shield_t > 0.0
	_shield_ring.visible = shield_on
	_shield_ring.position = ppos
	if shield_on:
		var sp := 1.0 + 0.07 * sin(_anim * 7.5) + clampf(logic.show_shield_t / 0.85, 0.0, 1.0) * 0.14
		_fit_px(_shield_ring, (162.0 + 14.0 * sin(_anim * 5.5)) * sp)
		var sa := 0.92 if logic.shield else clampf(logic.show_shield_t / 0.85, 0.0, 1.0) * 0.78
		_shield_ring.modulate = Color(0.42, 1.05, 1.25, sa)

	_sync_pool(_enemy_pool, logic.enemies, true)
	_sync_boss_parts(logic)
	_sync_pool(_bullet_pool, logic.bullets, false)
	_tick_bullet_trail_pollute(logic, delta)
	_sync_double_hud(logic)
	_sync_ebullets(logic)
	_sync_warns(logic)
	_sync_items(logic)
	_sync_corner_hud(logic, delta)
	_sync_combo_tower(logic, delta)
	_sync_rhythm_center(logic, delta)
	_sync_boss_bar(logic, delta)
	_sync_warning(logic)
	_sync_boss_title(delta)
	_layout_announce_fx(logic)

	if _hurt_t > 0.0:
		_hurt_t -= delta
		_hurt.visible = true
		_hurt.color = Color(0.92, 0.18, 0.22, 0.28 * clampf(_hurt_t / 0.15, 0.0, 1.0))
	else:
		_hurt.visible = false

	if _blast_t > 0.0:
		_blast_t -= delta
	if _pollute > 0.0:
		_pollute = maxf(0.0, _pollute - delta * 2.2)
	if _bomb_t > 0.0:
		_bomb_t -= delta
		_bomb_flash.visible = true
		_bomb_flash.material = null
		_bomb_flash.color = Color(1, 1, 1, 0.88 * clampf(_bomb_t / 0.055, 0.0, 1.0))
	elif _blast_t > 0.0:
		_bomb_flash.visible = true
		_bomb_flash.material = null
		_bomb_flash.color = Color(1.0, 0.94, 0.78, 0.14 * clampf(_blast_t / 0.05, 0.0, 1.0))
	elif _pollute > 0.0:
		_bomb_flash.visible = true
		_bomb_flash.material = null
		var pk := clampf(_pollute / 0.22, 0.0, 1.0)
		if ArcadeProfile.plane_low_fx():
			var hc := Color.from_hsv(_rainbow_hue, 0.62, 1.0)
			var aa := 0.045 + pk * 0.11 + clampf(_beat_glow / 1.6, 0.0, 1.0) * 0.055
			_bomb_flash.color = Color(hc.r, hc.g, hc.b, aa)
		else:
			_bomb_flash.color = Color(1.0, 0.92, 0.72, 0.055 * pk)
	else:
		_bomb_flash.visible = false
	if _ring_t > 0.0:
		_ring_t -= delta
		if _bomb_ring:
			var k := 1.0 - clampf(_ring_t / 0.46, 0.0, 1.0)
			_bomb_ring.visible = true
			_bomb_ring.centered = true
			_bomb_ring.position = Vector2(_play.size.x * 0.5, _play.size.y * 0.52)
			_bomb_ring.scale = Vector2.ONE * lerpf(0.55, 2.15, k)
			_bomb_ring.modulate = Color(1.0, 0.95, 0.75, 0.85 * (1.0 - k))
	elif _bomb_ring:
		_bomb_ring.visible = false

	if _double_flash > 0.0:
		_double_flash -= delta
		if _pickup_flash:
			_pickup_flash.visible = true
			_pickup_flash.color = Color(1.0, 0.92, 0.45, 0.38 * clampf(_double_flash / 0.28, 0.0, 1.0))
	elif _pickup_flash:
		_pickup_flash.visible = false

	if _shield_flash > 0.0:
		_shield_flash = maxf(0.0, _shield_flash - delta)
		if _pickup_flash and _double_flash <= 0.0:
			_pickup_flash.visible = true
			_pickup_flash.color = Color(0.32, 0.98, 1.08, 0.40 * clampf(_shield_flash / 0.34, 0.0, 1.0))

	var low := logic.hp == 1 and logic.playing
	var a := 0.08 + 0.06 * (0.5 + 0.5 * sin(_anim * 7.0))
	for e in _low_hp_edges:
		e.visible = low
		e.color = Color(0.95, 0.22, 0.26, a)

	if _wave_t > 0.0:
		_wave_t -= delta
		_wave_label.text = "WAVE %d" % logic.wave if _wave_title == "" else "WAVE %d  %s" % [logic.wave, _wave_title]
		_wave_label.visible = true
		_wave_label.add_theme_font_size_override("font_size", 40)
		_wave_label.modulate.a = clampf(_wave_t, 0.0, 1.0)
		var wk := 1.0 - clampf(_wave_t / 1.35, 0.0, 1.0)
		_wave_label.scale = Vector2.ONE * _pop_scale(wk)
		_wave_label.size = Vector2(420.0, 48.0)
		_wave_label.pivot_offset = Vector2(210.0, 24.0)
		_wave_label.rotation_degrees = -5.0
		_wave_label.position = Vector2(_play.position.x + _play.size.x * 0.5 - 210.0, _play.position.y + 18.0)
	else:
		_wave_label.visible = false
		_wave_label.scale = Vector2.ONE
		_wave_label.rotation_degrees = 0.0

	if logic.flash_t > 0.0 and logic.flash_text != "":
		var big := logic.flash_text == "WARNING" or logic.flash_text.begins_with("火力") or logic.flash_text == "护盾" or logic.flash_text == "没有目标" or logic.flash_text == "击破" or logic.flash_text == "破管" or logic.flash_text == "霸王击破" or logic.flash_text == "超级武器"
		_flash_label.add_theme_font_size_override("font_size", 52 if big else 36)
		_flash_label.text = logic.flash_text
		_flash_label.visible = logic.warning_t <= 0.0
		_flash_label.modulate = Color(1, 0.92, 0.55, clampf(logic.flash_t, 0.0, 1.0))
		var fk := 1.0 - clampf(logic.flash_t / 0.85, 0.0, 1.0)
		_flash_label.scale = Vector2.ONE * _pop_scale(fk)
		_flash_label.size = Vector2(420.0, 64.0)
		_flash_label.pivot_offset = Vector2(210.0, 32.0)
		_flash_label.rotation_degrees = -7.0 if big else -4.0
		_flash_label.position = Vector2(_play.position.x + _play.size.x * 0.5 - 210.0, _play.position.y + 52.0)
	else:
		_flash_label.visible = false
		_flash_label.scale = Vector2.ONE
		_flash_label.rotation_degrees = 0.0

	_tick_stars(delta)
	_tick_sparks(delta)
	_tick_booms(delta)
	_tick_floats(delta)
	_tick_score_gems(delta)
	_tick_rhythm_center_label(delta)


func combo_tower_world_center() -> Vector2:
	if _combo_tower_panel != null and _play != null:
		return _combo_tower_panel.position + _combo_tower_panel.size * 0.5
	return _score_gem_target()


func play_norm_from_world(world: Vector2) -> Vector2:
	if _play == null or _play.size.x < 1.0 or _play.size.y < 1.0:
		return Vector2(0.82, 0.48)
	return Vector2(
		clampf((world.x - _play.position.x) / _play.size.x, 0.0, 1.0),
		clampf((world.y - _play.position.y) / _play.size.y, 0.0, 1.0)
	)


func spawn_score_gems_world(
	count: int,
	world: Vector2,
	burst_mul: float = 1.0,
	gem_stagger_sec: float = 0.024,
	gem_size_mul: float = SCORE_RUBY_BREAK_SIZE_MUL
) -> void:
	if _play == null or _play.size.x < 1.0 or _play.size.y < 1.0:
		spawn_score_gems(
			count, 0.82, 0.48, burst_mul, Vector2.INF, true, gem_stagger_sec, gem_size_mul
		)
		return
	var nx := clampf((world.x - _play.position.x) / _play.size.x, 0.0, 1.0)
	var ny := clampf((world.y - _play.position.y) / _play.size.y, 0.0, 1.0)
	spawn_score_gems(count, nx, ny, burst_mul, world, true, gem_stagger_sec, gem_size_mul)


func spawn_score_gems(
	count: int,
	nx: float,
	ny: float,
	burst_mul: float = 1.0,
	start_override: Vector2 = Vector2.INF,
	use_ruby: bool = false,
	gem_stagger_sec: float = 0.024,
	gem_size_mul: float = 1.0
) -> void:
	if count <= 0 or _play == null:
		return
	_ensure_score_gem_tex()
	var tex := _tex_score_ruby if use_ruby else _tex_score_gem
	if tex == null:
		tex = _tex_score_gem if use_ruby else _tex_score_ruby
	if tex == null or _gem_layer == null:
		return
	var start := start_override if start_override != Vector2.INF else _to_world(nx, ny)
	var n := maxi(1, count)
	var bmul := maxf(burst_mul, 0.5)
	for i in n:
		var rect := _mk_score_gem_rect(use_ruby)
		_gem_layer.add_child(rect)
		var ang := TAU * float(i) / float(n) + sin(float(i) * 2.31 + nx * 11.0) * 0.45
		var dist := lerpf(
			SCORE_GEM_BURST_DIST_MIN * bmul,
			SCORE_GEM_BURST_DIST_MAX * bmul,
			0.5 + 0.5 * sin(float(i) * 1.63 + ny * 7.0)
		)
		var fly_size_mul := gem_size_mul if use_ruby else 1.0
		_gem_flies.append({
			"node": rect,
			"t": 0.0,
			"delay": float(i) * gem_stagger_sec,
			"burst_off": Vector2(cos(ang), sin(ang)) * dist,
			"start": start,
			"spin": randf_range(-1.4, 1.4),
			"gem_size_mul": fly_size_mul,
		})


func _ensure_score_gem_tex() -> void:
	if _tex_score_gem == null and ResourceLoader.exists(PATH_SCORE_GEM):
		_tex_score_gem = load(PATH_SCORE_GEM) as Texture2D
	if _tex_score_ruby == null and ResourceLoader.exists(PATH_SCORE_RUBY):
		_tex_score_ruby = load(PATH_SCORE_RUBY) as Texture2D


## SCORE_GEM_PX = 宝石显示宽度（1280×720 画布像素，与道具 ITEM_PX 同规则）
func _mk_score_gem_rect(use_ruby: bool = false) -> TextureRect:
	var rect := TextureRect.new()
	var tex := _tex_score_ruby if use_ruby else _tex_score_gem
	if tex == null:
		tex = _tex_score_gem if use_ruby else _tex_score_ruby
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.visible = false
	return rect


func _score_gem_size(mul: float = 1.0, tex: Texture2D = null) -> Vector2:
	_ensure_score_gem_tex()
	var t := tex
	if t == null:
		t = _tex_score_gem
	if t == null:
		return Vector2(SCORE_GEM_PX, SCORE_GEM_PX)
	var tw := float(t.get_width())
	var th := float(t.get_height())
	if tw < 1.0 or th < 1.0:
		return Vector2(SCORE_GEM_PX, SCORE_GEM_PX)
	var w := SCORE_GEM_PX * maxf(mul, 0.05)
	var h := w * th / tw
	return Vector2(w, h)


func _place_score_gem_rect(rect: TextureRect, center: Vector2, mul: float = 1.0) -> void:
	if rect == null:
		return
	var sz := _score_gem_size(mul, rect.texture)
	rect.custom_minimum_size = sz
	rect.size = sz
	rect.pivot_offset = sz * 0.5
	rect.position = center - sz * 0.5


func _score_gem_target() -> Vector2:
	if _score_val != null and _score_val.visible:
		return _score_val.position + Vector2(_score_val.size.x * 0.84, _score_val.size.y * 0.48)
	if _play != null:
		return _play.position + Vector2(_play.size.x - 36.0, 42.0)
	return Vector2(1180.0, 48.0)


func _tick_score_gems(delta: float) -> void:
	if _gem_flies.is_empty():
		if _score_gem_punch > 0.0:
			_score_gem_punch = maxf(0.0, _score_gem_punch - delta * 3.8)
		return
	var end := _score_gem_target()
	var done: Array[int] = []
	for fi in _gem_flies.size():
		var fly: Dictionary = _gem_flies[fi]
		var rect: TextureRect = fly.get("node") as TextureRect
		if rect == null or not is_instance_valid(rect):
			done.append(fi)
			continue
		fly["t"] = float(fly["t"]) + delta
		var t := float(fly["t"]) - float(fly["delay"])
		if t < 0.0 or t > SCORE_GEM_GATHER_TO + 0.06:
			rect.visible = false
			if t > SCORE_GEM_GATHER_TO:
				rect.queue_free()
				done.append(fi)
			continue
		var start: Vector2 = fly["start"]
		var burst_pt: Vector2 = start + fly["burst_off"]
		var pos := start
		var size_mul := 1.0
		var alpha := 1.0
		if t < SCORE_GEM_BURST_OUT:
			var u := _gem_smooth01(t / SCORE_GEM_BURST_OUT)
			u = 1.0 - pow(1.0 - u, 2.2)
			pos = start.lerp(burst_pt, u)
			size_mul = lerpf(0.55, 1.0, u)
			alpha = clampf(0.2 + u, 0.0, 1.0)
		elif t < SCORE_GEM_GATHER_FROM:
			pos = burst_pt
			var h := (t - SCORE_GEM_BURST_OUT) / maxf(SCORE_GEM_GATHER_FROM - SCORE_GEM_BURST_OUT, 0.001)
			size_mul = 1.0 + sin(h * PI * 2.2 + float(fly["spin"])) * 0.05
		else:
			var u := _gem_smooth01(
				(t - SCORE_GEM_GATHER_FROM)
				/ maxf(SCORE_GEM_GATHER_TO - SCORE_GEM_GATHER_FROM, 0.001)
			)
			u = pow(u, 1.06)
			var mid := burst_pt.lerp(end, 0.35) + Vector2(-70.0, 48.0)
			pos = _gem_bezier2(burst_pt, mid, end, u)
			size_mul = lerpf(1.0, 0.72, u)
			alpha = lerpf(1.0, 0.25, clampf(u * 0.92, 0.0, 1.0))
			if u > 0.9:
				alpha = lerpf(alpha, 0.0, (u - 0.9) / 0.1)
				if u >= 0.98:
					_score_gem_punch = maxf(_score_gem_punch, 0.24)
		rect.visible = alpha > 0.03
		var base_mul := float(fly.get("gem_size_mul", 1.0))
		_place_score_gem_rect(rect, pos, size_mul * base_mul)
		rect.rotation = float(fly["spin"]) + sin(t * 8.5) * 0.08
		rect.modulate = Color(1.0, 1.0, 1.0, alpha)
		_gem_flies[fi] = fly
	for i in range(done.size() - 1, -1, -1):
		_gem_flies.remove_at(done[i])
	if _score_gem_punch > 0.0:
		_score_gem_punch = maxf(0.0, _score_gem_punch - delta * 3.8)


func _clear_score_gems() -> void:
	for fly in _gem_flies:
		var rect: TextureRect = fly.get("node") as TextureRect
		if rect and is_instance_valid(rect):
			rect.queue_free()
	_gem_flies.clear()


func _gem_smooth01(x: float) -> float:
	var u := clampf(x, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)


func _gem_bezier2(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u * u * a + 2.0 * u * t * b + t * t * c


func _tick_rhythm_center_label(delta: float) -> void:
	if _rhythm_center_label == null or _rhythm_center_life <= 0.0:
		if _rhythm_center_label:
			_rhythm_center_label.visible = false
		return
	_rhythm_center_life -= delta
	var mx := _rhythm_center_max if _rhythm_center_max > 0.001 else 0.95
	var k := 1.0 - clampf(_rhythm_center_life / mx, 0.0, 1.0)
	_rhythm_center_label.scale = Vector2.ONE * _pop_scale(k)
	_layout_rhythm_center_label()
	_rhythm_center_label.modulate.a = clampf(_rhythm_center_life * 1.35, 0.0, 1.0)
	_rhythm_center_label.visible = _rhythm_center_life > 0.0


func _boss_stage_tex(style: int, stage: int) -> Texture2D:
	var stg := clampi(stage, 0, 3)
	if stg <= 0:
		return null
	if style < 0 or style >= _tex_boss_stages.size():
		return null
	var row: Array = _tex_boss_stages[style]
	if stg >= row.size():
		return null
	return row[stg] as Texture2D


func _sync_boss_parts(logic: PlaneLogic) -> void:
	while _boss_part_was_live.size() < _boss_part_pool.size():
		_boss_part_was_live.append(false)
	for i in _boss_part_pool.size():
		var spr := _boss_part_pool[i]
		if i >= logic.boss_parts.size() or not bool(logic.boss_parts[i]["live"]):
			spr.visible = false
			_boss_part_was_live[i] = false
			continue
		var d: Dictionary = logic.boss_parts[i]
		if not _boss_part_was_live[i]:
			_boss_part_was_live[i] = true
			ArcadeAudio.sfx_claw()
			punch(3.4)
			float_text("部件脱落", float(d["x"]), float(d["y"]) - 0.02, Color("FFB080"))
		spr.visible = true
		spr.position = _to_screen(float(d["x"]), float(d["y"]))
		var st := int(d.get("boss_style", 0))
		var part := int(d.get("part", 0))
		var tex: Texture2D = _tex_bosses[mini(maxi(st, 0), _tex_bosses.size() - 1)]
		if st >= 0 and st < _tex_boss_drops.size():
			var row: Array = _tex_boss_drops[st]
			if part >= 0 and part < row.size():
				var drop_tex := row[part] as Texture2D
				if drop_tex:
					tex = drop_tex
		spr.texture = tex
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var px: float = BOSS_PART_PX[clampi(part, 0, BOSS_PART_PX.size() - 1)]
		if st == 3:
			px = [108.0, 116.0, 122.0][clampi(part, 0, 2)]
		if st == 4:
			px = [98.0, 118.0, 118.0][clampi(part, 0, 2)]
		if float(d.get("flash", 0.0)) > 0.0:
			spr.modulate = Color(1.55, 1.35, 1.15, 1)
		else:
			spr.modulate = Color(1.04, 1.02, 0.98, 1)
		spr.rotation = float(d.get("rot", 0.0))
		_fit_px(spr, px)


func _sync_pool(pool: Array[Sprite2D], src: Array[Dictionary], is_enemy: bool) -> void:
	for i in pool.size():
		var spr := pool[i]
		if i >= src.size() or not bool(src[i]["live"]):
			spr.visible = false
			if is_enemy and i < _enemy_shadows.size():
				_enemy_shadows[i].visible = false
			if not is_enemy and i < _bullet_trails.size():
				_bullet_trails[i].visible = false
			if not is_enemy and i < _bullet_streaks.size():
				_bullet_streaks[i].visible = false
			if not is_enemy and i < _bullet_glows.size():
				_bullet_glows[i].visible = false
			if not is_enemy:
				_hide_bullet_chain_beads(i)
			continue
		var d: Dictionary = src[i]
		spr.visible = true
		var pos := _to_screen(float(d["x"]), float(d["y"]))
		spr.position = pos
		if is_enemy:
			var kind := int(d["kind"])
			var bst := int(d.get("boss_style", 0))
			if bool(d.get("is_boss", false)) and bst >= 0 and bst < _tex_bosses.size():
				var stg := int(d.get("boss_part_stage", 0))
				var staged := _boss_stage_tex(bst, stg)
				if staged:
					spr.texture = staged
				elif _tex_bosses[bst]:
					spr.texture = _tex_bosses[bst]
				spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			elif kind >= 0 and kind < _tex_enemies.size():
				spr.texture = _tex_enemies[kind]
			var px: float = KIND_PX[kind] if kind < KIND_PX.size() else 90.0
			if bool(d.get("is_boss", false)):
				px = float(BOSS_PX[bst]) if bst >= 0 and bst < BOSS_PX.size() else 200.0
			elif bool(d.get("boss", false)):
				px *= 1.28
			if bool(d.get("meteor", false)):
				px *= 1.42
			var dying := float(d.get("dying", 0.0))
			if dying > 0.0:
				px *= clampf(dying / 0.12, 0.25, 1.0)
				spr.modulate = Color(1.7, 1.7, 1.7, clampf(dying * 8.0, 0.0, 1.0))
			elif float(d.get("warn_t", 0.0)) > 0.0:
				px *= 1.06
				spr.modulate = Color(1.6, 0.35, 0.35, 1) if fmod(_anim, 0.12) < 0.06 else Color(1.2, 0.7, 0.7, 1)
			elif float(d.get("punch", 0.0)) > 0.0:
				px *= 1.16
				spr.modulate = Color(1.55, 1.55, 1.55, 1)
			elif bool(d.get("meteor", false)):
				spr.modulate = Color(0.55, 0.42, 0.38, 1)
			elif bool(d.get("is_boss", false)):
				var flash_on := float(d.get("flash", 0.0)) > 0.0 or float(d.get("aim_t", 0.0)) > 0.0
				var rage := bst >= 4 and bool(d.get("phase2", false))
				var base_c := Color(1.10, 1.04, 1.02, 1) if rage else Color.WHITE
				spr.modulate = Color(1.55, 1.55, 1.55, 1) if flash_on else base_c
			else:
				spr.modulate = Color(1.45, 1.45, 1.45, 1) if float(d.get("flash", 0.0)) > 0.0 else Color.WHITE
			_fit_px(spr, px)
			if str(d.get("pattern", "")) == "side":
				spr.rotation = atan2(float(d.get("vy", 0.2)), float(d.get("vx", 0.0))) - PI * 0.5
			elif bool(d.get("meteor", false)):
				spr.rotation = _anim * 0.8
			else:
				spr.rotation = 0.0
			if i < _enemy_shadows.size():
				_enemy_shadows[i].visible = true
				_enemy_shadows[i].position = pos + Vector2(0, 22 if bool(d.get("is_boss", false)) else 16)
				_enemy_shadows[i].scale = Vector2(px / 80.0 if bool(d.get("is_boss", false)) else px / 90.0, 0.85 if bool(d.get("is_boss", false)) else 0.65)
		else:
			var homing := bool(d.get("homing", false))
			var px := BULLET_PX * (0.82 if ArcadeProfile.plane_low_fx() else 1.0)
			spr.texture = _tex_bullet
			spr.z_index = 9
			var vx := float(d.get("vx", 0.0))
			var vy := float(d.get("vy", -1.0))
			spr.rotation = atan2(vx, -vy)
			var pulse_sc := 1.0 + _beat_glow * (0.28 + float(_climax_tier) * 0.07)
			_fit_needle(spr, px)
			spr.scale *= pulse_sc
			if ArcadeProfile.plane_low_fx():
				spr.scale.y *= 1.08 + _beat_glow * 0.12
			var half := _needle_half_len_px(spr)
			var tip := pos
			var center := _bullet_center_from_tip(tip, vx, vy, half)
			spr.position = center
			var low_fx := ArcadeProfile.plane_low_fx()
			if low_fx:
				spr.material = _fx_add_material()
				spr.modulate = _player_bullet_tint(0.92, 1.28, 1.0)
				spr.z_index = 10
				var gl := _bullet_glows[i] if i < _bullet_glows.size() else null
				var st := _bullet_streaks[i] if i < _bullet_streaks.size() else null
				_sync_bullet_bead_sprites(st, gl, tip, vx, vy, pulse_sc)
				if i < _bullet_trails.size():
					_sync_bullet_bead_trail(_bullet_trails[i], tip, vx, vy)
				_hide_bullet_chain_beads(i)
			else:
				var core := _player_bullet_tint(0.90 if not homing else 0.82, 1.32, 1.0)
				spr.modulate = core
				spr.material = _bullet_pulse_material()
				if i < _bullet_glows.size():
					var gl2 := _bullet_glows[i]
					gl2.visible = true
					gl2.material = _fx_add_material()
					gl2.texture = _tex_spark if _tex_spark else _tex_glow
					gl2.position = tip
					gl2.rotation = 0.0
					gl2.z_index = 10
					gl2.modulate = _player_bullet_tint(0.85, 1.35, 0.92)
					_fit_px(gl2, (9.0 + _beat_glow * 4.5) * pulse_sc)
				if i < _bullet_streaks.size():
					_bullet_streaks[i].visible = false
				if i < _bullet_trails.size():
					_sync_bullet_bead_trail(_bullet_trails[i], tip, vx, vy)
				_hide_bullet_chain_beads(i)


func _max_sparks() -> int:
	return ArcadeProfile.plane_max_sparks()


func _sync_laser(logic: PlaneLogic) -> void:
	if _laser_beam == null:
		return
	var on := logic.laser_t > 0.0 and logic.super_t <= 0.0 and logic.playing
	_laser_beam.visible = on
	if _laser_muzzle_fx:
		_laser_muzzle_fx.visible = on
	if not on:
		if _laser_impact and logic.super_t <= 0.0:
			_laser_impact.visible = false
		_sync_super_lasers(logic)
		return
	var ppos := _to_screen(logic.player_x, logic.player_y)
	var nose := _to_screen(logic.player_x, logic.player_y - 0.062)
	var pulse := sin(_anim * 18.0)
	var w := _play.size.x * 0.052
	var h := maxf(8.0, nose.y)
	var beam_tex := _tex_laser_beam_b if int(_anim / 0.08) % 2 == 1 and _tex_laser_beam_b else _tex_laser_beam
	if beam_tex == null:
		beam_tex = _tex_laser_beam
	_laser_beam.texture = beam_tex
	_laser_beam.centered = false
	_laser_beam.position = Vector2(ppos.x - w * 0.5, 0.0)
	var tw := float(beam_tex.get_width()) if beam_tex else 64.0
	var th := float(beam_tex.get_height()) if beam_tex else 256.0
	if tw < 1.0:
		tw = 64.0
	if th < 1.0:
		th = 256.0
	_laser_beam.material = _fx_add_material()
	_laser_beam.scale = Vector2((w / tw) * (1.0 + 0.08 * pulse), h / th)
	_laser_beam.modulate = Color(1.05, 1.15, 1.35, 0.58 + 0.10 * pulse)
	if _laser_muzzle_fx:
		_laser_muzzle_fx.material = _fx_add_material()
		_laser_muzzle_fx.texture = _tex_laser_muzzle if _tex_laser_muzzle else beam_tex
		_laser_muzzle_fx.position = nose
		_fit_px(_laser_muzzle_fx, 72.0 * (1.0 + 0.10 * pulse))
		_laser_muzzle_fx.modulate = Color(1.1, 1.2, 1.4, 0.88)
		_laser_muzzle_fx.rotation = 0.0
	_sync_laser_impact(logic, pulse)
	_sync_super_lasers(logic)


func _super_far_logic(origin: Vector2, ang: float) -> Vector2:
	var dx := sin(ang)
	var dy := -cos(ang)
	var t := 1.40
	if dy < -0.001:
		t = minf(t, (0.0 - origin.y) / dy)
	if dx > 0.001:
		t = minf(t, (1.04 - origin.x) / dx)
	elif dx < -0.001:
		t = minf(t, (-0.04 - origin.x) / dx)
	return origin + Vector2(dx, dy) * maxf(0.08, t)


func _sync_super_lasers(logic: PlaneLogic) -> void:
	var on := logic.super_t > 0.0 and logic.playing and not _super_beams.is_empty()
	for spr in _super_halos:
		spr.visible = on
	for spr in _super_beams:
		spr.visible = on
	for spr in _super_cores:
		spr.visible = on
	for spr in _super_muzzles:
		spr.visible = on
	for spr in _super_impacts:
		spr.visible = on
	if not on:
		return
	if _laser_impact:
		_laser_impact.visible = false
	var pulse := 0.5 + 0.5 * sin(_anim * 18.0)
	var flicker := 0.5 + 0.5 * sin(_anim * 31.0)
	var angles: Array[float] = logic.super_angles()
	var add := _gold_add_material()
	for i in mini(3, _super_beams.size()):
		var ang := float(angles[i]) if i < angles.size() else 0.0
		var origin: Vector2 = logic.super_beam_origin(i)
		var far := _super_far_logic(origin, ang)
		var muzzle := _to_screen(origin.x, origin.y)
		var tip := _to_screen(far.x, far.y)
		var delta := tip - muzzle
		var length := maxf(36.0, delta.length())
		var rot := delta.angle() + PI * 0.5
		var fat := 1.0 if i == 1 else 0.86
		var halo_w := _play.size.x * 0.078 * fat * (1.0 + 0.04 * pulse)
		var blade_w := _play.size.x * 0.034 * fat * (1.0 + 0.03 * flicker)
		var core_w := _play.size.x * 0.011 * fat * (1.0 + 0.05 * flicker)
		if i < _super_halos.size():
			_place_gold_layer(_super_halos[i], _tex_gold_halo if _tex_gold_halo else _tex_gold_beam, muzzle, rot, halo_w, length, Color(1.0, 0.72, 0.22, 0.42 + 0.10 * pulse), add)
		_place_gold_layer(_super_beams[i], _tex_gold_beam_b if (int(_anim / 0.08) + i) % 2 == 1 and _tex_gold_beam_b else _tex_gold_beam, muzzle, rot, blade_w, length, Color(1.0, 0.90, 0.48, 0.88 + 0.08 * flicker), add)
		if i < _super_cores.size():
			_place_gold_layer(_super_cores[i], _tex_gold_core if _tex_gold_core else _tex_gold_beam, muzzle, rot, core_w, length, Color(1.0, 0.98, 0.88, 0.95 + 0.05 * flicker), add)
		if i < _super_muzzles.size():
			var mz := _super_muzzles[i]
			mz.visible = true
			mz.texture = _tex_gold_muzzle if _tex_gold_muzzle else _tex_gold_beam
			mz.material = add
			mz.position = muzzle
			mz.rotation = rot
			_fit_px(mz, (38.0 if i == 1 else 30.0) * (1.12 + 0.18 * pulse))
			mz.modulate = Color(1.0, 0.92, 0.55, 1.0)
		if i >= _super_impacts.size():
			continue
		var hit := _super_impacts[i]
		var best_y := -1.0
		var best_x := far.x
		var found := false
		for e in logic.enemies:
			if not logic.super_hits_enemy(e, ang, origin.x, origin.y):
				continue
			var ey := float(e.get("y", 0.0))
			if ey > best_y:
				best_y = ey
				best_x = float(e.get("x", far.x))
				found = true
		hit.visible = true
		hit.texture = _tex_gold_impact if _tex_gold_impact else _tex_gold_muzzle
		hit.material = add
		hit.position = _to_screen(best_x, best_y) if found else tip
		_fit_px(hit, (28.0 if i == 1 else 22.0) * (1.0 + 0.16 * pulse))
		hit.modulate = Color(1.0, 0.90, 0.55, 0.70 + 0.20 * flicker)
		hit.rotation = 0.0


func _gold_add_material() -> CanvasItemMaterial:
	if _gold_add_mat == null:
		_gold_add_mat = CanvasItemMaterial.new()
		_gold_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _gold_add_mat


func _fx_add_material() -> CanvasItemMaterial:
	if _fx_add_mat == null:
		_fx_add_mat = CanvasItemMaterial.new()
		_fx_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _fx_add_mat


func _lerp_hue(a: float, b: float, t: float) -> float:
	var d := fmod(b - a + 1.5, 1.0) - 0.5
	return fmod(a + d * clampf(t, 0.0, 1.0) + 1.0, 1.0)


func _tick_rainbow_hue(logic: PlaneLogic, delta: float) -> void:
	var target := _rainbow_hue
	if logic.playing:
		if ArcadeAudio.plane_bgm_synced():
			target = ArcadeAudio.plane_rainbow_hue()
		else:
			target = fmod(_anim * 0.035, 1.0)
	var k := clampf(delta * (3.4 + float(_climax_tier) * 0.35 + _beat_glow * 0.45), 0.0, 1.0)
	_rainbow_hue = _lerp_hue(_rainbow_hue, target, k)


func _climax_flash_mul() -> float:
	var base := ArcadeAudio.plane_climax_brightness_mult()
	if _climax_tier >= 3:
		base *= 1.0 + 0.26 * absf(sin(_anim * 26.0)) * clampf(_beat_glow / 1.4, 0.0, 1.0)
	elif _climax_tier >= 2:
		base *= 1.0 + 0.14 * absf(sin(_anim * 18.0)) * clampf(_beat_glow / 1.4, 0.0, 1.0)
	elif _climax_tier >= 1:
		base *= 1.0 + 0.07 * clampf(_beat_glow / 1.35, 0.0, 1.0)
	return base


func _bullet_beat_brightness() -> float:
	var b := 0.48 + 0.58 * clampf(_beat_glow / 1.55, 0.0, 1.0)
	return minf(1.95, b * _climax_flash_mul())


func _player_bullet_tint(sat_scale: float, val_scale: float, alpha: float) -> Color:
	var h := _rainbow_hue
	var beat_ph := ArcadeAudio.plane_music_beat_phase()
	var pulse := maxf(_side_beat_pulse, (1.0 - beat_ph) * clampf(_beat_glow / 1.6, 0.0, 1.0))
	if pulse > 0.35:
		h = fmod(h + pulse * 0.06, 1.0)
	var c := Color.from_hsv(h, clampf(0.72 * sat_scale, 0.45, 0.95), clampf(1.08 * val_scale, 0.92, 1.0))
	var b := _bullet_beat_brightness()
	var mul := 1.18 + (b - 0.5) * 0.70 + pulse * 0.55
	c.r = minf(1.55, c.r * mul * 1.22)
	c.g = minf(1.50, c.g * mul * 1.18)
	c.b = minf(1.45, c.b * mul * 1.12)
	c.a = clampf(alpha * (0.88 + 0.22 * b), 0.0, 1.0)
	return c


func _bullet_pulse_material() -> ShaderMaterial:
	if _bullet_pulse_mat == null:
		var sh := load(PATH_BULLET_PULSE_SHADER) as Shader
		if sh:
			_bullet_pulse_mat = ShaderMaterial.new()
			_bullet_pulse_mat.shader = sh
	if _bullet_pulse_mat:
		_bullet_pulse_mat.set_shader_parameter("beat", _beat_glow)
		_bullet_pulse_mat.set_shader_parameter("climax", float(_climax_tier))
		_bullet_pulse_mat.set_shader_parameter("trail_strength", 0.0)
	return _bullet_pulse_mat


func _emit_bullet_trail_spark(origin: Vector2, back_dir: Vector2, px_scale: float = 1.0) -> bool:
	_ensure_spark_pool()
	var slot := _free_spark()
	if slot < 0:
		return false
	var life := randf_range(0.12, 0.28 + float(_climax_tier) * 0.04)
	_spark_life[slot] = life
	_spark_max[slot] = life
	var tex: Texture2D = _tex_glow if _tex_glow else (_tex_spark if _tex_spark else _tex_star)
	var spr := _spark_pool[slot]
	if _tex_spark and (slot + int(_anim * 10.0)) % 3 == 1:
		spr.texture = _tex_spark
	else:
		spr.texture = tex
	spr.material = _fx_add_material()
	var bd := back_dir.normalized() if back_dir.length_squared() > 0.0001 else Vector2(0.0, 1.0)
	var ang := bd.angle() + randf_range(-0.78, 0.78)
	var spd := randf_range(18.0, 72.0 + _beat_glow * 58.0 + float(_climax_tier) * 12.0)
	_spark_vel[slot] = Vector2.from_angle(ang) * spd
	spr.position = origin + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))
	spr.rotation = ang
	var col := _player_bullet_tint(0.82, 1.12, 0.58 + _beat_glow * 0.48)
	col.a *= clampf(px_scale, 0.35, 1.55)
	spr.modulate = col
	var px := randf_range(18.0, 38.0) * (0.92 + _beat_glow * 0.42 + float(_climax_tier) * 0.08) * px_scale
	_fit_px(spr, px)
	spr.z_index = 8
	spr.visible = true
	return true


func _emit_bullet_trail_halo(origin: Vector2, back_dir: Vector2, px_scale: float = 1.0) -> bool:
	_ensure_spark_pool()
	var slot := _free_spark()
	if slot < 0:
		return false
	var life := randf_range(0.16, 0.34)
	_spark_life[slot] = life
	_spark_max[slot] = life
	var spr := _spark_pool[slot]
	spr.texture = _tex_glow if _tex_glow else (_tex_trail if _tex_trail else _tex_spark)
	spr.material = _fx_add_material()
	var bd := back_dir.normalized() if back_dir.length_squared() > 0.0001 else Vector2(0.0, 1.0)
	spr.position = origin + bd * randf_range(-4.0, 10.0)
	spr.rotation = bd.angle()
	var col := _player_bullet_tint(0.72, 1.05, 0.22 + _beat_glow * 0.28)
	col.a *= clampf(px_scale * 0.85, 0.2, 1.2)
	spr.modulate = col
	var px := randf_range(36.0, 72.0) * (1.0 + _beat_glow * 0.35 + float(_climax_tier) * 0.12) * px_scale
	_fit_px(spr, px)
	spr.z_index = 7
	spr.visible = true
	_spark_vel[slot] = bd * randf_range(-8.0, 18.0)
	return true


func _sprinkle_bullet_pollute(tip: Vector2, back: Vector2) -> void:
	if ArcadeProfile.plane_low_fx():
		_emit_bullet_trail_spark(tip + back * randf_range(2.0, 9.0), back, 0.75 + float(_climax_tier) * 0.06)
		if _beat_glow > 0.55 and randf() > 0.45:
			_emit_bullet_trail_spark(tip + back * randf_range(6.0, 16.0), back, 0.65)
		_pollute = maxf(_pollute, 0.008 + _beat_glow * 0.018)
		return
	_emit_bullet_trail_spark(tip + back * randf_range(4.0, 18.0), back)
	_emit_bullet_trail_halo(tip + back * randf_range(2.0, 12.0), back, 0.95 + float(_climax_tier) * 0.08)
	if _beat_glow > 0.35:
		_emit_bullet_trail_spark(tip, back, 1.08)
	if _beat_glow > 0.55:
		_emit_bullet_trail_halo(tip, back, 1.12)
	if _climax_tier >= 2 and _beat_glow > 0.45:
		for _k in 2 + _climax_tier:
			var off := back * randf_range(-6.0, 14.0) + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))
			_emit_bullet_trail_spark(tip + off, back, 1.05 + randf() * 0.25)
	if _climax_tier >= 3 and _beat_glow > 0.65:
		_emit_bullet_trail_halo(tip + back * 6.0, back, 1.35)


func _tick_bullet_trail_pollute(logic: PlaneLogic, delta: float) -> void:
	if not logic.playing or logic.laser_t > 0.0 or logic.super_t > 0.0:
		return
	_bullet_pollute_cd -= delta
	var climax_k := clampf(float(_climax_tier) / 3.0, 0.0, 1.0)
	var interval := lerpf(0.038, 0.007, clampf(_beat_glow / 1.55, 0.0, 1.0))
	interval = lerpf(interval, interval * 0.72, climax_k)
	if ArcadeProfile.plane_low_fx():
		interval *= 2.6
	if _bullet_pollute_cd > 0.0:
		return
	_bullet_pollute_cd = interval
	var cap := mini(14 + int(_beat_glow * 11.0) + _climax_tier * 4, 38)
	if ArcadeProfile.plane_low_fx():
		cap = mini(5 + int(_beat_glow * 3.0) + _climax_tier * 2, 10)
	var n := 0
	for b in logic.bullets:
		if not bool(b.get("live", false)):
			continue
		n += 1
		if n > cap:
			break
		var vx := float(b.get("vx", 0.0))
		var vy := float(b.get("vy", -1.0))
		var tip := _to_screen(float(b["x"]), float(b["y"]))
		var back := _bullet_back_screen(vx, vy)
		_sprinkle_bullet_pollute(tip, back)
	_pollute = maxf(_pollute, 0.018 + _beat_glow * 0.028 + float(_climax_tier) * 0.012)


func _birth_beat_particles(logic: PlaneLogic, bar: bool, climax: int = 0) -> void:
	var low := ArcadeProfile.plane_low_fx()
	var muzzle := _to_screen(logic.player_x, logic.player_y - 0.062)
	var spray_n := 10 + logic.live_bullet_count() / 2 + climax * 5
	if bar:
		spray_n += 10 + climax * 4
	if low:
		spray_n = mini(spray_n, 8 + climax * 2)
	_emit_sparks(muzzle, spray_n, false, false, true, Vector2(0.0, -1.0))
	if not low:
		_emit_sparks(muzzle + Vector2(randf_range(-14.0, 14.0), randf_range(-6.0, 8.0)), spray_n / 2, false, false, true, Vector2(0.0, -1.0))
	var flash_px := 72.0 if bar else 48.0
	flash_px += float(climax) * 18.0
	if low:
		flash_px *= 0.85
	_alloc_fx(logic.player_x, logic.player_y - 0.05, FX_FLASH, 0.08 if bar else 0.05, flash_px, _player_bullet_tint(0.9, 1.1, 1.0), 0.0)
	if bar or climax >= 2:
		if not low or bar:
			_alloc_fx(logic.player_x, logic.player_y - 0.05, FX_BLOOM, 0.10, 96.0 + float(climax) * 24.0, _player_bullet_tint(0.75, 1.05, 0.85), 0.0)
	var bullet_cap := 12 if low else 28
	var n := 0
	for b in logic.bullets:
		if not bool(b["live"]):
			continue
		if n >= bullet_cap:
			break
		var p := _to_screen(float(b["x"]), float(b["y"]))
		var bd := Vector2(float(b.get("vx", 0.0)), float(b.get("vy", -1.0)))
		if bd.length_squared() < 0.0001:
			bd = Vector2(0.0, -1.0)
		bd = bd.normalized()
		if n % 2 == 0 or bar or climax >= 1:
			var burst := 4 + climax * 2 if bar else 2 + climax
			if low:
				burst = mini(burst, 2 if bar else 1)
			for _j in burst:
				_emit_bullet_trail_spark(p + bd * randf_range(-10.0, 14.0), bd, 1.08 + _beat_glow * 0.38)
				if not low and _j % 2 == 0:
					_emit_bullet_trail_halo(p + bd * randf_range(-6.0, 10.0), bd, 1.0 + float(climax) * 0.12)
		n += 1
	var poll := (0.06 if bar else 0.032) + float(climax) * 0.018
	if low:
		poll += 0.04 + float(climax) * 0.025
	_pollute = maxf(_pollute, poll)


func _setup_sky_shader_panel() -> void:
	if _sky_scroll != null:
		return
	var sh := load(PATH_SKY_SHADER) as Shader
	if sh == null:
		return
	_sky_mat = ShaderMaterial.new()
	_sky_mat.shader = sh
	_sky_scroll = ColorRect.new()
	_sky_scroll.name = "SkyScroll"
	_sky_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sky_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sky_scroll.material = _sky_mat
	_play_clip.add_child(_sky_scroll)
	_play_clip.move_child(_sky_scroll, 1)
	if _sky_a and ArcadeProfile.plane_use_shader_sky():
		_sky_a.visible = false
	if _sky_b and ArcadeProfile.plane_use_shader_sky():
		_sky_b.visible = false


func _update_sky_shader(bossing: bool) -> void:
	if _tex_sky == null:
		return
	var boss_col := Color(0.62, 0.64, 0.72, 1) if bossing else Color.WHITE
	if not ArcadeProfile.plane_use_shader_sky():
		if _sky_scroll:
			_sky_scroll.visible = false
		_place_strip(_sky_a, _sky_b, _tex_sky, _scroll_sky, _play.size)
		if _sky_a:
			_sky_a.modulate = boss_col
		if _sky_b:
			_sky_b.modulate = boss_col
		return
	_setup_sky_shader_panel()
	if _sky_scroll == null or _sky_mat == null:
		_place_strip(_sky_a, _sky_b, _tex_sky, _scroll_sky, _play.size)
		return
	var tw := float(_tex_sky.get_width())
	var th := float(_tex_sky.get_height())
	if tw < 1.0 or th < 1.0:
		return
	var sc := _play.size.x / tw
	var tile_h := th * sc
	_sky_mat.set_shader_parameter("sky_tex", _tex_sky)
	_sky_mat.set_shader_parameter("scroll_px", _scroll_sky)
	_sky_mat.set_shader_parameter("tile_h_px", tile_h)
	_sky_mat.set_shader_parameter("view_h_px", _play.size.y)
	_sky_mat.set_shader_parameter("one_shot", 1.0 if _sky_oneshot else 0.0)
	_sky_scroll.modulate = Color(0.62, 0.64, 0.72, 1) if bossing else Color.WHITE
	_sky_scroll.visible = true


func _ensure_spark_pool() -> void:
	if not _spark_pool.is_empty():
		return
	_spark_life.resize(_max_sparks())
	_spark_max.resize(_max_sparks())
	var spark_tex: Texture2D = _tex_spark if _tex_spark else _tex_glow
	if spark_tex == null:
		spark_tex = _tex_star
	var add := _fx_add_material()
	for i in _max_sparks():
		var s := _mk_sprite(spark_tex)
		s.visible = false
		s.material = add
		s.z_index = 6
		_play_clip.add_child(s)
		_spark_pool.append(s)
		_spark_vel.append(Vector2.ZERO)
		_spark_life[i] = 0.0
		_spark_max[i] = 0.0


func _free_spark() -> int:
	for i in _spark_pool.size():
		if _spark_life[i] <= 0.0:
			return i
	return -1


func _emit_sparks(origin: Vector2, n: int, boom: bool, gold: bool, micro: bool = false, bias_dir: Vector2 = Vector2.ZERO) -> void:
	_ensure_spark_pool()
	if _spark_pool.is_empty():
		return
	var spark_tex: Texture2D = _tex_spark if _tex_spark else (_tex_glow if _tex_glow else _tex_star)
	var add := _fx_add_material()
	var left := mini(n, _max_sparks())
	for k in left:
		var slot := _free_spark()
		if slot < 0:
			return
		var life := randf_range(0.28, 0.52) if boom else (randf_range(0.07, 0.16) if micro else randf_range(0.14, 0.28))
		_spark_life[slot] = life
		_spark_max[slot] = life
		var ang := randf() * TAU
		if bias_dir.length_squared() > 0.0001:
			ang = bias_dir.angle() + randf_range(-0.95, 0.95)
		var spd := randf_range(90.0, 260.0) if boom else (randf_range(80.0, 220.0) if micro else randf_range(40.0, 140.0))
		_spark_vel[slot] = Vector2(cos(ang), sin(ang)) * spd
		var spr := _spark_pool[slot]
		spr.texture = spark_tex
		spr.material = add
		spr.position = origin + Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
		spr.rotation = ang
		if gold:
			spr.modulate = Color(1.55, 1.22, 0.35, 1.0)
		elif boom:
			spr.modulate = Color(1.65, 0.95, 0.32, 1.0)
		elif micro:
			spr.modulate = Color(0.75, 1.15, 1.55, 0.95)
		else:
			spr.modulate = Color(0.55, 1.05, 1.55, 0.92)
		var px := randf_range(22.0, 44.0) if boom else (randf_range(5.0, 14.0) if micro else randf_range(10.0, 22.0))
		_fit_px(spr, px)
		spr.z_index = 6 if not boom else 5
		spr.visible = true


func _tick_sparks(delta: float) -> void:
	for i in _spark_pool.size():
		if _spark_life[i] <= 0.0:
			_spark_pool[i].visible = false
			continue
		_spark_life[i] -= delta
		_spark_vel[i] *= maxf(0.0, 1.0 - (1.2 if _spark_max[i] > 0.35 else 2.0) * delta)
		_spark_pool[i].position += _spark_vel[i] * delta
		var mx := _spark_max[i] if _spark_max[i] > 0.001 else 0.25
		var k := 1.0 - clampf(_spark_life[i] / mx, 0.0, 1.0)
		var spr := _spark_pool[i]
		spr.modulate.a = clampf(1.0 - k, 0.0, 1.0)
		spr.visible = _spark_life[i] > 0.0


func _ship_lit_material() -> ShaderMaterial:
	if _ship_lit_mat == null:
		var sh := load(PATH_SHIP_LIT) as Shader
		if sh:
			_ship_lit_mat = ShaderMaterial.new()
			_ship_lit_mat.shader = sh
	return _ship_lit_mat


func _place_gold_layer(spr: Sprite2D, tex: Texture2D, muzzle: Vector2, rot: float, width_px: float, length: float, col: Color, mat: CanvasItemMaterial) -> void:
	if spr == null:
		return
	if tex == null:
		tex = _tex_gold_beam
	spr.visible = true
	spr.texture = tex
	spr.material = mat
	spr.centered = true
	var tw := float(tex.get_width()) if tex else 128.0
	var th := float(tex.get_height()) if tex else 512.0
	if tw < 1.0:
		tw = 128.0
	if th < 1.0:
		th = 512.0
	spr.offset = Vector2(0.0, -th * 0.5)
	spr.position = muzzle
	spr.rotation = rot
	spr.scale = Vector2(width_px / tw, length / th)
	spr.modulate = col


func _sync_laser_impact(logic: PlaneLogic, pulse: float) -> void:
	if _laser_impact == null:
		return
	var best_y := -1.0
	var best_x := logic.player_x
	var found := false
	for e in logic.enemies:
		if not bool(e.get("live", false)):
			continue
		var ex := float(e.get("x", 0.5))
		var ey := float(e.get("y", 0.0))
		if absf(ex - logic.player_x) >= PlaneLogic.LASER_W:
			continue
		if ey >= logic.player_y:
			continue
		if ey > best_y:
			best_y = ey
			best_x = ex
			found = true
	_laser_impact.visible = true
	_laser_impact.material = _fx_add_material()
	_laser_impact.texture = _tex_laser_impact if _tex_laser_impact else _tex_laser_muzzle
	if found:
		_laser_impact.position = _to_screen(best_x, best_y)
	else:
		_laser_impact.position = Vector2(_to_screen(logic.player_x, 0.0).x, 18.0)
	_fit_px(_laser_impact, 44.0 * (1.0 + 0.10 * pulse))
	_laser_impact.modulate = Color(1.15, 1.2, 1.4, 0.62 + 0.12 * pulse)
	_laser_impact.rotation = _anim * 2.4


func _sync_double_hud(logic: PlaneLogic) -> void:
	var w := minf(_play.size.x * 0.56, _play.size.x - 248.0)
	w = maxf(w, minf(320.0, _play.size.x * 0.50))
	var x := _play.position.x + (_play.size.x - w) * 0.5
	var bar_h := 22.0
	## 火力条贴玩法区最底
	var y := _play.position.y + _play.size.y - 10.0 - bar_h
	var stack_y := y
	if _energy_bar_bg:
		_energy_bar_bg.visible = false
		_energy_bar_fill.visible = false
		_energy_bar_label.visible = false
	var shown := 0
	if _power_label:
		_power_label.visible = logic.playing
		_power_label.text = "火力  Lv%d / %d%s" % [
			logic.power_lv,
			PlaneLogic.POWER_MAX,
			("  " + logic.power_title(logic.power_lv)) if logic.power_lv > 0 else "",
		]
		_power_label.add_theme_font_size_override("font_size", 22)
		_power_label.position = Vector2(x, stack_y - 28.0)
		_power_label.size = Vector2(w, 26.0)
	if _double_bar_bg:
		var on := logic.playing
		_double_bar_bg.visible = on
		_double_bar_fill.visible = on
		_double_bar_label.visible = false
		if on:
			var ratio := clampf(float(logic.power_lv) / float(PlaneLogic.POWER_MAX), 0.0, 1.0)
			_double_bar_bg.position = Vector2(x, stack_y)
			_double_bar_bg.size = Vector2(w, bar_h)
			_double_bar_fill.position = Vector2(x + 3.0, stack_y + 3.0)
			_double_bar_fill.size = Vector2((w - 6.0) * maxf(0.08, ratio), bar_h - 6.0)
			if logic.power_lv >= 7:
				_double_bar_fill.color = Color(1.0, 0.38, 0.12, 0.95)
			elif logic.power_lv >= 5:
				_double_bar_fill.color = Color(1.0, 0.55, 0.18, 0.95)
			elif logic.power_lv >= 3:
				_double_bar_fill.color = Color(1.0, 0.72, 0.22, 0.95)
			elif logic.power_lv >= 2:
				_double_bar_fill.color = Color(1.0, 0.86, 0.32, 0.95)
			else:
				_double_bar_fill.color = Color(1.0, 0.90, 0.55, 0.95)
			shown += 1
	if _laser_bar_bg:
		_laser_bar_bg.visible = false
		_laser_bar_fill.visible = false
		_laser_bar_label.visible = false


func _compute_beat_bin_amps(bins: int) -> PackedFloat32Array:
	var amps := PackedFloat32Array()
	if bins < 1:
		return amps
	amps.resize(bins)
	var beat_f := ArcadeAudio.plane_beat_continuous()
	var beat_ph := ArcadeAudio.plane_music_beat_phase()
	var energy := clampf(_beat_glow / 1.75, 0.0, 1.0)
	var punch := _side_beat_pulse
	var beat_flash := (1.0 - beat_ph) * (0.55 + energy * 0.65)
	var tier := float(_climax_tier)
	for i in bins:
		var t := float(i) / float(bins)
		var ph := beat_f * 0.48 + t * 16.0 + punch * 2.8
		var w1 := absf(sin(ph * 1.65 + float(i) * 0.59))
		var w2 := absf(cos(ph * 2.15 + float(i) * 0.37))
		var w3 := absf(sin(ph * 3.8 + tier * 0.4))
		var w4 := absf(cos(ph * 5.1 + float(i) * 0.19 + punch * 1.5))
		var amp := energy * (0.12 + 0.88 * w1 * w2 * (0.50 + w3 * 0.35 + w4 * 0.22))
		amp *= 1.0 + punch * 0.72 + tier * 0.10 + beat_flash * 0.95
		if i % 4 == int(beat_f) % 4:
			amp *= 1.0 + punch * 0.55 + beat_flash * 0.35
		if i % 8 == int(beat_f * 0.5) % 8:
			amp *= 1.0 + energy * 0.35
		amps[i] = amp
	return amps


func _combo_tower_beat_amps() -> PackedFloat32Array:
	var n := COMBO_TOWER_BEAT_BINS
	var synth := _compute_beat_bin_amps(n)
	if not COMBO_TOWER_RAINBOW_BEAT_V2:
		return synth
	var spec := ArcadeAudio.plane_bgm_spectrum_amps(n)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var s := float(synth[i]) if i < synth.size() else 0.0
		var sp := float(spec[i]) if i < spec.size() else 0.0
		out[i] = clampf(maxf(s, sp * 0.92) * (0.58 + s * 0.48) + sp * 0.22, 0.0, 1.28)
	return out


func _horiz_beat_bin_count() -> int:
	return HORIZONTAL_BEAT_BINS_LOW if ArcadeProfile.plane_low_fx() else HORIZONTAL_BEAT_BINS


func _horiz_beat_reference_amps() -> PackedFloat32Array:
	var n := _horiz_beat_bin_count()
	var blend := _combo_tower_beat_amps()
	var spec := ArcadeAudio.plane_bgm_spectrum_amps(n)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var sp := float(spec[i]) if i < spec.size() else 0.0
		var bl := _horiz_beat_amp_at(blend, i, n)
		var a0 := maxf(sp * 1.08, bl * 0.58)
		var li := maxi(0, i - 1)
		var ri := mini(n - 1, i + 1)
		var sp_l := float(spec[li]) if li < spec.size() else 0.0
		var sp_r := float(spec[ri]) if ri < spec.size() else 0.0
		var nb0 := maxf(maxf(sp_l, sp_r) * 1.08, _horiz_beat_amp_at(blend, li, n) * 0.58)
		if a0 >= nb0 * 0.9 and a0 > 0.16:
			a0 *= HORIZONTAL_BEAT_AMP_PEAK_MUL
		out[i] = clampf(pow(a0, HORIZONTAL_BEAT_AMP_CURVE), 0.0, HORIZONTAL_BEAT_AMP_MAX)
	return out


func _horiz_beat_amp_at(amps: PackedFloat32Array, i: int, n: int) -> float:
	if amps.is_empty() or n < 1:
		return 0.0
	var fi := float(i) / float(maxi(1, n - 1)) * float(amps.size() - 1)
	var i0 := int(floor(fi))
	var i1 := mini(i0 + 1, amps.size() - 1)
	return lerpf(float(amps[i0]), float(amps[i1]), fi - float(i0))


func _mk_horiz_shader_bar(z: int) -> ColorRect:
	var bar := ColorRect.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.visible = false
	bar.color = Color(1.0, 1.0, 1.0, 1.0)
	bar.z_index = z
	var sm := ShaderMaterial.new()
	sm.shader = HORIZONTAL_BEAT_SHADER
	bar.material = sm
	add_child(bar)
	return bar


func _horiz_beat_far_norm(left_segment: bool, t: float) -> float:
	return t if left_segment else 1.0 - t


func _horiz_beat_arc_y_persp(far_norm: float, cy: float) -> float:
	var fn := pow(clampf(far_norm, 0.0, 1.0), HORIZONTAL_BEAT_ARC_CURVE)
	return cy + lerpf(HORIZONTAL_BEAT_OUTER_Y_DROP, -HORIZONTAL_BEAT_INNER_Y_LIFT, fn)


func _horiz_beat_depth_scale(far_norm: float) -> float:
	var fn := pow(clampf(far_norm, 0.0, 1.0), HORIZONTAL_BEAT_ARC_CURVE)
	return lerpf(HORIZONTAL_BEAT_DEPTH_NEAR, HORIZONTAL_BEAT_DEPTH_FAR, fn)


func _horiz_beat_width_scale(far_norm: float) -> float:
	var fn := pow(clampf(far_norm, 0.0, 1.0), HORIZONTAL_BEAT_ARC_CURVE)
	return lerpf(HORIZONTAL_BEAT_WIDTH_NEAR, HORIZONTAL_BEAT_WIDTH_FAR, fn)


func _clear_horiz_beat_bars() -> void:
	for bar in _horiz_beat_l_bars:
		if is_instance_valid(bar):
			bar.queue_free()
	for bar in _horiz_beat_r_bars:
		if is_instance_valid(bar):
			bar.queue_free()
	_horiz_beat_l_bars.clear()
	_horiz_beat_r_bars.clear()


func _build_horizontal_beat_spectrum() -> void:
	var need := _horiz_beat_bin_count()
	if _horiz_beat_l_bars.size() == need:
		return
	_clear_horiz_beat_bars()
	var beat_z := COMBO_TOWER_Z + 8
	for _i in need:
		_horiz_beat_l_bars.append(_mk_horiz_shader_bar(beat_z))
		_horiz_beat_r_bars.append(_mk_horiz_shader_bar(beat_z))


func _sync_horizontal_beat_segment(
	bars: Array[ColorRect],
	x0: float,
	x1: float,
	cy: float,
	left_segment: bool,
	amps: PackedFloat32Array,
	beat_flash: float,
	hue_off: float
) -> void:
	var n := bars.size()
	if n < 1:
		return
	var w := x1 - x0
	if w < 8.0:
		for bar in bars:
			bar.visible = false
		return
	var col_w := w / float(n)
	for i in n:
		var bar: ColorRect = bars[i]
		var amp := _horiz_beat_amp_at(amps, i, n)
		var t_bar := float(i) / float(maxi(1, n - 1))
		var cx := lerpf(x0, x1, t_bar)
		var far_n := _horiz_beat_far_norm(left_segment, t_bar)
		var cy_i := _horiz_beat_arc_y_persp(far_n, cy)
		if amp < 0.025:
			bar.visible = false
			continue
		var depth := _horiz_beat_depth_scale(far_n)
		var width_s := _horiz_beat_width_scale(far_n)
		var bar_w := maxf(1.0, col_w * HORIZONTAL_BEAT_BAR_WIDTH_FRAC * width_s)
		var bar_h := maxf(4.0, amp * HORIZONTAL_BEAT_HALF_H * 2.0 * depth)
		bar.visible = true
		bar.position = Vector2(cx - bar_w * 0.5, cy_i - bar_h * 0.5)
		bar.size = Vector2(bar_w, bar_h)
		var mat := bar.material as ShaderMaterial
		if mat:
			var hue := fmod(_rainbow_hue + hue_off, 1.0)
			var x_tint := (1.0 - far_n) * 0.92
			mat.set_shader_parameter("amp", amp * lerpf(1.0, 0.52, far_n))
			mat.set_shader_parameter("hue", hue)
			mat.set_shader_parameter("x_tint", x_tint)
			mat.set_shader_parameter("flash", beat_flash)


func _sync_horizontal_beat_bars(logic: PlaneLogic) -> void:
	_build_horizontal_beat_spectrum()
	if _play == null or _play.size.x < 8.0:
		return
	var on := logic.playing
	if not on:
		for bar in _horiz_beat_l_bars:
			bar.visible = false
		for bar in _horiz_beat_r_bars:
			bar.visible = false
		return
	var p := _play
	var cy := p.position.y + p.size.y * HORIZONTAL_BEAT_Y_FRAC
	var beat_ph := ArcadeAudio.plane_music_beat_phase()
	var energy := clampf(_beat_glow / 1.75, 0.0, 1.0)
	var beat_flash := (1.0 - beat_ph) * (0.45 + energy * 0.55) + _side_beat_pulse * 0.35
	var amps := _horiz_beat_reference_amps()
	var mid_x := p.position.x + p.size.x * 0.5
	var half_gap := p.size.x * HORIZONTAL_BEAT_CENTER_GAP_FRAC * 0.5
	var lx0 := p.position.x + HORIZONTAL_BEAT_SIDE_MARGIN
	var lx1 := mid_x - half_gap
	var rx0 := mid_x + half_gap
	var rx1 := p.position.x + p.size.x - HORIZONTAL_BEAT_SIDE_MARGIN
	_sync_horizontal_beat_segment(_horiz_beat_l_bars, lx0, lx1, cy, true, amps, beat_flash, 0.0)
	_sync_horizontal_beat_segment(_horiz_beat_r_bars, rx0, rx1, cy, false, amps, beat_flash, 0.0)


func _sync_side_beat_bars(logic: PlaneLogic) -> void:
	if _side_beat_spine_l == null:
		return
	var on := logic.playing
	_set_side_beat_visible(on)
	if HORIZONTAL_BEAT_ENABLED:
		return
	if not on:
		return
	var beat_f := ArcadeAudio.plane_beat_continuous()
	var energy := clampf(_beat_glow / 1.75, 0.0, 1.0)
	var punch := _side_beat_pulse
	var p := _play
	var top := p.position.y
	var htot := p.size.y
	var bins := _side_beat_spike_l.size()
	if bins < 1:
		return
	var seg_h := htot / float(bins)
	var hc := Color.from_hsv(_rainbow_hue, 0.90, 1.0)
	var tier := float(_climax_tier)
	var vs := get_viewport_rect().size
	var into_max := clampf(p.size.x * SIDE_BEAT_INTO_FRAC, SIDE_BEAT_INTO_MIN, SIDE_BEAT_INTO_MAX)
	var out_max := clampf(p.position.x * 0.65 + 4.0, 16.0, vs.x * SIDE_BEAT_OUT_FRAC)
	if _side_beat_haze_l:
		_side_beat_haze_l.visible = false
		_side_beat_haze_r.visible = false
	if _side_beat_veil_l:
		_side_beat_veil_l.visible = false
		_side_beat_veil_r.visible = false
	if _side_beat_spine_l:
		_side_beat_spine_l.visible = false
		_side_beat_spine_r.visible = false
	var amps := _compute_beat_bin_amps(bins)
	for i in bins:
		var amp := amps[i] if i < amps.size() else 0.0
		if SIDE_BEAT_SHOW_LEFT or not SIDE_BEAT_IN_COMBO_TOWER:
			_paint_side_beat_spike(_side_beat_spike_l[i], true, p, top, seg_h, float(i), amp, into_max, out_max, hc, tier)
		elif _side_beat_spike_l[i]:
			_side_beat_spike_l[i].visible = false
		if SIDE_BEAT_SHOW_RIGHT or not SIDE_BEAT_IN_COMBO_TOWER:
			_paint_side_beat_spike(_side_beat_spike_r[i], false, p, top, seg_h, float(i), amp, into_max, out_max, hc, tier)
		elif _side_beat_spike_r[i]:
			_side_beat_spike_r[i].visible = false
	if SIDE_BEAT_SHOW_LEFT or not SIDE_BEAT_IN_COMBO_TOWER:
		_paint_side_beat_chips(_side_beat_chip_l, true, p, top, htot, beat_f, energy, punch, hc, into_max, out_max)
	elif _side_beat_chip_l.size() > 0:
		for chip in _side_beat_chip_l:
			chip.visible = false
	if SIDE_BEAT_SHOW_RIGHT or not SIDE_BEAT_IN_COMBO_TOWER:
		_paint_side_beat_chips(_side_beat_chip_r, false, p, top, htot, beat_f, energy, punch, hc, into_max, out_max)
	elif _side_beat_chip_r.size() > 0:
		for chip in _side_beat_chip_r:
			chip.visible = false


func _side_beat_bin_count() -> int:
	return 34 if ArcadeProfile.plane_low_fx() else SIDE_BEAT_BIN_MAX


func _side_beat_chip_count() -> int:
	return 16 if ArcadeProfile.plane_low_fx() else SIDE_BEAT_CHIP_MAX


func _bullet_bead_count() -> int:
	return 4 if ArcadeProfile.plane_low_fx() else BULLET_BEAD_MAX


func _mk_beat_bar_rect(z: int) -> ColorRect:
	var r := ColorRect.new()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.visible = false
	r.z_index = z
	add_child(r)
	return r


func _build_side_beat_spectrum() -> void:
	if _side_beat_spine_l != null:
		return
	_side_beat_veil_l = _mk_beat_bar_rect(11)
	_side_beat_veil_r = _mk_beat_bar_rect(11)
	_side_beat_haze_l = _mk_beat_bar_rect(10)
	_side_beat_haze_r = _mk_beat_bar_rect(10)
	_side_beat_spine_l = _mk_beat_bar_rect(14)
	_side_beat_spine_r = _mk_beat_bar_rect(14)
	var bins := _side_beat_bin_count()
	for i in bins:
		_side_beat_spike_l.append(_mk_beat_bar_rect(13))
		_side_beat_spike_r.append(_mk_beat_bar_rect(13))
	var chips := _side_beat_chip_count()
	for i in chips:
		_side_beat_chip_l.append(_mk_beat_bar_rect(15))
		_side_beat_chip_r.append(_mk_beat_bar_rect(15))


func _set_side_beat_visible(on: bool) -> void:
	if _side_beat_veil_l == null:
		return
	if not on:
		_side_beat_spine_l.visible = false
		if _side_beat_haze_l:
			_side_beat_haze_l.visible = false
			_side_beat_haze_r.visible = false
		if _side_beat_veil_l:
			_side_beat_veil_l.visible = false
			_side_beat_veil_r.visible = false
		_side_beat_spine_r.visible = false
		for r in _side_beat_spike_l:
			r.visible = false
		for r in _side_beat_spike_r:
			r.visible = false
		for r in _side_beat_chip_l:
			r.visible = false
		for r in _side_beat_chip_r:
			r.visible = false


func _paint_side_beat_haze(
	haze: ColorRect,
	left: bool,
	top: float,
	htot: float,
	vs: Vector2,
	zone_w: float,
	hc: Color,
	energy: float,
	punch: float,
) -> void:
	if haze == null:
		return
	var p := _play
	var w := zone_w * 1.18
	var x := 0.0 if left else vs.x - w
	haze.visible = true
	haze.position = Vector2(x, top - 4.0)
	haze.size = Vector2(w + (p.position.x * 0.15 if left else p.position.x * 0.08), htot + 8.0)
	haze.color = Color(hc.r * 0.08, hc.g * 0.22, hc.b * 0.16, 0.14 + energy * 0.22 + punch * 0.16)


func _paint_side_beat_veil(
	veil: ColorRect,
	left: bool,
	top: float,
	htot: float,
	w: float,
	hc: Color,
	energy: float,
	punch: float,
	out_max: float,
) -> void:
	var p := _play
	var x := maxf(0.0, p.position.x - out_max) if left else p.position.x + p.size.x - w + out_max * 0.35
	veil.visible = true
	veil.position = Vector2(x, top)
	veil.size = Vector2(w, htot)
	veil.color = Color(hc.r * 0.14, hc.g * 0.38, hc.b * 0.26, 0.34 + energy * 0.38 + punch * 0.18)


func _paint_side_beat_spike(
	sp: ColorRect,
	left: bool,
	p: Rect2,
	top: float,
	seg_h: float,
	idx: float,
	amp: float,
	into_max: float,
	out_max: float,
	hc: Color,
	tier: float,
) -> void:
	sp.visible = amp > 0.05
	if not sp.visible:
		return
	var into := 3.0 + amp * into_max * SIDE_BEAT_INTO_AMP
	var y0 := top + seg_h * idx
	var h := maxf(2.0, seg_h * 1.12)
	var bright := 0.35 + amp * 0.72
	if left:
		sp.position = Vector2(p.position.x, y0)
		sp.size = Vector2(into, h)
	else:
		sp.position = Vector2(p.position.x + p.size.x - into, y0)
		sp.size = Vector2(into, h)
	sp.color = Color(
		hc.r * (0.88 + bright * 0.62 + tier * 0.05),
		hc.g * (0.98 + bright * 0.52 + tier * 0.04),
		hc.b * (0.90 + bright * 0.30),
		0.26 + amp * 0.68,
	)


func _paint_side_beat_chips(
	chips: Array[ColorRect],
	left: bool,
	p: Rect2,
	top: float,
	htot: float,
	beat_f: float,
	energy: float,
	punch: float,
	hc: Color,
	into_max: float,
	out_max: float,
) -> void:
	var n := chips.size()
	if n < 1:
		return
	for c in n:
		var chip := chips[c]
		if energy < 0.06 and punch < 0.04:
			chip.visible = false
			continue
		var ty := top + htot * fmod(float(c) / float(n) + beat_f * 0.07 + sin(beat_f + float(c)) * 0.025, 1.0)
		var spread := (into_max + out_max * 0.45) * 0.78
		var jitter := absf(sin(beat_f * 3.2 + float(c) * 1.7)) * spread
		var cx := maxf(4.0, p.position.x - out_max * 0.35 + jitter) if left else p.position.x + p.size.x - jitter
		var sz := 3.0 + energy * 6.0 + punch * 4.5
		chip.visible = true
		chip.position = Vector2(cx - sz * 0.5, ty)
		chip.size = Vector2(sz, sz * (0.82 + absf(sin(beat_f * 5.0 + float(c))) * 0.45))
		chip.color = Color(
			hc.r * 1.32 + 0.28,
			hc.g * 1.22 + 0.38,
			hc.b * 1.08 + 0.18,
			0.30 + energy * 0.50 + punch * 0.32,
		)


func _hide_bullet_chain_beads(bi: int) -> void:
	for j in BULLET_BEAD_MAX:
		var idx := bi * BULLET_BEAD_MAX + j
		if idx < _bullet_beads.size():
			_bullet_beads[idx].visible = false


func _sync_bullet_chain_beads(bi: int, tip: Vector2, vx: float, vy: float, pulse_sc: float) -> void:
	var n := _bullet_bead_count()
	var back := _bullet_back_screen(vx, vy)
	var perp := Vector2(back.y, -back.x)
	var chunk := _tex_star8 if _tex_star8 else (_tex_spark if _tex_spark else _tex_glow)
	var spark := _tex_spark if _tex_spark else chunk
	for j in n:
		var idx := bi * BULLET_BEAD_MAX + j
		if idx >= _bullet_beads.size():
			break
		var spr := _bullet_beads[idx]
		spr.visible = true
		spr.material = _fx_add_material()
		var dist := 6.0 + float(j) * (9.0 + _beat_glow * 3.5)
		var wobble := sin(_anim * 26.0 + float(bi) * 0.63 + float(j) * 1.65) * (2.0 + float(j) * 1.35)
		spr.position = tip + back * dist + perp * wobble
		var big := 1.0 if j < 2 else 1.48 + float(j - 2) * 0.28
		var px := (18.0 + float(j) * 5.0 + _beat_glow * 11.0) * pulse_sc * big
		spr.texture = chunk if j >= 1 else spark
		spr.z_index = 8 + mini(j, 3)
		spr.modulate = _player_bullet_tint(0.95 + float(j) * 0.04, 1.22, 0.52 + _beat_glow * 0.38)
		spr.rotation = float(bi + j) * 0.55 + _anim * 2.8
		_fit_px(spr, px)


func _place_energy_bar(logic: PlaneLogic, x: float, y: float, w: float, h: float = 26.0) -> void:
	if _energy_bar_bg == null:
		return
	var on := logic.playing
	_energy_bar_bg.visible = on
	_energy_bar_fill.visible = on
	_energy_bar_label.visible = on
	if not on:
		return
	var ratio := clampf(logic.energy / PlaneLogic.ENERGY_MAX, 0.0, 1.0)
	var super_on := logic.super_t > 0.0
	var pulse := 0.5 + 0.5 * sin(_anim * (14.0 if super_on else 6.0))
	_energy_bar_bg.position = Vector2(x, y)
	_energy_bar_bg.size = Vector2(w, h)
	_energy_bar_fill.position = Vector2(x + 3.0, y + 3.0)
	_energy_bar_fill.size = Vector2((w - 6.0) * maxf(0.0, ratio), h - 6.0)
	if super_on:
		_energy_bar_fill.color = Color(1.0, 0.92, 0.42, 0.88 + 0.12 * pulse)
		_energy_bar_label.text = "超级武器  %.1fs" % logic.super_t
		_energy_bar_label.modulate = Color(1.0, 0.94, 0.55, 1.0)
	else:
		_energy_bar_fill.color = Color(0.35, 0.92, 1.0, 0.95) if ratio < 0.98 else Color(1.0, 0.86, 0.32, 0.88 + 0.12 * pulse)
		_energy_bar_label.text = "能量  %d%%" % roundi(ratio * 100.0)
		_energy_bar_label.modulate = Color("A8F4FF")
	_energy_bar_label.add_theme_font_size_override("font_size", 22)
	_energy_bar_label.position = Vector2(x, y - 28.0)
	_energy_bar_label.size = Vector2(w, 26.0)


func _sync_corner_hud(logic: PlaneLogic, delta: float) -> void:
	## 左上：街机信息栏 · 右上：得分/生命 · 底部：火力条
	if _heart_punch > 0.0:
		_heart_punch = maxf(0.0, _heart_punch - delta)
	var on := true
	var col_cap := Color(0.82, 0.94, 1.0, 0.96)
	var col_val := Color(1.0, 0.96, 0.78, 1.0)

	for s in _hearts:
		s.visible = false
	for s in _heart_slots:
		s.visible = false
	for s in _bombs:
		s.visible = false
	for s in _bomb_slots:
		s.visible = false
	if _bomb_label:
		_bomb_label.visible = false
	if _bomb_cap:
		_bomb_cap.visible = false
	for p in _bomb_pips:
		p.visible = false

	## —— 左上角：百万大奖 / 本机奖励 / 下一次 / 投币（字号加大，铺满红框） ——
	var x0 := _play.position.x + 14.0
	var y := _play.position.y + 10.0
	var col_w := 420.0
	if _info_jackpot_cap:
		_info_jackpot_cap.visible = on
		_info_jackpot_cap.text = "百万大奖"
		_info_jackpot_cap.modulate = col_cap
		_info_jackpot_cap.add_theme_font_size_override("font_size", HUD_ARCADE_CAP_FS)
		_info_jackpot_cap.position = Vector2(x0, y)
		_info_jackpot_cap.size = Vector2(col_w, 44.0)
	y += 42.0
	if _info_jackpot_val:
		_info_jackpot_val.visible = on
		_info_jackpot_val.text = _fmt_int(arcade_jackpot)
		_info_jackpot_val.modulate = col_val
		_info_jackpot_val.add_theme_font_size_override("font_size", HUD_ARCADE_JACKPOT_FS)
		_info_jackpot_val.position = Vector2(x0 - 2.0, y - 4.0)
		_info_jackpot_val.size = Vector2(col_w + 20.0, 72.0)
	y += 78.0 + HUD_ARCADE_BLOCK_GAP
	if _info_local_cap:
		_info_local_cap.visible = on
		_info_local_cap.text = "本机奖励"
		_info_local_cap.modulate = col_cap
		_info_local_cap.add_theme_font_size_override("font_size", HUD_ARCADE_CAP_FS)
		_info_local_cap.position = Vector2(x0, y)
		_info_local_cap.size = Vector2(col_w, 44.0)
	y += 42.0
	if _info_local_val:
		_info_local_val.visible = on
		_info_local_val.text = _fmt_int(arcade_local_bonus)
		_info_local_val.modulate = col_val
		_info_local_val.add_theme_font_size_override("font_size", HUD_ARCADE_LOCAL_FS)
		_info_local_val.position = Vector2(x0 - 2.0, y - 4.0)
		_info_local_val.size = Vector2(col_w + 20.0, 68.0)
	y += 74.0 + HUD_ARCADE_BLOCK_GAP
	if _info_next:
		_info_next.visible = on
		_info_next.text = arcade_next_tip
		_info_next.modulate = Color(1.0, 0.92, 0.62, 0.98)
		_info_next.add_theme_font_size_override("font_size", HUD_ARCADE_NEXT_FS)
		_info_next.position = Vector2(x0, y)
		_info_next.size = Vector2(col_w + 40.0, 44.0)
	y += 44.0 + HUD_ARCADE_BLOCK_GAP
	if _info_coin_cap:
		_info_coin_cap.visible = on
		_info_coin_cap.text = "投币"
		_info_coin_cap.modulate = col_cap
		_info_coin_cap.add_theme_font_size_override("font_size", HUD_ARCADE_COIN_CAP_FS)
		_info_coin_cap.position = Vector2(x0, y)
		_info_coin_cap.size = Vector2(col_w, 44.0)
	y += 42.0
	if _info_coin:
		_info_coin.visible = on
		var got := clampi(arcade_coin_in, 0, HUD_COIN_COUNT_MAX)
		var denom := maxi(1, arcade_coin_need)
		var left := "%02d" % got if got < 100 else "%03d" % got
		_info_coin.text = "%s/%02d" % [left, denom]
		_info_coin.modulate = col_val
		_info_coin.add_theme_font_size_override("font_size", HUD_ARCADE_COIN_FS)
		_info_coin.position = Vector2(x0, y)
		_info_coin.size = Vector2(col_w, 58.0)

	## —— 右上角：得分 + 生命（加大字号） ——
	var hud_right := _play.position.x + _play.size.x - 12.0
	var hud_col_w := HUD_TR_COL_W
	var hud_left := hud_right - hud_col_w
	var score_y := _play.position.y + 6.0
	if _score_cap:
		_score_cap.visible = on
		_score_cap.text = "得分"
		_score_cap.modulate = col_cap
		_score_cap.add_theme_font_size_override("font_size", HUD_TR_CAP_FS)
		_score_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_score_cap.position = Vector2(hud_left, score_y)
		_score_cap.size = Vector2(hud_col_w, 36.0)
	if _score_val:
		_score_val.visible = on
		_score_val.text = _fmt_int(logic.score)
		_score_val.modulate = col_val
		_score_val.add_theme_font_size_override("font_size", HUD_TR_SCORE_FS)
		_score_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_score_val.position = Vector2(hud_left - 10.0, score_y + 30.0)
		_score_val.size = Vector2(hud_col_w + 12.0, 76.0)
		var gp := 1.0 + 0.16 * clampf(_score_gem_punch / 0.24, 0.0, 1.0)
		_score_val.pivot_offset = Vector2(_score_val.size.x, _score_val.size.y * 0.42)
		_score_val.scale = Vector2(gp, gp)

	if _life_cap:
		_life_cap.visible = on
		_life_cap.text = "生命"
		_life_cap.modulate = col_cap
		_life_cap.add_theme_font_size_override("font_size", HUD_TR_CAP_FS)
		_life_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_life_cap.position = Vector2(hud_left, score_y + 108.0)
		_life_cap.size = Vector2(hud_col_w, 34.0)
	var life_pop := 1.0 + 0.22 * clampf(_heart_punch / 0.28, 0.0, 1.0)
	var blink := logic.hp == 1 and logic.playing and fmod(_anim, 0.36) < 0.18
	var heart_px := HUD_HEART_PX
	var heart_gap := HUD_HEART_GAP
	var n_hearts := mini(_hearts.size(), 3)
	var total_w := float(n_hearts) * heart_px + float(maxi(0, n_hearts - 1)) * heart_gap
	var life_x0 := hud_right - total_w
	var life_y := score_y + 148.0
	for i in n_hearts:
		var slot: Sprite2D = _heart_slots[i]
		var h: Sprite2D = _hearts[i]
		var filled := on and i < logic.hp
		var side := heart_px * (life_pop if filled else 1.0)
		var cx := life_x0 + float(i) * (heart_px + heart_gap) + heart_px * 0.5
		var cy := life_y + heart_px * 0.5
		if slot:
			slot.visible = false
		if h:
			h.visible = on
			h.position = Vector2(cx, cy)
			h.z_index = 24
			_fit_px(h, side)
			if filled:
				var a := 0.42 if blink and i == 0 else 1.0
				h.modulate = Color(0.95, 0.1, 0.16, a)
			else:
				h.modulate = Color(0.32, 0.07, 0.09, 0.78)


func _build_combo_tower() -> void:
	if _combo_tower_panel != null:
		return
	_load_combo_hud_textures()
	_combo_tower_panel = PlaneComboTower.new()
	_combo_tower_panel.name = "ComboTowerLux"
	_combo_tower_panel.visible = false
	_combo_tower_panel.z_index = COMBO_TOWER_Z + 2
	_combo_tower_panel.segment_total = COMBO_TOWER_SEGS
	add_child(_combo_tower_panel)
	_combo_cap = _mk_hud_cap("连击")
	_combo_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_combo_cap.z_index = COMBO_TOWER_Z + 3
	add_child(_combo_cap)
	_combo_mul_glow_root = Control.new()
	_combo_mul_glow_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_mul_glow_root.z_index = COMBO_TOWER_Z + 3
	add_child(_combo_mul_glow_root)
	_combo_mul_root = Control.new()
	_combo_mul_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_mul_root.z_index = COMBO_TOWER_Z + 5
	add_child(_combo_mul_root)
	_combo_tier_tex = TextureRect.new()
	_combo_tier_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_tier_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_combo_tier_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_combo_tier_tex.z_index = COMBO_TOWER_Z + 4
	add_child(_combo_tier_tex)
	_combo_tier_fly_tex = TextureRect.new()
	_combo_tier_fly_tex.name = "ComboTierFly"
	_combo_tier_fly_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_tier_fly_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_combo_tier_fly_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_combo_tier_fly_tex.z_index = COMBO_TOWER_Z + 12
	_combo_tier_fly_tex.visible = false
	add_child(_combo_tier_fly_tex)


func _combo_tier_fly_keys() -> Array[String]:
	return ["luanwu", "wushuang", "fengshen"]


func _combo_tier_tex_layout(
	tk: String,
	tower_h: float,
	mul_right: float,
	top_y: float,
	label_w: float
) -> Dictionary:
	if tk.is_empty() or not _tex_combo_tiers.has(tk):
		return {}
	var tt: Texture2D = _tex_combo_tiers[tk]
	var th := clampf(tower_h * 0.13, 44.0, 62.0)
	var tw := th
	if tt.get_height() > 0:
		tw = th * float(tt.get_width()) / float(tt.get_height())
	tw = minf(tw, label_w + 72.0)
	th = tw * float(tt.get_height()) / float(maxi(1, tt.get_width()))
	return {
		"texture": tt,
		"pos": Vector2(mul_right - tw, top_y + tower_h * 0.88 - th * 0.5),
		"size": Vector2(tw, th),
	}


func _ease_smooth_step(t: float) -> float:
	var u := clampf(t, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)


func _try_start_combo_tier_fly(
	combo: int,
	prev_combo: int,
	layout: Dictionary,
	play_rect: Rect2
) -> void:
	if combo <= prev_combo or layout.is_empty():
		return
	var tk := _combo_tier_tex_key(combo)
	var old_tk := _combo_tier_tex_key(prev_combo)
	if tk == old_tk or not _combo_tier_fly_keys().has(tk):
		return
	var start := _combo_tier_fly_start_pos_size_for_texture(layout["texture"] as Texture2D, play_rect)
	if start.is_empty():
		return
	_combo_tier_anim_from_pos = start["pos"]
	_combo_tier_anim_from_size = start["size"]
	_combo_tier_anim_to_pos = layout["pos"]
	_combo_tier_anim_to_size = layout["size"]
	_combo_tier_fly_tex.texture = layout["texture"]
	_combo_tier_fly_tex.position = _combo_tier_anim_from_pos
	_combo_tier_fly_tex.size = _combo_tier_anim_from_size
	_combo_tier_fly_tex.scale = Vector2.ONE
	_combo_tier_fly_tex.visible = true
	_combo_tier_anim_t = 0.0
	_combo_punch = maxf(_combo_punch, 0.55)


func _combo_tier_fly_start_pos_size_for_texture(tt: Texture2D, play_rect: Rect2) -> Dictionary:
	if tt == null:
		return {}
	var th := clampf(
		play_rect.size.y * COMBO_TIER_FLY_START_H_FRAC,
		COMBO_TIER_FLY_START_H_MIN,
		COMBO_TIER_FLY_START_H_MAX
	)
	var tw := th
	if tt.get_height() > 0:
		tw = th * float(tt.get_width()) / float(tt.get_height())
	var pos := Vector2(
		play_rect.position.x + play_rect.size.x * 0.5 - tw * 0.5,
		play_rect.position.y + play_rect.size.y * COMBO_TIER_FLY_START_Y_FRAC - th * 0.5
	)
	return {"pos": pos, "size": Vector2(tw, th)}


func _tick_combo_tier_fly(delta: float, beat_flash: float) -> void:
	if _combo_tier_fly_tex == null:
		return
	if _combo_tier_peak_t > 0.0:
		_combo_tier_peak_t = maxf(0.0, _combo_tier_peak_t - delta)
	if _combo_tier_anim_t >= 1.0:
		if _combo_tier_peak_t <= 0.0:
			_combo_tier_fly_tex.visible = false
		return
	var hold := COMBO_TIER_PEAK_HOLD if _combo_tier_peak_t > 0.0 else COMBO_TIER_FLY_HOLD
	var total := hold + COMBO_TIER_FLY_MOVE
	_combo_tier_anim_t = minf(1.0, _combo_tier_anim_t + delta / total)
	var elapsed := _combo_tier_anim_t * total
	var pos: Vector2
	var size: Vector2
	if elapsed <= hold:
		pos = _combo_tier_anim_from_pos
		size = _combo_tier_anim_from_size
	else:
		var move_t := (elapsed - hold) / COMBO_TIER_FLY_MOVE
		var e := _ease_smooth_step(move_t)
		pos = _combo_tier_anim_from_pos.lerp(_combo_tier_anim_to_pos, e)
		size = _combo_tier_anim_from_size.lerp(_combo_tier_anim_to_size, e)
	_combo_tier_fly_tex.position = pos
	_combo_tier_fly_tex.size = size
	_combo_tier_fly_tex.modulate = Color(1, 1, 1, 0.88 + beat_flash * 0.12)
	if _combo_tier_anim_t >= 1.0 and _combo_tier_peak_t <= 0.0:
		_combo_tier_fly_tex.visible = false


func _load_combo_hud_textures() -> void:
	if _tex_combo_mul_x == null:
		var px: String = PATH_COMBO_TOWER + "combo_mul_x.png"
		if ResourceLoader.exists(px):
			_tex_combo_mul_x = load(px) as Texture2D
	if _tex_combo_digits.is_empty():
		for d in 10:
			var dp: String = PATH_COMBO_TOWER + "combo_digit_%d.png" % d
			if ResourceLoader.exists(dp):
				_tex_combo_digits.append(load(dp) as Texture2D)
			else:
				_tex_combo_digits.append(null)
	if _tex_combo_tiers.is_empty():
		for key in ["qishi", "mengong", "luanwu", "wushuang", "fengshen"]:
			var tp: String = PATH_COMBO_TOWER + "combo_tier_%s.png" % key
			if ResourceLoader.exists(tp):
				_tex_combo_tiers[key] = load(tp) as Texture2D


func _combo_tier_tex_key(combo: int) -> String:
	if combo < 3:
		return ""
	if combo < 10:
		return "qishi"
	if combo < PlaneLogic.COMBO_TIER_LUANWU:
		return "mengong"
	if combo < PlaneLogic.COMBO_TIER_WUSHUANG:
		return "luanwu"
	if combo < PlaneLogic.COMBO_TIER_FENGSHEN:
		return "wushuang"
	return "fengshen"


func _tint_combo_mul_root(root: Control, modulate_col: Color) -> void:
	for c in root.get_children():
		if c is CanvasItem:
			(c as CanvasItem).modulate = modulate_col


func _sync_combo_mul_digits(
	root: Control,
	combo: int,
	punch_sc: float,
	modulate_col: Color,
	right_x: float,
	base_y: float,
	glow: bool
) -> void:
	var cache_key := "%d_%.2f_%s" % [combo, punch_sc, "g" if glow else "m"]
	if root.get_meta("cache_key", "") == cache_key:
		_tint_combo_mul_root(root, modulate_col)
		return
	root.set_meta("cache_key", cache_key)
	for c in root.get_children():
		root.remove_child(c)
		c.free()
	if _tex_combo_mul_x == null or _tex_combo_digits.is_empty():
		return
	var digit_h := 46.0 + clampf(float(combo) / 35.0, 0.0, 1.0) * 22.0
	if glow:
		digit_h *= 1.06
	digit_h *= punch_sc
	var x_tex := _tex_combo_mul_x
	var x_h := digit_h * 0.72
	var x_w := x_h
	if x_tex.get_height() > 0:
		x_w = x_h * float(x_tex.get_width()) / float(x_tex.get_height())
	var s := str(maxi(0, combo))
	var total_w := x_w
	for ch in s:
		var di := int(ch) if ch.is_valid_int() else 0
		if di >= 0 and di < _tex_combo_digits.size() and _tex_combo_digits[di] != null:
			var dt: Texture2D = _tex_combo_digits[di]
			var dw := digit_h
			if dt.get_height() > 0:
				dw = digit_h * float(dt.get_width()) / float(dt.get_height())
			total_w += dw * 0.92
	var cursor := right_x - total_w
	var x_rect := TextureRect.new()
	x_rect.texture = x_tex
	x_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	x_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	x_rect.size = Vector2(x_w, x_h)
	x_rect.position = Vector2(cursor, base_y + (digit_h - x_h) * 0.5)
	x_rect.modulate = modulate_col
	root.add_child(x_rect)
	cursor += x_w * 0.85
	for ch in s:
		var di2 := int(ch) if ch.is_valid_int() else 0
		if di2 < 0 or di2 >= _tex_combo_digits.size() or _tex_combo_digits[di2] == null:
			continue
		var dt2: Texture2D = _tex_combo_digits[di2]
		var dw2 := digit_h
		if dt2.get_height() > 0:
			dw2 = digit_h * float(dt2.get_width()) / float(dt2.get_height())
		var dr := TextureRect.new()
		dr.texture = dt2
		dr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		dr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		dr.size = Vector2(dw2, digit_h)
		dr.position = Vector2(cursor, base_y)
		dr.modulate = modulate_col
		root.add_child(dr)
		cursor += dw2 * 0.88
	root.pivot_offset = Vector2(right_x - (right_x - total_w), base_y + digit_h * 0.45)
	root.scale = Vector2.ONE


func _combo_tier_name(combo: int) -> String:
	if combo < 3:
		return ""
	if combo < 10:
		return "起势"
	if combo < PlaneLogic.COMBO_TIER_LUANWU:
		return "猛攻"
	if combo < PlaneLogic.COMBO_TIER_WUSHUANG:
		return "乱舞"
	if combo < PlaneLogic.COMBO_TIER_FENGSHEN:
		return "无双"
	return "封神"


func _combo_tower_palette(combo: int) -> Dictionary:
	if combo < 3:
		return {
			"fill": Color(0.22, 0.55, 0.82, 0.85),
			"hot": Color(0.45, 0.85, 1.0, 0.95),
			"text": Color(0.82, 0.94, 1.0, 0.92),
		}
	if combo < 10:
		return {
			"fill": Color(0.18, 0.72, 0.95, 0.88),
			"hot": Color(0.55, 0.95, 1.0, 1.0),
			"text": Color(0.75, 0.98, 1.0, 1.0),
		}
	if combo < PlaneLogic.COMBO_TIER_LUANWU:
		return {
			"fill": Color(0.95, 0.62, 0.12, 0.9),
			"hot": Color(1.0, 0.85, 0.35, 1.0),
			"text": Color(1.0, 0.88, 0.42, 1.0),
		}
	if combo < PlaneLogic.COMBO_TIER_WUSHUANG:
		return {
			"fill": Color(1.0, 0.42, 0.14, 0.92),
			"hot": Color(1.0, 0.72, 0.28, 1.0),
			"text": Color(1.0, 0.72, 0.32, 1.0),
		}
	if combo < PlaneLogic.COMBO_TIER_FENGSHEN:
		return {
			"fill": Color(0.92, 0.22, 0.55, 0.94),
			"hot": Color(1.0, 0.45, 0.82, 1.0),
			"text": Color(1.0, 0.55, 0.88, 1.0),
		}
	return {
		"fill": Color(0.98, 0.18, 0.62, 0.96),
		"hot": Color(1.0, 0.38, 0.92, 1.0),
		"text": Color(1.0, 0.48, 0.95, 1.0),
	}


func _sync_combo_tower(logic: PlaneLogic, delta: float) -> void:
	if _combo_tower_panel == null:
		return
	if _combo_punch > 0.0:
		_combo_punch = maxf(0.0, _combo_punch - delta * 2.8)
	if _combo_break_t > 0.0:
		_combo_break_t = maxf(0.0, _combo_break_t - delta * 1.85)
	var combo := logic.combo if logic.playing else 0
	var combo_prev_frame := _combo_display_prev
	if combo > _combo_display_prev:
		_combo_punch = maxf(_combo_punch, 0.32 + float(combo - _combo_display_prev) * 0.05)
		_side_beat_pulse = maxf(_side_beat_pulse, 0.4 + clampf(float(combo) / 30.0, 0.0, 1.0) * 0.5)
	elif _combo_display_prev >= 3 and combo == 0:
		_combo_break_t = 0.55
		_combo_punch = maxf(_combo_punch, 0.45)
		if _combo_tier_peak_t <= 0.0:
			_combo_tier_anim_t = 1.0
			if _combo_tier_fly_tex:
				_combo_tier_fly_tex.visible = false
	_combo_display_prev = combo
	var show := logic.playing and (combo >= 1 or _combo_break_t > 0.02)
	_combo_tower_panel.visible = show
	if _combo_cap:
		_combo_cap.visible = show
	if _combo_mul_root:
		_combo_mul_root.visible = show
	if _combo_mul_glow_root:
		_combo_mul_glow_root.visible = show
	if _combo_tier_tex:
		_combo_tier_tex.visible = show and combo >= 3 and _combo_tier_anim_t >= 1.0
	if not show:
		# 封神峰值比连击断档 UI 更久；塔隐藏后仍须 tick，否则 fly 图会常驻
		if _combo_tier_peak_t > 0.0 or (_combo_tier_fly_tex != null and _combo_tier_fly_tex.visible):
			_tick_combo_tier_fly(delta, 0.0)
		return
	var pal := _combo_tower_palette(combo)
	var p := _play
	var tower_h := clampf(p.size.y * COMBO_TOWER_HEIGHT_FRAC, COMBO_TOWER_MIN_H, COMBO_TOWER_MAX_H)
	var tower_w := tower_h * COMBO_TOWER_FRAME_ASPECT
	var center_y := p.position.y + p.size.y * COMBO_TOWER_CENTER_Y_FRAC
	var top_y := center_y - tower_h * 0.5
	var fp_clear := 78.0
	top_y = clampf(top_y, p.position.y + 8.0, p.position.y + p.size.y - tower_h - fp_clear)
	var x_right := p.position.x + p.size.x - 6.0
	var tower_x := x_right - tower_w
	var break_k := clampf(_combo_break_t / 0.55, 0.0, 1.0)
	var punch_sc := 1.0 + 0.18 * clampf(_combo_punch / 0.32, 0.0, 1.0)
	var energy := clampf(_beat_glow / 1.75, 0.0, 1.0)
	var beat_ph := ArcadeAudio.plane_music_beat_phase() if logic.playing else 1.0
	var beat_flash := (1.0 - beat_ph) * (0.35 + energy * 0.55)
	var since_kill := logic.elapsed - logic.last_kill_at
	var decay_warn := combo > 0 and since_kill > PlaneLogic.COMBO_WINDOW * 0.62
	var fill := clampf(float(combo) / COMBO_TOWER_FILL_AT, 0.0, 1.0)
	var lit := clampi(int(round(fill * float(COMBO_TOWER_SEGS))), 0, COMBO_TOWER_SEGS)
	if combo > 0:
		lit = maxi(1, lit)
	if _combo_break_t > 0.0:
		lit = int(float(lit) * (1.0 - break_k * 0.85))
	_combo_tower_panel.position = Vector2(tower_x, top_y)
	_combo_tower_panel.size = Vector2(tower_w, tower_h)
	_combo_tower_panel.combo = combo
	_combo_tower_panel.lit_segments = lit
	_combo_tower_panel.hot_color = pal.hot
	_combo_tower_panel.break_k = break_k
	_combo_tower_panel.decay_warn = decay_warn
	_combo_tower_panel.beat_flash = beat_flash
	_combo_tower_panel.energy = energy
	_combo_tower_panel.punch = clampf(_combo_punch / 0.32, 0.0, 1.0)
	if (
		SIDE_BEAT_IN_COMBO_TOWER
		and not HORIZONTAL_BEAT_ENABLED
		and logic.playing
	):
		_combo_tower_panel.beat_amps = _combo_tower_beat_amps()
		_combo_tower_panel.beat_hue = _rainbow_hue
		_combo_tower_panel.beat_tier = float(_climax_tier)
		_combo_tower_panel.rainbow_beat_v2 = COMBO_TOWER_RAINBOW_BEAT_V2
	else:
		_combo_tower_panel.beat_amps = PackedFloat32Array()
		_combo_tower_panel.rainbow_beat_v2 = false
	_combo_tower_panel.tick(delta)
	var label_w := 188.0
	var label_x := tower_x - label_w - 6.0
	var mul_right := tower_x - 8.0
	var mul_y := top_y - 6.0
	if _combo_cap:
		_combo_cap.text = "连击"
		_combo_cap.modulate = pal.text
		_combo_cap.add_theme_font_size_override("font_size", 32)
		_combo_cap.position = Vector2(label_x, top_y - 42.0)
		_combo_cap.size = Vector2(label_w, 36.0)
	if _combo_mul_glow_root:
		_combo_mul_glow_root.position = Vector2(0, 0)
		_sync_combo_mul_digits(
			_combo_mul_glow_root,
			combo,
			punch_sc * 1.04,
			Color(pal.hot.r, pal.hot.g * 0.85, pal.hot.b * 0.5, 0.42 + beat_flash * 0.38),
			mul_right + 4.0,
			mul_y + 5.0,
			true
		)
	if _combo_mul_root:
		_combo_mul_root.position = Vector2(0, 0)
		_sync_combo_mul_digits(
			_combo_mul_root,
			combo,
			punch_sc,
			pal.text.lightened(0.06),
			mul_right,
			mul_y,
			false
		)
	var tk := _combo_tier_tex_key(combo)
	var tier_layout := _combo_tier_tex_layout(tk, tower_h, mul_right, top_y, label_w)
	_try_start_combo_tier_fly(combo, combo_prev_frame, tier_layout, p)
	_tick_combo_tier_fly(delta, beat_flash)
	if _combo_tier_tex:
		if tier_layout.is_empty():
			_combo_tier_tex.texture = null
		else:
			_combo_tier_tex.texture = tier_layout["texture"]
			_combo_tier_tex.size = tier_layout["size"]
			_combo_tier_tex.position = tier_layout["pos"]
			_combo_tier_tex.modulate = Color(1, 1, 1, 0.92 + beat_flash * 0.08)
			_combo_tier_tex.visible = show and combo >= 3 and _combo_tier_anim_t >= 1.0


func _fmt_int(n: int) -> String:
	## 千分位：752982 → 752,982
	var s := str(maxi(0, n))
	var out := ""
	var cnt := 0
	for i in range(s.length() - 1, -1, -1):
		if cnt > 0 and cnt % 3 == 0:
			out = "," + out
		out = s[i] + out
		cnt += 1
	return out


func rhythm_try_tap() -> Dictionary:
	if _rhythm == null or not _rhythm.window_open:
		return {}
	return _rhythm.try_tap()


func rhythm_flash_hit(judgement: String) -> void:
	_rhythm_hit_flash = 0.4 if judgement == "perfect" else 0.22
	_side_beat_pulse = maxf(_side_beat_pulse, 1.0 if judgement == "perfect" else 0.5)


func rhythm_judge_color(judgement: String) -> Color:
	var bright := 1.15 if judgement == "perfect" else (1.0 if judgement == "good" else 0.75)
	return _rhythm_ring_tint(0.98, bright)


func _rhythm_ring_tint(alpha: float, bright: float = 1.0) -> Color:
	var sat := clampf(0.86 + _beat_glow * 0.10, 0.72, 1.0)
	var c := Color.from_hsv(_rainbow_hue, sat, clampf(0.96 * bright, 0.75, 1.0))
	var pulse := 1.0 + clampf(_beat_glow / 1.75, 0.0, 1.0) * 0.42 + float(_climax_tier) * 0.10
	c.r = minf(1.32, c.r * pulse * bright)
	c.g = minf(1.28, c.g * pulse * bright)
	c.b = minf(1.26, c.b * pulse * bright)
	c.a = alpha
	return c


func _sync_rhythm_center(_logic: PlaneLogic, delta: float) -> void:
	if _rhythm_hit_flash > 0.0:
		_rhythm_hit_flash = maxf(0.0, _rhythm_hit_flash - delta)
	if _rhythm_target:
		_rhythm_target.visible = false
	if _rhythm_approach:
		_rhythm_approach.visible = false
	if _rhythm:
		_rhythm.tick(false)


func _sync_boss_bar(logic: PlaneLogic, delta: float) -> void:
	if _boss_bar_bg == null:
		return
	if _boss_bar_punch > 0.0:
		_boss_bar_punch = maxf(0.0, _boss_bar_punch - delta)
	var bo: Dictionary = logic.live_boss()
	var on := logic.playing and not bo.is_empty()
	_boss_bar_bg.visible = on
	_boss_bar_fill.visible = on
	_boss_bar_label.visible = on
	if _boss_bar_edge:
		_boss_bar_edge.visible = false
	if not on:
		return
	if float(bo.get("flash", 0.0)) > 0.0:
		_boss_bar_punch = 0.12
	var w := minf(300.0, _play.size.x * 0.66)
	var x := _play.position.x + (_play.size.x - w) * 0.5
	var y := _play.position.y + 10.0
	var hp_now := int(bo.get("hp", 0))
	var hp_max := maxi(1, int(bo.get("pipe_max", bo.get("max_hp", 1))))
	var ratio := clampf(float(hp_now) / float(hp_max), 0.0, 1.0)
	var jump := 3.0 * clampf(_boss_bar_punch / 0.12, 0.0, 1.0)
	var st := int(bo.get("boss_style", 0))
	var nm := logic.boss_name_for_style(st)
	var pipe := int(bo.get("pipe", 1))
	var breaking := bool(bo.get("breaking", false))
	var gold := st >= 4 and bool(bo.get("phase2", false))
	if _boss_bar_edge:
		_boss_bar_edge.visible = gold or breaking
		if gold or breaking:
			var pulse := 0.45 + 0.40 * absf(sin(_anim * 8.0))
			_boss_bar_edge.color = Color(1.0, 1.0, 1.0, pulse) if breaking else Color(1.0, 0.82, 0.28, pulse)
			_boss_bar_edge.position = Vector2(x - 3.0, y - 3.0 + jump)
			_boss_bar_edge.size = Vector2(w + 6.0, 20.0)
	_boss_bar_bg.position = Vector2(x, y + jump)
	_boss_bar_bg.size = Vector2(w, 14.0)
	_boss_bar_fill.position = Vector2(x + 2.0, y + 2.0 + jump)
	if breaking:
		_boss_bar_fill.size = Vector2((w - 4.0) * absf(sin(_anim * 22.0)), 10.0)
		_boss_bar_fill.color = Color(1.0, 0.95, 0.85, 0.95)
	else:
		_boss_bar_fill.size = Vector2((w - 4.0) * ratio, 10.0)
		_boss_bar_fill.color = Color(0.95, 0.42, 0.18, 0.95) if pipe >= 2 else Color(0.92, 0.22, 0.28, 0.95)
	var roman := "Ⅱ" if pipe >= 2 else "Ⅰ"
	_boss_bar_label.text = "%s  %s  %d" % [nm, roman, hp_now] if not breaking else "%s  破管" % nm
	_boss_bar_label.position = Vector2(x, y - 18.0 + jump)
	_boss_bar_label.size = Vector2(w, 18.0)


func _place_power_bar(bg: ColorRect, fill: ColorRect, lab: Label, t: float, tmax: float, playing: bool, title: String, col: Color, x: float, y: float, w: float) -> bool:
	var on := t > 0.0 and playing and bg != null
	if bg:
		bg.visible = on
		fill.visible = on
		lab.visible = on
	if not on:
		return false
	var ratio := clampf(t / tmax, 0.0, 1.0)
	bg.position = Vector2(x, y)
	bg.size = Vector2(w, 22.0)
	fill.position = Vector2(x + 3.0, y + 3.0)
	fill.size = Vector2((w - 6.0) * ratio, 16.0)
	fill.color = col
	lab.text = "%s  %.1fs" % [title, t]
	lab.add_theme_font_size_override("font_size", 22)
	lab.position = Vector2(x, y - 28.0)
	lab.size = Vector2(w, 26.0)
	return true


func _ebullet_beat_modulate(idx: int, fat: bool) -> Dictionary:
	var energy := clampf(_beat_glow / 1.75, 0.0, 1.0)
	var punch := _side_beat_pulse
	var flick := 0.78 + energy * 0.42 + punch * 0.38
	flick += absf(sin(_anim * 38.0 + float(idx) * 0.23)) * energy * 0.14
	if punch > 0.35:
		flick += punch * 0.22
	var hc: Color
	if fat:
		## Boss 弹：赤金火球色，和杂兵紫针弹明显区分
		hc = Color(1.0, 0.42 + energy * 0.18, 0.12)
	else:
		hc = Color.from_hsv(fmod(_rainbow_hue + 0.82, 1.0), 0.78, 1.0)
	var core_a := clampf(0.82 + energy * 0.18 + punch * 0.12, 0.0, 1.0)
	var core := Color(hc.r * flick * 1.15, hc.g * flick * 0.92, hc.b * flick * 1.22, core_a)
	if fat:
		core = Color(core.r * 1.12, core.g * 1.05, core.b * 0.95, minf(1.0, core.a + 0.1))
	var glow_a := clampf(0.22 + energy * 0.38 + punch * 0.32, 0.0, 0.92)
	var glow := Color(hc.r * 0.95, hc.g * 0.55, hc.b * 1.05, glow_a * flick)
	if fat:
		glow = Color(1.0, 0.35, 0.08, glow_a * flick)
	return {"core": core, "glow": glow, "scale": 1.0 + energy * 0.08 + punch * 0.12}


func _sync_ebullets(logic: PlaneLogic) -> void:
	var king := false
	var bo: Dictionary = logic.live_boss()
	if not bo.is_empty() and int(bo.get("boss_style", 0)) >= 4:
		king = true
	for i in _ebullet_pool.size():
		var spr := _ebullet_pool[i]
		var glow := _ebullet_glow[i] if i < _ebullet_glow.size() else null
		if i >= logic.ebullets.size() or not bool(logic.ebullets[i]["live"]):
			spr.visible = false
			if glow:
				glow.visible = false
			continue
		var b: Dictionary = logic.ebullets[i]
		var fat := bool(b.get("fat", false))
		var px := EBULLET_PX_KING if fat and king else (EBULLET_PX_BOSS if fat else EBULLET_PX)
		var pos := _to_screen(float(b["x"]), float(b["y"]))
		var vx := float(b.get("vx", 0.0))
		var vy := float(b.get("vy", 0.22))
		var ang := atan2(vx, -vy)
		var tex: Texture2D = _tex_ebullet_boss if fat and _tex_ebullet_boss else (_tex_ebullet if _tex_ebullet else _tex_bullet)
		spr.visible = true
		spr.texture = tex
		spr.position = pos
		spr.rotation = ang
		spr.material = _fx_add_material()
		spr.z_index = 16
		var eb := _ebullet_beat_modulate(i, fat)
		var core: Color = eb["core"]
		if fat and float(b.get("flash", 0.0)) > 0.0:
			core = Color(1.0, 0.92, 0.75, core.a)
		spr.modulate = core
		_fit_px(spr, px * float(eb["scale"]))
		if glow:
			glow.visible = true
			glow.material = _fx_add_material()
			glow.texture = _tex_glow if _tex_glow else tex
			glow.position = pos
			glow.rotation = ang
			glow.z_index = 15
			var gcol: Color = eb["glow"]
			if fat and float(b.get("flash", 0.0)) > 0.0:
				gcol = Color(1.0, 0.85, 0.45, minf(1.0, gcol.a + 0.25))
			glow.modulate = gcol
			_fit_px(glow, px * 1.45 * float(eb["scale"]))


func _sync_warns(logic: PlaneLogic) -> void:
	var used := 0
	for e in logic.enemies:
		if used >= _warn_lines.size():
			break
		if not bool(e["live"]):
			continue
		var hold := float(e.get("hold_t", 0.0)) > 0.0
		if float(e.get("warn_t", 0.0)) <= 0.0 and not hold:
			continue
		var ln := _warn_lines[used]
		ln.visible = true
		ln.clear_points()
		if hold:
			ln.add_point(_to_screen(float(e["x"]), float(e["y"])))
			ln.add_point(_to_screen(float(e["x"]), minf(0.92, float(e["y"]) + 0.22)))
			ln.width = 3.2
			ln.default_color = Color(1.0, 0.82, 0.28, 0.42 + 0.22 * sin(_anim * 14.0))
		else:
			ln.add_point(_to_screen(float(e["x"]), float(e["y"])))
			ln.add_point(_to_screen(float(e.get("aim_x", e["x"])), logic.player_y))
			ln.width = 4.2 if bool(e.get("is_boss", false)) else 3.0
			ln.default_color = Color(1.0, 0.22, 0.25, 0.55 + 0.35 * sin(_anim * 18.0))
		used += 1
	for i in range(used, _warn_lines.size()):
		_warn_lines[i].visible = false


func _sync_items(logic: PlaneLogic) -> void:
	for i in _item_pool.size():
		var spr := _item_pool[i]
		if i >= logic.items.size() or not bool(logic.items[i]["live"]):
			spr.visible = false
			continue
		var it: Dictionary = logic.items[i]
		var k := int(it["kind"])
		spr.texture = _tex_items[k] if k < _tex_items.size() else _tex_star
		spr.position = _to_screen(float(it["x"]), float(it["y"]))
		_fit_px(spr, ITEM_PX * (0.95 + 0.08 * sin(_anim * 7.0 + float(i))))
		spr.visible = true


func _tick_stars(delta: float) -> void:
	for i in _stars.size():
		if _star_life[i] <= 0.0:
			_stars[i].visible = false
			continue
		_star_life[i] -= delta
		_star_vel[i] *= maxf(0.0, 1.0 - 0.85 * delta)
		_stars[i].position += _star_vel[i] * delta
		_stars[i].rotation = _star_vel[i].angle() if _star_vel[i].length() > 1.0 else _stars[i].rotation
		var mx := _star_max[i] if i < _star_max.size() and _star_max[i] > 0.001 else 0.50
		var k := 1.0 - clampf(_star_life[i] / mx, 0.0, 1.0)
		var a := clampf((1.0 - k) * 1.15, 0.0, 1.0)
		if int(_anim * 36.0 + float(i) * 3.0) % 2 == 0:
			a *= 0.72
		_stars[i].modulate.a = a
		_stars[i].visible = _star_life[i] > 0.0


func _pop_scale(k: float) -> float:
	## 0→爆开过冲→回落，给击破字和爆炸一点「炸开」的手感
	if k < 0.14:
		return lerpf(0.38, 1.48, k / 0.14)
	if k < 0.30:
		return lerpf(1.48, 1.08, (k - 0.14) / 0.16)
	return 1.08


func _tick_floats(delta: float) -> void:
	for i in _floats.size():
		if _float_life[i] <= 0.0:
			_floats[i].visible = false
			_floats[i].scale = Vector2.ONE
			continue
		_float_life[i] -= delta
		var mx := _float_max[i] if i < _float_max.size() and _float_max[i] > 0.001 else 0.92
		var k := 1.0 - clampf(_float_life[i] / mx, 0.0, 1.0)
		var sc := _pop_scale(k)
		_floats[i].scale = Vector2(sc, sc)
		var tilt0 := _float_tilt[i] if i < _float_tilt.size() else 0.0
		_floats[i].rotation_degrees = tilt0 + sin((_anim + float(i)) * 7.0) * 3.5
		_floats[i].position.y -= 54.0 * delta
		_floats[i].modulate.a = clampf(_float_life[i] * 1.35, 0.0, 1.0)
		_floats[i].visible = _float_life[i] > 0.0


func _free_star() -> int:
	for i in _stars.size():
		if _star_life[i] <= 0.0:
			return i
	return -1


func _free_boom() -> int:
	for i in _booms.size():
		if _boom_life[i] <= 0.0:
			return i
	return -1


func _tick_booms(delta: float) -> void:
	for i in _booms.size():
		if _boom_life[i] <= 0.0:
			_booms[i].visible = false
			continue
		_boom_life[i] -= delta
		var life := _boom_life[i]
		if life <= 0.0:
			_booms[i].visible = false
			continue
		var mx := _boom_max[i] if i < _boom_max.size() and _boom_max[i] > 0.001 else 0.30
		var k := 1.0 - clampf(life / mx, 0.0, 1.0)
		var kind := int(_boom_set[i]) if i < _boom_set.size() else FX_GLOW
		var px := _boom_px[i] if i < _boom_px.size() and _boom_px[i] > 1.0 else 96.0
		_booms[i].texture = _fx_tex(kind)
		_booms[i].material = _fx_add_material()
		var sc := 1.0
		var a := 1.0
		match kind:
			FX_FLASH:
				sc = 1.08 - 0.22 * k
				a = 1.0 if k < 0.30 else clampf(1.0 - (k - 0.30) / 0.70, 0.0, 1.0)
			FX_BLOOM:
				sc = 0.55 + 1.65 * (1.0 - pow(1.0 - k, 1.25))
				a = clampf((1.0 - k) * 0.42, 0.0, 1.0)
			FX_GLOW:
				sc = 0.48 + 1.55 * (1.0 - pow(1.0 - k, 1.4))
				a = clampf(1.0 - k * 0.95, 0.0, 1.0)
			FX_RING:
				sc = 0.32 + 1.95 * k
				a = clampf((1.0 - k) * 1.05, 0.0, 1.0)
			FX_STAR:
				sc = 0.58 + 1.35 * k
				a = clampf(1.0 - k * 1.1, 0.0, 1.0)
			_:
				sc = 0.5 + 1.2 * k
				a = 1.0 - k
		_fit_px(_booms[i], px * sc)
		if i < _boom_rot.size():
			_booms[i].rotation = _boom_rot[i] + (k * 0.8 if kind == FX_STAR else 0.0)
		_booms[i].modulate.a = a
		_booms[i].visible = true


func _fx_tex(kind: int) -> Texture2D:
	match kind:
		FX_FLASH:
			if _tex_flash:
				return _tex_flash
		FX_RING:
			if _tex_ring_fx:
				return _tex_ring_fx
		FX_STAR:
			if _tex_star8:
				return _tex_star8
		FX_BLOOM, FX_GLOW:
			if _tex_glow:
				return _tex_glow
		_:
			if _tex_glow:
				return _tex_glow
	if _tex_glow:
		return _tex_glow
	return _tex_star


func _boom_frame_tex(frame: int, set_id: int) -> Texture2D:
	var pack: Array[Texture2D]
	match set_id:
		1:
			pack = _tex_boom_m
		2:
			pack = _tex_boom_l
		3:
			pack = _tex_boom_b
		_:
			pack = _tex_boom_s
	if frame >= 0 and frame < pack.size() and pack[frame]:
		return pack[frame]
	if set_id == 3 and _tex_boom_boss:
		return _tex_boom_boss
	if not _tex_boom_s.is_empty() and _tex_boom_s[0]:
		return _tex_boom_s[0]
	return _tex_star


func _sync_wings(logic: PlaneLogic) -> void:
	for i in _wings.size():
		var spr := _wings[i]
		var tr := _wing_trails[i] if i < _wing_trails.size() else null
		if i >= logic.wings.size() or not bool(logic.wings[i].get("live", false)):
			spr.visible = false
			if tr:
				tr.visible = false
			continue
		var w: Dictionary = logic.wings[i]
		var pos := _to_screen(float(w["x"]), float(w["y"]))
		## 火力 3 起僚机已画进玩家贴图，不再叠一层程序僚机
		if not _tex_players.is_empty() and logic.power_lv >= 2:
			spr.visible = false
			if tr:
				tr.visible = false
			continue
		spr.visible = true
		spr.texture = _player_tex_for(mini(logic.power_lv, 1))
		spr.position = pos
		_fit_py(spr, 46.0)
		spr.modulate = Color(0.92, 0.96, 1.0, 0.95)
		if tr:
			tr.visible = true
			tr.clear_points()
			tr.add_point(pos)
			tr.add_point(pos + Vector2(0, 22))
			tr.default_color = Color(1.0, 0.55, 0.18, 0.50) if logic.power_lv >= 5 else Color(0.55, 0.9, 1.0, 0.42)
			tr.width = 2.0


func _boss_muzzle_offs(st: int) -> Array:
	if st == 0:
		return BossMuzzleLayout.boss1_muzzle_offs(_play.size)
	if st == 1:
		return BossMuzzleLayout.boss2_muzzle_offs(_play.size)
	if st == 2:
		return BossMuzzleLayout.boss3_muzzle_offs(_play.size)
	if st == 3:
		return BossMuzzleLayout.boss4_muzzle_offs(_play.size)
	if st == 4:
		return BossMuzzleLayout.boss5_muzzle_offs(_play.size)
	if st >= 0 and st < MUZZLE_OFFS.size() and not MUZZLE_OFFS[st].is_empty():
		return MUZZLE_OFFS[st]
	return MUZZLE_OFFS[1] if MUZZLE_OFFS.size() > 1 else []


func _sync_muzzles(logic: PlaneLogic) -> void:
	var bo: Dictionary = logic.live_boss()
	var on := logic.playing and not bo.is_empty() and logic.boss_phase >= 4
	var st := int(bo.get("boss_style", 0)) if on else 0
	var offs: Array = _boss_muzzle_offs(st)
	for i in _muzzle_glows.size():
		var spr := _muzzle_glows[i]
		if not on or i >= offs.size():
			spr.visible = false
			continue
		var off: Vector2 = offs[i]
		spr.visible = true
		var mi := int(bo.get("muzzle_i", -1))
		var flashing := float(bo.get("flash", 0.0)) > 0.04 and (mi < 0 or i == mi)
		spr.material = _fx_add_material()
		spr.texture = _tex_flash if flashing and _tex_flash else (_tex_glow if _tex_glow else (_tex_muzzle if _tex_muzzle else _tex_ebullet))
		spr.position = _to_screen(float(bo["x"]) + off.x, float(bo["y"]) + off.y)
		var pulse := 1.0 + 0.22 * sin(_anim * 14.0 + float(i))
		_fit_px(spr, (38.0 if flashing else 22.0) * pulse * (1.0 if not flashing else (0.90 + 0.18 * absf(sin(_anim * 36.0)))))
		spr.modulate = Color(1.4, 1.0, 0.38, 0.95) if flashing else Color(1.15, 0.38, 0.14, 0.48)


func _sync_sweep(logic: PlaneLogic) -> void:
	if _sweep_beam == null:
		return
	var telegraph := false
	var tx := logic.sweep_x
	var ty := logic.sweep_y
	var kind := logic.sweep_kind
	for e in logic.enemies:
		if bool(e.get("is_boss", false)) and float(e.get("sweep_arm", 0.0)) > 0.0:
			telegraph = true
			tx = logic.sweep_x
			ty = logic.sweep_y
			kind = logic.sweep_kind
			break
	if _sweep_warn:
		var show_w := telegraph and logic.playing
		_sweep_warn.visible = show_w
		if show_w:
			_sweep_warn.clear_points()
			if kind == 1:
				_sweep_warn.add_point(_to_screen(tx, 0.02))
				_sweep_warn.add_point(_to_screen(tx, 0.96))
			else:
				_sweep_warn.add_point(_to_screen(0.04, ty))
				_sweep_warn.add_point(_to_screen(0.96, ty))
			_sweep_warn.width = 4.0
			_sweep_warn.default_color = Color(1.0, 0.32, 0.22, 0.38 + 0.28 * sin(_anim * 18.0))
	var vert := logic.sweep_on and logic.sweep_kind == 1 and logic.playing
	var horz := logic.sweep_on and logic.sweep_kind == 2 and logic.playing
	_sweep_beam.visible = (vert or horz)
	if vert:
		var bx := _to_screen(logic.sweep_x, 0.5).x
		var w := _play.size.x * 0.085
		_sweep_beam.position = Vector2(bx - w * 0.5, 0.0)
		_sweep_beam.size = Vector2(w, _play.size.y)
		_sweep_beam.color = Color(1.0, 0.28, 0.18, 0.38 + 0.12 * sin(_anim * 10.0))
	elif horz:
		var c := _to_screen(logic.sweep_x, logic.sweep_y)
		var bw := maxf(36.0, _play.size.x * logic.sweep_w)
		var bh := maxf(10.0, _play.size.y * 0.028)
		_sweep_beam.position = Vector2(c.x - bw * 0.5, c.y - bh * 0.5)
		_sweep_beam.size = Vector2(bw, bh)
		_sweep_beam.color = Color(1.0, 0.42, 0.28, 0.52 + 0.16 * sin(_anim * 14.0))


func _sync_warning(logic: PlaneLogic) -> void:
	if _warning_label == null:
		return
	var on := logic.warning_t > 0.0 and logic.playing
	_warning_label.visible = on
	if not on:
		return
	var pw := _play.size.x
	var ph := _play.size.y
	var cx := _play.position.x + pw * 0.5
	## 强闪：亮/半亮交替，不再淡到几乎看不见
	var blink := fmod(logic.warning_t * 5.2, 1.0) < 0.58
	var pulse := 1.0 + 0.06 * sin(_anim * 22.0)
	_warning_label.text = "!! WARNING !!"
	_warning_label.add_theme_font_size_override("font_size", 78)
	_warning_label.add_theme_constant_override("outline_size", 18)
	_warning_label.add_theme_color_override("font_outline_color", Color(0.08, 0.0, 0.0, 1.0))
	_warning_label.add_theme_color_override("font_shadow_color", Color(1.0, 0.15, 0.05, 0.75 if blink else 0.35))
	_warning_label.add_theme_constant_override("shadow_offset_x", 0)
	_warning_label.add_theme_constant_override("shadow_offset_y", 0)
	_warning_label.modulate = Color(1.0, 0.18 if blink else 0.42, 0.12, 1.0 if blink else 0.72)
	_warning_label.size = Vector2(pw * 0.92, 96.0)
	_warning_label.pivot_offset = Vector2(_warning_label.size.x * 0.5, 48.0)
	_warning_label.scale = Vector2(pulse, pulse)
	_warning_label.position = Vector2(cx - _warning_label.size.x * 0.5 * pulse, _play.position.y + ph * 0.34)
	_warning_label.z_index = 46


func _sync_boss_title(delta: float) -> void:
	if _title_t > 0.0:
		_title_t -= delta
	var on := _title_t > 0.0
	var tk := 1.0 - clampf(_title_t / 1.20, 0.0, 1.0)
	var sc := _pop_scale(tk) if on else 1.0
	var fade := 1.0
	if on:
		## 前段满亮，尾段才淡出
		fade = clampf(_title_t / 0.28, 0.0, 1.0) if _title_t < 0.28 else 1.0
	var pw := _play.size.x
	var ph := _play.size.y
	var cx := _play.position.x + pw * 0.5
	if _boss_title:
		_boss_title.visible = on
		if on:
			_boss_title.text = _title_name
			_boss_title.add_theme_font_size_override("font_size", 68)
			_boss_title.add_theme_constant_override("outline_size", 16)
			_boss_title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.42, 1.0))
			_boss_title.add_theme_color_override("font_outline_color", Color(0.12, 0.04, 0.0, 1.0))
			_boss_title.modulate = Color(1.05, 1.0, 0.85, fade)
			_boss_title.size = Vector2(pw * 0.9, 78.0)
			_boss_title.pivot_offset = Vector2(_boss_title.size.x * 0.5, 39.0)
			_boss_title.scale = Vector2(sc, sc)
			_boss_title.position = Vector2(cx - _boss_title.size.x * 0.5 * sc, _play.position.y + ph * 0.30)
			_boss_title.z_index = 46
		else:
			_boss_title.scale = Vector2.ONE
	if _boss_sub:
		_boss_sub.visible = on
		if on:
			_boss_sub.text = _title_sub
			_boss_sub.add_theme_font_size_override("font_size", 36)
			_boss_sub.add_theme_constant_override("outline_size", 12)
			_boss_sub.add_theme_color_override("font_color", Color(1.0, 0.78, 0.82, 1.0))
			_boss_sub.modulate = Color(1, 1, 1, fade)
			_boss_sub.size = Vector2(pw * 0.88, 44.0)
			_boss_sub.pivot_offset = Vector2(_boss_sub.size.x * 0.5, 22.0)
			_boss_sub.scale = Vector2(sc, sc)
			_boss_sub.position = Vector2(cx - _boss_sub.size.x * 0.5 * sc, _play.position.y + ph * 0.42)
			_boss_sub.z_index = 46
		else:
			_boss_sub.scale = Vector2.ONE


func _layout_announce_fx(logic: PlaneLogic) -> void:
	if _announce_veil == null:
		return
	var warn_on := logic.warning_t > 0.0 and logic.playing
	var title_on := _title_t > 0.0
	var on := warn_on or title_on
	_announce_veil.visible = on
	if _announce_bar:
		_announce_bar.visible = on
	if _announce_bar2:
		_announce_bar2.visible = on
	if not on:
		return
	var pw := _play.size.x
	var ph := _play.size.y
	var ox := _play.position.x
	var oy := _play.position.y
	_announce_veil.position = Vector2(ox, oy)
	_announce_veil.size = Vector2(pw, ph)
	_announce_veil.z_index = 44
	if warn_on:
		var flash := fmod(logic.warning_t * 5.2, 1.0) < 0.58
		_announce_veil.color = Color(0.55, 0.02, 0.04, 0.42 if flash else 0.28)
		var bar_h := ph * 0.16
		_announce_bar.position = Vector2(ox, oy + ph * 0.30)
		_announce_bar.size = Vector2(pw, bar_h)
		_announce_bar.color = Color(0.85, 0.05, 0.08, 0.72 if flash else 0.48)
		_announce_bar.z_index = 45
		_announce_bar2.position = Vector2(ox, oy + ph * 0.30 + bar_h - 4.0)
		_announce_bar2.size = Vector2(pw, 4.0)
		_announce_bar2.color = Color(1.0, 0.85, 0.25, 0.95 if flash else 0.55)
		_announce_bar2.z_index = 45
	else:
		_announce_veil.color = Color(0.02, 0.02, 0.08, 0.46)
		var bar_h := ph * 0.22
		_announce_bar.position = Vector2(ox, oy + ph * 0.26)
		_announce_bar.size = Vector2(pw, bar_h)
		_announce_bar.color = Color(0.08, 0.05, 0.02, 0.78)
		_announce_bar.z_index = 45
		_announce_bar2.position = Vector2(ox, oy + ph * 0.26)
		_announce_bar2.size = Vector2(pw, 5.0)
		_announce_bar2.color = Color(1.0, 0.78, 0.22, 0.9)
		_announce_bar2.z_index = 45


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	_load_textures()
	_ensure_trail_gradient()

	_cabinet = ColorRect.new()
	_cabinet.color = COL_CABINET
	_cabinet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cabinet)

	_shake_root = Node2D.new()
	_shake_root.name = "ShakeRoot"
	add_child(_shake_root)

	_side_stars_a = _mk_sprite(_tex_stars)
	_side_stars_b = _mk_sprite(_tex_stars)
	_side_stars_a.visible = false
	_side_stars_b.visible = false
	_shake_root.add_child(_side_stars_a)
	_shake_root.add_child(_side_stars_b)

	_play_clip = Control.new()
	_play_clip.name = "PlayClip"
	_play_clip.clip_contents = true
	_play_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shake_root.add_child(_play_clip)

	var play_bg := ColorRect.new()
	play_bg.name = "PlayFill"
	play_bg.color = Color(0.04, 0.07, 0.13, 1)
	play_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	play_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_play_clip.add_child(play_bg)
	_play_fill = play_bg

	_sky_a = _mk_sprite(_tex_sky)
	_sky_b = _mk_sprite(_tex_sky)
	_stars_a = _mk_sprite(_tex_stars)
	_stars_b = _mk_sprite(_tex_stars)
	_cloud_a = _mk_sprite(_tex_cloud)
	_cloud_b = _mk_sprite(_tex_cloud)
	_cloud_a.visible = false
	_cloud_b.visible = false
	_play_clip.add_child(_sky_a)
	_play_clip.add_child(_sky_b)
	_play_clip.add_child(_stars_a)
	_play_clip.add_child(_stars_b)
	_play_clip.add_child(_cloud_a)
	_play_clip.add_child(_cloud_b)
	_setup_sky_shader_panel()
	_boss_dim = ColorRect.new()
	_boss_dim.visible = false
	_boss_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_dim.color = Color(0.02, 0.02, 0.06, 0.22)
	_boss_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_play_clip.add_child(_boss_dim)
	_laser_beam = _mk_sprite(_tex_laser_beam)
	_laser_beam.centered = false
	_laser_beam.visible = false
	_laser_beam.z_index = 3
	_play_clip.add_child(_laser_beam)
	_super_beams.clear()
	_super_halos.clear()
	_super_cores.clear()
	_super_muzzles.clear()
	_super_impacts.clear()
	for i in 3:
		var halo := _mk_sprite(_tex_gold_halo if _tex_gold_halo else _tex_laser_beam)
		halo.centered = true
		halo.visible = false
		halo.z_index = 3
		_play_clip.add_child(halo)
		_super_halos.append(halo)
		var beam := _mk_sprite(_tex_gold_beam if _tex_gold_beam else _tex_laser_beam)
		beam.centered = true
		beam.visible = false
		beam.z_index = 4
		_play_clip.add_child(beam)
		_super_beams.append(beam)
		var core := _mk_sprite(_tex_gold_core if _tex_gold_core else _tex_laser_beam)
		core.centered = true
		core.visible = false
		core.z_index = 5
		_play_clip.add_child(core)
		_super_cores.append(core)
	_sweep_beam = ColorRect.new()
	_sweep_beam.visible = false
	_sweep_beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sweep_beam.color = Color(1.0, 0.28, 0.18, 0.4)
	_play_clip.add_child(_sweep_beam)
	_sweep_warn = Line2D.new()
	_sweep_warn.width = 5.0
	_sweep_warn.visible = false
	_sweep_warn.antialiased = false
	_play_clip.add_child(_sweep_warn)

	for i in PlaneLogic.MAX_ENEMIES:
		var sh := _mk_sprite(_tex_shadow)
		sh.visible = false
		sh.modulate = Color(1, 1, 1, 0.55)
		_play_clip.add_child(sh)
		_enemy_shadows.append(sh)
		var s := _mk_sprite(_tex_enemies[0])
		s.visible = false
		s.material = _ship_lit_material()
		_play_clip.add_child(s)
		_enemy_pool.append(s)
	for i in PlaneLogic.MAX_BOSS_PARTS:
		var bp := _mk_sprite(_tex_bosses[0] if _tex_bosses.size() > 0 else _tex_enemies[0])
		bp.visible = false
		bp.z_index = 11
		bp.material = _ship_lit_material()
		_play_clip.add_child(bp)
		_boss_part_pool.append(bp)
	for i in PlaneLogic.MAX_BULLETS:
		var st := _mk_sprite(_tex_trail if _tex_trail else _tex_glow)
		st.visible = false
		st.centered = true
		st.z_index = 3
		st.material = _fx_add_material()
		_play_clip.add_child(st)
		_bullet_streaks.append(st)
		var gl := _mk_sprite(_tex_glow if _tex_glow else _tex_bullet)
		gl.visible = false
		gl.z_index = 8
		gl.material = _fx_add_material()
		_play_clip.add_child(gl)
		_bullet_glows.append(gl)
		var tr := Line2D.new()
		tr.width = 2.4
		tr.visible = false
		tr.z_index = 9
		tr.antialiased = false
		tr.material = _fx_add_material()
		_play_clip.add_child(tr)
		_bullet_trails.append(tr)
		var s := _mk_sprite(_tex_bullet)
		s.visible = false
		s.z_index = 10
		s.material = null
		_play_clip.add_child(s)
		_bullet_pool.append(s)
	for i in PlaneLogic.MAX_BULLETS * BULLET_BEAD_MAX:
		var bd := _mk_sprite(_tex_star8 if _tex_star8 else _tex_spark)
		bd.visible = false
		bd.centered = true
		bd.z_index = 8
		bd.material = _fx_add_material()
		_play_clip.add_child(bd)
		_bullet_beads.append(bd)
	for i in PlaneLogic.MAX_EBULLETS:
		var g := _mk_sprite(_tex_ebullet if _tex_ebullet else _tex_bullet)
		g.visible = false
		g.modulate = Color(1.0, 0.28, 0.10, 0.38)
		g.z_index = 8
		g.material = _fx_add_material()
		_play_clip.add_child(g)
		_ebullet_glow.append(g)
		var s := _mk_sprite(_tex_ebullet if _tex_ebullet else _tex_bullet)
		s.visible = false
		s.z_index = 10
		_play_clip.add_child(s)
		_ebullet_pool.append(s)
	for i in MAX_WARNS:
		var ln := Line2D.new()
		ln.width = 3.0
		ln.visible = false
		ln.antialiased = false
		_play_clip.add_child(ln)
		_warn_lines.append(ln)
	for i in PlaneLogic.MAX_ITEMS:
		var s := _mk_sprite(_tex_star)
		s.visible = false
		_play_clip.add_child(s)
		_item_pool.append(s)

	_player_shadow = _mk_sprite(_tex_shadow)
	_player_shadow.modulate = Color(1, 1, 1, 0.6)
	_play_clip.add_child(_player_shadow)
	_lock_ring = _mk_sprite(_tex_bomb)
	_lock_ring.modulate = Color(1, 1, 1, 0.45)
	_play_clip.add_child(_lock_ring)
	_rhythm = _RhythmScript.new()
	_rhythm_target = _mk_sprite(_tex_rhythm_ring if _tex_rhythm_ring else _tex_ring)
	_rhythm_approach = _mk_sprite(_tex_rhythm_ring if _tex_rhythm_ring else _tex_ring)
	_rhythm_target.centered = true
	_rhythm_approach.centered = true
	_rhythm_target.visible = false
	_rhythm_approach.visible = false
	var ring_add := _fx_add_material()
	_rhythm_target.material = ring_add
	_rhythm_approach.material = ring_add
	_rhythm_target.z_index = 30
	_rhythm_approach.z_index = 31
	_play_clip.add_child(_rhythm_target)
	_play_clip.add_child(_rhythm_approach)
	_player = _mk_sprite(_tex_player)
	_player.material = _ship_lit_material()
	_player.z_index = 7
	_play_clip.add_child(_player)
	_muzzle = _mk_sprite(_tex_muzzle if _tex_muzzle else _tex_bullet)
	_muzzle.modulate = Color(1.2, 1.0, 0.55, 1)
	_muzzle.material = _fx_add_material()
	_muzzle.z_index = 11
	_muzzle.visible = false
	_play_clip.add_child(_muzzle)
	_laser_muzzle_fx = _mk_sprite(_tex_laser_muzzle if _tex_laser_muzzle else _tex_muzzle)
	_laser_muzzle_fx.visible = false
	_laser_muzzle_fx.z_index = 6
	_play_clip.add_child(_laser_muzzle_fx)
	_laser_impact = _mk_sprite(_tex_laser_impact if _tex_laser_impact else _tex_star)
	_laser_impact.visible = false
	_laser_impact.z_index = 4
	_play_clip.add_child(_laser_impact)
	for i in 3:
		var hit := _mk_sprite(_tex_gold_impact if _tex_gold_impact else _tex_star)
		hit.visible = false
		hit.z_index = 5
		_play_clip.add_child(hit)
		_super_impacts.append(hit)
		var mz := _mk_sprite(_tex_gold_muzzle if _tex_gold_muzzle else _tex_muzzle)
		mz.visible = false
		mz.z_index = 6
		_play_clip.add_child(mz)
		_super_muzzles.append(mz)
	var shield_tex: Texture2D = _tex_ring_fx if _tex_ring_fx else (_tex_glow if _tex_glow else _tex_bomb)
	_shield_ring = _mk_sprite(shield_tex)
	_shield_ring.material = _fx_add_material()
	_shield_ring.z_index = 8
	_shield_ring.modulate = Color(0.55, 0.95, 1.0, 0.7)
	_shield_ring.visible = false
	_play_clip.add_child(_shield_ring)

	_star_life.resize(PlaneLogic.MAX_FX)
	_star_max.resize(PlaneLogic.MAX_FX)
	var spark0: Texture2D = _tex_spark if _tex_spark else _tex_star
	for i in PlaneLogic.MAX_FX:
		var s := _mk_sprite(spark0)
		s.visible = false
		s.material = _fx_add_material()
		_play_clip.add_child(s)
		_stars.append(s)
		_star_vel.append(Vector2.ZERO)
		_star_life[i] = 0.0
		_star_max[i] = 0.0
	_boom_life.resize(MAX_BOOM_SPR)
	_boom_max.resize(MAX_BOOM_SPR)
	_boom_px.resize(MAX_BOOM_SPR)
	_boom_set.resize(MAX_BOOM_SPR)
	_boom_rot.resize(MAX_BOOM_SPR)
	var boom0: Texture2D = _tex_glow if _tex_glow else (_tex_boom_s[0] if not _tex_boom_s.is_empty() else _tex_star)
	for i in MAX_BOOM_SPR:
		var bspr := _mk_sprite(boom0)
		bspr.visible = false
		bspr.z_index = 7
		bspr.material = _fx_add_material()
		_play_clip.add_child(bspr)
		_booms.append(bspr)
		_boom_life[i] = 0.0
		_boom_max[i] = 0.0
		_boom_px[i] = 64.0
		_boom_set[i] = 0
		_boom_rot[i] = 0.0
	for i in PlaneLogic.MAX_WINGS:
		var wtr := Line2D.new()
		wtr.width = 2.0
		wtr.visible = false
		wtr.antialiased = false
		_play_clip.add_child(wtr)
		_wing_trails.append(wtr)
		var wspr := _mk_sprite(_tex_player)
		wspr.visible = false
		wspr.material = _ship_lit_material()
		_play_clip.add_child(wspr)
		_wings.append(wspr)
	for i in 3:
		var mz := _mk_sprite(_tex_muzzle if _tex_muzzle else _tex_ebullet)
		mz.visible = false
		_play_clip.add_child(mz)
		_muzzle_glows.append(mz)
	_bomb_ring = _mk_sprite(_tex_ring if _tex_ring else _tex_bomb)
	_bomb_ring.visible = false
	_play_clip.add_child(_bomb_ring)

	_frames.clear()
	for i in 8:
		var fr := ColorRect.new()
		fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fr.color = COL_BEZEL if i < 4 else COL_BEZEL_GOLD
		add_child(fr)
		_frames.append(fr)
	_bezel = _frames[0]
	_bezel_gold = _frames[4]
	_lock_ring.visible = false

	_build_side_beat_spectrum()
	_build_horizontal_beat_spectrum()
	_build_combo_tower()

	_pickup_flash = ColorRect.new()
	_pickup_flash.visible = false
	_pickup_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pickup_flash)
	_hurt = ColorRect.new()
	_hurt.visible = false
	_hurt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hurt)
	_bomb_flash = ColorRect.new()
	_bomb_flash.visible = false
	_bomb_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bomb_flash.material = null
	add_child(_bomb_flash)
	_low_hp_edges.clear()
	for i in 4:
		var edge := ColorRect.new()
		edge.visible = false
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(edge)
		_low_hp_edges.append(edge)

	_wave_label = _mk_label(40, Color("FFF4C0"))
	_outline(_wave_label)
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_wave_label)
	_flash_label = _mk_label(36, Color("F5D76E"))
	_outline(_flash_label)
	_flash_label.add_theme_constant_override("outline_size", 12)
	_flash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_flash_label)
	_announce_veil = ColorRect.new()
	_announce_veil.visible = false
	_announce_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_announce_veil.z_index = 44
	add_child(_announce_veil)
	_announce_bar = ColorRect.new()
	_announce_bar.visible = false
	_announce_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_announce_bar.z_index = 45
	add_child(_announce_bar)
	_announce_bar2 = ColorRect.new()
	_announce_bar2.visible = false
	_announce_bar2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_announce_bar2.z_index = 45
	add_child(_announce_bar2)
	_countdown_veil = ColorRect.new()
	_countdown_veil.visible = false
	_countdown_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_countdown_veil.color = Color(0.04, 0.01, 0.02, 0.62)
	_countdown_veil.z_index = 48
	add_child(_countdown_veil)
	_countdown_num = _mk_label(210, Color("F6D056"))
	_outline(_countdown_num)
	_countdown_num.add_theme_constant_override("outline_size", 30)
	_countdown_num.add_theme_color_override("font_outline_color", Color("6A3A08"))
	_countdown_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_countdown_num.z_index = 51
	add_child(_countdown_num)
	_countdown_plate = null
	_countdown_ready = _mk_label(22, Color("E8C050"))
	_outline(_countdown_ready)
	_countdown_ready.add_theme_constant_override("outline_size", 8)
	_countdown_ready.add_theme_color_override("font_outline_color", Color("4A2A08"))
	_countdown_ready.text = "GET READY"
	_countdown_ready.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_ready.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_countdown_ready.visible = false
	_countdown_ready.z_index = 50
	add_child(_countdown_ready)
	_countdown_howto = PlaneCountdownHowto.new()
	_countdown_howto.visible = false
	_countdown_howto.z_index = 50
	add_child(_countdown_howto)
	_warning_label = _mk_label(78, Color("FF2030"))
	_outline(_warning_label)
	_warning_label.add_theme_constant_override("outline_size", 18)
	_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_warning_label.z_index = 46
	add_child(_warning_label)
	_boss_title = _mk_label(68, Color("FFE08A"))
	_outline(_boss_title)
	_boss_title.add_theme_constant_override("outline_size", 16)
	_boss_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_title.z_index = 46
	add_child(_boss_title)
	_boss_sub = _mk_label(36, Color("FFD0D4"))
	_outline(_boss_sub)
	_boss_sub.add_theme_constant_override("outline_size", 12)
	_boss_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_sub.z_index = 46
	add_child(_boss_sub)
	_power_label = _mk_label(22, Color("FFE08A"))
	_outline(_power_label)
	_power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_power_label)
	_double_bar_bg = ColorRect.new()
	_double_bar_bg.color = Color(0.05, 0.06, 0.09, 0.78)
	_double_bar_bg.visible = false
	_double_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_double_bar_bg)
	_double_bar_fill = ColorRect.new()
	_double_bar_fill.color = Color(1.0, 0.86, 0.32, 0.95)
	_double_bar_fill.visible = false
	_double_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_double_bar_fill)
	_double_bar_label = _mk_label(18, Color("FFE08A"))
	_outline(_double_bar_label)
	_double_bar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_double_bar_label)
	_laser_bar_bg = ColorRect.new()
	_laser_bar_bg.color = Color(0.05, 0.06, 0.09, 0.78)
	_laser_bar_bg.visible = false
	_laser_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_laser_bar_bg)
	_laser_bar_fill = ColorRect.new()
	_laser_bar_fill.color = Color(0.45, 0.95, 1.0, 0.95)
	_laser_bar_fill.visible = false
	_laser_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_laser_bar_fill)
	_laser_bar_label = _mk_label(18, Color("A8F4FF"))
	_outline(_laser_bar_label)
	_laser_bar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_laser_bar_label)
	_energy_bar_bg = ColorRect.new()
	_energy_bar_bg.color = Color(0.05, 0.07, 0.10, 0.82)
	_energy_bar_bg.visible = false
	_energy_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_energy_bar_bg)
	_energy_bar_fill = ColorRect.new()
	_energy_bar_fill.color = Color(0.35, 0.92, 1.0, 0.95)
	_energy_bar_fill.visible = false
	_energy_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_energy_bar_fill)
	_energy_bar_label = _mk_label(22, Color("A8F4FF"))
	_outline(_energy_bar_label)
	_energy_bar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_energy_bar_bg.z_index = 18
	_energy_bar_fill.z_index = 19
	_energy_bar_label.z_index = 20
	add_child(_energy_bar_label)
	_heart_slots.clear()
	_hearts.clear()
	for i in 3:
		var slot := _mk_sprite(_tex_heart if _tex_heart else _tex_star)
		slot.modulate = Color(0.28, 0.06, 0.08, 0.82)
		slot.visible = false
		slot.z_index = 23
		add_child(slot)
		_heart_slots.append(slot)
		var h := _mk_sprite(_tex_heart if _tex_heart else _tex_star)
		h.visible = false
		h.z_index = 24
		add_child(h)
		_hearts.append(h)
	_bomb_slots.clear()
	_bombs.clear()
	for i in PlaneLogic.BOMB_MAX:
		var bslot := _mk_sprite(_tex_hud_bomb if _tex_hud_bomb else _tex_star)
		bslot.modulate = Color(0.16, 0.10, 0.06, 0.85)
		bslot.visible = false
		add_child(bslot)
		_bomb_slots.append(bslot)
		var b := _mk_sprite(_tex_hud_bomb if _tex_hud_bomb else _tex_star)
		b.visible = false
		add_child(b)
		_bombs.append(b)
	_bomb_label = _mk_label(16, Color("FFE08A"))
	_outline(_bomb_label)
	_bomb_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_bomb_label.visible = false
	add_child(_bomb_label)
	_score_cap = _mk_hud_cap("得分")
	_score_cap.add_theme_font_size_override("font_size", HUD_TR_CAP_FS)
	_score_val = _mk_label(HUD_TR_SCORE_FS, Color(1.0, 0.96, 0.78, 1.0))
	_score_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style_hud_score(_score_val)
	_score_val.z_index = 23
	add_child(_score_val)
	_gem_canvas = CanvasLayer.new()
	_gem_canvas.name = "ScoreGemCanvas"
	_gem_canvas.layer = 95
	add_child(_gem_canvas)
	_gem_layer = Control.new()
	_gem_layer.name = "ScoreGemLayer"
	_gem_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_gem_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gem_canvas.add_child(_gem_layer)
	_life_cap = _mk_hud_cap("生命")
	_life_cap.add_theme_font_size_override("font_size", HUD_TR_CAP_FS)
	_bomb_cap = _mk_hud_cap("炸弹")
	_info_jackpot_cap = _mk_hud_cap("百万大奖")
	_info_jackpot_cap.add_theme_font_size_override("font_size", HUD_ARCADE_CAP_FS)
	_info_jackpot_val = _mk_label(HUD_ARCADE_JACKPOT_FS, Color(1.0, 0.96, 0.78, 1.0))
	_info_jackpot_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_style_hud_score(_info_jackpot_val)
	_info_jackpot_val.z_index = 23
	add_child(_info_jackpot_val)
	_info_local_cap = _mk_hud_cap("本机奖励")
	_info_local_cap.add_theme_font_size_override("font_size", HUD_ARCADE_CAP_FS)
	_info_local_val = _mk_label(HUD_ARCADE_LOCAL_FS, Color(1.0, 0.96, 0.78, 1.0))
	_info_local_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_style_hud_score(_info_local_val)
	_info_local_val.z_index = 23
	add_child(_info_local_val)
	_info_next = _mk_label(HUD_ARCADE_NEXT_FS, Color(1.0, 0.92, 0.62, 0.98))
	_outline(_info_next)
	_info_next.add_theme_constant_override("outline_size", 8)
	_info_next.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_info_next.z_index = 23
	add_child(_info_next)
	_info_coin_cap = _mk_hud_cap("投币")
	_info_coin_cap.add_theme_font_size_override("font_size", HUD_ARCADE_COIN_CAP_FS)
	_info_coin = _mk_label(HUD_ARCADE_COIN_FS, Color(1.0, 0.96, 0.78, 1.0))
	_style_hud_score(_info_coin)
	_info_coin.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_info_coin.z_index = 23
	add_child(_info_coin)
	_life_pips.clear()
	for i in 3:
		var lp := ColorRect.new()
		lp.visible = false
		lp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lp.color = Color(0.55, 1.0, 0.45, 0.95)
		lp.z_index = 23
		add_child(lp)
		_life_pips.append(lp)
	_bomb_pips.clear()
	for i in PlaneLogic.BOMB_MAX:
		var bp := ColorRect.new()
		bp.visible = false
		bp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bp.color = Color(0.55, 1.0, 0.45, 0.95)
		bp.z_index = 23
		add_child(bp)
		_bomb_pips.append(bp)
	_boss_bar_edge = ColorRect.new()
	_boss_bar_edge.color = Color(1.0, 0.82, 0.28, 0.7)
	_boss_bar_edge.visible = false
	_boss_bar_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_boss_bar_edge)
	_boss_bar_bg = ColorRect.new()
	_boss_bar_bg.color = Color(0.10, 0.06, 0.07, 0.82)
	_boss_bar_bg.visible = false
	_boss_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_boss_bar_bg)
	_boss_bar_fill = ColorRect.new()
	_boss_bar_fill.color = Color(0.92, 0.22, 0.28, 0.95)
	_boss_bar_fill.visible = false
	_boss_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_boss_bar_fill)
	_boss_bar_label = _mk_label(16, Color("FFD0D4"))
	_outline(_boss_bar_label)
	_boss_bar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_boss_bar_label)
	_float_life.resize(MAX_FLOATS)
	_float_max.resize(MAX_FLOATS)
	_float_tilt.resize(MAX_FLOATS)
	for i in MAX_FLOATS:
		var lb := _mk_label(36, Color("FFE08A"))
		_outline(lb)
		lb.add_theme_constant_override("outline_size", 12)
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.z_index = 24
		add_child(lb)
		_floats.append(lb)
		_float_life[i] = 0.0
		_float_max[i] = 0.0
		_float_tilt[i] = 0.0
	_rhythm_center_label = _mk_label(52, Color("FFF4C0"))
	_outline(_rhythm_center_label)
	_rhythm_center_label.add_theme_constant_override("outline_size", 14)
	_rhythm_center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rhythm_center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_rhythm_center_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_rhythm_center_label.z_index = 34
	_rhythm_center_label.visible = false
	add_child(_rhythm_center_label)

	_layout()


func _layout() -> void:
	if not is_inside_tree():
		return
	var vs := get_viewport_rect().size
	if vs.x < 8.0:
		return
	_cabinet.position = Vector2.ZERO
	_cabinet.size = vs
	_play = Rect2(vs.x * 0.04, vs.y * 0.07, vs.x * 0.92, vs.y * 0.86)
	_layout_frames()
	if _play_clip:
		_play_clip.position = _play.position
		_play_clip.size = _play.size
	_hurt.position = _play.position
	_hurt.size = _play.size
	_bomb_flash.position = _play.position
	_bomb_flash.size = _play.size
	if _pickup_flash:
		_pickup_flash.position = _play.position
		_pickup_flash.size = _play.size
	if _low_hp_edges.size() == 4:
		var t := 8.0
		_low_hp_edges[0].position = _play.position
		_low_hp_edges[0].size = Vector2(_play.size.x, t)
		_low_hp_edges[1].position = _play.position + Vector2(0, _play.size.y - t)
		_low_hp_edges[1].size = Vector2(_play.size.x, t)
		_low_hp_edges[2].position = _play.position
		_low_hp_edges[2].size = Vector2(t, _play.size.y)
		_low_hp_edges[3].position = _play.position + Vector2(_play.size.x - t, 0)
		_low_hp_edges[3].size = Vector2(t, _play.size.y)


func _layout_frames() -> void:
	if _frames.size() < 8:
		return
	var p := _play
	_frames[0].visible = false
	_frames[1].visible = false
	_frames[2].visible = false
	_frames[3].visible = false
	_frames[4].visible = false
	_frames[5].visible = false
	_frames[6].visible = false
	_frames[7].visible = false


func _place_strip(a: Sprite2D, b: Sprite2D, tex: Texture2D, scroll: float, area: Vector2) -> void:
	## 天空只用双块循环滚动；单块贴屏会在 wrap 处露出非循环接缝
	if a == null or b == null or tex == null or area.x < 8.0 or area.y < 8.0:
		return
	_place_pair(a, b, tex, scroll, area, "sky")


func _place_pair(a: Sprite2D, b: Sprite2D, tex: Texture2D, scroll: float, area: Vector2, mode: String) -> void:
	if a == null or b == null or tex == null or area.x < 8.0 or area.y < 8.0:
		return
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	if tw < 1.0 or th < 1.0:
		return
	a.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	b.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var sc: float
	if mode == "sky":
		## 按宽度缩放，竖向用可循环块拼接，避免 max 缩放裁切破坏首尾 seal
		sc = area.x / tw
	elif mode == "cloud":
		sc = area.x / tw
	else:
		sc = maxf(area.x / tw, area.y / th)
	a.texture = tex
	b.texture = tex
	a.centered = false
	b.centered = false
	a.scale = Vector2(sc, sc)
	b.scale = Vector2(sc, sc)
	var h := th * sc
	var w := tw * sc
	if h < 1.0:
		return
	var x0 := (area.x - w) * 0.5
	if mode == "sky" and _sky_oneshot:
		var max_off := maxf(h - area.y, 0.0)
		var traveled := clampf(-scroll, 0.0, max_off)
		a.position = Vector2(x0, -(max_off - traveled))
		b.visible = false
		a.visible = true
		return
	var y0 := fposmod(scroll, h)
	a.position = Vector2(x0, y0)
	b.position = Vector2(x0, y0 - h + 2.0)
	a.visible = true
	b.visible = true


func _to_screen(nx: float, ny: float) -> Vector2:
	return Vector2(nx * _play.size.x, ny * _play.size.y)


func _to_world(nx: float, ny: float) -> Vector2:
	return _play.position + _to_screen(nx, ny)


func _mk_sprite(tex: Texture2D) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = true
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return s


func _player_tex_for(lv: int) -> Texture2D:
	if _tex_players.is_empty():
		return _tex_player
	var i := clampi(lv, 0, _tex_players.size() - 1)
	return _tex_players[i] if _tex_players[i] else _tex_player


func _fit_py(spr: Sprite2D, px: float) -> void:
	if spr == null or spr.texture == null:
		return
	var th := float(spr.texture.get_height())
	if th < 1.0:
		return
	spr.scale = Vector2.ONE * (px / th)


func _fit_px(spr: Sprite2D, px: float) -> void:
	if spr == null or spr.texture == null:
		return
	var tw := float(spr.texture.get_width())
	if tw < 1.0:
		return
	spr.scale = Vector2.ONE * (px / tw)


func _fit_needle(spr: Sprite2D, px: float) -> void:
	if spr == null or spr.texture == null:
		return
	var tw := float(spr.texture.get_width())
	var th := float(spr.texture.get_height())
	if tw < 1.0 or th < 1.0:
		return
	var s := px / tw
	spr.scale = Vector2(s * 0.50, s * 1.68)


func _bullet_dir_screen(vx: float, vy: float) -> Vector2:
	var d := Vector2(vx, vy)
	if d.length_squared() < 0.0001:
		d = Vector2(0.0, -1.0)
	d = d.normalized()
	return Vector2(d.x * _play.size.x, d.y * _play.size.y).normalized()


func _bullet_back_screen(vx: float, vy: float) -> Vector2:
	return -_bullet_dir_screen(vx, vy)


func _needle_half_len_px(spr: Sprite2D) -> float:
	if spr == null or spr.texture == null:
		return 14.0
	return absf(spr.scale.y) * float(spr.texture.get_height()) * 0.36


func _bullet_center_from_tip(tip: Vector2, vx: float, vy: float, half_len: float) -> Vector2:
	return tip + _bullet_dir_screen(vx, vy) * half_len


func _sync_bullet_bead_trail(tr: Line2D, tip: Vector2, vx: float, vy: float) -> void:
	tr.visible = true
	tr.material = _fx_add_material()
	tr.z_index = 7
	tr.gradient = _trail_grad
	tr.clear_points()
	var back := _bullet_back_screen(vx, vy)
	var beads := 9 + int(_beat_glow * 5.0) + _climax_tier
	var step := 4.8 + _beat_glow * 2.2
	for b in beads:
		var side := sin(float(b) * 2.1 + _anim * 18.0 + float(b) * 0.31) * 1.4
		var p := tip + back * (step * float(b))
		p += Vector2(back.y, -back.x) * side
		tr.add_point(p)
	tr.width = 0.95 + _beat_glow * 0.45
	tr.default_color = _player_bullet_tint(0.68, 1.02, 0.32 + _beat_glow * 0.24)
	if _tex_spark:
		tr.texture = _tex_spark
		tr.texture_mode = Line2D.LINE_TEXTURE_TILE


func _sync_bullet_bead_sprites(st: Sprite2D, gl: Sprite2D, tip: Vector2, vx: float, vy: float, pulse_sc: float) -> void:
	var back := _bullet_back_screen(vx, vy)
	var spark := _tex_spark if _tex_spark else (_tex_glow if _tex_glow else _tex_bullet)
	if gl:
		gl.visible = true
		gl.material = _fx_add_material()
		gl.texture = spark
		gl.position = tip
		gl.rotation = 0.0
		gl.z_index = 10
		gl.modulate = _player_bullet_tint(0.95, 1.32, 0.95)
		_fit_px(gl, (9.0 + _beat_glow * 5.0) * pulse_sc)
	if st:
		st.visible = true
		st.material = _fx_add_material()
		st.texture = spark
		st.rotation = 0.0
		st.z_index = 9
		var idx := int(_anim * 40.0) % 4
		var dist := 5.0 + float(idx) * 3.5
		st.position = tip + back * dist
		st.modulate = _player_bullet_tint(0.82, 1.22, 0.55 + _beat_glow * 0.28)
		_fit_px(st, (5.5 + _beat_glow * 3.0) * pulse_sc)


func _mk_label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.visible = false
	_apply_pop_font(l)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _mk_hud_cap(text: String) -> Label:
	var l := _mk_label(HUD_CAP_FONT, Color(0.82, 0.94, 1.0, 0.98))
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_style_hud_cap(l)
	l.z_index = 23
	add_child(l)
	return l


func _style_hud_cap(l: Label) -> void:
	l.add_theme_color_override("font_outline_color", Color(0.04, 0.10, 0.18, 0.92))
	l.add_theme_constant_override("outline_size", 8)
	l.add_theme_color_override("font_shadow_color", Color(0.0, 0.02, 0.06, 0.55))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 3)


func _style_hud_score(l: Label) -> void:
	l.add_theme_color_override("font_outline_color", Color(0.06, 0.14, 0.22, 0.95))
	l.add_theme_constant_override("outline_size", 12)
	l.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.5))
	l.add_theme_constant_override("shadow_offset_x", 3)
	l.add_theme_constant_override("shadow_offset_y", 4)


func _outline(l: Label) -> void:
	l.add_theme_color_override("font_outline_color", Color(0.22, 0.08, 0.12, 0.92))
	l.add_theme_constant_override("outline_size", 12)
	l.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.04, 0.45))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 3)


func _apply_pop_font(l: Label) -> void:
	if l == null or _font_pop == null:
		return
	l.add_theme_font_override("font", _font_pop)


func _load_pop_font() -> void:
	if ResourceLoader.exists(PATH_POP_FONT):
		_font_pop = load(PATH_POP_FONT) as Font
		if _font_pop:
			return
	var abs_path := ProjectSettings.globalize_path(PATH_POP_FONT)
	if FileAccess.file_exists(abs_path):
		var ff := FontFile.new()
		if ff.load_dynamic_font(abs_path) == OK:
			_font_pop = ff


func _load_textures() -> void:
	_load_pop_font()
	_tex_sky = _load_best_sky()
	_tex_stars = _paint_stars()
	_tex_cloud = _paint_cloud()
	_tex_player = _load_or_paint(PATH_PLAYER, _paint_player)
	_tex_players.clear()
	for path in PATH_PLAYER_LV:
		_tex_players.append(_load_or_paint(path, _paint_player))
	_tex_enemies.clear()
	_tex_enemies.append(_load_or_paint(PATH_ENEMY[0], _paint_enemy.bind(0)))
	_tex_enemies.append(_load_or_paint(PATH_ENEMY[1], _paint_enemy.bind(1)))
	_tex_enemies.append(_load_or_paint(PATH_ENEMY[2], _paint_enemy.bind(2)))
	_tex_enemies.append(_load_or_paint(PATH_ENEMY[3], _paint_enemy.bind(3)))
	_ensure_score_gem_tex()
	_tex_bullet = _load_or_paint(PATH_BULLET, _paint_bullet)
	_tex_bullet_fat = _load_or_paint(PATH_BULLET_FAT, _paint_bullet)
	_tex_bullet_gold = _load_or_paint(PATH_BULLET_GOLD, _paint_bullet)
	_tex_missile = _load_or_paint(PATH_MISSILE, _paint_bullet)
	_tex_trail = _load_or_paint(PATH_BULLET_TRAIL, _paint_bullet_trail)
	_tex_muzzle = _paint_muzzle()
	_tex_muzzle_player = _load_or_paint(PATH_MUZZLE_PLAYER, _paint_muzzle)
	_tex_bomb = _load_or_paint(PATH_BOMB, _paint_bomb)
	_tex_rhythm_ring = _try_tex(PATH_RHYTHM_RING)
	_tex_items.clear()
	_tex_items.append(_load_or_paint(PATH_ITEM[0], _paint_item.bind(0)))
	_tex_items.append(_load_or_paint(PATH_ITEM[1], _paint_item.bind(1)))
	_tex_items.append(_load_or_paint(PATH_ITEM[2], _paint_item.bind(2)))
	_tex_items.append(_load_or_paint(PATH_ITEM[3], _paint_item.bind(3)))
	_tex_items.append(_load_or_paint(PATH_ITEM[4], _paint_item.bind(4)))
	_tex_heart = _tex_items[4] if _tex_items.size() > 4 else _load_or_paint(PATH_ITEM[4], _paint_item.bind(4))
	_tex_hud_bomb = _tex_items[3] if _tex_items.size() > 3 else _load_or_paint(PATH_ITEM[3], _paint_item.bind(3))
	_tex_bosses.clear()
	for bi in 5:
		_tex_bosses.append(_load_or_paint(PATH_BOSS[bi], _paint_boss.bind(bi)))
	_tex_boss_stages.clear()
	_tex_boss_drops.clear()
	for bi in 5:
		var bid := bi + 1
		var fallback: Texture2D = _tex_bosses[bi]
		var stage_row: Array = []
		for sk in BOSS_STAGE_KEYS:
			var sp := "res://assets/plane/boss_stages/boss_%d_%s.png" % [bid, sk]
			var t := _try_tex(sp)
			stage_row.append(t if t else fallback)
		_tex_boss_stages.append(stage_row)
		var drop_row: Array = []
		for dk in BOSS_DROP_KEYS:
			var dp := "res://assets/plane/boss_drops/boss_%d_%s.png" % [bid, dk]
			var dt := _try_tex(dp)
			drop_row.append(dt if dt else fallback)
		_tex_boss_drops.append(drop_row)
	_tex_ebullet = _load_or_paint(PATH_EBULLET, _paint_ebullet)
	_tex_ebullet_boss = _load_or_paint(PATH_EBULLET_BOSS, _paint_ebullet_boss)
	_tex_star = _load_or_paint(PATH_STAR, _paint_star)
	_tex_spark = _load_or_paint(PATH_SPARK, _paint_star)
	_tex_glow = _load_or_paint(PATH_GLOW, _paint_bomb)
	_tex_ring_fx = _load_or_paint(PATH_RING_FX, _paint_ring)
	_tex_flash = _load_or_paint(PATH_FLASH, _paint_muzzle)
	_tex_star8 = _load_or_paint(PATH_STAR8, _paint_star)
	_tex_shadow = _load_or_paint(PATH_SHADOW, _paint_shadow)
	_tex_boom_s = _load_boom_pack(PATH_BOOM_S, 0)
	_tex_boom_m = _load_boom_pack(PATH_BOOM_M, 1)
	_tex_boom_l = _load_boom_pack(PATH_BOOM_L, 2)
	_tex_boom_b = _load_boom_pack(PATH_BOOM_B, 3)
	_tex_boom_boss = _load_or_paint(PATH_BOOM_BOSS, _paint_boom_pack.bind(3, 1))
	_tex_laser_beam = _load_or_paint(PATH_LASER_BEAM, _paint_laser_beam.bind(0.0))
	_tex_laser_beam_b = _load_or_paint(PATH_LASER_BEAM_B, _paint_laser_beam.bind(1.2))
	_tex_laser_muzzle = _load_or_paint(PATH_LASER_MUZZLE, _paint_laser_muzzle)
	_tex_laser_impact = _load_or_paint(PATH_LASER_IMPACT, _paint_laser_impact)
	_tex_gold_beam = _paint_gold_laser_beam(0.0)
	_tex_gold_beam_b = _paint_gold_laser_beam(1.15)
	_tex_gold_halo = _paint_gold_laser_halo()
	_tex_gold_core = _paint_gold_laser_core()
	_tex_gold_muzzle = _paint_gold_laser_muzzle()
	_tex_gold_impact = _paint_gold_laser_impact()
	_tex_ring = _load_or_paint(PATH_RING, _paint_ring)


func _load_boom_pack(paths: Array, set_id: int) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	for i in 4:
		var path: String = str(paths[i]) if i < paths.size() else PATH_BOOM[mini(i, PATH_BOOM.size() - 1)]
		out.append(_load_or_paint(path, _paint_boom_pack.bind(set_id, i)))
	return out


func _load_best_sky() -> Texture2D:
	var long_sky := _load_long_sky()
	if long_sky:
		_sky_oneshot = true
		return long_sky
	_sky_oneshot = false
	## 单块竖向循环（裁切天空 + 首尾 seal）；不用长图拼接，避免横缝/花边
	for path in [PATH_SKY_TILE, PATH_SKY_JPG, PATH_SKY]:
		if ArcadeProfile.plane_low_fx():
			var imp := _try_tex(path)
			if imp:
				var im := imp.get_image()
				if im and not im.is_empty():
					return _sky_tex_from_img(im)
		var img := Image.new()
		if FileAccess.file_exists(path) and img.load(ProjectSettings.globalize_path(path)) == OK:
			return _sky_tex_from_img(img)
	return _sky_tex_from_img(_paint_sky_image())


func _load_long_sky() -> Texture2D:
	if not FileAccess.file_exists(PATH_SKY_LONG):
		return null
	var img := Image.new()
	if img.load(ProjectSettings.globalize_path(PATH_SKY_LONG)) == OK and img.get_height() >= 4096:
		return ImageTexture.create_from_image(img)
	var tex := _try_tex(PATH_SKY_LONG)
	if tex and tex.get_height() >= 4096:
		return tex
	return null


func _paint_sky_image() -> Image:
	var w := 768
	var h := 1280
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var t := float(y) / float(h)
		var c := Color("070B18").lerp(Color("102040"), t * 0.55).lerp(Color("0A1A38"), maxf(0.0, t - 0.65) * 2.0)
		for x in w:
			var n := 0.0
			if (x * 13 + y * 7) % 47 == 0:
				n = 0.55
			img.set_pixel(x, y, c.lightened(n * 0.35))
	return img


func _sky_tex_from_img(img: Image) -> Texture2D:
	return ImageTexture.create_from_image(_make_sky_tileable(img))


func _make_sky_tileable(img: Image) -> Image:
	## 底部 band 渐变接到顶部，使 fract 循环处色差连续（单 shader 滚动，不会出现双 Sprite 双横带）
	var out: Image = img.duplicate()
	out.convert(Image.FORMAT_RGBA8)
	var w: int = out.get_width()
	var h: int = out.get_height()
	if w < 4 or h < 64:
		return out
	var band: int = clampi(h / 7, 96, 168)
	for yi in band:
		var t: float = smoothstep(0.0, 1.0, float(yi + 1) / float(band + 1))
		var y_bot: int = h - band + yi
		for x in w:
			var top_c: Color = out.get_pixel(x, yi)
			var bot_c: Color = out.get_pixel(x, y_bot)
			out.set_pixel(x, y_bot, bot_c.lerp(top_c, t))
	for x in w:
		out.set_pixel(x, h - 1, out.get_pixel(x, 0))
	return out


func _paint_sky() -> Texture2D:
	return _sky_tex_from_img(_paint_sky_image())


func _try_tex(path: String) -> Texture2D:
	if _tex_import_ready(path) and ResourceLoader.exists(path):
		var tex := ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE) as Texture2D
		if tex:
			return tex
	var img := Image.new()
	if FileAccess.file_exists(path) and img.load(ProjectSettings.globalize_path(path)) == OK:
		return _img_tex(img)
	return null


func _tex_import_ready(path: String) -> bool:
	var imp := path + ".import"
	if not FileAccess.file_exists(imp):
		return false
	var f := FileAccess.open(imp, FileAccess.READ)
	if f == null:
		return false
	return f.get_as_text().contains("res://.godot/imported/")


func _load_or_paint(path: String, painter: Callable) -> Texture2D:
	## 优先读源 PNG，避免 .import 缓存还停在旧爆炸/子弹图上
	var img := Image.new()
	if FileAccess.file_exists(path) and img.load(ProjectSettings.globalize_path(path)) == OK:
		return ImageTexture.create_from_image(img)
	if ResourceLoader.exists(path):
		var tex := ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE) as Texture2D
		if tex:
			return tex
	return painter.call()


func _img_tex(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)


func _paint_stars() -> Texture2D:
	var w := 256
	var h := 384
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in 90:
		var x := (i * 37 + 11) % w
		var y := (i * 53 + 19) % h
		var a := 0.28 + float(i % 6) * 0.10
		var c := Color(0.82, 0.90, 1.0, a)
		img.set_pixel(x, y, c)
		if i % 7 == 0 and x + 1 < w:
			img.set_pixel(x + 1, y, Color(c.r, c.g, c.b, a * 0.45))
	return _img_tex(img)


func _paint_cloud() -> Texture2D:
	var w := 320
	var h := 256
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in 10:
		_blob(img, 28 + (i * 29) % (w - 36), 28 + (i * 41) % (h - 40), 18 + i % 8, Color(0.72, 0.80, 0.92, 0.14))
	return _img_tex(img)


func _paint_player() -> Texture2D:
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_tri(img, 24, 4, 10, 40, Color("F5D76E"), true)
	_tri(img, 24, 8, 18, 32, Color("D4894A"), true)
	_rect(img, 21, 16, 6, 10, Color("FFF4C0"))
	_rect(img, 8, 26, 10, 5, Color("E8A838"))
	_rect(img, 30, 26, 10, 5, Color("E8A838"))
	_rect(img, 22, 36, 4, 8, Color("E85A6B"))
	return _img_tex(img)


func _paint_boss(style: int = 0) -> Texture2D:
	var img := Image.create(96, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match style:
		1:
			_rect(img, 16, 20, 64, 22, Color("3A4450"))
			_rect(img, 8, 36, 18, 14, Color("C84A3A"))
			_rect(img, 70, 36, 18, 14, Color("C84A3A"))
			_rect(img, 40, 12, 16, 12, Color("6AE0E8"))
		2:
			_blob(img, 48, 32, 26, Color("4A5560"))
			_blob(img, 48, 32, 16, Color("6A7884"))
			_rect(img, 44, 44, 8, 12, Color("E85A6B"))
			_rect(img, 28, 40, 6, 10, Color("E85A6B"))
			_rect(img, 62, 40, 6, 10, Color("E85A6B"))
		3:
			_rect(img, 10, 22, 76, 16, Color("3A4048"))
			_rect(img, 18, 16, 60, 10, Color("5A626C"))
			_rect(img, 62, 8, 16, 18, Color("4A545E"))
			_rect(img, 44, 36, 8, 14, Color("E85A6B"))
		4:
			_rect(img, 6, 26, 84, 16, Color("2E343C"))
			_rect(img, 22, 14, 52, 18, Color("4A3A48"))
			_rect(img, 40, 8, 16, 10, Color("6AE0E8"))
			_rect(img, 14, 40, 14, 12, Color("E85A6B"))
			_rect(img, 68, 40, 14, 12, Color("E85A6B"))
			_rect(img, 42, 38, 12, 16, Color("C84A3A"))
		_:
			_rect(img, 18, 18, 60, 28, Color("3A4048"))
			_rect(img, 22, 14, 52, 12, Color("2A3038"))
			_rect(img, 36, 8, 24, 10, Color("4A545E"))
			_rect(img, 42, 20, 12, 8, Color("6AE0E8"))
			_rect(img, 42, 40, 12, 12, Color("E85A6B"))
	return _img_tex(img)


func _paint_ebullet() -> Texture2D:
	var img := Image.create(40, 56, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_blob(img, 20, 14, 10, Color(0.55, 0.12, 0.95, 0.55))
	_blob(img, 20, 12, 6, Color(0.92, 0.45, 1.0, 0.92))
	_rect(img, 18, 10, 4, 36, Color(0.75, 0.28, 1.0, 0.75))
	_rect(img, 19, 8, 2, 14, Color(1.0, 0.95, 1.0, 0.95))
	return _img_tex(img)


func _paint_ebullet_boss() -> Texture2D:
	## Fallback：赤金火球，与杂兵紫针弹区分
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_blob(img, 32, 34, 22, Color(1.0, 0.18, 0.06, 0.45))
	_blob(img, 32, 32, 16, Color(1.0, 0.35, 0.08, 0.85))
	_blob(img, 32, 30, 11, Color(1.0, 0.62, 0.18, 0.95))
	_blob(img, 30, 27, 6, Color(1.0, 0.92, 0.55, 1.0))
	_blob(img, 29, 25, 3, Color(1.0, 1.0, 1.0, 1.0))
	return _img_tex(img)


func _paint_enemy(kind: int) -> Texture2D:
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cols := [Color("E85A6B"), Color("5EC4D4"), Color("C79BDE"), Color("F5D76E")]
	var col: Color = cols[kind]
	match kind:
		1:
			_tri(img, 24, 8, 8, 34, col, false)
			_rect(img, 22, 14, 4, 8, Color(1, 1, 1, 0.35))
		2:
			_tri(img, 24, 6, 20, 38, col, false)
			_rect(img, 16, 20, 16, 8, col.darkened(0.15))
			_rect(img, 20, 16, 8, 6, Color(1, 1, 1, 0.28))
		3:
			_tri(img, 24, 8, 16, 32, col, false)
			_rect(img, 20, 18, 8, 8, Color("FFF4C0"))
			_rect(img, 22, 12, 4, 16, Color("FFF4C0"))
		_:
			_tri(img, 24, 8, 14, 32, col, false)
			_rect(img, 21, 16, 6, 6, Color(1, 1, 1, 0.3))
	return _img_tex(img)


func _paint_muzzle() -> Texture2D:
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_blob(img, 24, 24, 18, Color(1.0, 0.85, 0.35, 0.55))
	_blob(img, 24, 24, 9, Color(1.0, 0.96, 0.75, 0.95))
	_rect(img, 22, 8, 4, 20, Color(1, 1, 0.9, 0.9))
	return _img_tex(img)


func _ensure_trail_gradient() -> void:
	if _trail_grad != null:
		return
	_trail_grad = Gradient.new()
	_trail_grad.colors = PackedColorArray([Color(1, 1, 1, 0.92), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.0)])
	_trail_grad.offsets = PackedFloat32Array([0.0, 0.35, 1.0])


func _paint_bullet_trail() -> Texture2D:
	var img := Image.create(32, 192, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(192):
		var t: float = float(y) / 191.0
		var a: float = pow(1.0 - t, 1.35)
		for x in range(32):
			var dx: float = absf(float(x - 16)) / 16.0
			var g: float = maxf(0.0, 1.0 - dx * 1.2)
			var c := Color(0.35, 0.88, 1.0, a * g * 0.85)
			img.set_pixel(x, y, c)
	return _img_tex(img)


func _paint_bullet() -> Texture2D:
	var img := Image.create(32, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_blob(img, 16, 22, 14, Color(0.12, 0.55, 1.0, 0.55))
	_blob(img, 16, 20, 8, Color(0.45, 0.92, 1.0, 0.95))
	_blob(img, 16, 18, 4, Color(1, 1, 1, 1))
	_rect(img, 14, 18, 4, 28, Color(0.4, 0.85, 1.0, 0.85))
	_rect(img, 15, 16, 2, 22, Color(1, 1, 1, 0.9))
	return _img_tex(img)


func _paint_bomb() -> Texture2D:
	var s := 48
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(s * 0.5, s * 0.5)
	for y in s:
		for x in s:
			var d := Vector2(x, y).distance_to(c) / 22.0
			if d < 1.0:
				img.set_pixel(x, y, Color(1, 0.95, 0.8, 0.55 * (1.0 - d)))
	return _img_tex(img)


func _paint_item(kind: int) -> Texture2D:
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match kind:
		0:
			_rect(img, 4, 8, 6, 10, Color("E8A838"))
			_rect(img, 14, 8, 6, 10, Color("E8A838"))
			_rect(img, 6, 4, 3, 6, Color("FFF4C0"))
			_rect(img, 16, 4, 3, 6, Color("FFF4C0"))
		1:
			_rect(img, 7, 6, 10, 12, Color("5EC4D4"))
			_rect(img, 9, 8, 6, 8, Color("E8F6FF"))
		2:
			_rect(img, 10, 2, 4, 20, Color("7CF0FF"))
			_rect(img, 8, 18, 8, 4, Color("E8FFFF"))
			_blob(img, 12, 6, 5, Color(0.6, 1.0, 1.0, 0.85))
		3:
			_rect(img, 8, 8, 8, 10, Color("E85A6B"))
			_rect(img, 6, 6, 12, 4, Color("FFF4C0"))
			_rect(img, 10, 4, 4, 6, Color("FFE08A"))
		4:
			_blob(img, 8, 9, 5, Color("E23B4A"))
			_blob(img, 15, 9, 5, Color("E23B4A"))
			_rect(img, 6, 10, 12, 6, Color("E23B4A"))
			_blob(img, 12, 16, 5, Color("C42236"))
			_blob(img, 9, 8, 2, Color("FFD0D4"))
		_:
			_rect(img, 10, 2, 4, 20, Color("F5D76E"))
			_rect(img, 2, 10, 20, 4, Color("F5D76E"))
			_rect(img, 8, 8, 8, 8, Color("FFF4C0"))
	return _img_tex(img)


func _paint_star() -> Texture2D:
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_rect(img, 10, 2, 4, 20, Color("F5D76E"))
	_rect(img, 2, 10, 20, 4, Color("F5D76E"))
	_rect(img, 8, 8, 8, 8, Color("FFF4C0"))
	return _img_tex(img)


func _paint_boom_pack(set_id: int, phase: int) -> Texture2D:
	var s := 128 if set_id <= 1 else (160 if set_id == 2 else 192)
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(s * 0.5, s * 0.5)
	var r_out := (22.0 + float(phase) * 8.0) * (float(s) / 128.0)
	if set_id == 3:
		r_out *= 1.15
	var nspk := 5 + set_id * 2 + phase
	var yst := 1.28 if set_id == 1 else 1.0
	for y in s:
		for x in s:
			var d := Vector2(float(x) - c.x, (float(y) - c.y) / yst).length()
			if d > r_out + 2.0:
				continue
			var ang := atan2((float(y) - c.y) / yst, float(x) - c.x)
			var slot := fposmod(ang / TAU * float(nspk), float(nspk))
			var f := slot - floorf(slot)
			var valley := 0.42 + 0.58 * pow(1.0 - absf(f - 0.5) * 2.0, 1.6)
			var edge := r_out * valley
			if d > edge:
				continue
			var t := d / maxf(1.0, edge)
			if phase >= 3:
				if t < 0.58 or t > 0.96:
					continue
				var u := 1.0 - absf((t - 0.76) / 0.20)
				var smoke := Color(1.0, 0.62, 0.28, 0.5 * u)
				if set_id == 1:
					smoke = Color(0.4, 0.7, 0.85, 0.45 * u)
				elif set_id == 2:
					smoke = Color(0.7, 0.25, 0.45, 0.5 * u)
				img.set_pixel(x, y, smoke)
				continue
			var col: Color
			if t < 0.16:
				col = Color(1, 1, 1, 1)
			elif set_id == 1:
				col = Color(0.55, 0.95, 1.0, 1).lerp(Color(1.0, 0.55, 0.18, 1), clampf((t - 0.16) / 0.7, 0.0, 1.0))
			elif set_id >= 2:
				col = Color(1.0, 0.95, 0.55, 1).lerp(Color(1.0, 0.22, 0.08, 1), clampf((t - 0.16) / 0.7, 0.0, 1.0))
			else:
				col = Color(1.0, 0.95, 0.45, 1).lerp(Color(1.0, 0.4, 0.1, 1), clampf((t - 0.16) / 0.7, 0.0, 1.0))
			img.set_pixel(x, y, col)
	if phase < 3:
		_blob(img, int(c.x), int(c.y), 10 + set_id * 3, Color(1.0, 1.0, 0.95, 1))
	if set_id == 3 and phase == 0:
		_rect(img, int(c.x) - 5, 16, 10, s - 32, Color(1, 1, 1, 0.9))
		_rect(img, 16, int(c.y) - 5, s - 32, 10, Color(1, 1, 1, 0.9))
	if set_id >= 2 and phase == 2:
		_rect(img, int(c.x) + 18, int(c.y) - 22, 18, 5, Color(1.0, 0.7, 0.25, 0.9))
		_rect(img, int(c.x) - 36, int(c.y) + 16, 16, 5, Color(1.0, 0.45, 0.15, 0.9))
	return _img_tex(img)


func _paint_laser_beam(phase: float) -> Texture2D:
	var w := 64
	var h := 256
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := (w - 1) * 0.5
	for y in h:
		var stripe := 0.62 + 0.28 * sin((float(y) / float(h)) * PI * 6.0 + phase)
		for x in w:
			var nx := absf(float(x) - cx) / (float(w) * 0.5)
			if nx >= 1.0:
				continue
			var col: Color
			if nx < 0.20:
				col = Color(1, 1, 1, stripe)
			elif nx < 0.42:
				col = Color("7AF4FF").lerp(Color(1, 1, 1, 1), 1.0 - (nx - 0.20) / 0.22)
				col.a = stripe
			elif nx < 0.72:
				col = Color("2EC8FF")
				col.a = stripe * (1.0 - (nx - 0.42) / 0.30 * 0.15)
			else:
				col = Color("2EC8FF")
				col.a = 0.65 * stripe * (1.0 - (nx - 0.72) / 0.28)
			img.set_pixel(x, y, col)
	return _img_tex(img)


func _paint_laser_muzzle() -> Texture2D:
	var img := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_blob(img, 48, 48, 28, Color(0.3, 0.85, 1.0, 0.45))
	_blob(img, 48, 48, 14, Color(1, 1, 1, 0.95))
	_rect(img, 44, 8, 8, 80, Color(0.7, 0.96, 1.0, 0.85))
	_rect(img, 8, 44, 80, 8, Color(0.7, 0.96, 1.0, 0.85))
	return _img_tex(img)


func _paint_laser_impact() -> Texture2D:
	var img := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_rect(img, 44, 10, 8, 76, Color("7AF4FF"))
	_rect(img, 10, 44, 76, 8, Color("7AF4FF"))
	_blob(img, 48, 48, 16, Color(1, 1, 1, 1))
	return _img_tex(img)


func _paint_gold_laser_beam(phase: float) -> Texture2D:
	var w := 128
	var h := 512
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := (w - 1) * 0.5
	for y in h:
		var along := float(y) / float(maxi(1, h - 1))
		var shape := pow(along, 0.52)
		if along < 0.04:
			shape *= along / 0.04
		var rad := 1.6 + shape * (w * 0.36)
		var shine := 1.0 + 0.07 * sin(along * TAU * 2.2 + phase)
		var muzzle := 0.0
		if along > 0.90:
			muzzle = (along - 0.90) / 0.10
		for x in w:
			var d := absf(float(x) - cx)
			var core := exp(-0.5 * pow(d / maxf(0.70, rad * 0.09), 2.0))
			var body := exp(-0.5 * pow(d / maxf(1.10, rad * 0.32), 2.0))
			var glow := exp(-0.5 * pow(d / maxf(1.80, rad * 0.88), 2.0))
			var r := (1.00 * core + 0.98 * body + 0.92 * glow * 0.32 + muzzle * glow * 0.55) * shine
			var g := (0.97 * core + 0.78 * body + 0.46 * glow * 0.34 + muzzle * glow * 0.40) * shine
			var b := (0.78 * core + 0.28 * body * 0.50 + 0.06 * glow * 0.18) * shine
			var a := clampf(core * 0.98 + body * 0.78 + glow * 0.26 + muzzle * 0.30, 0.0, 1.0)
			if a > 0.012:
				img.set_pixel(x, y, Color(clampf(r, 0.0, 1.0), clampf(g, 0.0, 1.0), clampf(b, 0.0, 1.0), a))
	return _img_tex(img)


func _paint_gold_laser_halo() -> Texture2D:
	var w := 160
	var h := 512
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := (w - 1) * 0.5
	for y in h:
		var along := float(y) / float(maxi(1, h - 1))
		var shape := pow(along, 0.48)
		if along < 0.05:
			shape *= along / 0.05
		var rad := 3.0 + shape * (w * 0.46)
		for x in w:
			var d := absf(float(x) - cx)
			var glow := exp(-0.5 * pow(d / maxf(2.2, rad), 2.0))
			var a := glow * 0.55 * (0.35 + 0.65 * along)
			if a > 0.012:
				img.set_pixel(x, y, Color(1.0, 0.62, 0.14, a))
	return _img_tex(img)


func _paint_gold_laser_core() -> Texture2D:
	var w := 48
	var h := 512
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := (w - 1) * 0.5
	for y in h:
		var along := float(y) / float(maxi(1, h - 1))
		var shape := pow(along, 0.42)
		if along < 0.03:
			shape *= along / 0.03
		var rad := 0.7 + shape * (w * 0.18)
		for x in w:
			var d := absf(float(x) - cx)
			var core := exp(-0.5 * pow(d / maxf(0.45, rad), 2.0))
			if core > 0.02:
				img.set_pixel(x, y, Color(1.0, 0.99, 0.92, core))
	return _img_tex(img)


func _paint_gold_laser_muzzle() -> Texture2D:
	var img := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(47.5, 47.5)
	for y in 96:
		for x in 96:
			var d := Vector2(float(x), float(y)).distance_to(c) / 46.0
			if d >= 1.0:
				continue
			var core := exp(-0.5 * pow(d / 0.16, 2.0))
			var mid := exp(-0.5 * pow(d / 0.38, 2.0))
			var glow := exp(-0.5 * pow(d / 0.82, 2.0))
			var r := clampf(core + 0.95 * mid + 0.70 * glow, 0.0, 1.0)
			var g := clampf(0.98 * core + 0.72 * mid + 0.38 * glow, 0.0, 1.0)
			var b := clampf(0.80 * core + 0.28 * mid + 0.06 * glow, 0.0, 1.0)
			var a := clampf(core * 0.95 + mid * 0.55 + glow * 0.28, 0.0, 1.0)
			img.set_pixel(x, y, Color(r, g, b, a))
	return _img_tex(img)


func _paint_gold_laser_impact() -> Texture2D:
	var img := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(47.5, 47.5)
	for y in 96:
		for x in 96:
			var p := Vector2(float(x), float(y))
			var d := p.distance_to(c) / 40.0
			var spike := 0.0
			var dx := absf(p.x - c.x)
			var dy := absf(p.y - c.y)
			if dx < 2.8:
				spike = maxf(spike, 1.0 - dy / 38.0)
			if dy < 2.8:
				spike = maxf(spike, 1.0 - dx / 38.0)
			spike = maxf(0.0, spike)
			if d >= 1.0 and spike <= 0.0:
				continue
			var glow := exp(-0.5 * pow(d / 0.42, 2.0))
			var a := clampf(glow * 0.85 + spike * 0.65, 0.0, 1.0)
			if a > 0.02:
				img.set_pixel(x, y, Color(1.0, 0.90, 0.55, a))
	return _img_tex(img)


func _paint_ring() -> Texture2D:
	var s := 128
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(s * 0.5, s * 0.5)
	for y in s:
		for x in s:
			var d := Vector2(x, y).distance_to(c)
			if d > 46.0 and d < 58.0:
				var a := 1.0 - absf(d - 52.0) / 6.0
				img.set_pixel(x, y, Color(1.0, 0.92, 0.7, a))
	return _img_tex(img)


func _paint_shadow() -> Texture2D:
	var img := Image.create(128, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(64, 24)
	for y in 48:
		for x in 128:
			var d := Vector2((x - c.x) / 54.0, (y - c.y) / 16.0).length()
			if d < 1.0:
				img.set_pixel(x, y, Color(0.08, 0.05, 0.03, 0.42 * (1.0 - d)))
	return _img_tex(img)


func _rect(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	var iw := img.get_width()
	var ih := img.get_height()
	for yy in range(maxi(0, y), mini(ih, y + h)):
		for xx in range(maxi(0, x), mini(iw, x + w)):
			img.set_pixel(xx, yy, col)


func _blob(img: Image, cx: int, cy: int, r: int, col: Color) -> void:
	var iw := img.get_width()
	var ih := img.get_height()
	for y in range(maxi(0, cy - r), mini(ih, cy + r + 1)):
		for x in range(maxi(0, cx - r), mini(iw, cx + r + 1)):
			var d := Vector2(x - cx, y - cy).length() / float(r)
			if d < 1.0:
				var old := img.get_pixel(x, y)
				var aa := col.a * (1.0 - d)
				img.set_pixel(x, y, Color(
					old.r * (1.0 - aa) + col.r * aa,
					old.g * (1.0 - aa) + col.g * aa,
					old.b * (1.0 - aa) + col.b * aa,
					minf(1.0, old.a + aa)
				))


func _tri(img: Image, cx: int, top: int, half_w: int, h: int, col: Color, up: bool) -> void:
	var iw := img.get_width()
	var ih := img.get_height()
	for i in h:
		var t := float(i) / float(maxi(1, h - 1))
		var w := int(lerpf(1.0, float(half_w), t if up else 1.0 - t))
		var y := top + i
		if y < 0 or y >= ih:
			continue
		for x in range(cx - w, cx + w + 1):
			if x >= 0 and x < iw:
				img.set_pixel(x, y, col)
