@tool
class_name RuledLight
extends Light3D

## A light whose color is base_color passed through the global ColorRules.

@export var base_color := Color.WHITE:
	set(value):
		base_color = value
		_refresh()


func _enter_tree() -> void:
	var rules := ColorRules.current()
	if rules != null and not rules.changed.is_connected(_refresh):
		rules.changed.connect(_refresh)
	_refresh()


func _exit_tree() -> void:
	var rules := ColorRules.current()
	if rules != null and rules.changed.is_connected(_refresh):
		rules.changed.disconnect(_refresh)


func _refresh() -> void:
	var rules := ColorRules.current()
	light_color = rules.apply(base_color) if rules != null else base_color
