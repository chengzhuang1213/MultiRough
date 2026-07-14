extends CharacterCombat
class_name WarriorCombat

func use_q(combat, origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float, attacker: PlayerController) -> void:
	var radius := 220.0 * (1.20 if attacker.get_upgrade_level("warrior_q_range") > 0 else 1.0)
	var damage_multiplier := 1.25 if attacker.get_upgrade_level("warrior_q_damage") > 0 else 1.0
	combat.activate_warrior_taunt(attacker, radius, 2.0)
	combat.damage_and_pull_enemies(origin, radius, damage * 0.85 * damage_multiplier, attacker)
	combat.spawn_warrior_q_vfx(origin, radius)
	combat.game._spawn_effect(origin, radius, Color(1.0, 0.45, 0.18, 0.22), 0.18)

func use_e(combat, origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float, attacker: PlayerController) -> void:
	if attacker.get_upgrade_level("warrior_e_shield") > 0:
		combat.throw_warrior_shield(origin, direction, damage, attacker)
		return
	attacker.activate_warrior_counter(3.0)
	combat.add_warrior_counter_field(attacker, damage * attacker.warrior_counter_pulse_multiplier, 3.0)
	combat.game._spawn_effect(origin, 58.0, Color(0.35, 0.72, 1.0, 0.30), 0.20)
	combat.game._spawn_ring_effect(origin, 58.0, Color(0.38, 0.82, 1.0, 0.85), 0.24)

func use_f(combat, _origin: Vector2, _direction: Vector2, damage: float, duration: float, attacker: PlayerController) -> void:
	combat.start_blade_ultimate(attacker, damage, minf(duration, 6.0))
