extends RefCounted
class_name AuthorityContract

const EVENT_PLAYER_INPUT := "player_input"
const EVENT_PLAYER_ACTION := "player_action"
const EVENT_UPGRADE_CHOICE := "upgrade_choice"
const EVENT_START_NEXT_WAVE := "start_next_wave"

const SNAPSHOT_VERSION := 1

static func make_player_state(player_id: int, position: Vector2, health: float, maximum_health: float, dead: bool) -> Dictionary:
	return {
		"player_id": player_id,
		"position": position,
		"health": health,
		"maximum_health": maximum_health,
		"dead": dead,
	}

static func make_enemy_state(enemy_id: int, enemy_type: String, position: Vector2, health: float, maximum_health: float) -> Dictionary:
	return {
		"enemy_id": enemy_id,
		"enemy_type": enemy_type,
		"position": position,
		"health": health,
		"maximum_health": maximum_health,
	}

static func make_snapshot(sequence: int, phase: String, wave_index: int, players: Array, enemies: Array) -> Dictionary:
	return {
		"version": SNAPSHOT_VERSION,
		"sequence": sequence,
		"phase": phase,
		"wave_index": wave_index,
		"players": players.duplicate(true),
		"enemies": enemies.duplicate(true),
	}

static func validate_snapshot(snapshot: Dictionary) -> bool:
	for key in ["version", "sequence", "phase", "wave_index", "players", "enemies"]:
		if not snapshot.has(key):
			return false
	return int(snapshot["version"]) == SNAPSHOT_VERSION
