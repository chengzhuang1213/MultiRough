extends CharacterCombat
class_name MageCombat

const Q_MAX_RANGE := 420.0
const E_MAX_CAST_RANGE := 180.0
const F_MAX_CAST_RANGE := 160.0

func basic_attack(combat, origin: Vector2, direction: Vector2, _length: float, _half_width: float, damage: float, is_critical: bool, attacker: PlayerController) -> void:
	var forward := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	combat.fire_mage_single_projectile(origin + forward * 24.0, forward, damage, attacker, is_critical)
	combat.game._spawn_line_skill_effect(origin, forward, 42.0, Color(0.72, 0.38, 1.0, 0.32), 0.08)

func use_q(combat, origin: Vector2, direction: Vector2, _length: float, half_width: float, damage: float, is_critical: bool, attacker: PlayerController) -> void:
	var forward := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	var explosion_radius := maxf(72.0, half_width * 1.8)
	if attacker.get_upgrade_level("mage_q_radius") > 0:
		explosion_radius *= 1.20
	var damage_multiplier := 1.20 if attacker.get_upgrade_level("mage_q_damage") > 0 else 1.0
	combat.fire_mage_fireball(origin + forward * 24.0, forward, damage * damage_multiplier, attacker, explosion_radius, Q_MAX_RANGE, is_critical)

func use_e(combat, origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float, is_critical: bool, attacker: PlayerController) -> void:
	var forward := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	if attacker.get_upgrade_level("mage_e_chain") > 0:
		combat.cast_chain_lightning(origin, forward, damage, attacker, attacker.get_upgrade_level("mage_e_conduction") > 0, is_critical)
		return
	var radius := maxf(105.0, half_width * 3.0)
	var expanded := attacker.get_upgrade_level("mage_e_field") > 0
	if expanded:
		radius *= 1.25
	var desired_center := origin + forward * minf(length * 0.55, E_MAX_CAST_RANGE)
	combat.add_mage_field(combat.clamp_ranged_target(origin, desired_center), radius, damage, attacker, 5.0 if expanded else 4.0, attacker.get_upgrade_level("mage_e_accumulation") > 0, is_critical)

func can_use_e(combat, origin: Vector2, direction: Vector2, attacker: PlayerController) -> bool:
	if attacker.get_upgrade_level("mage_e_chain") <= 0:
		return true
	return combat.has_enemy_in_aim_cone(origin, direction, 320.0, 0.25)

func use_f(combat, origin: Vector2, direction: Vector2, damage: float, duration: float, is_critical: bool, attacker: PlayerController) -> void:
	var forward := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	combat.add_mage_storm(combat.clamp_ranged_target(origin, origin + forward * F_MAX_CAST_RANGE), damage, duration, attacker, is_critical)
