@tool
class_name FogSettings
extends Resource

## Volumetric fog. Albedo and emission colors pass through the global ColorRules when applied.

@export var volumetric_enabled := true:
	set(value):
		volumetric_enabled = value
		emit_changed()
@export_range(0.0, 0.1, 0.001) var volumetric_density := 0.008:
	set(value):
		volumetric_density = value
		emit_changed()
@export var albedo := Color.WHITE:
	set(value):
		albedo = value
		emit_changed()
@export var emission := Color.WHITE:
	set(value):
		emission = value
		emit_changed()
## Zero keeps fog unlit; raise it for self-lit haze such as stage or street-light fog.
@export_range(0.0, 4.0, 0.01) var emission_energy := 0.0:
	set(value):
		emission_energy = value
		emit_changed()


func apply(environment: Environment, rules: ColorRules) -> void:
	environment.volumetric_fog_enabled = volumetric_enabled
	environment.volumetric_fog_density = volumetric_density
	environment.volumetric_fog_albedo = rules.apply(albedo)
	environment.volumetric_fog_emission = rules.apply(emission)
	environment.volumetric_fog_emission_energy = emission_energy
