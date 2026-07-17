extends SceneTree

const MainScene := preload("res://scenes/main/main.tscn")
const GameStateScript := preload("res://scripts/core/game_state.gd")
const GameRulesScript := preload("res://scripts/gameplay/game_rules.gd")
const UpgradeCatalogScript := preload("res://scripts/upgrades/upgrade_catalog.gd")

var failures: Array[String] = []
var game: Node

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	Engine.time_scale = 50.0
	game = MainScene.instantiate()
	root.add_child(game)
	await process_frame
	_check_single_layer_map()

	await _check_complete_single_player_run()
	await _check_restart_cleanup()
	await _check_defeat_and_second_restart()
	await _check_wave_timeout()
	await _check_return_to_menu_cleanup()
	await _check_network_upgrade_and_snapshot_sync()

	Engine.time_scale = 1.0
	if failures.is_empty():
		print("PASS: lifecycle checks")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)

func _check_single_layer_map() -> void:
	var water := game.map_root.get_node_or_null("WaterBase") as TextureRect
	var island := game.map_root.get_node_or_null("GrassIsland") as TileMapLayer
	var light_meadow := game.map_root.get_node_or_null("LightMeadowZone") as TileMapLayer
	var dark_meadow := game.map_root.get_node_or_null("DarkMeadowZone") as TileMapLayer
	_expect(water != null and water.texture != null, "single-layer map is missing its tiled water background")
	_expect(island != null and island.get_used_cells().size() >= 500, "single-layer grass island is incomplete")
	_expect(light_meadow != null and not light_meadow.get_used_cells().is_empty(), "light meadow region is missing")
	_expect(dark_meadow != null and not dark_meadow.get_used_cells().is_empty(), "dark meadow region is missing")
	_expect_flat_meadow(light_meadow, "light meadow")
	_expect_flat_meadow(dark_meadow, "dark meadow")
	_expect(_count_map_children("BoundaryBuilding") == 6, "map does not contain the full peripheral settlement")
	_expect(_count_map_children("BoundaryTree") >= 22, "full-map tree line is incomplete")
	_expect(_count_map_children("BoundaryBush") >= 16, "full-map bush clusters are incomplete")
	_expect_map_obstacle_collisions("BoundaryBuilding", 6, true)
	_expect_map_obstacle_collisions("BoundaryTree", 22, true)
	_expect_map_obstacle_collisions("SoftObstacle", 10, false)
	_expect_map_obstacle_collisions("CornerProp", 4, false)
	_expect_rocks_clear_of_trees()
	for child in game.map_root.get_children():
		if not str(child.name).begins_with("BoundaryTree"):
			continue
		var tree := child as Sprite2D
		var expected_frame := Vector2(tree.texture.get_width() / 8.0, tree.texture.get_height())
		_expect(tree.region_rect.size.is_equal_approx(expected_frame), "tree frame includes pixels from an adjacent animation frame: %s" % child.name)

func _expect_rocks_clear_of_trees() -> void:
	var rocks: Array = game.map_root.get_children().filter(func(child): return str(child.name).begins_with("SoftObstacle"))
	var trees: Array = game.map_root.get_children().filter(func(child): return str(child.name).begins_with("BoundaryTree"))
	for rock_value in rocks:
		var rock := rock_value as Sprite2D
		for tree_value in trees:
			var tree := tree_value as Sprite2D
			_expect(not _sprite_bounds(rock).intersects(_sprite_bounds(tree)), "%s overlaps %s" % [rock.name, tree.name])

func _sprite_bounds(sprite: Sprite2D) -> Rect2:
	var display_size := sprite.region_rect.size * sprite.scale.abs()
	return Rect2(sprite.position - display_size * 0.5, display_size).grow(4.0)

func _expect_map_obstacle_collisions(name_prefix: String, expected_count: int, blocks_ranged_attacks: bool) -> void:
	var props: Array = game.map_root.get_children().filter(func(child): return str(child.name).begins_with(name_prefix))
	_expect(props.size() == expected_count, "%s collision check found an unexpected prop count" % name_prefix)
	for prop_value in props:
		var prop := prop_value as Sprite2D
		var body := prop.get_node_or_null("MapObstacleBody") as StaticBody2D
		var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D if body != null else null
		_expect(body != null and (body.collision_layer & (1 << 3)) != 0, "%s is missing its map obstacle body" % prop.name)
		if body != null:
			_expect(((body.collision_layer & (1 << 4)) != 0) == blocks_ranged_attacks, "%s has the wrong ranged attack blocking layer" % prop.name)
		_expect(collision != null and collision.shape is RectangleShape2D, "%s is missing its collision shape" % prop.name)
		if collision != null and collision.shape is RectangleShape2D:
			var rectangle := collision.shape as RectangleShape2D
			_expect(rectangle.size.y >= prop.region_rect.size.y * 0.70, "%s collision only covers its bottom edge" % prop.name)

func _expect_flat_meadow(layer: TileMapLayer, label: String) -> void:
	if layer == null:
		return
	for cell in layer.get_used_cells():
		_expect(layer.get_cell_atlas_coords(cell) == Vector2i(1, 1), "%s uses a raised edge tile" % label)

func _count_map_children(name_prefix: String) -> int:
	var count := 0
	for child in game.map_root.get_children():
		if str(child.name).begins_with(name_prefix):
			count += 1
	return count

func _check_complete_single_player_run() -> void:
	game._start_game(1)
	await process_frame
	_expect(is_equal_approx(GameRulesScript.PLAYER_DAMAGE_GROWTH_PER_WAVE, 0.02), "per-wave player output growth is not exactly two percent")
	_expect(game.wave_index == 0, "single-player run did not start at wave 1")
	_expect(game.players.size() == 1, "single-player run did not create exactly one player")
	_expect(game.game_state == GameStateScript.WAVE_ACTIVE, "first wave is not active")
	_expect(game.wave_time_left > 0.0 and game.wave_time_left <= 120.0, "normal wave did not start with a 120-second limit")
	_expect(game.player_huds[0].get("player") == game.players[0], "player HUD was not bound to the created player")
	var player = game.players[0]
	_expect(player.collision_mask == 1 << 3, "player does not collide with the map obstacle layer")
	await physics_frame
	for obstacle_name in ["SoftObstacle1", "BoundaryTree1", "BoundaryBuilding1"]:
		var obstacle := game.map_root.get_node(obstacle_name) as Sprite2D
		var obstacle_collision := obstacle.get_node("MapObstacleBody/CollisionShape2D") as CollisionShape2D
		player.global_position = obstacle_collision.global_position - Vector2(200.0, 0.0)
		_expect(player.test_move(player.global_transform, Vector2(400.0, 0.0)), "player movement was not blocked by %s" % obstacle_name)
	var enemy: EnemyController = game.enemies[0]
	for blocker_name in ["BoundaryTree1", "BoundaryBuilding1"]:
		var blocker := game.map_root.get_node(blocker_name) as Sprite2D
		var blocker_collision := blocker.get_node("MapObstacleBody/CollisionShape2D") as CollisionShape2D
		player.global_position = blocker_collision.global_position - Vector2(200.0, 0.0)
		enemy.global_position = blocker_collision.global_position + Vector2(200.0, 0.0)
		enemy.health = enemy.max_health
		var projectile = game.combat_manager.fire_player_arrow(player.global_position, Vector2.RIGHT, 5.0, player, 500.0, 1.2)
		projectile._process(1.0)
		_expect(projectile.is_queued_for_deletion(), "%s did not stop a player projectile" % blocker_name)
		_expect(is_equal_approx(enemy.health, enemy.max_health), "player projectile damaged an enemy through %s" % blocker_name)
		enemy._marked_by = null
		game.combat_manager.mark_nearest_enemy(player.global_position, Vector2.RIGHT, 420.0, 8.0, 1.55, player)
		_expect(enemy._marked_by == null, "ranged skill targeted an enemy through %s" % blocker_name)
		await process_frame
	player.global_position = game.ARENA_BOUNDS.end
	game._update_camera()
	_expect(game.camera.global_position.x + game._get_viewport_size().x * 0.5 > game.ARENA_BOUNDS.end.x, "camera does not reveal water beyond the island edge")
	player.global_position = Vector2.ZERO
	game._update_camera()
	var hud: Dictionary = game.player_huds[0]
	var action_icons: Array = hud.get("action_icons", [])
	var action_cooldown_overlays: Array = hud.get("action_cooldown_overlays", [])
	var skill_icons: Array = hud.get("skill_icons", [])
	var cooldown_overlays: Array = hud.get("cooldown_overlays", [])
	_expect(action_icons.size() == 6 and action_icons.all(func(icon): return (icon as TextureRect).texture != null), "player HUD did not load all six action icons")
	_expect(action_cooldown_overlays.size() == 6, "player HUD did not create six vertical cooldown overlays")
	_expect(skill_icons.size() == 3 and skill_icons.all(func(icon): return (icon as TextureRect).texture != null), "player HUD did not load all three profession skill icons")
	_expect(cooldown_overlays.size() == 3, "player HUD did not create three vertical cooldown overlays")
	player._attack_timer = player.attack_cooldown
	game.player_roster.update_hud(0)
	_expect(is_equal_approx((action_cooldown_overlays[0] as ColorRect).anchor_bottom, 1.0), "basic attack cooldown did not cover its icon")
	player._attack_timer = 0.0
	player._secondary_timer = player.SECONDARY_COOLDOWN
	game.player_roster.update_hud(0)
	_expect(is_equal_approx((action_cooldown_overlays[2] as ColorRect).anchor_bottom, 1.0), "secondary cooldown did not cover its icon")
	player._secondary_timer = 0.0
	player._skill_timer = player.skill_cooldown
	game.player_roster.update_hud(0)
	_expect(is_equal_approx((cooldown_overlays[0] as ColorRect).anchor_bottom, 1.0), "Q cooldown did not fully cover its icon when activated")
	player._skill_timer = player.skill_cooldown * 0.5
	game.player_roster.update_hud(0)
	_expect(is_equal_approx((cooldown_overlays[0] as ColorRect).anchor_bottom, 0.5), "Q cooldown overlay did not rise with remaining time")
	player._skill_timer = 0.0
	var skill_badge: Control = game.upgrade_ui.build_badge_preview(UpgradeCatalogScript.BEHAVIOR_POOL[0], Color.WHITE)
	_expect(skill_badge.get_child_count() >= 1 and (skill_badge.get_child(0) as TextureRect).texture != null, "skill upgrade card did not load its profession icon")
	skill_badge.queue_free()
	_check_combat_manager_connections()

	var expected_wave_start_position := Vector2.ZERO
	for expected_wave_index in range(game.wave_manager.wave_count()):
		_expect(game.wave_index == expected_wave_index, "wave index did not advance in order")
		_expect(not game.enemies.is_empty(), "wave started without enemies")
		_expect(game.players[0].global_position.is_equal_approx(expected_wave_start_position), "player did not retain the previous wave-end position")
		var expected_damage_multiplier := 1.0 + float(expected_wave_index) * GameRulesScript.PLAYER_DAMAGE_GROWTH_PER_WAVE
		_expect(is_equal_approx(game.players[0].wave_damage_multiplier, expected_damage_multiplier), "player wave damage growth did not advance with the wave")
		var boss_wave: bool = game.game_state == GameStateScript.BOSS_WAVE
		if boss_wave:
			_expect(game.wave_time_left > 120.0 and game.wave_time_left <= 180.0, "boss wave did not start with a 180-second limit")
		else:
			expected_wave_start_position = Vector2(160.0 + float(expected_wave_index) * 24.0, -96.0)
			game.players[0].global_position = expected_wave_start_position
		await _kill_current_wave()
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
		game.upgrade_selection_input_lock_left = 1.0
		game._select_upgrade(1, upgrades[0])
		_expect(not game._all_required_upgrades_selected(), "upgrade selection accepted input during its one-second safety lock")
		game._process(1.0)
		game._select_upgrade(1, upgrades[0])
		_expect(game._all_required_upgrades_selected(), "selected upgrade was not confirmed")
		var left_click := InputEventMouseButton.new()
		left_click.button_index = MOUSE_BUTTON_LEFT
		left_click.pressed = true
		game._input(left_click)
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

func _check_network_upgrade_and_snapshot_sync() -> void:
	var host := MainScene.instantiate()
	var client := MainScene.instantiate()
	root.add_child(host)
	root.add_child(client)
	await process_frame
	_start_network_test_pair(host, client, ["archer", "mage"])
	await process_frame
	_expect(client.enemies.is_empty(), "client generated enemies before receiving a host snapshot")
	_sync_upgrade_round(host, client, 1, "archer_e_trap")
	_sync_upgrade_round(host, client, 1, "archer_e_execution_trap")
	_sync_upgrade_round(host, client, 2, "mage_e_chain")
	_sync_upgrade_round(host, client, 2, "mage_e_conduction")
	_expect(host.players[0].upgrade_levels == client.players[0].upgrade_levels, "archer trap branch diverged between host and client")
	_expect(host.players[1].upgrade_levels == client.players[1].upgrade_levels, "mage chain branch diverged between host and client")
	_expect(host.players[0].get_upgrade_level("archer_e_mark") == 0, "archer trap sync also applied the mark branch")
	_expect(host.players[1].get_upgrade_level("mage_e_field") == 0, "mage chain sync also applied the field branch")

	host.players[0].global_position = Vector2(125.0, -80.0)
	host.players[0]._skill_timer = 2.5
	host.wave_time_left = 47.5
	host.elapsed_time = 12.25
	host.enemies_defeated = 3
	host.damage_dealt = 456.0
	host.damage_taken = 78.0
	var host_enemy = host.enemies[0]
	host_enemy.global_position = Vector2(-215.0, 115.0)
	host_enemy.health = maxf(1.0, host_enemy.health - 9.0)
	host_enemy.apply_hunter_mark(host.players[0], 8.0, 1.55)
	host.combat_manager.fire_player_arrow(Vector2(-700.0, -400.0), Vector2.LEFT, 12.0, host.players[0])
	host.combat_manager.place_archer_trap(Vector2(40.0, 30.0), Vector2.RIGHT, host.players[0])
	var host_projectile = host.projectile_root.get_child(0)
	var host_area: Dictionary = host.persistent_skill_areas[0]
	var projectile_id := int(host_projectile.network_id)
	var area_id := int(host_area.get("network_id", -1))
	_expect(projectile_id > 0 and area_id > 0 and projectile_id != area_id, "host did not assign stable unique combat entity ids")
	host.network_snapshot_sequence = 7
	var snapshot: Dictionary = host._build_authority_snapshot()
	_expect(client._apply_authority_snapshot(snapshot), "client rejected a valid host snapshot")
	_expect(client.network_last_applied_snapshot == 7, "client did not advance the snapshot sequence")
	_expect(client.players[0].global_position.is_equal_approx(host.players[0].global_position), "host player position was not corrected from snapshot")
	_expect(is_equal_approx(client.players[0]._skill_timer, host.players[0]._skill_timer), "skill cooldown drifted after host snapshot")
	_expect(is_equal_approx(client.wave_time_left, host.wave_time_left), "wave timer drifted after host snapshot")
	_expect(client.enemies_defeated == host.enemies_defeated, "defeated-enemy count drifted after host snapshot")
	var client_enemy = _find_network_enemy(client, host_enemy.network_id)
	_expect(client_enemy != null, "client lost an enemy present in the host snapshot")
	if client_enemy != null:
		_expect(client_enemy.global_position.is_equal_approx(host_enemy.global_position), "enemy position drifted after host snapshot")
		_expect(is_equal_approx(client_enemy.health, host_enemy.health), "enemy health drifted after host snapshot")
		_expect(not client_enemy.authority_enabled, "client enemy continued running authoritative AI")
		_expect(client_enemy.is_marked_by(client.players[0]), "host hunter mark did not synchronize to the client")
	_expect(_find_network_projectile(client, projectile_id) != null, "client did not create the host projectile")
	_expect(_find_network_skill_area(client, area_id) != null, "client did not create the host skill area")
	var client_projectile_count: int = client.projectile_root.get_child_count()
	client.combat_manager.on_player_projectile_attack(Vector2.ZERO, Vector2.RIGHT, 10.0, false, client.players[0])
	_expect(client.projectile_root.get_child_count() == client_projectile_count, "client created a projectile from local combat simulation")
	var stale_snapshot := snapshot.duplicate(true)
	stale_snapshot["sequence"] = 6
	_expect(not client._apply_authority_snapshot(stale_snapshot), "client accepted an out-of-order authority snapshot")
	host_projectile.global_position = Vector2(-500.0, -400.0)
	var client_enemy_position_before_update: Vector2 = client_enemy.global_position
	host_enemy.global_position += Vector2(120.0, 0.0)
	host.network_snapshot_sequence = 8
	var update_snapshot: Dictionary = host._build_authority_snapshot()
	_expect(client._apply_authority_snapshot(update_snapshot), "client rejected combat entity update snapshot")
	var updated_client_projectile = _find_network_projectile(client, projectile_id)
	_expect(updated_client_projectile != null and updated_client_projectile.global_position.is_equal_approx(host_projectile.global_position), "client did not update the host projectile position")
	_expect(client_enemy.authority_target_position.is_equal_approx(host_enemy.global_position), "client enemy did not receive the host interpolation target")
	var distance_before_interpolation: float = client_enemy_position_before_update.distance_to(host_enemy.global_position)
	client_enemy._physics_process(0.05)
	_expect(client_enemy.global_position.distance_to(host_enemy.global_position) < distance_before_interpolation, "client enemy did not interpolate toward the host position")
	host_projectile.queue_free()
	host.combat_manager.remove_persistent_skill_area(host_area)
	host_enemy._mark_left = 0.0
	await process_frame
	host.network_snapshot_sequence = 9
	var removal_snapshot: Dictionary = host._build_authority_snapshot()
	_expect(client._apply_authority_snapshot(removal_snapshot), "client rejected combat entity removal snapshot")
	_expect(_find_network_projectile(client, projectile_id) == null, "client retained a projectile removed by the host")
	_expect(_find_network_skill_area(client, area_id) == null, "client retained a skill area removed by the host")
	_expect(not client_enemy.is_marked_by(client.players[0]), "client retained a hunter mark removed by the host")
	var client_effect_count: int = client.effect_root.get_child_count()
	client._network_show_enemy_telegraph("circle", {
		"origin": Vector2(75.0, -45.0),
		"radius": 120.0,
		"color": Color(1.0, 0.18, 0.10, 0.42),
		"lifetime": 0.8,
	})
	_expect(client.effect_root.get_child_count() == client_effect_count + 1, "client did not render a synchronized instantaneous enemy warning")

	host._clear_run_state()
	client._clear_run_state()
	await process_frame
	await process_frame
	_start_network_test_pair(host, client, ["warrior", "lancer"])
	await process_frame
	_sync_upgrade_round(host, client, 1, "warrior_e_shield")
	_sync_upgrade_round(host, client, 1, "warrior_e_shield_guard")
	_sync_upgrade_round(host, client, 2, "lancer_e_spear")
	_sync_upgrade_round(host, client, 2, "lancer_e_return")
	_expect(host.players[0].upgrade_levels == client.players[0].upgrade_levels, "warrior shield branch diverged between host and client")
	_expect(host.players[1].upgrade_levels == client.players[1].upgrade_levels, "lancer spear branch diverged between host and client")
	host.combat_manager.start_blade_ultimate(host.players[0], 20.0, 6.0)
	host.network_snapshot_sequence = 1
	var ultimate_snapshot: Dictionary = host._build_authority_snapshot()
	_expect(client._apply_authority_snapshot(ultimate_snapshot), "client rejected host ultimate state")
	var client_ultimate: Dictionary = client.ultimate_states[client.players[0].get_instance_id()]
	_expect(float(client_ultimate.get("duration_left", 0.0)) > 0.0, "client did not activate the host warrior ultimate")
	_expect((client_ultimate.get("root") as Node2D).visible, "client warrior ultimate presentation stayed hidden")

	host._clear_run_state()
	client._clear_run_state()
	await process_frame
	await process_frame
	_start_network_test_pair(host, client, ["warrior", "lancer"])
	await process_frame
	_expect(host.players.all(func(player): return (player as PlayerController).upgrade_levels.is_empty()), "host restart retained upgrades from the previous network run")
	_expect(client.players.all(func(player): return (player as PlayerController).upgrade_levels.is_empty()), "client restart retained upgrades from the previous network run")
	host.queue_free()
	client.queue_free()
	await process_frame

func _start_network_test_pair(host: Node, client: Node, character_ids: Array) -> void:
	host.network_mode = "host"
	host.local_peer_player_index = 1
	host.selected_character_ids = character_ids.duplicate()
	host._start_game(2)
	client.network_mode = "client"
	client.local_peer_player_index = 2
	client.selected_character_ids = character_ids.duplicate()
	client._start_game(2)

func _sync_upgrade_round(host: Node, client: Node, player_index: int, upgrade_id: String) -> void:
	var upgrade := _find_behavior_upgrade(upgrade_id)
	_expect(not upgrade.is_empty(), "missing network-sync upgrade: %s" % upgrade_id)
	if upgrade.is_empty():
		return
	for target_game in [host, client]:
		var slot: Dictionary = target_game._get_local_player_slot(player_index)
		slot["upgrades"] = [upgrade.duplicate(true)]
		slot["selected"] = false
		slot["selection_pending"] = false
	_expect(host._apply_confirmed_network_upgrade(player_index, 0), "host rejected synchronized upgrade: %s" % upgrade_id)
	_expect(client._apply_confirmed_network_upgrade(player_index, 0), "client rejected synchronized upgrade: %s" % upgrade_id)

func _find_behavior_upgrade(upgrade_id: String) -> Dictionary:
	for upgrade in UpgradeCatalogScript.BEHAVIOR_POOL:
		if str((upgrade as Dictionary).get("id", "")) == upgrade_id:
			return upgrade as Dictionary
	return {}

func _find_network_enemy(target_game: Node, network_id: int):
	for enemy in target_game.enemies:
		if is_instance_valid(enemy) and enemy.network_id == network_id:
			return enemy
	return null

func _find_network_projectile(target_game: Node, network_id: int):
	for projectile in target_game.projectile_root.get_children():
		if is_instance_valid(projectile) and not projectile.is_queued_for_deletion() and int(projectile.get("network_id")) == network_id:
			return projectile
	return null

func _find_network_skill_area(target_game: Node, network_id: int):
	for area in target_game.persistent_skill_areas:
		if int((area as Dictionary).get("network_id", -1)) == network_id:
			return area
	return null

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
	var cleanup_passes := 0
	while not game.enemies.is_empty() and cleanup_passes < 6:
		for enemy in game.enemies.duplicate():
			if is_instance_valid(enemy):
				if enemy.is_boss:
					enemy._boss_invulnerability_left = 0.0
				enemy.apply_damage(enemy.max_health * 10.0, enemy.global_position, 0.0)
		cleanup_passes += 1
		await process_frame

func _check_combat_manager_connections() -> void:
	var player = game.players[0]
	var enemy = game.enemies[0]
	enemy.global_position = player.global_position + Vector2(48.0, 0.0)
	var health_before: float = enemy.health
	player.basic_attack_requested.emit(player.global_position, Vector2.RIGHT, 80.0, 40.0, 5.0, false)
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
	_expect(not game.epic_upgrade_seen, "%s did not reset the epic upgrade guarantee" % context)
	_expect(game.enemies_defeated == 0, "%s did not reset the defeated-enemy count" % context)
	_expect(is_zero_approx(game.damage_dealt), "%s did not reset dealt damage" % context)
	_expect(is_zero_approx(game.damage_taken), "%s did not reset taken damage" % context)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
