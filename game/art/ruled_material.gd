@tool
class_name RuledMaterial
extends StandardMaterial3D

## A StandardMaterial3D whose albedo and emission pass through the global ColorRules.
## Emission is off until emission_strength is above zero.

@export var base_color := Color.WHITE:
	set(value):
		base_color = value
		_refresh()
@export var base_emission := Color.WHITE:
	set(value):
		base_emission = value
		_refresh()
@export_range(0.0, 16.0, 0.01) var emission_strength := 0.0:
	set(value):
		emission_strength = value
		_refresh()


func _init() -> void:
	var rules := ColorRules.current()
	if rules != null and not rules.changed.is_connected(_refresh):
		rules.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var rules := ColorRules.current()
	albedo_color = rules.apply(base_color) if rules != null else base_color
	emission_enabled = emission_strength > 0.0
	emission = rules.apply(base_emission) if rules != null else base_emission
	emission_energy_multiplier = emission_strength
