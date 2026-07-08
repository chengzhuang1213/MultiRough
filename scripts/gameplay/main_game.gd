extends Node2D

const GameStateScript := preload("res://scripts/core/game_state.gd")
const UpgradeCatalogScript := preload("res://scripts/upgrades/upgrade_catalog.gd")
const PlayerScript := preload("res://scripts/player/player_controller.gd")
const EnemyScript := preload("res://scripts/enemy/enemy_controller.gd")
const ProjectileScript := preload("res://scripts/projectiles/enemy_projectile.gd")

const ARENA_BOUNDS := Rect2(Vector2(-960, -540), Vector2(1920, 1080))
const VIEWPORT_SIZE := Vector2(1280, 720)
const UPGRADE_PANEL_WIDTH := 980.0
const UPGRADE_PANEL_HEIGHT := 460.0
const NEXT_WAVE_BUTTON_WIDTH := 220.0
const NEXT_WAVE_BUTTON_HEIGHT := 44.0
const SHOW_ENEMY_ATTACK_TELEGRAPH := false
const TREE_PATHS := [
	"res://assets/tiny_swords_free_pack/Terrain/Resources/Wood/Trees/Tree1.png",
	"res://assets/tiny_swords_free_pack/Terrain/Resources/Wood/Trees/Tree2.png",
	"res://assets/tiny_swords_free_pack/Terrain/Resources/Wood/Trees/Tree3.png",
	"res://assets/tiny_swords_free_pack/Terrain/Resources/Wood/Trees/Tree4.png",
]
const ROCK_PATHS := [
	"res://assets/tiny_swords_free_pack/Terrain/Decorations/Rocks/Rock1.png",
	"res://assets/tiny_swords_free_pack/Terrain/Decorations/Rocks/Rock2.png",
	"res://assets/tiny_swords_free_pack/Terrain/Decorations/Rocks/Rock3.png",
	"res://assets/tiny_swords_free_pack/Terrain/Decorations/Rocks/Rock4.png",
]
const CORNER_PROP_PATHS := [
	"res://assets/tiny_swords_free_pack/Terrain/Resources/Wood/Trees/Stump 1.png",
	"res://assets/tiny_swords_free_pack/Terrain/Resources/Gold/Gold Stones/Gold Stone 1.png",
	"res://assets/tiny_swords_free_pack/Terrain/Decorations/Rocks/Rock2.png",
	"res://assets/tiny_swords_free_pack/Terrain/Resources/Wood/Trees/Stump 2.png",
]
const WAVE_DEFS := [
	{"minions": 4},
	{"minions": 7},
	{"minions": 10},
	{"minions": 13},
	{"minions": 16},
	{"minions": 20},
	{"minions": 24},
	{"boss": true},
]

var game_state := GameStateScript.LOBBY
var wave_index := -1
var enemies: Array[EnemyController] = []
var current_upgrades_p1: Array = []
var current_upgrades_p2: Array = []
var selected_upgrade_p1: bool = false
var selected_upgrade_p2: bool = false
var local_player_count := 1
var minion_count_multiplier := 1.0
var enemy_health_multiplier := 1.0
var enemy_damage_multiplier := 1.0
var boss_health_multiplier := 1.0
var boss_damage_multiplier := 1.0
var elapsed_time := 0.0
var enemies_defeated := 0
var damage_dealt := 0.0
var damage_taken := 0.0
var ultimate_duration_left: float = 0.0
var ultimate_angle: float = 0.0
var ultimate_damage: float = 0.0
var ultimate_hit_cooldowns: Dictionary = {}
var ultimate_owner: PlayerController

var player: PlayerController
var player_two: PlayerController
var players: Array[PlayerController] = []
var camera: Camera2D
var map_root: Node2D
var enemy_root: Node2D
var projectile_root: Node2D
var effect_root: Node2D
var ui_layer: CanvasLayer
var main_menu_panel: VBoxContainer
var hud_left: VBoxContainer
var hud_right: VBoxContainer
var status_label: Label
var health_label: Label
var health_bar: ProgressBar
var health_label_two: Label
var health_bar_two: ProgressBar
var wave_label: Label
var enemies_label: Label
var cooldown_label: Label
var cooldown_label_two: Label
var defense_label: Label
var defense_label_two: Label
var upgrade_panel: VBoxContainer
var start_next_wave_button: Button
var result_label: Label
var restart_button: Button
var ultimate_blade_root: Node2D

func _ready() -> void:
	randomize()
	_ensure_input_map()
	_build_world()
	_build_ui()
	_show_main_menu()

func _ensure_input_map() -> void:
	_add_key_action("move_left", [KEY_A])
	_add_key_action("move_right", [KEY_D])
	_add_key_action("move_up", [KEY_W])
	_add_key_action("move_down", [KEY_S])
	_add_key_action("basic_attack", [KEY_J])
	_add_mouse_action("basic_attack", MOUSE_BUTTON_LEFT)
	_add_key_action("dash", [KEY_SPACE])
	_remove_key_action("dash", [KEY_K])
	_add_key_action("active_skill", [KEY_Q])
	_add_key_action("fan_skill", [KEY_E])
	_add_key_action("ultimate_skill", [KEY_F])
	_add_key_action("defend", [KEY_K])
	_add_mouse_action("defend", MOUSE_BUTTON_RIGHT)
	_add_key_action("move_left_p2", [KEY_LEFT])
	_add_key_action("move_right_p2", [KEY_RIGHT])
	_add_key_action("move_up_p2", [KEY_UP])
	_add_key_action("move_down_p2", [KEY_DOWN])
	_add_key_action("basic_attack_p2", [KEY_ENTER, KEY_KP_ENTER])
	_ensure_input_action("dash_p2")
	_add_key_action("defend_p2", [KEY_EQUAL, KEY_KP_ADD])
	_add_key_action("active_skill_p2", [KEY_1, KEY_KP_1])
	_add_key_action("fan_skill_p2", [KEY_2, KEY_KP_2])
	_add_key_action("ultimate_skill_p2", [KEY_3, KEY_KP_3])
	_add_key_action("upgrade_p1_1", [KEY_I])
	_add_key_action("upgrade_p1_2", [KEY_O])
	_add_key_action("upgrade_p1_3", [KEY_P])
	_add_key_action("upgrade_p2_1", [KEY_7, KEY_KP_7])
	_add_key_action("upgrade_p2_2", [KEY_8, KEY_KP_8])
	_add_key_action("upgrade_p2_3", [KEY_9, KEY_KP_9])

func _add_key_action(action: StringName, keys: Array[int]) -> void:
	_ensure_input_action(action)
	for key in keys:
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = key
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)

func _ensure_input_action(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

func _remove_key_action(action: StringName, keys: Array[int]) -> void:
	if not InputMap.has_action(action):
		return
	for key in keys:
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = key
		if InputMap.action_has_event(action, event):
			InputMap.action_erase_event(action, event)

func _add_mouse_action(action: StringName, button_index: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button_index
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)

func _process(delta: float) -> void:
	if _is_combat_active():
		elapsed_time += delta
	_update_camera()
	_update_enemy_targets()
	if _is_combat_active():
		_update_ultimate(delta)
	_handle_upgrade_hotkeys()
	_update_status()
	if _is_combat_active():
		if _all_players_dead():
			_enter_defeat()

func _build_world() -> void:
	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.position = Vector2.ZERO
	camera.enabled = true
	add_child(camera)

	map_root = Node2D.new()
	map_root.name = "Map"
	map_root.z_index = -100
	add_child(map_root)
	_build_map()

	enemy_root = Node2D.new()
	enemy_root.name = "Enemies"
	add_child(enemy_root)

	projectile_root = Node2D.new()
	projectile_root.name = "Projectiles"
	add_child(projectile_root)

	effect_root = Node2D.new()
	effect_root.name = "Effects"
	add_child(effect_root)

func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UI"
	add_child(ui_layer)

	hud_left = VBoxContainer.new()
	hud_left.position = Vector2(16, 16)
	hud_left.visible = false
	hud_left.add_theme_constant_override("separation", 6)
	ui_layer.add_child(hud_left)

	status_label = Label.new()
	hud_left.add_child(status_label)

	wave_label = Label.new()
	hud_left.add_child(wave_label)

	enemies_label = Label.new()
	hud_left.add_child(enemies_label)

	health_label = Label.new()
	hud_left.add_child(health_label)

	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(220, 18)
	health_bar.show_percentage = false
	_style_player_health_bar(health_bar)
	hud_left.add_child(health_bar)

	cooldown_label = Label.new()
	hud_left.add_child(cooldown_label)

	defense_label = Label.new()
	hud_left.add_child(defense_label)

	hud_right = VBoxContainer.new()
	hud_right.position = Vector2(1030, 16)
	hud_right.visible = false
	hud_right.add_theme_constant_override("separation", 6)
	ui_layer.add_child(hud_right)

	health_label_two = Label.new()
	hud_right.add_child(health_label_two)

	health_bar_two = ProgressBar.new()
	health_bar_two.custom_minimum_size = Vector2(220, 18)
	health_bar_two.show_percentage = false
	_style_player_health_bar(health_bar_two)
	hud_right.add_child(health_bar_two)

	cooldown_label_two = Label.new()
	hud_right.add_child(cooldown_label_two)

	defense_label_two = Label.new()
	hud_right.add_child(defense_label_two)

	main_menu_panel = VBoxContainer.new()
	main_menu_panel.position = Vector2(460, 230)
	main_menu_panel.custom_minimum_size = Vector2(360, 220)
	main_menu_panel.add_theme_constant_override("separation", 16)
	ui_layer.add_child(main_menu_panel)

	var title: Label = Label.new()
	title.text = "MultiRough"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	main_menu_panel.add_child(title)

	var single_button: Button = Button.new()
	single_button.text = "单人模式"
	single_button.custom_minimum_size = Vector2(360, 54)
	single_button.pressed.connect(_start_single_player)
	main_menu_panel.add_child(single_button)

	var coop_button: Button = Button.new()
	coop_button.text = "双人同屏"
	coop_button.custom_minimum_size = Vector2(360, 54)
	coop_button.pressed.connect(_start_local_coop)
	main_menu_panel.add_child(coop_button)

	upgrade_panel = VBoxContainer.new()
	upgrade_panel.position = (VIEWPORT_SIZE - Vector2(UPGRADE_PANEL_WIDTH, UPGRADE_PANEL_HEIGHT)) * 0.5
	upgrade_panel.custom_minimum_size = Vector2(UPGRADE_PANEL_WIDTH, UPGRADE_PANEL_HEIGHT)
	upgrade_panel.visible = false
	upgrade_panel.add_theme_constant_override("separation", 18)
	ui_layer.add_child(upgrade_panel)

	start_next_wave_button = Button.new()
	start_next_wave_button.text = "开启下一波"
	start_next_wave_button.position = Vector2(
		(VIEWPORT_SIZE.x - NEXT_WAVE_BUTTON_WIDTH) * 0.5,
		VIEWPORT_SIZE.y - 92.0
	)
	start_next_wave_button.custom_minimum_size = Vector2(NEXT_WAVE_BUTTON_WIDTH, NEXT_WAVE_BUTTON_HEIGHT)
	start_next_wave_button.visible = false
	start_next_wave_button.disabled = true
	start_next_wave_button.pressed.connect(_on_start_next_wave_pressed)
	ui_layer.add_child(start_next_wave_button)

	result_label = Label.new()
	result_label.position = Vector2(520, 248)
	result_label.visible = false
	result_label.add_theme_font_size_override("font_size", 28)
	ui_layer.add_child(result_label)

	restart_button = Button.new()
	restart_button.text = "重新开始"
	restart_button.position = Vector2(548, 510)
	restart_button.custom_minimum_size = Vector2(184, 48)
	restart_button.visible = false
	restart_button.pressed.connect(_on_restart_pressed)
	ui_layer.add_child(restart_button)

	_update_status()

func _style_player_health_bar(target_bar: ProgressBar) -> void:
	var lost_health_style: StyleBoxFlat = StyleBoxFlat.new()
	lost_health_style.bg_color = Color(0.72, 0.08, 0.07, 0.92)
	lost_health_style.set_corner_radius_all(2)
	target_bar.add_theme_stylebox_override("background", lost_health_style)

	var current_health_style: StyleBoxFlat = StyleBoxFlat.new()
	current_health_style.bg_color = Color(0.24, 1.0, 0.20, 1.0)
	current_health_style.set_corner_radius_all(2)
	target_bar.add_theme_stylebox_override("fill", current_health_style)

func _show_main_menu() -> void:
	game_state = GameStateScript.LOBBY
	if main_menu_panel != null:
		main_menu_panel.visible = true
	if hud_left != null:
		hud_left.visible = false
	if hud_right != null:
		hud_right.visible = false
	_update_status()

func _start_single_player() -> void:
	_start_game(1)

func _start_local_coop() -> void:
	_start_game(2)

func _start_game(player_count: int) -> void:
	local_player_count = player_count
	minion_count_multiplier = 2.0 if local_player_count > 1 else 1.0
	enemy_health_multiplier = 1.15 if local_player_count > 1 else 1.0
	enemy_damage_multiplier = 1.08 if local_player_count > 1 else 1.0
	boss_health_multiplier = 2.0 if local_player_count > 1 else 1.0
	boss_damage_multiplier = 1.12 if local_player_count > 1 else 1.0
	wave_index = -1
	elapsed_time = 0.0
	enemies_defeated = 0
	damage_dealt = 0.0
	damage_taken = 0.0
	selected_upgrade_p1 = false
	selected_upgrade_p2 = false
	current_upgrades_p1.clear()
	current_upgrades_p2.clear()
	if main_menu_panel != null:
		main_menu_panel.visible = false
	hud_left.visible = true
	hud_right.visible = local_player_count > 1
	_spawn_players(local_player_count)
	_start_next_wave()

func _spawn_players(player_count: int) -> void:
	player = _create_player("Player1", Vector2(-42.0, 0.0), Color.WHITE, true, "Blue Units")
	players = [player]
	if player_count > 1:
		player_two = _create_player("Player2", Vector2(42.0, 0.0), Color.WHITE, false, "Red Units")
		player_two.move_left_action = "move_left_p2"
		player_two.move_right_action = "move_right_p2"
		player_two.move_up_action = "move_up_p2"
		player_two.move_down_action = "move_down_p2"
		player_two.basic_attack_action = "basic_attack_p2"
		player_two.dash_action = "dash_p2"
		player_two.defend_action = "defend_p2"
		player_two.active_skill_action = "active_skill_p2"
		player_two.fan_skill_action = "fan_skill_p2"
		player_two.ultimate_skill_action = "ultimate_skill_p2"
		players.append(player_two)
	_setup_ultimate_blades()

func _create_player(player_name: String, spawn_position: Vector2, tint: Color, mouse_aim: bool, unit_folder: String) -> PlayerController:
	var new_player: PlayerController = PlayerScript.new()
	new_player.name = player_name
	new_player.global_position = spawn_position
	new_player.arena_bounds = ARENA_BOUNDS
	new_player.player_tint = tint
	new_player.use_mouse_aim = mouse_aim
	new_player.unit_color_folder = unit_folder
	new_player.basic_attack_requested.connect(_on_player_basic_attack.bind(new_player))
	new_player.active_skill_requested.connect(_on_player_active_skill.bind(new_player))
	new_player.fan_skill_requested.connect(_on_player_fan_skill.bind(new_player))
	new_player.ultimate_skill_requested.connect(_on_player_ultimate_skill.bind(new_player))
	new_player.health_changed.connect(_on_player_health_changed.bind(new_player))
	new_player.damage_taken.connect(_on_player_damage_taken.bind(new_player))
	new_player.died.connect(_on_player_died)
	add_child(new_player)
	return new_player

func _setup_ultimate_blades() -> void:
	ultimate_blade_root = Node2D.new()
	ultimate_blade_root.name = "UltimateBlades"
	ultimate_blade_root.visible = false
	add_child(ultimate_blade_root)
	for index in range(2):
		var blade: Line2D = Line2D.new()
		blade.name = "Blade%d" % index
		blade.width = 5.0
		blade.default_color = Color(0.65, 0.9, 1.0, 0.82)
		blade.points = PackedVector2Array([
			Vector2(-42.0, 0.0),
			Vector2(42.0, 0.0),
		])
		ultimate_blade_root.add_child(blade)

func _start_next_wave() -> void:
	_set_player_cooldowns_paused(false)
	wave_index += 1
	_clear_upgrade_panel()
	_clear_projectiles()
	upgrade_panel.visible = false
	start_next_wave_button.visible = false
	start_next_wave_button.disabled = true
	selected_upgrade_p1 = false
	selected_upgrade_p2 = false

	if wave_index >= WAVE_DEFS.size():
		_enter_victory()
		return

	_revive_dead_players_for_next_wave()

	var wave_def: Dictionary = WAVE_DEFS[wave_index]
	if wave_def.get("boss", false):
		game_state = GameStateScript.BOSS_WAVE
		_spawn_boss()
	else:
		game_state = GameStateScript.WAVE_ACTIVE
		_spawn_minions(roundi(float(wave_def["minions"]) * minion_count_multiplier))

	_update_status()

func _spawn_minions(count: int) -> void:
	for index in range(count):
		var enemy: EnemyController = EnemyScript.new()
		_setup_wave_enemy(enemy, index, count)
		enemy.global_position = _spawn_point(index, count)
		_register_enemy(enemy)

func _setup_wave_enemy(enemy: EnemyController, index: int, count: int) -> void:
	var wave_number: int = wave_index + 1
	if wave_number >= 4 and index % 7 == 3:
		enemy.setup_as_heavy(wave_number)
	elif wave_number >= 3 and index % 5 == 2:
		enemy.setup_as_ranged(wave_number)
	elif wave_number >= 5 and index == count - 1 and wave_number % 2 == 1:
		enemy.setup_as_elite(wave_number)
	else:
		enemy.setup_as_minion(wave_number)
	_tune_enemy_for_mode(enemy)

func _spawn_boss() -> void:
	var boss: EnemyController = EnemyScript.new()
	boss.setup_as_boss()
	_tune_boss_for_mode(boss)
	boss.global_position = Vector2(0, -180)
	_register_enemy(boss)
	_spawn_effect(boss.global_position, 120.0, Color(1.0, 0.18, 0.12, 0.20), 0.65)

func _tune_enemy_for_mode(enemy: EnemyController) -> void:
	enemy.max_health *= enemy_health_multiplier
	enemy.health = enemy.max_health
	enemy.attack_damage *= enemy_damage_multiplier
	enemy.projectile_damage *= enemy_damage_multiplier
	enemy.attack_interval *= 0.96 if local_player_count > 1 else 1.0

func _tune_boss_for_mode(boss: EnemyController) -> void:
	boss.max_health *= boss_health_multiplier
	boss.health = boss.max_health
	boss.attack_damage *= boss_damage_multiplier
	boss.move_speed *= 1.06 if local_player_count > 1 else 1.0
	boss.attack_interval *= 0.92 if local_player_count > 1 else 1.0

func _register_enemy(enemy: EnemyController) -> void:
	enemy.arena_bounds = ARENA_BOUNDS
	enemy.set_target(_find_closest_alive_player(enemy.global_position))
	enemy.died.connect(_on_enemy_died)
	enemy.damaged.connect(_on_enemy_damaged)
	enemy.attack_started.connect(_on_enemy_attack_started)
	enemy.attacked_player.connect(_on_enemy_attacked_player)
	enemy.projectile_requested.connect(_on_enemy_projectile_requested)
	enemy.area_attack_requested.connect(_on_enemy_area_attack_requested)
	enemies.append(enemy)
	enemy_root.add_child(enemy)

func _spawn_point(index: int, count: int) -> Vector2:
	var side: int = index % 4
	var lane_index: int = floori(float(index) / 4.0)
	var lane_center: int = floori(float(count) / 8.0)
	var lane_offset: float = float(lane_index - lane_center) * 120.0
	var margin: float = 44.0

	match side:
		0:
			return Vector2(clampf(lane_offset, -520.0, 520.0), ARENA_BOUNDS.position.y + margin)
		1:
			return Vector2(ARENA_BOUNDS.end.x - margin, clampf(lane_offset, -300.0, 300.0))
		2:
			return Vector2(clampf(lane_offset, -520.0, 520.0), ARENA_BOUNDS.end.y - margin)
		_:
			return Vector2(ARENA_BOUNDS.position.x + margin, clampf(lane_offset, -300.0, 300.0))

func _build_map() -> void:
	_build_ground_tiles()
	_build_soft_obstacles()
	_build_boundary_props()
	_build_corner_props()

func _build_ground_tiles() -> void:
	var background: ColorRect = ColorRect.new()
	background.name = "GrassBase"
	background.position = ARENA_BOUNDS.position
	background.size = ARENA_BOUNDS.size
	background.color = Color(0.31, 0.52, 0.31)
	background.z_index = -100
	map_root.add_child(background)

func _build_soft_obstacles() -> void:
	var positions: Array[Vector2] = [
		Vector2(-360.0, -150.0),
		Vector2(320.0, -120.0),
		Vector2(-220.0, 190.0),
		Vector2(430.0, 210.0),
		Vector2(40.0, -260.0),
	]
	for index in range(positions.size()):
		var path: String = ROCK_PATHS[index % ROCK_PATHS.size()]
		var prop: Sprite2D = _make_sprite(path, Vector2(64, 64), positions[index], Vector2(0.65, 0.65))
		prop.name = "SoftObstacle"
		prop.z_index = -35
		map_root.add_child(prop)

func _build_boundary_props() -> void:
	var gap_width: float = 420.0
	var step: float = 300.0
	var top_y: float = ARENA_BOUNDS.position.y - 48.0
	var bottom_y: float = ARENA_BOUNDS.end.y + 44.0
	var left_x: float = ARENA_BOUNDS.position.x - 44.0
	var right_x: float = ARENA_BOUNDS.end.x + 44.0

	for x in range(int(ARENA_BOUNDS.position.x), int(ARENA_BOUNDS.end.x) + 1, int(step)):
		if abs(float(x)) > gap_width * 0.5:
			_add_boundary_prop(Vector2(float(x), top_y), x)
			_add_boundary_prop(Vector2(float(x), bottom_y), x + 13)

	for y in range(int(ARENA_BOUNDS.position.y), int(ARENA_BOUNDS.end.y) + 1, int(step)):
		if abs(float(y)) > gap_width * 0.5:
			_add_boundary_prop(Vector2(left_x, float(y)), y + 29)
			_add_boundary_prop(Vector2(right_x, float(y)), y + 47)

func _add_boundary_prop(position: Vector2, seed_value: int) -> void:
	var sprite: Sprite2D
	var selector: int = abs(seed_value) % 3
	if selector == 0:
		sprite = _make_sprite(TREE_PATHS[abs(seed_value) % TREE_PATHS.size()], Vector2(256, 256), position, Vector2(0.32, 0.32))
	else:
		sprite = _make_sprite(ROCK_PATHS[abs(seed_value) % ROCK_PATHS.size()], Vector2(64, 64), position, Vector2(0.55, 0.55))
	sprite.name = "BoundaryProp"
	sprite.z_index = -40
	map_root.add_child(sprite)

func _build_corner_props() -> void:
	var corner_positions: Array[Vector2] = [
		Vector2(ARENA_BOUNDS.position.x + 130.0, ARENA_BOUNDS.position.y + 110.0),
		Vector2(ARENA_BOUNDS.end.x - 140.0, ARENA_BOUNDS.position.y + 120.0),
		Vector2(ARENA_BOUNDS.position.x + 150.0, ARENA_BOUNDS.end.y - 120.0),
		Vector2(ARENA_BOUNDS.end.x - 130.0, ARENA_BOUNDS.end.y - 110.0),
	]
	for index in range(corner_positions.size()):
		var prop_path: String = CORNER_PROP_PATHS[index % CORNER_PROP_PATHS.size()]
		var frame_size: Vector2 = Vector2(192, 256) if prop_path.contains("Stump") else Vector2(64, 64)
		var prop: Sprite2D = _make_sprite(prop_path, frame_size, corner_positions[index], Vector2(0.45, 0.45))
		prop.name = "CornerProp"
		prop.z_index = -30
		map_root.add_child(prop)

func _make_sprite(path: String, frame_size: Vector2, position: Vector2, sprite_scale: Vector2) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = load(path) as Texture2D
	sprite.centered = true
	sprite.position = position
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO, frame_size)
	sprite.scale = sprite_scale
	return sprite

func _update_camera() -> void:
	if camera == null or players.is_empty():
		return
	var focus: Vector2 = _get_alive_players_center()
	var half_view: Vector2 = VIEWPORT_SIZE * 0.5
	var min_position: Vector2 = ARENA_BOUNDS.position + half_view
	var max_position: Vector2 = ARENA_BOUNDS.end - half_view
	camera.global_position = focus.clamp(min_position, max_position)

func _get_alive_players_center() -> Vector2:
	var total: Vector2 = Vector2.ZERO
	var count: int = 0
	for existing_player in players:
		if is_instance_valid(existing_player) and not existing_player.is_dead:
			total += existing_player.global_position
			count += 1
	if count <= 0 and player != null:
		return player.global_position
	return total / maxf(1.0, float(count))

func _update_enemy_targets() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.set_target(_find_closest_alive_player(enemy.global_position))

func _find_closest_alive_player(origin: Vector2) -> PlayerController:
	var closest: PlayerController = null
	var closest_distance_squared: float = INF
	for existing_player in players:
		if not is_instance_valid(existing_player) or existing_player.is_dead:
			continue
		var distance_squared: float = origin.distance_squared_to(existing_player.global_position)
		if distance_squared < closest_distance_squared:
			closest = existing_player
			closest_distance_squared = distance_squared
	return closest

func _all_players_dead() -> bool:
	for existing_player in players:
		if is_instance_valid(existing_player) and not existing_player.is_dead:
			return false
	return true

func _is_combat_active() -> bool:
	return game_state == GameStateScript.WAVE_ACTIVE or game_state == GameStateScript.BOSS_WAVE

func _set_player_cooldowns_paused(paused: bool) -> void:
	for existing_player in players:
		if is_instance_valid(existing_player):
			existing_player.cooldowns_paused = paused

func _on_enemy_died(enemy: EnemyController) -> void:
	enemies_defeated += 1
	if is_instance_valid(enemy):
		_spawn_effect(enemy.global_position, 36.0, Color(1.0, 0.35, 0.25, 0.32), 0.16)
	enemies.erase(enemy)
	var alive_enemies: Array[EnemyController] = []
	for existing_enemy in enemies:
		if is_instance_valid(existing_enemy):
			alive_enemies.append(existing_enemy)
	enemies = alive_enemies
	_update_status()
	if enemies.is_empty():
		if game_state == GameStateScript.BOSS_WAVE:
			_enter_victory()
		else:
			_enter_wave_clear()

func _enter_wave_clear() -> void:
	game_state = GameStateScript.COUNTDOWN
	_set_player_cooldowns_paused(true)
	result_label.text = "波次清理完成"
	result_label.visible = true
	var timer: SceneTreeTimer = get_tree().create_timer(1.0)
	timer.timeout.connect(func() -> void:
		if game_state == GameStateScript.COUNTDOWN and enemies.is_empty():
			result_label.visible = false
			_enter_upgrade_select()
	)

func _on_enemy_attack_started(enemy: EnemyController, windup_time: float, attack_range: float) -> void:
	if SHOW_ENEMY_ATTACK_TELEGRAPH and is_instance_valid(enemy):
		_spawn_effect(enemy.global_position, attack_range, Color(1.0, 0.84, 0.25, 0.16), windup_time)

func _on_enemy_attacked_player(enemy: EnemyController, target: Node2D, damage: float) -> void:
	var target_player: PlayerController = target as PlayerController
	if target_player == null or target_player.is_dead:
		return
	var defended: bool = target_player.apply_damage(damage)
	if defended and is_instance_valid(enemy):
		enemy.apply_defense_repel(target_player.global_position, 190.0)
		_spawn_effect(enemy.global_position, 28.0, Color(0.35, 0.72, 1.0, 0.28), 0.10)

func _on_enemy_projectile_requested(_enemy: EnemyController, target: Node2D, origin: Vector2, direction: Vector2, damage: float) -> void:
	var projectile: EnemyProjectile = ProjectileScript.new()
	projectile.global_position = origin
	projectile.direction = direction
	projectile.damage = damage
	projectile.target = player
	if target != null and is_instance_valid(target):
		projectile.target = target
	projectile.hit_player.connect(_on_enemy_projectile_hit_player.bind(projectile.target))
	projectile_root.add_child(projectile)

func _on_enemy_projectile_hit_player(damage: float, target: Node2D) -> void:
	var target_player: PlayerController = target as PlayerController
	if target_player != null:
		target_player.apply_damage(damage)

func _on_enemy_area_attack_requested(_enemy: EnemyController, origin: Vector2, radius: float, damage: float, windup_time: float) -> void:
	if SHOW_ENEMY_ATTACK_TELEGRAPH:
		_spawn_effect(origin, radius, Color(1.0, 0.28, 0.18, 0.18), windup_time)
	var timer: SceneTreeTimer = get_tree().create_timer(windup_time)
	timer.timeout.connect(func() -> void:
		for existing_player in players:
			if is_instance_valid(existing_player) and not existing_player.is_dead and existing_player.global_position.distance_to(origin) <= radius:
				existing_player.apply_damage(damage)
				_spawn_effect(existing_player.global_position, 34.0, Color(1.0, 0.25, 0.22, 0.24), 0.10)
	)

func _on_enemy_damaged(enemy: EnemyController, amount: float) -> void:
	if is_instance_valid(enemy):
		damage_dealt += amount
		_spawn_effect(enemy.global_position, 22.0, Color(1.0, 0.95, 0.55, 0.24), 0.06)
		_spawn_damage_number(enemy.global_position + Vector2(-10.0, -34.0), amount, Color(1.0, 0.92, 0.42, 1.0))

func _on_player_damage_taken(amount: float, defended: bool, damaged_player: PlayerController) -> void:
	damage_taken += amount
	var color: Color = Color(0.35, 0.72, 1.0, 0.28) if defended else Color(1.0, 0.25, 0.22, 0.24)
	var radius: float = 42.0 if defended else 34.0
	_spawn_effect(damaged_player.global_position, radius, color, 0.10)
	_spawn_damage_number(damaged_player.global_position + Vector2(-12.0, -46.0), amount, color)

func _on_player_basic_attack(origin: Vector2, direction: Vector2, attack_length: float, half_width: float, damage: float, attacker: PlayerController) -> void:
	_damage_enemies_in_front(origin, direction, attack_length, half_width, damage, -1.0, attacker)

func _on_player_active_skill(origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float, attacker: PlayerController) -> void:
	_damage_enemies_in_front(origin, direction, length, half_width, damage, attacker.attack_knockback * 0.75, attacker)
	_spawn_shockwave_effect(origin, direction, length)

func _on_player_fan_skill(origin: Vector2, direction: Vector2, length: float, half_width: float, damage: float, attacker: PlayerController) -> void:
	var forward: Vector2 = direction.normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.RIGHT
	var angles: Array[float] = [-0.32, 0.0, 0.32]
	for angle in angles:
		var line_direction: Vector2 = forward.rotated(angle)
		_damage_enemies_in_front(origin, line_direction, length, half_width, damage, attacker.attack_knockback * 0.45, attacker)
		_spawn_line_skill_effect(origin, line_direction, length)

func _on_player_ultimate_skill(damage: float, duration: float, attacker: PlayerController) -> void:
	ultimate_duration_left = duration
	ultimate_angle = 0.0
	ultimate_damage = damage
	ultimate_owner = attacker
	ultimate_hit_cooldowns.clear()
	if ultimate_blade_root != null:
		ultimate_blade_root.visible = true

func _update_ultimate(delta: float) -> void:
	if ultimate_duration_left <= 0.0 or ultimate_owner == null or not is_instance_valid(ultimate_owner) or ultimate_owner.is_dead:
		if ultimate_blade_root != null:
			ultimate_blade_root.visible = false
		return

	ultimate_duration_left = maxf(0.0, ultimate_duration_left - delta)
	ultimate_angle += 7.2 * delta
	_update_ultimate_hit_cooldowns(delta)
	_update_ultimate_blade_visuals()
	_damage_enemies_with_ultimate()
	if ultimate_duration_left <= 0.0 and ultimate_blade_root != null:
		ultimate_blade_root.visible = false

func _update_ultimate_hit_cooldowns(delta: float) -> void:
	for key in ultimate_hit_cooldowns.keys():
		ultimate_hit_cooldowns[key] = maxf(0.0, float(ultimate_hit_cooldowns[key]) - delta)

func _update_ultimate_blade_visuals() -> void:
	if ultimate_blade_root == null:
		return
	if ultimate_owner == null or not is_instance_valid(ultimate_owner):
		return
	ultimate_blade_root.global_position = ultimate_owner.global_position
	for index in range(ultimate_blade_root.get_child_count()):
		var blade: Line2D = ultimate_blade_root.get_child(index) as Line2D
		var angle: float = ultimate_angle + PI * float(index)
		var center: Vector2 = Vector2(cos(angle), sin(angle)) * 62.0
		var tangent: Vector2 = Vector2(-sin(angle), cos(angle))
		blade.position = center
		blade.points = PackedVector2Array([
			-tangent * 42.0,
			tangent * 42.0,
		])

func _damage_enemies_with_ultimate() -> void:
	var hit_width: float = 18.0
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		var enemy_id: int = enemy.get_instance_id()
		if float(ultimate_hit_cooldowns.get(enemy_id, 0.0)) > 0.0:
			continue
		if _enemy_touched_by_ultimate_blade(enemy.global_position, hit_width):
			var hit_damage: float = ultimate_owner.roll_damage(ultimate_damage)
			enemy.apply_damage(hit_damage, ultimate_owner.global_position, ultimate_owner.attack_knockback * 0.35)
			_apply_lifesteal(ultimate_owner, hit_damage)
			ultimate_hit_cooldowns[enemy_id] = 0.35

func _enemy_touched_by_ultimate_blade(enemy_position: Vector2, hit_width: float) -> bool:
	if ultimate_blade_root == null:
		return false
	for index in range(ultimate_blade_root.get_child_count()):
		var blade: Line2D = ultimate_blade_root.get_child(index) as Line2D
		if blade == null or blade.points.size() < 2:
			continue
		var start: Vector2 = ultimate_blade_root.global_position + blade.position + blade.points[0]
		var end: Vector2 = ultimate_blade_root.global_position + blade.position + blade.points[1]
		if _distance_to_segment(enemy_position, start, end) <= hit_width:
			return true
	return false

func _distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment: Vector2 = end - start
	var length_squared: float = segment.length_squared()
	if length_squared <= 0.001:
		return point.distance_to(start)
	var t: float = clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	var closest: Vector2 = start + segment * t
	return point.distance_to(closest)

func _damage_enemies_in_radius(origin: Vector2, radius: float, damage: float, attacker: PlayerController) -> void:
	for enemy in enemies.duplicate():
		if is_instance_valid(enemy) and enemy.global_position.distance_to(origin) <= radius:
			var knockback: float = 150.0 if radius <= attacker.attack_range + 1.0 else 95.0
			enemy.apply_damage(damage, origin, knockback)
			_apply_lifesteal(attacker, damage)

func _damage_enemies_in_front(origin: Vector2, direction: Vector2, attack_length: float, half_width: float, damage: float, knockback: float = -1.0, attacker: PlayerController = null) -> void:
	var source_player: PlayerController = player if attacker == null else attacker
	var forward: Vector2 = direction.normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.RIGHT
	var hit_knockback: float = source_player.attack_knockback if knockback < 0.0 else knockback
	var side_axis: Vector2 = Vector2(-forward.y, forward.x)
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		var to_enemy: Vector2 = enemy.global_position - origin
		var forward_distance: float = to_enemy.dot(forward)
		var side_distance: float = absf(to_enemy.dot(side_axis))
		if forward_distance >= 0.0 and forward_distance <= attack_length and side_distance <= half_width:
			enemy.apply_damage(damage, origin, hit_knockback)
			_apply_lifesteal(source_player, damage)

func _apply_lifesteal(attacker: PlayerController, amount: float) -> void:
	if attacker != null and attacker.lifesteal_ratio > 0.0:
		attacker.heal(amount * attacker.lifesteal_ratio)

func _spawn_effect(origin: Vector2, radius: float, color: Color, lifetime: float = 0.08) -> void:
	var effect: Polygon2D = Polygon2D.new()
	var points: PackedVector2Array = []
	var segments: int = 28
	for index in range(segments):
		var angle: float = TAU * float(index) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	effect.polygon = points
	effect.position = origin
	effect.color = color
	effect_root.add_child(effect)

	var timer: SceneTreeTimer = get_tree().create_timer(lifetime)
	timer.timeout.connect(Callable(effect, "queue_free"))

func _spawn_shockwave_effect(origin: Vector2, direction: Vector2, length: float) -> void:
	var forward: Vector2 = direction.normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.RIGHT
	for index in range(4):
		var t: float = float(index + 1) / 4.0
		_spawn_effect(origin + forward * length * t, 18.0 + 8.0 * t, Color(0.35, 0.75, 1.0, 0.18), 0.12)

func _spawn_line_skill_effect(origin: Vector2, direction: Vector2, length: float) -> void:
	var forward: Vector2 = direction.normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.RIGHT
	var line: Line2D = Line2D.new()
	line.position = origin
	line.width = 4.0
	line.default_color = Color(1.0, 0.86, 0.32, 0.55)
	line.points = PackedVector2Array([
		Vector2.ZERO,
		forward * length,
	])
	effect_root.add_child(line)

	var timer: SceneTreeTimer = get_tree().create_timer(0.09)
	timer.timeout.connect(Callable(line, "queue_free"))

func _spawn_damage_number(origin: Vector2, amount: float, color: Color) -> void:
	var label: Label = Label.new()
	label.text = "%d" % roundi(amount)
	label.position = origin
	label.modulate = color
	label.add_theme_font_size_override("font_size", 18)
	effect_root.add_child(label)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", origin + Vector2(0.0, -26.0), 0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)
	tween.finished.connect(Callable(label, "queue_free"))

func _enter_upgrade_select() -> void:
	game_state = GameStateScript.UPGRADE_SELECT
	_set_player_cooldowns_paused(true)
	current_upgrades_p1 = UpgradeCatalogScript.roll(3)
	current_upgrades_p2 = UpgradeCatalogScript.roll(3)
	selected_upgrade_p1 = false
	selected_upgrade_p2 = local_player_count <= 1
	_clear_upgrade_panel()
	start_next_wave_button.visible = false
	start_next_wave_button.disabled = true
	if local_player_count <= 1:
		_build_single_player_upgrade_panel()
	else:
		_build_coop_upgrade_panel()

	upgrade_panel.visible = true
	_update_status()

func _build_single_player_upgrade_panel() -> void:
	var panel_width: float = 1180.0
	var panel_height: float = 540.0
	var card_width: float = 340.0
	var card_height: float = 420.0
	_configure_upgrade_panel(panel_width, panel_height)
	var title: Label = Label.new()
	title.text = "选择升级"
	title.custom_minimum_size = Vector2(panel_width, 0.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	upgrade_panel.add_child(title)

	var cards: HBoxContainer = HBoxContainer.new()
	cards.custom_minimum_size = Vector2(panel_width, card_height)
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 54)
	upgrade_panel.add_child(cards)

	var key_labels: Array[String] = ["I", "O", "P"]
	for index in range(current_upgrades_p1.size()):
		var upgrade: Dictionary = current_upgrades_p1[index]
		var key_label: String = key_labels[index]
		var button: Button = Button.new()
		button.text = "%s  [%s] %s" % [
			key_label,
			_format_rarity(str(upgrade.get("rarity", "Common"))),
			_format_upgrade_button(upgrade, player),
		]
		button.custom_minimum_size = Vector2(card_width, card_height)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(_select_upgrade.bind(1, upgrade))
		cards.add_child(button)

func _build_coop_upgrade_panel() -> void:
	_configure_upgrade_panel(UPGRADE_PANEL_WIDTH, UPGRADE_PANEL_HEIGHT)
	var title: Label = Label.new()
	title.text = "选择升级"
	title.custom_minimum_size = Vector2(UPGRADE_PANEL_WIDTH, 0.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	upgrade_panel.add_child(title)

	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 32)
	upgrade_panel.add_child(columns)

	columns.add_child(_build_upgrade_column("P1 选择：I / O / P", current_upgrades_p1, player, 1, ["I", "O", "P"]))
	if player_two != null:
		columns.add_child(_build_upgrade_column("P2 选择：7 / 8 / 9", current_upgrades_p2, player_two, 2, ["7", "8", "9"]))

func _configure_upgrade_panel(width: float, height: float) -> void:
	upgrade_panel.position = (VIEWPORT_SIZE - Vector2(width, height)) * 0.5
	upgrade_panel.custom_minimum_size = Vector2(width, height)

func _revive_dead_players_for_next_wave() -> void:
	var revive_position: Vector2 = _get_alive_players_center()
	for existing_player in players:
		if is_instance_valid(existing_player) and existing_player.is_dead:
			existing_player.global_position = revive_position + Vector2(randf_range(-42.0, 42.0), randf_range(-28.0, 28.0))
			existing_player.global_position = existing_player.global_position.clamp(ARENA_BOUNDS.position, ARENA_BOUNDS.end)
			existing_player.revive(0.5)

func _build_upgrade_column(title_text: String, upgrades: Array, target_player: PlayerController, player_index: int, key_labels: Array[String]) -> VBoxContainer:
	var column: VBoxContainer = VBoxContainer.new()
	column.custom_minimum_size = Vector2(460, 0.0)
	column.add_theme_constant_override("separation", 12)
	column.name = "UpgradeColumnP%d" % player_index

	var column_title: Label = Label.new()
	column_title.text = title_text
	column_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column_title.add_theme_font_size_override("font_size", 18)
	column.add_child(column_title)

	for index in range(upgrades.size()):
		var upgrade: Dictionary = upgrades[index]
		var button: Button = Button.new()
		button.text = "%s  [%s] %s" % [
			key_labels[index],
			_format_rarity(str(upgrade.get("rarity", "Common"))),
			_format_upgrade_button(upgrade, target_player),
		]
		button.custom_minimum_size = Vector2(460, 104)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(_select_upgrade.bind(player_index, upgrade))
		column.add_child(button)
	return column

func _select_upgrade(player_index: int, upgrade: Dictionary) -> void:
	if player_index == 1 and selected_upgrade_p1:
		return
	if player_index == 2 and selected_upgrade_p2:
		return
	var target_player: PlayerController = player if player_index == 1 else player_two
	if target_player == null or not is_instance_valid(target_player):
		return
	target_player.apply_upgrade(upgrade)
	if player_index == 1:
		selected_upgrade_p1 = true
	else:
		selected_upgrade_p2 = true
	_mark_upgrade_column_selected(player_index)
	if not _all_required_upgrades_selected():
		return
	upgrade_panel.visible = false
	start_next_wave_button.visible = true
	start_next_wave_button.disabled = false
	start_next_wave_button.grab_focus()

func _mark_upgrade_column_selected(player_index: int) -> void:
	var column: VBoxContainer = upgrade_panel.find_child("UpgradeColumnP%d" % player_index, true, false) as VBoxContainer
	if column == null:
		return
	for child in column.get_children():
		var item: CanvasItem = child as CanvasItem
		if item != null:
			item.visible = false
		child.queue_free()
	var selected_label: Label = Label.new()
	selected_label.text = "P%d 已选择" % player_index
	selected_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selected_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	selected_label.custom_minimum_size = Vector2(460, 340)
	selected_label.add_theme_font_size_override("font_size", 24)
	column.add_child(selected_label)

func _all_required_upgrades_selected() -> bool:
	return selected_upgrade_p1 and (selected_upgrade_p2 or local_player_count <= 1)

func _handle_upgrade_hotkeys() -> void:
	if game_state != GameStateScript.UPGRADE_SELECT:
		return
	if not selected_upgrade_p1:
		for index in range(current_upgrades_p1.size()):
			if Input.is_action_just_pressed("upgrade_p1_%d" % (index + 1)):
				var upgrade_p1: Dictionary = current_upgrades_p1[index]
				_select_upgrade(1, upgrade_p1)
				return
	if local_player_count > 1 and not selected_upgrade_p2:
		for index in range(current_upgrades_p2.size()):
			if Input.is_action_just_pressed("upgrade_p2_%d" % (index + 1)):
				var upgrade_p2: Dictionary = current_upgrades_p2[index]
				_select_upgrade(2, upgrade_p2)
				return

func _on_start_next_wave_pressed() -> void:
	if game_state != GameStateScript.UPGRADE_SELECT or not _all_required_upgrades_selected():
		return
	_start_next_wave()

func _enter_victory() -> void:
	game_state = GameStateScript.VICTORY
	_clear_remaining_enemies()
	_position_result_panel()
	result_label.text = _format_result_text("胜利")
	result_label.visible = true
	restart_button.visible = true
	_update_status()

func _enter_defeat() -> void:
	if game_state == GameStateScript.DEFEAT or game_state == GameStateScript.VICTORY:
		return
	game_state = GameStateScript.DEFEAT
	_position_result_panel()
	result_label.text = _format_result_text("失败")
	result_label.visible = true
	restart_button.visible = true
	_update_status()

func _on_restart_pressed() -> void:
	_clear_run_state()
	result_label.visible = false
	restart_button.visible = false
	_show_main_menu()

func _position_result_panel() -> void:
	result_label.position = Vector2(520, 248)
	restart_button.position = Vector2(548, 510)

func _format_result_text(title: String) -> String:
	return "%s\n用时：%.1f 秒\n击杀：%d\n造成伤害：%d\n受到伤害：%d" % [
		title,
		elapsed_time,
		enemies_defeated,
		roundi(damage_dealt),
		roundi(damage_taken),
	]

func _clear_remaining_enemies() -> void:
	for enemy in enemies.duplicate():
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()
	_clear_projectiles()
	_stop_ultimate()

func _clear_run_state() -> void:
	_clear_remaining_enemies()
	_clear_upgrade_panel()
	for existing_player in players:
		if is_instance_valid(existing_player):
			existing_player.queue_free()
	players.clear()
	player = null
	player_two = null
	wave_index = -1
	selected_upgrade_p1 = false
	selected_upgrade_p2 = false
	current_upgrades_p1.clear()
	current_upgrades_p2.clear()
	start_next_wave_button.visible = false
	start_next_wave_button.disabled = true
	upgrade_panel.visible = false
	if ultimate_blade_root != null:
		ultimate_blade_root.queue_free()
		ultimate_blade_root = null

func _stop_ultimate() -> void:
	ultimate_duration_left = 0.0
	ultimate_owner = null
	ultimate_hit_cooldowns.clear()
	if ultimate_blade_root != null:
		ultimate_blade_root.visible = false

func _clear_projectiles() -> void:
	if projectile_root == null:
		return
	for projectile in projectile_root.get_children():
		projectile.queue_free()

func _clear_upgrade_panel() -> void:
	for child in upgrade_panel.get_children():
		child.queue_free()

func _on_player_health_changed(current: float, maximum: float, changed_player: PlayerController) -> void:
	if changed_player == player and health_bar != null:
		health_bar.max_value = maximum
		health_bar.value = current
	elif changed_player == player_two and health_bar_two != null:
		health_bar_two.max_value = maximum
		health_bar_two.value = current
	_update_player_health_labels()

func _update_player_health_labels() -> void:
	if player != null:
		health_label.text = "P1 生命：%d / %d" % [roundi(player.health), roundi(player.max_health)]
	if player_two != null and local_player_count > 1:
		health_label_two.text = "P2 生命：%d / %d" % [roundi(player_two.health), roundi(player_two.max_health)]
	elif health_label_two != null:
		health_label_two.text = ""

func _on_player_died() -> void:
	if game_state == GameStateScript.WAVE_ACTIVE or game_state == GameStateScript.BOSS_WAVE:
		if _all_players_dead():
			_enter_defeat()

func _update_status() -> void:
	status_label.text = "状态：%s" % _format_game_state(game_state)
	wave_label.text = "波次：%d / %d" % [
		clampi(wave_index + 1, 1, WAVE_DEFS.size()),
		WAVE_DEFS.size(),
	]
	enemies_label.text = "剩余敌人：%d" % enemies.size()
	if player != null:
		_update_player_health_labels()
		cooldown_label.text = "普攻：%s   闪避：%s (%d/%d)   Q：%s   E：%s   F：%s" % [
			"就绪" if player.get_attack_ready() else "%.1f秒" % player.get_attack_remaining(),
			"就绪" if player.get_dash_ready() else "%.1f秒" % player.get_dash_remaining(),
			player.dash_charges,
			player.dash_max_charges,
			"就绪" if player.get_skill_ready() else "%.1f秒" % player.get_skill_remaining(),
			"就绪" if player.get_fan_skill_ready() else "%.1f秒" % player.get_fan_skill_remaining(),
			"就绪" if player.get_ultimate_ready() else "%.1f秒" % player.get_ultimate_remaining(),
		]
		defense_label.text = "P1 防御：%s" % ("生效中" if player.is_defending else "K")
	if player_two != null and local_player_count > 1:
		cooldown_label_two.text = "普攻：%s   1：%s   2：%s   3：%s" % [
			"就绪" if player_two.get_attack_ready() else "%.1f秒" % player_two.get_attack_remaining(),
			"就绪" if player_two.get_skill_ready() else "%.1f秒" % player_two.get_skill_remaining(),
			"就绪" if player_two.get_fan_skill_ready() else "%.1f秒" % player_two.get_fan_skill_remaining(),
			"就绪" if player_two.get_ultimate_ready() else "%.1f秒" % player_two.get_ultimate_remaining(),
		]
		defense_label_two.text = "P2 防御：%s" % ("生效中" if player_two.is_defending else "+")

func _format_upgrade_button(upgrade: Dictionary, target_player: PlayerController = null) -> String:
	var stat: String = str(upgrade.get("stat", ""))
	var current_value: String = _format_player_stat(stat, target_player)
	return "%s\n%s\n当前：%s" % [
		upgrade["title"],
		upgrade["description"],
		current_value,
	]

func _format_player_stat(stat: String, target_player: PlayerController = null) -> String:
	var stat_player: PlayerController = player if target_player == null else target_player
	if stat_player == null:
		return "-"
	match stat:
		"attack_damage":
			return "攻击力 %.1f" % stat_player.attack_damage
		"max_health":
			return "最大生命 %.0f" % stat_player.max_health
		"move_speed":
			return "移动速度 %.0f" % stat_player.move_speed
		"attack_cooldown":
			return "普攻冷却 %.2f秒" % stat_player.attack_cooldown
		"dash_cooldown":
			return "闪避冷却 %.2f秒" % stat_player.dash_cooldown
		"skill_cooldown":
			return "技能冷却 %.2f秒" % stat_player.skill_cooldown
		"attack_range":
			return "普攻范围 %.0f" % stat_player.attack_range
		"skill_damage":
			return "技能伤害 %.1f" % stat_player.skill_damage
		"skill_range":
			return "技能范围 %.0f" % stat_player.skill_length
		"lifesteal":
			return "吸血 %.0f%%" % (stat_player.lifesteal_ratio * 100.0)
		"crit_chance":
			return "暴击率 %.0f%%" % (stat_player.crit_chance * 100.0)
		"knockback":
			return "击退 %.0f" % stat_player.attack_knockback
		"dash_charges":
			return "闪避次数 %d" % stat_player.dash_max_charges
		"heal_percent":
			return "生命 %d / %d" % [roundi(stat_player.health), roundi(stat_player.max_health)]
		_:
			return "-"

func _format_game_state(state: String) -> String:
	match state:
		GameStateScript.WAVE_ACTIVE:
			return "战斗中"
		GameStateScript.UPGRADE_SELECT:
			return "升级选择"
		GameStateScript.BOSS_WAVE:
			return "首领战"
		GameStateScript.VICTORY:
			return "胜利"
		GameStateScript.DEFEAT:
			return "失败"
		GameStateScript.COUNTDOWN:
			return "准备"
		GameStateScript.LOBBY:
			return "大厅"
		_:
			return state

func _format_rarity(rarity: String) -> String:
	match rarity:
		"Common":
			return "普通"
		"Rare":
			return "稀有"
		"Epic":
			return "史诗"
		_:
			return rarity
