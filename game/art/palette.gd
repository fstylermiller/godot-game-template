@tool
class_name Palette
extends Resource

## A scene's named color swatches as authored. Always read them through resolved(), which applies
## the global ColorRules.

@export_multiline var description := ""
@export var swatches: Dictionary[String, Color] = {}:
	set(value):
		swatches = value
		emit_changed()


func resolved(rules: ColorRules = null) -> Array[Color]:
	var active := rules if rules != null else ColorRules.current()
	var colors: Array[Color] = []
	for color: Color in swatches.values():
		colors.append(active.apply(color))
	return colors


func swatch(swatch_name: String, rules: ColorRules = null) -> Color:
	var active := rules if rules != null else ColorRules.current()
	return active.apply(swatches[swatch_name])
