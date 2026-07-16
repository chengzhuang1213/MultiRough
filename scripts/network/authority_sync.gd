extends RefCounted
class_name AuthoritySync

const AuthorityContractScript := preload("res://scripts/network/authority_contract.gd")
const EnemyScript := preload("res://scripts/enemy/enemy_controller.gd")
const PlayerProjectileScript := preload("res://scripts/projectiles/player_projectile.gd")
const EnemyProjectileScript := preload("res://scripts/projectiles/enemy_projectile.gd")

var game: Node

func _init(game_node: Node) -> void:
	game = game_node

func build_snapshot() -> Dictionary:
	var player_states: Array = []
	for player_index in range(game.players.size()):
		var target_player := game.players[player_index] as PlayerController
		if target_player == null or not is_instance_valid(target_player):
			continue
		player_states.append(AuthorityContractScript.make_player_state(
			player_index + 1,
			target_player.global_position,
			target_player.health,
			target_player.max_health,
			target_player.is_dead,
			target_player.make_authority_cooldowns()
		))
	var enemy_states: Array = []
	for enemy in game.enemies:
		if is_instance_valid(enemy):
			enemy_states.append(enemy.make_authority_state(
				game.get_player_network_id(enemy._marked_by),
				game.get_player_network_id(enemy._guaranteed_arrow_crit_by)
			))
	var projectile_states: Array = []
	for projectile in game.projectile_root.get_children():
		if is_instance_valid(projectile) and not projectile.is_queued_for_deletion() and projectile.has_method("make_authority_state"):
			projectile_states.append(projectile.make_authority_state())
	return AuthorityContractScript.make_snapshot(
		game.network_snapshot_sequence,
		game.game_state,
		game.wave_index,
		player_states,
		enemy_states,
		game.wave_time_left,
		game.elapsed_time,
		{"enemies_defeated": game.enemies_defeated, "damage_dealt": game.damage_dealt, "damage_taken": game.damage_taken},
		projectile_states,
		game.combat_manager.make_authority_skill_area_states(),
		game.combat_manager.make_authority_ultimate_states()
	)

func apply_snapshot(snapshot: Dictionary) -> bool:
	if not AuthorityContractScript.validate_snapshot(snapshot):
		return false
	var sequence := int(snapshot.get("sequence", -1))
	if sequence <= game.network_last_applied_snapshot:
		return false
	game.network_last_applied_snapshot = sequence
	game.wave_index = int(snapshot.get("wave_index", game.wave_index))
	game.wave_time_left = maxf(0.0, float(snapshot.get("wave_time_left", game.wave_time_left)))
	game.elapsed_time = maxf(0.0, float(snapshot.get("elapsed_time", game.elapsed_time)))
	var authority_phase := str(snapshot.get("phase", game.game_state))
	if authority_phase == game.GameStateScript.VICTORY and game.game_state != game.GameStateScript.VICTORY:
		game._enter_victory()
	elif authority_phase == game.GameStateScript.DEFEAT and game.game_state != game.GameStateScript.DEFEAT:
		game._enter_defeat("房主判定失败")
	elif authority_phase in [game.GameStateScript.WAVE_ACTIVE, game.GameStateScript.BOSS_WAVE, game.GameStateScript.COUNTDOWN]:
		game.game_state = authority_phase
	for player_state in snapshot.get("players", []) as Array:
		var target_player: PlayerController = game._get_network_player(int((player_state as Dictionary).get("player_id", 0))) as PlayerController
		if target_player != null and is_instance_valid(target_player):
			target_player.apply_authority_state(player_state as Dictionary)
	apply_enemy_states(snapshot.get("enemies", []) as Array)
	apply_projectile_states(snapshot.get("projectiles", []) as Array)
	game.combat_manager.apply_authority_skill_area_states(snapshot.get("skill_areas", []) as Array)
	game.combat_manager.apply_authority_ultimate_states(snapshot.get("ultimates", []) as Array)
	var metrics: Dictionary = snapshot.get("metrics", {}) as Dictionary
	game.enemies_defeated = int(metrics.get("enemies_defeated", game.enemies_defeated))
	game.damage_dealt = float(metrics.get("damage_dealt", game.damage_dealt))
	game.damage_taken = float(metrics.get("damage_taken", game.damage_taken))
	return true

func apply_enemy_states(enemy_states: Array) -> void:
	var existing_by_id := {}
	for enemy in game.enemies:
		if is_instance_valid(enemy) and enemy.network_id > 0:
			existing_by_id[enemy.network_id] = enemy
	var authority_ids := {}
	for state in enemy_states:
		var enemy_state := state as Dictionary
		var enemy_id := int(enemy_state.get("enemy_id", -1))
		authority_ids[enemy_id] = true
		var enemy: EnemyController = existing_by_id.get(enemy_id) as EnemyController
		if enemy == null or not is_instance_valid(enemy):
			enemy = create_enemy(enemy_state)
		enemy.apply_authority_state(enemy_state)
		enemy.apply_authority_owners(
			game._get_network_player(int(enemy_state.get("marked_by_player_id", 0))),
			game._get_network_player(int(enemy_state.get("guaranteed_crit_player_id", 0)))
		)
		game.combat_manager.sync_authority_mark_visual(enemy, int(enemy_state.get("marked_by_player_id", 0)) > 0, float(enemy_state.get("mark_left", 0.0)))
	for enemy in game.enemies.duplicate():
		if is_instance_valid(enemy) and not authority_ids.has(enemy.network_id):
			game.enemies.erase(enemy)
			enemy.queue_free()

func apply_projectile_states(projectile_states: Array) -> void:
	var existing_by_id := {}
	for projectile in game.projectile_root.get_children():
		if is_instance_valid(projectile) and int(projectile.get("network_id")) > 0:
			existing_by_id[int(projectile.get("network_id"))] = projectile
	var authority_ids := {}
	for raw_state in projectile_states:
		var state := raw_state as Dictionary
		var entity_id := int(state.get("entity_id", -1))
		authority_ids[entity_id] = true
		var projectile: Node = existing_by_id.get(entity_id) as Node
		if projectile == null or not is_instance_valid(projectile):
			projectile = create_projectile(state)
		projectile.apply_authority_state(state)
	for projectile in game.projectile_root.get_children():
		if is_instance_valid(projectile) and not authority_ids.has(int(projectile.get("network_id"))):
			projectile.queue_free()

func create_projectile(state: Dictionary) -> Node:
	var projectile: Node
	if str(state.get("type", "player")) == "enemy":
		var enemy_projectile = EnemyProjectileScript.new()
		enemy_projectile.authority_presentation_only = true
		enemy_projectile.direction = state.get("direction", Vector2.RIGHT) as Vector2
		enemy_projectile.target = game._get_network_player(int(state.get("target_player_id", 0)))
		projectile = enemy_projectile
	else:
		var player_projectile = PlayerProjectileScript.new()
		player_projectile.authority_presentation_only = true
		player_projectile.direction = state.get("direction", Vector2.RIGHT) as Vector2
		player_projectile.visual_texture_path = str(state.get("visual_texture_path", ""))
		player_projectile.visual_size = state.get("visual_size", Vector2.ZERO) as Vector2
		player_projectile.visual_additive = bool(state.get("visual_additive", false))
		player_projectile.pierces_enemies = bool(state.get("pierces_enemies", false))
		projectile = player_projectile
	game.projectile_root.add_child(projectile)
	return projectile

func create_enemy(state: Dictionary) -> EnemyController:
	var enemy: EnemyController = EnemyScript.new()
	var enemy_type := str(state.get("enemy_type", "melee"))
	if enemy_type == "boss":
		enemy.setup_as_boss()
		game._tune_boss_for_mode(enemy)
	else:
		game._setup_wave_enemy(enemy, enemy_type)
	game._register_enemy(enemy, int(state.get("enemy_id", -1)))
	return enemy
