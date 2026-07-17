extends CharacterBody2D
class_name EnemyController

const EnemyArchetypesScript := preload("res://scripts/enemy/enemy_archetypes.gd")
const EnemyAnimationCatalogScript := preload("res://scripts/enemy/enemy_animation_catalog.gd")

signal died(enemy: EnemyController)
signal attack_started(enemy: EnemyController, windup_time: float, range: float)
signal attacked_player(enemy: EnemyController, target: Node2D, damage: float)
signal projectile_requested(enemy: EnemyController, target: Node2D, origin: Vector2, direction: Vector2, damage: float)
signal area_attack_requested(enemy: EnemyController, origin: Vector2, radius: float, damage: float, windup_time: float)
signal charge_started(enemy: EnemyController, origin: Vector2, direction: Vector2, length: float, windup_time: float)
signal self_destruct_requested(enemy: EnemyController, origin: Vector2, radius: float, damage: float)
signal healing_started(enemy: EnemyController, origin: Vector2, radius: float, windup_time: float)
signal healing_requested(enemy: EnemyController, origin: Vector2, radius: float, amount: float)
signal boss_reinforcement_requested(enemy: EnemyController)
signal damaged(enemy: EnemyController, amount: float)

const ANIM_IDLE := "idle"
const ANIM_RUN := "run"
const ANIM_ATTACK := "attack"
const TYPE_MELEE := "melee"
const TYPE_HEAVY := "heavy"
const TYPE_RANGED := "ranged"
const TYPE_SHIELD := "shield"
const TYPE_CHARGER := "charger"
const TYPE_BOMBER := "bomber"
const TYPE_PRIEST := "priest"
const TYPE_TRAINING_DUMMY := "training_dummy"
const TYPE_MINI_BOSS := "mini_boss"
const TYPE_BOSS := "boss"
const MINOR_SKILL_START_WAVE := 7
const MELEE_BLOOD_RAGE_HEALTH_RATIO := 0.40
const MELEE_BLOOD_RAGE_DURATION := 4.0
const MELEE_BLOOD_RAGE_SPEED_MULTIPLIER := 1.30
const MELEE_BLOOD_RAGE_ATTACK_INTERVAL_MULTIPLIER := 0.70
const HEAVY_STOMP_RADIUS := 105.0
const HEAVY_STOMP_WINDUP := 0.75
const HEAVY_STOMP_COOLDOWN := 5.5
const RANGED_REPOSITION_SHOTS := 3
const RANGED_REPOSITION_DURATION := 0.38
const RANGED_REPOSITION_SPEED_MULTIPLIER := 2.20
const BOSS_AOE_DAMAGE_TAKEN_MULTIPLIER := 0.70
const BOSS_CRITICAL_BONUS_MULTIPLIER := 0.80
const BOSS_PHASE_INVULNERABILITY := 0.75
const BOSS_ENRAGE_DAMAGE_MULTIPLIER := 1.30
const BOSS_DESPERATION_HEALTH_RATIO := 0.20
const BOSS_DESPERATION_RADIUS := 300.0
const BOSS_DESPERATION_WINDUP := 1.50
const BOSS_DESPERATION_COOLDOWN := 5.50

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
var is_mini_boss := false
var is_training_dummy := false
var network_id := -1
var authority_enabled := true
var authority_target_position := Vector2.ZERO
var authority_velocity := Vector2.ZERO
var authority_animation := ANIM_IDLE
var _authority_state_received := false
var minor_skill_enabled := false
var arena_bounds := Rect2(Vector2(-480, -270), Vector2(960, 540))

var _target: Node2D
var _forced_target: Node2D
var _forced_target_left := 0.0
var _marked_by: PlayerController
var _mark_left := 0.0
var _mark_damage_multiplier := 1.0
var _root_left := 0.0
var _stun_left := 0.0
var _slow_left := 0.0
var _slow_move_multiplier := 1.0
var _guaranteed_arrow_crit_by: PlayerController
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
var _boss_cataclysm_timer := 5.0
var _boss_cast_pause_left := 0.0
var _boss_enraged := false
var _boss_reinforcements_called := false
var _boss_invulnerability_left := 0.0
var _boss_desperation_timer := BOSS_DESPERATION_COOLDOWN
var _boss_desperation_unlocked := false
var _boss_phase_70_triggered := false
var _boss_phase_40_triggered := false
var _boss_phase_20_triggered := false
var _boss_phase_10_triggered := false
var _facing_direction := Vector2.RIGHT
var _shield_front_damage_multiplier := 0.30
var _charge_cooldown_left := 0.0
var _charge_windup_left := 0.0
var _charge_time_left := 0.0
var _charge_direction := Vector2.RIGHT
var _charge_speed := 520.0
var _charge_damage := 0.0
var _bomber_windup_left := 0.0
var _bomber_radius := 96.0
var _bomber_damage := 0.0
var _priest_heal_cooldown_left := 0.0
var _priest_cast_left := 0.0
var _priest_heal_radius := 190.0
var _priest_heal_amount := 0.0
var _melee_blood_rage_triggered := false
var _melee_blood_rage_left := 0.0
var _heavy_stomp_cooldown_left := 0.0
var _ranged_shots_since_reposition := 0
var _ranged_reposition_left := 0.0
var _ranged_reposition_direction := Vector2.ZERO
var _ranged_reposition_side := 1.0
var _is_dying := false
var _training_dummy_reset_left := 0.0
var training_damage_total := 0.0

var _sprite: Sprite2D
var _health_bar: ProgressBar
var _training_damage_label: Label

func _ready() -> void:
	add_to_group("enemies")
	_setup_nodes()

func _reset_special_state() -> void:
	is_boss = false
	is_mini_boss = false
	is_training_dummy = false
	_training_dummy_reset_left = 0.0
	training_damage_total = 0.0
	_is_dying = false
	_facing_direction = Vector2.RIGHT
	_charge_cooldown_left = 0.0
	_charge_windup_left = 0.0
	_charge_time_left = 0.0
	_charge_direction = Vector2.RIGHT
	_charge_damage = 0.0
	_bomber_windup_left = 0.0
	_bomber_damage = 0.0
	_priest_heal_cooldown_left = 0.0
	_priest_cast_left = 0.0
	_priest_heal_amount = 0.0
	minor_skill_enabled = false
	_melee_blood_rage_triggered = false
	_melee_blood_rage_left = 0.0
	_heavy_stomp_cooldown_left = 0.0
	_ranged_shots_since_reposition = 0
	_ranged_reposition_left = 0.0
	_ranged_reposition_direction = Vector2.ZERO
	_ranged_reposition_side = 1.0
	_stun_left = 0.0
	_slow_left = 0.0
	_slow_move_multiplier = 1.0
	_boss_cataclysm_timer = 5.0
	_boss_reinforcements_called = false
	_boss_invulnerability_left = 0.0
	_boss_desperation_timer = BOSS_DESPERATION_COOLDOWN
	_boss_desperation_unlocked = false
	_boss_phase_70_triggered = false
	_boss_phase_40_triggered = false
	_boss_phase_20_triggered = false
	_boss_phase_10_triggered = false

func setup_as_minion(wave_number: int) -> void:
	_apply_archetype(TYPE_MELEE, wave_number)

func setup_as_heavy(wave_number: int) -> void:
	_apply_archetype(TYPE_HEAVY, wave_number)

func setup_as_ranged(wave_number: int) -> void:
	_apply_archetype(TYPE_RANGED, wave_number)

func setup_as_shield(wave_number: int) -> void:
	_apply_archetype(TYPE_SHIELD, wave_number)

func setup_as_charger(wave_number: int) -> void:
	_apply_archetype(TYPE_CHARGER, wave_number)

func setup_as_bomber(wave_number: int) -> void:
	_apply_archetype(TYPE_BOMBER, wave_number)

func setup_as_priest(wave_number: int) -> void:
	_apply_archetype(TYPE_PRIEST, wave_number)

func setup_as_training_dummy() -> void:
	_apply_archetype(TYPE_TRAINING_DUMMY, 0)
	is_training_dummy = true
	if is_node_ready():
		_update_health_bar()
		_update_training_damage_label()

func setup_as_boss() -> void:
	_apply_archetype(TYPE_BOSS, 0)
	_boss_cataclysm_timer = 5.0
	_boss_enraged = false
	_boss_reinforcements_called = false
	_boss_invulnerability_left = 0.0
	_boss_desperation_timer = BOSS_DESPERATION_COOLDOWN

func setup_as_mini_boss() -> void:
	_apply_archetype(TYPE_MINI_BOSS, 5)
	is_boss = true
	is_mini_boss = true
	_boss_cataclysm_timer = 4.5
	_boss_enraged = false
	_boss_invulnerability_left = 0.0

func _apply_archetype(type_id: String, wave_number: int) -> void:
	_reset_special_state()
	enemy_type = type_id
	is_boss = type_id in [TYPE_BOSS, TYPE_MINI_BOSS]
	is_mini_boss = type_id == TYPE_MINI_BOSS
	minor_skill_enabled = wave_number >= MINOR_SKILL_START_WAVE and type_id in [TYPE_MELEE, TYPE_HEAVY, TYPE_RANGED]
	var stats: Dictionary = EnemyArchetypesScript.get_stats(type_id, wave_number)
	max_health = float(stats["max_health"])
	health = max_health
	move_speed = float(stats["move_speed"])
	attack_damage = float(stats["attack_damage"])
	attack_interval = float(stats["attack_interval"])
	attack_range = float(stats["attack_range"])
	attack_windup_time = float(stats["attack_windup_time"])
	attack_recovery_time = float(stats["attack_recovery_time"])
	preferred_range = float(stats.get("preferred_range", 0.0))
	projectile_damage = float(stats.get("projectile_damage", projectile_damage))
	_charge_damage = float(stats.get("charge_damage", 0.0))
	_charge_cooldown_left = float(stats.get("charge_cooldown", 0.0))
	_bomber_damage = float(stats.get("bomber_damage", 0.0))
	_bomber_radius = float(stats.get("bomber_radius", 96.0))
	_priest_heal_amount = float(stats.get("priest_heal_amount", 0.0))
	_priest_heal_cooldown_left = float(stats.get("priest_heal_cooldown", 0.0))
	_heavy_stomp_cooldown_left = 2.8 if minor_skill_enabled and type_id == TYPE_HEAVY else 0.0
	_boss_area_timer = float(stats.get("boss_area_timer", 2.4))
	if is_node_ready():
		_update_health_bar()
		_update_variant_visual()
		_play_animation(ANIM_IDLE, true)

func set_target(target: Node2D) -> void:
	if _forced_target_left > 0.0 and _forced_target != null and is_instance_valid(_forced_target):
		_target = _forced_target
		return
	_target = target

func apply_taunt(target: PlayerController, duration: float) -> void:
	if is_boss:
		return
	_forced_target = target
	_forced_target_left = maxf(_forced_target_left, duration)
	_target = target

func apply_hunter_mark(owner: PlayerController, duration: float, damage_multiplier: float) -> void:
	_marked_by = owner
	_mark_left = duration
	_mark_damage_multiplier = damage_multiplier

func get_damage_multiplier(attacker: PlayerController) -> float:
	return _mark_damage_multiplier if _mark_left > 0.0 and attacker == _marked_by else 1.0

func is_marked_by(owner: PlayerController) -> bool:
	return _mark_left > 0.0 and _marked_by == owner

func apply_root(duration: float) -> void:
	if not is_boss:
		_root_left = maxf(_root_left, duration)

func apply_stun(duration: float) -> void:
	if is_boss:
		return
	_stun_left = maxf(_stun_left, duration)

func apply_slow(duration: float, move_multiplier: float) -> void:
	if is_boss:
		return
	_slow_left = maxf(_slow_left, duration)
	_slow_move_multiplier = minf(_slow_move_multiplier, clampf(move_multiplier, 0.0, 1.0))

func apply_guaranteed_arrow_crit(owner: PlayerController) -> void:
	_guaranteed_arrow_crit_by = owner

func consume_guaranteed_arrow_crit(owner: PlayerController) -> bool:
	if _guaranteed_arrow_crit_by != owner:
		return false
	_guaranteed_arrow_crit_by = null
	return true

func _target_is_dead() -> bool:
	var player_target: PlayerController = _target as PlayerController
	return player_target != null and player_target.is_dead

func _physics_process(delta: float) -> void:
	if not authority_enabled:
		if _authority_state_received:
			global_position = global_position.lerp(authority_target_position, clampf(delta * 14.0, 0.0, 1.0))
		velocity = authority_velocity
		_play_animation(authority_animation)
		_advance_current_animation(delta)
		_update_feedback()
		return
	if is_training_dummy:
		velocity = Vector2.ZERO
		if _is_dying or health <= 0.0:
			_is_dying = false
			health = max_health
		_training_dummy_reset_left = maxf(0.0, _training_dummy_reset_left - delta)
		if _training_dummy_reset_left <= 0.0 and (health < max_health or training_damage_total > 0.0):
			health = max_health
			training_damage_total = 0.0
		_update_health_bar()
		_update_training_damage_label()
		_update_animation(delta, false)
		_update_feedback()
		return
	_forced_target_left = maxf(0.0, _forced_target_left - delta)
	_mark_left = maxf(0.0, _mark_left - delta)
	_root_left = maxf(0.0, _root_left - delta)
	_stun_left = maxf(0.0, _stun_left - delta)
	_slow_left = maxf(0.0, _slow_left - delta)
	if _slow_left <= 0.0:
		_slow_move_multiplier = 1.0
	if _forced_target_left <= 0.0:
		_forced_target = null
	if _mark_left <= 0.0:
		_marked_by = null
		_mark_damage_multiplier = 1.0
	_attack_timer = maxf(0.0, _attack_timer - delta)
	_charge_cooldown_left = maxf(0.0, _charge_cooldown_left - delta)
	_priest_heal_cooldown_left = maxf(0.0, _priest_heal_cooldown_left - delta)
	_melee_blood_rage_left = maxf(0.0, _melee_blood_rage_left - delta)
	_heavy_stomp_cooldown_left = maxf(0.0, _heavy_stomp_cooldown_left - delta)
	if is_boss:
		_boss_area_timer = maxf(0.0, _boss_area_timer - delta)
		_boss_cataclysm_timer = maxf(0.0, _boss_cataclysm_timer - delta)
		_boss_invulnerability_left = maxf(0.0, _boss_invulnerability_left - delta)
		_boss_desperation_timer = maxf(0.0, _boss_desperation_timer - delta)
	_stagger_left = maxf(0.0, _stagger_left - delta)
	_hit_flash_left = maxf(0.0, _hit_flash_left - delta)
	_attack_anim_left = maxf(0.0, _attack_anim_left - delta)
	_boss_cast_pause_left = maxf(0.0, _boss_cast_pause_left - delta)
	_update_feedback()
	if _stun_left > 0.0:
		velocity = Vector2.ZERO
		_update_animation(delta, false)
		return
	if _update_special_action(delta):
		return

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

	if _root_left > 0.0:
		velocity = Vector2.ZERO
		_update_animation(delta, false)
		return

	if _boss_cast_pause_left > 0.0:
		velocity = Vector2.ZERO
		_update_animation(delta, false)
		return
	if is_boss and _boss_invulnerability_left > 0.0:
		velocity = Vector2.ZERO
		_update_animation(delta, false)
		return

	if _target == null or not is_instance_valid(_target) or _target_is_dead():
		velocity = Vector2.ZERO
		_update_animation(delta, false)
		return

	var to_target: Vector2 = _target.global_position - global_position
	var distance: float = to_target.length()
	if to_target.length_squared() > 1.0:
		_facing_direction = to_target.normalized()
	if minor_skill_enabled and enemy_type == TYPE_HEAVY and _heavy_stomp_cooldown_left <= 0.0 and distance <= 170.0:
		_start_heavy_stomp()
		return
	if is_boss and _boss_desperation_unlocked and _boss_desperation_timer <= 0.0:
		_start_boss_desperation_attack()
		return
	if is_boss and _boss_cataclysm_timer <= 0.0:
		_start_boss_cataclysm()
		return
	if is_boss and _boss_area_timer <= 0.0:
		_start_boss_area_attack()
		return
	if enemy_type == TYPE_CHARGER and _charge_cooldown_left <= 0.0 and distance >= 85.0 and distance <= 340.0:
		_start_charge(to_target)
		return
	if enemy_type == TYPE_BOMBER:
		if distance <= attack_range:
			_start_bomber_explosion()
		else:
			velocity = to_target.normalized() * _current_move_speed()
			move_and_slide()
			global_position = global_position.clamp(arena_bounds.position, arena_bounds.end)
			_update_animation(delta, true)
		return
	if enemy_type == TYPE_PRIEST:
		if _priest_heal_cooldown_left <= 0.0 and _has_damaged_ally():
			_start_priest_heal()
			return
		_update_ranged_movement(to_target, distance)
		move_and_slide()
		global_position = global_position.clamp(arena_bounds.position, arena_bounds.end)
		_update_animation(delta, velocity.length() > 1.0)
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
		velocity = to_target.normalized() * _current_move_speed()
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

func _update_special_action(delta: float) -> bool:
	if _ranged_reposition_left > 0.0:
		_ranged_reposition_left = maxf(0.0, _ranged_reposition_left - delta)
		velocity = _ranged_reposition_direction * _current_move_speed() * RANGED_REPOSITION_SPEED_MULTIPLIER
		move_and_slide()
		global_position = global_position.clamp(arena_bounds.position, arena_bounds.end)
		_update_animation(delta, true)
		if _ranged_reposition_left <= 0.0:
			velocity = Vector2.ZERO
		return true
	if _bomber_windup_left > 0.0:
		velocity = Vector2.ZERO
		_bomber_windup_left = maxf(0.0, _bomber_windup_left - delta)
		_update_animation(delta, false)
		if _bomber_windup_left <= 0.0:
			self_destruct_requested.emit(self, global_position, _bomber_radius, _bomber_damage)
			_die()
		return true
	if _charge_windup_left > 0.0:
		velocity = Vector2.ZERO
		_charge_windup_left = maxf(0.0, _charge_windup_left - delta)
		_update_animation(delta, false)
		if _charge_windup_left <= 0.0:
			_charge_time_left = 0.46
		return true
	if _charge_time_left > 0.0:
		_charge_time_left = maxf(0.0, _charge_time_left - delta)
		velocity = _charge_direction * _charge_speed
		move_and_slide()
		global_position = global_position.clamp(arena_bounds.position, arena_bounds.end)
		_update_animation(delta, true)
		for node in get_tree().get_nodes_in_group("players"):
			var player := node as PlayerController
			if player != null and not player.is_dead and player.global_position.distance_to(global_position) <= 34.0:
				attacked_player.emit(self, player, _charge_damage)
				_charge_time_left = 0.0
				break
		if _charge_time_left <= 0.0:
			_attack_recovery_left = 0.45
		return true
	if _priest_cast_left > 0.0:
		velocity = Vector2.ZERO
		_priest_cast_left = maxf(0.0, _priest_cast_left - delta)
		_update_animation(delta, false)
		if _priest_cast_left <= 0.0:
			healing_requested.emit(self, global_position, _priest_heal_radius, _priest_heal_amount)
		return true
	return false

func _start_charge(to_target: Vector2) -> void:
	_charge_direction = to_target.normalized() if to_target != Vector2.ZERO else _facing_direction
	_charge_windup_left = 0.55
	_charge_cooldown_left = 3.2
	velocity = Vector2.ZERO
	_start_attack_animation()
	charge_started.emit(self, global_position, _charge_direction, 240.0, _charge_windup_left)

func _start_bomber_explosion() -> void:
	_bomber_windup_left = 0.90
	velocity = Vector2.ZERO
	_start_attack_animation()
	attack_started.emit(self, _bomber_windup_left, _bomber_radius)

func _start_priest_heal() -> void:
	_priest_cast_left = 0.65
	_priest_heal_cooldown_left = 5.0
	velocity = Vector2.ZERO
	_start_attack_animation()
	healing_started.emit(self, global_position, _priest_heal_radius, _priest_cast_left)

func _start_heavy_stomp() -> void:
	_heavy_stomp_cooldown_left = HEAVY_STOMP_COOLDOWN
	_attack_recovery_left = HEAVY_STOMP_WINDUP + 0.25
	velocity = Vector2.ZERO
	_start_attack_animation()
	area_attack_requested.emit(self, global_position, HEAVY_STOMP_RADIUS, attack_damage * 0.75, HEAVY_STOMP_WINDUP)

func _has_damaged_ally() -> bool:
	for node in get_tree().get_nodes_in_group("enemies"):
		var ally := node as EnemyController
		if ally != null and ally != self and is_instance_valid(ally) and ally.health < ally.max_health and ally.global_position.distance_to(global_position) <= _priest_heal_radius:
			return true
	return false

func apply_damage(amount: float, knockback_origin: Vector2 = Vector2.ZERO, knockback_force: float = 90.0, cause_stagger: bool = true, is_aoe: bool = false) -> float:
	if _is_dying or (is_boss and _boss_invulnerability_left > 0.0):
		return 0.0
	var resolved_amount := amount
	if is_training_dummy:
		var dummy_amount := minf(max_health, maxf(0.0, resolved_amount))
		health = maxf(1.0, health - dummy_amount)
		training_damage_total += dummy_amount
		_training_dummy_reset_left = 5.0
		_update_health_bar()
		_update_training_damage_label()
		_hit_flash_left = 0.10
		damaged.emit(self, dummy_amount)
		return dummy_amount
	if is_boss and not is_mini_boss:
		resolved_amount *= get_boss_damage_taken_multiplier()
		if is_aoe:
			resolved_amount *= BOSS_AOE_DAMAGE_TAKEN_MULTIPLIER
	if enemy_type == TYPE_SHIELD:
		var incoming_direction := (knockback_origin - global_position).normalized()
		if incoming_direction != Vector2.ZERO and incoming_direction.dot(_facing_direction) > 0.25:
			resolved_amount *= _shield_front_damage_multiplier
	var applied_amount := minf(health, resolved_amount)
	if is_boss:
		var next_phase_health := _get_next_boss_phase_health()
		if next_phase_health >= 0.0:
			applied_amount = minf(applied_amount, maxf(0.0, health - next_phase_health))
	health = maxf(0.0, health - applied_amount)
	if minor_skill_enabled and enemy_type == TYPE_MELEE and not _melee_blood_rage_triggered and health > 0.0 and health <= max_health * MELEE_BLOOD_RAGE_HEALTH_RATIO:
		_melee_blood_rage_triggered = true
		_melee_blood_rage_left = MELEE_BLOOD_RAGE_DURATION
	_update_health_bar()
	if is_boss:
		_update_boss_phase_transitions()
	_hit_flash_left = 0.10
	if cause_stagger and not is_boss:
		_stagger_left = maxf(_stagger_left, 0.13)
		_attack_windup_left = 0.0
		_attack_recovery_left = maxf(_attack_recovery_left, 0.12)
	if knockback_force > 0.0 and not is_boss:
		var push_direction: Vector2 = (global_position - knockback_origin).normalized()
		if push_direction == Vector2.ZERO:
			push_direction = Vector2.RIGHT
		_knockback_velocity = push_direction * knockback_force
	damaged.emit(self, applied_amount)
	if health <= 0.0:
		_die()
	return applied_amount

func get_boss_damage_taken_multiplier(health_ratio: float = -1.0) -> float:
	var ratio := health / max_health if health_ratio < 0.0 else health_ratio
	if ratio >= 0.70:
		return 1.0
	if ratio >= 0.40:
		return 0.95
	if ratio >= 0.10:
		return 0.90
	return 0.75

func _get_next_boss_phase_health() -> float:
	if is_mini_boss:
		if not _boss_phase_40_triggered and health > max_health * 0.50:
			return max_health * 0.50
		return -1.0
	if not _boss_phase_70_triggered and health > max_health * 0.70:
		return max_health * 0.70
	if not _boss_phase_40_triggered and health > max_health * 0.40:
		return max_health * 0.40
	if not _boss_phase_20_triggered and health > max_health * BOSS_DESPERATION_HEALTH_RATIO:
		return max_health * BOSS_DESPERATION_HEALTH_RATIO
	if not _boss_phase_10_triggered and health > max_health * 0.10:
		return max_health * 0.10
	return -1.0

func _update_boss_phase_transitions() -> void:
	var transitioned := false
	if is_mini_boss:
		if not _boss_phase_40_triggered and health <= max_health * 0.50:
			_boss_phase_40_triggered = true
			_enter_boss_enrage()
			_boss_invulnerability_left = 0.40
		return
	if not _boss_phase_70_triggered and health <= max_health * 0.70:
		_boss_phase_70_triggered = true
		_boss_reinforcements_called = true
		boss_reinforcement_requested.emit(self)
		transitioned = true
	elif not _boss_phase_40_triggered and health <= max_health * 0.40:
		_boss_phase_40_triggered = true
		_enter_boss_enrage()
		transitioned = true
	elif not _boss_phase_20_triggered and health <= max_health * BOSS_DESPERATION_HEALTH_RATIO:
		_boss_phase_20_triggered = true
		_boss_desperation_unlocked = true
		_boss_desperation_timer = 0.0
		transitioned = true
	elif not _boss_phase_10_triggered and health <= max_health * 0.10:
		_boss_phase_10_triggered = true
		transitioned = true
	if transitioned:
		_boss_invulnerability_left = BOSS_PHASE_INVULNERABILITY

func heal(amount: float) -> float:
	if _is_dying or amount <= 0.0 or health >= max_health:
		return 0.0
	var old_health := health
	health = minf(max_health, health + amount)
	_update_health_bar()
	return health - old_health

func make_authority_state(marked_by_player_id: int = 0, guaranteed_crit_player_id: int = 0) -> Dictionary:
	return {
		"enemy_id": network_id,
		"enemy_type": enemy_type,
		"position": global_position,
		"health": health,
		"maximum_health": max_health,
		"marked_by_player_id": marked_by_player_id,
		"mark_left": _mark_left,
		"mark_damage_multiplier": _mark_damage_multiplier,
		"root_left": _root_left,
		"stun_left": _stun_left,
		"slow_left": _slow_left,
		"slow_move_multiplier": _slow_move_multiplier,
		"guaranteed_crit_player_id": guaranteed_crit_player_id,
		"velocity": velocity,
		"facing_direction": _facing_direction,
		"animation": _current_anim,
		"minor_skill_enabled": minor_skill_enabled,
		"melee_blood_rage_left": _melee_blood_rage_left,
		"training_damage_total": training_damage_total,
		"training_damage_reset_left": _training_dummy_reset_left,
	}

func apply_authority_state(state: Dictionary) -> void:
	network_id = int(state.get("enemy_id", network_id))
	var next_position := state.get("position", global_position) as Vector2
	if authority_enabled or not _authority_state_received:
		global_position = next_position
	authority_target_position = next_position
	authority_velocity = state.get("velocity", Vector2.ZERO) as Vector2
	_facing_direction = state.get("facing_direction", _facing_direction) as Vector2
	authority_animation = str(state.get("animation", authority_animation))
	minor_skill_enabled = bool(state.get("minor_skill_enabled", minor_skill_enabled))
	_melee_blood_rage_left = maxf(0.0, float(state.get("melee_blood_rage_left", _melee_blood_rage_left)))
	training_damage_total = maxf(0.0, float(state.get("training_damage_total", training_damage_total)))
	_training_dummy_reset_left = maxf(0.0, float(state.get("training_damage_reset_left", _training_dummy_reset_left)))
	_authority_state_received = true
	max_health = maxf(1.0, float(state.get("maximum_health", max_health)))
	health = clampf(float(state.get("health", health)), 0.0, max_health)
	_mark_left = maxf(0.0, float(state.get("mark_left", 0.0)))
	_mark_damage_multiplier = float(state.get("mark_damage_multiplier", 1.0))
	_root_left = maxf(0.0, float(state.get("root_left", 0.0)))
	_stun_left = maxf(0.0, float(state.get("stun_left", 0.0)))
	_slow_left = maxf(0.0, float(state.get("slow_left", 0.0)))
	_slow_move_multiplier = float(state.get("slow_move_multiplier", 1.0))
	_is_dying = false
	_update_health_bar()
	_update_training_damage_label()

func apply_authority_owners(marked_by: PlayerController, guaranteed_crit_by: PlayerController) -> void:
	_marked_by = marked_by if _mark_left > 0.0 else null
	_guaranteed_arrow_crit_by = guaranteed_crit_by

func _die() -> void:
	if is_training_dummy:
		_is_dying = false
		health = max_health
		training_damage_total = 0.0
		_training_dummy_reset_left = 0.0
		_update_health_bar()
		_update_training_damage_label()
		return
	if _is_dying:
		return
	_is_dying = true
	health = 0.0
	died.emit(self)
	queue_free()

func apply_defense_repel(knockback_origin: Vector2, knockback_force: float = 170.0) -> void:
	if is_boss:
		return
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
	if not has_node("TrainingDamageLabel"):
		_training_damage_label = Label.new()
		_training_damage_label.name = "TrainingDamageLabel"
		_training_damage_label.position = Vector2(-82.0, -86.0)
		_training_damage_label.custom_minimum_size = Vector2(164.0, 26.0)
		_training_damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_training_damage_label.add_theme_font_size_override("font_size", 16)
		_training_damage_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.38, 1.0))
		_training_damage_label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.02, 0.98))
		_training_damage_label.add_theme_constant_override("outline_size", 3)
		_training_damage_label.z_index = 21
		add_child(_training_damage_label)
	else:
		_training_damage_label = get_node("TrainingDamageLabel") as Label
	_update_health_bar()
	_update_training_damage_label()
	_play_animation(ANIM_IDLE, true)

func _update_health_bar() -> void:
	if _health_bar == null:
		return
	_health_bar.max_value = max_health
	_health_bar.value = health
	_health_bar.visible = is_training_dummy or health < max_health

func _update_training_damage_label() -> void:
	if _training_damage_label == null:
		return
	_training_damage_label.visible = is_training_dummy
	_training_damage_label.text = "5秒伤害：%d" % roundi(training_damage_total)

func _update_variant_visual() -> void:
	if _sprite == null:
		return
	var tint: Color = EnemyAnimationCatalogScript.get_tint(enemy_type)
	if minor_skill_enabled:
		tint = tint.lerp(Color(1.0, 0.78, 0.34, 1.0), 0.18)
	_sprite.modulate = tint

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
	_advance_current_animation(delta)

func _advance_current_animation(delta: float) -> void:
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
	_attack_timer = _current_attack_interval()
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
		if minor_skill_enabled:
			_ranged_shots_since_reposition += 1
			if _ranged_shots_since_reposition >= RANGED_REPOSITION_SHOTS:
				_start_ranged_reposition(shoot_direction)
		return
	if global_position.distance_to(_target.global_position) <= attack_range + 16.0:
		attacked_player.emit(self, _target, attack_damage)

func _update_ranged_movement(to_target: Vector2, distance: float) -> void:
	if distance < preferred_range * 0.72:
		velocity = -to_target.normalized() * _current_move_speed()
	elif distance > preferred_range * 1.15:
		velocity = to_target.normalized() * _current_move_speed()
	else:
		velocity = Vector2.ZERO

func _start_ranged_reposition(shoot_direction: Vector2) -> void:
	_ranged_shots_since_reposition = 0
	_ranged_reposition_side *= -1.0
	_ranged_reposition_direction = shoot_direction.rotated(PI * 0.5 * _ranged_reposition_side).normalized()
	var destination := global_position + _ranged_reposition_direction * 90.0
	if not arena_bounds.has_point(destination):
		_ranged_reposition_direction *= -1.0
	_ranged_reposition_left = RANGED_REPOSITION_DURATION

func _current_attack_interval() -> float:
	if enemy_type == TYPE_MELEE and _melee_blood_rage_left > 0.0:
		return attack_interval * MELEE_BLOOD_RAGE_ATTACK_INTERVAL_MULTIPLIER
	return attack_interval

func _current_move_speed() -> float:
	var speed_multiplier := MELEE_BLOOD_RAGE_SPEED_MULTIPLIER if enemy_type == TYPE_MELEE and _melee_blood_rage_left > 0.0 else 1.0
	return move_speed * _slow_move_multiplier * speed_multiplier

func _update_close_range_pressure(to_target: Vector2, distance: float, delta: float) -> void:
	if distance <= 1.0:
		velocity = Vector2.ZERO
	else:
		var pressure_speed: float = _current_move_speed() * 0.28
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

func _start_boss_cataclysm() -> void:
	if _target == null or not is_instance_valid(_target) or _target_is_dead():
		return
	velocity = Vector2.ZERO
	_attack_timer = attack_interval
	_attack_recovery_left = 0.90
	_boss_cast_pause_left = 1.25
	_start_attack_animation()
	var radius := 220.0 if _boss_enraged else 190.0
	var damage := attack_damage * (2.25 if _boss_enraged else 2.0)
	area_attack_requested.emit(self, _target.global_position, radius, damage, _boss_cast_pause_left)
	_boss_cataclysm_timer = 6.5 if _boss_enraged else 8.5
	_boss_area_timer = maxf(_boss_area_timer, 1.8)

func _start_boss_desperation_attack() -> void:
	if _target == null or not is_instance_valid(_target) or _target_is_dead():
		return
	velocity = Vector2.ZERO
	_attack_timer = attack_interval
	_attack_recovery_left = 1.0
	_boss_cast_pause_left = BOSS_DESPERATION_WINDUP
	_start_attack_animation()
	area_attack_requested.emit(self, global_position, BOSS_DESPERATION_RADIUS, attack_damage * 2.8, BOSS_DESPERATION_WINDUP)
	_boss_desperation_timer = BOSS_DESPERATION_COOLDOWN
	_boss_area_timer = maxf(_boss_area_timer, 1.8)
	_boss_cataclysm_timer = maxf(_boss_cataclysm_timer, 2.4)

func _enter_boss_enrage() -> void:
	_boss_enraged = true
	attack_damage *= BOSS_ENRAGE_DAMAGE_MULTIPLIER
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
	_apply_sprite_frame(
		str(data["path"]),
		EnemyAnimationCatalogScript.get_frame_size(enemy_type, is_boss),
		EnemyAnimationCatalogScript.get_scale(enemy_type, is_boss),
		_anim_frame
	)

func _get_animation_data(anim_name: String) -> Dictionary:
	return EnemyAnimationCatalogScript.get_animation(enemy_type, anim_name, is_boss)

func _update_feedback() -> void:
	if _hit_flash_left > 0.0:
		_sprite.modulate = Color(1.0, 0.45, 0.45, 1.0)
	elif enemy_type == TYPE_MELEE and _melee_blood_rage_left > 0.0:
		_sprite.modulate = Color(1.0, 0.32, 0.16, 1.0)
	else:
		_update_variant_visual()
