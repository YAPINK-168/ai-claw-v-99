extends RefCounted
class_name VoiceStreamingAsrShared

## 正式 AI 与小游戏邀请共用 NLS WebSocket ASR 时的互斥约定（本阶段无运行时接入）。

const BUS_FORMAL := "PreviewAiVoiceRecord"
const BUS_INVITE := "InviteRecord"

const InviteStreamingAsrScript := preload("res://Scripts/voice/invite_streaming_asr.gd")


static func formal_capture_bus() -> String:
	return BUS_FORMAL


static func invite_capture_bus() -> String:
	return BUS_INVITE


## 正式持续监听可启动：无邀请监听占用且宿主允许连续听。
static func formal_may_open_capture(invite_listen_active: bool, host_may_listen: bool) -> bool:
	if invite_listen_active:
		return false
	return host_may_listen


## 邀请流式 ASR 可启动：正式 AI 会话未占用麦克风流程。
static func invite_may_open_stream(formal_session_active: bool, invite_phase_listening: bool) -> bool:
	if formal_session_active:
		return false
	return invite_phase_listening


static func create_invite_asr_parent(parent: Node, config: AliyunNlsConfig, tokens: NlsTokenProvider) -> InviteStreamingAsrScript:
	var asr := InviteStreamingAsrScript.new()
	asr.name = "SharedInviteStreamingAsr"
	parent.add_child(asr)
	asr.setup(config, tokens)
	return asr
