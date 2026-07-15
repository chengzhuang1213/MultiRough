extends SceneTree

const MainScene := preload("res://scenes/main/main.tscn")
const VerdantUIThemeScript := preload("res://scripts/ui/verdant_ui_theme.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var theme := VerdantUIThemeScript.build_theme()
	_expect_vertical_fit(theme.get_stylebox("normal", "Button"), 60.0, "button")
	_expect_vertical_fit(theme.get_stylebox("normal", "LineEdit"), 64.0, "input")
	_expect_framed_text_fit(theme.get_stylebox("normal", "Button"), 60.0, 19.0, "button")
	_expect_framed_text_fit(theme.get_stylebox("normal", "LineEdit"), 64.0, 17.0, "input")
	_expect_vertical_fit(theme.get_stylebox("background", "ProgressBar"), 30.0, "HUD bar")
	_expect_vertical_fit(theme.get_stylebox("separator", "HSeparator"), 18.0, "separator")
	_expect_vertical_fit(VerdantUIThemeScript.make_title_style(), 58.0, "title plate")
	_expect_vertical_fit(VerdantUIThemeScript.make_skill_slot_style(), 58.0, "skill slot")
	_expect_horizontal_fit(theme.get_stylebox("normal", "Button"), 82.0, "small button")
	_expect_horizontal_fit(theme.get_stylebox("normal", "LineEdit"), 184.0, "network input")
	_expect_horizontal_fit(VerdantUIThemeScript.make_skill_slot_style(), 58.0, "skill slot")

	var game = MainScene.instantiate()
	root.add_child(game)
	await process_frame
	for character_id in game.CHARACTER_ORDER:
		var active_card_path := str(game.CHARACTER_CARD_ART.get(character_id, ""))
		var legacy_card_path := str(game.CHARACTER_CARD_ART_LEGACY.get(character_id, ""))
		_expect(not active_card_path.is_empty() and ResourceLoader.exists(active_card_path), "redrawn character card is missing for %s" % character_id)
		_expect(not legacy_card_path.is_empty() and ResourceLoader.exists(legacy_card_path), "legacy character card was not preserved for %s" % character_id)
		_expect(active_card_path != legacy_card_path, "redrawn character card overwrote the legacy asset for %s" % character_id)
	_expect_control_inside(game.main_menu_panel, game.main_menu_ui.content, "main menu content")
	_expect(game.main_menu_panel.size.x <= game._get_viewport_size().x and game.main_menu_panel.size.y <= game._get_viewport_size().y, "main menu panel exceeds the viewport")
	_expect(game.network_ip_edit.custom_minimum_size.y >= 64.0, "network input is shorter than the themed input minimum")
	_expect(game.start_next_wave_button.custom_minimum_size.y >= 60.0, "next-wave button is shorter than the themed button minimum")
	_expect(game.restart_button.custom_minimum_size.y >= 60.0, "restart button is shorter than the themed button minimum")
	_expect(game.return_to_menu_button.custom_minimum_size.y >= 60.0, "return button is shorter than the themed button minimum")
	_expect(not game.restart_button.visible, "restart button is visible on the main menu")
	game._start_single_player()
	await process_frame
	_expect_control_inside(game.character_select_panel, game.character_select_ui.content, "character-select content")
	_expect(game.character_select_panel.size.x <= game._get_viewport_size().x and game.character_select_panel.size.y <= game._get_viewport_size().y, "character-select panel exceeds the viewport")
	_expect(game.character_select_start_button.custom_minimum_size.y >= 60.0, "character start button is shorter than the themed button minimum")
	for card_data in game.character_select_rows:
		var card_button := card_data.get("button") as Button
		_expect(card_button != null and card_button.custom_minimum_size.y >= 420.0, "character card is shorter than the single-player layout minimum")
		_expect_control_inside(card_button, card_data.get("content") as Control, "character card content")
		var art_frame := card_data.get("art_frame") as Control
		var card_art := card_data.get("art") as TextureRect
		_expect(card_art != null and card_art.stretch_mode == TextureRect.STRETCH_SCALE, "character portrait is not using the measured cover layout")
		_expect(card_art != null and card_art.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS, "character portrait is not using high-quality downsampling")
		_expect(art_frame != null and is_equal_approx(card_art.position.y, 0.0), "character portrait is not aligned to the top")
		_expect(art_frame != null and card_art.size.x + 0.01 >= art_frame.size.x and card_art.size.y + 0.01 >= art_frame.size.y, "character portrait does not fill its frame")
		var selected_badge := card_data.get("selected_badge") as Control
		var selected_label := card_data.get("selected_label") as Label
		_expect(selected_badge != null and selected_badge.custom_minimum_size.x >= 90.0 and selected_badge.custom_minimum_size.y >= 36.0, "selected badge is too small")
		_expect(selected_label != null and selected_label.get_theme_font_size("font_size") >= 16, "selected badge text is too small")
		for skill_panel_value in card_data.get("skill_panels", []):
			var skill_panel := skill_panel_value as PanelContainer
			var skill_icon := skill_panel.find_child("SkillIcon", true, false) as TextureRect
			_expect(skill_icon != null and skill_icon.texture != null, "character skill slot is missing its icon texture")
	var network_context: Dictionary = game._get_character_select_ui_context().duplicate(true)
	network_context["player_count"] = 2
	network_context["is_network"] = true
	network_context["network_status"] = "房间已创建，等待另一名玩家"
	game.character_select_ui.rebuild(network_context)
	await process_frame
	_expect_control_inside(game.character_select_panel, game.character_select_ui.content, "network character-select content")
	_expect(game.character_select_panel.size.y <= game._get_viewport_size().y, "network character-select panel exceeds the viewport")
	game.character_select_ui.rebuild(game._get_character_select_ui_context())
	await process_frame
	game._confirm_character_select()
	await process_frame
	_expect(not game.restart_button.visible, "restart button is visible during combat")
	_expect(game.player_hud.size.x <= 450.0, "combat HUD is wider than the compact layout")
	_expect(game.player_hud.size.y <= 140.0, "combat HUD is taller than the compact layout")
	var combat_hud_data: Dictionary = game.player_huds[0]
	var combat_health_layer := combat_hud_data.get("health_layer") as Control
	_expect(combat_health_layer != null and combat_health_layer.size.y <= 26.0, "combat health bar is taller than the compact layout")
	for action_panel_value in combat_hud_data.get("action_panels", []):
		var action_panel := action_panel_value as PanelContainer
		_expect(action_panel.size.y <= 56.0, "combat action slot is taller than the compact layout")
	game._clear_remaining_enemies()
	game.result_ui.show_result("测试", game._get_viewport_size())
	game._enter_upgrade_select()
	await process_frame
	_expect(not game.restart_button.visible, "restart button is visible during upgrade selection")
	_expect(not game.hud_left.visible, "combat status HUD is visible during upgrade selection")
	_expect(not game.player_hud.visible, "player HUD is visible during upgrade selection")
	_expect(not game.return_to_menu_button.visible, "return button is visible during upgrade selection")
	_expect(game.upgrade_ui.overlay.visible, "upgrade pause overlay is hidden")
	game.queue_free()

	if failures.is_empty():
		print("PASS: UI theme checks")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)

func _expect_vertical_fit(style: StyleBox, control_height: float, label: String) -> void:
	var texture_style := style as StyleBoxTexture
	if texture_style == null:
		failures.append("%s is not a StyleBoxTexture" % label)
		return
	var fixed_height := texture_style.texture_margin_top + texture_style.texture_margin_bottom
	_expect(fixed_height <= control_height, "%s fixed vertical margins %.1f exceed control height %.1f" % [label, fixed_height, control_height])

func _expect_horizontal_fit(style: StyleBox, control_width: float, label: String) -> void:
	var texture_style := style as StyleBoxTexture
	if texture_style == null:
		failures.append("%s is not a StyleBoxTexture" % label)
		return
	var fixed_width := texture_style.texture_margin_left + texture_style.texture_margin_right
	_expect(fixed_width <= control_width, "%s fixed horizontal margins %.1f exceed control width %.1f" % [label, fixed_width, control_width])

func _expect_framed_text_fit(style: StyleBox, control_height: float, font_size: float, label: String) -> void:
	var texture_style := style as StyleBoxTexture
	if texture_style == null:
		failures.append("%s is not a StyleBoxTexture" % label)
		return
	var safe_height := texture_style.texture_margin_top + texture_style.texture_margin_bottom + font_size + 4.0
	_expect(safe_height <= control_height, "%s frame and text need %.1f px but control height is %.1f px" % [label, safe_height, control_height])

func _expect_control_inside(outer: Control, inner: Control, label: String) -> void:
	var outer_rect := outer.get_global_rect()
	var inner_rect := inner.get_global_rect()
	_expect(outer_rect.encloses(inner_rect), "%s extends beyond its panel" % label)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
