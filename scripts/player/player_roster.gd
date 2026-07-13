extends RefCounted
class_name PlayerRoster

const PlayerScript := preload("res://scripts/player/player_controller.gd")

var game: Node
var combat

func _init(game_node: Node, combat_manager) -> void:
	game = game_node
	combat = combat_manager

func create_player(player_name: String, spawn_position: Vector2, tint: Color, mouse_aim: bool, character_config: Dictionary) -> PlayerController:
	var player: PlayerController = PlayerScript.new()
	player.name = player_name
	player.global_position = spawn_position
	player.arena_bounds = game.ARENA_BOUNDS
	player.player_tint = tint
	player.use_mouse_aim = mouse_aim
	player.apply_character_config(character_config)
	player.basic_attack_requested.connect(combat.on_player_basic_attack.bind(player))
	player.projectile_attack_requested.connect(combat.on_player_projectile_attack.bind(player))
	player.active_skill_requested.connect(combat.on_player_active_skill.bind(player))
	player.fan_skill_requested.connect(combat.on_player_fan_skill.bind(player))
	player.ultimate_skill_requested.connect(combat.on_player_ultimate_skill.bind(player))
	player.cooldown_notice_requested.connect(game._on_player_cooldown_notice_requested.bind(player))
	player.health_changed.connect(on_player_health_changed.bind(player))
	player.damage_taken.connect(combat.on_player_damage_taken.bind(player))
	player.reflected_damage_requested.connect(combat.on_player_reflected_damage.bind(player))
	player.perfect_guard_triggered.connect(combat.on_player_perfect_guard.bind(player))
	player.died.connect(game._on_player_died)
	game.add_child(player)
	return player

func add_slot(player_index: int, player: PlayerController, hud_index: int) -> void:
	game.local_player_slots.append({
		"player_index": player_index, "player": player, "hud_index": hud_index,
		"upgrades": [], "selected": false, "selection_pending": false,
	})

func get_slot(player_index: int) -> Dictionary:
	for slot in game.local_player_slots:
		if int(slot.get("player_index", 0)) == player_index:
			return slot
	return {}

func reset_upgrade_slots() -> void:
	for slot in game.local_player_slots:
		slot["upgrades"] = []
		slot["selected"] = false
		slot["selection_pending"] = false

func create_hud(parent: VBoxContainer, player_label: String, defend_hint: String, skill_labels: Array[String]) -> void:
	var health_label := Label.new()
	_configure_label(health_label)
	parent.add_child(health_label)
	var health_bar := ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(game.LOCAL_PLAYER_HUD_WIDTH, 18)
	health_bar.show_percentage = false
	_style_health_bar(health_bar)
	parent.add_child(health_bar)
	var cooldown_label := Label.new()
	_configure_label(cooldown_label)
	parent.add_child(cooldown_label)
	var defense_label := Label.new()
	_configure_label(defense_label)
	parent.add_child(defense_label)
	game.player_huds.append({
		"player": null, "name": player_label, "defend_hint": defend_hint,
		"skill_labels": skill_labels, "health_label": health_label,
		"health_bar": health_bar, "cooldown_label": cooldown_label,
		"defense_label": defense_label,
	})

func assign_hud(index: int, player: PlayerController) -> void:
	if index < 0 or index >= game.player_huds.size():
		return
	game.player_huds[index]["player"] = player
	update_hud(index)

func on_player_health_changed(current: float, maximum: float, player: PlayerController) -> void:
	for index in range(game.player_huds.size()):
		var hud: Dictionary = game.player_huds[index]
		if hud.get("player") == player:
			var health_bar: ProgressBar = hud["health_bar"] as ProgressBar
			if health_bar != null:
				health_bar.max_value = maximum
				health_bar.value = current
			update_hud(index)
			return

func update_all_huds() -> void:
	for index in range(game.player_huds.size()):
		update_hud(index)

func update_hud(index: int) -> void:
	if index < 0 or index >= game.player_huds.size():
		return
	var hud: Dictionary = game.player_huds[index]
	var player: PlayerController = hud.get("player") as PlayerController
	var health_label: Label = hud["health_label"] as Label
	var health_bar: ProgressBar = hud["health_bar"] as ProgressBar
	var cooldown_label: Label = hud["cooldown_label"] as Label
	var defense_label: Label = hud["defense_label"] as Label
	var player_name := str(hud.get("name", "P%d" % (index + 1)))
	if player == null or not is_instance_valid(player):
		health_label.text = ""
		health_bar.value = 0.0
		cooldown_label.text = ""
		defense_label.text = ""
		return
	health_label.text = "%s 生命：%d / %d%s" % [player_name, roundi(player.health), roundi(player.max_health), "（倒地）" if player.is_dead else ""]
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	var labels: Array = hud.get("skill_labels", ["普攻", "Q", "E", "F"])
	cooldown_label.text = "%s：%s   闪避：%s (%d/%d)   %s：%s   %s：%s   %s：%s" % [
		str(labels[0]), "就绪" if player.get_attack_ready() else "%.1f秒" % player.get_attack_remaining(),
		"就绪" if player.get_dash_ready() else "%.1f秒" % player.get_dash_remaining(), player.dash_charges, player.dash_max_charges,
		str(labels[1]), "就绪" if player.get_skill_ready() else "%.1f秒" % player.get_skill_remaining(),
		str(labels[2]), "就绪" if player.get_fan_skill_ready() else "%.1f秒" % player.get_fan_skill_remaining(),
		str(labels[3]), "就绪" if player.get_ultimate_ready() else "%.1f秒" % player.get_ultimate_remaining(),
	]
	defense_label.text = "%s 防御：%s" % [player_name, "生效中" if player.is_defending else str(hud.get("defend_hint", ""))]

func _configure_label(label: Label) -> void:
	label.custom_minimum_size = Vector2(game.LOCAL_PLAYER_HUD_WIDTH, 0.0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _style_health_bar(bar: ProgressBar) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.72, 0.08, 0.07, 0.92)
	background.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", background)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.24, 1.0, 0.20, 1.0)
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", fill)
