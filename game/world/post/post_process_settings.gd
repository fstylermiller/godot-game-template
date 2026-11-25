@tool
class_name PostProcessSettings
extends Resource

## Glow has no tint of its own; its color comes from RuledMaterial emission and RuledLight
## sources, so it already follows the global ColorRules.

@export var glow_enabled := true:
	set(value):
		glow_enabled = value
		emit_changed()


func apply(environment: Environment) -> void:
	environment.glow_enabled = glow_enabled
