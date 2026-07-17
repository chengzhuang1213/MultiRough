extends SceneTree

const GameRulesScript := preload("res://scripts/gameplay/game_rules.gd")
const WaveManagerScript := preload("res://scripts/gameplay/wave_manager.gd")
const UpgradeCatalogScript := preload("res://scripts/upgrades/upgrade_catalog.gd")
const UpgradeManagerScript := preload("res://scripts/upgrades/upgrade_manager.gd")
const UpgradeSessionScript := preload("res://scripts/upgrades/upgrade_session.gd")
const PlayerScript := preload("res://scripts/player/player_controller.gd")
const AuthorityContractScript := preload("res://scripts/network/authority_contract.gd")

var failures: Array[String] = []

func _init() -> void:
	_check_character_configs()
	_check_character_passives()
	_check_original_animation_sheets()
	_check_upgrade_application()
	_check_upgrade_rolls_are_unique()
	_check_general_upgrade_pool_and_rarity()
	_check_general_upgrade_totals()
	_check_behavior_upgrade_pool()
	_check_wave_progression()
	_check_multiplayer_scaling_and_revival()
	_check_wave_clear_healing()
	_check_cooldown_pause_boundary()
	_check_defense_hold_slowdown()
	_check_common_animation_states()
	_check_lancer_run_visual_scale()
	_check_warrior_level_one_ascension_aura()
	_check_archer_projectile_origin()
	_check_archer_charge_feedback()
	_check_combat_event_frame()
	_check_authority_snapshot_contract()
	if failures.is_empty():
		print("PASS: all logic checks")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)

func _check_character_configs() -> void:
	var errors: PackedStringArray = GameRulesScript.validate_character_configs()
	_expect(errors.is_empty(), "character configs are incomplete: %s" % ", ".join(errors))
	_expect(GameRulesScript.CHARACTER_ORDER.size() == 4, "expected exactly four configured characters")
	_expect(GameRulesScript.CHARACTER_ORDER.has("mage"), "mage is missing from character order")
	_expect(is_equal_approx(float(GameRulesScript.CHARACTER_CONFIGS["warrior"]["visual_scale"]), 0.49), "warrior visual scale changed")
	_expect(is_equal_approx(float(GameRulesScript.CHARACTER_CONFIGS["archer"]["visual_scale"]), 0.55), "archer visual scale changed")
	_expect(is_equal_approx(float(GameRulesScript.CHARACTER_CONFIGS["lancer"]["visual_scale"]), 0.55), "lancer visual scale changed")
	_expect(is_equal_approx(float(GameRulesScript.CHARACTER_CONFIGS["mage"]["visual_scale"]), 0.62), "mage visual scale changed")
	_expect(is_equal_approx(float(GameRulesScript.CHARACTER_CONFIGS["lancer"]["attack_range"]), 110.4), "lancer base attack range is not 15 percent above 96")
	_expect(is_equal_approx(float(GameRulesScript.CHARACTER_CONFIGS["warrior"]["defense_damage_multiplier"]), 0.30), "warrior passive defense multiplier is incorrect")
	_expect(int(GameRulesScript.CHARACTER_CONFIGS["archer"]["dash_max_charges"]) == 2, "archer passive does not grant two dash charges")
	_expect(is_equal_approx(GameRulesScript.NORMAL_WAVE_TIME_LIMIT, 120.0), "normal wave time limit is not 120 seconds")
	_expect(is_equal_approx(GameRulesScript.BOSS_WAVE_TIME_LIMIT, 180.0), "boss wave time limit is not 180 seconds")
	for character_id in GameRulesScript.CHARACTER_ORDER:
		for action_key in ["BASIC", "DODGE", "SECONDARY", "Q", "E", "F"]:
			_expect(GameRulesScript.get_action_tooltip(character_id, action_key).contains("\n"), "%s %s tooltip is missing its description" % [character_id, action_key])
	_check_mage_art_assets()

func _check_character_passives() -> void:
	var warrior = PlayerScript.new()
	warrior.apply_character_config(GameRulesScript.get_character_config("warrior"))
	warrior.is_defending = true
	var warrior_health: float = warrior.health
	warrior.apply_damage(10.0)
	_expect(is_equal_approx(warrior.health, warrior_health - 3.0), "warrior passive did not reduce defended damage to 30 percent")
	warrior.free()
	var archer = PlayerScript.new()
	archer.apply_character_config(GameRulesScript.get_character_config("archer"))
	_expect(archer.dash_max_charges == 2 and archer.dash_charges == 2, "archer did not start with two dash charges")
	archer.free()
	var lancer = PlayerScript.new()
	lancer.apply_character_config(GameRulesScript.get_character_config("lancer"))
	lancer.health -= 5.0
	var lancer_health: float = lancer.health
	lancer._tick_timers(30.0)
	_expect(is_equal_approx(lancer.health, lancer_health), "lancer retained the removed passive regeneration")
	lancer.activate_lancer_war_rhythm()
	_expect(is_equal_approx(lancer._lancer_war_rhythm_left, 3.0), "lancer war rhythm did not start for three seconds")
	_expect(is_equal_approx(lancer.get_current_attack_cooldown(), lancer.attack_cooldown * 0.70), "lancer war rhythm did not shorten basic attack cooldown by 30 percent")
	lancer._tick_timers(1.0)
	lancer.activate_lancer_war_rhythm()
	_expect(is_equal_approx(lancer._lancer_war_rhythm_left, 3.0), "lancer war rhythm stacked instead of refreshing its duration")
	lancer._tick_timers(3.0)
	_expect(is_equal_approx(lancer.get_current_attack_cooldown(), lancer.attack_cooldown), "lancer basic attack cooldown stayed shortened after war rhythm expired")
	lancer.free()

func _check_mage_art_assets() -> void:
	var paths := [
		"res://assets/original/characters/warrior/warrior_card_v4.png",
		"res://assets/original/characters/archer/archer_card_v2.png",
		"res://assets/original/characters/lancer/lancer_card_v2.png",
		"res://assets/original/characters/mage/mage_card_v2.png",
		"res://assets/ui/character_select/skills/warrior_q.png",
		"res://assets/ui/character_select/skills/warrior_e.png",
		"res://assets/ui/character_select/skills/warrior_f.png",
		"res://assets/ui/character_select/skills/archer_q.png",
		"res://assets/ui/character_select/skills/archer_e.png",
		"res://assets/ui/character_select/skills/archer_f.png",
		"res://assets/ui/character_select/skills/lancer_q.png",
		"res://assets/ui/character_select/skills/lancer_e.png",
		"res://assets/ui/character_select/skills/lancer_f.png",
		"res://assets/ui/character_select/skills/mage_q.png",
		"res://assets/ui/character_select/skills/mage_e.png",
		"res://assets/ui/character_select/skills/mage_f.png",
		"res://assets/ui/character_select/skills/warrior_basic.png",
		"res://assets/ui/character_select/skills/warrior_secondary.png",
		"res://assets/ui/character_select/skills/warrior_dodge.png",
		"res://assets/ui/character_select/skills/archer_basic.png",
		"res://assets/ui/character_select/skills/archer_secondary.png",
		"res://assets/ui/character_select/skills/archer_dodge.png",
		"res://assets/ui/character_select/skills/lancer_basic.png",
		"res://assets/ui/character_select/skills/lancer_secondary.png",
		"res://assets/ui/character_select/skills/lancer_dodge.png",
		"res://assets/ui/character_select/skills/mage_basic.png",
		"res://assets/ui/character_select/skills/mage_secondary.png",
		"res://assets/ui/character_select/skills/mage_dodge.png",
		"res://assets/effects/warrior/warrior_q_vfx.png",
		"res://assets/effects/warrior/warrior_e_vfx.png",
		"res://assets/effects/warrior/warrior_f_blade_vfx.png",
		"res://assets/original/characters/archer/archer_concept_v1.png",
		"res://assets/original/characters/archer/archer_pixel_master_v1.png",
		"res://assets/original/characters/archer/animations/archer_idle.png",
		"res://assets/original/characters/archer/animations/archer_run.png",
		"res://assets/original/characters/archer/animations/archer_attack_1.png",
		"res://assets/original/characters/archer/animations/archer_attack_2.png",
		"res://assets/original/characters/archer/animations/archer_cast.png",
		"res://assets/original/characters/archer/animations/archer_hit.png",
		"res://assets/original/characters/archer/animations/archer_death.png",
		"res://assets/original/characters/archer/animations/archer_dash.png",
		"res://assets/original/characters/archer/animations/archer_defend.png",
		"res://assets/original/characters/lancer/lancer_concept_v1.png",
		"res://assets/original/characters/lancer/animations/lancer_idle.png",
		"res://assets/original/characters/lancer/animations/lancer_run.png",
		"res://assets/original/characters/lancer/animations/lancer_attack_1.png",
		"res://assets/original/characters/lancer/animations/lancer_attack_2.png",
		"res://assets/original/characters/lancer/animations/lancer_cast.png",
		"res://assets/original/characters/lancer/animations/lancer_hit.png",
		"res://assets/original/characters/lancer/animations/lancer_death.png",
		"res://assets/original/characters/lancer/animations/lancer_dash.png",
		"res://assets/original/characters/lancer/animations/lancer_defend.png",
		"res://assets/original/characters/warrior/warrior_concept_v1.png",
		"res://assets/original/characters/warrior/animations/warrior_idle.png",
		"res://assets/original/characters/warrior/animations/warrior_run.png",
		"res://assets/original/characters/warrior/animations/warrior_attack_1.png",
		"res://assets/original/characters/warrior/animations/warrior_attack_2.png",
		"res://assets/original/characters/warrior/animations/warrior_cast.png",
		"res://assets/original/characters/warrior/animations/warrior_hit.png",
		"res://assets/original/characters/warrior/animations/warrior_death.png",
		"res://assets/original/characters/warrior/animations/warrior_dash.png",
		"res://assets/original/characters/warrior/animations/warrior_defend.png",
		"res://assets/original/characters/mage/mage_concept_v1.png",
		"res://assets/original/characters/mage/mage_basic_projectile.svg",
		"res://assets/original/characters/mage/animations/mage_idle.png",
		"res://assets/original/characters/mage/animations/mage_run.png",
		"res://assets/original/characters/mage/animations/mage_attack_1.png",
		"res://assets/original/characters/mage/animations/mage_attack_2.png",
		"res://assets/original/characters/mage/animations/mage_cast.png",
		"res://assets/original/characters/mage/animations/mage_hit.png",
		"res://assets/original/characters/mage/animations/mage_death.png",
		"res://assets/original/characters/mage/animations/mage_dash.png",
		"res://assets/original/characters/mage/animations/mage_defend.png",
	]
	for path in paths:
		_expect(ResourceLoader.exists(path), "original character art asset is missing: %s" % path)

func _check_original_animation_sheets() -> void:
	var frame_counts := {
		"idle": 6, "run": 6, "attack_1": 6, "attack_2": 6,
		"cast": 6, "hit": 3, "death": 6, "dash": 4, "defend": 4,
	}
	for character_id in ["warrior", "lancer", "archer", "mage"]:
		for animation_name in frame_counts:
			var path := "res://assets/original/characters/%s/animations/%s_%s.png" % [character_id, character_id, animation_name]
			var texture := load(path) as Texture2D
			_expect(texture != null, "animation sheet could not load: %s" % path)
			if texture == null:
				continue
			var expected_frames: int = int(frame_counts[animation_name])
			_expect(texture.get_width() == expected_frames * 192, "animation sheet width is invalid: %s" % path)
			_expect(texture.get_height() == 192, "animation sheet height is invalid: %s" % path)
			var image := texture.get_image()
			for frame_index in range(expected_frames):
				var has_pixels := false
				var bottom := -1
				for y in range(192):
					for x in range(frame_index * 192, (frame_index + 1) * 192):
						if image.get_pixel(x, y).a > 0.01:
							has_pixels = true
							bottom = y
				_expect(has_pixels, "%s frame %d is empty" % [path, frame_index])
				_expect(bottom <= 138, "%s frame %d exceeds foot baseline" % [path, frame_index])

func _check_upgrade_application() -> void:
	var player = PlayerScript.new()
	player.apply_character_config(GameRulesScript.get_character_config("warrior"))
	var base_damage: float = player.attack_damage
	player.apply_upgrade({"stat": "attack_damage", "multiplier": 1.16})
	_expect(is_equal_approx(player.attack_damage, base_damage * 1.16), "attack damage upgrade was not applied")
	var base_health: float = player.max_health
	player.apply_upgrade({"stat": "max_health", "multiplier": 1.20})
	_expect(is_equal_approx(player.max_health, base_health * 1.20), "maximum health upgrade was not applied")
	_expect(is_equal_approx(player.health, player.max_health), "maximum health upgrade did not preserve full health")
	player.apply_upgrade({"id": "archer_q_quickdraw", "stat": "behavior_upgrade", "max_level": 1})
	_expect(player.get_upgrade_level("archer_q_quickdraw") == 1, "behavior upgrade level was not recorded")
	_expect(is_equal_approx(player.archer_charge_time_multiplier, 0.8), "archer quickdraw behavior was not applied")
	player.apply_upgrade({"id": "archer_q_quickdraw", "stat": "behavior_upgrade", "max_level": 1})
	_expect(player.get_upgrade_level("archer_q_quickdraw") == 1, "behavior upgrade exceeded its one-card limit")
	player.free()
	var stat_player = PlayerScript.new()
	stat_player.apply_character_config(GameRulesScript.get_character_config("warrior"))
	var stat_base_damage: float = stat_player.attack_damage
	var common_damage := _find_general_upgrade("attack_damage_common")
	var rare_damage := _find_general_upgrade("attack_damage_rare")
	stat_player.apply_upgrade(common_damage)
	stat_player.apply_upgrade(rare_damage)
	_expect(is_equal_approx(stat_player.attack_damage, stat_base_damage * 1.26), "general attack upgrades are not additive from the base value")
	stat_player.apply_upgrade(common_damage)
	_expect(is_equal_approx(stat_player.attack_damage, stat_base_damage * 1.26), "general upgrade could be acquired more than once")
	var base_q_cooldown: float = stat_player.skill_cooldown
	var base_e_cooldown: float = stat_player.fan_skill_cooldown
	var base_f_cooldown: float = stat_player.ultimate_cooldown
	stat_player.apply_upgrade(_find_general_upgrade("skill_cooldown_epic"))
	_expect(is_equal_approx(stat_player.skill_cooldown, base_q_cooldown * 0.84), "skill cooldown card did not reduce Q cooldown")
	_expect(is_equal_approx(stat_player.fan_skill_cooldown, base_e_cooldown * 0.84), "skill cooldown card did not reduce E cooldown")
	_expect(is_equal_approx(stat_player.ultimate_cooldown, base_f_cooldown * 0.84), "skill cooldown card did not reduce F cooldown")
	var offered := [
		{"id": "offer_selected"},
		{"id": "offer_skipped_one"},
		{"id": "offer_skipped_two"},
	]
	stat_player.record_upgrade_offer_result(offered, "offer_selected")
	_expect(not stat_player.upgrade_offer_misses.has("offer_selected"), "selected card was recorded as skipped")
	_expect(int(stat_player.upgrade_offer_misses.get("offer_skipped_one", 0)) == 1, "first skipped card was not recorded")
	_expect(int(stat_player.upgrade_offer_misses.get("offer_skipped_two", 0)) == 1, "second skipped card was not recorded")
	stat_player.record_upgrade_offer_result(offered, "offer_selected")
	_expect(int(stat_player.upgrade_offer_misses.get("offer_skipped_one", 0)) == 2, "repeated skipped card did not increment its history")
	stat_player.free()
	var branch_player = PlayerScript.new()
	branch_player.apply_character_config(GameRulesScript.get_character_config("warrior"))
	var counter_card := _find_behavior_upgrade("warrior_e_counter")
	var shield_card := _find_behavior_upgrade("warrior_e_shield")
	var perfect_guard_card := _find_behavior_upgrade("warrior_e_perfect_guard")
	branch_player.apply_upgrade(perfect_guard_card)
	_expect(branch_player.get_upgrade_level("warrior_e_perfect_guard") == 0, "rare E upgrade ignored its common prerequisite")
	branch_player.apply_upgrade(counter_card)
	branch_player.apply_upgrade(shield_card)
	_expect(branch_player.get_upgrade_level("warrior_e_shield") == 0, "player acquired both mutually exclusive E branches")
	branch_player.apply_upgrade(perfect_guard_card)
	_expect(branch_player.get_upgrade_level("warrior_e_perfect_guard") == 1, "selected E branch could not acquire its rare follow-up")
	branch_player.free()

func _find_behavior_upgrade(upgrade_id: String) -> Dictionary:
	for upgrade in UpgradeCatalogScript.BEHAVIOR_POOL:
		if str((upgrade as Dictionary).get("id", "")) == upgrade_id:
			return upgrade as Dictionary
	return {}

func _find_general_upgrade(upgrade_id: String) -> Dictionary:
	for upgrade in UpgradeCatalogScript.GENERAL_POOL:
		if str((upgrade as Dictionary).get("id", "")) == upgrade_id:
			return upgrade as Dictionary
	return {}

func _check_upgrade_rolls_are_unique() -> void:
	seed(90710)
	for character_id in GameRulesScript.CHARACTER_ORDER:
		for _iteration in range(100):
			var upgrades: Array = UpgradeCatalogScript.roll(3, character_id)
			_expect(upgrades.size() == 3, "%s upgrade roll returned the wrong count" % character_id)
			_expect(UpgradeManagerScript.has_unique_ids(upgrades), "%s upgrade roll contains duplicate ids" % character_id)
			if character_id == "mage":
				_expect(upgrades.any(func(upgrade): return (upgrade as Dictionary).has("skill_slot")), "mage did not receive a skill upgrade after Q/E/F were implemented")

func _check_general_upgrade_pool_and_rarity() -> void:
	_expect(UpgradeCatalogScript.GENERAL_POOL.size() == 27, "general pool does not contain nine stats at three rarities")
	var expected_stats := ["attack_damage", "attack_cooldown", "attack_range", "max_health", "move_speed", "knockback", "crit_chance", "lifesteal", "skill_cooldown"]
	for stat in expected_stats:
		var cards := UpgradeCatalogScript.GENERAL_POOL.filter(func(upgrade): return str((upgrade as Dictionary).get("stat", "")) == stat)
		_expect(cards.size() == 3, "%s does not have three general rarity cards" % stat)
		var rarities := cards.map(func(upgrade): return str((upgrade as Dictionary).get("rarity", "")))
		_expect(rarities.count("Common") == 1 and rarities.count("Rare") == 1 and rarities.count("Epic") == 1, "%s general cards do not cover all rarities" % stat)
		for card in cards:
			_expect(int((card as Dictionary).get("max_level", 0)) == 1, "%s general card is not limited to one acquisition" % stat)
	_expect(is_equal_approx(UpgradeManagerScript.COMMON_RARITY_CHANCE + UpgradeManagerScript.RARE_RARITY_CHANCE + UpgradeManagerScript.EPIC_RARITY_CHANCE, 1.0), "upgrade rarity chances do not total 100 percent")
	_expect(UpgradeManagerScript.roll_rarity(true) == "Epic", "forced final-round epic guarantee failed")
	_expect(UpgradeManagerScript.roll_rarity(false, ["Common", "Rare"]) == "Epic", "rarity reroll did not skip exhausted pools")
	_expect(UpgradeCatalogScript.get_offer_weight_multiplier(0) == 4, "new card offer weight is incorrect")
	_expect(UpgradeCatalogScript.get_offer_weight_multiplier(1) == 2, "once-skipped card is not reduced to 50 percent weight")
	_expect(UpgradeCatalogScript.get_offer_weight_multiplier(2) == 1, "twice-skipped card is not reduced to 25 percent weight")
	_expect(UpgradeCatalogScript.get_offer_weight_multiplier(5) == 1, "skipped card weight fell below the 25 percent floor")
	seed(260713)
	var rarity_counts := {"Common": 0, "Rare": 0, "Epic": 0}
	for _index in range(2000):
		var rolled_rarity := UpgradeManagerScript.roll_rarity()
		rarity_counts[rolled_rarity] = int(rarity_counts.get(rolled_rarity, 0)) + 1
	_expect(absf(float(rarity_counts["Common"]) / 2000.0 - 0.50) < 0.05, "common rarity roll rate drifted too far from 50 percent")
	_expect(absf(float(rarity_counts["Rare"]) / 2000.0 - 0.35) < 0.05, "rare rarity roll rate drifted too far from 35 percent")
	_expect(absf(float(rarity_counts["Epic"]) / 2000.0 - 0.15) < 0.04, "epic rarity roll rate drifted too far from 15 percent")
	for rarity in ["Common", "Rare", "Epic"]:
		for character_id in GameRulesScript.CHARACTER_ORDER:
			var upgrades := UpgradeCatalogScript.roll(3, character_id, {}, rarity)
			_expect(upgrades.size() == 3, "%s %s roll did not return three cards" % [character_id, rarity])
			for upgrade in upgrades:
				_expect(str((upgrade as Dictionary).get("rarity", "")) == rarity, "%s roll mixed upgrade rarities" % rarity)

func _check_general_upgrade_totals() -> void:
	var player = PlayerScript.new()
	player.apply_character_config(GameRulesScript.get_character_config("warrior"))
	var base_damage: float = player.attack_damage
	var base_attack_cooldown: float = player.attack_cooldown
	var base_range: float = player.attack_range
	var base_health: float = player.max_health
	var base_speed: float = player.move_speed
	var base_knockback: float = player.attack_knockback
	var base_q_cooldown: float = player.skill_cooldown
	var base_e_cooldown: float = player.fan_skill_cooldown
	var base_f_cooldown: float = player.ultimate_cooldown
	for upgrade in UpgradeCatalogScript.GENERAL_POOL:
		player.apply_upgrade(upgrade as Dictionary)
	_expect(is_equal_approx(player.attack_damage, base_damage * 1.51), "all attack damage rarities do not total 51 percent")
	_expect(is_equal_approx(player.attack_cooldown, base_attack_cooldown * 0.65), "all attack cooldown rarities do not total 35 percent")
	_expect(is_equal_approx(player.attack_range, base_range * 1.51), "all attack range rarities do not total 51 percent")
	_expect(is_equal_approx(player.max_health, base_health * 1.64), "all maximum health rarities do not total 64 percent")
	_expect(is_equal_approx(player.move_speed, base_speed * 1.25), "all movement speed rarities do not total 25 percent")
	_expect(is_equal_approx(player.attack_knockback, base_knockback * 1.80), "all knockback rarities do not total 80 percent")
	_expect(is_equal_approx(player.crit_chance, 0.29), "all critical chance rarities do not total 29 percent")
	_expect(is_equal_approx(player.lifesteal_ratio, 0.07), "all lifesteal rarities do not total 7 percent")
	_expect(is_equal_approx(player.skill_cooldown, base_q_cooldown * 0.68), "all skill cooldown rarities do not reduce Q by 32 percent")
	_expect(is_equal_approx(player.fan_skill_cooldown, base_e_cooldown * 0.68), "all skill cooldown rarities do not reduce E by 32 percent")
	_expect(is_equal_approx(player.ultimate_cooldown, base_f_cooldown * 0.68), "all skill cooldown rarities do not reduce F by 32 percent")
	player.free()

func _check_behavior_upgrade_pool() -> void:
	_expect(UpgradeCatalogScript.BEHAVIOR_POOL.size() == 36, "behavior pool does not contain eight Q cards, sixteen E cards, and twelve F cards")
	_expect(not UpgradeCatalogScript.SKILL_POOL.any(func(upgrade): return str((upgrade as Dictionary).get("skill_slot", "")) == "Q"), "generic Q upgrades still exist beside the profession cards")
	_expect(not UpgradeCatalogScript.SKILL_POOL.any(func(upgrade): return str((upgrade as Dictionary).get("skill_slot", "")) == "E"), "generic E upgrades still exist beside the profession cards")
	for character_id in ["warrior", "archer", "mage", "lancer"]:
		var owned := {}
		var q_upgrades: Array = []
		var e_upgrades: Array = []
		var ultimate_upgrades: Array = []
		for upgrade in UpgradeCatalogScript.BEHAVIOR_POOL:
			if str((upgrade as Dictionary).get("character_id", "")) == character_id:
				owned[str((upgrade as Dictionary).get("id", ""))] = int((upgrade as Dictionary).get("max_level", 1))
				var skill_slot := str((upgrade as Dictionary).get("skill_slot", ""))
				if skill_slot == "Q":
					q_upgrades.append(upgrade)
				elif skill_slot == "E":
					e_upgrades.append(upgrade)
				elif skill_slot == "F":
					ultimate_upgrades.append(upgrade)
		_expect(q_upgrades.size() == 2, "%s does not have exactly two Q upgrades" % character_id)
		for upgrade in q_upgrades:
			_expect(str((upgrade as Dictionary).get("rarity", "")) == "Common", "%s Q upgrade is not common quality" % character_id)
			_expect(not (upgrade as Dictionary).has("requires"), "%s Q upgrade unexpectedly has a prerequisite" % character_id)
		_expect(e_upgrades.size() == 4, "%s does not have two complete E branches" % character_id)
		var e_rarities: Array = e_upgrades.map(func(upgrade): return str((upgrade as Dictionary).get("rarity", "")))
		_expect(e_rarities.count("Common") == 2, "%s E does not have two common branch choices" % character_id)
		_expect(e_rarities.count("Rare") == 2, "%s E does not have two rare follow-ups" % character_id)
		for upgrade in e_upgrades:
			var rarity := str((upgrade as Dictionary).get("rarity", ""))
			_expect((upgrade as Dictionary).has("excludes"), "%s E upgrade is missing branch exclusions" % character_id)
			if rarity == "Rare":
				_expect(not str((upgrade as Dictionary).get("requires", "")).is_empty(), "%s rare E upgrade is missing its common prerequisite" % character_id)
			else:
				_expect(not (upgrade as Dictionary).has("requires"), "%s common E branch unexpectedly has a prerequisite" % character_id)
		var common_one := e_upgrades.filter(func(upgrade): return str((upgrade as Dictionary).get("rarity", "")) == "Common")[0] as Dictionary
		var branch_one_owned := {str(common_one.get("id", "")): 1}
		var eligible := UpgradeCatalogScript.roll(100, character_id, branch_one_owned)
		var eligible_ids: Array = eligible.map(func(upgrade): return str((upgrade as Dictionary).get("id", "")))
		_expect(eligible_ids.has(str(e_upgrades.filter(func(upgrade): return str((upgrade as Dictionary).get("requires", "")) == str(common_one.get("id", "")))[0].get("id", ""))), "%s selected E branch did not unlock its rare follow-up" % character_id)
		for excluded_id in common_one.get("excludes", []):
			_expect(not eligible_ids.has(str(excluded_id)), "%s selected E branch still rolled the opposite branch" % character_id)
		_expect(ultimate_upgrades.size() == 3, "%s does not have exactly three independent ultimate upgrades" % character_id)
		var rarities: Array = ultimate_upgrades.map(func(upgrade): return str((upgrade as Dictionary).get("rarity", "")))
		_expect(rarities.count("Common") == 1, "%s ultimate is missing its common upgrade" % character_id)
		_expect(rarities.count("Rare") == 1, "%s ultimate is missing its rare upgrade" % character_id)
		_expect(rarities.count("Epic") == 1, "%s ultimate is missing its epic upgrade" % character_id)
		for upgrade in ultimate_upgrades:
			_expect(not (upgrade as Dictionary).has("requires"), "%s ultimate upgrade unexpectedly has a prerequisite" % character_id)
		var upgrades := UpgradeCatalogScript.roll(30, character_id, owned)
		for upgrade in upgrades:
			var required_character := str((upgrade as Dictionary).get("character_id", ""))
			_expect(required_character.is_empty() or required_character == character_id, "%s rolled another character's behavior upgrade" % character_id)
			_expect(not owned.has(str((upgrade as Dictionary).get("id", ""))), "%s rolled a behavior upgrade already at max level" % character_id)

func _check_wave_progression() -> void:
	var manager = WaveManagerScript.new()
	var boss_seen := false
	for expected_index in range(manager.wave_count()):
		var result: Dictionary = manager.advance()
		_expect(not bool(result["complete"]), "wave progression completed too early")
		_expect(int(result["index"]) == expected_index, "wave progression skipped an index")
		if bool((result["definition"] as Dictionary).get("boss", false)):
			boss_seen = true
			_expect(expected_index == manager.boss_wave_index(), "boss appeared at an unexpected wave")
		if expected_index == 4:
			_expect(bool((result["definition"] as Dictionary).get("mini_boss", false)), "wave five is not the mid-run mini-boss")
			_expect(manager.is_post_midboss_upgrade(), "wave five did not activate the post-midboss rarity rule")
	_expect(boss_seen, "wave progression never reached a boss")
	_expect(bool(manager.advance()["complete"]), "wave progression did not complete after the boss")
	for _index in range(100):
		_expect(UpgradeManagerScript.roll_rarity(false, ["Common"]) != "Common", "post-midboss rarity roll returned a common card")
	var final_player = PlayerScript.new()
	final_player.apply_character_config(GameRulesScript.get_character_config("mage"))
	var forced_final_roll: Dictionary = UpgradeSessionScript.roll_sets([final_player], true, ["Common"])
	_expect(str(forced_final_roll.get("rarity", "")) == "Epic", "final upgrade stopped forcing epic after common cards were excluded")
	final_player.free()

func _check_multiplayer_scaling_and_revival() -> void:
	var single: Dictionary = GameRulesScript.get_mode_scaling(1)
	var duo: Dictionary = GameRulesScript.get_mode_scaling(2)
	_expect(is_equal_approx(float(single["enemy_health"]), 1.0), "single-player enemy health scaling changed")
	_expect(is_equal_approx(float(duo["minion_count"]), 2.0), "duo minion count scaling is incorrect")
	_expect(is_equal_approx(float(duo["boss_health"]), 2.0), "duo boss health scaling is incorrect")
	var player = PlayerScript.new()
	player.apply_character_config(GameRulesScript.get_character_config("lancer"))
	player.apply_damage(player.max_health * 2.0)
	_expect(player.is_dead, "lethal damage did not kill the player")
	player.revive(GameRulesScript.REVIVE_HEALTH_RATIO)
	_expect(not player.is_dead, "revive did not restore the player")
	_expect(is_equal_approx(player.health, player.max_health * GameRulesScript.REVIVE_HEALTH_RATIO), "revive health ratio is incorrect")
	player.free()

func _check_wave_clear_healing() -> void:
	var player = PlayerScript.new()
	player.apply_character_config(GameRulesScript.get_character_config("warrior"))
	player.apply_damage(35.0)
	var expected_health: float = minf(player.max_health, player.health + GameRulesScript.WAVE_CLEAR_HEAL_AMOUNT)
	player.heal(GameRulesScript.WAVE_CLEAR_HEAL_AMOUNT)
	_expect(is_equal_approx(player.health, expected_health), "wave-clear healing amount is incorrect")
	player.heal(player.max_health * 2.0)
	_expect(is_equal_approx(player.health, player.max_health), "healing exceeded maximum health")
	player.free()

func _check_cooldown_pause_boundary() -> void:
	var player = PlayerScript.new()
	player._attack_timer = 1.0
	player._skill_timer = 2.0
	player.cooldowns_paused = true
	player._tick_timers(0.5)
	_expect(is_equal_approx(player._attack_timer, 1.0), "paused attack cooldown continued ticking")
	_expect(is_equal_approx(player._skill_timer, 2.0), "paused skill cooldown continued ticking")
	player.cooldowns_paused = false
	player._tick_timers(0.5)
	_expect(is_equal_approx(player._attack_timer, 0.5), "active attack cooldown did not tick")
	_expect(is_equal_approx(player._skill_timer, 1.5), "active skill cooldown did not tick")
	player.free()

func _check_defense_hold_slowdown() -> void:
	var player = PlayerScript.new()
	player.is_defending = true
	player._defend_hold_time = PlayerScript.DEFEND_TAP_GRACE
	_expect(is_equal_approx(player._get_defense_move_multiplier(), 1.0), "tapping defend unexpectedly slowed movement")
	player._defend_hold_time = (PlayerScript.DEFEND_TAP_GRACE + PlayerScript.DEFEND_FULL_STOP_TIME) * 0.5
	var partial_multiplier: float = player._get_defense_move_multiplier()
	_expect(partial_multiplier > 0.0 and partial_multiplier < 1.0, "holding defend did not gradually slow movement")
	player._defend_hold_time = PlayerScript.DEFEND_FULL_STOP_TIME
	_expect(is_zero_approx(player._get_defense_move_multiplier()), "holding defend did not stop movement")
	player.is_defending = false
	_expect(is_equal_approx(player._get_defense_move_multiplier(), 1.0), "releasing defend did not restore movement")
	player.free()

func _check_common_animation_states() -> void:
	for character_id in GameRulesScript.CHARACTER_ORDER:
		var player = PlayerScript.new()
		player.apply_character_config(GameRulesScript.get_character_config(character_id))
		player._setup_nodes()
		player.apply_damage(1.0)
		_expect(player._current_anim == "hit", "%s did not enter the shared hit animation" % character_id)
		player.apply_damage(player.max_health * 2.0)
		_expect(player._current_anim == "death", "%s did not enter the shared death animation" % character_id)
		_expect(player.visible, "%s death animation was hidden before it could play" % character_id)
		player.revive()
		_expect(player._current_anim == "idle", "%s did not return to idle after revival" % character_id)
		player._start_cast_animation()
		_expect(player._current_anim == "cast", "%s did not enter the shared cast animation" % character_id)
		player.free()

func _check_lancer_run_visual_scale() -> void:
	var player = PlayerScript.new()
	player.apply_character_config(GameRulesScript.get_character_config("lancer"))
	player._setup_nodes()
	player._play_animation("idle", true)
	var idle_scale: float = player._sprite.scale.y
	var idle_foot_y: float = player._sprite.position.y + 42.0 * idle_scale
	player._play_animation("run", true)
	var run_scale: float = player._sprite.scale.y
	var run_foot_y: float = player._sprite.position.y + 42.0 * run_scale
	_expect(is_equal_approx(run_scale, idle_scale * 1.24), "lancer run animation did not receive its size correction")
	_expect(is_equal_approx(run_foot_y, idle_foot_y), "lancer run size correction shifted the foot baseline")
	player.free()

func _check_archer_projectile_origin() -> void:
	var player = PlayerScript.new()
	player.apply_character_config(GameRulesScript.get_character_config("archer"))
	player.global_position = Vector2(100.0, 100.0)
	var origin := player.get_projectile_origin(Vector2.RIGHT)
	_expect(origin.x > player.global_position.x, "archer projectile did not start in front of the bow")
	_expect(origin.y < player.global_position.y, "archer projectile origin did not include the bow-center vertical offset")
	player.free()

func _check_warrior_level_one_ascension_aura() -> void:
	var player = PlayerScript.new()
	player.apply_character_config(GameRulesScript.get_character_config("warrior"))
	player._setup_nodes()
	player._update_skill_ascension_aura(0.0)
	_expect(not player._skill_ascension_aura.visible, "warrior ascension aura appeared before a profession skill upgrade")
	player.apply_upgrade({"id": "warrior_q_damage", "stat": "behavior_upgrade", "max_level": 1})
	player._update_skill_ascension_aura(0.0)
	_expect(player.get_profession_skill_upgrade_count() == 1, "warrior profession skill upgrade count did not reach level one")
	_expect(player._skill_ascension_aura.visible, "warrior level-one ascension aura did not appear")
	_expect(player._skill_ascension_aura.get_child_count() == 4, "warrior level-one ascension aura is not composed of two red-gold arc layers")
	player.apply_upgrade({"id": "move_speed_common", "stat": "move_speed", "amount": 0.05, "max_level": 1})
	_expect(player.get_profession_skill_upgrade_count() == 1, "general upgrades incorrectly advanced the warrior ascension aura")
	player.free()

func _check_archer_charge_feedback() -> void:
	var player = PlayerScript.new()
	player.apply_character_config(GameRulesScript.get_character_config("archer"))
	player.use_mouse_aim = false
	player._setup_nodes()
	player._archer_q_charging = true
	player._archer_q_charge_time = PlayerScript.ARCHER_Q_MAX_CHARGE_TIME * 0.5
	player._update_feedback()
	_expect(player._charge_indicator.visible, "archer Q did not show its charge bar while charging")
	_expect(player._charge_bar_fill.points.size() == 2 and is_equal_approx(player._charge_bar_fill.points[1].x, 0.0), "archer Q charge bar did not display half charge")
	_expect(player._charge_aim_line.points.size() == 2, "archer Q did not show its aiming guide while charging")
	player.archer_charge_time_multiplier = 0.8
	player._archer_q_charge_time = PlayerScript.ARCHER_Q_MAX_CHARGE_TIME * player.archer_charge_time_multiplier
	player._update_feedback()
	_expect(player._is_archer_q_fully_charged(), "archer Q full-charge feedback ignored the quickdraw duration")
	_expect(is_equal_approx(player._charge_aim_line.width, 4.0), "archer Q aiming guide did not become stronger at full charge")
	_expect(player._charge_full_flash.visible, "archer Q did not flash when it first reached full charge")
	player.free()

func _check_combat_event_frame() -> void:
	var player = PlayerScript.new()
	player.apply_character_config(GameRulesScript.get_character_config("warrior"))
	player._setup_nodes()
	var emitted := [false]
	player.basic_attack_requested.connect(func(_origin, _direction, _length, _width, _damage, _is_critical): emitted[0] = true)
	player._queue_combat_event("basic", Vector2.RIGHT, 10.0)
	player._start_attack_animation(false)
	_expect(not emitted[0], "melee damage emitted on the first visual frame")
	player._advance_animation(0.06)
	_expect(not emitted[0], "melee damage emitted before the configured event frame")
	player._advance_animation(0.06)
	_expect(emitted[0], "melee damage did not emit on the configured event frame")
	player.free()

func _check_authority_snapshot_contract() -> void:
	var cooldowns := {"attack": 0.1, "dash": 0.2, "skill": 0.3, "fan": 0.4, "ultimate": 0.5, "secondary": 0.6}
	var player_state: Dictionary = AuthorityContractScript.make_player_state(1, Vector2.ZERO, 100.0, 120.0, false, cooldowns)
	var enemy_state: Dictionary = AuthorityContractScript.make_enemy_state(1, "melee", Vector2(40.0, 20.0), 35.0, 46.0)
	var snapshot: Dictionary = AuthorityContractScript.make_snapshot(1, "WAVE_ACTIVE", 0, [player_state], [enemy_state], 59.0, 1.0, {"enemies_defeated": 2})
	_expect(AuthorityContractScript.validate_snapshot(snapshot), "authority snapshot contract is invalid")
	_expect(int(snapshot.get("version", 0)) == 4, "authority snapshot version was not advanced")
	_expect((player_state.get("velocity", Vector2.INF) as Vector2).is_equal_approx(Vector2.ZERO), "authority player state omitted velocity")
	_expect(str(player_state.get("animation", "")) == "idle", "authority player state omitted animation")
	_expect(snapshot.has("projectiles") and snapshot.has("skill_areas") and snapshot.has("ultimates"), "authority snapshot omitted combat entities")
	_expect(is_equal_approx(float(snapshot.get("wave_time_left", 0.0)), 59.0), "authority snapshot omitted wave time")
	var duplicate_enemy_snapshot := snapshot.duplicate(true)
	duplicate_enemy_snapshot["enemies"] = [enemy_state, enemy_state.duplicate(true)]
	_expect(not AuthorityContractScript.validate_snapshot(duplicate_enemy_snapshot), "authority snapshot accepted duplicate enemy ids")
	var duplicate_combat_entity_snapshot := snapshot.duplicate(true)
	duplicate_combat_entity_snapshot["projectiles"] = [{"entity_id": 4, "type": "player", "position": Vector2.ZERO}]
	duplicate_combat_entity_snapshot["skill_areas"] = [{"entity_id": 4, "type": "archer_trap", "position": Vector2.ZERO}]
	_expect(not AuthorityContractScript.validate_snapshot(duplicate_combat_entity_snapshot), "authority snapshot accepted a duplicate combat entity id")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
