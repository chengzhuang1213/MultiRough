extends CharacterCombat
class_name ArcherCombat

func basic_attack(combat, origin: Vector2, direction: Vector2, _length: float, _half_width: float, damage: float, attacker: PlayerController) -> void:
	combat.fire_player_arrow(origin, direction, damage, attacker)
	combat.game._spawn_line_skill_effect(origin, direction, 54.0, Color(1.0, 0.88, 0.42, 0.35), 0.08)

func use_q(combat, origin: Vector2, direction: Vector2, _length: float, _half_width: float, damage: float, attacker: PlayerController) -> void:
	var attack_length := attacker.skill_length * 1.28
	combat.damage_enemies_in_front(origin, direction, attack_length, 24.0, damage * 1.1, attacker.attack_knockback * 0.6, attacker)
	combat.game._spawn_line_skill_effect(origin, direction, attack_length, Color(0.95, 0.78, 0.28, 0.72), 0.14)

func use_e(combat, origin: Vector2, direction: Vector2, _length: float, _half_width: float, damage: float, attacker: PlayerController) -> void:
	var forward := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	for angle in [-0.22, 0.0, 0.22]:
		var arrow_direction: Vector2 = forward.rotated(angle)
		combat.fire_player_arrow(origin + arrow_direction * 24.0, arrow_direction, damage * 0.45, attacker, 600.0, 1.0, 17.0)
		combat.game._spawn_line_skill_effect(origin, arrow_direction, 48.0, Color(1.0, 0.86, 0.38, 0.32), 0.07)

func use_f(combat, origin: Vector2, direction: Vector2, damage: float, duration: float, attacker: PlayerController) -> void:
	combat.add_arrow_rain(origin, direction, damage, duration, attacker)
