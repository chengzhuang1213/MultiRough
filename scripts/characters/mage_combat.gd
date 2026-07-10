extends CharacterCombat
class_name MageCombat

const BASIC_PROJECTILE_TEXTURE := "res://assets/original/characters/mage/mage_basic_projectile.svg"

func basic_attack(combat, origin: Vector2, direction: Vector2, _length: float, _half_width: float, damage: float, attacker: PlayerController) -> void:
	var forward := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	combat.fire_player_arrow(origin + forward * 24.0, forward, damage, attacker, 480.0, 1.35, 18.0, BASIC_PROJECTILE_TEXTURE)
	combat.game._spawn_line_skill_effect(origin, forward, 42.0, Color(0.72, 0.38, 1.0, 0.32), 0.08)

func use_q(_combat, _origin: Vector2, _direction: Vector2, _length: float, _half_width: float, _damage: float, _attacker: PlayerController) -> void:
	pass

func use_e(_combat, _origin: Vector2, _direction: Vector2, _length: float, _half_width: float, _damage: float, _attacker: PlayerController) -> void:
	pass

func use_f(_combat, _origin: Vector2, _direction: Vector2, _damage: float, _duration: float, _attacker: PlayerController) -> void:
	pass
