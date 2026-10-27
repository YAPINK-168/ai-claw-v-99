extends RefCounted
class_name VoicePipelineBaselineStats

## 正式语音基线统计（Mock/实机均可写入）。与 VoiceTurnLatency 互补：成功率、抢占、会话结束原因。

static var turns_completed: int = 0
static var turns_error: int = 0
static var turns_aborted: int = 0
static var turns_cancelled: int = 0
static var session_closed: int = 0
static var preempt_total: int = 0
static var _preempt_by_reason: Dictionary = {}


static func reset() -> void:
	turns_completed = 0
	turns_error = 0
	turns_aborted = 0
	turns_cancelled = 0
	session_closed = 0
	preempt_total = 0
	_preempt_by_reason.clear()


static func record_turn_outcome(outcome: String) -> void:
	match outcome:
		"completed":
			turns_completed += 1
		"error":
			turns_error += 1
		"cancelled":
			turns_cancelled += 1
		_:
			if outcome.begins_with("session_") or outcome == "aborted" or outcome.begins_with("stale"):
				turns_aborted += 1


static func record_session_closed(_reason: String = "") -> void:
	session_closed += 1


static func record_preempt(reason: String) -> void:
	preempt_total += 1
	var key := reason if not reason.is_empty() else "unknown"
	_preempt_by_reason[key] = int(_preempt_by_reason.get(key, 0)) + 1


static func snapshot() -> Dictionary:
	return {
		"turns_completed": turns_completed,
		"turns_error": turns_error,
		"turns_aborted": turns_aborted,
		"turns_cancelled": turns_cancelled,
		"session_closed": session_closed,
		"preempt_total": preempt_total,
		"preempt_by_reason": _preempt_by_reason.duplicate(true),
	}


static func success_rate() -> Variant:
	var denom := turns_completed + turns_error + turns_aborted + turns_cancelled
	if denom <= 0:
		return null
	return float(turns_completed) / float(denom)


static func print_summary() -> void:
	var rate: Variant = success_rate()
	var rate_s := "—" if rate == null else "%.1f%%" % (float(rate) * 100.0)
	print(
		"voice_baseline_stats completed=%d error=%d aborted=%d cancelled=%d sessions_closed=%d preempt=%d success_rate=%s"
		% [turns_completed, turns_error, turns_aborted, turns_cancelled, session_closed, preempt_total, rate_s]
	)
	if not _preempt_by_reason.is_empty():
		print("  preempt_by_reason=", _preempt_by_reason)
