@tool
class_name SkySettings
extends Resource

## Authored sky gradient. Colors pass through the global ColorRules when the sky is built;
## brightness for night and evening scenes comes from energy, not from darker colors.

@export var top_color := Color(0.385, 0.454, 0.55):
	set(value):
		top_color = value
		emit_changed()
@export var horizon_color := Color(0.6463, 0.6558, 0.6708):
	set(value):
		horizon_color = value
		emit_changed()
@export var ground_horizon_color := Color(0.6463, 0.6558, 0.6708):
	set(value):
		ground_horizon_color = value
		emit_changed()
@export var ground_bottom_color := Color(0.2, 0.169, 0.133):
	set(value):
		ground_bottom_color = value
		emit_changed()
@export_range(0.0, 4.0, 0.01) var energy := 1.0:
	set(value):
		energy = value
		emit_changed()


func build(rules: ColorRules) -> Sky:
	var material := ProceduralSkyMaterial.new()
	material.sky_top_color = rules.apply(top_color)
	material.sky_horizon_color = rules.apply(horizon_color)
	material.ground_horizon_color = rules.apply(ground_horizon_color)
	material.ground_bottom_color = rules.apply(ground_bottom_color)
	material.sky_energy_multiplier = energy
	material.ground_energy_multiplier = energy
	var built := Sky.new()
	built.sky_material = material
	return built
