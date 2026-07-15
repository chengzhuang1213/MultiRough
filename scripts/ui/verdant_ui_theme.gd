extends RefCounted
class_name VerdantUITheme

const PANEL_TEXTURE := preload("res://assets/ui/theme/verdant_pixel/panel_large_9slice.png")
const TOOLTIP_TEXTURE := preload("res://assets/ui/theme/verdant_pixel/tooltip_9slice.png")
const TITLE_TEXTURE := preload("res://assets/ui/theme/verdant_pixel/title_plate_9slice.png")
const BUTTON_NORMAL_TEXTURE := preload("res://assets/ui/theme/verdant_pixel/button_normal_9slice.png")
const BUTTON_HOVER_TEXTURE := preload("res://assets/ui/theme/verdant_pixel/button_hover_9slice.png")
const BUTTON_PRESSED_TEXTURE := preload("res://assets/ui/theme/verdant_pixel/button_pressed_9slice.png")
const BUTTON_DISABLED_TEXTURE := preload("res://assets/ui/theme/verdant_pixel/button_disabled_9slice.png")
const INPUT_TEXTURE := preload("res://assets/ui/theme/verdant_pixel/input_field_9slice.png")
const HUD_BAR_TEXTURE := preload("res://assets/ui/theme/verdant_pixel/hud_bar_frame_9slice.png")
const SKILL_SLOT_TEXTURE := preload("res://assets/ui/theme/verdant_pixel/skill_slot_frame.png")
const SEPARATOR_TEXTURE := preload("res://assets/ui/theme/verdant_pixel/separator_tile.png")

const TEXT_PRIMARY := Color(0.96, 0.93, 0.78, 1.0)
const TEXT_MUTED := Color(0.72, 0.78, 0.66, 1.0)
const TEXT_DISABLED := Color(0.47, 0.51, 0.46, 1.0)
const TEXT_OUTLINE := Color(0.025, 0.055, 0.04, 0.96)

static func build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 18
	theme.set_color("font_color", "Label", TEXT_PRIMARY)
	theme.set_color("font_shadow_color", "Label", TEXT_OUTLINE)
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 2)

	theme.set_stylebox("panel", "PanelContainer", make_panel_style())
	theme.set_stylebox("panel", "TooltipPanel", make_tooltip_style())
	theme.set_color("font_color", "TooltipLabel", TEXT_PRIMARY)
	theme.set_font_size("font_size", "TooltipLabel", 16)

	theme.set_stylebox("normal", "Button", make_button_style(BUTTON_NORMAL_TEXTURE))
	theme.set_stylebox("hover", "Button", make_button_style(BUTTON_HOVER_TEXTURE))
	theme.set_stylebox("pressed", "Button", make_button_style(BUTTON_PRESSED_TEXTURE))
	theme.set_stylebox("focus", "Button", make_button_style(BUTTON_HOVER_TEXTURE))
	theme.set_stylebox("disabled", "Button", make_button_style(BUTTON_DISABLED_TEXTURE))
	theme.set_color("font_color", "Button", TEXT_PRIMARY)
	theme.set_color("font_hover_color", "Button", Color(0.98, 1.0, 0.88, 1.0))
	theme.set_color("font_pressed_color", "Button", Color(0.88, 0.92, 0.72, 1.0))
	theme.set_color("font_focus_color", "Button", Color(0.98, 1.0, 0.88, 1.0))
	theme.set_color("font_disabled_color", "Button", TEXT_DISABLED)
	theme.set_color("font_outline_color", "Button", TEXT_OUTLINE)
	theme.set_constant("outline_size", "Button", 2)
	theme.set_font_size("font_size", "Button", 19)

	var input_style := _make_texture_style(INPUT_TEXTURE, Vector4(52, 16, 52, 16), Vector4(28, 9, 28, 9))
	theme.set_stylebox("normal", "LineEdit", input_style)
	theme.set_stylebox("focus", "LineEdit", input_style.duplicate())
	theme.set_stylebox("read_only", "LineEdit", input_style.duplicate())
	theme.set_color("font_color", "LineEdit", TEXT_PRIMARY)
	theme.set_color("font_placeholder_color", "LineEdit", Color(0.64, 0.69, 0.58, 0.78))
	theme.set_color("caret_color", "LineEdit", Color(0.65, 0.94, 0.90, 1.0))
	theme.set_font_size("font_size", "LineEdit", 17)

	theme.set_stylebox("background", "ProgressBar", make_hud_bar_style())
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.42, 0.76, 0.28, 1.0)
	fill.border_color = Color(0.73, 0.91, 0.47, 1.0)
	fill.set_border_width_all(2)
	fill.set_corner_radius_all(5)
	fill.content_margin_left = 16
	fill.content_margin_top = 10
	fill.content_margin_right = 16
	fill.content_margin_bottom = 10
	theme.set_stylebox("fill", "ProgressBar", fill)

	theme.set_stylebox("separator", "HSeparator", make_separator_style())
	theme.set_constant("separation", "VBoxContainer", 12)
	theme.set_constant("separation", "HBoxContainer", 10)
	theme.set_constant("h_separation", "GridContainer", 10)
	theme.set_constant("v_separation", "GridContainer", 8)
	return theme

static func make_panel_style(tint: Color = Color.WHITE) -> StyleBoxTexture:
	return _make_texture_style(PANEL_TEXTURE, Vector4(84, 84, 84, 84), Vector4(34, 30, 34, 30), tint)

static func make_tooltip_style() -> StyleBoxTexture:
	return _make_texture_style(TOOLTIP_TEXTURE, Vector4(36, 28, 36, 28), Vector4(24, 16, 24, 16))

static func make_title_style() -> StyleBoxTexture:
	return _make_texture_style(TITLE_TEXTURE, Vector4(64, 20, 64, 20), Vector4(44, 10, 44, 10))

static func make_button_style(texture: Texture2D) -> StyleBoxTexture:
	return _make_texture_style(texture, Vector4(24, 18, 24, 18), Vector4(18, 10, 18, 10))

static func make_hud_bar_style() -> StyleBoxTexture:
	return _make_texture_style(HUD_BAR_TEXTURE, Vector4(44, 10, 44, 10), Vector4(14, 5, 14, 5))

static func make_skill_slot_style(tint: Color = Color.WHITE) -> StyleBoxTexture:
	return _make_texture_style(SKILL_SLOT_TEXTURE, Vector4(20, 20, 20, 20), Vector4(8, 8, 8, 8), tint)

static func make_separator_style() -> StyleBoxTexture:
	return _make_texture_style(SEPARATOR_TEXTURE, Vector4(60, 7, 60, 7), Vector4(0, 2, 0, 2))

static func _make_texture_style(texture: Texture2D, texture_margins: Vector4, content_margins: Vector4, tint: Color = Color.WHITE) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = texture_margins.x
	style.texture_margin_top = texture_margins.y
	style.texture_margin_right = texture_margins.z
	style.texture_margin_bottom = texture_margins.w
	style.content_margin_left = content_margins.x
	style.content_margin_top = content_margins.y
	style.content_margin_right = content_margins.z
	style.content_margin_bottom = content_margins.w
	style.modulate_color = tint
	return style
