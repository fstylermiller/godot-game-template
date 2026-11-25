extends GutTest


func test_slots_isolate_devices_and_reconnect_matching_guids() -> void:
	var slots := PlayerSlots.new()
	add_child_autofree(slots)
	assert_true(slots._join_device(2, "first"))
	assert_true(slots._join_device(3, "second"))
	assert_false(slots._join_device(2, "first"))
	assert_false(slots._join_device(4, "third"))
	var motion := InputEventJoypadMotion.new()
	motion.device = 2
	motion.axis = JOY_AXIS_LEFT_X
	motion.axis_value = 1.0
	slots._input(motion)
	assert_almost_eq(slots.slots[0].movement().x, 1.0, 0.001)
	assert_eq(slots.slots[1].movement(), Vector2.ZERO)
	slots._on_joy_connection_changed(2, false)
	assert_true(slots.has_disconnected_player())
	assert_eq(slots.slots[0].movement(), Vector2.ZERO)
	motion.device = 3
	slots._input(motion)
	assert_eq(slots.slots[1].movement(), Vector2.ZERO)
	assert_false(slots._join_device(5, "third"))
	assert_true(slots._join_device(5, "first"))
	assert_eq(slots.slots[0].device, 5)
	assert_eq(slots.slots[1].device, 3)


func test_keyboard_and_controller_intent_do_not_leak() -> void:
	var slots := PlayerSlots.new()
	add_child_autofree(slots)
	var join := InputEventKey.new()
	join.physical_keycode = KEY_ENTER
	join.pressed = true
	slots._input(join)
	assert_eq(slots.slots[0].device, PlayerSlot.KEYBOARD)
	assert_true(slots._join_device(1, "pad"))
	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	var button := InputEventJoypadButton.new()
	button.device = 1
	button.button_index = JOY_BUTTON_A
	button.pressed = true
	for slot in slots.slots:
		slot.handle_event(key)
		slot.handle_event(button)
	assert_eq(slots.slots[0].movement(), Vector2.UP)
	assert_eq(slots.slots[1].movement(), Vector2.ZERO)
	assert_false(slots.slots[0].take_jump())
	assert_true(slots.slots[1].take_jump())
	assert_false(slots.slots[1].take_jump())


func test_slot_applies_deadzone_and_disconnect_clears_held_intent() -> void:
	var slot := PlayerSlot.new()
	slot.bind(1, "pad")
	var motion := InputEventJoypadMotion.new()
	motion.device = 1
	motion.axis = JOY_AXIS_LEFT_X
	motion.axis_value = 0.1
	slot.handle_event(motion)
	assert_eq(slot.movement(), Vector2.ZERO)
	motion.axis_value = 0.6
	slot.handle_event(motion)
	assert_almost_eq(slot.movement().x, 0.5, 0.001)
	var button := InputEventJoypadButton.new()
	button.device = 1
	button.button_index = JOY_BUTTON_A
	button.pressed = true
	slot.handle_event(button)
	slot.disconnect_device()
	assert_eq(slot.movement(), Vector2.ZERO)
	assert_false(slot.jump_held)
	assert_false(slot.take_jump())
