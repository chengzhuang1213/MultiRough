extends Node2D
class_name EnemyProjectile

signal hit_player(damage: float)

var direction: Vector2 = Vector2.RIGHT
var speed: float = 360.0
var damage: float = 8.0
var lifetime: float = 2.2
var hit_radius: float = 18.0
var target: Node2D
var network_id := -1
var owner_enemy_id := 0
var target_player_id := 0
var authority_presentation_only := false

var _life_left: float = 0.0
var _visual: Polygon2D

func _ready() -> void:
	_life_left = lifetime
	_build_visual()

func _process(delta: float) -> void:
	position += direction.normalized() * speed * delta
	if authority_presentation_only:
		return
	_life_left -= delta
	if target != null and is_instance_valid(target):
		if global_position.distance_to(target.global_position) <= hit_radius:
			hit_player.emit(damage)
			queue_free()
			return
	if _life_left <= 0.0:
		queue_free()

func make_authority_state() -> Dictionary:
	return {
		"entity_id": network_id,
		"type": "enemy",
		"owner_enemy_id": owner_enemy_id,
		"target_player_id": target_player_id,
		"position": global_position,
		"direction": direction,
		"speed": speed,
		"lifetime": _life_left,
		"damage": damage,
		"hit_radius": hit_radius,
	}

func apply_authority_state(state: Dictionary) -> void:
	network_id = int(state.get("entity_id", network_id))
	owner_enemy_id = int(state.get("owner_enemy_id", owner_enemy_id))
	target_player_id = int(state.get("target_player_id", target_player_id))
	global_position = state.get("position", global_position) as Vector2
	direction = state.get("direction", direction) as Vector2
	speed = float(state.get("speed", speed))
	_life_left = float(state.get("lifetime", _life_left))
	damage = float(state.get("damage", damage))
	hit_radius = float(state.get("hit_radius", hit_radius))

func _build_visual() -> void:
	_visual = Polygon2D.new()
	_visual.polygon = PackedVector2Array([
		Vector2(12.0, 0.0),
		Vector2(-8.0, -5.0),
		Vector2(-4.0, 0.0),
		Vector2(-8.0, 5.0),
	])
	_visual.color = Color(0.95, 0.82, 0.36, 1.0)
	_visual.rotation = direction.angle()
	add_child(_visual)
