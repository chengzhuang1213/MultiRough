extends SceneTree

const MainScene := preload("res://scenes/main/main.tscn")
const CampaignSatchelUIThemeScript := preload("res://scripts/ui/campaign_satchel_ui_theme.gd")
const ReadableTooltipButtonScript := preload("res://scripts/ui/readable_tooltip_button.gd")
const CharacterTooltipPanelScript := preload("res://scripts/ui/character_tooltip_panel.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var theme := CampaignSatchelUIThemeScript.build_theme()
	_expect_vertical_fit(theme.get_stylebox("normal", "Button"), 100.0, "button")
	_expect_vertical_fit(theme.get_stylebox("normal", "LineEdit"), 100.0, "input")
	_expect_framed_text_fit(theme.get_stylebox("normal", "Button"), 100.0, 24.0, "button")
	_expect_framed_text_fit(theme.get_stylebox("normal", "LineEdit"), 100.0, 20.0, "input")
	_expect_same_style_layout(theme.get_stylebox("normal", "Button"), theme.get_stylebox("hover", "Button"), "button hover")
	_expect_same_style_layout(theme.get_stylebox("normal", "Button"), theme.get_stylebox("pressed", "Button"), "button pressed")
	_expect_vertical_fit(theme.get_stylebox("background", "ProgressBar"), 30.0, "HUD bar")
	_expect_vertical_fit(theme.get_stylebox("separator", "HSeparator"), 18.0, "separator")
	_expect_vertical_fit(CampaignSatchelUIThemeScript.make_title_style(), 58.0, "title plate")
	_expect_vertical_fit(CampaignSatchelUIThemeScript.make_skill_slot_style(), 58.0, "skill slot")
	_expect_horizontal_fit(theme.get_stylebox("normal", "Button"), 82.0, "small button")
	_expect_horizontal_fit(theme.get_stylebox("normal", "LineEdit"), 184.0, "network input")
	var input_style := theme.get_stylebox("normal", "LineEdit")
	_expect(input_style.content_margin_left >= 60.0 and input_style.content_margin_right >= 60.0, "network input text overlaps the decorative frame")
	_expect(theme.get_color("font_color", "LineEdit").a >= 0.99, "network input text is not fully visible")
	_expect(theme.get_constant("outline_size", "LineEdit") >= 2, "network input text has insufficient contrast")
	_expect_horizontal_fit(CampaignSatchelUIThemeScript.make_skill_slot_style(), 58.0, "skill slot")
	var tooltip_style := CampaignSatchelUIThemeScript.make_tooltip_style()
	_expect(tooltip_style is StyleBoxTexture, "tooltip is not using the campaign satchel texture")
	_expect(tooltip_style.content_margin_left >= 64.0 and tooltip_style.content_margin_right >= 64.0, "tooltip horizontal padding does not clear the blue reading area")
	_expect(tooltip_style.content_margin_top >= 68.0 and tooltip_style.content_margin_bottom >= 50.0, "tooltip vertical padding does not clear the parchment bands")
	var tooltip_host_style := theme.get_stylebox("panel", "TooltipPanel")
	_expect(tooltip_host_style is StyleBoxEmpty, "Godot tooltip host draws a second decorative frame")
	_expect(is_zero_approx(tooltip_host_style.content_margin_left) and is_zero_approx(tooltip_host_style.content_margin_top) and is_zero_approx(tooltip_host_style.content_margin_right) and is_zero_approx(tooltip_host_style.content_margin_bottom), "transparent tooltip host adds unexpected padding")
	_expect(CampaignSatchelUIThemeScript.make_rest_bar_style().texture == CampaignSatchelUIThemeScript.TITLE_TEXTURE, "rest HUD does not use its horizontal frame")
	_expect(CampaignSatchelUIThemeScript.make_hud_dock_style().texture == CampaignSatchelUIThemeScript.TITLE_TEXTURE, "combat HUD does not use its horizontal dock frame")
	_expect(CampaignSatchelUIThemeScript.make_character_card_style().texture == CampaignSatchelUIThemeScript.CHARACTER_CARD_TEXTURE, "character cards do not use their dedicated card texture")
	var tooltip_button := ReadableTooltipButtonScript.new()
	tooltip_button.tooltip_accent = Color(0.32, 0.88, 1.0)
	var tooltip_content := tooltip_button._make_custom_tooltip("较长的升级说明需要在固定宽度内自动换行，不能横跨相邻卡片。") as PanelContainer
	var tooltip_label := tooltip_content.get_node_or_null("ReadableTooltipLabel") as Label
	var rarity_style := tooltip_content.get_theme_stylebox("panel") as StyleBoxTexture
	_expect(tooltip_label != null and tooltip_label.custom_minimum_size.x <= 340.0, "upgrade tooltip content is wider than the readable limit")
	_expect(tooltip_label != null and tooltip_label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "upgrade tooltip does not wrap long text")
	_expect(rarity_style != null and rarity_style.modulate_color != Color.WHITE, "upgrade tooltip texture is not tinted by card rarity")
	tooltip_content.free()
	tooltip_button.free()

	var game = MainScene.instantiate()
	root.add_child(game)
	await process_frame
	_expect(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://assets/ui/theme/verdant_pixel")), "legacy verdant UI assets were not deleted")
	_expect(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://assets/ui/upgrades")), "legacy upgrade card assets were not deleted")
	for rarity in game.UPGRADE_CARD_ART:
		var upgrade_card_path := str(game.UPGRADE_CARD_ART[rarity])
		_expect(upgrade_card_path.begins_with("res://assets/ui/theme/campaign_satchel/"), "upgrade card still uses the legacy UI directory: %s" % rarity)
		_expect(ResourceLoader.exists(upgrade_card_path), "campaign satchel upgrade card is missing: %s" % rarity)
	for character_id in game.CHARACTER_ORDER:
		var active_card_path := str(game.CHARACTER_CARD_ART.get(character_id, ""))
		var legacy_card_path := str(game.CHARACTER_CARD_ART_LEGACY.get(character_id, ""))
		_expect(not active_card_path.is_empty() and ResourceLoader.exists(active_card_path), "redrawn character card is missing for %s" % character_id)
		_expect(not legacy_card_path.is_empty() and ResourceLoader.exists(legacy_card_path), "legacy character card was not preserved for %s" % character_id)
		_expect(active_card_path != legacy_card_path, "redrawn character card overwrote the legacy asset for %s" % character_id)
	_expect_control_inside(game.main_menu_panel, game.main_menu_ui.content, "main menu content")
	_expect(game.main_menu_panel.size.x <= game._get_viewport_size().x and game.main_menu_panel.size.y <= game._get_viewport_size().y, "main menu panel exceeds the viewport")
	_expect(game.network_ip_edit.custom_minimum_size.y >= 100.0, "network input is shorter than the adjusted input minimum")
	_expect(game.start_next_wave_button.custom_minimum_size.y >= 100.0, "next-wave button is shorter than the adjusted button minimum")
	_expect(game.restart_button.custom_minimum_size.y >= 100.0, "restart button is shorter than the adjusted button minimum")
	_expect(game.return_to_menu_button.custom_minimum_size.x <= 170.0 and game.return_to_menu_button.custom_minimum_size.y <= 72.0, "return button is not using the compact secondary size")
	_expect(not game.restart_button.visible, "restart button is visible on the main menu")
	game._start_single_player()
	await process_frame
	_expect_control_inside(game.character_select_panel, game.character_select_ui.content, "character-select content")
	_expect(game.character_select_panel.size.x <= game._get_viewport_size().x and game.character_select_panel.size.y <= game._get_viewport_size().y, "character-select panel exceeds the viewport")
	_expect(game.character_select_start_button.custom_minimum_size.y >= 100.0, "character start button is shorter than the adjusted button minimum")
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
		var card_style := card_button.get_theme_stylebox("normal") as StyleBoxTexture
		_expect(card_style != null and card_style.texture == CampaignSatchelUIThemeScript.CHARACTER_CARD_TEXTURE, "character card still uses the generic large panel")
		_expect(art_frame != null and art_frame.custom_minimum_size.x <= 212.0, "character portrait crowds the card frame")
		for skill_panel_value in card_data.get("skill_panels", []):
			var skill_panel := skill_panel_value as PanelContainer
			var skill_icon := skill_panel.find_child("SkillIcon", true, false) as TextureRect
			_expect(skill_icon != null and skill_icon.texture != null, "character skill slot is missing its icon texture")
			_expect(skill_panel.get_script() == CharacterTooltipPanelScript, "character skill slot is missing its colored tooltip")
			_expect(not skill_panel.tooltip_text.is_empty(), "character skill slot tooltip is empty")
			_expect((skill_panel.get("tooltip_accent") as Color).is_equal_approx(game.CHARACTER_CARD_ACCENTS.get(card_data.get("character_id"), Color.WHITE)), "character skill tooltip does not match its character color")
			for child in skill_panel.find_children("*", "Control", true, false):
				_expect((child as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE, "character skill icon blocks tooltip hover: %s" % child.name)
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
	_expect(not game.wave_label.text.contains("剩余") and not game.wave_label.text.contains("秒"), "wave countdown still appears in the top-left status text")
	var wave_timer_label := game.combat_hud_ui.wave_timer_label as Label
	_expect(wave_timer_label.visible and wave_timer_label.text.is_valid_int(), "centered wave countdown is not a number-only label")
	_expect(absf(wave_timer_label.get_global_rect().get_center().x - game._get_viewport_size().x * 0.5) <= 1.0 and wave_timer_label.position.y <= 32.0, "wave countdown is not centered at the top")
	var state_before_return_confirmation = game.game_state
	game.return_to_menu_button.pressed.emit()
	_expect(game.combat_hud_ui.return_confirmation_overlay.visible, "return-to-menu button skipped its confirmation overlay")
	_expect(game.get_tree().paused, "opening return confirmation did not pause the game")
	_expect(game.game_state == state_before_return_confirmation, "opening return confirmation immediately ended the run")
	game.combat_hud_ui.return_cancel_button.pressed.emit()
	_expect(not game.combat_hud_ui.return_confirmation_overlay.visible and not game.get_tree().paused, "canceling return confirmation did not resume the game")
	game.network_mode = "host"
	game.local_peer_player_index = 1
	game._handle_host_return_confirmation_action("open", 2)
	_expect(game.network_return_confirmation_requester == 2 and game.get_tree().paused, "host did not honor the client's synchronized pause request")
	_expect(game.combat_hud_ui.return_confirmation_overlay.visible and not game.combat_hud_ui.return_confirmation_actions.visible, "non-requesting peer did not receive the waiting confirmation state")
	game._handle_host_return_confirmation_action("cancel", 2)
	_expect(game.network_return_confirmation_requester == 0 and not game.get_tree().paused, "host did not synchronize the client's cancel request")
	game.network_mode = "client"
	game.local_peer_player_index = 2
	game._network_set_return_confirmation(true, 2)
	_expect(game.get_tree().paused and game.combat_hud_ui.return_confirmation_actions.visible, "client did not apply the host-authorized interactive confirmation")
	game._network_set_return_confirmation(false, 2)
	_expect(not game.get_tree().paused and not game.combat_hud_ui.return_confirmation_overlay.visible, "client did not resume after the host cleared synchronized pause")
	game.network_mode = "none"
	game.local_peer_player_index = 1
	_expect(game.player_hud.size.x <= 450.0, "combat HUD is wider than the compact layout")
	_expect(game.player_hud.size.y <= 140.0, "combat HUD is taller than the compact layout")
	var combat_hud_data: Dictionary = game.player_huds[0]
	var combat_dock_style := game.player_hud.get_theme_stylebox("panel") as StyleBoxTexture
	_expect(combat_dock_style != null and combat_dock_style.texture == CampaignSatchelUIThemeScript.TITLE_TEXTURE, "combat HUD still uses the square panel frame")
	var combat_health_layer := combat_hud_data.get("health_layer") as Control
	_expect(combat_health_layer != null and combat_health_layer.size.y <= 26.0, "combat health bar is taller than the compact layout")
	_expect(combat_health_layer != null and combat_health_layer.size.x <= 350.0, "combat health bar was not shortened inside the HUD")
	var combat_health_bar := combat_hud_data.get("health_bar") as ProgressBar
	_expect(combat_health_bar.size.y >= 23.0, "combat health bar was compressed into a thin line")
	var health_background := combat_health_bar.get_theme_stylebox("background") as StyleBoxFlat
	var health_fill := combat_health_bar.get_theme_stylebox("fill") as StyleBoxFlat
	_expect(health_background != null and health_background.bg_color.r > health_background.bg_color.g * 3.0, "lost health is not red")
	_expect(health_fill != null and health_fill.bg_color.g > health_fill.bg_color.r, "remaining health is not green")
	var health_frame := combat_health_layer.get_node_or_null("HealthFrame") as Panel
	_expect(health_frame != null, "combat health bar lost its decorative frame")
	_expect(health_frame != null and health_frame.get_index() < combat_health_bar.get_index(), "combat health frame overlays and splits the colored bar")
	var combat_health_label := combat_hud_data.get("health_label") as Label
	_expect(combat_health_label.get_theme_color("font_color").get_luminance() >= 0.85, "combat health text is not bright enough")
	_expect(combat_health_label.get_theme_constant("outline_size") >= 3, "combat health text outline is too thin")
	for action_panel_value in combat_hud_data.get("action_panels", []):
		var action_panel := action_panel_value as PanelContainer
		_expect(action_panel.size.y <= 56.0, "combat action slot is taller than the compact layout")
		_expect(action_panel.get_script() == CharacterTooltipPanelScript, "combat action slot is missing its colored tooltip")
		_expect(not action_panel.tooltip_text.is_empty(), "combat action tooltip is empty")
		_expect((action_panel.get("tooltip_accent") as Color).is_equal_approx(game.CHARACTER_CARD_ACCENTS["warrior"]), "combat action tooltip does not match the active character color")
		for child in action_panel.find_children("*", "Control", true, false):
			_expect((child as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE, "combat action icon blocks tooltip hover: %s" % child.name)
	for status_label_value in combat_hud_data.get("action_status_labels", []):
		var status_label := status_label_value as Label
		_expect(not status_label.text.contains("就绪"), "combat action status repeats ready text over the icon")
	game._clear_remaining_enemies()
	game.result_ui.show_result("测试", game._get_viewport_size())
	game._enter_upgrade_select()
	await process_frame
	_expect(not game.restart_button.visible, "restart button is visible during upgrade selection")
	_expect(not game.hud_left.visible, "combat status HUD is visible during upgrade selection")
	_expect(not game.combat_hud_ui.wave_timer_label.visible, "wave countdown is visible outside combat")
	_expect(not game.player_hud.visible, "player HUD is visible during upgrade selection")
	_expect(not game.return_to_menu_button.visible, "return button is visible during upgrade selection")
	_expect(game.upgrade_ui.overlay.visible, "upgrade pause overlay is hidden")
	_expect(not game.upgrade_ui.card_buttons.is_empty(), "upgrade selection has no cards")
	if not game.upgrade_ui.card_buttons.is_empty():
		var upgrade_card := game.upgrade_ui.card_buttons[0] as Button
		_expect(not upgrade_card.tooltip_text.is_empty(), "upgrade card is missing tooltip text")
		for child in upgrade_card.find_children("*", "Control", true, false):
			_expect((child as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE, "upgrade card child blocks tooltip hover: %s" % child.name)
	game.rest_ui.show_rest("第 1 波完成 · 战备休息", "测试升级\n测试说明", "[Q] 测试构筑", "第 2 波\n近战兵 ×5", game._get_viewport_size())
	await process_frame
	_expect(game.rest_ui.visible, "rest page did not become visible")
	_expect(game.rest_ui.panel.size.x <= game._get_viewport_size().x and game.rest_ui.panel.size.y <= game._get_viewport_size().y, "rest page size %s exceeds viewport %s" % [game.rest_ui.panel.size, game._get_viewport_size()])
	_expect(game.rest_ui.panel.position.y <= 20.0 and game.rest_ui.panel.size.y <= 180.0, "rest information UI is not a compact top bar: position=%s size=%s min=%s" % [game.rest_ui.panel.position, game.rest_ui.panel.size, game.rest_ui.panel.get_combined_minimum_size()])
	_expect(game.rest_ui.skill_buttons.size() == 3, "rest HUD does not contain distinct Q/E/F buttons")
	var rest_style := game.rest_ui.panel.get_theme_stylebox("panel") as StyleBoxTexture
	_expect(rest_style != null and rest_style.texture == CampaignSatchelUIThemeScript.TITLE_TEXTURE, "rest HUD still uses the square panel frame")
	for skill_button in game.rest_ui.skill_buttons:
		var icon := (skill_button as Button).get_node("Icon") as TextureRect
		_expect((skill_button as Button).clip_contents and icon.position.x >= 0.0 and icon.position.y >= 0.0 and icon.position.x + icon.size.x <= (skill_button as Button).size.x and icon.position.y + icon.size.y <= (skill_button as Button).size.y, "rest HUD skill icon protrudes outside its button")
	for info_button in [game.rest_ui.build_button, game.rest_ui.latest_button, game.rest_ui.intel_button]:
		var icon_frame := (info_button as Button).get_node_or_null("InfoIconFrame") as PanelContainer
		var button_bounds := Rect2(Vector2.ZERO, (info_button as Button).size)
		_expect(icon_frame != null and button_bounds.encloses(icon_frame.get_rect()), "rest information icon is not contained in its own slot")
	_expect(game.rest_ui.ready_button.custom_minimum_size.y >= 54.0, "rest ready button is too short")
	_expect(game.rest_ui.mouse_filter == Control.MOUSE_FILTER_IGNORE and game.rest_ui.panel.mouse_filter == Control.MOUSE_FILTER_STOP, "rest information panel blocks training-map input outside the panel")
	_expect(not game.rest_ui.latest_label.text.is_empty() and not game.rest_ui.build_label.text.is_empty() and not game.rest_ui.intel_label.text.is_empty(), "rest page omitted one of its three information columns")
	_expect(game.rest_ui.stats_text.get_theme_color("default_color").is_equal_approx(CampaignSatchelUIThemeScript.TEXT_PRIMARY), "stats drawer uses light tooltip text on parchment")
	game.rest_ui._toggle_stats_drawer()
	_expect(game.rest_ui.stats_drawer.visible and game.rest_ui.stats_dismiss_layer.visible, "stats drawer did not enable its outside-click layer")
	var outside_click := InputEventMouseButton.new()
	outside_click.button_index = MOUSE_BUTTON_LEFT
	outside_click.pressed = true
	game.rest_ui._on_stats_dismiss_gui_input(outside_click)
	_expect(not game.rest_ui.stats_drawer.visible and not game.rest_ui.stats_dismiss_layer.visible, "clicking outside does not close the stats drawer")
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

func _expect_same_style_layout(normal: StyleBox, state: StyleBox, label: String) -> void:
	_expect(is_equal_approx(normal.content_margin_left, state.content_margin_left), "%s changes left content margin" % label)
	_expect(is_equal_approx(normal.content_margin_top, state.content_margin_top), "%s changes top content margin" % label)
	_expect(is_equal_approx(normal.content_margin_right, state.content_margin_right), "%s changes right content margin" % label)
	_expect(is_equal_approx(normal.content_margin_bottom, state.content_margin_bottom), "%s changes bottom content margin" % label)

func _expect_control_inside(outer: Control, inner: Control, label: String) -> void:
	var outer_rect := outer.get_global_rect()
	var inner_rect := inner.get_global_rect()
	_expect(outer_rect.encloses(inner_rect), "%s extends beyond its panel" % label)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
