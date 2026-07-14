extends RefCounted
class_name UpgradeManager

const UpgradeCatalogScript := preload("res://scripts/upgrades/upgrade_catalog.gd")

const COMMON_RARITY_CHANCE := 0.50
const RARE_RARITY_CHANCE := 0.35
const EPIC_RARITY_CHANCE := 0.15

static func roll_rarity(force_epic: bool = false, excluded_rarities: Array = []) -> String:
	if force_epic:
		return "Epic"
	var choices := [
		{"rarity": "Common", "weight": COMMON_RARITY_CHANCE},
		{"rarity": "Rare", "weight": RARE_RARITY_CHANCE},
		{"rarity": "Epic", "weight": EPIC_RARITY_CHANCE},
	]
	var total_weight := 0.0
	for choice in choices:
		if not excluded_rarities.has(str(choice["rarity"])):
			total_weight += float(choice["weight"])
	if total_weight <= 0.0:
		return "Common"
	var roll_value := randf() * total_weight
	for choice in choices:
		var rarity := str(choice["rarity"])
		if excluded_rarities.has(rarity):
			continue
		roll_value -= float(choice["weight"])
		if roll_value <= 0.0:
			return rarity
	return "Common"

static func roll_for_characters(character_ids: Array, count: int = 3) -> Array:
	var result: Array = []
	for character_id in character_ids:
		result.append(UpgradeCatalogScript.roll(count, str(character_id)))
	return result

static func roll_for_players(players: Array, count: int = 3, rarity: String = "") -> Array:
	var result: Array = []
	for player_value in players:
		var player := player_value as PlayerController
		if player == null:
			result.append([])
		else:
			result.append(UpgradeCatalogScript.roll(count, player.character_id, player.upgrade_levels, rarity, player.upgrade_offer_misses))
	return result

static func has_unique_ids(upgrades: Array) -> bool:
	var seen: Dictionary = {}
	for upgrade in upgrades:
		var id := str((upgrade as Dictionary).get("id", ""))
		if id.is_empty() or seen.has(id):
			return false
		seen[id] = true
	return true

static func is_valid_choice(upgrades: Array, upgrade_index: int) -> bool:
	return upgrade_index >= 0 and upgrade_index < upgrades.size()
