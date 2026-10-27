class_name YouyouEmotionMap
extends RefCounted

## LLM emotion → YouyouFacePresenter 拆分情绪 id。

static func to_face_emotion(llm_emotion: String) -> String:
	match llm_emotion.strip_edges().to_lower():
		"happy", "playful", "proud", "curious", "shy":
			return "smile"
		"surprised", "surprise":
			return "surprise"
		"sad", "sorrow":
			return "sad"
		"angry":
			return "angry"
		"confused", "thinking":
			return "think"
		"laugh", "excited":
			return "laugh"
		"sleepy", "tired":
			return "sleepy"
		"serious", "stern":
			return "serious"
		"smug", "proud_smile":
			return "smug_smile"
		_:
			return "smile"
