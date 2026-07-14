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
	var target := Node2D.new()
	target.global_position = Vector2(120.0, 0.0)
	game.enemy_root.add_child(target)
	boss.set_target(target)
	var result := {"reinforcements": 0, "cataclysm": false}
	boss.boss_reinforcement_requested.connect(func(_source) -> void:
		result["reinforcements"] = int(result["reinforcements"]) + 1
	)
	boss.area_attack_requested.connect(func(_source, _origin, radius, _damage, windup) -> void:
		if radius >= 190.0 and windup >= 1.25:
			result["cataclysm"] = true
	)
	boss.apply_damage(boss.max_health * 0.31, boss.global_position, 0.0)
	_expect(int(result["reinforcements"]) == 1, "boss did not request reinforcements at 70 percent health")
	boss.apply_damage(boss.max_health * 0.31, boss.global_position, 0.0)
	_expect(int(result["reinforcements"]) == 1, "boss requested reinforcements more than once")
	_expect(boss._boss_enraged, "boss did not enrage at 40 percent health")
	boss._start_boss_cataclysm()
	_expect(bool(result["cataclysm"]), "boss did not emit its long-warning cataclysm attack")
	boss._stun_left = 0.0
	boss._boss_stun_resistance_left = 0.0
	boss.apply_stun(1.0)
	_expect(is_equal_approx(boss._stun_left, 1.0), "boss resisted the first stun")
	boss._stun_left = 0.0
	boss.apply_stun(1.0)
	_expect(is_equal_approx(boss._stun_left, 0.5), "boss did not gain temporary repeated-stun resistance")
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
