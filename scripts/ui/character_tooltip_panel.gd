extends PanelContainer
class_name CharacterTooltipPanel

const CONTENT_WIDTH := 310.0
const BASE_BACKGROUND := Color(0.012, 0.040, 0.055, 0.98)

var tooltip_accent := Color(0.88, 0.72, 0.37, 1.0)

func _make_custom_tooltip(for_text: String) -> Object:
	var panel := PanelContainer.new()
	panel.name = "CharacterTooltipPanel"
	panel.add_theme_stylebox_override("panel", _make_tooltip_style())
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label := Label.new()
	label.name = "CharacterTooltipLabel"
	label.text = for_text
	label.custom_minimum_size = Vector2(CONTENT_WIDTH, 0.0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.97, 0.95, 0.88, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.03, 0.98))
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	return panel

func _make_tooltip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BASE_BACKGROUND.lerp(tooltip_accent, 0.12)
	style.border_color = tooltip_accent
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.content_margin_left = 14
	style.content_margin_top = 10
	style.content_margin_right = 14
	style.content_margin_bottom = 10
	return style
