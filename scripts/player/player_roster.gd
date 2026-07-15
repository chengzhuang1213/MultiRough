extends RefCounted
class_name PlayerRoster

const PlayerScript := preload("res://scripts/player/player_controller.gd")
const VerdantUIThemeScript := preload("res://scripts/ui/verdant_ui_theme.gd")

var game: Node
var combat

func _init(game_node: Node, combat_manager) -> void:
	game = game_node
	combat = combat_manager

func create_player(player_name: String, spawn_position: Vector2, tint: Color, mouse_aim: bool, character_config: Dictionary) -> PlayerController:
	var player: PlayerController = PlayerScript.new()
	player.name = player_name
	player.global_position = spawn_position
	player.arena_bounds = game.ARENA_BOUNDS
	player.player_tint = tint
	player.use_mouse_aim = mouse_aim
	player.apply_character_config(character_config)
	player.basic_attack_requested.connect(combat.on_player_basic_attack.bind(player))
	player.projectile_attack_requested.connect(combat.on_player_projectile_attack.bind(player))
	player.active_skill_requested.connect(combat.on_player_active_skill.bind(player))
	player.fan_skill_requested.connect(combat.on_player_fan_skill.bind(player))
	player.ultimate_skill_requested.connect(combat.on_player_ultimate_skill.bind(player))
	player.secondary_action_requested.connect(combat.on_player_secondary_action.bind(player))
	player.cooldown_notice_requested.connect(game._on_player_cooldown_notice_requested.bind(player))
	player.health_changed.connect(on_player_health_changed.bind(player))
	player.damage_taken.connect(combat.on_player_damage_taken.bind(player))
	player.reflected_damage_requested.connect(combat.on_player_reflected_damage.bind(player))
	player.perfect_guard_triggered.connect(combat.on_player_perfect_guard.bind(player))
	player.died.connect(game._on_player_died)
	game.add_child(player)
	return player

func add_slot(player_index: int, player: PlayerController) -> void:
	game.local_player_slots.append({
		"player_index": player_index, "player": player,
		"upgrades": [], "selected": false, "selection_pending": false,
	})

func get_slot(player_index: int) -> Dictionary:
	for slot in game.local_player_slots:
		if int(slot.get("player_index", 0)) == player_index:
			return slot
	return {}

func reset_upgrade_slots() -> void:
	for slot in game.local_player_slots:
		slot["upgrades"] = []
		slot["selected"] = false
		slot["selection_pending"] = false

func create_hud(parent: PanelContainer, skill_labels: Array[String], hud_width: float = 440.0) -> void:
	parent.add_theme_stylebox_override("panel", VerdantUIThemeScript.make_compact_panel_style(Color(1.0, 1.0, 1.0, 0.96)))
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 8)
	parent.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	margin.add_child(content)

	var health_layer := Control.new()
	health_layer.custom_minimum_size = Vector2(hud_width - 80.0, 24.0)
	content.add_child(health_layer)
	var health_bar := ProgressBar.new()
	health_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	health_bar.show_percentage = false
	_style_health_bar(health_bar)
	health_layer.add_child(health_bar)
	var health_label := Label.new()
	health_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health_label.add_theme_font_size_override("font_size", 16)
	health_label.add_theme_color_override("font_color", Color(0.025, 0.045, 0.075, 1.0))
	health_label.add_theme_color_override("font_shadow_color", Color(0.8, 1.0, 0.35, 0.42))
	health_label.add_theme_constant_override("shadow_offset_x", 1)
	health_label.add_theme_constant_override("shadow_offset_y", 1)
	health_layer.add_child(health_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 4)
	content.add_child(actions)
	var action_names: Array[String] = ["普攻", "闪避", "右键", skill_labels[1], skill_labels[2], skill_labels[3]]
	var action_panels: Array[PanelContainer] = []
	var action_name_labels: Array[Label] = []
	var action_status_labels: Array[Label] = []
	var action_icons: Array[TextureRect] = []
	var action_cooldown_overlays: Array[ColorRect] = []
	var skill_icons: Array[TextureRect] = []
	var cooldown_overlays: Array[ColorRect] = []
	var ready_style := VerdantUIThemeScript.make_skill_slot_style()
	var cooldown_style := VerdantUIThemeScript.make_skill_slot_style(Color(0.66, 0.62, 0.48, 1.0))
	for action_index in range(action_names.size()):
		var action_name: String = action_names[action_index]
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(58.0, 54.0)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", ready_style)
		panel.tooltip_text = action_name
		panel.clip_contents = true
		actions.add_child(panel)
		var action_content := Control.new()
		action_content.custom_minimum_size = Vector2(0.0, 38.0)
		panel.add_child(action_content)
		var icon := TextureRect.new()
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		action_content.add_child(icon)
		action_icons.append(icon)
		var overlay := ColorRect.new()
		overlay.color = Color(0.01, 0.015, 0.025, 0.72)
		overlay.anchor_left = 0.0
		overlay.anchor_top = 0.0
		overlay.anchor_right = 1.0
		overlay.anchor_bottom = 0.0
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		action_content.add_child(overlay)
		action_cooldown_overlays.append(overlay)
		if action_index >= 3:
			skill_icons.append(icon)
			cooldown_overlays.append(overlay)
		var name_label := Label.new()
		name_label.text = action_name
		name_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		name_label.add_theme_font_size_override("font_size", 14 if action_index >= 3 else 12)
		name_label.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0, 1.0))
		name_label.add_theme_color_override("font_outline_color", Color(0.015, 0.02, 0.035, 0.98))
		name_label.add_theme_constant_override("outline_size", 3 if action_index >= 3 else 2)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		action_content.add_child(name_label)
		var status_label := Label.new()
		status_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		status_label.add_theme_font_size_override("font_size", 11)
		status_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.08, 1.0))
		status_label.add_theme_color_override("font_outline_color", Color(0.015, 0.02, 0.035, 0.98))
		status_label.add_theme_constant_override("outline_size", 3 if action_index >= 3 else 2)
		status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		action_content.add_child(status_label)
		action_panels.append(panel)
		action_name_labels.append(name_label)
		action_status_labels.append(status_label)

	game.player_huds.append({
		"player": null,
		"skill_labels": skill_labels,
		"health_label": health_label,
		"health_bar": health_bar,
		"health_layer": health_layer,
		"action_panels": action_panels,
		"action_name_labels": action_name_labels,
		"action_status_labels": action_status_labels,
		"action_icons": action_icons,
		"action_cooldown_overlays": action_cooldown_overlays,
		"skill_icons": skill_icons,
		"cooldown_overlays": cooldown_overlays,
		"ready_style": ready_style,
		"cooldown_style": cooldown_style,
	})

func assign_hud(index: int, player: PlayerController) -> void:
	if index < 0 or index >= game.player_huds.size():
		return
	game.player_huds[index]["player"] = player
	if player != null and is_instance_valid(player):
		var icons: Array = game.player_huds[index].get("action_icons", [])
		var action_keys: Array[String] = ["BASIC", "DODGE", "SECONDARY", "Q", "E", "F"]
		for action_index in range(mini(icons.size(), action_keys.size())):
			(icons[action_index] as TextureRect).texture = load(game.get_character_skill_icon_path(player.character_id, action_keys[action_index])) as Texture2D
	update_hud(index)

func on_player_health_changed(current: float, maximum: float, player: PlayerController) -> void:
	for index in range(game.player_huds.size()):
		var hud: Dictionary = game.player_huds[index]
		if hud.get("player") == player:
			var health_bar: ProgressBar = hud["health_bar"] as ProgressBar
			if health_bar != null:
				health_bar.max_value = maximum
				health_bar.value = current
			update_hud(index)
			return

func update_all_huds() -> void:
	for index in range(game.player_huds.size()):
		update_hud(index)

func set_hud_occlusion_opacity(opacity: float) -> void:
	if game.player_huds.is_empty():
		return
	var hud: Dictionary = game.player_huds[0]
	var clamped_opacity := clampf(opacity, 0.0, 1.0)
	game.player_hud.self_modulate.a = clamped_opacity
	var health_bar: ProgressBar = hud.get("health_bar") as ProgressBar
	var health_label: Label = hud.get("health_label") as Label
	if health_bar != null:
		health_bar.modulate.a = maxf(0.25, clamped_opacity)
	if health_label != null:
		health_label.modulate.a = maxf(0.55, clamped_opacity)
	for panel in hud.get("action_panels", []):
		(panel as PanelContainer).self_modulate.a = clamped_opacity
	for name_label in hud.get("action_name_labels", []):
		(name_label as Label).modulate.a = maxf(0.38, clamped_opacity)
	for status_label in hud.get("action_status_labels", []):
		(status_label as Label).modulate.a = maxf(0.38, clamped_opacity)

func update_hud(index: int) -> void:
	if index < 0 or index >= game.player_huds.size():
		return
	var hud: Dictionary = game.player_huds[index]
	var player: PlayerController = hud.get("player") as PlayerController
	var health_label: Label = hud["health_label"] as Label
	var health_bar: ProgressBar = hud["health_bar"] as ProgressBar
	var action_panels: Array = hud.get("action_panels", [])
	var action_status_labels: Array = hud.get("action_status_labels", [])
	var action_cooldown_overlays: Array = hud.get("action_cooldown_overlays", [])
	if player == null or not is_instance_valid(player):
		health_label.text = ""
		health_bar.value = 0.0
		for status_label in action_status_labels:
			(status_label as Label).text = ""
		return
	health_label.text = "%d / %d%s" % [roundi(player.health), roundi(player.max_health), "（倒地）" if player.is_dead else ""]
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	var ready_states: Array[bool] = [
		player.get_attack_ready(), player.get_dash_ready(), player.get_secondary_ready(),
		player.get_skill_ready(), player.get_fan_skill_ready(), player.get_ultimate_ready(),
	]
	var status_texts: Array[String] = [
		"就绪" if ready_states[0] else "%.1f秒" % player.get_attack_remaining(),
		"就绪 %d/%d" % [player.dash_charges, player.dash_max_charges] if ready_states[1] else "%.1f秒 %d/%d" % [player.get_dash_remaining(), player.dash_charges, player.dash_max_charges],
		"就绪" if ready_states[2] else "%.1f秒" % player.get_secondary_remaining(),
		"" if ready_states[3] else "%.1f" % player.get_skill_remaining(),
		"" if ready_states[4] else "%.1f" % player.get_fan_skill_remaining(),
		"" if ready_states[5] else "%.1f" % player.get_ultimate_remaining(),
	]
	var action_remaining: Array[float] = [
		player.get_attack_remaining(), player.get_dash_remaining(), player.get_secondary_remaining(),
		player.get_skill_remaining(), player.get_fan_skill_remaining(), player.get_ultimate_remaining(),
	]
	var action_cooldowns: Array[float] = [
		player.attack_cooldown, player.dash_cooldown, player.SECONDARY_COOLDOWN,
		player.skill_cooldown, player.fan_skill_cooldown, player.ultimate_cooldown,
	]
	for action_index in range(mini(action_cooldown_overlays.size(), action_remaining.size())):
		var ratio := clampf(action_remaining[action_index] / maxf(action_cooldowns[action_index], 0.001), 0.0, 1.0)
		var overlay := action_cooldown_overlays[action_index] as ColorRect
		overlay.anchor_bottom = ratio
		overlay.offset_bottom = 0.0
	var ready_style: StyleBox = hud["ready_style"] as StyleBox
	var cooldown_style: StyleBox = hud["cooldown_style"] as StyleBox
	for action_index in range(mini(action_panels.size(), action_status_labels.size())):
		var panel: PanelContainer = action_panels[action_index] as PanelContainer
		var status_label: Label = action_status_labels[action_index] as Label
		var ready := ready_states[action_index]
		panel.add_theme_stylebox_override("panel", ready_style if ready else cooldown_style)
		status_label.text = status_texts[action_index]
		status_label.add_theme_color_override("font_color", Color.WHITE if action_index >= 3 else (Color(0.55, 1.0, 0.08, 1.0) if ready else Color(1.0, 0.68, 0.12, 1.0)))

func _style_health_bar(bar: ProgressBar) -> void:
	bar.add_theme_stylebox_override("background", VerdantUIThemeScript.make_hud_bar_style())
	var fill := _make_panel_style(Color(0.55, 1.0, 0.06, 1.0), Color(0.28, 0.52, 0.04, 1.0), 2, 4)
	fill.content_margin_left = 16.0
	fill.content_margin_top = 10.0
	fill.content_margin_right = 16.0
	fill.content_margin_bottom = 10.0
	bar.add_theme_stylebox_override("fill", fill)

func _make_panel_style(background: Color, border: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = 8.0
	style.content_margin_top = 6.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 6.0
	return style
