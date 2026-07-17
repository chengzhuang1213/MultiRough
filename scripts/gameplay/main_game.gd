extends Node2D

const GameStateScript := preload("res://scripts/core/game_state.gd")
const EnemyScript := preload("res://scripts/enemy/enemy_controller.gd")
const GameRulesScript := preload("res://scripts/gameplay/game_rules.gd")
const WaveManagerScript := preload("res://scripts/gameplay/wave_manager.gd")
const UpgradeManagerScript := preload("res://scripts/upgrades/upgrade_manager.gd")
const UpgradeSessionScript := preload("res://scripts/upgrades/upgrade_session.gd")
const UpgradeCatalogScript := preload("res://scripts/upgrades/upgrade_catalog.gd")
const EnemyArchetypesScript := preload("res://scripts/enemy/enemy_archetypes.gd")
const CombatManagerScript := preload("res://scripts/gameplay/combat_manager.gd")
const MapBuilderScript := preload("res://scripts/gameplay/map_builder.gd")
const RestArenaScript := preload("res://scripts/gameplay/rest_arena.gd")
const EffectManagerScript := preload("res://scripts/gameplay/effect_manager.gd")
const WaveSpawnerScript := preload("res://scripts/gameplay/wave_spawner.gd")
const InputSetupScript := preload("res://scripts/input/input_setup.gd")
const PlayerRosterScript := preload("res://scripts/player/player_roster.gd")
const AuthoritySyncScript := preload("res://scripts/network/authority_sync.gd")
const CampaignSatchelUIThemeScript := preload("res://scripts/ui/campaign_satchel_ui_theme.gd")
const MainMenuUIScene := preload("res://scenes/ui/main_menu_ui.tscn")
const CharacterSelectUIScene := preload("res://scenes/ui/character_select_ui.tscn")
const CombatHUDUIScene := preload("res://scenes/ui/combat_hud_ui.tscn")
const UpgradeUIScene := preload("res://scenes/ui/upgrade_ui.tscn")
const RestUIScene := preload("res://scenes/ui/rest_ui.tscn")
const ResultUIScene := preload("res://scenes/ui/result_ui.tscn")

const ARENA_BOUNDS := Rect2(Vector2(-960, -540), Vector2(1920, 1080))
const VIEWPORT_SIZE := Vector2(1280, 720)
const MAP_VIEW_MARGIN := 160.0
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
	"Common": "res://assets/ui/theme/campaign_satchel/upgrade_card_common.png",
	"Rare": "res://assets/ui/theme/campaign_satchel/upgrade_card_rare.png",
	"Epic": "res://assets/ui/theme/campaign_satchel/upgrade_card_epic.png",
}
const CHARACTER_CONFIGS := GameRulesScript.CHARACTER_CONFIGS
const NETWORK_SNAPSHOT_INTERVAL := 0.10
const UPGRADE_SELECTION_INPUT_LOCK_TIME := 1.0
const ENEMY_DISPLAY_NAMES := {
	"melee": "近战兵", "heavy": "重装兵", "ranged": "远程兵", "shield": "盾卫",
	"charger": "冲锋者", "bomber": "爆破者", "priest": "祭司",
	"mini_boss": "紫晶统领", "boss": "最终首领",
}
const ENEMY_SKILL_INTEL := {
	"melee": "近身攻击；第7波起低血量进入血性狂怒",
	"heavy": "高伤害近战；第7波起周期性预警震地",
	"ranged": "保持距离射击；第7波起连续射击后侧移",
	"shield": "正面仅承受30%伤害，需要绕后",
	"charger": "预警后沿直线高速突进",
	"bomber": "接近目标后预警自爆",
	"priest": "周期治疗范围内受伤友军",
	"mini_boss": "周期范围攻击；半血短暂无敌并进入狂暴；不会召唤援军",
	"boss": "阶段锁血、范围攻击、援军、狂暴与低血量绝境攻击",
}

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
var upgrade_selection_input_lock_left := 0.0
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
var network_next_visual_event_id := 1
var network_last_visual_event_id := 0
var network_next_enemy_id := 1
var network_next_combat_entity_id := 1
var network_return_confirmation_requester := 0

var player: PlayerController
var player_two: PlayerController
var players: Array[PlayerController] = []
var camera: Camera2D
var map_root: Node2D
var rest_arena: Node2D
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
var rest_ui
var result_ui
var upgrade_ui_player_index := 1
var combat_manager
var player_roster
var authority_sync
var map_builder
var effect_manager
var wave_spawner
var rest_ready_players: Dictionary = {}
var rest_saved_player_cooldowns: Dictionary = {}

func _ready() -> void:
	randomize()
	combat_manager = CombatManagerScript.new(self)
	player_roster = PlayerRosterScript.new(self, combat_manager)
	authority_sync = AuthoritySyncScript.new(self)
	map_builder = MapBuilderScript.new(self)
	effect_manager = EffectManagerScript.new(self)
	wave_spawner = WaveSpawnerScript.new(self)
	_ensure_input_map()
	_build_world()
	_build_ui()
	get_viewport().size_changed.connect(_layout_ui)
	_show_main_menu()

func _input(event: InputEvent) -> void:
	if _try_start_next_wave_from_input(event):
		return
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
	_try_start_next_wave_from_input(event)

func _try_start_next_wave_from_input(event: InputEvent) -> bool:
	if not waiting_for_next_wave_input:
		return false
	if game_state != GameStateScript.UPGRADE_SELECT or not _all_required_upgrades_selected():
		return false
	if network_mode == "client":
		return false
	var keyboard_confirm: bool = event is InputEventKey and event.pressed and not event.echo
	var left_click_confirm: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if not keyboard_confirm and not left_click_confirm:
		return false
	get_viewport().set_input_as_handled()
	_start_next_wave_for_all_peers()
	return true

func _ensure_input_map() -> void:
	InputSetupScript.ensure_default_actions()

func _process(delta: float) -> void:
	if upgrade_selection_input_lock_left > 0.0:
		upgrade_selection_input_lock_left = maxf(0.0, upgrade_selection_input_lock_left - delta)
		if upgrade_selection_input_lock_left <= 0.0 and upgrade_ui != null:
			upgrade_ui.set_selection_enabled(true)
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
	if network_mode != "client":
		_update_enemy_targets()
	if _is_player_action_active() and network_mode != "client":
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
	rest_arena = RestArenaScript.new()
	rest_arena.name = "RestArena"
	rest_arena.visible = false
	add_child(rest_arena)

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
	ui_root.theme = CampaignSatchelUIThemeScript.build_theme()
	ui_layer.add_child(ui_root)

	combat_hud_ui = CombatHUDUIScene.instantiate()
	ui_root.add_child(combat_hud_ui)
	combat_hud_ui.next_wave_requested.connect(_on_start_next_wave_pressed)
	combat_hud_ui.return_confirmation_open_requested.connect(_on_return_confirmation_open_requested)
	combat_hud_ui.return_confirmation_cancel_requested.connect(_on_return_confirmation_cancel_requested)
	combat_hud_ui.return_to_menu_requested.connect(_on_return_confirmation_confirmed)
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

	rest_ui = RestUIScene.instantiate()
	ui_root.add_child(rest_ui)
	rest_ui.ready_pressed.connect(_on_rest_ready_pressed)

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
	if rest_ui != null:
		rest_ui.layout(viewport_size)
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
	if combat_hud_ui != null and combat_hud_ui.return_confirmation_overlay.visible:
		combat_hud_ui.hide_return_confirmation(true)
	network_return_confirmation_requester = 0
	game_state = GameStateScript.LOBBY
	if result_ui != null:
		result_ui.hide_result()
	if main_menu_panel != null:
		main_menu_panel.visible = true
	if character_select_panel != null:
		character_select_panel.visible = false
	if rest_ui != null:
		rest_ui.hide_rest()
	_set_main_map_active(true)
	if rest_arena != null:
		rest_arena.visible = false
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
	if combat_hud_ui != null:
		combat_hud_ui.hide_return_confirmation(true)
	network_return_confirmation_requester = 0
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

@rpc("any_peer", "call_remote", "reliable")
func _network_request_return_confirmation(action: String) -> void:
	if network_mode != "host" or multiplayer.get_remote_sender_id() != 2:
		return
	_handle_host_return_confirmation_action(action, 2)

@rpc("authority", "call_remote", "reliable")
func _network_set_return_confirmation(open: bool, requester_index: int, confirmed: bool = false) -> void:
	if network_mode != "client":
		return
	_apply_return_confirmation_state(open, requester_index)
	if confirmed and requester_index == local_peer_player_index:
		call_deferred("_on_return_to_menu_pressed")

func _on_return_confirmation_open_requested() -> void:
	if network_mode == "none":
		_apply_return_confirmation_state(true, local_peer_player_index)
		return
	if network_mode == "host":
		_handle_host_return_confirmation_action("open", 1)
		return
	if multiplayer.multiplayer_peer != null:
		rpc_id(1, "_network_request_return_confirmation", "open")

func _on_return_confirmation_cancel_requested() -> void:
	if network_mode == "none":
		_apply_return_confirmation_state(false, local_peer_player_index)
		return
	if network_mode == "host":
		_handle_host_return_confirmation_action("cancel", 1)
		return
	if multiplayer.multiplayer_peer != null:
		rpc_id(1, "_network_request_return_confirmation", "cancel")

func _on_return_confirmation_confirmed() -> void:
	if network_mode == "none":
		_apply_return_confirmation_state(false, local_peer_player_index, true)
		_on_return_to_menu_pressed()
		return
	if network_mode == "host":
		_handle_host_return_confirmation_action("confirm", 1)
		return
	if multiplayer.multiplayer_peer != null:
		rpc_id(1, "_network_request_return_confirmation", "confirm")

func _handle_host_return_confirmation_action(action: String, requester_index: int) -> void:
	if network_mode != "host" or requester_index < 1 or requester_index > 2:
		return
	match action:
		"open":
			if network_return_confirmation_requester != 0:
				return
			network_return_confirmation_requester = requester_index
			_apply_return_confirmation_state(true, requester_index)
			_broadcast_return_confirmation(true, requester_index)
		"cancel", "confirm":
			if network_return_confirmation_requester != requester_index:
				return
			var confirmed := action == "confirm"
			network_return_confirmation_requester = 0
			_apply_return_confirmation_state(false, requester_index, true)
			_broadcast_return_confirmation(false, requester_index, confirmed)
			if confirmed and requester_index == 1:
				call_deferred("_on_return_to_menu_pressed")

func _broadcast_return_confirmation(open: bool, requester_index: int, confirmed: bool = false) -> void:
	if multiplayer.multiplayer_peer != null and network_peer_joined:
		rpc("_network_set_return_confirmation", open, requester_index, confirmed)

func _apply_return_confirmation_state(open: bool, requester_index: int, force_unpause: bool = false) -> void:
	if combat_hud_ui == null:
		return
	if open:
		combat_hud_ui.show_return_confirmation(requester_index == local_peer_player_index)
	else:
		combat_hud_ui.hide_return_confirmation(force_unpause)

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
	network_next_visual_event_id = 1
	network_last_visual_event_id = 0
	network_next_enemy_id = 1
	network_next_combat_entity_id = 1
	rest_ready_players.clear()
	rest_saved_player_cooldowns.clear()
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
		player.authority_presentation_only = network_mode == "client" and local_peer_player_index != 1
		player.network_local_prediction_enabled = network_mode == "client" and local_peer_player_index == 1
		player.use_mouse_aim = local_peer_player_index == 1
		if local_peer_player_index == 1:
			player.basic_attack_action = "network_basic_attack"
	if player_two != null:
		player_two.external_input_enabled = local_peer_player_index != 2
		player_two.authority_presentation_only = network_mode == "client" and local_peer_player_index != 2
		player_two.network_local_prediction_enabled = network_mode == "client" and local_peer_player_index == 2
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

func _has_combat_authority() -> bool:
	return network_mode != "client"

func allocate_combat_entity_id() -> int:
	var entity_id := network_next_combat_entity_id
	network_next_combat_entity_id += 1
	return entity_id

func get_player_network_id(target_player: PlayerController) -> int:
	for index in range(players.size()):
		if players[index] == target_player:
			return index + 1
	return 0

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
	return authority_sync.build_snapshot()

@rpc("authority", "call_remote", "unreliable_ordered", 1)
func _network_receive_authority_snapshot(snapshot: Dictionary) -> void:
	if network_mode != "client":
		return
	_apply_authority_snapshot(snapshot)

func _broadcast_enemy_telegraph(shape: String, payload: Dictionary) -> void:
	if network_mode == "host":
		rpc("_network_show_enemy_telegraph", shape, payload)

func _broadcast_combat_visual(event_type: String, payload: Dictionary) -> void:
	if network_mode != "host" or not network_peer_joined or multiplayer.multiplayer_peer == null:
		return
	var event_id := network_next_visual_event_id
	network_next_visual_event_id += 1
	rpc("_network_show_combat_visual", event_id, event_type, payload)

@rpc("authority", "call_remote", "reliable", 2)
func _network_show_combat_visual(event_id: int, event_type: String, payload: Dictionary) -> void:
	if network_mode != "client" or event_id <= network_last_visual_event_id:
		return
	network_last_visual_event_id = event_id
	combat_manager.show_network_visual_event(event_type, payload)

@rpc("authority", "call_remote", "reliable")
func _network_show_enemy_telegraph(shape: String, payload: Dictionary) -> void:
	if network_mode != "client":
		return
	_show_enemy_telegraph(shape, payload)

func _show_enemy_telegraph(shape: String, payload: Dictionary) -> void:
	if shape == "line":
		_spawn_line_skill_effect(
			payload.get("origin", Vector2.ZERO) as Vector2,
			payload.get("direction", Vector2.RIGHT) as Vector2,
			float(payload.get("length", 0.0)),
			payload.get("color", Color.WHITE) as Color,
			float(payload.get("lifetime", 0.1))
		)
		return
	if shape == "ring":
		_spawn_ring_effect(
			payload.get("origin", Vector2.ZERO) as Vector2,
			float(payload.get("radius", 0.0)),
			payload.get("color", Color.WHITE) as Color,
			float(payload.get("lifetime", 0.1))
		)
		return
	_spawn_effect(
		payload.get("origin", Vector2.ZERO) as Vector2,
		float(payload.get("radius", 0.0)),
		payload.get("color", Color.WHITE) as Color,
		float(payload.get("lifetime", 0.1))
	)

func _apply_authority_snapshot(snapshot: Dictionary) -> bool:
	return authority_sync.apply_snapshot(snapshot)

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
	if game_state == GameStateScript.REST and network_mode != "client" and not _all_rest_players_ready():
		return
	if game_state == GameStateScript.VICTORY or game_state == GameStateScript.DEFEAT:
		return
	if game_state == GameStateScript.REST:
		_leave_rest_arena()
	if _is_network_game():
		seed(NETWORK_SYNC_SEED + (wave_index + 1) * 1009)
	_set_player_cooldowns_paused(false)
	_stop_ultimate()
	var wave_result: Dictionary = wave_manager.advance()
	wave_index = int(wave_result["index"])
	_clear_upgrade_panel()
	_clear_projectiles()
	upgrade_panel.visible = false
	if rest_ui != null:
		rest_ui.hide_rest()
	if combat_hud_ui != null:
		combat_hud_ui.set_combat_visible(true)
	if return_to_menu_button != null:
		return_to_menu_button.visible = true
	start_next_wave_button.visible = false
	start_next_wave_button.disabled = true
	result_ui.hide_result()
	waiting_for_next_wave_input = false
	rest_ready_players.clear()
	upgrade_selection_input_lock_left = 0.0
	_reset_upgrade_slots()

	if bool(wave_result["complete"]):
		_enter_victory()
		return

	_revive_dead_players_for_next_wave()
	_prepare_players_for_next_wave()
	_update_player_wave_damage_growth()

	var wave_def: Dictionary = wave_result["definition"] as Dictionary
	if wave_def.get("boss", false):
		game_state = GameStateScript.BOSS_WAVE
		wave_time_left = GameRulesScript.BOSS_WAVE_TIME_LIMIT
		if network_mode != "client":
			_spawn_boss()
	else:
		game_state = GameStateScript.WAVE_ACTIVE
		wave_time_left = GameRulesScript.NORMAL_WAVE_TIME_LIMIT
		if network_mode != "client":
			_spawn_wave(wave_def)

	_update_status()

func _prepare_players_for_next_wave() -> void:
	for existing_player in players:
		if not is_instance_valid(existing_player) or existing_player.is_dead:
			continue
		if not existing_player.global_position.is_finite() or not ARENA_BOUNDS.has_point(existing_player.global_position):
			existing_player.global_position = ARENA_BOUNDS.get_center()
		existing_player.velocity = Vector2.ZERO

func _update_player_wave_damage_growth() -> void:
	var multiplier := 1.0 + float(maxi(wave_index, 0)) * GameRulesScript.PLAYER_DAMAGE_GROWTH_PER_WAVE
	for existing_player in players:
		if is_instance_valid(existing_player):
			existing_player.wave_damage_multiplier = multiplier

func _spawn_minions(count: int) -> void:
	wave_spawner.spawn_minions(count)

func _spawn_wave(wave_def: Dictionary) -> void:
	wave_spawner.spawn_wave(wave_def)

func _setup_wave_enemy(enemy: EnemyController, enemy_type: String) -> void:
	wave_spawner.setup_wave_enemy(enemy, enemy_type)

func _spawn_boss() -> void:
	wave_spawner.spawn_boss()

func _tune_enemy_for_mode(enemy: EnemyController) -> void:
	wave_spawner.tune_enemy_for_mode(enemy)

func _tune_boss_for_mode(boss: EnemyController) -> void:
	wave_spawner.tune_boss_for_mode(boss)

func _register_enemy(enemy: EnemyController, authority_enemy_id: int = -1) -> void:
	if authority_enemy_id > 0:
		enemy.network_id = authority_enemy_id
		network_next_enemy_id = maxi(network_next_enemy_id, authority_enemy_id + 1)
	else:
		enemy.network_id = network_next_enemy_id
		network_next_enemy_id += 1
	enemy.arena_bounds = ARENA_BOUNDS
	enemy.authority_enabled = network_mode != "client"
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
	wave_spawner.spawn_boss_reinforcements(boss)

func _spawn_point(index: int, count: int) -> Vector2:
	return wave_spawner.spawn_point(index, count)

func _build_map() -> void:
	map_builder.build()

func _update_camera() -> void:
	if camera == null or players.is_empty():
		return
	var focus: Vector2 = _get_alive_players_center()
	var half_view: Vector2 = _get_viewport_size() * 0.5
	var camera_bounds := ARENA_BOUNDS.grow(MAP_VIEW_MARGIN)
	var min_position: Vector2 = camera_bounds.position + half_view
	var max_position: Vector2 = camera_bounds.end - half_view
	camera.global_position = Vector2(
		_clamp_camera_axis(focus.x, min_position.x, max_position.x, camera_bounds.get_center().x),
		_clamp_camera_axis(focus.y, min_position.y, max_position.y, camera_bounds.get_center().y)
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

func _is_player_action_active() -> bool:
	return _is_combat_active() or game_state == GameStateScript.REST

func _set_player_cooldowns_paused(paused: bool) -> void:
	for existing_player in players:
		if is_instance_valid(existing_player):
			existing_player.cooldowns_paused = paused

func _on_enemy_died(enemy: EnemyController) -> void:
	if enemy != null and enemy.is_training_dummy:
		return
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
		_broadcast_enemy_telegraph("circle", {
			"origin": enemy.global_position, "radius": attack_range,
			"color": warning_color, "lifetime": windup_time,
		})

func _on_enemy_damaged(enemy: EnemyController, amount: float) -> void:
	if is_instance_valid(enemy):
		if not enemy.is_training_dummy:
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
	effect_manager.spawn_effect(origin, radius, color, lifetime)

func _add_textured_effect(root: Node2D, texture: Texture2D, diameter: float, position: Vector2 = Vector2.ZERO, tint: Color = Color.WHITE, node_name: String = "TexturedEffect") -> Sprite2D:
	return effect_manager.add_textured_effect(root, texture, diameter, position, tint, node_name)

func _spawn_textured_effect(origin: Vector2, texture: Texture2D, diameter: float, lifetime: float, node_name: String = "TexturedEffect") -> void:
	effect_manager.spawn_textured_effect(origin, texture, diameter, lifetime, node_name)

func _animate_effect_rotation(sprite: Sprite2D, duration: float, clockwise: bool) -> void:
	effect_manager.animate_effect_rotation(sprite, duration, clockwise)

func _animate_effect_pulse(sprite: Sprite2D, minimum_alpha: float, maximum_alpha: float, duration: float) -> void:
	effect_manager.animate_effect_pulse(sprite, minimum_alpha, maximum_alpha, duration)

func _spawn_inward_streaks(origin: Vector2, radius: float, color: Color, count: int, lifetime: float) -> void:
	effect_manager.spawn_inward_streaks(origin, radius, color, count, lifetime)

func _spawn_spark_burst(origin: Vector2, color: Color, count: int, distance: float, lifetime: float) -> void:
	effect_manager.spawn_spark_burst(origin, color, count, distance, lifetime)

func _spawn_area_visual(root: Node2D, origin: Vector2, radius: float, color: Color) -> void:
	effect_manager.spawn_area_visual(root, origin, radius, color)

func _spawn_lancer_sweep_effect(origin: Vector2, direction: Vector2, length: float, half_width: float, texture: Texture2D) -> void:
	effect_manager.spawn_lancer_sweep_effect(origin, direction, length, half_width, texture)

func _spawn_line_skill_effect(origin: Vector2, direction: Vector2, length: float, color: Color = Color(1.0, 0.86, 0.32, 0.55), lifetime: float = 0.09) -> void:
	effect_manager.spawn_line_skill_effect(origin, direction, length, color, lifetime)

func _spawn_ring_effect(origin: Vector2, radius: float, color: Color, lifetime: float = 0.18) -> void:
	effect_manager.spawn_ring_effect(origin, radius, color, lifetime)

func _spawn_link_effect(start: Vector2, end: Vector2, color: Color, lifetime: float = 0.14) -> void:
	effect_manager.spawn_link_effect(start, end, color, lifetime)

func _spawn_damage_number(origin: Vector2, amount: float, color: Color) -> void:
	effect_manager.spawn_damage_number(origin, amount, color)

func _spawn_cooldown_bubble(target_player: PlayerController, text: String) -> void:
	effect_manager.spawn_cooldown_bubble(target_player, text)

func _enter_upgrade_select() -> void:
	if local_player_slots.is_empty():
		return
	if network_mode == "client":
		return
	_prepare_upgrade_select()
	var upgrade_players: Array = []
	for slot in local_player_slots:
		var target_player: PlayerController = slot.get("player") as PlayerController
		upgrade_players.append(target_player)
	var final_upgrade_round := wave_index == wave_manager.boss_wave_index() - 1
	var force_epic := final_upgrade_round and not epic_upgrade_seen
	var excluded_rarities: Array = ["Common"] if wave_manager.is_post_midboss_upgrade() else []
	var roll_result: Dictionary = UpgradeSessionScript.roll_sets(upgrade_players, force_epic, excluded_rarities)
	var upgrade_rarity: String = str(roll_result["rarity"])
	var upgrade_sets: Array = roll_result["sets"] as Array
	if upgrade_rarity == "Epic":
		epic_upgrade_seen = true
	UpgradeSessionScript.assign_sets(local_player_slots, upgrade_sets)
	if network_mode == "host":
		rpc("_network_begin_upgrade_select", upgrade_sets.duplicate(true))
		_build_single_player_upgrade_panel(local_peer_player_index)
	else:
		_build_single_player_upgrade_panel()
	upgrade_ui.set_selection_enabled(false)

	upgrade_panel.visible = true
	_update_status()

func _prepare_upgrade_select() -> void:
	game_state = GameStateScript.UPGRADE_SELECT
	upgrade_selection_input_lock_left = UPGRADE_SELECTION_INPUT_LOCK_TIME
	_heal_surviving_players_after_wave()
	_set_player_cooldowns_paused(true)
	_stop_ultimate()
	UpgradeSessionScript.reset_slots(local_player_slots)
	_clear_upgrade_panel()
	if combat_hud_ui != null:
		combat_hud_ui.set_combat_visible(false)
	if return_to_menu_button != null:
		return_to_menu_button.visible = false
	start_next_wave_button.visible = false
	start_next_wave_button.disabled = true
	waiting_for_next_wave_input = false
	result_ui.hide_result()
	if rest_ui != null:
		rest_ui.hide_rest()

@rpc("authority", "reliable")
func _network_begin_upgrade_select(upgrade_sets: Array) -> void:
	if network_mode != "client":
		return
	_clear_remaining_enemies()
	_prepare_upgrade_select()
	UpgradeSessionScript.assign_sets(local_player_slots, upgrade_sets)
	_build_single_player_upgrade_panel(local_peer_player_index)
	upgrade_ui.set_selection_enabled(false)
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
	if upgrade_selection_input_lock_left > 0.0:
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
	slot["last_upgrade"] = upgrade.duplicate(true)
	if not _all_required_upgrades_selected():
		return
	upgrade_panel.visible = false
	_enter_rest_phase()

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
	if not UpgradeSessionScript.apply_choice(slot, upgrade_index):
		return false
	if player_index == local_peer_player_index:
		upgrade_panel.visible = false
		result_label.text = "等待另一名玩家选择升级"
		result_panel.visible = true
	return true

func _set_network_upgrades_ready() -> void:
	_enter_rest_phase()

@rpc("authority", "reliable")
func _network_upgrades_ready() -> void:
	if network_mode != "client":
		return
	_set_network_upgrades_ready()

func _all_required_upgrades_selected() -> bool:
	return UpgradeSessionScript.all_selected(local_player_slots)

func _enter_rest_phase() -> void:
	game_state = GameStateScript.REST
	upgrade_panel.visible = false
	result_ui.hide_result()
	waiting_for_next_wave_input = false
	rest_ready_players.clear()
	_enter_rest_arena()
	var local_slot: Dictionary = _get_local_player_slot(local_peer_player_index)
	var local_player: PlayerController = local_slot.get("player") as PlayerController
	var latest_upgrade := local_slot.get("last_upgrade", {}) as Dictionary
	var next_wave_intel := _format_next_wave_intel()
	rest_ui.show_rest(
		"第 %d 波完成 · 战备休息" % (wave_index + 1),
		_format_latest_upgrade(latest_upgrade, local_player),
		_format_current_build(local_player),
		next_wave_intel,
		_get_viewport_size(),
		_get_rest_info_icon_paths(latest_upgrade, local_player),
		_get_rest_info_summaries(latest_upgrade, local_player),
		_get_rest_hud_context(latest_upgrade, local_player, _format_current_build(local_player))
	)
	_refresh_rest_ready_ui()
	_update_status()

func _enter_rest_arena() -> void:
	_clear_remaining_enemies()
	_clear_effects()
	_set_main_map_active(false)
	if rest_arena != null:
		rest_arena.visible = true
	_revive_dead_players_for_next_wave()
	rest_saved_player_cooldowns.clear()
	var spawn_positions := [Vector2(-45.0, 150.0), Vector2(45.0, 150.0)]
	for index in range(players.size()):
		var existing_player := players[index]
		if not is_instance_valid(existing_player):
			continue
		existing_player.arena_bounds = RestArenaScript.BOUNDS
		existing_player.global_position = spawn_positions[mini(index, spawn_positions.size() - 1)]
		existing_player.velocity = Vector2.ZERO
		rest_saved_player_cooldowns[index + 1] = existing_player.make_authority_cooldowns().duplicate(true)
		existing_player.reset_training_cooldowns()
		existing_player.cooldowns_paused = false
	if combat_hud_ui != null:
		combat_hud_ui.set_combat_visible(true)
		hud_left.visible = false
	if return_to_menu_button != null:
		return_to_menu_button.visible = true
	if network_mode != "client":
		_spawn_training_dummies()

func _spawn_training_dummies() -> void:
	var positions := [Vector2(-180.0, -20.0), Vector2(180.0, -20.0)]
	for index in range(positions.size()):
		var dummy: EnemyController = EnemyScript.new()
		dummy.name = "TrainingDummy%d" % (index + 1)
		dummy.setup_as_training_dummy()
		dummy.global_position = positions[index]
		_register_enemy(dummy)
		dummy.arena_bounds = RestArenaScript.BOUNDS

func _leave_rest_arena() -> void:
	_clear_remaining_enemies()
	_clear_effects()
	_set_main_map_active(true)
	if rest_arena != null:
		rest_arena.visible = false
	var spawn_positions := [Vector2(-42.0, 0.0), Vector2(42.0, 0.0)]
	for index in range(players.size()):
		var existing_player := players[index]
		if not is_instance_valid(existing_player):
			continue
		existing_player.arena_bounds = ARENA_BOUNDS
		existing_player.global_position = spawn_positions[mini(index, spawn_positions.size() - 1)]
		existing_player.velocity = Vector2.ZERO
		existing_player.restore_cooldowns(rest_saved_player_cooldowns.get(index + 1, {}) as Dictionary)
	rest_saved_player_cooldowns.clear()

func _set_main_map_active(active: bool) -> void:
	if map_root == null:
		return
	map_root.visible = active
	for node in map_root.find_children("*", "CollisionShape2D", true, false):
		var collision := node as CollisionShape2D
		if collision != null:
			collision.disabled = not active

func _format_latest_upgrade(upgrade: Dictionary, target_player: PlayerController) -> String:
	if upgrade.is_empty():
		return "本轮升级信息不可用"
	return "%s\n\n%s\n\n当前结果：%s" % [
		str(upgrade.get("title", "升级")),
		str(upgrade.get("description", "")),
		_format_upgrade_current(upgrade, target_player),
	]

func _format_current_build(target_player: PlayerController) -> String:
	if target_player == null or not is_instance_valid(target_player) or target_player.upgrade_levels.is_empty():
		return "尚未获得升级"
	var lines: Array[String] = []
	for upgrade_id_value in target_player.upgrade_levels.keys():
		var upgrade := UpgradeCatalogScript.get_by_id(str(upgrade_id_value))
		if upgrade.is_empty():
			continue
		var slot := str(upgrade.get("skill_slot", "属性"))
		lines.append("[%s] %s\n%s" % [slot, str(upgrade.get("title", upgrade_id_value)), str(upgrade.get("description", ""))])
	return "\n\n".join(lines) if not lines.is_empty() else "尚未获得升级"

func _get_rest_info_icon_paths(latest_upgrade: Dictionary, target_player: PlayerController) -> Array[String]:
	var latest_icon_path := str(CHARACTER_STAT_ICONS.get("attack", ""))
	var character_id := target_player.character_id if target_player != null else "warrior"
	var skill_slot := str(latest_upgrade.get("skill_slot", ""))
	if not skill_slot.is_empty():
		latest_icon_path = get_character_skill_icon_path(character_id, skill_slot)
	else:
		var stat := str(latest_upgrade.get("stat", ""))
		if stat in ["max_health", "heal_percent", "lifesteal"]:
			latest_icon_path = str(CHARACTER_STAT_ICONS.get("health", latest_icon_path))
		elif stat in ["move_speed", "dash_cooldown", "dash_charges"]:
			latest_icon_path = str(CHARACTER_STAT_ICONS.get("speed", latest_icon_path))
		elif stat.ends_with("cooldown") or stat.ends_with("duration"):
			latest_icon_path = str(CHARACTER_STAT_ICONS.get("cooldown", latest_icon_path))
	var build_icon_path := get_character_skill_icon_path(character_id, "BASIC")
	return [latest_icon_path, build_icon_path, str(CHARACTER_STAT_ICONS.get("health", ""))]

func _get_rest_info_summaries(latest_upgrade: Dictionary, target_player: PlayerController) -> Array[String]:
	var upgrade_count := 0
	if target_player != null:
		for level_value in target_player.upgrade_levels.values():
			upgrade_count += int(level_value)
	var next_wave_index := wave_index + 1
	var next_enemy_count := 0
	if next_wave_index >= 0 and next_wave_index < wave_manager.wave_definitions.size():
		var wave_def := wave_manager.wave_definitions[next_wave_index] as Dictionary
		for enemy_type in ["mini_boss", "boss", "melee", "heavy", "ranged", "shield", "charger", "bomber", "priest"]:
			next_enemy_count += _get_wave_intel_count(wave_def, enemy_type)
	return [
		str(latest_upgrade.get("title", "新强化")),
		"%d 项强化" % upgrade_count,
		"第 %d 波 · %d个目标" % [next_wave_index + 1, next_enemy_count],
	]

func _get_rest_hud_context(latest_upgrade: Dictionary, target_player: PlayerController, build_text: String) -> Dictionary:
	if target_player == null:
		return {}
	var skills: Array[Dictionary] = []
	for skill_key in ["Q", "E", "F"]:
		var detail := GameRulesScript.get_action_tooltip(target_player.character_id, skill_key)
		var upgrade_lines: Array[String] = []
		for upgrade_id_value in target_player.upgrade_levels.keys():
			var upgrade := UpgradeCatalogScript.get_by_id(str(upgrade_id_value))
			if str(upgrade.get("skill_slot", "")).to_upper() != skill_key:
				continue
			upgrade_lines.append("%s ×%d：%s" % [
				str(upgrade.get("title", upgrade_id_value)),
				int(target_player.upgrade_levels[upgrade_id_value]),
				str(upgrade.get("description", "")),
			])
		if not upgrade_lines.is_empty():
			detail += "\n\n当前强化\n" + "\n".join(upgrade_lines)
		skills.append({
			"key": skill_key,
			"icon": get_character_skill_icon_path(target_player.character_id, skill_key),
			"tooltip": "%s 技能\n\n%s" % [skill_key, detail],
		})
	var saved_cooldowns := rest_saved_player_cooldowns.get(local_peer_player_index, {}) as Dictionary
	var stats_lines: Array[String] = [
		"角色：%s" % _get_character_name(target_player.character_id),
		"生命：%d / %d" % [roundi(target_player.health), roundi(target_player.max_health)],
		"攻击：%.1f　技能伤害：%.1f" % [target_player.attack_damage * target_player.wave_damage_multiplier, target_player.skill_damage * target_player.wave_damage_multiplier],
		"移动速度：%.1f　击退：%.1f" % [target_player.move_speed, target_player.attack_knockback],
		"暴击率：%.1f%%　暴击伤害：%.0f%%" % [target_player.crit_chance * 100.0, target_player.crit_multiplier * 100.0],
		"吸血：%.1f%%" % (target_player.lifesteal_ratio * 100.0),
		"普攻 CD：%.2f秒　闪避 CD：%.2f秒" % [target_player.attack_cooldown, target_player.dash_cooldown],
		"Q CD：%.2f秒　E CD：%.2f秒　F CD：%.2f秒" % [target_player.skill_cooldown, target_player.fan_skill_cooldown, target_player.ultimate_cooldown],
		"选卡前剩余 CD：Q %.1f / E %.1f / F %.1f秒" % [
			float(saved_cooldowns.get("skill", 0.0)),
			float(saved_cooldowns.get("fan", 0.0)),
			float(saved_cooldowns.get("ultimate", 0.0)),
		],
	]
	stats_lines.append("\n当前构筑\n%s" % build_text)
	var icons := _get_rest_info_icon_paths(latest_upgrade, target_player)
	var summaries := _get_rest_info_summaries(latest_upgrade, target_player)
	return {
		"character_name": _get_character_name(target_player.character_id),
		"skills": skills,
		"stats_icon": str(CHARACTER_STAT_ICONS.get("attack", "")),
		"stats_text": "\n".join(stats_lines),
		"latest_icon": icons[0],
		"latest_summary": summaries[0],
		"intel_icon": icons[2],
		"intel_summary": summaries[2],
	}

func _format_next_wave_intel() -> String:
	var next_wave_index := wave_index + 1
	if next_wave_index < 0 or next_wave_index >= wave_manager.wave_definitions.size():
		return "所有波次已经完成"
	var wave_def: Dictionary = wave_manager.wave_definitions[next_wave_index] as Dictionary
	var lines: Array[String] = ["第 %d 波" % (next_wave_index + 1)]
	for enemy_type in ["mini_boss", "boss", "melee", "heavy", "ranged", "shield", "charger", "bomber", "priest"]:
		var count := _get_wave_intel_count(wave_def, enemy_type)
		if count <= 0:
			continue
		var stats := EnemyArchetypesScript.get_stats(enemy_type, next_wave_index + 1)
		var boss_class: bool = enemy_type in ["mini_boss", "boss"]
		var health_multiplier := boss_health_multiplier if boss_class else enemy_health_multiplier
		var damage_multiplier := boss_damage_multiplier if boss_class else enemy_damage_multiplier
		lines.append("\n%s ×%d\n生命 %d　攻击 %d\n%s" % [
			str(ENEMY_DISPLAY_NAMES.get(enemy_type, enemy_type)), count,
			roundi(float(stats.get("max_health", 0.0)) * health_multiplier),
			roundi(float(stats.get("attack_damage", 0.0)) * damage_multiplier),
			str(ENEMY_SKILL_INTEL.get(enemy_type, "无特殊技能")),
		])
	return "\n".join(lines)

func _get_wave_intel_count(wave_def: Dictionary, enemy_type: String) -> int:
	if enemy_type in ["mini_boss", "boss"]:
		return 1 if bool(wave_def.get(enemy_type, false)) else 0
	var base_count := int(wave_def.get(enemy_type, 0))
	if enemy_type in ["charger", "bomber"] and local_player_count > 1:
		return base_count * 2
	if enemy_type == "priest":
		return base_count
	return roundi(float(base_count) * minion_count_multiplier)

func _on_rest_ready_pressed() -> void:
	if game_state != GameStateScript.REST:
		return
	if network_mode == "none":
		rest_ready_players[1] = true
		_start_next_wave_for_all_peers()
		return
	if network_mode == "client":
		if bool(rest_ready_players.get(local_peer_player_index, false)):
			return
		rpc_id(1, "_network_set_rest_ready", local_peer_player_index)
		rest_ui.set_ready_state("准备请求已发送，等待房主确认", "等待确认", false)
		return
	if _all_rest_players_ready():
		_start_next_wave_for_all_peers()
		return
	rest_ready_players[local_peer_player_index] = true
	_broadcast_rest_ready_state()
	_refresh_rest_ready_ui()

@rpc("any_peer", "reliable")
func _network_set_rest_ready(player_index: int) -> void:
	if network_mode != "host" or multiplayer.get_remote_sender_id() != 2 or player_index != 2 or game_state != GameStateScript.REST:
		return
	rest_ready_players[player_index] = true
	_broadcast_rest_ready_state()
	_refresh_rest_ready_ui()

func _broadcast_rest_ready_state() -> void:
	if network_mode == "host":
		rpc("_network_sync_rest_ready", rest_ready_players.duplicate(true))

@rpc("authority", "reliable")
func _network_sync_rest_ready(ready_players: Dictionary) -> void:
	if network_mode != "client" or game_state != GameStateScript.REST:
		return
	rest_ready_players = ready_players.duplicate(true)
	_refresh_rest_ready_ui()

func _all_rest_players_ready() -> bool:
	var required_count := 2 if _is_network_game() else 1
	for player_index in range(1, required_count + 1):
		if not bool(rest_ready_players.get(player_index, false)):
			return false
	return true

func _refresh_rest_ready_ui() -> void:
	if rest_ui == null or game_state != GameStateScript.REST:
		return
	if network_mode == "none":
		rest_ui.set_ready_state("阅读完成后进入下一波", "准备完成并继续", true)
		return
	var host_ready := bool(rest_ready_players.get(1, false))
	var client_ready := bool(rest_ready_players.get(2, false))
	var status_text := "房主：%s　朋友：%s" % ["已准备" if host_ready else "准备中", "已准备" if client_ready else "准备中"]
	if network_mode == "client":
		rest_ui.set_ready_state(status_text, "已准备" if client_ready else "准备完成", not client_ready)
		return
	if host_ready and client_ready:
		rest_ui.set_ready_state(status_text, "开启下一波", true)
	elif host_ready:
		rest_ui.set_ready_state(status_text, "等待朋友", false)
	else:
		rest_ui.set_ready_state(status_text, "准备完成", true)

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
	if rest_ui != null:
		rest_ui.hide_rest()
	rest_ready_players.clear()
	rest_saved_player_cooldowns.clear()
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
	network_next_visual_event_id = 1
	network_last_visual_event_id = 0
	network_next_enemy_id = 1
	network_next_combat_entity_id = 1
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
	upgrade_selection_input_lock_left = 0.0

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
		wave_label.text = "波次：%d / %d" % [
			clampi(wave_index + 1, 1, WAVE_DEFS.size()),
			WAVE_DEFS.size(),
		]
		combat_hud_ui.wave_timer_label.text = str(ceili(wave_time_left))
		combat_hud_ui.wave_timer_label.visible = hud_left.visible
	else:
		wave_label.text = "波次：%d / %d" % [
			clampi(wave_index + 1, 1, WAVE_DEFS.size()),
			WAVE_DEFS.size(),
		]
		combat_hud_ui.wave_timer_label.text = ""
		combat_hud_ui.wave_timer_label.visible = false
	enemies_label.text = "训练木桩：%d" % enemies.size() if game_state == GameStateScript.REST else "剩余敌人：%d" % enemies.size()
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
		GameStateScript.REST:
			return "战备休息"
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
