extends RefCounted
class_name UpgradeCatalog

const POOL: Array = [
	{
		"id": "attack_damage",
		"title": "攻击力 +18%",
		"description": "普攻和连段造成更多伤害。",
		"stat": "attack_damage",
		"multiplier": 1.18,
		"rarity": "Common",
	},
	{
		"id": "max_health",
		"title": "最大生命 +22%",
		"description": "提高最大生命，并回复新增的生命值。",
		"stat": "max_health",
		"multiplier": 1.22,
		"rarity": "Common",
	},
	{
		"id": "move_speed",
		"title": "移动速度 +10%",
		"description": "移动更快，更容易调整站位。",
		"stat": "move_speed",
		"multiplier": 1.10,
		"rarity": "Common",
	},
	{
		"id": "attack_cooldown",
		"title": "普攻冷却 -14%",
		"description": "普攻恢复得更快。",
		"stat": "attack_cooldown",
		"multiplier": 0.86,
		"rarity": "Rare",
	},
	{
		"id": "attack_range",
		"title": "普攻范围 +15%",
		"description": "普攻可以打到更远的敌人。",
		"stat": "attack_range",
		"multiplier": 1.15,
		"rarity": "Rare",
	},
	{
		"id": "knockback",
		"title": "击退 +25%",
		"description": "攻击和技能会把敌人推得更远。",
		"stat": "knockback",
		"multiplier": 1.25,
		"rarity": "Rare",
	},
	{
		"id": "crit_chance",
		"title": "暴击率 +8%",
		"description": "攻击有概率造成额外伤害。",
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
		"id": "skill_damage",
		"title": "冲击波伤害 +22%",
		"description": "Q 技能造成更多伤害，E 技能也获得少量提升。",
		"stat": "skill_damage",
		"multiplier": 1.22,
		"rarity": "Rare",
	},
	{
		"id": "skill_cooldown",
		"title": "冲击波冷却 -16%",
		"description": "Q 技能恢复得更快。",
		"stat": "skill_cooldown",
		"multiplier": 0.84,
		"rarity": "Epic",
	},
	{
		"id": "skill_range",
		"title": "冲击波范围 +18%",
		"description": "Q 技能飞得更远，E 技能也获得少量范围提升。",
		"stat": "skill_range",
		"multiplier": 1.18,
		"rarity": "Rare",
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

static func roll(count: int = 3) -> Array:
	var weighted_choices: Array = []
	for upgrade in POOL:
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
	var used_ids: Dictionary = {}
	for upgrade in weighted_choices:
		var id: String = str(upgrade["id"])
		if used_ids.has(id):
			continue
		used_ids[id] = true
		result.append(upgrade)
		if result.size() >= count:
			break
	return result
