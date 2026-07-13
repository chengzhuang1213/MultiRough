extends CharacterCombat
class_name LancerCombat

func use_q(combat, origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float, attacker: PlayerController) -> void:
	combat.damage_enemies_in_front(origin, direction, length * 0.72, half_width * 3.2, damage, attacker.attack_knockback * 0.55, attacker)
	combat.game._spawn_lancer_sweep_effect(origin, direction, length * 0.72, half_width * 3.2)

func use_e(combat, origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float, attacker: PlayerController) -> void:
	combat.lancer_dash_spin(attacker, direction, minf(length * 0.55, 150.0), damage)

func use_f(combat, origin: Vector2, direction: Vector2, damage: float, duration: float, attacker: PlayerController) -> void:
	combat.add_lancer_storm(attacker, damage, minf(duration, 5.0))
