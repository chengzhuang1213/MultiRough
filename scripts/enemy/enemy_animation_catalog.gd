extends RefCounted
class_name EnemyAnimationCatalog

const FRAME_SIZE := Vector2(192, 192)
const BOSS_FRAME_SIZE := Vector2(320, 320)

const DATA := {
	"melee": {
		"idle": ["res://assets/tiny_swords_free_pack/Units/Red Units/Pawn/Pawn_Idle.png", 8, 0.12],
		"run": ["res://assets/tiny_swords_free_pack/Units/Red Units/Pawn/Pawn_Run.png", 6, 0.085],
		"attack": ["res://assets/tiny_swords_free_pack/Units/Red Units/Pawn/Pawn_Interact Knife.png", 4, 0.07],
	},
	"heavy": {
		"idle": ["res://assets/tiny_swords_free_pack/Units/Black Units/Pawn/Pawn_Idle.png", 8, 0.13],
		"run": ["res://assets/tiny_swords_free_pack/Units/Black Units/Pawn/Pawn_Run.png", 6, 0.11],
		"attack": ["res://assets/tiny_swords_free_pack/Units/Black Units/Pawn/Pawn_Interact Hammer.png", 3, 0.10],
	},
	"ranged": {
		"idle": ["res://assets/tiny_swords_free_pack/Units/Red Units/Archer/Archer_Idle.png", 6, 0.13],
		"run": ["res://assets/tiny_swords_free_pack/Units/Red Units/Archer/Archer_Run.png", 4, 0.10],
		"attack": ["res://assets/tiny_swords_free_pack/Units/Red Units/Archer/Archer_Shoot.png", 8, 0.07],
	},
	"shield": {
		"idle": ["res://assets/tiny_swords_free_pack/Units/Red Units/Warrior/Warrior_Guard.png", 6, 0.12],
		"run": ["res://assets/tiny_swords_free_pack/Units/Red Units/Warrior/Warrior_Run.png", 6, 0.10],
		"attack": ["res://assets/tiny_swords_free_pack/Units/Red Units/Warrior/Warrior_Attack1.png", 4, 0.08],
	},
	"charger": {
		"idle": ["res://assets/tiny_swords_free_pack/Units/Red Units/Lancer/Lancer_Idle.png", 12, 0.11],
		"run": ["res://assets/tiny_swords_free_pack/Units/Red Units/Lancer/Lancer_Run.png", 6, 0.08],
		"attack": ["res://assets/tiny_swords_free_pack/Units/Red Units/Lancer/Lancer_Right_Attack.png", 3, 0.09],
	},
	"bomber": {
		"idle": ["res://assets/tiny_swords_free_pack/Units/Black Units/Pawn/Pawn_Idle Hammer.png", 8, 0.12],
		"run": ["res://assets/tiny_swords_free_pack/Units/Black Units/Pawn/Pawn_Run Hammer.png", 6, 0.10],
		"attack": ["res://assets/tiny_swords_free_pack/Units/Black Units/Pawn/Pawn_Interact Hammer.png", 3, 0.12],
	},
	"priest": {
		"idle": ["res://assets/tiny_swords_free_pack/Units/Red Units/Monk/Idle.png", 6, 0.13],
		"run": ["res://assets/tiny_swords_free_pack/Units/Red Units/Monk/Run.png", 4, 0.10],
		"attack": ["res://assets/tiny_swords_free_pack/Units/Red Units/Monk/Heal.png", 11, 0.06],
	},
	"boss": {
		"idle": ["res://assets/tiny_swords_free_pack/Units/Black Units/Lancer/Lancer_Idle.png", 12, 0.11],
		"run": ["res://assets/tiny_swords_free_pack/Units/Black Units/Lancer/Lancer_Run.png", 6, 0.095],
		"attack": ["res://assets/tiny_swords_free_pack/Units/Black Units/Lancer/Lancer_Right_Attack.png", 3, 0.075],
	},
}

static func get_animation(enemy_type: String, anim_name: String, is_boss: bool = false) -> Dictionary:
	var type_key := "boss" if is_boss else enemy_type
	var type_data: Dictionary = DATA.get(type_key, DATA["melee"])
	var values: Array = type_data.get(anim_name, type_data["idle"])
	return {"path": values[0], "frames": values[1], "frame_time": values[2]}

static func get_frame_size(enemy_type: String, is_boss: bool) -> Vector2:
	return BOSS_FRAME_SIZE if is_boss or enemy_type == "charger" else FRAME_SIZE

static func get_scale(enemy_type: String, is_boss: bool) -> Vector2:
	if is_boss:
		return Vector2(0.85, 0.85)
	return {
		"heavy": Vector2(0.68, 0.68), "ranged": Vector2(0.52, 0.52),
		"shield": Vector2(0.60, 0.60), "charger": Vector2(0.58, 0.58),
		"bomber": Vector2(0.62, 0.62), "priest": Vector2(0.60, 0.60),
	}.get(enemy_type, Vector2(0.55, 0.55))

static func get_tint(enemy_type: String) -> Color:
	return {
		"heavy": Color(0.82, 0.82, 0.92, 1.0), "ranged": Color(0.95, 0.86, 0.58, 1.0),
		"shield": Color(0.72, 0.86, 1.0, 1.0), "charger": Color(1.0, 0.72, 0.72, 1.0),
		"bomber": Color(1.0, 0.68, 0.34, 1.0), "priest": Color(0.68, 1.0, 0.72, 1.0),
	}.get(enemy_type, Color.WHITE)
