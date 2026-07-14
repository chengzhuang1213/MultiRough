extends RefCounted
class_name WaveManager

const DEFAULT_WAVES := [
	{"melee": 4},
	{"melee": 5, "ranged": 2},
	{"melee": 6, "heavy": 2, "ranged": 2},
	{"melee": 6, "shield": 3, "ranged": 2},
	{"melee": 8, "heavy": 2, "charger": 1},
	{"melee": 8, "ranged": 4, "bomber": 1},
	{"melee": 8, "heavy": 3, "shield": 3, "charger": 1},
	{"melee": 8, "ranged": 5, "shield": 3, "priest": 1},
	{"melee": 9, "heavy": 4, "ranged": 4, "charger": 1, "bomber": 1},
	{"melee": 10, "heavy": 4, "ranged": 5, "shield": 4, "charger": 1, "bomber": 1, "priest": 1},
	{"boss": true},
]

var wave_index := -1
var wave_definitions: Array

func _init(definitions: Array = DEFAULT_WAVES) -> void:
	wave_definitions = definitions.duplicate(true)

func reset() -> void:
	wave_index = -1

func advance() -> Dictionary:
	wave_index += 1
	if wave_index >= wave_definitions.size():
		return {"complete": true, "index": wave_index, "definition": {}}
	return {
		"complete": false,
		"index": wave_index,
		"definition": (wave_definitions[wave_index] as Dictionary).duplicate(true),
	}

func wave_count() -> int:
	return wave_definitions.size()

func boss_wave_index() -> int:
	for index in range(wave_definitions.size()):
		if bool((wave_definitions[index] as Dictionary).get("boss", false)):
			return index
	return -1
