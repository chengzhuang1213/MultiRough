extends CharacterBody2D
class_name PlayerController

signal health_changed(current: float, maximum: float)
signal died
signal damage_taken(amount: float, defended: bool)
signal basic_attack_requested(origin: Vector2, direction: Vector2, attack_length: float, half_width: float, damage: float)
signal active_skill_requested(origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float)
signal fan_skill_requested(origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float)
signal ultimate_skill_requested(damage: float, duration: float)

const UNIT_PATH_PREFIX := "res://assets/tiny_swords_free_pack/Units/"
const WARRIOR_PATH_SUFFIX := "/Warrior/"
const SPRITE_FRAME_SIZE := Vector2(192, 192)
const ANIM_IDLE := "idle"
const ANIM_RUN := "run"
const ANIM_GUARD := "guard"
const ANIM_ATTACK_1 := "attack_1"
const ANIM_ATTACK_2 := "attack_2"

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
var unit_color_folder := "Blue Units"

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
var _attack_combo_index := 0
var _combo_window_left := 0.0

var _sprite: Sprite2D
var _collision_shape: CollisionShape2D

func _ready() -> void:
	add_to_group("players")
	collision_layer = 0
	collision_mask = 0
	_setup_nodes()
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return

	_tick_timers(delta)
	is_defending = Input.is_action_pressed(defend_action)
	var input_direction: Vector2 = Input.get_vector(move_left_action, move_right_action, move_up_action, move_down_action)
	if input_direction != Vector2.ZERO and _attack_anim_left <= 0.0:
		_last_direction = input_direction.normalized()

	if Input.is_action_just_pressed(basic_attack_action) and _attack_timer <= 0.0:
		var attack_direction: Vector2 = _get_attack_direction()
		_last_direction = attack_direction
		_attack_timer = attack_cooldown
		_start_attack_animation(false)
		basic_attack_requested.emit(global_position, attack_direction, attack_range, attack_half_width, _roll_damage(attack_damage))

	if Input.is_action_just_pressed(dash_action) and dash_charges > 0 and input_direction != Vector2.ZERO:
		dash_charges -= 1
		if _dash_timer <= 0.0:
			_dash_timer = dash_cooldown
		_dash_time_left = dash_time
		_invulnerable_left = maxf(_invulnerable_left, invulnerable_time)

	if Input.is_action_just_pressed(active_skill_action) and _skill_timer <= 0.0:
		var skill_direction: Vector2 = _get_attack_direction()
		_last_direction = skill_direction
		_skill_timer = skill_cooldown
		_start_attack_animation(true)
		active_skill_requested.emit(global_position, skill_direction, skill_length, skill_half_width, _roll_damage(skill_damage))

	if Input.is_action_just_pressed(fan_skill_action) and _fan_skill_timer <= 0.0:
		var fan_direction: Vector2 = _get_attack_direction()
		_last_direction = fan_direction
		_fan_skill_timer = fan_skill_cooldown
		_start_attack_animation(true)
		fan_skill_requested.emit(global_position, fan_direction, fan_skill_length, fan_skill_half_width, _roll_damage(fan_skill_damage))

	if Input.is_action_just_pressed(ultimate_skill_action) and _ultimate_timer <= 0.0:
		_ultimate_timer = ultimate_cooldown
		ultimate_skill_requested.emit(attack_damage * 1.5, ultimate_duration)

	var speed: float = dash_speed if _dash_time_left > 0.0 else move_speed
	if _dash_time_left <= 0.0 and _attack_anim_left > 0.0:
		speed *= attack_move_multiplier
	velocity = _last_direction * speed if _dash_time_left > 0.0 else input_direction * speed
	move_and_slide()
	global_position = global_position.clamp(arena_bounds.position, arena_bounds.end)
	_update_animation(delta, input_direction)
	_update_feedback()

func apply_damage(amount: float) -> bool:
	if is_dead or _invulnerable_left > 0.0:
		return false

	var defended: bool = is_defending
	var final_amount: float = amount * defense_damage_multiplier if is_defending else amount
	health = maxf(0.0, health - final_amount)
	_damage_flash_left = 0.12
	if defended:
		_defense_flash_left = 0.18
	damage_taken.emit(final_amount, defended)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		is_dead = true
		visible = false
		died.emit()
	return defended

func _get_attack_direction() -> Vector2:
	if not use_mouse_aim:
		return _last_direction
	var direction: Vector2 = get_global_mouse_position() - global_position
	if direction.length_squared() <= 1.0:
		return _last_direction
	return direction.normalized()

func heal(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	health = minf(max_health, health + amount)
	health_changed.emit(health, max_health)

func revive(health_ratio: float = 0.5) -> void:
	is_dead = false
	visible = true
	is_defending = false
	health = maxf(1.0, max_health * health_ratio)
	_invulnerable_left = maxf(_invulnerable_left, invulnerable_time)
	_damage_flash_left = 0.0
	_defense_flash_left = 0.0
	health_changed.emit(health, max_health)
	_play_animation(ANIM_IDLE, true)

func roll_damage(base_damage: float) -> float:
	return _roll_damage(base_damage)

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
			fan_skill_damage *= sqrt(multiplier)
		"skill_range":
			skill_length *= multiplier
			skill_half_width *= sqrt(multiplier)
			fan_skill_length *= sqrt(multiplier)
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
	_sprite.centered = true
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(Vector2.ZERO, SPRITE_FRAME_SIZE)
	_sprite.scale = Vector2(0.55, 0.55)
	_play_animation(ANIM_IDLE, true)

func _update_animation(delta: float, input_direction: Vector2) -> void:
	if _attack_anim_left > 0.0:
		if absf(_last_direction.x) > 0.01:
			_sprite.flip_h = _last_direction.x < 0.0
		_advance_animation(delta)
		return

	if input_direction.x != 0.0:
		_sprite.flip_h = input_direction.x < 0.0

	if is_defending:
		_play_animation(ANIM_GUARD)
	elif input_direction != Vector2.ZERO or _dash_time_left > 0.0:
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
	_sprite.region_rect = Rect2(Vector2(SPRITE_FRAME_SIZE.x * float(_anim_frame), 0.0), SPRITE_FRAME_SIZE)

func _get_animation_data(anim_name: String) -> Dictionary:
	match anim_name:
		ANIM_RUN:
			return {"path": _warrior_sprite_path("Warrior_Run.png"), "frames": 6, "frame_time": 0.075, "loop": true}
		ANIM_GUARD:
			return {"path": _warrior_sprite_path("Warrior_Guard.png"), "frames": 6, "frame_time": 0.095, "loop": true}
		ANIM_ATTACK_1:
			return {"path": _warrior_sprite_path("Warrior_Attack1.png"), "frames": 4, "frame_time": 0.055, "loop": false}
		ANIM_ATTACK_2:
			return {"path": _warrior_sprite_path("Warrior_Attack2.png"), "frames": 4, "frame_time": 0.055, "loop": false}
		_:
			return {"path": _warrior_sprite_path("Warrior_Idle.png"), "frames": 8, "frame_time": 0.12, "loop": true}

func _warrior_sprite_path(file_name: String) -> String:
	return UNIT_PATH_PREFIX + unit_color_folder + WARRIOR_PATH_SUFFIX + file_name

func _update_feedback() -> void:
	if _defense_flash_left > 0.0:
		_sprite.modulate = Color(0.65, 0.85, 1.0, 1.0)
	elif _invulnerable_left > 0.0:
		_sprite.modulate = Color(0.55, 0.95, 1.0, 0.85)
	elif _damage_flash_left > 0.0:
		_sprite.modulate = Color(1.0, 0.45, 0.45, 1.0)
	else:
		_sprite.modulate = player_tint

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
