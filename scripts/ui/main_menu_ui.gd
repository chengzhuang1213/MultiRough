extends PanelContainer
class_name MainMenuUI

signal single_player_requested
signal host_requested
signal join_requested

const UIFactoryScript := preload("res://scripts/ui/ui_factory.gd")
const CampaignSatchelUIThemeScript := preload("res://scripts/ui/campaign_satchel_ui_theme.gd")

const PANEL_SIZE := Vector2(800, 680)
const CONTENT_WIDTH := 500.0
const CONTROL_HEIGHT := 100.0

var content: VBoxContainer
var network_ip_edit: LineEdit
var network_status_label: Label

func _ready() -> void:
	custom_minimum_size = PANEL_SIZE
	content = UIFactoryScript.attach_panel_content(self, 116, 56, 116, 48)
	content.add_theme_constant_override("separation", 10)

	var title := Label.new()
	title.text = "MultiRough"
	title.custom_minimum_size = Vector2(CONTENT_WIDTH, 52)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", CampaignSatchelUIThemeScript.TEXT_PRIMARY)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "并肩作战 · 构筑你的战斗流派"
	subtitle.custom_minimum_size = Vector2(CONTENT_WIDTH, 24)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", CampaignSatchelUIThemeScript.TEXT_MUTED)
	content.add_child(subtitle)

	content.add_child(UIFactoryScript.build_separator(Vector2(CONTENT_WIDTH, 12)))

	var single_button := Button.new()
	single_button.text = "单人游戏"
	single_button.custom_minimum_size = Vector2(CONTENT_WIDTH, CONTROL_HEIGHT)
	single_button.add_theme_font_size_override("font_size", 24)
	single_button.pressed.connect(func() -> void: single_player_requested.emit())
	content.add_child(single_button)

	var network_title := Label.new()
	network_title.text = "联机游戏"
	network_title.custom_minimum_size = Vector2(CONTENT_WIDTH, 28)
	network_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	network_title.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	network_title.add_theme_font_size_override("font_size", 18)
	content.add_child(network_title)
	content.add_child(UIFactoryScript.build_separator(Vector2(CONTENT_WIDTH, 10)))

	network_ip_edit = LineEdit.new()
	network_ip_edit.placeholder_text = "主机 IP，例如 192.168.1.8"
	network_ip_edit.custom_minimum_size = Vector2(CONTENT_WIDTH, CONTROL_HEIGHT)
	network_ip_edit.add_theme_font_size_override("font_size", 20)
	content.add_child(network_ip_edit)

	var network_row := HBoxContainer.new()
	network_row.custom_minimum_size = Vector2(CONTENT_WIDTH, CONTROL_HEIGHT)
	network_row.add_theme_constant_override("separation", 14)
	content.add_child(network_row)

	var host_button := Button.new()
	host_button.text = "创建房间"
	host_button.custom_minimum_size = Vector2(242, CONTROL_HEIGHT)
	host_button.add_theme_font_size_override("font_size", 22)
	host_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host_button.pressed.connect(func() -> void: host_requested.emit())
	network_row.add_child(host_button)

	var join_button := Button.new()
	join_button.text = "加入房间"
	join_button.custom_minimum_size = Vector2(242, CONTROL_HEIGHT)
	join_button.add_theme_font_size_override("font_size", 22)
	join_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join_button.pressed.connect(func() -> void: join_requested.emit())
	network_row.add_child(join_button)

	network_status_label = Label.new()
	network_status_label.custom_minimum_size = Vector2(CONTENT_WIDTH, 40)
	network_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	network_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	network_status_label.add_theme_font_size_override("font_size", 14)
	network_status_label.add_theme_color_override("font_color", CampaignSatchelUIThemeScript.TEXT_MUTED)
	content.add_child(network_status_label)

func set_status(text: String) -> void:
	if network_status_label != null:
		network_status_label.text = text
