extends Node
## 街机音效 / BGM：待机、滚轮、各小游戏对局曲（可自适应 pitch）

enum BgmMode { OFF, ATTRACT, ROULETTE, PLAY, PLANE, LASSO, FISH, MATCH3, PINBALL, SHAFT, DICE, FEAST_EAT, FEAST_RACE }

const PATH_BGM_ATTRACT := "res://街机小游戏/audio/bgm_attract.wav"
const PATH_BGM_ROULETTE := "res://街机小游戏/audio/bgm_roulette.wav"
const PATH_BGM_PLAY := "res://街机小游戏/audio/bgm_play.wav"
const PATH_BGM_PLANE := "res://街机小游戏/audio/bgm_plane.wav"
const PATH_BGM_PLANE_STOMP := "res://街机小游戏/audio/bgm_plane_stomp.wav"
const PATH_BGM_PLANE_FRESH := "res://街机小游戏/audio/bgm_plane_fresh.wav"
## 霓虹空战默认对局曲（Suno 街机射击，约 152 BPM）；三首摇滚 wav 仍保留可切回
const PATH_BGM_PLANE_BLUE_LOTUS := "res://街机小游戏/audio/bgm_plane_blue_lotus.ogg"
const PLANE_BGM_USE_BLUE_LOTUS := true
const PATH_BGM_LASSO := "res://街机小游戏/audio/bgm_lasso.wav"
const PATH_BGM_FISH := "res://街机小游戏/audio/bgm_fish.wav"
const PATH_BGM_MATCH3 := "res://街机小游戏/audio/bgm_match3.wav"
const PATH_BGM_PINBALL := "res://街机小游戏/audio/bgm_pinball.wav"
const PATH_BGM_SHAFT := "res://街机小游戏/audio/bgm_shaft.wav"
const PATH_SHAFT_LAND := "res://街机小游戏/audio/shaft/sfx_land.wav"
const PATH_SHAFT_BREAK := "res://街机小游戏/audio/shaft/sfx_break.wav"
const PATH_SHAFT_CEILING_WARN := "res://街机小游戏/audio/shaft/sfx_ceiling_warn.wav"
const PATH_SHAFT_CRUSH := "res://街机小游戏/audio/shaft/sfx_crush.wav"
const PATH_SHAFT_FALL := "res://街机小游戏/audio/shaft/sfx_fall.wav"
const PATH_SHAFT_SPIKE := "res://街机小游戏/audio/shaft/sfx_spike.wav"
const PATH_SHAFT_SPRING := "res://街机小游戏/audio/shaft/sfx_spring.wav"
const PATH_SHAFT_MILESTONE := "res://街机小游戏/audio/shaft/sfx_milestone.wav"
const PATH_SHAFT_CLEAR100 := "res://街机小游戏/audio/shaft/sfx_clear100.wav"
const PATH_BGM_DICE := "res://街机小游戏/audio/bgm_dice.wav"
const PATH_BGM_DICE_HEAT := "res://街机小游戏/audio/bgm_dice_heat.wav"
const PATH_BGM_FEAST_EAT := "res://街机小游戏/audio/bgm_feast_eat.wav"
const PATH_BGM_FEAST_RACE := "res://街机小游戏/audio/bgm_feast_race.wav"
const PATH_FEAST_JUDGE_WU := "res://街机小游戏/audio/feast/sfx_judge_wu.wav"
const PATH_FEAST_JUDGE_QING := "res://街机小游戏/audio/feast/sfx_judge_qing.wav"
const PATH_FEAST_JUDGE_ZHONG := "res://街机小游戏/audio/feast/sfx_judge_zhong.wav"
const PATH_FEAST_JUDGE_MENG := "res://街机小游戏/audio/feast/sfx_judge_meng.wav"
const PATH_FEAST_JUDGE_KUANG := "res://街机小游戏/audio/feast/sfx_judge_kuang.wav"
const PATH_FEAST_EAT_BITE := "res://街机小游戏/audio/feast/sfx_eat_bite.wav"
const PATH_FEAST_EAT_BITES: PackedStringArray = [
	"res://街机小游戏/audio/feast/sfx_eat_bite_0.wav",
	"res://街机小游戏/audio/feast/sfx_eat_bite_1.wav",
	"res://街机小游戏/audio/feast/sfx_eat_bite_2.wav",
	"res://街机小游戏/audio/feast/sfx_eat_bite_3.wav",
	"res://街机小游戏/audio/feast/sfx_eat_bite_4.wav",
	"res://街机小游戏/audio/feast/sfx_eat_bite_5.wav",
	"res://街机小游戏/audio/feast/sfx_eat_bite_6.wav",
	"res://街机小游戏/audio/feast/sfx_eat_bite_7.wav",
]
const PATH_FEAST_EAT_DONE := "res://街机小游戏/audio/feast/sfx_eat_done.wav"
const PATH_FEAST_PROMPT_SWITCH := "res://街机小游戏/audio/feast/sfx_prompt_switch.wav"
const PATH_FEAST_BUFF_GAIN := "res://街机小游戏/audio/feast/sfx_buff_gain.wav"
const PATH_FEAST_BANANA_BURP := "res://街机小游戏/audio/feast/sfx_banana_burp.wav"
const PATH_FEAST_PEEL_SLIP := "res://街机小游戏/audio/feast/sfx_peel_slip.wav"
const PATH_FEAST_RANK := "res://街机小游戏/audio/feast/sfx_rank.wav"
const PATH_FEAST_INTRO_WALK := "res://街机小游戏/audio/feast/sfx_intro_walk.wav"
const PATH_FEAST_INTRO_JUMP := "res://街机小游戏/audio/feast/sfx_intro_jump.wav"
const PATH_DICE_ROLL_LIGHT := "res://街机小游戏/audio/dice/sfx_roll_light.wav"
const PATH_DICE_ROLL_MID := "res://街机小游戏/audio/dice/sfx_roll_mid.wav"
const PATH_DICE_ROLL_HARD := "res://街机小游戏/audio/dice/sfx_roll_hard.wav"
const PATH_DICE_FEVER := "res://街机小游戏/audio/dice/sfx_dice_fever.wav"
const PATH_DICE_LAND := "res://街机小游戏/audio/dice/sfx_land.wav"
const PATH_DICE_JACKPOT := "res://街机小游戏/audio/dice/sfx_jackpot.wav"
const PATH_DICE_RANK_WIN := "res://街机小游戏/audio/dice/sfx_rank_win.wav"
const PATH_DICE_RANK_LOSE := "res://街机小游戏/audio/dice/sfx_rank_lose.wav"
const _DICE_SFX_SCRIPT := "res://街机小游戏/scripts/dice/dice_sfx_3d.gd"
const PATH_EAT_GRAY := "res://街机小游戏/audio/sfx_eat_gray.wav"
const PATH_EAT_YELLOW := "res://街机小游戏/audio/sfx_eat_yellow.wav"
const PATH_EAT_RED := "res://街机小游戏/audio/sfx_eat_red.wav"
const PATH_COIN := "res://街机小游戏/audio/sfx_coin.wav"
const PATH_START := "res://街机小游戏/audio/sfx_start.wav"
const PATH_DIE := "res://街机小游戏/audio/sfx_die.wav"
const PATH_CLAW := "res://街机小游戏/audio/sfx_claw.wav"
const PATH_ROULETTE_START := "res://街机小游戏/audio/roulette/sfx_start.wav"
const PATH_ROULETTE_TICK := "res://街机小游戏/audio/roulette/sfx_tick.wav"
const PATH_ROULETTE_STOP := "res://街机小游戏/audio/roulette/sfx_stop.wav"
const PATH_PLANE_SHOOT := "res://街机小游戏/audio/plane/sfx_shoot.wav"
const PATH_PLANE_SHOOT_ENEMY_SMALL := "res://街机小游戏/audio/plane/sfx_shoot_enemy_small.wav"
const PATH_PLANE_SHOOT_ENEMY_BIG := "res://街机小游戏/audio/plane/sfx_shoot_enemy_big.wav"
const PATH_PLANE_SHOOT_BOSS := "res://街机小游戏/audio/plane/sfx_shoot_boss.wav"
const PATH_PLANE_BOSS_ENTRY_MISSILE := "res://街机小游戏/audio/plane/sfx_boss_entry_missile.wav"
const PATH_PLANE_HIT_RED := "res://街机小游戏/audio/plane/sfx_hit_red.wav"
const PATH_PLANE_HIT_CYAN := "res://街机小游戏/audio/plane/sfx_hit_cyan.wav"
const PATH_PLANE_HIT_PURPLE := "res://街机小游戏/audio/plane/sfx_hit_purple.wav"
const PATH_PLANE_HIT_GOLD := "res://街机小游戏/audio/plane/sfx_hit_gold.wav"
const PATH_PLANE_HIT_BOSS := "res://街机小游戏/audio/plane/sfx_hit_boss.wav"
const PATH_PLANE_EXPLODE_RED := "res://街机小游戏/audio/plane/sfx_explode_red.wav"
const PATH_PLANE_EXPLODE_CYAN := "res://街机小游戏/audio/plane/sfx_explode_cyan.wav"
const PATH_PLANE_EXPLODE_PURPLE := "res://街机小游戏/audio/plane/sfx_explode_purple.wav"
const PATH_PLANE_EXPLODE_GOLD := "res://街机小游戏/audio/plane/sfx_explode_gold.wav"
const PATH_PLANE_EXPLODE_BOSS_WRECK := "res://街机小游戏/audio/plane/sfx_explode_boss_wreck.wav"
const PATH_PLANE_EXPLODE_BOSS_PART := "res://街机小游戏/audio/plane/sfx_explode_boss_part.wav"
const PATH_PLANE_EXPLODE_PLAYER_DIE := "res://街机小游戏/audio/plane/sfx_explode_player_die.wav"
const PATH_PLANE_PLAYER_HURT := "res://街机小游戏/audio/plane/sfx_player_hurt.wav"
const PATH_PLANE_SHIELD_BREAK := "res://街机小游戏/audio/plane/sfx_shield_break.wav"
const PATH_PLANE_WARNING := "res://街机小游戏/audio/plane/sfx_warning.wav"
const PATH_PLANE_LOTTERY_CASH := "res://街机小游戏/audio/plane/sfx_lottery_cash.wav"
const PATH_PLANE_COLLECT_GAME_MATERIAL := "res://街机小游戏/audio/plane/sfx_collect_game_material_2s.wav"
const PATH_PLANE_COIN_ENV_POUR := "res://街机小游戏/audio/plane/sfx_coin_env_pour_4s.wav"
const PATH_PLANE_COIN_CLATTER := "res://街机小游戏/audio/plane/sfx_coin_clatter_5s.wav"
const PATH_PLANE_RUBY_DROP := "res://街机小游戏/audio/plane/sfx_ruby_drop.wav"
const PATH_PLANE_RUBY_DROPS: PackedStringArray = [
	"res://街机小游戏/audio/plane/sfx_ruby_drop_0.wav",
	"res://街机小游戏/audio/plane/sfx_ruby_drop_1.wav",
	"res://街机小游戏/audio/plane/sfx_ruby_drop_2.wav",
	"res://街机小游戏/audio/plane/sfx_ruby_drop_3.wav",
	"res://街机小游戏/audio/plane/sfx_ruby_drop_4.wav",
	"res://街机小游戏/audio/plane/sfx_ruby_drop_5.wav",
	"res://街机小游戏/audio/plane/sfx_ruby_drop_6.wav",
	"res://街机小游戏/audio/plane/sfx_ruby_drop_7.wav",
]
const RUBY_DROP_INTERVAL := 0.1
const RUBY_SFX_POOL := 16

const VOL_BGM_ATTRACT := -5.0
const VOL_BGM_ROULETTE := -5.0
const VOL_BGM_PLAY := -8.0
const VOL_BGM_EXTRA := -8.0
const VOL_BGM_PLANE := 5.0
const MINIGAME_PITCH_MAX := 1.5
## 飞机对局曲三首随机抽一首，整局不换：0=串烧 1=踩点 2=F#新旋律
const PLANE_TRACK_MEDLEY := 0
const PLANE_TRACK_STOMP := 1
const PLANE_TRACK_FRESH := 2
const PLANE_TRACK_BLUE_LOTUS := 3
const PLANE_BLUE_LOTUS_BPM := 152.0
## bgm_plane 摇滚串烧：R1(148)→朋克(186)→副歌(136)→踩点(128)→双踩(172)→尾奏回环
const PLANE_BEAT_BPM := 148.0
## bgm_plane_stomp：金属踩点 148BPM × 56 小节
const PLANE_STOMP_BPM := 148.0
const PLANE_STOMP_BEATS := 224 ## 56 bars × 4
## bgm_plane_fresh：F#金属 152BPM × 56 小节（结构同踩点）
const PLANE_FRESH_BPM := 152.0
const PLANE_FRESH_BEATS := 224
const VOL_SFX := -4.0
const VOL_SFX_EAT := 3.0
const VOL_SFX_PLANE := -6.0
const VOL_SFX_PLANE_EAT := -5.0
const VOL_SFX_PLANE_SHOOT := -7.0
const VOL_SFX_PLANE_ENEMY_EXPLODE := -3.5
## 连击断档红宝石赏音（预览 wav 较闷，不走 VOL_SFX_PLANE -6 封顶）
const VOL_SFX_PLANE_COMBO_BREAK := 8.0
const VOL_SFX_SHAFT_MOVE := -9.0 ## 落板会连打
const SHAFT_PITCH_MAX := 1.35 ## 策划上限，低于其它小游戏 1.5
const DICE_PITCH_MAX := 1.3 ## 狂拍骰子冲刺段上限
const FEAST_RACE_PITCH_MAX := 1.25 ## 赛跑冲刺段策划上限

var _bgm: AudioStreamPlayer
var _sfx: AudioStreamPlayer
var _sfx2: AudioStreamPlayer
var _sfx_fx: AudioStreamPlayer ## 爆炸/零件等，不被射击命中抢占
var _sfx_fx2: AudioStreamPlayer ## 第二 FX，避免破管/碎片/残骸互顶
var _sfx_fx_flip := false
var _sfx_eshot: AudioStreamPlayer ## 敌机/Boss 开火，不被玩家连射抢占
var _feast_bite_last := -1
var _mode: BgmMode = BgmMode.OFF
var _dice_heat := false
var _dice_3d: WeakRef
var _streams: Dictionary = {}
var _plane_beat_index: int = -1
var _plane_beat_times: PackedFloat32Array = PackedFloat32Array()
var _plane_beat_count: int = 0
var _plane_loop_sec: float = 0.0
var _plane_beat_map_ready: bool = false
var _plane_track: int = PLANE_TRACK_MEDLEY
var _plane_bgm_path: String = PATH_BGM_PLANE
var _bgm_duck_left := 0.0
var _bgm_vol_restore := VOL_BGM_PLANE
var _bgm_bus_idx := -1
var _bgm_spec_fx_idx := -1
var _plane_audio_env := 0.0
var _plane_audio_hit := 0.0
var _plane_audio_peak_follow := 0.0
var _plane_audio_beat_n := 0
var _plane_audio_beat_fired := false
var _plane_audio_last_peak_t := -999.0
var _ruby_sfx_pool: Array[AudioStreamPlayer] = []
var _ruby_pending: Array[Dictionary] = []


func _ready() -> void:
	AudioServer.set_bus_mute(0, false)
	if AudioServer.get_bus_volume_db(0) < -40.0:
		AudioServer.set_bus_volume_db(0, 0.0)

	_bgm = AudioStreamPlayer.new()
	_bgm.name = "BgmPlayer"
	_bgm.process_mode = Node.PROCESS_MODE_ALWAYS
	_bgm.finished.connect(_on_bgm_finished)
	add_child(_bgm)
	_ensure_bgm_bus()

	_sfx = AudioStreamPlayer.new()
	_sfx.name = "SfxPlayer"
	_sfx.bus = "Master"
	_sfx.volume_db = VOL_SFX
	_sfx.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_sfx)

	_sfx2 = AudioStreamPlayer.new()
	_sfx2.name = "SfxPlayer2"
	_sfx2.bus = "Master"
	_sfx2.volume_db = VOL_SFX
	_sfx2.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_sfx2)

	_sfx_fx = AudioStreamPlayer.new()
	_sfx_fx.name = "SfxFxPlayer"
	_sfx_fx.bus = "Master"
	_sfx_fx.volume_db = VOL_SFX
	_sfx_fx.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_sfx_fx)

	_sfx_fx2 = AudioStreamPlayer.new()
	_sfx_fx2.name = "SfxFxPlayer2"
	_sfx_fx2.bus = "Master"
	_sfx_fx2.volume_db = VOL_SFX
	_sfx_fx2.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_sfx_fx2)

	_sfx_eshot = AudioStreamPlayer.new()
	_sfx_eshot.name = "SfxEshotPlayer"
	_sfx_eshot.bus = "Master"
	_sfx_eshot.volume_db = VOL_SFX
	_sfx_eshot.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_sfx_eshot)

	_init_ruby_sfx_pool()

	_preload(PATH_BGM_ATTRACT, true)
	_preload(PATH_BGM_ROULETTE, true)
	_preload(PATH_BGM_PLAY, true)
	_preload(PATH_BGM_PLANE, true)
	_preload(PATH_BGM_PLANE_STOMP, true)
	_preload(PATH_BGM_PLANE_FRESH, true)
	if ResourceLoader.exists(PATH_BGM_PLANE_BLUE_LOTUS):
		_preload(PATH_BGM_PLANE_BLUE_LOTUS, true)
	if ResourceLoader.exists(PATH_BGM_LASSO):
		_preload(PATH_BGM_LASSO, true)
	if ResourceLoader.exists(PATH_BGM_FISH):
		_preload(PATH_BGM_FISH, true)
	if ResourceLoader.exists(PATH_BGM_MATCH3):
		_preload(PATH_BGM_MATCH3, true)
	if ResourceLoader.exists(PATH_BGM_PINBALL):
		_preload(PATH_BGM_PINBALL, true)
	if ResourceLoader.exists(PATH_BGM_SHAFT):
		_preload(PATH_BGM_SHAFT, true)
	if ResourceLoader.exists(PATH_BGM_DICE):
		_preload(PATH_BGM_DICE, true)
	if ResourceLoader.exists(PATH_BGM_DICE_HEAT):
		_preload(PATH_BGM_DICE_HEAT, true)
	if ResourceLoader.exists(PATH_BGM_FEAST_EAT):
		_preload(PATH_BGM_FEAST_EAT, true)
	if ResourceLoader.exists(PATH_BGM_FEAST_RACE):
		_preload(PATH_BGM_FEAST_RACE, true)
	if ResourceLoader.exists(PATH_FEAST_INTRO_WALK):
		_preload(PATH_FEAST_INTRO_WALK, false)
	if ResourceLoader.exists(PATH_FEAST_INTRO_JUMP):
		_preload(PATH_FEAST_INTRO_JUMP, false)
	if ResourceLoader.exists(PATH_FEAST_EAT_BITE):
		_preload(PATH_FEAST_EAT_BITE, false)
	for p in PATH_FEAST_EAT_BITES:
		if ResourceLoader.exists(p):
			_preload(p, false)
	if ResourceLoader.exists(PATH_FEAST_EAT_DONE):
		_preload(PATH_FEAST_EAT_DONE, false)
	_preload(PATH_EAT_GRAY, false)
	_preload(PATH_EAT_YELLOW, false)
	_preload(PATH_EAT_RED, false)
	_preload(PATH_COIN, false)
	_preload(PATH_START, false)
	_preload(PATH_DIE, false)
	_preload(PATH_CLAW, false)
	_preload(PATH_ROULETTE_START, false)
	_preload(PATH_ROULETTE_TICK, false)
	_preload(PATH_ROULETTE_STOP, false)
	_preload(PATH_PLANE_SHOOT, false)
	_preload(PATH_PLANE_SHOOT_ENEMY_SMALL, false)
	_preload(PATH_PLANE_SHOOT_ENEMY_BIG, false)
	_preload(PATH_PLANE_SHOOT_BOSS, false)
	_preload(PATH_PLANE_BOSS_ENTRY_MISSILE, false)
	_preload(PATH_PLANE_HIT_RED, false)
	_preload(PATH_PLANE_HIT_CYAN, false)
	_preload(PATH_PLANE_HIT_PURPLE, false)
	_preload(PATH_PLANE_HIT_GOLD, false)
	_preload(PATH_PLANE_HIT_BOSS, false)
	_preload(PATH_PLANE_EXPLODE_RED, false)
	_preload(PATH_PLANE_EXPLODE_CYAN, false)
	_preload(PATH_PLANE_EXPLODE_PURPLE, false)
	_preload(PATH_PLANE_EXPLODE_GOLD, false)
	_preload(PATH_PLANE_EXPLODE_BOSS_WRECK, false)
	_preload(PATH_PLANE_EXPLODE_BOSS_PART, false)
	_preload(PATH_PLANE_EXPLODE_PLAYER_DIE, false)
	_preload(PATH_PLANE_PLAYER_HURT, false)
	_preload(PATH_PLANE_SHIELD_BREAK, false)
	_preload(PATH_PLANE_WARNING, false)
	_preload(PATH_PLANE_LOTTERY_CASH, false)
	_preload(PATH_PLANE_COLLECT_GAME_MATERIAL, false)
	_preload(PATH_PLANE_COIN_ENV_POUR, false)
	_preload(PATH_PLANE_COIN_CLATTER, false)
	_preload(PATH_PLANE_RUBY_DROP, false)
	for rp in PATH_PLANE_RUBY_DROPS:
		_preload(rp, false)
	if ResourceLoader.exists(PATH_SHAFT_LAND):
		_preload(PATH_SHAFT_LAND, false)
		_preload(PATH_SHAFT_BREAK, false)
		_preload(PATH_SHAFT_CEILING_WARN, false)
		_preload(PATH_SHAFT_CRUSH, false)
		_preload(PATH_SHAFT_FALL, false)
		_preload(PATH_SHAFT_SPIKE, false)
		_preload(PATH_SHAFT_SPRING, false)
		_preload(PATH_SHAFT_MILESTONE, false)
		_preload(PATH_SHAFT_CLEAR100, false)
	if ResourceLoader.exists(PATH_DICE_ROLL_LIGHT):
		_preload(PATH_DICE_ROLL_LIGHT, false)
		_preload(PATH_DICE_ROLL_MID, false)
		_preload(PATH_DICE_ROLL_HARD, false)
		_preload(PATH_DICE_FEVER, false)
		_preload(PATH_DICE_LAND, false)
		_preload(PATH_DICE_JACKPOT, false)
		_preload(PATH_DICE_RANK_WIN, false)
		_preload(PATH_DICE_RANK_LOSE, false)
		_preload(PATH_BGM_DICE, true)
	if ResourceLoader.exists(PATH_BGM_DICE_HEAT):
		_preload(PATH_BGM_DICE_HEAT, true)

	# 等主场景就绪后由 snake_game 切 attract / roulette / play


func _preload(path: String, loop: bool) -> void:
	if not ResourceLoader.exists(path):
		push_warning("[ArcadeAudio] missing %s" % path)
		return
	## IGNORE：避免磁盘 wav 已更新但引擎仍返回旧导入缓存
	var loaded: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if loaded == null:
		loaded = load(path) as Resource
	if loaded == null:
		push_warning("[ArcadeAudio] load failed %s" % path)
		return
	var stream: AudioStream = loaded.duplicate() as AudioStream
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		if loop:
			_force_wav_loop(wav)
		else:
			wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	_streams[path] = stream


func _reload_plane_combat_sfx() -> void:
	## 进飞机局时强制刷新射击/爆炸流，改 wav 后不必杀进程
	for p in [
		PATH_PLANE_SHOOT,
		PATH_PLANE_SHOOT_ENEMY_SMALL,
		PATH_PLANE_SHOOT_ENEMY_BIG,
		PATH_PLANE_SHOOT_BOSS,
		PATH_PLANE_BOSS_ENTRY_MISSILE,
		PATH_PLANE_WARNING,
		PATH_PLANE_EXPLODE_BOSS_PART,
		PATH_PLANE_EXPLODE_BOSS_WRECK,
		PATH_PLANE_HIT_BOSS,
	]:
		_preload(p, false)


func _ensure_eshot_player() -> void:
	if _sfx_eshot != null and is_instance_valid(_sfx_eshot):
		return
	_sfx_eshot = AudioStreamPlayer.new()
	_sfx_eshot.name = "SfxEshotPlayer"
	_sfx_eshot.bus = "Master"
	_sfx_eshot.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_sfx_eshot)


func _force_wav_loop(wav: AudioStreamWAV) -> void:
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	var frames := _wav_frame_count(wav)
	if frames <= 0:
		frames = maxi(1, int(round(wav.get_length() * float(wav.mix_rate))))
	wav.loop_end = frames


func _wav_frame_count(wav: AudioStreamWAV) -> int:
	var data := wav.data
	if data.is_empty():
		return 0
	var bytes_per_frame := 1
	match wav.format:
		AudioStreamWAV.FORMAT_8_BITS:
			bytes_per_frame = 1
		AudioStreamWAV.FORMAT_16_BITS:
			bytes_per_frame = 2
		AudioStreamWAV.FORMAT_IMA_ADPCM:
			return maxi(1, int(round(wav.get_length() * float(wav.mix_rate))))
		_:
			bytes_per_frame = 2
	if wav.stereo:
		bytes_per_frame *= 2
	return data.size() / bytes_per_frame


func _on_bgm_finished() -> void:
	if _mode == BgmMode.OFF:
		return
	if _bgm.stream != null:
		_bgm.play()


func _plane_sfx_volume(volume_db: float) -> float:
	if _mode == BgmMode.PLANE:
		return minf(volume_db, VOL_SFX_PLANE)
	return volume_db


func _play_sfx(path: String, volume_db: float = VOL_SFX, respect_plane_cap: bool = true) -> void:
	var stream: AudioStream = _streams.get(path)
	if stream == null:
		return
	var player := _sfx
	if _sfx.playing:
		player = _sfx2
	player.stream = stream
	player.volume_db = _plane_sfx_volume(volume_db) if respect_plane_cap else volume_db
	player.pitch_scale = 1.0
	player.play()


## 重要战斗音效：双 FX 通道，破管/碎片/残骸可叠播
func _play_sfx_fx(path: String, volume_db: float) -> void:
	var stream: AudioStream = _streams.get(path)
	if stream == null:
		push_warning("[ArcadeAudio] missing fx stream %s" % path)
		return
	var player := _pick_sfx_fx_player()
	if player == null:
		_play_sfx(path, volume_db, false)
		return
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0
	player.play()


func _pick_sfx_fx_player() -> AudioStreamPlayer:
	if _sfx_fx == null:
		return null
	if _sfx_fx2 == null:
		return _sfx_fx
	## 优先空闲通道；都忙则轮换，避免后发盖死先发
	if not _sfx_fx.playing:
		return _sfx_fx
	if not _sfx_fx2.playing:
		return _sfx_fx2
	_sfx_fx_flip = not _sfx_fx_flip
	return _sfx_fx2 if _sfx_fx_flip else _sfx_fx


## 指定通道播 FX（碎片 / 残骸分层，保证破管同帧也能听见）
func _play_sfx_fx_slot(slot: int, path: String, volume_db: float) -> void:
	var stream: AudioStream = _streams.get(path)
	if stream == null:
		push_warning("[ArcadeAudio] missing fx stream %s" % path)
		return
	var player: AudioStreamPlayer = _sfx_fx2 if slot == 1 and _sfx_fx2 != null else _sfx_fx
	if player == null:
		_play_sfx(path, volume_db, false)
		return
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0
	player.play()


## 敌机开火：独立通道，不被玩家连射/命中顶掉
func _play_sfx_eshot(path: String, volume_db: float) -> void:
	_ensure_eshot_player()
	var stream: AudioStream = _streams.get(path)
	if stream == null:
		_preload(path, false)
		stream = _streams.get(path)
	if stream == null:
		push_warning("[ArcadeAudio] missing eshot stream %s" % path)
		return
	_sfx_eshot.stream = stream
	_sfx_eshot.volume_db = volume_db
	_sfx_eshot.pitch_scale = 1.0
	_sfx_eshot.play()


func _duck_bgm_brief(db_drop: float = 7.0, sec: float = 0.22) -> void:
	## 紫机重炮短暂压低 BGM，听觉上立刻「更猛」
	if _bgm == null or _mode != BgmMode.PLANE:
		return
	if _bgm_duck_left <= 0.0:
		_bgm_vol_restore = _bgm.volume_db
	_bgm.volume_db = _bgm_vol_restore - db_drop
	_bgm_duck_left = maxf(_bgm_duck_left, sec)


func _process(delta: float) -> void:
	if _bgm_duck_left > 0.0:
		_bgm_duck_left = maxf(0.0, _bgm_duck_left - delta)
		if _bgm_duck_left <= 0.0 and _bgm != null and _mode == BgmMode.PLANE:
			_bgm.volume_db = _bgm_vol_restore
	_tick_ruby_pending(delta)


func _init_ruby_sfx_pool() -> void:
	_ruby_sfx_pool.clear()
	for i in RUBY_SFX_POOL:
		var p := AudioStreamPlayer.new()
		p.name = "RubySfx%d" % i
		p.bus = "Master"
		p.volume_db = VOL_SFX + 5.0
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_ruby_sfx_pool.append(p)


func _play_ruby_tier_clip(path: String, fallback_burst: int = 1) -> void:
	_ruby_pending.clear()
	var stream: AudioStream = _streams.get(path)
	if stream == null:
		sfx_plane_ruby_burst(fallback_burst)
		return
	if _ruby_sfx_pool.is_empty():
		return
	var player: AudioStreamPlayer = _ruby_sfx_pool[0]
	for p in _ruby_sfx_pool:
		if not p.playing:
			player = p
			break
	player.stream = stream
	player.pitch_scale = 1.0
	player.volume_db = VOL_SFX_PLANE_COMBO_BREAK
	player.play()


## 起势(3–9)、猛攻(10–19) 连击断档
func sfx_plane_ruby_collect_material() -> void:
	_play_ruby_tier_clip(PATH_PLANE_COLLECT_GAME_MATERIAL, 1)


## 乱舞(50–99)、无双(100–159) 连击断档
func sfx_plane_ruby_coin_env() -> void:
	_play_ruby_tier_clip(PATH_PLANE_COIN_ENV_POUR, 5)


## 封神(160+) 连击断档
func sfx_plane_ruby_coin_clatter() -> void:
	_play_ruby_tier_clip(PATH_PLANE_COIN_CLATTER, 20)


func sfx_plane_ruby_burst(count: int) -> void:
	var n := maxi(0, count)
	if n <= 0:
		return
	for i in n:
		_ruby_pending.append({"t": float(i) * RUBY_DROP_INTERVAL, "seq": i})


func _tick_ruby_pending(delta: float) -> void:
	if _ruby_pending.is_empty():
		return
	var i := 0
	while i < _ruby_pending.size():
		var item: Dictionary = _ruby_pending[i]
		item["t"] = float(item["t"]) - delta
		if float(item["t"]) <= 0.0:
			_play_one_ruby_sfx(int(item.get("seq", 0)))
			_ruby_pending.remove_at(i)
		else:
			_ruby_pending[i] = item
			i += 1


func _play_one_ruby_sfx(seq: int) -> void:
	if _ruby_sfx_pool.is_empty():
		return
	var path := PATH_PLANE_RUBY_DROP
	if PATH_PLANE_RUBY_DROPS.size() > 0:
		path = PATH_PLANE_RUBY_DROPS[seq % PATH_PLANE_RUBY_DROPS.size()]
	var stream: AudioStream = _streams.get(path)
	if stream == null:
		stream = _streams.get(PATH_PLANE_RUBY_DROP)
	if stream == null:
		return
	var player: AudioStreamPlayer = _ruby_sfx_pool[0]
	for p in _ruby_sfx_pool:
		if not p.playing:
			player = p
			break
	player.stream = stream
	player.pitch_scale = randf_range(0.94, 1.08)
	player.volume_db = VOL_SFX_PLANE_COMBO_BREAK
	player.play()


func _ensure_bgm_bus() -> void:
	_bgm_bus_idx = AudioServer.get_bus_index("BGM")
	if _bgm_bus_idx < 0:
		AudioServer.add_bus(1)
		_bgm_bus_idx = 1
		AudioServer.set_bus_name(_bgm_bus_idx, "BGM")
	if _bgm_bus_idx > 0:
		AudioServer.set_bus_send(_bgm_bus_idx, &"Master")
		AudioServer.set_bus_mute(_bgm_bus_idx, false)
	if _bgm:
		_bgm.bus = "BGM"


func _ensure_bgm_spectrum() -> void:
	_ensure_bgm_bus()
	if _bgm_spec_fx_idx >= 0:
		return
	for i in AudioServer.get_bus_effect_count(_bgm_bus_idx):
		if AudioServer.get_bus_effect(_bgm_bus_idx, i) is AudioEffectSpectrumAnalyzer:
			_bgm_spec_fx_idx = i
			return
	var spec := AudioEffectSpectrumAnalyzer.new()
	spec.buffer_length = 2.0
	_bgm_spec_fx_idx = AudioServer.get_bus_effect_count(_bgm_bus_idx)
	AudioServer.add_bus_effect(_bgm_bus_idx, spec)


func _sample_bgm_bass_energy() -> float:
	if _bgm_spec_fx_idx < 0:
		return 0.0
	var inst := AudioServer.get_bus_effect_instance(_bgm_bus_idx, _bgm_spec_fx_idx)
	if inst == null:
		return 0.0
	var mag: Vector2 = inst.get_magnitude_for_frequency_range(48.0, 320.0, 1)
	return clampf(maxf(mag.x, mag.y) * 9.5, 0.0, 2.8)


func plane_bgm_spectrum_amps(count: int) -> PackedFloat32Array:
	var amps := PackedFloat32Array()
	if count < 1:
		return amps
	amps.resize(count)
	if _mode != BgmMode.PLANE:
		return amps
	_ensure_bgm_spectrum()
	if _bgm_spec_fx_idx < 0:
		return amps
	var inst := AudioServer.get_bus_effect_instance(_bgm_bus_idx, _bgm_spec_fx_idx)
	if inst == null:
		return amps
	var log_min := log(55.0)
	var log_max := log(10000.0)
	for i in count:
		var t0 := float(i) / float(count)
		var t1 := float(i + 1) / float(count)
		var f0 := exp(log_min + (log_max - log_min) * t0)
		var f1 := exp(log_min + (log_max - log_min) * t1)
		var mag: Vector2 = inst.get_magnitude_for_frequency_range(f0, f1, 1)
		amps[i] = clampf(maxf(mag.x, mag.y) * 11.0, 0.0, 1.0)
	return amps


func _reset_plane_audio_reactive() -> void:
	_plane_audio_env = 0.0
	_plane_audio_hit = 0.0
	_plane_audio_peak_follow = 0.0
	_plane_audio_beat_n = 0
	_plane_audio_beat_fired = false
	_plane_audio_last_peak_t = -999.0


func _tick_plane_audio_reactive(delta: float) -> void:
	if _bgm == null or not _bgm.playing:
		_plane_audio_env = lerpf(_plane_audio_env, 0.0, delta * 10.0)
		_plane_audio_hit = maxf(0.0, _plane_audio_hit - delta * 8.0)
		_plane_audio_beat_fired = false
		return
	_ensure_bgm_spectrum()
	var bass := _sample_bgm_bass_energy()
	_plane_audio_env = lerpf(_plane_audio_env, bass, clampf(delta * 16.0, 0.0, 1.0))
	var t := _plane_playback_t()
	var min_gap := 0.085 if _plane_track == PLANE_TRACK_BLUE_LOTUS else 0.065
	var rising := bass > _plane_audio_peak_follow * 1.07 + 0.035
	_plane_audio_peak_follow = lerpf(_plane_audio_peak_follow, bass, clampf(delta * 4.5, 0.0, 1.0))
	if rising and bass > 0.10 and t >= 0.0 and (t - _plane_audio_last_peak_t) >= min_gap:
		_plane_audio_last_peak_t = t
		_plane_audio_hit = 1.0
		_plane_audio_beat_n += 1
		_plane_audio_beat_fired = true
	else:
		_plane_audio_hit = maxf(0.0, _plane_audio_hit - delta * 8.5)


func play_attract() -> void:
	_ensure_hub_bgm(PATH_BGM_ATTRACT)
	call_deferred("_apply_hub_bgm", BgmMode.ATTRACT, PATH_BGM_ATTRACT, VOL_BGM_ATTRACT)


func play_roulette() -> void:
	_ensure_hub_bgm(PATH_BGM_ROULETTE)
	_apply_hub_bgm(BgmMode.ROULETTE, PATH_BGM_ROULETTE, VOL_BGM_ROULETTE)


func _ensure_hub_bgm(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_warning("[ArcadeAudio] missing %s" % path)
		return
	var cached: AudioStream = _streams.get(path)
	if cached == null or cached.get_length() <= 0.001:
		_preload(path, true)


func _apply_hub_bgm(mode: BgmMode, path: String, vol_db: float) -> void:
	_ensure_hub_bgm(path)
	_set_bgm(mode, path, vol_db)
	if _bgm == null or _bgm.playing:
		return
	# 主场景同帧切歌时偶发 play 失败，再灌一次流重试
	_preload(path, true)
	_set_bgm(mode, path, vol_db)
	if _bgm and not _bgm.playing:
		push_warning("[ArcadeAudio] hub bgm failed to start: %s" % path)


func play_game() -> void:
	_set_bgm(BgmMode.PLAY, PATH_BGM_PLAY, VOL_BGM_PLAY)


func play_plane() -> void:
	_plane_beat_index = -1
	_plane_beat_map_ready = false
	_bgm_duck_left = 0.0
	_reset_plane_audio_reactive()
	_reload_plane_combat_sfx()
	if PLANE_BGM_USE_BLUE_LOTUS and ResourceLoader.exists(PATH_BGM_PLANE_BLUE_LOTUS):
		_plane_track = PLANE_TRACK_BLUE_LOTUS
		_plane_bgm_path = PATH_BGM_PLANE_BLUE_LOTUS
	else:
		## 三首摇滚随机抽一首，整局持续
		_plane_track = randi() % 3
		match _plane_track:
			PLANE_TRACK_STOMP:
				_plane_bgm_path = PATH_BGM_PLANE_STOMP
			PLANE_TRACK_FRESH:
				_plane_bgm_path = PATH_BGM_PLANE_FRESH
			_:
				_plane_bgm_path = PATH_BGM_PLANE
	_set_bgm(BgmMode.PLANE, _plane_bgm_path, VOL_BGM_PLANE)
	_bgm_vol_restore = VOL_BGM_PLANE
	set_minigame_tempo(1.0)


func play_lasso() -> void:
	_set_bgm(BgmMode.LASSO, PATH_BGM_LASSO, VOL_BGM_EXTRA)
	set_minigame_tempo(1.0)


func play_fish() -> void:
	_set_bgm(BgmMode.FISH, PATH_BGM_FISH, VOL_BGM_EXTRA)
	set_minigame_tempo(1.0)


func play_match3() -> void:
	_set_bgm(BgmMode.MATCH3, PATH_BGM_MATCH3, VOL_BGM_EXTRA)
	set_minigame_tempo(1.0)


func play_pinball() -> void:
	_set_bgm(BgmMode.PINBALL, PATH_BGM_PINBALL, VOL_BGM_EXTRA)
	set_minigame_tempo(1.0)


func play_shaft() -> void:
	## 工业下坠 134BPM；层数升高 tempo 上限 1.35
	_set_bgm(BgmMode.SHAFT, PATH_BGM_SHAFT, VOL_BGM_EXTRA + 4.0)
	set_minigame_tempo(1.0)


func play_feast_eat() -> void:
	## 抢菜 124BPM 餐桌赶场，原速 loop
	_set_bgm(BgmMode.FEAST_EAT, PATH_BGM_FEAST_EAT, VOL_BGM_EXTRA + 1.2)
	set_minigame_tempo(1.0)


func play_feast_race() -> void:
	## 赛跑 BGM 固定原速（不做 set_minigame_tempo 后段加速）
	_set_bgm(BgmMode.FEAST_RACE, PATH_BGM_FEAST_RACE, VOL_BGM_EXTRA + 1.6)
	set_minigame_tempo(1.0)


func feast_race_tempo_for_remain(remain_sec: float) -> float:
	## 40s 赛跑：剩余 >12 原速，最后 12s 线性到 1.25
	if remain_sec > 12.0:
		return 1.0
	return clampf(1.0 + (12.0 - remain_sec) / 12.0 * 0.25, 1.0, FEAST_RACE_PITCH_MAX)


func _sfx_feast_path(path: String, fallback: String) -> String:
	if ResourceLoader.exists(path):
		return path
	return fallback


func sfx_feast_judge(tier: String) -> void:
	var path := PATH_FEAST_JUDGE_WU
	match tier:
		"qing":
			path = PATH_FEAST_JUDGE_QING
		"zhong":
			path = PATH_FEAST_JUDGE_ZHONG
		"meng":
			path = PATH_FEAST_JUDGE_MENG
		"kuang":
			path = PATH_FEAST_JUDGE_KUANG
	path = _sfx_feast_path(path, PATH_COIN if tier in ["meng", "kuang"] else PATH_EAT_GRAY)
	_play_sfx(path, VOL_SFX + 1.0)


func sfx_feast_eat_bite() -> void:
	var n := PATH_FEAST_EAT_BITES.size()
	var path := PATH_FEAST_EAT_BITE
	if n > 0:
		var i := randi() % n
		if n > 1 and i == _feast_bite_last:
			i = (i + 1 + randi() % (n - 1)) % n
		_feast_bite_last = i
		path = PATH_FEAST_EAT_BITES[i]
	_play_sfx(_sfx_feast_path(path, PATH_FEAST_EAT_BITE if ResourceLoader.exists(PATH_FEAST_EAT_BITE) else PATH_EAT_GRAY), VOL_SFX_EAT)


func sfx_feast_eat_done() -> void:
	_play_sfx(_sfx_feast_path(PATH_FEAST_EAT_DONE, PATH_COIN), VOL_SFX + 2.0)


func sfx_feast_prompt_switch() -> void:
	_play_sfx(_sfx_feast_path(PATH_FEAST_PROMPT_SWITCH, PATH_EAT_YELLOW), VOL_SFX)


func sfx_feast_buff_gain() -> void:
	_play_sfx(_sfx_feast_path(PATH_FEAST_BUFF_GAIN, PATH_COIN), VOL_SFX + 1.5)


func sfx_feast_banana_burp() -> void:
	_play_sfx(_sfx_feast_path(PATH_FEAST_BANANA_BURP, PATH_EAT_GRAY), VOL_SFX)


func sfx_feast_peel_slip() -> void:
	_play_sfx(_sfx_feast_path(PATH_FEAST_PEEL_SLIP, PATH_DIE), VOL_SFX)


func sfx_feast_rank(_rank: int) -> void:
	_play_sfx(_sfx_feast_path(PATH_FEAST_RANK, PATH_COIN), VOL_SFX + 3.0)


func sfx_feast_intro_walk(seat: int = 0) -> void:
	var path := _sfx_feast_path(PATH_FEAST_INTRO_WALK, PATH_EAT_GRAY)
	var stream: AudioStream = _streams.get(path)
	if stream == null:
		return
	var player := _sfx
	if _sfx.playing:
		player = _sfx2
	player.stream = stream
	player.volume_db = VOL_SFX - 7.0
	player.pitch_scale = 0.96 + float(seat % 5) * 0.035
	player.play()


func sfx_feast_intro_jump(_seat: int = 0) -> void:
	_play_sfx_fx(_sfx_feast_path(PATH_FEAST_INTRO_JUMP, PATH_COIN), VOL_SFX - 1.0)


func play_dice() -> void:
	## 铺垫曲；满 15s 切高潮曲，最后 20s 再提速
	_dice_heat = false
	_set_bgm(BgmMode.DICE, PATH_BGM_DICE, VOL_BGM_EXTRA + 1.5)
	set_minigame_tempo(1.0)


func dice_set_heat(on: bool) -> void:
	if _mode != BgmMode.DICE:
		return
	if _dice_heat == on:
		return
	_dice_heat = on
	var path := PATH_BGM_DICE_HEAT if on and ResourceLoader.exists(PATH_BGM_DICE_HEAT) else PATH_BGM_DICE
	var keep := _bgm.pitch_scale if _bgm else 1.0
	_set_bgm(BgmMode.DICE, path, VOL_BGM_EXTRA + (2.5 if on else 1.5))
	set_minigame_tempo(keep)


func dice_update_clock(elapsed_sec: float, remain_sec: float) -> void:
	## 0–15s 铺垫，15s 起高潮，剩余 ≤20s（约 55s）提速
	dice_set_heat(elapsed_sec >= 15.0)
	set_minigame_tempo(dice_tempo_for_remain(remain_sec))


func set_minigame_tempo(pitch: float) -> void:
	if _bgm == null:
		return
	## 飞机大战整局锁原速，其它小游戏仍可用曲速
	if _mode == BgmMode.PLANE:
		_bgm.pitch_scale = 1.0
		return
	var hi := MINIGAME_PITCH_MAX
	if _mode == BgmMode.SHAFT:
		hi = SHAFT_PITCH_MAX
	elif _mode == BgmMode.DICE:
		hi = DICE_PITCH_MAX
	elif _mode == BgmMode.FEAST_RACE:
		hi = FEAST_RACE_PITCH_MAX
	_bgm.pitch_scale = clampf(pitch, 0.85, hi)


func stop_bgm() -> void:
	_mode = BgmMode.OFF
	_plane_beat_index = -1
	_reset_plane_audio_reactive()
	if _bgm:
		_bgm.stop()
		_bgm.pitch_scale = 1.0


## 对局结束：先停对局曲，避免和结束界面叠在一起
func on_game_over() -> void:
	stop_bgm()


func _set_bgm(mode: BgmMode, path: String, vol_db: float) -> void:
	var stream: AudioStream = _streams.get(path)
	if stream == null:
		push_warning("[ArcadeAudio] no stream for %s" % path)
		return
	if _mode == mode and _bgm.playing and _bgm.stream == stream:
		_bgm.volume_db = vol_db
		return
	_mode = mode
	_bgm.stop()
	_bgm.stream = stream
	_bgm.volume_db = vol_db
	_bgm.pitch_scale = 1.0
	if not _bgm.is_inside_tree():
		call_deferred("_deferred_bgm_play")
	else:
		_bgm.play()


func _deferred_bgm_play() -> void:
	if _bgm and _bgm.stream and _mode != BgmMode.OFF:
		_bgm.play()


func sfx_eat(kind: int) -> void:
	var vol := VOL_SFX_PLANE_EAT if _mode == BgmMode.PLANE else VOL_SFX_EAT
	match kind:
		3:
			_play_sfx(PATH_EAT_RED, vol)
		4:
			_play_sfx(PATH_EAT_YELLOW, vol)
		_:
			_play_sfx(PATH_EAT_GRAY, vol)


func sfx_coin() -> void:
	_play_sfx(PATH_COIN)


func sfx_start() -> void:
	_play_sfx(PATH_START)


func sfx_speedup(level: int = 1) -> void:
	var stream: AudioStream = _streams.get(PATH_START)
	if stream == null:
		_play_sfx(PATH_EAT_YELLOW, VOL_SFX_EAT)
		return
	var player := _sfx2 if _sfx.playing else _sfx
	player.stream = stream
	player.pitch_scale = clampf(1.05 + float(level) * 0.09, 1.0, 1.72)
	player.volume_db = VOL_SFX + 1.5
	player.play()


func sfx_die() -> void:
	_play_sfx(PATH_DIE)


func sfx_claw() -> void:
	_play_sfx(PATH_CLAW)


func sfx_roulette_start() -> void:
	_play_sfx(PATH_ROULETTE_START, VOL_SFX + 2.0)


func sfx_roulette_tick(slow: float = 0.0) -> void:
	var stream: AudioStream = _streams.get(PATH_ROULETTE_TICK)
	if stream == null:
		return
	var player := _sfx2 if _sfx.playing else _sfx
	player.stream = stream
	player.pitch_scale = lerpf(1.1, 0.78, clampf(slow, 0.0, 1.0))
	player.volume_db = VOL_SFX + 0.5
	player.play()


func sfx_roulette_stop() -> void:
	_play_sfx_fx(PATH_ROULETTE_STOP, VOL_SFX + 3.5)


func sfx_plane_shoot() -> void:
	_play_sfx(PATH_PLANE_SHOOT, VOL_SFX_PLANE_SHOOT + 2.0)


func sfx_plane_shoot_enemy_small() -> void:
	## 红/青小机：短促细弹，独立通道
	_play_sfx_eshot(PATH_PLANE_SHOOT_ENEMY_SMALL, 1.5)


func sfx_plane_shoot_enemy_big() -> void:
	## 大型机：02_plasma_bolt 裁剪版，偏响 + 进局 reload
	_preload(PATH_PLANE_SHOOT_ENEMY_BIG, false)
	_play_sfx_eshot(PATH_PLANE_SHOOT_ENEMY_BIG, 12.0)
	_duck_bgm_brief(6.0, 0.18)


func sfx_plane_shoot_boss() -> void:
	## Boss 炮：同通道里最响一档
	_play_sfx_eshot(PATH_PLANE_SHOOT_BOSS, 5.0)


func sfx_plane_boss_entry_missile() -> void:
	_preload(PATH_PLANE_BOSS_ENTRY_MISSILE, false)
	_play_sfx_fx(PATH_PLANE_BOSS_ENTRY_MISSILE, 10.5)


func sfx_plane_hit(kind: int = 0, is_boss: bool = false) -> void:
	if is_boss:
		## 金属弹撞击装甲：走 FX 通道，不被玩家连射顶掉；音量不受飞机上限压制
		_preload(PATH_PLANE_HIT_BOSS, false)
		_play_sfx_fx(PATH_PLANE_HIT_BOSS, 4.0)
		return
	match clampi(kind, 0, 3):
		1:
			_play_sfx(PATH_PLANE_HIT_CYAN, VOL_SFX_PLANE_SHOOT + 2.0)
		2:
			_play_sfx(PATH_PLANE_HIT_PURPLE, VOL_SFX_PLANE_EAT + 2.0)
		3:
			_play_sfx(PATH_PLANE_HIT_GOLD, VOL_SFX_PLANE_EAT + 2.0)
		_:
			_play_sfx(PATH_PLANE_HIT_RED, VOL_SFX_PLANE_SHOOT + 2.0)


func sfx_plane_explode(kind: int = 0, is_boss: bool = false) -> void:
	if is_boss:
		_preload(PATH_PLANE_EXPLODE_BOSS_WRECK, false)
		_play_sfx_fx_slot(1, PATH_PLANE_EXPLODE_BOSS_WRECK, 8.5)
		return
	var vol := 0.5 + VOL_SFX_PLANE_ENEMY_EXPLODE
	var path := PATH_PLANE_EXPLODE_RED
	match clampi(kind, 0, 3):
		1:
			path = PATH_PLANE_EXPLODE_CYAN
			vol = 1.0 + VOL_SFX_PLANE_ENEMY_EXPLODE
		2:
			path = PATH_PLANE_EXPLODE_PURPLE
			vol = 1.75 + VOL_SFX_PLANE_ENEMY_EXPLODE
		3:
			path = PATH_PLANE_EXPLODE_GOLD
			vol = 2.25 + VOL_SFX_PLANE_ENEMY_EXPLODE
	_play_sfx_fx(path, vol)


func sfx_plane_boss_wreck() -> void:
	_preload(PATH_PLANE_EXPLODE_BOSS_WRECK, false)
	_play_sfx_fx_slot(1, PATH_PLANE_EXPLODE_BOSS_WRECK, 8.5)


func sfx_plane_boss_part() -> void:
	## 零件脱落爆炸：固定槽 0，可与破管/残骸叠播；音量偏大
	_preload(PATH_PLANE_EXPLODE_BOSS_PART, false)
	_play_sfx_fx_slot(0, PATH_PLANE_EXPLODE_BOSS_PART, 10.0)


func sfx_plane_warning() -> void:
	## Boss 战前 WARNING 警笛：独立 FX 通道，明显双音调
	_play_sfx_fx(PATH_PLANE_WARNING, 6.0)


## 结算彩票：BV14Z421t7Ms 整段数钱（不论张数，只播一次）
func sfx_plane_lottery_cash(_seq: int = 0) -> void:
	var path := PATH_PLANE_LOTTERY_CASH
	_preload(path, false)
	var stream: AudioStream = _streams.get(path)
	if stream == null:
		return
	var player := _pick_sfx_fx_player()
	if player == null:
		_play_sfx(path, VOL_SFX + 9.0, false)
		return
	player.stream = stream
	player.volume_db = VOL_SFX + 9.0
	player.pitch_scale = 1.0
	player.play()


func sfx_plane_player_hurt() -> void:
	## 自机扣血（hurt_02 电火花刮擦），FX 通道避免被连射顶掉
	_preload(PATH_PLANE_PLAYER_HURT, false)
	_play_sfx_fx(PATH_PLANE_PLAYER_HURT, 8.5)


func sfx_plane_shield_break() -> void:
	## 护盾被打掉（hurt_04 气流 whoosh）
	_preload(PATH_PLANE_SHIELD_BREAK, false)
	_play_sfx_fx(PATH_PLANE_SHIELD_BREAK, 7.5)


func sfx_plane_player_die() -> void:
	## 自机被击落：明显爆炸，弱于 Boss 残骸/解体
	_play_sfx_fx(PATH_PLANE_EXPLODE_PLAYER_DIE, 3.5)


func _shaft_has(path: String) -> bool:
	return _streams.get(path) != null


func sfx_shaft_land() -> void:
	if _shaft_has(PATH_SHAFT_LAND):
		_play_sfx(PATH_SHAFT_LAND, VOL_SFX_SHAFT_MOVE)
	else:
		_play_sfx(PATH_EAT_YELLOW, VOL_SFX - 4.0)


func sfx_shaft_break() -> void:
	if _shaft_has(PATH_SHAFT_BREAK):
		_play_sfx(PATH_SHAFT_BREAK, VOL_SFX)
	else:
		_play_sfx(PATH_EAT_GRAY, VOL_SFX)


func sfx_shaft_ceiling_warn() -> void:
	if _shaft_has(PATH_SHAFT_CEILING_WARN):
		_play_sfx(PATH_SHAFT_CEILING_WARN, VOL_SFX - 6.0)
	else:
		_play_sfx(PATH_EAT_GRAY, VOL_SFX - 8.0)


func sfx_shaft_crush() -> void:
	if _shaft_has(PATH_SHAFT_CRUSH):
		_play_sfx_fx(PATH_SHAFT_CRUSH, VOL_SFX + 2.5)
	else:
		_play_sfx_fx(PATH_DIE, VOL_SFX)


func sfx_shaft_fall() -> void:
	if _shaft_has(PATH_SHAFT_FALL):
		_play_sfx_fx(PATH_SHAFT_FALL, VOL_SFX + 2.0)
	else:
		_play_sfx_fx(PATH_DIE, VOL_SFX)


func sfx_shaft_spike() -> void:
	if _shaft_has(PATH_SHAFT_SPIKE):
		_play_sfx(PATH_SHAFT_SPIKE, VOL_SFX + 1.0)
	else:
		_play_sfx(PATH_EAT_RED, VOL_SFX)


func sfx_shaft_spring() -> void:
	if _shaft_has(PATH_SHAFT_SPRING):
		_play_sfx(PATH_SHAFT_SPRING, VOL_SFX - 1.0)
	else:
		_play_sfx(PATH_EAT_YELLOW, VOL_SFX)


func sfx_shaft_milestone() -> void:
	if _shaft_has(PATH_SHAFT_MILESTONE):
		_play_sfx_fx(PATH_SHAFT_MILESTONE, VOL_SFX + 1.5)
	else:
		_play_sfx_fx(PATH_START, VOL_SFX)


func sfx_shaft_clear100() -> void:
	if _shaft_has(PATH_SHAFT_CLEAR100):
		_play_sfx_fx(PATH_SHAFT_CLEAR100, VOL_SFX + 3.0)
	else:
		sfx_shaft_milestone()


## 层数 0→100：曲速 1.0→1.35（策划上限）
func shaft_tempo_for_level(level: int) -> float:
	return clampf(1.0 + float(maxi(level, 0)) / 100.0 * 0.35, 1.0, SHAFT_PITCH_MAX)


func bind_dice_3d(origin: Node3D) -> void:
	## 把拍击/落格/爆奖挂到 SubViewport 里的骰子位置；无 origin 则回退 2D
	if origin == null:
		clear_dice_3d()
		return
	var node: Node = origin.get_node_or_null("DiceSfx3D")
	if node == null:
		for c in origin.get_children():
			if c.has_method("play_fx") and c.has_method("play"):
				node = c
				break
	if node == null:
		if not ResourceLoader.exists(_DICE_SFX_SCRIPT):
			return
		var dice_script: Script = load(_DICE_SFX_SCRIPT) as Script
		if dice_script == null:
			return
		var made: Node = dice_script.new()
		made.name = "DiceSfx3D"
		origin.add_child(made)
		node = made
	_dice_3d = weakref(node)


func clear_dice_3d() -> void:
	_dice_3d = null


func _dice_3d_node() -> Node:
	if _dice_3d == null:
		return null
	var n: Variant = _dice_3d.get_ref()
	if n == null or not is_instance_valid(n):
		return null
	return n as Node


func _play_dice_world(path: String, volume_db: float, fx: bool) -> void:
	var node := _dice_3d_node()
	var stream: AudioStream = _streams.get(path)
	if node != null and stream != null:
		if fx and node.has_method("play_fx"):
			node.call("play_fx", stream, volume_db)
			return
		if node.has_method("play"):
			node.call("play", stream, volume_db)
			return
	if fx:
		_play_sfx_fx(path, volume_db)
	else:
		_play_sfx(path, volume_db)


func sfx_dice_roll_light() -> void:
	_play_dice_world(PATH_DICE_ROLL_LIGHT, VOL_SFX - 3.0, false)


func sfx_dice_roll_mid() -> void:
	_play_dice_world(PATH_DICE_ROLL_MID, VOL_SFX - 1.0, false)


func sfx_dice_roll_hard() -> void:
	_play_dice_world(PATH_DICE_ROLL_HARD, VOL_SFX + 1.5, false)


func sfx_dice_fever() -> void:
	_play_dice_world(PATH_DICE_FEVER, VOL_SFX + 3.0, true)


func sfx_dice_land() -> void:
	_play_dice_world(PATH_DICE_LAND, VOL_SFX - 2.0, false)


func sfx_dice_jackpot() -> void:
	_play_dice_world(PATH_DICE_JACKPOT, VOL_SFX + 2.5, true)


func sfx_dice_rank_win() -> void:
	_play_sfx_fx(PATH_DICE_RANK_WIN, VOL_SFX + 3.0)


func sfx_dice_rank_lose() -> void:
	_play_sfx_fx(PATH_DICE_RANK_LOSE, VOL_SFX + 0.5)


## 窗口内拍击次数 → 轻/普/猛/狂（策划 §6.2）
func sfx_dice_roll(hits: int) -> void:
	if hits >= 8:
		sfx_dice_fever()
	elif hits >= 5:
		sfx_dice_roll_hard()
	elif hits >= 2:
		sfx_dice_roll_mid()
	else:
		sfx_dice_roll_light()


## 剩余秒数：>20 原速，最后 20s 线性到 1.3
func dice_tempo_for_remain(remain_sec: float) -> float:
	if remain_sec > 20.0:
		return 1.0
	return clampf(1.0 + (20.0 - remain_sec) / 20.0 * 0.3, 1.0, DICE_PITCH_MAX)


func sfx_tetris_move() -> void:
	_play_sfx(PATH_EAT_GRAY, VOL_SFX - 1.0)


func sfx_tetris_rotate() -> void:
	_play_sfx(PATH_EAT_GRAY, VOL_SFX + 1.0)


func sfx_tetris_land() -> void:
	_play_sfx(PATH_EAT_YELLOW, VOL_SFX + 0.5)


func sfx_tetris_clear(lines: int) -> void:
	var vol := VOL_SFX_EAT + 2.0 + float(mini(lines, 4)) * 2.2
	if _mode == BgmMode.PLANE:
		vol = VOL_SFX_PLANE_SHOOT + float(mini(lines, 4)) * 1.2
	var path := PATH_EAT_RED if lines >= 2 else PATH_EAT_YELLOW
	var stream: AudioStream = _streams.get(path)
	if stream == null:
		return
	var player := _sfx2 if _sfx.playing else _sfx
	player.stream = stream
	player.pitch_scale = clampf(0.92 + float(mini(lines, 4)) * 0.06, 0.88, 1.18)
	player.volume_db = _plane_sfx_volume(vol)
	player.play()


func _plane_smooth01(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)


func _plane_clock_add_constant(durs: Array, bpm: float, beats: int) -> void:
	var d := 60.0 / bpm
	for _i in beats:
		durs.append(d)


func _plane_clock_add_ramp(durs: Array, bpm0: float, bpm1: float, beats: int) -> void:
	for i in beats:
		var u := _plane_smooth01((float(i) + 0.5) / float(beats))
		var bpm := lerpf(bpm0, bpm1, u)
		durs.append(60.0 / bpm)


func _ensure_plane_beat_map() -> void:
	if _plane_beat_map_ready:
		return
	var durs: Array[float] = []
	if _plane_track == PLANE_TRACK_BLUE_LOTUS:
		var song_len := _plane_active_stream_length()
		var beat_d := 60.0 / PLANE_BLUE_LOTUS_BPM
		var beats := maxi(16, int(ceil(song_len / beat_d)) if song_len > 0.01 else 128)
		_plane_clock_add_constant(durs, PLANE_BLUE_LOTUS_BPM, beats)
	elif _plane_track == PLANE_TRACK_STOMP:
		_plane_clock_add_constant(durs, PLANE_STOMP_BPM, PLANE_STOMP_BEATS)
	elif _plane_track == PLANE_TRACK_FRESH:
		_plane_clock_add_constant(durs, PLANE_FRESH_BPM, PLANE_FRESH_BEATS)
	else:
		_plane_clock_add_constant(durs, 148.0, 32)
		_plane_clock_add_ramp(durs, 148.0, 186.0, 8)
		_plane_clock_add_constant(durs, 186.0, 32)
		_plane_clock_add_ramp(durs, 186.0, 136.0, 8)
		_plane_clock_add_constant(durs, 136.0, 32)
		_plane_clock_add_ramp(durs, 136.0, 128.0, 8)
		_plane_clock_add_constant(durs, 128.0, 32)
		_plane_clock_add_ramp(durs, 128.0, 172.0, 8)
		_plane_clock_add_constant(durs, 172.0, 32)
		_plane_clock_add_ramp(durs, 172.0, 148.0, 8)
	var times := PackedFloat32Array()
	var t := 0.0
	for d in durs:
		times.append(t)
		t += d
	_plane_beat_times = times
	_plane_beat_count = durs.size()
	_plane_loop_sec = t
	if _plane_track == PLANE_TRACK_BLUE_LOTUS:
		var song_len := _plane_active_stream_length()
		if song_len > 0.01:
			_plane_loop_sec = song_len
	_plane_beat_map_ready = true


func _plane_playback_t() -> float:
	if _bgm == null or _mode != BgmMode.PLANE or not _bgm.playing:
		return -1.0
	_ensure_plane_beat_map()
	var t := _bgm.get_playback_position() * _bgm.pitch_scale
	if _plane_track == PLANE_TRACK_BLUE_LOTUS:
		var song_len := _plane_active_stream_length()
		if song_len > 0.01:
			return clampf(t, 0.0, song_len)
		return t
	if _plane_loop_sec > 0.001:
		t = fposmod(t, _plane_loop_sec)
	return t


func _plane_beat_index_at(t: float) -> int:
	var idx := 0
	while idx + 1 < _plane_beat_count and _plane_beat_times[idx + 1] <= t:
		idx += 1
	return clampi(idx, 0, maxi(0, _plane_beat_count - 1))


func _plane_beat_duration(idx: int) -> float:
	if idx + 1 < _plane_beat_count:
		return _plane_beat_times[idx + 1] - _plane_beat_times[idx]
	return maxf(_plane_loop_sec - _plane_beat_times[idx], 0.001)


func _plane_active_stream_length() -> float:
	var stream: AudioStream = _streams.get(_plane_bgm_path)
	if stream == null and _bgm != null:
		stream = _bgm.stream
	if stream == null:
		return 0.0
	return stream.get_length()


func _plane_section_for_beat(idx: int) -> Dictionary:
	if _plane_track == PLANE_TRACK_BLUE_LOTUS:
		var bar := idx / 4
		var climax := 0
		if bar >= 12 and bar < 24:
			climax = 1
		elif bar >= 24:
			climax = 2
		return {"id": "bl", "climax": climax, "beat0": (idx / 16) * 16}
	if _plane_track == PLANE_TRACK_STOMP or _plane_track == PLANE_TRACK_FRESH:
		return _plane_stomp_section_for_beat(idx)
	if idx < 32:
		return {"id": "r1", "climax": 0, "beat0": 0}
	if idx < 40:
		return {"id": "br1", "climax": 0, "beat0": 32}
	if idx < 72:
		return {"id": "r2", "climax": 1, "beat0": 40}
	if idx < 80:
		return {"id": "br2", "climax": 0, "beat0": 72}
	if idx < 112:
		return {"id": "r3", "climax": 1, "beat0": 80}
	if idx < 120:
		return {"id": "br3", "climax": 0, "beat0": 112}
	if idx < 152:
		return {"id": "r4", "climax": 2, "beat0": 120}
	if idx < 160:
		return {"id": "br4", "climax": 2, "beat0": 152}
	if idx < 192:
		return {"id": "r5", "climax": 3, "beat0": 160}
	return {"id": "coda", "climax": 0, "beat0": 192}


## bgm_plane_stomp：56 小节 × 4 拍，恒定 148BPM
func _plane_stomp_section_for_beat(idx: int) -> Dictionary:
	if idx < 16:
		return {"id": "st_intro", "climax": 0, "beat0": 0}
	if idx < 48:
		return {"id": "st_verse", "climax": 0, "beat0": 16}
	if idx < 64:
		return {"id": "st_pre", "climax": 1, "beat0": 48}
	if idx < 96:
		return {"id": "st_chorus", "climax": 2, "beat0": 64}
	if idx < 112:
		return {"id": "st_break", "climax": 0, "beat0": 96}
	if idx < 128:
		return {"id": "st_lift", "climax": 1, "beat0": 112}
	if idx < 192:
		return {"id": "st_final", "climax": 3, "beat0": 128}
	return {"id": "st_outro", "climax": 0, "beat0": 192}


func plane_bgm_synced() -> bool:
	return _plane_playback_t() >= 0.0


## 0~1：当前拍内相位（可变 BPM 节拍表）
func plane_beat_phase() -> float:
	var t := _plane_playback_t()
	if t < 0.0:
		return 0.0
	var idx := _plane_beat_index_at(t)
	var t0 := _plane_beat_times[idx]
	var dur := _plane_beat_duration(idx)
	return clampf((t - t0) / dur, 0.0, 1.0)


func plane_climax_tier() -> int:
	var t := _plane_playback_t()
	if t < 0.0:
		return 0
	return int(_plane_section_for_beat(_plane_beat_index_at(t)).get("climax", 0))


func plane_climax_brightness_mult() -> float:
	match plane_climax_tier():
		1:
			return 1.14
		2:
			return 1.32
		3:
			return 1.52
		_:
			return 1.0


## 与段落/和弦进行对齐的彩虹色相（0~1，红→紫）
func plane_rainbow_hue() -> float:
	var beat_f := plane_beat_continuous()
	if beat_f <= 0.001 and not plane_bgm_synced():
		return 0.0
	if _plane_track == PLANE_TRACK_BLUE_LOTUS:
		var hue := fmod(0.08 + beat_f * 0.018 + _plane_audio_env * 0.06, 1.0)
		if _plane_audio_hit > 0.35:
			hue = fmod(hue + 0.07, 1.0)
		return hue
	var idx := int(floor(beat_f))
	var sec: Dictionary = _plane_section_for_beat(idx)
	var sid: String = str(sec.get("id", "r1"))
	var b0: int = int(sec.get("beat0", 0))
	var local := beat_f - float(b0)
	match sid:
		"bl":
			return fmod(0.06 + local / 16.0 * 0.55, 1.0)
		"r1":
			return fmod(local / 32.0 * 0.16, 1.0)
		"br1":
			return fmod(0.12 + local / 8.0 * 0.10, 1.0)
		"r2":
			return fmod(0.06 + local / 16.0 * 0.48, 1.0)
		"br2":
			return fmod(0.38 + local / 8.0 * 0.14, 1.0)
		"r3":
			var bar := int(floor(local / 4.0))
			var intra := fmod(local, 4.0) / 4.0
			var sweep := (float(bar % 8) + intra) / 8.0
			return fmod(0.10 + sweep * 0.58, 1.0)
		"br3":
			return fmod(0.52 + local / 8.0 * 0.12, 1.0)
		"r4":
			var bar4 := int(floor(local / 4.0)) % 4
			var intra4 := fmod(local, 4.0) / 4.0
			return fmod(0.48 + float(bar4) * 0.11 + intra4 * 0.08, 1.0)
		"br4":
			return fmod(0.72 + local / 8.0 * 0.16, 1.0)
		"r5":
			return fmod(0.58 + local / 8.0 * 0.38, 1.0)
		"st_intro":
			return fmod(local / 16.0 * 0.12, 1.0)
		"st_verse":
			return fmod(0.08 + local / 32.0 * 0.22, 1.0)
		"st_pre":
			return fmod(0.28 + local / 16.0 * 0.14, 1.0)
		"st_chorus":
			return fmod(0.18 + local / 32.0 * 0.42, 1.0)
		"st_break":
			return fmod(0.55 + local / 16.0 * 0.1, 1.0)
		"st_lift":
			return fmod(0.35 + local / 16.0 * 0.18, 1.0)
		"st_final":
			return fmod(0.48 + local / 64.0 * 0.4, 1.0)
		"st_outro":
			return fmod(0.08 + local / 32.0 * 0.12, 1.0)
		_:
			return fmod(0.05 + local / 8.0 * 0.12, 1.0)


func _plane_beat_energy_grid() -> float:
	var t := _plane_playback_t()
	if t < 0.0:
		return 0.0
	var idx := _plane_beat_index_at(t)
	var t0 := _plane_beat_times[idx]
	var dur := _plane_beat_duration(idx)
	var ph := clampf((t - t0) / dur, 0.0, 1.0)
	var hit := exp(-ph * 9.5)
	var bar_start := idx - (idx % 4)
	var bar_t0 := _plane_beat_times[bar_start]
	var bar_dur := 0.0
	for k in 4:
		var bi := bar_start + k
		if bi < _plane_beat_count:
			bar_dur += _plane_beat_duration(bi)
	var bar_ph := clampf((t - bar_t0) / maxf(bar_dur, 0.001), 0.0, 1.0)
	var bar := exp(-bar_ph * 7.0)
	var tier := int(_plane_section_for_beat(idx).get("climax", 0))
	var tier_boost := 1.0 + float(tier) * 0.09
	var bridge_tail := 0.0
	var sid: String = str(_plane_section_for_beat(idx).get("id", ""))
	if sid.begins_with("br") and (idx - int(_plane_section_for_beat(idx).get("beat0", 0))) >= 6:
		bridge_tail = 0.22
	return clampf(hit * (0.55 + bar * 0.68 + bridge_tail) * tier_boost, 0.0, 1.75)


func plane_tick_reactive(delta: float) -> void:
	if _mode == BgmMode.PLANE:
		_tick_plane_audio_reactive(delta)


func plane_beat_energy() -> float:
	if _mode != BgmMode.PLANE:
		return 0.0
	var grid := _plane_beat_energy_grid()
	var audio := clampf(_plane_audio_env * 0.72 + _plane_audio_hit * 1.25, 0.0, 1.9)
	if _plane_track == PLANE_TRACK_BLUE_LOTUS:
		return clampf(maxf(audio, grid * 0.22), 0.0, 1.85)
	return clampf(maxf(grid, audio * 0.88), 0.0, 1.85)


## 0=刚闪，1=拍尾（侧栏/子弹脉冲用）
func plane_music_beat_phase() -> float:
	if _plane_audio_hit > 0.02:
		return clampf(1.0 - _plane_audio_hit, 0.0, 1.0)
	return plane_beat_phase()


## 连续拍位（小数），与 gen_plane_rock_medley 节拍表一致
func plane_beat_continuous() -> float:
	if _mode == BgmMode.PLANE and _plane_track == PLANE_TRACK_BLUE_LOTUS and _plane_audio_beat_n > 0:
		return float(_plane_audio_beat_n) + clampf(1.0 - _plane_audio_hit, 0.0, 0.995)
	var t := _plane_playback_t()
	if t < 0.0:
		return 0.0
	var idx := _plane_beat_index_at(t)
	var t0 := _plane_beat_times[idx]
	var dur := _plane_beat_duration(idx)
	var frac := clampf((t - t0) / dur, 0.0, 0.999)
	return float(idx) + frac


## 新鼓点沿上一帧触发一次（用于 Beat Hazard 式粒子诞生）
func plane_beat_fired() -> Dictionary:
	if not plane_bgm_synced():
		return {"hit": false, "bar": false, "n": 0, "climax": 0, "section": ""}
	if _plane_audio_beat_fired:
		var idx_a := _plane_audio_beat_n
		_plane_audio_beat_fired = false
		return {
			"hit": true,
			"bar": (idx_a % 4) == 0,
			"n": idx_a,
			"climax": plane_climax_tier(),
			"section": "audio",
		}
	if _plane_track == PLANE_TRACK_BLUE_LOTUS:
		return {"hit": false, "bar": false, "n": _plane_audio_beat_n, "climax": plane_climax_tier(), "section": "bl"}
	var beat_f := plane_beat_continuous()
	var idx := int(floor(beat_f))
	if idx == _plane_beat_index:
		return {"hit": false, "bar": false, "n": idx, "climax": plane_climax_tier(), "section": str(_plane_section_for_beat(idx).get("id", ""))}
	_plane_beat_index = idx
	var sec: Dictionary = _plane_section_for_beat(idx)
	var bar := (idx % 4) == 0
	return {
		"hit": true,
		"bar": bar,
		"n": idx,
		"climax": int(sec.get("climax", 0)),
		"section": str(sec.get("id", "")),
	}


## 相对小节第一拍「鼓点拍头」的秒数：0=与侧栏脉冲同拍，负=提前，正=晚拍
func plane_rhythm_hit_delta_sec(beat_idx: int) -> float:
	var t := _plane_playback_t()
	if t < 0.0:
		return 999.0
	_ensure_plane_beat_map()
	if beat_idx < 0 or beat_idx >= _plane_beat_count:
		return 999.0
	var t0 := _plane_beat_times[beat_idx]
	return t - t0


func plane_beat_index_now() -> int:
	var t := _plane_playback_t()
	if t < 0.0:
		return -1
	_ensure_plane_beat_map()
	return _plane_beat_index_at(t)


func plane_beat_count() -> int:
	_ensure_plane_beat_map()
	return _plane_beat_count


func plane_beat_time_at(beat_idx: int) -> float:
	_ensure_plane_beat_map()
	if beat_idx < 0 or beat_idx >= _plane_beat_count:
		return -1.0
	return _plane_beat_times[beat_idx]


## 测试/校验：给定时间下的打拍 delta（不依赖 BGM 播放）
func plane_rhythm_hit_delta_at_t(beat_idx: int, t: float) -> float:
	_ensure_plane_beat_map()
	if beat_idx < 0 or beat_idx >= _plane_beat_count:
		return 999.0
	return t - _plane_beat_times[beat_idx]


func plane_beat_duration_at(beat_idx: int) -> float:
	_ensure_plane_beat_map()
	if beat_idx < 0 or beat_idx >= _plane_beat_count:
		return 0.5
	return _plane_beat_duration(beat_idx)


## 音游缩圈：小节第一拍，跳过过渡/间奏段
func plane_rhythm_tap_beat(beat_idx: int) -> bool:
	_ensure_plane_beat_map()
	if beat_idx < 0 or beat_idx >= _plane_beat_count:
		return false
	if beat_idx % 4 != 0:
		return false
	var sid := str(_plane_section_for_beat(beat_idx).get("id", ""))
	if sid.begins_with("br") or sid == "st_break":
		return false
	return true
