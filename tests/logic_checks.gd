extends SceneTree

const GameRulesScript := preload("res://scripts/gameplay/game_rules.gd")
const WaveManagerScript := preload("res://scripts/gameplay/wave_manager.gd")
const UpgradeCatalogScript := preload("res://scripts/upgrades/upgrade_catalog.gd")
const UpgradeManagerScript := preload("res://scripts/upgrades/upgrade_manager.gd")
const PlayerScript := preload("res://scripts/player/player_controller.gd")
const AuthorityContractScript := preload("res://scripts/network/authority_contract.gd")

var failures: Array[String] = []

func _init() -> void:
	_check_character_configs()
	_check_original_animation_sheets()
	_check_upgrade_application()
	_check_upgrade_rolls_are_unique()
	_check_wave_progression()
	_check_multiplayer_scaling_and_revival()
	_check_wave_clear_healing()
	_check_cooldown_pause_boundary()
	_check_common_animation_states()
	_check_archer_projectile_origin()
	_check_combat_event_frame()
	_check_authority_snapshot_contract()
	if failures.is_empty():
		print("PASS: all logic checks")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)

func _check_character_configs() -> void:
	var errors: PackedStringArray = GameRulesScript.validate_character_configs()
	_expect(errors.is_empty(), "character configs are incomplete: %s" % ", ".join(errors))
	_expect(GameRulesScript.CHARACTER_ORDER.size() == 4, "expected exactly four configured characters")
	_expect(GameRulesScript.CHARACTER_ORDER.has("mage"), "mage is missing from character order")
	_check_mage_art_assets()

func _check_mage_art_assets() -> void:
	var paths := [
		"res://assets/original/characters/archer/archer_concept_v1.png",
		"res://assets/original/characters/archer/archer_pixel_master_v1.png",
		"res://assets/original/characters/archer/animations/archer_idle.png",
		"res://assets/original/characters/archer/animations/archer_run.png",
		"res://assets/original/characters/archer/animations/archer_attack_1.png",
		"res://assets/original/characters/archer/animations/archer_attack_2.png",
		"res://assets/original/characters/archer/animations/archer_cast.png",
		"res://assets/original/characters/archer/animations/archer_hit.png",
		"res://assets/original/characters/archer/animations/archer_death.png",
		"res://assets/original/characters/archer/animations/archer_dash.png",
		"res://assets/original/characters/archer/animations/archer_defend.png",
		"res://assets/original/characters/lancer/lancer_concept_v1.png",
		"res://assets/original/characters/lancer/animations/lancer_idle.png",
		"res://assets/original/characters/lancer/animations/lancer_run.png",
		"res://assets/original/characters/lancer/animations/lancer_attack_1.png",
		"res://assets/original/characters/lancer/animations/lancer_attack_2.png",
		"res://assets/original/characters/lancer/animations/lancer_cast.png",
		"res://assets/original/characters/lancer/animations/lancer_hit.png",
		"res://assets/original/characters/lancer/animations/lancer_death.png",
		"res://assets/original/characters/lancer/animations/lancer_dash.png",
		"res://assets/original/characters/lancer/animations/lancer_defend.png",
		"res://assets/original/characters/warrior/warrior_concept_v1.png",
		"res://assets/original/characters/warrior/animations/warrior_idle.png",
		"res://assets/original/characters/warrior/animations/warrior_run.png",
		"res://assets/original/characters/warrior/animations/warrior_attack_1.png",
		"res://assets/original/characters/warrior/animations/warrior_attack_2.png",
		"res://assets/original/characters/warrior/animations/warrior_cast.png",
		"res://assets/original/characters/warrior/animations/warrior_hit.png",
		"res://assets/original/characters/warrior/animations/warrior_death.png",
		"res://assets/original/characters/warrior/animations/warrior_dash.png",
		"res://assets/original/characters/warrior/animations/warrior_defend.png",
		"res://assets/original/characters/mage/mage_concept_v1.png",
		"res://assets/original/characters/mage/mage_basic_projectile.svg",
		"res://assets/original/characters/mage/animations/mage_idle.png",
		"res://assets/original/characters/mage/animations/mage_run.png",
		"res://assets/original/characters/mage/animations/mage_attack_1.png",
		"res://assets/original/characters/mage/animations/mage_attack_2.png",
		"res://assets/original/characters/mage/animations/mage_cast.png",
		"res://assets/original/characters/mage/animations/mage_hit.png",
		"res://assets/original/characters/mage/animations/mage_death.png",
		"res://assets/original/characters/mage/animations/mage_dash.png",
		"res://assets/original/characters/mage/animations/mage_defend.png",
	]
	for path in paths:
		_expect(ResourceLoader.exists(path), "original character art asset is missing: %s" % path)

func _check_original_animation_sheets() -> void:
	var frame_counts := {
		"idle": 6, "run": 6, "attack_1": 6, "attack_2": 6,
		"cast": 6, "hit": 3, "death": 6, "dash": 4, "defend": 4,
	}
	for character_id in ["warrior", "lancer", "archer", "mage"]:
		for animation_name in frame_counts:
			var path := "res://assets/original/characters/%s/animations/%s_%s.png" % [character_id, character_id, animation_name]
			var texture := load(path) as Texture2D
			_expect(texture != null, "animation sheet could not load: %s" % path)
			if texture == null:
				continue
			var expected_frames: int = int(frame_counts[animation_name])
			_expect(texture.get_width() == expected_frames * 192, "animation sheet width is invalid: %s" % path)
			_expect(texture.get_height() == 192, "animation sheet height is invalid: %s" % path)
			var image := texture.get_image()
			for frame_index in range(expected_frames):
				var has_pixels := false
				var bottom := -1
				for y in range(192):
					for x in range(frame_index * 192, (frame_index + 1) * 192):
						if image.get_pixel(x, y).a > 0.01:
							has_pixels = true
							bottom = y
				_expect(has_pixels, "%s frame %d is empty" % [path, frame_index])
				_expect(bottom <= 138, "%s frame %d exceeds foot baseline" % [path, frame_index])

func _check_upgrade_application() -> void:
	var player = PlayerScript.new()
	player.apply_character_config(GameRulesScript.get_character_config("warrior"))
	var base_damage: float = player.attack_damage
	player.apply_upgrade({"stat": "attack_damage", "multiplier": 1.16})
	_expect(is_equal_approx(player.attack_damage, base_damage * 1.16), "attack damage upgrade was not applied")
	var base_health: float = player.max_health
	player.apply_upgrade({"stat": "max_health", "multiplier": 1.20})
	_expect(is_equal_approx(player.max_health, base_health * 1.20), "maximum health upgrade was not applied")
	_expect(is_equal_approx(player.health, player.max_health), "maximum health upgrade did not preserve full health")
	player.free()

func _check_upgrade_rolls_are_unique() -> void:
	seed(90710)
	for character_id in GameRulesScript.CHARACTER_ORDER:
		for _iteration in range(100):
			var upgrades: Array = UpgradeCatalogScript.roll(3, character_id)
			_expect(upgrades.size() == 3, "%s upgrade roll returned the wrong count" % character_id)
			_expect(UpgradeManagerScript.has_unique_ids(upgrades), "%s upgrade roll contains duplicate ids" % character_id)
			if character_id == "mage":
				for upgrade in upgrades:
					_expect(not (upgrade as Dictionary).has("skill_slot"), "mage received a skill upgrade before its skills were designed")

func _check_wave_progression() -> void:
	var manager = WaveManagerScript.new()
	var boss_seen := false
	for expected_index in range(manager.wave_count()):
		var result: Dictionary = manager.advance()
		_expect(not bool(result["complete"]), "wave progression completed too early")
		_expect(int(result["index"]) == expected_index, "wave progression skipped an index")
		if bool((result["definition"] as Dictionary).get("boss", false)):
			boss_seen = true
			_expect(expected_index == manager.boss_wave_index(), "boss appeared at an unexpected wave")
	_expect(boss_seen, "wave progression never reached a boss")
	_expect(bool(manager.advance()["complete"]), "wave progression did not complete after the boss")

func _check_multiplayer_scaling_and_revival() -> void:
	var single: Dictionary = GameRulesScript.get_mode_scaling(1)
	var duo: Dictionary = GameRulesScript.get_mode_scaling(2)
	_expect(is_equal_approx(float(single["enemy_health"]), 1.0), "single-player enemy health scaling changed")
	_expect(is_equal_approx(float(duo["minion_count"]), 2.0), "duo minion count scaling is incorrect")
	_expect(is_equal_approx(float(duo["boss_health"]), 2.0), "duo boss health scaling is incorrect")
	var player = PlayerScript.new()
	player.apply_character_config(GameRulesScript.get_character_config("lancer"))
	player.apply_damage(player.max_health * 2.0)
	_expect(player.is_dead, "lethal damage did not kill the player")
	player.revive(GameRulesScript.REVIVE_HEALTH_RATIO)
	_expect(not player.is_dead, "revive did not restore the player")
	_expect(is_equal_approx(player.health, player.max_health * GameRulesScript.REVIVE_HEALTH_RATIO), "revive health ratio is incorrect")
	player.free()

func _check_wave_clear_healing() -> void:
	var player = PlayerScript.new()
	player.apply_character_config(GameRulesScript.get_character_config("warrior"))
	player.apply_damage(35.0)
	var expected_health: float = minf(player.max_health, player.health + GameRulesScript.WAVE_CLEAR_HEAL_AMOUNT)
	player.heal(GameRulesScript.WAVE_CLEAR_HEAL_AMOUNT)
	_expect(is_equal_approx(player.health, expected_health), "wave-clear healing amount is incorrect")
	player.heal(player.max_health * 2.0)
	_expect(is_equal_approx(player.health, player.max_health), "healing exceeded maximum health")
	player.free()

func _check_cooldown_pause_boundary() -> void:
	var player = PlayerScript.new()
	player._attack_timer = 1.0
	player._skill_timer = 2.0
	player.cooldowns_paused = true
	player._tick_timers(0.5)
	_expect(is_equal_approx(player._attack_timer, 1.0), "paused attack cooldown continued ticking")
	_expect(is_equal_approx(player._skill_timer, 2.0), "paused skill cooldown continued ticking")
	player.cooldowns_paused = false
	player._tick_timers(0.5)
	_expect(is_equal_approx(player._attack_timer, 0.5), "active attack cooldown did not tick")
	_expect(is_equal_approx(player._skill_timer, 1.5), "active skill cooldown did not tick")
	player.free()

func _check_common_animation_states() -> void:
	for character_id in GameRulesScript.CHARACTER_ORDER:
		var player = PlayerScript.new()
		player.apply_character_config(GameRulesScript.get_character_config(character_id))
		player._setup_nodes()
		player.apply_damage(1.0)
		_expect(player._current_anim == "hit", "%s did not enter the shared hit animation" % character_id)
		player.apply_damage(player.max_health * 2.0)
		_expect(player._current_anim == "death", "%s did not enter the shared death animation" % character_id)
		_expect(player.visible, "%s death animation was hidden before it could play" % character_id)
		player.revive()
		_expect(player._current_anim == "idle", "%s did not return to idle after revival" % character_id)
		player._start_cast_animation()
		_expect(player._current_anim == "cast", "%s did not enter the shared cast animation" % character_id)
		player.free()

func _check_archer_projectile_origin() -> void:
	var player = PlayerScript.new()
	player.apply_character_config(GameRulesScript.get_character_config("archer"))
	player.global_position = Vector2(100.0, 100.0)
	var origin := player.get_projectile_origin(Vector2.RIGHT)
	_expect(origin.x > player.global_position.x, "archer projectile did not start in front of the bow")
	_expect(origin.y < player.global_position.y, "archer projectile origin did not include the bow-center vertical offset")
	player.free()

func _check_combat_event_frame() -> void:
	var player = PlayerScript.new()
	player.apply_character_config(GameRulesScript.get_character_config("warrior"))
	player._setup_nodes()
	var emitted := [false]
	player.basic_attack_requested.connect(func(_origin, _direction, _length, _width, _damage): emitted[0] = true)
	player._queue_combat_event("basic", Vector2.RIGHT, 10.0)
	player._start_attack_animation(false)
	_expect(not emitted[0], "melee damage emitted on the first visual frame")
	player._advance_animation(0.06)
	_expect(not emitted[0], "melee damage emitted before the configured event frame")
	player._advance_animation(0.06)
	_expect(emitted[0], "melee damage did not emit on the configured event frame")
	player.free()

func _check_authority_snapshot_contract() -> void:
	var player_state: Dictionary = AuthorityContractScript.make_player_state(1, Vector2.ZERO, 100.0, 120.0, false)
	var snapshot: Dictionary = AuthorityContractScript.make_snapshot(1, "WAVE_ACTIVE", 0, [player_state], [])
	_expect(AuthorityContractScript.validate_snapshot(snapshot), "authority snapshot contract is invalid")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
