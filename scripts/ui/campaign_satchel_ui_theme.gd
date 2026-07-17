extends RefCounted
class_name CampaignSatchelUITheme

const PANEL_TEXTURE := preload("res://assets/ui/theme/campaign_satchel/panel_large_9slice.png")
const TOOLTIP_TEXTURE := preload("res://assets/ui/theme/campaign_satchel/tooltip_9slice.png")
const TITLE_TEXTURE := preload("res://assets/ui/theme/campaign_satchel/title_plate_9slice.png")
const BUTTON_NORMAL_TEXTURE := preload("res://assets/ui/theme/campaign_satchel/button_normal_9slice.png")
const BUTTON_HOVER_TEXTURE := preload("res://assets/ui/theme/campaign_satchel/button_hover_9slice.png")
const BUTTON_PRESSED_TEXTURE := preload("res://assets/ui/theme/campaign_satchel/button_pressed_9slice.png")
const BUTTON_DISABLED_TEXTURE := preload("res://assets/ui/theme/campaign_satchel/button_disabled_9slice.png")
const INPUT_TEXTURE := preload("res://assets/ui/theme/campaign_satchel/input_field_9slice.png")
const HUD_BAR_TEXTURE := preload("res://assets/ui/theme/campaign_satchel/hud_bar_frame_9slice.png")
const SKILL_SLOT_TEXTURE := preload("res://assets/ui/theme/campaign_satchel/skill_slot_frame.png")
const SEPARATOR_TEXTURE := preload("res://assets/ui/theme/campaign_satchel/separator_tile.png")
const CHARACTER_CARD_TEXTURE := preload("res://assets/ui/theme/campaign_satchel/upgrade_card_common.png")

const TEXT_PRIMARY := Color(0.20, 0.14, 0.08, 1.0)
const TEXT_MUTED := Color(0.40, 0.31, 0.22, 1.0)
const TEXT_DISABLED := Color(0.48, 0.45, 0.39, 1.0)
const TEXT_OUTLINE := Color(1.0, 0.94, 0.78, 0.82)
const TOOLTIP_TEXT := Color(0.98, 0.94, 0.82, 1.0)
const TOOLTIP_OUTLINE := Color(0.015, 0.025, 0.045, 0.98)
const ACCENT_BLUE := Color(0.20, 0.43, 0.74, 1.0)
const ACCENT_BLUE_DARK := Color(0.035, 0.10, 0.20, 0.98)
const ACCENT_BRASS := Color(0.72, 0.52, 0.20, 1.0)

static func build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 18
	theme.set_color("font_color", "Label", TEXT_PRIMARY)
	theme.set_color("font_shadow_color", "Label", Color(1.0, 0.94, 0.80, 0.54))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)

	theme.set_stylebox("panel", "PanelContainer", make_panel_style())
	# Godot wraps the object returned by _make_custom_tooltip() in TooltipPanel.
	# Keep that host transparent because our custom tooltip already draws the frame.
	theme.set_stylebox("panel", "TooltipPanel", make_tooltip_host_style())
	theme.set_color("font_color", "TooltipLabel", TOOLTIP_TEXT)
	theme.set_font_size("font_size", "TooltipLabel", 16)

	theme.set_stylebox("normal", "Button", make_button_style(BUTTON_NORMAL_TEXTURE))
	theme.set_stylebox("hover", "Button", make_button_style(BUTTON_HOVER_TEXTURE))
	theme.set_stylebox("pressed", "Button", make_button_style(BUTTON_PRESSED_TEXTURE))
	theme.set_stylebox("focus", "Button", make_button_style(BUTTON_HOVER_TEXTURE))
	theme.set_stylebox("disabled", "Button", make_button_style(BUTTON_DISABLED_TEXTURE))
	theme.set_color("font_color", "Button", TEXT_PRIMARY)
	theme.set_color("font_hover_color", "Button", Color(0.08, 0.20, 0.38, 1.0))
	theme.set_color("font_pressed_color", "Button", Color(0.12, 0.10, 0.08, 1.0))
	theme.set_color("font_focus_color", "Button", Color(0.08, 0.20, 0.38, 1.0))
	theme.set_color("font_disabled_color", "Button", TEXT_DISABLED)
	theme.set_color("font_outline_color", "Button", TEXT_OUTLINE)
	theme.set_constant("outline_size", "Button", 1)
	theme.set_font_size("font_size", "Button", 19)

	var input_style := _make_texture_style(INPUT_TEXTURE, Vector4(52, 16, 52, 16), Vector4(62, 9, 62, 9))
	theme.set_stylebox("normal", "LineEdit", input_style)
	theme.set_stylebox("focus", "LineEdit", input_style.duplicate())
	theme.set_stylebox("read_only", "LineEdit", input_style.duplicate())
	theme.set_color("font_color", "LineEdit", TOOLTIP_TEXT)
	theme.set_color("font_placeholder_color", "LineEdit", Color(0.76, 0.76, 0.72, 0.92))
	theme.set_color("font_outline_color", "LineEdit", TOOLTIP_OUTLINE)
	theme.set_constant("outline_size", "LineEdit", 2)
	theme.set_color("caret_color", "LineEdit", Color(0.52, 0.72, 1.0, 1.0))
	theme.set_font_size("font_size", "LineEdit", 17)

	theme.set_stylebox("background", "ProgressBar", make_hud_bar_style())
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.34, 0.72, 0.22, 1.0)
	fill.border_color = Color(0.72, 0.88, 0.40, 1.0)
	fill.set_border_width_all(2)
	fill.set_corner_radius_all(3)
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

static func make_compact_panel_style(tint: Color = Color.WHITE) -> StyleBoxTexture:
	return _make_texture_style(PANEL_TEXTURE, Vector4(42, 42, 42, 42), Vector4(16, 14, 16, 14), tint)

static func make_tooltip_style(accent: Color = ACCENT_BLUE) -> StyleBoxTexture:
	var tint := Color.WHITE.lerp(accent, 0.08)
	return _make_texture_style(TOOLTIP_TEXTURE, Vector4(36, 28, 36, 28), Vector4(68, 72, 68, 54), tint)

static func make_tooltip_host_style() -> StyleBoxEmpty:
	var style := StyleBoxEmpty.new()
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	return style

static func make_title_style() -> StyleBoxTexture:
	return _make_texture_style(TITLE_TEXTURE, Vector4(64, 20, 64, 20), Vector4(44, 10, 44, 10))

static func make_rest_bar_style() -> StyleBoxTexture:
	return _make_texture_style(TITLE_TEXTURE, Vector4(80, 24, 80, 24), Vector4(8, 6, 8, 6))

static func make_hud_dock_style(tint: Color = Color.WHITE) -> StyleBoxTexture:
	return _make_texture_style(TITLE_TEXTURE, Vector4(64, 20, 64, 20), Vector4(12, 6, 12, 6), tint)

static func make_character_card_style(tint: Color = Color.WHITE) -> StyleBoxTexture:
	return _make_texture_style(CHARACTER_CARD_TEXTURE, Vector4(30, 32, 30, 32), Vector4(10, 14, 10, 12), tint)

static func make_button_style(texture: Texture2D, tint: Color = Color.WHITE) -> StyleBoxTexture:
	return _make_texture_style(texture, Vector4(24, 18, 24, 18), Vector4(18, 10, 18, 10), tint)

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
