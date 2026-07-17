extends RefCounted
class_name WaveSpawner

const EnemyScript := preload("res://scripts/enemy/enemy_controller.gd")

var game

func _init(game_root) -> void:
	game = game_root

func spawn_minions(count: int) -> void:
	for index in range(count):
		var enemy: EnemyController = EnemyScript.new()
		enemy.setup_as_minion(game.wave_index + 1)
		tune_enemy_for_mode(enemy)
		enemy.global_position = spawn_point(index, count)
		game._register_enemy(enemy)

func spawn_wave(wave_def: Dictionary) -> void:
	if bool(wave_def.get("mini_boss", false)):
		spawn_mini_boss()
		return
	var spawn_types: Array[String] = []
	for enemy_type in ["melee", "heavy", "ranged", "shield"]:
		var scaled_count := roundi(float(wave_def.get(enemy_type, 0)) * game.minion_count_multiplier)
		for _index in range(scaled_count):
			spawn_types.append(enemy_type)
	var elite_multiplier := 2 if game.local_player_count > 1 else 1
	for enemy_type in ["charger", "bomber"]:
		for _index in range(int(wave_def.get(enemy_type, 0)) * elite_multiplier):
			spawn_types.append(enemy_type)
	for _index in range(int(wave_def.get("priest", 0))):
		spawn_types.append("priest")
	spawn_types.shuffle()
	for index in range(spawn_types.size()):
		var enemy: EnemyController = EnemyScript.new()
		setup_wave_enemy(enemy, spawn_types[index])
		enemy.global_position = spawn_point(index, spawn_types.size())
		game._register_enemy(enemy)

func setup_wave_enemy(enemy: EnemyController, enemy_type: String) -> void:
	var wave_number: int = game.wave_index + 1
	match enemy_type:
		"training_dummy": enemy.setup_as_training_dummy()
		"mini_boss": enemy.setup_as_mini_boss()
		"heavy": enemy.setup_as_heavy(wave_number)
		"ranged": enemy.setup_as_ranged(wave_number)
		"shield": enemy.setup_as_shield(wave_number)
		"charger": enemy.setup_as_charger(wave_number)
		"bomber": enemy.setup_as_bomber(wave_number)
		"priest": enemy.setup_as_priest(wave_number)
		_: enemy.setup_as_minion(wave_number)
	tune_enemy_for_mode(enemy)

func spawn_mini_boss() -> void:
	var mini_boss: EnemyController = EnemyScript.new()
	mini_boss.setup_as_mini_boss()
	mini_boss.max_health *= game.boss_health_multiplier
	mini_boss.health = mini_boss.max_health
	mini_boss.attack_damage *= game.boss_damage_multiplier
	mini_boss.global_position = Vector2(0, -160)
	game._register_enemy(mini_boss)
	game._spawn_effect(mini_boss.global_position, 96.0, Color(0.72, 0.32, 1.0, 0.24), 0.55)

func spawn_boss() -> void:
	var boss: EnemyController = EnemyScript.new()
	boss.setup_as_boss()
	tune_boss_for_mode(boss)
	boss.global_position = Vector2(0, -180)
	game._register_enemy(boss)
	game._spawn_effect(boss.global_position, 120.0, Color(1.0, 0.18, 0.12, 0.20), 0.65)

func tune_enemy_for_mode(enemy: EnemyController) -> void:
	enemy.max_health *= game.enemy_health_multiplier
	enemy.health = enemy.max_health
	enemy.attack_damage *= game.enemy_damage_multiplier
	enemy.projectile_damage *= game.enemy_damage_multiplier
	if enemy.enemy_type == EnemyController.TYPE_CHARGER:
		enemy._charge_damage *= game.enemy_damage_multiplier
	elif enemy.enemy_type == EnemyController.TYPE_BOMBER:
		enemy._bomber_damage *= game.enemy_damage_multiplier
	enemy.attack_interval *= 0.96 if game.local_player_count > 1 else 1.0

func tune_boss_for_mode(boss: EnemyController) -> void:
	boss.max_health *= game.boss_health_multiplier
	boss.health = boss.max_health
	boss.attack_damage *= game.boss_damage_multiplier
	boss.move_speed *= 1.06 if game.local_player_count > 1 else 1.0
	boss.attack_interval *= 0.92 if game.local_player_count > 1 else 1.0

func spawn_boss_reinforcements(boss: EnemyController) -> void:
	var reinforcement_types: Array[String] = ["melee", "melee", "ranged", "shield"]
	if game.local_player_count > 1:
		reinforcement_types.append_array(["melee", "ranged"])
	var offsets := [
		Vector2(-150.0, -90.0), Vector2(150.0, -90.0),
		Vector2(-150.0, 90.0), Vector2(150.0, 90.0),
		Vector2(0.0, -150.0), Vector2(0.0, 150.0),
	]
	for index in range(reinforcement_types.size()):
		var enemy: EnemyController = EnemyScript.new()
		setup_wave_enemy(enemy, reinforcement_types[index])
		enemy.global_position = (boss.global_position + offsets[index]).clamp(game.ARENA_BOUNDS.position, game.ARENA_BOUNDS.end)
		game._register_enemy(enemy)
		game._spawn_effect(enemy.global_position, 46.0, Color(0.92, 0.24, 0.18, 0.28), 0.24)

func spawn_point(index: int, count: int) -> Vector2:
	var side := index % 4
	var lane_index := floori(float(index) / 4.0)
	var lane_center := floori(float(count) / 8.0)
	var lane_offset := float(lane_index - lane_center) * 120.0
	var margin := 44.0
	match side:
		0: return Vector2(clampf(lane_offset, -520.0, 520.0), game.ARENA_BOUNDS.position.y + margin)
		1: return Vector2(game.ARENA_BOUNDS.end.x - margin, clampf(lane_offset, -300.0, 300.0))
		2: return Vector2(clampf(lane_offset, -520.0, 520.0), game.ARENA_BOUNDS.end.y - margin)
		_: return Vector2(game.ARENA_BOUNDS.position.x + margin, clampf(lane_offset, -300.0, 300.0))
