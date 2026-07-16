extends RefCounted
class_name GameRules

const WAVE_CLEAR_HEAL_AMOUNT := 20.0
const REVIVE_HEALTH_RATIO := 0.5
const NORMAL_WAVE_TIME_LIMIT := 120.0
const BOSS_WAVE_TIME_LIMIT := 180.0
const PLAYER_DAMAGE_GROWTH_PER_WAVE := 0.02

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

const CHARACTER_ACTION_TOOLTIPS := {
	"warrior": {
		"BASIC": "普攻 · 剑击\n前方近战攻击，造成伤害并击退敌人。",
		"DODGE": "闪避\n快速位移并短暂无敌。",
		"SECONDARY": "右键 · 持续格挡\n按住后只承受 30% 伤害，松开结束格挡。",
		"Q": "Q · 战吼\n伤害并牵引附近普通敌人，嘲讽 2 秒；期间自身受到伤害减半。",
		"E": "E · 反击姿态\n持续 3 秒，反弹敌人伤害并周期震击附近目标。",
		"F": "F · 环绕刀刃\n召唤环绕刀刃持续攻击身边敌人。",
	},
	"archer": {
		"BASIC": "普攻 · 射箭\n向瞄准方向发射高速箭矢。",
		"DODGE": "闪避\n快速位移并短暂无敌；弓箭手拥有 2 次充能。",
		"SECONDARY": "右键 · 三连箭\n向瞄准方向扇形发射 3 支箭。",
		"Q": "Q · 蓄力箭\n按住蓄力、松开发射；满蓄时伤害最高并可穿透敌人。",
		"E": "E · 猎人标记\n标记瞄准方向的敌人，提高对该目标造成的伤害。",
		"F": "F · 箭雨\n在目标区域持续落箭，重复攻击范围内敌人。",
	},
	"lancer": {
		"BASIC": "普攻 · 枪刺\n前方长距离近战攻击；释放技能后会暂时加快普攻。",
		"DODGE": "闪避\n快速位移并短暂无敌。",
		"SECONDARY": "右键 · 双向横扫\n同时横扫瞄准方向与身后，同一敌人只受一次伤害。",
		"Q": "Q · 广域横扫\n对前方大范围敌人造成伤害和轻微击退。",
		"E": "E · 突进回旋\n向目标方向突进，并在落点造成环形伤害。",
		"F": "F · 回旋风暴\n生成跟随自身的持续枪阵，周期横扫附近敌人。",
	},
	"mage": {
		"BASIC": "普攻 · 奥术法球\n向瞄准方向发射远程单体法球。",
		"DODGE": "闪避\n快速位移并短暂无敌。",
		"SECONDARY": "右键 · 奥术震退\n伤害并击退附近普通敌人，同时使其减速。",
		"Q": "Q · 爆裂火球\n火球命中敌人或到达最远距离时产生范围爆炸。",
		"E": "E · 固定法阵\n在目标位置创建持续伤害与减速区域。",
		"F": "F · 元素风暴\n在大范围内持续伤害全部敌人，并眩晕首次命中的普通敌人。",
	},
}

static func get_character_config(character_id: String) -> Dictionary:
	var fallback: Dictionary = CHARACTER_CONFIGS["warrior"]
	return (CHARACTER_CONFIGS.get(character_id, fallback) as Dictionary).duplicate(true)

static func get_action_tooltip(character_id: String, action_key: String) -> String:
	var fallback: Dictionary = CHARACTER_ACTION_TOOLTIPS["warrior"]
	var tooltips: Dictionary = CHARACTER_ACTION_TOOLTIPS.get(character_id, fallback)
	return str(tooltips.get(action_key, action_key))

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
