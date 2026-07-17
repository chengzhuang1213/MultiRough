extends RefCounted
class_name EnemyArchetypes

static func get_stats(enemy_type: String, wave_number: int = 0) -> Dictionary:
	if enemy_type == "training_dummy":
		return {
			"max_health": 10000.0, "move_speed": 0.0, "attack_damage": 0.0,
			"attack_interval": 999.0, "attack_range": 0.0,
			"attack_windup_time": 0.0, "attack_recovery_time": 0.0,
		}
	if enemy_type == "mini_boss":
		return {
			"max_health": 520.0, "move_speed": 78.0, "attack_damage": 14.0,
			"attack_interval": 0.78, "attack_range": 54.0,
			"attack_windup_time": 0.38, "attack_recovery_time": 0.30,
			"boss_area_timer": 1.8,
		}
	if enemy_type == "boss":
		return {
			"max_health": 1200.0, "move_speed": 70.0, "attack_damage": 18.0,
			"attack_interval": 0.65, "attack_range": 58.0,
			"attack_windup_time": 0.34, "attack_recovery_time": 0.28,
			"boss_area_timer": 1.6,
		}
	var base_health := 38.0 + wave_number * 8.0
	var base_speed := 90.0 + wave_number * 4.0
	var base_damage := 8.0 + wave_number * 2.0
	var stats := {
		"max_health": base_health, "move_speed": base_speed, "attack_damage": base_damage,
		"attack_interval": 0.85, "attack_range": 42.0,
		"attack_windup_time": 0.24, "attack_recovery_time": 0.20,
		"preferred_range": 0.0, "projectile_damage": 8.0,
	}
	match enemy_type:
		"heavy":
			stats.merge({"max_health": base_health * 2.25, "move_speed": base_speed * 0.58, "attack_damage": base_damage * 1.45, "attack_interval": 1.05, "attack_range": 48.0, "attack_windup_time": 0.42, "attack_recovery_time": 0.34}, true)
		"ranged":
			stats.merge({"max_health": base_health * 0.8, "move_speed": base_speed * 0.92, "attack_damage": base_damage * 0.75, "projectile_damage": base_damage * 0.75, "attack_interval": 1.35, "attack_range": 250.0, "preferred_range": 185.0, "attack_windup_time": 0.32, "attack_recovery_time": 0.26}, true)
		"shield":
			stats.merge({"max_health": base_health * 1.65, "move_speed": base_speed * 0.72, "attack_damage": base_damage * 1.05, "attack_interval": 1.0, "attack_range": 48.0, "attack_windup_time": 0.36, "attack_recovery_time": 0.30}, true)
		"charger":
			stats.merge({"max_health": base_health * 1.80, "move_speed": base_speed * 1.05, "attack_damage": base_damage * 1.45, "attack_interval": 1.15, "attack_range": 54.0, "attack_windup_time": 0.30, "charge_damage": base_damage * 1.45 * 1.55, "charge_cooldown": 1.2}, true)
		"bomber":
			stats.merge({"max_health": base_health * 1.20, "move_speed": base_speed * 0.90, "attack_range": 88.0, "bomber_damage": base_damage * 2.25, "bomber_radius": 96.0}, true)
		"priest":
			stats.merge({"max_health": base_health * 3.20, "move_speed": base_speed * 0.68, "attack_damage": base_damage * 0.65, "attack_interval": 1.4, "attack_range": 52.0, "preferred_range": 165.0, "priest_heal_amount": 14.0 + float(wave_number) * 2.0, "priest_heal_cooldown": 1.8}, true)
	return stats
