extends CharacterBody2D
class_name EnemyController

signal died(enemy: EnemyController)
signal attack_started(enemy: EnemyController, windup_time: float, range: float)
signal attacked_player(enemy: EnemyController, target: Node2D, damage: float)
signal projectile_requested(enemy: EnemyController, target: Node2D, origin: Vector2, direction: Vector2, damage: float)
signal area_attack_requested(enemy: EnemyController, origin: Vector2, radius: float, damage: float, windup_time: float)
signal damaged(enemy: EnemyController, amount: float)

const MINION_IDLE_SPRITE_PATH := "res://assets/tiny_swords_free_pack/Units/Red Units/Pawn/Pawn_Idle.png"
const MINION_RUN_SPRITE_PATH := "res://assets/tiny_swords_free_pack/Units/Red Units/Pawn/Pawn_Run.png"
const MINION_ATTACK_SPRITE_PATH := "res://assets/tiny_swords_free_pack/Units/Red Units/Pawn/Pawn_Interact Knife.png"
const BOSS_IDLE_SPRITE_PATH := "res://assets/tiny_swords_free_pack/Units/Black Units/Lancer/Lancer_Idle.png"
const BOSS_RUN_SPRITE_PATH := "res://assets/tiny_swords_free_pack/Units/Black Units/Lancer/Lancer_Run.png"
const BOSS_ATTACK_SPRITE_PATH := "res://assets/tiny_swords_free_pack/Units/Black Units/Lancer/Lancer_Right_Attack.png"
const MINION_FRAME_SIZE := Vector2(192, 192)
const BOSS_FRAME_SIZE := Vector2(320, 320)
const ANIM_IDLE := "idle"
const ANIM_RUN := "run"
const ANIM_ATTACK := "attack"
const TYPE_MELEE := "melee"
const TYPE_HEAVY := "heavy"
const TYPE_RANGED := "ranged"
const TYPE_ELITE := "elite"
const TYPE_BOSS := "boss"

var max_health := 45.0
var health := max_health
var move_speed := 95.0
var attack_damage := 10.0
var attack_interval := 0.8
var attack_range := 42.0
var attack_windup_time := 0.22
var attack_recovery_time := 0.20
var preferred_range := 0.0
var projectile_damage := 8.0
var enemy_type := TYPE_MELEE
var is_boss := false
var arena_bounds := Rect2(Vector2(-480, -270), Vector2(960, 540))

var _target: Node2D
var _attack_timer := 0.0
var _attack_windup_left := 0.0
var _attack_recovery_left := 0.0
var _hit_flash_left := 0.0
var _stagger_left := 0.0
var _knockback_velocity := Vector2.ZERO
var _current_anim := ""
var _anim_frame := 0
var _anim_timer := 0.0
var _attack_anim_left := 0.0
var _boss_area_timer := 2.4
var _boss_cast_pause_left := 0.0
var _boss_enraged := false

var _sprite: Sprite2D
var _health_bar: ProgressBar

func _ready() -> void:
	add_to_group("enemies")
	_setup_nodes()

func setup_as_minion(wave_number: int) -> void:
	is_boss = false
	enemy_type = TYPE_MELEE
	max_health = 38.0 + wave_number * 8.0
	health = max_health
	move_speed = 90.0 + wave_number * 4.0
	attack_damage = 8.0 + wave_number * 2.0
	attack_interval = 0.85
	attack_range = 42.0
	attack_windup_time = 0.24
	attack_recovery_time = 0.20
	if is_node_ready():
		_update_variant_visual()
		_play_animation(ANIM_IDLE, true)

func setup_as_heavy(wave_number: int) -> void:
	setup_as_minion(wave_number)
	enemy_type = TYPE_HEAVY
	max_health *= 2.25
	health = max_health
	move_speed *= 0.58
	attack_damage *= 1.45
	attack_interval = 1.05
	attack_range = 48.0
	attack_windup_time = 0.42
	attack_recovery_time = 0.34
	if is_node_ready():
		_update_health_bar()
		_update_variant_visual()

func setup_as_ranged(wave_number: int) -> void:
	setup_as_minion(wave_number)
	enemy_type = TYPE_RANGED
	max_health *= 0.8
	health = max_health
	move_speed *= 0.92
	attack_damage *= 0.75
	projectile_damage = attack_damage
	attack_interval = 1.35
	attack_range = 250.0
	preferred_range = 185.0
	attack_windup_time = 0.32
	attack_recovery_time = 0.26
	if is_node_ready():
		_update_health_bar()
		_update_variant_visual()

func setup_as_elite(wave_number: int) -> void:
	setup_as_minion(wave_number)
	enemy_type = TYPE_ELITE
	max_health *= 1.75
	health = max_health
	move_speed *= 1.12
	attack_damage *= 1.35
	attack_interval *= 0.82
	attack_windup_time *= 0.9
	if is_node_ready():
		_update_health_bar()
		_update_variant_visual()

func setup_as_boss() -> void:
	is_boss = true
	enemy_type = TYPE_BOSS
	max_health = 450.0
	health = max_health
	move_speed = 70.0
	attack_damage = 18.0
	attack_interval = 0.65
	attack_range = 58.0
	attack_windup_time = 0.34
	attack_recovery_time = 0.28
	_boss_area_timer = 1.6
	_boss_enraged = false
	if is_node_ready():
		_update_variant_visual()
		_play_animation(ANIM_IDLE, true)

func set_target(target: Node2D) -> void:
	_target = target

func _target_is_dead() -> bool:
	var player_target: PlayerController = _target as PlayerController
	return player_target != null and player_target.is_dead

func _physics_process(delta: float) -> void:
	_attack_timer = maxf(0.0, _attack_timer - delta)
	if is_boss:
		_boss_area_timer = maxf(0.0, _boss_area_timer - delta)
	_stagger_left = maxf(0.0, _stagger_left - delta)
	_hit_flash_left = maxf(0.0, _hit_flash_left - delta)
	_attack_anim_left = maxf(0.0, _attack_anim_left - delta)
	_boss_cast_pause_left = maxf(0.0, _boss_cast_pause_left - delta)
	_update_feedback()

	if _knockback_velocity.length() > 2.0:
		_update_animation(delta, true)
		velocity = _knockback_velocity
		move_and_slide()
		global_position = global_position.clamp(arena_bounds.position, arena_bounds.end)
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		return

	if _stagger_left > 0.0:
		velocity = Vector2.ZERO
		_update_animation(delta, false)
		return

	if _boss_cast_pause_left > 0.0:
		velocity = Vector2.ZERO
		_update_animation(delta, false)
		return

	if _target == null or not is_instance_valid(_target) or _target_is_dead():
		velocity = Vector2.ZERO
		_update_animation(delta, false)
		return

	var to_target: Vector2 = _target.global_position - global_position
	var distance: float = to_target.length()
	if is_boss and _boss_area_timer <= 0.0:
		_start_boss_area_attack()
		return

	if _attack_windup_left > 0.0:
		velocity = Vector2.ZERO
		_attack_windup_left = maxf(0.0, _attack_windup_left - delta)
		_update_animation(delta, false)
		if _attack_windup_left <= 0.0:
			_finish_attack()
		return

	if _attack_recovery_left > 0.0:
		velocity = Vector2.ZERO
		_attack_recovery_left = maxf(0.0, _attack_recovery_left - delta)
		_update_animation(delta, false)
		return

	if enemy_type == TYPE_RANGED:
		_update_ranged_movement(to_target, distance)
		move_and_slide()
		global_position = global_position.clamp(arena_bounds.position, arena_bounds.end)
		_update_animation(delta, velocity.length() > 1.0)
		if distance <= attack_range and _attack_timer <= 0.0:
			_start_attack()
	elif distance > attack_range:
		velocity = to_target.normalized() * move_speed
		move_and_slide()
		global_position = global_position.clamp(arena_bounds.position, arena_bounds.end)
		_update_animation(delta, true)
	else:
		if _attack_timer <= 0.0:
			velocity = Vector2.ZERO
			_update_animation(delta, false)
			_start_attack()
		else:
			_update_close_range_pressure(to_target, distance, delta)

	if abs(to_target.x) > 1.0:
		_sprite.flip_h = to_target.x < 0.0

func apply_damage(amount: float, knockback_origin: Vector2 = Vector2.ZERO, knockback_force: float = 90.0) -> void:
	health = maxf(0.0, health - amount)
	_update_health_bar()
	if is_boss and not _boss_enraged and health <= max_health * 0.5:
		_enter_boss_enrage()
	_hit_flash_left = 0.10
	_stagger_left = maxf(_stagger_left, 0.06 if is_boss else 0.13)
	if not is_boss:
		_attack_windup_left = 0.0
		_attack_recovery_left = maxf(_attack_recovery_left, 0.12)
	if knockback_force > 0.0:
		var push_direction: Vector2 = (global_position - knockback_origin).normalized()
		if push_direction == Vector2.ZERO:
			push_direction = Vector2.RIGHT
		_knockback_velocity = push_direction * knockback_force
	damaged.emit(self, amount)
	if health <= 0.0:
		died.emit(self)
		queue_free()

func apply_defense_repel(knockback_origin: Vector2, knockback_force: float = 170.0) -> void:
	var push_direction: Vector2 = (global_position - knockback_origin).normalized()
	if push_direction == Vector2.ZERO:
		push_direction = Vector2.RIGHT
	_knockback_velocity = push_direction * knockback_force
	_stagger_left = maxf(_stagger_left, 0.12)
	_attack_recovery_left = maxf(_attack_recovery_left, attack_recovery_time)

func _setup_nodes() -> void:
	if not has_node("Sprite2D"):
		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	if not has_node("CollisionShape2D"):
		var collision: CollisionShape2D = CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = 15.0
		collision.shape = circle
		add_child(collision)

	_sprite = get_node("Sprite2D") as Sprite2D
	if not has_node("HealthBar"):
		_health_bar = ProgressBar.new()
		_health_bar.name = "HealthBar"
		_health_bar.position = Vector2(-26.0, -48.0)
		_health_bar.custom_minimum_size = Vector2(52.0, 6.0)
		_health_bar.show_percentage = false
		_health_bar.z_index = 20
		add_child(_health_bar)
	else:
		_health_bar = get_node("HealthBar") as ProgressBar
	_update_health_bar()
	_play_animation(ANIM_IDLE, true)

func _update_health_bar() -> void:
	if _health_bar == null:
		return
	_health_bar.max_value = max_health
	_health_bar.value = health
	_health_bar.visible = health < max_health

func _update_variant_visual() -> void:
	if _sprite == null:
		return
	match enemy_type:
		TYPE_HEAVY:
			_sprite.modulate = Color(0.82, 0.82, 0.92, 1.0)
		TYPE_RANGED:
			_sprite.modulate = Color(0.95, 0.86, 0.58, 1.0)
		TYPE_ELITE:
			_sprite.modulate = Color(1.0, 0.72, 0.72, 1.0)
		_:
			_sprite.modulate = Color.WHITE

func _apply_sprite_frame(path: String, frame_size: Vector2, sprite_scale: Vector2, frame_index: int) -> void:
	_sprite.texture = load(path) as Texture2D
	_sprite.centered = true
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(Vector2(frame_size.x * float(frame_index), 0.0), frame_size)
	_sprite.scale = sprite_scale

func _update_animation(delta: float, moving: bool) -> void:
	var target_anim: String = ANIM_IDLE
	if _attack_anim_left > 0.0:
		target_anim = ANIM_ATTACK
	elif moving:
		target_anim = ANIM_RUN
	_play_animation(target_anim)
	var data: Dictionary = _get_animation_data(_current_anim)
	var frame_count: int = int(data["frames"])
	var frame_time: float = float(data["frame_time"])
	_anim_timer += delta
	while _anim_timer >= frame_time:
		_anim_timer -= frame_time
		_anim_frame = (_anim_frame + 1) % frame_count
	_apply_current_animation_frame()

func _start_attack_animation() -> void:
	var data: Dictionary = _get_animation_data(ANIM_ATTACK)
	_attack_anim_left = float(data["frames"]) * float(data["frame_time"])
	_play_animation(ANIM_ATTACK, true)

func _start_attack() -> void:
	_attack_timer = attack_interval
	_attack_windup_left = attack_windup_time
	_attack_recovery_left = 0.0
	_start_attack_animation()
	_attack_anim_left = maxf(_attack_anim_left, attack_windup_time + 0.05)
	attack_started.emit(self, attack_windup_time, attack_range)

func _finish_attack() -> void:
	_attack_recovery_left = attack_recovery_time
	if _target == null or not is_instance_valid(_target) or _target_is_dead():
		return
	if enemy_type == TYPE_RANGED:
		var shoot_direction: Vector2 = (_target.global_position - global_position).normalized()
		if shoot_direction == Vector2.ZERO:
			shoot_direction = Vector2.RIGHT
		projectile_requested.emit(self, _target, global_position, shoot_direction, projectile_damage)
		return
	if global_position.distance_to(_target.global_position) <= attack_range + 16.0:
		attacked_player.emit(self, _target, attack_damage)

func _update_ranged_movement(to_target: Vector2, distance: float) -> void:
	if distance < preferred_range * 0.72:
		velocity = -to_target.normalized() * move_speed
	elif distance > preferred_range * 1.15:
		velocity = to_target.normalized() * move_speed
	else:
		velocity = Vector2.ZERO

func _update_close_range_pressure(to_target: Vector2, distance: float, delta: float) -> void:
	if distance <= 1.0:
		velocity = Vector2.ZERO
	else:
		var pressure_speed: float = move_speed * 0.28
		velocity = to_target.normalized() * pressure_speed
		move_and_slide()
		global_position = global_position.clamp(arena_bounds.position, arena_bounds.end)
	_update_animation(delta, velocity.length() > 1.0)

func _start_boss_area_attack() -> void:
	if _target == null or not is_instance_valid(_target) or _target_is_dead():
		return
	velocity = Vector2.ZERO
	_attack_timer = attack_interval
	_attack_recovery_left = 0.75
	_boss_cast_pause_left = 0.72
	_start_attack_animation()
	var radius: float = 132.0 if _boss_enraged else 112.0
	var damage: float = attack_damage * (1.4 if _boss_enraged else 1.15)
	area_attack_requested.emit(self, _target.global_position, radius, damage, _boss_cast_pause_left)
	_boss_area_timer = 3.2 if _boss_enraged else 4.4

func _enter_boss_enrage() -> void:
	_boss_enraged = true
	move_speed *= 1.25
	attack_interval *= 0.72
	attack_windup_time *= 0.82
	attack_recovery_time *= 0.82
	_hit_flash_left = 0.45

func _play_animation(anim_name: String, force_restart: bool = false) -> void:
	if _current_anim == anim_name and not force_restart:
		return
	_current_anim = anim_name
	_anim_frame = 0
	_anim_timer = 0.0
	_apply_current_animation_frame()

func _apply_current_animation_frame() -> void:
	var data: Dictionary = _get_animation_data(_current_anim)
	var frame_size: Vector2 = BOSS_FRAME_SIZE if is_boss else MINION_FRAME_SIZE
	var sprite_scale: Vector2 = Vector2(0.85, 0.85) if is_boss else Vector2(0.55, 0.55)
	if enemy_type == TYPE_HEAVY:
		sprite_scale = Vector2(0.68, 0.68)
	elif enemy_type == TYPE_RANGED:
		sprite_scale = Vector2(0.52, 0.52)
	elif enemy_type == TYPE_ELITE:
		sprite_scale = Vector2(0.62, 0.62)
	_apply_sprite_frame(
		str(data["path"]),
		frame_size,
		sprite_scale,
		_anim_frame
	)

func _get_animation_data(anim_name: String) -> Dictionary:
	if is_boss:
		if anim_name == ANIM_ATTACK:
			return {"path": BOSS_ATTACK_SPRITE_PATH, "frames": 3, "frame_time": 0.075}
		if anim_name == ANIM_RUN:
			return {"path": BOSS_RUN_SPRITE_PATH, "frames": 6, "frame_time": 0.095}
		return {"path": BOSS_IDLE_SPRITE_PATH, "frames": 12, "frame_time": 0.11}

	if anim_name == ANIM_ATTACK:
		return {"path": MINION_ATTACK_SPRITE_PATH, "frames": 4, "frame_time": 0.07}
	if anim_name == ANIM_RUN:
		return {"path": MINION_RUN_SPRITE_PATH, "frames": 6, "frame_time": 0.085}
	return {"path": MINION_IDLE_SPRITE_PATH, "frames": 8, "frame_time": 0.12}

func _update_feedback() -> void:
	if _hit_flash_left > 0.0:
		_sprite.modulate = Color(1.0, 0.45, 0.45, 1.0)
	else:
		_update_variant_visual()
