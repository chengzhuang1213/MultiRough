extends Control
class_name CombatHUDUI

signal next_wave_requested
signal return_to_menu_requested

const PLAYER_HUD_WIDTH := 440.0

var hud_left: VBoxContainer
var hud_right: VBoxContainer
var status_label: Label
var wave_label: Label
var enemies_label: Label
var player_hud: PanelContainer
var start_next_wave_button: Button
var return_to_menu_button: Button

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
	start_next_wave_button.custom_minimum_size = Vector2(220, 60)
	start_next_wave_button.visible = false
	start_next_wave_button.disabled = true
	start_next_wave_button.mouse_filter = Control.MOUSE_FILTER_STOP
	start_next_wave_button.pressed.connect(func() -> void: next_wave_requested.emit())
	add_child(start_next_wave_button)

	return_to_menu_button = Button.new()
	return_to_menu_button.text = "返回主菜单"
	return_to_menu_button.custom_minimum_size = Vector2(160, 60)
	return_to_menu_button.visible = false
	return_to_menu_button.mouse_filter = Control.MOUSE_FILTER_STOP
	return_to_menu_button.pressed.connect(func() -> void: return_to_menu_requested.emit())
	add_child(return_to_menu_button)

func create_player_hud(player_roster) -> void:
	var skill_labels: Array[String] = ["普攻", "Q", "E", "F"]
	player_roster.create_hud(player_hud, skill_labels, PLAYER_HUD_WIDTH)

func layout(viewport_size: Vector2) -> void:
	hud_left.position = Vector2(16, 16)
	hud_right.position = Vector2(16, 16)
	player_hud.position = Vector2(
		maxf(16, (viewport_size.x - PLAYER_HUD_WIDTH) * 0.5),
		maxf(12, viewport_size.y - _hud_height() - 12)
	)
	start_next_wave_button.position = Vector2(
		(viewport_size.x - start_next_wave_button.custom_minimum_size.x) * 0.5,
		viewport_size.y - 92
	)
	return_to_menu_button.position = Vector2(
		maxf(16, viewport_size.x - return_to_menu_button.custom_minimum_size.x - 16),
		16
	)

func _hud_height() -> float:
	return player_hud.size.y if player_hud.size.y > 0 else 120.0

func set_combat_visible(visible: bool) -> void:
	hud_left.visible = visible
	player_hud.visible = visible
	if not visible:
		hud_right.visible = false

func update_status(state_text: String, wave_text: String, enemies_text: String) -> void:
	status_label.text = state_text
	wave_label.text = wave_text
	enemies_label.text = enemies_text
