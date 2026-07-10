extends CharacterCombat
class_name WarriorCombat

func use_q(combat, origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float, attacker: PlayerController) -> void:
	combat.damage_enemies_in_front(origin, direction, length, half_width, damage, attacker.attack_knockback * 0.75, attacker)
	combat.game._spawn_shockwave_effect(origin, direction, length)

func use_e(combat, origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float, attacker: PlayerController) -> void:
	var forward := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	for angle in [-0.32, 0.0, 0.32]:
		var line_direction: Vector2 = forward.rotated(angle)
		combat.damage_enemies_in_front(origin, line_direction, length, half_width, damage, attacker.attack_knockback * 0.45, attacker)
		combat.game._spawn_line_skill_effect(origin, line_direction, length)

func use_f(combat, _origin: Vector2, _direction: Vector2, damage: float, duration: float, attacker: PlayerController) -> void:
	combat.start_blade_ultimate(attacker, damage, duration)
