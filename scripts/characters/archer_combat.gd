extends CharacterCombat
class_name ArcherCombat

func basic_attack(combat, origin: Vector2, direction: Vector2, _length: float, _half_width: float, damage: float, attacker: PlayerController) -> void:
	combat.fire_player_arrow(origin, direction, damage, attacker, 560.0, 1.2, 18.0, "", 672.0 * attacker.get_attack_range_multiplier())
	combat.game._spawn_line_skill_effect(origin, direction, 54.0, Color(1.0, 0.88, 0.42, 0.35), 0.08)

func use_q(combat, origin: Vector2, direction: Vector2, _length: float, _half_width: float, damage: float, attacker: PlayerController) -> void:
	var projectile_origin := attacker.get_projectile_origin(direction)
	var projectile_direction := attacker.get_projectile_direction(projectile_origin, direction)
	var damage_multiplier := 1.25 if attacker.get_upgrade_level("archer_q_damage") > 0 else 1.0
	var projectile: PlayerProjectile = combat.fire_player_arrow(
		projectile_origin, projectile_direction, damage * 2.0 * damage_multiplier, attacker,
		760.0, 0.8, 20.0, "res://assets/effects/archer/archer_q_vfx.png", 0.0,
		Vector2(152.0, 48.0), true
	)
	projectile.pierces_enemies = attacker.archer_q_fully_charged
	combat.decorate_archer_q_projectile(projectile, projectile_origin, attacker.archer_q_fully_charged)
	combat.game._spawn_line_skill_effect(projectile_origin, projectile_direction, 90.0, Color(1.0, 0.72, 0.18, 0.75), 0.14)

func use_e(combat, origin: Vector2, direction: Vector2, _length: float, _half_width: float, damage: float, attacker: PlayerController) -> void:
	if attacker.get_upgrade_level("archer_e_trap") > 0:
		combat.place_archer_trap(origin, direction, attacker)
		return
	var empowered := attacker.get_upgrade_level("archer_e_mark") > 0
	combat.mark_nearest_enemy(origin, direction, 420.0, 12.0 if empowered else 8.0, 1.70 if empowered else 1.55, attacker)

func use_f(combat, origin: Vector2, direction: Vector2, damage: float, duration: float, attacker: PlayerController) -> void:
	combat.add_arrow_rain(origin, direction, damage, minf(duration, 5.0), attacker)
