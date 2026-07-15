extends RefCounted
class_name UIFactory

const VerdantUIThemeScript := preload("res://scripts/ui/verdant_ui_theme.gd")

static func attach_panel_content(panel: PanelContainer, left: int, top: int, right: int, bottom: int) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	margin.add_child(content)
	return content

static func build_title_plate(text: String, minimum_size: Vector2, font_size: int) -> PanelContainer:
	var plate := PanelContainer.new()
	plate.custom_minimum_size = minimum_size
	plate.add_theme_stylebox_override("panel", VerdantUIThemeScript.make_title_style())
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", VerdantUIThemeScript.TEXT_OUTLINE)
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(label)
	return plate

static func build_separator(minimum_size: Vector2) -> HSeparator:
	var separator := HSeparator.new()
	separator.custom_minimum_size = minimum_size
	separator.add_theme_stylebox_override("separator", VerdantUIThemeScript.make_separator_style())
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return separator
