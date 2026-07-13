extends RefCounted
class_name CombatManager

const EnemyProjectileScript := preload("res://scripts/projectiles/enemy_projectile.gd")
const PlayerProjectileScript := preload("res://scripts/projectiles/player_projectile.gd")
const WarriorCombatScript := preload("res://scripts/characters/warrior_combat.gd")
const ArcherCombatScript := preload("res://scripts/characters/archer_combat.gd")
const LancerCombatScript := preload("res://scripts/characters/lancer_combat.gd")
const MageCombatScript := preload("res://scripts/characters/mage_combat.gd")

var game: Node
var character_modules: Dictionary

func _init(game_node: Node) -> void:
	game = game_node
	character_modules = {
		"warrior": WarriorCombatScript.new(),
		"archer": ArcherCombatScript.new(),
		"lancer": LancerCombatScript.new(),
		"mage": MageCombatScript.new(),
	}

func get_character_module(character_id: String):
	return character_modules.get(character_id, character_modules["warrior"])

func damage_enemy(enemy: EnemyController, amount: float, attacker: PlayerController, knockback_origin: Vector2 = Vector2.ZERO, knockback_force: float = 90.0) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	var final_amount := amount * enemy.get_damage_multiplier(attacker)
	enemy.apply_damage(final_amount, knockback_origin, knockback_force)
	apply_lifesteal(attacker, final_amount)

func damage_enemies_in_radius(origin: Vector2, radius: float, damage: float, attacker: PlayerController) -> void:
	for enemy in game.enemies.duplicate():
		if is_instance_valid(enemy) and enemy.global_position.distance_to(origin) <= radius:
			damage_enemy(enemy, damage, attacker, origin, attacker.attack_knockback if attacker != null else 90.0)

func damage_enemies_in_front(origin: Vector2, direction: Vector2, attack_length: float, half_width: float, damage: float, knockback: float = -1.0, attacker: PlayerController = null) -> void:
	var forward := direction.normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.RIGHT
	var side := Vector2(-forward.y, forward.x)
	for enemy in game.enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		var offset: Vector2 = enemy.global_position - origin
		var forward_distance := offset.dot(forward)
		var side_distance := absf(offset.dot(side))
		if forward_distance < 0.0 or forward_distance > attack_length or side_distance > half_width:
			continue
		var resolved_knockback := knockback
		if resolved_knockback < 0.0:
			resolved_knockback = attacker.attack_knockback if attacker != null else 90.0
		damage_enemy(enemy, damage, attacker, origin, resolved_knockback)

func apply_lifesteal(attacker: PlayerController, amount: float) -> void:
	if attacker != null and is_instance_valid(attacker) and attacker.lifesteal_ratio > 0.0:
		attacker.heal(amount * attacker.lifesteal_ratio)

func on_enemy_attacked_player(enemy: EnemyController, target: Node2D, damage: float) -> void:
	var player := target as PlayerController
	if player == null or player.is_dead:
		return
	var defended := player.apply_damage(damage, enemy)
	if defended and is_instance_valid(enemy):
		enemy.apply_defense_repel(player.global_position, 190.0)
		game._spawn_effect(enemy.global_position, 28.0, Color(0.35, 0.72, 1.0, 0.28), 0.10)

func on_enemy_projectile_requested(enemy: EnemyController, target: Node2D, origin: Vector2, direction: Vector2, damage: float) -> void:
	var projectile = EnemyProjectileScript.new()
	projectile.global_position = origin
	projectile.direction = direction
	projectile.damage = damage
	projectile.target = target if target != null and is_instance_valid(target) else game.player
	projectile.hit_player.connect(_on_enemy_projectile_hit_player.bind(projectile.target, enemy))
	game.projectile_root.add_child(projectile)
	game._spawn_line_skill_effect(origin, direction, 58.0, Color(1.0, 0.74, 0.28, 0.42), 0.10)

func _on_enemy_projectile_hit_player(damage: float, target: Node2D, source: EnemyController) -> void:
	var player := target as PlayerController
	if player != null:
		player.apply_damage(damage, source)

func on_enemy_area_attack_requested(enemy: EnemyController, origin: Vector2, radius: float, damage: float, windup_time: float) -> void:
	if game.SHOW_ENEMY_ATTACK_TELEGRAPH:
		game._spawn_effect(origin, radius, Color(1.0, 0.18, 0.12, 0.22), windup_time)
	var timer: SceneTreeTimer = game.get_tree().create_timer(windup_time)
	timer.timeout.connect(func() -> void:
		game._spawn_effect(origin, radius, Color(1.0, 0.34, 0.20, 0.30), 0.16)
		for player in game.players:
			if is_instance_valid(player) and not player.is_dead and player.global_position.distance_to(origin) <= radius:
				player.apply_damage(damage, enemy)
				game._spawn_effect(player.global_position, 34.0, Color(1.0, 0.25, 0.22, 0.24), 0.10)
	)

func on_player_damage_taken(amount: float, defended: bool, player: PlayerController) -> void:
	game.damage_taken += amount
	var color := Color(0.35, 0.72, 1.0, 0.28) if defended else Color(1.0, 0.25, 0.22, 0.24)
	game._spawn_effect(player.global_position, 42.0 if defended else 34.0, color, 0.10)
	game._spawn_damage_number(player.global_position + Vector2(-12.0, -46.0), amount, color)

func on_player_reflected_damage(enemy: EnemyController, amount: float, player: PlayerController) -> void:
	game._spawn_link_effect(player.global_position, enemy.global_position, Color(0.35, 0.78, 1.0, 0.90), 0.16)
	damage_enemy(enemy, amount, player, player.global_position, 0.0)

func activate_warrior_taunt(owner: PlayerController, radius: float, duration: float) -> void:
	owner.activate_warrior_taunt_guard(duration)
	for enemy in game.enemies.duplicate():
		if is_instance_valid(enemy) and enemy.global_position.distance_to(owner.global_position) <= radius:
			enemy.apply_taunt(owner, duration)
			game._spawn_link_effect(enemy.global_position, owner.global_position, Color(1.0, 0.32, 0.16, 0.55), 0.20)
	game._spawn_ring_effect(owner.global_position, radius, Color(1.0, 0.42, 0.16, 0.75), 0.24)

func damage_and_pull_enemies(origin: Vector2, radius: float, damage: float, owner: PlayerController) -> void:
	for enemy in game.enemies.duplicate():
		if not is_instance_valid(enemy) or enemy.global_position.distance_to(origin) > radius:
			continue
		var pull_origin: Vector2 = enemy.global_position + (enemy.global_position - origin).normalized() * 80.0
		var pull_force := 0.0 if enemy.is_boss else 170.0
		damage_enemy(enemy, damage, owner, pull_origin, pull_force)

func add_warrior_counter_field(owner: PlayerController, damage: float, duration: float) -> void:
	var root := Node2D.new()
	root.name = "WarriorCounter_%s" % owner.name
	root.global_position = owner.global_position
	game.effect_root.add_child(root)
	game._spawn_area_visual(root, Vector2.ZERO, 105.0, Color(0.22, 0.58, 1.0, 0.10))
	game.persistent_skill_areas.append({
		"type": "warrior_counter", "owner": owner, "root": root,
		"duration_left": duration, "tick_left": 0.0, "interval": 0.60,
		"radius": 105.0, "damage": damage * 0.18,
	})

func mark_nearest_enemy(origin: Vector2, direction: Vector2, max_range: float, duration: float, multiplier: float, owner: PlayerController) -> void:
	var forward := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	var best: EnemyController
	var best_score := INF
	for enemy in game.enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		var offset: Vector2 = enemy.global_position - origin
		if offset.length() > max_range or offset.normalized().dot(forward) < 0.35:
			continue
		var score := offset.length() - offset.normalized().dot(forward) * 80.0
		if score < best_score:
			best = enemy
			best_score = score
	if best != null:
		best.apply_hunter_mark(owner, duration, multiplier)
		game._spawn_effect(best.global_position, 34.0, Color(1.0, 0.25, 0.18, 0.30), 0.18)
		game._spawn_ring_effect(best.global_position, 34.0, Color(1.0, 0.72, 0.18, 0.90), 0.30)

func lancer_dash_spin(owner: PlayerController, direction: Vector2, distance: float, damage: float) -> void:
	var forward := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	owner.global_position = (owner.global_position + forward * distance).clamp(owner.arena_bounds.position, owner.arena_bounds.end)
	damage_enemies_in_radius(owner.global_position, 120.0, damage, owner)
	game._spawn_effect(owner.global_position, 120.0, Color(0.58, 0.86, 1.0, 0.22), 0.16)

func on_player_basic_attack(origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float, attacker: PlayerController) -> void:
	get_character_module(attacker.character_id).basic_attack(self, origin, direction, length, half_width, damage, attacker)

func on_player_projectile_attack(origin: Vector2, direction: Vector2, damage: float, attacker: PlayerController) -> void:
	get_character_module(attacker.character_id).basic_attack(self, origin, direction, attacker.attack_range, attacker.attack_half_width, damage, attacker)

func fire_player_arrow(origin: Vector2, direction: Vector2, damage: float, attacker: PlayerController, speed: float = 560.0, lifetime: float = 1.2, hit_radius: float = 18.0, visual_texture_path: String = "") -> void:
	var projectile = PlayerProjectileScript.new()
	projectile.global_position = origin
	projectile.direction = direction
	projectile.damage = damage
	projectile.speed = speed
	projectile.lifetime = lifetime
	projectile.hit_radius = hit_radius
	projectile.visual_texture_path = visual_texture_path
	projectile.enemies = game.enemies
	projectile.hit_enemy.connect(_on_player_projectile_hit_enemy.bind(attacker))
	game.projectile_root.add_child(projectile)

func fire_mage_fireball(origin: Vector2, direction: Vector2, damage: float, attacker: PlayerController, explosion_radius: float, max_range: float) -> void:
	var projectile = PlayerProjectileScript.new()
	projectile.global_position = origin
	projectile.direction = direction
	projectile.damage = damage
	projectile.speed = 420.0
	projectile.lifetime = 1.5
	projectile.hit_radius = 20.0
	projectile.visual_texture_path = "res://assets/original/characters/mage/mage_basic_projectile.svg"
	projectile.max_distance = max_range
	projectile.enemies = game.enemies
	projectile.hit_enemy.connect(_on_mage_fireball_hit.bind(attacker, explosion_radius))
	projectile.reached_max_distance.connect(_on_mage_fireball_reached_limit.bind(damage, attacker, explosion_radius))
	game.projectile_root.add_child(projectile)
	game._spawn_line_skill_effect(origin, direction, 58.0, Color(0.88, 0.42, 1.0, 0.42), 0.10)

func _on_mage_fireball_hit(enemy: EnemyController, damage: float, attacker: PlayerController, explosion_radius: float) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	var impact := enemy.global_position
	game._spawn_effect(impact, explosion_radius, Color(0.82, 0.30, 1.0, 0.30), 0.16)
	damage_enemies_in_radius(impact, explosion_radius, damage, attacker)

func _on_mage_fireball_reached_limit(impact: Vector2, damage: float, attacker: PlayerController, explosion_radius: float) -> void:
	game._spawn_effect(impact, explosion_radius, Color(0.82, 0.30, 1.0, 0.30), 0.16)
	damage_enemies_in_radius(impact, explosion_radius, damage, attacker)

func _on_player_projectile_hit_enemy(enemy: EnemyController, damage: float, attacker: PlayerController) -> void:
	damage_enemy(enemy, damage, attacker, attacker.global_position, attacker.attack_knockback)

func on_player_active_skill(origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float, attacker: PlayerController) -> void:
	get_character_module(attacker.character_id).use_q(self, origin, direction, length, half_width, damage, attacker)

func on_player_fan_skill(origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float, attacker: PlayerController) -> void:
	get_character_module(attacker.character_id).use_e(self, origin, direction, length, half_width, damage, attacker)

func on_player_ultimate_skill(origin: Vector2, direction: Vector2, damage: float, duration: float, attacker: PlayerController) -> void:
	get_character_module(attacker.character_id).use_f(self, origin, direction, damage, duration, attacker)

func start_blade_ultimate(owner: PlayerController, damage: float, duration: float) -> void:
	var state: Dictionary = _get_ultimate_state(owner)
	state["duration_left"] = duration
	state["angle"] = 0.0
	state["damage"] = damage
	(state["hit_cooldowns"] as Dictionary).clear()
	(state["root"] as Node2D).visible = true
	owner.activate_warrior_blade_guard(duration)

func setup_ultimate(owner: PlayerController) -> void:
	var root := Node2D.new()
	root.name = "UltimateBlades_%s" % owner.name
	root.visible = false
	game.add_child(root)
	for index in range(3):
		var blade := Line2D.new()
		blade.name = "Blade%d" % index
		blade.width = 5.0
		blade.default_color = Color(0.65, 0.9, 1.0, 0.82)
		blade.points = PackedVector2Array([Vector2(-42.0, 0.0), Vector2(42.0, 0.0)])
		root.add_child(blade)
	game.ultimate_states[owner.get_instance_id()] = {"owner": owner, "root": root, "duration_left": 0.0, "angle": 0.0, "damage": 0.0, "hit_cooldowns": {}}

func update_ultimates(delta: float) -> void:
	for state in game.ultimate_states.values():
		_update_ultimate(state, delta)

func _update_ultimate(state: Dictionary, delta: float) -> void:
	var owner: PlayerController = state["owner"] as PlayerController
	var root: Node2D = state["root"] as Node2D
	var remaining := float(state.get("duration_left", 0.0))
	if remaining <= 0.0 or owner == null or not is_instance_valid(owner) or owner.is_dead:
		root.visible = false
		return
	state["duration_left"] = maxf(0.0, remaining - delta)
	var rotation_speed := 11.0 if owner.is_defending else 7.2
	state["angle"] = float(state.get("angle", 0.0)) + rotation_speed * delta
	var cooldowns: Dictionary = state["hit_cooldowns"]
	for key in cooldowns.keys():
		cooldowns[key] = maxf(0.0, float(cooldowns[key]) - delta)
	_update_blade_visuals(state)
	_damage_with_blades(state)
	_destroy_projectiles_with_blades(state)
	if float(state["duration_left"]) <= 0.0:
		root.visible = false

func _get_ultimate_state(owner: PlayerController) -> Dictionary:
	var key := owner.get_instance_id()
	if not game.ultimate_states.has(key):
		setup_ultimate(owner)
	return game.ultimate_states[key]

func _update_blade_visuals(state: Dictionary) -> void:
	var root: Node2D = state["root"]
	var owner: PlayerController = state["owner"]
	root.global_position = owner.global_position
	for index in range(root.get_child_count()):
		var blade: Line2D = root.get_child(index)
		var angle := float(state["angle"]) + TAU * float(index) / float(root.get_child_count())
		var tangent := Vector2(-sin(angle), cos(angle))
		blade.position = Vector2(cos(angle), sin(angle)) * 62.0
		blade.points = PackedVector2Array([-tangent * 42.0, tangent * 42.0])

func _damage_with_blades(state: Dictionary) -> void:
	var owner: PlayerController = state["owner"]
	var cooldowns: Dictionary = state["hit_cooldowns"]
	for enemy in game.enemies.duplicate():
		if not is_instance_valid(enemy) or float(cooldowns.get(enemy.get_instance_id(), 0.0)) > 0.0:
			continue
		if _enemy_touched_by_blade(state["root"], enemy.global_position, 18.0):
			var damage := owner.roll_damage(float(state["damage"]))
			damage_enemy(enemy, damage, owner, owner.global_position, owner.attack_knockback * 0.35)
			cooldowns[enemy.get_instance_id()] = 0.35

func _destroy_projectiles_with_blades(state: Dictionary) -> void:
	for node in game.projectile_root.get_children():
		var projectile := node as EnemyProjectile
		if projectile != null and _enemy_touched_by_blade(state["root"], projectile.global_position, 12.0):
			game._spawn_effect(projectile.global_position, 16.0, Color(0.55, 0.88, 1.0, 0.42), 0.10)
			projectile.queue_free()

func _enemy_touched_by_blade(root: Node2D, position: Vector2, hit_width: float) -> bool:
	for child in root.get_children():
		var blade := child as Line2D
		if blade != null and blade.points.size() >= 2:
			var start := root.global_position + blade.position + blade.points[0]
			var end := root.global_position + blade.position + blade.points[1]
			if _distance_to_segment(position, start, end) <= hit_width:
				return true
	return false

func _distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	if segment.length_squared() <= 0.001:
		return point.distance_to(start)
	var t := clampf((point - start).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return point.distance_to(start + segment * t)

func stop_ultimates() -> void:
	clear_persistent_skill_areas()
	for state in game.ultimate_states.values():
		state["duration_left"] = 0.0
		(state["hit_cooldowns"] as Dictionary).clear()
		(state["root"] as Node2D).visible = false

func clear_ultimate_states() -> void:
	for state in game.ultimate_states.values():
		var root: Node2D = state["root"]
		if is_instance_valid(root):
			root.queue_free()
	game.ultimate_states.clear()

func add_arrow_rain(origin: Vector2, direction: Vector2, damage: float, duration: float, attacker: PlayerController) -> void:
	var forward := direction.normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.RIGHT
	var center := origin + forward * 180.0
	var root := Node2D.new()
	root.name = "ArrowRain_%s" % attacker.name
	game.effect_root.add_child(root)
	game._spawn_area_visual(root, center, 125.0, Color(0.95, 0.78, 0.24, 0.16))
	game.persistent_skill_areas.append({
		"type": "arrow_rain", "owner": attacker, "root": root,
		"duration_left": minf(duration, 6.0), "tick_left": 0.0, "interval": 0.35,
		"origin": center, "radius": 125.0, "damage": damage * 0.26, "hit_counts": {},
	})

func add_lancer_storm(owner: PlayerController, damage: float, duration: float) -> void:
	var root := Node2D.new()
	root.name = "LancerStorm_%s" % owner.name
	root.global_position = owner.global_position
	game.effect_root.add_child(root)
	game._spawn_area_visual(root, Vector2.ZERO, 175.0, Color(0.48, 0.78, 1.0, 0.18))
	game.persistent_skill_areas.append({
		"type": "lancer_storm", "owner": owner, "root": root,
		"duration_left": duration, "tick_left": 0.0, "interval": 0.45,
		"radius": 175.0, "damage": damage * 0.34,
	})

func add_lancer_barricade(origin: Vector2, direction: Vector2, damage: float, duration: float, attacker: PlayerController) -> void:
	var forward := direction.normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.RIGHT
	var center := origin + forward * 135.0
	var root := Node2D.new()
	root.name = "LancerBarricade_%s" % attacker.name
	game.effect_root.add_child(root)
	game._spawn_lancer_barricade_visual(root, center, forward, 280.0, 70.0)
	game.persistent_skill_areas.append({
		"type": "lancer_barricade", "owner": attacker, "root": root,
		"duration_left": minf(duration, 6.0), "tick_left": 0.0, "interval": 0.35,
		"origin": center, "forward": forward, "length": 280.0, "half_depth": 35.0,
		"damage": damage * 0.42,
	})

func add_mage_field(center: Vector2, radius: float, damage: float, attacker: PlayerController) -> void:
	var root := Node2D.new()
	root.name = "MageField_%s" % attacker.name
	game.effect_root.add_child(root)
	game._spawn_area_visual(root, center, radius, Color(0.50, 0.24, 0.92, 0.18))
	game.persistent_skill_areas.append({
		"type": "mage_field", "owner": attacker, "root": root,
		"duration_left": 4.0, "tick_left": 0.0, "interval": 0.50,
		"origin": center, "radius": radius, "damage": damage * 0.10,
	})

func add_mage_storm(center: Vector2, damage: float, duration: float, attacker: PlayerController) -> void:
	var root := Node2D.new()
	root.name = "MageStorm_%s" % attacker.name
	game.effect_root.add_child(root)
	game._spawn_area_visual(root, center, 220.0, Color(0.36, 0.58, 1.0, 0.20))
	game.persistent_skill_areas.append({
		"type": "mage_storm", "owner": attacker, "root": root,
		"duration_left": minf(duration, 8.0), "tick_left": 0.0, "interval": 0.40,
		"origin": center, "radius": 220.0, "damage": damage * 0.12,
	})

func update_persistent_skill_areas(delta: float) -> void:
	for area in game.persistent_skill_areas.duplicate():
		var owner: PlayerController = area.get("owner") as PlayerController
		var duration_left := float(area.get("duration_left", 0.0)) - delta
		area["duration_left"] = duration_left
		if duration_left <= 0.0 or owner == null or not is_instance_valid(owner) or owner.is_dead:
			remove_persistent_skill_area(area)
			continue
		if str(area.get("type", "")) in ["warrior_counter", "lancer_storm"]:
			var tracking_root := area.get("root") as Node2D
			if tracking_root != null:
				tracking_root.global_position = owner.global_position
		var tick_left := float(area.get("tick_left", 0.0)) - delta
		if tick_left > 0.0:
			area["tick_left"] = tick_left
			continue
		area["tick_left"] = float(area.get("interval", 0.35))
		if str(area.get("type", "")) == "arrow_rain":
			_tick_arrow_rain(area, owner)
		elif str(area.get("type", "")) == "lancer_barricade":
			_tick_lancer_barricade(area, owner)
		elif str(area.get("type", "")) == "lancer_storm":
			_tick_lancer_storm(area, owner)
		elif str(area.get("type", "")) == "warrior_counter":
			_tick_warrior_field(area, owner)
		elif str(area.get("type", "")) in ["mage_field", "mage_storm"]:
			_tick_mage_area(area, owner)

func _tick_arrow_rain(area: Dictionary, owner: PlayerController) -> void:
	var center: Vector2 = area.get("origin", owner.global_position) as Vector2
	var radius := float(area.get("radius", 120.0))
	var damage := float(area.get("damage", owner.attack_damage))
	game._spawn_effect(center, radius, Color(1.0, 0.86, 0.28, 0.08), 0.08)
	game._spawn_line_skill_effect(center + Vector2(0.0, -90.0), Vector2.DOWN, 90.0, Color(1.0, 0.82, 0.24, 0.55), 0.10)
	for enemy in game.enemies.duplicate():
		if is_instance_valid(enemy) and enemy.global_position.distance_to(center) <= radius:
			var counts: Dictionary = area.get("hit_counts", {})
			var count := int(counts.get(enemy.get_instance_id(), 0)) + 1
			counts[enemy.get_instance_id()] = count
			damage_enemy(enemy, damage * minf(2.2, 1.0 + 0.18 * float(count - 1)), owner, center, owner.attack_knockback * 0.28)

func _tick_lancer_storm(area: Dictionary, owner: PlayerController) -> void:
	var radius := float(area.get("radius", 175.0))
	var damage := float(area.get("damage", owner.attack_damage))
	var root := area.get("root") as Node2D
	if root != null:
		root.global_position = owner.global_position
	game._spawn_effect(owner.global_position, radius, Color(0.46, 0.78, 1.0, 0.10), 0.12)
	game._spawn_ring_effect(owner.global_position, radius, Color(0.58, 0.88, 1.0, 0.58), 0.18)
	for enemy in game.enemies.duplicate():
		if is_instance_valid(enemy) and enemy.global_position.distance_to(owner.global_position) <= radius:
			damage_enemy(enemy, damage, owner, owner.global_position, owner.attack_knockback * 0.45)

func _tick_warrior_field(area: Dictionary, owner: PlayerController) -> void:
	var radius := float(area.get("radius", 105.0))
	var damage := float(area.get("damage", owner.attack_damage * 0.2))
	var color := Color(0.30, 0.72, 1.0, 0.48)
	game._spawn_ring_effect(owner.global_position, radius, color, 0.16)
	for enemy in game.enemies.duplicate():
		if is_instance_valid(enemy) and enemy.global_position.distance_to(owner.global_position) <= radius:
			damage_enemy(enemy, damage, owner, owner.global_position, owner.attack_knockback * 0.25)

func _tick_lancer_barricade(area: Dictionary, owner: PlayerController) -> void:
	var center: Vector2 = area.get("origin", owner.global_position) as Vector2
	var forward: Vector2 = (area.get("forward", Vector2.RIGHT) as Vector2).normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.RIGHT
	var side_axis := Vector2(-forward.y, forward.x)
	var half_side := float(area.get("length", 260.0)) * 0.5
	var half_depth := float(area.get("half_depth", 35.0))
	var damage := float(area.get("damage", owner.attack_damage))
	for enemy in game.enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		var to_enemy: Vector2 = enemy.global_position - center
		if absf(to_enemy.dot(forward)) <= half_depth and absf(to_enemy.dot(side_axis)) <= half_side:
			var knockback := 0.0 if enemy.is_boss else owner.attack_knockback * 0.55
			damage_enemy(enemy, damage, owner, center - forward * 40.0, knockback)

func _tick_mage_area(area: Dictionary, owner: PlayerController) -> void:
	var center: Vector2 = area.get("origin", owner.global_position) as Vector2
	var radius := float(area.get("radius", 120.0))
	var damage := float(area.get("damage", owner.attack_damage * 0.1))
	var color := Color(0.42, 0.68, 1.0, 0.10) if str(area.get("type", "")) == "mage_storm" else Color(0.72, 0.34, 1.0, 0.10)
	game._spawn_effect(center, radius, color, 0.10)
	game._spawn_ring_effect(center, radius, Color(color.r, color.g, color.b, 0.42), 0.16)
	for enemy in game.enemies.duplicate():
		if is_instance_valid(enemy) and enemy.global_position.distance_to(center) <= radius:
			damage_enemy(enemy, damage, owner, center, owner.attack_knockback * 0.16)

func remove_persistent_skill_area(area: Dictionary) -> void:
	game.persistent_skill_areas.erase(area)
	var root: Node2D = area.get("root") as Node2D
	if root != null and is_instance_valid(root):
		root.queue_free()

func clear_persistent_skill_areas() -> void:
	for area in game.persistent_skill_areas.duplicate():
		remove_persistent_skill_area(area)
	game.persistent_skill_areas.clear()
