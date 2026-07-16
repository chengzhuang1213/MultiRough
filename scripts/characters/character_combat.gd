extends RefCounted
class_name CharacterCombat

func basic_attack(combat, origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float, is_critical: bool, attacker: PlayerController) -> void:
	combat.damage_enemies_in_front(origin, direction, length, half_width, damage, -1.0, attacker, is_critical)

func use_q(_combat, _origin: Vector2, _direction: Vector2, _length: float, _half_width: float, _damage: float, _is_critical: bool, _attacker: PlayerController) -> void:
	pass

func use_e(_combat, _origin: Vector2, _direction: Vector2, _length: float, _half_width: float, _damage: float, _is_critical: bool, _attacker: PlayerController) -> void:
	pass

func can_use_e(_combat, _origin: Vector2, _direction: Vector2, _attacker: PlayerController) -> bool:
	return true

func use_f(_combat, _origin: Vector2, _direction: Vector2, _damage: float, _duration: float, _is_critical: bool, _attacker: PlayerController) -> void:
	pass
