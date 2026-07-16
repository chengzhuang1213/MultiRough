extends RefCounted
class_name InputSetup

static func ensure_default_actions() -> void:
	_add_key_action("move_left", [KEY_A])
	_add_key_action("move_right", [KEY_D])
	_add_key_action("move_up", [KEY_W])
	_add_key_action("move_down", [KEY_S])
	_add_key_action("basic_attack", [KEY_J])
	_add_mouse_action("basic_attack", MOUSE_BUTTON_LEFT)
	_add_key_action("network_basic_attack", [KEY_J])
	_add_key_action("dash", [KEY_SPACE])
	_remove_key_action("dash", [KEY_K])
	_add_key_action("active_skill", [KEY_Q])
	_add_key_action("fan_skill", [KEY_E])
	_add_key_action("ultimate_skill", [KEY_F])
	_add_key_action("defend", [KEY_K])
	_add_mouse_action("defend", MOUSE_BUTTON_RIGHT)

static func _add_key_action(action: StringName, keys: Array[int]) -> void:
	_ensure_input_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)

static func _ensure_input_action(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

static func _remove_key_action(action: StringName, keys: Array[int]) -> void:
	if not InputMap.has_action(action):
		return
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		if InputMap.action_has_event(action, event):
			InputMap.action_erase_event(action, event)

static func _add_mouse_action(action: StringName, button_index: int) -> void:
	_ensure_input_action(action)
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)
