extends RefCounted
class_name PlayerAnimationCatalog

const FRAME_SIZE := Vector2(192, 192)
const ROOT := "res://assets/original/characters/"

static func get_animation(character_id: String, anim_name: String) -> Dictionary:
	var directory := ROOT + character_id + "/animations/"
	if anim_name in ["cast", "hit", "death"]:
		return {
			"path": directory + character_id + "_" + anim_name + ".png",
			"frames": 3 if anim_name == "hit" else 6,
			"frame_time": 0.06 if anim_name == "hit" else 0.08,
			"loop": false,
			"frame_size": FRAME_SIZE,
		}
	var suffix := "idle"
	var frames := 6
	var frame_time := 0.14
	var loops := true
	match anim_name:
		"run":
			suffix = "run"
			frame_time = 0.09
		"guard":
			suffix = "defend"
			frames = 4
			frame_time = 0.10
			loops = false
		"attack_1":
			suffix = "attack_1"
			frame_time = 0.06
			loops = false
		"attack_2":
			suffix = "attack_2"
			frame_time = 0.07
			loops = false
		"dash":
			suffix = "dash"
			frames = 4
			frame_time = 0.06
			loops = false
	return {
		"path": directory + character_id + "_" + suffix + ".png",
		"frames": frames,
		"frame_time": frame_time,
		"loop": loops,
		"frame_size": FRAME_SIZE,
	}
