extends CharacterBody2D
class_name PlayerController

signal health_changed(current: float, maximum: float)
signal died
signal damage_taken(amount: float, defended: bool)
signal basic_attack_requested(origin: Vector2, direction: Vector2, attack_length: float, half_width: float, damage: float)
signal projectile_attack_requested(origin: Vector2, direction: Vector2, damage: float)
signal active_skill_requested(origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float)
signal fan_skill_requested(origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float)
signal ultimate_skill_requested(origin: Vector2, direction: Vector2, damage: float, duration: float)
signal cooldown_notice_requested(skill_index: int)
signal reflected_damage_requested(enemy: EnemyController, amount: float)

const UNIT_PATH_PREFIX := "res://assets/tiny_swords_free_pack/Units/"
const SPRITE_FRAME_SIZE := Vector2(192, 192)
const ANIM_IDLE := "idle"
const ANIM_RUN := "run"
const ANIM_GUARD := "guard"
const ANIM_ATTACK_1 := "attack_1"
const ANIM_ATTACK_2 := "attack_2"
const ANIM_DASH := "dash"
const ANIM_CAST := "cast"
const ANIM_HIT := "hit"
const ANIM_DEATH := "death"
const DEFEND_TAP_GRACE := 0.12
const DEFEND_FULL_STOP_TIME := 0.45
const ARCHER_Q_MAX_CHARGE_TIME := 1.20
const ARCHER_Q_MIN_DAMAGE_RATIO := 0.65
const CHARACTER_WARRIOR := "warrior"
const CHARACTER_ARCHER := "archer"
const CHARACTER_LANCER := "lancer"
const CHARACTER_MAGE := "mage"
const MAGE_ANIMATION_PATH := "res://assets/original/characters/mage/animations/"
const WARRIOR_ANIMATION_PATH := "res://assets/original/characters/warrior/animations/"
const LANCER_ANIMATION_PATH := "res://assets/original/characters/lancer/animations/"
const ARCHER_ANIMATION_PATH := "res://assets/original/characters/archer/animations/"

var max_health := 120.0
var health := max_health
var move_speed := 240.0
var attack_damage := 26.0
var attack_cooldown := 0.34
var attack_range := 76.0
var attack_half_width := 34.0
var attack_move_multiplier := 0.55
var attack_knockback := 150.0
var crit_chance := 0.0
var crit_multiplier := 1.8
var lifesteal_ratio := 0.0
var dash_cooldown := 0.95
var dash_max_charges := 1
var dash_charges := 1
var dash_speed := 760.0
var dash_time := 0.18
var invulnerable_time := 0.22
var defense_damage_multiplier := 0.45
var skill_damage := 58.0
var skill_cooldown := 4.0
var skill_length := 220.0
var skill_half_width := 42.0
var fan_skill_damage := 115.0
var fan_skill_cooldown := 9.0
var fan_skill_length := 250.0
var fan_skill_half_width := 16.0
var ultimate_cooldown: float = 28.0
var ultimate_duration: float = 8.0
var ultimate_damage_multiplier := 1.0

var arena_bounds := Rect2(Vector2(-480, -270), Vector2(960, 540))
var is_dead := false
var is_defending := false
var move_left_action: StringName = "move_left"
var move_right_action: StringName = "move_right"
var move_up_action: StringName = "move_up"
var move_down_action: StringName = "move_down"
var basic_attack_action: StringName = "basic_attack"
var dash_action: StringName = "dash"
var active_skill_action: StringName = "active_skill"
var fan_skill_action: StringName = "fan_skill"
var ultimate_skill_action: StringName = "ultimate_skill"
var defend_action: StringName = "defend"
var use_mouse_aim := true
var player_tint := Color.WHITE
var visual_scale := 0.55
var unit_color_folder := "Blue Units"
var character_id := CHARACTER_WARRIOR
var cooldowns_paused := false
var external_input_enabled := false

var _attack_timer := 0.0
var _dash_timer := 0.0
var _skill_timer := 0.0
var _fan_skill_timer := 0.0
var _ultimate_timer: float = 0.0
var _dash_time_left := 0.0
var _invulnerable_left := 0.0
var _damage_flash_left := 0.0
var _defense_flash_left := 0.0
var _last_direction := Vector2.RIGHT
var _current_anim := ""
var _anim_frame := 0
var _anim_timer := 0.0
var _attack_anim_left := 0.0
var _hit_anim_left := 0.0
var _death_anim_finished := false
var _pending_combat_event: Dictionary = {}
var _combat_event_emitted := false
var _defend_hold_time := 0.0
var _attack_combo_index := 0
var _combo_window_left := 0.0
var _external_move_direction := Vector2.ZERO
var _external_aim_direction := Vector2.RIGHT
var _external_aim_target := Vector2.ZERO
var _external_has_aim_target := false
var _external_defending := false
var _external_basic_pressed := false
var _external_dash_pressed := false
var _external_skill_pressed := false
var _external_skill_held := false
var _external_skill_released := false
var _external_fan_pressed := false
var _external_ultimate_pressed := false
var _warrior_taunt_guard_left := 0.0
var _warrior_counter_left := 0.0
var _warrior_blade_guard_left := 0.0
var _archer_q_charging := false
var _archer_q_charge_time := 0.0

var _sprite: Sprite2D
var _collision_shape: CollisionShape2D
var _charge_indicator: Line2D

func _ready() -> void:
	add_to_group("players")
	collision_layer = 0
	collision_mask = 0
	_setup_nodes()
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		if not _death_anim_finished:
			_advance_animation(delta)
			var death_data := _get_animation_data(ANIM_DEATH)
			_death_anim_finished = _anim_frame >= int(death_data["frames"]) - 1
		return

	_tick_timers(delta)
	is_defending = _get_defend_pressed() or _warrior_counter_left > 0.0
	_defend_hold_time = _defend_hold_time + delta if is_defending else 0.0
	var input_direction: Vector2 = _get_move_direction()
	if input_direction != Vector2.ZERO and _attack_anim_left <= 0.0:
		_last_direction = input_direction.normalized()

	if not cooldowns_paused and _consume_basic_pressed():
		if _attack_timer <= 0.0:
			var attack_direction: Vector2 = _get_attack_direction()
			_last_direction = attack_direction
			_attack_timer = attack_cooldown
			_queue_combat_event("basic", attack_direction, attack_damage)
			_start_attack_animation(false)
		else:
			cooldown_notice_requested.emit(0)

	if not cooldowns_paused and _consume_dash_pressed() and dash_charges > 0 and input_direction != Vector2.ZERO:
		dash_charges -= 1
		if dash_charges == dash_max_charges - 1:
			_dash_timer = dash_cooldown
		_dash_time_left = dash_time
		_invulnerable_left = maxf(_invulnerable_left, invulnerable_time)

	if not cooldowns_paused:
		if character_id == CHARACTER_ARCHER:
			_update_archer_q_charge(delta)
		elif _consume_skill_pressed():
			if _skill_timer <= 0.0:
				var skill_direction: Vector2 = _get_attack_direction()
				_last_direction = skill_direction
				_skill_timer = skill_cooldown
				_queue_combat_event("q", skill_direction, skill_damage)
				_start_cast_animation()
			else:
				cooldown_notice_requested.emit(1)

	if not cooldowns_paused and _consume_fan_pressed():
		if _fan_skill_timer <= 0.0:
			var fan_direction: Vector2 = _get_attack_direction()
			_last_direction = fan_direction
			_fan_skill_timer = fan_skill_cooldown
			_queue_combat_event("e", fan_direction, fan_skill_damage)
			_start_cast_animation()
		else:
			cooldown_notice_requested.emit(2)

	if not cooldowns_paused and _consume_ultimate_pressed():
		if _ultimate_timer <= 0.0:
			var ultimate_direction: Vector2 = _get_attack_direction()
			_last_direction = ultimate_direction
			_ultimate_timer = ultimate_cooldown
			_queue_combat_event("f", ultimate_direction, attack_damage * 1.5 * ultimate_damage_multiplier)
			_start_cast_animation()
		else:
			cooldown_notice_requested.emit(3)

	var speed: float = dash_speed if _dash_time_left > 0.0 else move_speed
	if _dash_time_left <= 0.0 and _attack_anim_left > 0.0:
		speed *= attack_move_multiplier
	if _dash_time_left <= 0.0:
		speed *= _get_defense_move_multiplier()
	velocity = _last_direction * speed if _dash_time_left > 0.0 else input_direction * speed
	move_and_slide()
	global_position = global_position.clamp(arena_bounds.position, arena_bounds.end)
	_update_animation(delta, input_direction)
	_update_feedback()

func make_input_packet() -> Dictionary:
	return {
		"move": Input.get_vector(move_left_action, move_right_action, move_up_action, move_down_action),
		"aim": _get_attack_direction(),
		"aim_target": get_global_mouse_position(),
		"defend": Input.is_action_pressed(defend_action),
		"basic": Input.is_action_just_pressed(basic_attack_action),
		"dash": Input.is_action_just_pressed(dash_action),
		"skill": Input.is_action_just_pressed(active_skill_action),
		"skill_hold": Input.is_action_pressed(active_skill_action),
		"fan": Input.is_action_just_pressed(fan_skill_action),
		"ultimate": Input.is_action_just_pressed(ultimate_skill_action),
		"position": global_position,
	}

func apply_external_input(packet: Dictionary) -> void:
	_external_move_direction = packet.get("move", Vector2.ZERO) as Vector2
	_external_aim_direction = packet.get("aim", _last_direction) as Vector2
	if packet.has("aim_target"):
		_external_aim_target = packet["aim_target"] as Vector2
		_external_has_aim_target = true
	if _external_aim_direction.length_squared() <= 0.001:
		_external_aim_direction = _last_direction
	_external_defending = bool(packet.get("defend", false))
	_external_basic_pressed = _external_basic_pressed or bool(packet.get("basic", false))
	_external_dash_pressed = _external_dash_pressed or bool(packet.get("dash", false))
	_external_skill_pressed = _external_skill_pressed or bool(packet.get("skill", false))
	var next_skill_held := bool(packet.get("skill_hold", false))
	_external_skill_released = _external_skill_released or (_external_skill_held and not next_skill_held)
	_external_skill_held = next_skill_held
	_external_fan_pressed = _external_fan_pressed or bool(packet.get("fan", false))
	_external_ultimate_pressed = _external_ultimate_pressed or bool(packet.get("ultimate", false))
	if packet.has("position"):
		global_position = packet["position"] as Vector2

func apply_damage(amount: float, source: EnemyController = null) -> bool:
	if is_dead or _invulnerable_left > 0.0:
		return false

	var defended: bool = is_defending
	var final_amount: float = amount * defense_damage_multiplier if is_defending else amount
	if _warrior_taunt_guard_left > 0.0:
		final_amount *= 0.5
	if _warrior_blade_guard_left > 0.0:
		final_amount *= 0.75
	health = maxf(0.0, health - final_amount)
	_damage_flash_left = 0.12
	if defended:
		_defense_flash_left = 0.18
	damage_taken.emit(final_amount, defended)
	if _warrior_counter_left > 0.0 and source != null and is_instance_valid(source):
		reflected_damage_requested.emit(source, amount * 1.30)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		is_dead = true
		_reset_transient_action_state()
		_death_anim_finished = false
		_play_animation(ANIM_DEATH, true)
		died.emit()
	elif not defended:
		_hit_anim_left = 0.18
		_play_animation(ANIM_HIT, true)
	return defended

func get_projectile_origin(direction: Vector2) -> Vector2:
	var forward := direction.normalized()
	if forward == Vector2.ZERO:
		forward = _last_direction
	return global_position + forward * 25.0 + Vector2(0.0, -12.0)

func get_projectile_direction(origin: Vector2, fallback: Vector2) -> Vector2:
	var target := Vector2.ZERO
	var has_target := false
	if external_input_enabled and _external_has_aim_target:
		target = _external_aim_target
		has_target = true
	elif not external_input_enabled and use_mouse_aim:
		target = get_global_mouse_position()
		has_target = true
	if has_target and target.distance_squared_to(origin) > 1.0:
		return (target - origin).normalized()
	return fallback.normalized() if fallback != Vector2.ZERO else _last_direction

func _queue_combat_event(event_type: String, direction: Vector2, base_damage: float) -> void:
	_pending_combat_event = {"type": event_type, "direction": direction, "damage": base_damage}
	_combat_event_emitted = false

func _emit_pending_combat_event() -> void:
	if _combat_event_emitted or _pending_combat_event.is_empty() or _anim_frame < 2:
		return
	_combat_event_emitted = true
	var event_type := str(_pending_combat_event.get("type", ""))
	var direction := _pending_combat_event.get("direction", _last_direction) as Vector2
	var damage := _roll_damage(float(_pending_combat_event.get("damage", 0.0)))
	match event_type:
		"basic":
			if character_id == CHARACTER_ARCHER:
				var projectile_origin := get_projectile_origin(direction)
				projectile_attack_requested.emit(projectile_origin, get_projectile_direction(projectile_origin, direction), damage)
			else:
				basic_attack_requested.emit(global_position, direction, attack_range, attack_half_width, damage)
		"q":
			active_skill_requested.emit(global_position, direction, skill_length, skill_half_width, damage)
		"e":
			fan_skill_requested.emit(global_position, direction, fan_skill_length, fan_skill_half_width, damage)
		"f":
			ultimate_skill_requested.emit(global_position, direction, damage, ultimate_duration)
	_pending_combat_event.clear()

func _get_attack_direction() -> Vector2:
	if external_input_enabled:
		return _external_aim_direction.normalized()
	if not use_mouse_aim:
		return _last_direction
	var direction: Vector2 = get_global_mouse_position() - global_position
	if direction.length_squared() <= 1.0:
		return _last_direction
	return direction.normalized()

func _get_move_direction() -> Vector2:
	if external_input_enabled:
		return _external_move_direction
	return Input.get_vector(move_left_action, move_right_action, move_up_action, move_down_action)

func _get_defend_pressed() -> bool:
	if external_input_enabled:
		return _external_defending
	return Input.is_action_pressed(defend_action)

func _get_defense_move_multiplier() -> float:
	if _warrior_counter_left > 0.0:
		return 1.0
	if not is_defending or _defend_hold_time <= DEFEND_TAP_GRACE:
		return 1.0
	var slowdown_duration := DEFEND_FULL_STOP_TIME - DEFEND_TAP_GRACE
	var slowdown_progress := (_defend_hold_time - DEFEND_TAP_GRACE) / slowdown_duration
	return 1.0 - clampf(slowdown_progress, 0.0, 1.0)

func activate_warrior_taunt_guard(duration: float) -> void:
	_warrior_taunt_guard_left = maxf(_warrior_taunt_guard_left, duration)

func activate_warrior_counter(duration: float) -> void:
	_warrior_counter_left = maxf(_warrior_counter_left, duration)

func activate_warrior_blade_guard(duration: float) -> void:
	_warrior_blade_guard_left = maxf(_warrior_blade_guard_left, duration)

func _consume_basic_pressed() -> bool:
	if not external_input_enabled:
		return Input.is_action_just_pressed(basic_attack_action)
	var pressed := _external_basic_pressed
	_external_basic_pressed = false
	return pressed

func _consume_dash_pressed() -> bool:
	if not external_input_enabled:
		return Input.is_action_just_pressed(dash_action)
	var pressed := _external_dash_pressed
	_external_dash_pressed = false
	return pressed

func _consume_skill_pressed() -> bool:
	if not external_input_enabled:
		return Input.is_action_just_pressed(active_skill_action)
	var pressed := _external_skill_pressed
	_external_skill_pressed = false
	return pressed

func _get_skill_held() -> bool:
	return _external_skill_held if external_input_enabled else Input.is_action_pressed(active_skill_action)

func _consume_skill_released() -> bool:
	if not external_input_enabled:
		return Input.is_action_just_released(active_skill_action)
	var released := _external_skill_released
	_external_skill_released = false
	return released

func _update_archer_q_charge(delta: float) -> void:
	if _consume_skill_pressed():
		if _skill_timer > 0.0:
			cooldown_notice_requested.emit(1)
		else:
			_archer_q_charging = true
			_archer_q_charge_time = 0.0
	if not _archer_q_charging:
		_consume_skill_released()
		return
	if _get_skill_held():
		_archer_q_charge_time = minf(ARCHER_Q_MAX_CHARGE_TIME, _archer_q_charge_time + delta)
	if not _consume_skill_released():
		return
	var charge_ratio := clampf(_archer_q_charge_time / ARCHER_Q_MAX_CHARGE_TIME, 0.0, 1.0)
	var damage_ratio := lerpf(ARCHER_Q_MIN_DAMAGE_RATIO, 1.0, charge_ratio)
	var skill_direction := _get_attack_direction()
	_last_direction = skill_direction
	_skill_timer = skill_cooldown
	_queue_combat_event("q", skill_direction, skill_damage * damage_ratio)
	_start_cast_animation()
	_archer_q_charging = false
	_archer_q_charge_time = 0.0
	_warrior_taunt_guard_left = 0.0
	_warrior_counter_left = 0.0
	_warrior_blade_guard_left = 0.0

func _consume_fan_pressed() -> bool:
	if not external_input_enabled:
		return Input.is_action_just_pressed(fan_skill_action)
	var pressed := _external_fan_pressed
	_external_fan_pressed = false
	return pressed

func _consume_ultimate_pressed() -> bool:
	if not external_input_enabled:
		return Input.is_action_just_pressed(ultimate_skill_action)
	var pressed := _external_ultimate_pressed
	_external_ultimate_pressed = false
	return pressed

func heal(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	health = minf(max_health, health + amount)
	health_changed.emit(health, max_health)

func revive(health_ratio: float = 0.5) -> void:
	is_dead = false
	visible = true
	_reset_transient_action_state()
	_death_anim_finished = false
	_play_animation(ANIM_IDLE, true)
	health = maxf(1.0, max_health * health_ratio)
	_invulnerable_left = maxf(_invulnerable_left, invulnerable_time)
	_damage_flash_left = 0.0
	_defense_flash_left = 0.0
	health_changed.emit(health, max_health)

func _reset_transient_action_state() -> void:
	velocity = Vector2.ZERO
	is_defending = false
	_dash_time_left = 0.0
	_attack_anim_left = 0.0
	_hit_anim_left = 0.0
	_defend_hold_time = 0.0
	_pending_combat_event.clear()
	_combat_event_emitted = false
	_combo_window_left = 0.0
	_external_move_direction = Vector2.ZERO
	_external_aim_target = Vector2.ZERO
	_external_has_aim_target = false
	_external_defending = false
	_external_basic_pressed = false
	_external_dash_pressed = false
	_external_skill_pressed = false
	_external_skill_held = false
	_external_skill_released = false
	_external_fan_pressed = false
	_external_ultimate_pressed = false
	_archer_q_charging = false
	_archer_q_charge_time = 0.0

func roll_damage(base_damage: float) -> float:
	return _roll_damage(base_damage)

func apply_character_config(config: Dictionary) -> void:
	character_id = str(config.get("id", character_id))
	visual_scale = float(config.get("visual_scale", visual_scale))
	unit_color_folder = str(config.get("unit_color_folder", unit_color_folder))
	max_health = float(config.get("max_health", max_health))
	health = max_health
	move_speed = float(config.get("move_speed", move_speed))
	attack_damage = float(config.get("attack_damage", attack_damage))
	attack_cooldown = float(config.get("attack_cooldown", attack_cooldown))
	attack_range = float(config.get("attack_range", attack_range))
	attack_half_width = float(config.get("attack_half_width", attack_half_width))
	attack_knockback = float(config.get("attack_knockback", attack_knockback))
	defense_damage_multiplier = float(config.get("defense_damage_multiplier", defense_damage_multiplier))
	skill_cooldown = float(config.get("skill_cooldown", skill_cooldown))
	skill_damage = float(config.get("skill_damage", skill_damage))
	skill_length = float(config.get("skill_length", skill_length))
	skill_half_width = float(config.get("skill_half_width", skill_half_width))
	fan_skill_damage = float(config.get("fan_skill_damage", fan_skill_damage))
	fan_skill_length = float(config.get("fan_skill_length", fan_skill_length))
	fan_skill_half_width = float(config.get("fan_skill_half_width", fan_skill_half_width))
	fan_skill_cooldown = float(config.get("fan_skill_cooldown", fan_skill_cooldown))
	ultimate_cooldown = float(config.get("ultimate_cooldown", ultimate_cooldown))
	health_changed.emit(health, max_health)
	if _sprite != null:
		_play_animation(ANIM_IDLE, true)

func _roll_damage(base_damage: float) -> float:
	if crit_chance > 0.0 and randf() < crit_chance:
		return base_damage * crit_multiplier
	return base_damage

func apply_upgrade(upgrade: Dictionary) -> void:
	var stat: String = str(upgrade.get("stat", ""))
	var multiplier: float = float(upgrade.get("multiplier", 1.0))

	match stat:
		"attack_damage":
			attack_damage *= multiplier
		"max_health":
			var old_max: float = max_health
			max_health *= multiplier
			health += max_health - old_max
			health_changed.emit(health, max_health)
		"move_speed":
			move_speed *= multiplier
		"attack_cooldown":
			attack_cooldown = maxf(0.15, attack_cooldown * multiplier)
		"dash_cooldown":
			dash_cooldown = maxf(0.35, dash_cooldown * multiplier)
		"skill_cooldown":
			skill_cooldown = maxf(1.0, skill_cooldown * multiplier)
		"attack_range":
			attack_range *= multiplier
		"skill_damage":
			skill_damage *= multiplier
		"skill_range":
			skill_length *= multiplier
			skill_half_width *= sqrt(multiplier)
		"fan_skill_damage":
			fan_skill_damage *= multiplier
		"fan_skill_range":
			fan_skill_length *= multiplier
			fan_skill_half_width *= sqrt(multiplier)
		"fan_skill_cooldown":
			fan_skill_cooldown = maxf(1.2, fan_skill_cooldown * multiplier)
		"ultimate_damage":
			ultimate_damage_multiplier *= multiplier
		"ultimate_duration":
			ultimate_duration *= multiplier
		"ultimate_cooldown":
			ultimate_cooldown = maxf(6.0, ultimate_cooldown * multiplier)
		"lifesteal":
			lifesteal_ratio += float(upgrade.get("add", 0.04))
		"crit_chance":
			crit_chance += float(upgrade.get("add", 0.08))
		"knockback":
			attack_knockback *= multiplier
		"dash_charges":
			dash_max_charges += int(upgrade.get("add", 1))
			dash_charges = dash_max_charges
		"heal_percent":
			heal(max_health * float(upgrade.get("percent", 0.15)))

func _tick_timers(delta: float) -> void:
	_warrior_taunt_guard_left = maxf(0.0, _warrior_taunt_guard_left - delta)
	_warrior_counter_left = maxf(0.0, _warrior_counter_left - delta)
	_warrior_blade_guard_left = maxf(0.0, _warrior_blade_guard_left - delta)
	if not cooldowns_paused:
		_attack_timer = maxf(0.0, _attack_timer - delta)
		if dash_charges < dash_max_charges:
			_dash_timer = maxf(0.0, _dash_timer - delta)
			if _dash_timer <= 0.0:
				dash_charges += 1
				if dash_charges < dash_max_charges:
					_dash_timer = dash_cooldown
		else:
			_dash_timer = 0.0
		_skill_timer = maxf(0.0, _skill_timer - delta)
		_fan_skill_timer = maxf(0.0, _fan_skill_timer - delta)
		_ultimate_timer = maxf(0.0, _ultimate_timer - delta)
	_dash_time_left = maxf(0.0, _dash_time_left - delta)
	_invulnerable_left = maxf(0.0, _invulnerable_left - delta)
	_damage_flash_left = maxf(0.0, _damage_flash_left - delta)
	_defense_flash_left = maxf(0.0, _defense_flash_left - delta)
	_attack_anim_left = maxf(0.0, _attack_anim_left - delta)
	_hit_anim_left = maxf(0.0, _hit_anim_left - delta)
	_combo_window_left = maxf(0.0, _combo_window_left - delta)

func _setup_nodes() -> void:
	if not has_node("Sprite2D"):
		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	if not has_node("CollisionShape2D"):
		_collision_shape = CollisionShape2D.new()
		_collision_shape.name = "CollisionShape2D"
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = 12.0
		_collision_shape.shape = circle
		add_child(_collision_shape)
	else:
		_collision_shape = get_node("CollisionShape2D") as CollisionShape2D

	_sprite = get_node("Sprite2D") as Sprite2D
	_charge_indicator = Line2D.new()
	_charge_indicator.name = "ChargeIndicator"
	_charge_indicator.width = 3.0
	_charge_indicator.closed = true
	_charge_indicator.visible = false
	_charge_indicator.position = Vector2(0.0, -30.0)
	add_child(_charge_indicator)
	_sprite.centered = true
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(Vector2.ZERO, SPRITE_FRAME_SIZE)
	_sprite.scale = Vector2.ONE * visual_scale
	_play_animation(ANIM_IDLE, true)

func _update_animation(delta: float, input_direction: Vector2) -> void:
	if _hit_anim_left > 0.0:
		_advance_animation(delta)
		return
	if _attack_anim_left > 0.0:
		if absf(_last_direction.x) > 0.01:
			_sprite.flip_h = _last_direction.x < 0.0
		_advance_animation(delta)
		return

	if input_direction.x != 0.0:
		_sprite.flip_h = input_direction.x < 0.0

	if is_defending:
		_play_animation(ANIM_GUARD)
	elif _dash_time_left > 0.0:
		_play_animation(ANIM_DASH)
	elif input_direction != Vector2.ZERO:
		_play_animation(ANIM_RUN)
	else:
		_play_animation(ANIM_IDLE)
	_advance_animation(delta)

func _start_attack_animation(use_second_attack: bool) -> void:
	if use_second_attack:
		_play_animation(ANIM_ATTACK_2, true)
	else:
		if _combo_window_left <= 0.0:
			_attack_combo_index = 0
		else:
			_attack_combo_index = 1 - _attack_combo_index
		var anim_name: String = ANIM_ATTACK_1 if _attack_combo_index == 0 else ANIM_ATTACK_2
		_play_animation(anim_name, true)
	_combo_window_left = 0.72
	_attack_anim_left = 0.26

func _start_cast_animation() -> void:
	_play_animation(ANIM_CAST, true)
	_attack_anim_left = 0.36

func _set_sprite_texture(path: String) -> void:
	var texture: Texture2D = load(path) as Texture2D
	if _sprite.texture != texture:
		_sprite.texture = texture

func _play_animation(anim_name: String, force_restart: bool = false) -> void:
	if _current_anim == anim_name and not force_restart:
		return

	_current_anim = anim_name
	_anim_frame = 0
	_anim_timer = 0.0
	var data: Dictionary = _get_animation_data(anim_name)
	_set_sprite_texture(str(data["path"]))
	_apply_animation_frame()

func _advance_animation(delta: float) -> void:
	var data: Dictionary = _get_animation_data(_current_anim)
	var frame_count: int = int(data["frames"])
	var frame_time: float = float(data["frame_time"])
	_anim_timer += delta
	while _anim_timer >= frame_time:
		_anim_timer -= frame_time
		_anim_frame += 1
		if _anim_frame >= frame_count:
			_anim_frame = 0 if bool(data["loop"]) else frame_count - 1
	_apply_animation_frame()

func _apply_animation_frame() -> void:
	var data: Dictionary = _get_animation_data(_current_anim)
	var frame_size: Vector2 = data.get("frame_size", SPRITE_FRAME_SIZE) as Vector2
	_sprite.region_rect = Rect2(Vector2(frame_size.x * float(_anim_frame), 0.0), frame_size)
	_emit_pending_combat_event()

func _get_animation_data(anim_name: String) -> Dictionary:
	if anim_name in [ANIM_CAST, ANIM_HIT, ANIM_DEATH]:
		return _get_common_state_animation_data(anim_name)
	if character_id == CHARACTER_ARCHER:
		return _get_archer_animation_data(anim_name)
	if character_id == CHARACTER_LANCER:
		return _get_lancer_animation_data(anim_name)
	if character_id == CHARACTER_MAGE:
		return _get_mage_animation_data(anim_name)
	return _get_warrior_animation_data(anim_name)

func _get_common_state_animation_data(anim_name: String) -> Dictionary:
	var directory := WARRIOR_ANIMATION_PATH
	if character_id == CHARACTER_ARCHER:
		directory = ARCHER_ANIMATION_PATH
	elif character_id == CHARACTER_LANCER:
		directory = LANCER_ANIMATION_PATH
	elif character_id == CHARACTER_MAGE:
		directory = MAGE_ANIMATION_PATH
	var frames := 3 if anim_name == ANIM_HIT else 6
	var frame_time := 0.06 if anim_name == ANIM_HIT else 0.08
	return {
		"path": directory + character_id + "_" + anim_name + ".png",
		"frames": frames,
		"frame_time": frame_time,
		"loop": false,
		"frame_size": SPRITE_FRAME_SIZE,
	}

func _get_warrior_animation_data(anim_name: String) -> Dictionary:
	match anim_name:
		ANIM_RUN:
			return {"path": WARRIOR_ANIMATION_PATH + "warrior_run.png", "frames": 6, "frame_time": 0.09, "loop": true, "frame_size": SPRITE_FRAME_SIZE}
		ANIM_GUARD:
			return {"path": WARRIOR_ANIMATION_PATH + "warrior_defend.png", "frames": 4, "frame_time": 0.10, "loop": false, "frame_size": SPRITE_FRAME_SIZE}
		ANIM_ATTACK_1:
			return {"path": WARRIOR_ANIMATION_PATH + "warrior_attack_1.png", "frames": 6, "frame_time": 0.06, "loop": false, "frame_size": SPRITE_FRAME_SIZE}
		ANIM_ATTACK_2:
			return {"path": WARRIOR_ANIMATION_PATH + "warrior_attack_2.png", "frames": 6, "frame_time": 0.07, "loop": false, "frame_size": SPRITE_FRAME_SIZE}
		ANIM_DASH:
			return {"path": WARRIOR_ANIMATION_PATH + "warrior_dash.png", "frames": 4, "frame_time": 0.06, "loop": false, "frame_size": SPRITE_FRAME_SIZE}
		_:
			return {"path": WARRIOR_ANIMATION_PATH + "warrior_idle.png", "frames": 6, "frame_time": 0.14, "loop": true, "frame_size": SPRITE_FRAME_SIZE}

func _get_archer_animation_data(anim_name: String) -> Dictionary:
	match anim_name:
		ANIM_RUN:
			return {"path": ARCHER_ANIMATION_PATH + "archer_run.png", "frames": 6, "frame_time": 0.09, "loop": true, "frame_size": SPRITE_FRAME_SIZE}
		ANIM_GUARD:
			return {"path": ARCHER_ANIMATION_PATH + "archer_defend.png", "frames": 4, "frame_time": 0.10, "loop": false, "frame_size": SPRITE_FRAME_SIZE}
		ANIM_ATTACK_1:
			return {"path": ARCHER_ANIMATION_PATH + "archer_attack_1.png", "frames": 6, "frame_time": 0.06, "loop": false, "frame_size": SPRITE_FRAME_SIZE}
		ANIM_ATTACK_2:
			return {"path": ARCHER_ANIMATION_PATH + "archer_attack_2.png", "frames": 6, "frame_time": 0.07, "loop": false, "frame_size": SPRITE_FRAME_SIZE}
		ANIM_DASH:
			return {"path": ARCHER_ANIMATION_PATH + "archer_dash.png", "frames": 4, "frame_time": 0.06, "loop": false, "frame_size": SPRITE_FRAME_SIZE}
		_:
			return {"path": ARCHER_ANIMATION_PATH + "archer_idle.png", "frames": 6, "frame_time": 0.14, "loop": true, "frame_size": SPRITE_FRAME_SIZE}

func _get_lancer_animation_data(anim_name: String) -> Dictionary:
	match anim_name:
		ANIM_RUN:
			return {"path": LANCER_ANIMATION_PATH + "lancer_run.png", "frames": 6, "frame_time": 0.09, "loop": true, "frame_size": SPRITE_FRAME_SIZE}
		ANIM_GUARD:
			return {"path": LANCER_ANIMATION_PATH + "lancer_defend.png", "frames": 4, "frame_time": 0.10, "loop": false, "frame_size": SPRITE_FRAME_SIZE}
		ANIM_ATTACK_1:
			return {"path": LANCER_ANIMATION_PATH + "lancer_attack_1.png", "frames": 6, "frame_time": 0.06, "loop": false, "frame_size": SPRITE_FRAME_SIZE}
		ANIM_ATTACK_2:
			return {"path": LANCER_ANIMATION_PATH + "lancer_attack_2.png", "frames": 6, "frame_time": 0.07, "loop": false, "frame_size": SPRITE_FRAME_SIZE}
		ANIM_DASH:
			return {"path": LANCER_ANIMATION_PATH + "lancer_dash.png", "frames": 4, "frame_time": 0.06, "loop": false, "frame_size": SPRITE_FRAME_SIZE}
		_:
			return {"path": LANCER_ANIMATION_PATH + "lancer_idle.png", "frames": 6, "frame_time": 0.14, "loop": true, "frame_size": SPRITE_FRAME_SIZE}

func _get_mage_animation_data(anim_name: String) -> Dictionary:
	match anim_name:
		ANIM_RUN:
			return {"path": MAGE_ANIMATION_PATH + "mage_run.png", "frames": 6, "frame_time": 0.09, "loop": true, "frame_size": SPRITE_FRAME_SIZE}
		ANIM_GUARD:
			return {"path": MAGE_ANIMATION_PATH + "mage_defend.png", "frames": 4, "frame_time": 0.10, "loop": false, "frame_size": SPRITE_FRAME_SIZE}
		ANIM_ATTACK_1:
			return {"path": MAGE_ANIMATION_PATH + "mage_attack_1.png", "frames": 6, "frame_time": 0.06, "loop": false, "frame_size": SPRITE_FRAME_SIZE}
		ANIM_ATTACK_2:
			return {"path": MAGE_ANIMATION_PATH + "mage_attack_2.png", "frames": 6, "frame_time": 0.07, "loop": false, "frame_size": SPRITE_FRAME_SIZE}
		ANIM_DASH:
			return {"path": MAGE_ANIMATION_PATH + "mage_dash.png", "frames": 4, "frame_time": 0.06, "loop": false, "frame_size": SPRITE_FRAME_SIZE}
		_:
			return {"path": MAGE_ANIMATION_PATH + "mage_idle.png", "frames": 6, "frame_time": 0.14, "loop": true, "frame_size": SPRITE_FRAME_SIZE}

func _unit_sprite_path(unit_folder: String, file_name: String) -> String:
	return UNIT_PATH_PREFIX + unit_color_folder + "/" + unit_folder + "/" + file_name

func _update_feedback() -> void:
	_update_charge_indicator()
	if _defense_flash_left > 0.0:
		_sprite.modulate = Color(0.65, 0.85, 1.0, 1.0)
	elif _invulnerable_left > 0.0:
		_sprite.modulate = Color(0.55, 0.95, 1.0, 0.85)
	elif _damage_flash_left > 0.0:
		_sprite.modulate = Color(1.0, 0.45, 0.45, 1.0)
	else:
		_sprite.modulate = player_tint

func _update_charge_indicator() -> void:
	if _charge_indicator == null:
		return
	_charge_indicator.visible = character_id == CHARACTER_ARCHER and _archer_q_charging
	if not _charge_indicator.visible:
		return
	var ratio := clampf(_archer_q_charge_time / ARCHER_Q_MAX_CHARGE_TIME, 0.0, 1.0)
	var radius := lerpf(10.0, 19.0, ratio)
	var points := PackedVector2Array()
	for index in range(25):
		var angle := TAU * float(index) / 24.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	_charge_indicator.points = points
	_charge_indicator.default_color = Color(1.0, lerpf(0.72, 0.95, ratio), 0.20, 0.55 + ratio * 0.45)

func get_dash_ready() -> bool:
	return dash_charges > 0

func get_skill_ready() -> bool:
	return _skill_timer <= 0.0

func get_attack_ready() -> bool:
	return _attack_timer <= 0.0

func get_dash_remaining() -> float:
	return _dash_timer

func get_skill_remaining() -> float:
	return _skill_timer

func get_attack_remaining() -> float:
	return _attack_timer

func get_fan_skill_ready() -> bool:
	return _fan_skill_timer <= 0.0

func get_fan_skill_remaining() -> float:
	return _fan_skill_timer

func get_ultimate_ready() -> bool:
	return _ultimate_timer <= 0.0

func get_ultimate_remaining() -> float:
	return _ultimate_timer
