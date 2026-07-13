extends CharacterCombat
class_name WarriorCombat

func use_q(combat, origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float, attacker: PlayerController) -> void:
	combat.activate_warrior_taunt(attacker, 220.0, 2.0)
	combat.damage_and_pull_enemies(origin, 220.0, damage * 0.85, attacker)
	combat.game._spawn_effect(origin, 220.0, Color(1.0, 0.45, 0.18, 0.22), 0.18)

func use_e(combat, origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float, attacker: PlayerController) -> void:
	attacker.activate_warrior_counter(3.0)
	combat.add_warrior_counter_field(attacker, damage, 3.0)
	combat.game._spawn_effect(origin, 58.0, Color(0.35, 0.72, 1.0, 0.30), 0.20)
	combat.game._spawn_ring_effect(origin, 58.0, Color(0.38, 0.82, 1.0, 0.85), 0.24)

func use_f(combat, _origin: Vector2, _direction: Vector2, damage: float, duration: float, attacker: PlayerController) -> void:
	combat.start_blade_ultimate(attacker, damage, minf(duration, 6.0))
