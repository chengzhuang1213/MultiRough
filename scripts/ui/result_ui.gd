extends Control
class_name ResultUI

signal restart_requested

const UIFactoryScript := preload("res://scripts/ui/ui_factory.gd")

var panel: PanelContainer
var result_label: Label
var restart_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(430, 290)
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	var content := UIFactoryScript.attach_panel_content(panel, 36, 28, 36, 28)
	result_label = Label.new()
	result_label.custom_minimum_size = Vector2(350, 210)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 28)
	content.add_child(result_label)

	restart_button = Button.new()
	restart_button.text = "重新开始"
	restart_button.custom_minimum_size = Vector2(184, 60)
	restart_button.visible = false
	restart_button.mouse_filter = Control.MOUSE_FILTER_STOP
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	add_child(restart_button)

func layout(viewport_size: Vector2) -> void:
	if panel == null or restart_button == null:
		return
	panel.position = (viewport_size - panel.custom_minimum_size) * 0.5 + Vector2(0, -36)
	restart_button.position = Vector2(
		(viewport_size.x - restart_button.custom_minimum_size.x) * 0.5,
		viewport_size.y * 0.5 + 150
	)

func show_result(text: String, viewport_size: Vector2) -> void:
	result_label.text = text
	panel.visible = true
	restart_button.visible = true
	layout(viewport_size)

func hide_result() -> void:
	panel.visible = false
	restart_button.visible = false
