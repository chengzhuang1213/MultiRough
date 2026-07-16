extends SceneTree

const MainScene := preload("res://scenes/main/main.tscn")
const WaveManagerScript := preload("res://scripts/gameplay/wave_manager.gd")
const EnemyScript := preload("res://scripts/enemy/enemy_controller.gd")

var failures: Array[String] = []
var game: Node

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	game = MainScene.instantiate()
	root.add_child(game)
	await process_frame
	_check_wave_roster()
	await _check_enemy_variants()
	await _check_basic_enemy_minor_skills()
	await _check_shield_directional_reduction()
	await _check_charger()
	await _check_bomber()
	await _check_priest_healing()
	await _check_boss_phases()
	await _check_projectile_after_source_death()
	if failures.is_empty():
		print("PASS: enemy behavior checks")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)

func _check_wave_roster() -> void:
	var waves: Array = WaveManagerScript.DEFAULT_WAVES
	_expect(waves.size() == 11, "wave roster is not ten normal waves plus one boss wave")
	_expect(bool((waves[10] as Dictionary).get("boss", false)), "wave 11 is not the boss wave")
	var roster := {}
	for index in range(10):
		for enemy_type in (waves[index] as Dictionary).keys():
			roster[enemy_type] = true
	for enemy_type in ["melee", "heavy", "ranged", "shield", "charger", "bomber", "priest"]:
		_expect(roster.has(enemy_type), "normal waves never spawn enemy type: %s" % enemy_type)

func _check_enemy_variants() -> void:
	var setups := {
		"melee": "setup_as_minion",
		"heavy": "setup_as_heavy",
		"ranged": "setup_as_ranged",
		"shield": "setup_as_shield",
		"charger": "setup_as_charger",
		"bomber": "setup_as_bomber",
		"priest": "setup_as_priest",
	}
	for enemy_type in setups:
		var enemy: EnemyController = EnemyScript.new()
		game.enemy_root.add_child(enemy)
		enemy.call(setups[enemy_type], 5)
		_expect(enemy.enemy_type == enemy_type, "%s setup produced the wrong enemy type" % enemy_type)
		enemy.queue_free()
	await process_frame

func _check_basic_enemy_minor_skills() -> void:
	var early_melee: EnemyController = EnemyScript.new()
	early_melee.setup_as_minion(6)
	_expect(not early_melee.minor_skill_enabled, "basic enemy minor skills activated before wave seven")
	early_melee.free()

	var melee: EnemyController = EnemyScript.new()
	game.enemy_root.add_child(melee)
	await process_frame
	melee.setup_as_minion(7)
	var base_speed := melee.move_speed
	var base_interval := melee.attack_interval
	melee.apply_damage(melee.max_health * 0.61, melee.global_position, 0.0, false)
	_expect(melee._melee_blood_rage_left > 0.0, "wave-seven melee did not trigger blood rage below 40 percent health")
	_expect(is_equal_approx(melee._current_move_speed(), base_speed * EnemyController.MELEE_BLOOD_RAGE_SPEED_MULTIPLIER), "melee blood rage did not increase movement speed")
	_expect(is_equal_approx(melee._current_attack_interval(), base_interval * EnemyController.MELEE_BLOOD_RAGE_ATTACK_INTERVAL_MULTIPLIER), "melee blood rage did not shorten its attack interval")
	melee.queue_free()

	var heavy: EnemyController = EnemyScript.new()
	game.enemy_root.add_child(heavy)
	await process_frame
	heavy.setup_as_heavy(7)
	var stomp := {"emitted": false}
	heavy.area_attack_requested.connect(func(_source, _origin, radius, damage, windup) -> void:
		stomp["emitted"] = is_equal_approx(radius, EnemyController.HEAVY_STOMP_RADIUS) and damage > 0.0 and is_equal_approx(windup, EnemyController.HEAVY_STOMP_WINDUP)
	)
	heavy._start_heavy_stomp()
	_expect(bool(stomp["emitted"]), "wave-seven heavy did not emit its warned ground stomp")
	_expect(is_equal_approx(heavy._heavy_stomp_cooldown_left, EnemyController.HEAVY_STOMP_COOLDOWN), "heavy ground stomp did not start its cooldown")
	heavy.queue_free()

	var ranged: EnemyController = EnemyScript.new()
	game.enemy_root.add_child(ranged)
	var target := Node2D.new()
	game.enemy_root.add_child(target)
	await process_frame
	ranged.setup_as_ranged(7)
	ranged.global_position = Vector2.ZERO
	target.global_position = Vector2.RIGHT * 180.0
	ranged.set_target(target)
	for _shot in range(EnemyController.RANGED_REPOSITION_SHOTS):
		ranged._finish_attack()
	_expect(ranged._ranged_reposition_left > 0.0 and not ranged._ranged_reposition_direction.is_zero_approx(), "wave-seven ranged enemy did not sidestep after three shots")
	ranged.queue_free()
	target.queue_free()
	await process_frame

func _check_shield_directional_reduction() -> void:
	var enemy: EnemyController = EnemyScript.new()
	game.enemy_root.add_child(enemy)
	await process_frame
	enemy.setup_as_shield(1)
	enemy.global_position = Vector2.ZERO
	enemy._facing_direction = Vector2.RIGHT
	var front_damage: float = enemy.apply_damage(10.0, Vector2.RIGHT * 20.0, 0.0)
	enemy.health = enemy.max_health
	var rear_damage: float = enemy.apply_damage(10.0, Vector2.LEFT * 20.0, 0.0)
	_expect(is_equal_approx(front_damage, 3.0), "shield guard did not reduce frontal damage to 30 percent")
	_expect(is_equal_approx(rear_damage, 10.0), "shield guard incorrectly reduced rear damage")
	enemy.queue_free()
	await process_frame

func _check_charger() -> void:
	var enemy: EnemyController = EnemyScript.new()
	game.enemy_root.add_child(enemy)
	await process_frame
	enemy.setup_as_charger(5)
	var result := {"telegraph": false}
	enemy.charge_started.connect(func(_source, _origin, _direction, _length, _windup) -> void:
		result["telegraph"] = true
	)
	enemy._start_charge(Vector2.RIGHT * 200.0)
	_expect(bool(result["telegraph"]), "charger did not emit its charge telegraph")
	_expect(enemy._charge_windup_left > 0.0, "charger did not enter charge windup")
	enemy._update_special_action(0.60)
	_expect(enemy._charge_time_left > 0.0, "charger did not enter its movement phase after windup")
	enemy.queue_free()
	await process_frame

func _check_bomber() -> void:
	var enemy: EnemyController = EnemyScript.new()
	game.enemy_root.add_child(enemy)
	await process_frame
	enemy.setup_as_bomber(5)
	var result := {"exploded": false}
	enemy.self_destruct_requested.connect(func(_source, _origin, radius, damage) -> void:
		result["exploded"] = radius > 0.0 and damage > 0.0
	)
	enemy._start_bomber_explosion()
	_expect(enemy._bomber_windup_left > 0.0, "bomber did not enter explosion windup")
	enemy._update_special_action(1.0)
	_expect(bool(result["exploded"]), "bomber did not request self-destruct damage after windup")
	_expect(enemy._is_dying, "bomber survived its self-destruct")
	await process_frame

func _check_priest_healing() -> void:
	var ally: EnemyController = EnemyScript.new()
	ally.setup_as_minion(5)
	ally.global_position = Vector2.ZERO
	game._register_enemy(ally)
	var priest: EnemyController = EnemyScript.new()
	priest.setup_as_priest(5)
	priest.global_position = Vector2(30.0, 0.0)
	game._register_enemy(priest)
	await process_frame
	ally.health = ally.max_health - 20.0
	var health_before: float = ally.health
	var result := {"telegraph": false}
	priest.healing_started.connect(func(_source, _origin, radius, windup) -> void:
		result["telegraph"] = radius > 0.0 and windup > 0.0
	)
	priest._priest_heal_cooldown_left = 0.0
	priest._start_priest_heal()
	_expect(bool(result["telegraph"]), "priest did not emit its healing telegraph")
	priest._update_special_action(0.70)
	_expect(ally.health > health_before, "priest heal did not restore a nearby damaged ally")
	for enemy in game.enemies.duplicate():
		if is_instance_valid(enemy):
			enemy.queue_free()
	game.enemies.clear()
	await process_frame

func _check_boss_phases() -> void:
	var boss: EnemyController = EnemyScript.new()
	game.enemy_root.add_child(boss)
	await process_frame
	boss.setup_as_boss()
	_expect(is_equal_approx(boss.max_health, 1200.0), "boss base health is not tuned for the target fight duration")
	var target := Node2D.new()
	target.global_position = Vector2(120.0, 0.0)
	game.enemy_root.add_child(target)
	boss.set_target(target)
	var result := {"reinforcements": 0, "cataclysm": false, "desperation": false}
	boss.boss_reinforcement_requested.connect(func(_source) -> void:
		result["reinforcements"] = int(result["reinforcements"]) + 1
	)
	boss.area_attack_requested.connect(func(_source, _origin, radius, _damage, windup) -> void:
		if radius >= 190.0 and windup >= 1.25:
			result["cataclysm"] = true
		if radius >= 300.0 and windup >= 1.5:
			result["desperation"] = true
	)
	_expect(is_equal_approx(boss.get_boss_damage_taken_multiplier(0.85), 1.0), "boss full-health damage multiplier is incorrect")
	_expect(is_equal_approx(boss.get_boss_damage_taken_multiplier(0.55), 0.95), "boss 40-70 percent damage multiplier is incorrect")
	_expect(is_equal_approx(boss.get_boss_damage_taken_multiplier(0.25), 0.90), "boss 10-40 percent damage multiplier is incorrect")
	_expect(is_equal_approx(boss.get_boss_damage_taken_multiplier(0.05), 0.75), "boss final damage multiplier is incorrect")
	var aoe_damage := boss.apply_damage(100.0, boss.global_position, 0.0, false, true)
	_expect(is_equal_approx(aoe_damage, 70.0), "boss AOE resistance did not reduce damage taken to 70 percent")
	boss.health = boss.max_health
	var phase_damage := boss.apply_damage(boss.max_health, boss.global_position, 0.0)
	_expect(is_equal_approx(phase_damage, boss.max_health * 0.30), "boss damage did not stop at the 70 percent phase gate")
	_expect(int(result["reinforcements"]) == 1, "boss did not request reinforcements at 70 percent health")
	_expect(boss._boss_invulnerability_left > 0.0, "boss did not become invulnerable during phase transition")
	_expect(is_equal_approx(boss.apply_damage(100.0), 0.0), "boss took damage during phase transition invulnerability")
	boss._boss_invulnerability_left = 0.0
	var attack_damage_before_enrage := boss.attack_damage
	boss.apply_damage(boss.max_health, boss.global_position, 0.0)
	_expect(int(result["reinforcements"]) == 1, "boss requested reinforcements more than once")
	_expect(boss._boss_enraged, "boss did not enrage at 40 percent health")
	_expect(is_equal_approx(boss.attack_damage, attack_damage_before_enrage * 1.30), "boss enrage did not increase attack damage by 30 percent")
	boss._boss_invulnerability_left = 0.0
	boss.apply_damage(boss.max_health, boss.global_position, 0.0)
	_expect(boss._boss_desperation_unlocked, "boss did not unlock desperation AOE at 20 percent health")
	boss._start_boss_desperation_attack()
	_expect(bool(result["desperation"]), "boss did not emit its large 20-percent-health AOE")
	boss._start_boss_cataclysm()
	_expect(bool(result["cataclysm"]), "boss did not emit its long-warning cataclysm attack")
	boss._stun_left = 0.0
	boss.apply_stun(1.0)
	boss.apply_root(1.0)
	boss.apply_slow(1.0, 0.5)
	boss.apply_defense_repel(Vector2.LEFT * 20.0)
	boss._boss_invulnerability_left = 0.0
	boss.apply_damage(1.0, Vector2.LEFT * 20.0, 200.0, true)
	_expect(is_zero_approx(boss._stun_left), "boss was affected by stun")
	_expect(is_zero_approx(boss._root_left), "boss was affected by root")
	_expect(is_zero_approx(boss._slow_left), "boss was affected by slow")
	_expect(boss._knockback_velocity.is_zero_approx(), "boss was affected by knockback")
	_expect(is_zero_approx(boss._stagger_left), "boss was affected by stagger")
	boss.queue_free()
	target.queue_free()
	await process_frame

func _check_projectile_after_source_death() -> void:
	game.selected_character_ids = ["warrior", "warrior"]
	game._start_game(1)
	await process_frame
	var player: PlayerController = game.players[0]
	var source: EnemyController = EnemyScript.new()
	source.setup_as_ranged(1)
	game.enemy_root.add_child(source)
	game.combat_manager.on_enemy_projectile_requested(source, player, player.global_position + Vector2(-140.0, 0.0), Vector2.RIGHT, 7.0)
	var projectile: Node = game.projectile_root.get_child(game.projectile_root.get_child_count() - 1)
	source.queue_free()
	await process_frame
	var health_before: float = player.health
	projectile.global_position = player.global_position
	projectile._process(0.0)
	_expect(player.health < health_before, "enemy projectile stopped working after its source died")
	var area_source: EnemyController = EnemyScript.new()
	area_source.setup_as_boss()
	game.enemy_root.add_child(area_source)
	health_before = player.health
	game.combat_manager.on_enemy_area_attack_requested(area_source, player.global_position, 50.0, 7.0, 0.01)
	area_source.queue_free()
	await create_timer(0.02).timeout
	_expect(player.health < health_before, "delayed enemy area attack stopped working after its source died")
	game._clear_run_state()
	await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
