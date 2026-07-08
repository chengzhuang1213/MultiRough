extends Node2D
class_name EnemyProjectile

signal hit_player(damage: float)

var direction: Vector2 = Vector2.RIGHT
var speed: float = 360.0
var damage: float = 8.0
var lifetime: float = 2.2
var hit_radius: float = 18.0
var target: Node2D

var _life_left: float = 0.0
var _visual: Polygon2D

func _ready() -> void:
	_life_left = lifetime
	_build_visual()

func _process(delta: float) -> void:
	position += direction.normalized() * speed * delta
	_life_left -= delta
	if target != null and is_instance_valid(target):
		if global_position.distance_to(target.global_position) <= hit_radius:
			hit_player.emit(damage)
			queue_free()
			return
	if _life_left <= 0.0:
		queue_free()

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
