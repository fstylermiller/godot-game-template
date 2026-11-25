@tool
class_name HueCap
extends Resource

## Limits saturation near one hue (for example harsh reds), fading out toward the edges of the band.

@export_range(0.0, 360.0, 1.0, "degrees") var hue_degrees := 25.0:
	set(value):
		hue_degrees = value
		emit_changed()
@export_range(1.0, 180.0, 1.0, "degrees") var width_degrees := 40.0:
	set(value):
		width_degrees = value
		emit_changed()
@export_range(0.0, 1.0, 0.01) var max_saturation := 0.8:
	set(value):
		max_saturation = value
		emit_changed()


func limit_for(hue: float) -> float:
	var distance := absf(fposmod(hue - hue_degrees / 360.0 + 0.5, 1.0) - 0.5) * 360.0
	var half_width := width_degrees / 2.0
	if distance >= half_width:
		return 1.0
	return lerpf(max_saturation, 1.0, distance / half_width)
