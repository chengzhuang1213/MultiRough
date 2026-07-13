extends CharacterCombat
class_name MageCombat

const BASIC_PROJECTILE_TEXTURE := "res://assets/original/characters/mage/mage_basic_projectile.svg"
const Q_MAX_RANGE := 420.0
const E_MAX_CAST_RANGE := 180.0
const F_MAX_CAST_RANGE := 160.0

func basic_attack(combat, origin: Vector2, direction: Vector2, _length: float, _half_width: float, damage: float, attacker: PlayerController) -> void:
	var forward := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	combat.fire_player_arrow(origin + forward * 24.0, forward, damage, attacker, 480.0, 1.35, 18.0, BASIC_PROJECTILE_TEXTURE)
	combat.game._spawn_line_skill_effect(origin, forward, 42.0, Color(0.72, 0.38, 1.0, 0.32), 0.08)

func use_q(combat, origin: Vector2, direction: Vector2, _length: float, half_width: float, damage: float, attacker: PlayerController) -> void:
	var forward := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	combat.fire_mage_fireball(origin + forward * 24.0, forward, damage, attacker, maxf(72.0, half_width * 1.8), Q_MAX_RANGE)

func use_e(combat, origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float, attacker: PlayerController) -> void:
	var forward := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	var radius := maxf(105.0, half_width * 3.0)
	combat.add_mage_field(origin + forward * minf(length * 0.55, E_MAX_CAST_RANGE), radius, damage, attacker)

func use_f(combat, origin: Vector2, direction: Vector2, damage: float, duration: float, attacker: PlayerController) -> void:
	var forward := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	combat.add_mage_storm(origin + forward * F_MAX_CAST_RANGE, damage, duration, attacker)
