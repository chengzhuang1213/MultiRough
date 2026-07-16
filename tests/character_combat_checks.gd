extends SceneTree

const MainScene := preload("res://scenes/main/main.tscn")
const UpgradeCatalogScript := preload("res://scripts/upgrades/upgrade_catalog.gd")

var failures: Array[String] = []
var game: Node

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	game = MainScene.instantiate()
	root.add_child(game)
	await process_frame
	for character_id in ["warrior", "archer", "lancer"]:
		await _check_character(character_id)
	await _check_archer_full_charge_piercing()
	await _check_mage_combat()
	await _check_e_cast_validation()
	await _check_secondary_actions()
	await _check_e_upgrade_branches()
	await _check_common_damage_accounting()
	if failures.is_empty():
		print("PASS: character combat checks")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)

func _check_e_cast_validation() -> void:
	game.selected_character_ids = ["archer", "archer"]
	game._start_game(1)
	await _wait_for_enemy()
	var player: PlayerController = game.players[0]
	var enemy: EnemyController = game.enemies[0]
	player.external_input_enabled = true
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(500.0, 0.0)
	player.apply_external_input({"fan": true, "aim": Vector2.RIGHT})
	player._physics_process(0.01)
	_expect(is_zero_approx(player._fan_skill_timer), "archer E consumed cooldown without a target in cast range")
	enemy.global_position = Vector2(400.0, 0.0)
	player.apply_external_input({"fan": true, "aim": Vector2.RIGHT})
	player._physics_process(0.01)
	_expect(player._fan_skill_timer > 0.0, "archer E did not enter cooldown after a valid cast")
	_expect(enemy._marked_by == player, "archer E did not execute after a valid target entered cast range")
	player._fan_skill_timer = 0.0
	enemy._marked_by = null
	enemy.global_position = player.global_position
	player.apply_external_input({"fan": true, "aim": Vector2.RIGHT})
	player._physics_process(0.01)
	_expect(enemy._marked_by == player, "archer E validation and execution disagreed for an overlapping target")
	game._clear_run_state()
	await process_frame

	game.selected_character_ids = ["mage", "mage"]
	game._start_game(1)
	await _wait_for_enemy()
	player = game.players[0]
	enemy = game.enemies[0]
	player.external_input_enabled = true
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(500.0, 0.0)
	player.apply_external_input({"fan": true, "aim": Vector2.RIGHT})
	player._physics_process(0.01)
	_expect(player._fan_skill_timer > 0.0, "mage base E did not enter cooldown after creating its field")
	_expect(_has_persistent_area("mage_field"), "mage base E press did not immediately create its field")
	game._clear_run_state()
	await process_frame

	game.selected_character_ids = ["mage", "mage"]
	game._start_game(1)
	await _wait_for_enemy()
	player = game.players[0]
	enemy = game.enemies[0]
	player.external_input_enabled = true
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(500.0, 0.0)
	_grant_upgrade(player, "mage_e_chain")
	player.apply_external_input({"fan": true, "aim": Vector2.RIGHT})
	player._physics_process(0.01)
	_expect(is_zero_approx(player._fan_skill_timer), "mage chain E consumed cooldown without a target in cast range")
	enemy.global_position = Vector2(300.0, 0.0)
	player.apply_external_input({"fan": true, "aim": Vector2.RIGHT})
	player._physics_process(0.01)
	_expect(player._fan_skill_timer > 0.0, "mage chain E did not enter cooldown after a valid cast")
	_expect(enemy.health < enemy.max_health, "mage chain E did not execute after a valid target entered cast range")
	player._fan_skill_timer = 0.0
	game._spawn_minions(1)
	enemy = game.enemies.back()
	enemy.global_position = player.global_position
	player.apply_external_input({"fan": true, "aim": Vector2.RIGHT})
	player._physics_process(0.01)
	_expect(enemy.health < enemy.max_health, "mage chain E validation and execution disagreed for an overlapping target")
	game._clear_run_state()
	await process_frame

func _check_character(character_id: String) -> void:
	game.selected_character_ids = [character_id, character_id]
	game._start_game(1)
	await _wait_for_enemy()
	var player: PlayerController = game.players[0]
	var enemy: EnemyController = game.enemies[0]
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(48.0, 0.0)
	_expect(player.character_id == character_id, "%s did not spawn with its character config" % character_id)
	_expect(is_equal_approx(player._sprite.scale.x, player.visual_scale), "%s did not apply its configured visual scale" % character_id)
	_expect(game.combat_manager.character_modules.has(character_id), "%s combat module is not registered" % character_id)

	_reset_enemy(enemy)
	var projectiles_before: int = game.projectile_root.get_child_count()
	if character_id == "archer":
		game.combat_manager.on_player_projectile_attack(player.global_position, Vector2.RIGHT, 5.0, player)
		_expect(game.projectile_root.get_child_count() == projectiles_before + 1, "archer basic attack did not create one arrow")
	else:
		game.combat_manager.on_player_basic_attack(player.global_position, Vector2.RIGHT, player.attack_range, player.attack_half_width, 5.0, player)
		_expect(enemy.health < enemy.max_health, "%s basic attack did not deal melee damage" % character_id)
	game._clear_projectiles()
	await process_frame

	_reset_enemy(enemy)
	game.combat_manager.on_player_active_skill(player.global_position, Vector2.RIGHT, player.skill_length, player.skill_half_width, 5.0, player)
	var base_q_damage := enemy.max_health - enemy.health
	if character_id == "warrior":
		_expect(player._warrior_taunt_guard_left > 0.0, "warrior Q did not grant its two-second damage reduction")
		_expect(enemy._forced_target == player, "warrior Q did not taunt a nearby normal enemy")
		_expect(enemy.health < enemy.max_health, "warrior Q did not damage enemies pulled into melee range")
		var pull_direction: Vector2 = (player.global_position - enemy.global_position).normalized()
		_expect(enemy._knockback_velocity.dot(pull_direction) >= 400.0, "warrior Q pull was not strong enough to visibly move a normal enemy toward the warrior")
		_expect(_has_effect_node("WarriorQEffect"), "warrior Q did not create its textured shockwave")
		_expect(_has_effect_node("WarriorQInwardStreaks"), "warrior Q did not create inward-moving streaks")
		player.apply_upgrade({"id": "warrior_q_range", "stat": "behavior_upgrade"})
		player.apply_upgrade({"id": "warrior_q_damage", "stat": "behavior_upgrade"})
		_reset_enemy(enemy)
		enemy.global_position = player.global_position + Vector2(240.0, 0.0)
		game.combat_manager.on_player_active_skill(player.global_position, Vector2.RIGHT, player.skill_length, player.skill_half_width, 5.0, player)
		_expect(enemy.health < enemy.max_health, "warrior common Q range upgrade did not reach 240 units")
		_expect(enemy.max_health - enemy.health > base_q_damage, "warrior common Q damage upgrade did not increase damage")
	elif character_id == "archer":
		_expect(game.projectile_root.get_child_count() > 0, "archer Q did not create its high-damage arrow")
		var base_arrow := game.projectile_root.get_child(game.projectile_root.get_child_count() - 1) as PlayerProjectile
		_expect(base_arrow.has_node("Texture") and (base_arrow.get_node("Texture") as Sprite2D).texture != null, "archer Q did not use its charged-arrow texture")
		_expect(base_arrow.has_node("ArcherQTrail"), "archer Q did not create its motion trail")
		_expect(not base_arrow.pierces_enemies, "archer Q pierced before reaching full charge")
		var base_arrow_damage := base_arrow.damage
		player.apply_upgrade({"id": "archer_q_quickdraw", "stat": "behavior_upgrade"})
		player.apply_upgrade({"id": "archer_q_damage", "stat": "behavior_upgrade"})
		game._clear_projectiles()
		game.combat_manager.on_player_active_skill(player.global_position, Vector2.RIGHT, player.skill_length, player.skill_half_width, 5.0, player)
		var upgraded_arrow := game.projectile_root.get_child(game.projectile_root.get_child_count() - 1) as PlayerProjectile
		_expect(is_equal_approx(upgraded_arrow.damage, base_arrow_damage * 1.25), "archer common Q damage upgrade did not increase arrow damage")
		_expect(is_equal_approx(player.archer_charge_time_multiplier, 0.8), "archer common Q charge upgrade did not shorten charging")
	else:
		_expect(enemy.health < enemy.max_health, "lancer Q no longer damages its frontal sweep")
		_expect(_has_effect_node("LancerSweep"), "lancer Q did not create its textured spear sweep")
		player.apply_upgrade({"id": "lancer_q_range", "stat": "behavior_upgrade"})
		player.apply_upgrade({"id": "lancer_q_damage", "stat": "behavior_upgrade"})
		_reset_enemy(enemy)
		enemy.global_position = player.global_position + Vector2(210.0, 0.0)
		game.combat_manager.on_player_active_skill(player.global_position, Vector2.RIGHT, player.skill_length, player.skill_half_width, 5.0, player)
		_expect(enemy.health < enemy.max_health, "lancer common Q range upgrade did not reach 210 units")
		_expect(enemy.max_health - enemy.health > base_q_damage, "lancer common Q damage upgrade did not increase damage")
	game._clear_projectiles()
	await process_frame

	_reset_enemy(enemy)
	projectiles_before = game.projectile_root.get_child_count()
	game.combat_manager.on_player_fan_skill(player.global_position, Vector2.RIGHT, player.fan_skill_length, player.fan_skill_half_width, 5.0, player)
	if character_id == "warrior":
		_expect(player._warrior_counter_left > 0.0, "warrior E did not activate counter stance")
		_expect(player._get_defense_move_multiplier() == 1.0, "warrior E did not preserve movement")
		_expect(_has_persistent_area("warrior_counter"), "warrior E did not create its counter damage field")
		var counter_root: Node2D = game.persistent_skill_areas[0].get("root") as Node2D
		_expect(counter_root != null and counter_root.has_node("WarriorCounterTexture"), "warrior E did not create its textured shield aura")
		_expect(counter_root != null and counter_root.has_node("WarriorCounterInnerTexture"), "warrior E did not create its counter-rotating inner aura")
	elif character_id == "archer":
		_expect(enemy._marked_by == player, "archer E did not mark its aimed target")
		_expect(is_equal_approx(enemy.get_damage_multiplier(player), 1.55), "archer E mark did not increase damage by 55 percent")
		_expect(enemy.has_node("ArcherMarkVFX/ArcherMarkTexture"), "archer E mark did not create its textured hunter sigil")
	else:
		_expect(enemy.health < enemy.max_health, "lancer E spin did not damage nearby enemies")
		_expect(_has_effect_node("LancerDashVFX"), "lancer E dash did not create its spear trail")
	game._clear_projectiles()
	await process_frame

	game.combat_manager.on_player_ultimate_skill(player.global_position, Vector2.RIGHT, 5.0, 8.0, player)
	if character_id == "warrior":
		var state: Dictionary = game.ultimate_states[player.get_instance_id()]
		_expect(float(state.get("duration_left", 0.0)) > 0.0, "warrior F did not activate its orbiting blades")
		_expect((state.get("root") as Node2D).get_child_count() == 2, "warrior base F did not create two orbiting blades")
		var first_blade: Node2D = (state.get("root") as Node2D).get_child(0) as Node2D
		_expect(first_blade != null and first_blade.has_node("Texture") and (first_blade.get_node("Texture") as Sprite2D).texture != null, "warrior F blade did not use its textured effect")
		_expect(first_blade != null and first_blade.has_node("Trail"), "warrior F blade did not create a motion trail")
		_expect(player._warrior_blade_guard_left <= 0.0, "warrior base F granted the epic damage reduction")
		player.apply_upgrade({"id": "warrior_f_extra_blade", "stat": "behavior_upgrade"})
		player.apply_upgrade({"id": "warrior_f_attack_defense", "stat": "behavior_upgrade"})
		game.combat_manager.on_player_ultimate_skill(player.global_position, Vector2.RIGHT, 5.0, 8.0, player)
		_expect((state.get("root") as Node2D).get_child_count() == 3, "warrior common F upgrade did not add one blade")
		_expect(player._warrior_blade_guard_left > 0.0, "warrior epic F upgrade did not grant damage reduction")
	elif character_id == "archer":
		_expect(_has_persistent_area("arrow_rain"), "archer F no longer creates arrow rain")
		var rain: Dictionary = game.persistent_skill_areas.back()
		_expect(is_equal_approx(float(rain.get("duration_left", 0.0)), 5.0), "archer F duration is not five seconds")
		_expect(is_equal_approx(float(rain.get("interval", 0.0)), 0.5), "archer F does not fire one arrow every 0.5 seconds")
		_expect(not bool(rain.get("critical_upgrade", false)), "archer base F received its rare critical effect")
		_expect(not bool(rain.get("weakpoint_upgrade", false)), "archer base F received its epic weak-point effect")
		var rain_root: Node2D = rain.get("root") as Node2D
		_expect(rain_root != null and rain_root.has_node("ArcherRainTexture"), "archer F did not create its textured arrow-rain zone")
		game._spawn_minions(1)
		var second_enemy: EnemyController = game.enemies.back()
		var rain_center := rain.get("origin") as Vector2
		_reset_enemy(enemy)
		enemy.global_position = rain_center
		second_enemy.global_position = rain_center + Vector2(20.0, 0.0)
		second_enemy.health = second_enemy.max_health
		game.combat_manager.update_persistent_skill_areas(0.0)
		var damaged_count := int(enemy.health < enemy.max_health) + int(second_enemy.health < second_enemy.max_health)
		_expect(damaged_count == 1, "archer F damaged more than one enemy in a single arrow tick")
		_expect(_has_effect_node("ArcherArrowStrike"), "archer F damage tick did not create a falling-arrow strike")
		game.combat_manager.clear_persistent_skill_areas()
		player.apply_upgrade({"id": "archer_f_weakpoint", "stat": "behavior_upgrade"})
		player.apply_upgrade({"id": "archer_f_damage", "stat": "behavior_upgrade"})
		player.apply_upgrade({"id": "archer_f_critical", "stat": "behavior_upgrade"})
		game.combat_manager.on_player_ultimate_skill(player.global_position, Vector2.RIGHT, 5.0, 8.0, player)
		var upgraded_rain: Dictionary = game.persistent_skill_areas.back()
		_expect(is_equal_approx(float(upgraded_rain.get("damage", 0.0)), 5.0 * 0.26 * 1.25), "archer common F upgrade did not increase arrow damage")
		_expect(bool(upgraded_rain.get("critical_upgrade", false)), "archer rare F upgrade did not enable critical arrows")
		_expect(bool(upgraded_rain.get("weakpoint_upgrade", false)), "archer epic F upgrade did not enable weak-point scaling")
	else:
		_expect(_has_persistent_area("lancer_storm"), "lancer F no longer creates its close-range storm")
		var storm: Dictionary = game.persistent_skill_areas.back()
		var storm_root: Node2D = storm.get("root") as Node2D
		_expect(storm_root != null and storm_root.has_node("LancerStormTexture"), "lancer F did not create its textured spear cyclone")
		_expect(is_equal_approx(float(storm.get("radius", 0.0)), 175.0), "lancer base F radius changed")
		_expect(not bool(storm.get("pull_upgrade", false)), "lancer base F received its rare pull effect")
		_expect(not bool(storm.get("finisher_upgrade", false)), "lancer base F received its epic finisher")
		game.combat_manager.clear_persistent_skill_areas()
		player.apply_upgrade({"id": "lancer_f_finisher", "stat": "behavior_upgrade"})
		player.apply_upgrade({"id": "lancer_f_reach", "stat": "behavior_upgrade"})
		player.apply_upgrade({"id": "lancer_f_pull", "stat": "behavior_upgrade"})
		game.combat_manager.on_player_ultimate_skill(player.global_position, Vector2.RIGHT, 5.0, 8.0, player)
		var upgraded_storm: Dictionary = game.persistent_skill_areas.back()
		_expect(is_equal_approx(float(upgraded_storm.get("radius", 0.0)), 210.0), "lancer common F upgrade did not expand the sweep")
		_expect(bool(upgraded_storm.get("pull_upgrade", false)), "lancer rare F upgrade did not enable pulling")
		_expect(bool(upgraded_storm.get("finisher_upgrade", false)), "lancer epic F upgrade did not enable the finishing sweep")
		_reset_enemy(enemy)
		enemy.global_position = player.global_position + Vector2(250.0, 0.0)
		game.combat_manager.update_persistent_skill_areas(5.1)
		_expect(enemy.health < enemy.max_health, "lancer epic F finishing sweep did not deal damage")
		_expect(_has_effect_node("LancerStormFinisher"), "lancer epic F did not create its textured finishing cyclone")

	game._clear_run_state()
	await process_frame
	await process_frame

func _check_archer_full_charge_piercing() -> void:
	game.selected_character_ids = ["archer", "archer"]
	game._start_game(1)
	await _wait_for_enemy()
	var player: PlayerController = game.players[0]
	var first_enemy: EnemyController = game.enemies[0]
	game._spawn_minions(1)
	var second_enemy: EnemyController = game.enemies.back()
	player.global_position = Vector2.ZERO
	player.external_input_enabled = true
	first_enemy.global_position = Vector2(80.0, 0.0)
	second_enemy.global_position = Vector2(160.0, 0.0)
	first_enemy.health = first_enemy.max_health
	second_enemy.health = second_enemy.max_health
	player.apply_external_input({"aim": Vector2.RIGHT, "skill": true, "skill_hold": true})
	player._physics_process(0.0)
	player._physics_process(1.2)
	player.apply_external_input({"aim": Vector2.RIGHT, "skill_hold": false})
	player._physics_process(0.0)
	_expect(bool(player._pending_combat_event.get("full_charge", false)), "archer Q did not preserve its full-charge state until the attack event")
	player._anim_frame = 2
	player._emit_pending_combat_event()
	var arrow := game.projectile_root.get_child(game.projectile_root.get_child_count() - 1) as PlayerProjectile
	_expect(arrow.pierces_enemies, "fully charged archer Q did not enable piercing")
	arrow.global_position = first_enemy.global_position
	arrow._process(0.0)
	_expect(first_enemy.health < first_enemy.max_health, "fully charged archer Q did not damage its first target")
	_expect(not arrow.is_queued_for_deletion(), "fully charged archer Q disappeared after its first target")
	arrow.global_position = second_enemy.global_position
	arrow._process(0.0)
	_expect(second_enemy.health < second_enemy.max_health, "fully charged archer Q did not pierce into a second target")
	var first_health_after_hit := first_enemy.health
	arrow.global_position = first_enemy.global_position
	arrow._process(0.0)
	_expect(is_equal_approx(first_enemy.health, first_health_after_hit), "piercing archer Q damaged the same enemy more than once")
	game._clear_run_state()
	await process_frame
	await process_frame

func _check_mage_combat() -> void:
	game.selected_character_ids = ["mage", "mage"]
	game._start_game(1)
	await _wait_for_enemy()
	var player: PlayerController = game.players[0]
	var enemy: EnemyController = game.enemies[0]
	player.global_position = Vector2.ZERO
	_reset_enemy(enemy)
	_expect(player.character_id == "mage", "mage did not spawn with its character config")
	_expect(game.combat_manager.character_modules.has("mage"), "mage combat module is not registered")
	var projectiles_before: int = game.projectile_root.get_child_count()
	game._spawn_minions(1)
	var splash_enemy: EnemyController = game.enemies.back()
	splash_enemy.global_position = enemy.global_position + Vector2(40.0, 0.0)
	splash_enemy.health = splash_enemy.max_health
	game.combat_manager.on_player_basic_attack(player.global_position, Vector2.RIGHT, player.attack_range, player.attack_half_width, 5.0, player)
	_expect(game.projectile_root.get_child_count() == projectiles_before + 1, "mage basic attack did not create one magic projectile")
	var projectile := game.projectile_root.get_child(game.projectile_root.get_child_count() - 1) as PlayerProjectile
	projectile.global_position = enemy.global_position
	projectile._process(0.0)
	_expect(enemy.health < enemy.max_health, "mage basic projectile did not deal damage")
	_expect(is_equal_approx(splash_enemy.health, splash_enemy.max_health), "mage left-click basic attack still dealt area damage")
	_reset_enemy(enemy)
	projectiles_before = game.projectile_root.get_child_count()
	game.combat_manager.on_player_active_skill(player.global_position, Vector2.RIGHT, player.skill_length, player.skill_half_width, 5.0, player)
	_expect(game.projectile_root.get_child_count() == projectiles_before + 1, "mage Q did not create a fireball")
	var fireball := game.projectile_root.get_child(game.projectile_root.get_child_count() - 1) as PlayerProjectile
	_expect(is_equal_approx(fireball.scale.x, 1.25), "mage Q fireball visual was not enlarged by 25 percent")
	_expect(is_equal_approx(fireball.hit_radius, 25.0), "mage Q fireball hit radius did not match its enlarged body")
	_expect(fireball.has_node("Texture") and (fireball.get_node("Texture") as Sprite2D).texture != null, "mage Q did not use its explosive-fireball texture")
	_expect(fireball.has_node("MageQTrail"), "mage Q did not create its motion trail")
	fireball.global_position = enemy.global_position
	fireball._process(0.0)
	_expect(enemy.health < enemy.max_health, "mage Q explosion did not damage its target")
	_expect(_has_effect_node("MageQExplosion"), "mage Q impact did not create its textured explosion")
	var base_q_damage := enemy.max_health - enemy.health
	game._clear_projectiles()
	await process_frame
	_reset_enemy(enemy)
	enemy.global_position = player.global_position + Vector2(444.0, 0.0)
	game.combat_manager.on_player_active_skill(player.global_position, Vector2.RIGHT, player.skill_length, player.skill_half_width, 5.0, player)
	var range_fireball := game.projectile_root.get_child(game.projectile_root.get_child_count() - 1) as PlayerProjectile
	range_fireball.enemies = []
	range_fireball._process(1.0)
	_expect(enemy.health < enemy.max_health, "mage Q did not explode at its maximum range")
	game._clear_projectiles()
	await process_frame
	_reset_enemy(enemy)
	enemy.global_position = player.global_position + Vector2(100.0, 0.0)
	game._spawn_minions(1)
	var radius_target: EnemyController = game.enemies.back()
	radius_target.global_position = enemy.global_position + Vector2(85.0, 0.0)
	radius_target.health = radius_target.max_health
	player.apply_upgrade({"id": "mage_q_radius", "stat": "behavior_upgrade"})
	player.apply_upgrade({"id": "mage_q_damage", "stat": "behavior_upgrade"})
	game.combat_manager.on_player_active_skill(player.global_position, Vector2.RIGHT, player.skill_length, player.skill_half_width, 5.0, player)
	var upgraded_fireball := game.projectile_root.get_child(game.projectile_root.get_child_count() - 1) as PlayerProjectile
	upgraded_fireball.global_position = enemy.global_position
	upgraded_fireball._process(0.0)
	_expect(enemy.max_health - enemy.health > base_q_damage, "mage common Q damage upgrade did not increase explosion damage")
	_expect(radius_target.health < radius_target.max_health, "mage common Q range upgrade did not expand the explosion")
	game._clear_projectiles()
	await process_frame

	_reset_enemy(enemy)
	game.combat_manager.on_player_fan_skill(player.global_position, Vector2.RIGHT, player.fan_skill_length, player.fan_skill_half_width, 5.0, player)
	_expect(_has_persistent_area("mage_field"), "mage E did not create a persistent field")
	var field: Dictionary = game.persistent_skill_areas[0]
	_expect((field.get("origin") as Vector2).distance_to(player.global_position) <= 180.0, "mage E exceeded its maximum cast range")
	var field_root: Node2D = field.get("root") as Node2D
	_expect(field_root != null and field_root.has_node("MageFieldTexture"), "mage E did not create its textured arcane field")
	enemy._stagger_left = 0.0
	enemy._knockback_velocity = Vector2.ZERO
	game.combat_manager.update_persistent_skill_areas(0.0)
	_expect(enemy.health < enemy.max_health, "mage E field did not damage an enemy inside it")
	_expect(is_equal_approx(enemy._slow_move_multiplier, 0.90), "mage E field did not reduce enemy movement speed by 10 percent")
	_expect(is_zero_approx(enemy._stagger_left), "mage E field damage still caused movement-stopping hit stagger")
	_expect(enemy._knockback_velocity == Vector2.ZERO, "mage E field damage still caused knockback")
	game.combat_manager.clear_persistent_skill_areas()

	_reset_enemy(enemy)
	game.combat_manager.on_player_ultimate_skill(player.global_position, Vector2.RIGHT, 5.0, 8.0, player)
	_expect(_has_persistent_area("mage_storm"), "mage F did not create an elemental storm")
	var storm: Dictionary = game.persistent_skill_areas[0]
	_expect((storm.get("origin") as Vector2).distance_to(player.global_position) <= 160.0, "mage F exceeded its maximum cast range")
	_expect(is_equal_approx(float(storm.get("duration_left", 0.0)), 5.0), "mage F duration is not five seconds")
	_expect(is_equal_approx(float(storm.get("interval", 0.0)), 1.0), "mage F does not pulse once per second")
	_expect(is_equal_approx(float(storm.get("radius", 0.0)), 220.0), "mage base F radius changed")
	_expect(not bool(storm.get("finisher_upgrade", false)), "mage base F received its epic finisher")
	var storm_root: Node2D = storm.get("root") as Node2D
	_expect(storm_root != null and storm_root.has_node("MageStormTexture"), "mage F did not create its textured elemental storm")
	game._spawn_minions(1)
	var second_enemy: EnemyController = game.enemies.back()
	second_enemy.setup_as_boss()
	var storm_center := storm.get("origin") as Vector2
	enemy.global_position = storm_center
	second_enemy.global_position = storm_center + Vector2(20.0, 0.0)
	second_enemy.health = second_enemy.max_health
	game.combat_manager.update_persistent_skill_areas(0.0)
	_expect(_has_effect_node("MageLightningStrike"), "mage F pulse did not create its lightning strike")
	_expect(enemy.health < enemy.max_health, "mage F storm did not damage an enemy inside it")
	_expect(second_enemy.health < second_enemy.max_health, "mage F did not damage every enemy inside its pulse")
	_expect(is_equal_approx(enemy._stun_left, 0.5), "mage F did not stun a normal enemy for half a second")
	_expect(is_equal_approx(second_enemy._stun_left, 0.5), "mage F half-second stun did not affect the boss")
	enemy._stun_left = 0.25
	game.combat_manager._tick_mage_area(storm, player)
	_expect(is_equal_approx(enemy._stun_left, 0.25), "mage F refreshed stun on every damage pulse")
	game.combat_manager.clear_persistent_skill_areas()
	player.apply_upgrade({"id": "mage_f_finisher", "stat": "behavior_upgrade"})
	player.apply_upgrade({"id": "mage_f_expansion", "stat": "behavior_upgrade"})
	player.apply_upgrade({"id": "mage_f_infusion", "stat": "behavior_upgrade"})
	game.combat_manager.on_player_ultimate_skill(player.global_position, Vector2.RIGHT, 5.0, 8.0, player)
	var upgraded_storm: Dictionary = game.persistent_skill_areas[0]
	_expect(is_equal_approx(float(upgraded_storm.get("radius", 0.0)), 264.0), "mage common F upgrade did not expand the storm")
	_expect(is_equal_approx(float(upgraded_storm.get("damage", 0.0)), 5.0 * 0.30 * 1.30), "mage rare F upgrade did not increase pulse damage")
	_expect(bool(upgraded_storm.get("finisher_upgrade", false)), "mage epic F upgrade did not enable the final explosion")
	_reset_enemy(enemy)
	enemy.global_position = (upgraded_storm.get("origin") as Vector2) + Vector2(300.0, 0.0)
	game.combat_manager.update_persistent_skill_areas(5.1)
	_expect(enemy.health < enemy.max_health, "mage epic F final explosion did not deal damage")
	_expect(_has_effect_node("MageStormFinisher"), "mage epic F did not create its textured final burst")
	game._clear_run_state()
	await process_frame
	await process_frame

func _check_secondary_actions() -> void:
	await _check_warrior_secondary()
	await _check_archer_secondary()
	await _check_mage_secondary()
	await _check_lancer_secondary()

func _check_warrior_secondary() -> void:
	game.selected_character_ids = ["warrior", "warrior"]
	game._start_game(1)
	await _wait_for_enemy()
	var player: PlayerController = game.players[0]
	player.external_input_enabled = true
	_press_secondary(player, Vector2.RIGHT)
	_expect(player.is_defending, "warrior right-click did not start sustained guard")
	_expect(player.has_node("WarriorSecondaryVFX/Texture"), "warrior right-click did not create its sustained shield VFX")
	_expect(is_equal_approx(player.get_secondary_remaining(), 3.0), "warrior guard did not start the shared three-second cooldown")
	player._tick_timers(3.1)
	player._physics_process(0.0)
	_expect(player.is_defending and player.get_secondary_ready(), "warrior guard did not remain active while its cooldown completed")
	_release_secondary(player)
	_expect(not player.is_defending, "warrior guard did not end after releasing right-click")
	_expect(not player.has_node("WarriorSecondaryVFX"), "warrior right-click shield VFX remained after guard release")
	_press_secondary(player, Vector2.RIGHT)
	_expect(player.is_defending, "warrior could not guard again after cooldown completed during a long hold")
	game._clear_run_state()
	await process_frame

func _check_archer_secondary() -> void:
	game.selected_character_ids = ["archer", "archer"]
	game._start_game(1)
	await _wait_for_enemy()
	var player: PlayerController = game.players[0]
	player.external_input_enabled = true
	var before: int = game.projectile_root.get_child_count()
	_press_secondary(player, Vector2.RIGHT)
	_expect(game.projectile_root.get_child_count() == before + 3, "archer right-click did not fire three arrows")
	_expect(_has_effect_node("ArcherSecondaryVFX"), "archer right-click did not create its triple-shot VFX")
	for index in range(before, game.projectile_root.get_child_count()):
		var arrow := game.projectile_root.get_child(index) as PlayerProjectile
		_expect(is_equal_approx(arrow.damage, player.attack_damage * 0.60), "archer right-click arrow did not deal 60 percent basic damage")
	_expect(is_equal_approx(player.get_secondary_remaining(), 3.0), "archer right-click did not start the shared cooldown")
	_release_secondary(player)
	_press_secondary(player, Vector2.RIGHT)
	_expect(game.projectile_root.get_child_count() == before + 3, "archer right-click fired again before the shared cooldown ended")
	game._clear_run_state()
	await process_frame

func _check_mage_secondary() -> void:
	game.selected_character_ids = ["mage", "mage"]
	game._start_game(1)
	await _wait_for_enemy()
	var player: PlayerController = game.players[0]
	var enemy: EnemyController = game.enemies[0]
	game._spawn_minions(1)
	var outside: EnemyController = game.enemies.back()
	game._spawn_minions(1)
	var boss: EnemyController = game.enemies.back()
	boss.setup_as_boss()
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(80.0, 0.0)
	outside.global_position = Vector2(120.0, 0.0)
	boss.global_position = Vector2(-80.0, 0.0)
	enemy.health = enemy.max_health
	outside.health = outside.max_health
	boss.health = boss.max_health
	enemy._knockback_velocity = Vector2.ZERO
	boss._knockback_velocity = Vector2.ZERO
	player.external_input_enabled = true
	var projectiles_before: int = game.projectile_root.get_child_count()
	_press_secondary(player, Vector2.RIGHT)
	_expect(_has_effect_node("MageSecondaryVFX"), "mage right-click did not create its repulsion VFX")
	_expect(is_equal_approx(enemy.max_health - enemy.health, player.attack_damage * 0.50), "mage right-click did not deal 50 percent basic damage")
	_expect(is_equal_approx(boss.max_health - boss.health, player.attack_damage * 0.50), "mage right-click did not damage the boss")
	_expect(is_equal_approx(outside.health, outside.max_health), "mage right-click damaged an enemy outside its 110 radius")
	_expect(enemy._knockback_velocity.length() > 0.0, "mage right-click did not repel a normal enemy")
	_expect(boss._knockback_velocity == Vector2.ZERO, "mage right-click repelled the boss")
	_expect(is_equal_approx(enemy._slow_left, 1.5) and is_equal_approx(enemy._slow_move_multiplier, 0.75), "mage right-click did not slow a normal enemy by 25 percent for 1.5 seconds")
	_expect(is_equal_approx(boss._slow_left, 1.5) and is_equal_approx(boss._slow_move_multiplier, 0.90), "mage right-click did not apply the light boss slow")
	_expect(game.projectile_root.get_child_count() == projectiles_before, "mage right-click still created a projectile")
	_expect(is_equal_approx(player.get_secondary_remaining(), 3.0), "mage right-click did not start the shared cooldown")
	var health_after_first_cast := enemy.health
	_release_secondary(player)
	_press_secondary(player, Vector2.RIGHT)
	_expect(is_equal_approx(enemy.health, health_after_first_cast), "mage right-click fired again before the shared cooldown ended")
	game._clear_run_state()
	await process_frame

func _check_lancer_secondary() -> void:
	game.selected_character_ids = ["lancer", "lancer"]
	game._start_game(1)
	await _wait_for_enemy()
	var player: PlayerController = game.players[0]
	var right_enemy: EnemyController = game.enemies[0]
	game._spawn_minions(1)
	var left_enemy: EnemyController = game.enemies.back()
	player.global_position = Vector2.ZERO
	right_enemy.global_position = Vector2(80.0, 0.0)
	left_enemy.global_position = Vector2(-80.0, 0.0)
	right_enemy.health = right_enemy.max_health
	left_enemy.health = left_enemy.max_health
	player.external_input_enabled = true
	_press_secondary(player, Vector2.RIGHT)
	_expect(_has_effect_node("LancerSecondaryVFX"), "lancer right-click did not create its double-sweep VFX")
	_expect(right_enemy.health < right_enemy.max_health and left_enemy.health < left_enemy.max_health, "lancer right-click did not hit both opposite directions")
	_expect(is_equal_approx(player.get_secondary_remaining(), 3.0), "lancer right-click did not start the shared cooldown")
	game._clear_run_state()
	await process_frame

func _press_secondary(player: PlayerController, direction: Vector2) -> void:
	player.apply_external_input({"aim": direction, "defend": false})
	player._physics_process(0.0)
	player.apply_external_input({"aim": direction, "aim_target": player.global_position + direction * 200.0, "defend": true})
	player._physics_process(0.0)

func _release_secondary(player: PlayerController) -> void:
	player.apply_external_input({"defend": false})
	player._physics_process(0.0)

func _check_common_damage_accounting() -> void:
	game.selected_character_ids = ["warrior", "warrior"]
	game._start_game(1)
	await _wait_for_enemy()
	var player: PlayerController = game.players[0]
	var enemy: EnemyController = game.enemies[0]
	player.health = 50.0
	player.lifesteal_ratio = 0.10
	game.damage_dealt = 0.0
	game.combat_manager.damage_enemy(enemy, 10.0, player, player.global_position, 0.0)
	_expect(is_equal_approx(game.damage_dealt, 10.0), "combat module counted one hit more than once")
	_expect(is_equal_approx(player.health, 51.0), "combat module applied lifesteal more or less than once")
	game._clear_run_state()
	await process_frame

func _check_e_upgrade_branches() -> void:
	await _check_warrior_e_branches()
	await _check_archer_e_branches()
	await _check_mage_e_branches()
	await _check_lancer_e_branches()

func _check_warrior_e_branches() -> void:
	game.selected_character_ids = ["warrior", "warrior"]
	game._start_game(1)
	await _wait_for_enemy()
	var player: PlayerController = game.players[0]
	var enemy: EnemyController = game.enemies[0]
	_grant_upgrade(player, "warrior_e_counter")
	_grant_upgrade(player, "warrior_e_perfect_guard")
	game.combat_manager.on_player_fan_skill(player.global_position, Vector2.RIGHT, player.fan_skill_length, player.fan_skill_half_width, 10.0, player)
	var health_before := player.health
	var enemy_health_before := enemy.health
	player.apply_damage(10.0, enemy)
	_expect(is_equal_approx(player.health, health_before), "warrior rare E perfect guard did not fully block damage")
	_expect(enemy.health < enemy_health_before, "warrior rare E perfect guard did not trigger retaliation damage")
	game._clear_run_state()
	await process_frame

	game.selected_character_ids = ["warrior", "warrior"]
	game._start_game(1)
	await _wait_for_enemy()
	player = game.players[0]
	enemy = game.enemies[0]
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(142.0, 0.0)
	_grant_upgrade(player, "warrior_e_shield")
	_grant_upgrade(player, "warrior_e_shield_guard")
	game.combat_manager.on_player_fan_skill(player.global_position, Vector2.RIGHT, player.fan_skill_length, player.fan_skill_half_width, 10.0, player)
	_expect(_has_persistent_area("warrior_shield"), "warrior alternate E did not create a shield shadow")
	game.combat_manager.update_persistent_skill_areas(0.23)
	_expect(enemy.health < enemy.max_health, "warrior shield shadow did not damage on its outward path")
	game.combat_manager.update_persistent_skill_areas(0.23)
	game.combat_manager.update_persistent_skill_areas(0.23)
	game.combat_manager.update_persistent_skill_areas(0.23)
	_expect(player._warrior_shield_guard_left > 0.0, "warrior rare E shield return did not grant protection")
	game._clear_run_state()
	await process_frame

func _check_archer_e_branches() -> void:
	game.selected_character_ids = ["archer", "archer"]
	game._start_game(1)
	await _wait_for_enemy()
	var player: PlayerController = game.players[0]
	var enemy: EnemyController = game.enemies[0]
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(80.0, 0.0)
	game._spawn_minions(1)
	var transfer_target: EnemyController = game.enemies.back()
	transfer_target.global_position = Vector2(120.0, 0.0)
	_grant_upgrade(player, "archer_e_mark")
	_grant_upgrade(player, "archer_e_mark_transfer")
	game.combat_manager.on_player_fan_skill(player.global_position, Vector2.RIGHT, player.fan_skill_length, player.fan_skill_half_width, 10.0, player)
	_expect(enemy.is_marked_by(player), "archer enhanced E did not mark its first target")
	_expect(is_equal_approx(enemy.get_damage_multiplier(player), 1.70), "archer enhanced E did not increase damage by 70 percent")
	game.combat_manager.damage_enemy(enemy, enemy.health + 1.0, player)
	_expect(transfer_target.is_marked_by(player), "archer rare E did not transfer its mark after a kill")
	_expect(is_equal_approx(transfer_target.get_damage_multiplier(player), 1.70), "archer transferred E mark lost its 70 percent damage bonus")
	game._clear_run_state()
	await process_frame

	game.selected_character_ids = ["archer", "archer"]
	game._start_game(1)
	await _wait_for_enemy()
	player = game.players[0]
	enemy = game.enemies[0]
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2.ZERO
	_grant_upgrade(player, "archer_e_trap")
	_grant_upgrade(player, "archer_e_execution_trap")
	game.combat_manager.on_player_fan_skill(player.global_position, Vector2.RIGHT, player.fan_skill_length, player.fan_skill_half_width, 10.0, player)
	_expect(player.global_position.x < 0.0, "archer alternate E did not backstep")
	var trap: Dictionary = game.persistent_skill_areas.back()
	var trap_root: Node2D = trap.get("root") as Node2D
	_expect(trap_root != null and trap_root.has_node("ArcherTrapTexture"), "archer trap E did not create its textured hunter sigil")
	game.combat_manager.update_persistent_skill_areas(0.0)
	_expect(enemy._root_left > 0.0, "archer trap did not root its target")
	_expect(enemy.consume_guaranteed_arrow_crit(player), "archer rare E trap did not prime a guaranteed arrow critical")
	game._clear_run_state()
	await process_frame

func _check_mage_e_branches() -> void:
	game.selected_character_ids = ["mage", "mage"]
	game._start_game(1)
	await _wait_for_enemy()
	var player: PlayerController = game.players[0]
	var enemy: EnemyController = game.enemies[0]
	player.global_position = Vector2.ZERO
	_grant_upgrade(player, "mage_e_field")
	_grant_upgrade(player, "mage_e_accumulation")
	game.combat_manager.on_player_fan_skill(player.global_position, Vector2.RIGHT, player.fan_skill_length, player.fan_skill_half_width, 10.0, player)
	var field: Dictionary = game.persistent_skill_areas.back()
	_expect(is_equal_approx(float(field.get("duration_left", 0.0)), 5.0), "mage common E field did not extend its duration")
	_expect(bool(field.get("accumulation", false)), "mage rare E field did not enable accumulating damage")
	game._clear_run_state()
	await process_frame

	game.selected_character_ids = ["mage", "mage"]
	game._start_game(1)
	await _wait_for_enemy()
	player = game.players[0]
	enemy = game.enemies[0]
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(80.0, 0.0)
	game._spawn_minions(1)
	var second_enemy: EnemyController = game.enemies.back()
	second_enemy.global_position = Vector2(180.0, 0.0)
	_grant_upgrade(player, "mage_e_chain")
	_grant_upgrade(player, "mage_e_conduction")
	game.combat_manager.on_player_fan_skill(player.global_position, Vector2.RIGHT, player.fan_skill_length, player.fan_skill_half_width, 10.0, player)
	_expect(enemy.health < enemy.max_health and second_enemy.health < second_enemy.max_health, "mage alternate E did not chain across multiple enemies")
	_expect(not _has_persistent_area("mage_field"), "mage alternate E still created a persistent circle")
	_expect(_has_effect_node("MageChainCast"), "mage chain E did not create its textured conduction cast")
	_expect(_has_effect_node("MageChainLightning"), "mage chain E did not create its dedicated lightning texture")
	game._clear_run_state()
	await process_frame

func _check_lancer_e_branches() -> void:
	game.selected_character_ids = ["lancer", "lancer"]
	game._start_game(1)
	await _wait_for_enemy()
	var player: PlayerController = game.players[0]
	player.global_position = Vector2.ZERO
	_grant_upgrade(player, "lancer_e_charge")
	_grant_upgrade(player, "lancer_e_double_sweep")
	game.combat_manager.on_player_fan_skill(player.global_position, Vector2.RIGHT, player.fan_skill_length, player.fan_skill_half_width, 10.0, player)
	_expect(player.global_position.x > 150.0, "lancer common E charge did not increase dash distance")
	_expect(player._invulnerable_left > 0.0, "lancer common E charge did not grant brief invulnerability")
	game._clear_run_state()
	await process_frame

	game.selected_character_ids = ["lancer", "lancer"]
	game._start_game(1)
	await _wait_for_enemy()
	player = game.players[0]
	var enemy: EnemyController = game.enemies[0]
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(158.0, 0.0)
	_grant_upgrade(player, "lancer_e_spear")
	_grant_upgrade(player, "lancer_e_return")
	game.combat_manager.on_player_fan_skill(player.global_position, Vector2.RIGHT, player.fan_skill_length, player.fan_skill_half_width, 10.0, player)
	_expect(is_equal_approx(player.global_position.x, 0.0), "lancer alternate E moved the player")
	var spear_root: Node2D = game.persistent_skill_areas.back().get("root") as Node2D
	_expect(spear_root != null and spear_root.has_node("LancerSpearTexture"), "lancer spear branch did not create its textured spear shadow")
	game.combat_manager.update_persistent_skill_areas(0.22)
	var health_after_outward := enemy.health
	_expect(health_after_outward < enemy.max_health, "lancer spear shadow did not damage outward")
	game.combat_manager.update_persistent_skill_areas(0.23)
	game.combat_manager.update_persistent_skill_areas(0.22)
	_expect(enemy.health < health_after_outward, "lancer rare E spear shadow did not damage on return")
	game._clear_run_state()
	await process_frame

func _grant_upgrade(player: PlayerController, upgrade_id: String) -> void:
	for upgrade in UpgradeCatalogScript.BEHAVIOR_POOL:
		if str((upgrade as Dictionary).get("id", "")) == upgrade_id:
			player.apply_upgrade(upgrade as Dictionary)
			return
	_expect(false, "missing behavior upgrade: %s" % upgrade_id)

func _reset_enemy(enemy: EnemyController) -> void:
	enemy.health = enemy.max_health
	enemy.global_position = Vector2(48.0, 0.0)
	enemy._knockback_velocity = Vector2.ZERO

func _has_persistent_area(area_type: String) -> bool:
	for area in game.persistent_skill_areas:
		if str(area.get("type", "")) == area_type:
			return true
	return false

func _has_effect_node(node_name: String) -> bool:
	for child in game.effect_root.get_children():
		if child.name == node_name:
			return true
	return false

func _wait_for_enemy() -> void:
	if game.enemies.is_empty():
		game._spawn_minions(1)
	for _index in range(10):
		if not game.enemies.is_empty():
			return
		await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
