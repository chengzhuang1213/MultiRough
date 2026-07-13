extends SceneTree

const MainScene := preload("res://scenes/main/main.tscn")

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
	await _check_mage_combat()
	await _check_common_damage_accounting()
	if failures.is_empty():
		print("PASS: character combat checks")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)

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
	if character_id == "warrior":
		_expect(player._warrior_taunt_guard_left > 0.0, "warrior Q did not grant its two-second damage reduction")
		_expect(enemy._forced_target == player, "warrior Q did not taunt a nearby normal enemy")
		_expect(enemy.health < enemy.max_health, "warrior Q did not damage enemies pulled into melee range")
	elif character_id == "archer":
		_expect(game.projectile_root.get_child_count() > 0, "archer Q did not create its high-damage arrow")
	else:
		_expect(enemy.health < enemy.max_health, "lancer Q no longer damages its frontal sweep")
	game._clear_projectiles()
	await process_frame

	_reset_enemy(enemy)
	projectiles_before = game.projectile_root.get_child_count()
	game.combat_manager.on_player_fan_skill(player.global_position, Vector2.RIGHT, player.fan_skill_length, player.fan_skill_half_width, 5.0, player)
	if character_id == "warrior":
		_expect(player._warrior_counter_left > 0.0, "warrior E did not activate counter stance")
		_expect(player._get_defense_move_multiplier() == 1.0, "warrior E did not preserve movement")
		_expect(_has_persistent_area("warrior_counter"), "warrior E did not create its counter damage field")
	elif character_id == "archer":
		_expect(enemy._marked_by == player, "archer E did not mark its aimed target")
		_expect(enemy.get_damage_multiplier(player) > 1.0, "archer E mark did not increase single-target damage")
	else:
		_expect(enemy.health < enemy.max_health, "lancer E spin did not damage nearby enemies")
	game._clear_projectiles()
	await process_frame

	game.combat_manager.on_player_ultimate_skill(player.global_position, Vector2.RIGHT, 5.0, 2.0, player)
	if character_id == "warrior":
		var state: Dictionary = game.ultimate_states[player.get_instance_id()]
		_expect(float(state.get("duration_left", 0.0)) > 0.0, "warrior F did not activate its orbiting blades")
		_expect((state.get("root") as Node2D).get_child_count() == 3, "warrior F did not create three orbiting blades")
		_expect(player._warrior_blade_guard_left > 0.0, "warrior F did not grant its personal damage reduction")
	elif character_id == "archer":
		_expect(_has_persistent_area("arrow_rain"), "archer F no longer creates arrow rain")
	else:
		_expect(_has_persistent_area("lancer_storm"), "lancer F no longer creates its close-range storm")

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
	game.combat_manager.on_player_basic_attack(player.global_position, Vector2.RIGHT, player.attack_range, player.attack_half_width, 5.0, player)
	_expect(game.projectile_root.get_child_count() == projectiles_before + 1, "mage basic attack did not create one magic projectile")
	var projectile := game.projectile_root.get_child(game.projectile_root.get_child_count() - 1) as PlayerProjectile
	projectile.global_position = enemy.global_position
	projectile._process(0.0)
	_expect(enemy.health < enemy.max_health, "mage basic projectile did not deal damage")
	_reset_enemy(enemy)
	projectiles_before = game.projectile_root.get_child_count()
	game.combat_manager.on_player_active_skill(player.global_position, Vector2.RIGHT, player.skill_length, player.skill_half_width, 5.0, player)
	_expect(game.projectile_root.get_child_count() == projectiles_before + 1, "mage Q did not create a fireball")
	var fireball := game.projectile_root.get_child(game.projectile_root.get_child_count() - 1) as PlayerProjectile
	fireball.global_position = enemy.global_position
	fireball._process(0.0)
	_expect(enemy.health < enemy.max_health, "mage Q explosion did not damage its target")
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
	game.combat_manager.on_player_fan_skill(player.global_position, Vector2.RIGHT, player.fan_skill_length, player.fan_skill_half_width, 5.0, player)
	_expect(_has_persistent_area("mage_field"), "mage E did not create a persistent field")
	var field: Dictionary = game.persistent_skill_areas[0]
	_expect((field.get("origin") as Vector2).distance_to(player.global_position) <= 180.0, "mage E exceeded its maximum cast range")
	game.combat_manager.update_persistent_skill_areas(0.0)
	_expect(enemy.health < enemy.max_health, "mage E field did not damage an enemy inside it")
	game.combat_manager.clear_persistent_skill_areas()

	_reset_enemy(enemy)
	game.combat_manager.on_player_ultimate_skill(player.global_position, Vector2.RIGHT, 5.0, 2.0, player)
	_expect(_has_persistent_area("mage_storm"), "mage F did not create an elemental storm")
	var storm: Dictionary = game.persistent_skill_areas[0]
	_expect((storm.get("origin") as Vector2).distance_to(player.global_position) <= 160.0, "mage F exceeded its maximum cast range")
	game.combat_manager.update_persistent_skill_areas(0.0)
	_expect(enemy.health < enemy.max_health, "mage F storm did not damage an enemy inside it")
	game._clear_run_state()
	await process_frame
	await process_frame

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

func _reset_enemy(enemy: EnemyController) -> void:
	enemy.health = enemy.max_health
	enemy.global_position = Vector2(48.0, 0.0)

func _has_persistent_area(area_type: String) -> bool:
	for area in game.persistent_skill_areas:
		if str(area.get("type", "")) == area_type:
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
