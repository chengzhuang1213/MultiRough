extends Control
class_name UpgradeUI

signal upgrade_selected(upgrade: Dictionary)

const UIFactoryScript := preload("res://scripts/ui/ui_factory.gd")
const CampaignSatchelUIThemeScript := preload("res://scripts/ui/campaign_satchel_ui_theme.gd")
const ReadableTooltipButtonScript := preload("res://scripts/ui/readable_tooltip_button.gd")

const PANEL_SIZE := Vector2(1120, 600)
const CONTENT_WIDTH := 1000.0
const CARD_SIZE := Vector2(294, 380)

var overlay: ColorRect
var panel: PanelContainer
var content: VBoxContainer
var card_art: Dictionary = {}
var stat_icons: Dictionary = {}
var current_text_provider: Callable
var skill_icon_provider: Callable
var card_buttons: Array[Button] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	overlay = ColorRect.new()
	overlay.name = "PausedBattleDim"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.01, 0.02, 0.015, 0.52)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	panel = PanelContainer.new()
	panel.name = "UpgradePanel"
	panel.custom_minimum_size = PANEL_SIZE
	add_child(panel)
	content = UIFactoryScript.attach_panel_content(panel, 18, 16, 18, 16)
	content.add_theme_constant_override("separation", 8)

func setup(art: Dictionary, icons: Dictionary, current_provider: Callable, skill_provider: Callable) -> void:
	card_art = art
	stat_icons = icons
	current_text_provider = current_provider
	skill_icon_provider = skill_provider

func show_options(title_text: String, upgrades: Array, target_player, viewport_size: Vector2) -> void:
	clear_options()
	layout(viewport_size)

	var title := Label.new()
	title.text = title_text
	title.custom_minimum_size = Vector2(CONTENT_WIDTH, 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	title.add_theme_font_size_override("font_size", 28)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "选择一项强化，本轮游戏将立即应用"
	subtitle.custom_minimum_size = Vector2(CONTENT_WIDTH, 20)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", CampaignSatchelUIThemeScript.TEXT_MUTED)
	content.add_child(subtitle)
	content.add_child(UIFactoryScript.build_separator(Vector2(CONTENT_WIDTH, 10)))

	var cards := HBoxContainer.new()
	cards.custom_minimum_size = Vector2(CONTENT_WIDTH, CARD_SIZE.y)
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 38)
	content.add_child(cards)
	for upgrade_value in upgrades:
		var upgrade: Dictionary = upgrade_value as Dictionary
		var button := _build_card(upgrade, target_player, CARD_SIZE)
		button.pressed.connect(_emit_upgrade.bind(upgrade))
		cards.add_child(button)
		card_buttons.append(button)

	var footer := Label.new()
	footer.text = "点击卡片选择升级 · 游戏已暂停"
	footer.custom_minimum_size = Vector2(CONTENT_WIDTH, 20)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_color_override("font_color", CampaignSatchelUIThemeScript.TEXT_MUTED)
	content.add_child(footer)
	visible = true

func clear_options() -> void:
	card_buttons.clear()
	if content == null:
		return
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

func set_selection_enabled(enabled: bool) -> void:
	for button in card_buttons:
		if is_instance_valid(button):
			button.disabled = not enabled

func build_badge_preview(upgrade: Dictionary, accent: Color) -> Control:
	return _build_badge(upgrade, accent)

func layout(viewport_size: Vector2) -> void:
	position = Vector2.ZERO
	if panel != null:
		panel.position = (viewport_size - PANEL_SIZE) * 0.5

func _emit_upgrade(upgrade: Dictionary) -> void:
	upgrade_selected.emit(upgrade)

func _build_card(upgrade: Dictionary, target_player, card_size: Vector2) -> Button:
	var rarity := str(upgrade.get("rarity", "Common"))
	var accent := _rarity_color(rarity)
	var current_text := _current_text(upgrade, target_player)
	var button := ReadableTooltipButtonScript.new()
	button.tooltip_accent = accent
	button.custom_minimum_size = card_size
	button.clip_contents = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = "%s\n%s\n\n当前：%s\n升级后：%s" % [
		upgrade.get("title", "升级"),
		upgrade.get("description", ""),
		current_text,
		_compact_effect(upgrade),
	]
	_style_card_button(button, accent)

	var background := TextureRect.new()
	background.texture = load(str(card_art.get(rarity, card_art.get("Common", "")))) as Texture2D
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.offset_left = 2
	background.offset_top = 2
	background.offset_right = -2
	background.offset_bottom = -2
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)

	var card_content := VBoxContainer.new()
	card_content.add_theme_constant_override("separation", 6)
	card_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(card_content)

	var rarity_center := CenterContainer.new()
	rarity_center.custom_minimum_size = Vector2(254, 24)
	card_content.add_child(rarity_center)
	var rarity_panel := PanelContainer.new()
	rarity_panel.custom_minimum_size = Vector2(90, 24)
	rarity_panel.add_theme_stylebox_override("panel", _make_rarity_style(accent))
	rarity_center.add_child(rarity_panel)
	var rarity_label := Label.new()
	rarity_label.text = _format_rarity(rarity)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 13)
	rarity_label.add_theme_color_override("font_color", accent)
	rarity_panel.add_child(rarity_label)

	var badge_center := CenterContainer.new()
	badge_center.custom_minimum_size = Vector2(254, 76)
	badge_center.add_child(_build_badge(upgrade, accent))
	card_content.add_child(badge_center)

	var title := Label.new()
	title.text = _short_title(str(upgrade.get("title", "升级")))
	title.custom_minimum_size = Vector2(254, 38)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 20)
	card_content.add_child(title)
	card_content.add_child(UIFactoryScript.build_separator(Vector2(220, 8)))

	var description := Label.new()
	description.text = str(upgrade.get("description", ""))
	description.custom_minimum_size = Vector2(254, 58)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 14)
	description.add_theme_color_override("font_color", CampaignSatchelUIThemeScript.TEXT_MUTED)
	card_content.add_child(description)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_content.add_child(spacer)

	var result_panel := PanelContainer.new()
	result_panel.custom_minimum_size = Vector2(254, 64)
	result_panel.add_theme_stylebox_override("panel", _make_result_style(accent))
	card_content.add_child(result_panel)
	var result_content := VBoxContainer.new()
	result_content.add_theme_constant_override("separation", 2)
	result_panel.add_child(result_content)
	var current := Label.new()
	current.text = "当前 · %s" % current_text
	current.add_theme_font_size_override("font_size", 13)
	current.add_theme_color_override("font_color", Color(0.82, 0.82, 0.78, 1.0))
	result_content.add_child(current)
	var after := Label.new()
	after.text = "升级后 · %s" % _compact_effect(upgrade)
	after.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	after.add_theme_font_size_override("font_size", 14)
	after.add_theme_color_override("font_color", Color(0.52, 0.72, 1.0, 1.0))
	result_content.add_child(after)
	_ignore_card_mouse_input(button)
	return button

func _ignore_card_mouse_input(card: Button) -> void:
	for child in card.find_children("*", "Control", true, false):
		(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

func _build_badge(upgrade: Dictionary, accent: Color) -> Control:
	var badge_size := Vector2(70, 70)
	var skill_slot := str(upgrade.get("skill_slot", ""))
	if not skill_slot.is_empty():
		var skill_panel := PanelContainer.new()
		skill_panel.custom_minimum_size = badge_size
		var style := CampaignSatchelUIThemeScript.make_skill_slot_style(Color.WHITE.lerp(accent, 0.10))
		style.content_margin_left = 7
		style.content_margin_top = 7
		style.content_margin_right = 7
		style.content_margin_bottom = 7
		skill_panel.add_theme_stylebox_override("panel", style)
		skill_panel.clip_contents = true
		var icon := TextureRect.new()
		icon.texture = load(str(skill_icon_provider.call(str(upgrade.get("character_id", "")), skill_slot))) as Texture2D
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		skill_panel.add_child(icon)
		var label := Label.new()
		label.text = skill_slot.to_upper()
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_outline_color", Color(0.015, 0.02, 0.035, 0.98))
		label.add_theme_constant_override("outline_size", 4)
		skill_panel.add_child(label)
		return skill_panel
	var icon := TextureRect.new()
	icon.texture = load(_stat_icon_path(str(upgrade.get("stat", "")))) as Texture2D
	icon.custom_minimum_size = badge_size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon

func _current_text(upgrade: Dictionary, target_player) -> String:
	return str(current_text_provider.call(upgrade, target_player))

func _stat_icon_path(stat: String) -> String:
	if stat in ["max_health", "heal_percent", "lifesteal"]:
		return str(stat_icons.get("health", ""))
	if stat in ["move_speed", "dash_cooldown", "dash_charges"]:
		return str(stat_icons.get("speed", ""))
	if stat.ends_with("cooldown") or stat.ends_with("duration"):
		return str(stat_icons.get("cooldown", ""))
	return str(stat_icons.get("attack", ""))

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"Rare": return Color(0.32, 0.88, 1.0)
		"Epic": return Color(1.0, 0.34, 0.28)
		_: return Color(0.88, 0.72, 0.37)

func _format_rarity(rarity: String) -> String:
	match rarity:
		"Common": return "普通"
		"Rare": return "稀有"
		"Epic": return "史诗"
		_: return rarity

func _short_title(title: String) -> String:
	var separator_index := title.find("·")
	return title.substr(separator_index + 1).strip_edges() if separator_index >= 0 else title

func _compact_effect(upgrade: Dictionary) -> String:
	if upgrade.has("amount"):
		var percent := roundi(float(upgrade.get("amount", 0.0)) * 100.0)
		var stat := str(upgrade.get("stat", ""))
		var stat_names: Dictionary = {
			"attack_damage": "攻击伤害",
			"attack_cooldown": "攻击冷却",
			"attack_range": "攻击范围",
			"max_health": "最大生命",
			"move_speed": "移动速度",
			"knockback": "击退力量",
			"crit_chance": "暴击率",
			"lifesteal": "吸血",
			"skill_cooldown": "技能冷却",
		}
		var stat_name: String = str(stat_names.get(stat, "属性"))
		var sign := "-" if stat.ends_with("cooldown") else "+"
		return "%s %s%d%%" % [stat_name, sign, percent]
	var description := str(upgrade.get("description", "")).trim_suffix("。")
	var comma_index := description.find("，")
	if comma_index > 0:
		description = description.left(comma_index)
	return description.left(18) + ("…" if description.length() > 18 else "")

func _make_rarity_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CampaignSatchelUIThemeScript.ACCENT_BLUE_DARK
	style.border_color = accent
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 8
	style.content_margin_right = 8
	return style

func _make_result_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CampaignSatchelUIThemeScript.ACCENT_BLUE_DARK
	style.border_color = accent
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_top = 6
	style.content_margin_right = 10
	style.content_margin_bottom = 6
	return style

func _style_card_button(button: Button, accent: Color) -> void:
	var normal := StyleBoxFlat.new()
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
