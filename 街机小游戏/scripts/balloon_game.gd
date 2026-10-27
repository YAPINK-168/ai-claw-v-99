extends Node2D
const CarnivalHud := preload("res://街机小游戏/scripts/balloon_carnival_hud.gd")
var _carnival_hud: Node2D
var _carnival_pops := 0
## 按种类计数：普通、条纹、星星、爱心、金色、钻石
var _pop_counts: Array[int] = [0, 0, 0, 0, 0, 0]
## 气球拉针试玩。针不动，拍一下抓取键拉一顿，碰到针尖就爆。按住不会连拉。

signal round_finished(points: int)
var _points_round_id := ""
signal ask_return_hub()

const PLAY_SEC := 30.0
const SETTLE_SEC := 5.0
const YANK_DUR := 0.14
const YANK_DEPTH := 0.011
const DEPTH_GAP := 0.013
const BALLOON_H := 150.0
## 贴图中心到气球结的距离，占整张图高度。结落在绳子上，身体从结往外鼓。
const KNOT_FROM_CENTER := 0.145
const CHAR_BOX_TOP := 0.618
const CHAR_CUT := 0.62
const NEEDLE_H := 206.0
const KIND_EMPTY := 0
const KIND_CHIP := 1
const KIND_TICKET := 2
const KIND_COIN := 3
const SPECIES_RED := 0
const SPECIES_STRIPE := 1
const SPECIES_STAR := 2
const SPECIES_CANDY := 3
const SPECIES_GOLD := 4
const SPECIES_DIAMOND := 5
const DIAMOND_CHANCE := 0.02
const TEX_DIAMOND_BADGE := preload("res://街机小游戏/miner/assets/gem.png")

const TEX_BG := preload("res://街机小游戏/assets/balloon/carnival/background_sky.png")
const TEX_POST := preload("res://街机小游戏/assets/balloon/carnival/stall.png")
const TEX_IDLE := preload("res://街机小游戏/assets/balloon/carnival/character.png")
const TEX_REACH := preload("res://街机小游戏/assets/balloon/carnival/character_reach.png")
const TEX_YANK := preload("res://街机小游戏/assets/balloon/carnival/character_pull.png")
const TEX_NEEDLE := preload("res://街机小游戏/assets/balloon/carnival/needle_v2.png")
const TEX_ROPE := preload("res://街机小游戏/assets/balloon/carnival/rope_original.png")
const TEX_WIND_HEAD := preload("res://街机小游戏/assets/balloon/carnival/wind_v2.png")
const TEX_WIND_TAIL := TEX_WIND_HEAD
const TEX_RED := preload("res://街机小游戏/assets/balloon/carnival/balloon_red.png")
const TEX_BLUE := preload("res://街机小游戏/assets/balloon/carnival/balloon_blue.png")
const TEX_YELLOW := preload("res://街机小游戏/assets/balloon/carnival/balloon_yellow.png")
const TEX_GREEN := preload("res://街机小游戏/assets/balloon/carnival/balloon_green.png")
const TEX_STRIPE := preload("res://街机小游戏/assets/balloon/carnival/balloon_stripe.png")
const COMMON_COLORS: Array[Texture2D] = [
	TEX_RED, TEX_YELLOW, TEX_BLUE, TEX_GREEN, preload("res://街机小游戏/assets/balloon/carnival/balloon_heart.png"), TEX_BLUE, TEX_STRIPE,
]
const TEX_SPECIES_STAR := preload("res://街机小游戏/assets/balloon/carnival/balloon_gold.png")
const TEX_CANDY := preload("res://街机小游戏/assets/balloon/carnival/balloon_heart.png")
const TEX_GOLD := preload("res://街机小游戏/assets/balloon/carnival/balloon_gold.png")
const TEX_DIAMOND := preload("res://街机小游戏/assets/balloon/carnival/balloon_bunny.png")
const TEX_CAT_BALLOON := preload("res://街机小游戏/assets/balloon/carnival/balloon_cat.png")
const TEX_CHIP := preload("res://街机小游戏/assets/balloon/carnival/prize_star_v2.png")
const TEX_TICKET := preload("res://街机小游戏/assets/balloon/carnival/prize_ticket_v2.png")
const TEX_COIN := preload("res://街机小游戏/assets/balloon/carnival/prize_coin_v2.png")
const TEX_BURST := preload("res://街机小游戏/assets/balloon/carnival/pop_burst_v2.png")
const TEX_STAR := TEX_CHIP
const TEX_LATEX := preload("res://街机小游戏/assets/balloon/carnival/latex_v2.png")
const TEX_CLAW_BONUS := preload("res://街机小游戏/assets/balloon/carnival/claw_bonus_v2.png")
const TEX_SHARDS: Array[Texture2D] = [
	preload("res://街机小游戏/assets/balloon/shard_0.png"),
	preload("res://街机小游戏/assets/balloon/shard_1.png"),
	preload("res://街机小游戏/assets/balloon/shard_2.png"),
	preload("res://街机小游戏/assets/balloon/shard_3.png"),
]
const SHARDS_YELLOW: Array[Texture2D] = [
	preload("res://街机小游戏/assets/balloon/shards/yellow_0.png"),
	preload("res://街机小游戏/assets/balloon/shards/yellow_1.png"),
	preload("res://街机小游戏/assets/balloon/shards/yellow_2.png"),
	preload("res://街机小游戏/assets/balloon/shards/yellow_3.png"),
	preload("res://街机小游戏/assets/balloon/shards/yellow_4.png"),
]
const SHARDS_BLUE: Array[Texture2D] = [
	preload("res://街机小游戏/assets/balloon/shards/blue_0.png"),
	preload("res://街机小游戏/assets/balloon/shards/blue_1.png"),
	preload("res://街机小游戏/assets/balloon/shards/blue_2.png"),
	preload("res://街机小游戏/assets/balloon/shards/blue_3.png"),
	preload("res://街机小游戏/assets/balloon/shards/blue_4.png"),
]
const SHARDS_GREEN: Array[Texture2D] = [
	preload("res://街机小游戏/assets/balloon/shards/green_0.png"),
	preload("res://街机小游戏/assets/balloon/shards/green_1.png"),
	preload("res://街机小游戏/assets/balloon/shards/green_2.png"),
	preload("res://街机小游戏/assets/balloon/shards/green_3.png"),
	preload("res://街机小游戏/assets/balloon/shards/green_4.png"),
]
const SHARDS_STRIPE: Array[Texture2D] = [
	preload("res://街机小游戏/assets/balloon/shards/stripe_0.png"),
	preload("res://街机小游戏/assets/balloon/shards/stripe_1.png"),
	preload("res://街机小游戏/assets/balloon/shards/stripe_2.png"),
	preload("res://街机小游戏/assets/balloon/shards/stripe_3.png"),
	preload("res://街机小游戏/assets/balloon/shards/stripe_4.png"),
]
const SHARDS_STAR: Array[Texture2D] = [
	preload("res://街机小游戏/assets/balloon/shards/star_0.png"),
	preload("res://街机小游戏/assets/balloon/shards/star_1.png"),
	preload("res://街机小游戏/assets/balloon/shards/star_2.png"),
	preload("res://街机小游戏/assets/balloon/shards/star_3.png"),
	preload("res://街机小游戏/assets/balloon/shards/star_4.png"),
	preload("res://街机小游戏/assets/balloon/shards/star_5.png"),
	preload("res://街机小游戏/assets/balloon/shards/star_6.png"),
]
const SHARDS_CANDY: Array[Texture2D] = [
	preload("res://街机小游戏/assets/balloon/shards/candy_0.png"),
	preload("res://街机小游戏/assets/balloon/shards/candy_1.png"),
	preload("res://街机小游戏/assets/balloon/shards/candy_2.png"),
	preload("res://街机小游戏/assets/balloon/shards/candy_3.png"),
	preload("res://街机小游戏/assets/balloon/shards/candy_4.png"),
]
const SHARDS_GOLD: Array[Texture2D] = [
	preload("res://街机小游戏/assets/balloon/shards/gold_0.png"),
	preload("res://街机小游戏/assets/balloon/shards/gold_1.png"),
	preload("res://街机小游戏/assets/balloon/shards/gold_2.png"),
	preload("res://街机小游戏/assets/balloon/shards/gold_3.png"),
	preload("res://街机小游戏/assets/balloon/shards/gold_4.png"),
	preload("res://街机小游戏/assets/balloon/shards/gold_5.png"),
]
const SHARDS_DIAMOND: Array[Texture2D] = [
	preload("res://街机小游戏/assets/balloon/shards/diamond_0.png"),
	preload("res://街机小游戏/assets/balloon/shards/diamond_1.png"),
	preload("res://街机小游戏/assets/balloon/shards/diamond_2.png"),
	preload("res://街机小游戏/assets/balloon/shards/diamond_3.png"),
	preload("res://街机小游戏/assets/balloon/shards/diamond_4.png"),
	preload("res://街机小游戏/assets/balloon/shards/diamond_5.png"),
	preload("res://街机小游戏/assets/balloon/shards/diamond_6.png"),
	preload("res://街机小游戏/assets/balloon/shards/diamond_7.png"),
	preload("res://街机小游戏/assets/balloon/shards/diamond_8.png"),
	preload("res://街机小游戏/assets/balloon/shards/diamond_9.png"),
]
const COIN_DROP_SFX := preload("res://街机小游戏/audio/balloon/sfx_coin_drop.wav")
const COIN_DROP_SFX_MID := preload("res://街机小游戏/audio/balloon/sfx_coin_drop_mid.wav")
const COIN_DROP_SFX_BIG := preload("res://街机小游戏/audio/balloon/sfx_coin_drop_big.wav")
const COIN_DROP_MID_MIN := 10
const COIN_DROP_MID_MAX := 40
const CHIP_DROP_SFX := preload("res://街机小游戏/audio/balloon/sfx_chip_drop.wav")
const CHIP_DROP_SFX_BIG := preload("res://街机小游戏/audio/balloon/sfx_chip_drop_big.wav")
const CHIP_DROP_BIG_MIN := 5
const TICKET_DROP_SFX := preload("res://街机小游戏/audio/balloon/sfx_ticket_drop.wav")
const WIND_BLOW_SFX: Array[AudioStream] = [
	preload("res://街机小游戏/audio/balloon/sfx_wind_blow.wav"),
	preload("res://街机小游戏/audio/balloon/sfx_wind_blow_2.wav"),
	preload("res://街机小游戏/audio/balloon/sfx_wind_blow_3.wav"),
]
const PRIZE_DROP_VOL_DB := 10.0
const POP_VOL_DB := 8.0
const WIND_VOL_DB := -2.0
const BGM_VOL_DB := -1.5
const BGM := preload("res://街机小游戏/audio/balloon/bgm.ogg")
const POP_SFX: Array[AudioStream] = [
	preload("res://街机小游戏/audio/balloon/sfx_pop.wav"),
	preload("res://街机小游戏/audio/balloon/sfx_pop_2.wav"),
	preload("res://街机小游戏/audio/balloon/sfx_pop_3.wav"),
	preload("res://街机小游戏/audio/balloon/sfx_pop_4.wav"),
	preload("res://街机小游戏/audio/balloon/sfx_pop_5.wav"),
	preload("res://街机小游戏/audio/balloon/sfx_pop_6.wav"),
	preload("res://街机小游戏/audio/balloon/sfx_pop_7.wav"),
]
const POP_VOICES := 4
const FX_CAP := 200
const SCORE_PER_TICKET := 3
const SCORE_PER_CHIP := 6
const SCORE_PER_COIN := 10
const LOOT_COUNT_MIN := 2
const LOOT_COUNT_MAX := 10
const COIN_BUNDLE_MIN := 10
const COIN_BUNDLE_STEP := 10
const COIN_BUNDLE_TIERS := 10
const CHAIN_WINDOW_MS := 700
const WIND_HEAD := 0.65
const WIND_TAIL := 1.45
const WIND_DRIFT_YANKS := 0.10
const WIND_WARN := 0.5
const WIND_BLOW := 3.5
const WIND_GAP := 4.0
const WIND_FIRST := 4.0
const WIND_COUNT := 3
const WIND_SWING_PREVIEW_HEAD := 0.85
const WIND_SWING_PREVIEW_TAIL := 1.5
const WIND_SWING_SWEEP_HEAD := 0.9
const WIND_SWING_SWEEP_TAIL := 3.8
const WIND_SWING_BACK_HEAD := 1.6
const WIND_SWING_BACK_TAIL := 4.2
const CAT_SIT_H := 90.0
const TEX_CAT_SIT_0 := preload("res://街机小游戏/assets/balloon/cat_sit_0.png")
const TEX_CAT_SIT_1 := preload("res://街机小游戏/assets/balloon/cat_sit_1.png")
const TEX_CAT_LICK_0 := preload("res://街机小游戏/assets/balloon/cat_lick_0.png")
const TEX_CAT_LICK_1 := preload("res://街机小游戏/assets/balloon/cat_lick_1.png")
const BIRD_BODY_H := 75.0
const BIRD_FLY_SEC := 14.0
const BIRD_X_MIN := 0.04
const BIRD_X_MAX := 0.58
const BIRD_SKY_TOP := 0.19
const BIRD_Y_MIN := 0.22
const BIRD_Y_MAX := 0.30
const BIRD_WING_PERIOD := 0.14
const TEX_BIRD_FLY_0 := preload("res://街机小游戏/assets/balloon/carnival/bird_fly_0.png")
const TEX_BIRD_FLY_1 := preload("res://街机小游戏/assets/balloon/carnival/bird_fly_1.png")
const TEX_SPECTATOR_0 := preload("res://街机小游戏/assets/balloon/spectator_boy_0.png")
const TEX_SPECTATOR_1 := preload("res://街机小游戏/assets/balloon/spectator_boy_1.png")
const SPECTATOR_X := 0.892
const TEX_PROGRESS_TRACK := preload("res://街机小游戏/assets/balloon/progress_track.png")
const TEX_PROGRESS_FILL := preload("res://街机小游戏/assets/balloon/progress_fill.png")
const TEX_PROGRESS_STAR_OFF := preload("res://街机小游戏/assets/balloon/progress_star_off.png")
const TEX_PROGRESS_STAR_ON := preload("res://街机小游戏/assets/balloon/progress_star_on.png")
const TEX_PROGRESS_CHEST_CLOSED := preload("res://街机小游戏/assets/balloon/progress_chest_closed.png")
const TEX_PROGRESS_CHEST_OPEN := preload("res://街机小游戏/assets/balloon/progress_chest_open.png")
const PROGRESS_PER_POP := 7.0
const PROGRESS_MAX := 100.0
const PROGRESS_MILESTONES := [0.25, 0.5, 0.75, 1.0]
const PROGRESS_REWARDS := [300, 300, 300, 500]
## 1080² 画布内轨道/充能区域（像素）。充能图比轨道更靠下、更高，不能和轨道用同一裁切。
const PROGRESS_TRACK_REGION := Rect2(70, 487, 925, 79)
const PROGRESS_FILL_REGION := Rect2(36, 512, 1004, 88)
## 充能条在轨道贴图内的落点（轨道区域局部像素），铺满内槽
const PROGRESS_GROOVE_IN_TRACK := Rect2(8, 14, 910, 51)
const PROGRESS_CHEST_CLOSED_REGION := Rect2(316, 337, 448, 422)
const PROGRESS_CHEST_OPEN_REGION := Rect2(221, 179, 655, 616)
const PROGRESS_STAR_X_N := [0.25, 0.5, 0.75]
const PROGRESS_BAR_W := 420.0
const PROGRESS_BAR_TOP := 14.0

var active := false
var debug_hold := false

var _phase := "idle"
var _time_left := PLAY_SEC
var _settle_left := 0.0
var _score := 0
var _awarded := false
var _claw_bonuses := 0
var _board_pull := false
var _scroll := 0.0
var _yank_from := 0.0
var _yank_to := 0.0
var _yank_t := 1.0
var _pose := "idle"
var _pull_taps := 0
var _view := Vector2(1280, 720)
var _fist := Vector2(420, 340)
var _rope_join := Vector2.ZERO
var _rope_forward := Vector2.RIGHT
var _rope_blend: ShaderMaterial
var _needle_tip := Vector2(480, 300)
var _stand_x := 380.0
var _slack := 0.0
var _sway := 0.0
var _kite_phase := 0.0
var _kite_curl := 0.0
var _kite_kick := 0.0
var _rng := RandomNumberGenerator.new()
var _balloons: Array = []
var _next_index := 0
var _fx: Array = []
var _chain := 1
var _last_pop_msec := 0
var _glow_left := 0.0
var _glow_dur := 0.3
var _glow_peak := 0.0

var _bg: Sprite2D
var _post: Sprite2D
var _rope: RopeDrawer
var _rope_hand: RopeDrawer
var _char: Sprite2D
var _char_anim_t := 0.44
var _face_textures: Dictionary = {}
var _face_rng := RandomNumberGenerator.new()
var _blink_wait := 2.4
var _blink_age := 1.0
var _face_happy_left := 0.0
var _needle: Sprite2D
var _hud: CanvasLayer
var _time_label: Label
var _score_label: Label
var _hint_label: Label
var _settle_label: Label
var _progress := 0.0
var _progress_display := 0.0
var _progress_milestones_claimed := 0
var _progress_root: Control
var _progress_track: TextureRect
var _progress_clip: Control
var _progress_fill: TextureRect
var _progress_stars: Array[TextureRect] = []
var _progress_chest: TextureRect
var _progress_groove_size := Vector2.ZERO
var _glow: ColorRect
var _gust: WindGust
var _wind_dir := 0
var _wind_phase := "off"
var _wind_left := 0.0
var _wind_wait := WIND_FIRST
var _winds_done := 0
var _wind_prev := 0
var _wind_prev2 := 0
var _wind_vis := 0.0
var _wind_vis_dir := 0
var _pop_voices: Array[AudioStreamPlayer] = []
var _coin_drop_player: AudioStreamPlayer
var _chip_drop_player: AudioStreamPlayer
var _ticket_drop_player: AudioStreamPlayer
var _wind_player: AudioStreamPlayer
var _bgm_player: AudioStreamPlayer
var _pop_voice_i := 0
var _cat: Sprite2D
var _cat_anim := "idle"
var _cat_timer := 0.0
var _cat_blink_wait := 2.8
var _cat_lick_wait := 10.0
var _cat_lick_step := 0
var _bird0: Sprite2D
var _bird1: Sprite2D
var _bird0_x := 0.0
var _bird1_x := 0.0
var _bird0_dir := 1
var _bird1_dir := -1
var _bird0_y_phase := 0.0
var _bird1_y_phase := 2.1
var _bird_wing_t := 0.0
var _bird_active := false
var _sky_balloon_decor: Node2D
var _bird_wait := 3.0
var _bird_height := 0.28
var _spectator: Sprite2D
var _spectator_anim := "idle"
var _spectator_timer := 0.0
var _spectator_blink_wait := 2.8


func _ready() -> void:
	_face_rng.randomize()
	for pose in ["idle","reach","pull"]:
		for state in ["smile","half","blink","effort"]:
			_face_textures[pose+"_"+state] = load("res://街机小游戏/assets/balloon/carnival/character_"+pose+"_"+state+".png")
	visible = false
	z_index = 100
	set_process(false)
	_build()
	_build_pop_voices()
	if get_tree().current_scene == self:
		call_deferred("start_round")


func start_round() -> void:
	_points_round_id = GameState.begin_points_round("balloon")
	_char_anim_t = 0.44
	_blink_wait = _face_rng.randf_range(1.8,3.0)
	_blink_age = 1.0
	_face_happy_left = 0.0
	_carnival_pops = 0
	_pop_counts = [0, 0, 0, 0, 0, 0]
	visible = true
	active = true
	_awarded = false
	_claw_bonuses = 0
	_board_pull = false
	_score = 0
	_scroll = 0.0
	_yank_t = 1.0
	_pose = "idle"
	_pull_taps = 0
	_phase = "play"
	_time_left = PLAY_SEC
	_settle_left = 0.0
	_chain = 1
	_last_pop_msec = 0
	_glow_left = 0.0
	if _glow:
		_glow.color = Color(1, 1, 1, 0)
	_reset_progress()
	_reset_wind()
	_rng.seed = Time.get_ticks_msec()
	_kite_phase = _rng.randf() * TAU
	_kite_curl = _rng.randf() * TAU
	_kite_kick = 0.0
	_reset_cat()
	_reset_birds()
	_sky_balloon_decor.reset()
	_reset_spectator()
	_clear_spawned()
	_layout()
	_build_string()
	_update_hud()
	set_process(true)
	_play_bgm()
	BoardLink.take_control()


func stop_and_hide() -> void:
	if _carnival_hud:
		_carnival_hud.visible = false
	active = false
	_phase = "idle"
	_board_pull = false
	debug_hold = false
	_pull_taps = 0
	set_process(false)
	for voice in _pop_voices:
		voice.stop()
	_stop_wind_sfx()
	_stop_bgm()
	_clear_spawned()
	visible = false
	_sky_balloon_decor.reset()
	BoardLink.release_control()


func on_board_key(mask: int, _pressed: bool = true) -> void:
	if not active or _phase != "play":
		_board_pull = false
		return
	var down := (mask & BoardLink.KEY_ENTER) != 0
	if down and not _board_pull:
		_queue_pull()
	_board_pull = down


func _unhandled_input(event: InputEvent) -> void:
	if not active or _phase != "play":
		return
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode in [KEY_O,KEY_SPACE] or event.physical_keycode == KEY_O):
		_queue_pull()
		get_viewport().set_input_as_handled()


func _queue_pull() -> void:
	_pull_taps = mini(_pull_taps + 1, 8)
	_char_anim_t = 0.06 if _char_anim_t < 0.055 else 0.0


func _build() -> void:
	_bg = Sprite2D.new()
	_bg.name = "Bg"
	_bg.texture = TEX_BG
	_bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_bg.centered = false
	_bg.z_index = 0
	_bg.material = null
	add_child(_bg)
	_sky_balloon_decor = preload("res://街机小游戏/scripts/balloon_sky_decor.gd").new()
	add_child(_sky_balloon_decor)
	var bouquet := CarnivalBouquet.new()
	bouquet.name = "DecorativeBouquet"
	bouquet.z_index = 2
	bouquet.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(bouquet)

	_bird0 = _make_bird("SkyBird0")
	_bird1 = _make_bird("SkyBird1")
	add_child(_bird0)
	add_child(_bird1)

	_post = Sprite2D.new()
	_post.name = "StallPost"
	_post.texture = TEX_POST
	_post.centered = false
	_post.z_index = 4
	add_child(_post)

	_rope = RopeDrawer.new()
	_rope.name = "Rope"
	_rope.tex = TEX_ROPE
	_rope.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_rope.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var rope_surface := ShaderMaterial.new()
	rope_surface.shader = preload("res://街机小游戏/scripts/balloon_rope_surface.gdshader")
	_rope.material = rope_surface
	_rope.z_index = 1
	add_child(_rope)

	_gust = WindGust.new()
	_gust.name = "Wind"
	_gust.head_tex = TEX_WIND_HEAD
	_gust.tail_tex = TEX_WIND_TAIL
	_gust.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_gust.z_index = 1
	add_child(_gust)

	_cat = Sprite2D.new()
	_cat.name = "StallCat"
	_cat.texture = TEX_CAT_SIT_0
	_cat.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_cat.centered = false
	_cat.z_index = 2
	add_child(_cat)

	_rope_hand = RopeDrawer.new()
	_rope_hand.name = "RopeHand"
	_rope_hand.tex = TEX_ROPE
	_rope_hand.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_rope_hand.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_rope_hand.material = rope_surface
	_rope_hand.z_index = 4
	add_child(_rope_hand)

	_char = Sprite2D.new()
	_char.name = "Youyou"
	_char.texture = TEX_IDLE
	_rope_blend = ShaderMaterial.new()
	_rope_blend.shader = preload("res://街机小游戏/scripts/balloon_rope_blend.gdshader")
	_char.material = _rope_blend
	_char.z_index = 5
	add_child(_char)

	_spectator = Sprite2D.new()
	_spectator.name = "SpectatorBoy"
	_spectator.texture = TEX_SPECTATOR_0
	_spectator.z_index = 5
	add_child(_spectator)

	_needle = Sprite2D.new()
	_needle.name = "Needle"
	_needle.texture = TEX_NEEDLE
	_needle.z_index = 7
	add_child(_needle)

	_hud = CanvasLayer.new()
	_hud.name = "Hud"
	_hud.layer = 30
	add_child(_hud)
	_glow = ColorRect.new()
	_glow.name = "Glow"
	_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow.color = Color(1, 1, 1, 0)
	_hud.add_child(_glow)
	_time_label = _make_label("Time", Vector2(28, 18), 28)
	_score_label = _make_label("Score", Vector2(980, 18), 28)
	_hint_label = _make_label("Hint", Vector2(28, 660), 22)
	_settle_label = _make_label("Settle", Vector2(390, 250), 48)
	_settle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_settle_label.visible = false
	_hud.add_child(_time_label)
	_hud.add_child(_score_label)
	_hud.add_child(_hint_label)
	_hud.add_child(_settle_label)
	_build_progress_hud()
	_carnival_hud = CarnivalHud.new()
	_hud.add_child(_carnival_hud)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


func _build_progress_hud() -> void:
	_progress_root = Control.new()
	_progress_root.name = "ProgressBar"
	_progress_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_progress_root)
	_progress_track = TextureRect.new()
	_progress_track.name = "Track"
	_progress_track.texture = _progress_make_atlas(TEX_PROGRESS_TRACK, PROGRESS_TRACK_REGION)
	_progress_track.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_progress_track.stretch_mode = TextureRect.STRETCH_SCALE
	_progress_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_root.add_child(_progress_track)
	_progress_clip = Control.new()
	_progress_clip.name = "FillClip"
	_progress_clip.clip_contents = true
	_progress_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_root.add_child(_progress_clip)
	_progress_fill = TextureRect.new()
	_progress_fill.name = "Fill"
	_progress_fill.texture = _progress_make_atlas(TEX_PROGRESS_FILL, PROGRESS_FILL_REGION)
	_progress_fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_progress_fill.stretch_mode = TextureRect.STRETCH_SCALE
	_progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_clip.add_child(_progress_fill)
	for i in 3:
		var star := TextureRect.new()
		star.name = "Star%d" % i
		star.texture = TEX_PROGRESS_STAR_OFF
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_progress_root.add_child(star)
		_progress_stars.append(star)
	_progress_chest = TextureRect.new()
	_progress_chest.name = "Chest"
	_progress_chest.texture = _progress_make_atlas(
		TEX_PROGRESS_CHEST_CLOSED, PROGRESS_CHEST_CLOSED_REGION
	)
	_progress_chest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_progress_chest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_progress_chest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_root.add_child(_progress_chest)


func _make_label(node_name: String, pos: Vector2, size: int) -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = pos
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(0.38, 0.2, 0.06))
	label.add_theme_color_override("font_outline_color", Color(1, 0.98, 0.92))
	label.add_theme_constant_override("outline_size", 8)
	return label


func _layout() -> void:
	_view = get_viewport_rect().size
	if _view.x < 200.0 or _view.y < 200.0:
		_view = Vector2(1280, 720)
	var bg_scale := maxf(_view.x / TEX_BG.get_width(), _view.y / TEX_BG.get_height())
	_bg.scale = Vector2.ONE * bg_scale
	_bg.position = (_view - TEX_BG.get_size() * bg_scale) * .5
	var post_scale := maxf(_view.x / TEX_POST.get_width(), _view.y / TEX_POST.get_height())
	_post.scale = Vector2.ONE * post_scale
	_post.position = (_view - TEX_POST.get_size() * post_scale) * .5
	# 店铺柜台在图高约 84.5%。人只露出上半身，放在左下红框里。
	var counter_y := _view.y * 0.845
	_stand_x = _view.x * 0.09
	_slack = 0.0
	_pose = "idle"
	_place_char()
	# 钉子立在柜台中部，针尖落在标注的圆里。
	_needle_tip = Vector2(_view.x * 0.39, _view.y * 0.70)
	var needle_h := counter_y - _needle_tip.y
	var nscale := needle_h / TEX_NEEDLE.get_height()
	_needle.scale = Vector2(nscale, nscale)
	# 裁掉透明留白后的贴图顶点直接对准碰撞针尖。
	_needle.position = _needle_tip + Vector2(0,needle_h*0.5)
	_paint_kite()
	_score_label.position = Vector2(_view.x - 250.0, 18)
	_hint_label.position = Vector2(28, _view.y - 58)
	_settle_label.position = Vector2(_view.x * 0.5 - 220.0, _view.y * 0.32)
	_place_cat()
	_place_spectator()
	_place_birds()
	_layout_progress_hud()
	# Hide the old spectators; the sky bird is controlled by its flight timer.
	for decor in [_cat,_spectator]:
		decor.visible = false
	for balloon in _balloons:
		var body: Sprite2D = balloon.node.get_node_or_null("Body")
		if body:
			body.scale = Vector2.ONE*(BALLOON_H*(_view.y/720.0)/TEX_RED.get_height())
			body.position = Vector2(0,-KNOT_FROM_CENTER*BALLOON_H*(_view.y/720.0))


func _progress_make_atlas(tex: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = region
	return atlas


func _layout_progress_hud() -> void:
	if _progress_root == null:
		return
	var sx := _view.x / 1280.0
	var sy := _view.y / 720.0
	var bar_w := PROGRESS_BAR_W * sx
	var bar_h := bar_w * PROGRESS_TRACK_REGION.size.y / PROGRESS_TRACK_REGION.size.x
	_progress_root.position = Vector2((_view.x - bar_w) * 0.5, PROGRESS_BAR_TOP * sy)
	_progress_root.size = Vector2(bar_w, bar_h)
	_progress_track.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_progress_track.position = Vector2.ZERO
	_progress_track.size = Vector2(bar_w, bar_h)
	var track_scale := Vector2(
		bar_w / PROGRESS_TRACK_REGION.size.x,
		bar_h / PROGRESS_TRACK_REGION.size.y
	)
	_progress_groove_size = PROGRESS_GROOVE_IN_TRACK.size * track_scale
	_progress_clip.position = PROGRESS_GROOVE_IN_TRACK.position * track_scale
	var star_sz := bar_h * 1.35
	for i in _progress_stars.size():
		var star := _progress_stars[i]
		var sx_n: float = PROGRESS_STAR_X_N[i]
		star.size = Vector2(star_sz, star_sz)
		star.position = Vector2(bar_w * sx_n - star_sz * 0.5, bar_h * 0.5 - star_sz * 0.52)
	var chest_h := bar_h * 2.05
	var chest_w := chest_h * PROGRESS_CHEST_CLOSED_REGION.size.x / PROGRESS_CHEST_CLOSED_REGION.size.y
	_progress_chest.size = Vector2(chest_w, chest_h)
	_progress_chest.position = Vector2(bar_w - chest_w * 0.38, bar_h * 0.5 - chest_h * 0.58)
	_sync_progress_fill()
	_sync_progress_stars_chest()


func _sync_progress_fill() -> void:
	if _progress_fill == null or _progress_clip == null:
		return
	var ratio := clampf(_progress_display / PROGRESS_MAX, 0.0, 1.0)
	var full := _progress_groove_size
	if full.x < 1.0:
		return
	_progress_clip.size = Vector2(full.x * ratio, full.y)
	_progress_fill.position = Vector2.ZERO
	_progress_fill.size = full
	_progress_fill.scale = Vector2.ONE


func _sync_progress_stars_chest() -> void:
	for i in _progress_stars.size():
		var bit := 1 << i
		var on := (_progress_milestones_claimed & bit) != 0
		_progress_stars[i].texture = TEX_PROGRESS_STAR_ON if on else TEX_PROGRESS_STAR_OFF
	if _progress_chest:
		var chest_open := (_progress_milestones_claimed & (1 << 3)) != 0
		if chest_open:
			_progress_chest.texture = _progress_make_atlas(
				TEX_PROGRESS_CHEST_OPEN, PROGRESS_CHEST_OPEN_REGION
			)
		else:
			_progress_chest.texture = _progress_make_atlas(
				TEX_PROGRESS_CHEST_CLOSED, PROGRESS_CHEST_CLOSED_REGION
			)


func _progress_bar_center() -> Vector2:
	var sx := _view.x / 1280.0
	var sy := _view.y / 720.0
	var bar_w := PROGRESS_BAR_W * sx
	var bar_h := bar_w * PROGRESS_TRACK_REGION.size.y / PROGRESS_TRACK_REGION.size.x
	return Vector2(_view.x * 0.5, PROGRESS_BAR_TOP * sy + bar_h * 0.5)


func _reset_progress() -> void:
	_progress = 0.0
	_progress_display = 0.0
	_progress_milestones_claimed = 0
	_sync_progress_fill()
	_sync_progress_stars_chest()


func _add_balloon_progress() -> void:
	_progress = minf(_progress + PROGRESS_PER_POP, PROGRESS_MAX)
	for i in PROGRESS_MILESTONES.size():
		var bit := 1 << i
		if _progress_milestones_claimed & bit:
			continue
		if _progress + 0.001 < PROGRESS_MILESTONES[i] * PROGRESS_MAX:
			continue
		_progress_milestones_claimed |= bit
		var bonus: int = int(PROGRESS_REWARDS[i])
		_score += bonus
		_float_points(_progress_bar_center(), bonus, i == PROGRESS_REWARDS.size() - 1)
		_flash_glow(Color(1.0, 0.85, 0.35, 0.24), 0.38)
		ArcadeAudio.sfx_start()
	_sync_progress_stars_chest()
	_update_hud()


func _make_bird(node_name: String) -> Sprite2D:
	var spr := Sprite2D.new()
	spr.name = node_name
	spr.texture = TEX_BIRD_FLY_0
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	spr.centered = true
	spr.z_index = 1
	return spr


func _place_cat() -> void:
	if _cat == null:
		return
	var u := _view.y / 720.0
	var counter_y := _view.y * 0.845
	var tex_h := float(TEX_CAT_SIT_0.get_height())
	var tex_w := float(TEX_CAT_SIT_0.get_width())
	var sc := u * CAT_SIT_H / tex_h
	_cat.scale = Vector2(sc, sc)
	var w := tex_w * sc
	var h := tex_h * sc
	_cat.position = Vector2(_view.x * 0.74 - w * 0.5, counter_y - h)


func _place_spectator() -> void:
	if _spectator == null:
		return
	var tex: Texture2D = _spectator.texture
	if tex == null:
		tex = TEX_SPECTATOR_0
	var h := float(tex.get_height())
	var cut_y := h * CHAR_CUT
	var scale := _view.y * (1.0 - CHAR_BOX_TOP) / cut_y
	_spectator.scale = Vector2(scale, scale)
	_spectator.position = Vector2(
		_view.x * SPECTATOR_X,
		_view.y * CHAR_BOX_TOP + h * 0.5 * scale
	)


func _reset_spectator() -> void:
	_spectator_anim = "idle"
	_spectator_timer = 0.0
	_spectator_blink_wait = _rng.randf_range(2.0, 3.8)
	if _spectator:
		_spectator.texture = TEX_SPECTATOR_0


func _step_spectator(delta: float) -> void:
	if _spectator == null:
		return
	if _spectator_anim == "blink":
		_spectator_timer -= delta
		if _spectator_timer <= 0.0:
			_spectator_anim = "idle"
			_spectator.texture = TEX_SPECTATOR_0
		return
	_spectator.texture = TEX_SPECTATOR_0
	_spectator_blink_wait -= delta
	if _spectator_blink_wait <= 0.0:
		_spectator_blink_wait = _rng.randf_range(2.2, 4.2)
		_spectator_anim = "blink"
		_spectator.texture = TEX_SPECTATOR_1
		_spectator_timer = 0.14


func _reset_cat() -> void:
	_cat_anim = "idle"
	_cat_timer = 0.0
	_cat_lick_step = 0
	_cat_blink_wait = _rng.randf_range(2.0, 3.5)
	_cat_lick_wait = _rng.randf_range(9.0, 14.0)
	if _cat:
		_cat.texture = TEX_CAT_SIT_0


func _step_cat(delta: float) -> void:
	if _cat == null:
		return
	if _cat_anim == "lick":
		_cat_timer -= delta
		if _cat_timer > 0.0:
			return
		_cat_lick_step += 1
		match _cat_lick_step:
			1:
				_cat.texture = TEX_CAT_LICK_0
				_cat_timer = 0.22
			2:
				_cat.texture = TEX_CAT_LICK_1
				_cat_timer = 0.34
			3:
				_cat.texture = TEX_CAT_LICK_1
				_cat_timer = 0.28
			4:
				_cat.texture = TEX_CAT_LICK_0
				_cat_timer = 0.18
			_:
				_cat_anim = "idle"
				_cat_lick_step = 0
				_cat.texture = TEX_CAT_SIT_0
		return
	if _cat_anim == "blink":
		_cat_timer -= delta
		if _cat_timer <= 0.0:
			_cat_anim = "idle"
			_cat.texture = TEX_CAT_SIT_0
		return
	_cat.texture = TEX_CAT_SIT_0
	_cat_blink_wait -= delta
	_cat_lick_wait -= delta
	if _cat_lick_wait <= 0.0:
		_cat_lick_wait = _rng.randf_range(9.0, 14.0)
		_cat_anim = "lick"
		_cat_lick_step = 0
		_cat_timer = 0.0
		return
	if _cat_blink_wait <= 0.0:
		_cat_blink_wait = _rng.randf_range(2.2, 4.2)
		_cat_anim = "blink"
		_cat.texture = TEX_CAT_SIT_1
		_cat_timer = 0.14


func _reset_birds() -> void:
	_bird_active = false
	_bird_wait = _face_rng.randf_range(2.0,4.0)
	_bird_wing_t = 0.0
	_place_birds()


func _place_birds() -> void:
	if _bird0 == null:
		return
	_bird1.visible = false
	_bird0.visible = _bird_active and _phase == "play"
	var wing_i := int(floor(_bird_wing_t / BIRD_WING_PERIOD)) % 2
	_bird0.texture = TEX_BIRD_FLY_0 if wing_i == 0 else TEX_BIRD_FLY_1
	var u := _view.y / 720.0
	_bird0.scale = Vector2.ONE * u * BIRD_BODY_H / TEX_BIRD_FLY_0.get_height()
	_bird0.flip_h = _bird0_dir < 0
	_bird0.position = Vector2(_bird0_x,_view.y*_bird_height+sin(_bird_wing_t*3.0)*4.0*u)


func _step_birds(delta: float) -> void:
	if _bird0 == null:
		return
	if _phase != "play":
		_bird0.visible = false
		_bird1.visible = false
		return
	if not _bird_active:
		_bird_wait -= delta
		if _bird_wait <= 0.0:
			_bird_active = true
			_bird0_dir = 1 if _face_rng.randf() < .5 else -1
			_bird0_x = -60.0 if _bird0_dir > 0 else _view.x+60.0
			_bird_height = _face_rng.randf_range(.25,.38)
			_bird_wing_t = 0.0
	else:
		_bird_wing_t += delta
		_bird0_x += float(_bird0_dir)*(_view.x+120.0)/9.0*delta
		if _bird0_x < -65.0 or _bird0_x > _view.x+65.0:
			_bird_active = false
			_bird_wait = _face_rng.randf_range(6.0,10.0)
	_place_birds()


func _step_face(delta: float) -> void:
	_face_happy_left = maxf(0,_face_happy_left-delta)
	_blink_age += delta
	_blink_wait -= delta
	if _blink_wait<=0.0:
		_blink_age = 0.0
		# Facial timing uses its own RNG and does not affect prize rolls.
		_blink_wait = _face_rng.randf_range(2.5,4.5)

func _expression_texture(base: Texture2D) -> Texture2D:
	var pose := "reach" if base==TEX_REACH else ("pull" if base==TEX_YANK else "idle")
	var state := "smile"
	if _blink_age<0.045 or (_blink_age>=0.12 and _blink_age<0.18):
		state = "half"
	elif _blink_age<0.12:
		state = "blink"
	elif _char_anim_t>=0.06 and _char_anim_t<0.23:
		state = "effort"
	elif _char_anim_t<0.34 or _face_happy_left>0.0:
		return base
	return _face_textures.get(pose+"_"+state,base)

func _place_char() -> void:
	var size := Vector2(0.0,_view.y*0.65)
	size.x = size.y*TEX_IDLE.get_width()/TEX_IDLE.get_height()
	var from: Texture2D = TEX_IDLE
	var to: Texture2D = TEX_IDLE
	var from_grip := Vector2(0.86,0.405)
	var to_grip := from_grip
	var blend := 0.0
	if _char_anim_t<0.055:
		to = TEX_REACH
		to_grip = Vector2(0.91,0.36)
		blend = _char_anim_t/0.055
	elif _char_anim_t<0.16:
		from = TEX_REACH
		to = TEX_YANK
		from_grip = Vector2(0.91,0.36)
		to_grip = Vector2(0.76,0.44)
		blend = (_char_anim_t-0.055)/0.105
	elif _char_anim_t<0.44:
		from = TEX_YANK
		from_grip = Vector2(0.76,0.44)
		blend = (_char_anim_t-0.16)/0.28
	blend = smoothstep(0.0,1.0,blend)
	var pull := sin(PI*clampf(_char_anim_t/0.44,0,1)) if _char_anim_t<0.44 else 0.0
	var breathing := sin(_sway*1.8)*1.2
	# Opaque sprite keyframes avoid double faces/limbs from whole-body alpha blending.
	_char.texture = _expression_texture(from if blend<0.5 else to)
	_char.scale = Vector2.ONE*(size.y/TEX_IDLE.get_height())
	_char.position = Vector2(_stand_x,_view.y*0.47)+size*0.5+Vector2(-14.0*pull,5.0*pull+breathing)*(_view.y/720.0)
	_char.rotation_degrees = -2.0*pull
	_char.modulate.a = 1.0
	var grip := from_grip if blend<0.5 else to_grip
	_fist = _char.position+((grip-Vector2(0.5,0.5))*size).rotated(_char.rotation)
	var body := from if blend<0.5 else to
	var end_pixel := Vector2(728,385.5)
	var edge := 740.0
	var direction := Vector2(20,-5)
	if body==TEX_REACH:
		end_pixel = Vector2(748,315)
		edge = 758.0
		direction = Vector2(12,-4)
	elif body==TEX_YANK:
		end_pixel = Vector2(623,405)
		edge = 635.0
		direction = Vector2(20,-5.5)
	_rope_blend.set_shader_parameter("rope_edge_px",edge)
	_rope_join = _char.position+((end_pixel-Vector2(384,512))*_char.scale).rotated(_char.rotation)
	_rope_forward = direction.rotated(_char.rotation).normalized()
	return


func _place_char_legacy() -> void:
	var tex: Texture2D = TEX_IDLE
	# 贴图上握住线的那只拳头。待机是胸前靠右的拳，不是脸。
	var fist := Vector2(410, 441)
	if _pose == "reach":
		tex = TEX_REACH
		fist = Vector2(436, 256)
	elif _pose == "yank":
		tex = TEX_YANK
		fist = Vector2(446, 488)
	var h := float(tex.get_height())
	var cut_y := h * CHAR_CUT
	var scale := _view.y * (1.0 - CHAR_BOX_TOP) / cut_y
	_char.texture = tex
	_char.scale = Vector2(scale, scale)
	var w := float(tex.get_width())
	_char.position = Vector2(
		_stand_x,
		_view.y * CHAR_BOX_TOP + h * 0.5 * scale
	)
	_fist = _char.position + (fist - Vector2(w * 0.5, h * 0.5)) * scale


func _bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return p0 * (u * u * u) + p1 * (3.0 * u * u * t) + p2 * (3.0 * u * t * t) + p3 * (t * t * t)


func _kite_point(s: float, sway: bool = true, windy: bool = true) -> Vector2:
	var u := _view.y / 720.0
	var calm := _calm_vanish()
	var aim := Vector2(_view.x * 1.08, 0.0) - _needle_tip
	if aim.length() < 1.0:
		aim = Vector2(1.0, -0.4)
	aim = aim.normalized()
	if s <= 0.0:
		# 从原件已有绳子的末端接出，首段藏在角色后方，避免重叠出第二股绳。
		var t := 1.0 - clampf(-s / 0.16, 0.0, 1.0)
		var span := _rope_join.distance_to(_needle_tip)
		var sag := Vector2(0.0,_slack*0.12*u)
		var p0 := _rope_join
		var p3 := _needle_tip
		var p1 := p0+_rope_forward*span*0.33+sag
		var p2 := _needle_tip - aim * span * 0.33+sag
		return _bezier(p0, p1, p2, p3, t)
	var along := clampf(s, 0.0, 1.3)
	var k := pow(along, 0.78)
	var p := _needle_tip.lerp(calm, k) + _kite_bend(k, u, false, false)
	# One rigid rotation for the whole garland: wind cannot stretch its spacing.
	if windy:
		p = _needle_tip + (p - _needle_tip).rotated(_bundle_sway_angle())
	return p


func _bundle_sway_angle() -> float:
	var wind := clampf(_wind_vis, 0.0, 1.0)
	return sin(_kite_phase) * lerpf(.14,.21,wind) + float(_wind_vis_dir) * wind * .035


func _kite_bend(k: float, u: float, _sway_on: bool, _blown: bool) -> Vector2:
	# Keep the same packed S silhouette; only the entire bundle sways left/right.
	var envelope := smoothstep(0.0,.12,k) * (1.0 - smoothstep(.85,1.0,k))
	return Vector2.RIGHT * sin(k * TAU + .8) * lerpf(60.0,150.0,k) * envelope * u


func _step_kite_shape(delta: float) -> void:
	var rate := lerpf(1.05, 1.70, clampf(_wind_vis, 0.0, 1.0))
	_kite_phase += delta * rate
	_kite_curl += delta * 0.12
	_kite_kick = move_toward(_kite_kick, 0.0, delta * 0.7)


func _calm_vanish() -> Vector2:
	# Keep the entry beyond the screen, including while the string swings in wind.
	return Vector2(_view.x*1.14,-_view.y*0.16)


func _depth_scale(s: float) -> float:
	# Perspective projection: nearby balloon bodies are much larger than the tail.
	return 1.16 / (1.0 + 6.4 * clampf(s, 0.0, 1.2))


func _gap_at(s: float) -> float:
	return _gap_at_legacy(s)


func _gap_at_legacy(s: float) -> float:
	# 间距跟着气球变小一起收，整串从近到远都挤在绳子上。
	var t := clampf((s - 0.12) / 0.88, 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)
	return DEPTH_GAP * lerpf(1.0, 0.30, t)


func _balloon_s(index: int) -> float:
	var pack := float(index) - _scroll / DEPTH_GAP
	if pack <= 0.0:
		return 0.05 + pack * DEPTH_GAP
	var s := 0.05
	var left := pack
	while left > 0.0 and s < 1.5:
		var g := _gap_at(s)
		var step := minf(left, 1.0)
		s += g * step
		left -= step
	return s


func _paint_kite() -> void:
	var far := PackedVector2Array()
	var far_w := PackedFloat32Array()
	var hand := PackedVector2Array()
	var hand_w := PackedFloat32Array()
	var u := _view.y / 720.0
	var steps := 192
	# Match the source rope in the character image at exactly the character's scale.
	var cord_width := 30.0*(_view.y*0.65/1024.0)
	for i in steps + 1:
		var s := lerpf(-0.16, 0.0, float(i) / float(steps))
		hand.append(_kite_point(s))
		hand_w.append(cord_width)
	var samples: Array[float] = []
	for i in steps + 1:
		samples.append(lerpf(0.0, 1.05, float(i) / float(steps)))
	# Include every real knot in the mesh, not just nearby interpolated samples.
	for balloon in _balloons:
		if balloon.alive:
			var knot_s := _balloon_s(int(balloon.index))
			if knot_s > 0.0 and knot_s < 1.05:
				samples.append(knot_s)
	samples.sort()
	var previous_s := -1.0
	for s in samples:
		if s - previous_s < 0.000001:
			continue
		far.append(_kite_point(s))
		far_w.append(cord_width)
		previous_s = s
	_rope.points = far
	_rope.widths = far_w
	var hand_uv := 0.0
	var repeat_ratio := float(TEX_ROPE.get_height())/30.0
	for i in range(1,hand.size()):
		hand_uv += hand[i].distance_to(hand[i-1])/maxf((hand_w[i]+hand_w[i-1])*0.5*repeat_ratio,8.0)
	_rope.phase = _scroll*2.0
	_rope.queue_redraw()
	_rope_hand.points = hand
	_rope_hand.widths = hand_w
	_rope_hand.phase = _scroll*2.0-hand_uv
	_rope_hand.queue_redraw()


func _build_string() -> void:
	_next_index = 0
	_fill_string()


func _fill_string() -> void:
	# 远处始终接着补，拉多少就来多少，不设只数上限。
	var guard := 0
	while _balloon_s(_next_index) <= 1.2 and guard < 140:
		_spawn_balloon(_next_index)
		_next_index += 1
		guard += 1


func _spawn_balloon(index: int) -> void:
	var species := _roll_species()
	var kind := KIND_EMPTY
	var points := 0
	var icons: Array[Texture2D] = []
	var amount := 0
	if species != SPECIES_DIAMOND:
		kind = _roll_loot(species)
		if kind != KIND_EMPTY:
			amount = _roll_loot_amount(kind)
			points = _points_for(kind, amount)
		icons = _look_icons(kind, amount)
	else:
		icons = [TEX_DIAMOND_BADGE]
	var tex := _species_tex(species)
	if species == SPECIES_RED:
		tex = COMMON_COLORS[int(_hash01(index, 8) * COMMON_COLORS.size()) % COMMON_COLORS.size()]
	# Appearance slots are independent of reward species and use no prize RNG.
	# Keep both approved animal designs visible in every opening garland.
	if posmod(index,10)==2:
		tex = TEX_DIAMOND
	elif posmod(index,10)==6:
		tex = TEX_CAT_BALLOON
	var mul := _species_mul(species)
	var u := _view.y / 720.0
	var root := Node2D.new()
	root.z_index = 2
	root.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var tether := Line2D.new()
	tether.name="Tether"
	tether.width=4.0*u
	tether.default_color=Color("CF8B24")
	tether.antialiased=true
	root.add_child(tether)
	var thread := Line2D.new()
	thread.name="Highlight"
	thread.width=1.6*u
	thread.default_color=Color("FFE69D")
	thread.antialiased=true
	tether.add_child(thread)
	var body := Sprite2D.new()
	body.name = "Body"
	body.texture = tex
	var bscale := BALLOON_H * u / TEX_RED.get_height()
	body.scale = Vector2(bscale, bscale)
	# 节点是绳子上的结。身体沿本地 -Y 鼓出去，结留在原点。
	body.position = Vector2(0.0, -KNOT_FROM_CENTER * BALLOON_H * u)
	root.add_child(body)
	_place_icons(body, icons, u, bscale)
	add_child(root)
	# 新出来的在远处，放到最底层。靠近针的那只一直画在上面，拉绳子时不会被后面的气球盖住换种类。
	move_child(root, 0)
	_balloons.append({
		"index": index,
		"species": species,
		"kind": kind,
		"amount": amount,
		"points": points,
		"node": root,
		"alive": true,
		"mul": mul,
		"tex": tex,
		"knot_offset": _balloon_knot_offset(tex),
	})


func _balloon_knot_offset(tex: Texture2D) -> float:
	# Art attachment is the bow center, not the hanging star below it.
	if tex == TEX_DIAMOND:
		return BALLOON_H * 0.17
	if tex == TEX_CAT_BALLOON:
		return BALLOON_H * 0.15
	return BALLOON_H * KNOT_FROM_CENTER


func _place_icons(body: Sprite2D, icons: Array[Texture2D], u: float, body_scale: float) -> void:
	var n := icons.size()
	if n == 0 or body_scale < 0.001:
		return
	var spots: Array[Vector2] = []
	if n == 1:
		spots = [Vector2(0, -8)]
	elif n == 2:
		spots = [Vector2(-12, -4), Vector2(12, 6)]
	elif n == 3:
		spots = [Vector2(-14, -10), Vector2(12, -2), Vector2(0, 12)]
	elif n == 4:
		spots = [Vector2(-16, -18), Vector2(14, -10), Vector2(-12, 6), Vector2(16, 14)]
	else:
		spots = [Vector2(-14, -16), Vector2(14, -16), Vector2(0, -2), Vector2(-12, 14), Vector2(12, 14)]
	for i in n:
		if icons[i]==TEX_DIAMOND_BADGE:
			var badge := DiamondBadge.new()
			badge.gem=TEX_DIAMOND_BADGE
			badge.name="DiamondBonus"
			badge.scale=Vector2.ONE*u/body_scale
			badge.position=Vector2(24,-12)*u/body_scale
			badge.z_as_relative=true
			badge.z_index=7
			body.add_child(badge)
			continue
		var icon := Sprite2D.new()
		icon.texture = icons[i]
		var target := 18.0 * u if n > 1 else 34.0 * u
		var sc := target / icon.texture.get_height() / body_scale
		icon.scale = Vector2(sc, sc)
		icon.position = spots[i] * u / body_scale
		if icons[i] == TEX_TICKET:
			icon.rotation = deg_to_rad(-8.0 if i % 2 == 0 else 7.0)
		body.add_child(icon)


func _roll_species() -> int:
	# 每颗新气球独立 2% 钻石奖励；其余 98% 保留旧非钻石相对权重。
	var r := _rng.randf()
	if r < DIAMOND_CHANCE:
		return SPECIES_DIAMOND
	r=(r-DIAMOND_CHANCE)/(1.0-DIAMOND_CHANCE)*0.996
	if r < 0.80:
		return SPECIES_RED
	if r < 0.90:
		return SPECIES_STRIPE
	if r < 0.95:
		return SPECIES_STAR
	if r < 0.98:
		return SPECIES_CANDY
	return SPECIES_GOLD


func _roll_loot(species: int) -> int:
	var empty_at := 0.82
	var chip_at := 0.97
	var ticket_at := 1.0
	match species:
		SPECIES_STRIPE:
			empty_at = 0.50
			chip_at = 0.85
			ticket_at = 0.98
		SPECIES_STAR:
			empty_at = 0.25
			chip_at = 0.65
			ticket_at = 0.90
		SPECIES_CANDY:
			empty_at = 0.05
			chip_at = 0.35
			ticket_at = 0.75
		SPECIES_GOLD:
			empty_at = 0.0
			chip_at = 0.15
			ticket_at = 0.55
	var r := _rng.randf()
	if r < empty_at:
		return KIND_EMPTY
	if r < chip_at:
		return KIND_CHIP
	if r < ticket_at:
		return KIND_TICKET
	return KIND_COIN


func _species_tex(species: int) -> Texture2D:
	match species:
		SPECIES_STRIPE:
			return TEX_STRIPE
		SPECIES_STAR:
			return TEX_SPECIES_STAR
		SPECIES_CANDY:
			return TEX_CANDY
		SPECIES_GOLD:
			return TEX_GOLD
		SPECIES_DIAMOND:
			return TEX_BLUE
		_:
			return TEX_RED


func _species_mul(species: int) -> float:
	return 1.12 if species in [SPECIES_GOLD,SPECIES_DIAMOND] else 1.0


func _species_mul_legacy(species: int) -> float:
	# 同一深度上的个头：越稀有越大（叠在 _depth_scale 上）
	match species:
		SPECIES_RED:
			return 0.94
		SPECIES_STRIPE:
			return 1.14
		SPECIES_STAR:
			return 1.36
		SPECIES_CANDY:
			return 1.60
		SPECIES_GOLD:
			return 1.86
		SPECIES_DIAMOND:
			return 2.12
		_:
			return 1.0


func _roll_weighted_range(from_n: int, to_n: int) -> int:
	# w(n) = 13 - n，n 越大权重越低
	var total := 0
	for n in range(from_n, to_n + 1):
		total += 13 - n
	var pick := _rng.randi_range(1, total)
	var acc := 0
	for n in range(from_n, to_n + 1):
		acc += 13 - n
		if pick <= acc:
			return n
	return to_n


func _roll_coin_bundle() -> int:
	# 10,20,…,100；档 k 权重 11-k
	var total := 0
	for tier in range(1, COIN_BUNDLE_TIERS + 1):
		total += 11 - tier
	var pick := _rng.randi_range(1, total)
	var acc := 0
	for tier in range(1, COIN_BUNDLE_TIERS + 1):
		acc += 11 - tier
		if pick <= acc:
			return tier * COIN_BUNDLE_STEP
	return COIN_BUNDLE_TIERS * COIN_BUNDLE_STEP


func _roll_loot_amount(kind: int) -> int:
	match kind:
		KIND_CHIP, KIND_TICKET:
			return _roll_weighted_range(LOOT_COUNT_MIN, LOOT_COUNT_MAX)
		KIND_COIN:
			return _roll_coin_bundle()
		_:
			return 0


func _points_for(kind: int, amount: int) -> int:
	match kind:
		KIND_CHIP:
			return amount * SCORE_PER_CHIP
		KIND_TICKET:
			return amount * SCORE_PER_TICKET
		KIND_COIN:
			return amount * SCORE_PER_COIN
		_:
			return 0


func _look_icons(_kind: int, _amount: int) -> Array[Texture2D]:
	# 盲盒：球面不贴筹码/票/币，只靠外壳种类认稀有度
	return []


func _note_chain() -> int:
	var now := Time.get_ticks_msec()
	if now - _last_pop_msec <= CHAIN_WINDOW_MS:
		_chain = mini(_chain + 1, 3)
	else:
		_chain = 1
	_last_pop_msec = now
	return _chain


func _process(delta: float) -> void:
	if not active:
		return
	if get_viewport_rect().size != _view:
		_layout()
	_step_face(delta)
	if _phase!="play":
		_place_char()
	if _phase == "play":
		_char_anim_t = minf(0.44,_char_anim_t+delta)
		_time_left -= delta
		_step_wind(delta)
		_step_wind_vis(delta)
		_step_yank(delta)
		if _yank_t < 1.0:
			_pose = "yank"
		elif _pull_taps > 0:
			_pose = "reach"
		else:
			_pose = "idle"
		_place_char()
		var slack_to := 0.0 if (_pull_taps > 0 or _yank_t < 1.0) else 18.0
		_slack = lerpf(_slack, slack_to, minf(1.0, delta * 6.0))
		_sway += delta * 1.5
		_step_kite_shape(delta)
		# Balloons and rope must use the exact same wind/curve state this frame.
		_sync_balloons(delta)
		_paint_kite()
		if _progress_display != _progress:
			_progress_display = move_toward(_progress_display, _progress, delta * 42.0)
			_sync_progress_fill()
		if _time_left <= 0.0:
			_begin_settle()
	elif _phase == "settle":
		_settle_left -= delta
		if _settle_left <= 0.0:
			_award()
	_tick_fx(delta)
	_tick_glow(delta)
	_step_cat(delta)
	_step_spectator(delta)
	_step_birds(delta)
	_sky_balloon_decor.step(delta,_view,_phase == "play")
	for decor in [_cat,_spectator]:
		decor.visible = false
	_update_hud()


func _step_yank(delta: float) -> void:
	if _yank_t < 1.0:
		_yank_t = minf(1.0, _yank_t + delta / YANK_DUR)
		var k := _yank_t*_yank_t*_yank_t*(_yank_t*(_yank_t*6.0-15.0)+10.0)
		_scroll = lerpf(_yank_from, _yank_to, k)
		return
	if debug_hold and _pull_taps == 0:
		_pull_taps = 1
	if _pull_taps <= 0:
		_drift_wind(delta)
		return
	_pull_taps -= 1
	_kite_phase += 0.08
	_kite_kick = 0.18
	_yank_from = _scroll
	_yank_to = _scroll + YANK_DEPTH * _wind_yank()
	_yank_t = 0.0
	_scroll = _yank_from


func _reset_wind() -> void:
	_wind_dir = 0
	_wind_phase = "off"
	_wind_left = 0.0
	_wind_wait = WIND_FIRST
	_winds_done = 0
	_wind_prev = 0
	_wind_prev2 = 0
	_wind_vis = 0.0
	_wind_vis_dir = 0
	_show_wind(0, 0.0)
	_stop_wind_sfx()


func _step_wind(delta: float) -> void:
	if _wind_phase == "off":
		if _winds_done >= WIND_COUNT:
			return
		_wind_wait -= delta
		if _wind_wait <= 0.0 and _time_left > 2.0:
			_start_wind()
		return
	_wind_left -= delta
	if _wind_left <= 0.0:
		if _wind_phase == "warn":
			_wind_phase = "blow"
			_wind_left = WIND_BLOW
			_play_wind_sfx()
		else:
			_end_wind()
			return


func _start_wind() -> void:
	var dir := 1 if _rng.randf() < 0.5 else -1
	if _wind_prev != 0 and _wind_prev == _wind_prev2 and dir == _wind_prev:
		dir = -dir
	_wind_prev2 = _wind_prev
	_wind_prev = dir
	_wind_dir = dir
	_wind_phase = "warn"
	_wind_left = WIND_WARN
	_winds_done += 1
	_wind_vis_dir = dir


func _end_wind() -> void:
	_stop_wind_sfx()
	_kite_curl += 0.2
	_kite_kick = 0.2
	_wind_dir = 0
	_wind_phase = "off"
	_wind_left = 0.0
	_wind_wait = WIND_GAP


func _step_wind_vis(delta: float) -> void:
	var target := 0.0
	if _wind_phase == "warn":
		target = 0.4
		_wind_vis_dir = _wind_dir
	elif _wind_phase == "blow":
		target = 1.0
		_wind_vis_dir = _wind_dir
	var tail := _wind_vis_dir < 0 or _wind_dir < 0
	var preview := WIND_SWING_PREVIEW_TAIL if tail else WIND_SWING_PREVIEW_HEAD
	var sweep := WIND_SWING_SWEEP_TAIL if tail else WIND_SWING_SWEEP_HEAD
	var back := WIND_SWING_BACK_TAIL if tail else WIND_SWING_BACK_HEAD
	var speed := 0.4 / preview
	if target > _wind_vis and _wind_vis >= 0.4:
		speed = 0.6 / sweep
	elif target < _wind_vis:
		speed = 1.0 / back
	_wind_vis = move_toward(_wind_vis, target, speed * delta)
	if _wind_vis <= 0.001 and _wind_phase == "off":
		_wind_vis = 0.0
		_wind_vis_dir = 0
	_show_wind(_wind_vis_dir, _wind_vis)


func _wind_yank() -> float:
	# Pull distance is controlled only by the player, not wind direction.
	return 1.0


func _drift_wind(_delta: float) -> void:
	# Wind moves the bundle visually; it does not advance or unwind balloons.
	pass


func _show_wind(dir: int, amount: float) -> void:
	if _gust:
		_gust.dir = dir
		_gust.amount = amount
		_gust.queue_redraw()


func _hash01(index: int, salt: int) -> float:
	var n := (index * 196613 + salt * 83492791 + 1234567)
	n = n ^ (n << 13)
	n = n ^ (n >> 17)
	n = n ^ (n << 5)
	return float(posmod(n, 10000)) / 10000.0


func _garland_pose(index: int, s: float, node_scale: float) -> Dictionary:
	# 六向错层围绕主绳成团，不能只绕结轻转、仍排成一根细链。
	var ahead := _kite_point(minf(s+.012,1.3))
	var back := _kite_point(maxf(s-.012,0.0))
	var tangent: Vector2=(ahead-back).normalized()
	var group := float(index/6)
	var sector := float(posmod(index,6))*TAU/6.0
	var jitter := lerpf(-.19,.19,_hash01(index,6))
	var roll := 0.0
	var angle := tangent.angle()+sector+jitter+sin(group*1.7)*.22+roll
	var neck := BALLOON_H*lerpf(.22,.46,_hash01(index,4))
	neck*=lerpf(.30,1.0,smoothstep(.0,.18,s))
	return {"shift":Vector2.ZERO,"rotation":angle+PI*.5,"neck":neck,"wobble":1.0}


func _garland_pose_legacy(index: int, s: float, node_scale: float) -> Dictionary:
	# 结钉在绳子上，身体从结往外鼓。角度打乱，避免左右对称的梳子。
	var u := _view.y / 720.0
	var ahead := _kite_point(minf(s + 0.02, 1.3), false)
	var back := _kite_point(maxf(s - 0.02, 0.0), false)
	var tangent := ahead - back
	if tangent.length() < 1.0:
		tangent = Vector2.RIGHT
	else:
		tangent = tangent.normalized()
	var normal := Vector2(-tangent.y, tangent.x)
	var reach := BALLOON_H * u * node_scale
	var side := 1.0 if _hash01(int(index / 2), 7) > 0.4 else -1.0
	if _hash01(index, 1) > 0.72:
		side = -side
	var along := lerpf(-0.4, 0.4, _hash01(index, 4))
	var shift := tangent * (along * reach * 0.12)
	var spin := lerpf(-1.05, 1.05, _hash01(index, 6))
	var outward: Vector2 = (normal * side).rotated(spin)
	return {
		"shift": shift,
		"rotation": outward.angle() + PI * 0.5,
		"wobble": lerpf(0.9, 1.12, _hash01(index, 9)),
	}


func _sync_balloons(delta: float) -> void:
	_fill_string()
	var i := 0
	while i < _balloons.size():
		if not _balloons[i].alive:
			_balloons.remove_at(i)
			continue
		i += 1
	var u := _view.y / 720.0
	var poke_index := -1
	var poke_dist := 100000.0
	for balloon in _balloons:
		if not balloon.alive:
			continue
		var s := _balloon_s(int(balloon.index))
		if s > 1.08 or s <= 0.0:
			continue
		var sc := _depth_scale(s) * float(balloon.mul)
		var pose: Dictionary = _garland_pose(int(balloon.index), s, sc)
		var knot: Vector2 = _kite_point(s, false, false)
		var wobble := float(pose.wobble)
		var offset := (float(balloon.knot_offset)+float(pose.neck))*u*sc*wobble
		var radius := 0.46 * BALLOON_H * u * sc * wobble
		var dist := knot.distance_to(_needle_tip)
		if s < 0.04 and dist <= offset + radius * 0.25 and dist < poke_dist:
			poke_dist = dist
			poke_index = int(balloon.index)
	for balloon in _balloons:
		if not balloon.alive:
			continue
		var s := _balloon_s(int(balloon.index))
		var node: Node2D = balloon.node
		if s > 1.08:
			node.visible = false
			continue
		if s <= 0.0:
			_pop(balloon, _needle_tip)
			continue
		node.visible = true
		var sc := _depth_scale(s) * float(balloon.mul)
		var pose: Dictionary = _garland_pose(int(balloon.index), s, sc)
		var knot: Vector2 = _kite_point(s) + (pose.shift as Vector2)
		var rot := float(pose.rotation)
		var wobble := float(pose.wobble)
		var offset := (float(balloon.knot_offset)+float(pose.neck))*u*sc*wobble
		if int(balloon.index) == poke_index:
			var back := knot - _needle_tip
			if back.length() < 1.0:
				back = Vector2(-1.0, 0.35)
			back = back.normalized()
			rot = (-back).angle() + PI * 0.5
			node.position = _needle_tip + back * offset
			balloon["poke"] = float(balloon.get("poke", 0.0)) + delta
			if float(balloon.poke) >= 0.05:
				_pop(balloon, _needle_tip)
				continue
		else:
			balloon["poke"] = 0.0
			node.position = knot
			node.rotation = rot
		node.rotation = rot
		node.scale = Vector2(sc * wobble, sc * wobble)
		node.z_index = 3
		var body := node.get_node_or_null("Body")
		if body:
			var neck := float(pose.neck)*u
			body.position=Vector2(0,-float(balloon.knot_offset)*u-neck)
			var tether: Line2D=node.get_node("Tether")
			# Even while a balloon touches the needle, its branch stays on the main cord.
			tether.points=PackedVector2Array([node.to_local(knot),Vector2(0,-neck-3.0*u)])
			tether.get_node("Highlight").points=tether.points
			for child in body.get_children():
				child.visible = sc > (0.32 if child.name=="DiamondBonus" else 0.48)
				if child.name=="DiamondBonus":
					child.rotation=-node.rotation


func _build_pop_voices() -> void:
	for i in POP_VOICES:
		var player := AudioStreamPlayer.new()
		player.name = "PopSfx%d" % i
		player.stream = POP_SFX[0]
		player.volume_db = POP_VOL_DB
		player.bus = "Master"
		add_child(player)
		_pop_voices.append(player)
	_coin_drop_player = AudioStreamPlayer.new()
	_coin_drop_player.name = "CoinDropSfx"
	_coin_drop_player.stream = COIN_DROP_SFX
	_coin_drop_player.volume_db = PRIZE_DROP_VOL_DB
	_coin_drop_player.bus = "Master"
	add_child(_coin_drop_player)
	_chip_drop_player = AudioStreamPlayer.new()
	_chip_drop_player.name = "ChipDropSfx"
	_chip_drop_player.stream = CHIP_DROP_SFX
	_chip_drop_player.volume_db = PRIZE_DROP_VOL_DB
	_chip_drop_player.bus = "Master"
	add_child(_chip_drop_player)
	_ticket_drop_player = AudioStreamPlayer.new()
	_ticket_drop_player.name = "TicketDropSfx"
	_ticket_drop_player.stream = TICKET_DROP_SFX
	_ticket_drop_player.volume_db = PRIZE_DROP_VOL_DB
	_ticket_drop_player.bus = "Master"
	add_child(_ticket_drop_player)
	_wind_player = AudioStreamPlayer.new()
	_wind_player.name = "WindBlowSfx"
	_wind_player.stream = WIND_BLOW_SFX[0]
	_wind_player.volume_db = WIND_VOL_DB
	_wind_player.bus = "Master"
	add_child(_wind_player)
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "Bgm"
	_bgm_player.stream = _looping_bgm()
	_bgm_player.volume_db = BGM_VOL_DB
	_bgm_player.bus = "Master"
	add_child(_bgm_player)


func _play_pop_sfx() -> void:
	if _pop_voices.is_empty():
		return
	var player := _pop_voices[_pop_voice_i % _pop_voices.size()]
	_pop_voice_i += 1
	player.stream = POP_SFX[_rng.randi() % POP_SFX.size()]
	player.pitch_scale = _rng.randf_range(0.97, 1.03)
	player.play()


func _play_coin_drop_sfx(coin_amount: int = 0) -> void:
	if _coin_drop_player == null:
		return
	if coin_amount >= COIN_DROP_MID_MIN and coin_amount <= COIN_DROP_MID_MAX:
		_coin_drop_player.stream = COIN_DROP_SFX_MID
	elif coin_amount > COIN_DROP_MID_MAX:
		_coin_drop_player.stream = COIN_DROP_SFX_BIG
	else:
		_coin_drop_player.stream = COIN_DROP_SFX
	_coin_drop_player.stop()
	_coin_drop_player.play()


func _play_chip_drop_sfx(chip_amount: int) -> void:
	if _chip_drop_player == null:
		return
	_chip_drop_player.stream = (
		CHIP_DROP_SFX_BIG if chip_amount >= CHIP_DROP_BIG_MIN else CHIP_DROP_SFX
	)
	_chip_drop_player.stop()
	_chip_drop_player.play()


func _play_ticket_drop_sfx() -> void:
	if _ticket_drop_player == null:
		return
	_ticket_drop_player.stop()
	_ticket_drop_player.play()


func _play_wind_sfx() -> void:
	if _wind_player == null or WIND_BLOW_SFX.is_empty():
		return
	_wind_player.stream = WIND_BLOW_SFX[_rng.randi() % WIND_BLOW_SFX.size()]
	_wind_player.stop()
	_wind_player.play()


func _stop_wind_sfx() -> void:
	if _wind_player == null:
		return
	_wind_player.stop()


func _looping_bgm() -> AudioStream:
	var stream := BGM.duplicate() as AudioStreamOggVorbis
	if stream:
		stream.loop = true
		return stream
	return BGM


func _play_bgm() -> void:
	if _bgm_player == null:
		return
	_bgm_player.stop()
	_bgm_player.play()


func _stop_bgm() -> void:
	if _bgm_player == null:
		return
	_bgm_player.stop()


func _pop(balloon: Dictionary, at: Vector2) -> void:
	if not bool(balloon.get("alive",false)):
		return
	_face_happy_left = 0.45
	_carnival_pops += 1
	balloon.alive = false
	var node: Node2D = balloon.node
	node.visible = false
	node.queue_free()
	_play_pop_sfx()
	_add_balloon_progress()
	var species := int(balloon.species)
	if species >= 0 and species < _pop_counts.size():
		_pop_counts[species] += 1
	var layers := _note_chain()
	var extra := (layers - 1) * 6
	var boost := 1.2 if species == SPECIES_CANDY or species == SPECIES_GOLD else 1.0
	var shards := _shards_for(balloon)
	if species == SPECIES_DIAMOND:
		_claw_bonuses+=1
		GameState.add_free_play(1, "钻石气球")
		BoardLink.report_free_play(1)
		_spray(at, 10 + extra, 150.0 * boost, shards)
		_hit_flash(at, 760.0 * boost, Color(0.7, 0.93, 1.0))
		_flash_glow(Color(0.55, 0.88, 1.0, 0.38), 0.55)
		_float_claw(at)
		_play_coin_drop_sfx()
		return
	var kind := int(balloon.kind)
	var points := int(balloon.points)
	var amount := int(balloon["amount"]) if balloon.has("amount") else 0
	_score += points
	match kind:
		KIND_CHIP:
			_spray(at, 8 + extra, 150.0 * boost, shards)
			_fly_prizes(at, kind, maxi(amount, 1), 168.0)
			_float_points(at, points, false)
			_play_chip_drop_sfx(maxi(amount, 1))
		KIND_TICKET:
			_spray(at, 10 + extra, 170.0 * boost, shards)
			_fly_prizes(at, kind, maxi(amount, 1), 180.0)
			_float_points(at, points, false)
			_flash_glow(Color(1.0, 0.92, 0.55, 0.16), 0.28)
			_play_ticket_drop_sfx()
		KIND_COIN:
			_spray(at, 8 + extra, 140.0 * boost, shards)
			_coin_rain_to_score(maxi(amount, 1))
			_float_points(at, points, true)
			_flash_glow(Color(1.0, 0.78, 0.2, 0.28), 0.45)
			_play_coin_drop_sfx(amount)
		_:
			_spray(at, 12 + extra, 130.0 * boost, shards)


func _shards_for(balloon: Dictionary) -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	if balloon.tex==TEX_RED or balloon.tex==TEX_CANDY or balloon.tex==TEX_STRIPE:
		result.append(TEX_LATEX)
		return result
	var species: int = int(balloon.species)
	var key: String = ["red","stripe","gold","heart","gold","bunny"][clampi(species,0,5)]
	if balloon.tex==TEX_CAT_BALLOON:
		key = "cat"
	elif balloon.tex==TEX_DIAMOND:
		key = "bunny"
	for i in 4:
		result.append(load("res://街机小游戏/assets/balloon/carnival/shard_%s_%d.png" % [key,i]) as Texture2D)
	return result


func _shards_for_legacy(balloon: Dictionary) -> Array[Texture2D]:
	match int(balloon.species):
		SPECIES_STRIPE:
			return SHARDS_STRIPE
		SPECIES_STAR:
			return SHARDS_STAR
		SPECIES_CANDY:
			return SHARDS_CANDY
		SPECIES_GOLD:
			return SHARDS_GOLD
		SPECIES_DIAMOND:
			return SHARDS_DIAMOND
	var tex: Texture2D = balloon.tex
	if tex == TEX_YELLOW:
		return SHARDS_YELLOW
	if tex == TEX_BLUE:
		return SHARDS_BLUE
	if tex == TEX_GREEN:
		return SHARDS_GREEN
	return TEX_SHARDS


func _spray(at: Vector2, count: int, reach: float, shards: Array[Texture2D]) -> void:
	var u := _view.y / 720.0
	var pile := shards if shards.size() > 0 else TEX_SHARDS
	for i in count:
		var star_piece := _rng.randf() < 0.45
		var sprite := Sprite2D.new()
		sprite.texture = TEX_STAR if star_piece else pile[_rng.randi() % pile.size()]
		sprite.z_index = 6
		var piece_h := (28.0 if star_piece else 46.0) * u
		var sc := piece_h / sprite.texture.get_height()
		sprite.scale = Vector2(sc, sc)
		sprite.position = at
		sprite.rotation = _rng.randf_range(-0.5, 0.5)
		add_child(sprite)
		var ang := TAU * float(i) / float(maxi(count, 1)) + _rng.randf_range(-0.35, 0.35)
		_add_fx({
			"node": sprite,
			"t": 0.0,
			"dur": _rng.randf_range(0.45, 0.7),
			"from": at,
			"to": at + Vector2(cos(ang), sin(ang)) * _rng.randf_range(reach * 0.55, reach) * u,
			"spin": _rng.randf_range(-5.0, 5.0),
			"kind": "star" if star_piece else "shard",
			"scale": sprite.scale,
		})


func _coin_rain_to_score(count: int) -> void:
	var u := _view.y / 720.0
	var goal := Vector2(_view.x - 120.0, 48.0)
	var piece_h := 34.0
	var stagger := 0.018
	if count > 1:
		stagger = minf(0.028, 2.4 / float(count))
	for i in count:
		var sprite := Sprite2D.new()
		sprite.texture = TEX_COIN
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.z_index = 10
		sprite.modulate = Color.WHITE
		var sc := piece_h * u / TEX_COIN.get_height()
		sprite.scale = Vector2(sc, sc)
		var x := _rng.randf_range(48.0, _view.x - 48.0)
		var from := Vector2(x, _rng.randf_range(-180.0, -28.0) * u)
		var drop_at := Vector2(
			x + _rng.randf_range(-40.0, 40.0),
			_rng.randf_range(0.30, 0.68) * _view.y
		)
		sprite.position = from
		add_child(sprite)
		_add_fx({
			"node": sprite,
			"t": -float(i) * stagger,
			"dur": _rng.randf_range(1.05, 1.45),
			"from": from,
			"drop": drop_at,
			"to": goal + Vector2(_rng.randf_range(-18, 10), _rng.randf_range(-8, 12)),
			"spin": _rng.randf_range(-2.5, 2.5),
			"kind": "coin_drop",
			"scale": sprite.scale,
		})


func _rain(tex: Texture2D, count: int, tint: Color, piece_h: float) -> void:
	var u := _view.y / 720.0
	for i in count:
		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.z_index = 9
		sprite.modulate = tint
		var sc := piece_h * u / tex.get_height()
		sprite.scale = Vector2(sc, sc)
		var x := _rng.randf_range(36.0, _view.x - 36.0)
		var from := Vector2(x, _rng.randf_range(-120.0, -16.0) * u)
		var to := Vector2(x + _rng.randf_range(-36.0, 36.0), _view.y + 48.0)
		sprite.position = from
		add_child(sprite)
		_add_fx({
			"node": sprite,
			"t": -_rng.randf_range(0.0, 0.18),
			"dur": _rng.randf_range(0.95, 1.35),
			"from": from,
			"to": to,
			"spin": _rng.randf_range(-2.0, 2.0),
			"kind": "rain",
			"scale": sprite.scale,
		})


func _flash_glow(color: Color, dur: float) -> void:
	if _glow == null:
		return
	_glow.color = color
	_glow_peak = color.a
	_glow_dur = maxf(dur, 0.05)
	_glow_left = _glow_dur


func _tick_glow(delta: float) -> void:
	if _glow == null or _glow_left <= 0.0:
		return
	_glow_left = maxf(0.0, _glow_left - delta)
	var a := 0.0 if _glow_dur <= 0.0 else _glow_peak * (_glow_left / _glow_dur)
	var tint := _glow.color
	tint.a = a
	_glow.color = tint


func _hit_flash(at: Vector2, burst_h: float, tint: Color) -> void:
	var u := _view.y / 720.0
	for n in 2:
		var burst := Sprite2D.new()
		burst.texture = TEX_BURST
		burst.z_index = 8
		burst.modulate = Color(1,1,1,minf(tint.a,0.85))
		var bsc := clampf(burst_h*0.22,80,150) * u / TEX_BURST.get_height() * (1.0 if n == 0 else 0.62)
		burst.scale = Vector2(bsc, bsc)
		burst.position = at
		burst.rotation = 0.0 if n == 0 else 0.4
		add_child(burst)
		_add_fx({
			"node": burst,
			"t": -0.06 * float(n),
			"dur": 0.55,
			"from": at,
			"to": at,
			"spin": 0.0,
			"kind": "flash",
			"scale": burst.scale,
		})


func _fly_prizes(at: Vector2, kind: int, count: int, reach: float) -> void:
	var tex := TEX_CHIP if kind == KIND_CHIP else TEX_TICKET
	var u := _view.y / 720.0
	var goal := Vector2(_view.x - 120.0, 48.0)
	var hold := 1.15
	for i in count:
		var icon := Sprite2D.new()
		icon.texture = tex
		icon.z_index = 8
		var target_h := 46.0 * u
		var sc := target_h / tex.get_height()
		icon.scale = Vector2(sc, sc)
		var ang := TAU * float(i) / float(maxi(count, 1)) + _rng.randf_range(-0.25, 0.25)
		var mid := at + Vector2(cos(ang), sin(ang)) * _rng.randf_range(reach * 0.65, reach) * u
		icon.position = at
		add_child(icon)
		_add_fx({
			"node": icon,
			"t": -float(i) * 0.02,
			"dur": hold + 0.5,
			"from": at,
			"mid": mid,
			"to": goal + Vector2(_rng.randf_range(-24, 12), _rng.randf_range(-8, 16)),
			"hold": hold,
			"spin": _rng.randf_range(-1.2, 1.2),
			"kind": "prize",
			"scale": icon.scale,
		})


func _float_claw(at: Vector2) -> void:
	var u := _view.y / 720.0
	var badge := Sprite2D.new()
	badge.texture = TEX_CLAW_BONUS
	var sc := 210.0*u/TEX_CLAW_BONUS.get_width()
	badge.scale = Vector2.ONE*sc
	var half := TEX_CLAW_BONUS.get_size()*sc*0.5
	var pos := at+Vector2(0,-95*u)
	pos.x = clampf(pos.x,half.x+12,_view.x-half.x-12)
	pos.y = clampf(pos.y,half.y+110*u,_view.y-half.y-12)
	badge.position = pos
	badge.z_index = 10
	badge.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(badge)
	_add_fx({
		"node": badge,
		"t": 0.0,
		"dur": 1.35,
		"from": pos,
		"to": pos + Vector2(0, -28.0 * u),
		"spin": 0.0,
		"kind": "bonus",
		"scale": badge.scale,
	})


func _float_points(at: Vector2, points: int, coin: bool = false) -> void:
	var u := _view.y / 720.0
	var label := CarnivalPoints.new()
	label.value = "+%d" % points
	label.font = _carnival_hud._font
	label.px = 52 if coin else 38
	var pos := Vector2(_view.x-150*u,145*u) if coin else at+Vector2(0,-65*u)
	var half_w: float = label.font.get_string_size(label.value,HORIZONTAL_ALIGNMENT_LEFT,-1,label.px).x*u*0.5+14*u
	pos.x = clampf(pos.x,half_w,_view.x-half_w)
	pos.y = clampf(pos.y,130*u,_view.y-60*u)
	label.position = pos
	label.scale = Vector2.ONE*u
	label.z_index = 10
	add_child(label)
	_add_fx({
		"node": label,
		"t": 0.0,
		"dur": 1.05 if coin else 0.7,
		"from": pos,
		"to": pos + Vector2(0, -48.0 * u),
		"spin": 0.0,
		"kind": "score",
		"scale": label.scale,
	})


func _tick_fx(delta: float) -> void:
	var keep: Array = []
	for item in _fx:
		item.t = float(item.t) + delta
		var t := float(item.t)
		var node: Node = item.node
		if node == null or not is_instance_valid(node):
			continue
		if t >= float(item.dur):
			node.queue_free()
			continue
		if t < 0.0:
			node.visible = false
			keep.append(item)
			continue
		node.visible = true
		var k := t / float(item.dur)
		var eased := 1.0 - pow(1.0 - k, 2.0)
		if node is Node2D and str(item.kind) != "text":
			var sprite := node as Node2D
			var kind := str(item.kind)
			var base := (item.scale if item.has("scale") else sprite.scale) as Vector2
			if kind == "score" or kind == "bonus":
				sprite.position = (item.from as Vector2).lerp(item.to as Vector2,eased)
				var punch := 1.0+sin(clampf(k/0.24,0,1)*PI)*0.16
				sprite.scale = base*punch
				sprite.modulate.a = 1.0 if k<0.65 else (1.0-k)/0.35
			elif kind == "flash":
				sprite.position = item.from
				var punch := 1.0
				if k < 0.28:
					punch = lerpf(0.15, 1.35, k / 0.28)
				else:
					punch = lerpf(1.35, 0.92, (k - 0.28) / 0.72)
				sprite.scale = base * punch
				sprite.modulate.a = 1.0 if k < 0.45 else 1.0 - (k - 0.45) / 0.55
			elif kind == "prize":
				var hold_for := float(item.hold)
				var rest := item.mid as Vector2
				if t < 0.22:
					var pop := clampf(t / 0.22, 0.0, 1.0)
					sprite.position = (item.from as Vector2).lerp(rest, 1.0 - pow(1.0 - pop, 2.0))
				elif t < hold_for:
					sprite.position = rest + Vector2(sin(t * 5.0) * 4.0, cos(t * 4.0) * 3.0)
				else:
					var fly := clampf((t - hold_for) / (float(item.dur) - hold_for), 0.0, 1.0)
					sprite.position = rest.lerp(item.to as Vector2, fly * fly)
					if fly > 0.82:
						sprite.modulate.a = 1.0 - (fly - 0.82) / 0.18
				sprite.rotation += float(item.spin) * delta
			elif kind == "rain":
				sprite.position = (item.from as Vector2).lerp(item.to as Vector2, eased)
				sprite.rotation += float(item.spin) * delta
				sprite.modulate.a = 1.0 if k < 0.72 else 1.0 - (k - 0.72) / 0.28
			elif kind == "coin_drop":
				var drop_pt := item.drop as Vector2
				var split := 0.5
				if k < split:
					var fk := k / split
					var fall := 1.0 - pow(1.0 - fk, 2.2)
					sprite.position = (item.from as Vector2).lerp(drop_pt, fall)
				else:
					var fk := (k - split) / (1.0 - split)
					var fly := fk * fk
					sprite.position = drop_pt.lerp(item.to as Vector2, fly)
					if fk > 0.78:
						sprite.modulate.a = 1.0 - (fk - 0.78) / 0.22
				sprite.rotation += float(item.spin) * delta
			else:
				sprite.position = (item.from as Vector2).lerp(item.to as Vector2, eased)
				sprite.rotation += float(item.spin) * delta
				if kind == "shard" or kind == "star":
					sprite.modulate.a = 1.0 - k
		elif node is Label:
			var label := node as Label
			label.position = (item.from as Vector2).lerp(item.to as Vector2, eased)
			if str(item.kind) == "hold":
				label.modulate.a = 1.0 if k < 0.72 else 1.0 - (k - 0.72) / 0.28
			else:
				label.modulate.a = 1.0 - k
		# Reward particles belong in the play area, never over the top HUD.
		if node is Sprite2D and str(item.kind) in ["star","shard","prize","rain","coin_drop"]:
			var particle := node as Sprite2D
			var half_h := particle.texture.get_height() * absf(particle.scale.y) * .5 if particle.texture else 0.0
			particle.visible = particle.position.y - half_h >= 130.0 * (_view.y / 720.0)
		keep.append(item)
	_fx = keep


func _add_fx(item: Dictionary) -> void:
	if item.node is Sprite2D and str(item.kind) in ["star","shard","prize","rain","coin_drop"]:
		var particle := item.node as Sprite2D
		var half_h := particle.texture.get_height() * absf(particle.scale.y) * .5 if particle.texture else 0.0
		particle.visible = particle.position.y - half_h >= 130.0 * (_view.y / 720.0)
	_fx.append(item)
	while _fx.size() > FX_CAP:
		var drop := -1
		var oldest := -999.0
		for i in _fx.size():
			var piece := str(_fx[i].kind)
			if piece != "shard" and piece != "star":
				continue
			var age := float(_fx[i].t)
			if age > oldest:
				oldest = age
				drop = i
		if drop < 0:
			break
		var gone: Node = _fx[drop].node
		if gone and is_instance_valid(gone):
			gone.queue_free()
		_fx.remove_at(drop)


func _begin_settle() -> void:
	_char_anim_t = 0.44
	_phase = "settle"
	_settle_left = SETTLE_SEC
	_time_left = 0.0
	_pose = "idle"
	_pull_taps = 0
	_place_char()
	_end_wind()
	_wind_vis = 0.0
	_wind_vis_dir = 0
	_show_wind(0, 0.0)
	_paint_kite()
	_sync_balloons(0.0)
	_settle_label.visible = true
	_hint_label.visible = false


func _award() -> void:
	if _awarded:
		return
	_awarded = true
	_phase = "done"
	var tokens := maxi(0, _score)
	BoardLink.release_control()
	if tokens > 0:
		GameState.add_tokens(tokens)
		BoardLink.report_settle(tokens)
	GameState.finish_points_round(self, "balloon", _points_round_id, _score)
	round_finished.emit(tokens)


func _update_hud() -> void:
	if _carnival_hud:
		for old in [_time_label,_score_label,_hint_label,_settle_label,_progress_root]:
			old.visible = false
		_carnival_hud.sync_state(self)
		return


func _update_hud_legacy() -> void:
	var sec := maxi(0, ceili(_time_left))
	_time_label.text = "剩余 %d 秒" % sec
	_score_label.text = "积分 %d" % _score
	if _phase == "play":
		_hint_label.visible = true
		_hint_label.text = "拍一下空格，拉一顿绳子"
		_settle_label.visible = false
	elif _phase == "settle" or _phase == "done":
		_hint_label.visible = false
		_settle_label.visible = true
		_settle_label.text = "本局积分 %d" % _score


func _clear_spawned() -> void:
	for balloon in _balloons:
		var node: Node = balloon.node
		if node and is_instance_valid(node):
			node.queue_free()
	_balloons.clear()
	for item in _fx:
		var node: Node = item.node
		if node and is_instance_valid(node):
			node.queue_free()
	_fx.clear()
	_glow_left = 0.0
	if _glow:
		_glow.color = Color(1, 1, 1, 0)


class DiamondBadge extends Node2D:
	var gem: Texture2D
	func _draw() -> void:
		draw_circle(Vector2.ZERO,29,Color("FFF3AA"))
		draw_circle(Vector2.ZERO,26,Color("EFAE28"))
		draw_circle(Vector2.ZERO,23,Color("143C79"))
		if gem:
			draw_texture_rect(gem,Rect2(-23,-19,46,38),false)

class CarnivalPoints extends Node2D:
	var value := "+0"
	var px := 38
	var font: Font
	func _draw() -> void:
		if font==null:
			return
		var size := font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,px)
		var at := Vector2(-size.x*0.5,(font.get_ascent(px)-font.get_descent(px))*0.5)
		draw_string_outline(font,at+Vector2(0,3),value,HORIZONTAL_ALIGNMENT_LEFT,-1,px,8,Color("8E251C"))
		draw_string_outline(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,px,4,Color("FFF5CE"))
		draw_string_outline(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,px,1,Color("CF7621"))
		draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,px,Color("FFDC47"))

class WindGust extends Node2D:
	var dir := 0
	var amount := 0.0
	var shift := 0.0
	var head_tex: Texture2D
	var tail_tex: Texture2D

	func _process(delta: float) -> void:
		if dir == 0 or amount <= 0.01:
			return
		shift += delta * 90.0
		queue_redraw()

	func _draw() -> void:
		if dir == 0 or amount <= 0.01:
			return
		var view := get_viewport_rect().size
		var width := view.x*0.29
		var height := width*head_tex.get_height()/head_tex.get_width()
		for i in 3:
			var x := fposmod(shift*float(dir)+float(i)*view.x*0.45,view.x+width)-width
			var y := view.y*(0.27+float(i)*0.16)+sin(shift*0.012+float(i))*view.y*0.012
			draw_set_transform(Vector2(x+(width if dir<0 else 0),y),0,Vector2(-1 if dir<0 else 1,1))
			draw_texture_rect(head_tex,Rect2(0,0,width,height),false,Color(1,1,1,clampf(amount,0,1)*0.55))
		draw_set_transform(Vector2.ZERO)

	func _draw_legacy() -> void:
		if dir == 0 or amount <= 0.01:
			return
		var tex: Texture2D = head_tex if dir > 0 else tail_tex
		if tex == null:
			return
		var view := get_viewport_rect().size
		var gust_w := view.x * 0.42
		var gust_h := gust_w * float(tex.get_height()) / float(tex.get_width())
		var span := view.x + gust_w
		var tint := Color(1, 1, 1, clampf(amount, 0.0, 1.0))
		for i in 2:
			var x := fposmod(shift * float(dir) + float(i) * span * 0.55, span) - gust_w * 0.15
			var y := view.y * (0.22 + float(i) * 0.16)
			draw_texture_rect(tex, Rect2(x, y, gust_w, gust_h), false, tint)


class CarnivalBouquet extends Node2D:
	func _draw() -> void:
		draw_set_transform(Vector2.ZERO,0,get_viewport_rect().size/Vector2(1280,720))
		var textures := [TEX_RED,TEX_YELLOW,TEX_BLUE,TEX_STRIPE]
		var centers := [Vector2(165,185),Vector2(218,242),Vector2(85,246),Vector2(247,297)]
		for i in 4:
			draw_line(centers[i]+Vector2(0,36),Vector2(182,395),Color("F8CE73"),2,true)
		for i in 4:
			var size := Vector2(117,146) if i!=2 else Vector2(155,194)
			draw_texture_rect(textures[i],Rect2(centers[i]-size*0.5,size),false)


class RopeDrawer extends Node2D:
	var _mesh := ArrayMesh.new()
	var tex: Texture2D
	var points := PackedVector2Array()
	var widths := PackedFloat32Array()
	var phase := 0.0
	## 共享法线的连续绳带，沿曲线铺设可重复的金色绳纹。

	func _draw() -> void:
		if tex == null or points.size() < 2:
			return
		var vertices := PackedVector3Array()
		var uvs := PackedVector2Array()
		var indices := PackedInt32Array()
		var v := phase
		var repeat_ratio := float(tex.get_height())/30.0
		for i in points.size():
			var tangent := (points[mini(i+1,points.size()-1)]-points[maxi(i-1,0)]).normalized()
			var normal := Vector2(-tangent.y,tangent.x)
			var width := widths[i] if i<widths.size() else 7.0
			if i>0:
				var previous_width := widths[i-1] if i-1<widths.size() else width
				# Integrate the local repeat length; dividing total distance by changing
				# width made distant twists race and shimmer as the curve moved.
				v += points[i].distance_to(points[i-1])/maxf((width+previous_width)*0.5*repeat_ratio,8.0)
			var left := points[i]-normal*width*0.5
			var right := points[i]+normal*width*0.5
			vertices.append(Vector3(left.x,left.y,0))
			vertices.append(Vector3(right.x,right.y,0))
			uvs.append(Vector2(0,v))
			uvs.append(Vector2(1,v))
			if i>0:
				var a := (i-1)*2
				indices.append_array(PackedInt32Array([a,a+1,a+2,a+1,a+3,a+2]))
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX]=vertices
		arrays[Mesh.ARRAY_TEX_UV]=uvs
		arrays[Mesh.ARRAY_INDEX]=indices
		_mesh.clear_surfaces()
		_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		draw_mesh(_mesh,tex)

	func _point_at(dist: float, acc: PackedFloat32Array) -> Vector2:
		if dist <= 0.0:
			return points[0]
		for i in range(1, points.size()):
			if acc[i] >= dist:
				var seg := acc[i] - acc[i - 1]
				var k := 0.0 if seg <= 0.001 else (dist - acc[i - 1]) / seg
				return points[i - 1].lerp(points[i], k)
		return points[points.size() - 1]
		return points[points.size() - 1]

	func _width_at(dist: float, acc: PackedFloat32Array) -> float:
		if widths.is_empty():
			return 10.0
		if dist <= 0.0:
			return widths[0]
		for i in range(1, points.size()):
			if acc[i] >= dist:
				var seg := acc[i] - acc[i - 1]
				var k := 0.0 if seg <= 0.001 else (dist - acc[i - 1]) / seg
				var w0 := widths[i - 1] if i - 1 < widths.size() else widths[widths.size() - 1]
				var w1 := widths[i] if i < widths.size() else w0
				return lerpf(w0, w1, k)
		return widths[widths.size() - 1]
