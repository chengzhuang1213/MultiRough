extends Node2D

const GameStateScript := preload("res://scripts/core/game_state.gd")
const EnemyScript := preload("res://scripts/enemy/enemy_controller.gd")
const GameRulesScript := preload("res://scripts/gameplay/game_rules.gd")
const WaveManagerScript := preload("res://scripts/gameplay/wave_manager.gd")
const UpgradeManagerScript := preload("res://scripts/upgrades/upgrade_manager.gd")
const CombatManagerScript := preload("res://scripts/gameplay/combat_manager.gd")
const PlayerRosterScript := preload("res://scripts/player/player_roster.gd")

const ARENA_BOUNDS := Rect2(Vector2(-960, -540), Vector2(1920, 1080))
const VIEWPORT_SIZE := Vector2(1280, 720)
const UPGRADE_PANEL_WIDTH := 980.0
const UPGRADE_PANEL_HEIGHT := 460.0
const NEXT_WAVE_BUTTON_WIDTH := 220.0
const NEXT_WAVE_BUTTON_HEIGHT := 44.0
const PLAYER_HUD_WIDTH := 560.0
const PLAYER_HUD_OCCLUDED_ALPHA := 0.20
const PLAYER_HUD_FADE_OUT_TIME := 0.12
const PLAYER_HUD_FADE_IN_TIME := 0.20
const PLAYER_HUD_FADE_RELEASE_DELAY := 0.08
const SHOW_ENEMY_ATTACK_TELEGRAPH := true
const NETWORK_PORT := 24567
const NETWORK_SYNC_SEED := 260708
const WAVE_CLEAR_HEAL_AMOUNT := GameRulesScript.WAVE_CLEAR_HEAL_AMOUNT
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
const WAVE_DEFS := WaveManagerScript.DEFAULT_WAVES
const CHARACTER_ORDER := GameRulesScript.CHARACTER_ORDER
const CHARACTER_CARD_ART := {
	"warrior": "res://assets/original/characters/warrior/warrior_card_v4.png",
	"archer": "res://assets/original/characters/archer/archer_card_v2.png",
	"lancer": "res://assets/original/characters/lancer/lancer_card_v2.png",
	"mage": "res://assets/original/characters/mage/mage_card_v2.png",
}
const CHARACTER_CARD_ACCENTS := {
	"warrior": Color(0.95, 0.38, 0.42),
	"archer": Color(0.78, 0.32, 0.62),
	"lancer": Color(0.36, 0.76, 0.63),
	"mage": Color(0.66, 0.42, 0.90),
}
const CHARACTER_SKILL_ICONS := {
	"warrior": {
		"Q": "res://assets/ui/character_select/skills/warrior_q.png",
		"E": "res://assets/ui/character_select/skills/warrior_e.png",
		"F": "res://assets/ui/character_select/skills/warrior_f.png",
	},
	"archer": {
		"Q": "res://assets/ui/character_select/skills/archer_q.png",
		"E": "res://assets/ui/character_select/skills/archer_e.png",
		"F": "res://assets/ui/character_select/skills/archer_f.png",
	},
	"lancer": {
		"Q": "res://assets/ui/character_select/skills/lancer_q.png",
		"E": "res://assets/ui/character_select/skills/lancer_e.png",
		"F": "res://assets/ui/character_select/skills/lancer_f.png",
	},
	"mage": {
		"Q": "res://assets/ui/character_select/skills/mage_q.png",
		"E": "res://assets/ui/character_select/skills/mage_e.png",
		"F": "res://assets/ui/character_select/skills/mage_f.png",
	},
}
const CHARACTER_STAT_ICONS := {
	"health": "res://assets/ui/character_select/stat_health.png",
	"attack": "res://assets/ui/character_select/stat_attack.png",
	"speed": "res://assets/ui/character_select/stat_speed.png",
	"cooldown": "res://assets/ui/character_select/stat_cooldown.png",
}
const UPGRADE_CARD_ART := {
	"Common": "res://assets/ui/upgrades/upgrade_card_common.png",
	"Rare": "res://assets/ui/upgrades/upgrade_card_rare.png",
	"Epic": "res://assets/ui/upgrades/upgrade_card_epic.png",
}
const CHARACTER_CONFIGS := GameRulesScript.CHARACTER_CONFIGS

var game_state := GameStateScript.LOBBY
var wave_index := -1
var wave_manager = WaveManagerScript.new()
var enemies: Array[EnemyController] = []
var local_player_slots: Array = []
var local_player_count := 1
var minion_count_multiplier := 1.0
var enemy_health_multiplier := 1.0
var enemy_damage_multiplier := 1.0
var boss_health_multiplier := 1.0
var boss_damage_multiplier := 1.0
var elapsed_time := 0.0
var wave_time_left := 0.0
var epic_upgrade_seen := false
var enemies_defeated := 0
var damage_dealt := 0.0
var damage_taken := 0.0
var ultimate_states: Dictionary = {}
var persistent_skill_areas: Array = []
var waiting_for_next_wave_input := false
var pending_player_count := 1
var selected_character_ids: Array = ["warrior", "warrior"]
var character_select_rows: Array = []
var character_select_slot_buttons: Array = []
var character_select_active_slot := 0
var network_mode := "none"
var local_peer_player_index := 1
var network_peer_joined := false
var network_status_text := ""

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
var network_ip_edit: LineEdit
var network_status_label: Label
var character_select_panel: VBoxContainer
var character_select_start_button: Button
var hud_left: VBoxContainer
var hud_right: VBoxContainer
var player_hud: PanelContainer
var status_label: Label
var wave_label: Label
var enemies_label: Label
var player_huds: Array = []
var player_hud_alpha := 1.0
var player_hud_fade_release_left := 0.0
var upgrade_panel: VBoxContainer
var start_next_wave_button: Button
var result_label: Label
var restart_button: Button
var return_to_menu_button: Button
var combat_manager
var player_roster

func _ready() -> void:
	randomize()
	combat_manager = CombatManagerScript.new(self)
	player_roster = PlayerRosterScript.new(self, combat_manager)
	_ensure_input_map()
	_build_world()
	_build_ui()
	get_viewport().size_changed.connect(_layout_ui)
	_show_main_menu()

func _input(event: InputEvent) -> void:
	if not _is_network_game():
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse_event.pressed:
		Input.action_press("network_basic_attack")
	else:
		Input.action_release("network_basic_attack")

func _unhandled_input(event: InputEvent) -> void:
	if not waiting_for_next_wave_input:
		return
	if game_state != GameStateScript.UPGRADE_SELECT or not _all_required_upgrades_selected():
		return
	if network_mode == "client":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_start_next_wave_for_all_peers()
	elif event is InputEventMouseButton and event.pressed:
		_start_next_wave_for_all_peers()

func _ensure_input_map() -> void:
	_add_key_action("move_left", [KEY_A])
	_add_key_action("move_right", [KEY_D])
	_add_key_action("move_up", [KEY_W])
	_add_key_action("move_down", [KEY_S])
	_add_key_action("basic_attack", [KEY_J])
	_add_mouse_action("basic_attack", MOUSE_BUTTON_LEFT)
	_add_key_action("network_basic_attack", [KEY_J])
	_add_key_action("dash", [KEY_SPACE])
	_remove_key_action("dash", [KEY_K])
	_add_key_action("active_skill", [KEY_Q])
	_add_key_action("fan_skill", [KEY_E])
	_add_key_action("ultimate_skill", [KEY_F])
	_add_key_action("defend", [KEY_K])
	_add_mouse_action("defend", MOUSE_BUTTON_RIGHT)

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
		wave_time_left = maxf(0.0, wave_time_left - delta)
		if wave_time_left <= 0.0:
			_enter_defeat("时间耗尽")
	if _is_network_game():
		_send_network_input()
	_update_camera()
	_update_player_hud_occlusion(delta)
	_update_enemy_targets()
	if _is_combat_active():
		combat_manager.update_ultimates(delta)
		_update_persistent_skill_areas(delta)
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

	player_hud = PanelContainer.new()
	player_hud.visible = false
	player_hud.custom_minimum_size = Vector2(PLAYER_HUD_WIDTH, 0.0)
	ui_layer.add_child(player_hud)

	_create_player_hud(player_hud, ["普攻", "Q", "E", "F"])

	hud_right = VBoxContainer.new()
	hud_right.position = Vector2(16, 16)
	hud_right.visible = false
	hud_right.add_theme_constant_override("separation", 6)
	ui_layer.add_child(hud_right)

	main_menu_panel = VBoxContainer.new()
	main_menu_panel.position = Vector2(460, 230)
	main_menu_panel.custom_minimum_size = Vector2(360, 250)
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

	var network_row: HBoxContainer = HBoxContainer.new()
	network_row.add_theme_constant_override("separation", 8)
	main_menu_panel.add_child(network_row)

	network_ip_edit = LineEdit.new()
	network_ip_edit.placeholder_text = "房主 IP，如 192.168.1.78"
	network_ip_edit.text = ""
	network_ip_edit.custom_minimum_size = Vector2(184, 42)
	network_row.add_child(network_ip_edit)

	var host_button: Button = Button.new()
	host_button.text = "创建联机"
	host_button.custom_minimum_size = Vector2(82, 42)
	host_button.pressed.connect(_start_network_host)
	network_row.add_child(host_button)

	var join_button: Button = Button.new()
	join_button.text = "加入"
	join_button.custom_minimum_size = Vector2(82, 42)
	join_button.pressed.connect(_start_network_client)
	network_row.add_child(join_button)

	network_status_label = Label.new()
	network_status_label.text = ""
	network_status_label.custom_minimum_size = Vector2(360, 0.0)
	network_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_menu_panel.add_child(network_status_label)

	character_select_panel = VBoxContainer.new()
	character_select_panel.custom_minimum_size = Vector2(1120, 680)
	character_select_panel.visible = false
	character_select_panel.add_theme_constant_override("separation", 10)
	ui_layer.add_child(character_select_panel)

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

	return_to_menu_button = Button.new()
	return_to_menu_button.text = "返回主菜单"
	return_to_menu_button.custom_minimum_size = Vector2(132, 40)
	return_to_menu_button.visible = false
	return_to_menu_button.pressed.connect(_on_return_to_menu_pressed)
	ui_layer.add_child(return_to_menu_button)

	_layout_ui()
	_update_status()

func _get_viewport_size() -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return VIEWPORT_SIZE
	return viewport_size

func _layout_ui() -> void:
	var viewport_size: Vector2 = _get_viewport_size()
	if hud_left != null:
		hud_left.position = Vector2(16, 16)
	if hud_right != null:
		hud_right.position = Vector2(16, 16)
	if player_hud != null:
		player_hud.position = Vector2(
			maxf(16.0, (viewport_size.x - PLAYER_HUD_WIDTH) * 0.5),
			maxf(16.0, viewport_size.y - _get_hud_height(player_hud) - 16.0)
		)
	if main_menu_panel != null:
		main_menu_panel.position = (viewport_size - main_menu_panel.custom_minimum_size) * 0.5
	if character_select_panel != null:
		character_select_panel.position = (viewport_size - character_select_panel.custom_minimum_size) * 0.5
	if upgrade_panel != null:
		upgrade_panel.position = (viewport_size - upgrade_panel.custom_minimum_size) * 0.5
	if start_next_wave_button != null:
		start_next_wave_button.position = Vector2(
			(viewport_size.x - NEXT_WAVE_BUTTON_WIDTH) * 0.5,
			viewport_size.y - 92.0
		)
	if return_to_menu_button != null:
		return_to_menu_button.position = Vector2(
			maxf(16.0, viewport_size.x - return_to_menu_button.custom_minimum_size.x - 16.0),
			16.0
		)
	if result_label != null and restart_button != null:
		_position_result_panel()

func _get_hud_height(hud: Control) -> float:
	var height: float = hud.size.y
	if height <= 0.0:
		return 128.0
	return height

func _update_player_hud_occlusion(delta: float) -> void:
	if player_hud == null or not player_hud.visible or not _is_combat_active():
		player_hud_alpha = 1.0
		player_hud_fade_release_left = 0.0
		player_roster.set_hud_occlusion_opacity(player_hud_alpha)
		return
	var occluded := _has_actor_behind_player_hud()
	if occluded:
		player_hud_fade_release_left = PLAYER_HUD_FADE_RELEASE_DELAY
	else:
		player_hud_fade_release_left = maxf(0.0, player_hud_fade_release_left - delta)
	var target_alpha := PLAYER_HUD_OCCLUDED_ALPHA if occluded or player_hud_fade_release_left > 0.0 else 1.0
	var transition_time := PLAYER_HUD_FADE_OUT_TIME if target_alpha < player_hud_alpha else PLAYER_HUD_FADE_IN_TIME
	player_hud_alpha = move_toward(player_hud_alpha, target_alpha, delta / transition_time)
	player_roster.set_hud_occlusion_opacity(player_hud_alpha)

func _has_actor_behind_player_hud() -> bool:
	var hud_rect := player_hud.get_global_rect()
	var canvas_transform := get_viewport().get_canvas_transform()
	for target_player in players:
		if is_instance_valid(target_player) and not target_player.is_dead:
			if hud_rect.has_point(canvas_transform * target_player.global_position):
				return true
	for enemy in enemies:
		if is_instance_valid(enemy):
			if hud_rect.has_point(canvas_transform * enemy.global_position):
				return true
	return false

func _create_player_hud(parent: PanelContainer, skill_labels: Array[String]) -> void:
	player_roster.create_hud(parent, skill_labels)

func _show_main_menu() -> void:
	game_state = GameStateScript.LOBBY
	if main_menu_panel != null:
		main_menu_panel.visible = true
	if character_select_panel != null:
		character_select_panel.visible = false
	if hud_left != null:
		hud_left.visible = false
	if hud_right != null:
		hud_right.visible = false
	if player_hud != null:
		player_hud.visible = false
	if return_to_menu_button != null:
		return_to_menu_button.visible = false
	_update_status()

func _start_single_player() -> void:
	network_mode = "none"
	_show_character_select(1)

func _start_network_host() -> void:
	_connect_network_signals()
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(NETWORK_PORT, 1)
	if error != OK:
		_set_network_status("创建失败：端口 %d 不可用" % NETWORK_PORT)
		return
	multiplayer.multiplayer_peer = peer
	network_mode = "host"
	local_peer_player_index = 1
	network_peer_joined = false
	selected_character_ids = ["warrior", "warrior"]
	var lan_addresses := _get_lan_ipv4_addresses()
	if lan_addresses.is_empty():
		_set_network_status("房间已创建，端口 %d。请把房主电脑的局域网 IPv4 发给朋友。" % NETWORK_PORT)
	else:
		_set_network_status(
			"房间已创建。朋友输入：%s（端口 %d）。无法加入时，房主运行 Allow-MultiRough-Host.cmd。"
			% [", ".join(lan_addresses), NETWORK_PORT]
		)
	_show_character_select(2)

func _start_network_client() -> void:
	_connect_network_signals()
	var address := network_ip_edit.text.strip_edges() if network_ip_edit != null else ""
	if address.is_empty():
		_set_network_status("请填写房主显示的局域网 IP，不能填写 127.0.0.1")
		return
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, NETWORK_PORT)
	if error != OK:
		_set_network_status("加入失败：无法连接 %s:%d" % [address, NETWORK_PORT])
		return
	multiplayer.multiplayer_peer = peer
	network_mode = "client"
	local_peer_player_index = 2
	network_peer_joined = false
	selected_character_ids = ["warrior", "warrior"]
	_set_network_status("连接中：%s:%d" % [address, NETWORK_PORT])

func _connect_network_signals() -> void:
	if not multiplayer.peer_connected.is_connected(_on_network_peer_connected):
		multiplayer.peer_connected.connect(_on_network_peer_connected)
	if not multiplayer.connected_to_server.is_connected(_on_network_connected_to_server):
		multiplayer.connected_to_server.connect(_on_network_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_network_connection_failed):
		multiplayer.connection_failed.connect(_on_network_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_on_network_server_disconnected):
		multiplayer.server_disconnected.connect(_on_network_server_disconnected)

func _on_network_peer_connected(peer_id: int) -> void:
	if network_mode != "host":
		return
	network_peer_joined = true
	_set_network_status("朋友已加入：peer %d。选择职业后由房主开始。" % peer_id)
	rpc_id(peer_id, "_network_enter_room", selected_character_ids)
	_refresh_character_select_buttons()

func _on_network_connected_to_server() -> void:
	network_peer_joined = true
	_set_network_status("已连接，选择你的职业，等待房主开始")
	_show_character_select(2)

func _on_network_connection_failed() -> void:
	_set_network_status("连接失败。确认双方在同一网络、IP 正确，并让房主运行 Allow-MultiRough-Host.cmd。")
	network_mode = "none"
	network_peer_joined = false
	multiplayer.multiplayer_peer = null

func _get_lan_ipv4_addresses() -> PackedStringArray:
	var addresses := PackedStringArray()
	for address in IP.get_local_addresses():
		if _is_private_ipv4(address) and not addresses.has(address):
			addresses.append(address)
	return addresses

func _is_private_ipv4(address: String) -> bool:
	var parts := address.split(".")
	if parts.size() != 4:
		return false
	for part in parts:
		if not part.is_valid_int():
			return false
		var value := part.to_int()
		if value < 0 or value > 255:
			return false
	var first := parts[0].to_int()
	var second := parts[1].to_int()
	return first == 10 or (first == 172 and second >= 16 and second <= 31) or (first == 192 and second == 168)

func _on_network_server_disconnected() -> void:
	_set_network_status("已断开连接")
	network_mode = "none"
	network_peer_joined = false
	multiplayer.multiplayer_peer = null
	_clear_run_state()
	_show_main_menu()

func _set_network_status(text: String) -> void:
	network_status_text = text
	if network_status_label != null:
		network_status_label.text = text

@rpc("any_peer", "reliable")
func _network_enter_room(character_ids: Array) -> void:
	selected_character_ids = character_ids.duplicate()
	_show_character_select(2)

@rpc("any_peer", "reliable")
func _network_set_character(player_index: int, character_id: String) -> void:
	if player_index < 1 or player_index > 2 or not CHARACTER_CONFIGS.has(character_id):
		return
	selected_character_ids[player_index - 1] = character_id
	if network_mode == "host":
		rpc("_network_set_character", player_index, character_id)
	_refresh_character_select_buttons()

@rpc("any_peer", "reliable")
func _network_start_game(character_ids: Array) -> void:
	selected_character_ids = character_ids.duplicate()
	if character_select_panel != null:
		character_select_panel.visible = false
	_start_game(2)

func _is_network_game() -> bool:
	return network_mode == "host" or network_mode == "client"

func _uses_external_player_input() -> bool:
	return _is_network_game()

func _show_character_select(player_count: int) -> void:
	pending_player_count = player_count
	if selected_character_ids.size() < 2:
		selected_character_ids = ["warrior", "warrior"]
	if main_menu_panel != null:
		main_menu_panel.visible = false
	if character_select_panel == null:
		_start_game(player_count)
		return
	character_select_panel.visible = true
	_rebuild_character_select_panel()
	_layout_ui()

func _rebuild_character_select_panel() -> void:
	character_select_rows.clear()
	character_select_slot_buttons.clear()
	for child in character_select_panel.get_children():
		character_select_panel.remove_child(child)
		child.queue_free()
	if _is_network_game():
		character_select_active_slot = local_peer_player_index - 1
	else:
		character_select_active_slot = clampi(character_select_active_slot, 0, pending_player_count - 1)

	var title: Label = Label.new()
	title.text = "联机房间" if _is_network_game() else "选择角色"
	title.custom_minimum_size = Vector2(1120, 38)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	character_select_panel.add_child(title)

	if _is_network_game():
		var room_status: Label = Label.new()
		room_status.text = network_status_text
		room_status.custom_minimum_size = Vector2(1120, 28)
		room_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		room_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		character_select_panel.add_child(room_status)

	if pending_player_count > 1:
		var slot_row: HBoxContainer = HBoxContainer.new()
		slot_row.custom_minimum_size = Vector2(1120, 42)
		slot_row.alignment = BoxContainer.ALIGNMENT_CENTER
		slot_row.add_theme_constant_override("separation", 12)
		character_select_panel.add_child(slot_row)
		for slot_index in range(pending_player_count):
			var slot_button: Button = Button.new()
			slot_button.custom_minimum_size = Vector2(240, 40)
			slot_button.pressed.connect(_set_character_select_active_slot.bind(slot_index))
			slot_row.add_child(slot_button)
			character_select_slot_buttons.append(slot_button)

	var card_row: HBoxContainer = HBoxContainer.new()
	card_row.custom_minimum_size = Vector2(1120, 452)
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	card_row.add_theme_constant_override("separation", 18)
	character_select_panel.add_child(card_row)
	for character_id in CHARACTER_ORDER:
		var card_data := _build_character_card(str(character_id))
		card_row.add_child(card_data["button"] as Button)
		character_select_rows.append(card_data)

	character_select_start_button = Button.new()
	character_select_start_button.custom_minimum_size = Vector2(1120, 50)
	character_select_start_button.pressed.connect(_confirm_character_select)
	character_select_panel.add_child(character_select_start_button)
	_refresh_character_select_buttons()

func _build_character_card(character_id: String) -> Dictionary:
	var config: Dictionary = CHARACTER_CONFIGS.get(character_id, CHARACTER_CONFIGS["warrior"])
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(266, 452)
	button.clip_contents = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(_select_active_character.bind(character_id))

	var art: TextureRect = TextureRect.new()
	art.texture = load(str(CHARACTER_CARD_ART.get(character_id, ""))) as Texture2D
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(art)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(content)

	var title_panel: PanelContainer = PanelContainer.new()
	title_panel.custom_minimum_size = Vector2(242, 42)
	title_panel.add_theme_stylebox_override("panel", _make_character_info_style(Color(0.03, 0.05, 0.07, 0.84)))
	title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title_panel)

	var title_label: Label = Label.new()
	title_label.text = _get_character_name(character_id)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_panel.add_child(title_label)

	var art_space: Control = Control.new()
	art_space.custom_minimum_size = Vector2(0, 202)
	art_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(art_space)

	var stats_panel: PanelContainer = PanelContainer.new()
	stats_panel.custom_minimum_size = Vector2(242, 88)
	stats_panel.add_theme_stylebox_override("panel", _make_character_info_style(Color(0.03, 0.05, 0.07, 0.88)))
	stats_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(stats_panel)

	var stats_grid: GridContainer = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 8)
	stats_grid.add_theme_constant_override("v_separation", 4)
	stats_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_panel.add_child(stats_grid)
	stats_grid.add_child(_build_character_stat("health", "生命 %d" % roundi(float(config.get("max_health", 0.0)))))
	stats_grid.add_child(_build_character_stat("attack", "攻击 %d" % roundi(float(config.get("attack_damage", 0.0)))))
	stats_grid.add_child(_build_character_stat("speed", "移速 %d" % roundi(float(config.get("move_speed", 0.0)))))
	stats_grid.add_child(_build_character_stat("cooldown", "间隔 %.2f秒" % float(config.get("attack_cooldown", 0.0))))

	var skills: HBoxContainer = HBoxContainer.new()
	skills.custom_minimum_size = Vector2(242, 58)
	skills.alignment = BoxContainer.ALIGNMENT_CENTER
	skills.add_theme_constant_override("separation", 6)
	skills.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(skills)
	for skill_key in ["Q", "E", "F"]:
		skills.add_child(_build_character_skill_key(character_id, skill_key, CHARACTER_CARD_ACCENTS.get(character_id, Color.WHITE)))

	return {
		"character_id": character_id,
		"button": button,
		"title_label": title_label,
	}

func _build_character_stat(icon_key: String, text: String) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size = Vector2(113, 32)
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon: TextureRect = TextureRect.new()
	icon.texture = load(str(CHARACTER_STAT_ICONS.get(icon_key, ""))) as Texture2D
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var label: Label = Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	return row

func _build_character_skill_key(character_id: String, skill_key: String, accent: Color) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(76, 58)
	panel.clip_contents = true
	var style := _make_character_info_style(Color(0.03, 0.05, 0.07, 0.92))
	style.border_color = accent
	style.set_border_width_all(2)
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon: TextureRect = TextureRect.new()
	var character_icons: Dictionary = CHARACTER_SKILL_ICONS.get(character_id, {})
	icon.texture = load(str(character_icons.get(skill_key, ""))) as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(icon)
	var label: Label = Label.new()
	label.text = skill_key
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 0.95))
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	return panel

func _make_character_info_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_top = 5
	style.content_margin_right = 8
	style.content_margin_bottom = 5
	return style

func _set_character_select_active_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= pending_player_count:
		return
	if _is_network_game() and slot_index != local_peer_player_index - 1:
		return
	character_select_active_slot = slot_index
	_refresh_character_select_buttons()

func _select_active_character(character_id: String) -> void:
	_select_character(character_select_active_slot, character_id)

func _select_character(slot_index: int, character_id: String) -> void:
	if slot_index < 0:
		return
	if _is_network_game() and slot_index != local_peer_player_index - 1:
		return
	while selected_character_ids.size() <= slot_index:
		selected_character_ids.append("warrior")
	selected_character_ids[slot_index] = character_id
	if _is_network_game():
		rpc("_network_set_character", slot_index + 1, character_id)
	_refresh_character_select_buttons()

func _refresh_character_select_buttons() -> void:
	for slot_index in range(character_select_slot_buttons.size()):
		var slot_button: Button = character_select_slot_buttons[slot_index] as Button
		var active := slot_index == character_select_active_slot
		slot_button.text = "%sP%d  %s" % ["> " if active else "", slot_index + 1, _get_character_name(_get_selected_character_id(slot_index))]
		slot_button.disabled = _is_network_game() and slot_index != local_peer_player_index - 1
		_style_character_slot_button(slot_button, active)
	var active_character_id := _get_selected_character_id(character_select_active_slot)
	for card_data in character_select_rows:
		var character_id: String = str(card_data.get("character_id", "warrior"))
		var button: Button = card_data.get("button") as Button
		var title_label: Label = card_data.get("title_label") as Label
		var selected := character_id == active_character_id
		if title_label != null:
			title_label.text = ("> " if selected else "") + _get_character_name(character_id)
		_style_character_card_button(button, selected, CHARACTER_CARD_ACCENTS.get(character_id, Color.WHITE))
	if character_select_start_button != null:
		if network_mode == "host":
			character_select_start_button.text = "开始联机" if network_peer_joined else "等待朋友加入"
			character_select_start_button.disabled = not network_peer_joined
		elif network_mode == "client":
			character_select_start_button.text = "等待房主开始"
			character_select_start_button.disabled = true
		else:
			character_select_start_button.text = "开始"
			character_select_start_button.disabled = false

func _style_character_card_button(button: Button, selected: bool, accent: Color) -> void:
	if button == null:
		return
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0.025, 0.035, 0.05, 1.0)
	normal.border_color = accent if selected else Color(0.30, 0.34, 0.38, 0.9)
	normal.set_border_width_all(4 if selected else 2)
	normal.set_corner_radius_all(6)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.border_color = accent.lightened(0.18)
	hover.set_border_width_all(4)
	var pressed: StyleBoxFlat = hover.duplicate()
	pressed.bg_color = Color(0.08, 0.10, 0.13, 1.0)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.modulate = Color.WHITE if selected else Color(0.82, 0.84, 0.86, 1.0)

func _style_character_slot_button(button: Button, active: bool) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.16, 0.20, 0.96) if active else Color(0.06, 0.08, 0.10, 0.90)
	style.border_color = Color(0.95, 0.76, 0.28, 1.0) if active else Color(0.30, 0.34, 0.38, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("disabled", style)

func _confirm_character_select() -> void:
	if network_mode == "client":
		return
	if network_mode == "host":
		if not network_peer_joined:
			_set_network_status("等待朋友加入后才能开始")
			_refresh_character_select_buttons()
			return
		if character_select_panel != null:
			character_select_panel.visible = false
		rpc("_network_start_game", selected_character_ids)
		_start_game(2)
		return
	if character_select_panel != null:
		character_select_panel.visible = false
	_start_game(pending_player_count)

func _start_game(player_count: int) -> void:
	if _uses_external_player_input():
		seed(NETWORK_SYNC_SEED)
	local_player_count = player_count
	var scaling: Dictionary = GameRulesScript.get_mode_scaling(local_player_count)
	minion_count_multiplier = float(scaling["minion_count"])
	enemy_health_multiplier = float(scaling["enemy_health"])
	enemy_damage_multiplier = float(scaling["enemy_damage"])
	boss_health_multiplier = float(scaling["boss_health"])
	boss_damage_multiplier = float(scaling["boss_damage"])
	wave_manager.reset()
	wave_index = wave_manager.wave_index
	elapsed_time = 0.0
	wave_time_left = 0.0
	epic_upgrade_seen = false
	enemies_defeated = 0
	damage_dealt = 0.0
	damage_taken = 0.0
	local_player_slots.clear()
	if main_menu_panel != null:
		main_menu_panel.visible = false
	hud_left.visible = true
	hud_right.visible = false
	player_hud.visible = true
	return_to_menu_button.visible = true
	_spawn_players(local_player_count)
	call_deferred("_layout_ui")
	_start_next_wave()

func _spawn_players(player_count: int) -> void:
	player = _create_player("Player1", Vector2(-42.0, 0.0), Color.WHITE, player_count <= 1, _build_character_config(0, "Blue Units"))
	players = [player]
	_add_local_player_slot(1, player)
	combat_manager.setup_ultimate(player)
	if player_count > 1:
		player_two = _create_player("Player2", Vector2(42.0, 0.0), Color.WHITE, false, _build_character_config(1, "Red Units"))
		players.append(player_two)
		_add_local_player_slot(2, player_two)
		combat_manager.setup_ultimate(player_two)
	if _uses_external_player_input():
		_configure_network_players()
	_assign_player_hud(0, _get_network_local_player() if _is_network_game() else player)

func _configure_network_players() -> void:
	if player != null:
		player.external_input_enabled = local_peer_player_index != 1
		player.use_mouse_aim = local_peer_player_index == 1
		if local_peer_player_index == 1:
			player.basic_attack_action = "network_basic_attack"
	if player_two != null:
		player_two.external_input_enabled = local_peer_player_index != 2
		player_two.use_mouse_aim = local_peer_player_index == 2
		if local_peer_player_index == 2:
			player_two.move_left_action = "move_left"
			player_two.move_right_action = "move_right"
			player_two.move_up_action = "move_up"
			player_two.move_down_action = "move_down"
			player_two.basic_attack_action = "network_basic_attack"
			player_two.dash_action = "dash"
			player_two.defend_action = "defend"
			player_two.active_skill_action = "active_skill"
			player_two.fan_skill_action = "fan_skill"
			player_two.ultimate_skill_action = "ultimate_skill"

func _get_network_local_player() -> PlayerController:
	if local_peer_player_index == 1:
		return player
	if local_peer_player_index == 2:
		return player_two
	return null

func _get_network_player(player_index: int) -> PlayerController:
	if player_index == 1:
		return player
	if player_index == 2:
		return player_two
	return null

func _send_network_input() -> void:
	if multiplayer.multiplayer_peer == null:
		return
	var local_player := _get_network_local_player()
	if local_player == null or not is_instance_valid(local_player):
		return
	rpc("_receive_player_input", local_peer_player_index, local_player.make_input_packet())

@rpc("any_peer", "unreliable")
func _receive_player_input(player_index: int, packet: Dictionary) -> void:
	if player_index == local_peer_player_index:
		return
	var target_player := _get_network_player(player_index)
	if target_player == null or not is_instance_valid(target_player):
		return
	target_player.apply_external_input(packet)

func _get_selected_character_id(slot_index: int) -> String:
	if slot_index >= 0 and slot_index < selected_character_ids.size():
		var selected_id: String = str(selected_character_ids[slot_index])
		if CHARACTER_CONFIGS.has(selected_id):
			return selected_id
	return "warrior"

func _get_character_name(character_id: String) -> String:
	var config: Dictionary = CHARACTER_CONFIGS.get(character_id, CHARACTER_CONFIGS["warrior"])
	return str(config.get("name", character_id))

func get_character_skill_icon_path(character_id: String, skill_key: String) -> String:
	var character_icons: Dictionary = CHARACTER_SKILL_ICONS.get(character_id, {})
	return str(character_icons.get(skill_key.to_upper(), ""))

func _build_character_config(slot_index: int, unit_color_folder: String) -> Dictionary:
	var character_id: String = _get_selected_character_id(slot_index)
	var config: Dictionary = GameRulesScript.get_character_config(character_id)
	config["unit_color_folder"] = "Yellow Units" if character_id in ["archer", "lancer"] else unit_color_folder
	return config

func _add_local_player_slot(player_index: int, target_player: PlayerController) -> void:
	player_roster.add_slot(player_index, target_player)

func _reset_upgrade_slots() -> void:
	player_roster.reset_upgrade_slots()

func _get_local_player_slot(player_index: int) -> Dictionary:
	return player_roster.get_slot(player_index)

func _create_player(player_name: String, spawn_position: Vector2, tint: Color, mouse_aim: bool, character_config: Dictionary) -> PlayerController:
	return player_roster.create_player(player_name, spawn_position, tint, mouse_aim, character_config)

func _assign_player_hud(index: int, target_player: PlayerController) -> void:
	player_roster.assign_hud(index, target_player)

func _start_next_wave() -> void:
	if game_state == GameStateScript.UPGRADE_SELECT and not _all_required_upgrades_selected():
		return
	if game_state == GameStateScript.VICTORY or game_state == GameStateScript.DEFEAT:
		return
	if _is_network_game():
		seed(NETWORK_SYNC_SEED + (wave_index + 1) * 1009)
	_set_player_cooldowns_paused(false)
	_stop_ultimate()
	var wave_result: Dictionary = wave_manager.advance()
	wave_index = int(wave_result["index"])
	_clear_upgrade_panel()
	_clear_projectiles()
	upgrade_panel.visible = false
	start_next_wave_button.visible = false
	start_next_wave_button.disabled = true
	result_label.visible = false
	waiting_for_next_wave_input = false
	_reset_upgrade_slots()

	if bool(wave_result["complete"]):
		_enter_victory()
		return

	_revive_dead_players_for_next_wave()

	var wave_def: Dictionary = wave_result["definition"] as Dictionary
	if wave_def.get("boss", false):
		game_state = GameStateScript.BOSS_WAVE
		wave_time_left = GameRulesScript.BOSS_WAVE_TIME_LIMIT
		_spawn_boss()
	else:
		game_state = GameStateScript.WAVE_ACTIVE
		wave_time_left = GameRulesScript.NORMAL_WAVE_TIME_LIMIT
		_spawn_wave(wave_def)

	_update_status()

func _spawn_minions(count: int) -> void:
	for index in range(count):
		var enemy: EnemyController = EnemyScript.new()
		enemy.setup_as_minion(wave_index + 1)
		_tune_enemy_for_mode(enemy)
		enemy.global_position = _spawn_point(index, count)
		_register_enemy(enemy)

func _spawn_wave(wave_def: Dictionary) -> void:
	var spawn_types: Array[String] = []
	for enemy_type in ["melee", "heavy", "ranged", "shield"]:
		var scaled_count := roundi(float(wave_def.get(enemy_type, 0)) * minion_count_multiplier)
		for _index in range(scaled_count):
			spawn_types.append(enemy_type)
	var elite_multiplier := 2 if local_player_count > 1 else 1
	for enemy_type in ["charger", "bomber"]:
		for _index in range(int(wave_def.get(enemy_type, 0)) * elite_multiplier):
			spawn_types.append(enemy_type)
	for _index in range(int(wave_def.get("priest", 0))):
		spawn_types.append("priest")
	spawn_types.shuffle()
	for index in range(spawn_types.size()):
		var enemy: EnemyController = EnemyScript.new()
		_setup_wave_enemy(enemy, spawn_types[index])
		enemy.global_position = _spawn_point(index, spawn_types.size())
		_register_enemy(enemy)

func _setup_wave_enemy(enemy: EnemyController, enemy_type: String) -> void:
	var wave_number: int = wave_index + 1
	match enemy_type:
		"heavy":
			enemy.setup_as_heavy(wave_number)
		"ranged":
			enemy.setup_as_ranged(wave_number)
		"shield":
			enemy.setup_as_shield(wave_number)
		"charger":
			enemy.setup_as_charger(wave_number)
		"bomber":
			enemy.setup_as_bomber(wave_number)
		"priest":
			enemy.setup_as_priest(wave_number)
		_:
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
	if enemy.enemy_type == EnemyController.TYPE_CHARGER:
		enemy._charge_damage *= enemy_damage_multiplier
	elif enemy.enemy_type == EnemyController.TYPE_BOMBER:
		enemy._bomber_damage *= enemy_damage_multiplier
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
	enemy.attacked_player.connect(combat_manager.on_enemy_attacked_player)
	enemy.projectile_requested.connect(combat_manager.on_enemy_projectile_requested)
	enemy.area_attack_requested.connect(combat_manager.on_enemy_area_attack_requested)
	enemy.charge_started.connect(combat_manager.on_enemy_charge_started)
	enemy.self_destruct_requested.connect(combat_manager.on_enemy_self_destruct_requested)
	enemy.healing_started.connect(combat_manager.on_enemy_healing_started)
	enemy.healing_requested.connect(combat_manager.on_enemy_healing_requested)
	enemy.boss_reinforcement_requested.connect(_on_boss_reinforcement_requested)
	enemies.append(enemy)
	enemy_root.add_child(enemy)

func _on_boss_reinforcement_requested(boss: EnemyController) -> void:
	if not is_instance_valid(boss) or game_state != GameStateScript.BOSS_WAVE:
		return
	var reinforcement_types: Array[String] = ["melee", "melee", "ranged", "shield"]
	if local_player_count > 1:
		reinforcement_types.append_array(["melee", "ranged"])
	var offsets := [
		Vector2(-150.0, -90.0), Vector2(150.0, -90.0),
		Vector2(-150.0, 90.0), Vector2(150.0, 90.0),
		Vector2(0.0, -150.0), Vector2(0.0, 150.0),
	]
	for index in range(reinforcement_types.size()):
		var enemy: EnemyController = EnemyScript.new()
		_setup_wave_enemy(enemy, reinforcement_types[index])
		enemy.global_position = (boss.global_position + offsets[index]).clamp(ARENA_BOUNDS.position, ARENA_BOUNDS.end)
		_register_enemy(enemy)
		_spawn_effect(enemy.global_position, 46.0, Color(0.92, 0.24, 0.18, 0.28), 0.24)

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
	var half_view: Vector2 = _get_viewport_size() * 0.5
	var min_position: Vector2 = ARENA_BOUNDS.position + half_view
	var max_position: Vector2 = ARENA_BOUNDS.end - half_view
	camera.global_position = Vector2(
		_clamp_camera_axis(focus.x, min_position.x, max_position.x, ARENA_BOUNDS.get_center().x),
		_clamp_camera_axis(focus.y, min_position.y, max_position.y, ARENA_BOUNDS.get_center().y)
	)

func _clamp_camera_axis(value: float, minimum: float, maximum: float, fallback: float) -> float:
	if minimum > maximum:
		return fallback
	return clampf(value, minimum, maximum)

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
	if not _is_combat_active():
		return
	game_state = GameStateScript.COUNTDOWN
	wave_time_left = 0.0
	_set_player_cooldowns_paused(true)
	_stop_ultimate()
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
		var warning_color: Color = Color(1.0, 0.24, 0.18, 0.20) if enemy.is_boss else Color(1.0, 0.84, 0.25, 0.13)
		_spawn_effect(enemy.global_position, attack_range, warning_color, windup_time)

func _on_enemy_damaged(enemy: EnemyController, amount: float) -> void:
	if is_instance_valid(enemy):
		damage_dealt += amount
		_spawn_effect(enemy.global_position, 22.0, Color(1.0, 0.95, 0.55, 0.24), 0.06)
		_spawn_damage_number(enemy.global_position + Vector2(-10.0, -34.0), amount, Color(1.0, 0.92, 0.42, 1.0))

func _update_persistent_skill_areas(delta: float) -> void:
	combat_manager.update_persistent_skill_areas(delta)

func _on_player_cooldown_notice_requested(skill_index: int, source_player: PlayerController) -> void:
	for index in range(player_huds.size()):
		var hud: Dictionary = player_huds[index]
		if hud.get("player") != source_player:
			continue
		var skill_labels: Array = hud.get("skill_labels", ["普攻", "Q", "E", "F"])
		var skill_label := "右键" if skill_index == 4 else str(skill_labels[clampi(skill_index, 0, skill_labels.size() - 1)])
		_spawn_cooldown_bubble(source_player, "%s：冷却中" % skill_label)
		return

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

func _spawn_area_visual(root: Node2D, origin: Vector2, radius: float, color: Color) -> void:
	var area: Polygon2D = Polygon2D.new()
	var points: PackedVector2Array = []
	var segments := 36
	for index in range(segments):
		var angle: float = TAU * float(index) / float(segments)
		points.append(origin + Vector2(cos(angle), sin(angle)) * radius)
	area.polygon = points
	area.color = color
	root.add_child(area)

func _spawn_lancer_barricade_visual(root: Node2D, center: Vector2, forward: Vector2, length: float, depth: float) -> void:
	var side_axis: Vector2 = Vector2(-forward.y, forward.x)
	var half_side: float = length * 0.5
	var half_depth: float = depth * 0.5
	var area: Polygon2D = Polygon2D.new()
	area.color = Color(0.55, 0.86, 1.0, 0.14)
	area.polygon = PackedVector2Array([
		center - side_axis * half_side - forward * half_depth,
		center + side_axis * half_side - forward * half_depth,
		center + side_axis * half_side + forward * half_depth,
		center - side_axis * half_side + forward * half_depth,
	])
	root.add_child(area)
	for index in range(5):
		var t: float = -0.5 + float(index) / 4.0
		var spear_center: Vector2 = center + side_axis * length * t
		var spear: Line2D = Line2D.new()
		spear.width = 5.0
		spear.default_color = Color(0.72, 0.95, 1.0, 0.72)
		spear.points = PackedVector2Array([
			spear_center - forward * 42.0,
			spear_center + forward * 42.0,
		])
		root.add_child(spear)

func _spawn_lancer_sweep_effect(origin: Vector2, direction: Vector2, length: float, half_width: float) -> void:
	var forward: Vector2 = direction.normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.RIGHT
	var side_axis: Vector2 = Vector2(-forward.y, forward.x)
	for side in [-1.0, 0.0, 1.0]:
		var line: Line2D = Line2D.new()
		line.position = origin
		line.width = 5.0
		line.default_color = Color(0.65, 0.92, 1.0, 0.48)
		line.points = PackedVector2Array([
			side_axis * half_width * side * 0.45,
			forward * length + side_axis * half_width * side,
		])
		effect_root.add_child(line)
		var timer: SceneTreeTimer = get_tree().create_timer(0.12)
		timer.timeout.connect(Callable(line, "queue_free"))

func _spawn_shockwave_effect(origin: Vector2, direction: Vector2, length: float) -> void:
	var forward: Vector2 = direction.normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.RIGHT
	for index in range(4):
		var t: float = float(index + 1) / 4.0
		_spawn_effect(origin + forward * length * t, 18.0 + 8.0 * t, Color(0.35, 0.75, 1.0, 0.18), 0.12)

func _spawn_line_skill_effect(origin: Vector2, direction: Vector2, length: float, color: Color = Color(1.0, 0.86, 0.32, 0.55), lifetime: float = 0.09) -> void:
	var forward: Vector2 = direction.normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.RIGHT
	var line: Line2D = Line2D.new()
	line.position = origin
	line.width = 4.0
	line.default_color = color
	line.points = PackedVector2Array([
		Vector2.ZERO,
		forward * length,
	])
	effect_root.add_child(line)

	var timer: SceneTreeTimer = get_tree().create_timer(lifetime)
	timer.timeout.connect(Callable(line, "queue_free"))

func _spawn_ring_effect(origin: Vector2, radius: float, color: Color, lifetime: float = 0.18) -> void:
	var ring := Line2D.new()
	ring.position = origin
	ring.width = 4.0
	ring.closed = true
	ring.default_color = color
	var points := PackedVector2Array()
	for index in range(37):
		var angle := TAU * float(index) / 36.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	ring.points = points
	effect_root.add_child(ring)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(1.12, 1.12), lifetime)
	tween.tween_property(ring, "modulate:a", 0.0, lifetime)
	tween.finished.connect(Callable(ring, "queue_free"))

func _spawn_link_effect(start: Vector2, end: Vector2, color: Color, lifetime: float = 0.14) -> void:
	var line := Line2D.new()
	line.width = 4.0
	line.default_color = color
	line.points = PackedVector2Array([start, end])
	effect_root.add_child(line)
	var timer := get_tree().create_timer(lifetime)
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

func _spawn_cooldown_bubble(target_player: PlayerController, text: String) -> void:
	if target_player == null or not is_instance_valid(target_player):
		return
	var bubble: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.08, 0.78)
	style.border_color = Color(0.95, 0.95, 0.95, 0.85)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	bubble.add_theme_stylebox_override("panel", style)
	bubble.position = target_player.global_position + Vector2(-46.0, -88.0)
	bubble.custom_minimum_size = Vector2(92.0, 28.0)

	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	bubble.add_child(label)
	effect_root.add_child(bubble)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(bubble, "position", bubble.position + Vector2(0.0, -10.0), 0.5)
	tween.tween_property(bubble, "modulate:a", 0.0, 0.5)
	tween.finished.connect(Callable(bubble, "queue_free"))

func _enter_upgrade_select() -> void:
	if local_player_slots.is_empty():
		return
	if network_mode == "client":
		return
	_prepare_upgrade_select()
	var character_ids: Array = []
	var upgrade_players: Array = []
	for slot in local_player_slots:
		var target_player: PlayerController = slot.get("player") as PlayerController
		character_ids.append(target_player.character_id if target_player != null else "")
		upgrade_players.append(target_player)
	var final_upgrade_round := wave_index == wave_manager.boss_wave_index() - 1
	var force_epic := final_upgrade_round and not epic_upgrade_seen
	var excluded_rarities: Array = []
	var upgrade_rarity := "Common"
	var upgrade_sets: Array = []
	while excluded_rarities.size() < 3:
		upgrade_rarity = UpgradeManagerScript.roll_rarity(force_epic and excluded_rarities.is_empty(), excluded_rarities)
		upgrade_sets = UpgradeManagerScript.roll_for_players(upgrade_players, 3, upgrade_rarity)
		var complete_roll := true
		for upgrades in upgrade_sets:
			if (upgrades as Array).size() < 3:
				complete_roll = false
				break
		if complete_roll:
			break
		excluded_rarities.append(upgrade_rarity)
	if upgrade_rarity == "Epic":
		epic_upgrade_seen = true
	for slot_index in range(local_player_slots.size()):
		local_player_slots[slot_index]["upgrades"] = upgrade_sets[slot_index]
	if network_mode == "host":
		rpc("_network_begin_upgrade_select", upgrade_sets.duplicate(true))
		_build_single_player_upgrade_panel(local_peer_player_index)
	else:
		_build_single_player_upgrade_panel()

	upgrade_panel.visible = true
	_update_status()

func _prepare_upgrade_select() -> void:
	game_state = GameStateScript.UPGRADE_SELECT
	_heal_surviving_players_after_wave()
	_set_player_cooldowns_paused(true)
	_stop_ultimate()
	for slot in local_player_slots:
		slot["upgrades"] = []
		slot["selected"] = false
		slot["selection_pending"] = false
	_clear_upgrade_panel()
	start_next_wave_button.visible = false
	start_next_wave_button.disabled = true
	waiting_for_next_wave_input = false
	result_label.visible = false

@rpc("authority", "reliable")
func _network_begin_upgrade_select(upgrade_sets: Array) -> void:
	if network_mode != "client":
		return
	_clear_remaining_enemies()
	_prepare_upgrade_select()
	for slot_index in range(mini(local_player_slots.size(), upgrade_sets.size())):
		var upgrades: Array = upgrade_sets[slot_index] as Array
		local_player_slots[slot_index]["upgrades"] = upgrades.duplicate(true)
	_build_single_player_upgrade_panel(local_peer_player_index)
	upgrade_panel.visible = true
	_update_status()

func _start_next_wave_for_all_peers() -> void:
	if network_mode == "host":
		rpc("_network_start_next_wave")
	_start_next_wave()

@rpc("authority", "reliable")
func _network_start_next_wave() -> void:
	if network_mode != "client":
		return
	_start_next_wave()

func _heal_surviving_players_after_wave() -> void:
	for existing_player in players:
		if is_instance_valid(existing_player) and not existing_player.is_dead:
			existing_player.heal(WAVE_CLEAR_HEAL_AMOUNT)

func _build_single_player_upgrade_panel(player_index: int = 1) -> void:
	var panel_width: float = 1120.0
	var panel_height: float = 600.0
	_configure_upgrade_panel(panel_width, panel_height)
	var slot: Dictionary = _get_local_player_slot(player_index)
	var target_player: PlayerController = slot.get("player") as PlayerController
	var title: Label = Label.new()
	title.text = "%s · 选择升级" % _get_character_name(target_player.character_id if target_player != null else "warrior")
	title.custom_minimum_size = Vector2(panel_width, 0.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	upgrade_panel.add_child(title)

	var cards: HBoxContainer = HBoxContainer.new()
	cards.custom_minimum_size = Vector2(panel_width, 490)
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 20)
	upgrade_panel.add_child(cards)

	var upgrades: Array = slot.get("upgrades", [])
	for upgrade_value in upgrades:
		var upgrade: Dictionary = upgrade_value as Dictionary
		var button := _build_upgrade_card(upgrade, target_player, Vector2(340, 470))
		button.pressed.connect(_select_upgrade.bind(player_index, upgrade))
		cards.add_child(button)

func _configure_upgrade_panel(width: float, height: float) -> void:
	upgrade_panel.custom_minimum_size = Vector2(width, height)
	upgrade_panel.position = (_get_viewport_size() - upgrade_panel.custom_minimum_size) * 0.5

func _revive_dead_players_for_next_wave() -> void:
	var revive_position: Vector2 = _get_alive_players_center()
	for existing_player in players:
		if is_instance_valid(existing_player) and existing_player.is_dead:
			existing_player.global_position = revive_position + Vector2(randf_range(-42.0, 42.0), randf_range(-28.0, 28.0))
			existing_player.global_position = existing_player.global_position.clamp(ARENA_BOUNDS.position, ARENA_BOUNDS.end)
			existing_player.revive(GameRulesScript.REVIVE_HEALTH_RATIO)

func _build_upgrade_card(upgrade: Dictionary, target_player: PlayerController, card_size: Vector2) -> Button:
	var rarity: String = str(upgrade.get("rarity", "Common"))
	var accent := _get_upgrade_rarity_color(rarity)
	var button: Button = Button.new()
	button.custom_minimum_size = card_size
	button.clip_contents = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_upgrade_card_button(button, accent)

	var background: TextureRect = TextureRect.new()
	background.texture = load(str(UPGRADE_CARD_ART.get(rarity, UPGRADE_CARD_ART["Common"]))) as Texture2D
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.offset_left = 3
	background.offset_top = 3
	background.offset_right = -3
	background.offset_bottom = -3
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(background)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 9)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(content)

	var rarity_label: Label = Label.new()
	rarity_label.text = _format_rarity(rarity)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 16)
	rarity_label.add_theme_color_override("font_color", accent)
	rarity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(rarity_label)

	var badge_center: CenterContainer = CenterContainer.new()
	badge_center.custom_minimum_size = Vector2(0, 112)
	badge_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_center.add_child(_build_upgrade_card_badge(upgrade, accent))
	content.add_child(badge_center)

	var title: Label = Label.new()
	title.text = str(upgrade.get("title", "升级"))
	title.custom_minimum_size = Vector2(0, 54)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 21)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title)

	var separator: HSeparator = HSeparator.new()
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(separator)

	var description: Label = Label.new()
	description.text = str(upgrade.get("description", ""))
	description.custom_minimum_size = Vector2(0, 76)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 16)
	description.add_theme_color_override("font_color", Color(0.88, 0.90, 0.92, 1.0))
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(description)

	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(spacer)

	var current: Label = Label.new()
	current.text = "当前：%s" % _format_upgrade_current(upgrade, target_player)
	current.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	current.add_theme_font_size_override("font_size", 15)
	current.add_theme_color_override("font_color", Color(0.70, 0.84, 0.78, 1.0))
	current.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(current)
	return button

func _build_upgrade_card_badge(upgrade: Dictionary, accent: Color) -> Control:
	var size := Vector2(104, 104)
	var skill_slot: String = str(upgrade.get("skill_slot", ""))
	if not skill_slot.is_empty():
		var panel: PanelContainer = PanelContainer.new()
		panel.custom_minimum_size = size
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(0.025, 0.035, 0.05, 0.92)
		style.border_color = accent
		style.set_border_width_all(3)
		style.set_corner_radius_all(6)
		panel.add_theme_stylebox_override("panel", style)
		panel.clip_contents = true
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon: TextureRect = TextureRect.new()
		icon.texture = load(get_character_skill_icon_path(str(upgrade.get("character_id", "")), skill_slot)) as Texture2D
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(icon)
		var label: Label = Label.new()
		label.text = skill_slot.to_upper()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_outline_color", Color(0.015, 0.02, 0.035, 0.98))
		label.add_theme_constant_override("outline_size", 5)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(label)
		return panel
	var icon: TextureRect = TextureRect.new()
	icon.texture = load(_get_upgrade_stat_icon_path(str(upgrade.get("stat", "")))) as Texture2D
	icon.custom_minimum_size = size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon

func _get_upgrade_stat_icon_path(stat: String) -> String:
	if stat in ["max_health", "heal_percent", "lifesteal"]:
		return str(CHARACTER_STAT_ICONS["health"])
	if stat in ["move_speed", "dash_cooldown", "dash_charges"]:
		return str(CHARACTER_STAT_ICONS["speed"])
	if stat.ends_with("cooldown") or stat.ends_with("duration"):
		return str(CHARACTER_STAT_ICONS["cooldown"])
	return str(CHARACTER_STAT_ICONS["attack"])

func _get_upgrade_rarity_color(rarity: String) -> Color:
	match rarity:
		"Rare":
			return Color(0.32, 0.88, 1.0, 1.0)
		"Epic":
			return Color(1.0, 0.34, 0.28, 1.0)
		_:
			return Color(0.88, 0.90, 0.92, 1.0)

func _style_upgrade_card_button(button: Button, accent: Color) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.border_color = Color(0, 0, 0, 0)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(accent.r, accent.g, accent.b, 0.05)
	hover.border_color = accent
	hover.set_border_width_all(4)
	var pressed: StyleBoxFlat = hover.duplicate()
	pressed.bg_color = Color(accent.r, accent.g, accent.b, 0.10)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)

func _select_upgrade(player_index: int, upgrade: Dictionary) -> void:
	if game_state != GameStateScript.UPGRADE_SELECT:
		return
	var slot: Dictionary = _get_local_player_slot(player_index)
	if slot.is_empty() or bool(slot.get("selected", false)) or bool(slot.get("selection_pending", false)):
		return
	if _is_network_game():
		if player_index != local_peer_player_index:
			return
		var upgrades: Array = slot.get("upgrades", [])
		var upgrade_index := upgrades.find(upgrade)
		if not UpgradeManagerScript.is_valid_choice(upgrades, upgrade_index):
			return
		slot["selection_pending"] = true
		if network_mode == "host":
			_confirm_network_upgrade(player_index, upgrade_index)
		else:
			rpc_id(1, "_network_choose_upgrade", player_index, upgrade_index)
		return
	var target_player: PlayerController = slot.get("player") as PlayerController
	if target_player == null or not is_instance_valid(target_player):
		return
	target_player.record_upgrade_offer_result(slot.get("upgrades", []) as Array, str(upgrade.get("id", "")))
	target_player.apply_upgrade(upgrade)
	slot["selected"] = true
	if not _all_required_upgrades_selected():
		return
	upgrade_panel.visible = false
	start_next_wave_button.visible = false
	start_next_wave_button.disabled = true
	waiting_for_next_wave_input = true
	result_label.text = "按任意键开启下一波"
	result_label.visible = true

@rpc("any_peer", "reliable")
func _network_choose_upgrade(player_index: int, upgrade_index: int) -> void:
	if network_mode != "host":
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id == 1 or player_index != 2:
		return
	_confirm_network_upgrade(player_index, upgrade_index)

func _confirm_network_upgrade(player_index: int, upgrade_index: int) -> void:
	if network_mode != "host":
		return
	if not _apply_confirmed_network_upgrade(player_index, upgrade_index):
		return
	rpc("_network_confirm_upgrade", player_index, upgrade_index)
	if _all_required_upgrades_selected():
		_set_network_upgrades_ready()
		rpc("_network_upgrades_ready")

@rpc("authority", "reliable")
func _network_confirm_upgrade(player_index: int, upgrade_index: int) -> void:
	if network_mode != "client":
		return
	_apply_confirmed_network_upgrade(player_index, upgrade_index)

func _apply_confirmed_network_upgrade(player_index: int, upgrade_index: int) -> bool:
	var slot: Dictionary = _get_local_player_slot(player_index)
	if slot.is_empty() or bool(slot.get("selected", false)):
		return false
	var upgrades: Array = slot.get("upgrades", [])
	if not UpgradeManagerScript.is_valid_choice(upgrades, upgrade_index):
		return false
	var target_player: PlayerController = slot.get("player") as PlayerController
	if target_player == null or not is_instance_valid(target_player):
		return false
	target_player.record_upgrade_offer_result(upgrades, str((upgrades[upgrade_index] as Dictionary).get("id", "")))
	target_player.apply_upgrade(upgrades[upgrade_index] as Dictionary)
	slot["selected"] = true
	slot["selection_pending"] = false
	if player_index == local_peer_player_index:
		upgrade_panel.visible = false
		result_label.text = "等待另一名玩家选择升级"
		result_label.visible = true
	return true

func _set_network_upgrades_ready() -> void:
	upgrade_panel.visible = false
	start_next_wave_button.visible = false
	start_next_wave_button.disabled = true
	waiting_for_next_wave_input = true
	result_label.text = "等待房主开启下一波" if network_mode == "client" else "按任意键开启下一波"
	result_label.visible = true

@rpc("authority", "reliable")
func _network_upgrades_ready() -> void:
	if network_mode != "client":
		return
	_set_network_upgrades_ready()

func _all_required_upgrades_selected() -> bool:
	if local_player_slots.is_empty():
		return false
	for slot in local_player_slots:
		var target_player: PlayerController = slot.get("player") as PlayerController
		if target_player != null and is_instance_valid(target_player) and not bool(slot.get("selected", false)):
			return false
	return true

func _on_start_next_wave_pressed() -> void:
	if game_state != GameStateScript.UPGRADE_SELECT or not _all_required_upgrades_selected():
		return
	_start_next_wave_for_all_peers()

func _enter_victory() -> void:
	game_state = GameStateScript.VICTORY
	wave_time_left = 0.0
	_clear_remaining_enemies()
	_clear_effects()
	_position_result_panel()
	result_label.text = _format_result_text("胜利")
	result_label.visible = true
	restart_button.visible = true
	_update_status()

func _enter_defeat(reason: String = "失败") -> void:
	if game_state == GameStateScript.DEFEAT or game_state == GameStateScript.VICTORY:
		return
	game_state = GameStateScript.DEFEAT
	wave_time_left = 0.0
	_clear_remaining_enemies()
	_clear_effects()
	_position_result_panel()
	result_label.text = _format_result_text(reason)
	result_label.visible = true
	restart_button.visible = true
	_update_status()

func _on_restart_pressed() -> void:
	_clear_run_state()
	result_label.visible = false
	restart_button.visible = false
	_show_main_menu()

func _on_return_to_menu_pressed() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer = null
	network_mode = "none"
	network_peer_joined = false
	local_peer_player_index = 1
	_set_network_status("")
	_clear_run_state()
	result_label.visible = false
	restart_button.visible = false
	_show_main_menu()

func _position_result_panel() -> void:
	var viewport_size: Vector2 = _get_viewport_size()
	result_label.position = viewport_size * 0.5 + Vector2(-120.0, -112.0)
	restart_button.position = Vector2(
		(viewport_size.x - 184.0) * 0.5,
		viewport_size.y * 0.5 + 150.0
	)

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
	_clear_effects()
	for existing_player in players:
		if is_instance_valid(existing_player):
			existing_player.queue_free()
	players.clear()
	player = null
	player_two = null
	_clear_ultimate_states()
	for index in range(player_huds.size()):
		_assign_player_hud(index, null)
	local_player_slots.clear()
	persistent_skill_areas.clear()
	wave_manager.reset()
	wave_index = wave_manager.wave_index
	elapsed_time = 0.0
	wave_time_left = 0.0
	epic_upgrade_seen = false
	enemies_defeated = 0
	damage_dealt = 0.0
	damage_taken = 0.0
	local_player_count = 1
	var scaling: Dictionary = GameRulesScript.get_mode_scaling(local_player_count)
	minion_count_multiplier = float(scaling["minion_count"])
	enemy_health_multiplier = float(scaling["enemy_health"])
	enemy_damage_multiplier = float(scaling["enemy_damage"])
	boss_health_multiplier = float(scaling["boss_health"])
	boss_damage_multiplier = float(scaling["boss_damage"])
	start_next_wave_button.visible = false
	start_next_wave_button.disabled = true
	upgrade_panel.visible = false
	waiting_for_next_wave_input = false

func _stop_ultimate() -> void:
	combat_manager.stop_ultimates()

func _clear_ultimate_states() -> void:
	combat_manager.clear_ultimate_states()

func _clear_projectiles() -> void:
	if projectile_root == null:
		return
	for projectile in projectile_root.get_children():
		projectile.queue_free()

func _clear_effects() -> void:
	if effect_root == null:
		return
	_clear_persistent_skill_areas()
	for effect in effect_root.get_children():
		effect.queue_free()

func _clear_persistent_skill_areas() -> void:
	combat_manager.clear_persistent_skill_areas()

func _clear_upgrade_panel() -> void:
	for child in upgrade_panel.get_children():
		child.queue_free()

func _update_player_health_labels() -> void:
	player_roster.update_all_huds()

func _on_player_died() -> void:
	if game_state == GameStateScript.WAVE_ACTIVE or game_state == GameStateScript.BOSS_WAVE:
		if _all_players_dead():
			_enter_defeat()

func _update_status() -> void:
	status_label.text = "状态：%s" % _format_game_state(game_state)
	if _is_combat_active():
		wave_label.text = "波次：%d / %d　剩余：%d秒" % [
			clampi(wave_index + 1, 1, WAVE_DEFS.size()),
			WAVE_DEFS.size(),
			ceili(wave_time_left),
		]
	else:
		wave_label.text = "波次：%d / %d" % [
			clampi(wave_index + 1, 1, WAVE_DEFS.size()),
			WAVE_DEFS.size(),
		]
	enemies_label.text = "剩余敌人：%d" % enemies.size()
	_update_player_health_labels()

func _format_upgrade_button(upgrade: Dictionary, target_player: PlayerController = null) -> String:
	var stat: String = str(upgrade.get("stat", ""))
	var current_value: String = _format_upgrade_current(upgrade, target_player)
	return "%s\n%s\n当前：%s" % [
		upgrade["title"],
		upgrade["description"],
		current_value,
	]

func _format_upgrade_current(upgrade: Dictionary, target_player: PlayerController = null) -> String:
	if str(upgrade.get("stat", "")) == "behavior_upgrade":
		if target_player == null:
			return "未获得"
		return "等级 %d/%d" % [target_player.get_upgrade_level(str(upgrade.get("id", ""))), int(upgrade.get("max_level", 1))]
	return _format_player_stat(str(upgrade.get("stat", "")), target_player)

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
			return "Q %.2f秒 / E %.2f秒 / F %.1f秒" % [stat_player.skill_cooldown, stat_player.fan_skill_cooldown, stat_player.ultimate_cooldown]
		"attack_range":
			return "普攻范围 %.0f" % stat_player.attack_range
		"skill_damage":
			return "Q 伤害 %.1f" % stat_player.skill_damage
		"skill_range":
			return "Q 范围 %.0f" % stat_player.skill_length
		"fan_skill_damage":
			return "E 伤害 %.1f" % stat_player.fan_skill_damage
		"fan_skill_range":
			return "E 范围 %.0f" % stat_player.fan_skill_length
		"fan_skill_cooldown":
			return "E 冷却 %.2f秒" % stat_player.fan_skill_cooldown
		"ultimate_damage":
			return "F 伤害倍率 %.0f%%" % (stat_player.ultimate_damage_multiplier * 100.0)
		"ultimate_duration":
			return "F 持续 %.1f秒" % stat_player.ultimate_duration
		"ultimate_cooldown":
			return "F 冷却 %.1f秒" % stat_player.ultimate_cooldown
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
