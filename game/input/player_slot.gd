class_name PlayerSlot
extends RefCounted

const KEYBOARD := -2
const UNASSIGNED := -1
const DEADZONE := 0.2

var device := UNASSIGNED
var connected := false
var guid := ""
var direction := Vector2.ZERO
var run_held := false
var jump_held := false
var _jump_pending := false
var _left := false
var _right := false
var _forward := false
var _back := false


func bind(device_id: int, device_guid: String = "") -> void:
	reset_input()
	device = device_id
	guid = device_guid
	connected = true


func disconnect_device() -> void:
	reset_input()
	connected = false


func reset_input() -> void:
	direction = Vector2.ZERO
	run_held = false
	jump_held = false
	_jump_pending = false
	_left = false
	_right = false
	_forward = false
	_back = false


func handle_event(event: InputEvent) -> void:
	if not connected:
		return
	if device == KEYBOARD and event is InputEventKey:
		_handle_key(event)
	elif device >= 0 and event.device == device:
		if event is InputEventJoypadMotion:
			if event.axis == JOY_AXIS_LEFT_X:
				direction.x = event.axis_value
			elif event.axis == JOY_AXIS_LEFT_Y:
				direction.y = event.axis_value
		elif event is InputEventJoypadButton:
			if event.button_index == JOY_BUTTON_B:
				run_held = event.pressed
			elif event.button_index == JOY_BUTTON_A:
				_set_jump(event.pressed)


func movement() -> Vector2:
	var length := direction.length()
	if length <= DEADZONE:
		return Vector2.ZERO
	return direction.normalized() * minf((length - DEADZONE) / (1.0 - DEADZONE), 1.0)


func take_jump() -> bool:
	var pressed := _jump_pending
	_jump_pending = false
	return pressed


func _set_jump(pressed: bool) -> void:
	if pressed and not jump_held:
		_jump_pending = true
	jump_held = pressed


func _handle_key(event: InputEventKey) -> void:
	match event.physical_keycode:
		KEY_A:
			_left = event.pressed
		KEY_D:
			_right = event.pressed
		KEY_W:
			_forward = event.pressed
		KEY_S:
			_back = event.pressed
		KEY_SHIFT:
			run_held = event.pressed
		KEY_SPACE:
			_set_jump(event.pressed)
	direction = Vector2(float(_right) - float(_left), float(_back) - float(_forward))
