extends GutTest


func test_any_roof_fades_out_for_group_members_and_keeps_its_shadow() -> void:
	var cover := CoveredRoof.new()
	var roof := MeshInstance3D.new()
	roof.name = "Slab"
	roof.mesh = BoxMesh.new()
	var material := RuledMaterial.new()
	material.base_color = Color(0.6, 0.3, 0.25)
	roof.mesh.surface_set_material(0, material)
	cover.add_child(roof)
	cover.roof = roof
	var shadow := MeshInstance3D.new()
	shadow.mesh = roof.mesh
	cover.add_child(shadow)
	cover.shadow_caster = shadow
	add_child_autofree(cover)
	assert_eq(cover.get_child_count(), 2, "The cutaway must not build geometry of its own.")
	assert_eq(shadow.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY)
	assert_eq(roof.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	var stranger := autofree(Node3D.new()) as Node3D
	cover._on_body_entered(stranger)
	assert_false(cover.is_occupied(), "Only the occupant group opens the cutaway.")
	var occupant := Node3D.new()
	occupant.add_to_group(CoveredRoof.DEFAULT_OCCUPANTS)
	add_child_autofree(occupant)
	cover._on_body_entered(occupant)
	cover._process(cover.fade_time * 0.5)
	var faded := roof.get_active_material(0) as BaseMaterial3D
	assert_ne(faded, material, "Fading must not touch the shared material.")
	assert_eq(faded.transparency, BaseMaterial3D.TRANSPARENCY_ALPHA)
	assert_between(faded.albedo_color.a, 0.01, 0.99)
	assert_true(roof.visible)
	cover._process(cover.fade_time)
	assert_false(roof.visible)
	assert_true(shadow.visible, "The covered space stays shaded.")
	cover._on_body_exited(occupant)
	cover._process(cover.fade_time)
	assert_true(roof.visible)
	assert_eq(faded.transparency, BaseMaterial3D.TRANSPARENCY_DISABLED)
	assert_almost_eq(faded.albedo_color.a, 1.0, 0.001)
	assert_almost_eq(material.albedo_color.a, 1.0, 0.001)


func test_partial_fade_floors_are_inherited_and_the_nearest_override_wins() -> void:
	var cover := CoveredRoof.new()
	cover.faded_opacity = 0.25
	var roof := Node3D.new()
	var awning := Node3D.new()
	awning.set_meta(CoveredRoof.OPACITY_META, 0.1)
	var awning_mesh := _mesh("Awning")
	var sign_mesh := _mesh("Sign")
	sign_mesh.set_meta(CoveredRoof.OPACITY_META, 0.0)
	var slab_mesh := _mesh("Slab")
	var bars_mesh := _mesh("Bars")
	bars_mesh.set_meta(CoveredRoof.GLTF_EXTRAS, {"cutaway_opacity": 0.2})
	awning.add_child(awning_mesh)
	awning.add_child(sign_mesh)
	roof.add_child(awning)
	roof.add_child(slab_mesh)
	roof.add_child(bars_mesh)
	cover.add_child(roof)
	cover.roof = roof
	add_child_autofree(cover)
	var occupant := Node3D.new()
	occupant.add_to_group(CoveredRoof.DEFAULT_OCCUPANTS)
	add_child_autofree(occupant)
	cover._on_body_entered(occupant)
	cover._process(cover.fade_time)
	assert_almost_eq(_alpha(awning_mesh), 0.1, 0.001, "Children inherit their parent's floor.")
	assert_true(awning_mesh.visible)
	assert_almost_eq(_alpha(slab_mesh), 0.25, 0.001, "Unmarked meshes use faded_opacity.")
	assert_false(sign_mesh.visible, "A nearer 0 override fades out completely.")
	assert_almost_eq(_alpha(bars_mesh), 0.2, 0.001, "Model custom properties set the floor too.")


func test_roof_turns_solid_only_with_the_required_occupants_in_frame() -> void:
	var cover := CoveredRoof.new()
	cover.occupant_group = &"test_cutaway_occupants"
	cover.occupants_to_frame = 2
	var roof := _mesh("Slab")
	(roof.mesh as BoxMesh).size = Vector3(10, 0.2, 10)
	roof.position = Vector3(0, 4, 0)
	cover.add_child(roof)
	cover.roof = roof
	add_child_autofree(cover)
	var occupants: Array[Node3D] = []
	for x in [-1.0, 1.0]:
		var occupant := Node3D.new()
		occupant.position = Vector3(x, 0, -3)
		occupant.add_to_group(cover.occupant_group)
		add_child_autofree(occupant)
		cover._on_body_entered(occupant)
		occupants.append(occupant)
	var camera := Camera3D.new()
	add_child_autofree(camera)
	camera.make_current()
	camera.look_at_from_position(Vector3(0, 30, 3), Vector3(0, 0, -3))
	cover._process(cover.fade_time)
	assert_eq(cover.fade, 1.0, "From above, the roof hides the occupants and fades.")
	camera.look_at_from_position(Vector3(0, 2, 3), Vector3(0, 0, -3))
	cover._process(cover.fade_time)
	assert_eq(cover.fade, 0.0, "Under the roof with all occupants framed, it turns solid.")
	occupants[1].position = Vector3(0, 0, 20)
	cover._process(cover.fade_time)
	assert_eq(cover.fade, 1.0, "An occupant out of frame keeps the cutaway open.")
	occupants[1].visible = false
	cover._process(cover.fade_time)
	assert_eq(cover.fade, 1.0, "One framed occupant does not satisfy the configured threshold.")
	cover.occupants_to_frame = 1
	cover._process(cover.fade_time)
	assert_eq(cover.fade, 0.0, "The same system supports a single occupant.")


func _mesh(mesh_name: String) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = mesh_name
	mesh.mesh = BoxMesh.new()
	mesh.mesh.surface_set_material(0, RuledMaterial.new())
	return mesh


func _alpha(mesh: MeshInstance3D) -> float:
	return (mesh.get_active_material(0) as BaseMaterial3D).albedo_color.a
