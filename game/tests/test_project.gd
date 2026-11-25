extends GutTest

const MAIN_SCENE := preload("res://main.tscn")
const ATMOSPHERE_SCENE := preload("res://world/atmosphere/atmosphere.tscn")
const DEFAULT_PALETTE := preload("res://art/palettes/default.tres")


func test_startup_is_independent_of_gameplay_systems() -> void:
	var scene := MAIN_SCENE.instantiate() as Node3D
	add_child_autofree(scene)
	assert_not_null(scene.get_node("Camera3D") as Camera3D)
	assert_not_null(scene.get_node("Atmosphere") as Atmosphere)
	assert_not_null(scene.get_node("Sun") as RuledLight)
	assert_true(scene.find_children("*", "PhysicsBody3D", true, false).is_empty())
	assert_true(scene.find_children("*", "MeshInstance3D", true, false).is_empty())
	assert_true(scene.find_children("*", "PlayerSlots", true, false).is_empty())


func test_global_rules_restyle_material_light_palette_and_atmosphere() -> void:
	var scene := MAIN_SCENE.instantiate() as Node3D
	add_child_autofree(scene)
	var atmosphere := scene.get_node("Atmosphere") as Atmosphere
	var sun := scene.get_node("Sun") as RuledLight
	var material := RuledMaterial.new()
	material.base_color = Color(0.5, 0.6, 0.7)
	material.base_emission = material.base_color
	material.emission_strength = 2.0
	var rules := ColorRules.current()
	var before := [
		material.albedo_color,
		material.emission,
		sun.light_color,
		DEFAULT_PALETTE.swatch("primary"),
		_sky_top(atmosphere),
		atmosphere.environment.volumetric_fog_albedo,
	]
	var original := rules.luminosity
	rules.luminosity = original - 0.2
	var after := [
		material.albedo_color,
		material.emission,
		sun.light_color,
		DEFAULT_PALETTE.swatch("primary"),
		_sky_top(atmosphere),
		atmosphere.environment.volumetric_fog_albedo,
	]
	rules.luminosity = original
	for index in before.size():
		assert_lt(after[index].ok_hsl_l, before[index].ok_hsl_l - 0.1)
	assert_eq(material.albedo_color, before[0])
	assert_eq(_sky_top(atmosphere), before[4])


func test_atmosphere_follows_replacement_resource_edits() -> void:
	var atmosphere := ATMOSPHERE_SCENE.instantiate() as Atmosphere
	add_child_autofree(atmosphere)
	var fog := FogSettings.new()
	atmosphere.fog = fog
	fog.volumetric_density = 0.02
	assert_almost_eq(atmosphere.environment.volumetric_fog_density, 0.02, 0.0001)
	fog.volumetric_enabled = false
	assert_false(atmosphere.environment.volumetric_fog_enabled)


func test_color_rules_support_hue_caps_and_luminosity_limits() -> void:
	var rules := ColorRules.new()
	var teal := Color.from_ok_hsl(0.5, 0.6, 0.5)
	rules.hue_shift_degrees = 36.0
	assert_almost_eq(rules.apply(teal).ok_hsl_h, 0.6, 0.01)
	rules.hue_shift_degrees = 0.0
	var cap := HueCap.new()
	cap.hue_degrees = 180.0
	cap.max_saturation = 0.3
	rules.hue_caps = [cap]
	assert_almost_eq(rules.apply(teal).ok_hsl_s, 0.3, 0.02)
	rules.luminosity = 0.5
	assert_almost_eq(rules.apply(teal).ok_hsl_l, rules.max_luminosity, 0.01)


func _sky_top(atmosphere: Atmosphere) -> Color:
	return (atmosphere.environment.sky.sky_material as ProceduralSkyMaterial).sky_top_color
