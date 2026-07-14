extends Node2D
class_name PlayerProjectile

signal hit_enemy(enemy: EnemyController, damage: float)
signal reached_max_distance(position: Vector2)

var direction := Vector2.RIGHT
var speed := 520.0
var damage := 18.0
var lifetime := 1.4
var hit_radius := 18.0
var enemies: Array = []
var visual_texture_path := ""
var visual_size := Vector2.ZERO
var visual_additive := false
var pierces_enemies := false
var max_distance := 0.0
var _distance_traveled := 0.0
var _hit_enemy_ids: Dictionary = {}

func _ready() -> void:
	_build_visual()

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		if max_distance > 0.0:
			reached_max_distance.emit(global_position)
		queue_free()
		return

	var move_direction: Vector2 = direction.normalized()
	if move_direction == Vector2.ZERO:
		move_direction = Vector2.RIGHT
	rotation = move_direction.angle()
	var movement := move_direction * speed * delta
	global_position += movement
	_distance_traveled += movement.length()
	if max_distance > 0.0 and _distance_traveled >= max_distance:
		reached_max_distance.emit(global_position)
		queue_free()
		return

	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		if _hit_enemy_ids.has(enemy.get_instance_id()):
			continue
		if global_position.distance_to(enemy.global_position) <= hit_radius:
			_hit_enemy_ids[enemy.get_instance_id()] = true
			hit_enemy.emit(enemy, damage)
			if not pierces_enemies:
				queue_free()
				return

func _build_visual() -> void:
	if not visual_texture_path.is_empty():
		var sprite := Sprite2D.new()
		sprite.name = "Texture"
		sprite.texture = load(visual_texture_path) as Texture2D
		if sprite.texture != null and visual_size != Vector2.ZERO:
			var texture_size := sprite.texture.get_size()
			sprite.scale = Vector2(
				visual_size.x / maxf(texture_size.x, 1.0),
				visual_size.y / maxf(texture_size.y, 1.0)
			)
		if visual_additive:
			var material := CanvasItemMaterial.new()
			material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			sprite.material = material
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
