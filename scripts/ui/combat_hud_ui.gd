extends Control
class_name CombatHUDUI

signal next_wave_requested
signal return_confirmation_open_requested
signal return_confirmation_cancel_requested
signal return_to_menu_requested

const PLAYER_HUD_WIDTH := 440.0
const CampaignSatchelUIThemeScript := preload("res://scripts/ui/campaign_satchel_ui_theme.gd")

var hud_left: VBoxContainer
var hud_right: VBoxContainer
var status_label: Label
var wave_label: Label
var enemies_label: Label
var wave_timer_label: Label
var player_hud: PanelContainer
var start_next_wave_button: Button
var return_to_menu_button: Button
var return_confirmation_overlay: Control
var return_confirmation_panel: PanelContainer
var return_confirmation_title: Label
var return_confirmation_warning: Label
var return_confirmation_actions: HBoxContainer
var return_confirm_button: Button
var return_cancel_button: Button
var pause_state_before_confirmation := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	hud_left = VBoxContainer.new()
	hud_left.visible = false
	hud_left.add_theme_constant_override("separation", 6)
	add_child(hud_left)
	status_label = Label.new()
	hud_left.add_child(status_label)
	wave_label = Label.new()
	hud_left.add_child(wave_label)
	enemies_label = Label.new()
	hud_left.add_child(enemies_label)

	wave_timer_label = Label.new()
	wave_timer_label.name = "WaveTimerLabel"
	wave_timer_label.custom_minimum_size = Vector2(120, 48)
	wave_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wave_timer_label.add_theme_font_size_override("font_size", 30)
	wave_timer_label.add_theme_color_override("font_color", Color(0.20, 0.14, 0.08, 1.0))
	wave_timer_label.add_theme_color_override("font_outline_color", Color(1.0, 0.94, 0.78, 0.92))
	wave_timer_label.add_theme_constant_override("outline_size", 3)
	wave_timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wave_timer_label.visible = false
	add_child(wave_timer_label)

	hud_right = VBoxContainer.new()
	hud_right.visible = false
	hud_right.add_theme_constant_override("separation", 6)
	add_child(hud_right)

	player_hud = PanelContainer.new()
	player_hud.visible = false
	player_hud.custom_minimum_size = Vector2(PLAYER_HUD_WIDTH, 0)
	add_child(player_hud)

	start_next_wave_button = Button.new()
	start_next_wave_button.text = "开启下一波"
	start_next_wave_button.custom_minimum_size = Vector2(260, 100)
	start_next_wave_button.add_theme_font_size_override("font_size", 23)
	start_next_wave_button.visible = false
	start_next_wave_button.disabled = true
	start_next_wave_button.mouse_filter = Control.MOUSE_FILTER_STOP
	start_next_wave_button.pressed.connect(func() -> void: next_wave_requested.emit())
	add_child(start_next_wave_button)

	return_to_menu_button = Button.new()
	return_to_menu_button.text = "返回主菜单"
	return_to_menu_button.custom_minimum_size = Vector2(160, 64)
	return_to_menu_button.add_theme_font_size_override("font_size", 17)
	return_to_menu_button.visible = false
	return_to_menu_button.mouse_filter = Control.MOUSE_FILTER_STOP
	return_to_menu_button.pressed.connect(_on_return_button_pressed)
	add_child(return_to_menu_button)

	_build_return_confirmation()

func _build_return_confirmation() -> void:
	return_confirmation_overlay = Control.new()
	return_confirmation_overlay.name = "ReturnConfirmationOverlay"
	return_confirmation_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return_confirmation_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	return_confirmation_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	return_confirmation_overlay.visible = false
	add_child(return_confirmation_overlay)

	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.01, 0.015, 0.025, 0.62)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	return_confirmation_overlay.add_child(backdrop)

	return_confirmation_panel = PanelContainer.new()
	return_confirmation_panel.name = "ReturnConfirmationPanel"
	return_confirmation_panel.custom_minimum_size = Vector2(460, 250)
	return_confirmation_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	return_confirmation_panel.add_theme_stylebox_override("panel", CampaignSatchelUIThemeScript.make_compact_panel_style())
	return_confirmation_overlay.add_child(return_confirmation_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	return_confirmation_panel.add_child(margin)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)

	return_confirmation_title = Label.new()
	return_confirmation_title.text = "返回主菜单？"
	return_confirmation_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return_confirmation_title.add_theme_font_size_override("font_size", 24)
	content.add_child(return_confirmation_title)
	return_confirmation_warning = Label.new()
	return_confirmation_warning.text = "当前游戏进度将会结束。"
	return_confirmation_warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return_confirmation_warning.add_theme_font_size_override("font_size", 16)
	return_confirmation_warning.add_theme_color_override("font_color", CampaignSatchelUIThemeScript.TEXT_MUTED)
	content.add_child(return_confirmation_warning)

	return_confirmation_actions = HBoxContainer.new()
	return_confirmation_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	return_confirmation_actions.add_theme_constant_override("separation", 14)
	content.add_child(return_confirmation_actions)
	return_cancel_button = Button.new()
	return_cancel_button.text = "取消"
	return_cancel_button.custom_minimum_size = Vector2(150, 64)
	return_cancel_button.pressed.connect(_on_return_cancel_pressed)
	return_confirmation_actions.add_child(return_cancel_button)
	return_confirm_button = Button.new()
	return_confirm_button.text = "确认返回"
	return_confirm_button.custom_minimum_size = Vector2(150, 64)
	return_confirm_button.pressed.connect(_on_return_confirm_pressed)
	return_confirmation_actions.add_child(return_confirm_button)

func create_player_hud(player_roster) -> void:
	var skill_labels: Array[String] = ["普攻", "Q", "E", "F"]
	player_roster.create_hud(player_hud, skill_labels, PLAYER_HUD_WIDTH)

func layout(viewport_size: Vector2) -> void:
	hud_left.position = Vector2(16, 16)
	hud_right.position = Vector2(16, 16)
	wave_timer_label.position = Vector2((viewport_size.x - wave_timer_label.custom_minimum_size.x) * 0.5, 24)
	player_hud.position = Vector2(
		maxf(16, (viewport_size.x - PLAYER_HUD_WIDTH) * 0.5),
		maxf(12, viewport_size.y - _hud_height() - 12)
	)
	start_next_wave_button.position = Vector2(
		(viewport_size.x - start_next_wave_button.custom_minimum_size.x) * 0.5,
		viewport_size.y - start_next_wave_button.custom_minimum_size.y - 32
	)
	return_to_menu_button.position = Vector2(
		maxf(16, viewport_size.x - return_to_menu_button.custom_minimum_size.x - 16),
		16
	)
	return_confirmation_panel.position = Vector2(
		(viewport_size.x - return_confirmation_panel.custom_minimum_size.x) * 0.5,
		(viewport_size.y - return_confirmation_panel.custom_minimum_size.y) * 0.5
	)

func _hud_height() -> float:
	return player_hud.size.y if player_hud.size.y > 0 else 120.0

func set_combat_visible(visible: bool) -> void:
	hud_left.visible = visible
	wave_timer_label.visible = visible
	player_hud.visible = visible
	if not visible:
		hud_right.visible = false

func show_return_confirmation(requester_is_local: bool) -> void:
	if return_confirmation_overlay.visible:
		return
	pause_state_before_confirmation = get_tree().paused
	return_confirmation_title.text = "返回主菜单？" if requester_is_local else "队友正在确认返回"
	return_confirmation_warning.text = "当前游戏进度将会结束。" if requester_is_local else "游戏已暂停，请等待队友选择。"
	return_confirmation_actions.visible = requester_is_local
	return_confirmation_overlay.visible = true
	get_tree().paused = true
	if requester_is_local:
		return_cancel_button.grab_focus()

func hide_return_confirmation(force_unpause: bool = false) -> void:
	return_confirmation_overlay.visible = false
	get_tree().paused = false if force_unpause else pause_state_before_confirmation

func _on_return_button_pressed() -> void:
	return_confirmation_open_requested.emit()

func _on_return_cancel_pressed() -> void:
	return_confirmation_cancel_requested.emit()

func _on_return_confirm_pressed() -> void:
	return_to_menu_requested.emit()
