extends SceneTree

const MainScene := preload("res://scenes/main/main.tscn")
const GameStateScript := preload("res://scripts/core/game_state.gd")

const CHARACTERS := ["warrior", "archer", "mage", "lancer"]
const PRIORITY := {
	"priest": 7000.0,
	"bomber": 6000.0,
	"charger": 5000.0,
	"ranged": 4000.0,
	"shield": 3000.0,
	"heavy": 2000.0,
	"boss": 1500.0,
	"melee": 1000.0,
}

var runs_per_character := 2
var simulation_speed := 12.0
var report_path := "res://tests/balance_report.json"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_parse_arguments()
	Engine.time_scale = simulation_speed
	var results: Array = []
	for character_id in CHARACTERS:
		for run_index in range(runs_per_character):
			var run_seed := 73000 + CHARACTERS.find(character_id) * 1000 + run_index
			var result: Dictionary = await _run_single(character_id, run_index + 1, run_seed)
			results.append(result)
			print("SIM %s #%d: %s, wave %d, %.1fs, damage %.0f, taken %.0f" % [
				character_id,
				run_index + 1,
				"WIN" if bool(result.get("victory", false)) else "LOSS",
				int(result.get("reached_wave", 0)),
				float(result.get("combat_time", 0.0)),
				float(result.get("damage_dealt", 0.0)),
				float(result.get("damage_taken", 0.0)),
			])
	Engine.time_scale = 1.0
	var report := {
		"runs_per_character": runs_per_character,
		"simulation_speed": simulation_speed,
		"method": "Real main scene and enemy AI; scripted movement and direct deterministic skill execution.",
		"limitations": "Useful for numeric screening only. It does not measure visual readability, input feel, or human reaction time.",
		"summary": _build_summary(results),
		"runs": results,
	}
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null:
		printerr("FAIL: could not write %s" % report_path)
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("PASS: balance simulation wrote %s" % report_path)
	quit(0)

func _parse_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--runs="):
			runs_per_character = maxi(1, int(argument.trim_prefix("--runs=")))
		elif argument.begins_with("--speed="):
			simulation_speed = clampf(float(argument.trim_prefix("--speed=")), 1.0, 20.0)
		elif argument.begins_with("--output="):
			var requested_path: String = argument.trim_prefix("--output=")
			report_path = requested_path if requested_path.begins_with("res://") else "res://" + requested_path

func _run_single(character_id: String, run_number: int, run_seed: int) -> Dictionary:
	seed(run_seed)
	var game := MainScene.instantiate()
	root.add_child(game)
	await process_frame
	game.selected_character_ids = [character_id, character_id]
	game._start_game(1)
	await process_frame
	var player: PlayerController = game.players[0]
	player.external_input_enabled = true
	player.use_mouse_aim = false
	var timers := {"basic": 0.0, "secondary": 0.0, "q": 0.0, "e": 0.0, "f": 0.0}
	var chosen_upgrades: Array[String] = []
	var wave_results: Array = []
	var active_wave := -1
	var wave_start_time := 0.0
	var wave_start_damage := 0.0
	var wave_start_taken := 0.0
	var frames := 0
	while game.game_state not in [GameStateScript.VICTORY, GameStateScript.DEFEAT] and frames < 18000:
		var combat_active: bool = game.game_state in [GameStateScript.WAVE_ACTIVE, GameStateScript.BOSS_WAVE]
		if combat_active:
			if active_wave != game.wave_index:
				active_wave = game.wave_index
				wave_start_time = game.elapsed_time
				wave_start_damage = game.damage_dealt
				wave_start_taken = game.damage_taken
			if not player.is_dead:
				_drive_bot(game, player, timers)
		else:
			player.apply_external_input({"move": Vector2.ZERO, "aim": Vector2.RIGHT})
			if active_wave >= 0:
				wave_results.append(_finish_wave_record(game, active_wave, wave_start_time, wave_start_damage, wave_start_taken))
				active_wave = -1
			if game.game_state == GameStateScript.UPGRADE_SELECT:
				var slot: Dictionary = game.local_player_slots[0]
				if not bool(slot.get("selected", false)):
					var upgrades: Array = slot.get("upgrades", [])
					if not upgrades.is_empty():
						var choice: Dictionary = _choose_upgrade(upgrades, character_id)
						chosen_upgrades.append(str(choice.get("id", "")))
						game._select_upgrade(1, choice)
				if game._all_required_upgrades_selected():
					game._start_next_wave_for_all_peers()
			elif game.game_state == GameStateScript.REST:
				game._on_rest_ready_pressed()
		await process_frame
		frames += 1
	if active_wave >= 0:
		wave_results.append(_finish_wave_record(game, active_wave, wave_start_time, wave_start_damage, wave_start_taken))
	var result := {
		"character": character_id,
		"run": run_number,
		"seed": run_seed,
		"victory": game.game_state == GameStateScript.VICTORY,
		"reached_wave": game.wave_index + 1,
		"combat_time": snappedf(game.elapsed_time, 0.01),
		"damage_dealt": snappedf(game.damage_dealt, 0.01),
		"damage_taken": snappedf(game.damage_taken, 0.01),
		"enemies_defeated": game.enemies_defeated,
		"health_remaining": snappedf(player.health, 0.01),
		"upgrades": chosen_upgrades,
		"waves": wave_results,
		"frame_guard_hit": frames >= 18000,
	}
	game.queue_free()
	await process_frame
	await process_frame
	return result

func _drive_bot(game: Node, player: PlayerController, timers: Dictionary) -> void:
	var target := _choose_target(game, player)
	if target == null:
		player.apply_external_input({"move": Vector2.ZERO, "aim": Vector2.RIGHT})
		return
	var offset: Vector2 = target.global_position - player.global_position
	var distance := offset.length()
	var aim := offset.normalized() if distance > 1.0 else Vector2.RIGHT
	var desired_distance := 72.0 if player.character_id in ["warrior", "lancer"] else (245.0 if player.character_id == "archer" else 205.0)
	var move := Vector2.ZERO
	if distance > desired_distance + 35.0:
		move = aim
	elif distance < desired_distance - 30.0:
		move = -aim
	else:
		var orbit_sign := -1.0 if int(game.elapsed_time / 2.5) % 2 == 0 else 1.0
		move = Vector2(-aim.y, aim.x) * orbit_sign
	var nearest := _nearest_enemy(game, player.global_position)
	var dash := false
	if nearest != null:
		var danger_distance: float = nearest.global_position.distance_to(player.global_position)
		if danger_distance < 82.0:
			var escape := (player.global_position - nearest.global_position).normalized()
			move = (escape + Vector2(-escape.y, escape.x) * 0.30).normalized()
			dash = player.get_dash_ready()
	var now: float = game.elapsed_time
	var secondary_pressed := player.character_id != "warrior" and now >= float(timers["secondary"])
	if secondary_pressed:
		timers["secondary"] = now + PlayerController.SECONDARY_COOLDOWN
	player.apply_external_input({
		"move": move,
		"aim": aim,
		"aim_target": target.global_position,
		"dash": dash,
		"defend": (player.character_id == "warrior" and distance < 68.0) or secondary_pressed,
	})
	if now >= float(timers["basic"]):
		_use_basic(game, player, target, aim, distance)
		timers["basic"] = now + player.attack_cooldown
	if now >= float(timers["q"]):
		_use_q(game, player, target, aim)
		timers["q"] = now + player.skill_cooldown
	if now >= float(timers["e"]):
		var fan_damage := player.roll_damage_context(player.fan_skill_damage)
		game.combat_manager.on_player_fan_skill(player.global_position, aim, player.fan_skill_length, player.fan_skill_half_width, float(fan_damage["amount"]), bool(fan_damage["is_critical"]), player)
		timers["e"] = now + player.fan_skill_cooldown
	if now >= float(timers["f"]):
		var ultimate_damage := player.roll_damage_context(player.attack_damage * 1.5 * player.ultimate_damage_multiplier)
		game.combat_manager.on_player_ultimate_skill(player.global_position, aim, float(ultimate_damage["amount"]), player.ultimate_duration, bool(ultimate_damage["is_critical"]), player)
		timers["f"] = now + player.ultimate_cooldown

func _use_basic(game: Node, player: PlayerController, target: EnemyController, aim: Vector2, distance: float) -> void:
	var damage_context := player.roll_damage_context(player.attack_damage)
	var damage := float(damage_context["amount"])
	var is_critical := bool(damage_context["is_critical"])
	if player.character_id == "mage":
		if distance <= 650.0 and randf() <= 0.90:
			game.combat_manager.damage_enemies_in_radius(target.global_position, 70.0, damage, player, is_critical)
	elif player.character_id == "archer":
		if distance <= 650.0 and randf() <= 0.90:
			game.combat_manager.damage_enemy(target, damage, player, player.global_position, player.attack_knockback, true, true, false, is_critical)
	else:
		game.combat_manager.on_player_basic_attack(player.global_position, aim, player.attack_range, player.attack_half_width, damage, is_critical, player)

func _use_q(game: Node, player: PlayerController, target: EnemyController, aim: Vector2) -> void:
	var damage_context := player.roll_damage_context(player.skill_damage)
	var damage := float(damage_context["amount"])
	var is_critical := bool(damage_context["is_critical"])
	if player.character_id == "archer":
		if player.get_upgrade_level("archer_q_damage") > 0:
			damage *= 1.25
		game.combat_manager.damage_enemy(target, damage, player, player.global_position, player.attack_knockback, true, true, false, is_critical)
	elif player.character_id == "mage":
		var radius := maxf(72.0, player.skill_half_width * 1.8)
		if player.get_upgrade_level("mage_q_radius") > 0:
			radius *= 1.20
		if player.get_upgrade_level("mage_q_damage") > 0:
			damage *= 1.20
		game.combat_manager._mage_fireball_explode(target.global_position, damage, player, radius, is_critical)
	else:
		game.combat_manager.on_player_active_skill(player.global_position, aim, player.skill_length, player.skill_half_width, damage, is_critical, player)

func _choose_target(game: Node, player: PlayerController) -> EnemyController:
	var best: EnemyController
	var best_score: float = -INF
	for enemy in game.enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		var score: float = float(PRIORITY.get(enemy.enemy_type, 0.0)) - enemy.global_position.distance_to(player.global_position)
		if score > best_score:
			best = enemy
			best_score = score
	return best

func _nearest_enemy(game: Node, origin: Vector2) -> EnemyController:
	var best: EnemyController
	var best_distance: float = INF
	for enemy in game.enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		var distance: float = enemy.global_position.distance_to(origin)
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best

func _choose_upgrade(upgrades: Array, character_id: String) -> Dictionary:
	var best: Dictionary = upgrades[0]
	var best_score: float = -INF
	for upgrade in upgrades:
		var candidate := upgrade as Dictionary
		var stat := str(candidate.get("stat", ""))
		var score: float = randf_range(0.0, 8.0)
		if stat == "behavior_upgrade" and str(candidate.get("character_id", "")) == character_id:
			score += 30.0
		elif stat in ["attack_damage", "skill_damage", "critical_chance"]:
			score += 24.0
		elif stat.contains("cooldown"):
			score += 21.0
		elif stat in ["lifesteal", "max_health"]:
			score += 17.0
		elif stat in ["attack_range", "move_speed"]:
			score += 12.0
		if score > best_score:
			best = candidate
			best_score = score
	return best

func _finish_wave_record(game: Node, wave_index: int, start_time: float, start_damage: float, start_taken: float) -> Dictionary:
	return {
		"wave": wave_index + 1,
		"time": snappedf(game.elapsed_time - start_time, 0.01),
		"damage": snappedf(game.damage_dealt - start_damage, 0.01),
		"damage_taken": snappedf(game.damage_taken - start_taken, 0.01),
		"cleared": game.game_state != GameStateScript.DEFEAT,
	}

func _build_summary(results: Array) -> Dictionary:
	var summary := {}
	for character_id in CHARACTERS:
		var character_runs: Array = results.filter(func(result) -> bool: return str(result.get("character", "")) == character_id)
		var wins := 0
		var time_total := 0.0
		var damage_total := 0.0
		var taken_total := 0.0
		var reached_wave_total := 0.0
		for result in character_runs:
			wins += int(bool(result.get("victory", false)))
			time_total += float(result.get("combat_time", 0.0))
			damage_total += float(result.get("damage_dealt", 0.0))
			taken_total += float(result.get("damage_taken", 0.0))
			reached_wave_total += float(result.get("reached_wave", 0))
		var count := maxf(1.0, float(character_runs.size()))
		summary[character_id] = {
			"wins": wins,
			"runs": character_runs.size(),
			"win_rate": snappedf(float(wins) / count, 0.001),
			"average_combat_time": snappedf(time_total / count, 0.01),
			"average_damage": snappedf(damage_total / count, 0.01),
			"average_damage_taken": snappedf(taken_total / count, 0.01),
			"average_reached_wave": snappedf(reached_wave_total / count, 0.01),
		}
	return summary
