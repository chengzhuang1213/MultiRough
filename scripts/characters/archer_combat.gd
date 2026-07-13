extends CharacterCombat
class_name ArcherCombat

func basic_attack(combat, origin: Vector2, direction: Vector2, _length: float, _half_width: float, damage: float, attacker: PlayerController) -> void:
	combat.fire_player_arrow(origin, direction, damage, attacker)
	combat.game._spawn_line_skill_effect(origin, direction, 54.0, Color(1.0, 0.88, 0.42, 0.35), 0.08)

func use_q(combat, origin: Vector2, direction: Vector2, _length: float, _half_width: float, damage: float, attacker: PlayerController) -> void:
	var projectile_origin := attacker.get_projectile_origin(direction)
	var projectile_direction := attacker.get_projectile_direction(projectile_origin, direction)
	combat.fire_player_arrow(projectile_origin, projectile_direction, damage * 2.0, attacker, 760.0, 0.8, 20.0)
	combat.game._spawn_line_skill_effect(projectile_origin, projectile_direction, 90.0, Color(1.0, 0.72, 0.18, 0.75), 0.14)

func use_e(combat, origin: Vector2, direction: Vector2, _length: float, _half_width: float, damage: float, attacker: PlayerController) -> void:
	combat.mark_nearest_enemy(origin, direction, 420.0, 8.0, 1.45, attacker)

func use_f(combat, origin: Vector2, direction: Vector2, damage: float, duration: float, attacker: PlayerController) -> void:
	combat.add_arrow_rain(origin, direction, damage, minf(duration, 5.0), attacker)
