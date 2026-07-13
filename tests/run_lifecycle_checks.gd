extends SceneTree

const MainScene := preload("res://scenes/main/main.tscn")
const GameStateScript := preload("res://scripts/core/game_state.gd")

var failures: Array[String] = []
var game: Node

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	Engine.time_scale = 50.0
	game = MainScene.instantiate()
	root.add_child(game)
	await process_frame

	await _check_complete_single_player_run()
	await _check_restart_cleanup()
	await _check_defeat_and_second_restart()
	await _check_wave_timeout()
	await _check_return_to_menu_cleanup()

	Engine.time_scale = 1.0
	if failures.is_empty():
		print("PASS: lifecycle checks")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)

func _check_complete_single_player_run() -> void:
	game._start_game(1)
	await process_frame
	_expect(game.wave_index == 0, "single-player run did not start at wave 1")
	_expect(game.players.size() == 1, "single-player run did not create exactly one player")
	_expect(game.game_state == GameStateScript.WAVE_ACTIVE, "first wave is not active")
	_expect(game.wave_time_left > 0.0 and game.wave_time_left <= 60.0, "normal wave did not start with a 60-second limit")
	_expect(game.player_huds[0].get("player") == game.players[0], "player HUD was not bound to the created player")
	_check_combat_manager_connections()

	for expected_wave_index in range(game.wave_manager.wave_count()):
		_expect(game.wave_index == expected_wave_index, "wave index did not advance in order")
		_expect(not game.enemies.is_empty(), "wave started without enemies")
		var boss_wave: bool = game.game_state == GameStateScript.BOSS_WAVE
		if boss_wave:
			_expect(game.wave_time_left > 60.0 and game.wave_time_left <= 120.0, "boss wave did not start with a 120-second limit")
		_kill_current_wave()
		await process_frame
		if boss_wave:
			_expect(game.game_state == GameStateScript.VICTORY, "defeating the boss did not enter victory")
			break

		_expect(game.game_state in [GameStateScript.COUNTDOWN, GameStateScript.UPGRADE_SELECT], "clearing a normal wave did not enter countdown or upgrade selection")
		if game.game_state == GameStateScript.COUNTDOWN:
			await create_timer(1.05).timeout
			await process_frame
		_expect(game.game_state == GameStateScript.UPGRADE_SELECT, "countdown did not enter upgrade selection")
		_expect(game.local_player_slots.size() == 1, "upgrade selection lost the player slot")
		var upgrades: Array = game.local_player_slots[0].get("upgrades", [])
		_expect(upgrades.size() == 3, "upgrade selection did not provide three choices")
		if upgrades.is_empty():
			return
		game._select_upgrade(1, upgrades[0])
		_expect(game._all_required_upgrades_selected(), "selected upgrade was not confirmed")
		game._start_next_wave_for_all_peers()
		await process_frame

	_expect(game.restart_button.visible, "victory did not expose restart")
	_expect(game.enemies.is_empty(), "victory left enemies in the tracked list")
	_expect(game.projectile_root.get_child_count() == 0, "victory left projectiles behind")
	_expect(game.persistent_skill_areas.is_empty(), "victory left persistent skill areas behind")

func _check_restart_cleanup() -> void:
	game._on_restart_pressed()
	await process_frame
	await process_frame
	_expect_clean_lobby("restart after victory")

func _check_defeat_and_second_restart() -> void:
	game._start_game(1)
	await process_frame
	_expect(game.players.size() == 1, "second run did not create a player")
	var active_player = game.players[0]
	active_player.apply_damage(active_player.max_health * 2.0)
	await process_frame
	_expect(game.game_state == GameStateScript.DEFEAT, "lethal player damage did not enter defeat")
	_expect(game.enemies.is_empty(), "defeat left enemies in the tracked list")
	_expect(game.projectile_root.get_child_count() == 0, "defeat left projectiles behind")
	_expect(game.persistent_skill_areas.is_empty(), "defeat left persistent skill areas behind")

	game._on_restart_pressed()
	await process_frame
	await process_frame
	_expect_clean_lobby("restart after defeat")

func _check_return_to_menu_cleanup() -> void:
	game._start_game(1)
	await process_frame
	_expect(game.return_to_menu_button.visible, "active run did not show the return-to-menu button")
	game._on_return_to_menu_pressed()
	await process_frame
	await process_frame
	_expect_clean_lobby("return-to-menu action")
	_expect(not game.return_to_menu_button.visible, "lobby still showed the return-to-menu button")

func _check_wave_timeout() -> void:
	game._start_game(1)
	await process_frame
	game.wave_time_left = 0.01
	game._process(0.02)
	_expect(game.game_state == GameStateScript.DEFEAT, "wave timeout did not end the run in defeat")
	_expect(game.enemies.is_empty(), "wave timeout left enemies behind")
	game._on_restart_pressed()
	await process_frame
	await process_frame
	_expect_clean_lobby("restart after wave timeout")

func _kill_current_wave() -> void:
	for enemy in game.enemies.duplicate():
		if is_instance_valid(enemy):
			enemy.apply_damage(enemy.health + 1.0)

func _check_combat_manager_connections() -> void:
	var player = game.players[0]
	var enemy = game.enemies[0]
	enemy.global_position = player.global_position + Vector2(48.0, 0.0)
	var health_before: float = enemy.health
	player.basic_attack_requested.emit(player.global_position, Vector2.RIGHT, 80.0, 40.0, 5.0)
	_expect(enemy.health < health_before, "player attack signal did not reach the combat manager")
	game.combat_manager.add_arrow_rain(player.global_position, Vector2.RIGHT, 10.0, 1.0, player)
	_expect(game.persistent_skill_areas.size() == 1, "combat manager did not register a persistent skill area")
	game.combat_manager.clear_persistent_skill_areas()
	_expect(game.persistent_skill_areas.is_empty(), "combat manager did not clear persistent skill areas")

func _expect_clean_lobby(context: String) -> void:
	_expect(game.game_state == GameStateScript.LOBBY, "%s did not return to lobby" % context)
	_expect(game.players.is_empty(), "%s left tracked players behind" % context)
	_expect(game.enemies.is_empty(), "%s left tracked enemies behind" % context)
	_expect(game.local_player_slots.is_empty(), "%s left upgrade slots behind" % context)
	_expect(game.ultimate_states.is_empty(), "%s left ultimate states behind" % context)
	_expect(game.persistent_skill_areas.is_empty(), "%s left persistent skill areas behind" % context)
	_expect(game.projectile_root.get_child_count() == 0, "%s left projectile nodes behind" % context)
	_expect(game.effect_root.get_child_count() == 0, "%s left effect nodes behind" % context)
	_expect(game.wave_index == -1, "%s did not reset the wave index" % context)
	_expect(is_zero_approx(game.elapsed_time), "%s did not reset elapsed time" % context)
	_expect(is_zero_approx(game.wave_time_left), "%s did not reset wave time" % context)
	_expect(game.enemies_defeated == 0, "%s did not reset the defeated-enemy count" % context)
	_expect(is_zero_approx(game.damage_dealt), "%s did not reset dealt damage" % context)
	_expect(is_zero_approx(game.damage_taken), "%s did not reset taken damage" % context)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
