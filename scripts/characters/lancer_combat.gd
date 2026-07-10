extends CharacterCombat
class_name LancerCombat

func use_q(combat, origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float, attacker: PlayerController) -> void:
	combat.damage_enemies_in_front(origin, direction, length * 1.18, half_width * 0.9, damage, attacker.attack_knockback * 0.85, attacker)
	combat.game._spawn_line_skill_effect(origin, direction, length * 1.18, Color(0.65, 0.9, 1.0, 0.60), 0.13)

func use_e(combat, origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float, attacker: PlayerController) -> void:
	combat.damage_enemies_in_front(origin, direction, length * 0.72, half_width * 4.2, damage * 0.72, attacker.attack_knockback * 0.95, attacker)
	combat.game._spawn_lancer_sweep_effect(origin, direction, length * 0.72, half_width * 4.2)

func use_f(combat, origin: Vector2, direction: Vector2, damage: float, duration: float, attacker: PlayerController) -> void:
	combat.add_lancer_barricade(origin, direction, damage, duration, attacker)
