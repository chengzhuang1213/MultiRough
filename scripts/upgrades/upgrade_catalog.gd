extends RefCounted
class_name UpgradeCatalog

const GENERAL_POOL: Array = [
	{"id": "attack_damage_common", "title": "一般·力量训练", "description": "普通攻击伤害提高 10%。", "stat": "attack_damage", "amount": 0.10, "rarity": "Common", "max_level": 1},
	{"id": "attack_damage_rare", "title": "稀有·战斗专精", "description": "普通攻击伤害提高 16%。", "stat": "attack_damage", "amount": 0.16, "rarity": "Rare", "max_level": 1},
	{"id": "attack_damage_epic", "title": "史诗·毁灭之力", "description": "普通攻击伤害提高 25%。", "stat": "attack_damage", "amount": 0.25, "rarity": "Epic", "max_level": 1},
	{"id": "attack_cooldown_common", "title": "一般·快速出手", "description": "普通攻击冷却缩短 7%。", "stat": "attack_cooldown", "amount": 0.07, "rarity": "Common", "max_level": 1},
	{"id": "attack_cooldown_rare", "title": "稀有·连贯攻势", "description": "普通攻击冷却缩短 11%。", "stat": "attack_cooldown", "amount": 0.11, "rarity": "Rare", "max_level": 1},
	{"id": "attack_cooldown_epic", "title": "史诗·无尽猛攻", "description": "普通攻击冷却缩短 17%。", "stat": "attack_cooldown", "amount": 0.17, "rarity": "Epic", "max_level": 1},
	{"id": "attack_range_common", "title": "一般·延伸打击", "description": "普通攻击范围提高 10%。", "stat": "attack_range", "amount": 0.10, "rarity": "Common", "max_level": 1},
	{"id": "attack_range_rare", "title": "稀有·精准距离", "description": "普通攻击范围提高 16%。", "stat": "attack_range", "amount": 0.16, "rarity": "Rare", "max_level": 1},
	{"id": "attack_range_epic", "title": "史诗·绝对射程", "description": "普通攻击范围提高 25%。", "stat": "attack_range", "amount": 0.25, "rarity": "Epic", "max_level": 1},
	{"id": "max_health_common", "title": "一般·强健体魄", "description": "最大生命提高 12%，并回复新增生命。", "stat": "max_health", "amount": 0.12, "rarity": "Common", "max_level": 1},
	{"id": "max_health_rare", "title": "稀有·坚韧生命", "description": "最大生命提高 20%，并回复新增生命。", "stat": "max_health", "amount": 0.20, "rarity": "Rare", "max_level": 1},
	{"id": "max_health_epic", "title": "史诗·不灭之躯", "description": "最大生命提高 32%，并回复新增生命。", "stat": "max_health", "amount": 0.32, "rarity": "Epic", "max_level": 1},
	{"id": "move_speed_common", "title": "一般·轻快步伐", "description": "移动速度提高 5%。", "stat": "move_speed", "amount": 0.05, "rarity": "Common", "max_level": 1},
	{"id": "move_speed_rare", "title": "稀有·迅捷身法", "description": "移动速度提高 8%。", "stat": "move_speed", "amount": 0.08, "rarity": "Rare", "max_level": 1},
	{"id": "move_speed_epic", "title": "史诗·疾风行者", "description": "移动速度提高 12%。", "stat": "move_speed", "amount": 0.12, "rarity": "Epic", "max_level": 1},
	{"id": "knockback_common", "title": "一般·冲击训练", "description": "击退力量提高 15%。", "stat": "knockback", "amount": 0.15, "rarity": "Common", "max_level": 1},
	{"id": "knockback_rare", "title": "稀有·强力震退", "description": "击退力量提高 25%。", "stat": "knockback", "amount": 0.25, "rarity": "Rare", "max_level": 1},
	{"id": "knockback_epic", "title": "史诗·不可阻挡", "description": "击退力量提高 40%。", "stat": "knockback", "amount": 0.40, "rarity": "Epic", "max_level": 1},
	{"id": "crit_chance_common", "title": "一般·弱点观察", "description": "暴击率提高 5%。", "stat": "crit_chance", "amount": 0.05, "rarity": "Common", "max_level": 1},
	{"id": "crit_chance_rare", "title": "稀有·致命精准", "description": "暴击率提高 9%。", "stat": "crit_chance", "amount": 0.09, "rarity": "Rare", "max_level": 1},
	{"id": "crit_chance_epic", "title": "史诗·必杀本能", "description": "暴击率提高 15%。", "stat": "crit_chance", "amount": 0.15, "rarity": "Epic", "max_level": 1},
	{"id": "lifesteal_common", "title": "一般·生命汲取", "description": "获得 1% 吸血。", "stat": "lifesteal", "amount": 0.01, "rarity": "Common", "max_level": 1},
	{"id": "lifesteal_rare", "title": "稀有·鲜血回响", "description": "获得 2% 吸血。", "stat": "lifesteal", "amount": 0.02, "rarity": "Rare", "max_level": 1},
	{"id": "lifesteal_epic", "title": "史诗·生命掠夺", "description": "获得 4% 吸血。", "stat": "lifesteal", "amount": 0.04, "rarity": "Epic", "max_level": 1},
	{"id": "skill_cooldown_common", "title": "一般·技能调息", "description": "Q、E、F 冷却缩短 6%。", "stat": "skill_cooldown", "amount": 0.06, "rarity": "Common", "max_level": 1},
	{"id": "skill_cooldown_rare", "title": "稀有·能量循环", "description": "Q、E、F 冷却缩短 10%。", "stat": "skill_cooldown", "amount": 0.10, "rarity": "Rare", "max_level": 1},
	{"id": "skill_cooldown_epic", "title": "史诗·无限施法", "description": "Q、E、F 冷却缩短 16%。", "stat": "skill_cooldown", "amount": 0.16, "rarity": "Epic", "max_level": 1},
]

const SKILL_POOL: Array = [
]

const BEHAVIOR_POOL: Array = [
	{"id": "warrior_q_damage", "title": "战士 Q · 战吼增幅", "description": "战吼伤害提高 25%。", "stat": "behavior_upgrade", "rarity": "Common", "skill_slot": "Q", "character_id": "warrior", "max_level": 1},
	{"id": "warrior_q_range", "title": "战士 Q · 扩音战吼", "description": "战吼的伤害、牵引与嘲讽范围扩大 20%。", "stat": "behavior_upgrade", "rarity": "Common", "skill_slot": "Q", "character_id": "warrior", "max_level": 1},
	{"id": "warrior_e_counter", "title": "战士 E · 坚守反击", "description": "保留移动防御姿态，反伤倍率从 130% 提高到 170%。", "stat": "behavior_upgrade", "rarity": "Common", "skill_slot": "E", "character_id": "warrior", "max_level": 1, "excludes": ["warrior_e_shield", "warrior_e_shield_guard"]},
	{"id": "warrior_e_shield", "title": "战士 E · 盾影投掷", "description": "E 改为投出往返盾影，伤害路径上的敌人。", "stat": "behavior_upgrade", "rarity": "Common", "skill_slot": "E", "character_id": "warrior", "max_level": 1, "excludes": ["warrior_e_counter", "warrior_e_perfect_guard"]},
	{"id": "warrior_e_perfect_guard", "title": "战士 E · 完美格挡", "description": "反击姿态中周期性完全抵消一次伤害并震击附近敌人。", "stat": "behavior_upgrade", "rarity": "Rare", "skill_slot": "E", "character_id": "warrior", "max_level": 1, "requires": "warrior_e_counter", "excludes": ["warrior_e_shield", "warrior_e_shield_guard"]},
	{"id": "warrior_e_shield_guard", "title": "战士 E · 回盾护体", "description": "盾影命中过敌人后，返回时提供 2 秒伤害减免。", "stat": "behavior_upgrade", "rarity": "Rare", "skill_slot": "E", "character_id": "warrior", "max_level": 1, "requires": "warrior_e_shield", "excludes": ["warrior_e_counter", "warrior_e_perfect_guard"]},
	{"id": "warrior_f_extra_blade", "title": "战士 F · 锋刃扩充", "description": "环绕刀刃增加 1 把。", "stat": "behavior_upgrade", "rarity": "Common", "skill_slot": "F", "character_id": "warrior", "max_level": 1},
	{"id": "warrior_f_projectile_guard", "title": "战士 F · 兵刃防线", "description": "环绕刀刃可以摧毁敌方投射物。", "stat": "behavior_upgrade", "rarity": "Rare", "skill_slot": "F", "character_id": "warrior", "max_level": 1},
	{"id": "warrior_f_attack_defense", "title": "战士 F · 攻守一体", "description": "大招期间减伤 25%；防御时刀刃旋转速度提高。", "stat": "behavior_upgrade", "rarity": "Epic", "skill_slot": "F", "character_id": "warrior", "max_level": 1},
	{"id": "archer_q_damage", "title": "弓箭手 Q · 强力蓄射", "description": "蓄力箭伤害提高 25%。", "stat": "behavior_upgrade", "rarity": "Common", "skill_slot": "Q", "character_id": "archer", "max_level": 1},
	{"id": "archer_q_quickdraw", "title": "弓箭手 Q · 快速蓄力", "description": "最大蓄力时间缩短 20%，完整伤害保持不变。", "stat": "behavior_upgrade", "rarity": "Common", "skill_slot": "Q", "character_id": "archer", "max_level": 1},
	{"id": "archer_e_mark", "title": "弓箭手 E · 强化标记", "description": "标记延长到 12 秒，对标记目标的增伤提高到 70%。", "stat": "behavior_upgrade", "rarity": "Common", "skill_slot": "E", "character_id": "archer", "max_level": 1, "excludes": ["archer_e_trap", "archer_e_execution_trap"]},
	{"id": "archer_e_trap", "title": "弓箭手 E · 猎人陷阱", "description": "E 改为后撤并留下陷阱，定身第一个触发的普通敌人。", "stat": "behavior_upgrade", "rarity": "Common", "skill_slot": "E", "character_id": "archer", "max_level": 1, "excludes": ["archer_e_mark", "archer_e_mark_transfer"]},
	{"id": "archer_e_mark_transfer", "title": "弓箭手 E · 追猎转移", "description": "标记目标死亡后，标记转移到附近生命最高的敌人。", "stat": "behavior_upgrade", "rarity": "Rare", "skill_slot": "E", "character_id": "archer", "max_level": 1, "requires": "archer_e_mark", "excludes": ["archer_e_trap", "archer_e_execution_trap"]},
	{"id": "archer_e_execution_trap", "title": "弓箭手 E · 处决陷阱", "description": "触发陷阱的敌人受到的下一支箭必定暴击。", "stat": "behavior_upgrade", "rarity": "Rare", "skill_slot": "E", "character_id": "archer", "max_level": 1, "requires": "archer_e_trap", "excludes": ["archer_e_mark", "archer_e_mark_transfer"]},
	{"id": "archer_f_damage", "title": "弓箭手 F · 强化箭矢", "description": "箭雨伤害提高 25%。", "stat": "behavior_upgrade", "rarity": "Common", "skill_slot": "F", "character_id": "archer", "max_level": 1},
	{"id": "archer_f_critical", "title": "弓箭手 F · 致命箭雨", "description": "箭雨中的箭矢获得 25% 暴击率。", "stat": "behavior_upgrade", "rarity": "Rare", "skill_slot": "F", "character_id": "archer", "max_level": 1},
	{"id": "archer_f_weakpoint", "title": "弓箭手 F · 锁定弱点", "description": "连续命中同一目标时，后续箭矢伤害逐次提高。", "stat": "behavior_upgrade", "rarity": "Epic", "skill_slot": "F", "character_id": "archer", "max_level": 1},
	{"id": "mage_q_damage", "title": "法师 Q · 火球增幅", "description": "火球爆炸伤害提高 20%。", "stat": "behavior_upgrade", "rarity": "Common", "skill_slot": "Q", "character_id": "mage", "max_level": 1},
	{"id": "mage_q_radius", "title": "法师 Q · 爆炸扩张", "description": "火球爆炸范围扩大 20%。", "stat": "behavior_upgrade", "rarity": "Common", "skill_slot": "Q", "character_id": "mage", "max_level": 1},
	{"id": "mage_e_field", "title": "法师 E · 领域扩张", "description": "固定法阵范围扩大 25%，持续时间从 4 秒提高到 5 秒。", "stat": "behavior_upgrade", "rarity": "Common", "skill_slot": "E", "character_id": "mage", "max_level": 1, "excludes": ["mage_e_chain", "mage_e_conduction"]},
	{"id": "mage_e_chain", "title": "法师 E · 连锁奥术", "description": "E 改为瞬发连锁闪电，依次攻击最多 5 个不同敌人。", "stat": "behavior_upgrade", "rarity": "Common", "skill_slot": "E", "character_id": "mage", "max_level": 1, "excludes": ["mage_e_field", "mage_e_accumulation"]},
	{"id": "mage_e_accumulation", "title": "法师 E · 魔力积蓄", "description": "敌人在法阵内连续受击时，后续脉冲伤害逐渐提高。", "stat": "behavior_upgrade", "rarity": "Rare", "skill_slot": "E", "character_id": "mage", "max_level": 1, "requires": "mage_e_field", "excludes": ["mage_e_chain", "mage_e_conduction"]},
	{"id": "mage_e_conduction", "title": "法师 E · 无限传导", "description": "连锁上限提高到 8 个，扩大跳跃距离并取消伤害衰减。", "stat": "behavior_upgrade", "rarity": "Rare", "skill_slot": "E", "character_id": "mage", "max_level": 1, "requires": "mage_e_chain", "excludes": ["mage_e_field", "mage_e_accumulation"]},
	{"id": "mage_f_expansion", "title": "法师 F · 魔力扩张", "description": "风暴范围扩大 20%。", "stat": "behavior_upgrade", "rarity": "Common", "skill_slot": "F", "character_id": "mage", "max_level": 1},
	{"id": "mage_f_infusion", "title": "法师 F · 法力灌注", "description": "每次风暴打击伤害提高 30%。", "stat": "behavior_upgrade", "rarity": "Rare", "skill_slot": "F", "character_id": "mage", "max_level": 1},
	{"id": "mage_f_finisher", "title": "法师 F · 风暴终结", "description": "风暴结束时追加一次更大范围、更高伤害的爆发。", "stat": "behavior_upgrade", "rarity": "Epic", "skill_slot": "F", "character_id": "mage", "max_level": 1},
	{"id": "lancer_q_damage", "title": "长枪 Q · 强力横扫", "description": "横扫伤害提高 20%。", "stat": "behavior_upgrade", "rarity": "Common", "skill_slot": "Q", "character_id": "lancer", "max_level": 1},
	{"id": "lancer_q_range", "title": "长枪 Q · 广域横扫", "description": "横扫长度和宽度扩大 20%。", "stat": "behavior_upgrade", "rarity": "Common", "skill_slot": "Q", "character_id": "lancer", "max_level": 1},
	{"id": "lancer_e_charge", "title": "长枪 E · 无畏冲锋", "description": "突进距离提高 30%，突进时获得 0.35 秒无敌。", "stat": "behavior_upgrade", "rarity": "Common", "skill_slot": "E", "character_id": "lancer", "max_level": 1, "excludes": ["lancer_e_spear", "lancer_e_return"]},
	{"id": "lancer_e_spear", "title": "长枪 E · 贯穿枪影", "description": "E 改为投出直线枪影，贯穿路径上的全部敌人。", "stat": "behavior_upgrade", "rarity": "Common", "skill_slot": "E", "character_id": "lancer", "max_level": 1, "excludes": ["lancer_e_charge", "lancer_e_double_sweep"]},
	{"id": "lancer_e_double_sweep", "title": "长枪 E · 二重横扫", "description": "突进到落点后追加一次更大范围横扫。", "stat": "behavior_upgrade", "rarity": "Rare", "skill_slot": "E", "character_id": "lancer", "max_level": 1, "requires": "lancer_e_charge", "excludes": ["lancer_e_spear", "lancer_e_return"]},
	{"id": "lancer_e_return", "title": "长枪 E · 回锋", "description": "枪影到达最大距离后返回，再次伤害并轻微牵引普通敌人。", "stat": "behavior_upgrade", "rarity": "Rare", "skill_slot": "E", "character_id": "lancer", "max_level": 1, "requires": "lancer_e_spear", "excludes": ["lancer_e_charge", "lancer_e_double_sweep"]},
	{"id": "lancer_f_reach", "title": "长枪 F · 长柄优势", "description": "横扫范围扩大 20%。", "stat": "behavior_upgrade", "rarity": "Common", "skill_slot": "F", "character_id": "lancer", "max_level": 1},
	{"id": "lancer_f_pull", "title": "长枪 F · 回旋牵引", "description": "每次横扫将普通敌人拉向自身。", "stat": "behavior_upgrade", "rarity": "Rare", "skill_slot": "F", "character_id": "lancer", "max_level": 1},
	{"id": "lancer_f_finisher", "title": "长枪 F · 破阵终击", "description": "大招结束时发动一次大范围、高伤害横扫。", "stat": "behavior_upgrade", "rarity": "Epic", "skill_slot": "F", "character_id": "lancer", "max_level": 1},
]

static func get_by_id(upgrade_id: String) -> Dictionary:
	for pool in [GENERAL_POOL, SKILL_POOL, BEHAVIOR_POOL]:
		for upgrade in pool:
			if str((upgrade as Dictionary).get("id", "")) == upgrade_id:
				return (upgrade as Dictionary).duplicate(true)
	return {}

static func roll(count: int = 3, character_id: String = "", upgrade_levels: Dictionary = {}, rarity: String = "", offer_misses: Dictionary = {}) -> Array:
	var result: Array = []
	var used_ids: Dictionary = {}
	var profession_pool: Array = []
	profession_pool.append_array(SKILL_POOL)
	profession_pool.append_array(BEHAVIOR_POOL)
	for upgrade in _roll_from_pool(profession_pool, min(2, count), used_ids, character_id, upgrade_levels, rarity, offer_misses):
		result.append(upgrade)

	if result.size() < count:
		var mixed_pool: Array = []
		mixed_pool.append_array(GENERAL_POOL)
		mixed_pool.append_array(SKILL_POOL)
		mixed_pool.append_array(BEHAVIOR_POOL)
		for upgrade in _roll_from_pool(mixed_pool, count - result.size(), used_ids, character_id, upgrade_levels, rarity, offer_misses):
			result.append(upgrade)

	result.shuffle()
	return result

static func get_offer_weight_multiplier(miss_count: int) -> int:
	if miss_count == 1:
		return 2
	if miss_count >= 2:
		return 1
	return 4

static func _roll_from_pool(pool: Array, count: int, used_ids: Dictionary, character_id: String, upgrade_levels: Dictionary, required_rarity: String = "", offer_misses: Dictionary = {}) -> Array:
	var weighted_choices: Array = []
	for upgrade in pool:
		if not required_rarity.is_empty() and str(upgrade.get("rarity", "Common")) != required_rarity:
			continue
		var required_character := str(upgrade.get("character_id", ""))
		if not required_character.is_empty() and required_character != character_id:
			continue
		var max_level := int(upgrade.get("max_level", 0))
		if max_level > 0 and int(upgrade_levels.get(str(upgrade.get("id", "")), 0)) >= max_level:
			continue
		var requires := str(upgrade.get("requires", ""))
		if not requires.is_empty() and int(upgrade_levels.get(requires, 0)) <= 0:
			continue
		var excluded := false
		for excluded_id in upgrade.get("excludes", []):
			if int(upgrade_levels.get(str(excluded_id), 0)) > 0:
				excluded = true
				break
		if excluded:
			continue
		var rarity: String = str(upgrade.get("rarity", "Common"))
		var weight: int = 6
		if rarity == "Rare":
			weight = 3
		elif rarity == "Epic":
			weight = 1
		var miss_count := int(offer_misses.get(str(upgrade.get("id", "")), 0))
		weight *= get_offer_weight_multiplier(miss_count)
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
