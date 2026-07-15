extends Node2D

const GameStateScript := preload("res://scripts/core/game_state.gd")
const EnemyScript := preload("res://scripts/enemy/enemy_controller.gd")
const GameRulesScript := preload("res://scripts/gameplay/game_rules.gd")
const WaveManagerScript := preload("res://scripts/gameplay/wave_manager.gd")
const UpgradeManagerScript := preload("res://scripts/upgrades/upgrade_manager.gd")
const CombatManagerScript := preload("res://scripts/gameplay/combat_manager.gd")
const PlayerRosterScript := preload("res://scripts/player/player_roster.gd")
const AuthorityContractScript := preload("res://scripts/network/authority_contract.gd")
const VerdantUIThemeScript := preload("res://scripts/ui/verdant_ui_theme.gd")
const MainMenuUIScene := preload("res://scenes/ui/main_menu_ui.tscn")
const CharacterSelectUIScene := preload("res://scenes/ui/character_select_ui.tscn")
const CombatHUDUIScene := preload("res://scenes/ui/combat_hud_ui.tscn")
const UpgradeUIScene := preload("res://scenes/ui/upgrade_ui.tscn")
const ResultUIScene := preload("res://scenes/ui/result_ui.tscn")

const ARENA_BOUNDS := Rect2(Vector2(-960, -540), Vector2(1920, 1080))
const VIEWPORT_SIZE := Vector2(1280, 720)
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
const CHARACTER_CARD_ART_LEGACY := {
	"warrior": "res://assets/original/characters/warrior/warrior_card_v4.png",
	"archer": "res://assets/original/characters/archer/archer_card_v2.png",
	"lancer": "res://assets/original/characters/lancer/lancer_card_v2.png",
	"mage": "res://assets/original/characters/mage/mage_card_v2.png",
}
const CHARACTER_CARD_ART := {
	"warrior": "res://assets/original/characters/warrior/warrior_card_select_redraw_v1.png",
	"archer": "res://assets/original/characters/archer/archer_card_select_redraw_v1.png",
	"lancer": "res://assets/original/characters/lancer/lancer_card_select_redraw_v1.png",
	"mage": "res://assets/original/characters/mage/mage_card_select_redraw_v1.png",
}
const CHARACTER_CARD_ACCENTS := {
	"warrior": Color(0.95, 0.38, 0.42),
	"archer": Color(0.78, 0.32, 0.62),
	"lancer": Color(0.36, 0.76, 0.63),
	"mage": Color(0.66, 0.42, 0.90),
}
const CHARACTER_SKILL_ICONS := {
	"warrior": {
		"BASIC": "res://assets/ui/character_select/skills/warrior_basic.png",
		"DODGE": "res://assets/ui/character_select/skills/warrior_dodge.png",
		"SECONDARY": "res://assets/ui/character_select/skills/warrior_secondary.png",
		"Q": "res://assets/ui/character_select/skills/warrior_q.png",
		"E": "res://assets/ui/character_select/skills/warrior_e.png",
		"F": "res://assets/ui/character_select/skills/warrior_f.png",
	},
	"archer": {
		"BASIC": "res://assets/ui/character_select/skills/archer_basic.png",
		"DODGE": "res://assets/ui/character_select/skills/archer_dodge.png",
		"SECONDARY": "res://assets/ui/character_select/skills/archer_secondary.png",
		"Q": "res://assets/ui/character_select/skills/archer_q.png",
		"E": "res://assets/ui/character_select/skills/archer_e.png",
		"F": "res://assets/ui/character_select/skills/archer_f.png",
	},
	"lancer": {
		"BASIC": "res://assets/ui/character_select/skills/lancer_basic.png",
		"DODGE": "res://assets/ui/character_select/skills/lancer_dodge.png",
		"SECONDARY": "res://assets/ui/character_select/skills/lancer_secondary.png",
		"Q": "res://assets/ui/character_select/skills/lancer_q.png",
		"E": "res://assets/ui/character_select/skills/lancer_e.png",
		"F": "res://assets/ui/character_select/skills/lancer_f.png",
	},
	"mage": {
		"BASIC": "res://assets/ui/character_select/skills/mage_basic.png",
		"DODGE": "res://assets/ui/character_select/skills/mage_dodge.png",
		"SECONDARY": "res://assets/ui/character_select/skills/mage_secondary.png",
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
const NETWORK_SNAPSHOT_INTERVAL := 0.10

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
var network_snapshot_sequence := 0
var network_last_applied_snapshot := -1
var network_snapshot_time_left := 0.0
var network_next_enemy_id := 1

var player: PlayerController
var player_two: PlayerController
var players: Array[PlayerController] = []
var camera: Camera2D
var map_root: Node2D
var enemy_root: Node2D
var projectile_root: Node2D
var effect_root: Node2D
var ui_layer: CanvasLayer
var ui_root: Control
var main_menu_panel: PanelContainer
var main_menu_content: VBoxContainer
var network_ip_edit: LineEdit
var network_status_label: Label
var character_select_panel: PanelContainer
var character_select_content: VBoxContainer
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
var upgrade_panel: Control
var upgrade_content: VBoxContainer
var start_next_wave_button: Button
var result_panel: PanelContainer
var result_label: Label
var restart_button: Button
var return_to_menu_button: Button
var main_menu_ui
var character_select_ui
var combat_hud_ui
var upgrade_ui
var result_ui
var upgrade_ui_player_index := 1
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
	if _is_combat_active() and network_mode != "client":
		elapsed_time += delta
		wave_time_left = maxf(0.0, wave_time_left - delta)
		if wave_time_left <= 0.0:
			_enter_defeat("时间耗尽")
	if _is_network_game():
		_send_network_input()
		_update_network_authority(delta)
	_update_camera()
	_update_player_hud_occlusion(delta)
	_update_enemy_targets()
	if _is_combat_active():
		combat_manager.update_ultimates(delta)
		_update_persistent_skill_areas(delta)
	_update_status()
	if _is_combat_active() and network_mode != "client":
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
	ui_root = Control.new()
	ui_root.name = "VerdantUIRoot"
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.theme = VerdantUIThemeScript.build_theme()
	ui_layer.add_child(ui_root)

	combat_hud_ui = CombatHUDUIScene.instantiate()
	ui_root.add_child(combat_hud_ui)
	combat_hud_ui.next_wave_requested.connect(_on_start_next_wave_pressed)
	combat_hud_ui.return_to_menu_requested.connect(_on_return_to_menu_pressed)
	combat_hud_ui.create_player_hud(player_roster)
	hud_left = combat_hud_ui.hud_left
	hud_right = combat_hud_ui.hud_right
	status_label = combat_hud_ui.status_label
	wave_label = combat_hud_ui.wave_label
	enemies_label = combat_hud_ui.enemies_label
	player_hud = combat_hud_ui.player_hud
	start_next_wave_button = combat_hud_ui.start_next_wave_button
	return_to_menu_button = combat_hud_ui.return_to_menu_button

	main_menu_ui = MainMenuUIScene.instantiate()
	ui_root.add_child(main_menu_ui)
	main_menu_ui.single_player_requested.connect(_start_single_player)
	main_menu_ui.host_requested.connect(_start_network_host)
	main_menu_ui.join_requested.connect(_start_network_client)
	main_menu_panel = main_menu_ui
	main_menu_content = main_menu_ui.content
	network_ip_edit = main_menu_ui.network_ip_edit
	network_status_label = main_menu_ui.network_status_label

	character_select_ui = CharacterSelectUIScene.instantiate()
	ui_root.add_child(character_select_ui)
	character_select_ui.active_slot_requested.connect(_set_character_select_active_slot)
	character_select_ui.character_requested.connect(_select_active_character)
	character_select_ui.start_requested.connect(_confirm_character_select)
	character_select_panel = character_select_ui
	character_select_content = character_select_ui.content

	upgrade_ui = UpgradeUIScene.instantiate()
	ui_root.add_child(upgrade_ui)
	upgrade_ui.setup(UPGRADE_CARD_ART, CHARACTER_STAT_ICONS, _format_upgrade_current, get_character_skill_icon_path)
	upgrade_ui.upgrade_selected.connect(_on_upgrade_ui_selected)
	upgrade_panel = upgrade_ui
	upgrade_content = upgrade_ui.content

	result_ui = ResultUIScene.instantiate()
	ui_root.add_child(result_ui)
	result_ui.restart_requested.connect(_on_restart_pressed)
	result_panel = result_ui.panel
	result_label = result_ui.result_label
	restart_button = result_ui.restart_button

	_layout_ui()
	_update_status()

func _get_viewport_size() -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return VIEWPORT_SIZE
	return viewport_size

func _layout_ui() -> void:
	var viewport_size: Vector2 = _get_viewport_size()
	if combat_hud_ui != null:
		combat_hud_ui.layout(viewport_size)
	if main_menu_panel != null:
		main_menu_panel.position = (viewport_size - main_menu_panel.custom_minimum_size) * 0.5
	if character_select_panel != null:
		character_select_panel.position = (viewport_size - character_select_panel.custom_minimum_size) * 0.5
	if upgrade_ui != null:
		upgrade_ui.layout(viewport_size)
	if result_ui != null:
		result_ui.layout(viewport_size)

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

func _show_main_menu() -> void:
	game_state = GameStateScript.LOBBY
	if result_ui != null:
		result_ui.hide_result()
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
	if main_menu_ui != null:
		main_menu_ui.set_status(text)
	elif network_status_label != null:
		network_status_label.text = text

@rpc("authority", "reliable")
func _network_enter_room(character_ids: Array) -> void:
	selected_character_ids = character_ids.duplicate()
	_show_character_select(2)

@rpc("any_peer", "reliable")
func _network_set_character(player_index: int, character_id: String) -> void:
	if player_index < 1 or player_index > 2 or not CHARACTER_CONFIGS.has(character_id):
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if network_mode == "host" and sender_id != 0 and (sender_id != 2 or player_index != 2):
		return
	if network_mode == "client" and sender_id != 1:
		return
	selected_character_ids[player_index - 1] = character_id
	if network_mode == "host":
		rpc("_network_set_character", player_index, character_id)
	_refresh_character_select_buttons()

@rpc("authority", "reliable")
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
	if _is_network_game():
		character_select_active_slot = local_peer_player_index - 1
	else:
		character_select_active_slot = clampi(character_select_active_slot, 0, pending_player_count - 1)
	character_select_ui.rebuild(_get_character_select_ui_context())
	character_select_rows = character_select_ui.rows
	character_select_slot_buttons = character_select_ui.slot_buttons
	character_select_start_button = character_select_ui.start_button

func _get_character_select_ui_context() -> Dictionary:
	return {
		"player_count": pending_player_count,
		"is_network": _is_network_game(),
		"local_peer_index": local_peer_player_index,
		"network_status": network_status_text,
		"network_mode": network_mode,
		"peer_joined": network_peer_joined,
		"active_slot": character_select_active_slot,
		"selected_ids": selected_character_ids.duplicate(),
		"character_order": CHARACTER_ORDER,
		"character_configs": CHARACTER_CONFIGS,
		"card_art": CHARACTER_CARD_ART,
		"card_accents": CHARACTER_CARD_ACCENTS,
		"skill_icons": CHARACTER_SKILL_ICONS,
		"stat_icons": CHARACTER_STAT_ICONS,
	}

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
	if character_select_ui == null:
		return
	character_select_ui.refresh(_get_character_select_ui_context())

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
	if result_ui != null:
		result_ui.hide_result()
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
	network_snapshot_sequence = 0
	network_last_applied_snapshot = -1
	network_snapshot_time_left = 0.0
	network_next_enemy_id = 1
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
	if network_mode != "client" or multiplayer.multiplayer_peer == null:
		return
	var local_player := _get_network_local_player()
	if local_player == null or not is_instance_valid(local_player):
		return
	rpc_id(1, "_receive_player_input", local_peer_player_index, local_player.make_input_packet())

@rpc("any_peer", "unreliable")
func _receive_player_input(player_index: int, packet: Dictionary) -> void:
	if network_mode != "host" or multiplayer.get_remote_sender_id() != 2 or player_index != 2:
		return
	var target_player := _get_network_player(player_index)
	if target_player == null or not is_instance_valid(target_player):
		return
	var authoritative_packet := packet.duplicate(true)
	authoritative_packet.erase("position")
	target_player.apply_external_input(authoritative_packet)

func _update_network_authority(delta: float) -> void:
	if network_mode != "host" or not network_peer_joined or players.is_empty():
		return
	network_snapshot_time_left -= delta
	if network_snapshot_time_left > 0.0:
		return
	network_snapshot_time_left += NETWORK_SNAPSHOT_INTERVAL
	network_snapshot_sequence += 1
	rpc("_network_receive_authority_snapshot", _build_authority_snapshot())

func _build_authority_snapshot() -> Dictionary:
	var player_states: Array = []
	for player_index in range(players.size()):
		var target_player := players[player_index] as PlayerController
		if target_player == null or not is_instance_valid(target_player):
			continue
		player_states.append(AuthorityContractScript.make_player_state(
			player_index + 1,
			target_player.global_position,
			target_player.health,
			target_player.max_health,
			target_player.is_dead,
			target_player.make_authority_cooldowns()
		))
	var enemy_states: Array = []
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy_states.append(enemy.make_authority_state())
	return AuthorityContractScript.make_snapshot(
		network_snapshot_sequence,
		game_state,
		wave_index,
		player_states,
		enemy_states,
		wave_time_left,
		elapsed_time,
		{"enemies_defeated": enemies_defeated, "damage_dealt": damage_dealt, "damage_taken": damage_taken}
	)

@rpc("authority", "unreliable_ordered")
func _network_receive_authority_snapshot(snapshot: Dictionary) -> void:
	if network_mode != "client":
		return
	_apply_authority_snapshot(snapshot)

func _apply_authority_snapshot(snapshot: Dictionary) -> bool:
	if not AuthorityContractScript.validate_snapshot(snapshot):
		return false
	var sequence := int(snapshot.get("sequence", -1))
	if sequence <= network_last_applied_snapshot:
		return false
	network_last_applied_snapshot = sequence
	wave_index = int(snapshot.get("wave_index", wave_index))
	wave_time_left = maxf(0.0, float(snapshot.get("wave_time_left", wave_time_left)))
	elapsed_time = maxf(0.0, float(snapshot.get("elapsed_time", elapsed_time)))
	var authority_phase := str(snapshot.get("phase", game_state))
	if authority_phase == GameStateScript.VICTORY and game_state != GameStateScript.VICTORY:
		_enter_victory()
	elif authority_phase == GameStateScript.DEFEAT and game_state != GameStateScript.DEFEAT:
		_enter_defeat("房主判定失败")
	elif authority_phase in [GameStateScript.WAVE_ACTIVE, GameStateScript.BOSS_WAVE, GameStateScript.COUNTDOWN]:
		game_state = authority_phase
	for player_state in snapshot.get("players", []) as Array:
		var target_player := _get_network_player(int((player_state as Dictionary).get("player_id", 0)))
		if target_player != null and is_instance_valid(target_player):
			target_player.apply_authority_state(player_state as Dictionary)
	_apply_authority_enemy_states(snapshot.get("enemies", []) as Array)
	var metrics: Dictionary = snapshot.get("metrics", {}) as Dictionary
	enemies_defeated = int(metrics.get("enemies_defeated", enemies_defeated))
	damage_dealt = float(metrics.get("damage_dealt", damage_dealt))
	damage_taken = float(metrics.get("damage_taken", damage_taken))
	return true

func _apply_authority_enemy_states(enemy_states: Array) -> void:
	var existing_by_id := {}
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.network_id > 0:
			existing_by_id[enemy.network_id] = enemy
	var authority_ids := {}
	for state in enemy_states:
		var enemy_state := state as Dictionary
		var enemy_id := int(enemy_state.get("enemy_id", -1))
		authority_ids[enemy_id] = true
		var enemy: EnemyController = existing_by_id.get(enemy_id) as EnemyController
		if enemy == null or not is_instance_valid(enemy):
			enemy = _create_enemy_from_authority_state(enemy_state)
		enemy.apply_authority_state(enemy_state)
	for enemy in enemies.duplicate():
		if is_instance_valid(enemy) and not authority_ids.has(enemy.network_id):
			enemies.erase(enemy)
			enemy.queue_free()

func _create_enemy_from_authority_state(state: Dictionary) -> EnemyController:
	var enemy: EnemyController = EnemyScript.new()
	var enemy_type := str(state.get("enemy_type", "melee"))
	if enemy_type == "boss":
		enemy.setup_as_boss()
		_tune_boss_for_mode(enemy)
	else:
		_setup_wave_enemy(enemy, enemy_type)
	_register_enemy(enemy, int(state.get("enemy_id", -1)))
	return enemy

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
	if combat_hud_ui != null:
		combat_hud_ui.set_combat_visible(true)
	if return_to_menu_button != null:
		return_to_menu_button.visible = true
	start_next_wave_button.visible = false
	start_next_wave_button.disabled = true
	result_ui.hide_result()
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

func _register_enemy(enemy: EnemyController, authority_enemy_id: int = -1) -> void:
	if authority_enemy_id > 0:
		enemy.network_id = authority_enemy_id
		network_next_enemy_id = maxi(network_next_enemy_id, authority_enemy_id + 1)
	else:
		enemy.network_id = network_next_enemy_id
		network_next_enemy_id += 1
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
	if network_mode == "client":
		enemies.erase(enemy)
		return
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
	result_panel.visible = true
	var timer: SceneTreeTimer = get_tree().create_timer(1.0)
	timer.timeout.connect(func() -> void:
		if game_state == GameStateScript.COUNTDOWN and enemies.is_empty():
			result_panel.visible = false
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

func _add_textured_effect(root: Node2D, texture: Texture2D, diameter: float, position: Vector2 = Vector2.ZERO, tint: Color = Color.WHITE, node_name: String = "TexturedEffect") -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.position = position
	sprite.modulate = tint
	var texture_width := maxf(float(texture.get_width()), 1.0)
	sprite.scale = Vector2.ONE * (diameter / texture_width)
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sprite.material = material
	root.add_child(sprite)
	return sprite

func _spawn_textured_effect(origin: Vector2, texture: Texture2D, diameter: float, lifetime: float, node_name: String = "TexturedEffect") -> void:
	var sprite := _add_textured_effect(effect_root, texture, diameter, origin, Color.WHITE, node_name)
	var final_scale := sprite.scale * 1.12
	sprite.scale *= 0.72
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", final_scale, lifetime)
	tween.tween_property(sprite, "modulate:a", 0.0, lifetime)
	tween.finished.connect(Callable(sprite, "queue_free"))

func _animate_effect_rotation(sprite: Sprite2D, duration: float, clockwise: bool) -> void:
	var tween := sprite.create_tween().set_loops()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(sprite, "rotation", TAU if clockwise else -TAU, maxf(duration, 0.05)).from(0.0)

func _animate_effect_pulse(sprite: Sprite2D, minimum_alpha: float, maximum_alpha: float, duration: float) -> void:
	sprite.modulate.a = maximum_alpha
	var tween := sprite.create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "modulate:a", minimum_alpha, maxf(duration * 0.5, 0.05))
	tween.tween_property(sprite, "modulate:a", maximum_alpha, maxf(duration * 0.5, 0.05))

func _spawn_inward_streaks(origin: Vector2, radius: float, color: Color, count: int, lifetime: float) -> void:
	var root := Node2D.new()
	root.name = "WarriorQInwardStreaks"
	effect_root.add_child(root)
	for index in range(count):
		var angle := TAU * float(index) / float(maxi(count, 1))
		var direction := Vector2(cos(angle), sin(angle))
		var streak := Line2D.new()
		streak.width = 3.0
		streak.default_color = color
		streak.position = origin + direction * radius
		streak.points = PackedVector2Array([-direction * 16.0, direction * 4.0])
		root.add_child(streak)
		var tween := streak.create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(streak, "position", origin + direction * 10.0, lifetime)
		tween.tween_property(streak, "modulate:a", 0.0, lifetime)
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(Callable(root, "queue_free"))

func _spawn_spark_burst(origin: Vector2, color: Color, count: int, distance: float, lifetime: float) -> void:
	var root := Node2D.new()
	root.name = "SparkBurst"
	effect_root.add_child(root)
	for index in range(count):
		var angle := TAU * float(index) / float(maxi(count, 1)) + randf_range(-0.16, 0.16)
		var direction := Vector2(cos(angle), sin(angle))
		var spark := Line2D.new()
		spark.width = randf_range(2.0, 4.0)
		spark.default_color = color
		spark.position = origin
		spark.points = PackedVector2Array([Vector2.ZERO, direction * randf_range(7.0, 14.0)])
		root.add_child(spark)
		var tween := spark.create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(spark, "position", origin + direction * randf_range(distance * 0.72, distance), lifetime)
		tween.tween_property(spark, "modulate:a", 0.0, lifetime)
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(Callable(root, "queue_free"))

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

func _spawn_lancer_sweep_effect(origin: Vector2, direction: Vector2, length: float, half_width: float, texture: Texture2D) -> void:
	var forward: Vector2 = direction.normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.RIGHT
	var side_axis: Vector2 = Vector2(-forward.y, forward.x)
	var root := Node2D.new()
	root.name = "LancerSweep"
	effect_root.add_child(root)
	var slash: Sprite2D = _add_textured_effect(root, texture, maxf(length * 1.65, half_width * 1.75), origin + forward * length * 0.44, Color.WHITE, "LancerSweepTexture")
	slash.rotation = forward.angle() - 0.72
	var slash_scale := slash.scale
	slash.scale *= 0.72
	var slash_tween := slash.create_tween().set_parallel(true)
	slash_tween.set_trans(Tween.TRANS_QUAD)
	slash_tween.set_ease(Tween.EASE_OUT)
	slash_tween.tween_property(slash, "scale", slash_scale * 1.08, 0.18)
	slash_tween.tween_property(slash, "modulate:a", 0.0, 0.18)
	for side in [-1.0, 0.0, 1.0]:
		var line: Line2D = Line2D.new()
		line.position = origin
		line.width = 5.0
		line.default_color = Color(0.65, 0.92, 1.0, 0.48)
		line.points = PackedVector2Array([
			side_axis * half_width * side * 0.45,
			forward * length + side_axis * half_width * side,
		])
		root.add_child(line)
		var line_tween := line.create_tween()
		line_tween.tween_property(line, "modulate:a", 0.0, 0.14)
	var timer: SceneTreeTimer = get_tree().create_timer(0.19)
	timer.timeout.connect(Callable(root, "queue_free"))
	_spawn_spark_burst(origin + forward * length * 0.72, Color(0.70, 0.96, 1.0, 0.92), 9, half_width * 0.72, 0.16)

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
	if combat_hud_ui != null:
		combat_hud_ui.set_combat_visible(false)
	if return_to_menu_button != null:
		return_to_menu_button.visible = false
	start_next_wave_button.visible = false
	start_next_wave_button.disabled = true
	waiting_for_next_wave_input = false
	result_ui.hide_result()

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
	var slot: Dictionary = _get_local_player_slot(player_index)
	var target_player: PlayerController = slot.get("player") as PlayerController
	upgrade_ui_player_index = player_index
	upgrade_ui.show_options(
		"%s · 选择升级" % _get_character_name(target_player.character_id if target_player != null else "warrior"),
		slot.get("upgrades", []),
		target_player,
		_get_viewport_size()
	)

func _on_upgrade_ui_selected(upgrade: Dictionary) -> void:
	_select_upgrade(upgrade_ui_player_index, upgrade)

func _revive_dead_players_for_next_wave() -> void:
	var revive_position: Vector2 = _get_alive_players_center()
	for existing_player in players:
		if is_instance_valid(existing_player) and existing_player.is_dead:
			existing_player.global_position = revive_position + Vector2(randf_range(-42.0, 42.0), randf_range(-28.0, 28.0))
			existing_player.global_position = existing_player.global_position.clamp(ARENA_BOUNDS.position, ARENA_BOUNDS.end)
			existing_player.revive(GameRulesScript.REVIVE_HEALTH_RATIO)

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
	result_panel.visible = true

@rpc("any_peer", "reliable")
func _network_choose_upgrade(player_index: int, upgrade_index: int) -> void:
	if network_mode != "host":
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id != 2 or player_index != 2:
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
		result_panel.visible = true
	return true

func _set_network_upgrades_ready() -> void:
	upgrade_panel.visible = false
	start_next_wave_button.visible = false
	start_next_wave_button.disabled = true
	waiting_for_next_wave_input = true
	result_label.text = "等待房主开启下一波" if network_mode == "client" else "按任意键开启下一波"
	result_panel.visible = true

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
	result_ui.show_result(_format_result_text("胜利"), _get_viewport_size())
	_update_status()

func _enter_defeat(reason: String = "失败") -> void:
	if game_state == GameStateScript.DEFEAT or game_state == GameStateScript.VICTORY:
		return
	game_state = GameStateScript.DEFEAT
	wave_time_left = 0.0
	_clear_remaining_enemies()
	_clear_effects()
	result_ui.show_result(_format_result_text(reason), _get_viewport_size())
	_update_status()

func _on_restart_pressed() -> void:
	_clear_run_state()
	result_ui.hide_result()
	_show_main_menu()

func _on_return_to_menu_pressed() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer = null
	network_mode = "none"
	network_peer_joined = false
	local_peer_player_index = 1
	_set_network_status("")
	_clear_run_state()
	result_ui.hide_result()
	_show_main_menu()

func _position_result_panel() -> void:
	if result_ui != null:
		result_ui.layout(_get_viewport_size())

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
	network_snapshot_sequence = 0
	network_last_applied_snapshot = -1
	network_snapshot_time_left = 0.0
	network_next_enemy_id = 1
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
	if upgrade_ui != null:
		upgrade_ui.clear_options()

func _update_player_health_labels() -> void:
	player_roster.update_all_huds()

func _on_player_died() -> void:
	if network_mode != "client" and (game_state == GameStateScript.WAVE_ACTIVE or game_state == GameStateScript.BOSS_WAVE):
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
