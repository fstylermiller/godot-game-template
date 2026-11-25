@tool
class_name ColorRules
extends Resource

## The one place that constrains color for the whole game. Every Palette and RuledMaterial passes
## its authored colors through apply(), so editing res://art/color_rules.tres restyles everything.
## Works in OKHSL so hue, saturation, and luminosity changes look perceptually even.

const PATH := "res://art/color_rules.tres"

static var _current: ColorRules

@export_group("Hue")
@export_range(-180.0, 180.0, 1.0, "degrees") var hue_shift_degrees := 0.0:
	set(value):
		hue_shift_degrees = value
		emit_changed()
@export_range(0.0, 360.0, 1.0, "degrees") var warm_target_degrees := 60.0:
	set(value):
		warm_target_degrees = value
		emit_changed()
@export_range(0.0, 1.0, 0.01) var warm_pull := 0.0:
	set(value):
		warm_pull = value
		emit_changed()
@export var hue_caps: Array[HueCap] = []:
	set(value):
		for cap in hue_caps:
			if cap != null and cap.changed.is_connected(emit_changed):
				cap.changed.disconnect(emit_changed)
		hue_caps = value
		for cap in hue_caps:
			if cap != null and not cap.changed.is_connected(emit_changed):
				cap.changed.connect(emit_changed)
		emit_changed()

@export_group("Saturation")
@export_range(0.0, 2.0, 0.01) var saturation := 1.0:
	set(value):
		saturation = value
		emit_changed()
@export_range(0.0, 1.0, 0.01) var min_saturation := 0.0:
	set(value):
		min_saturation = value
		emit_changed()
@export_range(0.0, 1.0, 0.01) var max_saturation := 0.95:
	set(value):
		max_saturation = value
		emit_changed()

@export_group("Luminosity")
@export_range(-0.5, 0.5, 0.01) var luminosity := 0.0:
	set(value):
		luminosity = value
		emit_changed()
@export_range(0.0, 3.0, 0.01) var contrast := 1.0:
	set(value):
		contrast = value
		emit_changed()
@export_range(0.0, 1.0, 0.01) var min_luminosity := 0.25:
	set(value):
		min_luminosity = value
		emit_changed()
@export_range(0.0, 1.0, 0.01) var max_luminosity := 0.96:
	set(value):
		max_luminosity = value
		emit_changed()


## Held statically so every material and palette shares one live instance.
static func current() -> ColorRules:
	if _current == null:
		_current = load(PATH) as ColorRules
	return _current


func apply(color: Color) -> Color:
	var hue := fposmod(color.ok_hsl_h + hue_shift_degrees / 360.0, 1.0)
	var toward_warm := fposmod(warm_target_degrees / 360.0 - hue + 0.5, 1.0) - 0.5
	hue = fposmod(hue + toward_warm * warm_pull, 1.0)

	var sat := maxf(color.ok_hsl_s * saturation, min_saturation)
	sat = minf(sat, max_saturation)
	for cap in hue_caps:
		if cap != null:
			sat = minf(sat, cap.limit_for(hue))

	var lum := (color.ok_hsl_l - 0.5) * contrast + 0.5 + luminosity
	lum = clampf(lum, min_luminosity, max_luminosity)
	return Color.from_ok_hsl(hue, clampf(sat, 0.0, 1.0), lum, color.a)
