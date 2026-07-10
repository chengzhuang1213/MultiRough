extends RefCounted
class_name UpgradeManager

const UpgradeCatalogScript := preload("res://scripts/upgrades/upgrade_catalog.gd")

static func roll_for_characters(character_ids: Array, count: int = 3) -> Array:
	var result: Array = []
	for character_id in character_ids:
		result.append(UpgradeCatalogScript.roll(count, str(character_id)))
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
