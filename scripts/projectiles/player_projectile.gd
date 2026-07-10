extends Node2D
class_name PlayerProjectile

signal hit_enemy(enemy: EnemyController, damage: float)

var direction := Vector2.RIGHT
var speed := 520.0
var damage := 18.0
var lifetime := 1.4
var hit_radius := 18.0
var enemies: Array = []
var visual_texture_path := ""

func _ready() -> void:
	_build_visual()

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	var move_direction: Vector2 = direction.normalized()
	if move_direction == Vector2.ZERO:
		move_direction = Vector2.RIGHT
	rotation = move_direction.angle()
	global_position += move_direction * speed * delta

	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) <= hit_radius:
			hit_enemy.emit(enemy, damage)
			queue_free()
			return

func _build_visual() -> void:
	if not visual_texture_path.is_empty():
		var sprite := Sprite2D.new()
		sprite.texture = load(visual_texture_path) as Texture2D
		add_child(sprite)
		return

	var line: Line2D = Line2D.new()
	line.width = 3.0
	line.default_color = Color(0.95, 0.78, 0.36, 1.0)
	line.points = PackedVector2Array([
		Vector2(-18.0, 0.0),
		Vector2(18.0, 0.0),
	])
	add_child(line)

	var head: Polygon2D = Polygon2D.new()
	head.color = Color(1.0, 0.9, 0.55, 1.0)
	head.polygon = PackedVector2Array([
		Vector2(22.0, 0.0),
		Vector2(12.0, -5.0),
		Vector2(12.0, 5.0),
	])
	add_child(head)
