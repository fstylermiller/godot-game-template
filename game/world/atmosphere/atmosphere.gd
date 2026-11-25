@tool
class_name Atmosphere
extends WorldEnvironment

## Composes the environment from independent sky, fog, and post-processing resources, resolving
## every atmosphere color through the global ColorRules.

@export var sky: SkySettings:
	set(value):
		_swap_watched(sky, value)
		sky = value
		rebuild()
@export var fog: FogSettings:
	set(value):
		_swap_watched(fog, value)
		fog = value
		rebuild()
@export var post_process: PostProcessSettings:
	set(value):
		_swap_watched(post_process, value)
		post_process = value
		rebuild()


func _enter_tree() -> void:
	_swap_watched(null, ColorRules.current())


func _exit_tree() -> void:
	_swap_watched(ColorRules.current(), null)


func _ready() -> void:
	rebuild()


func _validate_property(property: Dictionary) -> void:
	if property.name == "environment":
		property.usage = PROPERTY_USAGE_NONE


func rebuild() -> void:
	var rules := ColorRules.current()
	var built := Environment.new()
	built.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	if sky != null:
		built.background_mode = Environment.BG_SKY
		built.sky = sky.build(rules)
	if fog != null:
		fog.apply(built, rules)
	if post_process != null:
		post_process.apply(built)
	environment = built


func _swap_watched(previous: Resource, next: Resource) -> void:
	if previous != null and previous.changed.is_connected(rebuild):
		previous.changed.disconnect(rebuild)
	if next != null and not next.changed.is_connected(rebuild):
		next.changed.connect(rebuild)
