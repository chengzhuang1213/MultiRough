extends RefCounted
class_name UpgradeSession

const UpgradeManagerScript := preload("res://scripts/upgrades/upgrade_manager.gd")

static func roll_sets(players: Array, force_epic: bool) -> Dictionary:
	var excluded_rarities: Array = []
	var rarity := "Common"
	var sets: Array = []
	while excluded_rarities.size() < 3:
		rarity = UpgradeManagerScript.roll_rarity(force_epic and excluded_rarities.is_empty(), excluded_rarities)
		sets = UpgradeManagerScript.roll_for_players(players, 3, rarity)
		var complete := true
		for upgrades in sets:
			if (upgrades as Array).size() < 3:
				complete = false
				break
		if complete:
			break
		excluded_rarities.append(rarity)
	return {"rarity": rarity, "sets": sets}

static func reset_slots(slots: Array) -> void:
	for slot in slots:
		slot["upgrades"] = []
		slot["selected"] = false
		slot["selection_pending"] = false

static func assign_sets(slots: Array, sets: Array) -> void:
	for index in range(mini(slots.size(), sets.size())):
		slots[index]["upgrades"] = (sets[index] as Array).duplicate(true)

static func all_selected(slots: Array) -> bool:
	if slots.is_empty():
		return false
	for slot in slots:
		var target_player: PlayerController = slot.get("player") as PlayerController
		if target_player != null and is_instance_valid(target_player) and not bool(slot.get("selected", false)):
			return false
	return true

static func apply_choice(slot: Dictionary, upgrade_index: int) -> bool:
	if slot.is_empty() or bool(slot.get("selected", false)):
		return false
	var upgrades: Array = slot.get("upgrades", [])
	if not UpgradeManagerScript.is_valid_choice(upgrades, upgrade_index):
		return false
	var target_player: PlayerController = slot.get("player") as PlayerController
	if target_player == null or not is_instance_valid(target_player):
		return false
	target_player.record_upgrade_offer_result(upgrades, str((upgrades[upgrade_index] as Dictionary).get("id", "")))
	target_player.apply_upgrade(upgrades[upgrade_index] as Dictionary)
	slot["selected"] = true
	slot["selection_pending"] = false
	return true
