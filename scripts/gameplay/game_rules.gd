extends RefCounted
class_name GameRules

const WAVE_CLEAR_HEAL_AMOUNT := 20.0
const REVIVE_HEALTH_RATIO := 0.5
const NORMAL_WAVE_TIME_LIMIT := 60.0
const BOSS_WAVE_TIME_LIMIT := 120.0

const CHARACTER_ORDER := ["warrior", "archer", "lancer", "mage"]
const REQUIRED_CHARACTER_STATS := [
	"id",
	"name",
	"max_health",
	"move_speed",
	"attack_damage",
	"attack_cooldown",
	"attack_range",
	"skill_damage",
	"fan_skill_damage",
	"visual_scale",
	"dash_max_charges",
]

const CHARACTER_CONFIGS := {
	"warrior": {
		"id": "warrior",
		"name": "战士",
		"visual_scale": 0.49,
		"max_health": 120.0,
		"move_speed": 240.0,
		"attack_damage": 26.0,
		"attack_cooldown": 0.34,
		"attack_range": 76.0,
		"attack_half_width": 34.0,
		"attack_knockback": 150.0,
		"defense_damage_multiplier": 0.30,
		"dash_max_charges": 1,
		"skill_damage": 58.0,
		"skill_length": 220.0,
		"skill_half_width": 42.0,
		"skill_cooldown": 8.0,
		"fan_skill_damage": 115.0,
		"fan_skill_length": 250.0,
		"fan_skill_half_width": 16.0,
		"fan_skill_cooldown": 12.0,
		"ultimate_cooldown": 24.0,
	},
	"archer": {
		"id": "archer",
		"name": "弓箭手",
		"visual_scale": 0.55,
		"max_health": 95.0,
		"move_speed": 255.0,
		"attack_damage": 21.0,
		"attack_cooldown": 0.21,
		"attack_range": 420.0,
		"attack_half_width": 18.0,
		"attack_knockback": 80.0,
		"defense_damage_multiplier": 0.45,
		"dash_max_charges": 2,
		"skill_damage": 50.0,
		"skill_length": 260.0,
		"skill_half_width": 36.0,
		"skill_cooldown": 6.0,
		"fan_skill_damage": 92.0,
		"fan_skill_length": 300.0,
		"fan_skill_half_width": 14.0,
		"fan_skill_cooldown": 10.0,
		"ultimate_cooldown": 24.0,
	},
	"lancer": {
		"id": "lancer",
		"name": "长枪",
		"visual_scale": 0.55,
		"max_health": 130.0,
		"move_speed": 225.0,
		"attack_damage": 30.0,
		"attack_cooldown": 0.60,
		"attack_range": 110.4,
		"attack_half_width": 28.0,
		"attack_knockback": 95.0,
		"defense_damage_multiplier": 0.60,
		"dash_max_charges": 1,
		"skill_damage": 66.0,
		"skill_length": 260.0,
		"skill_half_width": 36.0,
		"skill_cooldown": 8.0,
		"fan_skill_damage": 120.0,
		"fan_skill_length": 280.0,
		"fan_skill_half_width": 14.0,
		"fan_skill_cooldown": 13.0,
		"ultimate_cooldown": 30.0,
	},
	"mage": {
		"id": "mage",
		"name": "法师",
		"visual_scale": 0.62,
		"max_health": 120.0,
		"move_speed": 240.0,
		"attack_damage": 18.0,
		"attack_cooldown": 0.38,
		"attack_range": 76.0,
		"attack_half_width": 34.0,
		"attack_knockback": 150.0,
		"defense_damage_multiplier": 0.45,
		"dash_max_charges": 1,
		"skill_damage": 36.0,
		"skill_length": 220.0,
		"skill_half_width": 42.0,
		"fan_skill_damage": 72.0,
		"fan_skill_length": 250.0,
		"fan_skill_half_width": 16.0,
	},
}

static func get_character_config(character_id: String) -> Dictionary:
	var fallback: Dictionary = CHARACTER_CONFIGS["warrior"]
	return (CHARACTER_CONFIGS.get(character_id, fallback) as Dictionary).duplicate(true)

static func get_mode_scaling(player_count: int) -> Dictionary:
	var multiplayer_run := player_count > 1
	return {
		"minion_count": 2.0 if multiplayer_run else 1.0,
		"enemy_health": 1.15 if multiplayer_run else 1.0,
		"enemy_damage": 1.08 if multiplayer_run else 1.0,
		"boss_health": 2.0 if multiplayer_run else 1.0,
		"boss_damage": 1.12 if multiplayer_run else 1.0,
	}

static func validate_character_configs() -> PackedStringArray:
	var errors := PackedStringArray()
	for character_id in CHARACTER_ORDER:
		if not CHARACTER_CONFIGS.has(character_id):
			errors.append("missing character: %s" % character_id)
			continue
		var config: Dictionary = CHARACTER_CONFIGS[character_id]
		for stat in REQUIRED_CHARACTER_STATS:
			if not config.has(stat):
				errors.append("%s missing stat: %s" % [character_id, stat])
		if str(config.get("id", "")) != character_id:
			errors.append("%s has mismatched id" % character_id)
	return errors
