extends RefCounted
class_name CombatManager

const EnemyProjectileScript := preload("res://scripts/projectiles/enemy_projectile.gd")
const PlayerProjectileScript := preload("res://scripts/projectiles/player_projectile.gd")
const WarriorCombatScript := preload("res://scripts/characters/warrior_combat.gd")
const ArcherCombatScript := preload("res://scripts/characters/archer_combat.gd")
const LancerCombatScript := preload("res://scripts/characters/lancer_combat.gd")
const MageCombatScript := preload("res://scripts/characters/mage_combat.gd")
const WarriorQVfxTexture := preload("res://assets/effects/warrior/warrior_q_vfx.png")
const WarriorEVfxTexture := preload("res://assets/effects/warrior/warrior_e_vfx.png")
const WarriorFBladeVfxTexture := preload("res://assets/effects/warrior/warrior_f_blade_vfx.png")
const ArcherQVfxTexture := preload("res://assets/effects/archer/archer_q_vfx.png")
const ArcherEVfxTexture := preload("res://assets/effects/archer/archer_e_vfx.png")
const ArcherFVfxTexture := preload("res://assets/effects/archer/archer_f_vfx.png")
const MageQVfxTexture := preload("res://assets/effects/mage/mage_q_vfx.png")
const MageEVfxTexture := preload("res://assets/effects/mage/mage_e_vfx.png")
const MageChainLightningVfxTexture := preload("res://assets/effects/mage/mage_chain_lightning_vfx.png")
const MageFVfxTexture := preload("res://assets/effects/mage/mage_f_vfx.png")
const LancerQVfxTexture := preload("res://assets/effects/lancer/lancer_q_vfx.png")
const LancerEVfxTexture := preload("res://assets/effects/lancer/lancer_e_vfx.png")
const LancerFVfxTexture := preload("res://assets/effects/lancer/lancer_f_vfx.png")
const WarriorSecondaryVfxTexture := preload("res://assets/effects/warrior/warrior_secondary_vfx.png")
const ArcherSecondaryVfxTexture := preload("res://assets/effects/archer/archer_secondary_vfx.png")
const MageSecondaryVfxTexture := preload("res://assets/effects/mage/mage_secondary_vfx.png")
const LancerSecondaryVfxTexture := preload("res://assets/effects/lancer/lancer_secondary_vfx.png")

const WARRIOR_Q_PULL_FORCE := 420.0
const MAGE_ARCANE_REPEL_RADIUS := 110.0
const MAGE_ARCANE_REPEL_DAMAGE_MULTIPLIER := 0.50
const MAGE_ARCANE_REPEL_FORCE := 260.0
const MAGE_ARCANE_REPEL_SLOW_DURATION := 1.5
const MAGE_ARCANE_REPEL_SLOW_MULTIPLIER := 0.75
const MAGE_ARCANE_REPEL_BOSS_SLOW_MULTIPLIER := 0.90

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

func can_player_use_e(origin: Vector2, direction: Vector2, attacker: PlayerController) -> bool:
	return get_character_module(attacker.character_id).can_use_e(self, origin, direction, attacker)

func has_enemy_in_aim_cone(origin: Vector2, direction: Vector2, max_range: float, minimum_dot: float) -> bool:
	var forward := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	for enemy in game.enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		var offset: Vector2 = enemy.global_position - origin
		var distance := offset.length()
		if distance <= max_range and (distance <= 1.0 or offset.normalized().dot(forward) >= minimum_dot):
			return true
	return false

func damage_enemy(enemy: EnemyController, amount: float, attacker: PlayerController, knockback_origin: Vector2 = Vector2.ZERO, knockback_force: float = 90.0, allow_lifesteal: bool = true, cause_stagger: bool = true) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	var wave_multiplier := attacker.wave_damage_multiplier if attacker != null else 1.0
	var final_amount := amount * wave_multiplier * enemy.get_damage_multiplier(attacker)
	var can_transfer_mark := attacker != null and attacker.get_upgrade_level("archer_e_mark_transfer") > 0 and enemy.is_marked_by(attacker)
	var death_position := enemy.global_position
	var effective_amount: float = enemy.apply_damage(final_amount, knockback_origin, knockback_force, cause_stagger)
	if allow_lifesteal:
		apply_lifesteal(attacker, effective_amount)
	if can_transfer_mark and enemy.health <= 0.0:
		transfer_hunter_mark(death_position, attacker, enemy)

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

func _on_enemy_projectile_hit_player(damage: float, target: Node2D, source) -> void:
	var player := target as PlayerController
	if player != null:
		var valid_source: EnemyController = null
		if source != null and is_instance_valid(source):
			valid_source = source as EnemyController
		player.apply_damage(damage, valid_source)

func on_enemy_area_attack_requested(enemy: EnemyController, origin: Vector2, radius: float, damage: float, windup_time: float) -> void:
	if game.SHOW_ENEMY_ATTACK_TELEGRAPH:
		game._spawn_effect(origin, radius, Color(1.0, 0.18, 0.12, 0.22), windup_time)
	var enemy_ref: WeakRef = weakref(enemy)
	var game_ref: WeakRef = weakref(game)
	var timer: SceneTreeTimer = game.get_tree().create_timer(windup_time)
	timer.timeout.connect(func() -> void:
		var active_game: Node = game_ref.get_ref()
		if active_game == null or not is_instance_valid(active_game):
			return
		active_game._spawn_effect(origin, radius, Color(1.0, 0.34, 0.20, 0.30), 0.16)
		var source: EnemyController = null
		var source_object: Object = enemy_ref.get_ref()
		if source_object != null and is_instance_valid(source_object):
			source = source_object as EnemyController
		for player in active_game.players:
			if is_instance_valid(player) and not player.is_dead and player.global_position.distance_to(origin) <= radius:
				player.apply_damage(damage, source)
				active_game._spawn_effect(player.global_position, 34.0, Color(1.0, 0.25, 0.22, 0.24), 0.10)
	)

func on_enemy_charge_started(_enemy: EnemyController, origin: Vector2, direction: Vector2, length: float, windup_time: float) -> void:
	game._spawn_line_skill_effect(origin, direction, length, Color(1.0, 0.24, 0.16, 0.68), windup_time)

func on_enemy_self_destruct_requested(enemy: EnemyController, origin: Vector2, radius: float, damage: float) -> void:
	game._spawn_effect(origin, radius, Color(1.0, 0.28, 0.12, 0.38), 0.18)
	game._spawn_ring_effect(origin, radius, Color(1.0, 0.58, 0.18, 0.90), 0.22)
	for player in game.players:
		if is_instance_valid(player) and not player.is_dead and player.global_position.distance_to(origin) <= radius:
			player.apply_damage(damage, enemy)

func on_enemy_healing_started(_enemy: EnemyController, origin: Vector2, radius: float, windup_time: float) -> void:
	game._spawn_ring_effect(origin, radius, Color(0.35, 1.0, 0.48, 0.62), windup_time)

func on_enemy_healing_requested(enemy: EnemyController, origin: Vector2, radius: float, amount: float) -> void:
	game._spawn_effect(origin, radius, Color(0.28, 1.0, 0.46, 0.20), 0.20)
	for ally in game.enemies.duplicate():
		if not is_instance_valid(ally) or ally == enemy or ally.global_position.distance_to(origin) > radius:
			continue
		var healed_amount: float = ally.heal(amount)
		if healed_amount > 0.0:
			game._spawn_ring_effect(ally.global_position, 24.0, Color(0.35, 1.0, 0.48, 0.72), 0.16)

func on_player_damage_taken(amount: float, defended: bool, player: PlayerController) -> void:
	game.damage_taken += amount
	var color := Color(0.35, 0.72, 1.0, 0.28) if defended else Color(1.0, 0.25, 0.22, 0.24)
	game._spawn_effect(player.global_position, 42.0 if defended else 34.0, color, 0.10)
	game._spawn_damage_number(player.global_position + Vector2(-12.0, -46.0), amount, color)

func on_player_reflected_damage(enemy: EnemyController, amount: float, player: PlayerController) -> void:
	game._spawn_link_effect(player.global_position, enemy.global_position, Color(0.35, 0.78, 1.0, 0.90), 0.16)
	game._spawn_textured_effect(player.global_position, WarriorEVfxTexture, 82.0, 0.18, "WarriorCounterFlash")
	game._spawn_spark_burst(player.global_position, Color(0.45, 0.86, 1.0, 0.92), 8, 42.0, 0.18)
	damage_enemy(enemy, amount, player, player.global_position, 0.0, false)

func on_player_perfect_guard(player: PlayerController) -> void:
	game._spawn_ring_effect(player.global_position, 115.0, Color(0.38, 0.82, 1.0, 0.85), 0.20)
	game._spawn_textured_effect(player.global_position, WarriorEVfxTexture, 132.0, 0.22, "WarriorPerfectGuardFlash")
	game._spawn_spark_burst(player.global_position, Color(0.72, 0.94, 1.0, 0.96), 12, 62.0, 0.22)
	damage_enemies_in_radius(player.global_position, 115.0, player.fan_skill_damage * 0.22, player)

func spawn_warrior_q_vfx(origin: Vector2, radius: float) -> void:
	game._spawn_textured_effect(origin, WarriorQVfxTexture, radius * 2.0, 0.32, "WarriorQEffect")
	game._spawn_ring_effect(origin, radius * 0.72, Color(1.0, 0.72, 0.20, 0.82), 0.28)
	game._spawn_inward_streaks(origin, radius, Color(1.0, 0.42, 0.12, 0.90), 16, 0.34)

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
		var pull_force := 0.0 if enemy.is_boss else WARRIOR_Q_PULL_FORCE
		damage_enemy(enemy, damage, owner, pull_origin, pull_force)

func add_warrior_counter_field(owner: PlayerController, damage: float, duration: float) -> void:
	var root := Node2D.new()
	root.name = "WarriorCounter_%s" % owner.name
	root.global_position = owner.global_position
	game.effect_root.add_child(root)
	game._spawn_area_visual(root, Vector2.ZERO, 105.0, Color(0.22, 0.58, 1.0, 0.10))
	var outer_aura: Sprite2D = game._add_textured_effect(root, WarriorEVfxTexture, 210.0, Vector2.ZERO, Color(1.0, 1.0, 1.0, 0.38), "WarriorCounterTexture")
	var inner_aura: Sprite2D = game._add_textured_effect(root, WarriorEVfxTexture, 158.0, Vector2.ZERO, Color(0.68, 0.88, 1.0, 0.18), "WarriorCounterInnerTexture")
	inner_aura.flip_h = true
	game._animate_effect_rotation(outer_aura, 3.6, true)
	game._animate_effect_rotation(inner_aura, 2.8, false)
	game._animate_effect_pulse(outer_aura, 0.24, 0.46, 0.72)
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
		var distance := offset.length()
		if distance > max_range or (distance > 1.0 and offset.normalized().dot(forward) < 0.35):
			continue
		var score := distance - (offset.normalized().dot(forward) * 80.0 if distance > 1.0 else 80.0)
		if score < best_score:
			best = enemy
			best_score = score
	if best != null:
		best.apply_hunter_mark(owner, duration, multiplier)
		_attach_archer_mark_vfx(best, duration)
		game._spawn_effect(best.global_position, 34.0, Color(1.0, 0.25, 0.18, 0.30), 0.18)
		game._spawn_ring_effect(best.global_position, 34.0, Color(1.0, 0.72, 0.18, 0.90), 0.30)

func transfer_hunter_mark(origin: Vector2, owner: PlayerController, excluded_enemy: EnemyController) -> void:
	var best: EnemyController
	var best_health := -1.0
	for enemy in game.enemies.duplicate():
		if not is_instance_valid(enemy) or enemy == excluded_enemy or enemy.global_position.distance_to(origin) > 320.0:
			continue
		if enemy.health > best_health:
			best = enemy
			best_health = enemy.health
	if best != null:
		best.apply_hunter_mark(owner, 12.0, 1.70)
		_attach_archer_mark_vfx(best, 12.0)
		game._spawn_link_effect(origin, best.global_position, Color(1.0, 0.72, 0.18, 0.85), 0.20)

func _attach_archer_mark_vfx(target: EnemyController, duration: float) -> void:
	var root := Node2D.new()
	root.name = "ArcherMarkVFX"
	root.position = Vector2(0.0, -16.0)
	target.add_child(root)
	var outer: Sprite2D = game._add_textured_effect(root, ArcherEVfxTexture, 78.0, Vector2.ZERO, Color(1.0, 1.0, 1.0, 0.78), "ArcherMarkTexture")
	var inner: Sprite2D = game._add_textured_effect(root, ArcherEVfxTexture, 54.0, Vector2.ZERO, Color(1.0, 0.70, 0.92, 0.42), "ArcherMarkInnerTexture")
	inner.flip_h = true
	game._animate_effect_rotation(outer, 3.2, true)
	game._animate_effect_rotation(inner, 2.1, false)
	game._animate_effect_pulse(outer, 0.44, 0.88, 0.72)
	var timer := game.get_tree().create_timer(duration)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(root):
			root.queue_free()
	)

func cast_chain_lightning(origin: Vector2, direction: Vector2, damage: float, owner: PlayerController, empowered: bool) -> void:
	game._spawn_textured_effect(origin, MageEVfxTexture, 118.0, 0.24, "MageChainCast")
	game._spawn_spark_burst(origin, Color(0.42, 0.72, 1.0, 0.94), 10, 46.0, 0.18)
	var remaining: Array[EnemyController] = []
	for enemy in game.enemies.duplicate():
		if is_instance_valid(enemy):
			remaining.append(enemy)
	var current_position := origin
	var max_targets := 8 if empowered else 5
	var jump_range := 210.0 if empowered else 160.0
	var hit_count := 0
	while hit_count < max_targets and not remaining.is_empty():
		var best: EnemyController
		var best_distance := INF
		for enemy in remaining:
			var distance := enemy.global_position.distance_to(current_position)
			if hit_count == 0:
				var forward := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
				var offset := enemy.global_position - origin
				if distance > 320.0 or (distance > 1.0 and offset.normalized().dot(forward) < 0.25):
					continue
			elif distance > jump_range:
				continue
			if distance < best_distance:
				best = enemy
				best_distance = distance
		if best == null:
			break
		var hit_damage := damage if empowered else damage * pow(0.85, hit_count)
		_spawn_mage_chain_lightning(current_position, best.global_position)
		game._spawn_spark_burst(best.global_position, Color(0.34, 0.78, 1.0, 0.94), 7, 32.0, 0.16)
		damage_enemy(best, hit_damage, owner, current_position, 0.0)
		current_position = best.global_position
		remaining.erase(best)
		hit_count += 1

func _spawn_mage_chain_lightning(start: Vector2, finish: Vector2) -> void:
	var offset := finish - start
	var distance := maxf(offset.length(), 1.0)
	var sprite := Sprite2D.new()
	sprite.name = "MageChainLightning"
	sprite.texture = MageChainLightningVfxTexture
	sprite.global_position = start.lerp(finish, 0.5)
	sprite.rotation = offset.angle()
	sprite.scale = Vector2(
		distance / maxf(float(MageChainLightningVfxTexture.get_width()), 1.0),
		0.36
	)
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sprite.material = material
	game.effect_root.add_child(sprite)
	var tween := sprite.create_tween().set_parallel(true)
	tween.tween_property(sprite, "scale:y", sprite.scale.y * 0.72, 0.18)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.18)
	tween.finished.connect(Callable(sprite, "queue_free"))

func lancer_dash_spin(owner: PlayerController, direction: Vector2, distance: float, damage: float) -> void:
	var forward := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	var start := owner.global_position
	owner.global_position = (owner.global_position + forward * distance).clamp(owner.arena_bounds.position, owner.arena_bounds.end)
	damage_enemies_in_radius(owner.global_position, 120.0, damage, owner)
	game._spawn_effect(owner.global_position, 120.0, Color(0.58, 0.86, 1.0, 0.22), 0.16)
	_spawn_lancer_dash_vfx(start, owner.global_position, forward)

func spawn_lancer_sweep_vfx(origin: Vector2, direction: Vector2, length: float, half_width: float) -> void:
	game._spawn_lancer_sweep_effect(origin, direction, length, half_width, LancerQVfxTexture)

func _spawn_lancer_dash_vfx(start: Vector2, finish: Vector2, forward: Vector2) -> void:
	var root := Node2D.new()
	root.name = "LancerDashVFX"
	game.effect_root.add_child(root)
	var distance := maxf(start.distance_to(finish), 80.0)
	var spear: Sprite2D = game._add_textured_effect(root, LancerEVfxTexture, distance * 1.45, start.lerp(finish, 0.5), Color.WHITE, "LancerDashTexture")
	spear.rotation = forward.angle()
	var trail := Line2D.new()
	trail.name = "LancerDashTrail"
	trail.width = 8.0
	trail.default_color = Color(0.58, 0.94, 1.0, 0.72)
	trail.points = PackedVector2Array([start, finish])
	root.add_child(trail)
	var tween := root.create_tween().set_parallel(true)
	tween.tween_property(spear, "modulate:a", 0.0, 0.20)
	tween.tween_property(trail, "modulate:a", 0.0, 0.20)
	tween.finished.connect(Callable(root, "queue_free"))
	game._spawn_spark_burst(finish, Color(0.70, 0.96, 1.0, 0.94), 12, 68.0, 0.20)

func schedule_lancer_second_sweep(owner: PlayerController, damage: float) -> void:
	var timer := game.get_tree().create_timer(0.18)
	timer.timeout.connect(func() -> void:
		if owner != null and is_instance_valid(owner) and not owner.is_dead:
			game._spawn_ring_effect(owner.global_position, 165.0, Color(0.62, 0.90, 1.0, 0.78), 0.20)
			spawn_lancer_sweep_vfx(owner.global_position, Vector2.RIGHT.rotated(randf_range(0.0, TAU)), 165.0, 90.0)
			damage_enemies_in_radius(owner.global_position, 165.0, damage * 0.75, owner)
	)

func on_player_basic_attack(origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float, attacker: PlayerController) -> void:
	get_character_module(attacker.character_id).basic_attack(self, origin, direction, length, half_width, damage, attacker)

func on_player_projectile_attack(origin: Vector2, direction: Vector2, damage: float, attacker: PlayerController) -> void:
	get_character_module(attacker.character_id).basic_attack(self, origin, direction, attacker.attack_range, attacker.attack_half_width, damage, attacker)

func on_player_secondary_action(origin: Vector2, direction: Vector2, damage: float, attacker: PlayerController) -> void:
	var forward := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	match attacker.character_id:
		"warrior":
			_show_warrior_secondary_vfx(attacker, forward)
		"archer":
			var projectile_origin := attacker.get_projectile_origin(forward)
			for angle in [-0.20, 0.0, 0.20]:
				var arrow_direction := forward.rotated(float(angle))
				fire_player_arrow(projectile_origin, arrow_direction, damage * 0.60, attacker, 560.0, 1.2, 18.0, "", 672.0 * attacker.get_attack_range_multiplier())
			game._spawn_line_skill_effect(projectile_origin, forward, 72.0, Color(1.0, 0.80, 0.30, 0.50), 0.10)
			_spawn_secondary_directional_vfx(projectile_origin, forward, ArcherSecondaryVfxTexture, 172.0, "ArcherSecondaryVFX", 0.20)
			game._spawn_spark_burst(projectile_origin, Color(1.0, 0.70, 0.30, 0.94), 10, 54.0, 0.18)
		"mage":
			cast_mage_arcane_repel(origin, damage, attacker)
		"lancer":
			damage_enemies_on_both_sides(origin, forward, attacker.attack_range * 1.35, attacker.attack_half_width * 1.40, damage * 0.80, attacker)
			_spawn_secondary_directional_vfx(origin, forward, LancerSecondaryVfxTexture, attacker.attack_range * 2.9, "LancerSecondaryVFX", 0.22)
			game._spawn_spark_burst(origin, Color(0.68, 0.96, 1.0, 0.94), 12, attacker.attack_half_width * 1.8, 0.18)

func _show_warrior_secondary_vfx(attacker: PlayerController, forward: Vector2) -> void:
	attacker._remove_warrior_secondary_vfx()
	var root := Node2D.new()
	root.name = "WarriorSecondaryVFX"
	attacker.add_child(root)
	var shield: Sprite2D = game._add_textured_effect(root, WarriorSecondaryVfxTexture, 132.0, forward * 24.0, Color(1.0, 1.0, 1.0, 0.88), "Texture")
	shield.rotation = forward.angle()
	game._animate_effect_pulse(shield, 0.54, 0.92, 0.48)

func _spawn_secondary_directional_vfx(origin: Vector2, forward: Vector2, texture: Texture2D, diameter: float, node_name: String, lifetime: float) -> void:
	var root := Node2D.new()
	root.name = node_name
	game.effect_root.add_child(root)
	var sprite: Sprite2D = game._add_textured_effect(root, texture, diameter, origin, Color.WHITE, "Texture")
	sprite.rotation = forward.angle()
	var target_scale := sprite.scale * 1.10
	sprite.scale *= 0.72
	var tween := sprite.create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", target_scale, lifetime)
	tween.tween_property(sprite, "modulate:a", 0.0, lifetime)
	tween.finished.connect(Callable(root, "queue_free"))

func cast_mage_arcane_repel(origin: Vector2, damage: float, attacker: PlayerController) -> void:
	for enemy in game.enemies.duplicate():
		if not is_instance_valid(enemy) or enemy.global_position.distance_to(origin) > MAGE_ARCANE_REPEL_RADIUS:
			continue
		var slow_multiplier := MAGE_ARCANE_REPEL_BOSS_SLOW_MULTIPLIER if enemy.is_boss else MAGE_ARCANE_REPEL_SLOW_MULTIPLIER
		var knockback_force := 0.0 if enemy.is_boss else MAGE_ARCANE_REPEL_FORCE
		enemy.apply_slow(MAGE_ARCANE_REPEL_SLOW_DURATION, slow_multiplier)
		damage_enemy(enemy, damage * MAGE_ARCANE_REPEL_DAMAGE_MULTIPLIER, attacker, origin, knockback_force)
	game._spawn_effect(origin, MAGE_ARCANE_REPEL_RADIUS, Color(0.62, 0.38, 1.0, 0.22), 0.14)
	game._spawn_ring_effect(origin, MAGE_ARCANE_REPEL_RADIUS, Color(0.78, 0.58, 1.0, 0.80), 0.20)
	_spawn_secondary_directional_vfx(origin, Vector2.RIGHT, MageSecondaryVfxTexture, MAGE_ARCANE_REPEL_RADIUS * 2.25, "MageSecondaryVFX", 0.24)
	game._spawn_spark_burst(origin, Color(0.64, 0.52, 1.0, 0.92), 16, MAGE_ARCANE_REPEL_RADIUS, 0.22)

func damage_enemies_on_both_sides(origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float, attacker: PlayerController) -> void:
	var forward := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	var side := Vector2(-forward.y, forward.x)
	for enemy in game.enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		var offset: Vector2 = enemy.global_position - origin
		if absf(offset.dot(forward)) <= length and absf(offset.dot(side)) <= half_width:
			damage_enemy(enemy, damage, attacker, origin, attacker.attack_knockback * 0.45)

func fire_player_arrow(origin: Vector2, direction: Vector2, damage: float, attacker: PlayerController, speed: float = 560.0, lifetime: float = 1.2, hit_radius: float = 18.0, visual_texture_path: String = "", max_distance: float = 0.0, visual_size: Vector2 = Vector2.ZERO, visual_additive: bool = false) -> PlayerProjectile:
	var projectile = PlayerProjectileScript.new()
	projectile.global_position = origin
	projectile.direction = direction
	projectile.damage = damage
	projectile.speed = speed
	projectile.lifetime = lifetime
	projectile.hit_radius = hit_radius
	projectile.visual_texture_path = visual_texture_path
	projectile.visual_size = visual_size
	projectile.visual_additive = visual_additive
	projectile.max_distance = max_distance
	projectile.enemies = game.enemies
	projectile.hit_enemy.connect(_on_player_projectile_hit_enemy.bind(attacker))
	game.projectile_root.add_child(projectile)
	return projectile

func decorate_archer_q_projectile(projectile: PlayerProjectile, origin: Vector2, fully_charged: bool) -> void:
	if projectile == null or not is_instance_valid(projectile):
		return
	var trail := Line2D.new()
	trail.name = "ArcherQTrail"
	trail.width = 13.0 if fully_charged else 9.0
	trail.points = PackedVector2Array([Vector2(-108.0, 0.0), Vector2(-52.0, 0.0), Vector2(-12.0, 0.0)])
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(0.92, 0.12, 0.58, 0.0),
		Color(1.0, 0.36, 0.22, 0.42),
		Color(1.0, 0.88, 0.34, 0.92),
	])
	trail.gradient = gradient
	projectile.add_child(trail)
	var texture_sprite := projectile.get_node_or_null("Texture") as Sprite2D
	if texture_sprite != null:
		game._animate_effect_pulse(texture_sprite, 0.72, 1.0, 0.20)
	game._spawn_textured_effect(origin, ArcherQVfxTexture, 108.0 if fully_charged else 82.0, 0.18, "ArcherQLaunchFlash")
	game._spawn_spark_burst(origin, Color(1.0, 0.72, 0.22, 0.92), 12 if fully_charged else 8, 48.0 if fully_charged else 38.0, 0.16)

func fire_mage_fireball(origin: Vector2, direction: Vector2, damage: float, attacker: PlayerController, explosion_radius: float, max_range: float) -> void:
	var projectile = PlayerProjectileScript.new()
	projectile.global_position = origin
	projectile.direction = direction
	projectile.damage = damage
	projectile.speed = 420.0
	projectile.lifetime = 1.5
	projectile.hit_radius = 25.0
	projectile.scale = Vector2.ONE * 1.25
	projectile.visual_texture_path = "res://assets/effects/mage/mage_q_vfx.png"
	projectile.visual_size = Vector2(94.0, 68.0)
	projectile.visual_additive = true
	projectile.max_distance = max_range
	projectile.enemies = game.enemies
	projectile.hit_enemy.connect(_on_mage_fireball_hit.bind(attacker, explosion_radius))
	projectile.reached_max_distance.connect(_on_mage_fireball_reached_limit.bind(damage, attacker, explosion_radius))
	game.projectile_root.add_child(projectile)
	_decorate_mage_q_projectile(projectile, origin)
	game._spawn_line_skill_effect(origin, direction, 58.0, Color(0.88, 0.42, 1.0, 0.42), 0.10)

func _decorate_mage_q_projectile(projectile: PlayerProjectile, origin: Vector2) -> void:
	var trail := Line2D.new()
	trail.name = "MageQTrail"
	trail.width = 11.0
	trail.points = PackedVector2Array([Vector2(-76.0, 0.0), Vector2(-38.0, 0.0), Vector2(-8.0, 0.0)])
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(0.18, 0.52, 1.0, 0.0),
		Color(0.48, 0.20, 1.0, 0.48),
		Color(0.84, 0.62, 1.0, 0.94),
	])
	trail.gradient = gradient
	projectile.add_child(trail)
	var texture_sprite := projectile.get_node_or_null("Texture") as Sprite2D
	if texture_sprite != null:
		game._animate_effect_pulse(texture_sprite, 0.72, 1.0, 0.22)
	game._spawn_textured_effect(origin, MageQVfxTexture, 88.0, 0.18, "MageQCastFlash")

func fire_mage_basic_projectile(origin: Vector2, direction: Vector2, damage: float, attacker: PlayerController) -> void:
	var projectile = PlayerProjectileScript.new()
	projectile.global_position = origin
	projectile.direction = direction
	projectile.damage = damage
	projectile.speed = 480.0
	projectile.lifetime = 1.35
	projectile.hit_radius = 18.0
	projectile.visual_texture_path = "res://assets/original/characters/mage/mage_basic_projectile.svg"
	projectile.max_distance = 648.0 * attacker.get_attack_range_multiplier()
	projectile.enemies = game.enemies
	projectile.hit_enemy.connect(_on_mage_basic_projectile_hit.bind(attacker))
	game.projectile_root.add_child(projectile)

func fire_mage_single_projectile(origin: Vector2, direction: Vector2, damage: float, attacker: PlayerController) -> void:
	fire_player_arrow(origin, direction, damage, attacker, 480.0, 1.35, 18.0, "res://assets/original/characters/mage/mage_basic_projectile.svg", 648.0 * attacker.get_attack_range_multiplier())

func _on_mage_basic_projectile_hit(enemy: EnemyController, damage: float, attacker: PlayerController) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	var impact := enemy.global_position
	game._spawn_effect(impact, 70.0, Color(0.72, 0.38, 1.0, 0.24), 0.12)
	damage_enemies_in_radius(impact, 70.0, damage, attacker)

func _on_mage_fireball_hit(enemy: EnemyController, damage: float, attacker: PlayerController, explosion_radius: float) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	var impact := enemy.global_position
	_mage_fireball_explode(impact, damage, attacker, explosion_radius)

func _on_mage_fireball_reached_limit(impact: Vector2, damage: float, attacker: PlayerController, explosion_radius: float) -> void:
	_mage_fireball_explode(impact, damage, attacker, explosion_radius)

func _mage_fireball_explode(impact: Vector2, damage: float, attacker: PlayerController, explosion_radius: float) -> void:
	game._spawn_effect(impact, explosion_radius, Color(0.82, 0.30, 1.0, 0.30), 0.16)
	_spawn_mage_q_explosion(impact, explosion_radius)
	damage_enemies_in_radius(impact, explosion_radius, damage, attacker)

func _spawn_mage_q_explosion(impact: Vector2, radius: float) -> void:
	var root := Node2D.new()
	root.name = "MageQExplosion"
	root.global_position = impact
	game.effect_root.add_child(root)
	for index in range(3):
		var burst: Sprite2D = game._add_textured_effect(root, MageQVfxTexture, radius * 2.15, Vector2.ZERO, Color(1.0, 1.0, 1.0, 0.82), "Burst%d" % index)
		burst.rotation = TAU * float(index) / 3.0
		var final_scale := burst.scale * 1.18
		burst.scale *= 0.62
		var tween := burst.create_tween().set_parallel(true)
		tween.tween_property(burst, "scale", final_scale, 0.22)
		tween.tween_property(burst, "modulate:a", 0.0, 0.22)
	game._spawn_spark_burst(impact, Color(0.50, 0.72, 1.0, 0.96), 14, radius * 0.82, 0.22)
	var timer := game.get_tree().create_timer(0.24)
	timer.timeout.connect(Callable(root, "queue_free"))

func _on_player_projectile_hit_enemy(enemy: EnemyController, damage: float, attacker: PlayerController) -> void:
	if attacker != null and attacker.character_id == "archer" and enemy.consume_guaranteed_arrow_crit(attacker):
		damage *= attacker.crit_multiplier
	damage_enemy(enemy, damage, attacker, attacker.global_position, attacker.attack_knockback)

func on_player_active_skill(origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float, attacker: PlayerController) -> void:
	get_character_module(attacker.character_id).use_q(self, origin, direction, length, half_width, damage, attacker)

func on_player_fan_skill(origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float, attacker: PlayerController) -> void:
	get_character_module(attacker.character_id).use_e(self, origin, direction, length, half_width, damage, attacker)

func on_player_ultimate_skill(origin: Vector2, direction: Vector2, damage: float, duration: float, attacker: PlayerController) -> void:
	get_character_module(attacker.character_id).use_f(self, origin, direction, damage, duration, attacker)

func start_blade_ultimate(owner: PlayerController, damage: float, duration: float) -> void:
	var state: Dictionary = _get_ultimate_state(owner)
	_sync_warrior_blade_count(state, 3 if owner.get_upgrade_level("warrior_f_extra_blade") > 0 else 2)
	state["duration_left"] = duration
	state["angle"] = 0.0
	state["damage"] = damage
	(state["hit_cooldowns"] as Dictionary).clear()
	(state["root"] as Node2D).visible = true
	game._spawn_ring_effect(owner.global_position, 92.0, Color(1.0, 0.48, 0.12, 0.88), 0.28)
	game._spawn_spark_burst(owner.global_position, Color(1.0, 0.68, 0.16, 0.94), 14, 82.0, 0.24)
	if owner.get_upgrade_level("warrior_f_attack_defense") > 0:
		owner.activate_warrior_blade_guard(duration)

func setup_ultimate(owner: PlayerController) -> void:
	var root := Node2D.new()
	root.name = "UltimateBlades_%s" % owner.name
	root.visible = false
	game.add_child(root)
	for index in range(2):
		_add_ultimate_blade(root, index)
	game.ultimate_states[owner.get_instance_id()] = {"owner": owner, "root": root, "duration_left": 0.0, "angle": 0.0, "damage": 0.0, "hit_cooldowns": {}}

func _sync_warrior_blade_count(state: Dictionary, desired_count: int) -> void:
	var root := state["root"] as Node2D
	while root.get_child_count() < desired_count:
		_add_ultimate_blade(root, root.get_child_count())
	while root.get_child_count() > desired_count:
		var blade := root.get_child(root.get_child_count() - 1)
		root.remove_child(blade)
		blade.queue_free()

func _add_ultimate_blade(root: Node2D, index: int) -> void:
	var blade := Node2D.new()
	blade.name = "Blade%d" % index
	var trail := Line2D.new()
	trail.name = "Trail"
	trail.width = 16.0
	trail.points = PackedVector2Array([Vector2(-64.0, 0.0), Vector2(-38.0, 0.0), Vector2(-10.0, 0.0)])
	var trail_gradient := Gradient.new()
	trail_gradient.colors = PackedColorArray([
		Color(1.0, 0.12, 0.02, 0.0),
		Color(1.0, 0.32, 0.04, 0.42),
		Color(1.0, 0.78, 0.22, 0.82),
	])
	trail.gradient = trail_gradient
	blade.add_child(trail)
	var texture_sprite: Sprite2D = game._add_textured_effect(blade, WarriorFBladeVfxTexture, 112.0, Vector2.ZERO, Color.WHITE, "Texture")
	game._animate_effect_pulse(texture_sprite, 0.72, 1.0, 0.26)
	root.add_child(blade)

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
	var attack_defense := owner.get_upgrade_level("warrior_f_attack_defense") > 0
	var rotation_speed := 11.0 if attack_defense and owner.is_defending else 7.2
	state["angle"] = float(state.get("angle", 0.0)) + rotation_speed * delta
	var cooldowns: Dictionary = state["hit_cooldowns"]
	for key in cooldowns.keys():
		cooldowns[key] = maxf(0.0, float(cooldowns[key]) - delta)
	_update_blade_visuals(state)
	_damage_with_blades(state)
	if owner.get_upgrade_level("warrior_f_projectile_guard") > 0:
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
		var blade: Node2D = root.get_child(index) as Node2D
		var angle := float(state["angle"]) + TAU * float(index) / float(root.get_child_count())
		var tangent := Vector2(-sin(angle), cos(angle))
		blade.position = Vector2(cos(angle), sin(angle)) * 62.0
		blade.rotation = tangent.angle()

func _damage_with_blades(state: Dictionary) -> void:
	var owner: PlayerController = state["owner"]
	var cooldowns: Dictionary = state["hit_cooldowns"]
	for enemy in game.enemies.duplicate():
		if not is_instance_valid(enemy) or float(cooldowns.get(enemy.get_instance_id(), 0.0)) > 0.0:
			continue
		if _enemy_touched_by_blade(state["root"], enemy.global_position, 18.0):
			var damage := owner.roll_damage(float(state["damage"]))
			damage_enemy(enemy, damage, owner, owner.global_position, owner.attack_knockback * 0.35)
			game._spawn_spark_burst(enemy.global_position, Color(1.0, 0.58, 0.12, 0.94), 7, 30.0, 0.16)
			cooldowns[enemy.get_instance_id()] = 0.35

func _destroy_projectiles_with_blades(state: Dictionary) -> void:
	for node in game.projectile_root.get_children():
		var projectile := node as EnemyProjectile
		if projectile != null and _enemy_touched_by_blade(state["root"], projectile.global_position, 12.0):
			game._spawn_effect(projectile.global_position, 16.0, Color(0.55, 0.88, 1.0, 0.42), 0.10)
			projectile.queue_free()

func _enemy_touched_by_blade(root: Node2D, position: Vector2, hit_width: float) -> bool:
	for child in root.get_children():
		var blade := child as Node2D
		if blade == null:
			continue
		var tangent := Vector2.RIGHT.rotated(blade.rotation)
		var center := root.global_position + blade.position
		if _distance_to_segment(position, center - tangent * 42.0, center + tangent * 42.0) <= hit_width:
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

func throw_warrior_shield(origin: Vector2, direction: Vector2, damage: float, owner: PlayerController) -> void:
	var forward := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	var root := Node2D.new()
	root.name = "WarriorShield_%s" % owner.name
	game.effect_root.add_child(root)
	game._spawn_area_visual(root, Vector2.ZERO, 20.0, Color(0.35, 0.72, 1.0, 0.34))
	var shield_texture: Sprite2D = game._add_textured_effect(root, WarriorEVfxTexture, 58.0, Vector2.ZERO, Color.WHITE, "WarriorShieldTexture")
	game._animate_effect_rotation(shield_texture, 0.62, true)
	game.persistent_skill_areas.append({
		"type": "warrior_shield", "owner": owner, "root": root, "duration_left": 2.0,
		"origin": origin, "direction": forward, "travel": 0.0, "max_travel": 280.0,
		"speed": 620.0, "damage": damage * 0.80, "returning": false,
		"hit_ids": {}, "hit_any": false,
		"guard_upgrade": owner.get_upgrade_level("warrior_e_shield_guard") > 0,
	})

func throw_lancer_spear(origin: Vector2, direction: Vector2, damage: float, owner: PlayerController, returns: bool) -> void:
	var forward := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	var root := Node2D.new()
	root.name = "LancerSpear_%s" % owner.name
	game.effect_root.add_child(root)
	var spear: Sprite2D = game._add_textured_effect(root, LancerEVfxTexture, 104.0, Vector2.ZERO, Color.WHITE, "LancerSpearTexture")
	var trail := Line2D.new()
	trail.name = "LancerSpearTrail"
	trail.width = 5.0
	trail.default_color = Color(0.52, 0.92, 1.0, 0.68)
	trail.points = PackedVector2Array([Vector2(-62.0, 0.0), Vector2(-12.0, 0.0)])
	root.add_child(trail)
	game._animate_effect_pulse(spear, 0.72, 1.0, 0.22)
	game.persistent_skill_areas.append({
		"type": "lancer_spear", "owner": owner, "root": root, "duration_left": 2.0,
		"origin": origin, "direction": forward, "travel": 0.0, "max_travel": 320.0,
		"speed": 720.0, "damage": damage * 0.90, "returning": false,
		"returns": returns, "hit_ids": {},
	})

func place_archer_trap(origin: Vector2, direction: Vector2, owner: PlayerController) -> void:
	var forward := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	owner.global_position = (owner.global_position - forward * 100.0).clamp(owner.arena_bounds.position, owner.arena_bounds.end)
	var root := Node2D.new()
	root.name = "ArcherTrap_%s" % owner.name
	game.effect_root.add_child(root)
	game._spawn_area_visual(root, origin, 34.0, Color(1.0, 0.72, 0.18, 0.24))
	var outer: Sprite2D = game._add_textured_effect(root, ArcherEVfxTexture, 82.0, origin, Color(1.0, 1.0, 1.0, 0.74), "ArcherTrapTexture")
	var inner: Sprite2D = game._add_textured_effect(root, ArcherEVfxTexture, 58.0, origin, Color(0.98, 0.54, 0.92, 0.38), "ArcherTrapInnerTexture")
	inner.flip_h = true
	game._animate_effect_rotation(outer, 4.0, true)
	game._animate_effect_rotation(inner, 2.7, false)
	game._animate_effect_pulse(outer, 0.40, 0.82, 0.84)
	game.persistent_skill_areas.append({
		"type": "archer_trap", "owner": owner, "root": root,
		"duration_left": 6.0, "tick_left": 0.0, "interval": 0.05,
		"origin": origin, "radius": 34.0,
		"execution_upgrade": owner.get_upgrade_level("archer_e_execution_trap") > 0,
	})

func add_arrow_rain(origin: Vector2, direction: Vector2, damage: float, duration: float, attacker: PlayerController) -> void:
	var forward := direction.normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.RIGHT
	var center := origin + forward * 180.0
	var root := Node2D.new()
	root.name = "ArrowRain_%s" % attacker.name
	game.effect_root.add_child(root)
	game._spawn_area_visual(root, center, 125.0, Color(0.95, 0.78, 0.24, 0.16))
	var outer: Sprite2D = game._add_textured_effect(root, ArcherFVfxTexture, 258.0, center, Color(1.0, 1.0, 1.0, 0.58), "ArcherRainTexture")
	var inner: Sprite2D = game._add_textured_effect(root, ArcherFVfxTexture, 214.0, center, Color(1.0, 0.68, 0.92, 0.24), "ArcherRainInnerTexture")
	inner.flip_h = true
	game._animate_effect_rotation(outer, 8.0, true)
	game._animate_effect_rotation(inner, 6.0, false)
	game._animate_effect_pulse(outer, 0.34, 0.68, 0.92)
	game.persistent_skill_areas.append({
		"type": "arrow_rain", "owner": attacker, "root": root,
		"duration_left": minf(duration, 5.0), "tick_left": 0.0, "interval": 0.50,
		"origin": center, "radius": 125.0,
		"damage": damage * 0.26 * (1.25 if attacker.get_upgrade_level("archer_f_damage") > 0 else 1.0),
		"current_target": null, "consecutive_hits": 0,
		"critical_upgrade": attacker.get_upgrade_level("archer_f_critical") > 0,
		"weakpoint_upgrade": attacker.get_upgrade_level("archer_f_weakpoint") > 0,
	})

func add_lancer_storm(owner: PlayerController, damage: float, duration: float) -> void:
	var root := Node2D.new()
	root.name = "LancerStorm_%s" % owner.name
	root.global_position = owner.global_position
	game.effect_root.add_child(root)
	var radius := 175.0 * (1.20 if owner.get_upgrade_level("lancer_f_reach") > 0 else 1.0)
	game._spawn_area_visual(root, Vector2.ZERO, radius, Color(0.48, 0.78, 1.0, 0.18))
	var outer: Sprite2D = game._add_textured_effect(root, LancerFVfxTexture, radius * 2.08, Vector2.ZERO, Color(1.0, 1.0, 1.0, 0.62), "LancerStormTexture")
	var inner: Sprite2D = game._add_textured_effect(root, LancerFVfxTexture, radius * 1.66, Vector2.ZERO, Color(0.60, 0.94, 1.0, 0.30), "LancerStormInnerTexture")
	inner.flip_h = true
	game._animate_effect_rotation(outer, 1.15, true)
	game._animate_effect_rotation(inner, 1.75, false)
	game._animate_effect_pulse(outer, 0.48, 0.76, 0.42)
	game.persistent_skill_areas.append({
		"type": "lancer_storm", "owner": owner, "root": root,
		"duration_left": duration, "tick_left": 0.0,
		"interval": 0.45, "radius": radius, "damage": damage * 0.34,
		"pull_upgrade": owner.get_upgrade_level("lancer_f_pull") > 0, "sweep_angle": 0.0,
		"finisher_upgrade": owner.get_upgrade_level("lancer_f_finisher") > 0,
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

func add_mage_field(center: Vector2, radius: float, damage: float, attacker: PlayerController, duration: float = 4.0, accumulation: bool = false) -> void:
	var root := Node2D.new()
	root.name = "MageField_%s" % attacker.name
	game.effect_root.add_child(root)
	game._spawn_area_visual(root, center, radius, Color(0.50, 0.24, 0.92, 0.18))
	var outer: Sprite2D = game._add_textured_effect(root, MageEVfxTexture, radius * 2.08, center, Color(1.0, 1.0, 1.0, 0.54), "MageFieldTexture")
	var inner: Sprite2D = game._add_textured_effect(root, MageEVfxTexture, radius * 1.62, center, Color(0.66, 0.48, 1.0, 0.28), "MageFieldInnerTexture")
	inner.flip_h = true
	game._animate_effect_rotation(outer, 7.0, true)
	game._animate_effect_rotation(inner, 5.0, false)
	game._animate_effect_pulse(outer, 0.30, 0.62, 0.86)
	game.persistent_skill_areas.append({
		"type": "mage_field", "owner": attacker, "root": root,
		"duration_left": duration, "tick_left": 0.0, "interval": 0.50,
		"origin": center, "radius": radius, "damage": damage * 0.10,
		"accumulation": accumulation, "hit_counts": {},
	})

func add_mage_storm(center: Vector2, damage: float, duration: float, attacker: PlayerController) -> void:
	var radius := 220.0 * (1.20 if attacker.get_upgrade_level("mage_f_expansion") > 0 else 1.0)
	var root := Node2D.new()
	root.name = "MageStorm_%s" % attacker.name
	game.effect_root.add_child(root)
	game._spawn_area_visual(root, center, radius, Color(0.36, 0.58, 1.0, 0.20))
	var outer: Sprite2D = game._add_textured_effect(root, MageFVfxTexture, radius * 2.06, center, Color(1.0, 1.0, 1.0, 0.54), "MageStormTexture")
	var inner: Sprite2D = game._add_textured_effect(root, MageFVfxTexture, radius * 1.72, center, Color(0.48, 0.72, 1.0, 0.26), "MageStormInnerTexture")
	inner.flip_h = true
	game._animate_effect_rotation(outer, 6.0, true)
	game._animate_effect_rotation(inner, 4.2, false)
	game._animate_effect_pulse(outer, 0.32, 0.64, 0.72)
	game.persistent_skill_areas.append({
		"type": "mage_storm", "owner": attacker, "root": root,
		"duration_left": minf(duration, 5.0), "tick_left": 0.0,
		"interval": 1.0, "origin": center, "radius": radius,
		"damage": damage * 0.30 * (1.30 if attacker.get_upgrade_level("mage_f_infusion") > 0 else 1.0),
		"finisher_upgrade": attacker.get_upgrade_level("mage_f_finisher") > 0,
		"stunned_ids": {},
	})

func update_persistent_skill_areas(delta: float) -> void:
	for area in game.persistent_skill_areas.duplicate():
		var owner: PlayerController = area.get("owner") as PlayerController
		var duration_left := float(area.get("duration_left", 0.0)) - delta
		area["duration_left"] = duration_left
		if duration_left <= 0.0 or owner == null or not is_instance_valid(owner) or owner.is_dead:
			if duration_left <= 0.0 and owner != null and is_instance_valid(owner) and not owner.is_dead:
				_finish_persistent_skill_area(area, owner)
			remove_persistent_skill_area(area)
			continue
		var area_type := str(area.get("type", ""))
		if area_type in ["warrior_shield", "lancer_spear"]:
			_update_traveling_skill(area, owner, delta)
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
		elif str(area.get("type", "")) == "archer_trap":
			_tick_archer_trap(area, owner)
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
	var target := _get_arrow_rain_target(center, radius)
	if target == null:
		area["current_target"] = null
		area["consecutive_hits"] = 0
		return
	var previous_target = area.get("current_target")
	if previous_target == null or not is_instance_valid(previous_target) or previous_target != target:
		area["current_target"] = target
		area["consecutive_hits"] = 0
	var count := int(area.get("consecutive_hits", 0)) + 1
	area["consecutive_hits"] = count
	game._spawn_line_skill_effect(target.global_position + Vector2(0.0, -90.0), Vector2.DOWN, 90.0, Color(1.0, 0.82, 0.24, 0.70), 0.10)
	_spawn_archer_arrow_strike(target.global_position)
	var damage_multiplier := 1.0
	if bool(area.get("weakpoint_upgrade", false)):
		damage_multiplier = minf(2.20, 1.0 + 0.18 * float(count - 1))
	var crit_chance := owner.crit_chance
	if bool(area.get("critical_upgrade", false)):
		crit_chance += 0.25
	if randf() < clampf(crit_chance, 0.0, 1.0):
		damage_multiplier *= owner.crit_multiplier
	damage_enemy(target, damage * damage_multiplier, owner, center, owner.attack_knockback * 0.28)
	game._spawn_spark_burst(target.global_position, Color(1.0, 0.72, 0.22, 0.92), 6, 26.0, 0.14)

func _spawn_archer_arrow_strike(target_position: Vector2) -> void:
	var root := Node2D.new()
	root.name = "ArcherArrowStrike"
	root.global_position = target_position + Vector2(0.0, -92.0)
	game.effect_root.add_child(root)
	var arrow: Sprite2D = game._add_textured_effect(root, ArcherQVfxTexture, 86.0, Vector2.ZERO, Color.WHITE, "Texture")
	arrow.scale.y *= 0.34
	arrow.rotation = PI * 0.5
	var tween := root.create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(root, "global_position", target_position, 0.14)
	tween.tween_property(arrow, "modulate:a", 0.0, 0.18).set_delay(0.05)
	tween.finished.connect(Callable(root, "queue_free"))

func _get_arrow_rain_target(center: Vector2, radius: float) -> EnemyController:
	var candidates: Array[EnemyController] = []
	for enemy in game.enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(center) <= radius:
			candidates.append(enemy)
	if candidates.is_empty():
		return null
	return candidates.pick_random()

func _tick_archer_trap(area: Dictionary, owner: PlayerController) -> void:
	var center := area.get("origin", owner.global_position) as Vector2
	var radius := float(area.get("radius", 34.0))
	for enemy in game.enemies.duplicate():
		if not is_instance_valid(enemy) or enemy.global_position.distance_to(center) > radius:
			continue
		enemy.apply_root(1.5)
		if bool(area.get("execution_upgrade", false)):
			enemy.apply_guaranteed_arrow_crit(owner)
		game._spawn_ring_effect(center, 48.0, Color(1.0, 0.72, 0.18, 0.82), 0.20)
		game._spawn_textured_effect(center, ArcherEVfxTexture, 96.0, 0.24, "ArcherTrapTrigger")
		game._spawn_spark_burst(center, Color(1.0, 0.42, 0.72, 0.94), 10, 46.0, 0.20)
		remove_persistent_skill_area(area)
		return

func _update_traveling_skill(area: Dictionary, owner: PlayerController, delta: float) -> void:
	var root := area.get("root") as Node2D
	if root == null:
		remove_persistent_skill_area(area)
		return
	var travel := float(area.get("travel", 0.0))
	var max_travel := float(area.get("max_travel", 280.0))
	var speed := float(area.get("speed", 620.0))
	var returning := bool(area.get("returning", false))
	travel += (-speed if returning else speed) * delta
	travel = clampf(travel, 0.0, max_travel)
	area["travel"] = travel
	var origin := area.get("origin", owner.global_position) as Vector2
	var direction := area.get("direction", Vector2.RIGHT) as Vector2
	root.global_position = origin + direction * travel
	root.rotation = direction.angle() + (PI if returning else 0.0)
	var hit_ids := area.get("hit_ids") as Dictionary
	for enemy in game.enemies.duplicate():
		if not is_instance_valid(enemy) or hit_ids.has(enemy.get_instance_id()) or enemy.global_position.distance_to(root.global_position) > 24.0:
			continue
		hit_ids[enemy.get_instance_id()] = true
		var damage := float(area.get("damage", owner.attack_damage))
		if str(area.get("type", "")) == "lancer_spear" and returning and not enemy.is_boss:
			var away: Vector2 = (enemy.global_position - owner.global_position).normalized()
			damage_enemy(enemy, damage, owner, enemy.global_position + away * 80.0, owner.attack_knockback * 0.35)
		else:
			damage_enemy(enemy, damage, owner, origin, owner.attack_knockback * 0.20)
		area["hit_any"] = true
	if not returning and travel >= max_travel:
		var should_return := str(area.get("type", "")) == "warrior_shield" or bool(area.get("returns", false))
		if should_return:
			area["returning"] = true
			hit_ids.clear()
		else:
			remove_persistent_skill_area(area)
	elif returning and travel <= 0.0:
		if str(area.get("type", "")) == "warrior_shield" and bool(area.get("guard_upgrade", false)) and bool(area.get("hit_any", false)):
			owner.activate_warrior_shield_guard(2.0)
			game._spawn_ring_effect(owner.global_position, 46.0, Color(0.35, 0.72, 1.0, 0.78), 0.20)
		remove_persistent_skill_area(area)

func _tick_lancer_storm(area: Dictionary, owner: PlayerController) -> void:
	var radius := float(area.get("radius", 175.0))
	var damage := float(area.get("damage", owner.attack_damage))
	var root := area.get("root") as Node2D
	if root != null:
		root.global_position = owner.global_position
	game._spawn_effect(owner.global_position, radius, Color(0.46, 0.78, 1.0, 0.10), 0.12)
	game._spawn_ring_effect(owner.global_position, radius, Color(0.58, 0.88, 1.0, 0.58), 0.18)
	var sweep_angle := float(area.get("sweep_angle", 0.0)) + 1.92
	area["sweep_angle"] = sweep_angle
	spawn_lancer_sweep_vfx(owner.global_position, Vector2.RIGHT.rotated(sweep_angle), radius, radius * 0.58)
	for enemy in game.enemies.duplicate():
		if is_instance_valid(enemy) and enemy.global_position.distance_to(owner.global_position) <= radius:
			if bool(area.get("pull_upgrade", false)) and not enemy.is_boss:
				var away: Vector2 = (enemy.global_position - owner.global_position).normalized()
				var pull_origin: Vector2 = enemy.global_position + away * 80.0
				damage_enemy(enemy, damage, owner, pull_origin, owner.attack_knockback * 0.45)
			else:
				damage_enemy(enemy, damage, owner, owner.global_position, owner.attack_knockback * 0.45)

func _finish_persistent_skill_area(area: Dictionary, owner: PlayerController) -> void:
	var area_type := str(area.get("type", ""))
	if area_type == "mage_storm" and bool(area.get("finisher_upgrade", false)):
		var center := area.get("origin", owner.global_position) as Vector2
		var radius := float(area.get("radius", 220.0)) * 1.35
		var damage := float(area.get("damage", owner.attack_damage)) * 2.0
		game._spawn_effect(center, radius, Color(0.36, 0.58, 1.0, 0.30), 0.18)
		game._spawn_ring_effect(center, radius, Color(0.56, 0.76, 1.0, 0.72), 0.22)
		game._spawn_textured_effect(center, MageFVfxTexture, radius * 2.0, 0.30, "MageStormFinisher")
		game._spawn_spark_burst(center, Color(0.58, 0.82, 1.0, 0.96), 20, radius * 0.72, 0.28)
		damage_enemies_in_radius(center, radius, damage, owner)
	elif area_type == "lancer_storm" and bool(area.get("finisher_upgrade", false)):
		var radius := float(area.get("radius", 175.0)) * 1.45
		var damage := float(area.get("damage", owner.attack_damage)) * 2.2
		game._spawn_effect(owner.global_position, radius, Color(0.48, 0.78, 1.0, 0.26), 0.18)
		game._spawn_ring_effect(owner.global_position, radius, Color(0.68, 0.92, 1.0, 0.78), 0.24)
		game._spawn_textured_effect(owner.global_position, LancerFVfxTexture, radius * 2.0, 0.30, "LancerStormFinisher")
		game._spawn_spark_burst(owner.global_position, Color(0.72, 0.96, 1.0, 0.96), 22, radius * 0.78, 0.28)
		damage_enemies_in_radius(owner.global_position, radius, damage, owner)

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
			var area_type := str(area.get("type", ""))
			if area_type == "mage_field":
				enemy.apply_slow(0.60, 0.90)
			elif area_type == "mage_storm":
				_spawn_mage_lightning_strike(enemy.global_position)
				var stunned_ids := area.get("stunned_ids") as Dictionary
				if not stunned_ids.has(enemy.get_instance_id()):
					enemy.apply_stun(0.5)
					stunned_ids[enemy.get_instance_id()] = true
			var hit_damage := damage
			if area_type == "mage_field" and bool(area.get("accumulation", false)):
				var hit_counts := area.get("hit_counts") as Dictionary
				var count := int(hit_counts.get(enemy.get_instance_id(), 0)) + 1
				hit_counts[enemy.get_instance_id()] = count
				hit_damage *= minf(2.0, 1.0 + 0.15 * float(count - 1))
			damage_enemy(enemy, hit_damage, owner, center, 0.0, true, false)

func _spawn_mage_lightning_strike(target_position: Vector2) -> void:
	var root := Node2D.new()
	root.name = "MageLightningStrike"
	root.global_position = target_position
	game.effect_root.add_child(root)
	var bolt := Line2D.new()
	bolt.width = 5.0
	bolt.default_color = Color(0.48, 0.82, 1.0, 0.96)
	bolt.points = PackedVector2Array([
		Vector2(-14.0, -132.0), Vector2(8.0, -98.0), Vector2(-7.0, -62.0), Vector2(5.0, -30.0), Vector2.ZERO,
	])
	root.add_child(bolt)
	var impact: Sprite2D = game._add_textured_effect(root, MageQVfxTexture, 72.0, Vector2.ZERO, Color.WHITE, "Impact")
	impact.rotation = PI * 0.5
	var tween := root.create_tween().set_parallel(true)
	tween.tween_property(bolt, "modulate:a", 0.0, 0.18)
	tween.tween_property(impact, "modulate:a", 0.0, 0.20)
	tween.finished.connect(Callable(root, "queue_free"))
	game._spawn_spark_burst(target_position, Color(0.46, 0.76, 1.0, 0.94), 9, 38.0, 0.18)

func remove_persistent_skill_area(area: Dictionary) -> void:
	game.persistent_skill_areas.erase(area)
	var root: Node2D = area.get("root") as Node2D
	if root != null and is_instance_valid(root):
		root.queue_free()

func clear_persistent_skill_areas() -> void:
	for area in game.persistent_skill_areas.duplicate():
		remove_persistent_skill_area(area)
	game.persistent_skill_areas.clear()
