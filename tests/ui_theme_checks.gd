extends SceneTree

const MainScene := preload("res://scenes/main/main.tscn")
const VerdantUIThemeScript := preload("res://scripts/ui/verdant_ui_theme.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var theme := VerdantUIThemeScript.build_theme()
	_expect_vertical_fit(theme.get_stylebox("normal", "Button"), 52.0, "button")
	_expect_vertical_fit(theme.get_stylebox("normal", "LineEdit"), 52.0, "input")
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
	_expect(game.network_ip_edit.custom_minimum_size.y >= 52.0, "network input is shorter than the themed input minimum")
	_expect(game.start_next_wave_button.custom_minimum_size.y >= 52.0, "next-wave button is shorter than the themed button minimum")
	_expect(game.restart_button.custom_minimum_size.y >= 52.0, "restart button is shorter than the themed button minimum")
	_expect(game.return_to_menu_button.custom_minimum_size.y >= 52.0, "return button is shorter than the themed button minimum")
	game._start_single_player()
	await process_frame
	_expect(game.character_select_start_button.custom_minimum_size.y >= 52.0, "character start button is shorter than the themed button minimum")
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

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
