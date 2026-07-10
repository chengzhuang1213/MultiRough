extends RefCounted
class_name WaveManager

const DEFAULT_WAVES := [
	{"minions": 4},
	{"minions": 7},
	{"minions": 10},
	{"minions": 13},
	{"minions": 16},
	{"minions": 20},
	{"minions": 24},
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
