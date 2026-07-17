extends Control
class_name RestUI

signal ready_pressed

const UIFactoryScript := preload("res://scripts/ui/ui_factory.gd")
const CampaignSatchelUIThemeScript := preload("res://scripts/ui/campaign_satchel_ui_theme.gd")
const ReadableTooltipButtonScript := preload("res://scripts/ui/readable_tooltip_button.gd")

const BAR_SIZE := Vector2(1210, 134)
const SKILL_BUTTON_SIZE := Vector2(60, 60)
const INFO_BUTTON_SIZE := Vector2(198, 78)

var panel: PanelContainer
var title_label: Label
var avatar_label: Label
var skill_buttons: Array[Button] = []
var latest_label: Label
var build_label: Label
var intel_label: Label
var latest_button
var build_button: Button
var intel_button
var latest_icon: TextureRect
var build_icon: TextureRect
var intel_icon: TextureRect
var ready_status_label: Label
var ready_button: Button
var stats_dismiss_layer: Control
var stats_drawer: PanelContainer
var stats_text: RichTextLabel

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	panel = PanelContainer.new()
	panel.name = "RestCharacterHUD"
	panel.custom_minimum_size = BAR_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", CampaignSatchelUIThemeScript.make_rest_bar_style())
	add_child(panel)
	var content := UIFactoryScript.attach_panel_content(panel, 10, 8, 10, 8)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	content.add_child(row)

	var avatar_frame := PanelContainer.new()
	avatar_frame.name = "PortraitPlaceholder"
	avatar_frame.custom_minimum_size = Vector2(86, 86)
	avatar_frame.clip_contents = true
	avatar_frame.add_theme_stylebox_override("panel", CampaignSatchelUIThemeScript.make_skill_slot_style())
	row.add_child(avatar_frame)
	avatar_label = Label.new()
	avatar_label.text = "头像\n待补"
	avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar_label.add_theme_font_size_override("font_size", 15)
	avatar_label.add_theme_color_override("font_color", CampaignSatchelUIThemeScript.TEXT_MUTED)
	avatar_frame.add_child(avatar_label)
	title_label = avatar_label

	var skills_box := VBoxContainer.new()
	skills_box.name = "SkillsSection"
	skills_box.custom_minimum_size = Vector2(204, 88)
	skills_box.alignment = BoxContainer.ALIGNMENT_CENTER
	skills_box.add_theme_constant_override("separation", 2)
	row.add_child(skills_box)
	var skills_heading := Label.new()
	skills_heading.text = "Q / E / F 技能"
	skills_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skills_heading.add_theme_font_size_override("font_size", 13)
	skills_heading.add_theme_color_override("font_color", CampaignSatchelUIThemeScript.TEXT_MUTED)
	skills_box.add_child(skills_heading)
	var skills_row := HBoxContainer.new()
	skills_row.alignment = BoxContainer.ALIGNMENT_CENTER
	skills_row.add_theme_constant_override("separation", 6)
	skills_box.add_child(skills_row)
	for key in ["Q", "E", "F"]:
		var skill_button := _build_skill_button(key)
		skill_buttons.append(skill_button)
		skills_row.add_child(skill_button)

	var stats_result := _build_info_button("详细属性", "点击查看")
	build_button = stats_result["button"]
	build_button.name = "DetailedStatsButton"
	build_icon = stats_result["icon"]
	build_label = stats_result["label"]
	build_button.pressed.connect(_toggle_stats_drawer)
	row.add_child(build_button)

	var latest_result := _build_info_button("上轮卡牌", "暂无记录")
	latest_button = latest_result["button"]
	latest_button.name = "LastCardButton"
	latest_icon = latest_result["icon"]
	latest_label = latest_result["label"]
	row.add_child(latest_button)

	var intel_result := _build_info_button("下轮敌人", "暂无情报")
	intel_button = intel_result["button"]
	intel_button.name = "NextEnemyButton"
	intel_icon = intel_result["icon"]
	intel_label = intel_result["label"]
	row.add_child(intel_button)

	var ready_box := VBoxContainer.new()
	ready_box.name = "ReadySection"
	ready_box.custom_minimum_size = Vector2(150, 88)
	ready_box.alignment = BoxContainer.ALIGNMENT_CENTER
	ready_box.add_theme_constant_override("separation", 2)
	row.add_child(ready_box)
	ready_status_label = Label.new()
	ready_status_label.custom_minimum_size = Vector2(150, 22)
	ready_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ready_status_label.clip_text = true
	ready_status_label.add_theme_font_size_override("font_size", 12)
	ready_status_label.add_theme_color_override("font_color", CampaignSatchelUIThemeScript.TEXT_MUTED)
	ready_box.add_child(ready_status_label)
	ready_button = Button.new()
	ready_button.text = "准备完成"
	ready_button.custom_minimum_size = Vector2(150, 60)
	ready_button.add_theme_font_size_override("font_size", 17)
	ready_button.pressed.connect(_on_ready_button_pressed)
	ready_box.add_child(ready_button)

	_build_stats_drawer()

func _build_skill_button(key: String) -> Button:
	var button = ReadableTooltipButtonScript.new()
	button.name = "%sSkillInfo" % key
	button.custom_minimum_size = SKILL_BUTTON_SIZE
	button.clip_contents = true
	_apply_skill_button_style(button)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.position = Vector2(9, 9)
	icon.size = Vector2(42, 42)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)
	var key_label := Label.new()
	key_label.text = key
	key_label.position = Vector2(4, 3)
	key_label.size = Vector2(24, 22)
	key_label.add_theme_font_size_override("font_size", 14)
	key_label.add_theme_color_override("font_color", Color.WHITE)
	key_label.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.01, 1.0))
	key_label.add_theme_constant_override("outline_size", 3)
	key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(key_label)
	return button

func _build_info_button(heading_text: String, default_summary: String) -> Dictionary:
	var button = ReadableTooltipButtonScript.new()
	button.custom_minimum_size = INFO_BUTTON_SIZE
	button.clip_contents = true
	button.tooltip_accent = Color(0.82, 0.70, 0.34, 1.0)
	_apply_info_button_style(button)
	var icon_frame := PanelContainer.new()
	icon_frame.name = "InfoIconFrame"
	icon_frame.position = Vector2(10, 11)
	icon_frame.size = Vector2(54, 54)
	icon_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_frame.add_theme_stylebox_override("panel", CampaignSatchelUIThemeScript.make_skill_slot_style())
	button.add_child(icon_frame)
	var icon := TextureRect.new()
	icon.name = "InfoIcon"
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 6.0
	icon.offset_top = 6.0
	icon.offset_right = -6.0
	icon.offset_bottom = -6.0
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_frame.add_child(icon)
	var heading := Label.new()
	heading.text = heading_text
	heading.position = Vector2(72, 10)
	heading.size = Vector2(112, 20)
	heading.add_theme_font_size_override("font_size", 13)
	heading.add_theme_color_override("font_color", CampaignSatchelUIThemeScript.TEXT_MUTED)
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(heading)
	var summary := Label.new()
	summary.text = default_summary
	summary.position = Vector2(72, 31)
	summary.size = Vector2(112, 36)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	summary.add_theme_font_size_override("font_size", 14)
	summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(summary)
	return {"button": button, "icon": icon, "label": summary}

func _apply_skill_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", CampaignSatchelUIThemeScript.make_skill_slot_style())
	button.add_theme_stylebox_override("hover", CampaignSatchelUIThemeScript.make_skill_slot_style(Color(0.88, 0.94, 1.0, 1.0)))
	button.add_theme_stylebox_override("pressed", CampaignSatchelUIThemeScript.make_skill_slot_style(Color(0.76, 0.82, 0.90, 1.0)))
	button.add_theme_stylebox_override("focus", CampaignSatchelUIThemeScript.make_skill_slot_style(Color(0.88, 0.94, 1.0, 1.0)))

func _apply_info_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", CampaignSatchelUIThemeScript.make_button_style(CampaignSatchelUIThemeScript.BUTTON_NORMAL_TEXTURE))
	button.add_theme_stylebox_override("hover", CampaignSatchelUIThemeScript.make_button_style(CampaignSatchelUIThemeScript.BUTTON_HOVER_TEXTURE))
	button.add_theme_stylebox_override("pressed", CampaignSatchelUIThemeScript.make_button_style(CampaignSatchelUIThemeScript.BUTTON_PRESSED_TEXTURE))
	button.add_theme_stylebox_override("focus", CampaignSatchelUIThemeScript.make_button_style(CampaignSatchelUIThemeScript.BUTTON_HOVER_TEXTURE))

func _build_stats_drawer() -> void:
	stats_dismiss_layer = Control.new()
	stats_dismiss_layer.name = "StatsDismissLayer"
	stats_dismiss_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stats_dismiss_layer.visible = false
	stats_dismiss_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	stats_dismiss_layer.gui_input.connect(_on_stats_dismiss_gui_input)
	add_child(stats_dismiss_layer)

	stats_drawer = PanelContainer.new()
	stats_drawer.name = "DetailedStatsDrawer"
	stats_drawer.custom_minimum_size = Vector2(430, 400)
	stats_drawer.visible = false
	stats_drawer.mouse_filter = Control.MOUSE_FILTER_STOP
	stats_drawer.add_theme_stylebox_override("panel", CampaignSatchelUIThemeScript.make_compact_panel_style())
	add_child(stats_drawer)
	var content := UIFactoryScript.attach_panel_content(stats_drawer, 18, 14, 18, 14)
	content.add_theme_constant_override("separation", 6)
	var heading := Label.new()
	heading.text = "详细属性与当前构筑"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 22)
	content.add_child(heading)
	content.add_child(UIFactoryScript.build_separator(Vector2(370, 6)))
	stats_text = RichTextLabel.new()
	stats_text.custom_minimum_size = Vector2(380, 300)
	stats_text.fit_content = false
	stats_text.scroll_active = true
	stats_text.add_theme_font_size_override("normal_font_size", 16)
	stats_text.add_theme_color_override("default_color", CampaignSatchelUIThemeScript.TEXT_PRIMARY)
	stats_text.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	stats_text.add_theme_constant_override("outline_size", 0)
	content.add_child(stats_text)
	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(180, 48)
	close_button.pressed.connect(_toggle_stats_drawer)
	content.add_child(close_button)

func _toggle_stats_drawer() -> void:
	_set_stats_drawer_visible(not stats_drawer.visible)

func _set_stats_drawer_visible(open: bool) -> void:
	stats_dismiss_layer.visible = open
	stats_drawer.visible = open

func _on_stats_dismiss_gui_input(event: InputEvent) -> void:
	var mouse_click := event as InputEventMouseButton
	if mouse_click != null and mouse_click.pressed:
		_set_stats_drawer_visible(false)
		stats_dismiss_layer.accept_event()
		return
	var touch := event as InputEventScreenTouch
	if touch != null and touch.pressed:
		_set_stats_drawer_visible(false)
		stats_dismiss_layer.accept_event()

func _on_ready_button_pressed() -> void:
	ready_pressed.emit()

func show_rest(title_text: String, latest_text: String, build_text: String, intel_text: String, viewport_size: Vector2, icon_paths: Array = [], summaries: Array = [], hud_context: Dictionary = {}) -> void:
	avatar_label.text = "%s\n头像待补" % str(hud_context.get("character_name", "角色"))
	var skill_entries := hud_context.get("skills", []) as Array
	for index in range(skill_buttons.size()):
		var entry: Dictionary = skill_entries[index] as Dictionary if index < skill_entries.size() else {}
		var icon := skill_buttons[index].get_node("Icon") as TextureRect
		_set_icon(icon, str(entry.get("icon", "")))
		skill_buttons[index].tooltip_text = str(entry.get("tooltip", "技能信息待补"))
	_set_icon(build_icon, str(hud_context.get("stats_icon", icon_paths[1] if icon_paths.size() > 1 else "")))
	_set_icon(latest_icon, str(hud_context.get("latest_icon", icon_paths[0] if icon_paths.size() > 0 else "")))
	_set_icon(intel_icon, str(hud_context.get("intel_icon", icon_paths[2] if icon_paths.size() > 2 else "")))
	build_label.text = "点击查看"
	latest_label.text = str(hud_context.get("latest_summary", summaries[0] if summaries.size() > 0 else "暂无记录"))
	intel_label.text = str(hud_context.get("intel_summary", summaries[2] if summaries.size() > 2 else intel_text.get_slice("\n", 0)))
	build_button.tooltip_text = "点击打开详细属性、冷却与当前构筑"
	latest_button.tooltip_text = "上轮获得卡牌\n\n%s" % latest_text
	intel_button.tooltip_text = "下轮敌人信息\n\n%s" % intel_text
	stats_text.text = str(hud_context.get("stats_text", build_text))
	_set_stats_drawer_visible(false)
	layout(viewport_size)
	visible = true

func _set_icon(target: TextureRect, path: String) -> void:
	target.texture = load(path) as Texture2D if not path.is_empty() else null

func set_ready_state(status_text_value: String, button_text: String, enabled: bool) -> void:
	ready_status_label.text = status_text_value
	ready_button.text = button_text
	ready_button.disabled = not enabled

func hide_rest() -> void:
	visible = false
	if stats_drawer != null and stats_dismiss_layer != null:
		_set_stats_drawer_visible(false)

func layout(viewport_size: Vector2) -> void:
	position = Vector2.ZERO
	if panel != null:
		var horizontal_margin := maxf(8.0, (viewport_size.x - BAR_SIZE.x) * 0.5)
		panel.anchor_left = 0.0
		panel.anchor_top = 0.0
		panel.anchor_right = 1.0
		panel.anchor_bottom = 0.0
		panel.offset_left = horizontal_margin
		panel.offset_top = 10.0
		panel.offset_right = -horizontal_margin
		panel.offset_bottom = 10.0 + BAR_SIZE.y
	if stats_drawer != null:
		stats_drawer.position = Vector2((viewport_size.x - 430.0) * 0.5, BAR_SIZE.y + 18.0)
