extends RefCounted
class_name UpgradeCatalog

const GENERAL_POOL: Array = [
	{
		"id": "attack_damage",
		"title": "普攻伤害 +16%",
		"description": "基础攻击造成更多伤害。",
		"stat": "attack_damage",
		"multiplier": 1.16,
		"rarity": "Common",
	},
	{
		"id": "attack_cooldown",
		"title": "普攻冷却 -12%",
		"description": "基础攻击恢复得更快。",
		"stat": "attack_cooldown",
		"multiplier": 0.88,
		"rarity": "Rare",
	},
	{
		"id": "attack_range",
		"title": "普攻范围 +12%",
		"description": "基础攻击可以命中更远的敌人。",
		"stat": "attack_range",
		"multiplier": 1.12,
		"rarity": "Rare",
	},
	{
		"id": "max_health",
		"title": "最大生命 +20%",
		"description": "提高最大生命，并回复新增的生命值。",
		"stat": "max_health",
		"multiplier": 1.20,
		"rarity": "Common",
	},
	{
		"id": "move_speed",
		"title": "移动速度 +9%",
		"description": "移动更快，更容易调整站位。",
		"stat": "move_speed",
		"multiplier": 1.09,
		"rarity": "Common",
	},
	{
		"id": "knockback",
		"title": "击退 +20%",
		"description": "攻击和技能会把敌人推得更远。",
		"stat": "knockback",
		"multiplier": 1.20,
		"rarity": "Rare",
	},
	{
		"id": "crit_chance",
		"title": "暴击率 +8%",
		"description": "攻击和技能有概率造成额外伤害。",
		"stat": "crit_chance",
		"add": 0.08,
		"rarity": "Rare",
	},
	{
		"id": "lifesteal",
		"title": "吸血 +4%",
		"description": "根据造成的伤害回复少量生命。",
		"stat": "lifesteal",
		"add": 0.04,
		"rarity": "Epic",
	},
	{
		"id": "dash_charges",
		"title": "闪避次数 +1",
		"description": "获得一次额外闪避充能。",
		"stat": "dash_charges",
		"add": 1,
		"rarity": "Epic",
	},
]

const SKILL_POOL: Array = [
	{
		"id": "q_damage",
		"title": "Q 技能伤害 +20%",
		"description": "强化当前职业的 Q 技能伤害。",
		"stat": "skill_damage",
		"multiplier": 1.20,
		"rarity": "Rare",
		"skill_slot": "Q",
	},
	{
		"id": "q_range",
		"title": "Q 技能范围 +16%",
		"description": "强化当前职业的 Q 技能距离或覆盖范围。",
		"stat": "skill_range",
		"multiplier": 1.16,
		"rarity": "Rare",
		"skill_slot": "Q",
	},
	{
		"id": "q_cooldown",
		"title": "Q 技能冷却 -15%",
		"description": "Q 技能恢复得更快。",
		"stat": "skill_cooldown",
		"multiplier": 0.85,
		"rarity": "Epic",
		"skill_slot": "Q",
	},
	{
		"id": "e_damage",
		"title": "E 技能伤害 +20%",
		"description": "强化当前职业的 E 技能伤害。",
		"stat": "fan_skill_damage",
		"multiplier": 1.20,
		"rarity": "Rare",
		"skill_slot": "E",
	},
	{
		"id": "e_range",
		"title": "E 技能范围 +14%",
		"description": "强化当前职业的 E 技能距离或覆盖范围。",
		"stat": "fan_skill_range",
		"multiplier": 1.14,
		"rarity": "Rare",
		"skill_slot": "E",
	},
	{
		"id": "e_cooldown",
		"title": "E 技能冷却 -14%",
		"description": "E 技能恢复得更快。",
		"stat": "fan_skill_cooldown",
		"multiplier": 0.86,
		"rarity": "Epic",
		"skill_slot": "E",
	},
	{
		"id": "f_damage",
		"title": "F 大招伤害 +22%",
		"description": "强化当前职业的 F 大招伤害。",
		"stat": "ultimate_damage",
		"multiplier": 1.22,
		"rarity": "Rare",
		"skill_slot": "F",
	},
	{
		"id": "f_duration",
		"title": "F 大招持续 +18%",
		"description": "延长当前职业的 F 大招持续时间。",
		"stat": "ultimate_duration",
		"multiplier": 1.18,
		"rarity": "Epic",
		"skill_slot": "F",
	},
	{
		"id": "f_cooldown",
		"title": "F 大招冷却 -14%",
		"description": "F 大招恢复得更快。",
		"stat": "ultimate_cooldown",
		"multiplier": 0.86,
		"rarity": "Epic",
		"skill_slot": "F",
	},
]

static func roll(count: int = 3, character_id: String = "") -> Array:
	var result: Array = []
	var used_ids: Dictionary = {}
	if character_id == "mage":
		return _roll_from_pool(GENERAL_POOL, count, used_ids)

	for upgrade in _roll_from_pool(SKILL_POOL, min(2, count), used_ids):
		result.append(upgrade)

	if result.size() < count:
		var mixed_pool: Array = []
		mixed_pool.append_array(GENERAL_POOL)
		mixed_pool.append_array(SKILL_POOL)
		for upgrade in _roll_from_pool(mixed_pool, count - result.size(), used_ids):
			result.append(upgrade)

	result.shuffle()
	return result

static func _roll_from_pool(pool: Array, count: int, used_ids: Dictionary) -> Array:
	var weighted_choices: Array = []
	for upgrade in pool:
		var rarity: String = str(upgrade.get("rarity", "Common"))
		var weight: int = 6
		if rarity == "Rare":
			weight = 3
		elif rarity == "Epic":
			weight = 1
		for _index in range(weight):
			weighted_choices.append(upgrade)

	weighted_choices.shuffle()
	var result: Array = []
	for upgrade in weighted_choices:
		var id: String = str(upgrade["id"])
		if used_ids.has(id):
			continue
		used_ids[id] = true
		result.append(upgrade)
		if result.size() >= count:
			break
	return result
