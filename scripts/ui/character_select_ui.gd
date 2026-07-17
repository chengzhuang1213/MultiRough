extends PanelContainer
class_name CharacterSelectUI

signal active_slot_requested(slot_index: int)
signal character_requested(character_id: String)
signal start_requested

const UIFactoryScript := preload("res://scripts/ui/ui_factory.gd")
const CampaignSatchelUIThemeScript := preload("res://scripts/ui/campaign_satchel_ui_theme.gd")
const GameRulesScript := preload("res://scripts/gameplay/game_rules.gd")
const CharacterTooltipPanelScript := preload("res://scripts/ui/character_tooltip_panel.gd")

const PANEL_SIZE := Vector2(1180, 700)
const CONTENT_WIDTH := 1080.0
const CARD_WIDTH := 240.0
const SINGLE_CARD_HEIGHT := 420.0
const MULTI_CARD_HEIGHT := 340.0
const ACTION_HEIGHT := 100.0

var content: VBoxContainer
var start_button: Button
var rows: Array = []
var slot_buttons: Array = []
var context: Dictionary = {}

func _ready() -> void:
	custom_minimum_size = PANEL_SIZE
	visible = false
	content = UIFactoryScript.attach_panel_content(self, 16, 10, 16, 10)
	content.add_theme_constant_override("separation", 8)

func rebuild(new_context: Dictionary) -> void:
	context = new_context
	rows.clear()
	slot_buttons.clear()
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	var is_network := bool(context.get("is_network", false))
	var player_count := int(context.get("player_count", 1))

	var title := Label.new()
	title.text = "联机房间" if is_network else "选择角色"
	title.custom_minimum_size = Vector2(CONTENT_WIDTH, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	title.add_theme_font_size_override("font_size", 30)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "选择一名英雄，查看核心属性与技能配置"
	subtitle.custom_minimum_size = Vector2(CONTENT_WIDTH, 22)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", CampaignSatchelUIThemeScript.TEXT_MUTED)
	content.add_child(subtitle)
	content.add_child(UIFactoryScript.build_separator(Vector2(CONTENT_WIDTH, 10)))

	if is_network:
		var room_status := Label.new()
		room_status.text = str(context.get("network_status", ""))
		room_status.custom_minimum_size = Vector2(CONTENT_WIDTH, 24)
		room_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		room_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		room_status.add_theme_font_size_override("font_size", 14)
		room_status.add_theme_color_override("font_color", CampaignSatchelUIThemeScript.TEXT_MUTED)
		content.add_child(room_status)

	if player_count > 1:
		var slot_row := HBoxContainer.new()
		slot_row.custom_minimum_size = Vector2(CONTENT_WIDTH, ACTION_HEIGHT)
		slot_row.alignment = BoxContainer.ALIGNMENT_CENTER
		slot_row.add_theme_constant_override("separation", 12)
		content.add_child(slot_row)
		for slot_index in range(player_count):
			var slot_button := Button.new()
			slot_button.custom_minimum_size = Vector2(220, ACTION_HEIGHT)
			slot_button.pressed.connect(func(index := slot_index) -> void: active_slot_requested.emit(index))
			slot_row.add_child(slot_button)
			slot_buttons.append(slot_button)

	if player_count == 1:
		var card_offset := Control.new()
		card_offset.custom_minimum_size = Vector2(CONTENT_WIDTH, 14)
		card_offset.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(card_offset)

	var card_height := MULTI_CARD_HEIGHT if player_count > 1 else SINGLE_CARD_HEIGHT
	var card_row := HBoxContainer.new()
	card_row.custom_minimum_size = Vector2(CONTENT_WIDTH, card_height)
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	card_row.add_theme_constant_override("separation", 25)
	content.add_child(card_row)
	for character_id in context.get("character_order", []):
		var card_data := _build_character_card(str(character_id), Vector2(CARD_WIDTH, card_height))
		card_row.add_child(card_data["button"] as Button)
		rows.append(card_data)

	var start_center := CenterContainer.new()
	start_center.custom_minimum_size = Vector2(CONTENT_WIDTH, ACTION_HEIGHT)
	content.add_child(start_center)
	start_button = Button.new()
	start_button.custom_minimum_size = Vector2(430, ACTION_HEIGHT)
	start_button.add_theme_font_size_override("font_size", 24)
	start_button.pressed.connect(func() -> void: start_requested.emit())
	start_center.add_child(start_button)
	refresh(new_context)

func refresh(new_context: Dictionary) -> void:
	context = new_context
	var active_slot := int(context.get("active_slot", 0))
	var is_network := bool(context.get("is_network", false))
	var local_peer_index := int(context.get("local_peer_index", 1))
	for slot_index in range(slot_buttons.size()):
		var slot_button := slot_buttons[slot_index] as Button
		var active := slot_index == active_slot
		slot_button.text = "P%d  %s" % [slot_index + 1, _character_name(_selected_id(slot_index))]
		slot_button.disabled = is_network and slot_index != local_peer_index - 1
		_style_slot_button(slot_button, active)
	var active_character_id := _selected_id(active_slot)
	var accents: Dictionary = context.get("card_accents", {})
	for card_data in rows:
		var character_id := str(card_data.get("character_id", "warrior"))
		var selected := character_id == active_character_id
		var badge := card_data.get("selected_badge") as Control
		if badge != null:
			badge.visible = selected
		_style_card_button(card_data.get("button") as Button, selected, accents.get(character_id, Color.WHITE))
	if start_button == null:
		return
	match str(context.get("network_mode", "none")):
		"host":
			var joined := bool(context.get("peer_joined", false))
			start_button.text = "开始联机" if joined else "等待朋友加入"
			start_button.disabled = not joined
		"client":
			start_button.text = "等待房主开始"
			start_button.disabled = true
		_:
			start_button.text = "开始游戏"
			start_button.disabled = false

func _build_character_card(character_id: String, card_size: Vector2) -> Dictionary:
	var configs: Dictionary = context.get("character_configs", {})
	var config: Dictionary = configs.get(character_id, configs.get("warrior", {}))
	var button := Button.new()
	button.custom_minimum_size = card_size
	button.clip_contents = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(func() -> void: character_requested.emit(character_id))

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 24 if card_size.y >= SINGLE_CARD_HEIGHT else 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)

	var card_content := VBoxContainer.new()
	card_content.add_theme_constant_override("separation", 6)
	card_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(card_content)

	var title_row := HBoxContainer.new()
	title_row.custom_minimum_size = Vector2(212, 36)
	card_content.add_child(title_row)
	var title_label := Label.new()
	title_label.text = _character_name(character_id)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_row.add_child(title_label)
	var selected_badge := PanelContainer.new()
	selected_badge.custom_minimum_size = Vector2(90, 36)
	selected_badge.add_theme_stylebox_override("panel", _make_chip_style(CampaignSatchelUIThemeScript.ACCENT_BLUE_DARK, CampaignSatchelUIThemeScript.ACCENT_BRASS))
	selected_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(selected_badge)
	var selected_label := Label.new()
	selected_label.text = "已选择"
	selected_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selected_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	selected_label.add_theme_font_size_override("font_size", 16)
	selected_label.add_theme_color_override("font_color", CampaignSatchelUIThemeScript.TOOLTIP_TEXT)
	selected_label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	selected_badge.add_child(selected_label)

	var role_label := Label.new()
	role_label.text = _character_role(character_id)
	role_label.custom_minimum_size = Vector2(212, 18)
	role_label.add_theme_font_size_override("font_size", 13)
	role_label.add_theme_color_override("font_color", CampaignSatchelUIThemeScript.TEXT_MUTED)
	card_content.add_child(role_label)

	var art_frame := Control.new()
	art_frame.custom_minimum_size = Vector2(212, 165 if card_size.y >= SINGLE_CARD_HEIGHT else 110)
	art_frame.clip_contents = true
	art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_content.add_child(art_frame)

	var art := TextureRect.new()
	art.texture = load(str((context.get("card_art", {}) as Dictionary).get(character_id, ""))) as Texture2D
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_frame.add_child(art)
	art_frame.resized.connect(_layout_portrait_top_aligned.bind(art_frame, art))
	_layout_portrait_top_aligned(art_frame, art)

	var stats_grid := GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 8)
	stats_grid.add_theme_constant_override("v_separation", 6)
	card_content.add_child(stats_grid)
	stats_grid.add_child(_build_stat("生命  %d" % roundi(float(config.get("max_health", 0)))))
	stats_grid.add_child(_build_stat("攻击  %d" % roundi(float(config.get("attack_damage", 0)))))
	stats_grid.add_child(_build_stat("移速  %d" % roundi(float(config.get("move_speed", 0)))))
	stats_grid.add_child(_build_stat("间隔  %.2f秒" % float(config.get("attack_cooldown", 0))))

	var compact := card_size.y < SINGLE_CARD_HEIGHT
	var skills := HBoxContainer.new()
	skills.custom_minimum_size = Vector2(212, 34 if compact else 48)
	skills.alignment = BoxContainer.ALIGNMENT_CENTER
	skills.add_theme_constant_override("separation", 8)
	card_content.add_child(skills)
	var skill_panels: Array[PanelContainer] = []
	for skill_key in ["Q", "E", "F"]:
		var skill_panel := _build_skill_key(character_id, skill_key, compact)
		skills.add_child(skill_panel)
		skill_panels.append(skill_panel)

	return {
		"character_id": character_id,
		"button": button,
		"content": card_content,
		"art_frame": art_frame,
		"art": art,
		"title_label": title_label,
		"selected_badge": selected_badge,
		"selected_label": selected_label,
		"skill_panels": skill_panels,
	}

func _layout_portrait_top_aligned(frame: Control, art: TextureRect) -> void:
	if frame == null or art == null or art.texture == null:
		return
	var frame_size := frame.size
	if frame_size.x <= 0.0 or frame_size.y <= 0.0:
		frame_size = frame.custom_minimum_size
	var texture_size := art.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var cover_scale := maxf(frame_size.x / texture_size.x, frame_size.y / texture_size.y)
	var display_size := texture_size * cover_scale
	art.position = Vector2((frame_size.x - display_size.x) * 0.5, 0.0)
	art.size = display_size

func _build_stat(text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(102, 28)
	panel.add_theme_stylebox_override("panel", _make_chip_style(Color(0.92, 0.84, 0.68, 0.96), CampaignSatchelUIThemeScript.ACCENT_BRASS))
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	panel.add_child(label)
	return panel

func _build_skill_key(character_id: String, skill_key: String, compact: bool) -> PanelContainer:
	var panel := CharacterTooltipPanelScript.new()
	panel.tooltip_accent = (context.get("card_accents", {}) as Dictionary).get(character_id, Color.WHITE)
	panel.tooltip_text = GameRulesScript.get_action_tooltip(character_id, skill_key)
	panel.custom_minimum_size = Vector2(64, 34 if compact else 48)
	panel.add_theme_stylebox_override("panel", _make_chip_style(CampaignSatchelUIThemeScript.ACCENT_BLUE_DARK, CampaignSatchelUIThemeScript.ACCENT_BRASS))
	panel.clip_contents = true
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_center := CenterContainer.new()
	icon_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(icon_center)
	var icon := TextureRect.new()
	icon.name = "SkillIcon"
	var character_icons: Dictionary = (context.get("skill_icons", {}) as Dictionary).get(character_id, {})
	icon.texture = load(str(character_icons.get(skill_key, ""))) as Texture2D
	icon.custom_minimum_size = Vector2(28, 28) if compact else Vector2(40, 40)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_center.add_child(icon)
	var label := Label.new()
	label.text = skill_key
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.add_theme_font_size_override("font_size", 11 if compact else 12)
	label.add_theme_color_override("font_color", CampaignSatchelUIThemeScript.TOOLTIP_TEXT)
	label.add_theme_color_override("font_outline_color", CampaignSatchelUIThemeScript.TOOLTIP_OUTLINE)
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	for child in panel.find_children("*", "Control", true, false):
		(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel

func _selected_id(slot_index: int) -> String:
	var selected: Array = context.get("selected_ids", [])
	var configs: Dictionary = context.get("character_configs", {})
	if slot_index >= 0 and slot_index < selected.size() and configs.has(str(selected[slot_index])):
		return str(selected[slot_index])
	return "warrior"

func _character_name(character_id: String) -> String:
	var configs: Dictionary = context.get("character_configs", {})
	return str((configs.get(character_id, configs.get("warrior", {})) as Dictionary).get("name", character_id))

func _character_role(character_id: String) -> String:
	match character_id:
		"archer": return "远程 · 爆发"
		"lancer": return "穿刺 · 控场"
		"mage": return "法术 · 范围"
		_: return "近战 · 生存"

func _make_chip_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 6
	style.content_margin_top = 3
	style.content_margin_right = 6
	style.content_margin_bottom = 3
	return style

func _style_card_button(button: Button, selected: bool, accent: Color) -> void:
	if button == null:
		return
	var normal_tint := Color.WHITE.lerp(accent, 0.05 if selected else 0.0)
	var normal := CampaignSatchelUIThemeScript.make_character_card_style(normal_tint)
	var hover := CampaignSatchelUIThemeScript.make_character_card_style(Color.WHITE.lerp(accent, 0.10))
	var pressed := CampaignSatchelUIThemeScript.make_character_card_style(Color(0.88, 0.84, 0.76, 1.0).lerp(accent, 0.08))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)

func _style_slot_button(button: Button, active: bool) -> void:
	button.add_theme_stylebox_override("normal", CampaignSatchelUIThemeScript.make_button_style(
		CampaignSatchelUIThemeScript.BUTTON_HOVER_TEXTURE if active else CampaignSatchelUIThemeScript.BUTTON_NORMAL_TEXTURE
	))
	button.add_theme_stylebox_override("hover", CampaignSatchelUIThemeScript.make_button_style(CampaignSatchelUIThemeScript.BUTTON_HOVER_TEXTURE))
	button.add_theme_stylebox_override("pressed", CampaignSatchelUIThemeScript.make_button_style(CampaignSatchelUIThemeScript.BUTTON_PRESSED_TEXTURE))
	button.add_theme_stylebox_override("disabled", CampaignSatchelUIThemeScript.make_button_style(CampaignSatchelUIThemeScript.BUTTON_DISABLED_TEXTURE))
