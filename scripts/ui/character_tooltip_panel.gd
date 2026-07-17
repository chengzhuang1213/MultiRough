extends PanelContainer
class_name CharacterTooltipPanel

const CONTENT_WIDTH := 310.0
const CampaignSatchelUIThemeScript := preload("res://scripts/ui/campaign_satchel_ui_theme.gd")

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
	label.add_theme_color_override("font_color", CampaignSatchelUIThemeScript.TOOLTIP_TEXT)
	label.add_theme_color_override("font_outline_color", CampaignSatchelUIThemeScript.TOOLTIP_OUTLINE)
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	return panel

func _make_tooltip_style() -> StyleBoxTexture:
	return CampaignSatchelUIThemeScript.make_tooltip_style(tooltip_accent)
