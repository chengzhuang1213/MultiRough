extends RefCounted
class_name AuthorityContract

const EVENT_PLAYER_INPUT := "player_input"
const EVENT_PLAYER_ACTION := "player_action"
const EVENT_UPGRADE_CHOICE := "upgrade_choice"
const EVENT_START_NEXT_WAVE := "start_next_wave"

const SNAPSHOT_VERSION := 2

static func make_player_state(player_id: int, position: Vector2, health: float, maximum_health: float, dead: bool, cooldowns: Dictionary = {}) -> Dictionary:
	return {
		"player_id": player_id,
		"position": position,
		"health": health,
		"maximum_health": maximum_health,
		"dead": dead,
		"cooldowns": cooldowns.duplicate(true),
	}

static func make_enemy_state(enemy_id: int, enemy_type: String, position: Vector2, health: float, maximum_health: float) -> Dictionary:
	return {
		"enemy_id": enemy_id,
		"enemy_type": enemy_type,
		"position": position,
		"health": health,
		"maximum_health": maximum_health,
	}

static func make_snapshot(sequence: int, phase: String, wave_index: int, players: Array, enemies: Array, wave_time_left: float = 0.0, elapsed_time: float = 0.0, metrics: Dictionary = {}) -> Dictionary:
	return {
		"version": SNAPSHOT_VERSION,
		"sequence": sequence,
		"phase": phase,
		"wave_index": wave_index,
		"wave_time_left": wave_time_left,
		"elapsed_time": elapsed_time,
		"players": players.duplicate(true),
		"enemies": enemies.duplicate(true),
		"metrics": metrics.duplicate(true),
	}

static func validate_snapshot(snapshot: Dictionary) -> bool:
	for key in ["version", "sequence", "phase", "wave_index", "wave_time_left", "elapsed_time", "players", "enemies", "metrics"]:
		if not snapshot.has(key):
			return false
	if int(snapshot["version"]) != SNAPSHOT_VERSION or int(snapshot["sequence"]) < 0:
		return false
	if typeof(snapshot["players"]) != TYPE_ARRAY or typeof(snapshot["enemies"]) != TYPE_ARRAY or typeof(snapshot["metrics"]) != TYPE_DICTIONARY:
		return false
	var player_ids := {}
	for player_state in snapshot["players"] as Array:
		for key in ["player_id", "position", "health", "maximum_health", "dead", "cooldowns"]:
			if not (player_state as Dictionary).has(key):
				return false
		var player_id := int((player_state as Dictionary)["player_id"])
		if player_id <= 0 or player_ids.has(player_id):
			return false
		player_ids[player_id] = true
	var enemy_ids := {}
	for enemy_state in snapshot["enemies"] as Array:
		for key in ["enemy_id", "enemy_type", "position", "health", "maximum_health"]:
			if not (enemy_state as Dictionary).has(key):
				return false
		var enemy_id := int((enemy_state as Dictionary)["enemy_id"])
		if enemy_id <= 0 or enemy_ids.has(enemy_id):
			return false
		enemy_ids[enemy_id] = true
	return true
