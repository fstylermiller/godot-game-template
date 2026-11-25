class_name PlayerSlots
extends Node

signal slots_changed

var slots: Array[PlayerSlot] = [PlayerSlot.new(), PlayerSlot.new()]


func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _exit_tree() -> void:
	Input.joy_connection_changed.disconnect(_on_joy_connection_changed)


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_A or event.button_index == JOY_BUTTON_START:
			if _join_device(event.device, Input.get_joy_guid(event.device)):
				return
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ENTER:
			if _join_device(PlayerSlot.KEYBOARD):
				return
	if has_disconnected_player():
		return
	for slot in slots:
		slot.handle_event(event)


func has_disconnected_player() -> bool:
	for slot in slots:
		if slot.device != PlayerSlot.UNASSIGNED and not slot.connected:
			return true
	return false


func _join_device(device: int, guid: String = "") -> bool:
	for slot in slots:
		if slot.connected and slot.device == device:
			return false
	for slot in slots:
		if not slot.connected and slot.device != PlayerSlot.UNASSIGNED:
			if slot.guid == guid and device >= 0:
				slot.bind(device, guid)
				slots_changed.emit()
				return true
	if has_disconnected_player():
		return false
	for slot in slots:
		if slot.device == PlayerSlot.UNASSIGNED:
			slot.bind(device, guid)
			slots_changed.emit()
			return true
	return false


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if connected:
		return
	for slot in slots:
		if slot.connected and slot.device == device:
			slot.disconnect_device()
			for other_slot in slots:
				other_slot.reset_input()
			slots_changed.emit()
			return
