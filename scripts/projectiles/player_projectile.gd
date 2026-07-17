extends Node2D
class_name PlayerProjectile

const RANGED_ATTACK_BLOCKER_LAYER := 1 << 4

signal hit_enemy(enemy: EnemyController, damage: float, is_critical: bool)
signal reached_max_distance(position: Vector2)

var direction := Vector2.RIGHT
var speed := 520.0
var damage := 18.0
var is_critical := false
var lifetime := 1.4
var hit_radius := 18.0
var enemies: Array = []
var visual_texture_path := ""
var visual_size := Vector2.ZERO
var visual_additive := false
var pierces_enemies := false
var max_distance := 0.0
var network_id := -1
var owner_player_id := 0
var projectile_type := "player"
var authority_presentation_only := false
var _distance_traveled := 0.0
var _hit_enemy_ids: Dictionary = {}

func _ready() -> void:
	_build_visual()

func _process(delta: float) -> void:
	if authority_presentation_only:
		var presentation_direction := direction.normalized()
		if presentation_direction == Vector2.ZERO:
			presentation_direction = Vector2.RIGHT
		rotation = presentation_direction.angle()
		global_position += presentation_direction * speed * delta
		return
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
	var next_position := global_position + movement
	var blocker_hit := _get_ranged_blocker_hit(global_position, next_position)
	if not blocker_hit.is_empty():
		global_position = blocker_hit.get("position", global_position) as Vector2
		reached_max_distance.emit(global_position)
		queue_free()
		return
	global_position = next_position
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
			hit_enemy.emit(enemy, damage, is_critical)
			if not pierces_enemies:
				queue_free()
				return

func _get_ranged_blocker_hit(start: Vector2, finish: Vector2) -> Dictionary:
	if not is_inside_tree() or start.is_equal_approx(finish):
		return {}
	var query := PhysicsRayQueryParameters2D.create(start, finish, RANGED_ATTACK_BLOCKER_LAYER)
	query.collide_with_areas = false
	return get_world_2d().direct_space_state.intersect_ray(query)

func make_authority_state() -> Dictionary:
	return {
		"entity_id": network_id,
		"type": projectile_type,
		"owner_player_id": owner_player_id,
		"position": global_position,
		"direction": direction,
		"speed": speed,
		"lifetime": lifetime,
		"damage": damage,
		"is_critical": is_critical,
		"hit_radius": hit_radius,
		"visual_texture_path": visual_texture_path,
		"visual_size": visual_size,
		"visual_additive": visual_additive,
		"pierces_enemies": pierces_enemies,
		"max_distance": max_distance,
	}

func apply_authority_state(state: Dictionary) -> void:
	network_id = int(state.get("entity_id", network_id))
	projectile_type = str(state.get("type", projectile_type))
	owner_player_id = int(state.get("owner_player_id", owner_player_id))
	global_position = state.get("position", global_position) as Vector2
	direction = state.get("direction", direction) as Vector2
	speed = float(state.get("speed", speed))
	lifetime = float(state.get("lifetime", lifetime))
	damage = float(state.get("damage", damage))
	is_critical = bool(state.get("is_critical", is_critical))
	hit_radius = float(state.get("hit_radius", hit_radius))
	max_distance = float(state.get("max_distance", max_distance))

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
