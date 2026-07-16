extends CharacterCombat
class_name LancerCombat

func use_q(combat, origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float, is_critical: bool, attacker: PlayerController) -> void:
	var range_multiplier := 1.20 if attacker.get_upgrade_level("lancer_q_range") > 0 else 1.0
	var damage_multiplier := 1.20 if attacker.get_upgrade_level("lancer_q_damage") > 0 else 1.0
	var sweep_length := length * 0.72 * range_multiplier
	var sweep_width := half_width * 3.2 * range_multiplier
	combat.damage_enemies_in_front(origin, direction, sweep_length, sweep_width, damage * damage_multiplier, attacker.attack_knockback * 0.55, attacker, is_critical)
	combat.spawn_lancer_sweep_vfx(origin, direction, sweep_length, sweep_width)

func use_e(combat, origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float, is_critical: bool, attacker: PlayerController) -> void:
	if attacker.get_upgrade_level("lancer_e_spear") > 0:
		combat.throw_lancer_spear(origin, direction, damage, attacker, attacker.get_upgrade_level("lancer_e_return") > 0, is_critical)
		return
	var charge_upgrade := attacker.get_upgrade_level("lancer_e_charge") > 0
	if charge_upgrade:
		attacker.grant_skill_invulnerability(0.35)
	var distance := minf(length * 0.55, 150.0) * (1.30 if charge_upgrade else 1.0)
	combat.lancer_dash_spin(attacker, direction, distance, damage, is_critical)
	if attacker.get_upgrade_level("lancer_e_double_sweep") > 0:
		combat.schedule_lancer_second_sweep(attacker, damage, is_critical)

func use_f(combat, origin: Vector2, direction: Vector2, damage: float, duration: float, is_critical: bool, attacker: PlayerController) -> void:
	combat.add_lancer_storm(attacker, damage, minf(duration, 5.0), is_critical)
